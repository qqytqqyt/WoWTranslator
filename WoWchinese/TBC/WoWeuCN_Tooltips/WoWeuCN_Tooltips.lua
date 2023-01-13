-- Addon: WoWeuCN-Tooltips
-- Author: qqytqqyt

-- Local variables
local WoWeuCN_Tooltips_version = GetAddOnMetadata("WoWeuCN_Tooltips", "Version");
local WoWeuCN_Tooltips_onDebug = false;      
local WoWeuCN_AddonPrefix = "WoWeuCN";   

local last_time = GetTime();
local last_text = 0;

-- Global variables initialtion
function WoWeuCN_Tooltips_CheckVars()
  if (not WoWeuCN_Tooltips_LastAnnounceDate) then
    WoWeuCN_Tooltips_LastAnnounceDate = 0;
  end
  if (not WoWeuCN_Tooltips_PS) then
     WoWeuCN_Tooltips_PS = {};
  end
  if (not WoWeuCN_Tooltips_SAVED) then
     WoWeuCN_Tooltips_SAVED = {};
  end
  if (not WoWeuCN_Tooltips_MISSING) then
     WoWeuCN_Tooltips_MISSING = {};
  end
  -- Initiation - active
  if (not WoWeuCN_Tooltips_PS["active"]) then
     WoWeuCN_Tooltips_PS["active"] = "1";
  end
  -- Initiation - spell translation
  if (not WoWeuCN_Tooltips_PS["transspell"] ) then
     WoWeuCN_Tooltips_PS["transspell"] = "1";   
  end
  -- Initiation - item translation
  if (not WoWeuCN_Tooltips_PS["transitem"] ) then
     WoWeuCN_Tooltips_PS["transitem"] = "1";   
  end
  -- Initiation - unit translation
  if (not WoWeuCN_Tooltips_PS["transunit"] ) then
     WoWeuCN_Tooltips_PS["transunit"] = "1";   
  end
  -- Initiation - achievement translation
  if (not WoWeuCN_Tooltips_PS["transachievement"] ) then
     WoWeuCN_Tooltips_PS["transachievement"] = "1";   
  end
  -- Initiation - advanced translation
  if (not WoWeuCN_Tooltips_PS["transadvanced"] ) then
     WoWeuCN_Tooltips_PS["transadvanced"] = "1";   
  end
   -- Path version info
  if (not WoWeuCN_Tooltips_PS["patch"]) then
     WoWeuCN_Tooltips_PS["patch"] = GetBuildInfo();
  end
  -- Saved variables per character
  if (not WoWeuCN_Tooltips_PC) then
     WoWeuCN_Tooltips_PC = {};
  end
end

local function loadAllItemData()
  loadItemData0();
end

local function loadAllSpellData()
  loadSpellData0();
end

local function loadAllUnitData()
  loadUnitData0();
end

local function loadAllAchievementData()
  loadAchievementData0();
end

-- commands
function WoWeuCN_Tooltips_SlashCommand(msg)
   if (msg=="on" or msg=="ON") then
      if (WoWeuCN_Tooltips_PS["active"]=="1") then
         print ("WOWeuCN - Tooltips 翻译模块已启用.");
      else
         print ("|cffffff00WOWeuCN - Tooltips 翻译模块已启用.");
         WoWeuCN_Tooltips_PS["active"] = "1";
         WoWeuCN_Tooltips_ToggleButton0:Enable();
         WoWeuCN_Tooltips_ToggleButton1:Enable();
         WoWeuCN_Tooltips_ToggleButton2:Enable();
         WoWeuCN_Tooltips_ToggleButton3:Enable();
      end
   elseif (msg=="off" or msg=="OFF") then
      if (WoWeuCN_Tooltips_PS["active"]=="0") then
         print ("WOWeuCN - Tooltips 翻译模块已关闭.");
      else
         print ("|cffffff00WOWeuCN - Tooltips 翻译模块已关闭.");
         WoWeuCN_Tooltips_PS["active"] = "0";
         WoWeuCN_Tooltips_ToggleButton0:Disable();
         WoWeuCN_Tooltips_ToggleButton1:Disable();
         WoWeuCN_Tooltips_ToggleButton2:Disable();
         WoWeuCN_Tooltips_ToggleButton3:Disable();
      end

    --set scan index
    elseif (string.sub(msg,1,string.len("index"))=="index") then
      local index = string.sub(msg,string.len("index")+2)
      scanIndex(index)

    --clear
    elseif (msg=="clear" or msg=="CLEAR") then
      scanClear()

    -- spell auto scan
    elseif (msg=="scanauto" or msg=="SCANAUTO") then
      scanInit()    
      WoWeuCN_Tooltips_wait(0.1, scanSpellAuto, WoWeuCN_Tooltips_SpellToolIndex, 1, 0)
    
    -- unit auto scan
    elseif (msg=="unitscanauto" or msg=="UNITSCANAUTO") then
      scanInit()
      WoWeuCN_Tooltips_wait(0.1, scanUnitAuto, WoWeuCN_Tooltips_UnitIndex, 1, 0)

    -- item auto scan
    elseif (msg=="itemscanauto" or msg=="ITEMSCANAUTO") then      
      scanInit()
      WoWeuCN_Tooltips_wait(0.1, scanItemAuto, WoWeuCN_Tooltips_ItemIndex, 1, 0)

    -- achivement auto scan
    elseif (msg=="achievescanauto" or msg=="ACHIVESCANAUTO") then      
      scanInit()
      WoWeuCN_Tooltips_wait(0.1, scanAchivementAuto, WoWeuCN_Tooltips_ItemIndex, 1, 0)


    elseif (msg=="") then
        InterfaceOptionsFrame_Show();
        InterfaceOptionsFrame_OpenToCategory("WoWeuCN-Tooltips");
    else
      print ("WOWeuCN-Tooltips - 指令说明:");
      print ("      /woweucn-tooltips on  - 启用Tooltips翻译模块");
      print ("      /woweucn-tooltips off - 禁用Tooltips翻译模块");
   end
