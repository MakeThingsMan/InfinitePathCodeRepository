
local runService = game:GetService("RunService")

local function FlingPreventionUpdate()
	local CurrentHum 	= game.Players.LocalPlayer.Character:WaitForChild("Humanoid")
	local CurrentRoot 	= game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart") or game.Players.LocalPlayer.Character.HumanoidRootPart
	local Force		 	= game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity.Magnitude
	
	if CurrentHum ~= nil and CurrentRoot ~= nil and Force ~= nil and CurrentRoot:IsDescendantOf(workspace) then
		if CurrentRoot.RotVelocity.Magnitude >= 150 then
			CurrentRoot.RotVelocity = Vector3.new()
			print("Rotational Fling prevented")
		end
		if CurrentRoot.Velocity.Magnitude >= 150 then
			CurrentRoot.Velocity = Vector3.new()
			--CurrentRoot.CFrame = CFrame.new() -- set this to be the direction the camera is looking in in terms of z and x and have y be 0
			print("Fling Prevented")
		end
	end
end

runService.RenderStepped:Connect(function()
	FlingPreventionUpdate()
end)