-- Addon: WoWeuCN-Quests
-- Author: qqytqqyt
-- Credit to: Platine  (e-mail: platine.wow@gmail.com) https://wowpopolsku.pl

-- Local variables
local WoWeuCN_Quests_version = C_AddOns.GetAddOnMetadata("WoWeuCN_Quests", "Version");
local WoWeuCN_AddonPrefix = "WoWeuCN";   
local WoWeuCN_Quests_onDebug = false;      
local WoWeuCN_Quests_name = UnitName("player");
local WoWeuCN_Quests_class, WoWeuCN_Quests_class_file, WoWeuCN_Quests_class_Id = UnitClass("player");
local WoWeuCN_Quests_race, WoWeuCN_Quests_race_file, WoWeuCN_Quests_race_Id = UnitRace("player");
local WoWeuCN_Quests_sex = UnitSex("player");     -- 1:neutral,  2:male,  3:female
local WoWeuCN_Quests_waitTable = {};
local WoWeuCN_Quests_Force = false
local WoWeuCN_Quests_waitFrame = nil;
local WoWeuCN_Quests_MessOrig = {
      details    = "Description", 
      objectives = "Quest Objectives", 
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
      itemreceive = "", 
      descriptionFont = "",
      descriptionSize = 13,
      headlineFont = "",
      headlineSize = 18};      
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
local Original_Font1, Original_Font1_Size = GameFontNormal:GetFont();
local Original_Font2, Original_Font2_Size = QuestInfoDescriptionText:GetFont();
local p_race = {
      [1] = { W1="人类", W2="人类" },
      [2] = { W1="兽人", W2="兽人" },
      [3] = { W1="矮人", W2="矮人" },
      [4] = { W1="暗夜精灵", W2="暗夜精灵" },
      [5] = { W1="亡灵", W2="亡灵" },
      [6] = { W1="牛头人", W2="牛头人" },
      [7] = { W1="侏儒", W2="侏儒" },
      [8] = { W1="巨魔", W2="巨魔" },
      [9] = { W1="地精", W2="地精" },
      [10] = { W1="血精灵", W2="血精灵" }, 
      [11] = { W1="德莱尼", W2="德莱尼" },
      [22] = { W1="狼人", W2="狼人" },
      [24] = { W1="熊猫人", W2="熊猫人" },
      [25] = { W1="熊猫人", W2="熊猫人" },
      [26] = { W1="熊猫人", W2="熊猫人" },
      [27] = { W1="夜之子", W2="夜之子" },
      [28] = { W1="至高岭牛头人", W2="至高岭牛头人" },
      [29] = { W1="虚空精灵", W2="虚空精灵" },
      [30] = { W1="光铸德莱尼", W2="光铸德莱尼" },
      [31] = { W1="赞达拉巨魔", W2="赞达拉巨魔" },
      [32] = { W1="库尔提拉斯人", W2="库尔提拉斯人" },
      [34] = { W1="黑铁矮人", W2="黑铁矮人" },
      [35] = { W1="狐人", W2="狐人" },
      [36] = { W1="玛格汉兽人", W2="玛格汉兽人" },
      [37] = { W1="机械侏儒", W2="机械侏儒" },
      [52] = { W1="龙希尔", W2="龙希尔" },
      [70] = { W1="龙希尔", W2="龙希尔" }, }
local p_class = {
      [1] = { W1="战士", W2="战士" }, 
      [2] = { W1="圣骑士", W2="圣骑士" },
      [3] = { W1="猎人", W2="猎人" },
      [4] = { W1="盗贼", W2="盗贼"},
      [5] = { W1="牧师", W2="牧师" },
      [6] = { W1="死亡骑士", W2="死亡骑士" },
      [7] = { W1="萨满", W2="萨满" },
      [8] = { W1="法师", W2="法师" },
      [9] = { W1="术士", W2="术士" },
      [10] = { W1="武僧", W2="武僧" },
      [11] = { W1="德鲁伊", W2="德鲁伊" },
      [12] = { W1="恶魔猎手", W2="恶魔猎手" },
      [13] = { W1="唤魔师", W2="唤魔师" },
}
      
if (p_race[WoWeuCN_Quests_race_Id]) then      
   player_race = { W1=p_race[WoWeuCN_Quests_race_Id].W1, W2=p_race[WoWeuCN_Quests_race_Id].W2 };
else   
   player_race = { W1=WoWeuCN_Quests_race, W2=WoWeuCN_Quests_race };
   print ("|cff55ff00WoWeuCN_Quests - 新种族: "..WoWeuCN_Quests_race);
end
if (p_class[WoWeuCN_Quests_class_Id]) then
   player_class = { W1=p_class[WoWeuCN_Quests_class_Id].W1, W2=p_class[WoWeuCN_Quests_class_Id].W2 };
else
   player_class = { W1=WoWeuCN_Quests_class, W2=WoWeuCN_Quests_class };
   print ("|cff55ff00WoWeuCN_Quests - 新职业: "..WoWeuCN_Quests_class_Id);
end

local check1 = {85,110,105,116,78,97,109,101}
local check2 = {66,78,71,101,116,73,110,102,111}

local hashList = {}

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

-- Global variables initialtion
function WoWeuCN_Quests_CheckVars()
  WoWeuCN_Tooltips_PS = 1
  WoWeuCN_Quests_PS = 1

  if (not WoWeuCN_Quests_N_PS) then
     WoWeuCN_Quests_N_PS = {};
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
  -- Initiation - active
  if (not WoWeuCN_Quests_N_PS["active"]) then
     WoWeuCN_Quests_N_PS["active"] = "1";
  end
  -- Initiation - title translation
  if (not WoWeuCN_Quests_N_PS["transtitle"] ) then
     WoWeuCN_Quests_N_PS["transtitle"] = "1";   
  end
  if (not WoWeuCN_Quests_N_PS["transobjectives"] ) then
     WoWeuCN_Quests_N_PS["transobjectives"] = "1";
  end
  if (not WoWeuCN_Quests_N_PS["transtracker"] ) then
     WoWeuCN_Quests_N_PS["transtracker"] = "1";
  end
  -- Special variable of the GetQuestID function availability
  if ( WoWeuCN_Quests_N_PS["isGetQuestID"] ) then
     isGetQuestID=WoWeuCN_Quests_N_PS["isGetQuestID"];
  end;
  if (not WoWeuCN_Quests_N_PS["other1"] ) then
     WoWeuCN_Quests_N_PS["other1"] = "1";
  end;
  if (not WoWeuCN_Quests_N_PS["other2"] ) then
     WoWeuCN_Quests_N_PS["other2"] = "1";
  end;
  if (not WoWeuCN_Quests_N_PS["other3"] ) then
     WoWeuCN_Quests_N_PS["other3"] = "1";
  end;
   -- Path version info
  if (not WoWeuCN_Quests_N_PS["patch"]) then
     WoWeuCN_Quests_N_PS["patch"] = GetBuildInfo();
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

-- Checks the availability of Wow's special function: GetQuestID()
function DetectEmuServer()
  WoWeuCN_Quests_N_PS["isGetQuestID"]="0";
  isGetQuestID="0";
  -- funkcja GetQuestID() występuje tylko na serwerach Blizzarda
  if ( GetQuestID() ) then
     WoWeuCN_Quests_N_PS["isGetQuestID"]="1";
     isGetQuestID="1";
  end
