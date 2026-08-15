local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.allNightCampaign
local var_0_3 = require("framework.scheduler")
local var_0_4 = xyd.tables.misc:getValue("activity_ragnarok_function_unlock")
local var_0_5 = {
	task = var_0_1:translation("RAGNAROK_MAIN_1"),
	story = var_0_1:translation("RAGNAROK_MAIN_2"),
	boss = var_0_1:translation("RAGNAROK_MAIN_3"),
	gacha = var_0_1:translation("RAGNAROK_MAIN_4")
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.ragnarok = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0:onRegister()
	arg_2_0:layout()
end

function var_0_0.onRegister(arg_3_0)
	return
end

function var_0_0.layout(arg_4_0)
	arg_4_0.container:getChildByName("btn_task"):getChildByName("txt_task"):setString(var_0_5.task)
	arg_4_0.container:getChildByName("btn_story"):getChildByName("txt_story"):setString(var_0_5.story)
	arg_4_0.container:getChildByName("btn_boss"):getChildByName("txt_boss"):setString(var_0_5.boss)
	arg_4_0.container:getChildByName("btn_gacha"):getChildByName("txt_gacha"):setString(var_0_5.gacha)
	arg_4_0.ragnarok:getInfo(function()
		arg_4_0:initBtn()
	end)
end

function var_0_0.initBtn(arg_6_0)
	local var_6_0 = arg_6_0.container:getChildByName("btn_story")

	var_6_0:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			var_6_0:setScale(0.9)
		elseif arg_7_1 == ccui.TouchEventType.ended then
			var_6_0:setScale(1)
			arg_6_0.ragnarok:enterMap(nil, 1)
		end
	end)

	local var_6_1 = arg_6_0.container:getChildByName("btn_boss")

	var_6_1:addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_8_0, arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			arg_6_0.ragnarok:loadInfo(function(arg_9_0)
				xyd.WindowManager.get():openWindow("ragnarok_main")
			end)
		end
	end)

	local var_6_2 = arg_6_0.container:getChildByName("btn_gacha")

	var_6_2:addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.began then
			var_6_2:setScale(0.9)
		elseif arg_10_1 == ccui.TouchEventType.ended then
			var_6_2:setScale(1)
			xyd.WindowManager.get():openWindow("activity_ragnarok_gacha")
		end
	end)

	local var_6_3 = arg_6_0.container:getChildByName("btn_task")

	var_6_3:addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.began then
			var_6_3:setScale(0.9)
		elseif arg_11_1 == ccui.TouchEventType.ended then
			var_6_3:setScale(1)
			arg_6_0.ragnarok:getTaskInfo(function()
				xyd.WindowManager.get():openWindow("activity_ragnarok_task")
			end)
		end
	end)

	if arg_6_0.ragnarok.isFuncOpen then
		var_6_3:setTouchEnabled(true)
		var_6_2:setTouchEnabled(true)
		var_6_1:setTouchEnabled(true)
		arg_6_0.container:getChildByName("mask_task"):setVisible(false)
		arg_6_0.container:getChildByName("mask_boss"):setVisible(false)
		arg_6_0.container:getChildByName("mask_gacha"):setVisible(false)
	else
		var_6_3:setTouchEnabled(false)
		var_6_2:setTouchEnabled(false)
		var_6_1:setTouchEnabled(false)
	end
end

return var_0_0
