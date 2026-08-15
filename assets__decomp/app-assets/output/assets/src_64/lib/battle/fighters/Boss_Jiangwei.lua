local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Jiangwei", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 10
local var_0_6 = -100
local var_0_7 = 10000327
local var_0_8 = 10000326

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isEnergy_ = nil
	arg_1_0.energyEffect_ = nil
	arg_1_0.noEnergy_ = nil
	arg_1_0.isRushgoon = false
	arg_1_0.skillRush_ = {}
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)
	arg_2_0:updateEnergySkill()
end

function var_0_3.applyBuffMoves(arg_3_0)
	var_0_3.super.applyBuffMoves(arg_3_0)

	if next(arg_3_0.skillRush_) == nil or var_0_1.ctx.battle.isReleased(arg_3_0.fighterModel) or arg_3_0:isDeath() or not arg_3_0:acttionInBlack() then
		return
	end

	local var_3_0, var_3_1 = unpack(arg_3_0.skillRush_[1])

	table.remove(arg_3_0.skillRush_, 1)

	if var_3_0 ~= 0 or var_3_1 ~= 0 then
		arg_3_0:moveByX(var_3_0, false)
		arg_3_0:moveByY(var_3_1, false)
	end

	if next(arg_3_0.skillRush_) == nil and arg_3_0.rushUnit_ then
		arg_3_0.rushUnit_:arrive()

		arg_3_0.rushUnit_.arrived = true
		arg_3_0.rushUnit_ = nil
		arg_3_0.isRushgoon = false
	end
end

function var_0_3.moveUnitArrive(arg_4_0, arg_4_1)
	if arg_4_1.resource then
		arg_4_1.resource:stop()
	end

	arg_4_1:arrive()

	if arg_4_1:getAreaResource() then
		local var_4_0 = arg_4_1.unitEffectType == var_0_2.UnitEffectType.SelfFootPos and arg_4_1.fighter:getY() or arg_4_1.desY_
		local var_4_1 = arg_4_1.unitEffectType == var_0_2.UnitEffectType.SelfFootPos and arg_4_1.fighter:getX() or arg_4_1.desX_

		arg_4_1:getAreaResource():addTo(var_0_1.ctx.battle.unitLayer)
		arg_4_1:getAreaResource():pos(var_4_1, var_4_0)
		arg_4_1:getAreaResource():playOnce()
		arg_4_1:getAreaResource():flipX(arg_4_1.fighter:getX() > arg_4_1.desX_)
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_4_2 = arg_4_1:getReportUnits()

		for iter_4_0, iter_4_1 in ipairs(var_4_2) do
			table.insert(arg_4_0.applyUnits_, iter_4_1)
		end
	else
		local var_4_3 = arg_4_0:getTargets(arg_4_1.skillID, arg_4_1)

		if next(var_4_3) then
			local var_4_4 = arg_4_1:createAttacks(var_4_3)

			for iter_4_2, iter_4_3 in ipairs(var_4_4) do
				if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
					iter_4_3.targetsCount = #var_4_4
				end

				table.insert(arg_4_0.applyUnits_, iter_4_3)
			end
		end
	end
end

function var_0_3.getFarest(arg_5_0)
	local var_5_0
	local var_5_1

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and (not var_5_0 or var_5_1 < math.abs(iter_5_1:getX() - arg_5_0:getX())) then
			var_5_0 = iter_5_1
			var_5_1 = math.abs(var_5_0:getX() - arg_5_0:getX())
		end
	end

	var_5_1 = var_5_1 and (var_5_1 > 50 and var_5_1 - 50 or var_5_1)

	return var_5_0, var_5_1
end

function var_0_3.createUnits(arg_6_0)
	local var_6_0, var_6_1 = arg_6_0.unitSkills_:getFront()

	if var_6_1 == var_0_8 then
		local var_6_2, var_6_3 = arg_6_0:getFarest()

		if not var_6_2 then
			return
		end

		local var_6_4 = var_0_5

		if arg_6_0.rushUnit_ then
			arg_6_0.rushUnit_:arrive()

			arg_6_0.rushUnit_.arrived = true
			arg_6_0.rushUnit_ = nil
			arg_6_0.isRushgoon = false
		end

		arg_6_0.skillRush_ = {}

		local var_6_5 = var_6_2:getX() < arg_6_0:getX() and -1 or 1

		for iter_6_0 = 1, var_6_4 do
			table.insert(arg_6_0.skillRush_, {
				var_6_5 * var_6_3 / var_6_4,
				0
			})
		end

		arg_6_0.isRushgoon = true

		arg_6_0:flipX(var_6_2:getX() < arg_6_0:getX())
	end

	var_0_3.super.createUnits(arg_6_0)
