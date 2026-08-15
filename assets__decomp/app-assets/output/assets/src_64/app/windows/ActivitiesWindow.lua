local var_0_0 = class("ActivitiesWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activities
local var_0_3 = {
	BOARD = 2,
	ACTIVITY = 1
}
local var_0_4 = 230
local var_0_5 = 104

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	if arg_1_2 then
		arg_1_0.defaultTableId = arg_1_2.default_table_id
	end

	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.activities = arg_1_0.activitiesModel:getActivitiesList()
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.firstEnter = true
end

function var_0_0.refreshRedMark(arg_2_0)
	arg_2_0.activitiesModel:refreshRedMark()

	if arg_2_0.activityRedPoint then
		arg_2_0.activityRedPoint:setVisible(arg_2_0.activitiesModel:getActivityRedMark())
		arg_2_0.activityRedPoint2:setVisible(arg_2_0.activitiesModel:getActivityRedMark())
	end

	if arg_2_0.boardRedPoint then
		arg_2_0.boardRedPoint:setVisible(arg_2_0.activitiesModel:getBoardRedMark())
		arg_2_0.boardRedPoint2:setVisible(arg_2_0.activitiesModel:getBoardRedMark())
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_1)

	arg_3_0.leftContainer = arg_3_0:nodeByName("left_container")
	arg_3_0.rightListContainer = arg_3_0:nodeByName("right_list_container")
	arg_3_0.firstLoad = 1
	arg_3_0.isLeftLayout = false
	arg_3_0.rightItems = {}
	arg_3_0.openedActivities = {}
	arg_3_0.showType = var_0_3.ACTIVITY
	arg_3_0.boardItemContainer = arg_3_0:nodeByName("board_item_container")
	arg_3_0.boardDetailContainer = arg_3_0:nodeByName("board_detail_container")
	arg_3_0.leftPanel_ = arg_3_0:nodeByName("left_panel")

	arg_3_0.leftPanel_:retain()

	arg_3_0.activityBtn = arg_3_0:nodeByName("activity_btn")
	arg_3_0.boardBtn = arg_3_0:nodeByName("board_btn")
	arg_3_0.activityRedPoint = arg_3_0.activityBtn:getChildByName("red_point")
	arg_3_0.boardRedPoint = arg_3_0.boardBtn:getChildByName("red_point")
	arg_3_0.activityRedPoint2 = arg_3_0:nodeByName("activity_show_png"):getChildByName("red_point")
	arg_3_0.boardRedPoint2 = arg_3_0:nodeByName("board_show_png"):getChildByName("red_point")

	arg_3_0:nodeByName("board_show_text"):setString(var_0_1:translation("ACTIVITIES_TEXT1"))
	arg_3_0:nodeByName("activity_show_text"):setString(var_0_1:translation("ACTIVITIES_TEXT2"))
	arg_3_0:nodeByName("board_txt"):setString(var_0_1:translation("ACTIVITIES_TEXT1"))
	arg_3_0:nodeByName("activity_txt"):setString(var_0_1:translation("ACTIVITIES_TEXT2"))
	arg_3_0:refreshRedMark()
	arg_3_0.activityBtn:addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_3_0.showType = var_0_3.ACTIVITY

			arg_3_0:changeShowType()
		end
	end)
	arg_3_0.boardBtn:addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = xyd.StoryData.get():getGuideID()

			if var_5_0 >= xyd.GuideStoryType.ACTIVITY_FOUR and var_5_0 < xyd.GuideStoryType.ACTIVITY_END then
				return false
			end

			xyd.playButtonSound()

			if not arg_3_0.boardInfo then
				arg_3_0.boardInfo = arg_3_0.activitiesModel:getBoardInfoList()

				arg_3_0:boardLayout()
			end

			arg_3_0:loadBoard()
		end
	end)
	arg_3_0:nodeByName("close"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = xyd.StoryData.get():getGuideID()

			if var_6_0 >= xyd.GuideStoryType.ACTIVITY_FOUR and var_6_0 < xyd.GuideStoryType.ACTIVITY_END then
				if not arg_3_0.isLeftLayout then
					xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_END)
					xyd.StoryData.get():persist()
				else
					return
				end
			end

			local var_6_1 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_6_1, false)
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
	arg_3_0:changeShowType()
	arg_3_0:rightLayout()
	arg_3_0:playGuide()
	xyd.WindowManager.get():openWindow("asset_wnd")

	arg_3_0.assetWindow = xyd.WindowManager.get():getWindow("asset_wnd")

	arg_3_0:playWindowAction()
end

