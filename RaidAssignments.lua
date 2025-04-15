AssignmentModule = {} 
AssignmentModule.title = "Assignments"  

VACT = VACT or {}
VACT.BossPresets = VACT.BossPresets or {}

function AssignmentModule:GetDisplayName(name)
    if not name then return "" end
    local trimmed = name:match("^%s*(.-)%s*$")
    local baseName = trimmed:match("^(.-)%-")
    return baseName or trimmed
end

function AssignmentModule:StripActiveRoster()
    if not self.activeRoster then return end
    for i, entry in ipairs(self.activeRoster) do
        if type(entry) == "table" and entry.name then
            entry.name = self:GetDisplayName(entry.name)
        elseif type(entry) == "string" then
            self.activeRoster[i] = self:GetDisplayName(entry)
        end
    end
end

AssignmentModule.raids = AssignmentData or {} 
AssignmentModule.activeRoster = {}  
AssignmentModule.selectedRaid = nil
AssignmentModule.selectedBoss = nil
AssignmentModule.selectedPresetIndex = nil
AssignmentModule.nameFrames = {} 
AssignmentModule.currentSlots = nil 

local function GetClassColor(classToken)
    local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
    if colors and classToken and colors[classToken] then
        local c = colors[classToken]
        return { c.r, c.g, c.b, 1 }
    end
    return {1, 1, 1, 1}
end

function GetPlayerClassColorByName(playerName)
    local currentRealm = GetRealmName()
    for _, entry in ipairs(AssignmentModule.activeRoster or {}) do
        if type(entry) == "table" and entry.name and entry.class then
            if AssignmentModule:GetDisplayName(entry.name):lower() == AssignmentModule:GetDisplayName(playerName):lower() then
                return GetClassColor(entry.class)
            end
        end
    end
    local numGuild = GetNumGuildMembers() or 0
    for i = 1, numGuild do
        local fullName, _, _, _, _, _, _, _, _, _, classToken = GetGuildRosterInfo(i)
        if fullName then
            local filteredName = AssignmentModule:GetDisplayName(fullName)
            if AssignmentModule:GetDisplayName(playerName):lower() == filteredName:lower() then
                return GetClassColor(classToken)
            end
        end
    end
    return {1, 1, 1, 1}
end

local function IsCursorInFrame(frame, margin)
    margin = margin or 10
    local cx, cy = GetCursorPosition()
    local scale = frame:GetEffectiveScale()
    cx = cx / scale
    cy = cy / scale
    local left, right = frame:GetLeft(), frame:GetRight()
    local top, bottom = frame:GetTop(), frame:GetBottom()
    return cx >= left - margin and cx <= right + margin and cy <= top + margin and cy >= bottom - margin
end

local function IsCursorInEditBox(editBox, marginY, marginX)
    marginY = marginY or 8
    marginX = marginX or 15
    local cx, cy = GetCursorPosition()
    local scale = editBox:GetEffectiveScale()
    cx = cx / scale
    cy = cy / scale
    local left, right = editBox:GetLeft(), editBox:GetRight()
    local top, bottom = editBox:GetTop(), editBox:GetBottom()
    return cx >= left - marginX and cx <= right + marginX and cy <= top + marginY and cy >= bottom - marginY
end

local function CreateAssignmentSlot(parent, width, height)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(width, height)
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1
    })
    container:SetBackdropColor(0.1, 0.1, 0.1, 1)
    container:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    local editBox = CreateFrame("EditBox", nil, container)
    editBox:SetAllPoints(container)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetText("")    
    editBox.usedName = nil     
    editBox:SetScript("OnEditFocusLost", function(self)
        local plain = self:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        plain = plain:match("^%s*(.-)%s*$") or ""  
        if plain == "" then
            self.usedName = nil
        else
            local filtered = AssignmentModule:GetDisplayName(plain)
            local color = GetPlayerClassColorByName(filtered)
            local r, g, b = color[1], color[2], color[3]
            local hexColor = string.format("%02x%02x%02x", r*255, g*255, b*255)
            self:SetText("|cff" .. hexColor .. filtered .. "|r")
            self:SetCursorPosition(0)
            self.usedName = filtered
        end
        AssignmentModule:UpdateRosterList()
    end)
    return editBox
end

