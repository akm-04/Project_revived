local var_0_0 = class("FishGamblingRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.model.Pet")
local var_0_4 = {
	honor = var_0_1:translation("CHAMPIONS_LEAGUE_HONOR"),
	itemTitle = var_0_1:translation("CHAMPIONS_LEAGUE_RANK_TITLE")
}
local var_0_5 = {
	"total_rank_list",
	"win_rank_list",
	"lose_rank_list"
}
local var_0_6 = {
	win_rank_list = "win",
	total_rank_list = "total",
	lose_rank_list = "lose"
}
local var_0_7 = {
	total_rank_list = var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_20"),
	win_rank_list = var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_21"),
	lose_rank_list = var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_22")
}
local var_0_8 = {
	total_rank_list = var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_23"),
	win_rank_list = var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_24"),
	lose_rank_list = var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_25")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.honorInfo = arg_1_2
	arg_1_0.myRank = arg_1_2.my_rank

	dump(arg_1_0.myRank)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()

	arg_2_0.rankType = var_0_5[1]

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.left_container = arg_3_0:nodeByName("left_inner")

	local var_3_0 = arg_3_0.left_container:getContentSize()

	arg_3_0.leftList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.left_container):onScroll(handler(arg_3_0, arg_3_0.scrollListener1)):setTouchType(true):setBounceable(true):pos(0, 0)
	arg_3_0.main_container = arg_3_0:nodeByName("main_inner")

	local var_3_1 = arg_3_0.main_container:getContentSize()

	arg_3_0.mainList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height + 99),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.main_container):onScroll(handler(arg_3_0, arg_3_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, -99)

	arg_3_0.mainList_:setDelegate(handler(arg_3_0, arg_3_0.rankDelegate))

	arg_3_0.bottom_container = arg_3_0:nodeByName("bottom_inner")

	local var_3_2 = arg_3_0.bottom_container:getContentSize()

	arg_3_0.bottomList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_2.width, var_3_2.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_3_0.bottom_container):onScroll(handler(arg_3_0, arg_3_0.scrollListener)):setTouchType(true):setBounceable(false):pos(0, 0)

	arg_3_0.bottomList_:setViewCanNotScroll(true)
	arg_3_0.bottomList_:setDelegate(handler(arg_3_0, arg_3_0.myrankDelegate))
	arg_3_0:nodeByName("refresh_bg"):setVisible(false)

	local var_3_3 = xyd.AssetLoader.get():loadSprite("windows/fish_gambling/refresh_bg.png")

	arg_3_0:nodeByName("refresh_bg"):addChild(var_3_3)
	var_3_3:setAnchorPoint(0, 0)
	var_3_3:setPosition(cc.p(0, 0))
	var_3_3:setLocalZOrder(0)
	arg_3_0:nodeByName("main_rank_txt"):setLocalZOrder(1)
	arg_3_0:nodeByName("on_time_txt"):setLocalZOrder(1)
	arg_3_0:nodeByName("refresh_time_txt"):setLocalZOrder(1)
	arg_3_0:updateLeftContainer()
end

function var_0_0.myrankDelegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = arg_4_0.myRank[var_0_6[arg_4_0.rankType]]
	local var_4_1 = 1

	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return var_4_1
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		if var_4_1 < arg_4_3 then
			return nil
		end

		if var_4_0.score and var_4_0.score > 0 then
			return arg_4_0:addMyRank(var_4_0)
		else
			return arg_4_0:initMyRank()
		end
	end
end

