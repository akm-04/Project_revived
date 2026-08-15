local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fangtianhuaji", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_8 = math.min
local var_0_9 = 18
local var_0_10 = 10000456
local var_0_11 = 10000459
local var_0_12 = 10000460
local var_0_13 = 10000452
local var_0_14 = 380
local var_0_15 = 10000453
local var_0_16 = 10000454
local var_0_17 = {
	40010191
}
local var_0_18 = 50
local var_0_19 = 80010109
local var_0_20 = 80020109
local var_0_21 = 40012075
local var_0_22 = 40012081
local var_0_23 = 1.75

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.greenSkillTarget_ = {}
	arg_1_0.shanbiCount_ = 0
	arg_1_0.energyTarget_ = {}
	arg_1_0.beginJump_ = false
	arg_1_0.greenBackCount_ = nil
	arg_1_0.blueBackCount_ = nil
	arg_1_0.energyCount_ = nil
	arg_1_0.addNeverDieBuff = false
end

function var_0_3.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7 = var_0_3.super.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)

	if arg_2_0.skinSkillID_ == var_0_19 and arg_2_4 > 0 then
		local var_2_0, var_2_1 = var_0_7.getTeam(arg_2_0)
		local var_2_2 = var_0_7.aliveTargets(var_2_1)

		arg_2_4 = arg_2_4 + arg_2_0:getAD() * #var_2_2 * 0.2
	end

	if arg_2_0:isHasBuffByID(var_0_22) and arg_2_6 > 0 then
		arg_2_6 = arg_2_6 * var_0_23
	end

	return arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.target:isDeath() and var_0_6:father(arg_3_1.skillID) == arg_3_0:getEnergySkillID() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_3_1:recordData(false, false, 0, 0, 0, 0)
	end

	if arg_3_1.skillID == var_0_11 then
		if arg_3_1.target:isDeath() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_0 = {}

			for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
				if not iter_3_1:isDeath() and not iter_3_1:isAffected() then
					table.insert(var_3_0, iter_3_1)
				end
			end

			local var_3_1 = arg_3_0:createAttackUnits(var_3_0, var_0_12)

			for iter_3_2, iter_3_3 in ipairs(var_3_1) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
				table.insert(arg_3_0.records_.special_units, iter_3_3)
			end
		end

		arg_3_0.energyTarget_ = {}
	elseif var_0_6:father(arg_3_1.skillID) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_3_1.target ~= arg_3_0 then
		local var_3_2 = arg_3_1.target:getX()
		local var_3_3 = arg_3_1.target:getY()
		local var_3_4

		if arg_3_0:getTeamType() == var_0_2.TeamType.A then
			var_3_4 = -1

			arg_3_0:flipX(false)
		else
			var_3_4 = 1

			arg_3_0:flipX(true)
		end

		arg_3_0:x(var_3_2 + 100 * var_3_4)
		arg_3_0:y(var_3_3)

		if arg_3_1.skillID == var_0_13 then
			arg_3_0.greenSkillTarget_ = {}
			arg_3_0.greenBackCount_ = var_0_9
		end
	end
end

function var_0_3.isBreakImmortal(arg_4_0)
	if arg_4_0.beginJump_ then
		return true
	else
		return var_0_3.super.isBreakImmortal(arg_4_0)
	end
end

