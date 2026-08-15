local var_0_0 = class("ZhugeDamageWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_1_0.data = arg_1_2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = xyd.tables.misc.zhugeTeleportMaxDamage
	local var_3_1 = arg_3_0.zhugeModel:getLocalBossInfo()
	local var_3_2 = arg_3_0.data.damage

	if var_3_0 < var_3_2 then
		var_3_2 = var_3_0
	end

	local var_3_3 = var_3_1.cur_damage
	local var_3_4 = var_3_1.free_times
	local var_3_5 = var_3_1.is_passed
	local var_3_6 = var_3_1.total_hp
	local var_3_7 = math.floor(var_3_3 / var_3_6 * 100)

	if var_3_7 > 100 then
		var_3_7 = 100
	end

	local var_3_8 = math.floor(var_3_2 / var_3_6 * 100)

	if var_3_8 > 100 then
		var_3_8 = 100
	end

	local var_3_9 = math.floor((var_3_3 - var_3_2) / var_3_6 * 100)

	arg_3_0:nodeByName("damage_num"):setString(var_3_2)
	arg_3_0:nodeByName("total_damage_num"):setString(var_3_3)
	arg_3_0:nodeByName("progress_num"):setString(var_3_7 .. "%")
	arg_3_0:nodeByName("add_progress_num"):setString("(+" .. var_3_8 .. "%)")
	arg_3_0:nodeByName("bar_blue"):setPercent(var_3_9)
	arg_3_0:nodeByName("bar"):setPercent(var_3_7)
	arg_3_0:nodeByName("text_damage"):setString(var_0_1:translation("ZHUGE_HOUSE_TIPS_13"))
	arg_3_0:nodeByName("text_total_damage"):setString(var_0_1:translation("ZHUGE_HOUSE_TIPS_14"))
	arg_3_0:nodeByName("text_progress"):setString(var_0_1:translation("ZHUGE_HOUSE_TIPS_15"))
	arg_3_0:nodeByName("close"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_4_0, false)
			arg_3_0:dispatchEvent({
				name = xyd.event.BATTLE_END_BACK_TO_MAIN
			})
		end
	end)
end

return var_0_0
