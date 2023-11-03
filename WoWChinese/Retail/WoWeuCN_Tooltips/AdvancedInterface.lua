function RemoveColourCode(s)
  if (s == nil) then
    return nil
  end

  s = string.gsub(s, '|c[%a%d][%a%d][%a%d][%a%d][%a%d][%a%d][%a%d][%a%d]', '')
  s = string.gsub(s, '|r', '')
  return s
end

function ReplaceJournalTabs()  
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
    return
  end
  
  ReplaceUIText(CollectionsJournalTab1.Text, "坐骑", 12)
  ReplaceUIText(CollectionsJournalTab2.Text, "宠物手册", 12)
  ReplaceUIText(CollectionsJournalTab3.Text, "玩具箱", 12)
  ReplaceUIText(CollectionsJournalTab4.Text, "传家宝", 12)
  ReplaceUIText(CollectionsJournalTab5.Text, "外观", 12)
end

function ReplaceUIText(textItem, text, maxFontSize)
  if not textItem or textItem:GetText() == nil then
    return
  end

  local _, fontHeight = textItem:GetFont();
  if fontHeight then
    if fontHeight > maxFontSize then
      fontHeight = maxFontSize
    end
    textItem:SetFont(WoWeuCN_Tooltips_Font1, fontHeight)
    textItem:SetText(RemoveColourCode(ReplaceText(text)))
  end
end

function OnSpellButtonUpdate(self)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
    return
  end
  
  local name = self:GetName()
  local slot, slotType, slotID = SpellBook_GetSpellBookSlot(self);
  if name == nil or slot == nil then
    return
  end
  local spellName, _, spellID = GetSpellBookItemName(slot, SpellBookFrame.bookType);
  local spellString = _G[name.."SpellName"];
  local spellData = GetSpellData(spellID)
  if ( spellData ) then
    ReplaceUIText(spellString, spellData[1], 15)
  end
end

function OnToyBoxUpdate(...)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
    return
  end

  for i = 1, 18 do
    local button = ToyBox.iconsFrame["spellButton"..i];
    if (not button.name:GetText()) then
      return
    end

    if (not button.nameHooked) then
      local titleLabel = button:CreateFontString(nil, "ARTWORK", "GameFontNormal");
      titleLabel:SetPoint(button.name:GetPoint())
      titleLabel:SetParent(button.name:GetParent())
      titleLabel:SetSize(button.name:GetSize())
      titleLabel:SetText(button.name:GetText())
      titleLabel:SetFont(button.name:GetFont())
      titleLabel:SetJustifyH(button.name:GetJustifyH());
      titleLabel:SetJustifyV(button.name:GetJustifyV());
      button.translatedName = titleLabel
      button.name:SetSize(1, 1)
      button.nameHooked = true
    end

    local toyString = button.translatedName
    local itemIndex = (ToyBox.PagingFrame:GetCurrentPage() - 1) * 18 + i;
    local itemID = C_ToyBox.GetToyFromIndex(itemIndex) 

    if (PlayerHasToy(itemID)) then    
        toyString:SetTextColor(1, 0.82, 0, 1);
        toyString:SetShadowColor(0, 0, 0, 1);
    else    
        toyString:SetTextColor(0.33, 0.27, 0.20, 1);
        toyString:SetShadowColor(0, 0, 0, 0.33);
    end

    local itemData = GetItemData(itemID)
    if itemData then
      if (button.translatedName:GetText() ~= itemData[1]) then
        ReplaceUIText(toyString, itemData[1], 12)
        toyString:Show()
      end
    end
  end
end

function OnToyBoxButtonUpdate(self)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
    return
  end

  local itemIndex = (ToyBox.PagingFrame:GetCurrentPage() - 1) * 18 + self:GetID();
	local itemID = C_ToyBox.GetToyFromIndex(itemIndex);
  local button = ToyBox.iconsFrame["spellButton"..self:GetID()];

  if (not button.name:GetText()) then
    return
  end

  if (not button.nameHooked and self:IsShown()) then
    local titleLabel = self:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    titleLabel:SetPoint(button.name:GetPoint())
    titleLabel:SetParent(button.name:GetParent())
    titleLabel:SetSize(button.name:GetSize())
    titleLabel:SetText(button.name:GetText())
    titleLabel:SetFont(button.name:GetFont())
    titleLabel:SetJustifyH(button.name:GetJustifyH());
    titleLabel:SetJustifyV(button.name:GetJustifyV());
    button.translatedName = titleLabel
    button.name:SetSize(1, 1)
    button.nameHooked = true
  end

  local toyString = button.translatedName
  if (PlayerHasToy(itemID)) then    
			toyString:SetTextColor(1, 0.82, 0, 1);
      toyString:SetShadowColor(0, 0, 0, 1);
  else    
			toyString:SetTextColor(0.33, 0.27, 0.20, 1);
			toyString:SetShadowColor(0, 0, 0, 0.33);
  end

  local itemData = GetItemData(itemID)
  if itemData then
    if (button.translatedName:GetText() ~= itemData[1]) then
      ReplaceUIText(toyString, itemData[1], 12)
      toyString:Show()
    end    
  end
end

function OnMountJournalButtonInit(button, elementData)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
    return
  end

  local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, isFiltered, isCollected, mountID, isForDragonriding = C_MountJournal.GetDisplayedMountInfo(elementData.index);
	
  local spellData = GetSpellData(spellID)
  if (spellData) then
    ReplaceUIText(button.name, spellData[1], 12)
  end
end

function OnPetJournalButtonInit(button, elementData)  
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
    return
  end

  local index = elementData.index;
  local empty, item2, item3, item4, item5, item6, item7, item8, item9, item10, npcID  = C_PetJournal.GetPetInfoByIndex(index);
  local unitData = GetUnitData(npcID)
  if (unitData) then
    if (button.name:GetText() ~= unitData[1]) then
      ReplaceUIText(button.name, unitData[1], 12)
      button.name:Show()
    end    
  end
end

function OnHeirloonButtonUpdate(button)  
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
    return
  end

  if (not button.name:GetText()) then
    return
  end
  
	local itemID = button.itemID
  local itemData = GetItemData(itemID)
  
  if (not button.nameHooked) then
    local titleLabel = button:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    titleLabel:Hide()
    button.translatedName = button.name
    button.name = titleLabel
    button.nameHooked = true
  end
  
  local heriloomString = button.translatedName
  if (C_Heirloom.PlayerHasHeirloom(itemID)) then    
    heriloomString:SetTextColor(1, 0.82, 0, 1);
    heriloomString:SetShadowColor(0, 0, 0, 1);
  else    
    heriloomString:SetTextColor(0.33, 0.27, 0.20, 1);
    heriloomString:SetShadowColor(0, 0, 0, 0.33);
  end

  if itemData then
    if (heriloomString:GetText() ~= itemData[1]) then
      ReplaceUIText(heriloomString, itemData[1], 12)
      heriloomString:Show()
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

function OnLootUpdate(self, ...)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
    return
  end
  
	local slotIndex = self:GetSlotIndex();
  local itemLink	= GetLootSlotLink(slotIndex);
  if not itemLink then
    return
  end
  local itemID = string.match(itemLink, 'Hitem:(%d+):')
  local itemData = GetItemData(itemID)
  
  if itemData then
    ReplaceUIText(self.Text, itemData[1], 12)
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
