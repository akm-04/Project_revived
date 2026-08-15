local var_0_0 = class("ActivityPartyMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.type_ = {}
	arg_1_0.subType_ = {}
	arg_1_0.mesc_ = {}
	arg_1_0.condition_ = {}
	arg_1_0.gift_ = {}

	import("app.common.tables.TableParser").parse("activity_party_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.subType_[var_2_0] = tonumber(arg_2_0.sub_type)
		arg_1_0.mesc_[var_2_0] = arg_2_0.mesc
		arg_1_0.condition_[var_2_0] = tonumber(arg_2_0.condition)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
	end)
end

function var_0_0.type(arg_3_0, arg_3_1)
	return arg_3_0.type_[arg_3_1] or 0
end

function var_0_0.subType(arg_4_0, arg_4_1)
	return arg_4_0.subType_[arg_4_1] or 0
end

function var_0_0.mesc(arg_5_0, arg_5_1)
	return arg_5_0.mesc_[arg_5_1] or ""
end

function var_0_0.condition(arg_6_0, arg_6_1)
	return arg_6_0.condition_[arg_6_1] or 0
end

function var_0_0.gift(arg_7_0, arg_7_1)
	return arg_7_0.gift_[arg_7_1] or 0
end

return var_0_0
