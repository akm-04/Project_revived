local var_0_0 = class("AdventureFavorWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")
local var_0_3 = xyd.tables.adventureEvent

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.eventId = arg_1_2.event_info.table_id
	arg_1_0.eventInfo = arg_1_2.event_info
	arg_1_0.shop = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.adventureEvent = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_1_0.hero = arg_1_0.selfPlayer:getHeroByID(arg_1_0.eventInfo.special_data)
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

	arg_3_0.cardContainer = arg_3_0:nodeByName("card_container")

	local var_3_0 = require("framework.scheduler")

	arg_3_0:startTimeCount(arg_3_0.eventId)
	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:nodeByName("btn_send"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			arg_4_0:nodeByName("btn_send"):setScale(0.9)
		elseif arg_5_1 == ccui.TouchEventType.moved then
			arg_4_0:nodeByName("btn_send"):setScale(1)
		elseif arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_4_0:nodeByName("btn_send"):setScale(1)

			if arg_4_0.hero:getFavorDegree() >= xyd.tables.misc.libraryFavorLimit then
				local var_5_0 = var_0_1:translation("ADVENTURE_FAVOR_FULL")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_5_0
				})
			elseif arg_4_0.selfPlayer:getBackpack():getItemNumByID(arg_4_0.eventInfo.detail.gift_item) > 0 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("LIBRARY_SURE_SEND_GIFT"), function()
					local var_6_0 = {}

					var_6_0.gift_num = 1
					var_6_0.gift_id = arg_4_0.eventInfo.detail.gift_item
					var_6_0.partner_id = arg_4_0.hero:getHeroID()

					arg_4_0.library:addFavor(var_6_0, function(arg_7_0, arg_7_1)
						if arg_7_0 == xyd.error.OK then
							arg_4_0.selfPlayer:getBackpack():addItemsByID(var_6_0.gift_id, 0 - var_6_0.gift_num)

							if arg_4_0.selfPlayer:getBackpack():getItemNumByID(var_6_0.gift_id) <= 0 then
								local var_7_0 = {}

								var_7_0.itemNum = 0
								var_7_0.itemID = arg_7_1.gift_id

								arg_4_0.selfPlayer:getBackpack():removeItem(var_7_0)
							end

							if var_6_0.gift_id ~= RING_ITEM_ID and arg_7_1.favor_degree then
								arg_4_0.hero:setFavorDegree(arg_7_1.favor_degree)
							end

							arg_4_0:nodeByName("item_num"):setString(arg_4_0.selfPlayer:getBackpack():getItemNumByID(arg_4_0.eventInfo.detail.gift_item))
							arg_4_0:rewardLayer(arg_4_0:nodeByName("item"), arg_4_0.eventInfo.detail.gift_item)

							if var_6_0.gift_id ~= RING_ITEM_ID then
								local var_7_1 = arg_4_0.library:getSendGiftDialogId(arg_4_0.hero, var_6_0.gift_id)
								local var_7_2 = {
									is_read = 1,
									extra_favor = true,
									dialog_id = var_7_1
								}
								local var_7_3 = cc.Sequence:create({
									cc.DelayTime:create(3)
								})

								arg_4_0:nodeByName("bg"):runActionOnce(var_7_3, false, function()
									arg_4_0.library:playDialog(arg_4_0.hero, var_7_2)
									xyd.WindowManager.get():closeWindow(arg_4_0.name)
								end)
							end

							xyd.EventDispatcher.get():dispatchEvent({
								name = xyd.event.ADVENTURE_EVENT_FINISH
							})
						end
					end)
				end, nil, nil, arg_4_0.colorMode)
			elseif arg_4_0.selfPlayer:getBackpack():getItemNumByID(arg_4_0.eventInfo.detail.gift_item) <= 0 then
				local var_5_1 = var_0_1:translation("LIBBRAY_GIFT_NOT_ENOUGH")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_5_1
				})
			end
		end
	end)
	arg_4_0:nodeByName("btn_buy"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.began then
			arg_4_0:nodeByName("btn_buy"):setScale(0.9)
		elseif arg_9_1 == ccui.TouchEventType.moved then
			arg_4_0:nodeByName("btn_buy"):setScale(1)
		elseif arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_4_0:nodeByName("btn_buy"):setScale(1)
			arg_4_0.shop:loadShopList({}, function()
				xyd.WindowManager.get():openWindow("shop", {
					shop_type = xyd.ShopType.MAGIC,
					top_status = xyd.MainSceneTop.CLOSE
				})
			end)
		end
	end)
end

function var_0_0.didClose(arg_11_0, arg_11_1)
	var_0_0.super:didClose(arg_11_1)

	if arg_11_0.handle_ then
		var_0_2.unscheduleGlobal(arg_11_0.handle_)
	end
end

