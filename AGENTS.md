# Development conventions

- Target World of Warcraft: Forever with Lua 5.1-compatible syntax and native UI
  frames created in Lua. No Java build, Ace3, or other runtime dependencies until
  a concrete feature needs them.
- Preserve existing user files. Runtime code belongs in `EnhancedJackfockHealthBar/`; its
  TOC lists files explicitly in dependency order: Namespace, Audio, Window,
  Tracker, Counters, Options, Core.
- Use WoW's private `local addonName, addon = ...` table across files. Keep frames
  anonymous and helpers local. Only the declared SavedVariables global and WoW
  slash-command registration should add globals.
- Initialize saved data only after the matching `ADDON_LOADED`. Preserve valid
  values and unrelated keys; validate persistent data before using it. Create
  the window once and reuse it.
- Keep annotations readable. Editor-only definitions belong in `editor/`, which
  must never enter the TOC. EmmyLua2 uses root `.emmyrc.json`, `Lua5.1`, and an
  editor library path; verify its current schema before changing configuration.
- Verify new APIs and restrictions in current Forever primary sources. Do not
  assume Retail or Classic compatibility. Record build/version evidence and
  uncertainty in `docs/COMPATIBILITY.md`; keep README focused on downloading,
  installing and using Enhanced Jackfock Health Bar. Confirm interface changes
  with in-game `GetBuildInfo()`.
- Never calculate, compare or branch on secret health; send it only through
  sanctioned native curves/display APIs. Do not infer health by reading widgets,
  drive sounds from secret alpha, or register restricted combat-log events.
- Track the exact Forever full name in the party/raid. Label observed combat time
  honestly; never invent swing counts, available defenses, potion counts or a
  killing blow. Use only a new unambiguous native recap after restrictions lift.
- Gate raid/guild reports on combat and chat lockdown, deduplicate transitions,
  expire bounded queues, and never send announcements from local demo mode.
- Keep options as drafts until Apply; validate atomically and copy threshold
  arrays. Keep settings and preview controls independent of secret unit data.
- Throttle missing-member roster scans and idle recap baselines. Keep death
  observation responsive and refresh the display when the user shows the window.
- Keep the health frame clean: HP, one native-alpha commentary line and counters.
  Put demo/help/status instructions in Options or chat. Own-client Whirlwind
  counters must use readable successful cast events; sync only when the realm
  permits addon messages. Never use visible chat as a blocked-transport workaround.
- Keep the alarm handle owned and stoppable: only readable HP in (0, 50%] may
  start it; healed, dead, missing or secret HP stops it with no fade. Never drive
  sound from secret display alpha. Check native completion for repeat playback,
  keep explicit previews separate, and back off after playback failures.
- Run `python tools/check.py` for manifest, Lua 5.1 and mocked lifecycle checks
  (dev dependency: Lupa 2.6). Keep `.tools/` out of addon packages.
- Real testing is inside Forever: enable `/console scriptErrors 1`, reload,
  toggle/drag/close the window, and verify position after reload and full restart.
  Report local checks separately from in-game tests; do not claim IDE debugging
  attaches to WoW.
- Build releases with `python tools/package.py`. Ship the original cover PNG in
  Media, bundled alarm and player screenshots; exclude editor files, local tools and IDE
  state. Keep the folder and TOC basename `EnhancedJackfockHealthBar`. Preserve
  the existing `MyForeverAddonDB` saved-variable name for settings compatibility.
