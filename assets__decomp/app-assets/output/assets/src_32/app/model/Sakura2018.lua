local var_0_0 = class("Sakura", import(".BaseModel"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.outlineColor = cc.c4b(108, 24, 187, 255)
	arg_1_0.outlineSize = 1.2
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1)
	local var_3_0 = {
		activity_id = xyd.Activities.Sakura2018
	}

	xyd.Backend.get():request(xyd.mid.LOAD_SINGLE_ACTIVITY, var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			if arg_4_1 then
				arg_3_0.activity = arg_4_1
				arg_3_0.details = arg_3_0.activity.details
			end

			if arg_3_1 then
				arg_3_1(arg_4_0, arg_4_1)
			end
		end
	end)
end

function var_0_0.updateUsedItems(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0.details.base_info.used_items

	for iter_5_0 = 1, #var_5_0 do
		if var_5_0[iter_5_0] == arg_5_1 then
			return
		end
	end

	table.insert(arg_5_0.details.base_info.used_items, arg_5_1)
end

function var_0_0.isItemMaked(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0.details.base_info.used_items

	for iter_6_0 = 1, #var_6_0 do
		if var_6_0[iter_6_0] == arg_6_1 then
			return true
		end
	end

	return false
end

function var_0_0.composeItem(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.SAKURA2018_COMPOSE_ITEM, var_7_0, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			arg_7_0:updateUsedItems(var_7_0.item_id)

			local var_8_0 = xyd.tables.activitySakura3Cook:material(var_7_0.item_id)

			for iter_8_0 = 1, #var_8_0 do
				local var_8_1 = {
					itemNum = 1,
					itemID = var_8_0[iter_8_0]
				}

				arg_7_0.backpack:removeItem(var_8_1)
			end

			arg_7_0:handleResponse(arg_8_1)
		end

		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.handleResponse(arg_9_0, arg_9_1)
	if arg_9_1.base_info then
		arg_9_0.details.base_info = arg_9_1.base_info
	end

	if arg_9_1.buy_times then
		arg_9_0.details.buy_times = arg_9_1.buy_times
	end
end

function var_0_0.createMaterialsItemContent(arg_10_0, arg_10_1)
	local var_10_0 = display.newNode()
	local var_10_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/sakura/fruit_factory/material_item.csb")
	local var_10_2 = var_10_1:getChildByName("container")

	if arg_10_0.backpack:getItemNumByID(arg_10_1) > 0 then
		var_10_2:getChildByName("cover"):setVisible(false)
		xyd.setItemBorder(var_10_2:getChildByName("icon_container"), arg_10_1)
	else
		xyd.setItemBorder(var_10_2:getChildByName("icon_container"), arg_10_1, nil, true)
	end

	var_10_2:getChildByName("name_txt"):setString(xyd.tables.item:name(arg_10_1))
	var_10_2:getChildByName("own_text"):setString(var_0_1:translation("OWN_TEXT1"))
	var_10_2:getChildByName("own_num_txt"):setString(arg_10_0.backpack:getItemNumByID(arg_10_1))
	var_10_2:getChildByName("name_txt"):enableOutline(arg_10_0.outlineColor, arg_10_0.outlineSize)
	var_10_2:getChildByName("own_text"):enableOutline(arg_10_0.outlineColor, arg_10_0.outlineSize)
	var_10_2:getChildByName("own_num_txt"):enableOutline(arg_10_0.outlineColor, arg_10_0.outlineSize)
	var_10_1:addTo(var_10_0)
	var_10_1:setAnchorPoint(cc.p(0, 0))
	var_10_0:setContentSize(var_10_2:getContentSize())
	var_10_1:setName("source")

	return var_10_0
end

function var_0_0.getReward(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1 or {}

	var_11_0.activity_id = xyd.Activities.Sakura2018

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_REWARD, var_11_0, function(arg_12_0, arg_12_1)
		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.hideWindows(arg_13_0)
	local var_13_0 = {
		"main_scene_top",
		"main_scene_bottom"
	}

	for iter_13_0, iter_13_1 in pairs(var_13_0) do
		local var_13_1 = xyd.WindowManager.get():getWindow(iter_13_1)

		if var_13_1 and not tolua.isnull(var_13_1) then
			var_13_1:setVisible(false)
		end
	end
end

return var_0_0
