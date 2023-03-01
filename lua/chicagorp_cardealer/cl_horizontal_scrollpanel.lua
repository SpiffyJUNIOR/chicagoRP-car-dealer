local PANEL = {}
AccessorFunc(PANEL, "Padding", "Padding")
AccessorFunc(PANEL, "pnlCanvas", "Canvas")

function PANEL:Init()
    self.pnlCanvas = vgui.Create("Panel", self)

    self.pnlCanvas.OnMousePressed = function(self, code)
        self:GetParent():OnMousePressed(code)
    end

    self.pnlCanvas:SetMouseInputEnabled(true)

    self.pnlCanvas.PerformLayout = function(pnl)
        self:PerformLayoutInternal()
        self:InvalidateParent()
    end

    -- Create the scroll bar
    self.VBar = vgui.Create("chicagoRP_HorizontalScrollBar", self)
    self.VBar:Dock(BOTTOM)
    self:SetPadding(0)
    self:SetMouseInputEnabled(true)
    -- This turns off the engine drawing
    self:SetPaintBackgroundEnabled(false)
    self:SetPaintBorderEnabled(false)
    self:SetPaintBackground(false)
end

function PANEL:AddItem(pnl)
    pnl:SetParent(self:GetCanvas())
end

function PANEL:OnChildAdded(child)
    self:AddItem(child)
end

function PANEL:SizeToContents()
    self:SetSize(self.pnlCanvas:GetSize())
end

function PANEL:GetVBar()
    return self.VBar
end

function PANEL:GetCanvas()
    return self.pnlCanvas
end

function PANEL:InnerWidth()
    return self:GetCanvas():GetWide()
end

function PANEL:Rebuild()
    self:GetCanvas():SizeToChildren(false, true)

    -- Although this behaviour isn't exactly implied, center vertically too
    if self.m_bNoSizing and self:GetCanvas():GetTall() < self:GetTall() then
        self:GetCanvas():SetPos(0, (self:GetTall() - self:GetCanvas():GetTall()) * 0.5)
    end
end

function PANEL:OnMouseWheeled(dlta)
    return self.VBar:OnMouseWheeled(dlta)
end

function PANEL:OnVScroll(iOffset)
    self.pnlCanvas:SetPos(0, iOffset)
end

function PANEL:ScrollToChild(panel)
    self:InvalidateLayout(true)
    local x, _ = self.pnlCanvas:GetChildPosition(panel)
    local w, _ = panel:GetSize()
    x = x + w * 0.5
    x = x - self:GetWide() * 0.5
    self.VBar:AnimateTo(x, 0.5, 0, 0.5)
end

-- Avoid an infinite loop
function PANEL:PerformLayoutInternal()
    local CanvasWide = self.pnlCanvas:GetWide()
    local Wide = self:GetWide()
    local YPos = 0
    self:Rebuild()
    self.VBar:SetUp(self:GetWide(), self.pnlCanvas:GetWide())
    XPos = self.VBar:GetOffset()

    if self.VBar.Enabled then
        Wide = Wide - self.VBar:GetWide()
    end

    self.pnlCanvas:SetPos(0, YPos)
    self.pnlCanvas:SetWide(Wide)
    self:Rebuild()

    if CanvasWide != self.pnlCanvas:GetWide() then
        self.VBar:SetScroll(self.VBar:GetScroll()) -- Make sure we are not too far down!
    end
end

function PANEL:PerformLayout()
    self:PerformLayoutInternal()
end

function PANEL:Clear()
    return self.pnlCanvas:Clear()
end

derma.DefineControl("chicagoRP_HorizontalScrollPanel", "", PANEL, "DPanel")