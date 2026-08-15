local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Alicetuzi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = {
	{
		40010595,
		40010596
	},
	{
		40010597,
		40010598
	},
	{
		40010599,
		40010570
	},
	{
		40010571,
		40010572
	},
	{
		40010573,
		40010574
	}
}

function var_0_3.die(arg_1_0)
	var_0_3.super.die(arg_1_0)

	local var_1_0 = true

	for iter_1_0, iter_1_1 in ipairs(arg_1_0.selfTeam_) do
		if (not iter_1_1:isDeath() or iter_1_1:canReborn()) and iter_1_1:getSummonType() == var_0_2.summonMonsterType.None then
			var_1_0 = false

			break
		end
	end

	if not var_1_0 then
		local var_1_1 = {}
		local var_1_2 = var_0_4:scope(arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		for iter_1_2, iter_1_3 in ipairs(arg_1_0.sideTeam_) do
			if not iter_1_3:isDeath() and not iter_1_3:isAffected() and math.abs(iter_1_3:getX() - arg_1_0:getX()) <= var_1_2 * 0.5 then
				table.insert(var_1_1, iter_1_3)
			end
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_1_3 = arg_1_0:createAttackUnits(var_1_1, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			for iter_1_4, iter_1_5 in ipairs(var_1_3) do
				table.insert(arg_1_0.moveAttackUnits_, iter_1_5)
				table.insert(arg_1_0.records_.special_units, iter_1_5)
			end
		end
	end
end

function var_0_3.getAD(arg_2_0)
	if not arg_2_0.summoner then
		return var_0_3.super.getAD(arg_2_0)
	else
		return arg_2_0.summoner:getAD()
	end
end

function var_0_3.getAP(arg_3_0)
	if not arg_3_0.summoner then
		return var_0_3.super.getAP(arg_3_0)
	else
		return arg_3_0.summoner:getAP()
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_4_0:purpleBuffNum(arg_4_1.target) > 0 then
		arg_4_4 = arg_4_4 * 2
	end

	return var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
end

function var_0_3.purpleBuffNum(arg_5_0, arg_5_1)
	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 0 then
		return 0
	else
		for iter_5_0, iter_5_1 in ipairs(var_0_5) do
			if arg_5_1:isHasBuffByID(iter_5_1[1]) then
				return iter_5_0
			end
		end

		return 0
	end
end

function var_0_3.canAttack(arg_6_0)
	return false
end

return var_0_3
