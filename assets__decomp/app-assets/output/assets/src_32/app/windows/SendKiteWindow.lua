local var_0_0 = class("SendKiteWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.message = ""
	arg_1_0.id = arg_1_2.idx
	arg_1_0.sendNum = arg_1_2.num
	arg_1_0.container = arg_1_2.container
	arg_1_0.kite = xyd.ModelManager.get():loadModel(xyd.ModelType.KITE)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:layout()
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 225))
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("send_desc"):setString(var_0_1:translation("SEND_KITE_DESC"))
	arg_4_0:initEditBox()
	arg_4_0:nodeByName("send_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = {
				idx = arg_4_0.id,
				num = arg_4_0.sendNum
			}

			if arg_4_0.message == "" then
				var_5_0.content = var_0_1:translation("SEND_KITE_EDIT_DESC")
			else
				var_5_0.content = arg_4_0.message
			end

			xyd.WindowManager.get():openWindow("anser_question", var_5_0)
		end
	end)
end

function var_0_0.initEditBox(arg_6_0)
	arg_6_0:nodeByName("edit_desc"):setString("")

	local var_6_0 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_6_0, cc.rect(28, 28, 1, 1))

	arg_6_0.editbox_ = ccui.EditBox:create(cc.size(530, 60), var_6_0)

	arg_6_0:nodeByName("edit_container"):addChild(arg_6_0.editbox_)
	arg_6_0.editbox_:setAnchorPoint(cc.p(0, 0))
	arg_6_0.editbox_:setPosition(0, 0)
	arg_6_0.editbox_:registerScriptEditBoxHandler(handler(arg_6_0, arg_6_0.inputboxEventHandler))
	arg_6_0.editbox_:setInputFlag(3)

	if not arg_6_0.message or arg_6_0.message == "" then
		arg_6_0:nodeByName("edit_desc"):setString(var_0_1:translation("SEND_KITE_EDIT_DESC"))
		arg_6_0:nodeByName("edit_desc"):setColor(cc.c3b(185, 185, 185))
	else
		arg_6_0:nodeByName("edit_desc"):setString(arg_6_0.message)
		arg_6_0:nodeByName("edit_desc"):setColor(cc.c3b(255, 255, 255))
	end
end

function var_0_0.inputboxEventHandler(arg_7_0, arg_7_1)
	if arg_7_1 == "began" then
		if not arg_7_0.message or arg_7_0.message == "" then
			arg_7_0:nodeByName("edit_desc"):setString("")
		else
			arg_7_0.editbox_:setText(arg_7_0:nodeByName("edit_desc"):getString())
		end
	end

	if arg_7_1 == "return" then
		local var_7_0 = arg_7_0.editbox_:getText()

		if var_7_0 == "" then
			arg_7_0.message = ""

			arg_7_0:nodeByName("edit_desc"):setString(var_0_1:translation("SEND_KITE_EDIT_DESC"))
			arg_7_0:nodeByName("edit_desc"):setColor(cc.c3b(185, 185, 185))
		else
			if xyd.utf8len(var_7_0) > 20 then
				var_7_0 = xyd.getTextstr(var_7_0, 1, 20)
			end

			arg_7_0.message = var_7_0

			arg_7_0:nodeByName("edit_desc"):setString(var_7_0)
			arg_7_0:nodeByName("edit_desc"):setColor(cc.c3b(255, 255, 255))
		end

		arg_7_0.editbox_:setText("")
		arg_7_0.editbox_:setVisible(true)
	end
end

return var_0_0
