"""Lua 5.1 checks with local mocks; never connects to or sends chat in WoW."""

from pathlib import Path
import sys
import package as release_package

ROOT = Path(__file__).resolve().parents[1]
ADDON_NAME = "EnhancedJackfockHealthBar"
sys.path.insert(0, str(ROOT / ".tools" / "python"))
try:
    from lupa.lua51 import LuaRuntime
except ImportError:
    raise SystemExit("Install checker: python -m pip install --target .tools/python lupa==2.6")


MOCKS = r"""
_mock = {frames = {}, units = {}, now = 100, raid = true, groupSize = 40,
    guild = true, combat = false, locked = false, sounds = {}, soundCalls = {}, soundSuccess = true,
    activeSounds = {}, stoppedSounds = {}, nextSoundHandle = 1,
    chat = {}, logs = {}, recaps = {},
    addonMessages = {}, prefixes = {}, outgoingRestricted = false, addonSendResult = 0,
    calls = {health = 0, unitExists = 0, deathRecords = 0, curves = 0, isPlaying = 0}}
local secretMT = {}
local function forbidden() error("Secret value inspected by Lua") end
secretMT.__add, secretMT.__sub, secretMT.__mul, secretMT.__div = forbidden, forbidden, forbidden, forbidden
secretMT.__lt, secretMT.__le, secretMT.__concat, secretMT.__tostring = forbidden, forbidden, forbidden, forbidden
function _mock.secret(value) return setmetatable({value = value}, secretMT) end
function issecretvalue(value) return getmetatable(value) == secretMT end
function canaccessvalue(value) return not issecretvalue(value) end
local function native(value) return issecretvalue(value) and rawget(value, "value") or value end
function print(...) _mock.logs[#_mock.logs + 1] = {...} end
function GetTime() return _mock.now end
Enum = {LuaCurveType = {Linear = 0, Step = 1},
    DamageMeterSessionType = {Overall = 0, Current = 1, Expired = 2},
    DamageMeterType = {DamageDone = 0, Deaths = 9},
    RegisterAddonMessagePrefixResult = {Success = 0, DuplicatePrefix = 1},
    SendAddonMessageResult = {Success = 0}}
Constants = {CharacterNameSeparatorConsts = {CHARACTERNAME_SURNAME_SEPARATOR = " "}}
SOUNDKIT = {RAID_WARNING = 8959}; STANDARD_TEXT_FONT = "Fonts/FRIZQT__.TTF"
local Frame = {}; Frame.__index = Frame
local Font = {}; Font.__index = Font
local Animation = {}; Animation.__index = Animation
local Curve = {}; Curve.__index = Curve
local function region(parent)
    return setmetatable({parent = parent, shown = true, scripts = {}, events = {}, fonts = {},
        x = 0, y = 0, moving = false, alpha = 1}, Frame)
end
function Frame:SetSize(w, h) self.width, self.height = w, h end
function Frame:SetWidth(v) self.width = v end
function Frame:SetHeight(v) self.height = v end
function Frame:SetFrameStrata(v) self.strata = v end
function Frame:SetClampedToScreen(v) self.clamped = v end
function Frame:SetMovable(v) self.movable = v end
function Frame:EnableMouse(v) self.mouse = v end
function Frame:RegisterForDrag(v) self.dragButton = v end
function Frame:SetBackdrop(v) assert(self.template == "BackdropTemplate"); self.backdrop = v end
function Frame:SetBackdropColor(...) self.backdropColor = {...} end
function Frame:SetPoint(p, parent, relative, x, y)
    self.point = {p, parent, relative, x, y}
    if p == "CENTER" and relative == "CENTER" then self.x, self.y = parent.x + x, parent.y + y end
end
function Frame:SetAllPoints(parent) self.allPoints = parent or self.parent end
function Frame:ClearAllPoints() self.point = nil end
function Frame:GetCenter() return self.x, self.y end
function Frame:SetScript(event, fn) self.scripts[event] = fn end
function Frame:RegisterEvent(event) self.events[event] = true; return true end
function Frame:UnregisterEvent(event) self.events[event] = nil end
function Frame:StartMoving() assert(self.movable); self.moving = true end
function Frame:StopMovingOrSizing() self.moving = false end
function Frame:IsShown() return self.shown end
function Frame:Show()
    local shown = self.shown; self.shown = true
    if not shown and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function Frame:Hide()
    local shown = self.shown; self.shown = false
    if shown and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Frame:SetAlpha(v) self.alpha = v end
function Frame:SetMinMaxValues(a, b) self.minimum, self.maximum = a, b end
function Frame:GetMinMaxValues() return self.minimum, self.maximum end
function Frame:SetValue(v)
    assert(self.kind ~= "Slider" or not issecretvalue(v), "Options slider received secret game data")
    local previous = self.value
    self.value = v
    if self.kind == "Slider" and v ~= previous and self.scripts.OnValueChanged then
        self.scripts.OnValueChanged(self, v, false)
    end
end
function Frame:GetValue() return self.value end
function Frame:SetOrientation(v) self.orientation = v end
function Frame:SetValueStep(v) self.step = v end
function Frame:SetObeyStepOnDrag(v) self.obeyStep = v end
function Frame:SetThumbTexture(v) self.thumbTexture = v end
function Frame:GetThumbTexture()
    self.thumb = self.thumb or region(self); return self.thumb
end
function Frame:SetText(v) self.text = v end
function Frame:GetText() return self.text end
function Frame:SetAutoFocus(value) self.autoFocus = value end
function Frame:SetMaxLetters(value) self.maxLetters = value end
function Frame:SetTextInsets(...) self.textInsets = {...} end
function Frame:ClearFocus() self.focused = false end
function Frame:SetChecked(v) self.checked = v and true or false end
function Frame:GetChecked() return self.checked or false end
function Frame:Enable() self.enabled = true end
function Frame:Disable() self.enabled = false end
function Frame:IsEnabled() return self.enabled ~= false end
function Frame:SetStatusBarTexture(v) self.texture = v end
function Frame:SetStatusBarColor(...) self.color = {...} end
function Frame:SetColorTexture(...) self.color = {...} end
function Frame:CreateTexture(name, layer)
    assert(name == nil); local texture = region(self); texture.layer = layer; return texture
end
function Frame:CreateFontString(name, layer, template)
    assert(name == nil); local font = setmetatable(region(self), Font)
    font.layer, font.template = layer, template; self.fonts[#self.fonts + 1] = font; return font
end
Font.SetPoint, Font.SetAlpha = Frame.SetPoint, Frame.SetAlpha
function Font:SetText(v) self.text = v end
function Font:SetFormattedText(fmt, ...)
    local args = {...}; for i = 1, #args do args[i] = native(args[i]) end
    self.text = string.format(fmt, unpack(args))
end
function Font:SetJustifyH(v) self.justification = v end
function Font:SetFont(...) self.font = {...}; return true end
function Font:SetHeight(v) self.height = v end
function Frame:CreateAnimationGroup() return setmetatable({animations = {}}, Animation) end
function Animation:CreateAnimation(kind)
    local anim = setmetatable({kind = kind}, Animation); self.animations[#self.animations + 1] = anim; return anim
end
function Animation:SetDuration(v) self.duration = v end
function Animation:SetFromAlpha(v) self.from = v end
function Animation:SetToAlpha(v) self.to = v end
function Animation:SetLooping(v) self.looping = v end
function Animation:Play() self.playing = true end
function Curve:SetType(v) self.type = v end
function Curve:AddPoint(x, y) self.points[#self.points + 1] = {x, y} end
local function evaluate(curve, x)
    x = native(x)
    local previous = curve.points[1]
    for i = 2, #curve.points do
        local p = curve.points[i]
        if x < p[1] then
            if curve.type == Enum.LuaCurveType.Step then return previous[2] end
            return previous[2] + (p[2] - previous[2]) * (x - previous[1]) / (p[1] - previous[1])
        end
        previous = p
    end
    return previous[2]
end
function Curve:Evaluate(x)
    assert(not issecretvalue(x), "Direct curve evaluation received a secret")
    return evaluate(self, x)
end
C_CurveUtil = {}
function C_CurveUtil.CreateCurve()
    _mock.calls.curves = _mock.calls.curves + 1
    return setmetatable({points = {}}, Curve)
end
UIParent = region(nil); UIParent.x, UIParent.y = 500, 400
SlashCmdList = {}
function CreateFrame(kind, name, parent, template)
    assert(kind == "Frame" or kind == "Button" or kind == "StatusBar" or kind == "Slider"
        or kind == "CheckButton" or kind == "EditBox")
    assert(name == nil, "Frames should remain anonymous")
    local f = region(parent); f.kind, f.template = kind, template
    _mock.frames[#_mock.frames + 1] = f; return f
end
function UnitExists(unit)
    _mock.calls.unitExists = _mock.calls.unitExists + 1
    return _mock.units[unit] ~= nil
end
function UnitIsConnected(unit) return UnitExists(unit) and _mock.units[unit].connected ~= false end
function UnitIsDeadOrGhost(unit) return UnitExists(unit) and (_mock.units[unit].dead or false) end
function UnitAffectingCombat(unit) return UnitExists(unit) and (_mock.units[unit].combat or false) end
function UnitIsPlayer(unit) return UnitExists(unit) and _mock.units[unit].player ~= false end
function UnitName(unit) local u = _mock.units[unit]; if u then return u.name, u.surname end end
function UnitGUID(unit) local u = _mock.units[unit]; return u and u.guid end
function IsInRaid() return _mock.raid end
function IsInGroup() return _mock.raid or _mock.party == true end
function IsInGuild() return _mock.guild end
function InCombatLockdown() return _mock.combat end
function UnitHealthPercent(unit, predicted, curve)
    _mock.calls.health = _mock.calls.health + 1
    local u = assert(_mock.units[unit]); local v = u.percent or 1
    if not curve then return v end
    local result = evaluate(curve, v)
    return issecretvalue(v) and _mock.secret(result) or result
end
C_Sound = {}
local function playSound(kind, asset, channel, options)
    assert(not issecretvalue(asset) and not issecretvalue(channel))
    local call = {kind=kind, channel=channel, options=options}
    if kind == "file" then call.path = asset else call.soundKitID = asset end
    _mock.sounds[#_mock.sounds + 1] = asset
    _mock.soundCalls[#_mock.soundCalls + 1] = call
    if not _mock.soundSuccess then return false, nil end
    local handle = _mock.nextSoundHandle
    _mock.nextSoundHandle = handle + 1
    call.handle = handle
    _mock.activeSounds[handle] = call
    return true, handle
end
function C_Sound.PlaySoundWithOptions(options)
    return playSound("kit", options.soundKitID, nil, options)
end
function PlaySound(soundKitID, channel)
    return playSound("kit", soundKitID, channel)
end
function PlaySoundFile(path, channel)
    return playSound("file", path, channel)
end
function StopSound(handle, fadeSeconds)
    assert(not issecretvalue(handle) and not issecretvalue(fadeSeconds))
    _mock.stoppedSounds[#_mock.stoppedSounds + 1] = {handle=handle, fadeSeconds=fadeSeconds}
    _mock.activeSounds[handle] = nil
end
function C_Sound.IsPlaying(handle)
    assert(not issecretvalue(handle))
    _mock.calls.isPlaying = _mock.calls.isPlaying + 1
    return _mock.activeSounds[handle] ~= nil
end
C_ChatInfo = {}
function C_ChatInfo.InChatMessagingLockdown() return _mock.locked end
function C_ChatInfo.SendChatMessage(message, channel)
    assert(not _mock.locked and not _mock.combat, "Chat sent during restrictions")
    assert(not issecretvalue(message) and #message <= 255, "Invalid chat message")
    _mock.chat[#_mock.chat + 1] = {message = message, channel = channel}
end
function C_ChatInfo.RegisterAddonMessagePrefix(prefix)
    assert(not issecretvalue(prefix))
    if _mock.prefixes[prefix] then return Enum.RegisterAddonMessagePrefixResult.DuplicatePrefix end
    _mock.prefixes[prefix] = true
    return Enum.RegisterAddonMessagePrefixResult.Success
end
function C_ChatInfo.AreOutgoingAddonChatMessagesRestricted() return _mock.outgoingRestricted end
function C_ChatInfo.SendAddonMessage(prefix, message, channel)
    assert(not _mock.combat and not _mock.locked and not _mock.outgoingRestricted,
        "Peer snapshot sent during restrictions")
    assert(not issecretvalue(prefix) and not issecretvalue(message) and #message <= 240)
    _mock.addonMessages[#_mock.addonMessages + 1] = {prefix = prefix, message = message, channel = channel}
    return _mock.addonSendResult
end
-- Synthetic spell fixtures: these IDs make no claim about the real game.
_mock.spellInfo = {
    Whirlwind = {spellID = 1001, name = "Whirlwind"},
    [1001] = {spellID = 1001, name = "Whirlwind"},
    [1002] = {spellID = 1002, name = "Whirlwind"},
    [2001] = {spellID = 2001, name = "Heroic Strike"},
}
C_Spell = {}
function C_Spell.GetSpellInfo(spell)
    assert(not issecretvalue(spell), "Spell lookup received an opaque identifier")
    return _mock.spellInfo[spell]
end
C_DamageMeter = {}
function C_DamageMeter.IsDamageMeterAvailable() return true, "" end
function C_DamageMeter.GetCombatSessionFromType(sessionType, kind)
    _mock.calls.deathRecords = _mock.calls.deathRecords + 1
    return _mock.currentMeter
end
function C_DamageMeter.GetSessionDurationSeconds(sessionType) return _mock.sessionDuration end
C_DeathRecap = {}
function C_DeathRecap.GetRecapEvents(id) return _mock.recaps[id] end
function _mock.fire(event, ...)
    for _, f in ipairs(_mock.frames) do if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end end
end
function _mock.tick(seconds)
    _mock.now = _mock.now + seconds
    for _, f in ipairs(_mock.frames) do if f.shown and f.scripts.OnUpdate then f.scripts.OnUpdate(f, seconds) end end
end
function _mock.step(count) for i = 1, count do _mock.tick(1) end end
function _mock.bar()
    for _, f in ipairs(_mock.frames) do if f.kind == "StatusBar" then return f end end
end
function _mock.mainFonts()
    local result = {}
    for _, frame in ipairs(_mock.frames) do
        local parent = frame
        while parent do
            if parent == addon.window then
                for _, font in ipairs(frame.fonts) do result[#result + 1] = font end
                break
            end
            parent = parent.parent
        end
    end
    return result
end
-- Test instrumentation models the native renderer accepting secret alpha.
-- Production Lua must never read these widgets to infer health thresholds.
function _mock.displayAlpha(font)
    local alpha, region = 1, font
    while region do
        if not region.shown then return 0 end
        alpha = alpha * native(region.alpha or 1)
        region = region.parent
    end
    return alpha
end
function _mock.click(button)
    assert(button:IsEnabled(), "Clicked a disabled control")
    if button.kind == "CheckButton" then button:SetChecked(not button:GetChecked()) end
    if button.scripts.OnClick then button.scripts.OnClick(button, "LeftButton") end
end
function _mock.button(text)
    for _, frame in ipairs(_mock.frames) do
        if frame.kind == "Button" and frame.text == text then return frame end
    end
    error("No button labelled " .. text)
end
function _mock.optionControls(kind)
    local result = {}
    for _, frame in ipairs(_mock.frames) do
        local parent = frame.parent
        while parent do
            if parent == addon.optionsWindow then
                if frame.kind == kind then result[#result + 1] = frame end
                break
            end
            parent = parent.parent
        end
    end
    return result
end
"""

