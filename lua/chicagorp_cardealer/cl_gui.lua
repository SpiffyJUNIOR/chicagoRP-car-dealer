local OpenDealerFrame = nil
local OpenBrowseFrame = nil
local OpenPurchaseFrame = nil
local OpenModelPanel = nil
local historytable = {} -- clearly defined structure needed (1: manufacturer scrollpos, 2: manufacturer opened, 3: browse scrollpos, 4: purchase panel car selected)
local vehiclewheels = {}
local manufacturermats = {}
local countrymats = {}
local cubemapmats = {}
local lerpStart = 0
local lerpTime = 0
local client = LocalPlayer()
local defaultCamPos = Vector(50, 50, 50)
local defaultCamAng = Angle(0, 0, 40)
local rightangle = Angle(0, 90, 0)

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

local function ismaterial(mat)
    return mat != nil and type(mat) == "material"
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

local function OpenDealerUI()
	UIFuncs.DealerUI()
end

local function OpenBrowseUI()
	UIFuncs.BrowseUI()
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

local function PurchaseUI(vehicletbl)
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

    local modelPanel = nil
    local buttonPanel = nil
    local colorButton = nil
    local colorPicker = nil
    local purchaseButton = nil
    local testDriveButton = nil

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

local function VehicleButton(parent, vehicletable, x, y, w, h) -- horizontally scrolling text?
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

    	UIFuncs.OpenDealerUI()
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

        draw.DrawText("$" .. tostring(client:getDarkRPVar("money")), "Default", 20, 0, color_white, TEXT_ALIGN_LEFT)

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

local function HoverTooltip(parent, hoveredpanel, w, h) -- do this
	local tooltip = vgui.Create("DPanel")
	tooltip:SetSize(290, 50)
	expandto



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

	for i = 1, #manufacturer do
		local vehicleButton = VehicleButton(scrollPanel, manufacturer[i], 150, 120)

		function vehicleButton:OnCursorEntered()
			self.toolTip = HoverTooltip(motherFrame, self, 290, 50)

			self.toolTip:SetText(manufacturer[i].PrintName)
			self.toolTip:SetCountry(manufacturer[i].Country)

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
			PurchaseUI(manufacturer[i])
		end
	end

	OpenBrowseFrame = motherFrame
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

	local scrollPanel = vgui.Create("DScrollPanel", motherFrame) -- Create the Scroll panel
	scrollPanel:Dock(FILL)
	scrollPanel:DockMargin(10, 150, 10, 10)

	local buttonLayout = vgui.Create("DIconLayout", scrollPanel)
	buttonLayout:Dock(FILL)
	buttonLayout:SetSpaceY(10)
	buttonLayout:SetSpaceX(10)

    for i = 1, #manufacturers do
    	local manufacButton = ManufacturerButton(buttonLayout, manufacturers[i], 256, 256)

    	function manufacButton:DoClick()
            chicagoRP.PanelFadeOut(motherFrame, 0.15)
            motherFrame:Close()

    		UIFuncs.BrowseUI(manufacturers[i], i) -- remove frame when you do this
    	end
    end

    OpenDealerFrame = motherFrame
end

-- to-do:
-- n/a just code
-- hovered car buttons

-- calc stats somehow
-- upgrade calc needs to be serverside i think (apply upgrades temporarily and then reset to original stats on exit)
-- we need to find a way to make this unexploitable (reset on exiting vehicle, reset on closing UI, create setupmove hook to reset stats once player position has changed a fair bit then remove hook)