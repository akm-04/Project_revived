local var_0_0 = class("BoardTaskBonusWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.awards = arg_1_2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:nodeByName("title"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_BONUS_TITLE"))
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.bonusList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_4_0:nodeByName("bonus_list"):getContentSize().width, arg_4_0:nodeByName("bonus_list"):getContentSize().height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("bonus_list")):align(display.BOTTOM_CENTER, 0, 0):setTouchType(true):pos(0, 0)

	arg_4_0.bonusList:setDelegate(handler(arg_4_0, arg_4_0.bonusListDelegate))
	arg_4_0.bonusList:reload()
end

function var_0_0.bonusListDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0
	local var_5_1 = 0
	local var_5_2 = arg_5_0.bonusList

	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #arg_5_0.awards
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_3 = var_5_2:dequeueItem()

		if not var_5_3 then
			var_5_3 = var_5_2:newItem()
		else
			var_5_3:removeAllChildren(true)
		end

		local var_5_4
		local var_5_5 = import("app.windows.BoardTaskBonusItem").new(arg_5_0.awards[arg_5_3])
		local var_5_6 = {}

		var_5_5:setPosition(0, (var_5_1 - arg_5_3) * 150)

		local var_5_7 = var_5_5:getContentSize()

		var_5_3:addContent(var_5_5)
		var_5_3:setItemSize(var_5_7.width + 5, var_5_7.height + 7)

		return var_5_3
	end
end

return var_0_0
