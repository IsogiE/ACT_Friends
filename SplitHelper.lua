local SplitHelper = {}

SplitHelper.characterRows = {} 


SplitHelper.title = "Split Helper"

function SplitHelper:GetConfigSize()
    return 1000, 600 
end

function SplitHelper:CreateConfigPanel(parent)
    if self.configPanel then
        self.configPanel:SetParent(parent)
        self.configPanel:ClearAllPoints()
        self.configPanel:SetAllPoints(parent)
        self.configPanel:Show()
        return self.configPanel
    end

    local configPanel = CreateFrame("Frame", nil, parent)
    configPanel:SetAllPoints(parent)

    local title = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", configPanel, "TOPLEFT", 20, 16)
    title:SetText("Split Helper")

    local importBoxFrame, importEditBox = UI:CreateMultilineEditBox(configPanel, 520, 60, "")
    importBoxFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    self.importBox = importEditBox
    
    errorHandler = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    errorHandler:SetPoint("TOPRIGHT", importBoxFrame, "BOTTOMRIGHT", 0, -5)

    local importButton = UI:CreateButton(configPanel, "Import", 120, 30)
    importButton:SetPoint("TOPLEFT", importBoxFrame, "BOTTOMLEFT", 0, -10)

    local scrollFrame = CreateFrame("ScrollFrame", nil, configPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(520, 400)
    scrollFrame:SetPoint("TOPLEFT", importButton, "BOTTOMLEFT", 0, -50)
    scrollbar = scrollFrame.ScrollBar
    scrollbar:Hide()

    self.scrollContent = CreateFrame("Frame", nil, scrollFrame) 
    self.scrollContent:SetSize(520, 300) 
    scrollFrame:SetScrollChild(self.scrollContent)

    self.resultText = self.scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.resultText:SetSize(500, 290)
    self.resultText:SetPoint("TOPLEFT", 10, -10)
    self.resultText:SetJustifyH("LEFT")
    self.resultText:SetJustifyV("TOP")
    self.resultText:SetWordWrap(true)

    local headerFrame = CreateFrame("Frame", nil, configPanel)
    headerFrame:SetSize(700, 20)
    headerFrame:SetPoint("TOPLEFT", importButton, "BOTTOMLEFT", 0, -30)

    local expectedHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    expectedHeader:SetPoint("LEFT", headerFrame, "LEFT", 0, -20)
    expectedHeader:SetText("Expected Characters:")

    local unexpectedHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    unexpectedHeader:SetPoint("RIGHT", headerFrame, "RIGHT", 0, -20)
    unexpectedHeader:SetText("Unexpected Characters:")

    self.splitDropdown = UI:CreateDropdown(configPanel, 520, 30)
    self.splitDropdown:SetPoint("TOPLEFT", importButton, "BOTTOMLEFT", 0, -10)
    self.splitDropdown.button.text:SetText("Select Split")

    local deleteButton = UI:CreateButton(configPanel, "Delete Split", 120, 30)
    deleteButton:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMLEFT", 0, 10)

    local renameButton = UI:CreateButton(configPanel, "Rename", 100, 30)
    renameButton:SetPoint("LEFT", self.splitDropdown, "RIGHT", 10, 0)

    local checkButton = UI:CreateButton(configPanel, "Refresh", 100, 30)
    checkButton:SetPoint("LEFT", renameButton, "RIGHT", 10, 0)

    local unexpectedScrollFrame = CreateFrame("ScrollFrame", nil, configPanel, "UIPanelScrollFrameTemplate")
    unexpectedScrollFrame:SetSize(140, 300)
    unexpectedScrollFrame:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 40, -30) 

    self.unexpectedScrollContent = CreateFrame("Frame", nil, unexpectedScrollFrame) 
    self.unexpectedScrollContent:SetSize(520, 300) 
    unexpectedScrollFrame:SetScrollChild(self.unexpectedScrollContent)

    self.unexpectedResultText = self.unexpectedScrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.unexpectedResultText:SetSize(500, 290)
    self.unexpectedResultText:SetPoint("TOPLEFT", 10, -10)
    self.unexpectedResultText:SetJustifyH("LEFT")
    self.unexpectedResultText:SetJustifyV("TOP")
    self.unexpectedResultText:SetWordWrap(true)

    self:UpdateDropdown()

    importButton:SetScript("OnClick", function()
        local characterString = self.importBox:GetText()
        if characterString ~= "" then
            self:ProcessCharacterString(characterString)
            self.importBox:SetText("")
            self:UpdateDropdown()
            self:DisplayImportedCharacters()
        end
    end)

    deleteButton:SetScript("OnClick", function()
        if self.selectedIndex then
            self:ClearData(self.selectedIndex)
            self:CheckCharacters()
        end
    end)

    renameButton:SetScript("OnClick", function()
        if self.selectedIndex then
            self:ShowRenamePopup(self.selectedIndex)
        end
    end)

    checkButton:SetScript("OnClick", function()
        if self.selectedIndex then
            self:CheckCharacters()
        end
    end)

    if not ACT.db.profile.splits then
        ACT.db.profile.splits = {
            profiles = {},
            KeepPosInGroup = true
        }
    end

    self.configPanel = configPanel
    return configPanel
