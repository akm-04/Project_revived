local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangliao", var_0_1.ctx.battle.requireFighter("Zhangliao"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 40
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_2.tables.skill
local var_0_8 = 6177
local var_0_9 = 103
local var_0_10 = {
	40010492
}

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.extraAckCount_ = 0
end

function var_0_3.getAD(arg_3_0)
	local var_3_0 = 0

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		var_3_0 = arg_3_0:getExtraAD()
	end

	return var_0_3.super.getAD(arg_3_0) + var_3_0
end

function var_0_3.getExtraAD(arg_4_0)
	local var_4_0 = var_0_8 + var_0_9 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)
	local var_4_1 = 0

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
		local var_4_2 = false

		if not iter_4_1:isDeath() and iter_4_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_4_3 = iter_4_1:getBuffs()

			for iter_4_2, iter_4_3 in ipairs(var_4_3) do
				local var_4_4 = iter_4_3:getDHarm()

				if var_4_4 > 0 then
					var_4_1 = var_4_4 * 0.25

					if var_4_0 <= var_4_1 then
						var_4_2 = true

						break
					end
				end
			end
		end

		if var_4_2 then
			break
		end
	end

	return math.min(var_4_0, var_4_1)
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("attack_info")) do
			local var_5_0 = iter_5_1.fighter_
			local var_5_1 = iter_5_1.rootID_

			if var_5_0:getTeamType() == arg_5_0:getTeamType() and var_0_7:father(var_5_1) == var_5_0:getEnergySkillID() and var_5_0:getSummonType() == var_0_2.summonMonsterType.None then
				local var_5_2 = arg_5_0:newBuff(var_0_10, arg_5_0, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

				arg_5_0:addBuffs(var_5_2)
			end
		end
	end

	if var_0_1.ctx.battle.count % 5 == 0 then
		arg_5_0.extraAckCount_ = 0

		for iter_5_2, iter_5_3 in ipairs(arg_5_0.sideTeam_) do
			if not iter_5_3:isDeath() and arg_5_0:isCannotMove(iter_5_3) then
				arg_5_0.extraAckCount_ = arg_5_0.extraAckCount_ + 1
			end
		end
	end
end

function var_0_3.isCannotMove(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1:getBuffs()

	for iter_6_0, iter_6_1 in ipairs(var_6_0) do
		if var_0_6:pause(iter_6_1:getTableID()) then
			return true
		end
	end

	return false
end

function var_0_3.getCurrentAckSpeed(arg_7_0)
	if arg_7_0.extraAckCount_ == 0 then
		return var_0_3.super.getCurrentAckSpeed(arg_7_0)
	end

	local var_7_0 = arg_7_0:getAttrByType(var_0_2.AttributeType.ACK_SPEED) + arg_7_0.extraAckCount_ * var_0_5 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
	local var_7_1 = math.min(var_7_0 / var_0_2.DECIMAL_BASE, var_0_2.MAX_ATTACK_SPEED)

	return (math.max(var_7_1, var_0_2.MIN_ATTACK_SPEED))
end

function var_0_3.newBuff(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
		local var_8_1 = var_0_4.new({
			tableID = iter_8_1,
			start = var_0_1.ctx.battle.count,
			level = arg_8_0:getSkillLevelByID(arg_8_3),
			skillID = arg_8_3,
			fighter = arg_8_0,
			target = arg_8_2
		})

		var_8_1:setIsHit(true)
		var_8_1:setDirection(arg_8_0:getFighterModel():getFlipX())
		table.insert(var_8_0, var_8_1)
	end

	return var_8_0
end

return var_0_3
