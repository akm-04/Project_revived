local var_0_0 = class("SnowBallWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = import("framework.scheduler")
local var_0_4 = xyd.tables.translation
local var_0_5 = 50
local var_0_6 = 45
local var_0_7 = 10
local var_0_8 = 12001028
local var_0_9 = {
	Super = 1,
	Normal = 0
}
local var_0_10 = {
	rightToLeft = 2,
	leftToRight = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.snowBall = xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_BALL)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.snowType = var_0_9.Normal
	arg_1_0.isDay = true
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:createScheduler()
end

function var_0_0.initModel(arg_4_0)
	arg_4_0.initModels = {}

	for iter_4_0, iter_4_1 in pairs(arg_4_0.details) do
		local var_4_0 = xyd.HeroAnimation.new(nil, tonumber(iter_4_1), 1, {})

		var_4_0:retain()
		table.insert(arg_4_0.initModels, var_4_0)
	end
end

function var_0_0.snowBallAttackEffect(arg_5_0)
	local var_5_0 = "skeletons/ui_effect/activity_snowball/activity_snowball2"
	local var_5_1 = var_5_0 .. ".json"
	local var_5_2 = var_5_0 .. ".atlas"

	arg_5_0.snowBallAttackEffect = var_0_2.new(var_5_1, var_5_2, 1)

	arg_5_0.snowBallAttackEffect:addTo(arg_5_0.clipper)
	arg_5_0.snowBallAttackEffect:setVisible(false)
	arg_5_0.snowBallAttackEffect:setAnchorPoint(cc.p(0.5, 0.5))
end

function var_0_0.snowBallEffect(arg_6_0)
	local var_6_0 = "skeletons/ui_effect/activity_snowball/activity_snowball"
	local var_6_1 = var_6_0 .. ".json"
	local var_6_2 = var_6_0 .. ".atlas"

	arg_6_0.snowBallEffect = var_0_2.new(var_6_1, var_6_2, 1)

	arg_6_0.snowBallEffect:addTo(arg_6_0.clipper)
	arg_6_0.snowBallEffect:setVisible(false)
	arg_6_0.snowBallEffect:setAnchorPoint(cc.p(0.5, 0.5))
end

function var_0_0.releaseModel(arg_7_0)
	for iter_7_0, iter_7_1 in pairs(arg_7_0.initModels) do
		iter_7_1:release()
	end

	arg_7_0.initModels = {}
end

function var_0_0.willClose(arg_8_0, arg_8_1)
	var_0_0.super.willClose(arg_8_0, arg_8_1)

	if arg_8_0.handle then
		var_0_3.unscheduleGlobal(arg_8_0.handle)

		arg_8_0.handle = nil
	end

	if arg_8_0.awardScheduler then
		var_0_3.unscheduleGlobal(arg_8_0.awardScheduler)

		arg_8_0.awardScheduler = nil
	end

	arg_8_0:releaseModel()
end

function var_0_0.createScheduler(arg_9_0)
	if arg_9_0.handle then
		var_0_3.unscheduleGlobal(arg_9_0.handle)

		arg_9_0.handle = nil
	end

	arg_9_0.isCanTouch = true
	arg_9_0.isInitModel = false
	arg_9_0.models = {}
	arg_9_0.snowBall = xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_BALL)
	arg_9_0.details = arg_9_0.snowBall.details.models
	arg_9_0.isCanTouch = true
	arg_9_0.count = 0
	arg_9_0.lastBornTime = 0
	arg_9_0.modelCount = 0
	arg_9_0.handle = var_0_3.scheduleGlobal(function()
		if not arg_9_0.isInitModel then
			arg_9_0.isInitModel = true

			arg_9_0:initModel()
			arg_9_0:nodeByName("waiting_container"):setVisible(false)
		end

		arg_9_0.count = arg_9_0.count + 1

		arg_9_0:loop()
	end, 0.03)
end