end

function WoWeuCN_Tooltips_SetCheckButtonState()
  WoWeuCN_TooltipsCheckButton0:SetChecked(WoWeuCN_Tooltips_PS["active"]=="1");
  WoWeuCN_TooltipsCheckButton3:SetChecked(WoWeuCN_Tooltips_PS["transspell"]=="1");
  WoWeuCN_TooltipsCheckButton4:SetChecked(WoWeuCN_Tooltips_PS["transitem"]=="1");
  WoWeuCN_TooltipsCheckButton5:SetChecked(WoWeuCN_Tooltips_PS["transunit"]=="1");
  WoWeuCN_TooltipsCheckButton6:SetChecked(WoWeuCN_Tooltips_PS["transachievement"]=="1");
  WoWeuCN_TooltipsCheckButton7:SetChecked(WoWeuCN_Tooltips_PS["transadvanced"]=="1");
end

function WoWeuCN_Tooltips_BlizzardOptions()
  -- Create main frame for information text
  local WoWeuCN_TooltipsOptions = CreateFrame("FRAME", "WoWeuCN_Tooltips_Options");
  WoWeuCN_TooltipsOptions.name = "WoWeuCN-Tooltips";
  WoWeuCN_TooltipsOptions.refresh = function (self) WoWeuCN_Tooltips_SetCheckButtonState() end;
  InterfaceOptions_AddCategory(WoWeuCN_TooltipsOptions);

  local WoWeuCN_TooltipsOptionsHeader = WoWeuCN_TooltipsOptions:CreateFontString(nil, "ARTWORK");
  WoWeuCN_TooltipsOptionsHeader:SetFontObject(GameFontNormalLarge);
  WoWeuCN_TooltipsOptionsHeader:SetJustifyH("LEFT"); 
  WoWeuCN_TooltipsOptionsHeader:SetJustifyV("TOP");
  WoWeuCN_TooltipsOptionsHeader:ClearAllPoints();
  WoWeuCN_TooltipsOptionsHeader:SetPoint("TOPLEFT", 16, -16);
  WoWeuCN_TooltipsOptionsHeader:SetText("WoWeuCN-Tooltips, ver. "..WoWeuCN_Tooltips_version.." ("..WoWeuCN_Tooltips_base..") by qqytqqyt © 2023");
  WoWeuCN_TooltipsOptionsHeader:SetFont(WoWeuCN_Tooltips_Font2, 16);

  local WoWeuCN_TooltipsPlayer = WoWeuCN_TooltipsOptions:CreateFontString(nil, "ARTWORK");
  WoWeuCN_TooltipsPlayer:SetFontObject(GameFontNormalLarge);
  WoWeuCN_TooltipsPlayer:SetJustifyH("LEFT"); 
  WoWeuCN_TooltipsPlayer:SetJustifyV("TOP");
  WoWeuCN_TooltipsPlayer:ClearAllPoints();
  WoWeuCN_TooltipsPlayer:SetPoint("TOPRIGHT", WoWeuCN_TooltipsOptionsHeader, "TOPRIGHT", 0, -22);
  WoWeuCN_TooltipsPlayer:SetText("作者 : "..WoWeuCN_Tooltips_Messages.author);
  WoWeuCN_TooltipsPlayer:SetFont(WoWeuCN_Tooltips_Font2, 16);

  local WoWeuCN_TooltipsCheckButton0 = CreateFrame("CheckButton", "WoWeuCN_TooltipsCheckButton0", WoWeuCN_TooltipsOptions, "OptionsCheckButtonTemplate");
  WoWeuCN_TooltipsCheckButton0:SetPoint("TOPLEFT", WoWeuCN_TooltipsOptionsHeader, "BOTTOMLEFT", 0, -44);
  WoWeuCN_TooltipsCheckButton0:SetScript("OnClick", function(self) if (WoWeuCN_Tooltips_PS["active"]=="1") then WoWeuCN_Tooltips_PS["active"]="0" else WoWeuCN_Tooltips_PS["active"]="1" end; end);
  WoWeuCN_TooltipsCheckButton0Text:SetFont(WoWeuCN_Tooltips_Font2, 13);
  WoWeuCN_TooltipsCheckButton0Text:SetText(WoWeuCN_Tooltips_Interface.active);

  local WoWeuCN_TooltipsOptionsMode1 = WoWeuCN_TooltipsOptions:CreateFontString(nil, "ARTWORK");
  WoWeuCN_TooltipsOptionsMode1:SetFontObject(GameFontWhite);
  WoWeuCN_TooltipsOptionsMode1:SetJustifyH("LEFT");
  WoWeuCN_TooltipsOptionsMode1:SetJustifyV("TOP");
  WoWeuCN_TooltipsOptionsMode1:ClearAllPoints();
  WoWeuCN_TooltipsOptionsMode1:SetPoint("TOPLEFT", WoWeuCN_TooltipsCheckButton0, "BOTTOMLEFT", 30, -20);
  WoWeuCN_TooltipsOptionsMode1:SetFont(WoWeuCN_Tooltips_Font2, 13);
  WoWeuCN_TooltipsOptionsMode1:SetText(WoWeuCN_Tooltips_Interface.options1);
  
  local WoWeuCN_TooltipsCheckButton3 = CreateFrame("CheckButton", "WoWeuCN_TooltipsCheckButton3", WoWeuCN_TooltipsOptions, "OptionsCheckButtonTemplate");
  WoWeuCN_TooltipsCheckButton3:SetPoint("TOPLEFT", WoWeuCN_TooltipsOptionsMode1, "BOTTOMLEFT", 0, -5);
  WoWeuCN_TooltipsCheckButton3:SetScript("OnClick", function(self) if (WoWeuCN_Tooltips_PS["transspell"]=="0") then WoWeuCN_Tooltips_PS["transspell"]="1" else WoWeuCN_Tooltips_PS["transspell"]="0" end; end);
  WoWeuCN_TooltipsCheckButton3Text:SetFont(WoWeuCN_Tooltips_Font2, 13);
  WoWeuCN_TooltipsCheckButton3Text:SetText(WoWeuCN_Tooltips_Interface.transspell);
  
  local WoWeuCN_TooltipsCheckButton4 = CreateFrame("CheckButton", "WoWeuCN_TooltipsCheckButton4", WoWeuCN_TooltipsOptions, "OptionsCheckButtonTemplate");
  WoWeuCN_TooltipsCheckButton4:SetPoint("TOPLEFT", WoWeuCN_TooltipsOptionsMode1, "BOTTOMLEFT", 0, -25);
  WoWeuCN_TooltipsCheckButton4:SetScript("OnClick", function(self) if (WoWeuCN_Tooltips_PS["transitem"]=="0") then WoWeuCN_Tooltips_PS["transitem"]="1" else WoWeuCN_Tooltips_PS["transitem"]="0" end; end);
  WoWeuCN_TooltipsCheckButton4Text:SetFont(WoWeuCN_Tooltips_Font2, 13);
  WoWeuCN_TooltipsCheckButton4Text:SetText(WoWeuCN_Tooltips_Interface.transitem);
  
  local WoWeuCN_TooltipsCheckButton5 = CreateFrame("CheckButton", "WoWeuCN_TooltipsCheckButton5", WoWeuCN_TooltipsOptions, "OptionsCheckButtonTemplate");
  WoWeuCN_TooltipsCheckButton5:SetPoint("TOPLEFT", WoWeuCN_TooltipsOptionsMode1, "BOTTOMLEFT", 0, -45);
  WoWeuCN_TooltipsCheckButton5:SetScript("OnClick", function(self) if (WoWeuCN_Tooltips_PS["transunit"]=="0") then WoWeuCN_Tooltips_PS["transunit"]="1" else WoWeuCN_Tooltips_PS["transunit"]="0" end; end);
  WoWeuCN_TooltipsCheckButton5Text:SetFont(WoWeuCN_Tooltips_Font2, 13);
  WoWeuCN_TooltipsCheckButton5Text:SetText(WoWeuCN_Tooltips_Interface.transunit);
  
  local WoWeuCN_TooltipsCheckButton6 = CreateFrame("CheckButton", "WoWeuCN_TooltipsCheckButton6", WoWeuCN_TooltipsOptions, "OptionsCheckButtonTemplate");
  WoWeuCN_TooltipsCheckButton6:SetPoint("TOPLEFT", WoWeuCN_TooltipsOptionsMode1, "BOTTOMLEFT", 0, -65);
  WoWeuCN_TooltipsCheckButton6:SetScript("OnClick", function(self) if (WoWeuCN_Tooltips_PS["transachievement"]=="0") then WoWeuCN_Tooltips_PS["transachievement"]="1" else WoWeuCN_Tooltips_PS["transachievement"]="0" end; end);
  WoWeuCN_TooltipsCheckButton6Text:SetFont(WoWeuCN_Tooltips_Font2, 13);
  WoWeuCN_TooltipsCheckButton6Text:SetText(WoWeuCN_Tooltips_Interface.transachievement);

  local WoWeuCN_TooltipsCheckButton7 = CreateFrame("CheckButton", "WoWeuCN_TooltipsCheckButton7", WoWeuCN_TooltipsOptions, "OptionsCheckButtonTemplate");
  WoWeuCN_TooltipsCheckButton7:SetPoint("TOPLEFT", WoWeuCN_TooltipsOptionsMode1, "BOTTOMLEFT", 0, -85);
  WoWeuCN_TooltipsCheckButton7:SetScript("OnClick", function(self) if (WoWeuCN_Tooltips_PS["transadvanced"]=="0") then WoWeuCN_Tooltips_PS["transadvanced"]="1" else WoWeuCN_Tooltips_PS["transadvanced"]="0" end; end);
  WoWeuCN_TooltipsCheckButton7Text:SetFont(WoWeuCN_Tooltips_Font2, 13);
  WoWeuCN_TooltipsCheckButton7Text:SetText(WoWeuCN_Tooltips_Interface.transadvanced);
