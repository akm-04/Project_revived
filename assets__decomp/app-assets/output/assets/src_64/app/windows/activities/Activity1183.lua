local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = xyd.tables.hero
local var_0_4 = xyd.tables.model
local var_0_5 = import("framework.scheduler")
local var_0_6 = {
	txt_not_enough = var_0_1:translation("LOVA_LETTER_NOT_ENOUGH")
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activityModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.details = {}
	arg_1_0.raffle_type = {}
	arg_1_0.keyID = var_0_2:getValue("activity_love_letter_id")

	arg_1_0:getActivityInfo()
end

function var_0_0.getActivityInfo(arg_2_0)
	arg_2_0.activity = arg_2_0.activitiesModel:getActivityInfo(xyd.Activities.LOVELETTER)
	arg_2_0.details = arg_2_0.activity.details
	arg_2_0.award_times = arg_2_0.details.award_times
end

function var_0_0.show(arg_3_0, arg_3_1)
	var_0_0.super.show(arg_3_0, arg_3_1)

	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_3_0.res)

	var_3_0:addTo(arg_3_0.parent)

	arg_3_0.container = var_3_0:getChildByName("container")

	arg_3_0:layout(arg_3_0.activity, arg_3_0.idx)
end

function var_0_0.layout(arg_4_0, arg_4_1, arg_4_2)
	if not arg_4_0.res or arg_4_0.res == 0 then
		print("No res available.")

		return
	end

	arg_4_0.listContainer = arg_4_0.container:getChildByName("txt_rule")

	local var_4_0 = arg_4_0.listContainer:getContentSize()

	arg_4_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_4_0.listContainer):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0:initRule()
	arg_4_0:initTXT()
	arg_4_0:initSprite()
	arg_4_0:updateTXT()
	arg_4_0:initBtnSummon()
	arg_4_0:initHeroShow()
	arg_4_0.container:getChildByName("btn_lookover"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("love_look_over_hero")
		end
	end)

	if arg_4_0.activity.is_open == 1 then
		arg_4_0.container:getChildByName("btn_change"):addTouchEventListener(function(arg_6_0, arg_6_1)
			xyd.buttonScaleAnim(arg_6_0, arg_6_1)

			if arg_6_1 == ccui.TouchEventType.ended then
				if arg_4_0.player.vip < 9 then
					local var_6_0 = var_0_1:translation("LOVE_LETTER_EXCHANGE_LIMIT_TIP")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_6_0
					})

					return
				end

				xyd.WindowManager.get():openWindow("love_letter_change_hero")
			end
		end)
	end
end

function var_0_0.initHeroShow(arg_7_0)
	local var_7_0 = var_0_2:getValue("activity_love_letter_show")

	for iter_7_0, iter_7_1 in ipairs(var_7_0) do
		local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1183/show_hero_item.csb")
		local var_7_2 = xyd.AssetLoader.get():loadSprite("windows/activities/1183/hero_show/" .. iter_7_0 .. ".png")

		var_7_2:setAnchorPoint(0, 0)
		var_7_1:getChildByName("card_pos"):addChild(var_7_2)
		var_7_1:getChildByName("txt_name"):setString(var_0_3:name(iter_7_1) .. "UP")
		var_7_1:setPosition((iter_7_0 - 1) * 163, 0)
		arg_7_0.container:getChildByName("hero_container"):addChild(var_7_1)
	end
end

