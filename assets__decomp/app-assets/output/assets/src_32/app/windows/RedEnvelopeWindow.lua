local var_0_0 = class("RedEnvelopeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = {
	FINISH = 2,
	SEND = 1
}
local var_0_4 = 285
local var_0_5 = 137

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.redEnvelope = xyd.ModelManager.get():loadModel(xyd.ModelType.RED_ENVELOPE)
end

function var_0_0.initLeftItems(arg_2_0)
	for iter_2_0, iter_2_1 in pairs(arg_2_0.redEnvelope:getRedEnvelopeList()) do
		local var_2_0 = arg_2_0:createLeftContent(iter_2_1)

		arg_2_0:addEnvelopeMessage(var_2_0)
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_0:nodeByName("close_btn")

	var_3_0:addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(var_3_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)

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
		viewRect = cc.rect(0, 0, 579, 405),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("right_list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))
	arg_3_0.leftListItems = {}
	arg_3_0.rightListItems = {}

	arg_3_0:initLeftItems()
	arg_3_0.leftList:setDelegate(handler(arg_3_0, arg_3_0.leftListDelegate))

	arg_3_0.rightScrollNodeY = nil
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:addBlockLayerWithNoTouchEvent()
	arg_5_0:updateRightList()
	arg_5_0:leftListScrollToEnd()
end

function var_0_0.didClose(arg_6_0)
	arg_6_0.leftList:removeAllItems()
end

function var_0_0.leftListDelegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return #arg_7_0.leftListItems
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_0
		local var_7_1 = arg_7_1:dequeueItem()

		if not var_7_1 then
			var_7_1 = arg_7_1:newItem()
		else
			var_7_1:removeAllChildren(false)
		end

		local var_7_2 = arg_7_0.leftListItems[arg_7_3]
		local var_7_3 = var_7_2:getWidth()
		local var_7_4 = var_7_2:getHeight()

		if var_7_2.type == var_0_3.SEND then
			local var_7_5 = var_7_2:getChildByName("source"):getChildByName("container")
			local var_7_6 = var_7_5:getChildByName("qiang_bg_mask")
			local var_7_7 = var_7_2.redEnvelope

			if var_7_5:getChildByName("click_node") then
				var_7_5:removeChildByName("click_node", true)
			end

			local var_7_8 = display.newNode()

			var_7_8:setContentSize(var_0_4, var_0_5)
			var_7_8:setAnchorPoint(cc.p(1, 0.5))
			var_7_8:setPosition(var_7_6:getPosition())
			var_7_8:addTo(var_7_5)
			var_7_8:setName("click_node")
			var_7_8:setLocalZOrder(100)
			var_7_8:setTouchEnabled(true)
			var_7_8:setTouchSwallowEnabled(false)
			var_7_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
				if arg_8_0.name == "began" then
					var_7_6:setVisible(true)

					return true
				elseif arg_8_0.name == "moved" then
					if arg_7_0.scrollViewMoved_ then
						var_7_6:setVisible(false)
					end

					return true
				elseif arg_8_0.name == "ended" and not arg_7_0.scrollViewMoved_ then
					var_7_6:setVisible(false)

					local function var_8_0(arg_9_0)
						if not arg_9_0 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_2:translation("RED_ENVELOP_QUESTION_ERROR_TIP")
							})

							return
						end

						local var_9_0 = {
							packet_id = var_7_7.packet_id
						}

						arg_7_0.redEnvelope:grabEnvelope(var_9_0, function(arg_10_0, arg_10_1)
							if arg_10_1.award_money then
								local var_10_0 = {
									crystal = arg_10_1.award_money,
									packetID = arg_10_1.packet_info.packet_id,
									container = var_7_5,
									id = arg_10_1.packet_info.id,
									awards = arg_10_1.awards
								}

								xyd.WindowManager.get():openWindow("grab_result", var_10_0)
							else
								if arg_10_1.packet_info and arg_7_0:isEnvelopeOpen(arg_10_1.packet_info.grab_players) then
									local var_10_1 = {
										packet_id = var_7_7.packet_id
									}

									arg_7_0.redEnvelope:loadEnvelopRecord(var_10_1, function(arg_11_0, arg_11_1)
										local var_11_0 = arg_11_1.log_list
										local var_11_1 = {
											players = var_11_0,
											id = var_7_7.id,
											num = arg_11_1.num
										}

										xyd.WindowManager.get():openWindow("envelope_record", var_11_1)
									end)

									return
								end

								if arg_10_1.packet_info and arg_7_0:isEnvelopeExpired(arg_10_1.packet_info.time) then
									local var_10_2 = {
										message = var_0_2:translation("ENVELOPE_EXPIRED")
									}

									xyd.WindowManager.get():openWindow("toast", var_10_2)

									return
								end

								local var_10_3 = {}

								if arg_10_1.packet_info then
									var_10_3.packetID = arg_10_1.packet_info.packet_id
									var_10_3.container = var_7_5
									var_10_3.id = arg_10_1.packet_info.id

									xyd.WindowManager.get():openWindow("grab_result", var_10_3)
								end
							end

							if arg_10_1.packet_info then
								var_7_2.redEnvelope = arg_10_1.packet_info
								var_7_7 = var_7_2.redEnvelope
							end
						end)
					end

					local var_8_1 = arg_7_0:isEnvelopeOpen(var_7_7.grab_players)
					local var_8_2 = arg_7_0:isGrabAll(var_7_7.grab_players, var_7_7.id)

					if arg_7_0:isEnvelopeExpired(var_7_7.time) then
						local var_8_3 = {
							message = var_0_2:translation("ENVELOPE_EXPIRED")
						}

						xyd.WindowManager.get():openWindow("toast", var_8_3)
					elseif not var_8_1 and not var_8_2 then
						xyd.WindowManager.get():openWindow("red_envelope_get", {
							content = var_7_7.content,
							callback = var_8_0
						})
					else
						var_8_0(true)
					end
				end
			end)
		end

		var_7_1:setItemSize(var_7_3, var_7_4)
		var_7_1:addContent(var_7_2)

		return var_7_1
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_7_2 then
		arg_7_0.leftListItems[arg_7_3]:removeFromParent(false)
	end
