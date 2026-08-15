local var_0_0 = class("SevenDayLoginWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.hero
local var_0_3 = xyd.tables.gift
local var_0_4 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.details = arg_1_2.response.details
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.hasRewardDay = arg_1_0.details.award_id
	arg_1_0.canRewardDay = arg_1_0.details.login_day
	arg_1_0.canRewardDay = math.min(arg_1_0.canRewardDay, arg_1_0.hasRewardDay + 1)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	if arg_3_0.effect and not tolua.isnull(arg_3_0.effect) then
		arg_3_0.effect:removeSelf()

		arg_3_0.effect = nil
	end

	for iter_3_0 = 1, 6 do
		local var_3_0 = xyd.tables.sevenDayLogin:giftId(iter_3_0)
		local var_3_1 = false
		local var_3_2 = arg_3_0:nodeByName("item_" .. iter_3_0)
		local var_3_3 = var_0_3:items(var_3_0)[1]
		local var_3_4 = var_0_3:itemNum(var_3_0)[1]

		xyd.setItemAndAddTips(var_3_2:getChildByName("icon"), var_3_3, var_3_4)
		var_3_2:getChildByName("item_shadow"):setVisible(false)
		var_3_2:getChildByName("bg_item_can_get"):setVisible(false)

		if iter_3_0 <= arg_3_0.canRewardDay then
			if iter_3_0 <= arg_3_0.hasRewardDay then
				var_3_2:getChildByName("item_shadow"):setVisible(true)
				var_3_2:getChildByName("text_item"):setString(string.format(var_0_1:translation("SIGN_IN_DAY_INDEX_TEXT"), var_0_1:translation("NUM_" .. iter_3_0)))
				var_3_2:getChildByName("text_item"):enableOutline(cc.c4b(72, 74, 160, 255), 2)
			else
				var_3_1 = true

				var_3_2:getChildByName("bg_item_can_get"):setVisible(true)
				var_3_2:getChildByName("text_item"):setString(var_0_1:translation("GET"))
				var_3_2:getChildByName("text_item"):enableOutline(cc.c4b(187, 64, 87, 255), 2)
			end
		else
			var_3_2:getChildByName("text_item"):setString(string.format(var_0_1:translation("SIGN_IN_DAY_INDEX_TEXT"), var_0_1:translation("NUM_" .. iter_3_0)))
			var_3_2:getChildByName("text_item"):enableOutline(cc.c4b(72, 74, 160, 255), 2)
		end

		if var_3_1 then
			local var_3_5 = "skeletons/ui_effect/seven_day_login/qiruhuodonglight"
			local var_3_6 = var_3_5 .. ".json"
			local var_3_7 = var_3_5 .. ".atlas"

			arg_3_0.effect = var_0_4.new(var_3_6, var_3_7, 1)

			arg_3_0.effect:addTo(var_3_2)
			arg_3_0.effect:setPosition(var_3_2:getChildByName("bg_item_can_get"):getPosition())
			arg_3_0.effect:play(nil, true)

			local var_3_8 = display.newNode()

			var_3_8:setContentSize(var_3_2:getContentSize())
			var_3_8:addTo(var_3_2)
			var_3_8:setTouchEnabled(true)
			var_3_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
				if arg_4_0.name == "began" then
					var_3_2:setScale(0.9)
				elseif arg_4_0.name == "ended" then
					var_3_2:setScale(1)
					arg_3_0:getReward()
				end

				return true
			end)
		end
	end

	local var_3_9 = "windows/seven_day_login/pic_hero.png"

	xyd.SpriteLoader.new(var_3_9, nil, nil, xyd.DefaultImageType.HOME_CARD):addTo(arg_3_0:nodeByName("node_hero"))

	local var_3_10 = xyd.tables.sevenDayLogin:giftId(7)
	local var_3_11 = var_0_3:items(var_3_10)[1]
	local var_3_12 = tonumber(var_3_11)

	arg_3_0:nodeByName("txt_hero_name"):setString(var_0_2:name(var_3_12))
	arg_3_0:nodeByName("txt_hero_name"):enableOutline(cc.c4b(186, 54, 110, 255), 2)

	if var_0_2:getCV(var_3_12) ~= "" then
		arg_3_0:nodeByName("txt_cv"):setString("CV:" .. var_0_2:getCV(var_3_12))
		arg_3_0:nodeByName("txt_cv"):enableOutline(cc.c4b(117, 35, 70, 255), 2)
	end

	arg_3_0:nodeByName("txt_hero_desc"):setString(var_0_2:getDes(var_3_12))
	arg_3_0:nodeByName("txt_hero_desc"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_3_0:nodeByName("txt_seven"):setString(var_0_1:translation("SIGN_IN_SEVEN_DAY_REWARD"))
	arg_3_0:nodeByName("txt_seven"):enableOutline(cc.c4b(145, 55, 82, 255), 2)
	arg_3_0:nodeByName("txt_seven"):getVirtualRenderer():setAdditionalKerning(3)

	if arg_3_0.canRewardDay < 2 then
		arg_3_0:nodeByName("txt_desc"):setString(var_0_1:translation("SEVEN_DAY_LOGIN_TEXT_1"))

		local var_3_13 = 2 - arg_3_0.canRewardDay
		local var_3_14 = xyd.createSpriteFromPlist("windows/seven_day_login/num_" .. var_3_13 .. ".png", "windows/seven_day_login/pl_main.plist")

		arg_3_0:nodeByName("node_day"):removeAllChildren()
		var_3_14:addTo(arg_3_0:nodeByName("node_day"))

		local var_3_15 = xyd.createSpriteFromPlist("windows/seven_day_login/summon.png", "windows/seven_day_login/pl_main.plist")

		arg_3_0:nodeByName("node_hero_name"):removeAllChildren()
		var_3_15:addTo(arg_3_0:nodeByName("node_hero_name"))
	elseif arg_3_0.canRewardDay < 7 then
		arg_3_0:nodeByName("txt_desc"):setString(var_0_1:translation("SEVEN_DAY_LOGIN_TEXT_1"))

		local var_3_16 = 7 - arg_3_0.canRewardDay
		local var_3_17 = xyd.createSpriteFromPlist("windows/seven_day_login/num_" .. var_3_16 .. ".png", "windows/seven_day_login/pl_main.plist")

		arg_3_0:nodeByName("node_day"):removeAllChildren()
		var_3_17:addTo(arg_3_0:nodeByName("node_day"))

		local var_3_18 = xyd.AssetLoader.get():loadSprite("windows/seven_day_login/hero_name.png")

		arg_3_0:nodeByName("node_hero_name"):removeAllChildren()
		var_3_18:addTo(arg_3_0:nodeByName("node_hero_name"))
	else
		arg_3_0:nodeByName("txt_desc"):setString(var_0_1:translation("SEVEN_DAY_LOGIN_TEXT_2"))

		local var_3_19 = xyd.createSpriteFromPlist("windows/seven_day_login/num_7.png", "windows/seven_day_login/pl_main.plist")

		arg_3_0:nodeByName("node_day"):removeAllChildren()
		var_3_19:addTo(arg_3_0:nodeByName("node_day"))

		local var_3_20 = xyd.AssetLoader.get():loadSprite("windows/seven_day_login/hero_name.png")

		arg_3_0:nodeByName("node_hero_name"):removeAllChildren()
		var_3_20:addTo(arg_3_0:nodeByName("node_hero_name"))
	end

	arg_3_0:nodeByName("txt_desc"):enableOutline(cc.c4b(160, 61, 88, 255), 2)

	local var_3_21 = arg_3_0:nodeByName("btn_get_hero")

	arg_3_0:nodeByName("txt_get_hero"):setString(var_0_1:translation("GET"))
	arg_3_0:nodeByName("btn_get_hero"):setVisible(arg_3_0.canRewardDay >= 7)
	var_3_21:addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0:getReward()
		end
	end)
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	arg_6_0:addBlockLayer()
end

