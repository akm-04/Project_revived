local var_0_0 = class("SnowRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 4

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.rankList = arg_1_2.rank_list or {}
	arg_1_0.myRank = arg_1_2.my_rank or {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initList()
	arg_2_0:layout()
end

function var_0_0.initList(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("list")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.list_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_3_0)

	arg_3_0.list_:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.list_:reload()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_rank"):enableOutline(cc.c4b(54, 161, 211, 255), 2)
	arg_4_0:nodeByName("text_score"):enableOutline(cc.c4b(54, 161, 211, 255), 2)
	arg_4_0:nodeByName("text_score_num"):enableOutline(cc.c4b(54, 161, 211, 255), 2)
	arg_4_0:nodeByName("text_rank"):setString(var_0_1:translation("SNOW_ACTIVITY_MY_RANK"))
	arg_4_0:nodeByName("text_score"):setString(var_0_1:translation("SNOW_ACTIVITY_MY_SCORE"))
	arg_4_0:nodeByName("text_score_num"):setString(math.floor(arg_4_0.myRank.score or 0))

	if arg_4_0.myRank.rank and arg_4_0.myRank.rank > 0 then
		local var_4_0 = xyd.AssetLoader.get():loadLabel(nil, "inscription_lev")

		var_4_0:setString(math.floor(arg_4_0.myRank.rank or 0))
		var_4_0:setScale(1.5)
		var_4_0:addTo(arg_4_0:nodeByName("container"))

		local var_4_1 = cc.p(arg_4_0:nodeByName("my_rank_pos"):getPosition())

		var_4_0:setPosition(cc.p(var_4_1))
	end

	xyd.imgEvent(arg_4_0:nodeByName("img_close"), function()
		xyd.WindowManager.get():closeWindow(arg_4_0)
	end)
end

function var_0_0.delegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = #arg_6_0.rankList

	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return var_6_0
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_1
		local var_6_2
		local var_6_3
		local var_6_4 = arg_6_0.list_:dequeueItem()

		if not var_6_4 then
			var_6_4 = arg_6_0.list_:newItem()
		else
			var_6_4:removeAllChildren()
		end

		local var_6_5 = display.newNode()

		var_6_5:setTouchSwallowEnabled(false)

		local var_6_6 = display.newNode()

		arg_6_0:initCell(var_6_6, arg_6_3)
		var_6_5:addChild(var_6_6)
		var_6_5:setContentSize(cc.size(arg_6_0.list_.viewRect_.width, var_6_6:getContentSize().height))
		var_6_4:setItemSize(arg_6_0.list_.viewRect_.width, var_6_6:getContentSize().height)
		var_6_4:addContent(var_6_5)

		return var_6_4
	end
end

function var_0_0.initCell(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_0.rankList[arg_7_2]
	local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/snow/snow_rank/rank_item.csb")
	local var_7_2 = var_7_1:getChildByName("container")
	local var_7_3 = var_7_2:getContentSize()

	var_7_1:addTo(arg_7_1)
	arg_7_1:setContentSize(var_7_3)

	var_7_0.playerInfo = var_7_0

	xyd.setPlayerAvatar(var_7_2:getChildByName("avatar"), var_7_0)

	if var_7_0.conquer_lev and var_7_0.conquer_lev > 0 then
		xyd.setConquerLev(var_7_0.conquer_lev, var_7_2:getChildByName("text_lev"), var_7_2:getChildByName("level_bg"), nil, nil, nil, nil, var_7_0.conquer_loop_id)
	else
		var_7_2:getChildByName("text_lev"):setString(var_7_0.lev)
	end

	var_7_2:getChildByName("text_name"):setString(var_7_0.player_name)
	var_7_2:getChildByName("text_region"):setString("S" .. xyd.getPlayerRegion(var_7_0.player_id))
	var_7_2:getChildByName("text_score_num"):setString(var_7_0.point)
	var_7_2:getChildByName("text_score"):setString(var_0_1:translation("SNOW_ACTIVITY_SCORE"))
	arg_7_0:initRankNum(var_7_2, arg_7_2)
end

function var_0_0.initRankNum(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0

	if arg_8_2 > 3 then
		var_8_0 = xyd.AssetLoader.get():loadLabel(nil, "inscription_lev")

		var_8_0:setString(arg_8_2)
		var_8_0:setScale(1.5)
	else
		var_8_0 = xyd.AssetLoader.get():loadSprite("windows/snow/snow_rank/rank0" .. arg_8_2 .. ".png")
	end

	var_8_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_0:addTo(arg_8_1)

	local var_8_1 = cc.p(arg_8_1:getChildByName("rank_num"):getPosition())

	var_8_0:setPosition(var_8_1)
end

return var_0_0
