local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = import("framework.scheduler")
local var_0_4 = import("app.model.Hero")
local var_0_5 = "skeletons/ui_effect/achievement/achievement_baoxiang"
local var_0_6 = "skeletons/ui_effect/achievement/achievement_baoxiang_spin"
local var_0_7 = xyd.tables.misc.singleDogGiftModel
local var_0_8 = 6
local var_0_9 = 50
local var_0_10 = 0.8
local var_0_11 = 3600

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.singleDogGiftTime = xyd.tables.misc.singleDogGiftTime
	arg_1_0.rollContainer = {}
	arg_1_0.curTimeNum = nil
	arg_1_0.countRoll = 0
	arg_1_0.singleDogModel_ = nil
	arg_1_0.textHandler = nil
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

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.container:getChildByName("text_mid_1"):setString(var_0_1:translation("TIME_HOUR"))
	arg_3_0.container:getChildByName("text_mid_2"):setString(var_0_1:translation("TIME_MINUTE"))
	arg_3_0.container:getChildByName("text_mid_3"):setString(var_0_1:translation("TIME_SECOND"))
	arg_3_0:updateTopText()
	arg_3_0:initTimeCount()
	arg_3_0:updateTimeCount()
	arg_3_0:initAwardBox()
	arg_3_0.container:getChildByName("btn_rule"):getChildByName("txt_rule"):setString(var_0_1:translation("ACTIVITY_RULE"))
	arg_3_0.container:getChildByName("btn_rule"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.began then
			arg_3_0.container:getChildByName("btn_rule"):setScale(0.9)
		elseif arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0.container:getChildByName("btn_rule"):setScale(1)

			local var_4_0 = {
				title_name = "ACTIVITY_SINGLE_DOG_RULE_TITLE",
				rule = "ACTIVITY_SINGLE_DOG_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_4_0)
		end
	end)
end

function var_0_0.updateTopText(arg_5_0)
	local var_5_0 = xyd.ServerTime.get():getServerTime()

	if var_5_0 > arg_5_0.activity.end_time then
		arg_5_0.container:getChildByName("text_top"):setString(var_0_1:translation("ACTIVITY_SINGLE_DOG_TIPS_2"))
		arg_5_0.container:getChildByName("text_bottom"):setString(var_0_1:translation("ACTIVITY_SINGLE_DOG_IS_OVER"))
	elseif var_5_0 > arg_5_0.singleDogGiftTime + var_0_11 and arg_5_0.activity.details.is_reward == 0 then
		arg_5_0.container:getChildByName("text_top"):setString(var_0_1:translation("ACTIVITY_SINGLE_DOG_TIPS_3"))
		arg_5_0.container:getChildByName("text_bottom"):setString(var_0_1:translation("ACTIVITY_SINGLE_DOG_TIPS_5"))
	elseif var_5_0 >= arg_5_0.singleDogGiftTime and var_5_0 <= arg_5_0.singleDogGiftTime + var_0_11 and arg_5_0.activity.details.is_reward == 0 then
		arg_5_0.container:getChildByName("text_top"):setString(var_0_1:translation("ACTIVITY_SINGLE_DOG_TIPS_2"))
		arg_5_0.container:getChildByName("text_bottom"):setString(var_0_1:translation("ACTIVITY_SINGLE_DOG_TIPS_4"))
	elseif arg_5_0.activity.details.is_reward == 1 then
		arg_5_0.container:getChildByName("text_top"):setString(var_0_1:translation("ACTIVITY_SINGLE_DOG_TIPS_2"))
		arg_5_0.container:getChildByName("text_bottom"):setString(var_0_1:translation("ACTIVITY_SINGLE_DOG_TIPS_6"))
	else
		arg_5_0.container:getChildByName("text_top"):setString(var_0_1:translation("ACTIVITY_SINGLE_DOG_TIPS_2"))
		arg_5_0.container:getChildByName("text_bottom"):setString(var_0_1:translation("ACTIVITY_SINGLE_DOG_TIPS_1"))
	end
end

function var_0_0.clipRollContainer(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1081/roll_num.csb")

	var_6_0:setAnchorPoint(cc.p(0, 0))
	var_6_0:setPosition(cc.p(0, 0))

	local var_6_1 = xyd.AssetLoader:get():loadSprite("windows/activities/1081/clip.png")

	var_6_1:setPosition(cc.p(0, 0))
	var_6_1:setAnchorPoint(cc.p(0, 0))

	local var_6_2 = cc.ClippingNode:create()

	var_6_2:setStencil(var_6_1)
	var_6_2:setInverted(true)
	var_6_2:setAlphaThreshold(0)
	arg_6_1:addChild(var_6_2)
	var_6_2:setPosition(cc.p(arg_6_2, arg_6_3))
	var_6_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_6_2:addChild(var_6_0)

	return var_6_0
end

function var_0_0.getTimeStr(arg_7_0, arg_7_1)
	local var_7_0 = tostring(math.floor(arg_7_1 / 3600))
	local var_7_1 = tostring(math.floor(arg_7_1 % 3600 / 60))
	local var_7_2 = tostring(math.floor(arg_7_1 % 60))

	if #var_7_0 <= 1 then
		var_7_0 = "0" .. var_7_0
	elseif #var_7_0 > 2 then
		var_7_0 = string.sub(var_7_0, -2, -1)
	end

	if #var_7_1 <= 1 then
		var_7_1 = "0" .. var_7_1
	end

	if #var_7_2 <= 1 then
		var_7_2 = "0" .. var_7_2
	end

	return var_7_0 .. var_7_1 .. var_7_2
end

function var_0_0.initTimeCount(arg_8_0)
	local var_8_0 = xyd.ServerTime.get():getServerTime()
	local var_8_1 = arg_8_0.singleDogGiftTime - var_8_0
	local var_8_2 = "000000"

	if var_8_1 > 0 then
		var_8_2 = arg_8_0:getTimeStr(var_8_1)
	end

	local var_8_3 = 0

	for iter_8_0 = 1, var_0_8 do
		local var_8_4 = cc.p(arg_8_0.container:getChildByName("num_node_" .. iter_8_0):getPosition())
		local var_8_5 = arg_8_0:clipRollContainer(arg_8_0.container, var_8_4.x - 17.5, var_8_4.y - var_0_9 * 1.5):getChildByName("container")
		local var_8_6 = cc.p(var_8_5:getChildByName("node_mid"):getPosition())
		local var_8_7 = string.sub(var_8_2, iter_8_0, iter_8_0)
		local var_8_8 = xyd.AssetLoader.get():loadSprite("windows/activities/1081/num/" .. var_8_7 .. ".png")

		var_8_8:addTo(var_8_5)
		var_8_8:setPosition(cc.p(var_8_6))
		var_8_8:setName("num_mid")
		table.insert(arg_8_0.rollContainer, var_8_5)
	end

	arg_8_0.curTimeNum = var_8_2
end

function var_0_0.changeTimeNum(arg_9_0, arg_9_1)
	if arg_9_1 < 0 then
		return
	end

	local var_9_0 = arg_9_0:getTimeStr(arg_9_1)
	local var_9_1 = 0

	for iter_9_0 = 1, var_0_8 do
		local var_9_2 = string.sub(arg_9_0.curTimeNum, iter_9_0, iter_9_0)

		if var_9_2 ~= string.sub(var_9_0, iter_9_0, iter_9_0) then
			local var_9_3 = arg_9_0.rollContainer[iter_9_0]
			local var_9_4 = cc.p(var_9_3:getChildByName("node_top"):getPosition())
			local var_9_5 = cc.p(var_9_3:getChildByName("node_mid"):getPosition())
			local var_9_6 = cc.p(var_9_3:getChildByName("node_bottom"):getPosition())
			local var_9_7 = var_9_2 - 1

			if iter_9_0 == 3 or iter_9_0 == 5 then
				if var_9_7 < 0 then
					var_9_7 = 5
				end
			elseif var_9_7 < 0 then
				var_9_7 = 9
			end

			local var_9_8 = var_9_3:getChildByName("num_bottom")

			if var_9_8 and not tolua.isnull(var_9_8) then
				var_9_8:removeSelf()
			end

			local var_9_9 = var_9_3:getChildByName("num_mid")

			if var_9_9 and not tolua.isnull(var_9_9) then
				var_9_9:setName("num_bottom")
			end

			local var_9_10 = xyd.AssetLoader.get():loadSprite("windows/activities/1081/num/" .. var_9_7 .. ".png")

			var_9_10:addTo(var_9_3)
			var_9_10:setPosition(cc.p(var_9_4))
			var_9_10:setName("num_mid")

			arg_9_0.curTimeNum = string.sub(arg_9_0.curTimeNum, 1, iter_9_0 - 1) .. var_9_7 .. string.sub(arg_9_0.curTimeNum, iter_9_0 + 1, -1)

			local var_9_11 = cc.MoveTo:create(var_0_10, cc.p(var_9_6))
			local var_9_12 = cc.MoveTo:create(var_0_10, cc.p(var_9_5))

			var_9_9:runAction(var_9_11)
			var_9_10:runAction(var_9_12)
		end
	end
end

function var_0_0.updateTimeCount(arg_10_0)
	local var_10_0 = xyd.ServerTime.get():getServerTime()
	local var_10_1 = arg_10_0.singleDogGiftTime - var_10_0

	if var_10_1 <= 0 then
		return
	end

	if arg_10_0.handler then
		var_0_3.unscheduleGlobal(arg_10_0.handler)

		arg_10_0.handler = nil
	end

	if var_10_1 > 0 then
		arg_10_0.handler = var_0_3.scheduleGlobal(function()
			var_10_1 = var_10_1 - 1

			if arg_10_0.container and not tolua.isnull(arg_10_0.container) then
				arg_10_0:changeTimeNum(var_10_1)
			end

			if var_10_1 < 0 then
				if arg_10_0.handler then
					var_0_3.unscheduleGlobal(arg_10_0.handler)

					arg_10_0.handler = nil
				end

				if arg_10_0.container and not tolua.isnull(arg_10_0.container) then
					arg_10_0:updateTopText()
					arg_10_0:initAwardBox()
					arg_10_0:updateTopTextTimeCount()
				end
			end
		end, 1)
	end
end

function var_0_0.updateTopTextTimeCount(arg_12_0)
	if arg_12_0.textHandler then
		var_0_3.unscheduleGlobal(arg_12_0.textHandler)

		arg_12_0.textHandler = nil
	end

	local var_12_0 = var_0_11 + 1

	if var_12_0 > 0 then
		arg_12_0.textHandler = var_0_3.scheduleGlobal(function()
			var_12_0 = var_12_0 - 1

			if var_12_0 < 0 then
				if arg_12_0.textHandler then
					var_0_3.unscheduleGlobal(arg_12_0.textHandler)

					arg_12_0.textHandler = nil
				end

				if arg_12_0.container and not tolua.isnull(arg_12_0.container) then
					arg_12_0:updateTopText()
				end
			end
		end, 1)
	end
end

function var_0_0.initAwardBox(arg_14_0)
	local var_14_0 = cc.p(arg_14_0.container:getChildByName("hero_node"):getPosition())
	local var_14_1 = arg_14_0.container:getChildByName("box_container")

	if arg_14_0:checkAwardCanGet() then
		arg_14_0.container:getChildByName("box_container"):setVisible(true)
		arg_14_0:initSingleDog(cc.p(var_14_0.x - 50, var_14_0.y))

		if arg_14_0.activity.details.is_reward == 0 then
			var_14_1:getChildByName("box_close"):setVisible(true)
			var_14_1:getChildByName("box_open"):setVisible(false)
			var_14_1:getChildByName("box_close"):setTouchEnabled(true)
			var_14_1:getChildByName("box_close"):addTouchEventListener(function(arg_15_0, arg_15_1)
				if arg_15_1 == ccui.TouchEventType.ended then
					arg_14_0.activitiesModel:getActivityReward(arg_14_0.activity.table_id, nil, function(arg_16_0, arg_16_1)
						if arg_16_0 == xyd.error.OK then
							arg_14_0.activity.details.is_reward = 1

							xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_16_1.awards)
							var_14_1:getChildByName("box_open"):setVisible(true)
							arg_14_0:updateTopText()
							arg_14_0.activitiesModel:clearRedMarkState(arg_14_0.activity.table_id, 2)

							local var_16_0 = xyd.WindowManager.get():getWindow("activities")

							if var_16_0 and var_16_0.rightItems then
								var_16_0:updateRightCell(arg_14_0.activity.table_id)
							end
						end
					end)
				end
			end)
		else
			var_14_1:getChildByName("box_close"):setVisible(false)
			var_14_1:getChildByName("box_open"):setVisible(true)
		end
	else
		arg_14_0:initSingleDog(cc.p(var_14_0.x - 50, var_14_0.y))
		arg_14_0.container:getChildByName("box_container"):setVisible(false)
	end
end

function var_0_0.checkAwardCanGet(arg_17_0)
	local var_17_0 = xyd.ServerTime.get():getServerTime()
	local var_17_1 = arg_17_0.activity.start_time
	local var_17_2 = arg_17_0.activity.end_time

	if var_17_0 >= arg_17_0.singleDogGiftTime and var_17_0 < var_17_2 then
		return true
	end

	return false
end

function var_0_0.initSingleDog(arg_18_0, arg_18_1)
	if arg_18_0.singleDogModel_ then
		arg_18_0.singleDogModel_ = nil
	end

	arg_18_0.singleDogModel_ = xyd.AssetLoader.get():loadSprite("windows/activities/1081/bg_hero.png")

	arg_18_0.singleDogModel_:setAnchorPoint(cc.p(0, 0))
	arg_18_0.container:addChild(arg_18_0.singleDogModel_)
	arg_18_0.singleDogModel_:setPosition(arg_18_1)
end

function var_0_0.playOpenEffect(arg_19_0, arg_19_1)
	if arg_19_0.openEffect and not tolua.isnull(arg_19_0.openEffect) then
		arg_19_0.openEffect:removeFromParent(true)
	end

	local var_19_0 = var_0_5 .. ".json"
	local var_19_1 = var_0_5 .. ".atlas"

	arg_19_0.openEffect = var_0_2.new(var_19_0, var_19_1, 1.4)

	local var_19_2 = arg_19_0.container:getChildByName("box_container")

	arg_19_0.openEffect:addTo(var_19_2)

	local var_19_3 = cc.p(var_19_2:getChildByName("box_close"):getPosition())

	arg_19_0.openEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_19_0.openEffect:setPosition(cc.p(var_19_3))

	local var_19_4 = var_0_6 .. ".json"
	local var_19_5 = var_0_6 .. ".atlas"

	arg_19_0.spinEffect = var_0_2.new(var_19_4, var_19_5, 1)

	arg_19_0.spinEffect:addTo(var_19_2)
	arg_19_0.spinEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_19_0.spinEffect:setPosition(cc.p(var_19_3))

	arg_19_0.isPlayingEffect = true

	var_19_2:getChildByName("box_close"):setVisible(false)
	var_19_2:getChildByName("box_open"):setVisible(false)
	arg_19_0.openEffect:play(function()
		xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_19_1, function()
			if arg_19_0.openEffect and not tolua.isnull(arg_19_0.openEffect) then
				arg_19_0.openEffect:removeSelf()
			end

			if arg_19_0.spinEffect and not tolua.isnull(arg_19_0.spinEffect) then
				arg_19_0.spinEffect:removeSelf()
			end

			var_19_2:getChildByName("box_open"):setVisible(true)
			arg_19_0:updateTopText()
			arg_19_0.activitiesModel:clearRedMarkState(arg_19_0.activity.table_id, 2)

			local var_21_0 = xyd.WindowManager.get():getWindow("activities")

			if var_21_0 and var_21_0.rightItems then
				var_21_0:updateRightCell(arg_19_0.activity.table_id)
			end
		end)
	end, false)
	arg_19_0.spinEffect:play(nil, true)
end

function var_0_0.release(arg_22_0)
	if arg_22_0.handler then
		var_0_3.unscheduleGlobal(arg_22_0.handler)

		arg_22_0.handler = nil
	end

	if arg_22_0.textHandler then
		var_0_3.unscheduleGlobal(arg_22_0.textHandler)
	end

	arg_22_0.singleDogModel_ = nil
	arg_22_0.rollContainer = {}
end

return var_0_0