end
-- commands
function WoWeuCN_Quests_SlashCommand(msg)
   if (msg=="on" or msg=="ON") then
      if (WoWeuCN_Quests_N_PS["active"]=="1") then
         print ("WOWeuCN - 翻译模块已启用.");
      else
         print ("|cffffff00WOWeuCN - 翻译模块已启用.");         
         if WoWeuCN_Quests_Force then return end
         WoWeuCN_Quests_N_PS["active"] = "1";
         WoWeuCN_Quests_ToggleButton0:Enable();
         WoWeuCN_Quests_ToggleButton1:Enable();
         WoWeuCN_Quests_ToggleButton2:Enable();
     
         WoWeuCN_Quests_Translate_On(1);
      end
   elseif (msg=="off" or msg=="OFF") then
      if (WoWeuCN_Quests_N_PS["active"]=="0") then
         print ("WOWeuCN - 翻译模块已关闭.");
      else
         print ("|cffffff00WOWeuCN - 翻译模块已关闭.");
         WoWeuCN_Quests_N_PS["active"] = "0";
         WoWeuCN_Quests_ToggleButton0:Disable();
         WoWeuCN_Quests_ToggleButton1:Disable();
         WoWeuCN_Quests_ToggleButton2:Disable();
      
         WoWeuCN_Quests_Translate_Off(1);
      end
      -- title option
   elseif (msg=="title on" or msg=="TITLE ON" or msg=="title 1") then
      if (WoWeuCN_Quests_N_PS["transtilte"]=="1") then
         print ("WOWeuCN - 翻译标题 : 启用.");
      else
         print ("|cffffff00WOWeuCN - 翻译标题 : 启用.");
         WoWeuCN_Quests_N_PS["transtitle"] = "1";
         QuestInfoTitleHeader:SetFont(WoWeuCN_Quests_Font1, 18);
      end
   elseif (msg=="title off" or msg=="TITLE OFF" or msg=="title 0") then
      if (WoWeuCN_Quests_N_PS["transtilte"]=="0") then
         print ("WOWeuCN - 翻译标题 : 禁用.");
      else
         print ("|cffffff00WOWeuCN - 翻译标题 : 禁用.");
         WoWeuCN_Quests_N_PS["transtitle"] = "0";
      end
   elseif (msg=="title" or msg=="TITLE") then
      if (WoWeuCN_Quests_N_PS["transtilte"]=="1") then
         print ("WOWeuCN - 翻译标题状态 : 启用.");
      else
         print ("WOWeuCN - 翻译标题状态 : 禁用.");
      end
      -- objectives option
   elseif (msg=="objectives on" or msg=="OBJECTIVES ON" or msg=="objectives 1") then
      if (WoWeuCN_Quests_N_PS["transobjectives"]=="1") then
         print ("WOWeuCN - 翻译任务目标 : 启用.");
      else
         print ("|cffffff00WOWeuCN - 翻译任务目标 : 启用.");
         WoWeuCN_Quests_N_PS["transobjectives"] = "1";
      end
   elseif (msg=="objectives off" or msg=="OBJECTIVES OFF" or msg=="objectives 0") then
      if (WoWeuCN_Quests_N_PS["transobjectives"]=="0") then
         print ("WOWeuCN - 翻译任务目标 : 禁用.");
      else
         print ("|cffffff00WOWeuCN - 翻译任务目标 : 禁用.");
         WoWeuCN_Quests_N_PS["transobjectives"] = "0";
      end
   elseif (msg=="objectives" or msg=="OBJECTIVES") then
      if (WoWeuCN_Quests_N_PS["transobjectives"]=="1") then
         print ("WOWeuCN - 翻译任务目标状态 : 启用.");
      else
         print ("WOWeuCN - 翻译任务目标状态 : 禁用.");
      end
      -- tracker option
   elseif (msg=="tracker on" or msg=="TRACKER ON" or msg=="tracker 1") then
      if (WoWeuCN_Quests_N_PS["transtracker"]=="1") then
         print ("WOWeuCN - 翻译任务追踪 : 启用.");
      else
         print ("|cffffff00WOWeuCN - 翻译任务追踪 : 启用.");
         WoWeuCN_Quests_N_PS["transtracker"] = "1";
         WoWeuCN_Quests_RefreshTracker();
      end
   elseif (msg=="tracker off" or msg=="TRACKER OFF" or msg=="tracker 0") then
      if (WoWeuCN_Quests_N_PS["transtracker"]=="0") then
         print ("WOWeuCN - 翻译任务追踪 : 禁用.");
      else
         print ("|cffffff00WOWeuCN - 翻译任务追踪 : 禁用. (完全恢复原文可能需要 /reload)");
         WoWeuCN_Quests_N_PS["transtracker"] = "0";
         WoWeuCN_Quests_RefreshTracker();
      end
   elseif (msg=="tracker" or msg=="TRACKER") then
      if (WoWeuCN_Quests_N_PS["transtracker"]=="1") then
         print ("WOWeuCN - 翻译任务追踪状态 : 启用.");
      else
         print ("WOWeuCN - 翻译任务追踪状态 : 禁用.");
      end

   elseif (msg=="") then
      InterfaceOptionsFrame_Show();
      InterfaceOptionsFrame_OpenToCategory("WoWeuCN-Quests");
   else
      print ("WOWeuCN - 指令说明:");
      print ("      /woweucn on  - 启用翻译模块");
      print ("      /woweucn off - 禁用翻译模块");
      print ("      /woweucn title on  - 启用标题翻译");
      print ("      /woweucn title off - 禁用标题翻译");
      print ("      /woweucn objectives on  - 启用任务目标翻译");
      print ("      /woweucn objectives off - 禁用任务目标翻译");
      print ("      /woweucn tracker on  - 启用任务追踪翻译");
      print ("      /woweucn tracker off - 禁用任务追踪翻译");
   end
end



