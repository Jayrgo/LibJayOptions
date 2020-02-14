local mixin, oldVersion = LibStub("LibJayOptions"):RegisterControl(
                              "EditBox", 0, "Button")

if not mixin then return end

local format = format
local tonumber = tonumber
---@param num number
---@return number num
local function round(num) return tonumber(format("%.1f", num)) end

---@param self table
local function EditBox_UpdateHeight(self)
    local parent = self:GetParent()
    local height = self:GetHeight()
    if round(parent:GetHeight() - 8) ~= round(height) then
        parent:SetHeight(height + 8)
    end
end

---@param self table
local function EditBox_OnEscapePressed(self) self:ClearFocus() end

---@param self table
local function EditBox_OnEnterPressed(self)
    local parent = self:GetParent()
    parent.callbacks:TriggerEvent("OnValueChanged", parent, self:GetText())
    self:ClearFocus()
end

---@param self table
---@param isUserInput boolean
local function EditBox_OnTextChanged(self, isUserInput)
    local parent = self:GetParent()
    parent.text:SetText(self:GetText())
    parent.count:SetFormattedText("%d/%d", self:GetNumLetters(),
                                  self:GetMaxLetters())
    if isUserInput then EditBox_UpdateHeight(self) end
end

---@param self table
local function EditBox_OnTextSet(self)
    self:GetParent().text:SetText(self:GetText())
    EditBox_UpdateHeight(self)
end

---@param self table
---@param width number
---@param height number
local function EditBox_OnSizeChanged(self, width, height)
    EditBox_UpdateHeight(self)
end

local LJOptions = LibStub("LibJayOptions")
---@param self table
local function EditBox_OnEditFocusGained(self)
    LJOptions:SetFocus(self)
    self:GetParent().count:Show()
end

---@param self table
local function EditBox_OnEditFocusLost(self)
    LJOptions:ClearFocus()
    self:HighlightText(0, 0)
    self:GetParent().count:Hide()
end

local IsAltKeyDown = IsAltKeyDown
---@param self table
---@param key string
local function EditBox_OnKeyDown(self, key)
    if key == "ENTER" and not IsAltKeyDown() then
        EditBox_OnEnterPressed(self)
    end
end

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

---@param self table
---@param width number
---@param height number
local function OnSizeChanged(self, width, height)
    self.width = self.width or 0
    if self.width ~= width then
        self.width = width
        self.callbacks:TriggerEvent("OnWidthChanged", self, width)
    end
    self.height = self.height or 0
    if self.height ~= height then
        self.height = height
        self.callbacks:TriggerEvent("OnHeightChanged", self, height)
    end
end

---@param self table
---@param button string
---@param down boolean
local function OnClick(self, button, down)
    local editBox = self.editBox
    if editBox:IsShown() then
        editBox:SetFocus()
        editBox:HighlightText()
    end
end

---@param self table
local function OnEnable(self) self.editBox:Enable() end