TARGET = r"""
_mock.currentMeter = {combatSources = {}}
_mock.units.raid40 = {name = "Dr", surname = "Enkel", guid = "target-1", percent = 1}
"""


def manifest_files():
    directory = ROOT / ADDON_NAME
    toc = directory / f"{ADDON_NAME}.toc"
    assert toc.stem == directory.name
    assert not (ROOT / "MyForeverAddon").exists(), "Old addon folder is still present"
    lines = toc.read_text(encoding="utf-8").splitlines()
    assert "## Interface: 16001" in lines and "## SavedVariables: MyForeverAddonDB" in lines
    files = [line.strip() for line in lines if line.strip() and not line.startswith("#")]
    assert files == ["Namespace.lua", "Audio.lua", "Window.lua", "Tracker.lua", "Counters.lua", "Options.lua", "Core.lua"], files
    paths = [directory / name for name in files]
    assert all(path.is_file() and path.parent == directory for path in paths)
    return paths


def fresh_addon(paths, saved="nil", setup=""):
    lua = LuaRuntime(unpack_returned_tuples=True)
    assert lua.eval("_VERSION") == "Lua 5.1"
    lua.execute(MOCKS)
    lua.execute(setup)
    baseline = set(lua.globals())
    addon = lua.table()
    for path in paths:
        chunk = lua.execute("return assert(loadstring(...))", path.read_text(encoding="utf-8"))
        chunk(ADDON_NAME, addon)
    assert set(lua.globals()) == baseline, "Unexpected file-scope global"
    assert lua.globals().MyForeverAddonDB is None
    lua.execute('_mock.fire("ADDON_LOADED", "OtherAddon")')
    assert addon.window is None and lua.globals().MyForeverAddonDB is None
    lua.execute('_mock.fire("ADDON_LOADED", "MyForeverAddon")')
    assert addon.window is None and lua.globals().MyForeverAddonDB is None, "Old addon name initialized the new addon"
    original = lua.eval(saved)
    lua.globals().MyForeverAddonDB = original
    lua.execute('_mock.fire("ADDON_LOADED", ...)', ADDON_NAME)
    assert addon.window is not None
    assert set(lua.globals()) == baseline | {"MyForeverAddonDB", "SLASH_MYFOREVERADDON1"}
    count = len(lua.globals()._mock.frames)
    lua.execute('_mock.fire("ADDON_LOADED", ...)', ADDON_NAME)
    assert len(lua.globals()._mock.frames) == count
    lua.globals().addon = addon
    return lua, addon, original


