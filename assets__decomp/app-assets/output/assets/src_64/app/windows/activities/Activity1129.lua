local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")
local var_0_3 = xyd.tables.activitySkinWarmUp
local var_0_4 = {
	SEVER = 1,
	PERSONAL = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.btnState = var_0_4.SEVER
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
	var_2_0:setPosition(38, 23)

	arg_2_0.container = var_2_0:getChildByName("bg")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:changeBtnState()
	arg_3_0:setButtonClick()
	arg_3_0.container:getChildByName("txt_time"):setString(var_0_1:translation("ACTIVITY_DACALL_TIME"))
	arg_3_0.container:getChildByName("txt_server"):setString(var_0_1:translation("ACTIVITY_DACALL_SERVER"))
	arg_3_0.container:getChildByName("txt_personal"):setString(var_0_1:translation("ACTIVITY_DACALL_PERSONAL"))
	arg_3_0.container:getChildByName("server"):setString(arg_3_0.details.server_support)
	arg_3_0.container:getChildByName("server"):enableOutline(cc.c4b(122, 39, 0, 255), 2)
	arg_3_0.container:getChildByName("personal"):setString(arg_3_0.details.base_info.person_support)
	arg_3_0.container:getChildByName("personal"):enableOutline(cc.c4b(122, 39, 0, 255), 2)

	local var_3_0 = arg_3_0.container:getChildByName("item_container")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_0):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0:updateListInfo()
	arg_3_0.list:reload()
	arg_3_0:updateTimeCount()
	arg_3_0.container:getChildByName("time"):enableOutline(cc.c4b(255, 255, 255, 255), 1)
end

function var_0_0.updateTimeCount(arg_4_0)
	local var_4_0 = arg_4_0.container:getChildByName("time")

	if arg_4_0.handle_ then
		var_0_2.unscheduleGlobal(arg_4_0.handle_)
	end

	local var_4_1 = arg_4_0.activity.end_time - xyd.ServerTime.get():getServerTime()

	if var_4_1 <= 0 then
		var_4_1 = 0

		return
	end

	var_4_0:setString(xyd.secondsToString(var_4_1, {
		toText = true
	}))

	arg_4_0.handle_ = var_0_2.scheduleGlobal(function()
		if var_4_0 and not tolua.isnull(var_4_0) then
			var_4_1 = var_4_1 - 1

			var_4_0:setString(xyd.secondsToString(var_4_1, {
				toText = true
			}))

			if var_4_1 == 0 and arg_4_0.handle_ then
				var_0_2.unscheduleGlobal(arg_4_0.handle_)

				arg_4_0.handle_ = nil
			end
		elseif arg_4_0.handle_ then
			var_0_2.unscheduleGlobal(arg_4_0.handle_)

			arg_4_0.handle_ = nil
		end
	end, 1)
end

function var_0_0.release(arg_6_0)
	if arg_6_0.handle_ then
		var_0_2.unscheduleGlobal(arg_6_0.handle_)

		arg_6_0.handle_ = nil
	end
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevX_ = arg_7_1.x
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" then
		local var_7_0 = 3

		if var_7_0 <= math.abs(arg_7_1.y - arg_7_0.prevY_) or var_7_0 <= math.abs(arg_7_1.x - arg_7_0.prevX_) then
			arg_7_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.updateListInfo(arg_8_0)
	arg_8_0.listInfo = var_0_3:getIds()
end

function var_0_0.delegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return #arg_9_0.listInfo
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_0 = arg_9_0.list:dequeueItem()

		if not var_9_0 then
			var_9_0 = arg_9_0.list:newItem()
		else
			var_9_0:removeAllChildren(true)
		end

		local var_9_1 = 480
		local var_9_2 = 150

		var_9_0:setItemSize(var_9_1, var_9_2)

		local var_9_3 = display.newNode()

		var_9_3:setContentSize(var_9_1, 138)
		arg_9_0:initCell(var_9_3, arg_9_3)
		var_9_0:addContent(var_9_3)

		return var_9_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_9_2 then
		-- block empty
	end
end

