local var_0_0 = class("KiteWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = {
	INITIAL = 0,
	CAN_SEND_AGIN = 2,
	GO_TO_CHARGE = 3,
	FIRST_CAN_SEND = 1
}
local var_0_4 = {
	FINISH = 2,
	SEND = 1
}
local var_0_5 = 3
local var_0_6 = 285
local var_0_7 = 137
local var_0_8 = 30

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.kite = xyd.ModelManager.get():loadModel(xyd.ModelType.KITE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.player_id = arg_1_0.selfPlayer.playerID
	arg_1_0.daily_grab_times = arg_1_0.kite.daily_grab_times
end

function var_0_0.initLeftItems(arg_2_0)
	for iter_2_0, iter_2_1 in pairs(arg_2_0.kite:getKiteList()) do
		local var_2_0 = arg_2_0:createLeftContent(iter_2_1)

		arg_2_0:addKiteMessage(var_2_0)
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)

	arg_3_0.leftList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(1, 1, 490, 565),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("left_list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))
	arg_3_0.rightList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 585, 350),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("right_list")):setBounceable(false)
	arg_3_0.leftListItems = {}
	arg_3_0.rightListItems = {}

	arg_3_0:initLeftItems()
	arg_3_0.leftList:setDelegate(handler(arg_3_0, arg_3_0.leftListDelegate))

	arg_3_0.rightScrollNodeY = nil

	arg_3_0:nodeByName("kite_king_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("kite_election")
		end
	end)
	arg_3_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("kiteking_rule")
		end
	end)
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
	arg_6_0:updateRightList()
	arg_6_0:leftListScrollToEnd()
	arg_6_0:addBlockLayer(cc.c4b(0, 0, 0, 220), true)
end

function var_0_0.didClose(arg_7_0)
	arg_7_0.leftList:removeAllItems()
end

function var_0_0.leftListDelegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return #arg_8_0.leftListItems
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_0
		local var_8_1 = arg_8_1:dequeueItem()

		if not var_8_1 then
			var_8_1 = arg_8_1:newItem()
		else
			var_8_1:removeAllChildren(false)
		end

		local var_8_2 = arg_8_0.leftListItems[arg_8_3]
		local var_8_3 = var_8_2:getWidth()
		local var_8_4 = var_8_2:getHeight()

		if var_8_2.type == var_0_4.SEND then
			local var_8_5 = var_8_2:getChildByName("source"):getChildByName("container")
			local var_8_6 = var_8_5:getChildByName("qiang_bg_mask")
			local var_8_7 = var_8_2.kite

			if var_8_7.packet_id == arg_8_0.kite.grab_packet_id then
				arg_8_0.kite.grab_packet_id = 0

				local var_8_8 = {
					kite = var_8_7
				}

				xyd.WindowManager.get():openWindow("anser_question", var_8_8)
			end

			if var_8_5:getChildByName("click_node") then
				var_8_5:removeChildByName("click_node", true)
			end

			local var_8_9 = display.newNode()

			var_8_9:setContentSize(var_0_6, var_0_7)
			var_8_9:setAnchorPoint(cc.p(0.5, 0.5))
			var_8_9:setPosition(var_8_6:getPosition())
			var_8_9:addTo(var_8_5)
			var_8_9:setName("click_node")
			var_8_9:setLocalZOrder(100)
			var_8_9:setTouchEnabled(true)
			var_8_9:setTouchSwallowEnabled(false)
			var_8_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
				if arg_9_0.name == "began" then
					var_8_6:setVisible(true)

					return true
				elseif arg_9_0.name == "moved" then
					if arg_8_0.scrollViewMoved_ then
						var_8_6:setVisible(false)
					end

					return true
				elseif arg_9_0.name == "ended" and not arg_8_0.scrollViewMoved_ then
					var_8_6:setVisible(false)

					if arg_8_0.daily_grab_times >= var_0_8 then
						local var_9_0 = {
							message = var_0_2:translation("DAILY_GRAB_MAX_TIMES")
						}

						xyd.WindowManager.get():openWindow("toast", var_9_0)

						return
					end

					if arg_8_0:isKiteOpen(var_8_7.grab_players) or var_8_7.player_id == arg_8_0.player_id then
						local var_9_1 = {
							packet_id = var_8_7.packet_id
						}

						arg_8_0.kite:loadGrabRecord(var_9_1, function(arg_10_0, arg_10_1)
							local var_10_0 = arg_10_1.log_list
							local var_10_1 = {
								players = var_10_0,
								id = var_8_7.id
							}

							xyd.WindowManager.get():openWindow("kite_record", var_10_1)
						end)

						return
					else
						local var_9_2 = {
							packet_id = var_8_7.packet_id
						}

						arg_8_0.kite:grabKite(var_9_2, function(arg_11_0, arg_11_1)
							if arg_11_1.packet_info then
								local var_11_0 = arg_11_1.packet_info

								if arg_8_0:isKiteExpired(arg_11_1.packet_info.time) then
									xyd.WindowManager.get():openWindow("toast", {
										message = var_0_2:translation("KITE_EXPIRED")
									})
								else
									local var_11_1 = arg_8_0:isKiteOpen(var_11_0.grab_players)

									var_8_5:getChildByName("open_kite_type" .. var_8_7.id):setVisible(var_11_1)
									var_8_5:getChildByName("close_kite_type" .. var_8_7.id):setVisible(false)

									local var_11_2 = var_8_5:getChildByName("desc_label")

									var_11_2:setString(var_0_2:translation("CHECK_KITE"))
									var_11_2:setColor(cc.c3b(241, 235, 7))

									if var_11_1 then
										arg_8_0.daily_grab_times = arg_8_0.daily_grab_times + 1
										var_8_7.grab_players = var_11_0.grab_players

										xyd.WindowManager.get():openWindow("anser_question", {
											kite = var_8_7
										})
									else
										local var_11_3 = {
											failed = true,
											kite = var_8_7
										}

										xyd.WindowManager.get():openWindow("grab_kite_result", var_11_3)
									end
								end
							end
						end)
					end
				end
			end)
		end

		var_8_1:setItemSize(var_8_3, var_8_4)
		var_8_1:addContent(var_8_2)

		return var_8_1
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_8_2 then
		arg_8_0.leftListItems[arg_8_3]:removeFromParent(false)
	end
