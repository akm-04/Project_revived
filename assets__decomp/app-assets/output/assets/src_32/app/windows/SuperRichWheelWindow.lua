local var_0_0 = class("SuperRichWheelWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")
local var_0_3 = 45
local var_0_4 = xyd.tables.activityRichMission

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:updatedata()

	arg_1_0.pos = arg_1_2.pos
	arg_1_0.gridInfo = arg_1_2.info
	arg_1_0.stationType = arg_1_2.grid_type
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	var_0_0.super.willClose(arg_3_0, arg_3_1)

	if arg_3_0.handle then
		var_0_2.unscheduleGlobal(arg_3_0.handle)

		arg_3_0.handle = nil
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0.scroll = arg_4_0:nodeByName("scroll")

	local var_4_0 = arg_4_0.scroll:getContentSize()

	arg_4_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.scrollList:setBounceable(false)
	arg_4_0.scrollList:setDelegate(handler(arg_4_0, arg_4_0.scrollListDelegate))
	arg_4_0.scrollList:reload()
	arg_4_0:setButtonClick()
	arg_4_0:nodeByName("down_btn"):setVisible(false)
	arg_4_0:nodeByName("index_text"):setVisible(true)
	arg_4_0:nodeByName("select_task_tip"):setVisible(false)
	arg_4_0:nodeByName("cancel_btn"):setVisible(false)
	arg_4_0:nodeByName("current"):setVisible(true)
	arg_4_0:nodeByName("award_btn"):setVisible(false)
	arg_4_0:updateAwardBtn()

	arg_4_0.wheel_decade = arg_4_0:nodeByName("index_pos")
	arg_4_0.wheelIndex = xyd.AssetLoader.get():loadLabel(nil, "wheel_num")

	arg_4_0.wheelIndex:addTo(arg_4_0.wheel_decade)
	arg_4_0.wheelIndex:setAnchorPoint(cc.p(0.5, 0.3))
	arg_4_0.wheelIndex:setScale(1)
	arg_4_0.wheelIndex:setString(arg_4_0.conduct)
	arg_4_0:setFerrisPos()

	if arg_4_0.conduct ~= 1 and arg_4_0.firstin then
		arg_4_0.conduct = arg_4_0.conduct - 1

		arg_4_0:rotateWheel()

		arg_4_0.conduct = arg_4_0.conduct + 1

		arg_4_0:updateNowWheelNum()
	else
		arg_4_0.angle = 56 - 22.5 * arg_4_0.conduct
	end
end

function var_0_0.updatedata(arg_5_0, arg_5_1)
	arg_5_0.superRich = xyd.ModelManager.get():loadModel(xyd.ModelType.SUPER_RICH)
	arg_5_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_5_0.missionInfo = arg_5_0.superRich.missionInfo
	arg_5_0.reqs = arg_5_0.missionInfo.reqs
	arg_5_0.times = arg_5_0.missionInfo.times
	arg_5_0.progress = arg_5_0.missionInfo.counts
	arg_5_0.ids = arg_5_0.missionInfo.ids
	arg_5_0.lev = arg_5_0.times == 0 and arg_5_0.missionInfo.lev - 1 or arg_5_0.missionInfo.lev

	local function var_5_0(arg_6_0)
		local var_6_0 = tonumber(arg_5_0.ids[arg_6_0])
		local var_6_1 = tonumber(arg_5_0.reqs[arg_6_0])

		return string.format(var_0_4:desc(var_6_0), var_6_1)
	end

	arg_5_0.data = {
		{
			txt = var_5_0(1),
			progress = arg_5_0.progress[1],
			totalTaskNum = arg_5_0.reqs[1]
		},
		{
			txt = var_5_0(2),
			progress = arg_5_0.progress[2],
			totalTaskNum = arg_5_0.reqs[2]
		},
		{
			txt = var_5_0(3),
			progress = arg_5_0.progress[3],
			totalTaskNum = arg_5_0.reqs[3]
		}
	}
	arg_5_0.mission = {
		{
			complete = false
		},
		{
			complete = false
		},
		{
			complete = false
		}
	}
	arg_5_0.conduct = tonumber(arg_5_0.lev)

	if arg_5_0.conduct ~= 1 and arg_5_0.firstin then
		arg_5_0.angle = 78.5 - 22.5 * arg_5_0.conduct
	else
		arg_5_0.angle = 56 - 22.5 * arg_5_0.conduct
	end

	arg_5_0.firstin = true

	if arg_5_0.data[1].progress ~= 0 or arg_5_0.data[2].progress ~= 0 or arg_5_0.data[3].progress ~= 0 then
		arg_5_0.firstin = false
	end
