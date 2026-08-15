local var_0_0 = class("FirstStoreAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.item
local var_0_2 = xyd.tables.gift
local var_0_3 = 980
local var_0_4 = 90001001
local var_0_5 = 90001067
local var_0_6 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.params = arg_1_2
	arg_1_0.backpack = arg_1_0.player:getBackpack()
end

function var_0_0.rewardFormat(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0 = arg_2_1:getContentSize().height
	local var_2_1 = var_2_0 / 4
	local var_2_2 = xyd.tables.gift:items(arg_2_2)

	if #var_2_2 == 1 and var_2_2[1] == 0 then
		var_2_2 = {}
	end

	local var_2_3 = xyd.tables.gift:itemNum(arg_2_2)
	local var_2_4 = display.newNode()

	var_2_4:setContentSize(var_2_0, var_2_0)

	for iter_2_0 = 1, #var_2_2 do
		if xyd.tables.item:type(var_2_2[iter_2_0]) == -1 then
			xyd.setAvatarBorder(var_2_2[iter_2_0], var_2_4, 1, xyd.tables.hero:initialStar(var_2_2[iter_2_0]))
			var_2_4:addTo(arg_2_1)
			var_2_4:setAnchorPoint(cc.p(0, 0))
			var_2_4:setPosition(0, 0)

			local var_2_5 = {
				id = var_2_2[iter_2_0],
				lev = xyd.tables.item:level(var_2_2[iter_2_0])
			}

			if xyd.tables.item:type(var_2_2[iter_2_0]) == -1 then
				var_2_5.tipsType = 0
				var_2_5.desc1 = xyd.tables.hero:getDes(var_2_2[iter_2_0])
			elseif specialItem then
				var_2_5.tipsType = 1
				var_2_5.id = -3
			else
				var_2_5.tipsType = 1
				var_2_5.desc1 = xyd.tables.item:desc1(var_2_2[iter_2_0])
				var_2_5.desc2 = xyd.tables.item:desc2(var_2_2[iter_2_0])
			end

			var_2_5.name = xyd.tables.item:name(var_2_2[iter_2_0])

			arg_2_0:addTips(var_2_4, var_2_5)
		end
	end

	return arg_2_1
end

function var_0_0.rewardLayer(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local var_3_0 = arg_3_1:getContentSize().height
	local var_3_1 = var_3_0 / 4
	local var_3_2 = xyd.tables.gift:items(arg_3_2)

	if #var_3_2 == 1 and var_3_2[1] == 0 then
		var_3_2 = {}
	end

	local var_3_3 = xyd.tables.gift:itemNum(arg_3_2)
	local var_3_4 = #var_3_2

	for iter_3_0 = 1, #var_3_2 do
		if xyd.tables.item:type(var_3_2[iter_3_0]) ~= -1 then
			local var_3_5 = display.newNode()

			var_3_5:setContentSize(var_3_0, var_3_0)

			local var_3_6 = xyd.tables.item:type(var_3_2[iter_3_0])

			xyd.setItemBorder(var_3_5, var_3_2[iter_3_0], false, false, var_3_3[iter_3_0])
			var_3_5:addTo(arg_3_1)
			var_3_5:setAnchorPoint(cc.p(0, 0))
			var_3_5:setPosition((iter_3_0 - 1) * (var_3_0 + var_3_1), 0)

			local var_3_7 = {
				id = var_3_2[iter_3_0],
				lev = xyd.tables.item:level(var_3_2[iter_3_0])
			}

			if xyd.tables.item:type(var_3_2[iter_3_0]) == -1 then
				var_3_7.tipsType = 0
				var_3_7.desc1 = xyd.tables.hero:getDes(var_3_2[iter_3_0])
			elseif specialItem then
				var_3_7.tipsType = 1
				var_3_7.id = -3
			else
				var_3_7.tipsType = 1
				var_3_7.desc1 = xyd.tables.item:desc1(var_3_2[iter_3_0])
				var_3_7.desc2 = xyd.tables.item:desc2(var_3_2[iter_3_0])
			end

			var_3_7.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_3_2[iter_3_0])
			var_3_7.name = xyd.tables.item:name(var_3_2[iter_3_0])

			arg_3_0:addTips(var_3_5, var_3_7)
		end
	end

	local var_3_8 = xyd.tables.gift:crystal(arg_3_2)

	if var_3_8 and var_3_8 > 0 then
		local var_3_9 = display.newNode()

		var_3_9:setContentSize(var_3_0, var_3_0)
		xyd.setItemBorder(var_3_9, -1, false, false, var_3_8)
		var_3_9:addTo(arg_3_1)
		var_3_9:setAnchorPoint(cc.p(0, 0))
		var_3_9:setPosition(var_3_4 * (var_3_0 + var_3_1), 0)

		local var_3_10 = {}

		var_3_10.id = -1
		var_3_10.tipsType = 1

		arg_3_0:addTips(var_3_9, var_3_10)

		var_3_4 = var_3_4 + 1
	end

	local var_3_11 = xyd.tables.gift:mana(arg_3_2)

	if var_3_11 and var_3_11 > 0 then
		local var_3_12 = display.newNode()

		var_3_12:setContentSize(var_3_0, var_3_0)
		xyd.setItemBorder(var_3_12, -2, false, false, var_3_11)
		var_3_12:addTo(arg_3_1)
		var_3_12:setAnchorPoint(cc.p(0, 0))
		var_3_12:setPosition(var_3_4 * (var_3_0 + var_3_1), 0)

		local var_3_13 = {}

		var_3_13.id = -2
		var_3_13.tipsType = 1

		arg_3_0:addTips(var_3_12, var_3_13)

		var_3_4 = var_3_4 + 1
	end

	local var_3_14 = xyd.tables.gift:drops(arg_3_2)
	local var_3_15 = false

	if var_3_14 and next(var_3_14) then
		var_3_15 = #var_3_14 ~= 1 or var_3_14[1] ~= 0
	end

	if var_3_15 and arg_3_3 and arg_3_3.table_id == xyd.Activities.OnlineReward then
		local var_3_16 = display.newNode()

		var_3_16:addTo(arg_3_1)
		var_3_16:setAnchorPoint(cc.p(0.5, 0.5))
		var_3_16:setPosition(var_3_4 * (var_3_0 + var_3_1), 0)
		var_3_16:setContentSize(var_3_0, var_3_0)

		local var_3_17 = xyd.AssetLoader.get():loadSprite("images/icon/black_bg.png")

		if var_3_17 then
			local var_3_18 = var_3_16:getWidth()
			local var_3_19 = var_3_16:getHeight()
			local var_3_20 = var_3_18 / var_3_17:getWidth()

			var_3_17:setScale(var_3_20)
			var_3_17:addTo(var_3_16)
			var_3_17:setAnchorPoint(cc.p(0.5, 0.5))
			var_3_17:setPosition(var_3_18 / 2, var_3_19 / 2)

			local var_3_21 = xyd.getBorder(0, false)

			xyd.displaySpriteOnContainer(var_3_21, var_3_16, true)
		end

		local var_3_22 = {}

		var_3_22.id = -3
		var_3_22.tipsType = 1

		arg_3_0:addTips(var_3_16, var_3_22)

		local var_3_23 = var_3_4 + 1
	end

	return arg_3_1
end

function var_0_0.layout(arg_4_0)
	local var_4_0
	local var_4_1 = arg_4_0:nodeByName("hero_list")

	arg_4_0:rewardFormat(var_4_1, var_0_5)

	local var_4_2 = arg_4_0:nodeByName("hero_list2")

	arg_4_0:rewardFormat(var_4_2, var_0_4)
	var_4_1:addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			var_4_1:scale(0.95)
		elseif arg_5_1 == ccui.TouchEventType.ended then
			var_4_1:scale(1)
		end
	end)
	var_4_2:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			var_4_2:scale(0.95)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			var_4_2:scale(1)
		end
	end)
	arg_4_0:rewardLayer(arg_4_0:nodeByName("list"), var_0_5)
	arg_4_0:rewardLayer(arg_4_0:nodeByName("list2"), var_0_4)
	arg_4_0:nodeByName("txt_tips"):setString(var_0_6:translation("FIRST_STORE_AWARD_TIPS"))

	arg_4_0.hasUnlimitGift = arg_4_0.params.hasUnlimitGift
	arg_4_0.UnlimitTableId = arg_4_0.params.UnlimitTableId
	arg_4_0.hasAwardGift = arg_4_0.params.details.is_awarded

	if arg_4_0.hasUnlimitGift == 0 and arg_4_0.params.details.charge == 0 then
		arg_4_0:nodeByName("rechar"):show()
		arg_4_0:nodeByName("getaward"):hide()
		arg_4_0:nodeByName("alreadyget"):hide()
		arg_4_0:nodeByName("hero_list2"):show()
		arg_4_0:nodeByName("list2"):show()
		arg_4_0:nodeByName("text1"):show()
		arg_4_0:nodeByName("hero_list"):hide()
		arg_4_0:nodeByName("list"):hide()
		arg_4_0:nodeByName("text2"):hide()
		arg_4_0:nodeByName("btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_7_0 = {
					chargeState = xyd.ChargeState.diamond
				}

				xyd.WindowManager.get():openWindow("vip_recharge", var_7_0)
			end
		end)
	elseif arg_4_0.hasUnlimitGift == 0 and arg_4_0.params.details.charge > 0 then
		arg_4_0:nodeByName("rechar"):hide()
		arg_4_0:nodeByName("getaward"):show()
		arg_4_0:nodeByName("alreadyget"):hide()
		arg_4_0:nodeByName("hero_list2"):show()
		arg_4_0:nodeByName("list2"):show()
		arg_4_0:nodeByName("text1"):show()
		arg_4_0:nodeByName("hero_list"):hide()
		arg_4_0:nodeByName("list"):hide()
		arg_4_0:nodeByName("text2"):hide()
		arg_4_0:nodeByName("btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
			if arg_8_1 == ccui.TouchEventType.ended then
				arg_4_0.activitiesModel:getActivityReward(arg_4_0.UnlimitTableId, nil, function(arg_9_0, arg_9_1)
					if arg_9_0 == xyd.error.OK then
						arg_4_0.player:handleRewards(arg_9_1.awards)
						arg_4_0.activitiesModel:clearRedMarkState(arg_4_0.UnlimitTableId, 2)

						if arg_4_0.activitiesModel.activities and next(arg_4_0.activitiesModel.activities) then
							for iter_9_0, iter_9_1 in ipairs(arg_4_0.activitiesModel.activities) do
								if iter_9_1.table_id == xyd.Activities.FirstRecharge and iter_9_1.is_open == 1 and iter_9_1.details and iter_9_1.details.is_awarded == 0 then
									arg_4_0.activitiesModel.activities[iter_9_0].details.is_awards = 1
								end

								if iter_9_1.table_id == xyd.Activities.FirstStoreAward and iter_9_1.is_open == 1 then
									local var_9_0 = false

									if iter_9_1.details and iter_9_1.details.is_awarded == 0 and iter_9_1.details.charge >= var_0_3 then
										var_9_0 = true
									end

									xyd.EventDispatcher.get():dispatchEvent({
										name = xyd.event.REFRESH_CHARGE_ACTIVITY_MAIN,
										params = {
											isShow = true,
											hasPoint = var_9_0
										}
									})
								end
							end
						end
					end
				end)

				if arg_4_0.params.details.charge < var_0_3 then
					arg_4_0:nodeByName("rechar"):show()
					arg_4_0:nodeByName("getaward"):hide()
					arg_4_0:nodeByName("hero_list2"):hide()
					arg_4_0:nodeByName("list2"):hide()
					arg_4_0:nodeByName("text1"):hide()
					arg_4_0:nodeByName("hero_list"):show()
					arg_4_0:nodeByName("list"):show()
					arg_4_0:nodeByName("text2"):show()
					arg_4_0:nodeByName("btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
						if arg_10_1 == ccui.TouchEventType.ended then
							xyd.playButtonSound()

							local var_10_0 = {
								chargeState = xyd.ChargeState.diamond
							}

							xyd.WindowManager.get():openWindow("vip_recharge", var_10_0)
						end
					end)
				else
					arg_4_0:nodeByName("hero_list2"):hide()
					arg_4_0:nodeByName("list2"):hide()
					arg_4_0:nodeByName("text1"):hide()
					arg_4_0:nodeByName("hero_list"):show()
					arg_4_0:nodeByName("list"):show()
					arg_4_0:nodeByName("text2"):show()
					arg_4_0:nodeByName("btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
						if arg_11_1 == ccui.TouchEventType.ended then
							local var_11_0 = arg_4_0.params.details.award_id

							arg_4_0.activitiesModel:getActivityReward(xyd.Activities.FirstStoreAward, var_11_0, function(arg_12_0, arg_12_1)
								arg_4_0.player:handleRewards(arg_12_1.awards)
								xyd.EventDispatcher.get():dispatchEvent({
									name = xyd.event.REFRESH_CHARGE_ACTIVITY_MAIN,
									params = {
										hasPoint = false,
										isShow = false
									}
								})
							end)
							arg_4_0:nodeByName("getaward"):hide()
							arg_4_0:nodeByName("alreadyget"):show()
							arg_4_0:nodeByName("btn"):setTouchEnabled(false)
							arg_4_0:nodeByName("btn"):setBright(false)
						end
					end)
				end
			end
		end)
	elseif arg_4_0.hasUnlimitGift == 1 and arg_4_0.hasAwardGift == 0 and arg_4_0.params.details.charge < var_0_3 then
		arg_4_0:nodeByName("rechar"):show()
		arg_4_0:nodeByName("getaward"):hide()
		arg_4_0:nodeByName("alreadyget"):hide()
		arg_4_0:nodeByName("hero_list2"):hide()
		arg_4_0:nodeByName("list2"):hide()
		arg_4_0:nodeByName("text1"):hide()
		arg_4_0:nodeByName("hero_list"):show()
		arg_4_0:nodeByName("list"):show()
		arg_4_0:nodeByName("text2"):show()
		arg_4_0:nodeByName("btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
			if arg_13_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_13_0 = {
					chargeState = xyd.ChargeState.diamond
				}

				xyd.WindowManager.get():openWindow("vip_recharge", var_13_0)
			end
		end)
	elseif arg_4_0.hasUnlimitGift == 1 and arg_4_0.hasAwardGift == 0 and arg_4_0.params.details.charge >= var_0_3 then
		arg_4_0:nodeByName("rechar"):hide()
		arg_4_0:nodeByName("getaward"):show()
		arg_4_0:nodeByName("alreadyget"):hide()
		arg_4_0:nodeByName("hero_list2"):hide()
		arg_4_0:nodeByName("list2"):hide()
		arg_4_0:nodeByName("text1"):hide()
		arg_4_0:nodeByName("hero_list"):show()
		arg_4_0:nodeByName("list"):show()
		arg_4_0:nodeByName("text2"):show()
		arg_4_0:nodeByName("btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
			if arg_14_1 == ccui.TouchEventType.ended then
				local var_14_0 = arg_4_0.params.details.award_id

				arg_4_0.activitiesModel:getActivityReward(xyd.Activities.FirstStoreAward, var_14_0, function(arg_15_0, arg_15_1)
					arg_4_0.player:handleRewards(arg_15_1.awards)
					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.REFRESH_CHARGE_ACTIVITY_MAIN,
						params = {
							hasPoint = false,
							isShow = false
						}
					})
				end)
				arg_4_0:nodeByName("getaward"):hide()
				arg_4_0:nodeByName("alreadyget"):show()
				arg_4_0:nodeByName("btn"):setTouchEnabled(false)
				arg_4_0:nodeByName("btn"):setBright(false)
			end
		end)
	elseif arg_4_0.hasUnlimitGift == 1 and arg_4_0.hasAwardGift == 1 then
		arg_4_0:nodeByName("rechar"):hide()
		arg_4_0:nodeByName("getaward"):hide()
		arg_4_0:nodeByName("alreadyget"):show()
		arg_4_0:nodeByName("hero_list2"):hide()
		arg_4_0:nodeByName("list2"):hide()
		arg_4_0:nodeByName("text1"):hide()
		arg_4_0:nodeByName("hero_list"):show()
		arg_4_0:nodeByName("list"):show()
		arg_4_0:nodeByName("text2"):show()
		arg_4_0:nodeByName("btn"):setTouchEnabled(false)
		arg_4_0:nodeByName("btn"):setBright(false)
	end

	local var_4_3 = arg_4_0:nodeByName("bar_text")
	local var_4_4 = arg_4_0:nodeByName("bar")
	local var_4_5 = 100
	local var_4_6

	var_4_3:enableShadow(xyd.color.FONT_SHADOW_A)

	local var_4_7 = arg_4_0.params.details.charge >= var_0_3 and 100 or math.min(arg_4_0.params.details.charge / var_0_3 * 100, 100)

	var_4_3:setString(xyd.tables.translation:translation("ALREADY_DEAL") .. arg_4_0.params.details.charge .. "/" .. var_0_3)
	var_4_4:setPercent(var_4_7)
end

function var_0_0.willOpen(arg_16_0, arg_16_1)
	arg_16_0:layout()
end

function var_0_0.didOpen(arg_17_0)
	arg_17_0:addBlockLayer()
end

return var_0_0
