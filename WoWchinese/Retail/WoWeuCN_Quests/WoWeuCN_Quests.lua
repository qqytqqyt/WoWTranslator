-- Addon: WoWeuCN-Quests
-- Author: qqytqqyt
-- Inspired by: Platine  (e-mail: platine.wow@gmail.com) https://wowpopolsku.pl

-- Zmienne lokalne
local QTR_version = GetAddOnMetadata("WoWeuCN_Quests", "Version");
local QTR_onDebug = false;      
local QTR_name = UnitName("player");
local QTR_class= UnitClass("player");
local QTR_race = UnitRace("player");
local QTR_sex = UnitSex("player");     -- 1:neutral,  2:męski,  3:żeński
local QTR_waitTable = {};
local QTR_waitFrame = nil;
local QTR_MessOrig = {
      details    = "Description", 
      objectives = "Objectives", 
      rewards    = "Rewards", 
      itemchoose1= "You will be able to choose one of these rewards:", 
      itemchoose2= "Choose one of these rewards:", 
      itemreceiv1= "You will also receive:", 
      itemreceiv2= "You receiving the reward:", 
      learnspell = "Learn Spell:", 
      reqmoney   = "Required Money:", 
      reqitems   = "Required items:", 
      experience = "Experience:", 
      currquests = "Current Quests", 
      avaiquests = "Available Quests", };
local QTR_quest_EN = {
      id = 0,
      title = "",
      details = "",
      objectives = "",
      progress = "",
      completion = "",
      itemchoose = "",
      itemreceive = "", };      
local QTR_quest_LG = {
      id = 0,
      title = "",
      details = "",
      objectives = "",
      progress = "",
      completion = "",
      itemchoose = "",
      itemreceive = "", };      

local last_time = GetTime();
local last_text = 0;
local curr_trans = "1";
local curr_goss = "X";
local curr_hash = 0;
local Original_Font1 = "Fonts\\MORPHEUS.ttf";
local Original_Font2 = "Fonts\\FRIZQT__.ttf";
local p_race = {
      ["Blood Elf"] = { W1="血精灵", W2="血精灵" }, 
      ["Dark Iron Dwarf"] = { W1="黑铁矮人", W2="黑铁矮人" },
      ["Draenei"] = { W1="德莱尼", W2="德莱尼" },
      ["Dwarf"] = { W1="矮人", W2="矮人" },
      ["Gnome"] = { W1="侏儒", W2="侏儒" },
      ["Goblin"] = { W1="哥布林", W2="哥布林" },
      ["Highmountain Tauren"] = { W1="高岭牛头人", W2="高岭牛头人" },
      ["Human"] = { W1="人类", W2="人类" },
      ["Kul Tiran"] = { W1="库尔提拉斯人", W2="库尔提拉斯人" },
      ["Lightforged Draenei"] = { W1="光铸德莱尼", W2="光铸德莱尼" },
      ["Mag'har Orc"] = { W1="玛格汉兽人", W2="玛格汉兽人" },
      ["Nightborne"] = { W1="夜之子", W2="夜之子" },
      ["Night Elf"] = { W1="暗夜精灵", W2="暗夜精灵" },
      ["Orc"] = { W1="兽人", W2="兽人" },
      ["Pandaren"] = { W1="熊猫人", W2="熊猫人" },
      ["Tauren"] = { W1="牛头人", W2="牛头人" },
      ["Troll"] = { W1="巨魔", W2="巨魔" },
      ["Undead"] = { W1="亡灵", W2="亡灵" },
      ["Void Elf"] = { W1="虚空精灵", W2="虚空精灵" },
      ["Worgen"] = { W1="狼人", W2="狼人" },
      ["Zandalari Troll"] = { W1="赞达拉巨魔", W2="赞达拉巨魔" }, }
local p_class = {
      ["Death Knight"] = { W1="死亡骑士", W2="死亡骑士" },
      ["Demon Hunter"] = { W1="恶魔猎手", W2="恶魔猎手" },
      ["Druid"] = { W1="德鲁伊", W2="德鲁伊" },
      ["Hunter"] = { W1="猎人", W2="猎人" },
      ["Mage"] = { W1="法师", W2="法师" },
      ["Monk"] = { W1="武僧", W2="武僧" },
      ["Paladin"] = { W1="圣骑士", W2="圣骑士" },
      ["Priest"] = { W1="牧师", W2="牧师" },
      ["Rogue"] = { W1="盗贼", W2="盗贼"},
      ["Shaman"] = { W1="萨满", W2="萨满" },
      ["Warlock"] = { W1="术士", W2="术士" },
      ["Warrior"] = { W1="战士", W2="战士" }, }
if (p_race[QTR_race]) then      
   player_race = { W1=p_race[QTR_race].W1, W2=p_race[QTR_race].W2 };
else   
   player_race = { W1=QTR_race, W2=QTR_race };
   print ("|cff55ff00QTR - 新种族: "..QTR_race);
end
if (p_class[QTR_class]) then
   player_class = { W1=p_class[QTR_class].W1, W2=p_class[QTR_class].W2 };
else
   player_class = { W1=QTR_class, W2=QTR_class };
   print ("|cff55ff00QTR - 新职业: "..QTR_class);
end


local function StringHash(text)           -- funkcja tworząca Hash (32-bitowa liczba) podanego tekstu
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


-- Zmienne programowe zapisane na stałe na komputerze
function QTR_CheckVars()
  if (not QTR_PS) then
     QTR_PS = {};
  end
  if (not QTR_SAVED) then
     QTR_SAVED = {};
  end
  if (not QTR_MISSING) then
     QTR_MISSING = {};
  end
  -- inicjalizacja: tłumaczenia włączone
  if (not QTR_PS["active"]) then
     QTR_PS["active"] = "1";
  end
  -- inicjalizacja: tłumaczenie tytułu questu włączone
  if (not QTR_PS["transtitle"] ) then
     QTR_PS["transtitle"] = "0";   
  end
  -- zmienna specjalna dostępności funkcji GetQuestID 
  if ( QTR_PS["isGetQuestID"] ) then
     isGetQuestID=QTR_PS["isGetQuestID"];
  end;
  -- okresowe wyświetlanie reklam o dodatku 
  if (not QTR_PS["reklama"] ) then
     QTR_PS["text1"] = "0";
     QTR_PS["text2"] = "1";
     QTR_PS["channel"] = "0";
  end;
  if (not QTR_PS["other1"] ) then
     QTR_PS["other1"] = "1";
  end;
  if (not QTR_PS["other2"] ) then
     QTR_PS["other2"] = "1";
  end;
  if (not QTR_PS["other3"] ) then
     QTR_PS["other3"] = "1";
  end;
  if (not QTR_PS["channel"] ) then
     QTR_PS["channel"] = "0";
  end;
   -- zapis wersji patcha Wow'a
  if (not QTR_PS["patch"]) then
     QTR_PS["patch"] = GetBuildInfo();
  end
  -- jeszcze nazwa gracza w przepadkach / per character
  if (not QTR_PC) then
     QTR_PC = {};
  end
  if (not QTR_PC["name1"] ) then
     QTR_PC["name1"] = QTR_name;
  end;
  if (not QTR_PC["name2"] ) then
     QTR_PC["name2"] = QTR_name;
  end;
  if (not QTR_PC["name3"] ) then
     QTR_PC["name3"] = QTR_name;
  end;
  if (not QTR_PC["name4"] ) then
     QTR_PC["name4"] = QTR_name;
  end;
  if (not QTR_PC["name5"] ) then
     QTR_PC["name5"] = QTR_name;
  end;
  if (not QTR_PC["name6"] ) then
     QTR_PC["name6"] = QTR_name;
  end;
  if (not QTR_PC["name7"] ) then
     QTR_PC["name7"] = QTR_name;
  end;
  QTR_GS = {};       -- tablica na teksty oryginalne
end


-- Sprawdza dostępność funkcji specjalnej Wow'a: GetQuestID()
function DetectEmuServer()
  QTR_PS["isGetQuestID"]="0";
  isGetQuestID="0";
  -- funkcja GetQuestID() występuje tylko na serwerach Blizzarda
  if ( GetQuestID() ) then
     QTR_PS["isGetQuestID"]="1";
     isGetQuestID="1";
  end
