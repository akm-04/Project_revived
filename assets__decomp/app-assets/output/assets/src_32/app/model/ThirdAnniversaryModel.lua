local var_0_0 = class("ThirdAnniversaryModel", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	Unlimit = 2,
	Normal = 1
}
local var_0_3 = 6

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.THIRD_ANNIVERSARY_BOSS, handler(arg_2_0, arg_2_0.onThirdAnniversaryBoss_))
end

function var_0_0.onThirdAnniversaryBoss_(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1.params.boss_info

	arg_3_0.total_damage = math.floor(var_3_0.total_damage)
	arg_3_0.self_damage = math.floor(var_3_0.self_damage)
	arg_3_0.total_rank = var_3_0.rank
	arg_3_0.challenge_times = var_3_0.challenge_times
	arg_3_0.boss_hp_limit = var_3_0.boss_hp
	arg_3_0.boss_hp = arg_3_0.boss_hp_limit - arg_3_0.total_damage
	arg_3_0.boss_stage = arg_3_0:getBossStage()
	arg_3_0.day_count = var_3_0.day_count
	arg_3_0.boss_id = arg_3_0:getBossID()
	arg_3_0.model_id = xyd.tables.hero:modelID(arg_3_0.boss_id)
end

function var_0_0.getBossID(arg_4_0)
	if arg_4_0.boss_stage == 1 then
		return xyd.tables.thirdAnniversaryBoss:stage1(arg_4_0.day_count)
	elseif arg_4_0.boss_stage == 2 then
		return xyd.tables.thirdAnniversaryBoss:stage2(arg_4_0.day_count)
	elseif arg_4_0.boss_stage == 3 then
		return xyd.tables.thirdAnniversaryBoss:stage3(arg_4_0.day_count)
	end
end

function var_0_0.getBossStage(arg_5_0)
	local var_5_0 = 0

	for iter_5_0, iter_5_1 in ipairs(xyd.tables.misc.thirdAnniversaryBossStage) do
		if iter_5_1 >= arg_5_0.boss_hp / arg_5_0.boss_hp_limit then
			var_5_0 = var_5_0 + 1
		end
	end

	if var_5_0 == 0 then
		var_5_0 = var_5_0 + 1
	end

	return var_5_0
end

function var_0_0.getBossRankList(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_1 or {}

	xyd.Backend.get():request(xyd.mid.THIRD_ANNIVERSARY_BOSS_RANK, var_6_0, function(arg_7_0, arg_7_1)
		if arg_7_0 == xyd.error.OK then
			arg_6_0.boss_rankInfo = arg_7_1 or {}
		end

		if arg_6_2 then
			arg_6_2(arg_7_0, arg_7_1)
		end
	end)
end

function var_0_0.loadInfo(arg_8_0, arg_8_1)
	xyd.Backend.get():request(xyd.mid.THIRD_ANNIVERSARY, nil, function(arg_9_0, arg_9_1)
		if arg_9_0 == xyd.error.OK then
			arg_8_0.diglettInfo = arg_9_1.diglett_info
			arg_8_0.collectInfo = arg_9_1.collect_info
			arg_8_0.bossInfo = arg_9_1.boss_info

			if arg_8_1 then
				arg_8_1(arg_9_0, arg_9_1)
			end
		end
	end)
end

function var_0_0.getLuckybagAward(arg_10_0, arg_10_1, arg_10_2)
	arg_10_1 = arg_10_1 or {}

	xyd.Backend.get():request(xyd.mid.LUCKYBAG_AWARD, arg_10_1, function(arg_11_0, arg_11_1)
		arg_10_2(arg_11_0, arg_11_1)
	end)
end

function var_0_0.getWishingpool(arg_12_0, arg_12_1, arg_12_2)
	arg_12_1 = arg_12_1 or {}

	xyd.Backend.get():request(xyd.mid.THIRD_ANNI_WISH, arg_12_1, function(arg_13_0, arg_13_1)
		arg_12_2(arg_13_0, arg_13_1)
	end)
end

function var_0_0.getWishingpoolList(arg_14_0, arg_14_1)
	xyd.Backend.get():request(xyd.mid.THIRD_ANNI_WISH_LIST, nil, function(arg_15_0, arg_15_1)
		arg_14_1(arg_15_0, arg_15_1)
	end, nil, nil, false)
end

function var_0_0.getWishingpoolAwards(arg_16_0, arg_16_1, arg_16_2)
	arg_16_1 = arg_16_1 or {}

	xyd.Backend.get():request(xyd.mid.THIRD_ANNI_WISH_AWARD, arg_16_1, function(arg_17_0, arg_17_1)
		if arg_17_0 == xyd.error.OK then
			arg_16_2(arg_17_0, arg_17_1)
		end
	end)
end

function var_0_0.getWishingCoin(arg_18_0, arg_18_1)
	xyd.Backend.get():request(xyd.mid.THIRD_ANNI_WISHING_COIN, nil, function(arg_19_0, arg_19_1)
		if arg_18_1 then
			arg_18_1(arg_19_0, arg_19_1)
		end
	end)
end

function var_0_0.loadMissionInfo(arg_20_0, arg_20_1)
	xyd.Backend.get():request(xyd.mid.THIRD_ANNI_MISSION, nil, function(arg_21_0, arg_21_1)
		if arg_21_0 == xyd.error.OK then
			arg_20_0.missionInfo = arg_21_1

			if arg_20_1 then
				arg_20_1()
			end
		end
	end)
end

function var_0_0.getMissionReward(arg_22_0, arg_22_1, arg_22_2)
	xyd.Backend.get():request(xyd.mid.THIRD_ANNI_MISSION_REWARD, {
		mission_id = arg_22_1
	}, function(arg_23_0, arg_23_1)
		if arg_22_2 then
			arg_22_2(arg_23_0, arg_23_1)
		end
	end)
end

function var_0_0.thirdAnniDiglettStart(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = arg_24_1 or {}

	xyd.Backend.get():request(xyd.mid.THIRD_ANNI_DIGLETT_START, var_24_0, function(arg_25_0, arg_25_1)
		if arg_25_0 == xyd.error.OK then
			arg_24_0:handleRespone(arg_25_1)
		end

		if arg_24_2 then
			arg_24_2(arg_25_0, arg_25_1)
		end
	end)
end

function var_0_0.thirdAnniDiglettEnd(arg_26_0, arg_26_1, arg_26_2)
	local var_26_0 = arg_26_1 or {}

	xyd.Backend.get():request(xyd.mid.THIRD_ANNI_DIGLETT_END, var_26_0, function(arg_27_0, arg_27_1)
		if arg_27_0 == xyd.error.OK then
			arg_26_0:handleRespone(arg_27_1)
		end

		if arg_26_2 then
			arg_26_2(arg_27_0, arg_27_1)
		end
	end)
end

function var_0_0.thirdAnniDiglettExchange(arg_28_0, arg_28_1, arg_28_2)
	local var_28_0 = arg_28_1 or {}

	xyd.Backend.get():request(xyd.mid.THIRD_ANNI_DIGLETT_EXCHANGE, var_28_0, function(arg_29_0, arg_29_1)
		if arg_29_0 == xyd.error.OK then
			arg_28_0:handleRespone(arg_29_1)
		end

		if arg_28_2 then
			arg_28_2(arg_29_0, arg_29_1)
		end
	end)
end

function var_0_0.thirdAnniDiglettRank(arg_30_0, arg_30_1, arg_30_2)
	local var_30_0 = arg_30_1 or {}

	xyd.Backend.get():request(xyd.mid.THIRD_ANNI_DIGLETT_RANK, var_30_0, function(arg_31_0, arg_31_1)
		if arg_31_0 == xyd.error.OK then
			-- block empty
		end

		if arg_30_2 then
			arg_30_2(arg_31_0, arg_31_1)
		end
	end)
end

function var_0_0.thirdAnniDiglettDouble(arg_32_0, arg_32_1, arg_32_2)
	local var_32_0 = arg_32_1 or {}

	xyd.Backend.get():request(xyd.mid.THIRD_ANNI_DIGLETT_DOUBLE, var_32_0, function(arg_33_0, arg_33_1)
		if arg_33_0 == xyd.error.OK then
			arg_32_0:handleRespone(arg_33_1)
		end

		if arg_32_2 then
			arg_32_2(arg_33_0, arg_33_1)
		end
	end)
end

function var_0_0.thirdAnniPersonAward(arg_34_0, arg_34_1, arg_34_2)
	local var_34_0 = arg_34_1 or {}

	xyd.Backend.get():request(xyd.mid.THIRD_ANNIVERSARY_BOSS_PERSON_AWARD, var_34_0, function(arg_35_0, arg_35_1)
		if arg_35_0 == xyd.error.OK then
			arg_34_0:handleRespone(arg_35_1)
		end

		if arg_34_2 then
			arg_34_2(arg_35_0, arg_35_1)
		end
	end)
end

function var_0_0.handleRespone(arg_36_0, arg_36_1)
	if arg_36_1.challenge_times then
		arg_36_0.diglettInfo.challenge_times = arg_36_1.challenge_times

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.REfRESH_THIRD_DIGLETT_TIMES
		})
	end

	if arg_36_1.inf_score then
		arg_36_0.diglettInfo.inf_score = arg_36_1.inf_score
	end

	if arg_36_1.point then
		arg_36_0.diglettInfo.point = arg_36_1.point
	end

	if arg_36_1.awards then
		arg_36_0.selfPlayer:handleRewards(arg_36_1.awards)
	end
end

function var_0_0.startDiglettHammer(arg_37_0)
	local var_37_0 = xyd.tables.misc.activityAnniversaryDiglettCost

	if var_37_0 > arg_37_0.selfPlayer.crystal then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
			local var_38_0 = {}

			var_38_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_38_0)
		end, nil, nil, xyd.ColorMode.ACTIVITY)

		return
	end

	local var_37_1 = string.format(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_NORMAL_COST_TIP"), var_37_0)

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_37_1, function()
		local var_39_0 = {
			bt_type = var_0_2.Normal
		}

		arg_37_0:thirdAnniDiglettStart(var_39_0, function(arg_40_0, arg_40_1)
			if arg_40_0 == xyd.error.OK then
				xyd.WindowManager.get():closeWindow("third_diglett_hammer")
				xyd.WindowManager.get():openWindow("third_diglett_hammer", arg_40_1)
				xyd.WindowManager.get():closeWindow("third_diglett_result")
			end
		end)
	end, nil, nil, xyd.ColorMode.ACTIVITY)
