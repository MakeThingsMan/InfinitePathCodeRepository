local Players 					= game:GetService("Players")
local UIS						= game:GetService("UserInputService")
local StarterGui 				= game:GetService("StarterGui")
local TweenService				= game:GetService("TweenService")
local cCE						= game.ReplicatedStorage:WaitForChild("ClientCombatEvent")
local SpS						= game.ReplicatedStorage:WaitForChild("SendPlayerStats")
local ShowBloodlines 			= game.ReplicatedStorage:WaitForChild("ShowBloodlines")
local rearrangeInventory		= game.ReplicatedStorage:WaitForChild("RearrangeInventory")
local rearrageHotbar			= game.ReplicatedStorage:WaitForChild("RearrangeHotbar")
local UpdateInv					= game.ReplicatedStorage:WaitForChild("UpdateInv")
local screenShake 				= game.ReplicatedStorage:WaitForChild("ScreenShake")
local findItem					= game.ReplicatedStorage:WaitForChild("FindItem")
local SetToolForAnimation 		= game.ReplicatedStorage:WaitForChild("SetToolForAnimation")
local equipItem					= game.ReplicatedStorage:WaitForChild("EquipItem")
local unequipItem				= game.ReplicatedStorage:WaitForChild("UnequipItem")
local ForcedUnequipTool			= game.ReplicatedStorage:WaitForChild("ForceUnequipTool")
local switch					= require(game.ReplicatedStorage.PlayerUsableSwitch)
---------------------------------------------------------------------------------------- TEMPORARY

----------------------------------------------------------------------------------------
--local DialogueEvent				= game.ReplicatedStorage:WaitForChild("DialogueEvent")
---------------------------------------------------------------------------------------- FRAMES
local dGUI						= script.Parent:WaitForChild("DialogueGui")
local cGUI						= script.Parent:WaitForChild("CombatGui")
local mGui						= script.Parent:WaitForChild("MiscGui")
local BarsFrame					= cGUI:WaitForChild("BarsFrame")
local InCombatFrame 			= cGUI.Frame
local HealthFrame				= BarsFrame.HealthFrame
local QiFrame					= BarsFrame.QiFrame
local CultivationFrame			= BarsFrame.CultivationFrame
local BloodFrame 				= dGUI.BloodlineFrame
local HotbarFrame				= cGUI.InventoryHolder.HotBarFrame
local InventoryFrame 			= cGUI.InventoryHolder.InventoryFrame
local TribTimer 				= cGUI.TribTimer -- temp
local EquipFrame				= cGUI.Equipment
local MoneyFrame				= mGui.MoneyFrame
---------------------------------------------------------------------------------------- FRAME COMPONENTS
local InCombatLabel 			= InCombatFrame.InCombatLabel
local HealthGUI					= HealthFrame.Health
local QiGUI						= QiFrame.Qi
local CultiGUI					= CultivationFrame.Cultivation
local BloodX				 	= BloodFrame.BloodEscapeFrame.BloodEscape
local TribText					= TribTimer.TribText
local Money						= MoneyFrame.Money
----------------------------------------------------------------------------------------
local player					= Players.LocalPlayer
local Character 				= player.Character or player.CharacterAdded:Wait()
local Humanoid 					= Character:WaitForChild("Humanoid")
local Animator					= Humanoid.Animator
----------------------------------------------------------------------------------------
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) -- removes that trash base backpack
---------------------------------------------------------------------------------------- Required Variables
local CurrentGlobalConnection	= nil
local previousGlobalConnection	= nil
local CurrentHover 				= nil
local holdingInventory			= false
local hoveringButton			= false
local holdingHotbar				= false
local inInventory 				= false
local inventory					= nil
local oldInventory				= nil
local HoverIdentifier			= nil
local lastToolEquipped			= nil
local activeGui					= {} -- hotbar is at pos 1, inv = pos 2, equipment = pos 3
---------------------------------------------------------------------------------------- Helper Functions
function hotbarHelper(InputObject)
	for i,v in pairs(HotbarFrame:GetChildren()) do
		if v:IsA("TextButton") then
			if InputObject.KeyCode == Enum.KeyCode[v:GetAttribute("Location")] then
				return true, v
			end
		end
	end
	return false
end
function inventoryHelper(inventory,oldinventory)
	if oldInventory == nil then return false end
	for i, v in pairs(oldInventory) do
		for j,k in pairs(v) do
			if inventory[i][j].Id ~= k.Id then
				--print(inventory[i][j].Id, k.Id, inventory[i][j].Id == k.Id, i,j)
				return false
			end
		end
	end
	return true
