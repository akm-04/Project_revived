local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = 378
local var_0_4 = "skeletons/ui_effect/activity_anniversary/anniversary_candle"
local var_0_5 = import("framework.scheduler")
local var_0_6 = 6
local var_0_7 = 80
local var_0_8 = 17
local var_0_9 = 10001095
local var_0_10

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.tableID = arg_1_0.activity.table_id
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.endTime = arg_1_0.activity.end_time
	arg_1_0.startTime = arg_1_0.activity.start_time
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
	var_2_0:setPosition(5, 15)

	arg_2_0.container = var_2_0:getChildByName("container")
	arg_2_0.menuContainer = arg_2_0.container:getChildByName("menu_container")

	arg_2_0:initAwardsWnd()
	arg_2_0:updateBar()
	arg_2_0:initStep()
	arg_2_0:initBottom()
	arg_2_0:initTop()
	arg_2_0:initDialog()
	arg_2_0:showDialog()
end

function var_0_0.update(arg_3_0)
	arg_3_0:updateBar()
	arg_3_0:initBottom()
	arg_3_0:initDialog()
	arg_3_0:showDialog()
end

function var_0_0.updateBar(arg_4_0)
	local var_4_0 = arg_4_0.details.step
	local var_4_1 = 0
	local var_4_2 = var_4_0 == 0 and 100 or var_4_0 * var_0_8

	arg_4_0.container:getChildByName("bar_bg"):getChildByName("loading_bar"):setPercent(var_4_2)

	for iter_4_0 = 1, var_0_6 do
		if var_4_0 == 0 then
			arg_4_0.menuContainer:getChildByName("txt_" .. iter_4_0):setColor(cc.c3b(68, 69, 94))
		elseif iter_4_0 < var_4_0 and var_4_0 ~= 0 then
			arg_4_0.menuContainer:getChildByName("txt_" .. iter_4_0):setColor(cc.c3b(255, 255, 255))
		elseif iter_4_0 == var_4_0 then
			arg_4_0.menuContainer:getChildByName("txt_" .. iter_4_0):setColor(cc.c3b(243, 230, 146))
		else
			arg_4_0.menuContainer:getChildByName("txt_" .. iter_4_0):setColor(cc.c3b(68, 69, 94))
		end
	end
end

function var_0_0.initStep(arg_5_0)
	local var_5_0, var_5_1 = arg_5_0.menuContainer:getPosition()

	for iter_5_0 = 1, var_0_6 do
		local var_5_2 = arg_5_0.menuContainer:getChildByName("btn_date_" .. iter_5_0)

		var_5_2:setTouchEnabled(true)
		var_5_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
			if arg_6_0.name == "began" then
				local var_6_0 = arg_5_0.container:getChildByName("date_awards")

				arg_5_0:showAwardsWnd(var_6_0, iter_5_0)

				local var_6_1, var_6_2 = var_5_2:getPosition()
				local var_6_3 = var_6_0:getChildByName("container"):getContentSize().width

				var_6_0:setVisible(true)
				var_6_0:setPosition(var_6_1 + var_5_0 - var_6_3 / 2 - 300, var_5_1 + var_6_2 - 150)

				return true
			elseif arg_6_0.name == "ended" then
				arg_5_0.container:getChildByName("date_awards"):setVisible(false)
			end
		end)
	end
end

