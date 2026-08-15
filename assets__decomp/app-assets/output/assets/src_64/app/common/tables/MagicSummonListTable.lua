local var_0_0 = class("MagicSummonListTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.getHeroId_ = {}

	import("app.common.tables.TableParser").parse("magic_summon_list.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.getHeroId_[var_2_0] = xyd.splitToNumber(arg_2_0.get_hero_id, "|")
	end)
end

function var_0_0.getHeroId(arg_3_0, arg_3_1)
	return arg_3_0.getHeroId_[arg_3_1] or {}
end

return var_0_0
