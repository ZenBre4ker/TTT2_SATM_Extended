--Initializing Convars
local detectiveEnabled = GetConVar("ttt_satm_detective")
local traitorEnabled = GetConVar("ttt_satm_traitor")
local satmduration = GetConVar("ttt_satm_duration")
local satmusecharges = GetConVar("ttt_satm_use_charges")
local satmteleportcharges = GetConVar("ttt_satm_teleport_charges")

--Serverside\\
if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/VGUI/ttt/icon_satm.vmt")
	resource.AddFile("sound/weapons/satm/sm_enter.wav")
	resource.AddFile("sound/weapons/satm/sm_exit.wav")
	util.AddNetworkString("SATMStartSound")
	util.AddNetworkString("SATMEndSound")
	util.AddNetworkString("SATMMessage")
end

--Clientside\\
if CLIENT then
	SWEP.PrintName = "SATM"
	SWEP.Slot = 7
	SWEP.ViewModelFOV = 70
	SWEP.ViewModelFlip = false
	SWEP.Icon = "VGUI/ttt/icon_satm"

	SWEP.EquipMenuData = {
		type = "Weapon",
		desc = "The Space and Time-Manipulator! Short SATM!\nChoose a mode with MOUSE2 \nand activate it with MOUSE1."
	}
end

--GeneralSettings\\
SWEP.Base = "weapon_tttbase"
SWEP.Spawnable = true
SWEP.AutoSpawnable = !detectiveEnabled:GetBool() && !traitorEnabled:GetBool()
SWEP.HoldType = "normal"
SWEP.AdminSpawnable = true
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Kind = !detectiveEnabled:GetBool() && !traitorEnabled:GetBool() && WEAPON_NADE || WEAPON_EQUIP2

--Damage\\
SWEP.Primary.Recoil = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Damage = 0
SWEP.Primary.Cone = 0.001
SWEP.Primary.ClipSize = satmusecharges:GetInt()
SWEP.Primary.ClipMax = satmusecharges:GetInt()
SWEP.Primary.DefaultClip = satmusecharges:GetInt()
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""

--Other\\
SWEP.InLoadoutFor = nil
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = true
SWEP.UseHands = false
SWEP.LimitedStock = true
SWEP.CanBuy = {}

if (detectiveEnabled:GetBool()) then
	table.insert(SWEP.CanBuy, ROLE_DETECTIVE)
end

if (traitorEnabled:GetBool()) then
	table.insert(SWEP.CanBuy, ROLE_TRAITOR)
end

--Sounds/Models\\
SWEP.ViewModel = "models/weapons/gamefreak/v_buddyfinder.mdl"
SWEP.WorldModel = ""
SWEP.Weight = 5

function SWEP:Initialize()
	local charges = satmusecharges:GetInt()

	self:SetClip1(charges)
	
	self.teleportcharges = satmteleportcharges:GetInt()
	self.satmmode = 1
	self.timescale = 1.5
	self:SetHoldType("normal")
	if CLIENT then
		self:AddHUDHelp("MOUSE1 to confirm.", "MOUSE2 to select mode.", false)
	end
end

function SWEP:Deploy()
	if SERVER then
		net.Start("SATMMessage")
		net.WriteInt(self.satmmode, 6)
		if self.satmmode >= 4 then net.WriteInt(self.teleportcharges, 6) end
		net.Send(self.Owner)
	end
	return self.BaseClass.Deploy(self)
end

