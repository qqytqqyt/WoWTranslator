-- Addon: WoWeuCN-Quests
-- Author: qqytqqyt
-- Credit to: Platine  (e-mail: platine.wow@gmail.com) https://wowpopolsku.pl

-- Local variables
local WoWeuCN_Quests_version = GetAddOnMetadata("WoWeuCN_Quests", "Version");
local WoWeuCN_Quests_onDebug = false;      
local WoWeuCN_Quests_name = UnitName("player");
local WoWeuCN_Quests_class, WoWeuCN_Quests_class_file, WoWeuCN_Quests_class_Id = UnitClass("player");
local WoWeuCN_Quests_race, WoWeuCN_Quests_race_file, WoWeuCN_Quests_race_Id = UnitRace("player");
local WoWeuCN_Quests_sex = UnitSex("player");     -- 1:neutral,  2:male,  3:female
local WoWeuCN_Quests_waitTable = {};
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
      [37] = { W1="机械侏儒", W2="机械侏儒" }, }
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
  -- Initiation - active
  if (not WoWeuCN_Quests_PS["active"]) then
     WoWeuCN_Quests_PS["active"] = "1";
  end
  -- Initiation - title translation
  if (not WoWeuCN_Quests_PS["transtitle"] ) then
     WoWeuCN_Quests_PS["transtitle"] = "1";   
  end
  if (not WoWeuCN_Quests_PS["transobjectives"] ) then
     WoWeuCN_Quests_PS["transobjectives"] = "1";   
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
   -- Path version info
  if (not WoWeuCN_Quests_PS["patch"]) then
     WoWeuCN_Quests_PS["patch"] = GetBuildInfo();
  end
  -- Saved variables per character
  if (not WoWeuCN_Quests_PC) then
     WoWeuCN_Quests_PC = {};
  end
end

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
  if (startIndex > 80000) then
    return;
  end
  for i = startIndex, startIndex + 100 do
    qcQuestInformationTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    qcQuestInformationTooltip:ClearLines()
    qcQuestInformationTooltip:SetHyperlink('quest:' .. i)
    qcQuestInformationTooltip:Show()
    local text =  EnumerateTooltipLines(qcQuestInformationTooltip)
    if (text ~= '' and text ~= nil) then
      WoWeuCN_Quests_QuestToolTips[i .. ''] = text
      print(i)
    end
  end
  print(attempt)
  print(counter)
  WoWeuCN_Quests_QuestIndex = startIndex
  if (counter >= 10) then
    QTR_wait(0.5, scanAuto, startIndex + 100, attempt + 1, 0)
  else
    QTR_wait(0.5, scanAuto, startIndex, attempt + 1, counter + 1)
  end
end


-- Checks the availability of Wow's special function: GetQuestID()
function DetectEmuServer()
  WoWeuCN_Quests_PS["isGetQuestID"]="0";
  isGetQuestID="0";
  -- funkcja GetQuestID() występuje tylko na serwerach Blizzarda
  if ( GetQuestID() ) then
     WoWeuCN_Quests_PS["isGetQuestID"]="1";
     isGetQuestID="1";
  end
end

-- scann
local function EnumerateTooltipLines_helper(...)
  local texts = '';
  local hasTitleSet = false
  local hasObjectivesSet = false
    for i = 1, select("#", ...) do
      
        local region = select(i, ...)
        --print(region:GetObjectType())
        if region and region:GetObjectType() == "FontString" then
      local text = region:GetText() -- string or nil
      --print(text)
			if (text ~= nil) then
        if (hasTitleSet ~= true and text ~= " ")
          then
            text = "{{" .. text .. "}}"
            hasTitleSet = true
          end

        if (i > 3 and hasObjectivesSet ~= true and text ~= " ")
          then
            text = "{{" .. text .. "}}"
            hasObjectivesSet = true
          end
        print(i)
        print(text)
        texts = texts .. text	
			end
        end
	end
	return texts
end

function EnumerateTooltipLines(tooltip) -- good for script handlers that pass the tooltip as the first argument.
    return EnumerateTooltipLines_helper(tooltip:GetRegions())
end

function qcQuestInformationTooltipSetup() -- *
	qcQuestInformationTooltip = CreateFrame("GameTooltip", "qcQuestInformationTooltip", UIParent, "GameTooltipTemplate")
	qcQuestInformationTooltip:SetFrameStrata("TOOLTIP")
end


