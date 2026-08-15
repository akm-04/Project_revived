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
	arg_3_0.container:getChildByName("btn_rule"):getChildByName("text_rule"):setString(var_0_1:translation("RULE_STATEMENT"))
	arg_3_0.container:getChildByName("btn_rule"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("skin_warmup_new_tip")
		end
	end)

	local var_3_0 = arg_3_0.container:getChildByName("bg_content")

	var_3_0:getChildByName("discount"):setString(arg_3_0.details.server_discount * 10)

	local var_3_1 = arg_3_0.details.preorder_discount

	if var_3_1 > 0 then
		var_3_0:getChildByName("word_no_discount"):setVisible(false)
		var_3_0:getChildByName("discount_num"):setString(var_3_1)
	else
		var_3_0:getChildByName("word_discount"):setVisible(false)
		var_3_0:getChildByName("discount_num"):setVisible(false)
	end

	local var_3_2 = arg_3_0.baseInfo.is_award == 1
	local var_3_3 = var_3_0:getChildByName("bg_info")

	var_3_3:getChildByName("line"):setVisible(false)

	local var_3_4 = var_3_3:getChildByName("node_buy")
	local var_3_5 = var_3_3:getChildByName("node_has_buy")

	var_3_4:setVisible(not var_3_2)
	var_3_5:setVisible(var_3_2)

	if var_3_2 then
		var_3_3:getChildByName("text_origin_price"):setVisible(false)
	else
		local var_3_6 = var_0_2:price(arg_3_0.skinItem)
		local var_3_7 = math.floor(var_3_6 * arg_3_0.details.server_discount - var_3_1)

		var_3_3:getChildByName("text_origin_price"):setString(string.format(var_0_1:translation("ACTIVITY_WARM_UP_NEW_TEXT_11"), var_3_7))
		var_3_4:getChildByName("text_price"):setString(string.format(var_0_1:translation("ACTIVITY_WARM_UP_NEW_TEXT_12"), arg_3_0.baseInfo.charge))

		local var_3_8 = var_3_4:getChildByName("btn_get")

		var_3_8:getChildByName("text_get"):setString(var_0_1:translation("OBTAIN"))

		if var_3_7 <= arg_3_0.baseInfo.charge then
			var_3_8:getChildByName("text_get"):setColor(cc.c4b(52, 54, 55, 255))
			var_3_8:addTouchEventListener(function(arg_5_0, arg_5_1)
				xyd.buttonScaleAnim(arg_5_0, arg_5_1)

				if arg_5_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()
					arg_3_0.activitiesModel:getActivityReward(xyd.Activities.SkinWarmUpNew2, nil, function(arg_6_0, arg_6_1)
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
			var_3_8:getChildByName("text_get"):setColor(cc.c4b(52, 54, 55, 255))
			var_3_8:setBright(false)
		end
	end
end

return var_0_0
