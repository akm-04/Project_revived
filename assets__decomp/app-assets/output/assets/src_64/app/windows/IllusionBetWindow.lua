local var_0_0 = class("IllusionBetWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.illusion = xyd.ModelManager.get():loadModel(xyd.ModelType.ILLUSION)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.setButtonClick(arg_3_0)
	arg_3_0:nodeByName("btn_reset"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			if arg_3_0.illusion.isBetOpen then
				arg_3_0.illusion.betPreSetInfo = clone(arg_3_0.illusion.betInfo)

				arg_3_0:updateListInfo()
				arg_3_0.list:reload()
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("ACTIVITY_GAMBLE_TIP1")
				})
			end
		end
	end)
	arg_3_0:nodeByName("btn_bet"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			if arg_3_0.illusion.isBetOpen then
				if not arg_3_0:checkHasEnoughMoney() then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("ACTIVITY_GAMBLE_TEXT6")
					})
				else
					local var_5_0 = 0

					for iter_5_0, iter_5_1 in pairs(arg_3_0.illusion.betInfo) do
						var_5_0 = var_5_0 + arg_3_0.illusion.betPreSetInfo[iter_5_0] - arg_3_0.illusion.betInfo[iter_5_0]
					end

					if var_5_0 <= 0 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_2:translation("ACTIVITY_GAMBLE_TEXT8")
						})

						return
					end

					local var_5_1

					if arg_3_0.illusion.hasBet then
						var_5_1 = string.format(var_0_2:translation("ACTIVITY_GAMBLE_TIP5"), var_5_0)
					else
						var_5_1 = string.format(var_0_2:translation("ACTIVITY_GAMBLE_TIP2"), var_5_0)
					end

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_1, function()
						arg_3_0.illusion:setIllusionBet(function(arg_7_0, arg_7_1)
							if arg_7_0 == xyd.error.OK and arg_3_0 and not tolua.isnull(arg_3_0) then
								arg_3_0.illusion.betPreSetInfo = clone(arg_3_0.illusion.betInfo)

								arg_3_0:changeButtonState()
								arg_3_0:updateListInfo()
								arg_3_0.list:reload()
							end
						end)
					end, nil, nil, arg_3_0.colorMode)
				end
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("ACTIVITY_GAMBLE_TIP1")
				})
			end
		end
	end)
	arg_3_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = {
				title_name = "ACTIVITY_GAMBLE_RULE_TITLE",
				rule = "ACTIVITY_GAMBLE_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("text_rule", var_8_0)
		end
	end)
end

function var_0_0.checkHasEnoughMoney(arg_9_0)
	local var_9_0 = 0

	for iter_9_0, iter_9_1 in pairs(arg_9_0.illusion.betInfo) do
		var_9_0 = var_9_0 + arg_9_0.illusion.betPreSetInfo[iter_9_0] - arg_9_0.illusion.betInfo[iter_9_0]
	end

	if var_9_0 > arg_9_0.player.mana then
		return false
	else
		return true
	end
end

function var_0_0.changeButtonState(arg_10_0)
	if arg_10_0.illusion.hasBet then
		arg_10_0:nodeByName("word_add_bet"):setVisible(true)
		arg_10_0:nodeByName("word_bet"):setVisible(false)
	else
		arg_10_0:nodeByName("word_add_bet"):setVisible(false)
		arg_10_0:nodeByName("word_bet"):setVisible(true)
	end
end

