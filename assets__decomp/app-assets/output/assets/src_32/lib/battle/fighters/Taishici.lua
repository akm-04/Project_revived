local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Taishici", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.dbuff
local var_0_5 = var_0_2.tables.hero
local var_0_6 = var_0_2.tables.skinSkill
local var_0_7 = 10350005
local var_0_8 = 0.005
local var_0_9 = 0.005
local var_0_10 = 6000
local var_0_11 = var_0_2.tables.cabinetSkillTable
local var_0_12 = 3

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
	arg_1_0.skinSkillBaojiHarmUp_ = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillBaojiHarmUp_ < var_0_12 and var_0_1.ctx.battle.count % 30 < 1 then
		arg_2_0.skinSkillBaojiHarmUp_ = math.min(var_0_12, arg_2_0.skinSkillBaojiHarmUp_ + 0.1)
	end

	if not arg_2_0.extraSkillJudge then
		arg_2_0.extraSkillJudge = true
		arg_2_0.extraSkillLevel = arg_2_0.hero_:skillBook()[tostring(var_0_7)] or 0
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if arg_3_0.extraSkillLevel > 0 and arg_3_0:isInTrouble(arg_3_1.target) then
		local var_3_0 = arg_3_1.target
		local var_3_1 = var_3_0:getHpLimit() * var_0_11:attrValues(var_0_7) * arg_3_0.extraSkillLevel * 0.01
		local var_3_2 = var_3_1 * var_3_1 / (var_3_1 + 8 * math.max(var_3_0:getHuJia() - arg_3_0:getDHuJia(), 0)) * var_3_0:getADJianShang()

		arg_3_4 = arg_3_4 + math.min(var_3_2, var_0_10)
	end

	if arg_3_3 then
		arg_3_4 = arg_3_4 * (1 + arg_3_0.skinSkillBaojiHarmUp_)
	end

	return var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
end

function var_0_3.isInTrouble(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1:getBuffs()

	for iter_4_0, iter_4_1 in ipairs(var_4_0) do
		if iter_4_1:isAdUnable() and iter_4_1:isApUnable() or var_0_4:attr(iter_4_1:getTableID()) == var_0_2.AttributeType.SPEED and (var_0_4:init(iter_4_1:getTableID()) < 0 or var_0_4:step(iter_4_1:getTableID()) < 0) then
			return true
		end
	end

	return false
end

return var_0_3