end


-- commands
function QTR_SlashCommand(msg)
   if (msg=="on" or msg=="ON") then
      if (QTR_PS["active"]=="1") then
         print ("QTR - tłumaczenie są włączone.");
      else
         print ("|cffffff00QTR - włączam tłumaczenie.");
         QTR_PS["active"] = "1";
         QTR_ToggleButton0:Enable();
         QTR_ToggleButton1:Enable();
         QTR_ToggleButton2:Enable();
         if (isQuestGuru()) then
            QTR_ToggleButton3:Enable();
         end
         if (isImmersion()) then
            QTR_ToggleButton4:Enable();
         end
         QTR_Translate_On(1);
      end
   elseif (msg=="off" or msg=="OFF") then
      if (QTR_PS["active"]=="0") then
         print ("QTR - tłumaczenia są wyłączone.");
      else
         print ("|cffffff00QTR - wyłączam tłumaczenia.");
         QTR_PS["active"] = "0";
         QTR_ToggleButton0:Disable();
         QTR_ToggleButton1:Disable();
         QTR_ToggleButton2:Disable();
         if (isQuestGuru()) then
            QTR_ToggleButton3:Disable();
         end
         if (isImmersion()) then
            QTR_ToggleButton4:Disable();
         end
         QTR_Translate_Off(1);
      end
   elseif (msg=="title on" or msg=="TITLE ON" or msg=="title 1") then
      if (QTR_PS["transtilte"]=="1") then
         print ("QTR - tłumaczenie tytułów jest włączone.");
      else
         print ("|cffffff00QTR - włączam tłumaczenie tytułów.");
         QTR_PS["transtitle"] = "1";
         QuestInfoTitleHeader:SetFont(QTR_Font1, 18);
      end
   elseif (msg=="title off" or msg=="TITLE OFF" or msg=="title 0") then
      if (QTR_PS["transtilte"]=="0") then
         print ("QTR - tłumaczenie tytułów jest wyłączone.");
      else
         print ("|cffffff00QTR - wyłączam tłumaczenie tytułów.");
         QTR_PS["transtitle"] = "0";
         QuestInfoTitleHeader:SetFont(Original_Font1, 18);
      end
   elseif (msg=="title" or msg=="TITLE") then
      if (QTR_PS["transtilte"]=="1") then
         print ("QTR - tłumaczenie tytułów jest włączone.");
      else
         print ("QTR - tłumaczenie tytułów jest wyłączone.");
      end
   elseif (msg=="") then
      InterfaceOptionsFrame_Show();
      InterfaceOptionsFrame_OpenToCategory("WoWeuCN-Quests");
   else
      print ("QTR - menu szybkich komend addonu:");
      print ("      /qtr on  - włącza tłumaczenia");
      print ("      /qtr off - wyłącza tłumaczenia");
      print ("      /qtr title on  - włącza tłumaczenie tytułu");
      print ("      /qtr title off - wyłącza tłumaczenie tytułu");
   end
end



function QTR_SetCheckButtonState()
  QTRCheckButton0:SetChecked(QTR_PS["active"]=="1");
  QTRCheckButton3:SetChecked(QTR_PS["transtitle"]=="1");
  QTRCheckOther1:SetChecked(QTR_PS["other1"]=="1");
  QTRCheckOther2:SetChecked(QTR_PS["other2"]=="1");
  QTRCheckOther3:SetChecked(QTR_PS["other3"]=="1");
  QTREditP1:SetText(QTR_PC["name1"]);
  QTREditP2:SetText(QTR_PC["name2"]);
  QTREditP3:SetText(QTR_PC["name3"]);
  QTREditP4:SetText(QTR_PC["name4"]);
  QTREditP5:SetText(QTR_PC["name5"]);
  QTREditP6:SetText(QTR_PC["name6"]);
  QTREditP7:SetText(QTR_PC["name7"]);
end



