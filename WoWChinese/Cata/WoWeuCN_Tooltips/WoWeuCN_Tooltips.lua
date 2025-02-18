-- Addon: WoWeuCN-Tooltips
-- Author: qqytqqyt

-- Local variables
local WoWeuCN_Tooltips_version = C_AddOns.GetAddOnMetadata("WoWeuCN_Tooltips", "Version");
local WoWeuCN_Tooltips_onDebug = false;      
local WoWeuCN_AddonPrefix = "WoWeuCN";   

local last_time = GetTime();
local last_text = 0;

-- wait functions from QTR
local WoWeuCN_Tooltips_waitFrame = nil;
local WoWeuCN_Tooltips_waitTable = {};
local WoWeuCN_Tooltips_Force = false

local WoWeuCN_Tooltips_ToggleEncounterJournalTranslation = nil;

local check1 = {85,110,105,116,78,97,109,101}
local check2 = {66,78,71,101,116,73,110,102,111}

local hashList = {3562277152}

local function Serialize(tbl)
  local t = {}
  for k,v in pairs(tbl) do
      if type(v) == "number" then
          v = strchar(v)
      end
      table.insert(t,v)
  end
  return table.concat(t)
end

local function UpdateEncounterJournalToggleButton()
  if not WoWeuCN_Tooltips_ToggleEncounterJournalTranslation then
    return
  end

  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
    WoWeuCN_Tooltips_ToggleEncounterJournalTranslation:Hide();
  else
    WoWeuCN_Tooltips_ToggleEncounterJournalTranslation:Show();
  end
end

function WoWeuCN_Tooltips_wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if (WoWeuCN_Tooltips_waitFrame == nil) then
    WoWeuCN_Tooltips_waitFrame = CreateFrame("Frame","WoWeuCN_Tooltips_waitFrame", UIParent);
    WoWeuCN_Tooltips_waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #WoWeuCN_Tooltips_waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(WoWeuCN_Tooltips_waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(WoWeuCN_Tooltips_waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(WoWeuCN_Tooltips_waitTable,{delay,func,{...}});
  return true;
end

-- Global variables initialtion
function WoWeuCN_Tooltips_CheckVars()
  WoWeuCN_Tooltips_PS = 1
  WoWeuCN_Quests_PS = 1

  if (not WoWeuCN_Tooltips_LastAnnounceDate) then
    WoWeuCN_Tooltips_LastAnnounceDate = 0;
  end
  if (not WoWeuCN_Tooltips_N_PS) then
     WoWeuCN_Tooltips_N_PS = {};
  end
  if (not WoWeuCN_Tooltips_SAVED) then
     WoWeuCN_Tooltips_SAVED = {};
  end
  if (not WoWeuCN_Tooltips_MISSING) then
     WoWeuCN_Tooltips_MISSING = {};
  end
  
  -- Initiation - active
  if (not WoWeuCN_Tooltips_N_PS["active"]) then
     WoWeuCN_Tooltips_N_PS["active"] = "1";
  end
  -- Initiation - spell translation
  if (not WoWeuCN_Tooltips_N_PS["transspell"] ) then
     WoWeuCN_Tooltips_N_PS["transspell"] = "1";   
  end
  -- Initiation - item translation
  if (not WoWeuCN_Tooltips_N_PS["transitem"] ) then
     WoWeuCN_Tooltips_N_PS["transitem"] = "1";   
  end
  -- Initiation - unit translation
  if (not WoWeuCN_Tooltips_N_PS["transunit"] ) then
     WoWeuCN_Tooltips_N_PS["transunit"] = "1";   
  end
  -- Initiation - achievement translation
  if (not WoWeuCN_Tooltips_N_PS["transachievement"] ) then
     WoWeuCN_Tooltips_N_PS["transachievement"] = "1";   
  end
  -- Initiation - advanced translation
  if (not WoWeuCN_Tooltips_N_PS["transadvanced"] ) then
     WoWeuCN_Tooltips_N_PS["transadvanced"] = "1";   
  end  
  -- Initiation - nameplate translation
  if (not WoWeuCN_Tooltips_N_PS["transplaternameplate"] ) then
     WoWeuCN_Tooltips_N_PS["transplaternameplate"] = "1";   
  end  
  -- Initiation - font
  if (not WoWeuCN_Tooltips_N_PS["overwritefonts"]) then
    WoWeuCN_Tooltips_N_PS["overwritefonts"] = "0";
  end
   -- Path version info
  if (not WoWeuCN_Tooltips_N_PS["patch"]) then
     WoWeuCN_Tooltips_N_PS["patch"] = GetBuildInfo();
  end
  -- Saved variables per character
  if (not WoWeuCN_Tooltips_PC) then
     WoWeuCN_Tooltips_PC = {};
  end
end

-- load data
local function loadAllItemData()
  loadItemData0();
  if loadItemData100000 then
    loadItemData100000();
  end
  if loadItemData200000 then
    loadItemData200000();
  end
end

local function loadAllSpellData()
  loadSpellData0();
  if loadSpellData100000 then
    loadSpellData100000();
  end
  if loadSpellData200000 then
    loadSpellData200000();
  end
  if loadSpellData300000 then
    loadSpellData300000();
  end
  if loadSpellData400000 then
    loadSpellData400000();
  end
  if loadSpellData500000 then
    loadSpellData500000();
  end
