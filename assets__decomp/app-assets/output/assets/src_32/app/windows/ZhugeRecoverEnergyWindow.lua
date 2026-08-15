local var_0_0 = class("ZhugeRecoverEnergyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 100

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.curNum_ = 0
	arg_1_0.maxNum_ = 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0.backpack:getItemNumByID(xyd.tables.misc.zhugeRecoverEnergyItem)
	local var_3_1 = xyd.tables.misc.zhugeRecoverEnergyCost

	if var_3_0 > 0 then
		arg_3_0.maxNum_ = var_3_0
	else
		arg_3_0.maxNum_ = math.ceil(arg_3_0.selfPlayer.crystal / var_3_1)

		if arg_3_0.maxNum_ > var_0_2 then
			arg_3_0.maxNum_ = var_0_2
		end
	end

	arg_3_0:updateNum()

	local var_3_2 = ""

	if var_3_0 > 0 then
		var_3_2 = var_0_1:translation("ZHUGE_ADVENTURE_TIPS_38")
	else
		var_3_2 = var_0_1:translation("ZHUGE_ADVENTURE_TIPS_39")
	end

	arg_3_0:nodeByName("text_tips"):setString(var_3_2)
	arg_3_0:nodeByName("btn_max"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0.curNum_ = arg_3_0.maxNum_

			arg_3_0:updateNum()
		end
	end)
	arg_3_0:nodeByName("btn_sure"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = xyd.tables.misc.zhugeRecoverEnergy
			local var_5_1 = xyd.tables.misc.zhugeRecoverEnergyCost
			local var_5_2 = ""

			if var_3_0 > 0 then
				var_5_2 = string.format(var_0_1:translation("ZHUGE_ADVENTURE_TIPS_1"), arg_3_0.curNum_, var_5_0 * arg_3_0.curNum_)
			else
				var_5_2 = string.format(var_0_1:translation("ZHUGE_ADVENTURE_TIPS_2"), arg_3_0.curNum_ * var_5_1, var_5_0 * arg_3_0.curNum_)
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_2, function()
				arg_3_0.zhugeModel:recoverEnergy(2, arg_3_0.curNum_, function(arg_7_0, arg_7_1)
					if arg_7_0 == xyd.error.OK then
						if arg_7_1.cost_type ~= xyd.Currency.CRYSTAL then
							local var_7_0 = {
								itemNum = arg_3_0.curNum_,
								itemID = xyd.tables.misc.zhugeRecoverEnergyItem
							}

							arg_3_0.backpack:removeItem(var_7_0)
						end

						local var_7_1 = xyd.WindowManager.get():getWindow("zhuge_forest_sweep")

						if var_7_1 and not tolua.isnull(var_7_1) then
							var_7_1:updateEnergy()
						end

						xyd.WindowManager.get():closeWindow(arg_3_0)
					end
				end)
			end, nil, nil, arg_3_0.colorMode)
		end
	end)
	arg_3_0:nodeByName("btn_del"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			arg_8_0:setScale(0.9)
		elseif arg_8_1 == ccui.TouchEventType.moved then
			arg_8_0:setScale(1)
		elseif arg_8_1 == ccui.TouchEventType.ended then
			arg_8_0:setScale(1)

			if arg_3_0.curNum_ > 1 then
				arg_3_0.curNum_ = arg_3_0.curNum_ - 1

				arg_3_0:updateNum()
			end
		end
	end)
	arg_3_0:nodeByName("btn_add"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.began then
			arg_9_0:setScale(0.9)
		elseif arg_9_1 == ccui.TouchEventType.moved then
			arg_9_0:setScale(1)
		elseif arg_9_1 == ccui.TouchEventType.ended then
			arg_9_0:setScale(1)

			if arg_3_0.curNum_ < arg_3_0.maxNum_ then
				arg_3_0.curNum_ = arg_3_0.curNum_ + 1

				arg_3_0:updateNum()
			end
		end
	end)
end

function var_0_0.didOpen(arg_10_0, arg_10_1)
	var_0_0.super:didOpen(arg_10_1)
	arg_10_0:addBlockLayer()
end

function var_0_0.updateNum(arg_11_0)
	local var_11_0 = arg_11_0.backpack:getItemNumByID(xyd.tables.misc.zhugeRecoverEnergyItem)
	local var_11_1 = xyd.tables.misc.zhugeRecoverEnergy
	local var_11_2 = xyd.tables.misc.zhugeRecoverEnergyCost
	local var_11_3 = var_11_0

	if var_11_0 <= 0 then
		var_11_3 = math.ceil(arg_11_0.selfPlayer.crystal / var_11_2)

		if var_11_3 > var_0_2 then
			var_11_3 = var_0_2
		end
	end

	arg_11_0:nodeByName("use_num_txt"):setString(arg_11_0.curNum_ .. "/" .. var_11_3)
end

return var_0_0
