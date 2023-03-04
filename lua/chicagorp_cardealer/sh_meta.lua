local ENTITY = FindMetaTable("Entity")

local simfphys_stats = {
    {
        "Mass"
    }, {
        "FrontHeight"
    }, {
        "FrontConstant"
    }, {
        "FrontDamping"
    }, {
        "FrontRelativeDamping"
    }, {
        "RearHeight"
    }, {
        "RearConstant"
    }, {
        "RearDamping"
    }, {
        "RearRelativeDamping"
    }, {
        "FastSteeringAngle"
    }, {
        "SteeringFadeFastSpeed"
    }, {
        "TurnSpeed"
    }, {
        "MaxGrip"
    }, {
        "Efficiency"
    }, {
        "GripOffset"
    }, {
        "BrakePower"
    }, {
        "IdleRPM"
    }, {
        "LimitRPM"
    }, {
        "PeakTorque"
    }, {
        "PowerbandStart"
    }, {
        "PowerbandEnd"
    }, {
        "PowerBias"
    }, {
        "DifferentialGear"
    }, {
        "Gears"
    }
}

---------------------------------
-- chicagoRPCarDealer.AddManufacturer
---------------------------------
-- Desc:		Adds a manufacturer to the global manufacturer table.
-- State:		Shared
-- Arg One:		Manufacturer table.
function chicagoRPCarDealer.AddManufacturer(tableinput)
	local seqtable = chicagoRPCarDealer.Manufacturers
	local hashtable = chicagoRPCarDealer.Manufacturers_HashTable

	table.insert(seqtable, tableinput)
    hashtable[tbl.name] = tbl
    hashtable[tbl.name].index = #hashtable + 1
end

---------------------------------
-- chicagoRPCarDealer.AddVehicle
---------------------------------
-- Desc:		Adds a vehicle to the global vehicle table.
-- State:		Shared
-- Arg One:		Car table.
function chicagoRPCarDealer.AddVehicle(tbl)
	-- chicagoRPCarDealer.[tbl.manufacturer] = tbl
	local seqtable = chicagoRPCarDealer.Vehicles
	local hashtable = chicagoRPCarDealer.Vehicles_HashTable

	tbl.upgradeslots = {}
	table.insert(seqtable, tbl)
    hashtable[tbl.name] = tbl
    hashtable[tbl.name].index = #hashtable + 1
end

---------------------------------
-- chicagoRPCarDealer.AddUpgradeSlot
---------------------------------
-- Desc:		Creates an upgrade slot for a vehicle.
-- State:		Shared
-- Arg One:		Slot table.
function chicagoRPCarDealer.AddUpgradeSlot(tbl)
	local seqtable = chicagoRPCarDealer.Vehicles
	local hashtable = chicagoRPCarDealer.Vehicles_HashTable
	local carindex = hashtable[tbl.vehicle].index

	table.insert(seqtable[carindex].upgradeslots, carindex, tbl)
	hashtable[tbl.vehicle].upgradeslots[tbl.slot] = tbl
	hashtable[tbl.vehicle].upgradeslots[tbl.slot].index = #hashtable.upgradeslots + 1
end

---------------------------------
-- chicagoRPCarDealer.AddUpgrade
---------------------------------
-- Desc:		Creates an upgrade for a vehicle's specified upgrade slot.
-- State:		Shared
-- Arg One:		Upgrade table.
function chicagoRPCarDealer.AddUpgrade(tbl)
	local seqtable = chicagoRPCarDealer.Vehicles
	local hashtable = chicagoRPCarDealer.Vehicles_HashTable
	local carindex = hashtable[tbl.vehicle].index
	local slotindex = hashtable[tbl.vehicle].upgradeslots[tbl.slot].index

	table.insert(seqtable[tbl.].upgradeslots[slotindex], tbl)
	hashtable[tbl.vehicle].upgradeslots[tbl.slot][tbl.upgradename] = tbl
	hashtable[tbl.vehicle].upgradeslots[tbl.slot][tbl.upgradename].index = #hashtable.upgradeslots[tbl.slot] + 1
