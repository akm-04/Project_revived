local var_0_0 = class("WishingPoolCoinWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 35

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.wishingTable = xyd.tables.AnniWishingpoolTable
	arg_1_0.messages = arg_1_2.msg
	arg_1_0.coinUseNum = 0
	arg_1_0.coinID = arg_1_0.wishingTable:getCoinID()
	arg_1_0.coinAllNum = arg_1_0.selfPlayer:getBackpack():getItemNumByID(arg_1_0.coinID)
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	var_0_0.super:didOpen(arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:updateCoinNum()
	arg_3_0:nodeByName("txt_title"):setString(var_0_1:translation("WISHING_POOL_2"))
	arg_3_0:nodeByName("txt_title"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_3_0:nodeByName("txt"):setString(var_0_1:translation("ACTIVITY_VISH_TIP"))
	arg_3_0:nodeByName("btn_add"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.began then
			arg_3_0:nodeByName("btn_add"):setScale(0.9)
		elseif arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0:nodeByName("btn_add"):setScale(1)

			arg_3_0.coinUseNum = arg_3_0.coinUseNum + 1

			if arg_3_0.coinUseNum >= arg_3_0.coinAllNum then
				arg_3_0.coinUseNum = arg_3_0.coinAllNum
			end

			arg_3_0:updateCoinNum()
		end
	end)
	arg_3_0:nodeByName("btn_sub"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			arg_3_0:nodeByName("btn_sub"):setScale(0.9)
		elseif arg_5_1 == ccui.TouchEventType.ended then
			arg_3_0:nodeByName("btn_sub"):setScale(1)

			arg_3_0.coinUseNum = arg_3_0.coinUseNum - 1

			if arg_3_0.coinUseNum <= 0 then
				arg_3_0.coinUseNum = 0
			end

			arg_3_0:updateCoinNum()
		end
	end)
	arg_3_0:nodeByName("close"):getChildByName("txt_cancel"):setString(var_0_1:translation("CANCEL"))
	arg_3_0:nodeByName("btn_send"):getChildByName("txt_send"):setString(var_0_1:translation("CHAT_WINDOW_SEND"))
	arg_3_0:nodeByName("btn_send"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			arg_3_0:nodeByName("btn_send"):setScale(0.9)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			arg_3_0:nodeByName("btn_send"):setScale(1)

			if arg_3_0.coinUseNum <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ANNIVERSARY_SENDING_FALSE_1")
				})

				return
			end

			if not arg_3_0.messages then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ANNIVERSARY_SENDING_FALSE_2")
				})

				return
			end

			local var_6_0 = {
				msg = arg_3_0.messages,
				num = arg_3_0.coinUseNum
			}

			arg_3_0.model:getWishingpool(var_6_0, function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					local var_7_0 = {
						itemID = arg_3_0.coinID,
						itemNum = arg_3_0.coinUseNum
					}

					arg_3_0.selfPlayer:getBackpack():removeItem(var_7_0)
					arg_3_0:updateCoinNum()

					local var_7_1 = xyd.WindowManager.get():getWindow("wishing_wnd")

					if var_7_1 and var_7_1.updateBagItem then
						var_7_1.isCanGetBag = arg_7_1.is_awards
						var_7_1.wishTimes = arg_7_1.wish_times

						for iter_7_0 = 1, #arg_3_0.wishingTable:getAllIds() do
							var_7_1:updateBagItem(iter_7_0)
						end

						var_7_1:updateCoinNum()
						var_7_1:updateWishTimes()

						if arg_3_0.messages then
							local var_7_2 = arg_3_0.messages
							local var_7_3 = arg_3_0.selfPlayer.playerName
							local var_7_4 = var_7_1:getRandomBallistic()

							if var_7_4 == 0 then
								var_7_4 = 4
							end

							local var_7_5 = {
								isSelf = 1,
								txtSize = 24,
								parent = var_7_1.newContainer,
								text = var_7_3,
								text_2 = var_7_2,
								duration = math.random(4, 7),
								ballistic = var_7_4,
								height = var_7_4 * var_0_2,
								callback = function()
									if var_7_1.danmuContainer and not tolua.isnull(var_7_1.danmuContainer) then
										table.insert(var_7_1.unusedBallistic, var_7_4)
									end
								end
							}
							local var_7_6 = import("app.windows.TextBarrageItem").new()

							var_7_6:setParams(var_7_5)
							var_7_6:move()
						end
					end

					if arg_7_1 and arg_7_1.awards then
						arg_3_0.selfPlayer:handleRewards(arg_7_1.awards)
					end

					xyd.WindowManager.get():closeWindow(arg_3_0)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("ANNIVERSARY_SENDING_FALSE")
					})
				end
			end)
		end
	end)
	arg_3_0:initEditBox()
end

function var_0_0.updateCoinNum(arg_9_0)
	arg_9_0:nodeByName("txt_coin_count"):setString(arg_9_0.coinUseNum .. "/" .. arg_9_0.coinAllNum)
end

function var_0_0.initEditBox(arg_10_0)
	local var_10_0 = xyd.AssetLoader.get()
	local var_10_1 = arg_10_0:nodeByName("coin_count_bg")
	local var_10_2 = var_10_1:getContentSize()
	local var_10_3 = 24
	local var_10_4 = "windows/login/transparent.png"

	arg_10_0.editBox_ = ccui.EditBox:create(cc.size(var_10_2.width - 16, var_10_2.height - 8), var_10_4)

	arg_10_0.editBox_:setAnchorPoint(0.5, 0.5)
	arg_10_0.editBox_:setNormalizedPosition(cc.p(0.5, 0.5))
	arg_10_0.editBox_:addTo(var_10_1)
	arg_10_0.editBox_:setFont(var_10_0.FONT_NAME, var_10_3)
	arg_10_0.editBox_:setFontColor(cc.c3b(0, 0, 0))
	arg_10_0.editBox_:registerScriptEditBoxHandler(handler(arg_10_0, arg_10_0.inputboxEventHandler))
	arg_10_0.editBox_:setInputFlag(3)
end

function var_0_0.inputboxEventHandler(arg_11_0, arg_11_1)
	if arg_11_1 == "began" then
		arg_11_0.editBox_:setText("")
		arg_11_0:nodeByName("txt_coin_count"):setVisible(false)
	elseif arg_11_1 == "return" then
		local var_11_0 = arg_11_0.editBox_:getText()
		local var_11_1 = tonumber(var_11_0)

		arg_11_0.editBox_:setText("")
		arg_11_0:nodeByName("txt_coin_count"):setVisible(true)

		if var_11_0 ~= "" then
			if var_11_1 then
				local var_11_2 = math.floor(var_11_1)

				if var_11_2 < 0 then
					local var_11_3 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

					xyd.WindowManager.get():openWindow("toast", {
						message = var_11_3
					})

					return
				elseif var_11_2 > arg_11_0.coinAllNum then
					arg_11_0.coinUseNum = arg_11_0.coinAllNum

					arg_11_0:updateCoinNum()

					return
				else
					arg_11_0.coinUseNum = var_11_2

					arg_11_0:updateCoinNum()
				end

				return
			else
				local var_11_4 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_4
				})

				return
			end
		end
	end
end

return var_0_0
