--- Message Event Filter which intercepts incoming links and shows their names in the language of the game client

local LINK_PATTERN = "(|H(%a+):(%d+)([^|]*)|h)%[(.-)%](|h)"

-- Items whose names are not in the client cache yet, their messages are translated as soon as the data arrives
local pendingItems = {}
local pendingFrame = CreateFrame("Frame")
local PENDING_TIMEOUT = 60
local translatingShown = false

-- Secret values (retail 12.x) must not be read by addon code
local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

local function GetItemName(id, link)
    local name = C_Item.GetItemInfo(link) or C_Item.GetItemInfo(id)
    if (not name and not translatingShown and C_Item.DoesItemExistByID(id)) then
        pendingItems[id] = GetTime()
        pendingFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
        C_Item.RequestLoadItemDataByID(id)
    end
    return name
end

local function GetSpellName(id)
    if C_Spell.GetSpellName then
        return C_Spell.GetSpellName(id)
    end
    local spellInfo = C_Spell.GetSpellInfo(id)
    return spellInfo and spellInfo.name
end

local function GetAchievementName(id)
    if GetAchievementInfo then
        local _, name = GetAchievementInfo(id)
        return name
    end
end

local LocalNames = {
    item = GetItemName,
    spell = GetSpellName,
    enchant = GetSpellName,
    achievement = GetAchievementName,
}

local function TranslateLink(head, linkType, id, data, text, tail)
    local getName = LocalNames[linkType]
    if not getName then
        return
    end

    local name = getName(tonumber(id), linkType .. ":" .. id .. data)
    if (not name or name == "") then
        return
    end

    -- retail appends the crafting quality icon to the name
    local original, icon = text:match("^(.-)(%s*|A.*)$")
    if not original then
        original, icon = text, ""
    end

    if (original == name) then
        return
    end
    -- recipe links carry the profession in front of the spell name
    if (linkType == "enchant" and original:sub(-#name) == name) then
        return
    end

    if (NativeLinks_PS["chatmode"] == "replace") then
        return head .. "[" .. name .. icon .. "]" .. tail
    end

    if (linkType == "achievement") then
        name = name:gsub("（", " ("):gsub("）", ")")
    end
    -- already side by side
    if (original:sub(1, #name + 2) == name .. " (") then
        return
    end
    return head .. "[" .. name .. " (" .. original .. ")" .. icon .. "]" .. tail
end

local function TranslateLinks(msg)
    return (msg:gsub(LINK_PATTERN, TranslateLink))
end

-- Rewrite the messages already shown in the chat frames once the name of an item is known
local function TranslateShownMessages(itemID)
    local itemLink = "|Hitem:" .. itemID .. ":"

    local function HasItemLink(message)
        if IsSecret(message) or type(message) ~= "string" then
            return false
        end
        return message:find(itemLink, 1, true) ~= nil
    end

    local function Translate(message, ...)
        return TranslateLinks(message), ...
    end

    translatingShown = true
    for _, frameName in ipairs(CHAT_FRAMES) do
        local chatFrame = _G[frameName]
        if (chatFrame and chatFrame.TransformMessages and chatFrame ~= _G.ChatFrame2) then
            chatFrame:TransformMessages(HasItemLink, Translate)
        end
    end
    translatingShown = false
end

pendingFrame:SetScript("OnEvent", function(self, event, itemID, success)
    local now = GetTime()
    if pendingItems[itemID] then
        pendingItems[itemID] = nil
        if (success and NativeLinks_IsActive() and NativeLinks_PS["chat"] ~= "0") then
            TranslateShownMessages(itemID)
        end
    end

    for id, requested in pairs(pendingItems) do
        if (now - requested > PENDING_TIMEOUT) then
            pendingItems[id] = nil
        end
    end
    if (next(pendingItems) == nil) then
        self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
    end
end)

local function IsFromPlayer(playerName, senderGUID)
    if (senderGUID and senderGUID ~= "" and senderGUID == UnitGUID("player")) then
        return true
    end

    local playerNamePlain, _ = strsplit("-", playerName);
    return playerName == UnitName("player") or playerNamePlain == UnitName("player")
end

local ChatFilter = function(chatFrame, _, msg, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, senderGUID, bnSenderID, ...)
    if (not NativeLinks_IsActive() or NativeLinks_PS["chat"] == "0") then
        return
    end

    if (IsSecret(msg) or IsSecret(playerName) or IsSecret(senderGUID)) then
        return
    end

    if (type(msg) ~= "string" or type(playerName) ~= "string" or not string.find(msg, "|H", 1, true)) then
        return
    end

    if (chatFrame == _G.ChatFrame2 or IsFromPlayer(playerName, senderGUID)) then
        return
    end

    local translated = TranslateLinks(msg)
    if (translated == msg) then
        return
    end

    return false, translated, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, senderGUID, bnSenderID, ...
end

function NativeLinks_RegisterChatFilters() -- todo: register immediately and cache calls until db is available
    local AddMessageEventFilter = ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter or ChatFrame_AddMessageEventFilter

    -- The message filter that triggers the above local function
    -- Party
    AddMessageEventFilter("CHAT_MSG_PARTY", ChatFilter)
    AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", ChatFilter)

    -- Raid
    AddMessageEventFilter("CHAT_MSG_RAID", ChatFilter)
    AddMessageEventFilter("CHAT_MSG_RAID_LEADER", ChatFilter)
    AddMessageEventFilter("CHAT_MSG_RAID_WARNING", ChatFilter)

    -- Guild
    AddMessageEventFilter("CHAT_MSG_GUILD", ChatFilter)
    AddMessageEventFilter("CHAT_MSG_OFFICER", ChatFilter)

    -- Battleground
    AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", ChatFilter)
    AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", ChatFilter)

    -- Whisper
    AddMessageEventFilter("CHAT_MSG_WHISPER", ChatFilter)

    -- Battle Net
    AddMessageEventFilter("CHAT_MSG_BN", ChatFilter)
    AddMessageEventFilter("CHAT_MSG_BN_WHISPER", ChatFilter)

    -- Open world
    AddMessageEventFilter("CHAT_MSG_CHANNEL", ChatFilter)
    AddMessageEventFilter("CHAT_MSG_SAY", ChatFilter)
    AddMessageEventFilter("CHAT_MSG_YELL", ChatFilter)

    -- Emote
    AddMessageEventFilter("CHAT_MSG_EMOTE", ChatFilter)

    -- System
    --AddMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilter)
    AddMessageEventFilter("CHAT_MSG_LOOT", ChatFilter)
end
