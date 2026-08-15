local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fengxian", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("BaseFighter")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_7 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_8 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_9 = var_0_2.tables.skill
local var_0_10 = var_0_2.tables.hero
local var_0_11 = var_0_2.tables.model
local var_0_12 = var_0_2.tables.dbuff
local var_0_13 = 40011840
local var_0_14 = 40011839
local var_0_15 = 10001704
local var_0_16 = 81190003
local var_0_17 = 10001706
local var_0_18 = 10001707
local var_0_19 = 10001708
local var_0_20 = 10001709
local var_0_21 = 10001710
local var_0_22 = 0.1
local var_0_23 = 300
local var_0_24 = 20000
local var_0_25 = 30000
local var_0_26 = 20000
local var_0_27 = 30000
local var_0_28 = 500
local var_0_29 = 10001353
local var_0_30 = 40011449
local var_0_31 = 600
local var_0_32 = 0.6
local var_0_33 = 0.9
local var_0_34 = 0.5
local var_0_35 = 150
local var_0_36 = 500
local var_0_37 = 10
local var_0_38 = 10001355
local var_0_39 = 10001354

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.purpleSkillCount = 0
	arg_2_0.greenX = 0
	arg_2_0.greenY = 0
	arg_2_0.greenPhase = 0
	arg_2_0.greenSkilling = false
	arg_2_0.summonHeroCD = var_0_31
	arg_2_0.summonHeros = {}
	arg_2_0.addEnergyCD = var_0_35
end

function var_0_3.populateWithHero(arg_3_0, arg_3_1)
	var_0_3.super.populateWithHero(arg_3_0, arg_3_1)

	local var_3_0 = arg_3_0.hero_:getTableID()

	arg_3_0.nPhase = var_3_0 == 89260011 and 1 or var_3_0 == 89260012 and 2 or var_3_0 == 89260013 and 3 or var_3_0 == 89260014 and 4 or var_3_0 == 89260015 and 5 or var_3_0 == 89260016 and 6 or var_3_0 == 89260017 and 7 or var_3_0 == 89260018 and 8 or var_3_0 == 89260019 and 9 or var_3_0 == 89260020 and 10 or 0
end

