include("shared.lua")

function ENT:LVSHudPaint( X, Y, ply )
	local R = 100
	surface.DrawCircle( X * 0.5, Y * 0.5, R, Color( 255, 255, 255 ) )

	surface.DrawCircle( X * 0.5 + self:GetSteer().x * R, Y * 0.5 + self:GetSteer().y * R, 5, Color( 255, 255, 255 ) )
end

function ENT:LVSCalcViewFirstPerson( view, ply )
	return view
end

function ENT:LVSCalcViewThirdPerson( view, ply )
	view.origin = self:LocalToWorld( Vector(-500,0,250) )
	view.angles = self:GetAngles()

	return view
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:DrawTranslucent()
end

function ENT:Initialize()
end

function ENT:Think()
end

function ENT:OnRemove()
end

function ENT:GetCrosshairFilterEnts()
	if not istable( self.CrosshairFilterEnts ) then
		self.CrosshairFilterEnts = {self}

		-- lets ask the server to build the filter for us because it has access to constraint.GetAllConstrainedEntities() 
		net.Start( "lvs_player_request_filter" )
			net.WriteEntity( self )
		net.SendToServer()
	end

	return self.CrosshairFilterEnts
end