local AchievementClass			= require(game.ServerScriptService.AchievementController.AchievementClass)

local Achievements = {
	["Test"]							= AchievementClass.new("Test","player.Name"," has gained a state of enlightenment by clicking the block",1),

	["States"] = {
		["MartialFreshie"]				= AchievementClass.new("MartialFreshie","player.Name"," has achieved the state of Qi Refinement",1),
		["MartialPractioner"]			= AchievementClass.new("MartialPractioner","player.Name"," has gained a state of enlightenment by clicking the block",5),
		["MartialMaster"]				= AchievementClass.new("MartialMaster","player.Name"," has gained a state of enlightenment by clicking the block",10),
		["MartialKing"]					= AchievementClass.new("MartialKing","player.Name"," has gained a state of enlightenment by clicking the block",25),
		["MartialAncestor"]				= AchievementClass.new("MartialAncestor","player.Name"," has gained a state of enlightenment by clicking the block",50),
		["MartialSovereign"]			= AchievementClass.new("MartialSovereign","player.Name"," has gained a state of enlightenment by clicking the block",100),	
	},
	["Bloodlines"] = { 
		["DormantBloodlines"] = {-- concerns obtainment
			["Basic"] = {
				["BloodlineOfFire"] 			= AchievementClass.new("BloodlineOfFire","player.Name"," has gained the bloodline of fire ",15),-- gained through having 3 characters with fire qi
				["BloodlineOfWater"] 			= AchievementClass.new("BloodlineOfWater","player.Name"," has gained the bloodline of Water ",15),-- gained through having 3 characters with water qi
				["BloodlineOfEarth"] 			= AchievementClass.new("BloodlineOfEarth","player.Name"," has gained the bloodline of Earth ",15),-- gained through having 3 characters with earth qi
				["BloodlineOfWood"] 			= AchievementClass.new("BloodlineOfWood","player.Name"," has gained the bloodline of Wood ",15),-- gained through having 3 characters with wood qi
				["BloodlineOfMetal"] 			= AchievementClass.new("BloodlineOfMetal","player.Name"," has gained the bloodline of Metal ",15),-- gained through having 3 characters with metal qi
			},
			["Advanced"] = {
				["BloodlineOfDragonsWeak"] 		= AchievementClass.new("WeakBloodlineOfDragons","player.Name"," has gained the bloodline of Metal ",50),	
			}
		},

		["Awakened Bloodlines"] = { -- concerns actually awakening and being able to use the bloodline 

		},

	}
}--point total is 317 currently

return Achievements