end

function var_0_3.isBreakImmortal(arg_7_0)
	if arg_7_0.isRushgoon then
		return true
	else
		return var_0_3.super.isBreakImmortal(arg_7_0)
	end
end

function var_0_3.isAffected(arg_8_0)
	if arg_8_0.isRushgoon then
		return true
	else
		return var_0_3.super.isAffected(arg_8_0)
	end
end

function var_0_3.updateEnergySkill(arg_9_0)
	if not arg_9_0.isEnergy_ or var_0_1.ctx.battle.count % 30 > 0 then
		return
	end

	if var_0_1.ctx.battle.teamBEnd then
		if arg_9_0.energyEffect_ then
			arg_9_0.energyEffect_:stop()

			arg_9_0.energyEffect_ = nil
		end

		return
	end

	arg_9_0:updateEnergyBy(var_0_6)

	if arg_9_0:getEnergy() < 1 then
		arg_9_0.isEnergy_ = nil
		arg_9_0.noEnergy_ = nil

		if arg_9_0.energyEffect_ then
			arg_9_0.energyEffect_:stop()

			arg_9_0.energyEffect_ = nil
		end
	end

	if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
		return
	end

	local var_9_0 = var_0_7
	local var_9_1 = arg_9_0:getEnergyTarget()
	local var_9_2 = arg_9_0:createAttackUnits(var_9_1, var_9_0)

	for iter_9_0, iter_9_1 in ipairs(var_9_2) do
		table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
		table.insert(arg_9_0.records_.special_units, iter_9_1)
	end
end

function var_0_3.applySingleUnit(arg_10_0, arg_10_1)
	var_0_3.super.applySingleUnit(arg_10_0, arg_10_1)

	if arg_10_1.skillID == arg_10_0:getEnergySkillID() then
		arg_10_0.energyPosX_ = arg_10_1.target:getX()
		arg_10_0.isEnergy_ = true

		if not arg_10_0.energyEffect_ then
			local var_10_0, var_10_1 = var_0_4:areaResource(arg_10_0:getEnergySkillID())

			if var_10_0 and var_10_0 ~= "" and var_10_1 and var_10_1 ~= "" then
				arg_10_0.energyEffect_ = var_0_1.ctx.battle.getSpine(arg_10_0:getEnergySkillID(), "area", arg_10_0:getScale())

				arg_10_0.energyEffect_:addTo(var_0_1.ctx.battle.unitBottomLayer)
			end
		end

		if arg_10_0.energyEffect_ then
			arg_10_0.energyEffect_:pos(arg_10_0.energyPosX_, 300)
			arg_10_0.energyEffect_:playRepeat()
		end
	end
end

function var_0_3.getDMP(arg_11_0)
	return var_0_2.PERCENT_BASE
end

function var_0_3.getEnergyTarget(arg_12_0)
	local var_12_0 = var_0_4:scope(var_0_7)
	local var_12_1 = {}

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.targetTeam_) do
		if not iter_12_1:isDeath() and not iter_12_1:isAffected() and math.abs(iter_12_1:getX() - arg_12_0.energyPosX_) < var_12_0 / 2 then
			table.insert(var_12_1, iter_12_1)
		end
	end

	return var_12_1
end

