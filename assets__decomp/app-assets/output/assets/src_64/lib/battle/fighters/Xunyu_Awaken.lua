local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xunyu", var_0_1.ctx.battle.requireFighter("Xunyu"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 10000136
local var_0_6 = 50110036
local var_0_7 = 80010036
local var_0_8 = 0.3
local var_0_9 = 40010938
local var_0_10 = 10000871
local var_0_11 = 0.16
local var_0_12 = 0.003
local var_0_13 = 2

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	if arg_1_1.skillID == arg_1_0:getEnergySkillID() or arg_1_1.skillID == var_0_6 then
		if arg_1_0.isAwakeTwiceType_ then
			if arg_1_4 > 0 then
				local var_1_0 = arg_1_4 * (1 + var_0_11)

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
				arg_1_0:updateHp(arg_1_0.skillRehp_ + arg_1_0:getHp())
				arg_1_0.fighterModel:playHPDeltas({
					{
						arg_1_0.skillRehp_,
						false
					}
				}, nil)
				arg_1_0:getFighterModel():stopAttackEffect_()

				arg_1_0.skillRehp_ = 0
			end
		end
	elseif arg_1_1.skillID == var_0_10 and arg_1_1.change_harm and arg_1_1.change_harm > 0 then
		arg_1_4 = arg_1_1.change_harm
	end

	return var_0_3.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.isAwakeTwiceType_ = false
	arg_2_0.isAwakeTwiceJudge_ = false
	arg_2_0.awakeTwiceTotalHarm_ = 0
end

function var_0_3.toDoPerFrames(arg_3_0)
	var_0_3.super.toDoPerFrames(arg_3_0)

	if not arg_3_0.isAwakeTwiceJudge_ then
		arg_3_0.isAwakeTwiceJudge_ = true

		if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
			arg_3_0.isAwakeTwiceType_ = true
		end
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if (arg_4_1.rootID_ == arg_4_0:getEnergySkillID() or arg_4_1.rootID_ == var_0_6) and arg_4_0.isAwakeTwiceType_ then
		local var_4_0 = arg_4_0:newBuff({
			var_0_9
		}, arg_4_0, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

		arg_4_0:addBuffs(var_4_0)
	end
end

function var_0_3.newBuff(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_1) do
		local var_5_1 = var_0_4.new({
			tableID = iter_5_1,
			start = var_0_1.ctx.battle.count,
			level = arg_5_0:getSkillLevelByID(arg_5_3),
			skillID = arg_5_3,
			fighter = arg_5_0,
			target = arg_5_2
		})

		var_5_1:setIsHit(true)
		var_5_1:setDirection(arg_5_0:getFighterModel():getFlipX())
		table.insert(var_5_0, var_5_1)
	end

	return var_5_0
end

function var_0_3.unitCollisionBreak(arg_6_0, arg_6_1)
	if arg_6_1.skillID == arg_6_0:getEnergySkillID() or arg_6_1.skillID == var_0_6 then
		if not arg_6_0.isAwakeTwiceType_ then
			arg_6_0.skillRehp_ = arg_6_0.skillRehp_ or 0

			if arg_6_0.skillRehp_ > 0 then
				arg_6_0:updateHp(arg_6_0.skillRehp_ + arg_6_0:getHp())
				arg_6_0.fighterModel:playHPDeltas({
					{
						arg_6_0.skillRehp_,
						false
					}
				}, nil)
				arg_6_0:getFighterModel():stopAttackEffect_()

				arg_6_0.skillRehp_ = 0
			end
		else
			arg_6_0:getFighterModel():stopAttackEffect_()
			arg_6_0:useAwakeTwiceSkill()
		end
	end
end

function var_0_3.useAwakeTwiceSkill(arg_7_0)
	local var_7_0 = arg_7_0:getBuffByID(var_0_9)

	if var_7_0 then
		arg_7_0:removeBuffs(var_7_0)
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_7_1 = arg_7_0:getTargets(var_0_10)

	if #var_7_1 > 0 then
		local var_7_2
		local var_7_3

		for iter_7_0, iter_7_1 in ipairs(var_7_1) do
			if not var_7_3 or var_7_3 > iter_7_1:getHp() then
				var_7_2 = iter_7_1
				var_7_3 = iter_7_1:getHp()
			end
		end

		local var_7_4 = arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) * arg_7_0.awakeTwiceTotalHarm_ * var_0_12 / #var_7_1
		local var_7_5 = arg_7_0:createAttackUnits(var_7_1, var_0_10)

		for iter_7_2, iter_7_3 in ipairs(var_7_5) do
			iter_7_3.change_harm = var_7_4

			if iter_7_3.target == var_7_2 then
				iter_7_3.change_harm = var_7_4 * var_0_13
			end

			table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
			table.insert(arg_7_0.records_.special_units, iter_7_3)
		end

		arg_7_0.awakeTwiceTotalHarm_ = 0
	end
end

return var_0_3
