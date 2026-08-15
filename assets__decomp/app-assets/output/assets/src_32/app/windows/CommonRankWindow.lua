local var_0_0 = class("CommonRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.title = arg_1_2.title or var_0_1:translation("RANK")
	arg_1_0.showRegion = arg_1_2.show_region or true
	arg_1_0.desc = arg_1_2.desc
	arg_1_0.maxNum = arg_1_2.max_num
	arg_1_0.myRank = arg_1_2.my_rank
	arg_1_0.rankData = arg_1_2.rank_list
	arg_1_0.key = arg_1_2.key
	arg_1_0.titleColor = arg_1_2.title_color or cc.c3b(255, 255, 255)
	arg_1_0.colorMode = arg_1_2.colorMode or xyd.ColorMode.BLUE
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	local var_2_0 = xyd.tables.systemColor:middleBG(arg_2_0.colorMode)

	if var_2_0 then
		local var_2_1 = cc.rect(1, 160, 1, 1)
		local var_2_2 = xyd.AssetLoader.get():loadSprite(var_2_0, var_2_1)

		var_2_2:addTo(arg_2_0:background())
		var_2_2:setAnchorPoint(0, 0)
		var_2_2:setPosition(0, 0)
		var_2_2:setScale9Enabled(true)
		var_2_2:setContentSize(arg_2_0:background():getContentSize())
		var_2_2:setLocalZOrder(-100)
	end

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_my"):setString(var_0_1:translation("MYRANK_TEXT"))
	arg_4_0:nodeByName("txt_title"):setString(arg_4_0.title)
	arg_4_0:nodeByName("txt_title"):setColor(arg_4_0.titleColor)

	if arg_4_0.desc then
		arg_4_0:nodeByName("txt_desc"):setString(arg_4_0.desc)
	else
		arg_4_0:nodeByName("txt_desc"):setVisible(false)
		arg_4_0:nodeByName("txt_num"):setVisible(false)
	end

	local var_4_0 = arg_4_0:nodeByName("rank_list"):getContentSize()

	arg_4_0.rankList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("rank_list")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.rankList:setDelegate(handler(arg_4_0, arg_4_0.rankDelegate))

	if arg_4_0.rankData and next(arg_4_0.rankData) then
		arg_4_0.rankList:reload()
	end

	if arg_4_0.myRank and next(arg_4_0.myRank) then
		arg_4_0:nodeByName("my_rank"):setString(arg_4_0.myRank.rank)
		arg_4_0:nodeByName("txt_num"):setString(math.ceil(arg_4_0.myRank[arg_4_0.key]))
	else
		arg_4_0:nodeByName("my_rank"):setVisible(false)
		arg_4_0:nodeByName("txt_num"):setVisible(false)
		arg_4_0:nodeByName("txt_my"):setVisible(false)
		arg_4_0:nodeByName("txt_desc"):setVisible(false)
	end
end

function var_0_0.rankDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = #arg_5_0.rankData

	if arg_5_0.maxNum then
		var_5_0 = math.min(arg_5_0.maxNum, var_5_0)
	end

	if arg_5_2 == cc.ui.UIListView.COUNT_TAG then
		return var_5_0
	elseif arg_5_2 == cc.ui.UIListView.CELL_TAG then
		local var_5_1 = arg_5_0.rankList:dequeueItem()

		if var_5_1 then
			var_5_1:removeAllChildren(true)
		else
			var_5_1 = arg_5_0.rankList:newItem()
		end

		local var_5_2 = arg_5_0:createRankItemContent(arg_5_3)
		local var_5_3 = var_5_2:getContentSize()

		var_5_1:addContent(var_5_2)
		var_5_1:setContentSize(var_5_3)
		var_5_1:setItemSize(var_5_3.width, var_5_3.height)

		return var_5_1
	end
end

function var_0_0.createRankItemContent(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0.rankData[arg_6_1]
	local var_6_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/common/rank/rank_item.csb")
	local var_6_2 = var_6_1:getChildByName("container")
	local var_6_3

	var_6_3.callback, var_6_3 = function(arg_7_0)
		if arg_7_0.name == "began" then
			arg_6_0.isOpenPlayerInfoWindow = false

			return true
		elseif arg_7_0.name == "ended" and not arg_6_0.scrollViewMoved_ then
			arg_6_0.isOpenPlayerInfoWindow = true

			xyd.openPersonDisplayWindow(var_6_0)
		end
	end, var_6_0

	xyd.setPlayerInfoContainer(var_6_2, var_6_3)

	if arg_6_1 <= 3 then
		var_6_2:getChildByName("bg_rank"):setVisible(false)
		var_6_2:getChildByName("rank"):setVisible(false)

		for iter_6_0 = 1, 3 do
			var_6_2:getChildByName("bg_rank_" .. iter_6_0):setVisible(arg_6_1 == iter_6_0)
			var_6_2:getChildByName("rank_" .. iter_6_0):setVisible(arg_6_1 == iter_6_0)
		end
	else
		var_6_2:getChildByName("bg_rank"):setVisible(true)

		for iter_6_1 = 1, 3 do
			var_6_2:getChildByName("bg_rank_" .. iter_6_1):setVisible(false)
			var_6_2:getChildByName("rank_" .. iter_6_1):setVisible(false)
		end

		local var_6_4 = var_6_2:getChildByName("rank")

		var_6_4:setString(arg_6_1)
		var_6_4:enableOutline(cc.c4b(89, 138, 174, 255), 3)
	end

	if arg_6_0.showRegion then
		var_6_2:getChildByName("txt_region"):setString(var_6_0.region)
	else
		var_6_2:getChildByName("txt_region"):setVisible(false)
	end

	if arg_6_0.desc then
		var_6_2:getChildByName("txt_desc"):setString(arg_6_0.desc)
		var_6_2:getChildByName("txt_num"):setString(math.ceil(var_6_0[arg_6_0.key]))
	else
		var_6_2:getChildByName("txt_desc"):setVisible(false)
		var_6_2:getChildByName("txt_num"):setVisible(false)
	end

	local var_6_5 = display.newNode()

	var_6_5:setContentSize(var_6_2:getContentSize())
	var_6_1:addTo(var_6_5)

	return var_6_5
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.scrollViewMoved_ = false
		arg_8_0.prevY_ = arg_8_1.y
	elseif arg_8_1.name == "moved" and 20 <= math.abs(arg_8_1.y - arg_8_0.prevY_) then
		arg_8_0.scrollViewMoved_ = true
	end
end

return var_0_0
