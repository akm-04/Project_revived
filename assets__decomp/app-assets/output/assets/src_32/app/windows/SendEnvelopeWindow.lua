local var_0_0 = class("SendEnvelopeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.envelopeIdx = arg_1_2.idx
	arg_1_0.totalNum = arg_1_2.num
	arg_1_0.maxSendNum = arg_1_0.totalNum

	if arg_1_0.maxSendNum > xyd.tables.misc.activityRedPacketMaxNum then
		arg_1_0.maxSendNum = xyd.tables.misc.activityRedPacketMaxNum
	end

	arg_1_0.redEnvelope = xyd.ModelManager.get():loadModel(xyd.ModelType.RED_ENVELOPE)
	arg_1_0.filterWord = xyd.ModelManager.get():loadModel(xyd.ModelType.FILTER_WORD)
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
				id = arg_4_0.envelopeIdx,
				num = arg_4_0.sendNum
			}

			if arg_4_0.message == "" then
				var_5_0.content = var_0_1:translation("SEND_ENVELOPE_EDIT_DESC")
			else
				var_5_0.content = arg_4_0.message
			end

			local var_5_1, var_5_2 = arg_4_0.filterWord:warningStrGsub(var_5_0.content)

			if var_5_2 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ENVELOPE_FILTER_WORD")
				})
			elseif arg_4_0:checkStr(var_5_0.content) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ENVELOPE_FILTER_WORD2")
				})
			else
				arg_4_0.redEnvelope:sendEnvelope(var_5_0, function(arg_6_0, arg_6_1)
					if arg_6_0 == xyd.error.OK then
						if arg_6_1.awards then
							arg_4_0.selfPlayer:handleRewards(arg_6_1.awards)
						end

						arg_4_0.redEnvelope.lastPacketList[arg_4_0.envelopeIdx] = arg_6_1.packet_id

						local var_6_0 = xyd.WindowManager.get():getWindow("red_envelope")

						if var_6_0 then
							arg_4_0.redEnvelope.selfState[arg_4_0.envelopeIdx] = arg_4_0.totalNum - arg_4_0.sendNum

							var_6_0:updateRightListItem(arg_4_0.envelopeIdx)
						end

						xyd.WindowManager.get():closeWindow(arg_4_0.name)
					end
				end)
			end
		end
	end)
	arg_4_0:nodeByName("send_desc"):setString(var_0_1:translation("RED_ENVELOP_SEND_TIP"))

	arg_4_0.barLen = arg_4_0:nodeByName("slide_container"):getContentSize().width

	arg_4_0:updateSendNum()
	arg_4_0:nodeByName("slide_icon"):setTouchEnabled(true)
	arg_4_0:nodeByName("slide_icon"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			return true
		elseif arg_7_0.name == "moved" then
			local var_7_0 = arg_4_0:nodeByName("slide_container"):convertToNodeSpace(cc.p(arg_7_0.x, arg_7_0.y))

			arg_4_0.posX = var_7_0.x

			if arg_4_0.posX < 1e-05 then
				arg_4_0.posX = 1e-05
			elseif arg_4_0.posX > arg_4_0.barLen then
				arg_4_0.posX = arg_4_0.barLen
			end

			arg_4_0:updateSendNum()

			return true
		elseif arg_7_0.name == "ended" then
			-- block empty
		end
	end)
end

function var_0_0.updateSendNum(arg_8_0)
	if not arg_8_0.posX then
		arg_8_0.posX = 1e-05
	end

	local var_8_0 = arg_8_0.posX / arg_8_0.barLen

	arg_8_0.sendNum = math.ceil(arg_8_0.maxSendNum * var_8_0)

	arg_8_0:nodeByName("slide_icon"):setPositionX(arg_8_0.posX)
	arg_8_0:nodeByName("progress_bar"):setPercent(var_8_0 * 100)

	local var_8_1 = xyd.AssetLoader.get():loadLabel(nil, "chargePrice")

	var_8_1:setString(arg_8_0.sendNum)
	arg_8_0:nodeByName("num_pos"):removeAllChildren(true)
	var_8_1:setAnchorPoint(cc.p(0, 0.5))
	var_8_1:addTo(arg_8_0:nodeByName("num_pos"))
