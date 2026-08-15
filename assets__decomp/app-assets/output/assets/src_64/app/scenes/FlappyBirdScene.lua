local var_0_0 = class("FlappyBirdScene", import("app.common.ui.BaseScene"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.flappyBirdPartner
local var_0_4 = xyd.tables.flappyBirdSkill
local var_0_5 = xyd.tables.sound
local var_0_6 = xyd.tables.translation
local var_0_7 = 360
local var_0_8 = -500
local var_0_9 = 3
local var_0_10 = 0
local var_0_11 = 1
local var_0_12 = 16
local var_0_13 = 256
local var_0_14 = 4096
local var_0_15 = 65535
local var_0_16 = 100
local var_0_17 = 100
local var_0_18 = 0.35
local var_0_19 = 15
local var_0_20 = 90
local var_0_21 = 60
local var_0_22 = 200
local var_0_23 = 420
local var_0_24 = 20
local var_0_25 = 10
local var_0_26 = 600
local var_0_27 = 300
local var_0_28 = -20
local var_0_29 = math.ceil(var_0_26 / var_0_22 * 30)
local var_0_30 = 300
local var_0_31 = 212
local var_0_32 = -7
local var_0_33 = xyd.STAGE_HEIGHT - 2 * var_0_17 - var_0_30
local var_0_34 = {
	300,
	70,
	10
}
local var_0_35 = {
	630,
	147,
	21
}
local var_0_36 = {
	30,
	7,
	1
}
local var_0_37 = 300
local var_0_38 = -16
local var_0_39 = 70
local var_0_40 = 5
local var_0_41 = 1.1
local var_0_42 = -0.15
local var_0_43 = -0.04
local var_0_44 = 1
local var_0_45 = 0.7
local var_0_46 = 0.2
local var_0_47 = 0.6
local var_0_48 = 0.014
local var_0_49 = 62
local var_0_50 = 91
local var_0_51 = -1000
local var_0_52 = 0.3
local var_0_53 = "skeletons/ui_effect/gold_catch/kaunggongdongzuo"
local var_0_54 = 1
local var_0_55 = 2
local var_0_56 = 3
local var_0_57 = {
	Crystal = 2,
	DoubleScore = 1,
	Shield = 3,
	Wudi = 4
}
local var_0_58 = {
	"tianshi",
	"jingling",
	"emo",
	"longqishi"
}
local var_0_59 = 10000
local var_0_60 = 10001

function var_0_0.__create(arg_1_0)
	return display.newPhysicsScene()
end

function var_0_0.ctor(arg_2_0, arg_2_1)
	var_0_0.super.ctor(arg_2_0, arg_2_1)

	arg_2_0.hp = var_0_9
	arg_2_0.count = 0
	arg_2_0.blockCreateCount = 0
	arg_2_0.blockCount = 0
	arg_2_0.score = 0
	arg_2_0.blockNodes = {}
	arg_2_0.gameOver = false
	arg_2_0.buffCount = 0
	arg_2_0.buffCD = 0
	arg_2_0.heroIndex = arg_2_1.heroIndex
	arg_2_0.skillID = var_0_3:skill(arg_2_0.heroIndex)
	arg_2_0.isPractice = arg_2_1.isPractice
	arg_2_0.data = {}
	arg_2_0.flappyBird = xyd.ModelManager.get():loadModel(xyd.ModelType.FLAPPY_BIRD)
end

function var_0_0.init(arg_3_0)
	arg_3_0.world = arg_3_0:getPhysicsWorld()

	arg_3_0.world:setGravity(cc.vec2(0, -0))
	arg_3_0:initConfig()
	arg_3_0:initGame()
	arg_3_0:layout()
end

function var_0_0.initConfig(arg_4_0)
	var_0_22 = 200
	var_0_26 = 600
	var_0_19 = 15
	var_0_10 = 0
	var_0_29 = math.ceil(var_0_26 / var_0_22 * 30)
	var_0_30 = 300
	var_0_33 = xyd.STAGE_HEIGHT - 2 * var_0_17 - var_0_30
	var_0_34 = {
		300,
		70,
		10
	}
	var_0_37 = 300
	var_0_40 = 5
	var_0_41 = 1
	var_0_46 = 0.2

	local var_4_0 = var_0_3:collisionSize(arg_4_0.heroIndex)

	var_0_49 = var_4_0[1]
	var_0_50 = var_4_0[2]
	var_0_51 = -111.11111111111111 * var_0_49 * var_0_50
	var_0_52 = var_0_3:scale(arg_4_0.heroIndex)
end

function var_0_0.initGame(arg_5_0)
	arg_5_0:addContactListener()
	arg_5_0:addEdge()
	arg_5_0:addHero()
end

function var_0_0.layout(arg_6_0)
	arg_6_0:initBackground()
	arg_6_0:loadUI()
	arg_6_0:setBtns()
	arg_6_0:runStartEffect()
end

function var_0_0.loadUI(arg_7_0)
	local var_7_0 = "windows/flappy_bird/game.csb"

	arg_7_0.contentView_ = xyd.AssetLoader.get():loadNodeFromJson(var_7_0):addTo(arg_7_0, var_0_60)
	arg_7_0.container = arg_7_0.contentView_:getChildByName("container")

	arg_7_0:updateHp(var_0_9)

	local var_7_1 = arg_7_0.container:getChildByName("bg_score")

	var_7_1:getChildByName("text_score_1"):setString(var_0_6:translation("FLAPPY_BIRD_TEXT_4"))
	var_7_1:getChildByName("text_score_2"):setString(var_0_6:translation("FLAPPY_BIRD_TEXT_5"))

	arg_7_0.scoreLabel = var_7_1:getChildByName("score")

	arg_7_0.scoreLabel:setString(arg_7_0.score)
end

function var_0_0.setBtns(arg_8_0)
	local var_8_0 = var_0_1.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.BLUE)
	})

	var_8_0:addTo(arg_8_0.container)
	var_8_0:setAnchorPoint(0.5, 0.5)
	var_8_0:setPosition(44, 697)
	var_8_0:setName("return_btn")
	var_8_0:setTouchSwallowEnabled(true)

	arg_8_0.returnBtn = var_8_0

	arg_8_0.returnBtn:addTouchEvent(function(arg_9_0)
		if arg_9_0.name == "ended" and arg_8_0.count > 0 then
			xyd.playCloseSound()
			arg_8_0:edgeContact(true)
		end
	end)
	arg_8_0:updateSkillBtn(true)

	local var_8_1 = arg_8_0.container:getChildByName("btn_skill")

	var_8_1:addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_8_0.buffCD == 0 and arg_8_0.count > 0 then
			xyd.buttonScaleAnim(arg_10_0, arg_10_1)

			if arg_10_1 == ccui.TouchEventType.ended then
				arg_8_0:addHeroBuff()
			end
		end
	end)
	arg_8_0:setSkillBtnEffect(var_8_1)

	local var_8_2 = display.newNode()

	var_8_2:setContentSize(var_8_1:getContentSize())
	var_8_2:addTo(var_8_1)
	var_8_2:setTouchEnabled(true)
	var_8_2:setTouchSwallowEnabled(true)
