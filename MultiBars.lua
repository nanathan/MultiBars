local _

local MultiBars = LibStub("AceAddon-3.0"):NewAddon("MultiBars", "AceConsole-3.0", "AceEvent-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local MULTIBARS_DEBUG = false
local MULTIBARS_DEBUG_VERBOSE = false
local LOGGED_EVENTS = {}
local UNLOGGED_EVENTS = {
	["BAG_UPDATE"] = true,
}

-- Default settings. WoW will replace with persisted values after the addon is loaded.
MultiBarsGlobalOptions = MultiBarsGlobalOptions or {}
MultiBarsOptions = MultiBarsOptions or {}
local MultiBarsGlobalOptionsDefaults = {
	blacklist = {
	},
	feedPetBlacklist = {
	},
}
local MultiBarsOptionsDefaults = {
	adjustContainerOffset = true,
	adjustGroupsForPetBar = false,
	dropdownSound = true,
	bars = {
		MultiBarAspect = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
		},
		MultiBarBlessing = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
			useAlternates = true,
			useModSwitch = true,
		},
		MultiBarBuff = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
		},
		MultiBarConsumable = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
		},
		MultiBarCurse = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
		},
		MultiBarDemon = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
		},
		MultiBarDruid = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
			useAlternates = true,
			useModSwitch = true,
		},
		MultiBarFeedPet = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
			includeBuffFood = false,
		},
		MultiBarFood = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
			includeBuffFood = false,
		},
		MultiBarHunterPet = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
		},
		MultiBarMacro = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
		},
		MultiBarMageArmor = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
		},
		MultiBarMageBuff = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
			useAlternates = true,
			useModSwitch = true,
		},
		MultiBarMagePortal = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
			useAlternates = true,
			useModSwitch = true,
		},
		MultiBarPriest = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
			useAlternates = true,
			useModSwitch = true,
		},
		MultiBarProfession = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
		},
		MultiBarSeal = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
		},
		MultiBarTrap = {
			color = { 2 / 3, 2 / 3, 0.7, 1 },
			hidden = {},
			maxButtons = 12,
			reversed = false,
		},
	},
	groups = {
		{
			bars = {},
			alignment = "right",
			nopet = true,
			nocombat = false,
			scale = 0.8,
			offset = {
				x = 0,
				y = 0,
			},
		},
		{
			bars = {},
			alignment = "right",
			nopet = true,
			nocombat = false,
			scale = 0.8,
			offset = {
				x = 0,
				y = 0,
			},
		},
		{
			bars = {},
			alignment = "bottom",
			nopet = true,
			nocombat = false,
			scale = 0.8,
			offset = {
				x = 0,
				y = 0,
			},
		},
		{
			bars = {},
			alignment = "top",
			nopet = true,
			nocombat = false,
			scale = 0.8,
			offset = {
				x = 0,
				y = 0,
			},
		},
	},
	blacklist = {
	},
	macros = {
		{},
		{},
		{},
		{},
		{},
		{},
		{},
		{},
		{},
		{},
		{},
		{},
	},
}

local function NotNull(value)
	if value == nil then
		return "nil"
	else
		return value
	end
end

local function MultiBars_clone(obj, seen)
	if type(obj) ~= "table" then return obj end
	local s = seen or {}
	if s[obj] then return s[obj] end
	local result = {}
	s[obj] = result
	local k, v
	for k, v in pairs(obj) do
		result[MultiBars_clone(k, s)] = MultiBars_clone(v, s)
	end
	return res
end

-- Recursively copy values from source to destination (but only for keys that were missing in dest)
local function MultiBars_copyMissing(source, dest)
	local k, v
	for k, v in pairs(source) do
		if type(v) == "table" then
			if not dest[k] then
				dest[k] = {}
			end
			MultiBars_copyMissing(v, dest[k])
		else
			if dest[k] == nil then
				dest[k] = v
			end
		end
	end
end

-- copy the defaults into the options while the addon is loading
MultiBars_copyMissing(MultiBarsGlobalOptionsDefaults, MultiBarsGlobalOptions)
MultiBars_copyMissing(MultiBarsOptionsDefaults, MultiBarsOptions)

MultiBarsConfig_MixinConfigFunctions(MultiBars)

local function MultiBars_MarkCombatLockdownFlag(self)
	MultiBars.needsPostCombatUpdate = true
end

