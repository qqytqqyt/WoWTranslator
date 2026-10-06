-- Options page under Options > AddOns, the slash commands change the same saved variables

local NativeLinks_OptionsCategory = nil;

local function CreateCheckbox(category, variable, key, name, tooltip)
  local function GetValue()
    return NativeLinks_PS[key] ~= "0"
  end
  local function SetValue(value)
    NativeLinks_PS[key] = value and "1" or "0"
  end

  local setting = Settings.RegisterProxySetting(category, variable, Settings.VarType.Boolean, name, true, GetValue, SetValue)
  return setting, Settings.CreateCheckbox(category, setting, tooltip)
end

local function CreateOptions()
  local messages = NativeLinks_Messages
  local category = Settings.RegisterVerticalLayoutCategory("Native Links")

  CreateCheckbox(category, "NATIVELINKS_ACTIVE", "active", messages.optactive, messages.optactivetip)
  local chatSetting, chatInitializer = CreateCheckbox(category, "NATIVELINKS_CHAT", "chat", messages.optchat, messages.optchattip)

  -- Dropdown values are the positions in this list
  local modes = { "both", "replace" }
  local function GetMode()
    return NativeLinks_PS["chatmode"] == "replace" and 2 or 1
  end
  local function SetMode(value)
    NativeLinks_PS["chatmode"] = modes[tonumber(value) or 1] or "both"
  end
  local function GetModeOptions()
    local container = Settings.CreateControlTextContainer()
    container:Add(1, messages.optmodeboth)
    container:Add(2, messages.optmodereplace)
    return container:GetData()
  end

  local modeSetting = Settings.RegisterProxySetting(category, "NATIVELINKS_CHATMODE", Settings.VarType.Number, messages.optmode, 1, GetMode, SetMode)
  local modeInitializer = Settings.CreateDropdown(category, modeSetting, GetModeOptions, messages.optmodetip)
  if modeInitializer and modeInitializer.SetParentInitializer and chatInitializer then
    modeInitializer:SetParentInitializer(chatInitializer, function() return chatSetting:GetValue() end)
  end

  Settings.RegisterAddOnCategory(category)
  return category
end

function NativeLinks_RegisterOptions()
  if NativeLinks_OptionsCategory or not NativeLinks_PS then return end
  if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterProxySetting and Settings.CreateCheckbox
      and Settings.CreateDropdown and Settings.CreateControlTextContainer and Settings.RegisterAddOnCategory and Settings.VarType) then
    return
  end

  local ok, category = xpcall(CreateOptions, geterrorhandler())
  if ok then
    NativeLinks_OptionsCategory = category
  end
end

function NativeLinks_OpenOptions()
  NativeLinks_RegisterOptions()

  local category = NativeLinks_OptionsCategory
  if not category then
    return false
  end
  return (pcall(Settings.OpenToCategory, category.GetID and category:GetID() or category))
end
