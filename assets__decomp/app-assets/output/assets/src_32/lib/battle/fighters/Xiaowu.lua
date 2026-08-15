local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 300
local var_0_7 = {
	40010115,
	40010116,
	40010117
}
local var_0_8 = 0
local var_0_9 = 0.5
local var_0_10 = 0
local var_0_11 = 0.001
local var_0_12 = 90

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("magic_crit_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.purpleCount = nil
	arg_2_0.purpleCDCount = nil
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_3_0.purpleCount = var_0_6
	end

	if arg_3_1.skillID == arg_3_0:getEnergySkillID() then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
			if not iter_3_1:isAffected() and not iter_3_1:isDeath() then
				arg_3_0:addEnergyBuff(iter_3_1)
			end
		end

		arg_3_0:die()
		arg_3_0:updateHp(0)
		arg_3_0:updateEnergyTo(0)
	end
end

function var_0_3.addEnergyBuff(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_0:getEnergySkillID()
	local var_4_1 = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
	local var_4_2 = var_0_10 + var_0_11 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)

	if arg_4_0.isStarEnergy_ then
		var_4_2 = var_4_2 + 0.1
	end

	local var_4_3 = arg_4_0:getAP() * var_4_2
	local var_4_4 = arg_4_0:getAPBaoJi() * var_4_2
	local var_4_5 = arg_4_0:getDMoKang() * var_4_2

	for iter_4_0, iter_4_1 in ipairs(var_0_7) do
		local var_4_6 = var_0_4.new({
			tableID = iter_4_1,
			start = var_0_1.ctx.battle.count,
			level = var_4_1,
			skillID = var_4_0,
			fighter = arg_4_0,
			target = arg_4_1
		})

		if iter_4_0 == 1 then
			var_4_6.manualRevise = var_4_3
		elseif iter_4_0 == 2 then
			var_4_6.manualRevise = var_4_4
		else
			var_4_6.manualRevise = var_4_5
		end

		var_4_6:setIsHit(true)
		var_4_6:setDirection(arg_4_0:getFighterModel():getFlipX())
		arg_4_1:addBuffs({
			var_4_6
		})
	end
end

function var_0_3.updateEnergyBar(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	var_0_3.super.updateEnergyBar(arg_5_0)
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0.purpleCDCount then
		arg_6_0.purpleCDCount = arg_6_0.purpleCDCount - 1

		if arg_6_0.purpleCDCount <= 0 then
			arg_6_0.purpleCDCount = nil
		end
	end

	if arg_6_0.purpleCount then
		if not arg_6_0.purpleCDCount then
			local var_6_0 = var_0_8 + var_0_9 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

			for iter_6_0, iter_6_1 in ipairs(arg_6_0:getInfoByKey("magic_crit_info")) do
				local var_6_1 = iter_6_1[1].fighter

				if not var_6_1:isAffected() and not var_6_1:isDeath() and var_6_1:getTeamType() == arg_6_0:getTeamType() then
					if arg_6_0.isStarPurple_ then
						var_6_0 = var_6_0 + arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_5:desc4NumStep(arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))[2]
					end

					var_6_1:updateEnergyBy(var_6_0)

					arg_6_0.purpleCDCount = var_0_12
				end
			end
		end

		arg_6_0.purpleCount = arg_6_0.purpleCount - 1

		if arg_6_0.purpleCount <= 0 then
			arg_6_0.purpleCount = nil
		end
	end
end

function var_0_3.checkMove(arg_7_0)
	if arg_7_0.isEnterSkill_ then
		if var_0_1.ctx.battle.count < arg_7_0.hero_:enterDuration() then
			arg_7_0.isWalking_ = 1

			if not arg_7_0:isWalking() then
				arg_7_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
			elseif arg_7_0:isWalking() == 2 then
				local var_7_0 = arg_7_0:getFlipX() and -1 or 1

				arg_7_0:moveByX(arg_7_0.hero_:enterSpeed() * var_7_0)
			end

			if arg_7_0:getCurrentAnimation() ~= "run" then
				arg_7_0:modelWalk()
			end
		elseif not arg_7_0.playedEnterSkill_ then
			if arg_7_0:isWalking() ~= 3 then
				arg_7_0.preWalk_ = false
				arg_7_0.isWalking_ = false
				arg_7_0.behindWalk_ = false
				arg_7_0.playedEnterSkill_ = true
				arg_7_0.walk2Position_ = false

				if arg_7_0:getCurrentAnimation() == "run" then
					arg_7_0:getFighterModel():idle()
				end
			end
		elseif var_0_1.ctx.battle.count > arg_7_0.hero_:enterDelayDuration() then
			arg_7_0.isEnterSkill_ = nil
			arg_7_0.walk2Position_ = false
			arg_7_0.playedEnterSkill_ = false
		end

		return
	end

	var_0_3.super.checkMove(arg_7_0)
end

function var_0_3.setFormation(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	arg_8_0.isEnterSkill_ = arg_8_0:enterSkill() > 0 and arg_8_0:getSkillLevelByID(arg_8_0:enterSkill()) > 0

	if arg_8_0.isEnterSkill_ then
		arg_8_0.playedEnterSkill_ = false

		local var_8_0 = arg_8_0:getTeamType() == var_0_2.TeamType.A and 0 or var_0_2.STAGE_WIDTH

		arg_8_0:x(var_8_0)
		arg_8_0:y(var_0_2.STAGE_HEIGHT / 2 - 50 + arg_8_3 - 90 * (arg_8_2 % 2))

		return arg_8_2 + 1
	end

	return var_0_3.super.setFormation(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
end

function var_0_3.enterSkill(arg_9_0)
	return arg_9_0.hero_:enterSkill()
end

function var_0_3.buffAddAction(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_1:getLevel()
	local var_10_1 = var_0_5:desc4NumStep(arg_10_1:getSkillID())[2]

	if arg_10_1:getSkillID() == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_10_0.isStarBlue_ then
		arg_10_1.manualRevise = var_10_1 * var_10_0 * -1
	end
end

return var_0_3
