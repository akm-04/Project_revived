local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Luxifa", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = 10
local var_0_9 = 10000751
local var_0_10 = 10000752
local var_0_11 = 40010800
local var_0_12 = 10000749
local var_0_13 = 40010814
local var_0_14 = {
	40010796,
	40010797,
	40010798,
	40010799,
	40010815
}
local var_0_15 = 100
local var_0_16 = 20
local var_0_17 = 10
local var_0_18 = 15
local var_0_19 = 15
local var_0_20 = 20000
local var_0_21 = 5
local var_0_22 = 0.1
local var_0_23 = 0.001

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("death_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.isEnergyRushing_ = false
	arg_2_0.targetX_ = nil
	arg_2_0.targetY_ = nil
	arg_2_0.energyTarget_ = nil
	arg_2_0.skillRush_ = {}
	arg_2_0.finalFearList = {}
	arg_2_0.purpleMonsters_ = {}
	arg_2_0.isRushgoon = false
	arg_2_0.finalEnergyFear = false
	arg_2_0.greenBackCount_ = nil
	arg_2_0.greenBeforeCount_ = nil
	arg_2_0.blueBeforeCount_ = nil
	arg_2_0.energySummons = {}
	arg_2_0.energyStage = ENERGY_STAGE_NULL
end

function var_0_3.die(arg_3_0)
	for iter_3_0, iter_3_1 in pairs(arg_3_0.energySummons) do
		if iter_3_1:isDeath() ~= true then
			iter_3_1:updateHp(0)
			iter_3_1:die()
		end
	end

	var_0_3.super.die(arg_3_0)
end

function var_0_3.isBreakImmortal(arg_4_0)
	if arg_4_0.isEnergyRushing_ or arg_4_0.beginJump_ then
		return true
	end

	var_0_3.super.isBreakImmortal(arg_4_0)
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	local var_5_0 = arg_5_1.skillID
	local var_5_1 = arg_5_1.target

	if var_5_0 == var_0_9 then
		local var_5_2 = var_0_7:attackIndex(var_0_10)

		arg_5_0:playAttack(var_5_2)
	elseif var_5_0 == var_0_10 then
		arg_5_0.isEnergyRushing_ = false
		arg_5_0.energyTarget_ = nil

		if arg_5_1.target:isDeath() then
			arg_5_0:summonDeathHero(arg_5_1.target)

			if not arg_5_0.finalEnergyFear then
				local var_5_3 = arg_5_0:chooseFinalFearTarget()

				arg_5_0:addFearBuff(var_5_3)

				arg_5_0.finalEnergyFear = true
			end
		end
	elseif arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and var_0_7:father(var_5_0) == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_5_4 = arg_5_1.target:getX()
		local var_5_5 = arg_5_1.target:getY()
		local var_5_6

		if arg_5_0:getTeamType() == var_0_2.TeamType.A then
			var_5_6 = -1

			arg_5_0:flipX(false)
		else
			var_5_6 = 1

			arg_5_0:flipX(true)
		end

		arg_5_0:x(var_5_4 + 100 * var_5_6)
		arg_5_0:y(var_5_5)

		if arg_5_1.skillID == var_0_12 then
			arg_5_0.greenBackCount_ = var_0_17
		end

		local var_5_7

		var_5_7 = var_5_1:getX() < arg_5_0:getX() and -1 or 1
	elseif arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and var_5_0 == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_5_8 = arg_5_1.target
		local var_5_9 = arg_5_0:getBlueTeammates(var_5_8)

		for iter_5_0, iter_5_1 in pairs(var_5_9) do
			for iter_5_2, iter_5_3 in ipairs(var_0_14) do
				local var_5_10 = arg_5_0:newBuff(iter_5_3, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue), iter_5_1)

				var_5_10:setForceTarget(var_5_8)
				iter_5_1:addBuffs({
					var_5_10
				})
			end
		end
	end
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	if arg_6_1.rootID_ == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_6_0.greenPreX_ = arg_6_0:getX()
		arg_6_0.greenPreY_ = arg_6_0:getY()
		arg_6_0.greenBeforeCount_ = var_0_18
		arg_6_0.beginJump_ = true
	elseif arg_6_1.rootID_ == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_6_0.blueBeforeCount_ = var_0_19
	end

	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)
