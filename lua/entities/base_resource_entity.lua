AddCSLuaFile()
ENT.Type = "anim"
local baseClass
if WireLib and GAMEMODE.IsSandboxDerived then
	baseClass = baseclass.Get( "base_wire_entity" )
else
	baseClass = baseclass.Get( "base_anim" )
end

ENT.Category        = "Spacebuild"
ENT.PrintName 		= "Base Resource Entity"
ENT.Author 			= "SnakeSVx"
ENT.Contact 		= ""
ENT.Purpose 		= "Testing"
ENT.Instructions 	= ""

ENT.Spawnable = false
ENT.AdminOnly = false

local SB = SPACEBUILD
local leakSound = "PhysicsCannister.ThrusterLoop"

function ENT:Initialize()
	baseClass.Initialize(self)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		-- Wake the physics object up. It's time to have fun!
		local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:Wake()
		end
	end
	self:registerDevice()
end

function ENT:registerDevice()
	SB:registerDevice(self, SB.RDTYPES.STORAGE)
end

function ENT:OnRemove()
	baseClass.OnRemove(self)
	SB:removeDevice(self)
	self:StopSound(leakSound)
end

if SERVER then

	function ENT:Repair()
		SB.util.damage.repair(self)
	end

	function ENT:OnTakeDamage(DmgInfo)
		SB.util.damage.doDamage(self, DmgInfo:GetDamage())
	end

	function ENT:OnRestore()
		baseClass.OnRestore(self)
		SB:onRestore(self)
	end

	function ENT:PreEntityCopy()
		baseClass.PreEntityCopy(self)
		SB:buildDupeInfo(self)
	end

	function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
		baseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
		SB:applyDupeInfo(Ent, CreatedEntities)
	end

	function ENT:leakEnergy(energy)
		local zapme = SB.util.damage.zapArea
		if energy > 0 then
			local waterlevel = 0
			if self.WaterLevel2 then
				waterlevel = self:WaterLevel2()
			else
				waterlevel = self:WaterLevel()
			end
			if (waterlevel > 0) then
				if zapme then
					zapme(self:GetPos(), 1)
				end
				local tmp = ents.FindInSphere(self:GetPos(), 600)
				for _, ply in ipairs(tmp) do
					if (ply:IsPlayer()) then
						if (ply:WaterLevel() > 0) then
							if zapme then
								zapme(ply:GetPos(), 1)
							end
							ply:TakeDamage((energy / 100), 0)
						end
					end
				end
			else
				if (math.random(1, 10) < 2) then
					if zapme then
						zapme(self:GetPos(), 1)
					end
				end
			end
		end
	end

	function ENT:leakGas(gas)
		if gas > 0 then
			self:EmitSound(leakSound)
		else
			self:StopSound(leakSound)
		end
	end

	function ENT:performLeakCheck()
		local performance, maxLeakPercentage, leakEnergy,leakGas = SB.util.damage.performance(self, 10, 90), 0, 0, 0
		if performance < 10 then
			maxLeakPercentage = 60
		elseif performance < 30 then
			maxLeakPercentage = 30
		elseif performance < 50 then
			maxLeakPercentage = 10
		end
		if maxLeakPercentage > 0 then
			for k, v in pairs(self.rdobject:getResources()) do
				if v:getMaxAmount() > 0 and self:getResourceAmount(k) > 0 then
					local info, consume, notconsumed = v:getResourceInfo(), math.Round(math.random(0, self:getResourceAmount(k) *(maxLeakPercentage/100)))
					if consume > 0 then
						notconsumed = self:consumeResource(k, consume)
						consume = consume - notconsumed
						if info:hasAttribute(SB.RESTYPES.ENERGY) then
							leakEnergy = leakEnergy + consume
						end
						if info:hasAttribute(SB.RESTYPES.GAS) then
						    if self.environment then
								self.environment.convertResource("vacuum", k, consume)
							end
							leakGas = leakGas + consume
						end
					end
				end
			end
		end
		self:leakEnergy(leakEnergy)
		self:leakGas(leakGas)
	end

	function ENT:Think()
		self:performLeakCheck()

		self:NextThink(CurTime() + 1)
		return true
	end

end

if CLIENT then

	function ENT:Draw()
		baseClass.Draw(self)
		SB:drawBeams(self)
		self:drawScreen()
	end

	function ENT:drawScreen()
		-- do nothing
	end

end

function ENT:addResource(resource, maxamount, defaultvalue)
	return self.rdobject:addResource(resource, maxamount, defaultvalue)
end

function ENT:consumeResource(resource, amount)
	return self.rdobject:consumeResource(resource, amount)
end

function ENT:supplyResource(resource, amount)
	return self.rdobject:supplyResource(resource, amount)
end

function ENT:getResourceAmount(resource)
	return self.rdobject:getResourceAmount(resource)
end


function ENT:getMaxResourceAmount(resource)
	return self.rdobject:getMaxResourceAmount(resource)
end


