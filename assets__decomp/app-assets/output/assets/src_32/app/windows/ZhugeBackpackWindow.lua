local var_0_0 = class("ZhugeBackpackWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = xyd.tables.zhugeShop

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.datas = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:getDatas()
	arg_2_0:initListview()
	arg_2_0:layout()
end

function var_0_0.getDatas(arg_3_0)
	arg_3_0.datas = var_0_3:ids()
end

function var_0_0.updateListview(arg_4_0)
	arg_4_0.list:reload()
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("text_title"):setString(var_0_1:translation("ZHUGE_FOREST_TIPS_14"))
	arg_5_0:nodeByName("text_num"):setVisible(false)
end

function var_0_0.initListview(arg_6_0)
	local var_6_0 = arg_6_0:nodeByName("list")
	local var_6_1 = var_6_0:getContentSize().width
	local var_6_2 = var_6_0:getContentSize().height

	arg_6_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_6_1, var_6_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_6_0)

	arg_6_0.list:setDelegate(handler(arg_6_0, arg_6_0.delegate))
end

function var_0_0.delegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = #arg_7_0.datas

	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return var_7_0
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_1
		local var_7_2
		local var_7_3
		local var_7_4 = arg_7_0.list:dequeueItem()

		if not var_7_4 then
			var_7_4 = arg_7_0.list:newItem()
		else
			var_7_4:removeAllChildren()
		end

		local var_7_5 = display.newNode()

		var_7_5:setTouchSwallowEnabled(false)

		local var_7_6 = display.newNode()

		arg_7_0:initBackpackItem(var_7_6, arg_7_3)

		local var_7_7 = var_7_6:getContentSize().width
		local var_7_8 = var_7_6:getContentSize().height

		var_7_5:addChild(var_7_6)
		var_7_5:setContentSize(cc.size(arg_7_0.list.viewRect_.width, var_7_6:getContentSize().height + 5))
		var_7_4:setItemSize(arg_7_0.list.viewRect_.width, var_7_6:getContentSize().height + 5)
		var_7_4:addContent(var_7_5)

		return var_7_4
	end
end

function var_0_0.initBackpackItem(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = arg_8_0.datas[arg_8_2]
	local var_8_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/backpack_and_shop/list_item_1.csb")

	var_8_1:addTo(arg_8_1)

	local var_8_2 = var_8_1:getChildByName("container")
	local var_8_3 = var_8_2:getContentSize()

	arg_8_1:setContentSize(var_8_3)

	local var_8_4 = var_0_2:name(var_8_0)
	local var_8_5 = var_0_2:desc1(var_8_0)

	var_8_2:getChildByName("text_name"):setString(var_8_4)
	var_8_2:getChildByName("text_desc"):setString(var_8_5)

	local var_8_6 = arg_8_0.backpack:getItemNumByID(var_8_0)

	xyd.setItemBorder(var_8_2:getChildByName("item"), var_8_0, false, false, var_8_6, false, true)
	var_8_2:getChildByName("btn_buy"):setVisible(false)
	var_8_2:getChildByName("btn_use"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			if arg_8_0.backpack:getItemNumByID(var_8_0) > 0 then
				local var_9_0 = {
					itemID = var_8_0
				}

				xyd.WindowManager.get():openWindow("zhuge_item_use", var_9_0)
			else
				local var_9_1 = var_0_1:translation("ZHUGE_FOREST_TIPS_15")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_9_1
				})
			end
		end
	end)
end

function var_0_0.didOpen(arg_10_0, arg_10_1)
	var_0_0.super:didOpen(arg_10_1)
	arg_10_0.list:reload()
end

return var_0_0
