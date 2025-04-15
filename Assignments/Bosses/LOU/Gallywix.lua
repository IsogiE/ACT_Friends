AssignmentBossUI = AssignmentBossUI or {}
AssignmentBossUI["gallywix"] = function(parentFrame, rosterList)
    local frame = CreateFrame("Frame", nil, parentFrame)
    frame:SetAllPoints(parentFrame)
    
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
    title:SetText("Scatterblast Cannisters Frontal Assignments")
    
    local setLabel1 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    setLabel1:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -15)
    setLabel1:SetText("Set 1, 3, 5")
    
    local group1 = {}
    local group1Container = CreateFrame("Frame", nil, frame)
    group1Container:SetPoint("TOPLEFT", setLabel1, "BOTTOMLEFT", 0, -5)
    group1Container:SetSize((100 + 10)*5 - 10, (20 + 10)*2 - 10)
    
    for row = 1, 2 do
        for col = 1, 5 do
            local slot = CreateFrame("Frame", nil, group1Container, "BackdropTemplate")
            slot:SetSize(100, 20)
            local xOffset = (col - 1) * (100 + 10)
            local yOffset = -((row - 1) * (20 + 10))
            slot:SetPoint("TOPLEFT", group1Container, "TOPLEFT", xOffset, yOffset)
            
            slot:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
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
            
            table.insert(group1, editBox)
        end
    end

    AssignmentModule = AssignmentModule or {}
    AssignmentModule.allowDuplicates = false
    
    local setLabel2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    setLabel2:SetPoint("TOPLEFT", group1Container, "BOTTOMLEFT", 0, -30)
    setLabel2:SetText("Set 2, 4, 6")
    
    local group2 = {}
    local group2Container = CreateFrame("Frame", nil, frame)
    group2Container:SetPoint("TOPLEFT", setLabel2, "BOTTOMLEFT", 0, -5)
    group2Container:SetSize((100 + 10)*5 - 10, (20 + 10)*2 - 10)
    
    for row = 1, 2 do
        for col = 1, 5 do
            local slot = CreateFrame("Frame", nil, group2Container, "BackdropTemplate")
            slot:SetSize(100, 20)
            local xOffset = (col - 1) * (100 + 10)
            local yOffset = -((row - 1) * (20 + 10))
            slot:SetPoint("TOPLEFT", group2Container, "TOPLEFT", xOffset, yOffset)
            
            slot:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
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
            
            table.insert(group2, editBox)
        end
    end
    
    AssignmentModule.currentSlots = { group1, group2 }
    
    frame:SetScript("OnHide", function()
        for _, group in ipairs(AssignmentModule.currentSlots) do
            for _, editBox in ipairs(group) do
                editBox:SetText("")
                editBox.usedName = nil
            end
        end
        AssignmentModule:UpdateRosterList()
    end)
    
    local bossID = "gallywix"
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

    local function capFirst(str)
        if str and str ~= "" then
            return str:sub(1,1):upper() .. str:sub(2)
        end
        return str
    end
    
    local noteButton = UI:CreateButton(parentFrame, "Generate Note", 120, 25, function()
        if isGenerateNotePopupOpen then return end
        isGenerateNotePopupOpen = true
        local note = "liquidStart\n"
        for _, group in ipairs(AssignmentModule.currentSlots) do
            local assigned = {}
            for _, editBox in ipairs(group) do
                if editBox.usedName then
                    local name = editBox.usedName
                    if LiquidAPI and LiquidAPI.GetName then
                        local nick = LiquidAPI:GetName(name)
                        if nick and nick ~= "" then
                            name = nick
                        end
                    end
                    name = capFirst(name)
                    table.insert(assigned, name)
                end
            end
            note = note .. table.concat(assigned, " ") .. "\n"
        end
        note = note .. "liquidEnd"
        local popup, editBox = UI:CreatePopupWithEditBox("Assignment Note - Gallywix", 400, 300, note, function(text)
            isGenerateNotePopupOpen = false
        end, function()
            isGenerateNotePopupOpen = false
        end)
        popup:SetScript("OnHide", function() isGenerateNotePopupOpen = false end)
        popup:Show()
        editBox:ClearFocus()
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
        if isRenamePopupOpen then
            return
        end
    
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
    
        isRenamePopupOpen = true
        local popup, editBox = UI:CreatePopupWithEditBox("Save Preset", 320, 150, "",
            function(newName)
                if newName and newName:trim() ~= "" then
                    local presetName = newName
                    table.insert(VACT.BossPresets[bossID], { name = presetName, data = data })
                    UpdatePresetDropdown()
                    presetDropdown.button.text:SetText(presetName)
                end
                isRenamePopupOpen = false
            end,
            function()
                isRenamePopupOpen = false
            end)
        popup:Show()
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