local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yuji", var_0_1.ctx.battle.requireFighter("Yuji"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = 8
local var_0_7 = 50010009
local var_0_8 = 60020009
local var_0_9 = 10001330
local var_0_10 = 1000
local var_0_11 = 95
local var_0_12 = 200
local var_0_13 = 18
local var_0_14 = 200

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.deadBody_ = nil
	arg_1_0.summonMonsters_ = {}
	arg_1_0.TwiceAwakenUnitHitCounts = {}
end

function var_0_3.die(arg_2_0)
	for iter_2_0, iter_2_1 in ipairs(arg_2_0.summonMonsters_) do
		if not iter_2_1:isDeath() then
			iter_2_1:updateHp(0)
			iter_2_1:die()
		end
	end

	var_0_3.super.die(arg_2_0)
end

function var_0_3.deathFeedback(arg_3_0, arg_3_1)
	var_0_3.super.deathFeedback(arg_3_0, arg_3_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_3_0.TwiceAwakenUnitHitCounts[arg_3_1] == var_0_1.ctx.battle.count then
		local var_3_0 = arg_3_0:createAttackUnits({
			arg_3_0
		}, var_0_9)

		for iter_3_0, iter_3_1 in ipairs(var_3_0) do
			iter_3_1.basicHarm = var_0_12 + arg_3_0:getSkillLevelByID(var_0_8) * var_0_13

			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end
	end

	if arg_3_1:getSummonType() ~= var_0_2.summonMonsterType.None or arg_3_1 == arg_3_0 then
		return
	end

	arg_3_0.deadBody_ = arg_3_1
end

function var_0_3.getOrbOfFrontSkill(arg_4_0)
	local var_4_0 = var_0_3.super.getFrontSkill(arg_4_0)

	if not arg_4_0.deadBody_ or var_4_0 == arg_4_0:getEnergySkillID() then
		return var_0_3.super.getOrbOfFrontSkill(arg_4_0)
	end

	return arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)
end

function var_0_3.canSummonBat(arg_5_0)
	local var_5_0 = 0

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.summonMonsters_) do
		if not iter_5_1:isDeath() then
			var_5_0 = var_5_0 + 1
		end
	end

	if var_5_0 < var_0_6 then
		return true
	else
		return false
	end
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if var_0_4:father(arg_6_1.skillID) == var_0_7 and arg_6_0:getSkillLevelByID(var_0_8) > 0 then
		local var_6_0 = 0
		local var_6_1 = {}

		for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
			if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1:getX() - var_0_14 < arg_6_1.target:getX() and arg_6_1.target:getX() < iter_6_1:getX() + var_0_14 then
				if iter_6_1:getSummonType() == var_0_2.summonMonsterType.None then
					if iter_6_1 ~= arg_6_1.target then
						table.insert(var_6_1, iter_6_1)
					end
				else
					iter_6_1:forceDie()

					var_6_0 = var_6_0 + 1
				end
			end
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_2 = arg_6_0:createAttackUnits(var_6_1, var_0_8)

			for iter_6_2, iter_6_3 in ipairs(var_6_2) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
				table.insert(arg_6_0.records_.special_units, iter_6_3)
			end

			local var_6_3 = arg_6_0:createAttackUnits({
				arg_6_0
			}, var_0_9)

			for iter_6_4, iter_6_5 in ipairs(var_6_3) do
				iter_6_5.basicHarm = var_0_10 + arg_6_0:getSkillLevelByID(var_0_8) * var_0_11 + var_6_0 * (var_0_12 + arg_6_0:getSkillLevelByID(var_0_8) * var_0_13)

				table.insert(arg_6_0.moveAttackUnits_, iter_6_5)
				table.insert(arg_6_0.records_.special_units, iter_6_5)
			end
		end
	end

	if arg_6_1.skillID ~= arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) then
		return
	end

	if not arg_6_0.deadBody_ or arg_6_0.deadBody_.isSummon then
		arg_6_0.deadBody_ = nil

		return
	end

	local var_6_4 = arg_6_1.skillID
	local var_6_5 = var_0_4:summonMonster(var_6_4)

	if next(var_6_5) == nil then
		return
	end

	for iter_6_6, iter_6_7 in ipairs(var_6_5) do
		local var_6_6 = arg_6_0:getSkillLevelByID(var_6_4)
		local var_6_7 = arg_6_0.hero_:getColor()
		local var_6_8 = {
			x = arg_6_0.deadBody_:getX(),
			y = arg_6_0.deadBody_:getY()
		}

		if arg_6_0:canSummonBat() then
			arg_6_0:setSummonMonsters(iter_6_7, var_6_6, var_6_7, var_6_8)
		end
	end

	arg_6_0.deadBody_.isSummon = true
	arg_6_0.deadBody_ = nil
end

function var_0_3.setSummonMonsters(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4)
	local var_7_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_7_0 = arg_7_0:getSummonMonster()
	else
		local var_7_1 = var_0_5.new()

		var_7_1:populateWithTableID(arg_7_1)

		var_7_1.level_ = arg_7_2 or var_7_1.level_
		var_7_1.color_ = arg_7_3 or var_7_1.color_

		for iter_7_0, iter_7_1 in pairs(var_7_1.skillLev_) do
			var_7_1.skillLev_[iter_7_0] = arg_7_0.hero_.skillLev_[iter_7_0]
		end

		local var_7_2 = var_7_1:className()

		var_7_0 = var_0_1.ctx.battle.requireFighter(var_7_2).new({
			is_arena = arg_7_0.isInArena_
		})

		var_7_0:populateWithHero(var_7_1)
		var_7_0:initModels()
		var_7_0.fighterModel:initHeaderView(arg_7_0:getTeamType() - 1)

		var_7_0.fighterIndex = arg_7_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_7_0:setFormationDelay(0, 100)
	end

	var_7_0:setTeamType(arg_7_0:getTeamType())

	var_7_0.summoner = arg_7_0

	var_7_0.fighterModel:pos(arg_7_4.x, arg_7_4.y - #arg_7_0.summonMonsters_)
	var_7_0:updateHp(var_7_0:getHpLimit())
	var_7_0:getFighterModel():flipX(arg_7_0:getTeamType() == var_0_2.TeamType.B)
	var_7_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_7_0:born()
	var_7_0:setGlobalBuffs()

	local var_7_3 = var_7_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_7_3, var_7_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_7_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_7_0.summonMonsters_, var_7_0)
end

function var_0_3.updateUnitInfoBySpecialHero(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_8_0:getSkillLevelByID(var_0_8) > 0 and arg_8_1.skillID == var_0_7 or arg_8_1.skillID == var_0_8 and arg_8_1.target:getSummonType() == var_0_2.summonMonsterType.None then
		arg_8_0.TwiceAwakenUnitHitCounts[arg_8_1.target] = var_0_1.ctx.battle.count
	end
end

return var_0_3
