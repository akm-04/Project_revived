local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yuanshu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 80000223
local var_0_8 = 80000222
local var_0_9 = 10000288
local var_0_10 = 80010073

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.room_ = nil
	arg_1_0.energyCount = nil
	arg_1_0.monsterCount_ = 0
	arg_1_0.summonMonsters_ = {}
end

function var_0_3.die(arg_2_0)
	for iter_2_0, iter_2_1 in ipairs(arg_2_0.summonMonsters_) do
		if not iter_2_1:isDeath() then
			iter_2_1:updateHp(0)
			iter_2_1:die()
		end
	end

	arg_2_0:transform2girl()
	var_0_3.super.die(arg_2_0)
end

function var_0_3.singleLoop(arg_3_0)
	var_0_3.super.singleLoop(arg_3_0)
	arg_3_0:updateState()
end

function var_0_3.getHuJia(arg_4_0)
	return var_0_3.super.getHuJia(arg_4_0) * (arg_4_0.room_ and arg_4_0.skinSkillID_ == var_0_10 and 1.2 or 1)
end

function var_0_3.getMoKang(arg_5_0)
	return var_0_3.super.getMoKang(arg_5_0) * (arg_5_0.room_ and arg_5_0.skinSkillID_ == var_0_10 and 1.2 or 1)
end

function var_0_3.updateState(arg_6_0)
	if not arg_6_0.room_ or arg_6_0:isDeath() then
		return
	end

	local var_6_0 = false

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
		if not iter_6_1:isDeath() or iter_6_1:canReborn() then
			var_6_0 = true
		end
	end

	if not var_6_0 then
		arg_6_0:transform2girl()

		return
	end

	if arg_6_0:acttionInBlack() and arg_6_0.energyCount then
		arg_6_0.energyCount = arg_6_0.energyCount + 1

		local var_6_1 = arg_6_0.skinSkillID_ == var_0_10 and 60 or 40

		if arg_6_0.energyCount % math.floor(2400 / var_6_1) < 1 and arg_6_0:getEnergy() > 0 then
			arg_6_0.monsterCount_ = arg_6_0.monsterCount_ + 1

			local var_6_2 = arg_6_0.monsterCount_ % 4 < 1 and var_0_7 or var_0_8
			local var_6_3 = {
				x = arg_6_0:getX(),
				y = arg_6_0:getY() - arg_6_0.monsterCount_
			}

			arg_6_0:setSummonMonsters(var_6_2, arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy), arg_6_0.hero_:getColor(), var_6_3)
		end

		if arg_6_0.energyCount % 30 < 1 then
			arg_6_0:updateEnergyBy(-var_6_1)

			if arg_6_0:getEnergy() < 1 then
				arg_6_0:transform2girl()
			end
		end
	end
end

function var_0_3.canAttack(arg_7_0)
	if arg_7_0.room_ then
		return false
	end

	return var_0_3.super.canAttack(arg_7_0)
end

function var_0_3.checkEnergySkill(arg_8_0)
	if arg_8_0.room_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_8_0)
end

function var_0_3.playAttack(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_1 == var_0_6:attackIndex(arg_9_0:getEnergySkillID()) then
		var_0_3.super.playAttack(arg_9_0, arg_9_1, function()
			arg_9_0:x(arg_9_0:getX())
			arg_9_0:y(arg_9_0:getY())
			arg_9_0:getFighterModel():playAnimation_("gongji05", true, nil, nil, nil, false)

			if arg_9_2 then
				arg_9_2()
			end
		end)
	else
		var_0_3.super.playAttack(arg_9_0, arg_9_1, arg_9_2)
	end
end

function var_0_3.applySingleUnit(arg_11_0, arg_11_1)
	var_0_3.super.applySingleUnit(arg_11_0, arg_11_1)

	if arg_11_1.skillID == arg_11_0:getEnergySkillID() then
		arg_11_0.room_ = true
		arg_11_0.energyCount = 20
	end
end

function var_0_3.transform2girl(arg_12_0)
	if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
		arg_12_0.room_ = nil
		arg_12_0.energyCount = nil
		arg_12_0.monsterCount_ = 0

		return
	end

	arg_12_0:getFighterModel():resume()

	local var_12_0 = var_0_9
	local var_12_1 = var_0_6:sound(var_12_0)

	var_0_1.ctx.battle.pushSoundQueue(var_12_1)

	local var_12_2 = var_0_6:attackIndex(var_12_0)

	arg_12_0:playAttack(var_12_2)

	arg_12_0.unitSkills_ = var_0_5.new({
		fighter = arg_12_0,
		skillID = var_12_0
	})

	arg_12_0:beginAttackEnd(arg_12_0.unitSkills_)

	arg_12_0.room_ = nil
	arg_12_0.energyCount = nil
	arg_12_0.monsterCount_ = 0
end

function var_0_3.setSummonMonsters(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4)
	local var_13_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_13_0 = arg_13_0:getSummonMonster()

		if not var_13_0 then
			return
		end
	else
		local var_13_1 = var_0_4.new()

		var_13_1:populateWithTableID(arg_13_1)

		var_13_1.level_ = arg_13_2 or var_13_1.level_
		var_13_1.color_ = arg_13_3 or var_13_1.color_

		for iter_13_0, iter_13_1 in ipairs(var_13_1.skillLev_) do
			var_13_1.skillLev_[iter_13_0] = arg_13_0.hero_.skillLev_[iter_13_0]
		end

		local var_13_2 = var_13_1:className()

		var_13_0 = var_0_1.ctx.battle.requireFighter(var_13_2).new({
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

	var_13_0.fighterModel:pos(arg_13_4.x, arg_13_4.y - #arg_13_0.summonMonsters_)
	var_13_0:updateHp(var_13_0:getHpLimit())
	var_13_0:getFighterModel():flipX(arg_13_0:getTeamType() == var_0_2.TeamType.B)
	var_13_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_13_0:born()
	var_13_0:setGlobalBuffs()

	local var_13_3 = var_13_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_13_3, var_13_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_13_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_13_0.summonMonsters_, var_13_0)
end

function var_0_3.getHurtMP(arg_14_0)
	if arg_14_0.room_ then
		return 0
	end

	return var_0_3.super.getHurtMP(arg_14_0)
end

function var_0_3.addBuffs(arg_15_0, arg_15_1)
	if not arg_15_0.room_ then
		var_0_3.super.addBuffs(arg_15_0, arg_15_1)

		return
	end

	local var_15_0 = {}

	for iter_15_0, iter_15_1 in ipairs(arg_15_1) do
		if not iter_15_1:isFear() and not iter_15_1:isApUnable() and not iter_15_1:isAdUnable() and not iter_15_1:isExcuteAdCircle() and not iter_15_1:isAttackFriend() then
			table.insert(var_15_0, iter_15_1)
		end
	end

	var_0_3.super.addBuffs(arg_15_0, var_15_0)
end

function var_0_3.getDMP(arg_16_0)
	return var_0_2.PERCENT_BASE
end

function var_0_3.isMoveUnable(arg_17_0)
	if arg_17_0.room_ then
		return true
	end

	return var_0_3.super.isMoveUnable(arg_17_0)
end

function var_0_3.isBreakImmortal(arg_18_0)
	if arg_18_0.room_ then
		return true
	end

	return false
end

return var_0_3
