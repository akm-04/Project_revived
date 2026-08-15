local var_0_0 = class("TipsMenu", function()
	return display.newLayer()
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0._subItems = {}

	arg_2_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(arg_2_0, arg_2_0.onTouch_))
end

function var_0_0.setTipsLayer(arg_3_0, arg_3_1)
	arg_3_0.tipsLayer_ = arg_3_1

	arg_3_1:addTo(arg_3_0)
	arg_3_1:setVisible(false)
end

function var_0_0.getItemForTouch_(arg_4_0, arg_4_1, arg_4_2)
	for iter_4_0, iter_4_1 in pairs(arg_4_0._subItems) do
		if iter_4_1:isVisible() then
			local var_4_0 = iter_4_1:getBoundingBox()
			local var_4_1 = iter_4_1:convertToNodeSpace(cc.p(arg_4_1, arg_4_2))

			var_4_0.x, var_4_0.y = 0, 0

			if cc.rectContainsPoint(var_4_0, var_4_1) then
				return iter_4_0
			end
		end
	end

	return nil
end

function var_0_0.addItem(arg_5_0, arg_5_1)
	arg_5_0._subItems = arg_5_0._subItems or {}

	table.insert(arg_5_0._subItems, arg_5_1)
	arg_5_1:addTo(arg_5_0)
end

function var_0_0.clear(arg_6_0, arg_6_1)
	arg_6_0:removeAllChildren(arg_6_1)

	arg_6_0._subItems = {}
	arg_6_0.tipsLayer_ = nil
end

function var_0_0.onTouch_(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		local var_7_0 = arg_7_0:getItemForTouch_(arg_7_1.x, arg_7_1.y)

		if not var_7_0 then
			return false
		end

		if arg_7_0.tipsLayer_ then
			arg_7_0.tipsLayer_:setVisible(true)
			arg_7_0.tipsLayer_:setTitle(arg_7_0._subItems[var_7_0]:getTitle())
			arg_7_0.tipsLayer_:addDescText(arg_7_0._subItems[var_7_0]:getDesc())
		end

		arg_7_0._tempSelectedIndex = var_7_0

		arg_7_0._subItems[var_7_0]:selected()

		return true
	elseif arg_7_1.name == "moved" then
		local var_7_1 = arg_7_0:getItemForTouch_(arg_7_1.x, arg_7_1.y)

		if var_7_1 == arg_7_0._tempSelectedIndex then
			return
		end

		if arg_7_0._tempSelectedIndex then
			arg_7_0._subItems[arg_7_0._tempSelectedIndex]:unselected()

			if arg_7_0.tipsLayer_ then
				arg_7_0.tipsLayer_:clearAllDescText()
				arg_7_0.tipsLayer_:setVisible(false)
			end
		end

		arg_7_0._tempSelectedIndex = var_7_1

		if var_7_1 then
			arg_7_0._subItems[var_7_1]:selected()

			if arg_7_0.tipsLayer_ then
				arg_7_0.tipsLayer_:setVisible(true)
				arg_7_0.tipsLayer_:setTitle(arg_7_0._subItems[var_7_1]:getTitle())
				arg_7_0.tipsLayer_:addDescText(arg_7_0._subItems[var_7_1]:getDesc())
			end
		end
	elseif arg_7_1.name == "ended" then
		local var_7_2 = arg_7_0:getItemForTouch_(arg_7_1.x, arg_7_1.y)

		if arg_7_0._tempSelectedIndex then
			arg_7_0._subItems[arg_7_0._tempSelectedIndex]:unselected()

			arg_7_0._tempSelectedIndex = nil

			if arg_7_0.tipsLayer_ then
				arg_7_0.tipsLayer_:clearAllDescText()
				arg_7_0.tipsLayer_:setVisible(false)
			end
		end
	elseif arg_7_1.name == "cancelled" and arg_7_0._tempSelectedIndex then
		arg_7_0._subItems[arg_7_0._tempSelectedIndex]:unselected()

		arg_7_0._tempSelectedIndex = nil

		if arg_7_0.tipsLayer_ then
			arg_7_0.tipsLayer_:clearAllDescText()
			arg_7_0.tipsLayer_:setVisible(false)
		end
	end
end

return var_0_0
