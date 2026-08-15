local var_0_0 = class("ActivityCvLinkTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.cv_ = {}
	arg_1_0.partnerId_ = {}
	arg_1_0.cvIcon_ = {}
	arg_1_0.sound_ = {}
	arg_1_0.time_ = {}

	import("app.common.tables.TableParser").parse("activity_cv_link.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.partner_id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.cv_[var_2_0] = arg_2_0.cv
		arg_1_0.cvIcon_[var_2_0] = arg_2_0.cv_icon
		arg_1_0.sound_[var_2_0] = arg_2_0.sound
		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.time)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.cv(arg_4_0, arg_4_1)
	return arg_4_0.cv_[arg_4_1] or ""
end

function var_0_0.partnerId(arg_5_0, arg_5_1)
	return arg_5_0.partnerId_[arg_5_1] or 0
end

function var_0_0.cvIcon(arg_6_0, arg_6_1)
	return arg_6_0.cvIcon_[arg_6_1] or ""
end

function var_0_0.sound(arg_7_0, arg_7_1)
	return arg_7_0.sound_[arg_7_1] or ""
end

function var_0_0.time(arg_8_0, arg_8_1)
	return arg_8_0.time_[arg_8_1] or 0
end

return var_0_0
