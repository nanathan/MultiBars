
local ADD_CHARACTER_BLACKLIST = "addCharacterBlacklist"
local ADD_FEED_PET_BLACKLIST = "addFeedPetBlacklist"
local ADD_GLOBAL_BLACKLIST = "addGlobalBlacklist"
local REMOVE_CHARACTER_BLACKLIST = "removeCharacterBlacklist"
local REMOVE_FEED_PET_BLACKLIST = "removeFeedPetBlacklist"
local REMOVE_GLOBAL_BLACKLIST = "removeGlobalBlacklist"

local MultiBars

local function NotNull(value)
	if value == nil then
		return "nil"
	else
		return value
	end
end

local function MultiBarsDropDown_AddCharacterBlacklistItem(self, itemid)
	MultiBars:AddBlacklistItem(itemid, false)
	MultiBars:UpdateActions()
end

local function MultiBarsDropDown_AddFeedPetBlacklistItem(self, itemid)
	MultiBars:AddFeedPetBlacklistItem(itemid)
	MultiBars:UpdateActions()
end

local function MultiBarsDropDown_AddGlobalBlacklistItem(self, itemid)
	MultiBars:AddBlacklistItem(itemid, true)
	MultiBars:UpdateActions()
end

local function MultiBarsDropDown_RemoveCharacterBlacklistItem(self, itemid)
	MultiBars:RemoveBlacklistItem(itemid)
	MultiBars:UpdateActions()
end

local function MultiBarsDropDown_RemoveFeedPetBlacklistItem(self, itemid)
	MultiBars:RemoveFeedPetBlacklistItem(itemid)
	MultiBars:UpdateActions()
end

local function MultiBarsDropDown_RemoveGlobalBlacklistItem(self, itemid)
	MultiBars:RemoveBlacklistItem(itemid)
	MultiBars:UpdateActions()
end

