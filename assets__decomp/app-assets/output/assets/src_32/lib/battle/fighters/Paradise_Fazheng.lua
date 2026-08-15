local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ParadiseFazheng", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = var_0_1.ctx.battle.getRequire("SkillEffect")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = var_0_2.tables.hero
local var_0_10 = var_0_2.tables.model
local var_0_11 = {
	40010224,
	40010225
}
local var_0_12 = 80033003
local var_0_13 = 20000

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.xuliSkill_ = nil
	arg_1_0.xuliCount_ = 0
end

function var_0_3.newFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	local var_2_0 = arg_2_1:className()
	local var_2_1 = var_0_1.ctx.battle.requireFighter(var_2_0).new({
		is_arena = arg_2_0.isInArena_
	})

	var_2_1:populateWithHero(arg_2_1)
	var_2_1:setTeamType(arg_2_2)
	var_2_1:initModels()
	var_2_1.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_2_1:getFighterModel():idle()

	local var_2_2 = arg_2_2 - 1

	var_2_1.fighterModel:initHeaderView(var_2_2)
	var_2_1:getFighterModel():flipX(arg_2_3)

	return var_2_1
end

function var_0_3.newBuff(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local var_3_0 = {}

	for iter_3_0, iter_3_1 in ipairs(arg_3_1) do
		local var_3_1 = var_0_6.new({
			tableID = iter_3_1,
			start = var_0_1.ctx.battle.count,
			level = arg_3_0:getSkillLevelByID(arg_3_3),
			skillID = arg_3_3,
			fighter = arg_3_0,
			target = arg_3_2
		})

		var_3_1:setIsHit(true)
		var_3_1:setDirection(arg_3_2:getFighterModel():getFlipX())
		table.insert(var_3_0, var_3_1)
	end

	return var_3_0
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_4_0 = arg_4_1.target
		local var_4_1 = var_4_0.hero_:toParams()
		local var_4_2 = var_4_0:getX() - 100
		local var_4_3 = var_4_0:getY()
		local var_4_4

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			local var_4_5 = "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

			var_4_4 = var_0_1.ctx.battle.summonMonsters[var_4_5]

			var_4_4:setTeamType(arg_4_0:getTeamType())
			var_4_4.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
		else
			local var_4_6 = var_0_5.new()

			var_4_6:populate(var_4_1)

			var_4_4 = arg_4_0:newFighter(var_4_6, arg_4_0:getTeamType(), false)

			local var_4_7 = #arg_4_0.selfTeam_ + 1

			var_4_4.fighterIndex = "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

			var_4_4:setFormationDelay(var_0_2.tables.battleConfig.skillDelayQueue[var_4_7], var_0_2.tables.battleConfig.formationWalkQueue[var_4_7])
		end

		var_4_4.fighterModel:pos(var_4_2, var_4_3)
		var_4_4:setupBattleAttrInfo()
		var_4_4:setGlobalBuffs()
		var_4_4:resetHpLimit(var_0_13)

		var_4_4.summonType_ = var_0_2.summonMonsterType.Copy

		if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
			var_4_4:getFighterModel():setMaskColor(cc.c4f(1, 0.88, 0.46, 1))
			var_4_4:setDefaultMaskColor(cc.c4f(1, 0.88, 0.46, 1))
		end

		var_4_4:addBuffs(arg_4_0:newBuff(var_0_11, var_4_4, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)))
		table.insert(arg_4_0.selfTeam_, var_4_4)
	elseif arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_4_8 = var_0_8:scope(arg_4_1.skillID) * 0.5
		local var_4_9 = var_0_9:heroType(arg_4_1.target:getTableID())
		local var_4_10 = {}

		for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
			if not iter_4_1:isDeath() and not iter_4_1:isAffected() and var_4_8 >= math.abs(iter_4_1:getX() - arg_4_1.target:getX()) and iter_4_1 ~= arg_4_1.target then
				if var_0_9:heroType(iter_4_1:getTableID()) ~= var_4_9 then
					iter_4_1:updateHp(0)
					iter_4_1:die()
				else
					table.insert(var_4_10, iter_4_1)
				end
			end
		end

		if next(var_4_10) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_11 = arg_4_0:createAttackUnits(var_4_10, var_0_12)

			for iter_4_2, iter_4_3 in ipairs(var_4_11) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
				table.insert(arg_4_0.records_.special_units, iter_4_3)
			end
		end
	end
end

function var_0_3.updateBaseInfo(arg_5_0)
	var_0_3.super.updateBaseInfo(arg_5_0)

	arg_5_0.xuliCount_ = arg_5_0.xuliCount_ > 0 and arg_5_0.xuliCount_ + 1 or 0
