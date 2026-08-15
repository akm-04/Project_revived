local var_0_0 = class("ThirdAnniWordDiaryWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.gift
local var_0_2 = xyd.tables.ThirdAnniversaryWord
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.thirdAnniModel = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_1_0.getTimes = arg_1_0.thirdAnniModel.collectInfo.get_times
	arg_1_0.sendTimes = arg_1_0.thirdAnniModel.collectInfo.send_times
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.scroll = arg_2_0:nodeByName("scroll")
	arg_2_0.begList = arg_2_1.beg_list
	arg_2_0.getList = arg_2_1.get_list
	arg_2_0.logList = arg_2_1.log_list
	arg_2_0.friends = arg_2_1.player_infos
	arg_2_0.log_ = {}

	local var_2_0 = arg_2_0.scroll:getContentSize()

	arg_2_0.scrollList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_2_0.width, var_2_0.height),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_2_0.scroll)

	arg_2_0.scrollList:setBounceable(true)

	arg_2_0.get_txt = arg_2_0:nodeByName("txt_get")

	arg_2_0.get_txt:setString(string.format(var_0_3:translation("ANNIVERSARY_GET_TIMES"), arg_2_0.getTimes, 10))

	for iter_2_0 = 1, #arg_2_0.getList do
		arg_2_0:updateListItem(iter_2_0, "get")
	end

	for iter_2_1 = 1, #arg_2_0.begList do
		arg_2_0:updateListItem(iter_2_1, "beg")
	end

	for iter_2_2 = 1, #arg_2_0.logList do
		arg_2_0:updateListItem(iter_2_2, "log")
	end

	arg_2_0.scrollList:reload()
end

