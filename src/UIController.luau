-- services
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PLRS = game:GetService("Players")
local GUIservice = game:GetService("GuiService")

local GUI = script.Parent

-- folders
local Templates = script:WaitForChild("Templates")

-- dependencies
local MainFrame = GUI:WaitForChild("Main")

local BlocksFrame = MainFrame:WaitForChild("Blocks")
local CodeContainer = MainFrame:WaitForChild("CodeContainer")
local PropertiesContainer = MainFrame:WaitForChild("Properties")

local ExecuteBtn = MainFrame:WaitForChild("ExecuteBtn")

-- consts
local blockClickCD = 0.5
local visibleOutrunTime = 0.05

local propertiesPreset = {
	["Print"] = {
		["TextToPrint"] = {
			["Name"] = "TextToPrint",
			["Type"] = "TextBox",
		},
		["UseVariable"] = {
			["Name"] = "UseVariable",
			["Type"] = "Checkbox",
		}
	},
	
	["Wait"] = {
		["WaitTime"] = {
			["Name"] = "WaitTime",
			["Type"] = "TextBox",
		},
		["UseVariable"] = {
			["Name"] = "UseVariable",
			["Type"] = "Checkbox",
		}
	},
	
	["Loop"] = {
		["Repeats"] = {
			["Name"] = "Repeats",
			["Type"] = "TextBox",
		},
		
		["Blocks_count"] = {
			["Name"] = "Blocks_count",
			["Type"] = "TextBox",
		},
		
		["UseVariable"] = {
			["Name"] = "UseVariable",
			["Type"] = "Checkbox",
		}
	},
	
	["Varible"] = {
		["Varible_name"] = {
			["Name"] = "Varible_name",
			["Type"] = "TextBox",
		},
		
		["Value"] = {
			["Name"] = "Varible_value",
			["Type"] = "TextBox",
		},
	}
}

-- intermediate varibles
local player = PLRS.LocalPlayer

-- let varibles
local isDragging = false
local draggingBlock = nil
local lastBlockClick = 0
local lastClickedBlock = nil

local isHoldingMouse = false

-- caches
local connections = {}
local threads = {}

-- data
local codeData = {}

-- utils
local CodeRunner = require(script:WaitForChild("CodeRunner"))

-- repeated lf
local function changeTransparency(ui, whole, transparency)
	ui.BackgroundTransparency = transparency
	if whole == true then
		for _, v in ui:GetChildren() do
			if v:IsA("Frame")
				or v:IsA("ImageLabel")
				or v:IsA("TextBox")
				or v:IsA("TextLabel")
				or v:IsA("TextButton")
				or v:IsA("ScrollingFrame")
				or v:IsA("ImageButton") then
				
				v.BackgroundTransparency = transparency
			elseif v:IsA("UIStroke") then
				v.Transparency =transparency
			end
		end
	end
end

local function findIndex(t, value)
	for i = 1, #t do
		if t[i] == value then
			return i
		end
	end
	return nil
end

-- math lf
local function isInsideFrame(target, frame)
	local fMinX = frame.AbsolutePosition.X
	local fMinY = frame.AbsolutePosition.Y
	local fMaxX = fMinX + frame.AbsoluteSize.X
	local fMaxY = fMinY + frame.AbsoluteSize.Y

	if typeof(target) == "Vector2" then
		local isInsideX = (target.X >= fMinX) and (target.X <= fMaxX)
		local isInsideY = (target.Y >= fMinY) and (target.Y <= fMaxY)

		return isInsideX and isInsideY
	else
		local tMinX = target.AbsolutePosition.X
		local tMinY = target.AbsolutePosition.Y
		local tMaxX = tMinX + target.AbsoluteSize.X
		local tMaxY = tMinY + target.AbsoluteSize.Y

		return (tMinX < fMaxX) and (tMaxX > fMinX) and (tMinY < fMaxY) and (tMaxY > fMinY)
	end
end

-- logic lf
local function createDragConnection(ui)
	if isDragging == false then return end
	if connections["DragConnection"] then return end
	
	local connection
	local blockCopy = ui:Clone()
	blockCopy.Visible = false
	blockCopy.AnchorPoint = Vector2.new(0.5, 0.5)
	blockCopy.Active = false
	blockCopy.Interactable = false
	blockCopy.Selectable = false

	blockCopy.Parent = GUI:FindFirstChild("DraggingBlocks")
	
	connection = RunService.RenderStepped:Connect(function()
		
		if isDragging == false then
			if connection then
				if threads["TaskDelays"]["BlockVisibleDelay"] then
					task.cancel(threads["TaskDelays"]["BlockVisibleDelay"])
					threads["TaskDelays"]["BlockVisibleDelay"] = nil
				end
				connection:Disconnect()
				connection = nil
				blockCopy:Destroy()
				connections["DragConnection"] = nil
				return
			end
		end
		
		if blockCopy then
			local mousePosition = UIS:GetMouseLocation()

			blockCopy.Position = UDim2.fromOffset(mousePosition.X, mousePosition.Y)
			
			if blockCopy.Visible == false then
				if not threads["TaskDelays"] then
					threads["TaskDelays"] = {}
				end
				
				local taskDelay1 = task.delay(visibleOutrunTime, function()
					blockCopy.Visible = true
					threads["TaskDelays"]["BlockVisibleDelay"] = nil
				end)
				
				threads["TaskDelays"]["BlockVisibleDelay"] = taskDelay1
			end
	end
	end)
	
	connections["DragConnection"] = connection
