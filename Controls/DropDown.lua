local mixin, oldVersion = LibStub("LibJayOptions"):RegisterControl(
                              "DropDown", 0, "Button")

if not mixin then return end

local L = {}

L.NONE = "none"

if GetLocale() == "deDE" then L.NONE = "keine" end

local pairs = pairs
local tostring = tostring
local tsort = table.sort
---@param values table
---@return table sortedValues
local function getSortedValues(values)
    local sortedList = {}
    for key in pairs(values) do sortedList[#sortedList + 1] = key end
    tsort(sortedList,
          function(a, b) return tostring(values[a]) < tostring(values[b]) end)
    return sortedList
end

---@param self table
local function UpdateFont(self)
    if self:IsEnabled() then
        if self:IsMouseOver() then
            self.text:SetFontObject("GameFontHighlightSmall")
        else
            self.text:SetFontObject("GameFontNormalSmall")
        end
    else
        self.text:SetFontObject("GameFontDisableSmall")
    end
end

local GameTooltip = GameTooltip
---@param self table
---@param motion boolean
local function TextHover_OnEnter(self, motion)
    local parent = self:GetParent()
    UpdateFont(parent)
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    GameTooltip:SetText(parent:GetText())
    GameTooltip:AddLine(self.text)
    GameTooltip:Show()
end

---@param self table
---@param motion boolean
local function TextHover_OnLeave(self, motion)
    UpdateFont(self:GetParent())
    GameTooltip:Hide()
end

---@param self table
---@param motion boolean
local function OnEnter(self, motion)
    UpdateFont(self)
    if self:IsEnabled() then
        self.callbacks:TriggerEvent("OnEnter", self, motion)
    end
end

---@param self table
---@param motion boolean
local function OnLeave(self, motion)
    UpdateFont(self)
    self.callbacks:TriggerEvent("OnLeave", self, motion)
end

local SOUND_IG_MAINMENU_OPTION_CHECKBOX_ON =
    SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
local PlaySound = PlaySound
local LJOptions = LibStub("LibJayOptions")
local LJDropDownMenu = LibStub("LibJayDropDownMenu")
---@param self table
---@param button string
---@param down boolean
local function OnClick(self, button, down)
    PlaySound(SOUND_IG_MAINMENU_OPTION_CHECKBOX_ON)

    if LJDropDownMenu:IsOwned(self) then
        LJDropDownMenu:Close()
        LJOptions:ClearFocus()
        return
    end

    local values = self.values
    if values then
        local menuList = {}

        local selectedValues = self.selectedValues
        local checked = function(info, arg) return selectedValues[arg] end

        local func = function(info, arg, checked)
            self:SetValue(arg, checked)
            self.callbacks:TriggerEvent("OnValueChanged", self, arg, checked)
        end

        local icons = self.icons
        local function getIcon(info, arg)
            if icons then return icons[arg] end
        end

        local sortedValues
        if self.sortByKeys then
            sortedValues = {}
            for k in pairs(values) do
                sortedValues[#sortedValues + 1] = k
            end
            tsort(sortedValues)
        else
            sortedValues = getSortedValues(values)
        end
        for i = 1, #sortedValues do
            local key = sortedValues[i]

            menuList[#menuList + 1] = {
                arg = key,
                text = tostring(values[key]),
                checked = checked,
                func = func,
                isNotRadio = self:IsMultiselect(),
                keepShownOnClick = self:IsMultiselect(),
                icon = getIcon
            }
        end

        local title = self:GetText()
        title = title ~= "" and title

        LJDropDownMenu:SetOwner(self, "ANCHOR_CURSOR")
        LJDropDownMenu:Open(menuList, title)
        if LJDropDownMenu:IsOpen() then LJOptions:SetFocus(self) end
    end
end

---@param self table
local function OnEnable(self) UpdateFont(self) end

---@param self table
local function OnDisable(self) UpdateFont(self) end

local CreateFrame = CreateFrame
local LJCallback = LibStub("LibJayCallback")
function mixin:OnLoad()
    self.OnLoad = nil
    self.callbacks = self.callbacks or LJCallback:New(self)

    self.expand = true

    self.icon = self.icon or self:CreateTexture()
    self.icon:SetParent(self)
    self.icon:SetDrawLayer("ARTWORK")
    self.icon:ClearAllPoints()
    self.icon:SetPoint("TOPLEFT")
    self.icon:SetPoint("BOTTOMLEFT")
    self.icon:SetWidth(26)

    local fontString = self:GetFontString() or self:CreateFontString()
    fontString:SetParent(self)
    fontString:SetDrawLayer("BORDER")
    fontString:ClearAllPoints()
    fontString:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", 2, 0)
    fontString:SetPoint("BOTTOMRIGHT", -30, 0)
    self:SetFontString(fontString)

    self:SetNormalFontObject("GameFontNormalSmallLeft")
    self:SetHighlightFontObject("GameFontHighlightSmallLeft")
    self:SetDisabledFontObject("GameFontDisableSmallLeft")

    local normalTexture = self:GetNormalTexture() or self:CreateTexture()
    normalTexture:ClearAllPoints()
    normalTexture:SetPoint("TOPRIGHT")
    normalTexture:SetSize(26, 26)
    normalTexture:SetTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Up]])
    normalTexture:SetDrawLayer("BACKGROUND")
    self:SetNormalTexture(normalTexture)

    local highlightTexture = self:GetHighlightTexture() or self:CreateTexture()
    highlightTexture:ClearAllPoints()
    highlightTexture:SetPoint("TOPRIGHT")
    highlightTexture:SetSize(26, 26)
    highlightTexture:SetTexture([[Interface\Buttons\UI-Common-MouseHilight]])
    highlightTexture:SetDrawLayer("BACKGROUND")
    self:SetHighlightTexture(highlightTexture, "ADD")

    local pushedTexture = self:GetPushedTexture() or self:CreateTexture()
    pushedTexture:ClearAllPoints()
    pushedTexture:SetPoint("TOPRIGHT")
    pushedTexture:SetSize(26, 26)
    pushedTexture:SetTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Down]])
    pushedTexture:SetDrawLayer("BACKGROUND")
    self:SetPushedTexture(pushedTexture)

    local disabledTexture = self:GetDisabledTexture() or self:CreateTexture()
    disabledTexture:ClearAllPoints()
    disabledTexture:SetPoint("TOPRIGHT")
    disabledTexture:SetSize(26, 26)
    disabledTexture:SetTexture(
        [[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Disabled]])
    disabledTexture:SetDrawLayer("BACKGROUND")
    self:SetDisabledTexture(disabledTexture)

    self.text = self.text or self:CreateFontString()
    self.text:SetParent(self)
    self.text:SetDrawLayer("OVERLAY")
    self.text:ClearAllPoints()
    self.text:SetPoint("TOPLEFT", self, "TOP", 5, 0)
    self.text:SetPoint("BOTTOMRIGHT", -30, 0)
    --[[ self.text:SetPoint("LEFT", self, "CENTER", 5, 0)
    self.text:SetPoint("RIGHT", -30, 0) ]]
    self.text:SetFontObject("GameFontNormalSmall")
    self.text:SetJustifyH("RIGHT")

    self.textHover = self.textHover or CreateFrame("Frame")
    self.textHover:SetParent(self)
    self.textHover:ClearAllPoints()
    self.textHover:SetPoint("TOPLEFT", self.text, "TOPLEFT")
    self.textHover:SetPoint("BOTTOMRIGHT", self.text, "BOTTOMRIGHT")

    self:SetScript("OnEnter", OnEnter)
    self:SetScript("OnLeave", OnLeave)
    self:SetScript("OnClick", OnClick)
    self:SetScript("OnEnable", OnEnable)
    self:SetScript("OnDisable", OnDisable)

    self.selectedValues = {}
