
local AceLocale = LibStub("AceLocale-3.0")

function MultiBarsConfig_MixinConfigFunctions(MultiBars)
	function MultiBars:GetGroupAlignment(group)
		if MultiBarsOptions and MultiBarsOptions.groups and MultiBarsOptions.groups[group].alignment then
			return MultiBarsOptions.groups[group].alignment
		end
		return "left"
	end
	
	function MultiBars:SetGroupAlignment(group, alignment)
		if MultiBarsOptions.groups[group] and (alignment == "left" or alignment == "right" or alignment == "top" or alignment == "bottom" or alignment == "unlocked" or alignment == "unlockedv") then
			MultiBarsOptions.groups[group].alignment = alignment
		end
	end
	
	function MultiBars:GetBarGroup(bar)
		if MultiBarsOptions and MultiBarsOptions.groups then
			local i, group
			for i, group in ipairs(MultiBarsOptions.groups) do
				if group.bars then
					local _, v
					for _, v in ipairs(group.bars) do
						if v == bar then
							return i
						end
					end
				end
			end
		end
		return 0
	end
	
	function MultiBars:SetBarGroup(barName, groupNumber)
		local i, group
		for i, group in ipairs(MultiBarsOptions.groups) do
			if i == groupNumber then
				-- for the matching group: add the bar if it's missing
				if not tContains(group.bars, barName) then
					tinsert(group.bars, barName)
				end
			else
				-- for the rest of the groups: remove the bar if it's present
				local index
				local n, bn
				-- find the index of the bar within the group
				for i, bn in ipairs(group.bars) do
					if bn == barName then
						index = i
					end
				end
				-- remove the bar, if the index was found
				if index then
					tremove(group.bars, index)
				end
			end
		end
	end
	
	function MultiBars:AddBlacklistItem(itemid, global)
		local options = MultiBarsOptions
		if global then
			options = MultiBarsGlobalOptions
		end
		if itemid then
			options.blacklist[itemid] = true
		end
	end
	
	function MultiBars:IsBlacklistItem(itemid)
		if itemid then
			return MultiBarsOptions.blacklist[itemid] or MultiBarsGlobalOptions.blacklist[itemid]
		end
		return false
	end
	
	function MultiBars:RemoveBlacklistItem(itemid, global)
		if itemid then
			if global == true then
				MultiBarsGlobalOptions.blacklist[itemid] = nil
			elseif global == false then
				MultiBarsOptions.blacklist[itemid] = nil
			else
				MultiBarsGlobalOptions.blacklist[itemid] = nil
				MultiBarsOptions.blacklist[itemid] = nil
			end
		end
	end
	
	function MultiBars:GetBlacklistString(global)
		local options = MultiBarsOptions
		if global then
			options = MultiBarsGlobalOptions
		end
		local blacklistString = ""
		local count = 0
		local i, v
		for i, v in pairs(options.blacklist) do
			if v then
				if count > 0 then
					blacklistString = blacklistString .. "," .. i
				else
					blacklistString = tostring(i)
				end
				count = count + 1
			end
		end
		return blacklistString
	end
	
	function MultiBars:SetBlacklistString(blacklistString, global)
		local options = MultiBarsOptions
		if global then
			options = MultiBarsGlobalOptions
		end
		wipe(options.blacklist)
		if blacklistString then
			local k, v
			for k, v in string.gmatch(blacklistString, "(%d+)(%D*)") do
				local itemid = tonumber(k)
				if itemid then
					options.blacklist[itemid] = true
				end
			end
		end
	end
	
	function MultiBars:AddFeedPetBlacklistItem(itemid)
		if itemid then
			MultiBarsGlobalOptions.feedPetBlacklist[itemid] = true
		end
	end
	
	function MultiBars:IsFeedPetBlacklistItem(itemid)
		if itemid then
			return MultiBarsGlobalOptions.feedPetBlacklist[itemid]
		end
		return false
	end
	
	function MultiBars:RemoveFeedPetBlacklistItem(itemid)
		if itemid then
			MultiBarsGlobalOptions.feedPetBlacklist[itemid] = nil
		end
	end
	
	-- does not return nil
	function MultiBars:IsMacroGeneral(buttonNumber)
		return MultiBarsOptions.macros[buttonNumber].general or false
	end
	
	function MultiBars:SetMacroGeneral(buttonNumber, general)
		if general then
			MultiBarsOptions.macros[buttonNumber].general = true
		else
			MultiBarsOptions.macros[buttonNumber].general = nil
		end
	end
	
	-- Returns a macro name or nil
	function MultiBars:GetMacroName(buttonNumber)
		return MultiBarsOptions.macros[buttonNumber].name
	end
	
	function MultiBars:SetMacroName(buttonNumber, macroName)
		local name = macroName
		if not macroName or strlen(macroName) == 0 then
			name = nil
		end
		MultiBarsOptions.macros[buttonNumber].name = name
	end
