
----------------------------------------------------------------------------------------------
--- AutomaticGateMotorsPROTOTYPE
--- @author: peteR_pg
--- Steam profile: https://steamcommunity.com/id/peter_pg/
--- GitHub Repository: https://github.com/Susjin/AutomaticGateMotorsPROTOTYPE

--- All the Utilities methods used in other files are listed in this file
--- @class ISAutoGateUtils
--- @return ISAutoGateUtils
	local ISAutoGateUtils = {}
----------------------------------------------------------------------------------------------
--Setting up locals


--[[**********************************************************************************]]--

------------------ Functions related to miscellaneous utils ------------------

local function comparatorDrainableUsesInt(item1, item2)
	return item1:getDrainableUsesInt() - item2:getDrainableUsesInt()
end
---Get the best Welding Rods inside a inventory container
---@param container ItemContainer Usually the player inventory
---@return DrainableComboItem WeldingRods with most uses left
function ISAutoGateUtils.getWeldingRodsWithMostUses(container)
	return container:getBestTypeEvalRecurse("Base.WeldingRods", comparatorDrainableUsesInt)
end

---Check if player has blowtorch and weldingmask
---@param player IsoPlayer Player
function ISAutoGateUtils.predicateInstallOption(player)
	local playerInventory = player:getInventory()
	if (playerInventory:contains("BlowTorch", true) and playerInventory:contains("WeldingMask", true)) or
		ISBuildMenu.cheat then return true else return false end
end

---Check if the item still have uses left
---@param inventoryItem InventoryItem Item to be checked
---@param itemType String Type of the item
---@return boolean True if has uses left, false if not
function ISAutoGateUtils.hasDeltaLeft(inventoryItem, itemType)
	if inventoryItem:getType() == itemType then
		if inventoryItem:getDelta() > 0 then
			return true
		end
	end
	return false
end

---Returns the given number rounded with the number of decimal places in param2 (0 by default)
---@param number number Number to be rounded
---@param numberDecimalPlaces number Amount of decimal places
---@return number Rounded number
function ISAutoGateUtils.roundNumber(number, numberDecimalPlaces)
	local decimal = 10^(numberDecimalPlaces or 0)
	return math.floor(number * decimal + 0.5) / decimal
end

--[[**********************************************************************************]]--

------------------ Functions related to getting a specific item from containers player's inventory) ------------------

---Get controllers inside the player inventory
---@param player IsoPlayer Player with the controller
---@param doorCode number A automatic gate motor code
---@return InventoryItem|InventoryItem[] If doorCode is not nil and a connected gate is found, returns the controller item. If doorCode is nil, returns all unconnected controllers as a table
function ISAutoGateUtils.findControllerOnPlayer(player, doorCode)
    local controllers = player:getInventory():getItemsFromType("GateController")
	local emptyControllers = {}
	for i=0, controllers:size()-1, 1 do
		local controller = controllers:get(i)
		local controllerCode = controller:getModData()["AutoGateFrequency_code"]
		if doorCode == nil then
			if controllerCode == nil then
				table.insert(emptyControllers, controller)
			end
		else
			if controllerCode == doorCode then
				return controller
			end
		end
	end
	if doorCode == nil then return emptyControllers else return nil end
end

--[[**********************************************************************************]]--

------------------ Functions related to the installation of the gate's automatic motor ------------------
---Called after motor install, defines the frequency for that gate
---@param gate IsoThumpable Contains the x,y and z fields with the gate corner position
function ISAutoGateUtils.installAutomaticGateMotor(gate)
    local fullGate = ISAutoGateUtils.getFullGate(gate)
    local corner = fullGate[1]
	local x, y, z = corner:getX(), corner:getY(), corner:getZ()

    for i = 1, #fullGate do
		fullGate[i]:getModData()["AutoGateFrequency_X"] = x
		fullGate[i]:getModData()["AutoGateFrequency_Y"] = y
		fullGate[i]:getModData()["AutoGateFrequency_Z"] = z
    end
	print(string.format("DEBUG: Frequency set! \nPOS: \nX: %d\nY: %d\nZ: %d", x, y, z))
end

--[[**********************************************************************************]]--

------------------ Functions related to gate's opening, closing and locking ------------------

---Checks if the gate have a battery with charges left, if true, toggles the gate.
---@param player IsoPlayer Player interacting with the gate
---@param gateFrequency IsoThumpable Any gate object
function ISAutoGateUtils.toggleAutomaticGate(gateFrequency, player)
	local gate = ISAutoGateUtils.getGateFromFrequency(gateFrequency)
	if gate and player then
		if ISAutoGateUtils.checkDistanceToGate(player, gate) then
			gate:ToggleDoor(player)
			print("DEBUG: Gate toggled!")
		end
	end
