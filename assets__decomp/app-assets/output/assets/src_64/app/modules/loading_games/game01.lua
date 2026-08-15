require("config")
require("cocos.init")
require("framework.init")

local var_0_0 = require("framework.scheduler")
local var_0_1 = "fonts/main_font.ttf"
local var_0_2 = {}
local var_0_3 = 1280
local var_0_4 = 720
local var_0_5 = 300
local var_0_6 = 150
local var_0_7 = 500
local var_0_8 = 0.05
local var_0_9 = 0.25
local var_0_10 = 0.5
local var_0_11 = 4
local var_0_12 = {
	0,
	330,
	580,
	800,
	1100,
	1210,
	1310,
	1530,
	1650,
	1760,
	1880,
	1990
}
local var_0_13 = {
	5,
	3,
	1,
	3,
	1,
	1
}
local var_0_14 = {
	110,
	180,
	220,
	290,
	330
}
local var_0_15 = {
	BRIDGE_GROW = 1,
	MOVE_FORWARD = 3,
	IDLE = 5,
	BRIDGE_ROTATION = 2,
	FALL = 4
}

function var_0_2.get(arg_1_0)
	if not var_0_2.INSTANCE then
		var_0_2.INSTANCE = setmetatable({}, {
			__index = var_0_2
		})
	end

	return var_0_2.INSTANCE
end

function var_0_2.init(arg_2_0)
	display.addSpriteFrames("images/loading_games/loading_games.plist", "images/loading_games/loading_games.png")

	arg_2_0.__layer = cc.Node:create()

	arg_2_0.__layer:setContentSize({
		width = var_0_3,
		height = var_0_4
	})

	arg_2_0.__bg = arg_2_0:newSprite("images/loading_games/game_bg.png")

	arg_2_0.__bg:setAnchorPoint({
		x = 0,
		y = 0
	})
	arg_2_0.__bg:setPosition(0, 0)
	arg_2_0.__layer:addChild(arg_2_0.__bg)

	arg_2_0.__tip = arg_2_0:newSprite("images/loading_games/show_tip.png")

	arg_2_0.__tip:align(display.CENTER, var_0_3 / 2, var_0_4 - 60)
	arg_2_0.__layer:addChild(arg_2_0.__tip)

	arg_2_0.__labelBack = arg_2_0:newSprite("images/loading_games/label_back.png")

	arg_2_0.__layer:addChild(arg_2_0.__labelBack)
	arg_2_0.__labelBack:pos(1180, 700)
	arg_2_0:prepareScoreLabel()
	arg_2_0:setupScreen()
	arg_2_0:setTouchEvent()

	arg_2_0.__recordScore = 0
end

function var_0_2.clear(arg_3_0)
	var_0_0.unscheduleGlobal(arg_3_0.__scheduler)
	arg_3_0.__bridgeSp:height(50)

	arg_3_0.__scheduler = nil
	arg_3_0.__model = nil

	arg_3_0:getFloors():removeSelf()

	arg_3_0.__floorNode = nil
	arg_3_0.__floor1 = nil
	arg_3_0.__floor2 = nil
	arg_3_0.__fallWall = nil
	arg_3_0.modleState_ = nil
	arg_3_0.__state = nil
end

function var_0_2.setupGame(arg_4_0)
	arg_4_0:initFloors()
	arg_4_0:newFloors()

	arg_4_0.__bridgeSp = ccui.Scale9Sprite:createWithSpriteFrameName("images/loading_games/bridge1.png", {
		width = 18,
		height = 44,
		x = 3,
		y = 3
	})

	arg_4_0.__bridgeSp:align(display.CENTER_BOTTOM, (var_0_12[2] + var_0_12[1]) / 2, 203)
	arg_4_0.__bridgeSp:height(var_0_7)

	arg_4_0.__bridgePosition = {
		(var_0_12[2] + var_0_12[1]) / 2,
		(var_0_12[2] + var_0_12[1]) / 2 + var_0_7
	}

	arg_4_0.__bridgeSp:addTo(arg_4_0:getFloors(), 2)
end

