-- WoW passes the same private table to every Lua file in this addon's TOC.
local addonName, addon = ...
---@cast addonName string
---@cast addon MyForeverAddon

addon.name = addonName
addon.title = "Enhanced Jackfock Health Bar"

---@param message string
function addon.Print(message)
    print("|cff33ccff" .. addon.title .. ":|r " .. message)
end