function QTR_BlizzardOptions()
  -- Create main frame for information text
  local QTROptions = CreateFrame("FRAME", "WoWeuCN_Quests_Options");
  QTROptions.name = "WoWeuCN-Quests";
  QTROptions.refresh = function (self) QTR_SetCheckButtonState() end;
  InterfaceOptions_AddCategory(QTROptions);

  local QTROptionsHeader = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsHeader:SetFontObject(GameFontNormalLarge);
  QTROptionsHeader:SetJustifyH("LEFT"); 
  QTROptionsHeader:SetJustifyV("TOP");
  QTROptionsHeader:ClearAllPoints();
  QTROptionsHeader:SetPoint("TOPLEFT", 16, -16);
  QTROptionsHeader:SetText("WoWeuCN-Quests, ver. "..QTR_version.." ("..QTR_base..") by Platine © 2010-2019");

  local QTRDateOfBase = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRDateOfBase:SetFontObject(GameFontNormalLarge);
  QTRDateOfBase:SetJustifyH("LEFT"); 
  QTRDateOfBase:SetJustifyV("TOP");
  QTRDateOfBase:ClearAllPoints();
  QTRDateOfBase:SetPoint("TOPRIGHT", QTROptionsHeader, "TOPRIGHT", 0, -22);
  QTRDateOfBase:SetText("Data bazy tłumaczeń: "..QTR_date);
  QTRDateOfBase:SetFont(QTR_Font2, 16);

  local QTRCheckButton0 = CreateFrame("CheckButton", "QTRCheckButton0", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton0:SetPoint("TOPLEFT", QTROptionsHeader, "BOTTOMLEFT", 0, -20);
  QTRCheckButton0:SetScript("OnClick", function(self) if (QTR_PS["active"]=="1") then QTR_PS["active"]="0" else QTR_PS["active"]="1" end; end);
  QTRCheckButton0Text:SetFont(QTR_Font2, 13);
  QTRCheckButton0Text:SetText(QTR_Interface.active);

  local QTROptionsMode1 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsMode1:SetFontObject(GameFontWhite);
  QTROptionsMode1:SetJustifyH("LEFT");
  QTROptionsMode1:SetJustifyV("TOP");
  QTROptionsMode1:ClearAllPoints();
  QTROptionsMode1:SetPoint("TOPLEFT", QTRCheckButton0, "BOTTOMLEFT", 30, -20);
  QTROptionsMode1:SetFont(QTR_Font2, 13);
  QTROptionsMode1:SetText(QTR_Interface.options1);
  
  local QTRCheckButton3 = CreateFrame("CheckButton", "QTRCheckButton3", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton3:SetPoint("TOPLEFT", QTROptionsMode1, "BOTTOMLEFT", 0, -5);
  QTRCheckButton3:SetScript("OnClick", function(self) if (QTR_PS["transtitle"]=="0") then QTR_PS["transtitle"]="1" else QTR_PS["transtitle"]="0" end; end);
  QTRCheckButton3Text:SetFont(QTR_Font2, 13);
  QTRCheckButton3Text:SetText(QTR_Interface.transtitle);
  
  local QTRIntegration0 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRIntegration0:SetFontObject(GameFontWhite);
  QTRIntegration0:SetJustifyH("LEFT");
  QTRIntegration0:SetJustifyV("TOP");
  QTRIntegration0:ClearAllPoints();
  QTRIntegration0:SetPoint("TOPLEFT", QTRCheckButton3, "BOTTOMLEFT", 0, -20);
  QTRIntegration0:SetFont(QTR_Font2, 13);
  QTRIntegration0:SetText("与其他插件集成:");
  
  local QTRIntegration1 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRIntegration1:SetFontObject(GameFontNormal);
  QTRIntegration1:SetJustifyH("LEFT");
  QTRIntegration1:SetJustifyV("TOP");
  QTRIntegration1:ClearAllPoints();
  QTRIntegration1:SetPoint("TOPLEFT", QTRIntegration0, "TOPRIGHT", 15, 0);
  QTRIntegration1:SetFont(QTR_Font2, 13);
  QTRIntegration1:SetText("QuestGuru,  Immersion,  Storyline");


--  if (ImmersionFrame ~= nil ) then
--     local QTRslider = CreateFrame("Slider", "QTRslider", QTROptions, "OptionsSliderTemplate");
--     QTRslider:SetPoint("TOPLEFT", QTRIntegration0, "BOTTOMLEFT", 0, -40);
--     QTRslider:SetMinMaxValues(0.5, 3.0);
--     QTRslider.minValue, QTRslider.maxValue = QTRslider:GetMinMaxValues();
--     QTRslider.Low:SetText(QTRslider.minValue.." sek");
--     QTRslider.High:SetText(QTRslider.maxValue.." sek");
--     getglobal(QTRslider:GetName() .. 'Text'):SetText('Opóźnienie Immersion');
--     getglobal(QTRslider:GetName() .. 'Text'):SetFont(QTR_Font2, 13);
--     QTRslider:SetValue(QTR_PS["delayImmersion"]);
--     QTRslider:SetValueStep(0.1);
--     QTRslider:SetScript("OnValueChanged", function(self,event,arg1) 
--                                           QTR_PS["delayImmersion"]=string.format("%.1f",event); 
--                                           QTRsliderVal:SetText(QTR_PS["delayImmersion"]);
--                                           end);
--     QTRsliderVal = QTROptions:CreateFontString(nil, "ARTWORK");
--     QTRsliderVal:SetFontObject(GameFontNormal);
--     QTRsliderVal:SetJustifyH("CENTER");
--     QTRsliderVal:SetJustifyV("TOP");
--     QTRsliderVal:ClearAllPoints();
--     QTRsliderVal:SetPoint("CENTER", QTRslider, "CENTER", 0, -12);
--     QTRsliderVal:SetFont(QTR_Font2, 13);
--     QTRsliderVal:SetText(QTR_PS["delayImmersion"]);   
--     end
  
end


function QTR_SaveQuest(event)
   if (event=="QUEST_DETAIL") then
      QTR_SAVED[QTR_quest_EN.id.." TITLE"]=GetTitleText();            -- save original title to future translation
      QTR_SAVED[QTR_quest_EN.id.." DESCRIPTION"]=GetQuestText();      -- save original text to future translation
      QTR_SAVED[QTR_quest_EN.id.." OBJECTIVE"]=GetObjectiveText();    -- save original text to future translation
   end
   if (event=="QUEST_PROGRESS") then
      QTR_SAVED[QTR_quest_EN.id.." PROGRESS"]=GetProgressText();      -- save original text to future translation
   end
   if (event=="QUEST_COMPLETE") then
      QTR_SAVED[QTR_quest_EN.id.." COMPLETE"]=GetRewardText();        -- save original text to future translation
   end
   if (QTR_SAVED[QTR_quest_EN.id.." TITLE"]==nil) then
      QTR_SAVED[QTR_quest_EN.id.." TITLE"]=GetTitleText();            -- zapisz tytył w przypadku tylko Zakończenia
   end
   QTR_SAVED[QTR_quest_EN.id.." PLAYER"]=QTR_name..'@'..QTR_race..'@'..QTR_class;  -- zapisz dane gracza
end


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

function QTR_ON_OFF()
   if (curr_trans=="1") then
      curr_trans="0";
      QTR_Translate_Off(1);
   else   
      curr_trans="1";
      QTR_Translate_On(1);
   end
end

-- Pierwsza funkcja wywoływana po załadowaniu dodatku
function QTR_OnLoad()
   QTR = CreateFrame("Frame");
   QTR:SetScript("OnEvent", QTR_OnEvent);
   QTR:RegisterEvent("ADDON_LOADED");
   QTR:RegisterEvent("QUEST_ACCEPTED");
   QTR:RegisterEvent("QUEST_DETAIL");
   QTR:RegisterEvent("QUEST_PROGRESS");
   QTR:RegisterEvent("QUEST_COMPLETE");
--   QTR:RegisterEvent("QUEST_FINISHED");
--   QTR:RegisterEvent("QUEST_GREETING");

   -- przycisk z nr ID questu w QuestFrame (NPC)
   QTR_ToggleButton0 = CreateFrame("Button",nil, QuestFrame, "UIPanelButtonTemplate");
   QTR_ToggleButton0:SetWidth(150);
   QTR_ToggleButton0:SetHeight(20);
   QTR_ToggleButton0:SetText("Quest ID=?");
   QTR_ToggleButton0:Show();
   QTR_ToggleButton0:ClearAllPoints();
   QTR_ToggleButton0:SetPoint("TOPLEFT", QuestFrame, "TOPLEFT", 92, -25);
   QTR_ToggleButton0:SetScript("OnClick", QTR_ON_OFF);
   
   -- przycisk z nr ID questu w QuestLogPopupDetailFrame
   QTR_ToggleButton1 = CreateFrame("Button",nil, QuestLogPopupDetailFrame, "UIPanelButtonTemplate");
   QTR_ToggleButton1:SetWidth(150);
   QTR_ToggleButton1:SetHeight(20);
   QTR_ToggleButton1:SetText("Quest ID=?");
   QTR_ToggleButton1:Show();
   QTR_ToggleButton1:ClearAllPoints();
   QTR_ToggleButton1:SetPoint("TOPLEFT", QuestLogPopupDetailFrame, "TOPLEFT", 40, -31);
   QTR_ToggleButton1:SetScript("OnClick", QTR_ON_OFF);

   -- przycisk z nr ID questu w QuestMapDetailsScrollFrame
   QTR_ToggleButton2 = CreateFrame("Button",nil, QuestMapDetailsScrollFrame, "UIPanelButtonTemplate");
   QTR_ToggleButton2:SetWidth(150);
   QTR_ToggleButton2:SetHeight(20);
   QTR_ToggleButton2:SetText("Quest ID=?");
   QTR_ToggleButton2:Show();
   QTR_ToggleButton2:ClearAllPoints();
   QTR_ToggleButton2:SetPoint("TOPLEFT", QuestMapDetailsScrollFrame, "TOPLEFT", 116, 29);
   QTR_ToggleButton2:SetScript("OnClick", QTR_ON_OFF);

   -- funkcja wywoływana po kliknięciu na nazwę questu w QuestTracker   
   hooksecurefunc(QUEST_TRACKER_MODULE, "OnBlockHeaderClick", QTR_PrepareReload);
   
   -- funkcja wywoływana po kliknięciu na nazwę questu w QuestMapFrame
   hooksecurefunc("QuestMapFrame_ShowQuestDetails", QTR_PrepareReload);
   
   isQuestGuru();
   isImmersion();
   isStoryline();       -- może być jeszcze nie załadowany, bo nazwa po QTR
end


function isQuestGuru()
   if (QuestGuru ~= nil ) then
      if (QTR_ToggleButton3==nil) then
         -- przycisk z nr ID questu w QuestGuru
         QTR_ToggleButton3 = CreateFrame("Button",nil, QuestGuru, "UIPanelButtonTemplate");
         QTR_ToggleButton3:SetWidth(150);
         QTR_ToggleButton3:SetHeight(20);
         QTR_ToggleButton3:SetText("Quest ID=?");
         QTR_ToggleButton3:Show();
         QTR_ToggleButton3:ClearAllPoints();
         QTR_ToggleButton3:SetPoint("TOPLEFT", QuestGuru, "TOPLEFT", 330, -33);
         QTR_ToggleButton3:SetScript("OnClick", QTR_ON_OFF);
         -- uaktualniono dane w QuestLogu
         QuestGuru:HookScript("OnUpdate", function() QTR_PrepareReload() end);
      end
      return true;
   else
      return false;   
   end
end


function isImmersion()
   if (ImmersionFrame ~= nil ) then
      if (QTR_ToggleButton4==nil) then
         -- przycisk z nr ID questu
         QTR_ToggleButton4 = CreateFrame("Button",nil, ImmersionFrame.TalkBox, "UIPanelButtonTemplate");
         QTR_ToggleButton4:SetWidth(150);
         QTR_ToggleButton4:SetHeight(20);
         QTR_ToggleButton4:SetText("Quest ID=?");
         QTR_ToggleButton4:Show();
         QTR_ToggleButton4:ClearAllPoints();
         QTR_ToggleButton4:SetPoint("TOPLEFT", ImmersionFrame.TalkBox, "TOPRIGHT", -200, -116);
         QTR_ToggleButton4:SetScript("OnClick", QTR_ON_OFF);
         -- otworzono okno dodatku Immersion : wywołanie przez OnEvent
         ImmersionFrame.TalkBox:HookScript("OnHide",function() QTR_ToggleButton4:Hide(); end);
         QTR_ToggleButton4:Disable();     -- nie można na razie przyciskać
         QTR_ToggleButton4:Hide();        -- wstępnie przycisk niewidoczny (bo może jest wybór questów)
      end
      return true;
   else   
      return false;
   end
end
   

function isStoryline()
   if (Storyline_NPCFrame ~= nil ) then
      if (QTR_ToggleButton5==nil) then
         -- przycisk z nr ID questu
         QTR_ToggleButton5 = CreateFrame("Button",nil, Storyline_NPCFrameChat, "UIPanelButtonTemplate");
         QTR_ToggleButton5:SetWidth(150);
         QTR_ToggleButton5:SetHeight(20);
         QTR_ToggleButton5:SetText("Quest ID=?");
         QTR_ToggleButton5:Hide();
         QTR_ToggleButton5:ClearAllPoints();
         QTR_ToggleButton5:SetPoint("BOTTOMLEFT", Storyline_NPCFrameChat, "BOTTOMLEFT", 244, -16);
         QTR_ToggleButton5:SetScript("OnClick", QTR_ON_OFF);
         Storyline_NPCFrameObjectivesContent:HookScript("OnShow", function() QTR_Storyline_Objectives() end);
         Storyline_NPCFrameRewards:HookScript("OnShow", function() QTR_Storyline_Rewards() end);
         Storyline_NPCFrameChat:HookScript("OnHide", function() QTR_Storyline_Hide() end);
--         QTR_ToggleButton5:Disable();     -- nie można przyciskać
      end
      return true;
   else
      return false;
   end
end


-- Określa aktualny numer ID questu z różnych metod
function QTR_GetQuestID()
   if (QTR_onDebug) then
      print('WANTED ID');   
   end
   
   quest_ID = QuestMapFrame.DetailsFrame.questID;
   
   if (quest_ID==nil) then
      quest_ID = QuestLogPopupDetailFrame.questID;
   end
   
   if (quest_ID==nil) then
      if (isQuestGuru() and QuestGuru:IsVisible()) then
         local questTitle, level, questTag, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(GetQuestLogSelection());
         quest_ID = questID;
      end
   end
   
   if(quest_ID==nil) then
      if (isImmersion() and ImmersionFrame:IsVisible()) then
         local nameOrig=ImmersionFrame.TalkBox.NameFrame.Name:GetText();
         local i = 1;
         while GetQuestLogTitle(i) do    -- przeglądaj wszystkie questy w QuestLogu
            local questTitle, level, questTag, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i);
            if (questTitle==nameOrig) then
               quest_ID = questID;
               break;
            end
            i = i + 1;
         end         
      end
      if (isStoryline() and Storyline_NPCFrameTitle:IsVisible()) then
         local nameOrig=Storyline_NPCFrameTitle:GetText();
         local i = 1;
         while GetQuestLogTitle(i) do    -- przeglądaj wszystkie questy w QuestLogu
            local questTitle, level, questTag, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i);
            if (questTitle==nameOrig) then
               quest_ID = questID;
               break;
            end
            i = i + 1;
         end        
      end
   end   
   
   if (quest_ID==nil) then
      if ( isGetQuestID=="1" ) then
         quest_ID = GetQuestID();
      end
   end         

   if (quest_ID==nil) then
      if (QTR_onDebug) then
         print('ID not found');
      end   
      quest_ID=0;
   else   
      if (QTR_onDebug) then
         print('Found ID='..tostring(quest_ID));
      end   
   end   
   
   
   return (quest_ID);
