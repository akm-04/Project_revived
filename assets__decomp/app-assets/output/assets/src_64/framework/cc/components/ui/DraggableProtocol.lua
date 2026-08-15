local var_0_0 = cc.Component
local var_0_1 = class("DraggableProtocol", var_0_0)

function var_0_1.ctor(arg_1_0)
	var_0_1.super.ctor(arg_1_0, "DraggableProtocol")
end

function var_0_1.setDraggableEnable(arg_2_0, arg_2_1)
	if arg_2_1 then
		arg_2_0.target_:setTouchEnabled(true)
		arg_2_0.target_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_3_0)
			return arg_2_0:dragOnTouch_(arg_3_0)
		end)
	else
		arg_2_0.target_:setTouchEnabled(false)
	end

	return arg_2_0.target_
end

function var_0_1.exportMethods(arg_4_0)
	arg_4_0:exportMethods_({
		"setDraggableEnable"
	})

	return arg_4_0.target_
end

function var_0_1.dragOnTouch_(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0.target_:getCascadeBoundingBox()

	if arg_5_1.name == "began" and not cc.rectContainsPoint(var_5_0, cc.p(arg_5_1.x, arg_5_1.y)) then
		printInfo("DraggableProtocol - touch didn't in viewRect")

		return false
	end

	if arg_5_1.name == "began" then
		return true
	elseif arg_5_1.name == "moved" then
		local var_5_1, var_5_2 = arg_5_0.target_:getPosition()

		arg_5_0.target_:setPosition(var_5_1 + arg_5_1.x - arg_5_1.prevX, var_5_2 + arg_5_1.y - arg_5_1.prevY)
	elseif arg_5_1.name == "ended" then
		-- block empty
	end
end

return var_0_1
