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

function ReplaceJournalTabs()  
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
    return
  end
  
  ReplaceUIText(CollectionsJournalTab1Text, "坐骑", 12)
  ReplaceUIText(CollectionsJournalTab2Text, "宠物手册", 12)
  ReplaceUIText(CollectionsJournalTab3Text, "玩具箱", 12)
  ReplaceUIText(CollectionsJournalTab4Text, "传家宝", 12)
  ReplaceUIText(CollectionsJournalTab5Text, "外观", 12)
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

local function PopulateBossDataProvider()
	local dataProvider = CreateDataProvider();

	local index = 1;
	while index do
		local name, description, bossID, rootSectionID, link = EJ_GetEncounterInfoByIndex(index);
		if bossID and bossID > 0 then
			dataProvider:Insert({index=index, name=name, description=description, bossID=bossID, rootSectionID=rootSectionID, link=link});
			index = index + 1;
		else
			break;
		end
	end

	return dataProvider;
end

function UpdateEncounterJournalHeaders()
  local usedHeaders = EncounterJournal.encounter.usedHeaders;

  local listEnd = #usedHeaders;
  for index, infoHeader in pairs(usedHeaders) do
    if (infoHeader and infoHeader.description) then      
      local sectionID = infoHeader.myID
      local difficultyID = EJ_GetDifficulty()
      if WoWeuCN_Tooltips_TranslateEncounterJournal then
        local sectionTranslation = WoWeuCN_Tooltips_EncounterSectionData[difficultyID .. 'x' .. sectionID]
        if (sectionTranslation) then
          infoHeader.button.title:SetText(sectionTranslation["Title"])
          infoHeader.description:SetText(sectionTranslation["Description"])
          EncounterJournal_ShiftHeaders(index)
        end
      else
        local sectionInfo =  C_EncounterJournal.GetSectionInfo(sectionID)
        infoHeader.button.title:SetText(sectionInfo.title)
        infoHeader.description:SetText(sectionInfo.description)
        EncounterJournal_ShiftHeaders(index)
      end
    end
  end
end

function OnEncounterJournalDisplay(encounterID, noButton)  
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
    return
  end

  local encounterTranslation = WoWeuCN_Tooltips_EncounterData[encounterID]  
  if (encounterTranslation) then    
	  local self = EncounterJournal.encounter;
    self.info.encounterTitle:SetText(encounterTranslation["Title"]);
    self.overviewFrame.loreDescription:SetText(encounterTranslation["Description"]);
    self.infoFrame.description:SetText(encounterTranslation["Description"]);
    self.infoFrame.descriptionHeight = self.infoFrame.description:GetHeight();
    if self.usedHeaders[1] then
      self.usedHeaders[1]:SetPoint("TOPRIGHT", 0 , -8 - EncounterJournal.encounter.infoFrame.descriptionHeight - 6);
    end
  end
  UpdateEncounterJournalHeaders()
end

function OnEncounterJournalToggle(object, hideBullets)  
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
    return
  end

  UpdateEncounterJournalHeaders()
end

function WoWeuCN_Tooltips_EncounterButton_On_Off()
  WoWeuCN_Tooltips_TranslateEncounterJournal = not WoWeuCN_Tooltips_TranslateEncounterJournal
  UpdateEncounterJournalHeaders()
end