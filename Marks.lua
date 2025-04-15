local RaidMarksModule = {}
RaidMarksModule.title = "Marks"

local function CreateCustomEditBox(parent, width, height)
    local edit = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    edit:SetSize(width, height)
    edit:SetAutoFocus(false)
    edit:SetFont("Fonts\\FRIZQT__.TTF", 14, "") 
    edit:SetJustifyH("LEFT")

    edit:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    edit:SetBackdropColor(0, 0, 0, 0) 
    edit:SetBackdropBorderColor(0.3, 0.3, 0.3, 1) 

    edit:SetText("")
    edit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    return edit
end

function RaidMarksModule:GetConfigSize()
    return 800, 600
end

function RaidMarksModule:CreateConfigPanel(parent)
    if self.configPanel then
        self.configPanel:SetParent(parent)
        self.configPanel:ClearAllPoints()
        self.configPanel:SetAllPoints(parent)
        self.configPanel:Show()
        return self.configPanel
    end

    local configPanel = CreateFrame("Frame", nil, parent)
    configPanel:SetAllPoints()

    local title = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", configPanel, "TOPLEFT", 20, 16)
    title:SetText(self.title)

    local toggleButton = UI:CreateButton(configPanel, "Enable", 140, 30)
    toggleButton:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)

    local clearButton = UI:CreateButton(configPanel, "Clear UI", 140, 30)
    clearButton:SetPoint("LEFT", toggleButton, "RIGHT", 10, 0)

    toggleButton:SetScript("OnClick", function(self)
        if not RaidMarksModule.Enabled then
            RaidMarksModule:Enable()
            self.text:SetText("Disable")
        else
            RaidMarksModule:Disable()
            self.text:SetText("Enable")
        end
    end)

    clearButton:SetScript("OnClick", function()
        RaidMarksModule:ClearMarks()
    end)

    self.rows = {}
    local rowSpacing = 8 
    local rowStartY  = -10
    for i = 1, 8 do
        local icon = configPanel:CreateTexture(nil, "ARTWORK")
        icon:SetSize(24, 24) 
        icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i)
        icon:SetPoint("TOPLEFT", toggleButton, "BOTTOMLEFT", 0, rowStartY - (i - 1) * (24 + rowSpacing))

        local editBox = CreateCustomEditBox(configPanel, 300, 24)
        editBox:SetPoint("LEFT", icon, "RIGHT", 10, 0)

        self.rows[i] = {icon = icon, editBox = editBox}
    end

    self.configPanel = configPanel
    return configPanel
end

function RaidMarksModule:Enable()
    self.Enabled = true
    if not self.timerFrame then
        self.timerFrame = CreateFrame("Frame")
        self.timerFrame:SetScript("OnUpdate", function(frame, elapsed)
            self:OnUpdate(elapsed)
        end)
    end
end

function RaidMarksModule:Disable()
    self.Enabled = false
    if self.timerFrame then
        self.timerFrame:SetScript("OnUpdate", nil)
        self.timerFrame = nil
    end
end

function RaidMarksModule:ClearMarks()
    for i = 1, 8 do
        local row = self.rows[i]
        if row and row.editBox then
            row.editBox:SetText("")
        end
    end
end

function RaidMarksModule:OnUpdate(elapsed)
    self.tmr = (self.tmr or 0) + elapsed
    if self.tmr < 0.5 then
        return
    end
    self.tmr = 0 
    for i = 1, 8 do
        local row = self.rows[i]
        if row and row.editBox then
            local text = row.editBox:GetText()
            if text and text ~= "" then
                if text:find("[, ]") then
                    for name in text:gmatch("([^,%s]+)") do
                        if UnitName(name) then
                            if GetRaidTargetIndex(name) ~= i then
                                SetRaidTargetIcon(name, i)
                            end
                            break
                        end
                    end
                elseif UnitName(text) then
                    if GetRaidTargetIndex(text) ~= i then
                        SetRaidTargetIcon(text, i)
                    end
                end
            end
        end
    end
end

function RaidMarksModule:OnEnable()
    self:Enable()
end

if ACT and ACT.RegisterModule then
    ACT:RegisterModule(RaidMarksModule)
end

return RaidMarksModule