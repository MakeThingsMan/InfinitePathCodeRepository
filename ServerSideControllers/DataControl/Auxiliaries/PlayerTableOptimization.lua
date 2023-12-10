local playerTable = {}

function playerTable.Update(NewTable)
	playerTable = NewTable
end

function playerTable.Get(player)
	return playerTable[player.UserId]
end 

return playerTable