function var_0_2.play(arg_5_0)
	math.randomseed(os.time())
	arg_5_0:setupGame()
	arg_5_0:modleIdle()

	arg_5_0.__angularVelocity = 0
	arg_5_0.__speedX = 0
	arg_5_0.__speedY = 0
	arg_5_0.__score = 0

	arg_5_0.__scoreLabel:setString(arg_5_0.__score)

	arg_5_0.__state = var_0_15.BRIDGE_ROTATION
	arg_5_0.__scheduler = var_0_0.scheduleUpdateGlobal(handler(arg_5_0, arg_5_0.loop))
end

function var_0_2.loop(arg_6_0)
	if arg_6_0.__state == var_0_15.BRIDGE_GROW then
		local var_6_0 = math.min(arg_6_0.__bridgeSp:getHeight() + 25, var_0_7)

		arg_6_0.__bridgeSp:height(var_6_0)
	elseif arg_6_0.__state == var_0_15.BRIDGE_ROTATION then
		arg_6_0.__angularVelocity = arg_6_0.__angularVelocity + var_0_8

		local var_6_1 = arg_6_0.__bridgeSp:getRotation() + arg_6_0.__angularVelocity

		if var_6_1 > 90 then
			var_6_1 = 90
			arg_6_0.__angularVelocity = arg_6_0.__angularVelocity > 1 and (0 - arg_6_0.__angularVelocity) / 5 or 0
		end

		arg_6_0.__bridgeSp:rotation(var_6_1)

		if arg_6_0.__angularVelocity >= 0 and arg_6_0.__angularVelocity < 1 and var_6_1 == 90 then
			arg_6_0.__state = var_0_15.MOVE_FORWARD

			arg_6_0:modleWalk()
		end
	elseif arg_6_0.__state == var_0_15.MOVE_FORWARD then
		arg_6_0.__speedX = arg_6_0.__speedX + var_0_9
		arg_6_0.__speedX = arg_6_0.__speedX > var_0_11 and var_0_11 or arg_6_0.__speedX

		arg_6_0:getFloors():x(arg_6_0:getFloors():getX() - arg_6_0.__speedX)
		arg_6_0:model():x(arg_6_0:model():getX() + arg_6_0.__speedX)
		arg_6_0:updateFloors()

		arg_6_0.__score = arg_6_0.__score + arg_6_0.__speedX

		if arg_6_0.__score % 10 < 1 and arg_6_0.__score > 10 then
			arg_6_0.__scoreLabel:setString(arg_6_0.__score)
		end

		if arg_6_0:isToFall() then
			arg_6_0:modleIdle()

			arg_6_0.__state = var_0_15.FALL
		elseif arg_6_0:isToStop() then
			arg_6_0:modleIdle()
			arg_6_0.__bridgeSp:rotation(0)
			arg_6_0.__bridgeSp:height(50)
			arg_6_0.__bridgeSp:x(arg_6_0:model():getX())

			arg_6_0.__state = var_0_15.IDLE
		end
	elseif arg_6_0.__state == var_0_15.FALL then
		arg_6_0.__speedY = arg_6_0.__speedY + var_0_10
		arg_6_0.__speedX = arg_6_0:model():getX() < arg_6_0.__fallWall and arg_6_0.__speedX or 0

		arg_6_0:model():pos(arg_6_0:model():getX() + arg_6_0.__speedX, arg_6_0:model():getY() - arg_6_0.__speedY)

		if arg_6_0:model():getY() < -500 then
			arg_6_0:gameEnd()
		end
	elseif arg_6_0.__state == var_0_15.IDLE then
		-- block empty
	end
end

function var_0_2.model(arg_7_0)
	if not arg_7_0.__model then
		local var_7_0 = "skeletons/liru/liru.json"
		local var_7_1 = "skeletons/liru/liru.atlas"

		arg_7_0.__model = sp.SkeletonAnimation:create(var_7_0, var_7_1, 1)

		arg_7_0:getFloors():addChild(arg_7_0.__model)
		arg_7_0.__model:setLocalZOrder(1)
		arg_7_0.__model:setPosition(200, 203)
	end

	return arg_7_0.__model
end

