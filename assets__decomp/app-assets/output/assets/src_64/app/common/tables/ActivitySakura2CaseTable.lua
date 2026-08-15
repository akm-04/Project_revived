local var_0_0 = class("ActivitySakura2CaseTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.desc_ = {}
	arg_1_0.model_ = {}
	arg_1_0.gift_ = {}

	import("app.common.tables.TableParser").parse("activity_sakura2_case.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.model_[var_2_0] = xyd.splitToNumber(arg_2_0.model, "|")
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1] or ""
end

function var_0_0.model(arg_4_0, arg_4_1)
	return arg_4_0.model_[arg_4_1] or {}
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or 0
end

function var_0_0.getRandomModel(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0:model(arg_6_1)

	return var_6_0[math.random(1, #var_6_0)]
end

return var_0_0
