local addonName, LootLogger = ...
local LDB = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")

LootLogger.MinimapIcon = LootLogger.MinimapIcon or {}

local minimapIconLDB = nil

function LootLogger.MinimapIcon:Init()
    minimapIconLDB = LDB:NewDataObject(addonName, {
        type = "launcher",
        icon = "Interface\\Icons\\INV_Misc_Bag_10",
        OnClick = function(_, button)
            if button == "LeftButton" then
                LootLogger.UI:ToggleMainFrame()
            elseif button == "RightButton" then
                -- Open options menu (if you have one)
                -- Otherwise, you can use this for another function
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("LootLogger")
            tooltip:AddLine("Left-click to toggle the main window")
            tooltip:AddLine("Right-click to open options")
        end,
    })

    DBIcon:Register(addonName, minimapIconLDB, LootLoggerDB.minimapIcon)
end

function LootLogger.MinimapIcon:Toggle()
    LootLoggerDB.minimapIcon.hide = not LootLoggerDB.minimapIcon.hide
    if LootLoggerDB.minimapIcon.hide then
        DBIcon:Hide(addonName)
    else
        DBIcon:Show(addonName)
    end
end