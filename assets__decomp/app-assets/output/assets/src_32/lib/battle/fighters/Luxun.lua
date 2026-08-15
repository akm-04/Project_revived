local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Luxun", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.dbuff
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 10000193
local var_0_8 = 25000
local var_0_9 = 20010127
local var_0_10 = 10000201
local var_0_11 = 10010061
local var_0_12 = {
	20010128,
	20010129
}
local var_0_13 = 2

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.currentTarget = nil
	arg_1_0.extraACKSpeed = 0
	arg_1_0.count = false
	arg_1_0.blueSkillExist = false
	arg_1_0.nearestTarget = nil
	arg_1_0.energyTarget = nil
	arg_1_0.energyHurtCount = 0
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)

	if not arg_2_0.count then
		if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
			arg_2_0.blueSkillExist = true
		end

		if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			arg_2_0.purpleSkillExist = true
		end

		arg_2_0.energyExtraHarm = var_0_6:init(var_0_10) + var_0_6:step(var_0_10) * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
		arg_2_0.count = true
	end

	if arg_2_0:acttionInBlack() and not arg_2_0:isDeath() then
		local function var_2_0(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
			local var_3_0 = {}

			for iter_3_0, iter_3_1 in ipairs(arg_3_0) do
				local var_3_1 = var_0_5.new({
					tableID = iter_3_1,
					start = var_0_1.ctx.battle.count,
					level = arg_3_2,
					skillID = arg_3_1,
					fighter = arg_2_0,
					target = arg_3_3
				})

				var_3_1:setYongJiu()
				table.insert(var_3_0, var_3_1)
			end

			return var_3_0
		end

		if arg_2_0.purpleSkillExist then
			local var_2_1 = false

			if not arg_2_0.nearestTarget then
				arg_2_0.nearestTarget = arg_2_0:getNearestTarget()
				var_2_1 = true
			else
				local var_2_2 = arg_2_0:getNearestTarget()

				if arg_2_0.nearestTarget ~= var_2_2 then
					arg_2_0.nearestTarget:removeBuffByID(var_0_12[1])
					arg_2_0.nearestTarget:removeBuffByID(var_0_12[2])

					arg_2_0.nearestTarget = var_2_2
					var_2_1 = true
				end
			end

			if var_2_1 and arg_2_0.nearestTarget then
				local var_2_3 = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
				local var_2_4 = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
				local var_2_5 = var_2_0(var_0_12, var_2_3, var_2_4, arg_2_0.nearestTarget)

				arg_2_0.nearestTarget:addBuffs(var_2_5)
			end
		end
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if arg_4_1.rootID_ == arg_4_0:getEnergySkillID() then
		arg_4_0.energyTarget = nil
	end
end

function var_0_3.calculateUnitData(arg_5_0, arg_5_1)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.calculateUnitData(arg_5_0, arg_5_1)

	if var_0_0.table.indexof(var_0_6:children(arg_5_0:getEnergySkillID()), arg_5_1.skillID) then
		local var_5_6 = arg_5_1.target

		if not arg_5_0.energyTarget then
			arg_5_0.energyTarget = var_5_6
			arg_5_0.energyHurtCount = 0
		elseif arg_5_0.energyTarget == var_5_6 then
			arg_5_0.energyHurtCount = arg_5_0.energyHurtCount + 1
		else
			arg_5_0.energyTarget = var_5_6
			arg_5_0.energyHurtCount = 0
		end

		var_5_2 = var_5_2 + arg_5_0.energyHurtCount * arg_5_0.energyExtraHarm
	end

	if arg_5_0.isSkinSkillOn_ and var_5_2 > 0 and arg_5_1.target then
		local var_5_7 = 0
		local var_5_8 = arg_5_0:getAttrByType(var_0_2.AttributeType.AGILE) - arg_5_1.target:getAttrByType(var_0_2.AttributeType.AGILE)

		if var_5_8 > 0 then
			var_5_7 = var_5_8 * var_0_13 * arg_5_1.target:getADJianShang()
		end

		var_5_2 = var_5_2 + var_5_7
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_1.skillID == var_0_7 then
		arg_6_0:removeGoodBuff(arg_6_1.target)
	end

	if arg_6_0.blueSkillExist and (arg_6_1.skillID == var_0_11 or var_0_0.table.indexof(var_0_6:children(arg_6_0:getEnergySkillID()), arg_6_1.skillID)) then
		local var_6_0 = var_0_4:init(var_0_9)
		local var_6_1 = var_0_4:step(var_0_9)
		local var_6_2 = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

		if not arg_6_0.currentTarget then
			arg_6_0.currentTarget = arg_6_1.target
			arg_6_0.extraACKSpeed = math.min(arg_6_0.extraACKSpeed + var_6_0 + var_6_1 * var_6_2, var_0_8)
		elseif arg_6_0.currentTarget ~= arg_6_1.target then
			arg_6_0.extraACKSpeed = 0
			arg_6_0.currentTarget = arg_6_1.target
			arg_6_0.extraACKSpeed = math.min(arg_6_0.extraACKSpeed + var_6_0 + var_6_1 * var_6_2, var_0_8)
		else
			arg_6_0.extraACKSpeed = math.min(arg_6_0.extraACKSpeed + var_6_0 + var_6_1 * var_6_2, var_0_8)
		end
	end
end

function var_0_3.getCurrentAckSpeed(arg_7_0)
	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) < 1 then
		return var_0_3.super.getCurrentAckSpeed(arg_7_0)
	end

	local var_7_0 = arg_7_0:getAttrByType(var_0_2.AttributeType.ACK_SPEED) + arg_7_0.extraACKSpeed
	local var_7_1 = math.min(var_7_0 / var_0_2.DECIMAL_BASE, var_0_2.MAX_ATTACK_SPEED)

	return (math.max(var_7_1, var_0_2.MIN_ATTACK_SPEED))
end

function var_0_3.removeGoodBuff(arg_8_0, arg_8_1)
	for iter_8_0 = #arg_8_1.buffs_, 1, -1 do
		local var_8_0 = arg_8_1.buffs_[iter_8_0]

		if var_8_0 and var_8_0:getBuffForm() == var_0_2.BuffForm.GAIN then
			arg_8_1:removeBuffs(var_8_0)
		end
	end
end

function var_0_3.die(arg_9_0)
	var_0_3.super.die(arg_9_0)

	if arg_9_0.nearestTarget then
		arg_9_0.nearestTarget:removeBuffByID(var_0_12[1])
		arg_9_0.nearestTarget:removeBuffByID(var_0_12[2])

		arg_9_0.nearestTarget = nil
	end
end

return var_0_3
