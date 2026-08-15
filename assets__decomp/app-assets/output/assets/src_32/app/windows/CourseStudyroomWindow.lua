local var_0_0 = class("CourseStudyroomWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.objectSubject
local var_0_3 = xyd.tables.objectClass
local var_0_4 = xyd.tables.objectBook
local var_0_5 = import("framework.scheduler")
local var_0_6 = {
	FREE = 1,
	ENTER = 2,
	STUDYING = 3,
	ENDED = 4
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.course = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.studyInfos = arg_1_0.course.roomInfo.study_infos
	arg_1_0.items = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initItems()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.CHECK_MIDDLE_RED_MARK,
		params = xyd.CheckMiddleRed.PRACTICE
	})
end

function var_0_0.layout(arg_4_0)
	arg_4_0.studyScroll = arg_4_0:nodeByName("study_scroll")
	arg_4_0.logScroll = arg_4_0:nodeByName("log_scroll")

	local var_4_0 = arg_4_0.studyScroll:getContentSize()

	arg_4_0.studyList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.studyScroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.studyList:setBounceable(true)
	arg_4_0.studyList:setDelegate(handler(arg_4_0, arg_4_0.studyListDelegate))

	local var_4_1 = arg_4_0.logScroll:getContentSize()

	arg_4_0.logList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_1.width + 10, var_4_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.logScroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.logList:setBounceable(true)
	arg_4_0.logList:setDelegate(handler(arg_4_0, arg_4_0.logListDelegate))
	arg_4_0:updateStudyList(true)
	arg_4_0:createScheduler()
end

function var_0_0.updateStudyList(arg_5_0, arg_5_1)
	arg_5_0.studyTimeTxts = {}
	arg_5_0.studyInfos = arg_5_0.course.roomInfo.study_infos

	arg_5_0:initItems()

	if arg_5_1 then
		arg_5_0.studyList:reload()
		arg_5_0.logList:reload()
	else
		arg_5_0.studyList:refreshList()
		arg_5_0.logList:refreshList()
	end

	arg_5_0:scrollToEnd(not arg_5_1)
end

function var_0_0.createScheduler(arg_6_0)
	if arg_6_0.handle then
		var_0_5.unscheduleGlobal(arg_6_0.handle)

		arg_6_0.handle = nil
	end

	arg_6_0:updateDownTime()

	arg_6_0.handle = var_0_5.scheduleGlobal(function()
		if not arg_6_0 then
			return
		end

		if arg_6_0:updateDownTime() and not tolua.isnull(arg_6_0.studyList) then
			local var_7_0 = {}

			arg_6_0.course:getStudyroomInfo(var_7_0, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					arg_6_0:updateStudyList()
				end
			end)
		end
	end, 0.01)
end

function var_0_0.updateDownTime(arg_9_0)
	local var_9_0 = false

	for iter_9_0 = 1, #arg_9_0.studyInfos do
		local var_9_1 = arg_9_0.studyTimeTxts[iter_9_0]

		if var_9_1 and not tolua.isnull(var_9_1) then
			local var_9_2 = arg_9_0:getDownTime(arg_9_0.studyInfos[iter_9_0])

			if var_9_2 > xyd.tables.misc.objectClassRoomTime then
				var_9_2 = xyd.tables.misc.objectClassRoomTime
			end

			if var_9_2 <= 0 then
				local var_9_3 = true
			else
				var_9_1:setString(xyd.secondsToString(var_9_2))
			end
		end
	end
end

function var_0_0.getDownTime(arg_10_0, arg_10_1)
	local var_10_0 = xyd.ServerTime.get():getServerTime()

	return arg_10_1.start_time + xyd.tables.misc.objectClassRoomTime - var_10_0
end

