---@meta
-- Minimal editor-only subset of the Forever UI API used by this addon.
-- These declarations are not implementations and are never loaded by WoW.
-- Verified against Blizzard's exported forever branch (1.60.1.70888):
-- https://github.com/Gethe/wow-ui-source/tree/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated

---@alias MyForeverAddonAnchor "TOPLEFT"|"TOP"|"TOPRIGHT"|"LEFT"|"CENTER"|"RIGHT"|"BOTTOMLEFT"|"BOTTOM"|"BOTTOMRIGHT"

---@class MyForeverAddonRegion
local Region = {}

---@param point MyForeverAddonAnchor
---@param relativeTo MyForeverAddonRegion
---@param relativePoint MyForeverAddonAnchor
---@param offsetX number
---@param offsetY number
function Region:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY) end

function Region:ClearAllPoints() end

---@return number? x
---@return number? y
function Region:GetCenter() end

---@param relativeTo? MyForeverAddonRegion Defaults to the parent.
function Region:SetAllPoints(relativeTo) end

---@param height number
function Region:SetHeight(height) end

---@param alpha number May be secret; never read the resulting alpha to infer HP.
function Region:SetAlpha(alpha) end

---@return MyForeverAddonAnimationGroup
function Region:CreateAnimationGroup() end

---@class MyForeverAddonFontString: MyForeverAddonRegion
local FontString = {}

---@param text string
function FontString:SetText(text) end

---@param format string
---@param ... any The native formatter accepts secret display values.
function FontString:SetFormattedText(format, ...) end

---@param fontFile string
---@param fontSize number
---@param flags? string
---@return boolean success
function FontString:SetFont(fontFile, fontSize, flags) end

---@param alignment "LEFT"|"CENTER"|"RIGHT"
function FontString:SetJustifyH(alignment) end

---@class MyForeverAddonBackdrop
---@field bgFile? string
---@field edgeFile? string
---@field tile? boolean
---@field tileSize? number
---@field edgeSize? number
---@field insets? {left: number, right: number, top: number, bottom: number}

---@class MyForeverAddonFrame: MyForeverAddonRegion
local Frame = {}

---@param width number
---@param height number
function Frame:SetSize(width, height) end

---@param strata string
function Frame:SetFrameStrata(strata) end

---@param clamped boolean
function Frame:SetClampedToScreen(clamped) end

---@param movable boolean
function Frame:SetMovable(movable) end

---@param enabled boolean
function Frame:EnableMouse(enabled) end

---@param ... string Mouse buttons to register.
function Frame:RegisterForDrag(...) end

function Frame:StartMoving() end
function Frame:StopMovingOrSizing() end
function Frame:Show() end
function Frame:Hide() end

---@return boolean
function Frame:IsShown() end

---@param event string
---@return boolean registered
function Frame:RegisterEvent(event) end

---@param event string
---@return boolean unregistered
function Frame:UnregisterEvent(event) end

---@param scriptType string
---@param handler fun(self: MyForeverAddonFrame, ...: any)
function Frame:SetScript(scriptType, handler) end

---@param name? string
---@param drawLayer? string
---@param templateName? string
---@return MyForeverAddonFontString
function Frame:CreateFontString(name, drawLayer, templateName) end

---@param name? string
---@param drawLayer? string
---@param templateName? string
---@param subLevel? number
---@return MyForeverAddonTexture
function Frame:CreateTexture(name, drawLayer, templateName, subLevel) end

-- Backdrop methods come from BackdropTemplate, not an ordinary bare Frame.
---@param backdrop MyForeverAddonBackdrop
function Frame:SetBackdrop(backdrop) end

---@param red number
---@param green number
---@param blue number
---@param alpha? number
function Frame:SetBackdropColor(red, green, blue, alpha) end

---@param frameType string
---@param name? string
---@param parent? MyForeverAddonFrame
---@param templateName? string
---@return MyForeverAddonFrame
---@overload fun(frameType: "StatusBar", name?: string, parent?: MyForeverAddonFrame, templateName?: string): MyForeverAddonStatusBar
---@overload fun(frameType: "Slider", name?: string, parent?: MyForeverAddonFrame, templateName?: string): MyForeverAddonSlider
---@overload fun(frameType: "Button", name?: string, parent?: MyForeverAddonFrame, templateName?: string): MyForeverAddonButton
---@overload fun(frameType: "CheckButton", name?: string, parent?: MyForeverAddonFrame, templateName?: string): MyForeverAddonCheckButton
function CreateFrame(frameType, name, parent, templateName) end

