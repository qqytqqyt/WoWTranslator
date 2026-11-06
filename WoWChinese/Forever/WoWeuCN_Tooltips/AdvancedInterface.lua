local _, DataStore = ...
local EncounterData = DataStore.R("Encounter", { "Title", "Description" })
local EncounterSectionData = DataStore.R("EncounterSection", { "Title", "Description" })

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
  
  -- Forever's journal has icon-only side tabs (CollectionsJournal.TabContainer) instead of these
  local tabTexts = { "坐骑", "宠物手册", "玩具箱", "传家宝", "外观" }
  for i, text in ipairs(tabTexts) do
    local tab = _G["CollectionsJournalTab" .. i]
    if tab then
      ReplaceUIText(tab.Text, text, 12)
    end
  end
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

function UpdateEncounterJournalHeaders()
  local usedHeaders = EncounterJournal.encounter.usedHeaders;

  local listEnd = #usedHeaders;
  for index, infoHeader in pairs(usedHeaders) do
    if (infoHeader and infoHeader.description) then      
      local sectionID = infoHeader.myID
      local difficultyID = EJ_GetDifficulty()
      if WoWeuCN_Tooltips_TranslateEncounterJournal then
        local sectionTranslation = EncounterSectionData[difficultyID .. 'x' .. sectionID]
        if (sectionTranslation) then
          WoWeuCN_Tooltips_ApplyAddonFont(infoHeader.button.title)
          WoWeuCN_Tooltips_ApplyAddonFont(infoHeader.description)
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

function UpdateOverviews() 
  local difficultyID = EJ_GetDifficulty()
  local self = EncounterJournal.encounter.overviewFrame
  local overviewSectionID = self.rootOverviewSectionID
  if not overviewSectionID then
    return
  end
  local overviewSectionTranslation = EncounterSectionData[difficultyID .. 'x' .. overviewSectionID]
  
  if (WoWeuCN_Tooltips_TranslateEncounterJournal and overviewSectionTranslation) then
    WoWeuCN_Tooltips_ApplyAddonFont(self.overviewDescription.Text)
    self.overviewDescription.Text:SetText(overviewSectionTranslation["Description"]);
    self.overviewDescription.descriptionHeight = self.overviewDescription:GetHeight();
  else
    local sectionInfo =  C_EncounterJournal.GetSectionInfo(overviewSectionID)
    self.overviewDescription.Text:SetText(sectionInfo.description);
    self.overviewDescription.descriptionHeight = self.overviewDescription:GetHeight();
  end

  for index, infoHeader in pairs(self.overviews) do
    if (infoHeader and infoHeader.description) then      
      local sectionID = infoHeader.sectionID
      if WoWeuCN_Tooltips_TranslateEncounterJournal then
        local sectionTranslation = EncounterSectionData[difficultyID .. 'x' .. sectionID]
        if (sectionTranslation) then
          WoWeuCN_Tooltips_ApplyAddonFont(infoHeader.button.title)
          infoHeader.button.title:SetText(sectionTranslation["Title"])
          EncounterJournal_SetBullets(infoHeader.overviewDescription, sectionTranslation["Description"], not infoHeader.expanded);
          EncounterJournal_ShiftHeaders(index)
        end
      else
        local sectionInfo =  C_EncounterJournal.GetSectionInfo(sectionID)
        infoHeader.button.title:SetText(sectionInfo.title)
        infoHeader.description:SetText(sectionInfo.description)
        EncounterJournal_SetBullets(infoHeader.overviewDescription, sectionInfo.description, not infoHeader.expanded);
        EncounterJournal_ShiftHeaders(index)
      end
    end
  end
end