function var_0_0.playWindowAction(arg_7_0)
	local var_7_0, var_7_1 = arg_7_0:nodeByName("bg_up"):getPosition()

	arg_7_0:nodeByName("bg_up"):setPosition(var_7_0, var_7_1 + 52)
	transition.moveTo(arg_7_0:nodeByName("bg_up"), {
		time = 0.3,
		y = var_7_1
	})

	local var_7_2, var_7_3 = arg_7_0.assetWindow:getPosition()

	arg_7_0.assetWindow:setPosition(var_7_2, var_7_3 + 52)
	transition.moveTo(arg_7_0.assetWindow, {
		time = 0.3,
		y = var_7_3
	})

	local var_7_4, var_7_5 = arg_7_0.leftContainer:getPosition()

	arg_7_0.leftContainer:setPosition(var_7_4 + 1280, var_7_5)
	transition.moveTo(arg_7_0.leftContainer, {
		time = 0.3,
		x = var_7_4
	})
end

function var_0_0.loadBoard(arg_8_0)
	if arg_8_0.boardInfo and #arg_8_0.boardInfo > 0 then
		arg_8_0.showType = var_0_3.BOARD

		arg_8_0:changeShowType()
	else
		xyd.WindowManager.get():openWindow("toast", {
			message = xyd.tables.translation:translation("ACTIVITIES_BOARD_NONE")
		})
	end
end

function var_0_0.changeShowType(arg_9_0)
	if arg_9_0.showType == var_0_3.ACTIVITY then
		arg_9_0.activityBtn:setEnabled(false)
		arg_9_0.activityBtn:setBright(false)
		arg_9_0.boardBtn:setEnabled(true)
		arg_9_0.boardBtn:setBright(true)
		arg_9_0.leftContainer:setVisible(true)
		arg_9_0.rightListContainer:setVisible(true)
		arg_9_0.boardItemContainer:setVisible(false)
		arg_9_0.boardDetailContainer:setVisible(false)
		arg_9_0:nodeByName("bg_activity"):setVisible(true)
		arg_9_0:nodeByName("bg_board"):setVisible(false)
		arg_9_0:nodeByName("activity_show_png"):setVisible(true)
		arg_9_0:nodeByName("board_btn"):setTouchEnabled(false)
		arg_9_0:nodeByName("activity_btn"):setTouchEnabled(false)

		local var_9_0, var_9_1 = arg_9_0:nodeByName("activity_show_png"):getPosition()
		local var_9_2 = cc.Sequence:create({
			cc.CallFunc:create(function()
				arg_9_0:nodeByName("activity_btn"):setVisible(false)
				arg_9_0:nodeByName("activity_show_png"):setPositionX(var_9_0 + 160)
				arg_9_0:nodeByName("activity_show_png"):scale(0.5)
			end),
			cc.Spawn:create({
				cc.MoveTo:create(0.3, cc.p(var_9_0, var_9_1)),
				cc.ScaleTo:create(0.3, 1)
			})
		})

		arg_9_0:nodeByName("activity_show_png"):runActionOnce(var_9_2)

		local var_9_3, var_9_4 = arg_9_0:nodeByName("board_show_png"):getPosition()
		local var_9_5 = cc.Sequence:create({
			cc.Spawn:create({
				cc.MoveTo:create(0.3, cc.p(var_9_3 + 160, var_9_4)),
				cc.ScaleTo:create(0.3, 0.5)
			}),
			cc.CallFunc:create(function()
				arg_9_0:nodeByName("board_show_png"):setVisible(false)
				arg_9_0:nodeByName("board_show_png"):setPositionX(var_9_3)
				arg_9_0:nodeByName("board_show_png"):scale(1)
			end)
		})

		arg_9_0:nodeByName("board_show_png"):runActionOnce(var_9_5)
		arg_9_0:nodeByName("board_btn"):setVisible(true)
		arg_9_0:nodeByName("board_btn"):setOpacity(0)

		local var_9_6 = cc.Sequence:create({
			cc.Spawn:create({
				cc.FadeIn:create(0.3)
			}),
			cc.CallFunc:create(function()
				arg_9_0:nodeByName("board_btn"):setTouchEnabled(true)
				arg_9_0:nodeByName("activity_btn"):setTouchEnabled(true)
			end)
		})

		arg_9_0:nodeByName("board_btn"):runActionOnce(var_9_6)

		local var_9_7, var_9_8 = arg_9_0:nodeByName("right_container"):getPosition()
		local var_9_9 = cc.Sequence:create({
			cc.CallFunc:create(function()
				arg_9_0:nodeByName("right_container"):setPosition(var_9_7 - 376, var_9_8)
			end),
			cc.Spawn:create({
				cc.MoveTo:create(0.3, cc.p(var_9_7, var_9_8))
			})
		})

		arg_9_0:nodeByName("right_container"):runActionOnce(var_9_9)
	else
		arg_9_0.activityBtn:setEnabled(true)
		arg_9_0.activityBtn:setBright(true)
		arg_9_0.boardBtn:setEnabled(false)
		arg_9_0.boardBtn:setBright(false)
		arg_9_0.leftContainer:setVisible(false)
		arg_9_0.rightListContainer:setVisible(false)
		arg_9_0.boardItemContainer:setVisible(true)
		arg_9_0.boardDetailContainer:setVisible(true)
		arg_9_0:nodeByName("bg_activity"):setVisible(false)
		arg_9_0:nodeByName("bg_board"):setVisible(true)
		arg_9_0:nodeByName("board_show_png"):setVisible(true)
		arg_9_0:nodeByName("board_btn"):setTouchEnabled(false)
		arg_9_0:nodeByName("activity_btn"):setTouchEnabled(false)

		local var_9_10, var_9_11 = arg_9_0:nodeByName("board_show_png"):getPosition()
		local var_9_12 = cc.Sequence:create({
			cc.CallFunc:create(function()
				arg_9_0:nodeByName("board_btn"):setVisible(false)
				arg_9_0:nodeByName("board_show_png"):setPositionX(var_9_10 + 160)
				arg_9_0:nodeByName("board_show_png"):scale(0.5)
			end),
			cc.Spawn:create({
				cc.MoveTo:create(0.3, cc.p(var_9_10, var_9_11)),
				cc.ScaleTo:create(0.3, 1)
			})
		})

		arg_9_0:nodeByName("board_show_png"):runActionOnce(var_9_12)

		local var_9_13, var_9_14 = arg_9_0:nodeByName("activity_show_png"):getPosition()
		local var_9_15 = cc.Sequence:create({
			cc.Spawn:create({
				cc.MoveTo:create(0.3, cc.p(var_9_13 + 160, var_9_14)),
				cc.ScaleTo:create(0.3, 0.5)
			}),
			cc.CallFunc:create(function()
				arg_9_0:nodeByName("activity_show_png"):setVisible(false)
				arg_9_0:nodeByName("activity_show_png"):setPositionX(var_9_13)
				arg_9_0:nodeByName("activity_show_png"):scale(1)
			end)
		})

		arg_9_0:nodeByName("activity_show_png"):runActionOnce(var_9_15)
		arg_9_0:nodeByName("activity_btn"):setVisible(true)
		arg_9_0:nodeByName("activity_btn"):setOpacity(0)

		local var_9_16 = cc.Sequence:create({
			cc.Spawn:create({
				cc.FadeIn:create(0.3)
			}),
			cc.CallFunc:create(function()
				arg_9_0:nodeByName("board_btn"):setTouchEnabled(true)
				arg_9_0:nodeByName("activity_btn"):setTouchEnabled(true)
			end)
		})

		arg_9_0:nodeByName("activity_btn"):runActionOnce(var_9_16)

		local var_9_17, var_9_18 = arg_9_0:nodeByName("right_container"):getPosition()
		local var_9_19 = cc.Sequence:create({
			cc.CallFunc:create(function()
				arg_9_0:nodeByName("right_container"):setPosition(var_9_17 - 376, var_9_18)
			end),
			cc.Spawn:create({
				cc.MoveTo:create(0.3, cc.p(var_9_17, var_9_18))
			})
		})

		arg_9_0:nodeByName("right_container"):runActionOnce(var_9_19)
	end