def check_defaults(paths):
    for saved, x, y in [("nil", 0, 0), ('"broken"', 0, 0),
        ("{windowPosition = false}", 0, 0),
        ("{windowPosition = {x = 0/0, y = math.huge}}", 0, 0),
        ("{windowPosition = {x = -math.huge, y = -12}}", 0, -12),
        ("{windowPosition = {x = 20, y = 30}, futureSetting = 7, sound = false}", 20, 30)]:
        lua, addon, original = fresh_addon(paths, saved)
        db = addon.db
        assert db.windowPosition.x == x and db.windowPosition.y == y
        assert addon.window.x == 500 + x and addon.window.y == 400 + y
        assert db.targetName == "Dr Enkel" and db.width == 420 and db.height == 290
        assert list(db.thresholds.values()) == [50, 30, 15]
        assert db.flashStrength == 1 and db.flashFade == 0.7
        assert db.soundFile == "alarm.mp3"
        if "futureSetting" in saved:
            assert lua.eval("function(a, b) return a == b end")(db, original)
            assert db.futureSetting == 7 and db.sound is False
    _, addon, _ = fresh_addon(paths, "{width=0/0,height=math.huge,thresholds={1,2,3},flash=false,flashStrength=0/0,flashFade=math.huge}")
    assert addon.db.width == 420 and addon.db.height == 290 and addon.db.flash is False
    assert list(addon.db.thresholds.values()) == [50, 30, 15]
    assert addon.db.flashStrength == 1 and addon.db.flashFade == 0.7
    _, saved_size, _ = fresh_addon(paths, "{width=1000,height=360}")
    assert saved_size.db.width == 1000 and saved_size.db.height == 360
    assert saved_size.window.width == 1000 and saved_size.window.height == 360
    _, invalid_audio, _ = fresh_addon(paths, '{soundFile="../outside.mp3"}')
    assert invalid_audio.db.soundFile == "alarm.mp3"
    print("PASS: delayed initialization, saved-data validation/preservation, no extra globals")


def check_commands(paths):
    lua, _, _ = fresh_addon(paths)
    lua.execute(r"""
        local slash = SlashCmdList.MYFOREVERADDON
        slash("size 1400 500"); assert(addon.db.width == 1400 and addon.db.height == 500)
        slash("size 359 500"); assert(addon.db.width == 1400)
        slash("size 500 219"); assert(addon.db.height == 500)
        slash("size 360 220"); assert(addon.db.width == 360 and addon.db.height == 220)
        slash("thresholds 70 40 10"); assert(addon.db.thresholds[2] == 40)
        slash("thresholds 10 40 70"); assert(addon.db.thresholds[2] == 40)
        slash("sound off"); slash("flash off"); slash("raid off"); slash("guild off")
        assert(not addon.db.sound and not addon.db.flash and not addon.db.announceRaid and not addon.db.announceGuild)
        slash("sound maybe"); assert(not addon.db.sound)
        local window = addon.window; window:Hide(); slash(""); assert(window:IsShown())
        slash(""); assert(not window:IsShown()); slash("")
        window.scripts.OnDragStart(window); window.x, window.y = 800, 260
        window.scripts.OnDragStop(window); assert(not window.moving)
        assert(addon.db.windowPosition.x == 300 and addon.db.windowPosition.y == -140)
        local count = #_mock.frames; addon.CreateWindow(); assert(#_mock.frames == count)
        slash("test 20"); assert(addon.testing); _mock.tick(1); assert(#_mock.chat == 0)
        slash("live"); assert(not addon.testing)
    """)
    _, restored, _ = fresh_addon(paths, "{windowPosition={x=300,y=-140}}")
    assert restored.window.x == 800 and restored.window.y == 260
    print("PASS: slash settings validation, window reuse and saved position")


