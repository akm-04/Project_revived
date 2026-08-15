local var_0_0 = class("ChampionsLeagueSwitchGroupWinodw", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	txtRule = var_0_1:translation("CROSS_ARENA_UPGRADE_TXT"),
	txtWait = var_0_1:translation("CHAMPIONS_LEAGUE_WAIT"),
	txtBefore = var_0_1:translation("CHAMPIONS_LEAGUE_BEFORE"),
	txtNow = var_0_1:translation("CHAMPIONS_LEAGUE_NOW")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.champions = xyd.ModelManager.get():loadModel(xyd.ModelType.CHAMPIONS_LEAGUE)
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("txt_rule"):getContentSize()
	local var_3_1 = {
		size = 24,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_TOP,
		color = cc.c3b(152, 83, 53),
		dimensions = cc.size(var_3_0.width, var_3_0.height)
	}
	local var_3_2 = xyd.getColorlabel(var_3_1, var_0_2.txtRule)

	var_3_2:setAnchorPoint(cc.p(0, 1))
	var_3_2:addTo(arg_3_0:nodeByName("container"))
	var_3_2:setPosition(arg_3_0:nodeByName("txt_rule"):getPosition())
	arg_3_0:nodeByName("txt_wait"):setString(var_0_2.txtWait)
	arg_3_0:nodeByName("txt_before"):setString(var_0_2.txtBefore)
	arg_3_0:nodeByName("txt_now"):setString(var_0_2.txtNow)
	arg_3_0:initBtn()
end

function var_0_0.initBtn(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("btn_wait")

	var_4_0:addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			var_4_0:setScale(0.9)
		end

		if arg_5_1 == ccui.TouchEventType.canceled then
			var_4_0:setScale(1)
		end

		if arg_5_1 == ccui.TouchEventType.ended then
			var_4_0:setScale(1)

			local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_5_0, false)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)

	local var_4_1 = arg_4_0:nodeByName("btn_choose_before")

	var_4_1:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			var_4_1:setScale(0.9)
		end

		if arg_6_1 == ccui.TouchEventType.canceled then
			var_4_1:setScale(1)
		end

		if arg_6_1 == ccui.TouchEventType.ended then
			var_4_1:setScale(1)

			local var_6_0 = {}

			var_6_0.use_ori_rank = 1

			arg_4_0.champions:selectAwardGroup(var_6_0)

			local var_6_1 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_6_1, false)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)

	local var_4_2 = arg_4_0:nodeByName("btn_choose_now")

	var_4_2:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			var_4_2:setScale(0.9)
		end

		if arg_7_1 == ccui.TouchEventType.canceled then
			var_4_2:setScale(1)
		end

		if arg_7_1 == ccui.TouchEventType.ended then
			var_4_2:setScale(1)

			local var_7_0 = {}

			var_7_0.use_ori_rank = 0

			arg_4_0.champions:selectAwardGroup(var_7_0)

			local var_7_1 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_7_1, false)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
end

return var_0_0