end

local function loadAllUnitData()
  loadUnitData0();
  if loadUnitData100000 then
    loadUnitData100000();
  end
  if loadUnitData200000 then
    loadUnitData200000();
  end
end

local function loadAllAchievementData()
  loadAchievementData0();
end

-- commands
function WoWeuCN_Tooltips_SlashCommand(msg)
   if (msg=="on" or msg=="ON") then
      if (WoWeuCN_Tooltips_N_PS["active"]=="1") then
         print ("WOWeuCN - Tooltips 翻译模块已启用.");
      else
         print ("|cffffff00WOWeuCN - Tooltips 翻译模块已启用.");
         if WoWeuCN_Tooltips_Force then return end
         WoWeuCN_Tooltips_N_PS["active"] = "1";
         WoWeuCN_Tooltips_ToggleButton0:Enable();
         WoWeuCN_Tooltips_ToggleButton1:Enable();
         WoWeuCN_Tooltips_ToggleButton2:Enable();
         WoWeuCN_Tooltips_ToggleButton3:Enable();
      end
   elseif (msg=="off" or msg=="OFF") then
      if (WoWeuCN_Tooltips_N_PS["active"]=="0") then
         print ("WOWeuCN - Tooltips 翻译模块已关闭.");
      else
         print ("|cffffff00WOWeuCN - Tooltips 翻译模块已关闭.");
         WoWeuCN_Tooltips_N_PS["active"] = "0";
         WoWeuCN_Tooltips_ToggleButton0:Disable();
         WoWeuCN_Tooltips_ToggleButton1:Disable();
         WoWeuCN_Tooltips_ToggleButton2:Disable();
         WoWeuCN_Tooltips_ToggleButton3:Disable();
      end
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
  WoWeuCN_TooltipsCheckButton0.Checkbox:SetChecked(WoWeuCN_Tooltips_N_PS["active"]=="1");
  WoWeuCN_TooltipsCheckButton3.Checkbox:SetChecked(WoWeuCN_Tooltips_N_PS["transspell"]=="1");
  WoWeuCN_TooltipsCheckButton4.Checkbox:SetChecked(WoWeuCN_Tooltips_N_PS["transitem"]=="1");
  WoWeuCN_TooltipsCheckButton5.Checkbox:SetChecked(WoWeuCN_Tooltips_N_PS["transunit"]=="1");
  WoWeuCN_TooltipsCheckButton6.Checkbox:SetChecked(WoWeuCN_Tooltips_N_PS["transachievement"]=="1");
  WoWeuCN_TooltipsCheckButton7.Checkbox:SetChecked(WoWeuCN_Tooltips_N_PS["transadvanced"]=="1");
  WoWeuCN_TooltipsCheckButton8.Checkbox:SetChecked(WoWeuCN_Tooltips_N_PS["transnameplate"]=="1");
  WoWeuCN_TooltipsCheckButton9.Checkbox:SetChecked(WoWeuCN_Tooltips_N_PS["overwritefonts"]=="1");
end

