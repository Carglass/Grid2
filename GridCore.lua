--[[
Created by Grid2 original authors, modified by Michael
--]]

--{{{ Initialization

Grid2 = LibStub("AceAddon-3.0"):NewAddon("Grid2", "AceEvent-3.0", "AceConsole-3.0")

Grid2.versionstring = "Grid2 v"..GetAddOnMetadata("Grid2", "Version")

Grid2.debugFrame = Grid2DebugFrame or ChatFrame1
function Grid2:Debug(s, ...)
	if self.debugging then
		if s:find("%", nil, true) then
			Grid2:Print(self.debugFrame, "DEBUG", self.name, s:format(...))
		else
			Grid2:Print(self.debugFrame, "DEBUG", self.name, s, ...)
		end
	end
end

local media = LibStub("LibSharedMedia-3.0", true)

--{{{ AceDB defaults
Grid2.defaults = {
	profile = {
		debug = false,
	    versions = {},
		indicators = {},
		statuses = {},
		statusMap =  {},
	}
}
--}}}

--{{{
Grid2.setupFunc = {} -- type setup functions for non-unique objects: "buff" statuses / "icon" indicators / etc.
--}}}

--{{{ AceTimer-3.0, embedded upon use
function Grid2:ScheduleRepeatingTimer(...)
	LibStub("AceTimer-3.0"):Embed(Grid2)
	return self:ScheduleRepeatingTimer(...)
end

function Grid2:ScheduleTimer(...)
	LibStub("AceTimer-3.0"):Embed(Grid2)
	return self:ScheduleTimer(...)
end

function Grid2:CancelTimer(...)
	LibStub("AceTimer-3.0"):Embed(Grid2)
	return self:CancelTimer(...)
end
--}}}

--{{{  Module prototype
local modulePrototype = {}
modulePrototype.core = Grid2
modulePrototype.Debug = Grid2.Debug

function modulePrototype:OnInitialize()
	if not self.db then
		self.db = self.core.db:RegisterNamespace(self.moduleName or self.name, self.defaultDB or {} )
	end
	self.debugFrame = Grid2.debugFrame
	self.debugging = self.db.profile.debug
	if self.OnModuleInitialize then self:OnModuleInitialize() end
	self:Debug("OnInitialize")
end

function modulePrototype:OnEnable()
	if self.OnModuleEnable then self:OnModuleEnable() end
end

function modulePrototype:OnDisable()
	if self.OnModuleDisable then self:OnModuleDisable() end
end

function modulePrototype:OnUpdate()
	if self.OnModuleUpdate then self:OnModuleUpdate() end
end

Grid2:SetDefaultModulePrototype(modulePrototype)
Grid2:SetDefaultModuleLibraries("AceEvent-3.0")
--}}}

--{{{  Modules management
function Grid2:EnableModules()
	for _,module in self:IterateModules() do
		module:OnEnable()
	end
end

function Grid2:DisableModules()
	for _,module in self:IterateModules() do
		module:OnDisable()
	end
end

function Grid2:UpdateModules()
	for _,module in self:IterateModules() do
		module:OnUpdate()
	end
end
--}}}

function Grid2:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("Grid2DB", self.defaults)

	self.debugging = self.db.profile.debug

 	local LibDualSpec = LibStub('LibDualSpec-1.0')
	if LibDualSpec then
		LibDualSpec:EnhanceDatabase(self.db, "Grid2")
	end

	self:InitializeOptions()

	self.OnInitialize= nil
end

function Grid2:OnEnable()
	media:Register("statusbar", "Gradient", "Interface\\Addons\\Grid2\\media\\gradient32x32")
	media:Register("statusbar", "Grid2 Flat", "Interface\\Addons\\Grid2\\media\\white16x16")
	media:Register("border", "Grid2 Flat", "Interface\\Addons\\Grid2\\media\\white16x16")
		
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "GroupChanged")
	self:RegisterEvent("RAID_ROSTER_UPDATE", "GroupChanged")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("UNIT_PET")
	self:RegisterEvent("UNIT_NAME_UPDATE")
	
    self.db.RegisterCallback(self, "OnProfileChanged", "ProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "ProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "ProfileChanged")

	self:LoadConfig()

	self:SendMessage("Grid_Enabled")
end

function Grid2:OnDisable()
	self:SendMessage("Grid_Disabled")
end

function Grid2:LoadConfig()
	self:UpdateDefaults()
	self:Setup()	
end

function Grid2:InitializeOptions()
	self:RegisterChatCommand("grid2", "OnChatCommand")
	self:RegisterChatCommand("gr2", "OnChatCommand")
	local optionsFrame= CreateFrame( "Frame", nil, UIParent );
	optionsFrame.name = "Grid2"
	InterfaceOptions_AddCategory(optionsFrame)
	optionsFrame:SetScript("OnShow", function (self, ...)
		if not Grid2Options then Grid2:LoadGrid2Options() end
		self:SetScript("OnShow", nil)
	end)
	self.optionsFrame = optionsFrame
	self.InitializeOptions= nil
end

function Grid2:OnChatCommand(input)
    if not Grid2Options then
		Grid2:LoadGrid2Options()
	end		
	if Grid2Options then
		Grid2Options:OnChatCommand(input)
	end	
end

function Grid2:LoadGrid2Options()
	if not IsAddOnLoaded("Grid2Options") then
		LoadAddOn("Grid2Options")
	end
	if Grid2Options then
		self:LoadOptions()
		self.LoadGrid2Options= nil
	else
		Grid2:Print("You need Grid2Options addon enabled to be able to configure Grid2.")
	end
end

function Grid2:LoadOptions() -- Hook this to load any options addon (See RaidDebuffs)
	Grid2Options:Initialize()
end

function Grid2:ProfileChanged()
	self:Debug("Loaded profile (", self.db:GetCurrentProfile(),")")
	self:DisableModules()
	self:LoadConfig()
	self:UpdateModules()
	self:EnableModules()
	if Grid2Options then
		Grid2Options:MakeOptions()
	end	
end

--{{ Misc functions
function Grid2:MediaFetch(mediatype, key, def)
	return (key and media:Fetch(mediatype, key)) or (def and media:Fetch(mediatype, def))
end

local defaultColor= {r=0,g=0,b=0,a=0}
function Grid2:MakeColor(color)
	return color or defaultColor
end

function Grid2.Dummy()
end

function Grid2:HideBlizzardRaidFrames()
	CompactRaidFrameManager:UnregisterAllEvents()
	CompactRaidFrameManager:Hide()
	CompactRaidFrameContainer:UnregisterAllEvents()
	CompactRaidFrameContainer:Hide()
end
--}}
