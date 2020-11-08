-- Addon: WoWeuCN-Tooltips
-- Author: qqytqqyt

-- Local variables
local WoWeuCN_Tooltips_version = GetAddOnMetadata("WoWeuCN_Tooltips", "Version");
local WoWeuCN_Tooltips_onDebug = false;      

local last_time = GetTime();
local last_text = 0;

-- Global variables initialtion
function WoWeuCN_Tooltips_CheckVars()
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
   -- Path version info
  if (not WoWeuCN_Tooltips_PS["patch"]) then
     WoWeuCN_Tooltips_PS["patch"] = GetBuildInfo();
  end
  -- Saved variables per character
  if (not WoWeuCN_Tooltips_PC) then
     WoWeuCN_Tooltips_PC = {};
  end
end

-- wait functions from QTR
local QTR_waitFrame = nil;
local QTR_waitTable = {};

function QTR_wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if (QTR_waitFrame == nil) then
    QTR_waitFrame = CreateFrame("Frame","QTR_WaitFrame", UIParent);
    QTR_waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #QTR_waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(QTR_waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(QTR_waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(QTR_waitTable,{delay,func,{...}});
  return true;
end

local function scanAuto(startIndex, attempt, counter)
  if (startIndex > 400000) then
    return;
  end
  for i = startIndex, startIndex + 250 do
    qcSpellInformationTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    qcSpellInformationTooltip:ClearLines()
    qcSpellInformationTooltip:SetHyperlink('spell:' .. i)
    qcSpellInformationTooltip:Show()
    local text =  EnumerateTooltipStyledLines(qcSpellInformationTooltip)
    if (text ~= '' and text ~= nil) then
      if (i >=0 and i < 100000) then
        if (WoWeuCN_Tooltips_SpellToolTips0[i .. ''] == nil or string.len(WoWeuCN_Tooltips_SpellToolTips0[i .. '']) < string.len(text)) then
          WoWeuCN_Tooltips_SpellToolTips0[i .. ''] = text
        end
      elseif (i >=100000 and i < 200000) then
        if (WoWeuCN_Tooltips_SpellToolTips100000[i .. ''] == nil or string.len(WoWeuCN_Tooltips_SpellToolTips100000[i .. '']) < string.len(text)) then
          WoWeuCN_Tooltips_SpellToolTips100000[i .. ''] = text
        end
      elseif (i >=200000 and i < 300000) then
        if (WoWeuCN_Tooltips_SpellToolTips200000[i .. ''] == nil or string.len(WoWeuCN_Tooltips_SpellToolTips200000[i .. '']) < string.len(text)) then
          WoWeuCN_Tooltips_SpellToolTips200000[i .. ''] = text
        end
      elseif (i >=300000 and i < 400000) then
        if (WoWeuCN_Tooltips_SpellToolTips300000[i .. ''] == nil or string.len(WoWeuCN_Tooltips_SpellToolTips300000[i .. '']) < string.len(text)) then
          WoWeuCN_Tooltips_SpellToolTips300000[i .. ''] = text
        end
      end
      print(i)
    end
  end
  print(attempt)
  print(counter)
  WoWeuCN_Tooltips_SpellToolIndex = startIndex
  if (counter >= 5) then
    QTR_wait(0.5, scanAuto, startIndex + 250, attempt + 1, 0)
  else
    QTR_wait(0.5, scanAuto, startIndex, attempt + 1, counter + 1)
  end
end

local function scanItemAuto(startIndex, attempt, counter)
  if (startIndex > 200000) then
    return;
  end
  for i = startIndex, startIndex + 300 do
    local itemType, itemSubType, _, _, _, _, classID, subclassID = select(6, GetItemInfo(i))
    if (classID~=nil) then
      qcSpellInformationTooltip:SetOwner(UIParent, "ANCHOR_NONE")
      qcSpellInformationTooltip:ClearLines()
      qcSpellInformationTooltip:SetHyperlink('item:' .. i .. ':0:0:0:0:0:0:0')
      qcSpellInformationTooltip:Show()
      local text = EnumerateTooltipStyledLines(qcSpellInformationTooltip)
      text = text .. '{{{' .. classID .. '}}}'
      if (text ~= '' and text ~= nil) then
        if (i >=0 and i < 100000) then
          if (WoWeuCN_Tooltips_ItemToolTips0[i .. ''] == nil or string.len(WoWeuCN_Tooltips_ItemToolTips0[i .. '']) < string.len(text)) then
            WoWeuCN_Tooltips_ItemToolTips0[i .. ''] = text
          end
        elseif (i >=100000 and i < 200000) then
          if (WoWeuCN_Tooltips_ItemToolTips100000[i .. ''] == nil or string.len(WoWeuCN_Tooltips_ItemToolTips100000[i .. '']) < string.len(text)) then
            WoWeuCN_Tooltips_ItemToolTips100000[i .. ''] = text
          end
          print(i)
        end
      end
    else
      if (classId==nil) then
        print(i .. " skip")
      else
        print(i .. " gear")
      end
    end
  end
  print(attempt)
  print(counter)
  WoWeuCN_Tooltips_ItemIndex = startIndex
  if (counter >= 5) then
    QTR_wait(0.8, scanItemAuto, startIndex + 300, attempt + 1, 0)
  else
    QTR_wait(0.8, scanItemAuto, startIndex, attempt + 1, counter + 1)
  end
