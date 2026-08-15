local var_0_0 = class("NewTermMakeAlertItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = xyd.tables.twoYearsMission
local var_0_4 = 1000
local var_0_5 = 80
local var_0_6 = xyd.tables.hero
local var_0_7 = xyd.tables.newTermMake
local var_0_8 = 60

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/new_term/make_alert_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
		arg_3_0:setContentSize(arg_3_0.contentView_:getContentSize().width, arg_3_0.contentView_:getContentSize().height)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1.material_id
	local var_4_1 = var_0_7:combination(var_4_0)

	for iter_4_0, iter_4_1 in ipairs(var_4_1) do
		local var_4_2 = display.newNode()

		var_4_2:setContentSize(var_0_5 - 30, var_0_5 - 30)
		var_4_2:setAnchorPoint(0, 0.5)
		var_4_2:setPosition((iter_4_0 - 1) * var_0_8, 0)
		xyd.setItemBorder(var_4_2, iter_4_1)
		var_4_2:addTo(arg_4_0.contentView_:nodeByName("item_detail"))
	end

	arg_4_0.contentView_:nodeByName("item_name"):setString(var_0_2:name(arg_4_1.item_id))
	arg_4_0.contentView_:nodeByName("item_icon"):setContentSize(var_0_5, var_0_5)
	arg_4_0.contentView_:nodeByName("item_icon"):setAnchorPoint(0.5, 0.5)
	xyd.setItemBorder(arg_4_0.contentView_:nodeByName("item_icon"), arg_4_1.item_id)
	arg_4_0.contentView_:nodeByName("use_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.NEW_TERM_USE_MATERIAL_RATIO,
				params = {
					id = arg_4_1.material_id
				}
			})
			xyd.WindowManager.get():closeWindow("new_term_make_alert")
		end
	end)
end

local var_0_9 = class("NewTermMakeAlertWindow", import("app.common.ui.BaseWindow"))
local var_0_10 = import("app.common.ui.SpineEffect")
local var_0_11 = xyd.tables.translation
local var_0_12 = import("framework.scheduler")

function var_0_9.ctor(arg_6_0, arg_6_1, arg_6_2)
	var_0_9.super.ctor(arg_6_0, arg_6_1, arg_6_2)

	arg_6_0.logs = arg_6_2 or {}
end

function var_0_9.willOpen(arg_7_0, arg_7_1)
	var_0_9.super.willOpen(arg_7_0, arg_7_1)
end

function var_0_9.didOpen(arg_8_0, arg_8_1)
	var_0_9.super.didOpen(arg_8_0, arg_8_1)
	arg_8_0:addBlockLayer()
	arg_8_0:layout()
end

function var_0_9.layout(arg_9_0)
	arg_9_0:initListView()
end

function var_0_9.initListView(arg_10_0)
	if not arg_10_0.listView_ then
		arg_10_0.listView_ = cc.ui.UIListView.new({
			async = true,
			touchOnContent = true,
			viewRect = cc.rect(0, 0, 780, 450),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_10_0:nodeByName("item_list"))
	else
		arg_10_0.listView_:removeAllItems()
	end

	arg_10_0.listView_:setDelegate(handler(arg_10_0, arg_10_0.delegate))
	arg_10_0.listView_:reload()
end

function var_0_9.delegate(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	if cc.ui.UIListView.COUNT_TAG == arg_11_2 then
		return #arg_11_0.logs
	elseif cc.ui.UIListView.CELL_TAG == arg_11_2 then
		local var_11_0 = arg_11_1:dequeueItem()

		if not var_11_0 then
			var_11_0 = arg_11_1:newItem()
		else
			var_11_0:removeAllChildren(true)
		end

		local var_11_1 = var_0_0.new()
		local var_11_2 = arg_11_0.logs[arg_11_3]

		var_11_1:setParams(var_11_2)
		var_11_0:addContent(var_11_1)
		var_11_0:setItemSize(var_11_1:getContentSize().width, var_11_1:getContentSize().height)

		return var_11_0
	end
end

function var_0_9.willClose(arg_12_0)
	if arg_12_0.handle then
		var_0_12.unscheduleGlobal(arg_12_0.handle)

		arg_12_0.handle = nil
	end
end

return var_0_9
