local MacrosModule = {}

MacrosModule.title = "Macros"

function MacrosModule:GetConfigSize()
    return 800, 600 
end

function MacrosModule:CreateConfigPanel(parent)
    if self.configPanel then
        self.configPanel:SetParent(parent)
        self.configPanel:ClearAllPoints()
        self.configPanel:SetAllPoints(parent)
        self.configPanel:Show()
        return
    end

    local configPanel = CreateFrame("Frame", nil, parent)
    configPanel:SetAllPoints()

    local title = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", configPanel, "TOPLEFT", 20, 16)
    title:SetText("Macros")

    local focusMacroFrame, focusMacroEditBox = UI:CreateReadOnlyBox(configPanel, 240, 70, "")
    focusMacroFrame:SetPoint("TOPLEFT", 10, -90)
    self.focusMacroEdit = focusMacroEditBox

    local focusMacroLabel = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    focusMacroLabel:SetPoint("BOTTOM", focusMacroEditBox, "TOP", 0, 45)
    focusMacroLabel:SetText("Set Focus + Target Marker Macro")

    self.markerIcons = {}
    local buttonSpacing = 27 
    local buttonSize = 25 
    local totalWidth = buttonSpacing * 8 
    local startX = (27 - totalWidth) / 2 

    for i = 1, 8 do
        local button = CreateFrame("Button", nil, configPanel)
        self.markerIcons[i] = button
        button:SetSize(buttonSize, buttonSize) 
        button:SetPoint("BOTTOM", focusMacroEditBox, "TOP", startX + (i - 1) * buttonSpacing, 10)
        
        local texture = button:CreateTexture(nil, "BACKGROUND")
        texture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i)
        texture:SetAllPoints()
        
        local macroText = "/focus [@target]\n/run if not GetRaidTargetIndex(\"focus\") then SetRaidTarget(\"focus\"," .. i .. ") end"
        button:SetScript("OnClick", function()
            self.focusMacroEdit:SetText(macroText)
        end)
    end

    local worldMarkerFrame, worldMarkerEditBox = UI:CreateReadOnlyBox(configPanel, 240, 70, "")
    worldMarkerFrame:SetPoint("TOPLEFT", focusMacroFrame, "TOPRIGHT", 40, 0) 
    self.worldMarkerEdit = worldMarkerEditBox

    local worldMarkerLabel = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    worldMarkerLabel:SetPoint("BOTTOM", worldMarkerEditBox, "TOP", 0, 45)
    worldMarkerLabel:SetText("Place + Clear World Marker Macro")

    self.worldMarkerIcons = {}
    local markerMap = {5, 6, 3, 2, 7, 1, 4, 8}
    local buttonSpacing = 27 
    local buttonSize = 25 
    local totalWidth = buttonSpacing * 8 
    local startX = (27 - totalWidth) / 2 

    for i = 1, 8 do
        local button = CreateFrame("Button", nil, configPanel)
        self.worldMarkerIcons[i] = button
        button:SetSize(buttonSize, buttonSize) 
        button:SetPoint("BOTTOM", worldMarkerEditBox, "TOP", startX + (i - 1) * buttonSpacing, 10)
        
        local texture = button:CreateTexture(nil, "BACKGROUND")
        texture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i)
        texture:SetAllPoints()
        
        local macroText = "/cwm " .. markerMap[i] .. "\n/wm [@cursor] " .. markerMap[i]
        button:SetScript("OnClick", function()
            self.worldMarkerEdit:SetText(macroText)
        end)
    end

    local waMacroFrame, waMacroEditBox = UI:CreateReadOnlyBox(configPanel, 240, 110, "/ping [@player] Warning\n/run WeakAuras.ScanEvents(\"LIQUID_PRIVATE_AURA_MACRO\", true)\n/run WeakAuras.ScanEvents(\"NS_PA_MACRO\", true)")
    waMacroFrame:SetPoint("TOPLEFT", 10, -210)
    self.waMacroEdit = waMacroEditBox

    local waLabel = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    waLabel:SetPoint("BOTTOM", waMacroEditBox, "TOP", 0, 15)
    waLabel:SetText("WeakAuras Macros")

    local externalMacroFrame, externalMacroEditBox = UI:CreateReadOnlyBox(configPanel, 240, 110, "/ping [@player] Warning\n/run WeakAuras.ScanEvents(\"NS_EXTERNAL\", true)")
    externalMacroFrame:SetPoint("TOPLEFT", waMacroFrame, "TOPRIGHT", 40, 0)
    self.externalMacroEdit = externalMacroEditBox

    local externalLabel = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    externalLabel:SetPoint("BOTTOM", externalMacroEditBox, "TOP", 0, 15)
    externalLabel:SetText("External Macro")

    self.configPanel = configPanel
    return configPanel
end

if ACT and ACT.RegisterModule then
    ACT:RegisterModule(MacrosModule)
end