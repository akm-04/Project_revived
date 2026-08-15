local var_0_0 = class("Kite", import(".BaseModel"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.kite
local var_0_4 = 2001
local var_0_5 = {
	INITIAL = 0,
	CAN_SEND_AGIN = 2,
	GO_TO_CHARGE = 3,
	FIRST_CAN_SEND = 1
}
local var_0_6 = {
	50001091,
	50001092,
	50001093
}

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfState = {
		0,
		0,
		0
	}
	arg_1_0.kiteList = {}
	arg_1_0.haveSend = {}
	arg_1_0.lastKiteList = {}
	arg_1_0.canSendNum = {}
	arg_1_0.total_send = 0
	arg_1_0.daily_grab_times = 0
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.LOAD_KITES_INFO, handler(arg_2_0, arg_2_0.onLoadKiteInfo_))
	arg_2_0:registerEvent(xyd.event.BROCAST_SEND_KITES, handler(arg_2_0, arg_2_0.onBrocastSendKite_))
	arg_2_0:registerEvent(xyd.event.BROCAST_FINISH_KITES, handler(arg_2_0, arg_2_0.onBrocastFinishKite_))
	arg_2_0:registerEvent(xyd.event.RECHARGE, handler(arg_2_0, arg_2_0.onRecharge_))
end

function var_0_0.loadKiteInfo(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_KITES_INFO, var_3_0, function(arg_4_0, arg_4_1)
		if arg_3_2 then
			arg_3_2(arg_4_0)
		end
	end)
end

function var_0_0.loadGrabRecord(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_KITES_LOG, var_5_0, function(arg_6_0, arg_6_1)
		if arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.sendKite(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.SEND_KITES, var_7_0, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			arg_7_0.haveSend[var_7_0.id] = arg_7_0.haveSend[var_7_0.id] + var_7_0.num
			arg_7_0.canSendNum[var_7_0.id] = arg_7_0.canSendNum[var_7_0.id] - var_7_0.num

			arg_7_0:initSelfState()
			arg_7_0.selfPlayer:getBackpack():setItemNumByID(var_0_6[var_7_0.id], arg_7_0.canSendNum[var_7_0.id])
		end

		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.grabKite(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.GRAB_KITES, var_9_0, function(arg_10_0, arg_10_1)
		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.anserQuestion(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1 or {}

	xyd.Backend.get():request(xyd.mid.ANS_KITE_QUESTION, var_11_0, function(arg_12_0, arg_12_1)
		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.loadKiteRecord(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_SEND_KITES_LOG, var_13_0, function(arg_14_0, arg_14_1)
		if arg_13_2 then
			arg_13_2(arg_14_0, arg_14_1)
		end
	end)
end

function var_0_0.getElectionList(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0

	var_15_0 = arg_15_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_KITE_KING_INFO, {}, function(arg_16_0, arg_16_1)
		if arg_15_2 then
			arg_15_2(arg_16_0, arg_16_1)
		end
	end)
end

function var_0_0.signUpKiteKing(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_1 or {}

	xyd.Backend.get():request(xyd.mid.SIGN_UP_KITE_KING, var_17_0, function(arg_18_0, arg_18_1)
		if arg_17_2 then
			arg_17_2(arg_18_0, arg_18_1)
		end
	end)
end

function var_0_0.kiteKingVote(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = arg_19_1 or {}

	xyd.Backend.get():request(xyd.mid.kITE_KING_VOTE, var_19_0, function(arg_20_0, arg_20_1)
		if arg_19_2 then
			arg_19_2(arg_20_0, arg_20_1)
		end
	end)
end

function var_0_0.onLoadKiteInfo_(arg_21_0, arg_21_1)
	local var_21_0 = arg_21_1.params

	arg_21_0.canSendNum = {}
	arg_21_0.kiteList = {}
	arg_21_0.haveSend = {}
	arg_21_0.lastKiteList = {}
	arg_21_0.canSendNum = var_21_0.self_info.self_info
	arg_21_0.kiteList = var_21_0.red_packets
	arg_21_0.haveSend = var_21_0.self_info.have_send
	arg_21_0.lastKiteList = var_21_0.last_packets
	arg_21_0.grab_packet_id = var_21_0.self_info.grab_packet_id
	arg_21_0.daily_grab_times = var_21_0.self_info.daily_grab_times

	arg_21_0:initSelfState()
end

function var_0_0.initSelfState(arg_22_0)
	arg_22_0.selfState = {}
	arg_22_0.total_send = 0

	for iter_22_0 = 1, #arg_22_0.canSendNum do
		if arg_22_0.canSendNum[iter_22_0] == 0 and arg_22_0.haveSend[iter_22_0] == 0 then
			arg_22_0.selfState[iter_22_0] = var_0_5.INITIAL
		elseif arg_22_0.canSendNum[iter_22_0] > 0 and arg_22_0.haveSend[iter_22_0] == 0 then
			arg_22_0.selfState[iter_22_0] = var_0_5.FIRST_CAN_SEND
		elseif arg_22_0.canSendNum[iter_22_0] > 0 and arg_22_0.haveSend[iter_22_0] > 0 then
			arg_22_0.selfState[iter_22_0] = var_0_5.CAN_SEND_AGIN
		else
			arg_22_0.selfState[iter_22_0] = var_0_5.GO_TO_CHARGE
		end

		arg_22_0.total_send = arg_22_0.total_send + arg_22_0.haveSend[iter_22_0]
	end
end

function var_0_0.onBrocastSendKite_(arg_23_0, arg_23_1)
	local var_23_0 = arg_23_1.params.msg
	local var_23_1 = xyd.WindowManager.get():getWindow("kite")

	if var_23_1 then
		var_23_1:updateKiteList(arg_23_1)
	end

	local var_23_2 = xyd.WindowManager.get():getWindow("main_scene_top")

	if var_23_2 and not var_23_1 then
		local var_23_3 = {
			msg = string.format(xyd.tables.announce:content(var_0_4), var_23_0.player_name, var_0_3:name(var_23_0.id))
		}

		var_23_3.time = 7

		var_23_2:showBroadcast(var_23_3)
		var_23_2:showKiteRedMark(true)
	end
end

function var_0_0.onBrocastFinishKite_(arg_24_0, arg_24_1)
	local var_24_0 = xyd.WindowManager.get():getWindow("kite")

	if var_24_0 then
		var_24_0:packetFinishRefresh(arg_24_1)
		var_24_0:updateKiteList(arg_24_1)
	end
end

function var_0_0.onRecharge_(arg_25_0, arg_25_1)
	if arg_25_0.activities:isActivityOpen(xyd.RedEnvelope.KITE_ID) then
		local var_25_0 = arg_25_1.params.params.delta
		local var_25_1 = arg_25_0.selfPlayer:getBackpack()

		for iter_25_0 = 1, #var_0_6 do
			if var_25_0 >= var_0_3:amount(iter_25_0) then
				var_25_1:addItemsByID(var_0_6[iter_25_0], var_0_3:activityAmount(iter_25_0))
			end
		end

		arg_25_0:loadKiteInfo(nil, function()
			local var_26_0 = xyd.WindowManager.get():getWindow("kite")

			if var_26_0 then
				var_26_0:updateRightList(arg_25_1)
			end
		end)
	end
end

function var_0_0.isHaveKitesToSend(arg_27_0)
	for iter_27_0 = 1, #arg_27_0.canSendNum do
		if arg_27_0.canSendNum[iter_27_0] ~= 0 then
			return true
		end
	end

	return false
end

function var_0_0.getSelfState(arg_28_0)
	return arg_28_0.selfState or {}
end

function var_0_0.getCanSendNum(arg_29_0)
	return arg_29_0.canSendNum or {}
end

function var_0_0.getKiteList(arg_30_0)
	return arg_30_0.kiteList or {}
end

function var_0_0.getLastKiteList(arg_31_0)
	return arg_31_0.lastKiteList or {}
end

return var_0_0