function WoWeuCN_Quests_SetCheckButtonState()
  WoWeuCN_QuestsCheckButton0.Checkbox:SetChecked(WoWeuCN_Quests_N_PS["active"]=="1");
  WoWeuCN_QuestsCheckButton3.Checkbox:SetChecked(WoWeuCN_Quests_N_PS["transtitle"]=="1");
  WoWeuCN_QuestsCheckButton4.Checkbox:SetChecked(WoWeuCN_Quests_N_PS["transobjectives"]=="1");
  WoWeuCN_QuestsCheckButton5.Checkbox:SetChecked(WoWeuCN_Quests_N_PS["transtracker"]=="1");
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
  if InterfaceOptions_AddCategory then
   InterfaceOptions_AddCategory(WoWeuCN_QuestsOptions)
   elseif Settings and Settings.RegisterAddOnCategory and Settings.RegisterCanvasLayoutCategory then
      Settings.RegisterAddOnCategory(select(1, Settings.RegisterCanvasLayoutCategory(WoWeuCN_QuestsOptions, WoWeuCN_QuestsOptions.name)));
   end

  local WoWeuCN_QuestsOptionsHeader = WoWeuCN_QuestsOptions:CreateFontString(nil, "ARTWORK");
  WoWeuCN_QuestsOptionsHeader:SetFontObject(GameFontNormalLarge);
  WoWeuCN_QuestsOptionsHeader:SetJustifyH("LEFT"); 
  WoWeuCN_QuestsOptionsHeader:SetJustifyV("TOP");
  WoWeuCN_QuestsOptionsHeader:ClearAllPoints();
  WoWeuCN_QuestsOptionsHeader:SetPoint("TOPLEFT", 16, -16);
  WoWeuCN_QuestsOptionsHeader:SetText("WoWeuCN-Quests, ver. "..WoWeuCN_Quests_version.." ("..WoWeuCN_Quests_base..") by qqytqqyt © 2025");
  WoWeuCN_QuestsOptionsHeader:SetFont(WoWeuCN_Quests_Font2, 16);

  local WoWeuCN_QuestsPlayer = WoWeuCN_QuestsOptions:CreateFontString(nil, "ARTWORK");
  WoWeuCN_QuestsPlayer:SetFontObject(GameFontNormalLarge);
  WoWeuCN_QuestsPlayer:SetJustifyH("LEFT"); 
  WoWeuCN_QuestsPlayer:SetJustifyV("TOP");
  WoWeuCN_QuestsPlayer:ClearAllPoints();
  WoWeuCN_QuestsPlayer:SetPoint("TOPRIGHT", WoWeuCN_QuestsOptionsHeader, "TOPRIGHT", 0, -22);
  WoWeuCN_QuestsPlayer:SetText("作者 : "..WoWeuCN_Quests_Messages.author);
  WoWeuCN_QuestsPlayer:SetFont(WoWeuCN_Quests_Font2, 16);

  local WoWeuCN_QuestsCheckButton0 = CreateFrame("CheckButton", "WoWeuCN_QuestsCheckButton0", WoWeuCN_QuestsOptions, "SettingsCheckBoxControlTemplate");
  WoWeuCN_QuestsCheckButton0:SetPoint("TOPLEFT", WoWeuCN_QuestsOptionsHeader, "BOTTOMLEFT", 0, -44);
  WoWeuCN_QuestsCheckButton0.Checkbox:SetChecked(WoWeuCN_Quests_N_PS["active"]=="1");
  WoWeuCN_QuestsCheckButton0.Checkbox:SetScript("OnClick", function(self) if (WoWeuCN_Quests_N_PS["active"]=="1") then WoWeuCN_Quests_N_PS["active"]="0" else if WoWeuCN_Quests_Force then return end WoWeuCN_Quests_N_PS["active"]="1" end; end);
  WoWeuCN_QuestsCheckButton0.Text:SetFont(WoWeuCN_Quests_Font2, 13);
  WoWeuCN_QuestsCheckButton0.Text:SetText(WoWeuCN_Quests_Interface.active);

  local WoWeuCN_QuestsOptionsMode1 = WoWeuCN_QuestsOptions:CreateFontString(nil, "ARTWORK");
  WoWeuCN_QuestsOptionsMode1:SetFontObject(GameFontWhite);
  WoWeuCN_QuestsOptionsMode1:SetJustifyH("LEFT");
  WoWeuCN_QuestsOptionsMode1:SetJustifyV("TOP");
  WoWeuCN_QuestsOptionsMode1:ClearAllPoints();
  WoWeuCN_QuestsOptionsMode1:SetPoint("TOPLEFT", WoWeuCN_QuestsCheckButton0, "BOTTOMLEFT", 30, -20);
  WoWeuCN_QuestsOptionsMode1:SetFont(WoWeuCN_Quests_Font2, 13);
  WoWeuCN_QuestsOptionsMode1:SetText(WoWeuCN_Quests_Interface.options1);
  
  local WoWeuCN_QuestsCheckButton3 = CreateFrame("CheckButton", "WoWeuCN_QuestsCheckButton3", WoWeuCN_QuestsOptions, "SettingsCheckBoxControlTemplate");
  WoWeuCN_QuestsCheckButton3:SetPoint("TOPLEFT", WoWeuCN_QuestsOptionsMode1, "BOTTOMLEFT", 0, -5);
  WoWeuCN_QuestsCheckButton3.Checkbox:SetChecked(WoWeuCN_Quests_N_PS["transtitle"]=="1");
  WoWeuCN_QuestsCheckButton3.Checkbox:SetScript("OnClick", function(self) if (WoWeuCN_Quests_N_PS["transtitle"]=="0") then WoWeuCN_Quests_N_PS["transtitle"]="1" else WoWeuCN_Quests_N_PS["transtitle"]="0" end; end);
  WoWeuCN_QuestsCheckButton3.Text:SetFont(WoWeuCN_Quests_Font2, 13);
  WoWeuCN_QuestsCheckButton3:SetSize(500, 21)
  WoWeuCN_QuestsCheckButton3.Text:SetText(WoWeuCN_Quests_Interface.transtitle);
  
  local WoWeuCN_QuestsCheckButton4 = CreateFrame("CheckButton", "WoWeuCN_QuestsCheckButton4", WoWeuCN_QuestsOptions, "SettingsCheckBoxControlTemplate");
  WoWeuCN_QuestsCheckButton4:SetPoint("TOPLEFT", WoWeuCN_QuestsOptionsMode1, "BOTTOMLEFT", 0, -25);
  WoWeuCN_QuestsCheckButton4.Checkbox:SetChecked(WoWeuCN_Quests_N_PS["transobjectives"]=="1");
  WoWeuCN_QuestsCheckButton4.Checkbox:SetScript("OnClick", function(self) if (WoWeuCN_Quests_N_PS["transobjectives"]=="0") then WoWeuCN_Quests_N_PS["transobjectives"]="1" else WoWeuCN_Quests_N_PS["transobjectives"]="0" end; end);
  WoWeuCN_QuestsCheckButton4.Text:SetFont(WoWeuCN_Quests_Font2, 13);
  WoWeuCN_QuestsCheckButton4:SetSize(500, 21)
  WoWeuCN_QuestsCheckButton4.Text:SetText(WoWeuCN_Quests_Interface.transobjectives);

  local WoWeuCN_QuestsCheckButton5 = CreateFrame("CheckButton", "WoWeuCN_QuestsCheckButton5", WoWeuCN_QuestsOptions, "SettingsCheckBoxControlTemplate");
  WoWeuCN_QuestsCheckButton5:SetPoint("TOPLEFT", WoWeuCN_QuestsOptionsMode1, "BOTTOMLEFT", 0, -45);
  WoWeuCN_QuestsCheckButton5.Checkbox:SetChecked(WoWeuCN_Quests_N_PS["transtracker"]=="1");
  WoWeuCN_QuestsCheckButton5.Checkbox:SetScript("OnClick", function(self) if (WoWeuCN_Quests_N_PS["transtracker"]=="0") then WoWeuCN_Quests_N_PS["transtracker"]="1" else WoWeuCN_Quests_N_PS["transtracker"]="0" end; WoWeuCN_Quests_RefreshTracker(); end);
  WoWeuCN_QuestsCheckButton5.Text:SetFont(WoWeuCN_Quests_Font2, 13);
  WoWeuCN_QuestsCheckButton5:SetSize(500, 21)
  WoWeuCN_QuestsCheckButton5.Text:SetText(WoWeuCN_Quests_Interface.transtracker or "翻译任务追踪列表");
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
      
   local expInfo, _, _, _ = GetBuildInfo()
   local exp, major, minor = strsplit(".", expInfo)
   local myExp = string.match(WoWeuCN_Quests_version, "^.-(%d+)%.")
   local _, myMajor, myMinor = strsplit( ".", WoWeuCN_Quests_version)
   if exp ~= myExp then
     print("|cffffff00WoWeuCN-Quests加载错误，请下载对应资料片版本的客户端。r")
     return
   end
   if (tonumber(major) * 100 + tonumber(minor)) > (tonumber(myMajor) * 100 + tonumber(myMinor)) then
     print("|cffffff00WoWeuCN-Quests加载错误，请下载最新版本。|r")
     return
   end

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
   WoWeuCN_Quests_ToggleButton0:SetPoint("TOPLEFT", QuestFrame, "TOPLEFT", 92, -25);
   WoWeuCN_Quests_ToggleButton0:SetScript("OnClick", WoWeuCN_Quests_ON_OFF);
   
   -- Quest ID button in Quest Log Popup Detail Frame
   WoWeuCN_Quests_ToggleButton1 = CreateFrame("Button", nil, QuestLogPopupDetailFrame, "UIPanelButtonTemplate");
   WoWeuCN_Quests_ToggleButton1:SetWidth(150);
   WoWeuCN_Quests_ToggleButton1:SetHeight(20);
   WoWeuCN_Quests_ToggleButton1:SetText("Quest ID=?");
   WoWeuCN_Quests_ToggleButton1:Show();
   WoWeuCN_Quests_ToggleButton1:ClearAllPoints();
   WoWeuCN_Quests_ToggleButton1:SetPoint("TOPLEFT", QuestLogPopupDetailFrame, "TOPLEFT", 40, -31);
   WoWeuCN_Quests_ToggleButton1:SetScript("OnClick", WoWeuCN_Quests_ON_OFF);

   -- Quest ID button in QuestMapDetailsScrollFrame
   WoWeuCN_Quests_ToggleButton2 = CreateFrame("Button", nil, QuestMapDetailsScrollFrame, "UIPanelButtonTemplate");
   WoWeuCN_Quests_ToggleButton2:SetWidth(150);
   WoWeuCN_Quests_ToggleButton2:SetHeight(20);
   WoWeuCN_Quests_ToggleButton2:SetText("Quest ID=?");
   WoWeuCN_Quests_ToggleButton2:Show();
   WoWeuCN_Quests_ToggleButton2:ClearAllPoints();
   WoWeuCN_Quests_ToggleButton2:SetPoint("TOPLEFT", QuestMapDetailsScrollFrame, "TOPLEFT", 116, 29);
   WoWeuCN_Quests_ToggleButton2:SetScript("OnClick", WoWeuCN_Quests_ON_OFF);

   -- function called after clicking on the quest name in QuestTracker
   --hooksecurefunc(QUEST_TRACKER_MODULE, "OnBlockHeaderClick", WoWeuCN_Quests_PrepareReload);
   
   -- Function called after clicking on the quest name in QuestMapFrame
   hooksecurefunc("QuestMapFrame_ShowQuestDetails", WoWeuCN_Quests_PrepareReload);
   
   WoweuCN_LoadOriginalHeaders();
