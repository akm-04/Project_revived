local var_0_0 = class("NewDateGiftsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.details = arg_1_2.details
	arg_1_0.ids = xyd.tables.activityWeekNew2:ids()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_title"):enableOutline(cc.c4b(227, 83, 165, 255), 2)
	arg_3_0:nodeByName("txt_ok"):setString(var_0_1:translation("SURE"))
	arg_3_0:nodeByName("txt_title"):setString(var_0_1:translation("ACTIVITY_1126_TEXT10"))

	local var_3_0 = arg_3_0:nodeByName("list")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_0):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.scrollList:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.scrollList:reload()
	arg_3_0:nodeByName("btn_ok"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0:close()
		end
	end)
end

function var_0_0.delegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #arg_5_0.ids
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0 = arg_5_0.scrollList:dequeueItem()

		if not var_5_0 then
			var_5_0 = arg_5_0.scrollList:newItem()
		else
			var_5_0:removeAllChildren(true)
		end

		local var_5_1 = arg_5_0:createAwardItem(arg_5_3)
		local var_5_2 = var_5_1:getWidth()
		local var_5_3 = var_5_1:getHeight()

		var_5_0:setItemSize(var_5_2, var_5_3 + 9)
		var_5_0:addContent(var_5_1)

		return var_5_0
	end
end

function var_0_0.calculateIdByIdx(arg_6_0, arg_6_1)
	local var_6_0 = #arg_6_0.awardStatus - 1

	return (arg_6_1 + 1 - 2 + arg_6_0:getRotationBias()) % var_6_0 + 2
end

function var_0_0.getRotationBias(arg_7_0)
	local var_7_0 = 0

	for iter_7_0 = 2, #arg_7_0.awardStatus do
		if arg_7_0.awardStatus[iter_7_0] == -1 then
			var_7_0 = var_7_0 + 1
		else
			break
		end
	end

	return var_7_0
end

function var_0_0.createAwardItem(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_0.ids[arg_8_1]
	local var_8_1 = display.newNode()
	local var_8_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1126/gift_list_item.csb")
	local var_8_3 = var_8_2:getChildByName("container")
	local var_8_4 = var_8_0 .. var_0_1:translation("UNIT_DAY")

	var_8_3:getChildByName("text_day"):setString(var_8_4)
	var_8_3:getChildByName("text_day"):enableOutline(cc.c4b(233, 94, 157, 255), 2)

	local var_8_5 = var_8_3:getChildByName("item_list")
	local var_8_6 = xyd.tables.activityWeekNew2:gift(var_8_0)
	local var_8_7 = xyd.tables.activityWeekNew2:scrollNum(var_8_0)

	arg_8_0:rewardFormat(var_8_5, var_8_6, arg_8_1, var_8_7)
	var_8_2:addTo(var_8_1)
	var_8_2:setAnchorPoint(cc.p(0, 0))
	var_8_1:setContentSize(var_8_3:getContentSize())
	var_8_2:setName("source")

	return var_8_1
end

function var_0_0.rewardFormat(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4)
	local var_9_0 = arg_9_1:getContentSize().height
	local var_9_1 = 10
	local var_9_2 = clone(xyd.tables.gift:items(arg_9_2))
	local var_9_3 = clone(xyd.tables.gift:itemNum(arg_9_2))

	if arg_9_4 == -1 then
		table.insert(var_9_2, 1, arg_9_0.details.hero_id)
		table.insert(var_9_3, 1, 1)
	elseif arg_9_4 > 0 then
		table.insert(var_9_2, 1, xyd.tables.hero:stoneID(arg_9_0.details.hero_id))
		table.insert(var_9_3, 1, arg_9_4)
	end

	local var_9_4 = #var_9_2

	for iter_9_0 = 1, #var_9_2 do
		local var_9_5 = display.newNode()

		var_9_5:setContentSize(var_9_0, var_9_0)

		if xyd.tables.item:type(var_9_2[iter_9_0]) == -1 then
			xyd.setAvatarBorder(var_9_2[iter_9_0], var_9_5, 1, xyd.tables.hero:initialStar(var_9_2[iter_9_0]))
		else
			xyd.setItemBorder(var_9_5, var_9_2[iter_9_0], false, false, var_9_3[iter_9_0])
		end

		var_9_5:addTo(arg_9_1)
		var_9_5:setAnchorPoint(cc.p(0, 0))
		var_9_5:setPosition((iter_9_0 - 1) * (var_9_0 + var_9_1), 0)

		local var_9_6 = {
			id = var_9_2[iter_9_0],
			lev = xyd.tables.item:level(var_9_2[iter_9_0])
		}

		if xyd.tables.item:type(var_9_2[iter_9_0]) == -1 then
			var_9_6.tipsType = 0
			var_9_6.desc1 = xyd.tables.hero:getDes(var_9_2[iter_9_0])
		elseif specialItem then
			var_9_6.tipsType = 1
			var_9_6.id = -3
		else
			var_9_6.tipsType = 1
			var_9_6.desc1 = xyd.tables.item:desc1(var_9_2[iter_9_0])
			var_9_6.desc2 = xyd.tables.item:desc2(var_9_2[iter_9_0])
		end

		var_9_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_9_2[iter_9_0])
		var_9_6.name = xyd.tables.item:name(var_9_2[iter_9_0])

		arg_9_0:addTips(var_9_5, var_9_6)
	end

	local var_9_7 = xyd.tables.gift:crystal(arg_9_2)

	if var_9_7 and var_9_7 > 0 then
		local var_9_8 = display.newNode()

		var_9_8:setContentSize(var_9_0, var_9_0)
		xyd.setItemBorder(var_9_8, -1, false, false, var_9_7)
		var_9_8:addTo(arg_9_1)
		var_9_8:setAnchorPoint(cc.p(0, 0))
		var_9_8:setPosition(var_9_4 * (var_9_0 + var_9_1), 0)

		local var_9_9 = {}

		var_9_9.id = -1
		var_9_9.tipsType = 1

		arg_9_0:addTips(var_9_8, var_9_9)

		var_9_4 = var_9_4 + 1
	end

	local var_9_10 = xyd.tables.gift:mana(arg_9_2)

	if var_9_10 and var_9_10 > 0 then
		local var_9_11 = display.newNode()

		var_9_11:setContentSize(var_9_0, var_9_0)
		xyd.setItemBorder(var_9_11, -2, false, false, var_9_10)
		var_9_11:addTo(arg_9_1)
		var_9_11:setAnchorPoint(cc.p(0, 0))
		var_9_11:setPosition(var_9_4 * (var_9_0 + var_9_1), 0)

		local var_9_12 = {}

		var_9_12.id = -2
		var_9_12.tipsType = 1

		arg_9_0:addTips(var_9_11, var_9_12)

		local var_9_13 = var_9_4 + 1
	end

	return arg_9_1
end

function var_0_0.scrollListener(arg_10_0, arg_10_1)
	if arg_10_1.name == "began" then
		arg_10_0.scrollViewMoved_ = false
		arg_10_0.prevY_ = arg_10_1.y
	elseif arg_10_1.name == "moved" and 10 <= math.abs(arg_10_1.y - arg_10_0.prevY_) then
		arg_10_0.scrollViewMoved_ = true
	end
end

return var_0_0
