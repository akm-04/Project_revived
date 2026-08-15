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

	arg_2_0.container = var_2_1

	local var_2_2 = var_2_1:getChildByName("list")

	var_2_2:setTouchSwallowEnabled(false)

	local var_2_3 = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 670, 380),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_2):onScroll(handler(arg_2_0, arg_2_0.scrollListener))
	local var_2_4 = #xyd.tables.activityServerCharge:gifts()

	var_2_1:getChildByName("txt_rule"):setString(var_0_1:translation("ACTIVITY_1024_RULE"))
	var_2_1:getChildByName("people_num_txt"):setString(var_0_1:translation("ALREADY_CHARGE_PEOPLE"))
	var_2_1:getChildByName("charge_people_num"):setString(arg_2_0.activity.details.player_num)
	var_2_1:getChildByName("civil_reward"):setString(var_0_1:translation("ACTIVITY_1024_TEXT1"))
	var_2_1:getChildByName("super_reward"):setString(var_0_1:translation("ACTIVITY_1024_TEXT2"))

	local var_2_5 = 1
	local var_2_6 = var_2_1:getChildByName("civil_btn")
	local var_2_7 = var_2_1:getChildByName("super_btn")

	arg_2_0:updateTabState(var_2_5, var_2_6, var_2_7)
	var_2_6:addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			var_2_5 = 1

			arg_2_0:updateTabState(var_2_5, var_2_6, var_2_7)

			local var_3_0 = {
				list = var_2_3,
				listNum = var_2_4 / 2,
				activity = arg_2_0.activity,
				obtainStates = xyd.luaStringSplit(arg_2_0.activity.details.is_awards, "|"),
				count = arg_2_0.idx,
				type = var_2_5
			}

			arg_2_0:createAwardList(var_3_0)
		end
	end)
	var_2_7:addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			var_2_5 = 2

			arg_2_0:updateTabState(var_2_5, var_2_6, var_2_7)

			local var_4_0 = {
				list = var_2_3,
				listNum = var_2_4 / 2,
				activity = arg_2_0.activity,
				obtainStates = xyd.luaStringSplit(arg_2_0.activity.details.is_awards, "|"),
				count = arg_2_0.idx,
				type = var_2_5
			}

			arg_2_0:createAwardList(var_4_0)
		end
	end)

	local var_2_8 = {
		list = var_2_3,
		listNum = var_2_4 / 2,
		activity = arg_2_0.activity,
		obtainStates = xyd.luaStringSplit(arg_2_0.activity.details.is_awards, "|"),
		count = arg_2_0.idx,
		type = var_2_5
	}

	arg_2_0:createAwardList(var_2_8)
	arg_2_0:updateRedPoint()
end