def check_options_validation(paths):
    lua, _, _ = fresh_addon(paths, setup=TARGET)
    lua.execute(r"""
        local function settings()
            return {width=1440,height=600,thresholds={60,35,10},flashStrength=0.5,flashFade=1.2,
                sound=false,flash=false,announceRaid=false,announceGuild=false,soundFile="other-alarm.ogg"}
        end
        local invalid = {
            function(s) s.width = 359 end,
            function(s) s.height = 219 end,
            function(s) s.width = math.huge end,
            function(s) s.height = 0/0 end,
            function(s) s.thresholds = {10,35,60} end,
            function(s) s.thresholds = {60,35,0} end,
            function(s) s.thresholds = {100,35,10} end,
            function(s) s.thresholds = {60,35,0/0} end,
            function(s) s.sound = "off" end,
            function(s) s.flashStrength = -0.1 end,
            function(s) s.flashStrength = 1.1 end,
            function(s) s.flashFade = 0.2 end,
            function(s) s.flashFade = 2.1 end,
            function(s) s.soundFile = false end,
            function(s) s.soundFile = "../outside.mp3" end,
            function(s) s.soundFile = "Media/alert.mp3" end,
            function(s) s.soundFile = "C:\\alert.mp3" end,
            function(s) s.soundFile = "alarm..mp3" end,
            function(s) s.soundFile = "alert.wav" end,
            function(s) s.soundFile = "alert\n.mp3" end,
            function(s) s.soundFile = string.rep("a",129) .. ".mp3" end,
        }
        for _, corrupt in ipairs(invalid) do
            local s = settings(); corrupt(s)
            local success = addon.ApplyOptions(s)
            assert(not success, "Invalid options accepted")
            assert(addon.db.width == 420 and addon.db.height == 290)
            assert(addon.db.thresholds[1] == 50 and addon.db.sound and addon.db.flash)
            assert(addon.db.announceRaid and addon.db.announceGuild, "Rejected draft partly saved")
            assert(addon.db.soundFile == "alarm.mp3", "Rejected sound draft partly saved")
        end
        local s = settings()
        local success = addon.ApplyOptions(s)
        assert(success, "Valid options rejected")
        assert(addon.db.width == 1440 and addon.db.height == 600)
        assert(addon.db.flashStrength == 0.5 and addon.db.flashFade == 1.2)
        assert(addon.db.soundFile == "other-alarm.ogg")
        assert(addon.window.width == 1440 and addon.window.height == 600)
        assert(addon.db.thresholds[1] == 60 and addon.db.thresholds[2] == 35 and addon.db.thresholds[3] == 10)
        assert(not addon.db.sound and not addon.db.flash and not addon.db.announceRaid and not addon.db.announceGuild)
        s.thresholds[1] = 90
        assert(addon.db.thresholds[1] == 60, "Saved options alias an editable draft")
        assert(#_mock.chat == 0, "Applying options sent chat")
    """)
    _, restored, _ = fresh_addon(paths,
        '{width=1440,height=600,thresholds={60,35,10},flashStrength=0.5,flashFade=1.2,sound=false,flash=false,announceRaid=false,announceGuild=false,soundFile="other-alarm.ogg"}')
    assert restored.window.width == 1440 and restored.window.height == 600
    assert list(restored.db.thresholds.values()) == [60, 35, 10]
    assert restored.db.sound is False and restored.db.flash is False
    assert restored.db.announceRaid is False and restored.db.announceGuild is False
    assert restored.db.flashStrength == 0.5 and restored.db.flashFade == 1.2
    assert restored.db.soundFile == "other-alarm.ogg"
    print("PASS: options validate atomically, apply to the window and survive saved-data reload")


def check_options_panel(paths):
    lua, _, _ = fresh_addon(paths, setup=TARGET)
    lua.execute(r"""
        assert(addon.optionsWindow == nil, "Options should be created lazily")
        local before = #_mock.frames
        SlashCmdList.MYFOREVERADDON("options")
        local panel = assert(addon.optionsWindow)
        assert(panel:IsShown() and #_mock.frames > before)
        assert(not addon.testing and addon.db.width == 420 and addon.db.sound)
        local created = #_mock.frames
        local sliders, checks = _mock.optionControls("Slider"), _mock.optionControls("CheckButton")
        assert(#sliders == 7 and #checks == 4)
        assert(sliders[1]:GetValue() == 420 and sliders[2]:GetValue() == 290)
        assert(sliders[3]:GetValue() == 50 and checks[1]:GetChecked())
        sliders[1]:SetValue(2000); sliders[2]:SetValue(700)
        sliders[3]:SetValue(60); sliders[4]:SetValue(35); sliders[5]:SetValue(10)
        sliders[6]:SetValue(0.5); sliders[7]:SetValue(1.2)
        for _, check in ipairs(checks) do _mock.click(check) end
        assert(addon.db.width == 420 and addon.db.height == 290 and addon.db.sound,
            "Editing a draft saved options before Apply")
        assert(addon.window.width == 420, "Draft unexpectedly resized live frame")
        _mock.click(_mock.button("Apply"))
        assert(addon.db.width == 2000 and addon.db.height == 700)
        assert(addon.window.width == 2000 and addon.window.height == 700)
        assert(not addon.db.sound and not addon.db.flash and not addon.db.announceRaid and not addon.db.announceGuild)
        assert(addon.db.flashStrength == 0.5 and addon.db.flashFade == 1.2)
        sliders[1]:SetValue(2200)
        addon.ToggleOptions(); assert(not panel:IsShown())
        addon.ToggleOptions(); assert(panel:IsShown() and #_mock.frames == created)
        assert(sliders[1]:GetValue() == 2000 and not checks[1]:GetChecked(), "Reopen did not discard unsaved draft")
        sliders[3]:SetValue(20) -- Not above the 35% warning threshold.
        _mock.click(_mock.button("Test alerts"))
        assert(not addon.testing and addon.db.thresholds[1] == 60, "Invalid preview draft was applied")
        sliders[3]:SetValue(65)
        _mock.click(_mock.button("Test alerts"))
        assert(addon.testing and addon.db.thresholds[1] == 65)
        _mock.units.raid40.dead = true; _mock.step(5)
        assert(#_mock.chat == 0, "Options demo sent a death report")
        addon.ToggleOptions(); addon.ToggleOptions()
        assert(addon.testing, "Opening options unexpectedly stopped local demo")
        _mock.click(_mock.button("Resume live")); assert(not addon.testing)
        _mock.step(5); assert(#_mock.chat == 0, "Resume announced an already-dead unit")
        local sounds = #_mock.sounds
        _mock.click(_mock.button("Play sound"))
        assert(#_mock.sounds == sounds + 1 and not addon.db.sound, "Sound preview changed the saved sound preference")
        addon.window.x, addon.window.y = 800, 260
        addon.db.windowPosition.x, addon.db.windowPosition.y = 300, -140
        _mock.click(_mock.button("Center frame"))
        assert(addon.db.windowPosition.x == 0 and addon.db.windowPosition.y == 0)
        assert(addon.window.x == 500 and addon.window.y == 400)
        assert(#_mock.chat == 0)
    """)
    print("PASS: lazy/reused options, unsaved drafts, checkboxes, safe demo, sound preview and centering")


def check_health(paths):
    lua, _, _ = fresh_addon(paths, setup=TARGET)
    lua.execute(r"""
        local u, bar = _mock.units.raid40, _mock.bar()
        assert(bar.value == 1 and bar.fonts[1].text == "100%")
        u.percent = 0.4; _mock.tick(0.2); assert(#_mock.sounds == 1)
        _mock.tick(0.2); assert(#_mock.sounds == 1)
        u.percent = _mock.secret(0.1); _mock.tick(0.2)
        assert(issecretvalue(bar.value) and bar.fonts[1].text == "10%")
        assert(#_mock.sounds == 1, "Secret health triggered sound")
        u.percent = _mock.secret(0.02); _mock.tick(0.2); assert(#_mock.sounds == 1)
        _mock.units.raid40 = nil; _mock.fire("GROUP_ROSTER_UPDATE"); _mock.tick(0.2)
        assert(bar.value == 0 and #_mock.chat == 0)
        _mock.units.party4 = {name="Dr Enkel",guid="target-1",percent=0.8}
        _mock.raid, _mock.party = false, true; _mock.fire("GROUP_ROSTER_UPDATE"); _mock.tick(0.2)
        assert(bar.value == 0.8, "Party/full name resolution failed")
        _mock.units.party4.name = _mock.secret("Dr Enkel")
        _mock.fire("UNIT_NAME_UPDATE", "party4"); _mock.tick(0.2)
        assert(bar.value == 0, "Restricted name used for identity")
    """)
    print("PASS: raid/party name matching, secret health display, sound suppression and unit loss")