end

local function loadAllItemData()
  loadItemData0();
  loadItemData100000();
end

local function loadAllSpellData()
  loadSpellData0();
  loadSpellData100000();
  loadSpellData200000();
  loadSpellData300000();
end


local function EnumerateTooltipStyledLines_helper(...)
  local texts = '';
  local hasObjectivesSet = false
    for i = 1, select("#", ...) do
        local region = select(i, ...)
        if region and region:GetObjectType() == "FontString" then
      local text = region:GetText() -- string or nil
			if (text ~= nil) then
        if (text ~= " ")
          then
            text = "{{" .. text .. "}}"
            local r, g, b, a = region:GetTextColor()
            text = text .. "[[" .. r .. "]]" .. "[[" .. g .. "]]" .. "[[" .. b .. "]]"
          end
        print(i)
        print(text)
        texts = texts .. text	
			end
        end
	end
	return texts
end

function EnumerateTooltipStyledLines(tooltip) -- good for script handlers that pass the tooltip as the first argument.
  return EnumerateTooltipStyledLines_helper(tooltip:GetRegions())
end

function qcSpellInformationTooltipSetup() -- *
	qcSpellInformationTooltip = CreateFrame("GameTooltip", "qcSpellInformationTooltip", UIParent, "GameTooltipTemplate")
	qcSpellInformationTooltip:SetFrameStrata("TOOLTIP")
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
      end
      -- spell option
      elseif (msg=="spell on" or msg=="SPELL ON" or msg=="spell 1") then
          if (WoWeuCN_Tooltips_PS["transspell"]=="1") then
            print ("WOWeuCN - 翻译法术Tooltips : 启用.");
          else
            print ("|cffffff00WOWeuCN - 翻译法术Tooltips : 启用.");
            WoWeuCN_Tooltips_PS["transspell"] = "1";
          end
      elseif (msg=="spell off" or msg=="spell OFF" or msg=="spell 0") then
          if (WoWeuCN_Tooltips_PS["transspell"]=="0") then
            print ("WOWeuCN - 翻译法术Tooltips : 禁用.");
          else
            print ("|cffffff00WOWeuCN - 翻译法术Tooltips : 禁用.");
            WoWeuCN_Tooltips_PS["transspell"] = "0";
          end
      elseif (msg=="spell" or msg=="SPELL") then
          if (WoWeuCN_Tooltips_PS["transspell"]=="1") then
            print ("WOWeuCN - 翻译法术Tooltips : 启用.");
          else
            print ("WOWeuCN - 翻译法术Tooltips : 禁用.");
          end
      
      -- item option
      elseif (msg=="item on" or msg=="ITEM ON" or msg=="item 1") then
        if (WoWeuCN_Tooltips_PS["transitem"]=="1") then
          print ("WOWeuCN - 翻译道具Tooltips : 启用.");
        else
          print ("|cffffff00WOWeuCN - 翻译道具Tooltips : 启用.");
          WoWeuCN_Tooltips_PS["transitem"] = "1";
        end
    elseif (msg=="item off" or msg=="ITEM OFF" or msg=="item 0") then
        if (WoWeuCN_Tooltips_PS["transitem"]=="0") then
          print ("WOWeuCN - 翻译道具Tooltips : 禁用.");
        else
          print ("|cffffff00WOWeuCN - 翻译道具Tooltips : 禁用.");
          WoWeuCN_Tooltips_PS["transitem"] = "0";
        end
    elseif (msg=="item" or msg=="ITEM") then
        if (WoWeuCN_Tooltips_PS["transitem"]=="1") then
          print ("WOWeuCN - 翻译道具Tooltips : 启用.");
        else
          print ("WOWeuCN - 翻译道具Tooltips : 禁用.");
        end

    --spell scan
    elseif (msg=="back" or msg=="BACK") then
      WoWeuCN_Tooltips_SpellToolIndex = WoWeuCN_Tooltips_SpellToolIndex - 500;
      print(WoWeuCN_Tooltips_SpellToolIndex);
    elseif (msg=="clear" or msg=="CLEAR") then
      WoWeuCN_Tooltips_SpellToolIndex = 1;
      WoWeuCN_Tooltips_SpellToolTips0 = {} 
      WoWeuCN_Tooltips_SpellToolTips100000 = {} 
      WoWeuCN_Tooltips_SpellToolTips200000 = {} 
      WoWeuCN_Tooltips_SpellToolTips300000 = {} 
      print("Clear");
    elseif (msg=="reset" or msg=="RESET") then
      WoWeuCN_Tooltips_SpellToolIndex = 1;
      print("Reset");

    -- spell auto scan
    elseif (msg=="scanauto" or msg=="SCANAUTO") then
      if (WoWeuCN_Tooltips_SpellToolTips0 == nil) then
        WoWeuCN_Tooltips_SpellToolTips0 = {} 
      end
      if (WoWeuCN_Tooltips_SpellToolTips100000 == nil) then
        WoWeuCN_Tooltips_SpellToolTips100000 = {} 
      end
      if (WoWeuCN_Tooltips_SpellToolTips200000 == nil) then
        WoWeuCN_Tooltips_SpellToolTips200000 = {} 
      end
      if (WoWeuCN_Tooltips_SpellToolTips300000 == nil) then
        WoWeuCN_Tooltips_SpellToolTips300000 = {} 
      end
      if (WoWeuCN_Tooltips_SpellToolIndex == nil) then
        WoWeuCN_Tooltips_SpellToolIndex = 1
      end

      QTR_wait(0.1, scanAuto, WoWeuCN_Tooltips_SpellToolIndex, 1, 0)

    -- item scan
    elseif (msg=="itemreset" or msg=="ITEMRESET") then
      WoWeuCN_Tooltips_ItemIndex = 1;
      print("Reset");
    elseif (msg=="itemclear" or msg=="ITEMCLEAR") then
      WoWeuCN_Tooltips_ItemToolTips0 = {} 
      WoWeuCN_Tooltips_ItemToolTips100000 = {} 
      WoWeuCN_Tooltips_ItemIndex = 1
      print("Clear");
    
    -- item auto scan
    elseif (msg=="itemscanauto" or msg=="ITEMSCANAUTO") then      
      if (WoWeuCN_Tooltips_ItemIndex == nil) then
        WoWeuCN_Tooltips_ItemIndex = 1
      end
      if (WoWeuCN_Tooltips_ItemToolTips0 == nil) then
        WoWeuCN_Tooltips_ItemToolTips0 = {} 
      end
      if (WoWeuCN_Tooltips_ItemToolTips100000 == nil) then
        WoWeuCN_Tooltips_ItemToolTips100000 = {} 
      end
      QTR_wait(0.1, scanItemAuto, WoWeuCN_Tooltips_ItemIndex, 1, 0)
    elseif (msg=="") then
        InterfaceOptionsFrame_Show();
        InterfaceOptionsFrame_OpenToCategory("WoWeuCN-Tooltips");
    else
      print ("WOWeuCN-Tooltips - 指令说明:");
      print ("      /woweucn-tooltips on  - 启用Tooltips翻译模块");
      print ("      /woweucn-tooltips off - 禁用Tooltips翻译模块");
      print ("      /woweucn-tooltips spell on  - 启用法术Tooltips翻译");
      print ("      /woweucn-tooltips spell off - 禁用法术Tooltips翻译");
      print ("      /woweucn-tooltips item on  - 启用道具Tooltips翻译");
      print ("      /woweucn-tooltips item off - 禁用道具Tooltips翻译");
   end
