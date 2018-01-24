

function Damagelog:DrawSettings(x, y)

    local selectedcolor

    self.Settings = vgui.Create("DPanelList")
	self.Settings:SetSpacing(10)
	self.Settings:EnableVerticalScrollbar(true)
	
	self.ColorSettings = vgui.Create("DForm")
	self.ColorSettings:SetName("Colors")
	
	self.ColorChoice = vgui.Create("DComboBox")
	for k,v in pairs(self.colors) do
	    self.ColorChoice:AddChoice(k)
	end
	self.ColorChoice:ChooseOptionID(1)
	self.ColorChoice.OnSelect = function(panel,index,value,data)
	    self.ColorMixer:SetColor(self.colors[value].Custom)
		selectedcolor = value
	end
	self.ColorSettings:AddItem(self.ColorChoice)
	
	self.ColorMixer = vgui.Create("DColorMixer")
	self.ColorMixer:SetHeight(200)
	local found = false
	for k,v in pairs(self.colors) do
	    if not found then
	        self.ColorMixer:SetColor(v.Custom)
			selectedcolor = k
			found = true
		end
	end
	self.ColorSettings:AddItem(self.ColorMixer)
	
	self.SaveColor = vgui.Create("DButton")
	self.SaveColor:SetText("Save")
	self.SaveColor.DoClick = function()
	    local c = self.ColorMixer:GetColor()
		self.colors[selectedcolor].Custom = c
		self:SaveColors()
	end
	self.ColorSettings:AddItem(self.SaveColor)
	
	self.defaultcolor = vgui.Create("DButton")
	self.defaultcolor:SetText("Set as default")
	self.defaultcolor.DoClick = function()
		local c = self.colors[selectedcolor].Default
	    self.ColorMixer:SetColor(c)
		self.colors[selectedcolor].Custom = c
		self:SaveColors()
	end	
	self.ColorSettings:AddItem(self.defaultcolor)
	
	self.Settings:AddItem(self.ColorSettings)
	
	self.Tabs:AddSheet( "Settings", self.Settings, "icon16/wrench.png", false, false)	

end