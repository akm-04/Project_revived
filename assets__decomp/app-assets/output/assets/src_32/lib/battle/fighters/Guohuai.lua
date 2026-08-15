local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guohuai", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = var_0_2.tables.hero
local var_0_10 = 900
local var_0_11 = 40012002
local var_0_12 = 40011998
local var_0_13 = {
	40011999
}
local var_0_14 = 0.1
local var_0_15 = 0.004
local var_0_16 = 600
local var_0_17 = 0.1
local var_0_18 = 0.002
local var_0_19 = 0.5
local var_0_20 = 0.005
local var_0_21 = 0.1
local var_0_22 = 0.001
local var_0_23 = 10002380
local var_0_24 = 10002381
local var_0_25 = 10002382
local var_0_26 = 40012594
local var_0_27 = 40012595
local var_0_28 = 0.01
local var_0_29 = 0.02

function var_0_3.populateWithHero(arg_1_0, arg_1_1)
	var_0_3.super.populateWithHero(arg_1_0, arg_1_1)

	if arg_1_0.skinSkillIndex_ == 1 and arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
		arg_1_0.EnergySkill = 10002387
	elseif arg_1_0.skinSkillIndex_ == 1 then
		arg_1_0.EnergySkill = 10002386
	elseif arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
		arg_1_0.EnergySkill = 50020245
	else
		arg_1_0.EnergySkill = 50010245
	end

	if arg_1_0.skinSkillIndex_ == 1 then
		arg_1_0.GreenSkill = 10002385
		arg_1_0.LongBuffID = 40012591
		arg_1_0.blueBuffID = 40012592
		arg_1_0.blueselfDbuff = 40012593
	else
		arg_1_0.GreenSkill = 20020245
		arg_1_0.LongBuffID = 40011992
		arg_1_0.blueBuffID = 40011996
		arg_1_0.blueselfDbuff = 40011997
	end
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.summonMonster_ = nil
	arg_2_0.purpleBuffCount = 0
	arg_2_0.isAddPurple = false
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if not arg_3_0.isAddPurple and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_3_0.isAddPurple = true

		local var_3_0 = var_0_5.new({
			tableID = var_0_11,
			start = var_0_1.ctx.battle.count,
			level = arg_3_0:getSkillLevelByID(arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)),
			skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
			fighter = arg_3_0,
			target = arg_3_0
		})

		arg_3_0:addBuffs({
			var_3_0
		})

		arg_3_0.purpleBuffCount = var_0_16
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_3_0.purpleBuffCount > 0 then
		arg_3_0.purpleBuffCount = arg_3_0.purpleBuffCount - 1

		if arg_3_0.purpleBuffCount == 0 and not arg_3_0:isHasBuffByID(var_0_11) then
			local var_3_1 = var_0_5.new({
				tableID = var_0_11,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getSkillLevelByID(arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)),
				skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
				fighter = arg_3_0,
				target = arg_3_0
			})

			arg_3_0:addBuffs({
				var_3_1
			})
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0.EnergySkill then
		if arg_4_0.summonMonster_ and not arg_4_0.summonMonster_:isDeath() then
			if arg_4_0.summonMonster_.dieCount and arg_4_0.summonMonster_.enhanceTimes then
				arg_4_0.summonMonster_.dieCount = var_0_16
				arg_4_0.summonMonster_.enhanceTimes = arg_4_0.summonMonster_.enhanceTimes + 1
				arg_4_0.summonMonster_.hpLimit_ = arg_4_0.summonMonster_:getHpLimit() * (1 + arg_4_0.summonMonster_.enhanceTimes * (var_0_21 + arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * var_0_22))

				arg_4_0.summonMonster_:updateHp(arg_4_0.summonMonster_:getHpLimit())
			end
		else
			local var_4_0 = var_0_8:summonMonster(arg_4_0.EnergySkill)

			if next(var_4_0) == nil then
				return
			end

			for iter_4_0, iter_4_1 in ipairs(var_4_0) do
				local var_4_1 = arg_4_0:getSkillLevelByID(arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))
				local var_4_2 = arg_4_0.hero_:getColor()
				local var_4_3 = arg_4_0:getX()
				local var_4_4 = arg_4_0:getY()
				local var_4_5 = {
					x = var_4_3,
					y = var_4_4
				}

				arg_4_0:setSummonMonsters(iter_4_1, var_4_1, var_4_2, var_4_5)
			end
		end

		if arg_4_0.skinSkillIndex_ == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_6 = arg_4_0:getTargets(var_0_23)
			local var_4_7 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, var_0_23)

			for iter_4_2, iter_4_3 in ipairs(var_4_7) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
				table.insert(arg_4_0.records_.special_units, iter_4_3)
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	if arg_5_4 > 0 and (arg_5_1.skillID == arg_5_0:getPugongID() or arg_5_1.skillID == arg_5_0.GreenSkill) and arg_5_1.target:isHasBuffByID(arg_5_0.LongBuffID) then
		arg_5_4 = arg_5_4 + arg_5_4 * (var_0_17 + var_0_18 * arg_5_0:getSkillLevelByID(arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy)))
	end

	if arg_5_1.target:isHasBuffByID(arg_5_0.LongBuffID) and arg_5_0.skinSkillIndex_ == 1 and arg_5_4 > 0 then
		local var_5_0 = arg_5_0:createAttackUnits({
			arg_5_0
		}, var_0_24)

		for iter_5_0, iter_5_1 in ipairs(var_5_0) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end

		local var_5_1 = arg_5_0:createAttackUnits({
			arg_5_1.target
		}, var_0_25)

		for iter_5_2, iter_5_3 in ipairs(var_5_1) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
			table.insert(arg_5_0.records_.special_units, iter_5_3)
		end
	end

	return var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	var_0_3.super.buffAddAction(arg_6_0, arg_6_1)

	if arg_6_1:getTableID() == var_0_27 then
		local var_6_0 = var_0_28 * arg_6_1.target:getAD()
		local var_6_1 = var_0_29 * arg_6_0:getAD()
		local var_6_2 = math.min(var_6_0, var_6_1)

		arg_6_1.manualRevise = -var_6_2

		local var_6_3 = arg_6_0:createNewBuffs({
			var_0_26
		}, arg_6_0, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

		for iter_6_0, iter_6_1 in ipairs(var_6_3) do
			iter_6_1.manualRevise = var_6_2
		end

		arg_6_0:addBuffs(var_6_3)
	end
end

function var_0_3.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
	if arg_7_2 > 0 and arg_7_0:isHasBuffByID(var_0_13) then
		arg_7_2 = 0
	end

	return var_0_3.super.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
end

function var_0_3.die(arg_8_0)
	if arg_8_0:isForverNeverDie() then
		return
	end

	if arg_8_0:isNeverDie() then
		local var_8_0 = arg_8_0.neverDieBuffs_[1]
		local var_8_1 = var_8_0.fighter

		if var_8_0:getTableID() == var_0_11 then
			arg_8_0:updateHp(1, false)

			local var_8_2 = var_0_5.new({
				tableID = var_0_12,
				start = var_0_1.ctx.battle.count,
				level = arg_8_0:getSkillLevelByID(arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)),
				skillID = arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
				fighter = arg_8_0,
				target = arg_8_0,
				manualHarmRevise = arg_8_0:getHpLimit() * (var_0_14 + arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_15) / 6
			})

			arg_8_0:addBuffs({
				var_8_2
			})

			local var_8_3 = arg_8_0:createNewBuffs(var_0_13, arg_8_0, arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple), arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))

			arg_8_0:addBuffs(var_8_3)

			arg_8_0.purpleBuffCount = var_0_10
			arg_8_0.isImmortal_ = true
		end

		arg_8_0:removeBuffs(var_8_0)
		var_8_1:neverDieFeedBack(arg_8_0)

		return
	end

	arg_8_0:isLeadDeal()
	arg_8_0:forceDie()