end

local function MultiBarsConfig_CreateBaseOptions(MultiBars)
	local options = {
		name = "MultiBars",
		handler = MultiBars,
		type = 'group',
		args = {
			text = {
				type = 'description',
				order = 2,
				name = GetAddOnMetadata("MultiBars", "Notes") or "",
			},
			version = {
				type = 'description',
				order = 3,
				name = GetAddOnMetadata("MultiBars", "Version") or "",
			},
			dropdownSound = {
				type = 'toggle',
				order = 4,
				name = "Dropdown Sounds",
				desc = "Enables/Disables click sounds on the dropdown menus",
				width = "full",
				get = function(info) return MultiBarsOptions.dropdownSound end,
				set = function(info, value)
					MultiBarsOptions.dropdownSound = value
				end,
			},
			noManagedContainerOffsetMod = {
				type = 'toggle',
				order = 5,
				name = "Auto-adjust Blizzard Bag & Quest Tracker positions",
				desc = "Adjusts default Blizzard UI elements so the MultiBars don't cover them",
				width = "full",
				get = function(info) return MultiBarsOptions.adjustContainerOffset end,
				set = function(info, value)
					MultiBarsOptions.adjustContainerOffset = value
					if value then
						MultiBars:LayoutBars()
					else
						MultiBars:ResetBlizzardContainerOffset()
					end
					UIParent_ManageFramePositions()
				end,
			},
			reset = {
				type = 'execute',
				order = 25,
				name = "Reset Settings",
				func = function(info)
					MultiBars:ResetSettings()
					UIParent_ManageFramePositions()
				end,
			}
		},
	}
	
	return options
end

