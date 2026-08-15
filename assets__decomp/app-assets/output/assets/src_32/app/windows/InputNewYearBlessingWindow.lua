local var_0_0 = class("InputNewYearBlessingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.message = nil
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.filterWord = xyd.ModelManager.get():loadModel(xyd.ModelType.FILTER_WORD)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 225))
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_top"):setString(var_0_1:translation("NEW_YEAR_BLESSING_TIPS_6"))
	arg_4_0:initEditBox()
	arg_4_0:nodeByName("btn_send"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = {}
			local var_5_1 = var_0_1:translation("NEW_YEAR_BLESSING_TIPS_5")

			var_5_0.msg = arg_4_0.message or var_5_1

			arg_4_0:sendNewYearBlessing(var_5_0, function(arg_6_0, arg_6_1)
				if arg_4_0.callback then
					arg_4_0.callback(arg_6_0, arg_6_1)
				end

				if arg_6_0 == xyd.error.OK then
					xyd.WindowManager.get():closeWindow(arg_4_0)
				end
			end)
		end
	end)
end

function var_0_0.sendNewYearBlessing(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.ADD_NEWYEAR_WISH, var_7_0, function(arg_8_0, arg_8_1)
		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.initEditBox(arg_9_0)
	arg_9_0:nodeByName("edit_desc"):setString("")

	local var_9_0 = "windows/login/transparent.png"
	local var_9_1 = arg_9_0:nodeByName("edit_container")

	arg_9_0.editbox_ = ccui.EditBox:create(var_9_1:getContentSize(), var_9_0)

	arg_9_0:nodeByName("edit_container"):addChild(arg_9_0.editbox_)
	arg_9_0.editbox_:setAnchorPoint(cc.p(0, 0))
	arg_9_0.editbox_:setPosition(0, 0)
	arg_9_0.editbox_:registerScriptEditBoxHandler(handler(arg_9_0, arg_9_0.inputboxEventHandler))
	arg_9_0.editbox_:setInputFlag(3)

	if not arg_9_0.message or arg_9_0.message == "" then
		arg_9_0:nodeByName("edit_desc"):setString(var_0_1:translation("NEW_YEAR_BLESSING_TIPS_5"))
		arg_9_0:nodeByName("edit_desc"):setColor(cc.c3b(185, 185, 185))
	else
		arg_9_0:nodeByName("edit_desc"):setString(arg_9_0.message)
		arg_9_0:nodeByName("edit_desc"):setColor(cc.c3b(255, 255, 255))
	end
end

function var_0_0.inputboxEventHandler(arg_10_0, arg_10_1)
	if arg_10_1 == "began" then
		if not arg_10_0.message or arg_10_0.message == "" then
			arg_10_0:nodeByName("edit_desc"):setString("")
		else
			arg_10_0.editbox_:setText(arg_10_0:nodeByName("edit_desc"):getString())
		end
	end

	if arg_10_1 == "return" then
		local var_10_0, var_10_1 = arg_10_0.filterWord:warningStrGsub(arg_10_0.editbox_:getText())

		if var_10_1 then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("NEW_YEAR_BLESSING_TIPS_10")
			})

			var_10_0 = ""
		end

		if var_10_0 == "" then
			arg_10_0.message = nil

			arg_10_0:nodeByName("edit_desc"):setString(var_0_1:translation("NEW_YEAR_BLESSING_TIPS_5"))
			arg_10_0:nodeByName("edit_desc"):setColor(cc.c3b(185, 185, 185))
		else
			if xyd.utf8len(var_10_0) > 50 then
				var_10_0 = xyd.getTextstr(var_10_0, 1, 50)
			end

			arg_10_0.message = var_10_0

			arg_10_0:nodeByName("edit_desc"):setString(var_10_0)
			arg_10_0:nodeByName("edit_desc"):setColor(cc.c3b(213, 79, 34))
		end

		arg_10_0.editbox_:setText("")
		arg_10_0.editbox_:setVisible(true)
	end
end

return var_0_0