function var_0_3.createUnits(arg_5_0)
	var_0_3.super.createUnits(arg_5_0)

	if arg_5_0.beginJump_ then
		arg_5_0.beginJump_ = false
	end
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	if arg_6_1.rootID_ == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_6_0.beginJump_ = true

		local var_6_0 = arg_6_0:getFlipX() and 100 or -100
		local var_6_1 = math.ceil(var_0_6:pretime(var_0_15) / 2)
		local var_6_2 = {}

		arg_6_0.buffMovePath_ = {}
		arg_6_0.blueBackCount_ = var_0_6:pretime(var_0_16) + 20
		arg_6_0.bluePreX_ = arg_6_0:getX()
		arg_6_0.bluePreY_ = arg_6_0:getY()

		for iter_6_0 = 1, var_6_1 do
			if iter_6_0 <= var_6_1 then
				table.insert(arg_6_0.buffMovePath_, {
					var_6_0 / var_6_1,
					0
				})
			end
		end
	elseif arg_6_1.rootID_ == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_6_0.greenPreX_ = arg_6_0:getX()
		arg_6_0.greenPreY_ = arg_6_0:getY()
	elseif arg_6_1.rootID_ == arg_6_0:getEnergySkillID() then
		local var_6_3 = unpack(arg_6_0:selectTargetByTypeD2())
		local var_6_4

		if arg_6_0:getTeamType() == var_0_2.TeamType.A then
			var_6_4 = -1

			arg_6_0:flipX(false)
		else
			var_6_4 = 1

			arg_6_0:flipX(true)
		end

		if var_6_3 then
			arg_6_0.energyPosX_ = var_6_3:getX() + 100 * var_6_4
			arg_6_0.energyPosY_ = var_6_3:getY()
			arg_6_0.energyCount_ = var_0_6:pretime(var_0_10)
		end
	end

	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)
end

function var_0_3.selectTargetByTypeD1(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and iter_7_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_7_0, iter_7_1)
		end
	end

	if next(var_7_0) then
		for iter_7_2, iter_7_3 in ipairs(var_7_0) do
			local var_7_1 = false

			for iter_7_4, iter_7_5 in ipairs(arg_7_0.greenSkillTarget_) do
				if iter_7_3 == iter_7_5 then
					var_7_1 = true

					break
				end
			end

			if not var_7_1 then
				table.insert(arg_7_0.greenSkillTarget_, iter_7_3)

				return {
					iter_7_3
				}
			end
		end

		arg_7_0.greenSkillTarget_ = {}

		return arg_7_0:selectTargetByTypeD1(arg_7_1, arg_7_2)
	else
		return {}
	end
end

function var_0_3.selectTargetByTypeD2(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0

	if next(arg_8_0.energyTarget_) then
		return arg_8_0.energyTarget_
	else
		local var_8_1 = 2

		for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
			if not iter_8_1:isDeath() and not iter_8_1:isAffected() and iter_8_1:getSummonType() == var_0_2.summonMonsterType.None then
				local var_8_2 = iter_8_1:getHp() / iter_8_1:getHpLimit()

				if var_8_2 < var_8_1 then
					var_8_1 = var_8_2
					var_8_0 = iter_8_1
				end
			end
		end

		arg_8_0.energyTarget_ = {
			var_8_0
		}
	end

	return {
		var_8_0
	}
end

function var_0_3.toDoPerFrames(arg_9_0)
	if arg_9_0:isDeath() then
		return
	end

	if arg_9_0.shanbiCount_ > 0 and arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		arg_9_0.shanbiCount_ = arg_9_0.shanbiCount_ - 1
	end

	if arg_9_0.greenBackCount_ then
		arg_9_0.greenBackCount_ = arg_9_0.greenBackCount_ - 1

		if arg_9_0.greenBackCount_ <= 0 and arg_9_0.greenPreX_ and arg_9_0.greenPreY_ then
			arg_9_0:x(arg_9_0.greenPreX_)
			arg_9_0:y(arg_9_0.greenPreY_)

			arg_9_0.greenPreX_ = nil
			arg_9_0.greenPreY_ = nil
			arg_9_0.greenBackCount_ = nil
		end
	end

	if arg_9_0.blueBackCount_ then
		arg_9_0.blueBackCount_ = arg_9_0.blueBackCount_ - 1

		if arg_9_0.blueBackCount_ <= 0 then
			arg_9_0:x(arg_9_0.bluePreX_)
			arg_9_0:y(arg_9_0.bluePreY_)

			arg_9_0.bluePreX_ = nil
			arg_9_0.bluePreY_ = nil
			arg_9_0.blueBackCount_ = nil
		end
	end

	if arg_9_0.energyCount_ then
		arg_9_0.energyCount_ = arg_9_0.energyCount_ - 1

		if arg_9_0.energyCount_ <= 0 then
			arg_9_0.greenBackCount_ = nil

			arg_9_0:x(arg_9_0.energyPosX_)
			arg_9_0:y(arg_9_0.energyPosY_)

			arg_9_0.energyPosX_ = nil
			arg_9_0.energyPosY_ = nil
			arg_9_0.energyCount_ = nil
		end
	end

	if arg_9_0.skinSkillID_ == var_0_20 and not arg_9_0.addNeverDieBuff then
		arg_9_0.addNeverDieBuff = true

		local var_9_0 = arg_9_0:createNewBuffs({
			var_0_21
		}, arg_9_0, var_0_20)

		arg_9_0:addBuffs(var_9_0)
	end
end

function var_0_3.neverDieFeedBack(arg_10_0, arg_10_1)
	if arg_10_1 == arg_10_0 then
		local var_10_0 = arg_10_0:createNewBuffs({
			var_0_22
		}, arg_10_0, var_0_20)

		arg_10_0:addBuffs(var_10_0)

		if arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
			local var_10_1 = arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)

			arg_10_0:createSkillByID(var_10_1, arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green), var_0_6:attackIndex(var_10_1))
		end
	end
