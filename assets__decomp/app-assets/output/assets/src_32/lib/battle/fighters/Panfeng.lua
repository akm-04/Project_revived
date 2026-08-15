local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Panfeng", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.cabinetSkillTable
local var_0_5 = 10010123
local var_0_6 = 150
local var_0_7 = 0
local var_0_8 = 100
local var_0_9 = 10400004

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energySkill_ = nil
	arg_1_0.deadCount_ = nil
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
	arg_1_0.currentSkillID_ = nil
	arg_1_0.addMokangRate = 0
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)

	if arg_2_0.deadCount_ and arg_2_0.deadCount_ > 0 then
		arg_2_0.deadCount_ = arg_2_0.deadCount_ - 1

		if arg_2_0.deadCount_ < 1 then
			arg_2_0:updateHp(0)
			arg_2_0:die()
		end
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if not arg_3_0.extraSkillJudge then
		arg_3_0.extraSkillJudge = true
		arg_3_0.extraSkillLevel = arg_3_0.hero_:skillBook()[tostring(var_0_9)] or 0
		arg_3_0.addMokangRate = arg_3_0.extraSkillLevel * var_0_4:attrValues(var_0_9) * 0.01
	end
end

function var_0_3.getMoKang(arg_4_0)
	local var_4_0 = var_0_3.super.getMoKang(arg_4_0)

	if arg_4_0.extraSkillLevel > 0 then
		var_4_0 = var_4_0 + arg_4_0:getHuJia() * arg_4_0.addMokangRate
	end

	return var_4_0
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	if arg_5_1:getTableID() == var_0_5 then
		arg_5_0.energySkill_ = true

		local var_5_0 = arg_5_0:getHp() + arg_5_0:getExtraHp()

		arg_5_0:updateHp(var_5_0)

		return
	end
end

function var_0_3.buffRemoveAction(arg_6_0, arg_6_1)
	if arg_6_1:getTableID() == var_0_5 then
		arg_6_0.energySkill_ = nil

		if arg_6_0:getHp() > arg_6_0:getHpLimit() then
			arg_6_0:updateHp(arg_6_0:getHpLimit())
		end
	end
end

function var_0_3.getHpLimit(arg_7_0)
	if arg_7_0.energySkill_ then
		return var_0_3.super.getHpLimit(arg_7_0) + arg_7_0:getExtraHp()
	end

	return var_0_3.super.getHpLimit(arg_7_0)
end

function var_0_3.getExtraHp(arg_8_0)
	if not arg_8_0.extraHp_ then
		arg_8_0.extraHp_ = var_0_7 + var_0_8 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
	end

	return arg_8_0.extraHp_
end

function var_0_3.updateHp(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_0.deadCount_ and arg_9_0.deadCount_ > 0 then
		return
	end

	if arg_9_1 < 1 and arg_9_0.energySkill_ and not arg_9_0.deadCount_ then
		arg_9_0.deadCount_ = var_0_6
		arg_9_1 = 1
	end

	var_0_3.super.updateHp(arg_9_0, arg_9_1, arg_9_2)
end

function var_0_3.isBreakImmortal(arg_10_0)
	if arg_10_0.deadCount_ and arg_10_0.deadCount_ > 0 then
		return true
	end

	return var_0_3.super.isBreakImmortal(arg_10_0)
end

function var_0_3.checkEnergySkill(arg_11_0)
	if arg_11_0.deadCount_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_11_0)
end

return var_0_3
