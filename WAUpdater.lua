local AceComm = LibStub("AceComm-3.0")
local AceTimer = LibStub("AceTimer-3.0")
local LibDeflate = LibStub("LibDeflate")

local WeakAuraUpdaterModule = {}
WeakAuraUpdaterModule.title = "WeakAura Updater"

function WeakAuraUpdaterModule:GetConfigSize()
    return 800, 600
end

function WeakAuraUpdaterModule:EnsureDB()
    ACT.db.profile.weakauraUpdater = ACT.db.profile.weakauraUpdater or {}
    return ACT.db.profile.weakauraUpdater
end

WeakAuraUpdaterModule.weakAurasLoaded = false

local function OnAddonLoaded(_, _, addon)
    if addon == "WeakAuras" then
        WeakAuraUpdaterModule.weakAurasLoaded = true
    end
end

local addonLoadedFrame = CreateFrame("Frame")
addonLoadedFrame:RegisterEvent("ADDON_LOADED")
addonLoadedFrame:SetScript("OnEvent", OnAddonLoaded)

function WeakAuraUpdaterModule:CheckWeakAurasLoaded()
    if WeakAuras then
        self.weakAurasLoaded = true
    end
end

C_Timer.After(5, function()
    WeakAuraUpdaterModule:CheckWeakAurasLoaded()
end)

