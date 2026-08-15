local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Wangyuanji", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 10000679
local var_0_8 = 0.3
local var_0_9 = 40010696
local var_0_10 = 10000683
local var_0_11 = 40010723
local var_0_12 = 40010722
local var_0_13 = 10000684
local var_0_14 = 40010724
local var_0_15 = 40010725
local var_0_16 = 10
local var_0_17 = 40011302
local var_0_18 = 10001206
local var_0_19 = 10001211
local var_0_20 = 10001207
local var_0_21 = 10001208
local var_0_22 = 40011299
local var_0_23 = 10001212
local var_0_24 = 80010151
local var_0_25 = 40011301
local var_0_26 = 10001209
local var_0_27 = 10001204
local var_0_28 = 10001213
local var_0_29 = 1000

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.energyTotalHarm_ = 0
	arg_2_0.greenTotalHarm_ = {}
	arg_2_0.blueSummonMonsters_ = {}
	arg_2_0.isPurpleSkill_ = false
	arg_2_0.skinEnergyTotalHarm_ = {}
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0.blueSummonMonsters_ and next(arg_3_0.blueSummonMonsters_) then
		for iter_3_0 = #arg_3_0.blueSummonMonsters_, 1, -1 do
			local var_3_0 = arg_3_0.blueSummonMonsters_[iter_3_0] or {}

			if var_3_0 and next(var_3_0) then
				local var_3_1 = var_3_0.monster
				local var_3_2 = var_3_0.forceTarget

				if var_3_1:isDeath() and not var_3_2:isDeath() then
					var_3_2:removeBuffByID(var_0_11)
					table.remove(arg_3_0.blueSummonMonsters_, iter_3_0)
				elseif var_3_2:isDeath() and not var_3_1:isDeath() then
					var_3_1:updateHp(0)
					var_3_1:die()
					table.remove(arg_3_0.blueSummonMonsters_, iter_3_0)
				elseif var_3_2:isDeath() and var_3_1:isDeath() then
					table.remove(arg_3_0.blueSummonMonsters_, iter_3_0)
				elseif arg_3_0:isDeath() then
					var_3_1:updateHp(0)
					var_3_1:die()
					table.remove(arg_3_0.blueSummonMonsters_, iter_3_0)
					var_3_2:removeBuffByID(var_0_11)
				end
			end
		end
	end

	if arg_3_0:isDeath() then
		return
	end

	if arg_3_0.isPurpleSkill_ and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_0_1.ctx.battle.count % 10 < 1 then
		if arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_24 then
			local var_3_3 = {}

			for iter_3_1, iter_3_2 in ipairs(arg_3_0.sideTeam_) do
				if not iter_3_2:isDeath() and not iter_3_2:isAffected() and not iter_3_2:getBuffByID(var_0_15) and arg_3_0:isInCircle(iter_3_2) then
					table.insert(var_3_3, iter_3_2)
				end
			end

			if var_3_3 and next(var_3_3) then
				local var_3_4 = arg_3_0:createAttackUnits(var_3_3, var_0_23)

				for iter_3_3, iter_3_4 in ipairs(var_3_4) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_4)
					table.insert(arg_3_0.records_.special_units, iter_3_4)
				end
			end
		else
			local var_3_5 = {}

			for iter_3_5, iter_3_6 in ipairs(arg_3_0.sideTeam_) do
				if not iter_3_6:isDeath() and not iter_3_6:isAffected() and not iter_3_6:getBuffByID(var_0_15) and arg_3_0:isInCircle(iter_3_6) then
					table.insert(var_3_5, iter_3_6)
				end
			end

			if var_3_5 and next(var_3_5) then
				local var_3_6 = arg_3_0:createAttackUnits(var_3_5, var_0_13)

				for iter_3_7, iter_3_8 in ipairs(var_3_6) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_8)
					table.insert(arg_3_0.records_.special_units, iter_3_8)
				end
			end
		end
	end
