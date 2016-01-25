local DBALiveDKP = LibStub("AceAddon-3.0"):GetAddon("DBALiveDKP")
local L = LibStub("AceLocale-3.0"):GetLocale("DBALiveDKP", true)

local ROW_HEIGHT = 20
local MAX_ROWS = 30
local COLUMN_GAP = 5

local BUTTON_WIDTH = 120
local BUTTON_HEIGHT = 22

local NAME_LABEL_WIDTH = 140
local CLASS_LABEL_WIDTH = 100
local DKP_LABEL_WIDTH = 35

local listWindow
local sortButtons = {}

local sortMethods = {
    ["character"] = function (guid1, guid2, reverse) end,
    ["class"] = function (guid1, guid2, reverse) end,
    ["dkp"] = function (guid1, guid2, reverse) end
}

local function SortButtonAction(frame)
    PlaySound("gsTitleOptionExit")
    DBALiveDKP:ToggleListWindowSortMethod(frame.sortMethod)
end

function DBALiveDKP:UpdateListWindowDKPList()
end

function DBALiveDKP:ToggleListWindowSortMethod(sortMethod)
    if not (sortMethod and sortMethods[sortMethod]) then
        sortMethod = "character"
    end

    if sortMethod == (self.db.profile.sortMethod or "character") then
        self.db.profile.sortReverse = not self.db.profile.sortReverse
    else
        self.db.profile.sortMethod = sortMethod
        self.db.profile.sortReverse = nil
    end

    self:UpdateListWindowSortButtons()
    self:UpdateListWindowDKPList()
end

function DBALiveDKP:RestoreListWindowPosition()
    if listWindow then
        listWindow:ClearAllPoints()
        listWindow:SetPoint("CENTER", UIParent)

        local opts = self.db.profile.frameopts
        if opts then
            listWindow:SetPoint(opts.anchorFrom or "TOPLEFT", UIParent, opts.anchorTo or "TOPLEFT", opts.offsetX or 0, opts.offsetY or 0)
        else
            listWindow:SetPoint("CENTER", UIParent)
        end
    end
end

function DBALiveDKP:UpdateListWindowSortButtons()
    local sortMethod = self.db.profile.sortMethod
    if not (sortMethod and sortMethods[sortMethod]) then
        sortMethod = "character"
    end
    local sortReverse = self.db.profile.sortReverse

    for i = 1, #sortButtons do
        local button = sortButtons[i]
        local arrow = button.arrow
        if button.sortMethod == sortMethod then
            button:SetNormalFontObject(GameFontHighlight)
            if not arrow then
                arrow = button:CreateTexture(nil, "ARTWORK")
                arrow:SetWidth(9)
                arrow:SetHeight(8)
                arrow:SetPoint("LEFT", button:GetFontString(), "RIGHT", 3, -2)
                arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
                button.arrow = arrow
            end
            if sortReverse then
                arrow:SetTexCoord(0, 0.5625, 1.0, 0)
            else
                arrow:SetTexCoord(0, 0.5625, 0, 1.0)
            end
            arrow:Show()
        else
            button:SetNormalFontObject(GameFontNormal)
            if arrow then
                arrow:Hide()
            end
        end
    end
end

function DBALiveDKP:SaveListWindowPosition()
    if listWindow then
        local opts = self.db.profile.frameopts
        if not opts then
            opts = {}
            self.db.profile.frameopts = opts
        end

        local anchorFrom, _, anchorTo, offsetX, offsetY = listWindow:GetPoint()
        opts.anchorFrom = anchorFrom
        opts.anchorTo = anchorTo
        opts.offsetX = offsetX
        opts.offsetY = offsetY
    end
end

function DBALiveDKP:SetCurrentMultiTable(value)
    self:SetDKPData("currentMultiTable", value)
	self:UpdateListWindowDKPList()
end

