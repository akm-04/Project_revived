local var_0_0 = class("LvbuWorldCampusResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.misc.activityLvbuFengxianAddRate

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.lvbuFestival = xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL)
	arg_1_0.items = {}
	arg_1_0.lastHeight = 0
end

function var_0_0.getBattleResult(arg_2_0)
	arg_2_0.lvbuFestival:battle({}, function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			arg_2_0.records = arg_3_1.battle_result
			arg_2_0.dollars = arg_3_1.dollars
			arg_2_0.wins = arg_3_1.wins

			if arg_2_0 and not tolua.isnull(arg_2_0) then
				arg_2_0:updateRecordList()
			end
		elseif arg_2_0.blockLayer_ then
			arg_2_0.blockLayer_:removeSelf()
			arg_2_0:addBlockLayer()
		end
	end)
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	arg_4_0:getBattleResult()
	arg_4_0:nodeByName("end_pos"):setVisible(false)
	arg_4_0:nodeByName("on_battling_text"):setVisible(true)
	arg_4_0:nodeByName("battle_over_text"):setVisible(false)

	arg_4_0.container = arg_4_0:nodeByName("inner")

	local var_4_0 = arg_4_0.container:getContentSize()

	arg_4_0.recordList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.container):onScroll(handler(arg_4_0, arg_4_0.scrollListener)):setTouchType(true):pos(0, 0)

	arg_4_0.recordList_:setDelegate(handler(arg_4_0, arg_4_0.recordListDelegate))
	arg_4_0.recordList_:reload()
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	arg_5_0:addBlockLayer(nil, true)
end

function var_0_0.recordListDelegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return #arg_6_0.items
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0 = arg_6_0.recordList_:dequeueItem()

		if not var_6_0 then
			var_6_0 = arg_6_0.recordList_:newItem()
		else
			var_6_0:removeAllChildren(true)
		end

		local var_6_1 = arg_6_0.items[arg_6_3]
		local var_6_2 = var_6_1:getWidth()
		local var_6_3 = var_6_1:getHeight()

		var_6_0:setItemSize(var_6_2, var_6_3)
		var_6_0:addContent(var_6_1)

		return var_6_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_6_2 then
		arg_6_0.items[arg_6_3]:removeFromParent(false)
	end
end

function var_0_0.updateRecordList(arg_7_0)
	arg_7_0:nodeByName("result_desc_txt1"):setString(var_0_2:translation("LVBU_CAMPUS_RESULT_TEXT1"))

	local var_7_0 = arg_7_0.selfPlayer:getHeroIgnoreAwaken(xyd.tables.misc:getValue("lvbu_up_table_id"))
	local var_7_1 = 0

	if var_7_0 then
		var_7_1 = var_0_3[var_7_0:getStar()] or 0
	end

	local var_7_2 = arg_7_0.dollars * (1 / (1 + var_7_1))
	local var_7_3 = arg_7_0.dollars - var_7_2
	local var_7_4 = string.format(var_0_2:translation("LVBU_CAMPUS_RESULT_TEXT2"), arg_7_0.wins, xyd.tables.lvbuMatch:name(arg_7_0.wins), var_7_2)

	arg_7_0:nodeByName("result_desc_txt2"):setString(var_7_4)

	if var_7_3 > 0 then
		local var_7_5 = "+" .. string.format(var_0_2:translation("LVBU_CAMPUS_RESULT_TEXT3"), var_7_3, math.ceil(var_7_1 * 100))

		arg_7_0:nodeByName("result_desc_txt3"):setString(var_7_5)
	else
		arg_7_0:nodeByName("result_desc_txt3"):setString("")
	end

	if arg_7_0.handle then
		var_0_1.unscheduleGlobal(arg_7_0.handle)

		arg_7_0.handle = nil
	end

	if not arg_7_0.records or not next(arg_7_0.records) then
		return
	end

	arg_7_0.recordList_:removeAllItems()

	local var_7_6 = 1

	arg_7_0:addItem(1)
end

function var_0_0.addItem(arg_8_0)
	for iter_8_0 = 1, #arg_8_0.records do
		local var_8_0 = arg_8_0:createBattleResultItem(arg_8_0.records[iter_8_0], iter_8_0)

		var_8_0:retain()
		table.insert(arg_8_0.items, var_8_0)
	end

	arg_8_0.recordList_:reload()
	arg_8_0:scrollToEnd()
end