end

function var_0_0.runStartEffect(arg_11_0)
	local var_11_0 = xyd.createEffect(var_0_53)

	var_11_0:addTo(arg_11_0)
	var_11_0:setPosition(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2)
	var_11_0:play(function()
		var_0_2.performWithDelayGlobal(function()
			arg_11_0.world:setGravity(cc.vec2(0, -1000))
			arg_11_0:addTouchLayer()
			arg_11_0:addSchedule()
		end, 0.1)
	end, false, nil, "texiao01")

	local var_11_1 = "flappy_daojishi"

	audio.playSound(var_0_5:getSound(var_11_1))
end

function var_0_0.updateSkillBtn(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_0.contentView_:getChildByName("container")
	local var_14_1

	if arg_14_1 then
		var_14_1 = "windows/flappy_bird/10" .. arg_14_0.heroIndex .. "_1.png"
	else
		var_14_1 = "windows/flappy_bird/10" .. arg_14_0.heroIndex .. "_2.png"
	end

	local var_14_2 = var_14_0:getChildByName("btn_skill")

	var_14_2:loadTextures(var_14_1, var_14_1, var_14_1)

	if arg_14_2 then
		if not arg_14_0.btnEffect then
			local var_14_3 = "skeletons/ui_effect/flappy_bird/fx_daoju"

			arg_14_0.btnEffect = xyd.createEffect(var_14_3)

			arg_14_0.btnEffect:setScale(4)
			arg_14_0.btnEffect:setPosition(var_14_2:getPositionX() / 2 + 30, var_14_2:getPositionY() / 2 + 30)
			arg_14_0.btnEffect:addTo(var_14_2)
		end

		arg_14_0.btnEffect:play(nil, false, nil, "texiao01")

		local var_14_4 = "flappy_jinenglengquehao"

		audio.playSound(var_0_5:getSound(var_14_4))
	end
end

function var_0_0.setSkillBtnEffect(arg_15_0, arg_15_1)
	local var_15_0 = xyd.AssetLoader.get():loadSprite("windows/flappy_bird/10" .. arg_15_0.heroIndex .. "_1.png")

	arg_15_0.progressBar = display.newProgressTimer(var_15_0, display.PROGRESS_TIMER_RADIAL)

	arg_15_0.progressBar:addTo(arg_15_1, 1)
	arg_15_0.progressBar:setPosition(cc.p(arg_15_1:getContentSize().width / 2, arg_15_1:getContentSize().height / 2))
	arg_15_0.progressBar:setMidpoint(cc.p(0.5, 0.5))
	arg_15_0.progressBar:setBarChangeRate(cc.p(1, 0))
	arg_15_0.progressBar:setPercentage(0)
	arg_15_0.progressBar:setVisible(false)
end

function var_0_0.updateHp(arg_16_0, arg_16_1)
	if arg_16_1 > arg_16_0.hp then
		if not arg_16_0.hpEffect then
			local var_16_0 = "skeletons/ui_effect/flappy_bird/aixinbuff"

			arg_16_0.hpEffect = xyd.createEffect(var_16_0)

			arg_16_0.hpEffect:addTo(arg_16_0.hero:getNode())
			arg_16_0.hpEffect:setScale(0.5)
		end

		arg_16_0.hpEffect:play(nil, false, nil, "texiao")
	end

	arg_16_0.hp = arg_16_1

	local var_16_1 = arg_16_0.contentView_:getChildByName("container"):getChildByName("node_heart")

	for iter_16_0 = 1, 3 do
		var_16_1:getChildByName("heart_" .. 4 - iter_16_0 .. "_2"):setVisible(iter_16_0 <= arg_16_0.hp)
	end
end

function var_0_0.addHero(arg_17_0)
	local var_17_0 = display.newNode()
	local var_17_1 = var_0_49
	local var_17_2 = var_0_50
	local var_17_3 = cc.PhysicsBody:createBox({
		width = var_17_1,
		height = var_17_2
	}, cc.PhysicsMaterial(0.1, 0, 0))

	var_17_3:setCategoryBitmask(var_0_15)
	var_17_3:setContactTestBitmask(var_0_15)
	var_17_3:setCollisionBitmask(0)
	var_17_3:setGravityEnable(true)
	var_17_0:setPhysicsBody(var_17_3)
	var_17_0:setPosition(640, 360)
	var_17_0:addTo(arg_17_0)
	var_17_0:setName("hero")

	local var_17_4 = display.newRect(cc.rect(0, 0, var_17_1, var_17_2), {
		borderWidth = 1,
		fillColor = cc.c4f(0, 255, 0, 0),
		borderColor = cc.c4f(1, 255, 1, 0)
	})

	var_17_4:addTo(var_17_0)
	var_17_4:setPosition(-var_17_1 / 2, -var_17_2 / 2)

	local var_17_5 = var_0_3:model(arg_17_0.heroIndex)
	local var_17_6 = xyd.createEffect(var_17_5)
	local var_17_7 = var_0_3:offset(arg_17_0.heroIndex)

	var_17_6:setScale(var_0_52)
	var_17_6:setPosition(var_17_7[1], -200 * var_0_52 + var_17_7[2])
	var_17_6:addTo(var_17_0, -1)
	var_17_6:play(nil, true, nil, "fly")
	var_17_6:setName("effect")
	xyd.setCascadeOpacityEnabled(var_17_0, true)

	arg_17_0.hero = var_17_3
end

function var_0_0.addEdge(arg_18_0)
	local var_18_0 = 1280
	local var_18_1 = 10
	local var_18_2 = display.newRect(cc.rect(0, 0, var_18_0, var_18_1), {
		borderWidth = 3,
		fillColor = cc.c4f(0, 255, 0, 0),
		borderColor = cc.c4f(1, 255, 1, 0)
	})
	local var_18_3 = cc.PhysicsBody:createBox({
		width = var_18_0,
		height = var_18_1
	}, cc.PhysicsMaterial(0.1, 0, 0), {
		x = var_18_0 / 2,
		y = var_18_1 / 2
	})

	var_18_3:setDynamic(false)
	var_18_3:setCategoryBitmask(var_0_11)
	var_18_3:setContactTestBitmask(var_0_11)
	var_18_3:setCollisionBitmask(0)
	var_18_3:setGravityEnable(false)
	var_18_2:setPhysicsBody(var_18_3)
	var_18_2:addTo(arg_18_0)
	var_18_2:setPosition(0, 10)
	var_18_2:setName("edge")

	local var_18_4 = display.newRect(cc.rect(0, 0, var_18_0, var_18_1), {
		borderWidth = 3,
		fillColor = cc.c4f(0, 255, 0, 0),
		borderColor = cc.c4f(1, 255, 1, 0)
	})
	local var_18_5 = cc.PhysicsBody:createBox({
		width = var_18_0,
		height = var_18_1
	}, cc.PhysicsMaterial(0.1, 0, 0), {
		x = var_18_0 / 2,
		y = var_18_1 / 2
	})

	var_18_5:setDynamic(false)
	var_18_5:setCategoryBitmask(var_0_11)
	var_18_5:setContactTestBitmask(var_0_11)
	var_18_5:setCollisionBitmask(0)
	var_18_5:setGravityEnable(false)
	var_18_4:setPhysicsBody(var_18_5)
	var_18_4:addTo(arg_18_0)
	var_18_4:setPosition(0, 700)
	var_18_4:setName("top")

	local var_18_6 = 10
	local var_18_7 = 720
	local var_18_8 = display.newRect(cc.rect(0, 0, var_18_6, var_18_7), {
		borderWidth = 3,
		fillColor = cc.c4f(0, 255, 0, 100),
		borderColor = cc.c4f(1, 255, 1, 100)
	})
	local var_18_9 = cc.PhysicsBody:createBox({
		width = var_18_6,
		height = var_18_7
	}, cc.PhysicsMaterial(0.1, 0, 0), {
		x = var_18_6 / 2,
		y = var_18_7 / 2
	})

	var_18_9:setDynamic(false)
	var_18_9:setCategoryBitmask(var_0_12)
	var_18_9:setContactTestBitmask(var_0_13)
	var_18_9:setCollisionBitmask(0)
	var_18_9:setGravityEnable(false)
	var_18_8:setPhysicsBody(var_18_9)
	var_18_8:addTo(arg_18_0)
	var_18_8:setPosition(-300, 0)
	var_18_8:setName("removeEdege")
end

function var_0_0.addTouchLayer(arg_19_0)
	local var_19_0 = display.newNode()

	var_19_0:setColor(cc.c4b(255, 255, 255, 100))
	var_19_0:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	var_19_0:addTo(arg_19_0, var_0_59)
	var_19_0:setTouchEnabled(true)
	var_19_0:setTouchSwallowEnabled(false)
	var_19_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
		if arg_20_0.name == "began" then
			if not arg_19_0.gameOver then
				local var_20_0 = "flappy_" .. var_0_58[arg_19_0.heroIndex]

				audio.playSound(var_0_5:getSound(var_20_0))
				arg_19_0.hero:setVelocity({
					x = 0,
					y = var_0_7
				})
				arg_19_0.hero:getNode():getChildByName("effect"):play(nil, false, nil, "click")
			end

			arg_19_0.click = arg_19_0.count
		end

		return true
	end)
