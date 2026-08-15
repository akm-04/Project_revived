local var_0_0 = class("SnowActivity", import(".BaseModel"))
local var_0_1 = import("app.model.ActivityHero")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = 6

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.activity = {}
	arg_1_0.records = {}
	arg_1_0.hero_ = nil
	arg_1_0.activityID = xyd.Activities.SnowActivity
	arg_1_0.battleResultInfo = nil
end

function var_0_0.loadSingleActivity(arg_2_0, arg_2_1)
	local var_2_0 = {
		activity_id = arg_2_0:getActivityID()
	}

	arg_2_0.activities:loadSingleActivity(var_2_0, function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			arg_2_0:updateInfo(arg_3_1)
		end

		if arg_2_1 then
			arg_2_1(arg_3_0, arg_3_1)
		end
	end)
end

function var_0_0.getActivityID(arg_4_0)
	return arg_4_0.activityID or 0
end

function var_0_0.updateInfo(arg_5_0, arg_5_1)
	arg_5_0.activity = arg_5_1
	arg_5_0.baseInfo = arg_5_1.details.base_info or {}
	arg_5_0.snowmanInfo = arg_5_1.details.snowman_info or {}
	arg_5_0.snowArenaInfo = arg_5_1.details.arena_info or {}
	arg_5_0.unLockEffects = arg_5_1.details.unlock_effects or {}

	arg_5_0:initHero()
end

function var_0_0.updateBaseInfo(arg_6_0, arg_6_1)
	arg_6_0.baseInfo = arg_6_1

	arg_6_0:changeHeroEffect()
end

function var_0_0.initHero(arg_7_0)
	if not arg_7_0.hero_ then
		arg_7_0.hero_ = var_0_1.new()
	end

	local var_7_0 = arg_7_0:getSnowmanInfo()

	arg_7_0.hero_:populate(var_7_0)
	arg_7_0:changeHeroEffect()
end

function var_0_0.changeHeroEffect(arg_8_0)
	local var_8_0 = xyd.tables.activitySnowEffect:buff(arg_8_0.baseInfo.effect_id)

	arg_8_0.hero_:setEffectBuffID(var_8_0)
end

function var_0_0.getHero(arg_9_0)
	return arg_9_0.hero_
end

function var_0_0.getSnowmanInfo(arg_10_0)
	return arg_10_0.snowmanInfo or {}
end

function var_0_0.getBaseInfo(arg_11_0)
	return arg_11_0.baseInfo or {}
end

function var_0_0.getActivity(arg_12_0)
	return arg_12_0.activity or {}
end

function var_0_0.getArenaInfo(arg_13_0)
	return arg_13_0.snowArenaInfo or {}
end

function var_0_0.updateArenaInfo(arg_14_0, arg_14_1)
	arg_14_0.snowArenaInfo = arg_14_1
end

function var_0_0.updateExp(arg_15_0, arg_15_1)
	arg_15_0.snowmanInfo.exp = arg_15_1

	arg_15_0.hero_:addExp(arg_15_1 - arg_15_0.hero_:getExp(), 100)
end

function var_0_0.updateColor(arg_16_0, arg_16_1)
	arg_16_0.snowmanInfo.color = arg_16_1

	arg_16_0.hero_:setColor(arg_16_1)
end

function var_0_0.updatePromoteAttrs(arg_17_0, arg_17_1)
	arg_17_0.hero_.promoteAttrs_ = arg_17_1
end

function var_0_0.gacha(arg_18_0, arg_18_1, arg_18_2)
	arg_18_1 = arg_18_1 or {}

	xyd.Backend.get():request(xyd.mid.SNOW_GACHA, arg_18_1, function(arg_19_0, arg_19_1)
		if arg_19_0 == xyd.error.OK and arg_18_2 then
			arg_18_2(arg_19_1)
		end
	end)
end