end



-- Wywoływane przy przechwytywanych zdarzeniach
function QTR_OnEvent(self, event, name, ...)
   isStoryline();       -- utwórz przycisk, gdy Storyline aktywny
   if (QTR_onDebug) then
      print('OnEvent-event: '..event);   
   end   
   if (event=="ADDON_LOADED" and name=="WoWeuCN_Quests") then
      SlashCmdList["WOWEUCN_QUESTS"] = function(msg) QTR_SlashCommand(msg); end
      SLASH_WOWEUCN_QUESTS1 = "/woweucn-quests";
      SLASH_WOWEUCN_QUESTS2 = "/qtr";
      QTR_CheckVars();
      -- twórz interface Options w Blizzard-Interface-Addons
      QTR_BlizzardOptions();
      print ("|cffffff00WoWeuCN-Quests ver. "..QTR_version.." - "..QTR_Messages.loaded);
      QTR:UnregisterEvent("ADDON_LOADED");
      QTR.ADDON_LOADED = nil;
      if (not isGetQuestID) then
         DetectEmuServer();
      end
   elseif (event=="QUEST_DETAIL" or event=="QUEST_PROGRESS" or event=="QUEST_COMPLETE") then
      if ( QuestFrame:IsVisible() or isImmersion()) then
         QTR_QuestPrepare(event);
      elseif (isStoryline()) then
         if (not QTR_wait(1,QTR_Storyline_Quest)) then
         -- opóźnienie 1 sek
         end
      end
   elseif (isImmersion() and event=="QUEST_ACCEPTED") then
      QTR_delayed3();
   end
end

