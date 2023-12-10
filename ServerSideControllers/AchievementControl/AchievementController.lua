local sS						= game.ServerStorage:WaitForChild("SendStats")
local tS 						= game.ServerStorage:WaitForChild("TakeStats")
local aE 						= game.ServerStorage:WaitForChild("AchievementEvent")
local CheckAchievements			= game.ServerStorage:WaitForChild("CheckAchievements")
local BloodlinesClass			= require(script.BloodlinesClass)
local AchievementList 			= require(script.AchievementList)
local Switch 					= require(script.Parent.Switch)
local Players					= game:GetService("Players")
script.Parent:WaitForChild("DataController")

----------------------------------------------------- Achievements
aE.Event:Connect(function(player,achieve)
	local pStats = sS:Invoke(player)
	
	if not pStats.Achievements.Feats[achieve.Name] then 
		pStats.Achievements.Feats[achieve.Name] = achieve	
	end 
	if not pStats.Achievements.Feats[achieve.Name].Active then 
		pStats.Achievements.Points 								+= achieve.Points
		pStats.Achievements.Feats[achieve.Name].Active 			= true
		pStats.Achievements.Feats[achieve.Name].TimesAchieved 	+= 1
	end
	pStats = CheckAchievements:Invoke(player,pStats)
	tS:Fire(pStats,script.Name)
end)

----------------------------------------------------- Bloodline
-- NOTE TO SELF: IF SOMEONE HAS ALREADY OBTAINED A BLOODLINE THAT MEANS THEY'VE COMPLETED THE QUEST FOR SAID BLOODLINE MEANING YOU DON'T HAVE TO DO EXTRA CHECKS!
CheckAchievements.OnInvoke = function(player,pStats) -- if you have achievements 
		for j, achievement in pairs(pStats.Achievements.Feats) do-- for every achievement you have 
			if not pStats.Bloodlines.Obtained[achievement.Name] and achievement.Name:sub(1,9) == "Bloodline" then -- go through them and check if they have the bloodline label 
				for i, Bloodline in pairs(AchievementList.Bloodlines.DormantBloodlines.Basic) do --- Comb through the bloodlines section to see if you have the dormant bloodline 
					if achievement.Name == Bloodline.Name and achievement.TimesAchieved >= 3 then 
					pStats.Bloodlines.Obtained[Bloodline.Name] = BloodlinesClass.New(Bloodline.Name,"QiBloodline" , false)
					pStats.Bloodlines.Obtained.Count+=1 -- this is important so make sure it's accurate to how many you actually have
					end
				end
			end
		end
	return pStats
end