function var_0_0.studyListDelegate(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	if cc.ui.UIListView.COUNT_TAG == arg_11_2 then
		return xyd.tables.vip:numStudy(arg_11_0.selfPlayer.vip)
	elseif cc.ui.UIListView.CELL_TAG == arg_11_2 then
		local var_11_0 = arg_11_0.studyList:dequeueItem()

		if not var_11_0 then
			var_11_0 = arg_11_0.studyList:newItem()
		else
			var_11_0:removeAllChildren(true)
		end

		local var_11_1 = arg_11_0:creatStudyItemContent(arg_11_3)
		local var_11_2 = var_11_1:getWidth()
		local var_11_3 = var_11_1:getHeight()

		var_11_0:setItemSize(var_11_2, var_11_3 + 4)
		var_11_0:addContent(var_11_1)
		var_11_1:setPositionY(2)

		return var_11_0
	end
end

function var_0_0.creatStudyItemContent(arg_12_0, arg_12_1)
	local var_12_0 = display.newNode()
	local var_12_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/course/studyroom/study_item.csb")

	arg_12_0:updateStudyItem(var_12_1, arg_12_1)
	arg_12_0:updateStudyItemShow(var_12_1, arg_12_1)
	var_12_1:addTo(var_12_0)
	var_12_1:setAnchorPoint(cc.p(0, 0))
	var_12_0:setContentSize(var_12_1:getChildByName("container"):getContentSize())
	var_12_1:setName("source")

	return var_12_0
end

function var_0_0.getPositionState(arg_13_0, arg_13_1)
	if arg_13_1 > #arg_13_0.studyInfos then
		return var_0_6.FREE
	elseif arg_13_0.studyInfos[arg_13_1].start_time == 0 then
		return var_0_6.ENTER
	elseif arg_13_0.studyInfos[arg_13_1].start_time + xyd.tables.misc.objectClassRoomTime > xyd.ServerTime.get():getServerTime() then
		return var_0_6.STUDYING
	else
		return var_0_6.ENDED
	end
end

function var_0_0.updateStudyItemShow(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_1:getChildByName("container")
	local var_14_1 = var_14_0:getChildByName("sure_btn")
	local var_14_2 = var_14_0:getChildByName("cancel_btn")
	local var_14_3 = arg_14_0:getPositionState(arg_14_2)

	var_14_0:getChildByName("time_bg"):setVisible(false)
	var_14_0:getChildByName("time_txt"):setVisible(false)

	arg_14_0.studyTimeTxts[arg_14_2] = var_14_0:getChildByName("time_txt")

	if var_14_3 == var_0_6.FREE then
		var_14_1:setVisible(false)
		var_14_2:setVisible(false)
		var_14_0:getChildByName("icon_container"):setVisible(false)
		var_14_0:getChildByName("add_icon"):setVisible(true)
		var_14_0:getChildByName("desc_text"):setString(var_0_1:translation("COURSE_POSITION_FREE_TIP"))
	else
		var_14_1:setVisible(true)
		var_14_2:setVisible(true)
		var_14_0:getChildByName("icon_container"):setVisible(true)
		var_14_0:getChildByName("add_icon"):setVisible(false)

		if var_14_3 == var_0_6.STUDYING then
			var_14_1:getChildByName("accelerate_text"):setVisible(true)
			var_14_1:getChildByName("study_text"):setVisible(false)
			var_14_2:getChildByName("cancel_text"):setVisible(true)
			var_14_2:getChildByName("leave_text"):setVisible(false)
			var_14_0:getChildByName("time_bg"):setVisible(true)
			var_14_0:getChildByName("time_txt"):setVisible(true)
			var_14_0:getChildByName("desc_text"):setPositionY(35)
			var_14_0:getChildByName("desc_text"):setString(var_0_1:translation("COURSE_ON_STUDYING_TIP"))
		else
			var_14_1:getChildByName("accelerate_text"):setVisible(false)
			var_14_1:getChildByName("study_text"):setVisible(true)
			var_14_2:getChildByName("cancel_text"):setVisible(false)
			var_14_2:getChildByName("leave_text"):setVisible(true)
			var_14_0:getChildByName("desc_text"):setString(var_0_1:translation("COURSE_SELECT_STUDY_TIP"))
		end
	end
end

function var_0_0.updateStudyItem(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = arg_15_1:getChildByName("container")
	local var_15_1 = var_15_0:getChildByName("sure_btn")
	local var_15_2 = var_15_0:getChildByName("cancel_btn")
	local var_15_3 = var_15_0:getChildByName("add_icon")
	local var_15_4 = arg_15_0.studyInfos[arg_15_2]
	local var_15_5 = arg_15_0:getPositionState(arg_15_2)

	if var_15_5 == var_0_6.FREE then
		var_15_3:setTouchEnabled(true)
		var_15_3:setTouchSwallowEnabled(true)
		var_15_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
			if arg_16_0.name == "began" then
				arg_15_0.scrollViewMoved_ = false

				var_15_3:setScale(1.35)

				return true
			elseif arg_16_0.name == "ended" then
				xyd.playButtonSound()
				var_15_3:setScale(1.5)

				if arg_15_0.scrollViewMoved_ ~= true then
					local function var_16_0(arg_17_0)
						local var_17_0 = {
							partner_id = arg_17_0:getHeroID()
						}

						arg_15_0.course:enterRoom(var_17_0, function(arg_18_0, arg_18_1)
							if arg_18_0 == xyd.error.OK then
								arg_15_0:updateStudyList()
							end
						end)
					end

					local var_16_1 = {}

					var_16_1.is_apply_course = false
					var_16_1.callback = var_16_0

					xyd.WindowManager.get():openWindow("course_select_hero", var_16_1)
				end
			end
		end)
	else
		xyd.setAvatarBorder(arg_15_0.selfPlayer:getHero(var_15_4.partner_id), var_15_0:getChildByName("icon_container"))

		local function var_15_6(arg_19_0)
			local var_19_0 = {
				partner_id = var_15_4.partner_id,
				course_id = arg_19_0
			}

			arg_15_0.course:study(var_19_0, function(arg_20_0, arg_20_1)
				if arg_20_0 == xyd.error.OK then
					arg_15_0:updateStudyList()
				end
			end)
		end

		var_15_1:addTouchEventListener(function(arg_21_0, arg_21_1)
			if arg_21_1 == ccui.TouchEventType.ended and arg_15_0.scrollViewMoved_ ~= true then
				if var_15_5 == var_0_6.STUDYING then
					local var_21_0 = xyd.tables.misc.objectClassRoomMoney * math.ceil(arg_15_0:getDownTime(var_15_4) / 1800) / 2

					if var_21_0 > arg_15_0.selfPlayer.crystal then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
							local var_22_0 = {}

							var_22_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_22_0)
						end, nil, nil, arg_15_0.colorMode)

						return
					end

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("COURSE_SPEED_COST_TIPS"), var_21_0), function()
						local var_23_0 = {
							partner_id = var_15_4.partner_id,
							course_id = var_15_4.course_id
						}

						arg_15_0.course:speedStudy(var_23_0, function(arg_24_0, arg_24_1)
							if arg_24_0 == xyd.error.OK then
								arg_15_0:updateStudyList()
							end
						end)
					end, nil, nil, arg_15_0.colorMode)
				else
					local var_21_1 = {
						partner_id = var_15_4.partner_id
					}

					arg_15_0.course:getCourseInfo(var_21_1, function(arg_25_0, arg_25_1)
						if arg_25_0 == xyd.error.OK then
							local var_25_0 = {
								partner_id = var_15_4.partner_id,
								partner_courses = arg_25_1.partner_courses,
								callback = var_15_6
							}

							xyd.WindowManager.get():openWindow("course_study_select", var_25_0)
						end
					end)
				end
			end
		end)
		var_15_2:addTouchEventListener(function(arg_26_0, arg_26_1)
			if arg_26_1 == ccui.TouchEventType.ended and arg_15_0.scrollViewMoved_ ~= true then
				if var_15_5 ~= var_0_6.STUDYING then
					local var_26_0 = {
						partner_id = var_15_4.partner_id
					}

					arg_15_0.course:leaveRoom(var_26_0, function(arg_27_0, arg_27_1)
						if arg_27_0 == xyd.error.OK then
							arg_15_0:updateStudyList()
						end
					end)
				else
					local var_26_1 = {
						partner_id = var_15_4.partner_id
					}

					arg_15_0.course:cancelStudy(var_26_1, function(arg_28_0, arg_28_1)
						if arg_28_0 == xyd.error.OK then
							arg_15_0:updateStudyList()
						end
					end)
				end
			end
		end)
	end