def check_audio(paths):
    lua, _, _ = fresh_addon(paths, setup=TARGET)
    lua.execute(r"""
        local u = _mock.units.raid40
        local function health(value)
            u.percent = value
            addon.UpdateHealth("raid40")
        end
        local function activeCount()
            local count = 0
            for _ in pairs(_mock.activeSounds) do count = count + 1 end
            return count
        end
        assert(activeCount() == 0, "Healthy player started an automatic alarm")
        health(0.5)
        assert(activeCount() == 1, "Alarm did not start at 50%")
        local first = _mock.soundCalls[#_mock.soundCalls]
        assert(first.kind == "file" and first.channel == "Master")
        assert(first.path:gsub("\\", "/") == "Interface/AddOns/EnhancedJackfockHealthBar/Media/alarm.mp3")
        health(0.2)
        assert(activeCount() == 1 and #_mock.soundCalls == 1, "Low-health updates overlapped alarm clips")
        -- Native playback completion, not a guessed clip duration, permits a repeat.
        _mock.activeSounds[first.handle] = nil
        _mock.tick(0.2)
        assert(#_mock.soundCalls == 2 and activeCount() == 1, "Native completed alarm was not repeated")
        local repeated = _mock.soundCalls[2].handle
        health(0.5001)
        assert(not _mock.activeSounds[repeated] and activeCount() == 0, "Alarm continued above 50%")
        assert(_mock.stoppedSounds[#_mock.stoppedSounds].fadeSeconds == 0, "Alarm stop was delayed by a fade")
        _mock.tick(0.2)
        assert(#_mock.soundCalls == 2, "Stopped alarm restarted on a stale playback handle")
        for _, value in ipairs({0, _mock.secret(0.2)}) do
            health(0.4)
            assert(activeCount() == 1)
            health(value)
            assert(activeCount() == 0, "Zero or secret health left an alarm playing")
        end
        health(0.4)
        addon.UpdateHealth(nil)
        assert(activeCount() == 0, "Losing the watched unit left an alarm playing")
        health(0.4)
        assert(activeCount() == 1)
        addon.StopAlertSound(true)
        assert(activeCount() == 0)
        _mock.tick(0.2)
        assert(activeCount() == 0, "Explicit Stop sound immediately rearmed at low HP")
        health(0.6); health(0.4)
        assert(activeCount() == 1, "Recovery did not rearm a manually stopped alarm")
        addon.ApplyOptions({sound=false})
        assert(activeCount() == 0, "Disabling sounds left the alarm playing")
        health(1)
        local savedFile = addon.db.soundFile
        local accepted, message = addon.PreviewSound("other-alarm.ogg")
        assert(accepted and type(message) == "string" and message ~= "")
        local preview = _mock.soundCalls[#_mock.soundCalls]
        assert(preview.channel == "Master" and preview.path:gsub("\\", "/"):find("/Media/other-alarm.ogg", 1, true))
        assert(activeCount() == 1 and addon.db.soundFile == savedFile and not addon.db.sound,
            "Explicit draft preview was suppressed or changed saved preferences")
        health(0.9)
        assert(_mock.activeSounds[preview.handle], "Healthy HP stopped an independent manual preview")
        addon.StopAlertSound()
        assert(activeCount() == 0, "Stop sound did not stop the manual preview")
        addon.ApplyOptions({sound=true})
        addon.SetDemo(20)
        assert(activeCount() == 1, "Local alert demo overlapped clips")
        addon.window:Hide()
        assert(activeCount() == 0, "Hiding a local demo left its alarm running")
        _mock.tick(0.2)
        assert(activeCount() == 0, "Hidden local demo rearmed its alarm")
        addon.window:Show()
        assert(activeCount() == 1, "Showing a low-health demo did not restore its preview")
        addon.SetDemo(nil)
        assert(activeCount() == 0 and #_mock.chat == 0, "Resume live left demo audio playing or sent chat")
        _mock.soundSuccess = false
        local attempts = #_mock.soundCalls
        health(0.4)
        for _ = 1, 5 do _mock.tick(0.2) end
        assert(#_mock.soundCalls == attempts + 1, "Failed automatic sound retried at every health update")
        health(1)
        local success, failure = addon.PreviewSound("other-alarm.ogg")
        assert(not success and type(failure) == "string" and failure ~= "", "Native audio rejection was reported as playback")
        assert(activeCount() == 0)
        _mock.soundSuccess = true
        assert(addon.PreviewSound(""))
        assert(_mock.soundCalls[#_mock.soundCalls].kind == "kit", "Empty filename did not select the built-in sound")
    """)
    print("PASS: native Master-channel alarm, repeat/stop boundaries, manual previews and playback failures")


def check_audio_health_events(paths):
    lua, _, _ = fresh_addon(paths, setup=TARGET)
    lua.execute(r"""
        local u = _mock.units.raid40
        local function activeCount()
            local count = 0
            for _ in pairs(_mock.activeSounds) do count = count + 1 end
            return count
        end
        u.percent = 0.4
        local time = GetTime()
        _mock.fire("UNIT_HEALTH", "raid40")
        assert(activeCount() == 1 and GetTime() == time, "Matching health event did not immediately start the alarm")
        local queries = _mock.calls.health
        _mock.fire("UNIT_HEALTH", "raid3")
        _mock.fire("UNIT_HEALTH", _mock.secret("raid40"))
        assert(_mock.calls.health == queries, "Unrelated or secret unit event was treated as the watched player")
        u.percent = 0.8
        _mock.fire("UNIT_HEALTH", "raid40")
        assert(activeCount() == 0 and GetTime() == time, "Recovery event waited for polling to stop the alarm")
        addon.SetDemo(20)
        _mock.fire("UNIT_HEALTH", "raid40")
        assert(activeCount() == 1 and #_mock.chat == 0, "Real-unit event disrupted isolated demo mode")
        addon.SetDemo(nil)
    """)
    print("PASS: matching public health events update audio immediately without secret-unit inspection")


def check_audio_idle_and_logout(paths):
    lua, _, _ = fresh_addon(paths, setup=TARGET)
    lua.execute(r"""
        assert(addon.PreviewSound())
        local preview = _mock.soundCalls[#_mock.soundCalls].handle
        local queries = _mock.calls.isPlaying
        for _ = 1, 100 do addon.UpdateAlarm(0.4) end
        assert(_mock.calls.isPlaying == queries, "Health-event burst repeatedly inspected a preview handle")
        assert(#_mock.soundCalls == 1, "Health-event burst overlapped the manual preview")
        _mock.tick(0.2)
        assert(_mock.calls.isPlaying == queries + 1, "Preview inspection was not limited to the audio poll")
        addon.UpdateAlarm(1)
        _mock.activeSounds[preview] = nil -- Native playback has finished.
        _mock.tick(0.2)
        queries = _mock.calls.isPlaying
        local starts = #_mock.soundCalls
        _mock.step(5)
        assert(_mock.calls.isPlaying == queries, "Completed healthy preview kept polling its native handle")
        assert(#_mock.soundCalls == starts, "Completed preview restarted without an alarm request")
    """)
    for mode in ("alarm", "preview"):
        lua, _, _ = fresh_addon(paths, setup=TARGET)
        lua.execute(r"""
            local mode = ...
            if mode == "alarm" then
                _mock.units.raid40.percent = 0.4
                addon.UpdateHealth("raid40")
            else
                assert(addon.PreviewSound())
            end
            local handle = assert(_mock.soundCalls[#_mock.soundCalls].handle)
            assert(_mock.activeSounds[handle])
            local audioFrame
            for _, frame in ipairs(_mock.frames) do
                if frame.events.PLAYER_LOGOUT then audioFrame = frame; break end
            end
            assert(audioFrame, "Audio cleanup is not registered for logout/UI replacement")
            _mock.fire("PLAYER_LOGOUT")
            assert(not _mock.activeSounds[handle], "Logout retained an owned playback handle")
            assert(_mock.stoppedSounds[#_mock.stoppedSounds].fadeSeconds == 0)
            local queries, starts = _mock.calls.isPlaying, #_mock.soundCalls
            -- Only the audio lifecycle is exercised after logout: the real UI
            -- environment is replaced, so fresh unit events are not simulated.
            for _ = 1, 5 do audioFrame.scripts.OnUpdate(audioFrame, 0.2) end
            assert(_mock.calls.isPlaying == queries and #_mock.soundCalls == starts,
                "Audio lifecycle continued native work after releasing logout handles")
        """, mode)
    print("PASS: bounded preview polling, idle completion cleanup and logout handle release")


