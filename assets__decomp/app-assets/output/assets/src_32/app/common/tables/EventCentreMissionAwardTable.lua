local var_0_0 = class("EventCentreMissionAwardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.grade_ = {}
	arg_1_0.itemId_ = {}
	arg_1_0.itemNumber_ = {}
	arg_1_0.rewardId_ = {}
	arg_1_0.rewardResource_ = {}
	arg_1_0.time_ = {}
	arg_1_0.deposit = {}
	arg_1_0.rewardGold_ = {}

	import("app.common.tables.TableParser").parse("event_centre_mission_award.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.grade_[var_2_0] = arg_2_0.grade
		arg_1_0.itemId_[var_2_0] = arg_2_0.item_id
		arg_1_0.itemNumber_[var_2_0] = arg_2_0.item_number
		arg_1_0.rewardId_[var_2_0] = arg_2_0.reward_id
		arg_1_0.rewardResource_[var_2_0] = arg_2_0.reward_resource
		arg_1_0.rewardGold_[var_2_0] = arg_2_0.reward_gold
	end)
end

function var_0_0.grade(arg_3_0, arg_3_1)
	return arg_3_0.grade_[arg_3_1] or ""
end

function var_0_0.itemId(arg_4_0, arg_4_1)
	return arg_4_0.itemId_[arg_4_1] or ""
end

function var_0_0.itemNumber(arg_5_0, arg_5_1)
	return arg_5_0.itemNumber_[arg_5_1] or ""
end

function var_0_0.rewardId(arg_6_0, arg_6_1)
	return arg_6_0.rewardId_[arg_6_1] or ""
end

function var_0_0.rewardResource(arg_7_0, arg_7_1)
	return arg_7_0.rewardResource_[arg_7_1] or ""
end

function var_0_0.rewardGold(arg_8_0, arg_8_1)
	return arg_8_0.rewardGold_[arg_8_1]
end

return var_0_0
