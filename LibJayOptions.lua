local MAJOR = "LibJayOptions"
local MINOR = 1

assert(LibStub, format("%s requires LibStub.", MAJOR))

local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end

local safecall, xsafecall
do -- safecall, xsafecall
    local pcall = pcall
    ---@param func function
    ---@return boolean retOK
    safecall = function(func, ...) return pcall(func, ...) end

    local geterrorhandler = geterrorhandler
    ---@param err string
    ---@return function handler
    local function errorhandler(err) return geterrorhandler()(err) end

    local xpcall = xpcall
    ---@param func function
    ---@return boolean retOK
    xsafecall = function(func, ...) return xpcall(func, errorhandler, ...) end
end

local tnew, tdel
do -- tnew, tdel

    local cache = setmetatable({}, {__mode = "k"})

    local next = next
    local select = select
    ---@return table t
    function tnew(...)
        local t = next(cache)
        if t then
            cache[t] = nil
            local n = select("#", ...)
            for i = 1, n do t[i] = select(i, ...) end
            return t
        end
        return {...}
    end

    local wipe = wipe
    ---@param t table
    function tdel(t) cache[wipe(t)] = true end
end

local error = error
local format = format
local pairs = pairs
local tremove = tremove

lib.frame = lib.frame or CreateFrame("Frame")
local frame = lib.frame

frame:Hide()

frame.scrollFrame = frame.scrollFrame or CreateFrame("ScrollFrame", nil, lib.frame, "UIPanelScrollFrameTemplate")
lib.frame.scrollFrame:SetAllPoints()
lib.frame.scrollFrame.scrollBarHideable = true

lib.frame.container = lib.frame.container or CreateFrame("Frame", nil, lib.frame.scrollFrame, "VerticalLayoutFrame")
lib.frame.container.spacing = 0

lib.frame.scrollFrame:SetScrollChild(lib.frame.container)
lib.frame.scrollFrame:SetScript("OnSizeChanged", function(self, width, height)
    local scrollChild = self:GetScrollChild()
    scrollChild.fixedWidth = width - 10
    scrollChild:MarkDirty()
end)
lib.frame.scrollFrame:SetScript("OnUpdate",
                                function(self, elapsed) self.ScrollBar:SetShown(self:GetVerticalScrollRange() ~= 0) end)

local container = lib.frame.container