end

function var_0_0.getDiaryInfo(arg_41_0, arg_41_1)
	xyd.Backend.get():request(xyd.mid.THIRD_ANNI_WORD_DIARY, nil, function(arg_42_0, arg_42_1)
		if arg_42_0 == xyd.error.OK then
			arg_41_0.diaryInfo = arg_42_1

			arg_41_1(arg_42_1)
		end
	end)
end

function var_0_0.getCollectRank(arg_43_0, arg_43_1)
	xyd.Backend.get():request(xyd.mid.THIRD_ANNI_WORD_RANK, nil, function(arg_44_0, arg_44_1)
		if arg_44_0 == xyd.error.OK then
			arg_43_1(arg_44_1)
		end
	end)
end

function var_0_0.formatNewHeros(arg_45_0, arg_45_1)
	local var_45_0 = {
		100,
		100,
		80,
		60,
		0,
		0
	}
	local var_45_1 = {
		0,
		0,
		0,
		0,
		0,
		0
	}
	local var_45_2 = {
		0,
		0,
		0,
		0,
		0,
		0
	}

	for iter_45_0, iter_45_1 in pairs(arg_45_1) do
		if iter_45_1:isHaveAwakenItem() and not iter_45_1:isAwaken() then
			local var_45_3 = {
				100,
				100,
				80,
				60,
				0,
				0
			}
			local var_45_4 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			local var_45_5 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_45_0:renewHeroInfo(iter_45_1, var_45_3, var_45_4, var_45_5)
		elseif iter_45_1:isAwaken() and not iter_45_1:isAwakeTwice() then
			local var_45_6 = {
				100,
				100,
				80,
				60,
				40,
				0
			}
			local var_45_7 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			local var_45_8 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_45_0:renewHeroInfo(iter_45_1, var_45_6, var_45_7, var_45_8)
		elseif iter_45_1:isAwakeTwice() then
			local var_45_9 = {
				100,
				100,
				80,
				60,
				40,
				40
			}
			local var_45_10 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			local var_45_11 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_45_0:renewHeroInfo(iter_45_1, var_45_9, var_45_10, var_45_11)
		else
			local var_45_12 = {
				100,
				100,
				80,
				60,
				0,
				0
			}
			local var_45_13 = {
				0,
				1,
				1,
				1,
				1,
				1
			}
			local var_45_14 = {
				0,
				1,
				1,
				1,
				1,
				1
			}

			arg_45_0:renewHeroInfo(iter_45_1, var_45_12, var_45_13, var_45_14)
		end

		iter_45_1:updatePracticeAwardAttr()
	end
