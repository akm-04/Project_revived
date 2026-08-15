local var_0_0 = class("FirstStoreUnlimitWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.item
local var_0_2 = xyd.tables.gift
local var_0_3 = 980
local var_0_4 = 90001001
local var_0_5 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.backpack = arg_1_0.player:getBackpack()
	arg_1_0.params = arg_1_2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.rewardFormat(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_1:getContentSize().height
	local var_3_1 = var_3_0 / 4
	local var_3_2 = xyd.tables.gift:items(arg_3_2)

	if #var_3_2 == 1 and var_3_2[1] == 0 then
		var_3_2 = {}
	end

	local var_3_3 = xyd.tables.gift:itemNum(arg_3_2)
	local var_3_4 = #var_3_2
	local var_3_5 = display.newNode()

	var_3_5:setContentSize(var_3_0, var_3_0)

	if xyd.tables.item:type(var_3_2[var_3_4]) == -1 then
		xyd.setAvatarBorder(var_3_2[var_3_4], var_3_5, 1, xyd.tables.hero:initialStar(var_3_2[var_3_4]))
	else
		xyd.setItemBorder(var_3_5, var_3_2[var_3_4], false, false, var_3_3[var_3_4])
	end

	var_3_5:addTo(arg_3_1)
	var_3_5:setAnchorPoint(cc.p(0, 0))
	var_3_5:setPosition(0, 0)

	local var_3_6 = {
		id = var_3_2[var_3_4],
		lev = xyd.tables.item:level(var_3_2[var_3_4])
	}

	if xyd.tables.item:type(var_3_2[var_3_4]) == -1 then
		var_3_6.tipsType = 0
		var_3_6.desc1 = xyd.tables.hero:getDes(var_3_2[var_3_4])
	elseif specialItem then
		var_3_6.tipsType = 1
		var_3_6.id = -3
	else
		var_3_6.tipsType = 1
		var_3_6.desc1 = xyd.tables.item:desc1(var_3_2[var_3_4])
		var_3_6.desc2 = xyd.tables.item:desc2(var_3_2[var_3_4])
	end

	var_3_6.name = xyd.tables.item:name(var_3_2[var_3_4])

	arg_3_0:addTips(var_3_5, var_3_6)

	return arg_3_1
end

function var_0_0.rewardLayer(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = arg_4_1:getContentSize().height
	local var_4_1 = var_4_0 / 4
	local var_4_2 = xyd.tables.gift:items(arg_4_2)

	if #var_4_2 == 1 and var_4_2[1] == 0 then
		var_4_2 = {}
	end

	local var_4_3 = xyd.tables.gift:itemNum(arg_4_2)
	local var_4_4 = #var_4_2

	for iter_4_0 = 1, #var_4_2 do
		local var_4_5 = display.newNode()

		var_4_5:setContentSize(var_4_0, var_4_0)

		if xyd.tables.item:type(var_4_2[iter_4_0]) == -1 then
			xyd.setAvatarBorder(var_4_2[iter_4_0], var_4_5, 1, xyd.tables.hero:initialStar(var_4_2[iter_4_0]))
		else
			xyd.setItemBorder(var_4_5, var_4_2[iter_4_0], false, false, var_4_3[iter_4_0])
		end

		var_4_5:addTo(arg_4_1)
		var_4_5:setAnchorPoint(cc.p(0, 0))
		var_4_5:setPosition((iter_4_0 - 1) * (var_4_0 + var_4_1), 0)

		local var_4_6 = {
			id = var_4_2[iter_4_0],
			lev = xyd.tables.item:level(var_4_2[iter_4_0])
		}

		if xyd.tables.item:type(var_4_2[iter_4_0]) == -1 then
			var_4_6.tipsType = 0
			var_4_6.desc1 = xyd.tables.hero:getDes(var_4_2[iter_4_0])
		elseif specialItem then
			var_4_6.tipsType = 1
			var_4_6.id = -3
		else
			var_4_6.tipsType = 1
			var_4_6.desc1 = xyd.tables.item:desc1(var_4_2[iter_4_0])
			var_4_6.desc2 = xyd.tables.item:desc2(var_4_2[iter_4_0])
		end

		var_4_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_4_2[iter_4_0])
		var_4_6.name = xyd.tables.item:name(var_4_2[iter_4_0])

		arg_4_0:addTips(var_4_5, var_4_6)
	end

	function dealItem(arg_5_0, arg_5_1)
		if arg_5_0 and arg_5_0 > 0 then
			local var_5_0 = display.newNode()

			var_5_0:setContentSize(var_4_0, var_4_0)
			xyd.setItemBorder(var_5_0, arg_5_1, false, false, arg_5_0)
			var_5_0:addTo(arg_4_1)
			var_5_0:setAnchorPoint(cc.p(0, 0))
			var_5_0:setPosition(var_4_4 * (var_4_0 + var_4_1), 0)

			local var_5_1 = {
				id = arg_5_1
			}

			var_5_1.tipsType = 1

			arg_4_0:addTips(var_5_0, var_5_1)

			var_4_4 = var_4_4 + 1
		end
	end

	local var_4_7 = xyd.tables.gift:crystal(arg_4_2)

	dealItem(var_4_7, -1)

	local var_4_8 = xyd.tables.gift:mana(arg_4_2)

	dealItem(var_4_8, -2)
	arg_4_1:setPositionX(arg_4_0:nodeByName("btn"):getPositionX() - var_4_4 * 40)

	return arg_4_1
end

function var_0_0.layout(arg_6_0)
	arg_6_0:rewardLayer(arg_6_0:nodeByName("list"), var_0_4)
	arg_6_0:nodeByName("txt_tips"):setString(var_0_5:translation("ACTIVITY_CHARGE_TIP"))
	arg_6_0:updateMain()
	dump(arg_6_0.params)
	arg_6_0:nodeByName("btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			if arg_6_0.params.details.can_award == 0 then
				local var_7_0 = {}

				var_7_0.windowState = true
				var_7_0.chargeState = xyd.ChargeState.diamond

				xyd.WindowManager.get():openWindow("vip_recharge", var_7_0)
			elseif arg_6_0.params.details.is_awarded ~= 1 then
				arg_6_0.activitiesModel:getActivityReward(arg_6_0.params.table_id, nil, function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						arg_6_0.player:handleRewards(arg_8_1.awards)
						arg_6_0:nodeByName("btn"):setVisible(false)
						arg_6_0.activitiesModel:clearRedMarkState(arg_6_0.params.table_id, 2)

						if arg_6_0.activitiesModel.activities and next(arg_6_0.activitiesModel.activities) then
							for iter_8_0, iter_8_1 in ipairs(arg_6_0.activitiesModel.activities) do
								if iter_8_1.table_id == xyd.Activities.FirstRecharge and iter_8_1.is_open == 1 and iter_8_1.details and iter_8_1.details.is_awarded == 0 then
									arg_6_0.activitiesModel.activities[iter_8_0].details.is_awards = 1
								end

								if iter_8_1.table_id == xyd.Activities.FirstStoreAward and iter_8_1.is_open == 1 then
									local var_8_0 = false

									if iter_8_1.details and iter_8_1.details.is_awarded == 0 then
										if iter_8_1.details.charge >= var_0_3 then
											var_8_0 = true
										end

										arg_6_0.nextNeedParams = iter_8_1
									end

									xyd.EventDispatcher.get():dispatchEvent({
										name = xyd.event.REFRESH_CHARGE_ACTIVITY_MAIN,
										params = {
											isShow = true,
											hasPoint = var_8_0
										}
									})
								end
							end
						end
					end
				end)
			end
		end
	end)

	local var_6_0 = arg_6_0:nodeByName("bar_text")
	local var_6_1 = arg_6_0:nodeByName("bar")
	local var_6_2 = 100
	local var_6_3

	var_6_0:enableShadow(xyd.color.FONT_SHADOW_A)

	local var_6_4 = arg_6_0.params.details.charge >= var_0_3 and 100 or math.min(arg_6_0.params.details.charge / var_0_3 * 100, 100)

	var_6_0:setString(xyd.tables.translation:translation("ALREADY_DEAL") .. arg_6_0.params.details.charge .. "/" .. var_0_3)
	var_6_1:setPercent(var_6_4)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_6_0):addEventListener(xyd.event.REFRESH_CHARGE_ACTIVITY, function(arg_9_0)
		local var_9_0 = {
			activity_id = xyd.Activities.FirstRecharge
		}

		arg_6_0.activitiesModel:loadSingleActivity(var_9_0, function(arg_10_0, arg_10_1)
			arg_6_0.params = arg_10_1

			arg_6_0:updateMain()
		end)
	end)
end

function var_0_0.updateMain(arg_11_0)
	if arg_11_0.params.details.can_award == 0 then
		arg_11_0:nodeByName("getaward"):hide()
		arg_11_0:nodeByName("rechar"):show()
	elseif arg_11_0.params.details.is_awarded ~= 1 then
		arg_11_0:nodeByName("getaward"):show()
		arg_11_0:nodeByName("rechar"):hide()
	else
		arg_11_0:nodeByName("btn"):setVisible(false)
	end
end

function var_0_0.didOpen(arg_12_0)
	arg_12_0:addBlockLayer()
end

function var_0_0.willClose(arg_13_0)
	if arg_13_0.nextNeedParams then
		local var_13_0 = {
			activity_id = xyd.Activities.FirstStoreAward
		}

		xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_13_0, function(arg_14_0, arg_14_1)
			if arg_14_1.details and arg_14_1.is_open and arg_14_1.details and arg_14_1.is_open == 1 and arg_14_1.details.is_awarded == 0 then
				xyd.WindowManager.get():openWindow("firststore", arg_14_1)
			end
		end)
	end
end

return var_0_0