end

function var_0_0.addSchedule(arg_21_0)
	arg_21_0.handle = var_0_2.scheduleUpdateGlobal(handler(arg_21_0, arg_21_0.loop))
end

function var_0_0.loop(arg_22_0)
	arg_22_0.count = arg_22_0.count + 1
	arg_22_0.blockCreateCount = arg_22_0.blockCreateCount + 1

	if arg_22_0.blockCreateCount >= var_0_29 then
		arg_22_0.blockCreateCount = 0

		arg_22_0:addBlock()
	end

	if arg_22_0.count % var_0_20 == 0 then
		arg_22_0:updateGameSpeed()
	end

	if arg_22_0.count % 30 == 1 then
		arg_22_0:checkBg()
	end

	arg_22_0:heroLoop()
end

function var_0_0.addBlock(arg_23_0)
	arg_23_0.blockCount = arg_23_0.blockCount + 1

	local var_23_0 = display.newNode()
	local var_23_1 = var_0_17 + math.floor(math.random(var_0_33))

	if arg_23_0.lastBlockHeight then
		if arg_23_0.lastBlockHeight > var_23_1 + var_0_37 then
			var_23_1 = arg_23_0.lastBlockHeight - var_0_37
		elseif arg_23_0.lastBlockHeight < var_23_1 - var_0_37 then
			var_23_1 = arg_23_0.lastBlockHeight + var_0_37
		end
	end

	arg_23_0.lastBlockHeight = var_23_1

	local var_23_2 = var_0_16
	local var_23_3 = var_23_1
	local var_23_4 = display.newRect(cc.rect(0, 0, var_23_2, var_23_3), {
		borderWidth = 3,
		fillColor = cc.c4f(255, 0, 0, 0),
		borderColor = cc.c4f(1, 111, 1, 0)
	})
	local var_23_5 = cc.PhysicsBody:createBox({
		width = var_23_2,
		height = var_23_3
	}, cc.PhysicsMaterial(0.1, 0, 0), {
		x = var_23_2 / 2,
		y = var_23_3 / 2
	})

	var_23_5:setCategoryBitmask(var_0_13)
	var_23_5:setContactTestBitmask(var_0_12)
	var_23_5:setCollisionBitmask(0)
	var_23_5:setGravityEnable(false)
	var_23_5:setVelocity({
		y = 0,
		x = -var_0_22
	})
	var_23_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_23_4:setPhysicsBody(var_23_5)
	var_23_4:setPosition(xyd.STAGE_WIDTH + var_0_16 / 2 + 20, 0)
	var_23_4:addTo(var_23_0)
	var_23_4:setName("block")

	local var_23_6 = math.ceil(math.random(4))
	local var_23_7 = "windows/flappy_bird/block_" .. var_23_6 .. ".png"
	local var_23_8 = xyd.AssetLoader.get():loadSprite(var_23_7)

	var_23_8:setAnchorPoint(cc.p(0.5, 1))
	var_23_8:addTo(var_23_4)
	var_23_8:setPosition(var_0_16 / 2, var_23_3)

	local var_23_9 = 720 - var_23_1 - var_0_30
	local var_23_10 = display.newRect(cc.rect(0, 0, var_23_2, var_23_9), {
		borderWidth = 3,
		fillColor = cc.c4f(255, 0, 0, 0),
		borderColor = cc.c4f(1, 111, 1, 0)
	})
	local var_23_11 = cc.PhysicsBody:createBox({
		width = var_23_2,
		height = var_23_9
	}, cc.PhysicsMaterial(0.1, 0, 0), {
		x = var_23_2 / 2,
		y = var_23_9 / 2
	})

	var_23_11:setCategoryBitmask(var_0_13)
	var_23_11:setContactTestBitmask(var_0_12)
	var_23_11:setCollisionBitmask(0)
	var_23_11:setGravityEnable(false)
	var_23_11:setVelocity({
		y = 0,
		x = -var_0_22
	})
	var_23_10:setAnchorPoint(cc.p(0.5, 0.5))
	var_23_10:setPhysicsBody(var_23_11)
	var_23_10:setPosition(xyd.STAGE_WIDTH + var_0_16 / 2 + 20, var_23_1 + var_0_30)
	var_23_10:addTo(var_23_0)
	var_23_10:setName("block")

	local var_23_12 = xyd.AssetLoader.get():loadSprite(var_23_7)

	var_23_12:setAnchorPoint(cc.p(0.5, 1))
	var_23_12:setScaleY(-1)
	var_23_12:addTo(var_23_10)
	var_23_12:setPosition(var_0_16 / 2, 0)

	local var_23_13 = 4
	local var_23_14 = xyd.STAGE_HEIGHT
	local var_23_15 = display.newRect(cc.rect(0, 0, var_23_13, var_23_14), {
		borderWidth = 3,
		fillColor = cc.c4f(255, 0, 0, 100),
		borderColor = cc.c4f(1, 111, 1, 100)
	})
	local var_23_16 = cc.PhysicsBody:createBox({
		width = var_23_13,
		height = var_23_14
	}, cc.PhysicsMaterial(0.1, 0, 0), {
		x = var_23_13 / 2,
		y = var_23_14 / 2
	})

	var_23_16:setCategoryBitmask(var_0_14)
	var_23_16:setContactTestBitmask(var_0_14)
	var_23_16:setCollisionBitmask(0)
	var_23_16:setGravityEnable(false)
	var_23_16:setVelocity({
		y = 0,
		x = -var_0_22
	})
	var_23_15:setAnchorPoint(cc.p(0.5, 0.5))
	var_23_15:setPhysicsBody(var_23_16)
	var_23_15:setPosition(xyd.STAGE_WIDTH + var_0_16 + 20, 0)
	var_23_15:addTo(var_23_0)
	var_23_15:setName("scoreBox")
	var_23_15:setVisible(false)

	local var_23_17
	local var_23_18

	if (arg_23_0.blockCount - var_0_10) % var_0_19 == 0 then
		var_23_17 = "windows/flappy_bird/item_heart.png"
		var_23_18 = var_0_54
		var_0_10 = arg_23_0.blockCount
		var_0_19 = var_0_19 + var_0_25
	elseif xyd.weightedChoise({
		var_0_46,
		1 - var_0_46
	}) == 1 then
		if arg_23_0.heroIndex == var_0_57.Crystal and arg_23_0.buffCount > 0 or xyd.weightedChoise({
			var_0_18,
			1 - var_0_18
		}) == 1 then
			var_23_17 = "windows/flappy_bird/item_crystal.png"
			var_23_18 = var_0_56
		else
			var_23_17 = "windows/flappy_bird/item_gold.png"
			var_23_18 = var_0_55
		end
	end

	if var_23_17 then
		local var_23_19 = xyd.AssetLoader.get():loadSprite(var_23_17)
		local var_23_20 = var_23_19:getWidth()
		local var_23_21 = var_23_19:getHeight()
		local var_23_22 = cc.PhysicsBody:createBox({
			width = var_23_20,
			height = var_23_21
		}, cc.PhysicsMaterial(0.1, 0, 0))

		var_23_22:setCategoryBitmask(var_0_14)
		var_23_22:setContactTestBitmask(var_0_14)
		var_23_22:setCollisionBitmask(0)
		var_23_22:setGravityEnable(false)
		var_23_22:setVelocity({
			y = 0,
			x = -var_0_22
		})
		var_23_19:setAnchorPoint(cc.p(0.5, 0.5))
		var_23_19:setPhysicsBody(var_23_22)

		local var_23_23 = xyd.weightedChoise({
			0.5,
			0.5
		}) == 1 and 1 or -1
		local var_23_24 = xyd.weightedChoise({
			0.5,
			0.5
		}) == 1 and 1 or -1

		var_23_19:setPosition(xyd.STAGE_WIDTH + var_0_16 + 20 + var_23_23 * math.random(var_0_16 / 2) * var_0_40, var_23_1 + var_0_30 / 2 + var_23_24 * math.random(var_0_30 / 2) * var_0_41)
		var_23_19:addTo(var_23_0)
		var_23_19:setName("item")
		var_23_19:setTag(var_23_18)
	end

	var_23_0:addTo(arg_23_0, -10)
	var_23_0:setName("blockNode")
	table.insert(arg_23_0.blockNodes, var_23_0)
