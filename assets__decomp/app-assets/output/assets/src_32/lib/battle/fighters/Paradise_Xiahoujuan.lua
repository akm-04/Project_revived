local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xiahoujuan", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = 800313007
local var_0_10 = 40012254
local var_0_11 = 800313006
local var_0_12 = 90
local var_0_13 = 0.2
local var_0_14 = 800313011
local var_0_15 = 800313009
local var_0_16 = 300
local var_0_17 = 800313010

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.greenTargets = {}
	arg_2_0.harmInfo = {}
	arg_2_0.summonMonsters_ = {}
	arg_2_0.bigCottons = {}
	arg_2_0.smallCottonPosX = nil
	arg_2_0.smallCottonPosY = nil
	arg_2_0.energyTarget = nil
	arg_2_0.blueSkillCount = 0
	arg_2_0.purpleSkillCount = {}
end

function var_0_3.die(arg_3_0)
	for iter_3_0, iter_3_1 in ipairs(arg_3_0.summonMonsters_) do
		if not iter_3_1:isDeath() then
			iter_3_1:die()
		end
	end

	for iter_3_2, iter_3_3 in ipairs(arg_3_0.bigCottons) do
		if not iter_3_3.fighter:isDeath() then
			iter_3_3.fighter.killer_ = arg_3_0

			iter_3_3.fighter:die()
		end
	end

	return var_0_3.super.die(arg_3_0)
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.bigCottons) do
		if not iter_4_1.fighter:isDeath() then
			iter_4_1.count = iter_4_1.count + 1

			if iter_4_1.count >= var_0_16 and not iter_4_1.isSummon then
				arg_4_0.smallCottonPosX = iter_4_1.fighter:getX()
				arg_4_0.smallCottonPosY = iter_4_1.fighter:getY()

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_4_0 = arg_4_0:createAttackUnits({
						arg_4_0
					}, var_0_15)

					for iter_4_2, iter_4_3 in ipairs(var_4_0) do
						table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
						table.insert(arg_4_0.records_.special_units, iter_4_3)
					end
				end

				iter_4_1.isSummon = true

				iter_4_1.fighter:updateHp(0)

				iter_4_1.fighter.killer_ = arg_4_0

				iter_4_1.fighter:die()
			end
		end
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_4_4, iter_4_5 in pairs(arg_4_0.purpleSkillCount) do
			if iter_4_5.count > 0 then
				iter_4_5.count = iter_4_5.count - 1

				if iter_4_5.count == 0 then
					arg_4_0.purpleSkillCount[iter_4_4] = nil
				end
			end
		end
	end
end

