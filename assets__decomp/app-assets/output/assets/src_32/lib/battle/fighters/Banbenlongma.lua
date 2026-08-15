local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Banbenlongma", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_8 = 10001328
local var_0_9 = 20010207
local var_0_10 = 10001329
local var_0_11 = 30010207
local var_0_12 = 0
local var_0_13 = 200
local var_0_14 = 40011419
local var_0_15 = 40010207
local var_0_16 = 10010242
local var_0_17 = 80010207
local var_0_18 = 10002214
local var_0_19 = 10002215
local var_0_20 = 2

function var_0_3.populateWithHero(arg_1_0, arg_1_1)
	var_0_3.super.populateWithHero(arg_1_0, arg_1_1)

	if arg_1_0.skinSkillIndex_ == 1 then
		arg_1_0.EnergySkillID = 10002223
		arg_1_0.BlueSpecialEffectBuffID = 40012364
		arg_1_0.EnergySpecialEffectBuffID = 40012365
	else
		arg_1_0.EnergySkillID = 50010207
		arg_1_0.BlueSpecialEffectBuffID = 40011422
		arg_1_0.EnergySpecialEffectBuffID = 40011423
	end
end

function var_0_3.ctor(arg_2_0, arg_2_1)
	var_0_3.super.ctor(arg_2_0, arg_2_1)
	arg_2_0:listenInfo("attack_info")
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.cannonFort = {}

	for iter_3_0 = 1, var_0_20 do
		arg_3_0.cannonFort[var_0_20] = nil
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	local var_4_0 = arg_4_1.skillID

	if var_4_0 == var_0_9 then
		if arg_4_0.cannonFort[1] and not arg_4_0.cannonFort[1]:isDeath() then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_4_1 = arg_4_0:createAttackUnits({
					arg_4_0.cannonFort[1]
				}, var_0_10)

				for iter_4_0, iter_4_1 in ipairs(var_4_1) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
					table.insert(arg_4_0.records_.special_units, iter_4_1)
				end
			end
		else
			local var_4_2 = var_0_6:summonMonster(var_4_0)
			local var_4_3, var_4_4 = next(var_4_2)

			arg_4_0:setSummonMonsters(var_4_4, arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green), arg_4_0.hero_:getColor(), {
				x = arg_4_1.desX_ + (arg_4_0:getFlipX() and -50 or 50),
				y = arg_4_1.desY_ - 125
			}, var_0_9)
		end
	elseif var_4_0 == var_0_17 then
		local var_4_5 = {
			var_0_18,
			var_0_19
		}

		arg_4_0:judgeMoveUnit(arg_4_1, arg_4_0.cannonFort, var_4_5)
	elseif var_4_0 == var_0_18 then
		arg_4_0:setSummonSkill(arg_4_1, var_0_18, 0)
	elseif var_4_0 == var_0_19 then
		arg_4_0:setSummonSkill(arg_4_1, var_0_19, -125)
	end

	arg_4_0:judgeSingleUnit(arg_4_1, arg_4_0.cannonFort)
end

function var_0_3.judgeSingleUnit(arg_5_0, arg_5_1, arg_5_2)
	for iter_5_0 = 1, var_0_20 do
		local var_5_0 = arg_5_2[iter_5_0]

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_5_1.skillID == var_0_8 and arg_5_1.target == arg_5_0 and var_5_0 and not var_5_0:isDeath() then
			local var_5_1 = arg_5_0:createAttackUnits({
				var_5_0
			}, var_0_8)

			for iter_5_1, iter_5_2 in ipairs(var_5_1) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_2)
				table.insert(arg_5_0.records_.special_units, iter_5_2)
			end

			if var_5_0:isHasBuffByID(arg_5_0.BlueSpecialEffectBuffID) then
				var_5_0:removeBuffByID(arg_5_0.BlueSpecialEffectBuffID)
			end

			local var_5_2 = var_0_4.new({
				tableID = arg_5_0.EnergySpecialEffectBuffID,
				start = var_0_1.ctx.battle.count,
				level = arg_5_0:getSkillLevelByID(arg_5_0.EnergySkillID),
				skillID = arg_5_0.EnergySkillID,
				fighter = arg_5_0,
				target = var_5_0
			})

			var_5_0:addBuffs({
				var_5_2
			})
		end
	end
