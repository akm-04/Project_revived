local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Luxifa", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.dbuff
local var_0_9 = 10
local var_0_10 = 40010800
local var_0_11 = 10000749
local var_0_12 = {
	40011289,
	40010796,
	40010797,
	40010798,
	40010799,
	40010815
}
local var_0_13 = 100
local var_0_14 = 20
local var_0_15 = 10
local var_0_16 = 15
local var_0_17 = 15
local var_0_18 = 20000
local var_0_19 = 80010158
local var_0_20 = 80020158
local var_0_21 = 0.1
local var_0_22 = 0.001
local var_0_23 = 0.15
local var_0_24 = 0.3
local var_0_25 = {
	40011879,
	40011880
}
local var_0_26 = {
	40012219,
	40012220,
	40012221
}
local var_0_27 = {
	40012222,
	40012223,
	40012224
}
local var_0_28 = var_0_2.tables.elementEquip
local var_0_29 = 20001438
local var_0_30 = 10002091
local var_0_31 = 40012234
local var_0_32 = 20120004
local var_0_33 = 20120005
local var_0_34 = 20120006
local var_0_35 = 0.05
local var_0_36 = 0.025

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("death_info")
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 2 then
		arg_2_0.ENERGY_RUSH_SKILL = 10002081
		arg_2_0.ENERGY_DOWN_SKILL = 10002082
		arg_2_0.BLUE_ENEMY_BUFF = 40012231
	else
		arg_2_0.ENERGY_RUSH_SKILL = 10000751
		arg_2_0.ENERGY_DOWN_SKILL = 10000752
		arg_2_0.BLUE_ENEMY_BUFF = 40010814
	end
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.isEnergyRushing_ = false
	arg_3_0.targetX_ = nil
	arg_3_0.targetY_ = nil
	arg_3_0.energyTarget_ = nil
	arg_3_0.skillRush_ = {}
	arg_3_0.finalFearList = {}
	arg_3_0.purpleMonsters_ = {}
	arg_3_0.isRushgoon = false
	arg_3_0.finalEnergyFear = false
	arg_3_0.greenBackCount_ = nil
	arg_3_0.greenBeforeCount_ = nil
	arg_3_0.blueBeforeCount_ = nil
	arg_3_0.energySummons = {}
end

function var_0_3.forceDie(arg_4_0)
	for iter_4_0, iter_4_1 in pairs(arg_4_0.energySummons) do
		if iter_4_1:isDeath() ~= true then
			iter_4_1:forceDie()
		end
	end

	for iter_4_2, iter_4_3 in pairs(arg_4_0.purpleMonsters_) do
		if iter_4_3:isDeath() ~= true then
			iter_4_3:forceDie()
		end
	end

	var_0_3.super.forceDie(arg_4_0)
end

