local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("CampWarBoss", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_2.tables.dbuff
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.model

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.hpIndex_ = 1
	arg_1_0.extraHpCount_ = 0
	arg_1_0.campExtraHpCount_ = 0
end

function var_0_3.getAD(arg_2_0)
	return var_0_2.tables.battleConfig.elementBossBuffRate * (arg_2_0.hpIndex_ + arg_2_0.extraHpCount_ + arg_2_0.campExtraHpCount_) * arg_2_0.hero_:getBattleAttr(var_0_2.AttributeType.AD) + var_0_3.super.getAD(arg_2_0) - arg_2_0.hero_:getBattleAttr(var_0_2.AttributeType.AD)
end

function var_0_3.getAP(arg_3_0)
	return var_0_2.tables.battleConfig.elementBossBuffRate * (arg_3_0.hpIndex_ + arg_3_0.extraHpCount_ + arg_3_0.campExtraHpCount_) * arg_3_0.hero_:getBattleAttr(var_0_2.AttributeType.AP) + var_0_3.super.getAP(arg_3_0) - arg_3_0.hero_:getBattleAttr(var_0_2.AttributeType.AP)
end

function var_0_3.updateExtrHpCount(arg_4_0)
	local var_4_0 = var_0_2.tables.misc.campWarBattlePara1
	local var_4_1 = var_0_2.tables.misc.campWarBattlePara1
	local var_4_2 = var_0_2.tables.misc.campWarBattleTime

	if var_0_1.ctx.battle.count % var_4_2 ~= 0 then
		return
	end

	local var_4_3 = math.floor(var_0_1.ctx.battle.count / 30) * var_4_0 + var_4_1

	if var_4_3 * var_4_3 > arg_4_0.hpIndex_ then
		arg_4_0.extraHpCount_ = arg_4_0.extraHpCount_ + 1
	end

	if arg_4_0.hpIndex_ > 10 then
		arg_4_0.campExtraHpCount_ = arg_4_0.hpIndex_ - 10
	end
end

return var_0_3
