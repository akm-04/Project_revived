local var_0_0 = import(".htmlparser")
local var_0_1 = import(".LabelTTFEx")
local var_0_2 = class("RichTextEx", function()
	return ccui.RichText:create()
end)
local var_0_3 = string
local var_0_4 = ipairs
local var_0_5 = tonumber
local var_0_6 = "0_UIPic/gamefont.TTF"
local var_0_7 = 24
local var_0_8 = cc.c3b(255, 255, 255)

local function var_0_9(arg_2_0)
	local var_2_0 = 0
	local var_2_1 = 0
	local var_2_2 = 0

	if #arg_2_0 == 4 then
		var_2_0 = var_0_5(var_0_3.rep(var_0_3.sub(arg_2_0, 2, 2), 2), 16)
		var_2_1 = var_0_5(var_0_3.rep(var_0_3.sub(arg_2_0, 3, 3), 2), 16)
		var_2_2 = var_0_5(var_0_3.rep(var_0_3.sub(arg_2_0, 4, 4), 2), 16)
	elseif #arg_2_0 == 7 then
		var_2_0 = var_0_5(var_0_3.sub(arg_2_0, 2, 3), 16)
		var_2_1 = var_0_5(var_0_3.sub(arg_2_0, 4, 5), 16)
		var_2_2 = var_0_5(var_0_3.sub(arg_2_0, 6, 7), 16)
	end

	return cc.c3b(var_2_0, var_2_1, var_2_2)
end

function var_0_2.ctor(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = var_0_0.parse(arg_3_1)

	arg_3_0._callback = arg_3_2

	arg_3_0:render(var_3_0.nodes)
end

function var_0_2.render(arg_4_0, arg_4_1)
	local function var_4_0(arg_5_0, arg_5_1, arg_5_2)
		arg_5_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
			if arg_6_0.name == "began" then
				return true
			end

			if arg_6_0.name == "ended" and arg_4_0._callback then
				arg_4_0._callback(arg_5_1, arg_5_2)
			end
		end)
		arg_5_0:setTouchEnabled(true)
	end

	local var_4_1 = {
		t = function(arg_7_0)
			local var_7_0 = arg_7_0.attributes.f or var_0_6
			local var_7_1 = var_0_7

			if arg_7_0.attributes.s then
				var_7_1 = var_0_5(arg_7_0.attributes.s)
			end

			local var_7_2 = var_0_8

			if arg_7_0.attributes.c then
				var_7_2 = var_0_9(arg_7_0.attributes.c)
			end

			local var_7_3 = var_0_1.new(arg_7_0:getcontent(), var_7_0, var_7_1, var_7_2)

			if arg_7_0.attributes.id then
				var_4_0(var_7_3, arg_7_0.attributes.id, arg_7_0:getcontent())
				var_7_3:enableUnderLine()
			end

			return ccui.RichElementCustomNode:create(0, display.COLOR_WHITE, 255, var_7_3)
		end,
		i = function(arg_8_0)
			local var_8_0 = 0
			local var_8_1 = arg_8_0.attributes.s

			if var_0_3.byte(var_8_1, 1) == 35 then
				var_8_1 = var_0_3.sub(var_8_1, 2)
				var_8_0 = 1
			end

			local var_8_2 = ccui.ImageView:create(arg_8_0.attributes.s, var_8_0)
			local var_8_3 = var_8_2:getContentSize()

			if arg_8_0.attributes.w then
				var_8_3.width = var_0_5(arg_8_0.attributes.w)
			end

			if arg_8_0.attributes.h then
				var_8_3.height = var_0_5(arg_8_0.attributes.h)
			end

			var_8_2:ignoreContentAdaptWithSize(false)
			var_8_2:setContentSize(var_8_3)

			if arg_8_0.attributes.id then
				var_4_0(var_8_2, arg_8_0.attributes.id, var_8_1)
			end

			return ccui.RichElementCustomNode:create(0, display.COLOR_WHITE, 255, var_8_2)
		end,
		br = function(arg_9_0)
			return ccui.RichElementNewLine:create(0, display.COLOR_WHITE, 255)
		end
	}

	for iter_4_0, iter_4_1 in var_0_4(arg_4_1) do
		local var_4_2 = var_4_1[iter_4_1.name](iter_4_1)

		arg_4_0:pushBackElement(var_4_2)
	end
end

return var_0_2
