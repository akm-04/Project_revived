local var_0_0 = class("FourthAnniversaryMapRestartWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = "fourth_annni_map_restart"

function var_0_0.close(arg_1_0, arg_1_1)
	xyd.WindowManager.get():closeWindow(var_0_3, arg_1_1)
end

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2)
	var_0_0.super.ctor(arg_2_0, arg_2_1, arg_2_2)

	arg_2_0.callback_ = arg_2_2.callback
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.backpack = arg_2_0.selfPlayer:getBackpack()
	arg_2_0.restartItem = xyd.tables.misc:getValue("activity_anni4_campaign_reset_item")
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
	arg_3_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 0))
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	local function var_4_0(arg_5_0)
		if arg_4_0.callback_ ~= nil then
			arg_4_0.callback_(arg_5_0)
		end

		arg_4_0.callback_ = nil
	end

	local var_4_1 = arg_4_0:confirmButton_()

	var_4_1:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			var_4_1:setScale(0.9)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			var_4_1:setScale(1)

			if arg_4_0.backpack:getItemNumByID(arg_4_0.restartItem) <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("FOURTH_ANNI_MAP_REST_NOT_ENOUGH")
				})

				return
			end

			xyd.playButtonSound()
			var_0_0:close(function()
				var_4_0(true)
			end)
		end
	end)

	local var_4_2 = arg_4_0:rejectButton_()

	var_4_2:addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			var_4_2:setScale(0.9)
		elseif arg_8_1 == ccui.TouchEventType.ended then
			var_4_2:setScale(1)
			xyd.playButtonSound()
			var_0_0:close(function()
				var_4_0(false)
			end)
		end
	end)
end

function var_0_0.layout(arg_10_0)
	local var_10_0 = arg_10_0:nodeByName("splitline"):getContentSize().width
	local var_10_1 = var_0_2.new({
		size = var_10_0
	})

	var_10_1:addTo(arg_10_0:nodeByName("container"))
	var_10_1:setAnchorPoint(0.5, 0.5)
	var_10_1:setPosition(arg_10_0:nodeByName("splitline"):getPosition())
	arg_10_0:nodeByName("txt_name"):setString(var_0_1:translation("TIP"))
	arg_10_0:nodeByName("txt_tips"):setString(var_0_1:translation("FOURTH_ANNI_MAP_RESTART_TIPS"))

	local var_10_2 = arg_10_0.backpack:getItemNumByID(arg_10_0.restartItem)

	arg_10_0:nodeByName("txt_num"):setString(string.format(var_0_1:translation("FOURTH_ANNI_MAP_REST_NUM"), var_10_2))
	xyd.setItemBorder(arg_10_0:nodeByName("icon"), arg_10_0.restartItem)
	arg_10_0:nodeByName("txt_sure"):setString(var_0_1:translation("OK"))
	arg_10_0:nodeByName("txt_cancel"):setString(var_0_1:translation("CANCEL"))
end

function var_0_0.didClose(arg_11_0)
	var_0_0.super.didClose()
end

function var_0_0.confirmButton_(arg_12_0)
	return arg_12_0:nodeByName("btn_sure")
end

function var_0_0.rejectButton_(arg_13_0)
	return arg_13_0:nodeByName("btn_cancel")
end

return var_0_0
