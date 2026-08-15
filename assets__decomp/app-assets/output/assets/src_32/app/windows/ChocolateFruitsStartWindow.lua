local var_0_0 = class("ChocolateFruitsStartWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = "skeletons/ui_effect/gold_catch/kaunggongdongzuo"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.isStart = arg_1_2.is_start
	arg_1_0.isNext = arg_1_2.is_next
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayerWithNoTouchEvent()
	arg_2_0:initEffect()
end

function var_0_0.initEffect(arg_3_0)
	if not arg_3_0.isNext and not arg_3_0.selectEffect then
		local var_3_0 = xyd.createEffect(var_0_3)

		var_3_0:addTo(arg_3_0:nodeByName("down_time_container"))

		local var_3_1 = arg_3_0:nodeByName("down_time_container"):getContentSize()

		var_3_0:setPosition(var_3_1.width / 2, var_3_1.height / 2)
		var_3_0:play(function()
			var_0_2.performWithDelayGlobal(function()
				if arg_3_0.callback then
					arg_3_0.callback()
				end

				xyd.WindowManager.get():closeWindow(arg_3_0)
			end, 0.1)
		end, false, nil, "texiao01")

		arg_3_0.selectEffect = var_3_0
	elseif arg_3_0.isNext then
		local var_3_2 = xyd.createEffect(var_0_3)

		var_3_2:addTo(arg_3_0:nodeByName("down_time_container"))

		local var_3_3 = arg_3_0:nodeByName("down_time_container"):getContentSize()

		var_3_2:setPosition(var_3_3.width / 2, var_3_3.height / 2)
		var_3_2:play(function()
			var_0_2.performWithDelayGlobal(function()
				if arg_3_0.callback then
					arg_3_0.callback()
				end

				xyd.WindowManager.get():closeWindow(arg_3_0)
			end, 0.1)
		end, false, nil, "texiao02")

		arg_3_0.selectEffect = var_3_2
	end
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super.didOpen(arg_8_0, arg_8_1)

	if arg_8_0.isNext then
		arg_8_0:playAction()
	end
end

function var_0_0.layout(arg_9_0)
	arg_9_0:nodeByName("down_time_container"):setVisible(false)
	arg_9_0:nodeByName("start_container"):setVisible(false)
	arg_9_0:nodeByName("end_container"):setVisible(false)
	arg_9_0:nodeByName("next_container"):setVisible(false)

	for iter_9_0 = 1, 3 do
		arg_9_0:nodeByName("word_" .. iter_9_0):setVisible(false)
	end

	if arg_9_0.isNext then
		arg_9_0:nodeByName("down_time_container"):setVisible(true)
	elseif arg_9_0.isStart then
		arg_9_0:nodeByName("down_time_container"):setVisible(true)
	else
		arg_9_0:nodeByName("end_container"):setVisible(true)
	end
end

function var_0_0.playAction(arg_10_0)
	arg_10_0:nodeByName("next_container"):setVisible(true)

	arg_10_0.handle = var_0_2.performWithDelayGlobal(function()
		if arg_10_0.callback then
			arg_10_0.callback()
		end

		xyd.WindowManager.get():closeWindow(arg_10_0)
	end, 1.5)
end

function var_0_0.willClose(arg_12_0, arg_12_1)
	var_0_0.super.willClose(arg_12_0, arg_12_1)

	if arg_12_0.handler then
		var_0_2.unscheduleGlobal(arg_12_0.handler)

		arg_12_0.handler = nil
	end
end

return var_0_0
