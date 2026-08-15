local var_0_0 = class("ActivityDecodeCollectionTipWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.collectItems = arg_1_2.collect_items
	arg_1_0.needNum = arg_1_2.need_num
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("tip_txt1"):setString(var_0_1:translation("ACTIVITY_DECODE_PROGRESS_TEXT1"))
	arg_4_0:nodeByName("tip_txt2"):setString(string.format(var_0_1:translation("ACTIVITY_DECODE_PROGRESS_TEXT2"), #arg_4_0.collectItems, arg_4_0.needNum))

	local var_4_0 = xyd.tables.misc.activityDecodePandent

	for iter_4_0, iter_4_1 in pairs(var_4_0) do
		local var_4_1 = display.newNode()

		var_4_1:setContentSize(280, 45)
		var_4_1:setAnchorPoint(cc.p(0, 0.5))
		var_4_1:setPosition(cc.p(0, -(iter_4_0 - 1) * 70))

		local var_4_2 = var_4_1:getContentSize()
		local var_4_3 = xyd.createLabel(22, cc.c3b(255, 255, 255))

		var_4_3:setString(string.format(var_0_1:translation("ACTIVITY_DECODE_PROGRESS_TEXT3"), iter_4_0))
		var_4_3:addTo(var_4_1)
		var_4_3:setAnchorPoint(cc.p(0, 0.5))
		var_4_3:setPositionY(var_4_2.height / 2)

		local var_4_4 = display.newNode()

		var_4_4:setContentSize(35, 35)
		xyd.setItemBorder(var_4_4, iter_4_1)
		var_4_4:addTo(var_4_1)
		var_4_4:setAnchorPoint(cc.p(0, 0.5))
		var_4_4:setPosition(cc.p(100, var_4_2.height / 2))
		var_4_1:addTo(arg_4_0:nodeByName("item_pos"))
		var_4_1:setPositionY(-(iter_4_0 - 1) * var_4_2.height)

		local var_4_5 = xyd.createLabel(22, cc.c3b(255, 255, 255))

		if xyd.isInTable(arg_4_0.collectItems, tostring(iter_4_1)) then
			var_4_5:setString(1 .. "/" .. 1)
		else
			var_4_5:setString(0 .. "/" .. 1)
		end

		var_4_5:addTo(var_4_1)
		var_4_5:setAnchorPoint(cc.p(0, 0.5))
		var_4_5:setPosition(cc.p(190, var_4_2.height / 2))
	end
end

return var_0_0