end

function SplitHelper:DisplayImportedCharacters()
    if not self.selectedIndex then return end
    local profile = ACT.db.profile.splits.profiles[self.selectedIndex]
    if not profile then return end

    for _, child in ipairs({self.scrollContent:GetChildren()}) do
        child:Hide() 
    end

    for _, child in ipairs({self.unexpectedScrollContent:GetChildren()}) do
        child:Hide() 
    end

    local inBoth, inSheetNotRaid, inRaidNotSheet, unexpectedPlayers = self:CompareAndColorCharacters(self:GetRaidCharacters(), profile.characters)
    self:PrintColoredCharacters(inBoth, inSheetNotRaid, inRaidNotSheet)

    self:PrintUnexpectedCharacters(unexpectedPlayers)
end

function SplitHelper:ProcessCharacterString(characterString)
    local characters = {}
    for char in string.gmatch(characterString, '([^,]+)') do
        table.insert(characters, strtrim(char))
    end

    if #characters > 40 then
        errorHandler:SetText("Error: You can only import up to 40 players!")
        return
    end

    errorHandler:SetText("")

    table.insert(ACT.db.profile.splits.profiles, {
        name = "Import " .. (#ACT.db.profile.splits.profiles + 1),
        characters = characters
    })
end

function SplitHelper:UpdateDropdown()
    local options = {}
    for i, profile in ipairs(ACT.db.profile.splits.profiles) do
        table.insert(options, {
            text = profile.name,
            value = i,
            onClick = function()
                self.selectedIndex = i
                self.splitDropdown.button.text:SetText(profile.name)
                self:DisplayImportedCharacters()
            end
        })
    end
    UI:SetDropdownOptions(self.splitDropdown, options)
end

function SplitHelper:GetRaidCharacters()
    local raidCharacters = {}
    for i = 1, GetNumGroupMembers() do
        local name = GetRaidRosterInfo(i)
        if name then
            table.insert(raidCharacters, strtrim(name))
        end
    end
    return raidCharacters
end

function SplitHelper:StripRealmNames(characters)
    local strippedCharacters = {}
    for _, character in ipairs(characters) do
        local baseName = strsplit("-", character)
        table.insert(strippedCharacters, baseName)
    end
    return strippedCharacters
end

function SplitHelper:CompareAndColorCharacters(raidCharacters, sheetCharacters)
    local inBoth = {}
    local inSheetNotRaid = {}
    local inRaidNotSheet = {}
    local unexpectedPlayers = {} 

    local strippedRaidCharacters = self:StripRealmNames(raidCharacters)
    local strippedSheetCharacters = self:StripRealmNames(sheetCharacters)

    local raidSet = {}
    for _, character in ipairs(strippedRaidCharacters) do
        raidSet[strlower(character)] = true
    end

    for _, character in ipairs(strippedSheetCharacters) do
        local lowerCharacter = strlower(character)
        if raidSet[lowerCharacter] then
            table.insert(inBoth, character)
            raidSet[lowerCharacter] = nil
        else
            table.insert(inSheetNotRaid, character)
        end
    end

    for character, _ in pairs(raidSet) do
        table.insert(inRaidNotSheet, character)
    end

    for _, character in ipairs(strippedRaidCharacters) do
        local foundInSheet = false
        for _, sheetCharacter in ipairs(strippedSheetCharacters) do
            if strlower(character) == strlower(sheetCharacter) then
                foundInSheet = true
                break
            end
        end
        if not foundInSheet then
            table.insert(unexpectedPlayers, character) 
        end
    end

    return inBoth, inSheetNotRaid, inRaidNotSheet, unexpectedPlayers 
end

function SplitHelper:PrintColoredCharacters(inBoth, inSheetNotRaid, inRaidNotSheet, unexpectedPlayers)
    inBoth = inBoth or {}
    inSheetNotRaid = inSheetNotRaid or {}
    inRaidNotSheet = inRaidNotSheet or {}
    unexpectedPlayers = unexpectedPlayers or {}

    for _, child in ipairs({self.scrollContent:GetChildren()}) do
        child:Hide()  
    end

    self.scrollContent:ClearAllPoints()
    self.scrollContent:SetPoint("TOPLEFT", self.scrollContent:GetParent(), "TOPLEFT", 0, 0)

    local yOffset = -30 
    local xOffset = 0 

    local function createRow(character, color)
        local row = CreateFrame("Frame", nil, self.scrollContent, "BackdropTemplate")
        row:SetSize(120, 30)
        row:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", xOffset, yOffset)
        
        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1
        })
        row:SetBackdropColor(0.15, 0.15, 0.15, 1)
        row:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("CENTER")
        nameText:SetText(color .. character .. "|r")

        yOffset = yOffset - 30 + 1
        
        if yOffset == -175 then
            yOffset = yOffset - 10
        end

        if yOffset <= -(30 * 10 + 10) then
            yOffset = -30 
            xOffset = xOffset + 133 
        end

        table.insert(self.characterRows, row)
    end

    for i, character in ipairs(inBoth) do
        createRow(character, "|cff00ff00") 
    end

    for i, character in ipairs(inSheetNotRaid) do
        createRow(character, "|cffff0000") 
    end

    local totalRows = math.ceil(#inBoth / 10) + math.ceil(#inSheetNotRaid / 10) + math.ceil(#inRaidNotSheet / 10)
    self.scrollContent:SetHeight(totalRows * 30)

    self.scrollContent:Show() 
end

function SplitHelper:PrintUnexpectedCharacters(unexpectedPlayers)
    unexpectedPlayers = unexpectedPlayers or {}

    for _, child in ipairs({self.unexpectedScrollContent:GetChildren()}) do
        child:Hide() 
    end

    self.unexpectedScrollContent:ClearAllPoints()
    self.unexpectedScrollContent:SetPoint("TOPLEFT", self.unexpectedScrollContent:GetParent(), "TOPLEFT", 0, 0)

    local yOffset = 0 
    local xOffset = 10  

    local function createUnexpectedRow(character)
        local row = CreateFrame("Frame", nil, self.unexpectedScrollContent, "BackdropTemplate")
        row:SetSize(120, 30)
        row:SetPoint("TOPLEFT", self.unexpectedScrollContent, "TOPLEFT", xOffset, yOffset)
        
        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1
        })
        row:SetBackdropColor(0.15, 0.15, 0.15, 1)
        row:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("CENTER")
        nameText:SetText("|cffffff00" .. character .. "|r") 
    
        yOffset = yOffset - 30
    
        table.insert(self.characterRows, row)
    end

    for i, character in ipairs(unexpectedPlayers) do
        createUnexpectedRow(character)
    end

    local totalRows = math.ceil(#unexpectedPlayers / 10)
    self.unexpectedScrollContent:SetHeight(totalRows * 30)

    self.unexpectedScrollContent:Show() 
end

function SplitHelper:CreateCharacterRow(character, colorText, yOffset)
    local row = CreateFrame("Frame", nil, self.scrollContent, "BackdropTemplate")
    row:SetSize(520, 30)
    row:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 0, yOffset)

    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1
    })
    row:SetBackdropColor(0.15, 0.15, 0.15, 1)
    row:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("CENTER")
    nameText:SetText(colorText)

    return row
