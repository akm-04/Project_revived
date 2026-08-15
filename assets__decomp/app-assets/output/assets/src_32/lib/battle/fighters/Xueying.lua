local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xueying", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_8 = var_0_2.tables.cabinetSkillTable
local var_0_9 = 30010215
local var_0_10 = 40010215
local var_0_11 = 20100006
local var_0_12 = 10001492
local var_0_13 = 10001490
local var_0_14 = 0.1
local var_0_15 = 0.004
local var_0_16 = 80010215
local var_0_17 = 40012291
local var_0_18 = 0.2

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.greenTargets = {}
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.Energy2ndPhaseSkill = 10002151
		arg_2_0.GreenSkillID = 10002152
		arg_2_0.EnergySkillID = 10002153
	else
		arg_2_0.Energy2ndPhaseSkill = 10001491
		arg_2_0.GreenSkillID = 20020215
		arg_2_0.EnergySkillID = 50010215
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if not arg_3_0.extraSkillJudge then
		arg_3_0.extraSkillJudge = true
		arg_3_0.extraSkillLevel = arg_3_0.hero_:skillBook()[tostring(var_0_11)] or 0
	end

	if arg_3_0:getLeftInterval() <= 0 then
		arg_3_0.greenTargets = {}
	end
end

function var_0_3.selectTargetByTypeD2(arg_4_0, arg_4_1, arg_4_2)
	for iter_4_0, iter_4_1 in ipairs(arg_4_0.targetTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and not arg_4_0.greenTargets[iter_4_1] then
			arg_4_0.greenTargets[iter_4_1] = true

			return {
				iter_4_1
			}
		end
	end

	return {}
end

function var_0_3.unitAfterCreate(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_2 and next(arg_5_2) and arg_5_2[1].skillID == arg_5_0.GreenSkillID then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0.targetTeam_) do
			if not iter_5_1:isDeath() and not iter_5_1:isAffected() and not arg_5_0.greenTargets[iter_5_1] then
				arg_5_0:createSkillByID(arg_5_0.GreenSkillID, arg_5_0:getSkillLevelByID(arg_5_0.GreenSkillID), var_0_5:attackIndex(arg_5_0.GreenSkillID))

				return
			end
		end
	end

	arg_5_0.greenTargets = {}
end

function var_0_3.selectTargetByTypeD3(arg_6_0, arg_6_1, arg_6_2)
	return var_0_7.B17(arg_6_0, arg_6_1)
end

function var_0_3.checkSkillBreak(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_0:getSkillLevelByID(var_0_10) > 0 then
		return
	end

	var_0_3.super.checkSkillBreak(arg_7_0, arg_7_1, arg_7_2)
end

function var_0_3.applySingleUnit(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_1.skillID
	local var_8_1 = arg_8_1.target
	local var_8_2 = var_0_3.super.getDHuJia

	if arg_8_0:getSkillLevelByID(var_0_10) > 0 and (var_8_0 == var_0_13 or var_8_0 == arg_8_0.EnergySkillID or var_8_0 == var_0_9 or var_8_0 == arg_8_0:getPugongID()) then
		function arg_8_0.getDHuJia(arg_9_0)
			return var_0_3.super.getDHuJia(arg_9_0) + arg_8_1.target:getHuJia() * (var_0_14 + arg_9_0:getSkillLevelByID(var_0_10) * var_0_15)
		end
	end

	if var_8_0 == arg_8_0.EnergySkillID then
		arg_8_0:flipX(not var_8_1:flipX())
		arg_8_0:x(var_8_1:getX() + (var_8_1:getFlipX() and -50 or 50))
		arg_8_0:y(var_8_1:getY())
		arg_8_0:createSkillByID(arg_8_0.Energy2ndPhaseSkill, arg_8_0:getSkillLevelByID(arg_8_0.EnergySkillID), var_0_5:attackIndex(arg_8_0.Energy2ndPhaseSkill))
	elseif var_8_0 == var_0_12 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_8_3 = {}

			for iter_8_0, iter_8_1 in ipairs(arg_8_0.targetTeam_) do
				if not iter_8_1:isDeath() and not iter_8_1:isAffected() and (arg_8_0:getX() < iter_8_1:getX() and iter_8_1:getX() < var_8_1:getX() or var_8_1:getX() < iter_8_1:getX() and iter_8_1:getX() < arg_8_0:getX()) then
					table.insert(var_8_3, iter_8_1)
				end
			end

			local var_8_4 = arg_8_0:createAttackUnits(var_8_3, var_0_13)

			for iter_8_2, iter_8_3 in ipairs(var_8_4) do
				table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
				table.insert(arg_8_0.records_.special_units, iter_8_3)
			end
		end

		arg_8_0:flipX(not var_8_1:flipX())
		arg_8_0:x(var_8_1:getX() + (var_8_1:getFlipX() and -50 or 50))
		arg_8_0:y(var_8_1:getY())
	end

	var_0_3.super.applySingleUnit(arg_8_0, arg_8_1)

	arg_8_0.getDHuJia = var_8_2

	if (var_0_5:father(arg_8_1.skillID) == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or var_0_5:father(arg_8_1.skillID) == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) or var_0_5:father(arg_8_1.skillID) == arg_8_0:getEnergySkillID()) and arg_8_0.skinSkillID_ == var_0_16 then
		local var_8_5 = arg_8_0:createNewBuffs({
			var_0_17
		}, arg_8_1.target, var_0_16)

		arg_8_1.target:addBuffs(var_8_5)
	end
end

function var_0_3.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	if arg_10_0.extraSkillLevel > 0 and arg_10_1.skillID ~= arg_10_0:getPugongID() then
		local var_10_0 = arg_10_0.extraSkillLevel * var_0_8:attrValues(var_0_11) * 0.01
		local var_10_1 = arg_10_1.basicHarm * var_10_0

		arg_10_1.target:updateHp(arg_10_1.target:getHp() - var_10_1)
	end

	if arg_10_4 > 0 and arg_10_0.skinSkillID_ == var_0_16 then
		local var_10_2 = arg_10_1.target:getBuffs()

		for iter_10_0, iter_10_1 in ipairs(var_10_2) do
			if iter_10_1:getAttrType() == var_0_2.AttributeType.HUJIA and iter_10_1:getAttr() < 0 then
				arg_10_4 = arg_10_4 * (1 + var_0_18)

				break
			end
		end
	end

	return var_0_3.super.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
end

return var_0_3