function MultiBars_OnBarLoad(self)
	if MULTIBARS_DEBUG then
		MultiBars:Print("MultiBars_OnBarLoad(" .. self:GetName() .. ")")
	end

	self.addon = MultiBars
	-- bartype will be the suffix from the frame name, eg: Buff, Consumable, Food, Macro, Profession
	self.bartype = string.sub(self:GetName(), 9)
	if self.bartype == "Buff" or self.bartype == "Consumable" or self.bartype == "Food" then
		self.actionType = "item"
	elseif self.bartype == "Macro" then
		self.actionType = "macro"
	elseif self.bartype == "FeedPet" then
		self.actionType = "spell-item"
	else
		self.actionType = "spell"
	end
	self.GetAvailableActions = MultiBars_GetAvailableActions
	self.GetHiddenActions = function(self) return MultiBarsOptions.bars[self:GetName()].hidden end
	self.MarkCombatLockdownFlag = MultiBars_MarkCombatLockdownFlag
	self.DropDownInitialize = MultiBarsDropDown_Initialize
	
	MultiBarsCore_Bar_OnLoad(self)
end

local function MultiBars_AddBarAction(self, actions, action)
	if action then
		local n = #actions + 1
		actions[n] = action
	end
end

-- We have a separate tooltip that isn't shown in order to figure out spell reagents
-- (by having blizzard put the spell info into the tooltip, then getting the reagent info from it)
local MultiBarsTooltip = CreateFrame("GameTooltip", "MultiBarsTooltip", UIParent, "GameTooltipTemplate")
MultiBarsTooltip:SetOwner(UIParent, "ANCHOR_NONE")

local function MultiBars_GetReagentName(spellId)
	if spellId then
		MultiBarsTooltip:ClearLines()
		MultiBarsTooltip:SetSpellByID(spellId)
		for n = 1, MultiBarsTooltip:NumLines() do
			local text = _G["MultiBarsTooltipTextLeft" .. n]:GetText()
			if text then
				if string.find(text, "Reagents: |c........(.+)|r") then
					return gsub(text, "Reagents: |c........(.+)|r", "%1")
				elseif string.find(text, "Reagents: (.+)") then
					return gsub(text, "Reagents: (.+)", "%1")
				end
			end
		end
	end
	return nil
end

local function MultiBars_AddClassSpellAction(self, actions, spellInfo, options, barName)
	local name, _, icon, _, _, _, spellId = GetSpellInfo(spellInfo.name)
	local action, altAction
	local useAlt = options.useAlternates or options.useModSwitch
	
	-- Some spells have higher-level replacements with a different name...
	if spellInfo.name2 then
		local name2, _, icon2, _, _, _, spellId2 = GetSpellInfo(spellInfo.name2)
		
		if name2 then
			local reagent2 = MultiBars_GetReagentName(spellId2)
			action = {actionType = "spell", action = name2, spellId = spellId2, hideId = spellInfo.name, texture = icon2, itemName = reagent2}
		end
	end
	
	if name and not action then
		local reagent = MultiBars_GetReagentName(spellId)
		action = {actionType = "spell", action = name, spellId = spellId, hideId = spellInfo.name, texture = icon, itemName = reagent}
	end
	
	if useAlt then
		local altName, altIcon, altSpellId
		if spellInfo.alternate then
			altName, _, altIcon, _, _, _, altSpellId = GetSpellInfo(spellInfo.alternate)
			
			if altName then
				local reagent = MultiBars_GetReagentName(altSpellId)
				altAction = {actionType = "spell", action = altName, spellId = altSpellId, hideId = spellInfo.name, texture = altIcon, itemName = reagent}
			end
		end
	end
	
	if action and altAction then
		if options.useAlternates then
			local t = altAction
			altAction = action
			action = t
		end
		
		if options.useModSwitch then
			action.alternate = altAction
		end
	elseif altAction and not action then
		action = altAction
	end
	
	MultiBars_AddBarAction(self, actions, action)
end

local function MultiBars_AddProfessionAction(self, actions, profession)
	local name, _, icon, _, _, _, spellId = GetSpellInfo(profession)
	
	if name then
		MultiBars_AddBarAction(self, actions, {actionType = "spell", action = profession, spellId = spellId, hideId = profession, texture = icon})
	end
end

