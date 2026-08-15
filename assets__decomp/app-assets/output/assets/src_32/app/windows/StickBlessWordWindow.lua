local var_0_0 = class("StickBlessWordWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activitySticker
local var_0_4 = xyd.tables.misc
local var_0_5 = 5
local var_0_6 = 103
local var_0_7 = {
	BAN = 2,
	ACTION = 3,
	NORMAL = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.stickBless = xyd.ModelManager.get():loadModel(xyd.ModelType.STICK_BLESS)
	arg_1_0.timeHandler = nil
	arg_1_0.stickType_ = var_0_7.NORMAL
	arg_1_0.tipWndName_ = nil
	arg_1_0.isRunStickAction_ = false
	arg_1_0.isInAction_ = false
	arg_1_0.clickCloseNode_ = nil
	arg_1_0.selectGezi_ = nil
	arg_1_0.itemList_ = {}
	arg_1_0.awards = {}
	arg_1_0.remainNum = 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initData()
	arg_2_0:addBlockLayer()
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	if arg_3_0.timeHandler then
		var_0_1.unscheduleGlobal(arg_3_0.timeHandler)

		arg_3_0.timeHandler = nil
	end
end

function var_0_0.initData(arg_4_0)
	arg_4_0.datas = arg_4_0.stickBless:getStickerList()
	arg_4_0.baseInfo = arg_4_0.stickBless:getBaseInfo()
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("text_has_desc"):setString(var_0_2:translation("STICK_BLESS_FU_NUM"))
	arg_5_0:nodeByName("text_use_desc"):setString(var_0_2:translation("STICK_BLESS_BAN_NUM"))
	arg_5_0:nodeByName("text_score_desc"):setString(var_0_2:translation("STICK_BLESS_SCORE"))
	arg_5_0:nodeByName("text_score_desc_2"):setString(var_0_2:translation("STICK_BLESS_SCORE_3"))
	arg_5_0:nodeByName("text_time_desc"):setString(var_0_2:translation("ACTIVITY_END_TIME"))
	arg_5_0:nodeByName("text_time_desc"):enableOutline(cc.c4b(96, 39, 126, 255), 2)
	arg_5_0:nodeByName("text_time"):enableOutline(cc.c4b(132, 37, 11, 255), 2)
	xyd.imgEvent(arg_5_0:nodeByName("img_close"), function()
		if arg_5_0.awards and next(arg_5_0.awards) then
			arg_5_0.selfPlayer:handleRewards(arg_5_0.awards)

			arg_5_0.awards = {}
		end

		xyd.WindowManager.get():closeWindow(arg_5_0)
	end)
	arg_5_0:initList()
	arg_5_0:initTimeCount()
	arg_5_0:initRightMenu()
	arg_5_0:updateNum()
	arg_5_0:updateRemainNum()
	arg_5_0:nodeByName("text_tips"):setString("")

	local var_5_0 = cc.p(arg_5_0:nodeByName("text_tips"):getPosition())
	local var_5_1 = {
		size = 24,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		color = cc.c3b(152, 51, 12)
	}
	local var_5_2 = xyd.getColorlabel(var_5_1, var_0_2:translation("STICK_BLESS_TITLE_TIPS"))

	var_5_2:setAnchorPoint(cc.p(0, 0.5))
	var_5_2:addTo(arg_5_0:nodeByName("container"))
	var_5_2:setPosition(var_5_0)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_5_0):addEventListener(xyd.event.WINDOW_DID_CLOSE, function(arg_7_0)
		if (arg_7_0.windowName == "map_window" or arg_7_0.windowName == "red_envelope" or arg_7_0.windowName == "summon") and arg_5_0 and not tolua.isnull(arg_5_0) then
			arg_5_0:updateNum()
			arg_5_0:updateRemainNum()
		end
	end)
end

function var_0_0.initList(arg_8_0)
	arg_8_0:nodeByName("list"):removeAllChildren()

	arg_8_0.itemList_ = {}

	local var_8_0 = var_0_6 / 2
	local var_8_1 = arg_8_0:nodeByName("list"):getContentSize().height - var_0_6 / 2

	for iter_8_0 = 1, #arg_8_0.datas do
		local var_8_2 = arg_8_0.datas[iter_8_0]
		local var_8_3 = arg_8_0:createItem(iter_8_0, var_8_2)

		var_8_3:addTo(arg_8_0:nodeByName("list"))
		var_8_3:setPosition(cc.p(var_8_0, var_8_1))

		var_8_0 = var_0_6 + var_8_0

		if iter_8_0 % var_0_5 == 0 then
			var_8_1 = var_8_1 - var_0_6
			var_8_0 = var_0_6 / 2
		end

		table.insert(arg_8_0.itemList_, var_8_3)
	end
end

function var_0_0.createItem(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = var_0_3:itemID(arg_9_2.id)
	local var_9_1 = var_0_3:itemNum(arg_9_2.id)
	local var_9_2 = var_0_3:rarity(arg_9_2.id)
	local var_9_3 = arg_9_2.status
	local var_9_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/stick_bless_word/stick_item.csb")
	local var_9_5 = xyd.tables.item:icon(var_9_0)
	local var_9_6 = xyd.SpriteLoader.new(var_9_5, nil, nil, xyd.DefaultImageType.ITEM_ICON)

	var_9_6:addTo(var_9_4:getChildByName("icon"))
	var_9_6:setAnchorPoint(cc.p(0, 0))
	var_9_6:setPosition(cc.p(0, 0))
	var_9_4:getChildByName("text_num"):setString(var_9_1)

	local var_9_7 = var_9_4:getChildByName("mask")
	local var_9_8 = var_9_4:getChildByName("img_bless")
	local var_9_9 = var_9_4:getChildByName("img_ban")
	local var_9_10 = var_9_4:getChildByName("word_sr")
	local var_9_11 = var_9_4:getChildByName("word_ssr")
	local var_9_12 = var_9_4:getChildByName("yellow_gezi")

	var_9_4.status = var_9_3

	var_9_7:setVisible(false)
	var_9_8:setVisible(false)
	var_9_9:setVisible(false)
	var_9_12:setVisible(false)

	if var_9_3 == 1 then
		var_9_7:setVisible(true)
		var_9_8:setVisible(true)
	elseif var_9_3 == -1 then
		var_9_7:setVisible(true)
		var_9_9:setVisible(true)
	end

	if var_9_2 == 2 then
		var_9_11:setVisible(false)
	elseif var_9_2 == 3 then
		var_9_10:setVisible(false)
	else
		var_9_10:setVisible(false)
		var_9_11:setVisible(false)
	end

	var_9_4:setContentSize(var_0_6, var_0_6)
	var_9_4:setAnchorPoint(cc.p(0.5, 0.5))

	if var_9_3 == 0 then
		local var_9_13
		local var_9_14
		local var_9_15

		var_9_4:setTouchEnabled(true)
		var_9_4:setTouchSwallowEnabled(true)
		var_9_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
			if arg_10_0.name == "began" then
				if arg_9_0.stickType_ == var_0_7.NORMAL then
					arg_9_0:showTips(var_9_4, var_9_0, true)
				else
					var_9_4:setScale(0.9)
				end

				var_9_13 = arg_10_0.x
				var_9_14 = arg_10_0.y
				var_9_15 = false
			elseif arg_10_0.name == "moved" then
				local var_10_0 = 10

				if var_10_0 < math.abs(arg_10_0.x - var_9_13) or var_10_0 < math.abs(arg_10_0.y - var_9_14) then
					var_9_4:setScale(1)

					var_9_15 = true

					if arg_9_0.stickType_ == var_0_7.NORMAL then
						arg_9_0:showTips(var_9_4, var_9_0, false)
					end
				end
			elseif arg_10_0.name == "ended" and not var_9_15 then
				var_9_4:setScale(1)

				if arg_9_0.stickType_ == var_0_7.NORMAL then
					arg_9_0:showTips(var_9_4, var_9_0, false)
				elseif arg_9_0.stickType_ == var_0_7.BAN then
					arg_9_0:ban(arg_9_1, var_9_0, var_9_1)
				end
			end

			return true
		end)
	end

	return var_9_4
end

function var_0_0.showTips(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	if not arg_11_3 and arg_11_0.tipWndName_ then
		xyd.WindowManager.get():closeWindow(arg_11_0.tipWndName_)

		arg_11_0.tipWndName = nil

		return
	end

	local var_11_0 = {
		id = arg_11_2
	}
	local var_11_1 = "new_item_tips"

	arg_11_0.tipWndName_ = var_11_1

	if not xyd.WindowManager.get():getWindow(var_11_1) then
		local var_11_2 = xyd.WindowManager.get():openWindow(var_11_1, var_11_0)

		xyd.adaptToWorldPosition(arg_11_1, var_11_2)
	end
end

function var_0_0.initTimeCount(arg_12_0)
	local var_12_0 = arg_12_0.stickBless.activity.end_time - xyd.ServerTime.get():getServerTime()

	arg_12_0:updateTimeCount(var_12_0)
end

function var_0_0.updateTimeCount(arg_13_0, arg_13_1)
	local var_13_0 = arg_13_0:nodeByName("text_time")

	if arg_13_1 <= 0 then
		arg_13_1 = 0

		var_13_0:setString(xyd.secondsToString(arg_13_1))

		return
	end

	local function var_13_1(arg_14_0)
		if arg_14_0 > 86400 then
			return xyd.secondsToString1(arg_14_0, 3)
		else
			return xyd.secondsToString(arg_14_0)
		end
	end

	if arg_13_0.timeHandler then
		var_0_1.unscheduleGlobal(arg_13_0.timeHandler)

		arg_13_0.timeHandler = nil
	end

	if arg_13_1 > 0 then
		var_13_0:setString(var_13_1(arg_13_1))

		arg_13_0.timeHandler = var_0_1.scheduleGlobal(function()
			arg_13_1 = arg_13_1 - 1

			if var_13_0 and not tolua.isnull(var_13_0) then
				var_13_0:setString(var_13_1(arg_13_1))
			end

			if arg_13_1 <= 0 and arg_13_0.timeHandler then
				var_0_1.unscheduleGlobal(arg_13_0.timeHandler)

				arg_13_0.timeHandler = nil
			end
		end, 1)
	end
end

function var_0_0.initRightMenu(arg_16_0)
	arg_16_0:nodeByName("text_access"):setString(var_0_2:translation("STICK_BLESS_ACCESS"))
	arg_16_0:nodeByName("text_access"):setTouchEnabled(true)
	arg_16_0:nodeByName("text_access"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("stick_bless_access", arg_16_0.baseInfo)
		end
	end)
	arg_16_0:nodeByName("btn_stick"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.ended then
			if arg_16_0.isRunStickAction_ then
				arg_16_0:endSelectAction()

				return
			end

			if not arg_16_0.isInAction_ then
				if #arg_16_0:getCanSelect() == 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("STICK_BLESS_NEED_RESET")
					})

					return
				end

				local var_18_0 = arg_16_0.backpack:getItemNumByID(var_0_4.activityStickerItem)

				if var_18_0 < var_0_4.activityStickerStickCost then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("STICK_BLESS_FU_NOT_ENOUGH")
					})
				else
					arg_16_0.curSelectIdx = {}

					local var_18_1 = 1

					if arg_16_0.remainNum >= 10 and var_18_0 >= 10 * var_0_4.activityStickerStickCost then
						local var_18_2 = var_0_2:translation("STICK_BLESS_EXTRACT")

						local function var_18_3()
							var_18_1 = 10
							arg_16_0.isInAction_ = true

							arg_16_0.stickBless:stickBlessWord(var_18_1, function(arg_20_0, arg_20_1)
								if arg_20_0 == xyd.error.OK then
									if arg_16_0 and not tolua.isnull(arg_16_0) then
										arg_16_0:updateNum()

										arg_16_0.curSelectIdx = arg_20_1.sticker_idx

										arg_16_0:showStickAction()

										arg_16_0.awards = arg_20_1.awards
										arg_16_0.remainNum = arg_16_0.remainNum - 10
									end
								else
									arg_16_0.isInAction_ = false
								end
							end)
						end

						local function var_18_4()
							var_18_1 = 1
							arg_16_0.isInAction_ = true

							arg_16_0.stickBless:stickBlessWord(var_18_1, function(arg_22_0, arg_22_1)
								if arg_22_0 == xyd.error.OK then
									if arg_16_0 and not tolua.isnull(arg_16_0) then
										arg_16_0:updateNum()
										arg_16_0:updateRemainNum()

										arg_16_0.curSelectIdx = arg_22_1.sticker_idx

										arg_16_0:showStickAction()

										arg_16_0.awards = arg_22_1.awards
										arg_16_0.remainNum = arg_16_0.remainNum - 1
									end
								else
									arg_16_0.isInAction_ = false
								end
							end)
						end

						local var_18_5 = {
							rcallBefore = 0,
							lcallBefore = 0,
							width = 380,
							title = var_0_2:translation("TIP"),
							txt = var_18_2,
							rcallback = var_18_3,
							lcallback = var_18_4,
							colorMode = xyd.ColorMode.ACTIVITY,
							leftName = string.format(var_0_2:translation("STICK_BLESS_WORD"), 1),
							rightName = string.format(var_0_2:translation("STICK_BLESS_WORD"), 10)
						}

						xyd.WindowManager.get():openWindow("alert_green", var_18_5)
					else
						var_18_1 = 1
						arg_16_0.isInAction_ = true

						arg_16_0.stickBless:stickBlessWord(var_18_1, function(arg_23_0, arg_23_1)
							if arg_23_0 == xyd.error.OK then
								if arg_16_0 and not tolua.isnull(arg_16_0) then
									arg_16_0:updateNum()

									arg_16_0.curSelectIdx = arg_23_1.sticker_idx

									arg_16_0:showStickAction()

									arg_16_0.awards = arg_23_1.awards
									arg_16_0.remainNum = arg_16_0.remainNum - 1
								end
							else
								arg_16_0.isInAction_ = false
							end
						end)
					end
				end
			end
		end
	end)
	arg_16_0:nodeByName("btn_ban"):addTouchEventListener(function(arg_24_0, arg_24_1)
		if arg_24_1 == ccui.TouchEventType.ended then
			if arg_16_0.stickType_ == var_0_7.BAN then
				arg_16_0:showBanNode(false)

				arg_16_0.isInAction_ = false
				arg_16_0.stickType_ = var_0_7.NORMAL

				return
			end

			if arg_16_0.isInAction_ then
				return
			end

			if arg_16_0.stickBless:getBaseInfo().forbit_num < 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("STICK_BLESS_BAN_NOT_ENOUGH")
				})
			else
				arg_16_0.stickType_ = var_0_7.BAN

				arg_16_0:showBanNode(true)
			end
		end
	end)
	arg_16_0:nodeByName("btn_exchange"):addTouchEventListener(function(arg_25_0, arg_25_1)
		if arg_25_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("stick_bless_shop")
		end
	end)
	arg_16_0:nodeByName("btn_rank"):addTouchEventListener(function(arg_26_0, arg_26_1)
		if arg_26_1 == ccui.TouchEventType.ended then
			arg_16_0.stickBless:stickBlessRank(function(arg_27_0, arg_27_1)
				if arg_27_0 == xyd.error.OK then
					local var_27_0 = {
						rank_list = arg_27_1.rank_list,
						my_rank = arg_27_1.my_rank
					}

					xyd.WindowManager.get():openWindow("stick_bless_rank", var_27_0)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = "get message error"
					})
				end
			end)
		end
	end)
	arg_16_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_28_0, arg_28_1)
		if arg_28_1 == ccui.TouchEventType.ended then
			local var_28_0 = {
				title_name = "STICK_BLESS_TEXT_TITLE",
				rule = "STICK_BLESS_TEXT_RULE",
				hasOtherItem = true,
				otherItemType = xyd.TextRuleItemType.AwardsItem
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_28_0)
		end
	end)
	arg_16_0:nodeByName("btn_reset"):addTouchEventListener(function(arg_29_0, arg_29_1)
		if arg_29_1 == ccui.TouchEventType.ended and not arg_16_0.isInAction_ then
			local var_29_0 = arg_16_0.stickBless:getBaseInfo().free_times
			local var_29_1 = string.format(var_0_2:translation("STICK_BLESS_RESET_TIPS2"), var_0_4.activityStickerResetCost)

			if var_29_0 > 0 then
				var_29_1 = ""
			elseif arg_16_0.selfPlayer.crystal < var_0_4.activityStickerResetCost then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("STICK_BLESS_NO_CRYSTAL")
				})

				return
			end

			local var_29_2 = string.format(var_0_2:translation("STICK_BLESS_RESET_TIPS1"), var_29_1)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_29_2, function()
				arg_16_0.stickBless:stickBlessReset(function(arg_31_0, arg_31_1)
					if arg_31_0 == xyd.error.OK and arg_16_0 and not tolua.isnull(arg_16_0) then
						arg_16_0.clickCloseNode_ = nil
						arg_16_0.selectGezi_ = nil

						arg_16_0:initData()
						arg_16_0:initList()
						arg_16_0:updateNum()
						arg_16_0:updateRemainNum()
					end
				end)
			end, nil, nil, arg_16_0.colorMode)
		end
	end)
