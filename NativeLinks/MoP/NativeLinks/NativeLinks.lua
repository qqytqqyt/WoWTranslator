-- Addon: NativeLinks
-- Author: qqytqqyt

-- Local variables
local NativeLinks_version = C_AddOns.GetAddOnMetadata("NativeLinks", "Version");
local NativeLinks_Prefix = "NativeLinks";
local NativeLinks_Reminded = false;

-- Saved variable defaults
local NativeLinks_Defaults = {
  active = "1",       -- master switch
  chat = "1",         -- translate the links in other players' messages
  chatmode = "both",  -- "both": translation and original side by side, "replace": translation only
}

-- Secret values (retail 12.x) must not be read by addon code
local function IsSecret(value)
  return issecretvalue ~= nil and issecretvalue(value)
end

function NativeLinks_IsActive()
  return NativeLinks_PS ~= nil and NativeLinks_PS["active"] ~= "0"
end

-- The name data comes either as one table per kind (NativeLinks_ItemNameData)
-- or split by id range (NativeLinks_ItemNameData_0, NativeLinks_ItemNameData_100000, ...)
local function GetName(kind, id)
  local num_id = tonumber(id)
  if not num_id then return end
  local str_id = tostring(num_id)

  local data = _G["NativeLinks_" .. kind .. "NameData"]
  local name = data and data[str_id]
  if not name then
    data = _G["NativeLinks_" .. kind .. "NameData_" .. (num_id - num_id % 100000)]
    name = data and data[str_id]
  end

  if name and name ~= "" then
    return name
  end
end

-- The split data files wrap their tables in Load...NameData<range>() functions, run them once and release them
local function LoadNameData()
  for _, kind in ipairs({ "Item", "Spell", "Achievement" }) do
    for range = 0, 5000000, 100000 do
      local loader = "Load" .. kind .. "NameData" .. (range > 0 and range or "")
      if type(_G[loader]) == "function" then
        _G[loader]()
        _G[loader] = nil
      end
    end
  end
end

-- Link types to rewrite and the name data they use
local SUPPORTED = {
  item = "Item",
  spell = "Spell",
  achievement = "Achievement",
}
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
  SUPPORTED.enchant = "Spell"
end

-- Build a new link with a swapped display name, if configured
local function RewriteItemLinkText(link)
  local prefix, display, suffix = link:match("^(.-|h)%[(.-)%](|h.*)$")
  if not prefix then return link end

  local linkType, id = prefix:match("|H(%a+):(%d+)")
  local kind = linkType and SUPPORTED[linkType]
  if not kind then
    return link
  end

  if linkType == "item" then
    local suffixID = prefix:match("|Hitem:%d+:[^:|]*:[^:|]*:[^:|]*:[^:|]*:[^:|]*:(%-?%d+)")
    if suffixID and suffixID ~= "0" then
      return link -- don't rewrite random-suffix items
    end
  end

  local newName = GetName(kind, id)
  if not newName then
    return link
  end

  -- retail appends the crafting quality icon to the name
  local icon = display:match("(%s*|A.*)$") or ""
  newName = newName:gsub("[%[%]]", "") -- keep brackets sane
  return prefix .. "[" .. newName .. icon .. "]" .. suffix
end

