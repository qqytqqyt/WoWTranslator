-- Addon: WoWeuCN-Quests
-- Author: qqytqqyt
-- Credit to: Platine https://wowpopolsku.pl

-- Local variables
local WoWeuCN_Quests_version = GetAddOnMetadata("WoWeuCN_Quests", "Version");
local WoWeuCN_Quests_CtrFrame = CreateFrame("FRAME", "WoWEenCN-BubblesFrame");
local WoWeuCN_Quests_onDebug = false;      
local WoWeuCN_Quests_name = UnitName("player");
local WoWeuCN_Quests_class, WoWeuCN_Quests_class_file, WoWeuCN_Quests_class_Id= UnitClass("player");
local WoWeuCN_Quests_race, WoWeuCN_Quests_race_file, WoWeuCN_Quests_race_Id = UnitRace("player");
local WoWeuCN_Quests_sex = UnitSex("player");     -- 1:neutral,  2:male,  3:female
local WoWeuCN_Quests_waitTable = {};
local WoWeuCN_Quests_waitFrame = nil;
local WoWeuCN_Quests_MessOrig = {
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
local WoWeuCN_Quests_quest_EN = {
      id = 0,
      title = "",
      details = "",
      objectives = "",
      progress = "",
      completion = "",
      itemchoose = "",
      itemreceive = "", };      
local WoWeuCN_Quests_quest_LG = {
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
local Original_Font1 = QuestFontHighlight:GetFont();
local Original_Font2, Original_Font2_Size = QuestInfoDescriptionText:GetFont();
local p_race ={
      [10] = { W1="血精灵", W2="血精灵" }, 
      [11] = { W1="德莱尼", W2="德莱尼" },
      [3] = { W1="矮人", W2="矮人" },
      [7] = { W1="侏儒", W2="侏儒" },
      [1] = { W1="人类", W2="人类" },
      [4] = { W1="暗夜精灵", W2="暗夜精灵" },
      [2] = { W1="兽人", W2="兽人" },
      [6] = { W1="牛头人", W2="牛头人" },
      [8] = { W1="巨魔", W2="巨魔" },
      [5] = { W1="亡灵", W2="亡灵" }, }
  
local p_class = {
      [11] = { W1="德鲁伊", W2="德鲁伊" },
      [3] = { W1="猎人", W2="猎人" },
      [8] = { W1="法师", W2="法师" },
      [2] = { W1="圣骑士", W2="圣骑士" },
      [5] = { W1="牧师", W2="牧师" },
      [4] = { W1="盗贼", W2="盗贼"},
      [7] = { W1="萨满", W2="萨满" },
      [9] = { W1="术士", W2="术士" },
      [1] = { W1="战士", W2="战士" }, }

local removed_text = { "Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior", "Blood Elf", "Draenei", "Gnome", "Dwarf", "Night Elf", "Orc", "Undead", "Tauren", "Troll" }

if (p_race[WoWeuCN_Quests_race_Id]) then      
   player_race = { W1=p_race[WoWeuCN_Quests_race_Id].W1, W2=p_race[WoWeuCN_Quests_race_Id].W2 };
else   
   player_race = { W1=WoWeuCN_Quests_race, W2=WoWeuCN_Quests_race };
   print ("|cff55ff00WoWeuCN - 新种族: "..WoWeuCN_Quests_race_Id);
end
if (p_class[WoWeuCN_Quests_class_Id]) then
   player_class = { W1=p_class[WoWeuCN_Quests_class_Id].W1, W2=p_class[WoWeuCN_Quests_class_Id].W2 };
else
   player_class = { W1=WoWeuCN_Quests_class, W2=WoWeuCN_Quests_class };
   print ("|cff55ff00WoWeuCN - 新职业: "..WoWeuCN_Quests_class_Id);
end

-- Global variables initialtion
function WoWeuCN_Quests_CheckVars()
  if (not WoWeuCN_Quests_PS) then
     WoWeuCN_Quests_PS = {};
  end
  if (not WoWeuCN_Quests_LastAnnounceDate) then
     WoWeuCN_Quests_LastAnnounceDate = 0;
  end
  if (not WoWeuCN_Quests_SAVED) then
     WoWeuCN_Quests_SAVED = {};
  end
  if (not WoWeuCN_Quests_MISSING) then
     WoWeuCN_Quests_MISSING = {};
  end
  if (not WoWeuCN_Quests_CONTROL) then
     WoWeuCN_Quests_CONTROL = {};
  end
  -- Initiation - active
  if (not WoWeuCN_Quests_PS["active"]) then
     WoWeuCN_Quests_PS["active"] = "1";
  end
  -- Initiation - title translation
  if (not WoWeuCN_Quests_PS["transtitle"] ) then
     WoWeuCN_Quests_PS["transtitle"] = "1";   
  end
  -- Initiation - chat
  if (not WoWeuCN_Quests_PS["transchat"]) then
     WoWeuCN_Quests_PS["transchat"] = "1";
  end
  -- Initiation - font
  if (not WoWeuCN_Quests_PS["overwritefonts"]) then
     WoWeuCN_Quests_PS["overwritefonts"] = "0";
  end
  -- Special variable of the GetQuestID function availability
  if ( WoWeuCN_Quests_PS["isGetQuestID"] ) then
     isGetQuestID=WoWeuCN_Quests_PS["isGetQuestID"];
  end;
  if (not WoWeuCN_Quests_PS["other1"] ) then
     WoWeuCN_Quests_PS["other1"] = "1";
  end;
  if (not WoWeuCN_Quests_PS["other2"] ) then
     WoWeuCN_Quests_PS["other2"] = "1";
  end;
  if (not WoWeuCN_Quests_PS["other3"] ) then
     WoWeuCN_Quests_PS["other3"] = "1";
  end;
   -- Control record of the original EN quests
  if (not WoWeuCN_Quests_PS["control"]) then
     WoWeuCN_Quests_PS["control"] = "1";
  end
  -- Path version info
  if (not WoWeuCN_Quests_PS["patch"]) then
     WoWeuCN_Quests_PS["patch"] = GetBuildInfo();
  end
  -- Saved variables per character
  if (not WoWeuCN_Quests_PC) then
     WoWeuCN_Quests_PC = {};
  end
end


local WoWeuCN_Quests_waitFrame = nil;
local WoWeuCN_Quests_waitTable = {};

function WoWeuCN_Quests_wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if (WoWeuCN_Quests_waitFrame == nil) then
    WoWeuCN_Quests_waitFrame = CreateFrame("Frame","WoWeuCN_Quests_WaitFrame", UIParent);
    WoWeuCN_Quests_waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #WoWeuCN_Quests_waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(WoWeuCN_Quests_waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(WoWeuCN_Quests_waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(WoWeuCN_Quests_waitTable,{delay,func,{...}});
  return true;
end


local function scanAuto(startIndex, attempt, counter)
  if (startIndex > 70000) then
    return;
  end
  if (counter == 0) then
   print(startIndex)
  end
  
  for i = startIndex, startIndex + 150 do
   local title = C_QuestLog.GetQuestInfo(i)
   if (title ~= '' and title ~= nil) then
    print(title)
   end
  end
  
  WoWeuCN_Quests_QuestIndex = startIndex
  if (counter >= 5) then
    WoWeuCN_Quests_wait(0.2, scanAuto, startIndex + 150, attempt + 1, 0)
  else
    WoWeuCN_Quests_wait(0.2, scanAuto, startIndex, attempt + 1, counter + 1)
  end
end

-- Checks the availability of Wow's special function: GetQuestID()
function DetectEmuServer()
  WoWeuCN_Quests_PS["isGetQuestID"]="0";
  isGetQuestID="0";
  -- The GetQuestID () function only appears on Blizzard servers
  if ( GetQuestID() ) then
     WoWeuCN_Quests_PS["isGetQuestID"]="1";
     isGetQuestID="1";
  end
end


-- Commands
function WoWeuCN_Quests_SlashCommand(msg)
   if (msg=="on" or msg=="ON") then
      if (WoWeuCN_Quests_PS["active"]=="1") then
         print ("WoWeuCN - 翻译模块已启用.");
      else
         print ("|cffffff00WoWeuCN - 翻译模块已启用.");
         WoWeuCN_Quests_PS["active"] = "1";
         WoWeuCN_Quests_ToggleButton0:Enable();
         WoWeuCN_Quests_ToggleButton1:Enable();
         WoWeuCN_Quests_ToggleButton2:Enable();
         if (isQuestGuru()) then
            WoWeuCN_Quests_ToggleButton3:Enable();
         end
         if (isImmersion()) then
            WoWeuCN_Quests_ToggleButton4:Enable();
         end
         WoWeuCN_Quests_Translate_On(1);
      end
   elseif (msg=="off" or msg=="OFF") then
      if (WoWeuCN_Quests_PS["active"]=="0") then
         print ("WoWeuCN - 翻译模块已关闭.");
      else
         print ("|cffffff00WoWeuCN - 翻译模块已关闭.");
         WoWeuCN_Quests_PS["active"] = "0";
         WoWeuCN_Quests_ToggleButton0:Disable();
         WoWeuCN_Quests_ToggleButton1:Disable();
         WoWeuCN_Quests_ToggleButton2:Disable();
         if (isQuestGuru()) then
            WoWeuCN_Quests_ToggleButton3:Disable();
         end
         if (isImmersion()) then
            WoWeuCN_Quests_ToggleButton4:Disable();
         end
         WoWeuCN_Quests_Translate_Off(1);
      end
   -- title setting
   elseif (msg=="title on" or msg=="TITLE ON" or msg=="title 1") then
      if (WoWeuCN_Quests_PS["transtilte"]=="1") then
         print ("WoWeuCN - 翻译标题 : 启用.");
      else
         print ("|cffffff00WoWeuCN - 翻译标题 : 启用.");
         WoWeuCN_Quests_PS["transtitle"] = "1";
         QuestInfoTitleHeader:SetFont(WoWeuCN_Quests_Font1, 18);
      end
   elseif (msg=="title off" or msg=="TITLE OFF" or msg=="title 0") then
      if (WoWeuCN_Quests_PS["transtilte"]=="0") then
         print ("WoWeuCN - 翻译标题 : 禁用.");
      else
         print ("|cffffff00WoWeuCN - 翻译标题 : 禁用.");
         WoWeuCN_Quests_PS["transtitle"] = "0";
         QuestInfoTitleHeader:SetFont(Original_Font1, 18);
      end
   elseif (msg=="title" or msg=="TITLE") then
      if (WoWeuCN_Quests_PS["transtilte"]=="1") then
         print ("WoWeuCN - 翻译标题状态 : 启用.");
      else
         print ("WoWeuCN - 翻译标题状态 : 禁用.");
      end
   -- chat setting
   elseif (msg=="chat on" or msg=="CHAT ON" or msg=="chat 1") then
      if (WoWeuCN_Quests_PS["transchat"]=="1") then
         print ("WoWeuCN - 翻译NPC对话 : 启用.");
      else
         print ("|cffffff00WoWeuCN - 翻译NPC对话 : 启用.");
         WoWeuCN_Quests_PS["transchat"] = "1";
      end
   elseif (msg=="chat off" or msg=="CHAT OFF" or msg=="chat 0") then
      if (WoWeuCN_Quests_PS["transchat"]=="0") then
         print ("WoWeuCN - 翻译NPC对话 : 禁用.");
      else
         print ("|cffffff00WoWeuCN - 翻译标题 : 禁用.");
         WoWeuCN_Quests_PS["transchat"] = "0";
      end
   elseif (msg=="chat" or msg=="CHAT") then
      if (WoWeuCN_Quests_PS["transchat"]=="1") then
         print ("WoWeuCN - 翻译NPC对话状态 : 启用.");
      else
         print ("WoWeuCN - 翻译NPC对话状态 : 禁用.");
      end

   elseif (msg=="reset" or msg=="RESET") then
      WoWeuCN_Quests_QuestIndex = 1;
      print("Reset");
    elseif (msg=="clear" or msg=="CLEAR") then
      WoWeuCN_Quests_QuestIndex = 1;
      WoWeuCN_Quests_QuestToolTips = {} 
      print("Clear");
   elseif (msg=="jump" or msg=="JUMP") then
      WoWeuCN_Quests_QuestIndex = 63000;
      WoWeuCN_Quests_QuestToolTips = {} 
      print("Jump");
   elseif (msg=="scanauto" or msg=="SCANAUTO") then
      if (WoWeuCN_Quests_QuestToolTips == nil) then
        WoWeuCN_Quests_QuestToolTips = {} 
      end
      if (WoWeuCN_Quests_QuestIndex == nil) then
        WoWeuCN_Quests_QuestIndex = 1
      end
      WoWeuCN_Quests_wait(0.1, scanAuto, WoWeuCN_Quests_QuestIndex, 1, 0)
   elseif (msg=="") then
      InterfaceOptionsFrame_Show();
      InterfaceOptionsFrame_OpenToCategory("WoWeuCN-Quests");
   else
      print ("WoWeuCN - 指令说明:");
      print ("      /WoWeuCN on - 启用翻译模块");
      print ("      /WoWeuCN off - 禁用翻译模块");
      print ("      /WoWeuCN title on - 启用标题翻译");
      print ("      /WoWeuCN title off - 禁用标题翻译");
   end
end



function WoWeuCN_Quests_SetCheckButtonState()
  WoWeuCN_QuestsCheckButton0:SetChecked(WoWeuCN_Quests_PS["active"]=="1");
  WoWeuCN_QuestsCheckButton3:SetChecked(WoWeuCN_Quests_PS["transtitle"]=="1");
  WoWeuCN_QuestsCheckButton4:SetChecked(WoWeuCN_Quests_PS["transchat"]=="1");
  WoWeuCN_QuestsCheckButton5:SetChecked(WoWeuCN_Quests_PS["overwritefonts"]=="1");
  WoWeuCN_QuestsCheckOther1:SetChecked(WoWeuCN_Quests_PS["other1"]=="1");
  WoWeuCN_QuestsCheckOther2:SetChecked(WoWeuCN_Quests_PS["other2"]=="1");
  WoWeuCN_QuestsCheckOther3:SetChecked(WoWeuCN_Quests_PS["other3"]=="1");
end

function WoweuCN_LoadOriginalHeaders()
   if QuestInfoDescriptionHeader:GetText() ~= nil and QuestInfoDescriptionHeader:GetText() ~= WoWeuCN_Quests_MessOrig.details and QuestInfoDescriptionHeader:GetText() ~= WoWeuCN_Quests_Messages.details then
    WoWeuCN_Quests_MessOrig.details = QuestInfoDescriptionHeader:GetText()
   end
   if QuestInfoObjectivesHeader:GetText() ~= nil and QuestInfoObjectivesHeader:GetText() ~= WoWeuCN_Quests_MessOrig.objectives and QuestInfoObjectivesHeader:GetText() ~= WoWeuCN_Quests_Messages.objectives then
    WoWeuCN_Quests_MessOrig.objectives = QuestInfoObjectivesHeader:GetText()
   end
   if QuestInfoRewardsFrame.Header:GetText() ~= nil and QuestInfoRewardsFrame.Header:GetText() ~= WoWeuCN_Quests_MessOrig.rewards and QuestInfoRewardsFrame.Header:GetText() ~= WoWeuCN_Quests_Messages.rewards then
    WoWeuCN_Quests_MessOrig.rewards = QuestInfoRewardsFrame.Header:GetText()
   end
   if QuestInfoRewardsFrame.ItemChooseText:GetText() ~= nil and QuestInfoRewardsFrame.ItemChooseText:GetText() ~= WoWeuCN_Quests_MessOrig.itemchoose1 and QuestInfoRewardsFrame.ItemChooseText:GetText() ~= WoWeuCN_Quests_Messages.itemchoose1 then
    WoWeuCN_Quests_MessOrig.itemchoose1 = QuestInfoRewardsFrame.ItemChooseText:GetText()
   end
   if QuestInfoRewardsFrame.ItemReceiveText:GetText() ~= nil and QuestInfoRewardsFrame.ItemReceiveText:GetText() ~= WoWeuCN_Quests_MessOrig.itemreceiv1 and QuestInfoRewardsFrame.ItemReceiveText:GetText()  ~= WoWeuCN_Quests_Messages.itemreceiv1 then
    WoWeuCN_Quests_MessOrig.itemreceiv1 = QuestInfoRewardsFrame.ItemReceiveText:GetText()
   end
   if QuestInfoSpellObjectiveLearnLabel:GetText() ~= nil and QuestInfoSpellObjectiveLearnLabel:GetText() ~= WoWeuCN_Quests_MessOrig.learnspell and QuestInfoSpellObjectiveLearnLabel:GetText() ~= WoWeuCN_Quests_Messages.learnspell then
    WoWeuCN_Quests_MessOrig.learnspell = QuestInfoSpellObjectiveLearnLabel:GetText()
   end
   if QuestProgressRequiredMoneyText:GetText() ~= nil and QuestProgressRequiredMoneyText:GetText() ~= WoWeuCN_Quests_MessOrig.reqmoney and QuestProgressRequiredMoneyText:GetText() ~= WoWeuCN_Quests_Messages.reqmoney then
    WoWeuCN_Quests_MessOrig.reqmoney = QuestProgressRequiredMoneyText:GetText()
   end
   if QuestProgressRequiredItemsText:GetText() ~= nil and QuestProgressRequiredItemsText:GetText() ~= WoWeuCN_Quests_MessOrig.reqitems and QuestProgressRequiredItemsText:GetText() ~= WoWeuCN_Quests_Messages.reqitems then
    WoWeuCN_Quests_MessOrig.reqitems = QuestProgressRequiredItemsText:GetText()
   end
 end

function WoWeuCN_Quests_BlizzardOptions()
  -- Create main frame for information text
  local WoWeuCN_QuestsOptions = CreateFrame("FRAME", "WoWeuCN_Quests_Options");
  WoWeuCN_QuestsOptions.name = "WoWeuCN-Quests";
  WoWeuCN_QuestsOptions.refresh = function (self) WoWeuCN_Quests_SetCheckButtonState() end;
  InterfaceOptions_AddCategory(WoWeuCN_QuestsOptions);

  local WoWeuCN_QuestsOptionsHeader = WoWeuCN_QuestsOptions:CreateFontString(nil, "ARTWORK");
  WoWeuCN_QuestsOptionsHeader:SetFontObject(GameFontNormalLarge);
  WoWeuCN_QuestsOptionsHeader:SetJustifyH("LEFT"); 
  WoWeuCN_QuestsOptionsHeader:SetJustifyV("TOP");
  WoWeuCN_QuestsOptionsHeader:ClearAllPoints();
  WoWeuCN_QuestsOptionsHeader:SetPoint("TOPLEFT", 16, -16);
  WoWeuCN_QuestsOptionsHeader:SetText("WoWeuCN-Quests, ver. "..WoWeuCN_Quests_version.." by qqytqqyt © 2021");
  WoWeuCN_QuestsOptionsHeader:SetFont(WoWeuCN_Quests_Font2, 16);

  local WoWeuCN_QuestsPlayer = WoWeuCN_QuestsOptions:CreateFontString(nil, "ARTWORK");
  WoWeuCN_QuestsPlayer:SetFontObject(GameFontNormalLarge);
  WoWeuCN_QuestsPlayer:SetJustifyH("LEFT"); 
  WoWeuCN_QuestsPlayer:SetJustifyV("TOP");
  WoWeuCN_QuestsPlayer:ClearAllPoints();
  WoWeuCN_QuestsPlayer:SetPoint("TOPRIGHT", WoWeuCN_QuestsOptionsHeader, "TOPRIGHT", 0, -22);
  WoWeuCN_QuestsPlayer:SetText("作者 : "..WoWeuCN_Quests_Messages.author);
  WoWeuCN_QuestsPlayer:SetFont(WoWeuCN_Quests_Font2, 16);

  local WoWeuCN_QuestsCheckButton0 = CreateFrame("CheckButton", "WoWeuCN_QuestsCheckButton0", WoWeuCN_QuestsOptions, "OptionsCheckButtonTemplate");
  WoWeuCN_QuestsCheckButton0:SetPoint("TOPLEFT", WoWeuCN_QuestsOptionsHeader, "BOTTOMLEFT", 0, -44);
  WoWeuCN_QuestsCheckButton0:SetScript("OnClick", function(self) if (WoWeuCN_Quests_PS["active"]=="1") then WoWeuCN_Quests_PS["active"]="0" else WoWeuCN_Quests_PS["active"]="1" end; end);
  WoWeuCN_QuestsCheckButton0Text:SetFont(WoWeuCN_Quests_Font2, 13);
  WoWeuCN_QuestsCheckButton0Text:SetText(WoWeuCN_Quests_Interface.active);

  local WoWeuCN_QuestsOptionsMode1 = WoWeuCN_QuestsOptions:CreateFontString(nil, "ARTWORK");
  WoWeuCN_QuestsOptionsMode1:SetFontObject(GameFontWhite);
  WoWeuCN_QuestsOptionsMode1:SetJustifyH("LEFT");
  WoWeuCN_QuestsOptionsMode1:SetJustifyV("TOP");
  WoWeuCN_QuestsOptionsMode1:ClearAllPoints();
  WoWeuCN_QuestsOptionsMode1:SetPoint("TOPLEFT", WoWeuCN_QuestsCheckButton0, "BOTTOMLEFT", 30, -20);
  WoWeuCN_QuestsOptionsMode1:SetFont(WoWeuCN_Quests_Font2, 13);
  WoWeuCN_QuestsOptionsMode1:SetText(WoWeuCN_Quests_Interface.options1);
  
  local WoWeuCN_QuestsCheckButton3 = CreateFrame("CheckButton", "WoWeuCN_QuestsCheckButton3", WoWeuCN_QuestsOptions, "OptionsCheckButtonTemplate");
  WoWeuCN_QuestsCheckButton3:SetPoint("TOPLEFT", WoWeuCN_QuestsOptionsMode1, "BOTTOMLEFT", 0, -5);
  WoWeuCN_QuestsCheckButton3:SetScript("OnClick", function(self) if (WoWeuCN_Quests_PS["transtitle"]=="0") then WoWeuCN_Quests_PS["transtitle"]="1" else WoWeuCN_Quests_PS["transtitle"]="0" end; end);
  WoWeuCN_QuestsCheckButton3Text:SetFont(WoWeuCN_Quests_Font2, 13);
  WoWeuCN_QuestsCheckButton3Text:SetText(WoWeuCN_Quests_Interface.transtitle);

  local WoWeuCN_QuestsCheckButton4 = CreateFrame("CheckButton", "WoWeuCN_QuestsCheckButton4", WoWeuCN_QuestsOptions, "OptionsCheckButtonTemplate");
  WoWeuCN_QuestsCheckButton4:SetPoint("TOPLEFT", WoWeuCN_QuestsOptionsMode1, "BOTTOMLEFT", 0, -25);
  WoWeuCN_QuestsCheckButton4:SetScript("OnClick", function(self) if (WoWeuCN_Quests_PS["transchat"]=="0") then WoWeuCN_Quests_PS["transchat"]="1" else WoWeuCN_Quests_PS["transchat"]="0" end; end);
  WoWeuCN_QuestsCheckButton4Text:SetFont(WoWeuCN_Quests_Font2, 13);
  WoWeuCN_QuestsCheckButton4Text:SetText(WoWeuCN_Quests_Interface.transchat);

  local WoWeuCN_QuestsCheckButton5 = CreateFrame("CheckButton", "WoWeuCN_QuestsCheckButton5", WoWeuCN_QuestsOptions, "OptionsCheckButtonTemplate");
  WoWeuCN_QuestsCheckButton5:SetPoint("TOPLEFT", WoWeuCN_QuestsOptionsMode1, "BOTTOMLEFT", 0, -45);
  WoWeuCN_QuestsCheckButton5:SetScript("OnClick", function(self) if (WoWeuCN_Quests_PS["overwritefonts"]=="0") then WoWeuCN_Quests_PS["overwritefonts"]="1" else WoWeuCN_Quests_PS["overwritefonts"]="0" end; end);
  WoWeuCN_QuestsCheckButton5Text:SetFont(WoWeuCN_Quests_Font2, 13);
  WoWeuCN_QuestsCheckButton5Text:SetText(WoWeuCN_Quests_Interface.overwritefonts);
end


function WoWeuCN_Quests_SaveQuest(event)
   if (event=="QUEST_DETAIL") then
      WoWeuCN_Quests_SAVED[WoWeuCN_Quests_quest_EN.id.." TITLE"]=GetTitleText();            -- save original title to future translation
      WoWeuCN_Quests_SAVED[WoWeuCN_Quests_quest_EN.id.." DESCRIPTION"]=GetQuestText();      -- save original text to future translation
      WoWeuCN_Quests_SAVED[WoWeuCN_Quests_quest_EN.id.." OBJECTIVE"]=GetObjectiveText();    -- save original text to future translation
   end
   if (event=="QUEST_PROGRESS") then
      WoWeuCN_Quests_SAVED[WoWeuCN_Quests_quest_EN.id.." PROGRESS"]=GetProgressText();      -- save original text to future translation
   end
   if (event=="QUEST_COMPLETE") then
      WoWeuCN_Quests_SAVED[WoWeuCN_Quests_quest_EN.id.." COMPLETE"]=GetRewardText();        -- save original text to future translation
   end
   if (WoWeuCN_Quests_SAVED[WoWeuCN_Quests_quest_EN.id.." TITLE"]==nil) then
      WoWeuCN_Quests_SAVED[WoWeuCN_Quests_quest_EN.id.." TITLE"]=GetTitleText();            -- save title in case of End only
   end
   WoWeuCN_Quests_SAVED[WoWeuCN_Quests_quest_EN.id.." PLAYER"]=WoWeuCN_Quests_name..'@'..WoWeuCN_Quests_race..'@'..WoWeuCN_Quests_class;  -- save player data
end

function WoWeuCN_Quests_ON_OFF()
   if (curr_trans=="1") then
      curr_trans="0";
      WoWeuCN_Quests_Translate_Off(1);
   else   
      curr_trans="1";
      WoWeuCN_Quests_Translate_On(1);
   end
end


-- First function called after the add-in has been loaded
function WoWeuCN_Quests_OnLoad()
   WoWeuCN_Quests = CreateFrame("Frame");
   WoWeuCN_Quests:SetScript("OnEvent", WoWeuCN_Quests_OnEvent);
   WoWeuCN_Quests:RegisterEvent("ADDON_LOADED");
   WoWeuCN_Quests:RegisterEvent("QUEST_ACCEPTED");
   WoWeuCN_Quests:RegisterEvent("QUEST_DETAIL");
   WoWeuCN_Quests:RegisterEvent("QUEST_PROGRESS");
   WoWeuCN_Quests:RegisterEvent("QUEST_COMPLETE");
--   WoWeuCN_Quests:RegisterEvent("QUEST_FINISHED");
--   WoWeuCN_Quests:RegisterEvent("QUEST_GREETING");

   -- Quest ID button in QuestFrame 
   WoWeuCN_Quests_ToggleButton0 = CreateFrame("Button",nil, QuestFrame, "UIPanelButtonTemplate");
   WoWeuCN_Quests_ToggleButton0:SetWidth(150);
   WoWeuCN_Quests_ToggleButton0:SetHeight(20);
   WoWeuCN_Quests_ToggleButton0:SetText("Quest ID=?");
   WoWeuCN_Quests_ToggleButton0:Show();
   WoWeuCN_Quests_ToggleButton0:ClearAllPoints();
   WoWeuCN_Quests_ToggleButton0:SetPoint("TOPLEFT", QuestFrame, "TOPLEFT", 120, -50);
   WoWeuCN_Quests_ToggleButton0:SetScript("OnClick", WoWeuCN_Quests_ON_OFF);
   
   -- Quest ID button in Quest Log Popup Detail Frame
   WoWeuCN_Quests_ToggleButton1 = CreateFrame("Button",nil, QuestLogFrame, "UIPanelButtonTemplate");
   WoWeuCN_Quests_ToggleButton1:SetWidth(120);
   WoWeuCN_Quests_ToggleButton1:SetHeight(15);
   WoWeuCN_Quests_ToggleButton1:SetText("Quest ID=?");
   WoWeuCN_Quests_ToggleButton1:Show();
   WoWeuCN_Quests_ToggleButton1:ClearAllPoints();
   WoWeuCN_Quests_ToggleButton1:SetPoint("TOPLEFT", QuestLogFrame, "TOPLEFT", 218, -58);
   WoWeuCN_Quests_ToggleButton1:SetScript("OnClick", WoWeuCN_Quests_ON_OFF);

   -- Quest ID button in QuestMapDetailsScrollFrame
   WoWeuCN_Quests_ToggleButton2 = CreateFrame("Button",nil, QuestMapDetailsScrollFrame, "UIPanelButtonTemplate");
   WoWeuCN_Quests_ToggleButton2:SetWidth(150);
   WoWeuCN_Quests_ToggleButton2:SetHeight(20);
   WoWeuCN_Quests_ToggleButton2:SetText("Quest ID=?");
   WoWeuCN_Quests_ToggleButton2:Show();
   WoWeuCN_Quests_ToggleButton2:ClearAllPoints();
   WoWeuCN_Quests_ToggleButton2:SetPoint("TOPLEFT", QuestMapDetailsScrollFrame, "TOPLEFT", 116, 29);
   WoWeuCN_Quests_ToggleButton2:SetScript("OnClick", WoWeuCN_Quests_ON_OFF);


   -- function called after clicking on the quest name in QuestTracker
--   hooksecurefunc(QUEST_TRACKER_MODULE, "OnBlockHeaderClick", WoWeuCN_Quests_PrepareReload);
   
   -- Function called after clicking on the quest name in QuestMapFrame
  QuestLogDetailScrollFrame:HookScript("OnShow", WoWeuCN_Quests_Prepare1sek);
  EmptyQuestLogFrame:HookScript("OnShow", WoWeuCN_Quests_EmptyQuestLog);
  hooksecurefunc("SelectQuestLogEntry", WoWeuCN_Quests_Prepare1sek);

--  QuestLogTitleButton:HookScript("OnClick", WoWeuCN_Quests_PrepareReload);
--  if hooksecurefunc then
--     hooksecurefunc("QuestLogTitleButton_OnClick", function() WoWeuCN_Quests_PrepareReload() end);
--  end

--   hooksecurefunc("QuestMapFrame_ShowQuestDetails", WoWeuCN_Quests_PrepareReload);
   
   WoweuCN_LoadOriginalHeaders();
end

-- Specifies the current quest ID number from various methods
function WoWeuCN_Quests_GetQuestID()
   if ( isGetQuestID=="1" ) then
      quest_ID = GetQuestID();
   end
   
   if ((QuestLogFrame:IsVisible()) and ((quest_ID==nil) or (quest_ID==0))) then
      local questTitle, level, questTag, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(GetQuestLogSelection());
      quest_ID = questID;
   end
   
--   quest_ID = QuestFrame.questID;
--   if (quest_ID==nil) then
--      quest_ID = QuestLogPopupDetailFrame.questID;
--   end
     
   if (quest_ID==nil) then
      if (WoWeuCN_Quests_onDebug) then
         print('ID not found');
      end   
      quest_ID=0;
   else   
      if (WoWeuCN_Quests_onDebug) then
         print('Found ID='..tostring(quest_ID));
      end   
   end   

   return (quest_ID);
end

local function StringHash(text)              
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
 
local function UpdateBubblizeText()
   local chatBubbles = C_ChatBubbles.GetAllChatBubbles(false)
   for _, chatBubble in pairs(chatBubbles) do
      for j = 1, chatBubble:GetNumChildren() do               
         child = select(j, chatBubble:GetChildren()); 
         if true or not child:IsForbidden() then                    
            for j = 1, child:GetNumRegions() do                  
               region = select(j, child:GetRegions());           
               for idx, iArray in ipairs(WoWeuCN_Quests_BubblesArray) do     

                  if region and not region:GetName() and region:IsVisible() and region.GetText and region:GetText() == iArray[1] then         
                     region:SetText(iArray[2]);       
                     if (WoWeuCN_Quests_PS["overwritefonts"] == "1") then
                        local font, size, _ = child.String:GetFont()
                        region:SetFont(WoWeuCN_Quests_Font1, size)
                     end
                     tremove(WoWeuCN_Quests_BubblesArray, idx);             
                  end
               end
            end
         end
      end
   end
   
   for idx, iArray in ipairs(WoWeuCN_Quests_BubblesArray) do           
      if (iArray[3] >= 100) then                           
         tremove(WoWeuCN_Quests_BubblesArray, idx);                    
      else
         iArray[3] = iArray[3]+1;                         
      end;
   end;
   if (#(WoWeuCN_Quests_BubblesArray) == 0) then
      WoWeuCN_Quests_CtrFrame:SetScript("OnUpdate", nil);           
   end;
 end;
 
local function FindProS(text)               
   local dl_txt = string.len(text)-1;
   for i_j=1,dl_txt,1 do
      if (strsub(text,i_j,i_j+1)=="%s") then       
         return i_j;
      end
   end
   return 0;
end

local function OnNpcChat(self, event, arg1, arg2, arg3, arg4, arg5, ...)     
   local changeBubble = false;
   local colorText = "";
   local original_txt = strtrim(arg1);
   local name_NPC = arg2;
   local target = arg5;
   local translated = false;     
   
   local verb = " says: "
   if (event == "CHAT_MSG_MONSTER_SAY") then     
      colorText = "|cFFFFFF9F";
      changeBubble = true;
   elseif (event == "CHAT_MSG_MONSTER_PARTY") then
      colorText = "|cFFAAAAFF";
   elseif (event == "CHAT_MSG_MONSTER_YELL") then
      colorText = "|cFFFF4040";
      verb = " yells: "
      changeBubble = true;
   elseif (event == "CHAT_MSG_MONSTER_WHISPER") then
      colorText = "|cFFFFB5EB";
      verb = " whispers: "
   elseif (event == "CHAT_MSG_MONSTER_EMOTE") then
      colorText = "|cFFFF8040";
   end

   if (WoWeuCN_Quests_PS["active"] == "1" and WoWeuCN_Quests_PS["transchat"] == "1") then                    
      if (arg5 ~= "") then
         original_txt = string.gsub(original_txt, arg5, "");      
         original_txt = string.gsub(original_txt, string.upper(arg5), "");   
      end

      for i, text_replaced in pairs(removed_text) do
         original_txt = string.gsub(original_txt, text_replaced, "");      
         original_txt = string.gsub(original_txt, string.upper(text_replaced), "");     
         original_txt = string.gsub(original_txt, string.lower(text_replaced), "");       
      end

      local HashCode = StringHash(original_txt);
      if (WoWeuCN_Quests_ScriptData[HashCode]) then        
         newMessage = WoWeuCN_Quests_ScriptData[HashCode];
         if (arg5 ~= "") then                            
            newMessage = string.gsub(newMessage, "{name}", arg5);    
         end

         newMessage = string.gsub(newMessage, "<class>", player_class.W1);    
         newMessage = string.gsub(newMessage, "<CLASS>", player_class.W2);    
         newMessage = string.gsub(newMessage, "<race>", player_race.W1);    
         newMessage = string.gsub(newMessage, "<RACE>", player_race.W2);    

         newMessage = WoWeuCN_Quests_ExpandUnitInfo(newMessage)

         translated = true;
         nr_poz=FindProS(newMessage,1);        
         
         local font, size, _3 = self:GetFont()
         if (WoWeuCN_Quests_PS["overwritefonts"] == "1") then
            self:SetFont(WoWeuCN_Quests_Font1, size, _3)
         end

         if (nr_poz>0) then          
            if (nr_poz==1) then
               newMessage = name_NPC..strsub(newMessage, 3);
            else
               newMessage = strsub(newMessage,1,nr_poz-1)..name_NPC..strsub(newMessage, nr_poz+2);
            end
            self:AddMessage(colorText..newMessage);
         elseif (strsub(newMessage,1,2)=="%o") then         
            newMessage = strsub(newMessage, 3);
            self:AddMessage(colorText..newMessage:gsub("^%s*", ""));
         else
            self:AddMessage(colorText..name_NPC..verb..newMessage);
         end
         
         if (changeBubble) then                         
            tinsert(WoWeuCN_Quests_BubblesArray, { [1] = arg1, [2] = newMessage, [3] = 1 });
            WoWeuCN_Quests_CtrFrame:SetScript("OnUpdate", UpdateBubblizeText);
         end
      end
   end

   return translated
end


-- Even handlers
function WoWeuCN_Quests_OnEvent(self, event, name, ...)
   if (WoWeuCN_Quests_onDebug) then
      print('OnEvent-event: '..event);   
   end   
   if (event=="ADDON_LOADED" and name=="WoWeuCN_Quests") then

      ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", OnNpcChat)
      ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_PARTY", OnNpcChat)
      ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_YELL", OnNpcChat)
      ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_WHISPER", OnNpcChat)
      ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", OnNpcChat)
      WoWeuCN_Quests_BubblesArray = {};
      
      WoWeuCN_Quests_CtrFrame:SetScript("OnUpdate", UpdateBubblizeText);             -- wyłącz metodę Update, bo tablica pusta

      SlashCmdList["WOWEUCN_QUESTS"] = function(msg) WoWeuCN_Quests_SlashCommand(msg); end
      SLASH_WOWEUCN_QUESTS1 = "/woweucn-quests";
      SLASH_WOWEUCN_QUESTS2 = "/woweucn";
      WoWeuCN_Quests_CheckVars();
      -- Create interface Options in Blizzard-Interface-Addons
      WoWeuCN_Quests_BlizzardOptions();
      
      WoWeuCN_Quests_wait(2, Broadcast)
      WoWeuCN_Quests:UnregisterEvent("ADDON_LOADED");
      WoWeuCN_Quests.ADDON_LOADED = nil;
      if (not isGetQuestID) then
         DetectEmuServer();
      end
   elseif (event=="QUEST_DETAIL" or event=="QUEST_PROGRESS" or event=="QUEST_COMPLETE") then
      if ( QuestFrame:IsVisible()) then
         WoWeuCN_Quests_QuestPrepare(event);
      end	-- QuestFrame is Visible
   end
end

-- An empty QuestLog was opened
function WoWeuCN_Quests_EmptyQuestLog()
   WoWeuCN_Quests_ToggleButton1:Hide();
end


-- QuestLogPopupDetailFrame or QuestMapDetailsScrollFrame or QuestGuru or Immersion window opened
function WoWeuCN_Quests_QuestPrepare(questEvent)
   WoWeuCN_Quests_ToggleButton1:Show();        -- Show, because it could be hidden by an empty QuestLog
   
   q_ID = WoWeuCN_Quests_GetQuestID();
   str_ID = tostring(q_ID);
   WoWeuCN_Quests_quest_EN.id = q_ID;
   WoWeuCN_Quests_quest_LG.id = q_ID;

   if ( WoWeuCN_Quests_PS["active"]=="1" ) then	-- Translation activated
      WoWeuCN_Quests_ToggleButton0:Enable();
      WoWeuCN_Quests_ToggleButton1:Enable();
      WoWeuCN_Quests_ToggleButton2:Enable();
      curr_trans = "1";
      if ( WoWeuCN_Quests_QuestData[str_ID] ) then   -- Display only when there is a translation
         WoWeuCN_Quests_quest_LG.title = WoWeuCN_Quests_ExpandUnitInfo(WoWeuCN_Quests_QuestData[str_ID]["Title"]);
         WoWeuCN_Quests_quest_EN.title = GetTitleText();
         if (WoWeuCN_Quests_quest_EN.title=="") then
            WoWeuCN_Quests_quest_EN.title=GetQuestLogTitle(GetQuestLogSelection());
         end
         WoWeuCN_Quests_quest_LG.details = WoWeuCN_Quests_ExpandUnitInfo(WoWeuCN_Quests_QuestData[str_ID]["Description"]);
         WoWeuCN_Quests_quest_LG.objectives = WoWeuCN_Quests_ExpandUnitInfo(WoWeuCN_Quests_QuestData[str_ID]["Objectives"]);
--         WoWeuCN_Quests_quest_EN.details = QuestLogQuestDescription:GetText();
--         WoWeuCN_Quests_quest_EN.objectives = QuestLogObjectivesText:GetText();
         if (questEvent=="QUEST_DETAIL") then
            WoWeuCN_Quests_quest_EN.details = GetQuestText();
            WoWeuCN_Quests_quest_EN.objectives = GetObjectiveText();
            WoWeuCN_Quests_quest_EN.itemchoose = WoWeuCN_Quests_MessOrig.itemchoose1;
            WoWeuCN_Quests_quest_LG.itemchoose = WoWeuCN_Quests_Messages.itemchoose1;
            WoWeuCN_Quests_quest_EN.itemreceive = WoWeuCN_Quests_MessOrig.itemreceiv1;
            WoWeuCN_Quests_quest_LG.itemreceive = WoWeuCN_Quests_Messages.itemreceiv1;
         else   
            if (WoWeuCN_Quests_quest_LG.details ~= QuestLogQuestDescription:GetText()) then
               WoWeuCN_Quests_quest_EN.details = QuestLogQuestDescription:GetText();
            end
            if (WoWeuCN_Quests_quest_LG.objectives ~= QuestLogObjectivesText:GetText()) then
               WoWeuCN_Quests_quest_EN.objectives = QuestLogObjectivesText:GetText();
            end
         end   
         if (questEvent=="QUEST_PROGRESS") then
            WoWeuCN_Quests_quest_EN.progress = GetProgressText();
            WoWeuCN_Quests_quest_LG.progress = WoWeuCN_Quests_ExpandUnitInfo(WoWeuCN_Quests_QuestData[str_ID]["Progress"]);
         end
         if (questEvent=="QUEST_COMPLETE") then
            WoWeuCN_Quests_quest_EN.completion = GetRewardText();
            WoWeuCN_Quests_quest_LG.completion = WoWeuCN_Quests_ExpandUnitInfo(WoWeuCN_Quests_QuestData[str_ID]["Completion"]);
            WoWeuCN_Quests_quest_EN.itemchoose = WoWeuCN_Quests_MessOrig.itemchoose2;
            WoWeuCN_Quests_quest_LG.itemchoose = WoWeuCN_Quests_Messages.itemchoose2;
            WoWeuCN_Quests_quest_EN.itemreceive = WoWeuCN_Quests_MessOrig.itemreceiv2;
         end         

         -- missing data
         if (WoWeuCN_Quests_quest_EN.details ~= nil and strlen(WoWeuCN_Quests_quest_EN.details)>0 and strlen(WoWeuCN_Quests_quest_LG.details)==0) then
            WoWeuCN_Quests_quest_LG.details = WoWeuCN_Quests_quest_EN.details;
            QuestInfoDescriptionHeader:SetFont(Original_Font1, 18);
            QuestInfoDescriptionText:SetFont(Original_Font2, Original_Font2_Size);
         end
         if (WoWeuCN_Quests_quest_EN.objectives ~= nil and strlen(WoWeuCN_Quests_quest_EN.objectives)>0 and strlen(WoWeuCN_Quests_quest_LG.objectives)==0) then
            WoWeuCN_Quests_quest_LG.objectives = WoWeuCN_Quests_quest_EN.objectives;
            QuestInfoObjectivesHeader:SetFont(Original_Font1, 18);
            QuestInfoObjectivesText:SetFont(Original_Font2, Original_Font2_Size);
         end
         if (WoWeuCN_Quests_quest_EN.progress ~= nil and strlen(WoWeuCN_Quests_quest_EN.progress)>0 and strlen(WoWeuCN_Quests_quest_LG.progress)==0) then
            WoWeuCN_Quests_quest_LG.progress = WoWeuCN_Quests_quest_EN.progress;
            QuestProgressText:SetFont(Original_Font2, Original_Font2_Size);
         end
         if (WoWeuCN_Quests_quest_EN.completion ~= nil and strlen(WoWeuCN_Quests_quest_EN.completion)>0 and strlen(WoWeuCN_Quests_quest_LG.completion)==0) then
            WoWeuCN_Quests_quest_LG.completion = WoWeuCN_Quests_quest_EN.completion;
            QuestInfoRewardText:SetFont(Original_Font2, Original_Font2_Size);
         end

         WoWeuCN_Quests_ToggleButton0:SetText("Quest ID="..WoWeuCN_Quests_quest_LG.id.." ("..WoWeuCN_Quests_lang..")");
         WoWeuCN_Quests_ToggleButton1:SetText("Quest ID="..WoWeuCN_Quests_quest_LG.id.." ("..WoWeuCN_Quests_lang..")");
         WoWeuCN_Quests_ToggleButton2:SetText("Quest ID="..WoWeuCN_Quests_quest_LG.id.." ("..WoWeuCN_Quests_lang..")");
         WoWeuCN_Quests_Translate_On(1);
      else	      -- Quest cannot be translated
         WoWeuCN_Quests_ToggleButton0:Disable();
         WoWeuCN_Quests_ToggleButton1:Disable();
         WoWeuCN_Quests_ToggleButton2:Disable();
       
         WoWeuCN_Quests_ToggleButton0:SetText("Quest ID="..str_ID);
         WoWeuCN_Quests_ToggleButton1:SetText("Quest ID="..str_ID);
         WoWeuCN_Quests_ToggleButton2:SetText("Quest ID="..str_ID);
       
         WoWeuCN_Quests_Translate_On(0);
      end -- The quest is translated in the database
   else	-- Translations off...
      WoWeuCN_Quests_ToggleButton0:Disable();
      WoWeuCN_Quests_ToggleButton1:Disable();
      WoWeuCN_Quests_ToggleButton2:Disable();
--         if (isQuestGuru()) then
--            WoWeuCN_Quests_ToggleButton3:Disable();
--         end
--         if (isImmersion()) then
--            WoWeuCN_Quests_ToggleButton4:Disable();
--         end
      if ( WoWeuCN_Quests_QuestData[str_ID] ) then	-- ...but there is a translation in the database
         WoWeuCN_Quests_ToggleButton1:SetText("Quest ID="..str_ID);
         WoWeuCN_Quests_ToggleButton2:SetText("Quest ID="..str_ID);
      else
         WoWeuCN_Quests_ToggleButton1:SetText("Quest ID="..str_ID);
         WoWeuCN_Quests_ToggleButton2:SetText("Quest ID="..str_ID);
      end
   end	-- Translation actviated
end


-- Displays the translation
function WoWeuCN_Quests_Translate_On(typ)
   WoweuCN_LoadOriginalHeaders()
   if (WoWeuCN_Quests_PS["transtitle"]=="1") then    -- view translated title
      QuestInfoTitleHeader:SetFont(WoWeuCN_Quests_Font1, 18);
      QuestProgressTitleText:SetFont(WoWeuCN_Quests_Font1, 18);
   end

   QuestInfoObjectivesHeader:SetFont(WoWeuCN_Quests_Font1, 18);
   QuestInfoObjectivesHeader:SetText(WoWeuCN_Quests_Messages.objectives);
   QuestInfoObjectivesText:SetFont(WoWeuCN_Quests_Font2, 13);

   QuestLogRewardTitleText:SetFont(WoWeuCN_Quests_Font1, 18);
   QuestLogRewardTitleText:SetText(WoWeuCN_Quests_Messages.rewards);    
   QuestInfoRewardsFrame.Header:SetFont(WoWeuCN_Quests_Font1, 18);
   QuestInfoRewardsFrame.Header:SetText(WoWeuCN_Quests_Messages.rewards);  
   
   QuestLogDescriptionTitle:SetFont(WoWeuCN_Quests_Font1, 18);
   QuestLogDescriptionTitle:SetText(WoWeuCN_Quests_Messages.details);    
   
   QuestProgressRequiredItemsText:SetFont(WoWeuCN_Quests_Font1, 18);
   QuestProgressRequiredItemsText:SetText(WoWeuCN_Quests_Messages.reqitems);
   
--   QuestInfoSpellObjectiveLearnLabel:SetFont(WoWeuCN_Quests_Font2, 13);
--   QuestInfoSpellObjectiveLearnLabel:SetText(WoWeuCN_Quests_Messages.learnspell);
--   QuestInfoXPFrame.ReceiveText:SetFont(WoWeuCN_Quests_Font2, 13);
--   QuestInfoXPFrame.ReceiveText:SetText(WoWeuCN_Quests_Messages.experience);
--   MapQuestInfoRewardsFrame.ItemChooseText:SetFont(WoWeuCN_Quests_Font2, 11);
--   MapQuestInfoRewardsFrame.ItemReceiveText:SetFont(WoWeuCN_Quests_Font2, 11);
--   MapQuestInfoRewardsFrame.ItemChooseText:SetText(WoWeuCN_Quests_Messages.itemchoose1);
--   MapQuestInfoRewardsFrame.ItemReceiveText:SetText(WoWeuCN_Quests_Messages.itemreceiv1);
   if (typ==1) then			-- full switchover (there is a translation)
      QuestLogItemChooseText:SetFont(WoWeuCN_Quests_Font2, 13);
      QuestLogItemChooseText:SetText(WoWeuCN_Quests_Messages.itemchoose1);
      QuestLogItemReceiveText:SetFont(WoWeuCN_Quests_Font2, 13);
      QuestLogItemReceiveText:SetText(WoWeuCN_Quests_Messages.itemreceiv1);
      numer_ID = WoWeuCN_Quests_quest_LG.id;
      str_ID = tostring(numer_ID);
      if (numer_ID>0 and WoWeuCN_Quests_QuestData[str_ID]) then	-- restore translated subtitle version
         if (WoWeuCN_Quests_PS["transtitle"]=="1") then    -- view translated title
            QuestLogQuestTitle:SetFont(WoWeuCN_Quests_Font1, 18);
            QuestLogQuestTitle:SetText(WoWeuCN_Quests_quest_LG.title);
            QuestInfoTitleHeader:SetFont(WoWeuCN_Quests_Font1, 18);
            QuestInfoTitleHeader:SetText(WoWeuCN_Quests_quest_LG.title);
            QuestProgressTitleText:SetFont(WoWeuCN_Quests_Font1, 18);
            QuestProgressTitleText:SetText(WoWeuCN_Quests_quest_LG.title);
         end
         WoWeuCN_Quests_ToggleButton0:SetText("Quest ID="..WoWeuCN_Quests_quest_LG.id.." ("..WoWeuCN_Quests_lang..")");
         WoWeuCN_Quests_ToggleButton1:SetText("Quest ID="..WoWeuCN_Quests_quest_LG.id.." ("..WoWeuCN_Quests_lang..")");
         WoWeuCN_Quests_ToggleButton2:SetText("Quest ID="..WoWeuCN_Quests_quest_LG.id.." ("..WoWeuCN_Quests_lang..")");
        
         QuestLogQuestDescription:SetFont(WoWeuCN_Quests_Font2, 13);
         QuestLogQuestDescription:SetText(WoWeuCN_Quests_quest_LG.details);
         QuestInfoDescriptionText:SetFont(WoWeuCN_Quests_Font2, 13);
         QuestInfoDescriptionText:SetText(WoWeuCN_Quests_quest_LG.details);
         QuestInfoObjectivesText:SetFont(WoWeuCN_Quests_Font2, 13);
         QuestInfoObjectivesText:SetText(WoWeuCN_Quests_quest_LG.objectives);
         
         QuestLogObjectivesText:SetFont(WoWeuCN_Quests_Font2, 13);
         QuestLogObjectivesText:SetText(WoWeuCN_Quests_quest_LG.objectives);
         
         QuestProgressText:SetFont(WoWeuCN_Quests_Font2, 13);
         QuestProgressText:SetText(WoWeuCN_Quests_quest_LG.progress);
         QuestInfoRewardText:SetFont(WoWeuCN_Quests_Font2, 13);
         QuestInfoRewardText:SetText(WoWeuCN_Quests_quest_LG.completion);
         
         QuestInfoRewardsFrame.ItemChooseText:SetFont(WoWeuCN_Quests_Font2, 13);
         QuestInfoRewardsFrame.ItemChooseText:SetText(WoWeuCN_Quests_quest_LG.itemchoose);
         QuestInfoRewardsFrame.ItemReceiveText:SetFont(WoWeuCN_Quests_Font2, 13);
         QuestInfoRewardsFrame.ItemReceiveText:SetText(WoWeuCN_Quests_quest_LG.itemreceive);
      end
   else
      if (curr_trans == "1") then
         QuestInfoRewardsFrame.ItemChooseText:SetText(WoWeuCN_Quests_Messages.itemchoose1);
         QuestInfoRewardsFrame.ItemReceiveText:SetText(WoWeuCN_Quests_Messages.itemreceiv1);
         if ((ImmersionFrame ~= nil ) and (ImmersionFrame.TalkBox:IsVisible() )) then
            if (not WoWeuCN_Quests_wait(0.2,WoWeuCN_Quests_Immersion_Static)) then
               -- text replacement with a delay of 0.2 sec
            end
         end
      end
   end
end


-- displays the original text
function WoWeuCN_Quests_Translate_Off(typ)
   QuestInfoTitleHeader:SetFont(Original_Font1, 18);
   QuestInfoTitleHeader:SetText(WoWeuCN_Quests_quest_EN.title);

   QuestLogQuestTitle:SetFont(Original_Font1, 18);
   QuestLogQuestTitle:SetText(WoWeuCN_Quests_quest_EN.title);

   QuestProgressTitleText:SetFont(WoWeuCN_Quests_Font1, 18);
   QuestProgressTitleText:SetText(WoWeuCN_Quests_quest_EN.title);
   
   QuestInfoObjectivesHeader:SetFont(Original_Font1, 18);      -- Quest Objectives
   QuestInfoObjectivesHeader:SetText(WoWeuCN_Quests_MessOrig.objectives);

   QuestLogRewardTitleText:SetFont(Original_Font1, 18);        -- Reward
   QuestLogRewardTitleText:SetText(WoWeuCN_Quests_MessOrig.rewards);
   QuestInfoRewardsFrame.Header:SetFont(Original_Font1, 18);   -- Reward
   QuestInfoRewardsFrame.Header:SetText(WoWeuCN_Quests_MessOrig.rewards);
   
   QuestLogDescriptionTitle:SetFont(Original_Font1, 18);       -- Description
   QuestLogDescriptionTitle:SetText(WoWeuCN_Quests_MessOrig.details);
   
   QuestProgressRequiredItemsText:SetFont(Original_Font1, 18);
   QuestProgressRequiredItemsText:SetText(WoWeuCN_Quests_MessOrig.reqitems);
   
   QuestInfoSpellObjectiveLearnLabel:SetFont(Original_Font2, Original_Font2_Size);
   QuestInfoSpellObjectiveLearnLabel:SetText(WoWeuCN_Quests_MessOrig.learnspell);
   QuestInfoXPFrame.ReceiveText:SetFont(Original_Font2, Original_Font2_Size);
   QuestInfoXPFrame.ReceiveText:SetText(WoWeuCN_Quests_MessOrig.experience);
   if (typ==1) then			-- full switchover (there is a translation)
      QuestLogItemChooseText:SetFont(Original_Font2, Original_Font2_Size);
      QuestLogItemChooseText:SetText(WoWeuCN_Quests_MessOrig.itemchoose1);
      QuestLogItemReceiveText:SetFont(Original_Font2, Original_Font2_Size);
      QuestLogItemReceiveText:SetText(WoWeuCN_Quests_MessOrig.itemreceiv1);
      numer_ID = WoWeuCN_Quests_quest_EN.id;
      if (numer_ID>0 and WoWeuCN_Quests_QuestData[str_ID]) then	-- restore original subtitle version
         WoWeuCN_Quests_ToggleButton0:SetText("Quest ID="..WoWeuCN_Quests_quest_EN.id);
         WoWeuCN_Quests_ToggleButton1:SetText("Quest ID="..WoWeuCN_Quests_quest_EN.id);
         WoWeuCN_Quests_ToggleButton2:SetText("Quest ID="..WoWeuCN_Quests_quest_EN.id);
        
         QuestLogQuestDescription:SetFont(Original_Font2, Original_Font2_Size);
         QuestLogQuestDescription:SetText(WoWeuCN_Quests_quest_EN.details);
         QuestInfoDescriptionText:SetFont(Original_Font2, Original_Font2_Size);
         QuestInfoDescriptionText:SetText(WoWeuCN_Quests_quest_EN.details);
         QuestInfoObjectivesText:SetFont(Original_Font2, Original_Font2_Size);
         QuestInfoObjectivesText:SetText(WoWeuCN_Quests_quest_EN.objectives);
         
         QuestLogObjectivesText:SetFont(Original_Font2, Original_Font2_Size);
         QuestLogObjectivesText:SetText(WoWeuCN_Quests_quest_EN.objectives);
         
         QuestProgressText:SetFont(Original_Font2, Original_Font2_Size);
         QuestProgressText:SetText(WoWeuCN_Quests_quest_EN.progress);
         QuestInfoRewardText:SetFont(Original_Font2, Original_Font2_Size);
         QuestInfoRewardText:SetText(WoWeuCN_Quests_quest_EN.completion);
         
         QuestInfoRewardsFrame.ItemChooseText:SetFont(Original_Font2, Original_Font2_Size);
         QuestInfoRewardsFrame.ItemChooseText:SetText(WoWeuCN_Quests_quest_EN.itemchoose);
         QuestInfoRewardsFrame.ItemReceiveText:SetFont(Original_Font2, Original_Font2_Size);
         QuestInfoRewardsFrame.ItemReceiveText:SetText(WoWeuCN_Quests_quest_EN.itemreceive);
      end
   end
end


function WoWeuCN_Quests_delayed3()
   WoWeuCN_Quests_ToggleButton4:SetText("请先选择任务");
   WoWeuCN_Quests_ToggleButton4:Hide();
   if (not WoWeuCN_Quests_wait(1,WoWeuCN_Quests_delayed4)) then
   ---
   end
end


function WoWeuCN_Quests_PrepareReload()
   WoWeuCN_Quests_QuestPrepare('');
end;      


function WoWeuCN_Quests_Prepare1sek()
   if (not WoWeuCN_Quests_wait(0.1,WoWeuCN_Quests_PrepareReload)) then
   ---
   end
end;      

-- replace pending characters in the text
function WoWeuCN_Quests_ExpandUnitInfo(msg)
   msg = string.gsub(msg, "NEW_LINE", "\n");
   msg = string.gsub(msg, "{name}", WoWeuCN_Quests_name);
   
-- player gender YOUR_GENDER(x;y)
   local nr_1, nr_2, nr_3 = 0;
   local WoWeuCN_Quests_forma = "";
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
               if (WoWeuCN_Quests_sex==3) then        -- female form
                  WoWeuCN_Quests_forma = string.sub(msg,nr_2+1,nr_3-1);
               else                        -- male form
                  WoWeuCN_Quests_forma = string.sub(msg,nr_1+1,nr_2-1);
               end
               msg = string.sub(msg,1,nr_poz-1) .. WoWeuCN_Quests_forma .. string.sub(msg,nr_3+1);
            end   
         end
      end
      nr_poz = string.find(msg, "YOUR_GENDER");
   end

   if (WoWeuCN_Quests_sex==3) then        
      msg = string.gsub(msg, "{race}", player_race.W2);                        
      msg = string.gsub(msg, "{class}", player_class.W2);                      
   else                    
      msg = string.gsub(msg, "{race}", player_race.W1);                        
      msg = string.gsub(msg, "{class}", player_class.W1);                      
   end
   
   return msg;
end

function Broadcast()
   print ("|cffffff00WoWeuCN-Quests ver. "..WoWeuCN_Quests_version.." - "..WoWeuCN_Quests_Messages.loaded);
   print (_G["ORANGE_FONT_COLOR_CODE"] .. "已加载NPC喊话翻译模块(beta)。仅支持部分NPC喊话。如需关闭请在插件设置中调整。");
   print (_G["ORANGE_FONT_COLOR_CODE"] .. "如遇字体缺失/不连贯问题请手动在客户端中采用多语系字体，或在插件设置中使用内置字体选项。");
    
   local regionCode = GetCurrentRegion()
   if (regionCode ~= 3) then
     print ("|cffffff00本插件主要服务欧洲服务器玩家。你所在的服务器区域支持中文客户端，如有需要请搜索战网修改客户端语言教程修改语言，直接使用中文进行游戏。|r");
     return
   end

   local name,title,_,enabled = GetAddOnInfo('WoWeuCN_Tooltips')
   if (title == nil) then
      local addonName = _G["GREEN_FONT_COLOR_CODE"] .. "Tooltips Translator - Chinese|r"
      print ("|cffffff00欢迎使用任务汉化插件。如需法术/道具等汉化请安装 " .. addonName .. " 翻译插件。|r");
   end

   local name, _, rank = GetGuildInfo("player");
   if (name == nil or rank > 2) then
      return
   end
   if (time() - WoWeuCN_Quests_LastAnnounceDate < WowenCN_Quests_WeekDiff) then
      return
   end
   
   local bNetTagInfo = _G["GREEN_FONT_COLOR_CODE"] .. "<>|r" 
   WoWeuCN_Quests_LastAnnounceDate = time()
   --print(_G["ORANGE_FONT_COLOR_CODE"] .. "休闲玩家寻找华人休闲工会回归TBC，有意接收请联系" .. bNetTagInfo .. "。|r")
 end
 

