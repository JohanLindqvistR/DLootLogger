-- File: LootLogger.lua (Main file)

local AddonName, LootLogger = ...

-- Initialize addon components
LootLogger.Utils = LootLogger.Utils or {}
LootLogger.Database = LootLogger.Database or {}
LootLogger.UI = LootLogger.UI or {}
LootLogger.MinimapIcon = LootLogger.MinimapIcon or {}

-- Main initialization function
function LootLogger:Init()
    if self.Database.Init then
        self.Database:Init()
    else
        print("LootLogger: Database component not properly loaded")
    end

    if self.UI.Init then
        self.UI:Init()
    else
        print("LootLogger: UI component not properly loaded")
    end
	
    if self.MinimapIcon.Init then
        self.MinimapIcon:Init()
    else
        print("LootLogger: MinimapIcon component not properly loaded")
    end
    if ChatAnnounce == nil then
        ChatAnnounce = false
    end
    self:RegisterEvents()
end

-- Register necessary events
function LootLogger:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_LOOT")
    frame:RegisterEvent("ENCOUNTER_END")
    frame:RegisterEvent("RAID_INSTANCE_WELCOME")    
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "ADDON_LOADED" and ... == AddonName then
            self:OnAddonLoaded()
        elseif event == "CHAT_MSG_LOOT" then
            self:OnLootMessage(...)
        elseif event == "RAID_INSTANCE_WELCOME" then
            self:OnRaidMessage(...)
        elseif event == "ENCOUNTER_END" then
            self:OnEncounterEnd(...)
        end
    end)
end

-- Handler for when the addon is loaded
function LootLogger:OnAddonLoaded()
    self.Database:Load()
    print(AddonName .. " loaded successfully!")
end

-- Handler for entering raid
function LootLogger:OnRaidMessage(...)
    local zone = ...
    local sessiondate = date("%Y-%m-%d")
    local sessionname = zone .. " " .. sessiondate
    print(zone .. " entered!")
    if LootLogger.Database:LoadSession(sessionname) then
        LootLogger.UI:UpdateMainFrame()
    elseif LootLogger.Database:StartNewSession(sessionname) then
        LootLogger.UI:UpdateMainFrame()
    end
end

-- Handler for loot messages
function LootLogger:OnLootMessage(...)
    local message = ...
    local player, itemLink = self.Utils.ParseLootMessage(message)

    if player and itemLink then
        self.Database:RecordLoot(player, itemLink)
        self.UI:UpdateMainFrame()
        if ChatAnnounce then
            SendChatMessage(player .. " has won need roll: " .. itemLink, IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or IsInRaid() and "RAID" or "PARTY")
        end
    end
end

-- Handler for encounter end
function LootLogger:OnEncounterEnd(...)
    local encounterID, encounterName, difficultyID, raidSize, success = ...
    if success == 1 then
        self.Database:SetLastEncounteredBoss(encounterName)
        print("LootLogger: Encounter ended, boss defeated: " .. encounterName)
    end
end

-- Function to handle item trades
function LootLogger:TradeItem(player1, player2, item)
    if self.Database:TradeItem(player1, player2, item) then
        print(player1 .. " has traded " .. item .. " to " .. player2 .. ".")
        self.UI:UpdateMainFrame()
    else
        print("Error: Unable to complete the trade.")
    end
end

-- Function to delete an item from a player's loot
function LootLogger:DeleteItem(player, item)
    if self.Database:DeleteItem(player, item) then
        print("Deleted " .. item .. " from " .. player)
        self.UI:UpdateMainFrame()
    else
        print("Error: Unable to delete the item.")
    end
end

-- Function to bark loot information
function LootLogger:BarkLoot(player, chatType)
    local lootData = self.Database:GetPlayerLoot(player)
    if lootData then
        local lootDetails = {"Loot won by " .. player .. ":"}
        for _, itemData in ipairs(lootData.itemsWon) do
            table.insert(lootDetails, "- " .. itemData.item .. " from " .. itemData.boss .. " on " .. itemData.timestamp)
        end

        for _, line in ipairs(lootDetails) do
            if chatType == "WHISPER" then
                SendChatMessage(line, "WHISPER", nil, player)
            elseif chatType == "RAID" then
                SendChatMessage(line, "RAID")
            elseif chatType == "OFFICER" then
                SendChatMessage(line, "OFFICER")
            elseif chatType == "SAY" then
                SendChatMessage(line, "SAY")
            end
        end
    else
        print("No loot data found for player: " .. player)
    end
end

-- Register slash commands
SLASH_LOOTLOGGER1 = "/lootlog"
SlashCmdList["LOOTLOGGER"] = function(msg)
    local command, arg = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()

    if command == "minimap" then
        LootLogger.MinimapIcon:Toggle()
    elseif command == "chat" then
        if arg and arg == "toogle" then
            ChatAnnounce = not ChatAnnounce
        end
        print("DLootLogger: Chat announcements are " .. tostring(ChatAnnounce))
    elseif command == "newsession" then
        if arg and arg ~= "" then
            if LootLogger.Database:StartNewSession(arg) then
                LootLogger.UI:UpdateMainFrame()
            end
        else
            print("Usage: /lootlog newsession <session name>")
        end
    elseif command == "loadsession" then
        if arg and arg ~= "" then
            if LootLogger.Database:LoadSession(arg) then
                LootLogger.UI:UpdateMainFrame()
            end
        else
            print("Usage: /lootlog loadsession <session name>")
        end
    elseif command == "listsessions" then
        local sessions = LootLogger.Database:GetSessions()
        print("Available sessions:")
        for _, session in ipairs(sessions) do
            print("- " .. session)
        end
    else
        LootLogger.UI:ToggleMainFrame()
    end
end

-- Initialize the addon
LootLogger:Init()
