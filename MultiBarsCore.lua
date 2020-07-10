
local _
local MBC_DEBUG = false

local function NotNull(value)
	if value == nil then
		return "nil"
	else
		return value
	end
end

local function MultiBarsCore_ShortenHotKey(key)
	local short, n = "", 1
	
	local start = string.find(key, "[-]", n)
	while start do
		short = short .. string.lower(string.sub(key, n, n)) .. "-"
		
		n = start + 1
		start = string.find(key, "[-]", n)
	end
	
	short = short .. string.sub(key, n)
	
	return short
end

function MultiBarsCore_Bar_SetVisible(self, visible, nopet, nocombat)
	if visible then
		self.hidden = nil
		self:Show()
		if nopet and nocombat then
			RegisterStateDriver(self, "visibility", "[nopet,nocombat,nopetbattle,nooverridebar,novehicleui,nopossessbar] show; hide")
		elseif nopet then
			RegisterStateDriver(self, "visibility", "[nopet,nopetbattle,nooverridebar,novehicleui,nopossessbar] show; hide")
		elseif nocombat then
			RegisterStateDriver(self, "visibility", "[nocombat,nopetbattle,nooverridebar,novehicleui,nopossessbar] show; hide")
		else
			RegisterStateDriver(self, "visibility", "[nopetbattle,nooverridebar,novehicleui,nopossessbar] show; hide")
		end
	else
		self.hidden = true
		self:Hide()
		UnregisterStateDriver(self, "visibility")
	end
end

function MultiBarsCore_Bar_OnLoad(self)
	local name = self:GetName()
	if MBC_DEBUG then
		DEFAULT_CHAT_FRAME:AddMessage("MultiBarsCore_Bar_OnLoad(" .. name .. ")")
	end
	
	-- Check the "interface"
	if not self.bartype then
		error(name .. ".bartype is not set")
	end
	if not self.actionType then
		error(name .. ".actionType is not set")
	end
	if not self.GetAvailableActions then
		error(name .. ".GetAvailableActions is not set")
	end
	if not self.GetHiddenActions then
		error(name .. ".GetHiddenActions is not set")
	end
	
	self.actions = {}
	self.maxButtons = 12
	self.buttons = {}
	self.buttonActions = {}
	self.cooldowns = {}
	self.counts = {}
	self.hotkeyTexts = {}
	self.icons = {}
	self.names = {}
	self.normals = {}
	local n
	for n = 1, self.maxButtons do
		self.buttons[n] = _G[name .. "Button" .. n]
		self.buttons[n].buttonNumber = n
		self.cooldowns[n] = _G[name .. "Button" .. n .. "Cooldown"]
		self.counts[n] = _G[name .. "Button" .. n .. "Count"]
		self.hotkeyTexts[n] = _G[name .. "Button" .. n .. "HotKey"]
		self.icons[n] = _G[name .. "Button" .. n .. "Icon"]
		self.names[n] = _G[name .. "Button" .. n .. "Name"]
		self.normals[n] = _G[name .. "Button" .. n .. "NormalTexture"]
	end
	
	if self.actionType == "spell" then
		self:RegisterEvent("MODIFIER_STATE_CHANGED")
		self:SetScript("OnEvent", MultiBarsCore_Bar_OnEvent)
	end
	
	self:EnableMouse(1)
	self:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 5, right = 5, top = 5, bottom = 5 },
	})
	
	MultiBarsCore_Bar_SetBorderColor(self, nil)
end

-- CraftFrame is used for hunter Beast Training
local function MultiBarsCore_GetCraftName()
	local name
	
	if CraftFrame and CraftFrame:IsShown() then
		if CraftFrameTitleText then
			name = CraftFrameTitleText:GetText()
		end
	end
	
	return name
end

-- TradeSkillFrame is used for professions
local function MultiBarsCore_GetTradeName()
	local name
	
	if TradeSkillFrame and TradeSkillFrame:IsShown() then
		if TradeSkillFrameTitleText then
			name = TradeSkillFrameTitleText:GetText()
		end
	end
	
	return name
end