local function MultiBarsConfig_CreateSingleBarOptions(MultiBars, options, barName, n)
	local L = AceLocale:GetLocale("MultiBars", true)
	options.args[barName] = {
		type = 'group',
		order = n,
		name = L[barName],
		inline = true,
		args = {
			color = {
				type = 'color',
				order = 1,
				name = "Border Color",
				desc = "",
				hasAlpha = false,
				get = function(info) return unpack(MultiBarsOptions.bars[barName].color) end,
				set = function(info, r, g, b, a)
					MultiBarsOptions.bars[barName].color = { r, g, b, a }
					MultiBars:UpdateVisuals()
				end,
			},
			reversed = {
				type = 'toggle',
				order = 2,
				name = "Reverse Button Order",
				desc = "",
				get = function(info) return MultiBarsOptions.bars[barName].reversed end,
				set = function(info, value)
					MultiBarsOptions.bars[barName].reversed = value
					MultiBars:UpdateActions()
				end,
			},
		}
	}
	
	local nextOrder = 3
	
	if barName == "MultiBarFood" then
		options.args[barName].args.includeBuffFood = {
			type = 'toggle',
			order = nextOrder,
			name = "Include Buff Food",
			desc = "Whether to also include buttons for buff food items on this bar",
			get = function(info) return MultiBarsOptions.bars[barName].includeBuffFood end,
			set = function(info, value)
				MultiBarsOptions.bars[barName].includeBuffFood = value
				MultiBars:UpdateActions()
			end,
		}
		nextOrder = nextOrder + 1
	end
	
	if MULTIBARS_CLASS_BARS[barName] and MULTIBARS_CLASS_BARS[barName].hasAlternates then
		options.args[barName].args.useAlternates = {
			type = 'toggle',
			order = nextOrder,
			name = "Default to Alternates",
			desc = "Un-modified clicks will be for the alternate version of the spell (i.e. the group buff instead of single-target version of the spell)",
			get = function(info) return MultiBarsOptions.bars[barName].useAlternates end,
			set = function(info, value)
				MultiBarsOptions.bars[barName].useAlternates = value
				MultiBars:UpdateActions()
			end,
		}
		nextOrder = nextOrder + 1
		
		options.args[barName].args.useModSwitch = {
			type = 'toggle',
			order = nextOrder,
			name = "Use alt-key",
			desc = 'Alt-clicking will cast the other version of the spell (either group or single-target depending on the "Default to Alternates" option)',
			get = function(info) return MultiBarsOptions.bars[barName].useModSwitch end,
			set = function(info, value)
				MultiBarsOptions.bars[barName].useModSwitch = value
				MultiBars:UpdateActions()
			end,
		}
		nextOrder = nextOrder + 1
	end
	
	if _G[barName].actionType == "spell" then
		options.args[barName].args.unhideAll = {
			type = 'execute',
			order = nextOrder,
			name = "Un-Hide All Buttons",
			desc = "Un-hides all previously-hidden buttons for this bar",
			func = function(self)
				wipe(MultiBarsOptions.bars[barName].hidden)
				MultiBars:UpdateActions()
				MultiBars:LayoutBars()
			end,
		}
		nextOrder = nextOrder + 1
	end
end

local function MultiBarsConfig_CreateBarOptions(MultiBars)
	local options = {
		name = "MultiBars Bar Options",
		handler = MultiBars,
		type = 'group',
		args = {
		},
	}
	local _, barName
	local n = 0
	local names = {}
	for barName, _ in pairs(MultiBarsOptions.bars) do
		n = n + 1
		names[n] = barName
	end
	sort(names)
	
	for n = 1, #names do
		barName = names[n]
		local barInfo = MULTIBARS_CLASS_BARS[barName]
		if not barInfo or not barInfo.class or barInfo.class == UnitClassBase("player") then
			MultiBarsConfig_CreateSingleBarOptions(MultiBars, options, barName, n)
		end
	end
	
	return options
end

