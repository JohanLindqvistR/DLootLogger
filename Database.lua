-- File: Database.lua

local _, LootLogger = ...

LootLogger.Database = LootLogger.Database or {}

local playerLootWins = {}
local lastEncounteredBoss = nil
local databaseCreatedTimestamp = nil
local currentSession = nil
local sessions = {}

function LootLogger.Database:Init()
    -- Initialize database
    if not LootLoggerDB then
        self:Reset()
    end
end

function LootLogger.Database:Load()
    if LootLoggerDB then
        sessions = LootLoggerDB.sessions or {}
        databaseCreatedTimestamp = LootLoggerDB.createdTimestamp or time()
        currentSession = LootLoggerDB.currentSession
        if currentSession and sessions[currentSession] then
            playerLootWins = sessions[currentSession].lootData
            lastEncounteredBoss = sessions[currentSession].lastBoss
        else
            self:StartNewSession("Default")
        end
    else
        self:Reset()
    end
end

function LootLogger.Database:Save()
    if currentSession then
        sessions[currentSession] = {
            lootData = playerLootWins,
            lastBoss = lastEncounteredBoss
        }
    end
    LootLoggerDB = {
        sessions = sessions,
        currentSession = currentSession,
        createdTimestamp = databaseCreatedTimestamp
    }
end

function LootLogger.Database:Reset()
    sessions = {}
    databaseCreatedTimestamp = time()
    self:StartNewSession("Default")
    self:Save()
end

function LootLogger.Database:RenameCurrentSession(newName)
    if not currentSession then
        print("No active session to rename.")
        return false
    end

    if sessions[newName] then
        print("A session with the name '" .. newName .. "' already exists.")
        return false
    end

    local oldName = currentSession
    sessions[newName] = sessions[currentSession]
    sessions[currentSession] = nil
    currentSession = newName

    self:Save()
    print("Session renamed from '" .. oldName .. "' to '" .. newName .. "'.")
    return true
end

function LootLogger.Database:ResetCurrentSession()
    if currentSession then
        local sessionToDelete = currentSession
        sessions[sessionToDelete] = nil
        
        -- Switch to "Default" session or create a new one
        if sessionToDelete ~= "Default" and sessions["Default"] then
            self:LoadSession("Default")
        else
            self:StartNewSession("Default")
        end
        
        self:Save()
        print("Session '" .. sessionToDelete .. "' has been deleted.")
        return true
    else
        print("No active session to reset.")
        return false
    end
end

function LootLogger.Database:StartNewSession(sessionName)
    if not sessionName or sessionName == "" then
        sessionName = "Session_" .. date("%Y-%m-%d_%H-%M-%S")
    end
    
    if sessions[sessionName] then
        print("Session name already exists. Please choose a different name.")
        return false
    end
    
    currentSession = sessionName
    playerLootWins = {}
    lastEncounteredBoss = nil
    sessions[currentSession] = {
        lootData = playerLootWins,
        lastBoss = lastEncounteredBoss
    }
    self:Save()
    print("New LootLogger session started: " .. currentSession)
    return true
end

function LootLogger.Database:LoadSession(sessionName)
    if sessions[sessionName] then
        currentSession = sessionName
        playerLootWins = sessions[sessionName].lootData
        lastEncounteredBoss = sessions[sessionName].lastBoss
        self:Save()
        print("Loaded LootLogger session: " .. sessionName)
        return true
    else
        print("Session not found: " .. sessionName)
        return false
    end
end

function LootLogger.Database:GetSessions()
    local sessionList = {}
    for sessionName, _ in pairs(sessions) do
        table.insert(sessionList, sessionName)
    end
    return sessionList
end

function LootLogger.Database:GetCurrentSession()
    return currentSession
end

function LootLogger.Database:RecordLoot(player, itemLink)
    if not playerLootWins[player] then
        playerLootWins[player] = {
            totalWins = 0,
            itemsWon = {}
        }
    end

    local bossName = lastEncounteredBoss or "Unknown"
    local timestamp = LootLogger.Utils.GetFormattedDateTime()
    
    table.insert(playerLootWins[player].itemsWon, {
        item = itemLink,
        boss = bossName,
        timestamp = timestamp
    })
    
    playerLootWins[player].totalWins = playerLootWins[player].totalWins + 1
    
    self:Save()
    print(player .. " has won: " .. itemLink .. " from " .. bossName .. " at " .. timestamp)