end
function animationHelper(sign,lastHotbarConnection)
	for j = 1, 10, 1 do
		if CurrentGlobalConnection ~= lastHotbarConnection then
			local x = 1+(j*sign)/27.419
			lastHotbarConnection.BackgroundColor3 = Color3.new(x,x,x)
			task.wait()
		else
			return
		end
	end
	lastHotbarConnection.Transparency = .45
end

function animateEnterOrLeave(sign,button)
	hoveringButton = sign > 0
	if holdingInventory then return end 
	for j =1, 10, 1 do
		if CurrentGlobalConnection ~= button then
			local x = 1+((j/27.419)*sign)
			button.BackgroundColor3 = Color3.new(x, x, x)
			task.wait(.01)
		else
			return
		end
	end
end

function showItem(pstats,i,j,TurnOff) --TurnOff is a temporary solution because i'm tired of this bs breaking bruh
	local slot
	if j then 
		if pstats.Inventory[i][j].Type == "Empty" or TurnOff then ForcedUnequipTool:FireServer() return end
		local success = findItem:InvokeServer(pstats.Inventory[i][j],player.Name,lastToolEquipped,"Find")
		if (previousGlobalConnection == nil and not success) or (previousGlobalConnection == -1 and not success) or success then return end
		lastToolEquipped =  findItem:InvokeServer(pstats.Inventory[i][j],player.Name,lastToolEquipped,"EquipCycle")
		slot = pstats.Inventory[i][j]
	else
		if pstats.Hotbar[i-1].Type == "Empty" or TurnOff then ForcedUnequipTool:FireServer() return end
		local success = findItem:InvokeServer(pstats.Hotbar[i-1],player.Name,lastToolEquipped,"Find")
		if (previousGlobalConnection == nil and not success) or (previousGlobalConnection == -1 and not success) or success then return end

		lastToolEquipped =  findItem:InvokeServer(pstats.Hotbar[i-1],player.Name,lastToolEquipped,"EquipCycle")
		slot = pstats.Hotbar[i-1]
		end
		------------------------------------------------------------
		--print(lastToolEquipped)
		if lastToolEquipped == nil then return end
		if slot.Animations == nil then return end
		SetToolForAnimation:Fire(player.UserId,lastToolEquipped,slot.Type,slot) -- ships the animation handling over to the animation controller
end

function hoverIcon(Icon)
	local x = Icon:Clone()
	local constraint = Instance.new("UIAspectRatioConstraint")
	constraint.AspectRatio = 1
	constraint.AspectType = Enum.AspectType.FitWithinMaxSize
	constraint.DominantAxis = Enum.DominantAxis.Height
	constraint.Parent = x
	x.Parent = cGUI
	x.AnchorPoint	= Vector2.new(0,0)
	x.Size = UDim2.new(.5*.125,0,.4*.19,0)
	while UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
		if inInventory == false then break end 
		local mouse = player:GetMouse()
		local offset = x.AbsoluteSize.Y/mouse.ViewSizeY*UIS:GetMouseLocation().Y/mouse.ViewSizeY
		x.Position = UDim2.new(UIS:GetMouseLocation().X/mouse.ViewSizeX,0,UIS:GetMouseLocation().Y/mouse.ViewSizeY-offset,0)
		task.wait()
	end
	x:Destroy()
end

function lookup(a,b)
	if a == b then 
		return true 
	elseif string.match(b,"Left") == "Left" then
		return string.sub(b,5) == a 
	elseif string.match(b,"Right") == "Right" then 
		return string.sub(b,6) == a 
	else return false
	end
end

local tweenControllerSwitch = switch()