function var_0_0.loop(arg_11_0)
	local var_11_0 = arg_11_0.count - arg_11_0.lastBornTime

	arg_11_0:updateModelState()

	if var_11_0 > 20 and var_11_0 >= math.random(0, 100) and arg_11_0.modelCount < xyd.tables.misc.snowBallModelInitNum then
		arg_11_0.lastBornTime = arg_11_0.count
		arg_11_0.modelCount = arg_11_0.modelCount + 1

		arg_11_0:addModel()
	end
end

function var_0_0.setAwardContainer(arg_12_0, arg_12_1)
	arg_12_0:nodeByName("award_container"):removeAllChildren()

	local var_12_0
	local var_12_1
	local var_12_2

	for iter_12_0, iter_12_1 in pairs(arg_12_1) do
		local var_12_3 = ""
		local var_12_4 = string.format(var_0_4:translation("SNOW_BALL_AWARD_TEXT2"), xyd.tables.item:name(iter_12_1.table_id), iter_12_1.item_num)
		local var_12_5 = {
			size = 24,
			color = cc.c3b(255, 254, 133)
		}
		local var_12_6 = xyd.AssetLoader.get():loadLabel(var_12_5)

		var_12_6:setAnchorPoint(0, 0.5)
		var_12_6:addTo(arg_12_0:nodeByName("award_container"))
		var_12_6:setString(var_12_4)
		var_12_6:setPosition(var_0_7, (iter_12_0 - 1) * (var_0_6 + var_0_7) + var_0_7 + var_0_6 / 2)

		var_12_2 = var_12_6:getContentSize().width

		local var_12_7 = cc.Node:create()

		var_12_7:setContentSize(var_0_6, var_0_6)
		xyd.setItemBorder(var_12_7, iter_12_1.table_id)
		var_12_7:addTo(arg_12_0:nodeByName("award_container"))
		var_12_7:setAnchorPoint(0, 0)
		var_12_7:setPosition(var_0_7 * 2 + var_12_2, (iter_12_0 - 1) * (var_0_6 + var_0_7) + var_0_7)

		local var_12_8 = ""
		local var_12_9 = string.format(var_0_4:translation("SNOW_BALL_AWARD_TEXT"), xyd.tables.item:name(iter_12_1.table_id), iter_12_1.item_num)
		local var_12_10 = {
			size = 24,
			color = cc.c3b(255, 254, 133)
		}
		local var_12_11 = xyd.AssetLoader.get():loadLabel(var_12_10)

		var_12_11:setAnchorPoint(0, 0.5)
		var_12_11:addTo(arg_12_0:nodeByName("award_container"))
		var_12_11:setString(var_12_9)

		var_12_0 = var_12_11:getContentSize().width

		local var_12_12 = var_12_11:getContentSize().height

		var_12_11:setPosition(var_0_7 * 3 + var_0_6 + var_12_2, (iter_12_0 - 1) * (var_0_6 + var_0_7) + var_0_7 + var_0_6 / 2)
	end

	arg_12_0:nodeByName("award_container"):setContentSize(var_0_7 * 5 + var_0_6 + var_12_0 + var_12_2, #arg_12_1 * (var_0_6 + var_0_7 * 2))
end

function var_0_0.updateModelState(arg_13_0)
	local var_13_0 = true

	for iter_13_0 = #arg_13_0.models, 1, -1 do
		local var_13_1 = arg_13_0.models[iter_13_0]
		local var_13_2 = var_13_1:getChildByName("model")
		local var_13_3 = var_13_1.params
		local var_13_4 = arg_13_0.count - var_13_3.born_time
		local var_13_5 = math.abs(var_13_3.start_postion.x - var_13_3.turn_position.x) / var_13_3.speedx
		local var_13_6
		local var_13_7 = var_13_3.start_postion.y

		if var_13_1.is_dead then
			var_13_6 = var_13_1:getPositionX()

			var_13_1:getChildByName("touch_node"):setTouchEnabled(false)

			if not var_13_1.has_dead then
				arg_13_0.models[iter_13_0].has_dead = true

				var_13_2:die(function()
					local var_14_0 = cc.Sequence:create({
						cc.Spawn:create({
							cc.FadeTo:create(1, 0)
						})
					})

					var_13_2.model:runActionOnce(var_14_0)

					if var_13_1:getChildByName("effect") then
						var_13_1:getChildByName("effect"):setVisible(false)
					end
				end)
			end
		elseif var_13_3.is_turn and var_13_5 <= var_13_4 and var_13_4 < var_13_5 + var_0_5 then
			local var_13_8 = false

			var_13_6 = var_13_3.turn_position.x

			if not var_13_3.has_idle then
				var_13_2:idle(true)

				local var_13_9 = xyd.tables.expression:expression(var_13_3.expression)
				local var_13_10 = var_13_9 .. ".json"
				local var_13_11 = var_13_9 .. ".atlas"
				local var_13_12 = var_0_2.new(var_13_10, var_13_11, 1)

				var_13_12:setAnchorPoint(cc.p(0.5, 0.5))
				var_13_12:addTo(var_13_1)

				if var_13_3.modelId == var_0_8 then
					var_13_12:setPosition(cc.p(0, 55))
				else
					var_13_12:setPosition(cc.p(0, 155))
				end

				var_13_12:setName("effect")
				var_13_12:play(nil, false)

				arg_13_0.models[iter_13_0].params.has_idle = true
			end
		else
			local var_13_13 = false

			if var_13_3.has_idle and not var_13_3.has_walk then
				var_13_2:walk(true)
				var_13_1:removeChildByName("effect")

				arg_13_0.models[iter_13_0].params.has_walk = true
			end

			if var_13_3.direction == var_0_10.leftToRight then
				var_13_6 = var_13_3.start_postion.x + var_13_4 * var_13_3.speedx

				if var_13_3.is_turn and var_13_6 > var_13_3.turn_position.x then
					if not var_13_3.has_turn then
						var_13_2:flipX(true)

						arg_13_0.models[iter_13_0].params.has_turn = true
					end

					var_13_6 = var_13_6 - 2 * (var_13_6 - var_13_3.turn_position.x) + var_0_5 * var_13_3.speedx
				end
			else
				var_13_6 = var_13_3.start_postion.x - var_13_4 * var_13_3.speedx

				if var_13_3.is_turn and var_13_6 < var_13_3.turn_position.x then
					if not var_13_3.has_turn then
						var_13_2:flipX(false)

						arg_13_0.models[iter_13_0].params.has_turn = true
					end

					var_13_6 = var_13_6 + 2 * (var_13_3.turn_position.x - var_13_6) - var_0_5 * var_13_3.speedx
				end
			end
		end

		var_13_1:setPosition(cc.p(var_13_6, var_13_7))

		if var_13_4 > var_13_3.move_time then
			var_13_1:removeSelf()
			table.remove(arg_13_0.models, iter_13_0)

			if #arg_13_0.models == 0 then
				arg_13_0:turnToNight()
			end
		end
	end
end

function var_0_0.generateModelPostion(arg_15_0, arg_15_1)
	local var_15_0 = 100
	local var_15_1 = math.random(1, 2)
	local var_15_2 = math.random(1, 10)
	local var_15_3 = arg_15_0.heroContainer:getContentSize().width
	local var_15_4 = arg_15_0.heroContainer:getContentSize().height
	local var_15_5

	if arg_15_1 == var_0_8 then
		var_15_5 = math.random(300, 480)
	else
		var_15_5 = math.random(0, 220)
	end

	if var_15_1 == var_0_10.leftToRight then
		local var_15_6 = math.random(580, 930)

		if var_15_2 <= 2 then
			return var_15_1, true, cc.p(-var_15_0, var_15_5), cc.p(var_15_6, var_15_5), cc.p(-var_15_0, var_15_5)
		else
			return var_15_1, false, cc.p(-var_15_0, var_15_5), cc.p(var_15_6, var_15_5), cc.p(var_15_3 + var_15_0, var_15_5)
		end
	else
		local var_15_7 = math.random(160, 490)

		if var_15_2 <= 2 then
			return var_15_1, true, cc.p(var_15_3 + var_15_0, var_15_5), cc.p(var_15_7, var_15_5), cc.p(var_15_3 + var_15_0, var_15_5)
		else
			return var_15_1, false, cc.p(var_15_3 + var_15_0, var_15_5), cc.p(var_15_7, var_15_5), cc.p(-var_15_0, var_15_5)
		end
	end
end

function var_0_0.layout(arg_16_0)
	arg_16_0:nodeByName("waiting_container"):setVisible(true)
	arg_16_0:nodeByName("waiting_txt"):setString(var_0_4:translation("SNOW_BALL_INIT_MODEL"))
	arg_16_0:nodeByName("night"):setVisible(false)
	arg_16_0:nodeByName("award_container"):setVisible(false)

	arg_16_0.heroContainer = arg_16_0:nodeByName("hero_container")

	arg_16_0:setButtonClick()
	arg_16_0:updateShowByState()

	local var_16_0 = arg_16_0.heroContainer:getContentSize()

	arg_16_0:nodeByName("rule_cover"):setTouchEnabled(true)
	arg_16_0:nodeByName("change_cover"):setTouchEnabled(true)
	arg_16_0:nodeByName("charge_cover"):setTouchEnabled(true)
	arg_16_0:nodeByName("rank_cover"):setTouchEnabled(true)
	arg_16_0:nodeByName("rule_cover"):setTouchSwallowEnabled(true)
	arg_16_0:nodeByName("change_cover"):setTouchSwallowEnabled(true)
	arg_16_0:nodeByName("charge_cover"):setTouchSwallowEnabled(true)
	arg_16_0:nodeByName("rank_cover"):setTouchSwallowEnabled(true)

	local var_16_1 = xyd.AssetLoader:get():loadSprite("windows/snow_ball/clipper.png")

	arg_16_0.clipper = cc.ClippingNode:create()

	arg_16_0.clipper:setStencil(var_16_1)
	arg_16_0.clipper:setInverted(false)
	arg_16_0.clipper:setAlphaThreshold(0)
	var_16_1:align(display.CENTER, var_16_0.width / 2, var_16_0.height / 2)
	arg_16_0.heroContainer:addChild(arg_16_0.clipper, -1)

	local var_16_2 = cc.ParticleSystemQuad:create("effects/xuehua_yuan_particle_texture.plist")

	var_16_2:setPosition(var_16_0.width / 2, var_16_0.height / 2)
	arg_16_0.clipper:addChild(var_16_2, 200)
	arg_16_0:snowBallAttackEffect()
	arg_16_0:snowBallEffect()

	local var_16_3 = display.newNode()

	var_16_3:setContentSize(var_16_0)
	var_16_3:setAnchorPoint(cc.p(0, 0))
	arg_16_0.clipper:addChild(var_16_3)
	var_16_3:setName("touch_area")
	var_16_3:setLocalZOrder(-2000)
	var_16_3:setTouchEnabled(true)
	var_16_3:setTouchSwallowEnabled(false)
	var_16_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
		if arg_17_0.name == "began" then
			if arg_16_0.snowBallNum <= 0 then
				local var_17_0 = var_0_4:translation("SNOW_BALL_NOT_ENOUGH")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_17_0
				})

				return false
			end

			if not arg_16_0.isCanTouch then
				return false
			end

			arg_16_0.isCanTouch = false

			arg_16_0.snowBallAttackEffect:setPosition(arg_16_0.clipper:convertToNodeSpace(cc.p(arg_17_0.x, arg_17_0.y)))
			arg_16_0.snowBallAttackEffect:setVisible(true)
			arg_16_0.snowBallAttackEffect:play(function()
				arg_16_0.snowBallAttackEffect:setVisible(false)
			end, false)
			arg_16_0.activitiesModel:getActivityReward2(xyd.Activities.SnowBall, 0, arg_16_0.snowType, function(arg_19_0, arg_19_1)
				if arg_19_0 == xyd.error.OK then
					arg_16_0:useSnowBall()
					arg_16_0:updateShowByState()
				end

				arg_16_0.isCanTouch = true
			end)

			return true
		end

		return true
	end)
