local var_0_0 = class("ThrowSandbagWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpriteNodeButton")
local var_0_4 = xyd.tables.misc
local var_0_5 = xyd.tables.hero
local var_0_6 = xyd.tables.throwSandbag
local var_0_7 = xyd.tables.throwSandbagBuff
local var_0_8 = "skeletons/buff/buff_eff_freeze"
local var_0_9 = var_0_4:getValue("dodge_app")
local var_0_10 = var_0_4:getValue("dodge_offset")
local var_0_11 = 5
local var_0_12 = var_0_4:getValue("dodge_ballspac")
local var_0_13 = 10
local var_0_14 = {
	Jiansu = 1,
	Bingdong = 5,
	AddSandBag = 4,
	FriendProbUp = 3,
	ProbUp = 2,
	AtkSpeed = 6
}
local var_0_15 = 6
local var_0_16 = 1

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.chooseID = arg_1_2.chooseID
	arg_1_0.gameInfos = arg_1_2.gameInfos
	arg_1_0.selfRds = arg_1_2.selfRds
	arg_1_0.friendRds = arg_1_2.friendRds
	arg_1_0.points_ = {}
	arg_1_0.points_.self = {}
	arg_1_0.points_.friend = {}
	arg_1_0.shootTag_ = {}
	arg_1_0.shootTag_.self = {}
	arg_1_0.shootTag_.friend = {}
	arg_1_0.destPos_ = {}
	arg_1_0.destPos_.self = {}
	arg_1_0.destPos_.friend = {}
	arg_1_0.awards_ = {}
	arg_1_0.awards_.self = {}
	arg_1_0.awards_.friend = {}
	arg_1_0.countQueue_ = {}
	arg_1_0.buffQueue_ = {}
	arg_1_0.shootTimesCount = 0
	arg_1_0.shootCountRecord_ = {}
	arg_1_0.probUpRecord = {}
	arg_1_0.friendProbUpRecord_ = {}
	arg_1_0.records_ = {}
	arg_1_0.buffs_ = {}

	for iter_1_0 = 1, var_0_15 do
		table.insert(arg_1_0.buffs_, 0)
	end

	arg_1_0.count = 0
	arg_1_0.addHeroCount = 0
	arg_1_0.atkInterval = 0
	arg_1_0.throwNum = 5
	arg_1_0.sandBagNum = var_0_4:getValue("dodge_ballnum")
	arg_1_0.isEnd = false
	arg_1_0.throwSandbag = xyd.ModelManager.get():loadModel(xyd.ModelType.THROW_SANDBAG)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initData()
	arg_2_0:layout()
	arg_2_0:addTouchLayer()
	arg_2_0:startGame()
end

function var_0_0.initData(arg_3_0, arg_3_1)
	arg_3_0.heroCount = 0
	arg_3_0.heroShowCount = 0
	arg_3_0.buffShowCount = 0
	arg_3_0.buffNum = 0
	arg_3_0.heroNodes_ = {}
	arg_3_0.movingHeroNodes_ = {}
	arg_3_0.sortInfos = {}

	for iter_3_0 = 1, #arg_3_0.gameInfos.monsters do
		local var_3_0 = {
			originIndex = iter_3_0,
			id = arg_3_0.gameInfos.monsters[iter_3_0]
		}

		table.insert(arg_3_0.sortInfos, var_3_0)
	end

	for iter_3_1 = #arg_3_0.gameInfos.buffs, 1, -1 do
		local var_3_1 = {
			id = arg_3_0.gameInfos.buffs[iter_3_1].id
		}

		table.insert(arg_3_0.sortInfos, arg_3_0.gameInfos.buffs[iter_3_1].pos, var_3_1)
	end

	for iter_3_2 = 1, #arg_3_0.sortInfos do
		arg_3_0:createHero(arg_3_0.sortInfos[iter_3_2])
	end
end

function var_0_0.addTouchLayer(arg_4_0)
	local var_4_0 = display.newNode()

	var_4_0:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	var_4_0:addTo(arg_4_0:nodeByName("node_touch"))
	var_4_0:setTouchEnabled(true)
	var_4_0:setTouchSwallowEnabled(false)
	var_4_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" and arg_4_0:canShoot() then
			arg_4_0:shoot(arg_5_0.x, arg_5_0.y, arg_4_0.throwNum, "self")

			if arg_4_0.friend then
				local var_5_0 = var_0_4:getValue("dodge_friendpro")

				if arg_4_0:isHasBuffByType(var_0_14.FriendProbUp) then
					var_5_0 = var_5_0 + var_0_7:effect(var_0_14.FriendProbUp)
					arg_4_0.friendProbUpRecord_[arg_4_0.count] = true
				end

				if var_5_0 >= arg_4_0.friendRds[arg_4_0.shootTimesCount] / 1000 then
					arg_4_0:shoot(arg_5_0.x, arg_5_0.y, 5, "friend")
				end
			end

			arg_4_0.atkInterval = var_0_12

			if arg_4_0:isHasBuffByType(var_0_14.AtkSpeed) then
				arg_4_0.atkInterval = arg_4_0.atkInterval - var_0_7:effect(var_0_14.AtkSpeed)
			end
		end

		return true
	end)