end

local function createProperties(pattern, method, tableOn)
	local patternTable = propertiesPreset[pattern]
	if patternTable then
		local tableToReturn = {}
		if method == "Create" then
			for i, v in patternTable do
				if v["Type"] == "TextBox" then
					if PropertiesContainer.Interactables:FindFirstChild(v["Name"].."_Property") then
						continue
					else
						local textBoxTemplate = script:FindFirstChild("Templates"):FindFirstChild("Properties"):FindFirstChild("TextBoxTemplate")
						if textBoxTemplate then
							local textBox = textBoxTemplate:Clone()
							textBox.NameLabel.Text = v["Name"]
							textBox.Name = v["Name"].."_Property"..#codeData
							textBox.Parent = PropertiesContainer:FindFirstChild("Interactables")
							local toReturn = {
								Name = v["Name"],
								part = textBox,
								Type = "TextBox",
								partName = v["Name"].."_Property"..#codeData,
							}
							table.insert(tableToReturn, toReturn)
						end
					end
				end
				
				if v["Type"] == "Checkbox" then
					if PropertiesContainer.Interactables:FindFirstChild(v["Name"].."_Property") then
						continue
					else
						local checkBoxTemplate =script:FindFirstChild("Templates"):FindFirstChild("Properties"):FindFirstChild("CheckboxTemplate")
						if checkBoxTemplate then
							local checkBox = checkBoxTemplate:Clone()
							checkBox.NameLabel.Text = v["Name"]
							checkBox.Name = v["Name"].."_Property"..#codeData
							checkBox.Parent = PropertiesContainer:FindFirstChild("Interactables")
							local toReturn = {
								Name = v["Name"],
								part = checkBox,
								Type = "Checkbox",
								partName = v["Name"].."_Property"..#codeData,
							}
							table.insert(tableToReturn, toReturn)
						end
					end
				end
			end

			return tableToReturn
		end
		
		if method == "Show" then
			if tableOn then
				for _, v in tableOn do
					if PropertiesContainer:FindFirstChild("Interactables"):FindFirstChild(v["partName"]) then
						PropertiesContainer:FindFirstChild("Interactables"):FindFirstChild(v["partName"]).Visible = true
					else
						continue
					end
				end
			end
		end
		
		if method == "HideAll" then
			for _, v in PropertiesContainer:FindFirstChild("Interactables"):GetChildren() do
				if v:IsA("Frame") or v:IsA("TextButton") or v:IsA("TextLabel") or v:IsA("TextBox") or v:IsA("ScrollingFrame") then
					v.Visible = false
				end
			end
		end
		
		if method == "Delete" then
			if tableOn then
				for _, v in tableOn do
					if PropertiesContainer:FindFirstChild("Interactables"):FindFirstChild(v["partName"]) then
						PropertiesContainer:FindFirstChild("Interactables"):FindFirstChild(v["partName"]):Destroy()
					else
						continue
					end
				end
			end
		end
	else
		return false
	end
end

