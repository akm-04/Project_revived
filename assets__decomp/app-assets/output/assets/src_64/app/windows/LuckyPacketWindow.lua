local var_0_0 = class("LuckyPacketWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = {
	CAN_SEND = 1,
	HAVE_SEND = 2,
	NO_SEND = 0
}
local var_0_4 = {
	FINISH = 2,
	SEND = 1
}
local var_0_5 = 285
local var_0_6 = 137

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.luckyPacket = xyd.ModelManager.get():loadModel(xyd.ModelType.LUCKY_PACKET)
end

function var_0_0.initLeftItems(arg_2_0)
	for iter_2_0, iter_2_1 in pairs(arg_2_0.luckyPacket:getSakuraLuckyPacketList()) do
		local var_2_0 = arg_2_0:createLeftContent(iter_2_1)

		arg_2_0:addPacketMessage(var_2_0)
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
		viewRect = cc.rect(1, 1, 576, 405),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("right_list"))
	arg_3_0.leftListItems = {}
	arg_3_0.rightListItems = {}

	arg_3_0:initLeftItems()
	arg_3_0.leftList:setDelegate(handler(arg_3_0, arg_3_0.leftListDelegate))

	arg_3_0.rightScrollNodeY = nil
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:addBlockLayer(cc.c4b(0, 0, 0, 220), true)
	arg_4_0:updateRightList()
	arg_4_0:leftListScrollToEnd()
end

function var_0_0.didClose(arg_5_0)
	arg_5_0.leftList:removeAllItems()
end

function var_0_0.leftListDelegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return #arg_6_0.leftListItems
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0
		local var_6_1 = arg_6_1:dequeueItem()

		if not var_6_1 then
			var_6_1 = arg_6_1:newItem()
		else
			var_6_1:removeAllChildren(false)
		end

		local var_6_2 = arg_6_0.leftListItems[arg_6_3]
		local var_6_3 = var_6_2:getWidth()
		local var_6_4 = var_6_2:getHeight()

		if var_6_2.type == var_0_4.SEND then
			local var_6_5 = var_6_2:getChildByName("source"):getChildByName("container")
			local var_6_6 = var_6_5:getChildByName("qiang_bg_mask")
			local var_6_7 = var_6_2.luckyPacket

			if var_6_5:getChildByName("click_node") then
				var_6_5:removeChildByName("click_node", true)
			end

			local var_6_8 = display.newNode()

			var_6_8:setContentSize(var_0_5, var_0_6)
			var_6_8:setAnchorPoint(cc.p(1, 0.5))
			var_6_8:setPosition(var_6_6:getPosition())
			var_6_8:addTo(var_6_5)
			var_6_8:setName("click_node")
			var_6_8:setLocalZOrder(100)
			var_6_8:setTouchEnabled(true)
			var_6_8:setTouchSwallowEnabled(false)
			var_6_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
				if arg_7_0.name == "began" then
					var_6_6:setVisible(true)

					return true
				elseif arg_7_0.name == "moved" then
					if arg_6_0.scrollViewMoved_ then
						var_6_6:setVisible(false)
					end

					return true
				elseif arg_7_0.name == "ended" and not arg_6_0.scrollViewMoved_ then
					var_6_6:setVisible(false)

					local var_7_0 = {
						packet_id = var_6_7.packet_id
					}

					arg_6_0.luckyPacket:grabPacket(var_7_0, function(arg_8_0, arg_8_1)
						if arg_8_1.award_money then
							local var_8_0 = {
								crystal = arg_8_1.award_money,
								packetID = arg_8_1.packet_info.packet_id,
								container = var_6_5,
								id = arg_8_1.packet_info.id
							}

							xyd.WindowManager.get():openWindow("grab_packet_result", var_8_0)
						else
							if arg_8_1.packet_info and arg_6_0:isPacketOpen(arg_8_1.packet_info.grab_players) then
								local var_8_1 = {
									packet_id = var_6_7.packet_id
								}

								arg_6_0.luckyPacket:loadPacketRecord(var_8_1, function(arg_9_0, arg_9_1)
									local var_9_0 = arg_9_1.log_list
									local var_9_1 = {
										players = var_9_0,
										id = var_6_7.id
									}

									xyd.WindowManager.get():openWindow("packet_record", var_9_1)
								end)

								return
							end

							if arg_8_1.packet_info and arg_6_0:isPacketExpired(arg_8_1.packet_info.time) then
								local var_8_2 = {
									message = var_0_2:translation("PACKET_EXPIRED")
								}

								xyd.WindowManager.get():openWindow("toast", var_8_2)

								return
							end

							local var_8_3 = {}

							if arg_8_1.packet_info then
								var_8_3.packetID = arg_8_1.packet_info.packet_id
								var_8_3.container = var_6_5
								var_8_3.id = arg_8_1.packet_info.id

								xyd.WindowManager.get():openWindow("grab_packet_result", var_8_3)
							end
						end
					end)
				end
			end)
		end

		var_6_1:setItemSize(var_6_3, var_6_4)
		var_6_1:addContent(var_6_2)

		return var_6_1
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_6_2 then
		arg_6_0.leftListItems[arg_6_3]:removeFromParent(false)
	end
