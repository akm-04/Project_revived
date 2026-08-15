local var_0_0 = class("RagnarokRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.carry_rank = arg_1_2.carry_rank
	arg_1_0.score_rank = arg_1_2.score_rank
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar({
		isEcoBar = 0,
		show_rule = true
	})
	arg_2_0:layout(arg_2_1)
end

function var_0_0.layout(arg_3_0, arg_3_1)
	arg_3_0:nodeByName("txt_title_carry"):setString(var_0_1:translation("RAGNAROK_BOSS_RANK_1"))
	arg_3_0:nodeByName("txt_title_score"):setString(var_0_1:translation("RAGNAROK_BOSS_RANK_2"))

	local var_3_0 = arg_3_0:nodeByName("list_carry"):getContentSize()

	arg_3_0.carryList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list_carry")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.carryList:setDelegate(handler(arg_3_0, arg_3_0.carryDelegate))
	arg_3_0.carryList:reload()

	local var_3_1 = arg_3_0:nodeByName("list_score"):getContentSize()

	arg_3_0.scoreList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list_score")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.scoreList:setDelegate(handler(arg_3_0, arg_3_0.scoreDelegate))
	arg_3_0.scoreList:reload()

	local var_3_2 = arg_3_0:nodeByName("top_sidebar"):nodeByName("rule")

	xyd.nodeEventSample(var_3_2, nil, function()
		local var_4_0 = {}

		var_4_0.title_name = "RAGNAROK_BOSS_RANK_3"
		var_4_0.rule = "RAGNAROK_BOSS_RANK_4"
		var_4_0.style = xyd.RuleStyle.PURPLE

		xyd.WindowManager.get():openWindow("ragnarok_rank_rule", var_4_0)
	end)

	if arg_3_1.self_carry_rank > 0 then
		arg_3_0:nodeByName("my_carry"):addChild(arg_3_0:createMyItem(arg_3_1.self_carry_rank, arg_3_1.self_carry))
	end

	if arg_3_1.self_score_rank > 0 then
		arg_3_0:nodeByName("my_score"):addChild(arg_3_0:createMyItem(arg_3_1.self_score_rank, arg_3_1.self_score))
	end
end

function var_0_0.carryDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #arg_5_0.carry_rank
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0 = arg_5_0.carryList:dequeueItem()

		if var_5_0 then
			var_5_0:removeAllChildren()
		else
			var_5_0 = arg_5_0.carryList:newItem()
		end

		local var_5_1 = arg_5_0:createCarryItemContent(arg_5_3)
		local var_5_2 = var_5_1:getContentSize()

		var_5_0:addContent(var_5_1)
		var_5_0:setContentSize(var_5_2)
		var_5_0:setItemSize(var_5_2.width, var_5_2.height)

		return var_5_0
	end
end

function var_0_0.createCarryItemContent(arg_6_0, arg_6_1)
	local var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1203/ragnarok/rank_item.csb")
	local var_6_1 = var_6_0:getChildByName("container")
	local var_6_2 = var_6_1:getContentSize()
	local var_6_3 = arg_6_0.carry_rank[arg_6_1].player_info

	var_6_0:setContentSize(var_6_2)
	var_6_1:getChildByName("txt_score"):setString(var_0_1:translation("RAGNAROK_BOSS_SHOP_1"))

	var_6_3.playerInfo = var_6_3
	var_6_3.is_new = true

	xyd.setPlayerAvatar(var_6_1:getChildByName("avatar"), var_6_3)

	local var_6_4 = {
		lev = var_6_3.lev,
		conquerLev = var_6_3.conquer_lev,
		loopID = var_6_3.conquer_loop_id,
		fontColor = cc.c3b(102, 30, 30)
	}

	xyd.setLev(var_6_1:getChildByName("lev_container"), var_6_4)
	var_6_1:getChildByName("txt_name"):setString(var_6_3.player_name)
	var_6_1:getChildByName("txt_region"):setString("S" .. var_6_3.region)
	var_6_1:getChildByName("score"):setString(math.floor(arg_6_0.carry_rank[arg_6_1].score))

	if arg_6_1 <= 3 then
		var_6_1:getChildByName("rank"):setTexture("windows/activities/1203/ragnarok/rank/rank" .. arg_6_1 .. ".png")
		var_6_1:getChildByName("bg"):setTexture("windows/activities/1203/ragnarok/rank/bg_rank" .. arg_6_1 .. ".png")
		var_6_1:getChildByName("txt_rank"):setVisible(false)
	else
		var_6_1:getChildByName("rank"):setVisible(false)
		var_6_1:getChildByName("txt_rank"):setString(arg_6_1)
		var_6_1:getChildByName("txt_rank"):enableOutline(cc.c4b(89, 138, 174, 255), 2)
	end

	return var_6_0
end

function var_0_0.scoreDelegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return #arg_7_0.score_rank
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_0 = arg_7_0.scoreList:dequeueItem()

		if var_7_0 then
			var_7_0:removeAllChildren()
		else
			var_7_0 = arg_7_0.scoreList:newItem()
		end

		local var_7_1 = arg_7_0:createScoreItemContent(arg_7_3)
		local var_7_2 = var_7_1:getContentSize()

		var_7_0:addContent(var_7_1)
		var_7_0:setContentSize(var_7_2)
		var_7_0:setItemSize(var_7_2.width, var_7_2.height)

		return var_7_0
	end
end

function var_0_0.createScoreItemContent(arg_8_0, arg_8_1)
	local var_8_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1203/ragnarok/rank_item.csb")
	local var_8_1 = var_8_0:getChildByName("container")
	local var_8_2 = var_8_1:getContentSize()
	local var_8_3 = arg_8_0.score_rank[arg_8_1].player_info

	var_8_0:setContentSize(var_8_2)
	var_8_1:getChildByName("txt_score"):setString(var_0_1:translation("RAGNAROK_BOSS_SHOP_1"))

	var_8_3.playerInfo = var_8_3
	var_8_3.is_new = true

	xyd.setPlayerAvatar(var_8_1:getChildByName("avatar"), var_8_3)

	local var_8_4 = {
		lev = var_8_3.lev,
		conquerLev = var_8_3.conquer_lev,
		loopID = var_8_3.conquer_loop_id,
		fontColor = cc.c3b(102, 30, 30)
	}

	xyd.setLev(var_8_1:getChildByName("lev_container"), var_8_4)
	var_8_1:getChildByName("txt_name"):setString(var_8_3.player_name)
	var_8_1:getChildByName("txt_region"):setString("S" .. var_8_3.region)
	var_8_1:getChildByName("score"):setString(math.floor(arg_8_0.score_rank[arg_8_1].score))

	if arg_8_1 <= 3 then
		var_8_1:getChildByName("rank"):setTexture("windows/activities/1203/ragnarok/rank/rank" .. arg_8_1 .. ".png")
		var_8_1:getChildByName("bg"):setTexture("windows/activities/1203/ragnarok/rank/bg_rank" .. arg_8_1 .. ".png")
		var_8_1:getChildByName("txt_rank"):setVisible(false)
	else
		var_8_1:getChildByName("rank"):setVisible(false)
		var_8_1:getChildByName("txt_rank"):setString(arg_8_1)
		var_8_1:getChildByName("txt_rank"):enableOutline(cc.c4b(89, 138, 174, 255), 2)
	end

	return var_8_0
end

function var_0_0.createMyItem(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1203/ragnarok/rank_item.csb")
	local var_9_1 = var_9_0:getChildByName("container")
	local var_9_2 = {}

	var_9_1:getChildByName("txt_score"):setString(var_0_1:translation("RAGNAROK_BOSS_SHOP_1"))

	var_9_2.avatar_id = arg_9_0.selfPlayer:getMyCurrentAvatarID()
	var_9_2.avatar_frame_id = arg_9_0.selfPlayer.avatarFrame
	var_9_2.lev = arg_9_0.selfPlayer.lev
	var_9_2.conquer_lev = arg_9_0.selfPlayer.conquerLev
	var_9_2.conquer_loop_id = arg_9_0.selfPlayer.conquerLoopID
	var_9_2.player_id = arg_9_0.selfPlayer.playerID
	var_9_2.player_name = arg_9_0.selfPlayer.playerName
	var_9_2.region = arg_9_0.selfPlayer.region
	var_9_2.playerInfo = var_9_2

	xyd.setPlayerAvatar(var_9_1:getChildByName("avatar"), var_9_2)

	local var_9_3 = {
		lev = var_9_2.lev,
		conquerLev = var_9_2.conquer_lev,
		loopID = var_9_2.conquer_loop_id,
		fontColor = cc.c3b(102, 30, 30)
	}

	xyd.setLev(var_9_1:getChildByName("lev_container"), var_9_3)
	var_9_1:getChildByName("txt_name"):setString(var_9_2.player_name)
	var_9_1:getChildByName("txt_region"):setString("S" .. var_9_2.region)
	var_9_1:getChildByName("score"):setString(math.floor(arg_9_2))

	if arg_9_1 <= 3 then
		var_9_1:getChildByName("rank"):setTexture("windows/activities/1203/ragnarok/rank/rank" .. arg_9_1 .. ".png")
		var_9_1:getChildByName("bg"):setTexture("windows/activities/1203/ragnarok/rank/bg_rank" .. arg_9_1 .. ".png")
		var_9_1:getChildByName("txt_rank"):setVisible(false)
	else
		var_9_1:getChildByName("rank"):setVisible(false)
		var_9_1:getChildByName("txt_rank"):setString(arg_9_1)
		var_9_1:getChildByName("txt_rank"):enableOutline(cc.c4b(89, 138, 174, 255), 2)
	end

	return var_9_0
end

function var_0_0.scrollListener(arg_10_0, arg_10_1)
	if arg_10_1.name == "began" then
		arg_10_0.scrollViewMoved_ = false
		arg_10_0.prevY_ = arg_10_1.y
	elseif arg_10_1.name == "moved" and 20 <= math.abs(arg_10_1.y - arg_10_0.prevY_) then
		arg_10_0.scrollViewMoved_ = true
	end
end

return var_0_0
