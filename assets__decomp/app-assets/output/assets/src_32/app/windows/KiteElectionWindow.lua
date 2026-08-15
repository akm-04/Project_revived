local var_0_0 = class("KiteElectionWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/kite_king/election/item.csb")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.kite = xyd.ModelManager.get():loadModel(xyd.ModelType.KITE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.isVoted = 0
	arg_1_0.electionListItems = {}
	arg_1_0.playerLev = arg_1_0.selfPlayer.lev
	arg_1_0.playerId = arg_1_0.selfPlayer.playerID
	arg_1_0.playerName = arg_1_0.selfPlayer.playerName
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.electionList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, 880, 340),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("scroll")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.electionList:setDelegate(handler(arg_2_0, arg_2_0.electionListDelegate))
	arg_2_0:nodeByName("close"):addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			local var_3_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_3_0, false)
			xyd.WindowManager.get():closeWindow(arg_2_0)
		end
	end)
	arg_2_0:nodeByName("check_award_btn"):setTouchSwallowEnabled(true)
	arg_2_0:nodeByName("check_award_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("kite_award")
		end
	end)

	arg_2_0.nodeX = arg_2_0.electionList.scrollNode:getPositionX()
	arg_2_0.nodeY = arg_2_0.electionList.scrollNode:getPositionY()

	arg_2_0.kite:getElectionList({}, function(arg_5_0, arg_5_1)
		if arg_5_0 == xyd.error.OK then
			arg_2_0.electionListItems = arg_5_1.rank_list
			arg_2_0.isVoted = arg_5_1.self_info.daily_voted_flag
			arg_2_0.have_signed_up = arg_5_1.self_info.have_signed_up
			arg_2_0.rank = arg_5_1.self_rank
			arg_2_0.voteNum = arg_5_1.self_info.votes_num

			arg_2_0:updateSelfInfo()
			arg_2_0.electionList:reload()

			if #arg_2_0.electionListItems == 0 then
				arg_2_0:nodeByName("no_one_participate_txt"):setString(var_0_1:translation("NO_ONE_PARTICIPATE"))
			else
				arg_2_0:nodeByName("no_one_participate_txt"):setVisible(false)
			end
		end
	end)
end

function var_0_0.updateSelfInfo(arg_6_0)
	if arg_6_0.have_signed_up == 1 then
		arg_6_0:nodeByName("rank_txt"):setVisible(true)
		arg_6_0:nodeByName("vote_txt"):setVisible(true)
		arg_6_0:nodeByName("participate_btn"):setVisible(false)
		arg_6_0:nodeByName("rank_txt"):setString(var_0_1:translation("ACTIVITY_KITE_MY_RANK"))
		arg_6_0:nodeByName("vote_txt"):setString(string.format(var_0_1:translation("ACTIVITY_KITE_MY_VOTE"), arg_6_0.voteNum))
		arg_6_0:addRankContent(arg_6_0:nodeByName("rank_pos"), arg_6_0.rank)
	else
		arg_6_0:nodeByName("participate_btn"):setTouchSwallowEnabled(true)
		arg_6_0:nodeByName("participate_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.TouchEventType.ended then
				if arg_6_0.playerLev < 20 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("RANK_NOT_ENOUGH")
					})

					return
				elseif arg_6_0.kite.total_send < 10 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("SEND_KITES_NOT_ENOUGH")
					})

					return
				end

				xyd.WindowManager.get():openWindow("kite_participate")
			end
		end)
		arg_6_0:nodeByName("rank_txt"):setVisible(false)
		arg_6_0:nodeByName("vote_txt"):setVisible(false)
	end
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super:didOpen(arg_8_1)
	arg_8_0:addBlockLayer(cc.c4b(0, 0, 0, 225), true)
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevY_ = arg_9_1.y
	elseif arg_9_1.name == "moved" and 10 <= math.abs(arg_9_1.y - arg_9_0.prevY_) then
		arg_9_0.scrollViewMoved_ = true
	end
end

