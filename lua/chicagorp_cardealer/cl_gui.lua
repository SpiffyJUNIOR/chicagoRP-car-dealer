local function OpenBrowseUI(manu)
	dmodelpanel
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