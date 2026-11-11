local _, addon = ...
---@cast addon MyForeverAddon

-- Forever has readable death/combat flags, but health and native meter data
-- can be secret. Never branch on a secret value or register combat-log events.
local unit, unitName, unitGUID
local wasDead, wasInCombat, combatStarted, partialCombat
local rosterDirty = true
local knownRecaps, baselineReady = {}, false
local reports = {}
local elapsedPoll, elapsedReports = 0, 0
local nextRosterScan, nextBaselineRefresh = 0, 0
local started, lastTesting = false, false
-- Raid encounters can remain locked down for several minutes after an early death.
local MAX_REPORTS, REPORT_LIFETIME = 5, 600
local quips = { "Floor inspector: shift complete.", "Tank spec: horizontal.", "Gravity wins again." }
local nextQuip = 0

local function Accessible(value)
    return not issecretvalue(value)
end

local function NormalizeName(value)
    return value:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " "):lower()
end

function addon.GetUnitDisplayName(token)
    local first, surname = UnitName(token)
    if not Accessible(first) or not Accessible(surname)
        or type(first) ~= "string" or first == "" then
        return nil
    end

    -- Camelot uses a surname, not Retail's Name-Realm convention. Some
    -- Forever paths already put the full name in the first return value.
    local separator = Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR
    if type(surname) == "string" and surname ~= ""
        and not first:find(separator, 1, true) then
        return first .. separator .. surname
    end
    return first
end

local function ReadGUID(token)
    local guid = UnitGUID(token)
    if Accessible(guid) and type(guid) == "string" then
        return guid
    end
end

local function MatchesName(name)
    return name and NormalizeName(name) == NormalizeName(addon.db.targetName)
end

local function FindUnit()
    local grouped = IsInGroup()
    if not Accessible(grouped) or not grouped then
        return nil
    end
    local raid = IsInRaid()
    if not Accessible(raid) then
        return nil
    end
    local function Matches(token)
        local exists, player = UnitExists(token), UnitIsPlayer(token)
        if not Accessible(exists) or not Accessible(player) or not exists or not player then
            return false
        end
        return MatchesName(addon.GetUnitDisplayName(token))
    end
    if raid then
        for index = 1, 40 do
            local token = "raid" .. index
            if Matches(token) then return token end
        end
    else
        for index = 1, 4 do
            local token = "party" .. index
            if Matches(token) then return token end
        end
        if Matches("player") then return "player" end
    end
end

local function RestrictionsClear()
    local combat = InCombatLockdown()
    local chat = C_ChatInfo.InChatMessagingLockdown()
    return Accessible(combat) and Accessible(chat) and not combat and not chat
end