function var_0_0.updateTabState(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if arg_5_1 == 1 then
		arg_5_2:setBrightStyle(ccui.BrightStyle.highlight)
		arg_5_3:setBrightStyle(ccui.BrightStyle.normal)
	else
		arg_5_3:setBrightStyle(ccui.BrightStyle.highlight)
		arg_5_2:setBrightStyle(ccui.BrightStyle.normal)
	end
end

function var_0_0.updateRedPoint(arg_6_0)
	local var_6_0 = xyd.luaStringSplit(arg_6_0.activity.details.is_awards, "|")
	local var_6_1 = #xyd.tables.activityServerCharge:gifts()
	local var_6_2 = var_6_1 / 2
	local var_6_3 = arg_6_0.container:getChildByName("civil_btn")
	local var_6_4 = arg_6_0.container:getChildByName("super_btn")

	var_6_3:getChildByName("red_point"):setVisible(false)
	var_6_4:getChildByName("red_point"):setVisible(false)

	for iter_6_0 = 1, var_6_1 do
		if var_6_0[iter_6_0] == "0" and arg_6_0.activity.details.player_num >= xyd.tables.activityServerCharge:num(iter_6_0) and arg_6_0.player.vip >= xyd.tables.activityServerCharge:vip(iter_6_0) and arg_6_0.activity.details.is_charged == 1 then
			if iter_6_0 <= var_6_2 then
				var_6_3:getChildByName("red_point"):setVisible(true)
			else
				var_6_4:getChildByName("red_point"):setVisible(true)
			end
		end
	end
end

function var_0_0.createAwardList(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_1.list
	local var_7_1 = arg_7_1.activity
	local var_7_2 = arg_7_1.listNum
	local var_7_3 = arg_7_1.count

	if arg_7_1.type then
		var_7_0:removeAllItems()
	end

	for iter_7_0 = 1, var_7_2 do
		if arg_7_0:checkInitItem(iter_7_0, arg_7_1) then
			local var_7_4 = var_7_0:newItem()
			local var_7_5 = display.newNode()
			local var_7_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1024/activity_item.csb")
			local var_7_7 = var_7_6:getChildByName("container")

			arg_7_0:rewardItemLayout(var_7_1, var_7_7, var_7_3, iter_7_0, var_7_2, arg_7_1.type)
			var_7_6:addTo(var_7_5)
			var_7_6:setTouchEnabled(true)
			var_7_6:setAnchorPoint(cc.p(0, 0))
			var_7_6:setPosition(0, 5)
			var_7_6:setTouchSwallowEnabled(false)
			var_7_5:setContentSize(667, 171)
			var_7_4:addContent(var_7_5)
			var_7_4:setItemSize(667, 171)
			var_7_0:addItem(var_7_4)
		end
	end

	var_7_0:reload()
end

function var_0_0.rewardItemLayout(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6)
	local var_8_0 = arg_8_2:getChildByName("btn")
	local var_8_1 = arg_8_2:getChildByName("bg_yilingqu")
	local var_8_2 = arg_8_2:getChildByName("yilingqu_big")
	local var_8_3 = var_8_0:getChildByName("lingqu")
	local var_8_4 = var_8_0:getChildByName("get_gray")
	local var_8_5 = var_8_0:getChildByName("expired")
	local var_8_6 = var_8_0:getChildByName("not_begin")

	var_8_3:setString(var_0_1:translation("ACTIVITY_COMMON_TEXT1"))
	var_8_4:setString(var_0_1:translation("ACTIVITY_COMMON_TEXT1"))
	var_8_5:setString(var_0_1:translation("ACTIVITY_COMMON_TEXT4"))
	var_8_6:setString(var_0_1:translation("ACTIVITY_COMMON_TEXT3"))

	local var_8_7 = {
		btn = var_8_0,
		alreadyObtain1 = var_8_1,
		alreadyObtain2 = var_8_2,
		obtain_bright = var_8_3,
		obtain_gray = var_8_4,
		expired = var_8_5,
		notBegin = var_8_6
	}
	local var_8_8 = arg_8_2:getChildByName("reward_container")
	local var_8_9 = arg_8_2:getChildByName("item_title_container")
	local var_8_10 = {
		color = cc.c3b(255, 255, 255)
	}

	var_8_10.size = 20

	local var_8_11 = xyd.AssetLoader.get():loadLabel(var_8_10)

	var_8_11:setMaxLineWidth(280)
	var_8_11:addTo(var_8_9)
	var_8_11:setAnchorPoint(cc.p(0, 0))
	var_8_11:setPosition(0, 0)

	local var_8_12 = xyd.tables.activityServerCharge:name(arg_8_4)

	var_8_11:setString(var_8_12)

	local var_8_13 = xyd.ServerTime.get():getServerTime()
	local var_8_14 = xyd.luaStringSplit(arg_8_1.details.is_awards, "|")
	local var_8_15 = true

	if arg_8_6 ~= 1 then
		arg_8_4 = arg_8_4 + arg_8_5
	end

	if arg_8_0.player.vip < xyd.tables.activityServerCharge:vip(arg_8_4) then
		var_8_15 = false
	end

	if arg_8_1.details.player_num < xyd.tables.activityServerCharge:num(arg_8_4) or not var_8_15 then
		arg_8_0:setBtnGetState(-1, var_8_7)
	elseif var_8_14[arg_8_4] == "1" then
		arg_8_0:setBtnGetState(0, var_8_7)
	else
		arg_8_0:setBtnGetState(1, var_8_7)
	end

	arg_8_0:rewardFormat(var_8_8, xyd.tables.activityServerCharge:gift(arg_8_4))

	if not arg_8_0:checkTime(arg_8_1) then
		arg_8_0:setBtnGetState(-1, var_8_7)
	end

	if var_8_13 < arg_8_1.start_time then
		arg_8_0:setBtnGetState(-2, var_8_7)
	end

	var_8_0:addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.began then
			var_8_0:setScale(0.9)
		elseif arg_9_1 == ccui.TouchEventType.moved then
			var_8_0:setScale(1)
		elseif arg_9_1 == ccui.TouchEventType.ended then
			var_8_0:setScale(1)

			if arg_8_1.details.is_charged == 0 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ACTIVITY_SERVER_CHARGE_TIP"), function()
					local var_10_0 = {}

					var_10_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_10_0)
				end, nil, nil, xyd.ColorMode.ACTIVITY)

				return
			end

			local var_9_0 = arg_8_4

			arg_8_0.activitiesModel:getActivityReward(arg_8_1.table_id, var_9_0, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					arg_8_0.player:handleRewards(arg_11_1.awards)
					arg_8_0:setBtnGetState(0, var_8_7)
					arg_8_0.activitiesModel:clearRedMarkState(arg_8_1.table_id, 2)

					if arg_8_0.activities[arg_8_3].details.is_awarded then
						arg_8_0.activities[arg_8_3].details.is_awarded = 1
					end

					if arg_8_0.activities[arg_8_3].details.is_awards then
						local var_11_0 = xyd.luaStringSplit(arg_8_0.activities[arg_8_3].details.is_awards, "|")

						var_11_0[arg_8_4] = "1"

						local var_11_1 = xyd.luaStringMerge(var_11_0, "|")

						arg_8_0.activities[arg_8_3].details.is_awards = var_11_1
					end

					if arg_8_0.activity.details.is_awards then
						local var_11_2 = xyd.luaStringSplit(arg_8_0.activities[arg_8_3].details.is_awards, "|")

						var_11_2[arg_8_4] = "1"

						local var_11_3 = xyd.luaStringMerge(var_11_2, "|")

						arg_8_0.activity.details.is_awards = var_11_3
					end

					local var_11_4 = xyd.WindowManager.get():getWindow("activities")

					if var_11_4 then
						var_11_4:rightLayout()
					end

					arg_8_0:updateRedPoint()
				end
			end)
		end
	end)