function var_0_0.gachaExtra(arg_20_0, arg_20_1, arg_20_2)
	arg_20_1 = arg_20_1 or {}

	xyd.Backend.get():request(xyd.mid.SNOW_GACHA_EXTRA, arg_20_1, function(arg_21_0, arg_21_1)
		if arg_21_0 == xyd.error.OK and arg_20_2 then
			arg_20_2(arg_21_1)
		end
	end)
end

function var_0_0.gachaBuy(arg_22_0, arg_22_1, arg_22_2)
	xyd.Backend.get():request(xyd.mid.SNOW_GACHA_BUY, {
		gear_id = arg_22_1
	}, function(arg_23_0, arg_23_1)
		if arg_23_0 == xyd.error.OK and arg_22_2 then
			arg_22_2(arg_23_1)
		end
	end)
end

function var_0_0.getBattleResultInfo(arg_24_0)
	return arg_24_0.battleResultInfo
end

function var_0_0.updateUnlockEffect(arg_25_0, arg_25_1)
	arg_25_0.unLockEffects = arg_25_1
end

function var_0_0.isUnLockEffect(arg_26_0, arg_26_1)
	if arg_26_0.unLockEffects and next(arg_26_0.unLockEffects) then
		for iter_26_0 = 1, #arg_26_0.unLockEffects do
			if arg_26_0.unLockEffects[iter_26_0] == arg_26_1 then
				return true
			end
		end
	end

	return false
end