---@param self table
local function OnDisable(self) self.editBox:Disable() end

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

    self.count = self.count or self:CreateFontString()
    self.count:SetDrawLayer("OVERLAY")
    self.count:SetParent(self)
    self.count:ClearAllPoints()
    self.count:SetPoint("BOTTOMLEFT", self, "BOTTOM", -5, 6)
    self.count:SetFontObject("GameFontNormalSmall")
    self.count:Hide()

    self.text = self.text or self:CreateFontString()
    self.text:SetDrawLayer("OVERLAY")
    self.text:SetParent(self)
    self.text:ClearAllPoints()
    self.text:SetPoint("LEFT", self, "CENTER", 5, 0)
    self.text:SetPoint("RIGHT", -5, 0)
    self.text:SetFontObject("GameFontNormalSmall")

    self.editBox = self.editBox or CreateFrame("EditBox")
    self.editBox:SetParent(self)
    self.editBox:SetFontObject("GameFontNormalSmall")
    self.editBox:ClearAllPoints()
    self.editBox:SetPoint("BOTTOMLEFT", self.count, "BOTTOMRIGHT", 2, -2)
    --[[ self.editBox:SetPoint("LEFT", self, "CENTER", 5, 0) ]]
    self.editBox:SetPoint("RIGHT", -5, 0)
    self.editBox:SetAutoFocus(false)
    self.editBox:SetTextInsets(4, 4, 4, 4)
    self.editBox:EnableMouse(true)

    self.editBox:SetBackdrop({
        bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        tile = false,
        tileEdge = false,
        tileSize = 16,
        edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    self.editBox:SetBackdropColor(0, 0, 0, 0.5)
    self.editBox:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    self.editBox:SetScript("OnEscapePressed", EditBox_OnEscapePressed)
    self.editBox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
    self.editBox:SetScript("OnTextChanged", EditBox_OnTextChanged)
    self.editBox:SetScript("OnTextSet", EditBox_OnTextSet)
    self.editBox:SetScript("OnSizeChanged", EditBox_OnSizeChanged)
    self.editBox:SetScript("OnEditFocusGained", EditBox_OnEditFocusGained)
    self.editBox:SetScript("OnEditFocusLost", EditBox_OnEditFocusLost)

    EditBox_UpdateHeight(self.editBox)

    self:SetScript("OnEnter", OnEnter)
    self:SetScript("OnLeave", OnLeave)
    self:SetScript("OnSizeChanged", OnSizeChanged)
    self:SetScript("OnClick", OnClick)
    self:SetScript("OnEnable", OnEnable)
    self:SetScript("OnDisable", OnDisable)
end

function mixin:OnAcquire()
    self:SetHeight(20)
    self:SetIcon()
    self:SetText()
    self:SetValue()
    self:SetReadOnly()
    self:SetMultiLine(true)
    self:SetJustifyH("LEFT")
    self:SetMaxLetters()

    local editBox = self.editBox
    editBox:SetText(" ")
    editBox:SetFrameStrata("DIALOG")
end

function mixin:OnRelease()
    self.callbacks:Wipe()
    self.editBox:ClearFocus()
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

---@param value string
function mixin:SetValue(value)
    value = value or ""
    local editBox = self.editBox
    if value ~= editBox:GetText() then editBox:SetText(value) end
end

---@return string value
function mixin:GetValue() return self.editBox:GetText() end

---@return boolean hasFocus
function mixin:HasFocus() return self.editBox:HasFocus() end

function mixin:ClearFocus() self.editBox:ClearFocus() end

---@param state boolean
function mixin:SetReadOnly(state)
    local editBox, text = self.editBox, self.text
    if state then
        if not text:IsShown() then text:Show() end
        if editBox:IsShown() then editBox:Hide() end
        self:SetPushedTextOffset(0, 0)
    else
        if text:IsShown() then text:Hide() end
        if not editBox:IsShown() then editBox:Show() end
        self:SetPushedTextOffset(1.6, -1.6)
    end
end

---@param state boolean
function mixin:SetMultiLine(state)
    if not state then
        state = false
    else
        state = true
    end
    local editBox = self.editBox
    if editBox:IsMultiLine() ~= state then
        editBox:SetMultiLine(state)
        if not state then
            editBox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
            editBox:SetScript("OnKeyDown", nil)
        else
            editBox:SetScript("OnEnterPressed", nil)
            editBox:SetScript("OnKeyDown", EditBox_OnKeyDown)
        end
    end
end

---@param justifyH string | "\"LEFT\"" | "\"CENTER\"" | "\"RIGHT\""
function mixin:SetJustifyH(justifyH)
    local editBox, text = self.editBox, self.text
    if editBox:GetJustifyH() ~= justifyH then editBox:SetJustifyH(justifyH) end
    if text:GetJustifyH() ~= justifyH then text:SetJustifyH(justifyH) end
end

---@param maxLetters number
function mixin:SetMaxLetters(maxLetters)
    maxLetters = maxLetters or 255
    local editBox = self.editBox
    if editBox:GetMaxLetters() ~= maxLetters then
        editBox:SetMaxLetters(maxLetters)
    end
end