end

function var_0_0.checkBg(arg_24_0)
	for iter_24_0, iter_24_1 in ipairs(arg_24_0.bgNode) do
		local var_24_0 = iter_24_1:getChildByName("pic1"):getWidth()

		if iter_24_1:getPositionX() + (arg_24_0.bgCount[iter_24_0] + 1) * var_24_0 < 0 then
			arg_24_0:addBgPic(iter_24_1)

			arg_24_0.bgCount[iter_24_0] = arg_24_0.bgCount[iter_24_0] + 1
		end
	end
end

function var_0_0.addContactListener(arg_25_0)
	local function var_25_0(arg_26_0)
		local var_26_0 = arg_26_0:getShapeA():getBody():getNode()
		local var_26_1 = arg_26_0:getShapeB():getBody():getNode()

		if var_26_0 and var_26_1 and not tolua.isnull(var_26_0) and not tolua.isnull(var_26_1) then
			local var_26_2 = display.getRunningScene()

			var_26_2:isCollision(var_26_0, var_26_1, "edge", "hero")

			if var_26_2:isCollision(var_26_0, var_26_1, "edge", "hero") then
				var_26_2:edgeContact()
			elseif var_26_2:isCollision(var_26_0, var_26_1, "block", "hero") then
				var_26_2:blockContact(false)
			elseif var_26_2:isCollision(var_26_0, var_26_1, "top", "hero") then
				var_26_2:blockContact(true)
			elseif var_26_2:isCollision(var_26_0, var_26_1, "scoreBox", "hero") then
				if var_26_2.heroIndex == var_0_57.DoubleScore and var_26_2.buffCount > 0 then
					var_26_2:addScore(150)
				else
					var_26_2:addScore(100)
				end

				var_26_2:record("cross_num", 1)
			elseif var_26_2:isCollision(var_26_0, var_26_1, "item", "hero") then
				var_26_2:getItem(var_26_0, var_26_1)
			elseif var_26_0:getName() == "removeEdege" then
				var_26_2:removeBlock(var_26_1:getParent())
			elseif var_26_1:getName() == "removeEdege" then
				var_26_2:removeBlock(var_26_0:getParent())
			end
		end

		return false
	end

	local var_25_1 = cc.EventListenerPhysicsContact:create()

	var_25_1:registerScriptHandler(var_25_0, cc.Handler.EVENT_PHYSICS_CONTACT_BEGIN)
	arg_25_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(var_25_1, arg_25_0)