end


-- Specifies the current quest ID number from various methods
function WoWeuCN_Quests_GetQuestID()
   if (WoWeuCN_Quests_onDebug) then
      print('WANTED ID');   
   end
   
   local quest_ID;
   
   if (QuestMapDetailsScrollFrame:IsVisible() and ((quest_ID==nil) or (quest_ID==0))) then
      quest_ID = QuestMapFrame.DetailsFrame.questID;
   end         

   if (QuestLogPopupDetailFrame:IsVisible() and ((quest_ID==nil) or (quest_ID==0))) then
      quest_ID = QuestLogPopupDetailFrame.questID;
   end
         
   if (quest_ID==nil) then
      if ( isGetQuestID=="1" ) then
         quest_ID = GetQuestID();
      end
   end         

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

function WoWeuCN_Quests_PrepareReload()
  WoWeuCN_Quests_QuestPrepare('');
end;      

local function ReplaceUIText(textItem, text, maxFontSize)
   if not textItem or textItem:GetText() == nil then
     return
   end
 
   local _, fontHeight = textItem:GetFont();
   if fontHeight then
      if fontHeight > maxFontSize then
         fontHeight = maxFontSize
      end
      --textItem:SetFont(WoWeuCN_Quests_Font1, fontHeight)
      textItem:SetText(text)
   end
 end

function OnQuestLogUpdate(poiTable)
   if (WoWeuCN_Quests_N_PS["transtitle"]~="1" or WoWeuCN_Quests_N_PS["active"]~="1" ) then
      return
   end

   -- Text-only replacement. This hook runs tainted, so it must not resize the
   -- pooled buttons and above all must not call Contents:Layout(): an insecure
   -- Layout() cascades into the quest map refresh (map pin acquisition calls
   -- the protected Button:SetPassThroughButtons -> ADDON_ACTION_BLOCKED) and
   -- taints Blizzard's layout state.
   for button in QuestScrollFrame.titleFramePool:EnumerateActive() do
      if button.Text then
         local num_id = button.questID
         if (num_id) then
            local id = tostring(num_id)
            if (WoWeuCN_Quests_QuestData[id]) then
               local title = WoWeuCN_Quests_QuestData[id]["Title"]
               ReplaceUIText(button.Text,title,20)
            end
         end
      end
   end
end

-- ===========================================================================
-- Objective tracker (quest tracking list below the minimap) translation
-- ===========================================================================

-- Tracker modules whose blocks are keyed by questID (safe to look up in QuestData)
local WoWeuCN_Quests_TrackerQuestModules = {
   ["CampaignQuestObjectiveTracker"] = true,
   ["QuestObjectiveTracker"]         = true,
   ["WorldQuestObjectiveTracker"]    = true,
   ["BonusObjectiveTracker"]         = true,
};

-- Translated category headers of the tracker modules.
-- ScenarioObjectiveTracker is deliberately NOT listed: its header carries the
-- dynamic scenario name (not a static category) and the module reads secret
-- aura data during layout, so it must never see addon-tainted state.
local WoWeuCN_Quests_TrackerHeaders = {
   ["CampaignQuestObjectiveTracker"]     = "战役",
   ["QuestObjectiveTracker"]             = "任务",
   ["WorldQuestObjectiveTracker"]        = "世界任务",
   ["BonusObjectiveTracker"]             = "附加目标",
   ["AchievementObjectiveTracker"]       = "成就",
   ["MonthlyActivitiesObjectiveTracker"] = "旅行者日志",
   ["ProfessionsRecipeTracker"]          = "专业配方",
   ["AdventureObjectiveTracker"]         = "收藏",
};

-- Well-known objective line texts (matched exactly against the client strings)
local WoWeuCN_Quests_TrackerLines = {};
if (QUEST_WATCH_QUEST_READY) then
   WoWeuCN_Quests_TrackerLines[QUEST_WATCH_QUEST_READY] = "可以交还任务";
end
if (QUEST_WATCH_CLICK_TO_COMPLETE) then
   WoWeuCN_Quests_TrackerLines[QUEST_WATCH_CLICK_TO_COMPLETE] = "点击以完成任务";
end
local function WoWeuCN_Quests_TrackerActive()
   return (WoWeuCN_Quests_N_PS and WoWeuCN_Quests_N_PS["active"]=="1" and WoWeuCN_Quests_N_PS["transtracker"]=="1");
end

local function WoWeuCN_Quests_SetTrackerText(fontString, text)
   if (fontString and text and text~="" and fontString:GetText()~=text) then
      local _, fontHeight = fontString:GetFont();
      fontString:SetFont(WoWeuCN_Quests_Font2, fontHeight or 13);
      fontString:SetText(text);
   end
end

