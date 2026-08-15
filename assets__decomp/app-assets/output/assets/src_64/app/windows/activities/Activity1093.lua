local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.activityIdDate
local var_0_5 = 378
local var_0_6 = "skeletons/ui_effect/activity_anniversary/anniversary_candle"
local var_0_7 = 6
local var_0_8 = 80
local var_0_9 = 17
local var_0_10 = 10001094
local var_0_11

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

	local var_2_1 = xyd.tables.activities:title(arg_2_0.activity.table_id)
	local var_2_2 = xyd.AssetLoader.get():loadSprite(var_2_1)

	var_2_2:addTo(var_2_0)
	var_2_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_2_2:setPosition(var_2_0:getChildByName("title_pos"):getPosition())

	arg_2_0.container = var_2_0:getChildByName("container")
	arg_2_0.menuContainer = arg_2_0.container:getChildByName("menu_container")

	arg_2_0:initAwardsWnd()
	arg_2_0:initMenu()
	arg_2_0:initBottom()
	arg_2_0:initTop()
	arg_2_0:initDialog()
	arg_2_0:showDialog()
end

function var_0_0.update(arg_3_0)
	arg_3_0:initMenu()
	arg_3_0:initBottom()
	arg_3_0:initDialog()
	arg_3_0:showDialog()
end

function var_0_0.initMenu(arg_4_0)
	local var_4_0 = arg_4_0.details.day_count
	local var_4_1 = 0
	local var_4_2 = var_4_0 == 0 and 100 or var_4_0 * var_0_9

	arg_4_0.container:getChildByName("bar_bg"):getChildByName("loading_bar"):setPercent(var_4_2)

	local var_4_3 = arg_4_0.menuContainer:getContentSize().height

	arg_4_0.menuContainer:removeAllChildren()

	local var_4_4 = 8

	for iter_4_0 = 1, var_0_7 do
		local var_4_5 = 0
		local var_4_6

		if var_4_0 == 0 then
			var_4_6 = "windows/activities/1069/btn_bg_1.png"
		elseif iter_4_0 < var_4_0 and var_4_0 ~= 0 then
			var_4_6 = "windows/activities/1069/btn_bg_1.png"
		elseif iter_4_0 == var_4_0 then
			var_4_6 = "windows/activities/1069/btn_bg_2.png"
			var_4_5 = -9
		else
			var_4_6 = "windows/activities/1069/btn_bg_3.png"
		end

		local var_4_7 = xyd.AssetLoader.get():loadSprite(var_4_6)

		var_4_7:addTo(arg_4_0.menuContainer)
		var_4_7:setPosition(66.5 + var_4_5, var_4_4 + var_4_7:getContentSize().height / 2)
		var_4_7:setAnchorPoint(cc.p(0.5, 0.5))

		local var_4_8 = xyd.AssetLoader.get():loadSprite("windows/activities/1069/date_" .. iter_4_0 .. ".png")

		var_4_8:addTo(arg_4_0.menuContainer)
		var_4_8:setPosition(68.5, var_4_4 + 5)
		var_4_8:setAnchorPoint(cc.p(0.5, 0))

		var_4_4 = var_4_4 + var_4_3 / var_0_7 - 2

		var_4_7:setTouchEnabled(true)
		var_4_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
			if arg_5_0.name == "began" then
				var_4_7:setScale(0.9)

				local var_5_0 = arg_4_0.container:getChildByName("date_awards")

				arg_4_0:showAwardsWnd(var_5_0, iter_4_0)

				local var_5_1 = var_4_7:convertToWorldSpace(cc.p(0, 0))
				local var_5_2 = var_5_0:getChildByName("container"):getContentSize().width

				var_5_0:setVisible(true)
				var_5_0:setPosition(var_5_1.x - var_5_2 / 2, var_5_1.y + 20)

				return true
			elseif arg_5_0.name == "ended" then
				var_4_7:setScale(1)
				arg_4_0.container:getChildByName("date_awards"):setVisible(false)
			end
		end)
	end
end