end

---Checks if the player is within the max range (set by the SandboxSettings) to the gate
---@param player IsoPlayer Player to be checked
---@param gate IsoThumpable Any gate object
---@return boolean Returns true if the player is within range, if not, returns false
function ISAutoGateUtils.checkDistanceToGate(player, gate)
    if gate and (gate:getSquare():DistTo(player:getSquare()) < 35) then
        return true
    end
    return false
end

--[[**********************************************************************************]]--

------------------ Functions that get the Gate position from object or vice-versa (also by frequency) ------------------
---Gets a IsoThumpable Gate Object from a IsoSquare
---@param isoGridSquare IsoGridSquare Position to search for
---@return IsoThumpable Returns gate object found, if not, returns nil
function ISAutoGateUtils.getGateFromSquare(isoGridSquare)
	if not isoGridSquare then return nil end
	for i=0, isoGridSquare:getObjects():size()-1 do
        local object = isoGridSquare:getObjects():get(i)
        local name = tostring(object:getName())
        if (instanceof(object, "IsoThumpable")) and
			((name == "Double Door")) then
            return object
        end
    end
	return nil
end

---Gets the left-most corner IsoSquare of a Gate Object
---@param gate IsoThumpable Any gate object
---@return IsoGridSquare Returns the position of the corner gate
function ISAutoGateUtils.getGateCorner(gate)
	if not gate then return nil end
    local gateSquare = gate:getSquare()
    local isNorth = gate:getNorth()
    local gateProperties = tonumber(gateSquare:getProperties():Val("DoubleDoor"))
    local x = gateSquare:getX()
    local y = gateSquare:getY()
    local z = gateSquare:getZ()
    if gateProperties == 1 or gateProperties == 5 then
        return gateSquare
    end
    if isNorth then
        if gateProperties == 2 then
            return getCell():getGridSquare(x-1,y,z)
        elseif gateProperties == 3 then
            return getCell():getGridSquare(x-2,y,z)
        elseif gateProperties == 4 or gateProperties == 8 then
            return getCell():getGridSquare(x-3,y,z)
        elseif gateProperties == 6 then
            return getCell():getGridSquare(x,y-1,z)
        else
            return getCell():getGridSquare(x-3,y-1,z)
        end
    else
        if gateProperties == 2 then
            return getCell():getGridSquare(x,y+1,z)
        elseif gateProperties == 3 then
            return getCell():getGridSquare(x,y+2,z)
        elseif gateProperties == 4 or gateProperties == 8 then
            return getCell():getGridSquare(x,y+3,z)
        elseif gateProperties == 6 then
            return getCell():getGridSquare(x-1,y,z)
        else
            return getCell():getGridSquare(x-1,y+3,z)
        end
    end
end

---Gets all the 4 objects of a gate
---@param gate IsoThumpable Any gate object
---@return table<number, IsoThumpable> Returns a table with all 4 gate objects within (indexes 1->4, left->right)
function ISAutoGateUtils.getFullGate(gate)
	if not gate then return nil end
	---@type table<number, IsoThumpable>
    local fullGate = {}
    local corner = ISAutoGateUtils.getGateCorner(gate)
    local isNorth = gate:getNorth()
	if not corner then return nil end
    local x = corner:getX()
    local y = corner:getY()
    local z = corner:getZ()
    fullGate[1] = ISAutoGateUtils.getGateFromSquare(corner)
    local offsetX = 0
    local offsetY = 0
    for i = 1, 3 do
        if isNorth then
            offsetX = i
        else
            offsetY = -i
        end
        local gridSquare = getCell():getGridSquare(x+ offsetX, y+ offsetY, z)
        local gateInCell = ISAutoGateUtils.getGateFromSquare(gridSquare)
        if gateInCell then
            table.insert(fullGate, gateInCell)
        end
    end
	if gate:IsOpen() then
		if isNorth then
			y = y+1
		else
			x = x+1
		end
		for i = 0, 3 do
			if isNorth then
				offsetX = i
			else
				offsetY = -i
			end
			local gridSquare = getCell():getGridSquare(x+ offsetX, y+ offsetY, z)
			local gateInCell = ISAutoGateUtils.getGateFromSquare(gridSquare)
			if gateInCell then
				table.insert(fullGate, gateInCell)
			end
		end
	end
    return fullGate