end

function var_0_0.updateRightList(arg_10_0)
	arg_10_0.rightList:removeAllItems()

	arg_10_0.rightListItems = nil
	arg_10_0.rightListItems = {}

	local var_10_0 = xyd.tables.luckyPacket:getItemMaxNum()

	for iter_10_0 = 1, var_10_0 do
		local var_10_1 = display.newNode()
		local var_10_2 = arg_10_0.rightList:newItem()
		local var_10_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/lucky_packet/right_item.csb")
		local var_10_4 = var_10_3:getChildByName("container")

		arg_10_0:initRightListCell(var_10_4, iter_10_0)
		var_10_3:addTo(var_10_1)
		var_10_3:setAnchorPoint(cc.p(0, 0))
		table.insert(arg_10_0.rightListItems, var_10_4)
		var_10_1:setContentSize(var_10_4:getContentSize())
		var_10_2:addContent(var_10_1)
		var_10_2:setItemSize(var_10_4:getWidth(), var_10_4:getHeight() + 10)
		arg_10_0.rightList:addItem(var_10_2)
	end

	arg_10_0.rightList:reload()

	if arg_10_0.rightScrollNodeY then
		arg_10_0.rightList:getScrollNode():setPositionY(arg_10_0.rightScrollNodeY)
	end
end