local function MultiBars_AddConsumableItemAction(self, actions, addedItems, bag, bagSlot)
	local itemid = GetContainerItemID(bag, bagSlot)
	if not itemid then
		return
	end
	if MULTIBARS_BUFF_FOOD_ITEMS[itemid] or MULTIBARS_FOOD_ITEMS[itemid] or MultiBars:IsBlacklistItem(itemid) then
		return
	end
	local itemName, _, _, _, _, itemType, _, _, itemEquipLoc, itemIcon = GetItemInfo(itemid)
	local itemSpell, spellId = GetItemSpell(itemid)
	
	if itemType == "Weapon" or itemType == "Armor" then
		return
	end
	
	if itemid and not addedItems[itemid] and itemSpell and itemEquipLoc == "" then
		addedItems[itemid] = true
		
		MultiBars_AddBarAction(self, actions, {actionType = "item", action = itemName, item = itemid, spellId = spellId, texture = itemIcon})
	end
end

local function MultiBars_AddFeedPetItemAction(self, actions, addedItems, bag, bagSlot, buffFood, regularFood)
	local itemid = GetContainerItemID(bag, bagSlot)
	if not itemid then
		return
	end
	
	if (not MULTIBARS_BUFF_FOOD_ITEMS[itemid] and not MULTIBARS_FOOD_ITEMS[itemid]) or MultiBars:IsFeedPetBlacklistItem(itemid) or addedItems[itemid] or (not buffFood and MULTIBARS_BUFF_FOOD_ITEMS[itemid]) then
		return
	end
	
	local itemName, _, _, _, _, itemType, _, _, itemEquipLoc, itemIcon = GetItemInfo(itemid)
	
	addedItems[itemid] = true
	
	MultiBars_AddBarAction(self, actions, {actionType = "spell-item", action = "Feed Pet", item = itemid, itemName = itemName, petBuffId = 1539, texture = itemIcon})
end

local function MultiBars_AddFoodItemAction(self, actions, addedItems, bag, bagSlot, buffFood, regularFood)
	local itemid = GetContainerItemID(bag, bagSlot)
	if not itemid then
		return
	end
	
	if (not MULTIBARS_BUFF_FOOD_ITEMS[itemid] and not MULTIBARS_FOOD_ITEMS[itemid]) or MultiBars:IsBlacklistItem(itemid) or addedItems[itemid] or (not buffFood and MULTIBARS_BUFF_FOOD_ITEMS[itemid]) or (not regularFood and MULTIBARS_FOOD_ITEMS[itemid]) then
		return
	end
	
	local itemName, _, _, _, _, itemType, _, _, itemEquipLoc, itemIcon = GetItemInfo(itemid)
	
	addedItems[itemid] = true
	
	MultiBars_AddBarAction(self, actions, {actionType = "item", action = itemName, item = itemid, texture = itemIcon})
end

local function MultiBars_GetMacroSlot(name, general)
	local n
	if not general then
		for n = 121, 138 do
			local macroName = GetMacroInfo(n)
			if macroName and macroName == name then
				return n
			end
		end
	end
	
	for n = 1, 120 do
		local macroName = GetMacroInfo(n)
		if macroName and macroName == name then
			return n
		end
	end
	
	return nil
end

local function MultiBars_AddMacroAction(self, actions, info)
	if not info or not info.name then
		return
	end
	
	local slot = MultiBars_GetMacroSlot(info.name, info.general)
	
	if not slot then
		return
	end
	
	local name, icon = GetMacroInfo(slot)
	
	MultiBars_AddBarAction(self, actions, {actionType = "macro", action = name, slot = slot, general = info.general, texture = icon})
end

