local var_0_0 = class("MonsterTipsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.giftContainer = arg_2_0:nodeByName("gift_container")

	local var_2_0 = arg_2_1.des
	local var_2_1 = arg_2_1.monsterName

	arg_2_0.items = arg_2_1.itemTable

	if #arg_2_0.items == 1 and arg_2_0.items[1] == 0 then
		arg_2_0.items = {}
	end

	arg_2_0:nodeByName("des"):setString(var_2_0)
	arg_2_0:nodeByName("name"):setString(var_2_1)
	arg_2_0:nodeByName("maybe"):setString(var_0_1:translation("CAN_GET_REWARD"))

	arg_2_0.listView_ = cc.ui.UIListView.new({
		touchOnContent = true,
		async = true,
		viewRect = cc.rect(0, 0, arg_2_0.giftContainer:getWidth(), arg_2_0.giftContainer:getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_2_0.giftContainer):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.listView_:setTouchSwallowEnabled(true)
	arg_2_0.listView_:setDelegate(handler(arg_2_0, arg_2_0.delegate))
	arg_2_0.listView_:reload()
end

function var_0_0.delegate(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	if cc.ui.UIListView.COUNT_TAG == arg_3_2 then
		return #arg_3_0.items
	elseif cc.ui.UIListView.CELL_TAG == arg_3_2 then
		if arg_3_3 > #arg_3_0.items then
			return nil
		end

		local var_3_0 = arg_3_0.listView_:dequeueItem()

		if not var_3_0 then
			var_3_0 = arg_3_0.listView_:newItem()
		else
			var_3_0:removeAllChildren(true)
		end

		local var_3_1 = arg_3_0.items[arg_3_3]
		local var_3_2 = display.newNode()
		local var_3_3, var_3_4 = arg_3_0:initCell(var_3_2, var_3_1, arg_3_3)
		local var_3_5 = display.newNode()

		var_3_5:addChild(var_3_2)
		var_3_5:setContentSize(var_3_3, var_3_4)
		var_3_0:setItemSize(var_3_3, var_3_4)
		var_3_0:addContent(var_3_5)

		return var_3_0
	end
end

function var_0_0.initCell(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = arg_4_0.giftContainer:getContentSize().height
	local var_4_1 = var_4_0 / 4
	local var_4_2 = display.newNode()

	var_4_2:setContentSize(var_4_0, var_4_0)
	var_4_2:setTouchEnabled(true)
	var_4_2:setTouchSwallowEnabled(false)
	var_4_2:setAnchorPoint(cc.p(0, 0))
	var_4_2:setPosition(0, 0)

	if xyd.tables.item:type(arg_4_2) == -1 then
		xyd.setAvatarBorder(arg_4_2, var_4_2, 1, xyd.tables.hero:initialStar(arg_4_2))
	else
		xyd.setItemBorder(var_4_2, arg_4_2, false, false, 1)
	end

	local var_4_3 = {
		id = arg_4_2,
		lev = xyd.tables.item:level(arg_4_2)
	}

	if xyd.tables.item:type(arg_4_2) == -1 then
		var_4_3.tipsType = 0
		var_4_3.desc1 = xyd.tables.hero:getDes(arg_4_2)
	elseif specialItem then
		var_4_3.tipsType = 1
		var_4_3.id = -3
	else
		var_4_3.tipsType = 1
		var_4_3.desc1 = xyd.tables.item:desc1(arg_4_2)
		var_4_3.desc2 = xyd.tables.item:desc2(arg_4_2)
	end

	var_4_3.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(arg_4_2)
	var_4_3.name = xyd.tables.item:name(arg_4_2)

	arg_4_0:addTips(var_4_2, var_4_3)
	arg_4_1:setContentSize(var_4_0 + var_4_1, var_4_0)
	arg_4_1:addChild(var_4_2)
	arg_4_1:setTouchSwallowEnabled(false)
	arg_4_1:setTouchEnabled(true)

	return var_4_0 + var_4_1, var_4_0
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.startClick_ = true
		arg_5_0.prevX_ = arg_5_1.x
	elseif arg_5_1.name == "moved" and 20 <= math.abs(arg_5_1.x - arg_5_0.prevX_) then
		arg_5_0.startClick_ = false

		xyd.WindowManager.get():closeWindow("new_item_tips")
	end
end

function var_0_0.didOpen(arg_6_0)
	arg_6_0:addBlockLayer()
end

function var_0_0.rewardFormat(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1:getContentSize().height
	local var_7_1 = var_7_0 / 4
	local var_7_2 = arg_7_2

	if #var_7_2 == 1 and var_7_2[1] == 0 then
		var_7_2 = {}
	end

	local var_7_3 = {}

	for iter_7_0 = 1, #var_7_2 do
		var_7_3[iter_7_0] = 1
	end

	local var_7_4 = #var_7_2

	for iter_7_1 = 1, #var_7_2 do
		local var_7_5 = display.newNode()

		var_7_5:setContentSize(var_7_0, var_7_0)

		if xyd.tables.item:type(var_7_2[iter_7_1]) == -1 then
			xyd.setAvatarBorder(var_7_2[iter_7_1], var_7_5, 1, xyd.tables.hero:initialStar(var_7_2[iter_7_1]), activity)
		else
			xyd.setItemBorder(var_7_5, var_7_2[iter_7_1], false, false, var_7_3[iter_7_1])
		end

		var_7_5:addTo(arg_7_1)
		var_7_5:setAnchorPoint(cc.p(0, 0))
		var_7_5:setPosition((iter_7_1 - 1) * (var_7_0 + var_7_1), 0)

		local var_7_6 = {
			id = var_7_2[iter_7_1],
			lev = xyd.tables.item:level(var_7_2[iter_7_1])
		}

		if xyd.tables.item:type(var_7_2[iter_7_1]) == -1 then
			var_7_6.tipsType = 0
			var_7_6.desc1 = xyd.tables.hero:getDes(var_7_2[iter_7_1])
		elseif specialItem then
			var_7_6.tipsType = 1
			var_7_6.id = -3
		else
			var_7_6.tipsType = 1
			var_7_6.desc1 = xyd.tables.item:desc1(var_7_2[iter_7_1])
			var_7_6.desc2 = xyd.tables.item:desc2(var_7_2[iter_7_1])
		end

		var_7_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_7_2[iter_7_1])
		var_7_6.name = xyd.tables.item:name(var_7_2[iter_7_1])

		arg_7_0:addTips(var_7_5, var_7_6)
	end

	return arg_7_1
end

function var_0_0.didClose(arg_8_0)
	xyd.WindowManager.get():closeWindow("new_item_tips")
end

return var_0_0
