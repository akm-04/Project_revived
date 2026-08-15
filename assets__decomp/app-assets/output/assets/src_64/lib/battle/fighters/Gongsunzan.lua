local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Gongsunzan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = 80000283
local var_0_6 = 40011054
local var_0_7 = 40011055
local var_0_8 = 10000961
local var_0_9 = 40011057
local var_0_10 = 10000964
local var_0_11 = 0
local var_0_12 = 0.002
local var_0_13 = 10000969

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isCreateBird_ = false
	arg_1_0.birdTarget_ = nil
	arg_1_0.isBlueType_ = false
	arg_1_0.isPurpleType_ = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		if arg_2_0.birdTarget_ and not arg_2_0.birdTarget_:isDeath() then
			arg_2_0.birdTarget_:updateHp(0)
			arg_2_0.birdTarget_:die()
		end

		return
	end

	if not arg_2_0.isCreateBird_ then
		arg_2_0.isCreateBird_ = true

		arg_2_0:summonMonster()
	end
end

function var_0_3.getOrbOfFrontSkill(arg_3_0)
	local var_3_0 = var_0_3.super.getOrbOfFrontSkill(arg_3_0)

	if arg_3_0.isBlueType_ and var_3_0 == arg_3_0:getPugongID() then
		var_3_0 = var_0_8
	end

	return var_3_0
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		if arg_4_0.birdTarget_ then
			arg_4_0.birdTarget_:setForceTarget(arg_4_1.target)
		end
	elseif var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and (arg_4_1.skillID == arg_4_0:getPugongID() or arg_4_1.skillID == var_0_8) then
		local var_4_0 = var_0_12 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) + var_0_11

		if var_0_2.weightedChoise({
			var_4_0,
			1 - var_4_0
		}) == 1 then
			local var_4_1 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, var_0_10)

			for iter_4_0, iter_4_1 in ipairs(var_4_1) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end
	elseif arg_4_1.skillID == var_0_13 and arg_4_0.birdTarget_ and not arg_4_0.birdTarget_:isDeath() then
		arg_4_0.birdTarget_:useSkill()
	end
end

function var_0_3.selectTargetByTypeD3(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = {}

	if arg_5_0.birdTarget_ and not arg_5_0.birdTarget_:isDeath() then
		table.insert(var_5_0, arg_5_0.birdTarget_)
	end

	table.insert(var_5_0, arg_5_0)

	return var_5_0
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	var_0_3.super.buffAddAction(arg_6_0, arg_6_1)

	if arg_6_1:getTableID() == var_0_7 then
		if arg_6_1.target == arg_6_0 then
			arg_6_0.isBlueType_ = true
		elseif arg_6_1.target == arg_6_0.birdTarget_ then
			arg_6_0.birdTarget_:setSpecialAttack(true)
		end
	elseif arg_6_1:getTableID() == var_0_9 and arg_6_1.target == arg_6_0 then
		arg_6_0.isPurpleType_ = true
	end
end

function var_0_3.buffRemoveAction(arg_7_0, arg_7_1)
	var_0_3.super.buffRemoveAction(arg_7_0, arg_7_1)

	if arg_7_1:getTableID() == var_0_7 then
		if arg_7_1.target == arg_7_0 then
			arg_7_0.isBlueType_ = false
		elseif arg_7_1.target == arg_7_0.birdTarget_ then
			arg_7_0.birdTarget_:setSpecialAttack(false)
		end
	elseif arg_7_1:getTableID() == var_0_9 and arg_7_1.target == arg_7_0 then
		arg_7_0.isPurpleType_ = false
	end
end

function var_0_3.summonMonster(arg_8_0)
	local var_8_0 = {
		var_0_5
	}

	if next(var_8_0) == nil then
		return
	end

	local var_8_1 = arg_8_0:getEnergySkillID()

	for iter_8_0, iter_8_1 in ipairs(var_8_0) do
		local var_8_2 = arg_8_0:getSkillLevelByID(var_8_1)
		local var_8_3 = arg_8_0.hero_:getColor()
		local var_8_4 = arg_8_0:getFlipX() == true and -1 or 1
		local var_8_5 = arg_8_0:getX() + var_8_4 * 100
		local var_8_6 = {
			x = var_8_5,
			y = arg_8_0:getY()
		}

		arg_8_0.birdTarget_ = arg_8_0:setSummonMonsters(iter_8_1, var_8_2, var_8_3, var_8_6)
	end
end

function var_0_3.setSummonMonsters(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4)
	local var_9_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_9_0 = arg_9_0:getSummonMonster()
	else
		local var_9_1 = var_0_4.new()

		var_9_1:populateWithTableID(arg_9_1)

		var_9_1.level_ = arg_9_2 or var_9_1.level_
		var_9_1.color_ = arg_9_3 or var_9_1.color_

		for iter_9_0, iter_9_1 in ipairs(var_9_1.skillLev_) do
			local var_9_2 = arg_9_0.hero_:getSkillLevel(iter_9_0)

			if var_9_2 and var_9_2 > 0 then
				var_9_1.skillLev_[iter_9_0] = var_0_0.clone(var_9_2)
			end
		end

		local var_9_3 = var_9_1:className()

		var_9_0 = var_0_1.ctx.battle.requireFighter(var_9_3).new({
			is_arena = arg_9_0.isInArena_
		})

		var_9_0:populateWithHero(var_9_1)
		var_9_0:initModels()
		var_9_0.fighterModel:initHeaderView(arg_9_0:getTeamType() - 1)

		var_9_0.fighterIndex = arg_9_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_9_0:setFormationDelay(0, 100)
	end

	var_9_0:setTeamType(arg_9_0:getTeamType())

	var_9_0.summoner = arg_9_0

	var_9_0.fighterModel:pos(arg_9_4.x, arg_9_4.y)
	var_9_0:getFighterModel():flipX(arg_9_0:getTeamType() == var_0_2.TeamType.B)
	var_9_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_9_0:born()
	var_9_0:setGlobalBuffs()
	var_9_0:updateHp(var_9_0:getHpLimit())

	local var_9_4 = var_9_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_9_4, var_9_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_9_0)
	var_0_1.ctx.battle.updateZorder()

	return var_9_0
end

return var_0_3