end

function var_0_0.updateRightList(arg_12_0)
	arg_12_0.rightList:removeAllItems()

	arg_12_0.rightListItems = nil
	arg_12_0.rightListItems = {}

	local var_12_0 = xyd.tables.kite:getItemMaxNum()

	for iter_12_0 = 1, var_12_0 do
		local var_12_1 = display.newNode()
		local var_12_2 = arg_12_0.rightList:newItem()
		local var_12_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/kite/right_item.csb")
		local var_12_4 = var_12_3:getChildByName("container")

		arg_12_0:initRightListCell(var_12_4, iter_12_0)
		var_12_3:addTo(var_12_1)
		var_12_3:setAnchorPoint(cc.p(0, 0))
		table.insert(arg_12_0.rightListItems, var_12_4)
		var_12_1:setContentSize(var_12_4:getContentSize())
		var_12_2:addContent(var_12_1)
		var_12_2:setItemSize(var_12_4:getWidth(), var_12_4:getHeight() + 10)
		arg_12_0.rightList:addItem(var_12_2)
	end

	arg_12_0.rightList:reload()

	if arg_12_0.rightScrollNodeY then
		arg_12_0.rightList:getScrollNode():setPositionY(arg_12_0.rightScrollNodeY)
	end
end

function var_0_0.initRightListCell(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_0.kite:getSelfState()[arg_13_2]
	local var_13_1 = arg_13_1:getChildByName("kite_num_txt")
	local var_13_2 = arg_13_1:getChildByName("charge_num_txt")
	local var_13_3 = string.format(var_0_2:translation("KITE_NUM_TIP"), xyd.tables.kite:activityAmount(arg_13_2), var_0_2:translation("KITE_NAME_TYPE" .. arg_13_2))
	local var_13_4 = ""

	if var_13_0 == var_0_3.INITIAL then
		var_13_4 = string.format(var_0_2:translation("KITE_CHARGE_TIP2"), xyd.tables.kite:amount(arg_13_2))
	elseif var_13_0 == var_0_3.GO_TO_CHARGE then
		var_13_4 = string.format(var_0_2:translation("KITE_CHARGE_TIP"), xyd.tables.kite:amount(arg_13_2))
	else
		var_13_3 = string.format(var_0_2:translation("KITE_NUM_TIP"), arg_13_0.kite:getCanSendNum()[arg_13_2], var_0_2:translation("KITE_NAME_TYPE" .. arg_13_2))
		var_13_4 = string.format(var_0_2:translation("KITE_CAN_SEND"))
	end

	var_13_1:setString(var_13_3)
	var_13_2:setString(var_13_4)
	arg_13_0:initItemBtn(var_13_0, arg_13_1, arg_13_2)
end

function var_0_0.initItemBtn(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	local var_14_0 = arg_14_2:getChildByName("check_btn")
	local var_14_1 = arg_14_2:getChildByName("send_btn")
	local var_14_2 = var_14_1:getChildByName("send_txt")
	local var_14_3 = var_14_1:getChildByName("send_again_txt")
	local var_14_4 = var_14_1:getChildByName("charge_txt")

	var_14_2:setVisible(arg_14_1 == var_0_3.FIRST_CAN_SEND)
	var_14_3:setVisible(arg_14_1 == var_0_3.CAN_SEND_AGIN)
	var_14_0:setVisible(arg_14_1 == var_0_3.CAN_SEND_AGIN or arg_14_1 == var_0_3.GO_TO_CHARGE)
	var_14_4:setVisible(arg_14_1 == var_0_3.GO_TO_CHARGE or arg_14_1 == var_0_3.INITIAL)
	var_14_0:addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			local var_15_0 = {
				id = arg_14_3
			}

			arg_14_0.kite:loadKiteRecord(var_15_0, function(arg_16_0, arg_16_1)
				if arg_16_1.log_list then
					local var_16_0 = {
						players = arg_16_1.log_list,
						id = arg_14_3
					}

					xyd.WindowManager.get():openWindow("send_kite_record", var_16_0)
				end
			end)
		end
	end)
	var_14_1:addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended then
			if arg_14_1 == var_0_3.INITIAL or arg_14_1 == var_0_3.GO_TO_CHARGE then
				xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
			end

			if arg_14_1 == var_0_3.FIRST_CAN_SEND or arg_14_1 == var_0_3.CAN_SEND_AGIN then
				local var_17_0 = {
					idx = arg_14_3
				}

				var_17_0.total_num = arg_14_0.kite:getCanSendNum()[var_17_0.idx]

				xyd.WindowManager.get():openWindow("select_kite_num", var_17_0)
			end
		end
	end)
