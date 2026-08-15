local var_0_0 = class("FlappyBirdSkillTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.buff_ = {}
	arg_1_0.buffScale_ = {}
	arg_1_0.buffOffset_ = {}
	arg_1_0.buffTime_ = {}
	arg_1_0.skillCD_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.buttonPic_ = {}

	import("app.common.tables.TableParser").parse("activity_flappy_skill.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.skill_id)

		arg_1_0.name_[var_2_0] = arg_2_0.skill_name
		arg_1_0.desc_[var_2_0] = arg_2_0.skill_desc
		arg_1_0.buff_[var_2_0] = arg_2_0.buff
		arg_1_0.buffScale_[var_2_0] = xyd.splitToNumber(arg_2_0.buff_scale, "|")
		arg_1_0.buffOffset_[var_2_0] = xyd.splitToNumber(arg_2_0.buff_shift, "|")
		arg_1_0.buffTime_[var_2_0] = tonumber(arg_2_0.buff_time)
		arg_1_0.skillCD_[var_2_0] = tonumber(arg_2_0.skill_cd)
		arg_1_0.icon_[var_2_0] = arg_2_0.skill_icon
		arg_1_0.buttonPic_[var_2_0] = arg_2_0.skill_button
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1]
end

function var_0_0.desc(arg_4_0, arg_4_1)
	return arg_4_0.desc_[arg_4_1]
end

function var_0_0.buff(arg_5_0, arg_5_1)
	return arg_5_0.buff_[arg_5_1]
end

function var_0_0.buffScale(arg_6_0, arg_6_1)
	return arg_6_0.buffScale_[arg_6_1]
end

function var_0_0.buffOffset(arg_7_0, arg_7_1)
	return arg_7_0.buffOffset_[arg_7_1]
end

function var_0_0.buffTime(arg_8_0, arg_8_1)
	return arg_8_0.buffTime_[arg_8_1]
end

function var_0_0.skillCD(arg_9_0, arg_9_1)
	return arg_9_0.skillCD_[arg_9_1]
end

function var_0_0.icon(arg_10_0, arg_10_1)
	return arg_10_0.icon_[arg_10_1]
end

function var_0_0.buttonPic(arg_11_0, arg_11_1)
	return arg_11_0.buttonPic_[arg_11_1]
end

return var_0_0
