local var_0_0 = class("EnergyTips", import("app.common.ui.BaseWindow"))

var_0_0.BG_IMG = "bg_img"
var_0_0.DATE_TIME = "data_time_txt"
var_0_0.BUYENERGY_TIMES = "buyenergy_times_txt"
var_0_0.RECOVER_DETAIL = "recover_detail_txt"

local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.tipHeight = {}
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
	local var_3_1 = string.format(var_0_2:translation("TIME_NOW"), var_3_0)

	arg_3_0:nodeByName(var_0_0.DATE_TIME):setString(var_3_1)
end

function var_0_0.getRecoverTime(arg_4_0)
	local var_4_0, var_4_1 = arg_4_0.selfPlayer:getNextSpiritEnergyCoolTime()
	local var_4_2 = math.floor(xyd.tables.misc:getValue("spirit_energy_minute")) / 60
	local var_4_3 = string.format(var_0_2:translation("NEXT_ENERGY_RECOVERY"), var_4_0)
	local var_4_4 = string.format(var_0_2:translation("RECOVER_ALL_ENERGY"), var_4_1)
	local var_4_5 = string.format(var_0_2:translation("RECOVER_ENERGY_INTERVAL"), var_4_2)
	local var_4_6 = var_4_3 .. "\n" .. var_4_4 .. "\n" .. var_4_5

	arg_4_0:nodeByName(var_0_0.RECOVER_DETAIL):setString(var_4_6)
end

function var_0_0.layout(arg_5_0)
	arg_5_0:getServerTime()

	if not arg_5_0.isHasTime then
		arg_5_0.handle2_ = var_0_1.scheduleGlobal(function()
			arg_5_0:getServerTime()
		end, 1)
		arg_5_0.isHasTime = true
	end

	arg_5_0:nodeByName(var_0_0.BUYENERGY_TIMES):setString("")

	if arg_5_0.selfPlayer.spiritEnergy >= xyd.tables.misc:getValue("spirit_energy_up_limit") then
		if arg_5_0.isRecover then
			var_0_1.unscheduleGlobal(arg_5_0.handle_)

			arg_5_0.isRecover = false
		end

		local var_5_0 = var_0_2:translation("ALREADY_RECOVER")

		arg_5_0:nodeByName(var_0_0.RECOVER_DETAIL):setString(var_5_0)
	else
		arg_5_0:getRecoverTime()

		if not arg_5_0.isRecover then
			arg_5_0.handle_ = var_0_1.scheduleGlobal(function()
				arg_5_0:getRecoverTime()
			end, 1)
			arg_5_0.isRecover = true
		end
	end

	arg_5_0.tipHeight = arg_5_0:nodeByName(var_0_0.RECOVER_DETAIL):getContentSize().height + 95

	arg_5_0:nodeByName(var_0_0.BG_IMG):height(arg_5_0.tipHeight)
	arg_5_0:nodeByName(var_0_0.BG_IMG):width(340)
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
