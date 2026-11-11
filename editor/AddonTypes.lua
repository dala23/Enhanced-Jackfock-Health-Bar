---@meta
-- Editor-only annotations. This directory must never appear in the WoW TOC.

---@class MyForeverAddonPosition
---@field x number Offset from UIParent's center, in UI units.
---@field y number Offset from UIParent's center, in UI units.

---@class MyForeverAddonDatabase
---@field windowPosition MyForeverAddonPosition
---@field targetName string Exact Forever first name and surname.
---@field width number Window width in UI units.
---@field height number Window height in UI units.
---@field thresholds number[] Three descending percentages; warnings apply below each.
---@field sound boolean
---@field soundFile string Filename in Media; empty selects the built-in sound.
---@field flash boolean
---@field announceRaid boolean
---@field announceGuild boolean
---@field flashStrength number Flash opacity multiplier, from 0 to 1.
---@field flashFade number Seconds per pulse fade, from 0.3 to 2.
---@field counters? table<string, MyForeverAddonCounters> Counts keyed by normalized watched full name.

---@class MyForeverAddonCounters
---@field deaths number Observed deaths on this installation.
---@field whirlwinds number Successful local casts or a verified peer snapshot.
---@field whirlwindsUnknown? boolean An opaque local cast made the historical tally incomplete.

---@class MyForeverAddon
---@field name string
---@field title string User-facing addon title.
---@field db MyForeverAddonDatabase Available after our ADDON_LOADED event.
---@field window? MyForeverAddonFrame
---@field CreateWindow fun()
---@field ToggleWindow fun()
---@field ApplyWindowSettings fun()
---@field UpdateHealth fun(unit?: string)
---@field ShowDeath fun(message: string, silent?: boolean)
---@field TestWindow fun(percent?: number)
---@field testing? boolean Local visual demo; tracker must not announce while true.
---@field Print fun(message: string)
---@field StartTracking fun()
---@field ResetTracking fun()
---@field GetUnitDisplayName fun(unit: string): string?
---@field optionsWindow? MyForeverAddonFrame
---@field ToggleOptions fun()
---@field RefreshOptions fun()
---@field ApplyOptions fun(settings: MyForeverAddonOptions): boolean, string?
---@field SetDemo fun(percent?: number)
---@field PreviewSound fun(filenameOverride?: string): boolean, string
---@field NormalizeSoundFile fun(value: any): string?, string?
---@field StartAudio fun()
---@field UpdateAlarm fun(fraction?: number) Stops on unavailable or secret HP.
---@field StopAlertSound fun(suppressUntilRecovery?: boolean)
---@field CenterWindow fun()
---@field StartCounters fun()
---@field RecordDeath fun()
---@field GetCounters fun(): number, number?, boolean Third result marks a cached peer snapshot; nil Whirlwinds is unknown.
---@field UpdateCounters? fun()

---@class MyForeverAddonOptions
---@field width? number
---@field height? number
---@field thresholds? number[]
---@field sound? boolean
---@field soundFile? string
---@field flash? boolean
---@field announceRaid? boolean
---@field announceGuild? boolean
---@field flashStrength? number
---@field flashFade? number

---@type MyForeverAddonDatabase|nil
MyForeverAddonDB = nil

---@type string
SLASH_MYFOREVERADDON1 = "/myforeveraddon"