end

function var_0_3.calculateUnitData(arg_7_0, arg_7_1)
	local var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5 = var_0_3.super.calculateUnitData(arg_7_0, arg_7_1)

	if arg_7_1.skillID == var_0_10 and arg_7_1.target == arg_7_0.energyTarget_ then
		var_7_2 = var_7_2 + arg_7_1.target:getDamage() * (var_0_22 + var_0_23 * arg_7_0:getSkillLevelByID(arg_7_0:getEnergySkillID()))
	end

	return var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5
end

function var_0_3.chooseFinalFearTarget(arg_8_0)
	local function var_8_0(arg_9_0, arg_9_1)
		for iter_9_0, iter_9_1 in pairs(arg_9_0) do
			if iter_9_1 == arg_9_1 then
				return true
			end
		end

		return false
	end

	local var_8_1

	for iter_8_0, iter_8_1 in pairs(arg_8_0.sideTeam_) do
		if not var_8_0(arg_8_0.finalFearList, iter_8_1:getTableID()) then
			var_8_1 = iter_8_1

			table.insert(arg_8_0.finalFearList, iter_8_1:getTableID())

			break
		end
	end

	if not var_8_1 then
		return arg_8_0:getNearestTarget()
	else
		return var_8_1
	end
end

function var_0_3.summonDeathHero(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_1:getX() - 100
	local var_10_1 = arg_10_1:getY()
	local var_10_2 = var_0_6.new()

	var_10_2:populate(arg_10_1.hero_:toParams())

	local var_10_3

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_10_4 = arg_10_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_10_3 = var_0_1.ctx.battle.summonMonsters[var_10_4]

		var_10_3:setTeamType(arg_10_0:getTeamType())
		var_10_3.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	else
		var_10_3 = arg_10_0:newFighter(var_10_2, arg_10_0:getTeamType(), false)

		local var_10_5 = #arg_10_0.selfTeam_ + 1

		var_10_3.fighterIndex = arg_10_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_10_3:setFormationDelay(var_0_2.tables.battleConfig.skillDelayQueue[var_10_5], var_0_2.tables.battleConfig.formationWalkQueue[var_10_5])
	end

	var_10_3.fighterModel:pos(var_10_0, var_10_1)
	var_10_3:setupBattleAttrInfo()
	var_10_3:setGlobalBuffs()

	local var_10_6 = arg_10_0:getHp() / arg_10_0:getHpLimit()

	var_10_3:setHp(var_10_3:getHpLimit() * var_10_6)

	var_10_3.summonType_ = var_0_2.summonMonsterType.Copy

	table.insert(arg_10_0.selfTeam_, var_10_3)
	table.insert(arg_10_0.energySummons, var_10_3)
end

function var_0_3.createAttacks(arg_11_0)
	local var_11_0 = arg_11_0.unitSkills_

	if not var_11_0 then
		return
	end

	if var_11_0:isEmptyQueue() then
		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			table.remove(arg_11_0.reportSkills_, 1)
		end

		arg_11_0.unitSkills_ = nil

		return
	end

	local var_11_1, var_11_2 = var_11_0:getFront()

	while var_11_1 and var_11_1 < 1 do
		if var_0_1.ctx.battle.infoListener.createAttack_info then
			table.insert(var_0_1.ctx.battle.infoListener.createAttack_info, arg_11_0)
		end

		arg_11_0:createUnits(var_11_0)
		var_11_0:popQueue()

		if var_11_2 == var_0_9 then
			local var_11_3 = var_0_7:attackIndex(var_11_2)

			arg_11_0:playAttack(var_11_3)
		end

		var_11_1, var_11_2 = var_11_0:getFront()

		if not arg_11_0:isCreatingUnits() then
			arg_11_0.unitSkills_ = nil

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				table.remove(arg_11_0.reportSkills_, 1)
			end

			arg_11_0:updateEnergyBy(var_11_0:getRemp() * arg_11_0:getAttrByType(var_0_2.AttributeType.ENERGY_RATE))
			arg_11_0:popFrontSkill()
		end
	end
end

function var_0_3.applyBuffMoves(arg_12_0)
	var_0_3.super.applyBuffMoves(arg_12_0)

	if next(arg_12_0.skillRush_) == nil or var_0_1.ctx.battle.isReleased(arg_12_0.fighterModel) or arg_12_0:isDeath() or not arg_12_0:acttionInBlack() then
		return
	end

	local var_12_0, var_12_1 = unpack(arg_12_0.skillRush_[1])

	arg_12_0.energyRushPreX_ = arg_12_0:getX()

	table.remove(arg_12_0.skillRush_, 1)

	if var_12_0 ~= 0 or var_12_1 ~= 0 then
		arg_12_0:moveByX(var_12_0, false)
		arg_12_0:moveByY(var_12_1, false)
	end

	if next(arg_12_0.skillRush_) == nil and arg_12_0.rushUnit_ then
		arg_12_0.rushUnit_:arrive()

		arg_12_0.rushUnit_.arrived = true
		arg_12_0.rushUnit_ = nil
		arg_12_0.isRushgoon = false
	end
end

function var_0_3.toDoPerFrames(arg_13_0)
	var_0_3.super.toDoPerFrames(arg_13_0)

	if arg_13_0:isDeath() then
		return
	end

	if arg_13_0.isEnergyRushing_ then
		for iter_13_0, iter_13_1 in pairs(arg_13_0.sideTeam_) do
			if not iter_13_1:isDeath() and not iter_13_1:isAffected() and arg_13_0.energyRushPreX_ and (arg_13_0:getX() - iter_13_1:getX()) * (arg_13_0.energyRushPreX_ - iter_13_1:getX()) < 0 and not iter_13_1:isHasBuffByID(var_0_11) then
				arg_13_0:addFearBuff(iter_13_1)
				table.insert(arg_13_0.finalFearList, iter_13_1:getTableID())
			end
		end
	end

	if arg_13_0.greenBackCount_ then
		arg_13_0.greenBackCount_ = arg_13_0.greenBackCount_ - 1

		if arg_13_0.greenBackCount_ <= 0 then
			arg_13_0:x(arg_13_0.greenPreX_)
			arg_13_0:y(arg_13_0.greenPreY_)

			arg_13_0.greenPreX_ = nil
			arg_13_0.greenPreY_ = nil
			arg_13_0.greenBackCount_ = nil
			arg_13_0.beginJump_ = false
		end
	end

	if arg_13_0.greenBeforeCount_ then
		arg_13_0.greenBeforeCount_ = arg_13_0.greenBeforeCount_ - 1

		if arg_13_0.greenBeforeCount_ <= 0 then
			local var_13_0 = arg_13_0:getNearestTarget()
			local var_13_1

			if arg_13_0:getTeamType() == var_0_2.TeamType.A then
				var_13_1 = -1

				arg_13_0:flipX(false)
			else
				var_13_1 = 1

				arg_13_0:flipX(true)
			end

			if var_13_0 then
				arg_13_0:x(var_13_0:getX() + var_13_1 * 100)
				arg_13_0:y(var_13_0:getY())
			end

			arg_13_0.greenBeforeCount_ = nil
		end
	end

	if arg_13_0.blueBeforeCount_ then
		arg_13_0.blueBeforeCount_ = arg_13_0.blueBeforeCount_ - 1

		if arg_13_0.blueBeforeCount_ <= 0 then
			local var_13_2 = arg_13_0:getTargetB31()
			local var_13_3

			if arg_13_0:getTeamType() == var_0_2.TeamType.A then
				var_13_3 = -1

				arg_13_0:flipX(false)
			else
				var_13_3 = 1

				arg_13_0:flipX(true)
			end

			if var_13_2 then
				arg_13_0:x(var_13_2:getX() + var_13_3 * 200)
				arg_13_0:y(var_13_2:getY())
			end

			arg_13_0.blueBeforeCount_ = nil
		end
	end

	for iter_13_2 = #arg_13_0.purpleMonsters_, 1, -1 do
		if arg_13_0.purpleMonsters_[iter_13_2]:isDeath() then
			table.remove(arg_13_0.purpleMonsters_, iter_13_2)
		end
	end

	if arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and #arg_13_0.purpleMonsters_ < var_0_21 then
		for iter_13_3, iter_13_4 in ipairs(arg_13_0:getInfoByKey("death_info")) do
			if iter_13_4 ~= arg_13_0 and iter_13_4:getTeamType() ~= arg_13_0:getTeamType() and #arg_13_0.purpleMonsters_ < var_0_21 then
				local var_13_4 = arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
				local var_13_5 = var_0_7:summonMonster(var_13_4)

				if next(var_13_5) == nil then
					return
				end

				for iter_13_5, iter_13_6 in ipairs(var_13_5) do
					local var_13_6 = arg_13_0:getSkillLevelByID(var_13_4)
					local var_13_7 = arg_13_0.hero_:getColor()
					local var_13_8 = {
						x = iter_13_4:getX(),
						y = iter_13_4:getY()
					}
					local var_13_9 = arg_13_0:setSummonMonsters(iter_13_6, var_13_6, var_13_7, var_13_8)
				end
			end
		end
	end
end

function var_0_3.setSummonMonsters(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4)
	local var_14_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_14_1 = arg_14_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_14_0 = var_0_1.ctx.battle.summonMonsters[var_14_1]
	else
		local var_14_2 = var_0_6.new()

		var_14_2:populateWithTableID(arg_14_1)

		var_14_2.level_ = arg_14_2 or var_14_2.level_
		var_14_2.color_ = arg_14_3 or var_14_2.color_

		for iter_14_0, iter_14_1 in ipairs(var_14_2.skillLev_) do
			local var_14_3 = var_14_2:getSkillId(iter_14_0)
			local var_14_4 = arg_14_0.hero_:getSkillLevelByID(var_14_3)

			if var_14_4 and var_14_4 > 0 then
				var_14_2.skillLev_[iter_14_0] = var_14_4
			end
		end

		local var_14_5 = var_14_2:className()

		var_14_0 = var_0_1.ctx.battle.requireFighter(var_14_5).new({
			is_arena = arg_14_0.isInArena_
		})

		var_14_0:populateWithHero(var_14_2)
		var_14_0:initModels()
		var_14_0.fighterModel:initHeaderView(arg_14_0:getTeamType() - 1)

		var_14_0.fighterIndex = arg_14_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_14_0:setFormationDelay(0, 100)
	end

	var_14_0:setTeamType(arg_14_0:getTeamType())

	var_14_0.summoner = arg_14_0

	var_14_0.fighterModel:pos(arg_14_4.x, arg_14_4.y)
	var_14_0:updateHp(var_14_0:getHpLimit())
	var_14_0:getFighterModel():flipX(arg_14_0:getTeamType() == var_0_2.TeamType.B)
	var_14_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_14_0:born()
	var_14_0:setGlobalBuffs()

	local var_14_6 = var_14_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_14_6, var_14_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_14_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_14_0.purpleMonsters_, var_14_0)

	var_14_0.summonType_ = var_0_2.summonMonsterType.Monster

	return var_14_0
