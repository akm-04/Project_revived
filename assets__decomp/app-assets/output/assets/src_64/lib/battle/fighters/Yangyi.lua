local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yangyi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = 40011519
local var_0_8 = 10001468
local var_0_9 = 10001464
local var_0_10 = 10001465
local var_0_11 = 10001466
local var_0_12 = 40010214

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	local var_1_0 = arg_1_1.target
	local var_1_1 = arg_1_1.skillID

	if var_1_1 == arg_1_0:getEnergySkillID() and var_1_0:isHasBuffByID(var_0_7) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_1_2 = arg_1_0:createAttackUnits({
			var_1_0
		}, var_0_8)

		for iter_1_0, iter_1_1 in ipairs(var_1_2) do
			table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
			table.insert(arg_1_0.records_.special_units, iter_1_1)
		end
	end

	if var_1_1 == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and var_1_0:isHasBuffByID(var_0_7) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_1_3 = arg_1_0:createAttackUnits({
			var_1_0
		}, var_0_9)

		for iter_1_2, iter_1_3 in ipairs(var_1_3) do
			table.insert(arg_1_0.moveAttackUnits_, iter_1_3)
			table.insert(arg_1_0.records_.special_units, iter_1_3)
		end
	end

	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)
end

function var_0_3.selectTargetByTypeD3(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0, var_2_1 = var_0_4.getTeam(arg_2_0)
	local var_2_2 = 0
	local var_2_3

	for iter_2_0, iter_2_1 in ipairs(var_2_1) do
		if not iter_2_1:isDeath() and not iter_2_1:isAffected() and iter_2_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_2_4 = iter_2_1.hero_:getZhandouli()

			if var_2_2 < var_2_4 then
				var_2_3 = iter_2_1
				var_2_2 = var_2_4
			end
		end
	end

	return {
		var_2_3
	}
end

function var_0_3.deathFeedback(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1:getBuffByID(var_0_7)

	if var_3_0 and var_3_0.fighter == arg_3_0 then
		arg_3_1:removeBuffs(var_3_0)

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_1 = arg_3_1:createAttackUnits(arg_3_0:selectTargetByTypeD3(nil, nil), var_0_10)

			for iter_3_0, iter_3_1 in ipairs(var_3_1) do
				iter_3_1.actualFighter = arg_3_0

				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end
		end
	end
end

function var_0_3.updateUnitInfoBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	if arg_4_1.skillID == var_0_10 and arg_4_1.actualFighter == arg_4_0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_0 = arg_4_0:createAttackUnits({
			arg_4_1.target
		}, var_0_11)

		for iter_4_0, iter_4_1 in ipairs(var_4_0) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)

			if iter_4_1.resource then
				iter_4_1.resource:pos(iter_4_1:getIniPos())
				iter_4_1:rotate()
				iter_4_1:movePosition()
				iter_4_1.resource:addTo(var_0_1.ctx.battle.unitLayer)
				iter_4_1.resource:playRepeat()
			end
		end
	end
end

function var_0_3.forceDie(arg_5_0)
	if arg_5_0:getSkillLevelByID(var_0_12) > 0 and arg_5_0.killer_ and arg_5_0.killer_:getTeamType() ~= arg_5_0:getTeamType() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_0 = arg_5_0:createAttackUnits({
			arg_5_0.killer_
		}, var_0_12)

		for iter_5_0, iter_5_1 in ipairs(var_5_0) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)

			if iter_5_1.resource then
				iter_5_1.resource:pos(iter_5_1:getIniPos())
				iter_5_1:rotate()
				iter_5_1:movePosition()
				iter_5_1.resource:addTo(var_0_1.ctx.battle.unitLayer)
				iter_5_1.resource:playRepeat()
			end
		end
	end

	var_0_3.super.forceDie(arg_5_0)
end

return var_0_3
