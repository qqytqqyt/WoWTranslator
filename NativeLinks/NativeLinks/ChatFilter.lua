--- Message Event Filter which intercepts incoming linked quests and replaces them with Hyperlinks

local function regexEscape(str)
    return str:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
end

ChatFilter = function(chatFrame, _, msg, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, senderGUID, bnSenderID, ...)
    if (NativeLinks_PS["active"]=="0") then
        return
    end
    
    local playerNamePlain, _ = strsplit("-", playerName);

    if playerName == UnitName("player") or playerNamePlain == UnitName("player") then
        return
    end

    if string.find(msg, "Hitem:") then
        if chatFrame and chatFrame.historyBuffer and #(chatFrame.historyBuffer.elements) > 0 and chatFrame ~= _G.ChatFrame2 then
            while (string.find(msg, "Hitem:")) do
                local id, name = string.match(msg, "^.-Hitem:(%d+):.-%[(.-)%]")
                local itemData = C_Item.GetItemInfo(tonumber(id))
                if (itemData) then
                    msg = string.gsub(msg, regexEscape(name .. "]"), itemData .. " (" .. name .. ")]", 1)
                end
                msg = string.gsub(msg, "Hitem:", "£TMP£", 1)
            end
            
            msg = string.gsub(msg, "£TMP£", "Hitem:")
        end
    end

    if string.find(msg, "Hspell:") then
        if chatFrame and chatFrame.historyBuffer and #(chatFrame.historyBuffer.elements) > 0 and chatFrame ~= _G.ChatFrame2 then
            while (string.find(msg, "Hspell:")) do
                local id, name = string.match(msg, "^.-Hspell:(%d+):.-%[(.-)%]")
                local spellInfo = C_Spell.GetSpellInfo(tonumber(id))
                local spellData = spellInfo.name
                if (spellData) then
                    msg = string.gsub(msg, regexEscape(name .. "]"), spellData .. " (" .. name .. ")]", 1)
                end
                msg = string.gsub(msg, "Hspell:", "£TMP£", 1)
            end
            
            msg = string.gsub(msg, "£TMP£", "Hspell:")
        end
    end
    if string.find(msg, "Henchant:") then
        if chatFrame and chatFrame.historyBuffer and #(chatFrame.historyBuffer.elements) > 0 and chatFrame ~= _G.ChatFrame2 then
            while (string.find(msg, "Henchant:")) do
                local id, name = string.match(msg, "^.-Henchant:(%d+).-%[(.-)%]")
                local spellInfo = C_Spell.GetSpellInfo(tonumber(id))
                local spellData = spellInfo.name
                if (spellData) then
                    msg = string.gsub(msg, regexEscape(name .. "]"), spellData .. " (" .. name .. ")]", 1)
                end
                msg = string.gsub(msg, "Henchant:", "£TMP£", 1)
            end
            
            msg = string.gsub(msg, "£TMP£", "Henchant:")
        end
    end

    if string.find(msg, "Hachievement:") then
        if chatFrame and chatFrame.historyBuffer and #(chatFrame.historyBuffer.elements) > 0 and chatFrame ~= _G.ChatFrame2 then
            while (string.find(msg, "Hachievement:")) do
                local id, name = string.match(msg, "^.-Hachievement:(%d+):.-%[(.-)%]")
                local _, achievementData = GetAchievementInfo(tonumber(id))
                if (achievementData) then
                    translatedName = string.gsub(achievementData, "（", " (").gsub(achievementData, "）", ")")
                    msg = string.gsub(msg, regexEscape(name .. "]"), translatedName .. " (" .. name .. ")]", 1)
                end
                msg = string.gsub(msg, "Hachievement:", "£TMP£", 1)
            end
            
            msg = string.gsub(msg, "£TMP£", "Hachievement:")
        end
    end

    return false, msg, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, senderGUID, bnSenderID, ...
end

function RegisterChatFilterEvents() -- todo: register immediately and cache calls until db is available
    -- The message filter that triggers the above local function
    -- Party
    ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", ChatFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", ChatFilter)

    -- Raid
    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", ChatFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", ChatFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_WARNING", ChatFilter)

    -- Guild
    ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", ChatFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", ChatFilter)

    -- Battleground
    ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", ChatFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", ChatFilter)

    -- Whisper
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", ChatFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ChatFilter)

    -- Battle Net
    ChatFrame_AddMessageEventFilter("CHAT_MSG_BN", ChatFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", ChatFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", ChatFilter)

    -- Open world
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", ChatFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", ChatFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", ChatFilter)

    -- Emote
    ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", ChatFilter)

    -- System
    --ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", ChatFilter)
end