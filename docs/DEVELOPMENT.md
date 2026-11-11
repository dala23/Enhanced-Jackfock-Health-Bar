# Development

Use plain Lua compatible with WoW's embedded Lua 5.1 runtime and native frames.
The addon has no runtime libraries. Keep helpers local and use the private addon
table passed through `...`; the saved-variable name and slash registration are
the only addon globals.

## IntelliJ IDEA and EmmyLua2

Open the repository root in IntelliJ IDEA. Install **EmmyLua2**, by CppCXY, from
Settings > Plugins > Marketplace. Release **0.24.0.115-IDEA262** supports IntelliJ
builds 261.0-262.*, including IDEA 2026.2.1. Restart if the IDE requests it.
Avoid enabling the older EmmyLua language plugin alongside EmmyLua2.
[Verified Marketplace release](https://plugins.jetbrains.com/plugin/25076-emmylua2/versions/stable/1121133).

Root `.emmyrc.json` uses the analyzer's exact `Lua5.1` runtime value,
`EnhancedJackfockHealthBar` as the workspace root and `editor` as an annotation library.
Automatic `require` insertion is disabled because WoW loads files from the TOC.
Configuration follows the [0.24.0 guide](https://github.com/EmmyLuaLs/emmylua-analyzer-rust/blob/0.24.0/docs/config/emmyrc_json_EN.md)
and [schema](https://raw.githubusercontent.com/EmmyLuaLs/emmylua-analyzer-rust/0.24.0/crates/emmylua_code_analysis/resources/schema.json).

## Layout

- `EnhancedJackfockHealthBar/`: shipped Lua, manifest and release artwork.
- `editor/`: editor-only namespace and API annotations; never add these to the TOC.
- `tools/check.py`: Lua 5.1 syntax and mocked behavior checks.
- `tools/package.py`: builds the installable archive in ignored `dist/`.
- `docs/COMPATIBILITY.md`: primary API evidence and restrictions.

Load order is Namespace, Audio, Window, Tracker, Counters, Options, Core. Initialize saved data
only on the matching `ADDON_LOADED`. Validate an entire settings draft before
writing it. Keep demo mode isolated from real tracking and announcements.

The supplied cover is `EnhancedJackfockHealthBar/Media/AddonImage.png`, unchanged from the
provided image. Use it for the release/download listing. It is not loaded as an
in-game texture. The public title is **Enhanced Jackfock Health Bar**; retain
`EnhancedJackfockHealthBar` as the installation folder/TOC basename. The existing
`MyForeverAddonDB` global and slash registration remain for settings compatibility.

## Check and package

```powershell
python -m pip install --target .tools/python lupa==2.6
python tools/check.py
python tools/package.py
```

Lupa is used only for local checks, with its Lua 5.1 backend. It is not packaged.
Checks cover settings validation, options drafts, secret-value display, name
matching, timing, report deduplication/expiry and reduced idle work. The package
contains the addon folder with `Media/alarm.mp3`, player screenshots, README and compatibility notes, without IDE
files, local tools or test dependencies.

Actual testing happens inside Forever. An ordinary IDE run configuration does
not supply WoW's frames or events, and standard Lua debugging may not attach to
the game. Copy the addon into the client, enable `/console scriptErrors 1`, and
use `/reload` while changing Lua. Restart when installing a new manifest/file.
Test options, demo/resume, size/position persistence, secret health in combat,
and a real grouped death followed by deferred chat delivery. The default frame
is 420 x 290; keep valid saved sizes. Audio repeats only while public HP is in
(0, 50%], stops without fade on recovery/unknown HP, and uses native playback
state rather than a guessed file length. Manual previews are independent.
Mocks cannot verify
client rendering, actual restrictions, native recap population or disk loading.

New loose audio filenames require a full client restart. Test actual playback
of the bundled MP3 inside Forever; accepted playback is not proof of audibility.

Before publishing, run the checks and package builder, review the tracked file
list, then upload the named ZIP as a release asset. Use the provided PNG as the
release cover. Preserve existing repository work and do not commit `.tools`,
`dist`, credentials or personal IDE state.