end

function var_0_0.updateAwarded(arg_7_0)
	local var_7_0 = arg_7_0:nodeByName("award_btn")

	var_7_0:setVisible(true)
	var_7_0:setTouchEnabled(false)
	var_7_0:getChildByName("award_text"):setVisible(false)
	var_7_0:getChildByName("awarded_text"):setVisible(true)
end

function var_0_0.updateAwardBtn(arg_8_0)
	local var_8_0 = arg_8_0:nodeByName("award_btn")

	var_8_0:setTouchEnabled(false)
	var_8_0:getChildByName("award_text"):setVisible(false)
	var_8_0:getChildByName("awarded_text"):setVisible(false)

	if tonumber(arg_8_0.times) == 1 then
		if not arg_8_0.mission[1].complete or not arg_8_0.mission[2].complete or not arg_8_0.mission[3].complete then
			var_8_0:setVisible(false)
			var_8_0:setTouchEnabled(false)
			var_8_0:setBright(false)
			var_8_0:getChildByName("award_text"):setVisible(true)
		else
			var_8_0:setVisible(true)
			var_8_0:setTouchEnabled(true)
			var_8_0:setBright(true)
			var_8_0:getChildByName("award_text"):setVisible(true)
		end
	else
		var_8_0:setVisible(true)
		var_8_0:getChildByName("award_text"):setVisible(false)
		var_8_0:getChildByName("awarded_text"):setVisible(true)
	end
end

function var_0_0.setFerrisPos(arg_9_0)
	if arg_9_0.conduct ~= 1 and arg_9_0.firstin then
		arg_9_0.angle = 78.5 - 22.5 * arg_9_0.conduct
	else
		arg_9_0.angle = 56 - 22.5 * arg_9_0.conduct
	end

	for iter_9_0 = 1, 16 do
		local var_9_0 = tostring("ferris_" .. iter_9_0)
		local var_9_1 = tostring("end_bg_" .. iter_9_0)
		local var_9_2 = arg_9_0.angle + iter_9_0 * 22.5
		local var_9_3 = 247 * math.cos(math.rad(var_9_2)) + 5.5
		local var_9_4 = 247 * math.sin(math.rad(var_9_2)) + 118

		arg_9_0:nodeByName(var_9_0):setPosition(cc.p(var_9_3, var_9_4))
		arg_9_0:nodeByName(var_9_1):setPosition(cc.p(var_9_3, var_9_4))

		if iter_9_0 == 16 or iter_9_0 == 15 or iter_9_0 == 9 then
			arg_9_0:nodeByName(var_9_1):setPosition(cc.p(var_9_3 + 2, var_9_4))
		end

		if iter_9_0 == 5 then
			arg_9_0:nodeByName(var_9_1):setPosition(cc.p(var_9_3, var_9_4 - 2))
		end

		if iter_9_0 > arg_9_0.conduct then
			arg_9_0:nodeByName(var_9_1):setOpacity(0)
		end

		if iter_9_0 == arg_9_0.conduct and (not arg_9_0.mission[1].complete or not arg_9_0.mission[2].complete or not arg_9_0.mission[3].complete) then
			arg_9_0:nodeByName(var_9_1):setOpacity(0)
		end
	end
end

function var_0_0.setButtonClick(arg_10_0)
	arg_10_0:nodeByName("up_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_10_0:nodeByName("up_btn"):setVisible(false)
			arg_10_0:nodeByName("down_btn"):setVisible(true)

			arg_10_0.isScaleUp = true

			arg_10_0:updateWheelShow()
		end
	end)
	arg_10_0:nodeByName("down_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_10_0:nodeByName("up_btn"):setVisible(true)
			arg_10_0:nodeByName("down_btn"):setVisible(false)

			arg_10_0.isScaleUp = false

			arg_10_0:updateWheelShow()
		end
	end)
	arg_10_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_13_0 = {
				text = var_0_1:translation("ACTIVITY_RICH_WHEEL_RULE_TEXT"),
				giftId = xyd.tables.misc.activityRichWheelReward
			}

			xyd.WindowManager.get():openWindow("super_rich_rule", var_13_0)
		end
	end)
	arg_10_0:nodeByName("award_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_14_0 = {}

			arg_10_0.superRich:monopolyMissionAward(var_14_0, function(arg_15_0, arg_15_1)
				if arg_15_0 == xyd.error.OK then
					arg_10_0:updateAwarded()
				end
			end)
		end
	end)
	arg_10_0:nodeByName("backpack_btn"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local function var_16_0()
				arg_10_0.selectItem = not arg_10_0.selectItem

				arg_10_0:updateWheelCondition()
			end

			local var_16_1 = {
				callback = var_16_0,
				use_type = {
					0,
					1,
					0
				}
			}
			local var_16_2 = xyd.WindowManager.get():openWindow("super_rich_backpack", var_16_1)

			var_16_2:setPosition(cc.p(1175, 130))
			var_16_2:addBlockLayer(cc.c4b(0, 0, 0, 0))
		end
	end)
	arg_10_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.began then
			xyd.playButtonSound()
		elseif arg_18_1 == ccui.TouchEventType.ended then
			arg_10_0.selectItem = not arg_10_0.selectItem

			arg_10_0:updateWheelCondition()
		end
	end)
