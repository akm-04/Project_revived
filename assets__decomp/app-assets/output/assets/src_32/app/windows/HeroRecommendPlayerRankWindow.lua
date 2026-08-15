local var_0_0 = class("HeroRecommendPlayerRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.heroRecommend = xyd.ModelManager.get():loadModel(xyd.ModelType.HERO_RECOMMEND)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.myRank = arg_1_2.my_rank
	arg_1_0.rankData = arg_1_2.rank_list
	arg_1_0.hero = arg_1_2.hero
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = string.format(var_0_1:translation("RECOMMEND_PLAYER_RANK_TEXT"), arg_3_0.hero:getName())

	arg_3_0:nodeByName("title_txt"):setString(var_3_0)
	arg_3_0:nodeByName("my_zhandouli_text"):setString(var_0_1:translation("MY_ZHANDOULI_TEXT1"))
	arg_3_0:nodeByName("rank_txt"):setString(arg_3_0.myRank.rank)
	arg_3_0:nodeByName("zhandouli_txt"):setString(math.ceil(arg_3_0.myRank.force))
	arg_3_0:nodeByName("rank_text"):setString(var_0_1:translation("RANKING") .. ":")

	arg_3_0.scroll = arg_3_0:nodeByName("scroll")

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

	arg_3_0.scrollList:setDelegate(handler(arg_3_0, arg_3_0.scrollListDelegate))
	arg_3_0.scrollList:reload()
end

function var_0_0.scrollListDelegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #arg_4_0.rankData
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
	local var_5_0 = arg_5_0.rankData[arg_5_1]
	local var_5_1 = display.newNode()
	local var_5_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_recommend/player_rank/player_rank_item.csb")
	local var_5_3 = var_5_2:getChildByName("container")

	xyd.setPlayerInfoContainer(var_5_3, var_5_0)

	local var_5_4 = {
		avatar_id = var_5_0.avatar_id,
		avatar_frame_id = var_5_0.avatar_frame_id,
		playerInfo = var_5_0
	}

	var_5_3:getChildByName("avtar_container"):removeAllChildren()
	xyd.setPlayerAvatar(var_5_3:getChildByName("avtar_container"), var_5_4)
	var_5_3:getChildByName("region_txt"):setString("S" .. tostring(var_5_0.region))
	var_5_3:getChildByName("zhandouli_txt"):setString(math.ceil(var_5_0.force))
	var_5_3:getChildByName("zhandouli_text"):setString(var_0_1:translation("HERO_INFO_ZHANDOULI"))

	local var_5_5

	if arg_5_1 <= 3 then
		var_5_5 = xyd.AssetLoader.get():loadSprite("windows/single_day/rank/" .. arg_5_1 .. ".png")
	else
		var_5_5 = xyd.AssetLoader.get():loadLabel(nil, "tacit_rank")

		var_5_5:setString(arg_5_1)
		var_5_5:setAnchorPoint(cc.p(0.5, 0.5))
		var_5_5:setLocalZOrder(20)
	end

	var_5_5:addTo(var_5_3:getChildByName("rank_pos"))
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
