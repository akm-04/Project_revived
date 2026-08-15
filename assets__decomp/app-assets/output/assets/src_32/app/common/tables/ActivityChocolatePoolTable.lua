local var_0_0 = class("ActivityChocolatePoolTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.awardId_ = {}
	arg_1_0.isSpecial_ = {}
	arg_1_0.specialItem_ = {}

	import("app.common.tables.TableParser").parse("activity_chocolate_pool.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.awardId_[var_2_0] = tonumber(arg_2_0.award_id)
		arg_1_0.isSpecial_[var_2_0] = tonumber(arg_2_0.is_special)
		arg_1_0.specialItem_[var_2_0] = tonumber(arg_2_0.special_item)
	end)
end

function var_0_0.awardId(arg_3_0, arg_3_1)
	return arg_3_0.awardId_[arg_3_1] or 0
end

function var_0_0.isSpecial(arg_4_0, arg_4_1)
	return arg_4_0.isSpecial_[arg_4_1] or 0
end

function var_0_0.specialItem(arg_5_0, arg_5_1)
	return arg_5_0.specialItem_[arg_5_1] or 0
end

return var_0_0
