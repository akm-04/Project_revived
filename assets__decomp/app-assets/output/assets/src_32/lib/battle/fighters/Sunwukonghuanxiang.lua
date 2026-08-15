local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Sunwukonghuanxiang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 1
local var_0_5 = 20
local var_0_6 = 0.5
local var_0_7 = 10
local var_0_8 = 80010052
local var_0_9 = 10002027

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.leftCount_ = 15 * var_0_1.ctx.battleConst.frames
	arg_1_0.extraHp_ = 0
end

function var_0_3.updateBaseInfo(arg_2_0)
	var_0_3.super.updateBaseInfo(arg_2_0)

	arg_2_0.leftCount_ = arg_2_0.leftCount_ - 1

	if arg_2_0.leftCount_ < 1 and not arg_2_0:isDeath() then
		arg_2_0:updateHp(0)
		arg_2_0:die()
	end
end

function var_0_3.getShanBi(arg_3_0)
	return var_0_5 + var_0_4 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)
end

function var_0_3.getAD(arg_4_0)
	if arg_4_0.summoner then
		return arg_4_0.summoner:getAD() * var_0_6
	end

	return var_0_3.super.getAD(arg_4_0)
end

function var_0_3.getHpLimit(arg_5_0)
	if arg_5_0.hero_:isAwaken() then
		return var_0_3.super.getHpLimit(arg_5_0) + arg_5_0.extraHp_
	else
		return var_0_7 + arg_5_0.extraHp_
	end
end

function var_0_3.setExtraSkillHp(arg_6_0, arg_6_1)
	arg_6_0.extraHp_ = arg_6_0.extraHp_ + arg_6_1
end

function var_0_3.die(arg_7_0)
	var_0_3.super.die(arg_7_0)

	if arg_7_0:isDeath() and arg_7_0.summoner.skinSkillID_ == var_0_8 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_7_0 = arg_7_0:createAttackUnits({
			arg_7_0.killer_
		}, var_0_9)

		for iter_7_0, iter_7_1 in ipairs(var_7_0) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
			table.insert(arg_7_0.records_.special_units, iter_7_1)
		end
	end
end

return var_0_3