function MultiBars_GetAvailableActions(self)
	local actions = {}
	local barName = self:GetName()
	
	if MULTIBARS_CLASS_BARS[barName] and MULTIBARS_CLASS_BARS[barName].spells then
		local info = MULTIBARS_CLASS_BARS[barName]
		local opt = MultiBarsOptions.bars[barName]
		local n
		for n = 1, #info.spells do
			MultiBars_AddClassSpellAction(self, actions, info.spells[n], opt, barName)
		end
	elseif barName == "MultiBarProfession" then
		local i,n
		for i,n in ipairs(MULTIBARS_PROFESSIONS) do
			MultiBars_AddProfessionAction(self, actions, n)
		end
	elseif barName == "MultiBarBuff" then
		local bagNum, slotNum
		local addedItems = {}
		for bag = NUM_BAG_SLOTS, 0, -1 do
			for bagSlot = 1, GetContainerNumSlots(bag) do
				MultiBars_AddFoodItemAction(self, actions, addedItems, bag, bagSlot, true, false)
			end
		end
	elseif barName == "MultiBarConsumable" then
		local bagNum, slotNum
		local addedItems = {}
		for bag = NUM_BAG_SLOTS, 0, -1 do
			for bagSlot = 1, GetContainerNumSlots(bag) do
				MultiBars_AddConsumableItemAction(self, actions, addedItems, bag, bagSlot)
			end
		end
	elseif barName == "MultiBarFeedPet" then
		local includeBuffFood = MultiBarsOptions.bars.MultiBarFeedPet.includeBuffFood
		local bagNum, slotNum
		local addedItems = {}
		for bag = NUM_BAG_SLOTS, 0, -1 do
			for bagSlot = 1, GetContainerNumSlots(bag) do
				MultiBars_AddFeedPetItemAction(self, actions, addedItems, bag, bagSlot, includeBuffFood, true)
			end
		end
	elseif barName == "MultiBarFood" then
		local includeBuffFood = MultiBarsOptions.bars.MultiBarFood.includeBuffFood
		local bagNum, slotNum
		local addedItems = {}
		for bag = NUM_BAG_SLOTS, 0, -1 do
			for bagSlot = 1, GetContainerNumSlots(bag) do
				MultiBars_AddFoodItemAction(self, actions, addedItems, bag, bagSlot, includeBuffFood, true)
			end
		end
	elseif barName == "MultiBarMacro" then
		local macro
		for macro = 1, #MultiBarsOptions.macros do
			MultiBars_AddMacroAction(self, actions, MultiBarsOptions.macros[macro])
		end
	end
	
	if #actions > 0 and MultiBarsOptions.bars[barName].reversed then
		local a, n, r = #actions, 1, {}
		for n = 1, #actions do
			r[n] = actions[a]
			a = a - 1
		end
		actions = r
	end
	
	return actions
end

function MultiBars:UpdateActions()
	if MULTIBARS_DEBUG_VERBOSE then
		MultiBars:Print("MultiBars:UpdateActions()")
	end
	
	if not MultiBars.bars then
		return
	end
	
	if InCombatLockdown() then
		MultiBars.needsPostCombatUpdate = true
		return
	end
	
	local name, bar
	for name, bar in pairs(MultiBars.bars) do
		bar.maxButtons = MultiBarsOptions.bars[name].maxButtons
		MultiBarsCore_Bar_UpdateActions(bar)
	end
end

function MultiBars_UpdateVisibility()
	MultiBars:UpdateVisibility()
end

function MultiBars:UpdateVisibility()
	if MULTIBARS_DEBUG_VERBOSE then
		MultiBars:Print("MultiBars:UpdateVisibility()")
	end
	
	if not MultiBars.bars then
		return
	end
	
	if InCombatLockdown() then
		MultiBars.needsPostCombatVisibility = true
		return
	end
	
	-- first hide the bars, because some may not be included in any of the groups
	local k,v
	for k, v in pairs(MultiBars.bars) do
		MultiBarsCore_Bar_SetVisible(v, false)
	end
	
	local groupNum, groupOptions
	for groupNum, groupOptions in ipairs(MultiBarsOptions.groups) do
		local scale = groupOptions.scale or 1
		if not (scale > 0) then
			scale = 1
		end
		
		local _, barName
		for _, barName in ipairs(groupOptions.bars) do
			current = MultiBars.bars[barName]
			
			current:ClearAllPoints()
			current:SetScale(scale)
			MultiBarsCore_Bar_SetOrientation(current, vertical)
			
			if current.buttonActions and #current.buttonActions > 0 then
				MultiBarsCore_Bar_SetVisible(current, true, groupOptions.nopet, groupOptions.nocombat)
			end
		end
	end
end

function MultiBars:ResetBlizzardContainerOffset()
	UIPARENT_MANAGED_FRAME_POSITIONS["CONTAINER_OFFSET_X"].baseX = 0
	UIPARENT_MANAGED_FRAME_POSITIONS["CONTAINER_OFFSET_Y"].baseY = 70
end

function MultiBars_LayoutBars()
	MultiBars:LayoutBars()
end

