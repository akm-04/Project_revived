local var_0_0 = class("TaskWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.missionReward
local var_0_4 = xyd.tables.misc
local var_0_5 = 150
local var_0_6 = "windows/task/icon_progress_point.png"
local var_0_7 = "windows/task/icon_progress_point_yellow.png"
local var_0_8 = {
	xyd.TaskType.DAILY,
	xyd.TaskType.GROW,
	xyd.TaskType.AWAKE,
	xyd.TaskType.PARTNER,
	xyd.TaskType.CHALLENGE
}
local var_0_9 = {
	CHALLENGE = 5,
	PARTNER = 4,
	GROW = 2,
	AWAKE = 3,
	DAILY = 1
}
local var_0_10 = {
	30,
	60,
	90,
	120,
	150
}
local var_0_11 = {
	LARGE = 1000,
	MIDDLE = 500
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
	arg_1_0.redmark = xyd.ModelManager.get():loadModel(xyd.ModelType.REDMARK)
	arg_1_0.battlePass = xyd.ModelManager.get():loadModel(xyd.ModelType.BATTLE_PASS)
	arg_1_0.data = {}
end

function var_0_0.didOpen(arg_2_0)
	arg_2_0:layout()
	arg_2_0:onRegister()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.container = arg_3_0:nodeByName("container")
	arg_3_0.size = arg_3_0.container:getContentSize()

	arg_3_0.container:setLocalZOrder(1)

	arg_3_0.leftSidebar = arg_3_0:nodeByName("left_sidebar")

	local var_3_0 = {
		true,
		true,
		true,
		true,
		true
	}

	if arg_3_0.selfPlayer.lev < 90 then
		var_3_0[3] = false
	end

	if not arg_3_0.battlePass:isOpen() or not arg_3_0.battlePass:isFuncOpen() then
		var_3_0[5] = false
	end

	arg_3_0.leftSidebar:createSidebarList({
		var_0_2:translation("MISSION_DAILY"),
		var_0_2:translation("MISSION_GROW"),
		var_0_2:translation("MISSION_AWAKE"),
		var_0_2:translation("MISSION_PARTNER"),
		var_0_2:translation("MISSION_CHALLENGE")
	}, nil, nil, var_3_0)

	if not arg_3_0.task:getCurTaskType() then
		arg_3_0.leftSidebar:getBtnByIdx(var_0_9.DAILY):setBrightStyle(xyd.ButtonStyle.HIGHLIGHT)
	else
		for iter_3_0, iter_3_1 in ipairs(var_0_8) do
			if arg_3_0.task:getCurTaskType() == iter_3_1 then
				arg_3_0.leftSidebar:getBtnByIdx(iter_3_0):setBrightStyle(xyd.ButtonStyle.HIGHLIGHT)
			end
		end
	end

	arg_3_0:updateRedMark()
	arg_3_0:updateRight()
end

function var_0_0.updateRight(arg_4_0)
	local var_4_0 = arg_4_0.task:getCurTaskType()

	if var_4_0 == xyd.TaskType.DAILY then
		arg_4_0:updateDaily()
	elseif var_4_0 == xyd.TaskType.WEEK then
		arg_4_0:updateWeek()
	elseif var_4_0 == xyd.TaskType.GROW then
		arg_4_0:updateGrow()
		xyd.sendGudieBtnClick("grow")
	elseif var_4_0 == xyd.TaskType.AWAKE then
		arg_4_0:updateAwake()
	elseif var_4_0 == xyd.TaskType.PARTNER then
		arg_4_0:updatePartner()
	elseif var_4_0 == xyd.TaskType.CHALLENGE then
		arg_4_0:updateChallenge()
	end
end

function var_0_0.updateRedMark(arg_5_0)
	if arg_5_0.redmark:isRedmark(xyd.FunctionID.ID_MISSION, xyd.redmark.DAILY_TASK) then
		arg_5_0.leftSidebar:getBtnByIdx(var_0_9.DAILY):showRedPoint(true)
	else
		arg_5_0.leftSidebar:getBtnByIdx(var_0_9.DAILY):showRedPoint(false)
	end

	if arg_5_0.redmark:isRedmark(xyd.FunctionID.ID_MISSION, xyd.redmark.GROW_TASK) then
		arg_5_0.leftSidebar:getBtnByIdx(var_0_9.GROW):showRedPoint(true)
	else
		arg_5_0.leftSidebar:getBtnByIdx(var_0_9.GROW):showRedPoint(false)
	end

	if arg_5_0.redmark:isRedmark(xyd.FunctionID.ID_MISSION, xyd.redmark.AWAKE_TASK) then
		arg_5_0.leftSidebar:getBtnByIdx(var_0_9.AWAKE):showRedPoint(true)
	else
		arg_5_0.leftSidebar:getBtnByIdx(var_0_9.AWAKE):showRedPoint(false)
	end

	if arg_5_0.redmark:isRedmark(xyd.FunctionID.ID_MISSION, xyd.redmark.PARTNER_TASK) then
		arg_5_0.leftSidebar:getBtnByIdx(var_0_9.PARTNER):showRedPoint(true)
	else
		arg_5_0.leftSidebar:getBtnByIdx(var_0_9.PARTNER):showRedPoint(false)
	end

	if arg_5_0.redmark:isRedmark(xyd.FunctionID.ID_BATTLE_PASS, xyd.redmark.BATTLE_PASS_MISSION_COMPLETE) then
		arg_5_0.leftSidebar:getBtnByIdx(var_0_9.CHALLENGE):showRedPoint(true)
	else
		arg_5_0.leftSidebar:getBtnByIdx(var_0_9.CHALLENGE):showRedPoint(false)
	end
end

function var_0_0.updateDaily(arg_6_0)
	arg_6_0:clearRes()

	arg_6_0.data = arg_6_0.task:getTaskByType(arg_6_0.task:getCurTaskType())

	local var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/task/task_daily_huoyue.csb")

	var_6_0:addTo(arg_6_0.container)
	var_6_0:setAnchorPoint(0, 0)
	var_6_0:setPosition(-5, 511)

	local var_6_1 = var_6_0:getChildByName("background")

	arg_6_0.dailyHuoyueProgress = var_6_1:getChildByName("progress_bar")

	arg_6_0.dailyHuoyueProgress:setPercent(arg_6_0.task:getDailyHuoyue() / var_0_5 * 100)

	arg_6_0.dailyHuoyueLabel = xyd.AssetLoader.get():loadLabel(nil, "task_num")

	arg_6_0.dailyHuoyueLabel:setAnchorPoint(0.5, 0.5)
	arg_6_0.dailyHuoyueLabel:addTo(var_6_1)
	arg_6_0.dailyHuoyueLabel:setPosition(var_6_1:getChildByName("pos_txt_daily_badge"):getPosition())

	arg_6_0.dailyGiftIcons = {}
	arg_6_0.dailyGiftOpenIcons = {}
	arg_6_0.dailyGiftEffects = {}
	arg_6_0.dailyNodes = {}
	arg_6_0.dailyPt = {}

	for iter_6_0, iter_6_1 in ipairs(var_0_10) do
		local var_6_2 = var_6_1:getChildByName("icon_gift_" .. iter_6_0)
		local var_6_3 = var_6_1:getChildByName("icon_gift_open_" .. iter_6_0)

		arg_6_0.dailyGiftIcons[iter_6_0] = var_6_2
		arg_6_0.dailyGiftOpenIcons[iter_6_0] = var_6_3

		local var_6_4, var_6_5 = var_6_2:getPosition()
		local var_6_6 = "skeletons/ui_effect/daily_mission/daily_mission_box01.json"
		local var_6_7 = "skeletons/ui_effect/daily_mission/daily_mission_box01.atlas"
		local var_6_8 = var_0_1.new(var_6_6, var_6_7, 1)

		var_6_8:setAnchorPoint(0.5, 0.5)
		var_6_8:addTo(var_6_1)
		var_6_8:setPosition(var_6_4, var_6_5 - 7)

		arg_6_0.dailyGiftEffects[iter_6_0] = var_6_8

		local var_6_9 = display.newNode()

		var_6_9:addTo(var_6_1)
		var_6_9:setAnchorPoint(0.5, 0.5)
		var_6_9:setPosition(var_6_4, var_6_5)
		var_6_9:setContentSize(var_6_2:getContentSize())
		var_6_9:setTouchEnabled(true)
		var_6_9:setTouchSwallowEnabled(true)

		arg_6_0.dailyNodes[iter_6_0] = var_6_9

		local var_6_10 = xyd.AssetLoader.get():loadSprite(var_0_6)

		var_6_10:addTo(var_6_1)
		var_6_10:setAnchorPoint(0.5, 0.5)

		local var_6_11, var_6_12 = var_6_1:getChildByName("pos_pt_" .. iter_6_1):getPosition()

		var_6_10:setPosition(var_6_11, var_6_12)

		arg_6_0.dailyPt[iter_6_0] = var_6_10
	end

	arg_6_0:updateDailyHuoyue()

	local var_6_13 = xyd.AssetLoader.get():loadNodeFromJson("windows/task/task_week_huoyue.csb")

	var_6_13:addTo(arg_6_0.container)
	var_6_13:setAnchorPoint(0, 0)
	var_6_13:setPosition(0, 0)

	local var_6_14 = var_6_13:getChildByName("background")

	arg_6_0.weeklyHuoyueLabel = xyd.AssetLoader.get():loadLabel(nil, "task_num")

	arg_6_0.weeklyHuoyueLabel:setAnchorPoint(0.5, 0.5)
	arg_6_0.weeklyHuoyueLabel:addTo(var_6_14)

	local var_6_15, var_6_16 = var_6_14:getChildByName("pos_week_badge_val"):getPosition()

	arg_6_0.weeklyHuoyueLabel:setPosition(var_6_15 + 5, var_6_16 - 5)

	local var_6_17 = xyd.AssetLoader.get():loadLabel(nil, "task_num")

	var_6_17:setAnchorPoint(0.5, 0.5)
	var_6_17:addTo(var_6_14)

	local var_6_18, var_6_19 = var_6_14:getChildByName("pos_word_500"):getPosition()

	var_6_17:setPosition(var_6_18 - 1, var_6_19 - 6)
	var_6_17:setString("500")

	local var_6_20 = xyd.AssetLoader.get():loadLabel(nil, "task_num")

	var_6_20:setAnchorPoint(0.5, 0.5)
	var_6_20:addTo(var_6_14)

	local var_6_21, var_6_22 = var_6_14:getChildByName("pos_word_1000"):getPosition()

	var_6_20:setPosition(var_6_21 - 6, var_6_22 - 6)
	var_6_20:setString("1000")

	arg_6_0.weeklyNodes = {}

	local var_6_23 = "skeletons/ui_effect/daily_mission/daily_mission_boxmiddle"

	arg_6_0.middleEffect = var_0_1.new(var_6_23 .. ".json", var_6_23 .. ".atlas", 1)

	arg_6_0.middleEffect:addTo(var_6_13:getChildByName("background"))

	arg_6_0.middleIcon = var_6_13:getChildByName("background"):getChildByName("icon_gift_500")

	local var_6_24, var_6_25 = arg_6_0.middleIcon:getPosition()

	arg_6_0.middleEffect:setAnchorPoint(0.5, 0.5)
	arg_6_0.middleEffect:setPosition(var_6_24, var_6_25)

	arg_6_0.middleOpenIcon = var_6_13:getChildByName("background"):getChildByName("icon_gift_500_open")

	local var_6_26 = display.newNode()

	var_6_26:addTo(var_6_13:getChildByName("background"))
	var_6_26:setContentSize(arg_6_0.middleIcon:getContentSize())
	var_6_26:setAnchorPoint(0.5, 0.5)
	var_6_26:setPosition(arg_6_0.middleIcon:getPosition())
	var_6_26:setTouchEnabled(true)
	var_6_26:setTouchSwallowEnabled(true)

	arg_6_0.weeklyNodes[var_0_11.MIDDLE] = var_6_26

	local var_6_27 = "skeletons/ui_effect/daily_mission/daily_mission_boxbig"

	arg_6_0.largeEffect = var_0_1.new(var_6_27 .. ".json", var_6_27 .. ".atlas", 1)

	arg_6_0.largeEffect:addTo(var_6_13:getChildByName("background"))

	arg_6_0.largeIcon = var_6_13:getChildByName("background"):getChildByName("icon_gift_1000")

	local var_6_28, var_6_29 = arg_6_0.largeIcon:getPosition()

	arg_6_0.largeEffect:setAnchorPoint(0.5, 0.5)
	arg_6_0.largeEffect:setPosition(var_6_28, var_6_29)

	arg_6_0.largeOpenIcon = var_6_13:getChildByName("background"):getChildByName("icon_gift_1000_open")

	local var_6_30 = display.newNode()

	var_6_30:addTo(var_6_13:getChildByName("background"))
	var_6_30:setContentSize(arg_6_0.largeIcon:getContentSize())
	var_6_30:setAnchorPoint(0.5, 0.5)
	var_6_30:setPosition(arg_6_0.largeIcon:getPosition())
	var_6_30:setTouchEnabled(true)
	var_6_30:setTouchSwallowEnabled(true)

	arg_6_0.weeklyNodes[var_0_11.LARGE] = var_6_30

	arg_6_0:updateWeeklyHuoyue()

	arg_6_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_6_0.container:getWidth(), 440),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_6_0.container):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.list:setAnchorPoint(0, 0)
	arg_6_0.list:setPosition(0, 90)
	arg_6_0.list:setDelegate(handler(arg_6_0, arg_6_0.delegate))
	arg_6_0.list:reload()
	arg_6_0:registerWeeklyHuoyueBtn(var_0_11.MIDDLE)
	arg_6_0:registerWeeklyHuoyueBtn(var_0_11.LARGE)

	for iter_6_2, iter_6_3 in ipairs(var_0_10) do
		arg_6_0:registerDailyHuoyueBtn(iter_6_2)
	end
