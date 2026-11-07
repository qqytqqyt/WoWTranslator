local ADDON = ...
local FONT = "Interface\\AddOns\\" .. ADDON .. "\\Fonts\\woweucn.ttf"
local FORK = "WoWeuCN_Forever"
local KEY = "forkprompt"
local DELAY = 2
local FAMILY = {
  { "WoWeuCN_Quests", "WoWeuCN-Quests（任务汉化）" },
  { "WoWeuCN_Tooltips", "WoWeuCN-Tooltips（悬停提示汉化）" },
  { "WoWeuCN_Interface", "WoWeuCN-Interface（界面汉化）" },
}

local TEXT = {
  title   = "WoWeuCN 汉化插件提示",
  body    = "检测到第三方改版插件 WoWeuCN_Forever（WoWeuCN Plus）与本插件同时启用。两者会对同一内容重复翻译，请只保留其中一个，然后 /reload。\n\n"
         .. "该版本的部分新任务与其他翻译数据经证书许可取自本插件，但相关更新会先在本原版插件发布。\n\n"
         .. "原版汉化插件共三个：WoWeuCN-Quests（任务）、WoWeuCN-Tooltips（悬停提示）、WoWeuCN-Interface（界面），可在 Curseforge 或其他插件管理器搜索 woweucn 获取。",
  dismiss = "知道了",
  never   = "不再提示",
  missing = "|cffffff00WoWeuCN：尚未安装 %s，可在 Curseforge 或其他插件管理器搜索 woweucn 获取。|r",
}

local function Shared()
  local shared = _G.WoWeuCN_LoginNotice
  if type(shared) ~= "table" then
    shared = {}
    _G.WoWeuCN_LoginNotice = shared
  end
  return shared
end

local function Loaded(name)
  if C_AddOns and C_AddOns.IsAddOnLoaded then
    return C_AddOns.IsAddOnLoaded(name) == true
  end
  return false
end

local function Installed(name)
  if not (C_AddOns and C_AddOns.GetAddOnInfo) then
    return true
  end
  local ok, _, title = pcall(C_AddOns.GetAddOnInfo, name)
  return ok and title ~= nil
end

local function Remember(value)
  Shared().fork = value
  for i = 1, #FAMILY do
    local saved = _G[FAMILY[i][1] .. "_N_PS"]
    if type(saved) == "table" then
      saved[KEY] = value
    end
  end
end

local function State()
  local shared = Shared()
  if shared.fork then
    return shared.fork
  end
  local state
  for i = 1, #FAMILY do
    local saved = _G[FAMILY[i][1] .. "_N_PS"]
    local value = type(saved) == "table" and saved[KEY] or nil
    if value == "off" then
      return "off"
    end
    if type(value) == "string" and (not state or value > state) then
      state = value
    end
  end
  return state
end

local function Label(parent, size)
  local label = parent:CreateFontString(nil, "ARTWORK")
  label:SetFontObject(GameFontHighlight)
  label:SetFont(FONT, size, "")
  return label
end

local function CreatePopup()
  local name = ADDON .. "_LoginNoticePopup"
  local frame = CreateFrame("Frame", name, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  frame:SetSize(480, 220)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
  frame:SetFrameStrata("DIALOG")
  frame:SetToplevel(true)
  frame:EnableMouse(true)
  if frame.SetBackdrop then
    frame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
  end

  local title = Label(frame, 16)
  title:SetPoint("TOP", frame, "TOP", 0, -18)
  title:SetText(TEXT.title)

  local body = Label(frame, 13)
  body:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -48)
  body:SetWidth(432)
  body:SetJustifyH("LEFT")
  body:SetJustifyV("TOP")
  body:SetSpacing(3)
  body:SetText(TEXT.body)

  local never = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  never:SetSize(24, 24)
  never:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 16)
  local neverLabel = Label(frame, 12)
  neverLabel:SetPoint("LEFT", never, "RIGHT", 2, 0)
  neverLabel:SetText(TEXT.never)

  local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  button:SetSize(100, 22)
  button:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 16)
  if CreateFont then
    local normal = CreateFont(ADDON .. "_LoginNoticeButtonFont")
    normal:CopyFontObject(GameFontNormal)
    normal:SetFont(FONT, 12, "")
    local highlight = CreateFont(ADDON .. "_LoginNoticeButtonFontHighlight")
    highlight:CopyFontObject(GameFontHighlight)
    highlight:SetFont(FONT, 12, "")
    button:SetNormalFontObject(normal)
    button:SetHighlightFontObject(highlight)
  end
  button:SetText(TEXT.dismiss)
  button:SetScript("OnClick", function()
    if never:GetChecked() then
      Remember("off")
    end
    frame:Hide()
  end)

  local height = body:GetStringHeight()
  if type(height) ~= "number" or height <= 0 then
    height = 160
  end
  frame:SetHeight(48 + height + 62)
  if type(UISpecialFrames) == "table" then
    tinsert(UISpecialFrames, name)
  end
  frame.body, frame.never, frame.button = body, never, button
  return frame
end

local popup

local function ShowPopup()
  if not popup then
    local ok, result = pcall(CreatePopup)
    if not ok then
      print("|cffffff00" .. TEXT.title .. "：" .. string.gsub(TEXT.body, "\n+", " ") .. "|r")
      return
    end
    popup = result
  end
  popup:Show()
end

local function ForkNotice()
  if not Loaded(FORK) then
    return
  end
  local today = date("%Y-%m-%d")
  local state = State()
  if state == "off" or state == today then
    Remember(state)
    return
  end
  Shared().fork = today
  local function show()
    ShowPopup()
    Remember(today)
  end
  if C_Timer and C_Timer.After then
    C_Timer.After(DELAY, show)
  else
    show()
  end
end

local function CompanionHint()
  local shared = Shared()
  if shared.hint then
    return
  end
  shared.hint = true
  local missing = {}
  for i = 1, #FAMILY do
    local name, label = FAMILY[i][1], FAMILY[i][2]
    if name ~= ADDON and not Installed(name) then
      missing[#missing + 1] = label
    end
  end
  if #missing > 0 then
    print(string.format(TEXT.missing, table.concat(missing, "、")))
  end
end

local frame = CreateFrame("Frame", ADDON .. "_LoginNotice")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event)
  self:UnregisterEvent(event)
  if event == "PLAYER_LOGIN" then
    CompanionHint()
  else
    ForkNotice()
  end
end)
