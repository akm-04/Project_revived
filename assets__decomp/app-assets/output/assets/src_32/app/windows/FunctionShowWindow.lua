local var_0_0 = class("FunctionShowWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.functionOpen
local var_0_3 = "skeletons/ui_effect/function_show/"
local var_0_4 = "windows/function_show/"
local var_0_5 = 15
local var_0_6 = 36

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.effects = {}
	arg_1_0.funcID = arg_1_2.funcID
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:setContentSize(1280, 720)

	if color == nil then
		color = cc.c4b(0, 0, 0, 150)
	end

	arg_2_0.blockLayer_ = display.newColorLayer(color)

	local var_2_0 = arg_2_0:convertToWorldSpace(cc.p(0, 0))

	arg_2_0.blockLayer_:pos(-var_2_0.x, -var_2_0.y):addTo(arg_2_0, -1)

	local function var_2_1(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			local var_3_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_3_0, false)
			xyd.WindowManager.get():closeWindow(arg_2_0.name)
		end

		return true
	end

	local function var_2_2(arg_4_0, arg_4_1)
		if callback then
			callback()
		end

		local var_4_0 = xyd.tables.sound:getSound("ui_close_window")

		audio.playSound(var_4_0, false)
		xyd.WindowManager.get():closeWindow(arg_2_0.name)
	end

	arg_2_0.layerListener = cc.EventListenerTouchOneByOne:create()

	arg_2_0.layerListener:setSwallowTouches(true)
	arg_2_0.layerListener:registerScriptHandler(var_2_1, cc.Handler.EVENT_TOUCH_BEGAN)
	arg_2_0.layerListener:registerScriptHandler(var_2_2, cc.Handler.EVENT_TOUCH_ENDED)
	arg_2_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(arg_2_0.layerListener, arg_2_0)
	arg_2_0:layout()
end

function var_0_0.layout(arg_5_0)
	arg_5_0:initEffect()
	arg_5_0:createScheduler()
	arg_5_0:addSprite()
end

function var_0_0.createScheduler(arg_6_0)
	if arg_6_0.handle then
		var_0_1.unscheduleGlobal(arg_6_0.handle)

		arg_6_0.handle = nil
	end

	arg_6_0.totalCount = 0
	arg_6_0.playFirst = false
	arg_6_0.playSecond = false
	arg_6_0.playThird = false
	arg_6_0.handle = var_0_1.scheduleUpdateGlobal(handler(arg_6_0, arg_6_0.loop))
end

function var_0_0.addSprite(arg_7_0)
	local var_7_0 = var_0_2:functionPic(arg_7_0.funcID)
	local var_7_1 = ".png"
	local var_7_2 = var_0_4 .. var_7_0 .. var_7_1

	icon = xyd.SpriteLoader.new(var_7_2, nil, nil, xyd.DefaultImageType.COMMON_TITLE)

	icon:setAnchorPoint(cc.p(0.5, 0.5))
	icon:addTo(arg_7_0:nodeByName("pic_pos"))
	arg_7_0:nodeByName("txt"):setString(var_0_2:functionDesc(arg_7_0.funcID))
end

function var_0_0.loop(arg_8_0)
	if arg_8_0.totalCount <= var_0_5 then
		arg_8_0.effects.tanchuang1:setVisible(true)

		if not arg_8_0.playFirst then
			arg_8_0.effects.tanchuang1:play(nil, true, nil, "texiao01")

			arg_8_0.playFirst = true
		end
	elseif arg_8_0.totalCount <= var_0_6 then
		arg_8_0:nodeByName("pic_pos"):setVisible(true)
		arg_8_0:nodeByName("txt"):setVisible(true)
		arg_8_0.effects.tanchuang2:setVisible(true)
		arg_8_0.effects.tanchuang3:setVisible(true)

		if not arg_8_0.playSecond then
			local var_8_0 = "texiao0" .. var_0_2:fxNum(arg_8_0.funcID)

			arg_8_0.effects.tanchuang2:play(nil, true, nil, var_8_0)
			arg_8_0.effects.tanchuang3:play(nil, true, nil, "texiao")

			arg_8_0.playSecond = true
		end
	elseif arg_8_0.totalCount <= var_0_6 + 1 then
		arg_8_0.effects.tanchuang1.effect2:setVisible(true)

		if not arg_8_0.playThird then
			arg_8_0.effects.tanchuang1.effect2:play(nil, true, nil, "texiao02")

			arg_8_0.playThird = true
		end
	else
		arg_8_0.effects.tanchuang1:setVisible(false)
	end

	arg_8_0.totalCount = arg_8_0.totalCount + 1
end

function var_0_0.initEffect(arg_9_0)
	arg_9_0:nodeByName("pic_pos"):setVisible(false)
	arg_9_0:nodeByName("txt"):setVisible(false)

	if not arg_9_0.effects.tanchuang1 then
		local var_9_0 = arg_9_0:getEffect("gongnengtanchuang1")

		var_9_0:addTo(arg_9_0:nodeByName("pic1_pos"))
		var_9_0:setPosition(cc.p(0, 0))
		var_9_0:setVisible(false)

		arg_9_0.effects.tanchuang1 = var_9_0

		local var_9_1 = arg_9_0:getEffect("gongnengtanchuang1")

		var_9_1:addTo(arg_9_0:nodeByName("pic1_pos"))
		var_9_1:setPosition(cc.p(0, 0))
		var_9_1:setVisible(false)

		arg_9_0.effects.tanchuang1.effect2 = var_9_1
	end

	if not arg_9_0.effects.tanchuang2 then
		local var_9_2 = arg_9_0:getEffect("gongnengtanchuang2")

		var_9_2:addTo(arg_9_0:nodeByName("pic2_pos"))
		var_9_2:setPosition(cc.p(0, 0))
		var_9_2:setVisible(false)

		arg_9_0.effects.tanchuang2 = var_9_2
	end

	if not arg_9_0.effects.tanchuang3 then
		local var_9_3 = arg_9_0:getEffect("gongnengtanchuang3")

		var_9_3:addTo(arg_9_0:nodeByName("pic3_pos"))
		var_9_3:setPosition(cc.p(0, 0))
		var_9_3:setVisible(false)

		arg_9_0.effects.tanchuang3 = var_9_3
	end
end

function var_0_0.getEffect(arg_10_0, arg_10_1)
	local var_10_0 = var_0_3 .. arg_10_1
	local var_10_1 = xyd.createEffect(var_10_0)

	var_10_1:setAnchorPoint(cc.p(0, 0))

	return var_10_1
end

function var_0_0.willClose(arg_11_0, arg_11_1)
	var_0_0.super.willClose(arg_11_0, arg_11_1)

	if arg_11_0.handle then
		var_0_1.unscheduleGlobal(arg_11_0.handle)

		arg_11_0.handle = nil
	end
end

function var_0_0.didClose(arg_12_0)
	var_0_0.super.didClose(arg_12_0, params)
end

return var_0_0