function var_0_3.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.updateUnitDataByTarget(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_1.target == arg_4_0 and var_4_2 > 0 then
		if arg_4_1.attackType == var_0_2.AttackType.AP and (arg_4_0.nPhase == 2 and var_4_2 < var_0_24 or arg_4_0.nPhase == 3 and var_4_2 > var_0_24) then
			var_4_2 = var_4_2 * 0.1
		end

		if arg_4_1.attackType == var_0_2.AttackType.AD and (arg_4_0.nPhase == 4 and var_4_2 < var_0_26 or arg_4_0.nPhase == 5 and var_4_2 > var_0_27) then
			var_4_2 = var_4_2 * 0.1
		end

		if arg_4_0.nPhase == 6 then
			var_4_2 = 0
		end

		if arg_4_0.nPhase == 9 and var_4_2 > 0 then
			if arg_4_0:isBattleUnable() or arg_4_0:isPugongOnly() then
				var_4_2 = var_4_2 + var_4_2 * var_0_34
			else
				var_4_2 = var_4_2 - var_4_2 * var_0_33
			end
		end
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.addBuffs(arg_5_0, arg_5_1)
	if arg_5_0.nPhase == 9 then
		return var_0_4.addBuffs(arg_5_0, arg_5_1)
	else
		var_0_3.super.addBuffs(arg_5_0, arg_5_1)
	end
end

function var_0_3.isBreakImmortal(arg_6_0)
	return arg_6_0.greenSkilling or arg_6_0.nPhase ~= 9
end

function var_0_3.isAdImmortal(arg_7_0)
	if arg_7_0.nPhase == 2 or arg_7_0.nPhase == 3 then
		return true
	end

	return var_0_3.super.isAdImmortal(arg_7_0)
end

function var_0_3.isApImmortal(arg_8_0)
	if arg_8_0.Fengxian == 4 or arg_8_0.nPhase == 5 then
		return true
	end

	return var_0_3.super.isApImmortal(arg_8_0)
end

function var_0_3.isImmortal(arg_9_0, arg_9_1)
	if arg_9_0.nPhase == 8 then
		for iter_9_0, iter_9_1 in ipairs(arg_9_0.summonHeros) do
			if not iter_9_1:isDeath() then
				return true
			end
		end
	end

	return var_0_3.super.isImmortal(arg_9_0, arg_9_1)
end

function var_0_3.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	if arg_10_0.nPhase == 7 and arg_10_4 > 0 then
		local var_10_0 = arg_10_0:createAttackUnits({
			arg_10_1.target
		}, var_0_29)

		for iter_10_0, iter_10_1 in ipairs(var_10_0) do
			table.insert(arg_10_0.moveAttackUnits_, iter_10_1)
			table.insert(arg_10_0.records_.special_units, iter_10_1)
		end

		local var_10_1 = 0

		for iter_10_2, iter_10_3 in ipairs(arg_10_1.target:getBuffs()) do
			if iter_10_3.tableID_ == var_0_30 then
				var_10_1 = var_10_1 + 1
			end
		end

		arg_10_4 = arg_10_4 + var_10_1 * var_0_28
	end

	return arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7
end

function var_0_3.toDoPerFrames(arg_11_0)
	var_0_3.super.toDoPerFrames(arg_11_0)

	if arg_11_0.nPhase == 10 then
		if arg_11_0.addEnergyCD > 0 then
			arg_11_0.addEnergyCD = arg_11_0.addEnergyCD - 1
		else
			for iter_11_0, iter_11_1 in ipairs(arg_11_0.sideTeam_) do
				if not iter_11_1:isDeath() and not iter_11_1:isAffected() then
					local var_11_0 = iter_11_1:getEnergy()

					iter_11_1:updateEnergyBy(var_0_36)

					local var_11_1 = iter_11_1:getEnergy()
					local var_11_2 = math.max(var_0_36 - var_11_1 + var_11_0, 0) * var_0_37

					if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						local var_11_3 = arg_11_0:createAttackUnits({
							iter_11_1
						}, var_0_38)

						for iter_11_2, iter_11_3 in ipairs(var_11_3) do
							iter_11_3:setExtraHarm(var_11_2)
							table.insert(arg_11_0.moveAttackUnits_, iter_11_3)
							table.insert(arg_11_0.records_.special_units, iter_11_3)
						end
					end
				end
			end

			arg_11_0.addEnergyCD = var_0_35
		end

		for iter_11_4, iter_11_5 in ipairs(arg_11_0:getInfoByKey("attack_info")) do
			if iter_11_5.fighter_:getTeamType() ~= arg_11_0:getTeamType() and iter_11_5.rootID_ == iter_11_5.fighter_:getEnergySkillID() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_11_4 = arg_11_0:createAttackUnits({
					iter_11_5.fighter_
				}, var_0_39)

				for iter_11_6, iter_11_7 in ipairs(var_11_4) do
					table.insert(arg_11_0.moveAttackUnits_, iter_11_7)
					table.insert(arg_11_0.records_.special_units, iter_11_7)
				end
			end
		end
	end

	if arg_11_0.nPhase == 8 then
		if arg_11_0.summonHeroCD > 0 then
			arg_11_0.summonHeroCD = arg_11_0.summonHeroCD - 1
		elseif not arg_11_0:isImmortal() then
			for iter_11_8, iter_11_9 in ipairs(arg_11_0.sideTeam_) do
				if not iter_11_9:isDeath() and iter_11_9:getSummonType() == var_0_2.summonMonsterType.None then
					local var_11_5 = arg_11_0:summonHeroMirror(iter_11_9, iter_11_9:getLevel())

					table.insert(arg_11_0.summonHeros, var_11_5)
				end
			end

			arg_11_0.summonHeroCD = var_0_31
		end
	end

	local var_11_6 = arg_11_0:getBuffByID(var_0_13) or arg_11_0:getBuffByID(var_0_14)

	if var_11_6 and var_11_6.leftCount_ % math.ceil(var_11_6:getTime() / 5 + 1) == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_11_7 = arg_11_0:createAttackUnits(var_0_7.B8(arg_11_0, var_0_15), var_0_15)

		for iter_11_10, iter_11_11 in ipairs(var_11_7) do
			table.insert(arg_11_0.moveAttackUnits_, iter_11_11)
			table.insert(arg_11_0.records_.special_units, iter_11_11)
		end
	end

	if arg_11_0.purpleSkillCount > 0 then
		arg_11_0.purpleSkillCount = arg_11_0.purpleSkillCount - 1
	end

	if arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_11_12, iter_11_13 in ipairs(arg_11_0:getInfoByKey("buff_info")) do
			if iter_11_13.target:getTeamType() ~= arg_11_0:getTeamType() and arg_11_0.purpleSkillCount <= 0 and iter_11_13:isFear() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_11_8 = arg_11_0:createAttackUnits({
					arg_11_0
				}, arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				for iter_11_14, iter_11_15 in ipairs(var_11_8) do
					table.insert(arg_11_0.moveAttackUnits_, iter_11_15)
					table.insert(arg_11_0.records_.special_units, iter_11_15)
				end
			end
		end
	end
end

function var_0_3.summonHeroMirror(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_12_1 = arg_12_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_12_0 = var_0_1.ctx.battle.summonMonsters[var_12_1]

		if not var_12_0 then
			arg_12_0:summonMonstersErrorLog()
		end
	else
		local var_12_2 = var_0_8.new()
		local var_12_3 = arg_12_1.hero_:toParams()

		var_12_2:populate(var_12_3)

		var_12_2.level_ = arg_12_2 < 100 and arg_12_2 or 100

		local var_12_4 = var_12_2:className()

		var_12_0 = var_0_1.ctx.battle.requireFighter(var_12_4).new({
			is_arena = arg_12_0.isInArena_
		})

		var_12_0:populateWithHero(var_12_2)

		for iter_12_0, iter_12_1 in pairs(var_12_0.skillLevelByID_) do
			var_12_0.skillLevelByID_[iter_12_0] = arg_12_2
		end

		for iter_12_2, iter_12_3 in pairs(var_12_0.skillLevelByColor_) do
			if var_12_0.hero_:getSkillId(iter_12_2) > 0 then
				var_12_0.skillLevelByColor_[iter_12_2] = arg_12_2
			end
		end

		var_12_0:initModels()
		var_12_0.fighterModel:initHeaderView(arg_12_0:getTeamType() - 1)

		var_12_0.fighterIndex = arg_12_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_12_0:setFormationDelay(0, 100)

		var_12_0.startSkillQueue_ = {}
		var_12_0.skillQueue_ = arg_12_1.skillQueue_

		var_12_0:updateEnergyTo(arg_12_1:getEnergy())
	end

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		var_12_0:getFighterModel():setMaskColor(cc.c4f(1, 0.88, 0.46, 1))
		var_12_0:setDefaultMaskColor(cc.c4f(1, 0.88, 0.46, 1))
	end

	var_12_0.summonType_ = var_0_2.summonMonsterType.Copy

	var_12_0:setSummonAutoFight(true)

	var_12_0.hasReborn_ = true

	var_12_0:setTeamType(arg_12_0:getTeamType())

	var_12_0.summoner = arg_12_0

	var_12_0.fighterModel:pos(arg_12_1:getPos())
	var_12_0:getFighterModel():flipX(arg_12_1:getFlipX())
	var_12_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_12_0:born()
	var_12_0:setGlobalBuffs()
	var_12_0:updateHp(var_12_0:getHpLimit() * var_0_32)

	local var_12_5 = var_12_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_12_5, var_12_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_12_0)
	var_0_1.ctx.battle.updateZorder()

	return var_12_0
end

function var_0_3.buffRemoveAction(arg_13_0, arg_13_1)
	if arg_13_1:getTableID() == var_0_13 then
		local var_13_0 = arg_13_0:getBuffByID(var_0_14)

		if #arg_13_0:getBuffsByID(var_0_13) == 1 and var_13_0 then
			var_13_0.extraTime_ = 0

			local var_13_1 = var_0_12:time(var_0_13) / var_0_12:time(var_0_14)

			var_13_0.leftCount_ = math.floor(var_13_0.leftCount_ / var_13_1)
		end
	end
end

function var_0_3.beginAttackEnd(arg_14_0, arg_14_1)
	var_0_3.super.beginAttackEnd(arg_14_0, arg_14_1)

	if var_0_9:father(arg_14_1.rootID_) == arg_14_0:getEnergySkillID() then
		local var_14_0, var_14_1 = next(var_0_7.B4(arg_14_0, arg_14_0:getEnergySkillID()))

		if var_14_1 then
			arg_14_0:x(var_14_1:getX() + (var_14_1:getFlipX() and 50 or -50))
			arg_14_0:y(var_14_1:getY())
		end
	end
end

function var_0_3.applySingleUnit(arg_15_0, arg_15_1)
	if arg_15_1.basicHarm > 0 and var_0_2.weightedChoise({
		var_0_22,
		1 - var_0_22
	}) == 1 and arg_15_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_15_1.target:getTeamType() ~= arg_15_0:getTeamType() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_15_0 = arg_15_0:createAttackUnits({
			arg_15_1.target
		}, var_0_21)

		for iter_15_0, iter_15_1 in ipairs(var_15_0) do
			table.insert(arg_15_0.moveAttackUnits_, iter_15_1)
			table.insert(arg_15_0.records_.special_units, iter_15_1)
		end
	end

	var_0_3.super.applySingleUnit(arg_15_0, arg_15_1)

	if arg_15_1.skillID == var_0_16 then
		arg_15_0.greenSkilling = true

		if arg_15_0.greenPhase == 0 then
			arg_15_0.greenX = arg_15_0:getX()
			arg_15_0.greenY = arg_15_0:getY()

			if next(arg_15_0:selectTargetByTypeD1()) then
				local var_15_1 = arg_15_0:selectTargetByTypeD1()[1]

				arg_15_0:x(var_15_1:getX() + (var_15_1:getFlipX() and -50 or 50))
				arg_15_0:y(var_15_1:getY())
				arg_15_0:createSkillByID(var_0_17, arg_15_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_9:attackIndex(var_0_17))
			end
		elseif arg_15_0.greenPhase == 1 then
			if next(arg_15_0:selectTargetByTypeD2()) then
				local var_15_2 = arg_15_0:selectTargetByTypeD2()[1]

				arg_15_0:x(var_15_2:getX() + (var_15_2:getFlipX() and -50 or 50))
				arg_15_0:y(var_15_2:getY())
				arg_15_0:createSkillByID(var_0_18, arg_15_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_9:attackIndex(var_0_18))
			end
		elseif arg_15_0.greenPhase == 2 and next(arg_15_0:selectTargetByTypeD3()) then
			local var_15_3 = arg_15_0:selectTargetByTypeD3()[1]

			arg_15_0:x(var_15_3:getX() + (var_15_3:getFlipX() and -50 or 50))
			arg_15_0:y(var_15_3:getY())
			arg_15_0:createSkillByID(var_0_19, arg_15_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_9:attackIndex(var_0_19))
		end
	elseif arg_15_1.skillID == var_0_17 then
		arg_15_0.greenPhase = 1

		arg_15_0:createSkillByID(var_0_16, arg_15_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_9:attackIndex(var_0_16))
	elseif arg_15_1.skillID == var_0_18 then
		arg_15_0.greenPhase = 2

		arg_15_0:createSkillByID(var_0_16, arg_15_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_9:attackIndex(var_0_16))
	elseif arg_15_1.skillID == var_0_19 then
		arg_15_0:createSkillByID(var_0_20, arg_15_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_9:attackIndex(var_0_20))
	elseif arg_15_1.skillID == var_0_20 then
		arg_15_0.greenPhase = 0

		arg_15_0:x(arg_15_0.greenX)
		arg_15_0:y(arg_15_0.greenY)

		arg_15_0.greenSkilling = false
	end
end

function var_0_3.selectTargetByTypeD1(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0

	for iter_16_0, iter_16_1 in ipairs(arg_16_0.targetTeam_) do
		var_16_0 = not iter_16_1:isDeath() and not iter_16_1:isAffected() and ((not var_16_0 or not (var_16_0:getAD() < iter_16_1:getAD())) and var_16_0 or iter_16_1) or var_16_0
	end

	return {
		var_16_0
	}
end

function var_0_3.selectTargetByTypeD2(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0

	for iter_17_0, iter_17_1 in ipairs(arg_17_0.targetTeam_) do
		var_17_0 = not iter_17_1:isDeath() and not iter_17_1:isAffected() and ((not var_17_0 or not (var_17_0:getAP() < iter_17_1:getAP())) and var_17_0 or iter_17_1) or var_17_0
	end

	return {
		var_17_0
	}
end

function var_0_3.selectTargetByTypeD3(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0

	for iter_18_0, iter_18_1 in ipairs(arg_18_0.targetTeam_) do
		var_18_0 = not iter_18_1:isDeath() and not iter_18_1:isAffected() and ((not var_18_0 or not (var_18_0:getEnergy() < iter_18_1:getEnergy())) and var_18_0 or iter_18_1) or var_18_0
	end

	return {
		var_18_0
	}
end

return var_0_3