:case("Equipment",function(appear)
	local offset = -1
	local x = math.floor(offset + appear) 
	EquipFrame.Position = UDim2.new(offset,0,.835,0)
	local endpos	= UDim2.new(x+.274,0,.835,0)
	local tribEndpos= UDim2.new(0,0,EquipFrame.Position.Y.Scale,0)
	local tribStart = UDim2.new(0,0,0.5,0)
	EquipFrame:TweenPosition(endpos,Enum.EasingDirection.Out,Enum.EasingStyle.Back,.8,true,nil)
	if appear == 1 then 
		TribTimer:TweenPosition(tribEndpos,Enum.EasingDirection.Out,Enum.EasingStyle.Back,.7,true,nil)
	else
		TribTimer:TweenPosition(tribStart,Enum.EasingDirection.Out,Enum.EasingStyle.Back,.6,true,nil)
	end
end)
:case("Inventory",function(appear)
	local offset 	= -1
	local x 	 	= math.floor(offset+appear)
	local endpos 	= UDim2.new(.5,0,x+.813,0)
	InventoryFrame.Position = UDim2.new(.5,0,2,0)
	InventoryFrame:TweenPosition(endpos,Enum.EasingDirection.Out,Enum.EasingStyle.Back,.7,true,nil)
end)



function TweenController(Trigger,Appear)
	-- appear is either 1 or -1 depending on whether or not the thing is appearing or disappearing
	-- uses the activeGui array to see what gui's are currently active throughout the player's screen
	-- this will shift everything over when something either appears or disappears from the gui.
	
	tweenControllerSwitch(Trigger,Appear)
	
end

