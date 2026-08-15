local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.needChargeCount = 0

	xyd.EventDispatcher.get():addEventListener(cc.mvc.AppBase.APP_ENTER_FOREGROUND_EVENT, handler(arg_1_0, arg_1_0.updateLive2d))
end

function var_0_0.updateLive2d(arg_2_0)
	if arg_2_0.handler then
		var_0_2.unscheduleGlobal(arg_2_0.handler)

		arg_2_0.handler = nil
	end

	if arg_2_0.live2d and arg_2_0.container and not tolua.isnull(arg_2_0.container) then
		arg_2_0.live2d:removeFromParent(true)

		arg_2_0.live2d = nil
		arg_2_0.handler = var_0_2.performWithDelayGlobal(function()
			if arg_2_0 and arg_2_0.container and not tolua.isnull(arg_2_0.container) then
				arg_2_0:addLive2dModel(arg_2_0.container)
			end
		end, 0.5)
	end
end

function var_0_0.show(arg_4_0, arg_4_1)
	var_0_0.super.show(arg_4_0, arg_4_1)

	if not arg_4_0.res or arg_4_0.res == 0 then
		print("No res available.")

		return
	end

	local var_4_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_4_0.res)

	var_4_0:addTo(arg_4_0.parent)
	var_4_0:setAnchorPoint(cc.p(0, 0))
	var_4_0:setPosition(0, 0)

	local var_4_1 = var_4_0:getChildByName("container")
	local var_4_2 = var_4_1:getChildByName("item_skin")

	arg_4_0.timer = var_4_1:getChildByName("timer")

	local var_4_3 = var_4_1:getChildByName("btn_buy")
	local var_4_4 = xyd.tables.activities:gift(arg_4_0.activity.table_id)
	local var_4_5 = xyd.tables.gift:items(var_4_4)

	if #var_4_5 == 1 and var_4_5[1] == 0 then
		var_4_5 = {}
	end

	local var_4_6 = xyd.tables.gift:itemNum(var_4_4)
	local var_4_7 = display.newNode()

	var_4_7:setContentSize(var_4_2:getContentSize().height, var_4_2:getContentSize().height)
	xyd.setItemBorder(var_4_7, var_4_5[1], false, false, var_4_6[1])
	var_4_7:addTo(var_4_2)
	var_4_7:setAnchorPoint(cc.p(0, 0))
	var_4_7:setPosition(0, 0)

	for iter_4_0 = 1, 1 do
		local var_4_8 = {
			id = var_4_5[iter_4_0],
			lev = xyd.tables.item:level(var_4_5[iter_4_0])
		}

		if xyd.tables.item:type(var_4_5[iter_4_0]) == -1 then
			var_4_8.tipsType = 0
			var_4_8.desc1 = xyd.tables.hero:getDes(var_4_5[iter_4_0])
		else
			var_4_8.tipsType = 1
			var_4_8.desc1 = xyd.tables.item:desc1(var_4_5[iter_4_0])
			var_4_8.desc2 = xyd.tables.item:desc2(var_4_5[iter_4_0])
		end

		var_4_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_4_5[iter_4_0])
		var_4_8.name = xyd.tables.item:name(var_4_5[iter_4_0])

		if iter_4_0 == 1 then
			arg_4_0:addTips(var_4_7, var_4_8)
		elseif iter_4_0 == 2 then
			-- block empty
		end
	end

	arg_4_0.timer:enableOutline(cc.c4b(255, 255, 255, 255), 3)

	function onTimer()
		local var_5_0 = xyd.ServerTime.get():getServerTime()

		if not var_5_0 then
			return
		end

		local var_5_1 = arg_4_0.activity.end_time - var_5_0

		if var_5_1 <= 0 or var_5_0 < arg_4_0.activity.start_time then
			if arg_4_0.handle then
				var_0_2.unscheduleGlobal(arg_4_0.handle)

				arg_4_0.handle = nil
			end

			return
		end

		local var_5_2 = var_5_1 / 3600 / 24
		local var_5_3 = var_5_1 / 3600
		local var_5_4 = var_5_1 % 3600 / 60
		local var_5_5 = var_5_1 % 3600 % 60
		local var_5_6 = string.format("%02d:%02d:%02d", var_5_3, var_5_4, var_5_5)

		if arg_4_0.timer and not tolua.isnull(arg_4_0.timer) then
			arg_4_0.timer:setString(var_0_1:translation("ACTIVITY_1130_TIP1") .. var_5_6)
		end
	end

	if arg_4_0.activity.is_open then
		onTimer()

		if not arg_4_0.handle then
			arg_4_0.handle = var_0_2.scheduleGlobal(handler(arg_4_0, onTimer), 1)
		end
	end

	var_4_1:getChildByName("charge_text"):setString(var_0_1:translation("ALREADY_CHARGE") .. arg_4_0.activity.details.charge)
	var_4_1:getChildByName("charge_text"):enableOutline(cc.c4b(255, 255, 255, 255), 3)

	local var_4_9 = 100 - arg_4_0.activity.details.discounts[1] * 100
	local var_4_10 = 100 - arg_4_0.activity.details.discounts[2] * 100

	var_4_1:getChildByName("personal_discount"):setString(arg_4_0.activity.details.discounts[1] * 10)
	var_4_1:getChildByName("server_discount"):setString((arg_4_0.activity.details.discounts[2] or 1) * 10)

	arg_4_0.needChargeCount = math.ceil(arg_4_0.activity.details.discounts[1] * (arg_4_0.activity.details.discounts[2] or 1) * xyd.tables.activitySkinDiscount:price(1))

	var_4_1:getChildByName("charge"):setString(arg_4_0.needChargeCount)
	var_4_3:getChildByName("charge_txt"):setString(var_0_1:translation("ACTIVITY_1130_TIP4"))
	var_4_3:getChildByName("reward_gray"):setString(var_0_1:translation("ACTIVITY_1130_TIP3"))
	var_4_3:getChildByName("reward_txt"):setString(var_0_1:translation("ACTIVITY_1130_TIP2"))
	arg_4_0:freshWords(var_4_1)
	var_4_3:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			var_4_3:setScale(0.9)
		elseif arg_6_1 == ccui.TouchEventType.moved then
			var_4_3:setScale(1)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			var_4_3:setScale(1)

			local var_6_0 = ""

			if arg_4_0.activity.is_open == 1 then
				if arg_4_0.isAwarded then
					var_6_0 = var_0_1:translation("REWARD_HAS_GOT")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_6_0
					})
				elseif arg_4_0.needCharge then
					local var_6_1 = {}

					var_6_1.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_6_1)
					xyd.WindowManager.get():closeWindow("activities")
				else
					arg_4_0.activitiesModel:getActivityReward(arg_4_0.activity.table_id, 1, function(arg_7_0, arg_7_1)
						if arg_7_0 == xyd.error.OK then
							arg_4_0.player:handleRewards(arg_7_1.awards)
							arg_4_0.activitiesModel:clearRedMarkState(arg_4_0.activity.table_id, 2)

							local var_7_0 = xyd.WindowManager.get():getWindow("activities")

							if var_7_0 then
								var_7_0:rightLayout()
							end

							arg_4_0.activities[arg_4_0.idx].details.is_awarded = 1

							arg_4_0:freshWords(var_4_1)
						end
					end)
				end
			else
				if xyd.ServerTime.get():getServerTime() < arg_4_0.activity.start_time then
					var_6_0 = var_0_1:translation("ACTIVITY_NO_OPEN")
				elseif xyd.ServerTime.get():getServerTime() >= arg_4_0.activity.end_time then
					var_6_0 = var_0_1:translation("ACTIVITY_END")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_6_0
				})
			end
		end
	end)

	arg_4_0.container = var_4_1