end

function var_0_0.isCollision(arg_27_0, arg_27_1, arg_27_2, arg_27_3, arg_27_4)
	if arg_27_1:getName() == arg_27_3 and arg_27_2:getName() == arg_27_4 or arg_27_1:getName() == arg_27_4 and arg_27_2:getName() == arg_27_3 then
		return true
	end

	return false
end

function var_0_0.edgeContact(arg_28_0, arg_28_1)
	arg_28_0:heroDie(arg_28_1)
	arg_28_0.world:setGravity(cc.vec2(0, -98))
	arg_28_0.hero:setVelocity({
		x = 0,
		y = 0
	})
	arg_28_0:gameResult()

	local var_28_0 = "flappy_youxijieshu"

	audio.playSound(var_0_5:getSound(var_28_0))
end

function var_0_0.blockContact(arg_29_0, arg_29_1)
	if not arg_29_1 then
		if arg_29_0.isImmortal then
			return
		end

		if arg_29_0.heroIndex == var_0_57.Wudi and arg_29_0.buffCount > 0 then
			return
		elseif arg_29_0.heroIndex == var_0_57.Shield and arg_29_0.buffCount > 0 then
			arg_29_0:removeHeroBuff()

			return
		else
			arg_29_0:updateHp(arg_29_0.hp - 1)

			local var_29_0 = "flappy_pengzhuang"

			audio.playSound(var_0_5:getSound(var_29_0))

			if arg_29_0.hp > 0 then
				arg_29_0.isImmortal = true

				local var_29_1 = cc.Sequence:create({
					cc.FadeOut:create(0.5),
					cc.FadeIn:create(0.5),
					cc.FadeOut:create(0.5),
					cc.FadeIn:create(0.5),
					cc.FadeOut:create(0.5),
					cc.FadeIn:create(0.5),
					cc.CallFunc:create(function()
						if tolua.isnull(arg_29_0) then
							return
						end

						arg_29_0.isImmortal = false
					end)
				})

				arg_29_0.hero:getNode():runActionOnce(var_29_1)

				return
			end
		end
	end

	arg_29_0:heroDie()
