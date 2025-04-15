AssignmentBossUI = AssignmentBossUI or {}
AssignmentBossUI["rikreverb"] = function(parentFrame, rosterList)
    local frame = CreateFrame("Frame", nil, parentFrame)
    frame:SetAllPoints(parentFrame)
    
    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
    desc:SetText("Amplifier Soakers Assignments")
    
    local markers = { "star", "circle", "diamond", "triangle", "moon", "square", "cross", "skull" }
    local markerLabelWidth = 150
    local prevLabel = nil
    local slotsGroups = {}
    for index, marker in ipairs(markers) do
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        if index == 1 then
            label:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -15)
        else
            label:SetPoint("TOPLEFT", prevLabel, "BOTTOMLEFT", 0, -40)
        end
        label:SetText("{" .. marker .. "} Soakers:")
        label:SetWidth(markerLabelWidth)
        label:SetJustifyH("LEFT")
        prevLabel = label

        local slots = {}
        local prevSlotFrame = nil
        for j = 1, 4 do
            local slot = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            slot:SetSize(100, 20)
            if j == 1 then
                slot:SetPoint("LEFT", label, "RIGHT", 10, 0)
            else
                slot:SetPoint("LEFT", prevSlotFrame, "RIGHT", 10, 0)
            end
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
            slots[j] = editBox
            prevSlotFrame = slot
        end
        table.insert(slotsGroups, slots)
    end

    AssignmentModule.currentSlots = slotsGroups
    AssignmentModule = AssignmentModule or {}
    AssignmentModule.allowDuplicates = false

    frame:SetScript("OnHide", function()
        for _, group in ipairs(AssignmentModule.currentSlots) do
            for _, editBox in ipairs(group) do
                editBox:SetText("")
                editBox.usedName = nil
            end
        end
        if AssignmentModule.UpdateRosterList then
            AssignmentModule:UpdateRosterList()
        end
    end)
    
    local bossID = "rikreverb"
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
        for i, marker in ipairs(markers) do
            local assigned = {}
            for _, slot in ipairs(slotsGroups[i]) do
                if slot.usedName then
                    local name = slot.usedName
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
            if #assigned > 0 then
                note = note .. "{" .. marker .. "} " .. table.concat(assigned, " ") .. "\n"
            end
        end
        note = note .. "liquidEnd"
        local popup, editBox = UI:CreatePopupWithEditBox("Assignment Note - Rik Reverb", 400, 300, note, function(text)
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
            if AssignmentModule.UpdateRosterList then
                AssignmentModule:UpdateRosterList()
            end
        end
    end)
    clearUIButton:SetPoint("RIGHT", savePresetButton, "LEFT", -spacing, 0)
end