-- Note: it's important not to call UIParent_ManageFramePositions from here, because
-- we've hooked that function to invoke LayoutBars
function MultiBars:LayoutBars()
	if MULTIBARS_DEBUG_VERBOSE then
		MultiBars:Print("MultiBars:LayoutBars()")
	end
	
	if not MultiBars.bars then
		return
	end
	
	if InCombatLockdown() then
		MultiBars.needsPostCombatLayout = true
		return
	end
	
	-- first hide the bars, because some bars may not be included in any of the groups
	local k,v
	for k, v in pairs(MultiBars.bars) do
		MultiBarsCore_Bar_SetVisible(v, false)
	end
	
	local leftAnchor, rightAnchor, verticalAnchor
	local baselefty, baserighty, leftx, lefty, rightx, righty = -8, -8, 0, 0, 0, 0
	local topx, topy, bottomx, bottomy, basex = 0, 0, 0, 0, -1
	
	-- handle moving up/down based on the XP+rep bars taking up vertical space
	local numWatchBars = (ReputationWatchBar:IsShown() and 1 or 0) + (MainMenuExpBar:IsShown() and 1 or 0)
	baserighty = baserighty + numWatchBars * 9
	-- there's some special spacing Blizzard adds for max level characters
	local maxLevelBar = MainMenuBarMaxLevelBar:IsShown()
	baserighty = baserighty + (maxLevelBar and 5 or 0)
	
	if MultiBarsOptions.adjustGroupsForPetBar then
		baselefty = baselefty + 34
	end
	
	if StanceBarFrame and StanceBarFrame:IsShown() then
		leftAnchor = StanceBarFrame
		baselefty = baselefty + 6
	else
		leftAnchor = MainMenuBar
		baselefty = baselefty + numWatchBars * 9
		baselefty = baselefty + (maxLevelBar and 5 or 0)
		if SHOW_MULTI_ACTIONBAR_1 then
			baselefty = baselefty + 40
		end
	end
	
	rightAnchor = MainMenuBar
	if SHOW_MULTI_ACTIONBAR_2 then
		baserighty = baserighty + 40
	end
	
	if SHOW_MULTI_ACTIONBAR_4 then
		verticalAnchor = MultiBarLeft
	elseif SHOW_MULTI_ACTIONBAR_3 then
		verticalAnchor = MultiBarRight
	end
	
	local groupNum, groupOptions
	for groupNum, groupOptions in ipairs(MultiBarsOptions.groups) do
		local scale = groupOptions.scale or 1
		if not (scale > 0) then
			scale = 1
		end
		local alignment = groupOptions.alignment
		local vertical = alignment == "top" or alignment == "bottom" or alignment == "unlockedv"
		local offset = groupOptions.offset
		
		local previous, current, i
		local _, barName
		for _, barName in ipairs(groupOptions.bars) do
			current = MultiBars.bars[barName]
			
			current:ClearAllPoints()
			current:SetScale(scale)
			MultiBarsCore_Bar_SetOrientation(current, vertical)
			
			if current.buttonActions and #current.buttonActions > 0 then
				MultiBarsCore_Bar_SetVisible(current, true, groupOptions.nopet, groupOptions.nocombat)
				
				if not previous then
					if alignment == "left" then
						current:SetPoint("BOTTOMLEFT", leftAnchor, "TOPLEFT", (leftx + offset.x) / scale, (baselefty + lefty + offset.y) / scale)
						leftx = leftx + offset.x
						lefty = lefty + 42 * scale + offset.y
					elseif alignment == "right" then
						current:SetPoint("BOTTOMRIGHT", rightAnchor, "TOPRIGHT", (rightx + offset.x) / scale, (baserighty + righty + offset.y) / scale)
						rightx = rightx + offset.x
						righty = righty + 42 * scale + offset.y
					elseif alignment == "top" then
						if verticalAnchor then
							current:SetPoint("TOPRIGHT", verticalAnchor, "TOPLEFT", (basex - topx + offset.x) / scale, (topy + offset.y) / scale)
						else
							current:SetPoint("TOPRIGHT", MinimapCluster, "BOTTOMRIGHT", (basex - topx + offset.x) / scale, (topy + offset.y) / scale)
						end
						topx = topx + 42 * scale - offset.x
						topy = topy + offset.y
					elseif alignment == "bottom" then
						if verticalAnchor then
							current:SetPoint("BOTTOMRIGHT", verticalAnchor, "BOTTOMLEFT", (basex - bottomx + offset.x) / scale, (bottomy + offset.y) / scale)
						else
							current:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", (basex - bottomx + offset.x) / scale, (bottomy + offset.y) / scale)
						end
						bottomx = bottomx + 42 * scale - offset.x
						bottomy = bottomy + offset.y
					else
						current:SetPoint("CENTER", UIParent, "CENTER", offset.x / scale, offset.y / scale)
					end
				else
					if alignment == "left" then
						current:SetPoint("LEFT", previous, "RIGHT", 0, 0)
					elseif alignment == "right" or alignment == "unlockedv" then
						current:SetPoint("RIGHT", previous, "LEFT", 0, 0)
					elseif alignment == "top" then
						current:SetPoint("TOP", previous, "BOTTOM", 0, 0)
					else
						-- Used for alignment == "bottom" and alignment == "unlocked"
						current:SetPoint("BOTTOM", previous, "TOP", 0, 0)
					end
				end
				previous = current
			end
		end
	end
	
	if MultiBarsOptions.adjustContainerOffset then
		-- hack into the UIParent data to cause the vanilla UI to adjust its layout
		-- (see: UIParent.lua in the Blizzard UI)
		if UIPARENT_MANAGED_FRAME_POSITIONS then
			local petOffset = 0
			if (PetActionBarFrame and PetActionBarFrame:IsShown()) or (StanceBarFrame and StanceBarFrame:IsShown()) or (MultiCastActionBarFrame and MultiCastActionBarFrame:IsShown()) or (PossessBarFrame and PossessBarFrame:IsShown()) or (MainMenuBarVehicleLeaveButton and MainMenuBarVehicleLeaveButton:IsShown()) then
				petOffset = 35
			end
			local offsetx, offsety = topx, righty
			if bottomx > topx then
				offsetx = bottomx
			end
			offsety = offsety + 35 + baserighty - numWatchBars * 9 - (maxLevelBar and 10 or 0) - petOffset
			UIPARENT_MANAGED_FRAME_POSITIONS["CONTAINER_OFFSET_X"].baseX = offsetx
			UIPARENT_MANAGED_FRAME_POSITIONS["CONTAINER_OFFSET_Y"].baseY = offsety
		end
	end
