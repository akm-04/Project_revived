local var_0_0 = class("SelectPersonHideWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 4
local var_0_3 = var_0_1:translation("PERSON_HIDE")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.personDisplay = xyd.ModelManager.get():loadModel(xyd.ModelType.PERSON_DISPLAY)
	arg_1_0.selectHide = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0 = arg_2_0:nodeByName("list"):getContentSize()

	arg_2_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_0.width, var_2_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_2_0:nodeByName("list"))

	arg_2_0.list:setDelegate(handler(arg_2_0, arg_2_0.delegate))

	arg_2_0.hideTypes = arg_2_0.personDisplay:getHideTypes()
	arg_2_0.selectHide = clone(arg_2_0.hideTypes)

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0.list:reload()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_name"):setString(var_0_3)

	local var_4_0 = import("app.common.ui.SplitLine").new({
		size = 400
	})

	var_4_0:addTo(arg_4_0:nodeByName("container"))
	var_4_0:setAnchorPoint(0.5, 0.5)
	var_4_0:setPosition(arg_4_0:nodeByName("icon_bar"):getPosition())
	arg_4_0:initButtonEvent()
end

function var_0_0.initButtonEvent(arg_5_0)
	arg_5_0:nodeByName("btn_ok"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			arg_5_0:nodeByName("btn_ok"):setScale(0.9)
		end

		if arg_6_1 == ccui.TouchEventType.ended then
			arg_5_0:nodeByName("btn_ok"):setScale(1)

			local var_6_0 = arg_5_0.selectHide

			arg_5_0.personDisplay:hideSubType(var_6_0, function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("PERSON_HIDE_SUCCESS")
					})
					xyd.WindowManager.get():closeWindow(arg_5_0)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("PERSON_HIDE_ERROR")
					})
				end
			end)
		end

		if arg_6_1 == ccui.TouchEventType.moved then
			arg_5_0:nodeByName("btn_ok"):setScale(1)
		end
	end)
	arg_5_0:nodeByName("btn_cancel"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			arg_5_0:nodeByName("btn_cancel"):setScale(0.9)
		end

		if arg_8_1 == ccui.TouchEventType.ended then
			arg_5_0:nodeByName("btn_cancel"):setScale(1)
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end

		if arg_8_1 == ccui.TouchEventType.moved then
			arg_5_0:nodeByName("btn_cancel"):setScale(1)
		end
	end)
end

function var_0_0.delegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = var_0_2

	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return var_9_0
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_1
		local var_9_2
		local var_9_3
		local var_9_4 = arg_9_0.list:dequeueItem()

		if not var_9_4 then
			var_9_4 = arg_9_0.list:newItem()
		else
			var_9_4:removeAllChildren()
		end

		local var_9_5 = display.newNode()

		var_9_5:setTouchSwallowEnabled(false)

		local var_9_6 = display.newNode()

		arg_9_0:initHideCell(var_9_6, arg_9_3)
		var_9_5:addChild(var_9_6)
		var_9_5:setContentSize(cc.size(arg_9_0.list.viewRect_.width, var_9_6:getContentSize().height))
		var_9_4:setItemSize(arg_9_0.list.viewRect_.width, var_9_6:getContentSize().height)
		var_9_4:addContent(var_9_5)

		return var_9_4
	end
end

function var_0_0.initHideCell(arg_10_0, arg_10_1, arg_10_2)
	if arg_10_2 == 1 or arg_10_2 == 3 then
		return
	end

	local var_10_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/person_main/select_hide_item.csb")
	local var_10_1 = var_10_0:getChildByName("container")
	local var_10_2 = var_10_1:getContentSize()

	arg_10_1:setContentSize(var_10_2.width, var_10_2.height)
	var_10_0:addTo(arg_10_1)
	var_10_0:setPosition(cc.p(20, 0))
	var_10_1:getChildByName("txt_tips"):setString(var_0_1:translation("PERSON_HIDE_TIPS_" .. arg_10_2))

	local var_10_3 = var_10_1:getChildByName("img_select_box")

	if arg_10_0:checkIsHide(arg_10_2) then
		var_10_3:getChildByName("img_check"):setVisible(true)
	else
		var_10_3:getChildByName("img_check"):setVisible(false)
	end

	var_10_3:setTouchEnabled(true)
	var_10_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			return true
		elseif arg_11_0.name == "ended" then
			if arg_10_0:checkIsHide(arg_10_2) then
				arg_10_0:removeSelect(arg_10_2)
				var_10_3:getChildByName("img_check"):setVisible(false)
			else
				arg_10_0:addSelect(arg_10_2)
				var_10_3:getChildByName("img_check"):setVisible(true)
			end
		end
	end)
end

function var_0_0.checkIsHide(arg_12_0, arg_12_1)
	for iter_12_0 = 1, #arg_12_0.selectHide do
		if arg_12_0.selectHide[iter_12_0] == arg_12_1 then
			return true
		end
	end

	return false
end

function var_0_0.removeSelect(arg_13_0, arg_13_1)
	for iter_13_0 = 1, #arg_13_0.selectHide do
		if arg_13_0.selectHide[iter_13_0] == arg_13_1 then
			table.remove(arg_13_0.selectHide, iter_13_0)

			break
		end
	end
end

function var_0_0.addSelect(arg_14_0, arg_14_1)
	table.insert(arg_14_0.selectHide, arg_14_1)
end

return var_0_0
