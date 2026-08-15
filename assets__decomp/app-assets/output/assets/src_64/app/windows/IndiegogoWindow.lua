local var_0_0 = class("IndiegogoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.indiegogoTable
local var_0_4 = 100
local var_0_5 = 40
local var_0_6 = 40
local var_0_7 = 17
local var_0_8 = 3
local var_0_9 = 30
local var_0_10 = 1
local var_0_11 = 390
local var_0_12 = {
	SEND_ORDER = 2,
	ORDER = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.fundingList = arg_1_2.funding_list
	arg_1_0.releaseList = arg_1_2.release_list
	arg_1_0.isGotoCheck = arg_1_2.isGotoCheck
	arg_1_0.gotoFundID = arg_1_2.fundID
	arg_1_0.worldFundingTotal = -1
	arg_1_0.start_pos = var_0_10
	arg_1_0.query_num = xyd.tables.misc.indiegogoQueryNum
	arg_1_0.leftBtnType = nil
	arg_1_0.fundingState = xyd.FUNDING_STATE.System
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:nodeByName("btn_funding_system"):setBrightStyle(ccui.BrightStyle.highlight)
	arg_2_0:nodeByName("btn_funding_system"):setTouchEnabled(false)
	arg_2_0:layout()
end

function var_0_0.swapFundingState(arg_3_0, arg_3_1)
	arg_3_0.fundingState = arg_3_1 or xyd.FUNDING_STATE.System

	arg_3_0:initFundingData()
	arg_3_0:initFundingViewByState()
	arg_3_0:updateNPCTips()
end

function var_0_0.updateNPCTips(arg_4_0)
	if arg_4_0.leftBtnType == var_0_12.ORDER and arg_4_0.fundingState ~= xyd.FUNDING_STATE.System and #arg_4_0.fundingList <= 0 then
		arg_4_0:nodeByName("NPC"):setVisible(true)
	else
		arg_4_0:nodeByName("NPC"):setVisible(false)
	end
end

function var_0_0.initFundingData(arg_5_0)
	local var_5_0 = {
		list_type = arg_5_0.fundingState
	}

	arg_5_0.socialSystem:loadFundingList(var_5_0, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			arg_5_0.fundingList = arg_6_1.funding_list

			if arg_5_0.fundingState == xyd.FUNDING_STATE.Friend then
				table.sort(arg_5_0.fundingList, function(arg_7_0, arg_7_1)
					return arg_7_0.release_time > arg_7_1.release_time
				end)
			end

			if arg_6_1.total_num ~= nil then
				arg_5_0.worldFundingTotal = arg_6_1.total_num
			end

			arg_5_0.start_pos = var_0_10
			arg_5_0.query_num = QUERY_NUM

			arg_5_0.list:reload()
			arg_5_0:updateNPCTips()
		end
	end)
end

function var_0_0.initFundingViewByState(arg_8_0)
	if arg_8_0.fundingState == xyd.FUNDING_STATE.System then
		arg_8_0:nodeByName("btn_funding_system"):setTouchEnabled(false)
		arg_8_0:nodeByName("btn_funding_friend"):setTouchEnabled(true)
		arg_8_0:nodeByName("btn_funding_world"):setTouchEnabled(true)
		arg_8_0:nodeByName("btn_funding_friend"):setBrightStyle(ccui.BrightStyle.normal)
		arg_8_0:nodeByName("btn_funding_world"):setBrightStyle(ccui.BrightStyle.normal)
		arg_8_0:nodeByName("btn_funding_system"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_8_0.fundingState == xyd.FUNDING_STATE.Friend then
		arg_8_0:nodeByName("btn_funding_system"):setTouchEnabled(true)
		arg_8_0:nodeByName("btn_funding_friend"):setTouchEnabled(false)
		arg_8_0:nodeByName("btn_funding_world"):setTouchEnabled(true)
		arg_8_0:nodeByName("btn_funding_system"):setBrightStyle(ccui.BrightStyle.normal)
		arg_8_0:nodeByName("btn_funding_world"):setBrightStyle(ccui.BrightStyle.normal)
		arg_8_0:nodeByName("btn_funding_friend"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_8_0.fundingState == xyd.FUNDING_STATE.World then
		arg_8_0:nodeByName("btn_funding_system"):setTouchEnabled(true)
		arg_8_0:nodeByName("btn_funding_friend"):setTouchEnabled(true)
		arg_8_0:nodeByName("btn_funding_world"):setTouchEnabled(false)
		arg_8_0:nodeByName("btn_funding_system"):setBrightStyle(ccui.BrightStyle.normal)
		arg_8_0:nodeByName("btn_funding_friend"):setBrightStyle(ccui.BrightStyle.normal)
		arg_8_0:nodeByName("btn_funding_world"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_0.layout(arg_9_0)
	local var_9_0 = arg_9_0:nodeByName("detail_container_funding")
	local var_9_1 = var_9_0:getContentSize()

	arg_9_0.fundingContainerHeight = var_9_1.height
	arg_9_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_9_1.width, var_9_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_9_0):onScroll(handler(arg_9_0, arg_9_0.scrollListener))

	arg_9_0.list:setDelegate(handler(arg_9_0, arg_9_0.delegate))
	arg_9_0.list:reload()
	arg_9_0:updateNPCTips()
	arg_9_0:nodeByName("load_funding_tip"):setVisible(false)
	arg_9_0:nodeByName("reload_funding_tip"):setVisible(false)
	arg_9_0:nodeByName("text_funding_system"):setString(var_0_2:translation("INDIEGOGO_TEXT_3"))
	arg_9_0:nodeByName("btn_funding_system"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended and arg_9_0.fundingState ~= xyd.FUNDING_STATE.System then
			arg_9_0:swapFundingState(xyd.FUNDING_STATE.System)
		end
	end)
	arg_9_0:nodeByName("text_funding_friend"):setString(var_0_2:translation("INDIEGOGO_TEXT_4"))
	arg_9_0:nodeByName("btn_funding_friend"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended and arg_9_0.fundingState ~= xyd.FUNDING_STATE.Friend then
			arg_9_0:swapFundingState(xyd.FUNDING_STATE.Friend)
		end
	end)
	arg_9_0:nodeByName("text_funding_world"):setString(var_0_2:translation("INDIEGOGO_TEXT_5"))
	arg_9_0:nodeByName("btn_funding_world"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended and arg_9_0.fundingState ~= xyd.FUNDING_STATE.World then
			arg_9_0:swapFundingState(xyd.FUNDING_STATE.World)
		end
	end)
	arg_9_0:nodeByName("text_doing"):setString(var_0_2:translation("INDIEGOGO_TEXT_2"))
	arg_9_0:nodeByName("btn_order"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended and arg_9_0.leftBtnType ~= var_0_12.ORDER then
			arg_9_0:updateLeftBtn(var_0_12.ORDER)
		end
	end)
	arg_9_0:nodeByName("text_send"):setString(var_0_2:translation("INDIEGOGO_TEXT_1"))
	arg_9_0:nodeByName("btn_send_order"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended and arg_9_0.leftBtnType ~= var_0_12.SEND_ORDER then
			arg_9_0:updateLeftBtn(var_0_12.SEND_ORDER)
			arg_9_0:initSendOrder()
		end
	end)
	arg_9_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			local var_15_0 = {
				ruleType = 1
			}

			xyd.WindowManager.get():openWindow("teacher_rule", var_15_0)
		end
	end)

	local var_9_2 = xyd.tables.misc.indiegogoStorageUpper

	arg_9_0:nodeByName("text_max_coin"):setString("/" .. var_9_2)
	arg_9_0:updateLeftBtn(var_0_12.ORDER)
	arg_9_0:updateSelfCoin()
	arg_9_0:checkFunctionIsOpen()
end

function var_0_0.checkFunctionIsOpen(arg_16_0)
	if not arg_16_0.player:isFuncOpen(xyd.FunctionID.ID_MY_CLASS) then
		-- block empty
	end
end

function var_0_0.updateSelfCoin(arg_17_0)
	local var_17_0 = arg_17_0.player.spiritStone

	arg_17_0:nodeByName("text_self_coin"):setString(var_17_0)
end

function var_0_0.scrollListener(arg_18_0, arg_18_1)
	if arg_18_1.name == "began" then
		arg_18_0.nodeY = arg_18_0.list:getScrollNode():getPositionY()

		arg_18_0:nodeByName("load_funding_tip"):setVisible(false)
		arg_18_0:nodeByName("reload_funding_tip"):setVisible(false)

		arg_18_0.is_scroll = false
		arg_18_0.is_scroll_top = false
		arg_18_0.scrollViewMoved_ = false
		arg_18_0.prevY_ = arg_18_1.y
	elseif arg_18_1.name == "moved" then
		if 1 <= math.abs(arg_18_1.y - arg_18_0.prevY_) then
			arg_18_0.scrollViewMoved_ = true
		end

		if arg_18_0.fundingState == xyd.FUNDING_STATE.World then
			if arg_18_0.list:getScrollNode():getPositionY() < arg_18_0.fundingContainerHeight - 25 then
				arg_18_0:nodeByName("reload_funding_tip"):setVisible(true)

				arg_18_0.is_scroll_top = true
			else
				arg_18_0:nodeByName("reload_funding_tip"):setVisible(false)

				arg_18_0.is_scroll_top = false
			end
		end

		if #arg_18_0.fundingList < arg_18_0.worldFundingTotal and arg_18_0.fundingState == xyd.FUNDING_STATE.World then
			if arg_18_0.list:getScrollNode():getPositionY() > #arg_18_0.fundingList * (arg_18_0.itemContainerHeight + var_0_8) + 25 and arg_18_0.list:getScrollNode():getPositionY() >= arg_18_0.fundingContainerHeight + 25 then
				arg_18_0:nodeByName("load_funding_tip"):setVisible(true)

				arg_18_0.is_scroll = true
			else
				arg_18_0:nodeByName("load_funding_tip"):setVisible(false)

				arg_18_0.is_scroll = false
			end
		end
	elseif arg_18_1.name == "scrollEnd" then
		if arg_18_0.is_scroll == true then
			arg_18_0:nodeByName("load_funding_tip"):setVisible(false)
			arg_18_0:nodeByName("reload_funding_tip"):setVisible(false)

			if arg_18_0.fundingState == xyd.FUNDING_STATE.World then
				local var_18_0 = {
					list_type = arg_18_0.fundingState,
					start_pos = #arg_18_0.fundingList + 1,
					query_num = arg_18_0.query_num,
					total = arg_18_0.worldFundingTotal
				}

				arg_18_0.socialSystem:loadFundingList(var_18_0, function(arg_19_0, arg_19_1)
					local var_19_0 = {}

					if arg_19_0 == xyd.error.OK then
						local var_19_1 = arg_19_1.funding_list

						for iter_19_0, iter_19_1 in pairs(var_19_1) do
							table.insert(arg_18_0.fundingList, iter_19_1)
						end

						arg_18_0.start_pos = #arg_18_0.fundingList + 1

						arg_18_0.list:refreshList()
						arg_18_0:updateNPCTips()

						if arg_18_0.list and arg_18_0.list.getScrollNode and not tolua.isnull(arg_18_0.list) then
							local var_19_2 = arg_18_0.list:getScrollNode()
							local var_19_3 = var_19_2:getPositionY()

							var_19_2:setPositionY(var_19_3 + 20)
						end
					end
				end)
			end

			arg_18_0.is_scroll = false
		end

		if arg_18_0.is_scroll_top == true then
			arg_18_0:nodeByName("reload_funding_tip"):setVisible(false)

			if arg_18_0.fundingState == xyd.FUNDING_STATE.World then
				arg_18_0:initFundingData()
			end

			arg_18_0.is_scroll_top = false
		end
	end
end

function var_0_0.updateLeftBtn(arg_20_0, arg_20_1)
	arg_20_0.leftBtnType = arg_20_1

	if arg_20_1 == var_0_12.ORDER then
		arg_20_0:nodeByName("btn_order"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_20_0:nodeByName("btn_order"):setTouchEnabled(false)
		arg_20_0:nodeByName("btn_send_order"):setTouchEnabled(true)
		arg_20_0:nodeByName("btn_send_order"):setBrightStyle(ccui.BrightStyle.normal)
		arg_20_0:nodeByName("btn_funding_world"):setVisible(true)
		arg_20_0:nodeByName("btn_funding_friend"):setVisible(true)
		arg_20_0:nodeByName("btn_funding_system"):setVisible(true)
		arg_20_0:nodeByName("detail_container_funding"):setVisible(true)
		arg_20_0:nodeByName("detail_container"):setVisible(false)
		arg_20_0.list:setVisible(true)

		local var_20_0 = arg_20_0:nodeByName("detail_container"):getChildByName("release_container")

		if var_20_0 then
			var_20_0:removeSelf()
		end
	else
		arg_20_0:nodeByName("btn_send_order"):setTouchEnabled(false)
		arg_20_0:nodeByName("btn_order"):setTouchEnabled(true)
		arg_20_0:nodeByName("btn_order"):setBrightStyle(ccui.BrightStyle.normal)
		arg_20_0:nodeByName("btn_send_order"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_20_0:nodeByName("btn_funding_world"):setVisible(false)
		arg_20_0:nodeByName("btn_funding_friend"):setVisible(false)
		arg_20_0:nodeByName("btn_funding_system"):setVisible(false)
		arg_20_0:nodeByName("detail_container_funding"):setVisible(false)
		arg_20_0:nodeByName("detail_container"):setVisible(true)
		arg_20_0.list:setVisible(false)
	end
end

function var_0_0.delegate(arg_21_0, arg_21_1, arg_21_2, arg_21_3)
	if cc.ui.UIListView.COUNT_TAG == arg_21_2 then
		return #arg_21_0.fundingList
	elseif cc.ui.UIListView.CELL_TAG == arg_21_2 then
		if arg_21_3 > #arg_21_0.fundingList then
			return
		end

		local var_21_0 = arg_21_0.list:dequeueItem() or arg_21_0.list:newItem()

		var_21_0:removeAllChildren(true)

		local var_21_1 = display.newNode()

		arg_21_0:initOngingOrderCell(var_21_1, arg_21_3)

		local var_21_2 = var_21_1:getWidth()
		local var_21_3 = var_21_1:getHeight()

		var_21_0:setItemSize(var_21_2, var_21_3 + var_0_8)
		var_21_0:addContent(var_21_1)

		return var_21_0
	end
end

function var_0_0.initOngingOrderCell(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = arg_22_0.fundingList[arg_22_2]
	local var_22_1 = var_22_0.table_id
	local var_22_2 = var_22_0.release_player
	local var_22_3 = var_22_0.release_player_info
	local var_22_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/indiegogo/ongoing_item.csb")
	local var_22_5 = var_22_4:getChildByName("container")
	local var_22_6 = var_22_5:getContentSize()

	arg_22_1:setContentSize(var_22_6.width, var_22_6.height)

	arg_22_0.itemContainerHeight = var_22_6.height

	arg_22_1:addChild(var_22_4)

	local var_22_7 = math.floor(100 * var_22_0.progress / var_0_3:achieveStone(var_22_1))

	var_22_5:getChildByName("text_progress"):setString(string.format(var_0_2:translation("INDIEGOGO_PROGRESS"), var_22_7))

	local var_22_8 = cc.p(var_22_5:getChildByName("node_icon"):getPosition())
	local var_22_9 = display.newNode()

	var_22_9:setContentSize(var_0_4, var_0_4)

	local var_22_10
	local var_22_11
	local var_22_12 = var_0_3:name(var_22_1)

	if var_22_2 == arg_22_0.player.playerID then
		var_22_10 = var_0_3:issueAward(var_22_1)
		var_22_11 = var_0_3:issueAwardNum(var_22_1)
	else
		var_22_10 = var_0_3:participationAward(var_22_1)
		var_22_11 = var_0_3:participationAwardNum(var_22_1)

		if var_22_2 ~= 0 then
			var_22_12 = var_22_12 .. var_0_2:translation("")
		end
	end

	if var_22_10 <= var_0_7 then
		var_22_10 = -var_22_10

		if var_22_10 == -1 then
			var_22_10 = -2
		end
	end

	local var_22_13 = var_22_5:getChildByName("node_line")

	var_0_1.new({
		size = var_22_13:getWidth() - 5
	}):addTo(var_22_13)
	var_22_5:getChildByName("btn_check"):getChildByName("text_check"):setString(var_0_2:translation("INDIEGOGO_TEXT_6"))

	if var_22_2 ~= 0 then
		var_22_5:getChildByName("text_lev"):setVisible(true)
		var_22_5:getChildByName("text_name_release"):setVisible(true)
		var_22_5:getChildByName("name_bg"):setVisible(true)
		var_22_5:getChildByName("dengjiquan"):setVisible(true)

		var_22_3.playerInfo = {}
		var_22_3.playerInfo.player_id = var_22_2

		xyd.setPlayerAvatar(var_22_5:getChildByName("avatar"), var_22_3)

		if var_22_3.conquer_lev and var_22_3.conquer_lev > 0 then
			xyd.setConquerLev(var_22_3.conquer_lev, var_22_5:getChildByName("text_lev"), var_22_5:getChildByName("dengjiquan"), nil, nil, nil, nil, var_22_3.conquer_loop_id)
		else
			var_22_5:getChildByName("text_lev"):setString(var_22_3.lev)
		end

		var_22_5:getChildByName("text_name_release"):setString(var_22_3.player_name)
	else
		var_22_5:getChildByName("text_lev"):setVisible(false)
		var_22_5:getChildByName("text_name_release"):setVisible(false)
		var_22_5:getChildByName("name_bg"):setVisible(false)
		var_22_5:getChildByName("dengjiquan"):setVisible(false)
		var_22_5:getChildByName("node_award"):setPosition(var_22_5:getChildByName("node_award"):getPositionX() - var_0_11, var_22_5:getChildByName("node_award"):getPositionY())
		var_22_5:getChildByName("text_award"):setPosition(var_22_5:getChildByName("text_award"):getPositionX() - var_0_11, var_22_5:getChildByName("text_award"):getPositionY())
	end

	var_22_5:getChildByName("text_name"):setString(var_22_12)
	xyd.setItemBorder(var_22_9, var_22_10)
	var_22_9:addTo(var_22_5)
	var_22_9:setAnchorPoint(cc.p(0.5, 0.5))
	var_22_9:setPosition(cc.p(var_22_8))
	var_22_5:getChildByName("text_award"):setString(var_0_2:translation("INDIEGOGO_AWARD"))

	local var_22_14 = cc.p(var_22_5:getChildByName("node_award"):getPosition())
	local var_22_15 = arg_22_0:createIconItem(var_22_10, var_22_11)

	var_22_5:addChild(var_22_15)
	var_22_15:setPosition(cc.p(var_22_14))
	var_22_5:getChildByName("btn_check"):addTouchEventListener(function(arg_23_0, arg_23_1)
		xyd.buttonScaleAnim(arg_23_0, arg_23_1)

		if arg_23_1 == ccui.TouchEventType.ended and not arg_22_0.scrollViewMoved_ then
			local var_23_0 = {
				fund_id = var_22_0.id,
				list_idx = arg_22_2
			}

			arg_22_0:openCheckOrderWnd(var_23_0)
		end
	end)
end

function var_0_0.createAvatar(arg_24_0, arg_24_1, arg_24_2)
	xyd.setAvatarClip(arg_24_1:getChildByName("avatar"), arg_24_2.avatar_id, 1)

	local var_24_0 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"

	if arg_24_2.avatar_frame_id and arg_24_2.avatar_frame_id ~= 0 then
		var_24_0 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[arg_24_2.avatar_frame_id] .. ".png"
	end

	local var_24_1 = xyd.AssetLoader.get():loadSprite(var_24_0)
	local var_24_2 = arg_24_1:getChildByName("avatar_frame"):getContentSize()

	var_24_1:addTo(arg_24_1:getChildByName("avatar_frame"))
	var_24_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_24_1:setPosition(var_24_2.width / 2 - 1, var_24_2.height / 2 - 3)
end

function var_0_0.openCheckOrderWnd(arg_25_0, arg_25_1)
	arg_25_0.socialSystem:getInfoByID(arg_25_1, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK then
			xyd.WindowManager.get():openWindow("indiegogo_check_order", arg_26_1)
		else
			local var_26_0 = var_0_2:translation("INDIEGOGO_HAVE_OVER")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_26_0
			})
		end
	end)
end

function var_0_0.initSendOrder(arg_27_0)
	local var_27_0 = arg_27_0:nodeByName("detail_container"):getChildByName("release_container")

	if var_27_0 then
		var_27_0:removeSelf()
	end

	local var_27_1 = display.newNode()

	var_27_1:setName("release_container")

	local var_27_2 = arg_27_0:nodeByName("detail_container"):getContentSize()

	var_27_1:setContentSize(var_27_2.width, var_27_2.height)
	var_27_1:addTo(arg_27_0:nodeByName("detail_container"))

	local var_27_3 = var_27_2.height - 7

	for iter_27_0, iter_27_1 in pairs(arg_27_0.releaseList) do
		if iter_27_1 == 1 then
			local var_27_4 = tonumber(iter_27_0)
			local var_27_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/indiegogo/main_send_item.csb")
			local var_27_6 = var_27_5:getChildByName("container")
			local var_27_7 = var_27_6:getContentSize()

			var_27_5:setPosition(cc.p(0, var_27_3 - var_27_7.height))

			var_27_3 = var_27_3 - var_27_7.height - 10

			var_27_1:addChild(var_27_5)

			local var_27_8 = var_0_3:name(var_27_4)

			var_27_6:getChildByName("text_name"):setString(var_27_8)

			local var_27_9 = cc.p(var_27_6:getChildByName("node_icon"):getPosition())
			local var_27_10 = display.newNode()
			local var_27_11 = var_0_3:issueAward(var_27_4)
			local var_27_12 = var_0_3:issueAwardNum(var_27_4)
			local var_27_13 = var_0_3:issueStone(var_27_4)

			var_27_10:setContentSize(var_0_4, var_0_4)
			xyd.setItemBorder(var_27_10, var_27_11)
			var_27_10:addTo(var_27_6)
			var_27_10:setAnchorPoint(cc.p(0.5, 0.5))
			var_27_10:setPosition(cc.p(var_27_9))

			local var_27_14 = var_27_6:getChildByName("node_line")

			var_0_1.new({
				size = var_27_14:getWidth() - 5
			}):addTo(var_27_14)
			var_27_6:getChildByName("btn_send"):getChildByName("text_send"):setString(var_0_2:translation("INDIEGOGO_TEXT_7"))

			local var_27_15 = cc.p(var_27_6:getChildByName("node_award"):getPosition())
			local var_27_16 = arg_27_0:createIconItem(var_27_11, var_27_12, true)

			var_27_6:addChild(var_27_16)
			var_27_16:setPosition(cc.p(var_27_15))

			local var_27_17 = cc.p(var_27_6:getChildByName("node_cost"):getPosition())
			local var_27_18 = true
			local var_27_19 = arg_27_0:createIconItem(nil, var_27_13, true, var_27_18)

			var_27_6:addChild(var_27_19)
			var_27_19:setPosition(cc.p(var_27_17))
			var_27_6:getChildByName("btn_send"):addTouchEventListener(function(arg_28_0, arg_28_1)
				xyd.buttonScaleAnim(arg_28_0, arg_28_1)

				if arg_28_1 == ccui.TouchEventType.ended then
					local var_28_0 = {
						table_id = var_27_4
					}

					xyd.WindowManager.get():openWindow("indiegogo_send_order", var_28_0)
				end
			end)
		end
	end
end

function var_0_0.createIconItem(arg_29_0, arg_29_1, arg_29_2, arg_29_3, arg_29_4)
	local var_29_0 = display.newNode()
	local var_29_1
	local var_29_2 = var_0_5

	if arg_29_3 then
		var_29_2 = var_0_6
	end

	if arg_29_1 then
		var_29_1 = display.newNode()

		var_29_1:setContentSize(var_29_2, var_29_2)
		xyd.setItemBorder(var_29_1, arg_29_1)
		var_29_1:setPosition(cc.p(0, 0))
	else
		var_29_1 = xyd.AssetLoader.get():loadSprite("windows/social_system/indiegogo/spirit_stone.png")

		var_29_1:setScale(0.8)
		var_29_1:setPosition(cc.p(0, 0))
	end

	var_29_1:setAnchorPoint(cc.p(0, 0.5))
	var_29_1:addTo(var_29_0)

	local var_29_3 = cc.c3b(52, 54, 55)
	local var_29_4

	if arg_29_4 then
		var_29_4 = arg_29_2

		var_29_1:setPositionY(5)
	else
		var_29_4 = "X" .. arg_29_2
	end

	local var_29_5 = {
		size = 24,
		text = var_29_4,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		color = var_29_3
	}
	local var_29_6 = xyd.AssetLoader.get():loadLabel(var_29_5)

	var_29_6:setAnchorPoint(cc.p(0, 0.5))
	var_29_6:setPosition(cc.p(var_29_2 + 10, -2))
	var_29_6:addTo(var_29_0)

	return var_29_0
end

function var_0_0.didOpen(arg_30_0, arg_30_1)
	var_0_0.super:didOpen(arg_30_1)
	arg_30_0:IsGotoCheckWnd()
end

function var_0_0.IsGotoCheckWnd(arg_31_0)
	if arg_31_0.isGotoCheck and arg_31_0.gotoFundID then
		local var_31_0 = {
			fund_id = arg_31_0.gotoFundID
		}

		arg_31_0:openCheckOrderWnd(var_31_0)
	end
end

return var_0_0
