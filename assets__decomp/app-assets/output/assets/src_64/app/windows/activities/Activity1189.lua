local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activitySkinWarmUpNewTable
local var_0_3 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.baseInfo = arg_1_0.details.base_info
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))

	arg_2_0.container = var_2_0:getChildByName("container")
	arg_2_0.skinItem = xyd.tables.misc:getValue("activity_skin_warmup_new_item_id")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0.container:getChildByName("bg_heat")

	var_3_0:getChildByName("text_heat"):setString(var_0_1:translation("ACTIVITY_WARM_UP_NEW_TEXT_1"))
	var_3_0:getChildByName("heat_num"):setString(arg_3_0.details.total_heat)
	var_3_0:getChildByName("text_heat"):enableOutline(cc.c4b(48, 82, 134, 255), 2)
	var_3_0:getChildByName("heat_num"):enableOutline(cc.c4b(139, 84, 65, 255), 2)
	arg_3_0.container:getChildByName("bg_price"):getChildByName("price"):setString(var_0_2:price(arg_3_0.skinItem))
	arg_3_0.container:getChildByName("btn_rule"):getChildByName("text_rule"):setString(var_0_1:translation("RULE_STATEMENT"))
	arg_3_0.container:getChildByName("btn_rule"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("skin_warmup_new_tip")
		end
	end)

	local var_3_1 = arg_3_0.container:getChildByName("bg_content")
	local var_3_2 = var_3_1:getChildByName("node_progress")
	local var_3_3 = var_0_2:heatPoint(arg_3_0.skinItem)
	local var_3_4 = var_0_2:discountPoint(arg_3_0.skinItem)

	for iter_3_0 = 1, 4 do
		var_3_2:getChildByName("node_" .. iter_3_0):setVisible(false)
		var_3_2:getChildByName("heat_point_" .. iter_3_0):setString(var_3_3[iter_3_0])
		var_3_2:getChildByName("text_heat_point_" .. iter_3_0):setString(string.format(var_0_1:translation("ACTIVITY_DACALL_DISCOUNT"), var_3_4[iter_3_0] * 10))
		var_3_2:getChildByName("heat_point_" .. iter_3_0):enableOutline(cc.c4b(255, 255, 255, 255), 2)
		var_3_2:getChildByName("text_heat_point_" .. iter_3_0):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	end

	local var_3_5 = var_3_2:getChildByName("bg_progress"):getChildByName("progress")
	local var_3_6 = var_3_3[#var_3_3]
	local var_3_7 = arg_3_0.details.total_heat

	if var_3_6 < var_3_7 then
		var_3_7 = var_3_6
	end

	local var_3_8 = var_3_7 / var_3_6

	if var_3_8 == 1 then
		var_3_5:setPercent(100)
	else
		var_3_5:setPercent(var_3_8 * 0.85 * 100)
	end

	local var_3_9 = math.floor(var_3_8 * 4)

	if var_3_9 > 0 then
		var_3_1:getChildByName("discount"):setString(var_3_4[var_3_9] * 10)
	else
		var_3_1:getChildByName("discount"):setString(10)
	end

	for iter_3_1 = 1, 4 do
		if iter_3_1 <= var_3_9 then
			var_3_2:getChildByName("node_" .. iter_3_1):setVisible(true)
		else
			break
		end
	end

	var_3_1:getChildByName("bg_charge_tip"):getChildByName("tip"):setString(string.format(var_0_1:translation("ACTIVITY_WARM_UP_NEW_TEXT_2"), var_0_2:recharge(arg_3_0.skinItem)))
	var_3_1:getChildByName("bg_charge_tip"):getChildByName("tip"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_3_1:getChildByName("bg_charge_tip"):getChildByName("tip"):getVirtualRenderer():setAdditionalKerning(-2)

	local var_3_10 = arg_3_0.baseInfo.is_award == 1
	local var_3_11 = arg_3_0.baseInfo.is_order == 1
	local var_3_12 = var_3_1:getChildByName("bg_info")
	local var_3_13 = var_3_12:getChildByName("node_award")
	local var_3_14 = var_3_12:getChildByName("node_discount")

	var_3_13:setVisible(not var_3_10)
	var_3_14:setVisible(var_3_10)

	if var_3_10 then
		var_3_14:getChildByName("discount_crystal"):setString(var_0_2:exDiscount(arg_3_0.skinItem))
	else
		local var_3_15 = var_3_13:getChildByName("award_container")

		arg_3_0:rewardFormat(var_3_15, var_0_2:gift(arg_3_0.skinItem))
		var_3_13:getChildByName("text_charge"):setString(string.format(var_0_1:translation("ACTIVITY_WARM_UP_NEW_TEXT_4"), arg_3_0.baseInfo.total_charge))
		var_3_13:getChildByName("text_charge"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
		var_3_13:getChildByName("text_charge"):getVirtualRenderer():setAdditionalKerning(-2)

		local var_3_16 = var_3_13:getChildByName("btn_get")

		var_3_16:getChildByName("text_get"):setString(var_0_1:translation("OBTAIN"))

		if var_3_11 then
			var_3_16:getChildByName("text_get"):setColor(cc.c4b(132, 54, 75, 255))
			var_3_16:addTouchEventListener(function(arg_5_0, arg_5_1)
				xyd.buttonScaleAnim(arg_5_0, arg_5_1)

				if arg_5_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()
					arg_3_0.activitiesModel:getActivityReward(xyd.Activities.SkinWarmUpNew, nil, function(arg_6_0, arg_6_1)
						if arg_6_0 == xyd.error.OK then
							arg_3_0.baseInfo = arg_6_1.base_info

							arg_3_0:layout()

							if arg_6_1 and arg_6_1.awards then
								arg_3_0.selfPlayer:handleRewards(arg_6_1.awards)
							end
						end
					end)
				end
			end)
		else
			var_3_16:getChildByName("text_get"):setColor(cc.c4b(52, 54, 55, 255))
			var_3_16:setBright(false)
		end
	end
end

return var_0_0