end

function var_0_0.initEditBox(arg_9_0)
	arg_9_0:nodeByName("edit_desc"):setString("")

	local var_9_0 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_9_0, cc.rect(28, 28, 1, 1))

	arg_9_0.editbox_ = ccui.EditBox:create(cc.size(530, 60), var_9_0)

	arg_9_0:nodeByName("edit_container"):addChild(arg_9_0.editbox_)
	arg_9_0.editbox_:setAnchorPoint(cc.p(0, 0))
	arg_9_0.editbox_:setPosition(0, 0)
	arg_9_0.editbox_:registerScriptEditBoxHandler(handler(arg_9_0, arg_9_0.inputboxEventHandler))
	arg_9_0.editbox_:setInputFlag(3)

	if not arg_9_0.message or arg_9_0.message == "" then
		arg_9_0:nodeByName("edit_desc"):setString(var_0_1:translation("SEND_ENVELOPE_EDIT_DESC"))
		arg_9_0:nodeByName("edit_desc"):setColor(cc.c3b(185, 185, 185))
	else
		arg_9_0:nodeByName("edit_desc"):setString(arg_9_0.message)
		arg_9_0:nodeByName("edit_desc"):setColor(cc.c3b(255, 255, 255))
	end
end

function var_0_0.inputboxEventHandler(arg_10_0, arg_10_1)
	if arg_10_1 == "began" then
		local var_10_0 = arg_10_0:nodeByName("edit_desc"):getString()

		if not arg_10_0.message or arg_10_0.message == "" then
			arg_10_0:nodeByName("edit_desc"):setString("")
		else
			arg_10_0.editbox_:setText(var_10_0)
		end
	end

	if arg_10_1 == "return" then
		local var_10_1 = arg_10_0.editbox_:getText()

		if var_10_1 == "" then
			arg_10_0.message = ""

			arg_10_0:nodeByName("edit_desc"):setString(var_0_1:translation("SEND_ENVELOPE_EDIT_DESC"))
			arg_10_0:nodeByName("edit_desc"):setColor(cc.c3b(185, 185, 185))
		else
			if xyd.utf8len(var_10_1) > 23 then
				var_10_1 = xyd.getTextstr(var_10_1, 1, 8)
			end

			arg_10_0.message = var_10_1

			arg_10_0:nodeByName("edit_desc"):setString(var_10_1)
			arg_10_0:nodeByName("edit_desc"):setColor(cc.c3b(175, 122, 117))
		end

		arg_10_0.editbox_:setText("")
		arg_10_0.editbox_:setVisible(true)
	end
end

function var_0_0.checkStr(arg_11_0, arg_11_1)
	arg_11_1 = arg_11_1 or ""

	if arg_11_1 == var_0_1:translation("SEND_ENVELOPE_EDIT_DESC") then
		return false
	end

	local var_11_0 = {}
	local var_11_1 = string.len(arg_11_1)

	while arg_11_1 do
		local var_11_2 = string.byte(arg_11_1, 1)

		if var_11_2 == nil then
			break
		end

		if var_11_2 > 127 then
			arg_11_1 = string.sub(arg_11_1, 4, var_11_1)

			return true
		else
			if var_11_2 < 48 or var_11_2 > 57 and var_11_2 < 65 or var_11_2 > 90 and var_11_2 < 97 or var_11_2 > 122 and var_11_2 <= 127 then
				return true
			end

			arg_11_1 = string.sub(arg_11_1, 2, var_11_1)
		end
	end

	return false
end

return var_0_0