def check_audio_options(paths):
    lua, _, _ = fresh_addon(paths, setup=TARGET)
    lua.execute(r"""
        addon.ToggleOptions()
        local edits = _mock.optionControls("EditBox")
        assert(#edits == 1, "Custom audio filename control is missing")
        local input = edits[1]
        assert(input:GetText() == "alarm.mp3")
        input:SetText("other-alarm.ogg")
        assert(addon.db.soundFile == "alarm.mp3", "Typing a sound draft saved before Apply")
        _mock.click(_mock.button("Play sound"))
        assert(addon.db.soundFile == "alarm.mp3", "Preview silently saved a sound draft")
        local preview = _mock.soundCalls[#_mock.soundCalls]
        assert(preview.path:gsub("\\", "/"):find("/Media/other-alarm.ogg", 1, true), "Preview ignored the sound draft")
        _mock.click(_mock.button("Stop sound"))
        assert(not C_Sound.IsPlaying(preview.handle))
        addon.ToggleOptions(); addon.ToggleOptions()
        assert(input:GetText() == "alarm.mp3", "Reopening options kept an unsaved sound draft")
        input:SetText("other-alarm.ogg")
        _mock.click(_mock.button("Apply"))
        assert(addon.db.soundFile == "other-alarm.ogg")
        input:SetText("../outside.mp3")
        local calls = #_mock.soundCalls
        _mock.click(_mock.button("Play sound"))
        assert(#_mock.soundCalls == calls, "Invalid preview path reached native playback")
        _mock.click(_mock.button("Apply"))
        assert(addon.db.soundFile == "other-alarm.ogg", "Invalid sound draft replaced saved preferences")
        input:SetText("alarm.mp3")
        _mock.soundSuccess = false
        local success, failure = addon.PreviewSound(input:GetText())
        assert(not success)
        _mock.click(_mock.button("Play sound"))
        local foundFailure = false
        for _, font in ipairs(addon.optionsWindow.fonts) do
            if type(font.text) == "string" and font.text:find(failure, 1, true) then foundFailure = true end
            assert(font.text ~= "Sound sample played using your game audio settings.", "Failed sound still claims playback")
        end
        assert(foundFailure, "Options did not show the native playback failure")
        assert(#_mock.chat == 0)
    """)
    print("PASS: custom audio draft/Apply behavior, preview error feedback and explicit stop control")


def check_health_commentary(paths):
    lua, _, _ = fresh_addon(paths, setup=TARGET)
    lua.execute(r"""
        local messages = {
            "Ser bra ut, kör Whirlwind",
            "Koordinera healingteamet",
            "NU JÄVLAR ÄR HAN ILLA UTE!",
        }
        local function expectCommentary(expected)
            local found, visible = {}, 0
            for _, font in ipairs(_mock.mainFonts()) do
                for _, message in ipairs(messages) do
                    if font.text == message then
                        found[message] = true
                        if _mock.displayAlpha(font) > 0 then
                            visible = visible + 1
                            assert(message == expected, "Wrong health commentary is visible")
                        end
                    end
                end
                local text = font.text or ""
                for _, legacy in ipairs({"LOCAL DEMO", "Try /", "Drag to move", "Click Options",
                    "Looking for", "LEGACY TRACKER STATUS", "LEGACY DEATH SUMMARY"}) do
                    assert(not text:find(legacy, 1, true), "Legacy footer text remains in main window: " .. text)
                end
            end
            for _, message in ipairs(messages) do assert(found[message], "Missing commentary layer") end
            assert(visible == 1, "Expected exactly one visible health commentary line")
        end
        expectCommentary(messages[1])
        if addon.SetTrackingStatus then addon.SetTrackingStatus("LEGACY TRACKER STATUS") end
        addon.ShowDeath("LEGACY DEATH SUMMARY", true)
        expectCommentary(messages[1])
        for _, sample in ipairs({{1, 1}, {0.8, 2}, {0.25, 2}, {0.2, 3}}) do
            _mock.units.raid40.percent = sample[1]
            addon.UpdateHealth("raid40")
            expectCommentary(messages[sample[2]])
        end
        addon.SetDemo(20)
        expectCommentary(messages[3])
        assert(#_mock.chat == 0)
        addon.SetDemo(nil)
        local sounds = #_mock.sounds
        _mock.units.raid40.percent = _mock.secret(0.2)
        addon.UpdateHealth("raid40")
        expectCommentary(messages[3])
        assert(#_mock.sounds == sounds, "Secret health commentary triggered a sound")
    """)
    print("PASS: one native health commentary line, correct boundary levels and no legacy footer clutter")


def check_own_counters(paths):
    setup = TARGET + r"""
        _mock.units.player = _mock.units.raid40
    """
    lua, _, _ = fresh_addon(paths, setup=setup)
    lua.execute(r"""
        local deaths, casts, snapshot = addon.GetCounters()
        assert(deaths == 0 and casts == 0 and not snapshot)
        _mock.fire("UNIT_SPELLCAST_START", "player", "cast-start", 1001)
        _mock.fire("UNIT_SPELLCAST_SUCCEEDED", "raid40", "other-unit", 1001)
        _mock.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "different-spell", 2001)
        assert(select(2, addon.GetCounters()) == 0, "Non-successful/non-local/unrelated cast was counted")
        _mock.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-1", 1001)
        _mock.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-1", 1001)
        _mock.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-rank", 1002)
        assert(select(2, addon.GetCounters()) == 2, "Readable own Whirlwind casts were not deduplicated")
        addon.SetDemo(20)
        _mock.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "demo-cast", 1001)
        addon.RecordDeath()
        assert(select(1, addon.GetCounters()) == 0 and select(2, addon.GetCounters()) == 2)
        addon.SetDemo(nil)
        _mock.fire("UNIT_SPELLCAST_SUCCEEDED", _mock.secret("player"), "opaque-unit", 1001)
        assert(select(2, addon.GetCounters()) == 2)
        _mock.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "opaque-spell", _mock.secret(1001))
        assert(select(2, addon.GetCounters()) == nil, "Opaque cast left a falsely complete Whirlwind tally")
        assert(addon.db.counters["dr enkel"].whirlwindsUnknown)
        _mock.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-after-opaque", 1001)
        assert(select(2, addon.GetCounters()) == nil, "Later readable cast erased incomplete-observation flag")
        _mock.step(40)
        assert(#_mock.addonMessages == 0, "An incomplete tally was broadcast as complete")
    """)
    lua, addon, _ = fresh_addon(paths,
        '{counters = {["dr enkel"] = {deaths = 3, whirlwinds = 7}}}', setup=setup)
    assert addon.GetCounters() == (3, 7, False)
    lua.execute('_mock.spellInfo.Whirlwind = nil; _mock.fire("SPELLS_CHANGED")')
    assert addon.GetCounters() == (3, None, False), "Missing spell metadata invented a readable tally"
    print("PASS: own successful Whirlwind casts, public GUID deduplication and incomplete-data guards")


