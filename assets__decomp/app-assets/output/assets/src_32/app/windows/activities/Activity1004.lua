local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

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
	local var_2_2 = var_2_1:getChildByName("list_container")
	local var_2_3 = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 670, 300),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_2):onScroll(handler(arg_2_0, arg_2_0.scrollListener))
	local var_2_4 = #xyd.tables.activityFund:levels()
	local var_2_5 = {
		list = var_2_3,
		listNum = var_2_4,
		activity = arg_2_0.activity,
		obtainStates = xyd.luaStringSplit(arg_2_0.activity.details.is_awards, "|"),
		count = arg_2_0.idx
	}

	arg_2_0:createAwardList(var_2_5)

	if arg_2_0.activity.details.is_buy == 1 then
		var_2_1:getChildByName("buy_fund_btn"):setTouchEnabled(false)
		var_2_1:getChildByName("buy_fund_btn"):setBright(false)
		var_2_1:getChildByName("goumai_fund_txt"):setVisible(false)
		var_2_1:getChildByName("already_buy_gray"):setVisible(true)
	else
		var_2_1:getChildByName("buy_fund_btn"):setTouchEnabled(true)
		var_2_1:getChildByName("buy_fund_btn"):setBright(true)
		var_2_1:getChildByName("goumai_fund_txt"):setVisible(true)
		var_2_1:getChildByName("already_buy_gray"):setVisible(false)
		var_2_1:getChildByName("buy_fund_btn"):setLocalZOrder(100)
		var_2_1:getChildByName("goumai_fund_txt"):setLocalZOrder(100)
		var_2_1:getChildByName("already_buy_gray"):setLocalZOrder(100)
		var_2_1:getChildByName("buy_fund_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
			if arg_3_1 == ccui.TouchEventType.ended then
				if arg_2_0.player.vip < 2 then
					local var_3_0 = var_0_1:translation("BUY_FUND_TIP")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_3_0
					})

					return
				end

				if arg_2_0.player.crystal < xyd.tables.misc.fundPrice then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_4_0 = {}

						var_4_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_4_0)
					end, nil, nil, xyd.ColorMode.ACTIVITY)

					return
				end

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("BUY_FUND_CONFIRM"), function()
					arg_2_0.activitiesModel:buyFund(function(arg_6_0)
						if arg_6_0 == xyd.error.OK then
							if var_2_1 and var_2_1:getChildByName("buy_fund_btn") then
								var_2_1:getChildByName("buy_fund_btn"):setVisible(false)
								var_2_1:getChildByName("goumai_fund_txt"):setVisible(false)
							end

							if arg_2_0.activities[arg_2_0.idx].details.is_buy then
								arg_2_0.activities[arg_2_0.idx].details.is_buy = 1
							end

							if arg_2_0.activity.details.is_buy then
								arg_2_0.activity.details.is_buy = 1
							end

							arg_2_0.parent:removeAllChildren()
							arg_2_0:show()
						else
							local var_6_0 = var_0_1:translation("CAN_NOT_BUY_FUND")

							xyd.WindowManager.get():openWindow("toast", {
								message = var_6_0
							})
						end
					end)
				end, nil, nil, xyd.ColorMode.ACTIVITY)
			end
		end)
	end
end

function var_0_0.rewardItemLayout(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4)
	local var_7_0 = arg_7_2:getChildByName("btn")
	local var_7_1 = arg_7_2:getChildByName("yilingqu")
	local var_7_2 = arg_7_2:getChildByName("lingqu")
	local var_7_3 = arg_7_2:getChildByName("get_gray")
	local var_7_4 = arg_7_2:getChildByName("expired")
	local var_7_5 = arg_7_2:getChildByName("not_begin")
	local var_7_6 = {
		btn = var_7_0,
		alreadyObtain = var_7_1,
		obtain_bright = var_7_2,
		obtain_gray = var_7_3,
		expired = var_7_4,
		notBegin = var_7_5
	}
	local var_7_7 = arg_7_2:getChildByName("reward_container")
	local var_7_8 = arg_7_2:getChildByName("item_title_container")
	local var_7_9 = {
		color = cc.c3b(255, 255, 255)
	}

	var_7_9.size = 20

	local var_7_10 = xyd.AssetLoader.get():loadLabel(var_7_9)

	var_7_10:setMaxLineWidth(280)
	var_7_10:addTo(var_7_8)
	var_7_10:setAnchorPoint(cc.p(0, 0))
	var_7_10:setPosition(10, 3)
	var_7_10:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	local var_7_11 = xyd.tables.activityFund:name(arg_7_4)

	var_7_10:setString(var_7_11)

	local var_7_12 = xyd.ServerTime.get():getServerTime()
	local var_7_13 = xyd.luaStringSplit(arg_7_1.details.is_awards, "|")

	if arg_7_0.player.lev < xyd.tables.activityFund:level(arg_7_4) or arg_7_1.details.is_buy == 0 then
		arg_7_0:setBtnGetState(-1, var_7_6)
	elseif var_7_13[arg_7_4] == "1" then
		arg_7_0:setBtnGetState(0, var_7_6)
	else
		arg_7_0:setBtnGetState(1, var_7_6)
	end

	arg_7_0:rewardFormat(var_7_7, xyd.tables.activityFund:gift(arg_7_4))

	if not arg_7_0:checkTime(arg_7_1) then
		arg_7_0:setBtnGetState(-1, var_7_6)
	end

	var_7_0:addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = arg_7_4

			arg_7_0.activitiesModel:getActivityReward(arg_7_1.table_id, var_8_0, function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					arg_7_0.player:handleRewards(arg_9_1.awards)
					arg_7_0:setBtnGetState(0, var_7_6)
					arg_7_0.activitiesModel:clearRedMarkState(arg_7_1.table_id, 2)

					if arg_7_0.activities[arg_7_3].details.is_awarded then
						arg_7_0.activities[arg_7_3].details.is_awarded = 1
					end

					if arg_7_0.activities[arg_7_3].details.is_awards then
						local var_9_0 = xyd.luaStringSplit(arg_7_0.activities[arg_7_3].details.is_awards, "|")

						var_9_0[arg_7_4] = "1"

						local var_9_1 = xyd.luaStringMerge(var_9_0, "|")

						arg_7_0.activities[arg_7_3].details.is_awards = var_9_1
					end

					local var_9_2 = xyd.WindowManager.get():getWindow("activities")

					if var_9_2 then
						var_9_2:rightLayout()
					end
				end
			end)
		end
	end)
end

function var_0_0.checkInitItem(arg_10_0, arg_10_1, arg_10_2)
	if arg_10_2.activity.table_id == xyd.Activities.GrowthFund and arg_10_2.obtainStates[arg_10_1] == "1" then
		return false
	end

	return true
end

return var_0_0
