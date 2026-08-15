local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("XiahouFunnel", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 0.7
local var_0_5 = 81010049
local var_0_6 = 40011099
local var_0_7 = 10000992
local var_0_8 = 0.1
local var_0_9 = 0.005

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.skinWiseNum_ = 0
	arg_1_0.skinStrengthNum_ = 0
	arg_1_0.skinAgileNum_ = 0
	arg_1_0.records_.add_bullet = {}
end

function var_0_3.getAD(arg_2_0)
	if arg_2_0.summoner and not arg_2_0.summoner:isDeath() then
		return arg_2_0.summoner:getAD() * var_0_4
	end

	return var_0_3.super.getAD(arg_2_0)
end

function var_0_3.isAffected(arg_3_0)
	return true
end

function var_0_3.checkMove(arg_4_0)
	return false
end

function var_0_3.canAttack(arg_5_0)
	if arg_5_0.summoner and arg_5_0.summoner:isWalking() then
		return false
	end

	return var_0_3.super.canAttack(arg_5_0)
end

function var_0_3.unitAfterCreate(arg_6_0, arg_6_1, arg_6_2)
	var_0_3.super.unitAfterCreate(arg_6_0, arg_6_1, arg_6_2)

	for iter_6_0 = 1, #arg_6_2 do
		local var_6_0 = arg_6_2[iter_6_0].target

		if var_6_0 and not var_6_0:isDeath() then
			local var_6_1 = var_6_0:getX()

			arg_6_0:flipX(var_6_1 < arg_6_0:getX())

			break
		end
	end
end

function var_0_3.setSkinType(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	arg_7_0.skinStrengthNum_ = arg_7_1
	arg_7_0.skinWiseNum_ = arg_7_2
	arg_7_0.skinAgileNum_ = arg_7_3
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_4 > 0 and arg_8_0.summoner and arg_8_0.summoner.isSkinSkillOn_ and arg_8_0.summoner.skinSkillID_ == var_0_5 then
		if arg_8_0.skinStrengthNum_ > 0 then
			local var_8_0 = arg_8_1.target:getHpLimit() * 0.02 * arg_8_1.target:getADJianShang() * arg_8_0.skinStrengthNum_

			var_8_0 = var_8_0 > 5000 and 5000 or var_8_0
			arg_8_4 = arg_8_4 + var_8_0
		end

		if arg_8_0.skinWiseNum_ > 0 then
			arg_8_7 = arg_8_7 - 6 * arg_8_0.skinWiseNum_
		end

		if arg_8_0.skinAgileNum_ > 0 then
			local var_8_1 = {}

			for iter_8_0 = 1, arg_8_0.skinAgileNum_ do
				table.insert(var_8_1, var_0_6)
			end

			local var_8_2 = arg_8_0:createNewBuffs(var_8_1, arg_8_1.target, arg_8_0:getEnergySkillID())

			arg_8_1.target:addBuffs(var_8_2)
		end
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

function var_0_3.beginAttackEnd(arg_9_0, arg_9_1)
	var_0_3.super.beginAttackEnd(arg_9_0, arg_9_1)

	if arg_9_0.summoner and arg_9_0.summoner:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if arg_9_0.addBullet[tostring(var_0_1.ctx.battle.count)] then
				arg_9_0.summoner:updateBullet(1)
			end
		else
			local var_9_0 = var_0_8 + var_0_9 * arg_9_0.summoner:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)

			if var_0_2.weightedChoise({
				var_9_0,
				1 - var_9_0
			}) == 1 then
				arg_9_0.summoner:updateBullet(1)

				arg_9_0.records_.add_bullet[tostring(var_0_1.ctx.battle.count)] = true
			end
		end
	end
end

function var_0_3.setupReport(arg_10_0, arg_10_1)
	var_0_3.super.setupReport(arg_10_0, arg_10_1)

	arg_10_0.addBullet = arg_10_1.add_bullet
end

function var_0_3.writeReport(arg_11_0)
	local var_11_0 = var_0_3.super.writeReport(arg_11_0)

	var_11_0.add_bullet = arg_11_0.records_.add_bullet

	return var_11_0
end

return var_0_3
