local var_0_0 = class("FurnitureStorageWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = xyd.tables.dormFurnitureItem
local var_0_4 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.btnState = xyd.StorageType.FURNITURE
	arg_1_0.listInfo = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:setButtonClick()
	arg_2_0:layout()
end

function var_0_0.setButtonClick(arg_3_0, arg_3_1)
	arg_3_0:nodeByName("btn_furniture"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0.btnState = xyd.StorageType.FURNITURE

			arg_3_0:changeButtonState()
			arg_3_0:updateListInfo()
			arg_3_0.list:reload()
		end
	end)
	arg_3_0:nodeByName("btn_decoration"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_3_0.btnState = xyd.StorageType.DECORATION

			arg_3_0:changeButtonState()
			arg_3_0:updateListInfo()
			arg_3_0.list:reload()
		end
	end)
	arg_3_0:nodeByName("btn_electronic"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			arg_3_0.btnState = xyd.StorageType.ELECTRONIC

			arg_3_0:changeButtonState()
			arg_3_0:updateListInfo()
			arg_3_0.list:reload()
		end
	end)
	arg_3_0:nodeByName("btn_fixture"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			arg_3_0.btnState = xyd.StorageType.FIXTURE

			arg_3_0:changeButtonState()
			arg_3_0:updateListInfo()
			arg_3_0.list:reload()
		end
	end)
	arg_3_0:nodeByName("btn_material"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			arg_3_0.btnState = xyd.StorageType.MATERIAL

			arg_3_0:changeButtonState()
			arg_3_0:updateListInfo()
			arg_3_0.list:reload()
		end
	end)
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	return
end

function var_0_0.didClose(arg_10_0, arg_10_1)
	var_0_0.super:didClose(arg_10_1)
end

function var_0_0.layout(arg_11_0)
	local var_11_0 = arg_11_0:nodeByName("item_list")
	local var_11_1 = var_11_0:getContentSize()

	arg_11_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_11_1.width, var_11_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_11_0):onScroll(handler(arg_11_0, arg_11_0.scrollListener))

	arg_11_0.list:setDelegate(handler(arg_11_0, arg_11_0.delegate))
	arg_11_0:changeButtonState()
	arg_11_0:updateListInfo()
	arg_11_0.list:reload()
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevX_ = arg_12_1.x
		arg_12_0.prevY_ = arg_12_1.y
	elseif arg_12_1.name == "moved" then
		local var_12_0 = 3

		if var_12_0 <= math.abs(arg_12_1.y - arg_12_0.prevY_) or var_12_0 <= math.abs(arg_12_1.x - arg_12_0.prevX_) then
			arg_12_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.changeButtonState(arg_13_0)
	if arg_13_0.btnState == xyd.StorageType.FURNITURE then
		arg_13_0:nodeByName("btn_furniture"):setTouchEnabled(false)
		arg_13_0:nodeByName("btn_decoration"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_electronic"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_fixture"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_material"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_material"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_furniture"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_13_0:nodeByName("btn_decoration"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_electronic"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_fixture"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_13_0.btnState == xyd.StorageType.DECORATION then
		arg_13_0:nodeByName("btn_furniture"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_decoration"):setTouchEnabled(false)
		arg_13_0:nodeByName("btn_electronic"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_fixture"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_material"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_material"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_furniture"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_decoration"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_13_0:nodeByName("btn_electronic"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_fixture"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_13_0.btnState == xyd.StorageType.ELECTRONIC then
		arg_13_0:nodeByName("btn_furniture"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_decoration"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_electronic"):setTouchEnabled(false)
		arg_13_0:nodeByName("btn_fixture"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_material"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_material"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_furniture"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_decoration"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_electronic"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_13_0:nodeByName("btn_fixture"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_13_0.btnState == xyd.StorageType.FIXTURE then
		arg_13_0:nodeByName("btn_furniture"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_decoration"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_electronic"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_fixture"):setTouchEnabled(false)
		arg_13_0:nodeByName("btn_material"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_material"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_furniture"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_decoration"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_electronic"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_fixture"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_13_0.btnState == xyd.StorageType.MATERIAL then
		arg_13_0:nodeByName("btn_furniture"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_decoration"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_electronic"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_fixture"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_material"):setTouchEnabled(false)
		arg_13_0:nodeByName("btn_material"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_13_0:nodeByName("btn_furniture"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_decoration"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_electronic"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_fixture"):setBrightStyle(ccui.BrightStyle.normal)
	end
end

function var_0_0.updateListInfo(arg_14_0)
	arg_14_0.listInfo = {}

	local var_14_0 = var_0_2:getItemsByTypes(xyd.ItemType.FURNITURE)

	if arg_14_0.btnState ~= xyd.StorageType.MATERIAL then
		for iter_14_0, iter_14_1 in pairs(var_14_0) do
			if var_0_3:subtype(iter_14_1) == arg_14_0.btnState and arg_14_0.selfPlayer:getBackpack():getItemNumByID(iter_14_1) > 0 then
				table.insert(arg_14_0.listInfo, iter_14_1)
			end
		end
	else
		for iter_14_2, iter_14_3 in pairs(var_14_0) do
			if var_0_2:subType(iter_14_3) == xyd.ItemType.FURNITURE and arg_14_0.selfPlayer:getBackpack():getItemNumByID(iter_14_3) > 0 then
				table.insert(arg_14_0.listInfo, iter_14_3)
			end
		end
	end
end

function var_0_0.delegate(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	if cc.ui.UIListView.COUNT_TAG == arg_15_2 then
		return (math.ceil(#arg_15_0.listInfo / var_0_4))
	elseif cc.ui.UIListView.CELL_TAG == arg_15_2 then
		local var_15_0 = arg_15_0.list:dequeueItem()

		if not var_15_0 then
			var_15_0 = arg_15_0.list:newItem()
		else
			var_15_0:removeAllChildren(true)
		end

		local var_15_1 = 700
		local var_15_2 = 135

		var_15_0:setItemSize(var_15_1, var_15_2)

		local var_15_3 = display.newNode()

		var_15_3:setContentSize(var_15_1, 110)
		arg_15_0:initCell(var_15_3, arg_15_3)
		var_15_0:addContent(var_15_3)

		return var_15_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_15_2 then
		-- block empty
	end
end

function var_0_0.initCell(arg_16_0, arg_16_1, arg_16_2)
	for iter_16_0 = 1, var_0_4 do
		local var_16_0 = (arg_16_2 - 1) * var_0_4 + iter_16_0

		if var_16_0 > #arg_16_0.listInfo then
			break
		end

		local var_16_1 = display.newNode()

		var_16_1:setContentSize(110, 110)
		var_16_1:setPosition(140 * iter_16_0 - 70, 55)
		var_16_1:setAnchorPoint(0.5, 0.5)
		arg_16_1:addChild(var_16_1)
		var_16_1:setTouchEnabled(true)
		var_16_1:setTouchSwallowEnabled(false)
		xyd.setItemBorder(var_16_1, arg_16_0.listInfo[var_16_0], false, false, arg_16_0.selfPlayer:getBackpack():getItemNumByID(arg_16_0.listInfo[var_16_0]))

		local var_16_2 = {
			id = arg_16_0.listInfo[var_16_0],
			lev = xyd.tables.item:level(arg_16_0.listInfo[var_16_0])
		}

		if xyd.tables.item:type(arg_16_0.listInfo[var_16_0]) == -1 then
			var_16_2.tipsType = 0
			var_16_2.desc1 = xyd.tables.hero:getDes(arg_16_0.listInfo[var_16_0])
		elseif specialItem then
			var_16_2.tipsType = 1
			var_16_2.id = -3
		else
			var_16_2.tipsType = 1
			var_16_2.desc1 = xyd.tables.item:desc1(arg_16_0.listInfo[var_16_0])
			var_16_2.desc2 = xyd.tables.item:desc2(arg_16_0.listInfo[var_16_0])
		end

		var_16_2.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(arg_16_0.listInfo[var_16_0])
		var_16_2.name = xyd.tables.item:name(arg_16_0.listInfo[var_16_0])

		arg_16_0:addTips(var_16_1, var_16_2)
	end
end

return var_0_0
