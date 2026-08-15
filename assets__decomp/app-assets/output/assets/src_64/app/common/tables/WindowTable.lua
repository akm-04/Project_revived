local var_0_0 = class("WindowTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.classNames_ = {}
	arg_1_0.windowTypes_ = {}
	arg_1_0.resources_ = {}
	arg_1_0.layoutTypes_ = {}
	arg_1_0.offsets_ = {}
	arg_1_0.priorities_ = {}
	arg_1_0.openAnimations_ = {}
	arg_1_0.closeAnimations_ = {}
	arg_1_0.dependencies_ = {}
	arg_1_0.childWindowNames_ = {}
	arg_1_0.showBackgrounds_ = {}
	arg_1_0.excepts_ = {}
	arg_1_0.hides_ = {}
	arg_1_0.shows_ = {}
	arg_1_0.sideBySide_ = {}
	arg_1_0.hideBgEffect_ = {}
	arg_1_0.hideTouch_ = {}
	arg_1_0.canTouch_ = {}
	arg_1_0.colorMode_ = {}
	arg_1_0.title_ = {}
	arg_1_0.isAddTheme_ = {}

	import("app.common.tables.TableParser").parse("window.lua", function(arg_2_0)
		local var_2_0 = arg_2_0.win_name

		arg_1_0.classNames_[var_2_0] = arg_2_0.class
		arg_1_0.windowTypes_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.resources_[var_2_0] = arg_2_0.res
		arg_1_0.layoutTypes_[var_2_0] = arg_2_0.layout
		arg_1_0.offsets_[var_2_0] = cc.p(tonumber(arg_2_0.off_x), tonumber(arg_2_0.off_y))
		arg_1_0.priorities_[var_2_0] = tonumber(arg_2_0.priority)
		arg_1_0.openAnimations_[var_2_0] = xyd.parseNumberArray(arg_2_0.open_animation)
		arg_1_0.closeAnimations_[var_2_0] = xyd.parseNumberArray(arg_2_0.close_animation)
		arg_1_0.showBackgrounds_[var_2_0] = tonumber(arg_2_0.show_background)
		arg_1_0.hideBgEffect_[var_2_0] = tonumber(arg_2_0.hide_bg_effect)
		arg_1_0.hideTouch_[var_2_0] = tonumber(arg_2_0.hide_touch)
		arg_1_0.canTouch_[var_2_0] = tonumber(arg_2_0.can_touch)
		arg_1_0.colorMode_[var_2_0] = tonumber(arg_2_0.color_mode)
		arg_1_0.title_[var_2_0] = arg_2_0.wnd_title
		arg_1_0.isAddTheme_[var_2_0] = tonumber(arg_2_0.is_add_theme) or 0

		local var_2_1 = arg_2_0.dependency

		arg_1_0.dependencies_[var_2_0] = var_2_1
		arg_1_0.childWindowNames_[var_2_1] = arg_1_0.childWindowNames_[var_2_1] or {}

		table.insert(arg_1_0.childWindowNames_[var_2_1], var_2_0)

		arg_1_0.excepts_[var_2_0] = {}

		local var_2_2 = arg_1_0:lua_string_split(arg_2_0.except, "|")

		if var_2_2 then
			for iter_2_0, iter_2_1 in pairs(var_2_2) do
				table.insert(arg_1_0.excepts_[var_2_0], iter_2_1)
			end
		end

		arg_1_0.hides_[var_2_0] = {}

		local var_2_3 = arg_1_0:lua_string_split(arg_2_0.hide, "|")

		if var_2_3 then
			for iter_2_2, iter_2_3 in pairs(var_2_3) do
				table.insert(arg_1_0.hides_[var_2_0], iter_2_3)
			end
		end

		arg_1_0.shows_[var_2_0] = {}

		local var_2_4 = arg_1_0:lua_string_split(arg_2_0.show, "|")

		if var_2_4 then
			for iter_2_4, iter_2_5 in pairs(var_2_4) do
				table.insert(arg_1_0.shows_[var_2_0], iter_2_5)
			end
		end

		arg_1_0.sideBySide_[var_2_0] = xyd.split(arg_2_0.side_by_side, "|")
	end)
end

function var_0_0.hasWindow(arg_3_0, arg_3_1)
	return arg_3_0.classNames_[arg_3_1] ~= nil
end

function var_0_0.className(arg_4_0, arg_4_1)
	return arg_4_0.classNames_[arg_4_1]
end

function var_0_0.windowType(arg_5_0, arg_5_1)
	return arg_5_0.windowTypes_[arg_5_1] or 0
end

function var_0_0.resource(arg_6_0, arg_6_1)
	return arg_6_0.resources_[arg_6_1]
end

function var_0_0.layoutType(arg_7_0, arg_7_1)
	return arg_7_0.layoutTypes_[arg_7_1]
end

function var_0_0.offset(arg_8_0, arg_8_1)
	return arg_8_0.offsets_[arg_8_1]
end

function var_0_0.priority(arg_9_0, arg_9_1)
	return arg_9_0.priorities_[arg_9_1]
end

function var_0_0.openAnimations(arg_10_0, arg_10_1)
	return arg_10_0.openAnimations_[arg_10_1] or {}
end

function var_0_0.closeAnimations(arg_11_0, arg_11_1)
	return arg_11_0.closeAnimations_[arg_11_1] or {}
end

function var_0_0.dependency(arg_12_0, arg_12_1)
	return arg_12_0.dependencies_[arg_12_1]
end

function var_0_0.childWindowNames(arg_13_0, arg_13_1)
	return arg_13_0.childWindowNames_[arg_13_1]
end

function var_0_0.showBackground(arg_14_0, arg_14_1)
	return arg_14_0.showBackgrounds_[arg_14_1] ~= 0
end

function var_0_0.exceptNames(arg_15_0, arg_15_1)
	return arg_15_0.excepts_[arg_15_1]
end

function var_0_0.hideNames(arg_16_0, arg_16_1)
	return arg_16_0.hides_[arg_16_1]
end

function var_0_0.showNames(arg_17_0, arg_17_1)
	return arg_17_0.shows_[arg_17_1]
end

function var_0_0.sideBySideNames(arg_18_0, arg_18_1)
	return arg_18_0.sideBySide_[arg_18_1]
end

function var_0_0.lua_string_split(arg_19_0, arg_19_1, arg_19_2)
	if not arg_19_1 then
		return nil
	end

	local var_19_0 = {}

	while true do
		local var_19_1 = string.find(arg_19_1, arg_19_2)

		if not var_19_1 then
			var_19_0[#var_19_0 + 1] = arg_19_1

			break
		end

		local var_19_2 = string.sub(arg_19_1, 1, var_19_1 - 1)

		var_19_0[#var_19_0 + 1] = var_19_2
		arg_19_1 = string.sub(arg_19_1, var_19_1 + 1, #arg_19_1)
	end

	return var_19_0
end

function var_0_0.hideBgEffect(arg_20_0, arg_20_1)
	return arg_20_0.hideBgEffect_[arg_20_1]
end

function var_0_0.hideTouch(arg_21_0, arg_21_1)
	return arg_21_0.hideTouch_[arg_21_1]
end

function var_0_0.canTouch(arg_22_0, arg_22_1)
	return (arg_22_0.canTouch_[arg_22_1] or 0) == 0
end

function var_0_0.colorMode(arg_23_0, arg_23_1)
	return arg_23_0.colorMode_[arg_23_1]
end

function var_0_0.title(arg_24_0, arg_24_1)
	return arg_24_0.title_[arg_24_1] or ""
end

function var_0_0.isAddTheme(arg_25_0, arg_25_1)
	return arg_25_0.isAddTheme_[arg_25_1] or 0
end

return var_0_0
