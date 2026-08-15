local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = 40010070
local var_0_8 = 100
local var_0_9 = 60
local var_0_10 = {
	40010072,
	40010267
}

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("shanbi_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.isEnergy_ = false
	arg_2_0.target_ = nil
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getEnergySkillID() then
		local var_3_0 = arg_3_1.target
		local var_3_1 = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)

		arg_3_0.isEnergy_ = true

		var_3_0:setImmuneControl(true)

		arg_3_0.target_ = var_3_0
	end
end

function var_0_3.selectTargetByTypeD1(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = {}
	local var_4_1 = 0

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
		if not iter_4_1:isDeath() and iter_4_1 ~= arg_4_0 and var_4_1 <= iter_4_1:getAD() then
			if iter_4_1:getAD() == var_4_1 then
				table.insert(var_4_0, iter_4_1)
			else
				var_4_0 = {
					iter_4_1
				}
			end

			var_4_1 = iter_4_1:getAD()
		end
	end

	local var_4_2

	if #var_4_0 > 1 then
		var_4_2 = var_4_0[math.random(1, #var_4_0)]
	else
		var_4_2 = var_4_0[1]
	end

	return {
		var_4_2
	}
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1:getLevel()
	local var_5_1 = var_0_4:desc4NumStep(arg_5_1:getSkillID())[2]

	if arg_5_1:getSkillID() == arg_5_0:getEnergySkillID() and arg_5_0.isStarEnergy_ then
		arg_5_1.manualRevise = 0.1
	elseif arg_5_1:getSkillID() == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_5_0.isStarBlue_ then
		arg_5_1.manualRevise = var_5_1 * var_5_0 * -1
	elseif arg_5_1:getSkillID() == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) and arg_5_0.isStarPurple_ then
		arg_5_1.manualRevise = var_5_1 * var_5_0
	end
end

function var_0_3.toDoPerFrames(arg_6_0)
	var_0_3.super.toDoPerFrames(arg_6_0)

	if arg_6_0:isDeath() then
		return
	end

	if arg_6_0.isEnergy_ and var_0_1.ctx.battle.count % 30 < 1 and arg_6_0:getNearestTarget() then
		if not arg_6_0.target_:isDeath() then
			arg_6_0:updateEnergyTo(arg_6_0:getEnergy() - var_0_8)

			if arg_6_0:getEnergy() < 1 then
				for iter_6_0, iter_6_1 in ipairs(var_0_10) do
					arg_6_0.target_:removeBuffByID(iter_6_1)
				end

				arg_6_0.target_:setImmuneControl(false)

				arg_6_0.target_ = nil
				arg_6_0.isEnergy_ = false
			end
		else
			arg_6_0.target_:setImmuneControl(false)

			arg_6_0.isEnergy_ = false
			arg_6_0.target_ = nil
		end
	end

	for iter_6_2, iter_6_3 in ipairs(arg_6_0:getInfoByKey("shanbi_info")) do
		if iter_6_3.fighter:getTeamType() == arg_6_0:getTeamType() then
			local var_6_0 = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
			local var_6_1 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
			local var_6_2 = iter_6_3.fighter
			local var_6_3 = var_0_5.new({
				tableID = var_0_7,
				start = var_0_1.ctx.battle.count,
				level = var_6_0,
				skillID = var_6_1,
				fighter = arg_6_0,
				target = var_6_2
			})

			var_6_3:setIsHit(true)
			var_6_3:setDirection(arg_6_0:getFighterModel():getFlipX())
			var_6_2:addBuffs({
				var_6_3
			})
			arg_6_0:updateEnergyTo(arg_6_0:getEnergy() + var_0_9)
		end
	end
end

function var_0_3.getDMP(arg_7_0)
	return var_0_2.PERCENT_BASE
end

function var_0_3.checkEnergySkill(arg_8_0)
	if arg_8_0.isEnergy_ then
		return false
	elseif var_0_3.super.checkEnergySkill(arg_8_0) then
		if next(arg_8_0:selectTargetByTypeD1()) then
			return true
		else
			return false
		end
	else
		return false
	end
end

return var_0_3
