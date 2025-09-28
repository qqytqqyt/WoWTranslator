-- Addon: NativeLinks
-- Author: qqytqqyt

-- Local variables
local NativeLinks_version = C_AddOns.GetAddOnMetadata("NativeLinks", "Version");
local NativeLinks_Prefix = "NativeLinks";   

local kinds = {
  spell = "Spell",
  item = "Item",
  unit = "NPC",
  quest = "Quest",
  talent = "Talent",
  achievement = "Achievement",
  criteria = "Criteria",
  ability = "Ability",
  currency = "Currency",
  artifactpower = "ArtifactPower",
  enchant = "Enchant",
  bonus = "Bonus",
  gem = "Gem",
  mount = "Mount",
  companion = "Companion",
  macro = "Macro",
  equipmentset = "EquipmentSet",
  visual = "Visual",
  source = "Source",
  species = "Species",
  icon = "Icon",
}

local function GetItemName(id)
  local str_id = tostring(id)
  local num_id = tonumber(id)

  local name
  if (num_id >= 0 and num_id < 100000) then
    name = NativeLinks_ItemNameData_0[str_id]
  elseif (num_id >= 100000 and num_id < 200000 and NativeLinks_ItemNameData_100000) then
    name = NativeLinks_ItemNameData_100000[str_id]
  elseif (num_id >= 200000 and num_id < 300000 and NativeLinks_ItemNameData_200000) then
    name = NativeLinks_ItemNameData_200000[str_id]
  elseif (num_id >= 300000 and num_id < 400000 and NativeLinks_ItemNameData_300000) then
    name = NativeLinks_ItemNameData_300000[str_id]
  end

  return name
end

local function GetSpellName(id)
  local str_id = tostring(id)
  local num_id = tonumber(id)
  
  local name
  if (num_id >= 0 and num_id < 100000) then
    name = NativeLinks_SpellNameData_0[str_id]
  elseif (num_id >= 100000 and num_id < 200000 and NativeLinks_SpellNameData_100000) then
    name = NativeLinks_SpellNameData_100000[str_id]
  elseif (num_id >= 200000 and num_id < 300000 and NativeLinks_SpellNameData_200000) then
    name = NativeLinks_SpellNameData_200000[str_id]
  elseif (num_id >= 300000 and num_id < 400000 and NativeLinks_SpellNameData_300000) then
    name = NativeLinks_SpellNameData_300000[str_id]
  elseif (num_id >= 400000 and num_id < 500000 and NativeLinks_SpellNameData_400000) then
    name = NativeLinks_SpellNameData_400000[str_id]
  elseif (num_id >= 500000 and num_id < 600000 and NativeLinks_SpellNameData_500000) then
    name = NativeLinks_SpellNameData_500000[str_id]
  end

  return name
end

local function GetUnitName(id)
  local str_id = tostring(id)
  local num_id = tonumber(id)
  local name

  if (num_id >= 0 and num_id < 100000) then
    name = NativeLinks_UnitNameData_0[str_id]
  elseif (num_id >= 100000 and num_id < 200000) then
    name = NativeLinks_UnitNameData_100000[str_id]
  elseif (num_id >= 200000 and num_id < 300000) then
    name = NativeLinks_UnitNameData_200000[str_id]
  elseif (num_id >= 300000 and num_id < 400000) then
    name = NativeLinks_UnitNameData_300000[str_id]
  end

  return name
end

local function GetAchievementName(id)
  local str_id = tostring(id)
  local num_id = tonumber(id)
  local name = NativeLinks_AchievementNameData[str_id]

  return name
end

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
  if not link or not NativeLinks_PS["active"] == "1" then return link end


  local prefix, display, suffix = link:match("^(.-|h)%[(.-)%](|h.*)$")
  if not prefix then return link end

  local linkType = prefix:match("|H([^:]+):")
  if not linkType or not SUPPORTED[linkType] then
    return link
  end

  local id = ExtractID(prefix, linkType)
  local newName

  if linkType == "item" and id then   
    local _, itemID, enchant, gem1, gem2, gem3, gem4, suffixID = strsplit(":", link)
    if suffixID ~= nil and suffixID ~= "" and suffixId ~= "0" then
      return link -- don't rewrite random-suffix items
    end
    newName = GetItemName(id)
  elseif linkType == "spell" and id then
    newName = GetSpellName(id)
  elseif linkType == "achievement" and id then
    newName = GetAchievementName(id)
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