end

function var_0_0.updateGrow(arg_7_0)
	arg_7_0:clearRes()

	arg_7_0.data = arg_7_0.task:getTaskByType(arg_7_0.task:getCurTaskType())

	if not arg_7_0.data or not next(arg_7_0.data) then
		arg_7_0:noTaskShow()

		return
	end

	arg_7_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_7_0.container:getWidth(), 620),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_7_0.container):onScroll(handler(arg_7_0, arg_7_0.scrollListener))

	arg_7_0.list:setAnchorPoint(0, 0)
	arg_7_0.list:setPosition(0, 0)
	arg_7_0.list:setDelegate(handler(arg_7_0, arg_7_0.delegate))
	arg_7_0.list:reload()
end

function var_0_0.updateAwake(arg_8_0)
	arg_8_0:clearRes()

	arg_8_0.data = arg_8_0.task:getTaskByType(arg_8_0.task:getCurTaskType())

	if not arg_8_0.data or not next(arg_8_0.data) then
		arg_8_0:noTaskShow()

		return
	end

	arg_8_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_8_0.container:getWidth(), 620),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_8_0.container):onScroll(handler(arg_8_0, arg_8_0.scrollListener))

	arg_8_0.list:setAnchorPoint(0, 0)
	arg_8_0.list:setPosition(0, 0)
	arg_8_0.list:setDelegate(handler(arg_8_0, arg_8_0.delegate))
	arg_8_0.list:reload()
