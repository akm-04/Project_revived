local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("GuyongDragon", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 10000893
local var_0_7 = 300

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.leftTime_ = var_0_7
	arg_1_0.isDieSkillUse_ = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() or arg_2_0.isDieSkillUse_ then
		return
	end

	arg_2_0.leftTime_ = arg_2_0.leftTime_ - 1

	if arg_2_0.leftTime_ <= 0 then
		arg_2_0:specialAttack()
	end
end

function var_0_3.createUnits(arg_3_0, arg_3_1)
	var_0_3.super.createUnits(arg_3_0, arg_3_1)

	if (arg_3_1 or arg_3_0.unitSkills_).rootID_ == var_0_6 then
		arg_3_0:updateHp(0)
		arg_3_0:die()
	end
end

function var_0_3.specialAttack(arg_4_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType or arg_4_0.isDieSkillUse_ then
		return
	end

	arg_4_0.isDieSkillUse_ = true

	local var_4_0 = false

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
		if not iter_4_1:isDeath() or iter_4_1:canReborn() then
			var_4_0 = true
		end
	end

	if not var_4_0 then
		arg_4_0:updateHp(0)
		arg_4_0:die()

		return
	end

	local var_4_1 = var_0_6
	local var_4_2 = var_0_5:sound(var_4_1)

	var_0_1.ctx.battle.pushSoundQueue(var_4_2)

	local var_4_3 = var_0_5:attackIndex(var_4_1)

	arg_4_0:playAttack(var_4_3)

	arg_4_0.unitSkills_ = var_0_4.new({
		fighter = arg_4_0,
		skillID = var_4_1
	})

	arg_4_0:beginAttackEnd(arg_4_0.unitSkills_)
end

function var_0_3.isAffected(arg_5_0)
	return true
end

function var_0_3.isAdImmortal(arg_6_0)
	return true
end

function var_0_3.isApImmortal(arg_7_0)
	return true
end

function var_0_3.updateNearestTarget(arg_8_0)
	if arg_8_0.summoner and not arg_8_0.summoner:isDeath() then
		local var_8_0, var_8_1 = arg_8_0.summoner:getPos()
		local var_8_2 = 0
		local var_8_3

		for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
			if not iter_8_1:isDeath() and not iter_8_1:isAffected() and iter_8_1 ~= arg_8_0 then
				local var_8_4, var_8_5 = iter_8_1:getPos()
				local var_8_6 = math.abs(var_8_0 - var_8_4)

				if var_8_2 <= var_8_6 then
					var_8_2 = var_8_6
					var_8_3 = iter_8_1
				end
			end
		end

		arg_8_0.nearestTarget_ = var_8_3
	else
		return var_0_3.super.updateNearestTarget(arg_8_0)
	end
end

return var_0_3
