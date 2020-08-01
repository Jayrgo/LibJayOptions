local mixin, oldVersion = LibStub("LibJayOptions"):RegisterControl("Slider", 0, "Button")

if not mixin then return end

---@param self table
---@param isOver boolean
local function UpdateFonts(self, isOver)
    local parent = self:GetParent()
    if parent:IsEnabled() then
        if isOver then
            parent.text:SetFontObject("GameFontHighlightSmall")
        else
            parent.text:SetFontObject("GameFontNormalSmall")
        end
    else
        parent.text:SetFontObject("GameFontDisableSmall")
    end
end

local select = select
local strlen = strlen
local strsplit = strsplit
---@param self table
local function UpdateText(self)
    local parent = self:GetParent()
    local text = parent.text

    local value, min, max = self:GetValue(), self:GetMinMaxValues()
    if value == min and parent.minText then
        text:SetText(parent.minText)
    elseif value == max and parent.maxText then
        text:SetText(parent.maxText)
    else
        if parent.isPercent then
            local places = select(2, strsplit(".", parent.step * 100))
            text:SetFormattedText("%." .. (places and strlen(places) or 0) .. "f %%", value * 100)
        else
            local places = select(2, strsplit(".", parent.step))
            text:SetFormattedText("%." .. (places and strlen(places) or 0) .. "f", value)
        end
    end
    self:SetHitRectInsets(-text:GetStringWidth(), 0, 0, 0)
end

---@param self table
---@param value number
---@param isUserInput boolean
local function Slider_OnValueChanged(self, value, isUserInput)
    UpdateText(self)
    if isUserInput then
        local parent = self:GetParent()
        parent.callbacks:TriggerEvent("OnValueChanged", parent, value)
    end
end

---@param self table
---@param min number
---@param max number
local function Slider_OnMinMaxChanged(self, min, max) Slider_OnValueChanged(self, self:GetValue(), false) end

---@param self table
---@param delta number
local function Slider_OnMouseWheel(self, delta)
    local parent = self:GetParent()
    if parent:IsEnabled() then self:SetValue(self:GetValue() + (delta * parent.step), true) end
end

---@param self table
---@param button string
local function Slider_OnMouseDown(self, button)
    if self:GetParent():IsEnabled() then Slider_OnValueChanged(self, self:GetValue(), true) end
end

---@param self table
---@param motion boolean
local function OnEnter(self, motion) if self:IsEnabled() then self.callbacks:TriggerEvent("OnEnter", self, motion) end end

---@param self table
---@param motion boolean
local function OnLeave(self, motion) self.callbacks:TriggerEvent("OnLeave", self, motion) end

---@param self table
---@param motion boolean
local function Slider_OnEnter(self, motion)
    UpdateFonts(self, true)
    local parent = self:GetParent()
    if parent:IsEnabled() then parent:LockHighlight() end
    OnEnter(parent, motion)
end

---@param self table
---@param motion boolean
local function Slider_OnLeave(self, motion)
    UpdateFonts(self, false)
    local parent = self:GetParent()
    parent:UnlockHighlight()
    OnLeave(parent, motion)
end

---@param self table
local function OnEnable(self)
    local slider = self.slider
    slider:Enable()
    UpdateFonts(slider)
end

---@param self table
local function OnDisable(self)
    local slider = self.slider
    slider:Disable()
    UpdateFonts(slider)
end

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
    self:SetFontString(fontString)

    self:SetNormalFontObject("GameFontNormalSmallLeft")
    self:SetHighlightFontObject("GameFontHighlightSmallLeft")
    self:SetDisabledFontObject("GameFontDisableSmallLeft")

    self.text = self.text or self:CreateFontString()
    self.text:SetParent(self)
    self.text:SetDrawLayer("OVERLAY")
    self.text:ClearAllPoints()
    self.text:SetPoint("TOPRIGHT", self, "TOP", 2, 0)
    self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOM", 2, 0)
    fontString:SetPoint("BOTTOMRIGHT", self.text, "BOTTOMLEFT", -2, 0)

    self.slider = self.slider or CreateFrame("Slider", nil, self)
    self.slider:ClearAllPoints()
    self.slider:SetPoint("LEFT", self, "CENTER", 4, 0)
    self.slider:SetPoint("RIGHT", -5, 0)
    self.slider:SetOrientation("HORIZONTAL")
    self.slider:SetBackdrop({
        bgFile = [[Interface\Buttons\UI-SliderBar-Background]],
        edgeFile = [[Interface\Buttons\UI-SliderBar-Border]],
        tile = true,
        edgeSize = 8,
        tileSize = 8,
        insets = {left = 3, right = 3, top = 6, bottom = 6},
    })
    self.slider:SetObeyStepOnDrag(true)

    self.slider:SetThumbTexture([[Interface\Buttons\UI-SliderBar-Button-Horizontal]])
    self.slider:SetHeight(18)

    self.slider:SetScript("OnValueChanged", Slider_OnValueChanged)
    self.slider:SetScript("OnMinMaxChanged", Slider_OnMinMaxChanged)
    self.slider:SetScript("OnMouseWheel", Slider_OnMouseWheel)
    self.slider:SetScript("OnMouseDown", Slider_OnMouseDown)
    self.slider:SetScript("OnEnter", Slider_OnEnter)
    self.slider:SetScript("OnLeave", Slider_OnLeave)

    self:SetScript("OnEnter", OnEnter)
    self:SetScript("OnLeave", OnLeave)
    self:SetScript("OnEnable", OnEnable)
    self:SetScript("OnDisable", OnDisable)

    UpdateFonts(self.slider, false)
end

function mixin:OnAcquire()
    self:SetHeight(26)
    self:SetIcon()
    self:SetText()
    self:SetStep()
    self:SetIsPercent()
    self:SetMinMaxValues(0, 0)
    self:SetMinMaxTexts()
end

function mixin:OnRelease() self.callbacks:Wipe() end

---@param value boolean
function mixin:SetValue(value) self.slider:SetValue(value) end

---@return boolean value
function mixin:GetValue() return self.slider:GetValue() end

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

---@param min any
---@param max any
function mixin:SetMinMaxValues(min, max) self.slider:SetMinMaxValues(min, max) end

---@param isPercent boolean
function mixin:SetIsPercent(isPercent)
    self.isPercent = isPercent
    UpdateText(self.slider)
end

---@param step number
function mixin:SetStep(step)
    self.step = step or (self.isPercent and 0.01 or 1)
    local slider = self.slider
    slider:SetValueStep(self.step)
    slider:SetStepsPerPage(self.step)
    UpdateText(slider)
end

---@param min string
---@param max string
function mixin:SetMinMaxTexts(min, max)
    self.minText = min
    self.maxText = max
    UpdateText(self.slider)
end

---@return boolean hasFocus
function mixin:HasFocus() return self.slider:IsDraggingThumb() end

