local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("DBuffTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.time_ = {}
	arg_1_0.timeStep_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.moveUnable_ = {}
	arg_1_0.fear_ = {}
	arg_1_0.sleep_ = {}
	arg_1_0.possessed_ = {}
	arg_1_0.spGive_ = {}
	arg_1_0.spReduce_ = {}
	arg_1_0.spGiveRate_ = {}
	arg_1_0.apUnable_ = {}
	arg_1_0.adUnable_ = {}
	arg_1_0.pugongOnly_ = {}
	arg_1_0.noSkip_ = {}
	arg_1_0.attackFriend_ = {}
	arg_1_0.attr_ = {}
	arg_1_0.init_ = {}
	arg_1_0.step_ = {}
	arg_1_0.canMiss_ = {}
	arg_1_0.effectResource_ = {}
	arg_1_0.scale_ = {}
	arg_1_0.yx_ = {}
	arg_1_0.y_ = {}
	arg_1_0.x_ = {}
	arg_1_0.type_ = {}
	arg_1_0.filterColor_ = {}
	arg_1_0.affected_ = {}
	arg_1_0.teamAffected_ = {}
	arg_1_0.invisible_ = {}
	arg_1_0.dHarm_ = {}
	arg_1_0.dHarmType_ = {}
	arg_1_0.harmToHp_ = {}
	arg_1_0.stepHarm_ = {}
	arg_1_0.dHarmLast_ = {}
	arg_1_0.position_ = {}
	arg_1_0.isApImmortal_ = {}
	arg_1_0.isAdImmortal_ = {}
	arg_1_0.baseHarm_ = {}
	arg_1_0.stepBase_ = {}
	arg_1_0.ap_ = {}
	arg_1_0.isCover_ = {}
	arg_1_0.floatText_ = {}
	arg_1_0.pause_ = {}
	arg_1_0.isAdBreakImmortal_ = {}
	arg_1_0.removeSkill_ = {}
	arg_1_0.isBack_ = {}
	arg_1_0.canCopy_ = {}
	arg_1_0.dmpRateInit_ = {}
	arg_1_0.dmpRateStep_ = {}
	arg_1_0.baseMana_ = {}
	arg_1_0.stepBaseMana_ = {}
	arg_1_0.buffForm_ = {}
	arg_1_0.invalidMpIncrease_ = {}
	arg_1_0.invalidEnergySkill_ = {}
	arg_1_0.shieldInit_ = {}
	arg_1_0.shieldStep_ = {}
	arg_1_0.isLimit_ = {}
	arg_1_0.isSkillDown_ = {}
	arg_1_0.skillDownReq_ = {}
	arg_1_0.isAct_ = {}
	arg_1_0.actNum_ = {}
	arg_1_0.limitAttr_ = {}
	arg_1_0.dbuffType_ = {}
	arg_1_0.useSkillCount_ = {}
	arg_1_0.ignoreFlip_ = {}
	arg_1_0.isChaos_ = {}
	arg_1_0.energyLimit_ = {}
	arg_1_0.coverLimit_ = {}
	arg_1_0.canRemove_ = {}
	arg_1_0.isPartnerControl_ = {}
	arg_1_0.isImmuneControl_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("buff.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("buff", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.id)

	arg_2_0.time_[var_2_0] = tonumber(arg_2_1.time)
	arg_2_0.timeStep_[var_2_0] = tonumber(arg_2_1.time_step)
	arg_2_0.desc_[var_2_0] = arg_2_1.desc
	arg_2_0.moveUnable_[var_2_0] = tonumber(arg_2_1.move_unable)
	arg_2_0.fear_[var_2_0] = tonumber(arg_2_1.fear)
	arg_2_0.sleep_[var_2_0] = tonumber(arg_2_1.is_sleep)
	arg_2_0.possessed_[var_2_0] = tonumber(arg_2_1.possessed)
	arg_2_0.spGive_[var_2_0] = tonumber(arg_2_1.sp_give)
	arg_2_0.spReduce_[var_2_0] = tonumber(arg_2_1.sp_reduce)
	arg_2_0.spGiveRate_[var_2_0] = tonumber(arg_2_1.sp_give_rate)
	arg_2_0.apUnable_[var_2_0] = tonumber(arg_2_1.ap_unable)
	arg_2_0.adUnable_[var_2_0] = tonumber(arg_2_1.ad_unable)
	arg_2_0.pugongOnly_[var_2_0] = tonumber(arg_2_1.pugong)
	arg_2_0.noSkip_[var_2_0] = tonumber(arg_2_1.no_skip)
	arg_2_0.attackFriend_[var_2_0] = tonumber(arg_2_1.attack_friend)
	arg_2_0.attr_[var_2_0] = tonumber(arg_2_1.attr)
	arg_2_0.init_[var_2_0] = arg_2_1.init
	arg_2_0.step_[var_2_0] = arg_2_1.step_attr
	arg_2_0.canMiss_[var_2_0] = tonumber(arg_2_1.can_miss)
	arg_2_0.effectResource_[var_2_0] = {
		arg_2_1.json,
		arg_2_1.atlas,
		tonumber(arg_2_1.scale)
	}
	arg_2_0.isAct_[var_2_0] = tonumber(arg_2_1.is_act)
	arg_2_0.actNum_[var_2_0] = tonumber(arg_2_1.act_num) or 0
	arg_2_0.scale_[var_2_0] = tonumber(arg_2_1.scale)
	arg_2_0.yx_[var_2_0] = tonumber(arg_2_1.yx)
	arg_2_0.y_[var_2_0] = tonumber(arg_2_1.y)
	arg_2_0.x_[var_2_0] = tonumber(arg_2_1.x)
	arg_2_0.type_[var_2_0] = tonumber(arg_2_1.type)
	arg_2_0.filterColor_[var_2_0] = tonumber(arg_2_1.filter_color)
	arg_2_0.affected_[var_2_0] = tonumber(arg_2_1.affected)
	arg_2_0.teamAffected_[var_2_0] = tonumber(arg_2_1.team_invisible)
	arg_2_0.invisible_[var_2_0] = tonumber(arg_2_1.invisible)
	arg_2_0.dHarm_[var_2_0] = tonumber(arg_2_1.d_harm)
	arg_2_0.dHarmType_[var_2_0] = tonumber(arg_2_1.d_harm_type)
	arg_2_0.stepHarm_[var_2_0] = tonumber(arg_2_1.step_harm)
	arg_2_0.harmToHp_[var_2_0] = tonumber(arg_2_1.harm_to_hp)
	arg_2_0.dHarmLast_[var_2_0] = tonumber(arg_2_1.d_harm_last)
	arg_2_0.position_[var_2_0] = tonumber(arg_2_1.position)
	arg_2_0.isAdImmortal_[var_2_0] = tonumber(arg_2_1.ad_immortal)
	arg_2_0.isApImmortal_[var_2_0] = tonumber(arg_2_1.ap_immortal)
	arg_2_0.baseHarm_[var_2_0] = tonumber(arg_2_1.base_harm)
	arg_2_0.stepBase_[var_2_0] = tonumber(arg_2_1.step_base)
	arg_2_0.ap_[var_2_0] = tonumber(arg_2_1.ap)
	arg_2_0.isCover_[var_2_0] = tonumber(arg_2_1.is_cover)
	arg_2_0.floatText_[var_2_0] = var_0_1.split(arg_2_1.float_text, "|")
	arg_2_0.pause_[var_2_0] = tonumber(arg_2_1.pause)
	arg_2_0.isAdBreakImmortal_[var_2_0] = tonumber(arg_2_1.no_ad_break)
	arg_2_0.removeSkill_[var_2_0] = tonumber(arg_2_1.remove_skill)
	arg_2_0.isBack_[var_2_0] = tonumber(arg_2_1.back)
	arg_2_0.canCopy_[var_2_0] = tonumber(arg_2_1.can_copy)
	arg_2_0.dmpRateInit_[var_2_0] = tonumber(arg_2_1.dmp_rate_init)
	arg_2_0.dmpRateStep_[var_2_0] = tonumber(arg_2_1.dmp_rate_step)
	arg_2_0.baseMana_[var_2_0] = tonumber(arg_2_1.base_mp)
	arg_2_0.stepBaseMana_[var_2_0] = tonumber(arg_2_1.step_mp)
	arg_2_0.buffForm_[var_2_0] = tonumber(arg_2_1.buff_form)
	arg_2_0.invalidMpIncrease_[var_2_0] = tonumber(arg_2_1.invalid_mp_increase)
	arg_2_0.invalidEnergySkill_[var_2_0] = tonumber(arg_2_1.invalid_energy_skill)
	arg_2_0.shieldInit_[var_2_0] = tonumber(arg_2_1.shield_init)
	arg_2_0.shieldStep_[var_2_0] = tonumber(arg_2_1.shield_step)
	arg_2_0.isLimit_[var_2_0] = tonumber(arg_2_1.is_limit)
	arg_2_0.isSkillDown_[var_2_0] = tonumber(arg_2_1.skill_down)
	arg_2_0.skillDownReq_[var_2_0] = tonumber(arg_2_1.skill_down_req)
	arg_2_0.limitAttr_[var_2_0] = tonumber(arg_2_1.attr_limit)
	arg_2_0.dbuffType_[var_2_0] = tonumber(arg_2_1.debuff_type)
	arg_2_0.useSkillCount_[var_2_0] = tonumber(arg_2_1.use_skill_count)
	arg_2_0.ignoreFlip_[var_2_0] = tonumber(arg_2_1.ignore_flip)
	arg_2_0.isChaos_[var_2_0] = tonumber(arg_2_1.is_chaos)
	arg_2_0.energyLimit_[var_2_0] = arg_2_1.energy_limit
	arg_2_0.coverLimit_[var_2_0] = tonumber(arg_2_1.cover_limit)
	arg_2_0.canRemove_[var_2_0] = tonumber(arg_2_1.can_remove)
	arg_2_0.isPartnerControl_[var_2_0] = tonumber(arg_2_1.is_partner_control)
	arg_2_0.isImmuneControl_[var_2_0] = tonumber(arg_2_1.is_immune_control)
end

function var_0_2.hasBuff(arg_3_0, arg_3_1)
	return arg_3_0.time_[arg_3_1] ~= nil
end

function var_0_2.desc(arg_4_0, arg_4_1)
	return arg_4_0.desc_[arg_4_1] or ""
end

function var_0_2.time(arg_5_0, arg_5_1)
	return arg_5_0.time_[arg_5_1] or 0
end

function var_0_2.timeStep(arg_6_0, arg_6_1)
	return arg_6_0.timeStep_[arg_6_1] or 0
end

function var_0_2.fear(arg_7_0, arg_7_1)
	return arg_7_0.fear_[arg_7_1] or 0
end

function var_0_2.sleep(arg_8_0, arg_8_1)
	return (arg_8_0.sleep_[arg_8_1] or 0) == 1
end

function var_0_2.possessed(arg_9_0, arg_9_1)
	return (arg_9_0.possessed_[arg_9_1] or 0) == 1
end

function var_0_2.moveUnable(arg_10_0, arg_10_1)
	return (arg_10_0.moveUnable_[arg_10_1] or 0) == 1
end

function var_0_2.type(arg_11_0, arg_11_1)
	return arg_11_0.type_[arg_11_1] or 0
end

function var_0_2.apUnable(arg_12_0, arg_12_1)
	return (arg_12_0.apUnable_[arg_12_1] or 0) == 1
end

function var_0_2.adUnable(arg_13_0, arg_13_1)
	return (arg_13_0.adUnable_[arg_13_1] or 0) == 1
end

function var_0_2.noSkip(arg_14_0, arg_14_1)
	return (arg_14_0.noSkip_[arg_14_1] or 0) == 1
end

function var_0_2.attackFriend(arg_15_0, arg_15_1)
	return (arg_15_0.attackFriend_[arg_15_1] or 0) == 1
end

function var_0_2.attr(arg_16_0, arg_16_1)
	return arg_16_0.attr_[arg_16_1] or 0
end

function var_0_2.init(arg_17_0, arg_17_1)
	local var_17_0 = string.find(arg_17_0.init_[arg_17_1], "p")

	if var_17_0 then
		local var_17_1 = arg_17_0.init_[arg_17_1]:sub(1, var_17_0 - 1)

		return (tonumber(var_17_1) or 0) / var_0_1.DECIMAL_BASE, true
	end

	return tonumber(arg_17_0.init_[arg_17_1]) or 0, false
end

function var_0_2.step(arg_18_0, arg_18_1)
	local var_18_0 = string.find(arg_18_0.step_[arg_18_1], "p")

	if var_18_0 then
		local var_18_1 = arg_18_0.step_[arg_18_1]:sub(1, var_18_0 - 1)

		return (tonumber(var_18_1) or 0) / var_0_1.DECIMAL_BASE
	end

	return tonumber(arg_18_0.step_[arg_18_1]) or 0
end

function var_0_2.canMiss(arg_19_0, arg_19_1)
	return (arg_19_0.canMiss_[arg_19_1] or 1) == 1
end

function var_0_2.effectResource(arg_20_0, arg_20_1)
	return unpack(arg_20_0.effectResource_[arg_20_1] or {})
end

function var_0_2.scale(arg_21_0, arg_21_1)
	return arg_21_0.scale_[arg_21_1]
end

function var_0_2.yx(arg_22_0, arg_22_1)
	return arg_22_0.yx_[arg_22_1] or 0
end

function var_0_2.y(arg_23_0, arg_23_1)
	return arg_23_0.y_[arg_23_1] or 0
end

function var_0_2.x(arg_24_0, arg_24_1)
	return arg_24_0.x_[arg_24_1] or 0
end

function var_0_2.filterColor(arg_25_0, arg_25_1)
	return arg_25_0.filterColor_[arg_25_1] or 0
end

function var_0_2.affected(arg_26_0, arg_26_1)
	return (arg_26_0.affected_[arg_26_1] or 0) == 1
end

function var_0_2.teamAffected(arg_27_0, arg_27_1)
	return (arg_27_0.teamAffected_[arg_27_1] or 0) == 1
end

function var_0_2.invisible(arg_28_0, arg_28_1)
	return (arg_28_0.invisible_[arg_28_1] or 0) == 1
end

function var_0_2.dHarm(arg_29_0, arg_29_1)
	return arg_29_0.dHarm_[arg_29_1] or 0
end

function var_0_2.dHarmType(arg_30_0, arg_30_1)
	return arg_30_0.dHarmType_[arg_30_1] or 0
end

function var_0_2.stepHarm(arg_31_0, arg_31_1)
	return arg_31_0.stepHarm_[arg_31_1] or 0
end

function var_0_2.harmToHP(arg_32_0, arg_32_1)
	return arg_32_0.harmToHp_[arg_32_1] or 0
end

function var_0_2.isDHarmLast(arg_33_0, arg_33_1)
	return (arg_33_0.dHarmLast_[arg_33_1] or 0) == 1
end

function var_0_2.position(arg_34_0, arg_34_1)
	return arg_34_0.position_[arg_34_1] or 0
end

function var_0_2.isApImmortal(arg_35_0, arg_35_1)
	return (arg_35_0.isApImmortal_[arg_35_1] or 0) == 1
end

function var_0_2.isAdImmortal(arg_36_0, arg_36_1)
	return (arg_36_0.isAdImmortal_[arg_36_1] or 0) == 1
end

function var_0_2.baseHarm(arg_37_0, arg_37_1)
	return arg_37_0.baseHarm_[arg_37_1] or 0
end

function var_0_2.stepBase(arg_38_0, arg_38_1)
	return arg_38_0.stepBase_[arg_38_1] or 0
end

function var_0_2.ap(arg_39_0, arg_39_1)
	return (arg_39_0.ap_[arg_39_1] or 0) / var_0_1.DECIMAL_BASE
end

function var_0_2.isCover(arg_40_0, arg_40_1)
	return (arg_40_0.isCover_[arg_40_1] or 1) == 1
end

function var_0_2.floatText(arg_41_0, arg_41_1)
	return arg_41_0.floatText_[arg_41_1]
end

function var_0_2.pause(arg_42_0, arg_42_1)
	return (arg_42_0.pause_[arg_42_1] or 0) == 1
end

function var_0_2.isAdBreakImmortal(arg_43_0, arg_43_1)
	return (arg_43_0.isAdBreakImmortal_[arg_43_1] or 0) == 1
end

function var_0_2.removeSkill(arg_44_0, arg_44_1)
	return arg_44_0.removeSkill_[arg_44_1] or 0
end

function var_0_2.isBack(arg_45_0, arg_45_1)
	return (arg_45_0.isBack_[arg_45_1] or 0) == 1
end

function var_0_2.canCopy(arg_46_0, arg_46_1)
	return (arg_46_0.canCopy_[arg_46_1] or 0) == 1
end

function var_0_2.dmpRateStep(arg_47_0, arg_47_1)
	return (arg_47_0.dmpRateStep_[arg_47_1] or 0) / var_0_1.DECIMAL_BASE
end

function var_0_2.dmpRateInit(arg_48_0, arg_48_1)
	return (arg_48_0.dmpRateInit_[arg_48_1] or 0) / var_0_1.DECIMAL_BASE
end

function var_0_2.baseMana(arg_49_0, arg_49_1)
	return arg_49_0.baseMana_[arg_49_1] or 0
end

function var_0_2.stepBaseMana(arg_50_0, arg_50_1)
	return arg_50_0.stepBaseMana_[arg_50_1] or 0
end

function var_0_2.buffForm(arg_51_0, arg_51_1)
	return arg_51_0.buffForm_[arg_51_1] or 0
end

function var_0_2.isPugongOnly(arg_52_0, arg_52_1)
	return (arg_52_0.pugongOnly_[arg_52_1] or 0) == 1
end

function var_0_2.isInvalidMpIncrease(arg_53_0, arg_53_1)
	return (arg_53_0.invalidMpIncrease_[arg_53_1] or 0) == 1
end

function var_0_2.isInvalidEnergySkill(arg_54_0, arg_54_1)
	return (arg_54_0.invalidEnergySkill_[arg_54_1] or 0) == 1
end

function var_0_2.shieldInit(arg_55_0, arg_55_1)
	return arg_55_0.shieldInit_[arg_55_1] or 0
end

function var_0_2.shieldStep(arg_56_0, arg_56_1)
	return arg_56_0.shieldStep_[arg_56_1] or 0
end

function var_0_2.isLimit(arg_57_0, arg_57_1)
	return arg_57_0.isLimit_[arg_57_1] or 0
end

function var_0_2.isSkillDown(arg_58_0, arg_58_1)
	return arg_58_0.isSkillDown_[arg_58_1] or 0
end

function var_0_2.skillDownReq(arg_59_0, arg_59_1)
	return arg_59_0.skillDownReq_[arg_59_1] or 0
end

function var_0_2.isAct(arg_60_0, arg_60_1)
	return arg_60_0.isAct_[arg_60_1] == 1
end

function var_0_2.actNum(arg_61_0, arg_61_1)
	return arg_61_0.actNum_[arg_61_1]
end

function var_0_2.isSpGive(arg_62_0, arg_62_1)
	return (arg_62_0.spGive_[arg_62_1] or 0) == 1
end

function var_0_2.isSpReduce(arg_63_0, arg_63_1)
	return (arg_63_0.spReduce_[arg_63_1] or 0) == 1
end

function var_0_2.spGiveRate(arg_64_0, arg_64_1)
	return arg_64_0.spGiveRate_[arg_64_1] or 0
end

function var_0_2.limitAttr(arg_65_0, arg_65_1)
	return arg_65_0.limitAttr_[arg_65_1] or 0
end

function var_0_2.dbuffType(arg_66_0, arg_66_1)
	return arg_66_0.dbuffType_[arg_66_1] or 0
end

function var_0_2.useSkillCount(arg_67_0, arg_67_1)
	return arg_67_0.useSkillCount_[arg_67_1] or 0
end

function var_0_2.ignoreFlip(arg_68_0, arg_68_1)
	return arg_68_0.ignoreFlip_[arg_68_1] or 0
end

function var_0_2.isChaos(arg_69_0, arg_69_1)
	return arg_69_0.isChaos_[arg_69_1] or 0
end

function var_0_2.isPartnerControl(arg_70_0, arg_70_1)
	return arg_70_0.isPartnerControl_[arg_70_1] or 0
end

function var_0_2.isImmuneControl(arg_71_0, arg_71_1)
	return arg_71_0.isImmuneControl_[arg_71_1] or 0
end

function var_0_2.energyLimit(arg_72_0, arg_72_1)
	if not arg_72_0.energyLimit_[arg_72_1] then
		return 1
	end

	local var_72_0 = string.find(arg_72_0.energyLimit_[arg_72_1], "p")

	if var_72_0 then
		local var_72_1 = arg_72_0.energyLimit_[arg_72_1]:sub(1, var_72_0 - 1)

		return (tonumber(var_72_1) or 0) / var_0_1.DECIMAL_BASE
	end

	return 1
end

function var_0_2.CoverLimit(arg_73_0, arg_73_1)
	local var_73_0 = arg_73_0.coverLimit_[arg_73_1] or 999

	return var_73_0 ~= 0 and var_73_0 or 999
end

function var_0_2.canRemove(arg_74_0, arg_74_1)
	return (arg_74_0.canRemove_[arg_74_1] or 0) == 1
end

return var_0_2