local function ReadDeathRecords()
    if not RestrictionsClear() or not C_DamageMeter or not C_DeathRecap then
        return nil
    end
    local available = C_DamageMeter.IsDamageMeterAvailable()
    if not Accessible(available) or not available then return nil end

    local session = C_DamageMeter.GetCombatSessionFromType(
        Enum.DamageMeterSessionType.Current, Enum.DamageMeterType.Deaths)
    if not Accessible(session) or type(session) ~= "table" then return nil end
    local sources = session.combatSources
    if not Accessible(sources) or type(sources) ~= "table" then return nil end
    local result = {}
    for _, source in ipairs(sources) do
        if Accessible(source) and type(source) == "table" then
            local name, guid = source.name, source.sourceGUID
            local id, deathTime = source.deathRecapID, source.deathTimeSeconds
            if Accessible(name) and Accessible(guid) and Accessible(id)
                and Accessible(deathTime) and type(id) == "number" and id > 0
                and ((unitGUID and guid == unitGUID)
                    or (not unitGUID and type(name) == "string" and MatchesName(name))) then
                result[#result + 1] = { id = id, deathTime = deathTime }
            end
        end
    end
    return result
end

local function BaselineRecaps(force)
    local now = GetTime()
    if not force and now < nextBaselineRefresh then return end
    nextBaselineRefresh = now + 1
    local records = ReadDeathRecords()
    if records then
        for _, record in ipairs(records) do knownRecaps[record.id] = true end
        baselineReady = true
    end
end

local function CleanText(text)
    return text:gsub("|", ""):gsub("[%c]", " ")
end

local function ReadCause(recapID)
    local events = C_DeathRecap.GetRecapEvents(recapID)
    if not Accessible(events) or type(events) ~= "table" then return nil end
    local hit = events[1]
    if not Accessible(hit) or type(hit) ~= "table" then return nil end
    -- Blizzard's DeathRecap UI marks entry 1 as the killing blow, not the
    -- largest hit. hideCaster must also be respected when reporting it.
    local event, spell, environment = hit.event, hit.spellName, hit.environmentalType
    local caster, hideCaster = hit.sourceName, hit.hideCaster
    if not Accessible(event) or not Accessible(spell) or not Accessible(environment)
        or not Accessible(caster) or not Accessible(hideCaster) then return nil end
    local cause
    if event == "ENVIRONMENTAL_DAMAGE" and type(environment) == "string" then
        cause = environment:lower()
    elseif event == "SWING_DAMAGE" then
        cause = "a melee hit"
    elseif type(spell) == "string" and spell ~= "" then
        cause = spell
    end
    if not cause then return nil end
    if not hideCaster and type(caster) == "string" and caster ~= "" then
        cause = cause .. " (" .. caster .. ")"
    end
    return CleanText(cause)
end

local function ResolveCause(report)
    if not report.baselineReady or not report.sessionClock then return nil end
    local records = ReadDeathRecords()
    if not records then return nil end
    local candidate
    for _, record in ipairs(records) do
        if not report.baselineIDs[record.id] and not knownRecaps[record.id] then
            if candidate then return nil end -- multiple deaths cannot be paired safely
            candidate = record
        end
    end
    if not candidate then return nil end
    -- The native session clock is distinct from his individual observed combat
    -- time. A recap must agree with the clock sampled at death, not just be new.
    if type(candidate.deathTime) ~= "number" or candidate.deathTime ~= candidate.deathTime
        or candidate.deathTime < 0
        or math.abs(candidate.deathTime - report.sessionClock) > 1 then return nil end
    -- If observation was lost or another death is queued, prefer unknown over
    -- associating an old killing blow with this death.
    if #reports ~= 1 or not unitName or NormalizeName(unitName) ~= NormalizeName(report.name)
        or (report.guid and unitGUID ~= report.guid) then return nil end
    local cause = ReadCause(candidate.id)
    if cause then knownRecaps[candidate.id] = true end
    return cause
end

local function LimitText(text, limit)
    -- Keep UTF-8 names intact when reserving the 255-byte chat budget.
    local index, last = 1, 0
    while index <= #text do
        local byte = text:byte(index)
        local width = byte < 128 and 1 or byte < 224 and 2 or byte < 240 and 3 or 4
        if index + width - 1 > limit then break end
        last = index + width - 1
        index = index + width
    end
    return text:sub(1, last)
end

local function DeathMessage(report, cause)
    local duration = report.duration and string.format("%.1fs%s observed combat",
        report.duration, report.partial and "+" or "") or "combat time unavailable"
    return string.format(
        "[Enhanced Jackfock Health Bar] %s died to %s; %s. %s Swings/defensives/potions: unavailable.",
        LimitText(CleanText(report.name), 40), LimitText(cause or "an unavailable cause", 60),
        LimitText(duration, 32), report.quip)
end

local function InvalidateCauseBaseline()
    baselineReady = false
    nextBaselineRefresh = 0
    for _, queued in ipairs(reports) do queued.baselineReady = false end
end

local function FlushReports()
    if addon.testing or not RestrictionsClear() then return end
    local now = GetTime()
    while reports[1] do
        local report = reports[1]
        if now - report.time > REPORT_LIFETIME then
            InvalidateCauseBaseline()
            table.remove(reports, 1)
            addon.ShowDeath(DeathMessage(report, nil) .. " Report expired; no chat sent.", true)
        else
            report.safeSince = report.safeSince or now
            local cause = ResolveCause(report)
            if not cause and now - report.safeSince < 3 then return end
            local message = DeathMessage(report, cause)
            addon.ShowDeath(message, true)
            -- Queue handling is the supported route: no protected-call retry
            -- loop, secure snippet, macro, or attempt to bypass restrictions.
            local raid, guild = IsInRaid(), IsInGuild()
            local sameMember = unitName and NormalizeName(unitName) == NormalizeName(report.name)
                and (not report.guid or unitGUID == report.guid)
            if addon.db.announceRaid and Accessible(raid) and raid and sameMember then
                C_ChatInfo.SendChatMessage(message, "RAID")
            end
            if addon.db.announceGuild and Accessible(guild) and guild then
                C_ChatInfo.SendChatMessage(message, "GUILD")
            end
            if not cause then
                -- A late recap from this unresolved death must never be
                -- mistaken for the next death. Rebaseline before resolving more.
                InvalidateCauseBaseline()
            end
            table.remove(reports, 1)
            return -- at most one death report per second
        end
    end
end

local function ObserveDeath(now)
    addon.RecordDeath()
    nextQuip = nextQuip % #quips + 1
    local baselineIDs = {}
    for id in pairs(knownRecaps) do baselineIDs[id] = true end
    local sessionClock
    if C_DamageMeter and C_DamageMeter.GetSessionDurationSeconds then
        -- This clock getter has no SecretWhenInCombat annotation in Forever.
        -- Still reject a restricted or unavailable return rather than inferring it.
        local value = C_DamageMeter.GetSessionDurationSeconds(Enum.DamageMeterSessionType.Current)
        if Accessible(value) and type(value) == "number" and value >= 0 and value < math.huge then
            sessionClock = value
        end
    end
    local report = {
        name = unitName, guid = unitGUID, time = now,
        duration = combatStarted and math.max(0, now - combatStarted) or nil,
        partial = partialCombat, baselineReady = baselineReady, baselineIDs = baselineIDs,
        sessionClock = sessionClock, quip = quips[nextQuip],
    }
    if #reports == MAX_REPORTS then
        InvalidateCauseBaseline()
        report.baselineReady = false
        table.remove(reports, 1)
    end
    reports[#reports + 1] = report
    addon.ShowDeath(DeathMessage(report, nil) .. " Awaiting native recap / chat restrictions.")
end

local function ForgetUnit()
    unit, unitName, unitGUID = nil, nil, nil
    wasDead, wasInCombat, combatStarted, partialCombat = nil, nil, nil, nil
    knownRecaps, baselineReady = {}, false
    nextRosterScan, nextBaselineRefresh = 0, 0
end

local function Poll()
    if addon.testing then return end
    local now = GetTime()
    -- Missing members do not need a full roster scan at health-update speed.
    -- Roster/name/world events still bypass this cooldown on the next poll.
    if rosterDirty or (not unit and now >= nextRosterScan) then
        local found = FindUnit()
        local name = found and addon.GetUnitDisplayName(found)
        local guid = found and ReadGUID(found)
        local same = found and unitName and name and NormalizeName(name) == NormalizeName(unitName)
            and (not unitGUID or not guid or guid == unitGUID)
        if not same then ForgetUnit() end
        unit, unitName = found, name
        if guid then unitGUID = guid end
        nextRosterScan = now + 1
        rosterDirty = false
    end
    if not unit then
        addon.UpdateHealth(nil)
        return
    end

    local exists, connected = UnitExists(unit), UnitIsConnected(unit)
    if not Accessible(exists) or not Accessible(connected) or not exists or not connected then
        ForgetUnit()
        addon.UpdateHealth(nil)
        return
    end
    local dead, combat = UnitIsDeadOrGhost(unit), UnitAffectingCombat(unit)
    if not Accessible(dead) or not Accessible(combat) then
        addon.UpdateHealth(unit)
        return
    end
    if wasDead == nil then
        -- Finding an already dead player never creates a new death report.
        wasDead, wasInCombat = dead, combat and not dead
        if combat and not dead then combatStarted, partialCombat = now, true end
        if not dead then BaselineRecaps(true) end
    else
        if dead and not wasDead then ObserveDeath(now) end
        if dead then
            combatStarted, partialCombat = nil, nil
        elseif combat and not wasInCombat then
            combatStarted, partialCombat = now, false
        elseif not combat then
            combatStarted, partialCombat = nil, nil
            if #reports == 0 then BaselineRecaps() end
        end
        wasDead, wasInCombat = dead, combat and not dead
    end
    addon.UpdateHealth(unit)
end

function addon.ResetTracking()
    ForgetUnit()
    reports = {}
    rosterDirty = true
    elapsedPoll, elapsedReports = 0, 0
    if started and not addon.testing then Poll() end
end

function addon.StartTracking()
    if started then return end
    started = true
    lastTesting = addon.testing or false
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_NAME_UPDATE")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(_, event, token)
        if event == "UNIT_HEALTH" then
            if not addon.testing and Accessible(token) and token == unit then
                addon.UpdateHealth(unit)
            end
        elseif Accessible(token) then
            rosterDirty = true
        end
    end)
    frame:SetScript("OnUpdate", function(_, elapsed)
        local testing = addon.testing or false
        if testing ~= lastTesting then
            lastTesting = testing
            addon.ResetTracking()
        end
        if testing then return end
        elapsedPoll = elapsedPoll + elapsed
        elapsedReports = elapsedReports + elapsed
        if elapsedPoll >= 0.2 then
            elapsedPoll = 0
            Poll()
        end
        if elapsedReports >= 1 then
            elapsedReports = 0
            FlushReports()
        end
    end)
    Poll()
end
