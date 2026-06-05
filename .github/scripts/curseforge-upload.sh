#!/usr/bin/env bash
# Packages changed WoWChinese addons and uploads them to CurseForge.
# Triggered by push to master (auto-detects changed addons) or manually
# via workflow_dispatch (uploads the selected flavor/addon).
set -euo pipefail

API_BASE="https://wow.curseforge.com/api"
FLAVORS=(Anniversary Classic MoP Retail)

# Read a "## Field: value" entry from a .toc, tolerating UTF-8 BOM and CRLF
toc_field() {
  sed -e '1s/^\xEF\xBB\xBF//' -e 's/\r$//' "$2" | grep -m1 "^## $1:" | sed "s/^## $1:[[:space:]]*//" || true
}

if [[ -z "${CURSEFORGE_TOKEN:-}" ]]; then
  echo "::error::CURSEFORGE_TOKEN secret is not set"; exit 1
fi

# ---------------------------------------------------------------------------
# 1. Determine which addon folders to upload
# ---------------------------------------------------------------------------
declare -a ADDON_DIRS=()

if [[ "$EVENT_NAME" == "workflow_dispatch" ]]; then
  ADDON_DIRS=("WoWChinese/$INPUT_FLAVOR/$INPUT_ADDON")
else
  BEFORE="$BEFORE_SHA"
  # New branch / force push: fall back to the parent of the pushed commit
  if [[ -z "$BEFORE" || "$BEFORE" =~ ^0+$ ]] || ! git cat-file -e "$BEFORE" 2>/dev/null; then
    BEFORE="$(git rev-parse "${AFTER_SHA}~1")"
  fi
  paths=()
  for f in "${FLAVORS[@]}"; do paths+=("WoWChinese/$f"); done
  mapfile -t ADDON_DIRS < <(
    git diff --name-only "$BEFORE" "$AFTER_SHA" -- "${paths[@]}" |
      awk -F/ 'NF>=4 {print $1"/"$2"/"$3}' | sort -u
  )
fi

