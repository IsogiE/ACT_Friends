local NicknameModule = {}
NicknameModule.title = "Nicknames"

local AceComm = LibStub("AceComm-3.0")
local LibDeflate = LibStub("LibDeflate")

local PUSH_PREFIX = "ACTF_NICK_UPPY" 
local KILL_PREFIX = "ACTF_NUKE"
local CMP_PREFIX = "ACTF_NCMP"

ACT.db = ACT.db or {}
ACT.db.profile = ACT.db.profile or {}
ACT.db.profile.nicknames = ACT.db.profile.nicknames or {}   
ACT.db.profile.defaultNicknames = ACT.db.profile.defaultNicknames or "" 
ACT.db.profile.defaultNicknameVersion = ACT.db.profile.defaultNicknameVersion or 0

local function strtrim(s)
    return s and s:match("^%s*(.-)%s*$") or ""
end

local function isDefaultCharacter(nickname, charName)
    if not ACT.db.profile.defaultNicknames or ACT.db.profile.defaultNicknames == "" then
        return false
    end
    for entry in string.gmatch(ACT.db.profile.defaultNicknames, "[^;]+") do
        entry = strtrim(entry)
        if entry ~= "" then
            local defNick, defChars = strsplit(":", entry)
            if defNick and strtrim(defNick):lower() == nickname:lower() then
                for defaultChar in string.gmatch(defChars, "[^,]+") do
                    if strtrim(defaultChar):lower() == charName:lower() then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function NicknameModule:CleanupEmptyNicknames()
    local nicknamesMap = ACT.db.profile.nicknames
    local toRemove = {}
    for nickname, data in pairs(nicknamesMap) do
        local chars = data and data.characters
        if not chars or #chars == 0 then
            table.insert(toRemove, nickname)
        end
    end
    for _, nickname in ipairs(toRemove) do
        nicknamesMap[nickname] = nil
    end
end

AceComm:RegisterComm(PUSH_PREFIX, function(prefix, message, distribution, sender)
    if prefix == PUSH_PREFIX then
        local decoded = LibDeflate:DecodeForPrint(message)
        local decompressed = LibDeflate:DecompressDeflate(decoded)
        if decompressed then
            NicknameModule:MergePushUpdate(decompressed)
            ACT.db.profile.defaultNicknames = decompressed
            NicknameModule:CleanupEmptyNicknames()
            NicknameModule:RefreshContent()
            NicknameModule:PromptPushReload_Default(sender)
        end
    end
end)

AceComm:RegisterComm(KILL_PREFIX, function(prefix, message, distribution, sender)
    if prefix == KILL_PREFIX then
        ACT.db.profile.nicknames = {}
        ACT.db.profile.defaultNicknames = ""
        ACT.db.profile.defaultNicknameVersion = 0
        NicknameModule:RefreshContent()
        if not NicknameModule.killswitchPopup then
            NicknameModule.killswitchPopup = UI:CreateTextPopup(
                "Killswitch Activated",
                sender .. " has triggered a killswitch! Please reload your UI.",
                "Reload Now",
                "Later",
                function() ReloadUI() end,
                function() end
            )
            NicknameModule.killswitchPopup:SetScript("OnHide", function()
                NicknameModule.killswitchPopup = nil
            end)
        end
        NicknameModule.killswitchPopup:Show()
    end
end)

NicknameModule.compareResponses = {}
NicknameModule.compareActive = false
AceComm:RegisterComm(CMP_PREFIX, function(prefix, message, distribution, sender)
    if message == "REQ" then
        if sender ~= UnitName("player") then
            local defaultNick = ACT.db.profile.defaultNicknames or ""
            local compressed = LibDeflate:CompressDeflate(defaultNick)
            local encoded = LibDeflate:EncodeForPrint(compressed)
            AceComm:SendCommMessage(CMP_PREFIX, encoded, distribution)
        end
    else
        if NicknameModule.compareActive then
            local decoded = LibDeflate:DecodeForPrint(message)
            local decompressed = LibDeflate:DecompressDeflate(decoded)
            if decompressed then
                local simpleName = sender:match("^(.-)-") or sender
                NicknameModule.compareResponses[simpleName] = decompressed
            end
        end
    end
end)

local function GetPlayerBattleTag()
    if C_BattleNet and C_BattleNet.GetAccountInfoByGUID then
        local guid = UnitGUID("player")
        if guid then
            local info = C_BattleNet.GetAccountInfoByGUID(guid)
            if info and info.battleTag then
                return info.battleTag
            end
        end
    end
    return UnitName("player")
end

local function IsPrivilegedUser()
    local battleTag = GetPlayerBattleTag()
    return (battleTag == "Isogi#21124" or battleTag == "Jafar#21190" or battleTag == "ViklunD#2904" or battleTag == "Strike#2545" or battleTag == "Brokenlenny#2577")
end

