local var_0_0 = class("FourthAnniGoldCatchWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.misc.activityAnni4thGoldTime
local var_0_4 = xyd.tables.activityAnni4thGoldMap
local var_0_5 = xyd.tables.activityAnni4thGoldItem
local var_0_6 = xyd.tables.activityAnni4thGoldNormal
local var_0_7 = xyd.tables.activityAnni4thGoldSpecial
local var_0_8 = xyd.tables.activityAnni4thGoldLuckybag
local var_0_9 = xyd.tables.goldCatchItem
local var_0_10 = 30
local var_0_11 = 126
local var_0_12 = 180
local var_0_13 = 80
local var_0_14 = 1.5
local var_0_15 = 20
local var_0_16 = 14
local var_0_17 = 30
local var_0_18 = 0.5
local var_0_19 = 0.3
local var_0_20 = 0.12
local var_0_21 = "skeletons/ui_effect/gold_catch/"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	cc.Director:getInstance():purgeCachedData()
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.itemHeight = var_0_5:getHeight()
	arg_1_0.speedMultiply = var_0_5:getMultiple()
	arg_1_0.itemSpeed = var_0_5:getSpeed()
	arg_1_0.rates = {}
	arg_1_0.annifourth = xyd.ModelManager.get():loadModel(xyd.ModelType.FOURTH_ANNIVERSARY)
	arg_1_0.btType = arg_1_2.bt_type

	if arg_1_2.getInfo then
		arg_1_0.getInfo = true
	end

	arg_1_0.effects = {}
	arg_1_0.angle = -1 * var_0_13
	arg_1_0.notEnd = false
	arg_1_0.move = false
	arg_1_0.moveTime = 0
	arg_1_0.down = -1
	arg_1_0.itemNum = 8
	arg_1_0.point = 0
	arg_1_0.goldenNum = 0
	arg_1_0.bombNum = 0
	arg_1_0.clockNum = 0

	if arg_1_0.btType == 1 then
		arg_1_0.levelStage = var_0_6:getScore()
	elseif arg_1_0.btType == 2 then
		arg_1_0.levelStage = var_0_7:getScore()
		arg_1_0.goldenNum = 2
		arg_1_0.bombNum = 2
		arg_1_0.clockNum = 1
	end

	arg_1_0.nowLev = 1
	arg_1_0.nowGetItem = 0
	arg_1_0.downangle = 31
	arg_1_0.isPause = false
	arg_1_0.changeSpeed = false
	arg_1_0.speedUp = false
	arg_1_0.pauseTime = 2
	arg_1_0.moveSpeed = arg_1_0:changeMoveSpeed(var_0_16)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	collectgarbage("collect")
	arg_2_0:layout()
end

function var_0_0.getEffect(arg_3_0, arg_3_1)
	local var_3_0 = var_0_21 .. arg_3_1
	local var_3_1 = xyd.createEffect(var_3_0)

	var_3_1:setAnchorPoint(cc.p(0, 0))

	return var_3_1
end

function var_0_0.setType(arg_4_0)
	arg_4_0.types = {}

	local var_4_0 = {}

	for iter_4_0 = 1, 8 do
		local var_4_1 = var_0_5:sequence(iter_4_0)

		for iter_4_1 = var_4_1[1], var_4_1[2] do
			arg_4_0.types[iter_4_1] = iter_4_0
		end
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:updateTime(0)
	arg_5_0:setType()

	local function var_5_0(...)
		arg_5_0:createScheduler()
	end

	local function var_5_1()
		local var_7_0 = {}

		var_7_0.is_start = true
		var_7_0.callback = var_5_0

		xyd.WindowManager.get():openWindow("gold_start", var_7_0)
	end

	local var_5_2 = var_0_8:getAllRates()
	local var_5_3 = 1

	for iter_5_0 = 1, #var_5_2 do
		for iter_5_1 = 1, var_5_2[iter_5_0] do
			arg_5_0.rates[var_5_3] = iter_5_0
			var_5_3 = var_5_3 + 1
		end
	end

	if arg_5_0.annifourth.notFristIn then
		var_5_1()
	else
		arg_5_0.annifourth.notFristIn = true

		local var_5_4 = {
			callback = var_5_1
		}

		var_5_4.nowPage = 6

		xyd.WindowManager.get():openWindow("gold_graphic", var_5_4)
	end

	arg_5_0:initEffect()
	arg_5_0:initMapCondition()
	arg_5_0:checkMap()
	arg_5_0:addTouchArena()
end

function var_0_0.initMapCondition(arg_8_0)
	arg_8_0:nodeByName("point_container"):setVisible(false)
	arg_8_0:nodeByName("item_container"):setVisible(false)
	arg_8_0:nodeByName("point_text"):enableOutline(cc.c4b(168, 106, 34, 255), 2)
	arg_8_0:nodeByName("point_txt"):enableOutline(cc.c4b(168, 106, 34, 255), 2)
	arg_8_0:nodeByName("item_txt"):enableOutline(cc.c4b(168, 106, 34, 255), 2)
	arg_8_0:nodeByName("money_text"):setString(tostring(var_0_1:translation("FOURTH_ANNI_GOLD_TIP1")) .. "：")
	arg_8_0:nodeByName("score_text"):setString(var_0_1:translation("FOURTH_ANNI_GOLD_TIP2"))
	arg_8_0:nodeByName("time_text"):setString(tostring(var_0_1:translation("FOURTH_ANNI_GOLD_TIP3")) .. "：")
	arg_8_0:nodeByName("level_text1"):setString(var_0_1:translation("FOURTH_ANNI_GOLD_TIP4"))
	arg_8_0:nodeByName("level_text2"):setString(var_0_1:translation("FOURTH_ANNI_GOLD_TIP5"))
	arg_8_0:nodeByName("point_text"):setString(var_0_1:translation("FOURTH_ANNI_GOLD_TIP1"))

	arg_8_0.allMap = var_0_4:level()
	arg_8_0.levelNum = 0

	if arg_8_0.btType == 1 then
		arg_8_0.levelNum = #var_0_6:level()
	else
		arg_8_0.levelNum = #var_0_7:level()
	end
end

function var_0_0.createScheduler(arg_9_0)
	if arg_9_0.handle then
		var_0_2.unscheduleGlobal(arg_9_0.handle)

		arg_9_0.handle = nil
	end

	arg_9_0.totalCount = 0
	arg_9_0.totalFrame = 0

	arg_9_0.effects.partner:play(nil, true, nil, "idle")

	arg_9_0.rotateFace = var_0_14

	arg_9_0:updateTime(arg_9_0.totalCount)

	arg_9_0.handle = var_0_2.scheduleUpdateGlobal(handler(arg_9_0, arg_9_0.loop))
end

function var_0_0.loop(arg_10_0)
	if arg_10_0.totalCount >= var_0_3 * var_0_10 and not arg_10_0.notEnd then
		if arg_10_0.handle then
			var_0_2.unscheduleGlobal(arg_10_0.handle)

			arg_10_0.handle = nil
		end

		if arg_10_0.nowLev >= arg_10_0.levelNum then
			arg_10_0.onEnd = true
		end

		arg_10_0:endGame()

		return
	end

	if arg_10_0.forceEnd and not arg_10_0.notEnd then
		if arg_10_0.handle then
			var_0_2.unscheduleGlobal(arg_10_0.handle)

			arg_10_0.handle = nil
		end

		arg_10_0.onEnd = true

		arg_10_0:endGame()

		return
	end

	if arg_10_0.isPause then
		return
	end

	local var_10_0 = 0.01
	local var_10_1 = arg_10_0.newNode
	local var_10_2 = arg_10_0:nodeByName("gouzi_container")
	local var_10_3 = cc.p(arg_10_0.newNode:getPosition())

	if not arg_10_0.isPause then
		if arg_10_0.move then
			if var_10_3.x < 0 or var_10_3.x > 1280 or var_10_3.y < 0 then
				arg_10_0.down = 1

				arg_10_0.effects.partner:play(nil, true, nil, "idle_up")
			end

			if arg_10_0.down == 1 then
				if not arg_10_0.changeSpeed then
					arg_10_0.moveSpeed = arg_10_0:changeMoveSpeed(var_0_15)
				end
			else
				arg_10_0.moveSpeed = arg_10_0:changeMoveSpeed(var_0_16)
			end

			arg_10_0.moveTime = arg_10_0.moveTime + 1

			local var_10_4 = math.sin(math.rad(arg_10_0.angle))
			local var_10_5 = math.cos(math.rad(arg_10_0.angle))
			local var_10_6 = var_10_4 * arg_10_0.moveSpeed
			local var_10_7 = var_10_5 * arg_10_0.moveSpeed

			if var_10_3.y + arg_10_0.down * var_10_7 < arg_10_0.originalPos.y then
				var_10_1:runActionOnce(cc.MoveBy:create(var_10_0, cc.p(arg_10_0.down * var_10_6, arg_10_0.down * var_10_7)))
				var_10_2:runActionOnce(cc.MoveBy:create(var_10_0, cc.p(arg_10_0.down * var_10_6, arg_10_0.down * var_10_7)))

				if arg_10_0.nowGetItem ~= 0 and not arg_10_0.getItem[arg_10_0.nowGetItem] then
					arg_10_0.item[arg_10_0.nowGetItem]:setLocalZOrder(200 + arg_10_0.nowGetItem)
					arg_10_0.item[arg_10_0.nowGetItem]:runActionOnce(cc.MoveBy:create(var_10_0, cc.p(arg_10_0.down * var_10_6, arg_10_0.down * var_10_7)))
				end

				var_10_3 = cc.p(arg_10_0.newNode:getPosition())
			else
				var_10_1:stopAllActions()
				var_10_1:setPosition(cc.p(arg_10_0.originalPos.x, arg_10_0.originalPos.y))
				var_10_2:stopAllActions()
				var_10_2:setPosition(cc.p(arg_10_0.originalPos.x, arg_10_0.originalPos.y))

				var_10_3 = cc.p(arg_10_0.newNode:getPosition())

				if arg_10_0.nowGetItem ~= 0 and not arg_10_0.getItem[arg_10_0.nowGetItem] then
					arg_10_0.item[arg_10_0.nowGetItem]:setVisible(false)
					arg_10_0.item[arg_10_0.nowGetItem]:stopAllActions()
					arg_10_0:nodeByName("gouzi_container"):getChildByName("gou_left"):setRotation(30)
					arg_10_0:nodeByName("gouzi_container"):getChildByName("gou_right"):setRotation(-30)
					arg_10_0:updatePoint(arg_10_0.itemType[arg_10_0.nowGetItem])

					arg_10_0.getItem[arg_10_0.nowGetItem] = true
				end

				arg_10_0.move = false
				arg_10_0.down = -1

				arg_10_0.effects.partner:play(nil, true, nil, "idle")

				arg_10_0.changeSpeed = false

				if arg_10_0.angle <= 0 then
					arg_10_0.angle = -1 * var_0_13
				else
					arg_10_0.angle = var_0_13
				end

				var_10_1:runAction(cc.Sequence:create({
					cc.RotateTo:create(var_10_0, arg_10_0.angle)
				}))
				var_10_2:runAction(cc.Sequence:create({
					cc.RotateTo:create(var_10_0, arg_10_0.angle)
				}))
			end

			local var_10_8 = 40
			local var_10_9 = 48
			local var_10_10 = 14
			local var_10_11 = math.floor(var_10_3.x - var_10_4 * var_10_8)
			local var_10_12 = math.floor(var_10_3.y - var_10_5 * var_10_8)
			local var_10_13 = math.floor(var_10_3.x + var_10_5 * var_10_10 - var_10_4 * var_10_8)
			local var_10_14 = math.floor(var_10_3.y + var_10_4 * var_10_10 - var_10_5 * var_10_8)
			local var_10_15 = math.floor(var_10_3.x - var_10_5 * var_10_10 - var_10_4 * var_10_8)
			local var_10_16 = math.floor(var_10_3.y - var_10_4 * var_10_10 - var_10_5 * var_10_8)
			local var_10_17 = math.floor(var_10_3.x - var_10_4 * var_10_9)
			local var_10_18 = math.floor(var_10_3.y - var_10_5 * var_10_9)
			local var_10_19 = math.floor(var_10_3.x + var_10_5 * var_10_10 - var_10_4 * var_10_9)
			local var_10_20 = math.floor(var_10_3.y + var_10_4 * var_10_10 - var_10_5 * var_10_9)
			local var_10_21 = math.floor(var_10_3.x - var_10_5 * var_10_10 - var_10_4 * var_10_9)
			local var_10_22 = math.floor(var_10_3.y - var_10_4 * var_10_10 - var_10_5 * var_10_9)

			if var_10_3.x >= 0 and var_10_3.x <= 1280 and var_10_3.y >= 0 and arg_10_0.down == -1 and (arg_10_0.map[var_10_11][var_10_12] > 0 or arg_10_0.map[var_10_13][var_10_14] > 0 or arg_10_0.map[var_10_15][var_10_16] > 0 or arg_10_0.map[var_10_17][var_10_18] > 0 or arg_10_0.map[var_10_19][var_10_20] > 0 or arg_10_0.map[var_10_21][var_10_22] > 0) then
				arg_10_0.nowGetItem = math.max(arg_10_0.map[var_10_11][var_10_12], arg_10_0.map[var_10_13][var_10_14], arg_10_0.map[var_10_15][var_10_16], arg_10_0.map[var_10_17][var_10_18], arg_10_0.map[var_10_19][var_10_20], arg_10_0.map[var_10_21][var_10_22])

				if not arg_10_0.getItem[arg_10_0.nowGetItem] then
					arg_10_0.down = 1

					arg_10_0.item[arg_10_0.nowGetItem]:setRotation(arg_10_0.angle)
					arg_10_0.item[arg_10_0.nowGetItem]:setPosition(cc.p(var_10_3.x - (arg_10_0.itemHeight[arg_10_0.itemType[arg_10_0.nowGetItem]] + 60) * var_10_4, var_10_3.y - (arg_10_0.itemHeight[arg_10_0.itemType[arg_10_0.nowGetItem]] + 60) * var_10_5))
					arg_10_0.item[arg_10_0.nowGetItem]:setLocalZOrder(200 + arg_10_0.nowGetItem)
					arg_10_0:nodeByName("gouzi_container"):getChildByName("gou_left"):setRotation(10)
					arg_10_0:nodeByName("gouzi_container"):getChildByName("gou_right"):setRotation(-10)
					arg_10_0.effects.partner:play(nil, true, nil, "idle_up")

					arg_10_0.changeSpeed = true

					local var_10_23 = #arg_10_0.itemSpeed[arg_10_0.itemType[arg_10_0.nowGetItem]]

					if var_10_23 == 1 then
						arg_10_0.moveSpeed = arg_10_0:changeMoveSpeed(arg_10_0.itemSpeed[arg_10_0.itemType[arg_10_0.nowGetItem]][1])
					else
						local var_10_24 = math.random(1, var_10_23)

						arg_10_0.moveSpeed = arg_10_0:changeMoveSpeed(arg_10_0.itemSpeed[arg_10_0.itemType[arg_10_0.nowGetItem]][var_10_24])
					end
				end
			end
		else
			if arg_10_0.angle < -1 * var_0_13 then
				arg_10_0.rotateFace = var_0_14
			end

			if arg_10_0.angle > var_0_13 then
				arg_10_0.rotateFace = -1 * var_0_14
			end

			arg_10_0.angle = arg_10_0.angle + arg_10_0.rotateFace

			var_10_1:runAction(cc.Sequence:create({
				cc.RotateTo:create(var_10_0, arg_10_0.angle)
			}))
			var_10_2:runAction(cc.Sequence:create({
				cc.RotateTo:create(var_10_0, arg_10_0.angle)
			}))
		end

		arg_10_0.totalCount = arg_10_0.totalCount + 1

		arg_10_0:updateTime(arg_10_0.totalCount)
	end
end

function var_0_0.updatePoint(arg_11_0, arg_11_1)
	arg_11_0.notEnd = true

	local var_11_0 = var_0_5:price(arg_11_1)
	local var_11_1 = 0
	local var_11_2 = 1

	if var_11_0 >= 0 then
		var_11_1 = var_11_0
		var_11_2 = 1
	else
		local var_11_3 = math.random(1, #arg_11_0.rates)

		if arg_11_0.rates[var_11_3] == 1 then
			arg_11_0.bombNum = arg_11_0.bombNum + 1
			var_11_2 = 3
		elseif arg_11_0.rates[var_11_3] == 2 then
			arg_11_0.clockNum = arg_11_0.clockNum + 1
			var_11_2 = 4
		elseif arg_11_0.rates[var_11_3] == 3 then
			arg_11_0.goldenNum = arg_11_0.goldenNum + 1
			var_11_2 = 2
		else
			var_11_1 = var_0_8:num(arg_11_0.rates[var_11_3])
		end
	end

	arg_11_0:nodeByName("point_txt"):setString("+" .. var_11_1)
	arg_11_0:nodeByName("item_txt"):setString("+1")

	local var_11_4
	local var_11_5

	if var_11_2 == 1 then
		var_11_4 = arg_11_0:nodeByName("point_container")
		var_11_5 = arg_11_0:nodeByName("target_pos1")
	elseif var_11_2 == 2 then
		var_11_4 = arg_11_0:nodeByName("item_container")
		var_11_5 = arg_11_0:nodeByName("target_pos2")

		arg_11_0:nodeByName("golden_water_show"):setVisible(true)
		arg_11_0:nodeByName("bomb_show"):setVisible(false)
		arg_11_0:nodeByName("clock_show"):setVisible(false)
	elseif var_11_2 == 3 then
		var_11_4 = arg_11_0:nodeByName("item_container")
		var_11_5 = arg_11_0:nodeByName("target_pos3")

		arg_11_0:nodeByName("golden_water_show"):setVisible(false)
		arg_11_0:nodeByName("bomb_show"):setVisible(true)
		arg_11_0:nodeByName("clock_show"):setVisible(false)
	elseif var_11_2 == 4 then
		var_11_4 = arg_11_0:nodeByName("item_container")
		var_11_5 = arg_11_0:nodeByName("target_pos4")

		arg_11_0:nodeByName("golden_water_show"):setVisible(false)
		arg_11_0:nodeByName("bomb_show"):setVisible(false)
		arg_11_0:nodeByName("clock_show"):setVisible(true)
	end

	var_11_4:setVisible(true)

	local var_11_6 = cc.p(var_11_4:getPosition())
	local var_11_7 = cc.p(var_11_5:getPosition())

	var_11_4:pos(var_11_6.x, var_11_6.y)
	var_11_4:scale(1)
	var_11_4:runAction(cc.Sequence:create({
		cc.DelayTime:create(var_0_20 * 1),
		cc.Spawn:create({
			cc.MoveBy:create(var_0_18, cc.p(0, var_0_17)),
			cc.FadeIn:create(var_0_18)
		}),
		cc.DelayTime:create(var_0_18),
		cc.Spawn:create({
			cc.ScaleTo:create(var_0_19, 0.3),
			cc.MoveTo:create(var_0_19, cc.p(var_11_7.x, var_11_7.y))
		}),
		cc.CallFunc:create(function()
			var_11_4:setVisible(false)
			var_11_4:setPosition(var_11_6.x, var_11_6.y)

			arg_11_0.notEnd = false

			arg_11_0:addPoint(var_11_1)
		end)
	}))
end

function var_0_0.addPoint(arg_13_0, arg_13_1)
	arg_13_0.point = arg_13_0.point + arg_13_1

	arg_13_0:nodeByName("money_txt"):setString(arg_13_0.point)
	arg_13_0:nodeByName("golden_num"):setString(arg_13_0.goldenNum)
	arg_13_0:nodeByName("bomb_num"):setString(arg_13_0.bombNum)
	arg_13_0:nodeByName("clock_num"):setString(arg_13_0.clockNum)
end

function var_0_0.initEffect(arg_14_0)
	local var_14_0 = arg_14_0:nodeByName("container")

	arg_14_0.newNode = arg_14_0:clipRollContainer(var_14_0)

	arg_14_0.newNode:setVisible(false)

	if not arg_14_0.effects.partner then
		local var_14_1 = arg_14_0:getEffect("guangjinkuanggong")

		var_14_1:addTo(arg_14_0:nodeByName("partner_pos"))
		var_14_1:play(nil, true)
		var_14_1:setPosition(cc.p(0, 0))
		var_14_1:setScale(0.6)

		arg_14_0.effects.partner = var_14_1

		arg_14_0.effects.partner:play(nil, true, nil, "idle")
		arg_14_0.effects.partner:setLocalZOrder(300)
		arg_14_0.newNode:setLocalZOrder(301)
		arg_14_0:nodeByName("gouzi_container"):setLocalZOrder(302)

		local var_14_2 = arg_14_0:getEffect("boom")

		var_14_2:addTo(arg_14_0:nodeByName("boom_pos"))
		var_14_2:setPosition(cc.p(0, 0))
		var_14_2:play(nil, true)
		var_14_2:setVisible(false)

		arg_14_0.effects.partner.boomEffect = var_14_2

		local var_14_3 = arg_14_0:getEffect("change")

		var_14_3:addTo(arg_14_0:nodeByName("boom_pos"))
		var_14_3:setPosition(cc.p(0, 0))
		var_14_3:play(nil, true)
		var_14_3:setVisible(false)

		arg_14_0.effects.partner.changeEffect = var_14_3
	end
end

function var_0_0.clipRollContainer(arg_15_0, arg_15_1)
	local var_15_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary4th/gold_catch/gouzi.csb")

	var_15_0:setAnchorPoint(cc.p(0.5, 0.075))
	var_15_0:setPosition(cc.p(639.5, 607))

	local var_15_1 = xyd.AssetLoader:get():loadSprite("windows/anniversary4th/gold_catch/shadow1.png")

	var_15_1:setAnchorPoint(cc.p(0, 0))
	var_15_1:setPosition(cc.p(0, 607))

	local var_15_2 = cc.ClippingNode:create()

	var_15_2:setStencil(var_15_1)
	var_15_2:setInverted(true)
	var_15_2:setAlphaThreshold(0)
	arg_15_1:addChild(var_15_2)
	var_15_2:setPosition(cc.p(0, 0))
	var_15_2:setAnchorPoint(cc.p(0, 0))
	var_15_2:addChild(var_15_0)

	return var_15_0
end

function var_0_0.checkMap(arg_16_0)
	arg_16_0.originalPos = cc.p(arg_16_0:nodeByName("gouzi_pos"):getPosition())

	arg_16_0:updateTime(0)

	arg_16_0.getItem = {}

	arg_16_0:nodeByName("gouzi_container"):stopAllActions()
	arg_16_0.newNode:stopAllActions()
	arg_16_0:nodeByName("gouzi_container"):setPosition(arg_16_0.originalPos)
	arg_16_0:nodeByName("gouzi_container"):setRotation(arg_16_0.angle)
	arg_16_0:nodeByName("gouzi_container"):setVisible(true)
	arg_16_0.newNode:setPosition(arg_16_0.originalPos)
	arg_16_0.newNode:setRotation(arg_16_0.angle)
	arg_16_0.newNode:setVisible(true)
	arg_16_0:nodeByName("money_txt"):setString(arg_16_0.point)
	arg_16_0:nodeByName("score_txt"):setString(arg_16_0.levelStage[arg_16_0.nowLev])
	arg_16_0:nodeByName("control_btn"):setBright(true)
	arg_16_0:nodeByName("control_btn"):setTouchEnabled(true)
	arg_16_0:nodeByName("golden_num"):setString(arg_16_0.goldenNum)
	arg_16_0:nodeByName("bomb_num"):setString(arg_16_0.bombNum)
	arg_16_0:nodeByName("clock_num"):setString(arg_16_0.clockNum)
	arg_16_0:nodeByName("level_txt"):setString(arg_16_0.nowLev)

	if arg_16_0.btType == 1 then
		arg_16_0:nodeByName("level_txt"):setString(arg_16_0.nowLev .. "/" .. arg_16_0.levelNum)
	end

	arg_16_0:nodeByName("control_btn"):setBright(true)
	arg_16_0:nodeByName("pause"):setVisible(false)
	arg_16_0:nodeByName("continue"):setVisible(true)

	arg_16_0.map = {}

	for iter_16_0 = -100, 1380 do
		arg_16_0.map[iter_16_0] = {}

		for iter_16_1 = -100, -1 do
			arg_16_0.map[iter_16_0][iter_16_1] = -1
		end
	end

	for iter_16_2 = 0, 1280 do
		for iter_16_3 = 0, 720 do
			arg_16_0.map[iter_16_2][iter_16_3] = 0
		end
	end

	for iter_16_4 = -100, -1 do
		for iter_16_5 = 0, 720 do
			arg_16_0.map[iter_16_4][iter_16_5] = -1
		end
	end

	for iter_16_6 = 1280, 1380 do
		for iter_16_7 = 0, 720 do
			arg_16_0.map[iter_16_6][iter_16_7] = -1
		end
	end

	if arg_16_0.getInfo then
		for iter_16_8 = -1000, 2380 do
			arg_16_0.map[iter_16_8] = {}

			for iter_16_9 = -100, -1 do
				arg_16_0.map[iter_16_8][iter_16_9] = -1
			end
		end

		for iter_16_10 = 0, 1280 do
			for iter_16_11 = 0, 720 do
				arg_16_0.map[iter_16_10][iter_16_11] = 0
			end
		end
	end

	local var_16_0 = {}
	local var_16_1 = 1
	local var_16_2 = {}

	if arg_16_0.btType == 1 then
		var_16_2 = var_0_6:mapSequence(arg_16_0.nowLev)
	else
		var_16_2 = var_0_7:mapSequence(arg_16_0.nowLev)
	end

	local var_16_3 = #var_16_2
	local var_16_4 = var_16_2[math.random(1, var_16_3)]

	var_16_0[arg_16_0.nowLev] = arg_16_0.allMap[var_16_4]
	arg_16_0.item = {}
	arg_16_0.itemType = {}

	local var_16_5 = 1
	local var_16_6 = 1

	arg_16_0.randomPos = {}

	for iter_16_12 = 1, 80 do
		arg_16_0.randomPos[iter_16_12] = {}
	end

	for iter_16_13 = 1, 80 do
		if arg_16_0.getInfo then
			arg_16_0.types[iter_16_13] = math.floor((iter_16_13 - 1) / 10) + 1
		end
	end

	for iter_16_14 = 1, 80 do
		if arg_16_0.getInfo then
			local var_16_7 = arg_16_0.types[iter_16_14]
			local var_16_8 = iter_16_14 - math.floor(iter_16_14 / 10) * 10

			if var_16_8 == 0 then
				var_16_8 = 10
			end

			local var_16_9 = arg_16_0:getItemName(var_16_7, var_16_8)

			arg_16_0.item[var_16_5] = arg_16_0:nodeByName(var_16_9)
			arg_16_0.itemType[var_16_5] = var_16_7
			var_16_5 = var_16_5 + 1
		elseif var_16_0[arg_16_0.nowLev][iter_16_14] then
			local var_16_10 = arg_16_0.types[iter_16_14]
			local var_16_11 = iter_16_14 - math.floor(iter_16_14 / 10) * 10
			local var_16_12 = arg_16_0:getItemName(var_16_10, var_16_11)

			arg_16_0.item[var_16_5] = arg_16_0:nodeByName(var_16_12)

			arg_16_0.item[var_16_5]:setLocalZOrder(100 + var_16_5)

			arg_16_0.itemType[var_16_5] = var_16_10

			local var_16_13 = #var_16_0[arg_16_0.nowLev][iter_16_14]

			if var_16_0[arg_16_0.nowLev][iter_16_14][1] > 0 then
				if var_16_13 == 2 then
					arg_16_0.item[var_16_5]:setPosition(cc.p(var_16_0[arg_16_0.nowLev][iter_16_14][1], var_16_0[arg_16_0.nowLev][iter_16_14][2]))
					arg_16_0.item[var_16_5]:setRotation(0)
				else
					local var_16_14 = math.random(1, var_16_13 / 2)

					arg_16_0.item[var_16_5]:setPosition(cc.p(var_16_0[arg_16_0.nowLev][iter_16_14][var_16_14 * 2 - 1], var_16_0[arg_16_0.nowLev][iter_16_14][var_16_14 * 2]))
					arg_16_0.item[var_16_5]:setRotation(0)
				end

				var_16_5 = var_16_5 + 1
			elseif var_16_0[arg_16_0.nowLev][iter_16_14][1] == 0 then
				local var_16_15 = math.abs(var_16_0[arg_16_0.nowLev][iter_16_14][2])

				if #arg_16_0.randomPos[var_16_15] <= 0 then
					for iter_16_15 = 3, #var_16_0[arg_16_0.nowLev][iter_16_14] do
						arg_16_0.randomPos[var_16_15][iter_16_15 - 2] = var_16_0[arg_16_0.nowLev][iter_16_14][iter_16_15]
					end
				end

				local var_16_16 = #arg_16_0.randomPos[var_16_15]
				local var_16_17 = math.random(1, var_16_16 / 2)

				arg_16_0.item[var_16_5]:setPosition(cc.p(arg_16_0.randomPos[var_16_15][var_16_17 * 2 - 1], arg_16_0.randomPos[var_16_15][var_16_17 * 2]))
				table.remove(arg_16_0.randomPos[var_16_15], var_16_17 * 2 - 1)
				table.remove(arg_16_0.randomPos[var_16_15], var_16_17 * 2 - 1)
				arg_16_0.item[var_16_5]:setRotation(0)

				var_16_5 = var_16_5 + 1
			end
		end
	end

	for iter_16_16 = 1, #arg_16_0.item do
		arg_16_0.item[iter_16_16]:setVisible(true)
	end

	arg_16_0.itemNum = #arg_16_0.item
	arg_16_0.itemposx = {}
	arg_16_0.itemposy = {}

	local var_16_18 = {}
	local var_16_19 = var_0_9:pos(1)
	local var_16_20 = var_0_9:pos(2)
	local var_16_21 = var_0_9:pos(3)
	local var_16_22 = var_0_9:pos(4)
	local var_16_23 = var_0_9:pos(5)
	local var_16_24 = var_0_9:pos(6)
	local var_16_25 = var_0_9:pos(7)
	local var_16_26 = var_0_9:pos(8)
	local var_16_27 = var_0_9:pos(9)
	local var_16_28 = var_0_9:pos(10)
	local var_16_29 = var_0_9:pos(11)
	local var_16_30 = var_0_9:pos(12)
	local var_16_31 = var_0_9:pos(13)
	local var_16_32 = var_0_9:pos(14)

	for iter_16_17 = 1, arg_16_0.itemNum do
		arg_16_0.itemposx[iter_16_17] = arg_16_0.item[iter_16_17]:getPositionX()
		arg_16_0.itemposy[iter_16_17] = arg_16_0.item[iter_16_17]:getPositionY()

		if arg_16_0.itemType[iter_16_17] == 1 then
			for iter_16_18 = 1, #var_16_19 / 2 do
				var_16_18[1] = math.ceil(var_16_19[iter_16_18 * 2 - 1] + arg_16_0.itemposx[iter_16_17])
				var_16_18[2] = math.ceil(var_16_19[iter_16_18 * 2] + arg_16_0.itemposy[iter_16_17])
				arg_16_0.map[var_16_18[1]][var_16_18[2]] = iter_16_17
			end

			for iter_16_19 = 1, #var_16_20 / 2 do
				var_16_18[1] = math.ceil(var_16_20[iter_16_19 * 2 - 1] + arg_16_0.itemposx[iter_16_17])
				var_16_18[2] = math.ceil(var_16_20[iter_16_19 * 2] + arg_16_0.itemposy[iter_16_17])
				arg_16_0.map[var_16_18[1]][var_16_18[2]] = iter_16_17
			end

			for iter_16_20 = 1, #var_16_21 / 2 do
				var_16_18[1] = math.ceil(var_16_21[iter_16_20 * 2 - 1] + arg_16_0.itemposx[iter_16_17])
				var_16_18[2] = math.ceil(var_16_21[iter_16_20 * 2] + arg_16_0.itemposy[iter_16_17])
				arg_16_0.map[var_16_18[1]][var_16_18[2]] = iter_16_17
			end
		elseif arg_16_0.itemType[iter_16_17] == 2 then
			for iter_16_21 = 1, #var_16_25 / 2 do
				var_16_18[1] = math.ceil(var_16_25[iter_16_21 * 2 - 1] + arg_16_0.itemposx[iter_16_17])
				var_16_18[2] = math.ceil(var_16_25[iter_16_21 * 2] + arg_16_0.itemposy[iter_16_17])
				arg_16_0.map[var_16_18[1]][var_16_18[2]] = iter_16_17
			end

			for iter_16_22 = 1, #var_16_26 / 2 do
				var_16_18[1] = math.ceil(var_16_26[iter_16_22 * 2 - 1] + arg_16_0.itemposx[iter_16_17])
				var_16_18[2] = math.ceil(var_16_26[iter_16_22 * 2] + arg_16_0.itemposy[iter_16_17])
				arg_16_0.map[var_16_18[1]][var_16_18[2]] = iter_16_17
			end
		elseif arg_16_0.itemType[iter_16_17] == 3 then
			for iter_16_23 = 1, #var_16_29 / 2 do
				var_16_18[1] = math.ceil(var_16_29[iter_16_23 * 2 - 1] + arg_16_0.itemposx[iter_16_17])
				var_16_18[2] = math.ceil(var_16_29[iter_16_23 * 2] + arg_16_0.itemposy[iter_16_17])
				arg_16_0.map[var_16_18[1]][var_16_18[2]] = iter_16_17
			end
		elseif arg_16_0.itemType[iter_16_17] == 4 then
			for iter_16_24 = 1, #var_16_22 / 2 do
				var_16_18[1] = math.ceil(var_16_22[iter_16_24 * 2 - 1] + arg_16_0.itemposx[iter_16_17])
				var_16_18[2] = math.ceil(var_16_22[iter_16_24 * 2] + arg_16_0.itemposy[iter_16_17])
				arg_16_0.map[var_16_18[1]][var_16_18[2]] = iter_16_17
			end

			for iter_16_25 = 1, #var_16_23 / 2 do
				var_16_18[1] = math.ceil(var_16_23[iter_16_25 * 2 - 1] + arg_16_0.itemposx[iter_16_17])
				var_16_18[2] = math.ceil(var_16_23[iter_16_25 * 2] + arg_16_0.itemposy[iter_16_17])
				arg_16_0.map[var_16_18[1]][var_16_18[2]] = iter_16_17
			end

			for iter_16_26 = 1, #var_16_24 / 2 do
				var_16_18[1] = math.ceil(var_16_24[iter_16_26 * 2 - 1] + arg_16_0.itemposx[iter_16_17])
				var_16_18[2] = math.ceil(var_16_24[iter_16_26 * 2] + arg_16_0.itemposy[iter_16_17])
				arg_16_0.map[var_16_18[1]][var_16_18[2]] = iter_16_17
			end
		elseif arg_16_0.itemType[iter_16_17] == 5 then
			for iter_16_27 = 1, #var_16_27 / 2 do
				var_16_18[1] = math.ceil(var_16_27[iter_16_27 * 2 - 1] + arg_16_0.itemposx[iter_16_17])
				var_16_18[2] = math.ceil(var_16_27[iter_16_27 * 2] + arg_16_0.itemposy[iter_16_17])
				arg_16_0.map[var_16_18[1]][var_16_18[2]] = iter_16_17
			end

			for iter_16_28 = 1, #var_16_28 / 2 do
				var_16_18[1] = math.ceil(var_16_28[iter_16_28 * 2 - 1] + arg_16_0.itemposx[iter_16_17])
				var_16_18[2] = math.ceil(var_16_28[iter_16_28 * 2] + arg_16_0.itemposy[iter_16_17])
				arg_16_0.map[var_16_18[1]][var_16_18[2]] = iter_16_17
			end
		elseif arg_16_0.itemType[iter_16_17] == 6 then
			for iter_16_29 = 1, #var_16_30 / 2 do
				var_16_18[1] = math.ceil(var_16_30[iter_16_29 * 2 - 1] + arg_16_0.itemposx[iter_16_17])
				var_16_18[2] = math.ceil(var_16_30[iter_16_29 * 2] + arg_16_0.itemposy[iter_16_17])
				arg_16_0.map[var_16_18[1]][var_16_18[2]] = iter_16_17
			end
		elseif arg_16_0.itemType[iter_16_17] == 7 then
			for iter_16_30 = 1, #var_16_32 / 2 do
				var_16_18[1] = math.ceil(var_16_32[iter_16_30 * 2 - 1] + arg_16_0.itemposx[iter_16_17])
				var_16_18[2] = math.ceil(var_16_32[iter_16_30 * 2] + arg_16_0.itemposy[iter_16_17])
				arg_16_0.map[var_16_18[1]][var_16_18[2]] = iter_16_17
			end
		elseif arg_16_0.itemType[iter_16_17] == 8 then
			for iter_16_31 = 1, #var_16_31 / 2 do
				var_16_18[1] = math.ceil(var_16_31[iter_16_31 * 2 - 1] + arg_16_0.itemposx[iter_16_17])
				var_16_18[2] = math.ceil(var_16_31[iter_16_31 * 2] + arg_16_0.itemposy[iter_16_17])
				arg_16_0.map[var_16_18[1]][var_16_18[2]] = iter_16_17
			end
		end
	end

	for iter_16_32 = 1, arg_16_0.itemNum do
		arg_16_0.getItem[iter_16_32] = false
	end
end

function var_0_0.getItemName(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = ""

	if arg_17_1 == 1 then
		var_17_0 = tostring("gold_big_" .. arg_17_2)
	elseif arg_17_1 == 2 then
		var_17_0 = tostring("gold_middle_" .. arg_17_2)
	elseif arg_17_1 == 3 then
		var_17_0 = tostring("gold_small_" .. arg_17_2)
	elseif arg_17_1 == 4 then
		var_17_0 = tostring("stone_big_" .. arg_17_2)
	elseif arg_17_1 == 5 then
		var_17_0 = tostring("stone_middle_" .. arg_17_2)
	elseif arg_17_1 == 6 then
		var_17_0 = tostring("stone_small_" .. arg_17_2)
	elseif arg_17_1 == 7 then
		var_17_0 = tostring("zuanshi_" .. arg_17_2)
	elseif arg_17_1 == 8 then
		var_17_0 = tostring("bag_" .. arg_17_2)
	end

	return var_17_0
end

function var_0_0.pauseAll(arg_18_0)
	if arg_18_0.pauseTime % 2 == 1 then
		arg_18_0.isPause = true
	elseif arg_18_0.isPause then
		arg_18_0.isPause = false
	else
		arg_18_0.isPause = true
	end

	if arg_18_0.pauseTime <= 0 then
		arg_18_0:nodeByName("control_btn"):setTouchEnabled(false)
	end

	if arg_18_0.pauseTime == 0 then
		if arg_18_0.isPause then
			arg_18_0:nodeByName("control_btn"):setBright(true)
		else
			arg_18_0:nodeByName("control_btn"):setBright(false)
		end
	end

	if arg_18_0.pauseTime % 2 == 1 then
		arg_18_0:nodeByName("control_btn"):setBright(true)
	end

	arg_18_0:nodeByName("pause"):setVisible(arg_18_0.isPause)
	arg_18_0:nodeByName("continue"):setVisible(not arg_18_0.isPause)
end

function var_0_0.willClose(arg_19_0, arg_19_1)
	var_0_0.super.willClose(arg_19_0, arg_19_1)

	if arg_19_0.handle then
		var_0_2.unscheduleGlobal(arg_19_0.handle)

		arg_19_0.handle = nil
	end

	cc.Director:getInstance():purgeCachedData()
end

function var_0_0.endGame(arg_20_0)
	if arg_20_0.onEnd or arg_20_0.point < arg_20_0.levelStage[arg_20_0.nowLev] then
		arg_20_0.isPause = true

		local var_20_0 = {
			score = arg_20_0.point
		}

		if arg_20_0.btType == 2 then
			var_20_0.wave_nums = arg_20_0.nowLev - 1
		end

		arg_20_0.annifourth:fourthAnniGoldEnd(var_20_0, function(arg_21_0, arg_21_1)
			arg_20_0.onEnd = false

			if arg_21_0 == xyd.error.OK then
				var_20_0.bt_type = arg_20_0.btType
				var_20_0.score = arg_21_1.score
				var_20_0.wave_nums = arg_21_1.wave_nums or var_20_0.wave_nums
				var_20_0.awards = arg_21_1.awards

				xyd.WindowManager.get():openWindow("gold_result", var_20_0)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("NET_WORK_ERROR_TEXT")
				})
				xyd.WindowManager.get():closeWindow(arg_20_0)
			end
		end)
	else
		arg_20_0:goToNextLevel()
	end
end

function var_0_0.updateTime(arg_22_0, arg_22_1)
	if arg_22_1 < 0 then
		arg_22_1 = 0
	end

	local var_22_0 = math.max(0, var_0_3 - math.ceil(arg_22_1 / var_0_10))

	arg_22_0:nodeByName("time_txt"):setString(xyd.secondsToString(var_22_0))
end

function var_0_0.addTouchArena(arg_23_0)
	arg_23_0:nodeByName("asset_container4"):setLocalZOrder(1001)
	arg_23_0:nodeByName("asset_container4"):setTouchSwallowEnabled(true)

	local var_23_0 = display.newNode()

	var_23_0:setName("touchNode")
	var_23_0:setContentSize(1180, 580)
	var_23_0:setAnchorPoint(cc.p(0, 0))
	var_23_0:setTouchEnabled(true)
	var_23_0:addTo(arg_23_0:nodeByName("container"))
	var_23_0:setLocalZOrder(1000)
	var_23_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_24_0)
		if arg_24_0.name == "began" and not arg_23_0.onEnd and not arg_23_0.move then
			if not arg_23_0.isPause then
				arg_23_0.move = true

				arg_23_0.effects.partner:play(nil, false, nil, "idle_down")
			end
		elseif arg_24_0.name == "moved" then
			-- block empty
		elseif arg_24_0.name == "ended" then
			-- block empty
		end
	end)

	local var_23_1 = display.newNode()

	var_23_1:setName("touchNode1")
	var_23_1:setContentSize(100, 205)
	var_23_1:setAnchorPoint(cc.p(0, 0))
	var_23_1:setPosition(cc.p(1180, 0))
	var_23_1:setTouchEnabled(true)
	var_23_1:addTo(arg_23_0:nodeByName("container"))
	var_23_1:setLocalZOrder(1000)
	var_23_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_25_0)
		if arg_25_0.name == "began" and not arg_23_0.onEnd and not arg_23_0.move then
			dump(22)

			if not arg_23_0.isPause then
				arg_23_0.move = true

				arg_23_0.effects.partner:play(nil, false, nil, "idle_down")
			end
		elseif arg_25_0.name == "moved" then
			-- block empty
		elseif arg_25_0.name == "ended" then
			-- block empty
		end
	end)
	arg_23_0:nodeByName("golden_water"):setTouchEnabled(true)
	arg_23_0:nodeByName("golden_water"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_26_0)
		if arg_26_0.name == "began" then
			if arg_23_0.goldenNum > 0 then
				arg_23_0:nodeByName("golden_water"):setScale(0.9)
				arg_23_0:changeStone()
				arg_23_0:nodeByName("golden_num"):setString(arg_23_0.goldenNum)
			end

			return true
		elseif arg_26_0.name == "moved" then
			arg_23_0:nodeByName("golden_water"):setScale(1)
		elseif arg_26_0.name == "ended" then
			arg_23_0:nodeByName("golden_water"):setScale(1)
		end
	end)
	arg_23_0:nodeByName("bomb"):setTouchEnabled(true)
	arg_23_0:nodeByName("bomb"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_27_0)
		if arg_27_0.name == "began" then
			if arg_23_0.bombNum > 0 then
				arg_23_0:nodeByName("bomb"):setScale(0.9)

				if arg_23_0.nowGetItem ~= 0 and not arg_23_0.getItem[arg_23_0.nowGetItem] then
					arg_23_0.bombNum = arg_23_0.bombNum - 1

					arg_23_0.item[arg_23_0.nowGetItem]:setVisible(false)
					arg_23_0.item[arg_23_0.nowGetItem]:stopAllActions()
					arg_23_0:nodeByName("gouzi_container"):getChildByName("gou_left"):setRotation(30)
					arg_23_0:nodeByName("gouzi_container"):getChildByName("gou_right"):setRotation(-30)

					arg_23_0.getItem[arg_23_0.nowGetItem] = true
					arg_23_0.moveSpeed = arg_23_0:changeMoveSpeed(var_0_15)
					nowPos = cc.p(arg_23_0.item[arg_23_0.nowGetItem]:getPosition())

					arg_23_0.effects.partner.boomEffect:setVisible(true)
					arg_23_0.effects.partner.boomEffect:setPosition(cc.p(nowPos.x, nowPos.y))
					arg_23_0.effects.partner.boomEffect:play(nil, false, nil, "texiao")
					arg_23_0:nodeByName("bomb_num"):setString(arg_23_0.bombNum)
				end
			end

			return true
		elseif arg_27_0.name == "moved" then
			arg_23_0:nodeByName("bomb"):setScale(1)
		elseif arg_27_0.name == "ended" then
			arg_23_0:nodeByName("bomb"):setScale(1)
		end
	end)
	arg_23_0:nodeByName("clock"):setTouchEnabled(true)
	arg_23_0:nodeByName("clock"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_28_0)
		if arg_28_0.name == "began" then
			if arg_23_0.clockNum > 0 then
				arg_23_0:nodeByName("clock"):setScale(0.9)

				if not arg_23_0.speedUp then
					arg_23_0.clockNum = arg_23_0.clockNum - 1
					arg_23_0.speedUp = true
					arg_23_0.moveSpeed = arg_23_0:changeMoveSpeed(arg_23_0.moveSpeed)
				end

				arg_23_0:nodeByName("clock_num"):setString(arg_23_0.clockNum)
			end

			return true
		elseif arg_28_0.name == "moved" then
			arg_23_0:nodeByName("clock"):setScale(1)
		elseif arg_28_0.name == "ended" then
			arg_23_0:nodeByName("clock"):setScale(1)
		end
	end)
	arg_23_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_29_0, arg_29_1)
		xyd.buttonScaleAnim(arg_23_0:nodeByName("rule_btn"), arg_29_1)

		if arg_29_1 == ccui.TouchEventType.ended then
			arg_23_0:pauseAll()

			local function var_29_0()
				arg_23_0:pauseAll()
			end

			local var_29_1 = {
				callback = var_29_0
			}

			var_29_1.nowPage = 6

			xyd.WindowManager.get():openWindow("gold_graphic", var_29_1)
		end
	end)
	arg_23_0:nodeByName("next_btn"):setVisible(false)
	arg_23_0:nodeByName("next_btn"):addTouchEventListener(function(arg_31_0, arg_31_1)
		xyd.buttonScaleAnim(arg_23_0:nodeByName("next_btn"), arg_31_1)

		if arg_31_1 == ccui.TouchEventType.ended then
			arg_23_0:endGame()
		end
	end)
	arg_23_0:nodeByName("control_btn"):addTouchEventListener(function(arg_32_0, arg_32_1)
		xyd.buttonScaleAnim(arg_23_0:nodeByName("control_btn"), arg_32_1)

		if arg_32_1 == ccui.TouchEventType.ended and arg_23_0.pauseTime > 0 then
			arg_23_0.pauseTime = arg_23_0.pauseTime - 1

			arg_23_0:pauseAll()
		end
	end)
	arg_23_0:nodeByName("close"):addTouchEventListener(function(arg_33_0, arg_33_1)
		if arg_33_1 == ccui.TouchEventType.ended then
			arg_23_0:pauseAll()

			if not arg_23_0.handle then
				xyd.WindowManager.get():closeWindow(arg_23_0)

				return
			end

			local var_33_0 = var_0_1:translation("ACTIVITY_CHOCOLATE_FRUIT_EXIT")
			local var_33_1 = {}

			var_33_1.lcallback, var_33_1.title = function(...)
				arg_23_0:pauseAll()
			end, var_0_1:translation("TIP")
			var_33_1.showBegin = true

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
				var_33_0
			}, function()
				arg_23_0.forceEnd = true
			end, var_33_1, nil, xyd.ColorMode.ACTIVITY)
		end
	end)