end

function var_0_0.updatePartner(arg_9_0)
	arg_9_0:clearRes()

	arg_9_0.data = arg_9_0.task:getTaskByType(arg_9_0.task:getCurTaskType())

	if not arg_9_0.data or not next(arg_9_0.data) then
		arg_9_0:noTaskShow()

		return
	end

	arg_9_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_9_0.container:getWidth(), 620),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_9_0.container):onScroll(handler(arg_9_0, arg_9_0.scrollListener))

	arg_9_0.list:setAnchorPoint(0, 0)
	arg_9_0.list:setPosition(0, 0)
	arg_9_0.list:setDelegate(handler(arg_9_0, arg_9_0.delegate))
	arg_9_0.list:reload()
end

function var_0_0.updateChallenge(arg_10_0)
	arg_10_0:clearRes()

	arg_10_0.data = arg_10_0.battlePass:getTaskDatas()

	if not arg_10_0.data or not next(arg_10_0.data) then
		arg_10_0:noTaskShow()

		return
	end

	local var_10_0 = arg_10_0.battlePass:getLevel()
	local var_10_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/task/challenge_main.csb")

	var_10_1:setName("challenge_main")
	arg_10_0.container:addChild(var_10_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), var_10_1):addEventListener(xyd.event.BATTLE_PASS_POINT_CHANGE, handler(arg_10_0, arg_10_0.updatePoint))
	var_10_1:getChildByName("txt_gp"):enableOutline(cc.c4b(52, 54, 55, 255), 2)
	var_10_1:getChildByName("txt_level"):setString(var_10_0)

	local var_10_2 = 945 - (var_10_1:getChildByName("txt_level"):getContentSize().width - 39) / 2

	var_10_1:getChildByName("word_lv"):setPositionX(var_10_2)
	var_10_1:getChildByName("txt_level"):setPositionX(var_10_2)

	local var_10_3 = arg_10_0.battlePass:getPoint() .. "/" .. var_0_4:getValue("battle_pass_point_per_level")

	var_10_1:getChildByName("txt_gp"):setString(var_10_3)

	local var_10_4 = var_10_1:getChildByName("list"):getContentSize()

	arg_10_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_10_4.width, var_10_4.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_10_1:getChildByName("list")):onScroll(handler(arg_10_0, arg_10_0.scrollListener))
	arg_10_0.challengeWeek = 1

	var_10_1:getChildByName("btn_week_1"):setBrightStyle(ccui.BrightStyle.highlight)

	for iter_10_0 = 1, 6 do
		local var_10_5 = var_10_1:getChildByName("btn_week_" .. iter_10_0)
		local var_10_6 = string.format(var_0_2:translation("BATTLE_PASS_TEXT_33"), var_0_2:translation("NUM_" .. iter_10_0))

		var_10_5:getChildByName("txt"):setString(var_10_6)

		if iter_10_0 <= arg_10_0.battlePass:getWeek() then
			var_10_5:addTouchEventListener(function(arg_11_0, arg_11_1)
				if arg_11_1 == ccui.TouchEventType.ended then
					for iter_11_0 = 1, 6 do
						if iter_11_0 == iter_10_0 then
							var_10_1:getChildByName("btn_week_" .. iter_11_0):setBrightStyle(ccui.BrightStyle.highlight)
						else
							var_10_1:getChildByName("btn_week_" .. iter_11_0):setBrightStyle(ccui.BrightStyle.normal)
						end
					end

					arg_10_0.challengeWeek = iter_10_0

					arg_10_0.list:reload()
				end
			end)
		else
			var_10_5:setTouchEnabled(false)
			var_10_5:getChildByName("mask"):setVisible(true)
		end
	end

	arg_10_0.list:setDelegate(handler(arg_10_0, arg_10_0.battlePassDelegate))
	arg_10_0.list:reload()
