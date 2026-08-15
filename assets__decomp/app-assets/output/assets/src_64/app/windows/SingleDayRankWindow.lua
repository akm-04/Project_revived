local var_0_0 = class("SingleDayRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.rankData = arg_1_2.data or {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.scroll = arg_4_0:nodeByName("scroll")

	arg_4_0:nodeByName("rank_empty_text"):setString(var_0_1:translation("RANK_EMPTY_TEXT"))

	local var_4_0 = arg_4_0.scroll:getContentSize()

	arg_4_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 20, var_4_0.width, var_4_0.height - 20),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.list:setBounceable(true)
	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.listDelegate))
	arg_4_0.list:setTouchType(false)
	arg_4_0.list:reload()
end

function var_0_0.listDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		if #arg_5_0.rankData > 0 then
			arg_5_0:nodeByName("rank_empty_text"):setVisible(false)
		else
			arg_5_0:nodeByName("rank_empty_text"):setVisible(true)
		end

		return #arg_5_0.rankData
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0
		local var_5_1 = arg_5_0.list:dequeueItem()

		if not var_5_1 then
			var_5_1 = arg_5_0.list:newItem()
		else
			var_5_1:removeAllChildren(false)
		end

		local var_5_2 = arg_5_0:createListContent(arg_5_0.rankData[arg_5_3])
		local var_5_3 = var_5_2:getWidth()
		local var_5_4 = var_5_2:getHeight()

		var_5_1:setItemSize(var_5_3, var_5_4)
		var_5_1:addContent(var_5_2)

		return var_5_1
	end
end

function var_0_0.createListContent(arg_6_0, arg_6_1)
	local var_6_0 = display.newNode()
	local var_6_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/single_day/rank_item.csb")
	local var_6_2 = var_6_1:getChildByName("container")

	for iter_6_0 = 1, 2 do
		local var_6_3

		if iter_6_0 == 1 then
			var_6_3 = arg_6_1.left_player_info
		else
			var_6_3 = arg_6_1.right_player_info
		end

		local var_6_4 = {
			avatar_id = var_6_3.avatar_id,
			avatar_frame_id = var_6_3.avatar_frame_id
		}

		xyd.setPlayerAvatar(var_6_2:getChildByName("avtar_container" .. iter_6_0), var_6_4)
		var_6_2:getChildByName("name_txt" .. iter_6_0):setString(var_6_3.player_name)
		var_6_2:getChildByName("region_txt" .. iter_6_0):setString("S" .. var_6_3.region)
	end

	var_6_2:getChildByName("agreement_text"):setString(var_0_1:translation("AGREEMENT_TEXT1"))
	var_6_2:getChildByName("agreement_txt"):setString(arg_6_1.tacit)

	local var_6_5

	if arg_6_1.rank <= 3 then
		var_6_5 = xyd.AssetLoader.get():loadSprite("windows/single_day/rank/" .. arg_6_1.rank .. ".png")
	else
		var_6_5 = xyd.AssetLoader.get():loadLabel(nil, "tacit_rank")

		var_6_5:setString(arg_6_1.rank)
	end

	var_6_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_6_5:addTo(var_6_2:getChildByName("rank_pos"))
	var_6_1:addTo(var_6_0)
	var_6_1:setAnchorPoint(cc.p(0, 0))
	var_6_0:setContentSize(var_6_2:getContentSize())
	var_6_1:setName("source")

	return var_6_0
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevX_ = arg_7_1.x
	elseif arg_7_1.name == "moved" and 20 <= math.abs(arg_7_1.x - arg_7_0.prevX_) then
		arg_7_0.scrollViewMoved_ = true
	end
end

return var_0_0
