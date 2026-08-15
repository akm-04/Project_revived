local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 2
local var_0_7 = 3
local var_0_8 = 40010422

function var_0_3.checkMove(arg_1_0)
	if arg_1_0.isEnterSkill_ then
		if var_0_1.ctx.battle.count < arg_1_0.hero_:enterDuration() then
			arg_1_0.isWalking_ = 1

			if not arg_1_0:isWalking() then
				arg_1_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
			elseif arg_1_0:isWalking() == 2 then
				local var_1_0 = arg_1_0:getFlipX() and -1 or 1

				arg_1_0:moveByX(arg_1_0.hero_:enterSpeed() * var_1_0)
			end

			if arg_1_0:getCurrentAnimation() ~= "run" then
				arg_1_0:modelWalk()
			end
		elseif not arg_1_0.playedEnterSkill_ then
			if arg_1_0:isWalking() ~= 3 then
				arg_1_0.preWalk_ = false
				arg_1_0.isWalking_ = false
				arg_1_0.behindWalk_ = false
				arg_1_0.playedEnterSkill_ = true
				arg_1_0.walk2Position_ = false

				if arg_1_0:getCurrentAnimation() == "run" then
					arg_1_0:getFighterModel():idle()
				end
			end
		elseif var_0_1.ctx.battle.count > arg_1_0.hero_:enterDelayDuration() then
			arg_1_0.isEnterSkill_ = nil
			arg_1_0.walk2Position_ = false
			arg_1_0.playedEnterSkill_ = false
		end

		return
	end

	var_0_3.super.checkMove(arg_1_0)
end

function var_0_3.setFormation(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	arg_2_0.isEnterSkill_ = arg_2_0:enterSkill() > 0 and arg_2_0:getSkillLevelByID(arg_2_0:enterSkill()) > 0

	if arg_2_0.isEnterSkill_ then
		arg_2_0.playedEnterSkill_ = false

		local var_2_0 = arg_2_0:getTeamType() == var_0_2.TeamType.A and 0 or var_0_2.STAGE_WIDTH

		arg_2_0:x(var_2_0)
		arg_2_0:y(var_0_2.STAGE_HEIGHT / 2 - 50 + arg_2_3 - 90 * (arg_2_2 % 2))

		return arg_2_2 + 1
	end

	return var_0_3.super.setFormation(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
end

function var_0_3.enterSkill(arg_3_0)
	return arg_3_0.hero_:enterSkill()
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) and arg_4_0.isStarPurple_ then
		local var_4_0 = var_0_4.new({
			tableID = var_0_8,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getSkillLevelByID(arg_4_1.skillID),
			skillID = arg_4_1.skillID,
			fighter = arg_4_0,
			target = arg_4_1.target
		})

		var_4_0:setIsHit(true)
		var_4_0:setDirection(arg_4_0:getFighterModel():getFlipX())
		arg_4_1.target:addBuffs({
			var_4_0
		})
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	if arg_5_1.skillID == arg_5_0:getEnergySkillID() and arg_5_1.target and arg_5_1.target:getSummonType() == var_0_2.summonMonsterType.Copy then
		if arg_5_0.isStarEnergy_ then
			arg_5_4 = arg_5_4 * var_0_7
		else
			arg_5_4 = arg_5_4 * var_0_6
		end
	elseif arg_5_0.isStarBlue_ and arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_5_5 = arg_5_5 + var_0_5:desc4NumStep(arg_5_1.skillID)[2] * arg_5_0:getSkillLevelByID(arg_5_1.skillID)
	end

	return var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
end

return var_0_3
