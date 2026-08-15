local var_0_0 = class("EventCentreMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.hero_ = {}
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.enemy_ = {}
	arg_1_0.fighting_ = {}
	arg_1_0.time_ = {}
	arg_1_0.deposit_ = {}
	arg_1_0.monsterStar_ = {}
	arg_1_0.monsterQuality_ = {}
	arg_1_0.monsterLevel_ = {}
	arg_1_0.fightId_ = {}
	arg_1_0.heroId_ = {}

	import("app.common.tables.TableParser").parse("event_centre_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.hero_[var_2_0] = arg_2_0.hero
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.heroId_[var_2_0] = tonumber(arg_2_0.hero_id)
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.enemy_[var_2_0] = xyd.splitToNumber(arg_2_0.enemy, "|")
		arg_1_0.fighting_[var_2_0] = tonumber(arg_2_0.fighting)
		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.time)
		arg_1_0.deposit_[var_2_0] = tonumber(arg_2_0.deposit)
		arg_1_0.monsterStar_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_star, "|")
		arg_1_0.monsterQuality_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_quality, "|")
		arg_1_0.monsterLevel_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_level, "|")
		arg_1_0.fightId_[var_2_0] = tonumber(arg_2_0.fight_id)
	end)
end

function var_0_0.hero(arg_3_0, arg_3_1)
	return arg_3_0.hero_[arg_3_1] or ""
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.desc(arg_5_0, arg_5_1)
	return arg_5_0.desc_[arg_5_1] or ""
end

function var_0_0.enemy(arg_6_0, arg_6_1)
	return arg_6_0.enemy_[arg_6_1] or ""
end

function var_0_0.fighting(arg_7_0, arg_7_1)
	return arg_7_0.fighting_[arg_7_1] or ""
end

function var_0_0.time(arg_8_0, arg_8_1)
	return arg_8_0.time_[arg_8_1] or 0
end

function var_0_0.deposit(arg_9_0, arg_9_1)
	return arg_9_0.deposit_[arg_9_1] or ""
end

function var_0_0.monsterStar(arg_10_0, arg_10_1)
	return arg_10_0.monsterStar_[arg_10_1] or {}
end

function var_0_0.monsterQuality(arg_11_0, arg_11_1)
	return arg_11_0.monsterQuality_[arg_11_1] or {}
end

function var_0_0.monsterLevel(arg_12_0, arg_12_1)
	return arg_12_0.monsterLevel_[arg_12_1] or {}
end

function var_0_0.fightId(arg_13_0, arg_13_1)
	return arg_13_0.fightId_[arg_13_1] or 0
end

function var_0_0.heroId(arg_14_0, arg_14_1)
	return arg_14_0.heroId_[arg_14_1] or 0
end

return var_0_0