function var_0_2.modleIdle(arg_8_0)
	if arg_8_0.modleState_ == "idle" then
		return
	end

	arg_8_0:model():setToSetupPose()
	arg_8_0:model():setAnimation(0, "idle", true)

	arg_8_0.modleState_ = "idle"
end

function var_0_2.modleWalk(arg_9_0)
	if arg_9_0.modleState_ == "walk" then
		return
	end

	arg_9_0:model():setToSetupPose()
	arg_9_0:model():setAnimation(0, "run", true)

	arg_9_0.modleState_ = "walk"
end

function var_0_2.setParent(arg_10_0, arg_10_1)
	if not arg_10_0.__layer then
		return
	end

	arg_10_0.__layer:addTo(arg_10_1)

	local var_10_0 = arg_10_1:getContentSize()

	arg_10_0.__layer:align(display.CENTER, var_10_0.width / 2, var_10_0.height / 2)
	print(var_10_0.width, var_10_0.height)
end

function var_0_2.setTouchEvent(arg_11_0)
	arg_11_0.__bg:setTouchEnabled(true)
	arg_11_0.__bg:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
		if arg_12_0.name == "began" and arg_11_0.__state == var_0_15.IDLE then
			arg_11_0.__state = var_0_15.BRIDGE_GROW
		elseif arg_12_0.name == "ended" and arg_11_0.__state == var_0_15.BRIDGE_GROW then
			arg_11_0.__state = var_0_15.BRIDGE_ROTATION

			local var_12_0 = arg_11_0.__bridgeSp:getScaleY() * arg_11_0.__bridgeSp:getHeight()

			arg_11_0.__bridgePosition = {
				arg_11_0.__bridgeSp:getX(),
				arg_11_0.__bridgeSp:getX() + var_12_0
			}
		end

		return true
	end)
end

function var_0_2.getFloors(arg_13_0)
	return arg_13_0.__floorNode
end

function var_0_2.initFloors(arg_14_0)
	arg_14_0.__floorNode = cc.Node:create()

	arg_14_0.__floorNode:align(display.LEFT_BOTTOM, 0, 0)
	arg_14_0.__floorNode:addTo(arg_14_0.__layer)

	arg_14_0.__floor1 = cc.Node:create()

	arg_14_0.__floor1:align(display.LEFT_BOTTOM, 0, 0)
	arg_14_0.__floor1:addTo(arg_14_0.__floorNode)

	arg_14_0.__floorXY1 = var_0_12
	arg_14_0.__floorSP1 = var_0_13

	for iter_14_0, iter_14_1 in ipairs(var_0_13) do
		local var_14_0 = arg_14_0:newSprite("images/loading_games/floor" .. iter_14_1 .. ".png")

		var_14_0:align(display.LEFT_BOTTOM, arg_14_0.__floorXY1[2 * iter_14_0 - 1], 0)
		arg_14_0.__floor1:addChild(var_14_0)
	end
end

function var_0_2.updateFloors(arg_15_0)
	if arg_15_0.__floorXY1[12] + arg_15_0.__floor1:getX() + arg_15_0:getFloors():getX() <= 0 then
		arg_15_0.__floor1:removeSelf()

		arg_15_0.__floor1 = arg_15_0.__floor2
		arg_15_0.__floorXY1 = arg_15_0.__floorXY2
		arg_15_0.__floorSP1 = arg_15_0.__floorSP2

		arg_15_0:newFloors()
	end
end

function var_0_2.newFloors(arg_16_0)
	arg_16_0.__floorXY2 = {}
	arg_16_0.__floorSP2 = {}

	local var_16_0 = cc.Node:create()

	var_16_0:align(display.LEFT_BOTTOM, x, 0)

	for iter_16_0 = 1, 6 do
		local var_16_1 = math.random(var_0_6, var_0_5)
		local var_16_2 = iter_16_0 > 1 and arg_16_0.__floorXY2[2 * iter_16_0 - 2] + var_16_1 or var_16_1

		table.insert(arg_16_0.__floorXY2, var_16_2)

		local var_16_3 = math.random(5)
		local var_16_4 = var_0_14[var_16_3]

		table.insert(arg_16_0.__floorXY2, var_16_2 + var_16_4)
		table.insert(arg_16_0.__floorSP2, var_16_3)
	end

	for iter_16_1, iter_16_2 in ipairs(arg_16_0.__floorSP2) do
		local var_16_5 = arg_16_0:newSprite("images/loading_games/floor" .. iter_16_2 .. ".png")

		var_16_5:align(display.LEFT_BOTTOM, arg_16_0.__floorXY2[2 * iter_16_1 - 1], 0)
		var_16_0:addChild(var_16_5)
	end

	var_16_0:addTo(arg_16_0.__floorNode)
	var_16_0:align(display.CENTER_BOTTOM, arg_16_0.__floor1:getX() + arg_16_0.__floorXY1[12], 0)

	arg_16_0.__floor2 = var_16_0
