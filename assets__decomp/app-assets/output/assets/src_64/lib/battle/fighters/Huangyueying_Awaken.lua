local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Huangyueying", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.hero
local var_0_9 = var_0_2.tables.model
local var_0_10 = 10010052
local var_0_11 = 10010051
local var_0_12 = 10001896
local var_0_13 = 10001917
local var_0_14 = 10001901
local var_0_15 = 10001902
local var_0_16 = 10001907
local var_0_17 = 10001908

function var_0_3.populateWithHero(arg_1_0, arg_1_1)
	var_0_3.super.populateWithHero(arg_1_0, arg_1_1)

	if arg_1_0.skinSkillIndex_ == 1 then
		arg_1_0.SummonSkill = var_0_16
		arg_1_0.SummonSkill2 = var_0_17
	else
		arg_1_0.SummonSkill = var_0_14
		arg_1_0.SummonSkill2 = var_0_15
	end
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.summonMonsters_ = {}
	arg_2_0.energyMonster_ = nil
	arg_2_0.awakenMonster_ = nil
end

function var_0_3.die(arg_3_0)
	for iter_3_0, iter_3_1 in ipairs(arg_3_0.summonMonsters_) do
		if iter_3_1:isDeath() ~= true then
			iter_3_1:updateHp(0)
			iter_3_1:die()
		end
	end

	var_0_3.super.die(arg_3_0)
end

function var_0_3.selectTargetByTypeD1(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_2 and arg_4_2.manualTargets_ then
		return arg_4_2.manualTargets_
	end

	local var_4_0 = var_0_5.B3(arg_4_0, arg_4_1)

	if not var_4_0 then
		return {}
	end

	local var_4_1 = {
		var_4_0
	}
	local var_4_2, var_4_3 = var_0_5.getTeam(arg_4_0)

	for iter_4_0, iter_4_1 in ipairs(var_4_3) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and iter_4_1 ~= var_4_0 and math.abs(iter_4_1:getX() - var_4_0:getX()) < var_0_7:scope(arg_4_1) / 2 then
			table.insert(var_4_1, iter_4_1)
		end
	end

	return var_4_1
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)

	if arg_5_1.rootID_ == var_0_13 then
		if arg_5_0.energyMonster_ and not arg_5_0.energyMonster_:isDeath() then
			arg_5_0.energyMonster_:createSkillByID(var_0_12, arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy), 3)
		end

		if arg_5_0.awakenMonster_ and not arg_5_0.awakenMonster_:isDeath() then
			arg_5_0.awakenMonster_:createSkillByID(var_0_12, arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy), 3)
		end
	end

	if arg_5_1.rootID_ ~= arg_5_0.SummonSkill or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_5_0 = arg_5_0.SummonSkill2

	arg_5_0.specialSkills_ = var_0_4.new({
		fighter = arg_5_0,
		skillID = var_5_0
	})

	arg_5_0:beginAttackEnd(arg_5_0.specialSkills_)
end

function var_0_3.moveUnitArrive(arg_6_0, arg_6_1)
	var_0_3.super.moveUnitArrive(arg_6_0, arg_6_1)

	local var_6_0 = arg_6_1.skillID
	local var_6_1 = var_0_7:summonMonster(var_6_0)

	if next(var_6_1) == nil then
		return
	end

	if var_6_0 == arg_6_0.SummonSkill and arg_6_0.energyMonster_ and not arg_6_0.energyMonster_:isDeath() then
		arg_6_0.energyMonster_:updateHp(0)
		arg_6_0.energyMonster_:die()

		if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) <= 0 then
			var_0_0.table.removebyvalue(arg_6_0.summonMonsters_, arg_6_0.energyMonster_)
		end
	elseif var_6_0 == arg_6_0.SummonSkill2 and arg_6_0.awakenMonster_ and not arg_6_0.awakenMonster_:isDeath() then
		arg_6_0.awakenMonster_:updateHp(0)
		arg_6_0.awakenMonster_:die()

		if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) <= 0 then
			var_0_0.table.removebyvalue(arg_6_0.summonMonsters_, arg_6_0.awakenMonster_)
		end
	end

	for iter_6_0, iter_6_1 in ipairs(var_6_1) do
		local var_6_2 = arg_6_0:getSkillLevelByID(var_6_0)
		local var_6_3 = arg_6_0.hero_:getColor()
		local var_6_4 = {
			x = var_0_1.ctx.battle.adjustX(arg_6_1.desX_, arg_6_0),
			y = arg_6_1.desY_
		}
		local var_6_5 = arg_6_0:setSummonMonsters(iter_6_1, var_6_2, var_6_3, var_6_4)

		if var_6_0 == arg_6_0.SummonSkill then
			arg_6_0.energyMonster_ = var_6_5
		else
			arg_6_0.awakenMonster_ = var_6_5
		end
	end