function var_0_0.initMyRank(arg_5_0)
	local var_5_0 = arg_5_0.bottomList_:dequeueItem()

	if not var_5_0 then
		var_5_0 = arg_5_0.bottomList_:newItem()
	else
		var_5_0:removeAllChildren(true)
	end

	local var_5_1 = display.newNode()
	local var_5_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/rank/my_rank_item.csb")
	local var_5_3 = var_5_2:getChildByName("container")

	xyd.setPlayerTitle(var_5_3:getChildByName("title_container"), arg_5_0.selfPlayer.titleInfo)

	local var_5_4 = var_5_3:getContentSize()

	var_5_3:getChildByName("text_player_name"):setString(arg_5_0.selfPlayer.playerName)
	xyd.setPlayerAvatar(var_5_3:getChildByName("avatar"), {
		avatar_id = arg_5_0.selfPlayer:getMyCurrentAvatarID(),
		avatar_frame_id = arg_5_0.selfPlayer.avatarFrame
	})

	if arg_5_0.selfPlayer.conquerLev and arg_5_0.selfPlayer.conquerLev > 0 then
		xyd.setConquerLev(arg_5_0.selfPlayer.conquerLev, var_5_3:getChildByName("text_level"), var_5_3:getChildByName("dengjiquan"), nil, nil, 0.6)
	else
		var_5_3:getChildByName("text_level"):setString(arg_5_0.selfPlayer.lev)
	end

	local var_5_5 = xyd.AssetLoader.get():loadSprite("windows/fish_gambling/my_rank_bg.png")

	var_5_3:addChild(var_5_5)
	var_5_5:setAnchorPoint(0, 0)
	var_5_5:setPosition(cc.p(0, 0))
	var_5_5:setLocalZOrder(-1)
	var_5_3:getChildByName("my_rank_png"):setVisible(false)
	var_5_3:getChildByName("text_my_rank"):setVisible(false)
	var_5_3:getChildByName("rank_num"):setVisible(false)
	var_5_3:getChildByName("text_yesterday"):setVisible(false)
	var_5_3:getChildByName("down_arrow"):setVisible(false)
	var_5_3:getChildByName("up_arrow"):setVisible(false)
	var_5_3:getChildByName("text_change"):setVisible(false)
	var_5_3:getChildByName("text_rank"):enableOutline(cc.c4b(145, 90, 53, 255), 2)
	var_5_2:setPosition(cc.p(0, 0))
	var_5_2:setContentSize(var_5_4.width, var_5_4.height)
	var_5_1:addChild(var_5_2)
	var_5_1:setContentSize(cc.size(arg_5_0.bottomList_.viewRect_.width, var_5_4.height))
	var_5_0:addContent(var_5_1)
	var_5_0:setItemSize(arg_5_0.bottomList_.viewRect_.width, var_5_4.height)

	return var_5_0
end