end

function var_0_0.addLive2dModel(arg_8_0, arg_8_1)
	if not arg_8_1 or tolua.isnull(arg_8_1) then
		return
	end

	if arg_8_0.live2d and not tolua.isnull(arg_8_0.live2d) then
		arg_8_0.live2d:removeFromParent(true)

		arg_8_0.live2d = nil
	end

	local var_8_0 = 40001067

	arg_8_1:getChildByName("bottonPanel"):setLocalZOrder(-1)

	if xyd.isLive2dCanUse() then
		local var_8_1 = xyd.tables.model:live2d(var_8_0)
		local var_8_2 = xyd.tables.libraryHomeCard:live2dx(var_8_0)
		local var_8_3 = xyd.tables.libraryHomeCard:live2dy(var_8_0)
		local var_8_4 = arg_8_1:getContentSize().width / 2 + var_8_2 - 200
		local var_8_5 = arg_8_1:getContentSize().height / 2 + var_8_3 - 35
		local var_8_6 = cc.Director:getInstance():getVisibleSize()
		local var_8_7, var_8_8 = var_8_4 + (var_8_6.width - xyd.STAGE_WIDTH) / 2, var_8_5 + (var_8_6.height - xyd.STAGE_HEIGHT) / 2 - 10
		local var_8_9 = xyd.tables.model:live2dScale(var_8_0) * 0.8
		local var_8_10 = xyd.newLive2d(arg_8_1, var_8_1, var_8_9 * xyd.STAGE_WIDTH / var_8_6.width, var_8_9 * xyd.STAGE_WIDTH / var_8_6.width, cc.p(var_8_7, var_8_8))

		arg_8_0.live2d = var_8_10

		var_8_10:setLocalZOrder(-1)
	else
		local var_8_11 = 1000
		local var_8_12 = xyd.AssetLoader.get():loadSprite("images/home_card/" .. var_8_0 + var_8_11 .. ".png")

		arg_8_1:addChild(var_8_12)
		var_8_12:setScale(0.8)
		var_8_12:setAnchorPoint(cc.p(0, 0))
		var_8_12:setPosition(cc.p(0, 75))
		var_8_12:setLocalZOrder(-1)
	end
end

function var_0_0.freshWords(arg_9_0, arg_9_1)
	arg_9_0.isAwarded = false
	arg_9_0.needCharge = false

	if arg_9_0.activity.details.is_awarded ~= 0 then
		arg_9_0.isAwarded = true
	elseif arg_9_0.activity.details.charge < arg_9_0.needChargeCount then
		arg_9_0.needCharge = true
	end

	arg_9_1:getChildByName("btn_buy"):getChildByName("charge_txt"):setVisible(false)
	arg_9_1:getChildByName("btn_buy"):getChildByName("reward_gray"):setVisible(false)
	arg_9_1:getChildByName("btn_buy"):getChildByName("reward_txt"):setVisible(false)
	arg_9_1:getChildByName("btn_buy"):setBright(true)

	if arg_9_0.isAwarded then
		arg_9_1:getChildByName("btn_buy"):getChildByName("reward_gray"):setVisible(true)
		arg_9_1:getChildByName("btn_buy"):setBright(false)
	elseif arg_9_0.needCharge then
		arg_9_1:getChildByName("btn_buy"):getChildByName("charge_txt"):setVisible(true)
	else
		arg_9_1:getChildByName("btn_buy"):getChildByName("reward_txt"):setVisible(true)
	end
end

function var_0_0.release(arg_10_0)
	if arg_10_0.handle then
		var_0_2.unscheduleGlobal(arg_10_0.handle)

		arg_10_0.handle = nil
	end
end

return var_0_0
