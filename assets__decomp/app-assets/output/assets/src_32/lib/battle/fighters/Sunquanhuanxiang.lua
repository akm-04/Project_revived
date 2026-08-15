local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Sunquanhuanxiang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_2.tables.skill
local var_0_6
local var_0_7 = 40010056
local var_0_8 = 60010056
local var_0_9 = 10000181
local var_0_10 = 0.05

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.extraHarm = nil
	arg_1_0.awakenLevel_ = nil
	arg_1_0.awakenSkillTimes_ = 3
	arg_1_0.extraHp_ = 0
	arg_1_0.skinCureType_ = false
end

function var_0_3.getExtraHarm(arg_2_0)
	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 then
		return 0
	end

	if not arg_2_0.extraHarm and arg_2_0.summoner then
		arg_2_0.extraHarm = var_0_5:init(var_0_9) + var_0_5:step(var_0_9) * arg_2_0.summoner:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
	end

	return arg_2_0.extraHarm or 0
end

function var_0_3.getAwakenLevel(arg_3_0)
	if not arg_3_0.awakenLevel_ and arg_3_0.summoner then
		arg_3_0.awakenLevel_ = arg_3_0.summoner:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
	end

	return arg_3_0.awakenLevel_ or 0
end

function var_0_3.getMp(arg_4_0)
	if not arg_4_0.mp_ then
		arg_4_0.mp_ = var_0_5:mp(var_0_8) + var_0_5:mpStep(var_0_8) * arg_4_0:getAwakenLevel()
	end

	return arg_4_0.mp_
end

function var_0_3.calculateUnitData(arg_5_0, arg_5_1)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.calculateUnitData(arg_5_0, arg_5_1)
	local var_5_6 = arg_5_1.target

	if arg_5_1.skillID == var_0_7 then
		local var_5_7 = 0

		for iter_5_0, iter_5_1 in ipairs(var_0_1.ctx.battle.teamA) do
			if not iter_5_1:isDeath() and iter_5_1:getSummonType() == 0 then
				var_5_7 = var_5_7 + 1
			end
		end

		for iter_5_2, iter_5_3 in ipairs(var_0_1.ctx.battle.teamB) do
			if not iter_5_3:isDeath() and iter_5_3:getSummonType() == 0 then
				var_5_7 = var_5_7 + 1
			end
		end

		if var_5_7 <= 10 and var_5_2 > 0 then
			var_5_2 = var_5_2 + (10 - var_5_7) * arg_5_0:getExtraHarm()
		end

		if var_5_2 > 0 and arg_5_0:getAwakenLevel() > 0 and arg_5_0.awakenSkillTimes_ > 0 then
			if var_5_6.__cname ~= "Sunquan" then
				var_5_5 = var_5_5 + arg_5_0:getMp()
			end

			arg_5_0.awakenSkillTimes_ = arg_5_0.awakenSkillTimes_ - 1
		end
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.checkKilling(arg_6_0, arg_6_1)
	if arg_6_0.summoner and not arg_6_0.summoner:isDeath() then
		arg_6_0.summoner:checkKilling()
	end
end

function var_0_3.setExtraSkillHp(arg_7_0, arg_7_1)
	arg_7_0.extraHp_ = arg_7_1
end

function var_0_3.getHpLimit(arg_8_0)
	return var_0_3.super.getHpLimit(arg_8_0) + arg_8_0.extraHp_
end

function var_0_3.setSkinCureType(arg_9_0, arg_9_1)
	arg_9_0.skinCureType_ = arg_9_1
end

function var_0_3.die(arg_10_0)
	if arg_10_0.skinCureType_ and not arg_10_0.summoner:isDeath() and not arg_10_0.summoner:isAffected() then
		local var_10_0 = arg_10_0.summoner:getHpLimit() * arg_10_0.summoner:getDCureRate() * var_0_10

		arg_10_0.summoner:updateHp(arg_10_0.summoner:getHp() + var_10_0)
	end

	return var_0_3.super.die(arg_10_0)
end

return var_0_3
