local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = {
	40010243
}
local var_0_7 = {
	40010249
}
local var_0_8 = 0
local var_0_9 = 0.05
local var_0_10 = 40010425

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.enterHero_ = nil
	arg_1_0.enterCancelCount_ = nil
	arg_1_0.enterSkillID_ = nil
	arg_1_0.isSpecialEneterSkill_ = nil
	arg_1_0.isPurpleSuccess_ = nil
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == arg_2_0:getEnergySkillID() then
		local var_2_0 = arg_2_1.target
		local var_2_1 = 0.8

		if arg_2_0.isStarEnergy_ then
			var_2_1 = 0.75
		end

		if var_2_0:getEnergy() >= var_0_2.ENERGY_DECIMAL_BASE * var_2_1 then
			local var_2_2 = math.max(arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy), 20)
			local var_2_3 = math.min(1 / (var_0_2.tables.battleConfig.buffHitParam1 * math.max(var_2_0:getLevel() - var_2_2, 0) + var_0_2.tables.battleConfig.buffHitParam2), 1)

			if var_0_2.weightedChoise({
				var_2_3,
				1 - var_2_3
			}) == 1 then
				var_2_0:addBuffs(arg_2_0:newBuff(var_0_6, var_2_0, arg_2_1.skillID))
			end
		end
	end
end

function var_0_3.checkMove(arg_3_0)
	if arg_3_0.isSpecialEneterSkill_ then
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
			arg_3_0.isSpecialEneterSkill_ = nil
			arg_3_0.walk2Position_ = false
			arg_3_0.playedEnterSkill_ = false
		end

		return
	end

	var_0_3.super.checkMove(arg_3_0)
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if var_0_1.ctx.battle.count == 1 then
			local var_4_0 = {}

			for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
				if iter_4_1.isEnterSkill_ then
					local var_4_1 = iter_4_1.hero_:enterSkill()
					local var_4_2 = var_0_5:selectType(var_4_1)

					if not string.find(var_4_2, "D") then
						table.insert(var_4_0, iter_4_1)
					end
				end
			end

			if next(var_4_0) then
				local var_4_3 = var_4_0[math.random(1, #var_4_0)]

				arg_4_0.enterCancelCount_ = var_0_5:pretime(var_4_3.hero_:enterSkill())

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_4_4 = {
						var_4_3
					}
					local var_4_5 = arg_4_0:createAttackUnits(var_4_4, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

					for iter_4_2, iter_4_3 in ipairs(var_4_5) do
						table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
						table.insert(arg_4_0.records_.special_units, iter_4_3)
					end
				end

				if arg_4_0.isStarPurple_ then
					local var_4_6 = arg_4_0:newBuff({
						var_0_10
					}, var_4_3, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

					var_4_3:addBuffs(var_4_6)
				end

				arg_4_0.enterHero_ = var_4_3
				arg_4_0.enterSkillID_ = var_4_3.hero_:enterSkill()
			end
		end

		if arg_4_0.enterCancelCount_ then
			local var_4_7 = unpack(var_0_5:buffs(arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)))

			if not arg_4_0.isPurpleSuccess_ and arg_4_0.enterHero_:isHasBuffByID(var_4_7) then
				local var_4_8 = arg_4_0:getTeamType() == var_0_2.TeamType.A and 0 or var_0_2.STAGE_WIDTH

				arg_4_0:x(var_4_8)

				arg_4_0.isSpecialEneterSkill_ = true
				arg_4_0.isPurpleSuccess_ = true
			elseif arg_4_0.isPurpleSuccess_ then
				if var_0_1.ctx.battle.count == arg_4_0.enterCancelCount_ then
					arg_4_0.enterHero_.isEnterSkill_ = nil
					arg_4_0.enterHero_.walk2Position_ = false
					arg_4_0.enterHero_.playedEnterSkill_ = false
					arg_4_0.enterHero_.preWalk_ = false
					arg_4_0.enterHero_.isWalking_ = false
					arg_4_0.enterHero_.behindWalk_ = false

					arg_4_0.enterHero_:skillIsBreak()
					arg_4_0.enterHero_:resumeIdle()

					arg_4_0.enterHero_ = nil
					arg_4_0.enterCancelCount_ = nil

					arg_4_0:createSkillByID(arg_4_0.enterSkillID_, arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple), 3)

					arg_4_0.enterSkillID_ = nil
				else
					local var_4_9 = arg_4_0:getTeamType() == var_0_2.TeamType.A and 1 or -1

					arg_4_0:moveByX(var_4_9 * 6)
				end
			elseif var_0_1.ctx.battle.count > arg_4_0.enterCancelCount_ then
				arg_4_0.enterCancelCount_ = nil
				arg_4_0.enterHero_ = nil
				arg_4_0.enterSkillID_ = nil
			end
		end
	end

	if var_0_1.ctx.battle.count % 30 >= 1 then
		return
	end

	local var_4_10 = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)

	if var_4_10 > 0 then
		local var_4_11 = var_0_8 + var_0_9 * var_4_10

		for iter_4_4, iter_4_5 in ipairs(arg_4_0.sideTeam_) do
			if not iter_4_5:isDeath() and not iter_4_5:isAffected() then
				iter_4_5:updateEnergyBy(-var_4_11)
			end
		end
	end
end

function var_0_3.newBuff(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_1) do
		local var_5_1 = var_0_4.new({
			tableID = iter_5_1,
			start = var_0_1.ctx.battle.count,
			level = arg_5_0:getSkillLevelByID(arg_5_3),
			skillID = arg_5_3,
			fighter = arg_5_0,
			target = arg_5_2
		})

		var_5_1:setIsHit(true)
		var_5_1:setDirection(arg_5_0:getFighterModel():getFlipX())
		table.insert(var_5_0, var_5_1)
	end

	return var_5_0
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	if arg_6_0.isStarBlue_ and arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_6_0 = var_0_5:desc4NumStep(arg_6_1.skillID)[2]

		arg_6_4 = arg_6_0:getSkillLevelByID(arg_6_1.skillID) * var_6_0 * arg_6_1.target:getAPJianShang() + arg_6_4
	end

	return var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
end

return var_0_3
