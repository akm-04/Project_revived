local var_0_0 = class("SystemColorTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.descs_ = {}
	arg_1_0.bgSources_ = {}
	arg_1_0.btnColors_ = {}
	arg_1_0.btnImgs_ = {}
	arg_1_0.alertBG_ = {}
	arg_1_0.middleBG_ = {}

	import("app.common.tables.TableParser").parse("system_color.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.descs_ = arg_2_0.desc
		arg_1_0.bgSources_[var_2_0] = xyd.split(arg_2_0.bg_source)
		arg_1_0.btnColors_[var_2_0] = xyd.split(arg_2_0.btn_color)
		arg_1_0.btnImgs_[var_2_0] = xyd.split(arg_2_0.btn_img)
		arg_1_0.alertBG_[var_2_0] = arg_2_0.alert_img
		arg_1_0.middleBG_[var_2_0] = arg_2_0.middle_img

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.desc(arg_4_0, arg_4_1)
	return arg_4_0.descs_[arg_4_1]
end

function var_0_0.bgSources(arg_5_0, arg_5_1)
	return arg_5_0.bgSources_[arg_5_1]
end

function var_0_0.btnColors(arg_6_0, arg_6_1)
	return arg_6_0.btnColors_[arg_6_1]
end

function var_0_0.btnImgs(arg_7_0, arg_7_1)
	return arg_7_0.btnImgs_[arg_7_1]
end

function var_0_0.alertBG(arg_8_0, arg_8_1)
	return arg_8_0.alertBG_[arg_8_1]
end

function var_0_0.middleBG(arg_9_0, arg_9_1)
	return arg_9_0.middleBG_[arg_9_1]
end

return var_0_0
