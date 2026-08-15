local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Chengyu", var_0_1.ctx.battle.requireFighter("Chengyu"))
local var_0_4 = var_0_2.tables.battleConfig
local var_0_5 = 20
local var_0_6 = 2
local var_0_7 = 10002038

function var_0_3.forceDie(arg_1_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_1_0 = {}

		for iter_1_0, iter_1_1 in ipairs(arg_1_0.selfTeam_) do
			if not iter_1_1:isDeath() and not iter_1_1:isAffected() then
				table.insert(var_1_0, iter_1_1)
			end
		end

		if next(var_1_0) then
			local var_1_1 = arg_1_0:createAttackUnits(var_1_0, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			for iter_1_2, iter_1_3 in ipairs(var_1_1) do
				iter_1_3.arrived = false

				table.insert(arg_1_0.moveAttackUnits_, iter_1_3)
				table.insert(arg_1_0.records_.special_units, iter_1_3)
			end
		end
	end

	return var_0_3.super.forceDie(arg_1_0)
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_2_1.attackType == var_0_2.AttackType.AP then
		local var_2_0 = arg_2_1.target
		local var_2_1 = arg_2_1.fighter

		if var_2_0.hero_:getHeroType() ~= var_0_2.HeroType.WISE then
			local var_2_2 = (var_2_1:getAPBaoJi() + var_0_5 + var_0_6 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)) / (var_0_4.mokangBaojiParam1 * math.max(var_2_0:getMoKang() - var_2_1:getDMoKang(), 0) + var_0_4.mokangBaojiParam2)

			arg_2_0.fixedBaojiRate = math.min(1, var_2_2)
		end
	end

	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_2_1.attackType == var_0_2.AttackType.AP and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_2_1.isBaoJi then
		local var_2_3 = arg_2_0:createAttackUnits({
			arg_2_1.target
		}, var_0_7)

		for iter_2_0, iter_2_1 in ipairs(var_2_3) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end
end

return var_0_3