function OnEncounterJournalDisplay(encounterID, noButton)  
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
    return
  end

  local encounterTranslation = EncounterData[encounterID]  
  if (encounterTranslation) then    
    local self = EncounterJournal.encounter;
    WoWeuCN_Tooltips_ApplyAddonFont(self.info.encounterTitle)
    WoWeuCN_Tooltips_ApplyAddonFont(self.overviewFrame.loreDescription)
    WoWeuCN_Tooltips_ApplyAddonFont(self.infoFrame.description)
    self.info.encounterTitle:SetText(encounterTranslation["Title"]);
    self.overviewFrame.loreDescription:SetText(encounterTranslation["Description"]);
    local difficultyID = EJ_GetDifficulty()
    local sectionID = self.overviewFrame.rootOverviewSectionID
    local sectionTranslation = EncounterSectionData[difficultyID .. 'x' .. sectionID]
    
    if (sectionTranslation) then
      WoWeuCN_Tooltips_ApplyAddonFont(self.overviewFrame.overviewDescription.Text)
      self.overviewFrame.overviewDescription.Text:SetText(sectionTranslation["Description"]);
      self.overviewFrame.overviewDescription.descriptionHeight = self.overviewFrame.overviewDescription:GetHeight();
    end
    
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

  if (object == EncounterJournal.encounter.overviewFrame) then
    return
  end

  UpdateEncounterJournalHeaders()
end

function OnEncounterJournalOverview(infoHeader, description)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
    return
  end

  local sectionID = infoHeader.sectionID
  local difficultyID = EJ_GetDifficulty()
  if WoWeuCN_Tooltips_TranslateEncounterJournal then
    local sectionTranslation = EncounterSectionData[difficultyID .. 'x' .. sectionID]
    if (sectionTranslation) then
      WoWeuCN_Tooltips_ApplyAddonFont(infoHeader.button.title)
      infoHeader.button.title:SetText(sectionTranslation["Title"])
      EncounterJournal_SetBullets(infoHeader.overviewDescription, sectionTranslation["Description"], not infoHeader.expanded);
    end
  else
    local sectionInfo =  C_EncounterJournal.GetSectionInfo(sectionID)
    infoHeader.button.title:SetText(sectionInfo.title)
    EncounterJournal_SetBullets(infoHeader.overviewDescription, sectionInfo.description, not infoHeader.expanded);
  end
end

function WoWeuCN_Tooltips_EncounterButton_On_Off()
  WoWeuCN_Tooltips_TranslateEncounterJournal = not WoWeuCN_Tooltips_TranslateEncounterJournal
  UpdateEncounterJournalHeaders()
  UpdateOverviews()
end

function OnHouseTooltip(self, GameTooltip)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0") then
    print(WoWeuCN_Tooltips_N_PS["transadvanced"])
    return
  end

  if (WoWeuCN_Tooltips_DecorMapping ~= nil and self.entryInfo ~= nil and self.entryInfo.entryID ~= nil and self.entryInfo.entryID.recordID ~= nil) then
    local decorID = self.entryInfo.entryID.recordID
    local itemID = WoWeuCN_Tooltips_DecorMapping['' .. decorID]
    if (itemID ~= nil) then
      GameTooltip:AddLine(" ")
      local itemData = GetItemData(itemID)
      if ( itemData ) then  
        local region = itemData[1]
        GameTooltip:AddLine(region, 1, 1, 1, 1)
        WoWeuCN_Tooltips_ApplyTooltipLineFont(GameTooltip, GameTooltip:NumLines())
        GameTooltip:Show()
      end
    end
  end
end