end

function var_0_0.startGame(arg_6_0)
	arg_6_0.handle = var_0_2.scheduleUpdateGlobal(handler(arg_6_0, arg_6_0.mainLoop))
end

function var_0_0.mainLoop(arg_7_0)
	arg_7_0.count = arg_7_0.count + 1
	arg_7_0.atkInterval = arg_7_0.atkInterval - 1

	if not arg_7_0:isHasBuffByType(var_0_14.Bingdong) then
		arg_7_0.addHeroCount = arg_7_0.addHeroCount + 1

		if arg_7_0.addHeroCount % var_0_9 == 1 then
			local var_7_0 = true

			arg_7_0:addHero(var_7_0)
		elseif arg_7_0.addHeroCount % var_0_9 == 1 + math.floor(var_0_9 / 2) then
			arg_7_0:addHero()
		end
	end

	arg_7_0:checkBuff()

	if arg_7_0.count % 10 == 1 then
		arg_7_0:checkHeroRemove()

		if not arg_7_0.isEnd and arg_7_0:checkEnd() then
			arg_7_0:sendResult()
		end
	end
end

function var_0_0.createHero(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_1.id
	local var_8_1 = display.newNode()

	var_8_1.info = arg_8_1

	if not arg_8_1.originIndex then
		arg_8_0.buffNum = arg_8_0.buffNum + 1
		var_8_1.buff = var_8_0
		var_8_1.moveSpeed = var_0_7:speed(var_8_0)

		local var_8_2 = xyd.AssetLoader.get():loadSprite("windows/throw_sandbag/game/buff_" .. var_8_0 .. ".png")

		var_8_2:setRotation(-35)
		var_8_2:addTo(var_8_1)
		var_8_2:setPosition(17, 130)

		local var_8_3 = xyd.createEffect("skeletons/ui_effect/throw_sandbag/dodge_bird")

		var_8_3:setScaleX(-1)
		var_8_3:addTo(var_8_1, -1)
		var_8_3:play(nil, true, nil, "shenti")
		var_8_3:setName("model_shenti")

		local var_8_4 = xyd.createEffect("skeletons/ui_effect/throw_sandbag/dodge_bird")

		var_8_4:setScaleX(-1)
		var_8_4:addTo(var_8_1, 1)
		var_8_4:play(nil, true, nil, "zhuazi")
		var_8_4:setName("model")
		var_8_1:setPositionY(200)

		local var_8_5 = var_0_4:getValue("dodge_collider1")[1]
		local var_8_6 = var_0_4:getValue("dodge_collider1")[2]
		local var_8_7 = display.newRect(cc.rect(0, 0, var_8_5, var_8_6), {
			borderWidth = 3,
			fillColor = cc.c4f(0, 0, 255, 0),
			borderColor = cc.c4f(0, 0, 255, 0)
		})

		var_8_7:addTo(var_8_1, 1)
		var_8_7:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_7:setPosition(0, 130 + var_8_6 / 2)
		var_8_7:setName("border")
		var_8_7:setContentSize(var_8_5, var_8_6)
		var_8_1:addTo(arg_8_0:nodeByName("node_hero"), 1)
	else
		local var_8_8 = var_0_6:partnerID(var_8_0)
		local var_8_9

		if var_8_8 then
			var_8_9 = var_0_5:modelID(var_8_8)
		else
			var_8_9 = var_0_6:model(var_8_0)
		end

		var_8_1.id = var_8_0
		var_8_1.moveSpeed = var_0_6:speed(var_8_0)

		local var_8_10 = xyd.HeroAnimation.new(var_8_9, var_8_9, xyd.tables.model:uiScale(var_8_9), {})

		var_8_10:setName("model")
		var_8_10:walk(true)
		var_8_10:flipX(true)
		var_8_10:addTo(var_8_1)

		local var_8_11 = 0.75

		var_8_10:setScale(var_8_11)

		local var_8_12 = var_0_6:collider(var_8_0)
		local var_8_13 = var_0_4:getValue("dodge_collider2")[(var_8_12 - 1) * 2 + 1]
		local var_8_14 = var_0_4:getValue("dodge_collider2")[(var_8_12 - 1) * 2 + 2]
		local var_8_15 = display.newRect(cc.rect(0, 0, var_8_13, var_8_14), {
			borderWidth = 3,
			fillColor = cc.c4f(0, 0, 255, 0),
			borderColor = cc.c4f(0, 0, 255, 0)
		})

		var_8_15:addTo(var_8_1, 1)
		var_8_15:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_15:setPosition(0, var_8_10.headPoint.y / 2 * var_8_11)
		var_8_15:setName("border")
		var_8_15:setContentSize(var_8_13, var_8_14)

		if var_8_1.id == arg_8_0.chooseID then
			local var_8_16 = "windows/throw_sandbag/game/choose.png"
			local var_8_17 = xyd.AssetLoader.get():loadSprite(var_8_16)
			local var_8_18 = var_8_10.headPoint

			var_8_17:setScale(1 / var_8_11)
			var_8_17:addTo(var_8_10)
			var_8_17:align(display.CENTER_BOTTOM, var_8_18.x, var_8_18.y + 20)
		end

		var_8_1:addTo(arg_8_0:nodeByName("node_hero"))
	end

	table.insert(arg_8_0.heroNodes_, var_8_1)
end

function var_0_0.addHero(arg_9_0, arg_9_1)
	if arg_9_0.heroCount < #arg_9_0.heroNodes_ then
		arg_9_0.heroCount = arg_9_0.heroCount + 1

		local var_9_0 = arg_9_0.heroNodes_[arg_9_0.heroCount]

		if arg_9_1 and not var_9_0.buff then
			arg_9_0.heroCount = arg_9_0.heroCount - 1

			return
		end

		local var_9_1 = var_9_0:getChildByName("model")

		if arg_9_0:isHasBuffByType(var_0_14.Jiansu) then
			var_9_0:runAction(cc.RepeatForever:create(cc.MoveBy:create(1, cc.p(-var_9_0.moveSpeed + var_0_7:effect(var_0_14.Jiansu), 0))))
			var_9_1:setTimeScale(0.5)

			local var_9_2 = var_9_0:getChildByName("model_shenti")

			if var_9_2 then
				var_9_2:setTimeScale(0.5)
			end
		else
			var_9_0:runAction(cc.RepeatForever:create(cc.MoveBy:create(1, cc.p(-var_9_0.moveSpeed, 0))))
		end

		table.insert(arg_9_0.movingHeroNodes_, var_9_0)
	end
end

function var_0_0.addBuff(arg_10_0, arg_10_1)
	if arg_10_1 == var_0_14.AddSandBag then
		arg_10_0.sandBagNum = arg_10_0.sandBagNum + var_0_7:effect(var_0_14.AddSandBag)

		arg_10_0:nodeByName("text_total_num"):setString(arg_10_0.sandBagNum)

		return
	end

	if arg_10_0.buffs_[arg_10_1] > 0 then
		arg_10_0.buffs_[arg_10_1] = var_0_7:time(arg_10_1)
	else
		arg_10_0:updateBuffShow(arg_10_1)

		arg_10_0.buffs_[arg_10_1] = var_0_7:time(arg_10_1)

		for iter_10_0, iter_10_1 in ipairs(arg_10_0.movingHeroNodes_) do
			local var_10_0 = iter_10_1:getChildByName("model")

			if arg_10_1 == var_0_14.Bingdong then
				iter_10_1:stopAllActions()
				arg_10_0:addEffect(var_10_0, var_0_8)
				var_10_0:pause()

				local var_10_1 = iter_10_1:getChildByName("model_shenti")

				if var_10_1 then
					var_10_1:pause()
				end
			elseif arg_10_1 == var_0_14.Jiansu then
				iter_10_1:stopAllActions()
				var_10_0:setTimeScale(0.5)

				local var_10_2 = iter_10_1:getChildByName("model_shenti")

				if var_10_2 then
					var_10_2:setTimeScale(0.5)
				end

				if not arg_10_0:isHasBuffByType(var_0_14.Bingdong) then
					iter_10_1:runAction(cc.RepeatForever:create(cc.MoveBy:create(1, cc.p(-iter_10_1.moveSpeed + var_0_7:effect(var_0_14.Jiansu), 0))))
				end
			end
		end
	end
end

function var_0_0.removeBuff(arg_11_0, arg_11_1)
	arg_11_0.buffs_[arg_11_1] = 0

	arg_11_0:updateBuffShow(arg_11_1, true)

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.movingHeroNodes_) do
		local var_11_0 = iter_11_1:getChildByName("model")

		if arg_11_1 == var_0_14.Bingdong then
			iter_11_1:stopAllActions()
			var_11_0:getChildByName("effect"):removeSelf()
			var_11_0:resume()

			local var_11_1 = iter_11_1:getChildByName("model_shenti")

			if var_11_1 then
				var_11_1:resume()
			end

			if not arg_11_0:isHasBuffByType(var_0_14.Jiansu) then
				iter_11_1:runAction(cc.RepeatForever:create(cc.MoveBy:create(1, cc.p(-iter_11_1.moveSpeed, 0))))
			else
				iter_11_1:runAction(cc.RepeatForever:create(cc.MoveBy:create(1, cc.p(-iter_11_1.moveSpeed + var_0_7:effect(var_0_14.Jiansu), 0))))
			end
		elseif arg_11_1 == var_0_14.Jiansu then
			iter_11_1:stopAllActions()
			var_11_0:setTimeScale(1)

			local var_11_2 = iter_11_1:getChildByName("model_shenti")

			if var_11_2 then
				var_11_2:setTimeScale(1)
			end

			if not arg_11_0:isHasBuffByType(var_0_14.Bingdong) then
				iter_11_1:runAction(cc.RepeatForever:create(cc.MoveBy:create(1, cc.p(-iter_11_1.moveSpeed, 0))))
			end
		end
	end