end

-- First function called after the add-in has been loaded
function WoWeuCN_Tooltips_OnLoad()
   WoWeuCN_Tooltips = CreateFrame("Frame");
   WoWeuCN_Tooltips:SetScript("OnEvent", WoWeuCN_Tooltips_OnEvent);
   WoWeuCN_Tooltips:RegisterEvent("ADDON_LOADED");
   
   GameTooltip:HookScript("OnTooltipSetSpell", function(...) OnTooltipSpell(..., GameTooltip) end)
   GameTooltip:HookScript("OnTooltipSetItem", function(...) OnTooltipItem(..., GameTooltip) end)
   ItemRefTooltip:HookScript("OnTooltipSetItem", function(...) OnTooltipItem(..., GameTooltip) end)

   EmbeddedItemTooltip:HookScript("OnTooltipSetItem", function(...) OnTooltipItem(..., GameTooltip) end)
   ShoppingTooltip1:HookScript("OnTooltipSetItem", function(...) OnTooltipItem(..., GameTooltip) end)
   ShoppingTooltip2:HookScript("OnTooltipSetItem", function(...) OnTooltipItem(..., GameTooltip) end)
   ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", function(...) OnTooltipItem(..., GameTooltip) end)
   ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", function(...) OnTooltipItem(..., GameTooltip) end)

   GameTooltip:HookScript("OnTooltipSetUnit", function(...) OnTooltipUnit(..., GameTooltip) end)

   if (_G.ElvUISpellBookTooltip ~= nil) then
    _G.ElvUISpellBookTooltip:HookScript("OnTooltipSetSpell", function(...) OnTooltipSpellElvUi(..., GameTooltip) end)
   end

   if LootFrame then
    hooksecurefunc("LootFrame_UpdateButton", function(...) OnLootUpdate(...) end);
   end
   if MerchantFrame then
    hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function(...) OnMerchantInfoUpdate(...) end);
   end
   
   hooksecurefunc("SpellButton_UpdateButton", function(...) OnSpellBookUpdate(...) end);
   RegisterChatFilterEvents()

   qcSpellInformationTooltipSetup();
   loadAllSpellData()
   loadAllItemData()
   loadAllUnitData()
   loadAllAchievementData()