end

function var_0_0.updateRightList(arg_12_0)
	arg_12_0.rightList:removeAllItems()

	arg_12_0.rightListItems = nil
	arg_12_0.rightListItems = {}

	local var_12_0 = xyd.tables.redEnvelope:getItemMaxNum()

	for iter_12_0 = 1, var_12_0 do
		local var_12_1 = display.newNode()
		local var_12_2 = arg_12_0.rightList:newItem()
		local var_12_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/red_envelope/right_item.csb")
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
	local var_13_0 = arg_13_0.redEnvelope:getSelfState()[arg_13_2]
	local var_13_1 = arg_13_0.redEnvelope:getLastPacketList()[arg_13_2]
	local var_13_2 = arg_13_1:getChildByName("envelope_num_txt")
	local var_13_3 = arg_13_1:getChildByName("crystal_num_txt")
	local var_13_4 = arg_13_1:getChildByName("charge_num_txt")
	local var_13_5 = string.format(var_0_2:translation("RED_ENVELOPE_NUM_TIP"), xyd.tables.redEnvelope:pacAmount(arg_13_2))
	local var_13_6 = ""

	if var_13_0 <= 0 then
		var_13_6 = string.format(var_0_2:translation("RED_ENVELOPE_CHARGE_TIP2"), xyd.tables.redEnvelope:amount(arg_13_2))
	else
		var_13_6 = string.format(var_0_2:translation("RED_ENVELOPE_CAN_SEND"), var_13_0)
	end

	var_13_2:setString(var_13_5)
	var_13_3:setString(xyd.tables.redEnvelope:pacMoney(arg_13_2))
	var_13_3:setColor(cc.c3b(48, 228, 227))
	var_13_3:enableShadow(cc.c4b(0, 0, 0, 255), cc.size(1, -1), 2)
	var_13_4:setString(var_13_6)
	arg_13_0:initItemBtn(var_13_0, arg_13_1, arg_13_2, var_13_1)
end

function var_0_0.initItemBtn(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4)
	local var_14_0 = arg_14_2:getChildByName("check_btn")
	local var_14_1 = arg_14_2:getChildByName("send_btn")
	local var_14_2 = var_14_1:getChildByName("send_txt")
	local var_14_3 = var_14_1:getChildByName("charge_txt")

	var_14_0:setVisible(arg_14_4 > 0)
	var_14_2:setVisible(arg_14_1 > 0)
	var_14_3:setVisible(arg_14_1 <= 0)
	var_14_0:addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended and not arg_14_0.scrollViewMoved_ and arg_14_4 > 0 then
			local var_15_0 = {
				packet_id = arg_14_4
			}

			arg_14_0.redEnvelope:loadEnvelopRecord(var_15_0, function(arg_16_0, arg_16_1)
				local var_16_0 = arg_16_1.log_list
				local var_16_1 = {
					players = var_16_0,
					id = arg_14_3,
					num = arg_16_1.num
				}

				xyd.WindowManager.get():openWindow("envelope_record", var_16_1)
			end)
		end
	end)
	var_14_1:addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended and not arg_14_0.scrollViewMoved_ then
			if arg_14_1 <= 0 then
				xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
			end

			if arg_14_1 > 0 then
				local var_17_0 = {
					idx = arg_14_3,
					num = arg_14_1
				}

				xyd.WindowManager.get():openWindow("send_envelope", var_17_0)
			end
		end
	end)
