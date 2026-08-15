local var_0_0 = import("framework.scheduler")
local var_0_1 = class("DialogWindow", import("app.common.ui.BaseWindow"))
local var_0_2 = xyd.tables.misc
local var_0_3 = 1
local var_0_4 = 2
local var_0_5 = 1
local var_0_6 = 2
local var_0_7 = 3
local var_0_8 = require("framework.scheduler")

function var_0_1.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_1.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.dialogData_ = arg_1_2.dialog_data
	arg_1_0.maxIndex_ = #arg_1_0.dialogData_
	arg_1_0.playingIndex_ = 0
	arg_1_0.storyPoint_ = 0

	if arg_1_2.callback then
		arg_1_0.callback = arg_1_2.callback
	end
end

function var_0_1.willOpen(arg_2_0, arg_2_1)
	var_0_1.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:hideOtherWindows()
	arg_2_0:layout()
end

function var_0_1.didOpen(arg_3_0, arg_3_1)
	var_0_1.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:nextPlay()
end

function var_0_1.hideOtherWindows(arg_4_0)
	local var_4_0 = xyd.WindowManager.get():getWindow(xyd.WindowName.battleBottomWnd)
	local var_4_1 = xyd.WindowManager.get():getWindow(xyd.WindowName.battleTopWnd)

	if var_4_1 then
		var_4_1:setVisible(false)
	end

	if var_4_0 then
		var_4_0:setVisible(false)
	end
end

function var_0_1.layout(arg_5_0)
	arg_5_0.maskColor = cc.c4f(0.5, 0.5, 0.5, 1)

	local var_5_0 = display.newNode()

	var_5_0:setName("role")
	var_5_0:size(arg_5_0:getContentSize())
	var_5_0:setAnchorPoint(cc.p(0, 0))
	var_5_0:setPosition(cc.p(0, 0))
	var_5_0:addTo(arg_5_0, -1)

	arg_5_0.roleLayer_ = var_5_0

	arg_5_0:setTouchSwallowEnabled(false)

	arg_5_0.touchLayer_ = var_5_0:clone()

	arg_5_0.touchLayer_:addTo(arg_5_0)
	arg_5_0.touchLayer_:setTouchEnabled(true)
	arg_5_0.touchLayer_:setTouchSwallowEnabled(false)
	arg_5_0.touchLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "ended" then
			arg_5_0:nextPlay()
		end

		return true
	end)
end

function var_0_1.nextPlay(arg_7_0)
	if arg_7_0.playingIndex_ >= arg_7_0.maxIndex_ then
		arg_7_0:onEnded()

		return
	end

	arg_7_0.playingIndex_ = arg_7_0.playingIndex_ + 1

	arg_7_0:update()
end

function var_0_1.update(arg_8_0)
	if arg_8_0.playingIndex_ > arg_8_0.maxIndex_ then
		return
	end

	local var_8_0 = arg_8_0.dialogData_[arg_8_0.playingIndex_].dialog
	local var_8_1 = arg_8_0.dialogData_[arg_8_0.playingIndex_].name
	local var_8_2 = arg_8_0.dialogData_[arg_8_0.playingIndex_].img
	local var_8_3 = arg_8_0.dialogData_[arg_8_0.playingIndex_].position

	arg_8_0:nodeByName("text"):setString(var_8_0)

	if var_8_3 == var_0_3 then
		if arg_8_0.leftIcon_ ~= var_8_2 then
			if arg_8_0.roleLeft1_ then
				arg_8_0.roleLeft1_:removeSelf()
				arg_8_0.roleLeft2_:removeSelf()
			end

			local var_8_4 = xyd.SpriteLoader.new(var_8_2, nil, nil, xyd.DefaultImageType.HOME_CARD)

			var_8_4:addTo(arg_8_0.roleLayer_)
			var_8_4:pos(10, 0)
			var_8_4:setAnchorPoint(cc.p(0, 0))

			local var_8_5 = var_8_4:clone()

			var_8_5:addTo(arg_8_0.roleLayer_)

			arg_8_0.leftIcon_ = var_8_2
			arg_8_0.roleLeft1_ = var_8_4
			arg_8_0.roleLeft2_ = var_8_5

			arg_8_0:gray(arg_8_0.roleLeft2_)
		end

		arg_8_0:iconFilter(arg_8_0.roleLeft1_, arg_8_0.roleLeft2_, false)
		arg_8_0:iconFilter(arg_8_0.roleRight1_, arg_8_0.roleRight2_, true)
		arg_8_0:nodeByName("name_box1"):setVisible(true)
		arg_8_0:nodeByName("label_name1"):setString(var_8_1)
		arg_8_0:nodeByName("label_name1"):setVisible(true)
		arg_8_0:nodeByName("name_box2"):setVisible(false)
		arg_8_0:nodeByName("label_name2"):setVisible(false)
	else
		if arg_8_0.rightIcon_ ~= var_8_2 then
			if arg_8_0.roleRight1_ then
				arg_8_0.roleRight1_:removeSelf()
				arg_8_0.roleRight2_:removeSelf()
			end

			local var_8_6 = xyd.SpriteLoader.new(var_8_2, nil, nil, xyd.DefaultImageType.HOME_CARD)

			var_8_6:addTo(arg_8_0.roleLayer_)
			var_8_6:pos(arg_8_0:getWidth() - var_8_6:getWidth() - 150, 0)
			var_8_6:setAnchorPoint(cc.p(0, 0))

			local var_8_7 = var_8_6:clone()

			var_8_7:addTo(arg_8_0.roleLayer_)

			arg_8_0.rightIcon_ = var_8_2
			arg_8_0.roleRight1_ = var_8_6
			arg_8_0.roleRight2_ = var_8_7

			arg_8_0:gray(arg_8_0.roleRight2_)
		end

		arg_8_0:iconFilter(arg_8_0.roleLeft1_, arg_8_0.roleLeft2_, true)
		arg_8_0:iconFilter(arg_8_0.roleRight1_, arg_8_0.roleRight2_, false)
		arg_8_0:nodeByName("name_box2"):setVisible(true)
		arg_8_0:nodeByName("label_name2"):setString(var_8_1)
		arg_8_0:nodeByName("label_name2"):setVisible(true)
		arg_8_0:nodeByName("name_box1"):setVisible(false)
		arg_8_0:nodeByName("label_name1"):setVisible(false)
	end
end

function var_0_1.iconFilter(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if not arg_9_1 or not arg_9_2 then
		return
	end

	if arg_9_3 then
		arg_9_1:hide()
		arg_9_2:hide()
	else
		arg_9_2:hide()
		arg_9_1:show()
	end
end

function var_0_1.gray(arg_10_0, arg_10_1)
	local var_10_0 = cc.TintBy:create(0, 200, 200, 200)

	arg_10_1:runActionOnce(var_10_0)
end

function var_0_1.onEnded(arg_11_0)
	local var_11_0 = xyd.WindowManager.get():getWindow("dialog")

	if var_11_0 and not tolua.isnull(var_11_0) then
		xyd.WindowManager.get():closeWindow("dialog")
	end
end

function var_0_1.willClose(arg_12_0)
	local var_12_0 = xyd.WindowManager.get():getWindow(xyd.WindowName.battleBottomWnd)
	local var_12_1 = xyd.WindowManager.get():getWindow(xyd.WindowName.battleTopWnd)

	if var_12_1 then
		var_12_1:setVisible(true)
	end

	if var_12_0 then
		var_12_0:setVisible(true)
	end

	arg_12_0:dispatchEvent({
		name = xyd.event.DIALOG_COMPLETE
	})
end

return var_0_1