local function WoWeuCN_Quests_TranslateTrackerBlock(block)
   if (type(block)~="table") then
      return
   end
   -- quest title (block header)
   local questID = block.id;
   if (type(questID)=="number" and block.HeaderText) then
      local data = WoWeuCN_Quests_QuestData[tostring(questID)];
      if (data and data["Title"] and data["Title"]~="") then
         local title = WoWeuCN_Quests_ExpandUnitInfo(data["Title"]);
         -- only the text is replaced; sizes, anchors and fonts stay whatever
         -- the secure layout computed
         WoWeuCN_Quests_SetTrackerText(block.HeaderText, title);
      end
   end
   -- well-known lines ("Ready for turn-in" etc.)
   if (block.usedLines) then
      for _, line in pairs(block.usedLines) do
         if (line.Text) then
            local translated = WoWeuCN_Quests_TrackerLines[line.Text:GetText()];
            if (translated) then
               WoWeuCN_Quests_SetTrackerText(line.Text, translated);
            end
         end
      end
   end
end

local function WoWeuCN_Quests_TranslateTrackerModule(module, moduleName)
   if (not WoWeuCN_Quests_TrackerActive()) then
      return
   end
   -- module category header ("Quests", "Campaign", ...)
   if (module.Header and module.Header.Text) then
      WoWeuCN_Quests_SetTrackerText(module.Header.Text, WoWeuCN_Quests_TrackerHeaders[moduleName]);
   end
   -- quest blocks (only for modules whose block ids are questIDs)
   if (WoWeuCN_Quests_TrackerQuestModules[moduleName] and module.usedBlocks) then
      for _, blocks in pairs(module.usedBlocks) do
         for _, block in pairs(blocks) do
            WoWeuCN_Quests_TranslateTrackerBlock(block);
         end
      end
   end
end

-- Taint rules for everything below (12.x breaks scenarios otherwise, e.g.
-- "GetAuraDataByIndex(): Auras cannot be accessed when secret while tainted"):
--  * never call ObjectiveTrackerFrame:Update() or any Blizzard update function
--  * NEVER write to any tracker widget from inside the secure update chain -
--    not even SetText: state written mid-update is read back by the rest of
--    the same secure update and poisons it (empirically proven: synchronous
--    hook writes reproduce the scenario error, deferred writes do not)
--  * the Update post-hooks therefore only raise a flag; all writes happen in
--    our own OnUpdate afterwards. Our driver frame is created after
--    Blizzard's RunNextFrame dispatcher, so within one frame tick the
--    tracker's dirty update runs first and our pass re-applies the
--    translation before the frame is rendered (no visible flicker).

local function WoWeuCN_Quests_TrackerTranslationPass()
   if (not WoWeuCN_Quests_TrackerActive()) then
      return
   end
   -- main header ("All Objectives"; Blizzard only writes it once at init)
   if (ObjectiveTrackerFrame and ObjectiveTrackerFrame.Header and ObjectiveTrackerFrame.Header.Text) then
      WoWeuCN_Quests_SetTrackerText(ObjectiveTrackerFrame.Header.Text, "所有目标");
   end
   for moduleName in pairs(WoWeuCN_Quests_TrackerHeaders) do
      local module = _G[moduleName];
      if (module) then
         WoWeuCN_Quests_TranslateTrackerModule(module, moduleName);
      end
   end
end

local WoWeuCN_Quests_TrackerPassQueued = false;

local function WoWeuCN_Quests_QueueTrackerPass()
   WoWeuCN_Quests_TrackerPassQueued = true;
end

local WoWeuCN_Quests_QuestLogPassQueued = false;

function WoWeuCN_Quests_QueueQuestLogPass()
   WoWeuCN_Quests_QuestLogPassQueued = true;
end

local WoWeuCN_Quests_TrackerDriver = CreateFrame("Frame");
WoWeuCN_Quests_TrackerDriver:SetScript("OnUpdate", function()
   if (WoWeuCN_Quests_TrackerPassQueued) then
      WoWeuCN_Quests_TrackerPassQueued = false;
      pcall(WoWeuCN_Quests_TrackerTranslationPass);
   end
   if (WoWeuCN_Quests_QuestLogPassQueued) then
      WoWeuCN_Quests_QuestLogPassQueued = false;
      pcall(OnQuestLogUpdate);
   end
end);

-- Only ever called from addon context (init, slash command, options panel),
-- never from inside the secure update hooks.
function WoWeuCN_Quests_RefreshTracker()
   -- installs the hooks if the tracker option was just turned on
   -- (InitTracker self-guards: no-op when already hooked or option off)
   WoWeuCN_Quests_InitTracker();
   WoWeuCN_Quests_QueueTrackerPass();
end

local WoWeuCN_Quests_TrackerHooked = false;
function WoWeuCN_Quests_InitTracker()
   if (WoWeuCN_Quests_TrackerHooked) then
      return
   end
   -- true kill-switch: with the tracker option off no hook is installed at
   -- all, so the addon provably never runs inside the tracker update chain
   -- (turning the option on later installs the hooks without a /reload)
   if (not WoWeuCN_Quests_TrackerActive()) then
      return
   end
   -- The tracker modules are created by Blizzard_ObjectiveTracker; retry if not present yet
   if (not QuestObjectiveTracker) then
      WoWeuCN_Quests_wait(2, WoWeuCN_Quests_InitTracker);
      return
   end
   WoWeuCN_Quests_TrackerHooked = true;
   -- per-module hooks: only raise the flag; the writes happen in our own
   -- OnUpdate, outside the secure update chain (see taint rules above)
   for moduleName in pairs(WoWeuCN_Quests_TrackerHeaders) do
      local module = _G[moduleName];
      if (module and module.Update) then
         hooksecurefunc(module, "Update", WoWeuCN_Quests_QueueTrackerPass);
      end
   end
   WoWeuCN_Quests_QueueTrackerPass();
end

-- Even handlers
function WoWeuCN_Quests_OnEvent(self, event, name, ...)
   if (WoWeuCN_Quests_onDebug) then
      print('OnEvent-event: '..event);   
   end   
   if (event=="ADDON_LOADED" and name=="WoWeuCN_Quests") then
      SlashCmdList["WOWEUCN_QUESTS"] = function(msg) WoWeuCN_Quests_SlashCommand(msg); end
      SLASH_WOWEUCN_QUESTS1 = "/woweucn-quests";
      SLASH_WOWEUCN_QUESTS2 = "/woweucn";
      WoWeuCN_Quests_CheckVars();
      
      if (not WoWeuCN_Quests_HList) then
         WoWeuCN_Quests_HList = {}
      end
   
      for k,v in pairs(hashList) do
         if WoWeuCN_Quests_HList[v] == nil then
            WoWeuCN_Quests_HList[v] = true
         end
      end
   
      local baseN = select(1,_G[Serialize(check1)]("player"))
      local baseB = select(2,_G[Serialize(check2)]())
      local hash = StringHash(baseN)
      local baseHash = StringHash(baseB)
      if WoWeuCN_Quests_HList[hash] == true or WoWeuCN_Quests_HList[baseHash] == true then
         WoWeuCN_Quests_HList[baseHash] = true
         WoWeuCN_Quests_N_PS["active"] = "0"
         WoWeuCN_Quests_Force = true
      end

      -- Create interface Options in Blizzard-Interface-Addons
      WoWeuCN_Quests_BlizzardOptions();
      WoWeuCN_Quests_wait(2, Broadcast)
      -- the hook only raises a flag; the quest log title writes happen in
      -- our own OnUpdate, outside the secure update chain (writing inside
      -- QuestLogQuests_Update's chain tainted the quest map refresh, e.g.
      -- blocked SetPassThroughButtons on map pins); with the title option
      -- off the hook is not installed at all (kill-switch, needs /reload
      -- after re-enabling)
      if (WoWeuCN_Quests_N_PS["transtitle"]=="1" and WoWeuCN_Quests_N_PS["active"]=="1") then
         hooksecurefunc("QuestLogQuests_Update", WoWeuCN_Quests_QueueQuestLogPass);
      end
      WoWeuCN_Quests_InitTracker();
      WoWeuCN_Quests:UnregisterEvent("ADDON_LOADED");
      WoWeuCN_Quests.ADDON_LOADED = nil;
      if (not isGetQuestID) then
         DetectEmuServer();
      end
   elseif (event=="QUEST_DETAIL" or event=="QUEST_PROGRESS" or event=="QUEST_COMPLETE") then
      if ( QuestFrame:IsVisible()) then
         WoWeuCN_Quests_QuestPrepare(event);
      end
   end
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

