local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhuhuan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 40012051
local var_0_5 = 40012045
local var_0_6 = 0.2
local var_0_7 = 0.005
local var_0_8 = {
	40012046
}
local var_0_9 = {
	40012047,
	40012048
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
	arg_1_0:listenInfo("harm_info")

	arg_1_0.energyTarget = nil
end

function var_0_3.checkEnergySkill(arg_2_0)
	if arg_2_0.energyTarget and not arg_2_0.energyTarget:isDeath() then
		return false
	else
		return var_0_3.super.checkEnergySkill(arg_2_0)
	end
end

function var_0_3.buffAddAction(arg_3_0, arg_3_1)
	if arg_3_1:getTableID() == var_0_4 then
		arg_3_0.energyTarget = arg_3_1.target
	end
end

function var_0_3.buffRemoveAction(arg_4_0, arg_4_1)
	if arg_4_1:getTableID() == var_0_4 and arg_4_0.energyTarget == arg_4_1.target then
		arg_4_0.energyTarget = nil
	end
end

function var_0_3.getTargets(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_0.energyTarget and not arg_5_0.energyTarget:isDeath() then
		return {
			arg_5_0.energyTarget
		}
	else
		return var_0_3.super.getTargets(arg_5_0, arg_5_1, arg_5_2)
	end
end

function var_0_3.getOrbOfFrontSkill(arg_6_0)
	local var_6_0 = var_0_3.super.getOrbOfFrontSkill(arg_6_0)

	if var_6_0 == arg_6_0:getPugongID() and arg_6_0.energyTarget and arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
		var_6_0 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
	end

	return var_6_0
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	local var_7_0 = arg_7_1.target

	if arg_7_4 > 0 and var_7_0:isHasBuffByID(var_0_5) then
		arg_7_4 = arg_7_4 * (1 + var_0_6 + var_0_7 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.updateUnitDataByTarget(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7 = var_0_3.super.updateUnitDataByTarget(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_4 > 0 and arg_8_1.fighter:isHasBuffByID(var_0_5) then
		arg_8_4 = 0
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

function var_0_3.applySingleUnit(arg_9_0, arg_9_1)
	var_0_3.super.applySingleUnit(arg_9_0, arg_9_1)

	if arg_9_0.addXuanyunBuff and arg_9_1.basicHarm > 0 then
		local var_9_0 = arg_9_0:createNewBuffs(var_0_8, arg_9_1.target, arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		arg_9_1.target:addBuffs(var_9_0)

		arg_9_0.addXuanyunBuff = false
	end

	if arg_9_1.skillID == arg_9_0:getEnergySkillID() then
		arg_9_0:energySkill(arg_9_1)
	end
end

function var_0_3.energySkill(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_1.target
	local var_10_1 = var_10_0:getBuffs()

	for iter_10_0 = #var_10_1, 1, -1 do
		local var_10_2 = var_10_1[iter_10_0]

		if var_10_2 and (var_10_2:getBuffForm() == var_0_2.BuffForm.GAIN or var_10_2:getType() == var_0_2.BuffType.REVIVIE) and var_10_2:canRemove() then
			var_10_0:removeBuffByID(var_10_2:getTableID())
		end
	end
end

function var_0_3.toDoPerFrames(arg_11_0)
	if not arg_11_0:isDeath() and arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_11_0, iter_11_1 in ipairs(arg_11_0:getInfoByKey("harm_info")) do
			if iter_11_1.fighter == arg_11_0 then
				local var_11_0 = iter_11_1.harm

				if math.floor(var_11_0) % 2 == 1 then
					arg_11_0.addXuanyunBuff = true
				else
					local var_11_1 = arg_11_0:createNewBuffs(var_0_9, arg_11_0, arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

					arg_11_0:addBuffs(var_11_1)
				end
			end
		end
	end
end

return var_0_3