end

---------------------------------
-- chicagoRPCarDealer.GetManufacturers
---------------------------------
-- Desc:		Gets the prone animation state of the given player.
-- State:		Shared
-- Arg One:		Bool - Return hashtable? (Default: False)
-- Returns: 	Table - Manufacturers.
function chicagoRPCarDealer.GetManufacturers(hashbool)
	if hashbool then
		return chicagoRPCarDealer.Manufacturers_HashTable
	elseif !hashbool or hashbool == nil then
		return chicagoRPCarDealer.Manufacturers
	end
end

---------------------------------
-- chicagoRPCarDealer.GetManufacturer
---------------------------------
-- Desc:		Gets the manufacturer from a string or index input.
-- State:		Shared
-- Arg One:		String/Number - Index.
-- Returns: 	Table - Manufacturer.
function chicagoRPCarDealer.GetManufacturer(inp)
	local typ = type(inp)
	local seqtable = chicagoRPCarDealer.Manufacturers
	local hashtable = chicagoRPCarDealer.Manufacturers_HashTable

	if typ == "number" then
		return seqtable[inp]
	elseif typ == "string" then
		return hashtable[inp]
	end
end

---------------------------------
-- chicagoRPCarDealer.GetVehicleBaseStats
---------------------------------
-- Desc:		Gets a vehicle's base info from a string or index input.
-- State:		Shared
-- Arg One:		String/Number - Index.
-- Returns: 	Table - Car's base stats.
function chicagoRPCarDealer.GetVehicleInfo(inp)
	local typ = type(inp)
	local seqtable = chicagoRPCarDealer.Vehicles
	local hashtable = chicagoRPCarDealer.Vehicles_HashTable

	if typ == "number" then
		return seqtable[inp]
	elseif typ == "string" then
		return hashtable[inp]
	end
end

---------------------------------
-- chicagoRPCarDealer.GetUpgradeSlots
---------------------------------
-- Desc:		Gets a vehicle's upgrade slots from a string or index input.
-- State:		Shared
-- Arg One:		String/Number - Index.
-- Returns: 	Table - Upgrade slots.
function chicagoRPCarDealer.GetUpgradeSlots(inp)
	local typ = type(inp)
	local seqtable = chicagoRPCarDealer.Vehicles
	local hashtable = chicagoRPCarDealer.Vehicles_HashTable

	if typ == "number" then
		return seqtable[inp].upgradeslots
	elseif typ == "string" then
		return hashtable[inp].upgradeslots
	end
end

---------------------------------
-- chicagoRPCarDealer.GetUpgrades
---------------------------------
-- Desc:		Gets a vehicle's upgrades from a specified vehicle's upgrade slot.
-- State:		Shared
-- Arg One:		String/Number - Vehicle Index.
-- Arg Two:		String/Number - Slot Index.
-- Returns: 	Table - Upgrades.
function chicagoRPCarDealer.GetUpgrades(vehinp, slotinp)
	local vehtyp = type(vehinp)
	local slottyp = type(slotinp)
	local seqtable = chicagoRPCarDealer.Vehicles
	local hashtable = chicagoRPCarDealer.Vehicles_HashTable

	if vehtyp == "number" and slottyp == "number" then
		return seqtable[carinp].upgradeslots[slotinp]
	elseif vehtyp == "string" and slottyp == "string" then
		return hashtable[carinp].upgradeslots[slotinp]
	end
end

