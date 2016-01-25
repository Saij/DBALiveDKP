local addonName = "DBALiveDKP"

local DBALiveDKP = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

DBALiveDKP.addonTitle = GetAddOnInfo(addonName, "Title")
DBALiveDKP.addonVersion = GetAddOnMetadata(addonName, "X-Curse-Packaged-Version") or GetAddOnMetadata(addonName, "Version")
DBALiveDKP.addonName = addonName

local slashHandlers = {
}

local defaults = {
    profile = {
    }
}

DBALiveDKP.classColors = setmetatable({}, {__index = function(t, k)
    if type(k) == "nil" then k = "" end

    -- Select class color
    -- Try to translate localized classname back to Blizzard internal class
    local color = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[k])
    color = color or (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[L[k]])
    color = color or RAID_CLASS_COLORS[k]
    color = color or RAID_CLASS_COLORS[L[k]]
    color = color or GRAY_FONT_COLOR
    
    rawset(t, k, color)
    return color
end })

DBALiveDKP.classColorFormatters = setmetatable({}, {__index = function(t, k)
    if type(k) == "nil" then k = "" end
    local color = DBALiveDKP.classColors[k]
    local formatter = string.format("|cff%02x%02x%02x%%s|r", color.r * 255, color.g * 255, color.b * 255)
    rawset(t, k, formatter)
    return formatter
end })

function DBALiveDKP:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New(addonName .. "DB", defaults, true)
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    self:InitDKPData()

    self:RegisterChatCommand("livedkp", function(input)
		if not input or strtrim(input) == "" then
			DBALiveDKP:ToggleListWindow()
		else
			local argument = self:GetArgs(input)
			local handler = argument and slashHandlers[string.lower(argument)]

			if handler then
				handler()
			else
                self:Print("WRONG COMMAND")
				-- configDialog:Open(addonName)
			end
		end
	end)
end

function DBALiveDKP:OnEnable()
    if CUSTOM_CLASS_COLORS then
        CUSTOM_CLASS_COLORS:RegisterCallback("ClassColorsChanged", self)
    end
end

function DBALiveDKP:OnDisable()
    if CUSTOM_CLASS_COLORS then
        CUSTOM_CLASS_COLORS:UnregisterCallback("ClassColorsChanged", self)
    end
end

function DBALiveDKP:ClassColorsChanged()
    wipe(DBALiveDKP.classColors)
    wipe(DBALiveDKP.classColorFormatters)
end

function DBALiveDKP:RefreshConfig()
    self:RestoreListWindowPosition()
end

function DBALiveDKP:SetDKPData(key, value)
    if not self.db.profile.dkp then
        self.db.profile.dkp = {}
    end

    self.db.profile.dkp[key] = value
end

function DBALiveDKP:GetDKPData(key, default)
    if not self.db.profile.dkp then
        self:SetDKPData(key, default)
        return default
    end

    if not self.db.profile.dkp[key] then
        self:SetDKPData(key, default)
        return default
    end

    return self.db.profile.dkp[key]
end

function DBALiveDKP:InitDKPData()
    local lastLocalChange = self:GetDKPData("lastLocalChange", 0)
    local lastOnlineChange = 0

    if DKPInfo and DKPInfo.timestamp then
        lastOnlineChange = tonumber(DKPInfo.timestamp)
    end

    -- Multitable Support
    if multiTable and lastLocalChange <= lastOnlineChange then
        currentMultiTable = nil
        mtable = self:GetDKPData("multiTable", {})
        wipe(mtable)

        for index, entry in ipairs(multiTable) do
            for name, tableEntry in pairs(entry) do
                if not currentMultiTable then
                    currentMultiTable = name
                end
                mtable[name] = tableEntry
            end
        end

        self:SetDKPData("multiTable", mtable)
        self:SetDKPData("currentMultiTable", currentMultiTable)
    end

    -- Update DKP Points
    if gdkp and gdkp.players and lastLocalChange <= lastOnlineChange then
        dkpData = self:GetDKPData("dkpData", {})
        wipe(dkpData)

        for player, data in pairs(gdkp.players) do
            playerData = {
                ["class"] = data.class,
                ["multiTables"] = {}
            }

            multiTable = self:GetDKPData("multiTable", {})
            for mtable, _ in pairs(multiTable) do
                playerData.multiTables[mtable] = {
                    ["earned"] = data[mtable .. "_earned"],
                    ["spent"] = data[mtable .. "_spent"],
                    ["adjust"] = data[mtable .. "_adjust"],
                    ["current"] = data[mtable .. "_current"]
                }
            end

            dkpData[player] = playerData
        end

        self:SetDKPData("dkpData", dkpData)
    end
end