function var_0_0.createBattleResultItem(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = display.newNode()
	local var_9_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/lvbu/campus_result/result_item.csb")
	local var_9_2 = var_9_1:getChildByName("container")

	var_9_2:getChildByName("title_bg"):getChildByName("round_txt"):setString(string.format(var_0_2:translation("SUPER_ARENA_TITLE"), arg_9_2))

	local var_9_3 = var_9_2:getChildByName("sub_container1")
	local var_9_4 = {
		avatar_id = arg_9_0.selfPlayer:getMyCurrentAvatarID(),
		avatar_frame_id = arg_9_0.selfPlayer.avatarFrame
	}

	xyd.setPlayerAvatar(var_9_3:getChildByName("avatar"), var_9_4)
	var_9_3:getChildByName("text_player_name"):setString(arg_9_0.selfPlayer.playerName)

	if arg_9_0.selfPlayer.conquerLev and arg_9_0.selfPlayer.conquerLev > 0 then
		var_9_3:getChildByName("text_level"):setString(arg_9_0.selfPlayer.conquerLev)
		var_9_3:getChildByName("lv"):setVisible(false)
		xyd.setConquerLev(arg_9_0.selfPlayer.conquerLev, var_9_3:getChildByName("text_level"), var_9_3:getChildByName("conquer_lev"), nil, nil, nil, nil, arg_9_0.selfPlayer.conquerLoopID)
	else
		var_9_3:getChildByName("text_level"):setString(arg_9_0.selfPlayer.lev)
		var_9_3:getChildByName("conquer_lev"):setVisible(false)
	end

	if arg_9_1.star > 0 then
		var_9_3:getChildByName("win"):setVisible(true)
		var_9_3:getChildByName("lose"):setVisible(false)
		var_9_3:getChildByName("cup"):setVisible(true)
		var_9_3:getChildByName("result_text"):setString(var_0_2:translation("LVBU_WIN_TEXT"))
	else
		var_9_3:getChildByName("win"):setVisible(false)
		var_9_3:getChildByName("lose"):setVisible(true)
		var_9_3:getChildByName("cup"):setVisible(false)
		var_9_3:getChildByName("result_text"):setString(var_0_2:translation("LVBU_LOSE_TEXT"))
	end

	var_9_3:getChildByName("result_text"):enableOutline(cc.c4b(121, 41, 28, 255), 2)

	local var_9_5 = var_9_2:getChildByName("sub_container2")
	local var_9_6 = {
		avatar_id = arg_9_1.avatar_id,
		avatar_frame_id = arg_9_1.avatar_frame_id
	}

	xyd.setPlayerAvatar(var_9_5:getChildByName("avatar"), var_9_6)
	var_9_5:getChildByName("text_player_name"):setString(arg_9_1.player_name)

	if arg_9_1.conquer_lev and arg_9_1.conquer_lev > 0 then
		var_9_5:getChildByName("text_level"):setString(arg_9_1.conquer_lev)
		var_9_5:getChildByName("lv"):setVisible(false)
		xyd.setConquerLev(arg_9_1.conquer_lev, var_9_5:getChildByName("text_level"), var_9_5:getChildByName("conquer_lev"), nil, nil, nil, nil, arg_9_1.conquer_loop_id)
	else
		var_9_5:getChildByName("text_level"):setString(arg_9_1.lev)
		var_9_5:getChildByName("conquer_lev"):setVisible(false)
	end

	if arg_9_1.star == 0 then
		var_9_5:getChildByName("win"):setVisible(true)
		var_9_5:getChildByName("lose"):setVisible(false)
		var_9_5:getChildByName("cup"):setVisible(true)
		var_9_5:getChildByName("result_text"):setString(var_0_2:translation("LVBU_WIN_TEXT"))
	else
		var_9_5:getChildByName("win"):setVisible(false)
		var_9_5:getChildByName("lose"):setVisible(true)
		var_9_5:getChildByName("cup"):setVisible(false)
		var_9_5:getChildByName("result_text"):setString(var_0_2:translation("LVBU_LOSE_TEXT"))
	end

	var_9_5:getChildByName("result_text"):enableOutline(cc.c4b(121, 41, 28, 255), 2)
	var_9_1:addTo(var_9_0)
	var_9_1:setAnchorPoint(cc.p(0, 0))
	var_9_0:setContentSize(var_9_2:getContentSize())
	var_9_1:setName("source")

	return var_9_0
end

function var_0_0.scrollToEnd(arg_10_0)
	local var_10_0 = arg_10_0:getItemsHeight()
	local var_10_1 = arg_10_0.recordList_:getViewRectInWorldSpace()
	local var_10_2 = 0

	if var_10_0 >= var_10_1.height then
		var_10_2 = var_10_0 - var_10_1.height
	end

	local var_10_3 = arg_10_0.recordList_:getScrollNode()

	var_10_3:setPositionY(var_10_3:getPositionY() + arg_10_0.lastHeight)
	var_10_3:runAction(cc.MoveBy:create(0.2 * #arg_10_0.records, cc.p(0, var_10_2 - arg_10_0.lastHeight)))

	arg_10_0.lastHeight = var_10_2
	arg_10_0.handle = var_0_1.scheduleGlobal(function()
		arg_10_0:nodeByName("end_pos"):setVisible(true)

		if arg_10_0.blockLayer_ then
			arg_10_0.blockLayer_:removeSelf()
		end

		arg_10_0:addBlockLayer()

		if arg_10_0.handle then
			var_0_1.unscheduleGlobal(arg_10_0.handle)

			arg_10_0.handle = nil
		end
	end, 0.5)
end

function var_0_0.getItemsHeight(arg_12_0)
	local var_12_0 = 0

	for iter_12_0 = 1, #arg_12_0.items do
		if arg_12_0.items[iter_12_0] then
			var_12_0 = var_12_0 + (arg_12_0.items[iter_12_0]:getContentSize().height or 0)
		end
	end

	return var_12_0
end

function var_0_0.scrollListener(arg_13_0, arg_13_1)
	if arg_13_1.name == "began" then
		arg_13_0.scrollViewMoved_ = false
		arg_13_0.prevX_ = arg_13_1.x
	elseif arg_13_1.name == "moved" and 1 <= math.abs(arg_13_1.x - arg_13_0.prevX_) then
		arg_13_0.scrollViewMoved_ = true
	end
end

function var_0_0.didClose(arg_14_0, arg_14_1)
	if arg_14_0.handle then
		var_0_1.unscheduleGlobal(arg_14_0.handle)

		arg_14_0.handle = nil
	end
end

return var_0_0