end

function var_0_0.renewHeroInfo(arg_46_0, arg_46_1, arg_46_2, arg_46_3, arg_46_4)
	arg_46_1.color_ = 16
	arg_46_1.level_ = 100
	arg_46_1.skillLev_ = {}
	arg_46_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_46_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_46_1.color_ >= xyd.EquipQuality.GREEN then
		arg_46_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_46_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_46_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_46_1.color_ >= xyd.EquipQuality.BLUE then
		arg_46_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_46_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_46_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_46_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_46_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_46_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_46_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_46_1:isAwaken() then
		arg_46_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_46_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_46_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	if arg_46_1:isAwakeTwice() then
		arg_46_1.skillLev_[xyd.SKILL_INDEX.AwakeTwice] = tonumber(arg_46_2[xyd.SKILL_INDEX.AwakeTwice]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.AwakeTwice]
	else
		arg_46_1.skillLev_[xyd.SKILL_INDEX.AwakeTwice] = false
	end

	arg_46_1.equips_ = {}

	for iter_46_0 = 1, var_0_3 do
		table.insert(arg_46_1.equips_, tonumber(arg_46_4[iter_46_0]))
	end

	arg_46_1.fumo_ = {}

	for iter_46_1 = 1, var_0_3 do
		table.insert(arg_46_1.fumo_, tonumber(arg_46_3[iter_46_1]))
	end

	arg_46_1.fumoLev_ = {}

	for iter_46_2 = 1, var_0_3 do
		local var_46_0 = arg_46_1:getEquipByIndex(iter_46_2)

		table.insert(arg_46_1.fumoLev_, tonumber(var_46_0:getMaxFumoStar()))
	end