end

function var_0_0.boardLayout(arg_18_0)
	if arg_18_0.boardInfo == nil or #arg_18_0.boardInfo == 0 then
		return
	end

	local var_18_0 = arg_18_0.boardItemContainer:getContentSize()

	arg_18_0.boardList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_18_0.width, var_18_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_18_0.boardItemContainer):onScroll(handler(arg_18_0, arg_18_0.scrollListener))

	for iter_18_0, iter_18_1 in ipairs(arg_18_0.boardInfo) do
		local var_18_1 = json.decode(iter_18_1.content) or {}
		local var_18_2 = {
			parent = arg_18_0.boardDetailContainer,
			title = iter_18_1.title,
			content = var_18_1.content or iter_18_1.content,
			url = var_18_1.img_url
		}
		local var_18_3 = import("app.windows.ActivityBoardDetail").new(var_18_2)
		local var_18_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/board/board_item.csb")
		local var_18_5 = var_18_4:getChildByName("container")
		local var_18_6 = var_18_5:getChildByName("red_point")

		arg_18_0:setClick(var_18_5, false)

		if arg_18_0.activitiesModel.noticeIDs[iter_18_1.table_id] ~= nil then
			var_18_6:setVisible(false)
		end

		if iter_18_0 == 1 then
			var_18_3:show()

			arg_18_0.lastBoardId = iter_18_1.table_id

			var_18_6:setVisible(false)

			if arg_18_0.lastBoardCell and not tolua.isnull(arg_18_0.lastBoardCell) then
				arg_18_0:setClick(arg_18_0.lastBoardCell:getChildByName("container"), false)
			end

			arg_18_0:setClick(var_18_5, true)
			xyd.db.boardRedMark:updateNoticeID(arg_18_0.activitiesModel.player.playerID, iter_18_1.table_id)
			arg_18_0:refreshRedMark()

			arg_18_0.lastBoardCell = var_18_4
		end

		local var_18_7 = arg_18_0.boardList:newItem()
		local var_18_8 = display.newNode()

		var_18_5:getChildByName("title"):setString(iter_18_1.title)
		var_18_5:getChildByName("bg_time"):getChildByName("date"):setString(iter_18_1.start_date)
		var_18_4:addTo(var_18_8)
		var_18_4:setTouchEnabled(true)
		var_18_4:setTouchSwallowEnabled(false)
		var_18_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
			if arg_19_0.name == "began" then
				var_18_5:setScale(0.9)

				return true
			elseif arg_19_0.name == "ended" then
				var_18_5:setScale(1)

				if not arg_18_0.scrollViewMoved_ and (not arg_18_0.lastBoardId or arg_18_0.lastBoardId ~= iter_18_1.table_id) then
					if arg_18_0.lastBoardCell and not tolua.isnull(arg_18_0.lastBoardCell) then
						arg_18_0:setClick(arg_18_0.lastBoardCell:getChildByName("container"), false)
					end

					arg_18_0.boardDetailContainer:removeAllChildren()
					var_18_3:show()

					arg_18_0.lastBoardId = iter_18_1.table_id

					var_18_6:setVisible(false)
					arg_18_0:setClick(var_18_5, true)

					arg_18_0.lastBoardCell = var_18_4

					xyd.db.boardRedMark:updateNoticeID(arg_18_0.activitiesModel.player.playerID, iter_18_1.table_id)
					arg_18_0:refreshRedMark()
				end
			end
		end)
		var_18_8:setContentSize(var_0_4, var_0_5)
		var_18_7:addContent(var_18_8)
		var_18_7:setItemSize(var_0_4, var_0_5 + 33)
		arg_18_0.boardList:addItem(var_18_7)
	end

	arg_18_0.boardList:reload()
