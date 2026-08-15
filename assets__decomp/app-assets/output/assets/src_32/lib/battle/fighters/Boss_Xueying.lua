local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xueying", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_8 = var_0_2.tables.cabinetSkillTable
local var_0_9 = 50010215
local var_0_10 = 20020215
local var_0_11 = 30010215
local var_0_12 = 40010215
local var_0_13 = 20100006
local var_0_14 = 10001491
local var_0_15 = 10001492
local var_0_16 = 10001490
local var_0_17 = 0.1
local var_0_18 = 0.002

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.greenTargets = {}
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if not arg_2_0.extraSkillJudge then
		arg_2_0.extraSkillJudge = true
		arg_2_0.extraSkillLevel = arg_2_0.hero_:skillBook()[tostring(var_0_13)] or 0
	end

	if arg_2_0:getLeftInterval() <= 0 then
		arg_2_0.greenTargets = {}
	end
end

function var_0_3.selectTargetByTypeD2(arg_3_0, arg_3_1, arg_3_2)
	for iter_3_0, iter_3_1 in ipairs(arg_3_0.targetTeam_) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() and not arg_3_0.greenTargets[iter_3_1] then
			arg_3_0.greenTargets[iter_3_1] = true

			return {
				iter_3_1
			}
		end
	end

	return {}
end

function var_0_3.unitAfterCreate(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_2 and next(arg_4_2) and arg_4_2[1].skillID == var_0_10 then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0.targetTeam_) do
			if not iter_4_1:isDeath() and not iter_4_1:isAffected() and not arg_4_0.greenTargets[iter_4_1] then
				arg_4_0:createSkillByID(var_0_10, arg_4_0:getSkillLevelByID(var_0_10), var_0_5:attackIndex(var_0_10))

				return
			end
		end
	end

	arg_4_0.greenTargets = {}
end

function var_0_3.selectTargetByTypeD3(arg_5_0, arg_5_1, arg_5_2)
	return var_0_7.B17(arg_5_0, arg_5_1)
end

function var_0_3.checkSkillBreak(arg_6_0, arg_6_1, arg_6_2)
	if arg_6_0:getSkillLevelByID(var_0_12) > 0 then
		return
	end

	var_0_3.super.checkSkillBreak(arg_6_0, arg_6_1, arg_6_2)
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_1.skillID
	local var_7_1 = arg_7_1.target
	local var_7_2 = var_0_3.super.getDHuJia

	if arg_7_0:getSkillLevelByID(var_0_12) > 0 and (var_7_0 == var_0_16 or var_7_0 == var_0_9 or var_7_0 == var_0_11 or var_7_0 == arg_7_0:getPugongID()) then
		function arg_7_0.getDHuJia(arg_8_0)
			return var_0_3.super.getDHuJia(arg_8_0) + arg_7_1.target:getHuJia() * (var_0_17 + arg_8_0:getSkillLevelByID(var_0_12) * var_0_18)
		end
	end

	if var_7_0 == var_0_9 then
		arg_7_0:flipX(not var_7_1:flipX())
		arg_7_0:x(var_7_1:getX() + (var_7_1:getFlipX() and -50 or 50))
		arg_7_0:y(var_7_1:getY())
		arg_7_0:createSkillByID(var_0_14, arg_7_0:getSkillLevelByID(var_0_9), var_0_5:attackIndex(var_0_14))
	elseif var_7_0 == var_0_15 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_7_3 = {}

			for iter_7_0, iter_7_1 in ipairs(arg_7_0.targetTeam_) do
				if not iter_7_1:isDeath() and not iter_7_1:isAffected() and (arg_7_0:getX() < iter_7_1:getX() and iter_7_1:getX() < var_7_1:getX() or var_7_1:getX() < iter_7_1:getX() and iter_7_1:getX() < arg_7_0:getX()) then
					table.insert(var_7_3, iter_7_1)
				end
			end

			local var_7_4 = arg_7_0:createAttackUnits(var_7_3, var_0_16)

			for iter_7_2, iter_7_3 in ipairs(var_7_4) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
				table.insert(arg_7_0.records_.special_units, iter_7_3)
			end
		end

		arg_7_0:flipX(not var_7_1:flipX())
		arg_7_0:x(var_7_1:getX() + (var_7_1:getFlipX() and -50 or 50))
		arg_7_0:y(var_7_1:getY())
	end

	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	arg_7_0.getDHuJia = var_7_2
end

function var_0_3.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	if arg_9_0.extraSkillLevel > 0 and arg_9_1.skillID ~= arg_9_0:getPugongID() then
		local var_9_0 = arg_9_0.extraSkillLevel * var_0_8:attrValues(var_0_13) * 0.01

		arg_9_4 = arg_9_4 + arg_9_1.basicHarm * var_9_0
	end

	return var_0_3.super.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
end

return var_0_3
