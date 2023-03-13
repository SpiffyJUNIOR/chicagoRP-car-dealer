util.AddNetworkString("chicagoRP_cardealer_dealerUI")
util.AddNetworkString("chicagoRP_cardealer_garageUI")
util.AddNetworkString("chicagoRP_cardealer_mechanicUI")

util.AddNetworkString("chicagoRP_cardealer_starttestdrive")
util.AddNetworkString("chicagoRP_cardealer_endtestdrive")

local function EndTestDrive(ply, vehicle)
	if !IsValid(ply) or !IsValid(vehicle) then return end

	if timer.Exists(timername) then
		timer.Remove(timername)
	end

	vehicle:Remove()

	net.Start("chicagoRP_cardealer_endtestdrive")
	net.Send(ply)
end

net.Receive("chicagoRP_cardealer_starttestdrive", function(len, ply)
	local vehicle = -- send data to spawn spot entity, returns vehicle ent
	local plyname = ply:Name()
	local timername = "chicagoRP_cardealer_testdrive-" .. plyname

	timer.Create(timername, 30, 1, EndTestDrive(ply, vehicle))
	vehicle.testdrive = true -- for external compat

	local oOnRemove = vehicle.OnRemove
	function vehicle:OnRemove() -- assuming ent is removed when health reaches 0, add compat for vcmod and svmod
		EndTestDrive(ply, vehicle)
	end
end
