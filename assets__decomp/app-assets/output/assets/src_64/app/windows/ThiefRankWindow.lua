local var_0_0 = class("ThiefRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	xyd.ModelManager.get():loadModel(xyd.ModelType.NIAN_BOSS):getThiefRank(function(arg_3_0, arg_3_1)
		arg_2_0.rankList = arg_3_1.boss_rank.infos

		arg_2_0:layout()
	end)
end

function var_0_0.layout(arg_4_0)
	arg_4_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, 780, 480),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_4_0:nodeByName("rank_list_container")):align(display.BOTTOM_CENTER, 0, 0):setTouchType(true):pos(0, 0)

	arg_4_0:nodeByName("rank_title"):setString(var_0_2:translation("THIEF_RANK_TITLE"))
	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.thiefRankDelegate))
	arg_4_0.list:reload()
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	arg_5_0:addBlockLayer()
end

function var_0_0.thiefRankDelegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0
	local var_6_1 = 0
	local var_6_2 = arg_6_0.list

	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return #arg_6_0.rankList
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_3 = var_6_2:dequeueItem()

		if not var_6_3 then
			var_6_3 = var_6_2:newItem()
		else
			var_6_3:removeAllChildren(true)
		end

		local var_6_4
		local var_6_5 = import("app.windows.ThiefRankItem").new(arg_6_0.rankList[arg_6_3], arg_6_3)
		local var_6_6 = {}

		var_6_5:setPosition(0, (var_6_1 - arg_6_3) * 121)

		local var_6_7 = var_6_5:getContentSize()

		var_6_3:addContent(var_6_5)
		var_6_3:setItemSize(var_6_7.width + 2, var_6_7.height + 7)

		return var_6_3
	end
end

return var_0_0
