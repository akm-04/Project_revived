local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.translation
local var_0_3 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.oldIndex = arg_1_0.activity.details.current_index
	arg_1_0.curTimes = arg_1_0.activity.details.times
	arg_1_0.curRounds = arg_1_0.activity.details.rounds
	arg_1_0.newIndex = arg_1_0.activity.details.current_index
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
	local var_2_2 = var_2_1:getChildByName("throw_node")
	local var_2_3 = "windows/activities/1050/offset_2.png"
	local var_2_4 = xyd.AssetLoader.get():loadSprite(var_2_3)

	var_2_4:setAnchorPoint(0.5, 0.5)
	var_2_2:addChild(var_2_4, 0, 1)
	var_2_2:setTouchEnabled(true)

	local var_2_5 = var_2_1:getChildByName("activity_date")

	arg_2_0:setDate(var_2_5)

	local var_2_6 = xyd.tables.activityGoHiking:tableLength()

	arg_2_0:initGiftIcon(var_2_1, var_2_6)

	local var_2_7 = var_2_1:getChildByName("index_container")

	xyd.setAvatarClip(var_2_7, arg_2_0.player:getMyCurrentAvatarID(), 1)
	var_2_7:setAnchorPoint(0.5, 0)
	var_2_7:setScale(0.6, 0.6)

	local var_2_8 = var_2_1:getChildByName("gift_box" .. arg_2_0.newIndex)

	var_2_7:setPosition(var_2_8:getPositionX() - 2, var_2_8:getPositionY() + 40)

	local var_2_9 = xyd.AssetLoader.get():loadSprite("windows/activities/1050/border.png")

	var_2_9:setAnchorPoint(0.5, 0)
	var_2_9:setScale(1.5)
	var_2_7:addChild(var_2_9)
	var_2_9:setPosition(40, -32)

	local var_2_10 = var_2_1:getChildByName("rule_btn")

	var_2_10:addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.began then
			var_2_10:setScale(0.9)
		elseif arg_3_1 == ccui.TouchEventType.canceled then
			var_2_10:setScale(1)
		elseif arg_3_1 == ccui.TouchEventType.ended then
			var_2_10:setScale(1)

			local var_3_0 = {}

			var_3_0.title_name = "OUTING_RULE"
			var_3_0.rule = "SAKURA_OUTING_RULES"

			xyd.WindowManager.get():openWindow("go_hiking_rule", var_3_0)
		end
	end)

	local var_2_11 = var_2_1:getChildByName("reward_btn")

	var_2_11:getChildByName("txt_reward"):setString(var_0_1:translation("GOHIKING_CIRCLE_REWARD"))
	var_2_11:getChildByName("txt_reward"):enableOutline(cc.c4b(128, 26, 52, 255), 1)
	var_2_11:addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.began then
			var_2_11:setScale(0.9)
		elseif arg_4_1 == ccui.TouchEventType.canceled then
			var_2_11:setScale(1)
		elseif arg_4_1 == ccui.TouchEventType.ended then
			var_2_11:setScale(1)

			local var_4_0 = xyd.tables.misc.outingCircleGift
			local var_4_1 = {}

			var_4_1.title_name = "GOHIKING_CIRCLE_REWARD"
			var_4_1.rule = "OUTING_RULE_CIRCLE_TITLE"
			var_4_1.giftIds = var_4_0

			xyd.WindowManager.get():openWindow("go_hiking_rule", var_4_1)
		end
	end)

	local var_2_12 = arg_2_0.curTimes

	arg_2_0:createLabel(var_2_12, var_2_1)

	local var_2_13 = arg_2_0.curRounds

	arg_2_0:createCircle(var_2_13, var_2_1)

	local var_2_14 = "windows/activities/1050/effect_yinghua_dice"
	local var_2_15 = var_2_14 .. ".json"
	local var_2_16 = var_2_14 .. ".atlas"
	local var_2_17 = var_0_3.new(var_2_15, var_2_16, 1)

	var_2_2:addChild(var_2_17)
	var_2_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			if arg_2_0.curTimes == 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("NUMBER_HAS_FINISH")
				})
			end

			return true
		elseif arg_5_0.name == "ended" and arg_2_0.curTimes > 0 then
			arg_2_0.activitiesModel:getActivityReward(arg_2_0.activity.table_id, nil, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					arg_2_0.newIndex = arg_6_1.current_index

					var_2_2:setTouchEnabled(false)
					var_2_2:removeChild(var_2_2:getChildByTag(1))
					var_2_17:play(function()
						play()
					end, false)

					function play()
						var_2_17:play(function()
							local var_9_0 = "windows/activities/1050/offset_" .. arg_6_1.offset_index .. ".png"
							local var_9_1 = xyd.AssetLoader.get():loadSprite(var_9_0)

							var_9_1:setAnchorPoint(0.5, 0.5)
							var_2_2:addChild(var_9_1, 0, 1)

							arg_2_0.curTimes = arg_2_0.curTimes - 1

							local var_9_2 = arg_6_1.current_index
							local var_9_3 = arg_6_1.offset_index
							local var_9_4 = arg_6_1.times

							if arg_6_1.rounds then
								arg_2_0.curRounds = arg_6_1.rounds

								arg_2_0:createCircle(arg_2_0.curRounds, var_2_1)
							end

							arg_2_0:createLabel(var_9_4, var_2_1)

							local var_9_5 = 1

							function awartIconMove()
								if var_9_5 < var_9_3 + 2 then
									arg_2_0.oldIndex = arg_2_0.newIndex - var_9_3

									if arg_2_0.oldIndex <= 0 then
										arg_2_0.oldIndex = arg_2_0.oldIndex + 26
									end

									local var_10_0 = arg_2_0.oldIndex + var_9_5

									if var_10_0 > 26 then
										var_10_0 = var_10_0 % 26
									end

									var_9_5 = var_9_5 + 1

									local var_10_1, var_10_2 = var_2_1:getChildByName("gift_box" .. var_10_0):getPosition()

									if var_9_5 == var_9_3 + 2 then
										if next(arg_6_1.awards) ~= nil then
											arg_2_0.player:handleRewards(arg_6_1.awards)
										else
											xyd.WindowManager.get():openWindow("toast", {
												message = var_0_1:translation("ONE_MORE_TIME")
											})
										end

										arg_2_0.curTimes = arg_6_1.times
										arg_2_0.oldIndex = arg_6_1.current_index

										var_2_2:setTouchEnabled(true)

										return
									else
										local var_10_3 = cc.CallFunc:create(awartIconMove)
										local var_10_4 = cc.MoveTo:create(0.3, cc.p(var_10_1 - 2, var_10_2 + 40))

										var_2_7:runAction(cc.Sequence:create({
											var_10_4,
											var_10_3
										}))
									end
								end
							end

							awartIconMove()
						end, false)
					end
				end
			end)
		end
	end)
