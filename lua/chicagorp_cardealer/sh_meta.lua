local ENTITY = FindMetaTable("Entity")

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
-- chicagoRPCarDealer.AddCar
---------------------------------
-- Desc:		Adds a car to the global car table.
-- State:		Shared
-- Arg One:		Car table.
function chicagoRPCarDealer.AddCar(tbl)
	-- chicagoRPCarDealer.[tbl.manufacturer] = tbl
	local seqtable = chicagoRPCarDealer.Cars
	local hashtable = chicagoRPCarDealer.Cars_HashTable

	tbl.upgradeslots = {}
	table.insert(seqtable, tbl)
    hashtable[tbl.name] = tbl
    hashtable[tbl.name].index = #hashtable + 1
end

---------------------------------
-- chicagoRPCarDealer.AddUpgradeSlot
---------------------------------
-- Desc:		Creates an upgrade slot for a car.
-- State:		Shared
-- Arg One:		Slot table.
function chicagoRPCarDealer.AddUpgradeSlot(tbl)
	local seqtable = chicagoRPCarDealer.Cars
	local hashtable = chicagoRPCarDealer.Cars_HashTable
	local carindex = hashtable[tbl.car].index

	table.insert(seqtable[carindex].upgradeslots, carindex, tbl)
	hashtable[tbl.car].upgradeslots[tbl.slot] = tbl
	hashtable[tbl.car].upgradeslots[tbl.slot].index = #hashtable.upgradeslots + 1
end

---------------------------------
-- chicagoRPCarDealer.AddUpgrade
---------------------------------
-- Desc:		Creates an upgrade for a car's specified upgrade slot.
-- State:		Shared
-- Arg One:		Upgrade table.
function chicagoRPCarDealer.AddUpgrade(tbl)
	local seqtable = chicagoRPCarDealer.Cars
	local hashtable = chicagoRPCarDealer.Cars_HashTable
	local carindex = hashtable[tbl.car].index
	local slotindex = hashtable[tbl.car].upgradeslots[tbl.slot].index

	table.insert(seqtable[tbl.car].upgradeslots[slotindex], tbl)
	hashtable[tbl.car].upgradeslots[tbl.slot][tbl.upgradename] = tbl
	hashtable[tbl.car].upgradeslots[tbl.slot][tbl.upgradename].index = #hashtable.upgradeslots[tbl.slot] + 1
end

---------------------------------
-- chicagoRPCarDealer.GetManufacturers
---------------------------------
-- Desc:		Gets the prone animation state of the given player.
-- State:		Shared
-- Arg One:		Bool - Return hashtable? (Default: False)
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
-- chicagoRPCarDealer.GetCarBaseStats
---------------------------------
-- Desc:		Gets a car's base stats from a string or index input.
-- State:		Shared
-- Arg One:		String/Number - Index.
function chicagoRPCarDealer.GetCarBaseStats(inp)
	local seqtable = chicagoRPCarDealer.Cars
	local hashtable = chicagoRPCarDealer.Cars_HashTable

	if typ == "number" then
		return seqtable[inp]
	elseif typ == "string" then
		return hashtable[inp]
	end
end

---------------------------------
-- chicagoRPCarDealer.GetUpgradeSlots
---------------------------------
-- Desc:		Gets a car's base stats from a string or index input.
-- State:		Shared
-- Arg One:		String/Number - Index.
function chicagoRPCarDealer.GetUpgradeSlots(inp)
	local seqtable = chicagoRPCarDealer.Cars
	local hashtable = chicagoRPCarDealer.Cars_HashTable

	if typ == "number" then
		return seqtable[inp]
	elseif typ == "string" then
		return hashtable[tbl.car].upgradeslots[inp] -- fucking fix this
	end
end

---------------------------------
-- chicagoRPCarDealer.GetUpgradeSlot
---------------------------------
-- Desc:		Gets a car's base stats from a string or index input.
-- State:		Shared
-- Arg One:		String/Number - Index.
function chicagoRPCarDealer.GetUpgradeSlot()
	local seqtable = chicagoRPCarDealer.Cars
	local hashtable = chicagoRPCarDealer.Cars_HashTable
end

---------------------------------
-- chicagoRPCarDealer.GetUpgrades
---------------------------------
-- Desc:		Gets a car's base stats from a string or index input.
-- State:		Shared
-- Arg One:		String/Number - Index.
function chicagoRPCarDealer.GetUpgrades()
	local seqtable = chicagoRPCarDealer.Cars
	local hashtable = chicagoRPCarDealer.Cars_HashTable
end

---------------------------------
-- chicagoRPCarDealer.GetUpgradeStats
---------------------------------
-- Desc:		Gets a car's base stats from a string or index input.
-- State:		Shared
-- Arg One:		String/Number - Index.
function chicagoRPCarDealer.GetUpgradeStats()
	local seqtable = chicagoRPCarDealer.Cars
	local hashtable = chicagoRPCarDealer.Cars_HashTable
end

function ENTITY:GetCarBaseStats()
end

function ENTITY:GetCarStats()
end

function ENTITY:GetCarUpgradeSlots()
end

function ENTITY:GetCarUpgrades()
end





