local var_0_0 = class("FriendRecallTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.desc_ = {}
	arg_1_0.crystal_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.type_ = {}
	arg_1_0.condition_ = {}
	arg_1_0.typeToidsList_ = {}

	import("app.common.tables.TableParser").parse("friend_recall.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.crystal_[var_2_0] = tonumber(arg_2_0.crystal)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.condition_[var_2_0] = tonumber(arg_2_0.condition)

		if not arg_1_0.typeToidsList_[arg_1_0.type_[var_2_0]] then
			arg_1_0.typeToidsList_[arg_1_0.type_[var_2_0]] = {}
		end

		table.insert(arg_1_0.typeToidsList_[arg_1_0.type_[var_2_0]], var_2_0)
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1] or ""
end

function var_0_0.crystal(arg_4_0, arg_4_1)
	return arg_4_0.crystal_[arg_4_1] or 0
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1]
end

function var_0_0.type(arg_6_0, arg_6_1)
	return arg_6_0.type_[arg_6_1] or 0
end

function var_0_0.condition(arg_7_0, arg_7_1)
	return arg_7_0.condition_[arg_7_1] or 1
end

function var_0_0.getIdsByType(arg_8_0, arg_8_1)
	return arg_8_0.typeToidsList_[arg_8_1] or {}
end

return var_0_0
