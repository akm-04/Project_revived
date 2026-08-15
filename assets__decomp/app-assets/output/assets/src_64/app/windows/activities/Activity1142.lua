local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 1

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.is_open = arg_1_0.activity.is_open or 0
	arg_1_0.startTime = arg_1_0.activity.start_time
	arg_1_0.endTime = arg_1_0.activity.end_time
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	arg_2_0.serverTime = xyd.ServerTime.get():getServerTime()

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	arg_2_0.detail = var_2_0

	local var_2_1 = var_2_0:getChildByName("container")
	local var_2_2 = var_2_1:getChildByName("bg_desc"):getChildByName("desc")

	var_2_2:setString(var_0_1:translation("VALENTINE_TIPS_TXT5"))
	var_2_2:enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_2_1:getChildByName("dialog"):getChildByName("sth_to_say"):setString(var_0_1:translation("VALENTINE_TIPS_TXT13"))
	arg_2_0:registerButtons()
	arg_2_0:initItems()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0.detail):addEventListener(xyd.event.VALENTINE_ACTIVITY_UPDATE, function(arg_3_0)
		if arg_2_0.detail and not tolua.isnull(arg_2_0.detail) then
			arg_2_0:initItems()
		end
	end)
end

function var_0_0.checkActivityNotOpen(arg_4_0)
	if arg_4_0.is_open == 0 then
		local var_4_0 = ""

		if arg_4_0.startTime > arg_4_0.serverTime then
			var_4_0 = var_0_1:translation("ACTIVITY_NO_OPEN")
		elseif arg_4_0.endTime < arg_4_0.serverTime then
			var_4_0 = var_0_1:translation("ACTIVITY_FINISHED")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_4_0
		})

		return true
	end
end

function var_0_0.registerButtons(arg_5_0)
	local var_5_0 = arg_5_0.detail:getChildByName("container")
	local var_5_1 = var_5_0:getChildByName("give_btn")

	var_5_1:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			var_5_1:setScale(0.9)
		elseif arg_6_1 == ccui.TouchEventType.canceled then
			var_5_1:setScale(1)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			var_5_1:setScale(1)

			if arg_5_0:checkActivityNotOpen() then
				return
			end

			xyd.WindowManager.get():openWindow("valentine_give_gift_alert")
		end
	end)
	var_5_1:getChildByName("txt"):setString(var_0_1:translation("PRESENT_GIFT"))

	local var_5_2 = var_5_0:getChildByName("rank_btn")

	var_5_2:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			var_5_2:setScale(0.9)
		elseif arg_7_1 == ccui.TouchEventType.canceled then
			var_5_2:setScale(1)
		elseif arg_7_1 == ccui.TouchEventType.ended then
			var_5_2:setScale(1)

			if arg_5_0:checkActivityNotOpen() then
				return
			end

			xyd.Backend.get():request(xyd.mid.VALENTINE_GIFT_RANK, {}, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("valentine_gift_rank", arg_8_1.all_rank_list)
				end
			end)
		end
	end)
	var_5_2:getChildByName("txt"):setString(var_0_1:translation("PLAYER_RANK"))
	var_5_0:getChildByName("dialog"):setTouchEnabled(true)
	var_5_0:getChildByName("dialog"):setTouchSwallowEnabled(false)
	var_5_0:getChildByName("dialog"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "ended" then
			xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge, {
				chargeState = xyd.ChargeState.giftbag
			})
		end

		return true
	end)
end

function var_0_0.initItems(arg_10_0)
	local var_10_0 = arg_10_0.detail:getChildByName("container"):getChildByName("bg_list")
	local var_10_1 = xyd.tables.misc.valentinePresentItems

	for iter_10_0, iter_10_1 in pairs(var_10_1) do
		local var_10_2 = var_10_0:getChildByName("item" .. iter_10_0)
		local var_10_3 = var_10_0:getChildByName("item_desc" .. iter_10_0)

		var_10_2:setAnchorPoint(0.5, 0.5)
		var_10_2:setContentSize(95, 95)
		var_10_2:removeAllChildren()
		xyd.setItemAndAddTips(var_10_2, iter_10_1)

		local var_10_4 = arg_10_0.selfPlayer:getBackpack():getItemNumByID(iter_10_1)

		var_10_3:setString(xyd.tables.item:name(iter_10_1) .. " x " .. var_10_4)
	end
end

function var_0_0.release(arg_11_0)
	if arg_11_0.handle then
		scheduler.unscheduleGlobal(arg_11_0.handle)

		arg_11_0.handle = nil
	end
end

return var_0_0