function var_0_0.initTop(arg_7_0)
	local var_7_0 = arg_7_0.container:getChildByName("top_left_bg")
	local var_7_1 = arg_7_0.endTime
	local var_7_2 = arg_7_0.startTime
	local var_7_3 = xyd.ServerTime.get():getServerTime()

	if var_7_1 - var_7_3 < 0 then
		var_7_0:getChildByName("text_left_1"):setString(var_0_1:translation("DATE_TEXT_10"))
		var_7_0:getChildByName("text_left_1"):setPositionX(50)
		var_7_0:getChildByName("text_time"):setVisible(false)
		var_7_0:getChildByName("text_left_2"):setVisible(false)
	elseif var_7_3 < var_7_2 then
		var_7_0:getChildByName("text_left_1"):setString(var_0_1:translation("DATE_TEXT_9"))
		var_7_0:getChildByName("text_left_1"):setPositionX(50)
		var_7_0:getChildByName("text_time"):setVisible(false)
		var_7_0:getChildByName("text_left_2"):setVisible(false)
	else
		local var_7_4 = var_7_1 - var_7_3

		arg_7_0:updateWaitingTime(var_7_0, var_7_4)
		var_7_0:getChildByName("text_left_1"):setString(var_0_1:translation("DATE_TEXT_4"))
		var_7_0:getChildByName("text_left_2"):setString(var_0_1:translation("DATE_TEXT_5"))
	end

	local var_7_5 = arg_7_0.container:getChildByName("top_right_bg")

	var_7_5:getChildByName("text_right_1"):setString(var_0_1:translation("DATE_TEXT_6"))
	var_7_5:getChildByName("text_right_1"):setFontSize(20)
	var_7_5:getChildByName("text_right_1"):setPositionX(var_7_5:getChildByName("text_right_1"):getPositionX() + 5)
	var_7_5:getChildByName("text_name"):setString(var_0_1:translation("DATE_TEXT_7"))
	var_7_5:getChildByName("text_name"):setFontSize(20)
	var_7_5:getChildByName("text_right_2"):setString(var_0_1:translation("DATE_TEXT_8"))
	var_7_5:getChildByName("text_right_2"):setFontSize(20)
	var_7_5:getChildByName("text_right_2"):setPositionX(var_7_5:getChildByName("text_right_2"):getPositionX() + 10)
end

function var_0_0.initBottom(arg_8_0)
	local var_8_0 = arg_8_0.container:getChildByName("bottom_container")
	local var_8_1 = arg_8_0.details.step

	if var_8_1 > 0 then
		local var_8_2 = xyd.tables.activityDate:cost(var_8_1)
		local var_8_3 = xyd.tables.activityDate:name(var_8_1)
		local var_8_4 = var_8_0:getChildByName("awards_container")

		arg_8_0:initAwards(var_8_4, var_8_1)
		var_8_0:getChildByName("text_bottom_1"):setString(string.format(var_0_1:translation("DATE_TEXT_1"), var_8_3))
		var_8_0:getChildByName("text_bottom_2"):setString(string.format(var_0_1:translation("DATE_TEXT_2"), var_8_2))
		var_8_0:getChildByName("text_bottom_3"):setString(var_0_1:translation("DATE_TEXT_3"))
		var_8_0:getChildByName("text_bottom_1"):enableOutline(cc.c4b(89, 89, 139, 255), 2)
		var_8_0:getChildByName("text_bottom_2"):enableOutline(cc.c4b(89, 89, 139, 255), 2)
		var_8_0:getChildByName("text_bottom_3"):enableOutline(cc.c4b(89, 89, 139, 255), 2)

		local var_8_5 = var_8_0:getChildByName("btn_date")
		local var_8_6 = arg_8_0.endTime
		local var_8_7 = arg_8_0.startTime
		local var_8_8 = xyd.ServerTime.get():getServerTime()

		if var_8_6 - var_8_8 < 0 or var_8_8 < var_8_7 then
			var_8_0:getChildByName("btn_date_gray"):setVisible(true)
			var_8_5:setVisible(false)
		else
			var_8_0:getChildByName("btn_date_gray"):setVisible(false)
			var_8_5:setVisible(true)
		end

		var_8_5:addTouchEventListener(function(arg_9_0, arg_9_1)
			if arg_9_1 == ccui.TouchEventType.ended then
				if var_8_2 > arg_8_0.player.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_10_0 = {}

						var_10_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_10_0)
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				else
					local var_9_0 = string.format(var_0_1:translation("DATE_TEXT_14"), var_8_2, var_0_1:translation("DATE_TEXT_7"), var_8_3)

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_0, function()
						arg_8_0.activitiesModel:getActivityReward(arg_8_0.tableID, var_8_1, function(arg_12_0, arg_12_1)
							if arg_12_0 == xyd.error.OK then
								arg_8_0.details.step = arg_12_1.step

								local var_12_0 = {
									step = var_8_1,
									awards = arg_12_1.awards,
									table_id = arg_8_0.tableID
								}

								arg_8_0:update()
								xyd.WindowManager.get():openWindow("activity_date", var_12_0)
							end
						end)
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				end
			end
		end)
		var_8_0:getChildByName("txt"):setString(var_0_1:translation("ACTIVITY_DATE_TXT"))
		var_8_0:getChildByName("btn_rule"):addTouchEventListener(function(arg_13_0, arg_13_1)
			if arg_13_1 == ccui.TouchEventType.ended then
				local var_13_0 = {}

				var_13_0.title_name = "ACTIVITY_DATE_RULE_TITLE"
				var_13_0.rule = "ACTIVITY_DATE_RULE_TEXT"

				xyd.WindowManager.get():openWindow("new_text_rule", var_13_0)
			end
		end)
	else
		var_8_0:removeAllChildren()

		local var_8_9 = {
			size = 24,
			color = cc.c3b(52, 54, 55),
			text = var_0_1:translation("DATE_TEXT_15")
		}
		local var_8_10 = xyd.AssetLoader.get():loadLabel(var_8_9)

		var_8_0:addChild(var_8_10)

		local var_8_11 = var_8_0:getContentSize()

		var_8_10:setPosition(cc.p(var_8_11.width / 2, var_8_11.height / 2))
		var_8_10:setAnchorPoint(cc.p(0.5, 0.5))
	end