end



function WoWeuCN_Tooltips_SetCheckButtonState()
  WoWeuCN_TooltipsCheckButton0:SetChecked(WoWeuCN_Tooltips_PS["active"]=="1");
  WoWeuCN_TooltipsCheckButton3:SetChecked(WoWeuCN_Tooltips_PS["transspell"]=="1");
  WoWeuCN_TooltipsCheckButton4:SetChecked(WoWeuCN_Tooltips_PS["transitem"]=="1");
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
  WoWeuCN_TooltipsOptionsHeader:SetText("WoWeuCN-Tooltips, ver. "..WoWeuCN_Tooltips_version.." ("..WoWeuCN_Tooltips_base..") by qqytqqyt © 2020");
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
  
end

-- First function called after the add-in has been loaded
function WoWeuCN_Tooltips_OnLoad()
   WoWeuCN_Tooltips = CreateFrame("Frame");
   WoWeuCN_Tooltips:SetScript("OnEvent", WoWeuCN_Tooltips_OnEvent);
   WoWeuCN_Tooltips:RegisterEvent("ADDON_LOADED");
   
   GameTooltip:HookScript("OnTooltipSetSpell", function(...) OnTooltipSpell(..., GameTooltip) end)
   GameTooltip:HookScript("OnTooltipSetItem", function(...) OnTooltipItem(..., GameTooltip) end)

   if (_G.ElvUISpellBookTooltip ~= nil) then
    _G.ElvUISpellBookTooltip:HookScript("OnTooltipSetSpell", function(...) OnTooltipSpellElvUi(..., GameTooltip) end)
   end
   
   qcSpellInformationTooltipSetup();
   loadAllSpellData()
   loadAllItemData()
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
    local lines = tooltip:NumLines()
    for i= 1, lines do
      local line = _G[("GameTooltipTextLeft%d"):format(i)]
      if line and line:GetText() and line:GetText():find(itemData[1]) then
        return
      end
    end
    tooltip:AddLine(" ")
    for i = 1, #itemData do
      local region = itemData[i]
      tooltip:AddLine(region, 1, 1, 1, 1)
    end
  end