local function MultiBarsConfig_CreateLayoutGroupOptions(MultiBars, options, n)
	local groupn = "group" .. n
	local L = AceLocale:GetLocale("MultiBars", true)
	options.args[groupn] = {
		type = 'group',
		order = n,
		name = "Layout Group " .. n,
		inline = true,
		args = {
			bars = {
				type = 'multiselect',
				order = 1,
				name = "Included Bars",
				desc = "",
				values = {
					MultiBarBuff = L.MultiBarBuff,
					MultiBarConsumable = L.MultiBarConsumable,
					MultiBarFood = L.MultiBarFood,
					MultiBarMacro = L.MultiBarMacro,
					MultiBarProfession = L.MultiBarProfession,
				},
				get = function(info, key) return MultiBars:GetBarGroup(key) == n end,
				set = function(info, key, value)
					if value then
						MultiBars:SetBarGroup(key, n)
					else
						MultiBars:SetBarGroup(key, 0)
					end
					MultiBars:LayoutBars()
					UIParent_ManageFramePositions()
				end,
			},
			alignment = {
				type = 'select',
				order = 2,
				name = "Alignment",
				desc = "",
				values = {
					left = "Left",
					right = "Right",
					top = "Top",
					bottom = "Bottom",
					unlocked = "Unlocked (horizontal)",
					unlockedv = "Unlocked (vertical)",
				},
				get = function(info) return MultiBars:GetGroupAlignment(n) end,
				set = function(info, value)
					MultiBars:SetGroupAlignment(n, value)
					MultiBars:LayoutBars()
					UIParent_ManageFramePositions()
				end,
				style = "radio",
			},
			scale = {
				type = 'range',
				order = 3,
				name = "Scale",
				desc = "Scales the size of the bars",
				softMin = 0.1,
				softMax = 2,
				bigStep = 0.1,
				get = function(info) return MultiBarsOptions.groups[n].scale end,
				set = function(info, value)
					local s = tonumber(value)
					if s then
						MultiBarsOptions.groups[n].scale = s
						MultiBars:LayoutBars()
						UIParent_ManageFramePositions()
					end
				end,
			},
			offsetX = {
				type = 'range',
				order = 4,
				name = "X Offset",
				desc = "Offset",
				softMin = -100,
				softMax = 100,
				bigStep = 1,
				get = function(info) return MultiBarsOptions.groups[n].offset.x end,
				set = function(info, value)
					local s = tonumber(value)
					if s then
						MultiBarsOptions.groups[n].offset.x = s
						MultiBars:LayoutBars()
						UIParent_ManageFramePositions()
					end
				end,
			},
			offsetY = {
				type = 'range',
				order = 5,
				name = "Y Offset",
				desc = "Offset",
				softMin = -100,
				softMax = 100,
				bigStep = 1,
				get = function(info) return MultiBarsOptions.groups[n].offset.y end,
				set = function(info, value)
					local s = tonumber(value)
					if s then
						MultiBarsOptions.groups[n].offset.y = s
						MultiBars:LayoutBars()
						UIParent_ManageFramePositions()
					end
				end,
			},
			hideWithPet = {
				type = 'toggle',
				order = 6,
				name = "Hide if a pet is out",
				desc = "The bars in this group will be hidden when the player has a pet out",
				get = function(info) return MultiBarsOptions.groups[n].nopet end,
				set = function(info, value)
					MultiBarsOptions.groups[n].nopet = value
					MultiBars:LayoutBars()
					UIParent_ManageFramePositions()
				end,
			},
			hideInCombat = {
				type = 'toggle',
				order = 7,
				name = "Hide in combat",
				desc = "The bars in this group will be hidden when the player is in combat",
				get = function(info) return MultiBarsOptions.groups[n].nocombat end,
				set = function(info, value)
					MultiBarsOptions.groups[n].nocombat = value
					MultiBars:LayoutBars()
					UIParent_ManageFramePositions()
				end,
			},
		}
	}
	
	local playerClass = UnitClassBase("player")
	if playerClass == "DRUID" then
		options.args[groupn].args.bars.values["MultiBarDruid"] = L.MultiBarDruid
	elseif playerClass == "HUNTER" then
		options.args[groupn].args.bars.values["MultiBarAspect"] = L.MultiBarAspect
		options.args[groupn].args.bars.values["MultiBarFeedPet"] = L.MultiBarFeedPet
		options.args[groupn].args.bars.values["MultiBarHunterPet"] = L.MultiBarHunterPet
		options.args[groupn].args.bars.values["MultiBarTrap"] = L.MultiBarTrap
	elseif playerClass == "PALADIN" then
		options.args[groupn].args.bars.values["MultiBarBlessing"] = L.MultiBarBlessing
		options.args[groupn].args.bars.values["MultiBarSeal"] = L.MultiBarSeal
	elseif playerClass == "PRIEST" then
		options.args[groupn].args.bars.values["MultiBarPriest"] = L.MultiBarPriest
	elseif playerClass == "WARLOCK" then
		options.args[groupn].args.bars.values["MultiBarCurse"] = L.MultiBarCurse
		options.args[groupn].args.bars.values["MultiBarDemon"] = L.MultiBarDemon
	end
end

local function MultiBarsConfig_CreateLayoutOptions(MultiBars)
	local options = {
		name = "MultiBars Layout Groups",
		handler = MultiBars,
		type = 'group',
		args = {
		},
	}
	local n
	for n = 1, #MultiBarsOptions.groups do
		MultiBarsConfig_CreateLayoutGroupOptions(MultiBars, options, n)
	end
	
	return options
end