function NicknameModule:MergePushUpdate(defaultString)
    local newEntries = {}
    for entry in string.gmatch(defaultString, "[^;]+") do
        entry = strtrim(entry)
        if entry ~= "" then
            local nickname, characters = strsplit(":", entry)
            if nickname and characters then
                nickname = strtrim(nickname)
                local normalizedNick = nickname:lower()
                newEntries[normalizedNick] = { originalCase = nickname, characters = {} }
                for charName in string.gmatch(characters, "[^,]+") do
                    charName = strtrim(charName)
                    if charName ~= "" then
                        table.insert(newEntries[normalizedNick].characters, charName)
                    end
                end
            end
        end
    end
    local existing = ACT.db.profile.nicknames
    for normNick, newData in pairs(newEntries) do
        for _, charName in ipairs(newData.characters) do
            for exNick, data in pairs(existing) do
                if exNick:lower() ~= normNick and data.characters then
                    for i = #data.characters, 1, -1 do
                        local currentChar = nil
                        if type(data.characters[i]) == "table" then
                            currentChar = data.characters[i].character
                        else
                            currentChar = data.characters[i]
                        end
                        if currentChar and currentChar:lower() == charName:lower() then
                            table.remove(data.characters, i)
                        end
                    end
                end
            end
        end
    end
    for normNick, newData in pairs(newEntries) do
        existing[newData.originalCase] = { characters = newData.characters }
    end
end

function NicknameModule:ConfirmPushDefault()
    if not self.pushDefaultPopup then
        self.pushDefaultPopup = UI:CreateTextPopup(
            "Confirm Push Default",
            "Are you sure you want to push default nicknames?",
            "Confirm",
            "Cancel",
            function()
                self.pushDefaultPopup:Hide()
                if ACT.db.profile.defaultNicknames and ACT.db.profile.defaultNicknames ~= "" then
                    local compressed = LibDeflate:CompressDeflate(ACT.db.profile.defaultNicknames)
                    local encoded = LibDeflate:EncodeForPrint(compressed)
                    AceComm:SendCommMessage(PUSH_PREFIX, encoded, "RAID")
                    NicknameModule:ProcessDefaultImportString(ACT.db.profile.defaultNicknames)
                    NicknameModule:CleanupEmptyNicknames()
                    NicknameModule:RefreshContent()
                    NicknameModule:PromptPushReload_Default(UnitName("player"))
                end
            end,
            function()
                self.pushDefaultPopup:Hide()
            end
        )
        self.pushDefaultPopup:SetScript("OnHide", function()
            self.pushDefaultPopup = nil
        end)
    end
    self.pushDefaultPopup:Show()
end

function NicknameModule:PushDefaultNicknames(updateData)
    local compressed = LibDeflate:CompressDeflate(updateData)
    local encoded = LibDeflate:EncodeForPrint(compressed)
    AceComm:SendCommMessage(PUSH_PREFIX, encoded, "RAID")
    NicknameModule:PromptPushReload_Default(UnitName("player"))
end

function NicknameModule:GetConfigSize()
    return 800, 600
end

