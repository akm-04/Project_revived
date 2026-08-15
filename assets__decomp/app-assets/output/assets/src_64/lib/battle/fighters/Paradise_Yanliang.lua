local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ParadiseYanliang", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = var_0_1.ctx.battle.getRequire("SkillEffect")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = var_0_2.tables.hero
local var_0_10 = var_0_2.tables.model
local var_0_11 = {
	40010226,
	40010227
}
local var_0_12 = {
	40010228,
	40010229
}
local var_0_13 = {
	40010226,
	40010227
}
local var_0_14 = {
	40010228,
	40010229
}
local var_0_15 = {
	40010245,
	40010246
}
local var_0_16 = 60
local var_0_17 = 89220007
local var_0_18 = 2
local var_0_19 = 4
local var_0_20 = {
	40010231
}
local var_0_21 = {
	40010230
}
local var_0_22 = 79000

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.summonNpc_ = nil
	arg_1_0.skillRush_ = {}
end

function var_0_3.applyBuffMoves(arg_2_0)
	var_0_3.super.applyBuffMoves(arg_2_0)

	if next(arg_2_0.skillRush_) == nil or var_0_1.ctx.battle.isReleased(arg_2_0.fighterModel) or arg_2_0:isDeath() or not arg_2_0:acttionInBlack() then
		return
	end

	local var_2_0, var_2_1 = unpack(arg_2_0.skillRush_[1])

	table.remove(arg_2_0.skillRush_, 1)

	if var_2_0 ~= 0 or var_2_1 ~= 0 then
		arg_2_0:moveByX(var_2_0, false)
		arg_2_0:moveByY(var_2_1, false)

		if arg_2_0:getX() <= -1 * arg_2_0:getFighterModel():getWidth() / 2 and var_2_0 < 0 then
			arg_2_0:x(arg_2_0:getFighterModel():getWidth() / 2 + var_0_2.STAGE_WIDTH)

			if arg_2_0.rushUnit_ then
				arg_2_0.rushUnit_.iniX_ = arg_2_0:getX()
			end
		elseif arg_2_0:getX() >= var_0_2.STAGE_WIDTH + arg_2_0:getFighterModel():getWidth() / 2 and var_2_0 > 0 then
			arg_2_0:x(-1 * arg_2_0:getFighterModel():getWidth() / 2)

			if arg_2_0.rushUnit_ then
				arg_2_0.rushUnit_.iniX_ = arg_2_0:getX()
			end
		end
	end

	if next(arg_2_0.skillRush_) == nil and arg_2_0.rushUnit_ then
		arg_2_0.rushUnit_:arrive()

		arg_2_0.rushUnit_.arrived = true
		arg_2_0.rushUnit_ = nil
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) then
		var_3_2 = var_0_22
		var_3_1 = false
	end

	return var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5
end

