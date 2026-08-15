local var_0_0 = class("InputAuthenticMsgWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	STUDNET = 2,
	TEACHER = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.message = ""
	arg_1_0.data = arg_1_2.data
	arg_1_0.relation = arg_1_2.relation
	arg_1_0.playerId = arg_1_0.data.player_id
	arg_1_0.callback = arg_1_2.callback
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
	arg_4_0:nodeByName("tips_txt"):setString(var_0_1:translation("INPUT_AUTHENTIC_TIPS"))
	arg_4_0:initEditBox()
	arg_4_0:nodeByName("send_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = {
				msg = arg_4_0.message or ""
			}

			if arg_4_0.relation then
				var_5_0.to_player_id = arg_4_0.playerId
				var_5_0.relation_type = arg_4_0.relation

				arg_4_0.socialSystem:ApplyRelation(var_5_0, function(arg_6_0, arg_6_1)
					if arg_6_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("TEACHER_SEND_TIP3")
						})

						if arg_4_0.callback then
							arg_4_0.data.is_send_apply = true

							arg_4_0.callback()
						end

						xyd.WindowManager.get():closeWindow(arg_4_0)
					else
						xyd.WindowManager.get():closeWindow(arg_4_0)
					end
				end)
			else
				var_5_0.player_id = arg_4_0.playerId

				arg_4_0.socialSystem:requestFriend(var_5_0, function(arg_7_0, arg_7_1)
					if arg_4_0.callback then
						arg_4_0.data.is_send_apply = true

						arg_4_0.callback()
					end

					if arg_7_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("SEND_FRIEND_APPLY_SUCCEED")
						})
						xyd.WindowManager.get():closeWindow(arg_4_0)
					end
				end)
			end
		end
	end)
end

function var_0_0.initEditBox(arg_8_0)
	arg_8_0:nodeByName("edit_desc"):setString("")
	arg_8_0:nodeByName("edit_desc"):setColor(cc.c3b(255, 255, 255))

	local var_8_0 = "windows/login/transparent.png"
	local var_8_1 = arg_8_0:nodeByName("edit_container")

	xyd.AssetLoader.get():loadSprite(var_8_0, cc.rect(28, 28, 1, 1))

	arg_8_0.editbox_ = ccui.EditBox:create(var_8_1:getContentSize(), var_8_0)

	arg_8_0:nodeByName("edit_container"):addChild(arg_8_0.editbox_)
	arg_8_0.editbox_:setAnchorPoint(cc.p(0, 0))
	arg_8_0.editbox_:setPosition(0, 0)
	arg_8_0.editbox_:registerScriptEditBoxHandler(handler(arg_8_0, arg_8_0.inputboxEventHandler))
	arg_8_0.editbox_:setInputFlag(3)

	if not arg_8_0.message or arg_8_0.message == "" then
		if arg_8_0.relation then
			local var_8_2 = ""

			if arg_8_0.relation == var_0_2.TEACHER then
				var_8_2 = var_0_1:translation("TEACHER_SEND_TIP1")
			else
				var_8_2 = var_0_1:translation("TEACHER_SEND_TIP2")
			end

			arg_8_0:nodeByName("edit_desc"):setString(var_8_2)
		else
			arg_8_0:nodeByName("edit_desc"):setString(var_0_1:translation("INPUT_AUTHENTIC_EDIT_MSG"))
		end
	else
		arg_8_0:nodeByName("edit_desc"):setString(arg_8_0.message)
	end
end

function var_0_0.inputboxEventHandler(arg_9_0, arg_9_1)
	if arg_9_1 == "began" then
		if not arg_9_0.message or arg_9_0.message == "" then
			arg_9_0:nodeByName("edit_desc"):setString("")
		else
			arg_9_0.editbox_:setText(arg_9_0:nodeByName("edit_desc"):getString())
		end
	end

	if arg_9_1 == "return" then
		local var_9_0 = arg_9_0.editbox_:getText()

		if var_9_0 == "" then
			if arg_9_0.relation then
				if arg_9_0.relation == var_0_2.TEACHER then
					arg_9_0.message = var_0_1:translation("TEACHER_SEND_TIP1")
				else
					arg_9_0.message = var_0_1:translation("TEACHER_SEND_TIP2")
				end

				arg_9_0:nodeByName("edit_desc"):setString(arg_9_0.message)
			else
				arg_9_0.message = ""

				arg_9_0:nodeByName("edit_desc"):setString(var_0_1:translation("INPUT_AUTHENTIC_TIPS"))
			end
		else
			if xyd.utf8len(var_9_0) > 26 then
				var_9_0 = xyd.getTextstr(var_9_0, 1, 26)
			end

			arg_9_0.message = var_9_0

			arg_9_0:nodeByName("edit_desc"):setString(var_9_0)
		end

		arg_9_0.editbox_:setText("")
		arg_9_0.editbox_:setVisible(true)
	end
end

return var_0_0
