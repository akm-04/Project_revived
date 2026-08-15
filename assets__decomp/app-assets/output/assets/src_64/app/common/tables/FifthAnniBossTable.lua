local var_0_0 = class("FifthAnniBossTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.battleId_ = {}
	arg_1_0.award_ = {}

	import("app.common.tables.TableParser").parse("fifth_anni_boss.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.battleId_[var_2_0] = xyd.splitToNumber(arg_2_0.battle_id, "|")
		arg_1_0.award_[var_2_0] = tonumber(arg_2_0.award)
	end)
end

function var_0_0.battleId(arg_3_0, arg_3_1)
	return arg_3_0.battleId_[arg_3_1] or {}
end

function var_0_0.award(arg_4_0, arg_4_1)
	return arg_4_0.award_[arg_4_1] or 0
end

return var_0_0