function NicknameModule:CreateConfigPanel(parent)
    if self.configPanel then
        self.configPanel:SetParent(parent)
        self.configPanel:ClearAllPoints()
        self.configPanel:SetAllPoints(parent)
        self.configPanel:Show()
        return self.configPanel
    end
    local configPanel = CreateFrame("Frame", nil, parent)
    configPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    configPanel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    
    local importLabel = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    importLabel:SetPoint("TOPLEFT", configPanel, "TOPLEFT", 20, 16)
    importLabel:SetText("Nicknames")
    
    local importBoxFrame, importBoxEdit = UI:CreateMultilineEditBox(configPanel, 520, 40, nil)
    importBoxFrame:SetPoint("TOPLEFT", importLabel, "BOTTOMLEFT", 0, -10)
    self.importBoxFrame = importBoxFrame
    self.importBoxEdit = importBoxEdit
    
    local importButton = UI:CreateButton(configPanel, "Import", 120, 30, function()
        local text = self.importBoxEdit:GetText()
        self.importErrorMsg:SetText("")
        if text and text ~= "" then
            local normalizedParts = {}
            for entry in string.gmatch(text, "[^;]+") do
                entry = strtrim(entry)
                if entry ~= "" then
                    local nick, chars = strsplit(":", entry)
                    if nick and chars then
                        local normNick = nick:sub(1,1):upper() .. nick:sub(2):lower()
                        local normChars = {}
                        for c in string.gmatch(chars, "[^,]+") do
                            c = strtrim(c)
                            if c ~= "" then
                                local normChar = c:sub(1,1):upper() .. c:sub(2):lower()
                                table.insert(normChars, normChar)
                            end
                        end
                        table.insert(normalizedParts, normNick .. ": " .. table.concat(normChars, ", "))
                    end
                end
            end
            text = table.concat(normalizedParts, "; ")
            local conflict = self:CheckImportConflicts(text)
            if conflict then
                self.importErrorMsg:SetText("This character already has a nickname associated with it")
                C_Timer.After(3, function() self.importErrorMsg:SetText("") end)
                return
            end
            self:ProcessImportString(text)
            NicknameModule:CleanupEmptyNicknames()
            self.importBoxEdit:SetText("")
            self:RefreshContent()
            NicknameModule:PromptReloadNormal()
        end
    end)
    importButton:SetPoint("TOPLEFT", importBoxFrame, "BOTTOMLEFT", 0, -10)
    
    local errorMsg = configPanel:CreateFontString(nil, "OVERLAY", "GameFontRed")
    errorMsg:SetPoint("TOPLEFT", importButton, "BOTTOMLEFT", 0, -5)
    errorMsg:SetText("")
    self.importErrorMsg = errorMsg
    
    local integrationCheckbox = CreateFrame("CheckButton", nil, configPanel, "UICheckButtonTemplate")
    integrationCheckbox:SetPoint("LEFT", importButton, "RIGHT", 20, 0)
    integrationCheckbox:SetSize(22, 22)
    integrationCheckbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    integrationCheckbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    integrationCheckbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    integrationCheckbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    integrationCheckbox.Text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    integrationCheckbox.Text:SetText("Show nicknames on Party/Raid Frames & MRT Raid CDs")
    integrationCheckbox.Text:ClearAllPoints()
    integrationCheckbox.Text:SetPoint("LEFT", integrationCheckbox, "RIGHT", 5, 0)
    integrationCheckbox:SetChecked(ACT.db.profile.useNicknameIntegration)
    integrationCheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        ACT.db.profile.useNicknameIntegration = checked
        NicknameModule:RefreshContent()
        NicknameModule:PromptReloadNormal()
    end)
    
    local headerFrame = CreateFrame("Frame", nil, configPanel)
    headerFrame:SetSize(520, 20)
    headerFrame:SetPoint("TOPLEFT", importButton, "BOTTOMLEFT", 0, -30)
    
    local nicknameHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nicknameHeader:SetPoint("LEFT", headerFrame, "LEFT", 0, -10)
    nicknameHeader:SetText("Nickname")
    
    local charHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    charHeader:SetPoint("LEFT", headerFrame, "LEFT", 113, -10)
    charHeader:SetText("Character Names")
    
    local actionsHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    actionsHeader:SetPoint("LEFT", headerFrame, "LEFT", 350, -10)
    actionsHeader:SetText("Actions")
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, configPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(520, 320)
    scrollFrame:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        if NicknameModule.dropdowns then
            for _, dropdown in ipairs(NicknameModule.dropdowns) do
                if dropdown.list and dropdown.list:IsShown() then
                    dropdown.list:Hide()
                end
            end
        end
        self.ScrollBar:SetValue(offset)
    end)
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(520, 320)
    scrollFrame:SetScrollChild(scrollChild)
    self.scrollChild = scrollChild
    
    local defaultButton = UI:CreateButton(configPanel, "Default Nicknames", 120, 30, function()
        NicknameModule:ShowWipeCustomPopup()
    end)
    defaultButton:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -15)
    
    local nickStringButton = UI:CreateButton(configPanel, "Nickname String", 120, 30, function()
        NicknameModule:ShowNicknameStringPopup()
    end)
    nickStringButton:SetPoint("LEFT", defaultButton, "RIGHT", 10, 0)
    
    if IsPrivilegedUser() then
        local officerFrame = CreateFrame("Frame", "OfficerToolsFrame", configPanel, "BackdropTemplate")
        officerFrame:SetSize(165, 235)
        officerFrame:SetPoint("TOPLEFT", configPanel, "TOPRIGHT", -213, 40)
        
        officerFrame.bg = officerFrame:CreateTexture(nil, "BACKGROUND")
        officerFrame.bg:SetAllPoints()
        officerFrame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)
        
        officerFrame.border = CreateFrame("Frame", nil, officerFrame, "BackdropTemplate")
        officerFrame.border:SetAllPoints()
        officerFrame.border:SetBackdrop({
            edgeFile = "Interface\\AddOns\\ACT_Friends\\media\\border",
            edgeSize = 8,
        })
        
        local title = officerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", officerFrame, "TOP", 0, -10)
        title:SetText("OFFICER TOOLS")
        
        local btnHeight = 30
        local btnSpacing = 5
        local currentY = -40
        local function CreateOfficerButton(text, commandFunc)
            local btn = UI:CreateButton(officerFrame, text, 135, btnHeight, commandFunc)
            btn:SetPoint("TOP", officerFrame, "TOP", 0, currentY)
            currentY = currentY - (btnHeight + btnSpacing)
        end
        
        CreateOfficerButton("Set Default", function() SlashCmdList["SETDEFAULTNICK"]("") end)
        CreateOfficerButton("Compare Defaults", function() 
            NicknameModule:CompareDefaultNicknames() 
        end)
        CreateOfficerButton("Push Default", function() NicknameModule:ConfirmPushDefault() end)
        CreateOfficerButton("Nuke Local Nicknames", function() SlashCmdList["WIPENICKNAMES"]("") end)
        CreateOfficerButton("Nuke ALL Nicknames", function() SlashCmdList["ACTKILLSWITCH"]("") end)
        
        self.officerFrame = officerFrame
    end    
    
    self.configPanel = configPanel
    NicknameModule:NormalizeStoredNames()
    self:RefreshContent()
    
    return configPanel
end

function NicknameModule:CheckImportConflicts(importString)
    local newEntries = {}
    for entry in string.gmatch(importString, "[^;]+") do
        entry = strtrim(entry)
        if entry ~= "" then
            local nickname, characters = strsplit(":", entry)
            if nickname and characters then
                nickname = strtrim(nickname)
                local normalizedNick = nickname:lower()
                newEntries[normalizedNick] = newEntries[normalizedNick] or {}
                for charName in string.gmatch(characters, "[^,]+") do
                    charName = strtrim(charName)
                    if charName ~= "" then
                        table.insert(newEntries[normalizedNick], charName:lower())
                    end
                end
            end
        end
    end
    for existingNick, data in pairs(ACT.db.profile.nicknames) do
        local normalizedExistingNick = existingNick:lower()
        if data and data.characters then
            for _, charData in ipairs(data.characters) do
                local existingChar = (type(charData) == "table" and charData.character or charData)
                if existingChar then
                    existingChar = existingChar:lower()
                    for newNick, charList in pairs(newEntries) do
                        for _, importedChar in ipairs(charList) do
                            if importedChar == existingChar and newNick ~= normalizedExistingNick then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function NormalizeString(str)
  if not str or str == "" then return str end
  return str:sub(1, 1):upper() .. str:sub(2):lower()
