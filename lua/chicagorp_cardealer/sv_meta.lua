local ENTITY = FindMetaTable("Entity")

---------------------------------
-- ENTITY:SetVehicleOwner
---------------------------------
-- Desc:		Gets a vehicle's owner.
-- State:		Server
-- Arg One:		Entity - Player entity to set as owner.
function ENTITY:SetVehicleOwner(ply)
	self:keysOwn(ply)
end