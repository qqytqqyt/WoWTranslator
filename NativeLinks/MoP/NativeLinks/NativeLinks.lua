-- Addon: NativeLinks
-- Author: qqytqqyt

-- Local variables
local NativeLinks_version = C_AddOns.GetAddOnMetadata("NativeLinks", "Version");
local NativeLinks_Prefix = "NativeLinks";   

-- Get an ID from the |H<type>:... header
local function ExtractID(prefix, linkType)
  if linkType == "item" then
    return prefix:match("|Hitem:(%d+):")
  elseif linkType == "spell" then
    -- Spell links can be |Hspell:<id>|h or |Hspell:<id>:<subid>...
    return prefix:match("|Hspell:(%d+):?")
  elseif linkType == "achievement" then
    -- Achievements: |Hachievement:<id>:<guid stuff>...
    return prefix:match("|Hachievement:(%d+):")
  end
end

local SUPPORTED = {
  item = true,
  spell = true,
  achievement = true,
}

-- Build a new link with a swapped display name, if configured
local function RewriteItemLinkText(link)
  if not link or not NativeLinks_PS["active"] == "1" or IsAltKeyDown() then return link end


  local prefix, display, suffix = link:match("^(.-|h)%[(.-)%](|h.*)$")
  if not prefix then return link end

  local linkType = prefix:match("|H([^:]+):")
  if not linkType or not SUPPORTED[linkType] then
    return link
  end

  local id = ExtractID(prefix, linkType)
  local newName

  if linkType == "item" and id and NativeLinks_ItemNameData[id] and NativeLinks_ItemNameData[id] ~= "" then   
    local _, itemID, enchant, gem1, gem2, gem3, gem4, suffixID = strsplit(":", link)
    if suffixID ~= nil and suffixID ~= "" and suffixId ~= "0" then
      return link -- don't rewrite random-suffix items
    end
    newName = NativeLinks_ItemNameData[id]
  elseif linkType == "spell" and id and NativeLinks_SpellNameData[id] and NativeLinks_SpellNameData[id] ~= "" then
    newName = NativeLinks_SpellNameData[id]
  elseif linkType == "achievement" and id and NativeLinks_AchievementNameData[id] and NativeLinks_AchievementNameData[id] ~= "" then
    newName = NativeLinks_AchievementNameData[id]
  end

  if newName then
    newName = newName:gsub("[%[%]]", "") -- keep brackets sane
    return prefix .. "[" .. newName .. "]" .. suffix
  else
    return link
  end
end

local function RewriteItemLink(link)
  if not link or not NativeLinks_PS["active"] == "1" then return end

 -- Find the active edit box
  local editBox = ChatEdit_GetActiveWindow() or ChatEdit_ChooseBoxForSend()
  if not editBox or not editBox.GetText then return end

  -- Rewrite any supported links in the edit box AFTER the original insertion
  local text = editBox:GetText() or ""
  local oldText = text
  -- Pass 1: color-wrapped links
  text = text:gsub("(|c%x+|H.-|h%[.-%]|h|r)", function(tok)
    return RewriteItemLinkText(tok)
  end)
  -- Pass 2: bare links
  text = text:gsub("(|H.-|h%[.-%]|h)", function(tok)
    return RewriteItemLinkText(tok)
  end)
  if oldText ~= text then
    editBox:SetText(text)
  end
end

function NativeLinks_SlashCommand(msg)
   msg = msg or ""
  local cmd, rest = msg:match("^(%S+)%s*(.-)$")
  cmd = cmd and cmd:lower() or ""

  if cmd == "on" then
    NativeLinks_PS["active"] = "1";  
    print("NativeLinks enabled.")
  elseif cmd == "off" then
    NativeLinks_PS["active"] = "0"; 
    print("NativeLinks disabled.")
  else
    print("NativeLinks Commands:")
    print("  /nl on                      - enable link rewriting")
    print("  /nl off                     - disable link rewriting")
  end
end

local function OnTooltipItem(self, tooltip)
  if (NativeLinks_PS["active"]=="0") then
    return
  end
	-- Case for linked spell
  local name, itemLink = self:GetItem()
  if (itemLink == nil) then 
    return
  end

  local itemID = string.match(itemLink, 'Hitem:(%d+):')
  if (itemID == nil) then 
    return
  end

  local itemName = NativeLinks_ItemNameData[itemID]
  if ( itemName ) then      
    local line = _G["GameTooltipTextLeft1"]
    local r, g, b, a = line:GetTextColor()
    self:AddLine(" ")
    self:AddLine(itemName, r, g, b, a)
  end
end

local function OnTooltipSpell(self, tooltip)
  if (NativeLinks_PS["active"]=="0") then
    return
  end
	-- Case for linked spell
  local name,id = self:GetSpell()
  if (id == nil) then 
    return
  end

  local str_id = tostring(id)
  local spellName = NativeLinks_SpellNameData[str_id]
  if ( spellName ) then  
    local line = _G["GameTooltipTextLeft1"]
    local r, g, b, a = line:GetTextColor()
    self:AddLine(" ")
    self:AddLine(spellName, r, g, b, a)
  end