end

function var_0_3.isInCircle(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1:getX()
	local var_4_1 = arg_4_0:getX()

	if var_0_6:scope(arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)) / 2 >= math.abs(var_4_0 - var_4_1) then
		return true
	end

	return false
end

function var_0_3.buffRemoveAction(arg_5_0, arg_5_1)
	if arg_5_1:getTableID() == var_0_12 or arg_5_1:getTableID() == var_0_22 then
		arg_5_0.isPurpleSkill_ = false
	end
end

function var_0_3.selectTargetByTypeD1(arg_6_0, arg_6_1, arg_6_2)
	if arg_6_0.blueSummonMonsters_ and next(arg_6_0.blueSummonMonsters_) then
		return {}
	end

	local var_6_0 = 0
	local var_6_1
	local var_6_2 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1:getSummonType() == var_0_2.summonMonsterType.None and var_6_0 < iter_6_1:getAD() then
			var_6_0 = iter_6_1:getAD()
			var_6_1 = iter_6_1
		end
	end

	return {
		var_6_1
	}
end

function var_0_3.greenSkill(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_1.target:getBuffsByID(var_0_9)

	if #var_7_0 > 1 then
		local var_7_1 = 0
		local var_7_2 = var_0_2.tables.battleConfig.buffHarmBaseDuration

		for iter_7_0 = #var_7_0, 1, -1 do
			local var_7_3 = var_7_0[iter_7_0]

			if var_7_3 then
				local var_7_4 = math.ceil(var_7_3.leftCount_ / var_7_2)

				if var_7_4 > var_0_16 then
					var_7_4 = var_0_16
				end

				var_7_1 = var_7_1 + var_7_3:getHarm() * var_7_3.fighter:getBuffHarmRate() * var_7_4

				var_7_3.target:removeBuffs(var_7_3)
			end
		end

		arg_7_0.greenTotalHarm_[arg_7_1.target] = var_7_1

		local var_7_5 = {
			arg_7_1.target
		}
		local var_7_6 = arg_7_0:createAttackUnits(var_7_5, var_0_10)

		for iter_7_1, iter_7_2 in ipairs(var_7_6) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_2)
			table.insert(arg_7_0.records_.special_units, iter_7_2)
		end
	end
end