function var_0_0.initSprite(arg_8_0)
	local var_8_0 = "images/icon/eco/icon_crystal.png"
	local var_8_1 = "windows/activities/1183/icon_love_letter.png"
	local var_8_2 = xyd.AssetLoader.get():loadSprite(var_8_0)

	var_8_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_2:setPosition(arg_8_0.container:getChildByName("icon_ten_cost"):getPosition())
	var_8_2:setScale(0.85)
	var_8_2:addTo(arg_8_0.container)
	var_8_2:setName("icon_ten_crystal")

	local var_8_3 = xyd.AssetLoader.get():loadSprite(var_8_1)

	var_8_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_3:setPosition(arg_8_0.container:getChildByName("icon_ten_cost"):getPosition())
	var_8_3:setScale(0.85)
	var_8_3:addTo(arg_8_0.container)
	var_8_3:setName("icon_ten_letter")

	local var_8_4 = xyd.AssetLoader.get():loadSprite(var_8_0)

	var_8_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_4:setPosition(arg_8_0.container:getChildByName("icon_once_cost"):getPosition())
	var_8_4:setScale(0.85)
	var_8_4:addTo(arg_8_0.container)
	var_8_4:setName("icon_one_crystal")

	local var_8_5 = xyd.AssetLoader.get():loadSprite(var_8_1)

	var_8_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_5:setPosition(arg_8_0.container:getChildByName("icon_once_cost"):getPosition())
	var_8_5:setScale(0.85)
	var_8_5:addTo(arg_8_0.container)
	var_8_5:setName("icon_one_letter")
end

function var_0_0.initTXT(arg_9_0)
	arg_9_0.container:getChildByName("btn_lookover"):getChildByName("txt_lookfor"):enableOutline(cc.c4b(179, 49, 83, 255), 2)
	arg_9_0.container:getChildByName("btn_change"):getChildByName("txt_change"):enableOutline(cc.c4b(179, 49, 83, 255), 2)
end

function var_0_0.updateTXT(arg_10_0, arg_10_1)
	arg_10_0.award_times = arg_10_1 or arg_10_0.award_times

	local var_10_0, var_10_1 = xyd.tables.misc:getValue("activity_love_letter_normal_times"), xyd.tables.misc:getValue("activity_love_letter_sx_times")

	if arg_10_0.player.vip >= 9 then
		var_10_0 = var_10_1
	end

	arg_10_0.container:getChildByName("txt_guarantee"):setString(arg_10_0.award_times .. "/" .. var_10_0)

	local var_10_2 = arg_10_0.container:getChildByName("btn_summon_guarantee")
	local var_10_3 = arg_10_0.container:getChildByName("btn_summon_guarantee2")

	if var_10_0 > arg_10_0.award_times then
		var_10_2:setVisible(false)
		var_10_3:setVisible(true)
	else
		var_10_2:setVisible(true)
		var_10_3:setVisible(false)
	end

	local var_10_4 = arg_10_0.player:getBackpack():getItemNumByID(arg_10_0.keyID) or 0

	arg_10_0.container:getChildByName("num_love_letter"):setString("X " .. var_10_4)

	local var_10_5 = xyd.tables.misc:getValue("activity_love_letter_price")
	local var_10_6
	local var_10_7

	if var_10_4 <= 0 then
		var_10_6 = var_10_5[1]
		var_10_7 = var_10_5[2]
		arg_10_0.raffle_type[1] = 1
		arg_10_0.raffle_type[2] = 1

		arg_10_0.container:getChildByName("icon_ten_crystal"):setVisible(true)
		arg_10_0.container:getChildByName("icon_ten_letter"):setVisible(false)
		arg_10_0.container:getChildByName("icon_one_crystal"):setVisible(true)
		arg_10_0.container:getChildByName("icon_one_letter"):setVisible(false)
	elseif var_10_4 < 10 and var_10_4 >= 1 then
		var_10_6 = 1
		var_10_7 = var_10_5[2]
		arg_10_0.raffle_type[1] = 2
		arg_10_0.raffle_type[2] = 1

		arg_10_0.container:getChildByName("icon_ten_crystal"):setVisible(true)
		arg_10_0.container:getChildByName("icon_ten_letter"):setVisible(false)
		arg_10_0.container:getChildByName("icon_one_crystal"):setVisible(false)
		arg_10_0.container:getChildByName("icon_one_letter"):setVisible(true)
	else
		var_10_6 = 1
		var_10_7 = 10
		arg_10_0.raffle_type[1] = 2
		arg_10_0.raffle_type[2] = 2

		arg_10_0.container:getChildByName("icon_ten_crystal"):setVisible(false)
		arg_10_0.container:getChildByName("icon_ten_letter"):setVisible(true)
		arg_10_0.container:getChildByName("icon_one_crystal"):setVisible(false)
		arg_10_0.container:getChildByName("icon_one_letter"):setVisible(true)
	end

	arg_10_0.container:getChildByName("txt_cost_once"):setString(var_10_6)
	arg_10_0.container:getChildByName("txt_cost_ten"):setString(var_10_7)