function AssignmentModule:UpdateRosterList()
    if not self.nameListContent then return end
    local allowDuplicates = self.allowDuplicates
    local used = {}
    if self.currentSlots and not allowDuplicates then
        for _, group in ipairs(self.currentSlots) do
            for _, slot in ipairs(group) do
                if slot.usedName then
                    used[slot.usedName] = true
                end
            end
        end
    end

    local names = self.activeRoster or {}
    local yOffset = -2
    local index = 0
    for _, entry in ipairs(names) do
        local playerName = (type(entry) == "table") and entry.name or entry
        if playerName and (allowDuplicates or not used[playerName]) then
            index = index + 1
            local color
            if type(entry) == "table" and entry.class then
                color = GetClassColor(entry.class)
            else
                color = GetPlayerClassColorByName(playerName)
            end
            local frame = self.nameFrames[index]
            if frame then
                frame.playerName = playerName
                frame.classColor = color or {1, 1, 1, 1}
                frame.nameText:SetText(self:GetDisplayName(playerName))
                frame.nameText:SetTextColor(unpack(color or {1, 1, 1, 1}))
                frame.originalParent = self.nameListContent
            else
                frame = self:CreateDraggableNameFrame(self.nameListContent, playerName, color or {1, 1, 1, 1})
                self.nameFrames[index] = frame
            end
            frame:SetParent(self.nameListContent)
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", self.nameListContent, "TOPLEFT", 0, yOffset)
            frame.originalPoint = "TOPLEFT"
            frame.originalRelPoint = "TOPLEFT"
            frame.originalX = 0
            frame.originalY = yOffset
            frame:Show()
            yOffset = yOffset - 22
        end
    end
    for i = index+1, #self.nameFrames do
        self.nameFrames[i]:Hide()
    end

    local totalEntries = index
    local lineHeight = 22
    local contentHeight = 0
    local extraPaddingMinimal = 5 
    local bottomPadding = 10  
    if totalEntries < 40 then
        contentHeight = totalEntries * lineHeight + extraPaddingMinimal
    else
        contentHeight = 40 * lineHeight + bottomPadding
    end

    self.nameListContent:SetHeight(contentHeight)

    if self.rosterScroll then
        self.rosterScroll:SetVerticalScroll(0)
    end
end

function AssignmentModule:CreateDraggableNameFrame(parent, playerName, classColor)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(200, 20)
    frame:SetFrameStrata("HIGH")
    frame:SetBackdrop({
        bgFile = nil,
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1
    })
    frame:SetBackdropBorderColor(1, 1, 1, 1)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame.nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.nameText:SetPoint("CENTER")
    frame.nameText:SetText(self:GetDisplayName(playerName))
    frame.nameText:SetTextColor(unpack(classColor or {1,1,1,1}))
    frame.classColor = classColor or {1,1,1,1}
    frame.playerName = playerName
    frame.originalParent = parent
    frame.originalPoint, frame.originalRelPoint = nil, nil
    frame.originalX, frame.originalY = nil, nil
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            if ClearAllEditFocus then ClearAllEditFocus() end 
            AssignmentModule.DragContainer = AssignmentModule.DragContainer or CreateFrame("Frame", "Assignment_DragContainer", UIParent)
            local dragLayer = AssignmentModule.DragContainer
            dragLayer:SetAllPoints(UIParent)
            dragLayer:SetFrameStrata("HIGH")
            dragLayer:SetFrameLevel(400)
            self:SetParent(dragLayer)
            self:SetFrameLevel(400)
            self:ClearAllPoints()
            self:StartMoving()
        end
    end)
    frame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self:StopMovingOrSizing()
            local dropped = false
            if AssignmentModule.currentSlots then
                for _, group in ipairs(AssignmentModule.currentSlots) do
                    for _, editBox in ipairs(group) do
                        if editBox and editBox:IsVisible() then
                            if editBox:GetLeft() and editBox:GetRight() then
                                local cx, cy = GetCursorPosition()
                                local scale = editBox:GetEffectiveScale()
                                cx, cy = cx/scale, cy/scale
                                local left, right = editBox:GetLeft(), editBox:GetRight()
                                local top, bottom = editBox:GetTop(), editBox:GetBottom()
                                if cx >= left - 15 and cx <= right + 15 and cy >= bottom - 8 and cy <= top + 8 then
                                    local name = AssignmentModule:GetDisplayName(self.playerName) or ""
                                    local r, g, b = unpack(self.classColor or {1,1,1,1})
                                    local hexColor = string.format("%02x%02x%02x", r*255, g*255, b*255)
                                    editBox:SetText("|cff" .. hexColor .. name .. "|r")
                                    editBox:SetJustifyH("LEFT")
                                    editBox:SetCursorPosition(0)
                                    editBox.usedName = name
                                    self:Hide()
                                    dropped = true
                                    break
                                end
                            end
                        end
                    end
                    if dropped then break end
                end
            end
            if not dropped then
                if self.originalPoint and self.originalRelPoint then
                    self:SetParent(self.originalParent or parent)
                    self:ClearAllPoints()
                    self:SetPoint(self.originalPoint, self.originalParent or parent, self.originalRelPoint, self.originalX or 0, self.originalY or 0)
                end
                self:Show() 
            else
                AssignmentModule:UpdateRosterList()
            end
        end
    end)
    return frame