function var_0_3.skinHarmSkill(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_1.target:getBuffsByID(var_0_17)

	if #var_8_0 > 1 then
		local var_8_1 = 0
		local var_8_2 = var_0_2.tables.battleConfig.buffHarmBaseDuration

		for iter_8_0 = #var_8_0, 1, -1 do
			local var_8_3 = var_8_0[iter_8_0]

			if var_8_3 then
				local var_8_4 = math.ceil(var_8_3.leftCount_ / var_8_2)

				if var_8_4 > var_0_16 then
					var_8_4 = var_0_16
				end

				var_8_1 = var_8_1 + var_8_3:getHarm() * var_8_3.fighter:getBuffHarmRate() * var_8_4
			end
		end

		arg_8_0.skinEnergyTotalHarm_[arg_8_1.target] = var_8_1

		local var_8_5 = {
			arg_8_1.target
		}
		local var_8_6 = arg_8_0:createAttackUnits(var_8_5, var_0_28)

		for iter_8_1, iter_8_2 in ipairs(var_8_6) do
			table.insert(arg_8_0.moveAttackUnits_, iter_8_2)
			table.insert(arg_8_0.records_.special_units, iter_8_2)
		end
	end
end

function var_0_3.greenSkinSkill(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_1.target:getBuffsByID(var_0_17)

	if #var_9_0 > 1 then
		local var_9_1 = 0
		local var_9_2 = var_0_2.tables.battleConfig.buffHarmBaseDuration

		for iter_9_0 = #var_9_0, 1, -1 do
			local var_9_3 = var_9_0[iter_9_0]

			if var_9_3 then
				local var_9_4 = math.ceil(var_9_3.leftCount_ / var_9_2)

				if var_9_4 > var_0_16 then
					var_9_4 = var_0_16
				end

				var_9_1 = var_9_1 + var_9_3:getHarm() * var_9_3.fighter:getBuffHarmRate() * var_9_4

				var_9_3.target:removeBuffs(var_9_3)
			end
		end

		arg_9_0.greenTotalHarm_[arg_9_1.target] = var_9_1

		local var_9_5 = {
			arg_9_1.target
		}
		local var_9_6 = arg_9_0:createAttackUnits(var_9_5, var_0_19)

		for iter_9_1, iter_9_2 in ipairs(var_9_6) do
			table.insert(arg_9_0.moveAttackUnits_, iter_9_2)
			table.insert(arg_9_0.records_.special_units, iter_9_2)
		end
	end
end

function var_0_3.energySkill(arg_10_0, arg_10_1)
	arg_10_0:collectEnergySkillHarm()

	local var_10_0 = var_0_6:scope(var_0_7)
	local var_10_1 = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and iter_10_1 ~= arg_10_1.target and math.abs(iter_10_1:getX() - arg_10_1.target:getX()) <= var_10_0 * 0.5 then
			table.insert(var_10_1, iter_10_1)
		end
	end

	local var_10_2 = arg_10_0:createAttackUnits(var_10_1, var_0_7)

	for iter_10_2, iter_10_3 in ipairs(var_10_2) do
		table.insert(arg_10_0.moveAttackUnits_, iter_10_3)
		table.insert(arg_10_0.records_.special_units, iter_10_3)
	end
end

function var_0_3.collectEnergySkillHarm(arg_11_0)
	local var_11_0 = 0
	local var_11_1 = var_0_2.tables.battleConfig.buffHarmBaseDuration

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.sideTeam_) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() then
			local var_11_2 = iter_11_1:getBuffs()

			for iter_11_2 = #var_11_2, 1, -1 do
				local var_11_3 = var_11_2[iter_11_2]

				if var_11_3:getType() == var_0_2.BuffType.CONTINUE_HARM then
					local var_11_4 = math.ceil(var_11_3.leftCount_ / var_11_1)

					if var_11_4 > var_0_16 then
						var_11_4 = var_0_16
					end

					var_11_0 = var_11_0 + var_11_3:getHarm() * var_11_3.fighter:getBuffHarmRate() * var_11_4
				end
			end
		end
	end

	for iter_11_3, iter_11_4 in ipairs(arg_11_0.selfTeam_) do
		if not iter_11_4:isDeath() and not iter_11_4:isAffected() then
			local var_11_5 = iter_11_4:getBuffs()

			for iter_11_5 = #var_11_5, 1, -1 do
				local var_11_6 = var_11_5[iter_11_5]

				if var_11_6:getType() == var_0_2.BuffType.CONTINUE_HARM then
					local var_11_7 = math.ceil(var_11_6.leftCount_ / var_11_1)

					if var_11_7 > var_0_16 then
						var_11_7 = var_0_16
					end

					var_11_0 = var_11_0 + var_11_6:getHarm() * var_11_6.fighter:getBuffHarmRate() * var_11_7
				end
			end
		end
	end

	arg_11_0.energyTotalHarm_ = var_11_0
end

function var_0_3.blueSkinSkill(arg_12_0, arg_12_1)
	if arg_12_1.target:isBoss() then
		return
	end

	local var_12_0
	local var_12_1 = arg_12_1.target
	local var_12_2 = var_12_1:getX() - 100
	local var_12_3 = var_12_1:getY()
	local var_12_4 = var_12_1.hero_:toParams()

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_12_0 = arg_12_0:getSummonMonster()
	else
		local var_12_5 = var_0_5.new()

		var_12_5:populate(var_12_4)

		local var_12_6 = var_12_5:className()

		var_12_0 = var_0_1.ctx.battle.requireFighter(var_12_6).new({
			is_arena = arg_12_0.isInArena_
		})

		var_12_0:populateWithHero(var_12_5)
		var_12_0:initModels()
		var_12_0.fighterModel:initHeaderView(arg_12_0:getTeamType() - 1)

		var_12_0.fighterIndex = arg_12_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_12_0:setFormationDelay(0, 100)
	end

	var_12_0:setTeamType(arg_12_0:getTeamType())

	var_12_0.summoner = arg_12_0

	var_12_0.fighterModel:pos(var_12_2, var_12_3)
	var_12_0:getFighterModel():flipX(arg_12_0:getTeamType() == var_0_2.TeamType.B)
	var_12_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_12_0:born()
	var_12_0:setGlobalBuffs()
	var_12_0:updateHp(var_12_0:getHpLimit())

	var_12_0.summonType_ = var_0_2.summonMonsterType.Copy

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		var_12_0:getFighterModel():setMaskColor(cc.c4f(1, 0.88, 0.46, 1))
		var_12_0:setDefaultMaskColor(cc.c4f(1, 0.88, 0.46, 1))
	end

	local var_12_7 = arg_12_0:newBuff({
		var_0_11
	}, var_12_0, var_0_26, var_12_1)

	var_12_0:addBuffs(var_12_7)

	local var_12_8 = arg_12_0:newBuff({
		var_0_25
	}, var_12_0, var_0_26)

	var_12_0:addBuffs(var_12_8)

	local var_12_9 = arg_12_0:newBuff({
		var_0_11
	}, var_12_1, var_0_26, var_12_0)

	var_12_1:addBuffs(var_12_9)

	local var_12_10 = var_12_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_12_10, var_12_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_12_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_12_0.blueSummonMonsters_, {
		monster = var_12_0,
		forceTarget = var_12_1
	})