---@class MyForeverAddonButton: MyForeverAddonFrame
local Button = {}

---@param text string
function Button:SetText(text) end

---@class MyForeverAddonCheckButton: MyForeverAddonButton
local CheckButton = {}

---@return boolean
function CheckButton:GetChecked() end

---@param checked boolean
function CheckButton:SetChecked(checked) end

---@class MyForeverAddonSlider: MyForeverAddonFrame
local Slider = {}

---@param orientation "HORIZONTAL"|"VERTICAL"
function Slider:SetOrientation(orientation) end

---@param minimum number Public setting value, not secret health.
---@param maximum number
function Slider:SetMinMaxValues(minimum, maximum) end

---@param step number
function Slider:SetValueStep(step) end

---@param obeyStep boolean
function Slider:SetObeyStepOnDrag(obeyStep) end

---@param texture string
function Slider:SetThumbTexture(texture) end

---@return MyForeverAddonTexture
function Slider:GetThumbTexture() end

---@param value number
function Slider:SetValue(value) end

---@return number
function Slider:GetValue() end

---@type MyForeverAddonFrame
UIParent = {}

---@type table<string, fun(message: string, editBox: MyForeverAddonFrame)>
SlashCmdList = {}

---@class MyForeverAddonStatusBar: MyForeverAddonFrame
local StatusBar = {}

---@param texture string
function StatusBar:SetStatusBarTexture(texture) end

---@param minimum number May be secret.
---@param maximum number May be secret.
function StatusBar:SetMinMaxValues(minimum, maximum) end

---@param value number May be secret; accepted directly by this native widget.
function StatusBar:SetValue(value) end

---@param red number
---@param green number
---@param blue number
---@param alpha? number Components may be secret.
function StatusBar:SetStatusBarColor(red, green, blue, alpha) end

---@class MyForeverAddonTexture: MyForeverAddonRegion
local Texture = {}

---@param width number
---@param height number
function Texture:SetSize(width, height) end

---@param red number
---@param green number
---@param blue number
---@param alpha? number
function Texture:SetColorTexture(red, green, blue, alpha) end

---@class MyForeverAddonAnimationGroup
local AnimationGroup = {}

---@param animationType "Alpha"
---@return MyForeverAddonAlphaAnimation
function AnimationGroup:CreateAnimation(animationType) end

---@param loopType "NONE"|"REPEAT"|"BOUNCE"
function AnimationGroup:SetLooping(loopType) end

function AnimationGroup:Play() end

---@class MyForeverAddonAlphaAnimation
local AlphaAnimation = {}

---@param alpha number
function AlphaAnimation:SetFromAlpha(alpha) end

---@param alpha number
function AlphaAnimation:SetToAlpha(alpha) end

---@param seconds number
function AlphaAnimation:SetDuration(seconds) end

---@class MyForeverAddonCurve
local Curve = {}

---@param curveType number Enum.LuaCurveType value.
function Curve:SetType(curveType) end

---@param x number
---@param y number
function Curve:AddPoint(x, y) end

---@param x number Public demo input only; real HP uses UnitHealthPercent with this curve.
---@return number
function Curve:Evaluate(x) end

C_CurveUtil = {}
---@return MyForeverAddonCurve
function C_CurveUtil.CreateCurve() end

---@type { LuaCurveType: { Step: number }, DamageMeterSessionType: { Current: number }, DamageMeterType: { Deaths: number }, RegisterAddonMessagePrefixResult: { Success: number, DuplicatePrefix: number }, SendAddonMessageResult: { Success: number } }
Enum = {}

---@type { RAID_WARNING: number }
SOUNDKIT = {}

---@type string
STANDARD_TEXT_FONT = ""

C_Sound = {}
---@param options { soundKitID: number }
---@return boolean? success A playback request may return no result.
---@return number? soundHandle
function C_Sound.PlaySoundWithOptions(options) end

