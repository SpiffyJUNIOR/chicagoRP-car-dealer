local OpenDealerFrame = nil
local OpenBrowseFrame = nil
local OpenScrollPanel = nil
local OpenPurchaseFrame = nil
local OpenComboBox = nil
local OpenModelPanel = nil
local searchstring = nil
local historytable = {} -- clearly defined structure needed (1: manufacturer scrollpos, 2: manufacturer opened, 3: browse scrollpos, 4: purchase panel's selected car)
local vehiclewheels = {}
local manufacturermats = {}
local countrymats = {}
local cubemapmats = {}
local paintmats = {}
local lerpStart = 0
local lerpTime = 0
local client = LocalPlayer()
local gradient1 = Color(230, 45, 40, 150)
local gradient2 = Color(245, 135, 70, 150)
local graycolor = Color(40, 40, 40, 200)
local darkgraycolor = Color(20, 20, 20, 200)
local defaultCamPos = Vector(50, 50, 50)
local defaultCamAng = Angle(0, 0, 40)
local rightangle = Angle(0, 90, 0)
local fallbackcolortbl = {255, 255, 255, 255}

local UIFuncs = UIFuncs or {}

local simfphyswheelatts = {
	[1] = "wheel_fl",
	[2] = "wheel_fr",
	[3] = "wheel_rl",
	[4] = "wheel_rr"
}

local simfphyswheelpos = {
	[1] = "CustomWheelPosFL",
	[2] = "CustomWheelPosFR",
	[3] = "CustomWheelPosRL",
	[4] = "CustomWheelPosRR",
	[5] = "CustomWheelPosML",
	[6] = "CustomWheelPosMR",
}

local simfphyswheelheight = {
	[1] = "FrontHeight",
	[2] = "FrontHeight",
	[3] = "RearHeight",
	[4] = "RearHeight",
	[5] = "RearHeight",
	[6] = "RearHeight",
}

local simfphyswheelbools = {
	[1] = false,
	[2] = true,
	[3] = false,
	[4] = true,
	[5] = false,
	[6] = true,
}

function isempty(s)
    return s == nil or s == ""
end

local function ismaterial(mat)
    return mat != nil and type(mat) == "material"
end

local function attachCurrency(str)
    local config = GAMEMODE.Config
    return config.currencyLeft and config.currency .. str or str .. config.currency
end

local function ManufacturerMaterials()
	for i = 1, #chicagoRPCarDealer.Manufacturers do
		if ismaterial(manufacturermats[i]) then continue end

		manufacturermats[i] = Material(chicagoRPCarDealer.Manufacturers[i].Icon, "smooth mips")
	end
end

local function CountryMaterials(manufacturertbl)
	local vehicleHashTable = chicagoRPCarDealer.Vehicles_HashTable

	for i = 1, #manufacturertbl do
		local vehicle = vehicleHashTable[i]
		local country = chicagoRPCarDealer.GetCountryCode(vehicle.Country)

		countrymats[country] = Material("materials/flags16/" .. country .. ".png", "mips")
	end
end

local function GCManufacturerMats()
	if table.IsEmpty(manufacturermats) then return end

	manufacturermats = {}
end

local function GCCountryMats()
	if table.IsEmpty(countrymats) then return end

	countrymats = {}
end

local function CenterElement(mainW, mainH, elementW, elementH)
	local centerX = mainW * (0.5) - elementW * 0.5
	local centerY = mainH * (0.5) - elementH * 0.5

	return centerX, centerY
end

local function CenterX(mainW, elementW)
	local centerX = mainW * (0.5) - elementW * 0.5

	return centerX
end

local function CenterY(mainH, elementH)
	local centerY = mainH * (0.5) - elementH * 0.5

	return centerY
end

local function OpenDealerUI()
	UIFuncs.DealerUI()
end

local function OpenBrowseUI(tbl, index)
	UIFuncs.BrowseUI(tbl, index)
end

local function OpenPurchaseUI(manufacturertbl, manuindex, vehicletbl)
	UIFuncs.PurchaseUI(manufacturertbl, manuindex, vehicletbl)
end

local function SetStaticCubemap(ent)
	if !IsValid(ent) then return end

	local matlist = ent:GetMaterials()

	for i = 1, #matlist do
		local mat = Material(matlist[i])

		if mat:IsError() then continue end
		local envmapparam = mat:GetString("$envmap")
		if chicagoRP_NPCShop.isempty(envmapparam) or mat:GetShader() != "VertexLitGeneric" then continue end

		mat:SetString("$envmap", "materials/chicagorp_cardealer/staticcubemap.hdr.vtf")
		mat:Recompute()

		-- local newmat = CreateMaterial("fancycubemapmat" .. i, "VertexLitGeneric", {
		-- 	mat:GetKeyValues()
		-- })

		-- cubemapmats[i] = newmat

		ent:SetSubMaterial(i, !mat)
	end
end

local function GCCubemapMats()
	if table.IsEmpty(cubemapmats) then return end

	for i = 1, #cubemapmats do
		cubemapmats[i] = nil
	end
end

local function GCCSEnts(tbl)
	if !istable(tbl) or table.IsEmpty(tbl) then return end

	for i = 1, #tbl do
		tbl[i]:Remove()
	end
end

net.Receive("chicagoRP_cardealer_endtestdrive", function(len)
	if IsValid(OpenDealerFrame) or IsValid(OpenBrowseFrame) or IsValid(OpenPurchaseFrame) then return end

	OpenPurchaseUI(chicagoRPCarDealer.Manufacturers[historytable[2]], historytable[2], chicagoRPCarDealer.Vehicles_HashTable[historytable[4]])
end)

local function SetCameraPos(pos)
	if IsValid(OpenModelPanel) then
		OpenModelPanel:SetCamPos(pos)
	end
end

local function SetCameraAng(ang)
	if IsValid(OpenModelPanel) then
		OpenModelPanel:SetLookAng(ang)
	end
end

local function BodyGroupIsValid(bodygroups, entity)
    for i = 1, #bodygroups do
        local mygroup = entity:GetBodygroup(i)

        for g_index = 1, table.Count(bodygroups[i]) do
            if mygroup == bodygroups[i][g_index] then return true end
        end
    end

    return false
end

local function ExhaustEffect(ent, simfphystbl, fThrottle, IdleRPM, LimitRPM)
    if !simfphystbl.ExhaustPositions then return end
    local scale = fThrottle * (0.2 + math.min(IdleRPM / LimitRPM, 1) * 0.8)^2

    for i = 1, table.Count(simfphystbl.ExhaustPositions) do
        if simfphystbl.ExhaustPositions[i].OnBodyGroups then
            if BodyGroupIsValid(simfphystbl.ExhaustPositions[i].OnBodyGroups, ent) then
                local effectdata = EffectData()
                effectdata:SetOrigin(simfphystbl.ExhaustPositions[i].pos)
                effectdata:SetAngles(simfphystbl.ExhaustPositions[i].ang)
                effectdata:SetMagnitude(scale)
                effectdata:SetEntity(ent)
                util.Effect("simfphys_exhaust", effectdata)
            end
        else
            local effectdata = EffectData()
            effectdata:SetOrigin(simfphystbl.ExhaustPositions[i].pos)
            effectdata:SetAngles(simfphystbl.ExhaustPositions[i].ang)
            effectdata:SetMagnitude(scale)
            effectdata:SetEntity(ent)
            util.Effect("simfphys_exhaust", effectdata)
        end
    end
end

local function GetForwardYaw(simfphystbl, ent)
	if !IsValid(ent) then return end

    ent.posepositions["Pose0_Pos_FL"] = simfphystbl.CustomWheels and ent:LocalToWorld(simfphystbl.CustomWheelPosFL) or ent:GetAttachment(ent:LookupAttachment("wheel_fl")).Pos
    ent.posepositions["Pose0_Pos_FR"] = simfphystbl.CustomWheels and ent:LocalToWorld(simfphystbl.CustomWheelPosFR) or ent:GetAttachment(ent:LookupAttachment("wheel_fr")).Pos
    ent.posepositions["Pose0_Pos_RL"] = simfphystbl.CustomWheels and ent:LocalToWorld(simfphystbl.CustomWheelPosRL) or ent:GetAttachment(ent:LookupAttachment("wheel_rl")).Pos
    ent.posepositions["Pose0_Pos_RR"] = simfphystbl.CustomWheels and ent:LocalToWorld(simfphystbl.CustomWheelPosRR) or ent:GetAttachment(ent:LookupAttachment("wheel_rr")).Pos
    ent.posepositions["Pose1_Pos_FL"] = simfphystbl.CustomWheels and ent:LocalToWorld(simfphystbl.CustomWheelPosFL) or ent:GetAttachment(ent:LookupAttachment("wheel_fl")).Pos
    ent.posepositions["Pose1_Pos_FR"] = simfphystbl.CustomWheels and ent:LocalToWorld(simfphystbl.CustomWheelPosFR) or ent:GetAttachment(ent:LookupAttachment("wheel_fr")).Pos
    ent.posepositions["Pose1_Pos_RL"] = simfphystbl.CustomWheels and ent:LocalToWorld(simfphystbl.CustomWheelPosRL) or ent:GetAttachment(ent:LookupAttachment("wheel_rl")).Pos
    ent.posepositions["Pose1_Pos_RR"] = simfphystbl.CustomWheels and ent:LocalToWorld(simfphystbl.CustomWheelPosRR) or ent:GetAttachment(ent:LookupAttachment("wheel_rr")).Pos
    ent.posepositions["PoseL_Pos_FL"] = ent:WorldToLocal(ent.posepositions.Pose1_Pos_FL)
    ent.posepositions["PoseL_Pos_FR"] = ent:WorldToLocal(ent.posepositions.Pose1_Pos_FR)
    ent.posepositions["PoseL_Pos_RL"] = ent:WorldToLocal(ent.posepositions.Pose1_Pos_RL)
    ent.posepositions["PoseL_Pos_RR"] = ent:WorldToLocal(ent.posepositions.Pose1_Pos_RR)
    ent.VehicleData["suspensiontravel_fl"] = simfphystbl.CustomWheels and simfphystbl.FrontHeight or math.Round((ent.posepositions.Pose0_Pos_FL - ent.posepositions.Pose1_Pos_FL):LengthSqr(), 2) -- originally Length()
    ent.VehicleData["suspensiontravel_fr"] = simfphystbl.CustomWheels and simfphystbl.FrontHeight or math.Round((ent.posepositions.Pose0_Pos_FR - ent.posepositions.Pose1_Pos_FR):LengthSqr(), 2)
    ent.VehicleData["suspensiontravel_rl"] = simfphystbl.CustomWheels and simfphystbl.RearHeight or math.Round((ent.posepositions.Pose0_Pos_RL - ent.posepositions.Pose1_Pos_RL):LengthSqr(), 2)
    ent.VehicleData["suspensiontravel_rr"] = simfphystbl.CustomWheels and simfphystbl.RearHeight or math.Round((ent.posepositions.Pose0_Pos_RR - ent.posepositions.Pose1_Pos_RR):LengthSqr(), 2)
    local pFL = ent.posepositions.Pose0_Pos_FL
    local pFR = ent.posepositions.Pose0_Pos_FR
    local pRL = ent.posepositions.Pose0_Pos_RL
    local pRR = ent.posepositions.Pose0_Pos_RR
    local pAngL = ent:WorldToLocalAngles(((pFL + pFR) / 2 - (pRL + pRR) / 2):Angle())

    return pAngL.y
end

local function CreateCSWheel(simfphystbl, ent, index, attachmentpos, height, swap_y)
	if !IsValid(ent) then return end

	local LocalAngForward = angle_zero
	LocalAngForward.y = GetForwardYaw(simfphystbl, ent)
    local fAng = ent:LocalToWorldAngles(LocalAngForward)
    local rAng = ent:LocalToWorldAngles(LocalAngForward:Sub(rightangle))
    local forward = fAng:Forward()
    local right = swap_y and -rAng:Forward() or rAng:Forward()
    local up = ent:GetUp()

    local csWheel = ClientsideModel("models/props_vehicles/tire001c_car.mdl", RENDERGROUP_BOTH)
    csWheel:SetPos(attachmentpos - up * height)
    csWheel:SetAngles(fAng)
    csWheel:SetParent(ent)

    if simfphystbl.CustomWheels then
        local model = (simfphystbl.CustomWheelModel_R and (index == 3 or index == 4 or index == 5 or index == 6)) and simfphystbl.CustomWheelModel_R or simfphystbl.CustomWheelModel
        local ghostAng = right:Angle()
        local mirAng = swap_y and 1 or -1
        ghostAng:RotateAroundAxis(forward, simfphystbl.CustomWheelAngleOffset.p * mirAng)
        ghostAng:RotateAroundAxis(right, simfphystbl.CustomWheelAngleOffset.r * mirAng)
        ghostAng:RotateAroundAxis(up, -simfphystbl.CustomWheelAngleOffset.y)
        local Camber = simfphystbl.CustomWheelCamber or 0
        ghostAng:RotateAroundAxis(forward, Camber * mirAng)
        local csCustomWheel = ents.Create("gmod_sent_vehicle_fphysics_attachment")
        csCustomWheel:SetModel(model)
        csCustomWheel:SetPos(csWheel:GetPos())
        csCustomWheel:SetAngles(ghostAng)
        csCustomWheel:SetParent(ent)
        csCustomWheel:SetRenderMode(RENDERMODE_TRANSALPHA)

        if simfphystbl.ModelInfo then
            if simfphystbl.ModelInfo.WheelColor then
                GhostWheel:SetColor(simfphystbl.ModelInfo.WheelColor)
            end
        end

        csWheel:Remove()
    end
end

local function CreateWheelEnts(ent, simfphystbl)
	if !IsValid(ent) then return end
	local wheelcount = 4

    if simfphystbl.CustomWheels and simfphystbl.CustomWheelPosML then
        wheelcount = wheelcount + 1
    end

    if simfphystbl.CustomWheels and simfphystbl.CustomWheelPosMR then
        wheelcount = wheelcount + 1
    end

	for i = 1, wheelcount do
		if simfphystbl.CustomWheels then
	    	local CSWheel = CreateCSWheel(simfphystbl, ent, i, ent:LocalToWorld(simfphystbl.[simfphyswheelpos[i]]), simfphystbl.[simfphyswheelheight[i]], simfphyswheelbools[i])
	    	table.insert(CSents, CSWheel)
	    else
	    	local CSWheel = CreateCSWheel(simfphystbl, ent, i, simfphyswheelatts[i], simfphystbl.[simfphyswheelheight[i]], simfphyswheelbools[i])
	    	table.insert(CSents, CSWheel)
	    end
    end
end

local function StatPanel(parent, x, y, w, h)
    if !IsValid(parent) then return end

    local stattbl = nil

    local statPanel = vgui.Create("DPanel", parent)
    statPanel:SetSize(w, h)
    statPanel:SetPos(x, y)

    function statPanel:Paint(w, h)
    	draw.RoundedBox(2, 0, 0, w, h, graycolor)

    	if !istable(stattbl) then 
    		draw.SimpleText("No vehicle highlighted, or no stats to display.", "Default", 5, 5, color_white, TEXT_ALIGN_LEFT)

    		return
    	end

    	for i = 1, #stattbl do
    		draw.DrawText(stattbl[i].stat, "Default", 20, 0, color_white, TEXT_ALIGN_LEFT)
    	end
    end

    function statPanel:SetStatTable(tbl)
    	stattbl = GetCarStats(tbl)
    end
end

local function SearchBox(parent, x, y, w, h)
    if !IsValid(parent) then return end

    local searchEntry = vgui.Create("DPanel", parent)
    searchEntry:SetSize(w, h)
    searchEntry:SetPos(x, y)

    function searchEntry:Paint(w, h)
        surface.SetDrawColor(40, 40, 40, 200)
        surface.DrawRect(0, 0, w, h)

        if math.sin((SysTime() * 1) * 6) > 0 then
            draw.DrawText("__", "Default", 16, 12, color_white, TEXT_ALIGN_CENTER)
        end

        return nil
    end

    function searchEntry:OnValueChanged(value)
    	searchstring = tostring(value) -- not sure if needed but i dont want it being turned into a number value

    	if IsValid(OpenScrollPanel) then
    		OpenScrollPanel:InvalidateLayout(false)
    	end
    end

    return searchEntry
end

local function FancyModelPanel(parent, x, y, w, h)
    if !IsValid(parent) then return end

    local simfphystbl = nil
    local CSents = {}

    local parentPanel = vgui.Create("DPanel", parent)
    parentPanel:SetSize(w, h)
    parentPanel:SetPos(x, y)

    function parentPanel:Paint(w, h)
        chicagoRP.BlurBackground(self)
    end

    local modelPanel = vgui.Create("DModelPanel", parentPanel)
    modelPanel:SetSize(w, h)
    modelPanel:SetPos(x, y)
    -- modelPanel:SetAmbientLight(color_white) -- main light up top (typically slightly yellow), fill light below camera (very faint pale blue), rim light to the left (urban color), rimlight to the right (white)
    -- modelPanel:SetDirectionalLight(BOX_TOP, slightyellowcolor)
    -- modelPanel:SetDirectionalLight(BOX_FRONT, slightbluecolor)
    -- modelPanel:SetDirectionalLight(BOX_LEFT, lightcolor)

    local oldCamPos = modelPanel:GetCamPos()
    local oldCamAng = modelPanel:GetLookAng()

    function modelPanel:LayoutEntity(ent) return end -- how do we make cam movement smoothened?

	function modelPanel:Paint(w, h)
		if !IsValid(self.Entity) then return end
		local x, y = self:LocalToScreen(0, 0)
		self:LayoutEntity(self.Entity)

		local ang = self.aLookAngle
		if !ang then
		    ang = (self.vLookatPos - self.vCamPos):Angle()
		end

		cam.Start3D(LerpVector((SysTime() - lerpStart) / lerpTime, oldCamPos, self.vCamPos), LerpAngle((SysTime() - lerpStart) / lerpTime, oldCamAng, ang), self.fFOV, x, y, w, h, 5, self.FarZ)

		render.SuppressEngineLighting(false)
		-- render.SetLightingOrigin(self.Entity:GetPos())
		-- render.ResetModelLighting(self.colAmbientLight.r / 255, self.colAmbientLight.g / 255, self.colAmbientLight.b / 255)
		-- render.SetColorModulation(self.colColor.r / 255, self.colColor.g / 255, self.colColor.b / 255)
		-- render.SetBlend((self:GetAlpha() / 255) * (self.colColor.a / 255)) -- * surface.GetAlphaMultiplier()

		-- for i = 0, 6 do
		--     local col = self.DirectionalLight[i]

		--     if col then
		--         render.SetModelLighting(i, col.r / 255, col.g / 255, col.b / 255)
		--     end
		-- end

		self:DrawModel()

		render.SuppressEngineLighting(false)
		cam.End3D()

		self.LastPaint = RealTime()

		lerpStart = SysTime()
		oldCamPos = self:GetCamPos()
		oldCamAng = ang

		return true
	end

	function modelPanel:OnRemove()
		GCCubemapMats()
		GCCSEnts(CSents)
	end

	function modelPanel:Think()
		if !IsValid(modelPanel.Entity) or !istable(simfphystbl) then return end

		local curtime = CurTime()
		local IdleRPM = simfphystbl.IdleRPM
		local LimitRPM = simfphystbl.LimitRPM
	    self.RunNext = self.RunNext or 0

	    if self.RunNext < curtime then
	        ExhaustEffect(modelPanel.Entity, simfphystbl, 0.50, IdleRPM, LimitRPM)
	        self.RunNext = curtime + 0.06
	    end
	end

	function modelPanel:PerformLayout(w, h)
		GCCubemapMats()
		GCCSEnts(CSents)

	    if IsValid(self.Entity) then -- post-init
	    	CreateWheelEnts(self.Entity, simfphystbl)
	    end

	    SetStaticCubemap(self.Entity)
	end

	function modelPanel:SetSimfphysTable(tbl)
		simfphystbl = tbl
	end

	OpenModelPanel = modelPanel

    return modelPanel
end

local function IconModelPanel(parent, x, y, w, h)
    if !IsValid(parent) then return end

    local parentPanel = vgui.Create("DPanel", parent)
    parentPanel:SetSize(w, h)
    parentPanel:SetPos(x, y)

    parentPanel.Paint = nil

    local modelPanel = vgui.Create("DModelPanel", parentPanel)
    modelPanel:SetSize(w, h)
    modelPanel:SetPos(x, y)
    -- modelPanel:SetAmbientLight(color_white) -- main light up top (typically slightly yellow), fill light below camera (very faint pale blue), rim light to the left (urban color), rimlight to the right (white)
    -- modelPanel:SetDirectionalLight(BOX_TOP, slightyellowcolor)
    -- modelPanel:SetDirectionalLight(BOX_FRONT, slightbluecolor)
    -- modelPanel:SetDirectionalLight(BOX_LEFT, lightcolor)

    function modelPanel:LayoutEntity(ent) return end -- how do we make cam movement smoothened?

    function modelPanel:SetMats(tbl)
    	self.Entity:SetSubMaterial(0, tbl.MaterialPath)

    	if !isempty(tbl.MaterialPath2) then
    		self.Entity:SetSubMaterial(1, tbl.MaterialPath2)
    	else
    		self.Entity:SetSubMaterial(1, "transparentmat")
    	end
    end

    return modelPanel
end

-- local function PurchaseButtonFrame(parent, w, h)
-- 	if !IsValid(parent) then return end

-- 	local scrW = ScrW()
-- 	local scrH = ScrH()
-- 	local centerX = select(1, CenterElement(scrW, scrH, 700, 400))

--     local parentPanel = vgui.Create("DPanel", parent)
--     parentPanel:SetSize(w, h)
--     parentPanel:SetPos(centerX, scrH - 400)

--     function parentPanel:Paint(w, h)
--     	chicagoRP.DrawOutlinedRoundedBox(4, 0, 0, w, h, graycolor, color_black, 2)

--     	return nil
--     end

--     return parentPanel
-- end

local function ColorPicker(parent, x, y, w, h, vehicletbl)
	if !IsValid(parent) then return end

	local defaultcolortbl = vehicletbl.DefaultColor or fallbackcolortbl
	local defaultcolor = Color(defcol[1], defcol[2], defcol[3], defcol[4])

	local frame = vgui.Create("DPanel")
	frame:SetSize(0, 0)
	frame:SetPos(x, y)

	frame:SizeTo(w, h, 0.5, 0, -1)
	chicagoRP.PanelFadeIn(frame, 0.5)

	function frame:OnRemove()
		self:SizeTo(0, 0, 0.5, 0, -1)
		chicagoRP.PanelFadeOut(self, 0.5)
	end

	local colorPicker = vgui.Create("DRGBPicker", frame)
	colorPicker:SetSize(40, h - 20)
	colorPicker:Dock(LEFT)
	colorPicker:SetPalette(true)
	colorPicker:SetAlphaBar(true)
	colorPicker:SetWangs(true)
	colorPicker:SetColor(defaultcolor)

	local huePicker = vgui.Create("DColorCube", frame)
	huePicker:Dock(RIGHT)
	huePicker:SetSize(w - 60, h - 20)

	local labelX, labelY = huePicker:GetPos()

	local colorLabel = vgui.Create("DLabel", frame)
	colorLabel:SetPos(labelX, labelY + h - 20)
	colorLabel:SetText("Color(" .. tostring(defaultcolor.r) .. " ," .. tostring(defaultcolor.g) .. " ," .. tostring(defaultcolor.b) .. " ," .. tostring(defaultcolor.a) .. ")")

	colorLabel:SizeToContents()
	colorLabel.Think = nil

	function colorLabel:Paint(w, h)
		draw.DrawText(self:GetText(), "Default", 0, 0, color_white, TEXT_ALIGN_LEFT)

		return nil
	end

	function colorLabel:UpdateColors(col)
	    self:SetText("Color(" .. col.r .. ", " .. col.g .. ", " .. col.b .. ")")

	    if IsValid(OpenModelPanel) and IsValid(OpenModelPanel.Entity) then
	    	OpenModelPanel.Entity:SetColor(col)
	    end
	end

	function colorPicker:OnChange(col)
	    local h = ColorToHSV(col)
	    local s, v = select(2, ColorToHSV(huePicker:GetRGB()))

	    col = HSVToColor(h, s, v)
	    huePicker:SetColor(col)

	    colorLabel:UpdateColors(col)
	end

	function huePicker:OnUserChanged(col)
	    colorLabel:UpdateColors(col)

	    if IsValid(OpenComboBox) then
			for i = 1, #OpenComboBox:ChildCount() do
	            local option = OpenComboBox.Menu:GetChild(i)
	            local modelPanel = option:GetChild(1)

	            modelPanel.Entity:SetColor(col)
	        end
	    end
	end

	return frame
end

local function ColorPickerButton(parent, x, y, w, h)
	if !IsValid(parent) then return end

    local button = vgui.Create("DButton", parent)
    button:SetSize(w, h)
    button:SetText("ColorPicker")

    function button:Paint(w, h)
    	chicagoRP.DrawOutlinedRoundedBox(4, 0, 0, w, h, graycolor, color_white, 1)
        surface.SetMaterial(iconhere)
        surface.DrawTexturedRectRotated(128, 128, 128, 128, 0)
        DisableClipping(true)
        draw.DrawText(self:GetText(), "Default", 0, h + 20, color_white, TEXT_ALIGN_CENTER)

        return nil
    end

    return button
end

local function PaintPicker(parent, x, y, w, h, vehicletbl)
	if !IsValid(parent) or !IsValid(OpenModelPanel) or !IsValid(OpenModelPanel.Entity) then return end

	local currentcolor = OpenModelPanel.Entity:GetColor()

	local comboBox = vgui.Create("DComboBox")
	comboBox:SetPos(x, y)
	comboBox:SetSize(w, h)
	comboBox:SetText("PaintPicker")

	for i = 1, #vehicletbl.PaintMaterials do
		comboBox:AddChoice(vehicletbl.PaintMaterials[i].PrintName, vehicletbl.PaintMaterials[i].Index)
	end

	function comboBox.DropButton:Paint(w, h)
    	chicagoRP.DrawOutlinedRoundedBox(4, 0, 0, w, h, graycolor, color_white, 1)
        draw.DrawText(self:GetText(), "Default", 0, 0, color_white, TEXT_ALIGN_LEFT)

		-- return nil
	end

	function comboBox:OnMenuOpened()
		for i = 1, #self:ChildCount() do
            local option = self.Menu:GetChild(i)

            local optionW = select(1, option:GetSize())
            local centerY = CenterY(optionW, 32)

            function option:Paint(w, h)
            	-- chicagoRP.DrawOutlinedRoundedBox(4, 4, 4, 32, 32, color_transparent, color_white, 4)
            	if self:IsHovered() then
            		draw.RoundedBox(2, 0, 0, w, h, graycolor)
            	else
            		draw.RoundedBox(2, 0, 0, w, h, color_black)
            	end
            	draw.DrawText(self:GetText(), "chicagoRP_NPCShop", 4, 4, whitecolor, TEXT_ALIGN_LEFT)
            	chicagoRP.DrawRoundedOutlinedGradientBox(4, 4, centerY, 32, 32, gradient1, gradient2, 4)
                
                return nil
            end

            option.oPerformLayout = opt.PerformLayout
            function option:PerformLayout(w, h)
                self:oPerformLayout(w, h)
                self:SetSize(w, 40)
                self:SetTextInset(0, 0)
            end

            local iconPanel = IconModelPanel(option, 4, centerY, 32, 32)
            -- iconPanel:SetModel(insertmodelhere)
            iconPanel.Entity:SetMats(vehicletbl.PaintMaterials)
            iconPanel.Entity:SetColor(currentcolor)
        end
    end

	function comboBox:OnSelect(_, _, data)
		if IsValid(OpenModelPanel) and IsValid(OpenModelPanel.Entity) then
			OpenModelPanel.Entity:SetSkin(data)
		end
	end

	OpenComboBox = comboBox

	return comboBox
end

local function PurchaseButton(parent, x, y, w, h)
	if !IsValid(parent) then return end

    local button = vgui.Create("DButton", parent)
    button:SetSize(w, h)
    button:SetText("Purchase")

    function button:Paint(w, h)
    	if self:GetDisabled() then
    		chicagoRP.DrawOutlinedRoundedBox(4, 0, 0, w, h, darkgraycolor, color_white, 1)
    	else
    		chicagoRP.DrawOutlinedRoundedBox(4, 0, 0, w, h, graycolor, color_white, 1)
    	end

        surface.SetMaterial(purchaseicon) -- purchaseicon
        surface.DrawTexturedRectRotated(128, 128, 128, 128, 0)
        draw.DrawText(self:GetText(), "Default", 0, h + 20, color_white, TEXT_ALIGN_LEFT)

        return nil
    end

    function button:PerformLayout(w, h)
    	if chicagoRPCarDealer.IsVehicleOwned(self.vehicle) then
    		self:SetEnabled(false)
    		self:SetText("Owned")
    	end
    end

    button:InvalidateLayout(true)

    return button
end

local function TestDriveConfirm(parent, x, y, w, h)
	if !IsValid(parent) then return end

    local scrW = ScrW()
    local scrH = ScrH()
    local parentPanel = vgui.Create("DPanel", parent)
    parentPanel:SetPos(x, y)
    parentPanel:SetSize(w, h)

    parentPanel:SizeTo(w, h, 1, 0, -1)
    parentPanel:RequestFocus()

    function parentPanel:OnFocusChanged(bool)
    	if !bool then
    		self:Remove()
    	end
    end

    local label = vgui.Create("DLabel", parent)
    label:SetPos(x, y)
    label:SetSize(w, h)
    label:SetText("This will start a 30 second test drive that will close the UI, are you sure?")
    label:SetWrap(true)
    label:SetAutoStretchVertical(true)

    label.Think = nil

    local button = vgui.Create("DButton", parentPanel)
    button:SetSize(w, h)
    button:SetText("Confirm?")

    function button:Paint(w, h)
    	DisableClipping(true)
    	surface.SetDrawColor(40, 40, 40, 100)
    	surface.DrawRect(0, 0, scrW, scrH)
    	DisableClipping(false)

    	chicagoRP.DrawOutlinedRoundedBox(4, 0, 0, w, h, graycolor, color_white, 1)
        draw.DrawText(self:GetText(), "Default", 0, 0, color_white, TEXT_ALIGN_LEFT)
        DisableClipping(true)

        return nil
    end

    return button
end

local function TestDriveButton(parent, x, y, w, h)
	if !IsValid(parent) then return end

    local button = vgui.Create("DButton", parent)
    button:SetSize(w, h)
    button:SetText("Test Drive")

    function button:Paint(w, h)
    	chicagoRP.DrawOutlinedRoundedBox(4, 0, 0, w, h, graycolor, color_white, 1)
        surface.SetMaterial(purchaseicon) -- purchaseicon
        surface.DrawTexturedRectRotated(128, 128, 128, 128, 0)
        draw.DrawText(self:GetText(), "Default", 0, h + 20, color_white, TEXT_ALIGN_LEFT)

        return nil
    end

    return button
end

local function PriceLabel(parent, x, y, w, h)
	if !IsValid(parent) then return end

	local label = vgui.Create("DLabel", parent)
	label:SetPos(x, y)
	label:SetSize(w, h)

	label:SetText("1")
	label.Think = nil

    function label:Paint(w, h)
        draw.RoundedBox(2, 0, 0, w, h, graycolor)
        draw.DrawText(attachCurrency(self:GetText()), "Default", 0, 0, color_white, TEXT_ALIGN_LEFT)

        return nil
    end

    return label
end

function UIFuncs.PurchaseUI(manufacturertbl, manuindex, vehicletbl)
	local vehicles_hashtable = chicagoRPCarDealer.Vehicles_HashTable
    local scrW = ScrW()
    local scrH = ScrH()
    local motherFrame = vgui.Create("DFrame")
    motherFrame:SetSize(scrW, scrH)
    motherFrame:SetVisible(true)
    motherFrame:SetDraggable(false)
    motherFrame:ShowCloseButton(true)
    motherFrame:SetTitle(manufacturers[i].PrintName)
    motherFrame:ParentToHUD()
    chicagoRP.HideHUD = true

    motherFrame.lblTitle.Think = nil

    chicagoRP.PanelFadeIn(motherFrame, 0.15)

    motherFrame:SetKeyboardInputEnabled(true)
    motherFrame:MakePopup()
    motherFrame:Center()

    function motherFrame:OnClose()
        if IsValid(self) then
            chicagoRP.PanelFadeOut(motherFrame, 0.15)
        end

        chicagoRP.HideHUD = false
    end

    function motherFrame:OnKeyCodePressed(key)
        if key == KEY_ESCAPE or key == KEY_Q then
            surface.PlaySound("chicagoRP_settings/back.wav")
            timer.Simple(0.15, function()
                if IsValid(self) then
                    self:Close()
                end
            end)
        end
    end

    function motherFrame:Paint(w, h)
        -- chicagoRP.BlurBackground(self)
        surface.SetDrawColor(40, 40, 40, 200)
        surface.DrawRect(0, 0, w, h)
    end

    if !isempty(historytable[4]) then vehicletbl = vehicles_hashtable[historytable[4]] end

	local backButton = BackButton(motherFrame, 0, 0, 195, 40)
	local manufacturerPanel = ManufacturerPanel(motherFrame, manufacturertbl, 200, 0, 220, 40)
	local moneyPanel = MoneyPanel(motherFrame, 1775, 0, 150, 40)

	local centerX, centerY = CenterElement(scrW, scrH, 1900, 835)
    local modelPanel = FancyModelPanel(motherFrame, centerX, centerY, 1900, 835)
    -- local buttonPanel = PurchaseButtonFrame(motherFrame, 700, 400)

    local colorButton = ColorPickerButton(buttonPanel, 20, 40, 128, 128, vehicletbl)
    local paintButton = PaintPicker(buttonPanel, 200, 40, 96, 40, vehicletbl)

    local parentW, parentH = buttonPanel:GetSize()
	local purcX, purcY = CenterElement(parentW, parentH, 320, 160)

    local purchaseButton = PurchaseButton(buttonPanel, purcX, purcY, 320, 160)
    local testDriveButton = TestDriveButton(buttonPanel, 400, 200, 80, 60)
    local priceDisplay = PriceLabel(parent, x, y, w, h)

    purchaseButton.vehicle = vehicletbl.EntityName
    priceDisplay:SetText(tostring(vehicletbl.Price))
    priceDisplay:SizeToContents()

    local OpenColorPicker = nil
    local colorPickerX, colorPickerY = select(1, colorButton:GetPos()), select(2, buttonPanel:GetPos())

    local testDriveW, testDriveH = testDriveButton:GetSize()
    local testDriveX, testDriveY = testDriveButton:GetPos()

	local oDoClick = backButton.DoClick
	function backButton:DoClick()
		oDoClick()

		UIFuncs.OpenBrowseUI(manufacturertbl, manuindex)
	end

    function testDriveButton:DoClick()
    	local confirmBox = TestDriveConfirm(motherFrame, testDriveX, testDriveY + testDriveH + 4, testDriveW, testDriveH + (math.Round(testDriveH * 0.5)))
    
    	function confirmBox:DoClick()
    		motherFrame:Close()

    		net.Start("chicagoRP_cardealer_starttestdrive")
    		net.WriteString(vehicletbl.EntityName)
    		net.SendToServer()
    	end
    end

    function colorButton:DoClick()
    	if IsValid(OpenColorPicker) then OpenColorPicker:Remove() return end
    	local colorPicker = ColorPicker(motherFrame, colorPickerX, colorPickerY - 320, 200, 300, vehicletbl)

    	OpenColorPicker = colorPicker
    end

    function purchaseButton:DoClick()
    	net.Start("chicagoRP_cardealer_purchasecar")
		net.WriteString(vehicletbl.EntityName)
		net.SendToServer()

		notification.AddLegacy("Congratulations on your purchase of a " .. vehicletbl.PrintName .. "!", NOTIFY_GENERIC, 5)
		surface.PlaySound("buttons/button15.wav")
		self:InvalidateLayout(true)
	end

    historytable[4] = vehicletbl.EntityName
    OpenPurchaseFrame = motherFrame
end

local function HorizontalScrollPanel(parent, x, y, w, h)
	local scrollPanel = vgui.Create("chicagoRP_HorizontalScrollPanel", parent)
	scrollPanel:SetSize(w, h)
	scrollPanel:SetPos(x, y)

	local scrollBar = scrollPanel:GetVBar()

    function button:Paint(w, h)
        return nil
    end

    return scrollPanel
end

local function VehicleButton(parent, vehicletable, x, y, w, h)
	if !IsValid(parent) or !istable(vehicletable) then return end

    local button = parent:Add("DButton")
    button:SetSize(w, h)
    button:Dock(LEFT)
    button:DockMargin(10, 0, 10, 0)
    
    button:SetText(vehicletable.PrintName)

    local centerX, centerY = CenterElement(w, h, 120, 90)
    local textCenterX, centerY = CenterElement(120, 90, 30, 15)

	local speed = 5
	local range = 100
	local country = chicagoRPCarDealer.GetCountryCode(vehicletable.Country)

    function button:Paint(w, h)
    	local offset = range * math.sin(CurTime() * speed)

        draw.RoundedBox(2, 0, 0, w, h, graycolor)
        draw.DrawText(self:GetText(), "Default", 30 + offset, 5, color_white, TEXT_ALIGN_LEFT)
        draw.RoundedBox(2, centerX, centerY, 120, 90, Color(10, 10, 10, 50))
        draw.DrawText("icon should be here", "Default", textCenterX, centerY, color_white, TEXT_ALIGN_LEFT)
        surface.SetMaterial(countrymats[country])
        surface.DrawTexturedRectRotated(64, 6, 32, 32, 0)

        return nil
    end

    return button
end

local function BackButton(parent, x, y, w, h)
	if !IsValid(parent) then return end

    local button = parent:Add("DButton")
    button:SetSize(w, h)
    button:SetPos(x, y)
    button:SetText("iconhere Back")

    function button:Paint(w, h)
        draw.RoundedBox(2, 0, 0, w, h, graycolor)
        draw.DrawText(self:GetText(), "Default", 20, 0, color_white, TEXT_ALIGN_RIGHT)

        return nil
    end

    function button:DoClick()
    	if IsValid(OpenBrowseFrame) then
	        chicagoRP.PanelFadeOut(OpenBrowseFrame, 0.15)
	        OpenBrowseFrame:Close()
	    end
    end

    return button
end

local function ManufacturerPanel(parent, index, x, y, w, h)
	if !IsValid(parent) then return end

    local manuPanel = parent:Add("DPanel")
    manuPanel:SetSize(w, h)
    manuPanel:SetPos(x, y)
    manuPanel:SetText(chicagoRPCarDealer.Manufacturers[index].PrintName)

    local manumat = Material(chicagoRPCarDealer.Manufacturers[index].Icon, "smooth mips")

    function manuPanel:Paint(w, h)
        draw.RoundedBox(2, 0, 0, w, h, graycolor)
        draw.DrawText(self:GetText(), "Default", 20, 0, color_white, TEXT_ALIGN_RIGHT)
        surface.SetMaterial(manumat)
        surface.DrawTexturedRectRotated(64, 6, 32, 32, 0)

        return nil
    end

    return manuPanel
end

local function MoneyPanel(parent, x, y, w, h)
	if !IsValid(parent) then return end

    local moneyPanel = parent:Add("DPanel")
    moneyPanel:SetSize(w, h)
    moneyPanel:SetPos(x, y)

    function moneyPanel:Paint(w, h)
        draw.RoundedBox(2, 0, 0, w, h, graycolor)

        if !IsValid(client) then return nil end

        draw.DrawText(DarkRP.formatMoney(client:getDarkRPVar("money")), "Default", 20, 0, color_white, TEXT_ALIGN_LEFT)

        return nil
    end

    return moneyPanel
end

local function RefreshModelPanel(vehicletbl)
	local spawnlist = list.Get("simfphys_vehicles")
	local simfphystbl = spawnlist[vehicletbl.EntityName]
	local colortbl = vehicletbl.DefaultColor

	if IsValid(OpenModelPanel) then
		OpenModelPanel:SetModel(simfphystbl.Model)
		OpenModelPanel:SetSimfphysTable(simfphystbl)
		OpenModelPanel:InvalidateLayout(true)
		if istable(colortbl) then
			OpenModelPanel.Entity:SetColor(Color(colortbl[1], colortbl[2], colortbl[3], colortbl[4]))
		end
	end
end

local function HoverTooltip(parent, hoveredpanel, w, h)
	if !IsValid(parent) or !IsValid(hoveredpanel) then return end

	local hoverX, hoverY = hoveredpanel:GetPos()
	local hoverW, hoverH = hoveredpanel:GetSize()
	local tooltip = vgui.Create("DPanel")
	-- tooltip:SetSize(290, 50)
	tooltip:SetPos(hoverX * (0.5) - 290 * 0.5, hoverY - hoverH - 50)
    tooltip:SizeTo(w, h, 0.5, 0, -1)

	function tooltip:Paint(w, h)
		local country = chicagoRPCarDealer.GetCountryCode(self.country)

        draw.RoundedBox(2, 0, 0, w, h, graycolor)
        draw.DrawText(self:GetText(), "Default", 20, 0, color_white, TEXT_ALIGN_LEFT)
        surface.SetMaterial(countrymats[country])
        surface.DrawTexturedRectRotated(64, 6, 32, 32, 0)

        return nil
    end

    function tooltip:OnRemove()
    	if IsValid(self) then
    		tooltip:SizeTo(0, 0, 0.5, 0, -1)
    	end
    end

    function tooltip:SetCountry(str)
    	self.country = str
    end

    return tooltip
end

function UIFuncs.BrowseUI(manufacturer, manuindex)
    local scrW = ScrW()
    local scrH = ScrH()
    local motherFrame = vgui.Create("DFrame")
    motherFrame:SetSize(scrW, scrH)
    motherFrame:SetVisible(true)
    motherFrame:SetDraggable(false)
    motherFrame:ShowCloseButton(true)
    motherFrame:SetTitle(manufacturers[i].PrintName)
    motherFrame:ParentToHUD()
    chicagoRP.HideHUD = true

    motherFrame.lblTitle.Think = nil

    chicagoRP.PanelFadeIn(motherFrame, 0.15)

    motherFrame:SetKeyboardInputEnabled(true)
    motherFrame:MakePopup()
    motherFrame:Center()

    function motherFrame:OnClose()
        if IsValid(self) then
            chicagoRP.PanelFadeOut(motherFrame, 0.15)
        end

        chicagoRP.HideHUD = false
    end

    function motherFrame:OnKeyCodePressed(key)
        if key == KEY_ESCAPE or key == KEY_Q then
            surface.PlaySound("chicagoRP_settings/back.wav")
            timer.Simple(0.15, function()
                if IsValid(self) then
                    self:Close()
                end
            end)
        end
    end

    function motherFrame:Paint(w, h)
        -- chicagoRP.BlurBackground(self)
        surface.SetDrawColor(40, 40, 40, 200)
        surface.DrawRect(0, 0, w, h)
    end

    CountryMaterials(manufacturer)

	local modelPanel = FancyModelPanel(motherFrame, 5, 50, 1900, 835)
	local statPanel = StatPanel(motherFrame, 1500, 60, 380, 400)
	local backButton = BackButton(motherFrame, 0, 0, 195, 40)
	local manufacturerPanel = ManufacturerPanel(motherFrame, manuindex, 200, 0, 220, 40)
	local moneyPanel = MoneyPanel(motherFrame, 1775, 0, 150, 40)

	local scrollPanel = HorizontalScrollPanel(motherFrame, 20, 900, 1890, 150)
	local scrollPanelBar = scrollPanel:GetVBar()

	local scrollpos = historytable[3]
	if isnumber(scrollpos) then scrollPanelBar:AnimateTo(scrollpos, 1, 0, -1) end

	local oDoClick = backButton.DoClick
	function backButton:DoClick()
		oDoClick()

		UIFuncs.OpenDealerUI()
	end

	function scrollPanel:PerformLayout(w, h)
		for i = 1, #manufacturer do
			if !isempty(searchstring) then
				local foundtext = select(3, string.find(string.lower(manufacturer[i].PrintName), searchstring, 1, false))

				if isempty(foundtext) then continue end
			end

			local vehicleButton = VehicleButton(scrollPanel, manufacturer[i], 150, 120)

			function vehicleButton:OnCursorEntered()
				local tooltip = HoverTooltip(motherFrame, self, 290, 50)

				tooltip:SetText(manufacturer[i].PrintName)
				tooltip:SetCountry(manufacturer[i].Country)

				self.toolTip = tooltip

				timer.Simple(1.5, function()
					if IsValid(self) and self:IsHovered() then
						RefreshModelPanel(manufacturer[i])
					end
				end)
			end

			function vehicleButton:OnCursorExited()
				if IsValid(self.toolTip) then
					self.toolTip:Remove()
				end
			end

			function vehicleButton:DoClick()
				UIFuncs.PurchaseUI(manufacturer, i, manufacturer[i])

				historytable[2] = manuindex
				historytable[3] = scrollPanelBar:GetScroll()
			end
		end
	end

	scrollPanel:InvalidateLayout(true)

	historytable[4] = nil
	OpenBrowseFrame = motherFrame
	OpenScrollPanel = scrollPanel
end

local function ManufacturerButton(parent, tbl, w, h)
    local button = parent:Add("DButton")
    button:SetSize(w, h)
    button:SetText(tbl.PrintName)

    function button:Paint(w, h)
        draw.RoundedBox(2, 0, 0, w, h, graycolor)
        draw.DrawText(self:GetText(), "Default", 20, 0, color_white, TEXT_ALIGN_LEFT)
        surface.SetMaterial(manufacturermats[tbl.index])
        surface.DrawTexturedRectRotated(128, 128, 128, 128, 0)

        return nil
    end

    return button
end

function UIFuncs.DealerUI()
	local manufacturers = chicagoRPCarDealer.Manufacturers
	local vehicles = chicagoRPCarDealer.Vehicles
	local manufacturers_hashtable = chicagoRPCarDealer.Manufacturers_HashTable
	local vehicles_hashtable = chicagoRPCarDealer.Vehicles_HashTable
    local scrW = ScrW()
    local scrH = ScrH()
    local motherFrame = vgui.Create("DFrame")
    motherFrame:SetSize(scrW, scrH)
    motherFrame:SetVisible(true)
    motherFrame:SetDraggable(false)
    motherFrame:ShowCloseButton(true)
    motherFrame:SetTitle("Car Dealer")
    motherFrame:ParentToHUD()
    chicagoRP.HideHUD = true

    motherFrame.lblTitle.Think = nil

    chicagoRP.PanelFadeIn(motherFrame, 0.15)

    motherFrame:SetKeyboardInputEnabled(true)
    motherFrame:MakePopup()
    motherFrame:Center()

    ManufacturerMaterials()

    function motherFrame:OnClose()
        if IsValid(self) then
            chicagoRP.PanelFadeOut(motherFrame, 0.15)
        end

        GCManufacturerMats()

        chicagoRP.HideHUD = false
    end

    function motherFrame:OnKeyCodePressed(key)
        if key == KEY_ESCAPE or key == KEY_Q then
            surface.PlaySound("chicagoRP_settings/back.wav")
            timer.Simple(0.15, function()
                if IsValid(self) then
                    self:Close()
                end
            end)
        end
    end

    function motherFrame:Paint(w, h)
        -- chicagoRP.BlurBackground(self)
        surface.SetDrawColor(40, 40, 40, 200)
        surface.DrawRect(0, 0, w, h)
    end

	local backButton = BackButton(motherFrame, 0, 0, 195, 40)
	local moneyPanel = MoneyPanel(motherFrame, 1775, 0, 150, 40)

	local scrollPanel = vgui.Create("DScrollPanel", motherFrame)
	local scrollPanelBar = scrollPanel:GetVBar()
	scrollPanel:Dock(FILL)
	scrollPanel:DockMargin(10, 150, 10, 10)

	local buttonLayout = vgui.Create("DIconLayout", scrollPanel)
	buttonLayout:Dock(FILL)
	buttonLayout:SetSpaceY(10)
	buttonLayout:SetSpaceX(10)

	local scrollpos = historytable[1]
	if isnumber(scrollpos) then scrollPanelBar:AnimateTo(scrollpos, 1, 0, -1) end

    for i = 1, #manufacturers do
    	local manufacButton = ManufacturerButton(buttonLayout, manufacturers[i], 256, 256)

    	function manufacButton:DoClick()
            chicagoRP.PanelFadeOut(motherFrame, 0.15)
            motherFrame:Close()

            historytable[1] = scrollPanelBar:GetScroll()

    		UIFuncs.BrowseUI(manufacturers[i], i) -- remove frame when you do this
    	end
    end

    function backButton:DoClick()
    	motherFrame:Close()
    	historytable = {}
    end

    historytable = {}
    OpenDealerFrame = motherFrame
end

-- to-do:
-- n/a just code
-- serverside code (purchasing car, use psuedo code for SQL)
-- mechanic UI
-- used car dealer (table that refreshes after set period. picks 9 random cars that are used but discounted, have random colors/paint and may contain upgrades)
-- SQL shit

-- color picker icon (circle with paintbrush or outlined circle in bottom right corner)
-- dtextentry for entering specific values into color picker?
-- calc stats somehow (https://github.com/SpiffyJUNIOR/simfphys_base/blob/master/lua/simfphys/base_functions.lua#L248)
-- multiple cars (how do we index them and tell cars of the same model apart?)

-- upgrade calc needs to be serverside i think (apply upgrades temporarily and then reset to original stats on exit)
-- we need to find a way to make this unexploitable (reset on exiting vehicle, reset on closing UI, create setupmove hook to reset stats once player position has changed a fair bit then remove hook)