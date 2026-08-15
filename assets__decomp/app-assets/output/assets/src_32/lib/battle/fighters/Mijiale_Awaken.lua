local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_4 = var_0_0.class("Mijiale", var_0_1.ctx.battle.requireFighter("Mijiale"))
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 0.4
local var_0_7 = 0.004
local var_0_8 = 0.4
local var_0_9 = 0.004
local var_0_10 = 0.1
local var_0_11 = 0.0015
local var_0_12 = 0.04

function var_0_4.init(arg_1_0)
	var_0_4.super.init(arg_1_0)

	arg_1_0.righteousPartner = nil
end

function var_0_4.populateWithHero(arg_2_0, arg_2_1)
	var_0_4.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 2 then
		arg_2_0.SHIELD_BUFF = 40012242
	else
		arg_2_0.SHIELD_BUFF = 40010819
	end
end

function var_0_4.toDoPerFrames(arg_3_0)
	local var_3_0 = 0

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
		if not iter_3_1:isDeath() and iter_3_1 ~= arg_3_0 and iter_3_1:getSummonType() == var_0_2.summonMonsterType.None and (not arg_3_0.righteousPartner or var_3_0 < iter_3_1:getDamage()) then
			arg_3_0.righteousPartner = iter_3_1
			var_3_0 = iter_3_1:getDamage()
		end
	end

	var_0_4.super.toDoPerFrames(arg_3_0)
end

function var_0_4.addShields(arg_4_0, arg_4_1)
	var_0_4.super.addShields(arg_4_0, arg_4_1)

	if arg_4_0.righteousPartner then
		local var_4_0 = arg_4_0.righteousPartner:getBuffByID(arg_4_0.SHIELD_BUFF)
		local var_4_1 = var_0_6 + arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * var_0_7

		if arg_4_0.extraSkillLevel2 > 0 then
			var_4_1 = var_4_1 + arg_4_0.extraSkillLevel2 * var_0_12
		end

		local var_4_2 = math.floor(arg_4_1 * var_4_1)

		if var_4_0 then
			var_4_0:setShieldNum(var_4_0:getShieldNum() + var_4_2)
		else
			local var_4_3 = var_0_3.new({
				tableID = arg_4_0.SHIELD_BUFF,
				start = var_0_1.ctx.battle.count,
				level = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake),
				skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
				fighter = arg_4_0,
				target = arg_4_0.righteousPartner
			})

			var_4_3:setShieldNum(var_4_2)
			arg_4_0.righteousPartner:addBuffs({
				var_4_3
			})
		end
	end
end

function var_0_4.updateHp(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_0:getHp()

	var_0_4.super.updateHp(arg_5_0, arg_5_1, arg_5_2)

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_5_0:isDeath() then
		local var_5_1 = arg_5_0:getHp()

		if var_5_0 < var_5_1 and arg_5_0.righteousPartner and not arg_5_0.righteousPartner:isDeath() and not arg_5_0.righteousPartner:isAffected() then
			local var_5_2 = arg_5_0:createAttackUnits({
				arg_5_0.righteousPartner
			}, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			for iter_5_0, iter_5_1 in ipairs(var_5_2) do
				local var_5_3 = var_0_8 + arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * var_0_9

				if arg_5_0.extraSkillLevel2 > 0 then
					var_5_3 = var_5_3 + arg_5_0.extraSkillLevel2 * var_0_12
				end

				iter_5_1.cure_num = (var_5_1 - var_5_0) * var_5_3

				table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
				table.insert(arg_5_0.records_.special_units, iter_5_1)
			end
		end
	end
end

function var_0_4.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_4.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) and arg_6_1.cure_num and arg_6_1.cure_num > 0 then
		arg_6_5 = arg_6_5 + arg_6_1.cure_num
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_4.updateUnitDataBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_4.super.updateUnitDataBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	local var_7_0 = arg_7_1.target

	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_7_5 > 0 and var_7_0:getTeamType() == arg_7_0:getTeamType() then
		arg_7_5 = arg_7_5 * (1 + (var_0_10 + var_0_11 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)))

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_7_1 = arg_7_0:createAttackUnits({
				var_7_0
			}, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			for iter_7_0, iter_7_1 in ipairs(var_7_1) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
				table.insert(arg_7_0.records_.special_units, iter_7_1)
			end
		end
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_4.addBuffBySpecialHero(arg_8_0, arg_8_1)
	if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
			local var_8_0 = iter_8_1.target

			if var_8_0:getTeamType() == arg_8_0:getTeamType() then
				if (iter_8_1:getType() == var_0_2.BuffType.REVIVIE or iter_8_1:isDHarmBuff()) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_8_1 = arg_8_0:createAttackUnits({
						var_8_0
					}, arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

					for iter_8_2, iter_8_3 in ipairs(var_8_1) do
						table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
						table.insert(arg_8_0.records_.special_units, iter_8_3)
					end
				end

				if iter_8_1:getType() == var_0_2.BuffType.REVIVIE then
					local var_8_2 = var_0_10 + var_0_11 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)

					iter_8_1.manualHarmRevise = iter_8_1:getHarm() * (1 + var_8_2)
				end
			end
		end
	end
end

return var_0_4