end

function var_0_0.rightLayout(arg_20_0)
	if arg_20_0.rightList then
		arg_20_0.nodeX = arg_20_0.rightList.scrollNode:getPositionX()
		arg_20_0.nodeY = arg_20_0.rightList.scrollNode:getPositionY()

		arg_20_0.rightList:removeAllItems()
	else
		local var_20_0 = arg_20_0.rightListContainer:getContentSize()

		arg_20_0.rightList = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, var_20_0.width, var_20_0.height),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		})

		arg_20_0.rightList:addTo(arg_20_0.rightListContainer)
		arg_20_0.rightList:onScroll(handler(arg_20_0, arg_20_0.scrollListener))
	end

	local var_20_1 = 0

	for iter_20_0 = 1, #arg_20_0.activities do
		local var_20_2 = arg_20_0.activities[iter_20_0]
		local var_20_3 = arg_20_0:createAcitivityShow(var_20_2.table_id, iter_20_0)

		if var_20_3 then
			if arg_20_0:checkIsOpen(var_20_2) and not arg_20_0:activityVanishCheck(var_20_2) then
				var_20_1 = var_20_1 + 1
				arg_20_0.openedActivities[var_20_2.table_id] = var_20_3

				local var_20_4 = arg_20_0.rightList:newItem()
				local var_20_5 = display.newNode()

				arg_20_0:initRightCell(var_20_2, var_20_5, iter_20_0)
				var_20_5:setContentSize(var_0_4, var_0_5)
				var_20_4:addContent(var_20_5)
				var_20_4:setItemSize(var_0_4, var_0_5 + 33)
				arg_20_0.rightList:addItem(var_20_4)
			else
				var_20_3:release()
			end
		end
	end

	arg_20_0.rightList:reload()

	if arg_20_0.firstLoad == 1 then
		arg_20_0.rightList.scrollNode:setPosition(0, -(var_0_5 + 33) * var_20_1 + 667)
	elseif arg_20_0.nodeX and arg_20_0.nodeY then
		arg_20_0.rightList.scrollNode:setPosition(arg_20_0.nodeX, arg_20_0.nodeY)
	end

	arg_20_0.firstLoad = 0
end