end

---Gets a specific gate from a frequency
---@param frequency table Contains the x, y, z and code of a gate
---@return IsoThumpable If found, returns the gate corner object, if not, returns nil
function ISAutoGateUtils.getGateFromFrequency(frequency)
	local square = getCell():getGridSquare(frequency[1],frequency[2],frequency[3])
    if square then
        local gate = ISAutoGateUtils.getGateFromSquare(square)
		if gate then
			if gate:getModData()["AutoGateFrequency_code"] == frequency[4] then
				return gate
			end
		end
	end
	return nil
end

--[[**********************************************************************************]]--

------------------ Functions related to gate frequency and connecting ------------------
---Gets a table with 5 positions containing the X, Y, Z, code and controllers from a Object
---@param obj IsoThumpable|InventoryItem Any gate object/controller item
---@return table Returns the table with frequency info, if none, returns nil
function ISAutoGateUtils.getFrequency(obj)
    local frequency = {}
    frequency[1] = obj:getModData()["AutoGateFrequency_X"]
    if frequency[1] == nil then
        return nil
    end
    frequency[2] = obj:getModData()["AutoGateFrequency_Y"]
    frequency[3] = obj:getModData()["AutoGateFrequency_Z"]
    frequency[4] = obj:getModData()["AutoGateFrequency_code"]
    return frequency
end

---Connects a controller to a gate, copying it's frequency
---@param controller InventoryItem Controller without a frequency
---@param gate IsoThumpable Gate with a motor installed
---@return boolean Returns true if the action is successful, if not, returns false
function ISAutoGateUtils.connectGateController(controller, gate)
	local frequency = ISAutoGateUtils.getFrequency(gate)
	if frequency then
		local fullGate = ISAutoGateUtils.getFullGate(ISAutoGateUtils.getGateFromFrequency(frequency))
		local code = ZombRand(100, 9999)
		for i = 1, #fullGate do
			fullGate[i]:getModData()["AutoGateFrequency_code"] = code
		end
		controller:getModData()["AutoGateFrequency_X"] = frequency[1]
		controller:getModData()["AutoGateFrequency_Y"] = frequency[2]
		controller:getModData()["AutoGateFrequency_Z"] = frequency[3]
		controller:getModData()["AutoGateFrequency_code"] = code
		controller:setName(getText("IGUI_AutoGate_GateName") .. " - No. ".. code)
		controller:setCustomName(true)

		print(string.format("DEBUG: Controller connected! \nPOS: \nX: %d", frequency[1]))
		print(string.format("\nY: %d\nZ: %d\nCode: %d", frequency[2], frequency[3], code))
		return true
	end
	return false
end

---Copies the frequency from one controller to another
---@param controllerFrom InventoryItem Controller with a frequency
---@param controllerTo InventoryItem Controller without a frequency
---@return boolean Returns true if the action is successful, if not, returns false
function ISAutoGateUtils.makeControllerCopy(controllerFrom, controllerTo)
	local frequency = ISAutoGateUtils.getFrequency(controllerFrom)
	if frequency then
		controllerTo:getModData()["AutoGateFrequency_X"] = frequency[1]
		controllerTo:getModData()["AutoGateFrequency_Y"] = frequency[2]
		controllerTo:getModData()["AutoGateFrequency_Z"] = frequency[3]
		controllerTo:getModData()["AutoGateFrequency_code"] = frequency[4]
		controllerTo:setName(controllerFrom:getName())
		controllerTo:setCustomName(true)
		ISAutoGateUtils.debugMessage("Controller frequency copied")
		return true
	end
	return false
end

---Empties controller frequency, disconnecting it from the gate previously connected
---@param controller InventoryItem Controller with a frequency
---@return boolean Returns true if the action is successful, if not, returns false
function ISAutoGateUtils.clearController(controller)
	local frequency = ISAutoGateUtils.getFrequency(controller)
	if not frequency then
		return false
	end
	controller:getModData()["AutoGateFrequency_X"] 	  = nil
	controller:getModData()["AutoGateFrequency_Y"] 	  = nil
	controller:getModData()["AutoGateFrequency_Z"] 	  = nil
	controller:getModData()["AutoGateFrequency_code"] = nil
	controller:setName(getItemNameFromFullType("AutoGate.GateController"))
	controller:setCustomName(false)
	ISAutoGateUtils.debugMessage("Controller frequency cleared")
	return true
end


--[[**********************************************************************************]]--


------------------ Returning file for 'require' ------------------
return ISAutoGateUtils