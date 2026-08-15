local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("ActivityFishTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.rarity_ = {}
	arg_1_0.minW_ = {}
	arg_1_0.maxW_ = {}
	arg_1_0.price_ = {}
	arg_1_0.exp_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.desc2_ = {}
	arg_1_0.hp_ = {}
	arg_1_0.atk_ = {}
	arg_1_0.def_ = {}
	arg_1_0.spd_ = {}
	arg_1_0.crt_ = {}
	arg_1_0.evd_ = {}
	arg_1_0.attr_ = {}
	arg_1_0.defScore_ = {}
	arg_1_0.atkScore_ = {}
	arg_1_0.score_ = {}
	arg_1_0.leiming_ = {}
	arg_1_0.skill_ = {}
	arg_1_0.skillDesc_ = {}
	arg_1_0.model_ = {}
	arg_1_0.scale_ = {}
	arg_1_0.buffTexiao_ = {}
	arg_1_0.buffTiaozheng_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("activity_fish.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("activity_fish", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.id)

	arg_2_0.name_[var_2_0] = arg_2_1.name
	arg_2_0.rarity_[var_2_0] = tonumber(arg_2_1.rarity)
	arg_2_0.minW_[var_2_0] = tonumber(arg_2_1.min_w)
	arg_2_0.maxW_[var_2_0] = tonumber(arg_2_1.max_w)
	arg_2_0.price_[var_2_0] = tonumber(arg_2_1.price)
	arg_2_0.exp_[var_2_0] = tonumber(arg_2_1.exp)
	arg_2_0.desc_[var_2_0] = arg_2_1.desc
	arg_2_0.desc2_[var_2_0] = arg_2_1.desc2
	arg_2_0.hp_[var_2_0] = tonumber(arg_2_1.hp)
	arg_2_0.atk_[var_2_0] = tonumber(arg_2_1.atk)
	arg_2_0.def_[var_2_0] = tonumber(arg_2_1.def)
	arg_2_0.spd_[var_2_0] = tonumber(arg_2_1.spd)
	arg_2_0.crt_[var_2_0] = tonumber(arg_2_1.crt)
	arg_2_0.evd_[var_2_0] = tonumber(arg_2_1.evd)
	arg_2_0.defScore_[var_2_0] = tonumber(arg_2_1.def_score)
	arg_2_0.atkScore_[var_2_0] = tonumber(arg_2_1.atk_score)
	arg_2_0.score_[var_2_0] = tonumber(arg_2_1.score)
	arg_2_0.leiming_[var_2_0] = arg_2_1.leiming
	arg_2_0.skill_[var_2_0] = arg_2_1.skill
	arg_2_0.skillDesc_[var_2_0] = arg_2_1.skill_desc
	arg_2_0.model_[var_2_0] = arg_2_1.model
	arg_2_0.scale_[var_2_0] = tonumber(arg_2_1.scale)
	arg_2_0.buffTexiao_[var_2_0] = arg_2_1.buff_texiao
	arg_2_0.buffTiaozheng_[var_2_0] = var_0_1.splitToNumber(arg_2_1.buff_tiaozheng, "|")
	arg_2_0.attr_[var_2_0] = {}
	arg_2_0.attr_[var_2_0][var_0_1.FishAttributeType.HP] = tonumber(arg_2_1.hp)
	arg_2_0.attr_[var_2_0][var_0_1.FishAttributeType.AD] = tonumber(arg_2_1.atk)
	arg_2_0.attr_[var_2_0][var_0_1.FishAttributeType.HUJIA] = tonumber(arg_2_1.def)
	arg_2_0.attr_[var_2_0][var_0_1.FishAttributeType.SPEED] = tonumber(arg_2_1.spd)
	arg_2_0.attr_[var_2_0][var_0_1.FishAttributeType.BAOJI] = tonumber(arg_2_1.crt) / 100
	arg_2_0.attr_[var_2_0][var_0_1.FishAttributeType.SHANBI] = tonumber(arg_2_1.evd) / 100
end

function var_0_2.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_2.rarity(arg_4_0, arg_4_1)
	return arg_4_0.rarity_[arg_4_1] or 0
end

function var_0_2.minW(arg_5_0, arg_5_1)
	return arg_5_0.minW_[arg_5_1] or 0
end

function var_0_2.maxW(arg_6_0, arg_6_1)
	return arg_6_0.maxW_[arg_6_1] or 0
end

function var_0_2.price(arg_7_0, arg_7_1)
	return arg_7_0.price_[arg_7_1] or 0
end

function var_0_2.exp(arg_8_0, arg_8_1)
	return arg_8_0.exp_[arg_8_1] or 0
end

function var_0_2.desc(arg_9_0, arg_9_1)
	return arg_9_0.desc_[arg_9_1] or ""
end

function var_0_2.desc2(arg_10_0, arg_10_1)
	return arg_10_0.desc2_[arg_10_1] or ""
end

function var_0_2.hp(arg_11_0, arg_11_1)
	return arg_11_0.hp_[arg_11_1] or 0
end

function var_0_2.atk(arg_12_0, arg_12_1)
	return arg_12_0.atk_[arg_12_1] or 0
end

function var_0_2.def(arg_13_0, arg_13_1)
	return arg_13_0.def_[arg_13_1] or 0
end

function var_0_2.spd(arg_14_0, arg_14_1)
	return arg_14_0.spd_[arg_14_1] or 0
end

function var_0_2.crt(arg_15_0, arg_15_1)
	return arg_15_0.crt_[arg_15_1] or 0
end

function var_0_2.evd(arg_16_0, arg_16_1)
	return arg_16_0.evd_[arg_16_1] or 0
end

function var_0_2.attr(arg_17_0, arg_17_1, arg_17_2)
	return arg_17_0.attr_[arg_17_1][arg_17_2] or 0
end

function var_0_2.defScore(arg_18_0, arg_18_1)
	return arg_18_0.defScore_[arg_18_1] or 0
end

function var_0_2.atkScore(arg_19_0, arg_19_1)
	return arg_19_0.atkScore_[arg_19_1] or 0
end

function var_0_2.score(arg_20_0, arg_20_1)
	return arg_20_0.score_[arg_20_1] or 0
end

function var_0_2.leiming(arg_21_0, arg_21_1)
	return arg_21_0.leiming_[arg_21_1] or ""
end

function var_0_2.skill(arg_22_0, arg_22_1)
	return arg_22_0.skill_[arg_22_1] or ""
end

function var_0_2.skillDesc(arg_23_0, arg_23_1)
	return arg_23_0.skillDesc_[arg_23_1] or ""
end

function var_0_2.model(arg_24_0, arg_24_1)
	return arg_24_0.model_[arg_24_1] or ""
end

function var_0_2.scale(arg_25_0, arg_25_1)
	return arg_25_0.scale_[arg_25_1] or 0
end

function var_0_2.buffTexiao(arg_26_0, arg_26_1)
	return arg_26_0.buffTexiao_[arg_26_1] or ""
end

function var_0_2.buffTiaozheng(arg_27_0, arg_27_1)
	return arg_27_0.buffTiaozheng_[arg_27_1] or {}
end

return var_0_2