end

function var_0_0.turnToDay(arg_20_0)
	arg_20_0.isDay = true

	local var_20_0 = cc.Sequence:create({
		cc.Spawn:create({
			cc.FadeTo:create(1, 0)
		}),
		cc.CallFunc:create(function()
			arg_20_0:nodeByName("night"):setVisible(false)
			arg_20_0.clipper:getChildByName("touch_area"):setTouchEnabled(true)
			arg_20_0:nodeByName("waiting_container"):setVisible(true)
			arg_20_0:createScheduler()
		end)
	})

	arg_20_0:nodeByName("night"):runActionOnce(var_20_0)
end

function var_0_0.turnToNight(arg_22_0)
	arg_22_0:releaseModel()
	arg_22_0:nodeByName("award_container"):setVisible(false)
	arg_22_0:nodeByName("night"):setVisible(true)
	arg_22_0:nodeByName("night"):setOpacity(0)
	arg_22_0.clipper:getChildByName("touch_area"):setTouchEnabled(false)

	local var_22_0 = cc.Sequence:create({
		cc.Spawn:create({
			cc.FadeTo:create(1, 255)
		}),
		cc.CallFunc:create(function()
			arg_22_0.isDay = false
		end)
	})

	arg_22_0:nodeByName("night"):runActionOnce(var_22_0)
