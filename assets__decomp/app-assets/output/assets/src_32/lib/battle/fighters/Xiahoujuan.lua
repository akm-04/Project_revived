local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xiahoujuan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = math.abs
local var_0_10 = math.min
local var_0_11 = 10001160
local var_0_12 = 40011268
local var_0_13 = 0.5
local var_0_14 = 195
local var_0_15 = 40011269
local var_0_16 = 5
local var_0_17 = 10001161
local var_0_18 = 10001159
local var_0_19 = 10001162
local var_0_20 = 300
local var_0_21 = 10001163
local var_0_22 = 80010195
local var_0_23 = 300

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
	arg_2_0.isAddPurpleBuff = false
	arg_2_0.purpleRemoveCount = {}
	arg_2_0.energyTarget = nil
	arg_2_0.blueSkillCount = 0
	arg_2_0.skinSkillCount = 0
	arg_2_0.skinHarmExtra = 1
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

	arg_4_0.blueSkillCount = arg_4_0.blueSkillCount - 1

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0:getInfoByKey("harm_info")) do
			local var_4_0 = iter_4_1.harm
			local var_4_1 = iter_4_1.target

			if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
				local var_4_2 = iter_4_1.fighter

				if not arg_4_0.harmInfo[var_4_2] then
					arg_4_0.harmInfo[var_4_2] = var_4_0
				else
					arg_4_0.harmInfo[var_4_2] = arg_4_0.harmInfo[var_4_2] + var_4_0
				end

				if var_4_2:getSummonType() == var_0_2.summonMonsterType.None and var_4_2:getTeamType() ~= arg_4_0:getTeamType() and arg_4_0.harmInfo[var_4_2] > var_4_2:getHpLimit() * var_0_13 and arg_4_0.blueSkillCount <= 0 and not var_4_2:isDeath() then
					arg_4_0.harmInfo[var_4_2] = 0
					arg_4_0.blueSkillCount = var_0_14

					if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						local var_4_3 = arg_4_0:createAttackUnits({
							var_4_2
						}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

						for iter_4_2, iter_4_3 in ipairs(var_4_3) do
							table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
							table.insert(arg_4_0.records_.special_units, iter_4_3)
						end
					end
				end
			end
		end
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and not arg_4_0.isAddPurpleBuff then
		arg_4_0.isAddPurpleBuff = true

		for iter_4_4, iter_4_5 in ipairs(arg_4_0.selfTeam_) do
			if iter_4_5:getSummonType() == var_0_2.summonMonsterType.None then
				local var_4_4 = var_0_7.new({
					tableID = var_0_15,
					start = var_0_1.ctx.battle.count,
					level = arg_4_0:getSkillLevelByID(arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)),
					skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
					fighter = arg_4_0,
					target = iter_4_5
				})

				iter_4_5:addBuffs({
					var_4_4
				})
			end
		end
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_4_6, iter_4_7 in ipairs(arg_4_0:getInfoByKey("buff_info")) do
			if iter_4_7.target and not iter_4_7.target:isDeath() and iter_4_7.target:isHasBuffByID(var_0_15) and (not arg_4_0.purpleRemoveCount[iter_4_7.target] or arg_4_0.purpleRemoveCount[iter_4_7.target] < var_0_16) and iter_4_7.fighter:getTeamType() ~= iter_4_7.target:getTeamType() and iter_4_7:canRemove() then
				iter_4_7.target:removeBuffs(iter_4_7)

				if not arg_4_0.purpleRemoveCount[iter_4_7.target] then
					arg_4_0.purpleRemoveCount[iter_4_7.target] = 0
				end

				arg_4_0.purpleRemoveCount[iter_4_7.target] = arg_4_0.purpleRemoveCount[iter_4_7.target] + 1

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_4_5 = arg_4_0:createAttackUnits({
						iter_4_7.target
					}, var_0_17)

					for iter_4_8, iter_4_9 in ipairs(var_4_5) do
						table.insert(arg_4_0.moveAttackUnits_, iter_4_9)
						table.insert(arg_4_0.records_.special_units, iter_4_9)
					end
				end

				if arg_4_0.purpleRemoveCount[iter_4_7.target] >= var_0_16 then
					iter_4_7.target:removeBuffByID(var_0_15)
				end
			end
		end
	end

	for iter_4_10, iter_4_11 in ipairs(arg_4_0.bigCottons) do
		if not iter_4_11.fighter:isDeath() then
			iter_4_11.count = iter_4_11.count + 1

			if iter_4_11.count >= var_0_20 and not iter_4_11.isSummon then
				arg_4_0.smallCottonPosX = iter_4_11.fighter:getX()
				arg_4_0.smallCottonPosY = iter_4_11.fighter:getY()

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_4_6 = arg_4_0:createAttackUnits({
						arg_4_0
					}, var_0_19)

					for iter_4_12, iter_4_13 in ipairs(var_4_6) do
						table.insert(arg_4_0.moveAttackUnits_, iter_4_13)
						table.insert(arg_4_0.records_.special_units, iter_4_13)
					end
				end

				iter_4_11.isSummon = true

				iter_4_11.fighter:updateHp(0)

				iter_4_11.fighter.killer_ = arg_4_0

				iter_4_11.fighter:die()
			end
		end
	end

	if arg_4_0.isSkinSkillOn_ and arg_4_0.skinSkillID_ == var_0_22 then
		arg_4_0.skinSkillCount = arg_4_0.skinSkillCount + 1

		if arg_4_0.skinSkillCount >= var_0_23 then
			arg_4_0.skinSkillCount = 0
			arg_4_0.skinHarmExtra = arg_4_0.skinHarmExtra * 1.05

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				arg_4_0:updateNearestTarget()

				local var_4_7 = arg_4_0:createAttackUnits({
					arg_4_0:getNearestTarget()
				}, var_0_22)

				for iter_4_14, iter_4_15 in ipairs(var_4_7) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_15)
					table.insert(arg_4_0.records_.special_units, iter_4_15)
				end
			end
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and arg_5_1.target:isHasBuffByID(var_0_12) and arg_5_1.fighter:getTeamType() ~= arg_5_0:getTeamType() then
		local var_5_0 = arg_5_1.target:getBuffByID(var_0_12)

		if not arg_5_0.greenTargets[var_5_0] then
			arg_5_0.greenTargets[var_5_0] = {}
		end

		table.insert(arg_5_0.greenTargets[var_5_0], arg_5_1.fighter)
	end

	return arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7
