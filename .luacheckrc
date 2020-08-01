-- luacheck: ignore
std = "lua51"
max_line_length = false
exclude_files = {".luacheckrc", ".luaformat"}
ignore = {
    "211", -- Unused local variable
    "212", -- Unused argument
}
globals = {}
read_globals = {
    "ColorPickerFrame", --
    "CreateFrame", --
    "DISABLED_FONT_COLOR", --
    "GameTooltip", --
    "GetLocale", --
    "HIGHLIGHT_FONT_COLOR", --
    "InCombatLockdown", --
    "InterfaceAddOnsList_Update", --
    "InterfaceOptionsFrame", --
    "InterfaceOptionsFrame_OpenToCategory", --
    "InterfaceOptions_AddCategory", --
    "IsAltKeyDown", --
    "LibStub", --
    "NORMAL_FONT_COLOR", --
    "OpacitySliderFrame", --
    "OptionsListButtonToggle_OnClick", --
    "PlaySound", --
    "SOUNDKIT", --
    "format", --
    "geterrorhandler", --
    "strlen", --
    "strsplit", --
    "tremove", --
    "wipe", --
}
