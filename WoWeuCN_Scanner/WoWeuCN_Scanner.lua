-- Addon: WoWeuCN-Scanner
-- Author: qqytqqyt

-- Local variables
local WoWeuCN_Scanner_version = GetAddOnMetadata("WoWeuCN_Scanner", "Version");
local WoWeuCN_AddonPrefix = "WoWeuCN";   

-- commands
function WoWeuCN_Scanner_SlashCommand(msg)
   if (string.sub(msg,1,string.len("index"))=="index") then
      local index = string.sub(msg,string.len("index")+2)
      WoWeuCN_Scanner_ScanIndex(index)

    --clear
    elseif (msg=="clear" or msg=="CLEAR") then
      WoWeuCN_Scanner_ScanClear()

    -- spell auto scan
    elseif (msg=="spellscanauto" or msg=="SPELLSCANAUTO") then
      WoWeuCN_Scanner_ScanInit()    
      WoWeuCN_Scanner_wait(0.1, WoWeuCN_Scanner_ScanSpellAuto, WoWeuCN_Scanner_SpellToolIndex, 1, 0)
    
    -- unit auto scan
    elseif (msg=="unitscanauto" or msg=="UNITSCANAUTO") then
      WoWeuCN_Scanner_ScanInit()
      WoWeuCN_Scanner_wait(0.1, WoWeuCN_Scanner_ScanUnitAuto, WoWeuCN_Scanner_UnitIndex, 1, 0)

    -- item auto scan
    elseif (msg=="itemscanauto" or msg=="ITEMSCANAUTO") then      
      WoWeuCN_Scanner_ScanInit()
      WoWeuCN_Scanner_wait(0.1, WoWeuCN_Scanner_ScanItemAuto, WoWeuCN_Scanner_ItemIndex, 1, 0)

    -- achivement auto scan
    elseif (msg=="achievescanauto" or msg=="ACHIVESCANAUTO") then      
      WoWeuCN_Scanner_ScanInit()
      WoWeuCN_Scanner_wait(0.1, WoWeuCN_Scanner_ScanAchivementAuto, WoWeuCN_Scanner_ItemIndex, 1, 0)

    -- quest scan  
    elseif (msg=="questscanauto" or msg=="QUESTSCANAUTO") then     
      WoWeuCN_Scanner_ScanInit()
      WoWeuCN_Scanner_wait(0.1, WoWeuCN_Scanner_ScanQuestAuto, WoWeuCN_Scanner_QuestIndex, 1, 0)

      -- quest cache scan
      elseif (msg=="cachescanauto" or msg=="CACHESCANAUTO") then     
        WoWeuCN_Scanner_ScanInit()
      WoWeuCN_Scanner_wait(0.1, WoWeuCN_Scanner_ScanCacheAuto, WoWeuCN_Scanner_QuestIndex, 1, 0)

    elseif (msg=="") then
        InterfaceOptionsFrame_Show();
        InterfaceOptionsFrame_OpenToCategory("WoWeuCN-Scanner");
   end
end
-- First function called after the add-in has been loaded
function WoWeuCN_Scanner_OnLoad()
   WoWeuCN_Scanner = CreateFrame("Frame");
   WoWeuCN_Scanner:SetScript("OnEvent", WoWeuCN_Scanner_OnEvent);
   WoWeuCN_Scanner:RegisterEvent("ADDON_LOADED");
   
   qcInformationTooltipSetup();
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

-- Even handlers
function WoWeuCN_Scanner_OnEvent(self, event, name, ...)
   if (event=="ADDON_LOADED" and name=="WoWeuCN_Scanner") then
      SlashCmdList["WoWeuCN_Scanner"] = function(msg) WoWeuCN_Scanner_SlashCommand(msg); end
      SLASH_WoWeuCN_Scanner1 = "/WoWeuCN-Scanner";
      -- Create interface Options in Blizzard-Interface-Addons
      WoWeuCN_Scanner:UnregisterEvent("ADDON_LOADED");
      WoWeuCN_Scanner.ADDON_LOADED = nil;
      return
   end
end