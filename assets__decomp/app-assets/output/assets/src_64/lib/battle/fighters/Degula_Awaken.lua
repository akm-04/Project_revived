local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Degula", var_0_1.ctx.battle.requireFighter("Degula"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = 10001153
local var_0_7 = 90
local var_0_8 = 8
local var_0_9 = 80030066
local var_0_10 = 10001872
local var_0_11 = 10001871

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyAwakeCountDown = 0
	arg_1_0.summonMonsters_ = {}
	arg_1_0.batNum = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0.isEnergyBuff_ then
		arg_2_0.energyAwakeCountDown = arg_2_0.energyAwakeCountDown - 1

		if arg_2_0.energyAwakeCountDown <= 0 then
			arg_2_0.energyAwakeCountDown = var_0_7

			arg_2_0:summonABat()
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if var_0_4:father(arg_3_1.skillID) == arg_3_0:getEnergySkillID() and arg_3_1.target == arg_3_0 then
		arg_3_0.energyAwakeCountDown = var_0_7

		arg_3_0:summonThreeBat()
	end
end

function var_0_3.deathFeedback(arg_4_0, arg_4_1)
	var_0_3.super.deathFeedback(arg_4_0, arg_4_1)

	if arg_4_1.hero_:getTableID() == var_0_4:summonMonster(var_0_6)[1] and arg_4_1:getTeamType() == arg_4_0:getTeamType() then
		arg_4_0.batNum = arg_4_0.batNum - 1
	end
end

function var_0_3.summonThreeBat(arg_5_0)
	for iter_5_0 = 1, 3 do
		if arg_5_0.batNum < var_0_8 then
			local var_5_0 = var_0_4:summonMonster(var_0_6)

			for iter_5_1, iter_5_2 in pairs(var_5_0) do
				local var_5_1 = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
				local var_5_2 = arg_5_0.hero_:getColor()
				local var_5_3 = arg_5_0:getFlipX() and arg_5_0:getX() - 75 or arg_5_0:getX() + 75
				local var_5_4 = var_0_1.ctx.battle.adjustX(var_5_3, arg_5_0)
				local var_5_5 = {
					x = var_5_4,
					y = arg_5_0:getY() - 150 + 60 * iter_5_0
				}

				arg_5_0:setSummonMonsters(iter_5_2, var_5_1, var_5_2, var_5_5)
			end

			arg_5_0.batNum = arg_5_0.batNum + 1

			if arg_5_0.isSkinSkillOn_ and arg_5_0.skinSkillID_ == var_0_9 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_5_6 = arg_5_0:createAttackUnits(arg_5_0:selectTargetByTypeD1(var_0_11), var_0_11)

				for iter_5_3, iter_5_4 in ipairs(var_5_6) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_4)
					table.insert(arg_5_0.records_.special_units, iter_5_4)
				end
			end
		end
	end
end

function var_0_3.summonABat(arg_6_0)
	if arg_6_0.batNum < var_0_8 then
		local var_6_0 = var_0_4:summonMonster(var_0_6)

		for iter_6_0, iter_6_1 in pairs(var_6_0) do
			local var_6_1 = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
			local var_6_2 = arg_6_0.hero_:getColor()
			local var_6_3 = arg_6_0:getFlipX() and arg_6_0:getX() - 75 or arg_6_0:getX() + 75
			local var_6_4 = var_0_1.ctx.battle.adjustX(var_6_3, arg_6_0)
			local var_6_5 = {
				x = var_6_4,
				y = arg_6_0:getY()
			}

			arg_6_0:setSummonMonsters(iter_6_1, var_6_1, var_6_2, var_6_5)
		end

		arg_6_0.batNum = arg_6_0.batNum + 1

		if arg_6_0.isSkinSkillOn_ and arg_6_0.skinSkillID_ == var_0_9 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_6 = arg_6_0:createAttackUnits(arg_6_0:selectTargetByTypeD1(var_0_11), var_0_11)

			for iter_6_2, iter_6_3 in ipairs(var_6_6) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
				table.insert(arg_6_0.records_.special_units, iter_6_3)
			end
		end
	end
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

		for iter_7_0, iter_7_1 in ipairs(var_7_1.skillLev_) do
			local var_7_2 = var_7_1:getSkillId(iter_7_0)
			local var_7_3 = arg_7_0.hero_:getSkillLevelByID(var_7_2)

			if var_7_3 and var_7_3 > 0 then
				var_7_1.skillLev_[iter_7_0] = var_7_3
			end
		end

		local var_7_4 = var_7_1:className()

		var_7_0 = var_0_1.ctx.battle.requireFighter(var_7_4).new({
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

	var_7_0.fighterModel:pos(arg_7_4.x, arg_7_4.y)
	var_7_0:updateHp(var_7_0:getHpLimit())
	var_7_0:getFighterModel():flipX(arg_7_0:getTeamType() == var_0_2.TeamType.B)
	var_7_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_7_0:born()
	var_7_0:setGlobalBuffs()

	local var_7_5 = var_7_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_7_5, var_7_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_7_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_7_0.summonMonsters_, var_7_0)
end

function var_0_3.forceDie(arg_8_0)
	for iter_8_0, iter_8_1 in ipairs(arg_8_0.summonMonsters_) do
		iter_8_1:forceDie()
	end

	var_0_3.super.forceDie(arg_8_0)
end

return var_0_3
