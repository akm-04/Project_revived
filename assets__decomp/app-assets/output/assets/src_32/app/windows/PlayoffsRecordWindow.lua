local var_0_0 = class("PlayoffsRecordWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = xyd.tables.playoffTimeTable

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.PlayoffsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYOFFS)
	arg_1_0.params = arg_1_2.params
	arg_1_0.player_id = tonumber(arg_1_2.player_id)
	arg_1_0.onFocus = 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("text_title"):setString(var_0_1:translation("REGION_ARENA_TEXT_26"))
	arg_2_0:nodeByName("text_group"):setString(var_0_1:translation("REGION_ARENA_TEXT_27"))
	arg_2_0:nodeByName("text_eight"):setString(var_0_1:translation("REGION_ARENA_TEXT_28"))
	arg_2_0:nodeByName("text_four"):setString(var_0_1:translation("REGION_ARENA_TEXT_29"))
	arg_2_0:nodeByName("text_half"):setString(var_0_1:translation("REGION_ARENA_TEXT_30"))
	arg_2_0:nodeByName("text_final"):setString(var_0_1:translation("REGION_ARENA_TEXT_31"))
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:initRecordList()
	arg_3_0.recordList:reload()
	arg_3_0:layout()
	arg_3_0:registerListener()
end

function var_0_0.layout(arg_4_0)
	if arg_4_0.PlayoffsModel.playoff_info.stage <= 6 or not xyd.tableHaveElement(arg_4_0.PlayoffsModel.battle_status["6"], arg_4_0.player_id) then
		arg_4_0:nodeByName("final_button"):setTouchEnabled(false)
		arg_4_0:nodeByName("final_button"):setBright(false)
	end

	if arg_4_0.PlayoffsModel.playoff_info.stage <= 5 or not xyd.tableHaveElement(arg_4_0.PlayoffsModel.battle_status["5"], arg_4_0.player_id) then
		arg_4_0:nodeByName("half_button"):setTouchEnabled(false)
		arg_4_0:nodeByName("half_button"):setBright(false)
	end

	if arg_4_0.PlayoffsModel.playoff_info.stage <= 4 or not xyd.tableHaveElement(arg_4_0.PlayoffsModel.battle_status["4"], arg_4_0.player_id) then
		arg_4_0:nodeByName("four_button"):setTouchEnabled(false)
		arg_4_0:nodeByName("four_button"):setBright(false)
	end

	if arg_4_0.PlayoffsModel.playoff_info.stage <= 3 or not xyd.tableHaveElement(arg_4_0.PlayoffsModel.battle_status["3"], arg_4_0.player_id) then
		arg_4_0:nodeByName("eight_button"):setTouchEnabled(false)
		arg_4_0:nodeByName("eight_button"):setBright(false)
	end
end

function var_0_0.registerListener(arg_5_0)
	local function var_5_0(arg_6_0)
		arg_5_0.PlayoffsModel:getRecordList(arg_5_0.player_id, arg_6_0, function(arg_7_0, arg_7_1)
			if arg_7_0 == xyd.error.OK then
				arg_5_0.params = arg_7_1
				arg_5_0.onFocus = 0

				arg_5_0:reloadList()
			end
		end)
	end

	arg_5_0:nodeByName("group_button"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			var_5_0(3)
		end
	end)
	arg_5_0:nodeByName("eight_button"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			var_5_0(4)
		end
	end)
	arg_5_0:nodeByName("four_button"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			var_5_0(5)
		end
	end)
	arg_5_0:nodeByName("half_button"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			var_5_0(6)
		end
	end)
	arg_5_0:nodeByName("final_button"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			var_5_0(7)
		end
	end)
end

function var_0_0.initRecordList(arg_13_0)
	arg_13_0.recordList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_13_0:nodeByName("history_list"):getContentSize().width, arg_13_0:nodeByName("history_list"):getContentSize().height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_13_0:nodeByName("history_list")):align(display.BOTTOM_CENTER, 0, 0):setTouchType(true):pos(0, 0)

	arg_13_0.recordList:setDelegate(handler(arg_13_0, arg_13_0.recordListDelegate))
end

function var_0_0.reloadList(arg_14_0)
	local var_14_0, var_14_1 = arg_14_0.recordList.scrollNode:getPosition()

	arg_14_0.recordList:removeAllItems()
	arg_14_0.recordList:reload()

	if arg_14_0.onFocus ~= 0 then
		arg_14_0.recordList:scrollTo(var_14_0, var_14_1)
	end

	if arg_14_0.onFocus == 3 then
		arg_14_0.recordList:scrollTo(0, arg_14_0.recordList:getListEndPosAndHeight())
	end
end

function var_0_0.recordListDelegate(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	local var_15_0
	local var_15_1 = 0
	local var_15_2 = arg_15_0.recordList

	if cc.ui.UIListView.COUNT_TAG == arg_15_2 then
		return #arg_15_0.params
	elseif cc.ui.UIListView.CELL_TAG == arg_15_2 then
		local var_15_3 = var_15_2:dequeueItem()

		if not var_15_3 then
			var_15_3 = var_15_2:newItem()
		else
			var_15_3:removeAllChildren(true)
		end

		local var_15_4

		if arg_15_3 ~= arg_15_0.onFocus then
			var_15_4 = import("app.windows.PlayoffsRecordItem").new(false, arg_15_3, arg_15_0.params[arg_15_3])
		else
			var_15_4 = import("app.windows.PlayoffsRecordItem").new(true, arg_15_3, arg_15_0.params[arg_15_3])
		end

		local var_15_5 = {}

		var_15_4:setPosition(0, (var_15_1 - arg_15_3) * 150 + 34)

		local var_15_6 = var_15_4:getContentSize()

		var_15_3:addContent(var_15_4)
		var_15_3:setItemSize(var_15_6.width + 5, var_15_6.height + 5)

		return var_15_3
	end
end

return var_0_0
