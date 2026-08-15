local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Liru", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.elementEquip
local var_0_7 = 80110013
local var_0_8 = 40011598
local var_0_9 = 40011605
local var_0_10 = 40011599
local var_0_11 = 20001431

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.skinSkillUsed = false
	arg_1_0.skinSheldExtra = 0
	arg_1_0.elementAttr = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() then
		return
	end

	if not arg_2_0.skinSkillUsed and arg_2_0.skinSkillID_ == var_0_7 then
		arg_2_0.skinSkillUsed = true

		arg_2_0:addBuffs({
			var_0_4.new({
				tableID = var_0_8,
				start = var_0_1.ctx.battle.count,
				level = arg_2_0:getLevel(),
				skillID = var_0_7,
				fighter = arg_2_0,
				target = arg_2_0
			})
		})
	end
end

function var_0_3.neverDieFeedBack(arg_3_0, arg_3_1)
	arg_3_1:updateHp(1)

	if arg_3_1 == arg_3_0 then
		arg_3_0:addBuffs({
			var_0_4.new({
				tableID = var_0_9,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getLevel(),
				skillID = var_0_7,
				fighter = arg_3_0,
				target = arg_3_0
			})
		})
		arg_3_0:createSkillByID(arg_3_0:getEnergySkillID(), arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy), var_0_5:attackIndex(arg_3_0:getEnergySkillID()))
	end
end

function var_0_3.die(arg_4_0)
	if arg_4_0:isForverNeverDie() then
		arg_4_0:updateHp(1)

		return
	end

	var_0_3.super.die(arg_4_0)
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if not arg_5_0:isDeath() and arg_5_0.skinSkillID_ == var_0_7 and arg_5_1.skillID == arg_5_0:getEnergySkillID() then
		local var_5_0 = arg_5_6 - (arg_5_0:getHpLimit() - arg_5_0:getHp())

		if var_5_0 > 0 then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_5_1 = arg_5_0:createAttackUnits({
					arg_5_0
				}, var_0_7)

				for iter_5_0, iter_5_1 in ipairs(var_5_1) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
					table.insert(arg_5_0.records_.special_units, iter_5_1)
				end
			end

			arg_5_0.skinSheldExtra = var_5_0
		end
	end

	return arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	if arg_6_0:hasElementEquipByID(var_0_11) and arg_6_1.skillID == arg_6_0:getEnergySkillID() then
		local var_6_0 = var_0_11
		local var_6_1 = var_0_6:skillIDs(var_6_0)
		local var_6_2 = var_0_6:buffIDs(var_6_0)
		local var_6_3 = arg_6_0:createNewBuffs(var_6_2, arg_6_0, var_6_1[1])

		for iter_6_0, iter_6_1 in ipairs(var_6_3) do
			iter_6_1.manualRevise = arg_6_0.elementAttr
		end

		arg_6_0:addBuffs(var_6_3)
	end

	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_1.skillID == var_0_7 then
		local var_6_4 = var_0_4.new({
			tableID = var_0_10,
			start = var_0_1.ctx.battle.count,
			level = arg_6_0:getLevel(),
			skillID = var_0_7,
			fighter = arg_6_0,
			target = arg_6_0
		})

		var_6_4.manualDharm = arg_6_0.skinSheldExtra
		arg_6_0.skinSheldExtra = 0

		arg_6_0:addBuffs({
			var_6_4
		})
	end

	if arg_6_0:hasElementEquipByID(var_0_11) and arg_6_1.attackType == var_0_2.AttackType.AP then
		local var_6_5 = var_0_11
		local var_6_6 = var_0_6:battleAttr(var_6_5, arg_6_0:getElementEquipLevelByID(var_6_5))
		local var_6_7 = arg_6_0.hero_:getElementEquipActiveRate(var_6_5)

		arg_6_0.elementAttr = arg_6_0.elementAttr + var_6_6 * var_6_7
	end
end

return var_0_3