function var_0_0.initRightCell(arg_21_0, arg_21_1, arg_21_2, arg_21_3)
	local var_21_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/main_wnd/activity_list_item.csb")
	local var_21_1 = "images/activities/" .. arg_21_1.table_id .. ".png"
	local var_21_2 = "images/activities/" .. arg_21_1.table_id .. "_0.png"
	local var_21_3 = xyd.SpriteLoader.new(var_21_1, nil, nil, xyd.DefaultImageType.ACTIVITIY_ICON, container)
	local var_21_4 = xyd.SpriteLoader.new(var_21_2, nil, nil, xyd.DefaultImageType.ACTIVITIY_ICON_CLICK, container)
	local var_21_5 = var_21_0:getChildByName("container")

	arg_21_0:setClick(var_21_5, false)

	local var_21_6 = var_21_5:getChildByName("red_point")

	if arg_21_0.activitiesModel:getRedMarkMap(arg_21_1.table_id).state <= 0 then
		var_21_6:setVisible(false)
	else
		var_21_6:setVisible(true)
	end

	local var_21_7 = var_21_5:getChildByName("bg_time"):getChildByName("activity_time")
	local var_21_8 = var_0_2:cutOffTime(arg_21_1.table_id)
	local var_21_9
	local var_21_10

	if arg_21_1.details and arg_21_1.details.start_time then
		var_21_9 = arg_21_1.details.start_time
	else
		var_21_9 = arg_21_1.start_time
	end

	if arg_21_1.details and arg_21_1.details.start_time then
		var_21_10 = arg_21_1.details.end_time
	else
		var_21_10 = arg_21_1.end_time
	end

	if arg_21_1.table_id == xyd.Activities.PointExchange or arg_21_1.table_id == xyd.Activities.GreenHand or arg_21_1.table_id == xyd.Activities.MoeGirls then
		var_21_10 = var_21_9 + var_21_8 * 24 * 60 * 60
	end

	local var_21_11, var_21_12, var_21_13 = arg_21_0:createTimeTxt(var_21_9, var_21_10, var_21_8)

	if var_21_8 < 0 then
		var_21_5:getChildByName("bg_time"):setVisible(false)
		var_21_5:getChildByName("icon_1"):setVisible(true)
	elseif var_21_13 == 1 then
		var_21_5:getChildByName("bg_time"):setVisible(false)
		var_21_5:getChildByName("icon_2"):setVisible(true)
	else
		var_21_7:setString(var_21_11)
	end

	var_21_3:addTo(var_21_0:getChildByName("container"))
	var_21_3:setLocalZOrder(-100)
	var_21_3:setAnchorPoint(cc.p(0, 0))
	var_21_3:setPosition(0, 0)
	var_21_4:addTo(var_21_5:getChildByName("bg_click"))
	var_21_4:setLocalZOrder(-100)
	var_21_4:setAnchorPoint(cc.p(0, 0.5))
	var_21_4:setPosition(0, 0)
	var_21_0:addTo(arg_21_2)
	var_21_0:setAnchorPoint(cc.p(0, 0))
	var_21_0:setTouchSwallowEnabled(false)

	if arg_21_0.isLeftLayout then
		if arg_21_3 == arg_21_0.lastClickActivity then
			arg_21_0.lastActivityCell = var_21_0

			arg_21_0:setClick(var_21_5, true)
		end
	elseif (not arg_21_0.defaultTableId or arg_21_0.defaultTableId == -1 or arg_21_0.activities[arg_21_3].table_id == arg_21_0.defaultTableId) and arg_21_0.activities[arg_21_3].table_id ~= xyd.Activities.ZhaoYunSkin then
		arg_21_0.lastActivityCell = var_21_0

		arg_21_0:setClick(var_21_5, true)
		arg_21_0:leftLayout(arg_21_3)

		arg_21_0.lastClickActivity = arg_21_3

		if arg_21_0.activitiesModel:getRedMarkMap(arg_21_1.table_id).state ~= 0 then
			arg_21_0.activitiesModel:clearRedMarkState(arg_21_1.table_id, 1)

			if arg_21_0.activitiesModel:getRedMarkMap(arg_21_1.table_id).state == 0 then
				var_21_6:setVisible(false)
			end
		end

		arg_21_0.isLeftLayout = true
	end

	local var_21_14 = display.newNode()

	var_21_14:setContentSize(var_0_4, var_0_5)
	var_21_14:setTouchEnabled(true)
	var_21_14:setTouchSwallowEnabled(false)
	var_21_14:setAnchorPoint(cc.p(0, 0))
	var_21_14:addTo(var_21_0)
	var_21_14:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
		if arg_22_0.name == "began" then
			var_21_0:getChildByName("container"):setScale(0.9)

			return true
		elseif arg_22_0.name == "ended" then
			var_21_0:getChildByName("container"):setScale(1)

			if not arg_21_0.scrollViewMoved_ then
				if arg_21_0.activitiesModel:getRedMarkMap(arg_21_1.table_id).state ~= 0 then
					arg_21_0.activitiesModel:clearRedMarkState(arg_21_1.table_id, 1)

					if arg_21_0.activitiesModel:getRedMarkMap(arg_21_1.table_id).state == 0 then
						var_21_6:setVisible(false)
					end
				end

				for iter_22_0, iter_22_1 in pairs(arg_21_0.openedActivities) do
					if iter_22_0 ~= arg_21_1.table_id and iter_22_1 then
						iter_22_1:release()
					end
				end

				if not arg_21_0.lastClickActivity or arg_21_0.lastClickActivity ~= arg_21_3 then
					if arg_21_0.lastActivityCell and not tolua.isnull(arg_21_0.lastActivityCell) then
						arg_21_0:setClick(arg_21_0.lastActivityCell:getChildByName("container"), false)
					end

					arg_21_0:setClick(var_21_5, true)
					arg_21_0:leftLayout(arg_21_3)

					arg_21_0.lastClickActivity = arg_21_3
					arg_21_0.lastActivityCell = var_21_0
				end

				if arg_21_1.table_id == xyd.Activities.FBDianZan then
					xyd.FBDianZan()
				end

				if arg_21_1.table_id == xyd.Activities.NEW_DATE then
					arg_21_0:playGuide()
				end
			end
		end
	end)

	if var_21_13 == 1 then
		arg_21_0:GrayNode(var_21_0)
	end

	arg_21_0.rightItems[tostring(arg_21_1.table_id)] = var_21_0
