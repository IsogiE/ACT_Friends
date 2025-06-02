local HomeModule = {}

HomeModule.title = "Home"

function HomeModule:GetConfigSize()
    return 800, 600
end

function HomeModule:CreateConfigPanel(parent)
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
    title:SetText("Home")

    local logo = configPanel:CreateTexture(nil, "ARTWORK")
    logo:SetSize(256, 256)
    logo:SetPoint("TOP", configPanel, "TOP", -120, -50)
    logo:SetTexture("Interface\\AddOns\\ACT_Friends\\media\\logo.tga")
    logo:SetTexCoord(0.05, 0.95, 0.05, 0.95)

    local brick = configPanel:CreateTexture(nil, "ARTWORK")
    brick:SetSize(64, 64)
    brick:SetPoint("TOP", configPanel, "TOP", -120, -450)
    brick:SetTexture("Interface\\AddOns\\ACT_Friends\\media\\roiben.tga")
    brick:SetTexCoord(0.05, 0.95, 0.05, 0.95)

    local cope = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cope:SetPoint("BOTTOM", brick, "TOP", 0, 12)
    cope:SetText("o7 won MDI in our hearts")

    local o7 = configPanel:CreateTexture(nil, "ARTWORK")
    o7:SetSize(24, 24)
    o7:SetPoint("RIGHT", cope, "LEFT", -6, 0)
    o7:SetTexture("Interface\\AddOns\\ACT_Friends\\media\\o7.tga")

    local info = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    info:SetPoint("TOP", logo, "BOTTOM", 0, -10)
    info:SetText("|cff00ccffAdvance Custom Tools|r\n\n|cffffcc00The #1 way to upset your raiders|r")
    info:SetJustifyH("CENTER")

    self.configPanel = configPanel
    return configPanel
end

if ACT and ACT.RegisterModule then
    ACT:RegisterModule(HomeModule)
end