end

function var_0_3.updateUnitDataByTarget(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)
	local var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = var_0_3.super.updateUnitDataByTarget(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)

	if arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and not var_11_0 and not arg_11_0:isCreatingUnits() and arg_11_1.attackType == var_0_2.AttackType.AD and arg_11_1.fighter:getTeamType() ~= arg_11_0:getTeamType() and arg_11_0.shanbiCount_ <= 0 then
		arg_11_0.shanbiCount_ = var_0_14
		var_11_0 = true

		if arg_11_1.fighter:getX() - arg_11_0:getX() < 0 then
			arg_11_0:flipX(true)
		else
			arg_11_0:flipX(false)
		end

		local var_11_6 = arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)

		if arg_11_0.hero_.isSkinOn_ and arg_11_0.hero_.isSkinOn_ ~= 0 or arg_11_0.isSkinSkillOn_ then
			var_11_6 = var_0_6:skinSkill(var_11_6, arg_11_0.skinSkillIndex_)
		end

		local var_11_7 = var_0_6:sound(var_11_6)

		var_0_1.ctx.battle.pushSoundQueue(var_11_7)

		local var_11_8 = var_0_6:attackIndex(var_11_6)

		arg_11_0:playAttack(var_11_8)

		arg_11_0.unitSkills_ = var_0_5.new({
			fighter = arg_11_0,
			skillID = var_11_6
		})

		arg_11_0:beginAttackEnd(arg_11_0.unitSkills_)

		arg_11_0.manualTarget_ = {
			arg_11_1.fighter
		}
	end

	return var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5
end

function var_0_3.playShanbi(arg_12_0, arg_12_1)
	var_0_3.super.playShanbi(arg_12_0, arg_12_1)

	if arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_12_0:addBuffs(arg_12_0:newBuff(var_0_17, arg_12_0, arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)))
		arg_12_0:updateEnergyTo(arg_12_0:getEnergy() + var_0_18)
	end
end

function var_0_3.newBuff(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0 = {}

	for iter_13_0, iter_13_1 in ipairs(arg_13_1) do
		local var_13_1 = var_0_4.new({
			tableID = iter_13_1,
			start = var_0_1.ctx.battle.count,
			level = arg_13_0:getSkillLevelByID(arg_13_3),
			skillID = arg_13_3,
			fighter = arg_13_0,
			target = arg_13_2
		})

		var_13_1:setIsHit(true)
		var_13_1:setDirection(arg_13_0:getFighterModel():getFlipX())
		table.insert(var_13_0, var_13_1)
	end

	return var_13_0
end

return var_0_3
