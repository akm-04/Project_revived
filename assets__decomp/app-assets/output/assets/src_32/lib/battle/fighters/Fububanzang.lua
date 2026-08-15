local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fububanzang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 20010184
local var_0_8 = math
local var_0_9 = 0
local var_0_10 = 1
local var_0_11 = 750

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.seed_ = 0
	arg_1_0.baojiCount_ = 0
	arg_1_0.summonMonsters_ = {}
	arg_1_0.summonMonster_ = nil
	arg_1_0.cdTime_ = 0
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)

	arg_2_0.cdTime_ = arg_2_0.cdTime_ > 0 and arg_2_0.cdTime_ - 1 or 0
end

function var_0_3.die(arg_3_0)
	if arg_3_0.summonMonster_ and arg_3_0.summonMonster_:isDeath() ~= true then
		arg_3_0.summonMonster_:updateHp(0)
		arg_3_0.summonMonster_:die()
	end

	var_0_3.super.die(arg_3_0)
end

function var_0_3.deathFeedback(arg_4_0, arg_4_1)
	if arg_4_1:getTeamType() ~= arg_4_0:getTeamType() and arg_4_1:getSummonType() == var_0_2.summonMonsterType.None then
		arg_4_0.cdTime_ = 0
	end
end

function var_0_3.buffRemoveAction(arg_5_0, arg_5_1)
	if arg_5_1:getRemoveSkill() < 1 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_5_0 = arg_5_1:getRemoveSkill()
	local var_5_1 = var_0_6:randomOrb(var_5_0)

	if next(var_5_1) == nil or not arg_5_1.target.killer_ then
		return
	end

	local var_5_2 = os.clock() * 1000 + arg_5_0.seed_ * 1000

	arg_5_0.seed_ = arg_5_0.seed_ + 1

	var_0_8.randomseed(var_5_2)

	local var_5_3 = var_5_1[var_0_8.random(#var_5_1)]
	local var_5_4 = {
		arg_5_1.target.killer_
	}
	local var_5_5 = arg_5_0:createAttackUnits(var_5_4, var_5_3)

	for iter_5_0, iter_5_1 in ipairs(var_5_5) do
		table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
		table.insert(arg_5_0.records_.special_units, iter_5_1)
	end
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		if not arg_6_3 then
			arg_6_0.baojiCount_ = arg_6_0.baojiCount_ + 1
		else
			arg_6_0.baojiCount_ = 0
		end
	end

	if arg_6_1.target:isHasBuffByID(var_0_7) and arg_6_4 > 0 then
		arg_6_4 = arg_6_4 * 2
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.selectTargetByTypeD1(arg_7_0, arg_7_1, arg_7_2)
	if not arg_7_2 then
		return var_0_4.B1(arg_7_0, arg_7_1)
	end

	if not arg_7_2.targets_ or not next(arg_7_2.targets_) then
		return
	end

	local var_7_0 = arg_7_2.targets_
	local var_7_1, var_7_2 = var_0_4.getTeam(arg_7_0)
	local var_7_3, var_7_4 = var_7_0[#var_7_0]:getPos()
	local var_7_5
	local var_7_6

	for iter_7_0, iter_7_1 in ipairs(var_7_2) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and iter_7_1:isHasBuffByID(var_0_7) then
			local var_7_7, var_7_8 = iter_7_1:getPos()
			local var_7_9 = var_0_8.abs(var_7_3 - var_7_7)

			if (not var_7_5 or var_7_9 < var_7_5) and not arg_7_2.recordTargets_[iter_7_1.fighterIndex] then
				var_7_5 = var_7_9
				var_7_6 = iter_7_1
			end
		end
	end

	local var_7_10 = {}

	if var_7_6 then
		var_7_10 = {
			var_7_6
		}
	end

	return var_7_10
end

function var_0_3.getADBaoJi(arg_8_0)
	local var_8_0 = var_0_3.super.getADBaoJi(arg_8_0)
	local var_8_1 = arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

	if var_8_1 > 0 and arg_8_0.baojiCount_ > 0 then
		return var_8_0 + (var_8_1 * var_0_10 + var_0_9) * arg_8_0.baojiCount_
	end

	return var_8_0
end

function var_0_3.dodge(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	if var_0_6:type(arg_9_1.skillID) == var_0_2.AttackType.CURE or arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 then
		return
	end

	if (not arg_9_0.summonMonster_ or arg_9_0.summonMonster_:isDeath()) and arg_9_0.cdTime_ < 1 then
		local var_9_0 = arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_9_1 = var_0_6:summonMonster(var_9_0)

		if next(var_9_1) == nil then
			return false
		end

		arg_9_0.cdTime_ = var_0_11

		local var_9_2 = arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
		local var_9_3 = arg_9_0.hero_:getColor()
		local var_9_4 = arg_9_0:getFlipX() and -10 or 10
		local var_9_5 = arg_9_0:getX() + var_9_4
		local var_9_6 = {
			x = var_9_5,
			y = arg_9_0:getY() + 0.1
		}
		local var_9_7 = arg_9_0:getFlipX() and 120 or -120
		local var_9_8 = var_0_1.ctx.battle.adjustX(arg_9_0:getX() + var_9_7, arg_9_0)

		arg_9_0:x(var_9_8)

		for iter_9_0, iter_9_1 in ipairs(var_9_1) do
			arg_9_0:setSummonMonsters(iter_9_1, var_9_2, var_9_3, var_9_6)
		end

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			return true
		end

		local var_9_9 = {
			arg_9_0.summonMonster_
		}
		local var_9_10 = arg_9_0:createAttackUnits(var_9_9, arg_9_1.skillID)

		for iter_9_2, iter_9_3 in ipairs(var_9_10) do
			iter_9_3:clearCollisionNum()
			table.insert(arg_9_0.moveAttackUnits_, iter_9_3)
			table.insert(arg_9_0.records_.special_units, iter_9_3)
		end

		arg_9_1.records_.doge = true

		return true
	end

	return false
end

function var_0_3.setSummonMonsters(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4)
	local var_10_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_10_0 = arg_10_0:getSummonMonster()
	else
		local var_10_1 = var_0_5.new()

		var_10_1:populateWithTableID(arg_10_1)

		var_10_1.level_ = arg_10_2 or var_10_1.level_
		var_10_1.color_ = arg_10_3 or var_10_1.color_

		for iter_10_0, iter_10_1 in ipairs(var_10_1.skillLev_) do
			var_10_1.skillLev_[iter_10_0] = arg_10_2
		end

		local var_10_2 = var_10_1:className()

		var_10_0 = var_0_1.ctx.battle.requireFighter(var_10_2).new({
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
	var_10_0:updateHp(var_10_0:getHpLimit())
	var_10_0:getFighterModel():flipX(arg_10_0:getTeamType() == var_0_2.TeamType.B)
	var_10_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_10_0:born()
	var_10_0:setGlobalBuffs()

	local var_10_3 = var_10_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_10_3, var_10_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_10_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_10_0.summonMonsters_, var_10_0)

	if var_10_0.summonType_ == var_0_2.summonMonsterType.Monster then
		if arg_10_0.summonMonster_ then
			arg_10_0.summonMonster_:updateHp(0)
			arg_10_0.summonMonster_:die()
			var_0_0.table.removebyvalue(arg_10_0.summonMonsters_, arg_10_0.summonMonster_)
		end

		arg_10_0.summonMonster_ = var_10_0
	end
end

return var_0_3