end

function mixin:OnAcquire()
    self:SetHeight(26)
    self:SetText()
    self:SetIcon()
    self:SetValues()
    self:SetValue()
    self:SetIcons()
    self:UpdateFont()
    self:SetSortByKeys()
    self:ResumeUpdates()
end

local wipe = wipe
function mixin:OnRelease()
    wipe(self.selectedValues)
    self.callbacks:Wipe()
    if self:HasFocus() then LJDropDownMenu:Close() end
end

function mixin:PauseUpdates() self.pauseUpdates = true end

---@param self table
---@param state boolean
---@param text string
local function TextHover_SetEnabled(self, state, text)
    local textHover = self.textHover
    textHover.text = text
    if state then
        textHover:SetScript("OnEnter", TextHover_OnEnter)
        textHover:SetScript("OnLeave", TextHover_OnLeave)
        textHover:SetMouseClickEnabled(false)
        --[[ textHover:SetMouseMotionEnabled(true) ]]
    else
        textHover:SetScript("OnEnter", nil)
        textHover:SetScript("OnLeave", nil)
        textHover:SetMouseMotionEnabled(false)
    end
end

local TEXTURE_STRING = "|T%s:0|t "
local format = format
---@param icon string
local function getTextureString(icon) return format(TEXTURE_STRING, icon) end