end

function var_0_0.showBanNode(arg_32_0, arg_32_1)
	arg_32_0.isInAction_ = true

	local var_32_0 = 0

	for iter_32_0 = 1, #arg_32_0.itemList_ do
		if arg_32_0.itemList_[iter_32_0].status == 0 then
			var_32_0 = var_32_0 + 1

			arg_32_0.itemList_[iter_32_0]:getChildByName("yellow_gezi"):setVisible(arg_32_1)
		end
	end

	if arg_32_1 and var_32_0 <= 0 then
		arg_32_0.isInAction_ = false
	end
end

function var_0_0.ban(arg_33_0, arg_33_1, arg_33_2, arg_33_3)
	local var_33_0 = xyd.tables.item:name(arg_33_2)
	local var_33_1 = string.format(var_0_2:translation("STICK_BLESS_BAN_TIPS_2"), var_33_0, arg_33_3)

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_33_1, function()
		arg_33_0.stickBless:stickBlessBan(arg_33_1, function(arg_35_0, arg_35_1)
			if arg_35_0 == xyd.error.OK and arg_33_0 and not tolua.isnull(arg_33_0) then
				arg_33_0:updateNum()
				arg_33_0:updateRemainNum()
				arg_33_0:showBanAction(arg_33_1)
			end
		end)
	end, nil, nil, arg_33_0.colorMode)