end

function var_0_2.isToFall(arg_17_0)
	if arg_17_0.__fallWall then
		return true
	end

	local var_17_0 = arg_17_0:model():getX()

	if var_17_0 < arg_17_0.__bridgePosition[2] and var_17_0 > arg_17_0.__bridgePosition[1] then
		return false
	end

	if var_17_0 < arg_17_0.__floor2:getX() then
		local var_17_1 = var_17_0 - arg_17_0.__floor1:getX()

		if var_17_1 < arg_17_0.__floorXY1[1] then
			arg_17_0.__fallWall = arg_17_0.__floorXY1[1] + arg_17_0.__floor1:getX()

			return true
		end

		for iter_17_0 = 1, #arg_17_0.__floorXY1 / 2 - 1 do
			if var_17_1 > arg_17_0.__floorXY1[2 * iter_17_0] and var_17_1 < arg_17_0.__floorXY1[2 * iter_17_0 + 1] then
				arg_17_0.__fallWall = arg_17_0.__floorXY1[2 * iter_17_0 + 1] + arg_17_0.__floor1:getX()

				return true
			end
		end
	else
		local var_17_2 = var_17_0 - arg_17_0.__floor2:getX()

		if var_17_2 < arg_17_0.__floorXY2[1] then
			arg_17_0.__fallWall = arg_17_0.__floorXY2[1] + arg_17_0.__floor2:getX()

			return true
		end

		for iter_17_1 = 1, #arg_17_0.__floorXY2 / 2 - 1 do
			if var_17_2 > arg_17_0.__floorXY2[2 * iter_17_1] and var_17_2 < arg_17_0.__floorXY2[2 * iter_17_1 + 1] then
				arg_17_0.__fallWall = arg_17_0.__floorXY2[2 * iter_17_1 + 1] + arg_17_0.__floor2:getX()

				return true
			end
		end
	end

	return false
end

function var_0_2.isToStop(arg_18_0)
	return arg_18_0:model():getX() >= arg_18_0.__bridgePosition[2]
end

function var_0_2.resetBridge(arg_19_0)
	arg_19_0.__bridgeSp:height(50)
	arg_19_0.__bridgeSp:pos(arg_19_0:model():getPosition())

	arg_19_0.__bridgePosition = {
		(var_0_12[2] + var_0_12[1]) / 2,
		(var_0_12[4] + var_0_12[3]) / 2
	}

	arg_19_0:getFloors():addChild(arg_19_0.__bridgeSp)
end

function var_0_2.gameEnd(arg_20_0)
	arg_20_0.__scoreLabel:setString(arg_20_0.__score)
	arg_20_0:alert(function()
		arg_20_0.__recordScore = math.max(arg_20_0.__score, arg_20_0.__recordScore)

		arg_20_0:clear()
		arg_20_0:play()
	end)
end

function var_0_2.newSprite(arg_22_0, arg_22_1)
	local var_22_0 = "#" .. arg_22_1

	if cc.SpriteFrameCache:getInstance():getSpriteFrame(arg_22_1) ~= nil then
		return display.newSprite(var_22_0)
	end

	return display.newSprite(arg_22_1)
end

