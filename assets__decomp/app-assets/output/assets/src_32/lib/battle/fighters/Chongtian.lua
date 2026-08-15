local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Chongtian", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 0.05
local var_0_7 = -0.15
local var_0_8 = -0.05
local var_0_9 = -0.05
local var_0_10 = 40010656
local var_0_11 = 40010665
local var_0_12 = 0.003
local var_0_13 = 30

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.recoverCount = var_0_13
	arg_1_0.energyCost = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if not arg_2_0:isDeath() and not var_0_1.ctx.battle.teamBEnd then
		arg_2_0.recoverCount = arg_2_0.recoverCount - 1

		if arg_2_0.recoverCount <= 0 then
			arg_2_0.recoverCount = var_0_13

			arg_2_0:hpDeal(arg_2_0:getHpLimit() * var_0_12)
		end
	end
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if arg_3_1.rootID_ == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_3_0:hpDeal(arg_3_0:getHpLimit() * var_0_8)
	elseif arg_3_1.rootID_ == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_3_0:hpDeal(arg_3_0:getHpLimit() * var_0_9)
	elseif arg_3_1.rootID_ == arg_3_0:getEnergySkillID() then
		arg_3_0:removeDbuff()
		arg_3_0:hpDeal(arg_3_0:getHpLimit() * var_0_7, true)
	end
end

function var_0_3.removeDbuff(arg_4_0)
	for iter_4_0 = #arg_4_0.buffs_, 1, -1 do
		local var_4_0 = arg_4_0.buffs_[iter_4_0]

		if var_4_0 and var_4_0:getBuffForm() == var_0_2.BuffForm.DEBUFF then
			arg_4_0:removeBuffs(var_4_0)
		end
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == arg_5_0:getEnergySkillID() then
		if arg_5_1.target:isDeath() then
			arg_5_0:hpDeal(arg_5_0.energyCost)
		elseif not arg_5_1.isShanBi then
			arg_5_0:hpDeal(arg_5_0.energyCost / 2)
		end

		arg_5_0.energyCost = 0
	end
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	if arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_6_1.target:isHasBuffByID(var_0_11) then
		arg_6_4 = arg_6_4 * 2
	end

	return var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
end

function var_0_3.buffAddAction(arg_7_0, arg_7_1)
	if arg_7_1:getTableID() == var_0_10 then
		if arg_7_1.target:isHasBuffByID(var_0_11) then
			arg_7_1:setExtraTime(90)
			arg_7_1.target:removeBuffByID(var_0_11)
		else
			local var_7_0 = var_0_4.new({
				level = 1,
				tableID = var_0_11,
				start = var_0_1.ctx.battle.count,
				skillID = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
				fighter = arg_7_0,
				target = arg_7_1.target
			})

			var_7_0.target:addBuffs({
				var_7_0
			})
		end
	end
end

function var_0_3.getCurrentAckSpeed(arg_8_0)
	local var_8_0 = var_0_3.super.getCurrentAckSpeed(arg_8_0)
	local var_8_1 = arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	local var_8_2 = var_0_5:init(var_8_1) + var_0_5:step(var_8_1) * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
	local var_8_3 = var_8_0 + math.floor(100 - arg_8_0:getHp() / arg_8_0:getHpLimit() * 100) * var_8_2 / var_0_2.DECIMAL_BASE

	return math.min(var_8_3, var_0_2.MAX_ATTACK_SPEED)
end

function var_0_3.hpDeal(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_0:getHp()
	local var_9_1 = arg_9_0:getHpLimit()

	if arg_9_1 > 0 then
		var_9_0 = math.min(var_9_1, var_9_0 + arg_9_1)
	else
		local var_9_2 = var_0_6 * var_9_1

		if var_9_2 < var_9_0 then
			var_9_0 = math.max(var_9_2, var_9_0 + arg_9_1)
		end

		if arg_9_2 then
			arg_9_0.energyCost = math.max(0, arg_9_0:getHp() - var_9_0)
		end
	end

	arg_9_0:updateHp(var_9_0)
end

return var_0_3