end

function var_0_0.updateNum(arg_36_0)
	local var_36_0 = arg_36_0.stickBless:getBaseInfo()
	local var_36_1 = arg_36_0.backpack:getItemNumByID(var_0_4.activityStickerItem)

	dump(var_0_4.activityStickerItem)
	arg_36_0:nodeByName("text_bless_num"):setString(var_36_1 .. "/" .. var_0_4.activityStickerStickCost)
	arg_36_0:nodeByName("text_use_count"):setString(var_36_0.forbit_num)

	local var_36_2 = var_0_4.activityStickerBanCount - var_36_0.fu_count
	local var_36_3 = string.format(var_0_2:translation("STICK_BLESS_BAN_TIPS"), var_36_2)

	arg_36_0:nodeByName("text_ban_desc"):setString(var_36_3)
	arg_36_0:nodeByName("text_score"):setString(var_36_0.point)
end

function var_0_0.endSelectAction(arg_37_0)
	if arg_37_0.stickBlessHandler then
		var_0_1.unscheduleGlobal(arg_37_0.stickBlessHandler)

		arg_37_0.stickBlessHandler = nil
	end

	if arg_37_0.isRunStickAction_ then
		arg_37_0.isRunStickAction_ = false

		arg_37_0:changeGezi(true)
		arg_37_0:showFuAction()
	end
