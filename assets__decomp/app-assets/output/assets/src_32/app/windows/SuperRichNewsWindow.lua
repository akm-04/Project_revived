local var_0_0 = class("SuperRichNewsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityRichEvent
local var_0_3 = "windows/zillionaire/news/"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.superRich = xyd.ModelManager.get():loadModel(xyd.ModelType.SUPER_RICH)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.eventType = arg_1_2.event_type
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer(nil, true)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("desc_txt"):setString(var_0_2:event(arg_4_0.eventType))

	local var_4_0 = xyd.AssetLoader.get():loadSprite(var_0_3 .. arg_4_0.eventType .. ".png")

	arg_4_0:nodeByName("card"):setSpriteFrame(var_4_0:getSpriteFrame())
	arg_4_0:closeButton():addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_5_0, false)

			local var_5_1 = arg_4_0.backpack:getItemNumByID(xyd.tables.misc.activityRichPasserByCardItem)
			local var_5_2 = xyd.tables.activityRichEvent:canUseCard(arg_4_0.eventType)

			if var_5_1 > 0 and var_5_2 > 0 then
				local var_5_3 = var_0_1:translation("SUPER_RICH_USE_CARD_TIP")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_3, function()
					local var_6_0 = {}

					arg_4_0:handleSkip(1)
				end, {
					lcallback = function()
						arg_4_0:handleSkip(0)
					end
				}, nil, arg_4_0.colorMode)
			else
				arg_4_0:handleSkip(0)
			end
		end
	end)
end

function var_0_0.handleSkip(arg_8_0, arg_8_1)
	local var_8_0 = {
		skip = arg_8_1
	}

	arg_8_0.superRich:monopolySkip(var_8_0, function(arg_9_0, arg_9_1)
		if arg_9_0 == xyd.error.OK then
			if arg_8_0.callback then
				arg_8_0.callback(var_8_0.skip, arg_9_1)
			end

			xyd.WindowManager.get():closeWindow(arg_8_0)
		else
			xyd.WindowManager.get():closeWindow(arg_8_0)
		end
	end)
end

function var_0_0.didClose(arg_10_0, arg_10_1)
	var_0_0.super.didClose(arg_10_0, arg_10_1)
	arg_10_0.callback()
end

return var_0_0