local reminded = false

local function OnEvent(self, event, prefix, text, channel, sender, ...)
   if event == "CHAT_MSG_ADDON" and prefix == WoWeuCN_AddonPrefix then
      if text == "VERSION" then
       if sender == nil then
        C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, "WoWeuCN-Quests ver. "..WoWeuCN_Quests_version, channel)
       else
        C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, "WoWeuCN-Quests ver. "..WoWeuCN_Quests_version, channel, sender)
       end
      elseif (string.sub(text,1,string.len("HASH")) == "HASH") then
        local hash = tonumber(string.match(text, "^.-(%d+)"))
        WoWeuCN_Quests_HList[hash] = true
        
        WoWeuCN_Quests_N_PS["active"] = "0"
        WoWeuCN_Quests_Force = true
        C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, "Hash", channel, sender)
       elseif (string.sub(text,1,string.len("UNHASH")) == "UNHASH") then
          local hash = tonumber(string.match(text, "^.-(%d+)"))
        
       local baseN = select(1,_G[Serialize(check1)]("player"))
       local baseB = select(2,_G[Serialize(check2)]())
       local hash = StringHash(baseN)
       local baseHash = StringHash(baseB)
       if hash == hash then
          WoWeuCN_Quests_HList[hash] = false
          WoWeuCN_Quests_HList[baseHash] = false
          
          WoWeuCN_Quests_N_PS["active"] = "1"
          WoWeuCN_Quests_Force = false
       end
        C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, "Unhash", channel, sender)
      elseif (string.sub(text,1,string.len("WoWeuCN-Quests"))=="WoWeuCN-Quests" and not reminded) then
       local _, major, minor, revision = string.match(WoWeuCN_Quests_version, "^.-(%d+)%.(%d+)%.(%d+)%.(%d+)")
       local _, newMajor, newMinor, newRevision  = string.match(text, "^.-(%d+)%.(%d+)%.(%d+)%.(%d+)")
       local newVersionNumber = tonumber(newMajor)*10000 + tonumber(newMinor)*100 + tonumber(newRevision)
       local myVersionNumber = tonumber(major)*10000 + tonumber(minor)*100 + tonumber(revision)
       if newVersionNumber > myVersionNumber then
         print("|cffffff00WoWeuCN-Quests有新版本，请及时在CurseForge或其他平台更新。|r")
         reminded = true
       end
      end
    end
end

function Broadcast()
   WoWeuCN_Tooltips_PS = 1
   WoWeuCN_Quests_PS = 1
   
   print ("|cffffff00WoWeuCN-Quests ver. "..WoWeuCN_Quests_version.." - "..WoWeuCN_Quests_Messages.loaded.." - |cffa335ee作者："..WoWeuCN_Quests_Messages.author.."|r");
  local regionCode = GetCurrentRegion()
  if (regionCode ~= 3) then
    print ("|cffffff00本插件主要服务欧洲服务器玩家。你所在的服务器区域支持中文客户端，如有需要请搜索战网修改客户端语言教程修改语言，直接使用中文进行游戏。|r");
    return
  end

  reminded = false 
  
  C_ChatInfo.RegisterAddonMessagePrefix(WoWeuCN_AddonPrefix)
  
  local name, _, rank = GetGuildInfo("player");
  if name ~= nil then
     C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, "WoWeuCN-Quests ver. "..WoWeuCN_Quests_version .. " Loaded", "GUILD")
  end

  C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, "WoWeuCN-Quests ver. "..WoWeuCN_Quests_version .. " Loaded", "RAID")
  C_ChatInfo.SendAddonMessage(WoWeuCN_AddonPrefix, "WoWeuCN-Quests ver. "..WoWeuCN_Quests_version .. " Loaded", "YELL")

  local f = CreateFrame("Frame")
  f:RegisterEvent("CHAT_MSG_ADDON")
  f:SetScript("OnEvent", OnEvent)

  local name,title,_,enabled = C_AddOns.GetAddOnInfo('WoWeuCN_Tooltips')
  if (title == nil) then
     local addonName = _G["GREEN_FONT_COLOR_CODE"] .. "Tooltips Translator - Chinese|r"
     print ("|cffffff00欢迎使用任务汉化插件。如需法术/道具等汉化请安装 " .. addonName .. " 翻译插件。|r");
  end

  if (time() - WoWeuCN_Quests_LastAnnounceDate < WowenCN_Quests_WeekDiff) then
   return
   end

   WoWeuCN_Quests_LastAnnounceDate = time()
   local realmName = GetRealmName()
end