-- Rewrite the link which has just been inserted into the chat edit box
local function RewriteItemLink(link)
  if IsSecret(link) or type(link) ~= "string" then return end
  if not NativeLinks_IsActive() or IsAltKeyDown() then return end

  -- Find the active edit box
  local editBox
  if ChatFrameUtil and ChatFrameUtil.GetActiveWindow then
    editBox = ChatFrameUtil.GetActiveWindow() or ChatFrameUtil.ChooseBoxForSend()
  else
    editBox = ChatEdit_GetActiveWindow() or ChatEdit_ChooseBoxForSend()
  end
  if not editBox or not editBox.GetText then return end

  local text = editBox:GetText()
  if IsSecret(text) or type(text) ~= "string" then return end

  local newLink = RewriteItemLinkText(link)
  if newLink == link then return end

  -- The inserted link sits right before the cursor
  local cursor = editBox:GetCursorPosition()
  local head, tail = text:sub(1, cursor), text:sub(cursor + 1)
  if head:sub(-#link) == link then
    head = head:sub(1, #head - #link) .. newLink
    editBox:SetText(head .. tail)
    editBox:SetCursorPosition(#head)
    return
  end

  -- Otherwise swap the last copy of the link in the edit box
  local last, from = nil, 1
  while true do
    local found = text:find(link, from, true)
    if not found then break end
    last, from = found, found + 1
  end
  if last then
    editBox:SetText(text:sub(1, last - 1) .. newLink .. text:sub(last + #link))
  end
end

local function PrintHelp()
  print("NativeLinks Commands:")
  for _, line in ipairs(NativeLinks_Messages.help) do
    print("  " .. line)
  end
end

function NativeLinks_SlashCommand(msg)
  msg = msg or ""
  local cmd, rest = msg:match("^(%S+)%s*(.-)%s*$")
  cmd = cmd and cmd:lower() or ""
  rest = rest and rest:lower() or ""

  if cmd == "on" then
    NativeLinks_PS["active"] = "1";
    print(NativeLinks_Messages.cmdon)
  elseif cmd == "off" then
    NativeLinks_PS["active"] = "0";
    print(NativeLinks_Messages.cmdoff)
  elseif cmd == "chat" and rest == "on" then
    NativeLinks_PS["chat"] = "1";
    print(NativeLinks_Messages.cmdchaton)
  elseif cmd == "chat" and rest == "off" then
    NativeLinks_PS["chat"] = "0";
    print(NativeLinks_Messages.cmdchatoff)
  elseif cmd == "chat" and rest == "both" then
    NativeLinks_PS["chatmode"] = "both";
    print(NativeLinks_Messages.cmdchatboth)
  elseif cmd == "chat" and rest == "replace" then
    NativeLinks_PS["chatmode"] = "replace";
    print(NativeLinks_Messages.cmdchatreplace)
  elseif cmd == "config" or cmd == "options" then
    if not NativeLinks_OpenOptions() then
      PrintHelp()
    end
  else
    PrintHelp()
  end
end

-- Add the English name at the bottom of a tooltip
local function AddNameLine(tooltip, name)
  if not name or not tooltip.AddLine then return end
  if tooltip.IsForbidden and tooltip:IsForbidden() then return end

  local r, g, b = 1, 1, 1
  local line = _G[(tooltip:GetName() or "GameTooltip") .. "TextLeft1"] or _G["GameTooltipTextLeft1"]
  if line then
    local lr, lg, lb = line:GetTextColor()
    if not (IsSecret(lr) or IsSecret(lg) or IsSecret(lb)) and lr then
      r, g, b = lr, lg, lb
    end
  end

  tooltip:AddLine(" ")
  tooltip:AddLine(name, r, g, b, true)
end

-- Tooltip scripts of the classic clients
local function OnTooltipItem(self)
  if not NativeLinks_IsActive() then
    return
  end
  -- Case for linked item
  local name, itemLink = self:GetItem()
  if (itemLink == nil) then
    return
  end

  AddNameLine(self, GetName("Item", string.match(itemLink, 'Hitem:(%d+)')))
end

local function OnTooltipSpell(self)
  if not NativeLinks_IsActive() then
    return
  end
  -- Case for linked spell
  local name, id = self:GetSpell()
  if (id == nil) then
    return
  end

  AddNameLine(self, GetName("Spell", id))
end

-- Tooltip data of the retail based clients
local TooltipKinds = {}

local function translateTooltip(tooltip, data)
  if not NativeLinks_IsActive() then return end
  if not data or IsSecret(data.type) then return end

  local kind = TooltipKinds[data.type]
  if not kind then return end

  local id = data.id
  if IsSecret(id) then return end
  if type(id) == "table" and #id == 1 then id = id[1] end
  if IsSecret(id) then return end
  AddNameLine(tooltip, GetName(kind, id))
end

local function HookTooltips()
  if GameTooltip:HasScript("OnTooltipSetItem") then
    for _, tooltipName in ipairs({ "GameTooltip", "ItemRefTooltip", "EmbeddedItemTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2" }) do
      local tooltip = _G[tooltipName]
      if tooltip and tooltip:HasScript("OnTooltipSetItem") then
        tooltip:HookScript("OnTooltipSetItem", OnTooltipItem)
      end
    end
    GameTooltip:HookScript("OnTooltipSetSpell", OnTooltipSpell)
  elseif TooltipDataProcessor and Enum.TooltipDataType then
    for dataType, kind in pairs({ Spell = "Spell", UnitAura = "Spell", RecipeRankInfo = "Spell", Totem = "Spell", Item = "Item", Toy = "Item" }) do
      if Enum.TooltipDataType[dataType] then
        TooltipKinds[Enum.TooltipDataType[dataType]] = kind
      end
    end
    TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes, translateTooltip)
  end
end

-- First function called after the add-in has been loaded
function NativeLinks_OnLoad()
   NativeLinks = CreateFrame("Frame");
   local expInfo, _, _, _ = GetBuildInfo()
   local exp, major, minor = strsplit(".", expInfo)
   local myExp = string.match(NativeLinks_version, "^.-(%d+)%.")
   local _, myMajor, myMinor = strsplit( ".", NativeLinks_version)
   if exp ~= myExp then
     print("|cffffff00" .. NativeLinks_Messages.loaderrorexp .. "|r")
     return
   end
   if (tonumber(major) * 100 + tonumber(minor)) > (tonumber(myMajor) * 100 + tonumber(myMinor)) then
     print("|cffffff00" .. NativeLinks_Messages.loaderror .. "|r")
     return
   end

   NativeLinks:SetScript("OnEvent", NativeLinks_OnEvent);
   NativeLinks:RegisterEvent("ADDON_LOADED");
   NativeLinks:RegisterEvent("PLAYER_LOGIN");

   HookTooltips()

   -- The clients only call ChatFrameUtil.InsertLink now, ChatEdit_InsertLink is a copy kept for addons
   if ChatFrameUtil and ChatFrameUtil.InsertLink then
     hooksecurefunc(ChatFrameUtil, "InsertLink", RewriteItemLink)
   end
   if ChatEdit_InsertLink then
     hooksecurefunc("ChatEdit_InsertLink", RewriteItemLink)
   end

   NativeLinks_RegisterChatFilters()
end

local function SendVersion(text, channel, target)
  pcall(C_ChatInfo.SendAddonMessage, NativeLinks_Prefix, text, channel, target)
end

local function OnAddonMessage(self, event, prefix, text, channel, sender)
  if IsSecret(prefix) or IsSecret(text) then return end
  if prefix ~= NativeLinks_Prefix or type(text) ~= "string" then return end

  if text == "VERSION" then
    SendVersion("NativeLinks ver. "..NativeLinks_version, channel, sender)
  elseif (string.sub(text,1,string.len("NativeLinks"))=="NativeLinks" and not NativeLinks_Reminded) then
    local _, major, minor, revision = string.match(NativeLinks_version, "^.-(%d+)%.(%d+)%.(%d+)%.(%d+)")
    local _, newMajor, newMinor, newRevision  = string.match(text, "^.-(%d+)%.(%d+)%.(%d+)%.(%d+)")
    if not major or not newMajor then return end
    local newVersionNumber = tonumber(newMajor)*10000 + tonumber(newMinor)*100 + tonumber(newRevision)
    local myVersionNumber = tonumber(major)*10000 + tonumber(minor)*100 + tonumber(revision)
    if newVersionNumber > myVersionNumber then
      print("|cffffff00" .. NativeLinks_Messages.newversion .. "|r")
      NativeLinks_Reminded = true
    end
  end
end

local function Broadcast()
  print ("|cffffff00NativeLinks ver. "..NativeLinks_version.." - "..NativeLinks_Messages.loaded.." - |cffa335ee"..NativeLinks_Messages.author.."|r");

  local name, _, rank = GetGuildInfo("player");
  if name ~= nil then
    SendVersion("NativeLinks ver. "..NativeLinks_version .. " Loaded", "GUILD")
  end

  SendVersion("NativeLinks ver. "..NativeLinks_version .. " Loaded", "RAID")
  SendVersion("NativeLinks ver. "..NativeLinks_version .. " Loaded", "YELL")

  local f = CreateFrame("Frame")
  f:RegisterEvent("CHAT_MSG_ADDON")
  f:SetScript("OnEvent", OnAddonMessage)

  C_ChatInfo.RegisterAddonMessagePrefix(NativeLinks_Prefix)
end

-- Even handlers
function NativeLinks_OnEvent(self, event, name, ...)
   if (event=="ADDON_LOADED" and name=="NativeLinks") then
      SlashCmdList["NativeLinks"] = function(msg) NativeLinks_SlashCommand(msg); end
      SLASH_NativeLinks1 = "/NativeLinks";
      SLASH_NativeLinks2 = "/nl";

      if (not NativeLinks_PS) then
        NativeLinks_PS = {};
      end

      for key, value in pairs(NativeLinks_Defaults) do
        if (not NativeLinks_PS[key]) then
          NativeLinks_PS[key] = value;
        end
      end

      C_Timer.After(2, Broadcast)

      LoadNameData()

      NativeLinks:UnregisterEvent("ADDON_LOADED");
      NativeLinks.ADDON_LOADED = nil;
      return
   end

   if (event=="PLAYER_LOGIN") then
      NativeLinks_RegisterOptions()
      NativeLinks:UnregisterEvent("PLAYER_LOGIN");
      return
   end
end
