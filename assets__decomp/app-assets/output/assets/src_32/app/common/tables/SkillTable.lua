local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("SkillTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.name_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.pretime_ = {}
	arg_1_0.distance_ = {}
	arg_1_0.scope_ = {}
	arg_1_0.typeDesc_ = {}
	arg_1_0.selectType_ = {}
	arg_1_0.type_ = {}
	arg_1_0.skillType_ = {}
	arg_1_0.beMiss_ = {}
	arg_1_0.ad_ = {}
	arg_1_0.ap_ = {}
	arg_1_0.adStep_ = {}
	arg_1_0.apStep_ = {}
	arg_1_0.init_ = {}
	arg_1_0.initMD5_ = {}
	arg_1_0.step_ = {}
	arg_1_0.stepMD5_ = {}
	arg_1_0.attachAttr_ = {}
	arg_1_0.attrToHarm_ = {}
	arg_1_0.attachStep_ = {}
	arg_1_0.attachLimit_ = {}
	arg_1_0.buffs_ = {}
	arg_1_0.unitNum_ = {}
	arg_1_0.interval_ = {}
	arg_1_0.attackIndex_ = {}
	arg_1_0.remp_ = {}
	arg_1_0.xixue_ = {}
	arg_1_0.speed_ = {}
	arg_1_0.timeout_ = {}
	arg_1_0.timeout2_ = {}
	arg_1_0.sound_ = {}
	arg_1_0.selfResource_ = {}
	arg_1_0.selfDelay_ = {}
	arg_1_0.areaResource_ = {}
	arg_1_0.unitResource_ = {}
	arg_1_0.unitEffectType_ = {}
	arg_1_0.areaPosition_ = {}
	arg_1_0.hurtResource_ = {}
	arg_1_0.hurtEffectType_ = {}
	arg_1_0.yx_ = {}
	arg_1_0.y_ = {}
	arg_1_0.isRotate_ = {}
	arg_1_0.collisionNum_ = {}
	arg_1_0.isResetToXY_ = {}
	arg_1_0.isResetTarget_ = {}
	arg_1_0.collisionRepeat_ = {}
	arg_1_0.forceBreak_ = {}
	arg_1_0.collisionTimeout_ = {}
	arg_1_0.collisionWeaken_ = {}
	arg_1_0.children_ = {}
	arg_1_0.father_ = {}
	arg_1_0.manualType_ = {}
	arg_1_0.initPower_ = {}
	arg_1_0.stepPower_ = {}
	arg_1_0.orb_ = {}
	arg_1_0.randomOrb_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.mp_ = {}
	arg_1_0.mpStep_ = {}
	arg_1_0.hitSound_ = {}
	arg_1_0.ignoreDefenceType_ = {}
	arg_1_0.desc2_ = {}
	arg_1_0.desc3_ = {}
	arg_1_0.descNumInit_ = {}
	arg_1_0.descNumStep_ = {}
	arg_1_0.petStarType_ = {}
	arg_1_0.desc4_ = {}
	arg_1_0.desc4NumStep_ = {}
	arg_1_0.accelerate_ = {}
	arg_1_0.aTime_ = {}
	arg_1_0.isFixedTarget_ = {}
	arg_1_0.hitMove_ = {}
	arg_1_0.hitMoveTime_ = {}
	arg_1_0.move_ = {}
	arg_1_0.moveTime_ = {}
	arg_1_0.enterSpeed_ = {}
	arg_1_0.enterDuration_ = {}
	arg_1_0.enterDelayDuration_ = {}
	arg_1_0.summonMonster_ = {}
	arg_1_0.summonPos_ = {}
	arg_1_0.harmSaveSkill_ = {}
	arg_1_0.xixueSaveSkill_ = {}
	arg_1_0.selectChildren_ = {}
	arg_1_0.isInvalidAfterDeath_ = {}
	arg_1_0.xuliChild_ = {}
	arg_1_0.buffOrb_ = {}
	arg_1_0.buffOrbSkill_ = {}
	arg_1_0.isAwakenSkill_ = {}
	arg_1_0.isAwakeTwiceSkill_ = {}
	arg_1_0.shakeDelay_ = {}
	arg_1_0.shakeLev_ = {}
	arg_1_0.repulsionHero_ = {}
	arg_1_0.skinSkill_ = {}
	arg_1_0.itemID_ = {}
	arg_1_0.isReflect_ = {}
	arg_1_0.ignoreImmortal_ = {}
	arg_1_0.snowmanUsable_ = {}
	arg_1_0.isRemp_ = {}
	arg_1_0.isTriggerSkill_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("skill.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("skill", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.id)

	if arg_2_0.name_[var_2_0] then
		error("duplicate skill ID " .. var_2_0)
	end

	arg_2_0.name_[var_2_0] = arg_2_1.name
	arg_2_0.icon_[var_2_0] = arg_2_1.icon
	arg_2_0.desc_[var_2_0] = string.gsub(arg_2_1.desc, "|", "\n")
	arg_2_0.desc2_[var_2_0] = var_0_1.luaStringSplit(arg_2_1.desc2, "|")
	arg_2_0.desc3_[var_2_0] = var_0_1.luaStringSplit(arg_2_1.desc3, "|")
	arg_2_0.descNumInit_[var_2_0] = var_0_1.splitToNumber(arg_2_1.desc_num_init, "|")
	arg_2_0.descNumStep_[var_2_0] = var_0_1.splitToNumber(arg_2_1.desc_num_step, "|")
	arg_2_0.petStarType_[var_2_0] = tonumber(arg_2_1.pet_star_type)
	arg_2_0.desc4_[var_2_0] = var_0_1.luaStringSplit(arg_2_1.desc4, "|")
	arg_2_0.desc4NumStep_[var_2_0] = var_0_1.splitToNumber(arg_2_1.desc4_num_step, "|")
	arg_2_0.pretime_[var_2_0] = tonumber(arg_2_1.pretime)
	arg_2_0.distance_[var_2_0] = tonumber(arg_2_1.distance)
	arg_2_0.scope_[var_2_0] = tonumber(arg_2_1.scope)
	arg_2_0.typeDesc_[var_2_0] = tonumber(arg_2_1.type_desc)
	arg_2_0.selectType_[var_2_0] = tonumber(arg_2_1.select_type) or arg_2_1.select_type
	arg_2_0.type_[var_2_0] = tonumber(arg_2_1.type)
	arg_2_0.skillType_[var_2_0] = tonumber(arg_2_1.skill_type)
	arg_2_0.beMiss_[var_2_0] = tonumber(arg_2_1.be_miss)
	arg_2_0.ad_[var_2_0] = tonumber(arg_2_1.ad)
	arg_2_0.ap_[var_2_0] = tonumber(arg_2_1.ap)
	arg_2_0.adStep_[var_2_0] = tonumber(arg_2_1.ad_step)
	arg_2_0.apStep_[var_2_0] = tonumber(arg_2_1.ap_step)
	arg_2_0.init_[var_2_0] = tonumber(arg_2_1.init)

	if isClient then
		arg_2_0.initMD5_[var_2_0] = crypto.md5(arg_2_1.init .. var_0_1.TableCryptoKey)
		arg_2_0.stepMD5_[var_2_0] = crypto.md5(arg_2_1.step .. var_0_1.TableCryptoKey)
	end

	arg_2_0.step_[var_2_0] = tonumber(arg_2_1.step)
	arg_2_0.unitNum_[var_2_0] = tonumber(arg_2_1.unit_num)
	arg_2_0.interval_[var_2_0] = tonumber(arg_2_1.interval)
	arg_2_0.attackIndex_[var_2_0] = tonumber(arg_2_1.attack_index)
	arg_2_0.remp_[var_2_0] = tonumber(arg_2_1.remp)
	arg_2_0.xixue_[var_2_0] = tonumber(arg_2_1.xixue)
	arg_2_0.speed_[var_2_0] = tonumber(arg_2_1.speed)
	arg_2_0.buffs_[var_2_0] = var_0_1.splitToNumber(arg_2_1.buffs, "|")
	arg_2_0.timeout_[var_2_0] = tonumber(arg_2_1.timeout)
	arg_2_0.sound_[var_2_0] = arg_2_1.sound
	arg_2_0.attachAttr_[var_2_0] = arg_2_1.attach_attr
	arg_2_0.attrToHarm_[var_2_0] = tonumber(arg_2_1.attr_to_harm)
	arg_2_0.attachStep_[var_2_0] = tonumber(arg_2_1.attch_step)
	arg_2_0.attachLimit_[var_2_0] = var_0_1.splitToNumber(arg_2_1.attch_limit, "|")
	arg_2_0.selfResource_[var_2_0] = {
		arg_2_1.json_self,
		arg_2_1.atlas_self
	}
	arg_2_0.selfDelay_[var_2_0] = tonumber(arg_2_1.delay_self)
	arg_2_0.areaResource_[var_2_0] = {
		arg_2_1.json_area,
		arg_2_1.atlas_area
	}
	arg_2_0.unitResource_[var_2_0] = {
		arg_2_1.json_unit,
		arg_2_1.atlas_unit
	}
	arg_2_0.unitEffectType_[var_2_0] = tonumber(arg_2_1.unit_effect_type)
	arg_2_0.areaPosition_[var_2_0] = var_0_1.splitToNumber(arg_2_1.area_pos, "|")
	arg_2_0.hurtResource_[var_2_0] = {
		arg_2_1.json_shouji,
		arg_2_1.atlas_shouji
	}
	arg_2_0.hurtEffectType_[var_2_0] = tonumber(arg_2_1.shouji_effect_type)
	arg_2_0.yx_[var_2_0] = tonumber(arg_2_1.yx)
	arg_2_0.y_[var_2_0] = tonumber(arg_2_1.y)
	arg_2_0.isRotate_[var_2_0] = tonumber(arg_2_1.is_rotate)
	arg_2_0.collisionNum_[var_2_0] = tonumber(arg_2_1.collision_num)
	arg_2_0.isResetToXY_[var_2_0] = tonumber(arg_2_1.is_reset_to_xy)
	arg_2_0.isResetTarget_[var_2_0] = tonumber(arg_2_1.is_reset_target)
	arg_2_0.collisionRepeat_[var_2_0] = tonumber(arg_2_1.collision_repeat)
	arg_2_0.forceBreak_[var_2_0] = tonumber(arg_2_1.force_break)
	arg_2_0.collisionTimeout_[var_2_0] = tonumber(arg_2_1.collision_timeout)
	arg_2_0.children_[var_2_0] = var_0_1.splitToNumber(arg_2_1.child, "|")
	arg_2_0.father_[var_2_0] = tonumber(arg_2_1.father)
	arg_2_0.manualType_[var_2_0] = tonumber(arg_2_1.manual_type)
	arg_2_0.initPower_[var_2_0] = tonumber(arg_2_1.init_power)
	arg_2_0.stepPower_[var_2_0] = tonumber(arg_2_1.step_power)
	arg_2_0.orb_[var_2_0] = tonumber(arg_2_1.orb)
	arg_2_0.randomOrb_[var_2_0] = var_0_1.splitToNumber(arg_2_1.random_orb, "|")
	arg_2_0.mp_[var_2_0] = tonumber(arg_2_1.mp)
	arg_2_0.mpStep_[var_2_0] = tonumber(arg_2_1.mp_step)
	arg_2_0.hitSound_[var_2_0] = arg_2_1.hit_sound
	arg_2_0.ignoreDefenceType_[var_2_0] = tonumber(arg_2_1.ignore_defence)
	arg_2_0.collisionWeaken_[var_2_0] = tonumber(arg_2_1.collision_weaken)
	arg_2_0.accelerate_[var_2_0] = var_0_1.splitToNumber(arg_2_1.acceleration, "|")
	arg_2_0.aTime_[var_2_0] = var_0_1.splitToNumber(arg_2_1.a_time, "|")
	arg_2_0.isFixedTarget_[var_2_0] = tonumber(arg_2_1.fixed_target)
	arg_2_0.hitMove_[var_2_0] = tonumber(arg_2_1.hit_move)
	arg_2_0.hitMoveTime_[var_2_0] = tonumber(arg_2_1.hit_move_period)
	arg_2_0.move_[var_2_0] = tonumber(arg_2_1.self_move)
	arg_2_0.moveTime_[var_2_0] = tonumber(arg_2_1.self_move_period)
	arg_2_0.enterSpeed_[var_2_0] = tonumber(arg_2_1.enter_speed)
	arg_2_0.enterDuration_[var_2_0] = tonumber(arg_2_1.enter_duration)
	arg_2_0.enterDelayDuration_[var_2_0] = tonumber(arg_2_1.enter_delay_duration)
	arg_2_0.summonMonster_[var_2_0] = var_0_1.splitToNumber(arg_2_1.summon_monster, "|")
	arg_2_0.summonPos_[var_2_0] = tonumber(arg_2_1.summon_pos)
	arg_2_0.harmSaveSkill_[var_2_0] = tonumber(arg_2_1.harm_save_skill)
	arg_2_0.xixueSaveSkill_[var_2_0] = tonumber(arg_2_1.xixue_save_skill)
	arg_2_0.selectChildren_[var_2_0] = var_0_1.splitToNumber(arg_2_1.select_children, "|")
	arg_2_0.isInvalidAfterDeath_[var_2_0] = tonumber(arg_2_1.invalid_after_death)
	arg_2_0.xuliChild_[var_2_0] = tonumber(arg_2_1.xuli_child)
	arg_2_0.buffOrb_[var_2_0] = tonumber(arg_2_1.buff_orb)
	arg_2_0.buffOrbSkill_[var_2_0] = tonumber(arg_2_1.buff_orb_skill)
	arg_2_0.isAwakenSkill_[var_2_0] = tonumber(arg_2_1.is_awaken)
	arg_2_0.isAwakeTwiceSkill_[var_2_0] = tonumber(arg_2_1.is_twice_awaken)
	arg_2_0.shakeDelay_[var_2_0] = tonumber(arg_2_1.shake_time)
	arg_2_0.shakeLev_[var_2_0] = tonumber(arg_2_1.shake_level)
	arg_2_0.repulsionHero_[var_2_0] = var_0_1.splitToNumber(arg_2_1.repulsion_hero, "|")
	arg_2_0.isReflect_[var_2_0] = tonumber(arg_2_1.is_reflect)
	arg_2_0.skinSkill_[var_2_0] = var_0_1.splitToNumber(arg_2_1.skin_skill, "|")
	arg_2_0.itemID_[var_2_0] = tonumber(arg_2_1.item_id) or 0
	arg_2_0.ignoreImmortal_[var_2_0] = tonumber(arg_2_1.ignore_immortal)
	arg_2_0.snowmanUsable_[var_2_0] = tonumber(arg_2_1.snowman_usable)
	arg_2_0.isRemp_[var_2_0] = tonumber(arg_2_1.is_remp)
	arg_2_0.isTriggerSkill_[var_2_0] = tonumber(arg_2_1.is_trigger_skill)
end

function var_0_2.isAwakenSkill(arg_3_0, arg_3_1)
	return arg_3_0.isAwakenSkill_[arg_3_1] or 0
end

function var_0_2.isAwakeTwiceSkill(arg_4_0, arg_4_1)
	return arg_4_0.isAwakeTwiceSkill_[arg_4_1] or 0
end

function var_0_2.hasSkill(arg_5_0, arg_5_1)
	return arg_5_0.names_[arg_5_1] ~= nil
end

function var_0_2.name(arg_6_0, arg_6_1)
	return arg_6_0.name_[arg_6_1] or 0
end

function var_0_2.desc(arg_7_0, arg_7_1)
	return arg_7_0.desc_[arg_7_1]
end

function var_0_2.desc2(arg_8_0, arg_8_1)
	return arg_8_0.desc2_[arg_8_1] or {}
end

function var_0_2.desc3(arg_9_0, arg_9_1)
	return arg_9_0.desc3_[arg_9_1] or {}
end

function var_0_2.descNumInit(arg_10_0, arg_10_1)
	return arg_10_0.descNumInit_[arg_10_1] or 0
end

function var_0_2.descNumStep(arg_11_0, arg_11_1)
	return arg_11_0.descNumStep_[arg_11_1] or {}
end

function var_0_2.petStarType(arg_12_0, arg_12_1)
	return arg_12_0.petStarType_[arg_12_1] or 0
end

function var_0_2.desc4(arg_13_0, arg_13_1)
	return arg_13_0.desc4_[arg_13_1] or {}
end

function var_0_2.desc4NumStep(arg_14_0, arg_14_1)
	return arg_14_0.desc4NumStep_[arg_14_1] or {}
end

function var_0_2.pretime(arg_15_0, arg_15_1)
	return arg_15_0.pretime_[arg_15_1] or 0
end

function var_0_2.distance(arg_16_0, arg_16_1)
	return arg_16_0.distance_[arg_16_1] or 0
end

function var_0_2.scope(arg_17_0, arg_17_1)
	return arg_17_0.scope_[arg_17_1] or 0
end

function var_0_2.typeDesc(arg_18_0, arg_18_1)
	return arg_18_0.typeDesc_[arg_18_1] or -1
end

function var_0_2.selectType(arg_19_0, arg_19_1)
	return arg_19_0.selectType_[arg_19_1] or 0
end

function var_0_2.beMiss(arg_20_0, arg_20_1)
	return arg_20_0.beMiss_[arg_20_1] or 0
end

function var_0_2.type(arg_21_0, arg_21_1)
	return arg_21_0.type_[arg_21_1] or 0
end

function var_0_2.skillType(arg_22_0, arg_22_1)
	return arg_22_0.skillType_[arg_22_1] or 0
end

function var_0_2.ad(arg_23_0, arg_23_1)
	return arg_23_0.ad_[arg_23_1] or 0
end

function var_0_2.ap(arg_24_0, arg_24_1)
	return arg_24_0.ap_[arg_24_1] or 0
end

function var_0_2.adStep(arg_25_0, arg_25_1)
	return arg_25_0.adStep_[arg_25_1] or 0
end

function var_0_2.apStep(arg_26_0, arg_26_1)
	return arg_26_0.apStep_[arg_26_1] or 0
end

function var_0_2.init(arg_27_0, arg_27_1)
	if isClient and arg_27_0.initMD5_[arg_27_1] and arg_27_0.init_[arg_27_1] and crypto.md5(tostring(arg_27_0.init_[arg_27_1]) .. var_0_1.TableCryptoKey) ~= arg_27_0.initMD5_[arg_27_1] then
		var_0_1.exitProgram()
	end

	return arg_27_0.init_[arg_27_1] or 0
end

function var_0_2.step(arg_28_0, arg_28_1)
	if isClient and arg_28_0.stepMD5_[arg_28_1] and arg_28_0.step_[arg_28_1] and crypto.md5(tostring(arg_28_0.step_[arg_28_1]) .. var_0_1.TableCryptoKey) ~= arg_28_0.stepMD5_[arg_28_1] then
		var_0_1.exitProgram()
	end

	return arg_28_0.step_[arg_28_1] or 0
end

function var_0_2.buffs(arg_29_0, arg_29_1)
	return arg_29_0.buffs_[arg_29_1] or {}
end

function var_0_2.unitNum(arg_30_0, arg_30_1)
	return arg_30_0.unitNum_[arg_30_1] or 0
end

function var_0_2.interval(arg_31_0, arg_31_1)
	return arg_31_0.interval_[arg_31_1] or 0
end

function var_0_2.attackIndex(arg_32_0, arg_32_1)
	return arg_32_0.attackIndex_[arg_32_1] or 0
end

function var_0_2.reMP(arg_33_0, arg_33_1)
	return arg_33_0.remp_[arg_33_1] or 0
end

function var_0_2.xixue(arg_34_0, arg_34_1)
	return arg_34_0.xixue_[arg_34_1] or 0
end

function var_0_2.speed(arg_35_0, arg_35_1)
	return arg_35_0.speed_[arg_35_1] or 0
end

function var_0_2.timeout(arg_36_0, arg_36_1)
	return arg_36_0.timeout_[arg_36_1]
end

function var_0_2.sound(arg_37_0, arg_37_1)
	return arg_37_0.sound_[arg_37_1]
end

function var_0_2.icon(arg_38_0, arg_38_1)
	return arg_38_0.icon_[arg_38_1]
end

function var_0_2.attachStep(arg_39_0, arg_39_1)
	return (arg_39_0.attachStep_[arg_39_1] or 0) / var_0_1.DECIMAL_BASE
end

function var_0_2.attachAttr(arg_40_0, arg_40_1)
	if not arg_40_0.attachAttr_[arg_40_1] or arg_40_0.attachAttr_[arg_40_1] == "" or arg_40_0.attachAttr_[arg_40_1] == "0" then
		return nil
	end

	return arg_40_0.attachAttr_[arg_40_1]
end

function var_0_2.attrToHarm(arg_41_0, arg_41_1)
	return (arg_41_0.attrToHarm_[arg_41_1] or 0) / var_0_1.DECIMAL_BASE
end

function var_0_2.attachLimit(arg_42_0, arg_42_1)
	return unpack(arg_42_0.attachLimit_[arg_42_1])
end

function var_0_2.selfResource(arg_43_0, arg_43_1)
	return unpack(arg_43_0.selfResource_[arg_43_1] or {})
end

function var_0_2.selfDelay(arg_44_0, arg_44_1)
	return arg_44_0.selfDelay_[arg_44_1] or 0
end

function var_0_2.areaResource(arg_45_0, arg_45_1)
	return unpack(arg_45_0.areaResource_[arg_45_1])
end

function var_0_2.targetDelay(arg_46_0, arg_46_1)
	return arg_46_0.targetDelay_[arg_46_1] or 0
end

function var_0_2.unitResource(arg_47_0, arg_47_1)
	return unpack(arg_47_0.unitResource_[arg_47_1])
end

function var_0_2.unitEffectType(arg_48_0, arg_48_1)
	return arg_48_0.unitEffectType_[arg_48_1] or 0
end

function var_0_2.areaPosition(arg_49_0, arg_49_1)
	return arg_49_0.areaPosition_[arg_49_1] or {}
end

function var_0_2.hurtResource(arg_50_0, arg_50_1)
	return unpack(arg_50_0.hurtResource_[arg_50_1])
end

function var_0_2.hurtEffectType(arg_51_0, arg_51_1)
	return arg_51_0.hurtEffectType_[arg_51_1] or 0
end

function var_0_2.yx(arg_52_0, arg_52_1)
	return arg_52_0.yx_[arg_52_1] or 0
end

function var_0_2.y(arg_53_0, arg_53_1)
	return arg_53_0.y_[arg_53_1] or 0
end

function var_0_2.isRotate(arg_54_0, arg_54_1)
	return (arg_54_0.isRotate_[arg_54_1] or 0) == 1
end

function var_0_2.collisionNum(arg_55_0, arg_55_1)
	return arg_55_0.collisionNum_[arg_55_1] or 0
end

function var_0_2.isResetTarget(arg_56_0, arg_56_1)
	return (arg_56_0.isResetTarget_[arg_56_1] or 0) == 1
end

function var_0_2.isResetToXY(arg_57_0, arg_57_1)
	return (arg_57_0.isResetToXY_[arg_57_1] or 0) == 1
end

function var_0_2.collisionRepeat(arg_58_0, arg_58_1)
	return (arg_58_0.collisionRepeat_[arg_58_1] or 0) == 1
end

function var_0_2.forceBreak(arg_59_0, arg_59_1)
	return (arg_59_0.forceBreak_[arg_59_1] or 0) == 1
end

function var_0_2.collisionTimeout(arg_60_0, arg_60_1)
	return arg_60_0.collisionTimeout_[arg_60_1] or 0
end

function var_0_2.children(arg_61_0, arg_61_1)
	return arg_61_0.children_[arg_61_1] or {}
end

function var_0_2.father(arg_62_0, arg_62_1)
	return arg_62_0.father_[arg_62_1] and arg_62_0.father_[arg_62_1] > 0 and arg_62_0.father_[arg_62_1] or arg_62_1
end

function var_0_2.manualType(arg_63_0, arg_63_1)
	return arg_63_0.manualType_[arg_63_1] or 0
end

function var_0_2.initPower(arg_64_0, arg_64_1)
	return arg_64_0.initPower_[arg_64_1] or 0
end

function var_0_2.stepPower(arg_65_0, arg_65_1)
	return arg_65_0.stepPower_[arg_65_1] or 0
end

function var_0_2.orb(arg_66_0, arg_66_1)
	return arg_66_0.orb_[arg_66_1] or 0
end

function var_0_2.randomOrb(arg_67_0, arg_67_1)
	return arg_67_0.randomOrb_[arg_67_1] or {}
end

function var_0_2.mp(arg_68_0, arg_68_1)
	return arg_68_0.mp_[arg_68_1] or 0
end

function var_0_2.mpStep(arg_69_0, arg_69_1)
	return arg_69_0.mpStep_[arg_69_1] or 0
end

function var_0_2.hitSound(arg_70_0, arg_70_1)
	return arg_70_0.hitSound_[arg_70_1]
end

function var_0_2.ignoreDefence(arg_71_0, arg_71_1)
	return (arg_71_0.ignoreDefenceType_[arg_71_1] or 0) == 1
end

function var_0_2.collisionWeaken(arg_72_0, arg_72_1)
	return (arg_72_0.collisionWeaken_[arg_72_1] or var_0_1.DECIMAL_BASE) / var_0_1.DECIMAL_BASE
end

function var_0_2.aTime(arg_73_0, arg_73_1)
	return arg_73_0.aTime_[arg_73_1] or {}
end

function var_0_2.accelerate(arg_74_0, arg_74_1)
	return arg_74_0.accelerate_[arg_74_1] or {}
end

function var_0_2.isFixedTarget(arg_75_0, arg_75_1)
	return (arg_75_0.isFixedTarget_[arg_75_1] or 0) == 1
end

function var_0_2.moveTime(arg_76_0, arg_76_1)
	return arg_76_0.moveTime_[arg_76_1] or 0
end

function var_0_2.move(arg_77_0, arg_77_1)
	return arg_77_0.move_[arg_77_1] or 0
end

function var_0_2.hitMove(arg_78_0, arg_78_1)
	return arg_78_0.hitMove_[arg_78_1] or 0
end

function var_0_2.hitMoveTime(arg_79_0, arg_79_1)
	return arg_79_0.hitMoveTime_[arg_79_1] or 0
end

function var_0_2.enterSpeed(arg_80_0, arg_80_1)
	return arg_80_0.enterSpeed_[arg_80_1] or 0
end

function var_0_2.enterDuration(arg_81_0, arg_81_1)
	return arg_81_0.enterDuration_[arg_81_1] or 0
end

function var_0_2.enterDelayDuration(arg_82_0, arg_82_1)
	return arg_82_0.enterDelayDuration_[arg_82_1] or 0
end

function var_0_2.summonMonster(arg_83_0, arg_83_1)
	return arg_83_0.summonMonster_[arg_83_1] or {}
end

function var_0_2.summonPos(arg_84_0, arg_84_1)
	return arg_84_0.summonPos_[arg_84_1] or 0
end

function var_0_2.harmSaveSkill(arg_85_0, arg_85_1)
	return arg_85_0.harmSaveSkill_[arg_85_1] or 0
end

function var_0_2.xixueSaveSkill(arg_86_0, arg_86_1)
	return arg_86_0.xixueSaveSkill_[arg_86_1] or 0
end

function var_0_2.selectChildren(arg_87_0, arg_87_1)
	return arg_87_0.selectChildren_[arg_87_1] or {}
end

function var_0_2.isInvalidAfterDeath(arg_88_0, arg_88_1)
	return (arg_88_0.isInvalidAfterDeath_[arg_88_1] or 0) == 1
end

function var_0_2.xuliChild(arg_89_0, arg_89_1)
	return arg_89_0.xuliChild_[arg_89_1] or 0
end

function var_0_2.buffOrbSkill(arg_90_0, arg_90_1)
	return arg_90_0.buffOrbSkill_[arg_90_1] or 0
end

function var_0_2.buffOrb(arg_91_0, arg_91_1)
	return arg_91_0.buffOrb_[arg_91_1] or 0
end

function var_0_2.shakeDelay(arg_92_0, arg_92_1)
	return arg_92_0.shakeDelay_[arg_92_1] or 0
end

function var_0_2.shakeLevel(arg_93_0, arg_93_1)
	return arg_93_0.shakeLev_[arg_93_1] or 0
end

function var_0_2.repulsionHero(arg_94_0, arg_94_1)
	return arg_94_0.repulsionHero_[arg_94_1] or {}
end

function var_0_2.isReflect(arg_95_0, arg_95_1)
	return (arg_95_0.isReflect_[arg_95_1] or 0) > 0
end

function var_0_2.skinSkill(arg_96_0, arg_96_1, arg_96_2)
	if arg_96_0.skinSkill_[arg_96_1] and next(arg_96_0.skinSkill_[arg_96_1]) then
		local var_96_0 = arg_96_0.skinSkill_[arg_96_1][arg_96_2]

		return var_96_0 > 0 and var_96_0 or arg_96_1
	end

	return arg_96_1
end

function var_0_2.getItemID(arg_97_0, arg_97_1)
	return arg_97_0.itemID_[arg_97_1]
end

function var_0_2.ignoreImmortal(arg_98_0, arg_98_1)
	return arg_98_0.ignoreImmortal_[arg_98_1] or 0
end

function var_0_2.snowmanUsable(arg_99_0, arg_99_1)
	return arg_99_0.snowmanUsable_[arg_99_1] or 0
end

function var_0_2.isRemp(arg_100_0, arg_100_1)
	return arg_100_0.isRemp_[arg_100_1] or 0
end

function var_0_2.isTriggerSkill(arg_101_0, arg_101_1)
	return (arg_101_0.isTriggerSkill_[arg_101_1] or 0) == 1
end

return var_0_2
