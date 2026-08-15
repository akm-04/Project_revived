local var_0_0 = class("CountShopAlertWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.misc:getValue("activity_sp_shop_item_id")

function var_0_0.open(arg_1_0, arg_1_1, arg_1_2, arg_1_3)
	local var_1_0 = arg_1_2 or {}

	var_1_0.txt = arg_1_0
	var_1_0.label = arg_1_3
	var_1_0.callback = arg_1_1

	return xyd.WindowManager.get():openWindow("count_shop_alert", var_1_0)
end

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2)
	var_0_0.super.ctor(arg_2_0, arg_2_1, arg_2_2)

	arg_2_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.title = arg_2_2.title or xyd.tables.translation:translation("TIP")
	arg_2_0.txt = arg_2_2.txt
	arg_2_0.label = arg_2_2.label
	arg_2_0.callback = arg_2_2.callback
end

function var_0_0.willOpen(arg_3_0)
	arg_3_0:nodeByName("icon_check"):setVisible(false)
end

function var_0_0.didOpen(arg_4_0)
	arg_4_0.container = arg_4_0:nodeByName("container")

	arg_4_0:addBlockLayer()
	arg_4_0:layout()
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("txt_name"):setString(arg_5_0.title)
	arg_5_0:nodeByName("txt_sure"):setString(xyd.tables.translation:translation("SURE"))
	arg_5_0:nodeByName("txt_cancel"):setString(xyd.tables.translation:translation("CANCEL"))

	local var_5_0 = xyd.tables.translation:translation("ACTIVITY_SP_SHOP_USE_ITEM") .. string.format(xyd.tables.translation:translation("ACTIVITY_SP_SHOP_TIP"), arg_5_0.player:getBackpack():getItemNumByID(var_0_3))

	arg_5_0:nodeByName("txt_check"):setString(var_5_0)

	local var_5_1 = false
	local var_5_2 = {
		size = 28,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_CENTER,
		color = cc.c3b(68, 69, 77),
		dimensions = cc.size(500, 80)
	}
	local var_5_3 = xyd.getColorlabel(var_5_2, arg_5_0.txt)

	var_5_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_3:addTo(arg_5_0.container)
	var_5_3:setPosition(arg_5_0:nodeByName("pos_text"):getPosition())

	local var_5_4 = var_0_1.new({
		size = 500
	})

	var_5_4:addTo(arg_5_0.container)
	var_5_4:setAnchorPoint(0.5, 0.5)
	var_5_4:setPosition(cc.p(300, 140))

	local var_5_5 = arg_5_0:nodeByName("bg_check")

	if var_5_1 then
		arg_5_0:nodeByName("icon_check"):setVisible(true)
	else
		arg_5_0:nodeByName("icon_check"):setVisible(false)
	end

	var_5_5:setTouchEnabled(true)
	var_5_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			return true
		elseif arg_6_0.name == "ended" then
			if arg_5_0.player:getBackpack():getItemNumByID(var_0_3) < 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("ACTIVITY_SP_SHOP_ITEM_NOT_ENOUGH")
				})

				return
			end

			var_5_1 = not var_5_1

			if var_5_1 then
				arg_5_0:nodeByName("icon_check"):setVisible(true)
			else
				arg_5_0:nodeByName("icon_check"):setVisible(false)
			end
		end
	end)
	arg_5_0:nodeByName("btn_cancel"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			arg_5_0:nodeByName("btn_cancel"):setScale(0.9)
		end

		if arg_7_1 == ccui.TouchEventType.ended then
			arg_5_0:nodeByName("btn_cancel"):setScale(1)
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end

		if arg_7_1 == ccui.TouchEventType.moved then
			arg_5_0:nodeByName("btn_cancel"):setScale(1)
		end
	end)
	arg_5_0:nodeByName("btn_sure"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			arg_5_0:nodeByName("btn_sure"):setScale(0.9)
		end

		if arg_8_1 == ccui.TouchEventType.ended then
			arg_5_0:nodeByName("btn_sure"):setScale(1)
			xyd.WindowManager.get():closeWindow(arg_5_0, function()
				arg_5_0.callback(var_5_1)
			end)
		end

		if arg_8_1 == ccui.TouchEventType.moved then
			arg_5_0:nodeByName("btn_sure"):setScale(1)
		end
	end)
end

return var_0_0
