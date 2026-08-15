local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
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

	local var_2_1 = var_2_0:getChildByName("container")
	local var_2_2 = var_2_1:getChildByName("des_text")
	local var_2_3 = var_2_1:getChildByName("buy_btn")
	local var_2_4 = var_2_1:getChildByName("num_1")
	local var_2_5 = var_2_1:getChildByName("num_2")

	var_2_2:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	var_2_4:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	var_2_5:enableOutline(cc.c4b(0, 0, 0, 255), 1)

	arg_2_0.timeTxt = var_2_1:getChildByName("time_bg"):getChildByName("time_txt")

	local function var_2_6()
		local var_3_0 = tonumber(xyd.ServerTime.get():getServerTime())
		local var_3_1 = arg_2_0.activity.end_time - var_3_0

		if tolua.isnull(arg_2_0.timeTxt) then
			return
		end

		if var_3_1 <= 0 then
			arg_2_0.timeTxt:setString(var_0_1:translation("ACTIVITY_END"))
		end

		if var_3_0 < arg_2_0.activity.start_time then
			arg_2_0.timeTxt:setString(var_0_1:translation("ACTIVITY_NO_OPEN"))
		end

		if var_3_1 <= 0 or var_3_0 < arg_2_0.activity.start_time then
			if arg_2_0.handle then
				var_0_2.unscheduleGlobal(arg_2_0.handle)

				arg_2_0.handle = nil
			end

			return
		end

		local var_3_2 = xyd.secondsToString1(var_3_1)

		if arg_2_0.timeTxt and not tolua.isnull(arg_2_0.timeTxt) then
			arg_2_0.timeTxt:setString(var_3_2)
		end
	end

	if arg_2_0.activity.is_open == 1 then
		var_2_6()

		if not arg_2_0.handle then
			arg_2_0.handle = var_0_2.scheduleGlobal(handler(arg_2_0, var_2_6), 1)
		end
	elseif not arg_2_0.handle then
		var_0_2.unscheduleGlobal(arg_2_0.handle)

		arg_2_0.handle = nil
	end

	var_2_1:getChildByName("des_text"):setString(var_0_1:translation("SKIN_ACTIVITY_TEXT"))
	var_2_4:setString(xyd.tables.misc.skinCostYuanbao)
	var_2_5:setString(xyd.tables.misc.skinShopDiscountNum)
	var_2_3:addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = arg_2_0.activity
			local var_4_1 = xyd.ServerTime.get():getServerTime()

			if var_4_1 < var_4_0.start_time and var_4_0.is_open == 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("SKIN_NOT_OPEN")
				})

				return
			elseif var_4_1 > var_4_0.end_time and var_4_0.is_open == 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("SKIN_CLOSED")
				})

				return
			end

			if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_SKIN_SHOP) then
				xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
					xyd.WindowManager.get():openWindow("shop", {
						shop_type = xyd.ShopType.SKIN
					})
				end)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("SKIN_OPEN")
				})
			end
		end
	end)
end

return var_0_0
