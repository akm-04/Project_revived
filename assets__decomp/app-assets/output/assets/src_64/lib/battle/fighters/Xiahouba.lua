local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xiahouba", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 0.1
local var_0_8 = 0.005
local var_0_9 = 10000552
local var_0_10 = 10000554
local var_0_11 = 10000553
local var_0_12 = 3
local var_0_13 = 10000555
local var_0_14 = 10000556
local var_0_15 = 10000557
local var_0_16 = 40010404
local var_0_17 = {
	40010402,
	40010403,
	40010404
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.mushroomNum_ = {
		green = 0,
		yellow = 0,
		red = 0
	}
	arg_1_0.summonMonsters_ = {}
end

function var_0_3.getOrbOfFrontSkill(arg_2_0)
	local var_2_0 = var_0_3.super.getOrbOfFrontSkill(arg_2_0)

	if var_2_0 == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		return arg_2_0:getGreenSkillID() or var_2_0
	end

	return var_2_0
end

function var_0_3.getMaxHarmEnemy(arg_3_0)
	local var_3_0
	local var_3_1

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.targetTeam_) do
		if (not iter_3_1:isDeath() or iter_3_1:canReborn()) and iter_3_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_3_1 or var_3_1 < iter_3_1.harms) then
			var_3_0 = iter_3_1
			var_3_1 = iter_3_1.harms
		end
	end

	return var_3_0
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_0
		local var_4_1 = {
			var_0_9,
			var_0_10,
			var_0_11
		}

		for iter_4_0, iter_4_1 in ipairs(var_4_1) do
			if iter_4_1 == arg_4_1.rootID_ then
				var_4_0 = iter_4_0

				break
			end
		end

		if var_4_0 then
			local var_4_2 = ({
				"red",
				"green",
				"yellow"
			})[var_4_0]

			arg_4_0.mushroomNum_[var_4_2] = arg_4_0.mushroomNum_[var_4_2] + 1

			if arg_4_0.mushroomNum_[var_4_2] >= var_0_12 then
				arg_4_0.mushroomNum_[var_4_2] = 0

				local var_4_3 = {}

				for iter_4_2, iter_4_3 in ipairs(arg_4_0.targetTeam_) do
					if not iter_4_3:isDeath() and not iter_4_3:isAffected() then
						table.insert(var_4_3, iter_4_3)
					end
				end

				local var_4_4 = arg_4_0:createAttackUnits(var_4_3, var_0_13)

				for iter_4_4, iter_4_5 in ipairs(var_4_4) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
					table.insert(arg_4_0.records_.special_units, iter_4_5)
				end

				local var_4_5 = arg_4_0:createAttackUnits(var_4_3, var_0_14)

				for iter_4_6, iter_4_7 in ipairs(var_4_5) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_7)
					table.insert(arg_4_0.records_.special_units, iter_4_7)
				end

				local var_4_6 = arg_4_0:createAttackUnits({
					arg_4_0
				}, var_0_15)

				for iter_4_8, iter_4_9 in ipairs(var_4_6) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_9)
					table.insert(arg_4_0.records_.special_units, iter_4_9)
				end
			end
		end
	end
end

function var_0_3.getGreenSkillID(arg_5_0)
	local var_5_0 = 0
	local var_5_1 = 0
	local var_5_2 = 0
	local var_5_3 = 0
	local var_5_4 = {
		var_0_9,
		var_0_10,
		var_0_11
	}

	if #arg_5_0.targetTeam_ == 0 then
		return
	end

	local var_5_5 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
		if not iter_5_1:isDeath() and (iter_5_1:getSummonType() == var_0_2.summonMonsterType.Monster or iter_5_1:getSummonType() == var_0_2.summonMonsterType.None) then
			table.insert(var_5_5, iter_5_1)
		end
	end

	for iter_5_2, iter_5_3 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_3:isDeath() and (iter_5_3:getSummonType() == var_0_2.summonMonsterType.Monster or iter_5_3:getSummonType() == var_0_2.summonMonsterType.None) then
			table.insert(var_5_5, iter_5_3)
		end
	end

	for iter_5_4, iter_5_5 in ipairs(var_5_5) do
		if iter_5_5.hero_:getHeroType() == var_0_2.HeroType.STRENGTH then
			var_5_0 = var_5_0 + 1
		elseif iter_5_5.hero_:getHeroType() == var_0_2.HeroType.WISE then
			var_5_1 = var_5_1 + 1
		else
			var_5_2 = var_5_2 + 1
		end
	end

	local var_5_6 = arg_5_0:getMaxHarmEnemy()
	local var_5_7 = 1

	if var_5_6 then
		var_5_7 = var_5_6.hero_:getHeroType()
	end

	if var_5_1 <= var_5_0 and var_5_2 <= var_5_0 then
		if var_5_0 == var_5_1 or var_5_0 == var_5_2 then
			var_5_3 = var_5_7
		else
			var_5_3 = 1
		end
	elseif var_5_2 <= var_5_1 then
		if var_5_1 == var_5_2 then
			var_5_3 = var_5_7
		else
			var_5_3 = 2
		end
	else
		var_5_3 = 3
	end

	return var_5_4[var_5_3]
end