-- Otworzono okienko QuestLogPopupDetailFrame lub QuestMapDetailsScrollFrame lub QuestGuru lub Immersion
function QTR_QuestPrepare(zdarzenie)
   if (isQuestGuru()) then
      if (QTR_PS["other1"]=="0") then       -- jest aktywny QuestGuru, ale nie zezwolono na tłumaczenie
         QTR_ToggleButton3:Hide();
         return;
      else   
         QTR_ToggleButton3:Show();
         if (QuestGuru:IsVisible() and (curr_trans=="0")) then
            QTR_Translate_Off(1);
            local questTitle, level, questTag, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(GetQuestLogSelection());
            if (QTR_quest_EN.id==questID) then
               return;
            end
         end
      end   
   end
   if (isImmersion()) then
      if (QTR_PS["other2"]=="0") then       -- jest aktywny Immersion, ale nie zezwolono na tłumaczenie
         QTR_ToggleButton4:Hide();
         return
      else
         QTR_ToggleButton4:Show();
         if (ImmersionContentFrame:IsVisible() and (curr_trans=="0")) then
            QTR_Translate_Off(1);
            return;
         end
      end      
   end
   q_ID = QTR_GetQuestID();
   str_ID = tostring(q_ID);
   QTR_quest_EN.id = q_ID;
   QTR_quest_LG.id = q_ID;
   if (isStoryline()) then
      QTR_ToggleButton5:Hide();
      if (QTR_PS["other3"]=="1") then
         if (q_ID>0) then
            QTR_ToggleButton5:Show();
         end
      else        -- nie zezwolono na tłumaczenie
         return
     end      
   end
   if ( QTR_PS["active"]=="1" ) then	-- tłumaczenia włączone
      QTR_ToggleButton0:Enable();
      QTR_ToggleButton1:Enable();
      QTR_ToggleButton2:Enable();
      if (isImmersion()) then
         if (q_ID==0) then
            return;
         end   
         QTR_ToggleButton4:Enable();
      end
      curr_trans = "1";
      if ( QTR_QuestData[str_ID] ) then   -- wyświetlaj tylko, gdy istnieje tłumaczenie
         QTR_quest_LG.title = QTR_ExpandUnitInfo(QTR_QuestData[str_ID]["Title"]);
         QTR_quest_EN.title = GetTitleText();
         if (QTR_quest_EN.title=="") then
            QTR_quest_EN.title=GetQuestLogTitle(GetQuestLogSelection());
         end
         QTR_quest_LG.details = QTR_ExpandUnitInfo(QTR_QuestData[str_ID]["Description"]);
         QTR_quest_LG.objectives = QTR_ExpandUnitInfo(QTR_QuestData[str_ID]["Objectives"]);
         if (zdarzenie=="QUEST_DETAIL") then
            QTR_quest_EN.details = GetQuestText();
            QTR_quest_EN.objectives = GetObjectiveText();
            QTR_quest_EN.itemchoose = QTR_MessOrig.itemchoose1;
            QTR_quest_LG.itemchoose = QTR_Messages.itemchoose1;
            QTR_quest_EN.itemreceive = QTR_MessOrig.itemreceiv1;
            QTR_quest_LG.itemreceive = QTR_Messages.itemreceiv1;
            if (strlen(QTR_quest_EN.details)>0 and strlen(QTR_quest_LG.details)==0) then
               QTR_MISSING[QTR_quest_EN.id.." DESCRIPTION"]=QTR_quest_EN.details;     -- save missing translation part
            end
            if (strlen(QTR_quest_EN.objectives)>0 and strlen(QTR_quest_LG.objectives)==0) then
               QTR_MISSING[QTR_quest_EN.id.." OBJECTIVE"]=QTR_quest_EN.objectives;    -- save missing translation part
            end
         else   
            if (QTR_quest_LG.details ~= QuestInfoDescriptionText:GetText()) then
               QTR_quest_EN.details = QuestInfoDescriptionText:GetText();
            end
            if (QTR_quest_LG.objectives ~= QuestInfoObjectivesText:GetText()) then
               QTR_quest_EN.objectives = QuestInfoObjectivesText:GetText();
            end
         end   
         if (zdarzenie=="QUEST_PROGRESS") then
            QTR_quest_EN.progress = GetProgressText();
            QTR_quest_LG.progress = QTR_ExpandUnitInfo(QTR_QuestData[str_ID]["Progress"]);
            if (strlen(QTR_quest_EN.progress)>0 and strlen(QTR_quest_LG.progress)==0) then
               QTR_MISSING[QTR_quest_EN.id.." PROGRESS"]=QTR_quest_EN.progress;     -- save missing translation part
            end
            if (strlen(QTR_quest_LG.progress)==0) then      -- treść jest pusta, a otworzono okienko Progress
               QTR_quest_LG.progress = QTR_ExpandUnitInfo('YOUR_NAME');
            end
         end
         if (zdarzenie=="QUEST_COMPLETE") then
            QTR_quest_EN.completion = GetRewardText();
            QTR_quest_LG.completion = QTR_ExpandUnitInfo(QTR_QuestData[str_ID]["Completion"]);
            QTR_quest_EN.itemchoose = QTR_MessOrig.itemchoose2;
            QTR_quest_LG.itemchoose = QTR_Messages.itemchoose2;
            QTR_quest_EN.itemreceive = QTR_MessOrig.itemreceiv2;
            QTR_quest_LG.itemreceive = QTR_Messages.itemreceiv2;
            if (strlen(QTR_quest_EN.completion)>0 and strlen(QTR_quest_LG.completion)==0) then
               QTR_MISSING[QTR_quest_EN.id.." COMPLETE"]=QTR_quest_EN.completion;     -- save missing translation part
            end
         end         
         QTR_ToggleButton0:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
         QTR_ToggleButton1:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
         QTR_ToggleButton2:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
         if (isQuestGuru()) then
            QTR_ToggleButton3:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
            QTR_ToggleButton3:Enable();
         end
         if (isImmersion()) then
            QTR_ToggleButton4:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
            QTR_quest_EN.details = GetQuestText();
            QTR_quest_EN.progress = GetProgressText();
            QTR_quest_EN.completion = GetRewardText();
         end
         if (isStoryline() and Storyline_NPCFrame:IsVisible()) then
            QTR_ToggleButton5:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
         end
         QTR_Translate_On(1);
      else	      -- nie ma przetłumaczonego takiego questu
         QTR_ToggleButton0:Disable();
         QTR_ToggleButton1:Disable();
         QTR_ToggleButton2:Disable();
         if (isQuestGuru()) then
            QTR_ToggleButton3:Disable();
         end
         if (isImmersion()) then
            QTR_ToggleButton4:Disable();
         end
         if (isStoryline()) then
            QTR_ToggleButton5:Disable();
         end
         QTR_ToggleButton0:SetText("Quest ID="..str_ID);
         QTR_ToggleButton1:SetText("Quest ID="..str_ID);
         QTR_ToggleButton2:SetText("Quest ID="..str_ID);
         if (isQuestGuru()) then
            QTR_ToggleButton3:SetText("Quest ID="..str_ID);
         end
         if (isImmersion()) then
            if (q_ID==0) then
               if (ImmersionFrame.TitleButtons:IsVisible()) then
                  QTR_ToggleButton4:SetText("请先选择人物");
               end
            else
               QTR_ToggleButton4:SetText("Quest ID="..str_ID);
            end
         end
         if (isStoryline()) then
            QTR_ToggleButton5:SetText("Quest ID="..str_ID);
         end
         QTR_Translate_On(0);
         QTR_SaveQuest(zdarzenie);
      end -- jest przetłumaczony quest w bazie
   else	-- tłumaczenia wyłączone
      QTR_ToggleButton0:Disable();
      QTR_ToggleButton1:Disable();
      QTR_ToggleButton2:Disable();
--         if (isQuestGuru()) then
--            QTR_ToggleButton3:Disable();
--         end
--         if (isImmersion()) then
--            QTR_ToggleButton4:Disable();
--         end
      if ( QTR_QuestData[str_ID] ) then	-- ale jest tłumaczenie w bazie
         QTR_ToggleButton1:SetText("Quest ID="..str_ID.." (EN)");
         QTR_ToggleButton2:SetText("Quest ID="..str_ID.." (EN)");
         if (isQuestGuru()) then
            QTR_ToggleButton3:SetText("Quest ID="..str_ID.." (EN)");
         end
         if (isImmersion()) then
            QTR_ToggleButton4:SetText("Quest ID="..str_ID.." (EN)");
         end
         if (isStoryline()) then
            QTR_ToggleButton5:SetText("Quest ID="..str_ID.." (EN)");
         end
      else
         QTR_ToggleButton1:SetText("Quest ID="..str_ID);
         QTR_ToggleButton2:SetText("Quest ID="..str_ID);
         if (isQuestGuru()) then
            QTR_ToggleButton3:SetText("Quest ID="..str_ID);
         end
         if (isImmersion()) then
            QTR_ToggleButton4:SetText("Quest ID="..str_ID);
         end
         if (isStoryline()) then
            QTR_ToggleButton5:SetText("Quest ID="..str_ID);
         end
      end
   end	-- tłumaczenia są włączone
end


-- wyświetla tłumaczenie
function QTR_Translate_On(typ)
   if (QTR_PS["transtitle"]=="1") then    -- wyświetl przetłumaczony tytuł
      QuestInfoTitleHeader:SetFont(QTR_Font1, 18);
      QuestProgressTitleText:SetFont(QTR_Font1, 18);
   end
   QuestInfoObjectivesHeader:SetFont(QTR_Font1, 18);
   QuestInfoObjectivesHeader:SetText(QTR_Messages.objectives);
   QuestInfoRewardsFrame.Header:SetFont(QTR_Font1, 18);
   QuestInfoRewardsFrame.Header:SetText(QTR_Messages.rewards);
   QuestInfoDescriptionHeader:SetFont(QTR_Font1, 18);
   QuestInfoDescriptionHeader:SetText(QTR_Messages.details);
   QuestProgressRequiredItemsText:SetFont(QTR_Font1, 18);
   QuestProgressRequiredItemsText:SetText(QTR_Messages.reqitems);
   QuestInfoDescriptionText:SetFont(QTR_Font2, 13);
   QuestInfoObjectivesText:SetFont(QTR_Font2, 13);
   QuestProgressText:SetFont(QTR_Font2, 13);
   QuestInfoRewardText:SetFont(QTR_Font2, 13);
   QuestInfoRewardsFrame.ItemChooseText:SetFont(QTR_Font2, 13);
   QuestInfoRewardsFrame.ItemReceiveText:SetFont(QTR_Font2, 13);
   QuestInfoSpellObjectiveLearnLabel:SetFont(QTR_Font2, 13);
   QuestInfoSpellObjectiveLearnLabel:SetText(QTR_Messages.learnspell);
   QuestInfoXPFrame.ReceiveText:SetFont(QTR_Font2, 13);
   QuestInfoXPFrame.ReceiveText:SetText(QTR_Messages.experience);
