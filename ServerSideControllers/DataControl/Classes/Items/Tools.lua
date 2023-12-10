local DamageClass 	= require(game.ServerScriptService.CombatController.DamageClass)
local ItemClass		= require(script.Parent)
local Tool = {}

function Tool.new(name,appearance,weight,stacks,durability,damage,hitboxes,animations,maxSwings,endlag,toolType,rank,value)

	local newTool = ItemClass.new(name,"Tool",appearance,weight,1,stacks,rank,value)
	
	if not toolType then 
		warn("This tool has no typing",name)
	end
	
	if not durability then 
		warn("This Tool has no durability", name)
	end

	if not damage then 
		DamageClass.New("BasicToolDamage",1,1,{"Neutral"},0,0,.05)
	end

	if not hitboxes then 
		warn("This Tool has no hitbox",name)
	end

	if not animations then 
		warn("This Tools has no animations",name)
	end

	if not maxSwings then 
		maxSwings = 1
	end

	if not endlag then
		warn("this Tool has no endlag",name)
	end

	newTool.Damage 		= damage
	newTool.Hitboxes	= hitboxes
	newTool.Animations	= animations
	newTool.MaxSwings	= maxSwings
	newTool.Endlag		= endlag
	newTool.ToolType	= toolType
	setmetatable(newTool,Tool)
	--print(newTool)
	return newTool
end

return Tool
