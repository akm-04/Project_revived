local var_0_0 = class("IndiegogoSendOrderWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.indiegogoTable
local var_0_4 = 100
local var_0_5 = 64
local var_0_6 = 30
local var_0_7 = 17
local var_0_8 = 10

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.tableID = arg_1_2.table_id
	arg_1_0.friendList = arg_1_0.socialSystem.friendlist
	arg_1_0.noticePlayers = {}
	arg_1_0.subSelectBox = {}
	arg_1_0.noticeAllPlayers = false
	arg_1_0.noticeWorld = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initNoticePlayers()
	arg_2_0:layout()
end

function var_0_0.initNoticePlayers(arg_3_0)
	for iter_3_0 = #arg_3_0.friendList, 1, -1 do
		if arg_3_0.friendList[iter_3_0].lev < xyd.tables.misc.crowdFundLevLimit then
			table.remove(arg_3_0.friendList, iter_3_0)
		else
			arg_3_0.noticePlayers[arg_3_0.friendList[iter_3_0].player_id] = 0
		end
	end
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("friend_container")
	local var_4_1 = var_4_0:getContentSize()

	arg_4_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_1.width, var_4_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_4_0):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.delegate))

	local var_4_2 = arg_4_0:nodeByName("line_1")

	var_0_1.new({
		size = var_4_2:getWidth(),
		type = xyd.SplitlineType.SOLID
	}):addTo(var_4_2)

	local var_4_3 = arg_4_0:nodeByName("line_2")

	var_0_1.new({
		size = var_4_3:getWidth(),
		type = xyd.SplitlineType.SOLID
	}):addTo(var_4_3)
	arg_4_0:nodeByName("btn_sure"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = false

			if var_0_3:issueStone(arg_4_0.tableID) > arg_4_0.player.spiritStone then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("INDIEGOGO_COIN_NOT_ENOUGH_1")
				})

				return true
			end

			local var_5_1 = ""

			if arg_4_0.noticeAllPlayers then
				var_5_1 = 1
			else
				for iter_5_0, iter_5_1 in pairs(arg_4_0.noticePlayers) do
					if iter_5_1 == 1 then
						var_5_1 = var_5_1 .. string.format("%d|", iter_5_0)
					end
				end
			end

			local var_5_2 = {
				table_id = arg_4_0.tableID,
				notice_players = var_5_1
			}

			if arg_4_0.noticeWorld then
				var_5_2.is_all_server = 1
			end

			arg_4_0.socialSystem:releaseFunding(var_5_2, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					local var_6_0 = xyd.WindowManager.get():getWindow("indiegogo")

					if var_6_0 then
						var_6_0.fundingList = arg_6_1.funding_list
						var_6_0.releaseList = arg_6_1.release_list

						var_6_0:swapFundingState(xyd.FUNDING_STATE.System)
						var_6_0:updateSelfCoin()
						var_6_0:initSendOrder()
					end

					xyd.WindowManager.get():closeWindow(arg_4_0)
				end
			end)
		end
	end)
	arg_4_0:nodeByName("btn_cancel"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)

	local var_4_4 = arg_4_0:nodeByName("select_box")

	arg_4_0:nodeByName("select"):setVisible(false)
	var_4_4:setTouchEnabled(true)
	var_4_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			return true
		elseif arg_8_0.name == "ended" then
			if not arg_4_0.noticeAllPlayers then
				arg_4_0:nodeByName("select"):setVisible(true)

				arg_4_0.noticeAllPlayers = true
			else
				arg_4_0:nodeByName("select"):setVisible(false)

				arg_4_0.noticeAllPlayers = false
			end

			arg_4_0:updateSubSelectBox()
		end
	end)

	local var_4_5 = arg_4_0:nodeByName("select_box_world")

	arg_4_0:nodeByName("select_world"):setVisible(false)
	var_4_5:setTouchEnabled(true)
	var_4_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			return true
		elseif arg_9_0.name == "ended" then
			if not arg_4_0.noticeWorld then
				arg_4_0:nodeByName("select_world"):setVisible(true)

				arg_4_0.noticeWorld = true
			else
				arg_4_0:nodeByName("select_world"):setVisible(false)

				arg_4_0.noticeWorld = false
			end
		end
	end)
	arg_4_0:nodeByName("text_tips_1"):setString(var_0_2:translation("INDIEGOGO_FAILED_TIPS_2"))
	arg_4_0:nodeByName("text_tips_2"):setString(var_0_2:translation("INDIEGOGO_NOTICE"))
	arg_4_0:nodeByName("text_item"):setString(var_0_2:translation("INDIEGOGO_AWARD"))
	arg_4_0:nodeByName("text_target"):setString(var_0_2:translation("INDIEGOGO_TARGET"))
	arg_4_0:updateLoadingBar()
	arg_4_0:initAwardItem()