end

function var_0_0.rechargeUpdate_(arg_18_0, arg_18_1)
	arg_18_0.kite:loadKiteInfo(nil, function(arg_19_0)
		if arg_19_0 == xyd.error.OK then
			arg_18_0.rightScrollNodeY = arg_18_0.rightList:getScrollNode():getPositionY()

			arg_18_0:updateRightList()
		end
	end)
end

function var_0_0.updateRightListItem(arg_20_0, arg_20_1)
	arg_20_0:initRightListCell(arg_20_0.rightListItems[arg_20_1], arg_20_1)
end

function var_0_0.createLabel(arg_21_0, arg_21_1, arg_21_2, arg_21_3)
	local var_21_0 = {
		color = arg_21_1,
		size = arg_21_2
	}
	local var_21_1 = xyd.AssetLoader.get():loadLabel(var_21_0)

	if arg_21_3 then
		var_21_1:setMaxLineWidth(arg_21_3)
	end

	return var_21_1
end

function var_0_0.addKiteMessage(arg_22_0, arg_22_1)
	if #arg_22_0.leftListItems == xyd.tables.misc.kitesShowMaxNum then
		table.remove(arg_22_0.leftListItems, 1):release()
	end

	table.insert(arg_22_0.leftListItems, arg_22_1)
	arg_22_1:retain()
end