end

function var_0_0.checkBuff(arg_12_0)
	for iter_12_0 = 1, var_0_15 do
		if arg_12_0.buffs_[iter_12_0] > 0 then
			arg_12_0.buffs_[iter_12_0] = arg_12_0.buffs_[iter_12_0] - 1

			if arg_12_0.buffs_[iter_12_0] == 0 then
				arg_12_0:removeBuff(iter_12_0)
			end
		end
	end
end

function var_0_0.layout(arg_13_0)
	local var_13_0 = var_0_3.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.BLUE)
	})

	var_13_0:addTo(arg_13_0)
	var_13_0:setAnchorPoint(0.5, 0.5)
	var_13_0:setPosition(46, 694)
	var_13_0:setName("return_btn")
	var_13_0:setTouchSwallowEnabled(true)

	arg_13_0.returnBtn = var_13_0

	arg_13_0.returnBtn:addTouchEvent(function(arg_14_0)
		if arg_14_0.name == "ended" then
			xyd.playCloseSound()

			local var_14_0 = xyd.tables.translation:translation("THROW_SANDBAG_TEXT_15")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_14_0, function()
				local var_15_0 = {
					records = arg_13_0.records_
				}

				arg_13_0.throwSandbag:sendResult(var_15_0, function(arg_16_0, arg_16_1)
					xyd.WindowManager.get():openWindow("throw_sandbag_result", {
						awards = arg_13_0.awards_
					})
				end)
			end)
		end
	end)

	local var_13_1 = arg_13_0:nodeByName("progress")

	var_13_1:addEventListener(function()
		local var_17_0 = math.ceil(var_13_1:getPercent() / var_0_13) * var_0_13

		if var_17_0 > 100 then
			var_17_0 = 100
		elseif var_17_0 < var_0_13 then
			var_17_0 = var_0_13
		end

		var_13_1:setPercent(var_17_0)
		arg_13_0:updateThrowNum(var_17_0 / 100 * var_0_13)
	end)

	local var_13_2 = arg_13_0:nodeByName("progress_di")
	local var_13_3 = display.newNode()

	var_13_3:setContentSize(var_13_2:getContentSize())
	var_13_3:addTo(var_13_2)
	var_13_3:setTouchEnabled(true)
	var_13_3:setTouchSwallowEnabled(true)
	var_13_1:setPercent(arg_13_0.throwNum / var_0_13 * 100)
	arg_13_0:updateThrowNum(arg_13_0.throwNum)
	arg_13_0:nodeByName("text_total_num"):setString(arg_13_0.sandBagNum)

	local var_13_4 = arg_13_0:nodeByName("text_left_partner")

	var_13_4:getVirtualRenderer():setAdditionalKerning(5)
	var_13_4:setString(#arg_13_0.heroNodes_ - arg_13_0.buffNum)

	arg_13_0.player = xyd.createEffect("skeletons/ui_effect/throw_sandbag/dodge_ball_b")

	arg_13_0.player:addTo(arg_13_0:nodeByName("node_self"))
	arg_13_0.player:setScale(0.2)
	arg_13_0.player:play(nil, true, nil, "idle")

	if arg_13_0.throwSandbag.gameFriendID > 0 then
		arg_13_0.friend = xyd.createEffect("skeletons/ui_effect/throw_sandbag/dodge_ball_f")

		arg_13_0.friend:addTo(arg_13_0:nodeByName("node_friend"))
		arg_13_0.friend:setScale(0.12)
		arg_13_0.friend:play(nil, true, nil, "idle")
	end
end

function var_0_0.updateThrowNum(arg_18_0, arg_18_1)
	if arg_18_0.throwNum ~= arg_18_1 then
		arg_18_0.throwNum = arg_18_1

		local var_18_0 = arg_18_0:nodeByName("progress")
		local var_18_1 = var_18_0:getPositionX() + var_18_0:getWidth() * (arg_18_1 / var_0_13 - 0.5)

		arg_18_0:nodeByName("bg_throw_num"):setPositionX(var_18_1)
		arg_18_0:nodeByName("text_throw_num"):setString(arg_18_1)
	end
end

function var_0_0.checkHeroRemove(arg_19_0)
	for iter_19_0 = #arg_19_0.movingHeroNodes_, 1, -1 do
		local var_19_0 = arg_19_0.movingHeroNodes_[iter_19_0]

		if arg_19_0:nodeByName("node_hero"):getPositionX() + var_19_0:getPositionX() < -200 then
			table.remove(arg_19_0.movingHeroNodes_, iter_19_0)
			var_19_0:removeSelf()
		end
	end

	for iter_19_1 = #arg_19_0.movingHeroNodes_, 1, -1 do
		local var_19_1 = arg_19_0.movingHeroNodes_[iter_19_1]
		local var_19_2 = arg_19_0:nodeByName("node_hero"):getPositionX() + var_19_1:getPositionX()

		if not var_19_1.isShow and var_19_2 < 1480 then
			if var_19_1.buff then
				arg_19_0.buffShowCount = arg_19_0.buffShowCount + 1
			end

			arg_19_0.heroShowCount = arg_19_0.heroShowCount + 1
			var_19_1.isShow = true
		end
	end

	arg_19_0:nodeByName("text_left_partner"):setString(arg_19_0:getLeftHero())
end

function var_0_0.getLeftHero(arg_20_0)
	return #arg_20_0.heroNodes_ - arg_20_0.buffNum - (arg_20_0.heroShowCount - arg_20_0.buffShowCount)
end

function var_0_0.shoot(arg_21_0, arg_21_1, arg_21_2, arg_21_3, arg_21_4)
	local var_21_0 = arg_21_0:convertToNodeSpace(cc.p(arg_21_1, arg_21_2))

	arg_21_1, arg_21_2 = var_21_0.x, var_21_0.y
	arg_21_4 = arg_21_4 or "self"

	local var_21_1 = arg_21_0.count

	arg_21_0.shootTag_[arg_21_4][var_21_1] = true
	arg_21_0.points_[arg_21_4][var_21_1] = {}
	arg_21_0.destPos_[arg_21_4][var_21_1] = {}

	if arg_21_4 == "self" then
		arg_21_0.shootTimesCount = arg_21_0.shootTimesCount + 1
		arg_21_0.shootCountRecord_[var_21_1] = arg_21_0.shootTimesCount

		if arg_21_3 > arg_21_0.sandBagNum then
			arg_21_3 = arg_21_0.sandBagNum
		end

		arg_21_0.sandBagNum = arg_21_0.sandBagNum - arg_21_3

		arg_21_0:nodeByName("text_total_num"):setString(arg_21_0.sandBagNum)
		arg_21_0.player:play(function()
			arg_21_0.player:play(nil, true, nil, "idle")
		end, false, nil, "skill")
	else
		arg_21_0.friend:play(function()
			arg_21_0.friend:play(nil, true, nil, "idle")
		end, false, nil, "skill")
	end

	local var_21_2 = arg_21_0:nodeByName("node_" .. arg_21_4 .. "_sandbag")
	local var_21_3 = var_21_2:getPositionX()
	local var_21_4 = var_21_2:getPositionY()
	local var_21_5 = arg_21_1 - var_21_3
	local var_21_6 = arg_21_2 - var_21_4

	local function var_21_7(arg_24_0)
		local var_24_0
		local var_24_1 = (math.random() - 0.5) * 4
		local var_24_2 = 1 / (1 + math.exp(-var_24_1)) * var_0_10
		local var_24_3 = math.random() * 360 - 180 * arg_24_0 / arg_21_3
		local var_24_4 = math.cos(var_24_3) * var_24_2
		local var_24_5 = math.sin(var_24_3) * var_24_2

		return var_24_4, var_24_5
	end

	local function var_21_8(arg_25_0)
		local var_25_0
		local var_25_1
		local var_25_2 = true

		while var_25_2 do
			var_25_0, var_25_1 = var_21_7(arg_25_0)

			if #arg_21_0.points_[arg_21_4][var_21_1] == 0 then
				break
			end

			local var_25_3 = false

			for iter_25_0 = 1, #arg_21_0.points_[arg_21_4][var_21_1] do
				local var_25_4, var_25_5 = arg_21_0.points_[arg_21_4][var_21_1][iter_25_0]:getPosition()
				local var_25_6 = var_25_4 - var_21_5
				local var_25_7 = var_25_5 - var_21_6

				if math.pow(var_25_6 - var_25_0, 2) + math.pow(var_25_7 - var_25_1, 2) <= math.pow(2 * var_0_11, 2) then
					var_25_3 = true

					break
				end
			end

			if not var_25_3 then
				break
			end
		end

		return var_25_0, var_25_1
	end

	arg_21_0.destPos_[arg_21_4][var_21_1] = {}

	for iter_21_0 = 1, arg_21_3 do
		local var_21_9, var_21_10 = var_21_8(iter_21_0)
		local var_21_11 = xyd.AssetLoader.get():loadSprite("windows/throw_sandbag/game/ball.png")

		var_21_11:setVisible(false)
		var_21_11:setScale(0.3)
		var_21_11:addTo(var_21_2)
		table.insert(arg_21_0.destPos_[arg_21_4][var_21_1], {
			x = var_21_5 + var_21_9,
			y = var_21_6 + var_21_10
		})
		table.insert(arg_21_0.points_[arg_21_4][var_21_1], var_21_11)
	end

	local var_21_12 = 0.5
	local var_21_13 = cc.Sequence:create({
		cc.DelayTime:create(0.2),
		cc.CallFunc:create(function()
			for iter_26_0, iter_26_1 in ipairs(arg_21_0.points_[arg_21_4][var_21_1]) do
				local var_26_0 = arg_21_0.destPos_[arg_21_4][var_21_1][iter_26_0]

				iter_26_1:setVisible(true)

				local var_26_1 = cc.Spawn:create({
					cc.MoveBy:create(var_21_12, cc.p(var_26_0.x, var_26_0.y)),
					cc.ScaleTo:create(var_21_12, 0.2)
				})
				local var_26_2 = transition.newEasing(var_26_1, "out", 2)

				iter_26_1:runAction(var_26_2)
			end
		end),
		cc.DelayTime:create(var_21_12 + 0.03333333333333333),
		cc.CallFunc:create(function()
			if arg_21_0 and not tolua.isnull(arg_21_0) then
				arg_21_0:checkHit(arg_21_4)
			end
		end)
	})

	var_21_2:runAction(var_21_13)
	table.insert(arg_21_0.countQueue_, var_21_1)
end

function var_0_0.canShoot(arg_28_0)
	return arg_28_0.sandBagNum > 0 and arg_28_0.atkInterval <= 0
end

function var_0_0.checkHit(arg_29_0, arg_29_1)
	local var_29_0 = table.remove(arg_29_0.countQueue_, 1)

	arg_29_0.shootTag_[arg_29_1][var_29_0] = false

	if arg_29_0.shootTag_.self[var_29_0] or arg_29_0.shootTag_.friend[var_29_0] then
		return
	end

	local function var_29_1(arg_30_0, arg_30_1)
		if arg_30_0.hasHit then
			return 0
		end

		local var_30_0 = arg_30_1:getChildByName("border")
		local var_30_1, var_30_2 = var_30_0:getPosition()
		local var_30_3 = arg_30_1:convertToWorldSpaceAR(cc.p(0, 0))
		local var_30_4 = arg_30_0:convertToWorldSpaceAR(cc.p(0, 0))

		if var_30_3.x + var_30_1 - var_30_0:getWidth() / 2 <= var_30_4.x and var_30_4.x <= var_30_3.x + var_30_1 + var_30_0:getWidth() / 2 and var_30_3.y + var_30_2 - var_30_0:getHeight() / 2 <= var_30_4.y and var_30_4.y <= var_30_3.y + var_30_2 + var_30_0:getHeight() / 2 then
			local var_30_5 = "skeletons/ui_effect/throw_sandbag/Edodge_ball_hit"
			local var_30_6 = arg_29_0:createEffect(var_30_5)
			local var_30_7 = arg_29_0:convertToNodeSpace(var_30_4)

			var_30_6:setPosition(var_30_7.x, var_30_7.y)
			var_30_6:play(function()
				arg_29_0:cacheEffect(var_30_5, var_30_6)
			end, false, nil, "texiao_01")

			arg_30_0.hasHit = true

			return 1
		end

		return 0
	end

	local var_29_2 = false

	for iter_29_0 = #arg_29_0.movingHeroNodes_, 1, -1 do
		local var_29_3 = arg_29_0.movingHeroNodes_[iter_29_0]
		local var_29_4 = 0

		if arg_29_0.points_.self[var_29_0] then
			for iter_29_1 = #arg_29_0.points_.self[var_29_0], 1, -1 do
				local var_29_5 = arg_29_0.points_.self[var_29_0][iter_29_1]

				var_29_4 = var_29_4 + var_29_1(var_29_5, var_29_3)
			end
		end

		if arg_29_0.points_.friend[var_29_0] then
			for iter_29_2 = #arg_29_0.points_.friend[var_29_0], 1, -1 do
				var_29_2 = true

				local var_29_6 = arg_29_0.points_.friend[var_29_0][iter_29_2]

				var_29_4 = var_29_4 + var_29_1(var_29_6, var_29_3)
			end
		end

		if var_29_3.buff then
			if var_29_4 > 0 then
				arg_29_0:addBuff(var_29_3.buff)
				table.remove(arg_29_0.movingHeroNodes_, iter_29_0)
				var_29_3:removeSelf()
			end
		else
			local var_29_7 = var_0_6:probability(var_29_3.id)

			if arg_29_0:isHasBuffByType(var_0_14.ProbUp) then
				var_29_7 = var_29_7 + var_0_7:effect(var_0_14.ProbUp)
				arg_29_0.probUpRecord[var_29_0] = true
			end

			local var_29_8 = arg_29_0.throwSandbag.baseInfo.act_id

			if var_29_8 and var_29_8 ~= 0 then
				local var_29_9 = xyd.tables.throwSandbagActivity

				if var_29_9:type(var_29_8) == var_0_16 and arg_29_0.throwSandbag.baseInfo.daily_count <= var_29_9:effectNum(var_29_8) then
					var_29_7 = var_29_7 + var_29_9:prob(var_29_8)
				end
			end

			local var_29_10 = var_29_4 * var_29_7
			local var_29_11 = math.min(var_29_10, 1)
			local var_29_12 = var_29_11 >= arg_29_0.selfRds[arg_29_0.shootCountRecord_[var_29_0]] / 1000

			if var_29_12 then
				local var_29_13 = var_29_3:convertToWorldSpaceAR(cc.p(0, 0))
				local var_29_14 = "skeletons/ui_effect/throw_sandbag/Edodge_ball_disp"
				local var_29_15 = arg_29_0:createEffect(var_29_14)
				local var_29_16 = arg_29_0:convertToNodeSpace(var_29_13)

				var_29_15:setPosition(var_29_16.x, var_29_16.y)
				var_29_15:play(function()
					arg_29_0:cacheEffect(var_29_14, var_29_15)
				end, false, nil, "texiao_01")

				if not arg_29_0.hitCheck then
					arg_29_0.hitCheck = {}
					arg_29_0.checkCount = 1
				end

				arg_29_0.hitCheck[arg_29_0.checkCount] = {
					singleHitRate = var_29_7,
					hitCount = var_29_4,
					seed = arg_29_0.selfRds[arg_29_0.shootCountRecord_[var_29_0]],
					rate_id = arg_29_0.shootCountRecord_[var_29_0]
				}
				arg_29_0.checkCount = arg_29_0.checkCount + 1

				arg_29_0:recordAward(var_29_3, var_29_2, var_29_0, var_29_4)
				table.remove(arg_29_0.movingHeroNodes_, iter_29_0)
				var_29_3:removeSelf()
			elseif var_29_11 > 0 and not var_29_12 then
				arg_29_0:playShanbi(var_29_3)
			end
		end
	end

	if arg_29_0.points_.self[var_29_0] then
		for iter_29_3 = #arg_29_0.points_.self[var_29_0], 1, -1 do
			local var_29_17 = arg_29_0.points_.self[var_29_0][iter_29_3]

			table.remove(arg_29_0.points_.self[var_29_0], iter_29_3)
			var_29_17:removeSelf()
		end
	end

	if arg_29_0.points_.friend[var_29_0] then
		for iter_29_4 = #arg_29_0.points_.friend[var_29_0], 1, -1 do
			local var_29_18 = arg_29_0.points_.friend[var_29_0][iter_29_4]

			table.remove(arg_29_0.points_.friend[var_29_0], iter_29_4)
			var_29_18:removeSelf()
		end
	end
end

function var_0_0.addEffect(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = xyd.createEffect(arg_33_2, 0.5)

	var_33_0:setAnimation(0, "texiao", true)
	var_33_0:setName("effect")
	var_33_0:addTo(arg_33_1)

	local var_33_1 = 0
	local var_33_2 = 150

	if arg_33_1.chestPoint then
		var_33_1 = arg_33_1.chestPoint.x
		var_33_2 = arg_33_1.chestPoint.y
	else
		var_33_0:setScale(0.6)
	end

	var_33_0:align(display.CENTER_BOTTOM, var_33_1, var_33_2)
end

function var_0_0.willClose(arg_34_0)
	if arg_34_0.handle then
		var_0_2.unscheduleGlobal(arg_34_0.handle)

		arg_34_0.handle = nil
	end
end

function var_0_0.isHasBuffByType(arg_35_0, arg_35_1)
	return arg_35_0.buffs_[arg_35_1] > 0
end

function var_0_0.checkEnd(arg_36_0)
	local var_36_0 = arg_36_0.countQueue_[1]

	if var_36_0 and (arg_36_0.shootTag_.self[var_36_0] or arg_36_0.shootTag_.friend[var_36_0]) then
		return false
	end

	return arg_36_0.sandBagNum == 0 or arg_36_0:getLeftHero() == 0 and #arg_36_0.movingHeroNodes_ == 0
end

function var_0_0.sendResult(arg_37_0)
	arg_37_0.isEnd = true

	local var_37_0 = arg_37_0:nodeByName("bg_end_tip")

	var_37_0:performWithDelay(function()
		var_37_0:setVisible(true)

		local var_38_0 = var_37_0:getChildByName("text_end_tip")

		if arg_37_0.sandBagNum > 0 then
			var_38_0:setString(var_0_1:translation("THROW_SANDBAG_TEXT_7"))
		else
			var_38_0:setString(var_0_1:translation("THROW_SANDBAG_TEXT_8"))
		end

		var_37_0:stopAllActions()
		var_37_0:performWithDelay(function()
			if arg_37_0 and not tolua.isnull(arg_37_0) then
				var_37_0:setVisible(false)

				local var_39_0 = {
					records = arg_37_0.records_
				}

				arg_37_0.throwSandbag:sendResult(var_39_0, function(arg_40_0, arg_40_1)
					xyd.WindowManager.get():openWindow("throw_sandbag_result", {
						awards = arg_37_0.awards_
					})
				end)
			end
		end, 3)
	end, 2)
end

function var_0_0.createEffect(arg_41_0, arg_41_1)
	if not arg_41_0.effectCache then
		arg_41_0.effectCache = {}
	end

	if not arg_41_0.effectCache[arg_41_1] then
		arg_41_0.effectCache[arg_41_1] = {}
	end

	if #arg_41_0.effectCache[arg_41_1] > 0 then
		local var_41_0 = table.remove(arg_41_0.effectCache[arg_41_1])

		var_41_0:setVisible(true)

		return var_41_0
	else
		local var_41_1 = xyd.createEffect(arg_41_1)

		var_41_1:addTo(arg_41_0)

		return var_41_1
	end
end

function var_0_0.cacheEffect(arg_42_0, arg_42_1, arg_42_2)
	arg_42_2:setVisible(false)
	table.insert(arg_42_0.effectCache[arg_42_1], arg_42_2)
end

function var_0_0.awardBroadcast(arg_43_0, arg_43_1, arg_43_2)
	local var_43_0 = arg_43_0:nodeByName("bg_tip")

	var_43_0:setVisible(true)
	var_43_0:getChildByName("text_tip"):setString(string.format(var_0_1:translation("THROW_SANDBAG_TEXT_6"), xyd.tables.item:name(arg_43_1), arg_43_2))
	var_43_0:stopAllActions()
	var_43_0:performWithDelay(function()
		if arg_43_0 and not tolua.isnull(arg_43_0) then
			var_43_0:setVisible(false)
		end
	end, 3)
end

function var_0_0.recordAward(arg_45_0, arg_45_1, arg_45_2, arg_45_3, arg_45_4)
	local var_45_0 = {}
	local var_45_1
	local var_45_2 = var_0_6:partnerID(arg_45_1.id)

	if var_45_2 then
		var_45_1 = var_0_5:stoneID(var_45_2)
	else
		var_45_1 = var_0_6:itemID(arg_45_1.id)
	end

	local var_45_3 = var_0_6:num(arg_45_1.id)

	if arg_45_1.id == arg_45_0.chooseID then
		var_45_3 = var_45_3 * 2
		var_45_0.isDouble = true
	end

	var_45_0.itemID = var_45_1
	var_45_0.num = var_45_3

	table.insert(arg_45_0.awards_.self, var_45_0)

	if arg_45_2 then
		local var_45_4 = clone(var_45_0)

		var_45_4.isFriend = true

		table.insert(arg_45_0.awards_.friend, var_45_4)
	end

	arg_45_0:awardBroadcast(var_45_1, var_45_3)

	local var_45_5 = {
		rate_id = arg_45_0.shootCountRecord_[arg_45_3],
		id = arg_45_1.info.originIndex,
		is_buff1 = arg_45_0.probUpRecord[arg_45_3] or false,
		is_buff2 = arg_45_0.friendProbUpRecord_[arg_45_3] or false,
		ball_num = arg_45_4
	}

	table.insert(arg_45_0.records_, var_45_5)
end

function var_0_0.playShanbi(arg_46_0, arg_46_1)
	local var_46_0 = xyd.tables.battleConfig.floatAnimationDuration
	local var_46_1 = xyd.tables.battleConfig.floatAnimationDeltaY
	local var_46_2 = xyd.tables.battleConfig.battleFloatScaleDuration
	local var_46_3 = xyd.tables.battleConfig.floatFadeOutDelay

	local function var_46_4(arg_47_0, arg_47_1)
		local var_47_0 = arg_47_0:getScale()

		arg_47_0:setAnchorPoint(cc.p(0.5, 0.5))
		xyd.setCascadeOpacityEnabled(arg_47_0, true)
		arg_47_0:scale(0)
		arg_47_0:setGlobalZOrder(1)

		local var_47_1 = {}

		table.insert(var_47_1, cc.ScaleTo:create(var_46_2, 1.2 * var_47_0, 1.2 * var_47_0))
		table.insert(var_47_1, cc.ScaleTo:create(var_46_2, var_47_0, var_47_0))
		table.insert(var_47_1, cc.DelayTime:create(var_46_3))
		table.insert(var_47_1, cc.FadeOut:create(var_46_0 - var_46_3))
		arg_47_0:runActionOnce(transition.sequence(var_47_1), true, arg_47_1, 0)
	end

	local var_46_5 = arg_46_1:getChildByName("model")
	local var_46_6 = "images/battle/float_text/miss1.png"
	local var_46_7 = xyd.AssetLoader.get():loadSprite(var_46_6)
	local var_46_8 = var_46_5.headPoint

	var_46_7:addTo(arg_46_1)
	var_46_7:align(display.CENTER_BOTTOM, var_46_8.x, var_46_8.y)
	var_46_4(var_46_7, function()
		var_46_7:removeSelf()
	end)
end

function var_0_0.updateBuffShow(arg_49_0, arg_49_1, arg_49_2)
	if arg_49_2 then
		local var_49_0

		for iter_49_0, iter_49_1 in ipairs(arg_49_0.buffQueue_) do
			if iter_49_1.buffType == arg_49_1 then
				var_49_0 = iter_49_0

				break
			end
		end

		arg_49_0.buffQueue_[var_49_0].buff:removeSelf()

		for iter_49_2 = var_49_0 + 1, #arg_49_0.buffQueue_ do
			local var_49_1 = arg_49_0.buffQueue_[iter_49_2].buff

			if iter_49_2 <= 4 then
				var_49_1:setVisible(true)

				local var_49_2, var_49_3 = arg_49_0:nodeByName("node_buff_" .. iter_49_2 - 1):getPosition()

				var_49_1:setPosition(var_49_2, var_49_3)
			else
				var_49_1:setVisible(false)
			end
		end

		table.remove(arg_49_0.buffQueue_, var_49_0)
	else
		local var_49_4 = xyd.AssetLoader.get():loadSprite("windows/throw_sandbag/game/buff_" .. arg_49_1 .. ".png")
		local var_49_5 = {
			buff = var_49_4,
			buffType = arg_49_1
		}

		table.insert(arg_49_0.buffQueue_, var_49_5)
		var_49_4:addTo(arg_49_0)

		if #arg_49_0.buffQueue_ <= 4 then
			var_49_4:setVisible(true)

			local var_49_6, var_49_7 = arg_49_0:nodeByName("node_buff_" .. #arg_49_0.buffQueue_):getPosition()

			var_49_4:setPosition(var_49_6, var_49_7)
		else
			var_49_4:setVisible(false)
		end
	end
end

return var_0_0
