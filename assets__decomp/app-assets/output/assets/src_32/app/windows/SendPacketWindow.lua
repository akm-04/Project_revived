local var_0_0 = class("SendPacketWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	CAN_SEND = 1,
	HAVE_SEND = 2,
	NO_SEND = 0
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.packetIdx = arg_1_2.idx
	arg_1_0.luckyPacket = xyd.ModelManager.get():loadModel(xyd.ModelType.LUCKY_PACKET)
	arg_1_0.message = ""
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:layout()
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 225))
end

function var_0_0.layout(arg_4_0)
	arg_4_0:initEditBox()
	arg_4_0:nodeByName("send_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = {
				id = arg_4_0.packetIdx
			}

			if arg_4_0.message == "" then
				var_5_0.content = var_0_1:translation("SEND_PACKET_EDIT_DESC")
			else
				var_5_0.content = arg_4_0.message
			end

			arg_4_0.luckyPacket:sendPacket(var_5_0, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					arg_4_0.luckyPacket.lastPacketList[arg_4_0.packetIdx] = arg_6_1.packet_id

					local var_6_0 = xyd.WindowManager.get():getWindow("lucky_packet")

					if var_6_0 then
						arg_4_0.luckyPacket.selfState[arg_4_0.packetIdx] = var_0_2.HAVE_SEND

						var_6_0:updateRightListItem(arg_4_0.packetIdx)
					end

					xyd.WindowManager.get():closeWindow(arg_4_0.name)
				end
			end)
		end
	end)
end

function var_0_0.initEditBox(arg_7_0)
	arg_7_0:nodeByName("edit_desc"):setString("")

	local var_7_0 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_7_0, cc.rect(28, 28, 1, 1))

	arg_7_0.editbox_ = ccui.EditBox:create(cc.size(530, 60), var_7_0)

	arg_7_0:nodeByName("edit_container"):addChild(arg_7_0.editbox_)
	arg_7_0.editbox_:setAnchorPoint(cc.p(0, 0))
	arg_7_0.editbox_:setPosition(0, 0)
	arg_7_0.editbox_:registerScriptEditBoxHandler(handler(arg_7_0, arg_7_0.inputboxEventHandler))
	arg_7_0.editbox_:setInputFlag(3)

	if not arg_7_0.message or arg_7_0.message == "" then
		arg_7_0:nodeByName("edit_desc"):setString(var_0_1:translation("SEND_PACKET_EDIT_DESC"))
		arg_7_0:nodeByName("edit_desc"):setColor(cc.c3b(185, 185, 185))
	else
		arg_7_0:nodeByName("edit_desc"):setString(arg_7_0.message)
		arg_7_0:nodeByName("edit_desc"):setColor(cc.c3b(255, 255, 255))
	end
end

function var_0_0.inputboxEventHandler(arg_8_0, arg_8_1)
	if arg_8_1 == "began" then
		if not arg_8_0.message or arg_8_0.message == "" then
			arg_8_0:nodeByName("edit_desc"):setString("")
		else
			arg_8_0.editbox_:setText(arg_8_0:nodeByName("edit_desc"):getString())
		end
	end

	if arg_8_1 == "return" then
		local var_8_0 = arg_8_0.editbox_:getText()

		if var_8_0 == "" then
			arg_8_0.message = ""

			arg_8_0:nodeByName("edit_desc"):setString(var_0_1:translation("SEND_PACKET_EDIT_DESC"))
			arg_8_0:nodeByName("edit_desc"):setColor(cc.c3b(185, 185, 185))
		else
			if xyd.utf8len(var_8_0) > 20 then
				var_8_0 = xyd.getTextstr(var_8_0, 1, 20)
			end

			arg_8_0.message = var_8_0

			arg_8_0:nodeByName("edit_desc"):setString(var_8_0)
			arg_8_0:nodeByName("edit_desc"):setColor(cc.c3b(255, 255, 255))
		end

		arg_8_0.editbox_:setText("")
		arg_8_0.editbox_:setVisible(true)
	end
end

return var_0_0
