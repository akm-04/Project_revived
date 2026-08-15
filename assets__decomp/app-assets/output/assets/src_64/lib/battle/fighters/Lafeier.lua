local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Lafeier", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = 40010932
local var_0_7 = 40010944
local var_0_8 = {
	40010939,
	40010940,
	40010941,
	40010942,
	40010943
}
local var_0_9 = 40010945
local var_0_10 = 10000872
local var_0_11 = 0.006
local var_0_12 = 0.2
local var_0_13 = 11004

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.greenTargets_ = {}
	arg_1_0.isPurpleAddBuffs_ = false
	arg_1_0.energyTarget_ = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	for iter_2_0 = #arg_2_0.greenTargets_, 1, -1 do
		local var_2_0 = arg_2_0.greenTargets_[iter_2_0].target
		local var_2_1 = arg_2_0.greenTargets_[iter_2_0].mirrow

		if var_2_1:isDeath() or not var_2_1:isHasBuffByID(var_0_6) then
			var_2_0:removeBuffByID(var_0_7)
			table.remove(arg_2_0.greenTargets_, iter_2_0)
		end
	end

	if next(arg_2_0.energyTarget_) and arg_2_0.energyTarget_.mirrow:isDeath() and arg_2_0.energyTarget_.target then
		arg_2_0.energyTarget_.target:removeBuffByID(var_0_9)

		arg_2_0.energyTarget_ = {}
	end

	arg_2_0:checkDeath()

	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and not arg_2_0.isPurpleAddBuffs_ then
		arg_2_0.isPurpleAddBuffs_ = true

		for iter_2_1, iter_2_2 in ipairs(arg_2_0.selfTeam_) do
			if not iter_2_2:isDeath() and not iter_2_2:isAffected() then
				local var_2_2 = arg_2_0:newBuff(var_0_8, iter_2_2, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				iter_2_2:addBuffs(var_2_2)
			end
		end
	end
end

function var_0_3.checkDeath(arg_3_0)
	if not next(arg_3_0.energyTarget_) and not next(arg_3_0.greenTargets_) then
		return
	end

	local var_3_0 = false
	local var_3_1 = 0

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1:getSummonType() == var_0_2.summonMonsterType.None then
			var_3_1 = var_3_1 + 1
		end
	end

	if var_3_1 < 1 then
		var_3_0 = true
	end

	if not var_3_0 then
		local var_3_2 = 0

		for iter_3_2, iter_3_3 in ipairs(arg_3_0.selfTeam_) do
			if (not iter_3_3:isDeath() or iter_3_3:canReborn()) and iter_3_3:getSummonType() == var_0_2.summonMonsterType.None then
				var_3_2 = var_3_2 + 1
			end
		end

		if var_3_2 < 1 then
			var_3_0 = true
		end
	end

	if var_3_0 then
		if next(arg_3_0.energyTarget_) and arg_3_0.energyTarget_.target then
			arg_3_0.energyTarget_.mirrow:updateHp(0)
			arg_3_0.energyTarget_.mirrow:forceDie()
			arg_3_0.energyTarget_.target:removeBuffByID(var_0_9)

			arg_3_0.energyTarget_ = {}
		end

		for iter_3_4 = #arg_3_0.greenTargets_, 1, -1 do
			local var_3_3 = arg_3_0.greenTargets_[iter_3_4].target
			local var_3_4 = arg_3_0.greenTargets_[iter_3_4].mirrow

			var_3_4:updateHp(0)
			var_3_4:forceDie()
			var_3_3:removeBuffByID(var_0_7)
		end

		arg_3_0.greenTargets_ = {}
	end
end

function var_0_3.buffRemoveAction(arg_4_0, arg_4_1)
	var_0_3.super.buffRemoveAction(arg_4_0, arg_4_1)

	if arg_4_1:getTableID() == var_0_6 then
		arg_4_1.target:updateHp(0)
		arg_4_1.target:forceDie()
	elseif arg_4_1:getTableID() == var_0_9 then
		if next(arg_4_0.energyTarget_) and not arg_4_0.energyTarget_.mirrow:isDeath() then
			arg_4_0.energyTarget_.mirrow:updateHp(0)
			arg_4_0.energyTarget_.mirrow:forceDie()
		end

		arg_4_0.energyTarget_ = {}

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_0 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, var_0_10)

			for iter_4_0, iter_4_1 in ipairs(var_4_0) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end
	end

	if arg_4_0.isSkinSkillOn_ then
		local var_4_1 = arg_4_1:getTableID()
		local var_4_2 = arg_4_1.target

		if var_4_2:isDeath() then
			return
		end

		if var_4_1 == var_0_9 or var_4_1 == var_0_7 then
			local var_4_3 = math.min(var_4_2:getHp() * 0.1, arg_4_0:getHpLimit() * 5)

			var_4_2:updateHp(var_4_2:getHp() - var_4_3)
		end
	end
end