local function SetItemTooltip(tooltip, id)
  if (NativeLinks_PS["active"]=="0") then
    return
  end
  
  local itemName = GetItemName(id)
  if ( itemName ) then      
    local line = _G["GameTooltipTextLeft1"]
    local r, g, b, a = line:GetTextColor()
    tooltip:AddLine(" ")
    tooltip:AddLine(itemName, r, g, b, a)
  end
end

local function SetSpellTooltip(tooltip, id)
  if (NativeLinks_PS["active"]=="0") then
    return
  end

  local spellName = GetSpellName(id)
  if ( spellName ) then  
    local line = _G["GameTooltipTextLeft1"]
    local r, g, b, a = line:GetTextColor()
    tooltip:AddLine(" ")
    tooltip:AddLine(spellName, r, g, b, a)
  end
end

local function SetUnitTooltip(tooltip, id)
  if (NativeLinks_PS["active"]=="0") then
    return
  end
  
  local unitName = GetUnitName(id)

  if ( unitName and unitName ~= "" ) then  
    local line = _G["GameTooltipTextLeft1"]
    local r, g, b, a = line:GetTextColor()
    tooltip:AddLine(" ")
    tooltip:AddLine(unitName, r, g, b, a)
  end
end

local function translateTooltip(tooltip, data, kind)
  if kind == kinds.unit and data.guid then
    local id = tonumber(data.guid:match("-(%d+)-%x+$"), 10)
    if id and data.guid:match("%a+") ~= "Player" then 
        SetUnitTooltip(tooltip, id)
    end
  elseif data.id then
    local id = data.id
    if type(id) == "table" and #id == 1 then id = id[1] end
    if kind == kinds.spell then
      SetSpellTooltip(tooltip, id)
    elseif kind == kinds.item then
      SetItemTooltip(tooltip, id)
    elseif kind == kinds.unit then
      SetUnitTooltip(tooltip, id)
    end
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
   
    if TooltipDataProcessor then
        TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes, function(tooltip, data)
          if not data or not data.type then return end
          if data.type == Enum.TooltipDataType.Spell then
            translateTooltip(tooltip, data, kinds.spell)
          elseif data.type == Enum.TooltipDataType.Item then
            translateTooltip(tooltip, data, kinds.item)
          elseif data.type == Enum.TooltipDataType.Unit then
            translateTooltip(tooltip, data, kinds.unit)
          elseif data.type == Enum.TooltipDataType.Currency then
            translateTooltip(tooltip, data, kinds.currency)
          elseif data.type == Enum.TooltipDataType.UnitAura then
            translateTooltip(tooltip, data, kinds.spell)
          elseif data.type == Enum.TooltipDataType.Mount then
            translateTooltip(tooltip, data, kinds.mount)
          elseif data.type == Enum.TooltipDataType.Achievement then
            translateTooltip(tooltip, data, kinds.achievement)
          elseif data.type == Enum.TooltipDataType.EquipmentSet then
            translateTooltip(tooltip, data, kinds.equipmentset)
          elseif data.type == Enum.TooltipDataType.RecipeRankInfo then
            translateTooltip(tooltip, data, kinds.spell)
          elseif data.type == Enum.TooltipDataType.Totem then
            translateTooltip(tooltip, data, kinds.spell)
          elseif data.type == Enum.TooltipDataType.Toy then
            translateTooltip(tooltip, data, kinds.item)
          elseif data.type == Enum.TooltipDataType.Quest then
            translateTooltip(tooltip, data, kinds.quest)
          elseif data.type == Enum.TooltipDataType.Macro then
            translateTooltip(tooltip, data, kinds.macro)
          end
        end)
      end
   
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

      LoadAchievementNameData()
      LoadItemNameData()
      LoadItemNameData100000()
      LoadItemNameData200000()
      LoadSpellNameData()
      LoadSpellNameData100000()
      LoadSpellNameData200000()
      LoadSpellNameData300000()
      LoadSpellNameData400000()
      LoadUnitNameData()
      LoadUnitNameData100000()
      LoadUnitNameData200000()     

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