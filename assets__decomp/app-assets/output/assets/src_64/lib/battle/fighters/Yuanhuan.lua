local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yuanhuan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = {
	40010838,
	40010839,
	40010845
}
local var_0_8 = 40010836
local var_0_9 = 0.5
local var_0_10 = 10000764
local var_0_11 = 2
local var_0_12 = 5
local var_0_13 = 0
local var_0_14 = 0.0002
local var_0_15 = 40010846
local var_0_16 = 20020006
local var_0_17 = 40010903

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.energyTargets_ = {}
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.summonMonsters_ = {}
	arg_2_0.curEnergyTarget_ = {}
	arg_2_0.ackCount_ = 0
	arg_2_0.extraSkillJudge = false
	arg_2_0.extraSkillLevel = 0
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		if arg_3_0.curEnergyTarget_ and next(arg_3_0.curEnergyTarget_) and not arg_3_0.curEnergyTarget_:isDeath() then
			arg_3_0.curEnergyTarget_:updateHp(0)
			arg_3_0.curEnergyTarget_:die()
		end

		if arg_3_0.summonMonsters_ and next(arg_3_0.summonMonsters_) then
			for iter_3_0 = #arg_3_0.summonMonsters_, 1, -1 do
				if arg_3_0.summonMonsters_[iter_3_0] and not arg_3_0.summonMonsters_[iter_3_0]:isDeath() then
					arg_3_0.summonMonsters_[iter_3_0]:updateHp(0)
					arg_3_0.summonMonsters_[iter_3_0]:die()
					table.remove(arg_3_0.summonMonsters_, iter_3_0)
				end
			end
		end

		return
	end

	if not arg_3_0.extraSkillJudge then
		arg_3_0.extraSkillJudge = true
		arg_3_0.extraSkillLevel = arg_3_0.hero_:skillBook()[tostring(var_0_16)] or 0
	end
end

function var_0_3.getCurrentAckSpeed(arg_4_0)
	local var_4_0 = var_0_3.super.getCurrentAckSpeed(arg_4_0)
	local var_4_1 = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_4_1 > 0 then
		local var_4_2 = (var_0_14 * var_4_1 + var_0_13) * arg_4_0.ackCount_

		var_4_0 = math.min(var_4_0 + var_4_2, var_0_2.MAX_ATTACK_SPEED)
	end

	return var_4_0
end