end

function var_0_3.blueSkill(arg_13_0, arg_13_1)
	if arg_13_1.target:isBoss() then
		return
	end

	local var_13_0
	local var_13_1 = arg_13_1.target
	local var_13_2 = var_13_1:getX() - 100
	local var_13_3 = var_13_1:getY()
	local var_13_4 = var_13_1.hero_:toParams()

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_13_0 = arg_13_0:getSummonMonster()
	else
		local var_13_5 = var_0_5.new()

		var_13_5:populate(var_13_4)

		local var_13_6 = var_13_5:className()

		var_13_0 = var_0_1.ctx.battle.requireFighter(var_13_6).new({
			is_arena = arg_13_0.isInArena_
		})

		var_13_0:populateWithHero(var_13_5)
		var_13_0:initModels()
		var_13_0.fighterModel:initHeaderView(arg_13_0:getTeamType() - 1)

		var_13_0.fighterIndex = arg_13_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_13_0:setFormationDelay(0, 100)
	end

	var_13_0:setTeamType(arg_13_0:getTeamType())

	var_13_0.summoner = arg_13_0

	var_13_0.fighterModel:pos(var_13_2, var_13_3)
	var_13_0:getFighterModel():flipX(arg_13_0:getTeamType() == var_0_2.TeamType.B)
	var_13_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_13_0:born()
	var_13_0:setGlobalBuffs()
	var_13_0:updateHp(var_13_0:getHpLimit())

	var_13_0.summonType_ = var_0_2.summonMonsterType.Copy

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		var_13_0:getFighterModel():setMaskColor(cc.c4f(1, 0.88, 0.46, 1))
		var_13_0:setDefaultMaskColor(cc.c4f(1, 0.88, 0.46, 1))
	end

	local var_13_7 = arg_13_0:newBuff({
		var_0_11
	}, var_13_0, arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue), var_13_1)

	var_13_0:addBuffs(var_13_7)

	local var_13_8 = arg_13_0:newBuff({
		var_0_14
	}, var_13_0, arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

	var_13_0:addBuffs(var_13_8)

	local var_13_9 = arg_13_0:newBuff({
		var_0_11
	}, var_13_1, arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue), var_13_0)

	var_13_1:addBuffs(var_13_9)

	local var_13_10 = var_13_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_13_10, var_13_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_13_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_13_0.blueSummonMonsters_, {
		monster = var_13_0,
		forceTarget = var_13_1
	})
