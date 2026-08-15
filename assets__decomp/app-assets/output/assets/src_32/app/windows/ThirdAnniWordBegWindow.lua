local var_0_0 = class("ThirdAnniWordBegWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.ThirdAnniversaryWord
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.scroll = arg_2_0:nodeByName("scroll")
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_2_0.thirdAnniModel = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_2_0.sendTimes = arg_2_0.thirdAnniModel.collectInfo.send_times
	arg_2_0.getTimes = arg_2_0.thirdAnniModel.collectInfo.get_times
	arg_2_0._type = arg_2_1._type
	arg_2_0.datas = arg_2_0.socialSystem.friendlist

	local var_2_0 = arg_2_0.scroll:getContentSize()

	arg_2_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_0.width, var_2_0.height),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):onScroll(handler(arg_2_0, arg_2_0.scrollListener)):addTo(arg_2_0.scroll)

	arg_2_0.scrollList:setBounceable(true)
	arg_2_0.scrollList:setDelegate(handler(arg_2_0, arg_2_0.delegate))

	if arg_2_0._type == "beg" then
		arg_2_0:nodeByName("title"):setString(var_0_2:translation("THIRD_ANNI_WORD_TITLE_BEG"))
		arg_2_0:nodeByName("send_time"):setString(string.format(var_0_2:translation("ACTIVITY_WORD_BEG_TIME"), arg_2_0.getTimes, var_0_3:getValue("activity_anniversary_word_get_limit")))
	else
		arg_2_0:nodeByName("title"):setString(var_0_2:translation("THIRD_ANNI_WORD_TITLE_SEND"))
		arg_2_0:nodeByName("send_time"):setString(string.format(var_0_2:translation("ACTIVITY_WORD_SEND_TIME"), arg_2_0.sendTimes, var_0_3:getValue("activity_anniversary_word_send_limit")))
	end

	arg_2_0:sortData()
	arg_2_0.scrollList:reload()
end

function var_0_0.sortData(arg_3_0)
	table.sort(arg_3_0.datas, function(arg_4_0, arg_4_1)
		local var_4_0 = xyd.db.newMessagesTime:getTime(arg_3_0.selfPlayer.playerID, arg_4_0.player_id)
		local var_4_1 = xyd.db.newMessagesTime:getTime(arg_3_0.selfPlayer.playerID, arg_4_1.player_id)

		if arg_4_0.is_online == arg_4_1.is_online and (var_4_0 > 0 or var_4_1 > 0) then
			return var_4_1 < var_4_0
		end

		if arg_4_0.is_online ~= arg_4_1.is_online then
			return arg_4_0.is_online > arg_4_1.is_online
		end

		local var_4_2 = xyd.db.newMessagesCount:getCount(arg_3_0.selfPlayer.playerID, arg_4_0.player_id)
		local var_4_3 = xyd.db.newMessagesCount:getCount(arg_3_0.selfPlayer.playerID, arg_4_1.player_id)

		if var_4_2 ~= var_4_3 then
			return var_4_3 <= var_4_2
		else
			return arg_4_0.last_time > arg_4_1.last_time
		end
	end)
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.scrollViewMoved_ = false
		arg_5_0.prevY_ = arg_5_1.y
	elseif arg_5_1.name == "moved" and 20 <= math.abs(arg_5_1.y - arg_5_0.prevY_) then
		arg_5_0.scrollViewMoved_ = true
	end
end