function var_0_3.getEnergyTarget(arg_5_0)
	local var_5_0 = arg_5_0:getDieHeros()

	if #var_5_0 == 0 then
		return {}
	end

	local var_5_1 = var_5_0[math.random(1, #var_5_0)]

	table.insert(arg_5_0.energyTargets_, var_5_1)

	return var_5_1
end

function var_0_3.getDieHeros(arg_6_0)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if iter_6_1:isDeath() and not iter_6_1:canReborn() and iter_6_1:getSummonType() == var_0_2.summonMonsterType.None and not var_0_0.table.keyof(arg_6_0.energyTargets_, iter_6_1) then
			table.insert(var_6_0, iter_6_1)
		end
	end

	return var_6_0
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if arg_7_1.skillID == arg_7_0:getEnergySkillID() then
		arg_7_0:summonEnergyMonster()
	elseif arg_7_1.skillID == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and #arg_7_0.summonMonsters_ < var_0_12 then
		arg_7_0:summonBlueMonster(arg_7_1.target)
	end
end

function var_0_3.summonEnergyMonster(arg_8_0)
	local var_8_0 = arg_8_0:getFlipX() == true and -1 or 1
	local var_8_1 = arg_8_0:getX() + var_8_0 * 100
	local var_8_2 = arg_8_0:getY()
	local var_8_3

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_8_3 = arg_8_0:getSummonMonster()
	else
		local var_8_4 = arg_8_0:getEnergyTarget()

		if not var_8_4 or not next(var_8_4) then
			return
		end

		local var_8_5 = var_0_6.new()
		local var_8_6 = var_8_4.hero_:toParams()

		var_8_5:populate(var_8_6)

		var_8_3 = arg_8_0:newFighter(var_8_5, arg_8_0:getTeamType(), false)

		local var_8_7 = #arg_8_0.selfTeam_ + 1

		var_8_3.fighterIndex = arg_8_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_8_3:setFormationDelay(var_0_2.tables.battleConfig.skillDelayQueue[var_8_7], var_0_2.tables.battleConfig.formationWalkQueue[var_8_7])
	end

	var_8_3.hasReborn_ = true
	var_8_3.summoner = arg_8_0

	var_8_3.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_8_3:setTeamType(arg_8_0:getTeamType())
	var_8_3.fighterModel:pos(var_8_1, var_8_2)
	var_8_3:setupBattleAttrInfo()
	var_8_3:setGlobalBuffs()
	var_8_3:setSummonAutoFight(true)
	var_8_3:born()

	var_8_3.summonType_ = var_0_2.summonMonsterType.Copy

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		var_8_3:getFighterModel():setMaskColor(cc.c4f(1, 0.88, 0.46, 1))
		var_8_3:setDefaultMaskColor(cc.c4f(1, 0.88, 0.46, 1))
	end

	var_8_3:addBuffs(arg_8_0:newBuff(var_0_7, var_8_3, arg_8_0:getEnergySkillID()))
	table.insert(arg_8_0.selfTeam_, var_8_3)

	arg_8_0.curEnergyTarget_ = var_8_3
end

function var_0_3.newBuff(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4)
	local var_9_0 = arg_9_4 or arg_9_0:getSkillLevelByID(arg_9_3) or 0
	local var_9_1 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_1) do
		local var_9_2 = var_0_5.new({
			tableID = iter_9_1,
			start = var_0_1.ctx.battle.count,
			level = var_9_0,
			skillID = arg_9_3,
			fighter = arg_9_0,
			target = arg_9_2
		})

		var_9_2:setIsHit(true)
		var_9_2:setDirection(arg_9_0:getFighterModel():getFlipX())
		table.insert(var_9_1, var_9_2)
	end

	return var_9_1
end

function var_0_3.newFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = arg_10_1:className()
	local var_10_1 = var_0_1.ctx.battle.requireFighter(var_10_0).new({
		is_arena = arg_10_0.isInArena_
	})

	var_10_1:populateWithHero(arg_10_1)
	var_10_1:initModels()
	var_10_1:getFighterModel():idle()

	local var_10_2 = arg_10_2 - 1

	var_10_1.fighterModel:initHeaderView(var_10_2)
	var_10_1:getFighterModel():flipX(arg_10_3)

	return var_10_1
end

function var_0_3.summonBlueMonster(arg_11_0, arg_11_1)
	local function var_11_0(arg_12_0, arg_12_1)
		local var_12_0 = {}

		if arg_12_1 >= #arg_12_0 then
			return arg_12_0
		end

		while arg_12_1 > #var_12_0 do
			local var_12_1 = math.random(1, #arg_12_0)

			if not var_0_0.table.keyof(var_12_0, arg_12_0[var_12_1]) then
				table.insert(var_12_0, arg_12_0[var_12_1])
			end
		end

		return var_12_0
	end

	local var_11_1 = arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
	local var_11_2 = var_0_4:summonMonster(var_11_1)

	if next(var_11_2) == nil then
		return
	end

	local var_11_3 = var_0_11

	if var_0_12 - #arg_11_0.summonMonsters_ < var_0_11 then
		var_11_3 = 1
	end

	local var_11_4 = var_11_0(var_11_2, var_11_3)

	for iter_11_0, iter_11_1 in ipairs(var_11_4) do
		local var_11_5 = arg_11_0:getSkillLevelByID(var_11_1)
		local var_11_6 = arg_11_0.hero_:getColor()
		local var_11_7

		if arg_11_1:isBoss() then
			local var_11_8 = arg_11_1:getFlipX() == true and -1 or 1

			var_11_7 = arg_11_1:getX() + var_11_8 * 100
		else
			var_11_7 = arg_11_0:getX() < arg_11_1:getX() and arg_11_1:getX() - 100 or arg_11_1:getX() + 100
		end

		local var_11_9 = var_0_1.ctx.battle.adjustX(var_11_7, arg_11_0)
		local var_11_10 = {
			y = 230,
			x = var_11_9
		}

		if arg_11_1:avoidHeroMoveBehind() then
			var_11_10.x = var_11_10.x - arg_11_1:getFighterModel():getWidth()
		end

		arg_11_0:setSummonMonsters(iter_11_1, var_11_5, var_11_6, var_11_10)

		arg_11_0.ackCount_ = arg_11_0.ackCount_ + 1
	end
end

function var_0_3.setSummonMonsters(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4)
	local var_13_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_13_0 = arg_13_0:getSummonMonster()
	else
		local var_13_1 = var_0_6.new()

		var_13_1:populateWithTableID(arg_13_1)

		var_13_1.level_ = arg_13_2 or var_13_1.level_
		var_13_1.color_ = arg_13_3 or var_13_1.color_

		for iter_13_0, iter_13_1 in ipairs(var_13_1.skillLev_) do
			local var_13_2 = arg_13_0.hero_:getSkillLevel(iter_13_0)

			if var_13_2 and var_13_2 > 0 then
				var_13_1.skillLev_[iter_13_0] = var_0_0.clone(var_13_2)
			end
		end

		local var_13_3 = var_13_1:className()

		var_13_0 = var_0_1.ctx.battle.requireFighter(var_13_3).new({
			is_arena = arg_13_0.isInArena_
		})

		var_13_0:populateWithHero(var_13_1)
		var_13_0:initModels()
		var_13_0.fighterModel:initHeaderView(arg_13_0:getTeamType() - 1)

		var_13_0.fighterIndex = arg_13_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_13_0:setFormationDelay(0, 100)
	end

	var_13_0:setTeamType(arg_13_0:getTeamType())

	var_13_0.summoner = arg_13_0

	var_13_0.fighterModel:pos(arg_13_4.x, arg_13_4.y)
	var_13_0:getFighterModel():flipX(arg_13_0:getTeamType() == var_0_2.TeamType.B)
	var_13_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_13_0:born()
	var_13_0:setGlobalBuffs()
	var_13_0:updateHp(var_13_0:getHpLimit())
	var_13_0:addBuffs(arg_13_0:newBuff({
		var_0_15
	}, var_13_0, arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)))
	table.insert(arg_13_0.summonMonsters_, var_13_0)

	local var_13_4 = var_13_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_13_4, var_13_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_13_0)
	var_0_1.ctx.battle.updateZorder()
end

function var_0_3.checkEnergySkill(arg_14_0)
	if #arg_14_0:getDieHeros() == 0 then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_14_0)
end

function var_0_3.buffRemoveAction(arg_15_0, arg_15_1)
	if arg_15_1:getTableID() == var_0_8 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_15_0 = arg_15_1.target

		if not var_15_0:isDeath() and var_15_0:getHp() / var_15_0:getHpLimit() < var_0_9 then
			local var_15_1 = arg_15_0:createAttackUnits({
				var_15_0
			}, var_0_10)

			for iter_15_0, iter_15_1 in ipairs(var_15_1) do
				table.insert(arg_15_0.moveAttackUnits_, iter_15_1)
				table.insert(arg_15_0.records_.special_units, iter_15_1)
			end
		end
	end
end

function var_0_3.deathFeedback(arg_16_0, arg_16_1)
	if arg_16_1.summoner and arg_16_1.summoner == arg_16_0 and arg_16_0.extraSkillLevel > 0 then
		local var_16_0 = arg_16_0:newBuff({
			var_0_17
		}, arg_16_0, arg_16_0:getEnergySkillID(), arg_16_0.extraSkillLevel)

		arg_16_0:addBuffs(var_16_0)
	end
end

return var_0_3