local function MultiBarsDropDown_BlacklistAddMenu(bar, func)
	local info
	
	local i, action
	for i, action in pairs(bar.actions) do
		if action.actionType == "item" and action.item then
			info = Lib_UIDropDownMenu_CreateInfo()
			info.text = action.action
			info.arg1 = action.item
			info.func = func
			info.notCheckable = true
			info.icon = action.texture
			info.noClickSound = not MultiBarsOptions.dropdownSound
			Lib_UIDropDownMenu_AddButton(info, LIB_UIDROPDOWNMENU_MENU_LEVEL)
		elseif action.actionType == "spell-item" and action.item then
			info = Lib_UIDropDownMenu_CreateInfo()
			info.text = action.itemName
			info.arg1 = action.item
			info.func = func
			info.notCheckable = true
			info.icon = action.texture
			info.noClickSound = not MultiBarsOptions.dropdownSound
			Lib_UIDropDownMenu_AddButton(info, LIB_UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
end

local function MultiBarsDropDown_BlacklistRemoveMenu(bar, func, blacklist, bartype)
	local info
	
	local bagNum, slotNum
	local bagItems = {}
	for bag = NUM_BAG_SLOTS, 0, -1 do
		for bagSlot = 1, GetContainerNumSlots(bag) do
			local itemid = GetContainerItemID(bag, bagSlot)
			if itemid then
				if (bartype == "Food" or bartype == "FeedPet") and (MULTIBARS_BUFF_FOOD_ITEMS[itemid] or MULTIBARS_FOOD_ITEMS[itemid]) then
					bagItems[itemid] = true
				elseif bartype == "Consumable" and not (MULTIBARS_BUFF_FOOD_ITEMS[itemid] or MULTIBARS_FOOD_ITEMS[itemid]) then
					bagItems[itemid] = true
				end
			end
		end
	end
	
	local itemid, v
	for itemid, v in pairs(blacklist) do
		if itemid and v and bagItems[itemid] then
			local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemid)
			info = Lib_UIDropDownMenu_CreateInfo()
			info.text = name
			info.arg1 = itemid
			info.icon = icon
			info.func = func
			info.notCheckable = true
			info.noClickSound = not MultiBarsOptions.dropdownSound
			Lib_UIDropDownMenu_AddButton(info, LIB_UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
end

function MultiBarsDropDown_Initialize(frame, level, menuList)
	local info
	local bar = frame:GetParent()
	MultiBars = bar.addon
	
	if (LIB_UIDROPDOWNMENU_MENU_LEVEL or 1) == 1 then
		if bar.bartype == "Buff" or bar.bartype == "Consumable" or bar.bartype == "Food" then
			info = Lib_UIDropDownMenu_CreateInfo()
			info.text = bar.bartype .. " Bar"
			info.isTitle = true
			info.notCheckable = true
			info.notClickable = true
			info.noClickSound = not MultiBarsOptions.dropdownSound
			Lib_UIDropDownMenu_AddButton(info)
			
			info = Lib_UIDropDownMenu_CreateInfo()
			info.text = "Add to Character Blacklist"
			info.value = ADD_CHARACTER_BLACKLIST
			info.notCheckable = true
			info.hasArrow = 1
			info.noClickSound = not MultiBarsOptions.dropdownSound
			Lib_UIDropDownMenu_AddButton(info)
			
			info = Lib_UIDropDownMenu_CreateInfo()
			info.text = "Add to Global Blacklist"
			info.value = ADD_GLOBAL_BLACKLIST
			info.notCheckable = true
			info.hasArrow = 1
			info.noClickSound = not MultiBarsOptions.dropdownSound
			Lib_UIDropDownMenu_AddButton(info)
			
			info = Lib_UIDropDownMenu_CreateInfo()
			info.text = "Remove from Character Blacklist"
			info.value = REMOVE_CHARACTER_BLACKLIST
			info.notCheckable = true
			info.hasArrow = 1
			info.noClickSound = not MultiBarsOptions.dropdownSound
			Lib_UIDropDownMenu_AddButton(info)
			
			info = Lib_UIDropDownMenu_CreateInfo()
			info.text = "Remove from Global Blacklist"
			info.value = REMOVE_GLOBAL_BLACKLIST
			info.notCheckable = true
			info.hasArrow = 1
			info.noClickSound = not MultiBarsOptions.dropdownSound
			Lib_UIDropDownMenu_AddButton(info)
		elseif bar.bartype == "Macro" then
			local barName = bar:GetName()
			
			info = Lib_UIDropDownMenu_CreateInfo()
			info.text = bar.bartype .. " Bar"
			info.isTitle = true
			info.notCheckable = true
			info.notClickable = true
			info.noClickSound = not MultiBarsOptions.dropdownSound
			Lib_UIDropDownMenu_AddButton(info)
			
			info = Lib_UIDropDownMenu_CreateInfo()
			info.text = "Configure Macros"
			info.func = function(self)
				if not IsAddOnLoaded("Blizzard_MacroUI") then
					LoadAddOn("Blizzard_MacroUI")
				end
				if MacroFrame_Show then
					MacroFrame_Show()
				end
			end
			info.noClickSound = not MultiBarsOptions.dropdownSound
			info.notCheckable = true
			Lib_UIDropDownMenu_AddButton(info, LIB_UIDROPDOWNMENU_MENU_LEVEL)
			
			if MultiBars.optionsPanels and MultiBars.optionsPanels.macroOptionsPanel then
				info = Lib_UIDropDownMenu_CreateInfo()
				info.text = "Configure Macro Bar"
				info.arg1 = MultiBars.optionsPanels.macroOptionsPanel
				info.func = function(self, category)
					-- this function has to be invoked twice due to a Blizzard bug
					InterfaceOptionsFrame_OpenToCategory(category)
					InterfaceOptionsFrame_OpenToCategory(category)
				end
				info.notCheckable = true
				info.noClickSound = not MultiBarsOptions.dropdownSound
				Lib_UIDropDownMenu_AddButton(info, LIB_UIDROPDOWNMENU_MENU_LEVEL)
			end
			
		elseif bar.bartype == "FeedPet" then
			info = Lib_UIDropDownMenu_CreateInfo()
			info.text = bar.bartype .. " Bar"
			info.isTitle = true
			info.notCheckable = true
			info.notClickable = true
			info.noClickSound = not MultiBarsOptions.dropdownSound
			Lib_UIDropDownMenu_AddButton(info)
			
			info = Lib_UIDropDownMenu_CreateInfo()
			info.text = "Add to Feed Pet Blacklist"
			info.value = ADD_FEED_PET_BLACKLIST
			info.notCheckable = true
			info.hasArrow = 1
			info.noClickSound = not MultiBarsOptions.dropdownSound
			Lib_UIDropDownMenu_AddButton(info)
			
			info = Lib_UIDropDownMenu_CreateInfo()
			info.text = "Remove from Feed Pet Blacklist"
			info.value = REMOVE_FEED_PET_BLACKLIST
			info.notCheckable = true
			info.hasArrow = 1
			info.noClickSound = not MultiBarsOptions.dropdownSound
			Lib_UIDropDownMenu_AddButton(info)
		elseif bar.actionType == "spell" then
			local barName = bar:GetName()
			
			info = Lib_UIDropDownMenu_CreateInfo()
			info.text = bar.bartype .. " Bar"
			info.isTitle = true
			info.notCheckable = true
			info.notClickable = true
			info.noClickSound = not MultiBarsOptions.dropdownSound
			Lib_UIDropDownMenu_AddButton(info)
			
			if MULTIBARS_CLASS_BARS[barName] and MULTIBARS_CLASS_BARS[barName].hasAlternates then
				info = Lib_UIDropDownMenu_CreateInfo()
				info.text = "Default to Alternates"
				info.arg1 = bar
				info.arg2 = not MultiBarsOptions.bars[barName].useAlternates
				info.func = function(self, bar, value)
					MultiBarsOptions.bars[barName].useAlternates = value
					MultiBars:UpdateActions()
				end
				info.checked = MultiBarsOptions.bars[barName].useAlternates or false
				info.noClickSound = not MultiBarsOptions.dropdownSound
				Lib_UIDropDownMenu_AddButton(info, LIB_UIDROPDOWNMENU_MENU_LEVEL)
				
				info = Lib_UIDropDownMenu_CreateInfo()
				info.text = "Use alt-key"
				info.arg1 = bar
				info.arg2 = not MultiBarsOptions.bars[barName].useModSwitch
				info.func = function(self, bar, value)
					MultiBarsOptions.bars[barName].useModSwitch = value
					MultiBars:UpdateActions()
				end
				info.checked = MultiBarsOptions.bars[barName].useModSwitch or false
				info.noClickSound = not MultiBarsOptions.dropdownSound
				Lib_UIDropDownMenu_AddButton(info, LIB_UIDROPDOWNMENU_MENU_LEVEL)
			end
			
			local hidden = bar:GetHiddenActions()
			local n
			for n = 1, #bar.actions do
				local action = bar.actions[n]
				if action then
					info = Lib_UIDropDownMenu_CreateInfo()
					info.text = action.action
					info.arg1 = bar
					info.arg2 = action.hideId
					info.arg3 = not hidden[action.hideId]
					info.icon = action.texture
					info.func = function(self, bar, hideId, value)
						MultiBarsOptions.bars[barName].hidden[hideId] = value
						MultiBars:UpdateActions()
						MultiBars:LayoutBars()
					end
					info.checked = not hidden[action.hideId]
					info.noClickSound = not MultiBarsOptions.dropdownSound
					Lib_UIDropDownMenu_AddButton(info, LIB_UIDROPDOWNMENU_MENU_LEVEL)
				end
			end
		end
	elseif LIB_UIDROPDOWNMENU_MENU_LEVEL == 2 then
		if LIB_UIDROPDOWNMENU_MENU_VALUE == ADD_CHARACTER_BLACKLIST then
			MultiBarsDropDown_BlacklistAddMenu(bar, MultiBarsDropDown_AddCharacterBlacklistItem)
		elseif LIB_UIDROPDOWNMENU_MENU_VALUE == ADD_FEED_PET_BLACKLIST then
			MultiBarsDropDown_BlacklistAddMenu(bar, MultiBarsDropDown_AddFeedPetBlacklistItem)
		elseif LIB_UIDROPDOWNMENU_MENU_VALUE == ADD_GLOBAL_BLACKLIST then
			MultiBarsDropDown_BlacklistAddMenu(bar, MultiBarsDropDown_AddGlobalBlacklistItem)
		elseif LIB_UIDROPDOWNMENU_MENU_VALUE == REMOVE_CHARACTER_BLACKLIST then
			MultiBarsDropDown_BlacklistRemoveMenu(bar, MultiBarsDropDown_RemoveCharacterBlacklistItem, MultiBarsOptions.blacklist, bar.bartype)
		elseif LIB_UIDROPDOWNMENU_MENU_VALUE == REMOVE_FEED_PET_BLACKLIST then
			MultiBarsDropDown_BlacklistRemoveMenu(bar, MultiBarsDropDown_RemoveFeedPetBlacklistItem, MultiBarsGlobalOptions.feedPetBlacklist, bar.bartype)
		elseif LIB_UIDROPDOWNMENU_MENU_VALUE == REMOVE_GLOBAL_BLACKLIST then
			MultiBarsDropDown_BlacklistRemoveMenu(bar, MultiBarsDropDown_RemoveGlobalBlacklistItem, MultiBarsGlobalOptions.blacklist, bar.bartype)
		end
	end
end
