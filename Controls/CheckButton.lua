local mixin, oldVersion = LibStub("LibJayOptions"):RegisterControl("CheckButton", 0, "CheckButton")

if not mixin then return end

---@param self table
---@param motion boolean
local function OnEnter(self, motion) if self:IsEnabled() then self.callbacks:TriggerEvent("OnEnter", self, motion) end end

---@param self table
---@param motion boolean
local function OnLeave(self, motion) self.callbacks:TriggerEvent("OnLeave", self, motion) end

local SOUND_IG_MAINMENU_OPTION_CHECKBOX_ON = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
local SOUND_IG_MAINMENU_OPTION_CHECKBOX_OFF = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
local PlaySound = PlaySound
local LJOptions = LibStub("LibJayOptions")
---@param self table
---@param button string
---@param down boolean
local function OnClick(self, button, down)
    LJOptions:ClearFocus()
    local value = self:GetValue()
    if value then
        PlaySound(SOUND_IG_MAINMENU_OPTION_CHECKBOX_ON)
    else
        PlaySound(SOUND_IG_MAINMENU_OPTION_CHECKBOX_OFF)
    end
    self.callbacks:TriggerEvent("OnValueChanged", self, value)
end

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
    normalTexture:SetTexture([[Interface\Buttons\UI-CheckBox-Up]])
    normalTexture:SetDrawLayer("BACKGROUND")
    self:SetNormalTexture(normalTexture)

    local highlightTexture = self:GetHighlightTexture() or self:CreateTexture()
    highlightTexture:ClearAllPoints()
    highlightTexture:SetPoint("TOPRIGHT")
    highlightTexture:SetSize(26, 26)
    highlightTexture:SetTexture([[Interface\Buttons\UI-CheckBox-Highlight]])
    highlightTexture:SetDrawLayer("BACKGROUND")
    self:SetHighlightTexture(highlightTexture, "ADD")

    local pushedTexture = self:GetPushedTexture() or self:CreateTexture()
    pushedTexture:ClearAllPoints()
    pushedTexture:SetPoint("TOPRIGHT")
    pushedTexture:SetSize(26, 26)
    pushedTexture:SetTexture([[Interface\Buttons\UI-CheckBox-Down]])
    pushedTexture:SetDrawLayer("BACKGROUND")
    self:SetPushedTexture(pushedTexture)

    local checkedTexture = self:GetCheckedTexture() or self:CreateTexture()
    checkedTexture:ClearAllPoints()
    checkedTexture:SetPoint("TOPRIGHT")
    checkedTexture:SetSize(26, 26)
    checkedTexture:SetTexture([[Interface\Buttons\UI-CheckBox-Check]])
    checkedTexture:SetDrawLayer("BACKGROUND")
    self:SetCheckedTexture(checkedTexture)

    local disabledTexture = self:GetDisabledCheckedTexture() or self:CreateTexture()
    disabledTexture:ClearAllPoints()
    disabledTexture:SetPoint("TOPRIGHT")
    disabledTexture:SetSize(26, 26)
    disabledTexture:SetTexture([[Interface\Buttons\UI-CheckBox-Check-Disabled]])
    disabledTexture:SetDrawLayer("BACKGROUND")
    self:SetDisabledCheckedTexture(disabledTexture)

    self:SetScript("OnEnter", OnEnter)
    self:SetScript("OnLeave", OnLeave)
    self:SetScript("OnClick", OnClick)
end

function mixin:OnAcquire()
    self:SetHeight(26)
    self:SetIcon()
    self:SetText()
end

function mixin:OnRelease() self.callbacks:Wipe() end

---@param value boolean
function mixin:SetValue(value) if value ~= self:GetChecked() then self:SetChecked(value) end end

---@return boolean value
function mixin:GetValue() return self:GetChecked() end

local unpack = unpack
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