local function MultiBarsCore_GetBuffs(unit)
	local buffs = {}
	
	local n
	for n = 1, 40 do
		local spellId = select(10, UnitBuff(unit, n))
		if spellId then
			buffs[spellId] = true
		end
	end
	
	return buffs
end

local function MultiBarsCore_GetPetBuffs()
	return MultiBarsCore_GetBuffs("pet")
end

local function MultiBarsCore_GetPlayerBuffs()
	return MultiBarsCore_GetBuffs("player")
end

local function MultiBarsCore_ShowCooldown(cooldown, start, duration, enable)
	if start and duration and duration > 0 then
		cooldown:SetCooldown(start, duration)
	else
		cooldown:Clear()
	end
end

function MultiBarsCore_Bar_OnEvent(self, event, state)
	if self:IsShown() then
		local n
		for n = 1, self.maxButtons do
			local action = self.buttonActions[n]
			if action and action.alternate then
				local texture = IsAltKeyDown() and action.alternate.texture or action.texture
				self.icons[n]:SetTexture(texture)
				self.normals[n]:Hide()
			end
		end
	end
end

local function dumpObject(name, object)
	if not object then
		DEFAULT_CHAT_FRAME:AddMessage(name .. " is nil")
	else
		local k, v
		DEFAULT_CHAT_FRAME:AddMessage(name .. ":")
		for k, v in pairs(object) do
			DEFAULT_CHAT_FRAME:AddMessage(" [" .. tostring(NotNull(k)) .. "]: " .. tostring(NotNull(v)))
		end
	end
end

local dumpCount = 0

function MultiBarsCore_Bar_OnUpdate(self)
	-- We have to manually update cooldowns, item quantities, and highlighting
	local craftName = MultiBarsCore_GetCraftName()
	local tradeName = MultiBarsCore_GetTradeName()
	local buffs = MultiBarsCore_GetPlayerBuffs()
	local petBuffs
	if UnitName("pet") then
		petBuffs = MultiBarsCore_GetPetBuffs()
	else
		petBuffs = {}
	end
	
	local n
	for n = 1, self.maxButtons do
		if n <= #self.buttonActions then
			local action = self.buttonActions[n]
			local button, cooldown, count = self.buttons[n], self.cooldowns[n], self.counts[n]
			
			-- see: line 506 (as of July 2020):
			-- https://github.com/Gethe/wow-ui-source/blob/classic/FrameXML/ActionButton.lua
			local isUsable, notEnoughMana = true, false
			
			if action.actionType == "item" then
				MultiBarsCore_ShowCooldown(cooldown, GetItemCooldown(action.item))
				
				if self.itemCounts and self.itemCounts[action.item] then
					count:SetText(tostring(self.itemCounts[action.item]))
				else
					count:SetText("")
				end
				
				isUsable, notEnoughMana = IsUsableItem(action.item)
				
				-- Show yellow border highlight when:
				-- the player currently has the buff
				button:SetChecked(action.spellId and (buffs[action.spellId] or IsCurrentSpell(action.spellId)))
			elseif action.actionType == "macro" then
				local name, icon = GetMacroInfo(action.slot)
				if icon ~= action.texture then
					action.texture = icon
					
					self.icons[n]:SetTexture(action.texture)
				end
				
				local wasSpell
				local spellId = GetMacroSpell(action.slot)
				if spellId then
					MultiBarsCore_ShowCooldown(cooldown, GetSpellCooldown(spellId))
					wasSpell = true
					
					isUsable, notEnoughMana = IsUsableSpell(spellId)
				end
				
				local border = button.Border
				
				local itemName, itemLink = GetMacroItem(action.slot)
				local wasItem, wasEquippedItem
				if itemLink then
					local itemId = GetItemInfoInstant(itemLink)
					if itemId then
						if IsEquippedItem(itemId) and border then
							wasEquippedItem = true
							-- see: line 383 (as of July 2020):
							-- https://github.com/Gethe/wow-ui-source/blob/classic/FrameXML/ActionButton.lua
							border:SetVertexColor(0, 1.0, 0, 0.35)
							border:Show()
						end
						if not wasSpell then
							MultiBarsCore_ShowCooldown(cooldown, GetItemCooldown(itemId))
							wasItem = true
						end
					end
				end
				
				if not wasSpell and not wasItem then
					cooldown:Clear()
				end
				if not wasEquippedItem and border then
					border:Hide()
				end
				
				-- Show yellow border highlight when:
				-- the player currently has the buff
				button:SetChecked(spellId and (buffs[spellId] or IsCurrentSpell(spellId)))
			elseif action.actionType == "spell" or action.actionType == "spell-item" then
				local a = action
				if action.alternate and IsAltKeyDown() then
					a = action.alternate
				end
				
				MultiBarsCore_ShowCooldown(cooldown, GetSpellCooldown(a.action))
				
				if a.itemName and self.itemCountsByName and self.itemCountsByName[a.itemName] then
					count:SetText(tostring(self.itemCountsByName[a.itemName]))
				else
					count:SetText("")
				end
				
				isUsable, notEnoughMana = IsUsableSpell(a.spellId)
				
				-- Show yellow border highlight when:
				-- the associated crafting window is open
				-- the player currently has the buff
				-- the spell is currently in targetting mode
				button:SetChecked((craftName and craftName == action.action) or (tradeName and tradeName == action.action) or (action.spellId and buffs[action.spellId]) or (action.alternate and action.alternate.spellId and buffs[action.alternate.spellId]) or (action.petBuffId and petBuffs[action.petBuffId]) or (a.spellId and IsCurrentSpell(a.spellId)))
			end
			
			if isUsable then
				self.icons[n]:SetVertexColor(1.0, 1.0, 1.0)
			elseif notEnoughMana then
				self.icons[n]:SetVertexColor(0.5, 0.5, 1.0)
			else
				self.icons[n]:SetVertexColor(0.4, 0.4, 0.4)
			end
			
			-- this thing keeps showing itself, and has to be re-hidden
			-- (this is the extra-thickness on the border. It can be hard to notice sometimes)
			self.normals[n]:Hide()
		end
	end
