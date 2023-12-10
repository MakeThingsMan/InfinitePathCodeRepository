local GraphModule				= require(game.ServerScriptService.GraphModule)
local DialogueEvent				= game.ReplicatedStorage.DialogueEvent
local Dialogue = {}
local specialChar = {
	["#"] = .3, -- used for ...'s 
	["$"] = .15, -- 
	["%"] = .075, -- used to spice up text a bit
	["@"] = .04, -- reset's the speed back to default speed
	["^"] = .02	-- used to speed up text for fast talking npcs or for flavor
}

function Dialogue.NewNode(name,choice,dialogue,priority,onSelected,splitPoint)
	local newNode = {}

	if not choice then
		choice = ""
	end

	if not dialogue then
		dialogue = ""
	end	

	if not priority then
		priority = 1
	end

	if not onSelected then
		onSelected = function() end
	end

	if not name then 
		warn("Debugging this will be hell if you dont slap a name on here")
		print(dialogue)
	end

	if not splitPoint then 
		splitPoint = false
	end	

	newNode.Choice		= choice
	newNode.Dialogue 	= dialogue
	newNode.Priority	= priority
	newNode.OnSelected	= onSelected
	newNode.Name		= name
	newNode.SplitPoint	= splitPoint
	return newNode
end

function Dialogue.QuickConnectTree(DialogueText,firstOrigin) -- will handle most cases for dialogue other than the case of looping options
	local DialogueTree	= GraphModule.new(GraphModule.GraphType.OneWay)
	DialogueTree 		= buildVertexes(DialogueTree,DialogueText)
	DialogueTree		= helpConnect(DialogueTree,DialogueText,2,firstOrigin)
	return DialogueTree
end

function Dialogue.LoopConnect(Tree,item,location,loopTo)
	Tree:AddVertex(item)
	Tree:Connect(location,item)
	Tree:Connect(item,loopTo)
	return Tree
end

function helpConnect(DialogueTree,DialogueText,index,firstorigin)
	local origin = firstorigin or DialogueText[index] 
	for i = index, #DialogueText, 1 do
		if DialogueText[index].SplitPoint then 
			origin = DialogueText[index]
		end
		if DialogueText[i].Priority == 1 then 
			DialogueTree:Connect(DialogueText[i-1],DialogueText[index])
		else
			DialogueTree:Connect(origin,DialogueText[index])
			helpConnect(DialogueTree,DialogueText,index+1,origin)
		end
		index += 1
	end
	return DialogueTree
end


function buildVertexes(DialogueTree,dialogueTable)
	for i, v in pairs(dialogueTable) do
		DialogueTree:AddVertex(v)
	end
	return DialogueTree
end

function Dialogue.SelectNode(node,DialogueGui,dialogButtonConnections,DialogTree,characters)
	local NameLabel = DialogueGui.DialogueBox.NameLabel
	Dialogue.ResetGUI(DialogueGui,dialogButtonConnections)
	if node.Dialogue ~= "" then
		print(node.Dialogue)
		Dialogue.PlayDialogue(DialogueGui,node.Dialogue)
	end
	
	NameLabel.Changed:Connect(function()
		local x = true 
		for i, name in pairs(characters)do 
			if NameLabel.Text == name  then 
				x = false
				break
			end
		end
		if x then 
			Dialogue.ResetGUI(DialogueGui,dialogButtonConnections)
			return
		end	
	end)
	
	local neighbors = DialogTree:Neighbors(node)
	if neighbors then
		table.sort(neighbors, function(a,b)
			return a.Priority <= b.Priority
		end)
		for index = 1, #neighbors do
			local nextNode = neighbors[index]
			local choiceButton = DialogueGui.DialogueBox.Options:FindFirstChild("Choice"..index)
			choiceButton.Visible = true
			------------------------------------------------- styleization
			local cont = false

			for i =1, #nextNode.Choice+50,1 do 
				local char = string.sub(nextNode.Choice,i,i)
			
				nextNode.Choice,cont = textAugments(char,cont,nextNode.Choice,i)
				--print(char,"I:", i,"Increment:")
				if i == #nextNode.Choice then break end
			end
			
			-------------------------------------------------
			print(nextNode.Choice)
			choiceButton.Text = nextNode.Choice
			if nextNode.Choice == "" then 
				wait(1)
				nextNode.OnSelected()	
				Dialogue.SelectNode(nextNode,DialogueGui,dialogButtonConnections,DialogTree,characters)
				return
			end
			dialogButtonConnections[index] = choiceButton.MouseButton1Click:Connect(function()
				nextNode.OnSelected()		
				Dialogue.SelectNode(nextNode,DialogueGui,dialogButtonConnections,DialogTree,characters)
			end)
		end
	else
		wait(.4)
		Dialogue.ExitDialog(DialogueGui,dialogButtonConnections)
	end
	print("end")
	return
end


function Dialogue.PlayDialogue(dGUI,Dialogue)
	local box = dGUI.DialogueBox
	local textSpeed = .04
	local char	
	local progressive 
	local cont = false
	local textBox = box.TextBox

	for i=1, #Dialogue,1 do	
		char				= string.sub(Dialogue,i,i)
		for x, v in pairs(specialChar) do
			if char == x then 
				textSpeed = v 
				Dialogue = Dialogue:sub(1,i-1) .. Dialogue:sub(i+1,#Dialogue)
			end
		end
		--Dialogue,cont = textAugments(char,cont,Dialogue,i)
		progressive  = string.sub(Dialogue,1,i)
		textBox.Text = progressive
		wait(textSpeed)
		--if i == #Dialogue then break end
	end	
end

function Dialogue.ResetGUI(DialogueGui,dialogueButtonConnections)
	DialogueGui.DialogueBox.Options.Choice1.Visible = false
	DialogueGui.DialogueBox.Options.Choice2.Visible = false
	DialogueGui.DialogueBox.Options.Choice3.Visible = false
	DialogueGui.DialogueBox.Options.Choice4.Visible = false
	for _, connection in pairs(dialogueButtonConnections) do
		connection:disconnect()
		connection = nil
	end
end

function textAugments(char,cont,text,i)
	if char == "|" then
		if char == "|" and  cont then
			cont = false 
			text = text:sub(1,i-1).. "</b>".. text:sub(i+1,#text)
		else 
			cont = true 
			text =  text:sub(1,i-1).. "<b>" .. text:sub(i+1,#text)
		end
	end
	return text,cont
end

function Dialogue.ExitDialog(DialogueGui,dbc)
	Dialogue.ResetGUI(DialogueGui,dbc)
	DialogueGui.DialogueBox.Visible = false
end

function Dialogue.SetName(DialogueGui,Name)
	local NameLabel = DialogueGui.DialogueBox.NameLabel
	NameLabel.Text = Name
end

return Dialogue
