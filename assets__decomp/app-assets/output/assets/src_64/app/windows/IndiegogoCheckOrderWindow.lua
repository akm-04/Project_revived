local var_0_0 = class("IndiegogoCheckOrderWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.indiegogoTable
local var_0_4 = import("framework.scheduler")
local var_0_5 = 100
local var_0_6 = 64
local var_0_7 = 30
local var_0_8 = 17
local var_0_9 = 10

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.fundingInfo = arg_1_2
	arg_1_0.tableID = arg_1_0.fundingInfo.table_id
	arg_1_0.listIdx = arg_1_0.fundingInfo.id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("friend_container")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_0):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setDelegate(handler(arg_3_0, arg_3_0.delegate))

	local var_3_2 = arg_3_0:nodeByName("line_1")

	var_0_1.new({
		size = var_3_2:getWidth(),
		type = xyd.SplitlineType.SOLID
	}):addTo(var_3_2)

	local var_3_3 = arg_3_0:nodeByName("line_2")

	var_0_1.new({
		size = var_3_3:getWidth(),
		type = xyd.SplitlineType.SOLID
	}):addTo(var_3_3)
	arg_3_0:nodeByName("btn_insert_coin"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = var_0_3:participationStone(arg_3_0.tableID)

			if var_4_0 > arg_3_0.player.spiritStone then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("INDIEGOGO_COIN_NOT_ENOUGH_2")
				})

				return true
			elseif arg_3_0.fundingInfo.progress + var_4_0 == var_0_3:achieveStone(arg_3_0.tableID) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("INDIEGOGO_MISSION_SUCCESS")
				})

				arg_3_0.deleteFinishedFunding = true
			end

			local var_4_1 = {
				fund_id = arg_3_0.fundingInfo.id
			}

			arg_3_0.socialSystem:investFunding(var_4_1, function(arg_5_0, arg_5_1)
				if arg_5_0 == xyd.error.OK then
					arg_3_0.fundingInfo = arg_5_1.fund_info

					arg_3_0:updateLoadingBar()
					arg_3_0.list:reload()

					local var_5_0 = xyd.WindowManager.get():getWindow("indiegogo")

					if var_5_0 then
						var_5_0:updateSelfCoin()
					end
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("INDIEGOGO_HAVE_OVER")
					})

					arg_3_0.deleteFinishedFunding = true

					return true
				end
			end)
		end
	end)
	arg_3_0:nodeByName("text_title"):setString(var_0_3:name(arg_3_0.tableID))
	arg_3_0:nodeByName("text_item"):setString(var_0_2:translation("INDIEGOGO_AWARD"))
	arg_3_0:nodeByName("text_target"):setString(var_0_2:translation("INDIEGOGO_TARGET"))

	if arg_3_0.fundingInfo.release_player == 0 then
		arg_3_0:nodeByName("text_tips_1"):setString(var_0_2:translation("INDIEGOGO_FAILED_TIPS_1"))
	else
		local var_3_4 = arg_3_0.fundingInfo.release_time
		local var_3_5 = var_0_3:time(arg_3_0.tableID)
		local var_3_6 = xyd.ServerTime.get():getServerTime()
		local var_3_7 = var_3_4 + var_3_5 - var_3_6

		arg_3_0:updateCountTime(var_3_7)
	end

	arg_3_0:updateLoadingBar()
	arg_3_0:updateInsertBtn()
	arg_3_0:initAwardItem()
end