end

function OnTooltipUnit(self, tooltip)
  if (NativeLinks_PS["active"]=="0") then
    return
  end
	-- Case for linked unit
  local unitName, unit = self:GetUnit()
  if (unit == nil) then 
    return
  end

  local unitGUID = UnitGUID(unit);
  local type, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", unitGUID);
  
  local unitName = NativeLinks_UnitNameData[npc_id]

  if ( unitName ) then  
    local line = _G["GameTooltipTextLeft1"]
    local r, g, b, a = line:GetTextColor()
    self:AddLine(" ")
    self:AddLine(unitName, r, g, b, a)
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
   
   GameTooltip:HookScript("OnTooltipSetSpell", function(...) OnTooltipSpell(..., GameTooltip) end)
   GameTooltip:HookScript("OnTooltipSetItem", function(...) OnTooltipItem(..., GameTooltip) end)
   ItemRefTooltip:HookScript("OnTooltipSetItem", function(...) OnTooltipItem(..., GameTooltip) end)

   EmbeddedItemTooltip:HookScript("OnTooltipSetItem", function(...) OnTooltipItem(..., GameTooltip) end)
   ShoppingTooltip1:HookScript("OnTooltipSetItem", function(...) OnTooltipItem(..., GameTooltip) end)
   ShoppingTooltip2:HookScript("OnTooltipSetItem", function(...) OnTooltipItem(..., GameTooltip) end)
   ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", function(...) OnTooltipItem(..., GameTooltip) end)
   ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", function(...) OnTooltipItem(..., GameTooltip) end)

   GameTooltip:HookScript("OnTooltipSetUnit", function(...) OnTooltipUnit(..., GameTooltip) end)
   
   hooksecurefunc('ChatEdit_InsertLink', RewriteItemLink)

   RegisterChatFilterEvents()
end

local NativeLinks_waitFrame = nil;
local NativeLinks_waitTable = {};

function NativeLinks_wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if (NativeLinks_waitFrame == nil) then
    NativeLinks_waitFrame = CreateFrame("Frame","NativeLinks_waitFrame", UIParent);
    NativeLinks_waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #NativeLinks_waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(NativeLinks_waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(NativeLinks_waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(NativeLinks_waitTable,{delay,func,{...}});
  return true;
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

      if (not NativeLinks_PS["active"]) then
        NativeLinks_PS["active"] = "1";
      end

      NativeLinks_wait(2, Broadcast)
      NativeLinks:UnregisterEvent("ADDON_LOADED");
      NativeLinks.ADDON_LOADED = nil;
      return
   end
end


local function OnEvent(self, event, prefix, text, channel, sender, ...)
  if event == "CHAT_MSG_ADDON" and prefix == NativeLinks_Prefix then
    if text == "VERSION" then
      if sender == nil then
       C_ChatInfo.SendAddonMessage(NativeLinks_Prefix, "NativeLinks ver. "..NativeLinks_version, channel)
      else
       C_ChatInfo.SendAddonMessage(NativeLinks_Prefix, "NativeLinks ver. "..NativeLinks_version, channel, sender)
      end
    elseif (string.sub(text,1,string.len("NativeLinks"))=="NativeLinks" and not reminded) then
      local _, major, minor, revision = string.match(NativeLinks_version, "^.-(%d+)%.(%d+)%.(%d+)%.(%d+)")
      local _, newMajor, newMinor, newRevision  = string.match(text, "^.-(%d+)%.(%d+)%.(%d+)%.(%d+)")
      local newVersionNumber = tonumber(newMajor)*10000 + tonumber(newMinor)*100 + tonumber(newRevision)
      local myVersionNumber = tonumber(major)*10000 + tonumber(minor)*100 + tonumber(revision)
      if newVersionNumber > myVersionNumber then
        print("|cffffff00" .. NativeLinks_Messages.newversion .. "|r")
        reminded = true
      end
    end
  end
end

function Broadcast()
  print ("|cffffff00NativeLinks ver. "..NativeLinks_version.." - "..NativeLinks_Messages.loaded.." - |cffa335ee"..NativeLinks_Messages.author.."|r");
  
  local name, _, rank = GetGuildInfo("player");
  if name ~= nil then
    C_ChatInfo.SendAddonMessage(NativeLinks_Prefix, "NativeLinks ver. "..NativeLinks_version .. " Loaded", "GUILD")
  end

  C_ChatInfo.SendAddonMessage(NativeLinks_Prefix, "NativeLinks ver. "..NativeLinks_version .. " Loaded", "RAID")
  C_ChatInfo.SendAddonMessage(NativeLinks_Prefix, "NativeLinks ver. "..NativeLinks_version .. " Loaded", "YELL")

  reminded = false
  local f = CreateFrame("Frame")
  f:RegisterEvent("CHAT_MSG_ADDON")
  f:RegisterEvent("ADDON_LOADED")
  f:SetScript("OnEvent", OnEvent)
  
  C_ChatInfo.RegisterAddonMessagePrefix(NativeLinks_Prefix)
end