local function ResetTimeScale()
	game.SetTimeScale(1)
	net.Start("SATMEndSound")
	net.Broadcast()
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	if not IsFirstTimePredicted() then return end

	if self.satmmode >= 4 and self.teleportcharges <= 0 then
		self:DoSATMAnimation(false)
		if SERVER then
			net.Start("SATMMessage")
			net.WriteInt(25, 6)
			net.Send(self.Owner)
		end
		return
	else
		self:DoSATMAnimation(true)
	end

	if SERVER then
		local owner = self.Owner

		if self.satmmode == 1 || self.satmmode == 2 || self.satmmode == 3 then
			timer.Remove("ResetSATM")
			game.SetTimeScale(self.timescale)
			net.Start("SATMStartSound")
			net.Broadcast()

			if self.satmmode != 3 then
				timer.Create("ResetSATM", satmduration:GetInt() * self.timescale, 1, ResetTimeScale)
			end

		elseif self.satmmode == 4 || self.satmmode == 5 then
			if !owner:OnGround() or owner:Crouching() then
				net.Start("SATMMessage")
				net.WriteInt(20, 6)
				net.Send(owner)
				return
			end

			local aliveplayers = {}

			for k, v in pairs(player.GetAll()) do
				if v:IsTerror() and v != owner and !v:Crouching() then
					table.insert(aliveplayers, v)
				end
			end

			if #aliveplayers <= 0 then
				net.Start("SATMMessage")
				net.WriteInt(15, 6)
				net.Send(owner)
				return
			end

			table.Shuffle(aliveplayers)
			local index = math.random(#aliveplayers)
			local ply = aliveplayers[index]
			table.remove(aliveplayers,index)

			local ply2 = owner

			if self.satmmode == 5 and #aliveplayers>0 then
				table.insert(aliveplayers, owner)
				index = math.random(#aliveplayers)
				ply2 = aliveplayers[index]	
			end

			if ply:IsInWorld() and ply2:IsInWorld() then
				local plypos = ply:GetPos()
				local ply2pos = ply2:GetPos()
				local plyang = ply:EyeAngles()
				local ply2ang = ply2:EyeAngles()
				ply2:SetPos(plypos)
				ply2:SetEyeAngles(plyang)
				ply:SetPos(ply2pos)
				ply:SetEyeAngles(ply2ang)
			end

			net.Start("SATMMessage")
			if self.satmmode == 4 then
				net.WriteInt(10, 6)
				net.WriteString(ply:Nick())
			elseif self.satmmode == 5 then
				net.WriteInt(11, 6)
				net.WriteString(ply:Nick())
				net.WriteString(ply2:Nick())
			end	
			net.Send(owner)

			net.Start("SATMMessage")
			net.WriteInt(12, 6)
			if ply2==owner then
				net.Send(ply)
			else
				net.Send({ply,ply2})
			end

			self.teleportcharges = self.teleportcharges - 1 
		end
	end

	self:TakePrimaryAmmo(1)
	if ( self.satmmode == 4 || self.satmmode == 5) then self.Primary.ClipSize = self.Primary.ClipSize - 1 end
end

function SWEP:SecondaryAttack()
	self:DoSATMAnimation(false)
	self.satmmode = self.satmmode + 1

	if self.satmmode > 5 then
		self.satmmode = 1
	end

	if self.satmmode == 1 then
		self.timescale = 1.5
	elseif self.satmmode == 2 then
		self.timescale = 0.5
	elseif self.satmmode == 3 then
		self.timescale = 1
	end

	if SERVER then
		net.Start("SATMMessage")
		net.WriteInt(self.satmmode, 6)
		if self.satmmode == 4 || self.satmmode == 5 then net.WriteInt(self.teleportcharges, 6) end
		net.Send(self.Owner)
	end
end

function SWEP:DoSATMAnimation(bool)
	local switchweapon = bool
	self:SetNextPrimaryFire(CurTime() + 1)
	self:SetNextSecondaryFire(CurTime() + 0.5)
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

	timer.Simple(0.3, function()
		if IsValid(self) then
			self:SendWeaponAnim(ACT_VM_IDLE)
			if switchweapon && CLIENT && IsValid(self.Owner) && self.Owner == LocalPlayer() && self.Owner:Alive() then
				RunConsoleCommand("lastinv")
			end

			if SERVER && self:Clip1() <= 0 then
				self:Remove()
			end
		end
	end)
end

function SWEP:OnRemove()
	if CLIENT && IsValid(self.Owner) && self.Owner == LocalPlayer() && self.Owner:Alive() then
		RunConsoleCommand("lastinv")
	end
end

function SWEP:OnDrop()
	if SERVER then
		if game.GetTimeScale() != 1 then
			net.Start("SATMMessage")
			net.WriteInt(0, 6)
			net.Broadcast()
			game.SetTimeScale(1)
			net.Start("SATMEndSound")
			net.Broadcast()
			timer.Remove("ResetSATM")
		end

		self:Remove()
	end
end

if SERVER then
	hook.Add("TTTPrepareRound", "ResetSATM", function()
		game.SetTimeScale(1)
		timer.Remove("ResetSATM")
	end)
else
	net.Receive("SATMStartSound", function()
		surface.PlaySound("weapons/satm_ext/sm_enter.wav")
	end)

	net.Receive("SATMEndSound", function()
		surface.PlaySound("weapons/satm_ext/sm_exit.wav")
	end)

	net.Receive("SATMMessage", function()
		local mode = net.ReadInt(6)

		if mode == 0 then
			chat.AddText("SATM: ", COLOR_WHITE, "The Space and Time-Manipulator is now destroyed and the time is reset!")
		elseif mode == 1 then
			chat.AddText("SATM: ", COLOR_WHITE, "Mode: Faster time.")
		elseif mode == 2 then
			chat.AddText("SATM: ", COLOR_WHITE, "Mode: Slower time.")
		elseif mode == 3 then
			chat.AddText("SATM: ", COLOR_WHITE, "Mode: Normal time.")
		elseif mode == 4 then
			local charges = net.ReadInt(6)
			chat.AddText("SATM: ", COLOR_WHITE, "Mode: Swap your position with a random player. " .. "Charges left: " .. charges)
		elseif mode == 5 then
			local charges = net.ReadInt(6)
			chat.AddText("SATM: ", COLOR_WHITE, "Mode: Swap position of two random players. " .. "Charges left: " .. charges)
		elseif mode == 10 then
			local nick = net.ReadString()
			chat.AddText("SATM: ", COLOR_WHITE, "You swapped your position with ", COLOR_GREEN, nick, COLOR_WHITE, ".")
		elseif mode == 11 then
			local nick = net.ReadString()
			local nick2 = net.ReadString()
			chat.AddText("SATM: ", COLOR_GREEN, nick, COLOR_WHITE, " swapped his position with ", COLOR_GREEN, nick2, COLOR_WHITE, ".")
		elseif mode == 12 then
			chat.AddText("SATM: ", COLOR_WHITE, "You got teleported.")
		elseif mode == 15 then
			chat.AddText("SATM: ", COLOR_WHITE, "No more players alive or all alive players crouching!")
		elseif mode == 20 then
			chat.AddText("SATM: ", COLOR_WHITE, "You need to stand on the ground and to not be crouching to switch positions!")
		elseif mode == 25 then
			chat.AddText("SATM: ", COLOR_WHITE, "No charges left for teleportation!")
			surface.PlaySound( "common/wpn_denyselect.wav" )
		end

		chat.PlaySound()
	end)
end
