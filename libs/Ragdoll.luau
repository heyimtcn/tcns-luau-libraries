--!nocheck

---REQUIRE ON THE CLIENT

---WARNING: Since ragdolling disables Humanoid.RequireNeck, falling to the void or having every part of the character get delted will not kill the character, it will also make manual resetting impossible, i advice you make a fix like when the humanoidrootpart is deleted respawn the player

local COMM_CHANNEL_ID = 27 --EDIT

local RunService = game:GetService("RunService")

local data = {}

if RunService:IsServer() then
	data.ServerComm = require(script.Parent.Communicator.ServerComm)
	data.Comm = data.ServerComm.get(COMM_CHANNEL_ID)
	data.Signal = data.Comm:RemoteSignal(0)
else
	local plr = game.Players.LocalPlayer
	data.ClientComm = require(script.Parent.Communicator.ClientComm)
	data.Comm = data.ClientComm.get(COMM_CHANNEL_ID)
	data.Signal = data.Comm:RemoteSignal(0)
	data.Handler = function(enabled:boolean)
		if not plr.Character then
			return
		end
		local char = plr.Character
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if enabled then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
			humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
		else
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,true)
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
	data.Connection = data.Signal:Connect(data.Handler)
end

local Ragdoll = {
	Data = data
}

function Ragdoll.is_ragdolled(char:Model):boolean
	return if char:GetAttribute("Ragdolled") then true else false
end

function Ragdoll.ragdoll(char:Model)
	if RunService:IsClient() then
		error("Called ragdoll on the client",2)
	end
	if Ragdoll.is_ragdolled(char) then
		return
	end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	for _, motor6d in char:GetDescendants() do
		if motor6d:IsA("Motor6D") then
			local bsc = Instance.new("BallSocketConstraint")
			local attch0 = Instance.new("Attachment")
			local attch1  = Instance.new("Attachment")
			attch0.Parent = motor6d.Part0
			attch1.Parent = motor6d.Part1
			bsc.Name = "RagdollConstraint"
			bsc.Parent = motor6d.Parent
			bsc.Attachment0 = attch0
			bsc.Attachment1 = attch1
			attch0.CFrame = motor6d.C0
			attch1.CFrame = motor6d.C1
			bsc.MaxFrictionTorque = 200
			bsc.LimitsEnabled = true
			bsc.TwistLimitsEnabled = true
			motor6d.Enabled = false
		end
	end
	humanoid.RequiresNeck = false
	char:SetAttribute("Ragdolled",true)
	local plr = game.Players:GetPlayerFromCharacter(char)
	if plr then
		data.Signal:FireFor({plr},true)
	else
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
		humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
	end
end

function Ragdoll.unragdoll(char:Model)
	if RunService:IsClient() then
		error("Called unragdoll on the client",2)
	end
	if not Ragdoll.is_ragdolled(char) then
		return
	end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	for _, inst in char:GetDescendants() do
		if inst:IsA("BallSocketConstraint") and inst.Name == "RagdollConstraint" then
			inst:Destroy()
		elseif inst:IsA("Motor6D") then
			inst.Enabled = true
		end
	end
	humanoid.RequiresNeck = true
	char:SetAttribute("Ragdolled",false)
	local plr = game.Players:GetPlayerFromCharacter(char)
	if plr then
		data.Signal:FireFor({plr},false)
	else
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,true)
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

function Ragdoll.toggle(char:Model)
	if RunService:IsClient() then
		error("Called toggle on the client",2)
	end
	if not Ragdoll.is_ragdolled(char) then
		Ragdoll.ragdoll(char)
	else
		Ragdoll.unragdoll(char)
	end
end

return Ragdoll