function var_0_2.setProgress_(arg_23_0, arg_23_1)
	if arg_23_0.__progressBar == nil then
		arg_23_0.__bottomBack = ccui.Scale9Sprite:createWithSpriteFrameName("images/loading_games/bottom_back1.png", {
			width = 60,
			height = 69,
			x = 20,
			y = 0
		})

		arg_23_0.__bottomBack:size(var_0_3, 70)
		arg_23_0.__bottomBack:addTo(arg_23_0.__layer, 2)
		arg_23_0.__bottomBack:align(display.LEFT_BOTTOM, 0, 0)

		local var_23_0 = arg_23_0:newSprite("images/loading_games/loading_bar.png")

		arg_23_0.__progressBar = cc.ProgressTimer:create(var_23_0)

		arg_23_0.__progressBar:setType(1)
		arg_23_0.__progressBar:setMidpoint({
			x = 0,
			y = 0
		})
		arg_23_0.__progressBar:setBarChangeRate({
			x = 1,
			y = 0
		})
		arg_23_0.__progressBar:setPercentage(0)
		arg_23_0.__progressBar:setAnchorPoint({
			x = 0.5,
			y = 0.5
		})

		arg_23_0.__progressBackground = ccui.Scale9Sprite:createWithSpriteFrameName("images/loading_games/loading_bar_back.png", {
			width = 40,
			height = 24,
			x = 15,
			y = 0
		})

		arg_23_0.__progressBackground:size(var_23_0:getWidth(), var_23_0:getHeight())
		arg_23_0.__progressBackground:addTo(arg_23_0.__layer, 3)
		arg_23_0.__progressBackground:align(display.LEFT_CENTER, 50, 30)
		arg_23_0.__progressBar:pos(var_23_0:getWidth() / 2, var_23_0:getHeight() / 2)
		arg_23_0.__progressBackground:addChild(arg_23_0.__progressBar)
	end

	arg_23_0.__progressBar:setPercentage(arg_23_1 * 100)
end

function var_0_2.prepareScoreLabel(arg_24_0)
	if arg_24_0.__scoreLabel == nil then
		arg_24_0.__scoreLabel = cc.Label:createWithTTF("", var_0_1, 24)

		arg_24_0.__scoreLabel:enableShadow()
		arg_24_0.__scoreLabel:setAnchorPoint({
			x = 0.5,
			y = 0.5
		})
		arg_24_0.__scoreLabel:setPosition({
			x = 75,
			y = 16
		})
		arg_24_0.__scoreLabel:addTo(arg_24_0.__labelBack, 3)
	end
end

function var_0_2.prepareProgressLabel_(arg_25_0)
	if arg_25_0.progressLabel_ == nil then
		arg_25_0.progressLabel_ = cc.Label:createWithTTF("", var_0_1, 24)

		arg_25_0.progressLabel_:enableShadow()
		arg_25_0.progressLabel_:setAnchorPoint({
			x = 0,
			y = 0.5
		})
		arg_25_0.progressLabel_:setPosition({
			x = 1020,
			y = 30
		})
		arg_25_0.progressLabel_:addTo(arg_25_0.__layer, 3)
	end
end

function var_0_2.setDownloadProgressMessage_(arg_26_0, arg_26_1, arg_26_2)
	local var_26_0 = string.format("%.1fM", arg_26_1 / 1024 / 1024)
	local var_26_1 = string.format("%.1fM", arg_26_2 / 1024 / 1024)

	arg_26_0:prepareProgressLabel_()
	arg_26_0.progressLabel_:setString(string.format(__("DOWNLOAD_PROGRESS_GAME"), var_26_0, var_26_1))
end

function var_0_2.setUnzipProgressMessage_(arg_27_0, arg_27_1)
	arg_27_0:prepareProgressLabel_()
	arg_27_0.progressLabel_:setString(__("UNZIP_PROGRESS_GAME"))
end

function var_0_2.setDownloadSpeedMessage_(arg_28_0, arg_28_1, arg_28_2)
	if arg_28_0.downloadSpeedLabel_ == nil then
		arg_28_0.downloadSpeedLabel_ = cc.Label:createWithTTF("", var_0_1, 24)

		arg_28_0.downloadSpeedLabel_:enableShadow()
		arg_28_0.downloadSpeedLabel_:setAnchorPoint({
			x = 1,
			y = 0.5
		})
		arg_28_0.downloadSpeedLabel_:setPosition({
			x = 1260,
			y = 30
		})
		arg_28_0.downloadSpeedLabel_:addTo(arg_28_0.__layer, 3)
	end

	arg_28_0.downloadSpeedLabel_:setVisible(not arg_28_2)
	arg_28_0.downloadSpeedLabel_:setString(string.format("%.2fKB/S", arg_28_1))