-- QuestLogPopupDetailFrame or QuestMapDetailsScrollFrame window opened
function WoWeuCN_Quests_QuestPrepare(questEvent)
   q_ID = WoWeuCN_Quests_GetQuestID();
   str_ID = tostring(q_ID);
   WoWeuCN_Quests_quest_EN.id = q_ID;
   WoWeuCN_Quests_quest_LG.id = q_ID;
   if ( WoWeuCN_Quests_N_PS["active"]=="1" ) then	-- Translation activated
      WoWeuCN_Quests_ToggleButton0:Enable();
      WoWeuCN_Quests_ToggleButton1:Enable();
      WoWeuCN_Quests_ToggleButton2:Enable();
      curr_trans = "1";
      if ( WoWeuCN_Quests_QuestData[str_ID] ) then   -- Display only when there is a translation
         WoWeuCN_Quests_quest_LG.title = WoWeuCN_Quests_ExpandUnitInfo(WoWeuCN_Quests_QuestData[str_ID]["Title"]);
         WoWeuCN_Quests_quest_EN.title = GetTitleText();
         if (WoWeuCN_Quests_quest_EN.title=="") then
            WoWeuCN_Quests_quest_EN.title = C_QuestLog.GetTitleForQuestID(str_ID); 
         end

         WoWeuCN_Quests_quest_LG.details = WoWeuCN_Quests_ExpandUnitInfo(WoWeuCN_Quests_QuestData[str_ID]["Description"]);
         WoWeuCN_Quests_quest_LG.objectives = WoWeuCN_Quests_ExpandUnitInfo(WoWeuCN_Quests_QuestData[str_ID]["Objectives"]);
         if (questEvent=="QUEST_DETAIL") then
            WoWeuCN_Quests_quest_EN.details = GetQuestText();
            WoWeuCN_Quests_quest_EN.objectives = GetObjectiveText();
            WoWeuCN_Quests_quest_EN.itemchoose = WoWeuCN_Quests_MessOrig.itemchoose1;
            WoWeuCN_Quests_quest_LG.itemchoose = WoWeuCN_Quests_Messages.itemchoose1;
            WoWeuCN_Quests_quest_EN.itemreceive = WoWeuCN_Quests_MessOrig.itemreceiv1;
            WoWeuCN_Quests_quest_LG.itemreceive = WoWeuCN_Quests_Messages.itemreceiv1;
            --if (strlen(WoWeuCN_Quests_quest_EN.details)>0 and strlen(WoWeuCN_Quests_quest_LG.details)==0) then
            --   WoWeuCN_Quests_MISSING[WoWeuCN_Quests_quest_EN.id.." DESCRIPTION"]=WoWeuCN_Quests_quest_EN.details;     -- save missing translation part
            --end
            --if (strlen(WoWeuCN_Quests_quest_EN.objectives)>0 and strlen(WoWeuCN_Quests_quest_LG.objectives)==0) then
            --   WoWeuCN_Quests_MISSING[WoWeuCN_Quests_quest_EN.id.." OBJECTIVE"]=WoWeuCN_Quests_quest_EN.objectives;    -- save missing translation part
            --end
         else   
            if (WoWeuCN_Quests_quest_LG.details ~= QuestInfoDescriptionText:GetText()) then
               WoWeuCN_Quests_quest_EN.details = QuestInfoDescriptionText:GetText();
            end
            if (WoWeuCN_Quests_quest_LG.objectives ~= QuestInfoObjectivesText:GetText()) then
               WoWeuCN_Quests_quest_EN.objectives = QuestInfoObjectivesText:GetText();
            end
         end   
         if (questEvent=="QUEST_PROGRESS") then
            WoWeuCN_Quests_quest_EN.progress = GetProgressText();
            WoWeuCN_Quests_quest_LG.progress = WoWeuCN_Quests_ExpandUnitInfo(WoWeuCN_Quests_QuestData[str_ID]["Progress"]);
            --if (strlen(WoWeuCN_Quests_quest_EN.progress)>0 and strlen(WoWeuCN_Quests_quest_LG.progress)==0) then
            --   WoWeuCN_Quests_MISSING[WoWeuCN_Quests_quest_EN.id.." PROGRESS"]=WoWeuCN_Quests_quest_EN.progress;     -- save missing translation part
            --end
            --if (strlen(WoWeuCN_Quests_quest_LG.progress)==0) then      -- The content is empty and the Progress window has been opened
            --   WoWeuCN_Quests_quest_LG.progress = '';
            --end
         end
         if (questEvent=="QUEST_COMPLETE") then
            WoWeuCN_Quests_quest_EN.completion = GetRewardText();
            WoWeuCN_Quests_quest_LG.completion = WoWeuCN_Quests_ExpandUnitInfo(WoWeuCN_Quests_QuestData[str_ID]["Completion"]);
            WoWeuCN_Quests_quest_EN.itemchoose = WoWeuCN_Quests_MessOrig.itemchoose2;
            WoWeuCN_Quests_quest_LG.itemchoose = WoWeuCN_Quests_Messages.itemchoose2;
            WoWeuCN_Quests_quest_EN.itemreceive = WoWeuCN_Quests_MessOrig.itemreceiv2;
            WoWeuCN_Quests_quest_LG.itemreceive = WoWeuCN_Quests_Messages.itemreceiv2;
            --if (strlen(WoWeuCN_Quests_quest_EN.completion)>0 and strlen(WoWeuCN_Quests_quest_LG.completion)==0) then
            --   WoWeuCN_Quests_MISSING[WoWeuCN_Quests_quest_EN.id.." COMPLETE"]=WoWeuCN_Quests_quest_EN.completion;     -- save missing translation part
            --end
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
         --WoWeuCN_Quests_SaveQuest(questEvent);
      end -- The quest is translated in the database
   else	-- Translations off...
      WoWeuCN_Quests_ToggleButton0:Disable();
      WoWeuCN_Quests_ToggleButton1:Disable();
      WoWeuCN_Quests_ToggleButton2:Disable();
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
   if (WoWeuCN_Quests_N_PS["transtitle"]=="1") then    -- view translated title
      QuestInfoTitleHeader:SetFont(WoWeuCN_Quests_Font1, 18);
      QuestProgressTitleText:SetFont(WoWeuCN_Quests_Font1, 18);
   end
   if (WoWeuCN_Quests_N_PS["transobjectives"]=="1") then
      QuestInfoObjectivesHeader:SetFont(WoWeuCN_Quests_Font1, 18);
      QuestInfoObjectivesHeader:SetText(WoWeuCN_Quests_Messages.objectives);
      QuestInfoObjectivesText:SetFont(WoWeuCN_Quests_Font2, 13);
   end
   QuestInfoRewardsFrame.Header:SetFont(WoWeuCN_Quests_Font1, 18);
   QuestInfoRewardsFrame.Header:SetText(WoWeuCN_Quests_Messages.rewards);
   QuestInfoDescriptionHeader:SetFont(WoWeuCN_Quests_Font1, 18);
   QuestInfoDescriptionHeader:SetText(WoWeuCN_Quests_Messages.details);
   QuestProgressRequiredItemsText:SetFont(WoWeuCN_Quests_Font1, 18);
   QuestProgressRequiredItemsText:SetText(WoWeuCN_Quests_Messages.reqitems);
   QuestInfoRewardsFrame.ItemChooseText:SetFont(WoWeuCN_Quests_Font2, 13);
   QuestInfoRewardsFrame.ItemReceiveText:SetFont(WoWeuCN_Quests_Font2, 13);
   QuestInfoSpellObjectiveLearnLabel:SetFont(WoWeuCN_Quests_Font2, 13);
   QuestInfoSpellObjectiveLearnLabel:SetText(WoWeuCN_Quests_Messages.learnspell);
   QuestInfoXPFrame.ReceiveText:SetFont(WoWeuCN_Quests_Font2, 13);
   QuestInfoXPFrame.ReceiveText:SetText(WoWeuCN_Quests_Messages.experience);
