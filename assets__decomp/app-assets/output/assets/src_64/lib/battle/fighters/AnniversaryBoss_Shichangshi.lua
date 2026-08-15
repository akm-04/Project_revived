local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Shichangshi", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("BaseFighter")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_7 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_8 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_9 = var_0_2.tables.skill
local var_0_10 = var_0_2.tables.hero
local var_0_11 = var_0_2.tables.model
local var_0_12 = var_0_2.tables.dbuff
local var_0_13 = 81180005
local var_0_14 = 10001365
local var_0_15 = 81180002
local var_0_16 = 10001366
local var_0_17 = 650
local var_0_18 = 0.11
local var_0_19 = 20000
local var_0_20 = 20000
local var_0_21 = 20000
local var_0_22 = 20000
local var_0_23 = 500
local var_0_24 = 10001353
local var_0_25 = 40011449
local var_0_26 = 600
local var_0_27 = 0.6
local var_0_28 = 0.9
local var_0_29 = 0.5
local var_0_30 = 150
local var_0_31 = 500
local var_0_32 = 10
local var_0_33 = 10001355
local var_0_34 = 10001354

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
	arg_1_0:listenInfo("attack_info")

	arg_1_0.nGhostFires = 0
	arg_1_0.nPhase = 0
	arg_1_0.summonHeroCD = var_0_26
	arg_1_0.summonHeros = {}
	arg_1_0.addEnergyCD = var_0_30
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	local var_2_0 = arg_2_0.hero_:getTableID()

	arg_2_0.nPhase = var_2_0 == 89260001 and 1 or var_2_0 == 89260002 and 2 or var_2_0 == 89260003 and 3 or var_2_0 == 89260004 and 4 or var_2_0 == 89260005 and 5 or var_2_0 == 89260006 and 6 or var_2_0 == 89260007 and 7 or var_2_0 == 89260008 and 8 or var_2_0 == 89260009 and 9 or var_2_0 == 89260010 and 10 or 0
end

function var_0_3.updateUnitDataBySpecialHero(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_1.target == arg_3_0 and var_3_2 > 0 then
		if arg_3_1.attackType == var_0_2.AttackType.AP and (arg_3_0.nPhase == 2 and var_3_2 < var_0_19 or arg_3_0.nPhase == 3 and var_3_2 > var_0_19) then
			var_3_2 = var_3_2 * 0.1
		end

		if arg_3_1.attackType == var_0_2.AttackType.AD and (arg_3_0.nPhase == 4 and var_3_2 < var_0_21 or arg_3_0.nPhase == 5 and var_3_2 > var_0_22) then
			var_3_2 = var_3_2 * 0.1
		end

		if arg_3_0.nPhase == 6 then
			var_3_2 = 0
		end

		if arg_3_0.nPhase == 9 and var_3_2 > 0 then
			if arg_3_0:isBattleUnable() or arg_3_0:isPugongOnly() then
				var_3_2 = var_3_2 + var_3_2 * var_0_29
			else
				var_3_2 = var_3_2 - var_3_2 * var_0_28
			end
		end
	end

	return var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	local var_4_0 = arg_4_1.target

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_4_1.skillID == var_0_14 then
		arg_4_0.nGhostFires = 0
	end

	if arg_4_1.skillID >= 10001356 and arg_4_1.skillID <= 10001364 then
		local var_4_1 = var_0_9:scope(var_0_14) / 2
		local var_4_2 = {}

		for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
			if not iter_4_1:isDeath() and not iter_4_1:isAffected() and var_4_1 > math.abs(iter_4_1:getX() - var_4_0:getX()) then
				table.insert(var_4_2, iter_4_1)
			end
		end

		local var_4_3 = arg_4_0:createAttackUnits(var_4_2, var_0_14)

		for iter_4_2, iter_4_3 in ipairs(var_4_3) do
			iter_4_3:setExtraHarm(arg_4_0.nGhostFires * var_0_17)
			table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
			table.insert(arg_4_0.records_.special_units, iter_4_3)
		end

		local var_4_4 = var_0_1.ctx.battle.getSpine(var_0_14, "area", 1)

		var_4_4:addTo(var_0_1.ctx.battle.unitBottomLayer)
		var_4_4:pos(var_4_0:getX(), var_4_0:getY())
		var_4_4:setScale(0.64)
		var_4_4:playOnce()
	elseif arg_4_1.skillID == var_0_15 then
		local var_4_5 = var_0_9:scope(var_0_16) / 2
		local var_4_6 = {}

		for iter_4_4, iter_4_5 in ipairs(arg_4_0.sideTeam_) do
			if not iter_4_5:isDeath() and not iter_4_5:isAffected() and var_4_5 > math.abs(iter_4_5:getX() - var_4_0:getX()) then
				table.insert(var_4_6, iter_4_5)
			end
		end

		local var_4_7 = arg_4_0:createAttackUnits(var_4_6, var_0_16)

		for iter_4_6, iter_4_7 in ipairs(var_4_7) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_7)
			table.insert(arg_4_0.records_.special_units, iter_4_7)
		end

		local var_4_8 = var_0_1.ctx.battle.getSpine(var_0_16, "area", 1)

		var_4_8:addTo(var_0_1.ctx.battle.unitBottomLayer)
		var_4_8:pos(var_4_0:getX(), var_4_0:getY())
		var_4_8:setScale(0.64)
		var_4_8:playOnce()
	end