function var_0_3.isBreakImmortal(arg_5_0)
	if arg_5_0.isEnergyRushing_ or arg_5_0.beginJump_ then
		return true
	end

	var_0_3.super.isBreakImmortal(arg_5_0)
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	local var_6_0 = arg_6_1.skillID
	local var_6_1 = arg_6_1.target

	if var_6_0 == arg_6_0.ENERGY_RUSH_SKILL then
		local var_6_2 = var_0_7:attackIndex(arg_6_0.ENERGY_DOWN_SKILL)

		arg_6_0:playAttack(var_6_2)
	elseif var_6_0 == arg_6_0.ENERGY_DOWN_SKILL then
		arg_6_0.isEnergyRushing_ = false
		arg_6_0.energyTarget_ = nil

		if arg_6_1.target:isDeath() then
			arg_6_0:summonDeathHero(arg_6_1.target)

			if not arg_6_0.finalEnergyFear then
				local var_6_3 = arg_6_0:chooseFinalFearTarget()

				arg_6_0:addFearBuff(var_6_3)

				arg_6_0.finalEnergyFear = true
			end
		end
	elseif arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and var_0_7:father(var_6_0) == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_6_4 = arg_6_1.target:getX()
		local var_6_5 = arg_6_1.target:getY()
		local var_6_6

		if arg_6_0:getTeamType() == var_0_2.TeamType.A then
			var_6_6 = -1

			arg_6_0:flipX(false)
		else
			var_6_6 = 1

			arg_6_0:flipX(true)
		end

		arg_6_0:x(var_6_4 + 100 * var_6_6)
		arg_6_0:y(var_6_5)

		if arg_6_1.skillID == var_0_11 then
			arg_6_0.greenBackCount_ = var_0_15
		end

		local var_6_7

		var_6_7 = var_6_1:getX() < arg_6_0:getX() and -1 or 1

		arg_6_0:elementSkill(arg_6_1)
	elseif arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and var_6_0 == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_6_8 = arg_6_1.target
		local var_6_9 = arg_6_0:getBlueTeammates(var_6_8)

		for iter_6_0, iter_6_1 in pairs(var_6_9) do
			for iter_6_2, iter_6_3 in ipairs(var_0_12) do
				local var_6_10 = arg_6_0:newBuff(iter_6_3, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue), iter_6_1)

				if iter_6_2 == 1 then
					var_6_10:setForceTarget(var_6_8)
				end

				iter_6_1:addBuffs({
					var_6_10
				})
			end
		end
	end

	if arg_6_0.isSkinSkillOn_ and arg_6_0.skinSkillID_ == var_0_20 and not arg_6_1.target:isDeath() and (var_0_7:father(arg_6_1.skillID) == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or var_0_7:father(arg_6_1.skillID) == arg_6_0:getPugongID() or var_0_7:father(arg_6_1.skillID) == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) or var_0_7:father(arg_6_1.skillID) == arg_6_0.ENERGY_DOWN_SKILL) and next(arg_6_1.target.buffs_) ~= nil then
		for iter_6_4 = #arg_6_1.target.buffs_, 1, -1 do
			local var_6_11 = arg_6_1.target.buffs_[iter_6_4]
			local var_6_12 = arg_6_0:isStunBuff(var_6_11)

			if var_6_11 and var_6_12 then
				local var_6_13 = arg_6_0:createNewBuffs(var_0_26, arg_6_1.target, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

				arg_6_1.target:addBuffs(var_6_13)

				local var_6_14 = var_0_8:init(var_0_26[1])
				local var_6_15 = var_0_8:init(var_0_26[2])
				local var_6_16 = var_0_8:init(var_0_26[3])
				local var_6_17 = arg_6_1.target:getAD() * var_6_14
				local var_6_18 = arg_6_1.target:getHuJia() * var_6_15
				local var_6_19 = arg_6_1.target:getMoKang() * var_6_16

				arg_6_0:addBuffs(arg_6_0:skinNewBuff(var_0_27[1], var_0_20, 1, arg_6_0, -var_6_17))
				arg_6_0:addBuffs(arg_6_0:skinNewBuff(var_0_27[2], var_0_20, 1, arg_6_0, -var_6_18))
				arg_6_0:addBuffs(arg_6_0:skinNewBuff(var_0_27[3], var_0_20, 1, arg_6_0, -var_6_19))
			end
		end
	end
end

function var_0_3.beginAttackEnd(arg_7_0, arg_7_1)
	if arg_7_1.rootID_ == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_7_0.greenPreX_ = arg_7_0:getX()
		arg_7_0.greenPreY_ = arg_7_0:getY()
		arg_7_0.greenBeforeCount_ = var_0_16
		arg_7_0.beginJump_ = true
	elseif arg_7_1.rootID_ == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_7_0.blueBeforeCount_ = var_0_17
	end

	var_0_3.super.beginAttackEnd(arg_7_0, arg_7_1)
end

function var_0_3.calculateUnitData(arg_8_0, arg_8_1)
	local var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5 = var_0_3.super.calculateUnitData(arg_8_0, arg_8_1)

	if arg_8_1.skillID == arg_8_0.ENERGY_DOWN_SKILL and arg_8_1.target == arg_8_0.energyTarget_ then
		local var_8_6 = arg_8_1.target
		local var_8_7 = math.max(var_8_6:getHpLimit() - var_8_6:getHp(), 0)
		local var_8_8 = var_0_21 + var_0_22 * arg_8_0:getSkillLevelByID(arg_8_0:getEnergySkillID())

		if arg_8_0.extraSkillLevel3 > 0 then
			var_8_8 = var_8_8 + arg_8_0.extraSkillLevel3 * var_0_36
		end

		var_8_2 = var_8_2 + var_8_7 * var_8_8
	end

	if arg_8_0.isSkinSkillOn_ and arg_8_0.skinSkillID_ == var_0_20 and not arg_8_1.target:isDeath() and (var_0_7:father(arg_8_1.skillID) == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or var_0_7:father(arg_8_1.skillID) == arg_8_0:getPugongID() or var_0_7:father(arg_8_1.skillID) == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) or var_0_7:father(arg_8_1.skillID) == arg_8_0.ENERGY_DOWN_SKILL) and next(arg_8_1.target.buffs_) ~= nil then
		for iter_8_0 = #arg_8_1.target.buffs_, 1, -1 do
			local var_8_9 = arg_8_1.target.buffs_[iter_8_0]
			local var_8_10 = arg_8_0:isStunBuff(var_8_9)

			if var_8_9 and var_8_10 and var_8_9.fighter ~= arg_8_0 then
				var_8_2 = var_8_2 * (1 + var_0_23)
			elseif var_8_9 and var_8_10 and var_8_9.fighter == arg_8_0 then
				var_8_2 = var_8_2 * (1 + var_0_24)
			end
		end
	end

	if arg_8_0.extraSkillLevel1 > 0 and var_8_2 > 0 and var_0_7:father(arg_8_1.skillID) == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		var_8_2 = var_8_2 * (1 + var_0_35 * arg_8_0.extraSkillLevel1)
	end

	return var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5
