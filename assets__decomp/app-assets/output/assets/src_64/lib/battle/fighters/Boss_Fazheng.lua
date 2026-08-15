local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fazheng", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("SkillEffect")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.xuliSkill_ = nil
	arg_1_0.xuliCount_ = 0
end

function var_0_3.singleLoop(arg_2_0)
	arg_2_0:updateBaseInfo()
	arg_2_0:checkMove()

	if not arg_2_0:isDeath() then
		arg_2_0:createAttacks()
	end

	arg_2_0:beginAttack()

	if arg_2_0:acttionInBlack() then
		arg_2_0:applyUnitMoves()
		arg_2_0:applyUnitHarms()
		arg_2_0:applyBuffHarms()

		arg_2_0.xuliCount_ = arg_2_0.xuliCount_ > 0 and arg_2_0.xuliCount_ + 1 or 0
	end

	arg_2_0:applyBuffMoves()

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType and arg_2_0.reportDieCount_ > 0 and var_0_1.ctx.battle.count > arg_2_0.reportDieCount_ and arg_2_0.isDead_ ~= true then
		arg_2_0:updateHp(0)
		arg_2_0:die()
	end

	arg_2_0:checkAwaken()
end

function var_0_3.createAttacks(arg_3_0)
	local var_3_0 = arg_3_0.unitSkills_

	if not var_3_0 then
		return
	end

	if var_3_0:isEmptyQueue() then
		arg_3_0.unitSkills_ = nil

		return
	end

	local var_3_1, var_3_2 = var_3_0:getFront()

	while var_3_1 and var_3_1 < 1 do
		if var_3_2 == arg_3_0:getEnergySkillID() then
			arg_3_0:specialAttack()
		else
			arg_3_0:createUnits()
		end

		var_3_0:popQueue()

		var_3_1, var_3_2 = var_3_0:getFront()

		if not arg_3_0:isCreatingUnits() then
			arg_3_0.unitSkills_ = nil

			arg_3_0:updateEnergyBy(var_3_0:getRemp())
			arg_3_0:popFrontSkill()
		end
	end
end

function var_0_3.specialAttack(arg_4_0)
	if arg_4_0:isDeath() or not arg_4_0.xuliSkill_ then
		arg_4_0.xuliSkill_ = nil

		return
	end

	arg_4_0.xuliSkill_ = nil

	local var_4_0 = var_0_6:xuliChild(arg_4_0:getEnergySkillID())
	local var_4_1 = var_0_6:sound(var_4_0)

	var_0_1.ctx.battle.pushSoundQueue(var_4_1)

	local var_4_2 = var_0_6:attackIndex(var_4_0)

	arg_4_0:playAttack(var_4_2)

	arg_4_0.unitSkills_ = var_0_4.new({
		fighter = arg_4_0,
		skillID = var_4_0
	})

	local var_4_3
	local var_4_4, var_4_5 = var_0_6:areaResource(var_4_0)

	if var_4_4 and var_4_4 ~= "" and var_4_5 and var_4_5 ~= "" then
		var_4_3 = var_0_5.new(var_4_0, "area", arg_4_0:getScale())
	end

	if var_4_3 then
		var_4_3:addTo(var_0_1.ctx.battle.unitLayer)
		var_4_3:pos(arg_4_0:getX(), arg_4_0:getY())
		var_4_3:playOnce()
		var_4_3:flipX(arg_4_0:getFlipX())
	end

	arg_4_0:beginAttackEnd(arg_4_0.unitSkills_)
end

function var_0_3.beginAttack(arg_5_0)
	if not arg_5_0:canAttack() then
		return
	end

	if arg_5_0:getFrontSkill() == arg_5_0:getEnergySkillID() then
		arg_5_0.xuliSkill_ = true
		arg_5_0.xuliCount_ = 1
	end

	var_0_3.super.beginAttack(arg_5_0)
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	if arg_6_1.skillID == var_0_6:xuliChild(arg_6_0:getEnergySkillID()) and var_0_6:pretime(arg_6_0:getEnergySkillID()) > 0 then
		local var_6_0 = var_0_6:pretime(arg_6_0:getEnergySkillID()) + var_0_6:pretime(var_0_6:xuliChild(arg_6_0:getEnergySkillID())) + 1

		arg_6_4 = arg_6_4 * math.min(arg_6_0.xuliCount_ * arg_6_0.xuliCount_ / (var_6_0 * var_6_0), 1)
		arg_6_0.xuliSkill_ = nil
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.applyUnitBuffs(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6)
	if arg_7_0:isDeath() then
		for iter_7_0, iter_7_1 in ipairs(arg_7_1 or {}) do
			if iter_7_1:getYx() > 0 then
				arg_7_0.buffMovePath_ = iter_7_1:getPath()
			end
		end

		return
	end

	if next(arg_7_2) then
		arg_7_0.fighterModel:playFloatText({
			var_0_2.BattleFloatType.BUFF_MISS
		}, arg_7_0:getTeamType())
	end

	if next(arg_7_1) then
		arg_7_0:addBuffs(arg_7_1)
	end

	if arg_7_5 and arg_7_0:isCreatingUnits() then
		arg_7_0:skillIsBreak(arg_7_6)

		arg_7_0.leftInterval_ = 0
	end

	if arg_7_3 then
		arg_7_0:checkSkillBreak(var_0_2.BreakSkillType.AD, arg_7_6)
	elseif arg_7_4 then
		arg_7_0:checkSkillBreak(var_0_2.BreakSkillType.AP, arg_7_6)
	end
end

function var_0_3.checkSkillBreak(arg_8_0, arg_8_1, arg_8_2)
	if arg_8_1 == var_0_2.BreakSkillType.AP then
		if arg_8_0:getCurrentSkillType() == var_0_2.AttackType.AP or arg_8_0:getCurrentSkillType() == var_0_2.AttackType.CURE then
			if arg_8_0:isCreatingUnits() then
				arg_8_0.fighterModel:playFloatText({
					var_0_2.BattleFloatType.BREAK
				}, arg_8_0:getTeamType())

				if arg_8_0.xuliSkill_ then
					arg_8_0.xuliSkill_ = nil
				end

				arg_8_0:skillIsBreak(arg_8_2)
				arg_8_0:resumeIdle()
			end

			arg_8_0.isEnergySkill_ = false
		end
	elseif arg_8_1 == var_0_2.BreakSkillType.AD then
		if arg_8_0:isAdBreakImmortal() then
			return
		end

		arg_8_0:setBreakInterval()

		if not arg_8_0:isPause() then
			arg_8_0:attacked()
		end

		if arg_8_0:getCurrentSkillType() == var_0_2.AttackType.AD then
			if arg_8_0:isCreatingUnits() then
				arg_8_0.fighterModel:playFloatText({
					var_0_2.BattleFloatType.BREAK
				}, arg_8_0:getTeamType())
				arg_8_0:skillIsBreak(arg_8_2)
			end

			arg_8_0.isEnergySkill_ = false
		end

		if arg_8_0:getCurrentSkillType() == var_0_2.AttackType.AP or arg_8_0:getCurrentSkillType() == var_0_2.AttackType.CURE then
			if arg_8_0:isCreatingUnits() then
				arg_8_0.fighterModel:playFloatText({
					var_0_2.BattleFloatType.BREAK
				}, arg_8_0:getTeamType())
				arg_8_0:skillIsBreak(arg_8_2)

				if arg_8_0.xuliSkill_ then
					arg_8_0:specialAttack()
				end
			end

			arg_8_0.isEnergySkill_ = false
		end
	end
end

return var_0_3
