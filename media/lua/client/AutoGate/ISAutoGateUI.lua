
----------------------------------------------------------------------------------------------
--- AutomaticGateMotorsPROTOTYPE
--- @author: peteR_pg
--- Steam profile: https://steamcommunity.com/id/peter_pg/
--- GitHub Repository: https://github.com/Susjin/AutomaticGateMotorsPROTOTYPE

--- Main file with all functions related to the User Interface
--- @class ISAutoGateUI
local ISAutoGateUI = {}
----------------------------------------------------------------------------------------------
--Setting up locals
local ISAutoGateUtils = require "AutoGate/ISAutoGateUtils"
local ISAutoGateTooltip = require "AutoGate/ISAutoGateTooltip"
local ISAutoGateInstallAction = require "AutoGate/ISAutoGateInstallAction"

local BlowtorchUtils = ISBlacksmithMenu

---Equips items for TimedAction
---@param player IsoPlayer Player doing the action
---@return DrainableComboItem, DrainableComboItem
function ISAutoGateUI.checkAndEquipInstallItems(player)
    local playerInventory = player:getInventory()

    --Checking if equipped items are valid
    local equippedPrimary = player:getPrimaryHandItem()
    local alreadyEquippedPrimary = false
    if instanceof(equippedPrimary, "DrainableComboItem") then
        alreadyEquippedPrimary = ISAutoGateUtils.hasDeltaLeft(equippedPrimary, "BlowTorch")
    end
    local equippedSecondary = player:getSecondaryHandItem()
    local alreadyEquippedSecondary = false
    if instanceof(equippedSecondary, "DrainableComboItem") then
        alreadyEquippedSecondary = ISAutoGateUtils.hasDeltaLeft(equippedSecondary, "WeldingRods")
    end
    --Setting correct items
    local blowtorch = BlowtorchUtils.getBlowTorchWithMostUses(playerInventory)
    if alreadyEquippedPrimary then
        blowtorch = equippedPrimary
    end
    local weldingrods = ISAutoGateUtils.getWeldingRodsWithMostUses(playerInventory)
    if alreadyEquippedSecondary then
        weldingrods = equippedSecondary
    end
    local weldingmask = playerInventory:getItemFromTypeRecurse("WeldingMask")

    ISInventoryPaneContextMenu.transferIfNeeded(player, blowtorch)
    ISInventoryPaneContextMenu.transferIfNeeded(player, weldingrods)
    luautils.equipItems(player, blowtorch, weldingrods)
    ISInventoryPaneContextMenu.wearItem(weldingmask, player:getPlayerNum())
    return blowtorch, weldingrods
end

---Executes the TimedAction Install
---@param player IsoPlayer Player doing the action
---@param gate IsoThumpable Gate without motor installed
function ISAutoGateUI.queueInstallAutomaticGateMotor(player, gate)
    local playerSquare = player:getSquare()
    local gateCornerObject = ISAutoGateUtils.getGateFromSquare(ISAutoGateUtils.getGateCorner(gate))

    local gateSquare = gateCornerObject:getSquare()
    local gateOppositeSquare = gateCornerObject:getOppositeSquare()
    local doorSquare = gateOppositeSquare:DistTo(playerSquare) < gateSquare:DistTo(playerSquare) and gateOppositeSquare or gateSquare

    ISTimedActionQueue.add(ISWalkToTimedAction:new(player, doorSquare))
    local blowtorch, weldingrods = ISAutoGateUI.checkAndEquipInstallItems(player)
    ISTimedActionQueue.add(ISAutoGateInstallAction:new(player, gateCornerObject, blowtorch, weldingrods))
end

