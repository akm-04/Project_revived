local var_0_0 = class("SummerFishingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = "skeletons/ui_effect/summer/fish1"
local var_0_5 = "skeletons/ui_effect/summer/goldfish_water"
local var_0_6 = "skeletons/ui_effect/summer/zhiparticle_texture"
local var_0_7 = xyd.tables.activitySummerGoldfish:appearAccumulateRate()
local var_0_8 = 882
local var_0_9 = var_0_8
local var_0_10 = 2 * math.deg(math.asin(var_0_8 / 2 / var_0_9))
local var_0_11 = var_0_9 * (1 - math.abs(math.cos(math.rad(var_0_10 / 2))))
local var_0_12 = {
	High = 2,
	Normal = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.summer = xyd.ModelManager.get():loadModel(xyd.ModelType.SUMMER)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.netType = var_0_12.Normal
	arg_1_0.isCanTouch = true
	arg_1_0.fishs = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:createScheduler()
	arg_2_0:layout()
	arg_2_0:playTips(var_0_3:translation("SUMMER_FISH_TIPS2"))
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	var_0_0.super.willClose(arg_3_0, arg_3_1)

	if arg_3_0.handle then
		var_0_2.unscheduleGlobal(arg_3_0.handle)

		arg_3_0.handle = nil
	end
end

function var_0_0.createScheduler(arg_4_0)
	if arg_4_0.handle then
		var_0_2.unscheduleGlobal(arg_4_0.handle)

		arg_4_0.handle = nil
	end

	arg_4_0.count = 0
	arg_4_0.lastBornTime = 0
	arg_4_0.handle = var_0_2.scheduleGlobal(function()
		arg_4_0.count = arg_4_0.count + 1

		arg_4_0:loop()
	end, 0.01)
end

function var_0_0.loop(arg_6_0)
	local var_6_0 = arg_6_0.count - arg_6_0.lastBornTime

	arg_6_0:updateFishsState()

	if var_6_0 > 20 and var_6_0 >= math.random(0, 100) then
		arg_6_0.lastBornTime = arg_6_0.count

		local var_6_1 = arg_6_0:generateFishType()

		arg_6_0:addFish(var_6_1)
	end
end

function var_0_0.generateFishType(arg_7_0)
	local var_7_0 = math.random(1, 10000)

	for iter_7_0 = 1, #var_0_7 do
		if var_7_0 <= var_0_7[iter_7_0] then
			return iter_7_0
		end
	end
end

function var_0_0.updateFishsState(arg_8_0)
	for iter_8_0 = #arg_8_0.fishs, 1, -1 do
		local var_8_0 = arg_8_0.fishs[iter_8_0]
		local var_8_1 = var_8_0.params
		local var_8_2 = arg_8_0.count - var_8_1.born_time
		local var_8_3 = var_8_1.start_postion.x + var_8_2 * var_8_1.speedx
		local var_8_4 = var_8_1.end_position.y + var_8_2 * var_8_1.speedy
		local var_8_5 = 0

		if var_8_2 <= var_8_1.move_time / 2 then
			var_8_5 = -(var_0_11 * (var_8_2 * 2 / var_8_1.move_time))
		else
			var_8_5 = -(var_0_11 * ((var_8_1.move_time - var_8_2) * 2 / var_8_1.move_time))
		end

		var_8_0:setPosition(cc.p(var_8_3, var_8_4 + var_8_5))

		local var_8_6 = var_8_1.initialRotation + var_8_2 * var_8_1.rotationDelta

		var_8_0:rotation(var_8_6)

		if var_8_2 > var_8_1.move_time then
			var_8_0:removeSelf()
			table.remove(arg_8_0.fishs, iter_8_0)
		end
	end
end

function var_0_0.layout(arg_9_0)
	arg_9_0:nodeByName("point_text"):setString(var_0_3:translation("POINT_TEXT1"))
	arg_9_0:nodeByName("task_text"):setString(var_0_3:translation("MISSION"))
	arg_9_0:nodeByName("rank_text"):setString(var_0_3:translation("RANK"))
	arg_9_0:nodeByName("buy_text"):setString(var_0_3:translation("BUY"))
	arg_9_0:nodeByName("exchange_text"):setString(var_0_3:translation("EXCHANGE"))

	local var_9_0 = cc.c4b(218, 87, 0, 255)

	arg_9_0:nodeByName("net_num_txt"):enableOutline(var_9_0, 2)

	arg_9_0.fishingContainer = arg_9_0:nodeByName("fishing_container")

	local var_9_1 = arg_9_0.fishingContainer:getContentSize()
	local var_9_2 = arg_9_0.fishingContainer:getContentSize()
	local var_9_3 = xyd.AssetLoader:get():loadSprite("windows/summer/fish/pool_cover.png")

	arg_9_0.clipper = cc.ClippingNode:create()

	arg_9_0.clipper:setStencil(var_9_3)
	arg_9_0.clipper:setInverted(false)
	arg_9_0.clipper:setAlphaThreshold(0)
	var_9_3:addTo(arg_9_0.fishingContainer, -1)
	var_9_3:align(display.CENTER, var_9_1.width / 2, var_9_1.height / 2)
	arg_9_0.fishingContainer:addChild(arg_9_0.clipper)

	local var_9_4 = arg_9_0.summer:createEffect(var_0_5)

	var_9_4:play(nil, true)
	var_9_4:addTo(arg_9_0.clipper)
	var_9_4:setPosition(var_9_1.width / 2 - 335.5, var_9_1.height / 2 + 200)
	var_9_4:setLocalZOrder(20)
	arg_9_0:setButtonClick()
	arg_9_0:updateNetShow()
	arg_9_0:updatePoints()

	local var_9_5 = display.newNode()

	var_9_5:setContentSize(671, 413)
	var_9_5:setAnchorPoint(cc.p(0, 0))
	var_9_5:addTo(arg_9_0.clipper)
	var_9_5:setLocalZOrder(100)
	var_9_5:setTouchEnabled(true)
	var_9_5:setTouchSwallowEnabled(false)
	var_9_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			if not arg_9_0.isCanTouch then
				return false
			end

			if arg_9_0.netNum <= 0 then
				arg_9_0:playTips(var_0_3:translation("SUMMER_FISH_TIPS3"))

				return false
			end

			arg_9_0.netIcon:setVisible(false)

			arg_9_0.net = xyd.AssetLoader:get():loadSprite("windows/summer/fish/net_normal_2.png")

			if arg_9_0.netType == var_0_12.High then
				arg_9_0.net = xyd.AssetLoader:get():loadSprite("windows/summer/fish/net_high_2.png")
			end

			arg_9_0.net:setAnchorPoint(cc.p(0.5, 0.7))
			arg_9_0.net:addTo(arg_9_0.clipper)
			arg_9_0.net:setRotation(-15)
			arg_9_0.net:setPosition(arg_9_0.clipper:convertToNodeSpace(cc.p(arg_10_0.x, arg_10_0.y)))

			arg_9_0.isIntouchArena = true

			return true
		elseif arg_10_0.name == "ended" then
			arg_9_0.isIntouchArena = false

			xyd.playButtonSound()

			if not arg_9_0.isCanTouch then
				return false
			end

			arg_9_0:resetNet()
		end
	end)
end

function var_0_0.resetNet(arg_11_0)
	arg_11_0.netIcon:setVisible(true)

	if arg_11_0.net and not tolua.isnull(arg_11_0.net) then
		arg_11_0.net:removeFromParent()

		arg_11_0.net = nil
	end
end

function var_0_0.updateNetShow(arg_12_0)
	arg_12_0.netItemId = xyd.tables.misc.summerGoldFishNetItem

	if arg_12_0.netType == var_0_12.High then
		arg_12_0.netItemId = xyd.tables.misc.summerGoldFishSuperNetItem
	end

	arg_12_0.netNum = arg_12_0.backpack:getItemNumByID(arg_12_0.netItemId)

	arg_12_0:nodeByName("net_num_txt"):setString("x" .. tostring(arg_12_0.netNum))
	arg_12_0:nodeByName("net_pos"):removeAllChildren()

	arg_12_0.netIcon = xyd.AssetLoader:get():loadSprite("windows/summer/fish/net_normal_1.png")

	if arg_12_0.netType == var_0_12.High then
		arg_12_0.netIcon = xyd.AssetLoader:get():loadSprite("windows/summer/fish/net_high_1.png")
	end

	arg_12_0.netIcon:addTo(arg_12_0:nodeByName("net_pos"))
	arg_12_0.netIcon:setRotation(-15)
	arg_12_0.netIcon:setPositionY(100)

	if arg_12_0.netNum <= 0 then
		arg_12_0.netIcon:setVisible(false)
	end

	arg_12_0:nodeByName("buy_net_pos"):removeAllChildren()

	local var_12_0 = xyd.AssetLoader:get():loadSprite("windows/summer/fish/net_normal_3.png")

	if arg_12_0.netType == var_0_12.High then
		var_12_0 = xyd.AssetLoader:get():loadSprite("windows/summer/fish/net_high_3.png")
	end

	var_12_0:addTo(arg_12_0:nodeByName("buy_net_pos"))
	var_12_0:setScale(var_12_0:getContentSize().width * 1.5 / 100)
end

function var_0_0.updatePoints(arg_13_0)
	arg_13_0:nodeByName("point_txt"):setString(arg_13_0.summer.details.goldfish_info.point)
end

function var_0_0.addFish(arg_14_0, arg_14_1)
	local var_14_0 = arg_14_0:createFish(arg_14_1)

	var_14_0:addTo(arg_14_0.clipper)
	var_14_0:setLocalZOrder(10)

	var_14_0.params = arg_14_0:generateFishAcitionParams()
	var_14_0.params.fish_type = arg_14_1

	var_14_0:setPosition(var_14_0.params.start_postion)
	table.insert(arg_14_0.fishs, var_14_0)
end

function var_0_0.generateFishAcitionParams(arg_15_0)
	local var_15_0 = {}

	var_15_0.start_postion, var_15_0.end_position = arg_15_0:generateFishPostion()
	var_15_0.born_time = arg_15_0.count
	var_15_0.move_time = math.random(75, 125)
	var_15_0.speedx = (var_15_0.end_position.x - var_15_0.start_postion.x) / var_15_0.move_time
	var_15_0.speedy = (var_15_0.end_position.y - var_15_0.start_postion.y) / var_15_0.move_time

	if var_15_0.start_postion.x < var_15_0.end_position.x then
		var_15_0.initialRotation = 90 + var_0_10 / 2
		var_15_0.rotationDelta = -var_0_10 / var_15_0.move_time
	else
		var_15_0.initialRotation = -90 - var_0_10 / 2
		var_15_0.rotationDelta = var_0_10 / var_15_0.move_time
	end

	return var_15_0
end

function var_0_0.generateFishPostion(arg_16_0)
	local var_16_0 = 100
	local var_16_1 = math.random(1, 2)
	local var_16_2 = arg_16_0.fishingContainer:getContentSize().width
	local var_16_3 = arg_16_0.fishingContainer:getContentSize().height
	local var_16_4 = math.random(160, 450)

	if var_16_1 == 1 then
		return cc.p(-var_16_0, var_16_4), cc.p(var_16_2 + var_16_0, var_16_4)
	elseif var_16_1 == 2 then
		return cc.p(var_16_2 + var_16_0, var_16_4), cc.p(-var_16_0, var_16_4)
	end
end

function var_0_0.setButtonClick(arg_17_0)
	arg_17_0:nodeByName("task_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
		xyd.buttonScaleAnim(arg_18_0, arg_18_1)

		if arg_18_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("summer_fish_task")
		end
	end)
	arg_17_0:nodeByName("exchange_btn"):addTouchEventListener(function(arg_19_0, arg_19_1)
		xyd.buttonScaleAnim(arg_19_0, arg_19_1)

		if arg_19_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("summer_exchange")
		end
	end)
	arg_17_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_20_0, arg_20_1)
		xyd.buttonScaleAnim(arg_20_0, arg_20_1)

		if arg_20_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("summer_fish_rule")
		end
	end)
	arg_17_0:nodeByName("swap_net_btn"):addTouchEventListener(function(arg_21_0, arg_21_1)
		xyd.buttonScaleAnim(arg_21_0, arg_21_1)

		if arg_21_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_17_0.netType == var_0_12.Normal then
				arg_17_0.netType = var_0_12.High
			else
				arg_17_0.netType = var_0_12.Normal
			end

			arg_17_0:updateNetShow()
		end
	end)
	arg_17_0:nodeByName("buy_net_btn"):addTouchEventListener(function(arg_22_0, arg_22_1)
		xyd.buttonScaleAnim(arg_22_0, arg_22_1)

		if arg_22_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_17_0.netType == var_0_12.Normal then
				if arg_17_0.selfPlayer.crystal < xyd.tables.misc.summerGoldFishBuyCost then
					local function var_22_0()
						local var_23_0 = {}

						var_23_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_23_0)
					end

					local var_22_1 = {
						rcallBefore = 0,
						txt = var_0_3:translation("ZUANSHI_ABSENCE"),
						rcallback = var_22_0,
						align = xyd.ui_align.CENTER
					}

					xyd.WindowManager.get():openWindow("common_alert", var_22_1)

					return
				end

				local var_22_2 = string.format(var_0_3:translation("SUMMER_FISH_TIPS8"), xyd.tables.misc.summerGoldFishBuyCost, xyd.tables.misc.summerGoldFishBuyNum)

				local function var_22_3()
					arg_17_0:playTips(var_0_3:translation("SUMMER_FISH_TIPS5"))
				end

				local function var_22_4()
					local var_25_0 = {}

					arg_17_0.summer:buyNet(var_25_0, function(arg_26_0, arg_26_1)
						if arg_26_0 == xyd.error.OK and arg_17_0 then
							arg_17_0:updateNetShow()
							arg_17_0:playTips(var_0_3:translation("SUMMER_FISH_TIPS6"))
						end
					end)
				end

				local var_22_5 = {
					txt = var_22_2,
					rcallback = var_22_4,
					lcallback = var_22_3,
					align = xyd.ui_align.CENTER
				}

				xyd.WindowManager.get():openWindow("common_alert", var_22_5)
			else
				xyd.WindowManager.get():openWindow("vip_recharge")
			end
		end
	end)
	arg_17_0:nodeByName("rank_btn"):addTouchEventListener(function(arg_27_0, arg_27_1)
		xyd.buttonScaleAnim(arg_27_0, arg_27_1)

		if arg_27_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_27_0 = {}

			arg_17_0.summer:getGoldfishRankList(var_27_0, function(arg_28_0, arg_28_1)
				if arg_28_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("summer_fish_rank")
				end
			end)
		end
	end)
