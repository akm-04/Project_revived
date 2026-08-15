local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Wenpin", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_2.tables.skill
local var_0_8 = 10000637
local var_0_9 = {
	10000622,
	10000627
}
local var_0_10 = 10000639
local var_0_11 = 3
local var_0_12 = 5
local var_0_13 = 0
local var_0_14 = 3
local var_0_15 = 40010590
local var_0_16 = 40010588
local var_0_17 = 10000617
local var_0_18 = 10000638

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.purpleEffectCount_ = 0
	arg_2_0.showPurpleCount_ = false
	arg_2_0.isSkillPowerUp_ = false
	arg_2_0.isBuffTimeLonger_ = false
	arg_2_0.isShowBuffAdd_ = false
	arg_2_0.isHarmSilence_ = false
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() or arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) <= 0 then
		return
	end

	if not arg_3_0.showPurpleCount_ then
		arg_3_0.showPurpleCount_ = true

		arg_3_0:updateStateNumber(arg_3_0.purpleEffectCount_)
	end

	for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
		local var_3_0 = iter_3_1.target

		if var_3_0 and var_3_0:getTeamType() ~= arg_3_0:getTeamType() and arg_3_0:isMoveBackBuff(iter_3_1) then
			arg_3_0.purpleEffectCount_ = math.min(var_0_12, arg_3_0.purpleEffectCount_ + 1)

			arg_3_0:updateStateNumber(arg_3_0.purpleEffectCount_)
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_0.isSkillPowerUp_ then
		if var_0_7:father(arg_4_1.skillID) == arg_4_0:getEnergySkillID() then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_4_1.skillID ~= var_0_8 and arg_4_1.skillID ~= var_0_9[1] and arg_4_1.skillID ~= var_0_9[2] then
				local var_4_0 = {}
				local var_4_1 = var_0_7:scope(var_0_8)

				for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
					if not iter_4_1:isDeath() and not iter_4_1:isAffected() and math.abs(iter_4_1:getX() - arg_4_1.target:getX()) <= var_4_1 * 0.5 then
						table.insert(var_4_0, iter_4_1)
					end
				end

				local var_4_2 = arg_4_0:createAttackUnits(var_4_0, var_0_8)

				for iter_4_2, iter_4_3 in ipairs(var_4_2) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
					table.insert(arg_4_0.records_.special_units, iter_4_3)
				end
			end
		elseif arg_4_1.skillID == var_0_10 then
			arg_4_0.isSkillPowerUp_ = false
			arg_4_0.isBuffTimeLonger_ = true
		end
	end

	if arg_4_1.skillID == var_0_18 and not arg_4_0.isShowBuffAdd_ then
		local var_4_3 = arg_4_0:newBuff({
			var_0_15
		}, arg_4_1.target, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

		arg_4_1.target:addBuffs(var_4_3)

		arg_4_0.isShowBuffAdd_ = true

		if arg_4_0.isSkillPowerUp_ then
			arg_4_0.isHarmSilence_ = true
		else
			arg_4_0.isHarmSilence_ = false
		end
	elseif arg_4_1.skillID == var_0_17 and arg_4_0.isHarmSilence_ then
		local var_4_4 = arg_4_0:newBuff({
			var_0_16
		}, arg_4_1.target, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

		arg_4_1.target:addBuffs(var_4_4)
	end
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	if arg_5_0.isBuffTimeLonger_ and arg_5_1:getSkillID() == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_5_1:setExtraTime(30)
	end
end

function var_0_3.beginAttack(arg_6_0)
	if arg_6_0:canAttack() and not arg_6_0:isDeath() then
		local var_6_0 = arg_6_0:getFrontSkill()

		if arg_6_0.purpleEffectCount_ >= var_0_11 and var_6_0 ~= arg_6_0:getPugongID() then
			arg_6_0.purpleEffectCount_ = arg_6_0.purpleEffectCount_ - var_0_11

			arg_6_0:updateStateNumber(arg_6_0.purpleEffectCount_)

			arg_6_0.isSkillPowerUp_ = true
		else
			arg_6_0.isSkillPowerUp_ = false
			arg_6_0.isBuffTimeLonger_ = false
			arg_6_0.isShowBuffAdd_ = false
		end
	end

	var_0_3.super.beginAttack(arg_6_0)
end

function var_0_3.getOrbOfFrontSkill(arg_7_0)
	local var_7_0 = var_0_3.super.getOrbOfFrontSkill(arg_7_0)
	local var_7_1 = var_0_7:buffOrb(var_7_0)

	if var_7_0 == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and var_7_1 > 0 and arg_7_0.isSkillPowerUp_ then
		return var_7_1
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_7_0)
end

function var_0_3.getHuJia(arg_8_0)
	local var_8_0 = arg_8_0.purpleEffectCount_ * (var_0_13 + var_0_14 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))

	return var_0_3.super.getHuJia(arg_8_0) + var_8_0
end

function var_0_3.newBuff(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_1) do
		local var_9_1 = var_0_4.new({
			tableID = iter_9_1,
			start = var_0_1.ctx.battle.count,
			level = arg_9_0:getSkillLevelByID(arg_9_3),
			skillID = arg_9_3,
			fighter = arg_9_0,
			target = arg_9_2
		})

		var_9_1:setIsHit(true)
		var_9_1:setDirection(arg_9_0:getFighterModel():getFlipX())
		table.insert(var_9_0, var_9_1)
	end

	return var_9_0
end

function var_0_3.isMoveBackBuff(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_1:getTableID()

	if var_0_6:type(var_10_0) == var_0_2.BuffType.MOVE and var_0_6:x(var_10_0) > 1 then
		return true
	else
		return false
	end
end

return var_0_3