end

function MultiBars:UpdateVisuals()
	local name, bar
	for name, bar in pairs(MultiBars.bars) do
		local color = MultiBarsOptions.bars[name].color
		MultiBarsCore_Bar_SetBorderColor(bar, color)
	end
end

function MultiBars:UpdateBags()
	if not MultiBars.ready then
		return
	end
	if not self.itemCounts then
		self.itemCounts = {}
	end
	if not self.itemCountsByName then
		self.itemCountsByName = {}
	end
	wipe(self.itemCounts)
	wipe(self.itemCountsByName)
	
	for bag = NUM_BAG_SLOTS, 0, -1 do
		for bagSlot = 1, GetContainerNumSlots(bag) do
			local itemid = GetContainerItemID(bag, bagSlot)
			if itemid and not self.itemCounts[itemid] then
				local itemName, _, _, _, _, _, _, stackSize = GetItemInfo(itemid)
				local count = GetItemCount(itemid)
				if itemName then
					-- the first calls after starting the game return nil for itemName, and
					-- it seems like there's nothing that can be done about it...
					self.itemCountsByName[itemName] = count
				end
				if stackSize and stackSize > 1 and count and count > 0 then
					self.itemCounts[itemid] = count
				end
			end
		end
	end
	
	local bar
	for _, bar in pairs(MultiBars.bars) do
		bar.itemCounts = self.itemCounts
		bar.itemCountsByName = self.itemCountsByName
	end
end

function MultiBars:UpdateBindings()
	MultiBarsCore_Bar_UpdateBindings(MultiBarAspect)
	MultiBarsCore_Bar_UpdateBindings(MultiBarCurse)
	MultiBarsCore_Bar_UpdateBindings(MultiBarMacro)
	MultiBarsCore_Bar_UpdateBindings(MultiBarSeal)
	MultiBarsCore_Bar_UpdateBindings(MultiBarTrap)
end

local MultiBarsResetConfirmation = "MultiBarsResetConfirmation"
StaticPopupDialogs[MultiBarsResetConfirmation] = {
	text = "Are you sure you want to reset MultiBars settings?",
	button1 = "Yes",
	button2 = "No",
	OnAccept = function()
		MultiBars:ResetSettings()
		UIParent_ManageFramePositions()
	end,
	timeout = 30,
	whileDead = true,
	hideOnEscape = true,
}

function MultiBars:ShowResetSettingsConfirmation()
	StaticPopup_Show(MultiBarsResetConfirmation)
end

function MultiBars:ResetSettings()
	wipe(MultiBarsOptions)
	MultiBars_copyMissing(MultiBarsOptionsDefaults, MultiBarsOptions)
	MultiBars:OnFirstStart()
	MultiBars:UpdateBags()
	MultiBars:UpdateVisuals()
	MultiBars:UpdateActions()
	MultiBars:LayoutBars()
end