end

function var_0_0.updateLoadingBar(arg_10_0)
	arg_10_0:nodeByName("bar"):setPercent(0)
	arg_10_0:nodeByName("text_bar_num"):setString("0" .. "/" .. var_0_3:achieveStone(arg_10_0.tableID))
	arg_10_0:nodeByName("text_bar_num"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
	arg_10_0:nodeByName("text_bar_num"):setPositionY(arg_10_0:nodeByName("bar"):getPositionY() - 2)
end

function var_0_0.updateSubSelectBox(arg_11_0)
	for iter_11_0, iter_11_1 in pairs(arg_11_0.noticePlayers) do
		local var_11_0 = arg_11_0.subSelectBox[iter_11_0]

		if arg_11_0.noticeAllPlayers then
			arg_11_0.noticePlayers[iter_11_0] = 1

			if var_11_0 and not tolua.isnull(var_11_0) then
				var_11_0:getChildByName("select"):setVisible(true)
			end
		else
			arg_11_0.noticePlayers[iter_11_0] = 0

			if var_11_0 and not tolua.isnull(var_11_0) then
				var_11_0:getChildByName("select"):setVisible(false)
			end
		end
	end
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevY_ = arg_12_1.y
	elseif arg_12_1.name == "moved" and 10 <= math.abs(arg_12_1.y - arg_12_0.prevY_) then
		arg_12_0.scrollViewMoved_ = true
	end
end

function var_0_0.initAwardItem(arg_13_0)
	local var_13_0 = cc.p(arg_13_0:nodeByName("node_item"):getPosition())
	local var_13_1 = var_0_3:issueAward(arg_13_0.tableID)
	local var_13_2 = var_0_3:issueAwardNum(arg_13_0.tableID)
	local var_13_3 = var_0_3:name(arg_13_0.tableID)

	if var_13_1 <= var_0_7 then
		var_13_1 = -var_13_1

		if var_13_1 == -1 then
			var_13_1 = -2
		end
	end

	local var_13_4 = " x" .. var_13_2
	local var_13_5 = arg_13_0:createIconItem(var_13_1, var_13_4)

	var_13_5:addTo(arg_13_0:nodeByName("container"))
	var_13_5:getChildByName("label"):setPositionY(-8)
	var_13_5:setPosition(cc.p(var_13_0))
end

function var_0_0.delegate(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	if cc.ui.UIListView.COUNT_TAG == arg_14_2 then
		return #arg_14_0.friendList
	elseif cc.ui.UIListView.CELL_TAG == arg_14_2 then
		local var_14_0 = arg_14_0.list:dequeueItem() or arg_14_0.list:newItem()

		var_14_0:removeAllChildren(true)

		local var_14_1 = display.newNode()

		arg_14_0:initFundingCell(var_14_1, arg_14_3)

		local var_14_2 = var_14_1:getWidth()
		local var_14_3 = var_14_1:getHeight()

		var_14_0:setItemSize(var_14_2, var_14_3 + var_0_8)
		var_14_0:addContent(var_14_1)

		return var_14_0
	end
end

function var_0_0.createAvatar(arg_15_0, arg_15_1, arg_15_2)
	xyd.setAvatarClip(arg_15_1:getChildByName("avatar"), arg_15_2.avatar_id, 1)

	local var_15_0 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"

	if arg_15_2.avatar_frame_id and arg_15_2.avatar_frame_id ~= 0 then
		var_15_0 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[arg_15_2.avatar_frame_id] .. ".png"
	end

	local var_15_1 = xyd.AssetLoader.get():loadSprite(var_15_0)
	local var_15_2 = arg_15_1:getChildByName("avatar_frame"):getContentSize()

	var_15_1:addTo(arg_15_1:getChildByName("avatar_frame"))
	var_15_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_15_1:setScale(0.75)
	var_15_1:setPosition(var_15_2.width / 2 - 1, var_15_2.height / 2 - 3)
end

function var_0_0.createIconItem(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4)
	local var_16_0 = display.newNode()
	local var_16_1
	local var_16_2 = var_0_5

	if arg_16_3 then
		var_16_2 = var_0_6
	end

	if arg_16_1 then
		var_16_1 = display.newNode()

		var_16_1:setContentSize(var_16_2, var_16_2)
		xyd.setItemBorder(var_16_1, arg_16_1)
		var_16_1:setPosition(cc.p(0, 0))
	else
		var_16_1 = xyd.AssetLoader.get():loadSprite("windows/social_system/indiegogo/spirit_stone.png")

		var_16_1:setPosition(cc.p(0, 0))
	end

	var_16_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_16_1:addTo(var_16_0)

	local var_16_3 = cc.c3b(254, 115, 22)
	local var_16_4 = {
		size = 24,
		text = arg_16_2,
		align = cc.ui.TEXT_ALIGN_LEFT,
		color = var_16_3
	}
	local var_16_5 = xyd.AssetLoader.get():loadLabel(var_16_4)

	var_16_5:setAnchorPoint(cc.p(0, 0.5))
	var_16_5:setPosition(cc.p(var_16_2 / 2, 0))
	var_16_5:addTo(var_16_0)
	var_16_5:setName("label")
	var_16_0:setContentSize(var_16_2 + var_16_5:getContentSize().width, var_16_2)

	return var_16_0
end

function var_0_0.initFundingCell(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_0.friendList[arg_17_2]
	local var_17_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/indiegogo/order_item.csb")
	local var_17_2 = var_17_1:getChildByName("container")

	arg_17_0:createAvatar(var_17_2, var_17_0)

	if var_17_0.conquer_lev and var_17_0.conquer_lev > 0 then
		xyd.setConquerLev(var_17_0.conquer_lev, var_17_2:getChildByName("text_lev"), var_17_2:getChildByName("dengjiquan"), nil, nil, nil, nil, var_17_0.conquer_loop_id)
	else
		var_17_2:getChildByName("text_lev"):setString(var_17_0.lev)
	end

	var_17_2:getChildByName("text_name"):setString(var_17_0.player_name)

	local var_17_3 = var_17_2:getContentSize()

	arg_17_1:addChild(var_17_1)
	arg_17_1:setContentSize(var_17_3.width, var_17_3.height)

	local var_17_4 = var_17_2:getChildByName("select_box")

	if arg_17_0.noticePlayers[var_17_0.player_id] == 1 then
		var_17_4:getChildByName("select"):setVisible(true)
	else
		var_17_4:getChildByName("select"):setVisible(false)
	end

	var_17_4:setTouchEnabled(true)
	var_17_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
		if arg_18_0.name == "began" then
			return true
		elseif arg_18_0.name == "ended" then
			if arg_17_0.noticePlayers[var_17_0.player_id] == 1 then
				var_17_4:getChildByName("select"):setVisible(false)

				arg_17_0.noticePlayers[var_17_0.player_id] = 0
				arg_17_0.noticeAllPlayers = false

				arg_17_0:nodeByName("select"):setVisible(false)
			else
				var_17_4:getChildByName("select"):setVisible(true)

				arg_17_0.noticePlayers[var_17_0.player_id] = 1
			end
		end
	end)

	arg_17_0.subSelectBox[var_17_0.player_id] = var_17_4
end

function var_0_0.didOpen(arg_19_0, arg_19_1)
	var_0_0.super:didOpen(arg_19_1)
	arg_19_0:addBlockLayer()
	arg_19_0.list:reload()
end

return var_0_0