end

function var_0_0.updateWheelCondition(arg_19_0)
	arg_19_0:updateNowWheelNum()
	arg_19_0.scrollList:refreshList()
end

function var_0_0.rotateWheel(arg_20_0)
	if arg_20_0.handle then
		var_0_2.unscheduleGlobal(arg_20_0.handle)

		arg_20_0.handle = nil
	end

	local var_20_0 = 22.5
	local var_20_1 = 0.75
	local var_20_2 = 30

	arg_20_0.count = 0
	arg_20_0.handle = var_0_2.scheduleGlobal(function()
		arg_20_0.count = arg_20_0.count + 1

		if arg_20_0.count <= var_20_2 then
			arg_20_0.angle = arg_20_0.angle - var_20_1

			for iter_21_0 = 1, 16 do
				local var_21_0 = tostring("ferris_" .. iter_21_0)
				local var_21_1 = tostring("end_bg_" .. iter_21_0)
				local var_21_2 = arg_20_0.angle + 22.5 * iter_21_0
				local var_21_3 = 247 * math.cos(math.rad(var_21_2)) - 247 * math.cos(math.rad(var_21_2 + var_20_1))
				local var_21_4 = 247 * math.sin(math.rad(var_21_2)) - 247 * math.sin(math.rad(var_21_2 + var_20_1))

				arg_20_0:nodeByName(var_21_0):setPosition(xyd.addPosition(cc.p(arg_20_0:nodeByName(var_21_0):getPosition()), cc.p(var_21_3, var_21_4)))
				arg_20_0:nodeByName(var_21_1):setPosition(xyd.addPosition(cc.p(arg_20_0:nodeByName(var_21_1):getPosition()), cc.p(var_21_3, var_21_4)))
			end

			arg_20_0:nodeByName("ferris_wheel"):setRotation(arg_20_0:nodeByName("ferris_wheel"):getRotation() + var_20_1)
		elseif arg_20_0.handle then
			var_0_2.unscheduleGlobal(arg_20_0.handle)

			arg_20_0.handle = nil
		end
	end, 0.03333333333333333)
end

function var_0_0.updateWheelShow(arg_22_0, ...)
	if arg_22_0.isScaleUp then
		arg_22_0:nodeByName("circle_pos1"):setScale(2.2)
		arg_22_0:nodeByName("circle_pos1"):setPosition(cc.p(70, -230))
	else
		arg_22_0:nodeByName("circle_pos1"):setScale(1)
		arg_22_0:nodeByName("circle_pos1"):setPosition(cc.p(380, 275.4))
	end
end

function var_0_0.updateNowWheelNum(arg_23_0, ...)
	if arg_23_0.selectItem then
		arg_23_0.wheelIndex:setString("")
	else
		arg_23_0.wheelIndex:setString((arg_23_0.conduct - 1) % 16 + 1)
	end
end

function var_0_0.scrollListDelegate(arg_24_0, arg_24_1, arg_24_2, arg_24_3)
	if cc.ui.UIListView.COUNT_TAG == arg_24_2 then
		return #arg_24_0.data
	elseif cc.ui.UIListView.CELL_TAG == arg_24_2 then
		local var_24_0
		local var_24_1 = arg_24_0.scrollList:dequeueItem()

		if not var_24_1 then
			var_24_1 = arg_24_0.scrollList:newItem()
		else
			var_24_1:removeAllChildren(true)
		end

		local var_24_2 = arg_24_0:createListContent(arg_24_3)
		local var_24_3 = var_24_2:getWidth()
		local var_24_4 = var_24_2:getHeight()

		var_24_1:setItemSize(var_24_3, var_24_4)
		var_24_1:addContent(var_24_2)

		return var_24_1
	end
end

