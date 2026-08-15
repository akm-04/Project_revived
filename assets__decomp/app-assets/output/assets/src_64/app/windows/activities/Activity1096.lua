local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activity.redMark = arg_1_0.activitiesModel:getRedMarkMap(arg_1_0.activity.table_id)

	if arg_1_0.activity.redMark and arg_1_0:isCanGet() then
		arg_1_0.activity.redMark.state = 1
	end
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	if var_2_0 then
		arg_2_0.container = var_2_0:getChildByName("container")

		var_2_0:addTo(arg_2_0.parent)
		var_2_0:setPosition(-2, 18)

		arg_2_0.awardContainer = arg_2_0.container:getChildByName("award_container")
		arg_2_0.getBtn = arg_2_0.awardContainer:getChildByName("get_btn")

		arg_2_0.getBtn:addTouchEventListener(function(arg_3_0, arg_3_1)
			if arg_3_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				arg_2_0.activitiesModel:getActivityReward(arg_2_0.activity.table_id, nil, function(arg_4_0, arg_4_1)
					if arg_4_0 == xyd.error.OK and arg_4_1.awards then
						arg_2_0.selfPlayer:handleRewards(arg_4_1.awards)

						arg_2_0.activity.details.is_awarded = 1

						arg_2_0:updateGetBtnState()
					end
				end)
			end
		end)
		arg_2_0.container:getChildByName("box_left"):setVisible(false)
		arg_2_0.container:getChildByName("box_right"):setVisible(false)
		arg_2_0:update()
		arg_2_0:addTalk()
		arg_2_0:updateBoxMessageShow(math.random(0, 1) == 0)
	end
end

function var_0_0.addTalk(arg_5_0)
	local var_5_0 = display.newNode()

	var_5_0:setTouchEnabled(true)
	var_5_0:setContentSize(240, 220)
	var_5_0:addTo(arg_5_0.container)

	local var_5_1 = cc.p(arg_5_0.container:getChildByName("box_left"):getPosition())

	var_5_0:setPosition(var_5_1.x + 18, var_5_1.y + 13)
	var_5_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			return true
		elseif arg_6_0.name == "ended" then
			arg_5_0:updateBoxMessageShow(true)
		end
	end)

	local var_5_2 = display.newNode()

	var_5_2:setTouchEnabled(true)
	var_5_2:setContentSize(240, 220)
	var_5_2:addTo(arg_5_0.container)

	local var_5_3 = cc.p(arg_5_0.container:getChildByName("box_right"):getPosition())

	var_5_2:setPosition(var_5_3.x + 18, var_5_3.y + 13)
	var_5_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			return true
		elseif arg_7_0.name == "ended" then
			arg_5_0:updateBoxMessageShow(false)
		end
	end)
end

function var_0_0.update(arg_8_0)
	arg_8_0:updateBoxMessage()
	arg_8_0:updateGetBtnState()
	arg_8_0:updateAwardsIcon()
end

function var_0_0.updateBoxMessage(arg_9_0)
	arg_9_0.container:getChildByName("box_left"):getChildByName("duihua_txt"):setString(var_0_1:translation("MONDAY_GIFT_DIALOG1"))
	arg_9_0.container:getChildByName("box_right"):getChildByName("duihua_txt"):setString(var_0_1:translation("MONDAY_GIFT_DIALOG2"))
end

function var_0_0.updateAwardsIcon(arg_10_0)
	local var_10_0 = xyd.tables.misc.mondayGiftId
	local var_10_1 = xyd.tables.gift:items(var_10_0)
	local var_10_2 = xyd.tables.gift:itemNum(var_10_0)
	local var_10_3 = xyd.tables.gift:mana(var_10_0)

	for iter_10_0 = 1, #var_10_1 do
		xyd.setItemAndAddTips(arg_10_0.awardContainer:getChildByName("item" .. iter_10_0), var_10_1[iter_10_0], var_10_2[iter_10_0])
	end

	xyd.setItemAndAddTips(arg_10_0.awardContainer:getChildByName("item" .. #var_10_1 + 1), -2, var_10_3)
end

function var_0_0.updateGetBtnState(arg_11_0)
	arg_11_0.getBtn:setBright(false)
	arg_11_0.getBtn:setTouchEnabled(false)
	arg_11_0.getBtn:getChildByName("get"):setVisible(false)
	arg_11_0.getBtn:getChildByName("get_gray"):setVisible(false)
	arg_11_0.getBtn:getChildByName("already_get_gray"):setVisible(false)

	if arg_11_0.activity.start_time > xyd.ServerTime.get():getServerTime() then
		arg_11_0.getBtn:getChildByName("get_gray"):setVisible(true)
	elseif arg_11_0.activity.details.is_awarded ~= 1 then
		arg_11_0.getBtn:setBright(true)
		arg_11_0.getBtn:setTouchEnabled(true)
		arg_11_0.getBtn:getChildByName("get"):setVisible(true)
	elseif arg_11_0.activity.details.is_awarded == 0 then
		arg_11_0.getBtn:getChildByName("get_gray"):setVisible(true)
	else
		arg_11_0.getBtn:getChildByName("already_get_gray"):setVisible(true)
	end
end

function var_0_0.updateBoxMessageShow(arg_12_0, arg_12_1)
	arg_12_0.container:getChildByName("box_left"):setVisible(false)
	arg_12_0.container:getChildByName("box_right"):setVisible(false)

	if arg_12_0.delay ~= nil then
		var_0_2.unscheduleGlobal(arg_12_0.delay)

		arg_12_0.delay = nil
	end

	if arg_12_1 then
		arg_12_0.container:getChildByName("box_left"):setVisible(true)

		arg_12_0.delay = var_0_2.performWithDelayGlobal(function()
			if arg_12_0 and not tolua.isnull(arg_12_0.container) and not tolua.isnull(arg_12_0.container:getChildByName("box_left")) then
				arg_12_0.container:getChildByName("box_left"):setVisible(false)
			end
		end, xyd.tables.misc.dialogDefaultTime)
	else
		arg_12_0.container:getChildByName("box_right"):setVisible(true)

		arg_12_0.delay = var_0_2.performWithDelayGlobal(function()
			if arg_12_0 and not tolua.isnull(arg_12_0.container) and not tolua.isnull(arg_12_0.container:getChildByName("box_right")) then
				arg_12_0.container:getChildByName("box_right"):setVisible(false)
			end
		end, xyd.tables.misc.dialogDefaultTime)
	end
end

function var_0_0.isCanGet(arg_15_0)
	local var_15_0 = xyd.ServerTime.get():getServerTime()

	if var_15_0 < arg_15_0.activity.start_time or var_15_0 > arg_15_0.activity.end_time then
		return false
	end

	if os.date("%a", var_15_0) == "Mon" and arg_15_0.activity.details.is_awarded == 0 then
		return true
	end

	return false
end

return var_0_0
