local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = 10001117
local var_0_4 = xyd.tables.activityScholarshipReward

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)
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
	var_2_0:setPosition(37, 15)

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:createReward()
	arg_3_0:initTimeCount()
	arg_3_0.container:getChildByName("bottom_tips"):setString(var_0_1:translation("SCHOLARSHIP_TIPS"))
	arg_3_0:initDialog()
end

function var_0_0.createReward(arg_4_0)
	local var_4_0 = arg_4_0.container:getChildByName("reward_container")
	local var_4_1, var_4_2 = var_4_0:getContentSize().height, 0
	local var_4_3 = var_0_4:ids()

	for iter_4_0 = 1, #var_4_3 do
		local var_4_4 = var_4_3[iter_4_0]
		local var_4_5 = var_0_4:gift(var_4_4)
		local var_4_6 = var_0_4:range(var_4_4)
		local var_4_7 = xyd.tables.gift:items(var_4_5)
		local var_4_8 = xyd.tables.gift:itemNum(var_4_5)
		local var_4_9 = xyd.tables.gift:crystal(var_4_5)
		local var_4_10 = xyd.tables.gift:mana(var_4_5)
		local var_4_11 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1101/reward_item.csb")
		local var_4_12 = var_4_11:getChildByName("container")
		local var_4_13

		if var_4_6 == 1 then
			var_4_13 = string.format(var_0_1:translation("SCHOLARSHIP_REWARD_TIPS"), var_4_6)
		else
			local var_4_14 = var_0_4:range(var_4_3[iter_4_0 - 1]) + 1

			var_4_13 = string.format(var_0_1:translation("SCHOLARSHIP_REWARD_TIPS"), var_4_14 .. "-" .. var_4_6)
		end

		var_4_12:getChildByName("text_title"):setString(var_4_13)
		arg_4_0:rewardFormat(var_4_12:getChildByName("reward_container"), var_4_5)
		var_4_11:addTo(var_4_0)

		var_4_1 = var_4_1 - var_4_12:getContentSize().height

		var_4_11:setPosition(cc.p(var_4_2, var_4_1))
	end
end

function var_0_0.rewardFormat(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = arg_5_1:getContentSize().height
	local var_5_1 = 10
	local var_5_2 = xyd.tables.gift:items(arg_5_2)

	if #var_5_2 == 1 and var_5_2[1] == 0 then
		var_5_2 = {}
	end

	local var_5_3 = xyd.tables.gift:itemNum(arg_5_2)
	local var_5_4 = #var_5_2

	for iter_5_0 = 1, #var_5_2 do
		local var_5_5 = display.newNode()

		var_5_5:setContentSize(var_5_0, var_5_0)

		if xyd.tables.item:type(var_5_2[iter_5_0]) == -1 then
			xyd.setAvatarBorder(var_5_2[iter_5_0], var_5_5, 1, xyd.tables.hero:initialStar(var_5_2[iter_5_0]))
		else
			xyd.setItemBorder(var_5_5, var_5_2[iter_5_0], false, false, var_5_3[iter_5_0])
		end

		var_5_5:addTo(arg_5_1)
		var_5_5:setAnchorPoint(cc.p(0, 0))
		var_5_5:setPosition((iter_5_0 - 1) * (var_5_0 + var_5_1), 0)

		local var_5_6 = {
			id = var_5_2[iter_5_0],
			lev = xyd.tables.item:level(var_5_2[iter_5_0])
		}

		if xyd.tables.item:type(var_5_2[iter_5_0]) == -1 then
			var_5_6.tipsType = 0
			var_5_6.desc1 = xyd.tables.hero:getDes(var_5_2[iter_5_0])
		elseif specialItem then
			var_5_6.tipsType = 1
			var_5_6.id = -3
		else
			var_5_6.tipsType = 1
			var_5_6.desc1 = xyd.tables.item:desc1(var_5_2[iter_5_0])
			var_5_6.desc2 = xyd.tables.item:desc2(var_5_2[iter_5_0])
		end

		var_5_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_5_2[iter_5_0])
		var_5_6.name = xyd.tables.item:name(var_5_2[iter_5_0])

		arg_5_0:addTips(var_5_5, var_5_6)
	end

	local var_5_7 = xyd.tables.gift:crystal(arg_5_2)

	if var_5_7 and var_5_7 > 0 then
		local var_5_8 = display.newNode()

		var_5_8:setContentSize(var_5_0, var_5_0)
		xyd.setItemBorder(var_5_8, -1, false, false, var_5_7)
		var_5_8:addTo(arg_5_1)
		var_5_8:setAnchorPoint(cc.p(0, 0))
		var_5_8:setPosition(var_5_4 * (var_5_0 + var_5_1), 0)

		local var_5_9 = {}

		var_5_9.id = -1
		var_5_9.tipsType = 1

		arg_5_0:addTips(var_5_8, var_5_9)

		var_5_4 = var_5_4 + 1
	end

	local var_5_10 = xyd.tables.gift:mana(arg_5_2)

	if var_5_10 and var_5_10 > 0 then
		local var_5_11 = display.newNode()

		var_5_11:setContentSize(var_5_0, var_5_0)
		xyd.setItemBorder(var_5_11, -2, false, false, var_5_10)
		var_5_11:addTo(arg_5_1)
		var_5_11:setAnchorPoint(cc.p(0, 0))
		var_5_11:setPosition(var_5_4 * (var_5_0 + var_5_1), 0)

		local var_5_12 = {}

		var_5_12.id = -2
		var_5_12.tipsType = 1

		arg_5_0:addTips(var_5_11, var_5_12)

		local var_5_13 = var_5_4 + 1
	end

	return arg_5_1
