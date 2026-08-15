local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangjiao", var_0_1.ctx.battle.requireFighter("HideBoss"))
local var_0_4 = 81111004
local var_0_5 = 40011075
local var_0_6 = 3
local var_0_7 = 10000988
local var_0_8 = 10000987

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.skinMarkTargets_ = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_4 then
		local var_2_0 = 0

		for iter_2_0, iter_2_1 in pairs(arg_2_0.skinMarkTargets_) do
			if iter_2_1 and not iter_2_0:isDeath() and iter_2_0:isHasBuffByID(var_0_5) then
				var_2_0 = var_2_0 + 1
			end
		end

		if var_2_0 >= var_0_6 then
			arg_2_0:useSkinSkill()
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_4 and arg_3_1.skillID ~= var_0_7 and arg_3_1.skillID ~= var_0_8 and arg_3_1.target:getTeamType() ~= arg_3_0:getTeamType() and arg_3_1.skillID ~= arg_3_0:getPugongID() and not arg_3_1.target:isDeath() then
		local var_3_0 = arg_3_0:createNewBuffs({
			var_0_5
		}, arg_3_1.target, arg_3_0:getEnergySkillID())

		arg_3_1.target:addBuffs(var_3_0)
	end
end

function var_0_3.buffAddAction(arg_4_0, arg_4_1)
	var_0_3.super.buffAddAction(arg_4_0, arg_4_1)

	if arg_4_1:getTableID() == var_0_5 then
		arg_4_0.skinMarkTargets_[arg_4_1.target] = true
	end
end

function var_0_3.useSkinSkill(arg_5_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_0 = arg_5_0:getTargets(var_0_7)

		if next(var_5_0) then
			local var_5_1 = arg_5_0:createAttackUnits(var_5_0, var_0_7)

			for iter_5_0, iter_5_1 in ipairs(var_5_1) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
				table.insert(arg_5_0.records_.special_units, iter_5_1)
			end
		end

		local var_5_2 = arg_5_0:getTargets(var_0_8)

		if next(var_5_2) then
			local var_5_3 = arg_5_0:createAttackUnits(var_5_2, var_0_8)

			for iter_5_2, iter_5_3 in ipairs(var_5_3) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
				table.insert(arg_5_0.records_.special_units, iter_5_3)
			end
		end
	end

	for iter_5_4, iter_5_5 in pairs(arg_5_0.skinMarkTargets_) do
		if iter_5_5 and not iter_5_4:isDeath() then
			iter_5_4:removeBuffByID(var_0_5)
		end

		arg_5_0.skinMarkTargets_[iter_5_4] = false
	end
end

return var_0_3
