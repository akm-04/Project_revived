local var_0_0 = class("SummerQuizRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.summer = xyd.ModelManager.get():loadModel(xyd.ModelType.SUMMER)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.rankInfos = arg_1_0.summer.quizRankInfo
	arg_1_0.daykeys = table.keys(arg_1_0.rankInfos)

	table.sort(arg_1_0.daykeys, function(arg_2_0, arg_2_1)
		return arg_2_0 < arg_2_1
	end)

	arg_1_0.currentShowIndex = #arg_1_0.daykeys
	arg_1_0.today = arg_1_0.summer.details.big_pass_info.day_count
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
	arg_3_0:addBlockLayer()
	arg_3_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("title_text"):setString(var_0_1:translation("SUMMER_TEXT_5"))
	arg_4_0:nodeByName("myrank_text"):setString(var_0_1:translation("MYRANK_TEXT"))
	arg_4_0:nodeByName("cost_time_text"):setString(var_0_1:translation("QUIZ_COST_TIME_TEXT"))

	arg_4_0.scroll = arg_4_0:nodeByName("rank_scroll")

	local var_4_0 = arg_4_0.scroll:getContentSize()

	arg_4_0.rankList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.rankList:setBounceable(true)
	arg_4_0.rankList:setDelegate(handler(arg_4_0, arg_4_0.rankListDelegate))
	arg_4_0.rankList:reload()
	arg_4_0:updateMyRankInfo()

	arg_4_0.dayScroll = arg_4_0:nodeByName("day_scroll")

	local var_4_1 = arg_4_0.dayScroll:getContentSize()

	arg_4_0.dayList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_1.width, var_4_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.dayScroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.dayList:setBounceable(true)
	arg_4_0.dayList:setDelegate(handler(arg_4_0, arg_4_0.dayListDelegate))
	arg_4_0.dayList:reload()
end

function var_0_0.updateMyRankInfo(arg_5_0)
	local var_5_0 = arg_5_0.rankInfos[tostring(arg_5_0.daykeys[arg_5_0.currentShowIndex])].self_rank

	if var_5_0.rank and var_5_0.rank > 0 then
		arg_5_0:nodeByName("myrank_txt"):setString(var_5_0.rank)

		local var_5_1 = math.floor(var_5_0.finish_time)
		local var_5_2 = math.floor((var_5_0.finish_time - var_5_1) * 100)

		if var_5_2 < 10 then
			var_5_2 = "0" .. var_5_2
		end

		arg_5_0:nodeByName("cost_time_txt"):setString(os.date("%M'%S''", var_5_1) .. tostring(var_5_2))
	else
		arg_5_0:nodeByName("myrank_txt"):setString(var_0_1:translation("NO_RANK_TEXT"))
		arg_5_0:nodeByName("cost_time_txt"):setString("")
	end
end

function var_0_0.rankListDelegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	arg_6_0.rankData = arg_6_0.rankInfos[tostring(arg_6_0.daykeys[arg_6_0.currentShowIndex])].rank_list

	if not arg_6_0.rankData.is_sorted then
		table.sort(arg_6_0.rankData, function(arg_7_0, arg_7_1)
			return arg_7_0.finish_time < arg_7_1.finish_time
		end)

		arg_6_0.rankData.is_sorted = true
	end

	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		if #arg_6_0.rankData == 0 then
			arg_6_0:nodeByName("no_rank_tip_txt"):setString(var_0_1:translation("QUIZ_NOT_OPEN_TEXT1"))
		else
			arg_6_0:nodeByName("no_rank_tip_txt"):setString("")
		end

		return #arg_6_0.rankData
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0
		local var_6_1 = arg_6_0.rankList:dequeueItem()

		if not var_6_1 then
			var_6_1 = arg_6_0.rankList:newItem()
		else
			var_6_1:removeAllChildren(true)
		end

		local var_6_2 = arg_6_0:createRankListContent(arg_6_3)
		local var_6_3 = var_6_2:getWidth()
		local var_6_4 = var_6_2:getHeight()

		var_6_1:setItemSize(var_6_3, var_6_4)
		var_6_1:addContent(var_6_2)

		return var_6_1
	end
end

function var_0_0.createRankListContent(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_0.rankData[arg_8_1]
	local var_8_1 = display.newNode()
	local var_8_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/summer/quiz/rank_item.csb")
	local var_8_3 = var_8_2:getChildByName("container")
	local var_8_4 = var_8_0.player_info
	local var_8_5 = {
		playerInfo = var_8_4,
		avatar_id = var_8_4.avatar_id,
		avatar_frame_id = var_8_4.avatar_frame_id
	}

	xyd.setPlayerAvatar(var_8_3:getChildByName("icon_container"), var_8_5)
	var_8_3:getChildByName("region_txt"):setString("S" .. tostring(var_8_4.region))
	var_8_3:getChildByName("name_txt"):setString(var_8_4.player_name)

	local var_8_6 = math.floor(var_8_0.finish_time)
	local var_8_7 = math.floor((var_8_0.finish_time - var_8_6) * 100)

	if var_8_7 < 10 then
		var_8_7 = "0" .. var_8_7
	end

	var_8_3:getChildByName("cost_time_txt"):setString(os.date("%M'%S''", var_8_6) .. tostring(var_8_7))
	var_8_3:getChildByName("cost_time_text"):setString(var_0_1:translation("QUIZ_COST_TIME_TEXT"))

	var_8_0.rank = arg_8_1

	if var_8_0.rank <= 3 then
		var_8_3:getChildByName("rank_" .. arg_8_1):setVisible(true)
		var_8_3:getChildByName("rank_text"):setString("")
		var_8_3:getChildByName("bg_rank_" .. arg_8_1):setVisible(true)
	else
		var_8_3:getChildByName("rank_text"):setString(arg_8_1)
		var_8_3:getChildByName("rank_text"):enableOutline(cc.c3b(89, 138, 174), 3)
	end

	var_8_2:addTo(var_8_1)
	var_8_2:setAnchorPoint(cc.p(0, 0))
	var_8_1:setContentSize(var_8_3:getContentSize())
	var_8_2:setName("source")

	return var_8_1
end

function var_0_0.dayListDelegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return #arg_9_0.daykeys
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_0
		local var_9_1 = arg_9_0.dayList:dequeueItem()

		if not var_9_1 then
			var_9_1 = arg_9_0.dayList:newItem()
		else
			var_9_1:removeAllChildren(true)
		end

		local var_9_2 = arg_9_0:createDayListContent(arg_9_3)
		local var_9_3 = var_9_2:getWidth()
		local var_9_4 = var_9_2:getHeight()

		var_9_1:setItemSize(var_9_3, var_9_4 + 5)
		var_9_1:addContent(var_9_2)

		return var_9_1
	end
end

function var_0_0.createDayListContent(arg_10_0, arg_10_1)
	local var_10_0 = display.newNode()
	local var_10_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/summer/quiz/day_item.csb")
	local var_10_2 = var_10_1:getChildByName("container")

	var_10_2:getChildByName("day_normal"):setTouchSwallowEnabled(false)
	var_10_2:getChildByName("day_click"):setTouchSwallowEnabled(false)
	var_10_2:getChildByName("day_normal"):getChildByName("txt"):setString(string.format(var_0_1:translation("WAR_CAMP_DAY_TXT"), var_0_1:translation("NUM_" .. arg_10_1)))
	var_10_2:getChildByName("day_click"):getChildByName("txt"):setString(string.format(var_0_1:translation("WAR_CAMP_DAY_TXT"), var_0_1:translation("NUM_" .. arg_10_1)))

	if arg_10_1 == arg_10_0.currentShowIndex then
		var_10_2:getChildByName("day_normal"):setVisible(false)
		var_10_2:getChildByName("day_click"):setVisible(true)
		var_10_2:getChildByName("button"):setBrightStyle(ccui.BrightStyle.highlight)
		var_10_2:getChildByName("button"):setTouchEnabled(false)
	else
		var_10_2:getChildByName("day_normal"):setVisible(true)
		var_10_2:getChildByName("day_click"):setVisible(false)
		var_10_2:getChildByName("button"):setBrightStyle(ccui.BrightStyle.normal)
		var_10_2:getChildByName("button"):setTouchEnabled(true)
	end

	var_10_2:getChildByName("button"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_11_0, arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_10_0.currentShowIndex = arg_10_1

			arg_10_0.dayList:refreshList()
			arg_10_0.rankList:reload()
			arg_10_0:updateMyRankInfo()
		end
	end)
	var_10_1:addTo(var_10_0)
	var_10_1:setAnchorPoint(cc.p(0, 0))
	var_10_0:setContentSize(var_10_2:getContentSize())
	var_10_1:setName("source")

	return var_10_0
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevY_ = arg_12_1.y
	elseif arg_12_1.name == "moved" and 5 <= math.abs(arg_12_1.y - arg_12_0.prevY_) then
		arg_12_0.scrollViewMoved_ = true
	end
end

return var_0_0
