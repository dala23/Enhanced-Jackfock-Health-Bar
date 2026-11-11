local _, addon = ...
---@cast addon MyForeverAddon

local PREFIX, LIMIT = "EJFHB1", 2147483647
local started, ownName, ownKey, whirlwindID, whirlwindName
local remoteKnown, lastCastGUID = {}, nil
local dirty, prefixReady = false, false
local nextAttempt, nextBroadcast, elapsed = 0, 0, 0

local function Public(value)
    return not issecretvalue(value)
end

local function Key(name)
    return name:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " "):lower()
end

local function ValidCount(value)
    return type(value) == "number" and value == value and value >= 0
        and value <= LIMIT and value == math.floor(value)
end

local function Stats()
    if type(addon.db.counters) ~= "table" then addon.db.counters = {} end
    local key = Key(addon.db.targetName)
    local stats = addon.db.counters[key]
    if type(stats) ~= "table" then stats = {}; addon.db.counters[key] = stats end
    if not ValidCount(stats.deaths) then stats.deaths = 0 end
    if not ValidCount(stats.whirlwinds) then stats.whirlwinds = 0 end
    stats.whirlwindsUnknown = stats.whirlwindsUnknown == true
    return stats, key
end

local function Refresh()
    if addon.UpdateCounters then addon.UpdateCounters() end
end

local function ResolveIdentity()
    ownName = addon.GetUnitDisplayName("player")
    ownKey = ownName and Key(ownName) or nil
    whirlwindID, whirlwindName = nil, nil
    if C_Spell and C_Spell.GetSpellInfo then
        -- Resolve the current English client's spell instead of assuming a
        -- Retail/Classic ID. Missing metadata leaves the counter unavailable.
        local info = C_Spell.GetSpellInfo("Whirlwind")
        if Public(info) and type(info) == "table" and Public(info.spellID)
            and Public(info.name) and ValidCount(info.spellID) and info.spellID > 0
            and type(info.name) == "string" and info.name ~= "" then
            whirlwindID, whirlwindName = info.spellID, info.name
        end
    end
    dirty = true
    Refresh()
end

function addon.GetCounters()
    if not started then return 0, nil, false end
    local stats, key = Stats()
    if key == ownKey then
        return stats.deaths, whirlwindID and not stats.whirlwindsUnknown and stats.whirlwinds or nil, false
    end
    local snapshot = remoteKnown[key] == true
    return stats.deaths, snapshot and stats.whirlwinds or nil, snapshot
end

function addon.RecordDeath()
    if not started or addon.testing then return end
    local stats = Stats()
    stats.deaths = math.min(LIMIT, stats.deaths + 1)
    dirty = true
    Refresh()
end

local function ObserveCast(token, castGUID, spellID)
    if addon.testing or not Public(token) or token ~= "player" then return end
    local stats, key = Stats()
    if key ~= ownKey or not whirlwindID then return end
    if not Public(spellID) then
        -- An opaque cast could have been Whirlwind: never present a complete tally.
        stats.whirlwindsUnknown = true
        dirty = true
        Refresh()
        return
    end
    if not ValidCount(spellID) or spellID == 0 then return end
    if Public(castGUID) and type(castGUID) == "string" then
        if castGUID == lastCastGUID then return end
        lastCastGUID = castGUID
    end
    local isWhirlwind = spellID == whirlwindID
    if not isWhirlwind then
        local info = C_Spell.GetSpellInfo(spellID)
        isWhirlwind = Public(info) and type(info) == "table" and Public(info.name)
            and info.name == whirlwindName
    end
    if isWhirlwind then
        stats.whirlwinds = math.min(LIMIT, stats.whirlwinds + 1)
        dirty = true
        Refresh()
    end
end

local function GroupChannel()
    local grouped, raid = IsInGroup(), IsInRaid()
    if not Public(grouped) or not Public(raid) or not grouped then return nil end
    return raid and "RAID" or "PARTY"
end

local function TargetSender(sender, key, channel)
    if Key(sender) ~= key or channel ~= GroupChannel() then return false end
    local raid = channel == "RAID"
    for index = 1, raid and 40 or 4 do
        local name = addon.GetUnitDisplayName((raid and "raid" or "party") .. index)
        if name and Key(name) == key then return true end
    end
    return false
end

local function Receive(prefix, text, channel, sender)
    if addon.testing or not Public(prefix) or not Public(text) or not Public(channel)
        or not Public(sender) or prefix ~= PREFIX or type(text) ~= "string"
        or type(channel) ~= "string" or type(sender) ~= "string" or #text > 240 then return end
    local name, deaths, whirlwinds = text:match("^1\t([^\t]+)\t(%d+)\t(%d+)$")
    if not name then return end
    deaths, whirlwinds = tonumber(deaths), tonumber(whirlwinds)
    local stats, key = Stats()
    if key == ownKey or Key(name) ~= key or not ValidCount(deaths) or not ValidCount(whirlwinds)
        or not TargetSender(sender, key, channel) then return end
    stats.whirlwinds = whirlwinds
    remoteKnown[key] = true
    -- A peer snapshot must not overwrite this client's observed death counter.
    Refresh()
end

local function SendLatest()
    if addon.testing or not prefixReady then return end
    local now = GetTime()
    if now < nextAttempt or (not dirty and now < nextBroadcast) then return end
    local stats, key = Stats()
    if key ~= ownKey or not whirlwindID or stats.whirlwindsUnknown then return end
    local channel = GroupChannel()
    if not channel then return end
    local combat, chat = InCombatLockdown(), C_ChatInfo.InChatMessagingLockdown()
    local restricted = C_ChatInfo.AreOutgoingAddonChatMessagesRestricted()
    if not Public(combat) or not Public(chat) or not Public(restricted) or combat or chat or restricted then
        nextAttempt = now + 5
        return
    end
    local payload = string.format("1\t%s\t%d\t%d", ownName, stats.deaths, stats.whirlwinds)
    if #payload > 240 or ownName:find("[%c]") then return end
    local result = C_ChatInfo.SendAddonMessage(PREFIX, payload, channel)
    if Public(result) and result == Enum.SendAddonMessageResult.Success then
        dirty, nextBroadcast, nextAttempt = false, now + 30, now + 1
    else
        nextAttempt = now + 5
    end
end

function addon.StartCounters()
    if started then return end
    started = true
    Stats()
    ResolveIdentity()
    if C_ChatInfo.RegisterAddonMessagePrefix and C_ChatInfo.SendAddonMessage
        and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted and Enum.RegisterAddonMessagePrefixResult
        and Enum.SendAddonMessageResult then
        local result = C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
        prefixReady = Public(result) and (result == Enum.RegisterAddonMessagePrefixResult.Success
            or result == Enum.RegisterAddonMessagePrefixResult.DuplicatePrefix)
    end
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("SPELLS_CHANGED")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then ObserveCast(...)
        elseif event == "CHAT_MSG_ADDON" then Receive(...)
        elseif event == "GROUP_ROSTER_UPDATE" then dirty = true
        else ResolveIdentity() end
    end)
    frame:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed >= 1 then
            elapsed = 0
            SendLatest()
        end
    end)
end