function var_0_0.initRightListCell(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_0.luckyPacket:getSelfState()[arg_11_2]
	local var_11_1 = arg_11_0.luckyPacket:getLastPacketList()[arg_11_2]
	local var_11_2 = arg_11_1:getChildByName("packet_num_txt")
	local var_11_3 = arg_11_1:getChildByName("crystal_num_txt")
	local var_11_4 = arg_11_1:getChildByName("charge_num_txt")
	local var_11_5 = string.format(var_0_2:translation("LUCKY_PACKET_NUM_TIP"), xyd.tables.luckyPacket:pacAmount(arg_11_2))
	local var_11_6 = ""

	if var_11_0 == var_0_3.NO_SEND then
		var_11_6 = string.format(var_0_2:translation("LUCKY_PACKET_CHARGE_TIP2"), xyd.tables.luckyPacket:amount(arg_11_2))
	elseif var_11_0 == var_0_3.CAN_SEND then
		var_11_6 = var_0_2:translation("LUCKY_PACKET_CAN_SEND")
	else
		var_11_6 = string.format(var_0_2:translation("LUCKY_PACKET_CHARGE_TIP"), xyd.tables.luckyPacket:amount(arg_11_2))
	end

	var_11_2:setString(var_11_5)
	var_11_3:setString(xyd.tables.luckyPacket:pacMoney(arg_11_2))
	var_11_3:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	var_11_4:setString(var_11_6)
	arg_11_0:initItemBtn(var_11_0, arg_11_1, arg_11_2, var_11_1)
end

function var_0_0.initItemBtn(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4)
	local var_12_0 = arg_12_2:getChildByName("check_btn")
	local var_12_1 = arg_12_2:getChildByName("send_btn")
	local var_12_2 = var_12_1:getChildByName("send_txt")
	local var_12_3 = var_12_1:getChildByName("send_again_txt")
	local var_12_4 = var_12_1:getChildByName("charge_txt")

	var_12_0:setVisible(arg_12_1 == var_0_3.HAVE_SEND)
	var_12_2:setVisible(arg_12_1 == var_0_3.CAN_SEND)
	var_12_3:setVisible(arg_12_1 == var_0_3.HAVE_SEND)
	var_12_4:setVisible(arg_12_1 == var_0_3.NO_SEND)
	var_12_0:addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended and arg_12_4 > 0 then
			local var_13_0 = {
				packet_id = arg_12_4
			}

			arg_12_0.luckyPacket:loadPacketRecord(var_13_0, function(arg_14_0, arg_14_1)
				local var_14_0 = arg_14_1.log_list
				local var_14_1 = {
					players = var_14_0,
					id = arg_12_3
				}

				xyd.WindowManager.get():openWindow("packet_record", var_14_1)
			end)
		end
	end)
	var_12_1:addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			if arg_12_1 == var_0_3.NO_SEND then
				xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
			end

			if arg_12_1 == var_0_3.CAN_SEND then
				local var_15_0 = {
					idx = arg_12_3
				}

				xyd.WindowManager.get():openWindow("send_packet", var_15_0)
			end

			if arg_12_1 == var_0_3.HAVE_SEND then
				xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
			end
		end
	end)
end

function var_0_0.rechargeUpdate_(arg_16_0, arg_16_1)
	arg_16_0.luckyPacket:loadPacketInfo(nil, function(arg_17_0)
		if arg_17_0 == xyd.error.OK then
			arg_16_0.rightScrollNodeY = arg_16_0.rightList:getScrollNode():getPositionY()

			arg_16_0:updateRightList()
		end
	end)
end

function var_0_0.updateRightListItem(arg_18_0, arg_18_1)
	arg_18_0:initRightListCell(arg_18_0.rightListItems[arg_18_1], arg_18_1)
end