local sendTimeoutFrame = nil
function WeakAuraUpdaterModule:DistributeWeakAura(weakAuraData, description)
    local messagePrefix = "WEAKAURA_UPDATE:"
    local originalMsg = messagePrefix .. weakAuraData .. "|DESC:" .. (description or "")
    local compressed = LibDeflate:CompressDeflate(originalMsg, {
        level = 9
    })
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
    local fullMsg = "C" .. encoded .. "##F##"
    local chunkSize = 245
    local totalParts = math.ceil(#fullMsg / chunkSize)

    AceComm:SendCommMessage("ADVANCEWEAKAURA", "START:" .. totalParts, "RAID")

    local currentChunk = 1
    local function sendNextChunk()
        if currentChunk > totalParts then
            self:SetMessage("WeakAura pushed to raid (complete).")
            return
        end

        local chunk = fullMsg:sub((currentChunk - 1) * chunkSize + 1, currentChunk * chunkSize)
        AceComm:SendCommMessage("ADVANCEWEAKAURA", chunk, "RAID")
        self:SetMessage(string.format("Sending WeakAura... %d/%d", currentChunk, totalParts))

        currentChunk = currentChunk + 1
        C_Timer.After(0.1, sendNextChunk)
    end

    sendNextChunk()

    if sendTimeoutFrame then
        sendTimeoutFrame:Cancel()
    end
    sendTimeoutFrame = C_Timer.NewTimer(60, function()
    end)
end

function WeakAuraUpdaterModule:HandleIncomingWeakAura(prefix, msg, distribution, sender)
    if prefix ~= "ADVANCEWEAKAURA" then
        return
    end

    self.chunkBuffers = self.chunkBuffers or {}
    self.receiveStatus = self.receiveStatus or {}

    local actPrefix = "|cff00aaff[ACT]|r "

    if msg:sub(1, 6) == "START:" then
        local total = tonumber(msg:sub(7))
        if total then
            self.receiveStatus[sender] = {
                expected = total,
                received = 0
            }
            self.chunkBuffers[sender] = ""
            DEFAULT_CHAT_FRAME:AddMessage(string.format("%sReceiving from %s: 0/%d chunks", actPrefix, sender, total))
        end
        return
    end

    if not self.receiveStatus[sender] then
        return
    end

    self.chunkBuffers[sender] = self.chunkBuffers[sender] .. msg
    self.receiveStatus[sender].received = self.receiveStatus[sender].received + 1

    DEFAULT_CHAT_FRAME:AddMessage(string.format("%sReceiving from %s: %d/%d chunks", actPrefix, sender,
        self.receiveStatus[sender].received, self.receiveStatus[sender].expected))

    if self.chunkBuffers[sender]:sub(-5) == "##F##" then
        local completeMsg = self.chunkBuffers[sender]:sub(1, -6)
        self.chunkBuffers[sender] = nil
        self.receiveStatus[sender] = nil

        if completeMsg:sub(1, 1) == "C" then
            completeMsg = completeMsg:sub(2)
            local decoded = LibDeflate:DecodeForWoWAddonChannel(completeMsg)
            local decompressed = LibDeflate:DecompressDeflate(decoded)
            completeMsg = decompressed
        end

        local messagePrefix = "WEAKAURA_UPDATE:"
        local descPrefix = "|DESC:"
        local data, description = completeMsg:match("^" .. messagePrefix .. "(.*)" .. descPrefix .. "(.*)$")
        if data then
            local db = self:EnsureDB()
            db.pendingWeakAuraData = data
            self:ShowWeakAuraImportScreen(data, sender, description or "No Description")

            DEFAULT_CHAT_FRAME:AddMessage(string.format("%sReceived WeakAura from %s (complete)", actPrefix, sender))
        end
    end
end

AceComm:RegisterComm("ADVANCEWEAKAURA", function(...)
    WeakAuraUpdaterModule:HandleIncomingWeakAura(...)
end)

function WeakAuraUpdaterModule:ShowWeakAuraImportScreen(data, senderName, description)
    if self.weakAurasLoaded and WeakAuras and WeakAuras.Import then
        WeakAuras.Import(data)
        local db = self:EnsureDB()
        db.pendingWeakAuraData = nil
    else
        local db = self:EnsureDB()
        db.pendingWeakAuraData = data
    end
end

function WeakAuraUpdaterModule:CreateConfigPanel(parent)
    if self.configPanel then
        self.configPanel:SetParent(parent)
        self.configPanel:ClearAllPoints()
        self.configPanel:SetAllPoints(parent)
        self.configPanel:Show()
        return self.configPanel
    end

    local configPanel = CreateFrame("Frame", nil, parent)
    configPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    configPanel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    local importLabel = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    importLabel:SetPoint("TOPLEFT", configPanel, "TOPLEFT", 20, 16)
    importLabel:SetText("WeakAura Updater")

    local importBoxFrame, importBoxEdit = UI:CreateMultilineEditBox(configPanel, 520, 200, "")
    importBoxFrame:SetPoint("TOPLEFT", importLabel, "BOTTOMLEFT", 0, -10)
    self.importBoxFrame = importBoxFrame
    self.importBoxEdit = importBoxEdit

    local sendButton = UI:CreateButton(configPanel, "Send", 120, 30)
    sendButton:SetPoint("TOPLEFT", importBoxFrame, "BOTTOMLEFT", 0, -10)
    sendButton:SetScript("OnClick", function()
        local text = importBoxEdit:GetText()
        local description = ""
        local cleaned = tostring(text):match("^%s*(.-)%s*$")
        if not cleaned or string.sub(cleaned, 1, 6) ~= "!WA:2!" then
            importBoxEdit:SetText("")
            self:SetMessage("Please paste a valid WeakAura string (must begin with !WA:2!)")
            return
        end
        if text and text:trim() ~= "" then
            if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
                self:DistributeWeakAura(text, description)
                importBoxEdit:SetText("")
                self:SetMessage("WeakAura pushed to the raid.")
            else
                importBoxEdit:SetText("")
                self:SetMessage("You must be raid leader or assist to use this feature.")
            end
        else
            importBoxEdit:SetText("")
            self:SetMessage("Please paste a valid WeakAura string.")
        end
    end)

    local clearButton = UI:CreateButton(configPanel, "Clear", 120, 30)
    clearButton:SetPoint("LEFT", sendButton, "RIGHT", 10, 0)
    clearButton:SetScript("OnClick", function()
        local db = self:EnsureDB()
        db.pendingWeakAuraData = nil
        importBoxEdit:SetText("")
        self:SetMessage("")
    end)

    local messageLabel = configPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    messageLabel:SetPoint("TOPLEFT", sendButton, "BOTTOMLEFT", 0, -10)
    messageLabel:SetWidth(540)
    messageLabel:SetHeight(30)
    messageLabel:SetJustifyH("LEFT")
    self.messageLabel = messageLabel

    self.configPanel = configPanel
    return self.configPanel
end

function WeakAuraUpdaterModule:SetMessage(msg)
    if self.messageLabel then
        self.messageLabel:SetText(msg or "")
    end
end

if ACT and ACT.RegisterModule then
    ACT:RegisterModule(WeakAuraUpdaterModule)
end

return WeakAuraUpdaterModule
