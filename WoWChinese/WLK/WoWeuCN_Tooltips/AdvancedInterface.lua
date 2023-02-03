function RemoveColourCode(s)
  if (s == nil) then
    return nil
  end

  s = string.gsub(s, '|c[%a%d][%a%d][%a%d][%a%d][%a%d][%a%d][%a%d][%a%d]', '')
  s = string.gsub(s, '|r', '')
  return s
end

function ReplaceUIText(textItem, text, maxFontSize)
  if not textItem or textItem:GetText() == nil then
    return
  end

  if (WoWeuCN_Tooltips_N_PS["overwritefonts"]=="0") then    
    textItem:SetText(RemoveColourCode(ReplaceText(text)))
    return
  end
  
  local _, fontHeight = textItem:GetFont();
  if fontHeight then
    if fontHeight > maxFontSize then
      fontHeight = maxFontSize
    end
    textItem:SetFont(WoWeuCN_Tooltips_Font1, fontHeight, '')
    textItem:SetText(RemoveColourCode(ReplaceText(text)))
  end
end

function GetTradeSkillName(skillIndex)
  local link = GetTradeSkillItemLink(skillIndex)
  if link then 
    local itemID = string.match(link, '^.-Hitem:(%d+)')
    local itemData = GetItemData(itemID)
    if itemData then
      return itemData[1]
    end
  elseif not link then
    link = GetTradeSkillRecipeLink(skillIndex)
    if link then
      local spellID = string.match(link, '^.-:(%d+)')
      local spellData = GetSpellData(spellID)
      if spellData then
        local spellName = string.match(spellData[1], '^.-: (.+)Ç')
        return spellName
      end
    end
  end

  return nil
end

function OnTradeSkillSelectionUpdate(index)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
    return
  end

  local numReagents = GetTradeSkillNumReagents(index);
  local skillOffset = FauxScrollFrame_GetOffset(TradeSkillListScrollFrame);
  
  local buttonIndex = index - skillOffset
  local skillName = GetTradeSkillName(index)
  if not skillName then
    return
  end
  ReplaceUIText(TradeSkillSkillName, skillName, 15)
  
  if(numReagents == 0) then
    return
  end
  
  if ( GetTradeSkillDescription(index) ) then
    local link = GetTradeSkillRecipeLink(index)
    if link then
      local spellID = string.match(link, '^.-:(%d+)')
      local spellData = GetSpellData(spellID)
      if spellData then
        local text = ''
        for i = 3, #spellData do
          if i == 3 then
            text = spellData[i]
          else
            ext = text .. '\n' .. spellData[i]
          end
        end
        ReplaceUIText(TradeSkillDescription, text, 12)
      end
    end
  end

  ReplaceUIText(TradeSkillReagentLabel, "材料：", 12)
  for i=1, numReagents, 1 do
    local link = GetTradeSkillReagentItemLink(index, i)
    local itemID = string.match(link, '^.-Hitem:(%d+)')
    local itemData = GetItemData(itemID)
    if itemData then
      ReplaceUIText(_G["TradeSkillReagent"..i.."Name"], itemData[1], 12)
    end
  end
end

function OnTradeSkillUpdate()
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
    return
  end

	local numTradeSkills = GetNumTradeSkills();
  local skillOffset = FauxScrollFrame_GetOffset(TradeSkillListScrollFrame);
  
  if ( numTradeSkills == 0 ) then
    return
  end

  for i=1,TRADE_SKILLS_DISPLAYED,1 do
    local skillIndex = i + skillOffset;
    
    local button = _G["TradeSkillSkill" .. i .. "Text"]
    if button then
      local skillName = GetTradeSkillName(skillIndex)
      if skillName then
        ReplaceUIText(button, skillName, 12)
      end
    end
  end
end

function OnSpellBookUpdate(self)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
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
      ReplaceUIText(spellString, spellData[1], 15)
    end
  end
end

function OnMerchantInfoUpdate(...)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
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
        if itemData then
          ReplaceUIText(_G["MerchantItem"..i.."Name"], itemData[1], 12)
        end
      end
    end
  end
end

function OnLootUpdate(index)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
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
        ReplaceUIText(_G["LootButton"..index.."Text"], itemData[1], 12)
      end
    end
  end
end

function OnLootUpdateElvUI(self, ...)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") or not _G.ElvLootFrame then
    return
  end

  local numItems = GetNumLootItems()
  if numItems > 0 then
    for i = 1, numItems do
      local slot = _G.ElvLootFrame.slots[i]
      if slot then
        local itemLink	= GetLootSlotLink(i);
        if (itemLink) then
          local itemID = string.match(itemLink, 'Hitem:(%d+):')
          local itemData = GetItemData(itemID)

          if itemData then
            ReplaceUIText(slot.name, itemData[1], 12)
          end
        end
      end
    end
  end
end
