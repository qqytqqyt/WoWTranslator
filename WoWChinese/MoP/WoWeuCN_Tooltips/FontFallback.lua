-- Chinese font fallback
-- The client draws Chinese glyphs in its default fonts by falling back to Fonts\ARKai_T.ttf, which only
-- exists if the client was ever installed in Chinese; without it translated text renders as boxes.
-- In that case (or when the "overwritefonts" option is on) translated text is drawn in the addon font.

local CLIENT_CHINESE_FONT = "Fonts\\ARKai_T.ttf"
local clientFontMissing = nil

-- tooltip -> { [line] = { fontObject, file, size, flags } } for the lines switched to the addon font
local switchedLines = setmetatable({}, { __mode = "k" })
local hookedTooltips = setmetatable({}, { __mode = "k" })

-- EditBox:SetFont raises "Invalid font asset ... file not found" for a missing file
function WoWeuCN_Tooltips_IsClientChineseFontMissing()
  if clientFontMissing == nil then
    local probe = CreateFrame("EditBox")
    probe:SetAutoFocus(false)
    probe:Hide()
    clientFontMissing = not pcall(probe.SetFont, probe, CLIENT_CHINESE_FONT, 12, "")
  end
  return clientFontMissing
end

function WoWeuCN_Tooltips_UseAddonFont()
  if WoWeuCN_Tooltips_N_PS and WoWeuCN_Tooltips_N_PS["overwritefonts"] == "1" then
    return true
  end
  return WoWeuCN_Tooltips_IsClientChineseFontMissing()
end

-- For frames that keep showing translated text (journals, achievements): switch for good
function WoWeuCN_Tooltips_ApplyAddonFont(fontString)
  if not fontString or not WoWeuCN_Tooltips_UseAddonFont() then
    return
  end
  local file, size, flags = fontString:GetFont()
  if size and size > 0 and file ~= WoWeuCN_Tooltips_Font1 then
    fontString:SetFont(WoWeuCN_Tooltips_Font1, size, flags or "")
  end
end

local function RestoreTooltipLineFonts(tooltip)
  local lines = switchedLines[tooltip]
  if not lines then
    return
  end
  switchedLines[tooltip] = nil
  for line, saved in pairs(lines) do
    -- restore through the font object: GetFont() only reports the roman file of a font family, and
    -- SetFont with it drops the family's Chinese member, which is what drew boxes before a716c8a
    if saved.fontObject then
      line:SetFontObject(saved.fontObject)
    elseif saved.file then
      line:SetFont(saved.file, saved.size, saved.flags)
    end
  end
end

-- Tooltip lines are reused for the next tooltip, so a switched line goes back to its own font on clear
function WoWeuCN_Tooltips_ApplyTooltipLineFont(tooltip, index)
  if not tooltip or not index or not WoWeuCN_Tooltips_UseAddonFont() then
    return
  end
  local name = tooltip.GetName and tooltip:GetName()
  local line = name and _G[name .. "TextLeft" .. index]
  if not line then
    return
  end
  local file, size, flags = line:GetFont()
  if not size or size <= 0 or file == WoWeuCN_Tooltips_Font1 then
    return
  end

  local lines = switchedLines[tooltip]
  if not lines then
    lines = {}
    switchedLines[tooltip] = lines
  end
  if not lines[line] then
    lines[line] = { fontObject = line:GetFontObject(), file = file, size = size, flags = flags or "" }
  end
  line:SetFont(WoWeuCN_Tooltips_Font1, size, flags or "")

  if not hookedTooltips[tooltip] and tooltip.HasScript and tooltip:HasScript("OnTooltipCleared") then
    tooltip:HookScript("OnTooltipCleared", RestoreTooltipLineFonts)
    hookedTooltips[tooltip] = true
  end
end
