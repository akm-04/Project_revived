local var_0_0 = class("OccultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.creatsChapterSelect
local var_0_4 = var_0_3:chapterCount()
local var_0_5 = 340
local var_0_6 = 450
local var_0_7 = {
	cc.p(var_0_6 - 2 * var_0_5, 30),
	cc.p(var_0_6 - var_0_5, 55),
	cc.p(var_0_6, 30),
	cc.p(var_0_6 + var_0_5, 55),
	cc.p(var_0_6 + 2 * var_0_5, 30)
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.occult = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.data = {}

	if arg_1_2 and arg_1_2.chapter then
		arg_1_0.centreChapterPos = arg_1_2.chapter
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	local var_2_0 = {
		show_rule = true
	}

	arg_2_0:addTopSidebar(var_2_0)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.ECONOMY_AFTER, function(arg_3_0)
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0:updateLeftTimes()
		end
	end)
	arg_2_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_cooperate"):setString(var_0_2:translation("OCCLUT_TEXT_1"))
	arg_4_0:nodeByName("text_single"):setString(var_0_2:translation("OCCLUT_TEXT_2"))
	arg_4_0:nodeByName("text_sweep"):setString(var_0_2:translation("MAP_SWEEP"))
	arg_4_0:nodeByName("braveheart_num_txt"):setString(var_0_2:translation(""))
	arg_4_0:nodeByName("award_text"):setString(var_0_2:translation("INDIEGOGO_AWARD"))
	arg_4_0:nodeByName("award_text"):enableOutline(cc.c4b(52, 54, 55, 255), 2)
	arg_4_0:nodeByName("braveheart_text"):setString(var_0_2:translation("BRAVEHEART_TEXT"))
	arg_4_0:nodeByName("task_text"):setString(var_0_2:translation("OCCULT_TASK_TEXT"))
	arg_4_0:nodeByName("task_text"):enableOutline(cc.c4b(52, 54, 55, 255), 2)

	arg_4_0.innerContainer = arg_4_0:nodeByName("inner_container")
	arg_4_0.scroll = arg_4_0:nodeByName("award_scroll")

	local var_4_0 = arg_4_0.scroll:getContentSize()

	arg_4_0.awardList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.awardList:setBounceable(true)
	arg_4_0.awardList:setDelegate(handler(arg_4_0, arg_4_0.awardListDelegate))
	arg_4_0.awardList:setTouchType(false)
	arg_4_0:setButtonClick()

	arg_4_0.clippingNode = display.newClippingRegionNode()

	arg_4_0.clippingNode:setClippingRegion(cc.rect(0, 0, arg_4_0.innerContainer:getWidth(), arg_4_0.innerContainer:getHeight()))
	arg_4_0.clippingNode:setAnchorPoint(cc.p(0, 0))
	arg_4_0.clippingNode:addTo(arg_4_0.innerContainer)

	local var_4_1 = {}

	for iter_4_0 = 1, var_0_4 do
		local var_4_2 = var_0_3:tableID(iter_4_0)

		table.insert(var_4_1, var_4_2)
	end

	arg_4_0:initialChapterShow()
	arg_4_0:updateLeftTimes()
	arg_4_0:updateLeftTimesProgress()
	arg_4_0:nodeByName("braveheart_progress_container"):setVisible(false)
end

function var_0_0.updateLeftTimes(arg_5_0)
	local var_5_0 = arg_5_0.selfPlayer.occultTicket

	arg_5_0:nodeByName("braveheart_num_txt"):setString(tostring(var_5_0) .. "/" .. tostring(xyd.tables.misc.creatsTicketMax))
end

function var_0_0.updateLeftTimesProgress(arg_6_0)
	local var_6_0 = xyd.split(var_0_2:translation("OCCULT_TIMES_PROGRESS_TIPS"), "@")

	for iter_6_0 = 1, #var_6_0 do
		arg_6_0:nodeByName("progress_text" .. tostring(iter_6_0)):setString(var_6_0[iter_6_0])
	end

	arg_6_0:nodeByName("progress_text2"):setString(xyd.tables.misc.creatsTicketGet)
	arg_6_0:nodeByName("progress_text6"):setString(string.format(var_6_0[6], tostring(arg_6_0.occult.baseInfo.cost_energy) .. "/" .. tostring(xyd.tables.misc.creatsTicketGet)))
end

function var_0_0.initialChapterShow(arg_7_0)
	arg_7_0.models = {}

	if arg_7_0.centreChapterPos then
		-- block empty
	elseif var_0_4 >= 2 then
		arg_7_0.centreChapterPos = 2
	else
		arg_7_0.centreChapterPos = 1
	end

	for iter_7_0 = 1, var_0_4 do
		local var_7_0 = var_0_3:chapterModel(iter_7_0)
		local var_7_1 = xyd.HeroAnimation.new(nil, var_7_0, xyd.tables.model:uiScale(var_7_0), {})

		var_7_1:setScale(var_7_1:getScale() * 1.4)
		var_7_1:addTo(arg_7_0.clippingNode)
		var_7_1:setPosition(arg_7_0:getModelPostion(iter_7_0, arg_7_0.centreChapterPos))
		var_7_1:idle(true)

		arg_7_0.models[iter_7_0] = var_7_1
	end

	arg_7_0:update()
end

function var_0_0.update(arg_8_0)
	arg_8_0:updateAwardList()
	arg_8_0:updateArrowShow()
	arg_8_0:updateChapterDesc()
	arg_8_0:updateSweepBtnShow()
end

function var_0_0.updateAwardList(arg_9_0)
	arg_9_0.data = {}
	arg_9_0.data = clone(var_0_3:itemDisplay(arg_9_0.centreChapterPos))

	if var_0_3:mana(arg_9_0.centreChapterPos) > 0 then
		table.insert(arg_9_0.data, -2)
	end

	local var_9_0 = arg_9_0.occult:getAwakeAwardsItem(arg_9_0.centreChapterPos)

	for iter_9_0 = 1, #var_9_0 do
		table.insert(arg_9_0.data, 1, var_9_0[iter_9_0])
	end

	arg_9_0.awardList:reload()
end

function var_0_0.updateArrowShow(arg_10_0)
	if arg_10_0.centreChapterPos >= var_0_4 then
		arg_10_0:nodeByName("right_arrow"):setVisible(false)
	else
		arg_10_0:nodeByName("right_arrow"):setVisible(true)
	end

	if arg_10_0.centreChapterPos <= 1 then
		arg_10_0:nodeByName("left_arrow"):setVisible(false)
	else
		arg_10_0:nodeByName("left_arrow"):setVisible(true)
	end
end

function var_0_0.updateChapterDesc(arg_11_0)
	arg_11_0:nodeByName("top_score_text"):setString(var_0_2:translation("OCCULT_TOP_SCORE"))
	arg_11_0:nodeByName("top_score_txt"):setString(arg_11_0.occult:getChapterTopScore(arg_11_0.centreChapterPos))
	arg_11_0:nodeByName("task_desc_txt"):setString(var_0_3:chapterDes(arg_11_0.centreChapterPos))
	arg_11_0:nodeByName("task_desc_txt"):enableOutline(cc.c4b(52, 54, 55, 255), 2)
end

function var_0_0.updateSweepBtnShow(arg_12_0)
	if arg_12_0.occult:getChapterTopScore(arg_12_0.centreChapterPos) > 0 then
		arg_12_0:nodeByName("sweep_btn"):setVisible(true)
	else
		arg_12_0:nodeByName("sweep_btn"):setVisible(false)
	end
end

function var_0_0.getModelPostion(arg_13_0, arg_13_1, arg_13_2)
	if arg_13_1 < arg_13_2 - 1 then
		return var_0_7[1]
	elseif arg_13_1 == arg_13_2 - 1 then
		return var_0_7[2]
	elseif arg_13_1 == arg_13_2 then
		return var_0_7[3]
	elseif arg_13_1 == arg_13_2 + 1 then
		return var_0_7[4]
	elseif arg_13_1 > arg_13_2 + 1 then
		return var_0_7[5]
	end
end

function var_0_0.setButtonClick(arg_14_0)
	arg_14_0:nodeByName("top_sidebar")
	arg_14_0:nodeByName("top_sidebar"):nodeByName("rule")
	xyd.nodeEventSample(arg_14_0:nodeByName("top_sidebar"):nodeByName("rule"), nil, function(arg_15_0)
		local var_15_0 = {}

		var_15_0.title_name = "OCCLUT_RULE_TITLE"
		var_15_0.rule = "OCCLUT_RULE_TEXT"
		var_15_0.style = xyd.RuleStyle.BLUE

		xyd.WindowManager.get():openWindow("new_text_rule", var_15_0)
	end)
	arg_14_0:nodeByName("right_arrow"):setTouchEnabled(true)
	arg_14_0:nodeByName("right_arrow"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			arg_14_0:nodeByName("right_arrow"):setScale(0.9)

			return true
		elseif arg_16_0.name == "ended" then
			xyd.playButtonSound()
			arg_14_0:nodeByName("right_arrow"):setScale(1)
			arg_14_0:shiftCentreChapterPos(1)
		end
	end)
	arg_14_0:nodeByName("left_arrow"):setTouchEnabled(true)
	arg_14_0:nodeByName("left_arrow"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
		if arg_17_0.name == "began" then
			arg_14_0:nodeByName("left_arrow"):setScale(0.9)

			return true
		elseif arg_17_0.name == "ended" then
			xyd.playButtonSound()
			arg_14_0:nodeByName("left_arrow"):setScale(1)
			arg_14_0:shiftCentreChapterPos(-1)
		end
	end)
	arg_14_0:nodeByName("cooperate_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
		xyd.buttonScaleAnim(arg_18_0, arg_18_1)

		if arg_18_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_14_0.selfPlayer.occultTicket <= 0 then
				local var_18_0 = var_0_2:translation("NO_BRAVEHEART_TIP_TEXT")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_18_0
				})

				return
			end

			local var_18_1 = {
				chapter_id = arg_14_0.centreChapterPos
			}

			xyd.WindowManager.get():openWindow("occult_select_model", var_18_1)
		end
	end)
	arg_14_0:nodeByName("single_btn"):addTouchEventListener(function(arg_19_0, arg_19_1)
		xyd.buttonScaleAnim(arg_19_0, arg_19_1)

		if arg_19_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_14_0.selfPlayer.occultTicket <= 0 then
				local var_19_0 = var_0_2:translation("NO_BRAVEHEART_TIP_TEXT")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_19_0
				})

				return
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("OCCULT_SINLGE_BRAVEHEART_TIP"), function()
				local var_20_0 = {
					chapter_id = arg_14_0.centreChapterPos,
					campaign_type = xyd.OccultRoomType.SINGLE_PLAYER
				}

				arg_14_0.occult:createRoom(var_20_0, function(arg_21_0, arg_21_1)
					if arg_21_0 == xyd.error.OK then
						-- block empty
					end
				end)
			end, nil, nil, arg_14_0.colorMode)
		end
	end)
	arg_14_0:nodeByName("sweep_btn"):addTouchEventListener(function(arg_22_0, arg_22_1)
		xyd.buttonScaleAnim(arg_22_0, arg_22_1)

		if arg_22_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_14_0.selfPlayer.occultTicket <= 0 then
				local var_22_0 = var_0_2:translation("NO_BRAVEHEART_TIP_TEXT")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_22_0
				})

				return
			end

			local var_22_1 = xyd.tables.translation:translation("SWEEP_AWARD_TIP_TEXT")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_22_1, tostring(xyd.tables.misc.creatsSweepRewardRate * 100) .. "%"), function()
				local var_23_0 = {
					chapter_id = arg_14_0.centreChapterPos
				}

				arg_14_0.occult:sweep(var_23_0, function(arg_24_0, arg_24_1)
					if arg_24_0 == xyd.error.OK then
						local var_24_0 = {
							awards = arg_24_1.awards,
							top_score = arg_14_0.occult:getChapterTopScore(arg_14_0.centreChapterPos)
						}

						xyd.WindowManager.get():openWindow("occult_sweep_window", var_24_0)
					end
				end)
			end, nil, nil, arg_14_0.colorMode)
		end
	end)

	local var_14_0 = display.newNode()

	var_14_0:setContentSize(arg_14_0:nodeByName("braveheart"):getContentSize())
	var_14_0:setAnchorPoint(cc.p(0, 0))
	var_14_0:setTouchEnabled(true)
	var_14_0:addTo(arg_14_0:nodeByName("braveheart"))
	var_14_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_25_0)
		if arg_25_0.name == "began" then
			arg_14_0.beganEvent = arg_25_0

			arg_14_0:nodeByName("braveheart_progress_container"):setVisible(true)

			return true
		elseif arg_25_0.name == "moved" then
			if xyd.getDistance(arg_14_0.beganEvent, arg_25_0) > 30 then
				arg_14_0:nodeByName("braveheart_progress_container"):setVisible(false)
			end
		elseif arg_25_0.name == "ended" then
			arg_14_0:nodeByName("braveheart_progress_container"):setVisible(false)
		end
	end)