function var_0_0.initCell(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = arg_10_0.listInfo[arg_10_2]
	local var_10_1 = var_0_3:gift(var_10_0)
	local var_10_2 = var_0_3:serverCharge(var_10_0)
	local var_10_3 = 100 - var_0_3:serverDiscount(var_10_0) * 100
	local var_10_4 = var_0_3:charge(var_10_0)
	local var_10_5 = 100 - var_0_3:discount(var_10_0) * 100
	local var_10_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1129/dacall_item.csb")

	var_10_6:setPosition(0, 0)
	var_10_6:setAnchorPoint(0, 0)
	arg_10_1:addChild(var_10_6)

	local var_10_7 = var_10_6:getChildByName("bg")

	if arg_10_0.btnState == var_0_4.SEVER then
		var_10_7:getChildByName("award_container"):setVisible(false)
		var_10_7:getChildByName("btn_get"):setVisible(false)
		var_10_7:getChildByName("have_get"):setVisible(false)
		var_10_7:getChildByName("support"):setString(string.format(var_0_1:translation("ACTIVITY_DACALL_SUPPORT_WORD"), var_10_2))
		var_10_7:getChildByName("support"):enableOutline(cc.c4b(108, 5, 44, 255), 1)
		dump(string.format(var_0_1:translation("ACTIVITY_DACALL_DISCOUNT"), var_10_3))
		var_10_7:getChildByName("discount"):setString(string.format(var_0_1:translation("ACTIVITY_DACALL_DISCOUNT"), var_10_3))
		var_10_7:getChildByName("discount"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

		if var_10_2 <= arg_10_0.details.server_support then
			var_10_7:getChildByName("achieved"):setVisible(true)
			var_10_7:getChildByName("not_achieve"):setVisible(false)
		else
			var_10_7:getChildByName("achieved"):setVisible(false)
			var_10_7:getChildByName("not_achieve"):setVisible(true)
		end
	elseif arg_10_0.btnState == var_0_4.PERSONAL then
		var_10_7:getChildByName("award_container"):setVisible(true)
		var_10_7:getChildByName("achieved"):setVisible(false)
		var_10_7:getChildByName("not_achieve"):setVisible(false)
		var_10_7:getChildByName("support"):setString(string.format(var_0_1:translation("ACTIVITY_DACALL_SUPPORT_WORD"), var_10_4))
		var_10_7:getChildByName("support"):enableOutline(cc.c4b(108, 5, 44, 255), 1)
		dump(string.format(var_0_1:translation("ACTIVITY_DACALL_DISCOUNT"), var_10_5))
		var_10_7:getChildByName("discount"):setString(string.format(var_0_1:translation("ACTIVITY_DACALL_DISCOUNT"), var_10_5))
		var_10_7:getChildByName("discount"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
		arg_10_0:rewardLayer(var_10_7:getChildByName("award_container"), var_10_1)

		if arg_10_0.details.base_info.is_awards[var_10_0] == 1 then
			var_10_7:getChildByName("btn_get"):setVisible(false)
			var_10_7:getChildByName("have_get"):setVisible(true)
		else
			var_10_7:getChildByName("btn_get"):setVisible(true)
			var_10_7:getChildByName("have_get"):setVisible(false)
			var_10_7:getChildByName("btn_get"):addTouchEventListener(function(arg_11_0, arg_11_1)
				if arg_11_1 == ccui.TouchEventType.ended then
					local var_11_0

					if arg_10_0.activity.is_open == 1 then
						if arg_10_0.details.base_info.person_support >= var_10_4 then
							local var_11_1 = var_10_0

							arg_10_0.activitiesModel:getActivityReward(xyd.Activities.SkinWarmUp, var_11_1, function(arg_12_0, arg_12_1)
								if arg_12_0 == xyd.error.OK then
									arg_10_0.selfPlayer:handleRewards(arg_12_1.awards)

									local var_12_0 = {
										activity_id = xyd.Activities.SkinWarmUp
									}

									xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_12_0, function(arg_13_0, arg_13_1)
										if arg_13_0 == xyd.error.OK then
											arg_10_0.details = arg_13_1.details

											arg_10_0.container:getChildByName("server"):setString(arg_10_0.details.server_support)
											arg_10_0.container:getChildByName("personal"):setString(arg_10_0.details.base_info.person_support)
											arg_10_0.list:reload()
										end
									end)
								end
							end)
						else
							var_11_0 = var_0_1:translation("ACTIVITY_DACALL_NOT_ENOUGH")

							xyd.WindowManager.get():openWindow("toast", {
								message = var_11_0
							})
						end
					else
						if xyd.ServerTime.get():getServerTime() < arg_10_0.activity.start_time then
							var_11_0 = var_0_1:translation("ACTIVITY_NO_OPEN")
						elseif xyd.ServerTime.get():getServerTime() >= arg_10_0.activity.end_time then
							var_11_0 = var_0_1:translation("ACTIVITY_END")
						end

						xyd.WindowManager.get():openWindow("toast", {
							message = var_11_0
						})
					end
				end
			end)
		end
	end
end

function var_0_0.changeBtnState(arg_14_0)
	if arg_14_0.btnState == var_0_4.SEVER then
		arg_14_0.container:getChildByName("btn_server"):setTouchEnabled(false)
		arg_14_0.container:getChildByName("btn_personal"):setTouchEnabled(true)
		arg_14_0.container:getChildByName("btn_server"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_14_0.container:getChildByName("btn_personal"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_14_0.btnState == var_0_4.PERSONAL then
		arg_14_0.container:getChildByName("btn_server"):setTouchEnabled(true)
		arg_14_0.container:getChildByName("btn_personal"):setTouchEnabled(false)
		arg_14_0.container:getChildByName("btn_server"):setBrightStyle(ccui.BrightStyle.normal)
		arg_14_0.container:getChildByName("btn_personal"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_0.setButtonClick(arg_15_0)
	arg_15_0.container:getChildByName("btn_server"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			arg_15_0.btnState = var_0_4.SEVER

			arg_15_0:changeBtnState()
			arg_15_0:updateListInfo()
			arg_15_0.list:reload()
		end
	end)
	arg_15_0.container:getChildByName("btn_personal"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended then
			arg_15_0.btnState = var_0_4.PERSONAL

			arg_15_0:changeBtnState()
			arg_15_0:updateListInfo()
			arg_15_0.list:reload()
		end
	end)
	arg_15_0.container:getChildByName("btn_dacall"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.ended then
			if arg_15_0.activity.is_open == 1 then
				if arg_15_0.details.base_info.free_times > 0 then
					local var_18_0 = var_0_1:translation("ACTIVITY_DACALL_FIRST_CONFIRM")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_18_0, function()
						xyd.Backend.get():request(xyd.mid.ACTIVITY_DA_CALL, nil, function(arg_20_0, arg_20_1)
							if arg_20_0 == xyd.error.OK then
								arg_15_0.details = arg_20_1

								arg_15_0.container:getChildByName("server"):setString(arg_15_0.details.server_support)
								arg_15_0.container:getChildByName("personal"):setString(arg_15_0.details.base_info.person_support)
								arg_15_0.list:reload()
							end
						end)
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				elseif arg_15_0.selfPlayer.crystal < xyd.tables.misc.skinWarmUpCost then
					local var_18_1 = var_0_1:translation("ZUANSHI_ABSENCE")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_18_1, function()
						local var_21_0 = {}

						var_21_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_21_0)
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				else
					local var_18_2 = string.format(var_0_1:translation("ACTIVITY_DACALL_CONFIRM"), xyd.tables.misc.skinWarmUpCost)

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_18_2, function()
						xyd.Backend.get():request(xyd.mid.ACTIVITY_DA_CALL, nil, function(arg_23_0, arg_23_1)
							if arg_23_0 == xyd.error.OK then
								arg_15_0.details = arg_23_1

								arg_15_0.container:getChildByName("server"):setString(arg_15_0.details.server_support)
								arg_15_0.container:getChildByName("personal"):setString(arg_15_0.details.base_info.person_support)
								arg_15_0.list:reload()
							end
						end)
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				end
			else
				if xyd.ServerTime.get():getServerTime() < arg_15_0.activity.start_time then
					message = var_0_1:translation("ACTIVITY_NO_OPEN")
				elseif xyd.ServerTime.get():getServerTime() >= arg_15_0.activity.end_time then
					message = var_0_1:translation("ACTIVITY_END")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = message
				})
			end
		end
	end)
	arg_15_0.container:getChildByName("btn_rule"):addTouchEventListener(function(arg_24_0, arg_24_1)
		if arg_24_1 == ccui.TouchEventType.ended then
			local var_24_0 = {
				title_name = "ACTIVITY_SKIN_WARMUP_RULE_TITLE",
				rule = "ACTIVITY_SKIN_WARMUP_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("text_rule", var_24_0)
		end
	end)
end

function var_0_0.rewardLayer(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = xyd.tables.gift:items(arg_25_2)

	if #var_25_0 == 1 and var_25_0[1] == 0 then
		var_25_0 = {}
	end

	local var_25_1 = xyd.tables.gift:itemNum(arg_25_2)
	local var_25_2 = #var_25_1
	local var_25_3 = arg_25_1:getContentSize().height
	local var_25_4 = var_25_3 / 4 - 1
	local var_25_5 = #var_25_0

	for iter_25_0 = 1, #var_25_0 do
		local var_25_6 = display.newNode()

		var_25_6:setContentSize(var_25_3, var_25_3)

		local var_25_7 = xyd.tables.item:type(var_25_0[iter_25_0])

		xyd.setItemBorder(var_25_6, var_25_0[iter_25_0], false, false, var_25_1[iter_25_0])
		var_25_6:addTo(arg_25_1)
		var_25_6:setAnchorPoint(cc.p(0, 0))
		var_25_6:setPosition((iter_25_0 - 1) * (var_25_3 + var_25_4), 0)

		local var_25_8 = {
			id = var_25_0[iter_25_0],
			lev = xyd.tables.item:level(var_25_0[iter_25_0])
		}

		if xyd.tables.item:type(var_25_0[iter_25_0]) == -1 then
			var_25_8.tipsType = 0
			var_25_8.desc1 = xyd.tables.hero:getDes(var_25_0[iter_25_0])
		elseif specialItem then
			var_25_8.tipsType = 1
			var_25_8.id = -3
		else
			var_25_8.tipsType = 1
			var_25_8.desc1 = xyd.tables.item:desc1(var_25_0[iter_25_0])
			var_25_8.desc2 = xyd.tables.item:desc2(var_25_0[iter_25_0])
		end

		var_25_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_25_0[iter_25_0])
		var_25_8.name = xyd.tables.item:name(var_25_0[iter_25_0])

		arg_25_0:addTips(var_25_6, var_25_8)
	end

	local var_25_9 = xyd.tables.gift:crystal(arg_25_2)

	if var_25_9 and var_25_9 > 0 then
		local var_25_10 = display.newNode()

		var_25_10:setContentSize(var_25_3, var_25_3)
		xyd.setItemBorder(var_25_10, -1, false, false, var_25_9)
		var_25_10:addTo(arg_25_1)
		var_25_10:setAnchorPoint(cc.p(0, 0))
		var_25_10:setPosition(var_25_5 * (var_25_3 + var_25_4), 0)

		local var_25_11 = {}

		var_25_11.id = -1
		var_25_11.tipsType = 1

		arg_25_0:addTips(var_25_10, var_25_11)

		var_25_5 = var_25_5 + 1
	end

	local var_25_12 = xyd.tables.gift:mana(arg_25_2)

	if var_25_12 and var_25_12 > 0 then
		local var_25_13 = display.newNode()

		var_25_13:setContentSize(var_25_3, var_25_3)
		xyd.setItemBorder(var_25_13, -2, false, false, var_25_12)
		var_25_13:addTo(arg_25_1)
		var_25_13:setAnchorPoint(cc.p(0, 0))
		var_25_13:setPosition(var_25_5 * (var_25_3 + var_25_4), 0)

		local var_25_14 = {}

		var_25_14.id = -2
		var_25_14.tipsType = 1

		arg_25_0:addTips(var_25_13, var_25_14)

		local var_25_15 = var_25_5 + 1
	end

	return arg_25_1
end

return var_0_0