function var_0_0.initTop(arg_6_0)
	local var_6_0 = arg_6_0.container:getChildByName("top_left_bg")
	local var_6_1 = arg_6_0.endTime
	local var_6_2 = arg_6_0.startTime
	local var_6_3 = xyd.ServerTime.get():getServerTime()

	if var_6_1 - var_6_3 < 0 then
		var_6_0:getChildByName("text_left_1"):setString(var_0_3:translation("DATE_TEXT_10"))
		var_6_0:getChildByName("text_left_1"):setPositionX(50)
		var_6_0:getChildByName("text_time"):setVisible(false)
		var_6_0:getChildByName("text_left_2"):setVisible(false)
	elseif var_6_3 < var_6_2 then
		var_6_0:getChildByName("text_left_1"):setString(var_0_3:translation("DATE_TEXT_9"))
		var_6_0:getChildByName("text_left_1"):setPositionX(50)
		var_6_0:getChildByName("text_time"):setVisible(false)
		var_6_0:getChildByName("text_left_2"):setVisible(false)
	else
		local var_6_4 = var_6_1 - var_6_3

		arg_6_0:updateWaitingTime(var_6_0, var_6_4)
		var_6_0:getChildByName("text_left_1"):setString(var_0_3:translation("DATE_TEXT_4"))
		var_6_0:getChildByName("text_left_2"):setString(var_0_3:translation("DATE_TEXT_5"))
	end

	local var_6_5 = arg_6_0.container:getChildByName("top_right_bg")

	var_6_5:getChildByName("text_right_1"):setString(var_0_3:translation("DATE_TEXT_6"))
	var_6_5:getChildByName("text_name"):setString(var_0_3:translation("DATE_TEXT_7"))
	var_6_5:getChildByName("text_right_2"):setString(var_0_3:translation("DATE_TEXT_8"))
	arg_6_0.container:getChildByName("btn_rule"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = {}

			var_7_0.title_name = "ACTIVITY_ID_DATE_RULE_TITLE"
			var_7_0.rule = "ACTIVITY_ID_DATE_RULE_TEXT"

			xyd.WindowManager.get():openWindow("text_rule", var_7_0)
		end
	end)
end

function var_0_0.initBottom(arg_8_0)
	local var_8_0 = arg_8_0.details.day_count

	if var_8_0 > 0 then
		local var_8_1 = var_0_4:charge(var_8_0)
		local var_8_2 = var_0_4:name(var_8_0)
		local var_8_3 = arg_8_0.container:getChildByName("bottom_container"):getChildByName("awards_container")

		arg_8_0:initAwards(var_8_3, var_8_0)

		local var_8_4 = arg_8_0.container:getChildByName("bottom_container")

		var_8_4:getChildByName("text_bottom_1"):setString(string.format(var_0_3:translation("DATE_TEXT_1"), var_8_2))
		var_8_4:getChildByName("text_bottom_2"):setString(string.format(var_0_3:translation("ACTIVITY_ID_DATE_TEXT_2"), var_8_1))
		var_8_4:getChildByName("text_bottom_3"):setString(var_0_3:translation("DATE_TEXT_3"))

		local var_8_5 = arg_8_0.container:getChildByName("bottom_container"):getChildByName("btn_date")
		local var_8_6 = arg_8_0.endTime
		local var_8_7 = arg_8_0.startTime
		local var_8_8 = xyd.ServerTime.get():getServerTime()

		if arg_8_0.details.is_awarded == 1 then
			arg_8_0.container:getChildByName("bottom_container"):getChildByName("yilingqu"):setVisible(true)
			arg_8_0.container:getChildByName("bottom_container"):getChildByName("btn_date_gray"):setVisible(false)
			var_8_5:setVisible(false)
		elseif var_8_1 > arg_8_0.details.charge_count or var_8_6 - var_8_8 < 0 or var_8_8 < var_8_7 then
			arg_8_0.container:getChildByName("bottom_container"):getChildByName("yilingqu"):setVisible(false)
			arg_8_0.container:getChildByName("bottom_container"):getChildByName("btn_date_gray"):setVisible(true)
			var_8_5:setVisible(false)
		else
			arg_8_0.container:getChildByName("bottom_container"):getChildByName("yilingqu"):setVisible(false)
			arg_8_0.container:getChildByName("bottom_container"):getChildByName("btn_date_gray"):setVisible(false)
			var_8_5:setVisible(true)
		end

		var_8_5:addTouchEventListener(function(arg_9_0, arg_9_1)
			if arg_9_1 == ccui.TouchEventType.ended then
				local var_9_0 = string.format(var_0_3:translation("ACTIVITY_ID_DATE_TEXT_14"), var_8_1, var_0_3:translation("DATE_TEXT_7"), var_8_2)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_0, function()
					arg_8_0.activitiesModel:getActivityReward(arg_8_0.tableID, var_8_0, function(arg_11_0, arg_11_1)
						if arg_11_0 == xyd.error.OK then
							arg_8_0.details.is_awarded = arg_11_1.is_awarded

							local var_11_0 = {
								step = var_8_0,
								awards = arg_11_1.awards,
								table_id = arg_8_0.tableID,
								callback = arg_8_0:update()
							}

							xyd.WindowManager.get():openWindow("activity_date", var_11_0)
						end
					end)
				end, nil, nil, xyd.ColorMode.ACTIVITY)
			end
		end)
	else
		local var_8_9 = arg_8_0.container:getChildByName("bottom_container")

		var_8_9:removeAllChildren()

		local var_8_10 = {
			size = 24,
			color = cc.c3b(255, 216, 0),
			text = var_0_3:translation("DATE_TEXT_15")
		}
		local var_8_11 = xyd.AssetLoader.get():loadLabel(var_8_10)

		var_8_9:addChild(var_8_11)

		local var_8_12 = var_8_9:getContentSize()

		var_8_11:setPosition(cc.p(var_8_12.width / 2, var_8_12.height / 2))
		var_8_11:setAnchorPoint(cc.p(0.5, 0.5))
	end
