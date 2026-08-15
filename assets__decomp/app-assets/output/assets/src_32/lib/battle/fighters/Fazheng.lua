local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fazheng", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("SkillEffect")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = var_0_2.tables.cabinetSkillTable
local var_0_10 = 10350002
local var_0_11 = 80010040

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.xuliSkill_ = nil
	arg_1_0.xuliCount_ = 0
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if not arg_2_0.extraSkillJudge then
		arg_2_0.extraSkillJudge = true
		arg_2_0.extraSkillLevel = arg_2_0.hero_:skillBook()[tostring(var_0_10)] or 0
	end
end

function var_0_3.updateBaseInfo(arg_3_0)
	var_0_3.super.updateBaseInfo(arg_3_0)

	arg_3_0.xuliCount_ = arg_3_0.xuliCount_ > 0 and arg_3_0.xuliCount_ + 1 or 0
end

function var_0_3.clickAvatar(arg_4_0, arg_4_1)
	if arg_4_0.xuliSkill_ and arg_4_1.name == "ended" and var_0_1.ctx.battle.autoA ~= true then
		if arg_4_0:isCreatingUnits() then
			arg_4_0:skillIsBreak()
		end

		arg_4_0.isEnergySkill_ = false

		arg_4_0:specialAttack()
	end
end

function var_0_3.createAttacks(arg_5_0)
	local var_5_0 = arg_5_0.unitSkills_

	if not var_5_0 then
		return
	end

	if var_5_0:isEmptyQueue() then
		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			table.remove(arg_5_0.reportSkills_, 1)
		end

		arg_5_0.unitSkills_ = nil

		return
	end

	local var_5_1, var_5_2 = var_5_0:getFront()

	while var_5_1 and var_5_1 < 1 do
		if var_5_2 == arg_5_0:getEnergySkillID() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			arg_5_0:specialAttack()
		else
			arg_5_0:createUnits()
		end

		var_5_0:popQueue()

		var_5_1, var_5_2 = var_5_0:getFront()

		if not arg_5_0:isCreatingUnits() then
			arg_5_0.unitSkills_ = nil

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				table.remove(arg_5_0.reportSkills_, 1)
			end

			arg_5_0:updateEnergyBy(var_5_0:getRemp())
			arg_5_0:popFrontSkill()
		end
	end
end

function var_0_3.createUnits(arg_6_0, arg_6_1)
	var_0_3.super.createUnits(arg_6_0, arg_6_1)

	local var_6_0 = arg_6_1 or arg_6_0.unitSkills_
	local var_6_1 = var_0_6:xuliChild(arg_6_0:getEnergySkillID())

	if arg_6_0.isSkinSkillOn_ and arg_6_0.skinSkillID_ == var_0_11 and var_6_0.rootID_ == var_6_1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_2 = arg_6_0:getTargets(var_0_11)

		if not var_0_0.table.keyof(var_6_2, arg_6_0) then
			table.insert(var_6_2, arg_6_0)
		end

		local var_6_3 = arg_6_0:createAttackUnits(var_6_2, var_0_11)

		for iter_6_0, iter_6_1 in ipairs(var_6_3) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
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

	local var_7_0 = var_0_6:xuliChild(arg_7_0:getEnergySkillID())
	local var_7_1 = arg_7_0:getTargets(var_7_0)

	if not next(var_7_1) then
		arg_7_0:flipX(not arg_7_0:getFlipX())
	end

	local var_7_2 = var_0_6:sound(var_7_0)

	var_0_1.ctx.battle.pushSoundQueue(var_7_2)

	local var_7_3 = var_0_6:attackIndex(var_7_0)

	arg_7_0:playAttack(var_7_3)

	arg_7_0.unitSkills_ = var_0_4.new({
		fighter = arg_7_0,
		skillID = var_7_0
	})

	if arg_7_0:getTeamType() == var_0_2.TeamType.A and arg_7_0.bottomWnd then
		arg_7_0.bottomWnd:setXuliSkillEffect(arg_7_0, var_0_1.ctx.battle.teamA, false)
	end

	local var_7_4
	local var_7_5, var_7_6 = var_0_6:areaResource(var_7_0)

	if var_7_5 and var_7_5 ~= "" and var_7_6 and var_7_6 ~= "" then
		var_7_4 = var_0_1.ctx.battle.getSpine(var_7_0, "area", arg_7_0:getScale())
	end

	if var_7_4 then
		var_7_4:addTo(var_0_1.ctx.battle.unitLayer)
		var_7_4:pos(arg_7_0:getX(), arg_7_0:getY())
		var_7_4:playOnce()
		var_7_4:flipX(arg_7_0:getFlipX())
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

	if arg_9_1.rootID_ == var_0_6:xuliChild(arg_9_0:getEnergySkillID()) and var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_9_0 = arg_9_1.rootID_

		if arg_9_0:getTeamType() == var_0_2.TeamType.A and arg_9_0.bottomWnd then
			arg_9_0.bottomWnd:setXuliSkillEffect(arg_9_0, var_0_1.ctx.battle.teamA, false)
		end

		local var_9_1 = arg_9_0:getTargets(var_9_0)

		if not next(var_9_1) then
			arg_9_0:flipX(not arg_9_0:getFlipX())
		end

		local var_9_2
		local var_9_3, var_9_4 = var_0_6:areaResource(var_9_0)

		if var_9_3 and var_9_3 ~= "" and var_9_4 and var_9_4 ~= "" then
			var_9_2 = var_0_1.ctx.battle.getSpine(var_9_0, "area", arg_9_0:getScale())
		end

		if var_9_2 then
			var_9_2:addTo(var_0_1.ctx.battle.unitLayer)
			var_9_2:pos(arg_9_0:getX(), arg_9_0:getY())
			var_9_2:playOnce()
			var_9_2:flipX(arg_9_0:getFlipX())
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7 = var_0_3.super.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)

	if arg_10_1.skillID == var_0_6:xuliChild(arg_10_0:getEnergySkillID()) and var_0_6:pretime(arg_10_0:getEnergySkillID()) > 0 then
		local var_10_0 = var_0_6:pretime(arg_10_0:getEnergySkillID()) + var_0_6:pretime(var_0_6:xuliChild(arg_10_0:getEnergySkillID())) + 1

		arg_10_4 = arg_10_4 * math.min(arg_10_0.xuliCount_ * arg_10_0.xuliCount_ / (var_10_0 * var_10_0), 1)
		arg_10_0.xuliSkill_ = nil
	elseif arg_10_1.skillID == var_0_11 then
		local var_10_1 = var_0_6:pretime(arg_10_0:getEnergySkillID()) + var_0_6:pretime(var_0_6:xuliChild(arg_10_0:getEnergySkillID())) + 1

		arg_10_5 = arg_10_5 * math.min(arg_10_0.xuliCount_ * arg_10_0.xuliCount_ / (var_10_1 * var_10_1), 1)
	elseif arg_10_1.skillID == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_10_5 = arg_10_5 + arg_10_0.extraSkillLevel * var_0_9:attrValues(var_0_10)
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

return var_0_3