end

function var_0_0.shiftCentreChapterPos(arg_26_0, arg_26_1)
	arg_26_0:nodeByName("right_arrow"):setTouchEnabled(false)
	arg_26_0:nodeByName("left_arrow"):setTouchEnabled(false)
	var_0_1.performWithDelayGlobal(function()
		if arg_26_0 and not tolua.isnull(arg_26_0) and not tolua.isnull(arg_26_0:nodeByName("right_arrow")) then
			arg_26_0:nodeByName("right_arrow"):setTouchEnabled(true)
			arg_26_0:nodeByName("left_arrow"):setTouchEnabled(true)
		end
	end, 1)

	local var_26_0 = arg_26_0.centreChapterPos

	arg_26_0.centreChapterPos = arg_26_0.centreChapterPos + arg_26_1

	arg_26_0:update()

	for iter_26_0, iter_26_1 in pairs(arg_26_0.models) do
		local var_26_1 = arg_26_0:getModelPostion(iter_26_0, var_26_0)
		local var_26_2 = arg_26_0:getModelPostion(iter_26_0, arg_26_0.centreChapterPos)

		if var_26_1.x ~= var_26_2.x then
			iter_26_1:runAction(cc.MoveTo:create(1, var_26_2))
		end
	end
end

function var_0_0.awardListDelegate(arg_28_0, arg_28_1, arg_28_2, arg_28_3)
	if cc.ui.UIListView.COUNT_TAG == arg_28_2 then
		return #arg_28_0.data
	elseif cc.ui.UIListView.CELL_TAG == arg_28_2 then
		local var_28_0
		local var_28_1 = arg_28_0.awardList:dequeueItem()

		if not var_28_1 then
			var_28_1 = arg_28_0.awardList:newItem()
		else
			var_28_1:removeAllChildren(true)
		end

		local var_28_2 = arg_28_0:createListContent(arg_28_0.data[arg_28_3])
		local var_28_3 = var_28_2:getWidth() + 10
		local var_28_4 = var_28_2:getHeight()

		var_28_1:setItemSize(var_28_3, var_28_4)
		var_28_1:addContent(var_28_2)

		return var_28_1
	end
end

function var_0_0.createListContent(arg_29_0, arg_29_1)
	local var_29_0 = display.newNode()

	var_29_0:setContentSize(70, 70)
	xyd.setItemAndAddTips(var_29_0, arg_29_1)

	return var_29_0
end

function var_0_0.scrollListener(arg_30_0, arg_30_1)
	if arg_30_1.name == "began" then
		arg_30_0.scrollViewMoved_ = false
		arg_30_0.prevY_ = arg_30_1.y
	elseif arg_30_1.name == "moved" and 5 <= math.abs(arg_30_1.y - arg_30_0.prevY_) then
		arg_30_0.scrollViewMoved_ = true
	end
end

return var_0_0
