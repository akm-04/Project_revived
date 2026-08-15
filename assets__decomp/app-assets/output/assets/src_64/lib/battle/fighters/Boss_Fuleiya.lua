local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fuleiya", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = 0.003
local var_0_8 = 1.5

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyCount = 0
	arg_1_0.energyMonster1 = nil
	arg_1_0.energyMonster2 = nil
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	local var_2_0 = arg_2_1.skillID

	if var_0_4:father(var_2_0) == arg_2_0:getEnergySkillID() then
		arg_2_0.energyCount = arg_2_0.energyCount + 1

		arg_2_0:energySkill(arg_2_1)
	end
end

function var_0_3.energySkill(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1.skillID
	local var_3_1 = var_0_4:summonMonster(var_3_0)
	local var_3_2 = arg_3_0:getSkillLevelByID(var_3_0)
	local var_3_3 = arg_3_0.hero_:getColor()
	local var_3_4 = arg_3_0:getFlipX() == true and -1 or 1

	for iter_3_0, iter_3_1 in ipairs(var_3_1) do
		local var_3_5 = var_0_6.B17(arg_3_0)[1]
		local var_3_6 = {
			x = var_3_5:getX() + var_3_4 * 40,
			y = var_3_5:getY() - iter_3_0 * 40
		}

		if iter_3_0 == 1 then
			if arg_3_0.energyMonster1 then
				arg_3_0.energyMonster1:updateHp(0)
				arg_3_0.energyMonster1:die()

				arg_3_0.energyMonster1 = nil
			end

			arg_3_0.energyMonster1 = arg_3_0:setSummonMonsters(iter_3_1, var_3_2, var_3_3, var_3_6)
		elseif iter_3_0 == 2 then
			if arg_3_0.energyMonster2 then
				arg_3_0.energyMonster2:updateHp(0)
				arg_3_0.energyMonster2:die()

				arg_3_0.energyMonster2 = nil
			end

			arg_3_0.energyMonster2 = arg_3_0:setSummonMonsters(iter_3_1, var_3_2, var_3_3, var_3_6)
		end
	end
end

function var_0_3.setSummonMonsters(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4)
	local var_4_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_4_1 = arg_4_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_4_0 = var_0_1.ctx.battle.summonMonsters[var_4_1]
	else
		local var_4_2 = var_0_5.new()

		var_4_2:populateWithTableID(arg_4_1)

		var_4_2.level_ = arg_4_2 or var_4_2.level_
		var_4_2.color_ = arg_4_3 or var_4_2.color_

		for iter_4_0, iter_4_1 in pairs(var_4_2.skillLev_) do
			var_4_2.skillLev_[iter_4_0] = arg_4_0.hero_.skillLev_[iter_4_0]
		end

		if arg_4_0.energyCount == 1 then
			var_4_2.skillLev_[var_0_2.SKILL_INDEX.Green] = false
			var_4_2.skillLev_[var_0_2.SKILL_INDEX.Blue] = false
		elseif arg_4_0.energyCount == 2 then
			var_4_2.skillLev_[var_0_2.SKILL_INDEX.Blue] = false
		end

		local var_4_3 = var_4_2:className()

		var_4_0 = var_0_1.ctx.battle.requireFighter(var_4_3).new({
			is_arena = arg_4_0.isInArena_
		})

		var_4_0:populateWithHero(var_4_2)
		var_4_0:initModels()
		var_4_0.fighterModel:initHeaderView(arg_4_0:getTeamType() - 1)

		var_4_0.fighterIndex = arg_4_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_4_0:setFormationDelay(0, 100)
	end

	var_4_0:setTeamType(arg_4_0:getTeamType())

	var_4_0.summoner = arg_4_0

	var_4_0:setupHpLimit()
	var_4_0.fighterModel:pos(arg_4_4.x, arg_4_4.y)
	var_4_0:updateHp(var_4_0:getHpLimit())
	var_4_0:getFighterModel():flipX(arg_4_0:getTeamType() == var_0_2.TeamType.B)
	var_4_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_4_0:born()
	var_4_0:setGlobalBuffs()

	local var_4_4 = var_4_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_4_4, var_4_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_4_0)
	var_0_1.ctx.battle.updateZorder()

	return var_4_0
end

function var_0_3.die(arg_5_0)
	var_0_3.super.die(arg_5_0)

	if arg_5_0.energyMonster1 and not arg_5_0.energyMonster1:isDeath() then
		arg_5_0.energyMonster1:updateHp(0)
		arg_5_0.energyMonster1:die()

		arg_5_0.energyMonster1 = nil
	end

	if arg_5_0.energyMonster2 and not arg_5_0.energyMonster2:isDeath() then
		arg_5_0.energyMonster2:updateHp(0)
		arg_5_0.energyMonster2:die()

		arg_5_0.energyMonster2 = nil
	end
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and (arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_6_1.skillID == arg_6_0:getPugongID()) then
		arg_6_7 = arg_6_7 - var_0_8 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.updateUnitDataByTarget(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataByTarget(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if not arg_7_0.skillShanbi then
		arg_7_0.skillShanbi = 0
		arg_7_0.notskillShanbi = 0
	end

	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		local var_7_0 = var_0_7 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

		if var_0_2.weightedChoise({
			var_7_0,
			1 - var_7_0
		}) == 1 then
			arg_7_2 = true
			arg_7_0.skillShanbi = arg_7_0.skillShanbi + 1
		else
			arg_7_0.notskillShanbi = arg_7_0.notskillShanbi + 1
		end
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

return var_0_3
