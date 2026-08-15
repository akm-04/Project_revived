local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Lingtong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = var_0_2.tables.dbuff
local var_0_10 = 15
local var_0_11 = 20010081
local var_0_12 = 10000146

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.summonMonsters_ = {}
	arg_1_0.summonMonster_ = nil
	arg_1_0.robotCount_ = 0
end

function var_0_3.die(arg_2_0)
	if arg_2_0.summonMonster_ and arg_2_0.summonMonster_:isDeath() ~= true then
		arg_2_0.summonMonster_:updateHp(0)
		arg_2_0.summonMonster_:die()
	end

	var_0_3.super.die(arg_2_0)
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if arg_3_1.rootID_ == arg_3_0:getEnergySkillID() then
		arg_3_0.robotNum_ = var_0_0.clone(arg_3_0.robotCount_)
		arg_3_0.robotCount_ = 0
	end
end

function var_0_3.selectTargetByTypeD2(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0
	local var_4_1
	local var_4_2
	local var_4_3 = arg_4_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_4_4 = arg_4_0:getTeamType() ~= var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_4_5 = arg_4_0:isAttackFriend() and var_4_3 or var_4_4
	local var_4_6

	for iter_4_0, iter_4_1 in ipairs(var_4_5) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and (not var_4_6 or var_4_6:getAD() < iter_4_1:getAD()) then
			var_4_6 = iter_4_1
		end
	end

	if var_4_6 == nil then
		return {}
	end

	return {
		var_4_6
	}
end

function var_0_3.selectTargetByTypeD3(arg_5_0, arg_5_1, arg_5_2)
	return {
		arg_5_0
	}
end

function var_0_3.playShanbi(arg_6_0, arg_6_1)
	var_0_3.super.playShanbi(arg_6_0, arg_6_1)

	if arg_6_0.unitSkills_ and arg_6_0.unitSkills_.rootID_ == arg_6_0:getEnergySkillID() then
		if arg_6_0.robotNum_ then
			arg_6_0.robotNum_ = math.min(arg_6_0.robotNum_ + 1, var_0_10)
		end
	else
		arg_6_0.robotCount_ = math.min(arg_6_0.robotCount_ + 1, var_0_10)
	end

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_0 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_6_1 = {
			arg_6_0
		}
		local var_6_2 = arg_6_0:createAttackUnits(var_6_1, var_6_0)

		for iter_6_0, iter_6_1 in ipairs(var_6_2) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_4 > 0 and arg_7_1.skillID == var_0_12 then
		arg_7_4 = arg_7_0.robotNum_ * arg_7_0.robotNum_ / (var_0_10 * var_0_10) * arg_7_4
	end

	arg_7_1:recordData(arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.moveUnitArrive(arg_8_0, arg_8_1)
	var_0_3.super.moveUnitArrive(arg_8_0, arg_8_1)

	local var_8_0 = arg_8_1.skillID
	local var_8_1 = var_0_6:summonMonster(var_8_0)

	if next(var_8_1) == nil then
		return
	end

	local var_8_2 = (arg_8_0:getFlipX() and 150 or -150) + arg_8_1.desX_
	local var_8_3 = math.max(100, var_8_2)
	local var_8_4 = math.min(var_0_2.STAGE_WIDTH - 100, var_8_3)

	for iter_8_0, iter_8_1 in ipairs(var_8_1) do
		local var_8_5 = arg_8_0:getSkillLevelByID(var_8_0)
		local var_8_6 = arg_8_0.hero_:getColor()
		local var_8_7 = {
			x = var_8_4,
			y = arg_8_1.desY_
		}

		arg_8_0:setSummonMonsters(iter_8_1, var_8_5, var_8_6, var_8_7)
	end
end

function var_0_3.setSummonMonsters(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4)
	local var_9_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_9_0 = arg_9_0:getSummonMonster()
	else
		local var_9_1 = var_0_5.new()

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
	var_9_0:updateHp(var_9_0:getHpLimit())
	var_9_0:getFighterModel():flipX(arg_9_0:getTeamType() == var_0_2.TeamType.B)
	var_9_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_9_0:born()
	var_9_0:setGlobalBuffs()

	local var_9_4 = var_9_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_9_4, var_9_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_9_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_9_0.summonMonsters_, var_9_0)

	if var_9_0.summonType_ == var_0_2.summonMonsterType.Monster then
		if arg_9_0.summonMonster_ then
			arg_9_0.summonMonster_:updateHp(0)
			arg_9_0.summonMonster_:die()
			var_0_0.table.removebyvalue(arg_9_0.summonMonsters_, arg_9_0.summonMonster_)
		end

		arg_9_0.summonMonster_ = var_9_0
	end
end

function var_0_3.getHuJia(arg_10_0)
	local var_10_0 = var_0_9:init(var_0_11)
	local var_10_1 = var_0_9:step(var_0_11)

	return var_0_3.super.getHuJia(arg_10_0) + var_10_0 + var_10_1 * arg_10_0.robotCount_
end

return var_0_3
