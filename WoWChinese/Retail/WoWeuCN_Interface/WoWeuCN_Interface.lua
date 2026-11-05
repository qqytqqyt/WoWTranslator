-- Addon: WoWeuCN-Interface
-- Author: qqytqqyt

local WoWeuCN_Interface_version = C_AddOns.GetAddOnMetadata("WoWeuCN_Interface", "Version");
local WoWeuCN_Interface_onDebug = false;
local WoWeuCN_AddonPrefix = "WoWeuCN";
local WoWeuCN_Interface_VersionReminded = false;

WoWeuCN_Interface_Reverse = {};
local WoWeuCN_Interface_ReverseUpper = {};
local WoWeuCN_Interface_ReverseLower = {};
local WoWeuCN_Interface_ContextOverrides = {};
local WoWeuCN_Interface_Swept = 0;
local WoWeuCN_Interface_FontsDone = {};
local WoWeuCN_Interface_Initialized = false;
local WoWeuCN_Interface_SuppressHook = false;
WoWeuCN_Interface_SettingsCategory = nil;

local WoWeuCN_Interface_PreferredKeys = {
  ["PROFESSIONS_CRAFTING_FORM_BACK"] = 2,
  ["CATALOG_SHOP_BACK"] = 2,
  ["BACK"] = 1,
  ["LEADER"] = 1,
  ["OFFICER"] = 1,
  ["AVAILABLE"] = 1,
  ["DEPOSIT"] = 1,
  ["FILTER"] = 1,
  ["POI_FOCUS"] = 1,
  ["POWER_TYPE_FURY"] = 1,
  ["RAID_FINDER"] = 1,
  ["TRAIN"] = 1,
  ["FRONT_END_LOBBY_SOLO"] = 1,
  ["COOLDOWN_VIEWER_SETTINGS_BUTTON_REVERT_CHANGES"] = 1,
  ["HUD_EDIT_MODE_SETTING_AURA_FRAME_OPACITY"] = 1,
  ["PET_BATTLE_STAT_QUALITY"] = 1,
  ["AUCTION_CATEGORY_MISCELLANEOUS"] = 1,
  ["JOURNEYS_OVERVIEW_LABEL"] = 1,
  ["AUCTION_HOUSE_HEADER_CURRENT_BID"] = 1,
  ["BATTLEFIELDMINIMAP_OPACITY_LABEL"] = 1,
};

local WoWeuCN_Interface_PatternBlockedKeys = {
  "TITLE_TEMPLATE",
  "DECLENSION_SET",
  "GUILD_TEMPLATE",
  "GUILD_TITLE_TEMPLATE",
  "CALL_PET_SPELL_NAME",
  "ASSIST_ACTION_LOUNGING_PLAYER_NAME",
  "ASSIST_ACTION_PLAYER_GUARDIAN_NAME",
  "ASSIST_ACTION_PLAYER_SLAYER_TITLE",
  "BATTLE_PET_CAGE_ITEM_NAME",
  "CHALLENGE_MODE_KEYSTONE_NAME",
};

local WoWeuCN_Interface_NameFontStrings = {
  "^MerchantItem%d+Name$",
  "^MerchantBuyBackItemName$",
  "^LootButton%d+Text$",
  "^GroupLootFrame%d+Name$",
  "^SpellButton%d+SpellName$",
  "^TradePlayerItem%d+Name$",
  "^TradeRecipientItem%d+Name$",
  "^QuestInfoRewardsFrameQuestInfoItem%d+Name$",
  "^QuestInfoSpellObjectiveFrameName$",
  "^QuestInfoSkillPointFrameName$",
  "^QuestProgressItem%d+Name$",
  "^QuestLogItem%d+Name$",
  "^ActionButton%d+Name$",
  "^MultiBar%w+Button%d+Name$",
  "^TradeSkillSkill%d+Text$",
  "^TradeSkillSkillName$",
  "^TradeSkillReagent%d+Name$",
  "^Craft%d+Text$",
  "^CraftName$",
  "^CraftReagent%d+Name$",
  "^ClassTrainerSkill%d+Text$",
  "^ClassTrainerSkillName$",
  "^PrimaryProfession%dSpellButton%a+SpellName$",
  "^SecondaryProfession%dSpellButton%a+SpellName$",
  "^BrowseButton%d+Name$",
  "^AuctionsButton%d+Name$",
  "^BidButton%d+Name$",
  "^AuctionsItemButtonName$",
};

local WoWeuCN_Interface_ContextSpecs = {
  { key = "BACKSLOT", roots = {
      ["CharacterFrame"] = true, ["InspectFrame"] = true,
      ["EquipmentFlyoutFrame"] = true, ["DressUpFrame"] = true,
      ["WardrobeFrame"] = true, ["CollectionsJournal"] = true,
      ["ItemUpgradeFrame"] = true, ["AuctionFrame"] = true } },
  { key = "AUCTION_HOUSE_DEPOSIT_LABEL", roots = {
      ["AuctionHouseFrame"] = true } },
  { key = "MAIL_RETURN", roots = {
      ["MailFrame"] = true, ["OpenMailFrame"] = true } },
};

local WoWeuCN_Interface_PatternBuckets = nil;
local WoWeuCN_Interface_PatternCount = 0;
local WoWeuCN_Interface_PendingEntries = {};

local WoWeuCN_Interface_WORD = "[^%s%p%d%c]+";