end

function AssignmentModule:LoadBossUI(bossId)
    if self.bossFrame then
        for _, child in ipairs({ self.bossFrame:GetChildren() }) do
            child:Hide()
            child:SetParent(nil)
        end
    end
    self.currentSlots = nil  
    self.selectedBoss = bossId
    if AssignmentBossUI and AssignmentBossUI[bossId] then
        AssignmentBossUI[bossId](self.bossFrame, self.activeRoster)
        if self.currentSlots then
            for _, group in ipairs(self.currentSlots) do
                for _, editBox in ipairs(group) do
                    editBox:SetScript("OnEditFocusLost", function(self)
                        local plain = self:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                        plain = plain:match("^%s*(.-)%s*$") or ""
                        if plain == "" then
                            self.usedName = nil
                        else
                            local filtered = AssignmentModule:GetDisplayName(plain)
                            local color = GetPlayerClassColorByName(filtered)
                            local r, g, b = color[1], color[2], color[3]
                            local hexColor = string.format("%02x%02x%02x", r*255, g*255, b*255)
                            self:SetText("|cff" .. hexColor .. filtered .. "|r")
                            self:SetCursorPosition(0)
                            self.usedName = filtered
                        end
                        AssignmentModule:UpdateRosterList()
                    end)
                    
                    editBox:EnableMouse(true)
                    editBox:RegisterForDrag("LeftButton")
                    editBox:SetScript("OnDragStart", function(self)
                        if self:HasFocus() then
                            self:ClearFocus()
                            C_Timer.After(0.01, function()
                                self.dragStartX, self.dragStartY = GetCursorPosition()
                                self.isDragging = false
                                self:SetScript("OnUpdate", function(self)
                                    if not IsCursorInEditBox(self, 0, 0) then
                                        self.isDragging = true
                                        self:SetScript("OnUpdate", nil)
                                        if self.usedName and self.usedName ~= "" then
                                            AssignmentModule.DragContainer = AssignmentModule.DragContainer or CreateFrame("Frame", "Assignment_DragContainer", UIParent)
                                            local dragLayer = AssignmentModule.DragContainer
                                            dragLayer:SetAllPoints(UIParent)
                                            dragLayer:SetFrameStrata("HIGH")
                                            dragLayer:SetFrameLevel(400)
                                            local dragFrame = CreateFrame("Frame", nil, dragLayer, "BackdropTemplate")
                                            dragFrame:SetSize(self:GetWidth(), self:GetHeight())
                                            dragFrame:SetFrameStrata("TOOLTIP")
                                            dragFrame:SetBackdrop({
                                                bgFile = "Interface\\Buttons\\WHITE8x8",
                                                edgeFile = "Interface\\Buttons\\WHITE8x8",
                                                edgeSize = 1
                                            })
                                            dragFrame:SetBackdropBorderColor(1,1,1,1)
                                            dragFrame.text = dragFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                                            dragFrame.text:SetPoint("CENTER")
                                            dragFrame.text:SetText(self.usedName)
                                            dragFrame:EnableMouse(false)
                                            dragFrame:SetScript("OnUpdate", function(frame)
                                                local cx, cy = GetCursorPosition()
                                                local scale = UIParent:GetEffectiveScale()
                                                frame:ClearAllPoints()
                                                frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx/scale, cy/scale)
                                            end)
                                            self.dragFrame = dragFrame
                                        end
                                    end
                                end)
                            end)
                        else
                            self.dragStartX, self.dragStartY = GetCursorPosition()
                            self.isDragging = false
                            self:SetScript("OnUpdate", function(self)
                                if not IsCursorInEditBox(self, 0, 0) then
                                    self.isDragging = true
                                    self:SetScript("OnUpdate", nil)
                                    if self.usedName and self.usedName ~= "" then
                                        AssignmentModule.DragContainer = AssignmentModule.DragContainer or CreateFrame("Frame", "Assignment_DragContainer", UIParent)
                                        local dragLayer = AssignmentModule.DragContainer
                                        dragLayer:SetAllPoints(UIParent)
                                        dragLayer:SetFrameStrata("HIGH")
                                        dragLayer:SetFrameLevel(400)
                                        local dragFrame = CreateFrame("Frame", nil, dragLayer, "BackdropTemplate")
                                        dragFrame:SetSize(self:GetWidth(), self:GetHeight())
                                        dragFrame:SetFrameStrata("TOOLTIP")
                                        dragFrame:SetBackdrop({
                                            bgFile = "Interface\\Buttons\\WHITE8x8",
                                            edgeFile = "Interface\\Buttons\\WHITE8x8",
                                            edgeSize = 1
                                        })
                                        dragFrame:SetBackdropBorderColor(1,1,1,1)
                                        dragFrame.text = dragFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                                        dragFrame.text:SetPoint("CENTER")
                                        dragFrame.text:SetText(self.usedName)
                                        dragFrame:EnableMouse(false)
                                        dragFrame:SetScript("OnUpdate", function(frame)
                                            local cx, cy = GetCursorPosition()
                                            local scale = UIParent:GetEffectiveScale()
                                            frame:ClearAllPoints()
                                            frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx/scale, cy/scale)
                                        end)
                                        self.dragFrame = dragFrame
                                    end
                                end
                            end)
                        end
                    end)
                    editBox:SetScript("OnDragStop", function(self)
                        self:SetScript("OnUpdate", nil)
                        if self.dragFrame then
                            local dragFrame = self.dragFrame
                            dragFrame:SetScript("OnUpdate", nil)
                            dragFrame:Hide()
                            local dropTarget = nil
                            for _, group in ipairs(AssignmentModule.currentSlots or {}) do
                                for _, target in ipairs(group) do
                                    if target and IsCursorInEditBox(target, 8, 15) then
                                        dropTarget = target
                                        break
                                    end
                                end
                                if dropTarget then break end
                            end
                            local sourceEditBox = self
                            local sourceText = sourceEditBox.usedName or (sourceEditBox:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
                            sourceText = AssignmentModule:GetDisplayName(sourceText)
                            if dropTarget then
                                if dropTarget ~= sourceEditBox then
                                    local targetText = dropTarget.usedName or (dropTarget:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
                                    targetText = AssignmentModule:GetDisplayName(targetText)
                                    if targetText and targetText ~= "" then
                                        local sourceColor = GetPlayerClassColorByName(sourceText) or {1,1,1,1}
                                        local targetColor = GetPlayerClassColorByName(targetText) or {1,1,1,1}
                                        local sourceHex = string.format("%02x%02x%02x", sourceColor[1]*255, sourceColor[2]*255, sourceColor[3]*255)
                                        local targetHex = string.format("%02x%02x%02x", targetColor[1]*255, targetColor[2]*255, targetColor[3]*255)
                                        sourceEditBox:SetText("|cff" .. targetHex .. targetText .. "|r")
                                        sourceEditBox:SetJustifyH("LEFT")
                                        sourceEditBox:SetCursorPosition(0)
                                        sourceEditBox.usedName = targetText
                                        dropTarget:SetText("|cff" .. sourceHex .. sourceText .. "|r")
                                        dropTarget:SetJustifyH("LEFT")
                                        dropTarget:SetCursorPosition(0)
                                        dropTarget.usedName = sourceText
                                    else
                                        local sourceColor = GetPlayerClassColorByName(sourceText) or {1,1,1,1}
                                        local sourceHex = string.format("%02x%02x%02x", sourceColor[1]*255, sourceColor[2]*255, sourceColor[3]*255)
                                        dropTarget:SetText("|cff" .. sourceHex .. sourceText .. "|r")
                                        dropTarget:SetJustifyH("LEFT")
                                        dropTarget:SetCursorPosition(0)
                                        dropTarget.usedName = sourceText
                                        sourceEditBox:SetText("")
                                        sourceEditBox:SetJustifyH("LEFT")
                                        sourceEditBox:SetCursorPosition(0)
                                        sourceEditBox.usedName = nil
                                    end
                                end
                            else
                                if AssignmentModule.nameListContent and IsCursorInFrame(AssignmentModule.nameListContent) then
                                    sourceEditBox:SetText("")
                                    sourceEditBox:SetJustifyH("LEFT")
                                    sourceEditBox:SetCursorPosition(0)
                                    sourceEditBox.usedName = nil
                                    AssignmentModule:UpdateRosterList()
                                else
                                    local plain = sourceText or ""
                                    if plain ~= "" then
                                        local color = GetPlayerClassColorByName(plain)
                                        if color then
                                            local hexColor = string.format("%02x%02x%02x", color[1]*255, color[2]*255, color[3]*255)
                                            sourceEditBox:SetText("|cff" .. hexColor .. plain .. "|r")
                                        else
                                            sourceEditBox:SetText(plain)
                                        end
                                    else
                                        sourceEditBox:SetText("")
                                    end
                                    sourceEditBox:SetJustifyH("LEFT")
                                    sourceEditBox:SetCursorPosition(0)
                                end
                            end
                            self.dragFrame = nil
                        end
                    end)
                end
            end
        end
    end
end

function AssignmentModule:GetConfigSize()
    return 1200, 600  
end

function AssignmentModule:CreateConfigPanel(parent)
    if self.configPanel then
        self.configPanel:SetParent(parent)
        self.configPanel:ClearAllPoints()
        self.configPanel:SetAllPoints(parent)
        self.configPanel:Show()
        self.Presets = VACT.RaidGroupsPresets or {}
        self:UpdatePresetsDropdown()
        self:UpdateRosterList()
        return self.configPanel
    end

    local configPanel = CreateFrame("Frame", nil, parent)
    configPanel:SetAllPoints(parent)
    local titleLabel = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleLabel:SetPoint("TOPLEFT", configPanel, "TOPLEFT", 20, 16)
    titleLabel:SetText("Assignments")

    local raidDropdown = UI:CreateDropdown(configPanel, 180, 30)
    raidDropdown:SetPoint("TOPLEFT", configPanel, "TOPLEFT", 20, -40)
    raidDropdown.button.text:SetText("Select Raid")
    self.raidDropdown = raidDropdown

    local bossDropdown = UI:CreateDropdown(configPanel, 180, 30)
    bossDropdown:SetPoint("LEFT", raidDropdown, "RIGHT", 20, 0)
    bossDropdown.button.text:SetText("Select Boss")
    self.bossDropdown = bossDropdown

    local presetsDropdown = UI:CreateDropdown(configPanel, 200, 30)
    presetsDropdown:SetPoint("LEFT", bossDropdown, "RIGHT", 20, 0)
    presetsDropdown.button.text:SetText("Roster Preset")
    self.presetsDropdown = presetsDropdown

    local grabButton = UI:CreateButton(configPanel, "Grab Current Roster", 140, 30)
    grabButton:SetPoint("LEFT", presetsDropdown, "RIGHT", 20, 0)
    grabButton:SetScript("OnClick", function()
        AssignmentModule.selectedPresetIndex = nil
        if AssignmentModule.presetsDropdown then
            AssignmentModule.presetsDropdown.button.text:SetText("Roster Preset")
        end
        local rosterList = {}
        if IsInRaid() then
            local numRaid = GetNumGroupMembers() or 0
            for i = 1, numRaid do
                local name, _, _, _, _, class = GetRaidRosterInfo(i)
                if name then
                    table.insert(rosterList, { name = name, class = class })
                end
            end
        end
        AssignmentModule.activeRoster = rosterList
        AssignmentModule:StripActiveRoster()
        AssignmentModule:UpdateRosterList()
    end)

    local clearButton = UI:CreateButton(configPanel, "Clear Roster", 140, 30)
    clearButton:SetPoint("BOTTOMLEFT", grabButton, "TOPLEFT", 0, 10)
    clearButton:SetScript("OnClick", function()
        AssignmentModule.selectedPresetIndex = nil
        if AssignmentModule.presetsDropdown then
            AssignmentModule.presetsDropdown.button.text:SetText("Roster Preset")
        end
        AssignmentModule.activeRoster = {}
        AssignmentModule:UpdateRosterList()
        if AssignmentModule.currentSlots then
            for _, group in ipairs(AssignmentModule.currentSlots) do
                for _, slot in ipairs(group) do
                    slot:SetText("")
                    slot.usedName = nil
                end
            end
        end
    end)

    local applyButton = UI:CreateButton(configPanel, "Apply Roster", 120, 30)
    applyButton:SetPoint("LEFT", grabButton, "RIGHT", 20, 0)
    applyButton:SetScript("OnClick", function()
        if not AssignmentModule.selectedPresetIndex then return end
        local preset = AssignmentModule.Presets[AssignmentModule.selectedPresetIndex]
        if preset and preset.data then
            local rosterList = {}
            for part in string.gmatch(preset.data, "Group%d+:%s*([^;]+)") do
                for name in string.gmatch(part, "([^,]+)") do
                    local trimmed = name:match("^%s*(.-)%s*$")
                    if trimmed and trimmed ~= "" then
                        table.insert(rosterList, trimmed)
                    end
                end
            end
            AssignmentModule.activeRoster = rosterList
            AssignmentModule:StripActiveRoster()
            AssignmentModule:UpdateRosterList()
        end
    end)

    local rosterFrame = CreateFrame("Frame", nil, configPanel)
    rosterFrame:SetSize(220, 460) 
    rosterFrame:SetPoint("TOPLEFT", configPanel, "TOPLEFT", 20, -80)
    local listScroll = CreateFrame("ScrollFrame", nil, rosterFrame, "UIPanelScrollFrameTemplate")
    listScroll:SetSize(210, 420)  
    listScroll:SetPoint("TOPLEFT", rosterFrame, "TOPLEFT", 0, 0)
    local listContent = CreateFrame("Frame", nil, listScroll)
    listContent:SetSize(210, 420)
    listScroll:SetScrollChild(listContent)
    AssignmentModule.nameListContent = listContent

    local bossFrame = CreateFrame("Frame", nil, configPanel)
    bossFrame:SetSize(840, 500)
    bossFrame:SetPoint("TOPLEFT", rosterFrame, "TOPRIGHT", 40, 0)
    self.bossFrame = bossFrame

    local raidOptions = {}
    for i, raid in ipairs(self.raids) do
        table.insert(raidOptions, {
            text = raid.name,
            value = i,
            onClick = function()
                AssignmentModule.selectedRaid = i
                raidDropdown.button.text:SetText(raid.name)
                local bossOptions = {}
                for _, boss in ipairs(raid.bosses or {}) do
                    table.insert(bossOptions, {
                        text = boss.name,
                        value = boss.id,
                        onClick = function()
                            bossDropdown.button.text:SetText(boss.name)
                            AssignmentModule:LoadBossUI(boss.id)
                        end
                    })
                end
                UI:SetDropdownOptions(bossDropdown, bossOptions)
                bossDropdown.button.text:SetText("Select Boss")
                AssignmentModule:LoadBossUI(nil) 
            end
        })
    end
    UI:SetDropdownOptions(raidDropdown, raidOptions)
    if #raidOptions > 0 then
        raidOptions[1].onClick() 
    end

    self.Presets = VACT.RaidGroupsPresets or {}
    function AssignmentModule:UpdatePresetsDropdown()
        local options = {}
        for idx, preset in ipairs(AssignmentModule.Presets or {}) do
            table.insert(options, {
                text = preset.name,
                value = idx,
                onClick = function()
                    AssignmentModule.selectedPresetIndex = idx
                    presetsDropdown.button.text:SetText(preset.name)
                end
            })
        end
        UI:SetDropdownOptions(presetsDropdown, options)
    end
    self:UpdatePresetsDropdown()
    self:UpdateRosterList()
    self.configPanel = configPanel
    return configPanel
end

if ACT and ACT.RegisterModule then
    ACT:RegisterModule(AssignmentModule)
end