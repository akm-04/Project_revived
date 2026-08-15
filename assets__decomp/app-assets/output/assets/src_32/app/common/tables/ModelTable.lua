local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("ModelTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.modelIDs_ = {}
	arg_1_0.names_ = {}
	arg_1_0.types_ = {}
	arg_1_0.resources_ = {}
	arg_1_0.live2d_ = {}
	arg_1_0.live2dScale_ = {}
	arg_1_0.card_ = {}
	arg_1_0.smallCard_ = {}
	arg_1_0.newSmallCard_ = {}
	arg_1_0.avatars1_ = {}
	arg_1_0.avatars2_ = {}
	arg_1_0.effectResource_ = {}
	arg_1_0.deathSound_ = {}
	arg_1_0.scale_ = {}
	arg_1_0.uiScale_ = {}
	arg_1_0.creatsUiScale_ = {}
	arg_1_0.duration_ = {}
	arg_1_0.hurtDuration_ = {}
	arg_1_0.transparentCard_ = {}
	arg_1_0.campaignCard_ = {}
	arg_1_0.moveSound_ = {}
	arg_1_0.winSound_ = {}
	arg_1_0.normalAttack_ = {}
	arg_1_0.attack1_ = {}
	arg_1_0.attack2_ = {}
	arg_1_0.attack3_ = {}
	arg_1_0.attack4_ = {}
	arg_1_0.summonDuration_ = {}
	arg_1_0.changeDuration_ = {}
	arg_1_0.dynamicType_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("model.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("model", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.id)

	table.insert(arg_2_0.modelIDs_, var_2_0)

	arg_2_0.names_[var_2_0] = arg_2_1.name
	arg_2_0.types_[var_2_0] = arg_2_1.type
	arg_2_0.resources_[var_2_0] = {
		arg_2_1.json,
		arg_2_1.atlas
	}
	arg_2_0.live2d_[var_2_0] = arg_2_1.live2d
	arg_2_0.live2dScale_[var_2_0] = tonumber(arg_2_1.live2d_scale)
	arg_2_0.card_[var_2_0] = arg_2_1.card
	arg_2_0.smallCard_[var_2_0] = arg_2_1.small_card
	arg_2_0.avatars1_[var_2_0] = arg_2_1.avatars
	arg_2_0.avatars2_[var_2_0] = arg_2_1.avatars2
	arg_2_0.effectResource_[var_2_0] = {
		arg_2_1.effectJson,
		arg_2_1.effectAtlas
	}
	arg_2_0.deathSound_[var_2_0] = arg_2_1.death_sound
	arg_2_0.scale_[var_2_0] = tonumber(arg_2_1.scale)
	arg_2_0.uiScale_[var_2_0] = tonumber(arg_2_1.ui_scale)
	arg_2_0.creatsUiScale_[var_2_0] = tonumber(arg_2_1.creats_ui_scale)
	arg_2_0.transparentCard_[var_2_0] = arg_2_1.transparent_card
	arg_2_0.campaignCard_[var_2_0] = arg_2_1.campaign_card
	arg_2_0.duration_[var_2_0] = {}
	arg_2_0.dynamicType_[var_2_0] = tonumber(arg_2_1.is_dynamic)
	arg_2_0.newSmallCard_[var_2_0] = arg_2_1.s_card

	for iter_2_0 = 1, 10 do
		table.insert(arg_2_0.duration_[var_2_0], tonumber(arg_2_1["duration" .. iter_2_0]))
	end

	local var_2_1 = var_0_1.splitToNumber(arg_2_1.duration_x, "|")

	for iter_2_1 = 1, #var_2_1 do
		if var_2_1[iter_2_1] > 0 then
			table.insert(arg_2_0.duration_[var_2_0], var_2_1[iter_2_1])
		end
	end

	arg_2_0.hurtDuration_[var_2_0] = tonumber(arg_2_1.hurt_duration)
	arg_2_0.summonDuration_[var_2_0] = tonumber(arg_2_1.summon_duration)
	arg_2_0.changeDuration_[var_2_0] = tonumber(arg_2_1.change_duration)
	arg_2_0.moveSound_[var_2_0] = arg_2_1.sound_move
	arg_2_0.winSound_[var_2_0] = arg_2_1.sound_victory
	arg_2_0.normalAttack_[var_2_0] = arg_2_1.sound_skill0
	arg_2_0.attack1_[var_2_0] = arg_2_1.sound_skill1
	arg_2_0.attack2_[var_2_0] = arg_2_1.sound_skill2
	arg_2_0.attack3_[var_2_0] = arg_2_1.sound_skill3
	arg_2_0.attack4_[var_2_0] = arg_2_1.sound_skill4
end

function var_0_2.modelIDs(arg_3_0)
	return arg_3_0.modelIDs_
end

function var_0_2.name(arg_4_0, arg_4_1)
	return arg_4_0.names_[arg_4_1] or ""
end

function var_0_2.getMoveSound(arg_5_0, arg_5_1)
	return arg_5_0.moveSound_[arg_5_1] or ""
end

function var_0_2.getWinSound(arg_6_0, arg_6_1)
	return arg_6_0.winSound_[arg_6_1] or ""
end

function var_0_2.getNormalAttackSound(arg_7_0, arg_7_1)
	return arg_7_0.normalAttack_[arg_7_1] or ""
end

function var_0_2.getAttack1Sound(arg_8_0, arg_8_1)
	return arg_8_0.attack1_[arg_8_1] or ""
end

function var_0_2.getAttack2Sound(arg_9_0, arg_9_1)
	return arg_9_0.attack2_[arg_9_1] or ""
end

function var_0_2.getAttack3Sound(arg_10_0, arg_10_1)
	return arg_10_0.attack3_[arg_10_1] or ""
end

function var_0_2.getAttack4Sound(arg_11_0, arg_11_1)
	return arg_11_0.attack4_[arg_11_1] or ""
end

function var_0_2.description(arg_12_0, arg_12_1)
	return string.format("%d %s %s", arg_12_1, arg_12_0.names_[arg_12_1], arg_12_0.types_[arg_12_1])
end

function var_0_2.resource(arg_13_0, arg_13_1)
	return unpack(arg_13_0.resources_[arg_13_1] or {})
end

function var_0_2.avatar(arg_14_0, arg_14_1)
	return arg_14_0.avatars1_[arg_14_1]
end

function var_0_2.avatar2(arg_15_0, arg_15_1)
	return arg_15_0.avatars2_[arg_15_1]
end

function var_0_2.effectResource(arg_16_0, arg_16_1)
	return unpack(arg_16_0.effectResource_[arg_16_1] or {})
end

function var_0_2.deathSound(arg_17_0, arg_17_1)
	return arg_17_0.deathSound_[arg_17_1] or ""
end

function var_0_2.live2d(arg_18_0, arg_18_1)
	return arg_18_0.live2d_[arg_18_1] or ""
end

function var_0_2.live2dScale(arg_19_0, arg_19_1)
	return arg_19_0.live2dScale_[arg_19_1] or 0.5
end

function var_0_2.card(arg_20_0, arg_20_1)
	return arg_20_0.card_[arg_20_1] or ""
end

function var_0_2.smallCard(arg_21_0, arg_21_1)
	return arg_21_0.smallCard_[arg_21_1] or ""
end

function var_0_2.sCard(arg_22_0, arg_22_1)
	return string.gsub(arg_22_0.smallCard_[arg_22_1] or "", "small", "s")
end

function var_0_2.scale(arg_23_0, arg_23_1)
	return arg_23_0.scale_[arg_23_1] or 0
end

function var_0_2.duration(arg_24_0, arg_24_1, arg_24_2)
	if arg_24_2 then
		return arg_24_0.duration_[arg_24_1][arg_24_2] or 30
	end
end

function var_0_2.hurtDuration(arg_25_0, arg_25_1)
	return arg_25_0.hurtDuration_[arg_25_1] or 30
end

function var_0_2.uiScale(arg_26_0, arg_26_1)
	return arg_26_0.uiScale_[arg_26_1] or 1
end

function var_0_2.creatsUiScale(arg_27_0, arg_27_1)
	return arg_27_0.creatsUiScale_[arg_27_1] or arg_27_0:uiScale(arg_27_1) * 0.5
end

function var_0_2.transparentCard(arg_28_0, arg_28_1)
	return arg_28_0.transparentCard_[arg_28_1] or {}
end

function var_0_2.summonDuration(arg_29_0, arg_29_1)
	return arg_29_0.summonDuration_[arg_29_1] or 0
end

function var_0_2.changeDuration(arg_30_0, arg_30_1)
	return arg_30_0.changeDuration_[arg_30_1] or 0
end

function var_0_2.campaignCard(arg_31_0, arg_31_1)
	return arg_31_0.campaignCard_[arg_31_1] or ""
end

function var_0_2.dynamicType(arg_32_0, arg_32_1)
	return arg_32_0.dynamicType_[arg_32_1] or 0
end

function var_0_2.newSmallCard(arg_33_0, arg_33_1)
	return arg_33_0.newSmallCard_[arg_33_1] or ""
end

return var_0_2