end

function var_0_3.chooseFinalFearTarget(arg_9_0)
	local function var_9_0(arg_10_0, arg_10_1)
		for iter_10_0, iter_10_1 in pairs(arg_10_0) do
			if iter_10_1 == arg_10_1 then
				return true
			end
		end

		return false
	end

	local var_9_1

	for iter_9_0, iter_9_1 in pairs(arg_9_0.sideTeam_) do
		if not var_9_0(arg_9_0.finalFearList, iter_9_1:getTableID()) then
			var_9_1 = iter_9_1

			table.insert(arg_9_0.finalFearList, iter_9_1:getTableID())

			break
		end
	end

	if not var_9_1 then
		return arg_9_0:getNearestTarget()
	else
		return var_9_1
	end
end

function var_0_3.summonDeathHero(arg_11_0, arg_11_1)
	local var_11_0 = arg_11_1:getX() - 100
	local var_11_1 = arg_11_1:getY()
	local var_11_2 = var_0_6.new()

	var_11_2:populate(arg_11_1.hero_:toParams())

	local var_11_3

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_11_3 = arg_11_0:getSummonMonster()

		if not var_11_3 then
			arg_11_0:summonMonstersErrorLog()
		end

		var_11_3:setTeamType(arg_11_0:getTeamType())
		var_11_3.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	else
		var_11_3 = arg_11_0:newFighter(var_11_2, arg_11_0:getTeamType(), false)

		local var_11_4 = #arg_11_0.selfTeam_ + 1

		var_11_3.fighterIndex = arg_11_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_11_3:setFormationDelay(var_0_2.tables.battleConfig.skillDelayQueue[var_11_4], var_0_2.tables.battleConfig.formationWalkQueue[var_11_4])
	end

	var_11_3.summoner = arg_11_0

	var_11_3.fighterModel:pos(var_11_0, var_11_1)
	var_11_3:setupBattleAttrInfo()
	var_11_3:setGlobalBuffs()

	local var_11_5 = arg_11_0:getHp() / arg_11_0:getHpLimit()

	var_11_3:setHp(var_11_3:getHpLimit() * var_11_5)

	var_11_3.summonType_ = var_0_2.summonMonsterType.Copy

	table.insert(arg_11_0.selfTeam_, var_11_3)
	table.insert(arg_11_0.energySummons, var_11_3)