end

function var_0_0.initRule(arg_11_0)
	local var_11_0 = xyd.split(var_0_1:translation("LOVE_LETTER_RULE"), "\n")

	for iter_11_0 = 1, #var_11_0 do
		local var_11_1 = display.newNode()
		local var_11_2 = arg_11_0.list:newItem()
		local var_11_3 = {
			size = 20,
			color = cc.c3b(240, 171, 191),
			dimensions = cc.size(586, 0),
			text = var_11_0[iter_11_0]
		}
		local var_11_4 = xyd.AssetLoader.get():loadLabel(var_11_3)
		local var_11_5 = var_11_4:getContentSize().height

		var_11_1:setContentSize(630, var_11_5)

		local var_11_6 = xyd.AssetLoader.get():loadSprite("windows/activities/1183/love.png")

		var_11_6:setAnchorPoint(0.5, 1)
		var_11_6:setPosition(13, var_11_5 - 3)
		var_11_1:addChild(var_11_6)
		var_11_4:setAnchorPoint(cc.p(0, 0))
		var_11_4:setPosition(cc.p(35, 0))
		var_11_1:addChild(var_11_4)
		var_11_2:addContent(var_11_1)
		var_11_2:setItemSize(630, var_11_5 + 10)
		arg_11_0.list:addItem(var_11_2)
	end

	arg_11_0.list:reload()
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevX_ = arg_12_1.x
		arg_12_0.prevY_ = arg_12_1.y
	elseif arg_12_1.name == "moved" and 5 <= math.abs(arg_12_1.y - arg_12_0.prevY_) then
		arg_12_0.scrollViewMoved_ = true
	end
end

