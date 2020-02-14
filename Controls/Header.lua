local mixin, oldVersion = LibStub("LibJayOptions"):RegisterControl("Header",
                                                                       0,
                                                                       "Button")

if not mixin then return end

---@param self table
---@param motion boolean
local function OnEnter(self, motion)
    if self:IsEnabled() then
        self.callbacks:TriggerEvent("OnEnter", self, motion)
    end
end

---@param self table
---@param motion boolean
local function OnLeave(self, motion)
    self.callbacks:TriggerEvent("OnLeave", self, motion)
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

    self:SetPushedTextOffset(0, 0)

    self:SetScript("OnEnter", OnEnter)
    self:SetScript("OnLeave", OnLeave)
end

function mixin:OnAcquire()
    self:SetHeight(26)
    self:SetText()
    self:SetIcon()
end

function mixin:OnRelease() self.callbacks:Wipe() end

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