function var_0_3.dHarmBuffBreakFeedback(arg_5_0, arg_5_1, arg_5_2)
	var_0_3.super.dHarmBuffBreakFeedback(arg_5_0, arg_5_1, arg_5_2)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_5_2:getTableID() == var_0_10 then
		local var_5_0 = {}
		local var_5_1 = 0

		for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
			if not iter_5_1:isDeath() and not iter_5_1:isAffected() then
				table.insert(var_5_0, iter_5_1)

				var_5_1 = var_5_1 + 1

				if var_5_1 == 2 then
					break
				end
			end
		end

		local var_5_2 = arg_5_0:createAttackUnits(var_5_0, var_0_9)

		for iter_5_2, iter_5_3 in ipairs(var_5_2) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
			table.insert(arg_5_0.records_.special_units, iter_5_3)
		end
	end
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	local var_6_0 = arg_6_1.skillID

	if var_6_0 == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and not arg_6_0:isDeath() then
		local var_6_1 = var_0_8:summonMonster(var_6_0)

		if next(var_6_1) == nil then
			return
		end

		for iter_6_0, iter_6_1 in ipairs(var_6_1) do
			local var_6_2 = arg_6_0:getSkillLevelByID(var_6_0)
			local var_6_3 = arg_6_0.hero_:getColor()
			local var_6_4 = arg_6_1.target:getX()

			if arg_6_1.target:avoidHeroMoveBehind() then
				var_6_4 = var_6_4 - arg_6_1.target:getFighterModel():getWidth()
			end

			local var_6_5 = var_0_1.ctx.battle.adjustX(var_6_4, arg_6_0)
			local var_6_6 = {
				x = var_6_5,
				y = arg_6_1.target:getY() + 30
			}

			arg_6_0:setSummonMonsters(iter_6_1, var_6_2, var_6_3, var_6_6)
		end
	elseif var_6_0 == var_0_14 and not arg_6_0:isDeath() then
		arg_6_0.energyTarget = arg_6_1.target

		local var_6_7 = var_0_8:summonMonster(var_0_14)

		if next(var_6_7) == nil then
			return
		end

		for iter_6_2, iter_6_3 in ipairs(var_6_7) do
			local var_6_8 = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
			local var_6_9 = arg_6_0.hero_:getColor()
			local var_6_10 = arg_6_1.target:getX() + (arg_6_1.target:getFlipX() and -1 or 1) * 20
			local var_6_11 = var_0_1.ctx.battle.adjustX(var_6_10, arg_6_0)

			if arg_6_1.target:avoidHeroMoveBehind() then
				var_6_11 = var_6_11 - arg_6_1.target:getFighterModel():getWidth()
			end

			local var_6_12 = {
				x = var_6_11,
				y = arg_6_1.target:getY() + 30
			}

			arg_6_0:setBigSummonMonsters(iter_6_3, var_6_8, var_6_9, var_6_12)
		end
	elseif var_6_0 == var_0_11 then
		arg_6_0:setImmuneControl(false)
	elseif var_6_0 == var_0_15 and arg_6_0.smallCottonPosX and not arg_6_0:isDeath() then
		local var_6_13 = var_0_8:summonMonster(var_0_15)

		if next(var_6_13) == nil then
			return
		end

		for iter_6_4, iter_6_5 in ipairs(var_6_13) do
			local var_6_14 = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
			local var_6_15 = arg_6_0.hero_:getColor()
			local var_6_16 = arg_6_0.smallCottonPosX + (iter_6_4 - 2.5) * 200
			local var_6_17 = var_0_1.ctx.battle.adjustX(var_6_16, arg_6_0)
			local var_6_18 = {
				x = var_6_17,
				y = arg_6_0.smallCottonPosY
			}

			arg_6_0:setSummonMonsters(iter_6_5, var_6_14, var_6_15, var_6_18)
		end

		arg_6_0.smallCottonPosX = nil
		arg_6_0.smallCottonPosY = nil
	elseif var_6_0 == var_0_17 and arg_6_0.smallCottonPosX and not arg_6_0:isDeath() then
		local var_6_19 = var_0_8:summonMonster(var_0_17)

		if next(var_6_19) == nil then
			return
		end

		for iter_6_6, iter_6_7 in ipairs(var_6_19) do
			local var_6_20 = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
			local var_6_21 = arg_6_0.hero_:getColor()
			local var_6_22 = arg_6_0.smallCottonPosX + (iter_6_6 - 1.5) * 100
			local var_6_23 = var_0_1.ctx.battle.adjustX(var_6_22, arg_6_0)
			local var_6_24 = {
				x = var_6_23,
				y = arg_6_0.smallCottonPosY
			}

			arg_6_0:setSummonMonsters(iter_6_7, var_6_20, var_6_21, var_6_24)
		end

		arg_6_0.smallCottonPosX = nil
		arg_6_0.smallCottonPosY = nil
	elseif var_6_0 == arg_6_0:getPugongID() then
		-- block empty
	end
end

function var_0_3.beginAttackEnd(arg_7_0, arg_7_1)
	var_0_3.super.beginAttackEnd(arg_7_0, arg_7_1)

	if arg_7_1.rootID_ == var_0_11 then
		arg_7_0:setImmuneControl(true)
	end
end