function var_0_0.createLabel(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	local var_19_0 = {
		color = arg_19_1,
		size = arg_19_2
	}
	local var_19_1 = xyd.AssetLoader.get():loadLabel(var_19_0)

	if arg_19_3 then
		var_19_1:setMaxLineWidth(arg_19_3)
	end

	return var_19_1
end

function var_0_0.addPacketMessage(arg_20_0, arg_20_1)
	if #arg_20_0.leftListItems == xyd.tables.misc.luckyPacketsShowMaxNum then
		table.remove(arg_20_0.leftListItems, 1):release()
	end

	table.insert(arg_20_0.leftListItems, arg_20_1)
	arg_20_1:retain()
end

function var_0_0.createLeftContent(arg_21_0, arg_21_1)
	local var_21_0 = display.newNode()
	local var_21_1
	local var_21_2

	var_21_0.luckyPacket = arg_21_1
	var_21_0.type = arg_21_1.type

	if arg_21_1.type == var_0_4.SEND then
		var_21_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/lucky_packet/lucky_packet_begin.csb")

		local var_21_3 = var_21_1:getChildByName("container")
		local var_21_4 = var_21_3:getChildByName("qiang_bg_mask")

		var_21_4:setLocalZOrder(99)
		var_21_4:setVisible(false)

		local var_21_5, var_21_6 = var_21_3:getChildByName("grab_txt_pos"):getPosition()
		local var_21_7 = var_21_3:getChildByName("open_state")
		local var_21_8 = var_21_3:getChildByName("close_state")
		local var_21_9, var_21_10 = var_21_3:getChildByName("desc_pos"):getPosition()

		arg_21_0:showAvatarAndName(var_21_3, arg_21_1.avatar_id, arg_21_1.player_name, arg_21_1.avatar_frame_id)

		local var_21_11 = arg_21_0:isPacketOpen(arg_21_1.grab_players)
		local var_21_12 = arg_21_0:isGrabAll(arg_21_1.grab_players, arg_21_1.id)
		local var_21_13 = arg_21_0:createLabel(cc.c3b(242, 151, 75), 24)

		var_21_13:addTo(var_21_3)
		var_21_13:setName("desc_label")
		var_21_13:setAnchorPoint(cc.p(0.5, 0.5))
		var_21_13:setPosition(var_21_5, var_21_6)

		if not var_21_11 and not var_21_12 then
			var_21_13:setString(var_0_2:translation("OPEN_PACKET"))
			var_21_13:setColor(cc.c3b(242, 151, 75))
		else
			var_21_13:setString(var_0_2:translation("CHECK_PACKET"))
			var_21_13:setColor(cc.c3b(241, 235, 7))
		end

		var_21_13:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

		if var_21_11 or var_21_12 then
			var_21_7:setVisible(true)
			var_21_8:setVisible(false)
		else
			var_21_7:setVisible(false)
			var_21_8:setVisible(true)
		end

		local var_21_14 = arg_21_0:createLabel(cc.c3b(255, 255, 255), 24, 190)

		var_21_14:addTo(var_21_3)
		var_21_14:setAnchorPoint(cc.p(0, 1))
		var_21_14:setPosition(var_21_9, var_21_10)
		var_21_14:setString(arg_21_1.content)
		var_21_0:setContentSize(var_21_3:getContentSize())
	elseif arg_21_1.type == var_0_4.FINISH then
		var_21_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/lucky_packet/lucky_packet_end.csb")

		local var_21_15 = var_21_1:getChildByName("container")

		var_21_0:setContentSize(var_21_15:getWidth(), var_21_15:getHeight() + 10)
		arg_21_0:layoutFinishLabel(var_21_15, arg_21_1)
	end

	var_21_0:addChild(var_21_1)
	var_21_1:setName("source")

	return var_21_0
end

function var_0_0.layoutFinishLabel(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = {}
	local var_22_1 = {
		arg_22_2.player_name .. var_0_2:translation("PACKET_FINISH_TIP1"),
		arg_22_0:buildTimeStr(arg_22_2.offset_time),
		var_0_2:translation("PACKET_FINISH_TIP2"),
		arg_22_2.lucky_player,
		(var_0_2:translation("PACKET_FINISH_TIP3"))
	}

	for iter_22_0 = 1, 5 do
		var_22_0[iter_22_0] = arg_22_1:getChildByName("label" .. iter_22_0)

		var_22_0[iter_22_0]:setString(var_22_1[iter_22_0])

		if iter_22_0 ~= 1 and iter_22_0 ~= 4 then
			var_22_0[iter_22_0]:setPositionX(var_22_0[iter_22_0 - 1]:getPositionX() + var_22_0[iter_22_0 - 1]:getWidth() + 1)
		end
	end
end

function var_0_0.buildTimeStr(arg_23_0, arg_23_1)
	local var_23_0 = {
		math.floor(arg_23_1 / 3600),
		math.floor(arg_23_1 % 3600 / 60),
		arg_23_1 % 3600 % 60
	}
	local var_23_1 = {
		var_0_2:translation("UNIT_HOUR"),
		var_0_2:translation("UNIT_MINUTE"),
		(var_0_2:translation("UNIT_SECOND"))
	}
	local var_23_2 = ""

	for iter_23_0, iter_23_1 in ipairs(var_23_0) do
		iter_23_1 = iter_23_1 == 0 and "" or iter_23_1 .. var_23_1[iter_23_0]

		if iter_23_1 and iter_23_1 ~= "" then
			var_23_2 = var_23_2 .. iter_23_1
		end
	end

	return var_23_2
end

function var_0_0.updatePacketList(arg_24_0, arg_24_1)
	local var_24_0 = arg_24_1.params.msg

	arg_24_0:addPacketMessage(arg_24_0:createLeftContent(var_24_0))
	arg_24_0:leftListScrollToEnd()
end

function var_0_0.leftListScrollToEnd(arg_25_0)
	arg_25_0.leftList:reload()

	local var_25_0 = arg_25_0:getPacketMessageHeight()
	local var_25_1 = arg_25_0.leftList:getViewRectInWorldSpace()
	local var_25_2 = 0

	if var_25_0 > var_25_1.height then
		var_25_2 = var_25_0 - var_25_1.height
	end

	local var_25_3 = arg_25_0.leftList:getScrollNode()

	var_25_3:setPositionY(var_25_3:getPositionY() + var_25_2)
end

function var_0_0.getPacketMessageHeight(arg_26_0)
	local var_26_0 = 0

	for iter_26_0, iter_26_1 in pairs(arg_26_0.leftListItems) do
		var_26_0 = var_26_0 + iter_26_1:getHeight()
	end

	return var_26_0
end

function var_0_0.isPacketOpen(arg_27_0, arg_27_1)
	if not arg_27_1 then
		return false
	end

	for iter_27_0, iter_27_1 in pairs(arg_27_1) do
		if iter_27_1 == arg_27_0.selfPlayer.playerID then
			return true
		end
	end

	return false
end

function var_0_0.isGrabAll(arg_28_0, arg_28_1, arg_28_2)
	if not arg_28_1 or not next(arg_28_1) then
		return false
	end

	if xyd.tables.luckyPacket:pacAmount(tonumber(arg_28_2)) <= #arg_28_1 then
		return true
	end

	return false
end

function var_0_0.scrollListener(arg_29_0, arg_29_1)
	if arg_29_1.name == "began" then
		arg_29_0.scrollViewMoved_ = false
		arg_29_0.prevY_ = arg_29_1.y
	elseif arg_29_1.name == "moved" and 10 <= math.abs(arg_29_1.y - arg_29_0.prevY_) then
		arg_29_0.scrollViewMoved_ = true
	end
end

function var_0_0.isPacketExpired(arg_30_0, arg_30_1)
	if xyd.ServerTime.get():getServerTime() - arg_30_1 > xyd.tables.misc.luckyPacketsExpireTime then
		return true
	end

	return false
end

function var_0_0.showAvatarAndName(arg_31_0, arg_31_1, arg_31_2, arg_31_3, arg_31_4)
	local var_31_0, var_31_1 = arg_31_1:getChildByName("avatar_pos"):getPosition()
	local var_31_2, var_31_3 = arg_31_1:getChildByName("name_pos"):getPosition()

	arg_31_1:getChildByName("avatar_kuang"):setVisible(false)

	local var_31_4 = display.newNode()

	var_31_4:setContentSize(90, 90)
	var_31_4:setPosition(var_31_0, var_31_1)
	var_31_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_31_4:addTo(arg_31_1)

	local var_31_5 = {
		avatar_id = arg_31_2,
		avatar_frame_id = arg_31_4
	}

	xyd.setPlayerAvatar(var_31_4, var_31_5)

	local var_31_6 = {
		size = 22,
		color = cc.c3b(255, 255, 255)
	}
	local var_31_7 = xyd.AssetLoader.get():loadLabel(var_31_6)

	var_31_7:addTo(arg_31_1)
	var_31_7:setPosition(var_31_2, var_31_3)
	var_31_7:setAnchorPoint(cc.p(0.5, 0.5))
	var_31_7:setString(arg_31_3)
end

function var_0_0.packetFinishRefresh(arg_32_0, arg_32_1)
	for iter_32_0, iter_32_1 in ipairs(arg_32_0.leftListItems) do
		local var_32_0 = arg_32_1.params.msg
		local var_32_1 = iter_32_1.luckyPacket

		if var_32_0.packet_id == var_32_1.packet_id then
			local var_32_2 = iter_32_1:getChildByName("source"):getChildByName("container"):getChildByName("desc_label")

			var_32_2:setString(var_0_2:translation("CHECK_PACKET"))
			var_32_2:setColor(cc.c3b(241, 235, 7))
		end
	end
end

return var_0_0