end

function var_0_0.updateActivityRedMark(arg_23_0, arg_23_1)
	if arg_23_1 then
		local var_23_0 = arg_23_0.rightItems[tostring(arg_23_1.table_id)]:getChildByName("container"):getChildByName("red_point")

		if arg_23_0.activitiesModel:getRedMarkMap(arg_23_1.table_id).state <= 0 then
			var_23_0:setVisible(false)
		else
			var_23_0:setVisible(true)
		end

		return
	else
		for iter_23_0, iter_23_1 in pairs(arg_23_0.rightItems) do
			local var_23_1 = iter_23_1:getChildByName("container"):getChildByName("red_point")

			if arg_23_0.activitiesModel:getRedMarkMap(tonumber(iter_23_0)).state <= 0 then
				var_23_1:setVisible(false)
			else
				var_23_1:setVisible(true)
			end
		end
	end
end

function var_0_0.GrayNode(arg_24_0, arg_24_1, arg_24_2)
	if not arg_24_2 then
		local var_24_0 = cc.GLProgram:createWithByteArrays(xyd.shader.NO_MVP_VERT_STRING, xyd.shader.GRAY_FRAG_STRING)

		arg_24_2 = cc.GLProgramState:create(var_24_0)
	end

	arg_24_1:setGLProgramState(arg_24_2)

	for iter_24_0, iter_24_1 in pairs(arg_24_1:getChildren()) do
		arg_24_0:GrayNode(iter_24_1, arg_24_2)
	end
end

function var_0_0.setClick(arg_25_0, arg_25_1, arg_25_2)
	arg_25_1:getChildByName("bg_click"):setVisible(arg_25_2)
	arg_25_1:getChildByName("block"):setVisible(not arg_25_2)

	if arg_25_2 then
		arg_25_1:getChildByName("bg_time"):setPosition(219, 40)
		arg_25_1:getChildByName("red_point"):setPosition(215, 104)

		if arg_25_1:getChildByName("icon_1") then
			arg_25_1:getChildByName("icon_1"):setPosition(40, 110)
			arg_25_1:getChildByName("icon_2"):setPosition(30, 110)
		end

		if arg_25_1:getChildByName("title") then
			arg_25_1:getChildByName("title"):setPosition(106, 14)
		end
	else
		arg_25_1:getChildByName("bg_time"):setPosition(193, 48)
		arg_25_1:getChildByName("red_point"):setPosition(190, 98)

		if arg_25_1:getChildByName("icon_1") then
			arg_25_1:getChildByName("icon_1"):setPosition(40, 102)
			arg_25_1:getChildByName("icon_2"):setPosition(30, 102)
		end

		if arg_25_1:getChildByName("title") then
			arg_25_1:getChildByName("title"):setPosition(95, 20)
		end
	end
end

function var_0_0.updateRightCell(arg_26_0, arg_26_1)
	if not arg_26_1 or not arg_26_0.rightItems[tostring(arg_26_1)] then
		return
	end

	local var_26_0 = arg_26_0.rightItems[tostring(arg_26_1)]:getChildByName("container"):getChildByName("red_point")

	if arg_26_0.activitiesModel:getRedMarkMap(arg_26_1).state <= 0 then
		var_26_0:setVisible(false)
	else
		var_26_0:setVisible(true)
	end

	arg_26_0:refreshRedMark()
end

function var_0_0.leftLayout(arg_27_0, arg_27_1)
	arg_27_0.count = arg_27_1

	arg_27_0.leftContainer:removeAllChildren()
	arg_27_0.leftPanel_:addTo(arg_27_0.leftContainer, -1)
	arg_27_0.leftPanel_:setName("left_panel")

	local var_27_0 = arg_27_0.activities[arg_27_1]

	print("====================================", arg_27_1, var_27_0.table_id)

	if arg_27_0.openedActivities[var_27_0.table_id] then
		if arg_27_0.firstEnter then
			local var_27_1 = xyd.AssetLoader.get():loadSprite("images/main_scene.png")

			var_27_1:setAnchorPoint(0, 0)
			var_27_1:setPosition(0, 0)
			arg_27_0:nodeByName("bg_activity"):addChild(var_27_1)

			arg_27_0.firstEnter = false
		end

		xyd.AssetDownload.get():preloadActivitiesByTableID(tostring(var_27_0.table_id), function()
			arg_27_0:nodeByName("bg_activity"):removeAllChildren()

			local var_28_0 = "windows/activities/" .. var_27_0.table_id .. "/" .. var_27_0.table_id .. "_bg.png"

			if cc.FileUtils:getInstance():isFileExist(var_28_0) then
				local var_28_1 = xyd.AssetLoader.get():loadSprite(var_28_0)

				arg_27_0:nodeByName("bg_activity"):addChild(var_28_1)
				var_28_1:setAnchorPoint(0, 0)
				var_28_1:setPosition(0, 0)
				arg_27_0.leftContainer:setPositionX(0)
				arg_27_0.openedActivities[var_27_0.table_id]:show()
			else
				local var_28_2 = xyd.AssetLoader.get():loadSprite("images/main_scene.png")

				arg_27_0:nodeByName("bg_activity"):addChild(var_28_2)
				var_28_2:setAnchorPoint(0, 0)
				var_28_2:setPosition(0, 0)
				arg_27_0.leftContainer:setPositionX(400)
				arg_27_0.openedActivities[var_27_0.table_id]:show(nil, true)
			end

			arg_27_0:playGuide()
		end)
	end