def check_peer_counters(paths):
    lua, _, _ = fresh_addon(paths, setup=TARGET)
    lua.execute(r"""
        assert(select(2, addon.GetCounters()) == nil, "Unknown peer tally was presented as zero")
        local function packet(text, channel, sender, prefix)
            _mock.fire("CHAT_MSG_ADDON", prefix or "EJFHB1", text, channel or "RAID", sender or "Dr Enkel")
        end
        packet("1\tDr Enkel\t999\t8")
        local deaths, casts, snapshot = addon.GetCounters()
        assert(deaths == 0 and casts == 8 and snapshot, "Authenticated peer snapshot missing or deaths overwritten")
        local marked = false
        for _, font in ipairs(_mock.mainFonts()) do
            if (font.text or ""):find("Whirlwind: 8*", 1, true) then marked = true end
        end
        assert(marked, "Remote cached count is not marked as a snapshot")
        for _, invalid in ipairs({
            {"2\tDr Enkel\t0\t9"}, {"1\tOther Name\t0\t9"},
            {"1\tDr Enkel\t-1\t9"}, {"1\tDr Enkel\t0\t2147483648"},
            {"1\tDr Enkel\t0\t1.5"}, {"1\tDr Enkel\t0\t9\textra"},
            {"1\tDr Enkel\t0\t9", "PARTY"}, {"1\tDr Enkel\t0\t9", "WHISPER"},
            {"1\tDr Enkel\t0\t9", "RAID", "Impostor"},
            {"1\tDr Enkel\t0\t9", "RAID", "Dr Enkel-TestRealm"},
            {"1\tDr Enkel\t0\t9", "RAID", "Dr Enkel", "OTHER"},
            {string.rep("x", 241)},
        }) do
            packet(unpack(invalid))
            assert(select(2, addon.GetCounters()) == 8, "Malformed or unauthenticated peer packet changed tally")
        end
        local valid = "1\tDr Enkel\t0\t99"
        _mock.fire("CHAT_MSG_ADDON", _mock.secret("EJFHB1"), valid, "RAID", "Dr Enkel")
        _mock.fire("CHAT_MSG_ADDON", "EJFHB1", _mock.secret(valid), "RAID", "Dr Enkel")
        _mock.fire("CHAT_MSG_ADDON", "EJFHB1", valid, _mock.secret("RAID"), "Dr Enkel")
        _mock.fire("CHAT_MSG_ADDON", "EJFHB1", valid, "RAID", _mock.secret("Dr Enkel"))
        assert(select(2, addon.GetCounters()) == 8, "Secret peer payload inspected or accepted")
        _mock.combat, _mock.locked, _mock.outgoingRestricted = true, true, true
        _mock.step(10)
        deaths, casts, snapshot = addon.GetCounters()
        assert(deaths == 0 and casts == 8 and snapshot, "Restrictions erased the marked last-synced snapshot")
        packet("1\tDr Enkel\t0\t11")
        assert(select(2, addon.GetCounters()) == 11, "Readable authenticated incoming snapshot was rejected")
        assert(#_mock.addonMessages == 0)
        _mock.combat, _mock.locked, _mock.outgoingRestricted = false, false, false
        _mock.units.raid40 = nil
        packet("1\tDr Enkel\t0\t20")
        assert(select(2, addon.GetCounters()) == 11, "Sender outside actual group updated the tally")
    """)
    print("PASS: authenticated marked peer snapshots, malformed/secret packets and unknown remote data")


def check_peer_sending(paths):
    setup = TARGET + r"""
        _mock.units.player = _mock.units.raid40
    """
    for restriction in ("combat", "locked", "outgoingRestricted"):
        lua, _, _ = fresh_addon(paths, setup=setup)
        lua.execute(r"""
            local restriction = ...
            _mock[restriction] = true
            _mock.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-1", 1001)
            _mock.step(10)
            assert(#_mock.addonMessages == 0, "Peer send bypassed a game restriction")
            _mock[restriction] = false
            _mock.step(5)
            assert(#_mock.addonMessages == 1, "Allowed current snapshot was not sent after backoff")
            local sent = _mock.addonMessages[1]
            assert(sent.prefix == "EJFHB1" and sent.channel == "RAID")
            assert(sent.message == "1\tDr Enkel\t0\t1")
            _mock.step(4)
            assert(#_mock.addonMessages == 1, "Unchanged snapshot was sent at every update")
            addon.SetDemo(20)
            _mock.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "demo-cast", 1001)
            _mock.step(40)
            assert(#_mock.addonMessages == 1, "Demo sent peer messages")
        """, restriction)
    lua, addon, _ = fresh_addon(paths, setup=setup + '\nC_ChatInfo.RegisterAddonMessagePrefix = nil')
    lua.execute('_mock.step(40); assert(#_mock.addonMessages == 0)')
    assert addon.GetCounters() == (0, 0, False), "Unavailable transport broke local counters"
    print("PASS: peer sends respect combat/chat/realm restrictions, backoff, periodic limits and demo isolation")


def check_idle_work(paths):
    lua, _, _ = fresh_addon(paths)
    lua.execute(r"""
        local scans = _mock.calls.unitExists
        for i = 1, 4 do _mock.tick(0.2) end
        assert(_mock.calls.unitExists == scans, "Missing-player roster scanned more than once per second")
        _mock.units.raid40 = {name="Dr",surname="Enkel",guid="target-1",percent=1}
        _mock.fire("GROUP_ROSTER_UPDATE"); _mock.tick(0.2)
        assert(_mock.bar().value == 1, "Roster event did not bypass missing-player scan cooldown")
        local baselineQueries = _mock.calls.deathRecords
        for i = 1, 10 do _mock.tick(0.2) end
        assert(_mock.calls.deathRecords - baselineQueries <= 2, "Idle death meter queried at every health tick")
        _mock.units.raid40.combat = true; _mock.combat = true
        baselineQueries = _mock.calls.deathRecords
        for i = 1, 10 do _mock.tick(0.2) end
        assert(_mock.calls.deathRecords == baselineQueries, "Meter polled during combat restrictions")
    """)
    lua, _, _ = fresh_addon(paths, setup=TARGET)
    lua.execute(r"""
        local u, bar = _mock.units.raid40, _mock.bar()
        addon.window:Hide()
        local healthQueries = _mock.calls.health
        u.percent = 0.4; _mock.tick(0.2)
        assert(_mock.calls.health - healthQueries == 1, "Hidden bar did extra health display queries")
        assert(bar.value == 1 and #_mock.sounds == 1, "Hidden bar lost sound monitoring or redrew itself")
        addon.ApplyOptions({sound=false})
        healthQueries = _mock.calls.health
        u.percent = _mock.secret(0.02); _mock.tick(0.2)
        assert(_mock.calls.health == healthQueries, "Silent hidden bar kept querying health")
        addon.window:Show()
        assert(issecretvalue(bar.value) and bar.fonts[1].text == "2%", "Showing bar did not refresh latest health")
        local curves = _mock.calls.curves
        addon.ApplyOptions({width=1200,flashFade=1.2})
        assert(_mock.calls.curves == curves, "Size/fade-only change rebuilt health curves")
        addon.ApplyOptions({thresholds={60,35,10}})
        assert(_mock.calls.curves > curves, "Threshold changes did not refresh display curves")
    """)
    print("PASS: idle scans/meter queries throttled, hidden display work skipped and curves cached")


def check_deaths(paths):
    lua, _, _ = fresh_addon(paths, setup=TARGET)
    lua.execute(r"""
        local u = _mock.units.raid40
        u.combat = true; _mock.combat = true; _mock.tick(0.2)
        _mock.tick(4); _mock.sessionDuration = 4.2
        u.dead = true; u.combat = false; _mock.tick(0.2)
        assert(select(1, addon.GetCounters()) == 1, "Observed death counter was not incremented")
        _mock.tick(2); assert(#_mock.chat == 0)
        assert(select(1, addon.GetCounters()) == 1, "Repeated dead observations incremented the death counter")
        -- An early raid death must survive a boss fight longer than two minutes.
        _mock.combat, _mock.locked = false, true; _mock.step(130); assert(#_mock.chat == 0)
        _mock.currentMeter.combatSources = {{name="Dr Enkel",sourceGUID="target-1",deathRecapID=7,deathTimeSeconds=4.2}}
        _mock.recaps[7] = {{event="SPELL_DAMAGE",spellName="Floor Inspection",sourceName="Boss",hideCaster=false}}
        _mock.locked = false; _mock.step(1)
        assert(#_mock.chat == 2 and _mock.chat[1].channel == "RAID" and _mock.chat[2].channel == "GUILD")
        assert(_mock.chat[1].message:find("Floor Inspection", 1, true))
        assert(_mock.chat[1].message:find("4.2s", 1, true), _mock.chat[1].message)
        _mock.step(10); assert(#_mock.chat == 2, "Duplicate death reports")
        u.dead = false; _mock.tick(0.2)
        _mock.units.raid5, _mock.units.raid40 = u, nil
        _mock.fire("GROUP_ROSTER_UPDATE"); _mock.tick(0.2)
        assert(_mock.bar().value == 1, "Roster reorder lost identity")
        u.combat = true; _mock.tick(0.2); _mock.tick(1); u.dead = true; _mock.tick(0.2)
        assert(select(1, addon.GetCounters()) == 2, "Resurrection did not rearm observed death counter")
        _mock.step(5); assert(#_mock.chat == 4, "Resurrection did not rearm tracking")
        assert(not _mock.chat[3].message:find("Floor Inspection", 1, true), "Old recap reused")
    """)
    print("PASS: observed combat duration, death deduplication, deferred raid/guild chat and recap reuse guard")


