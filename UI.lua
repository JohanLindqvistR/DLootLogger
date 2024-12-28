-- File: UI.lua

local _, LootLogger = ...

LootLogger.UI = LootLogger.UI or {}

local mainFrame = nil
local lootTable = nil
local sortOrder = {}

function LootLogger.UI:Init()
    self:CreateMainFrame()
end

function LootLogger.UI:CreateMainFrame()
    mainFrame = CreateFrame("Frame", "LootLoggerMainFrame", UIParent, "BasicFrameTemplateWithInset")
    mainFrame:SetSize(1000, 600)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:Hide()

    -- Title
    mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY")
    mainFrame.title:SetFontObject("GameFontHighlight")
    mainFrame.title:SetPoint("TOPLEFT", 5, -5)
    mainFrame.title:SetText("LootLogger")

    -- Add session display
    mainFrame.sessionDisplay = mainFrame:CreateFontString(nil, "OVERLAY")
    mainFrame.sessionDisplay:SetFontObject("GameFontNormal")
    mainFrame.sessionDisplay:SetPoint("TOPLEFT", 10, -25)

	-- Create session management frame
    local sessionFrame = CreateFrame("Frame", nil, mainFrame)
    sessionFrame:SetPoint("TOPRIGHT", -10, -25)
    sessionFrame:SetSize(420, 30)

	-- Create session dropdown
    local sessionDropdown = CreateFrame("Frame", "LootLoggerSessionDropdown", sessionFrame, "UIDropDownMenuTemplate")
    sessionDropdown:SetPoint("TOPRIGHT", 0, -2)
    UIDropDownMenu_SetWidth(sessionDropdown, 200)
    UIDropDownMenu_SetText(sessionDropdown, "Select Session")
    UIDropDownMenu_Initialize(sessionDropdown, function(self, level) LootLogger.UI:InitializeSessionDropdown(self, level) end)

    -- Create new session button
    local newSessionButton = CreateFrame("Button", nil, sessionFrame, "UIPanelButtonTemplate")
    newSessionButton:SetSize(100, 22)
    newSessionButton:SetPoint("RIGHT", sessionDropdown, "LEFT", -10, 0)
    newSessionButton:SetText("New Session")
    newSessionButton:SetScript("OnClick", function()
        StaticPopup_Show("LOOTLOGGER_NEW_SESSION")
    end)

    -- Create rename session button
    local renameSessionButton = CreateFrame("Button", nil, sessionFrame, "UIPanelButtonTemplate")
    renameSessionButton:SetSize(100, 22)
    renameSessionButton:SetPoint("RIGHT", newSessionButton, "LEFT", -10, 0)
    renameSessionButton:SetText("Rename")
    renameSessionButton:SetScript("OnClick", function()
        StaticPopup_Show("LOOTLOGGER_RENAME_SESSION")
    end)
    
	-- Create fixed header frame
    local headerFrame = CreateFrame("Frame", nil, mainFrame)
    headerFrame:SetPoint("TOPLEFT", 10, -60)
    headerFrame:SetPoint("TOPRIGHT", -30, -60)
    headerFrame:SetHeight(20)

    -- Headers
    local headers = {"Player", "Item", "Boss", "Time"}
    local headerWidth = (headerFrame:GetWidth()) / #headers
    for i, header in ipairs(headers) do
        local headerButton = CreateFrame("Button", nil, headerFrame)
        headerButton:SetSize(headerWidth, 20)
        headerButton:SetPoint("TOPLEFT", (i-1) * headerWidth, 0)
        
        headerButton:SetScript("OnClick", function()
            self:SortLootData(header:lower())
        end)

        local headerText = headerButton:CreateFontString(nil, "OVERLAY")
        headerText:SetFontObject("GameFontNormal")
        headerText:SetPoint("LEFT", 5, 0)
        headerText:SetText(header)
    end

    -- Create ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", nil, mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT", 0, -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)

    -- Create content frame
    lootTable = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(lootTable)
    lootTable:SetSize(scrollFrame:GetWidth(), scrollFrame:GetHeight())

    -- Buttons
    local buttonWidth = 100
    local buttonHeight = 25
    local buttonSpacing = 10

    -- Reset Button
    local resetButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    resetButton:SetSize(buttonWidth, buttonHeight)
    resetButton:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 10, 10)
    resetButton:SetText("Delete Session")
    resetButton:SetScript("OnClick", function()
        StaticPopup_Show("LOOTLOGGER_CONFIRM_RESET")
    end)

    -- Export Button
    local exportButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    exportButton:SetSize(buttonWidth, buttonHeight)
    exportButton:SetPoint("LEFT", resetButton, "RIGHT", buttonSpacing, 0)
    exportButton:SetText("Export")
    exportButton:SetScript("OnClick", function()
        self:ShowExportFrame()
    end)

    self:CreateConfirmResetDialog()
    self:CreateNewSessionDialog()