end

function var_0_0.createAcitivityShow(arg_29_0, arg_29_1, arg_29_2)
	if var_0_2:isShow(arg_29_1) % 2 ~= 1 then
		return false
	end

	local var_29_0 = {
		idx = arg_29_2,
		tableID = arg_29_1,
		parent = arg_29_0.leftContainer
	}

	return import("app.windows.activities.Activity" .. arg_29_1).new(var_29_0)
end

function var_0_0.checkTime(arg_30_0, arg_30_1)
	local var_30_0 = xyd.ServerTime.get():getServerTime()
	local var_30_1 = arg_30_1.start_time
	local var_30_2 = arg_30_1.end_time

	if arg_30_1.days < 0 or arg_30_1.days > 0 and var_30_1 <= var_30_0 and var_30_0 <= var_30_2 then
		return true
	end

	return false
end

function var_0_0.checkIsOpen(arg_31_0, arg_31_1)
	if arg_31_1.is_open == 1 and arg_31_1.days == -1 then
		return true
	elseif arg_31_1.days > 0 then
		return true
	else
		return false
	end
end

function var_0_0.didOpen(arg_32_0, arg_32_1)
	arg_32_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.willClose(arg_33_0, arg_33_1)
	for iter_33_0, iter_33_1 in pairs(arg_33_0.openedActivities) do
		if iter_33_1 then
			iter_33_1:release()

			iter_33_1 = nil
		end
	end
end

function var_0_0.didClose(arg_34_0, arg_34_1)
	local var_34_0 = xyd.StoryData.get():getGuideID()
	local var_34_1

	if var_34_0 == xyd.GuideStoryType.ACTIVITY_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_START)
		xyd.StoryData.get():persist()
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.PLAY_GUIDE,
			params = {
				guide_id = xyd.GuideStoryType.GUIDE_FIGHT_4_START
			}
		})

		var_34_1 = true
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_MAINSCENE_LEFT_LIVE2D
	})
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {
			quickAction = var_34_1
		}
	})
	xyd.WindowManager.get():closeWindow("asset_wnd")
end

function var_0_0.activityVanishCheck(arg_35_0, arg_35_1)
	if arg_35_0.player.lev < var_0_2:levelReq(arg_35_1.table_id) then
		return true
	end

	local var_35_0 = xyd.ServerTime.get():getServerTime()

	if arg_35_1.days == -1 then
		if arg_35_1.details and arg_35_1.details.is_awarded and arg_35_1.details.is_awarded == 1 then
			if arg_35_1.table_id == xyd.Activities.SevenLogin or arg_35_1.table_id == xyd.Activities.SmallMonthCard or arg_35_1.table_id == xyd.Activities.MonthCard then
				return false
			else
				return true
			end
		end

		if arg_35_1.details and arg_35_1.details.is_awards then
			local var_35_1 = 0

			for iter_35_0, iter_35_1 in ipairs(xyd.luaStringSplit(arg_35_1.details.is_awards, "|")) do
				if iter_35_1 == "0" then
					var_35_1 = 1

					break
				end
			end

			if var_35_1 == 0 then
				return true
			end
		end

		if arg_35_1.details and arg_35_1.details.start_time and arg_35_1.table_id ~= xyd.Activities.SevendayGoal then
			if arg_35_1.table_id == xyd.Activities.PointExchange then
				local var_35_2 = var_0_2:cutOffTime(arg_35_1.table_id)

				if var_35_0 >= arg_35_1.details.end_time + var_35_2 * 24 * 60 * 60 then
					return true
				end
			elseif var_35_0 >= arg_35_1.details.end_time then
				return true
			end
		end
	elseif var_35_0 - arg_35_1.end_time >= 86400 then
		if xyd.db.activitiesIds:isActivityExist(arg_35_0.player.playerID, arg_35_1.table_id) then
			xyd.db.activitiesIds:deleteActivitiesId(arg_35_0.player.playerID, arg_35_1.table_id)
		end

		return true
	end

	return false
end

function var_0_0.scrollListener(arg_36_0, arg_36_1)
	if arg_36_1.name == "began" then
		arg_36_0.scrollViewMoved_ = false
		arg_36_0.prevY_ = arg_36_1.y
	elseif arg_36_1.name == "moved" and 20 <= math.abs(arg_36_1.y - arg_36_0.prevY_) then
		arg_36_0.scrollViewMoved_ = true
	end
end