end

local replacement = { 
  ["瞬发"] = "À",
  ["施法时间"] = "Á",
  ["码射程"] = "Â",
  ["秒"] = "Ã",
  ["冷却时间"] = "Ä",
  ["|cffffd100"] = "Å",
  ["|r|cff7f7f7f"] = "Æ",
  ["|r"] = "Ç",
  ["近战范围"] = "È",
  ["持续"] = "É",
  ["造成"] = "Ê",

  ["点伤害"] = "Ë",
  ["点治疗"] = "Ì",
  ["点生命值"] = "Í",
  ["点法力值"] = "Î",
  ["点物理伤害"] = "Ï",
  ["点魔法伤害"] = "Ð",
  ["点火焰伤害"] = "Ñ",
  ["点冰霜伤害"] = "Ò",
  ["点暗影伤害"] = "Ó",
  ["点神圣伤害"] = "Ô",
  ["点奥术伤害"] = "Õ",
  ["点混乱伤害"] = "Ö",
  ["点流血伤害"] = "Ø"
}

function ReplaceText(s)
  if (s == nil) then
    return nil
  end

  for origin,new in pairs(replacement) do
    s = string.gsub(s, new, origin)
  end

  return s
end

function GetFirstLineColorCode(...)
  local colorCode = _G["ORANGE_FONT_COLOR_CODE"]
  for regionIndex = 1, select("#", ...) do
    local region = select(regionIndex, ...)
    if region and region:GetObjectType() == "FontString" then
      local text = region:GetText() -- string or nil
      if (text ~= nil) then
        if (text ~= " ") then
          local r, g, b, a = region:GetTextColor()
          colorCode = string.format("%02x", a * 255) .. string.format("%02x", r * 255) .. string.format("%02x", g * 255) .. string.format("%02x", b * 255)
          return "|c" .. colorCode
        end
      end
    end
  end
  return colorCode
