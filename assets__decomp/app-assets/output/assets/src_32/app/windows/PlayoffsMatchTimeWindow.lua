local var_0_0 = class("PlayoffsMatchTimeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.playoffTimeTable = xyd.tables.playoffTimeTable
	arg_1_0.PlayoffsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYOFFS)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	return
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text1"):setString(var_0_1:translation("PLAYOFFS_TEXT_1"))
	arg_4_0:nodeByName("text2"):setString(var_0_1:translation("PLAYOFFS_TEXT_2"))
	arg_4_0:nodeByName("text3"):setString(var_0_1:translation("PLAYOFFS_TEXT_3"))
	arg_4_0:nodeByName("match_date_text"):setString(string.format(var_0_1:translation("PLAYOFFS_MATCH_DATE"), arg_4_0.playoffTimeTable:year(2), arg_4_0.playoffTimeTable:month(2), arg_4_0.playoffTimeTable:day(2)))

	arg_4_0.matchTimeList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_4_0:nodeByName("match_time_list"):getContentSize().width, arg_4_0:nodeByName("match_time_list"):getContentSize().height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("match_time_list")):align(display.BOTTOM_CENTER, 0, 0):setTouchType(true):pos(0, 0)

	arg_4_0.matchTimeList:setDelegate(handler(arg_4_0, arg_4_0.matchTimeListDelegate))
	arg_4_0.matchTimeList:reload()
	arg_4_0:nodeByName("text_cancel"):setString(var_0_1:translation("CANCEL"))
	arg_4_0:nodeByName("cancel_button"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("text_confirm"):setString(var_0_1:translation("OK"))
	arg_4_0:nodeByName("confirm_button"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = {}

			xyd.Backend.get():request(xyd.mid.PLAYOFFS_SIGN_UP, var_6_0, function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("PLAYOFFS_APPLY_SUCCESS")
					})

					arg_4_0.PlayoffsModel.player_info.is_signed = 1

					if xyd.WindowManager.get():getWindow("playoffs_schedule") then
						xyd.WindowManager.get():getWindow("playoffs_schedule"):updateListData()
						xyd.WindowManager.get():getWindow("playoffs_schedule"):updateList()
					end

					xyd.WindowManager.get():closeWindow(arg_4_0)
				end
			end)
		end
	end)
end

function var_0_0.matchTimeListDelegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0
	local var_8_1 = 0
	local var_8_2 = arg_8_0.matchTimeList

	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return 5
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_3 = var_8_2:dequeueItem()

		if not var_8_3 then
			var_8_3 = var_8_2:newItem()
		else
			var_8_3:removeAllChildren(true)
		end

		local var_8_4
		local var_8_5 = import("app.windows.PlayoffsMatchTimeItem").new(arg_8_3)

		var_8_5:setPosition(0, (var_8_1 - arg_8_3) * 80)

		local var_8_6 = var_8_5:getContentSize()

		var_8_3:addContent(var_8_5)
		var_8_3:setItemSize(var_8_6.width + 5, var_8_6.height + 7)

		return var_8_3
	end
end

return var_0_0
