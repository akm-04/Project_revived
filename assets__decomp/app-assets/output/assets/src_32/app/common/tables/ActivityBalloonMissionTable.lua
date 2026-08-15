local var_0_0 = class("ActivityBalloonMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.content_ = {}
	arg_1_0.type_ = {}
	arg_1_0.num_ = {}
	arg_1_0.itemId_ = {}
	arg_1_0.itemNum_ = {}

	import("app.common.tables.TableParser").parse("activity_balloon_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.content_[var_2_0] = arg_2_0.content
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.itemId_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.itemNum_[var_2_0] = tonumber(arg_2_0.item_num)
	end)
end

function var_0_0.content(arg_3_0, arg_3_1)
	return arg_3_0.content_[arg_3_1] or ""
end

function var_0_0.type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or 0
end

function var_0_0.num(arg_5_0, arg_5_1)
	return arg_5_0.num_[arg_5_1] or 0
end

function var_0_0.itemId(arg_6_0, arg_6_1)
	return arg_6_0.itemId_[arg_6_1] or 0
end

function var_0_0.itemNum(arg_7_0, arg_7_1)
	return arg_7_0.itemNum_[arg_7_1] or 0
end

return var_0_0
