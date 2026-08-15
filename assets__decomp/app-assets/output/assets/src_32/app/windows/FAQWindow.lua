local var_0_0 = class("FAQWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.EcoSidebar")
local var_0_2 = import("app.common.ui.SpriteNodeButton")
local var_0_3 = xyd.tables.faqPedia
local var_0_4 = xyd.tables.faqGuideCell
local var_0_5 = xyd.tables.faqGuideItem
local var_0_6 = xyd.tables.translation
local var_0_7 = import("app.common.ui.CommonButton")
local var_0_8 = import("app.common.ui.SidebarTabButton")
local var_0_9 = xyd.tables.misc
local var_0_10 = 8

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.ecoBarType = xyd.EcoSidebarType.MAIN
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
	arg_1_0.updateFunction = {}
	arg_1_0.updateFunction[1] = arg_1_0.updateGuideCell
	arg_1_0.updateFunction[2] = arg_1_0.updatePediaCell
	arg_1_0.updateFunction[3] = arg_1_0.updateInfoContent
	arg_1_0.updateFunction[4] = arg_1_0.updateGuideItem
	arg_1_0.updateFunction[5] = arg_1_0.updatePediaItem
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()

	if arg_2_0.changeBG and not tolua.isnull(arg_2_0.changeBG) then
		arg_2_0.changeBG:setPositionX(200)
	end

	arg_2_0:dataPrepare()
	arg_2_0:init()
	arg_2_0:updateAll()
end

