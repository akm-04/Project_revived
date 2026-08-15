local var_0_0 = class("SnowBallRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.snowBall = xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_BALL)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.rankInfo = arg_1_0.snowBall.rankInfo
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	if not arg_3_0.rankInfo.self_rank then
		return
	end

	arg_3_0:nodeByName("my_score"):setString(string.format(var_0_1:translation("SNOW_BALL_MY_SCORE"), arg_3_0.rankInfo.self_score))

	if arg_3_0.rankInfo.self_rank == 0 then
		arg_3_0:nodeByName("my_rank"):setVisible(false)
	else
		arg_3_0:nodeByName("my_rank"):setVisible(true)
		arg_3_0:nodeByName("my_rank"):setString(string.format(var_0_1:translation("SNOW_BALL_MY_RANK"), arg_3_0.rankInfo.self_rank))
	end

	local var_3_0 = cc.c4b(96, 145, 244, 255)

	arg_3_0:nodeByName("my_score"):enableOutline(var_3_0, 2)
	arg_3_0:nodeByName("my_rank"):enableOutline(var_3_0, 2)

	arg_3_0.scroll = arg_3_0:nodeByName("rank_list")

	local var_3_1 = arg_3_0.scroll:getContentSize()

	arg_3_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
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
		return #arg_4_0.rankInfo.list or {}
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
	local var_5_0 = arg_5_0.rankInfo.list[arg_5_1]
	local var_5_1 = display.newNode()
	local var_5_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/snow_ball/snow_ball_rank_item.csb")
	local var_5_3 = var_5_2:getChildByName("bg")
	local var_5_4 = var_5_0

	if var_5_4.conquer_lev and var_5_4.conquer_lev > 0 then
		var_5_3:getChildByName("lev_text"):setString(var_5_4.conquer_lev)
		var_5_3:getChildByName("level_bg"):setVisible(false)

		local var_5_5 = xyd.getLoopBy(var_5_4.conquer_lev, var_5_4.conquer_loop_id)

		if var_5_5 < 2 then
			var_5_5 = ""
		end

		var_5_3:getChildByName("conquer_lev_bg"):setTexture("images/conquer_lev" .. var_5_5 .. ".png")
	else
		var_5_3:getChildByName("lev_text"):setString(var_5_4.lev)
		var_5_3:getChildByName("conquer_lev_bg"):setVisible(false)
	end

	local var_5_6 = {
		playerInfo = var_5_4,
		avatar_id = var_5_4.avatar_id,
		avatar_frame_id = var_5_4.avatar_frame_id
	}

	xyd.setPlayerAvatar(var_5_3:getChildByName("icon_container"), var_5_6)
	var_5_3:getChildByName("region"):setString("S" .. tostring(xyd.getPlayerRegion(var_5_4.player_id)))
	var_5_3:getChildByName("name"):setString(var_5_4.player_name)
	var_5_3:getChildByName("name"):enableOutline(cc.c4b(255, 255, 255, 255), 1)
	var_5_3:getChildByName("score_text"):setString(string.format(var_0_1:translation("SNOW_BALL_SCORE"), var_5_4.score))

	local var_5_7

	var_5_0.rank = arg_5_1

	if var_5_0.rank <= 3 then
		var_5_7 = xyd.AssetLoader.get():loadSprite("windows/single_day/rank/" .. var_5_0.rank .. ".png")
	else
		var_5_7 = xyd.AssetLoader.get():loadLabel(nil, "tacit_rank")

		var_5_7:setString(var_5_0.rank)
	end

	var_5_7:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_7:addTo(var_5_3:getChildByName("rank_pos"))
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
