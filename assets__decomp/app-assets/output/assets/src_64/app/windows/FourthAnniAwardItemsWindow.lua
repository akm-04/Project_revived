local var_0_0 = class("FourthAnniAwardItemsWindow", import("app.common.ui.BaseWindow"))

var_0_0.TEXT_TITLE = "text_tittle"
var_0_0.TEXT_TOP = "text_top"

local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.items = arg_1_2.items
	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0)
	arg_2_0:layout()

	local var_2_0 = arg_2_0:nodeByName(var_0_0.TEXT_TITLE)
	local var_2_1 = arg_2_0:nodeByName(var_0_0.TEXT_TOP)

	var_2_0:setString(var_0_1:translation("FOURTH_AWARD_ITEM_SHOW"))
	var_2_1:setString(var_0_1:translation("FOURTH_AWARD_ITEM_TIPS"))
end

function var_0_0.didOpen(arg_3_0)
	var_0_0.super.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.willClose(arg_4_0)
	var_0_0.super.willClose(arg_4_0)
end

function var_0_0.didClose(arg_5_0)
	var_0_0.super.didClose(arg_5_0)
end

function var_0_0.layout(arg_6_0)
	local var_6_0 = arg_6_0:nodeByName("container")

	arg_6_0.touchList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_6_0:getWidth(), var_6_0:getHeight()),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_VCENTER
	}):addTo(var_6_0):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.touchList_:align(display.LEFT_BOTTOM, 0, 0)
	arg_6_0.touchList_:setDelegate(handler(arg_6_0, arg_6_0.delegate))
	arg_6_0.touchList_:reload()
	arg_6_0:nodeByName("close_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_6_0:nodeByName("close_btn"), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow(arg_6_0)
		end
	end)
	arg_6_0:nodeByName("close"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_6_0:nodeByName("close"), arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow(arg_6_0)
		end
	end)
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevX_ = arg_9_1.x
	elseif arg_9_1.name == "moved" and 20 <= math.abs(arg_9_1.x - arg_9_0.prevX_) then
		arg_9_0.scrollViewMoved_ = true
	end
end

function var_0_0.delegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return #arg_10_0.items
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_0
		local var_10_1
		local var_10_2 = arg_10_0.touchList_:dequeueItem()

		if not var_10_2 then
			var_10_2 = arg_10_0.touchList_:newItem()
		else
			var_10_2:removeAllChildren()
		end

		local var_10_3 = arg_10_0:nodeByName("container")
		local var_10_4 = display.newNode()

		var_10_4:setTouchSwallowEnabled(false)

		if var_10_3:getHeight() >= 100 then
			var_10_4:size(100, 100)
		else
			var_10_4:size(var_10_3:getHeight(), var_10_3:getHeight())
		end

		xyd.setItemBorder(var_10_4, arg_10_0.items[arg_10_3].item_id)
		var_10_4:align(display.LEFT_BOTTOM, 0, 0)
		var_10_2:setItemSize(var_10_4:getWidth() + 50, var_10_4:getHeight())
		var_10_4:setPosition(cc.p(0, 0))
		var_10_2:addContent(var_10_4)

		local var_10_5 = arg_10_0.items[arg_10_3].item_num
		local var_10_6 = {
			size = 22,
			y = 5,
			text = tostring(var_10_5),
			color = cc.c3b(255, 255, 255),
			align = cc.ui.TEXT_ALIGN_CENTER,
			valign = cc.ui.TEXT_VALIGN_TOP,
			x = var_10_4:getWidth() - 10
		}

		if var_10_5 > 1 then
			local var_10_7 = xyd.AssetLoader.get():loadLabel(var_10_6)

			var_10_7:addTo(var_10_4)
			var_10_7:setAnchorPoint(1, 0)
			var_10_7:enableOutline(cc.c4b(0, 0, 0, 255), 2)
		end

		local var_10_8 = {
			id = arg_10_0.items[arg_10_3].item_id
		}

		xyd.addTips(var_10_4, var_10_8)

		return var_10_2
	end
end

return var_0_0