local function WoWeuCN_Interface_ParseFormat(s)

  local pieces = {};
  local tokenCount = 0;
  local i = 1;
  local len = string.len(s);
  local lit = "";
  while (i <= len) do
    local a = string.find(s, "%", i, true);
    if (not a) then
      lit = lit .. string.sub(s, i);
      break;
    end
    lit = lit .. string.sub(s, i, a - 1);
    local numPart, dollar, width, conv = string.match(string.sub(s, a), "^%%(%d*)(%$?)([%d%.%-]*)([%a%%])");
    if (not conv) then
      lit = lit .. "%";
      i = a + 1;
    elseif (conv == "%") then
      lit = lit .. "%";
      i = a + 1 + string.len(numPart) + string.len(dollar) + string.len(width) + 1;
    else
      if (lit ~= "") then
        pieces[#pieces + 1] = { lit = lit };
        lit = "";
      end
      tokenCount = tokenCount + 1;
      local pos = nil;
      if (dollar == "$" and numPart ~= "") then
        pos = tonumber(numPart);
      end
      pieces[#pieces + 1] = { conv = conv, pos = pos or tokenCount };
      i = a + 1 + string.len(numPart) + string.len(dollar) + string.len(width) + 1;
    end
  end
  if (lit ~= "") then
    pieces[#pieces + 1] = { lit = lit };
  end
  return pieces, tokenCount;
end

local function WoWeuCN_Interface_EscapePattern(s)
  return (string.gsub(s, "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1"));
end

local function WoWeuCN_Interface_CompilePatternEntry(en, zh)
  local enPieces, enCount = WoWeuCN_Interface_ParseFormat(en);
  if (enCount == 0 or enCount > 8) then
    return nil;
  end
  local zhPieces, zhCount = WoWeuCN_Interface_ParseFormat(zh);
  if (zhCount ~= enCount) then
    return nil;
  end

  local pat = "^";
  local posToCapture = {};
  local captureIndex = 0;
  local lastTokenPiece = nil;
  for i = 1, #enPieces do
    if (enPieces[i].conv) then
      lastTokenPiece = enPieces[i];
    end
  end
  local words = {};
  local looseWords = {};
  local litLen = 0;
  for i = 1, #enPieces do
    local piece = enPieces[i];
    if (piece.lit) then
      litLen = litLen + string.len(piece.lit);
      pat = pat .. WoWeuCN_Interface_EscapePattern(piece.lit);
      local pieceLen = string.len(piece.lit);
      for startPos, word, endPos in string.gmatch(piece.lit, "()(" .. WoWeuCN_Interface_WORD .. ")()") do
        if (string.len(word) >= 3) then
          if ((startPos > 1 or i == 1) and (endPos <= pieceLen or i == #enPieces)) then
            words[word] = true;
          else
            looseWords[word] = true;
          end
        end
      end
    else
      captureIndex = captureIndex + 1;
      if (posToCapture[piece.pos]) then
        return nil;
      end
      posToCapture[piece.pos] = captureIndex;
      if (piece.conv == "d" or piece.conv == "i" or piece.conv == "u" or piece.conv == "f" or piece.conv == "g") then

        pat = pat .. "([%d%.,%- \194\160\226\128\175]+)";
      elseif (piece == lastTokenPiece) then
        pat = pat .. "(.*)";
      else
        pat = pat .. "(.-)";
      end
    end
  end
  if (next(words) == nil) then
    words = looseWords;
  end
  if (next(words) == nil) then
    return nil;
  end
  pat = pat .. "$";

  local out = {};
  for i = 1, #zhPieces do
    local piece = zhPieces[i];
    if (piece.lit) then
      out[#out + 1] = { lit = piece.lit };
    else
      local cap = posToCapture[piece.pos];
      if (not cap) then
        return nil;
      end
      out[#out + 1] = { cap = cap };
    end
  end
  return { pat = pat, out = out, words = words, litLen = litLen };
end

function WoWeuCN_Interface_HasForeignLetters(s)
  if (not string.find(s, "[%a\195-\223]")) then
    return false;
  end
  s = string.gsub(s, "|c%x%x%x%x%x%x%x%x", "");
  s = string.gsub(s, "|cn[%w_]+:", "");
  s = string.gsub(s, "|H.-|h", "");
  s = string.gsub(s, "|T.-|t", "");
  s = string.gsub(s, "|A.-|a", "");
  s = string.gsub(s, "|K.-|k", "");
  s = string.gsub(s, "|[rhn]", "");
  return (string.find(s, "%a%a") ~= nil) or (string.find(s, "[\195-\223][\128-\191]") ~= nil);
end

local function WoWeuCN_Interface_ExactTranslate(text)
  return WoWeuCN_Interface_Reverse[text] or WoWeuCN_Interface_ReverseUpper[text]
      or WoWeuCN_Interface_ReverseLower[string.lower(text)];
end

local function WoWeuCN_Interface_TranslateCapture(cap)
  return WoWeuCN_Interface_ExactTranslate(cap)
      or WoWeuCN_Interface_TryDecoratedTranslate(cap, WoWeuCN_Interface_ExactTranslate);
end

function WoWeuCN_Interface_TryPatternTranslate(text)
  if (not WoWeuCN_Interface_PatternBuckets or string.len(text) > 300) then
    return nil;
  end
  local allowMixed = WoWeuCN_Interface_N_PS and WoWeuCN_Interface_N_PS["transmixed"] == "1";
  local tried = 0;
  local best, bestLeft, bestLit = nil, nil, nil;
  for word in string.gmatch(text, WoWeuCN_Interface_WORD) do
    local bucket = WoWeuCN_Interface_PatternBuckets[word];
    if (bucket) then
      for j = 1, #bucket do
        local entry = bucket[j];
        tried = tried + 1;
        if (tried > 40) then
          break;
        end
        local c1, c2, c3, c4, c5, c6, c7, c8 = string.match(text, entry.pat);
        if (c1 ~= nil) then
          local caps = { c1, c2, c3, c4, c5, c6, c7, c8 };
          local parts = {};
          local left = 0;
          for k = 1, #entry.out do
            local piece = entry.out[k];
            if (piece.lit) then
              parts[#parts + 1] = piece.lit;
            else
              local cap = caps[piece.cap] or "";
              if (WoWeuCN_Interface_HasForeignLetters(cap)) then
                local sub = WoWeuCN_Interface_TranslateCapture(cap);
                if (sub) then
                  cap = sub;
                else
                  left = left + string.len(cap);
                end
              end
              parts[#parts + 1] = cap;
            end
          end
          if (best == nil or left < bestLeft or (left == bestLeft and entry.litLen > bestLit)) then
            best, bestLeft, bestLit = table.concat(parts), left, entry.litLen;
          end
        end
      end
    end
    if (tried > 40) then
      break;
    end
  end
  if (best ~= nil and (bestLeft == 0 or allowMixed)) then
    return best;
  end
  return nil;
end

local function WoWeuCN_Interface_CoreTranslate(text)
  return WoWeuCN_Interface_ExactTranslate(text) or WoWeuCN_Interface_TryPatternTranslate(text);
end

function WoWeuCN_Interface_TryDecoratedTranslate(text, core)
  core = core or WoWeuCN_Interface_CoreTranslate;

  local colorOpen, inner, colorClose = string.match(text, "^(|c%x%x%x%x%x%x%x%x)(.-)(|r)$");
  if (inner and inner ~= "") then
    local translated = core(inner) or WoWeuCN_Interface_TryDecoratedTranslate(inner, core);
    if (translated) then
      return colorOpen .. translated .. colorClose;
    end
    return nil;
  end

  local head, colonTail = string.match(text, "^(.-)(%s*[:：]%s*)$");
  if (head and head ~= "") then
    local translated = core(head);
    if (translated) then
      return translated .. colonTail;
    end
  end

  local label, sep, value = string.match(text, "^([^:]-)(%s*:%s*)(.+)$");
  if (label and label ~= "") then
    local translatedLabel = core(label);
    if (translatedLabel) then
      if (not WoWeuCN_Interface_HasForeignLetters(value)) then
        return translatedLabel .. sep .. value;
      end
      local translatedValue = core(value);
      if (translatedValue) then
        return translatedLabel .. sep .. translatedValue;
      end
    end
  end

  local lead, mid, trail = string.match(text, "^(%s*)(.-)(%s*)$");
  if (mid and mid ~= text and mid ~= "") then
    local translated = core(mid);
    if (translated) then
      return lead .. translated .. trail;
    end
  end

  local beforeDots = string.match(text, "^(.-)%.%.%.$");
  if (beforeDots and beforeDots ~= "") then
    local translated = core(beforeDots);
    if (translated) then
      return translated .. "...";
    end
  end
  return nil;
end

function WoWeuCN_Interface_TranslateText(text)
  return WoWeuCN_Interface_ExactTranslate(text)
      or WoWeuCN_Interface_TryDecoratedTranslate(text, WoWeuCN_Interface_ExactTranslate)
      or WoWeuCN_Interface_TryPatternTranslate(text)
      or WoWeuCN_Interface_TryDecoratedTranslate(text);
end

local WoWeuCN_Interface_TextCache = {};
local WoWeuCN_Interface_TextCacheCount = 0;
local WoWeuCN_Interface_TextCacheLimit = 20000;

function WoWeuCN_Interface_ClearTextCache()
  WoWeuCN_Interface_TextCache = {};
  WoWeuCN_Interface_TextCacheCount = 0;
end

function WoWeuCN_Interface_CachedTranslate(text)
  local cached = WoWeuCN_Interface_TextCache[text];
  if (cached ~= nil) then
    return cached or nil;
  end
  local translated = WoWeuCN_Interface_TranslateText(text);
  if (WoWeuCN_Interface_TextCacheCount >= WoWeuCN_Interface_TextCacheLimit) then
    WoWeuCN_Interface_ClearTextCache();
  end
  WoWeuCN_Interface_TextCache[text] = translated or false;
  WoWeuCN_Interface_TextCacheCount = WoWeuCN_Interface_TextCacheCount + 1;
  return translated;
end

local function WoWeuCN_Interface_ExpandPlurals(s)
  local variants = { s };
  while true do
    local expanded = false;
    local out = {};
    for i = 1, #variants do
      local v = variants[i];
      local pre, body, post = string.match(v, "^(.-)|4([^;]*);(.*)$");
      if (pre) then
        expanded = true;

        local forms = {};
        local start = 1;
        while true do
          local colon = string.find(body, ":", start, true);
          if (colon) then
            forms[#forms + 1] = string.sub(body, start, colon - 1);
            start = colon + 1;
          else
            forms[#forms + 1] = string.sub(body, start);
            break;
          end
        end
        if (#forms < 2 or #forms > 3) then
          return nil;
        end
        for f = 1, #forms do
          out[#out + 1] = pre .. forms[f] .. post;
        end
      else
        out[#out + 1] = v;
      end
    end
    variants = out;
    if (not expanded) then
      break;
    end
    if (#variants > 9) then
      return nil;
    end
  end
  for i = 1, #variants do
    if (string.find(variants[i], "|4", 1, true)) then
      return nil;
    end
  end
  return variants;
end

local function WoWeuCN_Interface_AddCompiledEntry(en, zh)
  local ok, entry = pcall(WoWeuCN_Interface_CompilePatternEntry, en, zh);
  if (ok and entry) then
    WoWeuCN_Interface_PendingEntries[#WoWeuCN_Interface_PendingEntries + 1] = entry;
  end
end

local function WoWeuCN_Interface_FinishPatternBuckets()
  local pending = WoWeuCN_Interface_PendingEntries;
  local freq = {};
  for i = 1, #pending do
    for word in pairs(pending[i].words) do
      freq[word] = (freq[word] or 0) + 1;
    end
  end
  for i = 1, #pending do
    local entry = pending[i];
    local best = nil;
    for word in pairs(entry.words) do
      if (best == nil or freq[word] < freq[best]
          or (freq[word] == freq[best] and (string.len(word) > string.len(best)
            or (string.len(word) == string.len(best) and word < best)))) then
        best = word;
      end
    end
    entry.words = nil;
    local bucket = WoWeuCN_Interface_PatternBuckets[best];
    if (not bucket) then
      bucket = {};
      WoWeuCN_Interface_PatternBuckets[best] = bucket;
    end
    bucket[#bucket + 1] = entry;
    WoWeuCN_Interface_PatternCount = WoWeuCN_Interface_PatternCount + 1;
  end
  for _, bucket in pairs(WoWeuCN_Interface_PatternBuckets) do
    table.sort(bucket, function(a, b)
      if (a.litLen ~= b.litLen) then
        return a.litLen > b.litLen;
      end
      return a.pat < b.pat;
    end);
  end
  WoWeuCN_Interface_PendingEntries = {};
end

local function WoWeuCN_Interface_AddPatternEntry(en, zh)
  if (string.find(en, "|4", 1, true) or string.find(zh, "|4", 1, true)) then
    local enVariants = WoWeuCN_Interface_ExpandPlurals(en);
    if (not enVariants) then
      return;
    end
    local zhFlat = string.gsub(zh, "|4([^:;]*)[^;]*;", "%1");
    for i = 1, #enVariants do
      WoWeuCN_Interface_AddCompiledEntry(enVariants[i], zhFlat);
    end
    return;
  end
  WoWeuCN_Interface_AddCompiledEntry(en, zh);
end

function WoWeuCN_Interface_BuildReverseMap()
  if (type(WoWeuCN_Interface_GS) ~= "table") then
    return 0;
  end
  WoWeuCN_Interface_PatternBuckets = {};
  WoWeuCN_Interface_ClearTextCache();
  local chosenKey = {};
  local count = 0;
  for key, translated in pairs(WoWeuCN_Interface_GS) do
    local original = rawget(_G, key);
    if (type(original) == "string" and original ~= translated) then
      local existing = chosenKey[original];
      if (existing == nil) then
        WoWeuCN_Interface_Reverse[original] = translated;
        chosenKey[original] = key;
        count = count + 1;
      else
        local newPri = WoWeuCN_Interface_PreferredKeys[key] or 0;
        local oldPri = WoWeuCN_Interface_PreferredKeys[existing] or 0;
        if (newPri == oldPri) then
          local canonical = string.gsub(string.gsub(string.upper(original), "[^%w]+", "_"), "^_*(.-)_*$", "%1");
          if (key == canonical) then
            newPri = newPri + 0.5;
          elseif (existing == canonical) then
            oldPri = oldPri + 0.5;
          end
        end
        if (newPri > oldPri or (newPri == oldPri and key < existing)) then
          WoWeuCN_Interface_Reverse[original] = translated;
          chosenKey[original] = key;
        end
      end
    end
  end
  local blockedPatternSources = {};
  for i = 1, #WoWeuCN_Interface_PatternBlockedKeys do
    local blockedValue = rawget(_G, WoWeuCN_Interface_PatternBlockedKeys[i]);
    if (type(blockedValue) == "string") then
      blockedPatternSources[blockedValue] = true;
    end
  end
  for original, translated in pairs(WoWeuCN_Interface_Reverse) do
    if (string.find(original, "%", 1, true) and not blockedPatternSources[original]) then
      WoWeuCN_Interface_AddPatternEntry(original, translated);
    end
  end
  WoWeuCN_Interface_FinishPatternBuckets();
  for i = 1, #WoWeuCN_Interface_ContextSpecs do
    local spec = WoWeuCN_Interface_ContextSpecs[i];
    local original = rawget(_G, spec.key);
    local translated = WoWeuCN_Interface_GS[spec.key];
    if (type(original) == "string" and type(translated) == "string"
        and translated ~= original and WoWeuCN_Interface_Reverse[original] ~= translated) then
      WoWeuCN_Interface_ContextOverrides[original] = { roots = spec.roots, translated = translated };
    end
  end
  local upperSource = {};
  for original, translated in pairs(WoWeuCN_Interface_Reverse) do
    local upper = string.upper(original);
    if (upper ~= original and WoWeuCN_Interface_Reverse[upper] == nil) then
      local existing = upperSource[upper];
      if (existing == nil or original < existing) then
        upperSource[upper] = original;
        WoWeuCN_Interface_ReverseUpper[upper] = translated;
      end
    end
  end
  local lowerSource = {};
  for original, translated in pairs(WoWeuCN_Interface_Reverse) do
    local lower = string.lower(original);
    local existing = lowerSource[lower];
    if (existing == nil or original == lower or (existing ~= lower and original < existing)) then
      lowerSource[lower] = original;
      WoWeuCN_Interface_ReverseLower[lower] = translated;
    end
  end
  WoWeuCN_Interface_GS = nil;
  return count;
end

function WoWeuCN_Interface_ApplyFonts()
  if (not WoWeuCN_Interface_N_PS or not WoWeuCN_Interface_Initialized) then
    return;
  end
  if (WoWeuCN_Interface_N_PS["active"] == "0" or WoWeuCN_Interface_N_PS["transfont"] == "0") then
    return;
  end
  if (type(GetFonts) ~= "function") then
    return;
  end
  local fonts = GetFonts();
  for i = 1, #fonts do
    local name = fonts[i];
    if (type(name) == "string" and not WoWeuCN_Interface_FontsDone[name]) then
      WoWeuCN_Interface_FontsDone[name] = true;
      local fontObject = _G[name];
      if (type(fontObject) == "table" and fontObject.GetFont and fontObject.SetFont) then
        local ok, file, height, flags = pcall(fontObject.GetFont, fontObject);
        if (ok and height and height > 0 and file ~= WoWeuCN_Interface_Font1) then
          pcall(fontObject.SetFont, fontObject, WoWeuCN_Interface_Font1, height, flags or "");
        end
      end
    end
  end

  STANDARD_TEXT_FONT = WoWeuCN_Interface_Font1;
  DAMAGE_TEXT_FONT = WoWeuCN_Interface_Font1;

  for i = 1, (NUM_CHAT_WINDOWS or 10) do
    local chatFrame = _G["ChatFrame" .. i];
    if (chatFrame and chatFrame.GetFont and chatFrame.SetFont) then
      local ok, _, height, flags = pcall(chatFrame.GetFont, chatFrame);
      if (ok and height and height > 0) then
        pcall(chatFrame.SetFont, chatFrame, WoWeuCN_Interface_Font1, height, flags or "");
      end
    end
  end
end

local function WoWeuCN_Interface_IsInExcludedFrame(frame)

  local tracker = _G["ObjectiveTrackerFrame"];
  local parent = frame;
  local depth = 0;
  while (parent and depth < 20) do
    if (tracker and parent == tracker) then
      return true;
    end
    if (parent.GetObjectType and parent:GetObjectType() == "GameTooltip") then

      return true;
    end
    local name = parent.GetName and parent:GetName();
    if (name and (string.find(name, "CooldownViewer", 1, true)
        or name == "BuffFrame" or name == "DebuffFrame"
        or string.find(name, "CastingBar", 1, true)
        or string.find(name, "Tooltip", 1, true))) then
      return true;
    end
    parent = parent:GetParent();
    depth = depth + 1;
  end
  return false;
end

local function WoWeuCN_Interface_ResolveContext(fontString, text)
  local override = WoWeuCN_Interface_ContextOverrides[text];
  if (not override) then
    return nil;
  end
  local parent = fontString:GetParent();
  local depth = 0;
  while (parent and depth < 20) do
    local name = parent.GetName and parent:GetName();
    if (name and override.roots[name]) then
      return override.translated;
    end
    parent = parent:GetParent();
    depth = depth + 1;
  end
  return nil;
end

local function WoWeuCN_Interface_AddDbText(map, text, zh, id)
  if (type(text) ~= "string" or text == "") then
    return;
  end
  if (type(zh) == "string" and zh ~= "") then
    map[text] = zh;
  elseif (map[text] == nil and type(id) == "number" and id > 0) then
    map[text] = false;
  end
end

local function WoWeuCN_Interface_BuildSkillText()
  local map = {};
  local lines = WoWeuCN_Interface_SkillLines;
  local categories = WoWeuCN_Interface_SkillCategories or {};
  local count = C_SkillInfo.GetNumSkillLines() or 0;
  for i = 1, count do
    local ok, info = pcall(C_SkillInfo.GetSkillLineInfo, i);
    if (ok and type(info) == "table") then
      if (info.isHeader and not info.isChild) then
        WoWeuCN_Interface_AddDbText(map, info.name, categories[info.skillID], info.skillID);
      else
        local entry = lines[info.skillID] or {};
        WoWeuCN_Interface_AddDbText(map, info.name, entry[1], info.skillID);
        WoWeuCN_Interface_AddDbText(map, info.description, entry[2], info.skillID);
      end
    end
  end
  return map;
end

local function WoWeuCN_Interface_BuildFactionText()
  local map = {};
  local factions = WoWeuCN_Interface_Factions;
  local count = C_Reputation.GetNumFactions() or 0;
  for i = 1, count do
    local ok, data = pcall(C_Reputation.GetFactionDataByIndex, i);
    if (ok and type(data) == "table") then
      local entry = factions[data.factionID] or {};
      WoWeuCN_Interface_AddDbText(map, data.name, entry[1], data.factionID);
      WoWeuCN_Interface_AddDbText(map, data.description, entry[2], data.factionID);
    end
  end
  return map;
end

local WoWeuCN_Interface_AuctionCategoryKeys = {
  "AUCTION_CATEGORY_ARMOR", "AUCTION_CATEGORY_BATTLE_PETS", "AUCTION_CATEGORY_CONSUMABLES",
  "AUCTION_CATEGORY_CONTAINERS", "AUCTION_CATEGORY_GEMS", "AUCTION_CATEGORY_GLYPHS",
  "AUCTION_CATEGORY_HOUSING", "AUCTION_CATEGORY_ITEM_ENHANCEMENT", "AUCTION_CATEGORY_MISCELLANEOUS",
  "AUCTION_CATEGORY_PROFESSION_EQUIPMENT", "AUCTION_CATEGORY_PROJECTILE", "AUCTION_CATEGORY_QUEST_ITEMS",
  "AUCTION_CATEGORY_RECIPES", "AUCTION_CATEGORY_TRADE_GOODS", "AUCTION_CATEGORY_WEAPONS",
  "TOKEN_FILTER_LABEL",
};

local function WoWeuCN_Interface_BuildSubClassText()
  local map = {};
  local blocked = {};
  for i = 1, #WoWeuCN_Interface_AuctionCategoryKeys do
    local value = rawget(_G, WoWeuCN_Interface_AuctionCategoryKeys[i]);
    if (type(value) == "string") then
      blocked[value] = true;
    end
  end
  local getInfo = (C_Item and C_Item.GetItemSubClassInfo) or GetItemSubClassInfo;
  local rows = WoWeuCN_Interface_ItemSubClasses;
  for i = 1, #rows do
    local row = rows[i];
    local ok, text = pcall(getInfo, row[1], row[2]);
    if (ok and type(text) == "string" and text ~= "" and not blocked[text]) then
      local zh;
      if (text == row[3]) then
        zh = row[5];
      elseif (text == row[4]) then
        zh = row[6];
      elseif (row[6] ~= "") then
        zh = row[6];
      else
        zh = row[5];
      end
      if (map[text] == nil or map[text] == false) then
        WoWeuCN_Interface_AddDbText(map, text, zh, 1);
      end
    end
  end
  return map;
end

local function WoWeuCN_Interface_BuildMapText()
  local map = {};
  local function add(text, zh)
    if (type(text) == "string" and text ~= "" and type(zh) == "string" and zh ~= "" and map[text] == nil) then
      map[text] = zh;
    end
  end
  local maps = WoWeuCN_Interface_UiMaps;
  if (type(C_Map.GetMapInfo) == "function") then
    for i = 1, #maps do
      local ok, info = pcall(C_Map.GetMapInfo, maps[i][1]);
      if (ok and type(info) == "table") then
        add(info.name, maps[i][2]);
      end
    end
  end
  local areas = WoWeuCN_Interface_Areas;
  if (type(areas) == "table" and type(C_Map.GetAreaInfo) == "function") then
    for i = 1, #areas do
      local ok, name = pcall(C_Map.GetAreaInfo, areas[i][1]);
      if (ok) then
        add(name, areas[i][2]);
      end
    end
  end
  local sorts = WoWeuCN_Interface_QuestSorts;
  if (type(sorts) == "table") then
    for i = 1, #sorts do
      add(sorts[i][1], sorts[i][2]);
    end
  end
  return map;
end

local WoWeuCN_Interface_SpellNames = nil;

local function WoWeuCN_Interface_GetSpellNameMap()
  if (WoWeuCN_Interface_SpellNames) then
    return WoWeuCN_Interface_SpellNames;
  end
  local map = {};
  local getSpellName = (C_Spell and C_Spell.GetSpellName) or GetSpellInfo;
  local spells = WoWeuCN_Interface_SkillSpells;
  if (type(getSpellName) == "function" and type(spells) == "table") then
    for i = 1, #spells do
      local ok, name = pcall(getSpellName, spells[i][1]);
      if (ok and type(name) == "string" and name ~= "" and map[name] == nil
          and not (issecretvalue and issecretvalue(name))) then
        map[name] = spells[i][2];
      end
    end
  end
  WoWeuCN_Interface_SpellNames = map;
  return map;
end

local WoWeuCN_Interface_StaticProfessionText = nil;

local function WoWeuCN_Interface_BuildStaticProfessionText()
  local map = {};
  local function add(text, zh)
    if (type(text) == "string" and text ~= "" and type(zh) == "string" and zh ~= "" and map[text] == nil) then
      map[text] = zh;
    end
  end
  for text, zh in pairs(WoWeuCN_Interface_GetSpellNameMap()) do
    add(text, zh);
  end
  local displayName = C_TradeSkillUI.GetTradeSkillDisplayName;
  local lines = WoWeuCN_Interface_SkillLines;
  if (type(displayName) == "function" and type(lines) == "table") then
    for id, entry in pairs(lines) do
      local ok, name = pcall(displayName, id);
      if (ok) then
        add(name, entry[1]);
      end
    end
  end
  local byText = { WoWeuCN_Interface_TotemCategories, WoWeuCN_Interface_SpellFocusObjects };
  for i = 1, #byText do
    local rows = byText[i];
    if (type(rows) == "table") then
      for j = 1, #rows do
        add(rows[j][1], rows[j][2]);
      end
    end
  end
  return map;
end

local function WoWeuCN_Interface_BuildProfessionText()
  if (not WoWeuCN_Interface_StaticProfessionText) then
    WoWeuCN_Interface_StaticProfessionText = WoWeuCN_Interface_BuildStaticProfessionText();
  end
  local map = {};
  local categories = WoWeuCN_Interface_TradeSkillCategories;
  if (type(C_TradeSkillUI.GetCategoryInfo) == "function") then
    for i = 1, #categories do
      local ok, info = pcall(C_TradeSkillUI.GetCategoryInfo, categories[i][1]);
      if (ok and type(info) == "table" and type(info.name) == "string" and info.name ~= ""
          and map[info.name] == nil) then
        map[info.name] = categories[i][2];
      end
    end
  end
  for text, zh in pairs(WoWeuCN_Interface_StaticProfessionText) do
    if (map[text] == nil) then
      map[text] = zh;
    end
  end
  return map;
end

local function WoWeuCN_Interface_BuildSpellBookText()
  local map = {};
  for text, zh in pairs(WoWeuCN_Interface_GetSpellNameMap()) do
    map[text] = zh;
  end
  local lines = WoWeuCN_Interface_SpellBookSkillLines;
  if (type(lines) == "table") then
    for i = 1, #lines do
      if (map[lines[i][1]] == nil) then
        map[lines[i][1]] = lines[i][2];
      end
    end
  end
  return map;
end

local function WoWeuCN_Interface_TranslateNameList(map, list)
  local parts = {};
  local start = 1;
  while (true) do
    local sepStart, sepEnd = string.find(list, ", ", start, true);
    local item = string.sub(list, start, (sepStart or 0) - 1);
    local open, inner, close = string.match(item, "^(|c%x%x%x%x%x%x%x%x)(.-)(|r)$");
    local zh = map[inner or item];
    if (type(zh) ~= "string") then
      return nil;
    end
    parts[#parts + 1] = open and (open .. zh .. close) or zh;
    if (not sepStart) then
      break;
    end
    start = sepEnd + 1;
  end
  return table.concat(parts, "，");
end

local function WoWeuCN_Interface_ComposeProfessionText(map, text)
  local en = rawget(_G, "PROFESSIONS_REQUIRED_TOOLS");
  local zh = type(en) == "string" and WoWeuCN_Interface_Reverse[en];
  if (type(en) ~= "string" or type(zh) ~= "string") then
    return nil;
  end
  local prefix = string.match(en, "^(.-)%%s$");
  local zhPrefix = string.match(zh, "^(.-)%%s$");
  if (not prefix or not zhPrefix or prefix == "" or string.sub(text, 1, string.len(prefix)) ~= prefix) then
    return nil;
  end
  local list = WoWeuCN_Interface_TranslateNameList(map, string.sub(text, string.len(prefix) + 1));
  return list and (zhPrefix .. list);
end

local WoWeuCN_Interface_DbContexts = {
  { roots = { "SkillsFrame" }, data = "SkillLines", api = "C_SkillInfo", build = WoWeuCN_Interface_BuildSkillText,
    event = "SKILL_LINES_CHANGED" },
  { roots = { "ReputationFrame" }, data = "Factions", api = "C_Reputation", build = WoWeuCN_Interface_BuildFactionText,
    event = "UPDATE_FACTION" },
  { roots = { "AuctionHouseFrame" }, data = "ItemSubClasses", build = WoWeuCN_Interface_BuildSubClassText },
  { roots = { "WorldMapFrame", "QuestMapFrame", "BattlefieldMapFrame", "MinimapCluster", "ZoneTextFrame",
      "SubZoneTextFrame" }, data = "UiMaps", api = "C_Map", build = WoWeuCN_Interface_BuildMapText },
  { roots = { "ProfessionsFrame" }, data = "SkillSpells", api = "C_TradeSkillUI",
    build = WoWeuCN_Interface_BuildProfessionText, event = "TRADE_SKILL_LIST_UPDATE",
    compose = WoWeuCN_Interface_ComposeProfessionText, names = true },
  { roots = { "PlayerSpellsFrame" }, data = "SkillSpells", api = "C_Spell",
    build = WoWeuCN_Interface_BuildSpellBookText, names = true },
};

local function WoWeuCN_Interface_DbMapGet(map, text, context)
  local value = map[text];
  if (value ~= nil) then
    return value;
  end
  local open, inner, close = string.match(text, "^(|c%x%x%x%x%x%x%x%x)(.-)(|r)$");
  if (inner and type(map[inner]) == "string") then
    return open .. map[inner] .. close;
  end
  if (context and context.compose) then
    local composed = context.compose(map, text);
    if (composed) then
      return composed;
    end
  end
  local core, suffix = string.match(text, "^(.-)(|c%x%x%x%x%x%x%x%x%s*%(.*)$");
  if (core and core ~= "") then
    local zh = map[core];
    if (zh) then
      return zh .. suffix;
    end
  end
  return nil;
end

local function WoWeuCN_Interface_DbContextRoot(context)
  for i = 1, #context.roots do
    local root = _G[context.roots[i]];
    if (root) then
      return root;
    end
  end
  return nil;
end

local function WoWeuCN_Interface_DbContextVisible(context)
  for i = 1, #context.roots do
    local root = _G[context.roots[i]];
    if (root and root.IsVisible and root:IsVisible()) then
      return true;
    end
  end
  return false;
end

local function WoWeuCN_Interface_IsUnderDbRoot(fontString, context)
  local parent = fontString:GetParent();
  local depth = 0;
  while (parent and depth < 20) do
    for i = 1, #context.roots do
      if (parent == _G[context.roots[i]]) then
        return true;
      end
    end
    local nextParent = parent:GetParent();
    if (type(parent.GetOwnerRegion) == "function") then
      local ok, owner = pcall(parent.GetOwnerRegion, parent);
      if (ok and owner) then
        nextParent = owner;
      end
    end
    parent = nextParent;
    depth = depth + 1;
  end
  return false;
end

function WoWeuCN_Interface_MarkDbTextDirty(event)
  for i = 1, #WoWeuCN_Interface_DbContexts do
    local context = WoWeuCN_Interface_DbContexts[i];
    if (event == nil or context.event == event) then
      context.dirty = true;
    end
  end
end

function WoWeuCN_Interface_GetDbTextEvents()
  local events = {};
  for i = 1, #WoWeuCN_Interface_DbContexts do
    local context = WoWeuCN_Interface_DbContexts[i];
    if (context.event and type(_G["WoWeuCN_Interface_" .. context.data]) == "table") then
      events[#events + 1] = context.event;
    end
  end
  return events;
end

local function WoWeuCN_Interface_DbContextMap(context)
  if (context.disabled) then
    return nil;
  end
  if (type(_G["WoWeuCN_Interface_" .. context.data]) ~= "table"
      or (context.api and type(_G[context.api]) ~= "table")) then
    return nil;
  end
  if (not WoWeuCN_Interface_DbContextRoot(context)) then
    return nil;
  end
  if (not context.map or (context.dirty and WoWeuCN_Interface_DbContextVisible(context))) then
    local ok, map = pcall(context.build);
    if (not ok or type(map) ~= "table") then
      context.disabled = true;
      return nil;
    end
    context.map = map;
    context.dirty = false;
  end
  return context.map;
end

local function WoWeuCN_Interface_DbTextKnown(text)
  for i = 1, #WoWeuCN_Interface_DbContexts do
    local context = WoWeuCN_Interface_DbContexts[i];
    local map = WoWeuCN_Interface_DbContextMap(context);
    if (map and WoWeuCN_Interface_DbMapGet(map, text, context) ~= nil) then
      return true;
    end
  end
  return false;
end

local function WoWeuCN_Interface_ResolveDbText(fontString, text)
  for i = 1, #WoWeuCN_Interface_DbContexts do
    local context = WoWeuCN_Interface_DbContexts[i];
    local map = WoWeuCN_Interface_DbContextMap(context);
    local value = map and WoWeuCN_Interface_DbMapGet(map, text, context);
    if (value ~= nil and WoWeuCN_Interface_IsUnderDbRoot(fontString, context)) then
      return value, context.names;
    end
  end
  return nil;
end

local function WoWeuCN_Interface_IsTitleRegion(fontString)
  local paperDoll = _G["PaperDollFrame"];
  local titlePane = paperDoll and paperDoll.TitleManagerPane;
  local parent = fontString:GetParent();
  local depth = 0;
  while (parent and depth < 20) do
    if (titlePane and parent == titlePane) then
      return true;
    end
    local name = parent.GetName and parent:GetName();
    if (name == "PlayerTitleDropdown") then
      return true;
    end
    if (type(parent.GetOwnerRegion) == "function") then
      local ok, owner = pcall(parent.GetOwnerRegion, parent);
      if (ok and owner and owner.GetName and owner:GetName() == "PlayerTitleDropdown") then
        return true;
      end
    end
    parent = parent:GetParent();
    depth = depth + 1;
  end
  return false;
end

local function WoWeuCN_Interface_IsNameRegion(fontString)
  local fsName = fontString.GetName and fontString:GetName();
  if (fsName) then
    for i = 1, #WoWeuCN_Interface_NameFontStrings do
      if (string.find(fsName, WoWeuCN_Interface_NameFontStrings[i])) then
        return true;
      end
    end
  end
  local parent = fontString:GetParent();
  if (not parent) then
    return false;
  end
  if ((parent.Name == fontString or parent.Text == fontString) and parent.NameFrame ~= nil) then
    return true;
  end
  if (parent.Name == fontString and (parent.ItemButton or parent.Button or parent.IconFrame or parent.SubName)) then
    return true;
  end
  if (parent.ItemName == fontString) then
    return true;
  end
  if (parent.Text == fontString and parent.IconBorder ~= nil) then
    return true;
  end
  if (parent.name == fontString and (parent.icon or parent.IconBorder)) then
    return true;
  end
  if (parent.Label == fontString and (parent.SkillUps or parent.LockedIcon)) then
    return true;
  end
  if (parent.OutputText == fontString or parent.RecraftingOutputText == fontString
      or parent.RecipeName == fontString or parent.RecraftRecipeName == fontString
      or parent.RewardName == fontString) then
    return true;
  end
  return false;
end

local function WoWeuCN_Interface_IsHotKeyRegion(fontString)
  local fsName = fontString.GetName and fontString:GetName();
  if (fsName and (string.find(fsName, "HotKey%d*$") or string.find(fsName, "Hotkey%d*$"))) then
    return true;
  end
  local parent = fontString:GetParent();
  if (parent and (parent.HotKey == fontString or parent.Hotkey == fontString
      or parent.hotKey == fontString or parent.hotkey == fontString)) then
    return true;
  end
  return false;
end

local function WoWeuCN_Interface_TranslateFontString(fontString)
  local text = fontString:GetText();
  if (issecretvalue and issecretvalue(text)) then
    return 0;
  end
  if (type(text) ~= "string" or string.len(text) < 2) then
    return 0;
  end
  local translated = WoWeuCN_Interface_ResolveContext(fontString, text);
  local isDbName = false;
  if (translated == nil) then
    local dbText, names = WoWeuCN_Interface_ResolveDbText(fontString, text);
    if (dbText == false) then
      return 0;
    end
    translated = dbText;
    isDbName = (dbText ~= nil and names == true);
  end
  if (translated == nil) then
    translated = WoWeuCN_Interface_CachedTranslate(text);
  end
  if (translated == nil) then
    return 0;
  end
  if (WoWeuCN_Interface_IsTitleRegion(fontString) or WoWeuCN_Interface_IsHotKeyRegion(fontString)
      or (not isDbName and WoWeuCN_Interface_IsNameRegion(fontString))) then
    return 0;
  end

  WoWeuCN_Interface_SuppressHook = true;
  local ok = pcall(fontString.SetText, fontString, translated);
  WoWeuCN_Interface_SuppressHook = false;
  if (not ok) then
    return 0;
  end
  return 1;
end

local function WoWeuCN_Interface_ProcessFrame(frame)
  if (frame.IsForbidden and frame:IsForbidden()) then
    return 0;
  end
  if (frame.IsProtected and frame:IsProtected()) then

    return 0;
  end
  if (frame:GetObjectType() == "EditBox") then
    return 0;
  end
  if (frame.GetNumRegions and frame:GetNumRegions() == 0) then
    return 0;
  end
  local count = 0;
  local excludedChecked = false;
  local regions = { frame:GetRegions() };
  for i = 1, #regions do
    local region = regions[i];
    if (region and region.IsObjectType and region:IsObjectType("FontString")) then
      if (not excludedChecked) then
        excludedChecked = true;
        if (WoWeuCN_Interface_IsInExcludedFrame(frame)) then
          return 0;
        end
      end
      local ok, n = pcall(WoWeuCN_Interface_TranslateFontString, region);
      if (ok and n) then
        count = count + n;
      end
    end
  end
  return count;
end

local WoWeuCN_Interface_FullScanActive = false;
local WoWeuCN_Interface_FullScanCursor = nil;
local WoWeuCN_Interface_FullScanTotal = 0;
local WoWeuCN_Interface_FullScanCallback = nil;
local WoWeuCN_Interface_FullScanBudgetMs = 12;
local WoWeuCN_Interface_FullScanMaxFrames = 5000;

local function WoWeuCN_Interface_ClockMs()
  if (type(GetTimePreciseSec) == "function") then
    return GetTimePreciseSec() * 1000;
  end
  if (type(debugprofilestop) == "function") then
    return debugprofilestop();
  end
  return 0;
end

function WoWeuCN_Interface_ScanExistingText(callback)
  if (not WoWeuCN_Interface_N_PS or WoWeuCN_Interface_N_PS["active"] == "0") then
    return false;
  end
  if (type(EnumerateFrames) ~= "function") then
    return false;
  end
  WoWeuCN_Interface_FullScanActive = true;
  WoWeuCN_Interface_FullScanCursor = nil;
  WoWeuCN_Interface_FullScanTotal = 0;
  WoWeuCN_Interface_FullScanCallback = callback;
  return true;
end

function WoWeuCN_Interface_IsFullScanActive()
  return WoWeuCN_Interface_FullScanActive;
end

local function WoWeuCN_Interface_FinishFullScan()
  local total = WoWeuCN_Interface_FullScanTotal;
  local callback = WoWeuCN_Interface_FullScanCallback;
  WoWeuCN_Interface_FullScanActive = false;
  WoWeuCN_Interface_FullScanCursor = nil;
  WoWeuCN_Interface_FullScanCallback = nil;
  if (type(callback) == "function") then
    pcall(callback, total);
  end
end

function WoWeuCN_Interface_FullScanStep(budgetMs, maxFrames)
  if (not WoWeuCN_Interface_FullScanActive) then
    return true;
  end
  if (InCombatLockdown()) then
    return false;
  end
  local deadline = WoWeuCN_Interface_ClockMs() + (budgetMs or WoWeuCN_Interface_FullScanBudgetMs);
  local limit = maxFrames or WoWeuCN_Interface_FullScanMaxFrames;
  local processed = 0;
  local cursor = WoWeuCN_Interface_FullScanCursor;
  while true do
    local frame = EnumerateFrames(cursor);
    if (not frame) then
      WoWeuCN_Interface_FinishFullScan();
      return true;
    end
    cursor = frame;
    WoWeuCN_Interface_FullScanCursor = cursor;
    local ok, n = pcall(WoWeuCN_Interface_ProcessFrame, frame);
    if (ok and n) then
      WoWeuCN_Interface_FullScanTotal = WoWeuCN_Interface_FullScanTotal + n;
      WoWeuCN_Interface_Swept = WoWeuCN_Interface_Swept + n;
    end
    processed = processed + 1;
    if (processed >= limit or WoWeuCN_Interface_ClockMs() >= deadline) then
      return false;
    end
  end
end

local function WoWeuCN_Interface_ReportRescan(total)
  print("WOWeuCN - Interface: 重新扫描完成, 本次修复 " .. total .. " 处界面文本.");
end

function WoWeuCN_Interface_RequestRescan()
  if (not WoWeuCN_Interface_ScanExistingText(WoWeuCN_Interface_ReportRescan)) then
    print("WOWeuCN - Interface: 翻译模块未启用, 无法重新扫描.");
    return false;
  end
  print("WOWeuCN - Interface: 正在重新扫描界面文本...");
  return true;
end

local WoWeuCN_Interface_PopupPassQueued = false;

local function WoWeuCN_Interface_QueuePopupPass()
  WoWeuCN_Interface_PopupPassQueued = true;
end

local function WoWeuCN_Interface_PopupTranslationPass()
  for i = 1, (STATICPOPUP_NUMDIALOGS or 4) do
    local dialog = _G["StaticPopup" .. i];
    if (dialog and dialog:IsShown()) then
      if (dialog.text) then
        pcall(WoWeuCN_Interface_TranslateFontString, dialog.text);
      end
      for j = 1, 4 do
        local button = _G["StaticPopup" .. i .. "Button" .. j];
        if (button and button:IsShown() and button.GetFontString) then
          local label = button:GetFontString();
          if (label) then
            pcall(WoWeuCN_Interface_TranslateFontString, label);
          end
        end
      end
    end
  end
end

local WoWeuCN_Interface_GameMenuPassQueued = false;

local function WoWeuCN_Interface_QueueGameMenuPass()
  WoWeuCN_Interface_GameMenuPassQueued = true;
end

local function WoWeuCN_Interface_TranslateFrameTree(frame, depth)
  local ok, n = pcall(WoWeuCN_Interface_ProcessFrame, frame);
  local count = (ok and n) or 0;
  if (depth > 0) then
    local children = { frame:GetChildren() };
    for i = 1, #children do
      count = count + WoWeuCN_Interface_TranslateFrameTree(children[i], depth - 1);
    end
  end
  return count;
end

local function WoWeuCN_Interface_GameMenuTranslationPass()
  local menu = _G["GameMenuFrame"];
  if (menu and menu:IsShown()) then
    WoWeuCN_Interface_TranslateFrameTree(menu, 4);
  end
end

local WoWeuCN_Interface_PanelQueue = {};

local WoWeuCN_Interface_PanelHooked = false;
function WoWeuCN_Interface_InitPanelHook()
  if (WoWeuCN_Interface_PanelHooked) then
    return;
  end
  if (WoWeuCN_Interface_N_PS["active"] == "0") then
    return;
  end
  if (type(ShowUIPanel) ~= "function") then
    return;
  end
  WoWeuCN_Interface_PanelHooked = true;
  hooksecurefunc("ShowUIPanel", function(frame)
    if (type(frame) == "table" and #WoWeuCN_Interface_PanelQueue < 8) then
      WoWeuCN_Interface_PanelQueue[#WoWeuCN_Interface_PanelQueue + 1] = frame;
    end
  end);
end

local WoWeuCN_Interface_GameMenuHooked = false;
function WoWeuCN_Interface_InitGameMenuHook()
  if (WoWeuCN_Interface_GameMenuHooked) then
    return;
  end

  if (WoWeuCN_Interface_N_PS["active"] == "0") then
    return;
  end
  local menu = _G["GameMenuFrame"];
  if (not menu or not menu.HookScript) then
    return;
  end
  WoWeuCN_Interface_GameMenuHooked = true;

  menu:HookScript("OnShow", WoWeuCN_Interface_QueueGameMenuPass);
end

local WoWeuCN_Interface_ScanCursor = nil;
local WoWeuCN_Interface_ScanAccum = 0;

local function WoWeuCN_Interface_PeriodicPass()
  if (not WoWeuCN_Interface_Initialized or not WoWeuCN_Interface_N_PS) then
    return;
  end
  if (WoWeuCN_Interface_N_PS["active"] == "0") then
    return;
  end
  if (type(EnumerateFrames) ~= "function" or InCombatLockdown()) then
    return;
  end
  for i = 1, 1200 do
    local frame = EnumerateFrames(WoWeuCN_Interface_ScanCursor);
    WoWeuCN_Interface_ScanCursor = frame;
    if (not frame) then
      break;
    end
    if (frame:IsVisible()) then
      local ok, n = pcall(WoWeuCN_Interface_ProcessFrame, frame);
      if (ok and n) then
        WoWeuCN_Interface_Swept = WoWeuCN_Interface_Swept + n;
      end
    end
  end
end

local WoWeuCN_Interface_LiveQueue = {};
local WoWeuCN_Interface_LiveQueued = {};
local WoWeuCN_Interface_LiveQueueHead = 1;
local WoWeuCN_Interface_LiveQueueCount = 0;
local WoWeuCN_Interface_LiveQueueMax = 5000;
local WoWeuCN_Interface_LiveBudgetMs = 6;

local function WoWeuCN_Interface_IsLiveCandidate(text)
  if (issecretvalue and issecretvalue(text)) then
    return false;
  end
  return type(text) == "string" and string.len(text) >= 2 and string.find(text, "[^%s%p%d%c]") ~= nil;
end

local function WoWeuCN_Interface_EnqueueLive(fontString)
  if (WoWeuCN_Interface_LiveQueued[fontString]) then
    return;
  end
  if (WoWeuCN_Interface_LiveQueueCount - WoWeuCN_Interface_LiveQueueHead + 1 >= WoWeuCN_Interface_LiveQueueMax) then
    return;
  end
  WoWeuCN_Interface_LiveQueued[fontString] = true;
  WoWeuCN_Interface_LiveQueueCount = WoWeuCN_Interface_LiveQueueCount + 1;
  WoWeuCN_Interface_LiveQueue[WoWeuCN_Interface_LiveQueueCount] = fontString;
end

local function WoWeuCN_Interface_OnFontStringSetText(fontString, text)
  if (WoWeuCN_Interface_SuppressHook or not WoWeuCN_Interface_Initialized) then
    return;
  end
  if (not WoWeuCN_Interface_IsLiveCandidate(text)) then
    return;
  end
  if (fontString.IsForbidden and fontString:IsForbidden()) then
    return;
  end
  WoWeuCN_Interface_EnqueueLive(fontString);
end

local function WoWeuCN_Interface_OnButtonSetText(button, text)
  if (WoWeuCN_Interface_SuppressHook or not WoWeuCN_Interface_Initialized) then
    return;
  end
  if (not WoWeuCN_Interface_IsLiveCandidate(text)) then
    return;
  end
  if (button.IsForbidden and button:IsForbidden()) then
    return;
  end
  local fontString = button.GetFontString and button:GetFontString();
  if (fontString) then
    WoWeuCN_Interface_EnqueueLive(fontString);
  end
end

local function WoWeuCN_Interface_TranslateQueuedRegion(region)
  local text = region:GetText();
  if (issecretvalue and issecretvalue(text)) then
    return;
  end
  if (type(text) ~= "string" or string.len(text) < 2) then
    return;
  end
  if (not WoWeuCN_Interface_ContextOverrides[text] and not WoWeuCN_Interface_DbTextKnown(text)
      and not WoWeuCN_Interface_CachedTranslate(text)) then
    return;
  end
  local parent = region:GetParent();
  if (not parent) then
    return;
  end
  if (parent.IsForbidden and parent:IsForbidden()) then
    return;
  end
  if (parent.IsProtected and parent:IsProtected()) then
    return;
  end
  if (parent:GetObjectType() == "EditBox") then
    return;
  end
  if (WoWeuCN_Interface_IsInExcludedFrame(parent)) then
    return;
  end
  WoWeuCN_Interface_TranslateFontString(region);
end

function WoWeuCN_Interface_ProcessLiveQueue(budgetMs)
  if (WoWeuCN_Interface_LiveQueueHead > WoWeuCN_Interface_LiveQueueCount) then
    return true;
  end
  local deadline = WoWeuCN_Interface_ClockMs() + (budgetMs or WoWeuCN_Interface_LiveBudgetMs);
  local processed = 0;
  while (WoWeuCN_Interface_LiveQueueHead <= WoWeuCN_Interface_LiveQueueCount) do
    local i = WoWeuCN_Interface_LiveQueueHead;
    local region = WoWeuCN_Interface_LiveQueue[i];
    WoWeuCN_Interface_LiveQueue[i] = nil;
    WoWeuCN_Interface_LiveQueueHead = i + 1;
    if (region) then
      WoWeuCN_Interface_LiveQueued[region] = nil;
      pcall(WoWeuCN_Interface_TranslateQueuedRegion, region);
    end
    processed = processed + 1;
    if (processed % 32 == 0 and WoWeuCN_Interface_ClockMs() >= deadline) then
      break;
    end
  end
  if (WoWeuCN_Interface_LiveQueueHead > WoWeuCN_Interface_LiveQueueCount) then
    WoWeuCN_Interface_LiveQueueHead = 1;
    WoWeuCN_Interface_LiveQueueCount = 0;
    return true;
  end
  return false;
end

function WoWeuCN_Interface_GetLiveQueueSize()
  return WoWeuCN_Interface_LiveQueueCount - WoWeuCN_Interface_LiveQueueHead + 1;
end

local WoWeuCN_Interface_LiveHooked = false;
function WoWeuCN_Interface_InitLiveHook()
  if (WoWeuCN_Interface_LiveHooked) then
    return;
  end
  if (WoWeuCN_Interface_N_PS["active"] == "0") then
    return;
  end
  if (not UIParent or not UIParent.CreateFontString) then
    return;
  end
  local dummy = UIParent:CreateFontString();
  if (not dummy) then
    return;
  end
  local meta = getmetatable(dummy);
  local methods = meta and meta.__index;
  if (type(methods) ~= "table" or type(methods.SetText) ~= "function") then
    return;
  end
  WoWeuCN_Interface_LiveHooked = true;
  local hooked = {};
  local function hookMethods(widgetMethods, handler)
    if (type(widgetMethods) ~= "table" or hooked[widgetMethods] or type(widgetMethods.SetText) ~= "function") then
      return;
    end
    hooked[widgetMethods] = true;
    hooksecurefunc(widgetMethods, "SetText", handler);
    if (type(widgetMethods.SetFormattedText) == "function") then
      hooksecurefunc(widgetMethods, "SetFormattedText", handler);
    end
  end
  hookMethods(methods, WoWeuCN_Interface_OnFontStringSetText);

  local buttonTypes = { "Button", "CheckButton" };
  for i = 1, #buttonTypes do
    local ok, widget = pcall(CreateFrame, buttonTypes[i]);
    if (ok and widget) then
      local widgetMeta = getmetatable(widget);
      local widgetMethods = widgetMeta and widgetMeta.__index;
      if (widgetMethods ~= methods) then
        hookMethods(widgetMethods, WoWeuCN_Interface_OnButtonSetText);
      end
      if (widget.Hide) then
        widget:Hide();
      end
    end
  end
end

local WoWeuCN_Interface_Driver = CreateFrame("Frame");
WoWeuCN_Interface_Driver:SetScript("OnUpdate", function(self, elapsed)
  WoWeuCN_Interface_SuppressHook = false;
  WoWeuCN_Interface_ProcessLiveQueue(WoWeuCN_Interface_LiveBudgetMs);
  if (WoWeuCN_Interface_PopupPassQueued) then
    WoWeuCN_Interface_PopupPassQueued = false;
    pcall(WoWeuCN_Interface_PopupTranslationPass);
  end
  if (WoWeuCN_Interface_GameMenuPassQueued) then
    WoWeuCN_Interface_GameMenuPassQueued = false;
    pcall(WoWeuCN_Interface_GameMenuTranslationPass);
  end
  if (#WoWeuCN_Interface_PanelQueue > 0 and WoWeuCN_Interface_Initialized) then
    for i = 1, #WoWeuCN_Interface_PanelQueue do
      local panel = WoWeuCN_Interface_PanelQueue[i];
      WoWeuCN_Interface_PanelQueue[i] = nil;
      if (panel and panel.IsShown and panel:IsShown()) then
        pcall(WoWeuCN_Interface_TranslateFrameTree, panel, 6);
      end
    end
  end
  if (WoWeuCN_Interface_FullScanActive) then
    local ok = pcall(WoWeuCN_Interface_FullScanStep, WoWeuCN_Interface_FullScanBudgetMs, WoWeuCN_Interface_FullScanMaxFrames);
    if (not ok) then
      WoWeuCN_Interface_FullScanActive = false;
      WoWeuCN_Interface_FullScanCallback = nil;
    end
    WoWeuCN_Interface_ScanAccum = 0;
  else
    WoWeuCN_Interface_ScanAccum = WoWeuCN_Interface_ScanAccum + (elapsed or 0);
    if (WoWeuCN_Interface_ScanAccum >= 0.4) then
      WoWeuCN_Interface_ScanAccum = 0;
      pcall(WoWeuCN_Interface_PeriodicPass);
    end
  end
end);

local WoWeuCN_Interface_PopupHooked = false;
function WoWeuCN_Interface_InitPopupHook()
  if (WoWeuCN_Interface_PopupHooked) then
    return;
  end

  if (WoWeuCN_Interface_N_PS["active"] == "0") then
    return;
  end
  if (type(StaticPopup_Show) ~= "function") then
    return;
  end
  WoWeuCN_Interface_PopupHooked = true;
  hooksecurefunc("StaticPopup_Show", WoWeuCN_Interface_QueuePopupPass);
end

function WoWeuCN_Interface_CheckVars()
  if (not WoWeuCN_Interface_N_PS) then
    WoWeuCN_Interface_N_PS = {};
  end

  if (not WoWeuCN_Interface_N_PS["active"]) then
    WoWeuCN_Interface_N_PS["active"] = "1";
  end

  if (not WoWeuCN_Interface_N_PS["transfont"]) then
    WoWeuCN_Interface_N_PS["transfont"] = "0";
  end

  if (not WoWeuCN_Interface_N_PS["transmixed"]) then
    WoWeuCN_Interface_N_PS["transmixed"] = "0";
  end

  if (WoWeuCN_Interface_N_PS["optver"] ~= "4") then
    if (WoWeuCN_Interface_N_PS["optver"] ~= "2" and WoWeuCN_Interface_N_PS["optver"] ~= "3") then
      WoWeuCN_Interface_N_PS["transfont"] = "0";
    end
    WoWeuCN_Interface_N_PS["optver"] = "4";
  end

  WoWeuCN_Interface_N_PS["transglobal"] = nil;
  WoWeuCN_Interface_N_PS["transexisting"] = nil;
  WoWeuCN_Interface_N_PS["transpopup"] = nil;

  if (not WoWeuCN_Interface_N_PS["patch"]) then
    WoWeuCN_Interface_N_PS["patch"] = GetBuildInfo();
  end
end

function WoWeuCN_Interface_SlashCommand(msg)
  msg = string.lower(msg or "");
  if (msg == "on") then
    if (WoWeuCN_Interface_N_PS["active"] == "1") then
      print("WOWeuCN - Interface 翻译模块已启用.");
    else
      WoWeuCN_Interface_N_PS["active"] = "1";
      print("|cffffff00WOWeuCN - Interface 翻译模块已启用, 输入 /reload 完全生效.");
      if (not InCombatLockdown()) then
        WoWeuCN_Interface_BuildReverseMap();
        WoWeuCN_Interface_ApplyFonts();
        WoWeuCN_Interface_ScanExistingText();
        WoWeuCN_Interface_InitPopupHook();
        WoWeuCN_Interface_InitGameMenuHook();
      end
    end
  elseif (msg == "off") then
    if (WoWeuCN_Interface_N_PS["active"] == "0") then
      print("WOWeuCN - Interface 翻译模块已关闭.");
    else
      WoWeuCN_Interface_N_PS["active"] = "0";
      print("|cffffff00WOWeuCN - Interface 翻译模块已关闭, 输入 /reload 完全生效.");
    end
  elseif (msg == "rescan") then
    WoWeuCN_Interface_RequestRescan();
  elseif (msg == "status") then
    local state = (WoWeuCN_Interface_N_PS["active"] == "1") and WoWeuCN_Interface_Messages.isactive or WoWeuCN_Interface_Messages.isinactive;
    print("WOWeuCN - Interface " .. state .. ": 已翻译 " .. WoWeuCN_Interface_Swept .. " 处界面文本.");
  elseif (msg == "") then
    if (Settings and Settings.OpenToCategory and WoWeuCN_Interface_SettingsCategory) then
      Settings.OpenToCategory(WoWeuCN_Interface_SettingsCategory:GetID());
    end
  else
    print("WOWeuCN-Interface - 指令说明:");
    print("      /woweucn-interface on     - 启用界面翻译模块");
    print("      /woweucn-interface off    - 禁用界面翻译模块");
    print("      /woweucn-interface rescan - 重新扫描并修复界面文本");
    print("      /woweucn-interface status - 显示当前状态");
  end
end

function WoWeuCN_Interface_SetCheckButtonState()
  WoWeuCN_InterfaceCheckButton0.Checkbox:SetChecked(WoWeuCN_Interface_N_PS["active"] == "1");
  WoWeuCN_InterfaceCheckButton1.Checkbox:SetChecked(WoWeuCN_Interface_N_PS["transfont"] == "1");
  WoWeuCN_InterfaceCheckButton2.Checkbox:SetChecked(WoWeuCN_Interface_N_PS["transmixed"] == "1");
end

local function WoWeuCN_Interface_CreateCheckButton(index, parent, anchorTo, offsetY, option, label)
  local button = CreateFrame("CheckButton", "WoWeuCN_InterfaceCheckButton" .. index, parent, "SettingsCheckBoxControlTemplate");
  button:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, offsetY);
  button.Checkbox:SetChecked(WoWeuCN_Interface_N_PS[option] == "1");
  button.Checkbox:SetScript("OnClick", function(self)
    if (WoWeuCN_Interface_N_PS[option] == "0") then
      WoWeuCN_Interface_N_PS[option] = "1";
    else
      WoWeuCN_Interface_N_PS[option] = "0";
    end
    WoWeuCN_Interface_ClearTextCache();
  end);
  button.Text:SetFont(WoWeuCN_Interface_Font2, 13);
  button:SetSize(850, 21);
  button.Text:SetText(label);
  return button;
end

function WoWeuCN_Interface_BlizzardOptions()
  local WoWeuCN_InterfaceOptions = CreateFrame("FRAME", "WoWeuCN_Interface_Options_Panel");
  WoWeuCN_InterfaceOptions.name = "WoWeuCN-Interface";
  WoWeuCN_InterfaceOptions.refresh = function(self) WoWeuCN_Interface_SetCheckButtonState() end;

  if InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(WoWeuCN_InterfaceOptions)
  elseif Settings and Settings.RegisterAddOnCategory and Settings.RegisterCanvasLayoutCategory then
    WoWeuCN_Interface_SettingsCategory = select(1, Settings.RegisterCanvasLayoutCategory(WoWeuCN_InterfaceOptions, WoWeuCN_InterfaceOptions.name));
    Settings.RegisterAddOnCategory(WoWeuCN_Interface_SettingsCategory);
  end

  local header = WoWeuCN_InterfaceOptions:CreateFontString(nil, "ARTWORK");
  header:SetFontObject(GameFontNormalLarge);
  header:SetJustifyH("LEFT");
  header:SetJustifyV("TOP");
  header:ClearAllPoints();
  header:SetPoint("TOPLEFT", 16, -16);
  header:SetText("WoWeuCN-Interface, ver. " .. WoWeuCN_Interface_version .. " (" .. WoWeuCN_Interface_base .. ") by qqytqqyt © 2026");
  header:SetFont(WoWeuCN_Interface_Font2, 16);

  local authorLine = WoWeuCN_InterfaceOptions:CreateFontString(nil, "ARTWORK");
  authorLine:SetFontObject(GameFontNormalLarge);
  authorLine:SetJustifyH("LEFT");
  authorLine:SetJustifyV("TOP");
  authorLine:ClearAllPoints();
  authorLine:SetPoint("TOPRIGHT", header, "TOPRIGHT", 0, -22);
  authorLine:SetText("作者 : " .. WoWeuCN_Interface_Messages.author);
  authorLine:SetFont(WoWeuCN_Interface_Font2, 16);

  local checkActive = CreateFrame("CheckButton", "WoWeuCN_InterfaceCheckButton0", WoWeuCN_InterfaceOptions, "SettingsCheckBoxControlTemplate");
  checkActive:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -44);
  checkActive.Checkbox:SetChecked(WoWeuCN_Interface_N_PS["active"] == "1");
  checkActive.Checkbox:SetScript("OnClick", function(self)
    if (WoWeuCN_Interface_N_PS["active"] == "1") then
      WoWeuCN_Interface_N_PS["active"] = "0";
    else
      WoWeuCN_Interface_N_PS["active"] = "1";
    end
  end);
  checkActive.Text:SetFont(WoWeuCN_Interface_Font2, 13);
  checkActive.Text:SetText(WoWeuCN_Interface_Options.active);

  local optionsLabel = WoWeuCN_InterfaceOptions:CreateFontString(nil, "ARTWORK");
  optionsLabel:SetFontObject(GameFontWhite);
  optionsLabel:SetJustifyH("LEFT");
  optionsLabel:SetJustifyV("TOP");
  optionsLabel:ClearAllPoints();
  optionsLabel:SetPoint("TOPLEFT", checkActive, "BOTTOMLEFT", 30, -20);
  optionsLabel:SetFont(WoWeuCN_Interface_Font2, 13);
  optionsLabel:SetText(WoWeuCN_Interface_Options.options1);

  local fontButton = WoWeuCN_Interface_CreateCheckButton(1, WoWeuCN_InterfaceOptions, optionsLabel, -5, "transfont", WoWeuCN_Interface_Options.transfont);
  local mixedButton = WoWeuCN_Interface_CreateCheckButton(2, WoWeuCN_InterfaceOptions, fontButton, -5, "transmixed", WoWeuCN_Interface_Options.transmixed);

  local reloadNote = WoWeuCN_InterfaceOptions:CreateFontString(nil, "ARTWORK");
  reloadNote:SetFontObject(GameFontWhite);
  reloadNote:SetJustifyH("LEFT");
  reloadNote:SetJustifyV("TOP");
  reloadNote:ClearAllPoints();
  reloadNote:SetPoint("TOPLEFT", mixedButton, "BOTTOMLEFT", 0, -20);
  reloadNote:SetFont(WoWeuCN_Interface_Font2, 13);
  reloadNote:SetText(WoWeuCN_Interface_Options.reloadnote);

  local rescanButton = CreateFrame("Button", "WoWeuCN_Interface_RescanButton", WoWeuCN_InterfaceOptions, "UIPanelButtonTemplate");
  rescanButton:SetSize(180, 24);
  rescanButton:SetPoint("TOPLEFT", reloadNote, "BOTTOMLEFT", 0, -15);
  rescanButton:SetText(WoWeuCN_Interface_Options.rescan);
  local rescanLabel = rescanButton.GetFontString and rescanButton:GetFontString();
  if (rescanLabel) then
    rescanLabel:SetFont(WoWeuCN_Interface_Font2, 13);
  end
  rescanButton:SetScript("OnClick", function()
    WoWeuCN_Interface_RequestRescan();
  end);
end

function WoWeuCN_Interface_BroadcastVersion()
  if (not C_ChatInfo or not C_ChatInfo.SendAddonMessage) then
    return;
  end
  if (C_ChatInfo.RegisterAddonMessagePrefix) then
    C_ChatInfo.RegisterAddonMessagePrefix(WoWeuCN_AddonPrefix);
  end
  local message = "WoWeuCN-Interface ver. " .. WoWeuCN_Interface_version .. " Loaded";
  if (GetGuildInfo and GetGuildInfo("player") ~= nil) then
    C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, message, "GUILD");
  end
  C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, message, "RAID");
  C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, message, "YELL");
end

function WoWeuCN_Interface_OnAddonMessage(prefix, text, channel, sender)
  if (prefix ~= WoWeuCN_AddonPrefix or type(text) ~= "string") then
    return;
  end
  if (text == "VERSION") then
    if (sender == nil) then
      C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, "WoWeuCN-Interface ver. " .. WoWeuCN_Interface_version, channel);
    else
      C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, "WoWeuCN-Interface ver. " .. WoWeuCN_Interface_version, channel, sender);
    end
  elseif (string.sub(text, 1, string.len("WoWeuCN-Interface")) == "WoWeuCN-Interface" and not WoWeuCN_Interface_VersionReminded) then
    local _, major, minor, revision = string.match(WoWeuCN_Interface_version, "^.-(%d+)%.(%d+)%.(%d+)%.(%d+)");
    local _, newMajor, newMinor, newRevision = string.match(text, "^.-(%d+)%.(%d+)%.(%d+)%.(%d+)");
    if (major and newMajor) then
      local newVersionNumber = tonumber(newMajor) * 10000 + tonumber(newMinor) * 100 + tonumber(newRevision);
      local myVersionNumber = tonumber(major) * 10000 + tonumber(minor) * 100 + tonumber(revision);
      if (newVersionNumber > myVersionNumber) then
        print("|cffffff00WoWeuCN-Interface有新版本，请及时在CurseForge或其他平台更新。|r");
        WoWeuCN_Interface_VersionReminded = true;
      end
    end
  end
end

function WoWeuCN_Interface_RunDeferredInit()
  if (WoWeuCN_Interface_N_PS["active"] == "1") then
    WoWeuCN_Interface_BuildReverseMap();
  end
  WoWeuCN_Interface_InitGameMenuHook();
  WoWeuCN_Interface_InitPanelHook();
  WoWeuCN_Interface_InitLiveHook();
  WoWeuCN_Interface_ApplyFonts();
  WoWeuCN_Interface_ScanExistingText();
  if (WoWeuCN_Interface_N_PS["active"] == "1") then
    print("|cffffff00WoWeuCN-Interface ver. " .. WoWeuCN_Interface_version .. " - " .. WoWeuCN_Interface_Messages.loaded .. " - |cffa335ee作者：" .. WoWeuCN_Interface_Messages.author .. "|r");
  end
  pcall(WoWeuCN_Interface_BroadcastVersion);
end

function WoWeuCN_Interface_OnEvent(self, event, arg1, arg2, arg3, arg4)
  if (WoWeuCN_Interface_onDebug) then
    print('OnEvent-event: ' .. event);
  end
  if (event == "ADDON_LOADED") then
    if (arg1 == "WoWeuCN_Interface") then
      SlashCmdList["WOWEUCN_INTERFACE"] = function(msg) WoWeuCN_Interface_SlashCommand(msg); end
      SLASH_WOWEUCN_INTERFACE1 = "/woweucn-interface";
      SLASH_WOWEUCN_INTERFACE2 = "/wcni";
      WoWeuCN_Interface_CheckVars();
      WoWeuCN_Interface_BlizzardOptions();
      WoWeuCN_Interface_InitPopupHook();
      WoWeuCN_Interface_InitGameMenuHook();

    else

      WoWeuCN_Interface_ApplyFonts();
    end
  elseif (event == "SKILL_LINES_CHANGED" or event == "UPDATE_FACTION" or event == "TRADE_SKILL_LIST_UPDATE") then
    WoWeuCN_Interface_MarkDbTextDirty(event);
  elseif (event == "CHAT_MSG_ADDON") then
    WoWeuCN_Interface_OnAddonMessage(arg1, arg2, arg3, arg4);
  elseif (event == "PLAYER_ENTERING_WORLD") then

    if ((arg1 or arg2) and not WoWeuCN_Interface_Initialized) then
      WoWeuCN_Interface_Initialized = true;

      C_Timer.After(2, WoWeuCN_Interface_RunDeferredInit);
    end
  end
end

function WoWeuCN_Interface_OnLoad()
  WoWeuCN_Interface = CreateFrame("Frame");

  local expInfo, _, _, _ = GetBuildInfo()
  local exp, major, minor = strsplit(".", expInfo)
  local myExp = string.match(WoWeuCN_Interface_version, "^.-(%d+)%.")
  local _, myMajor, myMinor = strsplit(".", WoWeuCN_Interface_version)
  if exp ~= myExp then
    print("|cffffff00WoWeuCN-Interface加载错误，请下载对应资料片版本的客户端。|r")
    return
  end
  if (tonumber(major) * 100 + tonumber(minor)) > (tonumber(myMajor) * 100 + tonumber(myMinor)) then
    print("|cffffff00WoWeuCN-Interface加载错误，请下载最新版本。|r")
    return
  end

  WoWeuCN_Interface:SetScript("OnEvent", WoWeuCN_Interface_OnEvent);
  WoWeuCN_Interface:RegisterEvent("ADDON_LOADED");
  WoWeuCN_Interface:RegisterEvent("PLAYER_ENTERING_WORLD");
  WoWeuCN_Interface:RegisterEvent("CHAT_MSG_ADDON");
  local dbEvents = WoWeuCN_Interface_GetDbTextEvents();
  for i = 1, #dbEvents do
    pcall(WoWeuCN_Interface.RegisterEvent, WoWeuCN_Interface, dbEvents[i]);
  end
end