function var_0_0.createTimeTxt(arg_37_0, arg_37_1, arg_37_2, arg_37_3)
	local var_37_0
	local var_37_1
	local var_37_2 = 0

	if arg_37_3 < 0 then
		var_37_0 = var_0_1:translation("FOREVER")
		var_37_1 = cc.c3b(255, 168, 0)

		return var_37_0, var_37_1, var_37_2
	end

	local var_37_3 = xyd.ServerTime.get():getServerTime()
	local var_37_4 = var_37_3 + (86400 - xyd.ServerTime.get():getSecondsOfDay())

	if var_37_3 < arg_37_1 then
		local var_37_5 = (arg_37_1 - var_37_4) / 86400

		if var_37_5 < 1 and var_37_5 >= 0 then
			var_37_0 = string.format(var_0_1:translation("ACTIVITY_BEGIN_TOMORROW"), os.date("%X", arg_37_1))
		elseif var_37_5 < 0 then
			var_37_0 = string.format(var_0_1:translation("ACTIVITY_BEGIN_TODAY"), os.date("%X", arg_37_1))
		else
			local var_37_6 = math.ceil(var_37_5)

			var_37_0 = string.format(var_0_1:translation("ACTIVITY_BEGIN_DAYS"), var_37_6)
		end

		var_37_1 = cc.c3b(190, 39, 23)
	elseif arg_37_2 <= var_37_3 then
		var_37_0 = var_0_1:translation("ACTIVITY_FINISHED")
		var_37_1 = cc.c3b(190, 39, 23)
		var_37_2 = 1
	elseif arg_37_1 <= var_37_3 and var_37_3 < arg_37_2 then
		local var_37_7 = (arg_37_2 - var_37_4) / 86400

		if var_37_7 < 0 then
			var_37_0 = string.format(var_0_1:translation("ACTIVITY_FINISH_TODAY"), os.date("%X", arg_37_2))
		elseif var_37_7 < 1 and var_37_7 >= 0 then
			var_37_0 = string.format(var_0_1:translation("ACTIVITY_FINISH_TOMORROW"), os.date("%X", arg_37_2))
		else
			local var_37_8 = math.ceil(var_37_7)

			var_37_0 = string.format(var_0_1:translation("ACTIVITY_FINISH_DAYS"), var_37_8)
		end

		var_37_1 = cc.c3b(255, 108, 0)
	end

	return var_37_0, var_37_1, var_37_2
end

function var_0_0.playGuide(arg_38_0)
	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	local var_38_0 = xyd.StoryData.get():getGuideID()

	if var_38_0 == xyd.GuideStoryType.ACTIVITY_FOUR then
		if not arg_38_0.isLeftLayout then
			return
		elseif not arg_38_0.rightItems[tostring(xyd.Activities.NEW_DATE)] then
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_END, true)
			xyd.StoryData.get():persist()

			return
		end

		local var_38_1 = arg_38_0.rightItems[tostring(xyd.Activities.NEW_DATE)]
		local var_38_2 = {
			680,
			250
		}
		local var_38_3 = false
		local var_38_4 = var_38_1:getChildByName("container"):getContentSize()
		local var_38_5 = cc.p(var_38_1:getPosition())
		local var_38_6 = var_38_1:getParent():convertToWorldSpace(cc.p(var_38_5.x + var_38_4.width / 2, var_38_5.y + var_38_4.height / 2))
		local var_38_7 = arg_38_0:convertToNodeSpace(var_38_6)

		xyd.showGuideWnd(var_38_1, var_38_7, var_38_4, 1, var_38_2, var_38_3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_FIVE, true)
	elseif var_38_0 == xyd.GuideStoryType.ACTIVITY_FIVE then
		arg_38_0:showOnlyDialogGuide(function()
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_SIX, true)
			arg_38_0:playGuide()
		end)
	elseif var_38_0 == xyd.GuideStoryType.ACTIVITY_SIX then
		arg_38_0:showOnlyDialogGuide(function()
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_SEVEN, true)
			arg_38_0:playGuide()
		end)
	elseif var_38_0 == xyd.GuideStoryType.ACTIVITY_SEVEN then
		arg_38_0:showOnlyDialogGuide(function()
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_END, true)
			xyd.StoryData.get():persist()
		end)
	end
end

function var_0_0.showOnlyDialogGuide(arg_42_0, arg_42_1)
	if xyd.WindowManager.get():isWindowOpen("guide_only_dialog") then
		xyd.WindowManager.get():closeWindow("guide_only_dialog")
	end

	local var_42_0 = true
	local var_42_1
	local var_42_2 = cc.p(600, 100)
	local var_42_3 = xyd.StoryData.get():getGuideID()
	local var_42_4 = {
		tipPosition = var_42_2,
		right = var_42_0
	}

	if arg_42_1 then
		var_42_4.callback = arg_42_1
	else
		function var_42_4.callback()
			arg_42_0:playGuide()
		end
	end

	local var_42_5 = xyd.WindowManager.get():openWindow("guide_only_dialog", var_42_4)
end

return var_0_0