end

function NicknameModule:NormalizeStoredNames()
  if ACT.db.profile.defaultNicknames and ACT.db.profile.defaultNicknames ~= "" then
    local parts = {}
    for entry in string.gmatch(ACT.db.profile.defaultNicknames, "[^;]+") do
      entry = strtrim(entry)
      if entry ~= "" then
        local nick, chars = strsplit(":", entry)
        if nick and chars then
          local normNick = NormalizeString(strtrim(nick))
          local normChars = {}
          for c in string.gmatch(chars, "[^,]+") do
            c = NormalizeString(strtrim(c))
            table.insert(normChars, c)
          end
          table.insert(parts, normNick .. ": " .. table.concat(normChars, ", "))
        end
      end
    end
    ACT.db.profile.defaultNicknames = table.concat(parts, "; ")
  end

  local newMap = {}
  for nickname, data in pairs(ACT.db.profile.nicknames) do
    local normNick = NormalizeString(nickname)
    local newChars = {}
    if data.characters then
      for _, charData in ipairs(data.characters) do
        local charName = nil
        if type(charData) == "table" then
          charName = NormalizeString(charData.character)
        else
          charName = NormalizeString(charData)
        end
        table.insert(newChars, { character = charName })
      end
    end
    newMap[normNick] = { characters = newChars }
  end
  ACT.db.profile.nicknames = newMap
end