function var_0_0.initBtnSummon(arg_13_0)
	local var_13_0 = arg_13_0.player:getBackpack():getItemNumByID(arg_13_0.keyID) or 0
	local var_13_1 = xyd.tables.misc:getValue("activity_love_letter_price")
	local var_13_2 = {}
	local var_13_3 = {}
	local var_13_4 = {}

	var_13_2[1] = var_0_1:translation("LOVE_LETTER_TAKE_ZUANSHI")
	var_13_2[2] = var_0_1:translation("LOVE_LETTER_TAKE_LETTER")
	var_13_3[1] = var_13_1[1]
	var_13_3[2] = 1
	var_13_4[1] = var_13_1[2]
	var_13_4[2] = 10

	local var_13_5 = arg_13_0.container:getChildByName("icon_love_letter")

	var_13_5:setTouchSwallowEnabled(false)
	var_13_5:setTouchEnabled(true)

	if arg_13_0.activity.is_open == 0 then
		return
	end

	local var_13_6 = arg_13_0.container:getChildByName("btn_summon_guarantee")
	local var_13_7 = 0.2
	local var_13_8 = cc.Spawn:create({
		cc.Sequence:create({
			cc.MoveBy:create(var_13_7, cc.p(5, 0)),
			cc.MoveBy:create(var_13_7, cc.p(-10, 0)),
			cc.MoveBy:create(var_13_7, cc.p(5, 0)),
			cc.DelayTime:create(var_13_7 * 3)
		}),
		cc.Sequence:create({
			cc.RotateBy:create(var_13_7, 15),
			cc.RotateBy:create(var_13_7, -30),
			cc.RotateBy:create(var_13_7, 15),
			cc.DelayTime:create(var_13_7 * 3)
		})
	})

	var_13_6:runAction(cc.RepeatForever:create(var_13_8))
	var_13_6:addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(arg_14_0, arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			local var_14_0 = {}

			xyd.Backend.get():request(xyd.mid.LOVE_LETTER_GUARANTEE, var_14_0, function(arg_15_0, arg_15_1)
				if arg_15_0 == xyd.error.OK and arg_15_1 and arg_15_1.awards and arg_15_1.award_times then
					arg_13_0.award_times = arg_15_1.award_times

					arg_13_0.player:handleRewardsWithoutShow(arg_15_1.awards)

					local var_15_0 = {}
					local var_15_1 = {}

					for iter_15_0, iter_15_1 in pairs(arg_15_1.awards) do
						if tonumber(iter_15_0) then
							table.insert(var_15_1, iter_15_1)
						end
					end

					var_15_0.leave = true
					var_15_0.items = var_15_1
					var_15_0.useNum = var_14_0.times
					var_15_0.costType = var_14_0.raffle_type

					function var_15_0.callback(arg_16_0)
						arg_13_0:updateTXT(arg_16_0)
					end

					xyd.WindowManager.get():openWindow("love_summon_result", var_15_0)
				end

				arg_13_0:updateTXT()
			end)
		end
	end)
	arg_13_0.container:getChildByName("btn_summon_once"):addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(arg_17_0, arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended then
			local var_17_0 = {
				times = 1,
				raffle_type = arg_13_0.raffle_type[1]
			}

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_13_2[var_17_0.raffle_type], var_13_3[var_17_0.raffle_type]), function()
				if var_17_0.raffle_type == 1 then
					if arg_13_0.player.crystal < var_13_3[1] then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
							local var_19_0 = {}

							var_19_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_19_0)
						end, nil, nil, xyd.ColorMode.ACTIVITY)
					else
						xyd.Backend.get():request(xyd.mid.LOVE_LETTER_RAFFLE, var_17_0, function(arg_20_0, arg_20_1)
							if arg_20_0 == xyd.error.OK then
								if arg_20_1 and arg_20_1.awards and arg_20_1.award_times then
									arg_13_0.award_times = arg_20_1.award_times

									arg_13_0.player:handleRewardsWithoutShow(arg_20_1.awards)

									local var_20_0 = {}
									local var_20_1 = {}

									for iter_20_0, iter_20_1 in pairs(arg_20_1.awards) do
										if tonumber(iter_20_0) then
											table.insert(var_20_1, iter_20_1)
										end
									end

									var_20_0.items = var_20_1
									var_20_0.useNum = var_17_0.times
									var_20_0.costType = var_17_0.raffle_type

									function var_20_0.callback(arg_21_0)
										arg_13_0:updateTXT(arg_21_0)
									end

									xyd.WindowManager.get():openWindow("love_summon_result", var_20_0)
								end
							else
								xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_1:translation("STICK_BLESS_NO_CRYSTAL"), nil, nil, nil, xyd.ColorMode.ACTIVITY)
							end

							arg_13_0:updateTXT()
						end)
					end
				elseif var_13_0 < var_17_0.times then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_6.txt_not_enough, nil, nil, nil, xyd.ColorMode.ACTIVITY)
				else
					xyd.Backend.get():request(xyd.mid.LOVE_LETTER_RAFFLE, var_17_0, function(arg_22_0, arg_22_1)
						if arg_22_0 == xyd.error.OK then
							if arg_22_1 and arg_22_1.awards and arg_22_1.award_times then
								arg_13_0.award_times = arg_22_1.award_times

								arg_13_0.player:handleRewardsWithoutShow(arg_22_1.awards)

								local var_22_0 = arg_13_0.player:getBackpack()
								local var_22_1 = {
									itemID = arg_13_0.keyID,
									itemNum = var_17_0.times
								}

								var_22_0:removeItem(var_22_1)

								local var_22_2 = {}
								local var_22_3 = {}

								for iter_22_0, iter_22_1 in pairs(arg_22_1.awards) do
									if tonumber(iter_22_0) then
										table.insert(var_22_3, iter_22_1)
									end
								end

								var_22_2.items = var_22_3
								var_22_2.useNum = var_17_0.times
								var_22_2.costType = var_17_0.raffle_type

								function var_22_2.callback(arg_23_0)
									arg_13_0:updateTXT(arg_23_0)
								end

								xyd.WindowManager.get():openWindow("love_summon_result", var_22_2)
							end
						else
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_6.txt_not_enough, nil, nil, nil, xyd.ColorMode.ACTIVITY)
						end

						arg_13_0:updateTXT()
					end)
				end
			end, nil, 0, xyd.ColorMode.ACTIVITY)
		end
	end)
	arg_13_0.container:getChildByName("btn_summon_ten"):addTouchEventListener(function(arg_24_0, arg_24_1)
		xyd.buttonScaleAnim(arg_24_0, arg_24_1)

		if arg_24_1 == ccui.TouchEventType.ended then
			local var_24_0 = {
				times = 10,
				raffle_type = arg_13_0.raffle_type[2]
			}

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_13_2[var_24_0.raffle_type], var_13_4[var_24_0.raffle_type]), function()
				if var_24_0.raffle_type == 1 then
					if arg_13_0.player.crystal < var_13_4[1] then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
							local var_26_0 = {}

							var_26_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_26_0)
						end, nil, nil, xyd.ColorMode.ACTIVITY)
					else
						xyd.Backend.get():request(xyd.mid.LOVE_LETTER_RAFFLE, var_24_0, function(arg_27_0, arg_27_1)
							if arg_27_0 == xyd.error.OK then
								if arg_27_1 and arg_27_1.awards and arg_27_1.award_times then
									arg_13_0.award_times = arg_27_1.award_times

									arg_13_0.player:handleRewardsWithoutShow(arg_27_1.awards)

									local var_27_0 = {}
									local var_27_1 = {}

									for iter_27_0, iter_27_1 in pairs(arg_27_1.awards) do
										if tonumber(iter_27_0) then
											table.insert(var_27_1, iter_27_1)
										end
									end

									var_27_0.items = var_27_1
									var_27_0.useNum = var_24_0.times
									var_27_0.costType = var_24_0.raffle_type

									function var_27_0.callback(arg_28_0)
										arg_13_0:updateTXT(arg_28_0)
									end

									xyd.WindowManager.get():openWindow("love_summon_result", var_27_0)
								end
							else
								xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_1:translation("STICK_BLESS_NO_CRYSTAL"), nil, nil, nil, xyd.ColorMode.ACTIVITY)
							end

							arg_13_0:updateTXT()
						end)
					end
				elseif var_13_0 < var_24_0.times then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_6.txt_not_enough, nil, nil, nil, xyd.ColorMode.ACTIVITY)
				else
					xyd.Backend.get():request(xyd.mid.LOVE_LETTER_RAFFLE, var_24_0, function(arg_29_0, arg_29_1)
						if arg_29_0 == xyd.error.OK then
							if arg_29_1 and arg_29_1.awards and arg_29_1.award_times then
								arg_13_0.award_times = arg_29_1.award_times

								arg_13_0.player:handleRewardsWithoutShow(arg_29_1.awards)

								local var_29_0 = arg_13_0.player:getBackpack()
								local var_29_1 = {
									itemID = arg_13_0.keyID,
									itemNum = var_24_0.times
								}

								var_29_0:removeItem(var_29_1)

								local var_29_2 = {}
								local var_29_3 = {}

								for iter_29_0, iter_29_1 in pairs(arg_29_1.awards) do
									if tonumber(iter_29_0) then
										table.insert(var_29_3, iter_29_1)
									end
								end

								var_29_2.items = var_29_3
								var_29_2.useNum = var_24_0.times
								var_29_2.costType = var_24_0.raffle_type

								function var_29_2.callback(arg_30_0)
									arg_13_0:updateTXT(arg_30_0)
								end

								xyd.WindowManager.get():openWindow("love_summon_result", var_29_2)
							end
						else
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_6.txt_not_enough, nil, nil, nil, xyd.ColorMode.ACTIVITY)
						end

						arg_13_0:updateTXT()
					end)
				end
			end, nil, 0, xyd.ColorMode.ACTIVITY)
		end
	end)
end

return var_0_0
