local var_0_0 = class("IncubusMoreWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.incubusTable
local var_0_3 = 5
local var_0_4 = 120

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.ids = arg_1_2.ids
	arg_1_0.incubus = xyd.ModelManager.get():loadModel(xyd.ModelType.INCUBUS)
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 60 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)

	local var_3_0 = arg_3_0:nodeByName("listview")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.width = var_3_1.width
	arg_3_0.listView_ = cc.ui.UIListView.new({
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_0):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.listView_:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.listView_:setBounceable(true)
	arg_3_0.listView_:reload()
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("tip_txt"):setString(var_0_1:translation("INCUBUS_MORE_TITLE"))
	arg_4_0:nodeByName("close"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			audio.playSound(xyd.tables.sound:getSound("ui_close_window"), false)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
	arg_6_0:addBlockLayer()
end

function var_0_0.delegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return math.ceil(#arg_7_0.ids / var_0_3)
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_0
		local var_7_1 = arg_7_0.listView_:dequeueItem()

		if not var_7_1 then
			var_7_1 = arg_7_0.listView_:newItem()
		else
			var_7_1:removeAllChildren(true)
		end

		if arg_7_3 then
			local var_7_2 = cc.Node:create()

			for iter_7_0 = 1, var_0_3 do
				local var_7_3 = (arg_7_3 - 1) * var_0_3 + iter_7_0

				if var_7_3 > #arg_7_0.ids then
					break
				end

				local var_7_4 = cc.Node:create()

				var_7_4:setAnchorPoint(cc.p(0.5, 0.5))
				var_7_4:setContentSize(var_0_4, var_0_4)
				var_7_4:setPosition((iter_7_0 - 3) * 125, 0)
				var_7_2:addChild(var_7_4)
				arg_7_0:setBorder(var_7_3, var_7_4)
			end

			var_7_1:setItemSize(arg_7_0.width, var_0_4 + 30)
			var_7_1:addContent(var_7_2)
		end

		return var_7_1
	end
end

function var_0_0.setBorder(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = var_0_2:hero(arg_8_0.ids[arg_8_1])

	xyd.setItemBorder(arg_8_2, var_8_0)
	arg_8_2:setTouchEnabled(true)
	arg_8_2:setTouchSwallowEnabled(false)
	arg_8_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			arg_8_2:setScale(0.9)

			return true
		elseif arg_9_0.name == "moved" then
			if arg_8_0.scrollViewMoved_ then
				arg_8_2:setScale(1)
			end
		elseif arg_9_0.name == "ended" then
			if arg_8_0.scrollViewMoved_ then
				return
			end

			arg_8_2:setScale(1)

			if arg_8_0.incubus.times < 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("TRIAL_NO_TIMES_LEFT")
				})

				return
			end

			xyd.WindowManager.get():openWindow("incubus_detail", {
				id = arg_8_0.ids[arg_8_1]
			})
			xyd.WindowManager.get():closeWindow(arg_8_0)
		end
	end)
end

return var_0_0