end

function var_0_0.updatePoint(arg_12_0)
	local var_12_0 = arg_12_0.container:getChildByName("challenge_main")

	if not var_12_0 then
		return
	end

	local var_12_1 = arg_12_0.battlePass:getLevel()

	var_12_0:getChildByName("txt_level"):setString(var_12_1)

	local var_12_2 = 945 - (var_12_0:getChildByName("txt_level"):getContentSize().width - 39) / 2

	var_12_0:getChildByName("word_lv"):setPositionX(var_12_2)
	var_12_0:getChildByName("txt_level"):setPositionX(var_12_2)

	local var_12_3 = arg_12_0.battlePass:getPoint() .. "/" .. var_0_4:getValue("battle_pass_point_per_level")

	var_12_0:getChildByName("txt_gp"):setString(var_12_3)
end

function var_0_0.clearRes(arg_13_0)
	arg_13_0.container:removeAllChildren()

	arg_13_0.list = nil
	arg_13_0.dailyGiftIcons = nil
	arg_13_0.dailyGiftOpenIcons = nil
	arg_13_0.dailyGiftEffects = nil
	arg_13_0.dailyHuoyueLabel = nil
	arg_13_0.weeklyHuoyueLabel = nil
	arg_13_0.largeIcon = nil
	arg_13_0.middleIcon = nil
	arg_13_0.largeEffect = nil
	arg_13_0.middleEffect = nil
	arg_13_0.largeOpenIcon = nil
	arg_13_0.middleOpenIcon = nil
	arg_13_0.dailyHuoyueProgress = nil
	arg_13_0.dailyNodes = nil
	arg_13_0.weeklyNodes = nil