end

function var_0_0.updateShowByState(arg_24_0)
	if arg_24_0.snowType == var_0_9.Normal then
		arg_24_0:nodeByName("ball"):setVisible(true)
		arg_24_0:nodeByName("super_ball"):setVisible(false)
		arg_24_0:nodeByName("word_add"):setVisible(true)
		arg_24_0:nodeByName("word_charge"):setVisible(false)

		arg_24_0.snowBallNum = arg_24_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.snowBallItem)

		arg_24_0:nodeByName("snow_num"):setString(arg_24_0.snowBallNum)
	else
		arg_24_0:nodeByName("ball"):setVisible(false)
		arg_24_0:nodeByName("super_ball"):setVisible(true)
		arg_24_0:nodeByName("word_add"):setVisible(false)
		arg_24_0:nodeByName("word_charge"):setVisible(true)

		arg_24_0.snowBallNum = arg_24_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.snowBallSuperItem)

		arg_24_0:nodeByName("snow_num"):setString(arg_24_0.snowBallNum)
	end
end

function var_0_0.addModel(arg_25_0)
	local var_25_0 = arg_25_0:createModel(arg_25_0.details[arg_25_0.modelCount], arg_25_0.modelCount)

	var_25_0:addTo(arg_25_0.clipper)

	local var_25_1 = var_25_0:getChildByName("model")

	var_25_0.params = arg_25_0:generatemodelAcitionParams(arg_25_0.details[arg_25_0.modelCount])

	var_25_0:setLocalZOrder(-math.ceil(var_25_0.params.start_postion.y))

	if var_25_0.params.direction == var_0_10.rightToLeft then
		var_25_1:flipX(true)
	end

	var_25_0:setPosition(var_25_0.params.start_postion)
	table.insert(arg_25_0.models, var_25_0)
