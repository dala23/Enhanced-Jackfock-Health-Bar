# Forever compatibility

This addon targets **World of Warcraft: Forever**, interface **16001**.
The verified API snapshot is Blizzard's exported UI for **1.60.1.70888**,
[commit 4cd0ab7](https://github.com/Gethe/wow-ui-source/commit/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe)
on Gethe's `forever` mirror. This is Blizzard source hosted by a third party,
not a promise that Retail or Classic examples work in Forever.

The [firsthand KethoDoc dump](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/README.md)
records `GetBuildInfo()` returning interface 16001 for Forever 1.60.1.70532,
with Mainline family and Camelot game type. The locally installed product is
`wowf`, build 1.60.1.70888. Its exact fourth `GetBuildInfo()` return has not been
captured in-game. If a patch changes compatibility, obtain that full output
before updating the TOC; changing a number does not establish API compatibility.

## Primary API evidence

All source links below are pinned to the same Forever export.

- [Unit APIs](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua)
  document health secrecy, native curve evaluation, and public death/combat flags.
  [Camelot name handling](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/NameUtil.lua)
  uses first name and surname instead of Retail's name/realm convention.
- [Status bars](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleStatusBarAPIDocumentation.lua)
  accept secret display values. [Numeric curves](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_APIDocumentationGenerated/LuaCurveObjectAPIDocumentation.lua)
  configure public display mappings. Real health is evaluated through native
  `UnitHealthPercent` and passed straight to widgets, never inspected in Lua.
  [Sound playback](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_APIDocumentationGenerated/SoundDocumentation.lua)
  cannot be driven by inspecting secret health or secret display opacity.
  `C_Sound.IsPlaying` checks actual owned playback state for repeating the alarm.
  [Forever's API dump](https://github.com/Ketho/BlizzardInterfaceResources/blob/forever/Resources/GlobalAPI.lua)
  and [firsthand custom-file playback](https://github.com/xIGBClutchIx/ForeverPlusPlus/blob/76bcfd777dedbb2dc098e18349f725d409209007/ForeverPlusPlus_AgentChat/AgentChat.lua)
  verify global `PlaySoundFile(path, "Master")` and `StopSound`. The addon uses
  zero fade and never invents completion-callback arguments or file duration.
  [Firsthand Forever tests](https://github.com/xIGBClutchIx/ForeverPlusPlus/blob/76bcfd777dedbb2dc098e18349f725d409209007/docs/forever-api.md)
  show that new filenames need full restart and an accepted request can still be
  inaudible. MP3/OGG filenames are accepted by the settings form; actual decoding
  and audible output still require client testing.
- [Damage meter](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_APIDocumentationGenerated/DamageMeterDocumentation.lua)
  exposes death recap IDs and a session clock, but no weapon-swing count.
  [Blizzard's recap UI](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_DeathRecap/Mainline/Blizzard_DeathRecap.lua)
  identifies entry 1 as the killing blow. This addon requires a new, unique,
  accessible ID with matching identity and session time; otherwise cause is unknown.
- [Chat](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua),
  [protected actions](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_APIDocumentationGenerated/RestrictedActionsDocumentation.lua)
  and [secret predicates](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_APIDocumentationGenerated/SecretPredicatesDocumentation.lua)
  define messaging/combat restrictions. Reports wait rather than bypass them.
- [Swing events](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_APIDocumentationGenerated/SwingTimerDocumentation.lua),
  [spell cooldowns](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua)
  and [inventory](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua)
  describe local-player information. They do not provide another raid member's
  swing count, ready defenses or potion inventory to this addon.
- **Whirlwind companion counter:** Dr Enkel's own installation counts readable
  `UNIT_SPELLCAST_SUCCEEDED` events for `player`, resolving `Whirlwind` through
  the native spell lookup rather than assuming a Retail spell ID. Other clients
  use only a validated snapshot received from his grouped full name. The
  [chat API](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua)
  documents a realm-level outgoing addon-message restriction as well as combat
  messaging lockdown. Installing on both clients does not guarantee transport.
  Sends require all restrictions to be clear; there is no visible-chat fallback.
  A remote total is explicitly a cached snapshot, not a guaranteed live count.
- [SharedXML load order](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_SharedXML/Blizzard_SharedXML.toc),
  [slider API](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleSliderAPIDocumentation.lua),
  [checkbox API](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleCheckboxAPIDocumentation.lua)
  and [checkbox artwork](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_SharedXML/Shared/Button/CheckButtonTemplates.xml)
  verify the native controls used by the options panel.
- [Addon loading](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_APIDocumentationGenerated/AddOnsDocumentation.lua),
  [slash registry](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_ChatFrameBase/Shared/SlashCommandsRegistry.lua)
  and [error popups](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_ScriptErrorsFrame/Blizzard_ScriptErrorsFrame.lua)
  support the manifest, private namespace, events and development commands.

## Validation limits

Lua 5.1 syntax and mocked behavior checks cover settings, secret-value handling,
owned audio handles, report correlation, deferred messages and reduced idle work.
The supplied screenshots show the health display and options in Forever. Actual
audible MP3 playback, cross-client transport, native recaps, chat delivery and
persistence across a full game restart still require client testing.