end

function var_0_3.judgeMoveUnit(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	for iter_6_0 = 1, var_0_20 do
		local var_6_0 = arg_6_2[iter_6_0]

		if var_6_0 and not var_6_0:isDeath() then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_6_1 = arg_6_0:createAttackUnits({
					var_6_0
				}, var_0_10)

				for iter_6_1, iter_6_2 in ipairs(var_6_1) do
					table.insert(arg_6_0.moveAttackUnits_, iter_6_2)
					table.insert(arg_6_0.records_.special_units, iter_6_2)
				end
			end
		elseif var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_2 = arg_6_0:createAttackUnits({
				arg_6_0
			}, arg_6_3[iter_6_0])

			for iter_6_3, iter_6_4 in ipairs(var_6_2) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_4)
				table.insert(arg_6_0.records_.special_units, iter_6_4)
			end
		end
	end
end

function var_0_3.setSummonSkill(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = var_0_6:summonMonster(arg_7_2)

	if next(var_7_0) == nil then
		return
	end

	for iter_7_0, iter_7_1 in ipairs(var_7_0) do
		local var_7_1 = arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)
		local var_7_2 = arg_7_0.hero_:getColor()
		local var_7_3 = {
			x = arg_7_1.desX_ + (arg_7_0:getFlipX() and -50 or 50),
			y = arg_7_1.desY_ + arg_7_3
		}

		arg_7_0:setSummonMonsters(iter_7_1, var_7_1, var_7_2, var_7_3, arg_7_2)
	end
end

function var_0_3.setSummonMonsters(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5)
	local var_8_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_8_0 = arg_8_0:getSummonMonster()
	else
		local var_8_1 = var_0_7.new()

		var_8_1:populateWithTableID(arg_8_1)

		var_8_1.level_ = arg_8_2 or var_8_1.level_
		var_8_1.color_ = arg_8_3 or var_8_1.color_

		for iter_8_0, iter_8_1 in ipairs(var_8_1.skillLev_) do
			local var_8_2 = arg_8_0.hero_:getSkillLevel(iter_8_0)

			if var_8_2 and var_8_2 > 0 then
				var_8_1.skillLev_[iter_8_0] = var_0_0.clone(var_8_2)
			end
		end

		local var_8_3 = var_8_1:className()

		var_8_0 = var_0_1.ctx.battle.requireFighter(var_8_3).new({
			is_arena = arg_8_0.isInArena_
		})

		var_8_0:populateWithHero(var_8_1)
		var_8_0:initModels()
		var_8_0.fighterModel:initHeaderView(arg_8_0:getTeamType() - 1)

		var_8_0.fighterIndex = arg_8_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_8_0:setFormationDelay(0, 50)
	end

	var_8_0:setTeamType(arg_8_0:getTeamType())

	var_8_0.summoner = arg_8_0

	var_8_0.fighterModel:pos(arg_8_4.x, arg_8_4.y)

	local var_8_4 = arg_8_0:getSkillLevelByID(var_0_11)

	if var_8_4 > 0 then
		local var_8_5 = var_0_12 + var_0_13 * var_8_4

		var_8_0:resetHpLimit(var_8_0:getHpLimit() + var_8_5)

		for iter_8_2, iter_8_3 in ipairs(arg_8_0.selfTeam_) do
			if iter_8_3.hero_:getHeroType() == var_0_2.HeroType.AGILE and not iter_8_3:isDeath() and not iter_8_3:isAffected() then
				local var_8_6 = var_0_4.new({
					tableID = var_0_14,
					start = var_0_1.ctx.battle.count,
					level = var_8_4,
					skillID = var_0_11,
					fighter = arg_8_0,
					target = var_8_0
				})

				var_8_0:addBuffs({
					var_8_6
				})
			end
		end
	end

	var_8_0.isImmuneControl = true

	var_8_0:updateHp(var_8_0:getHpLimit())
	var_8_0:getFighterModel():flipX(arg_8_0:getTeamType() == var_0_2.TeamType.B)
	var_8_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_8_0:born()
	var_8_0:setGlobalBuffs()

	local var_8_7 = var_8_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_8_7, var_8_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_8_0)
	var_0_1.ctx.battle.updateZorder()

	if arg_8_5 == var_0_9 then
		arg_8_0.cannonFort[1] = var_8_0
	elseif arg_8_5 == var_0_18 then
		arg_8_0.cannonFort[1] = var_8_0
	elseif arg_8_5 == var_0_19 then
		arg_8_0.cannonFort[2] = var_8_0
	end
