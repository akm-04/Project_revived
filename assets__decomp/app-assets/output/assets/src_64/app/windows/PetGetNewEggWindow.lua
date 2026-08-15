local var_0_0 = class("PetGetNewEggWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.hero
local var_0_3 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.egg_id = arg_1_2.egg_id
	arg_1_0.has_egg = arg_1_2.has_egg
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:modelShowEgg(var_0_2:getEggImgByEggId(arg_4_0.egg_id), arg_4_0:nodeByName("egg_node"))

	if arg_4_0.has_egg and arg_4_0.has_egg == false then
		arg_4_0:nodeByName("tip_text"):setString(var_0_1:translation("PET_EGG_GUIDE_TIP_1"))
	else
		arg_4_0:nodeByName("tip_text"):setString(var_0_1:translation("PET_EGG_GUIDE_TIP_2"))
	end

	if arg_4_0.timer == nil then
		arg_4_0.timer = var_0_3.scheduleGlobal(handler(arg_4_0, arg_4_0.timerUpdate), 5)
	end

	arg_4_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			arg_4_0:nodeByName("ok_btn"):setScale(0.9)

			return true
		elseif arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0:nodeByName("ok_btn"):setScale(1)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
end

function var_0_0.timerUpdate(arg_6_0)
	local var_6_0 = xyd.Shake:create(0.3, 2)

	arg_6_0:nodeByName("egg_node"):runAction(var_6_0)
end

function var_0_0.modelShowEgg(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = xyd.AssetLoader.get():loadSprite(arg_7_1)

	var_7_0:setTouchSwallowEnabled(false)

	local var_7_1 = arg_7_2:getContentSize().width / 2 - 10
	local var_7_2 = arg_7_2:getContentSize().height / 2

	var_7_0:setPosition(cc.p(var_7_1, var_7_2))
	arg_7_2:removeAllChildren()
	var_7_0:addTo(arg_7_2)

	local var_7_3 = xyd.Shake:create(1, 2)

	arg_7_0:nodeByName("egg_node"):runAction(var_7_3)
end

function var_0_0.willClose(arg_8_0, arg_8_1)
	if arg_8_0.timer then
		var_0_3.unscheduleGlobal(arg_8_0.timer)
	end

	var_0_0.super.willClose(arg_8_1)
end

function var_0_0.didClose(arg_9_0)
	wnd = xyd.WindowManager.get():getWindow("main_scene_bottom")

	if wnd then
		arg_9_0.selfPlayer:setPetGuideId()
		wnd:playGuide(true)
	end
end

return var_0_0
