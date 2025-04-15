local UI = {}

-- Template: Button
function UI:CreateButton(parent, text, width, height, onClickCallback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.text:SetPoint("CENTER")
    button.text:SetText(text)
    button:SetScript("OnClick", onClickCallback)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    button:SetBackdropColor(0.1, 0.1, 0.1, 1)
    button:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.2, 0.2, 0.2, 1)
        self:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.1, 0.1, 0.1, 1)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)
    return button
end

-- Template: Read Only Box
function UI:CreateReadOnlyBox(parent, width, height, defaultText)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetSize(width, height)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    box:SetBackdropColor(0.1, 0.1, 0.1, 1)
    box:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 5, -5)
    scroll:SetPoint("BOTTOMRIGHT", -5, 5)
    scroll.ScrollBar:Hide()

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetWidth(width - 10)
    editBox:SetTextInsets(5, 5, 5, 5)
    editBox:SetText(defaultText or "")
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    scroll:SetScrollChild(editBox)

    editBox.storedText = defaultText or ""

    local originalSetText = editBox.SetText
    editBox.SetText = function(self, text)
        self.storedText = text
        originalSetText(self, text)
    end

    editBox:SetScript("OnChar", function(self, char)
        self:SetText(self.storedText)
    end)

    editBox:SetScript("OnTextChanged", function(self)
        if self:GetText() ~= self.storedText then
            self:SetText(self.storedText)
        end
    end)

    return box, editBox
end


-- Template: (Multiline) Edit Box
function UI:CreateMultilineEditBox(parent, width, height, defaultText, onEnterPressed)
    local editBoxFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    editBoxFrame:SetSize(width, height)

    editBoxFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1
    })
    editBoxFrame:SetBackdropColor(0.1, 0.1, 0.1, 1)
    editBoxFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local scrollFrame = CreateFrame("ScrollFrame", nil, editBoxFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", -5, 5) 

    scrollFrame.ScrollBar:Hide()

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetWidth(width - 10) 
    editBox:SetTextInsets(5, 5, 5, 5)
    editBox:SetText(defaultText or "")
    scrollFrame:SetScrollChild(editBox)

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local min, max = self.ScrollBar:GetMinMaxValues()
        local curValue = self.ScrollBar:GetValue()
        if delta > 0 then
            self.ScrollBar:SetValue(math.max(curValue - 20, min))
        else
            self.ScrollBar:SetValue(math.min(curValue + 20, max))
        end
    end)

    editBox:SetScript("OnEditFocusGained", function()
        editBoxFrame:SetBackdropColor(0.2, 0.2, 0.2, 1)
        editBoxFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end)

    editBox:SetScript("OnEditFocusLost", function()
        editBoxFrame:SetBackdropColor(0.1, 0.1, 0.1, 1)
        editBoxFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)

    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if onEnterPressed then
            onEnterPressed(self:GetText())
        end
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    editBoxFrame:EnableMouse(true)
    editBoxFrame:SetScript("OnMouseDown", function()
        editBox:SetFocus()
    end)
    
    scrollFrame:EnableMouse(true)
    scrollFrame:SetScript("OnMouseDown", function()
        editBox:SetFocus()
    end)

    return editBoxFrame, editBox
end

-- Template: Dropdown
local activeDropdown = nil  
function UI:CreateDropdown(parent, width, height)
    local dropdown = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    dropdown:SetSize(width, height)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    dropdown:SetBackdropColor(0.1, 0.1, 0.1, 1)
    dropdown:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    dropdown.button = UI:CreateButton(dropdown, "Select", width, height)
    dropdown.button:SetAllPoints(dropdown)
    dropdown.button.text:SetJustifyH("LEFT")
    dropdown.button.text:SetPoint("LEFT", 5, 0)

    dropdown.button.arrow = dropdown.button:CreateTexture(nil, "OVERLAY")
    dropdown.button.arrow:SetSize(12, 12)
    dropdown.button.arrow:SetPoint("RIGHT", -5, 0)
    dropdown.button.arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
    dropdown.button.arrow:SetTexCoord(0, 1, 0, 1)

    dropdown.list = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    dropdown.list:SetSize(width, 150)
    dropdown.list:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    dropdown.list:SetBackdropColor(0, 0, 0, 0.9)
    dropdown.list:SetBackdropBorderColor(0, 0, 0, 1)
    dropdown.list:SetFrameStrata("HIGH")
    dropdown.list:SetFrameLevel(10)
    dropdown.list:Hide()
    dropdown.list:SetScript("OnShow", function(self)
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    end)

    dropdown.scrollFrame = CreateFrame("ScrollFrame", nil, dropdown.list, "UIPanelScrollFrameTemplate")
    dropdown.scrollFrame:SetPoint("TOPLEFT", 5, -5)
    dropdown.scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)
    
    dropdown.scrollChild = CreateFrame("Frame")
    dropdown.scrollChild:SetSize(width - 20, 150)
    dropdown.scrollFrame:SetScrollChild(dropdown.scrollChild)

    dropdown.button:SetScript("OnClick", function()
        if activeDropdown and activeDropdown ~= dropdown then
            activeDropdown.list:Hide()
        end
        dropdown.list:SetShown(not dropdown.list:IsShown())
        if dropdown.list:IsShown() then activeDropdown = dropdown else activeDropdown = nil end
        if dropdown.list:IsShown() then
            local frame = CreateFrame("Frame")
            frame:SetScript("OnMouseDown", function(_, button)
                if button == "LeftButton" and not MouseIsOver(dropdown.list) and not MouseIsOver(dropdown) then
                    dropdown.list:Hide()
                    activeDropdown = nil
                    frame:SetScript("OnMouseDown", nil)
                end
            end)
        end
    end)
    dropdown:SetScript("OnHide", function()
        dropdown.list:Hide()
        if activeDropdown == dropdown then activeDropdown = nil end
    end)
    return dropdown