end

local function MultiBarsCore_Bar_UpdateBinding(self, buttonNumber)
	local button, hotkeyText
	button = self.buttons[buttonNumber]
	hotkeyText = self.hotkeyTexts[buttonNumber]
	
	if not hotkeyText then
		DEFAULT_CHAT_FRAME:AddMessage("No hotkey text for " .. buttonNumber)
		return
	end
	
	local key1, key2 = GetBindingKey(button:GetName())
	if key1 then
		hotkeyText:SetText(MultiBarsCore_ShortenHotKey(key1))
	elseif key2 then
		hotkeyText:SetText(MultiBarsCore_ShortenHotKey(key2))
	else
		hotkeyText:SetText("")
	end
	
	if key1 then
		SetOverrideBindingClick(self, true, key1, button:GetName())
	end
	if key2 then
		SetOverrideBindingClick(self, true, key2, button:GetName())
	end
end

function MultiBarsCore_Bar_UpdateBindings(self)
	ClearOverrideBindings(self)
	
	local n
	for n = 1, self.maxButtons do
		MultiBarsCore_Bar_UpdateBinding(self, n)
	end
end

local function MultiBarsCore_Bar_SetActionOnButton(self, action, buttonNumber)
	if self.maxButtons and buttonNumber > self.maxButtons then
		return
	end
	self.buttonActions[buttonNumber] = action
	
	local button, cooldown, count, icon, name, normalTexture, shown
	button = self.buttons[buttonNumber]
	cooldown = self.cooldowns[buttonNumber]
	count = self.counts[buttonNumber]
	icon = self.icons[buttonNumber]
	name = self.names[buttonNumber]
	normalTexture = self.normals[buttonNumber]
	
	if cooldown.currentCooldownType ~= COOLDOWN_TYPE_NORMAL then
		cooldown:SetDrawEdge(false)
		cooldown:SetSwipeColor(0, 0, 0)
		cooldown:SetHideCountdownNumbers(false)
		cooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL
	end
	
	if action and action.actionType == "item" and action.action then
		button:SetAttribute("type", action.actionType)
		button:SetAttribute("item", action.action)
		icon:SetTexture(action.texture)
		shown = true
		
	elseif action and action.actionType == "macro" and action.action then
		button:SetAttribute("type", action.actionType)
		button:SetAttribute("macro", action.slot)
		icon:SetTexture(action.texture)
		name:SetText(action.action)
		shown = true
		
	elseif action and action.actionType == "spell" and action.action then
		button:SetAttribute("type", action.actionType)
		button:SetAttribute("spell", action.action)
		if action.alternate then
			button:SetAttribute("alt-type*", action.alternate.actionType)
			button:SetAttribute("alt-spell*", action.alternate.action)
		else
			button:SetAttribute("alt-type*", nil)
			button:SetAttribute("alt-spell*", nil)
		end
		icon:SetTexture(action.texture)
		shown = true
		
	elseif action and action.actionType == "spell-item" and action.action then
		button:SetAttribute("type", "spell")
		button:SetAttribute("spell", action.action)
		button:SetAttribute("target-item", action.itemName)
		icon:SetTexture(action.texture)
		shown = true
		
	else
		-- hidden buttons
		button:SetAttribute("type", nil)
		button:SetAttribute("item", nil)
		button:SetAttribute("macro", nil)
		button:SetAttribute("spell", nil)
		button:SetAttribute("alt-type*", nil)
		button:SetAttribute("alt-spell*", nil)
	end

	if shown then
		button:Show()
		normalTexture:Hide()
	else
		button:Hide()
	end