end

function var_0_0.setDate(arg_11_0, arg_11_1)
	local var_11_0 = arg_11_0.activity.start_time
	local var_11_1 = arg_11_0.activity.end_time
	local var_11_2 = os.date("%m", var_11_0)
	local var_11_3 = os.date("%d", var_11_0)
	local var_11_4 = os.date("%m", var_11_1)
	local var_11_5 = os.date("%d", var_11_1)

	arg_11_1:setString(string.format(var_0_1:translation("SAKURA_ACTIVITY_DATE"), var_11_2, var_11_3, var_11_4, var_11_5))
end

function var_0_0.createLabel(arg_12_0, arg_12_1, arg_12_2)
	arg_12_2:getChildByName("remain"):setString(arg_12_1)
end

function var_0_0.createCircle(arg_13_0, arg_13_1, arg_13_2)
	arg_13_2:getChildByName("complete"):setString(arg_13_1)
end

function var_0_0.initGiftIcon(arg_14_0, arg_14_1, arg_14_2)
	for iter_14_0 = 1, arg_14_2 do
		local var_14_0 = xyd.tables.activityGoHiking:getIcon(iter_14_0)

		if var_14_0 ~= nil then
			local var_14_1 = xyd.SpriteLoader.new(var_14_0, nil, extra_params, xyd.DefaultImageType.ITEM_ICON)

			var_14_1:setScale(0.57)

			if iter_14_0 == 1 or iter_14_0 == 9 or iter_14_0 == 19 then
				var_14_1:setScale(0.8)
			end

			var_14_1:setAnchorPoint(0, 0)
			arg_14_1:getChildByName("gift_box" .. iter_14_0):addChild(var_14_1)
			var_14_1:setPosition(17, 17)
		end

		local var_14_2 = "windows/activities/1050/grid_top.png"
		local var_14_3 = xyd.AssetLoader.get():loadSprite(var_14_2)

		var_14_3:setAnchorPoint(0, 0)

		local var_14_4 = arg_14_1:getChildByName("gift_box" .. iter_14_0)

		var_14_4:addChild(var_14_3)
		var_14_3:setTouchEnabled(true)
		var_14_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
			if arg_15_0.name == "began" then
				touchBeganY = arg_15_0.y

				if not xyd.WindowManager.get():getWindow("new_item_tips") then
					local var_15_0 = {}

					var_15_0.id = -8
					var_15_0.tipsType = 1
					var_15_0.specialTips = iter_14_0

					xyd.WindowManager.get():openWindow("new_item_tips", var_15_0):setPosition(var_14_4:getPositionX() + 280, var_14_4:getPositionY())
				end

				return true
			elseif arg_15_0.name == "moved" then
				local var_15_1 = arg_15_0.y

				if math.abs(var_15_1 - touchBeganY) > 30 then
					xyd.WindowManager.get():closeWindow("toast")
				end
			elseif arg_15_0.name == "ended" then
				xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)
	end
end

function var_0_0.checkInitItem(arg_16_0, arg_16_1, arg_16_2)
	return true
end

return var_0_0
