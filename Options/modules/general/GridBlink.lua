local L = Grid2Options.L
local Grid2Blink = Grid2:GetModule("Grid2Blink")

Grid2Options:AddGeneralOptions( "Misc", "blink", {
	effect = {
		type = "select",
		name = L["Blink effect"],
		desc = L["Select the type of Blink effect used by Grid2."],
		order = 10,
		get = function ()
			return Grid2Blink.db.profile.type
		end,
		set = function (_, v)
			local f= Grid2Blink.db.profile.type=="None" or v=="None"
			Grid2Blink.db.profile.type = v
			Grid2Blink:Update()
			if f then
				Grid2Options:MakeStatusesOptions()
			end			
		end,
		values= {["None"] = L["None"], ["Blink"] = L["Blink"], ["Flash"] = L["Flash"]},
	},
	frequency = {
		type = "range",
		name = L["Blink Frequency"],
		desc = L["Adjust the frequency of the Blink effect."],
		disabled = function () return Grid2Blink.db.profile.type == "None" end,
		min = 1,
		max = 10,
		step = .5,
		get = function ()
			return Grid2Blink.db.profile.frequency / 2
		end,
		set = function (_, v)
			Grid2Blink.db.profile.frequency = v * 2
			Grid2Blink:Update()
		end,
	},
})