function var_0_3.newBuff(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		local var_4_1 = var_0_6.new({
			tableID = iter_4_1,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getSkillLevelByID(arg_4_3),
			skillID = arg_4_3,
			fighter = arg_4_0,
			target = arg_4_2
		})

		var_4_1:setIsHit(true)
		var_4_1:setDirection(arg_4_2:getFighterModel():getFlipX())
		table.insert(var_4_0, var_4_1)
	end

	return var_4_0
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	local var_5_0 = arg_5_1.target
	local var_5_1 = arg_5_1.skillID

	if var_5_1 == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or var_5_1 == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		if var_5_0.hero_:getHeroType() == var_0_2.HeroType.STRENGTH then
			var_5_0:addBuffs(arg_5_0:newBuff(var_0_11, var_5_0, var_5_1))
		else
			var_5_0:addBuffs(arg_5_0:newBuff(var_0_12, var_5_0, var_5_1))
		end
	elseif var_5_1 == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		if var_5_0.hero_:getHeroType() == var_0_2.HeroType.STRENGTH then
			var_5_0:addBuffs(arg_5_0:newBuff(var_0_13, var_5_0, var_5_1))
		else
			var_5_0:addBuffs(arg_5_0:newBuff(var_0_14, var_5_0, var_5_1))
		end
	end
end

function var_0_3.moveUnitArrive(arg_6_0, arg_6_1)
	if arg_6_1.resource then
		arg_6_1.resource:stop()
	end

	arg_6_1:arrive()

	if arg_6_1:getAreaResource() then
		local var_6_0 = arg_6_1.unitEffectType == var_0_2.UnitEffectType.SelfFootPos and arg_6_1.fighter:getY() or arg_6_1.desY_
		local var_6_1 = arg_6_1.unitEffectType == var_0_2.UnitEffectType.SelfFootPos and arg_6_1.fighter:getX() or arg_6_1.desX_

		arg_6_1:getAreaResource():addTo(var_0_1.ctx.battle.unitLayer)
		arg_6_1:getAreaResource():pos(var_6_1, var_6_0)
		arg_6_1:getAreaResource():playOnce()
		arg_6_1:getAreaResource():flipX(arg_6_1.fighter:getX() > arg_6_1.desX_)
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_6_2 = arg_6_1:getReportUnits()

		for iter_6_0, iter_6_1 in ipairs(var_6_2) do
			table.insert(arg_6_0.applyUnits_, iter_6_1)
		end
	else
		local var_6_3 = arg_6_0:getTargets(arg_6_1.skillID, arg_6_1)

		if next(var_6_3) then
			local var_6_4 = arg_6_1:createAttacks(var_6_3)

			for iter_6_2, iter_6_3 in ipairs(var_6_4) do
				if arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
					iter_6_3.targetsCount = #var_6_4
				end

				table.insert(arg_6_0.applyUnits_, iter_6_3)
			end
		end
	end
end

function var_0_3.createUnits(arg_7_0)
	local var_7_0, var_7_1 = arg_7_0.unitSkills_:getFront()

	if var_0_8:father(var_7_1) == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		local var_7_2 = arg_7_0:getFighterModel():getWidth() + var_0_2.STAGE_WIDTH
		local var_7_3 = var_0_16

		if arg_7_0.rushUnit_ then
			arg_7_0.rushUnit_:arrive()

			arg_7_0.rushUnit_.arrived = true
			arg_7_0.rushUnit_ = nil
		end

		arg_7_0.skillRush_ = {}

		local var_7_4 = arg_7_0:getFlipX() and -1 or 1

		for iter_7_0 = 1, var_7_3 do
			table.insert(arg_7_0.skillRush_, {
				var_7_4 * var_7_2 / var_7_3,
				0
			})
		end
	end

	var_0_3.super.createUnits(arg_7_0)
end

function var_0_3.unitAfterCreate(arg_8_0, arg_8_1, arg_8_2)
	if arg_8_1 and arg_8_1.skillID == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		arg_8_0.rushUnit_ = arg_8_1
	end
end

function var_0_3.selectTargetByTypeD1(arg_9_0, arg_9_1, arg_9_2)
	return {
		arg_9_0.summonNpc_
	}
end

function var_0_3.toDoPerFrames(arg_10_0)
	if arg_10_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count == 80 then
		local var_10_0

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			local var_10_1 = "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1)

			var_10_0 = var_0_1.ctx.battle.summonMonsters[var_10_1]

			var_10_0:setTeamType(var_0_2.TeamType.A)
			var_10_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
		else
			local var_10_2 = var_0_5.new()

			var_10_2:populateWithTableID(var_0_17)

			var_10_0 = arg_10_0:newFighter(var_10_2, var_0_2.TeamType.A, false)

			local var_10_3 = #var_0_1.ctx.battle.teamA + 1

			var_10_0.fighterIndex = "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1)

			var_10_0:setFormationDelay(var_0_2.tables.battleConfig.skillDelayQueue[var_10_3], var_0_2.tables.battleConfig.formationWalkQueue[var_10_3])
		end

		var_10_0.fighterModel:pos(0, var_0_2.STAGE_HEIGHT / 2)
		var_10_0:setupBattleAttrInfo()
		var_10_0:setGlobalBuffs()

		var_10_0.opposeNpc = arg_10_0

		table.insert(var_0_1.ctx.battle.teamA, var_10_0)

		arg_10_0.summonNpc_ = var_10_0
	end
end

function var_0_3.setProgress(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	var_0_3.super.setProgress(arg_11_0, arg_11_1, arg_11_2, arg_11_3)

	if arg_11_0.hpIndex_ == var_0_18 + 1 and not arg_11_0.isPurpleBuffAddOne_ then
		arg_11_0.isPurpleBuffAddOne_ = true

		arg_11_0:addBuffs(arg_11_0:newBuff(var_0_20, arg_11_0, arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)))
	elseif arg_11_0.hpIndex_ == var_0_19 + 1 and not arg_11_0.isPurpleBuffAddTwo_ then
		arg_11_0.isPurpleBuffAddTwo_ = true

		arg_11_0:addBuffs(arg_11_0:newBuff(var_0_21, arg_11_0, arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)))
	end
end

function var_0_3.newFighter(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = arg_12_1:className()
	local var_12_1 = var_0_1.ctx.battle.requireFighter(var_12_0).new({
		is_arena = arg_12_0.isInArena_
	})

	var_12_1:populateWithHero(arg_12_1)
	var_12_1:setTeamType(arg_12_2)
	var_12_1:initModels()
	var_12_1.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_12_1:getFighterModel():idle()

	local var_12_2 = arg_12_2 - 1

	var_12_1.fighterModel:initHeaderView(var_12_2)
	var_12_1:getFighterModel():flipX(arg_12_3)

	return var_12_1
end

function var_0_3.removePurpleBuff(arg_13_0)
	arg_13_0:removeBuffByID(unpack(var_0_20))
	arg_13_0:removeBuffByID(unpack(var_0_21))
end

function var_0_3.addHarmBuff(arg_14_0)
	if not arg_14_0:isHasBuffByID(var_0_15[1]) then
		arg_14_0:addBuffs(arg_14_0:newBuff(var_0_15, arg_14_0, arg_14_0:getEnergySkillID()))
	end
end

function var_0_3.isHurtBreak(arg_15_0, arg_15_1, arg_15_2)
	return false
end

return var_0_3
