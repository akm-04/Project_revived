local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangjiao", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 0
local var_0_6 = 0.0007
local var_0_7 = 10000
local var_0_8 = 5
local var_0_9 = 81111004
local var_0_10 = 40011075
local var_0_11 = 3
local var_0_12 = 10000988
local var_0_13 = 10000987
local var_0_14 = 20001442

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeTwiceTargets_ = {}
	arg_1_0.count_ = false
	arg_1_0.skinMarkTargets_ = {}
	arg_1_0.isCleanMarkBuff_ = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	if not arg_2_0.count_ and arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		arg_2_0.count_ = true

		local var_2_0 = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)

		arg_2_0.awakeTwiceRateInit_ = var_0_4:descNumInit(var_2_0)[1] * 0.01
		arg_2_0.awakeTwiceRateStep_ = var_0_4:descNumStep(var_2_0)[1] * 0.01
	end

	if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_9 then
		local var_2_1 = 0

		for iter_2_0, iter_2_1 in pairs(arg_2_0.skinMarkTargets_) do
			if iter_2_1 and not iter_2_0:isDeath() and iter_2_0:isHasBuffByID(var_0_10) then
				var_2_1 = var_2_1 + 1
			end
		end

		if var_2_1 >= var_0_11 then
			arg_2_0:useSkinSkill()
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_1.skillID ~= arg_3_0:getPugongID() then
		local var_3_6 = (arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * var_0_6 + var_0_5) * arg_3_1.target:getHp()

		var_3_2 = var_3_2 + math.min(var_0_7, var_3_6)

		local var_3_7 = arg_3_0.awakeTwiceTargets_[arg_3_1.target]

		if var_3_7 and var_3_7 > 0 then
			var_3_2 = var_3_2 * (1 + var_3_7 * (arg_3_0.awakeTwiceRateStep_ * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) + arg_3_0.awakeTwiceRateInit_))
		end
	end

	return var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_4_1.skillID ~= arg_4_0:getPugongID() then
		local var_4_0 = arg_4_0.awakeTwiceTargets_[arg_4_1.target]

		if not var_4_0 then
			arg_4_0.awakeTwiceTargets_[arg_4_1.target] = 1
		else
			arg_4_0.awakeTwiceTargets_[arg_4_1.target] = var_4_0 + 1

			if var_4_0 + 1 == var_0_8 then
				arg_4_0.awakeTwiceTargets_[arg_4_1.target] = 0

				local var_4_1 = arg_4_0:createAttackUnits({
					arg_4_1.target
				}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

				for iter_4_0, iter_4_1 in ipairs(var_4_1) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
					table.insert(arg_4_0.records_.special_units, iter_4_1)
				end
			end
		end
	end

	if arg_4_0.isSkinSkillOn_ and arg_4_0.skinSkillID_ == var_0_9 and arg_4_1.skillID ~= var_0_12 and arg_4_1.skillID ~= var_0_13 and arg_4_1.target:getTeamType() ~= arg_4_0:getTeamType() and arg_4_1.skillID ~= arg_4_0:getPugongID() and not arg_4_1.target:isDeath() then
		local var_4_2 = arg_4_0:createNewBuffs({
			var_0_10
		}, arg_4_1.target, arg_4_0:getEnergySkillID())

		arg_4_1.target:addBuffs(var_4_2)
	end
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	var_0_3.super.buffAddAction(arg_5_0, arg_5_1)

	if arg_5_1:getTableID() == var_0_10 then
		arg_5_0.skinMarkTargets_[arg_5_1.target] = true
	end
end

function var_0_3.useSkinSkill(arg_6_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_0 = arg_6_0:getTargets(var_0_12)

		if next(var_6_0) then
			local var_6_1 = arg_6_0:createAttackUnits(var_6_0, var_0_12)

			for iter_6_0, iter_6_1 in ipairs(var_6_1) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
				table.insert(arg_6_0.records_.special_units, iter_6_1)
			end
		end

		local var_6_2 = arg_6_0:getTargets(var_0_13)

		if next(var_6_2) then
			local var_6_3 = arg_6_0:createAttackUnits(var_6_2, var_0_13)

			for iter_6_2, iter_6_3 in ipairs(var_6_3) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
				table.insert(arg_6_0.records_.special_units, iter_6_3)
			end
		end
	end

	for iter_6_4, iter_6_5 in pairs(arg_6_0.skinMarkTargets_) do
		if iter_6_5 and not iter_6_4:isDeath() then
			iter_6_4:removeBuffByID(var_0_10)
		end

		arg_6_0.skinMarkTargets_[iter_6_4] = false
	end
end

function var_0_3.energyDecimalBase(arg_7_0)
	if arg_7_0:hasElementEquipByID(var_0_14) then
		return var_0_2.ENERGY_DECIMAL_BASE * 0.5
	else
		return var_0_2.ENERGY_DECIMAL_BASE
	end
end

return var_0_3