---------------------------------
-- chicagoRPCarDealer.GetUpgradeStats
---------------------------------
-- Desc:		Gets an upgrade's stats from a specified index.
-- State:		Shared
-- Arg One:		String/Number - Vehicle Index.
-- Arg Two:		String/Number - Slot Index.
-- Arg Two:		String/Number - Upgrade Index.
-- Returns: 	Table - Upgrade stats.
function chicagoRPCarDealer.GetUpgradeStats(vehinp, slotinp, upginp)
	local vehtyp = type(vehinp)
	local slottyp = type(slotinp)
	local upgtype = type(upginp)
	local seqtable = chicagoRPCarDealer.Vehicles
	local hashtable = chicagoRPCarDealer.Vehicles_HashTable

	if vehtyp == "number" and slottyp == "number" and upgtype == "number" then
		return seqtable[carinp].upgradeslots[slotinp][upginp]
	elseif vehtyp == "string" and slottyp == "string" and upgtype == "string" then
		return hashtable[carinp].upgradeslots[slotinp][upginp]
	end
end

---------------------------------
-- ENTITY:GetVehicleLightTable
---------------------------------
-- Desc:		Gets a vehicle's light table.
-- State:		Shared
-- Returns: 	Table - Vehicle's light tbale.
function GetVehicleLightTable()
	return self.LightsTable
end

---------------------------------
-- ENTITY:GetVehicleName
---------------------------------
-- Desc:		Gets a vehicle's class name.
-- State:		Shared
-- Returns: 	String - Vehicle's class name.
function ENTITY:GetVehicleName()
	if self.IsSimfphyscar and self:IsSimfphyscar() then
		return self:GetSpawn_List()
	else
		return self:GetClass()
	end
end

---------------------------------
-- ENTITY:GetVehicleOwner
---------------------------------
-- Desc:		Gets a vehicle's owner.
-- State:		Shared
-- Returns: 	Entity - Vehicle's owner.
function ENTITY:GetVehicleOwner()
	if !self:IsVehicle() or !self:isKeysOwnable() or !self:isKeysOwned() then return end
	
	return self:getDoorOwner()
end

---------------------------------
-- ENTITY:GetVehicleBaseStats
---------------------------------
-- Desc:		Gets a vehicle's base (unmodified) stats.
-- State:		Shared
-- Returns: 	Table - Vehicle's base (unmodified) stats.
function ENTITY:GetVehicleBaseStats()
	if !self:IsVehicle() then return end
	local spawnlist = list.Get("simfphys_vehicles")
	local stattable = spawnlist[self:GetVehicleName()]
	local arraytbl = {}

	for i = 1, #simfphys_stats do
		arraytbl.[simfphys_stats[i]] = stattable.Members[simfphys_stats[i]]
	end

	return arraytbl
end

---------------------------------
-- ENTITY:GetVehicleStats
---------------------------------
-- Desc:		Gets a vehicle's current stats.
-- State:		Shared
-- Returns: 	Table - Vehicle's current stats.
function ENTITY:GetVehicleStats() -- stats including upgrades
	if !self:IsVehicle() then return end
	local arraytbl = {}

	for i = 1, #simfphys_stats do
		arraytbl.[simfphys_stats[i]] = self[simfphys_stats[i]]
	end

	return arraytbl
end

---------------------------------
-- ENTITY:GetVehicleUpgradeSlots
---------------------------------
-- Desc:		Gets a vehicle's upgrade slots.
-- State:		Shared
-- Returns: 	Table - Vehicle's upgrade slots.
function ENTITY:GetVehicleUpgradeSlots()
	if !self:IsVehicle() then return end

	return self.upgradeslots
end

---------------------------------
-- ENTITY:GetVehicleUpgrades
---------------------------------
-- Desc:		Gets a vehicle's equipped upgrades.
-- State:		Shared
-- Returns: 	Table - Vehicle's equipped upgrades.
function ENTITY:GetVehicleUpgrades()
	if !self:IsVehicle() then return end
	local upgradetable = {}

	for i = 1, #self.upgradeslots do
		upgradetabel[i] = self.upgradeslots[i]
	end

	return upgradetable
end





