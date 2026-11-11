local _, addon = ...
---@cast addon MyForeverAddon

local title, healthBar, healthText, counterText, flashGate
local commentaryLayers = {}
local colorCurves, flashCurve, percentCurve
local currentUnit, demoPercent
local pulseAnimation
local curveSettings

local function RenderCommentary(unit, demoFraction)
    for _, layer in ipairs(commentaryLayers) do
        if demoFraction ~= nil then
            layer.frame:SetAlpha(layer.curve:Evaluate(demoFraction))
        elseif unit then
            -- Each sentence is constant. Only its display alpha depends on HP;
            -- the addon never selects a sentence by inspecting secret health.
            layer.frame:SetAlpha(UnitHealthPercent(unit, true, layer.curve))
        else
            layer.frame:SetAlpha(0)
        end
    end
end

local function SavePosition()
    local frame = addon.window
    frame:StopMovingOrSizing()
    local x, y = frame:GetCenter()
    local parentX, parentY = UIParent:GetCenter()
    if x and y and parentX and parentY then
        addon.db.windowPosition.x = x - parentX
        addon.db.windowPosition.y = y - parentY
    end
end

local function MakeDisplayCurves()
    local levels = addon.db.thresholds
    local strength = addon.db.flashStrength
    if curveSettings and curveSettings[1] == levels[1] and curveSettings[2] == levels[2]
        and curveSettings[3] == levels[3] and curveSettings[4] == strength then
        return
    end
    curveSettings = { levels[1], levels[2], levels[3], strength }
    -- Curves are built from settings, never from secret health values.
    -- A step begins at each threshold: warnings apply BELOW that percentage.
    local stops = { 0, levels[3] / 100, levels[2] / 100, levels[1] / 100, 1 }
    local colors = {
        { 0.95, 0.10, 0.10 }, { 1, 0.35, 0.05 }, { 1, 0.80, 0.05 },
        { 0.15, 0.80, 0.30 }, { 0.15, 0.80, 0.30 },
    }
    colorCurves = {}
    for component = 1, 3 do
        local curve = C_CurveUtil.CreateCurve()
        curve:SetType(Enum.LuaCurveType.Step)
        for index, stop in ipairs(stops) do
            curve:AddPoint(stop, colors[index][component])
        end
        colorCurves[component] = curve
    end

    flashCurve = C_CurveUtil.CreateCurve()
    flashCurve:SetType(Enum.LuaCurveType.Step)
    flashCurve:AddPoint(0, 0.75 * addon.db.flashStrength)
    flashCurve:AddPoint(levels[3] / 100, 0.45 * addon.db.flashStrength)
    flashCurve:AddPoint(levels[2] / 100, 0.22 * addon.db.flashStrength)
    flashCurve:AddPoint(levels[1] / 100, 0)
    flashCurve:AddPoint(1, 0)

    percentCurve = C_CurveUtil.CreateCurve()
    percentCurve:AddPoint(0, 0)
    percentCurve:AddPoint(1, 100)
end

local function RenderHealth()
    if not addon.window then
        return
    end
    -- The window's visibility is controlled by the user, never by secret HP.
    -- Keep sound monitoring active while avoiding invisible widget updates.
    if not addon.window:IsShown() then
        if demoPercent == nil and addon.db.sound and currentUnit and UnitExists(currentUnit) then
            addon.UpdateAlarm(UnitHealthPercent(currentUnit, true))
        else
            addon.UpdateAlarm(nil)
        end
        return
    end
    if demoPercent ~= nil then
        -- These are local demo numbers, never game health or a fake unit death.
        local fraction = demoPercent / 100
        healthBar:SetValue(fraction)
        healthText:SetFormattedText("%.0f%%", demoPercent)
        healthBar:SetStatusBarColor(colorCurves[1]:Evaluate(fraction),
            colorCurves[2]:Evaluate(fraction), colorCurves[3]:Evaluate(fraction))
        if addon.db.flash then
            flashGate:SetAlpha(flashCurve:Evaluate(fraction))
        else
            flashGate:SetAlpha(0)
        end
        addon.UpdateAlarm(fraction)
        RenderCommentary(nil, fraction)
        return
    end
    if not currentUnit or not UnitExists(currentUnit) then
        healthBar:SetValue(0)
        healthBar:SetStatusBarColor(0.3, 0.3, 0.3)
        healthText:SetText("--")
        flashGate:SetAlpha(0)
        addon.UpdateAlarm(nil)
        RenderCommentary(nil, nil)
        return
    end

    local fraction = UnitHealthPercent(currentUnit, true)
    -- Every potentially secret value flows directly to a supported display API.
    -- Never read the bar back to infer a threshold or a health percentage.
    healthBar:SetValue(fraction)
    healthBar:SetStatusBarColor(UnitHealthPercent(currentUnit, true, colorCurves[1]),
        UnitHealthPercent(currentUnit, true, colorCurves[2]),
        UnitHealthPercent(currentUnit, true, colorCurves[3]))
    healthText:SetFormattedText("%.0f%%", UnitHealthPercent(currentUnit, true, percentCurve))
    if addon.db.flash then
        flashGate:SetAlpha(UnitHealthPercent(currentUnit, true, flashCurve))
    else
        flashGate:SetAlpha(0)
    end
    addon.UpdateAlarm(fraction)
    RenderCommentary(currentUnit, nil)