end

function LootLogger.Database:SetLastEncounteredBoss(bossName)
    lastEncounteredBoss = bossName
end

function LootLogger.Database:GetLootData()
    return LootLogger.Utils.DeepCopy(playerLootWins)
end

function LootLogger.Database:GetCreationTimestamp()
    return databaseCreatedTimestamp
end

function LootLogger.Database:GetPlayerLoot(player)
    return LootLogger.Utils.DeepCopy(playerLootWins[player])
end

function LootLogger.Database:TradeItem(player1, player2, item)
    if not playerLootWins[player1] then
        print("Error: Player1 (" .. player1 .. ") does not exist in the loot table.")
        return false
    end

    local itemIndex = nil
    local itemData = nil
    for i, wonItem in ipairs(playerLootWins[player1].itemsWon) do
        if wonItem.item == item then
            itemIndex = i
            itemData = LootLogger.Utils.DeepCopy(wonItem)
            break
        end
    end

    if not itemIndex then
        print("Error: Player1 (" .. player1 .. ") does not have the item: " .. item)
        return false
    end

    if not playerLootWins[player2] then
        playerLootWins[player2] = {
            totalWins = 0,
            itemsWon = {}
        }
    end

    table.insert(playerLootWins[player2].itemsWon, itemData)
    playerLootWins[player2].totalWins = playerLootWins[player2].totalWins + 1

    table.remove(playerLootWins[player1].itemsWon, itemIndex)
    playerLootWins[player1].totalWins = playerLootWins[player1].totalWins - 1

    self:Save()
    return true
end

function LootLogger.Database:DeleteItem(player, item)
    if not playerLootWins[player] then
        print("Error: Player (" .. player .. ") does not exist in the loot table.")
        return false
    end

    for i, wonItem in ipairs(playerLootWins[player].itemsWon) do
        if wonItem.item == item then
            table.remove(playerLootWins[player].itemsWon, i)
            playerLootWins[player].totalWins = playerLootWins[player].totalWins - 1
            self:Save()
            return true
        end
    end

    print("Error: Item (" .. item .. ") not found for player (" .. player .. ").")
    return false
end

function LootLogger.Database:GetSortedLootData()
    local sortedData = {}
    for player, data in pairs(playerLootWins) do
        for _, itemData in ipairs(data.itemsWon) do
            table.insert(sortedData, {
                player = player,
                item = itemData.item,
                boss = itemData.boss,
                time = itemData.timestamp,
            })
        end
    end
    return sortedData
end

function LootLogger.Database:ExportData()
    local exportString = ""
    for player, data in pairs(playerLootWins) do
        for _, itemData in ipairs(data.itemsWon) do
            exportString = exportString .. player .. ";" .. itemData.item .. ";" .. itemData.boss .. ";" .. itemData.timestamp .. ")\n"
        end
    end
    return exportString
end
function LootLogger.Database:ImportData(importString)
    -- This is a basic implementation. You might want to add more error checking and validation.
    local newData = {}
    local currentPlayer = nil
    
    for line in importString:gmatch("[^\r\n]+") do
        local player, totalWins = line:match("^(.+) has won (%d+) item%(s%):")
        if player and totalWins then
            currentPlayer = player
            newData[currentPlayer] = {
                totalWins = tonumber(totalWins),
                itemsWon = {}
            }
        elseif currentPlayer then
            local item, boss, timestamp = line:match("^  %- (.+) %(Boss: (.+), Time: (.+)%)$")
            if item and boss and timestamp then
                table.insert(newData[currentPlayer].itemsWon, {
                    item = item,
                    boss = boss,
                    timestamp = timestamp
                })
            end
        end
    end
    
    playerLootWins = newData
    self:Save()
    print("LootLogger: Data imported successfully.")
end
