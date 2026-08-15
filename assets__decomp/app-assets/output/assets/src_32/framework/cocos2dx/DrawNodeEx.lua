local var_0_0 = cc.DrawNode
local var_0_1 = var_0_0.drawPolygon

function var_0_0.drawPolygon(arg_1_0, arg_1_1, arg_1_2)
	local var_1_0 = #arg_1_1

	fillColor = cc.c4f(1, 1, 1, 1)
	borderWidth = 0
	borderColor = cc.c4f(0, 0, 0, 1)

	if arg_1_2 then
		if arg_1_2.fillColor then
			fillColor = arg_1_2.fillColor
		end

		if arg_1_2.borderWidth then
			borderWidth = arg_1_2.borderWidth
		end

		if arg_1_2.borderColor then
			borderColor = arg_1_2.borderColor
		end
	end

	var_0_1(arg_1_0, arg_1_1, #arg_1_1, fillColor, borderWidth, borderColor)

	return arg_1_0
end

local var_0_2 = var_0_0.drawConvexPolygon

function var_0_0.drawConvexPolygon(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0 = #arg_2_1

	borderWidth = 0
	borderColor = cc.c4f(0, 0, 0, 1)

	local var_2_1
	local var_2_2
	local var_2_3

	if arg_2_2 then
		if arg_2_2.center then
			var_2_2 = arg_2_2.center
		end

		if arg_2_2.centerColor then
			var_2_3 = arg_2_2.centerColor
		end

		if arg_2_2.borderWidth then
			borderWidth = arg_2_2.borderWidth
		end

		if arg_2_2.borderColor then
			borderColor = arg_2_2.borderColor
		end

		if arg_2_2.vertColors then
			var_2_1 = arg_2_2.vertColors
		end
	end

	if var_2_1 == nil or var_2_2 == nil or var_2_3 == nil then
		return nil
	end

	var_0_2(arg_2_0, arg_2_1, #arg_2_1, var_2_2, borderWidth, borderColor, var_2_1, var_2_3)

	return arg_2_0
end

local var_0_3 = var_0_0.drawDot

function var_0_0.drawDot(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	var_0_3(arg_3_0, arg_3_1, arg_3_2, arg_3_3)

	return arg_3_0
end
