local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("BattleConfigTable")
local var_0_3 = {
	"parse_tostring",
	"parse_tonumber",
	"parse_splitToString",
	"parse_splitToNumber"
}

function var_0_2.ctor(arg_1_0)
	arg_1_0.dict_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("battle_config.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("battle_config", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse_tostring(arg_2_0, arg_2_1, arg_2_2)
	arg_2_0.dict_[arg_2_2] = arg_2_1
end

function var_0_2.parse_tonumber(arg_3_0, arg_3_1, arg_3_2)
	arg_3_0.dict_[arg_3_2] = tonumber(arg_3_1)
end

function var_0_2.parse_splitToString(arg_4_0, arg_4_1, arg_4_2)
	arg_4_0.dict_[arg_4_2] = var_0_1.split(arg_4_1, "|")
end

function var_0_2.parse_splitToNumber(arg_5_0, arg_5_1, arg_5_2)
	arg_5_0.dict_[arg_5_2] = var_0_1.splitToNumber(arg_5_1, "|")
end

function var_0_2.parse(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1.key
	local var_6_1 = arg_6_1.value

	if var_6_0 == "action_needs_progress" then
		arg_6_0.actionNeedsProgress = tonumber(var_6_1)
	elseif var_6_0 == "extra_progress_param" then
		arg_6_0.extraActionProgressParam = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "defence_param" then
		arg_6_0.defenceParam = tonumber(var_6_1)
	elseif var_6_0 == "damage_float" then
		arg_6_0.damageFloat = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "min_damage" then
		arg_6_0.minimumAttackDamage = tonumber(var_6_1)
	elseif var_6_0 == "retrain_add_crit_rate" then
		arg_6_0.retrainAddCritRate = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "retrain_strong_attack_rate" then
		arg_6_0.retrainStrongAttackRate = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "strong_attack_damage_rate" then
		arg_6_0.strongAttackDamageRate = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "retrained_damage_rate" then
		arg_6_0.retrainedDamageRate = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "retrained_miss_rate" then
		arg_6_0.retrainedMissRate = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "miss_damage_rate" then
		arg_6_0.missDamageRate = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "min_resist_rate" then
		arg_6_0.minimumResistRate = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "max_resist_rate" then
		arg_6_0.maximumResistRate = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "round_hp_increase" then
		arg_6_0.roundHPIncrease = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "dizzy_buff_id" then
		arg_6_0.dizzyBuffID = tonumber(var_6_1)
	elseif var_6_0 == "misc_animation_duration" then
		arg_6_0.miscAnimationDuration = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "action_indicator_animation_duration" then
		arg_6_0.actionIndicatorAnimationDuration = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "arrow_animation_duration" then
		arg_6_0.arrowAnimationDuration = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "attack_move_animation_duration" then
		arg_6_0.attackMoveAnimationDuration = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "progress_animation_duration" then
		arg_6_0.progressAnimationDuration = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "shake_screen_duration" then
		arg_6_0.shakeScreenDuration = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "shake_screen_strength" then
		arg_6_0.shakeScreenStrength = tonumber(var_6_1)
	elseif var_6_0 == "dark_background_opacity" then
		arg_6_0.darkBackgroundOpacity = tonumber(var_6_1)
	elseif var_6_0 == "background_color_duration" then
		arg_6_0.backgroundColorDuration = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "background_reset_duration" then
		arg_6_0.backgroundResetDuration = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "special_skill_fg_scale_factor" then
		arg_6_0.specialSkillForegroundScaleFactor = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "special_skill_fg_present_duration" then
		arg_6_0.specialSkillForegroundPresentDuration = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "special_skill_fg_dismiss_duration" then
		arg_6_0.specialSkillForegroundDismissDuration = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "special_skill_fg_last_time" then
		arg_6_0.specialSkillForegroundLastTime = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "special_skill_name_shake_strength" then
		arg_6_0.specialSkillNameShakeStrength = tonumber(var_6_1)
	elseif var_6_0 == "float_delta_y" then
		arg_6_0.floatAnimationDeltaY = tonumber(var_6_1)
	elseif var_6_0 == "float_animation_duration" then
		arg_6_0.floatAnimationDuration = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "float_interval" then
		arg_6_0.floatAnimationInternal = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "battle_float_scale_duration" then
		arg_6_0.battleFloatScaleDuration = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "action_delay" then
		arg_6_0.actionDelay = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "model_scale_factor" then
		arg_6_0.modelScaleFactor = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "boss_model_scale_factor" then
		arg_6_0.bossModelScaleFactor = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "special_skill_model_scale" then
		arg_6_0.specialSkillModelScaleFactor = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "special_skill_model_y" then
		arg_6_0.specialSkillModelPositionY = tonumber(var_6_1)
	elseif var_6_0 == "special_skill_model_opacity" then
		arg_6_0.specialSkillModelOpacity = math.max(0, math.min(255, tonumber(var_6_1)))
	elseif var_6_0 == "scene_show_duration" then
		arg_6_0.sceneShowAnimationDuration = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "scene_hide_duration" then
		arg_6_0.sceneHideAnimationDuration = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "battle_title_duration" then
		arg_6_0.battleTitleShowDuration = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "loading_min_duration" then
		arg_6_0.minimumLoadingDuration = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "start_circle_distance" then
		arg_6_0.startCircleDistance = tonumber(var_6_1)
	elseif var_6_0 == "float_fadeout_delay" then
		arg_6_0.floatFadeOutDelay = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "remove_hero_model_duration" then
		arg_6_0.removeHeroModelDuration = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "attack_unit_paowuxian_duration" then
		arg_6_0.attackunitPaowuxianDuration = tonumber(var_6_1)
	elseif var_6_0 == "interval" then
		arg_6_0.interval = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "monster_drop_mana" then
		arg_6_0.monsterDropMana = tonumber(var_6_1)
	elseif var_6_0 == "item_drop_offy" then
		arg_6_0.itemDropOffY = tonumber(var_6_1)
	elseif var_6_0 == "item_drop_offx" then
		arg_6_0.itemDropOffX = tonumber(var_6_1)
	elseif var_6_0 == "buff_harm_base_duration" then
		arg_6_0.buffHarmBaseDuration = tonumber(var_6_1)
	elseif var_6_0 == "hp_move_base" then
		arg_6_0.hpProgressMoveBase = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "hp_move_step" then
		arg_6_0.hpProgressMoveStep = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "hp_brake_percent" then
		arg_6_0.hpProgressBrakePercent = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "hp_brake_base" then
		arg_6_0.hpProgressBrakeBase = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "magic_resist_resilience_param_1" then
		arg_6_0.mokangBaojiParam1 = tonumber(var_6_1)
	elseif var_6_0 == "magic_resist_resilience_param_2" then
		arg_6_0.mokangBaojiParam2 = tonumber(var_6_1)
	elseif var_6_0 == "magic_resist_resilience_param_3" then
		arg_6_0.mokangBaojiParam3 = tonumber(var_6_1)
	elseif var_6_0 == "hujia_resist_resilience_param_1" then
		arg_6_0.hujiaBaojiParam1 = tonumber(var_6_1)
	elseif var_6_0 == "hujia_resist_resilience_param_2" then
		arg_6_0.hujiaBaojiParam2 = tonumber(var_6_1)
	elseif var_6_0 == "hujia_resist_resilience_param_3" then
		arg_6_0.hujiaBaojiParam3 = tonumber(var_6_1)
	elseif var_6_0 == "ad_baoji_param1" then
		arg_6_0.adBaojiParam1 = tonumber(var_6_1)
	elseif var_6_0 == "ap_baoji_param1" then
		arg_6_0.apBaojiParam1 = tonumber(var_6_1)
	elseif var_6_0 == "ad_baoji_level_param1" then
		arg_6_0.adBaojiLevelParam1 = tonumber(var_6_1)
	elseif var_6_0 == "ap_baoji_level_param1" then
		arg_6_0.apBaojiLevelParam1 = tonumber(var_6_1)
	elseif var_6_0 == "buff_hit_param_1" then
		arg_6_0.buffHitParam1 = tonumber(var_6_1)
	elseif var_6_0 == "buff_hit_param_2" then
		arg_6_0.buffHitParam2 = tonumber(var_6_1)
	elseif var_6_0 == "move_speed_accelerate" then
		arg_6_0.speedAccelerate = tonumber(var_6_1)
	elseif var_6_0 == "red_hp_effect_rate" then
		arg_6_0.redHpRate = tonumber(var_6_1)
	elseif var_6_0 == "revive_count" then
		arg_6_0.reviveCount = tonumber(var_6_1)
	elseif var_6_0 == "break_duration" then
		arg_6_0.breakDuration = tonumber(var_6_1)
	elseif var_6_0 == "battle_queue_skill_delay" then
		arg_6_0.skillDelayQueue = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "counter_helix_rate" then
		arg_6_0.helixRate = tonumber(var_6_1)
	elseif var_6_0 == "counter_helix_cd" then
		arg_6_0.specialSkillInterval = tonumber(var_6_1)
	elseif var_6_0 == "axe_kill_mp" then
		arg_6_0.axeKillMp = tonumber(var_6_1)
	elseif var_6_0 == "axe_skill_hp_limit" then
		arg_6_0.axeSkillHpLimit = tonumber(var_6_1)
	elseif var_6_0 == "axe_skill_harm_rate" then
		arg_6_0.axeSkillHarmRate = tonumber(var_6_1)
	elseif var_6_0 == "arena_hp_increase" then
		arg_6_0.arenaHpIncrease = tonumber(var_6_1)
	elseif var_6_0 == "formation_walk_position" then
		arg_6_0.formationWalkQueue = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "formation_a" then
		arg_6_0.storyFormationA = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "formation_b" then
		arg_6_0.storyFormationB = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "select_radius_width" then
		arg_6_0.manualSelectWidth = tonumber(var_6_1)
	elseif var_6_0 == "boss_time_threshold" then
		arg_6_0.bossAwakenCount = tonumber(var_6_1)
	elseif var_6_0 == "element_boss_buff_rate" then
		arg_6_0.elementBossBuffRate = tonumber(var_6_1)
	elseif var_6_0 == "rehpmp_limit_chapter" then
		arg_6_0.rehpmpLimitChapter = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "rehpmp_limit_rate" then
		arg_6_0.rehpmpLimitRate = tonumber(var_6_1)
	elseif var_6_0 == "monster_nian_id" then
		arg_6_0.bossNianIds = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "monster_nian_number" then
		arg_6_0.bossNianAttackCounts = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "challenge_remp" then
		arg_6_0.challengeRemp = tonumber(var_6_1)
	elseif var_6_0 == "single_boss_buff_rate" then
		arg_6_0.singleBossBuffRate = tonumber(var_6_1)
	elseif var_6_0 == "harm_limit_para" then
		arg_6_0.harmLimitPara = tonumber(var_6_1)
	elseif var_6_0 == "activity_arena_partner_interval" then
		arg_6_0.activityArenaPartnerInterval = tonumber(var_6_1)
	else
		local var_6_2 = tonumber(arg_6_1.parse) or 1

		if var_0_3[var_6_2] then
			local var_6_3 = var_0_3[var_6_2]

			var_0_2[var_6_3](arg_6_0, var_6_1, var_6_0)
		end
	end
end

function var_0_2.getValue(arg_7_0, arg_7_1)
	return arg_7_0.dict_[arg_7_1]
end

return var_0_2
