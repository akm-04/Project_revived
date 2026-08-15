local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fazheng", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = 90030012
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("SkillEffect")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.hero
local var_0_9 = var_0_2.tables.model

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	local var_1_0 = arg_1_1.target

	if arg_1_1.skillID == var_0_4 then
		local var_1_1 = 1

		var_1_0:updateHp(var_1_1)
	end
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.xuliSkill_ = nil
	arg_2_0.xuliCount_ = 0
end

function var_0_3.singleLoop(arg_3_0)
	arg_3_0:updateBaseInfo()
	arg_3_0:checkMove()

	if not arg_3_0:isDeath() then
		arg_3_0:createAttacks()
	end

	arg_3_0:beginAttack()

	if arg_3_0:acttionInBlack() then
		arg_3_0:applyUnitMoves()
		arg_3_0:applyUnitHarms()
		arg_3_0:applyBuffHarms()

		arg_3_0.xuliCount_ = arg_3_0.xuliCount_ > 0 and arg_3_0.xuliCount_ + 1 or 0
	end

	arg_3_0:applyBuffMoves()

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType and arg_3_0.reportDieCount_ > 0 and var_0_1.ctx.battle.count > arg_3_0.reportDieCount_ and arg_3_0.isDead_ ~= true then
		arg_3_0:updateHp(0)
		arg_3_0:die()
	end
end

function var_0_3.createAttacks(arg_4_0)
	local var_4_0 = arg_4_0.unitSkills_

	if not var_4_0 then
		return
	end

	if var_4_0:isEmptyQueue() then
		arg_4_0.unitSkills_ = nil

		return
	end

	local var_4_1, var_4_2 = var_4_0:getFront()

	while var_4_1 and var_4_1 < 1 do
		if var_4_2 == arg_4_0:getEnergySkillID() then
			arg_4_0:specialAttack()
		else
			arg_4_0:createUnits()
		end

		var_4_0:popQueue()

		var_4_1, var_4_2 = var_4_0:getFront()

		if not arg_4_0:isCreatingUnits() then
			arg_4_0.unitSkills_ = nil

			arg_4_0:updateEnergyBy(var_4_0:getRemp())
			arg_4_0:popFrontSkill()
		end
	end
end

function var_0_3.specialAttack(arg_5_0)
	if arg_5_0:isDeath() or not arg_5_0.xuliSkill_ then
		arg_5_0.xuliSkill_ = nil

		return
	end

	arg_5_0.xuliSkill_ = nil

	local var_5_0 = var_0_7:xuliChild(arg_5_0:getEnergySkillID())
	local var_5_1 = var_0_7:sound(var_5_0)

	var_0_1.ctx.battle.pushSoundQueue(var_5_1)

	local var_5_2 = var_0_7:attackIndex(var_5_0)

	arg_5_0:playAttack(var_5_2)

	arg_5_0.unitSkills_ = var_0_5.new({
		fighter = arg_5_0,
		skillID = var_5_0
	})

	local var_5_3
	local var_5_4, var_5_5 = var_0_7:areaResource(var_5_0)

	if var_5_4 and var_5_4 ~= "" and var_5_5 and var_5_5 ~= "" then
		var_5_3 = var_0_6.new(var_5_0, "area", arg_5_0:getScale())
	end

	if var_5_3 then
		var_5_3:addTo(var_0_1.ctx.battle.unitLayer)
		var_5_3:pos(arg_5_0:getX(), arg_5_0:getY())
		var_5_3:playOnce()
		var_5_3:flipX(arg_5_0:getFlipX())
	end

	arg_5_0:beginAttackEnd(arg_5_0.unitSkills_)
end

function var_0_3.beginAttack(arg_6_0)
	if not arg_6_0:canAttack() then
		return
	end

	if arg_6_0:getFrontSkill() == arg_6_0:getEnergySkillID() then
		arg_6_0.xuliSkill_ = true
		arg_6_0.xuliCount_ = 1
	end

	var_0_3.super.beginAttack(arg_6_0)
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	local var_7_0 = var_0_7:pretime(arg_7_0:getEnergySkillID()) + var_0_7:pretime(var_0_7:xuliChild(arg_7_0:getEnergySkillID())) + 1

	arg_7_4 = arg_7_4 * math.min(arg_7_0.xuliCount_ * arg_7_0.xuliCount_ / (var_7_0 * var_7_0), 1)
	arg_7_0.xuliSkill_ = nil

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.applyUnitBuffs(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6)
	if arg_8_0:isDeath() then
		for iter_8_0, iter_8_1 in ipairs(arg_8_1 or {}) do
			if iter_8_1:getYx() > 0 then
				arg_8_0.buffMovePath_ = iter_8_1:getPath()
			end
		end

		return
	end

	if next(arg_8_2) then
		arg_8_0.fighterModel:playFloatText({
			var_0_2.BattleFloatType.BUFF_MISS
		}, arg_8_0:getTeamType())
	end

	if next(arg_8_1) then
		arg_8_0:addBuffs(arg_8_1)
	end

	if arg_8_5 and arg_8_0:isCreatingUnits() then
		arg_8_0:skillIsBreak(arg_8_6)

		arg_8_0.leftInterval_ = 0
	end

	if arg_8_3 then
		arg_8_0:checkSkillBreak(var_0_2.BreakSkillType.AD, arg_8_6)
	elseif arg_8_4 then
		arg_8_0:checkSkillBreak(var_0_2.BreakSkillType.AP, arg_8_6)
	end
end

function var_0_3.checkSkillBreak(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_1 == var_0_2.BreakSkillType.AP then
		if arg_9_0:getCurrentSkillType() == var_0_2.AttackType.AP or arg_9_0:getCurrentSkillType() == var_0_2.AttackType.CURE then
			if arg_9_0:isCreatingUnits() then
				arg_9_0.fighterModel:playFloatText({
					var_0_2.BattleFloatType.BREAK
				}, arg_9_0:getTeamType())

				if arg_9_0.xuliSkill_ then
					arg_9_0.xuliSkill_ = nil
				end

				arg_9_0:skillIsBreak(arg_9_2)
				arg_9_0:resumeIdle()
			end

			arg_9_0.isEnergySkill_ = false
		end
	elseif arg_9_1 == var_0_2.BreakSkillType.AD then
		if arg_9_0:isAdBreakImmortal() then
			return
		end

		arg_9_0:setBreakInterval()

		if not arg_9_0:isPause() then
			arg_9_0:attacked()
		end

		if arg_9_0:getCurrentSkillType() == var_0_2.AttackType.AD then
			if arg_9_0:isCreatingUnits() then
				arg_9_0.fighterModel:playFloatText({
					var_0_2.BattleFloatType.BREAK
				}, arg_9_0:getTeamType())
				arg_9_0:skillIsBreak(arg_9_2)
			end

			arg_9_0.isEnergySkill_ = false
		end

		if arg_9_0:getCurrentSkillType() == var_0_2.AttackType.AP or arg_9_0:getCurrentSkillType() == var_0_2.AttackType.CURE then
			if arg_9_0:isCreatingUnits() then
				arg_9_0.fighterModel:playFloatText({
					var_0_2.BattleFloatType.BREAK
				}, arg_9_0:getTeamType())
				arg_9_0:skillIsBreak(arg_9_2)

				if arg_9_0.xuliSkill_ then
					arg_9_0:specialAttack()
				end
			end

			arg_9_0.isEnergySkill_ = false
		end
	end
end

return var_0_3