end

function var_0_0.formatNewPets(arg_47_0, arg_47_1)
	local var_47_0 = {
		100,
		100,
		80,
		60,
		0
	}

	for iter_47_0, iter_47_1 in pairs(arg_47_1) do
		if iter_47_1:isHaveAwakenItem() and not iter_47_1:isAwaken() then
			local var_47_1 = {
				100,
				100,
				80,
				60,
				0
			}
			local var_47_2 = {
				1,
				1,
				1
			}

			arg_47_0:renewPetInfo(iter_47_1, var_47_1, var_47_2)
		elseif iter_47_1:isAwaken() then
			local var_47_3 = {
				100,
				100,
				80,
				60,
				40
			}
			local var_47_4 = {
				1,
				1,
				1
			}

			arg_47_0:renewPetInfo(iter_47_1, var_47_3, var_47_4)
		else
			local var_47_5 = {
				100,
				100,
				80,
				60,
				0
			}
			local var_47_6 = {
				0,
				1,
				1
			}

			arg_47_0:renewPetInfo(iter_47_1, var_47_5, var_47_6)
		end

		iter_47_1:updatePracticeAwardAttr()
	end
end

function var_0_0.renewPetInfo(arg_48_0, arg_48_1, arg_48_2, arg_48_3)
	local var_48_0 = 16

	arg_48_1.level_, arg_48_1.color_ = 100, var_48_0
	arg_48_1.skillLev_ = {}
	arg_48_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_48_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_48_1.color_ >= xyd.EquipQuality.GREEN then
		arg_48_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_48_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_48_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_48_1.color_ >= xyd.EquipQuality.BLUE then
		arg_48_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_48_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_48_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_48_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_48_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_48_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_48_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_48_1:isAwaken() then
		arg_48_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_48_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_48_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	arg_48_1.equips_ = {}

	for iter_48_0 = 1, var_0_3 do
		table.insert(arg_48_1.equips_, tonumber(arg_48_3[iter_48_0]))
	end
end

return var_0_0