end

function var_0_0.initAwards(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = xyd.tables.activityDate:giftID(arg_14_2)
	local var_14_1 = xyd.tables.gift:items(var_14_0)
	local var_14_2 = xyd.tables.gift:itemNum(var_14_0)

	arg_14_1:removeAllChildren()

	local var_14_3 = 0

	for iter_14_0 = 1, #var_14_1 do
		local var_14_4 = display.newNode()
		local var_14_5 = cc.Node:create()
		local var_14_6

		var_14_5:setContentSize(var_0_7, var_0_7)
		xyd.setItemBorder(var_14_5, var_14_1[iter_14_0])
		var_14_4:addChild(var_14_5)
		var_14_5:setPosition(var_14_3, 5)
		var_14_5:setTouchSwallowEnabled(false)
		var_14_5:setTouchEnabled(true)

		local var_14_7 = {
			id = var_14_1[iter_14_0]
		}

		arg_14_0:addTips(var_14_5, var_14_7)

		local var_14_8 = xyd.AssetLoader.get():loadSprite("windows/activities/1069/num_bg_1.png")

		var_14_8:addTo(var_14_4)
		var_14_8:setPosition(var_14_3 + var_0_7 - 3, 8)
		var_14_8:setAnchorPoint(cc.p(1, 0))

		local var_14_9 = {
			size = 20,
			color = cc.c3b(255, 255, 255)
		}
		local var_14_10 = xyd.AssetLoader.get():loadLabel(var_14_9)

		var_14_10:setString(var_14_2[iter_14_0])
		var_14_10:setAnchorPoint(cc.p(1, 0))
		var_14_10:addTo(var_14_4)
		var_14_10:setPosition(var_14_3 + var_0_7 - 10, 5)

		var_14_3 = var_14_3 + var_0_7 + 5

		arg_14_1:addChild(var_14_4)
	end
end

function var_0_0.initAwardsWnd(arg_15_0)
	local var_15_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1069/date_awards.csb")

	var_15_0:addTo(arg_15_0.container)
	var_15_0:setAnchorPoint(cc.p(0, 0))
	var_15_0:setPosition(cc.p(0, 0))
	var_15_0:setName("date_awards")
	var_15_0:setVisible(false)
end

function var_0_0.showAwardsWnd(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_1:getChildByName("container")

	arg_16_0:initAwards(var_16_0:getChildByName("awards_container"), arg_16_2)
	var_16_0:getChildByName("title"):setString(string.format(var_0_1:translation("DATE_TEXT_11"), xyd.tables.activityDate:name(arg_16_2)))
	var_16_0:getChildByName("text_bottom"):setString(var_0_1:translation("DATE_TEXT_12"))
	var_16_0:getChildByName("text_cost"):setString(string.format(var_0_1:translation("DATE_TEXT_13"), xyd.tables.activityDate:cost(arg_16_2)))
end

function var_0_0.updateWaitingTime(arg_17_0, arg_17_1, arg_17_2)
	local function var_17_0(arg_18_0)
		local var_18_0

		if arg_18_0 < 86400 then
			var_18_0 = xyd.secondsToString(arg_18_0)
		else
			var_18_0 = xyd.secondsToString1(arg_18_0)
		end

		return var_18_0
	end

	if var_0_10 then
		var_0_5.unscheduleGlobal(var_0_10)

		var_0_10 = nil
	end

	if arg_17_2 > 0 then
		arg_17_1:getChildByName("text_time"):setString(var_17_0(arg_17_2))

		local var_17_1 = arg_17_1:getChildByName("text_time"):getPositionX()
		local var_17_2 = arg_17_1:getChildByName("text_time"):getContentSize().width

		arg_17_1:getChildByName("text_left_2"):setPositionX(var_17_1 + var_17_2)

		var_0_10 = var_0_5.scheduleGlobal(function()
			arg_17_2 = arg_17_2 - 1

			if arg_17_1 and not tolua.isnull(arg_17_1) then
				arg_17_1:getChildByName("text_time"):setString(var_17_0(arg_17_2))

				local var_19_0 = arg_17_1:getChildByName("text_time"):getPositionX()
				local var_19_1 = arg_17_1:getChildByName("text_time"):getContentSize().width

				arg_17_1:getChildByName("text_left_2"):setPositionX(var_19_0 + var_19_1)
			end

			if arg_17_2 <= 0 and var_0_10 then
				var_0_5.unscheduleGlobal(var_0_10)

				var_0_10 = nil

				arg_17_0:initBottom()
				arg_17_0:initTop()
			end
		end, 1)
	end
end

function var_0_0.showDialog(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	local var_20_0 = arg_20_0.details.step
	local var_20_1 = xyd.split(var_0_1:translation("ACTIVITY_DATE_DIALOG"), "\n")
	local var_20_2 = arg_20_0.player.playerName
	local var_20_3 = arg_20_0.container:getChildByName("dialog_container")

	var_20_3:setVisible(true)
	var_20_3:removeChild(var_20_3:getChildByName("dialog"))

	local var_20_4

	if arg_20_1 ~= nil then
		var_20_4 = arg_20_1
	elseif var_20_0 == 0 then
		var_20_4 = string.format(var_20_1[#var_20_1], var_20_2)
	else
		var_20_4 = string.format(var_20_1[var_20_0], var_20_2)
	end

	local var_20_5 = {
		size = 24,
		color = cc.c3b(82, 79, 107),
		text = var_20_4,
		dimensions = cc.size(280, 0)
	}
	local var_20_6 = xyd.AssetLoader.get():loadLabel(var_20_5)

	var_20_6:setAnchorPoint(cc.p(0, 1))
	var_20_6:setPosition(cc.p(15, 76))
	var_20_6:setName("dialog")

	local var_20_7 = var_20_6:getContentSize().height
	local var_20_8 = var_20_3:getChildByName("dialog_bg"):getContentSize()
	local var_20_9 = 50 + var_20_7

	if var_20_9 < 100 then
		var_20_9 = 100
	end

	var_20_3:getChildByName("dialog_bg"):setContentSize(var_20_8.width, var_20_9)
	var_20_3:addChild(var_20_6)

	if arg_20_2 then
		arg_20_0.playSound_ = true

		audio.playSound(arg_20_2, false)
	end

	if arg_20_3 == nil then
		arg_20_3 = xyd.tables.misc.dialogDefaultTime
	end

	var_0_5.performWithDelayGlobal(function()
		if var_20_3 and not tolua.isnull(var_20_3) then
			var_20_3:setVisible(false)
		end

		if arg_20_0.playSound_ then
			arg_20_0.playSound_ = false
		end
	end, arg_20_3)
end

function var_0_0.initDialog(arg_22_0)
	local var_22_0 = display.newNode()

	arg_22_0.playSound_ = false

	var_22_0:setContentSize(400, 335)
	var_22_0:setPosition(cc.p(100, 120))
	arg_22_0.container:addChild(var_22_0)
	var_22_0:setTouchEnabled(true)
	var_22_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
		if arg_23_0.name == "began" then
			return true
		elseif arg_23_0.name == "ended" and not arg_22_0.playSound_ then
			local var_23_0 = xyd.tables.hero:clickDialog(var_0_9)
			local var_23_1 = xyd.tables.hero:dialogSounds(var_0_9)
			local var_23_2 = xyd.tables.hero:soundTimes(var_0_9)

			if var_23_0 ~= nil and #var_23_0 > 0 then
				if arg_22_0.speakIndex == 0 then
					arg_22_0.speakIndex = math.random(#var_23_0)
				else
					arg_22_0.speakIndex = xyd.randomIndex(arg_22_0.speakIndex, #var_23_0)
				end

				local var_23_3 = arg_22_0.speakIndex

				arg_22_0:showDialog(var_23_0[var_23_3], var_23_1[var_23_3], var_23_2[var_23_3])
			end
		end
	end)
end

function var_0_0.release(arg_24_0)
	if var_0_10 then
		var_0_5.unscheduleGlobal(var_0_10)

		var_0_10 = nil
	end
end

return var_0_0
