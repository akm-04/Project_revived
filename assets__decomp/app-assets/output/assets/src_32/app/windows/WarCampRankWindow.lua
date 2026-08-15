local var_0_0 = class("WarCampRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 4

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.warCamp_ = xyd.ModelManager.get():loadModel(xyd.ModelType.WAR_CAMP)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.rankData = arg_1_2
	arg_1_0.rankList1 = arg_1_2.list1
	arg_1_0.rankList2 = arg_1_2.list2
	arg_1_0.isHarm = arg_1_2.isHarm or false
	arg_1_0.totalScores = arg_1_2.total_scores
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addBlockLayerWithNoTouchEvent()

	arg_2_0.myCamp = arg_2_0.warCamp_:getCampType()

	arg_2_0:initList()
	arg_2_0:layout()
end

function var_0_0.initList(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("list_left")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.leftList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_3_0)

	arg_3_0.leftList_:setDelegate(handler(arg_3_0, arg_3_0.delegateLeft))
	arg_3_0.leftList_:reload()

	local var_3_2 = arg_3_0:nodeByName("list_right")
	local var_3_3 = var_3_2:getContentSize()

	arg_3_0.rightList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_3.width, var_3_3.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_3_2)

	arg_3_0.rightList_:setDelegate(handler(arg_3_0, arg_3_0.delegateRight))
	arg_3_0.rightList_:reload()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_rank"):setString(var_0_1:translation("WAR_CAMP_RANK_TIPS_2"))

	local var_4_0 = 0
	local var_4_1 = 0

	if arg_4_0.myCamp == xyd.WarCampSelectType.LEFT then
		var_4_1 = arg_4_0.rankData.self_rank1

		local var_4_2 = arg_4_0.rankData.self_score1
	else
		var_4_1 = arg_4_0.rankData.self_rank2

		local var_4_3 = arg_4_0.rankData.self_score2
	end

	local var_4_4 = {
		player_id = arg_4_0.selfPlayer.playerID,
		avatar_id = arg_4_0.selfPlayer.avatarId,
		avatar_frame_id = arg_4_0.selfPlayer.avatarFrame
	}

	if arg_4_0.totalScores then
		for iter_4_0 = 1, 2 do
			arg_4_0:nodeByName("damage_" .. iter_4_0):setString(arg_4_0.totalScores[iter_4_0])
			arg_4_0:nodeByName("damage_" .. iter_4_0):enableOutline(cc.c4b(233, 50, 12, 255), 2)
			arg_4_0:nodeByName("damage_txt_" .. iter_4_0):enableOutline(cc.c4b(233, 50, 12, 255), 2)
		end

		xyd.setPlayerAvatar(arg_4_0:nodeByName("avatar"), var_4_4)
	else
		for iter_4_1 = 1, 2 do
			arg_4_0:nodeByName("block_" .. iter_4_1):setVisible(false)
		end
	end

	arg_4_0:initRankNum(arg_4_0:nodeByName("container"), arg_4_0:nodeByName("my_rank_pos"), var_4_1)
end

function var_0_0.delegateLeft(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = #arg_5_0.rankList1

	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return var_5_0
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_1
		local var_5_2
		local var_5_3
		local var_5_4 = arg_5_0.leftList_:dequeueItem()

		if not var_5_4 then
			var_5_4 = arg_5_0.leftList_:newItem()
		else
			var_5_4:removeAllChildren()
		end

		local var_5_5 = display.newNode()

		var_5_5:setTouchSwallowEnabled(false)

		local var_5_6 = display.newNode()

		arg_5_0:initCell(var_5_6, arg_5_3, true)
		var_5_5:addChild(var_5_6)
		var_5_5:setContentSize(cc.size(arg_5_0.leftList_.viewRect_.width, var_5_6:getContentSize().height))
		var_5_4:setItemSize(arg_5_0.leftList_.viewRect_.width, var_5_6:getContentSize().height)
		var_5_4:addContent(var_5_5)

		return var_5_4
	end
end

function var_0_0.delegateRight(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = #arg_6_0.rankList2

	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return var_6_0
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_1
		local var_6_2
		local var_6_3
		local var_6_4 = arg_6_0.leftList_:dequeueItem()

		if not var_6_4 then
			var_6_4 = arg_6_0.leftList_:newItem()
		else
			var_6_4:removeAllChildren()
		end

		local var_6_5 = display.newNode()

		var_6_5:setTouchSwallowEnabled(false)

		local var_6_6 = display.newNode()

		arg_6_0:initCell(var_6_6, arg_6_3, false)
		var_6_5:addChild(var_6_6)
		var_6_5:setContentSize(cc.size(arg_6_0.leftList_.viewRect_.width, var_6_6:getContentSize().height))
		var_6_4:setItemSize(arg_6_0.leftList_.viewRect_.width, var_6_6:getContentSize().height)
		var_6_4:addContent(var_6_5)

		return var_6_4
	end
end

function var_0_0.initCell(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = {}

	if arg_7_3 then
		var_7_0 = arg_7_0.rankList1[arg_7_2]
	else
		var_7_0 = arg_7_0.rankList2[arg_7_2]
	end

	local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/war_camp/rank/rank_item.csb")
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

	if arg_7_0.isHarm then
		var_7_2:getChildByName("text_coin"):setString(var_0_1:translation("WAR_CAMP_RANK_TIPS_3"))
	else
		var_7_2:getChildByName("text_coin"):setString(var_0_1:translation("WAR_CAMP_RANK_TIPS_1"))
	end

	var_7_2:getChildByName("text_coin_num"):setString(var_7_0.score)
	arg_7_0:initRankNum(var_7_2, var_7_2:getChildByName("rank_num"), arg_7_2)
end

function var_0_0.initRankNum(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0
	local var_8_1 = 0

	if arg_8_3 == 0 or arg_8_3 > 3 then
		var_8_0 = xyd.AssetLoader.get():loadLabel(nil, "inscription_lev")

		var_8_0:setString(arg_8_3)
		var_8_0:setScale(1.5)

		var_8_1 = 5

		arg_8_1:getChildByName("bg_ph"):setVisible(false)
	else
		var_8_0 = xyd.AssetLoader.get():loadSprite("windows/zhugeliang/rank0" .. arg_8_3 .. ".png")
	end

	var_8_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_0:addTo(arg_8_1)

	local var_8_2 = cc.p(arg_8_2:getPosition())

	var_8_0:setPosition(var_8_2.x, var_8_2.y + var_8_1)
end

return var_0_0