function var_0_0.createLeftContent(arg_23_0, arg_23_1)
	local var_23_0 = display.newNode()
	local var_23_1
	local var_23_2

	var_23_0.kite = arg_23_1
	var_23_0.type = arg_23_1.type

	if arg_23_1.type == var_0_4.SEND then
		var_23_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/kite/kite_begin.csb")

		local var_23_3 = var_23_1:getChildByName("container")

		arg_23_0:setAllKiteinvisibel(var_23_3)
		var_23_3:getChildByName("qiang_bg_mask"):setVisible(false)

		local var_23_4, var_23_5 = var_23_3:getChildByName("grab_txt_pos"):getPosition()
		local var_23_6 = var_23_3:getChildByName("open_kite_type" .. arg_23_1.id)
		local var_23_7 = var_23_3:getChildByName("close_kite_type" .. arg_23_1.id)
		local var_23_8, var_23_9 = var_23_3:getChildByName("desc_pos"):getPosition()

		arg_23_0:showAvatarAndName(var_23_3, arg_23_1)

		local var_23_10 = arg_23_0:isKiteOpen(arg_23_1.grab_players)
		local var_23_11 = arg_23_0:isGrabAll(arg_23_1)
		local var_23_12 = arg_23_0:createLabel(cc.c3b(242, 151, 75), 24)

		var_23_12:addTo(var_23_3)
		var_23_12:setName("desc_label")
		var_23_12:setAnchorPoint(cc.p(0.5, 0.5))
		var_23_12:setPosition(var_23_4, var_23_5)

		if not var_23_10 and not var_23_11 and arg_23_1.player_id ~= arg_23_0.player_id then
			var_23_12:setString(var_0_2:translation("OPEN_KITE"))
			var_23_12:setColor(cc.c3b(242, 151, 75))
		else
			var_23_12:setString(var_0_2:translation("CHECK_KITE"))
			var_23_12:setColor(cc.c3b(241, 235, 7))
		end

		var_23_12:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

		if var_23_10 or var_23_11 then
			var_23_6:setVisible(true)
			var_23_7:setVisible(false)
		else
			var_23_6:setVisible(false)
			var_23_7:setVisible(true)
		end

		local var_23_13 = arg_23_0:createLabel(cc.c3b(255, 255, 255), 24, 190)

		var_23_13:addTo(var_23_3)
		var_23_13:setAnchorPoint(cc.p(0, 1))
		var_23_13:setPosition(var_23_8, var_23_9)
		var_23_13:setString(arg_23_1.content)
		var_23_0:setContentSize(var_23_3:getContentSize())
	elseif arg_23_1.type == var_0_4.FINISH then
		var_23_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/kite/kite_end.csb")

		local var_23_14 = var_23_1:getChildByName("container")

		var_23_0:setContentSize(var_23_14:getWidth(), var_23_14:getHeight() + 10)
		arg_23_0:layoutFinishLabel(var_23_14, arg_23_1)
	end

	var_23_0:addChild(var_23_1)
	var_23_1:setName("source")

	return var_23_0
end