end

function var_0_0.generatemodelAcitionParams(arg_26_0, arg_26_1)
	local var_26_0 = tonumber(arg_26_1)
	local var_26_1 = {}

	var_26_1.direction, var_26_1.is_turn, var_26_1.start_postion, var_26_1.turn_position, var_26_1.end_position = arg_26_0:generateModelPostion(var_26_0)
	var_26_1.born_time = arg_26_0.count
	var_26_1.modelId = var_26_0
	var_26_1.speedx = xyd.tables.activitySnowBall:speed(var_26_0) + math.random(-2, 2)
	var_26_1.move_time = (math.abs(var_26_1.turn_position.x - var_26_1.start_postion.x) + math.abs(var_26_1.turn_position.x - var_26_1.end_position.x)) / var_26_1.speedx

	if var_26_1.is_turn then
		var_26_1.move_time = var_26_1.move_time + var_0_5
	end

	var_26_1.has_turn = false
	var_26_1.has_idle = false
	var_26_1.has_walk = false
	var_26_1.is_dead = false
	var_26_1.expression = math.random(1, 2)

	return var_26_1
end

function var_0_0.setButtonClick(arg_27_0)
	arg_27_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_28_0, arg_28_1)
		if arg_28_1 == ccui.TouchEventType.began then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("snow_ball_rule")
		end
	end)
	arg_27_0:nodeByName("btn_change"):addTouchEventListener(function(arg_29_0, arg_29_1)
		if arg_29_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_27_0.snowType == var_0_9.Normal then
				arg_27_0.snowType = var_0_9.Super
			else
				arg_27_0.snowType = var_0_9.Normal
			end

			arg_27_0:updateShowByState()
		end
	end)
	arg_27_0:nodeByName("btn_add"):addTouchEventListener(function(arg_30_0, arg_30_1)
		if arg_30_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_27_0.snowType == var_0_9.Normal then
				if arg_27_0.selfPlayer.crystal < xyd.tables.misc.snowBallBuyCost then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_4:translation("ZUANSHI_ABSENCE"), function()
						local var_31_0 = {}

						var_31_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_31_0)
						xyd.WindowManager.get():closeWindow(arg_27_0)
					end, nil, nil, arg_27_0.colorMode)

					return
				end

				local var_30_0 = string.format(var_0_4:translation("BUY_SNOW_BALL_TIPS"), xyd.tables.misc.snowBallBuyCost, xyd.tables.misc.snowBallBuyNum)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_30_0, function()
					xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_BALL):buySnowBall(function(arg_33_0, arg_33_1)
						if arg_33_0 == xyd.error.OK then
							if not arg_27_0 or tolua.isnull(arg_27_0) then
								return
							end

							arg_27_0.selfPlayer:getBackpack():addItemsByID(xyd.tables.misc.snowBallItem, xyd.tables.misc.snowBallBuyNum)
							arg_27_0:updateShowByState()
						end
					end)
				end, nil, nil, arg_27_0.colorMode)
			else
				xyd.WindowManager.get():openWindow("garden_seed")
				xyd.WindowManager.get():closeWindow(arg_27_0)
			end
		end
	end)
	arg_27_0:nodeByName("btn_newday"):addTouchEventListener(function(arg_34_0, arg_34_1)
		if arg_34_1 == ccui.TouchEventType.ended and not arg_27_0.isDay then
			xyd.playButtonSound()
			arg_27_0.snowBall:loadInfo(function(arg_35_0, arg_35_1)
				if arg_35_0 == xyd.error.OK then
					arg_27_0:turnToDay()
				end
			end)
		end
	end)
	arg_27_0:nodeByName("btn_rank"):addTouchEventListener(function(arg_36_0, arg_36_1)
		if arg_36_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_36_0 = {}

			arg_27_0.snowBall:getRankList(var_36_0, function(arg_37_0, arg_37_1)
				if arg_37_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("snow_ball_rank")
				end
			end)
		end
	end)
