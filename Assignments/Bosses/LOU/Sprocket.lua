AssignmentBossUI = AssignmentBossUI or {}

AssignmentBossUI["sprocketmonger"] = function(parentFrame, rosterList)
    local frame = CreateFrame("Frame", nil, parentFrame)
    frame:SetAllPoints(parentFrame)
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -190, 90)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(scrollFrame:GetWidth())
    scrollFrame:SetScrollChild(content)
    
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
    title:SetText("Mine Assignment Priority")
    
    local topGroup = {}
    local topContainer = CreateFrame("Frame", nil, content)
    topContainer:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -15)
    topContainer:SetSize((100 + 10) * 5 - 10, (20 + 10) * 4 - 10) 
    
    for row = 1, 4 do
        for col = 1, 5 do
            local slot = CreateFrame("Frame", nil, topContainer, "BackdropTemplate")
            slot:SetSize(100, 20)
            local xOffset = (col - 1) * (100 + 10)
            local yOffset = -((row - 1) * (20 + 10))
            slot:SetPoint("TOPLEFT", topContainer, "TOPLEFT", xOffset, yOffset)
            slot:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1
            })
            slot:SetBackdropColor(0.1, 0.1, 0.1, 1)
            slot:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            
            local editBox = CreateFrame("EditBox", nil, slot)
            editBox:SetAllPoints(slot)
            editBox:SetAutoFocus(false)
            editBox:SetFontObject("GameFontHighlightSmall")
            editBox:SetText("")
            editBox:SetScript("OnEscapePressed", function(self)
                self:ClearFocus()
            end)
            editBox.usedName = nil
            
            table.insert(topGroup, editBox)
        end
    end

    AssignmentModule = AssignmentModule or {}
    AssignmentModule.allowDuplicates = true
    
    local labelTexts = { "1 M", "1 R", "2 M", "2 R", "3 M", "3 R", "4 M", "4 R",
                         "5 M", "5 R", "6 M", "6 R", "7 M", "7 R", "8 M", "8 R",
                         "9 M", "9 R" }
    local rowGroups = {}
    local lastElement = topContainer
    for i, labelText in ipairs(labelTexts) do
        local rowLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        if i == 1 then
            rowLabel:SetPoint("TOPLEFT", lastElement, "BOTTOMLEFT", 0, -30)
        else
            rowLabel:SetPoint("TOPLEFT", lastElement, "BOTTOMLEFT", 0, -10)
        end
        rowLabel:SetText(labelText)
        
        local rowContainer1 = CreateFrame("Frame", nil, content)
        rowContainer1:SetPoint("TOPLEFT", rowLabel, "BOTTOMLEFT", 0, -5)
        rowContainer1:SetSize((100 + 10) * 4 - 10, 20)
        local rowGroup = {}
        for col = 1, 4 do
            local slot = CreateFrame("Frame", nil, rowContainer1, "BackdropTemplate")
            slot:SetSize(100, 20)
            local xOffset = (col - 1) * (100 + 10)
            slot:SetPoint("TOPLEFT", rowContainer1, "TOPLEFT", xOffset, 0)
            slot:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1
            })
            slot:SetBackdropColor(0.1, 0.1, 0.1, 1)
            slot:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            
            local editBox = CreateFrame("EditBox", nil, slot)
            editBox:SetAllPoints(slot)
            editBox:SetAutoFocus(false)
            editBox:SetFontObject("GameFontHighlightSmall")
            editBox:SetText("")
            editBox:SetScript("OnEscapePressed", function(self)
                self:ClearFocus()
            end)
            editBox.usedName = nil
            
            table.insert(rowGroup, editBox)
        end
        
        local rowContainer2 = CreateFrame("Frame", nil, content)
        rowContainer2:SetPoint("TOPLEFT", rowContainer1, "BOTTOMLEFT", 0, -5)
        rowContainer2:SetSize((100 + 10) * 4 - 10, 20)
        for col = 1, 4 do
            local slot = CreateFrame("Frame", nil, rowContainer2, "BackdropTemplate")
            slot:SetSize(100, 20)
            local xOffset = (col - 1) * (100 + 10)
            slot:SetPoint("TOPLEFT", rowContainer2, "TOPLEFT", xOffset, 0)
            slot:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1
            })
            slot:SetBackdropColor(0.1, 0.1, 0.1, 1)
            slot:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            
            local editBox = CreateFrame("EditBox", nil, slot)
            editBox:SetAllPoints(slot)
            editBox:SetAutoFocus(false)
            editBox:SetFontObject("GameFontHighlightSmall")
            editBox:SetText("")
            editBox:SetScript("OnEscapePressed", function(self)
                self:ClearFocus()
            end)
            editBox.usedName = nil
            
            table.insert(rowGroup, editBox)
        end
        
        table.insert(rowGroups, rowGroup)
        lastElement = rowContainer2
    end
    
    local totalHeight = 0
    do
        local titleHeight = title:GetStringHeight() or 0
        totalHeight = 10 + titleHeight
        totalHeight = totalHeight + 15 + topContainer:GetHeight()
        if #rowGroups > 0 then
            totalHeight = totalHeight + 30 
            local measureFont = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            measureFont:SetWidth(100)
            measureFont:SetText(labelTexts[1] or "")
            local labelHeight = measureFont:GetStringHeight() or 0
            measureFont:Hide()
            for idx, group in ipairs(rowGroups) do
                if idx > 1 then
                    totalHeight = totalHeight + 10
                end
                totalHeight = totalHeight + labelHeight + 5 + 20 + 5 + 20
            end
        end
        totalHeight = totalHeight + 10
    end
    content:SetHeight(totalHeight)
    
    AssignmentModule.currentSlots = AssignmentModule.currentSlots or {}
    table.insert(AssignmentModule.currentSlots, topGroup)
    for _, group in ipairs(rowGroups) do
        table.insert(AssignmentModule.currentSlots, group)
    end
    
    frame:SetScript("OnHide", function()
        for _, group in ipairs(AssignmentModule.currentSlots) do
            for _, editBox in ipairs(group) do
                editBox:SetText("")
                editBox.usedName = nil
            end
        end
        if AssignmentModule and AssignmentModule.UpdateRosterList then
            AssignmentModule:UpdateRosterList()
        end
    end)
    
    local bossID = "sprocketmonger"
    VACT = VACT or {}
    VACT.BossPresets = VACT.BossPresets or {}
    VACT.BossPresets[bossID] = VACT.BossPresets[bossID] or {}
    
    local isRenamePopupOpen = false
    local isGenerateNotePopupOpen = false

    local presetDropdown

    local function UpdatePresetDropdown()
        local options = {}
        for idx, preset in ipairs(VACT.BossPresets[bossID]) do
            table.insert(options, {
                text = preset.name,
                value = idx,
                onClick = function()
                    presetDropdown.button.text:SetText(preset.name)
                end,
            })
        end
        UI:SetDropdownOptions(presetDropdown, options)
    end

    local noteButton = UI:CreateButton(parentFrame, "Generate Note", 120, 25, function()
        if isGenerateNotePopupOpen then return end
        isGenerateNotePopupOpen = true
        local note = "liquidStart\n"
        local topNames = {}
        for _, editBox in ipairs(topGroup) do
            if editBox.usedName then
                table.insert(topNames, editBox.usedName)
            end
        end
        note = note .. table.concat(topNames, " ") .. "\n\n"
        for idx, group in ipairs(rowGroups) do
            local names = {}
            for _, editBox in ipairs(group) do
                if editBox.usedName then
                    table.insert(names, editBox.usedName)
                end
            end
            if #names > 0 then
                note = note .. labelTexts[idx] .. " " .. table.concat(names, " ") .. "\n"
            end
        end
        note = note .. "liquidEnd"
        local popup, editBox = UI:CreatePopupWithEditBox("Assignment Note - Sprocketmonger", 400, 300, note, function(text)
            isGenerateNotePopupOpen = false
        end, function()
            isGenerateNotePopupOpen = false
        end)
        popup:SetScript("OnHide", function() isGenerateNotePopupOpen = false end)
        popup:Show()
        editBox:ClearFocus()
        editBox:HighlightText()
    end)
    noteButton:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -155, 35)

    local spacing = 10

    local loadPresetButton = UI:CreateButton(parentFrame, "Load Preset", 100, 25, function()
        local selectedText = presetDropdown.button.text:GetText()
        for _, preset in ipairs(VACT.BossPresets[bossID]) do
            if preset.name == selectedText then
                if preset.data and AssignmentModule.currentSlots then
                    for i, group in ipairs(AssignmentModule.currentSlots) do
                        if preset.data[i] then
                            for j, presetName in ipairs(preset.data[i]) do
                                local editBox = group[j]
                                if editBox then
                                    if presetName and presetName ~= "" then
                                        local color = GetPlayerClassColorByName(presetName) or {1,1,1,1}
                                        local r, g, b = color[1], color[2], color[3]
                                        local hexColor = string.format("%02x%02x%02x", r*255, g*255, b*255)
                                        editBox:SetText("|cff" .. hexColor .. presetName .. "|r")
                                        editBox.usedName = presetName
                                    else
                                        editBox:SetText("")
                                        editBox.usedName = nil
                                    end
                                end
                            end
                        end
                    end
                    if AssignmentModule.UpdateRosterList then
                        AssignmentModule:UpdateRosterList()
                    end
                end
                break
            end
        end
    end)
    loadPresetButton:SetPoint("RIGHT", noteButton, "LEFT", -spacing, 0)

    local deletePresetButton = UI:CreateButton(parentFrame, "Delete Preset", 100, 25, function()
        local selectedText = presetDropdown.button.text:GetText()
        local selectedIndex = nil
        for idx, preset in ipairs(VACT.BossPresets[bossID]) do
            if preset.name == selectedText then
                selectedIndex = idx
                break
            end
        end
        if selectedIndex then
            table.remove(VACT.BossPresets[bossID], selectedIndex)
            UpdatePresetDropdown()
            presetDropdown.button.text:SetText("Select Preset")
        end
    end)
    deletePresetButton:SetPoint("RIGHT", loadPresetButton, "LEFT", -spacing, 0)

    local renamePresetButton = UI:CreateButton(parentFrame, "Rename Preset", 100, 25, function()
        if isRenamePopupOpen then return end
        local selectedText = presetDropdown.button.text:GetText()
        local selectedIndex = nil
        for idx, preset in ipairs(VACT.BossPresets[bossID]) do
            if preset.name == selectedText then
                selectedIndex = idx
                break
            end
        end
        if selectedIndex then
            isRenamePopupOpen = true
            local currentPreset = VACT.BossPresets[bossID][selectedIndex]
            local popup, editBox = UI:CreatePopupWithEditBox("Rename Preset", 320, 150, currentPreset.name or "",
                function(newName)
                    if newName and newName:trim() ~= "" then
                        currentPreset.name = newName
                        UpdatePresetDropdown()
                        presetDropdown.button.text:SetText(newName)
                    end
                    isRenamePopupOpen = false
                end,
                function() isRenamePopupOpen = false end)
            popup:Show()
        end
    end)
    renamePresetButton:SetPoint("RIGHT", deletePresetButton, "LEFT", -spacing, 0)

    presetDropdown = UI:CreateDropdown(parentFrame, 200, 25)
    presetDropdown:SetPoint("RIGHT", renamePresetButton, "LEFT", -spacing, 0)
    presetDropdown.button.text:SetText("Select Preset")
    UpdatePresetDropdown()

    local savePresetButton = UI:CreateButton(parentFrame, "Save Preset", 100, 25, function()
        local hasData = false
        local data = {}
        if AssignmentModule.currentSlots then
            for i, group in ipairs(AssignmentModule.currentSlots) do
                data[i] = {}
                for j, editBox in ipairs(group) do
                    local name = editBox.usedName or ""
                    if name ~= "" then hasData = true end
                    data[i][j] = name
                end
            end
        end
        if not hasData then return end
        local presetName = "Preset " .. date("%Y-%m-%d %H:%M:%S")
        table.insert(VACT.BossPresets[bossID], { name = presetName, data = data })
        UpdatePresetDropdown()
        presetDropdown.button.text:SetText(presetName)
    end)
    savePresetButton:SetPoint("RIGHT", presetDropdown, "LEFT", -spacing, 0)

    local clearUIButton = UI:CreateButton(parentFrame, "Clear UI", 100, 25, function()
        if AssignmentModule.currentSlots then
            for _, group in ipairs(AssignmentModule.currentSlots) do
                for _, editBox in ipairs(group) do
                    editBox:SetText("")
                    editBox.usedName = nil
                end
            end
            AssignmentModule:UpdateRosterList()
        end
    end)
    clearUIButton:SetPoint("RIGHT", savePresetButton, "LEFT", -spacing, 0)
end