end

function var_0_0.setBtnGetState(arg_12_0, arg_12_1, arg_12_2)
	if arg_12_1 == 1 then
		arg_12_2.btn:setVisible(true)
		arg_12_2.btn:setTouchEnabled(true)
		arg_12_2.btn:setBright(true)
		arg_12_2.alreadyObtain1:setVisible(false)
		arg_12_2.alreadyObtain2:setVisible(false)
		arg_12_2.obtain_bright:setVisible(true)
		arg_12_2.obtain_gray:setVisible(false)
		arg_12_2.expired:setVisible(false)
		arg_12_2.notBegin:setVisible(false)
	elseif arg_12_1 == -1 then
		arg_12_2.btn:setVisible(true)
		arg_12_2.btn:setTouchEnabled(false)
		arg_12_2.btn:setBright(false)
		arg_12_2.alreadyObtain1:setVisible(false)
		arg_12_2.alreadyObtain2:setVisible(false)
		arg_12_2.obtain_bright:setVisible(false)
		arg_12_2.obtain_gray:setVisible(true)
		arg_12_2.expired:setVisible(false)
		arg_12_2.notBegin:setVisible(false)
	elseif arg_12_1 == 0 then
		arg_12_2.btn:setVisible(false)
		arg_12_2.btn:setBright(false)
		arg_12_2.btn:setTouchEnabled(false)
		arg_12_2.alreadyObtain1:setVisible(true)
		arg_12_2.alreadyObtain2:setVisible(true)
		arg_12_2.obtain_bright:setVisible(false)
		arg_12_2.obtain_gray:setVisible(false)
		arg_12_2.expired:setVisible(false)
		arg_12_2.notBegin:setVisible(false)
	elseif arg_12_1 == -2 then
		arg_12_2.btn:setVisible(true)
		arg_12_2.btn:setTouchEnabled(false)
		arg_12_2.btn:setBright(false)
		arg_12_2.alreadyObtain1:setVisible(false)
		arg_12_2.alreadyObtain2:setVisible(false)
		arg_12_2.obtain_bright:setVisible(false)
		arg_12_2.obtain_gray:setVisible(false)
		arg_12_2.expired:setVisible(false)
		arg_12_2.notBegin:setVisible(true)
	elseif arg_12_1 == 2 then
		arg_12_2.btn:setVisible(true)
		arg_12_2.btn:setBright(false)
		arg_12_2.alreadyObtain1:setVisible(false)
		arg_12_2.alreadyObtain2:setVisible(false)
		arg_12_2.obtain_bright:setVisible(false)
		arg_12_2.obtain_gray:setVisible(false)
		arg_12_2.expired:setVisible(true)
		arg_12_2.notBegin:setVisible(false)
	end
end

function var_0_0.checkInitItem(arg_13_0, arg_13_1, arg_13_2)
	return true
end

return var_0_0