function var_0_0.updateLoadingBar(arg_6_0)
	local var_6_0 = math.floor(100 * arg_6_0.fundingInfo.progress / var_0_3:achieveStone(arg_6_0.tableID))

	arg_6_0:nodeByName("bar"):setPercent(var_6_0)
	arg_6_0:nodeByName("text_bar_num"):setString(arg_6_0.fundingInfo.progress .. "/" .. var_0_3:achieveStone(arg_6_0.tableID))
	arg_6_0:nodeByName("text_bar_num"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
	arg_6_0:nodeByName("text_bar_num"):setPositionY(arg_6_0:nodeByName("bar"):getPositionY() - 2)
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" and 10 <= math.abs(arg_7_1.y - arg_7_0.prevY_) then
		arg_7_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateInsertBtn(arg_8_0)
	local var_8_0 = var_0_3:participationStone(arg_8_0.tableID)

	arg_8_0:nodeByName("spirit_cost_num"):setString("+" .. var_8_0)
end

function var_0_0.initAwardItem(arg_9_0)
	local var_9_0 = cc.p(arg_9_0:nodeByName("node_item"):getPosition())
	local var_9_1
	local var_9_2
	local var_9_3 = var_0_3:name(arg_9_0.tableID)

	if arg_9_0.fundingInfo.release_player == arg_9_0.player.playerID then
		var_9_1 = var_0_3:issueAward(arg_9_0.tableID)
		var_9_2 = var_0_3:issueAwardNum(arg_9_0.tableID)
	else
		var_9_1 = var_0_3:participationAward(arg_9_0.tableID)
		var_9_2 = var_0_3:participationAwardNum(arg_9_0.tableID)

		if arg_9_0.fundingInfo.release_player ~= 0 then
			local var_9_4 = var_9_3 .. var_0_2:translation("")
		end
	end

	if var_9_1 <= var_0_8 then
		var_9_1 = -var_9_1

		if var_9_1 == -1 then
			var_9_1 = -2
		end
	end

	local var_9_5 = " x" .. var_9_2
	local var_9_6 = arg_9_0:createIconItem(var_9_1, var_9_5, nil, nil, cc.c3b(254, 115, 22))

	var_9_6:addTo(arg_9_0:nodeByName("container"))
	var_9_6:getChildByName("label"):setPositionY(-8)
	var_9_6:setPosition(cc.p(var_9_0))
end

function var_0_0.delegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return #arg_10_0.fundingInfo.fund_player_infos
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_0 = arg_10_0.list:dequeueItem() or arg_10_0.list:newItem()

		var_10_0:removeAllChildren(true)

		local var_10_1 = display.newNode()

		arg_10_0:initFundingCell(var_10_1, arg_10_3)

		local var_10_2 = var_10_1:getWidth()
		local var_10_3 = var_10_1:getHeight()

		var_10_0:setItemSize(var_10_2, var_10_3 + var_0_9)
		var_10_0:addContent(var_10_1)

		return var_10_0
	end
end

function var_0_0.createAvatar(arg_11_0, arg_11_1, arg_11_2)
	xyd.setAvatarClip(arg_11_1:getChildByName("avatar"), arg_11_2.avatar_id, 1)

	local var_11_0 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"

	if arg_11_2.avatar_frame_id and arg_11_2.avatar_frame_id ~= 0 then
		var_11_0 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[arg_11_2.avatar_frame_id] .. ".png"
	end

	local var_11_1 = xyd.AssetLoader.get():loadSprite(var_11_0)
	local var_11_2 = arg_11_1:getChildByName("avatar_frame"):getContentSize()

	var_11_1:addTo(arg_11_1:getChildByName("avatar_frame"))
	var_11_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_11_1:setScale(0.75)
	var_11_1:setPosition(var_11_2.width / 2 - 1, var_11_2.height / 2 - 3)
end

function var_0_0.createIconItem(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5)
	local var_12_0 = display.newNode()
	local var_12_1
	local var_12_2 = var_0_6

	if arg_12_3 then
		var_12_2 = var_0_7
	end

	if arg_12_1 then
		var_12_1 = display.newNode()

		var_12_1:setContentSize(var_12_2, var_12_2)
		xyd.setItemBorder(var_12_1, arg_12_1)
		var_12_1:setPosition(cc.p(0, 0))
	else
		var_12_1 = xyd.AssetLoader.get():loadSprite("windows/social_system/indiegogo/spirit_stone.png")

		var_12_1:setPosition(cc.p(0, 0))
	end

	var_12_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_12_1:addTo(var_12_0)

	arg_12_5 = arg_12_5 or cc.c3b(52, 54, 55)

	local var_12_3 = {
		size = 24,
		text = arg_12_2,
		align = cc.ui.TEXT_ALIGN_LEFT,
		color = arg_12_5
	}
	local var_12_4 = xyd.AssetLoader.get():loadLabel(var_12_3)

	var_12_4:setAnchorPoint(cc.p(0, 0.5))
	var_12_4:setPosition(cc.p(var_12_2 / 2, 0))
	var_12_4:addTo(var_12_0)
	var_12_4:setName("label")
	var_12_0:setContentSize(var_12_2 + var_12_4:getContentSize().width, var_12_2)

	return var_12_0
end

function var_0_0.initFundingCell(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_0.fundingInfo.fund_player_infos
	local var_13_1 = arg_13_0.fundingInfo.fund_nums
	local var_13_2 = var_13_0[arg_13_2]
	local var_13_3 = var_13_1[arg_13_2]
	local var_13_4 = "+" .. var_13_3
	local var_13_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/indiegogo/order_item.csb")
	local var_13_6 = var_13_5:getChildByName("container")

	arg_13_0:createAvatar(var_13_6, var_13_2)

	if var_13_2.conquer_lev and var_13_2.conquer_lev > 0 then
		xyd.setConquerLev(var_13_2.conquer_lev, var_13_6:getChildByName("text_lev"), var_13_6:getChildByName("dengjiquan"), nil, nil, nil, nil, var_13_2.conquer_loop_id)
	else
		var_13_6:getChildByName("text_lev"):setString(var_13_2.lev)
	end

	var_13_6:getChildByName("text_name"):setString(var_13_2.player_name)

	local var_13_7 = arg_13_0:createIconItem(nil, var_13_4)
	local var_13_8 = var_13_6:getContentSize()

	var_13_6:getChildByName("node_cost"):addChild(var_13_7)
	arg_13_1:addChild(var_13_5)
	arg_13_1:setContentSize(var_13_8.width, var_13_8.height)
	var_13_6:getChildByName("select_box"):setVisible(false)
end

function var_0_0.didOpen(arg_14_0, arg_14_1)
	var_0_0.super:didOpen(arg_14_1)
	arg_14_0:addBlockLayer()
	arg_14_0.list:reload()
end

function var_0_0.willClose(arg_15_0)
	local var_15_0 = xyd.WindowManager.get():getWindow("indiegogo")

	if var_15_0 and arg_15_0.deleteFinishedFunding == true then
		arg_15_0.deleteFinishedFunding = false

		local var_15_1

		for iter_15_0, iter_15_1 in pairs(var_15_0.fundingList) do
			if tostring(iter_15_1.id) == tostring(arg_15_0.listIdx) then
				var_15_1 = iter_15_0
			end
		end

		table.remove(var_15_0.fundingList, var_15_1)

		var_15_0.worldFundingTotal = var_15_0.worldFundingTotal - 1

		var_15_0.list:refreshList()
	end
end

function var_0_0.updateCountTime(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_1

	if arg_16_0.handler then
		var_0_4.unscheduleGlobal(arg_16_0.handler)

		arg_16_0.handler = nil
	end

	arg_16_0:nodeByName("text_tips_1"):setString(string.format(var_0_2:translation("INDIEGOGO_END_TIME"), xyd.secondsToString(var_16_0)))

	if var_16_0 > 0 then
		arg_16_0:nodeByName("text_tips_1"):setString(string.format(var_0_2:translation("INDIEGOGO_END_TIME"), xyd.secondsToString(var_16_0)))

		arg_16_0.handler = var_0_4.scheduleGlobal(function()
			var_16_0 = var_16_0 - 1

			if not tolua.isnull(arg_16_0) then
				arg_16_0:nodeByName("text_tips_1"):setString(string.format(var_0_2:translation("INDIEGOGO_END_TIME"), xyd.secondsToString(var_16_0)))
			end

			if var_16_0 <= 0 and arg_16_0.handler then
				var_0_4.unscheduleGlobal(arg_16_0.handler)

				arg_16_0.handler = nil
			end
		end, 1)
	else
		arg_16_0:nodeByName("text_tips_1"):setString(string.format(var_0_2:translation("INDIEGOGO_END_TIME"), xyd.secondsToString(0)))
	end
end

return var_0_0
