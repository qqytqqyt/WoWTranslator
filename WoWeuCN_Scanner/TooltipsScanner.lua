-- wait functions from QTR
local WoWeuCN_Scanner_waitFrame = nil;
local WoWeuCN_Scanner_waitTable = {};

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

local function EnumerateTooltipStyledLines(tooltip) -- good for script handlers that pass the tooltip as the first argument.
  return EnumerateTooltipStyledLines_helper(tooltip:GetRegions())
end

function WoWeuCN_Scanner_ScanClear()
    WoWeuCN_Scanner_SpellToolTips0 = {} 
    WoWeuCN_Scanner_SpellToolTips100000 = {} 
    WoWeuCN_Scanner_SpellToolTips200000 = {} 
    WoWeuCN_Scanner_SpellToolTips300000 = {}    
    WoWeuCN_Scanner_SpellToolTips400000 = {}       
    WoWeuCN_Scanner_SpellToolTips500000 = {}       
    WoWeuCN_Scanner_ItemToolTips0 = {} 
    WoWeuCN_Scanner_ItemToolTips100000 = {} 
    WoWeuCN_Scanner_ItemToolTips200000 = {} 
    WoWeuCN_Scanner_UnitToolTips0 = {} 
    WoWeuCN_Scanner_UnitToolTips100000 = {} 
    WoWeuCN_Scanner_UnitToolTips200000 = {} 
    WoWeuCN_Scanner_Achivements0 = {} 
    WoWeuCN_Scanner_QuestToolTips = {}
    WoWeuCN_Scanner_EncounterSectionData = {}
    WoWeuCN_Scanner_EncounterData = {}
    WoWeuCN_Scanner_Index = 1
    print("Clear");
end

function WoWeuCN_Scanner_ScanInit()  
  if (WoWeuCN_Scanner_SpellToolTips0 == nil) then
  WoWeuCN_Scanner_SpellToolTips0 = {} 
  end
  if (WoWeuCN_Scanner_SpellToolTips100000 == nil) then
  WoWeuCN_Scanner_SpellToolTips100000 = {} 
  end
  if (WoWeuCN_Scanner_SpellToolTips200000 == nil) then
  WoWeuCN_Scanner_SpellToolTips200000 = {} 
  end
  if (WoWeuCN_Scanner_SpellToolTips300000 == nil) then
  WoWeuCN_Scanner_SpellToolTips300000 = {} 
  end
  if (WoWeuCN_Scanner_SpellToolTips400000 == nil) then
  WoWeuCN_Scanner_SpellToolTips400000 = {} 
  end
  if (WoWeuCN_Scanner_SpellToolTips500000 == nil) then
  WoWeuCN_Scanner_SpellToolTips500000 = {} 
  end
  if (WoWeuCN_Scanner_Index == nil) then
  WoWeuCN_Scanner_Index = 1
  end

  if (WoWeuCN_Scanner_UnitToolTips0 == nil) then
  WoWeuCN_Scanner_UnitToolTips0 = {} 
  end
  if (WoWeuCN_Scanner_UnitToolTips100000 == nil) then
  WoWeuCN_Scanner_UnitToolTips100000 = {} 
  end
  if (WoWeuCN_Scanner_UnitToolTips200000 == nil) then
  WoWeuCN_Scanner_UnitToolTips200000 = {} 
  end

  if (WoWeuCN_Scanner_ItemToolTips0 == nil) then
  WoWeuCN_Scanner_ItemToolTips0 = {} 
  end
  if (WoWeuCN_Scanner_ItemToolTips100000 == nil) then
  WoWeuCN_Scanner_ItemToolTips100000 = {} 
  end
  if (WoWeuCN_Scanner_ItemToolTips200000 == nil) then
  WoWeuCN_Scanner_ItemToolTips200000 = {} 
  end
  
  if (WoWeuCN_Scanner_Achivements0 == nil) then
    WoWeuCN_Scanner_Achivements0 = {} 
  end
  if (WoWeuCN_Scanner_QuestToolTips == nil) then
    WoWeuCN_Scanner_QuestToolTips = {} 
  end
  
  if (WoWeuCN_Scanner_EncounterSectionData == nil) then
    WoWeuCN_Scanner_EncounterSectionData = {}
  end
  
  if (WoWeuCN_Scanner_EncounterData == nil) then
    WoWeuCN_Scanner_EncounterData = {}
  end
end

function WoWeuCN_Scanner_ScanIndex(index)
    WoWeuCN_Scanner_Index = tonumber(index);
    print(index)
end