function NicknameModule:RefreshContent()
    self:CleanupEmptyNicknames()
    
    if not self.scrollChild then return end
    for _, child in ipairs({ self.scrollChild:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    self.dropdowns = {}

    local nicknamesMap = ACT.db.profile.nicknames
    local sortedNicknames = {}
    for nickname in pairs(nicknamesMap) do
        table.insert(sortedNicknames, nickname)
    end
    table.sort(sortedNicknames)
    local yOffset = -10
    for _, nickname in ipairs(sortedNicknames) do
        local data = nicknamesMap[nickname]
        local row = CreateFrame("Frame", nil, self.scrollChild, "BackdropTemplate")
        row:SetSize(520, 30)
        row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, yOffset)
        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        row:SetBackdropColor(0.15, 0.15, 0.15, 1)
        row:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", row, "LEFT", 5, 0)
        label:SetSize(150, 30)
        label:SetJustifyH("LEFT")
        label:SetText(nickname)
        
        local dropdown = UI:CreateDropdown(row, 200, 30)
        dropdown:SetPoint("LEFT", row, "LEFT", 110, 0)
        table.insert(self.dropdowns, dropdown)
        local options = {}
        local list = NicknameModule:GetCharacterList(nickname)
        for _, v in pairs(list) do
            table.insert(options, {
                text = v,
                value = v,
                onClick = function()
                    dropdown.selectedValue = v
                    dropdown.button.text:SetText(v)
                end
            })
        end
        UI:SetDropdownOptions(dropdown, options)
        dropdown.button.text:SetText("Select Character")
        dropdown.selectedValue = nil
        
        local actionsFrame = CreateFrame("Frame", nil, row)
        actionsFrame:SetSize(170, 30)
        actionsFrame:SetPoint("LEFT", row, "LEFT", 330, 0)
        actionsFrame:SetPoint("CENTER", row, "CENTER", 0, 0)
        
        local addBtn = UI:CreateButton(actionsFrame, "Add", 50, 20, function()
            if NicknameModule.characterInputPopup then
                NicknameModule.characterInputPopup:Hide()
                NicknameModule.characterInputPopup = nil
                NicknameModule.characterInputEditBox = nil
            end
        
            local title = "Add New Character"
            local defaultText = ""
            NicknameModule.characterInputPopup, NicknameModule.characterInputEditBox = UI:CreatePopupWithEditBox(
                title,
                300,
                200,
                defaultText,
                function(text)
                    if text and text ~= "" then
                        if not ACT.db.profile.nicknames[nickname] then
                            ACT.db.profile.nicknames[nickname] = { characters = {} }
                        end
                        table.insert(ACT.db.profile.nicknames[nickname].characters, { character = text })
                        NicknameModule:CleanupEmptyNicknames()
                        NicknameModule:RefreshContent()
                        NicknameModule:PromptReloadNormal()
                    end
                    if NicknameModule.characterInputPopup then
                        NicknameModule.characterInputPopup:Hide()
                    end
                end,
                function()
                    if NicknameModule.characterInputPopup then
                        NicknameModule.characterInputPopup:Hide()
                    end
                end
            )
            NicknameModule.characterInputPopup:SetScript("OnHide", function()
                NicknameModule.characterInputPopup = nil
                NicknameModule.characterInputEditBox = nil
            end)
            NicknameModule.characterInputPopup:Show()
        end)
        addBtn:SetPoint("LEFT", actionsFrame, "LEFT", 20, 0)
        
        local editBtn = UI:CreateButton(actionsFrame, "Edit", 50, 20, function()
            if dropdown.selectedValue then
                if isDefaultCharacter(nickname, dropdown.selectedValue) then
                    self.importErrorMsg:SetText("Error: Cannot edit Default Characters")
                    C_Timer.After(3, function() self.importErrorMsg:SetText("") end)
                    return
                end
        
                if NicknameModule.characterInputPopup then
                    NicknameModule.characterInputPopup:Hide()
                    NicknameModule.characterInputPopup = nil
                    NicknameModule.characterInputEditBox = nil
                end
        
                local title = "Edit Character"
                local defaultText = dropdown.selectedValue
                NicknameModule.characterInputPopup, NicknameModule.characterInputEditBox = UI:CreatePopupWithEditBox(
                    title,
                    300,
                    200,
                    defaultText,
                    function(text)
                        if text and text ~= "" then
                            if ACT.db.profile.nicknames[nickname] and ACT.db.profile.nicknames[nickname].characters then
                                for i, charData in ipairs(ACT.db.profile.nicknames[nickname].characters) do
                                    local existingName = (type(charData) == "table" and charData.character or charData)
                                    if existingName == dropdown.selectedValue then
                                        if type(charData) == "table" then
                                            ACT.db.profile.nicknames[nickname].characters[i].character = text
                                        else
                                            ACT.db.profile.nicknames[nickname].characters[i] = text
                                        end
                                        break
                                    end
                                end
                                dropdown.selectedValue = text
                                NicknameModule:CleanupEmptyNicknames()
                                NicknameModule:RefreshContent()
                                NicknameModule:PromptReloadNormal()
                            end
                        end
                        if NicknameModule.characterInputPopup then
                            NicknameModule.characterInputPopup:Hide()
                        end
                    end,
                    function()
                        if NicknameModule.characterInputPopup then
                            NicknameModule.characterInputPopup:Hide()
                        end
                    end
                )
                NicknameModule.characterInputPopup:SetScript("OnHide", function()
                    NicknameModule.characterInputPopup = nil
                    NicknameModule.characterInputEditBox = nil
                end)
                NicknameModule.characterInputPopup:Show()
            end
        end)
        editBtn:SetPoint("LEFT", addBtn, "RIGHT", 5, 0)
        
        local deleteBtn = UI:CreateButton(actionsFrame, "Delete", 50, 20, function()
            if dropdown.selectedValue then
                if isDefaultCharacter(nickname, dropdown.selectedValue) then
                    self.importErrorMsg:SetText("Error: Cannot delete Default Characters")
                    C_Timer.After(3, function() self.importErrorMsg:SetText("") end)
                    return
                end
                if ACT.db.profile.nicknames[nickname] and ACT.db.profile.nicknames[nickname].characters then
                    for i, charData in ipairs(ACT.db.profile.nicknames[nickname].characters) do
                        local existingName = (type(charData) == "table" and charData.character or charData)
                        if existingName == dropdown.selectedValue then
                            table.remove(ACT.db.profile.nicknames[nickname].characters, i)
                            break
                        end
                    end
                    dropdown.selectedValue = nil
                    NicknameModule:CleanupEmptyNicknames()
                    NicknameModule:RefreshContent()
                    NicknameModule:PromptReloadNormal()
                end
            end
        end)
        deleteBtn:SetPoint("LEFT", editBtn, "RIGHT", 5, 0)
        
        yOffset = yOffset - 40
    end
end

function NicknameModule:ProcessImportString(importString)
    local nicknamesMap = ACT.db.profile.nicknames
    local normalizedMap = {}
    
    for nickname, data in pairs(nicknamesMap) do
        local normalizedNick = nickname:lower()
        if not normalizedMap[normalizedNick] then
            normalizedMap[normalizedNick] = { originalCase = nickname, characters = {} }
        end
        if data.characters then
            for _, v in ipairs(data.characters) do
                local name = (type(v) == "table") and v.character or v
                if name then
                    local exists = false
                    for _, e in ipairs(normalizedMap[normalizedNick].characters) do
                        local existingName = (type(e) == "table") and e.character or e
                        if existingName and existingName:lower() == name:lower() then
                            exists = true
                            break
                        end
                    end
                    if not exists then
                        table.insert(normalizedMap[normalizedNick].characters, { character = name })
                    end
                end
            end
        end
    end
    
    for entry in string.gmatch(importString, "[^;]+") do
        entry = strtrim(entry)
        if entry ~= "" then
            local nickname, characters = strsplit(":", entry)
            if nickname and characters then
                nickname = strtrim(nickname)
                local normalizedNick = nickname:lower()
                if not normalizedMap[normalizedNick] then
                    normalizedMap[normalizedNick] = { originalCase = nickname, characters = {} }
                end
                for charName in string.gmatch(characters, "[^,]+") do
                    charName = strtrim(charName)
                    if charName ~= "" then
                        local exists = false
                        for _, e in ipairs(normalizedMap[normalizedNick].characters) do
                            local existingName = (type(e) == "table") and e.character or e
                            if existingName and existingName:lower() == charName:lower() then
                                exists = true
                                break
                            end
                        end
                        if not exists then
                            table.insert(normalizedMap[normalizedNick].characters, { character = charName })
                        end
                    end
                end
            end
        end
    end

    wipe(nicknamesMap)
    for _, data in pairs(normalizedMap) do
        nicknamesMap[data.originalCase] = { characters = data.characters }
    end
end

function NicknameModule:ProcessDefaultImportString(defaultString)
    local newEntries = {}
    for entry in string.gmatch(defaultString, "[^;]+") do
        entry = strtrim(entry)
        if entry ~= "" then
            local nickname, characters = strsplit(":", entry)
            if nickname and characters then
                nickname = strtrim(nickname)
                local normalizedNick = nickname:lower()
                newEntries[normalizedNick] = newEntries[normalizedNick] or { originalCase = nickname, characters = {} }
                for charName in string.gmatch(characters, "[^,]+") do
                    charName = strtrim(charName)
                    if charName ~= "" then
                        table.insert(newEntries[normalizedNick].characters, charName)
                    end
                end
            end
        end
    end

    local existing = ACT.db.profile.nicknames
    for normNick, newData in pairs(newEntries) do
        local targetNickname = nil
        for existingNick, data in pairs(existing) do
            if existingNick:lower() == normNick then
                targetNickname = existingNick
                break
            end
        end
        if not targetNickname then
            targetNickname = newData.originalCase
            existing[targetNickname] = { characters = {} }
        end

        for _, charName in ipairs(newData.characters) do
            for existingNick, data in pairs(existing) do
                if existingNick:lower() ~= normNick then
                    for i = #data.characters, 1, -1 do
                        local currentChar = nil
                        if type(data.characters[i]) == "table" then
                            currentChar = data.characters[i].character
                        else
                            currentChar = data.characters[i]
                        end
                        if currentChar and currentChar:lower() == charName:lower() then
                            table.remove(data.characters, i)
                        end
                    end
                end
            end

            local exists = false
            for _, charData in ipairs(existing[targetNickname].characters) do
                local existingChar = (type(charData) == "table" and charData.character or charData)
                if existingChar and existingChar:lower() == charName:lower() then
                    exists = true
                    break
                end
            end
            if not exists then
                table.insert(existing[targetNickname].characters, { character = charName })
            end
        end
    end
end

function NicknameModule:PromptReloadNormal()
    if not self.reloadPopupNormal then
        self.reloadPopupNormal = UI:CreateTextPopup(
            "Reload UI",
            "Please reload your UI to apply the changes (Custom Nicknames updated).",
            "Reload Now",
            "Later",
            function() ReloadUI() end,
            function() end
        )
        self.reloadPopupNormal:SetScript("OnHide", function()
            self.reloadPopupNormal = nil
        end)
    end
    self.reloadPopupNormal:Show()
end

function NicknameModule:PromptPushReload_Default(sender)
    sender = sender or UnitName("player")
    if not self.reloadPopupNormal_Default then
        self.reloadPopupNormal_Default = UI:CreateTextPopup(
            "Reload UI",
            sender .. " has pushed a new DEFAULT nickname update, please reload your UI.",
            "Reload Now",
            "Later",
            function() ReloadUI() end,
            function() end
        )
        self.reloadPopupNormal_Default:SetScript("OnHide", function()
            self.reloadPopupNormal_Default = nil
        end)
    else
        self.reloadPopupNormal_Default:Hide()
        self.reloadPopupNormal_Default = UI:CreateTextPopup(
            "Reload UI",
            sender .. " has pushed a new DEFAULT nickname update, please reload your UI.",
            "Reload Now",
            "Later",
            function() ReloadUI() end,
            function() end
        )
        self.reloadPopupNormal_Default:SetScript("OnHide", function()
            self.reloadPopupNormal_Default = nil
        end)
    end
    self.reloadPopupNormal_Default:Show()
end

function NicknameModule:ShowCharacterInputPopup(nickname, existingCharacter, callback)
    local title = existingCharacter and "Edit Character" or "Add New Character"
    local defaultText = existingCharacter or ""
    local popup, editBox = UI:CreatePopupWithEditBox(
        title,
        300,
        200,
        defaultText,
        function(text)
            if text and text ~= "" then
                callback(text)
                NicknameModule:CleanupEmptyNicknames()
                NicknameModule:RefreshContent()
                NicknameModule:PromptReloadNormal()
            end
        end,
        function() end
    )
    popup:SetScript("OnHide", function() end)
    popup:Show()
end

function NicknameModule:ShowWipeCustomPopup()
    if not self.wipePopup then
        self.wipePopup = UI:CreateTextPopup(
            "Reset Custom Nicknames", 
            "Are you sure you want to remove all custom nicknames?\nYour default nicknames will be re-imported.", 
            "Confirm",
            "Cancel",
            function()
                ACT.db.profile.nicknames = {}
                local defaultStr = ACT.db.profile.defaultNicknames or ""
                NicknameModule:ProcessImportString(defaultStr)
                NicknameModule:CleanupEmptyNicknames()
                NicknameModule:RefreshContent()
                NicknameModule:PromptReloadNormal()
            end,
            function() end
        )
        self.wipePopup:SetScript("OnHide", function()
            self.wipePopup = nil
        end)
    end
    self.wipePopup:Show()
end

function NicknameModule:GetCharacterList(nickname)
    local list = {}
    local nickData = ACT.db.profile.nicknames[nickname]
    if nickData and nickData.characters then
        for _, charData in ipairs(nickData.characters) do
            local charName = nil
            if type(charData) == "table" then
                charName = charData.character
            elseif type(charData) == "string" then
                charName = charData
            end
            if charName then
                list[charName] = charName
            end
        end
    end
    if not next(list) then
        list["Select Character"] = "Select Character"
    end
    return list
end

function NicknameModule:GetFullNicknameString()
    local combined = {}
    if ACT.db.profile.defaultNicknames and ACT.db.profile.defaultNicknames ~= "" then
        for entry in string.gmatch(ACT.db.profile.defaultNicknames, "[^;]+") do
            entry = strtrim(entry)
            if entry ~= "" then
                local nick, chars = strsplit(":", entry)
                if nick and chars then
                    local normalizedNick = nick:lower()
                    combined[normalizedNick] = combined[normalizedNick] or { original = nick, chars = {} }
                    for charName in string.gmatch(chars, "[^,]+") do
                        charName = strtrim(charName)
                        if charName ~= "" then
                            combined[normalizedNick].chars[ charName:lower() ] = charName
                        end
                    end
                end
            end
        end
    end
    if ACT.db.profile.nicknames then
        for nick, data in pairs(ACT.db.profile.nicknames) do
            local normalizedNick = nick:lower()
            combined[normalizedNick] = combined[normalizedNick] or { original = nick, chars = {} }
            if data.characters then
                for _, charData in ipairs(data.characters) do
                    local charName = (type(charData) == "table" and charData.character) or charData
                    if charName then
                        combined[normalizedNick].chars[ charName:lower() ] = charName
                    end
                end
            end
        end
    end

    local parts = {}
    for _, info in pairs(combined) do
        local charList = {}
        for _, char in pairs(info.chars) do
            table.insert(charList, char)
        end
        table.sort(charList)
        table.insert(parts, info.original .. ": " .. table.concat(charList, ", "))
    end
    table.sort(parts)
    return table.concat(parts, "; ")
end

function NicknameModule:ShowNicknameStringPopup()
    local fullNickString = self:GetFullNicknameString()
    if not self.nickStringPopup then
        self.nickStringPopup, self.nickStringEditBox = UI:CreatePopupWithEditBox(
            "Nickname String",
            300,
            200,
            fullNickString,
            function(text)
                if self.nickStringPopup then self.nickStringPopup:Hide() end
            end,
            function() if self.nickStringPopup then self.nickStringPopup:Hide() end end
        )
        self.nickStringPopup:SetScript("OnHide", function()
            self.nickStringPopup = nil
            self.nickStringEditBox = nil
        end)
        self.nickStringPopup:Show()
    else
        self.nickStringEditBox:SetText(fullNickString)
        self.nickStringPopup:Show()
    end
end

function NicknameModule:GetGroupMemberNames()
    local members = {}
    local playerName = UnitName("player")
    playerName = playerName:match("^(.-)-") or playerName
    if IsInRaid() then
        local num = GetNumGroupMembers()
        for i = 1, num do
            local name = UnitName("raid" .. i)
            if name then
                local simpleName = name:match("^(.-)-") or name
                if simpleName ~= playerName then
                    table.insert(members, simpleName)
                end
            end
        end
    elseif IsInGroup() then
        local num = GetNumGroupMembers()
        for i = 1, num - 1 do
            local name = UnitName("party" .. i)
            if name then
                local simpleName = name:match("^(.-)-") or name
                table.insert(members, simpleName)
            end
        end
    end
    return members
end

function NicknameModule:CompareDefaultNicknames()
    if not IsPrivilegedUser() then
        return
    end

    self.compareResponses = {}
    self.compareActive = true

    local officerDefault = ACT.db.profile.defaultNicknames or ""
    local progressMessage = "Comparing your default nicknames to party/raid members...\nWaiting for responses..."
    
    if not self.comparePopup then
        self.comparePopup = UI:CreateTextPopup("Nickname Comparison", progressMessage, "Okay", "Close",
            function() if self.comparePopup then self.comparePopup:Hide() end end,
            function() if self.comparePopup then self.comparePopup:Hide() end end)
        self.comparePopup:SetScript("OnHide", function()
            self.comparePopup = nil
        end)
        for _, child in ipairs({self.comparePopup:GetChildren()}) do
            if child:GetObjectType() == "FontString" then
                local font, size = child:GetFont()
                if font and string.find(font, "GameFontHighlight") then
                    self.comparePopup.messageLabel = child
                    break
                end
            end
        end
        self.comparePopup:Show()
    else
        if self.comparePopup.messageLabel then
            self.comparePopup.messageLabel:SetText(progressMessage)
        end
        self.comparePopup:Show()
    end

    local group = IsInRaid() and "RAID" or (IsInGroup() and "PARTY" or nil)
    if group then
        AceComm:SendCommMessage(CMP_PREFIX, "REQ", group)
    end

    C_Timer.After(3, function()
        self.compareActive = false

        local expectedMembers = self:GetGroupMemberNames()
        local resultText = "Comparing your default nicknames to party/raid members...\n\n"
        for _, member in ipairs(expectedMembers) do
            local response = self.compareResponses[member]
            if response then
                if response == officerDefault then
                    resultText = resultText .. member .. ": |cff00ff00Okay|r\n"
                else
                    resultText = resultText .. member .. ": |cffff0000Mismatch|r\n"
                end
            else
                resultText = resultText .. member .. ": |cff808080Addon Not Enabled|r\n"
            end
        end

        if resultText == "" then
            resultText = "No responses received."
        end

        if self.comparePopup and self.comparePopup.messageLabel then
            self.comparePopup.messageLabel:SetText(resultText)
        elseif self.comparePopup then
            self.comparePopup:Hide()
            self.comparePopup = nil
            self.comparePopup = UI:CreateTextPopup("Nickname Comparison", resultText, "Okay", "Close",
                function() if self.comparePopup then self.comparePopup:Hide() end end,
                function() if self.comparePopup then self.comparePopup:Hide() end end)
            self.comparePopup:SetScript("OnHide", function()
                self.comparePopup = nil
            end)
            self.comparePopup:Show()
        end
    end)
end

SLASH_SETDEFAULTNICK1 = "/actdefault"
SlashCmdList["SETDEFAULTNICK"] = function(msg)
    if not IsPrivilegedUser() then
        return
    end
    if not ACT.db.profile.defaultNicknameVersion then
        ACT.db.profile.defaultNicknameVersion = 0
    end
    if not NicknameModule.setDefaultPopup then
        NicknameModule.setDefaultPopup, _ = UI:CreatePopupWithEditBox(
            "Set New Default Nicknames",
            300,
            200,
            ACT.db.profile.defaultNicknames or "",
            function(text)
                if text and text ~= "" then
                    local normalizedParts = {}
                    for entry in string.gmatch(text, "[^;]+") do
                        entry = strtrim(entry)
                        if entry ~= "" then
                            local nick, chars = strsplit(":", entry)
                            if nick and chars then
                                local normNick = nick:sub(1,1):upper() .. nick:sub(2):lower()
                                local normChars = {}
                                for c in string.gmatch(chars, "[^,]+") do
                                    c = strtrim(c)
                                    if c ~= "" then
                                        local normChar = c:sub(1,1):upper() .. c:sub(2):lower()
                                        table.insert(normChars, normChar)
                                    end
                                end
                                table.insert(normalizedParts, normNick .. ": " .. table.concat(normChars, ", "))
                            end
                        end
                    end
                    text = table.concat(normalizedParts, "; ")
                    ACT.db.profile.defaultNicknames = text
                    ACT.db.profile.defaultNicknameVersion = ACT.db.profile.defaultNicknameVersion + 1
                    NicknameModule:ProcessDefaultImportString(text)
                    NicknameModule:CleanupEmptyNicknames()
                    NicknameModule:RefreshContent()
                    NicknameModule:PromptReloadNormal_Default()
                end
            end,
            function() end
        )
        NicknameModule.setDefaultPopup:SetScript("OnHide", function()
            NicknameModule.setDefaultPopup = nil
        end)
    end
    NicknameModule.setDefaultPopup:Show()
end

SLASH_PUSHDEFAULTNICK1 = "/actpush"
SlashCmdList["PUSHDEFAULTNICK"] = function(msg)
    if not IsPrivilegedUser() then
        return
    end
    NicknameModule:ConfirmPushDefault()
end

SLASH_WIPENICKNAMES1 = "/actwipe"
SlashCmdList["WIPENICKNAMES"] = function(msg)
    if not IsPrivilegedUser() then
        return
    end
    if not NicknameModule.wipePopup then
        NicknameModule.wipePopup = UI:CreateTextPopup(
            "Confirm Wipe",
            "Are you sure you want to wipe all nicknames? This action cannot be undone.",
            "Yes, Wipe",
            "Cancel",
            function()
                ACT.db.profile.nicknames = {}
                ACT.db.profile.defaultNicknames = ""
                ACT.db.profile.defaultNicknameVersion = 0
                NicknameModule:RefreshContent()
                NicknameModule:PromptReloadNormal()
            end,
            function() end
        )
        NicknameModule.wipePopup:SetScript("OnHide", function()
            NicknameModule.wipePopup = nil
        end)
    end
    NicknameModule.wipePopup:Show()
end

SLASH_ACTKILLSWITCH1 = "/actkillswitch"
SlashCmdList["ACTKILLSWITCH"] = function(msg)
    if not IsPrivilegedUser() then
        return
    end
    if not NicknameModule.killswitchPopup then
        NicknameModule.killswitchPopup = UI:CreateTextPopup(
            "Confirm Killswitch",
            "Are you sure you want to trigger the killswitch? This will wipe ALL nicknames for everyone.",
            "Yes, Killswitch",
            "Cancel",
            function()
                AceComm:SendCommMessage(KILL_PREFIX, "killswitch", "RAID")
                if not NicknameModule.killswitchPopup then
                    NicknameModule.killswitchPopup = UI:CreateTextPopup(
                        "Killswitch Activated",
                        UnitName("player") .. " has triggered a killswitch! Please reload your UI.",
                        "Reload Now",
                        "Later",
                        function() ReloadUI() end,
                        function() end
                    )
                    NicknameModule.killswitchPopup:SetScript("OnHide", function()
                        NicknameModule.killswitchPopup = nil
                    end)
                end
                NicknameModule.killswitchPopup:Show()
            end,
            function() end
        )
        NicknameModule.killswitchPopup:SetScript("OnHide", function()
            NicknameModule.killswitchPopup = nil
        end)
    end
    NicknameModule.killswitchPopup:Show()
end

function NicknameModule:PromptReloadNormal_Default()
    if not self.reloadPopupNormal_Default then
        self.reloadPopupNormal_Default = UI:CreateTextPopup(
            "Reload UI",
            "You have saved a new DEFAULT nickname update. Please reload your UI to apply these changes.",
            "Reload Now",
            "Later",
            function() ReloadUI() end,
            function() end
        )
        self.reloadPopupNormal_Default:SetScript("OnHide", function()
            self.reloadPopupNormal_Default = nil
        end)
    end
    self.reloadPopupNormal_Default:Show()
end

if ACT and ACT.RegisterModule then
    ACT:RegisterModule(NicknameModule)
end

return NicknameModule