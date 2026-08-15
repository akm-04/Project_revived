local var_0_0 = class("ChampionsHonorRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.model.Pet")
local var_0_4 = {
	honor = var_0_1:translation("CHAMPIONS_LEAGUE_HONOR"),
	roomTitle = var_0_1:translation("CHAMPIONS_LEAGUE_RANK_ROOM"),
	itemTitle = var_0_1:translation("CHAMPIONS_LEAGUE_RANK_TITLE")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.honorInfo = arg_1_2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()
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
	arg_3_0:nodeByName("refresh_bg"):setVisible(false)
	arg_3_0:updateLeftContainer()
end

function var_0_0.rankDelegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = arg_4_0.mainRankList
	local var_4_1 = #var_4_0

	if var_4_1 == 0 then
		arg_4_0:nodeByName("partner"):setVisible(true)
	end

	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return var_4_1
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		if arg_4_3 == 1 then
			arg_4_0:nodeByName("partner"):setVisible(false)
		end

		if var_4_1 < arg_4_3 then
			return nil
		end

		local var_4_2 = var_4_0[arg_4_3]

		return arg_4_0:addRankItem(var_4_2, arg_4_3)
	end
end

function var_0_0.addRankItem(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_0.mainList_:dequeueItem()

	if not var_5_0 then
		var_5_0 = arg_5_0.mainList_:newItem()
	else
		var_5_0:removeAllChildren(true)
	end

	local var_5_1 = display.newNode()
	local var_5_2 = "windows/champions_league/honor_item.csb"
	local var_5_3 = xyd.AssetLoader.get():loadNodeFromJson(var_5_2)
	local var_5_4 = var_5_3:getChildByName("container")

	arg_5_0:initAvatarInfo(var_5_4, arg_5_1.player_info)
	arg_5_0:initInfoText(var_5_4, arg_5_1, arg_5_2)
	arg_5_0:initHerosInfo(var_5_4, arg_5_1)

	local var_5_5 = var_5_4:getContentSize()

	var_5_3:setPosition(cc.p(0, 0))
	var_5_3:setContentSize(var_5_5.width, var_5_5.height)
	var_5_1:addChild(var_5_3)
	var_5_1:setContentSize(cc.size(arg_5_0.mainList_.viewRect_.width, var_5_3:getContentSize().height))
	var_5_0:addContent(var_5_1)
	var_5_0:setItemSize(arg_5_0.mainList_.viewRect_.width, var_5_1:getContentSize().height + 5)

	return var_5_0
end

function var_0_0.initAvatarInfo(arg_6_0, arg_6_1, arg_6_2)
	if not arg_6_2 then
		return
	end

	if arg_6_2.conquer_lev and arg_6_2.conquer_lev > 0 then
		local var_6_0 = {
			x = -2,
			y = 2
		}

		xyd.setConquerLev(arg_6_2.conquer_lev, arg_6_1:getChildByName("text_level"), arg_6_1:getChildByName("dengjiquan"), var_6_0, nil, nil, nil, arg_6_2.conquer_loop_id)
	else
		arg_6_1:getChildByName("text_level"):setString(arg_6_2.level or arg_6_2.lev)
	end

	arg_6_1:getChildByName("text_player_name"):setString(arg_6_2.player_name or arg_6_2.name)
	arg_6_1:getChildByName("avatar"):setScale(0.9333333333333333)

	local var_6_1 = math.floor(arg_6_2.player_id / 100000)

	arg_6_1:getChildByName("text_server"):setString("S " .. var_6_1)

	local function var_6_2(arg_7_0)
		if arg_7_0.name == "began" then
			arg_6_0.isOpenPlayerInfoWindow = false

			return true
		elseif arg_7_0.name == "ended" and not arg_6_0.scrollViewMoved_ then
			arg_6_0.isOpenPlayerInfoWindow = true

			xyd.openPersonDisplayWindow(arg_6_2)
		end
	end

	xyd.setPlayerAvatar(arg_6_1:getChildByName("avatar"), {
		showLevel = false,
		avatar_id = arg_6_2.avatar_id,
		avatar_frame_id = arg_6_2.avatar_frame_id,
		callback = var_6_2
	})
end

function var_0_0.initInfoText(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = string.format(var_0_4.itemTitle, arg_8_3)

	arg_8_1:getChildByName("txt_title"):enableOutline(cc.c4b(60, 16, 15, 255), 2)
	arg_8_1:getChildByName("txt_title"):setString(var_8_0)
end

function var_0_0.initHerosInfo(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = {}
	local var_9_1

	if arg_9_2.pet and arg_9_2.pet.pet_id then
		local var_9_2 = arg_9_2.pet

		if type(var_9_2.equips) == "string" then
			var_9_2.equips = xyd.splitToNumber(var_9_2.equips, "|")
		end

		local var_9_3 = var_0_3.new()

		var_9_3:populate(var_9_2)

		var_9_1 = var_9_3
	else
		var_9_1 = nil
	end

	if var_9_1 then
		local var_9_4 = display.newNode()

		var_9_4:setContentSize(64, 64)
		xyd.setPetAvatarNewUI(var_9_4, var_9_1, nil, true)
		var_9_4:setAnchorPoint(cc.p(0.5, 0, 5))
		var_9_4:setScale(0.6)
		var_9_4:addTo(arg_9_1:getChildByName("list_avatar"))
		var_9_4:setPosition(cc.p(32, 18))
	end

	if arg_9_2.heros and next(arg_9_2.heros) then
		for iter_9_0, iter_9_1 in pairs(arg_9_2.heros) do
			local var_9_5 = iter_9_1

			if type(var_9_5.equips) == "string" then
				var_9_5.equips = xyd.splitToNumber(var_9_5.equips, "|")
			end

			if iter_9_1.book_shelf_lev and iter_9_1.book_shelf_lev > 0 then
				var_9_5.book_shelf_lev = iter_9_1.book_shelf_lev
			else
				var_9_5.book_shelf_lev = 0
			end

			local var_9_6 = var_0_2.new()

			var_9_6:populate(var_9_5)

			if arg_9_2.player_info.conquer_lev and arg_9_2.player_info.conquer_lev > 0 then
				var_9_6:setConquerSchoolLev(arg_9_2.player_info.conquer_lev)
			end

			table.insert(var_9_0, var_9_6)
		end
	end

	for iter_9_2 = 1, #var_9_0 do
		local var_9_7 = display.newNode()

		var_9_7:setContentSize(64, 64)
		xyd.setAvatarBorderNewUI(var_9_0[iter_9_2], var_9_7, nil, nil, nil, nil, nil, nil, false)
		var_9_7:addTo(arg_9_1:getChildByName("list_avatar"))
		var_9_7:setPosition(cc.p(70 * iter_9_2, 5))
	end
end

function var_0_0.updateLeftContainer(arg_10_0)
	arg_10_0.leftList_:removeAllItems()
	arg_10_0:addLeftCategory()
	arg_10_0.leftList_:reload()

	arg_10_0.mainRankList = arg_10_0.honorInfo
	arg_10_0.mainRankTxt = var_0_4.roomTitle

	arg_10_0:updateMainContainer()
end

function var_0_0.addLeftCategory(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_0.leftList_:newItem()
	local var_11_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/rank/rank_type_item.csb")
	local var_11_2 = var_11_1:getChildByName("container")
	local var_11_3 = var_11_2:getContentSize()

	var_11_1:setPosition(cc.p(0, 0))
	var_11_1:setContentSize(var_11_3)
	var_11_1:setTouchEnabled(true)
	var_11_1:setTouchSwallowEnabled(false)
	var_11_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
		if arg_12_0.name == "began" then
			return true
		elseif arg_12_0.name == "ended" then
			if not arg_11_0.scrollViewMoved_1 then
				arg_11_0.mainRankList = arg_11_0.honorInfo
				arg_11_0.mainRankTxt = var_0_4.roomTitle

				arg_11_0:updateMainContainer()
			end

			return true
		end
	end)
	var_11_0:addContent(var_11_1)
	var_11_0:setItemSize(var_11_3.width, var_11_3.height + 20)
	arg_11_0.leftList_:addItem(var_11_0)
	arg_11_0:initLeftTitle(var_11_2)
end

function var_0_0.updateMainContainer(arg_13_0)
	arg_13_0.mainList_:reload()

	if arg_13_0.mainRankTxt then
		arg_13_0:nodeByName("refresh_bg"):setVisible(true)
		arg_13_0:nodeByName("main_rank_txt"):setString(arg_13_0.mainRankTxt)
	end
end

function var_0_0.initLeftTitle(arg_14_0, arg_14_1)
	arg_14_1:getChildByName("rank_txt"):setString(var_0_4.honor)
end

function var_0_0.scrollListener(arg_15_0, arg_15_1)
	if arg_15_1.name == "began" then
		arg_15_0.scrollViewMoved_ = false
		arg_15_0.prevY_ = arg_15_1.y
	elseif arg_15_1.name == "moved" and 10 <= math.abs(arg_15_1.y - arg_15_0.prevY_) then
		arg_15_0.scrollViewMoved_ = true
	end
end

function var_0_0.scrollListener1(arg_16_0, arg_16_1)
	if arg_16_1.name == "began" then
		arg_16_0.scrollViewMoved_1 = false
		arg_16_0.prevY_ = arg_16_1.y
	elseif arg_16_1.name == "moved" then
		if 10 <= math.abs(arg_16_1.y - arg_16_0.prevY_) then
			arg_16_0.scrollViewMoved_1 = true
		end
	elseif arg_16_1.name == "ended" then
		arg_16_0.scrollViewMoved_1 = false
	end
end

function var_0_0.didClose(arg_17_0)
	return
end

return var_0_0