end

function var_0_3.applySingleUnit(arg_14_0, arg_14_1)
	var_0_3.super.applySingleUnit(arg_14_0, arg_14_1)

	if arg_14_1.skillID == arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_14_0:greenSkill(arg_14_1)
	elseif (arg_14_1.skillID == arg_14_0:getEnergySkillID() or arg_14_1.skillID == var_0_18) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_14_0:energySkill(arg_14_1)
	elseif arg_14_1.skillID == arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_14_0:blueSkill(arg_14_1)
	elseif arg_14_1.skillID == arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) or arg_14_1.skillID == var_0_21 then
		arg_14_0.isPurpleSkill_ = true
	elseif arg_14_1.skillID == var_0_20 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_14_0:greenSkinSkill(arg_14_1)
	elseif arg_14_1.skillID == var_0_26 then
		arg_14_0:blueSkinSkill(arg_14_1)
	elseif arg_14_1.skillID == var_0_27 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_14_0:skinHarmSkill(arg_14_1)
	end
end

function var_0_3.newBuff(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4)
	local var_15_0 = {}

	for iter_15_0, iter_15_1 in ipairs(arg_15_1) do
		local var_15_1 = var_0_4.new({
			tableID = iter_15_1,
			start = var_0_1.ctx.battle.count,
			level = arg_15_0:getSkillLevelByID(arg_15_3),
			skillID = arg_15_3,
			fighter = arg_15_0,
			target = arg_15_2
		})

		var_15_1:setIsHit(true)
		var_15_1:setDirection(arg_15_0:getFighterModel():getFlipX())

		if arg_15_4 then
			var_15_1:setForceTarget(arg_15_4)
		end

		table.insert(var_15_0, var_15_1)
	end

	return var_15_0
end

function var_0_3.updateUnitDataByFighter(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7)
	local var_16_0, var_16_1, var_16_2, var_16_3, var_16_4, var_16_5 = var_0_3.super.updateUnitDataByFighter(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7)

	if var_16_2 > 0 and (arg_16_1.skillID == arg_16_0:getEnergySkillID() or arg_16_1.skillID == var_0_18) then
		arg_16_0:collectEnergySkillHarm()

		var_16_2 = arg_16_0.energyTotalHarm_ + var_16_2
	elseif var_16_2 > 0 and arg_16_1.skillID == var_0_7 then
		var_16_2 = arg_16_0.energyTotalHarm_ * var_0_8 + var_16_2
	elseif var_16_2 > 0 and (arg_16_1.skillID == var_0_10 or arg_16_1.skillID == var_0_19) and arg_16_0.greenTotalHarm_[arg_16_1.target] and arg_16_0.greenTotalHarm_[arg_16_1.target] > 0 then
		var_16_2 = arg_16_0.greenTotalHarm_[arg_16_1.target]
		arg_16_0.greenTotalHarm_[arg_16_1.target] = 0
	elseif var_16_2 > 0 and arg_16_1.skillID == var_0_28 and arg_16_0.skinEnergyTotalHarm_[arg_16_1.target] and arg_16_0.skinEnergyTotalHarm_[arg_16_1.target] > 0 then
		var_16_2 = arg_16_0.skinEnergyTotalHarm_[arg_16_1.target]
		arg_16_0.skinEnergyTotalHarm_[arg_16_1.target] = 0
	end

	local var_16_6 = math.min(var_16_2, var_0_29 * arg_16_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))

	return var_16_0, var_16_1, var_16_6, var_16_3, var_16_4, var_16_5
end

return var_0_3
