local var_0_0 = class("SakuraMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.sakura = xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA2018)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.starTreasure = xyd.ModelManager.get():loadModel(xyd.ModelType.STAR_TREASURE)
	arg_1_0.redEnvelopeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.RED_ENVELOPE)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	if not arg_2_0.sakura.hasShowTip then
		arg_2_0.sakura.hasShowTip = true

		xyd.WindowManager.get():openWindow("pic_tip", {
			path = "windows/sakura2018/tip.png"
		})
	end

	arg_2_0:nodeByName("progress_txt"):setString("")
	arg_2_0:nodeByName("progress_txt"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_2_0.starTreasure:loadInfo(function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			arg_2_0:updateStarTreasuerProgress()
		end
	end)
	arg_2_0:layout()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("close_btn")

	var_4_0:addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(var_4_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("fruit_factory_bg"):setTouchEnabled(true)
	arg_4_0:nodeByName("fruit_factory_bg"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			return true
		elseif arg_6_0.name == "ended" then
			xyd.playButtonSound()

			if arg_4_0:getDownTime() > 0 then
				arg_4_0:activityNotOpenTips()

				return
			end

			xyd.WindowManager.get():openWindow("sakura2018_fruit_factory")
		end
	end)
	arg_4_0:nodeByName("enjoy_sakura_bg"):setTouchEnabled(true)
	arg_4_0:nodeByName("enjoy_sakura_bg"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			return true
		elseif arg_7_0.name == "ended" then
			xyd.playButtonSound()

			if not arg_4_0.activitiesModel:isActivityOpen(xyd.Activities.StarTreasure) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_NOT_OPEN")
				})

				return
			end

			local var_7_0 = arg_4_0.starTreasure:getFirstOpenFlag()

			arg_4_0.starTreasure:loadInfo(function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("star_treasure")
				end
			end)
		end
	end)
	arg_4_0:nodeByName("sakura_battle_bg"):setTouchEnabled(true)
	arg_4_0:nodeByName("sakura_battle_bg"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			return true
		elseif arg_9_0.name == "ended" then
			xyd.playButtonSound()

			if not arg_4_0.activitiesModel:isActivityOpen(xyd.RedEnvelope.ENVELOPE_ID) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_NOT_OPEN")
				})

				return
			end

			arg_4_0.redEnvelopeModel:loadEnvelopeInfo(nil, function(arg_10_0)
				if arg_10_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("red_envelope")
				end
			end)
		end
	end)

	local var_4_1 = arg_4_0:nodeByName("btn_rule")

	var_4_1:addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(var_4_1, arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("new_text_rule", {
				title_name = "ACTIVITY_SAKURA2018_RULE_TITLE",
				rule = "ACTIVITY_SAKURA2018_RULE_TEXT"
			})
		end
	end)
	arg_4_0:nodeByName("fruit_factory_txt"):setString(var_0_1:translation("SAKURA2018_BRANCH_TIP1"))
	arg_4_0:nodeByName("enjoy_sakura__txt"):setString(var_0_1:translation("SAKURA2018_BRANCH_TIP2"))
	arg_4_0:nodeByName("sakura_battle_txt"):setString(var_0_1:translation("SAKURA2018_BRANCH_TIP3"))
	arg_4_0:updateDownTime()
end

function var_0_0.updateStarTreasuerProgress(arg_12_0)
	arg_12_0:nodeByName("progress_txt"):setString(string.format(var_0_1:translation("SAKURA2018_STAR_TREASURE_PROGRESS"), arg_12_0.starTreasure.currentFloor))
end

function var_0_0.activityNotOpenTips(arg_13_0)
	local var_13_0 = var_0_1:translation("SAKURA_NOT_OPEN")

	xyd.WindowManager.get():openWindow("toast", {
		message = var_13_0
	})
end

function var_0_0.updateDownTime(arg_14_0)
	if arg_14_0.handle then
		var_0_2.unscheduleGlobal(arg_14_0.handle)

		arg_14_0.handle = nil
	end

	local var_14_0 = arg_14_0.sakura.activity.end_time - xyd.ServerTime.get():getServerTime()

	arg_14_0:nodeByName("down_time_txt"):setString(xyd.secondsToString1(var_14_0, 3))

	arg_14_0.handle = var_0_2.scheduleGlobal(function()
		var_14_0 = var_14_0 - 1

		if arg_14_0:getDownTime() > 0 then
			arg_14_0:nodeByName("down_time_txt"):setString(var_0_1:translation("SAKURA_NOT_OPEN"))
		elseif var_14_0 <= 0 then
			arg_14_0:nodeByName("down_time_txt"):setString(var_0_1:translation("SAKURA_CLOSED"))
		else
			arg_14_0:nodeByName("down_time_txt"):setString(xyd.secondsToString1(var_14_0, 3))
		end
	end, 1)
end

function var_0_0.getDownTime(arg_16_0)
	return arg_16_0.sakura.activity.start_time - xyd.ServerTime.get():getServerTime()
end

function var_0_0.didOpen(arg_17_0, arg_17_1)
	arg_17_0:addBlockLayer()
end

function var_0_0.didClose(arg_18_0, arg_18_1)
	if arg_18_0.handle then
		var_0_2.unscheduleGlobal(arg_18_0.handle)

		arg_18_0.handle = nil
	end
end

return var_0_0