end

function var_0_0.changeGezi(arg_38_0, arg_38_1)
	local var_38_0 = arg_38_0:getCanSelect()

	if arg_38_0.selectGezi_ then
		arg_38_0.selectGezi_:getChildByName("yellow_gezi"):setVisible(false)
	end

	if arg_38_1 then
		arg_38_0.selectGezi_ = arg_38_0.itemList_[arg_38_0.curSelectIdx[1]]
	else
		local var_38_1 = xyd.randomIndex(arg_38_0.oldIndex or 0, #var_38_0)

		arg_38_0.oldIndex = var_38_1
		arg_38_0.selectGezi_ = var_38_0[var_38_1]
	end

	arg_38_0.selectGezi_:getChildByName("yellow_gezi"):setVisible(true)
end

function var_0_0.getCanSelect(arg_39_0)
	local var_39_0 = {}

	for iter_39_0 = 1, #arg_39_0.itemList_ do
		if arg_39_0.itemList_[iter_39_0].status == 0 then
			table.insert(var_39_0, arg_39_0.itemList_[iter_39_0])
		end
	end

	return var_39_0
end

function var_0_0.showStickAction(arg_40_0)
	if not arg_40_0.curSelectIdx or not next(arg_40_0.itemList_) then
		return
	end

	arg_40_0.isInAction_ = true

	if not arg_40_0.clickCloseNode_ or tolua.isnull(arg_40_0.clickCloseNode_) then
		local var_40_0 = display.newNode()
		local var_40_1 = arg_40_0:nodeByName("list"):getContentSize()

		var_40_0:setContentSize(var_40_1)
		var_40_0:setAnchorPoint(cc.p(0, 0))
		var_40_0:addTo(arg_40_0:nodeByName("list"))
		xyd.imgEvent(var_40_0, function()
			arg_40_0:endSelectAction()
		end)

		arg_40_0.clickCloseNode_ = var_40_0
	else
		arg_40_0.clickCloseNode_:setVisible(true)
	end

	if #arg_40_0:getCanSelect() == 1 then
		arg_40_0:showFuAction()

		return
	end

	if arg_40_0.stickBlessHandler then
		var_0_1.unscheduleGlobal(arg_40_0.stickBlessHandler)

		arg_40_0.stickBlessHandler = nil
	end

	local var_40_2 = 40
	local var_40_3 = 1

	arg_40_0.stickBlessHandler = var_0_1.scheduleGlobal(function()
		if not arg_40_0 or tolua.isnull(arg_40_0) then
			if arg_40_0.stickBlessHandler then
				var_0_1.unscheduleGlobal(arg_40_0.stickBlessHandler)

				arg_40_0.stickBlessHandler = nil
			end

			return
		end

		arg_40_0.isRunStickAction_ = true
		var_40_2 = var_40_2 - 1

		if var_40_2 % var_40_3 <= 0 then
			arg_40_0:changeGezi()
		end

		if var_40_2 <= 0 then
			arg_40_0:changeGezi(true)

			if arg_40_0.stickBlessHandler then
				arg_40_0.isRunStickAction_ = false

				var_0_1.unscheduleGlobal(arg_40_0.stickBlessHandler)

				arg_40_0.stickBlessHandler = nil
			end

			arg_40_0:showFuAction()
		elseif var_40_2 % 15 <= 0 then
			var_40_3 = var_40_3 + 1
		end
	end, 0.1)
end

function var_0_0.showFuAction(arg_43_0)
	for iter_43_0 = 1, #arg_43_0.curSelectIdx do
		local var_43_0 = arg_43_0.curSelectIdx[iter_43_0]

		if not arg_43_0 or tolua.isnull(arg_43_0) or not arg_43_0.itemList_[var_43_0] then
			return
		end

		arg_43_0.clickCloseNode_:setVisible(false)

		local var_43_1 = arg_43_0.itemList_[var_43_0]:getChildByName("mask")
		local var_43_2 = arg_43_0.itemList_[var_43_0]:getChildByName("img_bless")

		var_43_1:setVisible(true)
		var_43_2:setVisible(true)

		local var_43_3 = {}
		local var_43_4 = 1

		var_43_2:setOpacity(0)
		var_43_2:setScale(2)
		table.insert(var_43_3, cc.FadeIn:create(var_43_4))
		table.insert(var_43_3, cc.ScaleTo:create(var_43_4, 1))
		var_43_2:runActionOnce(cc.Spawn:create(var_43_3), false, function()
			arg_43_0.isInAction_ = false

			arg_43_0.itemList_[var_43_0]:getChildByName("yellow_gezi"):setVisible(false)
			arg_43_0.itemList_[var_43_0]:setTouchEnabled(false)

			if arg_43_0.awards and next(arg_43_0.awards) then
				arg_43_0.selfPlayer:handleRewards(arg_43_0.awards)

				arg_43_0.awards = {}
			end
		end)

		arg_43_0.itemList_[var_43_0].status = 1
	end
end

function var_0_0.showBanAction(arg_45_0, arg_45_1)
	if not arg_45_0 or tolua.isnull(arg_45_0) or not arg_45_0.itemList_[arg_45_1] then
		return
	end

	arg_45_0:showBanNode(false)

	arg_45_0.itemList_[arg_45_1].status = -1

	arg_45_0.itemList_[arg_45_1]:setTouchEnabled(false)

	arg_45_0.stickType_ = var_0_7.NORMAL

	local var_45_0 = arg_45_0.itemList_[arg_45_1]:getChildByName("mask")
	local var_45_1 = arg_45_0.itemList_[arg_45_1]:getChildByName("img_ban")

	var_45_0:setVisible(true)
	var_45_1:setVisible(true)

	local var_45_2 = {}
	local var_45_3 = 1

	var_45_1:setOpacity(0)
	var_45_1:setScale(2)
	table.insert(var_45_2, cc.FadeIn:create(var_45_3))
	table.insert(var_45_2, cc.ScaleTo:create(var_45_3, 1))
	var_45_1:runActionOnce(cc.Spawn:create(var_45_2), false, function()
		arg_45_0.isInAction_ = false
	end)
end

function var_0_0.updateRemainNum(arg_47_0)
	arg_47_0.remainNum = 0

	for iter_47_0 = 1, #arg_47_0.itemList_ do
		if arg_47_0.itemList_[iter_47_0].status == 0 then
			arg_47_0.remainNum = arg_47_0.remainNum + 1
		end
	end
end

return var_0_0