end

function var_0_0.logListDelegate(arg_29_0, arg_29_1, arg_29_2, arg_29_3)
	if cc.ui.UIListView.COUNT_TAG == arg_29_2 then
		return #arg_29_0.items
	elseif cc.ui.UIListView.CELL_TAG == arg_29_2 then
		local var_29_0 = arg_29_0.logList:dequeueItem() or arg_29_0.logList:newItem()

		var_29_0:removeAllChildren(true)

		local var_29_1 = arg_29_0.items[arg_29_3]

		if var_29_1:getParent() ~= nil then
			var_29_1:removeFromParent(false)
		end

		local var_29_2 = var_29_1:getWidth()
		local var_29_3 = var_29_1:getHeight()

		var_29_0:setItemSize(var_29_2 + 20, var_29_3)
		var_29_0:addContent(var_29_1)

		return var_29_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_29_2 then
		arg_29_0.items[arg_29_3]:removeFromParent(false)
	end
end

function var_0_0.creatlogItemContent(arg_30_0, arg_30_1)
	local var_30_0 = display.newNode()
	local var_30_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/course/studyroom/log_item.csb")
	local var_30_2 = var_30_1:getChildByName("container")
	local var_30_3 = var_30_2:getChildByName("details")

	arg_30_0:colorWords(var_30_3, arg_30_1)
	var_30_2:getChildByName("time_txt"):setString(os.date("%H:%M", arg_30_1.time))
	var_30_2:getChildByName("time_txt"):setPositionY(var_30_3:getContentSize().height - 10)
	var_30_1:addTo(var_30_0)
	var_30_1:setAnchorPoint(cc.p(0, 0))
	var_30_0:setContentSize(var_30_3:getContentSize().width, var_30_3:getContentSize().height + 16)
	var_30_1:setPositionY(8)
	var_30_1:setName("source")

	return var_30_0
