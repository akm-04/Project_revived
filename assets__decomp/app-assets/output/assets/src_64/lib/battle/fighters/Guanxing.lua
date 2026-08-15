local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guanxing", var_0_1.ctx.battle.getRequire("BaseFighter"))

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

return var_0_3