end

function split(s, delimiter)
  if (s == nil) then
    return nil
  end
  result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
      table.insert(result, match);
  end
  return result;
end

function OnSpellBookUpdate(self)
  if (WoWeuCN_Tooltips_PS["active"]=="0" or WoWeuCN_Tooltips_PS["transadvanced"]=="0") then
    return
  end

  local slot, slotType, slotID = SpellBook_GetSpellBookSlot(self);
  
	if ( slot ) then
    texture = GetSpellTexture(slot, SpellBookFrame.bookType);
  end
  
	if ( not slot or not texture or (strlen(texture) == 0) or (slotType == "FUTURESPELL" and Kiosk.IsEnabled())) then
    return
  end

	local name = self:GetName();
  local spellString = _G[name.."SpellName"];
  if spellString then
    local spellName, _, spellID = GetSpellBookItemName(slot, SpellBookFrame.bookType);
    local spellData = GetSpellData(spellID)
    if ( spellData ) then
      spellString:SetText(spellData[1])
    end
  end
end

function OnMerchantInfoUpdate(...)
  if (WoWeuCN_Tooltips_PS["active"]=="0" or WoWeuCN_Tooltips_PS["transadvanced"]=="0") then
    return
  end

  for i=1, MERCHANT_ITEMS_PER_PAGE do
    local itemButton = _G["MerchantItem"..i.."ItemButton"];
    local numMerchantItems = GetMerchantNumItems();
    if itemButton then
      local itemLink = itemButton.link
      if itemLink then
        local itemID = string.match(itemLink, 'Hitem:(%d+):')
        local itemData = GetItemData(itemID)
        if itemData and _G["MerchantItem"..i.."Name"] and _G["MerchantItem"..i.."Name"]:GetText() ~= nil then
          _G["MerchantItem"..i.."Name"]:SetText(itemData[1])
        end
      end
    end
  end
end