def check_untrusted_recaps(paths):
    # Each case observes a real transition, but the native recap must be rejected.
    for records, recap in [
        ('{{name="Dr Enkel",sourceGUID="somebody-else",deathRecapID=7,deathTimeSeconds=20}}',
         '{{event="SPELL_DAMAGE",spellName="Wrong killer"}}'),
        ('{{name="Dr Enkel",sourceGUID="target-1",deathRecapID=7,deathTimeSeconds=2}}',
         '{{event="SPELL_DAMAGE",spellName="Stale killer"}}'),
        ('{{name="Dr Enkel",sourceGUID="target-1",deathRecapID=7,deathTimeSeconds=20},'
         '{name="Dr Enkel",sourceGUID="target-1",deathRecapID=8,deathTimeSeconds=20}}',
         '{{event="SPELL_DAMAGE",spellName="Ambiguous killer"}}'),
        ('{{name="Dr Enkel",sourceGUID="target-1",deathRecapID=7,deathTimeSeconds=20}}',
         '{{event="SPELL_DAMAGE",spellName=_mock.secret("Hidden killer")}}'),
    ]:
        lua, _, _ = fresh_addon(paths, setup=TARGET)
        lua.execute(r"""
            _mock.sessionDuration = 20
            _mock.units.raid40.combat = true; _mock.tick(0.2)
            _mock.units.raid40.dead = true; _mock.tick(0.2)
        """)
        lua.execute("_mock.currentMeter.combatSources = " + records)
        lua.execute("_mock.recaps[7] = " + recap)
        lua.execute(r"""
            _mock.step(5)
            assert(#_mock.chat == 2)
            assert(_mock.chat[1].message:find("unavailable cause", 1, true), _mock.chat[1].message)
        """)
    print("PASS: mismatched, stale, ambiguous and secret recaps never invent a killing blow")


def check_message_budget(paths):
    setup = TARGET + '_mock.units.raid40.name = string.rep("Å", 40); _mock.units.raid40.surname = nil'
    lua, _, _ = fresh_addon(paths, '{targetName=string.rep("Å",40)}', setup)
    lua.execute(r"""
        local u = _mock.units.raid40
        u.combat = true; _mock.tick(0.2); _mock.tick(99)
        _mock.sessionDuration = 99
        u.dead = true; _mock.tick(0.2)
        _mock.currentMeter.combatSources = {{name=u.name,sourceGUID="target-1",deathRecapID=9,deathTimeSeconds=99}}
        _mock.recaps[9] = {{event="SPELL_DAMAGE",spellName=string.rep("Ö",80),sourceName="Boss",hideCaster=false}}
        _mock.step(5)
        assert(#_mock.chat == 2 and _mock.chat[1].message == _mock.chat[2].message)
    """)
    message = lua.globals()._mock.chat[1].message
    assert len(message.encode("utf-8")) <= 255
    assert "unavailable" in message and "Floor inspector: shift complete." in message
    print("PASS: long UTF-8 names/causes preserve the complete report within chat byte limits")


def check_observation_boundaries(paths):
    lua, _, _ = fresh_addon(paths, setup=TARGET + "_mock.units.raid40.combat = true")
    lua.execute(r"""
        _mock.tick(2); _mock.units.raid40.dead = true; _mock.tick(0.2); _mock.step(5)
        assert(#_mock.chat == 2 and _mock.chat[1].message:find("2.2s+ observed combat", 1, true))
    """)
    lua, _, _ = fresh_addon(paths, setup=TARGET + "_mock.units.raid40.dead = true")
    lua.execute("_mock.step(10); assert(#_mock.chat == 0, 'Already-dead unit announced')")
    lua, _, _ = fresh_addon(paths, setup=TARGET)
    lua.execute(r"""
        local u = _mock.units.raid40
        u.combat = true; _mock.tick(0.2); u.dead = true; _mock.tick(0.2); _mock.step(5)
        u.dead = false; _mock.tick(0.2); _mock.tick(2); u.dead = true; _mock.tick(0.2); _mock.step(5)
        assert(#_mock.chat == 4)
        assert(_mock.chat[3].message:find("2.2s observed combat", 1, true), "Resurrection reused earlier timer")
    """)
    lua, _, _ = fresh_addon(paths, setup=TARGET)
    lua.execute(r"""
        SlashCmdList.MYFOREVERADDON("test 5")
        _mock.units.raid40.combat, _mock.units.raid40.dead = true, true
        _mock.step(10); assert(#_mock.chat == 0, "Demo sent a death report")
        SlashCmdList.MYFOREVERADDON("live"); _mock.step(10); assert(#_mock.chat == 0)
        _mock.units.raid40.dead = _mock.secret(true)
        _mock.units.raid40.combat = _mock.secret(true)
        _mock.fire("UNIT_NAME_UPDATE", _mock.secret("raid40")); _mock.step(2)
        assert(#_mock.chat == 0, "Restricted death/combat flag produced report")
    """)
    # While chat is restricted, a burst is bounded to five pending reports.
    lua, _, _ = fresh_addon(paths, setup=TARGET)
    lua.execute(r"""
        local u = _mock.units.raid40; _mock.locked = true
        for i = 1, 6 do
            u.dead, u.combat = false, true; _mock.tick(0.2)
            u.dead = true; _mock.tick(0.2)
        end
        assert(#_mock.chat == 0); _mock.locked = false; _mock.step(30)
        assert(#_mock.chat == 10, "Pending report queue exceeded five deaths")
    """)
    lua, _, _ = fresh_addon(paths, setup=TARGET)
    lua.execute(r"""
        _mock.locked = true; _mock.units.raid40.dead = true; _mock.tick(0.2)
        _mock.tick(601); _mock.locked = false; _mock.step(5)
        assert(#_mock.chat == 0, "Expired report was sent")
    """)
    print("PASS: partial/already-dead observation, demo isolation, restricted flags, queue bound and expiry")


def main():
    paths = manifest_files()
    compiler = LuaRuntime()
    lua_files = sorted((ROOT / ADDON_NAME).glob("*.lua")) + sorted((ROOT / "editor").glob("*.lua"))
    for path in lua_files:
        compiler.execute("assert(loadstring(...))", path.read_text(encoding="utf-8"))
    print(f"PASS: TOC load order/editor isolation; Lua 5.1 syntax ({len(lua_files)} files)")
    _, members = release_package.manifest()
    archive_names = [name for name, _ in members]
    assert f"{ADDON_NAME}/{ADDON_NAME}.toc" in archive_names
    assert f"{ADDON_NAME}/Media/alarm.mp3" in archive_names, "Default alarm is missing from the installable package"
    assert not any(name.startswith("MyForeverAddon/") for name in archive_names)
    print("PASS: release layout uses the renamed addon folder and matching manifest")
    check_defaults(paths)
    check_commands(paths)
    check_options_validation(paths)
    check_options_panel(paths)
    check_health(paths)
    check_audio(paths)
    check_audio_health_events(paths)
    check_audio_idle_and_logout(paths)
    check_audio_options(paths)
    check_health_commentary(paths)
    check_own_counters(paths)
    check_peer_counters(paths)
    check_peer_sending(paths)
    check_idle_work(paths)
    check_deaths(paths)
    check_untrusted_recaps(paths)
    check_message_budget(paths)
    check_observation_boundaries(paths)
    print("Mocks do not verify WoW rendering, actual secrecy, chat delivery or disk persistence.")


if __name__ == "__main__":
    main()