---------------------------------------------------------------------------------------- Screen Shake
screenShake.OnClientEvent:Connect(function(intensity)
	for i =1, 20,1 do 
		local x = math.random(-intensity,intensity)/50
		local y = math.random(-intensity,intensity)/50
		Humanoid.CameraOffset = Vector3.new(x,y,0)
		task.wait(.01)
	end
	Humanoid.CameraOffset = Vector3.new(0,0,0)
end)
---------------------------------------------------------------------------------------- In combat stuff
cCE.OnClientEvent:Connect(function(key,value)
	if key == "InCombat" then
		InCombatFrame.Visible = value
	end
end)
---------------------------------------------------------------------------------------- Bloodlines stuff
ShowBloodlines.OnClientEvent:Connect(function() -- currently doesn't work with the tweening
	BloodFrame.Visible = true
	local pStats 			= SpS:InvokeServer(player)
	local BloodOptions		= game.ReplicatedStorage.GuiObjects.Bloodline
	local counter 			= 0
	local BloodConnections	= {}
	for i, v in pairs(pStats.Bloodlines.Obtained) do
		if i ~= "Count" then
			counter += 1
			print(v,counter)
			local x = BloodOptions:Clone()
			x.Parent 			= BloodFrame.ScrollingFrame
			x.Position 			= UDim2.new(0,0,BloodOptions.Size.Y.Scale*counter,0)
			x.TextButton.Text 	= v.Name
			x.Name				= v.Name
			x.Visible			= true
			BloodConnections[counter] = x.TextButton.MouseButton1Click:Connect(function()
				ShowBloodlines:FireServer(x.Name)
				print(x.Name, "This is what you need to look at to debug this shot")
			end)
		end
	end
	BloodX.MouseButton1Click:Connect(function()
		BloodFrame.Visible = false
		for i = 1, counter, 1 do
			BloodConnections[i]:Disconnect()
		end
		local children = BloodFrame.ScrollingFrame:GetChildren()
		for i, v in pairs(children) do
			if v.Name ~= "BloodEscapeFrame" or v.Name ~= "BloodEscape" then
				v:Destroy()
			end
		end
	end)
end)
---------------------------------------------------------------------------------------- Hotbar stuff
local pstats = SpS:InvokeServer(player) -- this could be dangerous so if you never end up needing this remove it and make something that only sends the inventory to the player
for i,v in pairs(HotbarFrame:GetChildren()) do
	if v:IsA("TextButton") then
		----------------------------------
		table.insert(activeGui,1,"Hotbar") 
		----------------------------------
		v.Text						= pstats.Hotbar[i-1].Name
		v.ImageLabel.TextLabel.Text = pstats.Hotbar[i-1].Stacks

		v.MouseButton1Down:Connect(function()
			local initialClickTime = tick()
			local lastHotbarConnection = CurrentGlobalConnection
			if CurrentGlobalConnection ~= nil and previousGlobalConnection ~= v and previousGlobalConnection ~= -1 then
				spawn(function()
					animationHelper(-1,lastHotbarConnection)
				end)
			elseif previousGlobalConnection == v and previousGlobalConnection ~= -1 then
				task.wait(.15) -- bug here where if you switch around enough times this triggers and makes the thing disappear.
				if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and holdingInventory == false then 
					lastHotbarConnection.Transparency = .45
					lastHotbarConnection.BackgroundColor3 = Color3.new(0.635294, 0.635294, 0.635294)
					previousGlobalConnection = -1
					showItem(pstats,tonumber(v.Name)+1,nil,true) -- this could cause problems idk
					return
				end
			end
			v.Transparency = 0
			v.BackgroundColor3 = Color3.new(1,1,1)
			CurrentGlobalConnection = v
			previousGlobalConnection = CurrentGlobalConnection

			while tick()-initialClickTime < .3 do -- if you're holding down and want to change the position of two opjects in your inventory this lets you do it.
				if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or CurrentHover ~= CurrentGlobalConnection or not inInventory then
					holdingInventory = false
					return
				end
				task.wait()
			end
			holdingInventory = true	
			HoverIdentifier= "Hotbar"
			v.BackgroundColor3 = Color3.new(1, 0.133333, 0.133333)
			spawn(function()
				hoverIcon(v)
			end)
		end)

		v.MouseButton1Up:Connect(function()
			local activateShowItem = true
			pstats = SpS:InvokeServer(player) -- don't remove this from this location this gotta be first for this to work
			if holdingInventory and CurrentHover ~= CurrentGlobalConnection then
				--here you isolate the variables so they cant get changed while you're swapping
				local CIS = CurrentGlobalConnection
				local CH  = CurrentHover
				local HID = HoverIdentifier
				--here you do the data switch
				local temp = pstats.Hotbar[tonumber(CurrentHover.Name)]
				if HID == "Inventory" then
					print("Hotbar to inventory")
					local otherTemp = pstats.Inventory[tonumber(CurrentGlobalConnection.Parent.Name)][tonumber(CurrentGlobalConnection.Name)].InvLocation
					-- current selection is in the Inventory
					-- current hover is in the hotbar
					pstats.Hotbar[tonumber(CurrentHover.Name)] = pstats.Inventory[tonumber(CurrentGlobalConnection.Parent.Name)][tonumber(CurrentGlobalConnection.Name)]
					pstats.Hotbar[tonumber(CurrentHover.Name)].InvLocation = temp.InvLocation

					pstats.Inventory[tonumber(CurrentGlobalConnection.Parent.Name)][tonumber(CurrentGlobalConnection.Name)] = temp
					pstats.Inventory[tonumber(CurrentGlobalConnection.Parent.Name)][tonumber(CurrentGlobalConnection.Name)].InvLocation = otherTemp

					CurrentGlobalConnection.Text				= pstats.Inventory[tonumber(CurrentGlobalConnection.Parent.Name)][tonumber(CurrentGlobalConnection.Name)].Name
					CurrentGlobalConnection.Counter.Text 		= pstats.Inventory[tonumber(CurrentGlobalConnection.Parent.Name)][tonumber(CurrentGlobalConnection.Name)].Stacks

					CurrentHover.Text							= pstats.Hotbar[tonumber(CurrentHover.Name)].Name
					CurrentHover.ImageLabel.TextLabel.Text 		= pstats.Hotbar[tonumber(CurrentHover.Name)].Stacks

					CurrentGlobalConnection = CurrentHover
					CurrentHover = CurrentGlobalConnection

					inventory = pstats.Inventory
					oldInventory = inventory
					rearrangeInventory:FireServer(inventory)
					rearrageHotbar:FireServer(pstats.Hotbar)
				elseif HID == "Hotbar" then
					print("Hotbar to Hotbar")
					-- Current Connection is in the hotbar
					-- Current Hover is in the hotbar

					local temp = pstats.Hotbar[tonumber(CurrentGlobalConnection.Name)]
					pstats.Hotbar[tonumber(CurrentGlobalConnection.Name)]	=  pstats.Hotbar[tonumber(CurrentHover.Name)]
					pstats.Hotbar[tonumber(CurrentHover.Name)]				=  temp --Current Hover

					--print(pstats.Hotbar[tonumber(CurrentGlobalConnection.Name)])
					--print(pstats.Hotbar[tonumber(CurrentHover.Name)])

					CurrentGlobalConnection.ImageLabel.TextLabel.Text 	= pstats.Hotbar[tonumber(CurrentGlobalConnection.Name)]	.Stacks										
					CurrentHover.ImageLabel.TextLabel.Text 				= pstats.Hotbar[tonumber(CurrentHover.Name)].Stacks

					CurrentGlobalConnection.Text 	= pstats.Hotbar[tonumber(CurrentGlobalConnection.Name)].Name
					CurrentHover.Text				= pstats.Hotbar[tonumber(CurrentHover.Name)].Name

					CurrentGlobalConnection 							= CurrentHover
					CurrentHover 										= CurrentGlobalConnection		
					rearrageHotbar:FireServer(pstats.Hotbar)
				end

				CurrentHover.TextTransparency 				= 0
				CurrentGlobalConnection.BackgroundColor3 	= Color3.new(1,1,1)
				CurrentGlobalConnection.Transparency 		= 0
				CurrentGlobalConnection.TextTransparency 	= 0

				previousGlobalConnection.BackgroundColor3	= Color3.new(0.635294, 0.635294, 0.635294)
				previousGlobalConnection.Transparency 		= .45
				previousGlobalConnection.TextTransparency 	= 0
				previousGlobalConnection = CurrentGlobalConnection
				holdingInventory = false
				activateShowItem = false
			end
			
			showItem(pstats,i)
			
		end)

		v.MouseEnter:Connect(function() --- Plays a little animation when you hover over the hotbar item
			CurrentHover = v
			animateEnterOrLeave(1,CurrentHover)
		end)
		v.MouseLeave:Connect(function() -- plays a little animation when you stop hovering over the hotbar item
			animateEnterOrLeave(-1,v)
		end)
	end