end

function var_0_3.createAttacks(arg_6_0)
	local var_6_0 = arg_6_0.unitSkills_

	if not var_6_0 then
		return
	end

	if var_6_0:isEmptyQueue() then
		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			table.remove(arg_6_0.reportSkills_, 1)
		end

		arg_6_0.unitSkills_ = nil

		return
	end

	local var_6_1, var_6_2 = var_6_0:getFront()

	while var_6_1 and var_6_1 < 1 do
		if var_6_2 == arg_6_0:getEnergySkillID() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			arg_6_0:specialAttack()
		else
			arg_6_0:createUnits()
		end

		var_6_0:popQueue()

		var_6_1, var_6_2 = var_6_0:getFront()

		if not arg_6_0:isCreatingUnits() then
			arg_6_0.unitSkills_ = nil

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				table.remove(arg_6_0.reportSkills_, 1)
			end

			arg_6_0:updateEnergyBy(var_6_0:getRemp())
			arg_6_0:popFrontSkill()
		end
	end
end

function var_0_3.specialAttack(arg_7_0)
	if arg_7_0:isDeath() or not arg_7_0.xuliSkill_ then
		arg_7_0.xuliSkill_ = nil

		return
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_7_0.xuliSkill_ = nil

	local var_7_0 = var_0_8:xuliChild(arg_7_0:getEnergySkillID())
	local var_7_1 = var_0_8:sound(var_7_0)

	var_0_1.ctx.battle.pushSoundQueue(var_7_1)

	local var_7_2 = var_0_8:attackIndex(var_7_0)

	arg_7_0:playAttack(var_7_2)

	arg_7_0.unitSkills_ = var_0_4.new({
		fighter = arg_7_0,
		skillID = var_7_0
	})

	if arg_7_0:getTeamType() == var_0_2.TeamType.A and arg_7_0.bottomWnd then
		arg_7_0.bottomWnd:setXuliSkillEffect(arg_7_0, var_0_1.ctx.battle.teamA, false)
	end

	local var_7_3
	local var_7_4, var_7_5 = var_0_8:areaResource(var_7_0)

	if var_7_4 and var_7_4 ~= "" and var_7_5 and var_7_5 ~= "" then
		var_7_3 = var_0_1.ctx.battle.getSpine(var_7_0, "area", arg_7_0:getScale())
	end

	if var_7_3 then
		var_7_3:addTo(var_0_1.ctx.battle.unitLayer)
		var_7_3:pos(arg_7_0:getX(), arg_7_0:getY())
		var_7_3:playOnce()
		var_7_3:flipX(arg_7_0:getFlipX())
	end

	arg_7_0:beginAttackEnd(arg_7_0.unitSkills_)
end

function var_0_3.beginAttack(arg_8_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_8_0 = arg_8_0.reportSkills_[1]

		if not var_8_0 or var_0_1.ctx.battle.count ~= var_8_0.startCount_ then
			if arg_8_0.reportSkills_[2] and arg_8_0.reportSkills_[2].startCount_ == var_0_1.ctx.battle.count then
				table.remove(arg_8_0.reportSkills_, 1)
			else
				return
			end
		end
	elseif not arg_8_0:canAttack() then
		return
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		if arg_8_0.reportSkills_[1].rootID_ == arg_8_0:getEnergySkillID() then
			arg_8_0.xuliSkill_ = true
			arg_8_0.xuliCount_ = 1

			if arg_8_0:getTeamType() == var_0_2.TeamType.A and arg_8_0.bottomWnd then
				arg_8_0.bottomWnd:setXuliSkillEffect(arg_8_0, var_0_1.ctx.battle.teamA, true)
			end
		end
	elseif arg_8_0:getFrontSkill() == arg_8_0:getEnergySkillID() then
		arg_8_0.xuliSkill_ = true
		arg_8_0.xuliCount_ = 1

		if arg_8_0:getTeamType() == var_0_2.TeamType.A and arg_8_0.bottomWnd then
			arg_8_0.bottomWnd:setXuliSkillEffect(arg_8_0, var_0_1.ctx.battle.teamA, true)
		end
	end

	var_0_3.super.beginAttack(arg_8_0)
end

function var_0_3.beginAttackEnd(arg_9_0, arg_9_1)
	var_0_3.super.beginAttackEnd(arg_9_0, arg_9_1)

	if arg_9_1.rootID_ == var_0_8:xuliChild(arg_9_0:getEnergySkillID()) and var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_9_0 = arg_9_1.rootID_

		if arg_9_0:getTeamType() == var_0_2.TeamType.A and arg_9_0.bottomWnd then
			arg_9_0.bottomWnd:setXuliSkillEffect(arg_9_0, var_0_1.ctx.battle.teamA, false)
		end

		local var_9_1
		local var_9_2, var_9_3 = var_0_8:areaResource(var_9_0)

		if var_9_2 and var_9_2 ~= "" and var_9_3 and var_9_3 ~= "" then
			var_9_1 = var_0_1.ctx.battle.getSpine(var_9_0, "area", arg_9_0:getScale())
		end

		if var_9_1 then
			var_9_1:addTo(var_0_1.ctx.battle.unitLayer)
			var_9_1:pos(arg_9_0:getX(), arg_9_0:getY())
			var_9_1:playOnce()
			var_9_1:flipX(arg_9_0:getFlipX())
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7 = var_0_3.super.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)

	if arg_10_1.skillID == var_0_8:xuliChild(arg_10_0:getEnergySkillID()) and var_0_8:pretime(arg_10_0:getEnergySkillID()) > 0 then
		local var_10_0 = var_0_8:pretime(arg_10_0:getEnergySkillID()) + var_0_8:pretime(var_0_8:xuliChild(arg_10_0:getEnergySkillID())) + 1

		arg_10_4 = arg_10_4 * math.min(arg_10_0.xuliCount_ * arg_10_0.xuliCount_ / (var_10_0 * var_10_0), 1)
		arg_10_0.xuliSkill_ = nil
	end

	return arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7