function var_0_0.addExp(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = arg_27_1 or {}

	var_27_0.activity_id = arg_27_0:getActivityID()

	xyd.Backend.get():request(xyd.mid.SNOW_ACTIVITY_ADD_EXP, var_27_0, function(arg_28_0, arg_28_1)
		if arg_28_0 == xyd.error.OK then
			local var_28_0 = {
				itemID = xyd.tables.hero:levelItem(arg_27_0.hero_:getTableID()),
				itemNum = var_27_0.item_num
			}

			arg_27_0.backpack:removeItem(var_28_0)

			if arg_28_1 and arg_28_1.exp then
				arg_27_0:updateExp(arg_28_1.exp)
			end

			if arg_28_1 and arg_28_1.color then
				arg_27_0:updateColor(arg_28_1.color)
			end
		end

		if arg_27_2 then
			arg_27_2(arg_28_0, arg_28_1)
		end
	end)
end

function var_0_0.addAttr(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = arg_29_1 or {}

	var_29_0.activity_id = arg_29_0:getActivityID()

	xyd.Backend.get():request(xyd.mid.SNOW_ACTIVITY_ADD_ATTR, var_29_0, function(arg_30_0, arg_30_1)
		if arg_30_0 == xyd.error.OK then
			local var_30_0 = 0

			for iter_30_0 = 1, #var_29_0.attr_nums do
				var_30_0 = var_30_0 + var_29_0.attr_nums[iter_30_0]
			end

			local var_30_1 = {
				itemID = xyd.tables.hero:attrItem(arg_29_0.hero_:getTableID()),
				itemNum = var_30_0
			}

			arg_29_0.backpack:removeItem(var_30_1)

			if arg_30_1 and arg_30_1.promote_attrs then
				arg_29_0:updatePromoteAttrs(arg_30_1.promote_attrs)
			end
		end

		if arg_29_2 then
			arg_29_2(arg_30_0, arg_30_1)
		end
	end)
end

function var_0_0.getRankInfo(arg_31_0, arg_31_1)
	local var_31_0 = {
		activity_id = arg_31_0:getActivityID()
	}

	xyd.Backend.get():request(xyd.mid.SNOW_ACTIVITY_RANK_LIST, var_31_0, function(arg_32_0, arg_32_1)
		if arg_31_1 then
			arg_31_1(arg_32_0, arg_32_1)
		end
	end)
end

function var_0_0.changeDefense(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = arg_33_1 or {}

	var_33_0.activity_id = arg_33_0:getActivityID()

	xyd.Backend.get():request(xyd.mid.SNOW_ACTIVITY_EDIT_DEFENSE, var_33_0, function(arg_34_0, arg_34_1)
		if arg_34_0 == xyd.error.OK and arg_34_1 and arg_34_1.arena_info then
			arg_33_0:updateArenaInfo(arg_34_1.arena_info)
		end

		if arg_33_2 then
			arg_33_2(arg_34_0, arg_34_1)
		end
	end)
end

function var_0_0.matchEnemy(arg_35_0, arg_35_1)
	local var_35_0 = {
		activity_id = arg_35_0:getActivityID()
	}

	xyd.Backend.get():request(xyd.mid.SNOW_ACTIVITY_MATCH_ENEMY, var_35_0, function(arg_36_0, arg_36_1)
		if arg_35_1 then
			arg_35_1(arg_36_0, arg_36_1)
		end
	end)
end

function var_0_0.getFightEnemyInfo(arg_37_0, arg_37_1, arg_37_2)
	local var_37_0 = arg_37_1 or {}

	var_37_0.activity_id = arg_37_0:getActivityID()

	xyd.Backend.get():request(xyd.mid.SNOW_ACTIVITY_GET_ENEMY_INFO, var_37_0, function(arg_38_0, arg_38_1)
		if arg_37_2 then
			arg_37_2(arg_38_0, arg_38_1)
		end
	end)
end

function var_0_0.fightResult(arg_39_0, arg_39_1, arg_39_2)
	local var_39_0 = arg_39_1 or {}

	var_39_0.activity_id = arg_39_0:getActivityID()

	xyd.Backend.get():request(xyd.mid.SNOW_ACTIVITY_FIGHT_RESULT, var_39_0, function(arg_40_0, arg_40_1)
		if arg_40_0 == xyd.error.OK then
			local var_40_0 = {
				itemNum = 1,
				itemID = xyd.tables.misc.snowmanChallengeItem
			}

			arg_39_0.backpack:removeItem(var_40_0)

			if arg_40_1 and arg_40_1.arena_info then
				arg_39_0.battleResultInfo = arg_40_1.arena_info
			end
		end

		if arg_39_2 then
			arg_39_2(arg_40_0, arg_40_1)
		end
	end)
end

function var_0_0.equipEffect(arg_41_0, arg_41_1, arg_41_2)
	local var_41_0 = arg_41_1 or {}

	var_41_0.activity_id = arg_41_0:getActivityID()

	xyd.Backend.get():request(xyd.mid.SNOW_ACTIVITY_EQUIP_EFFECT, var_41_0, function(arg_42_0, arg_42_1)
		if arg_42_0 == xyd.error.OK and arg_42_1 and arg_42_1.base_info then
			arg_41_0:updateBaseInfo(arg_42_1.base_info)
		end

		if arg_41_2 then
			arg_41_2(arg_42_0, arg_42_1)
		end
	end)
end

function var_0_0.battleRecords(arg_43_0, arg_43_1, arg_43_2)
	local var_43_0 = arg_43_1 or {}

	var_43_0.activity_id = arg_43_0:getActivityID()

	xyd.Backend.get():request(xyd.mid.SNOW_ACTIVITY_BATTLE_RECORDS, var_43_0, function(arg_44_0, arg_44_1)
		if arg_43_2 then
			arg_43_2(arg_44_0, arg_44_1)
		end
	end)
end

function var_0_0.getReport(arg_45_0, arg_45_1, arg_45_2)
	if param and param.report_key and arg_45_0.records[arg_45_1.report_key] then
		if arg_45_2 then
			arg_45_2(xyd.error.OK, arg_45_0.records[arg_45_1.report_key])
		end

		return
	end

	local var_45_0 = arg_45_1 or {}

	var_45_0.activity_id = arg_45_0:getActivityID()

	xyd.Backend.get():request(xyd.mid.SNOW_ACTIVITY_GET_REPORT, var_45_0, function(arg_46_0, arg_46_1)
		if arg_46_0 == xyd.error.OK then
			arg_45_0.records[var_45_0.report_key] = arg_46_1
		end

		if arg_45_2 then
			arg_45_2(arg_46_0, arg_46_1)
		end
	end)
end

function var_0_0.exchangeItem(arg_47_0, arg_47_1, arg_47_2)
	local var_47_0 = arg_47_0:getActivityID()

	arg_47_0.activities:getActivityReward(var_47_0, arg_47_1, arg_47_2)
end

function var_0_0.formatNewHeros(arg_48_0, arg_48_1, arg_48_2, arg_48_3)
	local var_48_0 = {
		1,
		1,
		1,
		1,
		0,
		0
	}
	local var_48_1 = {
		0,
		0,
		0,
		0,
		0,
		0
	}
	local var_48_2 = {
		0,
		0,
		0,
		0,
		0,
		0
	}

	for iter_48_0, iter_48_1 in pairs(arg_48_1) do
		iter_48_1.color_ = arg_48_3
		iter_48_1.level_ = arg_48_2
		iter_48_1.isSkinOn_ = 0
		iter_48_1.inscriptItems_ = {}

		if iter_48_1:beforeAwakenID() > 0 then
			iter_48_1:setTableID(iter_48_1:beforeAwakenID())
		end

		local var_48_3 = {
			arg_48_2,
			arg_48_2,
			arg_48_2,
			arg_48_2,
			0,
			0
		}

		arg_48_0:renewHeroInfo(iter_48_1, var_48_3, var_48_1, var_48_2)
		iter_48_1:updatePracticeAwardAttr()
	end
end

function var_0_0.renewHeroInfo(arg_49_0, arg_49_1, arg_49_2, arg_49_3, arg_49_4)
	arg_49_1.skillLev_ = {}
	arg_49_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_49_2[xyd.SKILL_INDEX.Energy])

	if arg_49_1.color_ >= xyd.EquipQuality.GREEN then
		arg_49_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_49_2[xyd.SKILL_INDEX.Green])
	else
		arg_49_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_49_1.color_ >= xyd.EquipQuality.BLUE then
		arg_49_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_49_2[xyd.SKILL_INDEX.Blue])
	else
		arg_49_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_49_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_49_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_49_2[xyd.SKILL_INDEX.Purple])
	else
		arg_49_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_49_1:isAwaken() then
		arg_49_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_49_2[xyd.SKILL_INDEX.Awake])
	else
		arg_49_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	if arg_49_1:isAwakeTwice() then
		arg_49_1.skillLev_[xyd.SKILL_INDEX.AwakeTwice] = tonumber(arg_49_2[xyd.SKILL_INDEX.AwakeTwice])
	else
		arg_49_1.skillLev_[xyd.SKILL_INDEX.AwakeTwice] = false
	end

	arg_49_1.equips_ = {}

	for iter_49_0 = 1, var_0_3 do
		table.insert(arg_49_1.equips_, tonumber(arg_49_4[iter_49_0]))
	end

	arg_49_1.fumo_ = {}

	for iter_49_1 = 1, var_0_3 do
		table.insert(arg_49_1.fumo_, tonumber(arg_49_3[iter_49_1]))
	end

	arg_49_1.fumoLev_ = {
		0,
		0,
		0,
		0,
		0,
		0
	}
end

function var_0_0.updateHeroEffect(arg_50_0, arg_50_1, arg_50_2)
	local var_50_0 = xyd.tables.activitySnowEffect:buff(arg_50_1)

	if var_50_0 == 0 then
		return
	end

	local var_50_1 = arg_50_2:getContentSize()
	local var_50_2, var_50_3, var_50_4 = xyd.tables.dbuff:effectResource(var_50_0)
	local var_50_5 = var_0_2.new(var_50_2, var_50_3, var_50_4)

	var_50_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_50_5:setPosition(var_50_1.width / 2, var_50_1.height / 2)
	var_50_5:addTo(arg_50_2)
	var_50_5:play(nil, true)

	return var_50_5
end

return var_0_0