function var_0_0.dataPrepare(arg_3_0)
	arg_3_0.npcContents = xyd.split(var_0_6:translation("FAQ_SENTENCE"), "#")

	local var_3_0 = clone(var_0_3:getAllLev())

	arg_3_0.pediaCellIndex = {
		1
	}

	for iter_3_0 = 2, #var_3_0 do
		if var_3_0[iter_3_0] ~= var_3_0[iter_3_0 - 1] then
			table.insert(arg_3_0.pediaCellIndex, iter_3_0)
		end
	end

	arg_3_0.pediaMaxPage = math.ceil(#arg_3_0.pediaCellIndex / 4)

	table.insert(arg_3_0.pediaCellIndex, #var_3_0 + 1)

	local var_3_1 = var_0_4:getAllNum()

	arg_3_0.guideCellIndex = {
		1
	}

	for iter_3_1 = 1, #var_3_1 do
		arg_3_0.guideCellIndex[iter_3_1 + 1] = arg_3_0.guideCellIndex[iter_3_1] + var_3_1[iter_3_1]
	end

	arg_3_0.guideMaxPage = math.ceil((#arg_3_0.guideCellIndex - 1) / 4)
	arg_3_0.right = arg_3_0:nodeByName("right")

	local var_3_2 = arg_3_0:nodeByName("next"):getHeight()
	local var_3_3 = arg_3_0.right:getWidth()
	local var_3_4 = arg_3_0.right:getHeight()

	arg_3_0.cellPos = {
		{
			width = var_3_3 * 0.25,
			height = var_3_2 + (var_3_4 - var_3_2) * 0.75 - 5
		},
		{
			width = var_3_3 * 0.25,
			height = var_3_2 + (var_3_4 - var_3_2) * 0.25 - 5
		},
		{
			width = var_3_3 * 0.75,
			height = var_3_2 + (var_3_4 - var_3_2) * 0.75 - 5
		},
		{
			width = var_3_3 * 0.75,
			height = var_3_2 + (var_3_4 - var_3_2) * 0.25 - 5
		}
	}
end

function var_0_0.init(arg_4_0)
	arg_4_0.left1 = arg_4_0:nodeByName("left1")
	arg_4_0.left2 = arg_4_0:nodeByName("left2")
	arg_4_0.left3 = arg_4_0:nodeByName("left3")
	arg_4_0.npc = arg_4_0:nodeByName("npc")
	arg_4_0.state = 1
	arg_4_0.cellPage = 1

	arg_4_0:npcSpeak()
	arg_4_0.npc:setTouchEnabled(true)
	arg_4_0.npc:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "ended" then
			arg_4_0:npcSpeak()
		end

		return true
	end)

	arg_4_0.isScaleUp = false

	for iter_4_0 = 1, 3 do
		local var_4_0 = arg_4_0.left1:getChildByName("tag" .. iter_4_0):getChildByName("btn")

		arg_4_0.left1:getChildByName("tag" .. iter_4_0):getChildByName("txt"):setString(var_0_6:translation("FAQ_TIP" .. iter_4_0))
		var_4_0:addTouchEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.TouchEventType.ended then
				if iter_4_0 == arg_4_0.state then
					var_4_0:setBrightStyle(ccui.BrightStyle.highlight)
				else
					arg_4_0.state = iter_4_0
					arg_4_0.cellPage = 1

					arg_4_0:updateAll()
				end
			end
		end)
	end

	arg_4_0.left1:getChildByName("tag1"):getChildByName("txt"):setString(var_0_6:translation("FAQ_TIP1"))
	arg_4_0.left1:getChildByName("tag2"):getChildByName("txt"):setString(var_0_6:translation("FAQ_TIP2"))
	arg_4_0.left1:getChildByName("tag3"):getChildByName("txt"):setString(var_0_6:translation("FAQ_TIP3"))
	arg_4_0.left3:getChildByName("tag"):getChildByName("btn"):setBrightStyle(ccui.BrightStyle.highlight)
	arg_4_0.left3:getChildByName("tag"):getChildByName("btn"):setTouchEnabled(false)

	local var_4_1 = var_0_2.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(arg_4_0.colorMode)
	})

	var_4_1:addTo(arg_4_0.left2:getChildByName("return"):getChildByName("btn"))
	var_4_1:setAnchorPoint(0.5, 0.5)
	var_4_1:setPosition(cc.p(46, 26))
	var_4_1:setName("return_btn2")

	arg_4_0.returnBtn2 = var_4_1

	arg_4_0.left2:getChildByName("return"):getChildByName("txt"):setString(var_0_6:translation("FAQ_TIP1"))
	arg_4_0.returnBtn2:setTouchSwallowEnabled(true)
	arg_4_0.returnBtn2:addTouchEvent(function(arg_7_0)
		if arg_7_0.name == "ended" then
			arg_4_0.state = arg_4_0.state - 3

			arg_4_0:updateAll()
		end
	end)
	arg_4_0.left3:getChildByName("tag"):getChildByName("btn"):setBrightStyle(ccui.BrightStyle.highlight)
	arg_4_0.left3:getChildByName("tag"):getChildByName("btn"):setTouchEnabled(false)
	arg_4_0.left3:getChildByName("return"):getChildByName("txt"):setString(var_0_6:translation("FAQ_TIP2"))

	local var_4_2 = var_0_2.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(arg_4_0.colorMode)
	})

	var_4_2:addTo(arg_4_0.left3:getChildByName("return"):getChildByName("btn"))
	var_4_2:setAnchorPoint(0.5, 0.5)
	var_4_2:setPosition(cc.p(46, 26))
	var_4_2:setName("return_btn3")

	arg_4_0.returnBtn3 = var_4_2

	arg_4_0.returnBtn3:setTouchSwallowEnabled(true)
	arg_4_0.returnBtn3:addTouchEvent(function(arg_8_0)
		if arg_8_0.name == "ended" then
			arg_4_0.state = arg_4_0.state - 3

			arg_4_0:updateAll()
		end
	end)

	local var_4_3 = arg_4_0:nodeByName("scroll")
	local var_4_4 = var_4_3:getContentSize()

	arg_4_0.pediaTagList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_4.width, var_4_4.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(var_4_3):onScroll(handler(arg_4_0, arg_4_0.scrollListener)):pos(0, 0)

	arg_4_0.pediaTagList:setBounceable(true)
	arg_4_0.pediaTagList:setTopBounceable(false)
	arg_4_0.pediaTagList:setDelegate(handler(arg_4_0, arg_4_0.pediaTagDelegate))

	arg_4_0.rightScroll = arg_4_0:nodeByName("right_scroll")

	local var_4_5 = arg_4_0.rightScroll:getContentSize()

	arg_4_0.rightList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_5.width, var_4_5.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.rightScroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0)

	arg_4_0.rightList:setBounceable(true)
	arg_4_0.rightList:setDelegate(handler(arg_4_0, arg_4_0.rightDelegate))
	arg_4_0.rightScroll:setVisible(false)
	arg_4_0:nodeByName("front"):setTouchEnabled(true)
	arg_4_0:nodeByName("front"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			arg_4_0:nodeByName("front"):setScale(0.9)

			return true
		elseif arg_9_0.name == "cancled" then
			arg_4_0:nodeByName("front"):setScale(1)
		elseif arg_9_0.name == "ended" then
			arg_4_0:nodeByName("front"):setScale(1)

			if arg_4_0.state <= 2 then
				arg_4_0.cellPage = arg_4_0.cellPage - 1
			else
				arg_4_0.itemPage = arg_4_0.itemPage - 1
			end

			arg_4_0:updatePageBtn()
			arg_4_0.updateFunction[arg_4_0.state](arg_4_0)
		end
	end)
	arg_4_0:nodeByName("next"):setTouchEnabled(true)
	arg_4_0:nodeByName("next"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			arg_4_0:nodeByName("next"):setScale(0.9)

			return true
		elseif arg_10_0.name == "cancled" then
			arg_4_0:nodeByName("next"):setScale(1)
		elseif arg_10_0.name == "ended" then
			arg_4_0:nodeByName("next"):setScale(1)

			if arg_4_0.state <= 2 then
				arg_4_0.cellPage = arg_4_0.cellPage + 1
			else
				arg_4_0.itemPage = arg_4_0.itemPage + 1
			end

			arg_4_0:updatePageBtn()
			arg_4_0.updateFunction[arg_4_0.state](arg_4_0)
		end
	end)

	arg_4_0.tabBtn = var_0_8.new({
		title = var_0_6:translation("FAQ_TIP4")
	})

	arg_4_0.tabBtn:addTo(arg_4_0:background())
	arg_4_0.tabBtn:setPosition(0.5, 40)
	arg_4_0:updateTabBtnShow()
	arg_4_0.tabBtn:setOnCall(function()
		xyd.db.settings:setShowFAQ(1)

		local var_11_0 = xyd.WindowManager.get():getWindow("main_scene_bottom")

		if var_11_0 and not tolua.isnull(var_11_0) then
			var_11_0:updateFaqBtnShow()
		end
	end)
	arg_4_0.tabBtn:setOffCall(function()
		xyd.db.settings:setShowFAQ(0)

		local var_12_0 = xyd.WindowManager.get():getWindow("main_scene_bottom")

		if var_12_0 and not tolua.isnull(var_12_0) then
			var_12_0:updateFaqBtnShow()
		end
	end)