-- commands
function WoWeuCN_Quests_SlashCommand(msg)
   if (msg=="on" or msg=="ON") then
      if (WoWeuCN_Quests_PS["active"]=="1") then
         print ("WOWeuCN - 翻译模块已启用.");
      else
         print ("|cffffff00WOWeuCN - 翻译模块已启用.");
         WoWeuCN_Quests_PS["active"] = "1";
         WoWeuCN_Quests_ToggleButton0:Enable();
         WoWeuCN_Quests_ToggleButton1:Enable();
         WoWeuCN_Quests_ToggleButton2:Enable();
     
         WoWeuCN_Quests_Translate_On(1);
      end
   elseif (msg=="off" or msg=="OFF") then
      if (WoWeuCN_Quests_PS["active"]=="0") then
         print ("WOWeuCN - 翻译模块已关闭.");
      else
         print ("|cffffff00WOWeuCN - 翻译模块已关闭.");
         WoWeuCN_Quests_PS["active"] = "0";
         WoWeuCN_Quests_ToggleButton0:Disable();
         WoWeuCN_Quests_ToggleButton1:Disable();
         WoWeuCN_Quests_ToggleButton2:Disable();
      
         WoWeuCN_Quests_Translate_Off(1);
      end
      -- title option
   elseif (msg=="title on" or msg=="TITLE ON" or msg=="title 1") then
      if (WoWeuCN_Quests_PS["transtilte"]=="1") then
         print ("WOWeuCN - 翻译标题 : 启用.");
      else
         print ("|cffffff00WOWeuCN - 翻译标题 : 启用.");
         WoWeuCN_Quests_PS["transtitle"] = "1";
         QuestInfoTitleHeader:SetFont(WoWeuCN_Quests_Font1, 18);
      end
   elseif (msg=="title off" or msg=="TITLE OFF" or msg=="title 0") then
      if (WoWeuCN_Quests_PS["transtilte"]=="0") then
         print ("WOWeuCN - 翻译标题 : 禁用.");
      else
         print ("|cffffff00WOWeuCN - 翻译标题 : 禁用.");
         WoWeuCN_Quests_PS["transtitle"] = "0";
      end
   elseif (msg=="title" or msg=="TITLE") then
      if (WoWeuCN_Quests_PS["transtilte"]=="1") then
         print ("WOWeuCN - 翻译标题状态 : 启用.");
      else
         print ("WOWeuCN - 翻译标题状态 : 禁用.");
      end
      -- objectives option
   elseif (msg=="objectives on" or msg=="OBJECTIVES ON" or msg=="objectives 1") then
      if (WoWeuCN_Quests_PS["transobjectives"]=="1") then
         print ("WOWeuCN - 翻译任务目标 : 启用.");
      else
         print ("|cffffff00WOWeuCN - 翻译任务目标 : 启用.");
         WoWeuCN_Quests_PS["transobjectives"] = "1";
      end
   elseif (msg=="objectives off" or msg=="OBJECTIVES OFF" or msg=="objectives 0") then
      if (WoWeuCN_Quests_PS["transobjectives"]=="0") then
         print ("WOWeuCN - 翻译任务目标 : 禁用.");
      else
         print ("|cffffff00WOWeuCN - 翻译任务目标 : 禁用.");
         WoWeuCN_Quests_PS["transobjectives"] = "0";
      end
   elseif (msg=="objectives" or msg=="OBJECTIVES") then
      if (WoWeuCN_Quests_PS["transobjectives"]=="1") then
         print ("WOWeuCN - 翻译任务目标状态 : 启用.");
      else
         print ("WOWeuCN - 翻译任务目标状态 : 禁用.");
      end

    -- dev scan
    elseif (msg=="back" or msg=="BACK") then
      WoWeuCN_Quests_QuestIndex = WoWeuCN_Quests_QuestIndex - 500;
      print(WoWeuCN_Quests_QuestIndex);
    elseif (msg=="reset" or msg=="RESET") then
      WoWeuCN_Quests_QuestIndex = 1;
      print("Reset");
    elseif (msg=="clear" or msg=="CLEAR") then
      WoWeuCN_Quests_QuestIndex = 1;
      WoWeuCN_Quests_QuestToolTips = {} 
      print("Clear");
   elseif (msg=="scan" or msg=="SCAN") then
      if (WoWeuCN_Quests_QuestToolTips == nil) then
        WoWeuCN_Quests_QuestToolTips = {} 
      end
      if (WoWeuCN_Quests_QuestIndex == nil) then
        WoWeuCN_Quests_QuestIndex = 1
      end
      for i = WoWeuCN_Quests_QuestIndex, WoWeuCN_Quests_QuestIndex + 500 do
        qcQuestInformationTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        qcQuestInformationTooltip:ClearLines()
        qcQuestInformationTooltip:SetHyperlink('quest:' .. i)
        qcQuestInformationTooltip:Show()
        local text =  EnumerateTooltipLines(qcQuestInformationTooltip)
        if (text ~= '' and text ~= nil) then
          WoWeuCN_Quests_QuestToolTips[i .. ''] = text
          print(i)
        end
      end
      WoWeuCN_Quests_QuestIndex = WoWeuCN_Quests_QuestIndex + 500
    elseif (msg=="scanauto" or msg=="SCANAUTO") then
      if (WoWeuCN_Quests_QuestToolTips == nil) then
        WoWeuCN_Quests_QuestToolTips = {} 
      end
      if (WoWeuCN_Quests_QuestIndex == nil) then
        WoWeuCN_Quests_QuestIndex = 1
      end
      QTR_wait(0.1, scanAuto, WoWeuCN_Quests_QuestIndex, 1, 0)

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
   end
