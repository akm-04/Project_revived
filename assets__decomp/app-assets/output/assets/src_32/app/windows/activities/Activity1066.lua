local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = "skeletons/ui_effect/activity_anniversary/anniversary_candle"

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activity.redMark = arg_1_0.activitiesModel:getRedMarkMap(arg_1_0.activity.table_id)

	if arg_1_0.activity.redMark and arg_1_0:isCanEat() then
		arg_1_0.activity.redMark.state = 1
	end

	arg_1_0.day = tonumber(arg_1_0.activity.details.day)
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
		var_2_0:setPosition(-5, 5)
		arg_2_0.container:getChildByName("rule"):setTouchEnabled(true)
		arg_2_0.container:getChildByName("rule"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_3_0)
			if arg_3_0.name == "began" then
				arg_2_0.container:getChildByName("rule"):setScale(0.9)

				return true
			elseif arg_3_0.name == "ended" then
				arg_2_0.container:getChildByName("rule"):setScale(1)
				xyd.WindowManager.get():openWindow("cake_rule")
			end
		end)
		arg_2_0:update()
	end
end

function var_0_0.isCanEat(arg_4_0)
	local var_4_0 = arg_4_0.activity
	local var_4_1 = xyd.ServerTime.get():getServerTime()

	if var_4_1 < var_4_0.start_time or var_4_1 > var_4_0.end_time then
		return false
	end

	if var_4_0.details.award_flag[arg_4_0.day] ~= 0 then
		return false
	end

	return true
end

function var_0_0.updateBoxMessage(arg_5_0)
	local var_5_0 = arg_5_0.activity
	local var_5_1 = xyd.ServerTime.get():getServerTime()

	if var_5_1 < var_5_0.start_time and var_5_0.is_open == 0 then
		arg_5_0:addMsgLabel(var_0_1:translation("SAKURA_NOT_OPEN"))

		return
	elseif var_5_1 > var_5_0.end_time and var_5_0.is_open == 0 then
		arg_5_0:addMsgLabel(var_0_1:translation("ACTIVITY_FINISHED"))

		return
	elseif var_5_0.details.award_flag[arg_5_0.day] == 1 then
		arg_5_0:addMsgLabel(var_0_1:translation("CAKE_EATTEN"))
	else
		arg_5_0:addMsgLabel(var_0_1:translation("NEW_CAKE_CAN_GET"))
	end
end

function var_0_0.update(arg_6_0)
	local var_6_0 = arg_6_0.activity
	local var_6_1 = xyd.ServerTime.get():getServerTime()

	arg_6_0:updateBoxMessage()
	arg_6_0:updateCake()
end

function var_0_0.updateCake(arg_7_0)
	local var_7_0 = xyd.tables.ActivityAnniversaryCakeTable:days()

	arg_7_0.canEat = arg_7_0:isCanEat()

	if arg_7_0.day >= 1 and var_7_0 >= arg_7_0.day then
		arg_7_0.container:getChildByName("desc"):setString(xyd.tables.ActivityAnniversaryCakeTable:name(arg_7_0.day))
	else
		arg_7_0.container:getChildByName("desc"):setString("")
	end

	arg_7_0.container:getChildByName("cake_pos"):removeAllChildren()
	arg_7_0.container:getChildByName("effect_pos"):removeAllChildren()

	if arg_7_0.canEat == false then
		arg_7_0.container:getChildByName("candle"):setVisible(false)

		if arg_7_0.day >= 1 and var_7_0 >= arg_7_0.day then
			local var_7_1 = "windows/activities/1066/cake_dregs.png"
			local var_7_2 = xyd.AssetLoader.get():loadSprite(var_7_1)

			var_7_2:setTouchEnabled(true)
			var_7_2:setAnchorPoint(cc.p(0.5, 0))
			var_7_2:addTo(arg_7_0.container:getChildByName("cake_pos"))
		end

		return
	end

	local var_7_3 = "windows/activities/1066/cake_" .. arg_7_0.day .. ".png"
	local var_7_4 = xyd.AssetLoader.get():loadSprite(var_7_3)

	var_7_4:setTouchEnabled(true)
	var_7_4:setAnchorPoint(cc.p(0.5, 0))
	var_7_4:addTo(arg_7_0.container:getChildByName("cake_pos"))
	var_7_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			return true
		elseif arg_8_0.name == "ended" then
			if arg_7_0.canEat ~= true then
				local var_8_0 = var_0_1:translation("CAKE_EATTEN")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_8_0
				})

				return
			else
				if xyd.WindowManager.get():isWindowOpen("toast") then
					xyd.WindowManager.get():closeWindow("toast")
				end

				arg_7_0:getCake(arg_7_0.day)
			end
		end
	end)

	local var_7_5 = var_0_3 .. ".json"
	local var_7_6 = var_0_3 .. ".atlas"

	arg_7_0.jigsawEffect = var_0_2.new(var_7_5, var_7_6, 1)

	arg_7_0.jigsawEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_7_0.jigsawEffect:addTo(arg_7_0.container:getChildByName("effect_pos"))
	arg_7_0.jigsawEffect:setScale(0.5)
	arg_7_0.jigsawEffect:play(nil, true)
end

function var_0_0.addMsgLabel(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_0.container:getChildByName("box")
	local var_9_1 = var_9_0:getChildByName("message_node")

	var_9_1:removeAllChildren()

	local var_9_2 = {
		size = 22,
		color = cc.c3b(220, 138, 0)
	}
	local var_9_3 = xyd.AssetLoader.get():loadLabel(var_9_2)

	var_9_3:setString(arg_9_1)
	var_9_3:addTo(var_9_1)
	var_9_3:setAnchorPoint(cc.p(0, 0.5))

	local var_9_4 = var_9_3:getContentSize().width

	var_9_0:getChildByName("duihua_bg"):width(55 + var_9_4)
	var_9_0:getChildByName("message_node"):width(10 + var_9_4)
	var_9_3:setPosition(cc.p(10, var_9_1:getContentSize().height / 2))
end

function var_0_0.getCake(arg_10_0, arg_10_1)
	arg_10_0.activitiesModel:getActivityReward(arg_10_0.activity.table_id, nil, function(arg_11_0, arg_11_1)
		if arg_11_0 == xyd.error.OK and arg_11_1.awards then
			arg_10_0.activity.details.award_flag = arg_11_1.act_info.award_flag

			arg_10_0.selfPlayer:handleRewards(arg_11_1.awards)
			arg_10_0:updateBoxMessage()
			arg_10_0:updateCake()
		end
	end)
end

return var_0_0