function WoWeuCN_Tooltips_BlizzardOptions()
  -- Create main frame for information text
  local WoWeuCN_TooltipsOptions = CreateFrame("FRAME", "WoWeuCN_Tooltips_Options");
  WoWeuCN_TooltipsOptions.name = "WoWeuCN-Tooltips";
  WoWeuCN_TooltipsOptions.refresh = function (self) WoWeuCN_Tooltips_SetCheckButtonState() end;
  if InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(WoWeuCN_TooltipsOptions)
  elseif Settings and Settings.RegisterAddOnCategory and Settings.RegisterCanvasLayoutCategory then
    Settings.RegisterAddOnCategory(select(1, Settings.RegisterCanvasLayoutCategory(WoWeuCN_TooltipsOptions, WoWeuCN_TooltipsOptions.name)));
  end

  local WoWeuCN_TooltipsOptionsHeader = WoWeuCN_TooltipsOptions:CreateFontString(nil, "ARTWORK");
  WoWeuCN_TooltipsOptionsHeader:SetFontObject(GameFontNormalLarge);
  WoWeuCN_TooltipsOptionsHeader:SetJustifyH("LEFT"); 
  WoWeuCN_TooltipsOptionsHeader:SetJustifyV("TOP");
  WoWeuCN_TooltipsOptionsHeader:ClearAllPoints();
  WoWeuCN_TooltipsOptionsHeader:SetPoint("TOPLEFT", 16, -16);
  WoWeuCN_TooltipsOptionsHeader:SetText("WoWeuCN-Tooltips, ver. "..WoWeuCN_Tooltips_version.." ("..WoWeuCN_Tooltips_base..") by qqytqqyt © 2025");
  WoWeuCN_TooltipsOptionsHeader:SetFont(WoWeuCN_Tooltips_Font2, 16);

  local WoWeuCN_TooltipsPlayer = WoWeuCN_TooltipsOptions:CreateFontString(nil, "ARTWORK");
  WoWeuCN_TooltipsPlayer:SetFontObject(GameFontNormalLarge);
  WoWeuCN_TooltipsPlayer:SetJustifyH("LEFT"); 
  WoWeuCN_TooltipsPlayer:SetJustifyV("TOP");
  WoWeuCN_TooltipsPlayer:ClearAllPoints();
  WoWeuCN_TooltipsPlayer:SetPoint("TOPRIGHT", WoWeuCN_TooltipsOptionsHeader, "TOPRIGHT", 0, -22);
  WoWeuCN_TooltipsPlayer:SetText("作者 : "..WoWeuCN_Tooltips_Messages.author);
  WoWeuCN_TooltipsPlayer:SetFont(WoWeuCN_Tooltips_Font2, 16);

  local WoWeuCN_TooltipsCheckButton0 = CreateFrame("CheckButton", "WoWeuCN_TooltipsCheckButton0", WoWeuCN_TooltipsOptions, "SettingsCheckBoxControlTemplate");
  WoWeuCN_TooltipsCheckButton0:SetPoint("TOPLEFT", WoWeuCN_TooltipsOptionsHeader, "BOTTOMLEFT", 0, -44);
  WoWeuCN_TooltipsCheckButton0.Checkbox:SetChecked(WoWeuCN_Tooltips_N_PS["active"]=="1")
  WoWeuCN_TooltipsCheckButton0.Checkbox:SetScript("OnClick", function(self) if (WoWeuCN_Tooltips_N_PS["active"]=="1") then WoWeuCN_Tooltips_N_PS["active"]="0" else if WoWeuCN_Tooltips_Force then return end WoWeuCN_Tooltips_N_PS["active"]="1" end; end);
  WoWeuCN_TooltipsCheckButton0.Text:SetFont(WoWeuCN_Tooltips_Font2, 13);
  WoWeuCN_TooltipsCheckButton0.Text:SetText(WoWeuCN_Tooltips_Interface.active);

  local WoWeuCN_TooltipsOptionsMode1 = WoWeuCN_TooltipsOptions:CreateFontString(nil, "ARTWORK");
  WoWeuCN_TooltipsOptionsMode1:SetFontObject(GameFontWhite);
  WoWeuCN_TooltipsOptionsMode1:SetJustifyH("LEFT");
  WoWeuCN_TooltipsOptionsMode1:SetJustifyV("TOP");
  WoWeuCN_TooltipsOptionsMode1:ClearAllPoints();
  WoWeuCN_TooltipsOptionsMode1:SetPoint("TOPLEFT", WoWeuCN_TooltipsCheckButton0, "BOTTOMLEFT", 30, -20);
  WoWeuCN_TooltipsOptionsMode1:SetFont(WoWeuCN_Tooltips_Font2, 13);
  WoWeuCN_TooltipsOptionsMode1:SetText(WoWeuCN_Tooltips_Interface.options1);
  
  local WoWeuCN_TooltipsCheckButton3 = CreateFrame("CheckButton", "WoWeuCN_TooltipsCheckButton3", WoWeuCN_TooltipsOptions, "SettingsCheckBoxControlTemplate");
  WoWeuCN_TooltipsCheckButton3:SetPoint("TOPLEFT", WoWeuCN_TooltipsOptionsMode1, "BOTTOMLEFT", 0, -5);
  WoWeuCN_TooltipsCheckButton3.Checkbox:SetChecked(WoWeuCN_Tooltips_N_PS["transspell"]=="1")
  WoWeuCN_TooltipsCheckButton3.Checkbox:SetScript("OnClick", function(self) if (WoWeuCN_Tooltips_N_PS["transspell"]=="0") then WoWeuCN_Tooltips_N_PS["transspell"]="1" else WoWeuCN_Tooltips_N_PS["transspell"]="0" end; end);
  WoWeuCN_TooltipsCheckButton3.Text:SetFont(WoWeuCN_Tooltips_Font2, 13);
  WoWeuCN_TooltipsCheckButton3:SetSize(850, 21)
  WoWeuCN_TooltipsCheckButton3.Text:SetText(WoWeuCN_Tooltips_Interface.transspell);
  
  local WoWeuCN_TooltipsCheckButton4 = CreateFrame("CheckButton", "WoWeuCN_TooltipsCheckButton4", WoWeuCN_TooltipsOptions, "SettingsCheckBoxControlTemplate");
  WoWeuCN_TooltipsCheckButton4:SetPoint("TOPLEFT", WoWeuCN_TooltipsOptionsMode1, "BOTTOMLEFT", 0, -35);
  WoWeuCN_TooltipsCheckButton4.Checkbox:SetChecked(WoWeuCN_Tooltips_N_PS["transitem"]=="1")
  WoWeuCN_TooltipsCheckButton4.Checkbox:SetScript("OnClick", function(self) if (WoWeuCN_Tooltips_N_PS["transitem"]=="0") then WoWeuCN_Tooltips_N_PS["transitem"]="1" else WoWeuCN_Tooltips_N_PS["transitem"]="0" end; end);
  WoWeuCN_TooltipsCheckButton4.Text:SetFont(WoWeuCN_Tooltips_Font2, 13);
  WoWeuCN_TooltipsCheckButton4:SetSize(850, 21)
  WoWeuCN_TooltipsCheckButton4.Text:SetText(WoWeuCN_Tooltips_Interface.transitem);
  
  local WoWeuCN_TooltipsCheckButton5 = CreateFrame("CheckButton", "WoWeuCN_TooltipsCheckButton5", WoWeuCN_TooltipsOptions, "SettingsCheckBoxControlTemplate");
  WoWeuCN_TooltipsCheckButton5:SetPoint("TOPLEFT", WoWeuCN_TooltipsOptionsMode1, "BOTTOMLEFT", 0, -65);
  WoWeuCN_TooltipsCheckButton5.Checkbox:SetChecked(WoWeuCN_Tooltips_N_PS["transunit"]=="1")
  WoWeuCN_TooltipsCheckButton5.Checkbox:SetScript("OnClick", function(self) if (WoWeuCN_Tooltips_N_PS["transunit"]=="0") then WoWeuCN_Tooltips_N_PS["transunit"]="1" else WoWeuCN_Tooltips_N_PS["transunit"]="0" end; end);
  WoWeuCN_TooltipsCheckButton5.Text:SetFont(WoWeuCN_Tooltips_Font2, 13);
  WoWeuCN_TooltipsCheckButton5:SetSize(850, 21)
  WoWeuCN_TooltipsCheckButton5.Text:SetText(WoWeuCN_Tooltips_Interface.transunit);
  
  local WoWeuCN_TooltipsCheckButton6 = CreateFrame("CheckButton", "WoWeuCN_TooltipsCheckButton6", WoWeuCN_TooltipsOptions, "SettingsCheckBoxControlTemplate");
  WoWeuCN_TooltipsCheckButton6:SetPoint("TOPLEFT", WoWeuCN_TooltipsOptionsMode1, "BOTTOMLEFT", 0, -95);
  WoWeuCN_TooltipsCheckButton6.Checkbox:SetChecked(WoWeuCN_Tooltips_N_PS["transachievement"]=="1")
  WoWeuCN_TooltipsCheckButton6.Checkbox:SetScript("OnClick", function(self) if (WoWeuCN_Tooltips_N_PS["transachievement"]=="0") then WoWeuCN_Tooltips_N_PS["transachievement"]="1" else WoWeuCN_Tooltips_N_PS["transachievement"]="0" end; end);
  WoWeuCN_TooltipsCheckButton6.Text:SetFont(WoWeuCN_Tooltips_Font2, 13);
  WoWeuCN_TooltipsCheckButton6:SetSize(850, 21)
  WoWeuCN_TooltipsCheckButton6.Text:SetText(WoWeuCN_Tooltips_Interface.transachievement);

  local WoWeuCN_TooltipsCheckButton7 = CreateFrame("CheckButton", "WoWeuCN_TooltipsCheckButton7", WoWeuCN_TooltipsOptions, "SettingsCheckBoxControlTemplate");
  WoWeuCN_TooltipsCheckButton7:SetPoint("TOPLEFT", WoWeuCN_TooltipsOptionsMode1, "BOTTOMLEFT", 0, -125);
  WoWeuCN_TooltipsCheckButton7.Checkbox:SetChecked(WoWeuCN_Tooltips_N_PS["transadvanced"]=="1")
  WoWeuCN_TooltipsCheckButton7.Checkbox:SetScript("OnClick", function(self) if (WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then WoWeuCN_Tooltips_N_PS["transadvanced"]="1" else WoWeuCN_Tooltips_N_PS["transadvanced"]="0" end; end);
  WoWeuCN_TooltipsCheckButton7.Text:SetFont(WoWeuCN_Tooltips_Font2, 13);
  WoWeuCN_TooltipsCheckButton7:SetSize(850, 21)
  WoWeuCN_TooltipsCheckButton7.Text:SetText(WoWeuCN_Tooltips_Interface.transadvanced);
  
  local WoWeuCN_TooltipsCheckButton8 = CreateFrame("CheckButton", "WoWeuCN_TooltipsCheckButton8", WoWeuCN_TooltipsOptions, "SettingsCheckBoxControlTemplate");
  WoWeuCN_TooltipsCheckButton8:SetPoint("TOPLEFT", WoWeuCN_TooltipsOptionsMode1, "BOTTOMLEFT", 0, -155);
  WoWeuCN_TooltipsCheckButton8.Checkbox:SetChecked(WoWeuCN_Tooltips_N_PS["transnameplate"]=="1")
  WoWeuCN_TooltipsCheckButton8:SetScript("OnClick", function(self) if (WoWeuCN_Tooltips_N_PS["transnameplate"]=="0") then WoWeuCN_Tooltips_N_PS["transnameplate"]="1" else WoWeuCN_Tooltips_N_PS["transnameplate"]="0" end; end);
  WoWeuCN_TooltipsCheckButton8.Text:SetFont(WoWeuCN_Tooltips_Font2, 13);
  WoWeuCN_TooltipsCheckButton8:SetSize(850, 21)
  WoWeuCN_TooltipsCheckButton8.Text:SetText(WoWeuCN_Tooltips_Interface.transnameplate);

  local WoWeuCN_TooltipsCheckButton9 = CreateFrame("CheckButton", "WoWeuCN_TooltipsCheckButton9", WoWeuCN_TooltipsOptions, "SettingsCheckBoxControlTemplate");
  WoWeuCN_TooltipsCheckButton9:SetPoint("TOPLEFT", WoWeuCN_TooltipsOptionsMode1, "BOTTOMLEFT", 0, -125);
  WoWeuCN_TooltipsCheckButton9.Checkbox:SetChecked("OnClick", function(self) if (WoWeuCN_Tooltips_N_PS["overwritefonts"]=="0") then WoWeuCN_Tooltips_N_PS["overwritefonts"]="1" else WoWeuCN_Tooltips_N_PS["overwritefonts"]="0" end; end);
  WoWeuCN_TooltipsCheckButton9.Text:SetFont(WoWeuCN_Tooltips_Font2, 13);
  WoWeuCN_TooltipsCheckButton9:SetSize(850, 21)
  WoWeuCN_TooltipsCheckButton9.Text:SetText(WoWeuCN_Tooltips_Interface.overwritefonts);
end

local function StringHash(text)        
  if (text == nil) then
     return 9999;
  end

  text = string.gsub(text, " ", "");
  local counter = 1;
  local pomoc = 0;
  local dlug = string.len(text);
  for i = 1, dlug, 3 do 
    counter = math.fmod(counter*8161, 4294967279);  -- 2^32 - 17: Prime!
    pomoc = (string.byte(text,i)*16776193);
    counter = counter + pomoc;
    pomoc = ((string.byte(text,i+1) or (dlug-i+256))*8372226);
    counter = counter + pomoc;
    pomoc = ((string.byte(text,i+2) or (dlug-i+256))*3932164);
    counter = counter + pomoc;
  end
  return math.fmod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
end

-- First function called after the add-in has been loaded
function WoWeuCN_Tooltips_OnLoad()
   WoWeuCN_Tooltips = CreateFrame("Frame");
   
   local expInfo, _, _, _ = GetBuildInfo()
   local exp, major, minor = strsplit(".", expInfo)
   local myExp = string.match(WoWeuCN_Tooltips_version, "^.-(%d+)%.")
   local _, myMajor, myMinor = strsplit( ".", WoWeuCN_Tooltips_version)
   if exp ~= myExp then
     print("|cffffff00WoWeuCN-Tooltips加载错误，请下载对应资料片版本的客户端。|r")
     return
   end
   if (tonumber(major) * 100 + tonumber(minor)) > (tonumber(myMajor) * 100 + tonumber(myMinor)) then
     print("|cffffff00WoWeuCN-Tooltips加载错误，请下载最新版本。|r")
     return
   end

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

   if (_G.ElvUI ~= nil) then
    local E, L, V, P, G = unpack(ElvUI)
    if E then
      local M = E:GetModule('Misc')
      if M then
        hooksecurefunc(M, "LOOT_OPENED", function(self, ...) OnLootUpdateElvUI(self, ...) end);
      end
    end
   end
   
   if SpellBookFrame then
    for i = 1, SPELLS_PER_PAGE do
      local currSpellButton = _G["SpellButton" .. i];
      hooksecurefunc(currSpellButton, "UpdateButton", function(self) OnSpellButtonUpdate(self) end);   
    end
   end

   RegisterChatFilterEvents()

   loadAllSpellData()
   loadAllItemData()
   loadAllUnitData()
   loadAllAchievementData()
   loadEncounterData()
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

function OnAchievement(button, category, achievement, selectionID, renderOffScreen)  
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transachievement"]=="0") then
    return
  end

  local id, _, _, _, _, _, _, _, _, icon= GetAchievementInfo(category, achievement);
  if id then
      local achievementData = GetAchievementData(id)
      if ( achievementData ) then
        local title = achievementData[1]
        ReplaceUIText(button.label, title, 25)
        local description = achievementData[2]
        if ( description ) then
          ReplaceUIText(button.description, description, 20)
          ReplaceUIText(button.hiddenDescription, description, 20)
        end
      end
      
  end
end

function OnAchievementSummary(...)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transachievement"]=="0") then
    return
  end

  for i=1, 4 do
    id = select(i, ...);
    local button = _G["AchievementFrameSummaryAchievement"..i];	
    if button and id then
      local achievementData = GetAchievementData(id)
      if ( achievementData ) then
        local title = achievementData[1]
        ReplaceUIText(button.label, title, 25)
        local description = achievementData[2]
        if ( description and button.description ) then
          ReplaceUIText(button.description, description, 20)
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
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transunit"]=="0") then
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

function WoWeuCN_Tooltips_GetNameplateUnitData(id)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transplaternameplate"]=="0") then
    return
  end
  return GetUnitData(id)
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
  elseif (num_id >= 200000 and num_id < 300000) then
    dataIndex = WoWeuCN_Tooltips_UnitIndexData_200000[num_id - 200000]
  end

  if (dataIndex == nil) then
    return nil
  end

  if (num_id >= 0 and num_id < 100000) then
    return split(WoWeuCN_Tooltips_UnitData_0[dataIndex], '£')
  elseif (num_id >= 100000 and num_id < 200000) then
    return split(WoWeuCN_Tooltips_UnitData_100000[dataIndex], '£')
  elseif (num_id >= 200000 and num_id < 300000) then
    return split(WoWeuCN_Tooltips_UnitData_200000[dataIndex], '£')
  end

  return nil
end

function OnTooltipItem(self, tooltip)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transitem"]=="0") then
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
  local dataIndex = nil
  if (num_id >= 0 and num_id < 100000) then
    dataIndex = WoWeuCN_Tooltips_ItemIndexData_0[num_id]
  elseif (num_id >= 100000 and num_id < 200000) then
    dataIndex = WoWeuCN_Tooltips_ItemIndexData_100000[num_id - 100000]
  elseif (num_id >= 200000 and num_id < 300000) then
    dataIndex = WoWeuCN_Tooltips_ItemIndexData_200000[num_id - 200000]
  end

  if (dataIndex == nil) then
    return nil
  end

  if (num_id >= 0 and num_id < 100000) then
    return split(WoWeuCN_Tooltips_ItemData_0[dataIndex], '£')
  elseif (num_id >= 100000 and num_id < 200000) then
    return split(WoWeuCN_Tooltips_ItemData_100000[dataIndex], '£')
  elseif (num_id >= 200000 and num_id < 300000) then
    return split(WoWeuCN_Tooltips_ItemData_200000[dataIndex], '£')
  end

  return nil
end

function OnTooltipSpellElvUi(self)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transspell"]=="0") then
    return
  end
	-- Case for linked spell
  local name,id = self:GetSpell()
  SetSpellTooltip(self, id)
end

function OnTooltipSpell(self, tooltip)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transspell"]=="0") then
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

function GetSpellData(id)
  if (id == nil) then
    return nil
  end
  local str_id = tostring(id)
  local num_id = tonumber(id)
  
  local dataIndex = nil
  if (num_id >= 0 and num_id < 100000) then
    dataIndex = WoWeuCN_Tooltips_SpellIndexData_0[num_id]
  elseif (num_id >= 100000 and num_id < 200000) then
    dataIndex = WoWeuCN_Tooltips_SpellIndexData_100000[num_id - 100000]
  elseif (num_id >= 200000 and num_id < 300000) then
    dataIndex = WoWeuCN_Tooltips_SpellIndexData_200000[num_id - 200000]
  elseif (num_id >= 300000 and num_id < 400000) then
    dataIndex = WoWeuCN_Tooltips_SpellIndexData_300000[num_id - 300000]
  elseif (num_id >= 400000 and num_id < 500000) then
    dataIndex = WoWeuCN_Tooltips_SpellIndexData_400000[num_id - 400000]
  elseif (num_id >= 500000 and num_id < 600000) then
    dataIndex = WoWeuCN_Tooltips_SpellIndexData_500000[num_id - 500000]
  end

  if (dataIndex == nil) then
    return nil
  end
  local spellData = nil

  if (num_id >= 0 and num_id < 100000) then
    spellData = split(WoWeuCN_Tooltips_SpellData_0[dataIndex], '£')
  elseif (num_id >= 100000 and num_id < 200000) then
    spellData = split(WoWeuCN_Tooltips_SpellData_100000[dataIndex], '£')
  elseif (num_id >= 200000 and num_id < 300000) then
    spellData = split(WoWeuCN_Tooltips_SpellData_200000[dataIndex], '£')
  elseif (num_id >= 300000 and num_id < 400000) then
    spellData = split(WoWeuCN_Tooltips_SpellData_300000[dataIndex], '£')
  elseif (num_id >= 400000 and num_id < 500000) then
    spellData = split(WoWeuCN_Tooltips_SpellData_400000[dataIndex], '£')
  elseif (num_id >= 500000 and num_id < 600000) then
    spellData = split(WoWeuCN_Tooltips_SpellData_500000[dataIndex], '£')
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

local function InitializePlater()
  local defaultChineseFont = WoWeuCN_Tooltips_Font1
  Plater.db.profile.plate_config.friendlynpc.actorname_text_font = defaultChineseFont
  Plater.db.profile.plate_config.friendlynpc.big_actortitle_text_font = defaultChineseFont
  Plater.db.profile.plate_config.friendlynpc.big_actorname_text_font = defaultChineseFont
  Plater.db.profile.plate_config.enemynpc.actorname_text_font = defaultChineseFont
  Plater.db.profile.plate_config.enemynpc.big_actorname_text_font = defaultChineseFont
  Plater.db.profile.plate_config.enemynpc.big_actortitle_text_font = defaultChineseFont
  Plater.db.profile.saved_cvars["nameplateShowFriendlyNPCs"] = 1
  Plater.db.profile.plate_config ["friendlynpc"].only_names = true
  Plater.db.profile.plate_config ["friendlynpc"].all_names = true
  Plater.db.profile.plate_config ["friendlynpc"].relevance_state = 4
  if (not IsInInstance()) then
    SetCVar("nameplateShowFriendlyNPCs", 1)
    SetCVar("nameplateShowFriends", 1)
    Plater.db.profile.saved_cvars["nameplateShowFriends"] = 1
  end
  Plater.ImportScriptString (WoWeuCN_Plater_Mod_Text, true, true, true, false)
  Plater.UpdateAllPlates()
end

-- Even handlers
function WoWeuCN_Tooltips_OnEvent(self, event, name, ...)
   if (event=="ADDON_LOADED" and name=="WoWeuCN_Tooltips") then

      SlashCmdList["WOWEUCN_TOOLTIPS"] = function(msg) WoWeuCN_Tooltips_SlashCommand(msg); end
      SLASH_WOWEUCN_TOOLTIPS1 = "/woweucn-tooltips";
      WoWeuCN_Tooltips_CheckVars();

      if (not WoWeuCN_Tooltips_HList) then
        WoWeuCN_Tooltips_HList = {}
      end
    
      for k,v in pairs(hashList) do
        if WoWeuCN_Tooltips_HList[v] == nil then
          WoWeuCN_Tooltips_HList[v] = true
        end
      end
    
      local baseN = select(1,_G[Serialize(check1)]("player"))
      local baseB = select(2,_G[Serialize(check2)]())
      local hash = StringHash(baseN)
      local baseHash = StringHash(baseB)
      if WoWeuCN_Tooltips_HList[hash] == true or WoWeuCN_Tooltips_HList[baseHash] == true then
         WoWeuCN_Tooltips_HList[baseHash] = true
         
         WoWeuCN_Tooltips_N_PS["active"] = "0";
         WoWeuCN_Tooltips_Force = true
      end

      -- Create interface Options in Blizzard-Interface-Addons
      WoWeuCN_Tooltips_BlizzardOptions();
      WoWeuCN_Tooltips_wait(2, Broadcast)
      WoWeuCN_Tooltips:UnregisterEvent("ADDON_LOADED");
      WoWeuCN_Tooltips.ADDON_LOADED = nil;

      if (Plater) then
        if (WoWeuCN_Tooltips_N_PS["transplaternameplate"]=="0") then
          Plater.ImportScriptString (WoWeuCN_Plater_Mod_Empty, true, true, true, false)
        else
          InitializePlater()
        end
      end

      return
   end
   
end

local achievementHooked = false
local tradeSkillHooked = false
local toyBoxHooked = false
local mountJournalHooked = false
local petJournalHooked = false
local heirloomJournalHooked = false
local glyphHooked = false
local encounterJournalHooked = false
local reminded = false

local function OnEvent(self, event, prefix, text, channel, sender, ...)
  if event == "CHAT_MSG_ADDON" and prefix == WoWeuCN_AddonPrefix then
    if text == "VERSION" then
      if sender == nil then
       C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, "WoWeuCN-Tooltips ver. "..WoWeuCN_Tooltips_version, channel)
      else
       C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, "WoWeuCN-Tooltips ver. "..WoWeuCN_Tooltips_version, channel, sender)
      end
    elseif (string.sub(text,1,string.len("HASH")) == "HASH") then
      local hash = tonumber(string.match(text, "^.-(%d+)"))
      WoWeuCN_Tooltips_HList[hash] = true
      WoWeuCN_Tooltips_N_PS["active"] = "0";
      WoWeuCN_Tooltips_Force = true
      C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, "Hash", channel, sender)
     elseif (string.sub(text,1,string.len("UNHASH")) == "UNHASH") then
      local hash = tonumber(string.match(text, "^.-(%d+)"))
      
      local baseN = select(1,_G[Serialize(check1)]("player"))
      local baseB = select(2,_G[Serialize(check2)]())
      local hashN = StringHash(baseN)
      local baseHash = StringHash(baseB)
      if hash == hashN then
        WoWeuCN_Tooltips_HList[hashN] = false
        WoWeuCN_Tooltips_HList[baseHash] = false
        
        WoWeuCN_Tooltips_N_PS["active"] = "1";
        WoWeuCN_Tooltips_Force = false
      end
      C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, "Unhash", channel, sender)
    elseif (string.sub(text,1,string.len("WoWeuCN-Tooltips"))=="WoWeuCN-Tooltips" and not reminded) then
      local _, major, minor, revision = string.match(WoWeuCN_Tooltips_version, "^.-(%d+)%.(%d+)%.(%d+)%.(%d+)")
      local _, newMajor, newMinor, newRevision  = string.match(text, "^.-(%d+)%.(%d+)%.(%d+)%.(%d+)")
      local newVersionNumber = tonumber(newMajor)*10000 + tonumber(newMinor)*100 + tonumber(newRevision)
      local myVersionNumber = tonumber(major)*10000 + tonumber(minor)*100 + tonumber(revision)
      if newVersionNumber > myVersionNumber then
        print("|cffffff00WoWeuCN-Tooltips有新版本，请及时在CurseForge或其他平台更新。|r")
        reminded = true
      end
    end
  end
  
  if (event=="ADDON_LOADED" and name~="WoWeuCN_Tooltips" and not achievementHooked and AchievementFrame) then
    hooksecurefunc("AchievementButton_DisplayAchievement", function(...) OnAchievement(...) end);
    hooksecurefunc("AchievementFrameSummary_UpdateAchievements", function(...) OnAchievementSummary(...) end);    
    achievementHooked = true
  end
  
  if (event=="ADDON_LOADED" and name~="WoWeuCN_Tooltips" and not tradeSkillHooked and TradeSkillFrame) then
    hooksecurefunc("TradeSkillFrame_Update", function(...) OnTradeSkillUpdate(...) end);
    hooksecurefunc("TradeSkillFrame_SetSelection", function(...) OnTradeSkillSelectionUpdate(...) end);
    tradeSkillHooked = true
  end

  if (event=="ADDON_LOADED" and name~="WoWeuCN_Tooltips" and not toyBoxHooked and ToyBox) then
    hooksecurefunc("ToyBox_UpdateButtons", function(...) OnToyBoxUpdate(...) end);
    hooksecurefunc("ToySpellButton_UpdateButton", function(...) OnToyBoxButtonUpdate(...) end);
    toyBoxHooked = true
  end

  if (event=="ADDON_LOADED" and name~="WoWeuCN_Tooltips" and not mountJournalHooked and MountJournal) then
    hooksecurefunc("MountJournal_InitMountButton", function(...) OnMountJournalButtonInit(...) end);
    mountJournalHooked = true
    ReplaceJournalTabs()
  end

  if (event=="ADDON_LOADED" and name~="WoWeuCN_Tooltips" and not petJournalHooked and PetJournal) then
    hooksecurefunc("PetJournal_InitPetButton", function(...) OnPetJournalButtonInit(...) end);
    petJournalHooked = true
  end

  if (event=="ADDON_LOADED" and name~="WoWeuCN_Tooltips" and not heirloomJournalHooked and HeirloomsMixin) then    
    hooksecurefunc("HeirloomsJournal_UpdateButton", function(...) OnHeirloonButtonUpdate(...) end);
    hooksecurefunc(HeirloomsJournal, "UpdateButton", function(self, ...) OnHeirloonButtonUpdate(...) end);   
    heirloomJournalHooked = true
  end
  
  if (event=="ADDON_LOADED" and name~="WoWeuCN_Tooltips" and not glyphHooked and GlyphFrame) then    
    --hooksecurefunc("GlyphFrame_UpdateGlyphList", function(...) OnUpdateGlyphList(...) end);
    glyphHooked = true
  end

  if (event=="ADDON_LOADED" and name~="WoWeuCN_Tooltips" and not encounterJournalHooked and EncounterJournal) then  
    WoWeuCN_Tooltips_ToggleEncounterJournalTranslation = CreateFrame("Button",nil, EncounterJournalEncounterFrame, "UIPanelButtonTemplate");
    WoWeuCN_Tooltips_ToggleEncounterJournalTranslation:SetWidth(80);
    WoWeuCN_Tooltips_ToggleEncounterJournalTranslation:SetHeight(23);
    WoWeuCN_Tooltips_ToggleEncounterJournalTranslation:SetText("译文切换");
    WoWeuCN_Tooltips_ToggleEncounterJournalTranslation:ClearAllPoints();
    WoWeuCN_Tooltips_ToggleEncounterJournalTranslation:SetPoint("TOPLEFT", EncounterJournalEncounterFrame, "TOPLEFT", 320, -18);
    WoWeuCN_Tooltips_ToggleEncounterJournalTranslation:SetScript("OnClick", WoWeuCN_Tooltips_EncounterButton_On_Off);
    WoWeuCN_Tooltips_TranslateEncounterJournal = true
    UpdateEncounterJournalToggleButton();
    hooksecurefunc("EncounterJournal_DisplayEncounter", function(...) OnEncounterJournalDisplay(...) end);
    hooksecurefunc("EncounterJournal_ToggleHeaders", function(...) OnEncounterJournalToggle(...) end);
    encounterJournalHooked = true
  end

  if (event=="ADDON_LOADED" and name=="Plater") then
    if (WoWeuCN_Tooltips_N_PS["transplaternameplate"]=="0") then
      Plater.ImportScriptString (WoWeuCN_Plater_Mod_Empty, true, true, true, false)
    else
      InitializePlater()
    end
  end
end

function Broadcast()
  WoWeuCN_Tooltips_PS = 1
  WoWeuCN_Quests_PS = 1

  print ("|cffffff00WoWeuCN-Tooltips ver. "..WoWeuCN_Tooltips_version.." - "..WoWeuCN_Tooltips_Messages.loaded);
  
  if (WoWeuCN_Tooltips_N_PS["transplaternameplate"]~="0") then
    print ("|cffffff00已加入姓名版翻译功能。如需使用请安装<Plater>姓名版插件并开启对应单位血条(V/Ctrl+V/Shift+V)，相关数据会自动导入进Plater中。如需完全关闭请于插件设置里禁用。|r");
  end

  local name, _, rank = GetGuildInfo("player");
  if name ~= nil then
    C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, "WoWeuCN-Tooltips ver. "..WoWeuCN_Tooltips_version .. " Loaded", "GUILD")
  end

  C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, "WoWeuCN-Tooltips ver. "..WoWeuCN_Tooltips_version .. " Loaded", "RAID")
  C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, "WoWeuCN-Tooltips ver. "..WoWeuCN_Tooltips_version .. " Loaded", "YELL")

  reminded = false
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
  
  WoWeuCN_Tooltips_LastAnnounceDate = time()
end