function var_0_0.addMyRank(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_0.bottomList_:dequeueItem()

	if not var_6_0 then
		var_6_0 = arg_6_0.bottomList_:newItem()
	else
		var_6_0:removeAllChildren(true)
	end

	local var_6_1 = display.newNode()
	local var_6_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/rank/my_rank_item.csb")
	local var_6_3 = var_6_2:getChildByName("container")

	xyd.setPlayerTitle(var_6_3:getChildByName("title_container"), arg_6_0.selfPlayer.titleInfo)

	local var_6_4 = var_6_3:getContentSize()

	var_6_3:getChildByName("text_player_name"):setString(arg_6_0.selfPlayer.playerName)
	xyd.setPlayerAvatar(var_6_3:getChildByName("avatar"), {
		avatar_id = arg_6_0.selfPlayer:getMyCurrentAvatarID(),
		avatar_frame_id = arg_6_0.selfPlayer.avatarFrame
	})

	if arg_6_0.selfPlayer.conquerLev and arg_6_0.selfPlayer.conquerLev > 0 then
		xyd.setConquerLev(arg_6_0.selfPlayer.conquerLev, var_6_3:getChildByName("text_level"), var_6_3:getChildByName("dengjiquan"), nil, nil, 0.6)
	else
		var_6_3:getChildByName("text_level"):setString(arg_6_0.selfPlayer.lev)
	end

	local var_6_5 = xyd.AssetLoader.get():loadSprite("windows/fish_gambling/my_rank_bg.png")

	var_6_3:addChild(var_6_5)
	var_6_5:setAnchorPoint(0, 0)
	var_6_5:setPosition(cc.p(0, 0))
	var_6_5:setLocalZOrder(-1)
	var_6_3:getChildByName("my_rank_png"):setVisible(false)
	var_6_3:getChildByName("text_my_rank"):setVisible(false)
	var_6_3:getChildByName("rank_num"):setVisible(false)
	arg_6_0:initTextMyRank(var_6_3, arg_6_2, arg_6_1)
	var_6_3:getChildByName("text_yesterday"):setVisible(false)
	var_6_3:getChildByName("down_arrow"):setVisible(false)
	var_6_3:getChildByName("up_arrow"):setVisible(false)
	var_6_3:getChildByName("text_change"):setVisible(false)
	var_6_3:getChildByName("text_rank"):enableOutline(cc.c4b(145, 90, 53, 255), 2)
	var_6_2:setPosition(cc.p(0, 0))
	var_6_2:setContentSize(var_6_4.width, var_6_4.height)
	var_6_1:addChild(var_6_2)
	var_6_1:setContentSize(cc.size(arg_6_0.bottomList_.viewRect_.width, var_6_4.height))
	var_6_0:addContent(var_6_1)
	var_6_0:setItemSize(arg_6_0.bottomList_.viewRect_.width, var_6_4.height)

	return var_6_0
end

function var_0_0.initTextMyRank(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = ""
	local var_7_1
	local var_7_2 = 0

	if arg_7_3.score then
		var_7_1 = arg_7_3.score
	elseif arg_7_3 == {} then
		var_7_1 = 0
	end

	if arg_7_3.rank then
		var_7_2 = arg_7_3.rank
	elseif arg_7_3 == {} then
		var_7_2 = 0
	end

	local var_7_3 = var_0_8[arg_7_0.rankType] .. var_7_1

	arg_7_1:getChildByName("text_rank"):setString(var_7_3)
	arg_7_1:getChildByName("rank_num"):setString(var_7_2)

	if var_7_2 ~= 0 then
		arg_7_1:getChildByName("text_my_rank"):enableOutline(cc.c4b(145, 90, 53, 255), 2)
		arg_7_1:getChildByName("text_my_rank"):setVisible(true)
		arg_7_1:getChildByName("rank_num"):enableOutline(cc.c4b(145, 90, 53, 255), 2)
		arg_7_1:getChildByName("rank_num"):setVisible(true)
	end
end

function var_0_0.rankDelegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = arg_8_0.mainRankList
	local var_8_1 = #var_8_0

	if var_8_1 == 0 then
		arg_8_0:nodeByName("partner"):setVisible(true)
	end

	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return var_8_1
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		if arg_8_3 == 1 then
			arg_8_0:nodeByName("partner"):setVisible(false)
		end

		if var_8_1 < arg_8_3 then
			return nil
		end

		local var_8_2 = var_8_0[arg_8_3]

		return arg_8_0:addRankItem(var_8_2, arg_8_3)
	end
end

function var_0_0.addRankItem(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_0.mainList_:dequeueItem()

	if not var_9_0 then
		var_9_0 = arg_9_0.mainList_:newItem()
	else
		var_9_0:removeAllChildren(true)
	end

	local var_9_1 = display.newNode()
	local var_9_2 = "windows/arena/rank/rank_item.csb"
	local var_9_3 = xyd.AssetLoader.get():loadNodeFromJson(var_9_2)
	local var_9_4 = var_9_3:getChildByName("container")

	arg_9_0:initAvatarInfo(var_9_4, arg_9_1.player_info)
	arg_9_0:initCellRankNum(var_9_4, arg_9_1, arg_9_2)
	arg_9_0:initInfoText(var_9_4, arg_9_1, arg_9_2)

	local var_9_5 = var_9_4:getContentSize()

	var_9_3:setPosition(cc.p(0, 0))
	var_9_3:setContentSize(var_9_5.width, var_9_5.height)
	var_9_1:addChild(var_9_3)
	var_9_1:setContentSize(cc.size(arg_9_0.mainList_.viewRect_.width, var_9_3:getContentSize().height))
	var_9_0:addContent(var_9_1)
	var_9_0:setItemSize(arg_9_0.mainList_.viewRect_.width, var_9_1:getContentSize().height + 5)

	return var_9_0
end

function var_0_0.initAvatarInfo(arg_10_0, arg_10_1, arg_10_2)
	if arg_10_2.conquer_lev and arg_10_2.conquer_lev > 0 then
		local var_10_0 = {
			x = -2,
			y = 2
		}

		xyd.setConquerLev(arg_10_2.conquer_lev, arg_10_1:getChildByName("text_level"), arg_10_1:getChildByName("dengjiquan"), var_10_0, nil, nil, nil, arg_10_2.conquer_loop_id)
	else
		arg_10_1:getChildByName("text_level"):setString(arg_10_2.level or arg_10_2.lev)
	end

	arg_10_1:getChildByName("text_player_name"):setString(arg_10_2.player_name or arg_10_2.name)
	arg_10_1:getChildByName("avatar"):setScale(0.9333333333333333)

	local function var_10_1(arg_11_0)
		if arg_11_0.name == "began" then
			arg_10_0.isOpenPlayerInfoWindow = false

			return true
		elseif arg_11_0.name == "ended" and not arg_10_0.scrollViewMoved_ then
			arg_10_0.isOpenPlayerInfoWindow = true

			xyd.openPersonDisplayWindow(arg_10_2)
		end
	end

	xyd.setPlayerAvatar(arg_10_1:getChildByName("avatar"), {
		showLevel = false,
		avatar_id = arg_10_2.avatar_id,
		avatar_frame_id = arg_10_2.avatar_frame_id,
		callback = var_10_1
	})
	xyd.setPlayerTitle(arg_10_1:getChildByName("title_container"), arg_10_2.title_info)
end

function var_0_0.initInfoText(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = var_0_8[arg_12_0.rankType] .. arg_12_2.bet

	arg_12_1:getChildByName("text_info"):setString(var_12_0)
end

function var_0_0.initCellRankNum(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0 = arg_13_1:getChildByName("rank_item_bg_1")
	local var_13_1 = arg_13_1:getChildByName("rank_item_bg_2")
	local var_13_2 = arg_13_1:getChildByName("rank_item_bg_3")
	local var_13_3 = arg_13_1:getChildByName("rank_val_1")
	local var_13_4 = arg_13_1:getChildByName("rank_val_2")
	local var_13_5 = arg_13_1:getChildByName("rank_val_3")

	if arg_13_3 == 1 or arg_13_2.rank == 1 then
		var_13_3:setVisible(true)
		var_13_4:setVisible(false)
		var_13_5:setVisible(false)
		var_13_0:setVisible(true)
		var_13_1:setVisible(false)
		var_13_2:setVisible(false)
	elseif arg_13_3 == 2 or arg_13_2.rank == 2 then
		var_13_3:setVisible(false)
		var_13_4:setVisible(true)
		var_13_5:setVisible(false)
		var_13_0:setVisible(false)
		var_13_1:setVisible(true)
		var_13_2:setVisible(false)
	elseif arg_13_3 == 3 or arg_13_2.rank == 3 then
		var_13_3:setVisible(false)
		var_13_4:setVisible(false)
		var_13_5:setVisible(true)
		var_13_0:setVisible(false)
		var_13_1:setVisible(false)
		var_13_2:setVisible(true)
	else
		var_13_3:setVisible(false)
		var_13_4:setVisible(false)
		var_13_5:setVisible(false)
		var_13_0:setVisible(false)
		var_13_1:setVisible(false)
		var_13_2:setVisible(false)

		local var_13_6 = xyd.AssetLoader.get():loadLabel(nil, "rankFonts")

		if arg_13_2.rank and arg_13_2.rank > 0 then
			var_13_6:setString(arg_13_2.rank)
		else
			var_13_6:setString(arg_13_3)
		end

		var_13_6:setAnchorPoint(cc.p(0.5, 0.5))
		var_13_6:setPosition(arg_13_1:getChildByName("rank_val_1"):getPosition())
		var_13_6:addTo(arg_13_1)
	end
end

function var_0_0.initHerosInfo(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = {}
	local var_14_1

	if arg_14_2.pet and arg_14_2.pet.pet_id then
		local var_14_2 = arg_14_2.pet

		if type(var_14_2.equips) == "string" then
			var_14_2.equips = xyd.splitToNumber(var_14_2.equips, "|")
		end

		local var_14_3 = var_0_3.new()

		var_14_3:populate(var_14_2)

		var_14_1 = var_14_3
	else
		var_14_1 = nil
	end

	if var_14_1 then
		local var_14_4 = display.newNode()

		var_14_4:setContentSize(64, 64)
		xyd.setPetAvatarNewUI(var_14_4, var_14_1, nil, true)
		var_14_4:setAnchorPoint(cc.p(0.5, 0, 5))
		var_14_4:setScale(0.6)
		var_14_4:addTo(arg_14_1:getChildByName("list_avatar"))
		var_14_4:setPosition(cc.p(32, 18))
	end

	if arg_14_2.heros and next(arg_14_2.heros) then
		for iter_14_0, iter_14_1 in pairs(arg_14_2.heros) do
			local var_14_5 = iter_14_1

			if type(var_14_5.equips) == "string" then
				var_14_5.equips = xyd.splitToNumber(var_14_5.equips, "|")
			end

			if iter_14_1.book_shelf_lev and iter_14_1.book_shelf_lev > 0 then
				var_14_5.book_shelf_lev = iter_14_1.book_shelf_lev
			else
				var_14_5.book_shelf_lev = 0
			end

			local var_14_6 = var_0_2.new()

			var_14_6:populate(var_14_5)

			if arg_14_2.player_info.conquer_lev and arg_14_2.player_info.conquer_lev > 0 then
				var_14_6:setConquerSchoolLev(arg_14_2.player_info.conquer_lev)
			end

			table.insert(var_14_0, var_14_6)
		end
	end

	for iter_14_2 = 1, #var_14_0 do
		local var_14_7 = display.newNode()

		var_14_7:setContentSize(64, 64)
		xyd.setAvatarBorderNewUI(var_14_0[iter_14_2], var_14_7, nil, nil, nil, nil, nil, nil, false)
		var_14_7:addTo(arg_14_1:getChildByName("list_avatar"))
		var_14_7:setPosition(cc.p(70 * iter_14_2, 5))
	end
end

function var_0_0.updateLeftContainer(arg_15_0)
	arg_15_0.leftList_:removeAllItems()

	for iter_15_0 = 1, #var_0_5 do
		if arg_15_0.honorInfo[var_0_5[iter_15_0]] then
			arg_15_0:addLeftCategory(arg_15_0.honorInfo[var_0_5[iter_15_0]], var_0_5[iter_15_0])
		end
	end

	arg_15_0.leftList_:reload()

	arg_15_0.mainRankList = arg_15_0.honorInfo.total_rank_list
	arg_15_0.mainRankTxt = var_0_7[var_0_5[1]]

	arg_15_0:updateMainContainer()
end

function var_0_0.addLeftCategory(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_0.leftList_:newItem()
	local var_16_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/fish_gambling/main/rank_type_item.csb")
	local var_16_2 = var_16_1:getChildByName("container")

	if not arg_16_0.leftBtn then
		arg_16_0.leftBtn = var_16_2:getChildByName("left_btn")

		arg_16_0.leftBtn:setBright(false)
	end

	local var_16_3 = var_16_2:getContentSize()

	var_16_1:setPosition(cc.p(0, 0))
	var_16_1:setContentSize(var_16_3)
	var_16_1:setTouchEnabled(true)
	var_16_1:setTouchSwallowEnabled(false)
	var_16_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
		if arg_17_0.name == "began" then
			return true
		elseif arg_17_0.name == "ended" then
			if not arg_16_0.scrollViewMoved_1 then
				arg_16_0.rankType = arg_16_2
				arg_16_0.mainRankList = arg_16_0.honorInfo[arg_16_0.rankType]
				arg_16_0.mainRankTxt = var_0_7[arg_16_0.rankType]

				arg_16_0:updateMainContainer()

				if arg_16_0.leftBtn then
					arg_16_0.leftBtn:setBright(true)
				end

				arg_16_0.leftBtn = var_16_2:getChildByName("left_btn")

				arg_16_0.leftBtn:setBright(false)
			end

			return true
		end
	end)
	var_16_0:addContent(var_16_1)
	var_16_0:setItemSize(var_16_3.width, var_16_3.height + 20)
	arg_16_0.leftList_:addItem(var_16_0)
	arg_16_0:initLeftTitle(var_16_2, var_0_7[arg_16_2])
end

function var_0_0.updateMainContainer(arg_18_0)
	arg_18_0.mainList_:reload()
	arg_18_0.bottomList_:reload()

	if arg_18_0.mainRankTxt then
		arg_18_0:nodeByName("refresh_bg"):setVisible(true)
		arg_18_0:nodeByName("main_rank_txt"):setString(arg_18_0.mainRankTxt)
	end
end

function var_0_0.initLeftTitle(arg_19_0, arg_19_1, arg_19_2)
	arg_19_1:getChildByName("rank_txt"):setString(arg_19_2)
end

function var_0_0.scrollListener(arg_20_0, arg_20_1)
	if arg_20_1.name == "began" then
		arg_20_0.scrollViewMoved_ = false
		arg_20_0.prevY_ = arg_20_1.y
	elseif arg_20_1.name == "moved" and 10 <= math.abs(arg_20_1.y - arg_20_0.prevY_) then
		arg_20_0.scrollViewMoved_ = true
	end
end

function var_0_0.scrollListener1(arg_21_0, arg_21_1)
	if arg_21_1.name == "began" then
		arg_21_0.scrollViewMoved_1 = false
		arg_21_0.prevY_ = arg_21_1.y
	elseif arg_21_1.name == "moved" then
		if 10 <= math.abs(arg_21_1.y - arg_21_0.prevY_) then
			arg_21_0.scrollViewMoved_1 = true
		end
	elseif arg_21_1.name == "ended" then
		arg_21_0.scrollViewMoved_1 = false
	end
end

function var_0_0.didClose(arg_22_0)
	return
end

return var_0_0
