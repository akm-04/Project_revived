local var_0_0 = class("ActivityDateWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = import("app.model.Hero")
local var_0_4 = 40001095
local var_0_5 = 10001095
local var_0_6 = 3
local var_0_7 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.awards = arg_1_2.awards
	arg_1_0.step = arg_1_2.step
	arg_1_0.tableID = arg_1_2.table_id
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0.step
	local var_4_1 = xyd.AssetLoader.get():loadSprite("windows/activities/1069/date_scene_" .. var_4_0 .. ".png")
	local var_4_2 = arg_4_0:nodeByName("container")
	local var_4_3, var_4_4 = arg_4_0:nodeByName("bg_1"):getPosition()

	var_4_2:addChild(var_4_1)
	var_4_1:setAnchorPoint(cc.p(0, 0))
	var_4_1:setPosition(cc.p(var_4_3 + 26, var_4_4 + 28))
	arg_4_0:nodeByName("text_dialog"):setString(string.format(var_0_2:translation("DATE_TEXT_16"), xyd.tables.activityDate:name(var_4_0)))
	arg_4_0:initHeroModel()
	arg_4_0:initAnimation()
	arg_4_0:nodeByName("bg_2"):setLocalZOrder(99)
	arg_4_0:nodeByName("skip"):setLocalZOrder(100)
	arg_4_0:nodeByName("date_dialog_bg"):setLocalZOrder(101)
	arg_4_0:nodeByName("skip"):setTouchEnabled(true)
	arg_4_0:nodeByName("skip"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			arg_4_0:nodeByName("skip"):setScale(0.9)

			return true
		elseif arg_5_0.name == "ended" then
			arg_4_0:nodeByName("skip"):setScale(1)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
end

function var_0_0.initHeroModel(arg_6_0)
	local var_6_0 = arg_6_0:nodeByName("container")
	local var_6_1 = arg_6_0:getHeroModel()

	var_6_1:setTouchSwallowEnabled(false)

	arg_6_0.modelState = xyd.ModelState.Walk

	local var_6_2 = var_6_0:getContentSize().width / 2
	local var_6_3 = var_6_0:getContentSize().width / 2

	var_6_1:setPosition(cc.p(0, 159.75))
	var_6_1:setTouchEnabled(true)
	var_6_1:setScale(0.8)

	local var_6_4 = xyd.AssetLoader.get():loadSprite("windows/activities/1069/clip_img.png")

	var_6_4:setPosition(cc.p(-190, -109.75))
	var_6_4:setAnchorPoint(cc.p(0, 0))

	local var_6_5 = cc.ClippingNode:create()

	var_6_5:setStencil(var_6_4)
	var_6_5:setInverted(true)
	var_6_5:setAlphaThreshold(0)
	var_6_0:addChild(var_6_5)
	var_6_5:addChild(var_6_1)
	var_6_5:setLocalZOrder(101)
end

function var_0_0.initAnimation(arg_7_0)
	local var_7_0 = arg_7_0.step
	local var_7_1 = arg_7_0:nodeByName("container"):getContentSize().width / 2
	local var_7_2 = arg_7_0:getHeroModel()

	transition.stopTarget(var_7_2)

	local var_7_3 = var_7_2:getPositionY()

	arg_7_0.modelState = xyd.ModelState.Walk

	arg_7_0:resetModelState()

	local var_7_4 = cc.Spawn:create({
		cc.MoveBy:create(var_0_7, cc.p(var_7_1, 0)),
		cc.CallFunc:create(function()
			local var_8_0 = var_0_2:translation("DATE_TEXT_17")

			arg_7_0:nodeByName("text_dialog_point"):setString(string.sub(var_8_0, 1, 1))

			if arg_7_0.handler then
				var_0_1.unscheduleGlobal(arg_7_0.handler)

				arg_7_0.handler = nil
			end

			local var_8_1 = var_0_7
			local var_8_2 = 0

			arg_7_0.handler = var_0_1.scheduleGlobal(function()
				var_8_1 = var_8_1 - 0.5
				var_8_2 = var_8_2 + 1

				if var_8_2 > #var_8_0 then
					var_8_2 = 1
				end

				arg_7_0:nodeByName("text_dialog_point"):setString(string.sub(var_8_0, 1, var_8_2))

				if var_8_1 <= 0 and arg_7_0.handler then
					var_0_1.unscheduleGlobal(arg_7_0.handler)

					arg_7_0.handler = nil
				end
			end, 0.5)
		end)
	})

	local function var_7_5()
		arg_7_0.modelState = xyd.ModelState.Idle

		arg_7_0:resetModelState()

		if arg_7_0.handler then
			var_0_1.unscheduleGlobal(arg_7_0.handler)

			arg_7_0.handler = nil
		end

		local var_10_0 = var_0_6

		arg_7_0.handler = var_0_1.scheduleGlobal(function()
			arg_7_0:nodeByName("text_dialog"):setString(var_0_2:translation("DATE_TEXT_15"))
			arg_7_0:nodeByName("text_dialog_point"):setString("")

			var_10_0 = var_10_0 - 1
			arg_7_0.modelState = xyd.ModelState.Win

			arg_7_0:resetModelState()

			if var_10_0 <= 0 and arg_7_0.handler then
				var_0_1.unscheduleGlobal(arg_7_0.handler)

				arg_7_0.handler = nil

				xyd.WindowManager.get():closeWindow(arg_7_0)
			end
		end, 1)
	end

	local var_7_6 = {}

	table.insert(var_7_6, var_7_4)
	table.insert(var_7_6, cc.CallFunc:create(var_7_5))
	var_7_2:runAction(transition.sequence(var_7_6))
end

function var_0_0.resetModelState(arg_12_0)
	local var_12_0 = arg_12_0:getHeroModel()
	local var_12_1

	if arg_12_0.modelState == xyd.ModelState.Walk then
		var_12_0:walk(true)

		var_12_1 = xyd.tables.model:getMoveSound(var_0_4)
	elseif arg_12_0.modelState == xyd.ModelState.Win then
		var_12_0:win(false, handler(arg_12_0, arg_12_0.setIsShow))

		var_12_1 = xyd.tables.model:getWinSound(var_0_4)
	else
		arg_12_0:setIsShow()
	end

	if var_12_1 and var_12_1 ~= "" then
		audio.stopAllSounds()
		audio.playSound(var_12_1, false)
	end
end

function var_0_0.setIsShow(arg_13_0)
	arg_13_0:getHeroModel():idle()
end

function var_0_0.getHeroModel(arg_14_0)
	if not arg_14_0.heroModel_ then
		arg_14_0.heroModel_ = xyd.HeroAnimation.new(nil, var_0_4, 1, {})
	end

	return arg_14_0.heroModel_
end

function var_0_0.willClose(arg_15_0)
	return
end

function var_0_0.didClose(arg_16_0)
	if arg_16_0.handler then
		var_0_1.unscheduleGlobal(arg_16_0.handler)

		arg_16_0.handler = nil
	end

	local var_16_0 = arg_16_0.awards
	local var_16_1 = arg_16_0.tableID

	arg_16_0.player:handleRewards(var_16_0, function()
		if arg_16_0.callback then
			arg_16_0.callback()
		end
	end)
end

return var_0_0
