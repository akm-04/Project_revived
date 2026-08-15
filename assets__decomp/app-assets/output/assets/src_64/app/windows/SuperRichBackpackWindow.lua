local var_0_0 = class("SuperRichBackpackWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.superRich = xyd.ModelManager.get():loadModel(xyd.ModelType.SUPER_RICH)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.canUseType = arg_1_2.use_type
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setButtonClick()
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0:nodeByName("control_card"):setTouchEnabled(true)
	arg_4_0:nodeByName("control_card"):setTouchSwallowEnabled(false)
	arg_4_0:nodeByName("control_card"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			return true
		elseif arg_5_0.name == "ended" and arg_4_0.canUseType[1] == 1 then
			xyd.playButtonSound()

			if arg_4_0.backpack:getItemNumByID(xyd.tables.misc.activityRichRemoteDiceItem) <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("SUPER_RICH_ITEM_NOT_ENOUGH")
				})

				return
			end

			arg_4_0.callback(1)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("ticket_vip"):setTouchEnabled(true)
	arg_4_0:nodeByName("ticket_vip"):setTouchSwallowEnabled(false)
	arg_4_0:nodeByName("ticket_vip"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			return true
		elseif arg_6_0.name == "ended" and arg_4_0.canUseType[2] == 1 then
			xyd.playButtonSound()

			if arg_4_0.backpack:getItemNumByID(xyd.tables.misc.activityRichVipCardItem) <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("SUPER_RICH_ITEM_NOT_ENOUGH")
				})

				return
			end

			arg_4_0.callback(2)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("pass_card"):setTouchEnabled(true)
	arg_4_0:nodeByName("pass_card"):setTouchSwallowEnabled(false)
	arg_4_0:nodeByName("pass_card"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			return true
		elseif arg_7_0.name == "ended" and arg_4_0.canUseType[3] == 1 then
			xyd.playButtonSound()

			if arg_4_0.backpack:getItemNumByID(xyd.tables.misc.activityRichPasserByCardItem) <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("SUPER_RICH_ITEM_NOT_ENOUGH")
				})

				return
			end

			arg_4_0.callback(3)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("control_num_txt"):setString(arg_4_0.backpack:getItemNumByID(xyd.tables.misc.activityRichRemoteDiceItem))
	arg_4_0:nodeByName("pass_card_num_txt"):setString(arg_4_0.backpack:getItemNumByID(xyd.tables.misc.activityRichVipCardItem))
	arg_4_0:nodeByName("ticket_num_txt"):setString(arg_4_0.backpack:getItemNumByID(xyd.tables.misc.activityRichPasserByCardItem))
	arg_4_0:nodeByName("control_num_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 2)
	arg_4_0:nodeByName("pass_card_num_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 2)
	arg_4_0:nodeByName("ticket_num_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 2)
end

return var_0_0
