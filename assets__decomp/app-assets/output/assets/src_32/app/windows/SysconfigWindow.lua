local var_0_0 = class("SysconfigWindow", import("app.common.ui.BaseWindow"))

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.listView_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 750, 500),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("list"))

	arg_2_0.listView_:setAnchorPoint(cc.p(0, 1))

	arg_2_0.blackList = {}
	arg_2_0.soundSwitch = xyd.db.settings:getSoundEffect()
	arg_2_0.musicSwitch = xyd.db.settings:getBackgroudMusicOn()
	arg_2_0.isReviewServer = false

	if xyd.Backend.get().GMURL_ ~= nil then
		arg_2_0.isReviewServer = true
	end

	arg_2_0:nodeByName("backgroud"):removeChild(arg_2_0:nodeByName("Image_9"))
	arg_2_0:nodeByName("backgroud"):removeChild(arg_2_0:nodeByName("Image_10"))
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0.listView_:newItem()
	local var_3_1 = display.newNode()
	local var_3_2 = display.newNode()
	local var_3_3 = import("app.windows.SwitchItem"):new()
	local var_3_4 = {
		voiceSwitch = arg_3_0.soundSwitch,
		musicSwitch = arg_3_0.musicSwitch
	}

	var_3_3:setParams(var_3_4)
	var_3_3:setCodeVisible(not arg_3_0.isReviewServer)
	var_3_2:size(750, 50)
	var_3_2:addChild(arg_3_0:nodeByName("Image_9"))
	var_3_2:addChild(arg_3_0:nodeByName("Image_10"))
	arg_3_0:nodeByName("Image_9"):align(display.CENTER, var_3_2:getWidth() / 2, var_3_2:getHeight() / 2)
	arg_3_0:nodeByName("Image_10"):align(display.CENTER, var_3_2:getWidth() / 2, var_3_2:getHeight() / 2)
	var_3_2:pos(0, 280)
	var_3_3:addChild(var_3_2)
	var_3_1:addChild(var_3_3)
	var_3_3:pos(0, 550)
	var_3_3:setAnchorPoint(cc.p(0, 1))
	var_3_3:ignoreAnchorPointForPosition(false)

	local var_3_5 = import("app.windows.MessagePushItem").new()

	var_3_1:addChild(var_3_5)
	var_3_5:pos(0, 50)
	var_3_1:setContentSize(750, 850)
	var_3_0:addContent(var_3_1)
	var_3_0:setItemSize(750, 850)
	arg_3_0.listView_:addItem(var_3_0)
	arg_3_0.listView_:reload()
end

function var_0_0.layoutMessageConfig(arg_4_0)
	return
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:addBlockLayer()
end

function var_0_0.buttonHandler(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if arg_6_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_6_2)
		arg_6_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound("sound/button.ogg", false)

		if arg_6_1 then
			arg_6_1(arg_6_2, arg_6_3)
		end
	elseif arg_6_3 == ccui.TouchEventType.began then
		return true
	elseif arg_6_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_6_2)
		arg_6_2:setScale(1)
	end
end

return var_0_0