local LJMixin = LibStub("LibJayMixin")
local acquireControl, releaseControl
do -- Controls
    lib.controls = lib.controls or {}

    lib.controls.mixins = lib.controls.mixins or {}
    lib.controls.versions = lib.controls.versions or {}
    lib.controls.frameTypes = lib.controls.frameTypes or {}
    lib.controls.caches = lib.controls.caches or {}

    local mixins = lib.controls.mixins
    local versions = lib.controls.versions
    local frameTypes = lib.controls.frameTypes
    local caches = lib.controls.caches

    ---@param control table
    ---@return number canUpgrade
    local function canUpgradeControl(control)
        local name, version, frameType = control._NAME, control._VERSION, control._FRAMETYPE

        if versions[name] == version then return 0 end
        if versions[name] >= version then if frameTypes[name] == frameType then return 1 end end
        return -1
    end

    ---@param control table
    ---@return number success
    local function upgradeControl(control)
        local canUpgrade = canUpgradeControl(control)
        if canUpgrade == 1 then LJMixin:Mixin(control, mixins[control.name]) end
        return canUpgrade
    end

    local type = type
    ---@param name string
    ---@param version number
    ---@param frameType string
    function lib:RegisterControl(name, version, frameType)
        if type(name) ~= "string" then
            error(format("Usage: %s:RegisterControl(name, version, frameType): 'name' - string expected got %s", MAJOR,
                         type(name)), 2)
        end
        if type(version) ~= "number" then
            error(format("Usage: %s:RegisterControl(name, version, frameType): 'version' - number expected got %s",
                         MAJOR, type(version)), 2)
        end
        if type(frameType) ~= "string" then
            error(format("Usage: %s:RegisterControl(name, version, frameType): 'frameType' - string expected got %s",
                         MAJOR, type(frameType)), 2)
        end

        local oldVersion = versions[name]
        if oldVersion and oldVersion >= version then return end

        local mixin = {_NAME = name, _VERSION = version, _FRAMETYPE = frameType}

        mixins[name] = mixin
        versions[name] = version
        frameTypes[name] = frameType

        local cache = caches[name]
        if cache then
            local i = 0
            while true do
                i = i + 1
                if i <= #cache then
                    if upgradeControl(cache[i]) == -1 then
                        tremove(cache, i)
                        i = i - 1
                    end
                else
                    break
                end
            end
        end

        return mixin, oldVersion
    end

    ---@param name string
    ---@return boolean isRegistered
    local function isControlRegistered(name) if mixins[name] then return true end end

    ---@param name string
    ---@return table control
    function acquireControl(name)
        local control
        if type(name) == "string" then
            local cache = caches[name]
            if cache then control = tremove(cache) end
            if not control then
                local mixin, frameType = mixins[name], frameTypes[name]
                if mixin and frameType then
                    control = LJMixin:CreateFrame(frameType, nil, nil, nil, nil, mixin)
                end
            end
        elseif type(name) == "table" then
            control = name
        end
        if control then
            control:SetParent(container)
            control:Show()
            safecall(control.OnAcquire, control)
            safecall(control.Enable, control)

            return control
        end
    end

    ---@param control table
    function releaseControl(control)
        local name = control._NAME

        if name and isControlRegistered(name) then
            if upgradeControl(control) >= 0 then
                caches[name] = caches[name] or {}
                caches[name][#caches[name] + 1] = control
            end
        end

        control:Hide()
        control:SetParent(nil)
        control:ClearAllPoints()
        safecall(control.OnRelease, control)
    end
end

do -- Panels
    local UPDATE_INTERVAL = 0.1
    local LOCKDOWN_ICON = [[Interface\CharacterFrame\UI-StateIcon]]
    local LOCKDOWN_ICON_COORDS = {0.5, 1, 0, 0.5}

    local type = type
    ---@param info table
    ---@param option table
    local function fillInfoPath(info, option)
        if option.parent then fillInfoPath(info, option.parent) end
        if type(option.path) == "table" then
            for i = 1, #option.path do info[#info + 1] = option.path[i] end
        else
            info[#info + 1] = option.path
        end
    end

    ---@param option table
    ---@return table info
    local function getInfo(option)
        local info = tnew()

        info.type = option.type
        info.arg = option.arg
        info.control = option.control

        if option.type == "select" then
            info.isMulti = option.isMulti
        elseif option.type == "color" then
            info.hasAlpha = option.hasAlpha
        end

        fillInfoPath(info, option)

        return info
    end

    local unpack = unpack
    ---@param option table
    ---@param key string
    ---@return any
    local function getOptionValue(option, key, ...)
        local value = option[key]
        if type(value) == "function" then
            local info = getInfo(option)
            local results = {xsafecall(value, info, ...)}
            tdel(info)
            if results[1] then return unpack(results, 2, #results) end
        elseif type(value) == "string" and type(option.handler) == "table" and option.handler[value] then
            local info = getInfo(option)
            local results = {xsafecall(option.handler[value], option.handler, info, ...)}
            tdel(info)
            if results[1] then return unpack(results, 2, #results) end
        end
        return value
    end

    local LJProtectedCall = LibStub("LibJayProtectedCall")
    ---@param option table
    local function setValue(option, ...)
        if getOptionValue(option, "noCombat") then
            LJProtectedCall:Call(getOptionValue, option, "set", ...)
        else
            getOptionValue(option, "set", ...)
        end
    end

    ---@param optionList table
    local function setDefaults(optionList)
        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]

            if option.type == "select" and option.isMulti then
                for k, v in pairs(getOptionValue(option, "values") or tnew()) do
                    setValue(option, k, getOptionValue(option, "default", k))
                end
            elseif option.type == "color" then
                local r, g, b, a = getOptionValue(option, "default")
                if option.hasAlpha then
                    setValue(option, r, g, b, a)
                else
                    setValue(option, r, g, b)
                end
            else
                setValue(option, getOptionValue(option, "default"))
            end

            if option.optionList then setDefaults(option.optionList) end
        end
    end
    ---@param controls table
    local function updateControls(controls)
        local safecall, getOptionValue = safecall, getOptionValue -- luacheck: ignore 431

        local inLockdown = InCombatLockdown()

        for i = 1, #controls do
            local control = controls[i]
            local option = control.option

            safecall(control.PauseUpdates, control)

            local hidden = getOptionValue(option, "hidden") or
                               ((control.parent and not control.parent:IsShown()) or false)
            if hidden and control:IsShown() then
                control:Hide()
                safecall(control.ClearFocus, control)
            elseif not hidden and not control:IsShown() then
                control:Show()
            end

            safecall(control.SetText, control, getOptionValue(option, "text"))

            local optionType = option.type
            if optionType == "boolean" then
                safecall(control.SetValue, control, getOptionValue(option, "get"))
            elseif optionType == "header" then -- luacheck: ignore 542
            elseif optionType == "number" then
                local result, hasFocus = safecall(control.HasFocus, control)
                if (result and not hasFocus) or not result then
                    safecall(control.SetValue, control, getOptionValue(option, "get"))
                end
                safecall(control.SetMinMaxValues, control, getOptionValue(option, "min"), getOptionValue(option, "max"))
                safecall(control.SetIsPercent, control, getOptionValue(option, "isPercent"))
                safecall(control.SetStep, control, getOptionValue(option, "step"))
                safecall(control.SetMinMaxValues, control, getOptionValue(option, "min"), getOptionValue(option, "max"))
                safecall(control.SetMinMaxTexts, control, getOptionValue(option, "minText"),
                         getOptionValue(option, "maxText"))
            elseif optionType == "string" then
                local result, hasFocus = safecall(control.HasFocus, control)
                if (result and not hasFocus) or not result then
                    safecall(control.SetValue, control, getOptionValue(option, "get"))
                end
                safecall(control.SetReadOnly, control, getOptionValue(option, "isReadOnly"))
                safecall(control.SetMaxLetters, control, getOptionValue(option, "maxLetters"))
                safecall(control.SetJustifyH, control, getOptionValue(option, "justifyH") or "LEFT")
                safecall(control.SetMultiLine, control, getOptionValue(option, "isMultiLine"))
            elseif optionType == "select" then
                safecall(control.SetMultiselect, control, option.isMulti)
                local result, hasFocus = safecall(control.HasFocus, control)
                if (result and not hasFocus) or not result then
                    local values = getOptionValue(option, "values")
                    safecall(control.SetValues, control, values)
                    if option.isMulti then
                        for k, v in pairs(values) do
                            safecall(control.SetValue, control, k, getOptionValue(option, "get", k))
                        end
                    else
                        safecall(control.SetValue, control, getOptionValue(option, "get"), true)
                    end
                    safecall(control.SetSortByKeys, control, getOptionValue(option, "sortByKeys"))
                    safecall(control.SetIcons, control, getOptionValue(option, "icons"))
                end
            elseif optionType == "color" then
                local hasAlpha = option.hasAlpha
                safecall(control.SetHasAlpha, control, hasAlpha)
                local r, g, b, a = getOptionValue(option, "get")
                if hasAlpha then
                    safecall(control.SetValue, control, r, g, b, a)
                else
                    safecall(control.SetValue, control, r, g, b)
                end
            end

            if inLockdown and getOptionValue(option, "noCombat") then
                safecall(control.SetEnabled, control, false)
                safecall(control.SetIcon, control, LOCKDOWN_ICON, LOCKDOWN_ICON_COORDS)
            else
                safecall(control.SetEnabled, control, not getOptionValue(option, "disabled"))
                safecall(control.SetIcon, control, getOptionValue(option, "icon"), getOptionValue(option, "iconCoords"))
            end

            safecall(control.ResumeUpdates, control)
        end

        container:MarkDirty()
    end

    local wipe = wipe
    ---@param control table
    ---@param option table
    local function Control_OnValueChanged(option, controls, control, ...)
        local values = {...}
        local set = true
        local info = getInfo(option)

        local onSet = option.onSet
        if type(onSet) == "function" then
            local result = {safecall(onSet, info, ...)}
            if result[1] then
                wipe(values)
                for i = 2, #result do values[#values + 1] = result[i] end
            else
                set = false
            end
            tdel(result)
            --[[ local success, result = safecall(onSet, option.arg, ...)
            if success then
                set = true
                value = result
            else
                set = false
            end ]]
        end

        if set then
            local validate = option.validate
            if type(validate) == "function" then
                local success, result = safecall(validate, info, unpack(values, 1, #values))
                set = (success and result) and true
            end
        end
        tdel(info)

        if set then setValue(option, unpack(values, 1, #values)) end
        tdel(values)
        updateControls(controls)

        if option.type == "select" and option.isMulti then
            local values = getOptionValue(option, "values") -- luacheck: ignore 421
            safecall(control.SetValues, control, values)
            for k, v in pairs(values) do
                safecall(control.SetValue, control, k, getOptionValue(option, "get", k))
            end
        end
    end

    local GameTooltip = GameTooltip
    ---@param option table
    ---@param control table
    ---@param motion boolean
    local function Control_OnEnter(option, control, motion)
        local info = getInfo(option)
        safecall(option.onEnter, info)
        tdel(info)
        local tooltip = getOptionValue(option, "tooltip")
        if tooltip then
            --[[ GameTooltip:SetOwner(control, "ANCHOR_RIGHT") ]]
            GameTooltip:ClearAllPoints()
            GameTooltip:SetPoint("TOPLEFT", control, "TOPRIGHT")
            GameTooltip:SetOwner(control, "ANCHOR_PRESERVE")
            GameTooltip:SetText(getOptionValue(option, "text"))
            GameTooltip:AddLine(tooltip, nil, nil, nil, true)
            GameTooltip:Show()
        end
    end

    ---@param option table
    ---@param control table
    ---@param motion boolean
    local function Control_OnLeave(option, control, motion)
        local info = getInfo(option)
        safecall(option.onLeave, info)
        tdel(info)
        GameTooltip:Hide()
    end

    ---@param control table
    local function Control_OnHeightChanged(control, height) container:MarkDirty() end

    ---@param option table
    local function Control_OnClick(option, ...) getOptionValue(option, "func", ...) end

    ---@param control table
    ---@param option table
    ---@param controls table
    local function Control_RegisterCallbacks(control, option, controls)
        control:RegisterCallback("OnValueChanged", Control_OnValueChanged, option, controls)
        control:RegisterCallback("OnEnter", Control_OnEnter, option)
        control:RegisterCallback("OnLeave", Control_OnLeave, option)
        control:RegisterCallback("OnHeightChanged", Control_OnHeightChanged)
    end

    ---@param optionList table
    ---@param leftPadding number | nil
    ---@param controls table | nil
    ---@return table controls
    local function createControls(optionList, leftPadding, controls)
        leftPadding = leftPadding or 0
        controls = controls or tnew()

        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                local optionType = option.type

                local control

                control = option.control
                if type(control) == "string" then control = acquireControl(control) end

                if not control then
                    if optionType == "boolean" then
                        control = acquireControl("CheckButton")
                    elseif optionType == "header" then
                        control = acquireControl("Header")
                    elseif optionType == "number" then
                        control = acquireControl("Slider")
                    elseif optionType == "function" then
                        control = acquireControl("Button")
                    elseif optionType == "string" then
                        control = acquireControl("EditBox")
                    elseif optionType == "select" then
                        control = acquireControl("DropDown")
                    elseif optionType == "color" then
                        control = acquireControl("ColorSelect")
                    end
                end

                if control then
                    control.option = option

                    safecall(Control_RegisterCallbacks, control, option, controls)
                    if optionType == "function" then
                        safecall(control.RegisterCallback, control, "OnClick", Control_OnClick, option)
                    end

                    control.layoutIndex = #controls
                    control.leftPadding = leftPadding
                    controls[#controls + 1] = control
                end

                if type(option.optionList) == "table" then
                    createControls(option.optionList, leftPadding + 15, controls)
                end
            end
        end

        return controls
    end

    ---@param controls table
    local function releaseAllControls(controls)
        if controls then
            local tremove = tremove -- luacheck: ignore 431
            local releaseControl = releaseControl -- luacheck: ignore 431
            for i = #controls, 1, -1 do releaseControl(tremove(controls, i)) end
        end
    end

    lib.panels = lib.panels or {}

    local panels = lib.panels

    local PanelMixin = {}

    local CreateFrame = CreateFrame
    local InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory
    function PanelMixin:OnLoad()
        self.controls = self.controls or {}

        self:Hide()

        self.text = self.text or self:CreateFontString()
        self.text:SetParent(self)
        self.text:SetDrawLayer("ARTWORK")
        self.text:SetFontObject("GameFontNormalHuge")
        self.text:Show()
        self.text:ClearAllPoints()

        if self.parent then
            self.parentButton = self.parentButton or CreateFrame("Button")
            self.parentButton:SetParent(self)
            self.parentButton:Show()
            self.parentButton:SetNormalFontObject("GameFontNormalHuge")
            self.parentButton:SetText(self.parent)
            self.parentButton:ClearAllPoints()
            self.parentButton:SetPoint("TOPLEFT", 16, -16)
            self.parentButton:SetSize(self.parentButton:GetTextWidth(), self.parentButton:GetTextHeight())
            self.parentButton:SetScript("OnClick", function()
                InterfaceOptionsFrame_OpenToCategory(self.parent)
            end)
            self.text:SetPoint("LEFT", self.parentButton, "RIGHT")
            self.text:SetText(" > " .. self.name)
        else
            if self.parentButton then self.parentButton:Hide() end
            self.text:SetPoint("TOPLEFT", 16, -16)
            self.text:SetText(self.name)
        end

        self:SetScript("OnShow", self.OnShow)
        self:SetScript("OnHide", self.OnHide)
        self:SetScript("OnUpdate", self.OnUpdate)
    end

    ---@param optionList table
    local function onShow(optionList)
        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                local info = getInfo(option)
                safecall(option.onShow, info)
                tdel(info)
                if option.optionList then onShow(option.optionList) end
            end
        end
    end

    ---@param self table
    local function OnShow(self)
        frame:SetParent(self)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", 16, -40)
        frame:SetPoint("BOTTOMRIGHT", -26, 3)
        frame:Show()

        if self.refreshed then
            releaseAllControls(self._controls)
            self._controls = createControls(self._optionList)
            onShow(self._optionList)
        end
        self.lastUpdate = UPDATE_INTERVAL
    end
    function PanelMixin:OnShow() xsafecall(OnShow, self) end

    ---@param optionList table
    local function onHide(optionList)
        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                local info = getInfo(option)
                safecall(option.onHide, info)
                tdel(info)
                if option.optionList then onHide(option.optionList) end
            end
        end
    end

    ---@param self table
    local function OnHide(self) releaseAllControls(self._controls) end
    function PanelMixin:OnHide() xsafecall(OnHide, self) end

    ---@param optionList table
    ---@param elapsed number
    local function onUpdate(optionList, elapsed)
        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                option.lastUpdate = (option.lastUpdate or (option.onUpdateInterval or UPDATE_INTERVAL)) + elapsed
                if option.lastUpdate >= (option.onUpdateInterval or UPDATE_INTERVAL) then
                    option.lastUpdate = 0
                    local info = getInfo(option)
                    safecall(option.onUpdate, info)
                    tdel(info)
                end
                if type(option.optionList) == "table" then onUpdate(option.optionList, elapsed) end
            end
        end
    end

    ---@param self table
    ---@param elapsed number
    local function OnUpdate(self, elapsed)
        onUpdate(self._optionList, elapsed)

        self.lastUpdate = (self.lastUpdate or 0) + elapsed
        if self.lastUpdate >= UPDATE_INTERVAL then
            self.lastUpdate = 0
            updateControls(self._controls)
        end
    end
    ---@param elapsed number
    function PanelMixin:OnUpdate(elapsed) xsafecall(OnUpdate, self, elapsed) end

    ---@param optionList table
    local function onOkay(optionList)
        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                local info = getInfo(option)
                safecall(option.onOkay, info)
                tdel(info)
                if type(option.optionList) == "table" then onOkay(option.optionList) end
            end
        end
    end

    ---@param self table
    local function okay(self)
        self.refreshed = nil

        onOkay(self._optionList)

        self._optionList = tdel(self._optionList)
        self._oldValues = tdel(self._oldValues)
    end
    function PanelMixin:okay() xsafecall(okay, self) end

    ---@param optionList table
    local function onCancel(optionList)
        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                local info = getInfo(option)
                safecall(option.onCancel, info)
                tdel(info)
                if option.optionList then onCancel(option.optionList) end
            end
        end
    end

    ---@param values table
    local function setValues(values)
        for option, value in pairs(values) do
            if option.type == "select" and option.isMulti then
                for k, v in pairs(value) do setValue(option, k, v) end
            elseif option.type == "color" then
                if option.hasAlpha then
                    setValue(option, value.r, value.g, value.b, value.a)
                else
                    setValue(option, value.r, value.g, value.b)
                end
            else
                setValue(option, value)
            end
        end
    end

    ---@param self table
    local function cancel(self)
        self.refreshed = nil

        onCancel(self._optionList)
        setValues(self._oldValues)

        self._optionList = tdel(self._optionList)
        self._oldValues = tdel(self._oldValues)
    end
    function PanelMixin:cancel() xsafecall(cancel, self) end

    ---@param optionList table
    local function onDefault(optionList)
        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                local info = getInfo(option)
                safecall(option.onDefault, info)
                tdel(info)
                if type(option.optionList) == "table" then onDefault(option.optionList) end
            end
        end
    end

    ---@param self table
    local function default(self)
        self.refreshed = nil

        onDefault(self._optionList)
        setDefaults(self._optionList)

        self._optionList = tdel(self._optionList)
        self._oldValues = tdel(self._oldValues)
        releaseAllControls(self._controls)
    end
    function PanelMixin:default() xsafecall(default, self) end

    ---@param optionList table
    local function onRefresh(optionList)
        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                local info = getInfo(option)
                safecall(option.onRefresh, info)
                tdel(info)
                if type(option.optionList) == "table" then onRefresh(option.optionList) end
            end
        end
    end

    ---@param optionList table
    ---@param parent any
    local function copyOptionList(optionList, parent)
        local newOptionList = tnew()
        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                local newOption = tnew()
                newOption.handler = option.handler or optionList.handler or (parent and parent.handler)
                newOption.parent = parent or optionList
                for k, v in pairs(option) do
                    if k ~= "handler" and k ~= "parent" and k ~= "optionList" then newOption[k] = v end
                end
                if option.optionList then
                    newOption.optionList = copyOptionList(option.optionList, newOption)
                end
                newOptionList[i] = newOption
            end
        end
        return newOptionList
    end

    ---@param optionList table
    ---@param values table | nil
    ---@return table values
    local function getValues(optionList, values)
        if not values then values = tnew() end

        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]

            if option.type == "select" and option.isMulti then
                values[option] = tnew()
                for k, v in pairs(getOptionValue(option, "values") or tnew()) do
                    values[option][k] = getOptionValue(option, "get", k)
                end
            elseif option.type == "color" then
                values[option] = tnew()
                values[option].r, values[option].g, values[option].b, values[option].a = getOptionValue(option, "get")
                if not option.hasAlpha then values[option].a = nil end
            else
                values[option] = getOptionValue(option, "get")
            end

            if option.optionList then getValues(option.optionList, values) end
        end

        return values
    end

    ---@param self table
    local function refresh(self)
        local optionList = copyOptionList(self.optionList)
        self._optionList = optionList

        onRefresh(optionList)
        self._oldValues = getValues(optionList)

        self.refreshed = true

        if self:IsVisible() then
            releaseAllControls(self._controls)
            self._controls = createControls(self._optionList)
            onShow(self._optionList)
        end
    end
    function PanelMixin:refresh() xsafecall(refresh, self) end

    for i = 1, #panels do LJMixin:Mixin(panels[i], PanelMixin) end -- upgrade

    local InterfaceAddOnsList_Update = InterfaceAddOnsList_Update
    local InterfaceOptionsFrame = InterfaceOptionsFrame
    local InterfaceOptions_AddCategory = InterfaceOptions_AddCategory
    --[[
    List of option attributes
    ==============================================================================
    Note: All functions are called with 'option.arg' as first argument.
    ------------------------------------------------------------------------------
    option.type = [string]
    option.control = [string, frame, nil]
    option.text = [string, function]
    option.get = [any]
    option.set = [any]
    option.default = [any]
    option.arg = [any]
    option.tooltip = [string, function]
    option.noCombat = [boolean, function]
    option.hidden = [boolean, function]
    option.disabled = [boolean, function]
    option.icon = [string, function]
    option.iconCoords = [number[], function]
    option.optionList = [table]
    option.handler = [table] -- inherited
    option.path = [any]

        --------------------------------------------------------------------------
        -- type == "boolean"
        --------------------------------------------------------------------------
        option.isRadio = [boolean, function] -- not implemented yet

        --------------------------------------------------------------------------
        -- type == "header"
        --------------------------------------------------------------------------

        --------------------------------------------------------------------------
        -- type == "number"
        --------------------------------------------------------------------------
        option.isPercent = [boolean, function]
        option.step = [number, function]
        option.min = [number, function]
        option.max = [number, function]
        option.minText = [string, function]
        option.maxText = [string, function]

        --------------------------------------------------------------------------
        -- type == "function" -- not implemented yet
        --------------------------------------------------------------------------
        option.func = [function]

        --------------------------------------------------------------------------
        -- type == "string"
        --------------------------------------------------------------------------
        option.isReadOnly = [boolean, function]
        option.maxLetters = [number, function]
        option.justifyH = [string, function]
        option.isMultiLine = [boolean, function]

        --------------------------------------------------------------------------
        -- type == "select"
        --------------------------------------------------------------------------
        option.values = [table<any, string>, function]
        option.isMulti = [boolean]

        --------------------------------------------------------------------------
        -- type == "color"
        --------------------------------------------------------------------------
        option.hasAlpha = [boolean]
    ]]
    ---@param name string
    ---@param parent string
    ---@param optionList table
    function lib:New(name, parent, optionList)
        if type(name) ~= "string" then
            error(
                format("Usage: %s:New(name[, parent], optionList): 'name' - string expected got %s", MAJOR, type(name)),
                2)
        end
        if type(parent) == "table" then optionList, parent = parent, nil end
        if type(parent) ~= "string" and type(parent) ~= "nil" then
            error(format("Usage: %s:New(name[, parent], optionList): 'parent' - string or nil expected got %s", MAJOR,
                         type(parent)), 2)
        end
        if type(optionList) ~= "table" then
            error(format("Usage: %s:New(name[, parent], optionList): 'optionList' - table expected got %s", MAJOR,
                         type(optionList)), 2)
        end

        local panel = LJMixin:Mixin(CreateFrame("Frame"), {name = name, parent = parent, optionList = optionList},
                                    PanelMixin)

        panels[#panels + 1] = panel

        InterfaceOptions_AddCategory(panel)

        if InterfaceOptionsFrame:IsShown() then
            panel:refresh()
            InterfaceAddOnsList_Update()
        end
    end
    setmetatable(lib, {__call = lib.New})
end

---@param control any
function lib:SetFocus(control)
    if control ~= self.focus then
        self:ClearFocus()
        self.focus = control
    end
end

---@return any control
function lib:GetFocus() return self.focus end

function lib:ClearFocus()
    local focus = self:GetFocus()
    if focus then
        safecall(focus.ClearFocus, focus)
        self.focus = nil
    end
end

do -- InterfaceOptionsFrame
    local OptionsListButtonToggle_OnClick = OptionsListButtonToggle_OnClick
    ---@param self table
    ---@param button string
    local function OnDoubleClick(self, button)
        local toggle = self.toggle
        if toggle:IsShown() and button == "LeftButton" then OptionsListButtonToggle_OnClick(toggle) end
    end

    for i = 1, 31 do
        local button = _G["InterfaceOptionsFrameAddOnsButton" .. i]
        button:SetScript("OnDoubleClick", OnDoubleClick)
    end
end
