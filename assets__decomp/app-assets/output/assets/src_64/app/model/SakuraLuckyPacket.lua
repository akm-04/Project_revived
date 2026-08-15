local var_0_0 = class("SakuraLuckyPacket", import(".BaseModel"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfState = {}
	arg_1_0.sakuraLuckyPacketList = {}
	arg_1_0.lastPacketList = {}
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.LOAD_GIFT_PACKETS_INFO, handler(arg_2_0, arg_2_0.onLoadSakuraLuckyPacketInfo_))
	arg_2_0:registerEvent(xyd.event.BROCAST_SEND_GIFT_PACKETS, handler(arg_2_0, arg_2_0.onBrocastSendPacket_))
	arg_2_0:registerEvent(xyd.event.BROCAST_FINISH_GIFT_PACKETS, handler(arg_2_0, arg_2_0.onBrocastFinishPacket_))
	arg_2_0:registerEvent(xyd.event.RECHARGE, handler(arg_2_0, arg_2_0.onRecharge_))
end

function var_0_0.loadPacketInfo(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_GIFT_PACKETS_INFO, var_3_0, function(arg_4_0, arg_4_1)
		if arg_3_2 then
			arg_3_2(arg_4_0)
		end
	end)
end

function var_0_0.loadGrabRecord(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0

	var_5_0 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_GIFT_PACKETS_LOG, {}, function(arg_6_0, arg_6_1)
		if arg_5_2 then
			arg_5_2(arg_6_0)
		end
	end)
end

function var_0_0.sendPacket(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.SEND_GIFT_PACKETS, var_7_0, function(arg_8_0, arg_8_1)
		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.grabPacket(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.GRAB_GIFT_PACKETS, var_9_0, function(arg_10_0, arg_10_1)
		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.loadPacketRecord(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_GIFT_PACKETS_LOG, var_11_0, function(arg_12_0, arg_12_1)
		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.onLoadSakuraLuckyPacketInfo_(arg_13_0, arg_13_1)
	local var_13_0 = arg_13_1.params

	arg_13_0.selfState = {}
	arg_13_0.sakuraLuckyPacketList = {}
	arg_13_0.lastPacketList = {}
	arg_13_0.selfState = var_13_0.self_info
	arg_13_0.sakuraLuckyPacketList = var_13_0.red_packets
	arg_13_0.lastPacketList = var_13_0.last_packets
end

function var_0_0.onBrocastSendPacket_(arg_14_0, arg_14_1)
	local var_14_0 = xyd.WindowManager.get():getWindow("lucky_packet")

	if var_14_0 then
		var_14_0:updatePacketList(arg_14_1)
	end

	local var_14_1 = xyd.WindowManager.get():getWindow("main_scene_top")

	if var_14_1 and not var_14_0 then
		local var_14_2 = {
			msg = arg_14_1.params.msg.player_name .. var_0_2:translation("PACKET_BROCAST")
		}

		var_14_2.time = 7

		var_14_1:showBroadcast(var_14_2)
		var_14_1:showPacketRedMark(true)
	end
end

function var_0_0.onBrocastFinishPacket_(arg_15_0, arg_15_1)
	local var_15_0 = xyd.WindowManager.get():getWindow("lucky_packet")

	if var_15_0 then
		var_15_0:packetFinishRefresh(arg_15_1)
		var_15_0:updatePacketList(arg_15_1)
	end
end

function var_0_0.onRecharge_(arg_16_0, arg_16_1)
	arg_16_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)

	if arg_16_0.activities:isScratchCardShow() then
		arg_16_0:loadPacketInfo(nil, function()
			local var_17_0 = xyd.WindowManager.get():getWindow("lucky_packet")

			if var_17_0 then
				var_17_0:updateRightList(arg_16_1)
			end
		end)
	end
end

function var_0_0.getSelfState(arg_18_0)
	return arg_18_0.selfState or {}
end

function var_0_0.getSakuraLuckyPacketList(arg_19_0)
	return arg_19_0.sakuraLuckyPacketList or {}
end

function var_0_0.getLastPacketList(arg_20_0)
	return arg_20_0.lastPacketList or {}
end

return var_0_0