---Adds the Install Automatic Motor option to a context menu
---@param player IsoPlayer Player doing the action
---@param context ISContextMenu ContextMenu when clicked on a gate
---@param gate IsoThumpable Gate without motor installed
function ISAutoGateUI.addOptionInstallAutomaticMotor(player, context, gate)
    ------------------ Setting variables ------------------
    local playerInventory = player:getInventory()
    local metalWelding = player:getPerkLevel(Perks.MetalWelding)
    local gateOpen = gate:IsOpen()
    local gateTextureName = tostring(gate:getTextureName())
    local components = playerInventory:getCountTypeRecurse("GateComponents")
    local blowtorch = BlowtorchUtils.getBlowTorchWithMostUses(playerInventory)
    local blowtorchUses = 0
    local weldingrods = ISAutoGateUtils.getWeldingRodsWithMostUses(playerInventory)
    local weldingrodsUses = 0
    local weldingmask = playerInventory:getCountTypeRecurse("WeldingMask")
    ------------------ Running checks ------------------
    if blowtorch   ~= nil then blowtorchUses = blowtorch:getDelta() end
    if weldingrods ~= nil then weldingrodsUses = weldingrods:getDelta() end
    ------------------ Adding option and tooltip ------------------
    local installOption = context:addOption(getText("ContextMenu_AutoGate_InstallComponents"), player, ISAutoGateUI.queueInstallAutomaticGateMotor, gate)
    if 	(metalWelding < 3) or (gateOpen) or (blowtorchUses < 0.09 ) or (weldingrodsUses < 0.08) or (weldingmask < 1) or (components < 1) then
        installOption.notAvailable = true
    end
    ISAutoGateTooltip.installGate(installOption, components, blowtorchUses, weldingrodsUses, weldingmask, metalWelding, gateOpen, gateTextureName)
end

function ISAutoGateUI.connectController(gate, emptyController, player)
    if ISAutoGateUtils.connectGateController(emptyController, gate) then
        HaloTextHelper.addText(player, getText("IGUI_AutoGate_ConnectControllerDone"), HaloTextHelper.getColorGreen())
        ISInventoryPage.dirtyUI() --Refresh inventory
    end
end

function ISAutoGateUI.copyController(controller, emptyController, player)
    if ISAutoGateUtils.makeControllerCopy(controller, emptyController) then
        HaloTextHelper.addText(player, getText("IGUI_AutoGate_CopyingDone"), HaloTextHelper.getColorGreen())
        ISInventoryPage.dirtyUI() --Refresh inventory
    end
end

function ISAutoGateUI.clearController(controller, player)
    if ISAutoGateUtils.clearController(controller) then
        HaloTextHelper.addText(player, getText("IGUI_AutoGate_ClearControllerDone"), HaloTextHelper.getColorGreen())
        ISInventoryPage.dirtyUI() --Refresh inventory
    end
end