end

function var_0_0.createFish(arg_29_0, arg_29_1)
	local var_29_0 = arg_29_0.summer:createEffect(var_0_4)

	var_29_0:play(nil, true, nil, arg_29_1)
	var_29_0:setTouchEnabled(true)

	local var_29_1 = display.newNode()
	local var_29_2 = 150

	var_29_1:setContentSize(var_29_2, var_29_2)
	var_29_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_29_1:setTouchEnabled(true)
	var_29_1:addTo(var_29_0)
	var_29_1:setPosition(var_29_2 / 2, var_29_2 / 2)
	var_29_1:setTouchSwallowEnabled(true)
	var_29_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_30_0)
		if arg_30_0.name == "began" then
			if arg_29_0.netNum <= 0 or not arg_29_0.isCanTouch or not arg_29_0.isIntouchArena then
				return false
			end

			arg_29_0.isCanTouch = false

			local var_30_0 = {
				fish_id = arg_29_1,
				net_item_id = arg_29_0.netItemId
			}

			arg_29_0.summer:catchFish(var_30_0, function(arg_31_0, arg_31_1)
				if arg_31_0 == xyd.error.OK then
					local function var_31_0()
						if var_30_0.fish_id == #var_0_7 then
							arg_29_0:playTips(var_0_3:translation("SUMMER_FISH_TIPS7"))
						end
					end

					if arg_31_1.is_success == 1 then
						local var_31_1 = {
							fish_id = arg_29_1,
							net_type = arg_29_0.netType,
							callback = var_31_0
						}

						xyd.WindowManager.get():openWindow("summer_fish_result", var_31_1)
						arg_29_0:removeFish(var_29_0)
						arg_29_0:resetNet()
						arg_29_0:updateNetShow()

						arg_29_0.isCanTouch = true
					else
						arg_29_0:playTips(var_0_3:translation("SUMMER_FISH_TIPS4"))

						local var_31_2 = var_0_3:translation("SUMMER_FISH_TIPS1")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_31_2
						})

						if arg_29_0.net and not tolua.isnull(arg_29_0.net) then
							arg_29_0.holeNet = xyd.AssetLoader:get():loadSprite("windows/summer/fish/net_normal_4.png")

							arg_29_0.holeNet:setAnchorPoint(cc.p(0.5, 0.7))

							if arg_29_0.netType == var_0_12.High then
								arg_29_0.holeNet = xyd.AssetLoader:get():loadSprite("windows/summer/fish/net_high_4.png")
							end

							arg_29_0.holeNet:addTo(arg_29_0.clipper)
							arg_29_0.holeNet:setRotation(-15)
							arg_29_0.holeNet:setPosition(arg_29_0.net:getPosition())
							arg_29_0.net:setVisible(false)
							var_0_2.performWithDelayGlobal(function()
								if arg_29_0 and not tolua.isnull(arg_29_0) then
									arg_29_0.holeNet:removeFromParent()
									arg_29_0:resetNet()
									arg_29_0:updateNetShow()

									arg_29_0.isCanTouch = true
								end
							end, 1.5)
						else
							arg_29_0.isCanTouch = true
						end
					end
				else
					arg_29_0.isCanTouch = true

					arg_29_0:resetNet()
				end
			end)
		end

		return true
	end)

	return var_29_0
end

function var_0_0.removeFish(arg_34_0, arg_34_1)
	for iter_34_0 = 1, #arg_34_0.fishs do
		if arg_34_0.fishs[iter_34_0] == arg_34_1 then
			arg_34_1:removeFromParent()
			table.remove(arg_34_0.fishs, iter_34_0)
		end
	end
end

function var_0_0.playTips(arg_35_0, arg_35_1)
	arg_35_0:nodeByName("dialog_txt"):setString(arg_35_1)
	arg_35_0:nodeByName("dialog_bg"):setVisible(true)
	var_0_2.performWithDelayGlobal(function()
		if arg_35_0 and not tolua.isnull(arg_35_0) then
			arg_35_0:nodeByName("dialog_bg"):setVisible(false)
		end
	end, xyd.tables.misc.dialogDefaultTime)
end

function var_0_0.addPartice(arg_37_0, arg_37_1)
	local var_37_0 = cc.ParticleSystemQuad:create(arg_37_1 .. ".plist")

	var_37_0:addTo(arg_37_0.clipper)
	var_37_0:setPosition(cc.p(200, 200))
end

return var_0_0
