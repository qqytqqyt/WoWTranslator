-- wait functions from QTR
local WoWeuCN_Tooltips_waitFrame = nil;
local WoWeuCN_Tooltips_waitTable = {};

function scanClear()
    WoWeuCN_Tooltips_SpellToolIndex = 1;
    WoWeuCN_Tooltips_SpellToolTips0 = {} 
    WoWeuCN_Tooltips_SpellToolTips100000 = {} 
    WoWeuCN_Tooltips_SpellToolTips200000 = {} 
    WoWeuCN_Tooltips_SpellToolTips300000 = {}      
    WoWeuCN_Tooltips_ItemToolTips0 = {} 
    WoWeuCN_Tooltips_ItemToolTips100000 = {} 
    WoWeuCN_Tooltips_ItemIndex = 1
    WoWeuCN_Tooltips_UnitToolTips0 = {} 
    WoWeuCN_Tooltips_UnitIndex = 1
    print("Clear");
end

function scanInit()  
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

    if (WoWeuCN_Tooltips_UnitToolTips0 == nil) then
    WoWeuCN_Tooltips_UnitToolTips0 = {} 
    end
    if (WoWeuCN_Tooltips_UnitIndex == nil) then
    WoWeuCN_Tooltips_UnitIndex = 1
    end

    if (WoWeuCN_Tooltips_ItemToolTips0 == nil) then
    WoWeuCN_Tooltips_ItemToolTips0 = {} 
    end
    if (WoWeuCN_Tooltips_ItemToolTips100000 == nil) then
    WoWeuCN_Tooltips_ItemToolTips100000 = {} 
    end
    if (WoWeuCN_Tooltips_ItemIndex == nil) then
    WoWeuCN_Tooltips_ItemIndex = 1
    end
end

function scanIndex(index)
    WoWeuCN_Tooltips_SpellToolIndex = tonumber(index);
    WoWeuCN_Tooltips_ItemIndex = tonumber(index);
    WoWeuCN_Tooltips_UnitIndex = tonumber(index);
    print(index)
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

function scanSpellAuto(startIndex, attempt, counter)
  if (startIndex > 400000) then
    return;
  end
  for i = startIndex, startIndex + 150 do
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
    WoWeuCN_Tooltips_wait(0.5, scanSpellAuto, startIndex + 150, attempt + 1, 0)
  else
    WoWeuCN_Tooltips_wait(0.5, scanSpellAuto, startIndex, attempt + 1, counter + 1)
  end
end

function scanUnitAuto(startIndex, attempt, counter)
  if (startIndex > 100000) then
    return;
  end
  for i = startIndex, startIndex + 250 do
    qcSpellInformationTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    qcSpellInformationTooltip:ClearLines()
    local guid = "Creature-0-0-0-0-"..i.."-0000000000";
    qcSpellInformationTooltip:SetHyperlink('unit:' .. guid)
    qcSpellInformationTooltip:Show()
    local text =  EnumerateTooltipStyledLines(qcSpellInformationTooltip)
    if (text ~= '' and text ~= nil) then
     if (i >=0 and i < 100000) then
      if (WoWeuCN_Tooltips_UnitToolTips0[i .. ''] == nil or string.len(WoWeuCN_Tooltips_UnitToolTips0[i .. '']) < string.len(text)) then
        WoWeuCN_Tooltips_UnitToolTips0[i .. ''] = text
      end
    elseif (i >=100000 and i < 200000) then
      if (WoWeuCN_Tooltips_UnitToolTips100000[i .. ''] == nil or string.len(WoWeuCN_Tooltips_UnitToolTips100000[i .. '']) < string.len(text)) then
        WoWeuCN_Tooltips_UnitToolTips100000[i .. ''] = text
      end
    end
    end
    print(i)
  end
  print(attempt)
  print(counter)
  WoWeuCN_Tooltips_UnitIndex = startIndex
  if (counter >= 3) then
    WoWeuCN_Tooltips_wait(0.5, scanUnitAuto, startIndex + 250, attempt + 1, 0)
  else
    WoWeuCN_Tooltips_wait(0.5, scanUnitAuto, startIndex, attempt + 1, counter + 1)
  end
end

function scanItemAuto(startIndex, attempt, counter)
  if (startIndex > 200000) then
    return;
  end
  for i = startIndex, startIndex + 150 do
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
    WoWeuCN_Tooltips_wait(0.5, scanItemAuto, startIndex + 150, attempt + 1, 0)
  else
    WoWeuCN_Tooltips_wait(0.5, scanItemAuto, startIndex, attempt + 1, counter + 1)
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