function DBALiveDKP:ToggleListWindow()
    if not listWindow then
    	local scrollBGFrameHeight = -(49 + 8 + ROW_HEIGHT * MAX_ROWS)

        listWindow = CreateFrame("Frame", "DBALiveDKP_ListWindow", UIParent, "UIPanelDialogTemplate")
        listWindow:Hide()

        listWindow.title:SetText(L["LIST_WINDOW_TITLE"])

        listWindow:EnableMouse(true)
        listWindow:SetMovable(true)
        listWindow:SetClampedToScreen(true)

        listWindow:SetFrameStrata("MEDIUM")
        listWindow:SetToplevel(true)

        listWindow:SetWidth(380)
        listWindow:SetHeight(scrollBGFrameHeight * -1 + 53)

        listWindow:SetScript("OnShow", function() 
        	PlaySound("igCharacterInfoOpen")
			DBALiveDKP:RestoreListWindowPosition()
			DBALiveDKP:UpdateListWindowSortButtons()
			DBALiveDKP:UpdateListWindowDKPList()
		end)

        listWindow:SetScript("OnHide", function() 
        	PlaySound("igCharacterInfoClose")
            CloseDropDownMenus()
        end)

        local titleButton = CreateFrame("Frame", nil, listWindow)
        titleButton:SetPoint("TOPLEFT", DBALiveDKP_ListWindowTitleBG)
        titleButton:SetPoint("BOTTOMRIGHT", DBALiveDKP_ListWindowTitleBG)
        titleButton:SetScript("OnMouseDown", function() listWindow:StartMoving() end)
        titleButton:SetScript("OnMouseUp", function() listWindow:StopMovingOrSizing() DBALiveDKP:SaveListWindowPosition() end)
        titleButton:SetScript("OnHide", function() listWindow:StopMovingOrSizing() DBALiveDKP:SaveListWindowPosition() end)

        local sortNameButton = CreateFrame("Button", "DBALiveDKP_ListWindow_SortNameButton", listWindow, "DBALiveDKP_HeaderButtonTemplate")
        sortNameButton:SetSize(NAME_LABEL_WIDTH, BUTTON_HEIGHT)
        sortNameButton:SetPoint("TOPLEFT", 20, -26)
        sortNameButton:SetText(L["LIST_WINDOW_COL_NAME"])
        sortNameButton.sortMethod = "character"
        sortNameButton:SetScript("OnClick", SortButtonAction)
        tinsert(sortButtons, sortNameButton)

        local sortClassButton = CreateFrame("Button", "DBALiveDKP_ListWindow_SortClassButton", listWindow, "DBALiveDKP_HeaderButtonTemplate")
        sortClassButton:SetSize(CLASS_LABEL_WIDTH + ROW_HEIGHT + COLUMN_GAP, BUTTON_HEIGHT)
        sortClassButton:SetPoint("TOPLEFT", sortNameButton, "TOPRIGHT", COLUMN_GAP, 0)
        sortClassButton:SetText(L["LIST_WINDOW_COL_CLASS"])
        sortClassButton.sortMethod = "class"
        sortClassButton:SetScript("OnClick", SortButtonAction)
        tinsert(sortButtons, sortClassButton)

        local sortDKPButton = CreateFrame("Button", "DBALiveDKP_ListWindow_SortDKPButton", listWindow, "DBALiveDKP_HeaderButtonTemplate")
        sortDKPButton:SetSize(DKP_LABEL_WIDTH + ROW_HEIGHT + COLUMN_GAP, BUTTON_HEIGHT)
        sortDKPButton:SetPoint("TOPLEFT", sortClassButton, "TOPRIGHT", COLUMN_GAP, 0)
        sortDKPButton:SetText(L["LIST_WINDOW_COL_DKP"])
        sortDKPButton.sortMethod = "dkp"
        sortDKPButton:SetScript("OnClick", SortButtonAction)
        tinsert(sortButtons, sortDKPButton)

        local multiTableButton = CreateFrame("Button", "DBALiveDKP_ListWindow_MultiTableDropDown", listWindow, "UIDropDownMenuTemplate")
        local multiTable = DBALiveDKP:GetDKPData("multiTable")
        local firstMultiTable
        multiTableButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
        multiTableButton:SetPoint("BOTTOMLEFT", 0, 13)
		UIDropDownMenu_Initialize(DBALiveDKP_ListWindow_MultiTableDropDown, function(self, level)
			for name, mtable in pairs(multiTable) do
                if not firstMultiTable then
                    firstMultiTable = name
                end
				info = UIDropDownMenu_CreateInfo()
                -- Seems to be an odd key - so we are implementing all alternatives
				info.text = mtable["disc"] or mtable["desc"] or name
				info.value = name
				info.func = function(self)
					UIDropDownMenu_SetSelectedID(DBALiveDKP_ListWindow_MultiTableDropDown, self:GetID())
					DBALiveDKP:SetCurrentMultiTable(self.value)
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end)
		UIDropDownMenu_SetWidth(DBALiveDKP_ListWindow_MultiTableDropDown, BUTTON_WIDTH)
		UIDropDownMenu_SetSelectedValue(DBALiveDKP_ListWindow_MultiTableDropDown, self:GetDKPData("currentMultiTable", firstMultiTable))
        listWindow.multiTableButton = multiTableButton

        local scrollBGFrame = CreateFrame("Frame", nil, listWindow, "InsetFrameTemplate3")
        scrollBGFrame:SetPoint("TOPLEFT", 10, -49)
        scrollBGFrame:SetPoint("BOTTOMRIGHT", listWindow, "TOPRIGHT", -8, scrollBGFrameHeight)

        local scrollFrame = CreateFrame("ScrollFrame", "DBALiveDKP_ScrollFrame", scrollBGFrame, "FauxScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 0, -4)
        scrollFrame:SetPoint("BOTTOMRIGHT", -23, 4)

        scrollFrame:SetScript("OnVerticalScroll", function(self, offset) FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, function() DBALiveDKP:UpdateListWindowDKPList() end) end)
        listWindow.scrollFrame = scrollFrame

        tinsert(UISpecialFrames, "DBALiveDKP_ListWindow")

        listWindow:Show()
    else
        if listWindow:IsShown() then
            listWindow:Hide()
        else
            listWindow:Show()
        end
    end
end