end

function var_0_3.createAttacks(arg_12_0)
	local var_12_0 = arg_12_0.unitSkills_

	if not var_12_0 then
		return
	end

	if var_12_0:isEmptyQueue() then
		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			table.remove(arg_12_0.reportSkills_, 1)
		end

		arg_12_0.unitSkills_ = nil

		return
	end

	local var_12_1, var_12_2 = var_12_0:getFront()

	while var_12_1 and var_12_1 < 1 do
		if var_0_1.ctx.battle.infoListener.createAttack_info then
			table.insert(var_0_1.ctx.battle.infoListener.createAttack_info, arg_12_0)
		end

		arg_12_0:createUnits(var_12_0)
		var_12_0:popQueue()

		if var_12_2 == arg_12_0.ENERGY_RUSH_SKILL then
			local var_12_3 = var_0_7:attackIndex(var_12_2)

			arg_12_0:playAttack(var_12_3)
		end

		var_12_1, var_12_2 = var_12_0:getFront()

		if not arg_12_0:isCreatingUnits() then
			arg_12_0.unitSkills_ = nil

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				table.remove(arg_12_0.reportSkills_, 1)
			end

			arg_12_0:updateEnergyBy(var_12_0:getRemp() * arg_12_0:getAttrByType(var_0_2.AttributeType.ENERGY_RATE))
			arg_12_0:popFrontSkill()
		end
	end
end

function var_0_3.applyBuffMoves(arg_13_0)
	var_0_3.super.applyBuffMoves(arg_13_0)

	if next(arg_13_0.skillRush_) == nil or var_0_1.ctx.battle.isReleased(arg_13_0.fighterModel) or arg_13_0:isDeath() or not arg_13_0:acttionInBlack() then
		return
	end

	local var_13_0, var_13_1 = unpack(arg_13_0.skillRush_[1])

	arg_13_0.energyRushPreX_ = arg_13_0:getX()

	table.remove(arg_13_0.skillRush_, 1)

	if var_13_0 ~= 0 or var_13_1 ~= 0 then
		arg_13_0:moveByX(var_13_0, false)
		arg_13_0:moveByY(var_13_1, false)
	end

	if next(arg_13_0.skillRush_) == nil and arg_13_0.rushUnit_ then
		arg_13_0.rushUnit_:arrive()

		arg_13_0.rushUnit_.arrived = true
		arg_13_0.rushUnit_ = nil
		arg_13_0.isRushgoon = false
	end
end

