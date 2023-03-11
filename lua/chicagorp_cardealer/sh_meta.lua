local ENTITY = FindMetaTable("Entity")

local simfphys_stats = {
    {"Mass"},
    {"FrontHeight"},
    {"FrontConstant"},
    {"FrontDamping"},
    {"FrontRelativeDamping"},
    {"RearHeight"},
    {"RearConstant"},
    {"RearDamping"},
    {"RearRelativeDamping"},
    {"FastSteeringAngle"},
    {"SteeringFadeFastSpeed"},
    {"TurnSpeed"},
    {"MaxGrip"},
    {"Efficiency"},
    {"GripOffset"},
    {"BrakePower"},
    {"IdleRPM"},
    {"LimitRPM"},
    {"PeakTorque"},
    {"PowerbandStart"},
    {"PowerbandEnd"},
    {"PowerBias"},
    {"DifferentialGear"},
    {"Gears"}
}

local countries = {
    ["Australia"] = "AU",
    ["Austria"] = "AT",
    ["Belgium"] = "BE",
    ["Canada"] = "CA",
    ["China"] = "CN",
    ["France"] = "FR",
    ["Germany"] = "DE",
    ["India"] = "IN",
    ["Italy"] = "IT",
    ["Japan"] = "JP",
    ["Netherlands"] = "NL",
    ["Poland"] = "PL",
    ["Russia"] = "RU",
    ["South Korea"] = "KR",
    ["Spain"] = "ES",
    ["Sweden"] = "SE",
    ["United Kingdom"] = "GB",
    ["United States"] = "US"
}

local function removename(tbl)
	if !istable(tbl) or table.IsEmpty(tbl) then return end
	local newobject = tbl

	newobject.PrintName = nil
	newobject.EntityName = nil

	return newobject
end

---------------------------------
-- chicagoRPCarDealer.AddManufacturer
---------------------------------
-- Desc:		Adds a manufacturer to the global manufacturer table.
-- State:		Shared
-- Arg One:		Manufacturer table.
function chicagoRPCarDealer.AddManufacturer(tbl)
	local seqtable = chicagoRPCarDealer.Manufacturers
	local hashtable = chicagoRPCarDealer.Manufacturers_HashTable

	table.insert(seqtable, tbl)
    hashtable[tbl.PrintName] = removename(tbl)
    hashtable[tbl.PrintName].index = #hashtable + 1
end

---------------------------------
-- chicagoRPCarDealer.AddVehicle
---------------------------------
-- Desc:		Adds a vehicle to the global vehicle table.
-- State:		Shared
-- Arg One:		Car table.
function chicagoRPCarDealer.AddVehicle(tbl)
	local seqtable_M = chicagoRPCarDealer.Manufacturers
	local hashtable_M = chicagoRPCarDealer.Manufacturers_HashTable
	local seqtable = chicagoRPCarDealer.Vehicles
	local hashtable = chicagoRPCarDealer.Vehicles_HashTable
	local manufacturerindex = hashtable_M[tbl.Manufacturer].index

	table.insert(seqtable, tbl)
    hashtable[tbl.EntityName] = removename(tbl)
    hashtable[tbl.EntityName].index = #hashtable + 1

    table.insert(seqtable_M[manufacturerindex], tbl.EntityName)
    hashtable_M[tbl.Manufacturer].[tbl.EntityName] = true
    hashtable_M[tbl.Manufacturer].[tbl.EntityName].index = #seqtable_M[manufacturerindex] + 1
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
	local carindex = hashtable[tbl.Vehicle].index

	table.insert(seqtable[carindex].upgradeslots, carindex, tbl)
	hashtable[tbl.Vehicle].upgradeslots[tbl.PrintName] = tbl
	hashtable[tbl.Vehicle].upgradeslots[tbl.PrintName].index = #hashtable.upgradeslots + 1
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
	local carindex = hashtable[tbl.Vehicle].index
	local slotindex = hashtable[tbl.Vehicle].upgradeslots[tbl.Slot].index

	table.insert(seqtable[tbl.Vehicle].upgradeslots[slotindex], tbl)
	hashtable[tbl.Vehicle].upgradeslots[tbl.Slot][tbl.PrintName] = tbl
	hashtable[tbl.Vehicle].upgradeslots[tbl.Slot][tbl.PrintName].index = #hashtable.upgradeslots[tbl.Slot] + 1
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
-- chicagoRPCarDealer.GetCountryCode
---------------------------------
-- Desc:		Gets a country's ISO 3166-1 alpha-2 code.
-- State:		Shared
-- Arg One:		String - Country string.
-- Returns: 	String - ISO 3166-1 alpha-2 Country code.
function chicagoRPCarDealer.GetCountryCode(ctrystr) -- memory usage? whats that???
	if string.len(ctrystr) == 2 then return ctrystr end

	return countries[ctrystr]
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

	return self.UpgadeSlots
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

	for i = 1, #self.UpgadeSlots do
		upgradetable[i] = self.UpgadeSlots[i]
	end

	return upgradetable
end