end

function var_0_3.checkSkillBreak(arg_11_0, arg_11_1, arg_11_2)
	if arg_11_1 == var_0_2.BreakSkillType.AP then
		if arg_11_0:getCurrentSkillType() == var_0_2.AttackType.AP or arg_11_0:getCurrentSkillType() == var_0_2.AttackType.CURE then
			if arg_11_0:isCreatingUnits() then
				arg_11_0.fighterModel:playFloatText({
					var_0_2.BattleFloatType.BREAK
				}, arg_11_0:getTeamType())
				arg_11_0:skillIsBreak(arg_11_2)

				if arg_11_0.xuliSkill_ then
					arg_11_0:specialAttack()
				end
			end

			arg_11_0.isEnergySkill_ = false
		end
	elseif arg_11_1 == var_0_2.BreakSkillType.AD then
		if arg_11_0:isAdBreakImmortal() then
			return
		end

		arg_11_0:setBreakInterval()

		if not arg_11_0:isPause() then
			arg_11_0:attacked()
		end

		if arg_11_0:getCurrentSkillType() == var_0_2.AttackType.AD then
			if arg_11_0:isCreatingUnits() then
				arg_11_0.fighterModel:playFloatText({
					var_0_2.BattleFloatType.BREAK
				}, arg_11_0:getTeamType())
				arg_11_0:skillIsBreak(arg_11_2)
			end

			arg_11_0.isEnergySkill_ = false
		end
	end
end

function var_0_3.addBlackLayer(arg_12_0)
	local var_12_0 = var_0_0.clone(var_0_1.ctx.battle.isEnergySkilling or 0)

	var_0_3.super.addBlackLayer(arg_12_0)

	var_0_1.ctx.battle.isEnergySkilling = math.max(var_12_0, 10)
end

function var_0_3.checkReHpMp(arg_13_0)
	var_0_3.super.checkReHpMp(arg_13_0)

	arg_13_0.xuliSkill_ = nil

	if arg_13_0:getTeamType() == var_0_2.TeamType.A and arg_13_0.bottomWnd then
		arg_13_0.bottomWnd:setXuliSkillEffect(arg_13_0, var_0_1.ctx.battle.teamA, false)
	end
end

function var_0_3.die(arg_14_0)
	arg_14_0.xuliSkill_ = nil

	if arg_14_0:getTeamType() == var_0_2.TeamType.A and arg_14_0.bottomWnd then
		arg_14_0.bottomWnd:setXuliSkillEffect(arg_14_0, var_0_1.ctx.battle.teamA, false)
	end

	var_0_3.super.die(arg_14_0)
end

function var_0_3.selectTargetByTypeD1(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = {}

	for iter_15_0, iter_15_1 in ipairs(arg_15_0.sideTeam_) do
		if not iter_15_1:isDeath() and not iter_15_1:isAffected() and iter_15_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_15_0, iter_15_1)
		end
	end

	local var_15_1

	if next(var_15_0) then
		var_15_1 = var_15_0[math.random(1, #var_15_0)]
	end

	return {
		var_15_1
	}
end

function var_0_3.isHurtBreak(arg_16_0, arg_16_1, arg_16_2)
	return false
end

return var_0_3
