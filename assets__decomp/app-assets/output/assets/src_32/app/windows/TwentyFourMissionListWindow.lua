local var_0_0 = class("TwentyFourMissionListWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityTwentyFourMission
local var_0_3 = xyd.tables.misc:getValue("activity_twenty_four_mission_id")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("title"):setString(var_0_1:translation("ACTIVITY_TWENTY_FOUR_TEXT_2"))

	arg_3_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_3_0:nodeByName("list"):getWidth(), arg_3_0:nodeByName("list"):getHeight()),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("list"))

	arg_3_0.list:setBounceable(true)
	arg_3_0.list:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.list:reload()
end

function var_0_0.delegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return var_0_3
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		if arg_4_3 > var_0_3 then
			return
		end

		local var_4_0 = arg_4_0.list:dequeueItem()

		if not var_4_0 then
			var_4_0 = arg_4_0.list:newItem()
		else
			var_4_0:removeAllChildren(true)
		end

		local var_4_1 = display.newNode()

		arg_4_0:initCell(var_4_1, arg_4_3)

		local var_4_2 = display.newNode()

		var_4_2:addChild(var_4_1)
		var_4_2:setContentSize(var_4_1:getContentSize())
		var_4_0:setItemSize(var_4_1:getContentSize().width, var_4_1:getContentSize().height)
		var_4_0:addContent(var_4_2)

		return var_4_0
	end
end

function var_0_0.initCell(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1179/mission_item.csb")
	local var_5_1 = var_5_0:getChildByName("container")

	var_5_1:getChildByName("name"):setString(var_0_1:translation("MISSION") .. arg_5_2)
	var_5_1:getChildByName("mission_desc"):setString(string.format(var_0_2:content(arg_5_2), var_0_2:num(arg_5_2)))
	var_5_1:getChildByName("award"):setString(var_0_1:translation("REWARD") .. ":")

	local var_5_2 = var_5_1:getChildByName("award_container")
	local var_5_3 = var_0_2:giftCode(arg_5_2)
	local var_5_4 = xyd.tables.gift:items(var_5_3)
	local var_5_5 = xyd.tables.gift:itemNum(var_5_3)
	local var_5_6 = var_5_2:getContentSize().height
	local var_5_7 = var_5_6 / 4

	for iter_5_0 = 1, #var_5_4 do
		local var_5_8 = display.newNode()

		var_5_8:setContentSize(var_5_6, var_5_6)
		xyd.setItemAndAddTips(var_5_8, var_5_4[iter_5_0], var_5_5[iter_5_0])
		var_5_8:addTo(var_5_2)
		var_5_8:setAnchorPoint(cc.p(0, 0))
		var_5_8:setPosition((iter_5_0 - 1) * (var_5_6 + var_5_7), 0)
	end

	if arg_5_2 == var_0_3 then
		local var_5_9 = display.newNode()

		var_5_9:setContentSize(var_5_6, var_5_6)
		xyd.setItemAndAddTips(var_5_9, var_5_3)
		var_5_9:addTo(var_5_2)
		var_5_9:setAnchorPoint(cc.p(0, 0))
		var_5_9:setPosition(0, 0)
	end

	arg_5_1:setContentSize(var_5_1:getContentSize())
	arg_5_1:addChild(var_5_0)
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
	arg_6_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