end

function var_0_0.removeBlock(arg_31_0, arg_31_1)
	local var_31_0 = table.indexof(arg_31_0.blockNodes, arg_31_1)

	table.remove(arg_31_0.blockNodes, var_31_0)
	arg_31_1:removeSelf()
end

function var_0_0.heroDie(arg_32_0, arg_32_1)
	if not arg_32_0.gameOver then
		arg_32_0.gameOver = true

		if arg_32_0.handle then
			var_0_2.unscheduleGlobal(arg_32_0.handle)

			arg_32_0.handle = nil
		end

		for iter_32_0, iter_32_1 in ipairs(arg_32_0.blockNodes) do
			local var_32_0 = iter_32_1:getChildren()

			for iter_32_2, iter_32_3 in ipairs(var_32_0) do
				iter_32_3:getPhysicsBody():setVelocity({
					x = 0,
					y = 0
				})
			end
		end

		arg_32_0.nearBgNode:stopAllActions()
		arg_32_0.centerBgNode:stopAllActions()
		arg_32_0.farBgNode:stopAllActions()

		if not arg_32_1 then
			arg_32_0.hero:setVelocity({
				x = 0,
				y = var_0_8
			})

			local var_32_1 = arg_32_0.hero:getNode():getChildByName("effect")

			var_32_1:play(function()
				var_32_1:play(nil, true, nil, "die02")
			end, false, nil, "die01")
		end

		arg_32_0:removeHeroBuff()
	end
end

function var_0_0.initBackground(arg_34_0)
	arg_34_0.nearBgNode = display.newNode()

	arg_34_0.nearBgNode:addTo(arg_34_0, 11)

	arg_34_0.centerBgNode = display.newNode()

	arg_34_0.centerBgNode:addTo(arg_34_0, -12)

	arg_34_0.farBgNode = display.newNode()

	arg_34_0.farBgNode:addTo(arg_34_0, -13)
	arg_34_0:initBgNode(arg_34_0.nearBgNode, "near", 1)
	arg_34_0:initBgNode(arg_34_0.centerBgNode, "center", 2)
	arg_34_0:initBgNode(arg_34_0.farBgNode, "far", 3)
end

function var_0_0.initBgNode(arg_35_0, arg_35_1, arg_35_2, arg_35_3)
	if not arg_35_0.bgCount then
		arg_35_0.bgCount = {
			0,
			0,
			0
		}
		arg_35_0.bgNode = {}
	end

	table.insert(arg_35_0.bgNode, arg_35_1)

	local var_35_0 = xyd.AssetLoader.get():loadSprite("windows/flappy_bird/" .. arg_35_2 .. ".png")

	var_35_0:setAnchorPoint(cc.p(0, 0))
	var_35_0:setName("pic1")
	var_35_0:addTo(arg_35_1)

	local var_35_1 = var_35_0:clone()

	var_35_1:setName("pic2")
	var_35_1:addTo(arg_35_1)
	var_35_1:setPositionX(var_35_0:getPositionX() + var_35_0:getWidth())

	local var_35_2 = var_35_0:getWidth() / var_0_34[arg_35_3]

	arg_35_1:runAction(cc.RepeatForever:create(cc.MoveBy:create(var_35_2, cc.p(-var_35_0:getWidth(), 0))))
