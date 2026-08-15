local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ElementSunce", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = 80020032

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.baojiHarmCount_ = 0
	arg_1_0.baojiHarmNum_ = 0
end

function var_0_3.applyHurtFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5)
	local var_2_0, var_2_1, var_2_2, var_2_3 = var_0_3.super.applyHurtFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5)

	if arg_2_1.attackType == var_0_2.AttackType.AD and var_2_2 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_2_0.baojiHarmNum_ = arg_2_0.baojiHarmNum_ + var_2_0
		arg_2_0.baojiHarmCount_ = arg_2_0.baojiHarmCount_ + 1

		if arg_2_0.baojiHarmCount_ == 3 then
			arg_2_0.baojiHarmCount_ = 0

			local var_2_4 = arg_2_0:getMostHpTarget()
			local var_2_5 = arg_2_0:createAttackUnits(var_2_4, var_0_4)

			for iter_2_0, iter_2_1 in ipairs(var_2_5) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
				table.insert(arg_2_0.records_.special_units, iter_2_1)
			end
		end
	end

	return var_2_0, var_2_1, var_2_2, var_2_3
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_1.skillID == var_0_4 then
		var_3_2 = var_3_2 + arg_3_0.baojiHarmNum_
		arg_3_0.baojiHarmNum_ = 0
	end

	return var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5
end

function var_0_3.getMostHpTarget(arg_4_0)
	local var_4_0
	local var_4_1

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() then
			local var_4_2 = iter_4_1:getHp() / iter_4_1:getHpLimit()

			if not var_4_1 or var_4_1 < var_4_2 then
				var_4_1 = var_4_2
				var_4_0 = iter_4_1
			end
		end
	end

	return {
		var_4_0
	}
end

return var_0_3
