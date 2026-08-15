local var_0_0 = class("FifthAnniversaryModel", import(".BaseModel"))
local var_0_1 = xyd.tables.misc:getValue("fifth_anni_party_point_per_level")

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.getInfo(arg_3_0, arg_3_1)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_GET_INFO, nil, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.monopolyPos = arg_4_1.mono_info.pos
			arg_3_0.monopolyTimes = arg_4_1.mono_info.move_time
			arg_3_0.monopolyCircles = arg_4_1.mono_info.round
			arg_3_0.gachaInfo = arg_4_1.gacha_info
			arg_3_0.partyInfo = arg_4_1.party_info
			arg_3_0.bossInfo = arg_4_1.boss_info

			if arg_3_0.bossInfo then
				arg_3_0.bossBuyTime = arg_3_0.bossInfo.buy_time
				arg_3_0.bossChallengeTime = arg_3_0.bossInfo.challenge_time
				arg_3_0.bossAwardInfo = arg_3_0.bossInfo.is_award
				arg_3_0.bossPoint = arg_3_0.bossInfo.point
				arg_3_0.isFighting = arg_3_0.bossInfo.is_fighting
			end
		end

		if arg_3_1 then
			arg_3_1(arg_4_0, arg_4_1)
		end
	end)
end

function var_0_0.gachaLockPool(arg_5_0, arg_5_1, arg_5_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_GACHA_LOCK_POOL, arg_5_1, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			for iter_6_0 = 1, 3 do
				arg_5_0.gachaInfo["pool_" .. iter_6_0] = xyd.splitToNumber(arg_5_1["pool_" .. iter_6_0], "|")
			end

			arg_5_0.gachaInfo.is_locked = 1
		end

		if arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.gachaDrawPool(arg_7_0, arg_7_1, arg_7_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_GACHA_DRAW_POOL, arg_7_1, function(arg_8_0, arg_8_1)
		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.gachaRefreshPool(arg_9_0, arg_9_1, arg_9_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_GACHA_REFRESH_POOL, arg_9_1, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			for iter_10_0 = 1, 3 do
				arg_9_0.gachaInfo["pool_" .. iter_10_0] = nil
			end

			arg_9_0.gachaInfo.is_locked = 0
		end

		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.gachaBuyDrawItem(arg_11_0, arg_11_1, arg_11_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_GACHA_BUY_DRAW_ITEM, arg_11_1, function(arg_12_0, arg_12_1)
		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.monopolyMove(arg_13_0, arg_13_1)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_MONOPOLY_MOVE, nil, function(arg_14_0, arg_14_1)
		if arg_13_1 then
			arg_13_1(arg_14_0, arg_14_1)
		end
	end)
end

function var_0_0.startFight(arg_15_0, arg_15_1, arg_15_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_BOSS_START_FIGHT, arg_15_1, function(arg_16_0, arg_16_1)
		if arg_15_2 then
			arg_15_2(arg_16_0, arg_16_1)
		end
	end)
end

function var_0_0.fightResult(arg_17_0, arg_17_1, arg_17_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_BOSS_FIGHT_RESULT, arg_17_1, function(arg_18_0, arg_18_1)
		if arg_17_2 then
			arg_17_2(arg_18_0, arg_18_1)
		end
	end)
end

function var_0_0.buyChallengeTime(arg_19_0, arg_19_1, arg_19_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_BOSS_BUY_CHALLENGE_TIME, arg_19_1, function(arg_20_0, arg_20_1)
		if arg_19_2 then
			arg_19_2(arg_20_0, arg_20_1)
		end
	end)
end

function var_0_0.getAward(arg_21_0, arg_21_1, arg_21_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_BOSS_GET_AWARD, arg_21_1, function(arg_22_0, arg_22_1)
		if arg_21_2 then
			arg_21_2(arg_22_0, arg_22_1)
		end
	end)
end

function var_0_0.getAllAward(arg_23_0, arg_23_1, arg_23_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_BOSS_GET_ALL_AWARD, arg_23_1, function(arg_24_0, arg_24_1)
		if arg_24_0 == xyd.error.OK then
			arg_23_0.bossAwardInfo = arg_24_1.info.is_award
		end

		if arg_23_2 then
			arg_23_2(arg_24_0, arg_24_1)
		end
	end)
end

function var_0_0.getRank(arg_25_0, arg_25_1)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_BOSS_GET_RANK, nil, function(arg_26_0, arg_26_1)
		if arg_25_1 then
			arg_25_1(arg_26_0, arg_26_1)
		end
	end)
end

function var_0_0.getBossInfo(arg_27_0, arg_27_1)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_BOSS_GET_INFO, nil, function(arg_28_0, arg_28_1)
		if arg_27_1 then
			arg_27_0.bossInfo = arg_28_1

			if arg_27_0.bossInfo then
				arg_27_0.bossBuyTime = arg_27_0.bossInfo.buy_time
				arg_27_0.bossChallengeTime = arg_27_0.bossInfo.challenge_time
				arg_27_0.bossAwardInfo = arg_27_0.bossInfo.is_award
				arg_27_0.bossPoint = arg_27_0.bossInfo.point
				arg_27_0.isFighting = arg_27_0.bossInfo.is_fighting
			end

			arg_27_1(arg_28_0, arg_28_1)
		end
	end)
end

function var_0_0.isGachaLock(arg_29_0)
	return arg_29_0.gachaInfo.is_locked == 1
end

function var_0_0.getPoolItems(arg_30_0, arg_30_1)
	return arg_30_0.gachaInfo["pool_" .. arg_30_1] or {}
end

function var_0_0.partySendGift(arg_31_0, arg_31_1, arg_31_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_PARTY_SEND_GIFT, arg_31_1, function(arg_32_0, arg_32_1)
		if arg_32_0 == xyd.error.OK then
			arg_31_0.partyInfo.send_point = arg_31_0.partyInfo.send_point + arg_31_1.show_point

			local var_32_0 = xyd.WindowManager.get():getWindow("fifth_anni_party_main")

			if var_32_0 and not tolua.isnull(var_32_0) then
				var_32_0:updateNum(true)
			end
		end

		if arg_31_2 then
			arg_31_2(arg_32_0, arg_32_1)
		end
	end)
end

function var_0_0.partyGetAward(arg_33_0, arg_33_1, arg_33_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_PARTY_GET_AWARD, arg_33_1, function(arg_34_0, arg_34_1)
		if arg_34_0 == xyd.error.OK then
			arg_33_0.partyInfo.is_award[arg_33_1.award_id] = 1
		end

		if arg_33_2 then
			arg_33_2(arg_34_0, arg_34_1)
		end
	end)
end

function var_0_0.partyGetAllAwards(arg_35_0, arg_35_1, arg_35_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_PARTY_GET_ALL_AWARDS, arg_35_1, function(arg_36_0, arg_36_1)
		if arg_36_0 == xyd.error.OK then
			local var_36_0 = xyd.tables.fifthAnniPartyAward

			for iter_36_0 = 1, var_36_0:all() do
				if arg_35_0:getReceivePoint() >= var_36_0:receivePoint(iter_36_0) and arg_35_0:getSendPoint() >= var_36_0:sendPoint(iter_36_0) then
					arg_35_0.partyInfo.is_award[iter_36_0] = 1
				end
			end
		end

		if arg_35_2 then
			arg_35_2(arg_36_0, arg_36_1)
		end
	end)
end

function var_0_0.partyGetLogs(arg_37_0, arg_37_1, arg_37_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_PARTY_GET_LOGS, arg_37_1, function(arg_38_0, arg_38_1)
		if arg_37_2 then
			arg_37_2(arg_38_0, arg_38_1)
		end
	end)
end

function var_0_0.partyGetSendRankList(arg_39_0, arg_39_1, arg_39_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_PARTY_GET_SEND_RANK_LIST, arg_39_1, function(arg_40_0, arg_40_1)
		if arg_39_2 then
			arg_39_2(arg_40_0, arg_40_1)
		end
	end)
end

function var_0_0.partyGetPlayerInfo(arg_41_0, arg_41_1, arg_41_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_PARTY_GET_PLAYER_INFO, arg_41_1, function(arg_42_0, arg_42_1)
		if arg_41_2 then
			arg_41_2(arg_42_0, arg_42_1)
		end
	end)
end

function var_0_0.partyGetCollectionInfo(arg_43_0, arg_43_1, arg_43_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_PARTY_GET_COLLECTION_INFO, arg_43_1, function(arg_44_0, arg_44_1)
		if arg_43_2 then
			arg_43_2(arg_44_0, arg_44_1)
		end
	end)
end

function var_0_0.partyGetCollectionAward(arg_45_0, arg_45_1, arg_45_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_PARTY_GET_COLLECTION_AWARD, arg_45_1, function(arg_46_0, arg_46_1)
		if arg_45_2 then
			arg_45_2(arg_46_0, arg_46_1)
		end
	end)
end

function var_0_0.partyGetRandomPlayers(arg_47_0, arg_47_1, arg_47_2)
	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_PARTY_GET_RANDOM_PLAYERS, arg_47_1, function(arg_48_0, arg_48_1)
		if arg_47_2 then
			arg_47_2(arg_48_0, arg_48_1)
		end
	end)
end

function var_0_0.getCelebrationLev(arg_49_0)
	return 1 + math.floor(arg_49_0.partyInfo.receive_point / var_0_1)
end

function var_0_0.getCelebrationExp(arg_50_0)
	return arg_50_0.partyInfo.receive_point % var_0_1
end

function var_0_0.getReceivePoint(arg_51_0)
	return arg_51_0.partyInfo.receive_point
end

function var_0_0.getSendPoint(arg_52_0)
	return arg_52_0.partyInfo.send_point
end

function var_0_0.getPartyIsAward(arg_53_0, arg_53_1)
	return arg_53_0.partyInfo.is_award[arg_53_1]
end

return var_0_0