function var_0_0.getReward(arg_7_0)
	local var_7_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)

	var_7_0:getActivityReward(xyd.Activities.SevenDayLogin, nil, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK and arg_8_1.awards then
			xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_8_1.awards, function()
				local var_9_0 = {
					activity_id = xyd.Activities.SevenDayLogin
				}

				var_7_0:loadSingleActivity(var_9_0, function(arg_10_0, arg_10_1)
					if arg_10_0 == xyd.error.OK then
						if arg_10_1.is_open ~= 1 then
							local var_10_0 = xyd.WindowManager.get():getWindow("main_scene_top")

							if var_10_0 then
								var_10_0:updateSevenDayLogin(true)
							end

							arg_7_0:close()
						else
							arg_7_0.details = arg_10_1.details
							arg_7_0.hasRewardDay = arg_7_0.details.award_id
							arg_7_0.canRewardDay = arg_7_0.details.login_day
							arg_7_0.canRewardDay = math.min(arg_7_0.canRewardDay, arg_7_0.hasRewardDay + 1)

							arg_7_0:layout()
						end
					end
				end)
			end)
		end
	end)
end

function var_0_0.willClose(arg_11_0, arg_11_1)
	var_0_0.super.willClose(arg_11_0, arg_11_1)

	if arg_11_0.callback then
		arg_11_0.callback()
	end
end

return var_0_0