end

function var_0_0.addBgPic(arg_36_0, arg_36_1, arg_36_2)
	local var_36_0 = arg_36_1:getChildByName("pic1")
	local var_36_1 = arg_36_1:getChildByName("pic2")

	var_36_0:removeSelf()
	var_36_1:setName("pic1")

	local var_36_2 = var_36_1:clone()

	var_36_2:addTo(arg_36_1)
	var_36_2:setPositionX(var_36_1:getPositionX() + var_36_1:getWidth())
	var_36_2:setName("pic2")
end

function var_0_0.updateGameSpeed(arg_37_0)
	var_0_22 = math.min(var_0_22 + var_0_24, var_0_23)
	var_0_26 = math.max(var_0_26 + var_0_28, var_0_27)
	var_0_29 = math.ceil(var_0_26 / var_0_22 * 30)

	for iter_37_0, iter_37_1 in ipairs(arg_37_0.blockNodes) do
		local var_37_0 = iter_37_1:getChildren()

		for iter_37_2, iter_37_3 in ipairs(var_37_0) do
			iter_37_3:getPhysicsBody():setVelocity({
				y = 0,
				x = -var_0_22
			})
		end
	end

	var_0_30 = math.max(var_0_30 + var_0_32, var_0_31)
	var_0_33 = xyd.STAGE_HEIGHT - 2 * var_0_17 - var_0_30

	for iter_37_4 = 1, 3 do
		var_0_34[iter_37_4] = math.min(var_0_34[iter_37_4] + var_0_36[iter_37_4], var_0_35[iter_37_4])

		local var_37_1 = arg_37_0.bgNode[iter_37_4]
		local var_37_2 = var_37_1:getChildByName("pic1")
		local var_37_3 = var_37_2:getWidth() / var_0_34[iter_37_4]

		var_37_1:stopAllActions()
		var_37_1:runAction(cc.RepeatForever:create(cc.MoveBy:create(var_37_3, cc.p(-var_37_2:getWidth(), 0))))
	end

	var_0_37 = math.max(var_0_37 + var_0_38, var_0_39)
	var_0_40 = math.max(var_0_40 + var_0_42, var_0_44)
	var_0_41 = math.max(var_0_41 + var_0_43, var_0_45)
	var_0_46 = math.min(var_0_46 + var_0_48, var_0_47)
end

function var_0_0.getItem(arg_38_0, arg_38_1, arg_38_2)
	local var_38_0

	if arg_38_1:getName() == "item" then
		var_38_0 = arg_38_1
	else
		var_38_0 = arg_38_2
	end

	if not arg_38_0.itemEffect then
		local var_38_1 = "skeletons/ui_effect/flappy_bird/fx_daoju"

		arg_38_0.itemEffect = xyd.createEffect(var_38_1)

		arg_38_0.itemEffect:setScale(2)
		arg_38_0.itemEffect:addTo(arg_38_0)
	end

	if var_38_0:getTag() == var_0_54 then
		arg_38_0:updateHp(math.min(arg_38_0.hp + 1, var_0_9))

		local var_38_2 = "flappy_shengming"

		audio.playSound(var_0_5:getSound(var_38_2))
	elseif var_38_0:getTag() == var_0_55 then
		arg_38_0:addScore(200)
		arg_38_0.itemEffect:setPosition(var_38_0:getPosition())
		arg_38_0.itemEffect:stopAllActions()
		arg_38_0.itemEffect:runActionOnce(cc.MoveBy:create(1, cc.p(-var_0_22, 0)))
		arg_38_0.itemEffect:play(nil, false, nil, "texiao01")
		arg_38_0:record("coin", 1)

		local var_38_3 = "flappy_jinbi"

		audio.playSound(var_0_5:getSound(var_38_3))
	elseif var_38_0:getTag() == var_0_56 then
		arg_38_0:addScore(400)
		arg_38_0.itemEffect:setPosition(var_38_0:getPosition())
		arg_38_0.itemEffect:stopAllActions()
		arg_38_0.itemEffect:runActionOnce(cc.MoveBy:create(1, cc.p(-var_0_22, 0)))
		arg_38_0.itemEffect:play(nil, false, nil, "texiao02")
		arg_38_0:record("crystal", 1)

		local var_38_4 = "flappy_zuanshi"

		audio.playSound(var_0_5:getSound(var_38_4))
	end

	var_38_0:removeSelf()
end

function var_0_0.heroLoop(arg_39_0)
	if arg_39_0.buffCount > 0 then
		arg_39_0.buffCount = arg_39_0.buffCount - 1

		if arg_39_0.buffCount == var_0_21 then
			arg_39_0:buffTip()
		elseif arg_39_0.buffCount == 0 then
			arg_39_0:removeHeroBuff()
		end
	end

	if arg_39_0.buffCD > 0 then
		arg_39_0.buffCD = arg_39_0.buffCD - 1

		if not arg_39_0.progressBar:isVisible() then
			local var_39_0 = arg_39_0.buffCD / 30

			arg_39_0.progressBar:setVisible(true)
			arg_39_0.progressBar:runActionOnce(cc.ProgressTo:create(var_39_0, 100))
		end

		if arg_39_0.buffCD == 0 then
			arg_39_0.progressBar:setVisible(false)
			arg_39_0.progressBar:runActionOnce(cc.ProgressTo:create(0.1, 0))
			arg_39_0:updateSkillBtn(true, true)
		end
	end
