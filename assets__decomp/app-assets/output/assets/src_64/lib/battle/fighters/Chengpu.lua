local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Chengpu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 10000600
local var_0_7 = 10
local var_0_8 = 10
local var_0_9 = 15

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isNextForce_ = false
	arg_1_0.isEnergyReady_ = false
	arg_1_0.isGreenRush_ = false
	arg_1_0.greenReadyCount_ = 0
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_1.rootID_ == arg_2_0:getEnergySkillID() then
		arg_2_0.isEnergyReady_ = true
	elseif arg_2_1.rootID_ == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_2_0.greenReadyCount_ = var_0_8
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:acttionInBlack() then
		if arg_3_0.greenReadyCount_ > 0 then
			arg_3_0.greenReadyCount_ = arg_3_0.greenReadyCount_ - 1

			if arg_3_0.greenReadyCount_ == 0 then
				arg_3_0.greenRushCount_ = var_0_7
				arg_3_0.isGreenRush_ = true
			elseif not arg_3_0:isCreatingUnits() then
				arg_3_0.greenReadyCount_ = 0
			end
		end

		if arg_3_0.isGreenRush_ then
			arg_3_0:moveByX(var_0_9)

			arg_3_0.greenRushCount_ = arg_3_0.greenRushCount_ - 1

			if arg_3_0.greenRushCount_ == 0 then
				arg_3_0.isGreenRush_ = false
			elseif not arg_3_0:isCreatingUnits() then
				arg_3_0.greenRushCount_ = 0
				arg_3_0.isGreenRush_ = false
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) and arg_4_0.isEnergyReady_ then
		arg_4_0.isEnergyReady_ = false

		local var_4_0 = arg_4_0:getX() < arg_4_1.target:getX() and -1 or 1

		arg_4_0:x(arg_4_1.target:getX() + var_4_0 * 100)
		arg_4_0:y(arg_4_1.target:getY())
	elseif arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_4_0.isNextForce_ = true
	elseif arg_4_1.skillID == arg_4_0:getPugongID() and arg_4_0.isNextForce_ and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_1 = {
			arg_4_1.target
		}
		local var_4_2 = arg_4_0:createAttackUnits(var_4_1, var_0_6)

		for iter_4_0, iter_4_1 in ipairs(var_4_2) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end

		arg_4_0.isNextForce_ = false
	end
end

function var_0_3.selectTargetByTypeD1(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0
	local var_5_1
	local var_5_2 = {}
	local var_5_3 = var_0_5:scope(arg_5_0:getEnergySkillID())

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.targetTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() then
			local var_5_4 = iter_5_1.hero_:getMainAttr(var_0_2.AttributeType.STRENGTH)

			if not var_5_0 or var_5_4 < var_5_0 then
				var_5_1 = iter_5_1
				var_5_0 = var_5_4
			end
		end
	end

	table.insert(var_5_2, var_5_1)

	for iter_5_2, iter_5_3 in ipairs(arg_5_0.targetTeam_) do
		if not iter_5_3:isDeath() and not iter_5_3:isAffected() and iter_5_3 ~= var_5_1 and math.abs(iter_5_3:getX() - var_5_1:getX()) < var_5_3 * 0.5 then
			table.insert(var_5_2, iter_5_3)
		end
	end

	return var_5_2
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	if arg_6_1:getSkillID() == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_6_1:setForceTarget(arg_6_0)
	end
end

return var_0_3
