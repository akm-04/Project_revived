local var_0_0 = class("ThirdAnniversaryBossRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.thirdAnniversary = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.rankInfo = arg_1_0.thirdAnniversary.boss_rankInfo
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("my_harm"):setString(string.format(var_0_1:translation("THIRD_ANNIVERSARY_BOSS_TEXT7"), arg_3_0.thirdAnniversary.self_damage))

	if arg_3_0.thirdAnniversary.total_rank == 0 then
		arg_3_0:nodeByName("my_rank"):setVisible(false)
	else
		arg_3_0:nodeByName("my_rank"):setVisible(true)
		arg_3_0:nodeByName("my_rank"):setString(string.format(var_0_1:translation("THIRD_ANNIVERSARY_BOSS_TEXT6"), arg_3_0.thirdAnniversary.total_rank))
	end

	local var_3_0 = cc.c4b(227, 74, 77, 255)

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
	local var_5_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/third_anniversary_boss/third_anniversary_rank_item.csb")
	local var_5_3 = var_5_2:getChildByName("bg")
	local var_5_4 = var_5_0.player_info

	if var_5_4.conquer_lev and var_5_4.conquer_lev > 0 then
		var_5_3:getChildByName("level_bg"):setVisible(false)
		xyd.setConquerLev(var_5_4.conquer_lev, var_5_3:getChildByName("lev_text"), var_5_3:getChildByName("level_bg"), nil, false, 0.9, "conquer_lev_bg", var_5_4.conquer_loop_id)
	else
		var_5_3:getChildByName("lev_text"):setString(var_5_4.lev)
		var_5_3:getChildByName("conquer_lev_bg"):setVisible(false)
	end

	local var_5_5 = {
		playerInfo = var_5_4,
		avatar_id = var_5_4.avatar_id,
		avatar_frame_id = var_5_4.avatar_frame_id
	}

	xyd.setPlayerAvatar(var_5_3:getChildByName("icon_container"), var_5_5)
	var_5_3:getChildByName("region"):setString("S" .. tostring(xyd.getPlayerRegion(var_5_4.player_id)))
	var_5_3:getChildByName("name"):setString(var_5_4.player_name)
	var_5_3:getChildByName("name"):enableOutline(cc.c4b(255, 255, 255, 255), 1)
	var_5_3:getChildByName("damage_text"):setString(string.format(var_0_1:translation("THIRD_ANNIVERSARY_BOSS_TEXT14"), var_5_0.damage))

	local var_5_6

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
