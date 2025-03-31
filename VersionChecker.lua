local VersionCheckerModule = {}

VersionCheckerModule.title = "Version Checker"

local AceComm = LibStub("AceComm-3.0")

function VersionCheckerModule:GetConfigSize()
    return 800, 600
end

_G.VACT = _G.VACT or {}
local VACT = _G.VACT 

local versionCheckTimer = nil 
local version = C_AddOns.GetAddOnMetadata("ACT", "Version")

local function OnAddonLoaded(addonName)
    if addonName == "ACT" then
        VACT.VersionCheck = VACT.VersionCheck or {}
        VACT.VersionCheck.responses = {}

        ART_VersionCheckDB = ART_VersionCheckDB or {}
        ART_VersionCheckDB.version = version

        VACT.VersionCheck.version = ART_VersionCheckDB.version
    end
end

local function compareVersions(v1, v2)
    local v1Parts = {strsplit(".", v1)}
    local v2Parts = {strsplit(".", v2)}
    for i = 1, math.max(#v1Parts, #v2Parts) do
        local v1Part = tonumber(v1Parts[i]) or 0
        local v2Part = tonumber(v2Parts[i]) or 0
        if v1Part > v2Part then
            return 1
        elseif v1Part < v2Part then
            return -1
        end
    end
    return 0
end

local function formatVersion(ver)
    ver = tostring(ver)
    if ver:find("%.") then
        return ver
    elseif #ver == 2 then
        return ver:sub(1,1) .. "." .. ver:sub(2,2)
    else
        return ver 
    end
end

function VersionCheckerModule:SendVersionCheck()
    if not VACT.VersionCheck.version then
        return
    end

    VACT.VersionCheck.responses = {}
    local message = "VERSION_CHECK:" .. VACT.VersionCheck.version

    local channel = IsInRaid() and "RAID" or "PARTY"
    AceComm:SendCommMessage("ADVANCEVERSION", message, channel)

    versionCheckTimer = C_Timer.NewTimer(5, function() VersionCheckerModule:CheckForNonResponders() end)
end

function VersionCheckerModule:SendVersionResponse(target, senderVersion)
    if not VACT.VersionCheck.version then
        return
    end

    local message = "VERSION_RESPONSE:" .. VACT.VersionCheck.version
    AceComm:SendCommMessage("ADVANCEVERSION", message, "WHISPER", target)
end

function VersionCheckerModule:OnCommReceived(prefix, message, distribution, sender)
    if prefix == "ADVANCEVERSION" then
        local command, ver = strsplit(":", message)
        local playerName = Ambiguate(sender, "mail")  
        if command == "VERSION_CHECK" then
            VACT.VersionCheck.responses[playerName] = ver
            VersionCheckerModule:SendVersionResponse(playerName, ver) 
        elseif command == "VERSION_RESPONSE" then
            VACT.VersionCheck.responses[playerName] = ver
            VersionCheckerModule:ShowResults()
        end
    end
end

function VersionCheckerModule:CheckForNonResponders()
    local groupType = IsInRaid() and "RAID" or "PARTY"
    local numGroupMembers = GetNumGroupMembers()

    for i = 1, numGroupMembers do
        local unit = groupType .. i
        local playerName = GetUnitName(unit, true)
        if playerName then
            playerName = Ambiguate(playerName, "mail") 
            if not VACT.VersionCheck.responses[playerName] then
                VACT.VersionCheck.responses[playerName] = "Addon not installed"
            end
        end
    end

    VersionCheckerModule:ShowResults()
end

function VersionCheckerModule:ShowResults()
    local highestVersion = VACT.VersionCheck.version
    for _, ver in pairs(VACT.VersionCheck.responses) do
        if compareVersions(ver, highestVersion) > 0 then
            highestVersion = ver
        end
    end

    local result = ""
    for player, ver in pairs(VACT.VersionCheck.responses) do
        local color
        if ver == "Addon not installed" then
            color = "|cff808080" 
        else
            color = compareVersions(ver, highestVersion) == 0 and "|cff00ff00" or "|cffff0000"
            ver = formatVersion(ver)
        end        
        local displayName = Ambiguate(player, "short") 
        result = result .. color .. displayName .. ": " .. ver .. "|r\n"
    end
    if self.configPanel and self.configPanel.resultFrame and self.configPanel.resultFrame.text then
        self.configPanel.resultFrame.text:SetText(result)
    end
end

AceComm:RegisterComm("ADVANCEVERSION", function(...) VersionCheckerModule:OnCommReceived(...) end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(...)
    end
end)

function VersionCheckerModule:CheckVersions()
    VersionCheckerModule:SendVersionCheck()
end

function VersionCheckerModule:CreateConfigPanel(parent)
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
    title:SetText("Version Checker")

    local checkVersionsButton = UI:CreateButton(configPanel, "Check Versions", 120, 30, function()
        VersionCheckerModule:CheckVersions()
    end)
    
    checkVersionsButton:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)

    local resultFrame, resultText = UI:CreateReadOnlyBox(configPanel, 520, 450, "")
    resultFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -50)

    resultFrame:SetScript("OnShow", function()
        VACT.VersionCheck.responses = {}
        resultText:SetText("") 
    end)

    resultFrame:SetScript("OnHide", function()
        if versionCheckTimer then
            versionCheckTimer:Cancel()
            versionCheckTimer = nil
        end
    end)

    self.configPanel = configPanel
    self.configPanel.resultFrame = resultFrame
    self.configPanel.resultFrame.text = resultText
    return configPanel
end

if ACT and ACT.RegisterModule then
    ACT:RegisterModule(VersionCheckerModule)
end