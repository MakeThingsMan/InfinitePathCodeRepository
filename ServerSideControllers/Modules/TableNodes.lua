local TableNode = {}

function TableNode.New(item,chance,min,max)
	local newNode = {}
	
	newNode.Item 		= item
	newNode.Chance		= chance
	newNode.MinAmount	= min
	newNode.MaxAmount	= max

	setmetatable(newNode,TableNode)
	return newNode
end

return TableNode