end

function var_0_3.setSummonMonsters(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4)
	local var_7_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_7_0 = arg_7_0:getSummonMonster()
	else
		local var_7_1 = var_0_6.new()

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

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_8_1:getTableID() == var_0_10 then
		arg_8_1:setExtraTime(30)
	end
end

function var_0_3.ctor(arg_9_0, arg_9_1)
	var_0_3.super.ctor(arg_9_0, arg_9_1)
	arg_9_0:listenInfo("death_info")
	arg_9_0:listenInfo("buff_info")
end

function var_0_3.toDoPerFrames(arg_10_0)
	if arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and next(arg_10_0.summonMonsters_) then
		for iter_10_0, iter_10_1 in ipairs(arg_10_0:getInfoByKey("buff_info")) do
			local var_10_0 = iter_10_1.fighter

			if iter_10_1:getTableID() == var_0_11 and var_10_0 and var_10_0.summoner == arg_10_0 then
				iter_10_1:setExtraTime(30)
			end
		end

		for iter_10_2, iter_10_3 in ipairs(arg_10_0:getInfoByKey("death_info")) do
			for iter_10_4, iter_10_5 in ipairs(arg_10_0.summonMonsters_) do
				if iter_10_5 == iter_10_3 then
					if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						local var_10_1 = {}
						local var_10_2 = arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)
						local var_10_3 = var_0_7:scope(var_10_2)

						for iter_10_6, iter_10_7 in ipairs(arg_10_0.sideTeam_) do
							if not iter_10_7:isDeath() and not iter_10_7:isAffected() and math.abs(iter_10_7:getX() - iter_10_3:getX()) <= var_10_3 * 0.5 then
								table.insert(var_10_1, iter_10_7)
							end
						end

						local var_10_4 = arg_10_0:createAttackUnits(var_10_1, var_10_2)

						for iter_10_8, iter_10_9 in ipairs(var_10_4) do
							table.insert(arg_10_0.moveAttackUnits_, iter_10_9)
							table.insert(arg_10_0.records_.special_units, iter_10_9)
						end
					end

					table.remove(arg_10_0.summonMonsters_, iter_10_4)

					break
				end
			end
		end
	end
end

function var_0_3.getOrbOfFrontSkill(arg_11_0)
	local var_11_0 = var_0_3.super.getOrbOfFrontSkill(arg_11_0)

	if var_11_0 == arg_11_0:getEnergySkillID() then
		if arg_11_0.isSkinSkillOn_ then
			if arg_11_0.energyMonster_ and not arg_11_0.energyMonster_:isDeath() or arg_11_0.awakenMonster_ and not arg_11_0.awakenMonster_:isDeath() then
				var_11_0 = var_0_13
			else
				var_11_0 = arg_11_0.SummonSkill
			end
		else
			var_11_0 = arg_11_0.SummonSkill
		end
	end

	return var_11_0
end

function var_0_3.energyDecimalBase(arg_12_0)
	if arg_12_0.isSkinSkillOn_ then
		return var_0_2.ENERGY_DECIMAL_BASE * 0.5
	else
		return var_0_3.super.energyDecimalBase(arg_12_0)
	end
end

function var_0_3.energyAction(arg_13_0, arg_13_1)
	if var_0_7:father(arg_13_1) == arg_13_0:getEnergySkillID() then
		arg_13_0:getFighterModel():playEnergyEffect_()

		if arg_13_0.isSkinSkillOn_ then
			arg_13_0:updateEnergyBy(-var_0_2.ENERGY_DECIMAL_BASE / 2)
		else
			arg_13_0:updateEnergyTo(arg_13_0:getDMP() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)
		end

		if arg_13_0:getTeamType() == var_0_2.TeamType.A or arg_13_0.isInArena_ or arg_13_0:isMainRole() then
			arg_13_0:addBlackLayer()
		end
	end
end

return var_0_3