function var_0_3.selectTargetByTypeD1(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = {}

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.sideTeam_) do
		if not iter_13_1:isDeath() and not iter_13_1:isAffected() then
			table.insert(var_13_0, iter_13_1)
		end
	end

	if not next(var_13_0) then
		return {}
	end

	table.sort(var_13_0, function(arg_14_0, arg_14_1)
		return arg_14_0:getX() < arg_14_1:getX()
	end)

	if #var_13_0 == 1 then
		return {
			var_13_0[1]
		}
	elseif #var_13_0 == 2 then
		return math.abs(var_13_0[1]:getX() - arg_13_0:getX()) > math.abs(var_13_0[2]:getX() - arg_13_0:getX()) and {
			var_13_0[2]
		} or {
			var_13_0[1]
		}
	elseif #var_13_0 == 3 then
		return {
			var_13_0[2]
		}
	else
		local var_13_1
		local var_13_2

		for iter_13_2 = 2, #var_13_0 - 1 do
			if not var_13_1 or var_13_1 > var_13_0[iter_13_2 + 1]:getX() - var_13_0[iter_13_2 - 1]:getX() then
				var_13_1 = var_13_0[iter_13_2 + 1]:getX() - var_13_0[iter_13_2 - 1]:getX()
				var_13_2 = var_13_0[iter_13_2]
			end
		end

		return {
			var_13_2
		}
	end
end

function var_0_3.unitAfterCreate(arg_15_0, arg_15_1, arg_15_2)
	if arg_15_1 and arg_15_1.skillID == var_0_8 then
		arg_15_0.rushUnit_ = arg_15_1
	end
end

function var_0_3.isHurtBreak(arg_16_0, arg_16_1, arg_16_2)
	if arg_16_1 > arg_16_0:getHpLimit() * var_0_2.SHOW_HURT_EFFECT_RATE and arg_16_0.isEnergySkill_ ~= true and not arg_16_0:isPause() and next(arg_16_0.rushUnit_ or {}) == nil or arg_16_2:isForceBreak() then
		return true
	end

	return false
end

function var_0_3.checkSkillBreak(arg_17_0, arg_17_1, arg_17_2)
	var_0_3.super.checkSkillBreak(arg_17_0, arg_17_1, arg_17_2)

	if arg_17_1 == var_0_2.BreakSkillType.AD then
		if arg_17_0:isAdBreakImmortal() or arg_17_0:isBreakImmortal() then
			return
		end

		if next(arg_17_0.skillRush_) then
			arg_17_0.skillRush_ = {}

			if arg_17_0:getX() > var_0_2.STAGE_WIDTH - arg_17_0:getFighterModel():getWidth() / 2 then
				arg_17_0:x(var_0_2.STAGE_WIDTH - arg_17_0:getFighterModel():getWidth() / 2)
			elseif arg_17_0:getX() < arg_17_0:getFighterModel():getWidth() / 2 then
				arg_17_0:x(arg_17_0:getFighterModel():getWidth() / 2)
			end
		end

		if arg_17_0.rushUnit_ then
			arg_17_0.rushUnit_:arrive()

			arg_17_0.rushUnit_.arrived = true
			arg_17_0.rushUnit_ = nil
			arg_17_0.isRushgoon = false
		end
	end
end

function var_0_3.clickAvatar(arg_18_0, arg_18_1)
	if arg_18_1.name == "ended" and var_0_1.ctx.battle.autoA ~= true then
		if next(arg_18_0.skillRush_) then
			arg_18_0.skillRush_ = {}

			if arg_18_0:getX() > var_0_2.STAGE_WIDTH - arg_18_0:getFighterModel():getWidth() / 2 then
				arg_18_0:x(var_0_2.STAGE_WIDTH - arg_18_0:getFighterModel():getWidth() / 2)
			elseif arg_18_0:getX() < arg_18_0:getFighterModel():getWidth() / 2 then
				arg_18_0:x(arg_18_0:getFighterModel():getWidth() / 2)
			end
		end

		if arg_18_0.rushUnit_ then
			arg_18_0.rushUnit_:arrive()

			arg_18_0.rushUnit_.arrived = true
			arg_18_0.rushUnit_ = nil
			arg_18_0.isRushgoon = false
		end
	end
end

function var_0_3.beginAttackEnd(arg_19_0, arg_19_1)
	var_0_3.super.beginAttackEnd(arg_19_0, arg_19_1)

	if arg_19_1.rootID_ == arg_19_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_19_0 = arg_19_0:getFarest()

		if var_19_0 then
			arg_19_0:flipX(var_19_0:getX() < arg_19_0:getX())
		end
	elseif arg_19_1.rootID_ == arg_19_0:getEnergySkillID() then
		arg_19_0.noEnergy_ = true
	end
end

function var_0_3.checkEnergySkill(arg_20_0)
	if arg_20_0.noEnergy_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_20_0)
end

return var_0_3