--   MapQuestInfoRewardsFrame.ItemChooseText:SetFont(QTR_Font2, 11);
--   MapQuestInfoRewardsFrame.ItemReceiveText:SetFont(QTR_Font2, 11);
--   MapQuestInfoRewardsFrame.ItemChooseText:SetText(QTR_Messages.itemchoose1);
--   MapQuestInfoRewardsFrame.ItemReceiveText:SetText(QTR_Messages.itemreceiv1);
   if (typ==1) then			-- pełne przełączenie (jest tłumaczenie)
      QuestInfoRewardsFrame.ItemChooseText:SetText(QTR_Messages.itemchoose1);
      QuestInfoRewardsFrame.ItemReceiveText:SetText(QTR_Messages.itemreceiv1);
      numer_ID = QTR_quest_LG.id;
      str_ID = tostring(numer_ID);
      if (numer_ID>0 and QTR_QuestData[str_ID]) then	-- przywróć przetłumaczoną wersję napisów
         if (QTR_PS["transtitle"]=="1") then
            QuestInfoTitleHeader:SetText(QTR_quest_LG.title);
            QuestProgressTitleText:SetText(QTR_quest_LG.title);
         end
         QTR_ToggleButton0:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
         QTR_ToggleButton1:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
         QTR_ToggleButton2:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
         if (isQuestGuru()) then
            QTR_ToggleButton3:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
         end
         if (isImmersion()) then
            QTR_ToggleButton4:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
            if (not QTR_wait(0.2,QTR_Immersion)) then    -- wywołaj podmienianie danych po 0.2 sek
               -- opóźnienie 0.2 sek
            end
         end
         if (isStoryline() and Storyline_NPCFrame:IsVisible()) then
            QTR_ToggleButton5:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
            QTR_Storyline(1);
         end
         QuestInfoDescriptionText:SetText(QTR_quest_LG.details);
         QuestInfoObjectivesText:SetText(QTR_quest_LG.objectives);
         QuestProgressText:SetText(QTR_quest_LG.progress);
         QuestInfoRewardText:SetText(QTR_quest_LG.completion);
--         QuestInfoRewardsFrame.ItemChooseText:SetText(QTR_quest_LG.itemchoose);
--         QuestInfoRewardsFrame.ItemReceiveText:SetText(QTR_quest_LG.itemreceive);
      end
   else
      if (curr_trans == "1") then
         QuestInfoRewardsFrame.ItemChooseText:SetText(QTR_Messages.itemchoose1);
         QuestInfoRewardsFrame.ItemReceiveText:SetText(QTR_Messages.itemreceiv1);
         if ((ImmersionFrame ~= nil ) and (ImmersionFrame.TalkBox:IsVisible() )) then
            if (not QTR_wait(0.2,QTR_Immersion_Static)) then
               -- podmiana tekstu z opóźnieniem 0.2 sek
            end
         end
      end
   end
end


-- wyświetla oryginalny tekst
function QTR_Translate_Off(typ)
   QuestInfoTitleHeader:SetFont(Original_Font1, 18);
   QuestProgressTitleText:SetFont(Original_Font1, 18);
   QuestInfoObjectivesHeader:SetFont(Original_Font1, 18);
   QuestInfoObjectivesHeader:SetText(QTR_MessOrig.objectives);
   QuestInfoRewardsFrame.Header:SetFont(Original_Font1, 18);
   QuestInfoRewardsFrame.Header:SetText(QTR_MessOrig.rewards);
   QuestInfoDescriptionHeader:SetFont(Original_Font1, 18);
   QuestInfoDescriptionHeader:SetText(QTR_MessOrig.details);
   QuestProgressRequiredItemsText:SetFont(Original_Font1, 18);
   QuestProgressRequiredItemsText:SetText(QTR_MessOrig.reqitems);
   QuestInfoDescriptionText:SetFont(Original_Font2, 13);
   QuestInfoObjectivesText:SetFont(Original_Font2, 13);
   QuestProgressText:SetFont(Original_Font2, 13);
   QuestInfoRewardText:SetFont(Original_Font2, 13);
   QuestInfoRewardsFrame.ItemChooseText:SetFont(Original_Font2, 13);
   QuestInfoRewardsFrame.ItemReceiveText:SetFont(Original_Font2, 13);
--   MapQuestInfoRewardsFrame.ItemReceiveText:SetFont(Original_Font2, 11);
--   MapQuestInfoRewardsFrame.ItemChooseText:SetFont(Original_Font2, 11);
   QuestInfoSpellObjectiveLearnLabel:SetFont(Original_Font2, 13);
   QuestInfoSpellObjectiveLearnLabel:SetText(QTR_MessOrig.learnspell);
   QuestInfoXPFrame.ReceiveText:SetFont(Original_Font2, 13);
   QuestInfoXPFrame.ReceiveText:SetText(QTR_MessOrig.experience);
   if (typ==1) then			-- pełne przełączenie (jest tłumaczenie)
      QuestInfoRewardsFrame.ItemChooseText:SetText(QTR_MessOrig.itemchoose1);
      QuestInfoRewardsFrame.ItemReceiveText:SetText(QTR_MessOrig.itemreceiv1);
--      MapQuestInfoRewardsFrame.ItemReceiveText:SetText(QTR_MessOrig.itemreceiv1);
--      MapQuestInfoRewardsFrame.ItemChooseText:SetText(QTR_MessOrig.itemreceiv1);
      numer_ID = QTR_quest_EN.id;
      if (numer_ID>0 and QTR_QuestData[str_ID]) then	-- przywróć oryginalną wersję napisów
         QTR_ToggleButton0:SetText("Quest ID="..QTR_quest_EN.id.." (EN)");
         QTR_ToggleButton1:SetText("Quest ID="..QTR_quest_EN.id.." (EN)");
         QTR_ToggleButton2:SetText("Quest ID="..QTR_quest_EN.id.." (EN)");
         if (QuestGuru ~= nil ) then
            QTR_ToggleButton3:SetText("Quest ID="..QTR_quest_EN.id.." (EN)");
         end
         if (ImmersionFrame ~= nil ) then
            QTR_ToggleButton4:SetText("Quest ID="..QTR_quest_EN.id.." (EN)");
            QTR_Immersion_OFF();
            ImmersionFrame.TalkBox.TextFrame.Text:RepeatTexts();   --reload text
         end
         if (isStoryline()) then
            QTR_ToggleButton5:SetText("Quest ID="..QTR_quest_EN.id.." (EN)");
            QTR_Storyline_OFF(1);
         end
         QuestInfoTitleHeader:SetText(QTR_quest_EN.title);
         QuestProgressTitleText:SetText(QTR_quest_EN.title);
         QuestInfoDescriptionText:SetText(QTR_quest_EN.details);
         QuestInfoObjectivesText:SetText(QTR_quest_EN.objectives);
         QuestProgressText:SetText(QTR_quest_EN.progress);
         QuestInfoRewardText:SetText(QTR_quest_EN.completion);
--         QuestInfoRewardsFrame.ItemChooseText:SetText(QTR_quest_EN.itemchoose);
--         QuestInfoRewardsFrame.ItemReceiveText:SetText(QTR_quest_EN.itemreceive);
      end
   else   
      if (curr_trans == "0") then
         if ((ImmersionFrame ~= nil ) and (ImmersionFrame.TalkBox:IsVisible() )) then
            if (not QTR_wait(0.2,QTR_Immersion_OFF_Static)) then
               -- podmiana tekstu z opóźnieniem 0.2 sek
            end
         end
      end
   end
end


function QTR_delayed3()
   QTR_ToggleButton4:SetText("wybierz wpierw quest");
   QTR_ToggleButton4:Hide();
   if (not QTR_wait(1,QTR_delayed4)) then
   ---
   end
end


