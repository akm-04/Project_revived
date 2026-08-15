local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Huangyueying", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = 10001896
local var_0_10 = 10001916
local var_0_11 = 10001900
local var_0_12 = 10001906

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.summonMonsters_ = {}
	arg_1_0.summonMonster_ = nil
end

function var_0_3.die(arg_2_0)
	if arg_2_0.summonMonster_ and arg_2_0.summonMonster_:isDeath() ~= true then
		arg_2_0.summonMonster_:updateHp(0)
		arg_2_0.summonMonster_:die()
	end

	var_0_3.super.die(arg_2_0)
end

function var_0_3.populateWithHero(arg_3_0, arg_3_1)
	var_0_3.super.populateWithHero(arg_3_0, arg_3_1)

	if arg_3_0.skinSkillIndex_ == 1 then
		arg_3_0.SummonSkill = var_0_12
	else
		arg_3_0.SummonSkill = var_0_11
	end
end

function var_0_3.selectTargetByTypeD1(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_2 and arg_4_2.manualTargets_ then
		return arg_4_2.manualTargets_
	end

	local var_4_0 = var_0_4.B3(arg_4_0, arg_4_1)

	if not var_4_0 then
		return {}
	end

	local var_4_1 = {
		var_4_0
	}
	local var_4_2, var_4_3 = var_0_4.getTeam(arg_4_0)

	for iter_4_0, iter_4_1 in ipairs(var_4_3) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and iter_4_1 ~= var_4_0 and math.abs(iter_4_1:getX() - var_4_0:getX()) < var_0_6:scope(arg_4_1) / 2 then
			table.insert(var_4_1, iter_4_1)
		end
	end

	return var_4_1
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)

	if arg_5_1.rootID_ == var_0_10 and arg_5_0.summonMonster_ and not arg_5_0.summonMonster_:isDeath() then
		arg_5_0.summonMonster_:createSkillByID(var_0_9, arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy), 3)
	end
end

function var_0_3.moveUnitArrive(arg_6_0, arg_6_1)
	var_0_3.super.moveUnitArrive(arg_6_0, arg_6_1)

	local var_6_0 = arg_6_1.skillID
	local var_6_1 = var_0_6:summonMonster(var_6_0)

	if next(var_6_1) == nil then
		return
	end

	if arg_6_0.summonMonster_ then
		arg_6_0.summonMonster_:updateHp(0)
		arg_6_0.summonMonster_:die()
		var_0_0.table.removebyvalue(arg_6_0.summonMonsters_, arg_6_0.summonMonster_)
	end

	for iter_6_0, iter_6_1 in ipairs(var_6_1) do
		local var_6_2 = arg_6_0:getSkillLevelByID(var_6_0)
		local var_6_3 = arg_6_0.hero_:getColor()
		local var_6_4 = {
			x = arg_6_1.desX_,
			y = arg_6_1.desY_
		}

		arg_6_0.summonMonster_ = arg_6_0:setSummonMonsters(iter_6_1, var_6_2, var_6_3, var_6_4)
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

	return var_7_0
end

function var_0_3.getOrbOfFrontSkill(arg_8_0)
	local var_8_0 = var_0_3.super.getOrbOfFrontSkill(arg_8_0)

	if var_8_0 == arg_8_0:getEnergySkillID() then
		if arg_8_0.isSkinSkillOn_ then
			if arg_8_0.summonMonster_ and not arg_8_0.summonMonster_:isDeath() then
				var_8_0 = var_0_10
			else
				var_8_0 = arg_8_0.SummonSkill
			end
		else
			var_8_0 = arg_8_0.SummonSkill
		end
	end

	return var_8_0
end

function var_0_3.energyDecimalBase(arg_9_0)
	if arg_9_0.isSkinSkillOn_ then
		return var_0_2.ENERGY_DECIMAL_BASE * 0.5
	else
		return var_0_3.super.energyDecimalBase(arg_9_0)
	end
end

function var_0_3.energyAction(arg_10_0, arg_10_1)
	if var_0_6:father(arg_10_1) == arg_10_0:getEnergySkillID() then
		arg_10_0:getFighterModel():playEnergyEffect_()

		if arg_10_0.isSkinSkillOn_ then
			arg_10_0:updateEnergyBy(-var_0_2.ENERGY_DECIMAL_BASE / 2)
		else
			arg_10_0:updateEnergyTo(arg_10_0:getDMP() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)
		end

		if arg_10_0:getTeamType() == var_0_2.TeamType.A or arg_10_0.isInArena_ or arg_10_0:isMainRole() then
			arg_10_0:addBlackLayer()
		end
	end
end

return var_0_3
