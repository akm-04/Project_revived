local var_0_0 = class("NewDateGiftsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.details = arg_1_2.details
	arg_1_0.ids = xyd.tables.activityWeekNew:ids()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("list")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 5, var_3_1.width, var_3_1.height - 5),
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
end

function var_0_0.delegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #arg_4_0.ids
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0 = arg_4_0.scrollList:dequeueItem()

		if not var_4_0 then
			var_4_0 = arg_4_0.scrollList:newItem()
		else
			var_4_0:removeAllChildren(true)
		end

		local var_4_1 = arg_4_0:createAwardItem(arg_4_3)
		local var_4_2 = var_4_1:getWidth()
		local var_4_3 = var_4_1:getHeight()

		var_4_0:setItemSize(var_4_2, var_4_3)
		var_4_0:addContent(var_4_1)

		return var_4_0
	end
end

function var_0_0.calculateIdByIdx(arg_5_0, arg_5_1)
	local var_5_0 = #arg_5_0.awardStatus - 1

	return (arg_5_1 + 1 - 2 + arg_5_0:getRotationBias()) % var_5_0 + 2
end

function var_0_0.getRotationBias(arg_6_0)
	local var_6_0 = 0

	for iter_6_0 = 2, #arg_6_0.awardStatus do
		if arg_6_0.awardStatus[iter_6_0] == -1 then
			var_6_0 = var_6_0 + 1
		else
			break
		end
	end

	return var_6_0
end

function var_0_0.createAwardItem(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_0.ids[arg_7_1]
	local var_7_1 = display.newNode()
	local var_7_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1107/gift_list_item.csb")
	local var_7_3 = var_7_2:getChildByName("container")
	local var_7_4 = var_7_0 .. var_0_1:translation("UNIT_DAY")

	var_7_3:getChildByName("text_day"):setString(var_7_4)

	local var_7_5 = var_7_3:getChildByName("item_list")
	local var_7_6 = xyd.tables.activityWeekNew:gift(var_7_0)

	arg_7_0:rewardFormat(var_7_5, var_7_6, arg_7_1)
	var_7_2:addTo(var_7_1)
	var_7_2:setAnchorPoint(cc.p(0, 0))
	var_7_1:setContentSize(var_7_3:getContentSize())
	var_7_2:setName("source")

	return var_7_1
end

function var_0_0.rewardFormat(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = arg_8_1:getContentSize().height
	local var_8_1 = 2.5
	local var_8_2 = clone(xyd.tables.gift:items(arg_8_2))

	if #var_8_2 == 1 and var_8_2[1] == 0 then
		var_8_2 = {}
	end

	if (not var_8_2 or not next(var_8_2)) and arg_8_3 == 7 then
		table.insert(var_8_2, arg_8_0.details.hero_id)
	end

	local var_8_3 = xyd.tables.gift:itemNum(arg_8_2)
	local var_8_4 = #var_8_2

	for iter_8_0 = 1, #var_8_2 do
		local var_8_5 = display.newNode()

		var_8_5:setContentSize(var_8_0, var_8_0)

		if xyd.tables.item:type(var_8_2[iter_8_0]) == -1 then
			xyd.setAvatarBorder(var_8_2[iter_8_0], var_8_5, 1, xyd.tables.hero:initialStar(var_8_2[iter_8_0]))
		else
			xyd.setItemBorder(var_8_5, var_8_2[iter_8_0], false, false, var_8_3[iter_8_0])
		end

		var_8_5:addTo(arg_8_1)
		var_8_5:setAnchorPoint(cc.p(0, 0))
		var_8_5:setPosition((iter_8_0 - 1) * (var_8_0 + var_8_1), 0)

		local var_8_6 = {
			id = var_8_2[iter_8_0],
			lev = xyd.tables.item:level(var_8_2[iter_8_0])
		}

		if xyd.tables.item:type(var_8_2[iter_8_0]) == -1 then
			var_8_6.tipsType = 0
			var_8_6.desc1 = xyd.tables.hero:getDes(var_8_2[iter_8_0])
		elseif specialItem then
			var_8_6.tipsType = 1
			var_8_6.id = -3
		else
			var_8_6.tipsType = 1
			var_8_6.desc1 = xyd.tables.item:desc1(var_8_2[iter_8_0])
			var_8_6.desc2 = xyd.tables.item:desc2(var_8_2[iter_8_0])
		end

		var_8_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_8_2[iter_8_0])
		var_8_6.name = xyd.tables.item:name(var_8_2[iter_8_0])

		arg_8_0:addTips(var_8_5, var_8_6)
	end

	local var_8_7 = xyd.tables.gift:crystal(arg_8_2)

	if var_8_7 and var_8_7 > 0 then
		local var_8_8 = display.newNode()

		var_8_8:setContentSize(var_8_0, var_8_0)
		xyd.setItemBorder(var_8_8, -1, false, false, var_8_7)
		var_8_8:addTo(arg_8_1)
		var_8_8:setAnchorPoint(cc.p(0, 0))
		var_8_8:setPosition(var_8_4 * (var_8_0 + var_8_1), 0)

		local var_8_9 = {}

		var_8_9.id = -1
		var_8_9.tipsType = 1

		arg_8_0:addTips(var_8_8, var_8_9)

		var_8_4 = var_8_4 + 1
	end

	local var_8_10 = xyd.tables.gift:mana(arg_8_2)

	if var_8_10 and var_8_10 > 0 then
		local var_8_11 = display.newNode()

		var_8_11:setContentSize(var_8_0, var_8_0)
		xyd.setItemBorder(var_8_11, -2, false, false, var_8_10)
		var_8_11:addTo(arg_8_1)
		var_8_11:setAnchorPoint(cc.p(0, 0))
		var_8_11:setPosition(var_8_4 * (var_8_0 + var_8_1), 0)

		local var_8_12 = {}

		var_8_12.id = -2
		var_8_12.tipsType = 1

		arg_8_0:addTips(var_8_11, var_8_12)

		local var_8_13 = var_8_4 + 1
	end

	return arg_8_1
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevY_ = arg_9_1.y
	elseif arg_9_1.name == "moved" and 10 <= math.abs(arg_9_1.y - arg_9_0.prevY_) then
		arg_9_0.scrollViewMoved_ = true
	end
end

return var_0_0
