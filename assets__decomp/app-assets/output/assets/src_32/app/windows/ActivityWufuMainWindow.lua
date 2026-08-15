local var_0_0 = class("ActivityWufuMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = xyd.tables.activityWufu
local var_0_3 = xyd.tables.translation
local var_0_4 = 6

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_2.details
	arg_1_0.isAward = arg_1_0.details.is_award
	arg_1_0.missionCount = arg_1_0.details.mission_count
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setTexts()
	arg_3_0:setBtns()
end

function var_0_0.setTexts(arg_4_0)
	for iter_4_0 = 1, 5 do
		local var_4_0 = arg_4_0:nodeByName("node_" .. iter_4_0)

		var_4_0:getChildByName("text_name"):setString(var_0_2:name(iter_4_0))
		var_4_0:getChildByName("text_name"):enableOutline(cc.c4b(147, 49, 35, 255), 2)

		local var_4_1 = var_0_2:desc(iter_4_0)
		local var_4_2 = string.gsub(var_4_1, "|", "\n")

		var_4_0:getChildByName("text_desc"):setString(string.format(var_4_2, arg_4_0.missionCount[iter_4_0], var_0_2:num(iter_4_0)))
		var_4_0:getChildByName("text_desc"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	end

	arg_4_0:nodeByName("text_wanneng"):setString(var_0_3:translation("ACTIVITY_WUFU_TEXT_1"))
	arg_4_0:nodeByName("text_wanneng"):enableOutline(cc.c4b(76, 76, 76, 255), 2)
	arg_4_0:nodeByName("text_progress"):enableOutline(cc.c4b(155, 22, 23, 255), 2)
end

function var_0_0.setBtns(arg_5_0)
	arg_5_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_6_0 = {}

			var_6_0.title_name = "ACTIVITY_NEWYEAR_BLESSING_RULE_TITLE"
			var_6_0.rule = "ACTIVITY_NEWYEAR_BLESSING_RULE_TEXT"
			var_6_0.style = xyd.RuleStyle.YELLOW

			xyd.WindowManager.get():openWindow("new_text_rule", var_6_0)
		end
	end)

	local var_5_0 = arg_5_0.details.special_fu ~= 0

	if not var_5_0 then
		xyd.GrayNode(arg_5_0:nodeByName("icon_wanneng"))
	end

	xyd.nodeEventSample(arg_5_0:nodeByName("icon_wanneng"), nil, function(arg_7_0)
		local var_7_0 = 1

		if var_5_0 then
			var_7_0 = 2
		end

		local var_7_1 = var_0_3:translation("ACTIVITY_NEWYEAR_BLESSING_TIP" .. var_7_0)

		xyd.WindowManager.get():openWindow("toast", {
			message = var_7_1
		})
	end)
	arg_5_0:nodeByName("icon_bag"):setTouchEnabled(true)
	arg_5_0:nodeByName("icon_bag"):setTouchSwallowEnabled(false)
	arg_5_0:nodeByName("icon_bag"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			local var_8_0 = xyd.tables.misc:getValue("activity_newyear_blessing_reward")

			xyd.WindowManager.get():openWindow("fourth_anni_gift_tip", {
				gift_id = var_8_0
			}):pos(950, 300)
		elseif arg_8_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("fourth_anni_gift_tip")

			if arg_5_0.details.state >= 5 then
				arg_5_0:getAward(var_0_4)
			end
		end

		return true
	end)

	for iter_5_0 = 1, 5 do
		local var_5_1 = arg_5_0:nodeByName("node_" .. iter_5_0)
		local var_5_2 = arg_5_0.missionCount[iter_5_0] >= var_0_2:num(iter_5_0)

		if arg_5_0.isAward[iter_5_0] ~= 0 then
			var_5_1:getChildByName("text_desc"):setVisible(false)
		elseif var_5_2 then
			var_5_1:getChildByName("word"):setVisible(false)
			var_5_1:getChildByName("text_desc"):setVisible(false)

			local var_5_3 = "windows/activities/1214/light.png"
			local var_5_4 = xyd.AssetLoader.get():loadSprite(var_5_3)

			var_5_4:addTo(var_5_1, -1)
			var_5_4:runAction(cc.RepeatForever:create(cc.RotateBy:create(10, 360)))
			var_5_4:setName("effect")

			local var_5_5 = "windows/activities/1214/word_get_award.png"
			local var_5_6 = xyd.AssetLoader.get():loadSprite(var_5_5)

			var_5_6:addTo(var_5_1)
			var_5_6:setName("word_get_award")
		else
			var_5_1:getChildByName("word"):setVisible(false)
		end

		local var_5_7 = display.newNode()

		var_5_7:setName("touch_node")
		var_5_7:setAnchorPoint(cc.p(0.5, 0.5))
		var_5_7:addTo(var_5_1)
		var_5_7:setContentSize(250, 250)
		var_5_7:setTouchEnabled(true)
		var_5_7:setTouchSwallowEnabled(true)
		var_5_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
			if arg_9_0.name == "ended" then
				print("click" .. iter_5_0)

				if arg_5_0.isAward[iter_5_0] ~= 0 then
					local var_9_0 = {
						idx = iter_5_0
					}

					xyd.WindowManager.get():openWindow("activity_wufu_blessing", var_9_0)
				elseif arg_5_0.missionCount[iter_5_0] >= var_0_2:num(iter_5_0) then
					arg_5_0:getAward(iter_5_0)
				else
					local var_9_1 = {
						idx = iter_5_0
					}

					xyd.WindowManager.get():openWindow("activity_wufu_award", var_9_1)
				end
			end

			return true
		end)
	end

	arg_5_0:updateBag()