function var_0_3.toDoPerFrames(arg_14_0)
	if not arg_14_0.extraSkillJudge then
		arg_14_0.extraSkillJudge = true

		local var_14_0 = arg_14_0.hero_:skillBook()

		arg_14_0.extraSkillLevel1 = var_14_0[tostring(var_0_32)] or 0
		arg_14_0.extraSkillLevel2 = var_14_0[tostring(var_0_33)] or 0
		arg_14_0.extraSkillLevel3 = var_14_0[tostring(var_0_34)] or 0
	end

	var_0_3.super.toDoPerFrames(arg_14_0)

	if arg_14_0:isDeath() then
		return
	end

	if arg_14_0.isEnergyRushing_ then
		for iter_14_0, iter_14_1 in pairs(arg_14_0.sideTeam_) do
			if not iter_14_1:isDeath() and not iter_14_1:isAffected() and arg_14_0.energyRushPreX_ and (arg_14_0:getX() - iter_14_1:getX()) * (arg_14_0.energyRushPreX_ - iter_14_1:getX()) < 0 and not iter_14_1:isHasBuffByID(var_0_10) then
				arg_14_0:addFearBuff(iter_14_1)
				table.insert(arg_14_0.finalFearList, iter_14_1:getTableID())
			end
		end
	end

	if arg_14_0.greenBackCount_ then
		arg_14_0.greenBackCount_ = arg_14_0.greenBackCount_ - 1

		if arg_14_0.greenBackCount_ <= 0 then
			arg_14_0:x(arg_14_0.greenPreX_)
			arg_14_0:y(arg_14_0.greenPreY_)

			arg_14_0.greenPreX_ = nil
			arg_14_0.greenPreY_ = nil
			arg_14_0.greenBackCount_ = nil
			arg_14_0.beginJump_ = false
		end
	end

	if arg_14_0.greenBeforeCount_ then
		arg_14_0.greenBeforeCount_ = arg_14_0.greenBeforeCount_ - 1

		if arg_14_0.greenBeforeCount_ <= 0 then
			local var_14_1 = arg_14_0:getNearestTarget()
			local var_14_2

			if arg_14_0:getTeamType() == var_0_2.TeamType.A then
				var_14_2 = -1

				arg_14_0:flipX(false)
			else
				var_14_2 = 1

				arg_14_0:flipX(true)
			end

			if var_14_1 then
				arg_14_0:x(var_14_1:getX() + var_14_2 * 100)
				arg_14_0:y(var_14_1:getY())
			end

			arg_14_0.greenBeforeCount_ = nil
		end
	end

	if arg_14_0.blueBeforeCount_ then
		arg_14_0.blueBeforeCount_ = arg_14_0.blueBeforeCount_ - 1

		if arg_14_0.blueBeforeCount_ <= 0 then
			local var_14_3 = arg_14_0:getTargetB31()
			local var_14_4

			if arg_14_0:getTeamType() == var_0_2.TeamType.A then
				var_14_4 = -1

				arg_14_0:flipX(false)
			else
				var_14_4 = 1

				arg_14_0:flipX(true)
			end

			if var_14_3 then
				arg_14_0:x(var_14_3:getX() + var_14_4 * 200)
				arg_14_0:y(var_14_3:getY())
			end

			arg_14_0.blueBeforeCount_ = nil
		end
	end

	if arg_14_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_14_2, iter_14_3 in ipairs(arg_14_0:getInfoByKey("death_info")) do
			if iter_14_3:getTeamType() == arg_14_0:getTeamType() and iter_14_3 ~= arg_14_0 and not arg_14_0:isDeath() and iter_14_3.summonType_ == var_0_2.summonMonsterType.None then
				local var_14_5 = arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
				local var_14_6 = var_0_7:summonMonster(var_14_5)

				if next(var_14_6) == nil then
					return
				end

				for iter_14_4, iter_14_5 in ipairs(var_14_6) do
					local var_14_7 = arg_14_0:getSkillLevelByID(var_14_5)
					local var_14_8 = arg_14_0.hero_:getColor()
					local var_14_9 = {
						x = iter_14_3:getX(),
						y = iter_14_3:getY()
					}
					local var_14_10 = arg_14_0:setSummonMonsters(iter_14_5, var_14_7, var_14_8, var_14_9)

					table.insert(arg_14_0.purpleMonsters_, var_14_10)
				end
			end
		end
	end
end

function var_0_3.setSummonMonsters(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4)
	local var_15_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_15_0 = arg_15_0:getSummonMonster()
	else
		local var_15_1 = var_0_6.new()

		var_15_1:populateWithTableID(arg_15_1)

		var_15_1.level_ = arg_15_2 or var_15_1.level_
		var_15_1.color_ = arg_15_3 or var_15_1.color_

		for iter_15_0, iter_15_1 in ipairs(var_15_1.skillLev_) do
			local var_15_2 = var_15_1:getSkillId(iter_15_0)
			local var_15_3 = arg_15_0.hero_:getSkillLevelByID(var_15_2)

			if var_15_3 and var_15_3 > 0 then
				var_15_1.skillLev_[iter_15_0] = var_15_3
			end
		end

		local var_15_4 = var_15_1:className()

		var_15_0 = var_0_1.ctx.battle.requireFighter(var_15_4).new({
			is_arena = arg_15_0.isInArena_
		})

		var_15_0:populateWithHero(var_15_1)
		var_15_0:initModels()
		var_15_0.fighterModel:initHeaderView(arg_15_0:getTeamType() - 1)

		var_15_0.fighterIndex = arg_15_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_15_0:setFormationDelay(0, 100)
	end

	if not var_15_0 then
		arg_15_0:summonMonstersErrorLog()
	end

	var_15_0:setTeamType(arg_15_0:getTeamType())

	var_15_0.summoner = arg_15_0

	var_15_0.fighterModel:pos(arg_15_4.x, arg_15_4.y)
	var_15_0:updateHp(var_15_0:getHpLimit())
	var_15_0:getFighterModel():flipX(arg_15_0:getTeamType() == var_0_2.TeamType.B)
	var_15_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_15_0:born()
	var_15_0:setGlobalBuffs()

	local var_15_5 = var_15_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_15_5, var_15_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_15_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_15_0.purpleMonsters_, var_15_0)

	var_15_0.summonType_ = var_0_2.summonMonsterType.Monster

	return var_15_0