function var_0_0.layout(arg_11_0)
	arg_11_0:updateTimeCount()
	arg_11_0:setButtonClick()
	arg_11_0:changeButtonState()
	arg_11_0:nodeByName("text_time"):setString(var_0_2:translation("ACTIVITY_GAMBLE_TEXT9"))

	local var_11_0 = xyd.createMultiColorTxt(var_0_2:translation("ACTIVITY_GAMBLE_TEXT1"), xyd.color.WHITE, 24, true)

	var_11_0:setAnchorPoint(0, 0.5)
	var_11_0:addTo(arg_11_0:nodeByName("text_node"))

	local var_11_1 = xyd.createMultiColorTxt(var_0_2:translation("ACTIVITY_GAMBLE_TEXT3"), xyd.color.WHITE, 24, true)

	var_11_1:setAnchorPoint(0, 0.5)
	var_11_1:addTo(arg_11_0:nodeByName("text_node2"))

	local var_11_2 = xyd.createMultiColorTxt(var_0_2:translation("ACTIVITY_GAMBLE_TEXT2"), xyd.color.WHITE, 24, true)

	var_11_2:setAnchorPoint(0, 0.5)
	var_11_2:addTo(arg_11_0:nodeByName("text_node3"))

	local var_11_3 = arg_11_0:nodeByName("num_list")
	local var_11_4 = var_11_3:getContentSize()

	arg_11_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_11_4.width, var_11_4.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_11_3):onScroll(handler(arg_11_0, arg_11_0.scrollListener))

	arg_11_0.list:setBounceable(false)
	arg_11_0.list:setDelegate(handler(arg_11_0, arg_11_0.delegate))
	arg_11_0:updateListInfo()
	arg_11_0.list:reload()
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevX_ = arg_12_1.x
		arg_12_0.prevY_ = arg_12_1.y
	elseif arg_12_1.name == "moved" then
		local var_12_0 = 3

		if var_12_0 <= math.abs(arg_12_1.y - arg_12_0.prevY_) or var_12_0 <= math.abs(arg_12_1.x - arg_12_0.prevX_) then
			arg_12_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.updateListInfo(arg_13_0)
	arg_13_0.listInfo = arg_13_0.illusion.betPreSetInfo
end

function var_0_0.updateTime(arg_14_0)
	local var_14_0 = 0
	local var_14_1 = xyd.ServerTime.get():getSecondsOfDay()

	if var_14_1 < xyd.tables.misc.dungenBossStart or var_14_1 > xyd.tables.misc.dungenBossStop then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_2:translation("PARADISE_BOSS_OPEN_TIP2")
		})

		return
	end
end

function var_0_0.delegate(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	if cc.ui.UIListView.COUNT_TAG == arg_15_2 then
		return (math.ceil(#arg_15_0.listInfo / var_0_3))
	elseif cc.ui.UIListView.CELL_TAG == arg_15_2 then
		local var_15_0 = arg_15_0.list:dequeueItem()

		if not var_15_0 then
			var_15_0 = arg_15_0.list:newItem()
		else
			var_15_0:removeAllChildren(true)
		end

		local var_15_1 = 665
		local var_15_2 = 124

		var_15_0:setItemSize(var_15_1, var_15_2)

		local var_15_3 = display.newNode()

		var_15_3:setContentSize(var_15_1, 124)
		arg_15_0:initCell(var_15_3, arg_15_3)
		var_15_0:addContent(var_15_3)

		return var_15_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_15_2 then
		-- block empty
	end
end

function var_0_0.initCell(arg_16_0, arg_16_1, arg_16_2)
	for iter_16_0 = 1, var_0_3 do
		local var_16_0 = (arg_16_2 - 1) * var_0_3 + iter_16_0

		if var_16_0 > #arg_16_0.listInfo then
			break
		end

		local var_16_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/illusion/illusion_bet/illusion_bet_item.csb")

		var_16_1:setContentSize(100, 111)
		var_16_1:setAnchorPoint(0.5, 0.5)
		var_16_1:setPosition(130 * iter_16_0 - 65, 55)
		arg_16_1:addChild(var_16_1)
		var_16_1:setTouchEnabled(true)
		var_16_1:setTouchSwallowEnabled(false)

		local var_16_2 = var_16_1:getChildByName("bg")

		if arg_16_0.listInfo[var_16_0] <= 0 then
			var_16_2:getChildByName("item_down_bg"):setVisible(false)
			var_16_2:getChildByName("jinbi_small"):setVisible(false)
			var_16_2:getChildByName("jinbi_large"):setVisible(false)
			var_16_2:getChildByName("num"):setVisible(true)
			var_16_2:getChildByName("num"):setString(var_16_0 - 1)
		elseif arg_16_0.listInfo[var_16_0] > 0 and arg_16_0.listInfo[var_16_0] < 10000 then
			var_16_2:getChildByName("item_down_bg"):setVisible(true)
			var_16_2:getChildByName("jinbi_small"):setVisible(true)
			var_16_2:getChildByName("jinbi_large"):setVisible(false)
			var_16_2:getChildByName("num"):setVisible(false)
			var_16_2:getChildByName("item_down_bg"):getChildByName("num_jinbi"):setString(arg_16_0.listInfo[var_16_0])
		else
			var_16_2:getChildByName("item_down_bg"):setVisible(true)
			var_16_2:getChildByName("jinbi_small"):setVisible(false)
			var_16_2:getChildByName("jinbi_large"):setVisible(true)
			var_16_2:getChildByName("num"):setVisible(false)
			var_16_2:getChildByName("item_down_bg"):getChildByName("num_jinbi"):setString(string.format(var_0_2:translation("ACTIVITY_GAMBLE_TEXT4"), math.floor(arg_16_0.listInfo[var_16_0] / 10000)))
		end

		if arg_16_0.listInfo[var_16_0] ~= arg_16_0.illusion.betInfo[var_16_0] then
			var_16_2:getChildByName("item_down_bg"):getChildByName("num_jinbi"):setColor(cc.c4b(255, 0, 0, 255))
		else
			var_16_2:getChildByName("item_down_bg"):getChildByName("num_jinbi"):setColor(cc.c4b(243, 208, 41, 255))
		end

		var_16_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
			if arg_17_0.name == "began" then
				var_16_1:setScale(0.9)

				return true
			elseif arg_17_0.name == "moved" then
				var_16_1:setScale(1)

				return true
			elseif arg_17_0.name == "ended" and not arg_16_0.scrollViewMoved_ then
				var_16_1:setScale(1)

				if arg_16_0.illusion.isBetOpen then
					local var_17_0 = {
						id = var_16_0,
						mana = arg_16_0.listInfo[var_16_0]
					}

					xyd.WindowManager.get():openWindow("illusion_bet_confirm", var_17_0)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("ACTIVITY_GAMBLE_TIP1")
					})
				end
			end
		end)
	end