function var_0_0.createListContent(arg_25_0, arg_25_1)
	local var_25_0 = arg_25_0.data[arg_25_1]
	local var_25_1 = arg_25_0.mission[arg_25_1]
	local var_25_2 = display.newNode()
	local var_25_3 = false
	local var_25_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/zillionaire/wheel/task_item.csb")
	local var_25_5 = var_25_4:getChildByName("container")

	if var_25_0.progress >= var_25_0.totalTaskNum then
		var_25_0.progress = var_25_0.totalTaskNum
		var_25_3 = true
		var_25_1.complete = true
	end

	var_25_5:getChildByName("cover"):setVisible(false)
	var_25_5:getChildByName("progress_txt"):setString(tostring(var_25_0.progress) .. "/" .. tostring(var_25_0.totalTaskNum))
	var_25_5:getChildByName("desc_txt"):setString(tostring(var_25_0.txt))

	if arg_25_0.selectItem and var_25_3 then
		var_25_5:getChildByName("cover"):setVisible(true)
	end

	if arg_25_0.selectItem then
		arg_25_0:nodeByName("index_text"):setVisible(false)
		arg_25_0:nodeByName("select_task_tip"):setVisible(true)
		arg_25_0:nodeByName("cancel_btn"):setVisible(true)
	else
		arg_25_0:nodeByName("index_text"):setVisible(true)
		arg_25_0:nodeByName("select_task_tip"):setVisible(false)
		arg_25_0:nodeByName("cancel_btn"):setVisible(false)
	end

	if var_25_3 then
		var_25_4:setTouchEnabled(false)
	else
		var_25_4:setTouchEnabled(true)
		var_25_5:getChildByName("select_icon"):setVisible(false)
		var_25_5:getChildByName("select"):setVisible(false)
	end

	var_25_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_26_0)
		if arg_26_0.name == "began" and arg_25_0.selectItem then
			var_25_4:setScale(0.9)

			return true
		elseif arg_26_0.name == "ended" then
			xyd.playButtonSound()
			var_25_4:setScale(1)

			local var_26_0 = {
				grid_type = arg_25_0.stationType,
				pos = arg_25_0.pos,
				idx = arg_25_1
			}

			arg_25_0.superRich:monopolyUseCard(var_26_0, function(arg_27_0, arg_27_1)
				if arg_27_0 == xyd.error.OK then
					var_25_3 = not var_25_3

					var_25_4:setTouchEnabled(false)
					var_25_5:getChildByName("cover"):setVisible(true)
					var_25_5:getChildByName("select_icon"):setVisible(true)
					var_25_5:getChildByName("select"):setVisible(true)

					var_25_0.progress = var_25_0.totalTaskNum
					arg_25_0.selectItem = not arg_25_0.selectItem

					arg_25_0.scrollList:refreshList()
					arg_25_0:updatelight()
					arg_25_0:updateWheelCondition()
				end
			end)
		end
	end)
	arg_25_0:updateAwardBtn()
	var_25_4:addTo(var_25_2)
	var_25_4:setAnchorPoint(cc.p(0, 0))
	var_25_2:setContentSize(var_25_5:getContentSize())
	var_25_4:setName("source")

	return var_25_2
end

function var_0_0.updateButtonCondition(arg_28_0)
	return
end

function var_0_0.scrollListener(arg_29_0, arg_29_1)
	if arg_29_1.name == "began" then
		arg_29_0.scrollViewMoved_ = false
		arg_29_0.prevY_ = arg_29_1.y
	elseif arg_29_1.name == "moved" and 5 <= math.abs(arg_29_1.y - arg_29_0.prevY_) then
		arg_29_0.scrollViewMoved_ = true
	end
end

function var_0_0.updatelight(arg_30_0)
	if arg_30_0.mission[1].complete and arg_30_0.mission[2].complete and arg_30_0.mission[3].complete then
		if arg_30_0.handle then
			var_0_2.unscheduleGlobal(arg_30_0.handle)

			arg_30_0.handle = nil
		end

		local var_30_0 = 30

		arg_30_0.count = 0
		arg_30_0.handle = var_0_2.scheduleGlobal(function()
			arg_30_0.count = arg_30_0.count + 1

			if arg_30_0.count <= var_30_0 then
				if arg_30_0.conduct <= 16 then
					local var_31_0 = tostring("end_bg_" .. arg_30_0.conduct)

					arg_30_0:nodeByName(var_31_0):setOpacity(8.5 * arg_30_0.count)
				end
			elseif arg_30_0.handle then
				var_0_2.unscheduleGlobal(arg_30_0.handle)

				arg_30_0.handle = nil
			end
		end, 0.03333333333333333)
	end
end

return var_0_0