function WoWeuCN_Scanner_wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if (WoWeuCN_Scanner_waitFrame == nil) then
    WoWeuCN_Scanner_waitFrame = CreateFrame("Frame","WoWeuCN_Scanner_waitFrame", UIParent);
    WoWeuCN_Scanner_waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #WoWeuCN_Scanner_waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(WoWeuCN_Scanner_waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(WoWeuCN_Scanner_waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(WoWeuCN_Scanner_waitTable,{delay,func,{...}});
  return true;
end

function WoWeuCN_Scanner_ScanSpellAuto(startIndex, attempt, counter)
  if (startIndex > 500000) then
    return;
  end
  for i = startIndex, startIndex + 150 do
    qcInformationTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    qcInformationTooltip:ClearLines()
    qcInformationTooltip:SetHyperlink('spell:' .. i)
    qcInformationTooltip:Show()
    local text =  EnumerateTooltipStyledLines(qcInformationTooltip)
    if (text ~= '' and text ~= nil) then
      if (i >=0 and i < 100000) then
        if (WoWeuCN_Scanner_SpellToolTips0[i .. ''] == nil or string.len(WoWeuCN_Scanner_SpellToolTips0[i .. '']) < string.len(text)) then
          WoWeuCN_Scanner_SpellToolTips0[i .. ''] = text
        end
      elseif (i >=100000 and i < 200000) then
        if (WoWeuCN_Scanner_SpellToolTips100000[i .. ''] == nil or string.len(WoWeuCN_Scanner_SpellToolTips100000[i .. '']) < string.len(text)) then
          WoWeuCN_Scanner_SpellToolTips100000[i .. ''] = text
        end
      elseif (i >=200000 and i < 300000) then
        if (WoWeuCN_Scanner_SpellToolTips200000[i .. ''] == nil or string.len(WoWeuCN_Scanner_SpellToolTips200000[i .. '']) < string.len(text)) then
          WoWeuCN_Scanner_SpellToolTips200000[i .. ''] = text
        end
      elseif (i >=300000 and i < 400000) then
        if (WoWeuCN_Scanner_SpellToolTips300000[i .. ''] == nil or string.len(WoWeuCN_Scanner_SpellToolTips300000[i .. '']) < string.len(text)) then
          WoWeuCN_Scanner_SpellToolTips300000[i .. ''] = text
        end
      elseif (i >=400000 and i < 500000) then
        if (WoWeuCN_Scanner_SpellToolTips400000[i .. ''] == nil or string.len(WoWeuCN_Scanner_SpellToolTips400000[i .. '']) < string.len(text)) then
          WoWeuCN_Scanner_SpellToolTips400000[i .. ''] = text
        end
      elseif (i >=500000 and i < 600000) then
        if (WoWeuCN_Scanner_SpellToolTips500000[i .. ''] == nil or string.len(WoWeuCN_Scanner_SpellToolTips500000[i .. '']) < string.len(text)) then
          WoWeuCN_Scanner_SpellToolTips500000[i .. ''] = text
        end
      end
      print(i)
    end
  end
  print(attempt)
  print('index ' .. startIndex)
  WoWeuCN_Scanner_Index = startIndex
  if (counter >= 5) then
    WoWeuCN_Scanner_wait(0.5, WoWeuCN_Scanner_ScanSpellAuto, startIndex + 150, attempt + 1, 0)
  else
    WoWeuCN_Scanner_wait(0.5, WoWeuCN_Scanner_ScanSpellAuto, startIndex, attempt + 1, counter + 1)
  end
end

function WoWeuCN_Scanner_ScanUnitAuto(startIndex, attempt, counter)
  if (startIndex > 300000) then
    return;
  end
  for i = startIndex, startIndex + 250 do
    qcInformationTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    qcInformationTooltip:ClearLines()
    local guid = "Creature-0-0-0-0-"..i.."-0000000000";
    qcInformationTooltip:SetHyperlink('unit:' .. guid)
    qcInformationTooltip:Show()
    local text =  EnumerateTooltipStyledLines(qcInformationTooltip)
    if (text ~= '' and text ~= nil) then
     if (i >=0 and i < 100000) then
      if (WoWeuCN_Scanner_UnitToolTips0[i .. ''] == nil or string.len(WoWeuCN_Scanner_UnitToolTips0[i .. '']) < string.len(text)) then
        WoWeuCN_Scanner_UnitToolTips0[i .. ''] = text
      end
    elseif (i >=100000 and i < 200000) then
      if (WoWeuCN_Scanner_UnitToolTips100000[i .. ''] == nil or string.len(WoWeuCN_Scanner_UnitToolTips100000[i .. '']) < string.len(text)) then
        WoWeuCN_Scanner_UnitToolTips100000[i .. ''] = text
      end
    elseif (i >=200000 and i < 300000) then
      if (WoWeuCN_Scanner_UnitToolTips200000[i .. ''] == nil or string.len(WoWeuCN_Scanner_UnitToolTips200000[i .. '']) < string.len(text)) then
        WoWeuCN_Scanner_UnitToolTips200000[i .. ''] = text
      end
    end
    end
    print(i)
  end
  print(attempt)
  print('index ' .. startIndex)
  WoWeuCN_Scanner_Index = startIndex
  if (counter >= 3) then
    WoWeuCN_Scanner_wait(0.5, WoWeuCN_Scanner_ScanUnitAuto, startIndex + 250, attempt + 1, 0)
  else
    WoWeuCN_Scanner_wait(0.5, WoWeuCN_Scanner_ScanUnitAuto, startIndex, attempt + 1, counter + 1)
  end