end

function var_0_0.updateTimeCount(arg_18_0)
	local var_18_0 = arg_18_0:nodeByName("time")

	if arg_18_0.handle_ then
		var_0_1.unscheduleGlobal(arg_18_0.handle_)
	end

	local var_18_1

	if not arg_18_0.illusion.isBetOpen then
		var_18_1 = 0
	else
		local var_18_2 = xyd.ServerTime.get():getSecondsOfDay()

		if var_18_2 < xyd.tables.misc.dayStartTime then
			var_18_1 = xyd.tables.misc.dayStartTime - var_18_2
		else
			var_18_1 = 86400 - var_18_2 + xyd.tables.misc.dayStartTime
		end
	end

	if var_18_1 <= 0 then
		var_18_1 = 0

		return
	end

	var_18_0:setString(xyd.secondsToString(var_18_1, {
		toText = false
	}))

	arg_18_0.handle_ = var_0_1.scheduleGlobal(function()
		if var_18_0 and not tolua.isnull(var_18_0) then
			var_18_1 = var_18_1 - 1

			var_18_0:setString(xyd.secondsToString(var_18_1, {
				toText = false
			}))

			if var_18_1 == 0 then
				arg_18_0.illusion.isBetOpen = false

				if arg_18_0.handle_ then
					var_0_1.unscheduleGlobal(arg_18_0.handle_)

					arg_18_0.handle_ = nil
				end
			end
		elseif arg_18_0.handle_ then
			var_0_1.unscheduleGlobal(arg_18_0.handle_)

			arg_18_0.handle_ = nil
		end
	end, 1)
end

function var_0_0.didOpen(arg_20_0, arg_20_1)
	return
end

function var_0_0.didClose(arg_21_0, arg_21_1)
	var_0_0.super:didClose(arg_21_1)

	if arg_21_0.handle_ then
		var_0_1.unscheduleGlobal(arg_21_0.handle_)

		arg_21_0.handle_ = nil
	end
end

return var_0_0
