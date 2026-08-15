local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = {
	40010964,
	40010965
}
local var_0_7 = 0.2
local var_0_8 = 0.1
local var_0_9 = 40010967
local var_0_10 = 40010968
local var_0_11 = 500
local var_0_12 = 10
local var_0_13 = 40010969

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
	arg_1_0:listenInfo("crit_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.purpleTarget = {}
	arg_2_0.curPurpleMaxCount = 0
	arg_2_0.purpleMaxCountJudge = false
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("attack_info")) do
			local var_3_0 = iter_3_1.fighter_

			if not arg_3_0.purpleTarget[var_3_0] and not var_3_0:isDeath() and var_3_0:getTeamType() == arg_3_0:getTeamType() and var_0_5:type(iter_3_1.rootID_) == var_0_2.AttackType.AD and (var_3_0:isHasBuffByID(var_0_9) or var_3_0:isHasBuffByID(var_0_10)) then
				arg_3_0.purpleTarget[var_3_0] = true
			elseif arg_3_0.purpleTarget[var_3_0] then
				var_3_0:removeBuffByID(var_0_9)
				var_3_0:removeBuffByID(var_0_10)

				arg_3_0.purpleTarget[var_3_0] = false
			end
		end
	end

	if arg_3_0:isDeath() then
		return
	end

	if not arg_3_0.purpleMaxCountJudge then
		arg_3_0.purpleMaxCountJudge = true
		arg_3_0.curPurpleMaxCount = var_0_12

		if arg_3_0.isStarPurple_ then
			arg_3_0.curPurpleMaxCount = var_0_12 + 2
		end
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_1 = {}

		for iter_3_2, iter_3_3 in ipairs(arg_3_0:getInfoByKey("crit_info")) do
			if iter_3_3.unit.fighter:getTeamType() == arg_3_0:getTeamType() and #arg_3_0:getBuffsByID(var_0_13) < arg_3_0.curPurpleMaxCount then
				local var_3_2 = arg_3_0:newBuff({
					var_0_13
				}, arg_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				arg_3_0:addBuffs(var_3_2)
			end
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = 0
	local var_4_1

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and var_4_0 < iter_4_1:getAttrByType(var_0_2.AttributeType.AGILE) then
			var_4_1 = iter_4_1
			var_4_0 = iter_4_1:getAttrByType(var_0_2.AttributeType.AGILE)
		end
	end

	return {
		var_4_1
	}
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == arg_5_0:getEnergySkillID() then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
			if not iter_5_1:isAffected() and not iter_5_1:isDeath() then
				arg_5_0:addEnergyBuff(iter_5_1)
			end
		end

		arg_5_0:die()
		arg_5_0:updateHp(0)
		arg_5_0:updateEnergyTo(0)
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

function var_0_3.addEnergyBuff(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_0:getEnergySkillID()
	local var_7_1 = 0

	if arg_7_0.isStarEnergy_ then
		var_7_1 = var_0_8
	end

	local var_7_2 = arg_7_0:getAD() * var_0_7
	local var_7_3 = arg_7_0:newBuff(var_0_6, arg_7_1, var_7_0)

	for iter_7_0 = 1, #var_7_3 do
		local var_7_4 = var_7_3[iter_7_0]

		if iter_7_0 == 1 then
			var_7_4.manualRevise = var_7_2
		elseif iter_7_0 == 2 then
			var_7_4.manualRevise = var_7_1 * var_7_4:getAttr()
		end
	end

	arg_7_1:addBuffs(var_7_3)
end

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	var_0_3.super.buffAddAction(arg_8_0, arg_8_1)

	if arg_8_1:getTableID() == var_0_10 and arg_8_0.isStarBlue_ then
		arg_8_1.manualRevise = var_0_11
	end
end

return var_0_3