end

function var_0_3.dHarmBuffBreakFeedback(arg_6_0, arg_6_1, arg_6_2)
	var_0_3.super.dHarmBuffBreakFeedback(arg_6_0, arg_6_1, arg_6_2)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_6_2:getTableID() == var_0_12 then
		local var_6_0 = {}

		if arg_6_0.greenTargets[arg_6_2] then
			local var_6_1 = {}

			for iter_6_0, iter_6_1 in pairs(arg_6_0.greenTargets[arg_6_2]) do
				if not iter_6_1:isDeath() and not iter_6_1:isAffected() and not var_6_1[iter_6_1] then
					var_6_1[iter_6_1] = iter_6_1

					table.insert(var_6_0, iter_6_1)
				end
			end

			arg_6_0.greenTargets[arg_6_2] = {}
		end

		local var_6_2 = arg_6_0:createAttackUnits(var_6_0, var_0_11)

		for iter_6_2, iter_6_3 in ipairs(var_6_2) do
			iter_6_3.harmRate = arg_6_2.leftCount_ / arg_6_2:getTime()

			table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
			table.insert(arg_6_0.records_.special_units, iter_6_3)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	local var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5 = var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if var_7_2 > 0 and arg_7_1.skillID == var_0_11 and arg_7_1.harmRate then
		var_7_2 = var_7_2 * arg_7_1.harmRate
	end

	return var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5
end

