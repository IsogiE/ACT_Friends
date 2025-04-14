AssignmentBossUI = AssignmentBossUI or {}
AssignmentBossUI["onearmedbandit"] = function(parentFrame, rosterList)
    local frame = CreateFrame("Frame", nil, parentFrame)
    frame:SetAllPoints(parentFrame)

    local orderLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    orderLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
    orderLabel:SetText("Spin-to-Win Order:")

    local outcomes = { "None", "SF", "SB", "FB", "FC", "CS", "CB" }
    local dropdowns = {}
    local prev = orderLabel
    for i = 1, 6 do
        local dd = UI:CreateDropdown(frame, 60, 25)
        if i == 1 then
            dd:SetPoint("LEFT", orderLabel, "RIGHT", 38, 0)
        else
            local arrow = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            arrow:SetPoint("LEFT", prev, "RIGHT", 5, 0)
            arrow:SetText(">")
            dd:SetPoint("LEFT", arrow, "RIGHT", 5, 0)
        end
        dd.button.text:SetText(outcomes[1])
        local options = {}
        for _, code in ipairs(outcomes) do
            table.insert(options, {
                text = code,
                value = code,
                onClick = function() dd.button.text:SetText(code) end
            })
        end
        UI:SetDropdownOptions(dd, options)
        dropdowns[i] = dd
        prev = dd
    end

    AssignmentModule = AssignmentModule or {}
    AssignmentModule.allowDuplicates = false

    local dispelLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dispelLabel:SetPoint("TOPLEFT", orderLabel, "BOTTOMLEFT", 0, -30)
    dispelLabel:SetText("Withering Flame Dispel:")

    local dispelSlots = {}
    for row = 1, 2 do
        for col = 1, 3 do
            local index = (row - 1) * 3 + col
            local slot = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            slot:SetSize(100, 20)
            if row == 1 then
                if col == 1 then
                    slot:SetPoint("LEFT", dispelLabel, "RIGHT", 10, 0)
                else
                    slot:SetPoint("LEFT", dispelSlots[index - 1], "RIGHT", 10, 0)
                end
            else
                if col == 1 then
                    slot:SetPoint("TOPLEFT", dispelSlots[1], "BOTTOMLEFT", 0, -10)
                else
                    slot:SetPoint("LEFT", dispelSlots[index - 1], "RIGHT", 10, 0)
                end
            end
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
            editBox.usedName = nil
            editBox:SetScript("OnEscapePressed", function(self)
                self:ClearFocus()
            end)
            dispelSlots[index] = editBox
        end
    end

    AssignmentModule.currentSlots = { dispelSlots } 

    frame:SetScript("OnHide", function()
        for _, slot in ipairs(dispelSlots) do
            slot:SetText("")
            slot.usedName = nil
        end
        AssignmentModule:UpdateRosterList()
    end)

    local bossID = "onearmedbandit"
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
        local sequence = {}
        for _, dd in ipairs(dropdowns) do
            local choice = dd.button.text:GetText()
            if choice and choice ~= "" and choice ~= "None" then
                table.insert(sequence, choice)
            end
        end
        local dispelNames = {}
        for _, slot in ipairs(dispelSlots) do
            if slot.usedName and slot.usedName ~= "" then
                table.insert(dispelNames, slot.usedName)
            end
        end
        local note = "liquidStart\n" .. table.concat(sequence, " ") .. "\nliquidEnd\n\nliquidStart2\n" .. table.concat(dispelNames, " ") .. "\nliquidEnd2"
        local popup, editBox = UI:CreatePopupWithEditBox("Assignment Note - One-Armed Bandit", 400, 200, note, function(text)
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
                if preset.dropdowns then
                    for i, value in ipairs(preset.dropdowns) do
                        local dd = dropdowns[i]
                        if dd then
                            dd.button.text:SetText(value)
                        end
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
        local dropdownData = {}
        for i, dd in ipairs(dropdowns) do
            dropdownData[i] = dd.button.text:GetText() or "None"
        end
        local presetName = "Preset " .. date("%Y-%m-%d %H:%M:%S")
        table.insert(VACT.BossPresets[bossID], { name = presetName, data = data, dropdowns = dropdownData })
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
        for _, dd in ipairs(dropdowns) do
            dd.button.text:SetText("None")
        end
    end)
    
    clearUIButton:SetPoint("RIGHT", savePresetButton, "LEFT", -spacing, 0)
end