end

function SplitHelper:ClearData(index)
    if index and ACT.db.profile.splits.profiles[index] then
        table.remove(ACT.db.profile.splits.profiles, index)
        self.selectedIndex = nil
        self.splitDropdown.button.text:SetText("Select Split")
        self.resultText:SetText("")
        self:UpdateDropdown()

        for _, row in ipairs(self.characterRows) do
            row:Hide()
            row = nil 
        end
        self.characterRows = {} 
    end
end


function SplitHelper:CheckCharacters()
    if not self.selectedIndex then return end
    
    local profile = ACT.db.profile.splits.profiles[self.selectedIndex]
    if not profile then return end

    local raidCharacters = self:GetRaidCharacters()
    local inBoth, inSheetNotRaid, inRaidNotSheet, unexpectedPlayers = self:CompareAndColorCharacters(self:GetRaidCharacters(), profile.characters)


    self:PrintColoredCharacters(inBoth, inSheetNotRaid, inRaidNotSheet)
    self:PrintUnexpectedCharacters(unexpectedPlayers)
end

function SplitHelper:ShowRenamePopup(index)
    if self.renamePopup then
        self.renamePopup:Hide()
        self.renamePopup = nil
        self.renameEditBox = nil
    end
    local profile = ACT.db.profile.splits.profiles[index]
    local defaultName = profile.name or ""
    self.renamePopup, self.renameEditBox = UI:CreatePopupWithEditBox("Enter new split name:", 320, 150, defaultName,
        function(newName)
            if newName and newName ~= "" then
                ACT.db.profile.splits.profiles[index].name = newName
                self:UpdateDropdown()
                self.splitDropdown.button.text:SetText(newName)
            end
            if self.renamePopup then
                self.renamePopup:Hide()
            end
        end,
        function()
            if self.renamePopup then
                self.renamePopup:Hide()
            end
        end
    )
    self.renamePopup:SetScript("OnHide", function()
        self.renamePopup = nil
        self.renameEditBox = nil
    end)
    self.renamePopup:Show()
end

ACT:RegisterModule(SplitHelper)