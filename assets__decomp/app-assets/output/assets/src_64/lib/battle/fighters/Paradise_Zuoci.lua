local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ParadiseZuoci", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = {
	40010427
}
local var_0_6 = {
	40010426
}

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	if arg_1_1.skillID == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		if not arg_1_0:isMagicHero(arg_1_1.target) then
			local var_1_0 = arg_1_0:newBuff(var_0_5, arg_1_1.target, arg_1_1.skillID)

			arg_1_1.target:addBuffs(var_1_0)
		end
	elseif arg_1_1.skillID == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and not arg_1_0:isMagicHero(arg_1_1.target) then
		local var_1_1 = arg_1_0:newBuff(var_0_6, arg_1_1.target, arg_1_1.skillID)

		arg_1_1.target:addBuffs(var_1_1)
	end
end

function var_0_3.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	if arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_2_0 = 0

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
			if not iter_2_1:isDeath() and iter_2_1:getSummonType() == var_0_2.summonMonsterType.None and arg_2_0:isMagicHero(iter_2_1) then
				var_2_0 = var_2_0 + 1
			end
		end

		arg_2_4 = arg_2_4 * (1 - 0.05 * var_2_0)
	end

	return var_0_3.super.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
end

function var_0_3.isMagicHero(arg_3_0, arg_3_1)
	if arg_3_1.hero_:getHeroType() == var_0_2.HeroType.WISE then
		return true
	end

	return false
end

function var_0_3.newBuff(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		local var_4_1 = var_0_4.new({
			tableID = iter_4_1,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getSkillLevelByID(arg_4_3),
			skillID = arg_4_3,
			fighter = arg_4_0,
			target = arg_4_2
		})

		var_4_1:setIsHit(true)
		var_4_1:setDirection(arg_4_0:getFighterModel():getFlipX())
		table.insert(var_4_0, var_4_1)
	end

	return var_4_0
end

return var_0_3