function OnLootUpdate(index)
  if (WoWeuCN_Tooltips_PS["active"]=="0" or WoWeuCN_Tooltips_PS["transadvanced"]=="0") then
    return
  end
  
	local numLootItems = LootFrame.numLootItems;
	--Logic to determine how many items to show per page
	local numLootToShow = LOOTFRAME_NUMBUTTONS;
  local self = LootFrame;
	if( self.AutoLootTable ) then
		numLootItems = #self.AutoLootTable;
	end
	if ( numLootItems > LOOTFRAME_NUMBUTTONS ) then
		numLootToShow = numLootToShow - 1; -- make space for the page buttons
	end
  local slot = (numLootToShow * (LootFrame.page - 1)) + index;

  if ( slot <= numLootItems ) then
		if ( (LootSlotHasItem(slot)  or (self.AutoLootTable and self.AutoLootTable[slot]) )and index <= numLootToShow) then
			local itemLink	= GetLootSlotLink(slot);
      if not itemLink then
        return
      end

      local itemID = string.match(itemLink, 'Hitem:(%d+):')
      local itemData = GetItemData(itemID)
      
      if itemData then
        local text = _G["LootButton"..index.."Text"];
        if text then
          text:SetText(itemData[1])
        end
      end
    end
  end
end

function OnAchievement(button, category, achievement, selectionID, renderOffScreen)  
  if (WoWeuCN_Tooltips_PS["active"]=="0" or WoWeuCN_Tooltips_PS["transachievement"]=="0") then
    return
  end

  local id, _, _, _, _, _, _, _, _, icon= GetAchievementInfo(category, achievement);
  if id then
      local achievementData = GetAchievementData(id)
      if ( achievementData ) then
        local title = achievementData[1]
        button.label:SetText(title);
        local description = achievementData[2]
        if ( description ) then
          if (button.description) then
            button.description:SetText(description);
          end
          if (button.hiddenDescription) then
            button.hiddenDescription:SetText(description);
          end
        end
      end
      
  end
end

function OnAchievementSummary(...)
  if (WoWeuCN_Tooltips_PS["active"]=="0" or WoWeuCN_Tooltips_PS["transachievement"]=="0") then
    return
  end

  for i=1, 4 do
    id = select(i, ...);
    local button = _G["AchievementFrameSummaryAchievement"..i];	
    if button and id then
      local achievementData = GetAchievementData(id)
      if ( achievementData ) then
        local title = achievementData[1]
        button.label:SetText(title);
        local description = achievementData[2]
        if ( description and button.description ) then
          button.description:SetText(description);
        end
      end
    end
  end
end

function GetAchievementData(id)
  if (id == nil) then
    return nil
  end
  local str_id = tostring(id)
  local num_id = tonumber(id)
  local dataIndex = nil
  if (num_id >= 0 and num_id < 100000) then
    dataIndex = WoWeuCN_Tooltips_AchievementIndexData_0[num_id]
  end

  if (dataIndex == nil) then
    return nil
  end

  if (num_id >= 0 and num_id < 100000) then    
    return split(WoWeuCN_Tooltips_AchievementData_0[dataIndex], '£')
  end

  return nil
end

function OnTooltipUnit(self, tooltip)
  if (WoWeuCN_Tooltips_PS["active"]=="0" or WoWeuCN_Tooltips_PS["transunit"]=="0") then
    return
  end
	-- Case for linked unit
  local unitName, unit = self:GetUnit()
  if (unit == nil) then 
    return
  end

  local unitGUID = UnitGUID(unit);
  local type, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", unitGUID);
  local unitData = GetUnitData(npc_id)

  if ( unitData ) then  
    self:AddLine(" ")
    for i = 1, #unitData do
      local text = unitData[i]
      if (i < 2) then
        local colorCode = GetFirstLineColorCode(self :GetRegions())
        self:AddLine(colorCode .. text .. "|r", 1, 1, 1, 1)
      else
        self:AddLine(text, 1, 1, 1, 1)
      end
    end
  end
end

function GetUnitData(id)
  if (id == nil) then
    return nil
  end
  local str_id = tostring(id)
  local num_id = tonumber(id)
  local dataIndex = nil
  if (num_id >= 0 and num_id < 100000) then
    dataIndex = WoWeuCN_Tooltips_UnitIndexData_0[num_id]
  elseif (num_id >= 100000 and num_id < 200000) then
    dataIndex = WoWeuCN_Tooltips_UnitIndexData_100000[num_id - 100000]
  end

  if (dataIndex == nil) then
    return nil
  end

  if (num_id >= 0 and num_id < 100000) then    
    return split(WoWeuCN_Tooltips_UnitData_0[dataIndex], '£')
  elseif (num_id >= 100000 and num_id < 200000) then    
    return split(WoWeuCN_Tooltips_UnitData_100000[dataIndex], '£')
  end

  return nil
end