function var_0_3.setSummonMonsters(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = arg_5_0:getSkillLevelByID(arg_5_2)
	local var_5_1

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_5_1 = arg_5_0:getSummonMonster()
	else
		local var_5_2 = var_0_4.new()
		local var_5_3 = arg_5_1.hero_:toParams()

		var_5_2:populate(var_5_3)

		var_5_2.level_ = var_5_0 < 100 and var_5_0 or 100

		local var_5_4 = var_5_2:className()

		var_5_1 = var_0_1.ctx.battle.requireFighter(var_5_4).new({
			is_arena = arg_5_0.isInArena_
		})

		var_5_1:populateWithHero(var_5_2)

		for iter_5_0, iter_5_1 in pairs(var_5_1.skillLevelByID_) do
			var_5_1.skillLevelByID_[iter_5_0] = var_5_0
		end

		for iter_5_2, iter_5_3 in pairs(var_5_1.skillLevelByColor_) do
			if var_5_1.hero_:getSkillId(iter_5_2) > 0 then
				var_5_1.skillLevelByColor_[iter_5_2] = var_5_0
			end
		end

		var_5_1:initModels()
		var_5_1.fighterModel:initHeaderView(arg_5_0:getTeamType() - 1)

		var_5_1.fighterIndex = arg_5_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_5_1:setFormationDelay(0, 100)

		var_5_1.startSkillQueue_ = {}
		var_5_1.skillQueue_ = arg_5_1.skillQueue_

		if arg_5_3 then
			var_5_1:updateEnergyTo(arg_5_1:getEnergy())
		end
	end

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		var_5_1:getFighterModel():setMaskColor(cc.c4f(1, 0.88, 0.46, 1))
		var_5_1:setDefaultMaskColor(cc.c4f(1, 0.88, 0.46, 1))
	end

	var_5_1.summonType_ = var_0_2.summonMonsterType.Copy

	var_5_1:setSummonAutoFight(true)

	var_5_1.hasReborn_ = true

	var_5_1:setTeamType(arg_5_0:getTeamType())

	var_5_1.summoner = arg_5_0

	var_5_1.fighterModel:pos(arg_5_1:getPos())
	var_5_1:getFighterModel():flipX(arg_5_1:getFlipX())
	var_5_1.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_5_1:born()
	var_5_1:setGlobalBuffs()

	local var_5_5 = arg_5_1:getHp() * (var_5_0 * var_0_11 + var_0_12)

	var_5_1:resetHpLimit(var_5_5)
	var_5_1:updateHp(var_5_1:getHpLimit())

	local var_5_6 = var_5_1:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_5_6, var_5_1)
	table.insert(var_0_1.ctx.battle.yOrder, var_5_1)
	var_0_1.ctx.battle.updateZorder()

	return var_5_1
end

function var_0_3.selectTargetByTypeD1(arg_6_0)
	local var_6_0 = {}
	local var_6_1 = 0

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1:getSummonType() == var_0_2.summonMonsterType.None and var_6_1 <= iter_6_1:getCurrentAckSpeed() then
			if iter_6_1:getCurrentAckSpeed() == var_6_1 then
				table.insert(var_6_0, iter_6_1)
			else
				var_6_0 = {}

				table.insert(var_6_0, iter_6_1)

				var_6_1 = iter_6_1:getCurrentAckSpeed()
			end
		end
	end

	if not next(var_6_0) then
		return {}
	end

	local var_6_2 = var_6_0[math.random(1, #var_6_0)]

	return {
		var_6_2
	}
end

function var_0_3.selectTargetByTypeD2(arg_7_0)
	local var_7_0
	local var_7_1

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
		if iter_7_1:getTableID() ~= var_0_13 and not iter_7_1:isDeath() and not iter_7_1:isAffected() and iter_7_1:getSummonType() == var_0_2.summonMonsterType.None and not iter_7_1:isBoss() and (not var_7_1 or var_7_1 < iter_7_1.harms) then
			var_7_0 = iter_7_1
			var_7_1 = iter_7_1.harms
		end
	end

	return {
		var_7_0
	}
end

function var_0_3.checkEnergySkill(arg_8_0)
	if next(arg_8_0.greenTargets_) then
		return false
	elseif next(arg_8_0.energyTarget_) then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_8_0)
end

function var_0_3.newBuff(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_1) do
		local var_9_1 = var_0_5.new({
			tableID = iter_9_1,
			start = var_0_1.ctx.battle.count,
			level = arg_9_0:getSkillLevelByID(arg_9_3),
			skillID = arg_9_3,
			fighter = arg_9_0,
			target = arg_9_2
		})

		var_9_1:setIsHit(true)
		var_9_1:setDirection(arg_9_0:getFighterModel():getFlipX())
		table.insert(var_9_0, var_9_1)
	end

	return var_9_0
end

function var_0_3.buffAddAction(arg_10_0, arg_10_1)
	var_0_3.super.buffAddAction(arg_10_0, arg_10_1)

	if arg_10_1:getTableID() == var_0_7 then
		local var_10_0 = arg_10_0:setSummonMonsters(arg_10_1.target, arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Green), false)
		local var_10_1 = arg_10_0:newBuff({
			var_0_6
		}, var_10_0, arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))

		var_10_0:addBuffs(var_10_1)
		table.insert(arg_10_0.greenTargets_, {
			target = arg_10_1.target,
			mirrow = var_10_0
		})
	elseif arg_10_1:getTableID() == var_0_9 then
		local var_10_2 = arg_10_0:setSummonMonsters(arg_10_1.target, arg_10_0:getEnergySkillID(), true)

		arg_10_0.energyTarget_ = {
			target = arg_10_1.target,
			mirrow = var_10_2
		}
	end
end

return var_0_3