end

function WoWeuCN_Scanner_ScanItemAuto(startIndex, attempt, counter)
  if (startIndex > 300000) then
    return;
  end
  for i = startIndex, startIndex + 150 do
    local itemType, itemSubType, _, _, _, _, classID, subclassID = select(6, GetItemInfo(i))
    if (classID~=nil) then
      qcInformationTooltip:SetOwner(UIParent, "ANCHOR_NONE")
      qcInformationTooltip:ClearLines()
      qcInformationTooltip:SetHyperlink('item:' .. i .. ':0:0:0:0:0:0:0')
      qcInformationTooltip:Show()
      local text = EnumerateTooltipStyledLines(qcInformationTooltip)
      text = text .. '{{{' .. classID .. '}}}'
      if (text ~= '' and text ~= nil) then
        if (i >=0 and i < 100000) then
          if (WoWeuCN_Scanner_ItemToolTips0[i .. ''] == nil or string.len(WoWeuCN_Scanner_ItemToolTips0[i .. '']) < string.len(text)) then
            WoWeuCN_Scanner_ItemToolTips0[i .. ''] = text
          end
        elseif (i >=100000 and i < 200000) then
          if (WoWeuCN_Scanner_ItemToolTips100000[i .. ''] == nil or string.len(WoWeuCN_Scanner_ItemToolTips100000[i .. '']) < string.len(text)) then
            WoWeuCN_Scanner_ItemToolTips100000[i .. ''] = text
          end
        elseif (i >=200000 and i < 300000) then
          if (WoWeuCN_Scanner_ItemToolTips200000[i .. ''] == nil or string.len(WoWeuCN_Scanner_ItemToolTips200000[i .. '']) < string.len(text)) then
            WoWeuCN_Scanner_ItemToolTips200000[i .. ''] = text
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
  print('index ' .. startIndex)
  WoWeuCN_Scanner_Index = startIndex
  if (counter >= 5) then
    WoWeuCN_Scanner_wait(0.5, WoWeuCN_Scanner_ScanItemAuto, startIndex + 150, attempt + 1, 0)
  else
    WoWeuCN_Scanner_wait(0.5, WoWeuCN_Scanner_ScanItemAuto, startIndex, attempt + 1, counter + 1)
  end
end

function WoWeuCN_Scanner_ScanAchivementAuto(startIndex, attempt, counter)
  if (startIndex > 60000) then
    return;
  end
  for i = startIndex, startIndex + 150 do
    qcInformationTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    qcInformationTooltip:ClearLines()
    qcInformationTooltip:SetHyperlink('achievement:' .. i .. ':0:0:0:0:0:0:0:0')
    qcInformationTooltip:Show()
    local text = EnumerateTooltipStyledLines(qcInformationTooltip)
    if (text ~= '' and text ~= nil) then
      if (WoWeuCN_Scanner_Achivements0[i .. ''] == nil or string.len(WoWeuCN_Scanner_Achivements0[i .. '']) < string.len(text)) then
        WoWeuCN_Scanner_Achivements0[i .. ''] = text
      end
    end
  end
  print(attempt)
  print('index ' .. startIndex)
  WoWeuCN_Scanner_Index = startIndex
  if (counter >= 5) then
    WoWeuCN_Scanner_wait(0.5, WoWeuCN_Scanner_ScanAchivementAuto, startIndex + 150, attempt + 1, 0)
  else
    WoWeuCN_Scanner_wait(0.5, WoWeuCN_Scanner_ScanAchivementAuto, startIndex, attempt + 1, counter + 1)
  end
end

local function EnumerateTooltipStyledLines_new(tooltipData)
  local texts = '';

  local index = 0
  for _, line in ipairs(tooltipData.lines) do
    if index < 7 then
      TooltipUtil.SurfaceArgs(line)
    end
      index = index + 1 
  end

  DevTools_Dump({ tooltipData })

	return texts
end

