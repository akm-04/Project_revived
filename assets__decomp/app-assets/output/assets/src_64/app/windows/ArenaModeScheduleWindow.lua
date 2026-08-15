local var_0_0 = class("ArenaModeScheduleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.arenaMode

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)
	arg_1_0.scheduleinfos = {}

	local var_1_0 = xyd.ServerTime.get():getServerTime()

	for iter_1_0, iter_1_1 in ipairs(arg_1_2.infos) do
		if var_1_0 < iter_1_1.end_time then
			table.insert(arg_1_0.scheduleinfos, iter_1_1)
		end
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.listContainer = arg_2_0:nodeByName("des_container")

	arg_2_0:initOpenTip()
	arg_2_0:initDesList()
	arg_2_0:initItemList()
	arg_2_0:updateView(arg_2_0.scheduleinfos[1].mode)
end

function var_0_0.initOpenTip(arg_3_0)
	local var_3_0 = xyd.tables.misc.arenaModeRank
	local var_3_1 = xyd.tables.misc.arenaModeTimes

	if var_3_0 < arg_3_0.model.rank or var_3_1 > arg_3_0.model.fightTimes then
		arg_3_0:nodeByName("bg_tip"):setVisible(true)

		local var_3_2 = var_0_1:translation("ARENA_MODE_OPEN_TIP1")

		if var_3_0 < arg_3_0.model.rank then
			var_3_2 = var_3_2 .. string.format(var_0_1:translation("ARENA_MODE_OPEN_TIP2"), var_3_0, arg_3_0.model.rank, var_3_0)
		end

		if var_3_1 > arg_3_0.model.fightTimes then
			var_3_2 = var_3_2 .. string.format(var_0_1:translation("ARENA_MODE_OPEN_TIP3"), var_3_1, arg_3_0.model.fightTimes, var_3_1)
		end

		arg_3_0:nodeByName("label_open_tip"):setString(var_3_2)
		arg_3_0:nodeByName("label_open_tip"):setPositionX(5)
	else
		local var_3_3 = arg_3_0.listContainer:getContentSize()

		arg_3_0.listContainer:setContentSize(var_3_3.width, var_3_3.height + 30)
	end
end

function var_0_0.initDesList(arg_4_0)
	local var_4_0 = arg_4_0.listContainer:getContentSize()

	arg_4_0.desList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.listContainer)
end

function var_0_0.initItemList(arg_5_0)
	local var_5_0 = arg_5_0:nodeByName("list_container")
	local var_5_1 = var_5_0:getContentSize()

	arg_5_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_5_1.width, var_5_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(var_5_0)

	table.insert(arg_5_0.scheduleinfos, {
		mode = 0
	})

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.scheduleinfos) do
		local var_5_2 = arg_5_0.list:newItem()
		local var_5_3 = arg_5_0:createModeItem(iter_5_1)
		local var_5_4 = var_5_3:getContentSize()

		var_5_2:setItemSize(var_5_4.width, var_5_4.height)
		var_5_2:addContent(var_5_3)
		arg_5_0.list:addItem(var_5_2)
	end

	arg_5_0.list:reload()
end

function var_0_0.createModeItem(arg_6_0, arg_6_1)
	local var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/mode/schedule/schedule_item.csb")
	local var_6_1 = var_6_0:getChildByName("container")
	local var_6_2 = var_6_1:getContentSize()
	local var_6_3 = var_6_1:getChildByName("bg")

	var_6_3:loadTexture("windows/arena/mode/schedule/bg_item" .. arg_6_1.mode .. ".png")

	if arg_6_1.mode > 0 then
		if xyd.ServerTime.get():getServerTime() > arg_6_1.start_time then
			var_6_3:getChildByName("ing_icon"):setVisible(true)
		end

		local var_6_4 = "%m" .. var_0_1:translation("MONTH") .. "%d" .. var_0_1:translation("DAY") .. " %H:%M"

		var_6_3:getChildByName("label_time"):setString(os.date(var_6_4, arg_6_1.start_time) .. "-\n" .. os.date(var_6_4, arg_6_1.end_time))

		local var_6_5 = cc.Node:create()
		local var_6_6 = var_6_3:getContentSize()

		var_6_5:setContentSize(var_6_6.width, var_6_6.height)
		var_6_5:addTo(var_6_3)
		var_6_5:setTouchEnabled(true)
		var_6_5:setTouchSwallowEnabled(false)
		var_6_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
			if arg_7_0.name == "began" then
				var_6_3:setScale(0.9)

				return true
			elseif arg_7_0.name == "ended" then
				var_6_3:setScale(1)
				arg_6_0:updateView(arg_6_1.mode)
			end
		end)
	else
		var_6_1:getChildByName("contact_line"):setVisible(false)

		var_6_2.width = var_6_2.width - 40

		var_6_1:setContentSize(var_6_2.width, var_6_2.height)
	end

	var_6_0:setContentSize(var_6_2.width, var_6_2.height)

	return var_6_0
end

function var_0_0.updateView(arg_8_0, arg_8_1)
	arg_8_0:nodeByName("name_txt"):loadTexture("windows/arena/mode/schedule/title" .. arg_8_1 .. ".png")

	local var_8_0 = var_0_2:desc(arg_8_1)

	if arg_8_1 == xyd.ArenaModeType.BAN then
		local var_8_1 = var_0_2:banList(arg_8_1)
		local var_8_2 = ""
		local var_8_3 = xyd.tables.hero

		for iter_8_0, iter_8_1 in ipairs(var_8_1) do
			if iter_8_1 ~= 0 then
				var_8_2 = var_8_2 .. var_8_3:name(iter_8_1) .. " "
			end
		end

		var_8_0 = string.format(var_8_0, var_8_2)
	end

	arg_8_0.desList:removeAllItems()

	local var_8_4 = arg_8_0.desList:newItem()
	local var_8_5 = display.newNode()
	local var_8_6 = xyd.AssetLoader.get():loadLabel({
		size = 24,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		x = x,
		y = y,
		color = cc.c3b(137, 49, 22),
		dimensions = cc.size(820, 0),
		text = string.gsub(var_8_0, "|", "\n")
	})
	local var_8_7 = var_8_6:getContentSize()

	var_8_5:setContentSize(var_8_7.width, var_8_7.height)
	var_8_6:addTo(var_8_5)
	var_8_6:setAnchorPoint(cc.p(0, 0))
	var_8_4:setItemSize(var_8_7.width, var_8_7.height)
	var_8_4:addContent(var_8_5)
	arg_8_0.desList:addItem(var_8_4)
	arg_8_0.desList:reload()
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	arg_9_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
