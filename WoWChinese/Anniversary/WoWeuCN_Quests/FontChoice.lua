local ADDON = ...
local TITLE = string.gsub(ADDON, "_", "-")
local SAVED = ADDON .. "_N_PS"
local BUNDLED_FONT = "Interface\\AddOns\\" .. ADDON .. "\\Fonts\\woweucn.ttf"

local CLIENT_FONT = "Fonts\\FRIZQT__.TTF"
if type(STANDARD_TEXT_FONT) == "string" and STANDARD_TEXT_FONT ~= "" then
  CLIENT_FONT = STANDARD_TEXT_FONT
end
local CLIENT_CHINESE_FONT = "Fonts\\ARKai_T.ttf"

local TEXT = {
  title        = "插件字体:",
  bundled      = "内置字体",
  client       = "游戏默认字体",
  chinese      = "游戏中文字体",
  apply        = "应用",
  preview      = "字体预览：艾泽拉斯的勇士 Heroes of Azeroth 0123456789",
  applied      = "已应用",
  notfound     = "找不到该字体文件，未作更改",
  savedmissing = "找不到该字体文件，暂用内置字体",
  loadmissing  = "找不到字体文件 %s，已改用内置字体。",
  hint         = "“游戏默认字体”即客户端的 %s，适用于已把它替换成中文字体的玩家。\n"
              .. "也可以填写其他字体文件的路径（相对于游戏目录，例如 Fonts\\myfont.ttf），按回车应用。\n"
              .. "放在插件目录之外的字体不会在更新插件时被覆盖。预览出现方块表示该字体不含中文。\n"
              .. "更换后部分界面需 /reload 才能完全生效。\n"
              .. "新放入 Fonts 文件夹的字体需要重启游戏后，插件才能识别。",
}

local probe

local function IsFontUsable(path)
  if not probe then
    probe = CreateFrame("EditBox")
    probe:SetAutoFocus(false)
    probe:Hide()
  end
  local ok, result = pcall(probe.SetFont, probe, path, 12, "")
  return ok and result ~= false
end

local function IsSameFile(a, b)
  return string.lower(a) == string.lower(b)
end

local function CleanPath(text)
  if type(text) ~= "string" then
    return ""
  end
  text = string.gsub(text, "^[%s\"']+", "")
  text = string.gsub(text, "[%s\"']+$", "")
  text = string.gsub(text, "/", "\\")
  if string.find(text, "^%a:\\") or string.find(text, "^\\") then
    text = string.match(text, "^.*\\_[%a_]+_\\(.+)$") or text
  end
  text = string.gsub(text, "^\\+", "")
  return text
end

local function Resolve()
  local saved = _G[SAVED]
  local choice = type(saved) == "table" and saved["font"] or nil
  if type(choice) ~= "string" or choice == "" then
    return BUNDLED_FONT, nil
  end
  if IsFontUsable(choice) then
    return choice, nil
  end
  return BUNDLED_FONT, choice
end

local warned = false

local function ApplyFontChoice()
  local font, missing = Resolve()
  _G[ADDON .. "_Font1"] = font
  _G[ADDON .. "_Font2"] = font
  if missing and not warned then
    warned = true
    print("|cffffff00" .. TITLE .. " - " .. string.format(TEXT.loadmissing, missing) .. "|r")
  end
  return font
end

local function SetFontChoice(text)
  local saved = _G[SAVED]
  if type(saved) ~= "table" then
    return false
  end
  local path = CleanPath(text)
  if path == "" or IsSameFile(path, BUNDLED_FONT) then
    path = nil
  elseif not IsFontUsable(path) then
    return false
  end
  local previous = _G[ADDON .. "_Font1"]
  saved["font"] = path
  local font = ApplyFontChoice()
  local onChanged = _G[ADDON .. "_OnFontChanged"]
  if font ~= previous and type(onChanged) == "function" then
    onChanged()
  end
  return true
end

