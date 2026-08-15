local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = math
local var_0_8 = 40010069
local var_0_9 = 0.5
local var_0_10 = 0.01

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.inheritCount_ = 0
end

function var_0_3.inherit(arg_2_0, arg_2_1)
	local var_2_0 = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_2_0 < 1 then
		return
	end

	local var_2_1 = arg_2_0:getInheritTarget(arg_2_1)

	if not var_2_1 then
		return
	end

	local var_2_2 = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)

	if not var_2_1:isDeath() and not var_2_1:isAffected() then
		local var_2_3 = var_0_5.new({
			tableID = var_0_8,
			start = var_0_1.ctx.battle.count,
			level = var_2_0,
			skillID = var_2_2,
			fighter = arg_2_0,
			target = var_2_1
		})

		var_2_3:setIsHit(true)
		var_2_3:setDirection(arg_2_0:getFighterModel():getFlipX())
		arg_2_0:setBuffAttr(var_2_3, arg_2_1)
		var_2_1:addBuffs({
			var_2_3
		})
	end
end

function var_0_3.getInheritTarget(arg_3_0, arg_3_1)
	local var_3_0
	local var_3_1

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
		local var_3_2 = var_0_7.abs(iter_3_1:getX() - arg_3_1:getX())

		if not iter_3_1:isDeath() and not iter_3_1:isAffected() and (not var_3_0 or var_3_2 < var_3_1) then
			var_3_0 = iter_3_1
			var_3_1 = var_3_2
		end
	end

	return var_3_0
end

function var_0_3.setBuffAttr(arg_4_0, arg_4_1, arg_4_2)
	arg_4_0.inheritCount_ = arg_4_0.inheritCount_ + 1

	local var_4_0 = arg_4_2:getHuJia()
	local var_4_1 = var_0_9 + arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_10

	if arg_4_0.isStarPurple_ then
		var_4_1 = var_4_1 + 0.1
	end

	arg_4_1.manualRevise = var_4_0 * var_4_1
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1:getLevel()
	local var_5_1 = var_0_4:desc4NumStep(arg_5_1:getSkillID())[2]

	if arg_5_1:getSkillID() == arg_5_0:getEnergySkillID() and arg_5_0.isStarEnergy_ then
		arg_5_1.manualRevise = var_5_1 * var_5_0
	elseif arg_5_1:getSkillID() == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_5_0.isStarBlue_ then
		arg_5_1.manualRevise = var_5_1 * var_5_0
	end
end

function var_0_3.deathFeedback(arg_6_0, arg_6_1)
	var_0_3.super.deathFeedback(arg_6_0, arg_6_1)

	if arg_6_1:getTeamType() == arg_6_0:getTeamType() and arg_6_0.inheritCount_ < 2 then
		arg_6_0:inherit(arg_6_1)
	end
end

return var_0_3