end

function var_0_3.forceDie(arg_9_0)
	if arg_9_0.cannonFort[1] and not arg_9_0.cannonFort[1]:isDeath() then
		arg_9_0.cannonFort[1]:forceDie()
	end

	if arg_9_0.cannonFort[2] and not arg_9_0.cannonFort[2]:isDeath() then
		arg_9_0.cannonFort[2]:forceDie()
	end

	var_0_3.super.forceDie(arg_9_0)
end

function var_0_3.toDoPerFrames(arg_10_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		for iter_10_0, iter_10_1 in ipairs(arg_10_0:getInfoByKey("attack_info")) do
			if iter_10_1.rootID_ == var_0_16 and arg_10_0:fighterIsCannonFort(iter_10_1.fighter_) then
				arg_10_0:onApplyPurplePassiveSkill()

				break
			end
		end
	end

	arg_10_0:judgePerFrames(arg_10_0.cannonFort)
end

function var_0_3.fighterIsCannonFort(arg_11_0, arg_11_1)
	for iter_11_0 = 1, var_0_20 do
		if arg_11_0.cannonFort[iter_11_0] == arg_11_1 then
			return true
		end
	end

	return false
end

function var_0_3.judgePerFrames(arg_12_0, arg_12_1)
	for iter_12_0 = 1, var_0_20 do
		local var_12_0 = arg_12_1[iter_12_0]

		if var_0_1.ctx.battle.walk2NextBattle_ and var_12_0 and not var_12_0:isDeath() then
			var_12_0:forceDie()
		end

		if var_12_0 and not var_12_0:isDeath() and arg_12_0:getSkillLevelByID(var_0_11) > 0 and not var_12_0:isHasBuffByID(arg_12_0.EnergySpecialEffectBuffID) and not var_12_0:isHasBuffByID(arg_12_0.BlueSpecialEffectBuffID) then
			local var_12_1 = var_0_4.new({
				tableID = arg_12_0.BlueSpecialEffectBuffID,
				start = var_0_1.ctx.battle.count,
				level = arg_12_0:getSkillLevelByID(var_0_11),
				skillID = var_0_11,
				fighter = arg_12_0,
				target = var_12_0
			})

			var_12_0:addBuffs({
				var_12_1
			})
		end
	end
end

function var_0_3.deathFeedback(arg_13_0, arg_13_1)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_13_0:fighterIsCannonFort(arg_13_1) then
		arg_13_0:onApplyPurplePassiveSkill()
	end
end

function var_0_3.onApplyPurplePassiveSkill(arg_14_0)
	if arg_14_0:getSkillLevelByID(var_0_15) == 0 then
		return
	end

	local var_14_0 = {}

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.selfTeam_) do
		if iter_14_1.hero_:getHeroType() == var_0_2.HeroType.AGILE and iter_14_1:getSummonType() == var_0_2.summonMonsterType.None and not iter_14_1:isDeath() and not iter_14_1:isAffected() then
			table.insert(var_14_0, iter_14_1)
		end
	end

	local var_14_1 = arg_14_0:createAttackUnits(var_14_0, var_0_15)

	for iter_14_2, iter_14_3 in ipairs(var_14_1) do
		table.insert(arg_14_0.moveAttackUnits_, iter_14_3)
		table.insert(arg_14_0.records_.special_units, iter_14_3)
	end
end

return var_0_3
