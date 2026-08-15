local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fantuan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 150
local var_0_6 = {
	10000331,
	10000332,
	10000333,
	10000334,
	10000335
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.leftCount_ = var_0_5
	arg_1_0.skill_ = var_0_6[os.time() % 5 + 1]
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)

	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.leftCount_ > 0 then
		arg_2_0.leftCount_ = arg_2_0.leftCount_ - 1

		if arg_2_0.leftCount_ < 1 or var_0_1.ctx.battle.teamBEnd then
			arg_2_0.leftCount_ = 0

			arg_2_0:updateHp(0)
			arg_2_0:die()
		end
	end

	arg_2_0:updateSkill()
end

function var_0_3.updateSkill(arg_3_0)
	if arg_3_0:isDeath() or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if var_0_1.ctx.battle.count % 30 > 0 then
		return
	end

	local var_3_0 = arg_3_0.skill_
	local var_3_1 = var_0_4:scope(var_3_0)
	local var_3_2 = {}

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
		if iter_3_1 ~= arg_3_0 and not iter_3_1:isDeath() and not iter_3_1:isAffected() and math.abs(iter_3_1:getX() - arg_3_0:getX()) < var_3_1 / 2 then
			table.insert(var_3_2, iter_3_1)
		end
	end

	local var_3_3 = arg_3_0:createAttackUnits(var_3_2, var_3_0)

	for iter_3_2, iter_3_3 in ipairs(var_3_3) do
		table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
		table.insert(arg_3_0.records_.special_units, iter_3_3)
	end
end

function var_0_3.canAttack(arg_4_0)
	return false
end

function var_0_3.applyBuffMoves(arg_5_0)
	return
end

function var_0_3.isBreakImmortal(arg_6_0)
	return true
end

function var_0_3.checkMove(arg_7_0)
	return
end

return var_0_3
