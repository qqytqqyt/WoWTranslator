-- Addon: WoWeuCN-Interface
-- Author: qqytqqyt

local WoWeuCN_Interface_version = C_AddOns.GetAddOnMetadata("WoWeuCN_Interface", "Version");
local WoWeuCN_Interface_onDebug = false;
local WoWeuCN_AddonPrefix = "WoWeuCN";
local WoWeuCN_Interface_VersionReminded = false;

WoWeuCN_Interface_Reverse = {};
local WoWeuCN_Interface_ReverseUpper = {};
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
  local indexWord = nil;
  for i = 1, #enPieces do
    local piece = enPieces[i];
    if (piece.lit) then
      pat = pat .. WoWeuCN_Interface_EscapePattern(piece.lit);
      for word in string.gmatch(piece.lit, WoWeuCN_Interface_WORD) do
        if (string.len(word) >= 3 and (not indexWord or string.len(word) > string.len(indexWord))) then
          indexWord = word;
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
  if (not indexWord) then
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
  return { pat = pat, out = out, word = indexWord };
end

function WoWeuCN_Interface_TryPatternTranslate(text)
  if (not WoWeuCN_Interface_PatternBuckets or string.len(text) > 300) then
    return nil;
  end
  local tried = 0;
  for word in string.gmatch(text, WoWeuCN_Interface_WORD) do
    local bucket = WoWeuCN_Interface_PatternBuckets[word];
    if (bucket) then
      for j = 1, #bucket do
        local entry = bucket[j];
        tried = tried + 1;
        if (tried > 40) then
          return nil;
        end
        local c1, c2, c3, c4, c5, c6, c7, c8 = string.match(text, entry.pat);
        if (c1 ~= nil) then
          local caps = { c1, c2, c3, c4, c5, c6, c7, c8 };
          local parts = {};
          for k = 1, #entry.out do
            local piece = entry.out[k];
            if (piece.lit) then
              parts[#parts + 1] = piece.lit;
            else
              parts[#parts + 1] = caps[piece.cap] or "";
            end
          end
          return table.concat(parts);
        end
      end
    end
  end
  return nil;
end

local function WoWeuCN_Interface_CoreTranslate(text)
  return WoWeuCN_Interface_Reverse[text] or WoWeuCN_Interface_ReverseUpper[text] or WoWeuCN_Interface_TryPatternTranslate(text);
end

function WoWeuCN_Interface_TryDecoratedTranslate(text)

  local colorOpen, inner, colorClose = string.match(text, "^(|c%x%x%x%x%x%x%x%x)(.-)(|r)$");
  if (inner and inner ~= "") then
    local translated = WoWeuCN_Interface_CoreTranslate(inner) or WoWeuCN_Interface_TryDecoratedTranslate(inner);
    if (translated) then
      return colorOpen .. translated .. colorClose;
    end
    return nil;
  end

  local head, colonTail = string.match(text, "^(.-)(%s*[:：]%s*)$");
  if (head and head ~= "") then
    local translated = WoWeuCN_Interface_CoreTranslate(head);
    if (translated) then
      return translated .. colonTail;
    end
  end

  local lead, mid, trail = string.match(text, "^(%s*)(.-)(%s*)$");
  if (mid and mid ~= text and mid ~= "") then
    local translated = WoWeuCN_Interface_CoreTranslate(mid);
    if (translated) then
      return lead .. translated .. trail;
    end
  end

  local beforeDots = string.match(text, "^(.-)%.%.%.$");
  if (beforeDots and beforeDots ~= "") then
    local translated = WoWeuCN_Interface_CoreTranslate(beforeDots);
    if (translated) then
      return translated .. "...";
    end
  end
  return nil;
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
    local bucket = WoWeuCN_Interface_PatternBuckets[entry.word];
    if (not bucket) then
      bucket = {};
      WoWeuCN_Interface_PatternBuckets[entry.word] = bucket;
    end
    bucket[#bucket + 1] = entry;
    WoWeuCN_Interface_PatternCount = WoWeuCN_Interface_PatternCount + 1;
  end
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
        if (newPri > oldPri or (newPri == oldPri and key < existing)) then
          WoWeuCN_Interface_Reverse[original] = translated;
          chosenKey[original] = key;
        end
      end
    end
  end
  for original, translated in pairs(WoWeuCN_Interface_Reverse) do
    if (string.find(original, "%", 1, true)) then
      WoWeuCN_Interface_AddPatternEntry(original, translated);
    end
  end
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

local function WoWeuCN_Interface_TranslateFontString(fontString)
  local text = fontString:GetText();
  if (issecretvalue and issecretvalue(text)) then
    return 0;
  end
  if (type(text) ~= "string" or text == "") then
    return 0;
  end
  local translated = WoWeuCN_Interface_ResolveContext(fontString, text);
  if (translated == nil) then
    translated = WoWeuCN_Interface_Reverse[text];
  end
  if (translated == nil) then
    translated = WoWeuCN_Interface_ReverseUpper[text];
  end
  if (translated == nil) then
    translated = WoWeuCN_Interface_TryPatternTranslate(text);
  end
  if (translated == nil) then
    translated = WoWeuCN_Interface_TryDecoratedTranslate(text);
  end
  if (translated == nil) then
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
  if (WoWeuCN_Interface_IsInExcludedFrame(frame)) then
    return 0;
  end
  local count = 0;
  local regions = { frame:GetRegions() };
  for i = 1, #regions do
    local region = regions[i];
    if (region and region.IsObjectType and region:IsObjectType("FontString")) then
      local ok, n = pcall(WoWeuCN_Interface_TranslateFontString, region);
      if (ok and n) then
        count = count + n;
      end
    end
  end
  return count;
end

function WoWeuCN_Interface_ScanExistingText()
  if (not WoWeuCN_Interface_N_PS) then
    return 0;
  end
  if (WoWeuCN_Interface_N_PS["active"] == "0") then
    return 0;
  end
  if (type(EnumerateFrames) ~= "function" or InCombatLockdown()) then
    return 0;
  end
  local total = 0;
  local frame = EnumerateFrames();
  while (frame) do
    local ok, n = pcall(WoWeuCN_Interface_ProcessFrame, frame);
    if (ok and n) then
      total = total + n;
    end
    frame = EnumerateFrames(frame);
  end
  WoWeuCN_Interface_Swept = WoWeuCN_Interface_Swept + total;
  return total;
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
local WoWeuCN_Interface_LiveQueueCount = 0;

local function WoWeuCN_Interface_OnFontStringSetText(fontString, text)
  if (WoWeuCN_Interface_SuppressHook or not WoWeuCN_Interface_Initialized) then
    return;
  end
  if (WoWeuCN_Interface_LiveQueueCount >= 200) then
    return;
  end
  if (issecretvalue and issecretvalue(text)) then
    return;
  end

  if (type(text) ~= "string" or string.len(text) < 2 or not string.find(text, "[^%s%p%d%c]")) then
    return;
  end
  if (fontString.IsForbidden and fontString:IsForbidden()) then
    return;
  end
  WoWeuCN_Interface_LiveQueueCount = WoWeuCN_Interface_LiveQueueCount + 1;
  WoWeuCN_Interface_LiveQueue[WoWeuCN_Interface_LiveQueueCount] = fontString;
end

local function WoWeuCN_Interface_TranslateQueuedRegion(region)
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
  hooksecurefunc(methods, "SetText", WoWeuCN_Interface_OnFontStringSetText);
  if (type(methods.SetFormattedText) == "function") then
    hooksecurefunc(methods, "SetFormattedText", WoWeuCN_Interface_OnFontStringSetText);
  end
end

local WoWeuCN_Interface_Driver = CreateFrame("Frame");
WoWeuCN_Interface_Driver:SetScript("OnUpdate", function(self, elapsed)
  WoWeuCN_Interface_SuppressHook = false;
  if (WoWeuCN_Interface_LiveQueueCount > 0) then
    local count = WoWeuCN_Interface_LiveQueueCount;
    WoWeuCN_Interface_LiveQueueCount = 0;
    for i = 1, count do
      local region = WoWeuCN_Interface_LiveQueue[i];
      WoWeuCN_Interface_LiveQueue[i] = nil;
      if (region) then
        pcall(WoWeuCN_Interface_TranslateQueuedRegion, region);
      end
    end
  end
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
  WoWeuCN_Interface_ScanAccum = WoWeuCN_Interface_ScanAccum + (elapsed or 0);
  if (WoWeuCN_Interface_ScanAccum >= 0.4) then
    WoWeuCN_Interface_ScanAccum = 0;
    pcall(WoWeuCN_Interface_PeriodicPass);
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
    local n = WoWeuCN_Interface_ScanExistingText();
    print("WOWeuCN - Interface: 重新扫描完成, 本次修复 " .. n .. " 处界面文本.");
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

  WoWeuCN_Interface_CreateCheckButton(1, WoWeuCN_InterfaceOptions, optionsLabel, -5, "transfont", WoWeuCN_Interface_Options.transfont);

  local reloadNote = WoWeuCN_InterfaceOptions:CreateFontString(nil, "ARTWORK");
  reloadNote:SetFontObject(GameFontWhite);
  reloadNote:SetJustifyH("LEFT");
  reloadNote:SetJustifyV("TOP");
  reloadNote:ClearAllPoints();
  reloadNote:SetPoint("TOPLEFT", optionsLabel, "BOTTOMLEFT", 0, -45);
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
    local n = WoWeuCN_Interface_ScanExistingText();
    print("WOWeuCN - Interface: 重新扫描完成, 本次修复 " .. n .. " 处界面文本.");
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
end