end

function LootLogger.UI:UpdateMainFrame()
    local lootData = LootLogger.Database:GetSortedLootData()
    self:PopulateLootTable(lootData)
    
    -- Update session display
    local currentSession = LootLogger.Database:GetCurrentSession()
    mainFrame.sessionDisplay:SetText("Current Session: " .. (currentSession or "None"))

    -- Update session dropdown
    UIDropDownMenu_SetText(LootLoggerSessionDropdown, currentSession or "Select Session")
    UIDropDownMenu_Initialize(LootLoggerSessionDropdown, self.InitializeSessionDropdown)
end

function LootLogger.UI:InitializeSessionDropdown(dropdown, level)
    local info = UIDropDownMenu_CreateInfo()
    local sessions = LootLogger.Database:GetSessions()
    local currentSession = LootLogger.Database:GetCurrentSession()
    
    for _, session in ipairs(sessions) do
        info.text = session
        info.func = function(self)
            LootLogger.Database:LoadSession(self.value)
            LootLogger.UI:UpdateMainFrame()
            CloseDropDownMenus()
        end
        info.value = session
        info.checked = (session == currentSession)
        UIDropDownMenu_AddButton(info, level)
    end
end

function LootLogger.UI:CreateNewSessionDialog()
    StaticPopupDialogs["LOOTLOGGER_NEW_SESSION"] = {
        text = "Enter a name for the new session:",
        button1 = "Create",
        button2 = "Cancel",
        hasEditBox = true,
        editBoxWidth = 150,
        OnAccept = function(self)
            local sessionName = self.editBox:GetText()
            if LootLogger.Database:StartNewSession(sessionName) then
                LootLogger.UI:UpdateMainFrame()
            end
        end,
        OnShow = function(self)
            self.editBox:SetText("")
            self.editBox:SetFocus()
        end,
        OnHide = function(self)
            self.editBox:SetText("")
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            local sessionName = parent.editBox:GetText()
            if LootLogger.Database:StartNewSession(sessionName) then
                LootLogger.UI:UpdateMainFrame()
            end
            parent:Hide()
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

function LootLogger.UI:PopulateLootTable(lootData)
    -- Clear existing rows
    for i = lootTable:GetNumChildren(), 1, -1 do
        local child = select(i, lootTable:GetChildren())
        if child.isLootRow then
            child:Hide()
            child:SetParent(nil)
        end
    end

    -- Add new rows
    local rowHeight = 20
    local columnWidth = (lootTable:GetWidth()) / 4
    for i, data in ipairs(lootData) do
        local row = CreateFrame("Button", nil, lootTable)
        row:SetSize(lootTable:GetWidth(), rowHeight)
        row:SetPoint("TOPLEFT", 0, -(i-1) * rowHeight)
        row.isLootRow = true
        
        -- Create highlight texture
        row.highlightTexture = row:CreateTexture(nil, "HIGHLIGHT")
        row.highlightTexture:SetAllPoints(row)
        row.highlightTexture:SetColorTexture(1, 1, 0, 0.3) -- Yellow with 30% opacity
        row:SetHighlightTexture(row.highlightTexture)

        local playerText = row:CreateFontString(nil, "OVERLAY")
        playerText:SetFontObject("GameFontHighlight")
        playerText:SetPoint("LEFT", 5, 0)
        playerText:SetText(data.player)

        local itemText = row:CreateFontString(nil, "OVERLAY")
        itemText:SetFontObject("GameFontHighlight")
        itemText:SetPoint("LEFT", columnWidth, 0)
        itemText:SetText(data.item)

        local bossText = row:CreateFontString(nil, "OVERLAY")
        bossText:SetFontObject("GameFontHighlight")
        bossText:SetPoint("LEFT", columnWidth * 2, 0)
        bossText:SetText(data.boss)

        local timeText = row:CreateFontString(nil, "OVERLAY")
        timeText:SetFontObject("GameFontHighlight")
        timeText:SetPoint("LEFT", columnWidth * 3, 0)
        timeText:SetText(data.time)

        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_CENTER")
            GameTooltip:SetHyperlink(data.item)
            GameTooltip:Show()
        end)
        
        row:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        row:SetScript("OnClick", function(self, button)
            if button == "LeftButton" then
                ChatEdit_InsertLink(data.item)
            end
        end)

        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    end

    lootTable:SetHeight(#lootData * rowHeight)
end

function LootLogger.UI:ConfirmDeleteItem(data)
    StaticPopup_Show("LOOTLOGGER_CONFIRM_DELETE", data.item, data.player, data)
end

function LootLogger.UI:ShowExportFrame()
    if not self.exportFrame then
        local exportFrame = CreateFrame("Frame", "LootLoggerExportFrame", UIParent, "BasicFrameTemplateWithInset")
        self.exportFrame = exportFrame
        exportFrame:SetSize(400, 300)
        exportFrame:SetPoint("CENTER")
        
        exportFrame:SetFrameStrata("DIALOG")
        exportFrame:SetFrameLevel(100)
        
        exportFrame:SetMovable(true)
        exportFrame:EnableMouse(true)
        exportFrame:RegisterForDrag("LeftButton")
        exportFrame:SetScript("OnDragStart", exportFrame.StartMoving)
        exportFrame:SetScript("OnDragStop", exportFrame.StopMovingOrSizing)

        exportFrame.title = exportFrame:CreateFontString(nil, "OVERLAY")
        exportFrame.title:SetFontObject("GameFontHighlight")
        exportFrame.title:SetPoint("LEFT", exportFrame.TitleBg, "LEFT", 5, 0)
        exportFrame.title:SetText("Export Loot Data")

        local scrollFrame = CreateFrame("ScrollFrame", nil, exportFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -30)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)

        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetFontObject(ChatFontNormal)
        editBox:SetWidth(scrollFrame:GetWidth())
        scrollFrame:SetScrollChild(editBox)

        self.exportEditBox = editBox
    end

    -- Always fetch fresh data when showing the export frame
    local exportData = LootLogger.Database:ExportData()
    self.exportEditBox:SetText(exportData)
    self.exportEditBox:HighlightText()

    self.exportFrame:Show()