end

function var_0_0.updateTabBtnShow(arg_13_0)
	if xyd.db.settings:getShowFAQ() == 0 then
		arg_13_0.tabBtn:switch(xyd.TabButtonType.OFF)
	elseif xyd.db.settings:getShowFAQ() == 1 then
		arg_13_0.tabBtn:switch(xyd.TabButtonType.ON)
	end
end

function var_0_0.npcSpeak(arg_14_0)
	local var_14_0

	if arg_14_0.npcSpeakIndex then
		var_14_0 = xyd.randomIndex(arg_14_0.npcSpeakIndex, #arg_14_0.npcContents)
	else
		var_14_0 = math.random(#arg_14_0.npcContents)
	end

	arg_14_0.npcSpeakIndex = var_14_0

	arg_14_0:nodeByName("npc_talk"):setString(arg_14_0.npcContents[var_14_0])
end

function var_0_0.scrollListener(arg_15_0, arg_15_1)
	if arg_15_1.name == "began" then
		arg_15_0.scrollViewMoved_ = false
		arg_15_0.prevY_ = arg_15_1.y
	elseif arg_15_1.name == "moved" and 20 <= math.abs(arg_15_1.y - arg_15_0.prevY_) then
		arg_15_0.scrollViewMoved_ = true
	end
end

function var_0_0.rightDelegate(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	local var_16_0

	if arg_16_0.state == 1 then
		var_16_0 = math.ceil((#arg_16_0.guideCellIndex - 1) / 3)
	elseif arg_16_0.state == 2 then
		var_16_0 = #arg_16_0.pediaCellIndex - 1
	elseif arg_16_0.state == 4 then
		var_16_0 = arg_16_0.guideCellIndex[arg_16_0.cellIndex + 1] - arg_16_0.guideCellIndex[arg_16_0.cellIndex]
	else
		var_16_0 = 0
	end

	if cc.ui.UIListView.COUNT_TAG == arg_16_2 then
		return var_16_0
	elseif cc.ui.UIListView.CELL_TAG == arg_16_2 then
		if var_16_0 < arg_16_3 then
			return nil
		end

		if arg_16_0.state == 1 then
			return arg_16_0:addGuideCell(arg_16_3)
		elseif arg_16_0.state == 2 then
			return arg_16_0:addPediaCell(arg_16_3)
		elseif arg_16_0.state == 4 then
			arg_16_0.left2:getChildByName("tag"):getChildByName("btn"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_16_0.left2:getChildByName("tag"):getChildByName("btn"):setTouchEnabled(false)

			return arg_16_0:addGuideItem(arg_16_3)
		end
	end
end

function var_0_0.pediaTagDelegate(arg_17_0, arg_17_1, arg_17_2, arg_17_3)
	if cc.ui.UIListView.COUNT_TAG == arg_17_2 then
		return arg_17_0.pediaCellIndex[arg_17_0.cellIndex + 1] - arg_17_0.pediaCellIndex[arg_17_0.cellIndex]
	elseif cc.ui.UIListView.CELL_TAG == arg_17_2 then
		local var_17_0 = arg_17_0.pediaCellIndex[arg_17_0.cellIndex] + arg_17_3 - 1
		local var_17_1 = arg_17_0.pediaTagList:dequeueItem()

		if not var_17_1 then
			var_17_1 = arg_17_0.pediaTagList:newItem()
		else
			var_17_1:removeAllChildren(true)
		end

		local var_17_2 = display.newNode()
		local var_17_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/faq/tag_cell.csb")
		local var_17_4 = var_17_3:getChildByName("container")
		local var_17_5 = var_17_4:getContentSize()

		var_17_4:setContentSize(var_17_5)

		local var_17_6 = var_17_4:getChildByName("btn")

		var_17_4:getChildByName("txt"):setString(var_0_3:getName(var_17_0))

		if var_17_0 == arg_17_0.itemId then
			var_17_6:setBrightStyle(ccui.BrightStyle.highlight)

			arg_17_0.brightBtn = var_17_6
			arg_17_0.clickOn = var_17_4:getChildByName("left_click_on")
			arg_17_0.clickNot = var_17_4:getChildByName("left_click_not")

			arg_17_0.clickOn:setVisible(true)
			arg_17_0.clickNot:setVisible(false)
		end

		var_17_6:addTouchEventListener(function(arg_18_0, arg_18_1)
			if arg_18_1 == ccui.TouchEventType.ended and not arg_17_0.scrollViewMoved_ then
				if var_17_0 ~= arg_17_0.itemId then
					if arg_17_0.brightBtn and not tolua.isnull(arg_17_0.brightBtn) then
						arg_17_0.brightBtn:setBrightStyle(ccui.BrightStyle.normal)
						arg_17_0.clickOn:setVisible(false)
						arg_17_0.clickNot:setVisible(true)
					end

					arg_17_0.itemId = var_17_0
					arg_17_0.itemMaxPage = math.ceil(#var_0_3:getTypes(arg_17_0.itemId) / 2)
					arg_17_0.itemPage = 1
					arg_17_0.brightBtn = var_17_6

					var_17_6:setBrightStyle(ccui.BrightStyle.highlight)

					arg_17_0.clickOn = var_17_4:getChildByName("left_click_on")
					arg_17_0.clickNot = var_17_4:getChildByName("left_click_not")

					arg_17_0.clickOn:setVisible(true)
					arg_17_0.clickNot:setVisible(false)
					arg_17_0.updateFunction[arg_17_0.state](arg_17_0)
					arg_17_0:updatePageBtn()
				else
					var_17_6:setBrightStyle(ccui.BrightStyle.highlight)
				end
			elseif var_17_0 == arg_17_0.itemId then
				var_17_6:setBrightStyle(ccui.BrightStyle.highlight)
			end
		end)

		local var_17_7 = var_17_5.height + 9

		if arg_17_3 == 1 then
			var_17_4:getChildByName("title_split"):setScaleY(0.6)

			var_17_7 = var_17_7 + 4
		end

		var_17_3:setTouchSwallowEnabled(false)
		var_17_3:setPosition(cc.p(0, 0))
		var_17_3:setContentSize(var_17_5.width, var_17_7)
		var_17_2:addChild(var_17_3)
		var_17_2:setContentSize(var_17_5.width, var_17_7)
		var_17_1:addContent(var_17_2)
		var_17_1:setItemSize(var_17_5.width, var_17_7)
		var_17_1:setLocalZOrder(-100 - arg_17_3)

		return var_17_1
	end
end

function var_0_0.updateAll(arg_19_0)
	arg_19_0:updateLeft()
	arg_19_0.updateFunction[arg_19_0.state](arg_19_0)
	arg_19_0:updatePageBtn()
end

function var_0_0.updateLeft(arg_20_0)
	arg_20_0.left1:setVisible(arg_20_0.state <= 3)
	arg_20_0.left2:setVisible(arg_20_0.state == 4)
	arg_20_0.left3:setVisible(arg_20_0.state == 5)

	for iter_20_0 = 1, 3 do
		local var_20_0 = arg_20_0.left1:getChildByName("tag" .. iter_20_0):getChildByName("btn")

		if arg_20_0.state == iter_20_0 then
			var_20_0:setBrightStyle(ccui.BrightStyle.highlight)
		else
			var_20_0:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	if arg_20_0.state == 4 then
		arg_20_0.left2:getChildByName("tag"):getChildByName("txt"):setString(var_0_4:getName(arg_20_0.cellIndex))
	end

	if arg_20_0.state == 5 then
		arg_20_0.left3:getChildByName("tag"):getChildByName("txt"):setString(arg_20_0:getPediaCellName(arg_20_0.cellIndex))
		arg_20_0.pediaTagList:reload()
	end
end

function var_0_0.updateGuideCell(arg_21_0)
	arg_21_0.right:removeAllChildren()
	arg_21_0.rightScroll:setVisible(true)
	arg_21_0.rightList:reload()
end

function var_0_0.addGuideItem(arg_22_0, arg_22_1)
	local var_22_0 = arg_22_0.guideCellIndex[arg_22_0.cellIndex] + arg_22_1 - 1
	local var_22_1 = arg_22_0.rightList:dequeueItem()

	if not var_22_1 then
		var_22_1 = arg_22_0.rightList:newItem()
	else
		var_22_1:removeAllChildren(true)
	end

	local var_22_2 = 985
	local var_22_3 = 135

	var_22_1:setItemSize(var_22_2, var_22_3)

	local var_22_4 = display.newNode()

	var_22_4:setContentSize(var_22_2, var_22_3)

	local var_22_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/faq/guide_item.csb")
	local var_22_6 = var_22_5:getChildByName("container")
	local var_22_7 = var_22_6:getContentSize()

	var_22_5:setAnchorPoint(0, 0)
	var_22_4:addChild(var_22_5)
	var_22_5:setPosition(0, 0)
	var_22_6:getChildByName("title"):setString(var_0_5:getName(var_22_0))
	var_22_6:getChildByName("desc"):setString(var_0_5:getContent(var_22_0))

	local var_22_8 = var_22_6:getChildByName("btn")
	local var_22_9 = var_0_5:getWindowName(var_22_0)
	local var_22_10 = var_0_5:getFunctionId(var_22_0)

	var_22_8:setVisible(var_22_10 >= 0 and var_22_9 ~= "")
	var_22_8:addTouchEventListener(function(arg_23_0, arg_23_1)
		xyd.buttonScaleAnim(var_22_8, arg_23_1)

		if arg_23_1 == ccui.TouchEventType.ended and not arg_22_0.scrollViewMoved_ then
			if var_22_10 == 8 and arg_22_0.selfPlayer:isFuncOpen(var_22_10) then
				local var_23_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH)

				if var_23_0.mapInfo == nil then
					var_23_0:loadMarchInfo({}, function(arg_24_0)
						if arg_24_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("march")
						end
					end)
				else
					xyd.WindowManager.get():openWindow("march")
				end
			elseif var_22_10 == 27 then
				arg_22_0.task:loadTaskByType(nil, function(arg_25_0)
					if arg_25_0 == xyd.error.OK then
						arg_22_0.selfPlayer:loadWorldMap(function()
							xyd.WindowManager.get():openWindow("task")
						end)
					end
				end)
			elseif var_22_10 == 99 and arg_22_0.selfPlayer:isFuncOpen(var_22_10) then
				xyd.Backend.get():request(xyd.mid.HUNQI_GET_CAMPAIGN_INFO, {}, function(arg_27_0, arg_27_1)
					if arg_27_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("hunqi_campaign", arg_27_1)
					end
				end)
			elseif var_22_10 == 0 or arg_22_0.selfPlayer:isFuncOpen(var_22_10) then
				xyd.WindowManager.get():openWindow(var_22_9)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_6:translation("FUNCTION_OPEN_TIP_OTHER")
				})
			end
		end
	end)
	var_22_1:addContent(var_22_4)

	return var_22_1
end

function var_0_0.addGuideCell(arg_28_0, arg_28_1)
	local var_28_0 = arg_28_0.rightList:dequeueItem()

	if not var_28_0 then
		var_28_0 = arg_28_0.rightList:newItem()
	else
		var_28_0:removeAllChildren(true)
	end

	local var_28_1 = 980
	local var_28_2 = 290

	var_28_0:setItemSize(var_28_1, var_28_2)

	local var_28_3 = display.newNode()

	var_28_3:setContentSize(var_28_1, var_28_2)

	for iter_28_0 = 1, 3 do
		local var_28_4 = arg_28_1 * 3 - 3 + iter_28_0

		if var_28_4 >= #arg_28_0.guideCellIndex then
			break
		end

		local var_28_5 = var_0_4:getOrder(var_28_4)
		local var_28_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/faq/guide_cell.csb")
		local var_28_7 = var_28_6:getChildByName("container")
		local var_28_8 = var_28_7:getContentSize()

		var_28_6:setPosition((var_28_8.width + 26) * (iter_28_0 - 1), 0)
		var_28_3:addChild(var_28_6)

		if iter_28_0 == 1 then
			var_28_7:getChildByName("txt_desc"):enableOutline(cc.c4b(0, 139, 191, 255), 2)
		elseif iter_28_0 == 2 then
			var_28_7:getChildByName("txt_desc"):enableOutline(cc.c4b(147, 105, 255, 255), 2)
		elseif iter_28_0 == 3 then
			var_28_7:getChildByName("txt_desc"):enableOutline(cc.c4b(213, 121, 59, 255), 2)
		end

		if var_28_4 == 8 then
			local var_28_9, var_28_10 = var_28_7:getChildByName("txt_want"):getPosition()
			local var_28_11, var_28_12 = var_28_7:getChildByName("txt_goal"):getPosition()

			var_28_7:getChildByName("txt_want"):setPosition(cc.p(var_28_9 - 30, var_28_10))
			var_28_7:getChildByName("txt_goal"):setPosition(cc.p(var_28_11 - 30, var_28_12))
		end

		var_28_7:getChildByName("txt_want"):enableOutline(cc.c4b(194, 117, 82, 255), 2)
		var_28_7:getChildByName("txt_want"):setString(var_0_6:translation("GUIDE_GUIDE_TWO"))
		var_28_7:getChildByName("txt_goal"):enableOutline(cc.c4b(194, 117, 82, 255), 2)
		var_28_7:getChildByName("txt_goal"):setString(var_0_4:getName(var_28_5))

		local var_28_13 = string.gsub(var_0_4:getContent(var_28_5), "|", "\n")

		var_28_7:getChildByName("txt_desc"):setString(var_28_13)

		local var_28_14 = xyd.AssetLoader.get():loadSprite(var_0_4:getIcon(var_28_5))
		local var_28_15 = {
			normal_img = var_0_4:getIcon(var_28_5),
			pressed_img = var_0_4:getIcon(var_28_5),
			disabled_img = var_0_4:getIcon(var_28_5)
		}
		local var_28_16 = var_0_7.new(var_28_15)

		var_28_16:setAnchorPoint(cc.p(0.5, 0.5))
		var_28_16:setScale(1, 1)
		var_28_16:addTo(var_28_7:getChildByName("img_pos"))
		var_28_16:setName("buttonGo")
		var_28_16:addTouchEvent(function(arg_29_0)
			if arg_29_0.name == "began" then
				var_28_7:setScale(0.9)

				return true
			elseif arg_29_0.name == "moved" then
				var_28_7:setScale(1)

				return true
			elseif arg_29_0.name == "ended" then
				var_28_7:setScale(1)

				if not arg_28_0.scrollViewMoved_ then
					arg_28_0.state = arg_28_0.state + 3
					arg_28_0.cellIndex = var_28_5

					arg_28_0.rightScroll:setVisible(false)
					arg_28_0:updateAll()
				end
			end

			if callback then
				callback(var_28_5, arg_29_0)
			end
		end)
	end

	var_28_0:addContent(var_28_3)

	return var_28_0
end

function var_0_0.addPediaCell(arg_30_0, arg_30_1)
	local var_30_0 = arg_30_0.rightList:dequeueItem()

	if not var_30_0 then
		var_30_0 = arg_30_0.rightList:newItem()
	else
		var_30_0:removeAllChildren(true)
	end

	local var_30_1 = 985
	local var_30_2 = 135

	var_30_0:setItemSize(var_30_1, var_30_2)

	local var_30_3 = display.newNode()

	var_30_3:setContentSize(var_30_1, var_30_2)

	local var_30_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/faq/pedia_cell.csb")
	local var_30_5 = var_30_4:getChildByName("container")
	local var_30_6 = var_30_5:getContentSize()

	var_30_4:setAnchorPoint(0, 0)
	var_30_3:addChild(var_30_4)
	var_30_4:setPosition(0, 0)
	var_30_5:getChildByName("btn"):getChildByName("btn_txt"):setString(var_0_6:translation("SUMMON_BUTTON_CHAKAN"))
	var_30_5:getChildByName("lev_txt"):setString(arg_30_0:getPediaCellName(arg_30_1))
	var_30_5:getChildByName("lev_txt"):setTouchSwallowEnabled(false)

	local var_30_7 = ""

	for iter_30_0 = arg_30_0.pediaCellIndex[arg_30_1], arg_30_0.pediaCellIndex[arg_30_1 + 1] - 1 do
		var_30_7 = var_30_7 .. var_0_3:getName(iter_30_0) .. ","
	end

	local var_30_8 = string.sub(var_30_7, 1, #var_30_7 - 1)

	if #var_30_8 > 45 and string.find(var_30_8, ",", 35) then
		local var_30_9 = string.find(var_30_8, ",", 35)

		var_30_8 = string.sub(var_30_8, 1, var_30_9) .. "etc."
	end

	var_30_5:getChildByName("info_txt"):setString(var_30_8)
	var_30_5:getChildByName("btn"):addTouchEventListener(function(arg_31_0, arg_31_1)
		xyd.buttonScaleAnim(var_30_5:getChildByName("btn"), arg_31_1)

		if arg_31_1 == ccui.TouchEventType.ended then
			arg_30_0.state = arg_30_0.state + 3
			arg_30_0.cellIndex = arg_30_1
			arg_30_0.itemId = arg_30_0.pediaCellIndex[arg_30_0.cellIndex]
			arg_30_0.itemPage = 1
			arg_30_0.itemMaxPage = math.ceil(#var_0_3:getTypes(arg_30_0.itemId) / 2)

			arg_30_0:updateAll()
		end
	end)
	var_30_0:addContent(var_30_3)

	return var_30_0
end

function var_0_0.updatePediaCell(arg_32_0)
	arg_32_0.right:removeAllChildren()
	arg_32_0.rightScroll:setVisible(true)
	arg_32_0.rightList:reload()
end

function var_0_0.updateInfoContent(arg_33_0)
	arg_33_0.right:removeAllChildren()
	arg_33_0.rightScroll:setVisible(false)

	local var_33_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/faq/info_wnd.csb")

	var_33_0:setAnchorPoint(0, 0)
	var_33_0:addTo(arg_33_0.right)
	var_33_0:setPosition(0, 0)

	local var_33_1 = var_0_9:getValue("contact_us")

	for iter_33_0 = 1, 6 do
		var_33_0:getChildByName("container"):getChildByName("txt" .. iter_33_0):setString(var_33_1[iter_33_0])
	end

	var_33_0:getChildByName("container"):getChildByName("txt7"):setString(var_0_6:translation("CONTACT_SENTENCE"))
end

function var_0_0.updateGuideItem(arg_34_0)
	arg_34_0.right:removeAllChildren()
	arg_34_0.rightScroll:setVisible(true)
	arg_34_0.rightList:reload()
end

function var_0_0.guideItemDelegate(arg_35_0, arg_35_1, arg_35_2, arg_35_3)
	if cc.ui.UIListView.COUNT_TAG == arg_35_2 then
		return arg_35_0.guideCellIndex[arg_35_0.cellIndex + 1] - arg_35_0.guideCellIndex[arg_35_0.cellIndex]
	elseif cc.ui.UIListView.CELL_TAG == arg_35_2 then
		local var_35_0 = arg_35_0.guideCellIndex[arg_35_0.cellIndex] + arg_35_3 - 1
		local var_35_1 = arg_35_0.rightList:dequeueItem()

		if not var_35_1 then
			var_35_1 = arg_35_0.rightList:newItem()
		else
			var_35_1:removeAllChildren(true)
		end

		local var_35_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/faq/guide_item.csb")
		local var_35_3 = var_35_2:getChildByName("container")
		local var_35_4 = var_35_3:getContentSize()

		var_35_3:getChildByName("title"):enableOutline(cc.c4b(151, 47, 128, 255), 2)
		var_35_3:getChildByName("title"):setString(var_0_5:getName(var_35_0))
		var_35_3:getChildByName("desc"):setString(var_0_5:getContent(var_35_0))
		var_35_3:getChildByName("btn"):getChildByName("txt"):setString(var_0_6:translation("BUTTON_NAME_GO"))

		local var_35_5 = var_35_3:getChildByName("btn")
		local var_35_6 = var_0_5:getWindowName(var_35_0)
		local var_35_7 = var_0_5:getFunctionId(var_35_0)

		var_35_5:setVisible(var_35_7 >= 0 and var_35_6 ~= "")
		var_35_5:addTouchEventListener(function(arg_36_0, arg_36_1)
			xyd.buttonScaleAnim(var_35_5, arg_36_1)

			if arg_36_1 == ccui.TouchEventType.ended and not arg_35_0.scrollViewMoved_ then
				if var_35_7 == 0 or arg_35_0.selfPlayer:isFuncOpen(var_35_7) then
					xyd.WindowManager.get():openWindow(var_35_6)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_6:translation("FUNCTION_OPEN_TIP_OTHER")
					})
				end
			end
		end)
		var_35_2:setPosition(-var_35_4.width / 2, -var_35_4.height / 2)
		var_35_2:setTouchSwallowEnabled(false)
		var_35_1:setItemSize(var_35_4.width, var_35_4.height)
		var_35_1:addContent(var_35_2)

		return var_35_1
	end
end

function var_0_0.updatePediaItem(arg_37_0)
	arg_37_0.right:removeAllChildren()
	arg_37_0.rightScroll:setVisible(false)

	for iter_37_0 = 1, 2 do
		local var_37_0 = var_0_3:getTypes(arg_37_0.itemId)[arg_37_0.itemPage * 2 - 2 + iter_37_0]
		local var_37_1 = var_0_3:getContents(arg_37_0.itemId)[arg_37_0.itemPage * 2 - 2 + iter_37_0]

		if not var_37_0 then
			break
		end

		local var_37_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/faq/pedia_item" .. var_37_0 .. ".csb")

		var_37_2:setAnchorPoint(0, 0)
		var_37_2:addTo(arg_37_0.right)

		local var_37_3 = var_37_2:getChildByName("container")

		var_37_2:setPosition((iter_37_0 - 1) * 684, (iter_37_0 - 1) * 33)

		if iter_37_0 == 1 then
			var_37_3:getChildByName("title"):setString(var_0_3:getName(arg_37_0.itemId))

			local var_37_4 = string.len(var_0_3:getName(arg_37_0.itemId))

			var_37_3:getChildByName("title_maohao1"):setPosition(333 - var_37_4 / 2 * 20 - 30, 535)
			var_37_3:getChildByName("title_maohao2"):setPosition(333 + var_37_4 / 2 * 20 + 30, 535)

			local var_37_5 = xyd.AssetLoader.get():loadSprite(var_37_1)

			var_37_5:setAnchorPoint(0, 0)
			var_37_5:setScale(1)
			var_37_5:addTo(var_37_3:getChildByName("img_pos"))
			var_37_5:setPosition(cc.p(0, 0))
			var_37_5:setGlobalZOrder(10)

			arg_37_0.img = var_37_5

			var_37_3:getChildByName("pic"):setGlobalZOrder(11)
		else
			var_37_3:getChildByName("txt"):setString("       " .. var_37_1)
		end
	end
end

function var_0_0.updateImgShow(arg_38_0)
	if arg_38_0.img and not tolua.isnull(arg_38_0.img) then
		if arg_38_0.isScaleUp then
			arg_38_0.img:setScale(2)
			arg_38_0.img:setPosition(cc.p(-263, -106))
			arg_38_0.img:setGlobalZOrder(1000)
			arg_38_0.left1:setVisible(false)
			arg_38_0.left2:setVisible(false)
			arg_38_0.left3:setVisible(false)
		else
			arg_38_0.left1:setVisible(arg_38_0.state <= 3)
			arg_38_0.left2:setVisible(arg_38_0.state == 4)
			arg_38_0.left3:setVisible(arg_38_0.state == 5)
			arg_38_0.img:setScale(1)
			arg_38_0.img:setPosition(cc.p(0, 0))
			arg_38_0.img:setGlobalZOrder(10)
		end
	end
end

function var_0_0.addImgTouch(arg_39_0)
	arg_39_0.img:setTouchEnabled(true)
	arg_39_0.img:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_40_0)
		if arg_40_0.name == "ended" then
			arg_39_0.isScaleUp = not arg_39_0.isScaleUp

			arg_39_0:updateImgShow()
		end

		return true
	end)
end

function var_0_0.getPediaCellName(arg_41_0, arg_41_1)
	if arg_41_1 == #arg_41_0.pediaCellIndex - 1 then
		return var_0_6:translation("FAQ_GLOSSARY")
	end

	local var_41_0 = arg_41_1 == 1 and 1 or var_0_3:getLev(arg_41_0.pediaCellIndex[arg_41_1 - 1]) + 1
	local var_41_1 = var_0_3:getLev(arg_41_0.pediaCellIndex[arg_41_1])

	return string.format("LV%d~%d", var_41_0, var_41_1)
end

function var_0_0.updatePageBtn(arg_42_0)
	if arg_42_0.state == 5 then
		arg_42_0:nodeByName("front"):setVisible(arg_42_0.itemPage > 1)
		arg_42_0:nodeByName("next"):setVisible(arg_42_0.itemPage < arg_42_0.itemMaxPage)

		return
	end

	arg_42_0:nodeByName("front"):setVisible(false)
	arg_42_0:nodeByName("next"):setVisible(false)
end

function var_0_0.didOpen(arg_43_0)
	arg_43_0:addBlockLayer()
end

return var_0_0