end

function var_0_0.noTaskShow(arg_14_0)
	local var_14_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/task/no_task_bg.csb")
	local var_14_1 = var_14_0:getChildByName("background"):getChildByName("txt_container")
	local var_14_2 = var_0_2:translation("TASK_EMPTY_TIP")
	local var_14_3 = xyd.createAutoFixLabel({
		fontSize = 24,
		txtColor = "#44454D",
		width = var_14_1:getWidth() + 5,
		height = var_14_1:getHeight() + 5,
		text = var_14_2,
		align = cc.ui.TEXT_ALIGN_CENTER,
		valign = cc.ui.TEXT_VALIGN_CENTER
	})

	var_14_3:addTo(var_14_1)
	var_14_3:setAnchorPoint(0, 0)
	var_14_3:setPosition(0, 0)
	var_14_0:addTo(arg_14_0.container)
	var_14_0:setAnchorPoint(0, 0)
	var_14_0:setPosition(200, 110)
end

function var_0_0.delegate(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	if cc.ui.UIListView.COUNT_TAG == arg_15_2 then
		local var_15_0

		if arg_15_0.task:getCurTaskType() == xyd.TaskType.DAILY then
			var_15_0 = math.ceil(#arg_15_0.data / 2)
		else
			var_15_0 = #arg_15_0.data
		end

		return var_15_0
	elseif cc.ui.UIListView.CELL_TAG == arg_15_2 then
		local var_15_1
		local var_15_2 = arg_15_1:dequeueItem()

		if not var_15_2 then
			var_15_2 = arg_15_1:newItem()
		else
			var_15_2:removeAllChildren(false)
		end

		local var_15_3

		if arg_15_0.task:getCurTaskType() == xyd.TaskType.DAILY then
			var_15_3 = {
				arg_15_0.task:getTaskByType(xyd.TaskType.DAILY)[2 * arg_15_3 - 1],
				arg_15_0.task:getTaskByType(xyd.TaskType.DAILY)[2 * arg_15_3]
			}
		else
			var_15_3 = arg_15_0.task:getTaskByType(arg_15_0.task:getCurTaskType())[arg_15_3]
		end

		local var_15_4 = {
			top = 0,
			left = 0,
			bottom = 0,
			right = 0
		}
		local var_15_5 = arg_15_0:createListCell(var_15_3)
		local var_15_6 = var_15_5:getWidth()
		local var_15_7 = var_15_5:getHeight()

		var_15_2:setMargin(var_15_4)
		var_15_2:setItemSize(var_15_6, var_15_7)
		var_15_2:addContent(var_15_5)

		return var_15_2
	end
end

function var_0_0.battlePassDelegate(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	if cc.ui.UIListView.COUNT_TAG == arg_16_2 then
		return math.ceil(#arg_16_0.data[arg_16_0.challengeWeek])
	elseif cc.ui.UIListView.CELL_TAG == arg_16_2 then
		local var_16_0
		local var_16_1 = arg_16_1:dequeueItem()

		if not var_16_1 then
			var_16_1 = arg_16_1:newItem()
		else
			var_16_1:removeAllChildren(false)
		end

		local var_16_2 = arg_16_0.data[arg_16_0.challengeWeek][arg_16_3]
		local var_16_3 = {
			top = 0,
			left = 0,
			bottom = 0,
			right = 0
		}
		local var_16_4 = arg_16_0:createListCell(var_16_2)
		local var_16_5 = var_16_4:getWidth()
		local var_16_6 = var_16_4:getHeight()

		var_16_1:setMargin(var_16_3)
		var_16_1:setItemSize(var_16_5, var_16_6)
		var_16_1:addContent(var_16_4)

		return var_16_1
	end
end

function var_0_0.createListCell(arg_17_0, arg_17_1)
	local var_17_0

	if arg_17_0.task:getCurTaskType() == xyd.TaskType.DAILY then
		var_17_0 = import("app.windows.TaskDailyCell")
	elseif arg_17_0.task:getCurTaskType() == xyd.TaskType.WEEK then
		var_17_0 = import("app.windows.TaskWeekCell")
	elseif arg_17_0.task:getCurTaskType() == xyd.TaskType.AWAKE then
		var_17_0 = import("app.windows.TaskAwakeCell")
	elseif arg_17_0.task:getCurTaskType() == xyd.TaskType.GROW then
		var_17_0 = import("app.windows.TaskGrowCell")
	elseif arg_17_0.task:getCurTaskType() == xyd.TaskType.PARTNER then
		var_17_0 = import("app.windows.TaskPartnerCell")
	elseif arg_17_0.task:getCurTaskType() == xyd.TaskType.CHALLENGE then
		var_17_0 = import("app.windows.TaskChallengeCell")
	end

	local var_17_1 = display.newNode()

	if arg_17_0.task:getCurTaskType() == xyd.TaskType.DAILY then
		local var_17_2 = 23
		local var_17_3
		local var_17_4

		if arg_17_1[1] then
			var_17_3 = var_17_0.new({
				taskInfo = arg_17_1[1]
			})

			var_17_3:layout()
			var_17_3:setAnchorPoint(0.5, 0.5)
			var_17_3:addTo(var_17_1)
			var_17_3:setPosition(0.5 * var_17_3:getWidth(), 0.5 * var_17_3:getHeight())
		end

		if arg_17_1[2] then
			local var_17_5 = var_17_0.new({
				taskInfo = arg_17_1[2]
			})

			var_17_5:layout()
			var_17_5:setAnchorPoint(0.5, 0.5)
			var_17_5:addTo(var_17_1)
			var_17_5:setPosition(1.5 * var_17_3:getWidth() + var_17_2, 0.5 * var_17_3:getHeight())
		end

		if var_17_3 then
			var_17_1:setContentSize(var_17_3:getWidth() * 2 + var_17_2, var_17_3:getHeight())
		end
	elseif arg_17_1 then
		local var_17_6 = var_17_0.new({
			taskInfo = arg_17_1
		})

		var_17_6:layout()
		var_17_6:setAnchorPoint(0.5, 0.5)
		var_17_6:addTo(var_17_1)
		var_17_1:setContentSize(var_17_6:getWidth(), var_17_6:getHeight())
		var_17_6:setPosition(0.5 * var_17_6:getWidth(), 0.5 * var_17_6:getHeight())
	end

	return var_17_1
end

function var_0_0.battlePassRefreshList(arg_18_0)
	arg_18_0.data = arg_18_0.battlePass:getTaskDatas()

	if arg_18_0.list and not tolua.isnull(arg_18_0.list) then
		arg_18_0.list:refreshList(nil, true)
	end
end

function var_0_0.refreshList(arg_19_0)
	if arg_19_0.list and not tolua.isnull(arg_19_0.list) then
		arg_19_0.list:refreshList(nil, true)
	end

	if arg_19_0.task:getCurTaskType() == xyd.TaskType.DAILY then
		arg_19_0:updateDailyHuoyue()
		arg_19_0:updateWeeklyHuoyue()
	end

	if arg_19_0.task:getCurTaskType() == xyd.TaskType.GROW or arg_19_0.task:getCurTaskType() == xyd.TaskType.AWAKE or arg_19_0.task:getCurTaskType() == xyd.TaskType.PARTNER then
		arg_19_0.data = arg_19_0.task:getTaskByType(arg_19_0.task:getCurTaskType())

		if not arg_19_0.data or not next(arg_19_0.data) then
			arg_19_0:noTaskShow()
		end
	end
end

function var_0_0.updateDailyHuoyue(arg_20_0)
	if not arg_20_0.dailyGiftIcons or not next(arg_20_0.dailyGiftIcons) or not arg_20_0.dailyGiftOpenIcons or not next(arg_20_0.dailyGiftOpenIcons) or not arg_20_0.dailyGiftEffects or not next(arg_20_0.dailyGiftEffects) then
		return
	end

	local var_20_0 = arg_20_0.task:getDailyHuoyue()
	local var_20_1 = arg_20_0.task:getDailyHuoyueAwards()
	local var_20_2 = xyd.AssetLoader.get():loadSprite(var_0_7)

	for iter_20_0, iter_20_1 in ipairs(var_0_10) do
		if var_20_0 < iter_20_1 then
			arg_20_0.dailyGiftOpenIcons[iter_20_0]:setVisible(false)
			arg_20_0.dailyGiftIcons[iter_20_0]:setVisible(true)
			arg_20_0.dailyGiftEffects[iter_20_0]:setVisible(false)
		elseif iter_20_1 <= var_20_0 and var_20_1[iter_20_0] == 0 then
			arg_20_0.dailyGiftOpenIcons[iter_20_0]:setVisible(false)
			arg_20_0.dailyGiftIcons[iter_20_0]:setVisible(false)
			arg_20_0.dailyGiftEffects[iter_20_0]:setVisible(true)
			arg_20_0.dailyGiftEffects[iter_20_0]:play(nil, true)
		else
			arg_20_0.dailyGiftOpenIcons[iter_20_0]:setVisible(true)
			arg_20_0.dailyGiftIcons[iter_20_0]:setVisible(false)
			arg_20_0.dailyGiftEffects[iter_20_0]:setVisible(false)
		end

		if iter_20_1 <= var_20_0 then
			arg_20_0.dailyPt[iter_20_0]:setSpriteFrame(var_20_2:getSpriteFrame())
		end

		arg_20_0:registerDailyHuoyueBtn(iter_20_0)
	end

	arg_20_0.dailyHuoyueProgress:setPercent(arg_20_0.task:getDailyHuoyue() / var_0_5 * 100)
	arg_20_0.dailyHuoyueLabel:setString(arg_20_0.task:getDailyHuoyue())
end

function var_0_0.updateWeeklyHuoyue(arg_21_0)
	arg_21_0.weeklyHuoyueLabel:setString(arg_21_0.task:getWeekHuoyue())

	local var_21_0 = arg_21_0.task:getWeekHuoyue()
	local var_21_1 = arg_21_0.task:getWeeklyHuoyueAwards()

	if var_21_0 >= var_0_11.MIDDLE then
		if var_21_1[1] == 1 then
			arg_21_0.middleIcon:setVisible(false)
			arg_21_0.middleEffect:setVisible(false)
			arg_21_0.middleOpenIcon:setVisible(true)
		else
			arg_21_0.middleIcon:setVisible(false)
			arg_21_0.middleEffect:setVisible(true)
			arg_21_0.middleOpenIcon:setVisible(false)
			arg_21_0.middleEffect:play(nil, true)
		end
	else
		arg_21_0.middleIcon:setVisible(true)
		arg_21_0.middleEffect:setVisible(false)
		arg_21_0.middleOpenIcon:setVisible(false)
	end

	if var_21_0 >= var_0_11.LARGE then
		if var_21_1[2] == 1 then
			arg_21_0.largeIcon:setVisible(false)
			arg_21_0.largeEffect:setVisible(false)
			arg_21_0.largeOpenIcon:setVisible(true)
		else
			arg_21_0.largeIcon:setVisible(false)
			arg_21_0.largeEffect:setVisible(true)
			arg_21_0.largeOpenIcon:setVisible(false)
			arg_21_0.largeEffect:play(nil, true)
		end
	else
		arg_21_0.largeIcon:setVisible(true)
		arg_21_0.largeEffect:setVisible(false)
		arg_21_0.largeOpenIcon:setVisible(false)
	end
end

function var_0_0.registerDailyHuoyueBtn(arg_22_0, arg_22_1)
	local var_22_0

	if arg_22_0.selfPlayer.lev < arg_22_0.selfPlayer.maxTeamLev then
		var_22_0 = var_0_3:gift(arg_22_1)
	else
		var_22_0 = var_0_3:gift2(arg_22_1)
	end

	xyd.addGiftTips(arg_22_0.dailyNodes[arg_22_1], {
		gift_id = var_22_0
	}, function()
		arg_22_0.task:getDailyHuoyueAward(arg_22_1, function(arg_24_0, arg_24_1)
			if arg_24_0 == xyd.error.OK then
				arg_22_0.task:setDailyHuoyueAwards(arg_22_1)
				arg_22_0:updateDailyHuoyue()

				local var_24_0 = "skeletons/ui_effect/daily_mission/daily_mission_light.json"
				local var_24_1 = "skeletons/ui_effect/daily_mission/daily_mission_light.atlas"
				local var_24_2
				local var_24_3 = var_0_1.new(var_24_0, var_24_1, 1)

				var_24_3:setAnchorPoint(cc.p(0.5, 0.5))
				var_24_3:addTo(arg_22_0.dailyGiftIcons[arg_22_1]:getParent())
				var_24_3:setPosition(arg_22_0.dailyGiftIcons[arg_22_1]:getPosition())
				var_24_3:play(function()
					var_24_3:setVisible(false)
				end, false)
				var_24_3:setContentSize(1, 1)
				var_24_3:setScale(1.3)

				local var_24_4 = {}

				if arg_24_1.awards then
					arg_22_0.selfPlayer:handleRewards(arg_24_1.awards)

					var_24_4.awards = arg_24_1.awards
				end

				local var_24_5 = xyd.WindowManager.get():getWindow(xyd.WindowName.TASK)

				if var_24_5 and not tolua.isnull(var_24_5) then
					var_24_5:updateWeeklyHuoyue()
				end

				if arg_24_1.caozhi_quiz == 1 then
					function var_24_4.callback()
						local var_26_0 = var_0_2:translation("ACTIVITY_TEXT_PAPER_TIPS")

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_26_0, function()
							xyd.WindowManager.get():closeWindow(arg_22_0)
							xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadActivities(function(arg_28_0)
								if arg_28_0 == xyd.error.OK then
									xyd.WindowManager.get():openWindow("activities", {
										default_table_id = xyd.Activities.TextPaper
									})
								end
							end)
						end, nil, nil, arg_22_0.colorMode)
					end
				end

				xyd.WindowManager.get():openWindow("alert_award", var_24_4)
			end
		end)
	end)
end

function var_0_0.registerWeeklyHuoyueBtn(arg_29_0, arg_29_1)
	local var_29_0
	local var_29_1

	if arg_29_1 == var_0_11.MIDDLE then
		var_29_0 = 1
		var_29_1 = 6
	elseif arg_29_1 == var_0_11.LARGE then
		var_29_0 = 2
		var_29_1 = 7
	end

	local var_29_2

	if arg_29_0.selfPlayer.lev < arg_29_0.selfPlayer.maxTeamLev then
		var_29_2 = var_0_3:gift(var_29_1)
	else
		var_29_2 = var_0_3:gift2(var_29_1)
	end

	xyd.addGiftTips(arg_29_0.weeklyNodes[arg_29_1], {
		gift_id = var_29_2
	}, function()
		arg_29_0.task:getWeekHuoyueAward(var_29_0, function(arg_31_0, arg_31_1)
			if arg_31_0 == xyd.error.OK then
				arg_29_0.task:setWeeklyHuoyueAwards(var_29_0)
				arg_29_0:updateWeeklyHuoyue()

				local var_31_0 = "skeletons/ui_effect/daily_mission/daily_mission_light.json"
				local var_31_1 = "skeletons/ui_effect/daily_mission/daily_mission_light.atlas"
				local var_31_2
				local var_31_3 = var_0_1.new(var_31_0, var_31_1, 1)

				var_31_3:setAnchorPoint(cc.p(0.5, 0.5))
				var_31_3:addTo(arg_29_0.weeklyNodes[arg_29_1]:getParent())
				var_31_3:setPosition(arg_29_0.weeklyNodes[arg_29_1]:getPosition())
				var_31_3:play(function()
					var_31_3:setVisible(false)
				end, false)
				var_31_3:setContentSize(1, 1)
				var_31_3:setScale(1.3)

				local var_31_4 = {}

				if arg_31_1.awards then
					arg_29_0.selfPlayer:handleRewards(arg_31_1.awards)

					var_31_4.awards = arg_31_1.awards
				end

				local var_31_5 = xyd.WindowManager.get():getWindow(xyd.WindowName.TASK)

				if var_31_5 and not tolua.isnull(var_31_5) then
					var_31_5:updateWeeklyHuoyue()
				end

				if arg_31_1.caozhi_quiz == 1 then
					function var_31_4.callback()
						local var_33_0 = var_0_2:translation("ACTIVITY_TEXT_PAPER_TIPS")

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_33_0, function()
							xyd.WindowManager.get():closeWindow(arg_29_0)
							xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadActivities(function(arg_35_0)
								if arg_35_0 == xyd.error.OK then
									xyd.WindowManager.get():openWindow("activities", {
										default_table_id = xyd.Activities.TextPaper
									})
								end
							end)
						end, nil, nil, arg_29_0.colorMode)
					end
				end

				xyd.WindowManager.get():openWindow("alert_award", var_31_4)
			end
		end)
	end)
end

function var_0_0.onRegister(arg_36_0)
	arg_36_0:onRegisterCommon()
	arg_36_0:onRegisterButton()
end

function var_0_0.onRegisterCommon(arg_37_0)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_37_0):addEventListener(xyd.event.ON_MISSION_STATE_CHANGE, handler(arg_37_0, arg_37_0.refreshList))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_37_0):addEventListener(xyd.event.UPDATE_MISSION_ONTIME, handler(arg_37_0, arg_37_0.updateTask))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_37_0):addEventListener(xyd.event.BACKEND_REDMARK, handler(arg_37_0, arg_37_0.updateRedMark))
end

