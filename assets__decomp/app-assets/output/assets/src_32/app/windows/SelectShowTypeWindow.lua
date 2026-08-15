local var_0_0 = class("SelectShowTypeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 4
local var_0_3 = 4
local var_0_4 = 30
local var_0_5 = var_0_1:translation("PERSON_SELECT_SHOW_TYPE")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.personDisplay = xyd.ModelManager.get():loadModel(xyd.ModelType.PERSON_DISPLAY)
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.infos = arg_1_2.all_show_types or {}
	arg_1_0.allTypes = {}
	arg_1_0.selectTypes = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0 = arg_2_0:nodeByName("list")
	local var_2_1 = var_2_0:getContentSize()

	arg_2_0.list_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_2_0)

	arg_2_0.list_:setDelegate(handler(arg_2_0, arg_2_0.delegate))
	arg_2_0:initPreSelect()
	arg_2_0:initAllTypes()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
	arg_3_0.list_:reload()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_name"):setString(var_0_5)
	arg_4_0:nodeByName("btn_sure"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			arg_4_0:nodeByName("btn_sure"):setScale(0.9)
		end

		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0:nodeByName("btn_sure"):setScale(1)

			local var_5_0 = arg_4_0:getSelectIds()

			arg_4_0.personDisplay:modifyShowTypes(var_5_0, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					if arg_4_0.callback then
						arg_4_0.callback()
					end

					xyd.WindowManager.get():closeWindow(arg_4_0)
				end
			end)
		end

		if arg_5_1 == ccui.TouchEventType.moved then
			arg_4_0:nodeByName("btn_sure"):setScale(1)
		end
	end)
	arg_4_0:nodeByName("btn_cancel"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			arg_4_0:nodeByName("btn_cancel"):setScale(0.9)
		end

		if arg_7_1 == ccui.TouchEventType.ended then
			arg_4_0:nodeByName("btn_cancel"):setScale(1)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end

		if arg_7_1 == ccui.TouchEventType.moved then
			arg_4_0:nodeByName("btn_cancel"):setScale(1)
		end
	end)

	local var_4_0 = import("app.common.ui.SplitLine").new({
		size = 944
	})

	var_4_0:addTo(arg_4_0:nodeByName("container"))
	var_4_0:setAnchorPoint(0.5, 0.5)
	var_4_0:setPosition(arg_4_0:nodeByName("conatiner_bar"):getPosition())
end

function var_0_0.getSelectIds(arg_8_0)
	local var_8_0 = {}

	for iter_8_0 = 1, #arg_8_0.selectTypes do
		local var_8_1 = arg_8_0.selectTypes[iter_8_0]

		table.insert(var_8_0, tonumber(var_8_1))
	end

	return var_8_0
end

function var_0_0.initAllTypes(arg_9_0)
	for iter_9_0, iter_9_1 in pairs(arg_9_0.infos) do
		table.insert(arg_9_0.allTypes, tonumber(iter_9_0))
	end
end

function var_0_0.initPreSelect(arg_10_0)
	local var_10_0 = arg_10_0.personDisplay:getShowTypes()

	for iter_10_0, iter_10_1 in pairs(var_10_0) do
		arg_10_0:addToSelectType(tonumber(iter_10_0))
	end
end

