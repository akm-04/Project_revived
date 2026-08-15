local var_0_0 = class("FlappyBirdGiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.level_ = {}
	arg_1_0.score_ = {}
	arg_1_0.normalGift_ = {}
	arg_1_0.numNormal_ = {}
	arg_1_0.specialGift_ = {}
	arg_1_0.numSpecial_ = {}
	arg_1_0.pointLev_ = {}
	arg_1_0.scorePoint_ = {}

	import("app.common.tables.TableParser").parse("activity_flappy_gift.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.level_[var_2_0] = tonumber(arg_2_0.level)
		arg_1_0.score_[var_2_0] = tonumber(arg_2_0.score)
		arg_1_0.normalGift_[var_2_0] = tonumber(arg_2_0.normal_gift)
		arg_1_0.numNormal_[var_2_0] = tonumber(arg_2_0.num_normal)
		arg_1_0.specialGift_[var_2_0] = tonumber(arg_2_0.special_gift)
		arg_1_0.numSpecial_[var_2_0] = tonumber(arg_2_0.num_special)
		arg_1_0.scorePoint_[var_2_0] = tonumber(arg_2_0.score_point)

		if var_2_0 == 1 then
			arg_1_0.pointLev_[var_2_0] = arg_1_0.scorePoint_[var_2_0]
		else
			arg_1_0.pointLev_[var_2_0] = arg_1_0.pointLev_[var_2_0 - 1] + arg_1_0.scorePoint_[var_2_0]
		end
	end)
end

function var_0_0.level(arg_3_0, arg_3_1)
	return arg_3_0.level_[arg_3_1] or 0
end

function var_0_0.score(arg_4_0, arg_4_1)
	return arg_4_0.score_[arg_4_1] or 0
end

function var_0_0.scorePoint(arg_5_0, arg_5_1)
	return arg_5_0.scorePoint_[arg_5_1] or 0
end

function var_0_0.pointLev(arg_6_0, arg_6_1)
	return arg_6_0.pointLev_[arg_6_1] or 0
end

function var_0_0.normalGift(arg_7_0, arg_7_1)
	return arg_7_0.normalGift_[arg_7_1] or 0
end

function var_0_0.numNormal(arg_8_0, arg_8_1)
	return arg_8_0.numNormal_[arg_8_1] or 0
end

function var_0_0.specialGift(arg_9_0, arg_9_1)
	return arg_9_0.specialGift_[arg_9_1] or 0
end

function var_0_0.numSpecial(arg_10_0, arg_10_1)
	return arg_10_0.numSpecial_[arg_10_1] or 0
end

return var_0_0