function var_0_0.delegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return #arg_6_0.datas
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0 = arg_6_0.scrollList:dequeueItem()

		if not var_6_0 then
			var_6_0 = arg_6_0.scrollList:newItem()
		else
			var_6_0:removeAllChildren(true)
		end

		local var_6_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary3rd/word_collection/beg/beg_item.csb")
		local var_6_2 = var_6_1:getChildByName("container")
		local var_6_3 = arg_6_0.datas[arg_6_3]
		local var_6_4 = var_6_2:getChildByName("info_container")
		local var_6_5 = {
			avatar_id = var_6_3.avatar_id,
			avatar_frame_id = var_6_3.avatar_frame_id
		}

		if var_6_3.is_online == 0 then
			var_6_5.isGray = true
		end

		var_6_5.playerInfo = var_6_3

		xyd.setPlayerAvatar(var_6_2:getChildByName("avtar_container"), var_6_5)

		if var_6_3.conquer_lev and var_6_3.conquer_lev > 0 then
			xyd.setConquerLev(var_6_3.conquer_lev, var_6_4:getChildByName("lev_txt"), var_6_4:getChildByName("lev1"), nil, false, 0.9, "lev2", var_6_3.conquer_loop_id)
		else
			var_6_4:getChildByName("lev_txt"):setString(var_6_3.lev)
			var_6_4:getChildByName("lev1"):setVisible(true)
		end

		var_6_4:getChildByName("name_txt"):setString(var_6_3.player_name)
		var_6_4:getChildByName("region_txt"):setString("S" .. xyd.getPlayerRegion(var_6_3.player_id))
		arg_6_0.socialSystem:setOnlineState(var_6_2:getChildByName("friend_state"), var_6_3)

		for iter_6_0 = 1, 5 do
			local var_6_6 = xyd.AssetLoader.get():loadSprite("windows/anniversary3rd/word_collection/icon" .. iter_6_0 .. ".png")
			local var_6_7 = 85 / var_6_6:getWidth()

			var_6_6:setScale(var_6_7)
			var_6_6:setAnchorPoint(cc.p(0.5, 0.5))
			var_6_6:addTo(var_6_2:getChildByName("item_pos"))
			var_6_6:setPosition(iter_6_0 * 95 - 95, 0)
			var_6_6:setTouchSwallowEnabled(false)
			var_6_6:setTouchEnabled(true)
			var_6_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
				if arg_7_0.name == "began" then
					var_6_6:setScale(0.9 * var_6_7)

					return true
				elseif arg_7_0.name == "moved" then
					var_6_6:setScale(var_6_7)
				elseif arg_7_0.name == "ended" then
					var_6_6:setScale(var_6_7)

					if arg_6_0.scrollViewMoved_ then
						return
					end

					if arg_6_0._type == "beg" then
						xyd.Backend.get():request(xyd.mid.THIRD_ANNI_WORD_BEG, {
							idx = iter_6_0,
							to_player = var_6_3.player_id
						}, function(arg_8_0, arg_8_1)
							if arg_8_0 == xyd.error.OK then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_2:translation("THIRD_ANNIVERSARY_WORD_TIP_2")
								})
							end
						end)
					elseif arg_6_0._type == "mercy" then
						if arg_6_0.selfPlayer:getBackpack():getItemNumByID(var_0_1:itemId(iter_6_0)) <= 0 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_2:translation("THIRD_ANNIVERSARY_WORD_TIP_1")
							})

							return
						end

						if arg_6_0.sendTimes >= var_0_3:getValue("activity_anniversary_word_send_limit") then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_2:translation("THIRD_ANNIVERSARY_WORD_TIP_4")
							})

							return
						end

						local var_7_0 = string.format(var_0_2:translation("THIRD_ANNIVERSARY_WORD_TIP_3"), var_0_1:word(iter_6_0), var_6_3.player_name)

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_7_0, function()
							xyd.Backend.get():request(xyd.mid.THIRD_ANNI_WORD_SEND, {
								idx = iter_6_0,
								to_player = var_6_3.player_id
							}, function(arg_10_0, arg_10_1)
								if arg_10_0 == xyd.error.OK then
									arg_6_0.selfPlayer:getBackpack():addItemsByID(var_0_1:itemId(iter_6_0), -1)

									arg_6_0.sendTimes = arg_10_1.send_times

									arg_6_0:nodeByName("send_time"):setString(string.format(var_0_2:translation("ACTIVITY_WORD_SEND_TIME"), arg_6_0.sendTimes, var_0_3:getValue("activity_anniversary_word_send_limit")))
								end
							end)
						end, nil, nil, xyd.ColorMode.ACTIVITY)
					end
				end
			end)
		end

		local var_6_8 = var_6_2:getContentSize()

		var_6_1:setAnchorPoint(cc.p(0, 0))
		var_6_1:setContentSize(var_6_8.width, var_6_8.height)
		var_6_0:setItemSize(var_6_8.width, var_6_8.height)
		var_6_0:addContent(var_6_1)

		return var_6_0
	end
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	arg_11_0:addBlockLayer()
end

function var_0_0.willClose(arg_12_0, arg_12_1)
	local var_12_0 = xyd.WindowManager.get():getWindow("third_anni_collection")

	if var_12_0 then
		var_12_0:updateItemNum()
	end

	arg_12_0.thirdAnniModel.collectInfo.send_times = arg_12_0.sendTimes
	arg_12_0.thirdAnniModel.collectInfo.get_times = arg_12_0.getTimes
end

return var_0_0
