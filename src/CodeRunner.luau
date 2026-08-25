--!strict

-- export Types
export type BlockData = {
	blockPattern: string,
	blockVisual: TextButton,
	blockConnections: {[string]: RBXScriptConnection},
	blockSaves: {[string]: any}
}

-- cache
local RunCodes = {}

local CodeRunner = {}

CodeRunner.RunCode = function(CodeTable: any)
	local currentRunThread
	if #CodeTable <= 0 then return end
	local currentIndex = 0
	local blocks_runned = {}
	
	local codesEnvironment = {
		["Varibles"] = {},
	}
	
	currentRunThread = task.spawn(function()
		for i, blockData: BlockData in ipairs(CodeTable) do
			local pattern = blockData.blockPattern
			currentIndex = i
			local toAdd = {
				["index"] = i,
				["block"] = blockData
			}
			
			table.insert(blocks_runned, toAdd)
			if pattern == "Print" then
				if blockData.blockSaves.UseVariable == true then
					local varible_name = blockData.blockSaves.TextToPrint
					if codesEnvironment["Varibles"][varible_name] then
						print(codesEnvironment["Varibles"][varible_name])
					else
						
					end
				else
					print(blockData.blockSaves.TextToPrint)
				end
			end
			
			if pattern == "Wait" then
				if blockData.blockSaves.UseVariable == true then
					if codesEnvironment["Varibles"][blockData.blockSaves.WaitTime] then
						local waitTime = tonumber(codesEnvironment["Varibles"][blockData.blockSaves.WaitTime])
						if waitTime then
							task.wait(waitTime)
						else
							
						end
					end
				else
					local waitTime = tonumber(blockData.blockSaves.WaitTime)
					if waitTime then
						task.wait(waitTime)
					else
						
					end
				end
			end
			
			if pattern == "Varible" then
				local varible_name = blockData.blockSaves.Varible_name
				local varible_value = blockData.blockSaves.Varible_value
				
				if codesEnvironment["Varibles"][varible_name] then
					codesEnvironment["Varibles"][varible_name] = varible_value
				else
					codesEnvironment["Varibles"][varible_name] = varible_value
				end
			end
			
			if pattern == "Loop" then
				local loopTimes = tonumber(blockData.blockSaves.Repeats)
				local block_count = tonumber(blockData.blockSaves.Blocks_count)
				
				if loopTimes and block_count then
					if loopTimes <= 0 then return end
					if block_count > #CodeTable or block_count <= 0 then return end
					
					local nextBlocks = {}
					local usedIds = {}
					for i, v in blocks_runned do
						if #blocks_runned <= 0 then break end
						table.insert(usedIds, v["index"])
					end
					
					for blockId, v in CodeTable do
						if blockId == i or usedIds[blockId] then continue end
						if blockId > i and blockId <= i + block_count then
							table.insert(nextBlocks, v)
						end
					end
					
					for _ = 1, loopTimes do
						for i, v: BlockData in ipairs(nextBlocks) do
							if v.blockPattern == "Print" then
								if v.blockSaves.UseVariable == true then
									local varible_name = v.blockSaves.TextToPrint
									if codesEnvironment["Varibles"][varible_name] then
										print(codesEnvironment["Varibles"][varible_name])
									else

									end
								else
									print(v.blockSaves.TextToPrint)
								end
							end
							
							if v.blockPattern == "Wait" then
								if blockData.blockSaves.UseVariable == true then
									if codesEnvironment["Varibles"][blockData.blockSaves.WaitTime] then
										local waitTime = tonumber(codesEnvironment["Varibles"][v.blockSaves.WaitTime])
										if waitTime then
											task.wait(waitTime)
										else

										end
									end
								else
									local waitTime = tonumber(v.blockSaves.WaitTime)
									if waitTime then
										task.wait(waitTime)
									else

									end
								end
							end
							
							if v.blockPattern == "Varible" then
								local varible_name = v.blockSaves.Varible_name
								local varible_value = v.blockSaves.Varible_value

								if codesEnvironment["Varibles"][varible_name] then
									codesEnvironment["Varibles"][varible_name] = varible_value
								else
									codesEnvironment["Varibles"][varible_name] = varible_value
								end
							end
						end
					end
				end
			end
		end
	end)
	table.insert(RunCodes, currentRunThread)
end

return CodeRunner

-- DragScripting Code_Runner
-- author - Kotost