end

function var_0_0.initTimeCount(arg_6_0)
	arg_6_0.container:getChildByName("time_text"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	local var_6_0 = arg_6_0.activity.details.begin_time
	local var_6_1 = 604800 - xyd.ServerTime.get():getServerTime() + var_6_0

	if var_6_1 < 0 then
		var_6_1 = 0
	end

	arg_6_0:updateTimeCount(var_6_1)
end

function var_0_0.updateTimeCount(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_0.container:getChildByName("time_text")
	local var_7_1 = var_0_1:translation("SCHOLARSHIP_COUNT_TIPS")

	if arg_7_1 <= 0 then
		var_7_0:setString(var_7_1 .. xyd.secondsToString(arg_7_1))

		return
	end

	local function var_7_2(arg_8_0)
		if arg_8_0 > 86400 then
			return xyd.secondsToString1(arg_8_0)
		else
			return xyd.secondsToString(arg_8_0)
		end
	end

	if arg_7_0.timeHandler then
		var_0_2.unscheduleGlobal(arg_7_0.timeHandler)

		arg_7_0.timeHandler = nil
	end

	if arg_7_1 > 0 then
		var_7_0:setString(var_7_1 .. var_7_2(arg_7_1))

		arg_7_0.timeHandler = var_0_2.scheduleGlobal(function()
			arg_7_1 = arg_7_1 - 1

			if var_7_0 and not tolua.isnull(var_7_0) then
				var_7_0:setString(var_7_1 .. var_7_2(arg_7_1))
			end

			if arg_7_1 <= 0 and arg_7_0.timeHandler then
				var_0_2.unscheduleGlobal(arg_7_0.timeHandler)

				arg_7_0.timeHandler = nil
			end
		end, 1)
	end
end

function var_0_0.showDialog(arg_10_0)
	local var_10_0 = xyd.tables.hero:clickDialog(var_0_3)
	local var_10_1 = xyd.tables.hero:dialogSounds(var_0_3)
	local var_10_2 = xyd.tables.hero:soundTimes(var_0_3)
	local var_10_3
	local var_10_4
	local var_10_5

	if var_10_0 ~= nil and #var_10_0 > 0 then
		if arg_10_0.speakIndex == 0 then
			arg_10_0.speakIndex = math.random(#var_10_0)
		else
			arg_10_0.speakIndex = xyd.randomIndex(arg_10_0.speakIndex, #var_10_0)
		end

		local var_10_6 = arg_10_0.speakIndex

		var_10_3 = var_10_0[var_10_6]
		var_10_4 = var_10_1[var_10_6]
		var_10_5 = var_10_2[var_10_6]
	else
		return false
	end

	local var_10_7 = arg_10_0.container:getChildByName("dialog_bg")

	var_10_7:setVisible(true)
	var_10_7:removeAllChildren()

	local var_10_8 = var_10_3
	local var_10_9 = {
		size = 20,
		color = cc.c3b(255, 255, 255),
		text = var_10_8,
		dimensions = cc.size(235, 0)
	}
	local var_10_10 = xyd.AssetLoader.get():loadLabel(var_10_9)

	var_10_10:setAnchorPoint(cc.p(0, 1))
	var_10_10:setName("dialog")

	local var_10_11 = var_10_10:getContentSize().height
	local var_10_12 = var_10_7:getContentSize()
	local var_10_13 = 60 + var_10_11

	if var_10_13 < 107 then
		var_10_13 = 107
	end

	local var_10_14 = var_10_13 - 107

	var_10_10:setPosition(cc.p(19, 58 + var_10_14))
	var_10_7:setContentSize(var_10_12.width, var_10_13)
	var_10_7:addChild(var_10_10)

	if var_10_4 then
		arg_10_0.playSound_ = true

		audio.playSound(var_10_4, false)
	end

	if var_10_5 == nil then
		var_10_5 = xyd.tables.misc.dialogDefaultTime
	end

	var_0_2.performWithDelayGlobal(function()
		if var_10_7 and not tolua.isnull(var_10_7) then
			var_10_7:setVisible(false)
		end

		if arg_10_0.playSound_ then
			arg_10_0.playSound_ = false
		end
	end, var_10_5)
end

function var_0_0.initDialog(arg_12_0)
	local var_12_0 = display.newNode()

	arg_12_0.playSound_ = false

	var_12_0:setContentSize(270, 350)
	var_12_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_12_0:setPosition(cc.p(548, 335))
	arg_12_0.container:addChild(var_12_0)
	var_12_0:setTouchEnabled(true)
	var_12_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			return true
		elseif arg_13_0.name == "ended" and not arg_12_0.playSound_ then
			arg_12_0:showDialog()
		end
	end)
	arg_12_0:showDialog()
end

function var_0_0.release(arg_14_0)
	if arg_14_0.timeHandler then
		var_0_2.unscheduleGlobal(arg_14_0.timeHandler)

		arg_14_0.timeHandler = nil
	end
end

return var_0_0