end

function MultiBarsCore_Bar_Autosize(self)
	local numButtons = (self.buttonActions and #self.buttonActions) or 0
	if numButtons > self.maxButtons then
		numButtons = self.maxButtons
	end
	if MBC_DEBUG then
		DEFAULT_CHAT_FRAME:AddMessage("MultiBarsCore_Bar_Autosize(" .. self:GetName() .. ") " .. tostring(numButtons))
	end
	if self.vertical then
		self:SetWidth(44)
		self:SetHeight(numButtons * 38 + 8)
	else
		self:SetWidth(numButtons * 38 + 8)
		self:SetHeight(44)
	end
end

function MultiBarsCore_Bar_UpdateActions(self)
	if MBC_DEBUG then
		DEFAULT_CHAT_FRAME:AddMessage("MultiBarsCore_Bar_UpdateActions(" .. self:GetName() .. ")")
	end
	
	if InCombatLockdown() then
		if self.MarkCombatLockdownFlag then
			self.MarkCombatLockdownFlag(self)
		end
		return
	end
	
	local actions = self:GetAvailableActions()
	self.actions = actions
	local hidden = self:GetHiddenActions()
	wipe(self.buttonActions)
	
	local buttonNumber = 1
	local n = 1
	while n <= #actions do
		local action = actions[n]
		
		if not action.hideId or not hidden[action.hideId] then
			MultiBarsCore_Bar_SetActionOnButton(self, action, buttonNumber)
			buttonNumber = buttonNumber + 1
		end
		
		n = n + 1
	end
	-- hide the rest of the buttons
	for buttonNumber = buttonNumber, self.maxButtons do
		MultiBarsCore_Bar_SetActionOnButton(self, nil, buttonNumber)
	end
	
	if MBC_DEBUG then
		DEFAULT_CHAT_FRAME:AddMessage("Frame " .. self:GetName() .. " has actions: " .. #self.buttonActions)
	end
	if #self.buttonActions > 0 and not self.hidden then
		MultiBarsCore_Bar_SetVisible(self, true)
		MultiBarsCore_Bar_Autosize(self)
	else
		MultiBarsCore_Bar_SetVisible(self, false)
	end
end

function MultiBarsCore_Bar_SetOrientation(self, vertical)
	self.vertical = vertical
	if not self.buttons then
		return
	end
	local n
	if vertical then
		self.buttons[1]:ClearAllPoints()
		self.buttons[1]:SetPoint("TOP", 0, -5)
		for n = 2, self.maxButtons do
			self.buttons[n]:ClearAllPoints()
			self.buttons[n]:SetPoint("TOP", self.buttons[n - 1], "BOTTOM", 0, -2)
		end
	else
		self.buttons[1]:ClearAllPoints()
		self.buttons[1]:SetPoint("LEFT", 5, 0)
		for n = 2, self.maxButtons do
			self.buttons[n]:ClearAllPoints()
			self.buttons[n]:SetPoint("LEFT", self.buttons[n - 1], "RIGHT", 2, 0)
		end
	end
	MultiBarsCore_Bar_Autosize(self)
end

function MultiBarsCore_Bar_SetBorderColor(self, color)
	if MBC_DEBUG then
		DEFAULT_CHAT_FRAME:AddMessage("MultiBarsCore_Bar_SetBorderColor(" .. self:GetName() .. ")")
	end
	
	if not color then
		color = { 2 / 3, 2 / 3, 0.7, 1 }
	end
	
	local r, g, b, a = unpack(color)
	self:SetBackdropBorderColor(r, g, b)
	self:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b, 0.7)
end

local function MultiBarsCore_GetCooldownString(startTime, duration)
	if startTime and duration then
		local now = GetTime()
		local endTime = startTime + duration
		if now < endTime then
			return SecondsToTime(endTime - now, nil, true, nil, true)
		end
	end
	return nil
end

local function MultiBarsCore_ShowItemTooltip(itemId)
	GameTooltip:SetItemByID(itemId)
	local cooldownString = MultiBarsCore_GetCooldownString(GetItemCooldown(itemId))
	if cooldownString then
		GameTooltip:AddLine("Cooldown Remaining: " .. cooldownString, 1, 1, 1)
	end
	GameTooltip:Show()
end

local function MultiBarsCore_ShowActionTooltip(action, add)
	if action.actionType == "item" then
		MultiBarsCore_ShowItemTooltip(action.item)
	elseif action.actionType == "macro" then
		local spellId = GetMacroSpell(action.slot)
		if spellId then
			GameTooltip:SetSpellByID(spellId)
			GameTooltip:Show()
			return
		end
		
		local itemName, itemLink = GetMacroItem(action.slot)
		if itemLink then
			local itemId = GetItemInfoInstant(itemLink)
			if itemId then
				MultiBarsCore_ShowItemTooltip(itemId)
				return
			end
		end
		
		-- just show the name of the macro in the tooltip if there's no spell
		GameTooltip:SetText(action.action, 1, 1, 1)
		GameTooltip:Show()
	elseif action.actionType == "spell" then
		local _, _, _, _, _, _, maxRankId = GetSpellInfo(GetSpellInfo(action.action))
		if add then
			GameTooltip:AddSpellByID(maxRankId)
		else
			GameTooltip:SetSpellByID(maxRankId)
		end
		GameTooltip:Show()
	elseif action.actionType == "spell-item" then
		MultiBarsCore_ShowItemTooltip(action.item)
		
		GameTooltip:AddLine(" ")
		
		local _, _, _, _, _, _, maxRankId = GetSpellInfo(GetSpellInfo(action.action))
		GameTooltip:AddSpellByID(maxRankId)
	end
end

function MultiBarsCore_Button_SetTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	
	local action
	if self.buttonNumber then
		local frame = self:GetParent()
		action = frame.buttonActions[self.buttonNumber]
	end
	
	if action then
		if IsAltKeyDown() and action.alternate then
			MultiBarsCore_ShowActionTooltip(action.alternate)
		else
			MultiBarsCore_ShowActionTooltip(action)
			
			if action.alternate then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Alt:")
				MultiBarsCore_ShowActionTooltip(action.alternate, true)
			end
		end
		
	end
end

function MultiBarsCore_Bar_OnMouseUp(self, button)
	if button == "RightButton" then
		GameTooltip:Hide()
		Lib_ToggleDropDownMenu(1, nil, _G[self:GetName() .. "DropDown"], self:GetName(), 0, 0)
		return
	end
	
	CloseDropDownMenus()
end

function MultiBarsCore_DropDownMenu_OnLoad(self)
	Lib_UIDropDownMenu_Initialize(self, MultiBarsCore_DropDownMenu_Initialize, "MENU")
	Lib_UIDropDownMenu_SetButtonWidth(self, 20)
	Lib_UIDropDownMenu_SetWidth(self, 20)
end

function MultiBarsCore_DropDownMenu_Initialize(frame, level, menuList)
	local bar = frame:GetParent()
	
	if bar and bar.DropDownInitialize then
		bar.DropDownInitialize(frame, level, menuList)
	end
end
