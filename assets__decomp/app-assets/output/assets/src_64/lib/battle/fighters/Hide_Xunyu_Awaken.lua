local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xunyu", var_0_1.ctx.battle.requireFighter("Hide_Xunyu"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 10000136
local var_0_6 = 40010938
local var_0_7 = 10000871
local var_0_8 = 0.16
local var_0_9 = 0.003
local var_0_10 = 2

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	if arg_1_1.skillID == arg_1_0:getEnergySkillID() then
		if arg_1_0.isAwakeTwiceType_ then
			if arg_1_4 > 0 then
				local var_1_0 = arg_1_4 * (1 + var_0_8)

				arg_1_0.awakeTwiceTotalHarm_ = arg_1_0.awakeTwiceTotalHarm_ + arg_1_4
				arg_1_6 = arg_1_6 + var_1_0
			end

			if arg_1_1.collisionNum <= 1 and arg_1_0.awakeTwiceTotalHarm_ > 0 then
				arg_1_0:getFighterModel():stopAttackEffect_()
				arg_1_0:useAwakeTwiceSkill()
			end
		else
			arg_1_0.skillRehp_ = (arg_1_0.skillRehp_ or 0) + arg_1_4

			if arg_1_1.collisionNum <= 1 and arg_1_0.skillRehp_ > 0 then
				-- block empty
			end
		end
	elseif arg_1_1.skillID == var_0_7 and arg_1_1.change_harm and arg_1_1.change_harm > 0 then
		arg_1_4 = arg_1_1.change_harm
	end

	return var_0_3.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	if arg_2_1.skillID == arg_2_0:getEnergySkillID() and arg_2_0:isDeath() then
		return
	end

	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.skillRehp_ = 0
	arg_3_0.isAwakeTwiceType_ = false
	arg_3_0.isAwakeTwiceJudge_ = false
	arg_3_0.awakeTwiceTotalHarm_ = 0
end

function var_0_3.toDoPerFrames(arg_4_0)
	var_0_3.super.toDoPerFrames(arg_4_0)

	if not arg_4_0.isAwakeTwiceJudge_ then
		arg_4_0.isAwakeTwiceJudge_ = true

		if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
			arg_4_0.isAwakeTwiceType_ = true
		end
	end
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)

	if arg_5_1.rootID_ == arg_5_0:getEnergySkillID() and arg_5_0.isAwakeTwiceType_ then
		local var_5_0 = arg_5_0:newBuff({
			var_0_6
		}, arg_5_0, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

		arg_5_0:addBuffs(var_5_0)
	end
end

function var_0_3.newBuff(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_1) do
		local var_6_1 = var_0_4.new({
			tableID = iter_6_1,
			start = var_0_1.ctx.battle.count,
			level = arg_6_0:getSkillLevelByID(arg_6_3),
			skillID = arg_6_3,
			fighter = arg_6_0,
			target = arg_6_2
		})

		var_6_1:setIsHit(true)
		var_6_1:setDirection(arg_6_0:getFighterModel():getFlipX())
		table.insert(var_6_0, var_6_1)
	end

	return var_6_0
end

function var_0_3.checkReHpMp(arg_7_0)
	var_0_3.super.checkReHpMp(arg_7_0)
end

function var_0_3.showCureEffect(arg_8_0)
	return
end

function var_0_3.unitCollisionBreak(arg_9_0, arg_9_1)
	if arg_9_1.skillID ~= arg_9_0:getEnergySkillID() or not arg_9_0.isAwakeTwiceType_ then
		-- block empty
	else
		arg_9_0:getFighterModel():stopAttackEffect_()
		arg_9_0:useAwakeTwiceSkill()
	end
end

function var_0_3.useAwakeTwiceSkill(arg_10_0)
	local var_10_0 = arg_10_0:getBuffByID(var_0_6)

	if var_10_0 then
		arg_10_0:removeBuffs(var_10_0)
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_10_1 = arg_10_0:getTargets(var_0_7)

	if #var_10_1 > 0 then
		local var_10_2
		local var_10_3

		for iter_10_0, iter_10_1 in ipairs(var_10_1) do
			if not var_10_3 or var_10_3 > iter_10_1:getHp() then
				var_10_2 = iter_10_1
				var_10_3 = iter_10_1:getHp()
			end
		end

		local var_10_4 = arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) * arg_10_0.awakeTwiceTotalHarm_ * var_0_9 / #var_10_1
		local var_10_5 = arg_10_0:createAttackUnits(var_10_1, var_0_7)

		for iter_10_2, iter_10_3 in ipairs(var_10_5) do
			iter_10_3.change_harm = var_10_4

			if iter_10_3.target == var_10_2 then
				iter_10_3.change_harm = var_10_4 * var_0_10
			end

			table.insert(arg_10_0.moveAttackUnits_, iter_10_3)
			table.insert(arg_10_0.records_.special_units, iter_10_3)
		end

		arg_10_0.awakeTwiceTotalHarm_ = 0
	end
end

return var_0_3