end
---------------------------------------------------------------------------------------- keyboard inputs and mouse stuff
UIS.InputBegan:Connect(function(InputObject,gameProcessedEvent)
	if gameProcessedEvent then return end
	--Inventory Section---------------------------------------------------------------------------------------------- Inventory Section
	if InputObject.KeyCode == Enum.KeyCode.Backquote then
		if inInventory then
			----------------------------------
			table.remove(activeGui,2)
			TweenController("Inventory",-1)
			----------------------------------
			InventoryFrame.Visible = false
			inInventory = false
			CurrentHover = nil

			if CurrentGlobalConnection ~= nil then 
				CurrentGlobalConnection.Transparency = .45
				CurrentGlobalConnection.BackgroundColor3 = Color3.new(0.635294, 0.635294, 0.635294)
			end

			holdingInventory = false
			CurrentGlobalConnection = nil
			previousGlobalConnection = -1
		else
			----------------------------------
			table.insert(activeGui,2,"Inventory")
			TweenController("Inventory",1)
			----------------------------------
			local pstats = SpS:InvokeServer(player)
			inventory 	= 	pstats.Inventory
			local success = inventoryHelper(inventory,oldInventory)
			local inventoryslots = InventoryFrame.ScrollingFrame:GetChildren()

			if inventoryslots and not success and not inInventory then -- In charge of actually resetting the inventory when you open it up again and it's different
				for i, v in pairs(inventoryslots) do 
					if v:IsA("Frame") then 
						v:Destroy()
					end
				end
			end

			if not success  then -- creates and initializes the inventory itself
				for i, v in pairs(inventory) do
					local Row 				= Instance.new("Frame")
					Row.Parent				= InventoryFrame.ScrollingFrame
					Row.Name				= i
					for j, k in pairs(v) do
						local x 			= Instance.new("TextButton")
						local uac 			= Instance.new("UIAspectRatioConstraint")
						local corner		= Instance.new("UICorner")
						local counter		= Instance.new("TextLabel")
						local corner2		= Instance.new("UICorner")
						x.Parent 			= Row
						x.Name 				= j
						x.Text 				= k.Name
						x.Size 				= UDim2.new(.125,0,.125,0)
						x.Transparency 		= .45
						x.AutoButtonColor	= false
						uac.Parent			= x
						corner.Parent		= x
						counter.Parent 		= x
						counter.Name		= "Counter"
						counter.AnchorPoint	= Vector2.new(1,0)
						counter.Position	= UDim2.new(1,0,0,0)
						counter.Size		= UDim2.new(.2,0,.2,0)
						counter.Text		= pstats.Inventory[i][j].Stacks
						counter.BackgroundColor3= Color3.new(0.490196, 0.490196, 0.490196)
						counter.BorderSizePixel = 0
						counter.TextColor3	= Color3.new(0.760784, 0.760784, 0.760784)
						corner2.Parent		= counter

						x.MouseButton1Down:Connect(function()
							local initialClickTime = tick()
							local lastInvConnection = CurrentGlobalConnection
							if CurrentGlobalConnection ~= nil and previousGlobalConnection ~= x and previousGlobalConnection ~= -1 then
								spawn(function()
									animationHelper(-1,lastInvConnection)
								end)
							elseif previousGlobalConnection == x and previousGlobalConnection ~= -1 and holdingInventory == false then
								task.wait(.15) -- bug here where if you switch around enough times this triggers and makes the thing disappear.
								if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and holdingInventory == false then 
									--print("this is triggering", CurrentGlobalConnection,lastInvConnection,previousGlobalConnection)
									lastInvConnection.Transparency = .45
									lastInvConnection.BackgroundColor3 = Color3.new(0.635294, 0.635294, 0.635294)
									previousGlobalConnection = -1
									return
								end	
							end
							x.Transparency = 0
							x.BackgroundColor3 = Color3.new(1,1,1)
							CurrentGlobalConnection = x
							previousGlobalConnection = CurrentGlobalConnection

							while tick()-initialClickTime < .3 do -- if you're holding down and want to change the position of two opjects in your inventory this lets you do it.
								if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or CurrentHover ~= CurrentGlobalConnection then
									holdingInventory = false
									return
								end
								task.wait()
							end
							holdingInventory = true	
							HoverIdentifier = "Inventory"
							x.BackgroundColor3 = Color3.new(1, 0.133333, 0.133333)
							spawn(function()
								hoverIcon(x)
							end)
						end)

						x.MouseButton1Up:Connect(function()
							--print("Current HOver",CurrentHover)
							if holdingInventory and CurrentHover ~= CurrentGlobalConnection then
								--here you isolate the variables so they cant get changed while you're swapping
								local CIS = CurrentGlobalConnection
								local CH  = CurrentHover
								local HID = HoverIdentifier
								--here you do the data switch
								pstats = SpS:InvokeServer(player)
								local temp = pstats.Inventory[tonumber(CurrentHover.Parent.Name)][tonumber(CurrentHover.Name)]
								--print("Hover id", HID, HID == "Hotbar")
								if HID == "Inventory" then
									print("Inventory to Inventory")
									pstats.Inventory[tonumber(CurrentHover.Parent.Name)][tonumber(CurrentHover.Name)] = pstats.Inventory[tonumber(CurrentGlobalConnection.Parent.Name)][tonumber(CurrentGlobalConnection.Name)]
									pstats.Inventory[tonumber(CurrentGlobalConnection.Parent.Name)][tonumber(CurrentGlobalConnection.Name)] = temp
									--here you show the switch	
									CurrentGlobalConnection.Text 	= pstats.Inventory[tonumber(CurrentGlobalConnection.Parent.Name)][tonumber(CurrentGlobalConnection.Name)].Name
									CurrentHover.Text				= pstats.Inventory[tonumber(CurrentHover.Parent.Name)][tonumber(CurrentHover.Name)].Name

									CurrentGlobalConnection.Counter.Text = pstats.Inventory[tonumber(CurrentGlobalConnection.Parent.Name)][tonumber(CurrentGlobalConnection.Name)].Stacks										
									CurrentHover.Counter.Text = pstats.Inventory[tonumber(CurrentHover.Parent.Name)][tonumber(CurrentHover.Name)].Stacks

									CurrentGlobalConnection = CurrentHover
									CurrentHover = CurrentGlobalConnection	
								elseif HID == "Hotbar" then
									local othertemp =  pstats.Hotbar[tonumber(CurrentGlobalConnection.Name)].InvLocation
									-- Current Connection is in the hotbar
									-- Current Hover is in the inventory
									print("Hotbar to inventory")
									pstats.Inventory[tonumber(CurrentHover.Parent.Name)][tonumber(CurrentHover.Name)] 				= pstats.Hotbar[tonumber(CurrentGlobalConnection.Name)]
									pstats.Inventory[tonumber(CurrentHover.Parent.Name)][tonumber(CurrentHover.Name)].InvLocation	= temp.InvLocation
									pstats.Hotbar[tonumber(CurrentGlobalConnection.Name)] 											= temp
									pstats.Hotbar[tonumber(CurrentGlobalConnection.Name)].InvLocation								= othertemp

									CurrentHover.Text									= pstats.Inventory[tonumber(CurrentHover.Parent.Name)][tonumber(CurrentHover.Name)].Name
									CurrentHover.Counter.Text 							= pstats.Inventory[tonumber(CurrentHover.Parent.Name)][tonumber(CurrentHover.Name)].Stacks

									CurrentGlobalConnection.Text						= pstats.Hotbar[tonumber(CurrentGlobalConnection.Name)].Name
									CurrentGlobalConnection.ImageLabel.TextLabel.Text 	= pstats.Hotbar[tonumber(CurrentGlobalConnection.Name)].Stacks

									CurrentGlobalConnection = CurrentHover
									CurrentHover 			= CurrentGlobalConnection	
									rearrageHotbar:FireServer(pstats.Hotbar)
								end

								CurrentGlobalConnection.BackgroundColor3 	= Color3.new(1,1,1)
								CurrentGlobalConnection.Transparency 		= 0

								previousGlobalConnection.BackgroundColor3	= Color3.new(0.635294, 0.635294, 0.635294)
								previousGlobalConnection.Transparency 		= .45
								previousGlobalConnection = CurrentGlobalConnection
								--here you save your changes so they update whenever the player opens their inventory
								inventory = pstats.Inventory
								oldInventory = inventory
								rearrangeInventory:FireServer(inventory)
								holdingInventory = false
							end
							--print(i,j)
							pstats = SpS:InvokeServer(player) -- required
							showItem(pstats,i,j)
						end)

						x.MouseEnter:Connect(function() --- Plays a little animation when you hover over the inventory item
							CurrentHover = x
							animateEnterOrLeave(1,CurrentHover)
						end)

						x.MouseLeave:Connect(function(pos1,pos2) -- plays a little animation when you stop hovering over the inventory item
							animateEnterOrLeave(-1,x)
						end)
					end
				end
			end
			oldInventory 		= 	inventory
			print(oldInventory)
			InventoryFrame.Visible = true
			inInventory = true
		end
	end
	--Equipment Section---------------------------------------------------------------------------------------------- Equipment Section	
	if InputObject.KeyCode == Enum.KeyCode.U then 
		local visibility = not EquipFrame.Visible
		
		if visibility == false then 
			TweenController("Equipment",-1)
		end
		
		EquipFrame.Visible = visibility

		if EquipFrame.Visible then 
			table.insert(activeGui,3,"Equipment")
			TweenController("Equipment",1)
			
			local equipSlot
			local item
			local location1 
			local Counter
			for i, v in pairs(EquipFrame:GetChildren()) do
				if v:IsA("Frame") and v.Name ~= "Cover" then
					v.TextButton.MouseButton2Down:Connect(function() -- right clicking
						local unequipButton 			= Instance.new("TextButton")
						local roundCorners				= Instance.new("UICorner")
						unequipButton.Text 				= "Unequip"
						unequipButton.Parent 			= v
						unequipButton.Position 			= UDim2.new(0,0,0,0)
						unequipButton.Size				= UDim2.new(1,0,.2,0)
						unequipButton.BackgroundColor3	= Color3.new(0.968627, 0.113725, 0.054902)
						unequipButton.Transparency 		= .2
						unequipButton.ZIndex			= 2
						roundCorners.Parent 			= unequipButton

						unequipButton.MouseButton1Click:Connect(function()
							unequipItem:FireServer(v.Name)
							v.TextButton.Text = v.Name
							unequipButton:Destroy()
						end)
						--add something later! probably just unequipping by putting the item back.
					end)

					v.TextButton.MouseButton1Up:Connect(function()
						print(pstats.Hotbar[tonumber(CurrentGlobalConnection.Name)].Type)
						equipSlot = v.Name
						pstats = SpS:InvokeServer(player) -- required
						if inInventory and CurrentGlobalConnection then
							if HoverIdentifier == "Inventory" then
								item = pstats.Inventory[tonumber(CurrentGlobalConnection.Parent.Name)][tonumber(CurrentGlobalConnection.Name)]
								location1 = item.InvLocation[1]
							elseif HoverIdentifier == "Hotbar" then
								item = pstats.Hotbar[tonumber(CurrentGlobalConnection.Name)]	
								location1= item.InvLocation[1]+1
							end
							print(item)
							if lookup(item.Location,v.Name) then --currently doesn't support accessories.
								if item.Type == "Equipment" or item.Type == "Artifact" or item.Type == "Spirit"  or item.Type == "Accessory"  then 
									v.TextButton.Text = item.Name
									if string.match(v.Name,"Right") == "Right"  then
										item.Appearance = item.Appearance.."Right"
									elseif string.match(v.Name,"Left") == "Left" then 
										item.Appearance = item.Appearance.."Left"
									end
									print(item)
									showItem(pstats,location1,item.InvLocation[2])
									equipItem:FireServer({equipSlot},item)
									task.wait(.2)
									showItem(pstats,location1,item.InvLocation[2])
									--Counter.Text = tostring(tonumber(Counter.Text)-1)
								end
							end 
						end
						if previousGlobalConnection ~= -1 then 
							previousGlobalConnection.BackgroundColor3	= Color3.new(0.635294, 0.635294, 0.635294)
							previousGlobalConnection.Transparency 		= .45
							previousGlobalConnection = -1
						end
						holdingInventory = false
						CurrentGlobalConnection = nil
					end)

					v.MouseEnter:Connect(function()
						--CurrentHover = v -- this might cause issues so lets leave this off for now.
						--			print("Entering the hotbar")
						animateEnterOrLeave(1,v.TextButton)
					end)
					v.MouseLeave:Connect(function() -- plays a little animation when you stop hovering over the hotbar item
						animateEnterOrLeave(-1,v.TextButton)
					end)

				end
			end
		end
	end
	--Hotbar Section------------------------------------------------------------------------------------------------- Hotbar Section	
	local pstats = SpS:InvokeServer(player) -- required 
	local success, name = hotbarHelper(InputObject)
	--print(CurrentGlobalConnection)
	local lastHotbarConnection = CurrentGlobalConnection
	if CurrentGlobalConnection ~= nil and success and previousGlobalConnection ~= name and previousGlobalConnection ~= -1 then
		spawn(function()
			animationHelper(-1,lastHotbarConnection)
		end)
	elseif previousGlobalConnection == name and previousGlobalConnection ~= -1 and success then
		lastHotbarConnection.Transparency = .45
		lastHotbarConnection.BackgroundColor3 = Color3.new(0.635294, 0.635294, 0.635294)
		previousGlobalConnection = -1
		showItem(pstats,tonumber(name.Name)+1,nil,true)
		return
	end
	if success then
		name.Transparency = 0
		name.BackgroundColor3 = Color3.new(1,1,1)
		CurrentGlobalConnection = name
		previousGlobalConnection = CurrentGlobalConnection
		showItem(pstats,tonumber(name.Name)+1)
	end
end)
---------------------------------------------------------------------------------------- Actively updates the players inventory and hotbar in real time smoothly.
UpdateInv.OnClientEvent:Connect(function()
	spawn(function() -- is this really needed though? I feel like this could be done without spawning another function on a different thread
		local pstats 			= SpS:InvokeServer(player)
		local hotbarItems 		= HotbarFrame:GetChildren()
		local inventoryItems 	= InventoryFrame.ScrollingFrame:GetChildren()	

		for i =1, #pstats.Hotbar,1 do
			hotbarItems[i+1].Text 						= pstats.Hotbar[i].Name
			hotbarItems[i+1].ImageLabel.TextLabel.Text	= pstats.Hotbar[i].Stacks
		end

		if not inInventory then return end

		for i =1, #pstats.Inventory,1 do
			for j = 1, #pstats.Inventory[i], 1 do 
				inventoryItems[i+2][j].Text 			= pstats.Inventory[i][j].Name
				inventoryItems[i+2][j].Counter.Text		= pstats.Inventory[i][j].Stacks
			end
		end
	end)
end)
----------------------------------------------------------------------------------------

--print(HotbarFrame:GetChildren()) -- this somehow fixed the stupid issue with the image icons
----------------------------------------------------------------------------------------
while Humanoid.Health > 0 do
	local pStats 			= SpS:InvokeServer(player)
	----------------------------------------------------------------------------------------
	local HpEdit 			= Humanoid.Health/Humanoid.MaxHealth
	local QiEdit			= pStats.Qi.Current/pStats.Qi.Max
	local CultiEdit			= pStats.Cultivation.CBase/pStats.Cultivation.CBaseMax
	----------------------------------------------------------------------------------------
	HealthGUI:TweenSize((UDim2.new(HpEdit,0,1,0)),Enum.EasingDirection.InOut,Enum.EasingStyle.Linear,0.15)
	QiGUI:TweenSize((UDim2.new(QiEdit,0,1,0)),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,0.15)
	CultiGUI:TweenSize((UDim2.new(CultiEdit,0,1,0)),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,0.15)
	TribText.Text 	= "Tribulation Timer: ".. pStats.Cultivation.TribulationTimer
	Money.Text		= pStats.Money
	----------------------------------------------------------------------------------------
	task.wait(.05)
end 