function var_0_3.applySingleUnit(arg_8_0, arg_8_1)
	var_0_3.super.applySingleUnit(arg_8_0, arg_8_1)

	local var_8_0 = arg_8_1.skillID

	if var_8_0 == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and not arg_8_0:isDeath() then
		local var_8_1 = var_0_8:summonMonster(var_8_0)

		if next(var_8_1) == nil then
			return
		end

		for iter_8_0, iter_8_1 in ipairs(var_8_1) do
			local var_8_2 = arg_8_0:getSkillLevelByID(var_8_0)
			local var_8_3 = arg_8_0.hero_:getColor()
			local var_8_4 = arg_8_1.target:getX()

			if arg_8_1.target:avoidHeroMoveBehind() then
				var_8_4 = var_8_4 - arg_8_1.target:getFighterModel():getWidth()
			end

			local var_8_5 = var_0_1.ctx.battle.adjustX(var_8_4, arg_8_0)
			local var_8_6 = {
				x = var_8_5,
				y = arg_8_1.target:getY() + 30
			}

			arg_8_0:setSummonMonsters(iter_8_1, var_8_2, var_8_3, var_8_6)
		end
	elseif var_8_0 == 10001250 and not arg_8_0:isDeath() then
		arg_8_0.energyTarget = arg_8_1.target

		local var_8_7 = var_0_8:summonMonster(10001250)

		if next(var_8_7) == nil then
			return
		end

		for iter_8_2, iter_8_3 in ipairs(var_8_7) do
			local var_8_8 = arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
			local var_8_9 = arg_8_0.hero_:getColor()
			local var_8_10 = arg_8_1.target:getX() + (arg_8_1.target:getFlipX() and -1 or 1) * 20
			local var_8_11 = var_0_1.ctx.battle.adjustX(var_8_10, arg_8_0)

			if arg_8_1.target:avoidHeroMoveBehind() then
				var_8_11 = var_8_11 - arg_8_1.target:getFighterModel():getWidth()
			end

			local var_8_12 = {
				x = var_8_11,
				y = arg_8_1.target:getY() + 30
			}

			arg_8_0:setBigSummonMonsters(iter_8_3, var_8_8, var_8_9, var_8_12)
		end
	elseif var_8_0 == var_0_18 then
		arg_8_0:setImmuneControl(false)
	elseif var_8_0 == var_0_19 and arg_8_0.smallCottonPosX and not arg_8_0:isDeath() then
		local var_8_13 = var_0_8:summonMonster(var_0_19)

		if next(var_8_13) == nil then
			return
		end

		for iter_8_4, iter_8_5 in ipairs(var_8_13) do
			local var_8_14 = arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
			local var_8_15 = arg_8_0.hero_:getColor()
			local var_8_16 = arg_8_0.smallCottonPosX + (iter_8_4 - 2.5) * 200
			local var_8_17 = var_0_1.ctx.battle.adjustX(var_8_16, arg_8_0)
			local var_8_18 = {
				x = var_8_17,
				y = arg_8_0.smallCottonPosY
			}

			arg_8_0:setSummonMonsters(iter_8_5, var_8_14, var_8_15, var_8_18)
		end

		arg_8_0.smallCottonPosX = nil
		arg_8_0.smallCottonPosY = nil
	elseif var_8_0 == var_0_21 and arg_8_0.smallCottonPosX and not arg_8_0:isDeath() then
		local var_8_19 = var_0_8:summonMonster(var_0_21)

		if next(var_8_19) == nil then
			return
		end

		for iter_8_6, iter_8_7 in ipairs(var_8_19) do
			local var_8_20 = arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
			local var_8_21 = arg_8_0.hero_:getColor()
			local var_8_22 = arg_8_0.smallCottonPosX + (iter_8_6 - 1.5) * 100
			local var_8_23 = var_0_1.ctx.battle.adjustX(var_8_22, arg_8_0)
			local var_8_24 = {
				x = var_8_23,
				y = arg_8_0.smallCottonPosY
			}

			arg_8_0:setSummonMonsters(iter_8_7, var_8_20, var_8_21, var_8_24)
		end

		arg_8_0.smallCottonPosX = nil
		arg_8_0.smallCottonPosY = nil
	elseif var_8_0 == var_0_22 and not arg_8_0:isDeath() then
		local var_8_25 = var_0_8:summonMonster(var_0_22)

		if next(var_8_25) == nil then
			return
		end

		for iter_8_8, iter_8_9 in ipairs(var_8_25) do
			local var_8_26 = arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
			local var_8_27 = arg_8_0.hero_:getColor()
			local var_8_28 = arg_8_1.target:getX()
			local var_8_29 = var_0_1.ctx.battle.adjustX(var_8_28, arg_8_0)
			local var_8_30 = {
				x = var_8_29,
				y = arg_8_1.target:getY() + 30
			}

			arg_8_0:setSummonMonsters(iter_8_9, var_8_26, var_8_27, var_8_30)
		end
	elseif var_8_0 == arg_8_0:getPugongID() then
		-- block empty
	end
