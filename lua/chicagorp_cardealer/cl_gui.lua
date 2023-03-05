local OpenModelPanel = nil
local vehiclewheels = {}
local cubemapmats = {}
local lerpStart = 0
local lerpTime = 0
local defaultCamPos = Vector(50, 50, 50)
local defaultCamAng = Angle(0, 0, 40)

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

local function CreateCSWheel(vehiclename, ent, index, attachmentpos, height, swap_y)
	-- ent.VehicleData (gmod_sent_vehicle_fphysics_base/spawn.lua#L345)
	-- wheel height (simulate suspension basically, gmod_sent_vehicle_fphysics_base/spawn.lua#L345)
	if !IsValid(ent) then return end

	local spawnlist = list.Get("simfphys_vehicles")
	local simfphystbl = spawnlist[vehiclename]
    local fAng = ent:LocalToWorldAngles(ent.VehicleData.LocalAngForward)
    local rAng = ent:LocalToWorldAngles(ent.VehicleData.LocalAngRight)
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

local function FancyModelPanel(parent, model, x, y, w, h)
	-- create wheel cs models
	-- create exhaust particles if possible
	-- create light entities if possible
    if lightcolor == nil then lightcolor = whitecolor end
    if model == nil or parent == nil then return end

    local parentPanel = vgui.Create("DPanel", parent)
    parentPanel:SetSize(w, h)
    parentPanel:SetPos(x, y)

    function parentPanel:Paint(w, h)
        chicagoRP.BlurBackground(self)
    end

    local modelPanel = vgui.Create("DModelPanel", parentPanel)
    modelPanel:SetSize(w, h)
    modelPanel:SetPos(x, y)
    modelPanel:SetModel(model)
    modelPanel:SetAmbientLight(whitecolor) -- main light up top (typically slightly yellow), fill light below camera (very faint pale blue), rim light to the left (urban color), rimlight to the right (white)
    modelPanel:SetDirectionalLight(BOX_TOP, slightyellowcolor)
    modelPanel:SetDirectionalLight(BOX_FRONT, slightbluecolor)
    modelPanel:SetDirectionalLight(BOX_LEFT, lightcolor)

    local oldCamPos = modelPanel:GetCamPos()
    local oldCamAng = modelPanel:GetLookAng()

    self:CreateWheel(1, WheelFL, self:GetAttachment(self:LookupAttachment("wheel_fl")).Pos, self.FrontHeight, self.FrontWheelRadius, false, self.posepositions.Pose1_Pos_FL, self.VehicleData.suspensiontravel_fl, self.FrontConstant, self.FrontDamping, self.FrontRelativeDamping)
    self:CreateWheel(2, WheelFR, self:GetAttachment(self:LookupAttachment("wheel_fr")).Pos, self.FrontHeight, self.FrontWheelRadius, true, self.posepositions.Pose1_Pos_FR, self.VehicleData.suspensiontravel_fr, self.FrontConstant, self.FrontDamping, self.FrontRelativeDamping)
    self:CreateWheel(3, WheelRL, self:GetAttachment(self:LookupAttachment("wheel_rl")).Pos, self.RearHeight, self.RearWheelRadius, false, self.posepositions.Pose1_Pos_RL, self.VehicleData.suspensiontravel_rl, self.RearConstant, self.RearDamping, self.RearRelativeDamping)
    self:CreateWheel(4, WheelRR, self:GetAttachment(self:LookupAttachment("wheel_rr")).Pos, self.RearHeight, self.RearWheelRadius, true, self.posepositions.Pose1_Pos_RR, self.VehicleData.suspensiontravel_rr, self.RearConstant, self.RearDamping, self.RearRelativeDamping)

    function modelPanel:LayoutEntity(ent) return end -- how do we make cam movement smoothened?

    function modelPanel:PreDrawModel(ent)
    	create wheel cs models
    	create exhaust particles
    	create light entities
    end

    function modelPanel:PostDrawModel(ent)
    	create wheel cs models
    	create exhaust particles
    	create light entities
    	render.SuppressEngineLighting(false)
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
		remove all ents and csents
	end

	SetStaticCubemap(modelPanel.Entity)

	OpenModelPanel = modelPanel

    return modelPanel
end

local function OpenBrowseUI(manu)
	fancydmodelpanel
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
	create frame
	enable keyboard nagivation -- how do we do keyboard nagivation?

	for manufacturers table do
		create button in dscrollpanel

		doclick
			openbrowseUI(v)
		end
	end
end

-- upgrade calc needs to be serverside i think (apply upgrades temporarily and then reset to original stats on exit)
-- we need to find a way to make this unexploitable (reset on exiting vehicle, reset on closing UI, create setupmove hook to reset stats once player position has changed a fair bit then remove hook)