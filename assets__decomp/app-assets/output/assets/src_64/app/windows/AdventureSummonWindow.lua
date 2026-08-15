local var_0_0 = class("AdventureSummonWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.hero
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.adventureEvent
local var_0_6 = xyd.tables.adventureSummon

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.eventId = arg_1_2.event_info.table_id
	arg_1_0.eventInfo = arg_1_2.event_info
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.adventureEvent = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
	arg_1_0.itemId = var_0_6:itemId(tostring(arg_1_0.eventInfo.special_data))
end

function var_0_0.setupBackground(arg_2_0)
	if arg_2_0.bg then
		arg_2_0:removeChild(arg_2_0.bg, true)
	end

	arg_2_0.bg = xyd.AssetLoader.get():loadSprite(var_0_5:contentBg(tostring(arg_2_0.eventId)))

	arg_2_0.bg:setAnchorPoint(0, 0)
	arg_2_0.bg:setPosition(0, 0)
	arg_2_0.bg:setScale(cc.Director:getInstance():getOpenGLView():getFrameSize().width / arg_2_0.bg:getContentSize().width)
	arg_2_0.bg:addTo(arg_2_0, -100)
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)

	arg_3_0.cardContainer = arg_3_0:nodeByName("card_container")

	arg_3_0:startTimeCount(arg_3_0.eventId)
	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:nodeByName("btn_check"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			arg_4_0:nodeByName("btn_check"):setScale(0.9)
		elseif arg_5_1 == ccui.TouchEventType.moved then
			arg_4_0:nodeByName("btn_check"):setScale(1)
		elseif arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_4_0:nodeByName("btn_check"):setScale(1)

			local var_5_0 = var_0_2.new()

			var_5_0:initUnCollected(arg_4_0.itemId)

			var_5_0.isHideBorrow = true

			xyd.WindowManager.get():openWindow(xyd.WindowName.heroattributeWnd, var_5_0)
		end
	end)
	arg_4_0:nodeByName("btn_buy"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			arg_4_0:nodeByName("btn_buy"):setScale(0.9)
		elseif arg_6_1 == ccui.TouchEventType.moved then
			arg_4_0:nodeByName("btn_buy"):setScale(1)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_4_0:nodeByName("btn_buy"):setScale(1)

			if arg_4_0.selfPlayer.crystal < var_0_6:price(tostring(arg_4_0.eventInfo.special_data)) then
				local var_6_0 = var_0_4:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_0, function()
					local var_7_0 = {}

					var_7_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_7_0)
				end, nil, nil, arg_4_0.colorMode)
			else
				local var_6_1 = var_0_4:translation("ADVENTURE_GIFT_BUY_CHOOSE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_1, function()
					local var_8_0 = {
						table_id = arg_4_0.eventInfo.special_data
					}

					arg_4_0.adventureEvent:buyAdventureCard(var_8_0, function(arg_9_0, arg_9_1)
						if arg_9_0 == xyd.error.OK then
							arg_4_0.selfPlayer:handleRewards(arg_9_1.awards)
							xyd.EventDispatcher.get():dispatchEvent({
								name = xyd.event.ADVENTURE_EVENT_FINISH
							})
							xyd.WindowManager.get():closeWindow(arg_4_0.name)
						end
					end)
				end, nil, nil, arg_4_0.colorMode)
			end
		end
	end)
end

function var_0_0.didClose(arg_10_0, arg_10_1)
	var_0_0.super:didClose(arg_10_1)

	if arg_10_0.handle_ then
		var_0_1.unscheduleGlobal(arg_10_0.handle_)
	end
end

function var_0_0.layout(arg_11_0)
	arg_11_0:nodeByName("Text_1"):setString(var_0_4:translation("ADVENTURE_PARTNER_TEXT_5"))
	arg_11_0:nodeByName("text"):setString(string.format(var_0_4:translation("ADVENTURE_MAIL_TEXT"), var_0_6:price(tostring(arg_11_0.eventInfo.special_data))))
	arg_11_0.adventureEvent:updateCardContainer(nil, arg_11_0.cardContainer, nil, arg_11_0.itemId)
end

function var_0_0.startTimeCount(arg_12_0, arg_12_1)
	if arg_12_0.handle_ then
		var_0_1.unscheduleGlobal(arg_12_0.handle_)
	end

	local var_12_0 = arg_12_0.adventureEvent:getEndTime(arg_12_1) - xyd.ServerTime.get():getServerTime()

	if var_12_0 <= 0 then
		return
	end

	arg_12_0.handle_ = var_0_1.scheduleGlobal(function()
		var_12_0 = var_12_0 - 1

		if var_12_0 == 0 then
			if arg_12_0.handle_ then
				var_0_1.unscheduleGlobal(arg_12_0.handle_)

				arg_12_0.handle_ = nil
			end

			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_4:translation("ADVENTURE_END")
			})

			wnd = xyd.WindowManager.get():getWindow("adventure_summon")

			if wnd and not tolua.isnull(wnd) then
				xyd.WindowManager.get():closeWindow("adventure_summon")
			end

			wnd = xyd.WindowManager.get():getWindow("alert")

			if wnd and not tolua.isnull(wnd) then
				xyd.WindowManager.get():closeWindow("alert")
			end
		end
	end, 1)
end

return var_0_0