function var_0_0.electionListDelegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return #arg_10_0.electionListItems
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_0
		local var_10_1 = arg_10_0.electionList:dequeueItem()

		if not var_10_1 then
			var_10_1 = arg_10_0.electionList:newItem()
		else
			var_10_1:removeAllChildren(false)
		end

		local var_10_2 = arg_10_0:createListContent(arg_10_3)
		local var_10_3 = var_10_2:getWidth()
		local var_10_4 = var_10_2:getHeight()

		var_10_1:setItemSize(var_10_3, var_10_4)
		var_10_1:addContent(var_10_2)
		var_10_2:getChildByName("source"):getChildByName("container"):getChildByName("vote_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
			if arg_11_1 == ccui.TouchEventType.ended then
				if arg_10_0.playerLev < 20 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("RANK_NOT_ENOUGH_TO_VOTE")
					})
				elseif arg_10_0.isVoted == 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("HAVE_VOTED")
					})
				else
					local var_11_0 = {
						player_id = arg_10_0.electionListItems[arg_10_3].player_id
					}

					arg_10_0.kite:kiteKingVote(var_11_0, function(arg_12_0, arg_12_1)
						if arg_12_0 == xyd.error.OK then
							arg_10_0.isVoted = arg_12_1.self_info.daily_voted_flag
							arg_10_0.electionListItems = arg_12_1.rank_list
							arg_10_0.rank = arg_12_1.self_rank
							arg_10_0.voteNum = arg_12_1.self_info.votes_num

							arg_10_0.electionList:reload()
							arg_10_0:updateSelfInfo()
						end
					end)
				end
			end
		end)

		return var_10_1
	end
end

function var_0_0.createListContent(arg_13_0, arg_13_1)
	local var_13_0 = arg_13_0.electionListItems[arg_13_1]
	local var_13_1 = display.newNode()
	local var_13_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/kite_king/election/item.csb")
	local var_13_3 = var_13_2:getChildByName("container")

	var_13_1:setAnchorPoint(cc.p(0, 0))
	var_13_1:setPosition(0, 0)

	local var_13_4 = var_13_3:getChildByName("bg_level")

	if var_13_0.conquer_lev and var_13_0.conquer_lev > 0 then
		xyd.setConquerLev(var_13_0.conquer_lev, var_13_4:getChildByName("lev_txt"), var_13_4:getChildByName("level_bg"), nil, nil, nil, nil, var_13_0.conquer_loop_id)
	else
		var_13_4:getChildByName("lev_txt"):setString(var_13_0.lev)
	end

	var_13_4:getChildByName("player_name"):setString(var_13_0.player_name)
	var_13_4:getChildByName("player_server"):setString("S" .. math.floor(var_13_0.player_id / 100000))
	var_13_3:getChildByName("manifestos"):setString(var_13_0.content)
	var_13_3:getChildByName("vote_txt"):setString(string.format(var_0_1:translation("TOTAL_VOTES"), var_13_0.votes_num))

	local var_13_5 = {
		avatar_id = var_13_0.avatar_id,
		avatar_frame_id = var_13_0.avatar_frame_id,
		playerInfo = {
			player_id = var_13_0.player_id
		}
	}

	xyd.setPlayerAvatar(var_13_3:getChildByName("avtar_container"), var_13_5)
	arg_13_0:addRankContent(var_13_3:getChildByName("rank_pos"), arg_13_1)
	var_13_2:addTo(var_13_1)
	var_13_2:setAnchorPoint(cc.p(0, 0))
	var_13_1:setContentSize(var_13_3:getContentSize())
	var_13_2:setName("source")

	return var_13_1
end

function var_0_0.addRankContent(arg_14_0, arg_14_1, arg_14_2)
	arg_14_1:removeAllChildren()

	local var_14_0

	if arg_14_2 <= 3 then
		var_14_0 = xyd.AssetLoader.get():loadSprite("windows/single_day/rank/" .. arg_14_2 .. ".png")
	else
		var_14_0 = xyd.AssetLoader.get():loadLabel(nil, "tacit_rank")

		var_14_0:setAnchorPoint(cc.p(0.5, 0.5))
		var_14_0:setString(arg_14_2)
	end

	var_14_0:addTo(arg_14_1)
end

return var_0_0
