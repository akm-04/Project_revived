local var_0_0 = class("ImagePickerWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.isAnimation = false
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer(nil, nil, true, function()
		arg_3_0:playMove(false, function()
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end)

		return true
	end)
	arg_3_0:playMove(true)
end

function var_0_0.layout(arg_6_0)
	arg_6_0:initButton()
	arg_6_0:nodeByName("text_photo"):setString(var_0_1:translation("OPEN_PHOTO"))
	arg_6_0:nodeByName("text_camera"):setString(var_0_1:translation("OPEN_CAMERA"))
	arg_6_0:nodeByName("text_cancel"):setString(var_0_1:translation("CANCEL"))
end

function var_0_0.initButton(arg_7_0)
	arg_7_0:nodeByName("btn_photo"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended and not arg_7_0.isAnimation then
			xyd.sdkPickupGallery(function(arg_9_0)
				local var_9_0 = false
				local var_9_1 = ""

				if arg_9_0 ~= "FALSE" then
					var_9_0 = true
					var_9_1 = arg_9_0
				end

				if arg_7_0.callback then
					arg_7_0.callback(var_9_0, var_9_1)
				end

				xyd.WindowManager.get():closeWindow(arg_7_0)
			end)
		end
	end)
	arg_7_0:nodeByName("btn_camera"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended and not arg_7_0.isAnimation then
			xyd.sdkTakePhoto(function(arg_11_0)
				local var_11_0 = false
				local var_11_1 = ""

				if arg_11_0 ~= "FALSE" then
					var_11_0 = true
					var_11_1 = arg_11_0
				end

				if arg_7_0.callback then
					arg_7_0.callback(var_11_0, var_11_1)
				end

				xyd.WindowManager.get():closeWindow(arg_7_0)
			end)
		end
	end)
	arg_7_0:nodeByName("btn_cancel"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended and not arg_7_0.isAnimation then
			arg_7_0:playMove(false, function()
				xyd.WindowManager.get():closeWindow(arg_7_0)
			end)
		end
	end)
end

function var_0_0.playMove(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_0:nodeByName("container")

	if arg_14_1 then
		local var_14_1 = cc.p(var_14_0:getPosition())
		local var_14_2 = var_14_1.x
		local var_14_3 = var_14_1.y
		local var_14_4 = var_14_0:getContentSize().height

		var_14_0:setPosition(cc.p(var_14_2, var_14_3 - var_14_4))

		arg_14_0.isAnimation = true

		arg_14_0:moveFadeInAction(var_14_2, var_14_3, var_14_0, function()
			arg_14_0.isAnimation = false

			if arg_14_2 then
				arg_14_2()
			end
		end)
	else
		local var_14_5 = cc.p(var_14_0:getPosition())
		local var_14_6 = var_14_5.x
		local var_14_7 = var_14_5.y
		local var_14_8 = var_14_0:getContentSize().height

		arg_14_0.isAnimation = true

		arg_14_0:moveFadeOutAction(var_14_6, var_14_7 - var_14_8, var_14_0, function()
			arg_14_0.isAnimation = false

			if arg_14_2 then
				arg_14_2()
			end
		end)
	end
end

function var_0_0.moveFadeInAction(arg_17_0, arg_17_1, arg_17_2, arg_17_3, arg_17_4, arg_17_5, arg_17_6)
	local var_17_0 = arg_17_5 or 0.4
	local var_17_1 = arg_17_6 or 0.5

	arg_17_0:widgetSet(arg_17_3)
	arg_17_3:setCascadeOpacityEnabled(true)
	arg_17_3:setOpacity(0)

	local var_17_2 = cc.Spawn:create(cc.FadeIn:create(var_17_0), cc.MoveTo:create(var_17_1, cc.p(arg_17_1, arg_17_2)))

	arg_17_3:runActionOnce(var_17_2, false, arg_17_4)
end

function var_0_0.moveFadeOutAction(arg_18_0, arg_18_1, arg_18_2, arg_18_3, arg_18_4)
	arg_18_0:widgetSet(arg_18_3)
	arg_18_3:setCascadeOpacityEnabled(true)

	local var_18_0 = cc.Spawn:create(cc.FadeOut:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_18_1, arg_18_2)))

	arg_18_3:runActionOnce(var_18_0, true, arg_18_4)
end

function var_0_0.widgetSet(arg_19_0, arg_19_1)
	for iter_19_0, iter_19_1 in ipairs(arg_19_1:getChildren()) do
		if iter_19_1 ~= nil then
			iter_19_1:setCascadeOpacityEnabled(true)
			arg_19_0:widgetSet(iter_19_1)
		end
	end
end

return var_0_0
