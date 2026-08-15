local var_0_0 = class("ChocolateFruitsCatchWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.activityChocolateFruit
local var_0_4 = xyd.tables.misc.activityChocolateFruitTime
local var_0_5 = 30
local var_0_6 = 126
local var_0_7 = 180
local var_0_8 = "skeletons/ui_effect/chocolate_fruit/"

FRUIT_STATE = {
	Moving = 2,
	Waiting = 1,
	InBacket = 4,
	HitHero = 6,
	OnGround = 5,
	OnPane = 3
}

local var_0_9 = 154
local var_0_10 = xyd.tables.misc.activityChocolateFruitMask

MASK_HIT_TYPE = {
	LR = 2,
	RR = 4,
	LL = 1,
	RL = 3,
	None = 5
}

function var_0_0.checkMaskType(arg_1_0, arg_1_1)
	local var_1_0 = arg_1_0:nodeByName("container"):convertToNodeSpace(cc.p(0, 0))
	local var_1_1 = arg_1_0.icon1:convertToNodeSpace(arg_1_1)
	local var_1_2 = xyd.subPosition(var_1_1, var_1_0)
	local var_1_3 = math.ceil(var_1_2.x) - 1
	local var_1_4 = math.ceil(var_1_2.y) - 1
	local var_1_5 = {}

	if var_1_4 < 0 or var_1_4 > var_0_9 then
		return MASK_HIT_TYPE.None
	else
		for iter_1_0 = 1, 4 do
			var_1_5[iter_1_0] = var_0_10[var_1_4 + var_0_9 * (iter_1_0 - 1)] or 0
		end

		if var_1_3 < var_1_5[1] or var_1_3 > var_1_5[4] or var_1_3 > var_1_5[2] and var_1_3 < var_1_5[3] then
			return MASK_HIT_TYPE.None
		elseif var_1_3 >= var_1_5[1] and var_1_3 <= var_1_5[2] then
			if var_1_3 < 52 then
				return MASK_HIT_TYPE.LL
			else
				return MASK_HIT_TYPE.LR
			end
		elseif var_1_3 >= var_1_5[3] and var_1_3 <= var_1_5[4] then
			if var_1_3 < 292 then
				return MASK_HIT_TYPE.RL
			else
				return MASK_HIT_TYPE.RR
			end
		end
	end
end

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2)
	var_0_0.super.ctor(arg_2_0, arg_2_1, arg_2_2)

	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.chocolate = xyd.ModelManager.get():loadModel(xyd.ModelType.CHOCOLATE)
	arg_2_0.fruits = {}
	arg_2_0.mine = 0
	arg_2_0.btType = arg_2_2.bt_type
	arg_2_0.star = 0
	arg_2_0.isPause = false
	arg_2_0.stage = 1
	arg_2_0.effects = {}
	arg_2_0.effectsPool = arg_2_0.chocolate.effectsPool or {}
	arg_2_0.fruitsPool = arg_2_0.chocolate.fruitsPool or {}
	arg_2_0.boomTime = 0
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)

	arg_3_0.items = arg_3_0:generateFruits(arg_3_0.stage)

	arg_3_0:layout()
end

