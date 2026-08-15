local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activitySkinCharge
local var_0_3 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
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

	var_2_1:getChildByName("text3"):getVirtualRenderer():setAdditionalKerning(-10)

	local var_2_2 = var_2_1:getChildByName("extra_item")
	local var_2_3 = var_2_1:getChildByName("item_skin")

	arg_2_0.timer = var_2_1:getChildByName("timer")
	arg_2_0.buyBtn = var_2_1:getChildByName("btn_buy")

	local var_2_4 = xyd.tables.activities:gift(arg_2_0.activity.table_id)
	local var_2_5 = xyd.tables.gift:items(var_2_4)

	if #var_2_5 == 1 and var_2_5[1] == 0 then
		var_2_5 = {}
	end

	local var_2_6 = xyd.tables.gift:itemNum(var_2_4)
	local var_2_7 = display.newNode()
	local var_2_8 = display.newNode()

	var_2_7:setContentSize(var_2_2:getContentSize().height, var_2_2:getContentSize().height)
	var_2_8:setContentSize(var_2_3:getContentSize().height, var_2_3:getContentSize().height)
	xyd.setItemBorder(var_2_8, var_2_5[1], false, false, var_2_6[1])

	if var_2_5[2] then
		xyd.setItemBorder(var_2_7, var_2_5[2], false, false, 1)
		var_2_7:addTo(var_2_2)
		var_2_7:setAnchorPoint(cc.p(0, 0))
		var_2_7:setPosition(0, 0)
	end

	var_2_8:addTo(var_2_3)
	var_2_8:setAnchorPoint(cc.p(0, 0))
	var_2_8:setPosition(0, 0)

	for iter_2_0 = 1, 2 do
		local var_2_9 = {
			id = var_2_5[iter_2_0],
			lev = xyd.tables.item:level(var_2_5[iter_2_0])
		}

		if xyd.tables.item:type(var_2_5[iter_2_0]) == -1 then
			var_2_9.tipsType = 0
			var_2_9.desc1 = xyd.tables.hero:getDes(var_2_5[iter_2_0])
		else
			var_2_9.tipsType = 1
			var_2_9.desc1 = xyd.tables.item:desc1(var_2_5[iter_2_0])
			var_2_9.desc2 = xyd.tables.item:desc2(var_2_5[iter_2_0])
		end

		var_2_9.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_2_5[iter_2_0])
		var_2_9.name = xyd.tables.item:name(var_2_5[iter_2_0])

		if iter_2_0 == 1 then
			arg_2_0:addTips(var_2_8, var_2_9)
		elseif iter_2_0 == 2 then
			arg_2_0:addTips(var_2_7, var_2_9)
		end
	end

	local function var_2_10()
		local var_3_0 = xyd.ServerTime.get():getServerTime()

		if not var_3_0 then
			return
		end

		local var_3_1 = arg_2_0.activity.end_time - var_3_0

		if var_3_1 <= 0 or var_3_0 < arg_2_0.activity.start_time then
			if arg_2_0.handle then
				var_0_3.unscheduleGlobal(arg_2_0.handle)

				arg_2_0.handle = nil
			end

			return
		end

		local var_3_2 = var_3_1 / 3600 / 24
		local var_3_3 = var_3_1 / 3600
		local var_3_4 = var_3_1 % 3600 / 60
		local var_3_5 = var_3_1 % 3600 % 60
		local var_3_6 = string.format("%02d:%02d:%02d", var_3_3, var_3_4, var_3_5)

		if arg_2_0.timer and not tolua.isnull(arg_2_0.timer) then
			arg_2_0.timer:setString(var_0_1:translation("ACTIVITY_TIME_LIMIT_1") .. var_3_6)
		end
	end

	if arg_2_0.activity.is_open then
		var_2_10()

		if not arg_2_0.handle then
			arg_2_0.handle = var_0_3.scheduleGlobal(handler(arg_2_0, var_2_10), 1)
		end
	end

	var_2_1:getChildByName("charge_txt"):setString(var_0_1:translation("ALREADY_CHARGE") .. arg_2_0.activity.details.charge)
	arg_2_0:freshWords(var_2_1)
	arg_2_0.buyBtn:addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_2_0.buyBtn, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = ""

			if arg_2_0.activity.is_open == 1 then
				if arg_2_0.isAwarded then
					var_4_0 = var_0_1:translation("REWARD_HAS_GOT")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_4_0
					})
				elseif arg_2_0.needCharge then
					local var_4_1 = {}

					var_4_1.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_4_1)
					xyd.WindowManager.get():closeWindow("activities")
				else
					arg_2_0.activitiesModel:getActivityReward(arg_2_0.activity.table_id, 1, function(arg_5_0, arg_5_1)
						if arg_5_0 == xyd.error.OK then
							arg_2_0.player:handleRewards(arg_5_1.awards)

							arg_2_0.activities[arg_2_0.idx].details.is_awarded = 1

							arg_2_0.activitiesModel:clearRedMarkState(arg_2_0.activity.table_id, 2)

							local var_5_0 = xyd.WindowManager.get():getWindow("activities")

							if var_5_0 then
								var_5_0:updateActivityRedMark(arg_2_0.activity)
							end

							arg_2_0:freshWords(var_2_1)
						end
					end)
				end
			else
				if xyd.ServerTime.get():getServerTime() < arg_2_0.activity.start_time then
					var_4_0 = var_0_1:translation("ACTIVITY_NO_OPEN")
				elseif xyd.ServerTime.get():getServerTime() >= arg_2_0.activity.end_time then
					var_4_0 = var_0_1:translation("ACTIVITY_END")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_4_0
				})
			end
		end
	end)
end

function var_0_0.freshWords(arg_6_0, arg_6_1)
	arg_6_0.isAwarded = false
	arg_6_0.needCharge = false

	if arg_6_0.activity.details.is_awarded ~= 0 then
		arg_6_0.isAwarded = true
	elseif arg_6_0.activity.details.charge < var_0_2:price(1) then
		arg_6_0.needCharge = true
	end

	local var_6_0 = arg_6_0.buyBtn:getChildByName("txt")

	arg_6_1:getChildByName("charge_txt"):setVisible(false)

	if arg_6_0.isAwarded then
		var_6_0:setString(var_0_1:translation("ACTIVITY_COMMON_TEXT2"))
	elseif arg_6_0.needCharge then
		var_6_0:setString(var_0_1:translation("ACTIVITY_1130_TIP4"))
		arg_6_1:getChildByName("charge_txt"):setVisible(true)
	else
		var_6_0:setString(var_0_1:translation("OBTAIN"))
	end
end

function var_0_0.release(arg_7_0)
	if arg_7_0.handle then
		var_0_3.unscheduleGlobal(arg_7_0.handle)

		arg_7_0.handle = nil
	end
end

return var_0_0