function var_0_0.delegate(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	local var_11_0 = math.ceil(#arg_11_0.allTypes / var_0_2)

	if cc.ui.UIListView.COUNT_TAG == arg_11_2 then
		return var_11_0
	elseif cc.ui.UIListView.CELL_TAG == arg_11_2 then
		local var_11_1
		local var_11_2
		local var_11_3
		local var_11_4 = arg_11_0.list_:dequeueItem()

		if not var_11_4 then
			var_11_4 = arg_11_0.list_:newItem()
		else
			var_11_4:removeAllChildren()
		end

		local var_11_5 = display.newNode()

		var_11_5:setTouchSwallowEnabled(false)

		for iter_11_0 = 1, var_0_2 do
			local var_11_6 = (arg_11_3 - 1) * var_0_2 + iter_11_0

			if var_11_6 > #arg_11_0.allTypes then
				break
			end

			var_11_3 = display.newNode()

			arg_11_0:initTypeCell(var_11_3, var_11_6)

			local var_11_7 = var_11_3:getContentSize().width
			local var_11_8 = var_11_3:getContentSize().height
			local var_11_9 = (arg_11_0.list_.viewRect_.width - var_11_7 * var_0_2) / (var_0_2 + 1)

			var_11_3:align(display.CENTER, var_11_9 * iter_11_0 + (iter_11_0 - 1) * var_11_7 + var_11_7 / 2, var_11_8 / 2)
			var_11_5:addChild(var_11_3)
		end

		var_11_5:setContentSize(cc.size(arg_11_0.list_.viewRect_.width, var_11_3:getContentSize().height))
		var_11_4:setItemSize(arg_11_0.list_.viewRect_.width, var_11_3:getContentSize().height + 10)
		var_11_4:addContent(var_11_5)

		return var_11_4
	end
end

function var_0_0.initTypeCell(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_0.allTypes[arg_12_2]

	arg_12_1:align(display.CENTER):size(146, 146)

	local var_12_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/person_main/select_type_item.csb")

	var_12_1:addTo(arg_12_1)
	var_12_1:setName("layout")

	local var_12_2 = var_12_1:getChildByName("container")
	local var_12_3 = var_12_2:getContentSize()

	arg_12_1:setContentSize(var_12_3)

	arg_12_1.data = var_12_0

	arg_12_1:setTouchEnabled(true)
	arg_12_1:setTouchSwallowEnabled(false)
	arg_12_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		arg_12_0:buttonHandler(nil, arg_12_1, arg_13_0)

		if arg_13_0.name == "began" then
			arg_12_0.startClick_ = true
			arg_12_0.prevX_ = arg_13_0.x
			arg_12_0.prevY_ = arg_13_0.y
		elseif arg_13_0.name == "moved" then
			if math.abs(arg_13_0.y - arg_12_0.prevY_) > 5 or math.abs(arg_13_0.x - arg_12_0.prevX_) > 5 then
				arg_12_0.startClick_ = false
			end
		elseif arg_13_0.name == "ended" and arg_12_0.startClick_ then
			arg_12_0:clickCell(arg_12_1)
		end

		return true
	end)
	arg_12_0:initCellText(var_12_2, var_12_0)

	local var_12_4 = arg_12_0:checkTypeIsSelect(var_12_0)

	var_12_2:getChildByName("icon_check"):setLocalZOrder(10)
	var_12_2:getChildByName("icon_check"):setVisible(var_12_4)
	var_12_2:getChildByName("btn_show"):setVisible(not var_12_4)
	var_12_2:getChildByName("btn_show_select"):setVisible(var_12_4)

	if var_12_4 then
		var_12_2:getChildByName("txt_num"):setColor(cc.c4b(255, 255, 255, 255))
		var_12_2:getChildByName("txt_type"):setColor(cc.c4b(65, 74, 84, 255))
	else
		var_12_2:getChildByName("txt_num"):setColor(cc.c4b(106, 105, 119, 255))
		var_12_2:getChildByName("txt_type"):setColor(cc.c4b(152, 83, 53, 255))
	end
end

function var_0_0.initCellText(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_0.infos[tostring(arg_14_2)]
	local var_14_1 = xyd.tables.personDisplayWords:personDisplayDesc(arg_14_2)
	local var_14_2, var_14_3 = arg_14_1:getChildByName("txt_num"):getPosition()
	local var_14_4

	if arg_14_2 == xyd.PlayerCardShowType.CREATE_TIME then
		local var_14_5 = os.date("%Y/%m/%d", tonumber(var_14_0))

		arg_14_1:getChildByName("txt_num"):setString(var_14_5)
		arg_14_1:getChildByName("txt_num"):setPosition(var_14_2 - 10, var_14_3)
	else
		local var_14_6 = var_14_0

		arg_14_1:getChildByName("txt_num"):setString(var_14_6)
	end

	arg_14_1:getChildByName("txt_type"):setString(var_14_1)
	arg_14_1:getChildByName("txt_num"):setLocalZOrder(5)

	local var_14_7 = xyd.AssetLoader.get():loadSprite("windows/person_display/person_main/icon_" .. arg_14_2 .. ".png")

	var_14_7:setPosition(arg_14_1:getChildByName("icon"):getPosition())
	var_14_7:setAnchorPoint(cc.p(0, 0))
	arg_14_1:addChild(var_14_7)
end

function var_0_0.clickCell(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_1.data
	local var_15_1 = arg_15_0:checkTypeIsSelect(var_15_0)

	if not var_15_1 then
		if #arg_15_0.selectTypes == var_0_3 then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("PERSON_SHOW_TYPE_MAX")
			})

			return
		end

		arg_15_0:addToSelectType(var_15_0)
		arg_15_1:getChildByName("layout"):getChildByName("container"):getChildByName("txt_num"):setColor(cc.c4b(255, 255, 255, 255))
		arg_15_1:getChildByName("layout"):getChildByName("container"):getChildByName("txt_type"):setColor(cc.c4b(65, 74, 84, 255))
	else
		arg_15_0:removeSelectType(var_15_0)
		arg_15_1:getChildByName("layout"):getChildByName("container"):getChildByName("txt_num"):setColor(cc.c4b(106, 105, 119, 255))
		arg_15_1:getChildByName("layout"):getChildByName("container"):getChildByName("txt_type"):setColor(cc.c4b(152, 83, 53, 255))
	end

	local var_15_2 = arg_15_1:getChildByName("layout"):getChildByName("container")

	var_15_2:getChildByName("icon_check"):setVisible(not var_15_1)
	var_15_2:getChildByName("btn_show"):setVisible(var_15_1)
	var_15_2:getChildByName("btn_show_select"):setVisible(not var_15_1)
end

function var_0_0.addToSelectType(arg_16_0, arg_16_1)
	table.insert(arg_16_0.selectTypes, arg_16_1)
end

function var_0_0.removeSelectType(arg_17_0, arg_17_1)
	for iter_17_0, iter_17_1 in pairs(arg_17_0.selectTypes) do
		if iter_17_1 == arg_17_1 then
			table.remove(arg_17_0.selectTypes, iter_17_0)

			break
		end
	end
end

function var_0_0.checkTypeIsSelect(arg_18_0, arg_18_1)
	for iter_18_0, iter_18_1 in pairs(arg_18_0.selectTypes) do
		if iter_18_1 == arg_18_1 then
			return true
		end
	end

	return false
end

function var_0_0.buttonHandler(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	if not arg_19_2 or not arg_19_2:getParent() then
		return
	end

	if arg_19_3.name == "ended" then
		transition.stopTarget(arg_19_2)
		arg_19_2:setScale(1)

		if arg_19_1 then
			arg_19_1(arg_19_2, eventType)
		end
	elseif arg_19_3.name == "began" then
		local var_19_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_19_2:runAction(var_19_0)

		return true
	elseif arg_19_3.name == "cancled" then
		transition.stopTarget(arg_19_2)
		arg_19_2:setScale(1)
	end
end

return var_0_0
