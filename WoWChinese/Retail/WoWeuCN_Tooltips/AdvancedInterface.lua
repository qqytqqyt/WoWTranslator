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

  local _, fontHeight = textItem:GetFont();
  if fontHeight then
    if fontHeight > maxFontSize then
      fontHeight = maxFontSize
    end
    textItem:SetFont(WoWeuCN_Tooltips_Font1, fontHeight)
    textItem:SetText(RemoveColourCode(ReplaceText(text)))
  end
end

function OnMerchantInfoUpdate(...)
  if (WoWeuCN_Tooltips_PS["active"]=="0" or WoWeuCN_Tooltips_PS["transadvanced"]=="0") then
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
  if (WoWeuCN_Tooltips_PS["active"]=="0" or WoWeuCN_Tooltips_PS["transadvanced"]=="0") then
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
  if (WoWeuCN_Tooltips_PS["active"]=="0" or WoWeuCN_Tooltips_PS["transadvanced"]=="0") or not _G.ElvLootFrame then
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
