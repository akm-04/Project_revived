local var_0_0 = import(".UILayout")
local var_0_1 = class("UIBoxLayout", var_0_0)

function var_0_1.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_1.super.ctor(arg_1_0, arg_1_2)

	arg_1_0.direction_ = arg_1_1 or display.LEFT_TO_RIGHT
end

function var_0_1.getDirection(arg_2_0)
	return arg_2_0.direction_
end

function var_0_1.setDirection(arg_3_0, arg_3_1)
	arg_3_0.direction_ = arg_3_1

	return arg_3_0
end

local var_0_2 = 0

function var_0_1.apply(arg_4_0, arg_4_1)
	if table.nums(arg_4_0.widgets_) == 0 then
		return
	end

	arg_4_1 = arg_4_1 or arg_4_0

	if DEBUG > 1 then
		local var_4_0 = string.rep("  ", var_0_2)

		printInfo("%sAPPLY LAYOUT %s", var_4_0, arg_4_0:getName())
	end

	local var_4_1 = arg_4_0.direction_ == display.LEFT_TO_RIGHT or arg_4_0.direction_ == display.RIGHT_TO_LEFT
	local var_4_2 = 0
	local var_4_3 = 0
	local var_4_4 = 0
	local var_4_5 = 0
	local var_4_6 = 0
	local var_4_7 = 0
	local var_4_8 = {}

	for iter_4_0, iter_4_1 in pairs(arg_4_0.widgets_) do
		local var_4_9 = {
			widget = iter_4_0,
			weight = iter_4_1.weight,
			order = iter_4_1.order
		}
		local var_4_10, var_4_11 = iter_4_0:getLayoutSize()
		local var_4_12, var_4_13 = iter_4_0:getLayoutSizePolicy()
		local var_4_14, var_4_15, var_4_16, var_4_17 = iter_4_0:getLayoutMargin()

		if var_4_12 == display.FIXED_SIZE then
			var_4_4 = var_4_4 + var_4_10 + var_4_17 + var_4_15
			var_4_9.width = var_4_10
		else
			var_4_2 = var_4_2 + iter_4_1.weight
		end

		if var_4_13 == display.FIXED_SIZE then
			var_4_5 = var_4_5 + var_4_11
			var_4_9.height = var_4_11
		else
			var_4_3 = var_4_3 + iter_4_1.weight
		end

		if var_4_6 < var_4_10 then
			var_4_6 = var_4_10
		end

		if var_4_7 < var_4_11 then
			var_4_7 = var_4_11
		end

		var_4_8[#var_4_8 + 1] = var_4_9
	end

	table.sort(var_4_8, function(arg_5_0, arg_5_1)
		return arg_5_0.order < arg_5_1.order
	end)

	local var_4_18, var_4_19 = arg_4_1:getLayoutSize()
	local var_4_20, var_4_21, var_4_22, var_4_23 = arg_4_1:getLayoutPadding()
	local var_4_24 = var_4_18 - var_4_23 - var_4_21
	local var_4_25 = var_4_19 - var_4_20 - var_4_22

	if var_4_1 then
		var_4_7 = var_4_25
	else
		var_4_6 = var_4_24
	end

	local var_4_26
	local var_4_27
	local var_4_28
	local var_4_29
	local var_4_30 = var_4_23
	local var_4_31 = var_4_25 + var_4_22
	local var_4_32 = var_4_24 + var_4_23
	local var_4_33 = var_4_22

	if arg_4_0.direction_ == display.LEFT_TO_RIGHT then
		var_4_26 = var_4_30
		var_4_27 = var_4_33
		var_4_28, var_4_29 = 1, 0
	elseif arg_4_0.direction_ == display.RIGHT_TO_LEFT then
		var_4_26 = var_4_32
		var_4_27 = var_4_33
		var_4_28, var_4_29 = -1, 0
	elseif arg_4_0.direction_ == display.TOP_TO_BOTTOM then
		var_4_26 = var_4_30
		var_4_27 = var_4_31
		var_4_28, var_4_29 = 0, -1
	elseif arg_4_0.direction_ == display.BOTTOM_TO_TOP then
		var_4_26 = var_4_30
		var_4_27 = var_4_33
		var_4_28, var_4_29 = 0, 1
	else
		printError("UIBoxLayout:apply() - invalid direction %s", tostring(arg_4_0.direction_))

		return
	end

	if iskindof(arg_4_1, "UILayout") then
		local var_4_34, var_4_35 = arg_4_1:getPosition()

		var_4_26 = var_4_26 + var_4_34
		var_4_27 = var_4_27 + var_4_35
	end

	local var_4_36 = var_4_24 - var_4_4
	local var_4_37 = var_4_36
	local var_4_38 = var_4_25 - var_4_5
	local var_4_39 = var_4_38
	local var_4_40 = #var_4_8
	local var_4_41 = 0
	local var_4_42 = 0
	local var_4_43 = {}

	for iter_4_2, iter_4_3 in ipairs(var_4_8) do
		local var_4_44
		local var_4_45

		if var_4_1 then
			if iter_4_3.width then
				var_4_44 = iter_4_3.width
			else
				if iter_4_2 ~= var_4_40 then
					var_4_44 = iter_4_3.weight / var_4_2 * var_4_36
				else
					var_4_44 = var_4_37
				end

				var_4_37 = var_4_37 - var_4_44
			end

			if iter_4_2 == var_4_40 then
				local var_4_46 = var_4_44
			end

			var_4_45 = iter_4_3.height or var_4_7
		else
			if iter_4_3.height then
				var_4_45 = iter_4_3.height
			else
				if iter_4_2 ~= var_4_40 then
					var_4_45 = iter_4_3.weight / var_4_3 * var_4_38
				else
					var_4_45 = var_4_39
				end

				var_4_39 = var_4_39 - var_4_45
			end

			if iter_4_2 == var_4_40 then
				local var_4_47 = var_4_45
			end

			var_4_44 = iter_4_3.width or var_4_6
		end

		local var_4_48
		local var_4_49
		local var_4_50 = iter_4_3.widget
		local var_4_51, var_4_52, var_4_53, var_4_54 = var_4_50:getLayoutMargin()

		if iter_4_3.width then
			var_4_44 = var_4_44 + var_4_54 + var_4_52
		end

		local var_4_55 = var_4_44 - var_4_54 - var_4_52

		if iter_4_3.height then
			var_4_49 = var_4_45 + var_4_51 + var_4_53
		else
			var_4_49 = var_4_45 - var_4_51 - var_4_53
		end

		local var_4_56 = var_4_26 + var_4_54

		if arg_4_0.direction_ == display.RIGHT_TO_LEFT then
			var_4_56 = var_4_26 - var_4_52
		end

		local var_4_57 = var_4_27 + var_4_53

		if arg_4_0.direction_ == display.TOP_TO_BOTTOM then
			var_4_57 = var_4_27 - var_4_51
		end

		local var_4_58 = var_4_50:getAnchorPoint()

		if var_4_1 then
			var_4_56 = var_4_56 + var_4_55 * var_4_58.x
			var_4_57 = var_4_57 + var_4_7 * var_4_58.y
		else
			var_4_56 = var_4_56 + var_4_6 * var_4_58.x
			var_4_57 = var_4_57 + var_4_49 * var_4_58.y
		end

		var_4_50:setPosition(var_4_56, var_4_57)

		var_0_2 = var_0_2 + 1

		var_4_50:setLayoutSize(var_4_55, var_4_49)

		var_0_2 = var_0_2 - 1
		var_4_43[#var_4_43 + 1] = {
			width = var_4_55,
			height = var_4_49
		}

		if var_4_1 then
			var_4_26 = var_4_26 + var_4_44 * var_4_28
		else
			var_4_27 = var_4_27 + var_4_45 * var_4_29
		end
	end

	if arg_4_0.direction_ == display.TOP_TO_BOTTOM then
		for iter_4_4, iter_4_5 in ipairs(var_4_8) do
			local var_4_59 = iter_4_5.widget

			var_4_59:setPositionY(var_4_59:getPositionY() - var_4_43[iter_4_4].height)
		end
	elseif arg_4_0.direction_ == display.RIGHT_TO_LEFT then
		for iter_4_6, iter_4_7 in ipairs(var_4_8) do
			local var_4_60 = iter_4_7.widget

			var_4_60:setPositionX(var_4_60:getPositionX() - var_4_43[iter_4_6].width)
		end
	end

	var_0_2 = var_0_2 + 1

	for iter_4_8, iter_4_9 in ipairs(var_4_8) do
		local var_4_61 = iter_4_9.widget

		if iskindof(var_4_61, "UILayout") then
			var_4_61:apply()
		end
	end

	var_0_2 = var_0_2 - 1
end

return var_0_1