end

function var_0_0.rechargeUpdate_(arg_18_0, arg_18_1)
	arg_18_0.redEnvelope:loadEnvelopeInfo(nil, function(arg_19_0)
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

function var_0_0.addEnvelopeMessage(arg_22_0, arg_22_1)
	if #arg_22_0.leftListItems == xyd.tables.misc.redEnvelopeShowMaxNum then
		table.remove(arg_22_0.leftListItems, 1):release()
	end

	table.insert(arg_22_0.leftListItems, arg_22_1)
	arg_22_1:retain()
end

function var_0_0.createLeftContent(arg_23_0, arg_23_1)
	local var_23_0 = display.newNode()
	local var_23_1
	local var_23_2

	var_23_0.redEnvelope = arg_23_1
	var_23_0.type = arg_23_1.type

	if arg_23_1.type == var_0_3.SEND then
		var_23_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/red_envelope/red_envelope_begin.csb")

		local var_23_3 = var_23_1:getChildByName("container")
		local var_23_4 = var_23_3:getChildByName("qiang_bg_mask")

		var_23_4:setLocalZOrder(99)
		var_23_4:setVisible(false)

		local var_23_5, var_23_6 = var_23_3:getChildByName("grab_txt_pos"):getPosition()
		local var_23_7 = var_23_3:getChildByName("open_state")
		local var_23_8 = var_23_3:getChildByName("close_state")
		local var_23_9, var_23_10 = var_23_3:getChildByName("desc_pos"):getPosition()

		arg_23_0:showAvatarAndName(var_23_3, arg_23_1)

		local var_23_11 = arg_23_0:isEnvelopeOpen(arg_23_1.grab_players)
		local var_23_12 = arg_23_0:isGrabAll(arg_23_1.grab_players, arg_23_1.id)
		local var_23_13 = arg_23_0:createLabel(cc.c3b(255, 255, 255), 24)

		var_23_13:addTo(var_23_3)
		var_23_13:setName("desc_label")
		var_23_13:setAnchorPoint(cc.p(0.5, 0.5))
		var_23_13:setPosition(var_23_5, var_23_6)

		if not var_23_11 and not var_23_12 then
			var_23_13:setString(var_0_2:translation("OPEN_ENVELOPE"))
			var_23_13:setColor(cc.c3b(255, 255, 255))
		else
			var_23_13:setString(var_0_2:translation("CHECK_ENVELOPE"))
			var_23_13:setColor(cc.c3b(255, 239, 64))
		end

		var_23_13:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

		if var_23_11 then
			var_23_7:setVisible(true)
			var_23_8:setVisible(false)
		else
			var_23_7:setVisible(false)
			var_23_8:setVisible(true)
		end

		local var_23_14 = arg_23_0:createLabel(cc.c3b(180, 30, 29), 24, 190)

		var_23_14:addTo(var_23_3)
		var_23_14:setAnchorPoint(cc.p(0, 1))
		var_23_14:setPosition(var_23_9, var_23_10)
		var_23_14:setString(var_0_2:translation("SEND_ENVELOPE_TEXT" .. arg_23_1.packet_id % 4 + 1))
		var_23_0:setContentSize(var_23_3:getContentSize())
	elseif arg_23_1.type == var_0_3.FINISH then
		var_23_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/red_envelope/red_envelope_end.csb")

		local var_23_15 = var_23_1:getChildByName("container")

		var_23_0:setContentSize(var_23_15:getWidth(), var_23_15:getHeight() + 10)
		arg_23_0:layoutFinishLabel(var_23_15, arg_23_1)
	end

	var_23_0:addChild(var_23_1)
	var_23_1:setName("source")

	return var_23_0
end

function var_0_0.layoutFinishLabel(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = {}
	local var_24_1 = {
		arg_24_2.player_name .. var_0_2:translation("ENVELOPE_FINISH_TIP1"),
		arg_24_0:buildTimeStr(arg_24_2.offset_time),
		var_0_2:translation("ENVELOPE_FINISH_TIP2"),
		arg_24_2.lucky_player,
		(var_0_2:translation("ENVELOPE_FINISH_TIP3"))
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
	if arg_25_1 < 1 then
		arg_25_1 = 1
	end

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

function var_0_0.updateEnvelopeList(arg_26_0, arg_26_1)
	local var_26_0 = arg_26_1.params.msg

	arg_26_0:addEnvelopeMessage(arg_26_0:createLeftContent(var_26_0))
	arg_26_0:leftListScrollToEnd()
end

function var_0_0.leftListScrollToEnd(arg_27_0)
	arg_27_0.leftList:reload()

	local var_27_0 = arg_27_0:getEnvelopeMessageHeight()
	local var_27_1 = arg_27_0.leftList:getViewRectInWorldSpace()
	local var_27_2 = 0

	if var_27_0 > var_27_1.height then
		var_27_2 = var_27_0 - var_27_1.height
	end

	local var_27_3 = arg_27_0.leftList:getScrollNode()

	var_27_3:setPositionY(var_27_3:getPositionY() + var_27_2)
end

function var_0_0.getEnvelopeMessageHeight(arg_28_0)
	local var_28_0 = 0

	for iter_28_0, iter_28_1 in pairs(arg_28_0.leftListItems) do
		var_28_0 = var_28_0 + iter_28_1:getHeight()
	end

	return var_28_0
end

function var_0_0.isEnvelopeOpen(arg_29_0, arg_29_1)
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

function var_0_0.isGrabAll(arg_30_0, arg_30_1, arg_30_2)
	if not arg_30_1 or not next(arg_30_1) then
		return false
	end

	if xyd.tables.redEnvelope:pacAmount(tonumber(arg_30_2)) <= #arg_30_1 then
		return true
	end

	return false
end

function var_0_0.scrollListener(arg_31_0, arg_31_1)
	if arg_31_1.name == "began" then
		arg_31_0.scrollViewMoved_ = false
		arg_31_0.prevY_ = arg_31_1.y
	elseif arg_31_1.name == "moved" and 10 <= math.abs(arg_31_1.y - arg_31_0.prevY_) then
		arg_31_0.scrollViewMoved_ = true
	end
end

function var_0_0.isEnvelopeExpired(arg_32_0, arg_32_1)
	if xyd.ServerTime.get():getServerTime() - arg_32_1 > xyd.tables.misc.redEnvelopeExpireTime then
		return true
	end

	return false
end

function var_0_0.showAvatarAndName(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0, var_33_1 = arg_33_1:getChildByName("avatar_pos"):getPosition()
	local var_33_2, var_33_3 = arg_33_1:getChildByName("name_pos"):getPosition()

	arg_33_1:getChildByName("avatar_kuang"):setVisible(false)

	local var_33_4 = display.newNode()

	var_33_4:setContentSize(90, 90)
	var_33_4:setPosition(var_33_0, var_33_1)
	var_33_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_33_4:addTo(arg_33_1)

	local var_33_5 = arg_33_2

	var_33_5.playerInfo = arg_33_2

	xyd.setPlayerAvatar(var_33_4, var_33_5)

	local var_33_6 = {
		size = 22,
		color = cc.c3b(255, 255, 255)
	}
	local var_33_7 = xyd.AssetLoader.get():loadLabel(var_33_6)

	var_33_7:addTo(arg_33_1)
	var_33_7:setPosition(var_33_2, var_33_3)
	var_33_7:setAnchorPoint(cc.p(0.5, 0.5))
	var_33_7:setString(arg_33_2.player_name)
end

function var_0_0.envelopeFinishRefresh(arg_34_0, arg_34_1)
	for iter_34_0, iter_34_1 in ipairs(arg_34_0.leftListItems) do
		local var_34_0 = arg_34_1.params.msg
		local var_34_1 = iter_34_1.redEnvelope

		if var_34_0.packet_id == var_34_1.packet_id then
			local var_34_2 = iter_34_1:getChildByName("source"):getChildByName("container"):getChildByName("desc_label")

			var_34_2:setString(var_0_2:translation("CHECK_ENVELOPE"))
			var_34_2:setColor(cc.c3b(241, 235, 7))
		end
	end
end

return var_0_0
