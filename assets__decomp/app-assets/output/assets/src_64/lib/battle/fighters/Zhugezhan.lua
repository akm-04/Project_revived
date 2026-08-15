local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhugezhan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.model
local var_0_8 = 0.15
local var_0_9 = 0
local var_0_10 = 494
local var_0_11 = 40011364
local var_0_12 = 0.5
local var_0_13 = 0.8
local var_0_14 = 1050
local var_0_15 = 10001299
local var_0_16 = 30

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleCollectHp_ = 0
	arg_1_0.purpleCount = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
			if not iter_2_1:isDeath() and iter_2_1:isHasBuffByID(var_0_11) then
				local var_2_0 = iter_2_1:getBuffByID(var_0_11)
				local var_2_1 = var_2_0.leftCount_ / var_2_0:getTime()

				var_2_0:getDHarm()

				var_2_0.dHarm_ = math.min(var_2_0:totalDHarm() * var_2_1, var_2_0.dHarm_)
			end
		end
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_2_0.purpleCount = arg_2_0.purpleCount - 1
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getEnergySkillID() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_0 = arg_3_0:selectTargetByTypeD1(arg_3_1.target)
		local var_3_1 = arg_3_0:createAttackUnits(var_3_0, var_0_15)

		for iter_3_0, iter_3_1 in ipairs(var_3_1) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end
	end
end

function var_0_3.updateHp(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = arg_4_0:getHp()

	var_0_3.super.updateHp(arg_4_0, arg_4_1, arg_4_2)

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_4_0:isDeath() and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_4_1 = arg_4_0:getHp()

		if var_4_1 < var_4_0 then
			arg_4_0.purpleCollectHp_ = arg_4_0.purpleCollectHp_ + var_4_0 - var_4_1

			if arg_4_0.purpleCount < 1 and arg_4_0.purpleCollectHp_ >= arg_4_0:getHpLimit() * var_0_13 then
				arg_4_0.purpleCollectHp_ = arg_4_0.purpleCollectHp_ % (arg_4_0:getHpLimit() * var_0_13)

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_4_2 = arg_4_0:createAttackUnits({
						arg_4_0
					}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

					for iter_4_0, iter_4_1 in ipairs(var_4_2) do
						table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
						table.insert(arg_4_0.records_.special_units, iter_4_1)
					end
				end

				arg_4_0.purpleCount = var_0_14
			end
		end
	end
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	var_0_3.super.buffAddAction(arg_5_0, arg_5_1)

	if arg_5_1:getTableID() == var_0_11 then
		arg_5_1.manualDharm = (arg_5_1.target:getHpLimit() - arg_5_1.target:getHp()) * var_0_12
	end

	return isShanbi, isBaoji, harm, cure, xixue, mp
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_4 > 0 and (arg_6_1.skillID == arg_6_0:getEnergySkillID() or arg_6_1.skillID == var_0_15) then
		arg_6_4 = math.min(arg_6_4 + arg_6_1.target:getHp() * var_0_8, var_0_9 + arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * var_0_10)
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.selectTargetByTypeD1(arg_7_0, arg_7_1)
	local var_7_0 = {}
	local var_7_1 = var_0_5:scope(var_0_15)

	if arg_7_1 then
		for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
			if not iter_7_1:isDeath() and not iter_7_1:isAffected() and math.abs(iter_7_1:getX() - arg_7_1:getX()) <= var_7_1 / 2 and iter_7_1 ~= arg_7_1 then
				table.insert(var_7_0, iter_7_1)
			end
		end
	end

	return var_7_0
end

return var_0_3