end

function var_0_0.initAwards(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = var_0_4:giftID(arg_12_2)
	local var_12_1 = xyd.tables.gift:items(var_12_0)
	local var_12_2 = xyd.tables.gift:itemNum(var_12_0)

	arg_12_1:removeAllChildren()

	local var_12_3 = 0

	for iter_12_0 = 1, #var_12_1 do
		local var_12_4 = display.newNode()
		local var_12_5 = cc.Node:create()

		var_12_5:setContentSize(var_0_8, var_0_8)
		xyd.setItemBorder(var_12_5, var_12_1[iter_12_0])
		var_12_4:addChild(var_12_5)
		var_12_5:setPosition(var_12_3, 5)

		local var_12_6 = {
			id = var_12_1[iter_12_0]
		}

		arg_12_0:addTips(var_12_5, var_12_6)

		local var_12_7 = xyd.AssetLoader.get():loadSprite("windows/activities/1069/num_bg_1.png")

		var_12_7:addTo(var_12_4)
		var_12_7:setPosition(var_12_3 + var_0_8 - 3, 8)
		var_12_7:setAnchorPoint(cc.p(1, 0))

		local var_12_8 = {
			size = 20,
			color = cc.c3b(255, 228, 0)
		}
		local var_12_9 = xyd.AssetLoader.get():loadLabel(var_12_8)

		var_12_9:setString(var_12_2[iter_12_0])
		var_12_9:setAnchorPoint(cc.p(1, 0))
		var_12_9:addTo(var_12_4)
		var_12_9:setPosition(var_12_3 + var_0_8 - 10, 5)

		var_12_3 = var_12_3 + var_0_8 + 5

		arg_12_1:addChild(var_12_4)
	end
end

function var_0_0.initAwardsWnd(arg_13_0)
	local var_13_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1069/date_awards.csb")

	var_13_0:addTo(arg_13_0.container)
	var_13_0:setAnchorPoint(cc.p(0, 0))
	var_13_0:setPosition(cc.p(0, 0))
	var_13_0:setName("date_awards")
	var_13_0:setVisible(false)
end

function var_0_0.showAwardsWnd(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_1:getChildByName("container")

	arg_14_0:initAwards(var_14_0:getChildByName("awards_container"), arg_14_2)
	var_14_0:getChildByName("title"):setString(string.format(var_0_3:translation("DATE_TEXT_11"), var_0_4:name(arg_14_2)))
	var_14_0:getChildByName("text_bottom"):setString(var_0_3:translation("ACTIVITY_ID_DATE_TEXT_12"))
	var_14_0:getChildByName("text_cost"):setString(string.format(var_0_3:translation("DATE_TEXT_13"), var_0_4:charge(arg_14_2)))
end

function var_0_0.updateWaitingTime(arg_15_0, arg_15_1, arg_15_2)
	local function var_15_0(arg_16_0)
		local var_16_0

		if arg_16_0 < 86400 then
			var_16_0 = xyd.secondsToString(arg_16_0)
		else
			var_16_0 = xyd.secondsToString1(arg_16_0)
		end

		return var_16_0
	end

	if var_0_11 then
		var_0_1.unscheduleGlobal(var_0_11)

		var_0_11 = nil
	end

	if arg_15_2 > 0 then
		arg_15_1:getChildByName("text_time"):setString(var_15_0(arg_15_2))

		local var_15_1 = arg_15_1:getChildByName("text_time"):getPositionX()
		local var_15_2 = arg_15_1:getChildByName("text_time"):getContentSize().width

		arg_15_1:getChildByName("text_left_2"):setPositionX(var_15_1 + var_15_2)

		var_0_11 = var_0_1.scheduleGlobal(function()
			arg_15_2 = arg_15_2 - 1

			if arg_15_1 and not tolua.isnull(arg_15_1) then
				arg_15_1:getChildByName("text_time"):setString(var_15_0(arg_15_2))

				local var_17_0 = arg_15_1:getChildByName("text_time"):getPositionX()
				local var_17_1 = arg_15_1:getChildByName("text_time"):getContentSize().width

				arg_15_1:getChildByName("text_left_2"):setPositionX(var_17_0 + var_17_1)
			end

			if arg_15_2 <= 0 and var_0_11 then
				var_0_1.unscheduleGlobal(var_0_11)

				var_0_11 = nil

				arg_15_0:initBottom()
				arg_15_0:initTop()
			end
		end, 1)
	end
end

function var_0_0.showDialog(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	local var_18_0 = arg_18_0.details.day_count
	local var_18_1 = xyd.split(var_0_3:translation("ACTIVITY_DATE_DIALOG"), "\n")
	local var_18_2 = arg_18_0.player.playerName
	local var_18_3 = arg_18_0.container:getChildByName("dialog_container")

	var_18_3:setVisible(true)
	var_18_3:removeChild(var_18_3:getChildByName("dialog"))

	local var_18_4

	if arg_18_1 ~= nil then
		var_18_4 = arg_18_1
	elseif var_18_0 == 0 then
		var_18_4 = string.format(var_18_1[#var_18_1], var_18_2)
	else
		var_18_4 = string.format(var_18_1[var_18_0], var_18_2)
	end

	local var_18_5 = {
		size = 20,
		color = cc.c3b(255, 228, 0),
		text = var_18_4,
		dimensions = cc.size(285, 0)
	}
	local var_18_6 = xyd.AssetLoader.get():loadLabel(var_18_5)

	var_18_6:setAnchorPoint(cc.p(0, 1))
	var_18_6:setPosition(cc.p(15, 85))
	var_18_6:setName("dialog")

	local var_18_7 = var_18_6:getContentSize().height
	local var_18_8 = var_18_3:getChildByName("dialog_bg"):getContentSize()
	local var_18_9 = 50 + var_18_7

	if var_18_9 < 100 then
		var_18_9 = 100
	end

	var_18_3:getChildByName("dialog_bg"):setContentSize(var_18_8.width, var_18_9)
	var_18_3:addChild(var_18_6)

	if arg_18_2 then
		arg_18_0.playSound_ = true

		audio.playSound(arg_18_2, false)
	end

	if arg_18_3 == nil then
		arg_18_3 = xyd.tables.misc.dialogDefaultTime
	end

	var_0_1.performWithDelayGlobal(function()
		if var_18_3 and not tolua.isnull(var_18_3) then
			var_18_3:setVisible(false)
		end

		if arg_18_0.playSound_ then
			arg_18_0.playSound_ = false
		end
	end, arg_18_3)
end

function var_0_0.initDialog(arg_20_0)
	local var_20_0 = display.newNode()

	arg_20_0.playSound_ = false

	var_20_0:setContentSize(400, 335)
	var_20_0:setPosition(cc.p(100, 120))
	arg_20_0.container:addChild(var_20_0)
	var_20_0:setTouchEnabled(true)
	var_20_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_21_0)
		if arg_21_0.name == "began" then
			return true
		elseif arg_21_0.name == "ended" and not arg_20_0.playSound_ then
			local var_21_0 = xyd.tables.hero:clickDialog(var_0_10)
			local var_21_1 = xyd.tables.hero:dialogSounds(var_0_10)
			local var_21_2 = xyd.tables.hero:soundTimes(var_0_10)

			if var_21_0 ~= nil and #var_21_0 > 0 then
				if arg_20_0.speakIndex == 0 then
					arg_20_0.speakIndex = math.random(#var_21_0)
				else
					arg_20_0.speakIndex = xyd.randomIndex(arg_20_0.speakIndex, #var_21_0)
				end

				local var_21_3 = arg_20_0.speakIndex

				arg_20_0:showDialog(var_21_0[var_21_3], var_21_1[var_21_3], var_21_2[var_21_3])
			end
		end
	end)
end

function var_0_0.release(arg_22_0)
	if var_0_11 then
		var_0_1.unscheduleGlobal(var_0_11)

		var_0_11 = nil
	end
end

return var_0_0
