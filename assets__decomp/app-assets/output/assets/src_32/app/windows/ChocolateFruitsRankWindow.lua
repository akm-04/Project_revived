local var_0_0 = class("ChocolateFruitsRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 1
local var_0_3 = 2

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.chocolate = xyd.ModelManager.get():loadModel(xyd.ModelType.CHOCOLATE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.rankInfo = arg_1_2.data
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	if not arg_3_0.rankInfo.self_info then
		return
	end

	if not arg_3_0.rankInfo.self_info.rank then
		arg_3_0.rankInfo.self_info.rank = 0
	end

	if not arg_3_0.rankInfo.self_info.total_point then
		arg_3_0.rankInfo.self_info.total_point = 0
	end

	if arg_3_0.rankInfo.self_info.rank > 0 then
		arg_3_0:nodeByName("myrank_txt"):setString(arg_3_0.rankInfo.self_info.rank)
	else
		arg_3_0:nodeByName("myrank_txt"):setString(var_0_1:translation("NO_RANK_TEXT"))
	end

	arg_3_0:nodeByName("myrank_text"):setString(var_0_1:translation("MYRANK_TEXT"))
	arg_3_0:nodeByName("myintegral_text"):setString(var_0_1:translation("THIRD_ANNI_WORD_RANK_TXT1"))
	arg_3_0:nodeByName("myintegral_txt"):setString(arg_3_0.rankInfo.self_info.score)

	arg_3_0.scroll = arg_3_0:nodeByName("scroll")

	local var_3_0 = arg_3_0.scroll:getContentSize()

	arg_3_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.scrollList:setBounceable(true)
	arg_3_0.scrollList:setDelegate(handler(arg_3_0, arg_3_0.scrollListDelegate))
	arg_3_0.scrollList:reload()
end

function var_0_0.scrollListDelegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #arg_4_0.rankInfo.rank_info or {}
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0
		local var_4_1 = arg_4_0.scrollList:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.scrollList:newItem()
		else
			var_4_1:removeAllChildren(true)
		end

		local var_4_2 = arg_4_0:createListContent(arg_4_3)
		local var_4_3 = var_4_2:getWidth()
		local var_4_4 = var_4_2:getHeight()

		var_4_1:setItemSize(var_4_3, var_4_4)
		var_4_1:addContent(var_4_2)

		return var_4_1
	end
end

function var_0_0.createListContent(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0.rankInfo.rank_info[arg_5_1]
	local var_5_1 = display.newNode()
	local var_5_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/chocolate/rule/rank_item.csb")
	local var_5_3 = var_5_2:getChildByName("container")
	local var_5_4 = var_5_0

	if var_5_4.conquer_lev and var_5_4.conquer_lev > 0 then
		xyd.setConquerLev(var_5_4.conquer_lev, var_5_3:getChildByName("lev_txt"), var_5_3:getChildByName("lv_bg"), nil, nil, nil, nil, var_5_4.conquer_loop_id)
	else
		var_5_3:getChildByName("lev_txt"):setString(var_5_4.lev)
	end

	local var_5_5 = {
		playerInfo = var_5_4,
		avatar_id = var_5_4.avatar_id,
		avatar_frame_id = var_5_4.avatar_frame_id
	}

	xyd.setPlayerAvatar(var_5_3:getChildByName("icon_container"), var_5_5)

	if var_5_4.region then
		var_5_3:getChildByName("region_txt"):setString("S" .. tostring(var_5_4.region))
	else
		var_5_3:getChildByName("region_txt"):setString("S" .. tostring(xyd.getPlayerRegion(var_5_4.player_id)))
	end

	var_5_3:getChildByName("name_txt"):setString(var_5_4.player_name)
	var_5_3:getChildByName("own_integral_txt"):setString(var_5_0.score)
	var_5_3:getChildByName("own_integral_text"):setString(var_0_1:translation("JIFEN_TIP"))

	var_5_0.rank = arg_5_1

	var_5_3:getChildByName("1"):setVisible(false)
	var_5_3:getChildByName("2"):setVisible(false)
	var_5_3:getChildByName("3"):setVisible(false)
	var_5_3:getChildByName("rank_txt"):setVisible(false)
	var_5_3:getChildByName("bg_common"):setVisible(false)
	var_5_3:getChildByName("first_bg"):setVisible(false)
	var_5_3:getChildByName("second_bg"):setVisible(false)
	var_5_3:getChildByName("third_bg"):setVisible(false)
	var_5_3:getChildByName("rank_txt"):enableOutline(cc.c4b(121, 52, 52, 255), 3)

	if var_5_0.rank <= 3 then
		if var_5_0.rank == 1 then
			var_5_3:getChildByName("1"):setVisible(true)
			var_5_3:getChildByName("first_bg"):setVisible(true)
		elseif var_5_0.rank == 2 then
			var_5_3:getChildByName("2"):setVisible(true)
			var_5_3:getChildByName("second_bg"):setVisible(true)
		else
			var_5_3:getChildByName("3"):setVisible(true)
			var_5_3:getChildByName("third_bg"):setVisible(true)
		end
	else
		var_5_3:getChildByName("rank_txt"):setVisible(true)
		var_5_3:getChildByName("bg_common"):setVisible(true)
		var_5_3:getChildByName("rank_txt"):setString(var_5_0.rank)
	end

	var_5_2:addTo(var_5_1)
	var_5_2:setAnchorPoint(cc.p(0, 0))
	var_5_1:setContentSize(var_5_3:getContentSize())
	var_5_2:setName("source")

	return var_5_1
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevY_ = arg_6_1.y
	elseif arg_6_1.name == "moved" and 5 <= math.abs(arg_6_1.y - arg_6_0.prevY_) then
		arg_6_0.scrollViewMoved_ = true
	end
end

return var_0_0