end

function var_0_3.addFearBuff(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_0:newBuff(var_0_10, arg_16_0:getEnergySkillID(), arg_16_1)

	arg_16_1:addBuffs({
		var_16_0
	})
end

function var_0_3.newBuff(arg_17_0, arg_17_1, arg_17_2, arg_17_3)
	return (var_0_4.new({
		tableID = arg_17_1,
		start = var_0_1.ctx.battle.count,
		level = arg_17_0:getSkillLevelByID(arg_17_2),
		skillID = arg_17_2,
		fighter = arg_17_0,
		target = arg_17_3
	}))
end

function var_0_3.skinNewBuff(arg_18_0, arg_18_1, arg_18_2, arg_18_3, arg_18_4, arg_18_5)
	local var_18_0 = var_0_4.new({
		tableID = arg_18_1,
		start = var_0_1.ctx.battle.count,
		level = arg_18_3,
		skillID = arg_18_2,
		fighter = arg_18_0,
		target = arg_18_4,
		manualRevise = arg_18_5
	})

	return {
		var_18_0
	}
end

function var_0_3.createUnits(arg_19_0)
	local var_19_0, var_19_1 = arg_19_0.unitSkills_:getFront()

	if var_19_1 == arg_19_0.ENERGY_RUSH_SKILL then
		arg_19_0.rushBeginX_ = arg_19_0:getX()

		local var_19_2, var_19_3 = arg_19_0:getTargetB4()

		arg_19_0.energyTarget_ = var_19_2

		if not var_19_2 then
			return
		end

		local var_19_4 = var_19_3 + var_0_13
		local var_19_5 = var_0_9

		if arg_19_0.rushUnit_ then
			arg_19_0.rushUnit_:arrive()

			arg_19_0.rushUnit_.arrived = true
			arg_19_0.rushUnit_ = nil
			arg_19_0.isRushgoon = false
		end

		arg_19_0.isEnergyRushing_ = true
		arg_19_0.finalEnergyFear = false
		arg_19_0.finalFearList = {}
		arg_19_0.skillRush_ = {}

		local var_19_6 = var_19_2:getX() < arg_19_0:getX() and -1 or 1

		for iter_19_0 = 1, var_19_5 do
			table.insert(arg_19_0.skillRush_, {
				var_19_6 * var_19_4 / var_19_5,
				0
			})
		end

		arg_19_0:flipX(var_19_2:getX() < arg_19_0:getX())
	end

	var_0_3.super.createUnits(arg_19_0)
end

function var_0_3.newFighter(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	local var_20_0 = arg_20_1:className()
	local var_20_1 = var_0_1.ctx.battle.requireFighter(var_20_0).new({
		is_arena = arg_20_0.isInArena_
	})

	var_20_1:populateWithHero(arg_20_1)
	var_20_1:setTeamType(arg_20_2)
	var_20_1:initModels()
	var_20_1.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_20_1:getFighterModel():idle()

	local var_20_2 = arg_20_2 - 1

	var_20_1.fighterModel:initHeaderView(var_20_2)
	var_20_1:getFighterModel():flipX(arg_20_3)

	return var_20_1
end

function var_0_3.getTargetB4(arg_21_0)
	local var_21_0
	local var_21_1
	local var_21_2

	for iter_21_0, iter_21_1 in ipairs(arg_21_0.sideTeam_) do
		if not iter_21_1:isDeath() and not iter_21_1:isAffected() and (not var_21_0 or var_21_2 > iter_21_1:getHp() / iter_21_1:getHpLimit() or var_21_2 == iter_21_1:getHp() / iter_21_1:getHpLimit() and var_21_0:getHp() > iter_21_1:getHp()) then
			var_21_0 = iter_21_1
			var_21_1 = math.abs(var_21_0:getX() - arg_21_0:getX())
			var_21_2 = var_21_0:getHp() / var_21_0:getHpLimit()
		end
	end

	if var_21_0 and var_21_0:avoidHeroMoveBehind() then
		var_21_1 = var_21_1 - (var_21_1 > 0 and 120 or -120)
	end

	var_21_1 = var_21_1 and (var_21_1 > 50 and var_21_1 - 50 or var_21_1)

	return var_21_0, var_21_1
end

function var_0_3.getTargetB31(arg_22_0)
	local var_22_0
	local var_22_1

	for iter_22_0, iter_22_1 in ipairs(arg_22_0.sideTeam_) do
		if not iter_22_1:isDeath() and not iter_22_1:isAffected() and iter_22_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_22_1 or var_22_1 < iter_22_1.harms) then
			var_22_0 = iter_22_1
			var_22_1 = iter_22_1.harms
		end
	end

	return var_22_0
end

function var_0_3.getBlueTeammates(arg_23_0, arg_23_1)
	local var_23_0 = var_0_7:scope(arg_23_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)) * 0.5
	local var_23_1 = {}

	for iter_23_0, iter_23_1 in pairs(arg_23_0.selfTeam_) do
		if not iter_23_1:isDeath() and not iter_23_1:isAffected() and (not t or rate > iter_23_1:getHp() / iter_23_1:getHpLimit() or rate == iter_23_1:getHp() / iter_23_1:getHpLimit() and t:getHp() > iter_23_1:getHp()) and var_23_0 >= math.abs(iter_23_1:getX() - arg_23_1:getX()) and iter_23_1 ~= arg_23_0 then
			table.insert(var_23_1, iter_23_1)
		end
	end

	return var_23_1
