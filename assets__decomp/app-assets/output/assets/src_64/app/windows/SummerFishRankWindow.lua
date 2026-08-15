local var_0_0 = class("SummerFishRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.summer = xyd.ModelManager.get():loadModel(xyd.ModelType.SUMMER)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.rankInfo = arg_1_0.summer.fishingRankInfo
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	if not arg_3_0.rankInfo.self_rank then
		return
	end

	if not arg_3_0.rankInfo.self_rank.rank then
		arg_3_0.rankInfo.self_rank.rank = 0
	end

	if not arg_3_0.rankInfo.self_rank.total_point then
		arg_3_0.rankInfo.self_rank.total_point = 0
	end

	arg_3_0:nodeByName("text_title"):setString(var_0_1:translation("SUMMER_TEXT_2"))
	arg_3_0:nodeByName("myintegral_txt"):setString(arg_3_0.rankInfo.self_rank.total_point)

	if arg_3_0.rankInfo.self_rank.rank > 0 then
		arg_3_0:nodeByName("myrank_txt"):setString(arg_3_0.rankInfo.self_rank.rank)
	else
		arg_3_0:nodeByName("myrank_txt"):setString(var_0_1:translation("NO_RANK_TEXT"))
	end

	arg_3_0:nodeByName("myrank_text"):setString(var_0_1:translation("MYRANK_TEXT"))
	arg_3_0:nodeByName("myintegral_text"):setString(var_0_1:translation("MYINTEGRAL_TEXT"))

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
		return #arg_4_0.rankInfo.rank_list or {}
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
	local var_5_0 = arg_5_0.rankInfo.rank_list[arg_5_1]
	local var_5_1 = display.newNode()
	local var_5_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/summer/fish/rank_item.csb")
	local var_5_3 = var_5_2:getChildByName("container")
	local var_5_4 = var_5_0.player_info

	if var_5_4.conquer_lev and var_5_4.conquer_lev > 0 then
		var_5_3:getChildByName("lev_txt"):setString(var_5_4.conquer_lev)
		var_5_3:getChildByName("lv_bg"):setVisible(false)

		local var_5_5 = xyd.getLoopBy(var_5_4.conquer_lev, var_5_4.conquer_loop_id)

		if var_5_5 < 2 then
			var_5_5 = ""
		end

		var_5_3:getChildByName("conquer_lev"):setTexture("images/conquer_lev" .. var_5_5 .. ".png")
	else
		var_5_3:getChildByName("lev_txt"):setString(var_5_4.lev)
		var_5_3:getChildByName("conquer_lev"):setVisible(false)
	end

	local var_5_6 = {
		playerInfo = var_5_4,
		avatar_id = var_5_4.avatar_id,
		avatar_frame_id = var_5_4.avatar_frame_id
	}

	xyd.setPlayerAvatar(var_5_3:getChildByName("icon_container"), var_5_6)
	var_5_3:getChildByName("region_txt"):setString("S" .. tostring(var_5_4.region))
	var_5_3:getChildByName("name_txt"):setString(var_5_4.player_name)
	var_5_3:getChildByName("own_integral_txt"):setString(var_5_0.total_point)
	var_5_3:getChildByName("own_integral_text"):setString(var_0_1:translation("GET_POINT_TEXT"))

	var_5_0.rank = arg_5_1

	if var_5_0.rank <= 3 then
		var_5_3:getChildByName("rank_" .. arg_5_1):setVisible(true)
		var_5_3:getChildByName("rank_text"):setString("")
		var_5_3:getChildByName("bg_rank_" .. arg_5_1):setVisible(true)
	else
		var_5_3:getChildByName("rank_text"):setString(arg_5_1)
		var_5_3:getChildByName("rank_text"):enableOutline(cc.c3b(89, 138, 174), 3)
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
