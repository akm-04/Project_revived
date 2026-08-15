local var_0_0 = class("ActivityFishBattleTextTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.desc_ = {}

	import("app.common.tables.TableParser").parse("activity_fish_battle_text.lua", function(arg_2_0)
		local var_2_0 = arg_2_0.case

		arg_1_0.desc_[var_2_0] = xyd.split(arg_2_0.desc, "@")
	end)
end

function var_0_0.getDesc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1]
end

return var_0_0