function MultiBars:OnFirstStart()
	if not MultiBarsOptions.startedBefore then
		MultiBarsOptions.startedBefore = true
		
		local playerClass = UnitClassBase("player")
		local groupOptions
		for _, groupOptions in ipairs(MultiBarsOptions.groups) do
			wipe(groupOptions.bars)
			if playerClass == "HUNTER" or playerClass == "WARLOCK" then
				groupOptions.nopet = false
			end
		end
		if playerClass == "DRUID" then
			MultiBarsOptions.groups[1].alignment = "left"
			MultiBarsOptions.groups[1].bars[1] = "MultiBarDruid"
			MultiBarsOptions.groups[2].alignment = "right"
			MultiBarsOptions.groups[2].bars[1] = "MultiBarConsumable"
			MultiBarsOptions.groups[2].bars[2] = "MultiBarBuff"
			MultiBarsOptions.groups[2].bars[3] = "MultiBarFood"
		elseif playerClass == "HUNTER" then
			MultiBarsOptions.adjustGroupsForPetBar = true
			MultiBarsOptions.groups[1].alignment = "left"
			MultiBarsOptions.groups[1].bars[1] = "MultiBarAspect"
			MultiBarsOptions.groups[1].bars[2] = "MultiBarTrap"
			MultiBarsOptions.groups[1].bars[3] = "MultiBarHunterPet"
			MultiBarsOptions.groups[1].bars[4] = "MultiBarFeedPet"
			MultiBarsOptions.groups[2].alignment = "right"
			MultiBarsOptions.groups[2].bars[1] = "MultiBarConsumable"
			MultiBarsOptions.groups[2].bars[2] = "MultiBarBuff"
			MultiBarsOptions.groups[2].bars[3] = "MultiBarFood"
		elseif playerClass == "MAGE" then
			MultiBarsOptions.groups[1].alignment = "left"
			MultiBarsOptions.groups[1].bars[1] = "MultiBarMageArmor"
			MultiBarsOptions.groups[1].bars[2] = "MultiBarMageBuff"
			MultiBarsOptions.groups[2].alignment = "right"
			MultiBarsOptions.groups[2].bars[1] = "MultiBarConsumable"
			MultiBarsOptions.groups[2].bars[2] = "MultiBarBuff"
			MultiBarsOptions.groups[2].bars[3] = "MultiBarFood"
			MultiBarsOptions.groups[4].alignment = "right"
			MultiBarsOptions.groups[4].bars[1] = "MultiBarMagePortal"
		elseif playerClass == "PALADIN" then
			MultiBarsOptions.groups[1].alignment = "left"
			MultiBarsOptions.groups[1].bars[1] = "MultiBarSeal"
			MultiBarsOptions.groups[1].bars[2] = "MultiBarBlessing"
			MultiBarsOptions.groups[2].alignment = "top"
			MultiBarsOptions.groups[2].bars[1] = "MultiBarConsumable"
			MultiBarsOptions.groups[2].bars[2] = "MultiBarBuff"
			MultiBarsOptions.groups[2].bars[3] = "MultiBarFood"
		elseif playerClass == "PRIEST" then
			MultiBarsOptions.groups[1].alignment = "left"
			MultiBarsOptions.groups[1].bars[1] = "MultiBarPriest"
			MultiBarsOptions.groups[2].alignment = "right"
			MultiBarsOptions.groups[2].bars[1] = "MultiBarConsumable"
			MultiBarsOptions.groups[2].bars[2] = "MultiBarBuff"
			MultiBarsOptions.groups[2].bars[3] = "MultiBarFood"
		elseif playerClass == "WARLOCK" then
			MultiBarsOptions.adjustGroupsForPetBar = true
			MultiBarsOptions.groups[1].alignment = "left"
			MultiBarsOptions.groups[1].bars[1] = "MultiBarCurse"
			MultiBarsOptions.groups[1].bars[2] = "MultiBarDemon"
			MultiBarsOptions.groups[2].alignment = "right"
			MultiBarsOptions.groups[2].bars[1] = "MultiBarConsumable"
			MultiBarsOptions.groups[2].bars[2] = "MultiBarBuff"
			MultiBarsOptions.groups[2].bars[3] = "MultiBarFood"
		else
			MultiBarsOptions.groups[1].alignment = "right"
			MultiBarsOptions.groups[1].bars[1] = "MultiBarConsumable"
			MultiBarsOptions.groups[1].bars[1] = "MultiBarBuff"
			MultiBarsOptions.groups[1].bars[2] = "MultiBarFood"
		end
		MultiBarsOptions.groups[3].alignment = "top"
		MultiBarsOptions.groups[3].bars[1] = "MultiBarProfession"
	end
end