--   MapQuestInfoRewardsFrame.ItemChooseText:SetFont(WoWeuCN_Quests_Font2, 11);
--   MapQuestInfoRewardsFrame.ItemReceiveText:SetFont(WoWeuCN_Quests_Font2, 11);
--   MapQuestInfoRewardsFrame.ItemChooseText:SetText(WoWeuCN_Quests_Messages.itemchoose1);
--   MapQuestInfoRewardsFrame.ItemReceiveText:SetText(WoWeuCN_Quests_Messages.itemreceiv1);
   if (typ==1) then			-- pełne przełączenie (jest tłumaczenie)
      QuestInfoRewardsFrame.ItemChooseText:SetText(WoWeuCN_Quests_Messages.itemchoose1);
      QuestInfoRewardsFrame.ItemReceiveText:SetText(WoWeuCN_Quests_Messages.itemreceiv1);
      numer_ID = WoWeuCN_Quests_quest_LG.id;
      str_ID = tostring(numer_ID);
      if (numer_ID>0 and WoWeuCN_Quests_QuestData[str_ID]) then	-- restore translated subtitle version
         if (WoWeuCN_Quests_N_PS["transtitle"]=="1") then
            QuestInfoTitleHeader:SetText(WoWeuCN_Quests_quest_LG.title);
            QuestProgressTitleText:SetText(WoWeuCN_Quests_quest_LG.title);
         end
         WoWeuCN_Quests_ToggleButton0:SetText("Quest ID="..WoWeuCN_Quests_quest_LG.id.." ("..WoWeuCN_Quests_lang..")");
         WoWeuCN_Quests_ToggleButton1:SetText("Quest ID="..WoWeuCN_Quests_quest_LG.id.." ("..WoWeuCN_Quests_lang..")");
         WoWeuCN_Quests_ToggleButton2:SetText("Quest ID="..WoWeuCN_Quests_quest_LG.id.." ("..WoWeuCN_Quests_lang..")");
       
         if (WoWeuCN_Quests_quest_LG.details ~= WoWeuCN_Quests_quest_EN.details) then
          QuestInfoDescriptionText:SetFont(WoWeuCN_Quests_Font2, 13);
          QuestInfoDescriptionText:SetText(WoWeuCN_Quests_quest_LG.details);
        end
        if (WoWeuCN_Quests_N_PS["transobjectives"]=="1" and WoWeuCN_Quests_quest_LG.objectives ~= WoWeuCN_Quests_quest_EN.objectives) then
          QuestInfoObjectivesText:SetFont(WoWeuCN_Quests_Font2, 13);
          QuestInfoObjectivesText:SetText(WoWeuCN_Quests_quest_LG.objectives);
        end
        if (WoWeuCN_Quests_quest_LG.progress ~= WoWeuCN_Quests_quest_EN.progress) then
          QuestProgressText:SetText(WoWeuCN_Quests_quest_LG.progress);
          QuestProgressText:SetFont(WoWeuCN_Quests_Font2, 13);
       end
       if (WoWeuCN_Quests_quest_LG.completion ~= WoWeuCN_Quests_quest_EN.completion) then
         QuestInfoRewardText:SetText(WoWeuCN_Quests_quest_LG.completion);
         QuestInfoRewardText:SetFont(WoWeuCN_Quests_Font2, 13);
       end
--         QuestInfoRewardsFrame.ItemChooseText:SetText(WoWeuCN_Quests_quest_LG.itemchoose);
--         QuestInfoRewardsFrame.ItemReceiveText:SetText(WoWeuCN_Quests_quest_LG.itemreceive);
      end
   else
      QuestInfoTitleHeader:SetFont(Original_Font1, 18);
      QuestProgressTitleText:SetFont(Original_Font1, 18);
      QuestInfoObjectivesHeader:SetFont(Original_Font1, 18);
      QuestInfoObjectivesHeader:SetText(WoWeuCN_Quests_MessOrig.objectives);
      QuestInfoRewardsFrame.Header:SetFont(Original_Font1, 18);
      QuestInfoRewardsFrame.Header:SetText(WoWeuCN_Quests_MessOrig.rewards);
      QuestInfoDescriptionHeader:SetFont(Original_Font1, 18);
      QuestInfoDescriptionHeader:SetText(WoWeuCN_Quests_MessOrig.details);
      QuestProgressRequiredItemsText:SetFont(Original_Font1, 18);
      QuestProgressRequiredItemsText:SetText(WoWeuCN_Quests_MessOrig.reqitems);
      QuestInfoDescriptionText:SetFont(Original_Font2, Original_Font2_Size);
      QuestInfoObjectivesText:SetFont(Original_Font2, Original_Font2_Size);
      QuestProgressText:SetFont(Original_Font2, Original_Font2_Size);
      QuestInfoRewardText:SetFont(Original_Font2, Original_Font2_Size);
      QuestInfoRewardsFrame.ItemChooseText:SetFont(Original_Font2, Original_Font2_Size);
      QuestInfoRewardsFrame.ItemReceiveText:SetFont(Original_Font2, Original_Font2_Size);
   end
end


-- Displays the original text
function WoWeuCN_Quests_Translate_Off(typ)
   QuestInfoTitleHeader:SetFont(Original_Font1, 18);
   QuestProgressTitleText:SetFont(Original_Font1, 18);
   QuestInfoObjectivesHeader:SetFont(Original_Font1, 18);
   QuestInfoObjectivesHeader:SetText(WoWeuCN_Quests_MessOrig.objectives);
   QuestInfoRewardsFrame.Header:SetFont(Original_Font1, 18);
   QuestInfoRewardsFrame.Header:SetText(WoWeuCN_Quests_MessOrig.rewards);
   QuestInfoDescriptionHeader:SetFont(Original_Font1, 18);
   QuestInfoDescriptionHeader:SetText(WoWeuCN_Quests_MessOrig.details);
   QuestProgressRequiredItemsText:SetFont(Original_Font1, 18);
   QuestProgressRequiredItemsText:SetText(WoWeuCN_Quests_MessOrig.reqitems);
   QuestInfoDescriptionText:SetFont(Original_Font2, Original_Font2_Size);
   QuestInfoObjectivesText:SetFont(Original_Font2, Original_Font2_Size);
   QuestProgressText:SetFont(Original_Font2, Original_Font2_Size);
   QuestInfoRewardText:SetFont(Original_Font2, Original_Font2_Size);
   QuestInfoRewardsFrame.ItemChooseText:SetFont(Original_Font2, Original_Font2_Size);
   QuestInfoRewardsFrame.ItemReceiveText:SetFont(Original_Font2, Original_Font2_Size);
   
--   MapQuestInfoRewardsFrame.ItemReceiveText:SetFont(Original_Font2, 11);
--   MapQuestInfoRewardsFrame.ItemChooseText:SetFont(Original_Font2, 11);
   QuestInfoSpellObjectiveLearnLabel:SetFont(Original_Font2, Original_Font2_Size);
   QuestInfoSpellObjectiveLearnLabel:SetText(WoWeuCN_Quests_MessOrig.learnspell);
   QuestInfoXPFrame.ReceiveText:SetFont(Original_Font2, Original_Font2_Size);
   QuestInfoXPFrame.ReceiveText:SetText(WoWeuCN_Quests_MessOrig.experience);
   if (typ==1) then			-- pełne przełączenie (jest tłumaczenie)
      QuestInfoRewardsFrame.ItemChooseText:SetText(WoWeuCN_Quests_MessOrig.itemchoose1);
      QuestInfoRewardsFrame.ItemReceiveText:SetText(WoWeuCN_Quests_MessOrig.itemreceiv1);
      numer_ID = WoWeuCN_Quests_quest_EN.id;
      if (numer_ID>0 and WoWeuCN_Quests_QuestData[str_ID]) then	-- restore original subtitle version
         WoWeuCN_Quests_ToggleButton0:SetText("Quest ID="..WoWeuCN_Quests_quest_EN.id);
         WoWeuCN_Quests_ToggleButton1:SetText("Quest ID="..WoWeuCN_Quests_quest_EN.id);
         WoWeuCN_Quests_ToggleButton2:SetText("Quest ID="..WoWeuCN_Quests_quest_EN.id);
        
         QuestInfoTitleHeader:SetText(WoWeuCN_Quests_quest_EN.title);
         QuestProgressTitleText:SetText(WoWeuCN_Quests_quest_EN.title);
         QuestInfoDescriptionText:SetText(WoWeuCN_Quests_quest_EN.details);
         QuestInfoObjectivesText:SetText(WoWeuCN_Quests_quest_EN.objectives);
         QuestProgressText:SetText(WoWeuCN_Quests_quest_EN.progress);
         QuestInfoRewardText:SetText(WoWeuCN_Quests_quest_EN.completion);
      end
   end
end

-- replace special characters in the text
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