function QTR_delayed4()
   if (ImmersionFrame.TitleButtons:IsVisible()) then
      if (ImmersionFrame.TitleButtons.Buttons[1] ~= nil ) then
         ImmersionFrame.TitleButtons.Buttons[1]:HookScript("OnClick", function() QTR_PrepareDelay(1) end);
      end
      if (ImmersionFrame.TitleButtons.Buttons[2] ~= nil ) then
         ImmersionFrame.TitleButtons.Buttons[2]:HookScript("OnClick", function() QTR_PrepareDelay(1) end);
      end
      if (ImmersionFrame.TitleButtons.Buttons[3] ~= nil ) then
         ImmersionFrame.TitleButtons.Buttons[3]:HookScript("OnClick", function() QTR_PrepareDelay(1) end);
      end   
      if (ImmersionFrame.TitleButtons.Buttons[4] ~= nil ) then
         ImmersionFrame.TitleButtons.Buttons[4]:HookScript("OnClick", function() QTR_PrepareDelay(1) end);
      end
      if (ImmersionFrame.TitleButtons.Buttons[5] ~= nil ) then
         ImmersionFrame.TitleButtons.Buttons[5]:HookScript("OnClick", function() QTR_PrepareDelay(1) end);
      end
   end
   QTR_QuestPrepare('');
end;      


function QTR_PrepareDelay(czas)     -- wywoływane po kliknięciu na nazwę questu z listy NPC
   if (czas==1) then
      if (not QTR_wait(1,QTR_PrepareReload)) then
      ---
      end
   end
   if (czas==3) then
      if (not QTR_wait(3,QTR_PrepareReload)) then
      ---
      end
   end
end;      


function QTR_PrepareReload()
   QTR_QuestPrepare('');
end;      


function QTR_Immersion()   -- wywoływanie tłumaczenia z opóźnieniem 0.2 sek
  ImmersionContentFrame.ObjectivesText:SetFont(QTR_Font2, 14);
  ImmersionContentFrame.ObjectivesText:SetText(QTR_quest_LG.objectives);
  ImmersionFrame.TalkBox.NameFrame.Name:SetFont(QTR_Font1, 20);
  ImmersionFrame.TalkBox.NameFrame.Name:SetText(QTR_quest_LG.title);
  ImmersionFrame.TalkBox.TextFrame.Text:SetFont(QTR_Font2, 14);
  if (strlen(QTR_quest_EN.details)>0) then                                    -- mamy zdarzenie DETAILS
     ImmersionFrame.TalkBox.TextFrame.Text:SetText(QTR_quest_LG.details);
  elseif (strlen(QTR_quest_EN.completion)>0) then
     ImmersionFrame.TalkBox.TextFrame.Text:SetText(QTR_quest_LG.completion);
  else
     ImmersionFrame.TalkBox.TextFrame.Text:SetText(QTR_quest_LG.progress);
  end
  QTR_Immersion_Static();        -- inne statyczne dane
end


function QTR_Immersion_Static() 
  ImmersionContentFrame.ObjectivesHeader:SetFont(QTR_Font1, 18);
  ImmersionContentFrame.ObjectivesHeader:SetText(QTR_Messages.objectives);  -- "Zadanie"
  ImmersionContentFrame.RewardsFrame.Header:SetFont(QTR_Font1, 18);
  ImmersionContentFrame.RewardsFrame.Header:SetText(QTR_Messages.rewards);  -- "Nagroda"
  ImmersionContentFrame.RewardsFrame.ItemChooseText:SetFont(QTR_Font2, 13);
  ImmersionContentFrame.RewardsFrame.ItemChooseText:SetText(QTR_Messages.itemchoose1); -- "Możesz wybrać nagrodę:"
  ImmersionContentFrame.RewardsFrame.ItemReceiveText:SetFont(QTR_Font2, 13);
  ImmersionContentFrame.RewardsFrame.ItemReceiveText:SetText(QTR_Messages.itemreceiv1); -- "Otrzymasz w nagrodę:"
  ImmersionContentFrame.RewardsFrame.XPFrame.ReceiveText:SetFont(QTR_Font2, 13);
  ImmersionContentFrame.RewardsFrame.XPFrame.ReceiveText:SetText(QTR_Messages.experience);  -- "Doświadczenie"
  ImmersionFrame.TalkBox.Elements.Progress.ReqText:SetFont(QTR_Font1, 18);
  ImmersionFrame.TalkBox.Elements.Progress.ReqText:SetText(QTR_Messages.reqitems);  -- "Wymagane itemy:"
end


function QTR_Immersion_OFF()   -- wywoływanie oryginału
  ImmersionContentFrame.ObjectivesText:SetFont(Original_Font2, 14);
  ImmersionContentFrame.ObjectivesText:SetText(QTR_quest_EN.objectives);
  ImmersionFrame.TalkBox.NameFrame.Name:SetFont(Original_Font1, 20);
  ImmersionFrame.TalkBox.NameFrame.Name:SetText(QTR_quest_EN.title);
  ImmersionFrame.TalkBox.TextFrame.Text:SetFont(Original_Font2, 14);
  if (strlen(QTR_quest_EN.details)>0) then                                    -- przywróć oryginalny tekst
     ImmersionFrame.TalkBox.TextFrame.Text:SetText(QTR_quest_EN.details);
  elseif (strlen(QTR_quest_EN.progress)>0) then
     ImmersionFrame.TalkBox.TextFrame.Text:SetText(QTR_quest_EN.progress);
  else
     ImmersionFrame.TalkBox.TextFrame.Text:SetText(QTR_quest_EN.completion);
  end
  QTR_Immersion_OFF_Static();       -- inne statyczne dane
end


function QTR_Immersion_OFF_Static()
  ImmersionContentFrame.ObjectivesHeader:SetFont(Original_Font1, 18);
  ImmersionContentFrame.ObjectivesHeader:SetText(QTR_MessOrig.objectives);  -- "Zadanie"
  ImmersionContentFrame.RewardsFrame.Header:SetFont(Original_Font1, 18);
  ImmersionContentFrame.RewardsFrame.Header:SetText(QTR_MessOrig.rewards);  -- "Nagroda"
  ImmersionContentFrame.RewardsFrame.ItemChooseText:SetFont(Original_Font2, 13);
  ImmersionContentFrame.RewardsFrame.ItemChooseText:SetText(QTR_MessOrig.itemchoose1); -- "Możesz wybrać nagrodę:"
  ImmersionContentFrame.RewardsFrame.ItemReceiveText:SetFont(Original_Font2, 13);
  ImmersionContentFrame.RewardsFrame.ItemReceiveText:SetText(QTR_MessOrig.itemreceiv1); -- "Otrzymasz w nagrodę:"
  ImmersionContentFrame.RewardsFrame.XPFrame.ReceiveText:SetFont(Original_Font2, 13);
  ImmersionContentFrame.RewardsFrame.XPFrame.ReceiveText:SetText(QTR_MessOrig.experience);  -- "Doświadczenie"
  ImmersionFrame.TalkBox.Elements.Progress.ReqText:SetFont(Original_Font1, 18);
  ImmersionFrame.TalkBox.Elements.Progress.ReqText:SetText(QTR_MessOrig.reqitems);  -- "Wymagane itemy:"
end


function QTR_Storyline_Delay()
   QTR_Storyline(1);
end


function QTR_Storyline_Quest()
   if (QTR_PS["active"]=="1" and QTR_PS["other3"]=="1" and Storyline_NPCFrameTitle:IsVisible()) then
      QTR_QuestPrepare('');
   end
end


function QTR_Storyline_Hide()
   if (QTR_PS["active"]=="1" and QTR_PS["other3"]=="1") then
      QTR_ToggleButton5:Hide();
   end
end


function QTR_Storyline_Objectives()
   if (QTR_onDebug) then
      print("QTR_ST: objectives");
   end
   if (QTR_PS["active"]=="1" and QTR_PS["other3"]=="1" and QTR_quest_LG.id>0) then
      local string_ID= tostring(QTR_quest_LG.id);
      Storyline_NPCFrameObjectivesContent.Title:SetText('Zadanie');
      if (QTR_QuestData[string_ID] ) then
         Storyline_NPCFrameObjectivesContent.Objectives:SetText(QTR_ExpandUnitInfo(QTR_QuestData[string_ID]["Objectives"]));
         Storyline_NPCFrameObjectivesContent.Objectives:SetFont(QTR_Font2, 13);
      end   
   end
end


