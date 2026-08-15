local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.chargeList
local var_0_3 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.buyTimes = arg_1_0.activity.details.buy_count
	arg_1_0.gifts = xyd.tables.misc.activityGoogleAdChargeId
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
	var_2_0:setPosition(0, 0)

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0.container:getChildByName("tip"):setString(var_0_1:translation("GIFT_BAG_TIP"))

	for iter_2_0 = 1, 2 do
		local var_2_1 = arg_2_0.container:getChildByName("button" .. iter_2_0)

		var_2_1:addTouchEventListener(function(arg_3_0, arg_3_1)
			if arg_3_1 == ccui.TouchEventType.began then
				var_2_1:setBrightStyle(ccui.BrightStyle.highlight)
			elseif arg_3_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				var_2_1:setBrightStyle(ccui.BrightStyle.normal)
				xyd.WindowManager.get():openWindow("woolen_rule", iter_2_0)
			end
		end)
	end

	for iter_2_1 = 1, 2 do
		local var_2_2 = arg_2_0.buyTimes[iter_2_1]
		local var_2_3 = arg_2_0.container:getChildByName("item" .. iter_2_1)
		local var_2_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1163/item.csb")
		local var_2_5 = var_2_4:getChildByName("container")

		var_2_4:setAnchorPoint(cc.p(0.5, 0.5))
		var_2_4:addTo(var_2_3)
		var_2_5:getChildByName("price1"):setString(var_0_2:charge(arg_2_0.gifts[iter_2_1]))
		var_2_5:getChildByName("price2"):setString(var_0_2:charge(arg_2_0.gifts[iter_2_1]) - 60)

		local var_2_6 = xyd.AssetLoader:get():loadSprite("images/border-white.png")
		local var_2_7 = xyd.AssetLoader:get():loadSprite("windows/activities/1163/icon" .. iter_2_1 .. ".png")

		var_2_7:addTo(var_2_5:getChildByName("icon_pos"))
		var_2_7:setScale(0.8)
		var_2_6:addTo(var_2_5:getChildByName("icon_pos"))
		var_2_6:setScale(0.8)

		if var_2_2 == 0 then
			var_2_5:getChildByName("buy_btn"):setBright(true)
			var_2_5:getChildByName("buy_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
				if arg_4_1 == ccui.TouchEventType.ended then
					local var_4_0 = {
						chargeId = arg_2_0.gifts[iter_2_1],
						giftId = var_0_2:gift(arg_2_0.gifts[iter_2_1]),
						price = var_0_2:charge(arg_2_0.gifts[iter_2_1]),
						giftbagName = var_0_2:name(arg_2_0.gifts[iter_2_1]),
						iosProductId = var_0_2:iosProductId(arg_2_0.gifts[iter_2_1])
					}

					xyd.WindowManager.get():openWindow("woolen", var_4_0)
					xyd.WindowManager.get():closeWindow("activities")
				end
			end)
		else
			var_2_5:getChildByName("buy_btn"):setBright(false)
		end
	end
end

return var_0_0