function var_0_0.layoutFinishLabel(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = {}
	local var_24_1 = {
		arg_24_2.player_name .. var_0_2:translation("KITE_FINISH_TIP1"),
		arg_24_0:buildTimeStr(arg_24_2.offset_time),
		var_0_2:translation("KITE_FINISH_TIP2"),
		arg_24_2.lucky_player,
		(var_0_2:translation("KITE_FINISH_TIP3"))
	}

	for iter_24_0 = 1, 5 do
		var_24_0[iter_24_0] = arg_24_1:getChildByName("label" .. iter_24_0)

		var_24_0[iter_24_0]:setString(var_24_1[iter_24_0])

		if iter_24_0 ~= 1 and iter_24_0 ~= 4 then
			var_24_0[iter_24_0]:setPositionX(var_24_0[iter_24_0 - 1]:getPositionX() + var_24_0[iter_24_0 - 1]:getWidth() + 1)
		end
	end
end

function var_0_0.buildTimeStr(arg_25_0, arg_25_1)
	local var_25_0 = {
		math.floor(arg_25_1 / 3600),
		math.floor(arg_25_1 % 3600 / 60),
		arg_25_1 % 3600 % 60
	}
	local var_25_1 = {
		var_0_2:translation("UNIT_HOUR"),
		var_0_2:translation("UNIT_MINUTE"),
		(var_0_2:translation("UNIT_SECOND"))
	}
	local var_25_2 = ""

	for iter_25_0, iter_25_1 in ipairs(var_25_0) do
		iter_25_1 = iter_25_1 == 0 and "" or iter_25_1 .. var_25_1[iter_25_0]

		if iter_25_1 and iter_25_1 ~= "" then
			var_25_2 = var_25_2 .. iter_25_1
		end
	end

	return var_25_2
end

function var_0_0.updateKiteList(arg_26_0, arg_26_1)
	local var_26_0 = arg_26_1.params.msg

	arg_26_0:addKiteMessage(arg_26_0:createLeftContent(var_26_0))
	arg_26_0:leftListScrollToEnd()
end

function var_0_0.leftListScrollToEnd(arg_27_0)
	arg_27_0.leftList:reload()

	local var_27_0 = arg_27_0:getKiteMessageHeight()
	local var_27_1 = arg_27_0.leftList:getViewRectInWorldSpace()
	local var_27_2 = 0

	if var_27_0 > var_27_1.height then
		var_27_2 = var_27_0 - var_27_1.height
	end

	local var_27_3 = arg_27_0.leftList:getScrollNode()

	var_27_3:setPositionY(var_27_3:getPositionY() + var_27_2)
end

function var_0_0.getKiteMessageHeight(arg_28_0)
	local var_28_0 = 0

	for iter_28_0, iter_28_1 in pairs(arg_28_0.leftListItems) do
		var_28_0 = var_28_0 + iter_28_1:getHeight()
	end

	return var_28_0
end

function var_0_0.isKiteOpen(arg_29_0, arg_29_1)
	if not arg_29_1 then
		return false
	end

	for iter_29_0, iter_29_1 in pairs(arg_29_1) do
		if iter_29_1 == arg_29_0.selfPlayer.playerID then
			return true
		end
	end

	return false
end

function var_0_0.isGrabAll(arg_30_0, arg_30_1)
	if arg_30_1.total == 0 then
		return true
	else
		return false
	end
end

function var_0_0.scrollListener(arg_31_0, arg_31_1)
	if arg_31_1.name == "began" then
		arg_31_0.scrollViewMoved_ = false
		arg_31_0.prevY_ = arg_31_1.y
	elseif arg_31_1.name == "moved" and 10 <= math.abs(arg_31_1.y - arg_31_0.prevY_) then
		arg_31_0.scrollViewMoved_ = true
	end
end

function var_0_0.isKiteExpired(arg_32_0, arg_32_1)
	if xyd.ServerTime.get():getServerTime() - arg_32_1 > xyd.tables.misc.kitesExpireTime then
		return true
	end

	return false
end

function var_0_0.showAvatarAndName(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = arg_33_2.player_name
	local var_33_1, var_33_2 = arg_33_1:getChildByName("avatar_pos"):getPosition()
	local var_33_3, var_33_4 = arg_33_1:getChildByName("name_pos"):getPosition()

	arg_33_1:getChildByName("avatar_kuang"):setVisible(false)

	local var_33_5 = display.newNode()

	var_33_5:setContentSize(90, 90)
	var_33_5:setPosition(var_33_1, var_33_2)
	var_33_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_33_5:addTo(arg_33_1)

	local var_33_6 = {
		avatar_id = arg_33_2.avatar_id,
		avatar_frame_id = arg_33_2.avatar_frame_id,
		playerInfo = {
			player_id = arg_33_2.player_id
		}
	}

	xyd.setPlayerAvatar(var_33_5, var_33_6)

	local var_33_7 = {
		size = 22,
		color = cc.c3b(255, 255, 255)
	}
	local var_33_8 = xyd.AssetLoader.get():loadLabel(var_33_7)

	var_33_8:addTo(arg_33_1)
	var_33_8:setPosition(var_33_3, var_33_4)
	var_33_8:setAnchorPoint(cc.p(0.5, 0.5))

	local var_33_9 = "(S" .. arg_33_2.region .. ")" .. (xyd.utf8len(var_33_0) > 5 and xyd.getTextstr(var_33_0, 1, 4) .. "..." or var_33_0)

	var_33_8:setString(var_33_9)
end

function var_0_0.kiteFinishRefresh(arg_34_0, arg_34_1)
	for iter_34_0, iter_34_1 in ipairs(arg_34_0.leftListItems) do
		local var_34_0 = arg_34_1.params.msg
		local var_34_1 = iter_34_1.kite

		if var_34_0.packet_id == var_34_1.packet_id then
			local var_34_2 = iter_34_1:getChildByName("source"):getChildByName("container"):getChildByName("desc_label")

			var_34_2:setString(var_0_2:translation("CHECK_KITE"))
			var_34_2:setColor(cc.c3b(241, 235, 7))
		end
	end
end

function var_0_0.setAllKiteinvisibel(arg_35_0, arg_35_1)
	for iter_35_0 = 1, var_0_5 do
		arg_35_1:getChildByName("open_kite_type" .. iter_35_0):setVisible(false)
		arg_35_1:getChildByName("close_kite_type" .. iter_35_0):setVisible(false)
	end
end

return var_0_0