end

function var_0_3.beginAttackEnd(arg_9_0, arg_9_1)
	var_0_3.super.beginAttackEnd(arg_9_0, arg_9_1)

	if arg_9_1.rootID_ == var_0_18 then
		arg_9_0:setImmuneControl(true)
	end
end

function var_0_3.deathFeedback(arg_10_0, arg_10_1)
	var_0_3.super.deathFeedback(arg_10_0, arg_10_1)

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.bigCottons) do
		if arg_10_1 == iter_10_1.fighter and iter_10_1.count < var_0_20 and arg_10_1.killer_ and arg_10_1.killer_:getTeamType() ~= arg_10_0:getTeamType() then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_10_0 = arg_10_0:createAttackUnits({
					arg_10_0
				}, var_0_21)

				for iter_10_2, iter_10_3 in ipairs(var_10_0) do
					table.insert(arg_10_0.moveAttackUnits_, iter_10_3)
					table.insert(arg_10_0.records_.special_units, iter_10_3)
				end
			end

			arg_10_0.smallCottonPosX = iter_10_1.fighter:getX()
			arg_10_0.smallCottonPosY = iter_10_1.fighter:getY()
		end
	end
end

function var_0_3.setSummonMonsters(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4)
	local var_11_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_11_0 = arg_11_0:getSummonMonster()
	else
		local var_11_1 = var_0_6.new()

		var_11_1:populateWithTableID(arg_11_1)

		var_11_1.level_ = arg_11_2 or var_11_1.level_
		var_11_1.color_ = arg_11_3 or var_11_1.color_

		for iter_11_0, iter_11_1 in ipairs(var_11_1.skillLev_) do
			local var_11_2 = var_11_1:getSkillId(iter_11_0)
			local var_11_3 = arg_11_0.hero_:getSkillLevelByID(var_11_2)

			if var_11_3 and var_11_3 > 0 then
				var_11_1.skillLev_[iter_11_0] = var_11_3
			end
		end

		local var_11_4 = var_11_1:className()

		var_11_0 = var_0_1.ctx.battle.requireFighter(var_11_4).new({
			is_arena = arg_11_0.isInArena_
		})

		var_11_0:populateWithHero(var_11_1)
		var_11_0:initModels()
		var_11_0.fighterModel:initHeaderView(arg_11_0:getTeamType() - 1)

		var_11_0.fighterIndex = arg_11_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_11_0:setFormationDelay(0, 100)
	end

	var_11_0:setTeamType(arg_11_0:getTeamType())

	var_11_0.summoner = arg_11_0

	var_11_0.fighterModel:pos(arg_11_4.x, arg_11_4.y)
	var_11_0:getFighterModel():flipX(arg_11_0:getTeamType() == var_0_2.TeamType.B)
	var_11_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_11_0:born()
	var_11_0:setGlobalBuffs()
	var_11_0:updateHp(var_11_0:getHpLimit())

	if arg_11_0.isSkinSkillOn_ and arg_11_0.skinSkillID_ == var_0_22 then
		var_11_0.harmExtra_ = arg_11_0.skinHarmExtra
	end

	if var_11_0:getTeamType() == var_0_2.TeamType.A then
		table.insert(var_0_1.ctx.battle.teamA, var_11_0)
	else
		table.insert(var_0_1.ctx.battle.teamB, var_11_0)
	end

	table.insert(var_0_1.ctx.battle.yOrder, var_11_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_11_0.summonMonsters_, var_11_0)
end

