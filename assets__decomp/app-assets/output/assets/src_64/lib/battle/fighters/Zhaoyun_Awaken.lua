local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhaoyun", var_0_1.ctx.battle.requireFighter("Zhaoyun"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.battleConfig
local var_0_6 = 10000127
local var_0_7 = 10000139
local var_0_8 = 0
local var_0_9 = 2
local var_0_10 = {
	40010936,
	40010937
}
local var_0_11 = 0.4

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isUseHpAddBuff_ = false
	arg_1_0.isHasAddAwakeTwiceBuff = false
end

function var_0_3.getDHuJiaNum(arg_2_0)
	if not arg_2_0.dHujia_ then
		arg_2_0.dHujia_ = var_0_8 + var_0_9 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
	end

	return arg_2_0.dHujia_
end

function var_0_3.setDHujia(arg_3_0, arg_3_1)
	if arg_3_1 then
		arg_3_0.dHujia_ = arg_3_1
	else
		arg_3_0.dHujia_ = var_0_8 + var_0_9 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
	end

	return arg_3_0.dHujia_
end

function var_0_3.calculateUnitData(arg_4_0, arg_4_1)
	if arg_4_1.skillID == var_0_7 then
		arg_4_0:setDHujia()
	end

	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.calculateUnitData(arg_4_0, arg_4_1)

	arg_4_0:setDHujia(0)

	if arg_4_1.skillID == var_0_7 and var_4_1 ~= true then
		var_4_2 = var_4_2 * (arg_4_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_4_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
		var_4_4 = var_4_4 * (arg_4_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_4_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
		var_4_1 = true
	elseif arg_4_1.skillID == var_0_6 and var_4_1 == true then
		var_4_2 = var_4_2 / (arg_4_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_4_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
		var_4_4 = var_4_4 / (arg_4_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_4_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
		var_4_1 = false
	end

	if arg_4_1.skillID == var_0_6 or arg_4_1.skillID == var_0_7 then
		arg_4_0.baoji_ = false
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.getDHuJia(arg_5_0)
	return var_0_3.super.getDHuJia(arg_5_0) + arg_5_0:getDHuJiaNum()
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_6_1.rootID_ == arg_6_0:getEnergySkillID() then
		arg_6_0:addAwakeTwiceBuff()
	end
end

function var_0_3.updateHp(arg_7_0, arg_7_1, arg_7_2)
	var_0_3.super.updateHp(arg_7_0, arg_7_1, arg_7_2)

	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and not arg_7_0.isUseHpAddBuff_ and arg_7_0:getHp() / arg_7_0:getHpLimit() <= var_0_11 then
		arg_7_0.isUseHpAddBuff_ = true

		arg_7_0:addAwakeTwiceBuff()
	end
end

function var_0_3.addAwakeTwiceBuff(arg_8_0)
	local var_8_0 = var_0_10[1]

	if arg_8_0.isHasAddAwakeTwiceBuff then
		var_8_0 = var_0_10[2]
	end

	local var_8_1 = arg_8_0:newBuff({
		var_8_0
	}, arg_8_0, arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

	arg_8_0:addBuffs(var_8_1)

	arg_8_0.isHasAddAwakeTwiceBuff = true
end

function var_0_3.newBuff(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_1) do
		local var_9_1 = var_0_4.new({
			tableID = iter_9_1,
			start = var_0_1.ctx.battle.count,
			level = arg_9_0:getSkillLevelByID(arg_9_3),
			skillID = arg_9_3,
			fighter = arg_9_0,
			target = arg_9_2
		})

		var_9_1:setIsHit(true)
		var_9_1:setDirection(arg_9_0:getFighterModel():getFlipX())
		table.insert(var_9_0, var_9_1)
	end

	return var_9_0
end

return var_0_3