end

function var_0_0.addHeroBuff(arg_40_0)
	arg_40_0:record("skill_num", 1)

	arg_40_0.buffCount = var_0_4:buffTime(arg_40_0.skillID)
	arg_40_0.buffCD = var_0_4:skillCD(arg_40_0.skillID)

	arg_40_0:updateSkillBtn(false)

	local var_40_0 = arg_40_0.hero:getNode()
	local var_40_1 = var_0_4:buff(arg_40_0.skillID)
	local var_40_2 = var_0_4:buffScale(arg_40_0.skillID)
	local var_40_3 = var_0_4:buffOffset(arg_40_0.skillID)
	local var_40_4 = xyd.createEffect(var_40_1 .. "1")
	local var_40_5 = xyd.createEffect(var_40_1 .. "2")

	var_40_4:addTo(var_40_0)
	var_40_4:setScale(var_40_2[1])
	var_40_4:setPosition(var_40_3[1], var_40_3[2])
	var_40_4:setName("buff1")
	var_40_4:play(nil, false, nil, "texiao")
	var_40_5:addTo(var_40_0)
	var_40_5:setScale(var_40_2[2])
	var_40_5:setPosition(var_40_3[3], var_40_3[4])
	var_40_5:setName("buff2")
	var_40_5:play(nil, true, nil, "texiao")

	local var_40_6 = "flappy_shifangjineng"

	audio.playSound(var_0_5:getSound(var_40_6))
end

function var_0_0.removeHeroBuff(arg_41_0)
	arg_41_0.buffCount = 0

	local var_41_0 = arg_41_0.hero:getNode()

	if var_41_0:getChildByName("buff1") then
		var_41_0:getChildByName("buff1"):removeSelf()
	end

	if var_41_0:getChildByName("buff2") then
		var_41_0:getChildByName("buff2"):removeSelf()
	end

	if arg_41_0.heroIndex == var_0_57.Shield then
		arg_41_0.isImmortal = true

		local var_41_1 = cc.Sequence:create({
			cc.DelayTime:create(1),
			cc.CallFunc:create(function()
				if tolua.isnull(arg_41_0) then
					return
				end

				arg_41_0.isImmortal = false
			end)
		})

		arg_41_0.hero:getNode():runActionOnce(var_41_1)
	end
end

function var_0_0.buffTip(arg_43_0)
	local var_43_0 = arg_43_0.hero:getNode()

	if var_43_0:getChildByName("buff1") then
		local var_43_1 = cc.Sequence:create({
			cc.FadeOut:create(0.5),
			cc.FadeIn:create(0.5),
			cc.FadeOut:create(0.5),
			cc.FadeIn:create(0.5)
		})

		var_43_0:getChildByName("buff1"):runActionOnce(var_43_1)
	end

	if var_43_0:getChildByName("buff2") then
		local var_43_2 = cc.Sequence:create({
			cc.FadeOut:create(0.5),
			cc.FadeIn:create(0.5),
			cc.FadeOut:create(0.5),
			cc.FadeIn:create(0.5)
		})

		var_43_0:getChildByName("buff2"):runActionOnce(var_43_2)
	end
end

function var_0_0.gameResult(arg_44_0)
	if not arg_44_0.isPractice then
		local var_44_0 = {
			hero_idx = arg_44_0.heroIndex,
			score = arg_44_0.score or 0,
			cross_num = arg_44_0.data.cross_num or 0,
			skill_num = arg_44_0.data.skill_num or 0,
			coin = arg_44_0.data.coin or 0
		}

		arg_44_0.flappyBird:endGame(var_44_0, function()
			xyd.WindowManager.get():openWindow("flappy_bird_result", {
				score = arg_44_0.score
			})
		end)
	else
		xyd.WindowManager.get():openWindow("flappy_bird_result", {
			score = arg_44_0.score
		})
	end
end

function var_0_0.addScore(arg_46_0, arg_46_1)
	arg_46_0.score = arg_46_0.score + arg_46_1

	arg_46_0.scoreLabel:setString(arg_46_0.score)
end

function var_0_0.record(arg_47_0, arg_47_1, arg_47_2)
	if not arg_47_0.data[arg_47_1] then
		arg_47_0.data[arg_47_1] = 0
	end

	arg_47_0.data[arg_47_1] = arg_47_0.data[arg_47_1] + arg_47_2
end

function var_0_0.onEnter(arg_48_0)
	audio.stopAllSounds()
	audio.stopMusic()

	local var_48_0 = xyd.tables.sound:getSound("flappy_bgm")

	audio.playMusic(var_48_0, true)
	arg_48_0:init()
end

function var_0_0.onExit(arg_49_0)
	audio.stopAllSounds()
	audio.stopMusic()

	local var_49_0 = xyd.tables.sound:getSound("home_bg_music")

	audio.playMusic(var_49_0, true)

	if arg_49_0.handle then
		var_0_2.unscheduleGlobal(arg_49_0.handle)

		arg_49_0.handle = nil
	end
end

return var_0_0