local tconcat = table.concat
---@param self table
local function Update(self)
    if self.pauseUpdates then return end

    local selectedValues, icons = self.selectedValues, self.icons
    local displayText, hoverText

    local values = self.values
    if values then
        if self:IsMultiselect() then
            local sortedValues = getSortedValues(values)
            displayText, hoverText = {}, {}
            for i = 1, #sortedValues do
                local key = sortedValues[i]

                if selectedValues[key] then
                    local valueText = tostring(values[key])
                    displayText[#displayText + 1] = valueText
                    if icons and icons[key] then
                        valueText = getTextureString(icons[key]) .. valueText
                    end
                    hoverText[#hoverText + 1] = valueText
                end
            end
            displayText = #displayText > 0 and tconcat(displayText, ", ")
            hoverText = tconcat(hoverText, "\n")
        else
            for k, v in pairs(values) do
                if selectedValues[k] then
                    displayText = tostring(v)
                    hoverText = displayText
                    break
                end
            end
        end
    end

    local text = self.text
    text:SetText(displayText or L["none"])
    TextHover_SetEnabled(self, text:IsTruncated(), hoverText)
    UpdateFont(self)
end

function mixin:ResumeUpdates()
    self.pauseUpdates = false
    Update(self)
end

---@param filename string
---@param coords table
function mixin:SetIcon(filename, coords)
    local icon = self.icon
    icon:SetTexture(filename)
    local left, right, top, bottom
    if coords then left, right, top, bottom = unpack(coords) end
    icon:SetTexCoord(left or 0, right or 1, top or 0, bottom or 1)
    icon:SetWidth(filename and 26 or 0.1)
end

---@param icons table
function mixin:SetIcons(icons) self.icons = icons end

---@param values table
function mixin:SetValues(values)
    self.values = values
    wipe(self.selectedValues)
end

---@param value any
---@param selected boolean
function mixin:SetValue(value, selected)
    local selectedValues = self.selectedValues

    if type(value) == "nil" then
        self.text:SetText()
        TextHover_SetEnabled(self, false)
        return
    end
    if not self:IsMultiselect() then
        for k, v in pairs(selectedValues) do selectedValues[k] = nil end
    end
    selectedValues[value] = selected

    Update(self)
end

function mixin:UpdateDisplayText() end

---@return any value
function mixin:GetValue() return self.value end

function mixin:HasFocus()
    return LJDropDownMenu:IsOpen() and LJDropDownMenu:IsOwned(self)
end

function mixin:ClearFocus()
    if LJDropDownMenu:IsOwned(self) then LJDropDownMenu:Close() end
end

---@param state boolean
function mixin:SetMultiselect(state) self.isMultiselect = state end

---@return boolean isMultiselect
function mixin:IsMultiselect() return self.isMultiselect end

---@param sortByKeys boolean
function mixin:SetSortByKeys(sortByKeys)
    self.sortByKeys = sortByKeys
    Update(self)
end