function QTR_Storyline_Rewards()
   if (QTR_onDebug) then
      print("QTR_ST: rewards");
   end
   if (QTR_PS["active"]=="1" and QTR_PS["other3"]=="1") then
      Storyline_NPCFrameRewards.Content.Title:SetText('Nagroda');
   end
end


function QTR_Storyline(nr)
   if (QTR_onDebug) then
      print('QTR_ST: Podmieniam quest '..QTR_quest_LG.id);
   end
   if (QTR_PS["transtitle"]=="1") then
      Storyline_NPCFrameTitle:SetText(QTR_quest_LG.title);
      Storyline_NPCFrameTitle:SetFont(QTR_Font2, 18);
   end
   local string_ID= tostring(QTR_quest_LG.id);
   local texts = { "" };
   if ((Storyline_NPCFrameChat.event ~= nil) and (QTR_QuestData[string_ID] ~= nil))then
      local event = Storyline_NPCFrameChat.event;
      if (event=="QUEST_DETAIL") then
     	   texts = { strsplit("\n", QTR_ExpandUnitInfo(QTR_QuestData[string_ID]["Description"])) };
      end   
      if (event=="QUEST_PROGRESS") then
     	   texts = { strsplit("\n", QTR_ExpandUnitInfo(QTR_QuestData[string_ID]["Progress"])) };
      end   
      if (event=="QUEST_COMPLETE") then
     	   texts = { strsplit("\n", QTR_ExpandUnitInfo(QTR_QuestData[string_ID]["Completion"])) };
      end   
   end
   local ileOry = #Storyline_NPCFrameChat.texts;
   local indeks = 0;
   for i=1,#texts do
      if texts[i]:len() > 0 then
         if (indeks<ileOry) then
            indeks=indeks+1;
            Storyline_NPCFrameChat.texts[indeks]=texts[i];
         end
      end
   end
   Storyline_NPCFrameChatText:SetFont(QTR_Font2, 16);
   if (nr==1) then      -- Reload text
      Storyline_NPCFrameObjectivesContent:Hide();
      Storyline_NPCFrame.chat.currentIndex = 0;
      Storyline_API.playNext(Storyline_NPCFrameModelsYou);  -- reload
   end
end


function QTR_Storyline_OFF(nr)
   if (QTR_onDebug) then
      print('QTR_SToff: Przywracam quest '..QTR_quest_EN.id);
   end
   if (QTR_PS["transtitle"]=="1") then
      Storyline_NPCFrameTitle:SetText(QTR_quest_EN.title);
      Storyline_NPCFrameTitle:SetFont(Original_Font2, 18);
   end
   local string_ID= tostring(QTR_quest_EN.id);
   local texts = { "" };
   if ((Storyline_NPCFrameChat.event ~= nil) and (QTR_QuestData[string_ID] ~= nil))then
      local event = Storyline_NPCFrameChat.event;
      if (event=="QUEST_DETAIL") then
     	   texts = { strsplit("\n", GetQuestText()) };
      end   
      if (event=="QUEST_PROGRESS") then
     	   texts = { strsplit("\n", GetProgressText()) };
      end   
      if (event=="QUEST_COMPLETE") then
     	   texts = { strsplit("\n", GetRewardText()) };
      end   
   end
   local ileOry = #Storyline_NPCFrameChat.texts;
   local indeks = 0;
   for i=1,#texts do
      if texts[i]:len() > 0 then
         if (indeks<ileOry) then
            indeks=indeks+1;
            Storyline_NPCFrameChat.texts[indeks]=texts[i];
         end
      end
   end
   Storyline_NPCFrameChatText:SetFont(Original_Font2, 16);
   if (nr==1) then      -- Reload text
      Storyline_NPCFrameObjectivesContent:Hide();
      Storyline_NPCFrame.chat.currentIndex = 0;
      Storyline_API.playNext(Storyline_NPCFrameModelsYou);  -- reload
   end
end


-- podmieniaj specjane znaki w tekście
function QTR_ExpandUnitInfo(msg)
   msg = string.gsub(msg, "NEW_LINE", "\n");
   msg = string.gsub(msg, "YOUR_NAME1", QTR_PC["name1"]);
   msg = string.gsub(msg, "YOUR_NAME2", QTR_PC["name2"]);
   msg = string.gsub(msg, "YOUR_NAME3", QTR_PC["name3"]);
   msg = string.gsub(msg, "YOUR_NAME4", QTR_PC["name4"]);
   msg = string.gsub(msg, "YOUR_NAME5", QTR_PC["name5"]);
   msg = string.gsub(msg, "YOUR_NAME6", QTR_PC["name6"]);
   msg = string.gsub(msg, "YOUR_NAME7", QTR_PC["name7"]);
   msg = string.gsub(msg, "YOUR_NAME", QTR_name);
   
-- jeszcze obsłużyć YOUR_GENDER(x;y)
   local nr_1, nr_2, nr_3 = 0;
   local QTR_forma = "";
   local nr_poz = string.find(msg, "YOUR_GENDER");    -- gdy nie znalazł, jest: nil
   while (nr_poz and nr_poz>0) do
      nr_1 = nr_poz + 1;   
      while (string.sub(msg, nr_1, nr_1) ~= "(") do
         nr_1 = nr_1 + 1;
      end
      if (string.sub(msg, nr_1, nr_1) == "(") then
         nr_2 =  nr_1 + 1;
         while (string.sub(msg, nr_2, nr_2) ~= ";") do
            nr_2 = nr_2 + 1;
         end
         if (string.sub(msg, nr_2, nr_2) == ";") then
            nr_3 = nr_2 + 1;
            while (string.sub(msg, nr_3, nr_3) ~= ")") do
               nr_3 = nr_3 + 1;
            end
            if (string.sub(msg, nr_3, nr_3) == ")") then
               if (QTR_sex==3) then        -- forma żeńska
                  QTR_forma = string.sub(msg,nr_2+1,nr_3-1);
               else                        -- forma męska
                  QTR_forma = string.sub(msg,nr_1+1,nr_2-1);
               end
               msg = string.sub(msg,1,nr_poz-1) .. QTR_forma .. string.sub(msg,nr_3+1);
            end   
         end
      end
      nr_poz = string.find(msg, "YOUR_GENDER");
   end

-- jeszcze obsłużyć NPC_GENDER(x;y)
   local nr_1, nr_2, nr_3 = 0;
   local QTR_forma = "";
   local nr_poz = string.find(msg, "NPC_GENDER");    -- gdy nie znalazł, jest: nil
   while (nr_poz and nr_poz>0) do
      nr_1 = nr_poz + 1;   
      while (string.sub(msg, nr_1, nr_1) ~= "(") do
         nr_1 = nr_1 + 1;
      end
      if (string.sub(msg, nr_1, nr_1) == "(") then
         nr_2 =  nr_1 + 1;
         while (string.sub(msg, nr_2, nr_2) ~= ";") do
            nr_2 = nr_2 + 1;
         end
         if (string.sub(msg, nr_2, nr_2) == ";") then
            nr_3 = nr_2 + 1;
            while (string.sub(msg, nr_3, nr_3) ~= ")") do
               nr_3 = nr_3 + 1;
            end
            if (string.sub(msg, nr_3, nr_3) == ")") then
               if (QTR_sex==3) then        -- forma żeńska
                  QTR_forma = string.sub(msg,nr_2+1,nr_3-1);
               else                        -- forma męska
                  QTR_forma = string.sub(msg,nr_1+1,nr_2-1);
               end
               msg = string.sub(msg,1,nr_poz-1) .. QTR_forma .. string.sub(msg,nr_3+1);
            end   
         end
      end
      nr_poz = string.find(msg, "NPC_GENDER");
   end

   if (QTR_sex==3) then        
      msg = string.gsub(msg, "YOUR_RACE", player_race.W2);                        -- Wołacz - pozostałe wystąpienia
      msg = string.gsub(msg, "YOUR_CLASS", player_class.W2);                      -- Wołacz - pozostałe wystąpienia
   else                    
      msg = string.gsub(msg, "YOUR_RACE", player_race.W1);                        -- Wołacz - pozostałe wystąpienia
      msg = string.gsub(msg, "YOUR_CLASS", player_class.W1);                      -- Wołacz - pozostałe wystąpienia
   end
   
   return msg;
end