end

function var_0_0.createModel(arg_38_0, arg_38_1, arg_38_2)
	local var_38_0 = display.newNode()

	var_38_0.is_dead = false
	var_38_0.has_dead = false

	local var_38_1 = tonumber(arg_38_1)
	local var_38_2 = arg_38_0.initModels[arg_38_2]
	local var_38_3 = xyd.tables.model:uiScale(var_38_1)

	var_38_2:setScale(var_38_3 * 0.5)
	var_38_2:walk(true)
	var_38_2:addTo(var_38_0)
	var_38_2:setName("model")

	local var_38_4 = display.newNode()

	var_38_4:setContentSize(100, 150)
	var_38_4:setAnchorPoint(cc.p(0.5, 0))
	var_38_4:setTouchEnabled(true)
	var_38_4:addTo(var_38_0)
	var_38_4:setName("touch_node")
	var_38_4:setTouchSwallowEnabled(true)
	var_38_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_39_0)
		if arg_39_0.name == "began" then
			if arg_38_0.snowBallNum <= 0 then
				local var_39_0 = var_0_4:translation("SNOW_BALL_NOT_ENOUGH")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_39_0
				})

				return false
			end

			if not arg_38_0.isCanTouch then
				return false
			end

			arg_38_0.isCanTouch = false

			arg_38_0.snowBallEffect:setVisible(true)
			arg_38_0.snowBallEffect:setPosition(arg_38_0.clipper:convertToNodeSpace(cc.p(arg_39_0.x, arg_39_0.y)))
			arg_38_0.snowBallEffect:setName("snow_ball")
			arg_38_0.snowBallEffect:play(function()
				arg_38_0.snowBallEffect:setVisible(false)
			end, false)
			arg_38_0.activitiesModel:getActivityReward2(xyd.Activities.SnowBall, arg_38_2, arg_38_0.snowType, function(arg_41_0, arg_41_1)
				if not arg_38_0 or tolua.isnull(arg_38_0) then
					return
				end

				if arg_41_0 == xyd.error.OK then
					if arg_41_1.is_hit == 1 then
						var_38_0.is_dead = true

						if arg_38_0.awardScheduler then
							var_0_3.unscheduleGlobal(arg_38_0.awardScheduler)

							arg_38_0.awardScheduler = nil
						end

						arg_38_0:nodeByName("award_container"):setVisible(true)
						arg_38_0:setAwardContainer(arg_41_1.awards)

						arg_38_0.awardScheduler = var_0_3.performWithDelayGlobal(function()
							arg_38_0:nodeByName("award_container"):setVisible(false)
						end, 2)

						arg_38_0.selfPlayer:handleRewardsWithoutShow(arg_41_1.awards)
						arg_38_0:useSnowBall()
						arg_38_0:updateShowByState()
					else
						arg_38_0:useSnowBall()
						arg_38_0:updateShowByState()
					end
				end

				arg_38_0.isCanTouch = true
			end)
		end

		return true
	end)

	return var_38_0