end

function LootLogger.UI:SortLootData(column)
    if sortOrder[column] == nil then
        sortOrder[column] = true
    else
        sortOrder[column] = not sortOrder[column]
    end

    local lootData = LootLogger.Database:GetSortedLootData()
    table.sort(lootData, function(a, b)
        if sortOrder[column] then
            return a[column] < b[column]
        else
            return a[column] > b[column]
        end
    end)

    self:PopulateLootTable(lootData)
end

-- Modify the ToggleMainFrame function to handle the global click catcher
function LootLogger.UI:ToggleMainFrame()
    if mainFrame:IsVisible() then
        mainFrame:Hide()
    else
        self:UpdateMainFrame()
        mainFrame:Show()
    end
end

function LootLogger.UI:CreateConfirmResetDialog()

    StaticPopupDialogs["LOOTLOGGER_RENAME_SESSION"] = {
        text = "Enter a new name for the current session:",
        button1 = "Rename",
        button2 = "Cancel",
        hasEditBox = true,
        editBoxWidth = 150,
        OnAccept = function(self)
            local newName = self.editBox:GetText()
            if LootLogger.Database:RenameCurrentSession(newName) then
                LootLogger.UI:UpdateMainFrame()
            end
        end,
        OnShow = function(self)
            self.editBox:SetText(LootLogger.Database:GetCurrentSession())
            self.editBox:HighlightText()
            self.editBox:SetFocus()
        end,
        OnHide = function(self)
            self.editBox:SetText("")
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            local newName = parent.editBox:GetText()
            if LootLogger.Database:RenameCurrentSession(newName) then
                LootLogger.UI:UpdateMainFrame()
            end
            parent:Hide()
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs["LOOTLOGGER_CONFIRM_RESET"] = {
        text = "Are you sure you want to delete the current session? This action cannot be undone.",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            if LootLogger.Database:ResetCurrentSession() then
                self:UpdateMainFrame()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs["LOOTLOGGER_CONFIRM_DELETE"] = {
        text = "Are you sure you want to delete %s from %s?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function(self, data)
            if LootLogger.Database:DeleteItem(data.player, data.item) then
                print("Deleted " .. data.item .. " from " .. data.player)
                LootLogger.UI:UpdateMainFrame()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

