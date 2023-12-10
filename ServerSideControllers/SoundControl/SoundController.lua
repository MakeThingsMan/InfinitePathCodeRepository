local PlaySound 			= game.ServerStorage:WaitForChild("PlaySound")


PlaySound.Event:Connect(function(sounds,Object)
	local Sound = Instance.new("Sound")
	Sound.SoundId = sounds[1]
	Sound.Parent = Object
	if not sounds.IsPlaying then 
		Sound:Play()
		if sounds[2] then 
			Sound.TimePosition = sounds[2]
			task.wait(sounds[3])
			Sound:Stop()
		end
	end
end)