end

function var_0_3.updateHp(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_0:getHp()

	var_0_3.super.updateHp(arg_5_0, arg_5_1, arg_5_2)

	local var_5_1 = arg_5_0:getHp()
	local var_5_2 = 1 - var_5_0 / arg_5_0:getHpLimit()
	local var_5_3 = 1 - var_5_1 / arg_5_0:getHpLimit()
	local var_5_4 = math.floor(var_5_3 / var_0_18) - math.floor(var_5_2 / var_0_18)

	arg_5_0.nGhostFires = arg_5_0.nGhostFires + var_5_4
end

function var_0_3.isAdImmortal(arg_6_0)
	if arg_6_0.nPhase == 2 or arg_6_0.nPhase == 3 then
		return true
	end

	return var_0_3.super.isAdImmortal(arg_6_0)
end

function var_0_3.isApImmortal(arg_7_0)
	if arg_7_0.nPhase == 4 or arg_7_0.nPhase == 5 then
		return true
	end

	return var_0_3.super.isApImmortal(arg_7_0)
end

function var_0_3.isImmortal(arg_8_0, arg_8_1)
	if arg_8_0.nPhase == 8 then
		for iter_8_0, iter_8_1 in ipairs(arg_8_0.summonHeros) do
			if not iter_8_1:isDeath() then
				return true
			end
		end
	end

	return var_0_3.super.isImmortal(arg_8_0, arg_8_1)
end

function var_0_3.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	if arg_9_0.nPhase == 7 and arg_9_4 > 0 then
		local var_9_0 = arg_9_0:createAttackUnits({
			arg_9_1.target
		}, var_0_24)

		for iter_9_0, iter_9_1 in ipairs(var_9_0) do
			table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
			table.insert(arg_9_0.records_.special_units, iter_9_1)
		end

		local var_9_1 = 0

		for iter_9_2, iter_9_3 in ipairs(arg_9_1.target:getBuffs()) do
			if iter_9_3.tableID_ == var_0_25 then
				var_9_1 = var_9_1 + 1
			end
		end

		arg_9_4 = arg_9_4 + var_9_1 * var_0_23
	end

	return arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7
end

function var_0_3.toDoPerFrames(arg_10_0)
	var_0_3.super.toDoPerFrames(arg_10_0)

	if arg_10_0.nPhase == 10 then
		if arg_10_0.addEnergyCD > 0 then
			arg_10_0.addEnergyCD = arg_10_0.addEnergyCD - 1
		else
			for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
				if not iter_10_1:isDeath() and not iter_10_1:isAffected() then
					local var_10_0 = iter_10_1:getEnergy()

					iter_10_1:updateEnergyBy(var_0_31)

					local var_10_1 = iter_10_1:getEnergy()
					local var_10_2 = math.max(var_0_31 - var_10_1 + var_10_0, 0) * var_0_32

					if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						local var_10_3 = arg_10_0:createAttackUnits({
							iter_10_1
						}, var_0_33)

						for iter_10_2, iter_10_3 in ipairs(var_10_3) do
							iter_10_3:setExtraHarm(var_10_2)
							table.insert(arg_10_0.moveAttackUnits_, iter_10_3)
							table.insert(arg_10_0.records_.special_units, iter_10_3)
						end
					end
				end
			end

			arg_10_0.addEnergyCD = var_0_30
		end

		for iter_10_4, iter_10_5 in ipairs(arg_10_0:getInfoByKey("attack_info")) do
			if iter_10_5.fighter_:getTeamType() ~= arg_10_0:getTeamType() and iter_10_5.rootID_ == iter_10_5.fighter_:getEnergySkillID() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_10_4 = arg_10_0:createAttackUnits({
					iter_10_5.fighter_
				}, var_0_34)

				for iter_10_6, iter_10_7 in ipairs(var_10_4) do
					table.insert(arg_10_0.moveAttackUnits_, iter_10_7)
					table.insert(arg_10_0.records_.special_units, iter_10_7)
				end
			end
		end
	end

	if arg_10_0.nPhase == 8 then
		if arg_10_0.summonHeroCD > 0 then
			arg_10_0.summonHeroCD = arg_10_0.summonHeroCD - 1
		elseif not arg_10_0:isImmortal() then
			for iter_10_8, iter_10_9 in ipairs(arg_10_0.sideTeam_) do
				if not iter_10_9:isDeath() and iter_10_9:getSummonType() == var_0_2.summonMonsterType.None then
					local var_10_5 = arg_10_0:summonHeroMirror(iter_10_9, iter_10_9:getLevel())

					table.insert(arg_10_0.summonHeros, var_10_5)
				end
			end

			arg_10_0.summonHeroCD = var_0_26
		end
	end
end

function var_0_3.summonHeroMirror(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_11_1 = arg_11_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_11_0 = var_0_1.ctx.battle.summonMonsters[var_11_1]

		if not var_11_0 then
			arg_11_0:summonMonstersErrorLog()
		end
	else
		local var_11_2 = var_0_8.new()
		local var_11_3 = arg_11_1.hero_:toParams()

		var_11_2:populate(var_11_3)

		var_11_2.level_ = arg_11_2 < 100 and arg_11_2 or 100

		local var_11_4 = var_11_2:className()

		var_11_0 = var_0_1.ctx.battle.requireFighter(var_11_4).new({
			is_arena = arg_11_0.isInArena_
		})

		var_11_0:populateWithHero(var_11_2)

		for iter_11_0, iter_11_1 in pairs(var_11_0.skillLevelByID_) do
			var_11_0.skillLevelByID_[iter_11_0] = arg_11_2
		end

		for iter_11_2, iter_11_3 in pairs(var_11_0.skillLevelByColor_) do
			if var_11_0.hero_:getSkillId(iter_11_2) > 0 then
				var_11_0.skillLevelByColor_[iter_11_2] = arg_11_2
			end
		end

		var_11_0:initModels()
		var_11_0.fighterModel:initHeaderView(arg_11_0:getTeamType() - 1)

		var_11_0.fighterIndex = arg_11_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_11_0:setFormationDelay(0, 100)

		var_11_0.startSkillQueue_ = {}
		var_11_0.skillQueue_ = arg_11_1.skillQueue_

		var_11_0:updateEnergyTo(arg_11_1:getEnergy())
	end

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		var_11_0:getFighterModel():setMaskColor(cc.c4f(1, 0.88, 0.46, 1))
		var_11_0:setDefaultMaskColor(cc.c4f(1, 0.88, 0.46, 1))
	end

	var_11_0.summonType_ = var_0_2.summonMonsterType.Copy

	var_11_0:setSummonAutoFight(true)

	var_11_0.hasReborn_ = true

	var_11_0:setTeamType(arg_11_0:getTeamType())

	var_11_0.summoner = arg_11_0

	var_11_0.fighterModel:pos(arg_11_1:getPos())
	var_11_0:getFighterModel():flipX(arg_11_1:getFlipX())
	var_11_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_11_0:born()
	var_11_0:setGlobalBuffs()
	var_11_0:updateHp(var_11_0:getHpLimit() * var_0_27)

	local var_11_5 = var_11_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_11_5, var_11_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_11_0)
	var_0_1.ctx.battle.updateZorder()

	return var_11_0
end

function var_0_3.addBuffs(arg_12_0, arg_12_1)
	if arg_12_0.nPhase == 9 then
		return var_0_4.addBuffs(arg_12_0, arg_12_1)
	else
		var_0_3.super.addBuffs(arg_12_0, arg_12_1)
	end
end

function var_0_3.isBreakImmortal(arg_13_0)
	return arg_13_0.nPhase ~= 9
end

return var_0_3