function OnTooltipItem(self, tooltip)
  if (WoWeuCN_Tooltips_PS["active"]=="0" or WoWeuCN_Tooltips_PS["transitem"]=="0") then
    return
  end
	-- Case for linked spell
  local _, itemLink = self:GetItem()
  if (itemLink == nil) then 
    return
  end

  local itemID = string.match(itemLink, 'Hitem:(%d+):')
  local itemData = GetItemData(itemID)
  if ( itemData ) then  
    local lines = self:NumLines()
    for i= 1, lines do
      local line = _G[("GameTooltipTextLeft%d"):format(i)]
      if not (line and line:GetText()) then
        line = _G[("ItemRefTooltipTextLeft%d"):format(i)]
      end
      if line and line:GetText() and string.len(line:GetText()) ~= 1 and itemData[1] and itemData[1]:find(line:GetText()) then
        return
      end
    end
    self:AddLine(" ")
    for i = 1, #itemData do
      local region = itemData[i]
      self:AddLine(region, 1, 1, 1, 1)
    end
  end
end

function GetItemData(id)
  if (id == nil) then
    return nil
  end
  local str_id = tostring(id)
  local num_id = tonumber(id)
  local num_id = tonumber(id) 
  local dataIndex = nil
  if (num_id >= 0 and num_id < 100000) then
    dataIndex = WoWeuCN_Tooltips_ItemIndexData_0[num_id]
  elseif (num_id >= 100000 and num_id < 200000) then
    dataIndex = WoWeuCN_Tooltips_ItemIndexData_100000[num_id - 100000]
  end

  if (dataIndex == nil) then
    return nil
  end

  if (num_id >= 0 and num_id < 100000) then
    return split(WoWeuCN_Tooltips_ItemData_0[dataIndex], '£')
  elseif (num_id >= 100000 and num_id < 200000) then
    return split(WoWeuCN_Tooltips_ItemData_100000[dataIndex], '£')
  end

  return nil
end

function OnTooltipSpellElvUi(self)
  if (WoWeuCN_Tooltips_PS["active"]=="0" or WoWeuCN_Tooltips_PS["transspell"]=="0") then
    return
  end
	-- Case for linked spell
  local name,id = self:GetSpell()
  SetSpellTooltip(self, id)
end

function OnTooltipSpell(self, tooltip)
  if (WoWeuCN_Tooltips_PS["active"]=="0" or WoWeuCN_Tooltips_PS["transspell"]=="0") then
    return
  end
	-- Case for linked spell
  local name,id = self:GetSpell()
  SetSpellTooltip(self, id)
end

local SetUnitAura = GameTooltip.SetUnitAura
GameTooltip.SetUnitAura = function(self, unit, index, filter) 
    local spellId = select(10, UnitAura(unit, index, filter))
    SetUnitAura(self, unit, index, filter)
    SetSpellTooltip(self, spellId)
end

local SetUnitBuff = GameTooltip.SetUnitBuff
GameTooltip.SetUnitBuff = function(self, unit, index, filter) 
    local spellId = select(10, UnitBuff(unit, index, filter))
    SetUnitBuff(self, unit, index, filter)
    SetSpellTooltip(self, spellId)
end

local SetUnitDebuff = GameTooltip.SetUnitDebuff
GameTooltip.SetUnitDebuff = function(self, unit, index, filter) 
    local spellId = select(10, UnitDebuff(unit, index, filter))
    SetUnitDebuff(self, unit, index, filter)
    SetSpellTooltip(self, spellId)
end

function SetSpellTooltip(self, id)
  local spellData = GetSpellData(id)
  if ( spellData ) then
    local lines = self:NumLines()
    for i= 1, lines do
      local line = _G[("GameTooltipTextLeft%d"):format(i)]
      if line and line:GetText() and line:GetText():find(spellData[1]) then
        return
      end
    end
  
    self:AddLine(" ")
    for i = 1, #spellData do
      local region = spellData[i]
      region = ReplaceText(region)
      self:AddLine(region, 1, 1, 1, 1)
    end
    self:Show()
  end
end