local function CreateFontOptions(panel, anchor, offsetY)

  local container = CreateFrame("Frame", nil, panel)
  container:SetSize(1, 1)
  container:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, offsetY)

  local function Label(size)
    local label = container:CreateFontString(nil, "ARTWORK")
    label:SetFontObject(GameFontWhite)
    label:SetFont(BUNDLED_FONT, size)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    return label
  end

  local normalFont, highlightFont
  if CreateFont then
    normalFont = CreateFont(ADDON .. "_ButtonFont")
    normalFont:CopyFontObject(GameFontNormal)
    normalFont:SetFont(BUNDLED_FONT, 12, "")
    highlightFont = CreateFont(ADDON .. "_ButtonFontHighlight")
    highlightFont:CopyFontObject(GameFontHighlight)
    highlightFont:SetFont(BUNDLED_FONT, 12, "")
  end
  local function Button(text, width)
    local button = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    if normalFont then
      button:SetNormalFontObject(normalFont)
      button:SetHighlightFontObject(highlightFont)
    end
    button:SetText(text)
    return button
  end

  local title = Label(13)
  title:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
  title:SetText(TEXT.title)

  local box = CreateFrame("EditBox", ADDON .. "_FontBox", container, "InputBoxTemplate")
  box:SetAutoFocus(false)
  box:SetSize(380, 22)
  box:SetMaxLetters(255)
  box:SetPoint("LEFT", title, "RIGHT", 14, 0)

  local apply = Button(TEXT.apply, 60)
  apply:SetPoint("LEFT", box, "RIGHT", 8, 0)

  local bundled = Button(TEXT.bundled, 90)
  bundled:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -14)
  local client = Button(TEXT.client, 110)
  client:SetPoint("LEFT", bundled, "RIGHT", 6, 0)
  local lastPreset = client
  local chinese
  if not IsSameFile(CLIENT_CHINESE_FONT, CLIENT_FONT) and IsFontUsable(CLIENT_CHINESE_FONT) then
    chinese = Button(TEXT.chinese, 110)
    chinese:SetPoint("LEFT", client, "RIGHT", 6, 0)
    lastPreset = chinese
  end

  local status = Label(12)
  status:SetPoint("LEFT", lastPreset, "RIGHT", 10, 0)

  local preview = container:CreateFontString(nil, "ARTWORK")
  preview:SetFontObject(GameFontHighlight)
  preview:SetJustifyH("LEFT")
  preview:SetPoint("TOPLEFT", bundled, "BOTTOMLEFT", 0, -10)
  preview:SetText(TEXT.preview)

  local hint = Label(12)
  hint:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", 0, -8)
  hint:SetTextColor(0.7, 0.7, 0.7)
  hint:SetText(string.format(TEXT.hint, CLIENT_FONT))

  local function ShowCurrent()
    local font, missing = Resolve()
    box:SetText(missing or font)
    box:SetCursorPosition(0)
    if not pcall(preview.SetFont, preview, font, 15, "") then
      preview:SetFont(BUNDLED_FONT, 15, "")
    end
    return missing
  end

  local function Submit(text)
    if SetFontChoice(text) then
      ShowCurrent()
      box:ClearFocus()
      status:SetText("|cff40ff40" .. TEXT.applied .. "|r")
    else
      status:SetText("|cffff4040" .. TEXT.notfound .. "|r")
    end
  end

  box:SetScript("OnEnterPressed", function(self) Submit(self:GetText()) end)
  box:SetScript("OnEscapePressed", function(self) ShowCurrent(); self:ClearFocus() end)
  apply:SetScript("OnClick", function() Submit(box:GetText()) end)
  bundled:SetScript("OnClick", function() Submit("") end)
  client:SetScript("OnClick", function() Submit(CLIENT_FONT) end)
  if chinese then
    chinese:SetScript("OnClick", function() Submit(CLIENT_CHINESE_FONT) end)
  end

  if ShowCurrent() then
    status:SetText("|cffff4040" .. TEXT.savedmissing .. "|r")
  end
  return container
end

_G[ADDON .. "_ApplyFontChoice"] = ApplyFontChoice
_G[ADDON .. "_SetFontChoice"] = SetFontChoice
_G[ADDON .. "_CreateFontOptions"] = function(panel, anchor, offsetY)

  local ok, result = pcall(CreateFontOptions, panel, anchor, offsetY)
  if ok then
    return result
  end
  if geterrorhandler then
    geterrorhandler()(result)
  end
end
