ACT = LibStub("AceAddon-3.0"):NewAddon("ACT", "AceConsole-3.0", "AceEvent-3.0")

UI = _G["UI"]

ACT.modules = {}

function ACT:RegisterModule(mod)
    table.insert(self.modules, mod)
end

function ACT:OpenConfig()
    if self.configFrame then
        self.configFrame:Show()
        return
    end

    local configFrame = CreateFrame("Frame", "ACT_ConfigFrame", UIParent)
    configFrame:SetSize(800, 600)
    configFrame:SetPoint("CENTER")
    configFrame:SetFrameStrata("HIGH")
    configFrame:EnableMouse(true)
    configFrame:SetMovable(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)

    if not tContains(UISpecialFrames, configFrame:GetName()) then
        tinsert(UISpecialFrames, configFrame:GetName())
    end

    configFrame.bg = configFrame:CreateTexture(nil, "BACKGROUND")
    configFrame.bg:SetAllPoints()
    configFrame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)

    configFrame.border = CreateFrame("Frame", nil, configFrame, "BackdropTemplate")
    configFrame.border:SetAllPoints()
    configFrame.border:SetBackdrop({
        edgeFile = "Interface\\AddOns\\ACT_Friends\\media\\border", 
        edgeSize = 6,
    })

    local closeButton = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -5, -5)

    local sidebar = CreateFrame("Frame", nil, configFrame, "BackdropTemplate")
    sidebar:SetSize(200, 560)
    sidebar:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, -40)

    local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("CENTER", sidebar, "TOP", 0, 10)
    title:SetText("Advance Custom Tools")

    local versionText = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    versionText:SetPoint("CENTER", sidebar, "BOTTOM", 0, 20)

    local function formatVersion(version)
        version = tostring(version)
        if version:find("%.") then
            return version
        elseif #version == 2 then
            return string.sub(version, 1, 1) .. "." .. string.sub(version, 2, 2)
        else
            return version:gsub("(%d)", "%1."):gsub("%.$", "")
        end
    end    

    local vnum = C_AddOns.GetAddOnMetadata("ACT_Friends", "Version")
    local formatted_version = formatVersion(vnum)
    versionText:SetText("Version: " .. formatted_version .. " (Friends)")

    local content = CreateFrame("Frame", nil, configFrame)
    content:SetSize(560, 540)
    content:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 220, -40)
    configFrame.content = content

    local divider = configFrame:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.5, 0.5, 0.5, 0.7)
    divider:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 0, 40)
    divider:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMRIGHT", 0, 0)
    divider:SetWidth(1)

    local selectedButton = nil
    local yOffset = 0
    local firstModule = nil
    local firstButton = nil  

    for i, mod in ipairs(self.modules) do
        if i == 1 then
            firstModule = mod 
        end

        local text = mod.title or ("Module " .. i)
        local btn = UI:CreateButton(sidebar, text, 180, 25)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 10, -10 - (yOffset * 30))

        local defaultColor = {0.1, 0.1, 0.1, 1}
        local hoverColor = {0.2, 0.2, 0.2, 1}
        local selectedColor = {0.3, 0.6, 1, 1}

        btn:SetBackdropColor(unpack(defaultColor))

        btn:SetScript("OnClick", function(self)
            if selectedButton then
                selectedButton:SetBackdropColor(unpack(defaultColor))
            end

            self:SetBackdropColor(unpack(selectedColor))
            selectedButton = self

            ACT.selectedModule = mod 
            ACT:ShowModule(mod)
        end)

        btn:SetScript("OnEnter", function(self)
            if self ~= selectedButton then
                self:SetBackdropColor(unpack(hoverColor))
            end
        end)

        btn:SetScript("OnLeave", function(self)
            if self ~= selectedButton then
                self:SetBackdropColor(unpack(defaultColor))
            end
        end)

        if i == 1 then
            firstButton = btn 
        end

        yOffset = yOffset + 1
    end

    self.configFrame = configFrame
    configFrame:Show()

    if self.selectedModule then
        self:ShowModule(self.selectedModule)
    elseif firstModule then
        self.selectedModule = firstModule
        self:ShowModule(firstModule)

        if firstButton then
            firstButton:SetBackdropColor(0.3, 0.6, 1, 1) 
            selectedButton = firstButton
        end
    end
end

function ACT:ShowModule(mod)
    if not self.configFrame or not self.configFrame.content then return end
    local content = self.configFrame.content

    for _, child in ipairs({ content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    self.configFrame:SetSize(800, 600) 
    content:SetSize(560, 540)  

    local width, height = mod:GetConfigSize()
    self.configFrame:SetSize(width, height)
    content:SetSize(width, height)

    if mod.CreateConfigPanel then
        mod:CreateConfigPanel(content)
    end
end

function ACT:OpenConfigCommand(input)
    self:OpenConfig()
end

function ACT:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ACTDB", {
        profile = {
            nicknames = {},
            nicknamesWiped = false,
            defaultNicknames = "", 
            splits = {
                profiles = {},
                KeepPosInGroup = true,
            },
            useNicknameIntegration = true,
            weakauraUpdater = {},
        }
    }, true)

    if ACT.db.profile.defaultNicknames and ACT.db.profile.defaultNicknames ~= "" then
        for _, mod in ipairs(self.modules) do
            if mod.ProcessImportString then
                mod:ProcessImportString(ACT.db.profile.defaultNicknames)
            end
        end
    elseif DefaultNicknames then
        local importString = table.concat(DefaultNicknames, "")
        for _, mod in ipairs(self.modules) do
            if mod.ProcessImportString then
                mod:ProcessImportString(importString)
            end
        end
    end    
end

function ACT:OnEnable()
    self:RegisterChatCommand("act", "OpenConfigCommand")

    local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("ACT", {
        type = "launcher",
        icon = [[Interface\AddOns\ACT_Friends\media\MiniMap.tga]],
        OnClick = function(clickedframe, button)
            ACT:OpenConfig()
        end,
    })

    local LDBIcon = LibStub("LibDBIcon-1.0")
    if not ACTDB then ACTDB = {} end
    if not ACTDB.minimap then ACTDB.minimap = {} end
    LDBIcon:Register("ACT", LDB, ACTDB.minimap)
end