end

function var_0_3.buffAddAction(arg_24_0, arg_24_1)
	if arg_24_0.isSkinSkillOn_ and arg_24_0.skinSkillID_ == var_0_19 and var_0_8:dbuffType(arg_24_1:getTableID()) == var_0_2.DBuffType.XUAN_YUN then
		local var_24_0 = arg_24_0:createNewBuffs(var_0_25, arg_24_0, arg_24_0.skinSkillID_)

		arg_24_0:addBuffs(var_24_0)
	end
end

function var_0_3.isStunBuff(arg_25_0, arg_25_1)
	if arg_25_1:dBuffType() == var_0_2.DBuffType.XUAN_YUN or arg_25_1:dBuffType() == var_0_2.DBuffType.KONG_JU then
		return true
	end

	return false
end

function var_0_3.elementSkill(arg_26_0, arg_26_1)
	if arg_26_0:hasElementEquipByID(var_0_29) then
		local var_26_0 = var_0_29
		local var_26_1 = var_0_28:battleAttr(var_26_0, arg_26_0:getElementEquipLevelByID(var_26_0))
		local var_26_2 = arg_26_0.hero_:getElementEquipActiveRate(var_26_0)
		local var_26_3 = arg_26_0:createNewBuffs({
			var_0_31
		}, arg_26_1.target, var_0_30)

		for iter_26_0, iter_26_1 in ipairs(var_26_3) do
			iter_26_1.manualHarmRevise = var_26_1 * var_26_2
		end

		arg_26_1.target:addBuffs(var_26_3)
	end
end

return var_0_3
