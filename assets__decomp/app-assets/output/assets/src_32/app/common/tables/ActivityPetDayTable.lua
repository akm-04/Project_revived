local var_0_0 = class("ActivityPetDayTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.recharge_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.day_ = {}
	arg_1_0.id_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.modelID_ = {}

	import("app.common.tables.TableParser").parse("activity_petday.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.id_, var_2_0)

		arg_1_0.recharge_[var_2_0] = tonumber(arg_2_0.recharge)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.gift_[var_2_0] = xyd.splitToNumber(arg_2_0.gift, "|")
		arg_1_0.day_[var_2_0] = tonumber(arg_2_0.day)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.modelID_[var_2_0] = xyd.splitToNumber(arg_2_0.model_id, "|")
	end)
end

function var_0_0.recharge(arg_3_0, arg_3_1)
	return arg_3_0.recharge_[arg_3_1] or 0
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or {}
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or 0
end

function var_0_0.gifts(arg_6_0)
	return arg_6_0.gift_ or {}
end

function var_0_0.day(arg_7_0, arg_7_1)
	return arg_7_0.day_[arg_7_1]
end

function var_0_0.icon(arg_8_0, arg_8_1)
	return arg_8_0.icon_[arg_8_1] or ""
end

function var_0_0.desc(arg_9_0, arg_9_1)
	return arg_9_0.desc_[arg_9_1]
end

function var_0_0.getIds(arg_10_0)
	return arg_10_0.id_
end

function var_0_0.modelID(arg_11_0, arg_11_1)
	return arg_11_0.modelID_[arg_11_1] or {}
end

return var_0_0
