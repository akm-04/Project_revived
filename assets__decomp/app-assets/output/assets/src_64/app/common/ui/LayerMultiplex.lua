local var_0_0 = class("LayerMultiplex", function()
	return display.newNode()
end)

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0.layers_ = {}
	arg_2_0.enabledLayer_ = 1

	for iter_2_0, iter_2_1 in ipairs(arg_2_1) do
		arg_2_0:addLayer(iter_2_1)
	end

	arg_2_0:setNodeEventEnabled(true)
end

function var_0_0.addLayer(arg_3_0, arg_3_1)
	arg_3_1:retain()
	print("retain " .. tostring(arg_3_1))
	table.insert(arg_3_0.layers_, arg_3_1)

	if arg_3_0.layers_[arg_3_0.enabledLayer_] == arg_3_1 then
		arg_3_0:addChild(arg_3_0.layers_[arg_3_0.enabledLayer_])
	end

	arg_3_0:setContentSize(cc.size(arg_3_0:getCascadeBoundingBox().width, arg_3_0:getCascadeBoundingBox().height))
end

function var_0_0.switchTo(arg_4_0, arg_4_1)
	assert(arg_4_1 <= #arg_4_0.layers_, string.format("Invalid index in MultiplexLayer switchTo message"))

	if arg_4_0.enabledLayer_ == arg_4_1 then
		return
	end

	arg_4_0:removeChild(arg_4_0.layers_[arg_4_0.enabledLayer_], false)

	arg_4_0.enabledLayer_ = arg_4_1

	arg_4_0:addChild(arg_4_0.layers_[arg_4_0.enabledLayer_])
end

function var_0_0.cleanup(arg_5_0)
	for iter_5_0, iter_5_1 in pairs(arg_5_0.layers_) do
		print("release " .. tostring(iter_5_1))
		iter_5_1:release()
	end
end

function var_0_0.onExitTransitionDidStart(arg_6_0)
	print("LayerMultiplex:onExitTransitionDidStart")
end

function var_0_0.onExit(arg_7_0)
	print("LayerMultiplex:onExit")
end

function var_0_0.onCleanup(arg_8_0)
	print("LayerMultiplex:onCleanup")
	arg_8_0:cleanup()
end

return var_0_0
