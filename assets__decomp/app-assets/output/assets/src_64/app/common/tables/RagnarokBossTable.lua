local var_0_0 = class("RagnarokBossTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.singleBattleId_ = {}
	arg_1_0.singleMonsterId_ = {}
	arg_1_0.cooperateBattleId_ = {}
	arg_1_0.cooperateMonsterId_ = {}

	import("app.common.tables.TableParser").parse("activity_ragnarok_boss_single.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.singleBattleId_[var_2_0] = tonumber(arg_2_0.battle_id)
		arg_1_0.singleMonsterId_[var_2_0] = tonumber(arg_2_0.monster_id)
	end)
	import("app.common.tables.TableParser").parse("activity_ragnarok_boss_team.lua", function(arg_3_0)
		local var_3_0 = tonumber(arg_3_0.id)

		arg_1_0.cooperateBattleId_[var_3_0] = tonumber(arg_3_0.battle_id)
		arg_1_0.cooperateMonsterId_[var_3_0] = tonumber(arg_3_0.monster_id)
	end)
end

function var_0_0.battleId(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_1 == xyd.RagnarokType.SINGLE then
		return arg_4_0.singleBattleId_[arg_4_2] or 0
	elseif arg_4_1 == xyd.RagnarokType.TEAM then
		return arg_4_0.cooperateBattleId_[arg_4_2] or 0
	end
end

function var_0_0.monsterId(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_1 == xyd.RagnarokType.SINGLE then
		return arg_5_0.singleMonsterId_[arg_5_2] or 0
	elseif arg_5_1 == xyd.RagnarokType.TEAM then
		return arg_5_0.cooperateMonsterId_[arg_5_2] or 0
	end
end

return var_0_0