end

function var_0_3.addFearBuff(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_0:newBuff(var_0_11, arg_15_0:getEnergySkillID(), arg_15_1)

	arg_15_1:addBuffs({
		var_15_0
	})
end

function var_0_3.newBuff(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	return (var_0_4.new({
		tableID = arg_16_1,
		start = var_0_1.ctx.battle.count,
		level = arg_16_0:getSkillLevelByID(arg_16_2),
		skillID = arg_16_2,
		fighter = arg_16_0,
		target = arg_16_3
	}))
end

function var_0_3.createUnits(arg_17_0)
	local var_17_0, var_17_1 = arg_17_0.unitSkills_:getFront()

	if var_17_1 == var_0_9 then
		arg_17_0.rushBeginX_ = arg_17_0:getX()

		local var_17_2, var_17_3 = arg_17_0:getTargetB4()

		arg_17_0.energyTarget_ = var_17_2

		if not var_17_2 then
			return
		end

		local var_17_4 = var_17_3 + var_0_15
		local var_17_5 = var_0_8

		if arg_17_0.rushUnit_ then
			arg_17_0.rushUnit_:arrive()

			arg_17_0.rushUnit_.arrived = true
			arg_17_0.rushUnit_ = nil
			arg_17_0.isRushgoon = false
		end

		arg_17_0.isEnergyRushing_ = true
		arg_17_0.finalEnergyFear = false
		arg_17_0.finalFearList = {}
		arg_17_0.skillRush_ = {}

		local var_17_6 = var_17_2:getX() < arg_17_0:getX() and -1 or 1

		for iter_17_0 = 1, var_17_5 do
			table.insert(arg_17_0.skillRush_, {
				var_17_6 * var_17_4 / var_17_5,
				0
			})
		end

		arg_17_0:flipX(var_17_2:getX() < arg_17_0:getX())
	end

	var_0_3.super.createUnits(arg_17_0)
end

function var_0_3.newFighter(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	local var_18_0 = arg_18_1:className()
	local var_18_1 = var_0_1.ctx.battle.requireFighter(var_18_0).new({
		is_arena = arg_18_0.isInArena_
	})

	var_18_1:populateWithHero(arg_18_1)
	var_18_1:setTeamType(arg_18_2)
	var_18_1:initModels()
	var_18_1.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_18_1:getFighterModel():idle()

	local var_18_2 = arg_18_2 - 1

	var_18_1.fighterModel:initHeaderView(var_18_2)
	var_18_1:getFighterModel():flipX(arg_18_3)

	return var_18_1
end

function var_0_3.getTargetB4(arg_19_0)
	local var_19_0
	local var_19_1
	local var_19_2

	for iter_19_0, iter_19_1 in ipairs(arg_19_0.sideTeam_) do
		if not iter_19_1:isDeath() and not iter_19_1:isAffected() and (not var_19_0 or var_19_2 > iter_19_1:getHp() / iter_19_1:getHpLimit() or var_19_2 == iter_19_1:getHp() / iter_19_1:getHpLimit() and var_19_0:getHp() > iter_19_1:getHp()) then
			var_19_0 = iter_19_1
			var_19_1 = math.abs(var_19_0:getX() - arg_19_0:getX())
			var_19_2 = var_19_0:getHp() / var_19_0:getHpLimit()
		end
	end

	if var_19_0 and var_19_0:avoidHeroMoveBehind() then
		var_19_1 = var_19_1 - (var_19_1 > 0 and 120 or -120)
	end

	var_19_1 = var_19_1 and (var_19_1 > 50 and var_19_1 - 50 or var_19_1)

	return var_19_0, var_19_1
end

function var_0_3.getTargetB31(arg_20_0)
	local var_20_0
	local var_20_1

	for iter_20_0, iter_20_1 in ipairs(arg_20_0.sideTeam_) do
		if not iter_20_1:isDeath() and not iter_20_1:isAffected() and iter_20_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_20_1 or var_20_1 < iter_20_1.harms) then
			var_20_0 = iter_20_1
			var_20_1 = iter_20_1.harms
		end
	end

	return var_20_0
end

function var_0_3.getBlueTeammates(arg_21_0, arg_21_1)
	local var_21_0 = var_0_7:scope(arg_21_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)) * 0.5
	local var_21_1 = {}

	for iter_21_0, iter_21_1 in pairs(arg_21_0.selfTeam_) do
		if not iter_21_1:isDeath() and not iter_21_1:isAffected() and (not t or rate > iter_21_1:getHp() / iter_21_1:getHpLimit() or rate == iter_21_1:getHp() / iter_21_1:getHpLimit() and t:getHp() > iter_21_1:getHp()) and var_21_0 >= math.abs(iter_21_1:getX() - arg_21_1:getX()) and iter_21_1 ~= arg_21_0 then
			table.insert(var_21_1, iter_21_1)
		end
	end

	return var_21_1
end

return var_0_3
