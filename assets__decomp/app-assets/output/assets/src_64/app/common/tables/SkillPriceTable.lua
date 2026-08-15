local var_0_0 = class("SkillPriceTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.gold_ = {}
	arg_1_0.exp_ = {}

	import("app.common.tables.TableParser").parse("skill_price.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.lev)

		arg_1_0.gold_[var_2_0] = tonumber(arg_2_0.mana)
	end)
end

function var_0_0.gold(arg_3_0, arg_3_1)
	return arg_3_0.gold_[arg_3_1] or 0
end

return var_0_0
