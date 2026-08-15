local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("ConquerSchoolLoopTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.ratio_ = {}
	arg_1_0.rewardItem_ = {}
	arg_1_0.rewardItemNum_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("conquer_school_loop.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("conquer_school_loop", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.loop_id)

	arg_2_0.ratio_[var_2_0] = arg_2_1.ratio
	arg_2_0.rewardItem_[var_2_0] = tonumber(arg_2_1.reward_item)
	arg_2_0.rewardItemNum_[var_2_0] = tonumber(arg_2_1.reward_item_num)
end

function var_0_2.ratio(arg_3_0, arg_3_1)
	return arg_3_0.ratio_[arg_3_1] or 0
end

function var_0_2.rewardItem(arg_4_0, arg_4_1)
	return arg_4_0.rewardItem_[arg_4_1] or 0
end

function var_0_2.rewardItemNum(arg_5_0, arg_5_1)
	return arg_5_0.rewardItemNum_[arg_5_1] or 0
end

return var_0_2
