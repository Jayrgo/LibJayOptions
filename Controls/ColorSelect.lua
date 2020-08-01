local mixin, oldVersion = LibStub("LibJayOptions"):RegisterControl("ColorSelect", 0, "Button")

if not mixin then return end

local DISABLED_FONT_COLOR = DISABLED_FONT_COLOR
local HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR
---@param self table
local function UpdateBorder(self)
    if self:IsEnabled() then
        if self:IsMouseOver() then
            self.border:SetColorTexture(HIGHLIGHT_FONT_COLOR:GetRGB())
        else
            self.border:SetColorTexture(NORMAL_FONT_COLOR:GetRGB())
        end
    else
        self.border:SetColorTexture(DISABLED_FONT_COLOR:GetRGB())
    end
end

---@param self table
---@param motion boolean
local function OnEnter(self, motion)
    UpdateBorder(self)
    if self:IsEnabled() then self.callbacks:TriggerEvent("OnEnter", self, motion) end
end

---@param self table
---@param motion boolean
local function OnLeave(self, motion)
    UpdateBorder(self)
    if self:IsEnabled() then self.callbacks:TriggerEvent("OnLeave", self, motion) end
end

local ColorPickerFrame = ColorPickerFrame
local OpacitySliderFrame = OpacitySliderFrame
local LJOptions = LibStub("LibJayOptions")
---@param self table
---@param button string
---@param down boolean
local function OnClick(self, button, down)
    local hasAlpha = self.hasAlpha

    local function callback(previousValues)
        local r, g, b, a
        if previousValues then
            r, g, b, a = unpack(previousValues)
        else
            r, g, b = ColorPickerFrame:GetColorRGB()
        end
        if hasAlpha then
            self.callbacks:TriggerEvent("OnValueChanged", self, r, g, b, a and a or (1 - OpacitySliderFrame:GetValue()))
        else
            self.callbacks:TriggerEvent("OnValueChanged", self, r, g, b)
        end
        LJOptions:ClearFocus()
    end

    ColorPickerFrame:SetColorRGB(self.r, self.g, self.b)
    ColorPickerFrame.func = callback
    ColorPickerFrame.hasOpacity = hasAlpha
    ColorPickerFrame.opacity = hasAlpha and 1 - self.a or 0
    ColorPickerFrame.opacityFunc = callback
    ColorPickerFrame.cancelFunc = callback
    ColorPickerFrame.previousValues = {self.r, self.g, self.b, hasAlpha and self.a}

    ColorPickerFrame:Hide()
    ColorPickerFrame:Show()
    if ColorPickerFrame:IsShown() then LJOptions:SetFocus(self) end
end

---@param self table
local function OnEnable(self) self:UpdateBorder() end

---@param self table
local function OnDisable(self) self:UpdateBorder() end

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
    fontString:SetPoint("BOTTOMRIGHT", self, "BOTTOM", -5, 0)
    self:SetFontString(fontString)

    self:SetNormalFontObject("GameFontNormalSmallLeft")
    self:SetHighlightFontObject("GameFontHighlightSmallLeft")
    self:SetDisabledFontObject("GameFontDisableSmallLeft")

    local normalTexture = self:GetNormalTexture() or self:CreateTexture()
    normalTexture:SetParent(self)
    normalTexture:ClearAllPoints()
    normalTexture:SetPoint("TOPRIGHT", -6, -6)
    normalTexture:SetSize(14, 14)
    self:SetNormalTexture(normalTexture)

    self.border = self.border or self:CreateTexture()
    self.border:SetParent(self)
    self.border:SetDrawLayer("BACKGROUND")
    self.border:ClearAllPoints()
    self.border:SetPoint("TOPRIGHT", -3, -3)
    self.border:SetSize(20, 20)

    self.midBorder = self.midBorder or self:CreateTexture()
    self.midBorder:SetParent(self)
    self.midBorder:SetDrawLayer("BORDER")
    self.midBorder:ClearAllPoints()
    self.midBorder:SetPoint("TOPRIGHT", -4, -4)
    self.midBorder:SetSize(18, 18)
    self.midBorder:SetColorTexture(0, 0, 0, 1)

    self:SetScript("OnEnter", OnEnter)
    self:SetScript("OnLeave", OnLeave)
    self:SetScript("OnClick", OnClick)
    self:SetScript("OnEnable", OnEnable)
    self:SetScript("OnDisable", OnDisable)

    self.selectedValues = {}
end

function mixin:OnAcquire()
    self:SetHeight(26)
    self:SetIcon()
    self:SetText()
    UpdateBorder(self)
    self:SetHasAlpha(false)
end

function mixin:OnRelease() self.callbacks:Wipe() end

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

---@param r number
---@param g number
---@param b number
---@param a number
function mixin:SetValue(r, g, b, a)
    self.r, self.g, self.b, self.a = r, g, b, a
    self:GetNormalTexture():SetColorTexture(r, g, b, a)
end

---@param hasAlpha boolean
function mixin:SetHasAlpha(hasAlpha) self.hasAlpha = hasAlpha end