function var_0_0.onRegisterButton(arg_38_0)
	arg_38_0.leftSidebar:registerButton(function(arg_39_0, arg_39_1)
		if arg_39_1.name == "ended" then
			arg_38_0.task:setCurTaskType(var_0_8[arg_39_0])
			arg_38_0.task:loadTaskByType(nil, function()
				arg_38_0:updateRight()
			end)
		end
	end)
end

function var_0_0.scrollListener(arg_41_0, arg_41_1)
	if arg_41_1.name == "began" then
		arg_41_0.scrollViewMoved_ = false
		arg_41_0.prevY_ = arg_41_1.y
	elseif arg_41_1.name == "moved" and 20 <= math.abs(arg_41_1.y - arg_41_0.prevY_) then
		arg_41_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateTask(arg_42_0)
	arg_42_0.task:loadTaskByType(xyd.TaskType.DAILY, nil, true)
end

function var_0_0.didClose(arg_43_0)
	arg_43_0.task:clearTaskCache()
	xyd.checkFirstInGuide("main_scene_bottom")

	if xyd.WindowManager.get():getWindow("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	local var_43_0

	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_STONE_START then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.PLAY_GUIDE,
			params = {
				guide_id = xyd.GuideStoryType.GUIDE_STONE_START
			}
		})

		var_43_0 = true
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {
			quickAction = var_43_0
		}
	})
end

return var_0_0
