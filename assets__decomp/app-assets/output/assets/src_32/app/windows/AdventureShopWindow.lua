local var_0_0 = class("AdventureShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.adventureEvent
local var_0_4 = xyd.tables.adventureShop

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.eventId = arg_1_2.event_info.table_id
	arg_1_0.eventInfo = arg_1_2.event_info
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.adventureEvent = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
	arg_1_0.itemId = var_0_4:itemId(tostring(arg_1_0.eventInfo.special_data))
end

function var_0_0.setupBackground(arg_2_0)
	if arg_2_0.bg then
		arg_2_0:removeChild(arg_2_0.bg, true)
	end

	arg_2_0.bg = xyd.AssetLoader.get():loadSprite(var_0_3:contentBg(tostring(arg_2_0.eventId)))

	arg_2_0.bg:setAnchorPoint(0, 0)
	arg_2_0.bg:setPosition(0, 0)
	arg_2_0.bg:setScale(cc.Director:getInstance():getOpenGLView():getFrameSize().width / arg_2_0.bg:getContentSize().width)
	arg_2_0.bg:addTo(arg_2_0, -1)
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:startTimeCount(arg_3_0.eventId)
	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:nodeByName("btn_buy"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			arg_4_0:nodeByName("btn_buy"):setScale(0.9)
		elseif arg_5_1 == ccui.TouchEventType.moved then
			arg_4_0:nodeByName("btn_buy"):setScale(1)
		elseif arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_4_0:nodeByName("btn_buy"):setScale(1)

			if arg_4_0.selfPlayer.crystal < var_0_4:price(tostring(arg_4_0.eventInfo.special_data)) then
				local var_5_0 = var_0_2:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_0, function()
					local var_6_0 = {}

					var_6_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_6_0)
				end, nil, nil, arg_4_0.colorMode)
			else
				local var_5_1 = var_0_2:translation("ADVENTURE_GIFT_BUY_CHOOSE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_1, function()
					local var_7_0 = {
						table_id = arg_4_0.eventInfo.special_data
					}

					arg_4_0.adventureEvent:buyAdventureItem(var_7_0, function(arg_8_0, arg_8_1)
						if arg_8_0 == xyd.error.OK then
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

function var_0_0.didClose(arg_9_0, arg_9_1)
	var_0_0.super:didClose(arg_9_1)

	if arg_9_0.handle_ then
		var_0_1.unscheduleGlobal(arg_9_0.handle_)
	end
end

function var_0_0.layout(arg_10_0)
	arg_10_0:rewardLayer(arg_10_0:nodeByName("item"), arg_10_0.itemId)
	arg_10_0:nodeByName("item_name"):setString(xyd.tables.item:name(arg_10_0.itemId))
	arg_10_0:nodeByName("price"):setString(tostring(var_0_4:price(tostring(arg_10_0.eventInfo.special_data))))
	arg_10_0:addDialog()
end

function var_0_0.addDialog(arg_11_0)
	local var_11_0 = {
		touchPosition = cc.p(0, 0),
		touchAreaSize = {
			width = 350,
			height = 420
		},
		times = {}
	}
	local var_11_1 = {}

	table.insert(var_11_1, var_0_2:translation("ADVENTURE_PARTNER_TEXT_3"))
	table.insert(var_11_0.times, xyd.tables.misc.dialogDefaultTime)

	var_11_0.msgs = var_11_1
	arg_11_0.speakCellContent = import("app.windows.SpeakCell").new(var_11_0)

	arg_11_0.speakCellContent:addTo(arg_11_0)
	arg_11_0.speakCellContent:setAnchorPoint(cc.p(0, 0))
	arg_11_0.speakCellContent:setPosition(arg_11_0:nodeByName("speak_pos"):getPosition())
	arg_11_0.speakCellContent:onclick()
end

function var_0_0.rewardLayer(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_1:getContentSize().height
	local var_12_1 = var_12_0 / 4
	local var_12_2 = {
		arg_12_2
	}

	if #var_12_2 == 1 and var_12_2[1] == 0 then
		var_12_2 = {}
	end

	local var_12_3 = {}

	var_12_3[1] = 1

	local var_12_4 = #var_12_2

	for iter_12_0 = 1, #var_12_2 do
		if xyd.tables.item:type(var_12_2[iter_12_0]) ~= -1 then
			local var_12_5 = display.newNode()

			var_12_5:setContentSize(var_12_0, var_12_0)

			local var_12_6 = xyd.tables.item:type(var_12_2[iter_12_0])

			xyd.setItemBorder(var_12_5, var_12_2[iter_12_0], false, false, var_12_3[iter_12_0])
			var_12_5:addTo(arg_12_1)
			var_12_5:setAnchorPoint(cc.p(0, 0))
			var_12_5:setPosition((iter_12_0 - 1) * (var_12_0 + var_12_1), 0)

			local var_12_7 = {
				id = var_12_2[iter_12_0],
				lev = xyd.tables.item:level(var_12_2[iter_12_0])
			}

			if xyd.tables.item:type(var_12_2[iter_12_0]) == -1 then
				var_12_7.tipsType = 0
				var_12_7.desc1 = xyd.tables.hero:getDes(var_12_2[iter_12_0])
			elseif specialItem then
				var_12_7.tipsType = 1
				var_12_7.id = -3
			else
				var_12_7.tipsType = 1
				var_12_7.desc1 = xyd.tables.item:desc1(var_12_2[iter_12_0])
				var_12_7.desc2 = xyd.tables.item:desc2(var_12_2[iter_12_0])
			end

			var_12_7.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_12_2[iter_12_0])
			var_12_7.name = xyd.tables.item:name(var_12_2[iter_12_0])

			arg_12_0:addTips(var_12_5, var_12_7)
		end
	end

	return arg_12_1
end

function var_0_0.startTimeCount(arg_13_0, arg_13_1)
	if arg_13_0.handle_ then
		var_0_1.unscheduleGlobal(arg_13_0.handle_)
	end

	local var_13_0 = arg_13_0.adventureEvent:getEndTime(arg_13_1) - xyd.ServerTime.get():getServerTime()

	if var_13_0 <= 0 then
		return
	end

	arg_13_0.handle_ = var_0_1.scheduleGlobal(function()
		var_13_0 = var_13_0 - 1

		if var_13_0 == 0 then
			if arg_13_0.handle_ then
				var_0_1.unscheduleGlobal(arg_13_0.handle_)

				arg_13_0.handle_ = nil
			end

			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_2:translation("ADVENTURE_END")
			})

			wnd = xyd.WindowManager.get():getWindow("adventure_shop")

			if wnd and not tolua.isnull(wnd) then
				xyd.WindowManager.get():closeWindow("adventure_shop")
			end

			wnd = xyd.WindowManager.get():getWindow("alert")

			if wnd and not tolua.isnull(wnd) then
				xyd.WindowManager.get():closeWindow("alert")
			end
		end
	end, 1)
end

return var_0_0
