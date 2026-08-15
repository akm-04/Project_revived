local var_0_0 = class("MagicItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1110/magic_item_sale.csb"))
		arg_3_0.contentView_:addTo(arg_3_0):setAnchorPoint(0.5, 0.5)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_0.contentView_:nodeByName("num1")
	local var_4_1 = arg_4_0.contentView_:nodeByName("num2")

	var_4_0:enableOutline(cc.c4b(84, 75, 134, 255), 1)
	var_4_1:enableOutline(cc.c4b(84, 75, 134, 255), 1)
	var_4_0:setString(xyd.tables.misc.magicShopNormal[arg_4_1])
	var_4_1:setString(xyd.tables.misc.magicShopDiscount[arg_4_1])

	for iter_4_0 = 1, #xyd.tables.misc.magicShopItems[arg_4_1] do
		xyd.setItemBorder(arg_4_0.contentView_:nodeByName("item" .. iter_4_0), xyd.tables.misc.magicShopItems[arg_4_1][iter_4_0])
	end
end

local var_0_3 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_4 = xyd.tables.translation

function var_0_3.ctor(arg_5_0, arg_5_1)
	var_0_3.super.ctor(arg_5_0, arg_5_1)

	arg_5_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_3.show(arg_6_0, arg_6_1)
	var_0_3.super.show(arg_6_0, arg_6_1)

	if not arg_6_0.res or arg_6_0.res == 0 then
		print("No res available.")

		return
	end

	local var_6_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_6_0.res)

	var_6_0:addTo(arg_6_0.parent)
	var_6_0:setAnchorPoint(cc.p(0, 0))
	var_6_0:setPosition(0, 0)

	local var_6_1 = var_6_0:getChildByName("container")
	local var_6_2 = var_6_1:getChildByName("des_text")
	local var_6_3 = var_6_1:getChildByName("item_container")

	arg_6_0.listView_ = cc.ui.UIListView.new({
		touchOnContent = true,
		viewRect = cc.rect(0, 0, 580, 280),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_6_3):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.listView_:setTouchSwallowEnabled(true)

	arg_6_0.timeTxt = var_6_1:getChildByName("time_bg"):getChildByName("time_txt")

	arg_6_0.timeTxt:enableOutline(cc.c4b(255, 255, 255, 255), 2)

	local function var_6_4()
		local var_7_0 = tonumber(xyd.ServerTime.get():getServerTime())
		local var_7_1 = arg_6_0.activity.end_time - var_7_0

		if tolua.isnull(arg_6_0.timeTxt) then
			return
		end

		if var_7_1 <= 0 then
			arg_6_0.timeTxt:setString(var_0_4:translation("ACTIVITY_END"))
		end

		if var_7_0 < arg_6_0.activity.start_time then
			arg_6_0.timeTxt:setString(var_0_4:translation("ACTIVITY_NO_OPEN"))
		end

		if var_7_1 <= 0 or var_7_0 < arg_6_0.activity.start_time then
			if arg_6_0.handle then
				var_0_2.unscheduleGlobal(arg_6_0.handle)

				arg_6_0.handle = nil
			end

			return
		end

		local var_7_2 = xyd.secondsToString1(var_7_1)

		if arg_6_0.timeTxt and not tolua.isnull(arg_6_0.timeTxt) then
			arg_6_0.timeTxt:setString(var_7_2)
		end
	end

	if arg_6_0.activity.is_open == 1 then
		var_6_4()

		if not arg_6_0.handle then
			arg_6_0.handle = var_0_2.scheduleGlobal(handler(arg_6_0, var_6_4), 1)
		end
	elseif not arg_6_0.handle then
		var_0_2.unscheduleGlobal(arg_6_0.handle)

		arg_6_0.handle = nil
	end

	var_6_1:getChildByName("des_text"):setString(var_0_4:translation("ACTIVITY_PROPOSE_DESC"))
	arg_6_0:updateItems()
end

function var_0_3.updateItems(arg_8_0)
	if arg_8_0.listView_ and not tolua.isnull(arg_8_0.listView_) then
		arg_8_0.listView_:removeAllItems()
	else
		return
	end

	for iter_8_0 = 1, 4 do
		local var_8_0 = arg_8_0.listView_:newItem()
		local var_8_1 = display.newNode()
		local var_8_2 = var_0_0.new()

		var_8_2:setParams(iter_8_0)
		var_8_1:addChild(var_8_2)
		var_8_0:addContent(var_8_1)
		var_8_1:setContentSize(580, 70)
		var_8_0:setItemSize(580, 70)
		arg_8_0.listView_:addItem(var_8_0)
	end

	arg_8_0.listView_:reload()
end

function var_0_3.release(arg_9_0)
	if arg_9_0.handle then
		var_0_2.unscheduleGlobal(arg_9_0.handle)

		arg_9_0.handle = nil
	end
end

return var_0_3