end

function var_0_3.buffRemoveAction(arg_9_0, arg_9_1)
	if arg_9_1:getTableID() == arg_9_0.blueBuffID then
		local var_9_0 = var_0_5.new({
			tableID = arg_9_0.blueselfDbuff,
			start = var_0_1.ctx.battle.count,
			level = arg_9_0:getSkillLevelByID(arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)),
			skillID = arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue),
			fighter = arg_9_0,
			target = arg_9_0
		})

		arg_9_0:addBuffs({
			var_9_0
		})
	elseif arg_9_1:getTableID() == var_0_13[1] then
		arg_9_0.isImmortal_ = false
	end
end

function var_0_3.forceDie(arg_10_0)
	if arg_10_0.summonMonster_ and not arg_10_0.summonMonster_:isDeath() then
		arg_10_0.summonMonster_:updateHp(0)
		arg_10_0.summonMonster_:die()
	end

	var_0_3.super.forceDie(arg_10_0)
end

function var_0_3.setSummonMonsters(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4)
	local var_11_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_11_0 = arg_11_0:getSummonMonster()
	else
		local var_11_1 = var_0_4.new()

		var_11_1:populateWithTableID(arg_11_1)

		var_11_1.level_ = arg_11_2 or var_11_1.level_
		var_11_1.color_ = arg_11_3 or var_11_1.color_

		for iter_11_0, iter_11_1 in ipairs(var_11_1.skillLev_) do
			local var_11_2 = arg_11_0.hero_:getSkillLevel(iter_11_0)

			if var_11_2 and var_11_2 > 0 then
				var_11_1.skillLev_[iter_11_0] = var_0_0.clone(var_11_2)
			end
		end

		local var_11_3 = var_11_1:className()

		var_11_0 = var_0_1.ctx.battle.requireFighter(var_11_3).new({
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

	var_11_0.hpLimit_ = arg_11_0:getHpLimit() * (var_0_19 + arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * var_0_20)

	var_11_0:updateHp(var_11_0:getHpLimit())

	arg_11_0.summonMonster_ = var_11_0

	local var_11_4 = var_11_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_11_4, var_11_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_11_0)
	var_0_1.ctx.battle.updateZorder()
end

return var_0_3
