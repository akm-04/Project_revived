local var_0_0 = class("CopyCodeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.invite = xyd.ModelManager.get():loadModel(xyd.ModelType.INVITE_FRIENDS_INFOS)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layOut()
end

function var_0_0.inputboxEventHandler(arg_3_0, arg_3_1)
	if arg_3_1 == "began" then
		arg_3_0.nameEditbox_:setText(arg_3_0:nodeByName("code_txt"):getString())
		arg_3_0:nodeByName("code_txt"):setString("")
	end

	if arg_3_1 == "return" then
		arg_3_0:nodeByName("code_txt"):setString(arg_3_0.invite:getInviteCode())
		arg_3_0.nameEditbox_:setText("")
	end
end

function var_0_0.layOut(arg_4_0)
	arg_4_0:nodeByName("code_txt"):setString(arg_4_0.invite:getInviteCode())
	arg_4_0:nodeByName("input_code_desc"):setString(var_0_1:translation("INVITE_FRIEND_CODE_DES"))

	local var_4_0 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_4_0, cc.rect(26, 26, 1, 1))

	local var_4_1 = arg_4_0:nodeByName("code_container")

	arg_4_0.nameEditbox_ = ccui.EditBox:create(cc.size(var_4_1:getWidth(), var_4_1:getHeight()), var_4_0)

	arg_4_0:nodeByName("code_container"):addChild(arg_4_0.nameEditbox_)
	arg_4_0.nameEditbox_:setAnchorPoint(cc.p(0, 0))
	arg_4_0.nameEditbox_:setPosition(0, 0)
	arg_4_0.nameEditbox_:registerScriptEditBoxHandler(handler(arg_4_0, arg_4_0.inputboxEventHandler))
	arg_4_0.nameEditbox_:setInputFlag(3)
	arg_4_0:nodeByName("copy_btn"):setVisible(false)
	arg_4_0:nodeByName("copy_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = var_0_1:translation("COPY_TO_CLIPBOARD")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_5_0
			})
		end
	end)
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super.didOpen(arg_6_0, arg_6_1)
	arg_6_0:addBlockLayer()
end

return var_0_0