function var_0_0.getEffect(arg_4_0, arg_4_1)
	if xyd.isInTable({
		"catch",
		"basket_effect"
	}, arg_4_1) then
		local var_4_0 = arg_4_0.effectsPool[arg_4_1]

		if var_4_0 and next(var_4_0) then
			local var_4_1 = var_4_0[#var_4_0]

			table.remove(var_4_0, #var_4_0)

			return var_4_1
		else
			return arg_4_0:getEffectByName(arg_4_1)
		end
	else
		return arg_4_0:getEffectByName(arg_4_1)
	end
end

function var_0_0.removeEffect(arg_5_0, arg_5_1, arg_5_2)
	if not arg_5_0.effectsPool[arg_5_2] then
		arg_5_0.effectsPool[arg_5_2] = {}
	end

	arg_5_1:removeSelf()
	table.insert(arg_5_0.effectsPool[arg_5_2], arg_5_1)
end

function var_0_0.getEffectByName(arg_6_0, arg_6_1)
	local var_6_0 = var_0_8 .. arg_6_1
	local var_6_1 = xyd.createEffect(var_6_0)

	var_6_1:setAnchorPoint(cc.p(0.5, 0))
	var_6_1:retain()

	return var_6_1
end

function var_0_0.getNextFruit(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_1
	local var_7_1 = {}

	for iter_7_0, iter_7_1 in pairs(arg_7_0.items) do
		if var_7_0 <= iter_7_1.startCount then
			var_7_1[iter_7_0] = 0
		elseif var_7_0 <= iter_7_1.middle then
			var_7_1[iter_7_0] = 2 * iter_7_1.fistHalfNum / (iter_7_1.middle - var_7_0) - iter_7_1.fistH

			if xyd.isInTable({
				3,
				4,
				5
			}, iter_7_0) then
				var_7_1[iter_7_0] = iter_7_1.fistHalfNum / (iter_7_1.middle - var_7_0)
			end
		elseif var_7_0 <= iter_7_1.endCount then
			if iter_7_1.fistHalfNum > 0 then
				iter_7_1.lastHalfNum = iter_7_1.fistHalfNum + iter_7_1.lastHalfNum
				iter_7_1.fistHalfNum = 0
			end

			var_7_1[iter_7_0] = iter_7_1.lastHalfNum / (iter_7_1.endCount - var_7_0)
		end

		var_7_1[iter_7_0] = var_7_1[iter_7_0] or 0
	end

	return var_7_1
end

function var_0_0.layout(arg_8_0)
	arg_8_0:updateTime(0)
	arg_8_0:nodeByName("title_txt"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_FRUIT_TIP1"))
	arg_8_0:nodeByName("time_txt"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	local function var_8_0(...)
		arg_8_0:createScheduler()
		arg_8_0.effects.fruit:play(function(...)
			arg_8_0.effects.fruit:play(nil, true, nil, "idle")
		end, false, nil, "open")
	end

	local function var_8_1(...)
		local var_11_0 = {}

		var_11_0.is_start = true
		var_11_0.callback = var_8_0

		xyd.WindowManager.get():openWindow("chocolate_fruits_start", var_11_0)
	end

	local var_8_2 = {
		playerID = arg_8_0.selfPlayer.playerID,
		name = xyd.state.CHOCOLATE_FRUIT_ALREADY_PLAYED,
		state = tostring(1)
	}
	local var_8_3 = tonumber(xyd.db.stateVariable:getState(var_8_2.playerID, var_8_2.name)) == 1

	if not var_8_3 then
		xyd.db.stateVariable:setState(var_8_2)
	end

	if var_8_3 then
		var_8_1()
	else
		local var_8_4 = {
			callback = var_8_1
		}

		xyd.WindowManager.get():openWindow("chocolate_fruits_graphic", var_8_4)
	end

	arg_8_0:addTouchArena()
	arg_8_0:pauseAll(false)
	arg_8_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_8_0:nodeByName("rule_btn"), arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			arg_8_0:pauseAll(true)

			local function var_12_0()
				arg_8_0:pauseAll(false)
			end

			local var_12_1 = {
				callback = var_12_0
			}

			xyd.WindowManager.get():openWindow("chocolate_fruits_graphic", var_12_1)
		end
	end)
	arg_8_0:nodeByName("control_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(arg_8_0:nodeByName("control_btn"), arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			arg_8_0:pauseAll(not arg_8_0.isPause)
		end
	end)
	arg_8_0:nodeByName("close"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			arg_8_0:pauseAll(true)

			if not arg_8_0.handle then
				xyd.WindowManager.get():closeWindow(arg_8_0)

				return
			end

			local var_15_0 = var_0_1:translation("ACTIVITY_CHOCOLATE_FRUIT_EXIT")

			local function var_15_1()
				arg_8_0.isPause = false

				arg_8_0:pauseAll(arg_8_0.isPause)
			end

			local var_15_2 = {
				rcallback = rightcallback,
				lcallback = var_15_1
			}

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_15_0, function()
				arg_8_0.forceEnd = true
			end, var_15_2, nil, xyd.ColorMode.ACTIVITY)

			return
		end
	end)
	arg_8_0:initEffect()
end

function var_0_0.initEffect(arg_18_0)
	if not arg_18_0.effects.basket then
		local var_18_0 = arg_18_0:getEffect("basket")

		var_18_0:addTo(arg_18_0:nodeByName("container"))
		var_18_0:play(nil, true)
		var_18_0:setPosition(cc.p(1142, 55))

		arg_18_0.effects.basket = var_18_0

		arg_18_0.effects.basket:play(nil, true, nil, "idle")
	end

	arg_18_0:nodeByName("fruit_pos"):setLocalZOrder(20)

	if not arg_18_0.effects.fruit then
		local var_18_1 = arg_18_0:getEffect("fruit")

		var_18_1:addTo(arg_18_0:nodeByName("fruit_pos"))
		var_18_1:play(nil, true)
		var_18_1:setPosition(cc.p(640, 46))

		arg_18_0.effects.fruit = var_18_1

		arg_18_0.effects.fruit:play(nil, true, nil, "idle")
		arg_18_0.effects.fruit:setLocalZOrder(20)

		local var_18_2 = arg_18_0:getEffect("boom_effect")

		var_18_2:addTo(arg_18_0.effects.fruit)
		var_18_2:setPosition(cc.p(-200, 250))
		var_18_2:play(nil, true)
		var_18_2:setVisible(false)

		arg_18_0.effects.fruit.boomLeft = var_18_2

		local var_18_3 = arg_18_0:getEffect("boom_effect")

		var_18_3:addTo(arg_18_0.effects.fruit)
		var_18_3:setPosition(cc.p(200, 250))
		var_18_3:play(nil, true)
		var_18_3:setVisible(false)

		arg_18_0.effects.fruit.boomRight = var_18_3

		arg_18_0.effects.fruit:setScale(0.54)
	end

	local var_18_4 = xyd.AssetLoader.get():loadSprite("windows/chocolate_fruits/catch/plane.png")

	var_18_4:setAnchorPoint(cc.p(0.5, 0))
	var_18_4:addTo(arg_18_0.effects.fruit)
	var_18_4:setPosition(cc.p(15, 0))
	var_18_4:setScale(1.8518518518518516)
	var_18_4:setVisible(false)

	arg_18_0.icon1 = var_18_4
end

function var_0_0.pauseAll(arg_19_0, arg_19_1)
	arg_19_0.isPause = arg_19_1

	arg_19_0:nodeByName("pause"):setVisible(arg_19_0.isPause)
	arg_19_0:nodeByName("continue"):setVisible(not arg_19_0.isPause)

	for iter_19_0, iter_19_1 in pairs(arg_19_0.fruits) do
		if arg_19_1 then
			iter_19_1:pause()
		else
			iter_19_1:resume()
		end
	end
end

function var_0_0.willClose(arg_20_0, arg_20_1)
	var_0_0.super.willClose(arg_20_0, arg_20_1)

	if arg_20_0.handle then
		var_0_2.unscheduleGlobal(arg_20_0.handle)

		arg_20_0.handle = nil
	end

	arg_20_0:removeAllFruits()
end

function var_0_0.releaseItems(arg_21_0, arg_21_1)
	for iter_21_0 = #arg_21_1, 1, -1 do
		local var_21_0 = arg_21_1[iter_21_0]

		table.remove(arg_21_1, iter_21_0)

		if var_21_0 and not tolua.isnull(var_21_0) then
			var_21_0:release()
		end
	end

	arg_21_1 = {}
end

function var_0_0.createScheduler(arg_22_0)
	if arg_22_0.handle then
		var_0_2.unscheduleGlobal(arg_22_0.handle)

		arg_22_0.handle = nil
	end

	arg_22_0.stageCount = 0
	arg_22_0.totalCount = 0
	arg_22_0.lastBornCount = 0

	arg_22_0:updateTime(arg_22_0.totalCount)
	arg_22_0:updateStar()

	arg_22_0.handle = var_0_2.scheduleUpdateGlobal(handler(arg_22_0, arg_22_0.loop))
end

function var_0_0.loop(arg_23_0)
	if arg_23_0.mine >= xyd.tables.misc.activityChocolateFruitBoom and arg_23_0.btType == 2 or arg_23_0.totalCount >= var_0_4 * var_0_5 and arg_23_0.btType == 1 or arg_23_0.forceEnd then
		if arg_23_0.handle then
			var_0_2.unscheduleGlobal(arg_23_0.handle)

			arg_23_0.handle = nil
		end

		arg_23_0:endGame()

		return
	end

	if arg_23_0.isPause then
		return
	end

	if arg_23_0.stageCount >= var_0_4 * var_0_5 then
		arg_23_0.stageCount = 0

		arg_23_0:nextStage()

		return
	end

	arg_23_0.stageCount = arg_23_0.stageCount + 1
	arg_23_0.totalCount = arg_23_0.totalCount + 1

	if arg_23_0.boomTime > 0 then
		arg_23_0.boomTime = arg_23_0.boomTime - 1

		if arg_23_0.boomTime == 0 then
			arg_23_0.effects.fruit.boomLeft:setVisible(false)
			arg_23_0.effects.fruit.boomRight:setVisible(false)
		end
	end

	arg_23_0:updateTime(arg_23_0.totalCount)

	local var_23_0 = arg_23_0.effects.fruit
	local var_23_1 = cc.p(var_23_0:getPosition())

	planeSize = var_0_7

	local var_23_2 = 0

	if arg_23_0.event then
		var_23_2 = (arg_23_0.event.x - var_23_1.x) / 15

		local var_23_3 = math.abs(var_23_2)
		local var_23_4 = math.min(var_23_3 * 15, math.max(xyd.tables.misc.activityChocolatefruitRunMin, var_23_3))

		if var_23_4 >= xyd.tables.misc.activityChocolatefruitRunMin then
			var_23_2 = var_23_2 / math.abs(var_23_2) * var_23_4
		end

		var_23_1 = xyd.addPosition(var_23_1, cc.p(var_23_2, 0))
	end

	var_23_1.x = math.min(1280 - planeSize / 2, var_23_1.x)
	var_23_1.x = math.max(planeSize / 2, var_23_1.x)

	if arg_23_0.boomTime <= 0 then
		var_23_0:runActionOnce(cc.MoveTo:create(0.03333333333333333, var_23_1))

		var_23_0.biasX = var_23_2
	end

	arg_23_0:updateFruitsState()

	local var_23_5 = arg_23_0:getNextFruit(arg_23_0.stageCount)
	local var_23_6 = 0
	local var_23_7 = 1

	for iter_23_0, iter_23_1 in pairs(var_23_5) do
		local var_23_8 = arg_23_0.items[iter_23_0]

		if var_23_6 < iter_23_1 then
			var_23_6 = iter_23_1
			var_23_7 = iter_23_0
		end

		if iter_23_1 >= math.random() then
			if arg_23_0.stageCount < var_23_8.middle then
				var_23_8.fistHalfNum = var_23_8.fistHalfNum - 1
			else
				var_23_8.lastHalfNum = var_23_8.lastHalfNum - 1
			end

			arg_23_0:addFruit(iter_23_0)

			arg_23_0.lastBornCount = arg_23_0.stageCount
		end
	end

	if arg_23_0.stageCount - arg_23_0.lastBornCount >= 90 and var_23_6 > 0 then
		local var_23_9 = arg_23_0.items[var_23_7]

		if arg_23_0.stageCount < var_23_9.middle then
			var_23_9.fistHalfNum = var_23_9.fistHalfNum - 1
		else
			var_23_9.lastHalfNum = var_23_9.lastHalfNum - 1
		end

		arg_23_0:addFruit(var_23_7)

		arg_23_0.lastBornCount = arg_23_0.stageCount
	end
end

function var_0_0.nextStage(arg_24_0)
	arg_24_0.stageCount = 0
	arg_24_0.lastBornCount = arg_24_0.stageCount
	arg_24_0.stage = arg_24_0.stage + 1

	arg_24_0:pauseAll(true)

	local function var_24_0(...)
		arg_24_0:removeAllFruits()

		arg_24_0.items = arg_24_0:generateFruits(arg_24_0.stage)
		arg_24_0.isPause = false
	end

	local var_24_1 = {
		callback = var_24_0
	}

	var_24_1.is_next = true

	xyd.WindowManager.get():openWindow("chocolate_fruits_start", var_24_1)
end

function var_0_0.removeAllFruits(arg_26_0)
	for iter_26_0 = #arg_26_0.fruits, 1, -1 do
		arg_26_0:removeFruit(iter_26_0, 0)
	end

	arg_26_0.fruits = {}
end

function var_0_0.endGame(arg_27_0)
	local function var_27_0(...)
		local var_28_0 = {
			score = arg_27_0.star
		}

		if arg_27_0.btType == 2 then
			var_28_0.wave_nums = arg_27_0.stage - 1
		end

		arg_27_0:removeAllFruits()
		arg_27_0.chocolate:chocolateFruitEnd(var_28_0, function(arg_29_0, arg_29_1)
			arg_27_0.onEnd = false

			if arg_29_0 == xyd.error.OK then
				var_28_0.bt_type = arg_27_0.btType
				var_28_0.score = arg_29_1.score
				var_28_0.wave_nums = arg_29_1.wave_nums or var_28_0.wave_nums
				var_28_0.awards = arg_29_1.awards

				xyd.WindowManager.get():openWindow("chocolate_fruits_result", var_28_0)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("NET_WORK_ERROR_TEXT")
				})
				xyd.WindowManager.get():closeWindow(arg_27_0)
			end
		end)
	end

	arg_27_0.onEnd = true

	arg_27_0.effects.fruit:play(function()
		var_27_0()
	end, false, nil, "open")
end

function var_0_0.updateTime(arg_31_0, arg_31_1)
	if arg_31_1 < 0 then
		arg_31_1 = 0
	end

	local var_31_0 = math.max(0, var_0_4 - math.ceil(arg_31_1 / var_0_5))

	if arg_31_0.btType == 2 then
		var_31_0 = math.ceil(arg_31_1 / var_0_5)
	end

	arg_31_0:nodeByName("time_txt"):setString(xyd.secondsToString(var_31_0))
end

function var_0_0.updateStar(arg_32_0, arg_32_1, arg_32_2)
	if arg_32_1 then
		arg_32_0.star = arg_32_0.star + var_0_3:point(arg_32_1)
		arg_32_0.star = math.max(0, arg_32_0.star)

		if var_0_3:point(arg_32_1) < 0 then
			arg_32_0.mine = arg_32_0.mine + 1
		end
	end

	arg_32_0:nodeByName("score_txt"):setString(arg_32_0.star)
	arg_32_0:nodeByName("bomb_txt"):setString(arg_32_0.mine)

	if arg_32_1 and arg_32_2 then
		arg_32_0:playAddScore(arg_32_1, arg_32_2)
	end
end

function var_0_0.addFruit(arg_33_0, arg_33_1)
	local var_33_0
	local var_33_1 = arg_33_0.fruitsPool[arg_33_1]

	if var_33_1 and next(var_33_1) then
		var_33_0 = var_33_1[#var_33_1]

		arg_33_0:reInitFruit(var_33_0)
		table.remove(var_33_1, #var_33_1)
	else
		var_33_0 = arg_33_0:createFruit(arg_33_1)

		var_33_0:retain()
	end

	var_33_0:addTo(arg_33_0:nodeByName("fruit_pos"))
	var_33_0:setLocalZOrder(30)

	local var_33_2 = arg_33_0:generateFruitAcitionParams(arg_33_1)

	var_33_2.fruit_type = arg_33_1
	var_33_2.time = var_0_3:times(arg_33_1)
	var_33_2.orgTime = var_33_2.time
	var_33_0.params = var_33_2

	var_33_0:setPosition(var_33_2.postion)
	table.insert(arg_33_0.fruits, var_33_0)
end

function var_0_0.createFruit(arg_34_0, arg_34_1)
	local var_34_0 = var_0_3:icon(arg_34_1)
	local var_34_1 = display.newNode()
	local var_34_2 = xyd.AssetLoader.get():loadSprite(var_34_0)

	var_34_2:setAnchorPoint(cc.p(0.5, 0))
	var_34_2:addTo(var_34_1)
	var_34_2:setName("fruit")

	if arg_34_1 == 2 then
		local var_34_3 = arg_34_0:getEffect("warning")
		local var_34_4 = arg_34_0:getEffect("bomb")

		var_34_3:addTo(var_34_1)
		var_34_4:addTo(var_34_1)

		var_34_1.warming = var_34_3
		var_34_1.bomb = var_34_4

		var_34_3:play(nil, false, nil, "texiao01")
		var_34_2:setVisible(false)

		var_34_1.danger_count = 30

		local var_34_5 = xyd.AssetLoader.get():loadSprite("windows/chocolate_fruits/catch/exclamatory_mark.png")

		var_34_5:setAnchorPoint(cc.p(0.5, 1))
		var_34_5:addTo(var_34_1)
		var_34_5:setPositionY(5)

		var_34_1.exclamatoryMark = var_34_5
	else
		if arg_34_1 ~= 1 then
			local var_34_6 = arg_34_0:getEffect("miss")

			var_34_6:addTo(var_34_1)
			var_34_6:setPosition(cc.p(0, 0))
			var_34_6:setVisible(false)

			var_34_1.effect = var_34_6
		end

		local var_34_7 = arg_34_0:getEffectByName("catch")

		var_34_7:addTo(var_34_1)
		var_34_7:setVisible(false)

		var_34_1.star = var_34_7
	end

	return var_34_1
end

function var_0_0.reInitFruit(arg_35_0, arg_35_1)
	if arg_35_1.params.fruit_type == 2 then
		arg_35_1.warming:setVisible(true)
		arg_35_1.bomb:setVisible(false)
		arg_35_1.exclamatoryMark:setVisible(true)
		arg_35_1:getChildByName("fruit"):setVisible(false)
		arg_35_1.warming:play(nil, false, nil, "texiao01")

		arg_35_1.danger_count = 30
	else
		arg_35_1:getChildByName("fruit"):setVisible(true)

		if arg_35_1.effect then
			arg_35_1.effect:setVisible(false)
		end

		if arg_35_1.star then
			arg_35_1.star:setVisible(false)
		end
	end
end

function var_0_0.playAddScore(arg_36_0, arg_36_1, arg_36_2)
	local var_36_0 = xyd.createLabel(38, cc.c3b(255, 255, 255))
	local var_36_1 = var_0_3:point(arg_36_1)

	if var_36_1 < 0 then
		var_36_0:setString(var_36_1)
	else
		var_36_0:setString("+" .. var_36_1)
	end

	var_36_0:addTo(arg_36_0:nodeByName("fruit_pos"))
	var_36_0:setAnchorPoint(cc.p(0.5, 0))
	var_36_0:setPosition(xyd.addPosition(arg_36_2, cc.p(0, 100)))
	var_36_0:enableOutline(cc.c4b(255, 96, 0, 255), 3)

	local var_36_2 = 0
	local var_36_3 = xyd.tables.battleConfig.floatAnimationDuration * 5
	local var_36_4 = xyd.tables.battleConfig.floatFadeOutDelay * 5
	local var_36_5 = cc.Spawn:create({
		cc.MoveBy:create(var_36_3, cc.p(0, 400)),
		cc.Sequence:create({
			cc.DelayTime:create(var_36_4),
			cc.FadeOut:create(var_36_3 - var_36_4)
		})
	})

	var_36_0:runActionOnce(var_36_5, true, nil, var_36_2)
end

function var_0_0.addTouchArena(arg_37_0)
	local var_37_0 = display.newNode()

	var_37_0:setName("touchNode")
	var_37_0:setContentSize(1280, 400)
	var_37_0:setAnchorPoint(cc.p(0, 0))
	var_37_0:setTouchEnabled(true)
	var_37_0:addTo(arg_37_0:nodeByName("container"))
	var_37_0:setLocalZOrder(1000)
	var_37_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_38_0)
		if arg_38_0.name == "began" and arg_37_0.boomTime <= 0 and not arg_37_0.onEnd then
			arg_37_0.event = arg_37_0:nodeByName("container"):convertToNodeSpace(cc.p(arg_38_0.x, arg_38_0.y))

			arg_37_0.effects.fruit:play(nil, true, nil, "run")

			return true
		elseif arg_38_0.name == "moved" and arg_37_0.boomTime <= 0 and not arg_37_0.onEnd then
			arg_37_0.event = arg_37_0:nodeByName("container"):convertToNodeSpace(cc.p(arg_38_0.x, arg_38_0.y))
		elseif arg_38_0.name == "ended" then
			if not arg_37_0.onEnd then
				arg_37_0.effects.fruit:play(nil, true, nil, "idle")
			end

			arg_37_0.event = nil
		end
	end)
end

function var_0_0.updateFruitsState(arg_39_0)
	for iter_39_0 = #arg_39_0.fruits, 1, -1 do
		local var_39_0 = arg_39_0.fruits[iter_39_0]
		local var_39_1 = var_39_0.params
		local var_39_2 = var_39_1.postion
		local var_39_3 = clone(var_39_2)

		if var_39_0.danger_count and var_39_0.danger_count >= 0 then
			var_39_0.danger_count = var_39_0.danger_count - 1

			if var_39_0.danger_count == 27 then
				var_39_0.warming:play(nil, true, nil, "texiao02")
			elseif var_39_0.danger_count == 3 then
				var_39_0.warming:play(nil, false, nil, "texiao03")
			end
		end

		if var_39_0.danger_count and var_39_0.danger_count <= 0 then
			var_39_0:getChildByName("fruit"):setVisible(true)
			var_39_0.warming:setVisible(false)
			var_39_0.exclamatoryMark:setVisible(false)
		end

		if var_39_1.HitHero or not var_39_1.isEnd and (not var_39_0.danger_count or var_39_0.danger_count <= -1) then
			var_39_2.x = var_39_2.x + var_39_1.speedx
			var_39_2.y = var_39_2.y + (var_39_1.speedy + var_39_1.g / 2)
			var_39_1.speedy = var_39_1.speedy + var_39_1.g
			var_39_1.postion = var_39_2

			var_39_0:setPosition(var_39_1.postion)
		end

		local var_39_4 = arg_39_0:getFruitState(var_39_1, var_39_3, var_39_2)

		if var_39_1.HitHero and var_39_1.maskType ~= MASK_HIT_TYPE.LR and var_39_1.maskType ~= MASK_HIT_TYPE.RL and var_39_4 ~= FRUIT_STATE.OnGround then
			-- block empty
		elseif var_39_4 == FRUIT_STATE.OnPane then
			if var_39_1.orgTime == 0 then
				arg_39_0:updateStar(var_39_1.fruit_type, var_39_2)
				var_39_0:getChildByName("fruit"):setVisible(false)

				if var_39_1.fruit_type == 2 then
					var_39_0.bomb:setVisible(true)
					var_39_0.bomb:play(nil, false)
					arg_39_0.effects.fruit.boomLeft:setVisible(true)
					arg_39_0.effects.fruit.boomRight:setVisible(true)

					arg_39_0.boomTime = 30

					arg_39_0:playSound("fruit_burst")
				elseif var_39_1.fruit_type == 1 then
					var_39_0.star:setVisible(true)
					var_39_0.star:play(nil, false, nil, "texiao02")
					arg_39_0:playSound("fruit_catch")
				end

				arg_39_0:removeFruit(iter_39_0)
			else
				local var_39_5 = arg_39_0:generateTargetPosition()

				if var_39_1.time > 1 then
					var_39_5 = cc.p(math.random(var_39_1.postion.x, 1020), var_39_1.postion.y)
					var_39_1.time = var_39_1.time - 1
				end

				var_39_1.speedy = -var_39_1.speedy
				var_39_1.speedx = arg_39_0:getTargetSpeedX(var_39_1.postion, var_39_5, var_39_1.g, var_39_1.speedy)

				local var_39_6 = arg_39_0:getEffect("catch")

				var_39_6:setAnchorPoint(cc.p(0.5, 0))
				var_39_6:addTo(arg_39_0:nodeByName("fruit_pos"))
				var_39_6:play(nil, false, nil, "texiao01")
				var_39_6:setPosition(var_39_0:getPosition())
				var_0_2.performWithDelayGlobal(function()
					if arg_39_0 and not tolua.isnull(var_39_6) then
						arg_39_0:removeEffect(var_39_6, "catch")
					end
				end, 0.4)
			end
		elseif var_39_4 == FRUIT_STATE.InBacket then
			arg_39_0:updateStar(var_39_1.fruit_type, var_39_2)
			arg_39_0:removeFruit(iter_39_0, 0)
			arg_39_0.effects.basket:play(function(...)
				arg_39_0.effects.basket:play(nil, true, nil, "idle")
			end, false, nil, "fruit")

			local var_39_7 = arg_39_0:getEffect("basket_effect")

			var_39_7:addTo(arg_39_0:nodeByName("fruit_pos"))
			var_39_7:setPosition(cc.p(1142, 255))
			var_39_7:play(nil, false)
			var_0_2.performWithDelayGlobal(function()
				if arg_39_0 and not tolua.isnull(var_39_7) then
					arg_39_0:removeEffect(var_39_7, "basket_effect")
				end
			end, 0.4)
			arg_39_0:playSound("fruit_catch")
		elseif var_39_4 == FRUIT_STATE.OnGround or var_39_4 == FRUIT_STATE.HitHero and xyd.isInTable({
			1,
			2
		}, var_39_1.fruit_type) then
			var_39_1.isEnd = true

			if var_39_4 == FRUIT_STATE.OnGround then
				var_39_0:setPositionY(46)
			else
				var_39_0:setPosition(var_39_3)
			end

			if var_39_0.effect then
				var_39_0.effect:setVisible(true)
			end

			var_39_0:getChildByName("fruit"):setVisible(false)

			if var_39_1.fruit_type == 5 then
				var_39_0.effect:play(nil, false, nil, "texiao0" .. 1)
			elseif var_39_1.fruit_type == 6 then
				var_39_0.effect:play(nil, false, nil, "texiao0" .. 2)
			elseif var_39_1.fruit_type == 4 then
				var_39_0.effect:play(nil, false, nil, "texiao0" .. 3)
			elseif var_39_1.fruit_type == 3 then
				var_39_0.effect:play(nil, false, nil, "texiao0" .. 4)
			elseif var_39_1.fruit_type == 2 then
				var_39_0.bomb:setVisible(true)
				var_39_0.bomb:play(nil, false)

				if var_39_4 == FRUIT_STATE.HitHero then
					arg_39_0.effects.fruit.boomLeft:setVisible(true)
					arg_39_0.effects.fruit.boomRight:setVisible(true)

					arg_39_0.boomTime = 30

					arg_39_0:updateStar(var_39_1.fruit_type)
					arg_39_0:playSound("fruit_burst")
				end
			end

			arg_39_0:removeFruit(iter_39_0)
		end

		if var_39_1.speedy < 0 and not var_39_1.HitHero and var_39_4 == FRUIT_STATE.HitHero and not xyd.isInTable({
			1,
			2
		}, var_39_1.fruit_type) then
			local var_39_8 = arg_39_0:checkMaskType(var_39_2)

			var_39_0:setLocalZOrder(10)

			var_39_1.HitHero = true

			if var_39_8 == MASK_HIT_TYPE.LL then
				var_39_1.speedx = -math.abs(var_39_1.speedx) * 3
			elseif var_39_8 == MASK_HIT_TYPE.LR then
				var_39_1.maskType = MASK_HIT_TYPE.LR
				var_39_1.speedy = var_39_1.speedy / 2
				var_39_1.speedx = var_39_1.speedx * 3

				var_39_0:setLocalZOrder(30)
			elseif var_39_8 == MASK_HIT_TYPE.RL then
				var_39_1.speedx = -math.abs(var_39_1.speedx) * 2
				var_39_1.speedy = var_39_1.speedy / 2
				var_39_1.maskType = MASK_HIT_TYPE.RL

				var_39_0:setLocalZOrder(30)
			elseif var_39_8 == MASK_HIT_TYPE.RR then
				var_39_1.speedx = math.abs(var_39_1.speedx) * 3
			end

			var_39_1.speedy = 2 * var_39_1.speedy
		end
	end
end

function var_0_0.playSound(arg_43_0, arg_43_1)
	local var_43_0 = xyd.tables.sound:getSound(arg_43_1)

	audio.playSound(var_43_0, false)
end

function var_0_0.removeFruit(arg_44_0, arg_44_1, arg_44_2)
	arg_44_2 = arg_44_2 or 0.4

	local var_44_0 = arg_44_0.fruits[arg_44_1]

	table.remove(arg_44_0.fruits, arg_44_1)

	local function var_44_1(arg_45_0)
		if arg_44_0 and not tolua.isnull(arg_45_0) then
			arg_45_0:removeSelf()

			local var_45_0 = arg_45_0.params.fruit_type

			if not arg_44_0.fruitsPool[var_45_0] then
				arg_44_0.fruitsPool[var_45_0] = {}
			end

			table.insert(arg_44_0.fruitsPool[var_45_0], arg_45_0)
		end
	end

	if arg_44_2 > 0 then
		var_0_2.performWithDelayGlobal(function()
			var_44_1(var_44_0)
		end, arg_44_2)
	else
		var_44_1(var_44_0)
	end
end

function var_0_0.getFruitState(arg_47_0, arg_47_1, arg_47_2, arg_47_3)
	local var_47_0 = arg_47_0.effects.fruit
	local var_47_1 = cc.p(var_47_0:getPosition())
	local var_47_2 = var_47_0.biasX or 0

	planeSize = var_0_7

	if arg_47_0:checkMaskType(arg_47_3) ~= MASK_HIT_TYPE.None then
		return FRUIT_STATE.HitHero
	elseif arg_47_2.y > var_0_6 and arg_47_3.y <= var_0_6 and arg_47_3.x > var_47_1.x - planeSize / 2 - math.max(var_47_2 / 2, 0) and arg_47_3.x < var_47_1.x + planeSize / 2 - math.min(var_47_2 / 2, 0) then
		return FRUIT_STATE.OnPane
	elseif arg_47_2.y < 10 then
		return FRUIT_STATE.OnGround
	elseif arg_47_3.x > 1100 and arg_47_3.x < 1180 and arg_47_2.y > 275 and arg_47_3.y <= 275 then
		return FRUIT_STATE.InBacket
	else
		return FRUIT_STATE.Moving
	end
end

function var_0_0.generateFruitAcitionParams(arg_48_0, arg_48_1)
	local var_48_0 = var_0_3:x(arg_48_1)
	local var_48_1 = var_0_3:y(arg_48_1)
	local var_48_2 = {
		postion = arg_48_0:generateFruitPostion()
	}

	var_48_2.orgPosition = var_48_2.postion
	var_48_2.speedx = math.random(var_48_0[1], var_48_0[2])
	var_48_2.speedy = -math.random(var_48_1[1], var_48_1[2])
	var_48_2.g = -xyd.tables.misc.activityChocolatefruitGravity

	if arg_48_1 == 2 and math.random() < 0.3333333333333333 then
		local var_48_3 = cc.p(arg_48_0.effects.fruit:getPosition()).x
		local var_48_4 = cc.p(var_48_3 + math.random(-var_0_7 / 2, var_0_7 / 2), var_0_6)

		var_48_2.speedx = arg_48_0:getTargetSpeedX(var_48_2.orgPosition, var_48_4, var_48_2.g, var_48_2.speedy)
	end

	return var_48_2
end

function var_0_0.generateFruitPostion(arg_49_0)
	return cc.p(math.random(100, 500), math.random(400, 600))
end

function var_0_0.generateTargetPosition(arg_50_0)
	return cc.p(1157, 285)
end

function var_0_0.getTargetSpeedX(arg_51_0, arg_51_1, arg_51_2, arg_51_3, arg_51_4)
	return (arg_51_2.x - arg_51_1.x) * arg_51_3 / (-arg_51_4 - math.sqrt(arg_51_4 * arg_51_4 + 2 * arg_51_3 * (arg_51_2.y - arg_51_1.y)))
end

function var_0_0.generateFruits(arg_52_0, arg_52_1)
	local var_52_0 = {}

	arg_52_1 = arg_52_1 or 1
	arg_52_1 = math.min(arg_52_1, 12)

	local var_52_1 = var_0_3:ids()

	for iter_52_0, iter_52_1 in pairs(var_52_1) do
		local var_52_2 = clone(var_0_3:num(iter_52_1))
		local var_52_3 = var_0_3:speed(iter_52_1)[arg_52_1] or 1
		local var_52_4 = var_0_3:open(iter_52_1)

		var_52_2[1] = var_52_2[1] * var_52_3
		var_52_2[2] = var_52_2[2] * var_52_3
		num = math.random(var_52_2[1], var_52_2[2])

		local var_52_5 = {
			num = num,
			startCount = var_52_4[1] * var_0_5,
			endCount = var_52_4[2] * var_0_5
		}

		var_52_5.totalCount = var_52_5.endCount - var_52_5.startCount
		var_52_5.middle = var_52_5.startCount + var_52_5.totalCount / 2
		var_52_5.fistHalfNum = math.ceil(var_52_5.num / 3)
		var_52_5.lastHalfNum = var_52_5.num - var_52_5.fistHalfNum
		var_52_5.fistH = 4 * var_52_5.fistHalfNum / var_52_5.totalCount
		var_52_5.lastH = 2 * var_52_5.lastHalfNum / var_52_5.totalCount
		var_52_0[iter_52_1] = var_52_5
	end

	return var_52_0
end

return var_0_0