function MultiBars:OnEvent(event, arg1, ...)
	local oldDebug = MULTIBARS_DEBUG
	if UNLOGGED_EVENTS[event] then
		MULTIBARS_DEBUG = false
	elseif LOGGED_EVENTS[event] then
		MULTIBARS_DEBUG = true
	end
	if MULTIBARS_DEBUG then
		MultiBars:Print("MultiBars:OnEvent(" .. event .. ") " .. tostring(NotNull(MultiBars.ready)))
	end
	
	-- Ignore all the events that happen before the UI's initialization is done
	-- Specifically, for example, BAG_UPDATE is called numerous times without bags being ready yet
	if not MultiBars.ready then
		if event == "PLAYER_ENTERING_WORLD" then
			MultiBars.ready = true
			hooksecurefunc("UIParent_ManageFramePositions", MultiBars_LayoutBars)
		else
			MULTIBARS_DEBUG = oldDebug
			return
		end
	end
	
	if event == "PLAYER_ENTERING_WORLD" then
		MultiBars:UpdateBags()
		MultiBars:UpdateVisuals()
		MultiBars:UpdateActions()
		MultiBars:LayoutBars()
		MultiBars:UpdateBindings()
	elseif event == "BAG_UPDATE" then
		MultiBars:UpdateBags()
		MultiBars:UpdateVisuals()
		MultiBars:UpdateActions()
		MultiBars:LayoutBars()
	elseif event == "LEARNED_SPELL_IN_TAB" or event == "UPDATE_MACROS" then
		MultiBars:UpdateVisuals()
		MultiBars:UpdateActions()
		MultiBars:LayoutBars()
	elseif event == "UPDATE_BINDINGS" then
		MultiBars:UpdateBindings()
	elseif event == "PLAYER_REGEN_ENABLED" then
		if MultiBars.needsPostCombatUpdate then
			MultiBars.needsPostCombatUpdate = nil
			MultiBars.needsPostCombatLayout = true
			MultiBars:UpdateActions()
		end
		
		if MultiBars.needsPostCombatLayout then
			MultiBars.needsPostCombatLayout = nil
			MultiBars:LayoutBars()
		end
	end
	MULTIBARS_DEBUG = oldDebug
end

function MultiBars:OnChatCommand(input)
	if not MultiBars.optionsPanels then
		return
	end
	
	local category = MultiBars.optionsPanels.optionsPanel
	
	if input then
		input = strlower(input)
		if input == "bar" or input == "bars" then
			category = MultiBars.optionsPanels.barPanel
		elseif input == "layout" then
			category = MultiBars.optionsPanels.layoutPanel
		elseif input == "blacklist" then
			category = MultiBars.optionsPanels.blacklistOptionsPanel
		elseif input == "macro" or input == "macros" then
			category = MultiBars.optionsPanels.macroOptionsPanel
		elseif input == "reset" then
			MultiBars:ShowResetSettingsConfirmation()
			return
		end
	end
	
	if not category then
		category = MultiBars.optionsPanels.optionsPanel
		if not category then
			return
		end
	end
	
	-- this function has to be invoked twice due to a Blizzard bug
	InterfaceOptionsFrame_OpenToCategory(category)
	InterfaceOptionsFrame_OpenToCategory(category)
end

function MultiBars:OnInitialize()
	if MULTIBARS_DEBUG then
		MultiBars:Print("MultiBars:OnInitialize()")
	end
	
	MultiBars:Print(NotNull(GetAddOnMetadata("MultiBars", "Version")))
	
	MultiBars.bars = {}
	local n
	for n, _ in pairs(MultiBarsOptionsDefaults.bars) do
		MultiBars.bars[n] = _G[n]
	end
	
	-- Fill in any missing options in the table
	MultiBars_copyMissing(MultiBarsGlobalOptionsDefaults, MultiBarsGlobalOptions)
	MultiBars_copyMissing(MultiBarsOptionsDefaults, MultiBarsOptions)
	MultiBars:OnFirstStart()
	
	self:RegisterEvent("BAG_UPDATE", "OnEvent")
	self:RegisterEvent("LEARNED_SPELL_IN_TAB", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("UPDATE_BINDINGS", "OnEvent")
	self:RegisterEvent("UPDATE_MACROS", "OnEvent")
	
	MultiBarsConfig_RegisterOptions(MultiBars, AceConfig, AceConfigDialog)
	
	MultiBars:RegisterChatCommand("mb", "OnChatCommand")
end

function MultiBars:OnEnable()
	if MULTIBARS_DEBUG then
		MultiBars:Print("MultiBars:OnEnable()")
	end
end
