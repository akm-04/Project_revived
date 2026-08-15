local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = math
local var_0_8 = 80
local var_0_9 = 10000368
local var_0_10 = 40010077
local var_0_11 = 40010076
local var_0_12 = 0.1
local var_0_13 = 0.002

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("shanbi_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.inheritCount_ = 0
	arg_2_0.isEnergy_ = false
	arg_2_0.target_ = nil
end

function var_0_3.selectTargetByTypeD1(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = {}
	local var_3_1
	local var_3_2 = arg_3_0:getTeamType() == var_0_2.TeamType.A and 1 or -1

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_3_3 = iter_3_1:getX() * var_3_2

			if not var_3_1 then
				var_3_0 = {
					iter_3_1
				}
				var_3_1 = var_3_3
			elseif var_3_1 <= var_3_3 then
				if var_3_3 == var_3_1 then
					table.insert(var_3_0, iter_3_1)
				else
					var_3_0 = {
						iter_3_1
					}
					var_3_1 = var_3_3
				end
			end
		end
	end

	local var_3_4

	if #var_3_0 > 1 then
		var_3_4 = var_3_0[var_0_7.random(1, #var_3_0)]
	else
		var_3_4 = var_3_0[1]
	end

	return {
		var_3_4
	}
end

function var_0_3.buffAddAction(arg_4_0, arg_4_1)
	if arg_4_1:getSkillID() == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_4_0.isStarBlue_ then
		arg_4_1:setExtraTime(90)
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	if arg_5_0.isStarEnergy_ and arg_5_1.skillID == var_0_9 then
		arg_5_5 = arg_5_5 + arg_5_0:getSkillLevelByID(arg_5_0:getEnergySkillID()) * var_0_4:desc4NumStep(arg_5_0:getEnergySkillID())[2]
	end

	return var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
end

function var_0_3.inherit(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_6_0 < 1 then
		return
	end

	local var_6_1 = arg_6_0:getInheritTarget(arg_6_1)

	if not var_6_1 then
		return
	end

	local var_6_2 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)

	if not var_6_1:isDeath() and not var_6_1:isAffected() then
		local var_6_3 = var_0_5.new({
			tableID = var_0_11,
			start = var_0_1.ctx.battle.count,
			level = var_6_0,
			skillID = var_6_2,
			fighter = arg_6_0,
			target = var_6_1
		})

		var_6_3:setIsHit(true)
		var_6_3:setYongJiu()
		var_6_3:setDirection(arg_6_0:getFighterModel():getFlipX())
		arg_6_0:setBuffAttr(var_6_3, arg_6_1)
		var_6_1:addBuffs({
			var_6_3
		})
	end
end

function var_0_3.getInheritTarget(arg_7_0, arg_7_1)
	local var_7_0
	local var_7_1

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfTeam_) do
		local var_7_2 = var_0_7.abs(iter_7_1:getX() - arg_7_1:getX())

		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and (not var_7_0 or var_7_2 < var_7_1) then
			var_7_0 = iter_7_1
			var_7_1 = var_7_2
		end
	end

	return var_7_0
end

function var_0_3.setBuffAttr(arg_8_0, arg_8_1, arg_8_2)
	arg_8_0.inheritCount_ = arg_8_0.inheritCount_ + 1

	local var_8_0 = arg_8_2:getShanBi()
	local var_8_1 = var_0_12 + arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_13

	if arg_8_0.isStarPurple_ then
		var_8_1 = var_8_1 + 0.1
	end

	arg_8_1.manualRevise = var_8_0 * var_8_1
end

function var_0_3.deathFeedback(arg_9_0, arg_9_1)
	var_0_3.super.deathFeedback(arg_9_0, arg_9_1)

	if arg_9_1:getTeamType() == arg_9_0:getTeamType() and arg_9_0.inheritCount_ < 2 then
		arg_9_0:inherit(arg_9_1)
	end
end

function var_0_3.applySingleUnit(arg_10_0, arg_10_1)
	var_0_3.super.applySingleUnit(arg_10_0, arg_10_1)

	if arg_10_1.skillID == arg_10_0:getEnergySkillID() then
		arg_10_0.target_ = arg_10_1.target

		arg_10_0.target_:setImmuneControl(true)

		arg_10_0.isEnergy_ = true
	end
end

function var_0_3.toDoPerFrames(arg_11_0)
	if arg_11_0:isDeath() then
		return
	end

	if arg_11_0.isEnergy_ then
		if var_0_1.ctx.battle.count % 30 < 1 and arg_11_0:getNearestTarget() then
			if not arg_11_0.target_:isDeath() then
				arg_11_0:updateEnergyTo(arg_11_0:getEnergy() - var_0_8)

				if arg_11_0:getEnergy() < 1 then
					arg_11_0.target_:removeBuffByID(var_0_10)
					arg_11_0.target_:setImmuneControl(false)

					arg_11_0.target_ = nil
					arg_11_0.isEnergy_ = false
				end
			else
				arg_11_0.target_:removeBuffByID(var_0_10)
				arg_11_0.target_:setImmuneControl(false)

				arg_11_0.isEnergy_ = false
				arg_11_0.target_ = nil
			end
		end

		for iter_11_0, iter_11_1 in ipairs(arg_11_0:getInfoByKey("shanbi_info")) do
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and iter_11_1.target == arg_11_0.target_ then
				local var_11_0 = {
					arg_11_0.target_
				}
				local var_11_1 = arg_11_0:createAttackUnits(var_11_0, var_0_9)

				for iter_11_2, iter_11_3 in ipairs(var_11_1) do
					table.insert(arg_11_0.moveAttackUnits_, iter_11_3)
					table.insert(arg_11_0.records_.special_units, iter_11_3)
				end
			end
		end
	end
end

function var_0_3.getDMP(arg_12_0)
	return var_0_2.PERCENT_BASE
end

function var_0_3.checkEnergySkill(arg_13_0)
	if arg_13_0.isEnergy_ then
		return false
	elseif var_0_3.super.checkEnergySkill(arg_13_0) then
		if next(arg_13_0:selectTargetByTypeD1()) then
			return true
		else
			return false
		end
	else
		return false
	end
end

return var_0_3