end

function var_0_0.removeNode(arg_43_0, arg_43_1)
	for iter_43_0 = 1, #arg_43_0.models do
		if arg_43_0.models[iter_43_0] == arg_43_1 then
			arg_43_1:removeFromParent()
			table.remove(arg_43_0.models, iter_43_0)
		end
	end
end

function var_0_0.useSnowBall(arg_44_0)
	if arg_44_0.snowType == var_0_9.Normal then
		arg_44_0.selfPlayer:getBackpack():addItemsByID(xyd.tables.misc.snowBallItem, -1)
	else
		arg_44_0.selfPlayer:getBackpack():addItemsByID(xyd.tables.misc.snowBallSuperItem, -1)
	end

	if arg_44_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.snowBallSuperItem) <= 0 then
		local var_44_0 = {
			itemID = xyd.tables.misc.snowBallSuperItem
		}

		var_44_0.itemNum = 1

		arg_44_0.selfPlayer:getBackpack():removeItem(var_44_0)
	end

	if arg_44_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.snowBallItem) <= 0 then
		local var_44_1 = {
			itemID = xyd.tables.misc.snowBallItem
		}

		var_44_1.itemNum = 1

		arg_44_0.selfPlayer:getBackpack():removeItem(var_44_1)
	end
end

return var_0_0