end

function UI:AddDropdownOption(dropdown, text, value, onClick)
    local option = CreateFrame("Frame", nil, dropdown.scrollChild, "BackdropTemplate")
    option:SetSize(dropdown:GetWidth() - 10, 20)
    option:SetPoint("TOPLEFT", dropdown.scrollChild, "TOPLEFT", 5, -((#dropdown.scrollChild.buttons or 0) * 20))
    option.text = option:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    option.text:SetText(text)
    option.text:SetJustifyH("LEFT")
    option.text:SetPoint("LEFT", option, "LEFT", 5, 0)
    option:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    option:SetBackdropColor(0, 0, 0, 0)
    option:SetScript("OnEnter", function(self) self:SetBackdropColor(1, 1, 1, 0.2) end)
    option:SetScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)
    option:SetScript("OnMouseUp", function()
        dropdown.button.text:SetText(text)
        dropdown.selectedValue = value
        dropdown.list:Hide()
        if onClick then onClick() end
    end)
    dropdown.scrollChild.buttons = dropdown.scrollChild.buttons or {}
    table.insert(dropdown.scrollChild.buttons, option)
end

function UI:SetDropdownOptions(dropdown, options)
    if dropdown.scrollChild.buttons then
        for _, btn in ipairs(dropdown.scrollChild.buttons) do
            btn:Hide()
            btn:SetParent(nil)
        end
    end
    dropdown.scrollChild.buttons = {}
    for _, opt in pairs(options) do
        UI:AddDropdownOption(dropdown, opt.text, opt.value, opt.onClick)
    end
end

-- Template: Text
function UI:CreateLabel(parent, text, fontSize, color, shadow, outline)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetText(text)
    label:SetFont("Fonts\\FRIZQT__.TTF", fontSize or 12)
    if shadow then
        label:SetShadowColor(0, 0, 0, 1)
        label:SetShadowOffset(1, -1)
    end
    if outline then
        local outlineLabel = parent:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
        outlineLabel:SetText(text)
        outlineLabel:SetFont("Fonts\\FRIZQT__.TTF", fontSize or 12)
        outlineLabel:SetTextColor(0, 0, 0, 1)
        outlineLabel:SetPoint("CENTER", label, "CENTER", 1, -1)
    end
    if color then
        label:SetTextColor(unpack(color))
    end
    return label
end

-- Template: Popup with Multiline Edit Box
function UI:CreatePopupWithEditBox(title, width, height, defaultText, onAccept, onCancel)
    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetSize(width, height)
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    popup:SetFrameStrata("HIGH")
    popup:SetFrameLevel(200)
    popup:SetMovable(true)
    popup:EnableMouse(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", function(self) self:StartMoving() end)
    popup:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    popup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    popup:SetBackdropColor(0.1, 0.1, 0.1, 1)
    popup:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local titleLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleLabel:SetPoint("TOP", popup, "TOP", 0, -10)
    titleLabel:SetText(title)

    local editFrame, editBox = UI:CreateMultilineEditBox(nil, width - 40, height - 100, defaultText)
    editFrame:SetParent(popup)
    editFrame:ClearAllPoints()
    editFrame:SetPoint("TOP", titleLabel, "BOTTOM", 0, -10)

    local acceptButton = UI:CreateButton(popup, "Accept", 80, 25, function()
         if onAccept then onAccept(editBox:GetText()) end
         popup:Hide()
    end)
    acceptButton:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 20, 20)

    local cancelButton = UI:CreateButton(popup, "Cancel", 80, 25, function()
         if onCancel then onCancel() end
         popup:Hide()
    end)
    cancelButton:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -20, 20)

    popup:Hide()
    return popup, editBox
end

-- Template: Text-Only Popup
function UI:CreateTextPopup(title, message, button1Text, button2Text, onAccept, onCancel)
    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetFrameStrata("HIGH")
    popup:SetFrameLevel(200)
    popup:SetMovable(true)
    popup:EnableMouse(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", function(self) self:StartMoving() end)
    popup:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    popup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    popup:SetBackdropColor(0.1, 0.1, 0.1, 1)
    popup:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local titleLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleLabel:SetPoint("TOP", popup, "TOP", 0, -10)
    titleLabel:SetText(title)

    local messageLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    messageLabel:SetPoint("TOP", titleLabel, "BOTTOM", 0, -10)
    messageLabel:SetWidth(280)
    messageLabel:SetWordWrap(true)
    messageLabel:SetText(message)

    local acceptButton = UI:CreateButton(popup, button1Text, 80, 25, function()
         if onAccept then onAccept() end
         popup:Hide()
    end)
    acceptButton:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 20, 20)
    
    local cancelButton = UI:CreateButton(popup, button2Text, 80, 25, function()
         if onCancel then onCancel() end
         popup:Hide()
    end)
    cancelButton:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -20, 20)

    popup:SetScript("OnShow", function(self)
        C_Timer.After(0, function()
            local paddingH = 60
            local newHeight = titleLabel:GetStringHeight() + 10 + messageLabel:GetStringHeight() + 10 + 35 + 20
            self:SetSize(320, newHeight)
            self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end)
    end)
    popup:Hide()
    return popup
end

_G["UI"] = UI