local var_0_0 = class("WarCampChatWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = {
	ALL_CAMP = 2,
	SELF_CAMP = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.warCamp_ = xyd.ModelManager.get():loadModel(xyd.ModelType.WAR_CAMP)
	arg_1_0.camp_ = arg_1_0.warCamp_:getCampType()
	arg_1_0.showChatType = var_0_1.SELF_CAMP
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:setTouchSwallowEnabled(false)
	arg_2_0:nodeByName("container"):setTouchEnabled(true)
	arg_2_0:nodeByName("container"):setTouchSwallowEnabled(false)
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	var_0_0.super:willClose(arg_3_1)
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("container")
	local var_4_1 = var_4_0:getContentSize()

	var_4_0:setPosition(cc.p(-var_4_1.width, 0))
	var_4_0:setTouchSwallowEnabled(true)
	arg_4_0:showChatWnd()
	arg_4_0:updateShowList()
	arg_4_0:nodeByName("img_msg"):setTouchEnabled(true)
	arg_4_0:nodeByName("img_msg"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			arg_4_0:nodeByName("img_msg"):setScale(0.9)

			return true
		elseif arg_5_0.name == "ended" then
			arg_4_0:nodeByName("img_msg"):setScale(1)
			arg_4_0:showChatWnd()
			arg_4_0:updateRedMark(false)
		end
	end)
	arg_4_0:nodeByName("btn_camp"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended and arg_4_0.showChatType ~= var_0_1.SELF_CAMP then
			arg_4_0.showChatType = var_0_1.SELF_CAMP

			arg_4_0:updateShowList()
		end
	end)
	arg_4_0:nodeByName("btn_all"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended and arg_4_0.showChatType ~= var_0_1.ALL_CAMP then
			arg_4_0.showChatType = var_0_1.ALL_CAMP

			arg_4_0:updateShowList()
		end
	end)
end

function var_0_0.updateShowList(arg_8_0)
	if arg_8_0.showChatType == var_0_1.SELF_CAMP then
		arg_8_0:nodeByName("list_all"):setVisible(false)
		arg_8_0:nodeByName("list_self"):setVisible(true)
		arg_8_0:nodeByName("btn_camp"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_8_0:nodeByName("btn_camp"):setTouchEnabled(false)
		arg_8_0:nodeByName("btn_all"):setTouchEnabled(true)
		arg_8_0:nodeByName("btn_all"):setBrightStyle(ccui.BrightStyle.normal)
	else
		arg_8_0:nodeByName("list_all"):setVisible(true)
		arg_8_0:nodeByName("list_self"):setVisible(false)
		arg_8_0:nodeByName("btn_camp"):setBrightStyle(ccui.BrightStyle.normal)
		arg_8_0:nodeByName("btn_all"):setTouchEnabled(false)
		arg_8_0:nodeByName("btn_camp"):setTouchEnabled(true)
		arg_8_0:nodeByName("btn_all"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_0.showChatWnd(arg_9_0)
	if arg_9_0.chatWinIsShow then
		arg_9_0.chatWinIsShow = false

		arg_9_0:playChatWinMove(arg_9_0.chatWinIsShow)

		return
	elseif arg_9_0.chatIsInit then
		arg_9_0.chatWinIsShow = true

		arg_9_0:playChatWinMove(arg_9_0.chatWinIsShow)

		return
	end

	arg_9_0:initChatWnd(arg_9_0:nodeByName("list_all"), true)
	arg_9_0:initChatWnd(arg_9_0:nodeByName("list_self"), false)
end

function var_0_0.initChatWnd(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = import("app.windows.GroupChatWnd").new()
	local var_10_1 = {
		no_click_avatar = true,
		add_wnd_name = "war_camp_chat",
		change_height = -80,
		select_type = xyd.FriendMsgSelectType.WAR_CAMP,
		chat_wnd_type = xyd.ChatWndType.SERVICE,
		isAll = arg_10_2
	}

	if not arg_10_2 then
		var_10_1.my_camp = arg_10_0.camp_
	end

	var_10_0:setParams(var_10_1)
	var_10_0:addTo(arg_10_1)
	var_10_0:setPosition(cc.p(0, 0))

	arg_10_0.chatIsInit = true
	arg_10_0.chatWinIsShow = false

	var_10_0:updateList()
	arg_10_0:updateRedMark(false)
end

function var_0_0.updateRedMark(arg_11_0, arg_11_1)
	if arg_11_0.chatWinIsShow then
		arg_11_0:nodeByName("icon_red"):setVisible(false)
	else
		arg_11_0:nodeByName("icon_red"):setVisible(arg_11_1)
	end
end

function var_0_0.playChatWinMove(arg_12_0, arg_12_1)
	local var_12_0 = arg_12_0:nodeByName("container")
	local var_12_1 = var_12_0:getContentSize()

	if arg_12_1 then
		var_12_0:setPosition(cc.p(-var_12_1.width, 0))
		var_12_0:setVisible(true)
		transition.moveTo(var_12_0, {
			time = 0.3,
			x = 0,
			y = 0
		})
	else
		transition.moveTo(var_12_0, {
			time = 0.3,
			y = 0,
			x = -var_12_1.width
		})
	end
end

return var_0_0
