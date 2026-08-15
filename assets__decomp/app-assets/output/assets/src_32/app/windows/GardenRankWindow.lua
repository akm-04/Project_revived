local var_0_0 = class("GardenRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.garden = xyd.ModelManager.get():loadModel(xyd.ModelType.GARDEN)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.rankInfo = arg_1_2.rank_info
	arg_1_0.selfRank = arg_1_2.self_info
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("total_reward_txt"):setString(arg_4_0.selfRank.score)
	arg_4_0:nodeByName("myrank_text"):setString(var_0_1:translation("MYRANK_TEXT"))
	arg_4_0:nodeByName("total_reward_text"):setString(var_0_1:translation("GARDEN_TOTAL_NUM_TEXT"))
	arg_4_0:nodeByName("txt_title"):setString(var_0_1:translation("GARDEN_RANK_TITLE_TEXT"))
	arg_4_0:nodeByName("txt_no_rank"):setString(var_0_1:translation("GARDEN_NO_RANK_TEXT"))

	if arg_4_0.selfRank.rank and arg_4_0.selfRank.rank > 0 then
		arg_4_0:nodeByName("txt_rank"):setString(arg_4_0.selfRank.rank)
	else
		arg_4_0:nodeByName("no_rank_tip"):setVisible(true)
		arg_4_0:nodeByName("no_rank_tip"):setString(var_0_1:translation("NO_RANK_TEXT"))
		arg_4_0:nodeByName("total_reward_txt"):setString(0)
	end

	if not arg_4_0.rankInfo or not next(arg_4_0.rankInfo) then
		arg_4_0:nodeByName("no_rank_pos"):setVisible(true)
		arg_4_0:nodeByName("txt_no_rank"):getVirtualRenderer():setLineHeight(30)

		return
	end

	arg_4_0.scroll = arg_4_0:nodeByName("scroll")

	local var_4_0 = arg_4_0.scroll:getContentSize()

	arg_4_0.scrollList = cc.ui.UIListView.new({
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

	arg_4_0.scrollList:setBounceable(true)
	arg_4_0.scrollList:setDelegate(handler(arg_4_0, arg_4_0.scrollListDelegate))
	arg_4_0.scrollList:setTouchType(false)
	arg_4_0.scrollList:reload()
end

function var_0_0.scrollListDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #(arg_5_0.rankInfo or {})
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0
		local var_5_1 = arg_5_0.scrollList:dequeueItem()

		if not var_5_1 then
			var_5_1 = arg_5_0.scrollList:newItem()
		else
			var_5_1:removeAllChildren(true)
		end

		local var_5_2 = arg_5_0:createListContent(arg_5_3)
		local var_5_3 = var_5_2:getWidth()
		local var_5_4 = var_5_2:getHeight()

		var_5_1:setItemSize(var_5_3, var_5_4)
		var_5_1:addContent(var_5_2)

		return var_5_1
	end
end

function var_0_0.createListContent(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0.rankInfo[arg_6_1]
	local var_6_1 = display.newNode()
	local var_6_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/garden/rank/rank_item.csb")
	local var_6_3 = var_6_2:getChildByName("container")
	local var_6_4 = var_6_0

	params = var_6_4

	xyd.setPlayerAvatar(var_6_3:getChildByName("icon_container"), params)

	local var_6_5 = var_6_3:getChildByName("icon_container"):getChildByName("avatar")

	var_6_5:setTouchEnabled(true)
	var_6_5:setTouchSwallowEnabled(false)
	var_6_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			return true
		elseif arg_7_0.name == "ended" and not arg_6_0.scrollViewMoved_ then
			local var_7_0 = {
				player_id = var_6_4.player_id
			}

			arg_6_0.garden:getGardenInfo(var_7_0, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					xyd.WindowManager.get():closeWindow(arg_6_0)
				end
			end)
		end
	end)

	local var_6_6 = {
		lev = var_6_4.lev,
		conquerLev = var_6_4.conquer_lev,
		loopID = var_6_4.conquer_loop_id,
		fontColor = cc.c3b(102, 30, 30)
	}

	xyd.setLev(var_6_3:getChildByName("lv"), var_6_6)
	var_6_3:getChildByName("region_txt"):setString("S" .. tostring(xyd.getPlayerRegion(var_6_4.player_id)))
	var_6_3:getChildByName("name_txt"):setString(var_6_4.player_name)
	var_6_3:getChildByName("total_reward_txt"):setString(var_6_0.score)
	var_6_3:getChildByName("total_reward_text"):setString(var_0_1:translation("GARDEN_TOTAL_NUM_TEXT"))

	if arg_6_1 <= 3 then
		rank = xyd.AssetLoader.get():loadSprite("windows/garden/rank/icon_rank_" .. arg_6_1 .. ".png")

		var_6_3:setBackGroundImage("windows/garden/rank/bg_rank_" .. arg_6_1 .. ".png")
	else
		rank = xyd.createLabel(48, cc.c3b(222, 243, 253))

		rank:enableOutline(cc.c4b(89, 138, 174, 255), 3)
		rank:setString(arg_6_1)
	end

	rank:setAnchorPoint(cc.p(0.5, 0.5))
	rank:addTo(var_6_3:getChildByName("rank_pos"))
	var_6_2:addTo(var_6_1)
	var_6_2:setAnchorPoint(cc.p(0, 0))
	var_6_1:setContentSize(var_6_3:getContentSize())
	var_6_2:setName("source")

	return var_6_1
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevY_ = arg_9_1.y
	elseif arg_9_1.name == "moved" and 5 <= math.abs(arg_9_1.y - arg_9_0.prevY_) then
		arg_9_0.scrollViewMoved_ = true
	end
end

return var_0_0
