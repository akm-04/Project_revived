local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = 40012321
local var_0_8 = 20
local var_0_9 = 0.5
local var_0_10 = 50
local var_0_11 = 0
local var_0_12 = 40012317
local var_0_13 = 40012318
local var_0_14 = 40012319
local var_0_15 = 40012320
local var_0_16 = 120
local var_0_17 = 0
local var_0_18 = 4
local var_0_19 = 3
local var_0_20 = 20
local var_0_21 = 50

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.AddEnergyBuffTime = false
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and not arg_3_1.target:isDeath() then
		local var_3_0 = arg_3_1.target

		arg_3_0:removeGoodBuff(arg_3_1.target)
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if arg_4_1.rootID_ == arg_4_0:getEnergySkillID() then
		arg_4_0.AddEnergyBuffTime = false
	end
end

function var_0_3.removeGoodBuff(arg_5_0, arg_5_1)
	for iter_5_0 = #arg_5_1.buffs_, 1, -1 do
		local var_5_0 = arg_5_1.buffs_[iter_5_0]

		if var_5_0 and var_5_0:getBuffForm() == var_0_2.BuffForm.GAIN and var_5_0:canRemove() and var_5_0.leftCount_ < 3000 then
			arg_5_1:removeBuffs(var_5_0)
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_6_1.fighter:isHasBuffByID(var_0_7) and arg_6_1.fighter:getTeamType() ~= arg_6_0:getTeamType() and arg_6_1.target:getTeamType() == arg_6_0:getTeamType() and arg_6_4 > 0 then
		local var_6_0 = (var_0_8 + var_0_9 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)) * 0.01
		local var_6_1 = math.max(0, 1 - var_6_0)

		if arg_6_0.isStarBlue_ then
			local var_6_2 = var_0_20

			var_6_1 = math.max(0, var_6_1 - var_6_2 * 0.01)
		end

		arg_6_4 = arg_6_4 * var_6_1
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.energyActionBySpecialHero(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_1 == arg_7_0 then
		return
	end

	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_7_1:getTeamType() == arg_7_0:getTeamType() then
		local var_7_0 = var_0_10 + var_0_11 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

		if arg_7_0.isStarPurple_ then
			var_7_0 = var_0_21 + var_7_0
		end

		arg_7_0:updateEnergyBy(var_7_0)
	end

	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) > 0 and not arg_7_0.AddEnergyBuffTime and arg_7_1:getTeamType() == arg_7_0:getTeamType() then
		arg_7_0.extraBuffTime = var_0_16 + var_0_17 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)

		for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfTeam_) do
			if not iter_7_1:isDeath() and iter_7_1:isHasBuffByID(var_0_12) then
				local var_7_1 = iter_7_1:getBuffByID(var_0_12)

				var_7_1:setExtraTime(var_7_1.extraTime_ + arg_7_0.extraBuffTime)
			end
		end

		for iter_7_2, iter_7_3 in ipairs(arg_7_0.sideTeam_) do
			if not iter_7_3:isDeath() and iter_7_3:isHasBuffByID(var_0_13) then
				local var_7_2 = iter_7_3:getBuffByID(var_0_13)

				var_7_2:setExtraTime(var_7_2.extraTime_ + arg_7_0.extraBuffTime)
			end

			if not iter_7_3:isDeath() and iter_7_3:isHasBuffByID(var_0_14) then
				local var_7_3 = iter_7_3:getBuffByID(var_0_14)

				var_7_3:setExtraTime(var_7_3.extraTime_ + arg_7_0.extraBuffTime)
			end
		end

		arg_7_0.AddEnergyBuffTime = true
	end
end

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	var_0_3.super.buffAddAction(arg_8_0, arg_8_1)

	if arg_8_1:getTableID() == var_0_12 and arg_8_0.isStarEnergy_ then
		local var_8_0 = var_0_18

		arg_8_1:setExtraTime(arg_8_1.extraTime_ + var_8_0 * 30)
	elseif arg_8_1:getTableID() == var_0_13 and arg_8_0.isStarEnergy_ then
		local var_8_1 = var_0_18

		arg_8_1:setExtraTime(arg_8_1.extraTime_ + var_8_1 * 30)
	elseif arg_8_1:getTableID() == var_0_14 and arg_8_0.isStarEnergy_ then
		local var_8_2 = var_0_18

		arg_8_1:setExtraTime(arg_8_1.extraTime_ + var_8_2 * 30)
	elseif arg_8_1:getTableID() == var_0_15 and arg_8_0.isStarGreen_ then
		local var_8_3 = var_0_19

		arg_8_1:setExtraTime(arg_8_1.extraTime_ + var_8_3 * 30)
	end
end

return var_0_3