end

function var_0_0.changeMoveSpeed(arg_36_0, arg_36_1)
	local var_36_0 = arg_36_1

	if arg_36_0.speedUp and arg_36_0.down == 1 and arg_36_0.nowGetItem ~= 0 then
		local var_36_1 = 1

		var_36_0 = var_36_0 * arg_36_0.speedMultiply[arg_36_0.itemType[arg_36_0.nowGetItem]]

		if var_36_0 > 25 then
			var_36_0 = 25
		end
	end

	return var_36_0
end

function var_0_0.changeStone(arg_37_0)
	if arg_37_0.nowGetItem ~= 0 and not arg_37_0.getItem[arg_37_0.nowGetItem] then
		nowPos = cc.p(arg_37_0.item[arg_37_0.nowGetItem]:getPosition())

		if arg_37_0.itemType[arg_37_0.nowGetItem] == 4 then
			arg_37_0.goldenNum = arg_37_0.goldenNum - 1
			arg_37_0.itemType[arg_37_0.nowGetItem] = 1

			arg_37_0.item[arg_37_0.nowGetItem]:setVisible(false)

			arg_37_0.item[arg_37_0.nowGetItem] = arg_37_0:nodeByName("gold_big")

			arg_37_0.item[arg_37_0.nowGetItem]:setPosition(cc.p(nowPos.x, nowPos.y))
			arg_37_0.item[arg_37_0.nowGetItem]:setVisible(true)
			arg_37_0.effects.partner.changeEffect:setPosition(cc.p(nowPos.x, nowPos.y))
			arg_37_0.effects.partner.changeEffect:setVisible(true)
			arg_37_0.effects.partner.changeEffect:play(nil, false, nil, "texiao")
		elseif arg_37_0.itemType[arg_37_0.nowGetItem] == 5 then
			arg_37_0.goldenNum = arg_37_0.goldenNum - 1
			arg_37_0.itemType[arg_37_0.nowGetItem] = 2

			arg_37_0.item[arg_37_0.nowGetItem]:setVisible(false)

			arg_37_0.item[arg_37_0.nowGetItem] = arg_37_0:nodeByName("gold_middle")

			arg_37_0.item[arg_37_0.nowGetItem]:setPosition(cc.p(nowPos.x, nowPos.y))
			arg_37_0.item[arg_37_0.nowGetItem]:setVisible(true)
			arg_37_0.effects.partner.changeEffect:setPosition(cc.p(nowPos.x, nowPos.y))
			arg_37_0.effects.partner.changeEffect:setVisible(true)
			arg_37_0.effects.partner.changeEffect:play(nil, false, nil, "texiao")
		elseif arg_37_0.itemType[arg_37_0.nowGetItem] == 6 then
			arg_37_0.goldenNum = arg_37_0.goldenNum - 1
			arg_37_0.itemType[arg_37_0.nowGetItem] = 3

			arg_37_0.item[arg_37_0.nowGetItem]:setVisible(false)

			arg_37_0.item[arg_37_0.nowGetItem] = arg_37_0:nodeByName("gold_small")

			arg_37_0.item[arg_37_0.nowGetItem]:setPosition(cc.p(nowPos.x, nowPos.y))
			arg_37_0.item[arg_37_0.nowGetItem]:setVisible(true)
			arg_37_0.effects.partner.changeEffect:setPosition(cc.p(nowPos.x, nowPos.y))
			arg_37_0.effects.partner.changeEffect:setVisible(true)
			arg_37_0.effects.partner.changeEffect:play(nil, false, nil, "texiao")
		end
	end