end

function addon.ApplyWindowSettings()
    if not addon.window then
        return
    end
    addon.window:SetSize(addon.db.width, addon.db.height)
    title:SetText(addon.db.targetName)
    local fontSize = math.max(18, math.min(100, math.floor(addon.db.height * 0.22)))
    healthText:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    local commentarySize = math.max(12, math.min(28, math.floor(addon.db.width / 28)))
    for _, layer in ipairs(commentaryLayers) do
        layer.text:SetFont(STANDARD_TEXT_FONT, commentarySize, "OUTLINE")
    end
    if pulseAnimation then
        pulseAnimation:SetDuration(addon.db.flashFade)
    end
    MakeDisplayCurves()
    RenderHealth()
end

function addon.CenterWindow()
    addon.window:StopMovingOrSizing()
    addon.db.windowPosition.x, addon.db.windowPosition.y = 0, 0
    addon.window:ClearAllPoints()
    addon.window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

function addon.UpdateHealth(unit)
    currentUnit = unit
    RenderHealth()
end

function addon.ShowDeath(_, silent)
    if not silent then
        addon.StopAlertSound()
    end
end

function addon.UpdateCounters()
    if counterText and addon.GetCounters then
        local deaths, whirlwinds, remoteSnapshot = addon.GetCounters()
        local whirlwindText = whirlwinds and (tostring(whirlwinds) .. (remoteSnapshot and "*" or "")) or "–"
        counterText:SetText("Dödsfall: " .. deaths .. "  |  Whirlwind: " .. whirlwindText)
    end
end

function addon.TestWindow(percent)
    demoPercent = percent
    if percent ~= nil then
        addon.window:Show()
    else
        addon.UpdateAlarm(nil)
    end
    RenderHealth()
end

function addon.CreateWindow()
    if addon.window then
        return
    end
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    addon.window = frame
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.04, 0.04, 0.06, 0.95)
    local position = addon.db.windowPosition
    frame:SetPoint("CENTER", UIParent, "CENTER", position.x, position.y)
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", SavePosition)
    frame:SetScript("OnHide", function()
        SavePosition()
        if addon.testing then addon.StopAlertSound() end
    end)
    frame:SetScript("OnShow", RenderHealth)

    title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -18)
    title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -144, -18)
    title:SetJustifyH("LEFT")
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
    closeButton:SetScript("OnClick", function() frame:Hide() end)
    local optionsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    optionsButton:SetText("Options")
    optionsButton:SetSize(88, 24)
    optionsButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -42, -12)
    optionsButton:SetScript("OnClick", function() addon.ToggleOptions() end)

    healthBar = CreateFrame("StatusBar", nil, frame)
    healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -52)
    healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 80)
    healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    healthBar:SetMinMaxValues(0, 1)
    local background = healthBar:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.12, 0.12, 0.14, 1)
    healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    healthText:SetPoint("CENTER", healthBar, "CENTER", 0, 0)

    -- The gate accepts the possibly secret alpha. The child's fixed animation
    -- runs independently; no animation callback inspects health or plays sounds.
    flashGate = CreateFrame("Frame", nil, healthBar)
    flashGate:SetAllPoints()
    flashGate:SetAlpha(0)
    local flashTexture = flashGate:CreateTexture(nil, "OVERLAY")
    flashTexture:SetAllPoints()
    flashTexture:SetColorTexture(1, 0.1, 0.05, 1)
    local animation = flashTexture:CreateAnimationGroup()
    local pulse = animation:CreateAnimation("Alpha")
    pulseAnimation = pulse
    pulse:SetFromAlpha(0.12)
    pulse:SetToAlpha(0.65)
    pulse:SetDuration(addon.db.flashFade)
    animation:SetLooping("BOUNCE")
    animation:Play()

    -- Step points are inclusive. Keep exactly 80% in the middle band.
    local upperBand = 0.8 + 1e-9
    local comments = {
        { "Ser bra ut, kör Whirlwind", upperBand, nil },
        { "Koordinera healingteamet", 0.25, upperBand },
        { "NU JÄVLAR ÄR HAN ILLA UTE!", 0, 0.25 },
    }
    for _, comment in ipairs(comments) do
        local layer = CreateFrame("Frame", nil, frame)
        layer:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -8)
        layer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 34)
        layer:SetAlpha(0)
        local text = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("LEFT", layer, "LEFT", 0, 0)
        text:SetPoint("RIGHT", layer, "RIGHT", 0, 0)
        text:SetText(comment[1])
        local curve = C_CurveUtil.CreateCurve()
        curve:SetType(Enum.LuaCurveType.Step)
        curve:AddPoint(0, comment[2] == 0 and 1 or 0)
        if comment[2] > 0 then curve:AddPoint(comment[2], 1) end
        if comment[3] then curve:AddPoint(comment[3], 0) end
        curve:AddPoint(1, comment[3] and 0 or 1)
        commentaryLayers[#commentaryLayers + 1] = { frame = layer, text = text, curve = curve }
    end
    counterText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    counterText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 14)
    counterText:SetText("Dödsfall: 0  |  Whirlwind: –")
    addon.ApplyWindowSettings()
    frame:Show()
end

function addon.ToggleWindow()
    local frame = addon.window
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end
