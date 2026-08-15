local var_0_0 = class("ZhangheDollDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityZhangheDollShop
local var_0_3 = xyd.tables.item
local var_0_4 = 50001482

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.idx = arg_1_2.idx
	arg_1_0.item_index = arg_1_2.item_index
	arg_1_0.last_times = arg_1_2.last_times
	arg_1_0.price = var_0_2:dollCost(arg_1_0.item_index)
	arg_1_0.item_id = var_0_2:itemID(arg_1_0.item_index)
	arg_1_0.item_name = var_0_3:name(arg_1_0.item_id)
	arg_1_0.gift_num = 1
	arg_1_0.maxGiftNum = 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("max_btn_txt"):setString(var_0_1:translation("MAX"))
	arg_4_0:nodeByName("gift_num_label"):setString(var_0_1:translation("ZHANGHE_DOLL_DETAIL_GIFT_NUM_LABEL"))
	arg_4_0:nodeByName("item_num_label"):setString(string.format(var_0_1:translation("ZHANGHE_DOLL_DETAIL_ITEM_NUM_LABEL"), arg_4_0.price))
	arg_4_0:nodeByName("item_name"):setString(arg_4_0.item_name)
	xyd.setItemBorder(arg_4_0:nodeByName("item_icon"), arg_4_0.item_id)
	arg_4_0:updateNums()
	arg_4_0:setupButtons()
end

function var_0_0.setupButtons(arg_5_0)
	arg_5_0:nodeByName("minus_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			arg_6_0:setScale(0.9)
		elseif arg_6_1 == ccui.TouchEventType.moved then
			arg_6_0:setScale(1)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			arg_6_0:setScale(1)

			arg_5_0.gift_num = arg_5_0.gift_num - 1

			if arg_5_0.gift_num <= 0 then
				arg_5_0.gift_num = 1
			end

			arg_5_0:updateNums()
		end
	end)
	arg_5_0:nodeByName("plus_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			arg_7_0:setScale(0.9)
		elseif arg_7_1 == ccui.TouchEventType.moved then
			arg_7_0:setScale(1)
		elseif arg_7_1 == ccui.TouchEventType.ended then
			arg_7_0:setScale(1)

			arg_5_0.gift_num = arg_5_0.gift_num + 1

			if arg_5_0.gift_num > arg_5_0.maxGiftNum then
				arg_5_0.gift_num = arg_5_0.maxGiftNum
			end

			arg_5_0:updateNums()
		end
	end)
	arg_5_0:nodeByName("max_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			arg_8_0:setScale(0.9)
		elseif arg_8_1 == ccui.TouchEventType.moved then
			arg_8_0:setScale(1)
		elseif arg_8_1 == ccui.TouchEventType.ended then
			arg_8_0:setScale(1)

			arg_5_0.gift_num = arg_5_0.maxGiftNum

			arg_5_0:updateNums()
		end
	end)
	arg_5_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.began then
			arg_9_0:setScale(0.9)
		elseif arg_9_1 == ccui.TouchEventType.moved then
			arg_9_0:setScale(1)
		elseif arg_9_1 == ccui.TouchEventType.ended then
			arg_9_0:setScale(1)
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)
	arg_5_0:nodeByName("confirm_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.began then
			arg_10_0:setScale(0.9)
		elseif arg_10_1 == ccui.TouchEventType.moved then
			arg_10_0:setScale(1)
		elseif arg_10_1 == ccui.TouchEventType.ended then
			arg_10_0:setScale(1)
			xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):getActivityReward2(xyd.Activities.ZhangheDoll, arg_5_0.idx, arg_5_0.gift_num, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					arg_5_0.selfPlayer:handleRewards(arg_11_1.awards)
					arg_5_0.selfPlayer:getBackpack():addItemsByID(var_0_4, -var_0_2:dollCost(arg_5_0.item_index) * arg_5_0.gift_num)

					if arg_5_0.selfPlayer:getBackpack():getItemNumByID(var_0_4) <= 0 then
						local var_11_0 = {
							itemID = var_0_4
						}

						var_11_0.itemNum = 1

						arg_5_0.selfPlayer:getBackpack():removeItem(var_11_0)
					end

					local var_11_1 = xyd.WindowManager.get():getWindow("zhanghe_doll_exchange")

					if var_11_1 then
						var_11_1.details.is_awarded = arg_11_1.base_info.is_awarded

						var_11_1.list:refreshList()
					end

					if arg_5_0 and not tolua.isnull(arg_5_0) then
						xyd.WindowManager.get():closeWindow(arg_5_0)
					end
				end
			end)
		end
	end)
end

function var_0_0.updateNums(arg_12_0)
	arg_12_0.maxGiftNum = math.floor(arg_12_0.selfPlayer:getBackpack():getItemNumByID(var_0_4) / var_0_2:dollCost(arg_12_0.item_index))

	if arg_12_0.last_times then
		arg_12_0.maxGiftNum = math.min(arg_12_0.last_times, arg_12_0.maxGiftNum)
	end

	arg_12_0:nodeByName("item_num_label"):setString(string.format(var_0_1:translation("ZHANGHE_DOLL_DETAIL_ITEM_NUM_LABEL"), arg_12_0.price * arg_12_0.gift_num))

	if arg_12_0.gift_num > arg_12_0.maxGiftNum then
		arg_12_0.gift_num = arg_12_0.maxGiftNum
	end

	arg_12_0:nodeByName("gift_num"):setString(tostring(arg_12_0.gift_num) .. "/" .. arg_12_0.maxGiftNum)
end

return var_0_0
