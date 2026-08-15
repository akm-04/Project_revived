local var_0_0 = class("RedEnvelope", import(".BaseModel"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfState = {}
	arg_1_0.redEnvelopeList = {}
	arg_1_0.lastPacketList = {}
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.LOAD_RED_ENVELOPE_INFO, handler(arg_2_0, arg_2_0.onLoadRedEnvelopeInfo_))
	arg_2_0:registerEvent(xyd.event.BROCAST_SEND_RED_ENVELOPE, handler(arg_2_0, arg_2_0.onBrocastSendEnvelope_))
	arg_2_0:registerEvent(xyd.event.BROCAST_FINISH_RED_ENVELOPE, handler(arg_2_0, arg_2_0.onBrocastFinishEnvelope_))
	arg_2_0:registerEvent(xyd.event.RECHARGE, handler(arg_2_0, arg_2_0.onRecharge_))
end

function var_0_0.loadEnvelopeInfo(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_RED_ENVELOPE_INFO, var_3_0, function(arg_4_0, arg_4_1)
		if arg_3_2 then
			arg_3_2(arg_4_0)
		end
	end)
end

function var_0_0.loadGrabRecord(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0

	var_5_0 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_RED_ENVELOPE_LOG, {}, function(arg_6_0, arg_6_1)
		if arg_5_2 then
			arg_5_2(arg_6_0)
		end
	end)
end

function var_0_0.sendEnvelope(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.SEND_RED_ENVELOPE, var_7_0, function(arg_8_0, arg_8_1)
		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.grabEnvelope(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.GRAB_RED_ENVELOPE, var_9_0, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK and arg_9_2 then
			arg_9_2(arg_10_1)
		end
	end)
end

function var_0_0.loadEnvelopRecord(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_RED_ENVELOPE_LOG, var_11_0, function(arg_12_0, arg_12_1)
		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.getRankInfo(arg_13_0, arg_13_1)
	xyd.Backend.get():request(xyd.mid.RED_PACKETS_RANK, {}, function(arg_14_0, arg_14_1)
		if arg_14_0 == xyd.error.OK then
			arg_13_1(arg_14_1)
		end
	end)
end

function var_0_0.onLoadRedEnvelopeInfo_(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_1.params

	arg_15_0.selfState = {}
	arg_15_0.redEnvelopeList = {}
	arg_15_0.lastPacketList = {}
	arg_15_0.selfState = var_15_0.self_info
	arg_15_0.redEnvelopeList = var_15_0.red_packets
	arg_15_0.lastPacketList = var_15_0.last_packets
	arg_15_0.grabTimes = var_15_0.grab_times
end

function var_0_0.onBrocastSendEnvelope_(arg_16_0, arg_16_1)
	local var_16_0 = xyd.WindowManager.get():getWindow("red_envelope")

	if var_16_0 then
		var_16_0:updateEnvelopeList(arg_16_1)
	end

	local var_16_1 = xyd.WindowManager.get():getWindow("main_scene_top")

	if var_16_1 and not var_16_0 then
		local var_16_2 = {
			msg = arg_16_1.params.msg.player_name .. var_0_2:translation("ENVELOPE_BROCAST")
		}

		var_16_2.time = 7

		var_16_1:showBroadcast(var_16_2)
		var_16_1:showEnvelopeRedMark(true)
	end
end

function var_0_0.onBrocastFinishEnvelope_(arg_17_0, arg_17_1)
	local var_17_0 = xyd.WindowManager.get():getWindow("red_envelope")

	if var_17_0 then
		var_17_0:envelopeFinishRefresh(arg_17_1)
		var_17_0:updateEnvelopeList(arg_17_1)
	end
end

function var_0_0.onRecharge_(arg_18_0, arg_18_1)
	arg_18_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)

	if arg_18_0.activities:isActivityOpen(xyd.RedEnvelope.ENVELOPE_ID) then
		arg_18_0:loadEnvelopeInfo(nil, function()
			local var_19_0 = xyd.WindowManager.get():getWindow("red_envelope")

			if var_19_0 then
				var_19_0:updateRightList(arg_18_1)
			end
		end)
	end
end

function var_0_0.getSelfState(arg_20_0)
	return arg_20_0.selfState or {}
end

function var_0_0.getRedEnvelopeList(arg_21_0)
	return arg_21_0.redEnvelopeList or {}
end

function var_0_0.getLastPacketList(arg_22_0)
	return arg_22_0.lastPacketList or {}
end

function var_0_0.getGrabTimes(arg_23_0)
	return arg_23_0.grabTimes or 0
end

return var_0_0