function WoWeuCN_Scanner_ScanQuestAuto(startIndex, attempt, counter)
  if (startIndex > 100000) then
    return;
  end
  for i = startIndex, startIndex + 100 do
    qcInformationTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    qcInformationTooltip:ClearLines()
    qcInformationTooltip:SetHyperlink('quest:' .. i)
    qcInformationTooltip:Show()
    local text =  EnumerateTooltipStyledLines(qcInformationTooltip)
    if (text ~= '' and text ~= nil) then
      WoWeuCN_Scanner_QuestToolTips[i .. ''] = text
      print(i)
    end
  end
  print(attempt)
  print('index ' .. startIndex)
  WoWeuCN_Scanner_Index = startIndex
  if (counter >= 5) then
     WoWeuCN_Scanner_wait(0.5, WoWeuCN_Scanner_ScanQuestAuto, startIndex + 100, attempt + 1, 0)
  else
     WoWeuCN_Scanner_wait(0.5, WoWeuCN_Scanner_ScanQuestAuto, startIndex, attempt + 1, counter + 1)
  end
end

function WoWeuCN_Scanner_ScanEncounterAuto(startIndex, attempt, counter)
  if (startIndex > 25000) then
    WoWeuCN_Scanner_Index = 0
    return;
  end
  for i = startIndex, startIndex + 100 do
    local sectionInfo = EJ_GetEncounterInfo(i)
    if (sectionInfo) then      
	    local ename, description, _, rootSectionID = EJ_GetEncounterInfo(i);
      WoWeuCN_Scanner_EncounterData[i] = {}
      WoWeuCN_Scanner_EncounterData[i]["Title"] = ename
      WoWeuCN_Scanner_EncounterData[i]["Description"] = description
    end
  end
  print(attempt)
  print('index ' .. startIndex)
  WoWeuCN_Scanner_Index = startIndex
  if (counter >= 2) then
     WoWeuCN_Scanner_wait(0.1, WoWeuCN_Scanner_ScanEncounterAuto, startIndex + 100, attempt + 1, 0)
  else
     WoWeuCN_Scanner_wait(0.1, WoWeuCN_Scanner_ScanEncounterAuto, startIndex, attempt + 1, counter + 1)
  end
end

function WoWeuCN_Scanner_ScanEncounterSectionAuto(startIndex, attempt, counter)
  if (startIndex > 50000) then
    WoWeuCN_Scanner_Index = 0
    return;
  end
  for difficultyId = 1, 45 do
    EJ_SetDifficulty(difficultyId)
    for i = startIndex, startIndex + 100 do
      local sectionInfo =  C_EncounterJournal.GetSectionInfo(i)
      if (sectionInfo and not sectionInfo.filteredByDifficulty) then
        WoWeuCN_Scanner_EncounterSectionData[EJ_GetDifficulty() .. 'x' .. i] = {}
        WoWeuCN_Scanner_EncounterSectionData[EJ_GetDifficulty() .. 'x' .. i]["Title"] = sectionInfo.title
        
        print(sectionInfo.title)
        WoWeuCN_Scanner_EncounterSectionData[EJ_GetDifficulty() .. 'x' .. i]["Description"] = sectionInfo.description
      end
    end
  end
  print(attempt)
  print('index ' .. startIndex)
  WoWeuCN_Scanner_Index = startIndex
  if (counter >= 2) then
     WoWeuCN_Scanner_wait(0.1, WoWeuCN_Scanner_ScanEncounterSectionAuto, startIndex + 100, attempt + 1, 0)
  else
     WoWeuCN_Scanner_wait(0.1, WoWeuCN_Scanner_ScanEncounterSectionAuto, startIndex, attempt + 1, counter + 1)
  end
end

function WoWeuCN_Scanner_ScanCacheAuto(startIndex, attempt, counter)
  if (startIndex > 100000) then
    return;
  end
  if (counter == 0) then
     print(startIndex)
    end
    
    for i = startIndex, startIndex + 150 do
     local title = ''
     if C_QuestLog.GetQuestInfo then
      title = C_QuestLog.GetQuestInfo(i)
     else
      title = C_QuestLog.GetTitleForQuestID(tostring(i))
     end
     if (title ~= '' and title ~= nil) then
      print(title)
     end
    end
    
    WoWeuCN_Scanner_Index = startIndex
    if (counter >= 5) then
      WoWeuCN_Scanner_wait(0.2, WoWeuCN_Scanner_ScanCacheAuto, startIndex + 150, attempt + 1, 0)
    else
      WoWeuCN_Scanner_wait(0.2, WoWeuCN_Scanner_ScanCacheAuto, startIndex, attempt + 1, counter + 1)
    end
end

function qcInformationTooltipSetup() -- *
	qcInformationTooltip = CreateFrame("GameTooltip", "qcInformationTooltip", UIParent, "GameTooltipTemplate")
	qcInformationTooltip:SetFrameStrata("TOOLTIP")
end