---@param soundHandle number A handle returned by this addon's own playback request.
---@return boolean
function C_Sound.IsPlaying(soundHandle) end

---@param path string Relative client path, including Interface/AddOns.
---@param channel? "Master"|"SFX"|"Music"|"Ambience"|"Dialog"
---@return boolean? accepted A request being accepted does not prove audible playback.
---@return number? soundHandle
function PlaySoundFile(path, channel) end

---@param soundHandle number A handle returned by this addon's own playback request.
---@param fadeoutMilliseconds? number Zero stops without a fade.
function StopSound(soundHandle, fadeoutMilliseconds) end

---@param value any
---@return boolean
function issecretvalue(value) end

---@param unit string
---@return boolean
function UnitExists(unit) end

---@param unit string
---@param usePredicted? boolean
---@param curve? MyForeverAddonCurve
---@return number Health fraction (0-1), or curve output. May be secret.
function UnitHealthPercent(unit, usePredicted, curve) end

-- Group/death tracking subset. Values from the unit and native meter APIs may
-- be secret even when annotated with an ordinary Lua type; guard before reading.
---@param unit string
---@return string? firstName
---@return string? surname Forever's second return is a surname, not a realm.
function UnitName(unit) end

---@param unit string
---@return string? guid May be secret.
function UnitGUID(unit) end

---@param unit string
---@return boolean
function UnitIsPlayer(unit) end

---@param unit string
---@return boolean
function UnitIsConnected(unit) end

---@param unit string
---@return boolean
function UnitIsDeadOrGhost(unit) end

---@param unit string
---@return boolean
function UnitAffectingCombat(unit) end

---@return boolean
function IsInGroup() end
---@return boolean
function IsInRaid() end
---@return boolean
function IsInGuild() end
---@return boolean
function InCombatLockdown() end
---@return number seconds
function GetTime() end

---@type { CharacterNameSeparatorConsts: { CHARACTERNAME_SURNAME_SEPARATOR: string } }
Constants = {}

C_ChatInfo = {}
---@return boolean
function C_ChatInfo.InChatMessagingLockdown() end

---@param message string At most 255 bytes.
---@param chatType "RAID"|"GUILD"
function C_ChatInfo.SendChatMessage(message, chatType) end

---@class MyForeverAddonDeathSource
---@field name? string
---@field sourceGUID? string
---@field deathRecapID? number
---@field deathTimeSeconds? number Session clock, not individual combat duration.

---@class MyForeverAddonDeathSession
---@field combatSources MyForeverAddonDeathSource[]

C_DamageMeter = {}
---@return boolean
function C_DamageMeter.IsDamageMeterAvailable() end

---@param sessionType number
---@param meterType number
---@return MyForeverAddonDeathSession?
function C_DamageMeter.GetCombatSessionFromType(sessionType, meterType) end

---@param sessionType number
---@return number? durationSeconds
function C_DamageMeter.GetSessionDurationSeconds(sessionType) end

---@class MyForeverAddonRecapEvent
---@field event? string
---@field spellName? string
---@field environmentalType? string
---@field sourceName? string
---@field hideCaster? boolean

C_DeathRecap = {}
---@param recapID number
---@return MyForeverAddonRecapEvent[]?
function C_DeathRecap.GetRecapEvents(recapID) end

---@class MyForeverAddonSpellInfo
---@field spellID number
---@field name string

C_Spell = {}
---@param spellIdentifier number|string
---@return MyForeverAddonSpellInfo? Metadata must be accessible before comparisons.
function C_Spell.GetSpellInfo(spellIdentifier) end

---@param prefix string
---@return number Enum.RegisterAddonMessagePrefixResult.
function C_ChatInfo.RegisterAddonMessagePrefix(prefix) end

---@return boolean Realm-level restriction; clearing combat alone does not permit comms.
function C_ChatInfo.AreOutgoingAddonChatMessagesRestricted() end

---@param prefix string
---@param message string Public data only.
---@param chatType "RAID"|"PARTY"
---@return number Enum.SendAddonMessageResult.
function C_ChatInfo.SendAddonMessage(prefix, message, chatType) end
