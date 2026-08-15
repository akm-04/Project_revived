local var_0_0 = class("HunqiStrengthenResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.oldItem = arg_1_2.oldItem
	arg_1_0.newItem = arg_1_2.newItem
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("word_3"):setVisible(false)
	arg_4_0:nodeByName("star"):setVisible(false)
	arg_4_0:nodeByName("light"):setVisible(false)

	local var_4_0 = xyd.createEffect("skeletons/ui_effect/hunqi/shengjichenggong")

	var_4_0:addTo(arg_4_0)
	var_4_0:setPosition(628, arg_4_0:nodeByName("word_3"):getPositionY() - 190)
	var_4_0:setVisible(false)
	arg_4_0:performWithDelay(function()
		var_4_0:setVisible(true)
		var_4_0:play(function()
			var_4_0:play(nil, true, nil, "texiao02")
		end, false, nil, "texiao01")
	end, 0.1)

	local var_4_1 = {
		noBorder = true,
		noLev = true,
		container = arg_4_0:nodeByName("icon"),
		item = arg_4_0.newItem
	}

	xyd.setHunqiBorder(var_4_1)
	arg_4_0:nodeByName("old_lev"):setString("LV." .. arg_4_0.oldItem.lev)
	arg_4_0:nodeByName("new_lev"):setString("LV." .. arg_4_0.newItem.lev)
	arg_4_0:nodeByName("text_ok"):setString(var_0_1:translation("OK"))
	arg_4_0:nodeByName("btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playCloseSound()
			arg_4_0:close()
		end
	end)

	local var_4_2 = arg_4_0:nodeByName("item_container"):getHeight()
	local var_4_3 = 51
	local var_4_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/hunqi/strengthen_item.csb")
	local var_4_5 = var_4_4:getChildByName("container")
	local var_4_6
	local var_4_7

	if xyd.tables.attr:isPercent(arg_4_0.newItem.main_attr) then
		var_4_6 = arg_4_0.oldItem.main_attr_value / 100 .. "%"
		var_4_7 = arg_4_0.newItem.main_attr_value / 100 .. "%"
	else
		var_4_6 = arg_4_0.oldItem.main_attr_value
		var_4_7 = arg_4_0.newItem.main_attr_value
	end

	var_4_5:getChildByName("name"):setString(xyd.tables.attr:name(arg_4_0.newItem.main_attr))
	var_4_5:getChildByName("old_num"):setString(var_4_6)
	var_4_5:getChildByName("new_num"):setString(var_4_7)
	var_4_4:addTo(arg_4_0:nodeByName("item_container"))
	var_4_4:setPositionY(var_4_2 - 26)

	local var_4_8 = {}

	if arg_4_0.newItem.sub then
		for iter_4_0 = 1, #arg_4_0.newItem.sub do
			local var_4_9 = arg_4_0.newItem.sub_attr[iter_4_0]
			local var_4_10 = xyd.AssetLoader.get():loadNodeFromJson("windows/hunqi/strengthen_item.csb")
			local var_4_11 = var_4_10:getChildByName("container")

			var_4_8[var_4_9] = true

			local var_4_12 = xyd.tables.attr:isPercent(var_4_9)

			if var_4_12 then
				var_4_7 = arg_4_0.newItem.sub_attr_value[iter_4_0] / 100 .. "%"
			else
				var_4_7 = arg_4_0.newItem.sub_attr_value[iter_4_0]
			end

			var_4_11:getChildByName("name"):setString(xyd.tables.attr:name(var_4_9))
			var_4_11:getChildByName("new_num"):setString(var_4_7)

			local var_4_13 = false

			if arg_4_0.oldItem.sub_attr then
				for iter_4_1, iter_4_2 in ipairs(arg_4_0.oldItem.sub_attr) do
					if var_4_9 == iter_4_2 then
						if var_4_12 then
							var_4_6 = arg_4_0.oldItem.sub_attr_value[iter_4_1] / 100 .. "%"
						else
							var_4_6 = arg_4_0.oldItem.sub_attr_value[iter_4_1]
						end

						var_4_11:getChildByName("old_num"):setString(var_4_6)

						var_4_13 = true
					end
				end
			end

			if not var_4_13 then
				var_4_6 = var_4_12 and "0%" or 0

				var_4_11:getChildByName("old_num"):setString(var_4_6)
			end

			var_4_10:addTo(arg_4_0:nodeByName("item_container"))
			var_4_10:setPositionY(var_4_2 - var_4_3 * iter_4_0 - 26)
		end
	end

	if arg_4_0.oldItem.sub then
		for iter_4_3 = 1, #arg_4_0.oldItem.sub do
			local var_4_14 = arg_4_0.oldItem.sub_attr[iter_4_3]

			if not var_4_8[var_4_14] then
				local var_4_15 = xyd.AssetLoader.get():loadNodeFromJson("windows/hunqi/strengthen_item.csb")
				local var_4_16 = var_4_15:getChildByName("container")
				local var_4_17

				if xyd.tables.attr:isPercent(var_4_14) then
					var_4_6 = arg_4_0.oldItem.sub_attr_value[iter_4_3] / 100 .. "%"
					var_4_17 = "0%"
				else
					var_4_6 = arg_4_0.oldItem.sub_attr_value[iter_4_3]
					var_4_17 = 0
				end

				var_4_16:getChildByName("name"):setString(xyd.tables.attr:name(var_4_14))
				var_4_16:getChildByName("old_num"):setString(var_4_6)
				var_4_16:getChildByName("new_num"):setString(var_4_17)
				var_4_15:addTo(arg_4_0:nodeByName("item_container"))
				var_4_15:setPositionY(var_4_2 - var_4_3 * (iter_4_3 + #arg_4_0.newItem.sub) - 26)
			end
		end
	end
end

return var_0_0
