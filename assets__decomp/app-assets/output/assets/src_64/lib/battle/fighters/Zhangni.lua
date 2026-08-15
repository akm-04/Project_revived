local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangni", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 40011548
local var_0_8 = 10001499
local var_0_9 = 10001496
local var_0_10 = 0.5
local var_0_11 = 10001497
local var_0_12 = 0.4
local var_0_13 = 40011542
local var_0_14 = 10001495
local var_0_15 = 10001494
local var_0_16 = 10001498
local var_0_17 = 40011551
local var_0_18 = 40011553
local var_0_19 = 40011545

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.PugongRate = 1
end

function var_0_3.getFrontSkill(arg_2_0)
	local var_2_0 = var_0_3.super.getFrontSkill(arg_2_0)

	if arg_2_0:isHasBuffByID(var_0_7) and var_2_0 == arg_2_0:getPugongID() then
		var_2_0 = var_0_8
	end

	return var_2_0
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1.skillID
	local var_3_1 = arg_3_1.target

	if var_3_0 == arg_3_0:getPugongID() or var_3_0 == var_0_8 then
		arg_3_1.basicHarm = arg_3_1.basicHarm * arg_3_0.PugongRate

		if arg_3_0.PugongRate == 2.2 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_2 = arg_3_0:createAttackUnits({
				arg_3_0
			}, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			for iter_3_0, iter_3_1 in ipairs(var_3_2) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end
		end

		if arg_3_0:isHasBuffByID(var_0_7) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_3 = var_0_2.weightedChoise({
				var_0_10,
				1 - var_0_10
			}) == 1
			local var_3_4 = var_0_2.weightedChoise({
				var_0_12,
				1 - var_0_12
			}) == 1

			if var_3_3 then
				local var_3_5 = arg_3_0:createAttackUnits({
					var_3_1
				}, var_0_9)

				for iter_3_2, iter_3_3 in ipairs(var_3_5) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
					table.insert(arg_3_0.records_.special_units, iter_3_3)
				end
			end

			if var_3_4 then
				local var_3_6 = arg_3_0:createAttackUnits({
					var_3_1
				}, var_0_11)

				for iter_3_4, iter_3_5 in ipairs(var_3_6) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_5)
					table.insert(arg_3_0.records_.special_units, iter_3_5)
				end
			end
		end

		if arg_3_0:isHasBuffByID(var_0_13) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_7 = arg_3_0:createAttackUnits({
				arg_3_0
			}, var_0_14)

			for iter_3_6, iter_3_7 in ipairs(var_3_7) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_7)
				table.insert(arg_3_0.records_.special_units, iter_3_7)
			end

			local var_3_8 = arg_3_0:createAttackUnits({
				var_3_1
			}, var_0_15)

			for iter_3_8, iter_3_9 in ipairs(var_3_8) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_9)
				table.insert(arg_3_0.records_.special_units, iter_3_9)
			end
		end
	end

	if var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_3_9 = arg_3_0:selectTargetByTypeD2(var_3_0, arg_3_1)[1]

		if var_3_9 then
			arg_3_0:flipX(var_3_9:getFlipX())
			arg_3_0:x(var_3_9:getX() + (var_3_9:getFlipX() and 50 or -50))
			arg_3_0:y(var_3_9:getY())
		end

		arg_3_0:createSkillByID(var_0_16, arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green), var_0_6:attackIndex(var_0_16))
	end

	if var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		for iter_3_10, iter_3_11 in ipairs(arg_3_0:getBuffs()) do
			if (iter_3_11:dBuffType() > 0 or iter_3_11:getType() == var_0_2.BuffType.D_Negative_Buff) and iter_3_11:canRemove() then
				arg_3_0:removeBuffs(iter_3_11)
			end
		end
	end

	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if arg_4_0.PugongRate == 0.3 or arg_4_0:isHasBuffByID(var_0_18) then
			arg_4_0.PugongRate = 2.2
		else
			arg_4_0.PugongRate = math.floor(math.random() * 20) / 10 + 0.3
		end
	end
end

function var_0_3.buffRemoveAction(arg_5_0, arg_5_1)
	if arg_5_1.target == arg_5_0 and arg_5_1:getTableID() == var_0_17 and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_5_0:addBuffs({
			var_0_5.new({
				tableID = var_0_18,
				start = var_0_1.ctx.battle.count,
				level = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue),
				skillID = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue),
				fighter = arg_5_0,
				target = arg_5_0
			})
		})
	end
end

function var_0_3.selectTargetByTypeD2(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.targetTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and (not var_6_0 or iter_6_1:getAttrByType(var_0_2.AttributeType.AGILE) < var_6_0:getAttrByType(var_0_2.AttributeType.AGILE)) then
			var_6_0 = iter_6_1
		end
	end

	return {
		var_6_0
	}
end

return var_0_3
