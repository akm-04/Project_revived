local var_0_0 = class("TutorRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.activityTutorRank
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.gift

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.rankData = arg_1_2.rankList
	arg_1_0.myRank = arg_1_2.myRank
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("rank_txt"):setString(var_0_2:translation("ACTIVITY_TUTOR_TEXT1"))
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_rule"), nil, function(arg_5_0)
		xyd.WindowManager.get():openWindow("tutor_rank_rule_window")
	end)

	if not arg_4_0.rankData or not next(arg_4_0.rankData) then
		return
	end

	local var_4_0 = arg_4_0:nodeByName("rank_list"):getContentSize()

	arg_4_0.rankList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("rank_list")):onScroll(handler(arg_4_0, arg_4_0.scrollListener)):pos(0, 0)

	arg_4_0.rankList:setDelegate(handler(arg_4_0, arg_4_0.rankDelegate))
	arg_4_0.rankList:reload()
	arg_4_0:addMyRank(arg_4_0:nodeByName("rank_self"))
end

function var_0_0.rankDelegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = math.min(100, #arg_6_0.rankData)

	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return var_6_0
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		if var_6_0 < arg_6_3 then
			return nil
		end

		return arg_6_0:addRankItem(arg_6_3)
	end
end

function var_0_0.addRankItem(arg_7_0, arg_7_1)
	if not next(arg_7_0.rankData) then
		return nil
	end

	local var_7_0 = arg_7_0.rankList:dequeueItem()
	local var_7_1 = arg_7_0.rankData[arg_7_1].player_info
	local var_7_2 = arg_7_0.rankData[arg_7_1].point

	if not var_7_0 then
		var_7_0 = arg_7_0.rankList:newItem()
	else
		var_7_0:removeAllChildren(true)
	end

	local var_7_3 = display.newNode()
	local var_7_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/tutor/tutor_rank_item.csb")
	local var_7_5 = var_7_4:getChildByName("container")
	local var_7_6 = var_7_5:getChildByName("rank_val_1")
	local var_7_7 = var_7_5:getChildByName("rank_val_2")
	local var_7_8 = var_7_5:getChildByName("rank_val_3")

	if arg_7_1 == 1 then
		var_7_6:setVisible(true)
		var_7_7:setVisible(false)
		var_7_8:setVisible(false)
	elseif arg_7_1 == 2 then
		var_7_6:setVisible(false)
		var_7_7:setVisible(true)
		var_7_8:setVisible(false)
	elseif arg_7_1 == 3 then
		var_7_6:setVisible(false)
		var_7_7:setVisible(false)
		var_7_8:setVisible(true)
	else
		var_7_6:setVisible(false)
		var_7_7:setVisible(false)
		var_7_8:setVisible(false)

		local var_7_9 = xyd.AssetLoader.get():loadLabel(nil, "rankFonts")

		var_7_9:setString(arg_7_1)
		var_7_9:setAnchorPoint(cc.p(0.5, 0.5))
		var_7_9:setPosition(var_7_5:getChildByName("rank_val_3"):getPosition())
		var_7_9:addTo(var_7_5)
	end

	var_7_5:getChildByName("txt_score"):setString(string.format(var_0_2:translation("ACTIVITY_TUTOR_RANK_SCORE_TEXT"), var_7_2))
	var_7_5:getChildByName("txt_level"):setString(var_7_1.lev)
	var_7_5:getChildByName("txt_name"):setString(var_7_1.player_name)
	var_7_5:getChildByName("avatar"):setScale(0.9333333333333333)

	local function var_7_10(arg_8_0)
		if arg_8_0.name == "began" then
			arg_7_0.isOpenPlayerInfoWindow = false

			return true
		elseif arg_8_0.name == "ended" and not arg_7_0.scrollViewMoved_ then
			arg_7_0.isOpenPlayerInfoWindow = true

			xyd.openPersonDisplayWindow(var_7_1)
		end
	end

	xyd.setPlayerAvatar(var_7_5:getChildByName("avatar"), {
		showLevel = false,
		avatar_id = var_7_1.avatar_id,
		avatar_frame_id = var_7_1.avatar_frame_id,
		callback = var_7_10
	})
	arg_7_0:addRankGift(var_7_5:getChildByName("list"), arg_7_1)
	var_7_3:addChild(var_7_4)
	var_7_3:setContentSize(cc.size(arg_7_0.rankList.viewRect_.width, var_7_5:getContentSize().height))
	var_7_0:addContent(var_7_3)
	var_7_0:setItemSize(arg_7_0.rankList.viewRect_.width, var_7_3:getContentSize().height + 5)

	return var_7_0
end

function var_0_0.addRankGift(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1:getContentSize().height
	local var_9_1 = 5
	local var_9_2 = var_0_1:getRank()
	local var_9_3
	local var_9_4

	if not var_9_2 or #var_9_2 == 0 then
		return
	end

	for iter_9_0, iter_9_1 in pairs(var_9_2) do
		if arg_9_2 >= iter_9_1[1] and arg_9_2 <= iter_9_1[2] then
			var_9_3 = var_0_1:gift(iter_9_0)
			var_9_4 = var_0_1:title(iter_9_0)
		end
	end

	if not var_9_3 then
		return
	end

	local var_9_5 = var_0_3:items(var_9_3)
	local var_9_6 = var_0_3:itemNum(var_9_3)

	for iter_9_2 = 1, #var_9_5 do
		local var_9_7 = display.newNode()
		local var_9_8 = xyd.tables.item:type(var_9_5[iter_9_2])

		var_9_7:setContentSize(var_9_0, var_9_0)
		xyd.setItemBorder(var_9_7, var_9_5[iter_9_2], false, false, var_9_6[iter_9_2])
		var_9_7:addTo(arg_9_1)
		var_9_7:setAnchorPoint(0, 0)
		var_9_7:setPosition((iter_9_2 - 1) * (var_9_0 + var_9_1), 0)

		local var_9_9 = {
			id = var_9_5[iter_9_2],
			lev = xyd.tables.item:level(var_9_5[iter_9_2])
		}

		if xyd.tables.item:type(var_9_5[iter_9_2]) == -1 then
			var_9_9.tipsType = 0
			var_9_9.desc1 = xyd.tables.hero:getDes(var_9_5[iter_9_2])
		elseif specialItem then
			var_9_9.tipsType = 1
			var_9_9.id = -3
		else
			var_9_9.tipsType = 1
			var_9_9.desc1 = xyd.tables.item:desc1(var_9_5[iter_9_2])
			var_9_9.desc2 = xyd.tables.item:desc2(var_9_5[iter_9_2])
		end

		var_9_9.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_9_5[iter_9_2])
		var_9_9.name = xyd.tables.item:name(var_9_5[iter_9_2])

		arg_9_0:addTips(var_9_7, var_9_9)
	end

	if var_9_4 and var_9_4 ~= 0 then
		local var_9_10 = {
			unique_id = 0,
			title_id = var_9_4
		}
		local var_9_11 = display.newNode()

		var_9_11:setContentSize(285, 85)
		var_9_11:setScale(0.6)
		xyd.setPlayerTitle(var_9_11, var_9_10)
		var_9_11:addTo(arg_9_1)
		var_9_11:setAnchorPoint(0, 0)
		var_9_11:setPosition(#var_9_5 * (var_9_0 + var_9_1) + 50, 20)
	end
end

function var_0_0.addMyRank(arg_10_0, arg_10_1)
	if not next(arg_10_0.myRank) then
		return
	end

	local var_10_0 = arg_10_0.myRank.rank

	if var_10_0 == 0 then
		return
	end

	local var_10_1 = arg_10_0.myRank.score
	local var_10_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/tutor/tutor_rank_item.csb"):getChildByName("container")
	local var_10_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/tutor/tutor_rank_item.csb")
	local var_10_4 = var_10_3:getChildByName("container")

	var_10_4:getChildByName("bg"):setVisible(false)

	local var_10_5 = var_10_4:getChildByName("rank_val_1")
	local var_10_6 = var_10_4:getChildByName("rank_val_2")
	local var_10_7 = var_10_4:getChildByName("rank_val_3")

	if var_10_0 == 1 then
		var_10_5:setVisible(true)
		var_10_6:setVisible(false)
		var_10_7:setVisible(false)
	elseif var_10_0 == 2 then
		var_10_5:setVisible(false)
		var_10_6:setVisible(true)
		var_10_7:setVisible(false)
	elseif var_10_0 == 3 then
		var_10_5:setVisible(false)
		var_10_6:setVisible(false)
		var_10_7:setVisible(true)
	else
		var_10_5:setVisible(false)
		var_10_6:setVisible(false)
		var_10_7:setVisible(false)

		local var_10_8 = xyd.AssetLoader.get():loadLabel(nil, "rankFonts")

		var_10_8:setString(var_10_0)
		var_10_8:setAnchorPoint(cc.p(0.5, 0.5))
		var_10_8:setPosition(var_10_4:getChildByName("rank_val_3"):getPosition())
		var_10_8:addTo(var_10_4)
	end

	var_10_4:getChildByName("txt_score"):setString("Points：" .. var_10_1)
	var_10_4:getChildByName("txt_level"):setString(arg_10_0.selfPlayer.lev)
	var_10_4:getChildByName("txt_name"):setString(arg_10_0.selfPlayer.playerName)
	var_10_4:getChildByName("avatar"):setScale(0.9333333333333333)
	xyd.setPlayerAvatar(var_10_4:getChildByName("avatar"), {
		showLevel = false,
		avatar_id = arg_10_0.selfPlayer:getMyCurrentAvatarID(),
		avatar_frame_id = arg_10_0.selfPlayer.avatarFrame
	})
	arg_10_0:addRankGift(var_10_4:getChildByName("list"), var_10_0)
	var_10_3:addTo(arg_10_1)
	var_10_3:setAnchorPoint(0, 0)
	var_10_3:setPosition(0, -12)
end

function var_0_0.scrollListener(arg_11_0, arg_11_1)
	if arg_11_1.name == "began" then
		arg_11_0.scrollViewMoved_ = false
		arg_11_0.prevY_ = arg_11_1.y
	elseif arg_11_1.name == "moved" and 10 <= math.abs(arg_11_1.y - arg_11_0.prevY_) then
		arg_11_0.scrollViewMoved_ = true
	end
end

return var_0_0
