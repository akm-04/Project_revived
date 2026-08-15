local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Wanshengnvwu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.model
local var_0_8 = 10000137

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7 = var_0_3.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)

	if var_0_5:father(arg_1_1.skillID) == arg_1_0:getEnergySkillID() and arg_1_4 > 0 then
		local var_1_0 = arg_1_1.target

		if var_1_0:isApUnable() and not var_1_0:isAdUnable() then
			arg_1_4 = 1.5 * arg_1_4
		end
	end

	return arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7
end

function var_0_3.createAttackUnits(arg_2_0, arg_2_1, arg_2_2)
	if arg_2_2 == var_0_8 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and (next(arg_2_1) == nil or not arg_2_1[1]:isApUnable() or not not arg_2_1[1]:isAdUnable()) and arg_2_0.unitSkills_ then
		arg_2_0.unitSkills_:popQueue()
	end

	return var_0_3.super.createAttackUnits(arg_2_0, arg_2_1, arg_2_2)
end

function var_0_3.checkMove(arg_3_0)
	if arg_3_0.isEnterSkill_ then
		if var_0_1.ctx.battle.count < arg_3_0.hero_:enterDuration() then
			arg_3_0.isWalking_ = 1

			if not arg_3_0:isWalking() then
				arg_3_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
			elseif arg_3_0:isWalking() == 2 then
				local var_3_0 = arg_3_0:getFlipX() and -1 or 1

				arg_3_0:moveByX(arg_3_0.hero_:enterSpeed() * var_3_0)
			end

			if arg_3_0:getCurrentAnimation() ~= "run" then
				arg_3_0:modelWalk()
			end
		elseif not arg_3_0.playedEnterSkill_ then
			if arg_3_0:isWalking() ~= 3 then
				arg_3_0.preWalk_ = false
				arg_3_0.isWalking_ = false
				arg_3_0.behindWalk_ = false
				arg_3_0.playedEnterSkill_ = true
				arg_3_0.walk2Position_ = false

				if arg_3_0:getCurrentAnimation() == "run" then
					arg_3_0:getFighterModel():idle()
				end
			end
		elseif var_0_1.ctx.battle.count > arg_3_0.hero_:enterDelayDuration() then
			arg_3_0.isEnterSkill_ = nil
			arg_3_0.walk2Position_ = false
			arg_3_0.playedEnterSkill_ = false
		end

		return
	end

	var_0_3.super.checkMove(arg_3_0)
end

function var_0_3.setFormation(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	arg_4_0.isEnterSkill_ = arg_4_0:enterSkill() > 0 and arg_4_0:getSkillLevelByID(arg_4_0:enterSkill()) > 0

	if arg_4_0.isEnterSkill_ then
		arg_4_0.playedEnterSkill_ = false

		local var_4_0 = arg_4_0:getTeamType() == var_0_2.TeamType.A and 0 or var_0_2.STAGE_WIDTH

		arg_4_0:x(var_4_0)
		arg_4_0:y(var_0_2.STAGE_HEIGHT / 2 - 50 + arg_4_3 - 90 * (arg_4_2 % 2))

		return arg_4_2 + 1
	end

	return var_0_3.super.setFormation(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
end

function var_0_3.enterSkill(arg_5_0)
	return arg_5_0.hero_:enterSkill()
end

return var_0_3
