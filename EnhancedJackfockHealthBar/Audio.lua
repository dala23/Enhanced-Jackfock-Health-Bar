local _, addon = ...
---@cast addon MyForeverAddon

local alarmHandle, previewHandle
local alarmWanted, mutedUntilRecovery, started = false, false, false
local nextAttempt, elapsed = 0, 0

function addon.NormalizeSoundFile(value)
    if type(value) ~= "string" then return nil, "Choose a sound filename or leave it empty for the built-in sound." end
    if value:find("[%c]") then return nil, "The sound filename cannot contain control characters." end
    local filename = value:match("^%s*(.-)%s*$")
    if filename == "" then return "" end
    if #filename > 128 or not filename:match("^[A-Za-z0-9 _%.%-]+$")
        or filename:find("..", 1, true) then
        return nil, "Use only a filename in Media, without folders or .. ."
    end
    local extension = filename:lower():match("%.([a-z0-9]+)$")
    if (extension ~= "ogg" and extension ~= "mp3") or #filename <= #extension + 1 then
        return nil, "Use an .ogg or .mp3 sound file."
    end
    return filename
end

local function ValidHandle(value)
    return not issecretvalue(value) and type(value) == "number" and value == value
        and value >= 0 and value < math.huge
end

local function StopAlarm()
    alarmWanted = false
    local handle = alarmHandle
    alarmHandle = nil
    if handle then StopSound(handle, 0) end
end

function addon.StopAlertSound(suppressUntilRecovery)
    StopAlarm()
    local handle = previewHandle
    previewHandle = nil
    if handle then StopSound(handle, 0) end
    mutedUntilRecovery = suppressUntilRecovery == true
    nextAttempt = 0
end

local function Play(filename)
    local normalized, errorMessage = addon.NormalizeSoundFile(filename)
    if not normalized then return nil, errorMessage end
    local success, handle
    if normalized == "" then
        success, handle = C_Sound.PlaySoundWithOptions({ soundKitID = SOUNDKIT.RAID_WARNING })
    else
        local path = "Interface\\AddOns\\" .. addon.name .. "\\Media\\" .. normalized
        -- PlaySoundFile exposes no verified completion-callback argument.
        -- Its Master channel still respects the player's master audio settings.
        success, handle = PlaySoundFile(path, "Master")
    end
    if issecretvalue(success) or success ~= true or not ValidHandle(handle) then
        if ValidHandle(handle) then StopSound(handle, 0) end
        return nil, "Sound request failed. Check the filename and audio settings; restart WoW after adding a new file."
    end
    return handle, "Sound requested. Hearing it depends on the file and your game audio settings."
end

local function IsPlaying(handle)
    local playing = C_Sound.IsPlaying(handle)
    if issecretvalue(playing) then return nil end
    return playing
end

local function TryStartAlarm()
    -- Health events can arrive in bursts. Playback inspection belongs in the
    -- bounded audio poll, not on every health update while a preview is active.
    if not alarmWanted or alarmHandle or previewHandle or GetTime() < nextAttempt then return end
    local handle = Play(addon.db.soundFile)
    if handle then alarmHandle = handle else nextAttempt = GetTime() + 5 end
end

function addon.UpdateAlarm(fraction)
    -- Never compare secret HP, inspect a display alpha, or infer health from UI.
    if issecretvalue(fraction) or type(fraction) ~= "number" or fraction ~= fraction
        or fraction < 0 or fraction > 1 then
        StopAlarm()
        return
    end
    if fraction == 0 or fraction > 0.5 then
        StopAlarm()
        mutedUntilRecovery = false
        nextAttempt = 0
        return
    end
    if not addon.db.sound or mutedUntilRecovery then StopAlarm(); return end
    alarmWanted = true
    TryStartAlarm()
end

function addon.PreviewSound(filenameOverride)
    local filename = filenameOverride == nil and addon.db.soundFile or filenameOverride
    -- Keep a manual one-shot separate: healthy or secret HP must not cut off
    -- an explicit preview. A preview also must not overlap an automatic alarm.
    StopAlarm()
    local previous = previewHandle
    previewHandle = nil
    if previous then StopSound(previous, 0) end
    local handle, message = Play(filename)
    previewHandle = handle
    return handle ~= nil, message
end

function addon.StartAudio()
    if started then return end
    started = true
    local frame = CreateFrame("Frame")
    -- Release native handles before the UI environment is replaced on reload.
    -- PLAYER_LOGOUT is documented in Forever's SystemDocumentation.lua.
    frame:RegisterEvent("PLAYER_LOGOUT")
    frame:SetScript("OnEvent", function() addon.StopAlertSound() end)
    frame:SetScript("OnUpdate", function(_, delta)
        if not alarmWanted and not previewHandle then return end
        elapsed = elapsed + delta
        if elapsed < 0.2 then return end
        elapsed = 0
        if previewHandle then
            local playing = IsPlaying(previewHandle)
            if playing == nil then StopAlarm(); return end
            if playing then return end
            previewHandle = nil
        end
        if not alarmWanted then return end
        if alarmHandle then
            local playing = IsPlaying(alarmHandle)
            if playing == nil then StopAlarm(); return end
            if playing then return end
            alarmHandle = nil
        end
        -- Repeat only after native playback reports completion. There is no
        -- guessed clip length or timer-based sound overlap.
        TryStartAlarm()
    end)
end