function var_0_0.layout(arg_12_0)
	arg_12_0:nodeByName("text_name"):setString(arg_12_0.hero:getName())
	arg_12_0.adventureEvent:updateCardContainer(arg_12_0.hero, arg_12_0.cardContainer)
	arg_12_0:rewardLayer(arg_12_0:nodeByName("item"), arg_12_0.eventInfo.detail.gift_item)
	arg_12_0:nodeByName("item_num"):setString(arg_12_0.selfPlayer:getBackpack():getItemNumByID(arg_12_0.eventInfo.detail.gift_item))
	arg_12_0:playTalk()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_12_0):addEventListener(xyd.event.REFRESH_MAGIC_GIFT, function(arg_13_0)
		if arg_12_0 and not tolua.isnull(arg_12_0) then
			arg_12_0:rewardLayer(arg_12_0:nodeByName("item"), arg_12_0.eventInfo.detail.gift_item)
			arg_12_0:nodeByName("item_num"):setString(arg_12_0.selfPlayer:getBackpack():getItemNumByID(arg_12_0.eventInfo.detail.gift_item))
		end
	end)
end

function var_0_0.rewardLayer(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_1:getContentSize().height
	local var_14_1 = var_14_0 / 4
	local var_14_2 = {
		arg_14_2
	}

	if #var_14_2 == 1 and var_14_2[1] == 0 then
		var_14_2 = {}
	end

	local var_14_3 = {}

	var_14_3[1] = 1

	local var_14_4 = #var_14_2

	for iter_14_0 = 1, #var_14_2 do
		if xyd.tables.item:type(var_14_2[iter_14_0]) ~= -1 then
			local var_14_5 = display.newNode()

			var_14_5:setContentSize(var_14_0, var_14_0)

			local var_14_6 = xyd.tables.item:type(var_14_2[iter_14_0])

			xyd.setItemBorder(var_14_5, var_14_2[iter_14_0], false, false, var_14_3[iter_14_0])
			var_14_5:addTo(arg_14_1)
			var_14_5:setAnchorPoint(cc.p(0, 0))
			var_14_5:setPosition((iter_14_0 - 1) * (var_14_0 + var_14_1), 0)

			local var_14_7 = {
				id = var_14_2[iter_14_0],
				lev = xyd.tables.item:level(var_14_2[iter_14_0])
			}

			if xyd.tables.item:type(var_14_2[iter_14_0]) == -1 then
				var_14_7.tipsType = 0
				var_14_7.desc1 = xyd.tables.hero:getDes(var_14_2[iter_14_0])
			elseif specialItem then
				var_14_7.tipsType = 1
				var_14_7.id = -3
			else
				var_14_7.tipsType = 1
				var_14_7.desc1 = xyd.tables.item:desc1(var_14_2[iter_14_0])
				var_14_7.desc2 = xyd.tables.item:desc2(var_14_2[iter_14_0])
			end

			var_14_7.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_14_2[iter_14_0])
			var_14_7.name = xyd.tables.item:name(var_14_2[iter_14_0])

			arg_14_0:addTips(var_14_5, var_14_7)
		end
	end

	return arg_14_1
end

function var_0_0.playTalk(arg_15_0)
	arg_15_0:nodeByName("text"):setString("")
	arg_15_0:speak(var_0_1:translation("ADVENTURE_PARTNER_TEXT_2"), arg_15_0:nodeByName("text"), xyd.tables.misc.dialogSpeed)
end

function var_0_0.speak(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	local var_16_0 = xyd.utf8len(arg_16_1)

	arg_16_0.showInOneTime = false
	arg_16_0.isOnSpeaking = true

	local var_16_1 = 0

	if arg_16_0.handler then
		var_0_2.unscheduleGlobal(arg_16_0.handler)

		arg_16_0.handler = nil
	end

	arg_16_0.handler = var_0_2.scheduleGlobal(function()
		var_16_1 = var_16_1 + 1

		if var_16_1 > var_16_0 and arg_16_0.handler or arg_16_0.showInOneTime == true then
			if not tolua.isnull(arg_16_2) then
				arg_16_2:setString(arg_16_1)
			end

			var_0_2.unscheduleGlobal(arg_16_0.handler)

			arg_16_0.isOnSpeaking = false

			return
		end

		local var_17_0 = xyd.getSplitUtf8Str(arg_16_1, 0, var_16_1 * 3)

		if not tolua.isnull(arg_16_2) then
			arg_16_2:setString(var_17_0)
		end
	end, arg_16_3)
end

function var_0_0.startTimeCount(arg_18_0, arg_18_1)
	if arg_18_0.handle_ then
		var_0_2.unscheduleGlobal(arg_18_0.handle_)
	end

	local var_18_0 = arg_18_0.adventureEvent:getEndTime(arg_18_1) - xyd.ServerTime.get():getServerTime()

	if var_18_0 <= 0 then
		return
	end

	arg_18_0.handle_ = var_0_2.scheduleGlobal(function()
		var_18_0 = var_18_0 - 1

		if var_18_0 == 0 then
			if arg_18_0.handle_ then
				var_0_2.unscheduleGlobal(arg_18_0.handle_)

				arg_18_0.handle_ = nil
			end

			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("ADVENTURE_END")
			})

			wnd = xyd.WindowManager.get():getWindow("adventure_favor")

			if wnd and not tolua.isnull(wnd) then
				xyd.WindowManager.get():closeWindow("adventure_favor")
			end

			wnd = xyd.WindowManager.get():getWindow("alert")

			if wnd and not tolua.isnull(wnd) then
				xyd.WindowManager.get():closeWindow("alert")
			end
		end
	end, 1)
end

return var_0_0