local function MultiBarsConfig_CreateBlacklistOptions(MultiBars)
	local blacklistOptions = {
		name = "MultiBars Item Blacklist",
		handler = MultiBars,
		type = 'group',
		args = {
			characterItems = {
				type = 'input',
				name = "Character-specific Item Blacklist",
				desc = "Items to be blacklisted from appearing for this character",
				width = "full",
				get = function(info) return MultiBars:GetBlacklistString(false) end,
				set = function(info, value)
					MultiBars:SetBlacklistString(value, false)
					MultiBarsCore_Bar_UpdateActions(MultiBarConsumable)
					MultiBarsCore_Bar_UpdateActions(MultiBarFood)
				end,
			},
			globalItems = {
				type = 'input',
				name = "Global Item Blacklist",
				desc = "Items to be blacklisted from appearing for any character",
				width = "full",
				get = function(info) return MultiBars:GetBlacklistString(true) end,
				set = function(info, value)
					MultiBars:SetBlacklistString(value, true)
					MultiBarsCore_Bar_UpdateActions(MultiBarConsumable)
					MultiBarsCore_Bar_UpdateActions(MultiBarFood)
				end,
			},
		},
	}
	
	return blacklistOptions
end

local function MultiBarsConfig_CreateMacroOptions(MultiBars)
	local macroOptions = {
		name = "MultiBars Macros",
		handler = MultiBars,
		type = 'group',
		args = {},
	}
	
	local n
	for n = 1, 12 do
		macroOptions.args["macro" .. n] = {
			type = 'input',
			name = "Macro " .. n,
			desc = "Macro " .. n,
			order = (2 * n) - 1,
			width = "double",
			get = function(info) return MultiBars:GetMacroName(n) or "" end,
			set = function(info, value)
				MultiBars:SetMacroName(n, value)
				MultiBarsCore_Bar_UpdateActions(MultiBarMacro)
				MultiBars:LayoutBars()
				UIParent_ManageFramePositions()
			end,
		}
		macroOptions.args["macro" .. n .. "general"] = {
			type = 'toggle',
			name = "General Macro",
			desc = "Use the named general macro instead of a character-specific macro",
			order = 2 * n,
			get = function(info) return MultiBars:IsMacroGeneral(n) end,
			set = function(info, value)
				MultiBars:SetMacroGeneral(n, value)
				MultiBarsCore_Bar_UpdateActions(MultiBarMacro)
				MultiBars:LayoutBars()
				UIParent_ManageFramePositions()
			end,
		}
	end
	
	return macroOptions
end

function MultiBarsConfig_RegisterOptions(MultiBars, AceConfig, AceConfigDialog)
	local options = MultiBarsConfig_CreateBaseOptions(MultiBars)
	local barOptions = MultiBarsConfig_CreateBarOptions(MultiBars)
	local layoutOptions = MultiBarsConfig_CreateLayoutOptions(MultiBars)
	local blacklistOptions = MultiBarsConfig_CreateBlacklistOptions(MultiBars)
	local macroOptions = MultiBarsConfig_CreateMacroOptions(MultiBars)
	
	AceConfig:RegisterOptionsTable("MultiBars", options)
	AceConfig:RegisterOptionsTable("MultiBarsBar", barOptions)
	AceConfig:RegisterOptionsTable("MultiBarsLayout", layoutOptions)
	AceConfig:RegisterOptionsTable("MultiBarsBlacklist", blacklistOptions)
	AceConfig:RegisterOptionsTable("MultiBarsMacros", macroOptions)
	
	MultiBars.optionsPanels = {
		optionsPanel = AceConfigDialog:AddToBlizOptions("MultiBars", "MultiBars"),
		barPanel = AceConfigDialog:AddToBlizOptions("MultiBarsBar", "Bars", "MultiBars"),
		layoutPanel = AceConfigDialog:AddToBlizOptions("MultiBarsLayout", "Layout", "MultiBars"),
		blacklistOptionsPanel = AceConfigDialog:AddToBlizOptions("MultiBarsBlacklist", "Item Blacklist", "MultiBars"),
		macroOptionsPanel = AceConfigDialog:AddToBlizOptions("MultiBarsMacros", "Macros", "MultiBars"),
	}
end
