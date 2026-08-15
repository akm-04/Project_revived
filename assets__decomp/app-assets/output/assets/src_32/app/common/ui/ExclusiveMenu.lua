local var_0_0 = class("ExclusiveMenu", function()
	return display.newLayer()
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0._subItems = {}

	arg_2_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(arg_2_0, arg_2_0.onTouch_))
end

function var_0_0.addItem(arg_3_0, arg_3_1)
	local var_3_0 = #arg_3_0._subItems

	table.insert(arg_3_0._subItems, arg_3_1)
	arg_3_0:addChild(arg_3_1, var_3_0)
end

function var_0_0.removeItems(arg_4_0, arg_4_1)
	if arg_4_1 > #arg_4_0._subItems then
		return
	end

	if arg_4_1 == arg_4_0._selectedIndex then
		arg_4_0._selectedIndex = nil
	end

	table.remove(arg_4_0._subItems, arg_4_1)
end

function var_0_0.getSelectedItem(arg_5_0)
	if arg_5_0._selectedIndex then
		return arg_5_0._subItems[arg_5_0._selectedIndex]
	else
		return nil
	end
end

function var_0_0.getSelectedIndex(arg_6_0)
	return arg_6_0._selectedIndex
end

function var_0_0.setSelectedIndex(arg_7_0, arg_7_1)
	if arg_7_1 ~= arg_7_0._selectedIndex then
		if arg_7_0._selectedIndex then
			arg_7_0._subItems[arg_7_0._selectedIndex]:setSelectedIndex(0)
		end

		arg_7_0._selectedIndex = arg_7_1

		if arg_7_1 then
			arg_7_0._subItems[arg_7_1]:activate()
		end
	end
end

function var_0_0.unselectAll(arg_8_0)
	local var_8_0 = arg_8_0._subItems
	local var_8_1 = arg_8_0._selectedIndex

	if arg_8_0._selectedIndex then
		arg_8_0._subItems[arg_8_0._selectedIndex]:setSelectedIndex(0)

		arg_8_0._selectedIndex = nil
	end
end

function var_0_0.getItemForTouch_(arg_9_0, arg_9_1, arg_9_2)
	for iter_9_0, iter_9_1 in pairs(arg_9_0._subItems) do
		if iter_9_1:isVisible() then
			local var_9_0 = iter_9_1:getBoundingBox()
			local var_9_1 = iter_9_1:convertToNodeSpace(cc.p(arg_9_1, arg_9_2))

			var_9_0.x, var_9_0.y = 0, 0

			if cc.rectContainsPoint(var_9_0, var_9_1) then
				return iter_9_0
			end
		end
	end

	return nil
end

function var_0_0.onTouch_(arg_10_0, arg_10_1)
	if arg_10_1.name == "began" then
		local var_10_0 = arg_10_0:getItemForTouch_(arg_10_1.x, arg_10_1.y)

		if not var_10_0 then
			return false
		end

		arg_10_0._tempSelectedIndex = var_10_0

		arg_10_0._subItems[var_10_0]:selected()

		return true
	elseif arg_10_1.name == "moved" then
		local var_10_1 = arg_10_0:getItemForTouch_(arg_10_1.x, arg_10_1.y)

		if var_10_1 == arg_10_0._tempSelectedIndex then
			return
		end

		if arg_10_0._tempSelectedIndex then
			arg_10_0._subItems[arg_10_0._tempSelectedIndex]:unselected()
		end

		arg_10_0._tempSelectedIndex = var_10_1

		if var_10_1 then
			arg_10_0._subItems[var_10_1]:selected()
		end
	elseif arg_10_1.name == "ended" then
		local var_10_2 = arg_10_0:getItemForTouch_(arg_10_1.x, arg_10_1.y)

		if arg_10_0._tempSelectedIndex then
			arg_10_0._subItems[arg_10_0._tempSelectedIndex]:unselected()

			arg_10_0._tempSelectedIndex = nil
		end

		if var_10_2 and var_10_2 ~= arg_10_0._selectedIndex then
			arg_10_0:setSelectedIndex(var_10_2)
		end
	elseif arg_10_1.name == "cancelled" and arg_10_0._tempSelectedIndex then
		arg_10_0._subItems[arg_10_0._tempSelectedIndex]:unselected()

		arg_10_0._tempSelectedIndex = nil
	end
end

function var_0_0.getItemAtIndex(arg_11_0, arg_11_1)
	return arg_11_0._subItems[arg_11_1]
end

function var_0_0.clear(arg_12_0, arg_12_1)
	arg_12_0:removeAllChildren(arg_12_1)

	arg_12_0._subItems = {}
	arg_12_0._selectedIndex = nil
end

return var_0_0
