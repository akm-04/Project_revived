local var_0_0 = class("PopularityVoteRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 4

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.myRankInfo = arg_1_2.my_rank_info or {}
	arg_1_0.rankList = arg_1_2.rank_list or {}
	arg_1_0.tableID = arg_1_2.table_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initList()
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
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
	arg_4_0:nodeByName("text_top_tips"):setString(string.format(var_0_1:translation("VOTE_RANK_TIPS_1"), xyd.tables.hero:name(arg_4_0.tableID)))
	arg_4_0:nodeByName("text_rank"):setString(var_0_1:translation("VOTE_RANK_TIPS_2"))
	arg_4_0:nodeByName("text_ticket"):setString(var_0_1:translation("VOTE_RANK_TIPS_3"))
	arg_4_0:nodeByName("my_rank_num"):setString(arg_4_0.myRankInfo.rank or 0)
	arg_4_0:nodeByName("text_ticket_num"):setString(arg_4_0.myRankInfo.vote_num or 0)
	arg_4_0:nodeByName("text_rank"):enableOutline(cc.c4b(85, 137, 243, 255), 2)
	arg_4_0:nodeByName("text_ticket"):enableOutline(cc.c4b(85, 137, 243, 255), 2)
	arg_4_0:nodeByName("my_rank_num"):enableOutline(cc.c4b(85, 137, 243, 255), 2)
	arg_4_0:nodeByName("text_ticket_num"):enableOutline(cc.c4b(85, 137, 243, 255), 2)

	if #arg_4_0.rankList == 0 then
		arg_4_0:nodeByName("text_mid_tips"):setString(var_0_1:translation("VOTE_RANK_TIPS_4"))
		arg_4_0:nodeByName("text_mid_tips"):setVisible(true)
	else
		arg_4_0:nodeByName("text_mid_tips"):setVisible(false)
	end
end

function var_0_0.delegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = #arg_5_0.rankList

	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return var_5_0
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_1
		local var_5_2
		local var_5_3
		local var_5_4 = arg_5_0.list_:dequeueItem()

		if not var_5_4 then
			var_5_4 = arg_5_0.list_:newItem()
		else
			var_5_4:removeAllChildren()
		end

		local var_5_5 = display.newNode()

		var_5_5:setTouchSwallowEnabled(false)

		local var_5_6 = display.newNode()

		arg_5_0:initCell(var_5_6, arg_5_3)
		var_5_5:addChild(var_5_6)
		var_5_5:setContentSize(cc.size(arg_5_0.list_.viewRect_.width, var_5_6:getContentSize().height))
		var_5_4:setItemSize(arg_5_0.list_.viewRect_.width, var_5_6:getContentSize().height)
		var_5_4:addContent(var_5_5)

		return var_5_4
	end
end

function var_0_0.initCell(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_0.rankList[arg_6_2]
	local var_6_1 = var_6_0.player_info
	local var_6_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/popularity_contest/rank_item_2.csb")
	local var_6_3 = var_6_2:getChildByName("container")
	local var_6_4 = var_6_3:getContentSize()

	var_6_2:addTo(arg_6_1)
	arg_6_1:setContentSize(var_6_4)

	var_6_1.playerInfo = var_6_1

	xyd.setPlayerAvatar(var_6_3:getChildByName("avatar"), var_6_1)

	if var_6_1.conquer_lev and var_6_1.conquer_lev > 0 then
		xyd.setConquerLev(var_6_1.conquer_lev, var_6_3:getChildByName("text_lev"), var_6_3:getChildByName("level_bg"), nil, nil, nil, nil, var_6_1.conquer_loop_id)
	else
		var_6_3:getChildByName("text_lev"):setString(var_6_1.lev)
	end

	var_6_3:getChildByName("text_name"):setString(var_6_1.player_name)
	var_6_3:getChildByName("text_region"):setString("S" .. xyd.getPlayerRegion(var_6_1.player_id))
	var_6_3:getChildByName("text_ticket_num"):setString(var_6_0.vote_num)
	var_6_3:getChildByName("text_ticket"):setString(var_0_1:translation("VOTE_RANK_TIPS_3"))
	arg_6_0:initRankNum(var_6_3, arg_6_2)
end

function var_0_0.initRankNum(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0

	if arg_7_2 > 3 then
		var_7_0 = xyd.AssetLoader.get():loadLabel(nil, "inscription_lev")

		var_7_0:setString(arg_7_2)
		var_7_0:setScale(1.5)
	else
		var_7_0 = xyd.AssetLoader.get():loadSprite("windows/zhugeliang/rank0" .. arg_7_2 .. ".png")
	end

	var_7_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_7_0:addTo(arg_7_1)

	local var_7_1 = cc.p(arg_7_1:getChildByName("rank_num"):getPosition())

	var_7_0:setPosition(var_7_1)
end

return var_0_0
