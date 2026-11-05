-- Built-in nameplate translation
-- With Plater loaded, the NPC names go into Plater as an imported mod (see InitializePlater in
-- WoWeuCN_Tooltips.lua) and this file stays idle. Without it, the NPC name on the game's own nameplates
-- is replaced by the Chinese name.
--
-- Taint: Blizzard's nameplate code never reads the name's text (only its shown state, and the click area is
-- anchored to its rectangle), so only the text is written - never Show/Hide or anchors. The
-- CompactUnitFrame_UpdateName post-hook only flags the unit frame; the name is rewritten afterwards from the
-- addon's own OnUpdate, outside Blizzard's update chain, before the frame is drawn.

-- nameplate UnitFrame -> { text = Chinese set, english = name it replaced, font = { object, file, size, flags } }
local states = setmetatable({}, { __mode = "k" })
local dirty = {}  -- nameplate UnitFrame -> true, updated on the next OnUpdate
local refreshAll = false
local nameHooked = false

local function IsReadable(value)
  return value ~= nil and not (issecretvalue and issecretvalue(value))
end

local function IsPlaterLoaded()
  if Plater then
    return true
  end
  return C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Plater") and true or false
end

local function IsNamePlateUnit(unit)
  return type(unit) == "string" and IsReadable(unit) and string.find(unit, "^nameplate") ~= nil
end

local function IsUsable(frame)
  return frame ~= nil and not (frame.IsForbidden and frame:IsForbidden())
end

-- the Chinese name for a nameplate unit, or nil (players, pets, unknown NPCs, translation disabled)
local function GetTranslatedName(unit)
  if not WoWeuCN_Tooltips_N_PS or not WoWeuCN_Tooltips_GetNameplateUnitData then
    return nil
  end
  local guid = UnitGUID(unit)
  if not IsReadable(guid) then
    return nil
  end
  local unitType, _, _, _, _, npcId = strsplit("-", guid)
  if (unitType ~= "Creature" and unitType ~= "Vehicle") or not npcId then
    return nil
  end
  local unitData = WoWeuCN_Tooltips_GetNameplateUnitData(npcId)
  local name = unitData and unitData[1]
  if type(name) ~= "string" or name == "" then
    return nil
  end
  return name
end

-- clients without the Chinese font: the addon font while the name is Chinese. Blizzard sets the font only
-- when it sets the plate up (SetFontObject + height), so that is what goes back.
local function SwitchFont(name, state)
  if not (WoWeuCN_Tooltips_UseAddonFont and WoWeuCN_Tooltips_UseAddonFont()) then
    return
  end
  local file, size, flags = name:GetFont()
  if file == WoWeuCN_Tooltips_Font1 or not size or size <= 0 then
    return
  end
  state.font = { object = name:GetFontObject(), file = file, size = size, flags = flags or "" }
  name:SetFont(WoWeuCN_Tooltips_Font1, size, flags or "")
end

local function RestoreFont(name, state)
  local font = state.font
  state.font = nil
  if not font or name:GetFont() ~= WoWeuCN_Tooltips_Font1 then
    return
  end
  if font.object then
    -- through the font object: SetFont with GetFont's file would drop the family's Chinese member
    name:SetFontObject(font.object)
    if name.SetFontHeight then
      name:SetFontHeight(font.size)
    else
      name:SetTextHeight(font.size)
    end
  else
    name:SetFont(font.file, font.size, font.flags)
  end
end

local function UpdateName(unitFrame)
  if not IsUsable(unitFrame) or not unitFrame.name then
    return
  end
  local name = unitFrame.name
  local unit = unitFrame.unit
  local state = states[unitFrame]
  local current = name:GetText()
  local text
  if IsNamePlateUnit(unit) and not IsPlaterLoaded() then
    text = GetTranslatedName(unit)
  end

  if text then
    if not state then
      state = {}
      states[unitFrame] = state
    end
    -- whatever Blizzard wrote since (the next unit of a pooled frame, a renamed unit) is the English name
    if IsReadable(current) and current ~= text then
      state.english = current
    end
    state.text = text
    SwitchFont(name, state)
    if not IsReadable(current) or current ~= text then
      name:SetText(text)
    end
  elseif state then
    -- translation turned off (option, Plater, unreadable GUID): put the English name back if it is still ours
    if IsNamePlateUnit(unit) and state.english and IsReadable(current) and current == state.text then
      name:SetText(state.english)
    end
    RestoreFont(name, state)
    states[unitFrame] = nil
  end
end

local function FlagNamePlate(plate)
  if IsUsable(plate) and plate.UnitFrame then
    dirty[plate.UnitFrame] = true
  end
end

function WoWeuCN_Tooltips_RefreshNameplates()
  refreshAll = true
end

local function HookUpdateName()
  if nameHooked or not CompactUnitFrame_UpdateName then
    return
  end
  hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
    -- runs inside Blizzard's update: only flag the frame (raid frames are skipped)
    if frame and (states[frame] or IsNamePlateUnit(frame.unit)) then
      dirty[frame] = true
    end
  end)
  nameHooked = true
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("NAME_PLATE_UNIT_ADDED")
driver:RegisterEvent("UNIT_NAME_UPDATE")

driver:SetScript("OnEvent", function(self, event, arg1)
  if event == "NAME_PLATE_UNIT_ADDED" or event == "UNIT_NAME_UPDATE" then
    if IsNamePlateUnit(arg1) and C_NamePlate and C_NamePlate.GetNamePlateForUnit then
      FlagNamePlate(C_NamePlate.GetNamePlateForUnit(arg1))
    end
  else
    -- ADDON_LOADED (Blizzard_UnitFrame may load after this addon, Plater turns this file off) and loading screens
    HookUpdateName()
    refreshAll = true
  end
end)

driver:SetScript("OnUpdate", function()
  if refreshAll then
    refreshAll = false
    for unitFrame in pairs(states) do
      dirty[unitFrame] = true
    end
    if C_NamePlate and C_NamePlate.GetNamePlates then
      for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        FlagNamePlate(plate)
      end
    end
  end
  if next(dirty) == nil then
    return
  end
  for unitFrame in pairs(dirty) do
    dirty[unitFrame] = nil
    UpdateName(unitFrame)
  end
end)

HookUpdateName()