local function addBlock(block)
	local mousePosition = UIS:GetMouseLocation()
	local inset = game:GetService("GuiService"):GetGuiInset()
	local correctedMouse = mousePosition - inset

	local isInside = isInsideFrame(correctedMouse, CodeContainer)
	
	if isInside == false then return end
	
	local blockPattern = block:GetAttribute("Pattern")
	if not blockPattern then return end
	
	local codeBlock
	for _, v in Templates:GetChildren() do
		if v:GetAttribute("Pattern") == blockPattern then
			codeBlock = v
			break
		end
	end
	
	if codeBlock == nil then return end
	
	local copyBlockVisual = codeBlock:Clone()
	copyBlockVisual.Name = copyBlockVisual.Name..#codeData
	copyBlockVisual.Parent = CodeContainer:FindFirstChild("Blocks")
	
	local Connections = {}
	local Data = {}
	local properties = createProperties(blockPattern, "Create")
	for _, v in properties do
		if v["Type"] == "TextBox" then
			local curr_conn
			curr_conn = v["part"].FocusLost:Connect(function(enterPressed, inputObject)
				Data[v["Name"]] = v["part"].Text
			end)
			table.insert(Connections, curr_conn)
		end
		if v["Type"] == "Checkbox" then
			local curr_conn
			local boolean = false
			curr_conn = v["part"].MouseButton1Click:Connect(function()
				if v["part"].Text == "⬜" then
					v["part"].Text = "✅"
				else
					v["part"].Text = "⬜"
				end
				
				boolean = not boolean
				Data[v["Name"]] = boolean
			end)
		end
	end
	
	local openPropertiesConn
	openPropertiesConn = copyBlockVisual.MouseButton1Click:Connect(function()
		if lastClickedBlock == copyBlockVisual.Name then
			PropertiesContainer.Visible = not PropertiesContainer.Visible
		else
			if PropertiesContainer.Visible == false then
				PropertiesContainer.Visible = true
			end
		end
		createProperties(blockPattern, "HideAll", properties)
		createProperties(blockPattern, "Show", properties)
		lastClickedBlock = copyBlockVisual.Name
	end)
	if not connections["ButtonOpenProperties"] then
		connections["ButtonOpenProperties"] = {}
	end
	table.insert(connections["ButtonOpenProperties"], openPropertiesConn)
	
	local blockData = {
		blockPattern = blockPattern,
		blockVisual = copyBlockVisual,
		blockConnections = Connections,
		blockSaves = Data
	}
	table.insert(codeData, blockData)
	
	local blockDestroyConn
	local clickCount = 0
	local lastClickTime = 0
	local doubleClickCD = 0.3
	blockDestroyConn = copyBlockVisual.MouseButton1Click:Connect(function()
		if os.clock() - lastClickTime >= doubleClickCD then
			clickCount = 0
		end
		
		clickCount += 1
		
		if clickCount >= 2 then
			if copyBlockVisual then
				local index = findIndex(codeData, blockData)
				if index then
					for _, conn in blockData.blockConnections do
						if conn then
							conn:Disconnect()
							conn = nil
						end
					end
					
					if connections["ButtonOpenProperties"] and connections["ButtonOpenProperties"][index] then
						connections["ButtonOpenProperties"][index]:Disconnect()
						connections["ButtonOpenProperties"][index] = nil
					end
					
					createProperties(blockPattern, "Delete", properties)
					if PropertiesContainer.Visible == true then
						PropertiesContainer.Visible = false
					end
					
					codeData[index] = nil
				end
				copyBlockVisual:Destroy()
			end

			if blockDestroyConn then
				blockDestroyConn:Disconnect()
				blockDestroyConn = nil
				connections["destroyBlockConnections"] = nil
				return
			end
		else
			lastClickTime = os.clock()
		end
	end)
	if not connections["destroyBlockConnections"] then
		connections["destroyBlockConnections"] = {}
	end
	table.insert(connections["destroyBlockConnections"], blockDestroyConn)
	
	local numberOfBlocks = #codeData
	local roughCanvasScaleY = (numberOfBlocks * 0.2)
	CodeContainer.CanvasSize = UDim2.fromScale(0, roughCanvasScaleY)
	
	return blockData
end

local function blockVisualAddConn()
	if isDragging == false then return end
	
	local ui = draggingBlock
	if ui == nil then return end
	
	local blockPattern = ui:GetAttribute("Pattern")
	
	if blockPattern then
		local codeBlock
		for _, v in Templates:GetChildren() do
			if v:GetAttribute("Pattern") == blockPattern then
				codeBlock = v
				break
			end
		end
		if codeBlock == nil then return end
		
		local codeBlockCopy = codeBlock:Clone()
		codeBlockCopy.Visible = false
		codeBlockCopy.Interactable = false
		changeTransparency(codeBlockCopy, true, 0.5)
		codeBlockCopy.Parent = CodeContainer:FindFirstChild("Blocks")
		
		local curr_connection
		curr_connection = RunService.RenderStepped:Connect(function()
			if isDragging == false then
				if curr_connection then
					curr_connection:Disconnect()
					curr_connection = nil
					codeBlockCopy:Destroy()
					connections["VisualAddBlockConn"] = nil
					return
				end
			end
			
			local mousePosition = UIS:GetMouseLocation()
			local inset = game:GetService("GuiService"):GetGuiInset()
			local correctedMouse = mousePosition - inset

			local isInside = isInsideFrame(correctedMouse, CodeContainer)
			
			if isInside == true then
				if codeBlockCopy then
					codeBlockCopy.Visible = true
				end
			else
				if codeBlockCopy then
					codeBlockCopy.Visible = false
				end
			end
		end)
		
		connections["VisualAddBlockConn"] = curr_connection
	end
end

-- return module
local UIController = {}

UIController.Init = function()
	UIS.InputBegan:Connect(function(input, gp)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isHoldingMouse = true
		end
	end)
	
	UIS.InputEnded:Connect(function(input, gp)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isHoldingMouse = false
			
			local lastDraggedBlock = draggingBlock
			if lastDraggedBlock == nil then return end
			
			if isDragging then
				isDragging = false
				draggingBlock = nil
			end
			
			local blockData = addBlock(lastDraggedBlock)
		end
	end)
	
	ExecuteBtn.MouseButton1Click:Connect(function()
		CodeRunner.RunCode(codeData)
	end)
	
	for _, block in BlocksFrame:GetChildren() do
		if block:IsA("TextButton") then
			if isDragging == true then return end
			
			block.MouseButton1Down:Connect(function()
				if os.clock() - lastBlockClick < blockClickCD then return end
				
				isDragging = true
				draggingBlock = block
				createDragConnection(block)
				blockVisualAddConn()
				
				lastBlockClick = os.clock()
			end)
		end
	end
	
end

return UIController

-- DragScripting UIController
-- author - Kotost
