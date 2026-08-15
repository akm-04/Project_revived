local var_0_0 = class("RedEnvelopeGetWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	Multiplication = 3,
	Substraction = 2,
	Addtion = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.redEnvelope = xyd.ModelManager.get():loadModel(xyd.ModelType.RED_ENVELOPE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.content = arg_1_2.content
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.filterWord = xyd.ModelManager.get():loadModel(xyd.ModelType.FILTER_WORD)
	arg_1_0.message = ""
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer(cc.c4b(0, 0, 0, 225))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("text1"):setString(var_0_1:translation("RED_ENVELOP_GET_TIP"))
	arg_3_0:nodeByName("text2"):setString(arg_3_0.content)
	arg_3_0:initEditBox()
	arg_3_0:nodeByName("btn_yes"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0, var_4_1 = arg_3_0.filterWord:warningStrGsub(arg_3_0.message)

			if var_4_1 or arg_3_0:checkStr(arg_3_0.message) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ENVELOPE_FILTER_WORD")
				})
			else
				if arg_3_0.message == arg_3_0.content then
					arg_3_0.callback(true)
				else
					arg_3_0.callback(false)
				end

				xyd.WindowManager.get():closeWindow(arg_3_0)
			end
		end
	end)
end

function var_0_0.initEditBox(arg_5_0)
	arg_5_0:nodeByName("edit_desc"):setString("")

	local var_5_0 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_5_0, cc.rect(28, 28, 1, 1))

	arg_5_0.editbox_ = ccui.EditBox:create(cc.size(530, 60), var_5_0)

	arg_5_0:nodeByName("edit_container"):addChild(arg_5_0.editbox_)
	arg_5_0.editbox_:setAnchorPoint(cc.p(0, 0))
	arg_5_0.editbox_:setPosition(0, 0)
	arg_5_0.editbox_:registerScriptEditBoxHandler(handler(arg_5_0, arg_5_0.inputboxEventHandler))
	arg_5_0.editbox_:setInputFlag(3)

	if not arg_5_0.message or arg_5_0.message == "" then
		arg_5_0:nodeByName("edit_desc"):setString(var_0_1:translation("RED_ENVELOP_GET_TIP2"))
		arg_5_0:nodeByName("edit_desc"):setColor(cc.c3b(185, 185, 185))
	else
		arg_5_0:nodeByName("edit_desc"):setString(arg_5_0.message)
		arg_5_0:nodeByName("edit_desc"):setColor(cc.c3b(255, 255, 255))
	end
end

function var_0_0.inputboxEventHandler(arg_6_0, arg_6_1)
	if arg_6_1 == "began" then
		local var_6_0 = arg_6_0:nodeByName("edit_desc"):getString()

		if not arg_6_0.message or arg_6_0.message == "" then
			arg_6_0:nodeByName("edit_desc"):setString("")
		else
			arg_6_0.editbox_:setText(var_6_0)
		end
	end

	if arg_6_1 == "return" then
		local var_6_1 = arg_6_0.editbox_:getText()

		if var_6_1 == "" then
			arg_6_0.message = ""

			arg_6_0:nodeByName("edit_desc"):setString(var_0_1:translation("RED_ENVELOP_GET_TIP2"))
			arg_6_0:nodeByName("edit_desc"):setColor(cc.c3b(185, 185, 185))
		else
			if xyd.utf8len(var_6_1) > 23 then
				var_6_1 = xyd.getTextstr(var_6_1, 1, 8)
			end

			arg_6_0.message = var_6_1

			arg_6_0:nodeByName("edit_desc"):setString(var_6_1)
			arg_6_0:nodeByName("edit_desc"):setColor(cc.c3b(175, 122, 117))
		end

		arg_6_0.editbox_:setText("")
		arg_6_0.editbox_:setVisible(true)
	end
end

function var_0_0.checkStr(arg_7_0, arg_7_1)
	arg_7_1 = arg_7_1 or ""

	if arg_7_1 == var_0_1:translation("SEND_ENVELOPE_EDIT_DESC") then
		return false
	end

	local var_7_0 = {}
	local var_7_1 = string.len(arg_7_1)

	while arg_7_1 do
		local var_7_2 = string.byte(arg_7_1, 1)

		if var_7_2 == nil then
			break
		end

		if var_7_2 > 127 then
			arg_7_1 = string.sub(arg_7_1, 4, var_7_1)
		else
			if var_7_2 < 48 or var_7_2 > 57 and var_7_2 < 65 or var_7_2 > 90 and var_7_2 < 97 or var_7_2 > 122 and var_7_2 <= 127 then
				return true
			end

			arg_7_1 = string.sub(arg_7_1, 2, var_7_1)
		end
	end

	return false
end

return var_0_0
