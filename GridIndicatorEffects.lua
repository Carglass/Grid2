-- Implements glow, blink and zoom in effects for indicators.

local indicatorPrototype = Grid2.indicatorPrototype

-- Glowing border effects
local LCG = LibStub("LibCustomGlow-1.0")

local function GetUpdate_GlowPixel(indicator)
	local funcStatus = indicator.GetCurrentStatus
	local funcFrame  = indicator.GetBlinkFrame
	local funcStart  = LCG.PixelGlow_Start
	local funcStop   = LCG.PixelGlow_Stop
	local dbx = indicator.dbx
	local color = dbx.glow_color
	local linesCount = dbx.glow_linesCount or 8
	local frequency = dbx.glow_frequency or 0.25
	local thickness = dbx.glow_thickness or 2
	local always = not not dbx.highlightAlways
	return function(self, parent, unit)
		local status, state = funcStatus(self, unit)
		local frame = funcFrame(self, parent)
		local enabled = status and (always or state=="blink")
		if enabled ~= frame.__glowEnabled then
			frame.__glowEnabled = enabled
			if enabled then
				funcStart( frame, color, linesCount, frequency, nil, thickness, 0, 0, false )
			else
				funcStop( frame )
			end
		end
		self:OnUpdate(parent, unit, status)
	end
end

local function GetUpdate_GlowAutoCast(indicator)
	local funcStatus = indicator.GetCurrentStatus
	local funcFrame  = indicator.GetBlinkFrame
	local funcStart  = LCG.AutoCastGlow_Start
	local funcStop   = LCG.AutoCastGlow_Stop
	local dbx = indicator.dbx
	local color = dbx.glow_color
	local particlesCount = dbx.glow_particlesCount or 4
	local frequency = dbx.glow_frequency or 0.12
	local particlesScale = dbx.glow_particlesScale or 1
	local always = not not dbx.highlightAlways
	return function(self, parent, unit)
		local status, state = funcStatus(self, unit)
		local frame = funcFrame(self, parent)
		local enabled = status and (always or state=="blink")
		if enabled ~= frame.__glowEnabled then
			frame.__glowEnabled = enabled
			if enabled then
				funcStart( frame, color, particlesCount, frequency, particlesScale, 0 , 0 )
			else
				funcStop( frame )
			end
		end
		self:OnUpdate(parent, unit, status)
	end
end

local function GetUpdate_GlowButton(indicator)
	local funcStatus = indicator.GetCurrentStatus
	local funcFrame  = indicator.GetBlinkFrame
	local funcStart  = LCG.ButtonGlow_Start
	local funcStop   = LCG.ButtonGlow_Stop
	local dbx = indicator.dbx
	local color = dbx.glow_color
	local frequency = dbx.glow_frequency or 0.12
	local always = not not dbx.highlightAlways
	return function(self, parent, unit)
		local status, state = funcStatus(self, unit)
		local frame = funcFrame(self, parent)
		local enabled = status and (always or state=="blink")
		if enabled ~= frame.__glowEnabled then
			frame.__glowEnabled = enabled
			if enabled then
				funcStart( frame, color, frequency )
			else
				funcStop( frame )
			end
		end
		self:OnUpdate(parent, unit, status)
	end
end

-- Zoom in/out effect, not using animation BOUNCE looping method because is bugged (generate glitches)
local function CreateScaleAnimation(frame, dbx)
	local scale  = dbx.animScale or 1.5
	local durat  = (dbx.animDuration or 0.7) / 2
	local origin = dbx.animOrigin or 'CENTER'
	local group  = frame:CreateAnimationGroup()
	local grow   = group:CreateAnimation("Scale")
	local shrink = group:CreateAnimation("Scale")
	grow:SetOrder(1)
	grow:SetOrigin(origin,0,0)
	grow:SetScale(scale,scale)
	grow:SetDuration(durat)
	shrink:SetOrder(2)
	shrink:SetOrigin(origin,0,0)
	shrink:SetScale(1/scale,1/scale)
	shrink:SetDuration(durat)
	frame.scaleAnim, group.grow, group.shrink = group, grow, shrink
	return group
end

local function GetUpdate_Scale(indicator)
	local funcStatus = indicator.GetCurrentStatus
	local funcFrame  = indicator.GetBlinkFrame
	local animOnEnabled = indicator.dbx.animOnEnabled
	return function(self, parent, unit)
		local status, state = funcStatus(self, unit)
		local frame = funcFrame(self, parent)
		local anim = frame.scaleAnim
		if status then
			if not (anim and anim:IsPlaying()) and not (animOnEnabled and frame:IsVisible()) then
				(anim or CreateScaleAnimation(frame, self.dbx)):Play()
			end
		elseif anim then
			anim:Stop()
		end
		self:OnUpdate(parent, unit, status)
	end
end

-- Blink effect
local function CreateBlinkAnimation(frame, dbx)
	local anim  = frame:CreateAnimationGroup()
	local alpha = anim:CreateAnimation("Alpha")
	anim.settings = alpha
	anim:SetLooping("REPEAT")
	alpha:SetOrder(1)
	alpha:SetFromAlpha( 1 )
	alpha:SetToAlpha( 0.1 )
	alpha:SetDuration( 1 / (dbx.blink_frequency or 2) )
	frame.blinkAnim = anim
	return anim
end

local function GetUpdate_Blink(indicator)
	local funcStatus = indicator.GetCurrentStatus
	local funcFrame  = indicator.GetBlinkFrame
	local always = not not indicator.dbx.highlightAlways
	return function(self, parent, unit)
		local status, state = funcStatus(self, unit)
		local frame = funcFrame(self, parent)
		local anim = frame.blinkAnim
		if status and (always or state=="blink") then
			(anim or CreateBlinkAnimation(frame,self.dbx)):Play()
		elseif anim then
			anim:Stop()
		end
		self:OnUpdate(parent, unit, status)
	end
end

-- Public method (overwriting the original UpdateDB defined in GridIndicator.lua)
do
	local updateFunctions = {
		[-1] = GetUpdate_Scale,
		[ 0] = GetUpdate_Blink,
		[ 1] = GetUpdate_GlowPixel,
		[ 2] = GetUpdate_GlowAutoCast,
		[ 3] = GetUpdate_GlowButton,
	}
	function indicatorPrototype:UpdateDB()
		if self.LoadDB then
			self:LoadDB()
		end
		if self.GetBlinkFrame then
			local typ = self.dbx.highlightType
			self.Update = typ and updateFunctions[typ](self) or indicatorPrototype.Update
		elseif not rawget(self, "Update") then
			self.Update = indicatorPrototype.Update -- speed optimization
		end
	end
end
