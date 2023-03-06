local OpenModelPanel = nil
local vehiclewheels = {}
local cubemapmats = {}
local lerpStart = 0
local lerpTime = 0
local defaultCamPos = Vector(50, 50, 50)
local defaultCamAng = Angle(0, 0, 40)
local rightangle = Angle(0, 90, 0)

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

local function GarbageCollectMats()
	if table.IsEmpty(cubemapmats) then return end

	for i = 1, #cubemapmats do
		cubemapmats[i] = nil
	end
end

local function GarbageCollectCSEnts(tbl)
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

local function FancyModelPanel(parent, simfphystbl, x, y, w, h)
    if lightcolor == nil then lightcolor = whitecolor end
    if model == nil or parent == nil then return end

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
    modelPanel:SetModel(simfphystbl.Model)
    -- modelPanel:SetAmbientLight(color_white) -- main light up top (typically slightly yellow), fill light below camera (very faint pale blue), rim light to the left (urban color), rimlight to the right (white)
    -- modelPanel:SetDirectionalLight(BOX_TOP, slightyellowcolor)
    -- modelPanel:SetDirectionalLight(BOX_FRONT, slightbluecolor)
    -- modelPanel:SetDirectionalLight(BOX_LEFT, lightcolor)

    local oldCamPos = modelPanel:GetCamPos()
    local oldCamAng = modelPanel:GetLookAng()

    function modelPanel:LayoutEntity(ent) return end -- how do we make cam movement smoothened?

    if IsValid(modelPanel.Entity) then -- post-init
    	local ent = modelPanel.Entity
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

    	create exhaust
    	create light entities
    end

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
		GarbageCollectMats()
		GarbageCollectCSEnts(CSents)
	end

	function modelPanel:Think()
		if !IsValid(modelPanel.Entity) then return end
		local curtime = CurTime()
		local IdleRPM = simfphystbl.IdleRPM
		local LimitRPM = simfphystbl.LimitRPM
	    self.RunNext = self.RunNext or 0

	    if self.RunNext < curtime then
	        ExhaustEffect(modelPanel.Entity, simfphystbl, 0.50, IdleRPM, LimitRPM)
	        self.RunNext = curtime + 0.06
	    end
	end

	SetStaticCubemap(modelPanel.Entity)

	OpenModelPanel = modelPanel

    return modelPanel
end

local function ManufacturerButton(parent, tbl, w, h)
    local button = parent:Add("DButton")
    button:SetSize(w, h)

    button:SetText(tbl.PrintName)

    function button:Paint(w, h)
        draw.RoundedBox(2, 0, 0, w, h, graycolor)
        draw.DrawText(self:GetText(), "Default", 20, 0, whitecolor, TEXT_ALIGN_LEFT)
        surface.SetMaterial(iconcache[tbl.PrintName])
        surface.DrawTexturedRectRotated(x, y, w, h, 0) -- how do we make the cubemap rotate with model orientation?

        return nil
    end

    return button
end

local function OpenBrowseUI(frame)
	FancyModelPanel(frame, simfphystbl, x, y, w, h)
	dpnael for stats
	dpanel for playerstats
	horizontalscrollpanel for car buttons

	dstatpanel:performlayout
		dstatpanel.car:getstats()
	end

	for k, v in ipairs(manu) do
		dbutton

		if dbutton hovered
			timer simple 1.5 dmodelpanel:setModel()
			dstatpanel.car = self
			dstatpanel invalidatelayout()
		end

		dbutton doclick
			OpenPurchaseUI
		end
	end
end

local function OpenDealerUI()
	local manufacturers = chicagoRPCarDealer.Manufacturers
	local vehicles = chicagoRPCarDealer.Vehicles
	local manufacturers_hashtable = chicagoRPCarDealer.Manufacturers_HashTable
	local vehicles_hashtable = chicagoRPCarDealer.Vehicles_HashTable
    local scrW = ScrW()
    local scrH = ScrH()
    local motherFrame = vgui.Create("DFrame")
    motherFrame:SetSize(scrWm scrH)
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

	local scrollPanel = vgui.Create("DScrollPanel", motherFrame) -- Create the Scroll panel
	scrollPanel:Dock(FILL)
	scrollPanel:DockMargin(10, 150, 10, 10)

	local buttonLayout = vgui.Create("DIconLayout", scrollPanel)
	buttonLayout:Dock(FILL)
	buttonLayout:SetSpaceY(10)
	buttonLayout:SetSpaceX(10)

    for i = 1, #manufacturers do
    	local manuButton = ManufacturerButton(buttonLayout, manufacturers[i], 200, 250)

    	function manuButton:DoClick()
    		code here lmao
    		openbrowseUI(v) -- remove frame when you do this
    	end
    end
end

-- to-do:
-- icon material caching
-- adding vehicles to manufacturer table (ONLY THEIR NAMES), keep current vehicle table as an index for that

-- upgrade calc needs to be serverside i think (apply upgrades temporarily and then reset to original stats on exit)
-- we need to find a way to make this unexploitable (reset on exiting vehicle, reset on closing UI, create setupmove hook to reset stats once player position has changed a fair bit then remove hook)