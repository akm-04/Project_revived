local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ZhangliangCoil", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 10000831
local var_0_5 = 90
local var_0_6 = 10
local var_0_7 = {
	"Zhangliang",
	"Zhangliang_Awaken"
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.addBuffTimeCount_ = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() or not arg_2_0.summoner or arg_2_0.summoner:isDeath() or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType or not arg_2_0.summoner:getNearestTarget() then
		return
	end

	arg_2_0.addBuffTimeCount_ = arg_2_0.addBuffTimeCount_ - 1

	if arg_2_0.addBuffTimeCount_ <= 0 then
		arg_2_0.addBuffTimeCount_ = var_0_5

		local var_2_0 = arg_2_0:createAttackUnits({
			arg_2_0.summoner
		}, var_0_4)

		for iter_2_0, iter_2_1 in ipairs(var_2_0) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == var_0_4 and arg_3_0.summoner and not arg_3_0.summoner:isDeath() and arg_3_0:checkSummonerIsZhangliang() then
		arg_3_0.summoner:updateChargeNum(var_0_6)
	end
end

function var_0_3.canAttack(arg_4_0)
	return false
end

function var_0_3.checkMove(arg_5_0)
	return false
end

function var_0_3.checkSummonerIsZhangliang(arg_6_0)
	local var_6_0 = arg_6_0.summoner.hero_:className()

	if var_6_0 == var_0_7[1] or var_6_0 == var_0_7[2] then
		return true
	end

	return false
end

return var_0_3
