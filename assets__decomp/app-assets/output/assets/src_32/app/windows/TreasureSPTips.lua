local var_0_0 = class("TreasureSPTips", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = 265
local var_0_4 = 170

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.handle_ = {}
	arg_1_0.handle2_ = {}
	arg_1_0.isRecover = false
	arg_1_0.isHasTime = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0 = xyd.tables.sound:getSound("ui_tips")

	audio.playSound(var_2_0, false)
	arg_2_0:layout()
end

function var_0_0.getServerTime(arg_3_0)
	local var_3_0 = os.date("%X", xyd.ServerTime.get():getServerTime())

	arg_3_0:nodeByName("txt_cur_time"):setString(var_0_2:translation("CUR_TIME") .. ":")
	arg_3_0:nodeByName("cur_time"):setString(var_3_0)
end

function var_0_0.getRecoverTime(arg_4_0)
	local var_4_0, var_4_1 = arg_4_0.selfPlayer:getNextTreasureSPCoolTime()
	local var_4_2 = xyd.tables.misc.treasureSPInterval / 60

	arg_4_0:nodeByName("txt_next_recover"):setString(var_0_2:translation("TREASURE_NEXT_SP_RECOVERY"))
	arg_4_0:nodeByName("txt_recover_all"):setString(var_0_2:translation("TREASURE_RECOVERY_ALL_SP"))
	arg_4_0:nodeByName("txt_recover_interval"):setString(var_0_2:translation("TREASURE_RECOVERY_SP_INTERVAL"))
	arg_4_0:nodeByName("next_recover_time"):setString(var_4_0)
	arg_4_0:nodeByName("recover_all_time"):setString(var_4_1)
	arg_4_0:nodeByName("recover_interval_time"):setString(string.format(var_0_2:translation("TREASURE_MINUTE"), var_4_2))
end

function var_0_0.layout(arg_5_0)
	arg_5_0:getServerTime()

	if not arg_5_0.isHasTime then
		arg_5_0.handle2_ = var_0_1.scheduleGlobal(function()
			arg_5_0:getServerTime()
		end, 1)
		arg_5_0.isHasTime = true
	end

	if arg_5_0.selfPlayer.treasureSP >= xyd.tables.misc.treasureSPLimit then
		if arg_5_0.isRecover then
			var_0_1.unscheduleGlobal(arg_5_0.handle_)

			arg_5_0.isRecover = false
		end

		local var_5_0 = var_0_2:translation("TREASURE_ALREADY_RECOVER")

		arg_5_0:nodeByName("txt_next_recover"):setString(var_5_0)
		arg_5_0:nodeByName("bg_img"):height(var_0_4)
		arg_5_0:nodeByName("txt_recover_all"):setVisible(false)
		arg_5_0:nodeByName("txt_recover_interval"):setVisible(false)
		arg_5_0:nodeByName("next_recover_time"):setVisible(false)
		arg_5_0:nodeByName("recover_all_time"):setVisible(false)
		arg_5_0:nodeByName("recover_interval_time"):setVisible(false)
	else
		arg_5_0:getRecoverTime()

		if not arg_5_0.isRecover then
			arg_5_0.handle_ = var_0_1.scheduleGlobal(function()
				arg_5_0:getRecoverTime()
			end, 1)
			arg_5_0.isRecover = true
		end

		arg_5_0:nodeByName("bg_img"):height(var_0_3)
		arg_5_0:nodeByName("txt_recover_all"):setVisible(true)
		arg_5_0:nodeByName("txt_recover_interval"):setVisible(true)
		arg_5_0:nodeByName("next_recover_time"):setVisible(true)
		arg_5_0:nodeByName("recover_all_time"):setVisible(true)
		arg_5_0:nodeByName("recover_interval_time"):setVisible(true)
	end
end

function var_0_0.willClose(arg_8_0, arg_8_1)
	var_0_0.super:willClose(arg_8_1)

	if arg_8_0.isRecover then
		var_0_1.unscheduleGlobal(arg_8_0.handle_)
	end

	if arg_8_0.isHasTime then
		var_0_1.unscheduleGlobal(arg_8_0.handle2_)
	end
end

return var_0_0
