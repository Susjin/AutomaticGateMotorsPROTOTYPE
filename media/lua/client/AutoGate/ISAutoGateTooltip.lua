
----------------------------------------------------------------------------------------------
--- Main file with all functions related to the tooltips
--- @class ISAutoGateTooltip
local ISAutoGateTooltip = {}

--- AutomaticGateMotorsPROTOTYPE
--- @author: peteR_pg
--- Steam profile: https://steamcommunity.com/id/peter_pg/
--- GitHub Repository: https://github.com/Susjin/AutomaticGateMotorsPROTOTYPE
----------------------------------------------------------------------------------------------
--Setting up locals
local colors = {}
colors.colorWhite = " <RGB:1,1,1> "
colors.colorUse   = nil
colors.colorGood  = " <RGB:0,1,0> "
colors.colorBad   = " <RGB:1,0,0> "

--[[**********************************************************************************]]--

---Shows a tooltip for a InstallGate ContextMenu Option
---@param installOption table Contains a given option inside a ContextMenu
---@param components number Amount of components on player's inventory
---@param blowtorch number Amount of blowtorch uses on player's inventory
---@param weldingrods number Amount of weldingrods uses on player's inventory
---@param weldingmask number Amount of weldingmasks on player's inventory
---@param metalWelding number MetalWelding level of the player
---@param gateOpen boolean True if the gate is open, false if not
---@param textureName string Name of the gate that will get motor installed
function ISAutoGateTooltip.installGate(installOption, components, blowtorch, weldingrods,
                                       weldingmask, metalWelding, gateOpen, textureName)
    installOption.toolTip = ISToolTip:new()
    installOption.toolTip:initialise()
    installOption.toolTip:setVisible(true)
    installOption.toolTip:setTexture(textureName)
    installOption.toolTip:setName(getText("Tooltip_AutoGate_InstallComponents"))

    installOption.toolTip.description = colors.colorWhite .. getText("Tooltip_AutoGate_InstallComponentsDescription") .. " <LINE><LINE> "
    installOption.toolTip.description = installOption.toolTip.description .. getText("Tooltip_craft_Needs") .. ": <LINE> "

    if blowtorch 	< 0.092 then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end;
    installOption.toolTip.description = installOption.toolTip.description .. colors.colorUse .. getItemNameFromFullType("Base.BlowTorch") .. " " .. getText("ContextMenu_Uses") .. " " .. tostring(math.ceil(blowtorch*10)) .. "/1 <LINE> ";

    if weldingrods 	< 0.084 then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
    installOption.toolTip.description = installOption.toolTip.description .. colors.colorUse .. getItemNameFromFullType("Base.WeldingRods") .. " " .. getText("ContextMenu_Uses") .. " " .. tostring(math.ceil(weldingrods*20)) .. "/2 <LINE> "

    if weldingmask 	< 1 	then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
    installOption.toolTip.description = installOption.toolTip.description .. colors.colorUse .. getItemNameFromFullType("Base.WeldingMask") .. " " .. tostring(weldingmask) .. "/1 <LINE> "

    if components 	< 1 	then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
    installOption.toolTip.description = installOption.toolTip.description .. colors.colorUse .. getItemNameFromFullType("AutoGate.GateComponents") .. " " .. tostring(components) .. "/1 <LINE><LINE> "

    if metalWelding < 3 	then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
    installOption.toolTip.description = installOption.toolTip.description .. colors.colorUse .. getText("IGUI_perks_MetalWelding") .. " " .. tostring(metalWelding) .. "/3 <LINE> "

    if gateOpen then installOption.toolTip.footNote = getText("Tooltip_AutoGate_CantInstallFootNote") end
end

---Shows a tooltip for a ConnectController ContextMenu Option
---@param connectOption table Contains a given option inside a ContextMenu
---@param amountEmpty number Amount of disconnected controllers on player inventory
---@param electrical number Electrical level of the Player
---@param textureName string Name of the gate to be connected to
function ISAutoGateTooltip.connectController(connectOption, amountEmpty, electrical, textureName)
    ---@type ISToolTip
    connectOption.toolTip = ISToolTip:new()
    connectOption.toolTip:initialise()
    connectOption.toolTip:setTexture(textureName)
    connectOption.toolTip:setVisible(true)
    connectOption.toolTip:setName(getText("Tooltip_AutoGate_Connecting"))

    connectOption.toolTip.description = colors.colorWhite .. getText("Tooltip_AutoGate_ConnectingDescription") .. " <LINE><LINE> "
    connectOption.toolTip.description = connectOption.toolTip.description .. getText("Tooltip_craft_Needs") .. ": <LINE> "

    if amountEmpty < 1 then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
    connectOption.toolTip.description = connectOption.toolTip.description .. colors.colorUse .. getItemNameFromFullType("AutoGate.GateController") .. " " .. tostring(amountEmpty) .. "/1 <LINE> "
    if electrical  < 1 then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
    connectOption.toolTip.description = connectOption.toolTip.description .. colors.colorUse .. " <LINE> " .. getText("IGUI_perks_Electricity") .. " " .. tostring(electrical) .. "/1 <LINE> "
end

------------------ Returning file for 'require' ------------------
return ISAutoGateTooltip
