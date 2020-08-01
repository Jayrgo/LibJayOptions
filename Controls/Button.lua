local mixin, oldVersion = LibStub("LibJayOptions"):RegisterControl("Button", 0, "Button")

if not mixin then return end

---@param self table
---@param motion boolean
local function OnEnter(self, motion) if self:IsEnabled() then self.callbacks:TriggerEvent("OnEnter", self, motion) end end

---@param self table
---@param motion boolean
local function OnLeave(self, motion) self.callbacks:TriggerEvent("OnLeave", self, motion) end

---@param self table
---@param button string
---@param down boolean
local function OnClick(self, button, down)
    if self.func then self.func(button, down) end
    self.callbacks:TriggerEvent("OnClick", self, button, down)
end

local min = math.min
---@param self table
local function UpdateTextures(self)
    self.middleTexture:SetWidth(min(self:GetWidth() - 30, self:GetTextWidth()))
    if self:IsEnabled() then
        self.leftTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
        self.middleTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
        self.rightTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
    else
        self.leftTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Disabled]])
        self.middleTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Disabled]])
        self.rightTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Disabled]])
    end
end

---@param self table
---@param elapsed number
local function OnUpdate(self, elapsed)
    self.lastUpdate = self.lastUpdate + elapsed
    if self.lastUpdate >= 0.2 then
        self.lastUpdate = 0
        UpdateTextures(self)
    end
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
    fontString:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", 12, 0)
    fontString:SetPoint("BOTTOMRIGHT", -12, 0)
    self:SetFontString(fontString)

    self:SetNormalFontObject("GameFontNormalSmallLeft")
    self:SetHighlightFontObject("GameFontHighlightSmallLeft")
    self:SetDisabledFontObject("GameFontDisableSmallLeft")

    self.leftTexture = self.leftTexture or self:CreateTexture()
    self.leftTexture:SetParent(self)
    self.leftTexture:SetDrawLayer("BACKGROUND")
    self.leftTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
    self.leftTexture:SetTexCoord(0, 0.09375, 0, 0.6875)
    self.leftTexture:ClearAllPoints()
    self.leftTexture:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", 2, 0)
    self.leftTexture:SetPoint("BOTTOMLEFT", self.icon, "BOTTOMRIGHT", 2, 0)
    self.leftTexture:SetWidth(12)

    self.middleTexture = self.middleTexture or self:CreateTexture()
    self.middleTexture:SetParent(self)
    self.middleTexture:SetDrawLayer("BACKGROUND")
    self.middleTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
    self.middleTexture:SetTexCoord(0.09375, 0.53125, 0, 0.6875)
    self.middleTexture:ClearAllPoints()
    self.middleTexture:SetPoint("TOPLEFT", self.leftTexture, "TOPRIGHT")
    self.middleTexture:SetPoint("BOTTOMLEFT", self.leftTexture, "BOTTOMRIGHT")

    self.rightTexture = self.rightTexture or self:CreateTexture()
    self.rightTexture:SetParent(self)
    self.rightTexture:SetDrawLayer("BACKGROUND")
    self.rightTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
    self.rightTexture:SetTexCoord(0.53125, 0.625, 0, 0.6875)
    self.rightTexture:ClearAllPoints()
    self.rightTexture:SetPoint("TOPLEFT", self.middleTexture, "TOPRIGHT")
    self.rightTexture:SetPoint("BOTTOMLEFT", self.middleTexture, "BOTTOMRIGHT")
    self.rightTexture:SetWidth(12)

    local highlightTexture = self:GetHighlightTexture() or self:CreateTexture()
    highlightTexture:SetParent(self)
    highlightTexture:SetTexture([[UIPanelButtonHighlightTexture]])
    highlightTexture:SetTexCoord(0, 1, 0, 1)
    self:SetHighlightTexture(highlightTexture)

    self.lastUpdate = 0
    self:SetScript("OnUpdate", OnUpdate)
    self:SetScript("OnClick", OnClick)
    self:SetScript("OnEnter", OnEnter)
    self:SetScript("OnLeave", OnLeave)
end

function mixin:OnAcquire()
    self:SetHeight(20)
    self:SetIcon()
    self:SetText()
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

---@param func function
function mixin:SetFunc(func) self.func = func end