function var_0_3.deathFeedback(arg_8_0, arg_8_1)
	var_0_3.super.deathFeedback(arg_8_0, arg_8_1)

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.bigCottons) do
		if arg_8_1 == iter_8_1.fighter and iter_8_1.count < var_0_16 and arg_8_1.killer_ and arg_8_1.killer_:getTeamType() ~= arg_8_0:getTeamType() then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_8_0 = arg_8_0:createAttackUnits({
					arg_8_0
				}, var_0_17)

				for iter_8_2, iter_8_3 in ipairs(var_8_0) do
					table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
					table.insert(arg_8_0.records_.special_units, iter_8_3)
				end
			end

			arg_8_0.smallCottonPosX = iter_8_1.fighter:getX()
			arg_8_0.smallCottonPosY = iter_8_1.fighter:getY()
		end
	end
end

function var_0_3.setSummonMonsters(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4)
	local var_9_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_9_0 = arg_9_0:getSummonMonster()
	else
		local var_9_1 = var_0_6.new()

		var_9_1:populateWithTableID(arg_9_1)

		var_9_1.level_ = arg_9_2 or var_9_1.level_
		var_9_1.color_ = arg_9_3 or var_9_1.color_

		for iter_9_0, iter_9_1 in ipairs(var_9_1.skillLev_) do
			local var_9_2 = var_9_1:getSkillId(iter_9_0)
			local var_9_3 = arg_9_0.hero_:getSkillLevelByID(var_9_2)

			if var_9_3 and var_9_3 > 0 then
				var_9_1.skillLev_[iter_9_0] = var_9_3
			end
		end

		local var_9_4 = var_9_1:className()

		var_9_0 = var_0_1.ctx.battle.requireFighter(var_9_4).new({
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

	if var_9_0:getTeamType() == var_0_2.TeamType.A then
		table.insert(var_0_1.ctx.battle.teamA, var_9_0)
	else
		table.insert(var_0_1.ctx.battle.teamB, var_9_0)
	end

	table.insert(var_0_1.ctx.battle.yOrder, var_9_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_9_0.summonMonsters_, var_9_0)
end

function var_0_3.setBigSummonMonsters(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4)
	local var_10_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_10_0 = arg_10_0:getSummonMonster()
	else
		local var_10_1 = var_0_6.new()

		var_10_1:populateWithTableID(arg_10_1)

		var_10_1.level_ = arg_10_2 or var_10_1.level_
		var_10_1.color_ = arg_10_3 or var_10_1.color_

		for iter_10_0, iter_10_1 in ipairs(var_10_1.skillLev_) do
			local var_10_2 = var_10_1:getSkillId(iter_10_0)
			local var_10_3 = arg_10_0.hero_:getSkillLevelByID(var_10_2)

			if var_10_3 and var_10_3 > 0 then
				var_10_1.skillLev_[iter_10_0] = var_10_3
			end
		end

		local var_10_4 = var_10_1:className()

		var_10_0 = var_0_1.ctx.battle.requireFighter(var_10_4).new({
			is_arena = arg_10_0.isInArena_
		})

		var_10_0:populateWithHero(var_10_1)
		var_10_0:initModels()
		var_10_0.fighterModel:initHeaderView(arg_10_0:getTeamType() - 1)

		var_10_0.fighterIndex = arg_10_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_10_0:setFormationDelay(0, 100)
	end

	var_10_0:setTeamType(arg_10_0:getTeamType())

	var_10_0.summoner = arg_10_0

	var_10_0.fighterModel:pos(arg_10_4.x, arg_10_4.y)
	var_10_0:getFighterModel():flipX(arg_10_0:getTeamType() == var_0_2.TeamType.B)
	var_10_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_10_0:born()
	var_10_0:setGlobalBuffs()
	var_10_0:updateHp(var_10_0:getHpLimit())

	if var_10_0:getTeamType() == var_0_2.TeamType.A then
		table.insert(var_0_1.ctx.battle.teamA, var_10_0)
	else
		table.insert(var_0_1.ctx.battle.teamB, var_10_0)
	end

	table.insert(var_0_1.ctx.battle.yOrder, var_10_0)
	var_0_1.ctx.battle.updateZorder()

	local var_10_5 = {
		isSummon = false,
		count = 0,
		fighter = var_10_0
	}

	table.insert(arg_10_0.bigCottons, var_10_5)
end

function var_0_3.selectTargetByTypeD1(arg_11_0)
	local var_11_0 = {}

	table.insert(var_11_0, arg_11_0)

	local var_11_1

	for iter_11_0, iter_11_1 in pairs(arg_11_0.selfTeam_) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() and iter_11_1 ~= arg_11_0 and iter_11_1:getSummonType() == var_0_2.summonMonsterType.None then
			if arg_11_0:getTeamType() == var_0_2.TeamType.A then
				if not var_11_1 or iter_11_1:getX() > var_11_1:getX() then
					var_11_1 = iter_11_1
				end
			elseif not var_11_1 or iter_11_1:getX() < var_11_1:getX() then
				var_11_1 = iter_11_1
			end
		end
	end

	if var_11_1 then
		table.insert(var_11_0, var_11_1)
	end

	return var_11_0
end

function var_0_3.selectTargetByTypeD2(arg_12_0)
	local function var_12_0(arg_13_0, arg_13_1)
		local var_13_0 = {}

		table.insert(var_13_0, arg_13_0)

		for iter_13_0, iter_13_1 in ipairs(arg_12_0.sideTeam_) do
			if not iter_13_1:isDeath() and not iter_13_1:isAffected() and iter_13_1 ~= arg_13_0 and arg_13_1 >= math.abs(iter_13_1:getX() - arg_13_0:getX()) then
				table.insert(var_13_0, iter_13_1)
			end
		end

		return var_13_0
	end

	local var_12_1
	local var_12_2 = 0
	local var_12_3 = var_0_8:scope(arg_12_0:getEnergySkillID()) * 0.5

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.sideTeam_) do
		if not iter_12_1:isDeath() and not iter_12_1:isAffected() then
			local var_12_4 = var_12_0(iter_12_1, var_12_3)

			if not var_12_1 or var_12_2 < #var_12_4 then
				var_12_1 = iter_12_1
				var_12_2 = #var_12_4
			end
		end
	end

	return {
		var_12_1
	}
end

function var_0_3.selectTargetByTypeD3(arg_14_0)
	local var_14_0 = {}

	if arg_14_0.energyTarget then
		for iter_14_0, iter_14_1 in ipairs(arg_14_0.sideTeam_) do
			if not iter_14_1:isDeath() and not iter_14_1:isAffected() and math.abs(iter_14_1:getX() - arg_14_0.energyTarget:getX()) <= var_0_8:scope(var_0_11) / 2 then
				table.insert(var_14_0, iter_14_1)
			end
		end
	end

	return var_14_0
end

function var_0_3.updateUnitDataByTarget(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4, arg_15_5, arg_15_6, arg_15_7)
	arg_15_2, arg_15_3, arg_15_4, arg_15_5, arg_15_6, arg_15_7 = var_0_3.super.updateUnitDataByTarget(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4, arg_15_5, arg_15_6, arg_15_7)

	local var_15_0 = arg_15_1.fighter

	if arg_15_4 > 0 and arg_15_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_15_1 = var_0_8:father(arg_15_1.skillID)

		if not arg_15_0.purpleSkillCount[var_15_0] or arg_15_0.purpleSkillCount[var_15_0].skillID ~= var_15_1 then
			arg_15_0.purpleSkillCount[var_15_0] = {
				num = 1,
				skillID = var_15_1,
				count = var_0_12
			}
		else
			local var_15_2 = arg_15_0.purpleSkillCount[var_15_0].num

			arg_15_4 = math.max(arg_15_4 * (1 - var_15_2 * var_0_13), 0)
			arg_15_0.purpleSkillCount[var_15_0] = {
				skillID = var_15_1,
				count = var_0_12,
				num = var_15_2 + 1
			}
		end
	end

	return arg_15_2, arg_15_3, arg_15_4, arg_15_5, arg_15_6, arg_15_7
end

return var_0_3