end



function WoWeuCN_Quests_SetCheckButtonState()
  WoWeuCN_QuestsCheckButton0:SetChecked(WoWeuCN_Quests_PS["active"]=="1");
  WoWeuCN_QuestsCheckButton3:SetChecked(WoWeuCN_Quests_PS["transtitle"]=="1");
  WoWeuCN_QuestsCheckButton4:SetChecked(WoWeuCN_Quests_PS["transobjectives"]=="1");
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
  WoWeuCN_QuestsOptionsHeader:SetText("WoWeuCN-Quests, ver. "..WoWeuCN_Quests_version.." ("..WoWeuCN_Quests_base..") by qqytqqyt © 2020");
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
  WoWeuCN_QuestsCheckButton4:SetScript("OnClick", function(self) if (WoWeuCN_Quests_PS["transobjectives"]=="0") then WoWeuCN_Quests_PS["transobjectives"]="1" else WoWeuCN_Quests_PS["transobjectives"]="0" end; end);
  WoWeuCN_QuestsCheckButton4Text:SetFont(WoWeuCN_Quests_Font2, 13);
  WoWeuCN_QuestsCheckButton4Text:SetText(WoWeuCN_Quests_Interface.transobjectives);
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
   hooksecurefunc(QUEST_TRACKER_MODULE, "OnBlockHeaderClick", WoWeuCN_Quests_PrepareReload);
   
   -- Function called after clicking on the quest name in QuestMapFrame
   hooksecurefunc("QuestMapFrame_ShowQuestDetails", WoWeuCN_Quests_PrepareReload);
   
   qcQuestInformationTooltipSetup();
   WoweuCN_LoadOriginalHeaders();
end


-- Specifies the current quest ID number from various methods
function WoWeuCN_Quests_GetQuestID()
   if (WoWeuCN_Quests_onDebug) then
      print('WANTED ID');   
   end
   
   quest_ID = QuestMapFrame.DetailsFrame.questID;
   
   if (quest_ID==nil) then
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
      -- Create interface Options in Blizzard-Interface-Addons
      WoWeuCN_Quests_BlizzardOptions();
      QTR_wait(2, Broadcast)
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

function Broadcast()
  print ("|cffffff00WoWeuCN-Quests ver. "..WoWeuCN_Quests_version.." - "..WoWeuCN_Quests_Messages.loaded);
  local regionCode = GetCurrentRegion()
  if (regionCode ~= 3) then
    print ("|cffffff00本插件主要服务欧洲服务器玩家。你所在的服务器区域支持中文客户端，如有需要请搜索战网修改客户端语言教程修改语言，直接使用中文进行游戏。|r");
    return
  end

  if (time() - WoWeuCN_Quests_LastAnnounceDate < WowenCN_Quests_WeekDiff) then
   return
   end

   WoWeuCN_Quests_LastAnnounceDate = time()
   local realmName = GetRealmName()

   local guildInfo = _G["GREEN_FONT_COLOR_CODE"] .. "<Blood Requiem>|r" 
   if (realmName == "Silvermoon") then
      --guildInfo = "\124cff00ff00\124HclubFinder:ClubFinder-1-137354-3391-68978962|h[Blood Requiem]\124h\124r"
   end

   print(_G["ORANGE_FONT_COLOR_CODE"] .. "Silvermoon 联盟公会" .. guildInfo .. _G["ORANGE_FONT_COLOR_CODE"] .. "招收治疗DPS加入我们开荒M团本的团队与大米冲层队伍。同时欢迎休闲玩家来欢乐打大米PVP评级。入会咨询/申请请|r" .. "\124cffffd100\124HclubTicket:wyPXGRUyyb\124h[点击加入社群]\124h\124r" .. _G["ORANGE_FONT_COLOR_CODE"] .. "。|r");
end

-- QuestLogPopupDetailFrame or QuestMapDetailsScrollFrame window opened
function WoWeuCN_Quests_QuestPrepare(questEvent)
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
   if (WoWeuCN_Quests_PS["transtitle"]=="1") then    -- view translated title
      QuestInfoTitleHeader:SetFont(WoWeuCN_Quests_Font1, 18);
      QuestProgressTitleText:SetFont(WoWeuCN_Quests_Font1, 18);
   end
   if (WoWeuCN_Quests_PS["transobjectives"]=="1") then
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
         if (WoWeuCN_Quests_PS["transtitle"]=="1") then
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
        if (WoWeuCN_Quests_PS["transobjectives"]=="1" and WoWeuCN_Quests_quest_LG.objectives ~= WoWeuCN_Quests_quest_EN.objectives) then
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

