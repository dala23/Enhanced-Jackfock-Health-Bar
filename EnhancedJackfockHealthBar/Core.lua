local _, addon = ...
---@cast addon MyForeverAddon

---@param value any
---@return boolean
local function IsFiniteNumber(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

local function InitializeSavedVariables()
    -- The client restores this global after the TOC files, before ADDON_LOADED.
    -- Never assign defaults at file scope: that could overwrite saved data.
    if type(MyForeverAddonDB) ~= "table" then
        MyForeverAddonDB = {}
    end

    local position = MyForeverAddonDB.windowPosition
    if type(position) ~= "table" then
        position = {}
        MyForeverAddonDB.windowPosition = position
    end
    if not IsFiniteNumber(position.x) then
        position.x = 0
    end
    if not IsFiniteNumber(position.y) then
        position.y = 0
    end

    addon.db = MyForeverAddonDB

    local db = addon.db
    if type(db.targetName) ~= "string" or not db.targetName:find("%S") or #db.targetName > 100 then
        db.targetName = "Dr Enkel"
    end
    if not IsFiniteNumber(db.width) or db.width < 360 or db.width > 4000 then
        db.width = 420
    end
    if not IsFiniteNumber(db.height) or db.height < 220 or db.height > 2000 then
        db.height = 290
    end
    if not IsFiniteNumber(db.flashStrength) or db.flashStrength < 0 or db.flashStrength > 1 then
        db.flashStrength = 1
    end
    if not IsFiniteNumber(db.flashFade) or db.flashFade < 0.3 or db.flashFade > 2 then
        db.flashFade = 0.7
    end
    local thresholds = db.thresholds
    if type(thresholds) ~= "table" or not IsFiniteNumber(thresholds[1])
        or not IsFiniteNumber(thresholds[2]) or not IsFiniteNumber(thresholds[3])
        or thresholds[1] >= 100 or thresholds[3] <= 0
        or thresholds[1] <= thresholds[2] or thresholds[2] <= thresholds[3] then
        db.thresholds = { 50, 30, 15 }
    end
    for _, setting in ipairs({ "sound", "flash", "announceRaid", "announceGuild" }) do
        if type(db[setting]) ~= "boolean" then
            db[setting] = true
        end
    end
    db.soundFile = addon.NormalizeSoundFile(db.soundFile) or "alarm.mp3"
end

-- Validate the whole draft before saving anything, so an invalid threshold
-- cannot leave half of an options form applied. Missing fields keep their value.
function addon.ApplyOptions(settings)
    if type(settings) ~= "table" then
        return false, "Options must be a table."
    end
    local values = {}
    for _, key in ipairs({ "width", "height", "flashStrength", "flashFade", "thresholds",
        "sound", "soundFile", "flash", "announceRaid", "announceGuild" }) do
        if settings[key] == nil then
            values[key] = addon.db[key]
        else
            values[key] = settings[key]
        end
    end
    if not IsFiniteNumber(values.width) or values.width < 360 or values.width > 4000
        or not IsFiniteNumber(values.height) or values.height < 220 or values.height > 2000 then
        return false, "Width must be 360-4000 and height 220-2000."
    end
    if not IsFiniteNumber(values.flashStrength) or values.flashStrength < 0 or values.flashStrength > 1
        or not IsFiniteNumber(values.flashFade) or values.flashFade < 0.3 or values.flashFade > 2 then
        return false, "Flash brightness must be 0-100% and fade time 0.3-2 seconds."
    end
    local levels = values.thresholds
    if type(levels) ~= "table" or not IsFiniteNumber(levels[1]) or not IsFiniteNumber(levels[2])
        or not IsFiniteNumber(levels[3]) or levels[1] >= 100 or levels[3] <= 0
        or levels[1] <= levels[2] or levels[2] <= levels[3] then
        return false, "Warning thresholds must go from high to low, between 1 and 99%."
    end
    for _, key in ipairs({ "sound", "flash", "announceRaid", "announceGuild" }) do
        if type(values[key]) ~= "boolean" then
            return false, "Sound, flashing and announcement switches must be on or off."
        end
    end
    local soundFile, soundError = addon.NormalizeSoundFile(values.soundFile)
    if not soundFile then return false, soundError end
    values.soundFile = soundFile
    values.thresholds = { levels[1], levels[2], levels[3] }
    if values.soundFile ~= addon.db.soundFile or values.sound ~= addon.db.sound then
        addon.StopAlertSound()
    end
    for key, value in pairs(values) do
        addon.db[key] = value
    end
    addon.ApplyWindowSettings()
    addon.RefreshOptions()
    return true
end

local function Help()
    addon.Print("/myforeveraddon toggles the window. Commands:")
    addon.Print("size 1400 500 | thresholds 50 30 15 | sound on/off | flash on/off")
    addon.Print("name Dr Enkel | watch (your current target) | raid on/off | guild on/off")
    addon.Print("options (clickable controls) | test 20 (local demo, no announcements) | live | status | help")
end

---@param percent? number Nil resumes live tracking; a number starts a local demo.
function addon.SetDemo(percent)
    addon.StopAlertSound()
    addon.testing = percent ~= nil
    addon.ResetTracking()
    addon.TestWindow(percent)
    if percent ~= nil then
        addon.window:Show()
    end
end

local function SlashCommand(message)
    local command, argument = message:match("^%s*(%S*)%s*(.-)%s*$")
    command = command:lower()
    if command == "" then
        addon.ToggleWindow()
    elseif command == "help" then
        Help()
    elseif command == "options" or command == "settings" then
        addon.ToggleOptions()
    elseif command == "size" then
        local width, height = argument:match("^(%d+)%s+(%d+)$")
        width, height = tonumber(width), tonumber(height)
        if not width or not height or width < 360 or width > 4000 or height < 220 or height > 2000 then
            addon.Print("Use size WIDTH HEIGHT: width 360-4000, height 220-2000.")
            return
        end
        addon.ApplyOptions({ width = width, height = height })
    elseif command == "thresholds" then
        local high, middle, low = argument:match("^(%d+)%s+(%d+)%s+(%d+)$")
        high, middle, low = tonumber(high), tonumber(middle), tonumber(low)
        if not high or not middle or not low or high >= 100 or low <= 0 or high <= middle or middle <= low then
            addon.Print("Use three descending percentages between 1 and 99, e.g. thresholds 50 30 15.")
            return
        end
        addon.ApplyOptions({ thresholds = { high, middle, low } })
    elseif command == "sound" or command == "flash" or command == "raid" or command == "guild" then
        argument = argument:lower()
        if argument ~= "on" and argument ~= "off" then
            addon.Print("Use " .. command .. " on or " .. command .. " off.")
            return
        end
        local key = ({ raid = "announceRaid", guild = "announceGuild" })[command] or command
        addon.ApplyOptions({ [key] = argument == "on" })
        addon.Print(command .. " " .. argument)
    elseif command == "name" or command == "watch" then
        local name = argument
        if command == "watch" then
            name = addon.GetUnitDisplayName("target")
        end
        if type(name) ~= "string" or not name:find("%S") or #name > 100 then
            addon.Print("Target the player and use watch, or use name Dr Enkel.")
            return
        end
        addon.db.targetName = name
        addon.SetDemo(nil)
        addon.ApplyWindowSettings()
        addon.Print("Watching " .. name .. " when they are in your party or raid.")
    elseif command == "test" then
        local percent = argument == "" and 20 or tonumber(argument)
        if not percent or not IsFiniteNumber(percent) or percent < 0 or percent > 100 then
            addon.Print("Use test PERCENT, from 0 to 100.")
            return
        end
        addon.SetDemo(percent)
        addon.Print("Local demo. Tracking and announcements paused; use live to resume.")
    elseif command == "live" then
        addon.SetDemo(nil)
        addon.Print("Live raid tracking resumed.")
    elseif command == "status" then
        addon.Print("Watching " .. addon.db.targetName .. (addon.testing and " (local demo)." or " (live)."))
        addon.Print("Threshold sounds need readable health. Secret health still supports bar color and flashing.")
        addon.Print("Your client cannot read his swing count, ready defensives or potion inventory.")
    else
        Help()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, loadedAddonName)
    if event ~= "ADDON_LOADED" or loadedAddonName ~= addon.name then
        return
    end

    self:UnregisterEvent("ADDON_LOADED")
    InitializeSavedVariables()
    addon.StartAudio()
    addon.CreateWindow()
    addon.StartCounters()
    addon.UpdateCounters()
    addon.StartTracking()

    -- These global registrations are required by WoW's slash-command API.
    SLASH_MYFOREVERADDON1 = "/myforeveraddon"
    SlashCmdList.MYFOREVERADDON = SlashCommand
end)
