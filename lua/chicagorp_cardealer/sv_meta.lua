local ENTITY = FindMetaTable("Entity")

---------------------------------
-- chicagoRPCarDealer.GiveVehicle
---------------------------------
-- Desc:		Gives a vehicle to a player.
-- State:		Server
-- Arg One:		String/Number - Vehicle Index.
function chicagoRPCarDealer.GiveVehicle(ply, vehinp)
	if !IsValid(ply) then return end
	-- sql query/add shit here
end

---------------------------------
-- ENTITY:SetVehicleOwner
---------------------------------
-- Desc:		Gets a vehicle's owner.
-- State:		Server
-- Arg One:		Entity - Player entity to set as owner.
function ENTITY:SetVehicleOwner(ply)
	self:keysOwn(ply)
end