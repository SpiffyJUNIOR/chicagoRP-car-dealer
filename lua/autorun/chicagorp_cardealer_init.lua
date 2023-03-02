AddCSLuaFile()

for _, f in ipairs(file.Find("chicagorp_cardealer/*.lua", "LUA")) do
    if string.Left(f, 3) == "sv_" then
        if SERVER then 
            include("chicagorp_cardealer/" .. f) 
        end
    elseif string.Left(f, 3) == "cl_" then
        if CLIENT then
            include("chicagorp_cardealer/" .. f)
        else
            AddCSLuaFile("chicagorp_cardealer/" .. f)
        end
    elseif string.Left(f, 3) == "sh_" then
        AddCSLuaFile("chicagorp_cardealer/" .. f)
        include("chicagorp_cardealer/" .. f)
    else
        print("chicagoRP Car Dealer detected unaccounted for lua file '" .. f .. "' - check prefixes!")
    end
    print("chicagoRP Car Dealer successfully loaded!")
end
