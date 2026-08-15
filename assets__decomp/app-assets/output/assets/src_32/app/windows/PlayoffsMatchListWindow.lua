local var_0_0 = class("PlayoffsMatchListWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = xyd.tables.playoffTimeTable

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.match_list = arg_1_2
	arg_1_0.isall = arg_1_0.match_list.is_all
	arg_1_0.playoffsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYOFFS)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	return
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:layout()

	if xyd.WindowManager.get():getWindow("playoffs_player_info") then
		xyd.WindowManager.get():closeWindow("playoffs_player_info")
	end
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0.playoffsModel.playoff_info.stage + 1

	if var_4_0 > 7 then
		var_4_0 = 7
	end

	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("REGION_ARENA_TEXT_17"))
	arg_4_0:nodeByName("date"):setString(var_0_4:year(var_4_0) .. "/" .. var_0_4:month(var_4_0) .. "/" .. var_0_4:day(var_4_0))
	arg_4_0:nodeByName("time"):setString(string.format(var_0_1:translation("PLAYOFFS_MATCH_LIST_TEXT3"), var_0_4:hour(var_4_0), var_0_4:minute(var_4_0)))

	if arg_4_0.isall then
		arg_4_0:nodeByName("title_text"):setString(var_0_1:translation("PLAYOFFS_MATCH_LIST_TEXT1"))
	else
		arg_4_0:nodeByName("title_text"):setString(var_0_1:translation("PLAYOFFS_MATCH_LIST_TEXT2"))
	end

	arg_4_0.matchList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_4_0:nodeByName("match_list"):getContentSize().width, arg_4_0:nodeByName("match_list"):getContentSize().height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("match_list")):align(display.BOTTOM_CENTER, 0, 0):setTouchType(true):pos(0, 0)

	arg_4_0.matchList:setDelegate(handler(arg_4_0, arg_4_0.matchListDelegate))
	arg_4_0.matchList:reload()
end

function var_0_0.matchListDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0
	local var_5_1 = 0
	local var_5_2 = arg_5_0.matchList

	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #arg_5_0.match_list.fight_list
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_3 = var_5_2:dequeueItem()

		if not var_5_3 then
			var_5_3 = var_5_2:newItem()
		else
			var_5_3:removeAllChildren(true)
		end

		local var_5_4
		local var_5_5 = import("app.windows.PlayoffsMatchListItem").new(arg_5_0.match_list.fight_list[arg_5_3])
		local var_5_6 = {}

		var_5_5:setPosition(0, (var_5_1 - arg_5_3) * 150 + 34)

		local var_5_7 = var_5_5:getContentSize()

		var_5_3:addContent(var_5_5)
		var_5_3:setItemSize(var_5_7.width + 5, var_5_7.height + 7)

		return var_5_3
	end
end

return var_0_0
