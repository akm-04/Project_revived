local var_0_0 = class("FlappyBirdPartnerTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.unlockType_ = {}
	arg_1_0.unlockValue_ = {}
	arg_1_0.unlockDesc_ = {}
	arg_1_0.avatar_ = {}
	arg_1_0.model_ = {}
	arg_1_0.scale_ = {}
	arg_1_0.offset_ = {}
	arg_1_0.collisionSize_ = {}
	arg_1_0.skill_ = {}

	import("app.common.tables.TableParser").parse("activity_flappy_partner.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.unlockType_[var_2_0] = xyd.splitToNumber(arg_2_0.unlock_type, "|")
		arg_1_0.unlockValue_[var_2_0] = xyd.splitToNumber(arg_2_0.unlock_value, "|")
		arg_1_0.unlockDesc_[var_2_0] = arg_2_0.unlock_desc
		arg_1_0.avatar_[var_2_0] = arg_2_0.avatar
		arg_1_0.model_[var_2_0] = arg_2_0.model
		arg_1_0.scale_[var_2_0] = tonumber(arg_2_0.scale)
		arg_1_0.offset_[var_2_0] = xyd.splitToNumber(arg_2_0.center_shift, "|")
		arg_1_0.collisionSize_[var_2_0] = xyd.splitToNumber(arg_2_0.collision_size, "|")
		arg_1_0.skill_[var_2_0] = tonumber(arg_2_0.skill)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1]
end

function var_0_0.unlockType(arg_4_0, arg_4_1)
	return arg_4_0.unlockType_[arg_4_1]
end

function var_0_0.unlockValue(arg_5_0, arg_5_1)
	return arg_5_0.unlockValue_[arg_5_1]
end

function var_0_0.unlockDesc(arg_6_0, arg_6_1)
	return arg_6_0.unlockDesc_[arg_6_1]
end

function var_0_0.avatar(arg_7_0, arg_7_1)
	return arg_7_0.avatar_[arg_7_1]
end

function var_0_0.model(arg_8_0, arg_8_1)
	return arg_8_0.model_[arg_8_1]
end

function var_0_0.scale(arg_9_0, arg_9_1)
	return arg_9_0.scale_[arg_9_1]
end

function var_0_0.offset(arg_10_0, arg_10_1)
	return arg_10_0.offset_[arg_10_1]
end

function var_0_0.collisionSize(arg_11_0, arg_11_1)
	return arg_11_0.collisionSize_[arg_11_1]
end

function var_0_0.skill(arg_12_0, arg_12_1)
	return arg_12_0.skill_[arg_12_1]
end

return var_0_0
