local var_0_0 = class("DialogConfigTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.names_ = {}
	arg_1_0.dialogClick_ = {}
	arg_1_0.soundClick_ = {}
	arg_1_0.timeClick_ = {}
	arg_1_0.isDynamic_ = {}
	arg_1_0.dynamicImagePath_ = {}
	arg_1_0.partnerImagePath_ = {}
	arg_1_0.location_ = {}
	arg_1_0.scale_ = {}

	import("app.common.tables.TableParser").parse("dialog_config.lua", function(arg_2_0)
		local var_2_0 = arg_2_0.window_name

		arg_1_0.dialogClick_[var_2_0] = xyd.split(arg_2_0.dialog_click, "|")
		arg_1_0.soundClick_[var_2_0] = xyd.split(arg_2_0.click_sound, "|")
		arg_1_0.timeClick_[var_2_0] = xyd.splitToNumber(arg_2_0.dialog_click_time, "|")
		arg_1_0.isDynamic_[var_2_0] = tonumber(arg_2_0.is_dynamic)
		arg_1_0.dynamicImagePath_[var_2_0] = arg_2_0.dynamic_image
		arg_1_0.partnerImagePath_[var_2_0] = arg_2_0.partner_image
		arg_1_0.location_[var_2_0] = xyd.splitToNumber(arg_2_0.location, "|")
		arg_1_0.scale_[var_2_0] = tonumber(arg_2_0.scailing)
	end)
end

function var_0_0.isDynamic(arg_3_0, arg_3_1)
	return arg_3_0.isDynamic_[arg_3_1]
end

function var_0_0.dialogClick(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_0.dialogClick_[arg_4_1]
	local var_4_1 = arg_4_0.soundClick_[arg_4_1]
	local var_4_2 = arg_4_0.timeClick_[arg_4_1]
	local var_4_3 = math.random(#var_4_0)

	return var_4_0[var_4_3], var_4_1[var_4_3], var_4_2[var_4_3]
end

function var_0_0.dynamicImagePath(arg_5_0, arg_5_1)
	return arg_5_0.dynamicImagePath_[arg_5_1]
end

function var_0_0.location(arg_6_0, arg_6_1)
	return arg_6_0.location_[arg_6_1] or {
		0,
		0
	}
end

function var_0_0.scale(arg_7_0, arg_7_1)
	return arg_7_0.scale_[arg_7_1] or 1
end

return var_0_0