if [[ ${#ADDON_DIRS[@]} -eq 0 ]]; then
  echo "No addon changes detected, nothing to upload."; exit 0
fi
echo "Addons to upload: ${ADDON_DIRS[*]}"

# ---------------------------------------------------------------------------
# 2. Fetch CurseForge game versions once (name -> id lookup)
# ---------------------------------------------------------------------------
curl -sSf -H "X-Api-Token: $CURSEFORGE_TOKEN" \
  "$API_BASE/game/versions" > /tmp/cf_versions.json

mkdir -p /tmp/cf_out
failures=0

for dir in "${ADDON_DIRS[@]}"; do
  echo "::group::$dir"
  if [[ ! -d "$dir" ]]; then
    echo "Directory no longer exists, skipping."; echo "::endgroup::"; continue
  fi

  addon="$(basename "$dir")"
  flavor="$(basename "$(dirname "$dir")")"
  toc="$dir/$addon.toc"
  if [[ ! -f "$toc" ]]; then
    echo "::error::Missing $toc"; failures=$((failures+1)); echo "::endgroup::"; continue
  fi

  # -------------------------------------------------------------------------
  # Parse .toc: Interface (may be comma-separated) and Version
  # -------------------------------------------------------------------------
  interface_line="$(toc_field Interface "$toc")"
  toc_version="$(toc_field Version "$toc")"
  title="$(toc_field Title "$toc")"
  [[ -z "$title" ]] && title="$addon"
  if [[ -z "$interface_line" || -z "$toc_version" ]]; then
    echo "::error::Could not parse Interface/Version from $toc"
    failures=$((failures+1)); echo "::endgroup::"; continue
  fi

  # Map each interface number (e.g. 50504) to a CF game version id (e.g. "5.5.4")
  gv_ids="[]"
  IFS=',' read -ra ifaces <<< "$interface_line"
  for raw in "${ifaces[@]}"; do
    iface="$(echo "$raw" | tr -d '[:space:]')"
    [[ -z "$iface" ]] && continue
    major=$((10#$iface / 10000))
    minor=$(( (10#$iface / 100) % 100 ))
    patch=$((10#$iface % 100))
    vname="$major.$minor.$patch"
    vid="$(jq -r --arg n "$vname" '[.[] | select(.name == $n)][0].id // empty' /tmp/cf_versions.json)"
    if [[ -z "$vid" ]]; then
      echo "::error::CurseForge has no game version named '$vname' (Interface $iface in $toc)"
      failures=$((failures+1)); echo "::endgroup::"; continue 2
    fi
    echo "Interface $iface -> game version $vname (id $vid)"
    gv_ids="$(jq -c --argjson id "$vid" '. + [$id] | unique' <<< "$gv_ids")"
  done

  # -------------------------------------------------------------------------
  # Resolve CurseForge project id
  # -------------------------------------------------------------------------
  case "$addon" in
    WoWeuCN_Quests)   project_id="${CF_PROJECT_ID_QUESTS:-}" ;;
    WoWeuCN_Tooltips) project_id="${CF_PROJECT_ID_TOOLTIPS:-}" ;;
    *) project_id="" ;;
  esac
  if [[ -z "$project_id" ]]; then
    echo "::error::No CurseForge project id configured for $addon (set repo variable CF_PROJECT_ID_QUESTS / CF_PROJECT_ID_TOOLTIPS)"
    failures=$((failures+1)); echo "::endgroup::"; continue
  fi

  # -------------------------------------------------------------------------
  # Changelog: manual override, or commit subjects touching this addon
  # -------------------------------------------------------------------------
  if [[ "$EVENT_NAME" == "workflow_dispatch" && -n "${INPUT_CHANGELOG:-}" ]]; then
    changelog="$INPUT_CHANGELOG"
  elif [[ "$EVENT_NAME" == "workflow_dispatch" ]]; then
    changelog="$(git log -1 --format='- %s' -- "$dir")"
  else
    changelog="$(git log --format='- %s' "$BEFORE..$AFTER_SHA" -- "$dir")"
  fi
  [[ -z "$changelog" ]] && changelog="- Update"
  echo "Changelog:"; echo "$changelog"

  # -------------------------------------------------------------------------
  # Package: zip must contain the addon folder at its root
  # -------------------------------------------------------------------------
  # Display name e.g. "WoWeuCN-Quests MoP 5.5.4.0" (toc Version already
  # carries the flavor prefix where relevant; Retail is plain "12.0.5.1")
  display_name="$title $toc_version"
  zip_name="${addon}-$(echo "$toc_version" | tr ' /' '--').zip"
  zip_path="/tmp/cf_out/$zip_name"
  rm -f "$zip_path"
  (cd "$(dirname "$dir")" && zip -r -q "$zip_path" "$addon" -x '*.git*')
  echo "Packaged $zip_path ($(du -h "$zip_path" | cut -f1))"

  # -------------------------------------------------------------------------
  # Upload
  # -------------------------------------------------------------------------
  metadata="$(jq -n \
    --arg changelog "$changelog" \
    --arg displayName "$display_name" \
    --argjson gameVersions "$gv_ids" \
    '{changelog: $changelog, changelogType: "markdown",
      displayName: $displayName, gameVersions: $gameVersions,
      releaseType: "release"}')"

  http_code="$(curl -sS -o /tmp/cf_resp.json -w '%{http_code}' \
    -H "X-Api-Token: $CURSEFORGE_TOKEN" \
    -F "metadata=$metadata" \
    -F "file=@$zip_path" \
    "$API_BASE/projects/$project_id/upload-file")"

  if [[ "$http_code" == "200" ]]; then
    file_id="$(jq -r '.id' /tmp/cf_resp.json)"
    echo "Uploaded '$display_name' to project $project_id (file id $file_id)"
  else
    echo "::error::Upload failed for $addon ($flavor) with HTTP $http_code: $(cat /tmp/cf_resp.json)"
    failures=$((failures+1))
  fi
  echo "::endgroup::"
done

exit $((failures > 0 ? 1 : 0))