end

function var_0_0.getContentTable(arg_31_0, arg_31_1)
	local var_31_0 = {}

	table.insert(var_31_0, arg_31_0.selfPlayer:getHero(arg_31_1.partner_id):getName())

	if arg_31_1.log_id == xyd.StudyRoomLogType.StartStudying or arg_31_1.log_id == xyd.StudyRoomLogType.EndStudying or arg_31_1.log_id == xyd.StudyRoomLogType.HandleCourse or arg_31_1.log_id == xyd.StudyRoomLogType.CancelStudying then
		local var_31_1 = string.format(var_0_1:translation("COURSE_NAME_FORMAT"), var_0_4:name(arg_31_1.course_id))

		table.insert(var_31_0, var_31_1)
	end

	if arg_31_1.log_id == xyd.StudyRoomLogType.EndStudying then
		table.insert(var_31_0, tostring(arg_31_1.param) .. "%")
	end

	return var_31_0
end

function var_0_0.colorWords(arg_32_0, arg_32_1, arg_32_2)
	local var_32_0 = display.newNode()
	local var_32_1 = xyd.tables.objectLog:text(arg_32_2.log_id)
	local var_32_2 = arg_32_0:getContentTable(arg_32_2)
	local var_32_3 = {
		cc.c3b(254, 255, 224),
		xyd.color.GREEN,
		xyd.color.RED
	}
	local var_32_4 = 60
	local var_32_5 = 1
	local var_32_6 = 1
	local var_32_7 = {}
	local var_32_8 = 3
	local var_32_9 = false

	while true do
		local function var_32_10(arg_33_0, arg_33_1)
			local var_33_0 = xyd.utf8len(arg_33_0)
			local var_33_1 = var_32_8

			var_32_8 = var_32_8 + var_33_0

			while var_32_8 > 14 do
				var_32_6 = var_32_6 + 1

				local var_33_2

				if var_33_1 > 13 then
					var_33_1 = 12
				end

				local var_33_3

				var_33_3, arg_33_0 = xyd.getSplitUtf8Str(arg_33_0, 0, (13 - var_33_1) * 3)

				if arg_33_0 then
					var_32_8 = xyd.utf8len(arg_33_0)
				else
					var_32_8 = 0
				end

				var_33_1 = 0

				local var_33_4 = display.newTTFLabel({
					font = "fonts/main_font.ttf",
					size = 20,
					text = var_33_3,
					color = arg_33_1,
					align = cc.TEXT_ALIGNMENT_LEFT
				})

				var_32_0:addChild(var_33_4)
				var_33_4:setPosition(var_32_4, 3)
				var_33_4:setAnchorPoint(cc.p(0, 0))

				var_32_4 = 0

				table.insert(var_32_7, var_33_4)

				for iter_33_0 = 1, #var_32_7 do
					var_32_7[iter_33_0]:setPositionY(var_32_7[iter_33_0]:getPositionY() + 30)
				end
			end

			if not arg_33_0 then
				return
			end

			local var_33_5 = display.newTTFLabel({
				font = "fonts/main_font.ttf",
				size = 20,
				text = arg_33_0,
				color = arg_33_1,
				align = cc.TEXT_ALIGNMENT_LEFT
			})

			var_32_0:addChild(var_33_5)
			var_33_5:setPosition(var_32_4, 3)
			var_33_5:setAnchorPoint(cc.p(0, 0))

			var_32_4 = var_32_4 + var_33_5:getContentSize().width + 3

			table.insert(var_32_7, var_33_5)
		end

		var_32_1 = var_32_1 or ""

		local var_32_11 = string.find(var_32_1, "{")
		local var_32_12 = string.find(var_32_1, "}")

		if var_32_11 and var_32_12 then
			local var_32_13 = string.sub(var_32_1, 1, var_32_11 - 1)
			local var_32_14 = var_32_2[var_32_5]
			local var_32_15 = var_32_3[var_32_5]

			var_32_5 = var_32_5 + 1
			var_32_1 = string.sub(var_32_1, var_32_12 + 1, #var_32_1)

			if var_32_11 < var_32_12 then
				if var_32_14 == nil then
					arg_32_0.is_wrong_item = true

					break
				else
					arg_32_0.is_wrong_item = false
				end

				var_32_10(var_32_13, cc.c3b(241, 186, 67))
				var_32_10("" .. var_32_14, var_32_15)
			else
				print("wrong data.")

				break
			end
		elseif var_32_11 or var_32_12 then
			print("Wrong data.")

			break
		else
			var_32_10(var_32_1, cc.c3b(241, 186, 67))

			break
		end
	end

	arg_32_1:addChild(var_32_0)
	arg_32_1:setContentSize(arg_32_1:getContentSize().width, arg_32_1:getContentSize().height + 30 * (var_32_6 - 1))
end

function var_0_0.scrollListener(arg_34_0, arg_34_1)
	if arg_34_1.name == "began" then
		arg_34_0.scrollViewMoved_ = false
		arg_34_0.prevX_ = arg_34_1.x
	elseif arg_34_1.name == "moved" and 5 <= math.abs(arg_34_1.x - arg_34_0.prevX_) then
		arg_34_0.scrollViewMoved_ = true
	end
end

function var_0_0.didClose(arg_35_0, arg_35_1)
	var_0_0.super:didClose(arg_35_1)

	if arg_35_0.handle then
		var_0_5.unscheduleGlobal(arg_35_0.handle)

		arg_35_0.handle = nil
	end
end

function var_0_0.initItems(arg_36_0)
	arg_36_0.logInfos = arg_36_0.course.roomInfo.log_infos

	for iter_36_0 = #arg_36_0.items + 1, #arg_36_0.logInfos do
		local var_36_0 = arg_36_0:creatlogItemContent(arg_36_0.logInfos[iter_36_0])

		var_36_0:retain()
		table.insert(arg_36_0.items, var_36_0)
	end
end

function var_0_0.scrollToEnd(arg_37_0, arg_37_1)
	local var_37_0 = arg_37_0:getItemsHeight()
	local var_37_1 = arg_37_0.logList:getViewRectInWorldSpace()

	if var_37_0 < var_37_1.height then
		return
	end

	local var_37_2 = arg_37_0.logList:getScrollNode()

	if not arg_37_0.beginScrollPos then
		arg_37_0.beginScrollPos = var_37_2:getPositionY()
	end

	local var_37_3 = var_37_0 + arg_37_0.beginScrollPos - var_37_2:getPositionY()

	if var_37_3 >= var_37_1.height then
		var_37_3 = var_37_3 - var_37_1.height
	end

	if arg_37_1 then
		var_37_2:runAction(cc.MoveBy:create(0.5, cc.p(0, var_37_3)))
	else
		var_37_2:setPositionY(var_37_2:getPositionY() + var_37_3)
	end
end

function var_0_0.getItemsHeight(arg_38_0)
	local var_38_0 = 0

	for iter_38_0 = 1, #arg_38_0.items do
		if arg_38_0.items[iter_38_0] then
			var_38_0 = var_38_0 + (arg_38_0.items[iter_38_0]:getContentSize().height or 0)
		end
	end

	return var_38_0
end

return var_0_0