end

function GetItemData(id)
  if (id == nil) then
    return nil
  end
  local str_id = tostring(id)
  local num_id = tonumber(id)
  if (num_id >= 0 and num_id < 50000) then
    return  WoWeuCN_Tooltips_ItemData_0[str_id]
  elseif (num_id >= 10000 and num_id < 200000) then
    return  WoWeuCN_Tooltips_ItemData_100000[str_id]
  end

  return nil
end

function OnTooltipSpellElvUi(self)
  if (WoWeuCN_Tooltips_PS["active"]=="0" or WoWeuCN_Tooltips_PS["transspell"]=="0") then
    return
  end
	-- Case for linked spell
  local name,id = self:GetSpell()
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
      self:AddLine(region, 1, 1, 1, 1)
    end
  end
end

function OnTooltipSpell(self, tooltip)
  if (WoWeuCN_Tooltips_PS["active"]=="0" or WoWeuCN_Tooltips_PS["transspell"]=="0") then
    return
  end
	-- Case for linked spell
  local name,id = self:GetSpell()
  local spellData = GetSpellData(id)
  if ( spellData ) then
    local lines = tooltip:NumLines()
    for i= 1, lines do
      local line = _G[("GameTooltipTextLeft%d"):format(i)]
      if line and line:GetText() and line:GetText():find(spellData[1]) then
        return
      end
    end
  
    tooltip:AddLine(" ")
    for i = 1, #spellData do
      local region = spellData[i]
      tooltip:AddLine(region, 1, 1, 1, 1)
    end
  end
end

function GetSpellData(id)
  if (id == nil) then
    return nil
  end
  local str_id = tostring(id)
  if (id >= 0 and id < 100000) then
    return  WoWeuCN_Tooltips_SpellData_0[str_id]
  elseif (id >= 100000 and id < 200000) then
    return  WoWeuCN_Tooltips_SpellData_100000[str_id]
  elseif (id >= 200000 and id < 300000) then
    return  WoWeuCN_Tooltips_SpellData_200000[str_id]
  elseif (id >= 300000 and id < 400000) then
    return  WoWeuCN_Tooltips_SpellData_300000[str_id]
  end

  return nil
end

-- Even handlers
function WoWeuCN_Tooltips_OnEvent(self, event, name, ...)
   if (event=="ADDON_LOADED" and name=="WoWeuCN_Tooltips") then
      SlashCmdList["WOWEUCN_TOOLTIPS"] = function(msg) WoWeuCN_Tooltips_SlashCommand(msg); end
      SLASH_WOWEUCN_TOOLTIPS1 = "/woweucn-tooltips";
      WoWeuCN_Tooltips_CheckVars();
      -- Create interface Options in Blizzard-Interface-Addons
      WoWeuCN_Tooltips_BlizzardOptions();
      QTR_wait(2, Broadcast)
      WoWeuCN_Tooltips:UnregisterEvent("ADDON_LOADED");
      WoWeuCN_Tooltips.ADDON_LOADED = nil;
   end
end

function Broadcast()
  print ("|cffffff00WoWeuCN-Tooltips ver. "..WoWeuCN_Tooltips_version.." - "..WoWeuCN_Tooltips_Messages.loaded);
  local name,_,_,enabled = GetAddOnInfo('WoWeuCN_Quests')
  if (enabled == true) then
    return
  end
  local regionCode = GetCurrentRegion()
  if (regionCode ~= 3) then
    print ("|cffffff00本插件主要服务欧洲服务器玩家。你所在的服务器区域支持中文客户端，如有需要请搜索战网修改客户端语言教程修改语言，直接使用中文进行游戏。|r");
    return
  end
end