function var_0_3.moveUnitArrive(arg_6_0, arg_6_1)
	var_0_3.super.moveUnitArrive(arg_6_0, arg_6_1)

	local var_6_0 = arg_6_1.skillID
	local var_6_1 = var_0_6:summonMonster(var_6_0)

	if next(var_6_1) == nil then
		return
	end

	for iter_6_0, iter_6_1 in ipairs(var_6_1) do
		local var_6_2 = arg_6_0:getSkillLevelByID(var_6_0)
		local var_6_3 = arg_6_0.hero_:getColor()
		local var_6_4 = {
			x = arg_6_1.desX_,
			y = arg_6_1.desY_
		}
		local var_6_5 = unpack(arg_6_0:selectTargetByTypeD3())
		local var_6_6

		if var_6_5 then
			var_6_6 = var_6_5.harms or 0
		else
			var_6_6 = arg_6_0:getMaxHarm()
		end

		local var_6_7 = var_6_6 * (var_0_7 + var_0_8 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))

		arg_6_0:setSummonMonsters(iter_6_1, var_6_2, var_6_3, var_6_4, var_6_7, var_6_5)
	end
end

function var_0_3.getMaxHarm(arg_7_0)
	local var_7_0

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.targetTeam_) do
		if iter_7_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_7_0 or var_7_0 < iter_7_1.harms) then
			var_7_0 = iter_7_1.harms
		end
	end

	return var_7_0 or 0
end

function var_0_3.setSummonMonsters(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6)
	local var_8_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_8_0 = arg_8_0:getSummonMonster()
	else
		local var_8_1 = var_0_4.new()

		var_8_1:populateWithTableID(arg_8_1)

		var_8_1.level_ = arg_8_2 or var_8_1.level_
		var_8_1.color_ = arg_8_3 or var_8_1.color_
		var_8_1.skillLev_[var_0_2.SKILL_INDEX.Energy] = arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)

		local var_8_2 = var_8_1:className()

		var_8_0 = var_0_1.ctx.battle.requireFighter(var_8_2).new({
			is_arena = arg_8_0.isInArena_
		})

		var_8_0:populateWithHero(var_8_1)
		var_8_0:initModels()
		var_8_0.fighterModel:initHeaderView(arg_8_0:getTeamType() - 1)

		var_8_0.fighterIndex = arg_8_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_8_0:setFormationDelay(0, 100)
	end

	var_8_0:setTeamType(arg_8_0:getTeamType())

	var_8_0.summoner = arg_8_0

	var_8_0.fighterModel:pos(arg_8_4.x, arg_8_4.y)
	var_8_0:resetHpLimit(arg_8_5 + var_8_0:getHpLimit())
	var_8_0:updateHp(var_8_0:getHpLimit())
	var_8_0:getFighterModel():flipX(arg_8_0:getTeamType() == var_0_2.TeamType.B)
	var_8_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_8_0:born()
	var_8_0:setGlobalBuffs()

	var_8_0.foucsTarget_ = arg_8_6

	if arg_8_6 then
		local var_8_3 = arg_8_0:getEnergySkillID()
		local var_8_4 = {}

		for iter_8_0, iter_8_1 in ipairs(var_0_17) do
			local var_8_5 = var_0_5.new({
				tableID = iter_8_1,
				start = var_0_1.ctx.battle.count,
				level = arg_8_0:getSkillLevelByID(var_8_3),
				skillID = var_8_3,
				fighter = arg_8_0,
				target = arg_8_6
			})

			var_8_5:setIsHit(true)
			var_8_5:setDirection(arg_8_6:getFighterModel():getFlipX())

			if var_8_5:getTableID() == var_0_16 then
				var_8_5:setForceTarget(var_8_0)
			end

			table.insert(var_8_4, var_8_5)
		end

		arg_8_6:addBuffs(var_8_4)
	end

	local var_8_6 = var_8_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_8_6, var_8_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_8_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_8_0.summonMonsters_, var_8_0)
end

function var_0_3.die(arg_9_0)
	for iter_9_0, iter_9_1 in ipairs(arg_9_0.summonMonsters_) do
		if not iter_9_1:isDeath() then
			iter_9_1:updateHp(0)
			iter_9_1:die()
		end
	end

	var_0_3.super.die(arg_9_0)
end

function var_0_3.selectTargetByTypeD1(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0
	local var_10_1

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.targetTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and iter_10_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_10_2 = iter_10_1:getAD()

			if not var_10_1 or var_10_1 < var_10_2 then
				var_10_0 = iter_10_1
				var_10_1 = var_10_2
			end
		end
	end

	return {
		var_10_0
	}
end

function var_0_3.selectTargetByTypeD2(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0
	local var_11_1

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.targetTeam_) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() and iter_11_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_11_2 = iter_11_1:getAP()

			if not var_11_1 or var_11_1 < var_11_2 then
				var_11_0 = iter_11_1
				var_11_1 = var_11_2
			end
		end
	end

	return {
		var_11_0
	}
end

function var_0_3.selectTargetByTypeD3(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0
	local var_12_1

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.targetTeam_) do
		if not iter_12_1:isDeath() and not iter_12_1:isAffected() and iter_12_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_12_1 or var_12_1 < iter_12_1.harms) then
			var_12_0 = iter_12_1
			var_12_1 = iter_12_1.harms
		end
	end

	return {
		var_12_0
	}
end

return var_0_3