function var_0_0.updateListItem(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0
	local var_3_1
	local var_3_2
	local var_3_3

	if arg_3_2 == "get" then
		var_3_0 = arg_3_0.getList[arg_3_1].player_id
		var_3_1 = arg_3_0.getList[arg_3_1].idx
	elseif arg_3_2 == "beg" then
		var_3_0 = arg_3_0.begList[arg_3_1].player_id
		var_3_1 = arg_3_0.begList[arg_3_1].idx
	else
		arg_3_0.log_[arg_3_1] = xyd.splitToNumber(arg_3_0.logList[arg_3_1], "|")
		var_3_0 = arg_3_0.log_[arg_3_1][1]
		var_3_1 = arg_3_0.log_[arg_3_1][2]
		unixTime = arg_3_0.log_[arg_3_1][3]
		var_3_3 = arg_3_0.log_[arg_3_1][4]
	end

	local var_3_4 = os.date("%x %X", unixTime)
	local var_3_5 = arg_3_0.friends[tostring(var_3_0)]
	local var_3_6 = arg_3_0.scrollList:newItem()
	local var_3_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary3rd/word_collection/diary/diary_item.csb")
	local var_3_8 = var_3_7:getChildByName("container")
	local var_3_9 = var_3_8:getChildByName("info_container")
	local var_3_10 = {
		avatar_id = var_3_5.avatar_id,
		avatar_frame_id = var_3_5.avatar_frame_id
	}

	var_3_10.isGray = false
	var_3_10.playerInfo = var_3_5

	xyd.setPlayerAvatar(var_3_8:getChildByName("avtar_container"), var_3_10)

	if var_3_5.conquer_lev and var_3_5.conquer_lev > 0 then
		var_3_9:getChildByName("lev1"):setVisible(false)
		xyd.setConquerLev(var_3_5.conquer_lev, var_3_9:getChildByName("lev_txt"), var_3_9:getChildByName("lev1"), nil, false, 0.9, "lev2", var_3_5.conquer_loop_id)
	else
		var_3_9:getChildByName("lev_txt"):setString(var_3_5.lev)
		var_3_9:getChildByName("lev2"):setVisible(false)
	end

	var_3_9:getChildByName("name_txt"):setString(var_3_5.player_name)

	local var_3_11 = var_3_8:getChildByName("send_btn")
	local var_3_12 = var_3_8:getChildByName("gift")
	local var_3_13 = var_3_8:getChildByName("desc")
	local var_3_14 = var_3_8:getChildByName("txt_get")
	local var_3_15 = var_3_8:getChildByName("time_txt")

	arg_3_0.get_txt:setString(string.format(var_0_3:translation("ANNIVERSARY_GET_TIMES"), arg_3_0.getTimes, 10))

	if arg_3_2 == "get" then
		var_3_12:setVisible(true)
		var_3_12:setTouchEnabled(true)
		var_3_13:setString(string.format(var_0_3:translation("THIRD_ANNIVERSARY_WORD_BEG"), var_0_2:word(var_3_1)))
		var_3_12:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
			if arg_4_0.name == "began" then
				var_3_12:setScale(0.9)

				return true
			elseif arg_4_0.name == "moved" then
				var_3_12:setScale(1)
			elseif arg_4_0.name == "ended" then
				var_3_12:setScale(1)

				if arg_3_0.getTimes >= var_0_4:getValue("activity_anniversary_word_get_limit") then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("THIRD_ANNIVERSARY_WORD_TIP_5")
					})

					return
				end

				xyd.Backend.get():request(xyd.mid.THIRD_ANNI_WORD_GET, {
					idx = var_3_1,
					from_player = var_3_5.player_id
				}, function(arg_5_0, arg_5_1)
					if arg_5_0 == xyd.error.OK then
						arg_3_0.selfPlayer:handleRewards(arg_5_1.awards)
						var_3_12:setVisible(false)
						var_3_8:getChildByName("gift_open"):setVisible(true)

						arg_3_0.getTimes = arg_5_1.get_times

						arg_3_0.get_txt:setString(string.format(var_0_3:translation("ANNIVERSARY_GET_TIMES"), arg_3_0.getTimes, 10))
					end
				end)
			end
		end)
	elseif arg_3_2 == "beg" then
		var_3_11:setVisible(true)
		var_3_13:setString(string.format(var_0_3:translation("THIRD_ANNIVERSARY_WORD_WISH"), var_0_2:word(var_3_1)))
		var_3_8:getChildByName("bg_diary_item2"):setVisible(true)
		var_3_11:addTouchEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.TouchEventType.ended then
				if arg_3_0.selfPlayer:getBackpack():getItemNumByID(var_0_2:itemId(var_3_1)) <= 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("THIRD_ANNIVERSARY_WORD_TIP_1")
					})

					return
				end

				if arg_3_0.sendTimes >= var_0_4:getValue("activity_anniversary_word_send_limit") then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("THIRD_ANNIVERSARY_WORD_TIP_4")
					})

					return
				end

				local var_6_0 = string.format(var_0_3:translation("THIRD_ANNIVERSARY_WORD_TIP_3"), var_0_2:word(var_3_1), var_3_5.player_name)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_0, function()
					xyd.Backend.get():request(xyd.mid.THIRD_ANNI_WORD_SEND, {
						idx = var_3_1,
						to_player = var_3_5.player_id
					}, function(arg_8_0, arg_8_1)
						if arg_8_0 == xyd.error.OK then
							arg_3_0.selfPlayer:getBackpack():addItemsByID(var_0_2:itemId(var_3_1), -1)
							var_3_11:setBright(false)
							var_3_11:setTouchEnabled(false)
							var_3_11:getChildByName("word_give"):setVisible(false)
							var_3_11:getChildByName("word_gave"):setVisible(true)

							arg_3_0.sendTimes = arg_8_1.send_times
						end
					end)
				end, nil, nil, arg_3_0.colorMode)
			end
		end)
	elseif var_3_3 == 1 then
		var_3_11:setVisible(true)
		var_3_13:setString(string.format(var_0_3:translation("THIRD_ANNIVERSARY_WORD_LOG"), var_0_2:word(var_3_1)))
		var_3_15:setString(var_3_4)
		var_3_11:setBright(false)
		var_3_11:setTouchEnabled(false)
		var_3_11:getChildByName("word_give"):setVisible(false)
		var_3_11:getChildByName("word_gave"):setVisible(true)
	elseif var_3_3 == 2 then
		var_3_12:setVisible(false)
		var_3_15:setString(var_3_4)
		var_3_8:getChildByName("gift_open"):setVisible(true)
		var_3_13:setString(string.format(var_0_3:translation("THIRD_ANNIVERSARY_WORD_BEG"), var_0_2:word(var_3_1)))
	end

	local var_3_16 = var_3_8:getContentSize()

	var_3_7:setAnchorPoint(cc.p(0, 0))
	var_3_7:setContentSize(var_3_16.width, var_3_16.height)
	var_3_6:setItemSize(var_3_16.width, var_3_16.height)
	var_3_6:addContent(var_3_7)
	arg_3_0.scrollList:addItem(var_3_6)
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	arg_9_0:addBlockLayer()
end

function var_0_0.willClose(arg_10_0, arg_10_1)
	local var_10_0 = xyd.WindowManager.get():getWindow("third_anni_collection")

	if var_10_0 then
		var_10_0:updateItemNum()
	end

	arg_10_0.thirdAnniModel.collectInfo.send_times = arg_10_0.sendTimes
	arg_10_0.thirdAnniModel.collectInfo.get_times = arg_10_0.getTimes
end

return var_0_0