end

function var_0_0.updateBag(arg_10_0)
	arg_10_0:nodeByName("text_progress"):setString(string.format(var_0_3:translation("ACTIVITY_WUFU_TEXT_2"), math.min(arg_10_0.details.state, 5), 5))

	if arg_10_0.isAward[var_0_4] ~= 0 then
		arg_10_0:nodeByName("icon_bag"):setVisible(false)
		arg_10_0:nodeByName("text_progress"):setVisible(false)
	elseif arg_10_0.details.state >= 5 then
		local var_10_0 = xyd.tables.misc:getValue("activity_ufocatcher_gift_frequency")
		local var_10_1 = cc.RepeatForever:create(cc.Sequence:create(cc.RotateBy:create(var_10_0 / 4, -20), cc.RotateBy:create(var_10_0 / 4, -20):reverse(), cc.RotateBy:create(var_10_0 / 4, 20), cc.RotateBy:create(var_10_0 / 4, 20):reverse(), cc.RotateBy:create(var_10_0 / 4, -20), cc.RotateBy:create(var_10_0 / 4, -20):reverse(), cc.RotateBy:create(var_10_0 / 4, 20), cc.RotateBy:create(var_10_0 / 4, 20):reverse(), cc.DelayTime:create(1)))

		arg_10_0:nodeByName("icon_bag"):runAction(var_10_1)
	end
end

function var_0_0.getAward(arg_11_0, arg_11_1)
	xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):getActivityReward(xyd.Activities.Wufu, arg_11_1, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0.selfPlayer:handleRewards(arg_12_1.awards)

			if arg_11_1 <= 5 then
				local var_12_0 = arg_11_0:nodeByName("node_" .. arg_11_1)

				var_12_0:getChildByName("effect"):removeSelf()
				var_12_0:getChildByName("word_get_award"):removeSelf()
				var_12_0:getChildByName("text_desc"):setVisible(false)
				var_12_0:getChildByName("word"):setVisible(true)
			end

			arg_11_0.isAward[arg_11_1] = 1

			arg_11_0:updateBag()
		end
	end)
end

return var_0_0