end

function var_0_2.beforeDownLoadCompleted(arg_29_0)
	var_0_0.unscheduleGlobal(arg_29_0.__scheduler)

	arg_29_0.__scheduler = nil
end

function var_0_2.downLoadCompleted(arg_30_0, arg_30_1)
	arg_30_0:setProgress_(1)

	if arg_30_0.alertView_ ~= nil then
		arg_30_0.alertView_:release()

		arg_30_0.alertView_ = nil
	end

	arg_30_0.__layer:setVisible(false)

	if arg_30_1 then
		arg_30_1()
	end
end

function var_0_2.alert(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0 = 34
	local var_31_1 = 174
	local var_31_2 = 64
	local var_31_3 = 240
	local var_31_4 = {
		140,
		200,
		170
	}

	if arg_31_0.alertView_ == nil then
		arg_31_0.alertView_ = ccui.Scale9Sprite:createWithSpriteFrameName("images/loading_games/box.png")

		arg_31_0.alertView_:retain()
		arg_31_0.alertView_:size(450, 300)
		arg_31_0.alertView_:align(display.CENTER, var_0_3 / 2, var_0_4 / 2)

		local var_31_5 = arg_31_0:newSprite("images/loading_games/label_end.png")

		var_31_5:addTo(arg_31_0.alertView_)
		var_31_5:align(display.CENTER, 225, 290)

		arg_31_0.alertYesButton_ = ccui.Button:create("images/loading_games/middle_button1.png", "images/loading_games/middle_button2.png", "", 1)

		arg_31_0.alertYesButton_:setContentSize(var_31_1, var_31_2)
		arg_31_0.alertYesButton_:align(display.CENTER, 225, 50)
		arg_31_0.alertView_:addChild(arg_31_0.alertYesButton_)

		local var_31_6 = arg_31_0:newSprite("images/loading_games/label_replay.png")

		var_31_6:addTo(arg_31_0.alertYesButton_)
		var_31_6:align(display.CENTER, var_31_1 / 2, var_31_2 / 2)

		arg_31_0.textLabel1_ = cc.Label:createWithTTF("", var_0_1, 24)

		arg_31_0.textLabel1_:setTextColor({
			g = 92,
			a = 255,
			b = 40,
			r = 147
		})
		arg_31_0.textLabel1_:setAlignment(1, 0)
		arg_31_0.textLabel1_:setWidth(100)
		arg_31_0.textLabel1_:setAnchorPoint({
			x = 0,
			y = 0.5
		})
		arg_31_0.textLabel1_:pos(30, 200)
		arg_31_0.textLabel1_:addTo(arg_31_0.alertView_)

		arg_31_0.textLabel2_ = cc.Label:createWithTTF("", var_0_1, 24)

		arg_31_0.textLabel2_:setTextColor({
			g = 92,
			a = 255,
			b = 40,
			r = 147
		})
		arg_31_0.textLabel2_:setAlignment(1, 0)
		arg_31_0.textLabel2_:setWidth(100)
		arg_31_0.textLabel2_:setAnchorPoint({
			x = 0,
			y = 0.5
		})
		arg_31_0.textLabel2_:pos(30, 140)
		arg_31_0.textLabel2_:addTo(arg_31_0.alertView_)

		arg_31_0.scoreLabel1_ = cc.Label:createWithTTF("", var_0_1, 24)

		arg_31_0.scoreLabel1_:setTextColor({
			g = 187,
			a = 255,
			b = 6,
			r = 200
		})
		arg_31_0.scoreLabel1_:setAlignment(1, 0)
		arg_31_0.scoreLabel1_:setWidth(150)
		arg_31_0.scoreLabel1_:setAnchorPoint({
			x = 0,
			y = 0.5
		})
		arg_31_0.scoreLabel1_:pos(120, 200)
		arg_31_0.scoreLabel1_:addTo(arg_31_0.alertView_)

		arg_31_0.scoreLabel2_ = cc.Label:createWithTTF("", var_0_1, 24)

		arg_31_0.scoreLabel2_:setTextColor({
			g = 187,
			a = 255,
			b = 6,
			r = 200
		})
		arg_31_0.scoreLabel2_:setAlignment(1, 0)
		arg_31_0.scoreLabel2_:setWidth(150)
		arg_31_0.scoreLabel2_:setAnchorPoint({
			x = 0,
			y = 0.5
		})
		arg_31_0.scoreLabel2_:pos(120, 140)
		arg_31_0.scoreLabel2_:addTo(arg_31_0.alertView_)

		arg_31_0.recordSp_ = arg_31_0:newSprite("images/loading_games/new_record.png")

		arg_31_0.recordSp_:align(display.LEFT_CENTER, 300, 200)
		arg_31_0.recordSp_:addTo(arg_31_0.alertView_)
	end

	if arg_31_0.alertView_:getParent() == nil then
		arg_31_0.__layer:addChild(arg_31_0.alertView_, 3)
	else
		return
	end

	arg_31_2 = arg_31_2 or {}

	local function var_31_7(arg_32_0)
		if arg_31_2.skipClose then
			if arg_31_1 ~= nil then
				arg_31_1(arg_32_0)
			end

			return
		end

		if arg_31_0.alertView_ ~= nil and arg_31_0.alertView_:getParent() ~= nil then
			arg_31_0.alertView_:runAction(cc.Sequence:create({
				cc.EaseBackIn:create(cc.ScaleTo:create(0.3, 0)),
				cc.CallFunc:create(function()
					arg_31_0.alertView_:removeFromParent()

					if arg_31_1 ~= nil then
						arg_31_1(arg_32_0)
					end
				end)
			}))
		end
	end

	arg_31_0.alertYesButton_:addTouchEventListener(function(arg_34_0, arg_34_1)
		if arg_34_1 == 2 then
			var_31_7(true)
		end
	end)
	arg_31_0.textLabel1_:setString(__("CURRENT_SCORE"))
	arg_31_0.textLabel2_:setString(__("RECORD_SCORE"))
	arg_31_0.scoreLabel1_:setString(arg_31_0.__score)
	arg_31_0.scoreLabel2_:setString(arg_31_0.__recordScore)
	arg_31_0.textLabel2_:setVisible(arg_31_0.__recordScore > 0)
	arg_31_0.scoreLabel2_:setVisible(arg_31_0.__recordScore > 0)
	arg_31_0.recordSp_:setVisible(arg_31_0.__score > arg_31_0.__recordScore)

	if arg_31_0.__recordScore <= 0 then
		arg_31_0.textLabel1_:y(var_31_4[3])
		arg_31_0.scoreLabel1_:y(var_31_4[3])
		arg_31_0.recordSp_:y(var_31_4[3])
	else
		arg_31_0.textLabel1_:y(var_31_4[2])
		arg_31_0.scoreLabel1_:y(var_31_4[2])
		arg_31_0.recordSp_:y(var_31_4[2])
	end

	arg_31_0.alertView_:setScale(0)
	arg_31_0.alertView_:runAction(cc.EaseBackOut:create(cc.ScaleTo:create(0.3, 1)))
end

function var_0_2.setupScreen(arg_35_0)
	local var_35_0 = cc.Director:getInstance()
	local var_35_1 = var_35_0:getOpenGLView()
	local var_35_2 = var_35_1:getFrameSize()
	local var_35_3 = 0
	local var_35_4 = var_35_2.width / var_35_2.height < 1.5
	local var_35_5 = var_35_4 and 4 or 3

	var_35_0:setContentScaleFactor(1)
	var_35_1:setDesignResolutionSize(var_0_3, var_0_4, var_35_5)

	local var_35_6 = var_35_0:getVisibleSize()

	if var_35_4 then
		var_35_6.height = var_0_4 / var_0_3 * var_35_6.width
	end

	print(var_35_6.width, var_35_6.height)
end

return var_0_2