---Triggers when user Opens a ContextMenu on a gate
---@param playerNum number PlayerID
---@param contextMenu ISContextMenu Main ContextMenu
---@param worldObjects IsoObject[] Contains all objects in mouse position
function ISAutoGateUI.doWorldMenu(playerNum, contextMenu, worldObjects)
    local player = getSpecificPlayer(playerNum)
    local square = worldObjects[1]:getSquare()
    local gate = ISAutoGateUtils.getGateFromSquare(square)

    --If a gate exists in the clicked square then
    if gate then
        --To counterpart some bizarre problems with gate IsoGridSquare, all functions will work with the Corner object
        gate = ISAutoGateUtils.getGateFromSquare(ISAutoGateUtils.getGateCorner(gate))
        local gateFrequency = ISAutoGateUtils.getFrequency(gate)
        --Checks if gate have a automatic motor installed
        if gateFrequency then
            ------------------ Setting variables ------------------
            local gateFrequencyCode = gateFrequency[4]
            local electrical = player:getPerkLevel(Perks.Electricity)
            local itemConnectedController = ISAutoGateUtils.findControllerOnPlayer(player, gateFrequencyCode)
            local emptyControllers = ISAutoGateUtils.findControllerOnPlayer(player, nil)
            local playerDistanceValid = ISAutoGateUtils.checkDistanceToGate(player, gate)
            ------------------ Use & Lock Options ------------------
            if (itemConnectedController and playerDistanceValid) then
                local useFromGateMenu  = contextMenu:addOptionOnTop(getText("ContextMenu_AutoGate_UseController"), gateFrequency, ISAutoGateUtils.toggleAutomaticGate, player)
            end
            if not gateFrequencyCode then
                local connectOption = contextMenu:addOption(getText("ContextMenu_AutoGate_ConnectController"), gate, ISAutoGateUI.connectController, emptyControllers[1], player)
                if (electrical < 1) or (#emptyControllers < 1) then connectOption.notAvailable = true end
                ISAutoGateTooltip.connectController(connectOption, #emptyControllers, electrical, gate:getTextureName())
            end
        else
            if ISAutoGateUtils.predicateInstallOption(player) then
                ISAutoGateUI.addOptionInstallAutomaticMotor(player, contextMenu, gate)
            end
        end
    end
end

---Triggers when user Opens a ContextMenu on a gate controller
---@param playerNum number PlayerID
---@param contextMenu ISContextMenu Main ContextMenu
---@param inventoryItems table Contains all objects on the player selected slot
function ISAutoGateUI.doInventoryMenu(playerNum, contextMenu, inventoryItems)
    local player = getSpecificPlayer(playerNum)
    local items = inventoryItems
    if not instanceof(inventoryItems[1], "InventoryItem") then
        items = inventoryItems[1].items
    end

    --Checking every controller on player's inventory and if it is connected
    for i = 1, #items do
        local itemInCheck = items[i]
        if instanceof(itemInCheck, "InventoryItem") then
            if itemInCheck:getType() == "GateController" then
                local controllerFrequency = ISAutoGateUtils.getFrequency(itemInCheck)
                if controllerFrequency then
                    ------------------ Setting variables ------------------
                    ---@type IsoThumpable
                    local gate = ISAutoGateUtils.getGateFromFrequency(controllerFrequency)
                    local gateExists = gate and true or false
                    ---@type InventoryItem
                    local controller = itemInCheck
                    local electrical = player:getPerkLevel(Perks.Electricity)
                    local emptyControllers = ISAutoGateUtils.findControllerOnPlayer(player, nil)
                    local playerDistanceValid = ISAutoGateUtils.checkDistanceToGate(player, gate)
                    ------------------ Use Controller Option ------------------
                    local useControllerOption = contextMenu:addOptionOnTop(getText("ContextMenu_AutoGate_UseController"), gate, ISAutoGateUtils.toggleAutomaticGate, player)
                    if (not gateExists) or (not playerDistanceValid) then useControllerOption.notAvailable = true end
                    ------------------ Copy Controller Option ------------------
                    local copyControllerOption = contextMenu:addOption(getText("ContextMenu_AutoGate_Copy"), controller, ISAutoGateUI.copyController, emptyControllers[1], player)
                    if (electrical < 1) or (#emptyControllers < 1) then copyControllerOption.notAvailable = true end
                    ISAutoGateTooltip.copyController(copyControllerOption, #emptyControllers, electrical)
                    ------------------ Clear Controller Option ------------------
                    local clearControllerOption = contextMenu:addOption(getText("ContextMenu_AutoGate_ClearController"), controller, ISAutoGateUI.clearController, player)
                    if (electrical < 1) then clearControllerOption.notAvailable = true end
                    ISAutoGateTooltip.clearController(clearControllerOption, electrical)
                break
                end
            end
        end
    end
end

--Register Events
Events.OnFillWorldObjectContextMenu.Add(ISAutoGateUI.doWorldMenu)
Events.OnFillInventoryObjectContextMenu.Add(ISAutoGateUI.doInventoryMenu)



------------------ Returning file for 'require' ------------------
return ISAutoGateUI