local _, addon = ...
---@cast addon MyForeverAddon

local controls, statusText

local function Label(parent, text, x, y, template)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

local function Slider(parent, labelText, y, minimum, maximum, step, format)
    local label = Label(parent, labelText, 24, y)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 192, y - 1)
    slider:SetSize(376, 22)
    slider:SetOrientation("HORIZONTAL")
    slider:EnableMouse(true)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("TOPLEFT", slider, "TOPLEFT", 0, -9)
    track:SetPoint("BOTTOMRIGHT", slider, "BOTTOMRIGHT", 0, 9)
    track:SetColorTexture(0.3, 0.3, 0.35, 1)
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:GetThumbTexture():SetSize(32, 32)
    slider:SetScript("OnValueChanged", function(_, value)
        -- These are public option values, never unit health or a secret display.
        label:SetText(labelText .. ": " .. format(value))
    end)
    return slider
end

local function Checkbox(parent, text, x, y)
    -- The art-only template avoids unnecessary named text children.
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonArtTemplate")
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    checkbox:SetSize(28, 28)
    local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    label:SetText(text)
    return checkbox
end

local function Button(parent, text, x, width, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, 14)
    button:SetText(text)
    button:SetSize(width, 24)
    button:SetScript("OnClick", callback)
    return button
end

local function Integer(value)
    return string.format("%.0f", value)
end

local function Percent(value)
    return string.format("%.0f%%", value)
end

local function Draft()
    return {
        width = math.floor(controls.width:GetValue() + 0.5),
        height = math.floor(controls.height:GetValue() + 0.5),
        thresholds = {
            math.floor(controls.notice:GetValue() + 0.5),
            math.floor(controls.warning:GetValue() + 0.5),
            math.floor(controls.critical:GetValue() + 0.5),
        },
        sound = controls.sound:GetChecked(),
        soundFile = controls.soundFile:GetText(),
        flash = controls.flash:GetChecked(),
        announceRaid = controls.announceRaid:GetChecked(),
        announceGuild = controls.announceGuild:GetChecked(),
        flashStrength = controls.flashStrength:GetValue(),
        flashFade = controls.flashFade:GetValue(),
    }
end

local function Apply()
    local saved, errorMessage = addon.ApplyOptions(Draft())
    statusText:SetText(saved and "Settings saved." or errorMessage or "Could not save settings.")
    return saved
end

function addon.RefreshOptions()
    if not controls then return end
    local db = addon.db
    controls.width:SetValue(db.width)
    controls.height:SetValue(db.height)
    controls.notice:SetValue(db.thresholds[1])
    controls.warning:SetValue(db.thresholds[2])
    controls.critical:SetValue(db.thresholds[3])
    controls.sound:SetChecked(db.sound)
    controls.soundFile:SetText(db.soundFile)
    controls.flash:SetChecked(db.flash)
    controls.announceRaid:SetChecked(db.announceRaid)
    controls.announceGuild:SetChecked(db.announceGuild)
    controls.flashStrength:SetValue(db.flashStrength)
    controls.flashFade:SetValue(db.flashFade)
    statusText:SetText(addon.testing and "Demo active: tracking is paused. Click Resume live to finish."
        or "Apply saves changes. Closing discards unapplied edits.")
end

local function CreateOptions()
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    addon.optionsWindow = frame
    frame:Hide()
    frame:SetSize(600, 710)
    -- Keep the controls above the main health bar even when it fills the screen.
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetScript("OnHide", function(self) self:StopMovingOrSizing() end)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.04, 0.04, 0.06, 0.98)

    Label(frame, addon.title .. " - Options", 18, -18, "GameFontNormalLarge")
    Label(frame, "Adjust the controls, then click Apply to save.", 24, -44, "GameFontHighlightSmall")
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
    close:SetScript("OnClick", function() frame:Hide() end)

    controls = {}
    controls.width = Slider(frame, "Width", -76, 360, 4000, 20, Integer)
    controls.height = Slider(frame, "Height", -126, 220, 2000, 10, Integer)
    Label(frame, "Health warning thresholds", 24, -174, "GameFontNormal")
    controls.notice = Slider(frame, "Notice below", -206, 1, 99, 1, Percent)
    controls.warning = Slider(frame, "Warning below", -251, 1, 99, 1, Percent)
    controls.critical = Slider(frame, "Critical below", -296, 1, 99, 1, Percent)
    Label(frame, "Alerts and announcements", 24, -343, "GameFontNormal")
    controls.sound = Checkbox(frame, "Sound warnings", 18, -364)
    controls.flash = Checkbox(frame, "Flashing warnings", 306, -364)
    controls.announceRaid = Checkbox(frame, "Raid announcements", 18, -398)
    controls.announceGuild = Checkbox(frame, "Guild announcements", 306, -398)
    controls.flashStrength = Slider(frame, "Flash brightness", -450, 0, 1, 0.05,
        function(value) return Percent(value * 100) end)
    controls.flashFade = Slider(frame, "Flash fade", -500, 0.3, 2, 0.1,
        function(value) return string.format("%.1fs", value) end)

    Label(frame, "Sound file", 24, -543)
    controls.soundFile = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    controls.soundFile:SetPoint("TOPLEFT", frame, "TOPLEFT", 192, -539)
    controls.soundFile:SetSize(376, 24)
    controls.soundFile:SetAutoFocus(false)
    controls.soundFile:SetMaxLetters(128)
    controls.soundFile:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    controls.soundFile:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local note = Label(frame,
        "File goes in Media. Restart WoW after adding it. Alarm stops above 50% or when HP is hidden.",
        24, -577, "GameFontHighlightSmall")
    note:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -577)
    note:SetHeight(28)
    statusText = Label(frame, "", 24, -617, "GameFontHighlightSmall")
    statusText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -617)
    statusText:SetHeight(42)

    Button(frame, "Apply", 18, 66, Apply)
    Button(frame, "Test alerts", 90, 90, function()
        if Apply() then
            addon.SetDemo(20)
            statusText:SetText("Demo at 20%: tracking and announcements paused. Click Resume live to finish.")
        end
    end)
    Button(frame, "Resume live", 186, 100, function()
        addon.SetDemo(nil)
        statusText:SetText("Live tracking resumed. Apply saves any other edits.")
    end)
    Button(frame, "Play sound", 292, 90, function()
        local _, message = addon.PreviewSound(controls.soundFile:GetText())
        statusText:SetText(message)
    end)
    Button(frame, "Stop sound", 388, 90, function()
        addon.StopAlertSound(true)
        statusText:SetText("Stopped. The alarm rearms after readable HP rises above 50%.")
    end)
    Button(frame, "Center frame", 484, 98, function()
        addon.CenterWindow()
        statusText:SetText("Health frame centered. Apply saves any other edits.")
    end)
    frame:SetScript("OnShow", addon.RefreshOptions)
end

function addon.ToggleOptions()
    if not addon.optionsWindow then CreateOptions() end
    local frame = addon.optionsWindow
    if frame:IsShown() then
        frame:Hide()
    else
        -- Refresh explicitly as well as on OnShow; there are no saved-data writes.
        addon.RefreshOptions()
        frame:Show()
    end
end