function GetSpellData(spellId)
  if (spellId == nil) then
    return nil
  end
  local str_id = tostring(spellId)
  local id = tonumber(spellId)
  local dataIndex = nil
  if (id >= 0 and id < 100000) then
    dataIndex = WoWeuCN_Tooltips_SpellIndexData_0[id]
  elseif (id >= 100000 and id < 200000) then
    dataIndex = WoWeuCN_Tooltips_SpellIndexData_100000[id - 100000]
  elseif (id >= 200000 and id < 300000) then
    dataIndex = WoWeuCN_Tooltips_SpellIndexData_200000[id - 200000]
  elseif (id >= 300000 and id < 400000) then
    dataIndex = WoWeuCN_Tooltips_SpellIndexData_300000[id - 300000]
  end

  if (dataIndex == nil) then
    return nil
  end
  local spellData = nil

  if (id >= 0 and id < 100000) then
    spellData = split(WoWeuCN_Tooltips_SpellData_0[dataIndex], '£')
  elseif (id >= 100000 and id < 200000) then
    spellData = split(WoWeuCN_Tooltips_SpellData_100000[dataIndex], '£')
  elseif (id >= 200000 and id < 300000) then
    spellData = split(WoWeuCN_Tooltips_SpellData_200000[dataIndex], '£')
  elseif (id >= 300000 and id < 400000) then
    spellData =  split(WoWeuCN_Tooltips_SpellData_300000[dataIndex], '£')
  end

  if ( spellData ) then
    while (string.find(spellData[1], "¿")) do
      spellData = GetSpellData(string.sub(spellData[1], 3))
      if (not spellData) then
        return
      end
    end
  end

  return spellData
end

-- Even handlers
function WoWeuCN_Tooltips_OnEvent(self, event, name, ...)
   if (event=="ADDON_LOADED" and name=="WoWeuCN_Tooltips") then
      SlashCmdList["WOWEUCN_TOOLTIPS"] = function(msg) WoWeuCN_Tooltips_SlashCommand(msg); end
      SLASH_WOWEUCN_TOOLTIPS1 = "/woweucn-tooltips";
      WoWeuCN_Tooltips_CheckVars();
      -- Create interface Options in Blizzard-Interface-Addons
      WoWeuCN_Tooltips_BlizzardOptions();
      WoWeuCN_Tooltips_wait(2, Broadcast)
      WoWeuCN_Tooltips:UnregisterEvent("ADDON_LOADED");
      WoWeuCN_Tooltips.ADDON_LOADED = nil;
      return
   end
end

local achievementHooked = false

local function OnEvent(self, event, prefix, text, channel, sender, ...)
  if event == "CHAT_MSG_ADDON" and prefix == WoWeuCN_AddonPrefix then
    if text == "VERSION" then
      C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, "WoWeuCN-Tooltips ver. "..WoWeuCN_Tooltips_version, channel)
    else
      --print(text .. " " .. sender)
    end
  end
  
  if (event=="ADDON_LOADED" and name~="WoWeuCN_Tooltips" and not achievementHooked and AchievementFrame) then
    hooksecurefunc("AchievementButton_DisplayAchievement", function(...) OnAchievement(...) end);
    hooksecurefunc("AchievementFrameSummary_UpdateAchievements", function(...) OnAchievementSummary(...) end);    
    achievementHooked = true
  end
end

function Broadcast()
  print ("|cffffff00WoWeuCN-Tooltips ver. "..WoWeuCN_Tooltips_version.." - "..WoWeuCN_Tooltips_Messages.loaded);
  print ("|cffffff00高级界面翻译已启用，如需关闭请在插件设置里更改。如遇字体问题可尝试在战网游戏设置中安装中文语言包。|r");

  local f = CreateFrame("Frame")
  f:RegisterEvent("CHAT_MSG_ADDON")
  f:RegisterEvent("ADDON_LOADED")
  f:SetScript("OnEvent", OnEvent)
  local name,title,_,enabled = GetAddOnInfo('WoWeuCN_Quests')
  if (enabled == true) then
    return
  elseif (title == nil) then
    local addonName = _G["GREEN_FONT_COLOR_CODE"] .. "Quest Translator - Chinese|r"
    print ("|cffffff00欢迎使用悬停提示汉化插件。如需中文任务汉化请安装 " .. addonName .. " 翻译插件。|r");
  end
  
  C_ChatInfo.RegisterAddonMessagePrefix(WoWeuCN_AddonPrefix)
  local regionCode = GetCurrentRegion()
  if (regionCode ~= 3) then
    print ("|cffffff00本插件主要服务欧洲服务器玩家。你所在的服务器区域支持中文客户端，如有需要请搜索战网修改客户端语言教程修改语言，直接使用中文进行游戏。|r");
    return
  end
  
  local name, _, rank = GetGuildInfo("player");
  if (name == nil or rank > 2) then
     return
  end
  if (time() - WoWeuCN_Tooltips_LastAnnounceDate < WowenCN_Tooltips_WeekDiff) then
     return
  end
  
  local bNetTagInfo = _G["GREEN_FONT_COLOR_CODE"] .. "<>|r" 
  WoWeuCN_Tooltips_LastAnnounceDate = time()
end

