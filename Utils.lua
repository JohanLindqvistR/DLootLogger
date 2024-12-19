-- File: Utils.lua

local _, LootLogger = ...

LootLogger.Utils = {}

-- Function to strip UI escape sequences from text
function LootLogger.Utils.StripUIEscapeSequences(text)
    -- Remove color codes
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    -- Remove the "|r" used to end a color sequence
    text = text:gsub("|r", "")
    -- Remove textures (|TtexturePath|t)
    text = text:gsub("|T.-|t", "")
    -- Remove hyperlinks (|Hsomething|htext|h)
    text = text:gsub("|H.-|h(.-)|h", "%1")
    -- Remove any remaining pipe sequences (|A, |K, etc.)
    text = text:gsub("|[A-Za-z0-9%-]+", "")

    return text
end

-- Function to parse loot messages
function LootLogger.Utils.ParseLootMessage(message)
    local strippedMsg = LootLogger.Utils.StripUIEscapeSequences(message)
    local player, itemLink = string.match(strippedMsg, "%[Loot%]: (.+) %(Need .* Main%-Spec%) Won: (.+)")
	itemLink = string.match(message, ".* Won: (.+)")
    
    if player and itemLink then
        if player == "You" then
            player = UnitName("player")
        end
        return player, itemLink
    end
    
    return nil, nil
end

-- Function to create a highlight texture for UI elements
function LootLogger.Utils.CreateHighlightTexture(frame)
    local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(frame)
    highlight:SetColorTexture(1, 1, 0, 0.3) -- Yellow with 30% opacity for better visibility
    highlight:Hide()
    return highlight
end

-- Function to get the current date and time as a formatted string
function LootLogger.Utils.GetFormattedDateTime()
    return date("%Y-%m-%d %H:%M:%S")
end

-- Function to validate a player name
function LootLogger.Utils.IsValidPlayerName(name)
    -- Check if the name is not empty and contains only allowed characters
    return name and name:match("^[a-zA-Z][a-zA-Z0-9%-]*$") ~= nil
end

-- Function to truncate a string to a certain length
function LootLogger.Utils.TruncateString(str, length)
    if #str <= length then
        return str
    else
        return str:sub(1, length - 3) .. "..."
    end
end

-- Function to create a deep copy of a table
function LootLogger.Utils.DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[LootLogger.Utils.DeepCopy(orig_key)] = LootLogger.Utils.DeepCopy(orig_value)
        end
        setmetatable(copy, LootLogger.Utils.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Function to merge two tables
function LootLogger.Utils.MergeTables(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            LootLogger.Utils.MergeTables(t1[k], v)
        else
            t1[k] = v
        end
    end
    return t1
end

-- Function to check if a value exists in a table
function LootLogger.Utils.TableContains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Function to get the size of a table (including non-integer keys)
function LootLogger.Utils.TableSize(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end
