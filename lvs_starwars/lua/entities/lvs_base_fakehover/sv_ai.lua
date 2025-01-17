
function ENT:OnCreateAI()
	self:StartEngine()
end

function ENT:OnRemoveAI()
	self:StopEngine()
end

function ENT:RunAI()
	local RangerLength = 25000

	local Target = self:AIGetTarget()

	local StartPos = self:LocalToWorld( self:OBBCenter() )

	local TraceFilter = self:GetCrosshairFilterEnts()

	local Front = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:GetForward() * RangerLength } )
	local FrontLeft = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,15,0) ):Forward() * RangerLength } )
	local FrontRight = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,-15,0) ):Forward() * RangerLength } )
	local FrontLeft1 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,60,0) ):Forward() * RangerLength } )
	local FrontRight1 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,-60,0) ):Forward() * RangerLength } )
	local FrontLeft2 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,85,0) ):Forward() * RangerLength } )
	local FrontRight2 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,-85,0) ):Forward() * RangerLength } )

	local TargetPos = (Front.HitPos + FrontLeft.HitPos + FrontRight.HitPos + FrontLeft1.HitPos + FrontRight1.HitPos + FrontLeft2.HitPos + FrontRight2.HitPos) / 7

	self._AIFireInput = false

	if IsValid( self:GetHardLockTarget() ) then
		TargetPos = self:GetHardLockTarget():GetPos()
		if self:AITargetInFront( self:GetHardLockTarget(), 65 ) then
			self._AIFireInput = true
		end
	else
		if IsValid( Target ) then
			TargetPos = Target:LocalToWorld( Target:OBBCenter() )

			if self:AITargetInFront( Target, 65 ) then
				self._AIFireInput = true
			end
		end
	end

	local DistToTarget = (TargetPos - self:GetPos()):Length()
	local LocalMove = self:WorldToLocal( TargetPos )

	if DistToTarget < 1000 then
		LocalMove.x = -1
	end

	if DistToTarget > 800 and DistToTarget < 1200 then
		LocalMove.y = math.sin( CurTime() * 1.5 + self:EntIndex() * 1337 ) * 10
	end

	self:SetMove( LocalMove.x, LocalMove.y )

	local pod = self:GetDriverSeat()

	if not IsValid( pod ) then return end

	local AimVector = (TargetPos - pod:LocalToWorld( Vector(0,0,33) )):GetNormalized()

	self:SetAIAimVector( AimVector )

	self:SetSteerTo( AimVector:Angle().y )
end

function ENT:OnAITakeDamage( dmginfo )
	local attacker = dmginfo:GetAttacker()

	if not IsValid( attacker ) then return end

	if not self:AITargetInFront( attacker, IsValid( self:AIGetTarget() ) and 120 or 45 ) then
		self:SetHardLockTarget( attacker )
	end
end

function ENT:SetHardLockTarget( target )
	self._HardLockTarget =  target
	self._HardLockTime = CurTime() + 4
end

function ENT:GetHardLockTarget()
	if (self._HardLockTime or 0) < CurTime() then return NULL end

	return self._HardLockTarget
end