end

function var_0_0.speedUp(arg_38_0)
	arg_38_0.speedUp = true
end

function var_0_0.goToNextLevel(arg_39_0)
	if arg_39_0.nowLev >= arg_39_0.levelNum then
		arg_39_0.forceEnd = true

		return
	else
		collectgarbage("collect")

		arg_39_0.nowLev = arg_39_0.nowLev + 1

		if arg_39_0.handle then
			var_0_2.unscheduleGlobal(arg_39_0.handle)

			arg_39_0.handle = nil
		end

		arg_39_0:pauseAll()

		local function var_39_0(...)
			arg_39_0.isPause = false
		end

		local var_39_1 = {
			callback = var_39_0
		}

		var_39_1.is_next = true

		xyd.WindowManager.get():openWindow("gold_start", var_39_1)
		arg_39_0:nodeByName("gouzi_container"):getChildByName("gou_left"):setRotation(30)
		arg_39_0:nodeByName("gouzi_container"):getChildByName("gou_right"):setRotation(-30)

		arg_39_0.angle = -1 * var_0_13
		arg_39_0.notEnd = false
		arg_39_0.move = false
		arg_39_0.moveTime = 0
		arg_39_0.down = -1
		arg_39_0.itemNum = 8
		arg_39_0.nowGetItem = 0
		arg_39_0.downangle = 31
		arg_39_0.changeSpeed = false
		arg_39_0.speedUp = false
		arg_39_0.pauseTime = 2
		arg_39_0.moveSpeed = arg_39_0:changeMoveSpeed(var_0_16)

		for iter_39_0 = 1, #arg_39_0.item do
			arg_39_0.item[iter_39_0]:setVisible(false)
		end

		arg_39_0:checkMap()
		arg_39_0:createScheduler()
	end
end

function var_0_0.playSound(arg_41_0, arg_41_1)
	local var_41_0 = xyd.tables.sound:getSound(arg_41_1)

	audio.playSound(var_41_0, false)
end

return var_0_0
