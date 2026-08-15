local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = math
local var_0_8 = 300
local var_0_9 = 50

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.skillRush_ = {}
	arg_1_0.purpleCounts_ = 0
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)
	arg_2_0:updatePurpleSkill()
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_0 = arg_3_0:getSkillLevelByID(arg_3_1.skillID)

	if arg_3_0.isStarEnergy_ and arg_3_1.skillID == arg_3_0:getEnergySkillID() then
		arg_3_4 = arg_3_4 + var_0_4:desc4NumStep(arg_3_1.skillID)[2] * var_3_0 * arg_3_1.target:getADJianShang()
	elseif arg_3_0.isStarBlue_ and arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_3_1 = var_0_4:desc4NumStep(arg_3_1.skillID)[2] * var_3_0

		arg_3_4 = arg_3_4 + var_0_7.ceil(var_3_1 * (arg_3_1.target:getHp() / arg_3_1.target:getHpLimit())) * arg_3_1.target:getADJianShang()
	end

	return var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
end

function var_0_3.updatePurpleSkill(arg_4_0)
	if arg_4_0:isDeath() or arg_4_0.purpleCounts_ < 1 then
		return
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_4_0.purpleCounts_ = arg_4_0.purpleCounts_ - 1

	if var_0_1.ctx.battle.count % 30 > 0 or arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 then
		return
	end

	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() then
			table.insert(var_4_0, iter_4_1)
		end
	end

	if next(var_4_0) == nil then
		return
	end

	local var_4_1 = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	local var_4_2 = arg_4_0:createAttackUnits(var_4_0, var_4_1)

	for iter_4_2, iter_4_3 in ipairs(var_4_2) do
		table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
		table.insert(arg_4_0.records_.special_units, iter_4_3)
	end
end

function var_0_3.setBuffAttr(arg_5_0, arg_5_1)
	if arg_5_1.skillID_ ~= arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		return
	end

	local var_5_0 = var_0_7.floor(arg_5_0.purpleCounts_ / 30)

	var_5_0 = var_5_0 > 0 and var_5_0 or 0
	arg_5_1.manualRevise = arg_5_1:getAttr() * var_5_0
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	if arg_6_1:getAttr() > 0 then
		arg_6_0:setBuffAttr(arg_6_1)
	end
end

function var_0_3.createUnits(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_1 or arg_7_0.unitSkills_
	local var_7_1, var_7_2 = var_7_0:getFront()

	if var_0_4:father(var_7_2) == arg_7_0:getEnergySkillID() then
		local var_7_3 = arg_7_0:getFighterModel():getWidth() + var_0_2.STAGE_WIDTH
		local var_7_4 = var_0_9

		if arg_7_0.rushUnit_ then
			arg_7_0.rushUnit_:arrive()

			arg_7_0.rushUnit_.arrived = true
			arg_7_0.rushUnit_ = nil
		end

		arg_7_0.skillRush_ = {}

		local var_7_5 = arg_7_0:getFlipX() and -1 or 1

		for iter_7_0 = 1, var_7_4 do
			table.insert(arg_7_0.skillRush_, {
				var_7_5 * var_7_3 / var_7_4,
				0
			})
		end
	end

	if var_7_0 and var_7_0.rootID_ == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_7_0.purpleCounts_ = var_0_8

		if arg_7_0.isStarPurple_ then
			arg_7_0.purpleCounts_ = arg_7_0.purpleCounts_ + var_0_8
		end
	end

	var_0_3.super.createUnits(arg_7_0, var_7_0)
end

function var_0_3.unitAfterCreate(arg_8_0, arg_8_1, arg_8_2)
	if arg_8_1 and arg_8_1.skillID == arg_8_0:getEnergySkillID() then
		arg_8_0.rushUnit_ = arg_8_1
	end
end

function var_0_3.moveUnitArrive(arg_9_0, arg_9_1)
	if arg_9_1.resource then
		arg_9_1.resource:stop()
	end

	arg_9_1:arrive()

	if arg_9_1:getAreaResource() then
		local var_9_0 = arg_9_1.unitEffectType == var_0_2.UnitEffectType.SelfFootPos and arg_9_1.fighter:getY() or arg_9_1.desY_
		local var_9_1 = arg_9_1.unitEffectType == var_0_2.UnitEffectType.SelfFootPos and arg_9_1.fighter:getX() or arg_9_1.desX_

		arg_9_1:getAreaResource():addTo(var_0_1.ctx.battle.unitLayer)
		arg_9_1:getAreaResource():pos(var_9_1, var_9_0)
		arg_9_1:getAreaResource():playOnce()
		arg_9_1:getAreaResource():flipX(arg_9_1.fighter:getX() > arg_9_1.desX_)
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_9_2 = arg_9_1:getReportUnits()

		for iter_9_0, iter_9_1 in ipairs(var_9_2) do
			table.insert(arg_9_0.applyUnits_, iter_9_1)
		end
	else
		local var_9_3 = arg_9_0:getTargets(arg_9_1.skillID, arg_9_1)

		if next(var_9_3) then
			local var_9_4 = arg_9_1:createAttacks(var_9_3)

			for iter_9_2, iter_9_3 in ipairs(var_9_4) do
				table.insert(arg_9_0.applyUnits_, iter_9_3)
			end
		end
	end
end

function var_0_3.applyBuffMoves(arg_10_0)
	var_0_3.super.applyBuffMoves(arg_10_0)

	if next(arg_10_0.skillRush_) == nil or var_0_1.ctx.battle.isReleased(arg_10_0.fighterModel) or arg_10_0:isDeath() or not arg_10_0:acttionInBlack() then
		return
	end

	local var_10_0, var_10_1 = unpack(arg_10_0.skillRush_[1])

	table.remove(arg_10_0.skillRush_, 1)

	if var_10_0 ~= 0 or var_10_1 ~= 0 then
		arg_10_0:moveByX(var_10_0, false)
		arg_10_0:moveByY(var_10_1, false)

		if arg_10_0:getX() <= -1 * arg_10_0:getFighterModel():getWidth() / 2 and var_10_0 < 0 then
			arg_10_0:x(arg_10_0:getFighterModel():getWidth() / 2 + var_0_2.STAGE_WIDTH)

			if arg_10_0.rushUnit_ then
				arg_10_0.rushUnit_.iniX_ = arg_10_0:getX()
			end
		elseif arg_10_0:getX() >= var_0_2.STAGE_WIDTH + arg_10_0:getFighterModel():getWidth() / 2 and var_10_0 > 0 then
			arg_10_0:x(-1 * arg_10_0:getFighterModel():getWidth() / 2)

			if arg_10_0.rushUnit_ then
				arg_10_0.rushUnit_.iniX_ = arg_10_0:getX()
			end
		end
	end

	if next(arg_10_0.skillRush_) == nil and arg_10_0.rushUnit_ then
		arg_10_0.rushUnit_:arrive()

		arg_10_0.rushUnit_.arrived = true
		arg_10_0.rushUnit_ = nil
	end
end

return var_0_3
