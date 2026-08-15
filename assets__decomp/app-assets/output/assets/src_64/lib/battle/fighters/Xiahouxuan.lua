local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xiahouxuan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 40010684
local var_0_6 = 0.0001
local var_0_7 = 0.0009
local var_0_8 = 0.0001
local var_0_9 = 0.0009
local var_0_10 = 300
local var_0_11 = 80010149
local var_0_12 = 40011496

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.extraAttr_ = 0
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == arg_2_0:getEnergySkillID() and arg_2_1.target:isDeath() then
		local var_2_0 = arg_2_0:newBuff({
			var_0_5
		}, arg_2_0, arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))

		arg_2_0:addBuffs(var_2_0)
	end
end

function var_0_3.buffAddAction(arg_3_0, arg_3_1)
	if arg_3_0.skinSkillID_ == var_0_11 and arg_3_1:dBuffType() == var_0_2.DBuffType.XUAN_YUN then
		local var_3_0 = arg_3_0:newBuff({
			var_0_12
		}, arg_3_1.target, arg_3_0:getLevel())

		arg_3_1.target:addBuffs(var_3_0)
	end
end

function var_0_3.selectTargetByTypeD1(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = 0
	local var_4_1

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and iter_4_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_4_1 or var_4_0 > iter_4_1:getHp() / iter_4_1:getHpLimit() or var_4_0 == iter_4_1:getHp() / iter_4_1:getHpLimit() and var_4_1:getHp() > iter_4_1:getHp()) then
			var_4_1 = iter_4_1
			var_4_0 = var_4_1:getHp() / var_4_1:getHpLimit()
		end
	end

	return {
		var_4_1
	}
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

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_4 > 0 and arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_6_0 = arg_6_1.target
		local var_6_1 = var_6_0:getHp() / var_6_0:getHpLimit()
		local var_6_2 = arg_6_0:getHp() / arg_6_0:getHpLimit()
		local var_6_3 = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

		if var_6_2 < var_6_1 and arg_6_0.extraAttr_ < var_0_10 then
			local var_6_4 = arg_6_4 * (var_0_7 * var_6_3 + var_0_6)

			arg_6_0.extraAttr_ = arg_6_0.extraAttr_ + var_6_4

			if arg_6_0.extraAttr_ > var_0_10 then
				arg_6_0.extraAttr_ = var_0_10
			end
		elseif var_6_1 < var_6_2 then
			arg_6_4 = arg_6_4 + arg_6_4 * (var_0_9 * var_6_3 + var_0_8)
		end
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.getHuJia(arg_7_0)
	return var_0_3.super.getHuJia(arg_7_0) + arg_7_0.extraAttr_
end

function var_0_3.getMoKang(arg_8_0)
	return var_0_3.super.getMoKang(arg_8_0) + arg_8_0.extraAttr_
end

return var_0_3