function var_0_3.setBigSummonMonsters(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4)
	local var_12_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_12_0 = arg_12_0:getSummonMonster()
	else
		local var_12_1 = var_0_6.new()

		var_12_1:populateWithTableID(arg_12_1)

		var_12_1.level_ = arg_12_2 or var_12_1.level_
		var_12_1.color_ = arg_12_3 or var_12_1.color_

		for iter_12_0, iter_12_1 in ipairs(var_12_1.skillLev_) do
			local var_12_2 = var_12_1:getSkillId(iter_12_0)
			local var_12_3 = arg_12_0.hero_:getSkillLevelByID(var_12_2)

			if var_12_3 and var_12_3 > 0 then
				var_12_1.skillLev_[iter_12_0] = var_12_3
			end
		end

		local var_12_4 = var_12_1:className()

		var_12_0 = var_0_1.ctx.battle.requireFighter(var_12_4).new({
			is_arena = arg_12_0.isInArena_
		})

		var_12_0:populateWithHero(var_12_1)
		var_12_0:initModels()
		var_12_0.fighterModel:initHeaderView(arg_12_0:getTeamType() - 1)

		var_12_0.fighterIndex = arg_12_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_12_0:setFormationDelay(0, 100)
	end

	var_12_0:setTeamType(arg_12_0:getTeamType())

	var_12_0.summoner = arg_12_0

	var_12_0.fighterModel:pos(arg_12_4.x, arg_12_4.y)
	var_12_0:getFighterModel():flipX(arg_12_0:getTeamType() == var_0_2.TeamType.B)
	var_12_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_12_0:born()
	var_12_0:setGlobalBuffs()
	var_12_0:updateHp(var_12_0:getHpLimit())

	if var_12_0:getTeamType() == var_0_2.TeamType.A then
		table.insert(var_0_1.ctx.battle.teamA, var_12_0)
	else
		table.insert(var_0_1.ctx.battle.teamB, var_12_0)
	end

	table.insert(var_0_1.ctx.battle.yOrder, var_12_0)
	var_0_1.ctx.battle.updateZorder()

	local var_12_5 = {
		isSummon = false,
		count = 0,
		fighter = var_12_0
	}

	table.insert(arg_12_0.bigCottons, var_12_5)
end

function var_0_3.selectTargetByTypeD1(arg_13_0)
	local var_13_0 = {}

	table.insert(var_13_0, arg_13_0)

	local var_13_1

	for iter_13_0, iter_13_1 in pairs(arg_13_0.selfTeam_) do
		if not iter_13_1:isDeath() and not iter_13_1:isAffected() and iter_13_1 ~= arg_13_0 and iter_13_1:getSummonType() == var_0_2.summonMonsterType.None then
			if arg_13_0:getTeamType() == var_0_2.TeamType.A then
				if not var_13_1 or iter_13_1:getX() > var_13_1:getX() then
					var_13_1 = iter_13_1
				end
			elseif not var_13_1 or iter_13_1:getX() < var_13_1:getX() then
				var_13_1 = iter_13_1
			end
		end
	end

	if var_13_1 then
		table.insert(var_13_0, var_13_1)
	end

	return var_13_0
end

function var_0_3.selectTargetByTypeD2(arg_14_0)
	local function var_14_0(arg_15_0, arg_15_1)
		local var_15_0 = {}

		table.insert(var_15_0, arg_15_0)

		for iter_15_0, iter_15_1 in ipairs(arg_14_0.sideTeam_) do
			if not iter_15_1:isDeath() and not iter_15_1:isAffected() and iter_15_1 ~= arg_15_0 and arg_15_1 >= math.abs(iter_15_1:getX() - arg_15_0:getX()) then
				table.insert(var_15_0, iter_15_1)
			end
		end

		return var_15_0
	end

	local var_14_1
	local var_14_2 = 0
	local var_14_3 = var_0_8:scope(arg_14_0:getEnergySkillID()) * 0.5

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.sideTeam_) do
		if not iter_14_1:isDeath() and not iter_14_1:isAffected() then
			local var_14_4 = var_14_0(iter_14_1, var_14_3)

			if not var_14_1 or var_14_2 < #var_14_4 then
				var_14_1 = iter_14_1
				var_14_2 = #var_14_4
			end
		end
	end

	return {
		var_14_1
	}
end

function var_0_3.selectTargetByTypeD3(arg_16_0)
	local var_16_0 = {}

	if arg_16_0.energyTarget then
		for iter_16_0, iter_16_1 in ipairs(arg_16_0.sideTeam_) do
			if not iter_16_1:isDeath() and not iter_16_1:isAffected() and math.abs(iter_16_1:getX() - arg_16_0.energyTarget:getX()) <= var_0_8:scope(var_0_18) / 2 then
				table.insert(var_16_0, iter_16_1)
			end
		end
	end

	return var_16_0
end

return var_0_3
