local var_0_0 = class("MonsterPositionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.positionGroups_ = {}
	arg_1_0.monsters_ = {}
	arg_1_0.towerLevels_ = {}
	arg_1_0.bossPositions_ = {}

	import("app.common.tables.TableParser").parse("battle_monster_group.csv", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.positionGroups_[var_2_0] = tonumber(arg_2_0.p_group)
		arg_1_0.monsters_[var_2_0] = {}

		table.insert(arg_1_0.monsters_[var_2_0], tonumber(arg_2_0.pos_1))
		table.insert(arg_1_0.monsters_[var_2_0], tonumber(arg_2_0.pos_2))
		table.insert(arg_1_0.monsters_[var_2_0], tonumber(arg_2_0.pos_3))
		table.insert(arg_1_0.monsters_[var_2_0], tonumber(arg_2_0.pos_4))
		table.insert(arg_1_0.monsters_[var_2_0], tonumber(arg_2_0.pos_5))

		arg_1_0.towerLevels_[var_2_0] = tonumber(arg_2_0.tower_lev)
		arg_1_0.bossPositions_[var_2_0] = tonumber(arg_2_0.boss_pos)
	end)
end

function var_0_0.positionGroup(arg_3_0, arg_3_1)
	return arg_3_0.positionGroups_[arg_3_1] or 0
end

function var_0_0.monsters(arg_4_0, arg_4_1)
	return arg_4_0.monsters_[arg_4_1] or {}
end

function var_0_0.towerLevel(arg_5_0, arg_5_1)
	return arg_5_0.towerLevels_[arg_5_1] or 0
end

function var_0_0.bossPosition(arg_6_0, arg_6_1)
	return arg_6_0.bossPositions_[arg_6_1] or 0
end

return var_0_0
