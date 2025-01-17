
ENT.Base = "lvs_base"

ENT.PrintName = "[LVS] Base Fighter Plane"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

ENT.MaxVelocity = 2500
ENT.MaxPerfVelocity = 1500
ENT.MaxThrust = 250

ENT.ThrottleRateUp = 0.6
ENT.ThrottleRateDown = 0.3

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxSlipAnglePitch = 20
ENT.MaxSlipAngleYaw = 10

function ENT:SetupDataTables()
	self:CreateBaseDT()

	self:AddDT( "Vector", "Steer" )
	self:AddDT( "Vector", "AIAimVector" )
	self:AddDT( "Float", "NWThrottle" )
	self:AddDT( "Float", "MaxThrottle" )
	self:AddDT( "Float", "LandingGear" )

	if SERVER then
		self:SetLandingGear( 1 )
		self:SetMaxThrottle( 1 )
	end
end

function ENT:PlayerDirectInput( ply, cmd )
	local Pod = self:GetDriverSeat()

	local Delta = FrameTime()

	local KeyLeft = ply:lvsKeyDown( "-ROLL" )
	local KeyRight = ply:lvsKeyDown( "+ROLL" )
	local KeyPitchUp = ply:lvsKeyDown( "+PITCH" )
	local KeyPitchDown = ply:lvsKeyDown( "-PITCH" )

	local MouseX = cmd:GetMouseX()
	local MouseY = cmd:GetMouseY()

	if ply:lvsKeyDown( "FREELOOK" ) and not Pod:GetThirdPersonMode() then
		MouseX = 0
		MouseY = 0
	else
		ply:SetEyeAngles( Angle(0,90,0) )
	end

	local SensX, SensY, ReturnDelta = ply:lvsMouseSensitivity()

	if KeyPitchDown then MouseY = 10 * ReturnDelta end
	if KeyPitchUp then MouseY = -10 * ReturnDelta end

	local Input = Vector( MouseX * 0.4 * SensX, MouseY * SensY, 0 )

	local Cur = self:GetSteer()

	local Rate = Delta * 3 * ReturnDelta

	local New = Vector(Cur.x, Cur.y, 0) - Vector( math.Clamp(Cur.x * Delta * 5 * ReturnDelta,-Rate,Rate), math.Clamp(Cur.y * Delta * 5 * ReturnDelta,-Rate,Rate), 0)

	local Target = New + Input * Delta * 0.8

	local Fx = math.Clamp( Target.x, -1, 1 )
	local Fy = math.Clamp( Target.y, -1, 1 )

	local TargetFz = (KeyLeft and 1 or 0) - (KeyRight and 1 or 0)
	local Fz = Cur.z + math.Clamp(TargetFz - Cur.z,-Rate * 3,Rate * 3)

	local F = Cur + (Vector( Fx, Fy, Fz ) - Cur) * math.min(Delta * 100,1)

	self:SetSteer( F )
end

function ENT:PlayerMouseAim( ply, cmd )
	if CLIENT then return end

	local Pod = self:GetDriverSeat()

	local PitchUp = ply:lvsKeyDown( "+PITCH" )
	local PitchDown = ply:lvsKeyDown( "-PITCH" )
	local YawRight = ply:lvsKeyDown( "+YAW" )
	local YawLeft = ply:lvsKeyDown( "-YAW" )
	local RollRight = ply:lvsKeyDown( "+ROLL" )
	local RollLeft = ply:lvsKeyDown( "-ROLL" )

	local FreeLook = ply:lvsKeyDown( "FREELOOK" )

	local EyeAngles = Pod:WorldToLocalAngles( ply:EyeAngles() )

	if FreeLook then
		if isangle( self.StoredEyeAngles ) then
			EyeAngles = self.StoredEyeAngles
		end
	else
		self.StoredEyeAngles = EyeAngles
	end

	local OverridePitch = 0
	local OverrideYaw = 0
	local OverrideRoll = (RollRight and 1 or 0) - (RollLeft and 1 or 0)

	if PitchUp or PitchDown then
		EyeAngles = self:GetAngles()

		self.StoredEyeAngles = Angle(EyeAngles.p,EyeAngles.y,0)

		OverridePitch = (PitchUp and 1 or 0) - (PitchDown and 1 or 0)
	end

	if YawRight or YawLeft then
		EyeAngles = self:GetAngles()

		self.StoredEyeAngles = Angle(EyeAngles.p,EyeAngles.y,0)

		OverrideYaw = (YawRight and 1 or 0) - (YawLeft and 1 or 0) 
	end

	self:ApproachTargetAngle( EyeAngles, OverridePitch, OverrideYaw, OverrideRoll, FreeLook )
end

function ENT:CalcThrottle( ply, cmd )
	if CLIENT then return end

	local Delta = FrameTime()

	local ThrottleUp =  ply:lvsKeyDown( "+THROTTLE" ) and self.ThrottleRateUp or 0
	local ThrottleDown = ply:lvsKeyDown( "-THROTTLE" ) and -self.ThrottleRateDown or 0

	local Throttle = (ThrottleUp + ThrottleDown) * Delta

	self:SetThrottle( self:GetThrottle() + Throttle )
end

function ENT:SetThrottle( NewThrottle )
	if self:GetEngineActive() then
		self:SetNWThrottle( math.Clamp(NewThrottle,0,self:GetMaxThrottle()) )
	else
		self:SetNWThrottle( 0 )
	end
end

function ENT:GetThrottle()
	if self:GetEngineActive() then
		return self:GetNWThrottle()
	else
		return 0
	end
end

function ENT:StartCommand( ply, cmd )
	if self:GetDriver() ~= ply then return end

	if SERVER and not self.WheelAutoRetract then
		local KeyJump = ply:lvsKeyDown( "VSPEC" )

		if self._lvsOldKeyJump ~= KeyJump then
			self._lvsOldKeyJump = KeyJump
			if KeyJump then
				self:ToggleLandingGear()
				self:PhysWake()
			end
		end
	end

	if ply:lvsMouseAim() then
		self:PlayerMouseAim( ply, cmd )
	else
		self:PlayerDirectInput( ply, cmd )
	end

	self:CalcThrottle( ply, cmd )
end

function ENT:FreezeStability()
	self._StabilityFrozen = CurTime() + 2
end

function ENT:GetStability()
	if (self._StabilityFrozen or 0) > CurTime() then
		return 1, 0, self.MaxPerfVelocity
	end

	local ForwardVelocity = self:WorldToLocal( self:GetPos() + self:GetVelocity() ).x

	local Stability = math.Clamp(ForwardVelocity / self.MaxPerfVelocity,0,1) ^ 2
	local InvStability = 1 - Stability

	return Stability, InvStability, ForwardVelocity
end

function ENT:GetThrustStrenght()
	local ForwardVelocity = self:WorldToLocal( self:GetPos() + self:GetVelocity() ).x

	return (self.MaxVelocity - ForwardVelocity) * self:GetThrottle() / self.MaxVelocity
end