function OnHousePreview(self, catalogEntryInfo)
  if (WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0") then
    return
  end

  if (WoWeuCN_Tooltips_DecorMapping ~= nil and catalogEntryInfo ~= nil and catalogEntryInfo.entryID ~= nil and catalogEntryInfo.entryID.recordID ~= nil) then
    local decorID = catalogEntryInfo.entryID.recordID
    local itemID = WoWeuCN_Tooltips_DecorMapping['' .. decorID]
    if (itemID ~= nil) then
      GameTooltip:AddLine(" ")
      local itemData = GetItemData(itemID)
      if ( itemData ) then
        WoWeuCN_Tooltips_ApplyAddonFont(self.NameContainer.Name)
        self.NameContainer.Name:SetText(itemData[1]);
      end
    end
  end
end
-- Profession window (mainline ProfessionsFrame): names that come from item and spell ids.
-- Category headers, recipe names and the "Requires:" line are database names: WoWeuCN_Interface does those.
local function ProfessionsOff()
  return WoWeuCN_Tooltips_N_PS["active"]=="0" or WoWeuCN_Tooltips_N_PS["transadvanced"]=="0"
end

local function ReplaceColouredText(fontString, english, chinese)
  local text = fontString:GetText()
  if not text or not english or english == "" then
    return false
  end
  local open, inner, close = string.match(text, "^(|c%x%x%x%x%x%x%x%x)(.-)(|r)$")
  local plain = inner or text
  if string.sub(plain, -string.len(english)) ~= english then
    return false
  end
  plain = string.sub(plain, 1, string.len(plain) - string.len(english)) .. chinese
  WoWeuCN_Tooltips_ApplyAddonFont(fontString)
  fontString:SetText(open and (open .. plain .. close) or plain)
  return true
end

function OnProfessionsOutputItem(form)
  if ProfessionsOff() or not form.transaction or not form.OutputText:IsShown() or form.isRecraft then
    return
  end
  local recipeID = form.transaction:GetRecipeID()
  local ok, outputInfo = pcall(C_TradeSkillUI.GetRecipeOutputItemData, recipeID)
  local itemID = ok and outputInfo and outputInfo.itemID
  local itemData = itemID and GetItemData(itemID)
  local english = itemID and C_Item.GetItemNameByID(itemID)
  if not itemData or not english then
    return
  end
  local fontString = form.OutputText
  if ReplaceColouredText(fontString, english, RemoveColourCode(ReplaceText(itemData[1]))) then
    -- same fitting as Blizzard's SetTextToFit, the Chinese name has a different width
    local minimized = ProfessionsUtil and ProfessionsUtil.IsCraftingMinimized()
    fontString:SetWidth(minimized and 250 or 800)
    if not minimized then
      fontString:SetWidth(fontString:GetStringWidth())
    end
    fontString:SetHeight(fontString:GetStringHeight())
  end
end

function OnProfessionsRecipeDescription(form)
  if ProfessionsOff() or not form.currentRecipeInfo or not form.Description:IsShown() then
    return
  end
  local current = form.Description:GetText()
  if not current or current == "" then
    return
  end
  local spellData = GetSpellData(form.currentRecipeInfo.recipeID)
  if not spellData then
    return
  end
  -- the scanned spell tooltip: line 1 is the name, the description is the first gold line before the
  -- crafted item's own block (which starts on a new line and carries its own gold flavour text)
  for i = 2, #spellData do
    if string.find(RemoveColourCode(ReplaceText(spellData[i])), "^\n") then
      return
    end
    if string.sub(spellData[i], 1, 2) == "Å" then
      WoWeuCN_Tooltips_ApplyAddonFont(form.Description)
      form.Description:SetText(RemoveColourCode(ReplaceText(spellData[i])))
      form.Description:SetHeight(600)
      form.Description:SetHeight(form.Description:GetStringHeight() + 1)
      return
    end
  end
end

function OnProfessionsReagentSlotUpdate(slot)
  if ProfessionsOff() or not slot.Name:IsShown() or not slot.nameText then
    return
  end
  local schematic = slot:GetReagentSlotSchematic()
  local candidates = {}
  local current = slot:GetReagent()
  if current then
    candidates[#candidates + 1] = current
  end
  if schematic and schematic.reagents then
    for _, reagent in ipairs(schematic.reagents) do
      candidates[#candidates + 1] = reagent
    end
  end
  for _, reagent in ipairs(candidates) do
    local itemData = reagent.itemID and GetItemData(reagent.itemID)
    local english = reagent.itemID and C_Item.GetItemNameByID(reagent.itemID)
    if itemData and english and ReplaceColouredText(slot.Name, english, RemoveColourCode(ReplaceText(itemData[1]))) then
      return
    end
  end
end
