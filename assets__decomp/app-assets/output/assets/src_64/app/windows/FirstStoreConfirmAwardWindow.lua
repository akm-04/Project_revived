local var_0_0 = class("FirstStoreConfirmAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityFirstCharge
local var_0_3 = 980

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.index = arg_1_2.index
	arg_1_0.UnlimitTableId = arg_1_2.UnlimitTableId
	arg_1_0.giftId = var_0_2:giftId(arg_1_0.index)
	arg_1_0.canAward = arg_1_2.can_award
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:rewardLayer(arg_3_0:nodeByName("item_scroll"), arg_3_0.giftId)
	arg_3_0:rewardFormat(arg_3_0:nodeByName("hero_container"), arg_3_0.giftId)
	arg_3_0:setButtonClick()
	arg_3_0:nodeByName("award_text"):setString(var_0_1:translation("FIRST_STORE_AWARD_TEXT11"))
	arg_3_0:nodeByName("confirm_text"):setString(var_0_1:translation("FIRST_STORE_AWARD_TEXT10"))
	arg_3_0:nodeByName("award_text"):setString(var_0_1:translation("FIRST_STORE_AWARD_TEXT12"))

	if not arg_3_0.canAward then
		arg_3_0:nodeByName("close"):setVisible(false)
		arg_3_0:nodeByName("sure_btn"):setPositionX(300)
	end
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0:nodeByName("close"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			arg_4_0:nodeByName("close"):setScale(0.9)
		elseif arg_5_1 == ccui.TouchEventType.moved then
			arg_4_0:nodeByName("close"):setScale(1)
		elseif arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_4_0:nodeByName("close"):setScale(1)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("sure_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			arg_4_0:nodeByName("sure_btn"):setScale(0.9)
		elseif arg_6_1 == ccui.TouchEventType.moved then
			arg_4_0:nodeByName("sure_btn"):setScale(1)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_4_0:nodeByName("sure_btn"):setScale(1)

			if not arg_4_0.canAward then
				xyd.WindowManager.get():closeWindow(arg_4_0)

				return
			end

			arg_4_0.activitiesModel:getActivityReward(arg_4_0.UnlimitTableId, arg_4_0.index, function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					arg_4_0.selfPlayer:handleRewards(arg_7_1.awards)
					arg_4_0.activitiesModel:clearRedMarkState(arg_4_0.UnlimitTableId, 2)

					if arg_4_0.activitiesModel.activities and next(arg_4_0.activitiesModel.activities) then
						for iter_7_0, iter_7_1 in ipairs(arg_4_0.activitiesModel.activities) do
							if iter_7_1.table_id == xyd.Activities.FirstRecharge and iter_7_1.is_open == 1 and iter_7_1.details and iter_7_1.details.is_awarded == 0 then
								arg_4_0.activitiesModel.activities[iter_7_0].details.is_awards = 1
							end

							if arg_4_0.callback then
								arg_4_0.callback()
							end
						end
					end

					xyd.WindowManager.get():closeWindow(arg_4_0)
				end
			end)
		end
	end)
end

function var_0_0.rewardFormat(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = arg_8_1:getContentSize().height
	local var_8_1 = var_8_0 / 4 - 5
	local var_8_2 = xyd.tables.gift:items(arg_8_2)

	if #var_8_2 == 1 and var_8_2[1] == 0 then
		var_8_2 = {}
	end

	local var_8_3 = xyd.tables.gift:itemNum(arg_8_2)
	local var_8_4 = display.newNode()

	var_8_4:setContentSize(var_8_0, var_8_0)

	for iter_8_0 = 1, #var_8_2 do
		if xyd.tables.item:type(var_8_2[iter_8_0]) == -1 then
			xyd.setAvatarBorder(var_8_2[iter_8_0], var_8_4, 1, xyd.tables.hero:initialStar(var_8_2[iter_8_0]))
			var_8_4:addTo(arg_8_1)
			var_8_4:setAnchorPoint(cc.p(0, 0))
			var_8_4:setPosition(0, 0)

			local var_8_5 = {
				id = var_8_2[iter_8_0],
				lev = xyd.tables.item:level(var_8_2[iter_8_0])
			}

			if xyd.tables.item:type(var_8_2[iter_8_0]) == -1 then
				var_8_5.tipsType = 0
				var_8_5.desc1 = xyd.tables.hero:getDes(var_8_2[iter_8_0])
			elseif specialItem then
				var_8_5.tipsType = 1
				var_8_5.id = -3
			else
				var_8_5.tipsType = 1
				var_8_5.desc1 = xyd.tables.item:desc1(var_8_2[iter_8_0])
				var_8_5.desc2 = xyd.tables.item:desc2(var_8_2[iter_8_0])
			end

			var_8_5.name = xyd.tables.item:name(var_8_2[iter_8_0])

			arg_8_0:addTips(var_8_4, var_8_5)
		end
	end

	return arg_8_1
end

function var_0_0.rewardLayer(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = arg_9_1:getContentSize().height
	local var_9_1 = var_9_0 / 4 - 11
	local var_9_2 = xyd.tables.gift:items(arg_9_2)

	if #var_9_2 == 1 and var_9_2[1] == 0 then
		var_9_2 = {}
	end

	local var_9_3 = xyd.tables.gift:itemNum(arg_9_2)
	local var_9_4 = #var_9_2
	local var_9_5 = 0

	for iter_9_0 = 1, #var_9_2 do
		if xyd.tables.item:type(var_9_2[iter_9_0]) ~= -1 then
			local var_9_6 = display.newNode()

			var_9_6:setContentSize(var_9_0, var_9_0)

			local var_9_7 = xyd.tables.item:type(var_9_2[iter_9_0])

			xyd.setItemBorder(var_9_6, var_9_2[iter_9_0], false, false, var_9_3[iter_9_0])
			var_9_6:addTo(arg_9_1)
			var_9_6:setAnchorPoint(cc.p(0, 0))
			var_9_6:setPosition((iter_9_0 - var_9_5 - 1) * (var_9_0 + var_9_1), 0)

			local var_9_8 = {
				id = var_9_2[iter_9_0],
				lev = xyd.tables.item:level(var_9_2[iter_9_0])
			}

			if xyd.tables.item:type(var_9_2[iter_9_0]) == -1 then
				var_9_8.tipsType = 0
				var_9_8.desc1 = xyd.tables.hero:getDes(var_9_2[iter_9_0])
			elseif specialItem then
				var_9_8.tipsType = 1
				var_9_8.id = -3
			else
				var_9_8.tipsType = 1
				var_9_8.desc1 = xyd.tables.item:desc1(var_9_2[iter_9_0])
				var_9_8.desc2 = xyd.tables.item:desc2(var_9_2[iter_9_0])
			end

			var_9_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_9_2[iter_9_0])
			var_9_8.name = xyd.tables.item:name(var_9_2[iter_9_0])

			arg_9_0:addTips(var_9_6, var_9_8)
		else
			var_9_5 = var_9_5 + 1
		end
	end

	local var_9_9 = var_9_4 - var_9_5
	local var_9_10 = xyd.tables.gift:crystal(arg_9_2)

	if var_9_10 and var_9_10 > 0 then
		local var_9_11 = display.newNode()

		var_9_11:setContentSize(var_9_0, var_9_0)
		xyd.setItemBorder(var_9_11, -1, false, false, var_9_10)
		var_9_11:addTo(arg_9_1)
		var_9_11:setAnchorPoint(cc.p(0, 0))
		var_9_11:setPosition(var_9_9 * (var_9_0 + var_9_1), 0)

		local var_9_12 = {}

		var_9_12.id = -1
		var_9_12.tipsType = 1

		arg_9_0:addTips(var_9_11, var_9_12)

		var_9_9 = var_9_9 + 1
	end

	local var_9_13 = xyd.tables.gift:mana(arg_9_2)

	if var_9_13 and var_9_13 > 0 then
		local var_9_14 = display.newNode()

		var_9_14:setContentSize(var_9_0, var_9_0)
		xyd.setItemBorder(var_9_14, -2, false, false, var_9_13)
		var_9_14:addTo(arg_9_1)
		var_9_14:setAnchorPoint(cc.p(0, 0))
		var_9_14:setPosition(var_9_9 * (var_9_0 + var_9_1), 0)

		local var_9_15 = {}

		var_9_15.id = -2
		var_9_15.tipsType = 1

		arg_9_0:addTips(var_9_14, var_9_15)

		var_9_9 = var_9_9 + 1
	end

	local var_9_16 = xyd.tables.gift:drops(arg_9_2)
	local var_9_17 = false

	if var_9_16 and next(var_9_16) then
		var_9_17 = #var_9_16 ~= 1 or var_9_16[1] ~= 0
	end

	if var_9_17 and arg_9_3 and arg_9_3.table_id == xyd.Activities.OnlineReward then
		local var_9_18 = display.newNode()

		var_9_18:addTo(arg_9_1)
		var_9_18:setAnchorPoint(cc.p(0.5, 0.5))
		var_9_18:setPosition(var_9_9 * (var_9_0 + var_9_1), 0)
		var_9_18:setContentSize(var_9_0, var_9_0)

		local var_9_19 = xyd.AssetLoader.get():loadSprite("images/icon/black_bg.png")

		if var_9_19 then
			local var_9_20 = var_9_18:getWidth()
			local var_9_21 = var_9_18:getHeight()
			local var_9_22 = var_9_20 / var_9_19:getWidth()

			var_9_19:setScale(var_9_22)
			var_9_19:addTo(var_9_18)
			var_9_19:setAnchorPoint(cc.p(0.5, 0.5))
			var_9_19:setPosition(var_9_20 / 2, var_9_21 / 2)

			local var_9_23 = xyd.getBorder(0, false)

			xyd.displaySpriteOnContainer(var_9_23, var_9_18, true)
		end

		local var_9_24 = {}

		var_9_24.id = -3
		var_9_24.tipsType = 1

		arg_9_0:addTips(var_9_18, var_9_24)

		local var_9_25 = var_9_9 + 1
	end

	return arg_9_1
end

return var_0_0
