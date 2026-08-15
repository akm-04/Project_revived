local var_0_0 = class("RagnarokChatWnd", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = 4
local var_0_3 = 4
local var_0_4 = 2

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.setParams(arg_3_0, arg_3_1)
	arg_3_0.params = arg_3_1
	arg_3_0.ragnarok = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)
	arg_3_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_3_0.Emotion = xyd.ModelManager.get():loadModel(xyd.ModelType.EMOTION)

	arg_3_0.ragnarok:setChatWnd(arg_3_0)

	arg_3_0.num = 1
	arg_3_0.emotionPageNum = math.ceil(arg_3_0.Emotion:allCounts() / (var_0_3 * var_0_4))

	arg_3_0:initList()
	arg_3_0:layout()
end

function var_0_0.getItems(arg_4_0)
	arg_4_0.ids = arg_4_0.boxTable:ids(arg_4_0.selectIndex)
end

function var_0_0.initList(arg_5_0)
	local var_5_0 = arg_5_0.contentView_:nodeByName("list")
	local var_5_1 = var_5_0:getContentSize()

	arg_5_0.list_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_1.width, var_5_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_5_0)

	arg_5_0.list_:setDelegate(handler(arg_5_0, arg_5_0.delegate))

	arg_5_0.emotionScroll = arg_5_0.contentView_:nodeByName("emotion_scroll")

	local var_5_2 = arg_5_0.emotionScroll:getContentSize()

	arg_5_0.emotionList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(2, 0, var_5_2.width - 2, var_5_2.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_5_0.emotionScroll):onScroll(handler(arg_5_0, arg_5_0.scrollListener2))

	arg_5_0.emotionList:disableScrollAuto(true)
	arg_5_0.emotionList:setBounceable(true)
	arg_5_0.emotionList:setTouchType(false)
	arg_5_0.emotionList:setDelegate(handler(arg_5_0, arg_5_0.emotionListDelegate))
	arg_5_0.emotionList:reload()
	arg_5_0:updatePointShow()
end

function var_0_0.scrollListener2(arg_6_0, arg_6_1)
	arg_6_0.itemwidth = 604

	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved2_ = false
		arg_6_0.prevx_ = arg_6_1.x
	elseif arg_6_1.name == "moved" then
		if 30 <= math.abs(arg_6_1.x - arg_6_0.prevx_) then
			arg_6_0.scrollViewMoved2_ = true
		end
	elseif arg_6_1.name == "ended" then
		if arg_6_0.prevx_ > arg_6_1.x then
			if arg_6_0.prevx_ - arg_6_1.x > 100 then
				arg_6_0.num = arg_6_0.num + 1

				if arg_6_0.num > arg_6_0.emotionPageNum then
					arg_6_0.num = arg_6_0.emotionPageNum
				end
			end

			arg_6_0.emotionList:scrollTo((1 - arg_6_0.num) * arg_6_0.itemwidth, 0)

			if arg_6_0.whitePoint then
				arg_6_0.whitePoint:setPosition(arg_6_0.contentView_:nodeByName("point_pos"):getChildByName("black_point_" .. arg_6_0.num):getPosition())
			end
		elseif arg_6_0.prevx_ < arg_6_1.x then
			if arg_6_0.prevx_ - arg_6_1.x < -100 then
				arg_6_0.num = arg_6_0.num - 1

				if arg_6_0.num < 1 then
					arg_6_0.num = 1
				end
			end

			arg_6_0.emotionList:scrollTo((1 - arg_6_0.num) * arg_6_0.itemwidth, 0)

			if arg_6_0.whitePoint then
				arg_6_0.whitePoint:setPosition(arg_6_0.contentView_:nodeByName("point_pos"):getChildByName("black_point_" .. arg_6_0.num):getPosition())
			end
		end
	end
end

function var_0_0.chatToFriend(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = {
		text = arg_7_1,
		msgType = arg_7_2
	}

	arg_7_0.ragnarok:chatToFriend(var_7_0, function(arg_8_0, arg_8_1)
		if not arg_7_0.contentView_ or tolua.isnull(arg_7_0.contentView_) then
			return
		end

		if arg_8_1.index == 2 then
			local var_8_0 = {
				id = xyd.generateUUID() or "",
				playerInfo = arg_7_0.ragnarok:getPlayerInfoByID(arg_7_0.selfPlayer.playerID),
				message = arg_7_1,
				msgType = arg_7_2,
				selectType = xyd.FriendMsgSelectType.RAGNAROK,
				time = arg_8_1.server_time or xyd.ServerTime.get():getServerTime()
			}

			var_8_0.isOwnSend = 1

			table.insert(arg_7_0.ragnarok.chatData, var_8_0)
			arg_7_0.ragnarok:addMsgItem(var_8_0)
			arg_7_0.blockLayer_:setVisible(false)
			arg_7_0.contentView_:nodeByName("emotion_container"):setVisible(false)
			arg_7_0.contentView_:nodeByName("btn_emotion"):setTouchEnabled(true)

			arg_7_0.text = ""

			arg_7_0.textInput:setString("")
		end
	end)
end

function var_0_0.layout(arg_9_0)
	arg_9_0.contentView_:nodeByName("send_txt"):setString(var_0_1:translation("CHAT_WINDOW_SEND"))
	xyd.nodeEventSample(arg_9_0.contentView_:nodeByName("btn_send"), nil, function()
		dump(arg_9_0.text)

		if arg_9_0.text and arg_9_0.text ~= "" then
			arg_9_0:chatToFriend(arg_9_0.text, xyd.FriendMsgType.COMMON)
		end
	end)
	arg_9_0.contentView_:nodeByName("btn_emotion"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			arg_9_0.contentView_:nodeByName("emotion_container"):setVisible(true)
			arg_9_0.blockLayer_:setVisible(true)
			arg_9_0.contentView_:nodeByName("btn_emotion"):setTouchEnabled(false)
			arg_9_0.contentView_:nodeByName("emotion_container"):setVisible(true)
		end
	end)
	arg_9_0:initEditBox()
	arg_9_0:addBlockLayer()
	arg_9_0.blockLayer_:setVisible(false)
	arg_9_0.contentView_:nodeByName("emotion_container"):setVisible(false)
end

function var_0_0.addBlockLayer(arg_12_0)
	arg_12_0.contentView_:nodeByName("emotion_container"):setLocalZOrder(30)

	arg_12_0.blockLayer_ = display.newColorLayer(cc.c4b(0, 0, 0, 0))

	local var_12_0 = arg_12_0.contentView_:nodeByName("container")
	local var_12_1 = var_12_0:convertToWorldSpace(cc.p(0, 0))

	arg_12_0.blockLayer_:pos(-var_12_1.x, -var_12_1.y):addTo(var_12_0, 20)
	arg_12_0.blockLayer_:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	arg_12_0.blockLayer_:setTouchEnabled(true)
	arg_12_0.blockLayer_:setTouchSwallowEnabled(true)
	arg_12_0.blockLayer_:setVisible(false)
	arg_12_0.blockLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			return true
		elseif arg_13_0.name == "ended" then
			arg_12_0.blockLayer_:setVisible(false)
			arg_12_0.contentView_:nodeByName("emotion_container"):setVisible(false)
			arg_12_0.contentView_:nodeByName("btn_emotion"):setTouchEnabled(true)
		end
	end)
end

function var_0_0.initEditBox(arg_14_0)
	arg_14_0.textInput = arg_14_0.contentView_:nodeByName("text_input")

	arg_14_0.textInput:setString("")

	local var_14_0 = arg_14_0.contentView_:nodeByName("edit_box"):getContentSize()
	local var_14_1 = "windows/login/transparent.png"

	arg_14_0.editBox = ccui.EditBox:create(var_14_0, var_14_1)

	arg_14_0.contentView_:nodeByName("edit_box"):addChild(arg_14_0.editBox)
	arg_14_0.editBox:setAnchorPoint(cc.p(0, 0))
	arg_14_0.editBox:setPosition(0, 0)
	arg_14_0.editBox:registerScriptEditBoxHandler(handler(arg_14_0, arg_14_0.inputContentbox))
	arg_14_0.editBox:setInputFlag(3)
	arg_14_0.editBox:setInputMode(cc.EDITBOX_INPUT_MODE_PAD_NUMBER)
	arg_14_0.editBox:setMaxLength(40)

	if not arg_14_0.text or arg_14_0.text == "" then
		arg_14_0.textInput:setString(var_0_1:translation("RAGNAROK_BOSS_17"))
		arg_14_0.textInput:setColor(cc.c3b(185, 185, 185))
	else
		arg_14_0.textInput:setString(arg_14_0.text)
		arg_14_0.textInput:setColor(cc.c3b(0, 0, 0))
	end
end

function var_0_0.inputContentbox(arg_15_0, arg_15_1)
	if arg_15_1 == "began" then
		if not arg_15_0.text or arg_15_0.text == "" then
			arg_15_0.textInput:setString("")
		else
			arg_15_0.editBox:setText(arg_15_0.textInput:getString())
		end
	elseif arg_15_1 == "return" then
		if not arg_15_0.editBox or tolua.isnull(arg_15_0.editBox) then
			return
		end

		local var_15_0 = arg_15_0.editBox:getText()

		if var_15_0 == "" then
			arg_15_0.text = ""

			arg_15_0.textInput:setString(var_0_1:translation("RAGNAROK_BOSS_17"))
			arg_15_0.textInput:setColor(cc.c3b(185, 185, 185))
		else
			if xyd.utf8len(var_15_0) > 40 then
				var_15_0 = xyd.getTextstr(var_15_0, 1, 40)
			end

			arg_15_0.text = var_15_0

			arg_15_0.textInput:setString(var_15_0)
			arg_15_0.textInput:setColor(cc.c3b(0, 0, 0))
		end

		arg_15_0.editBox:setText("")
		arg_15_0.editBox:setVisible(true)
	end
end

function var_0_0.emotionListDelegate(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	if cc.ui.UIListView.COUNT_TAG == arg_16_2 then
		return arg_16_0.emotionPageNum
	elseif cc.ui.UIListView.CELL_TAG == arg_16_2 then
		local var_16_0
		local var_16_1 = arg_16_0.emotionList:dequeueItem()

		if not var_16_1 then
			var_16_1 = arg_16_0.emotionList:newItem()
		else
			var_16_1:removeAllChildren(true)
		end

		local var_16_2 = arg_16_0:createEmotionPage(arg_16_3)
		local var_16_3 = var_16_2:getWidth()
		local var_16_4 = var_16_2:getHeight()

		var_16_1:setItemSize(var_16_3, var_16_4)
		var_16_1:addContent(var_16_2)

		return var_16_1
	end
end

function var_0_0.createEmotionPage(arg_17_0, arg_17_1)
	local var_17_0 = display.newNode()
	local var_17_1 = 148
	local var_17_2 = 110
	local var_17_3
	local var_17_4 = 135
	local var_17_5 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	var_17_0:setContentSize(604, 244)

	for iter_17_0 = 1, var_0_4 do
		local var_17_6 = 10

		for iter_17_1 = 1, var_0_3 do
			local var_17_7
			local var_17_8 = (arg_17_1 - 1) * var_0_4 * var_0_3 + (iter_17_0 - 1) * var_0_3 + iter_17_1

			if var_17_8 <= arg_17_0.Emotion:allCounts() then
				var_17_7 = arg_17_0:createEmotion(var_17_8)
			else
				return var_17_0
			end

			var_17_7:addTo(var_17_0)
			var_17_7:setPosition(cc.p(var_17_6, var_17_4 - var_17_2 * (iter_17_0 - 1)))

			var_17_6 = var_17_6 + var_17_1

			var_17_7:setTouchEnabled(true)
			var_17_7:setTouchSwallowEnabled(false)
			var_17_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
				if arg_18_0.name == "began" then
					if arg_17_0.scrollViewMoved2_ ~= true then
						var_17_7:setScale(0.9)
					end

					return true
				elseif arg_18_0.name == "ended" and arg_17_0.scrollViewMoved2_ ~= true then
					var_17_7:setScale(1)

					if xyd.tables.emoticon:itemID(arg_17_0.Emotion.emotionList[var_17_8].id) == 0 or var_17_5:getBackpack():getItemNumByID(xyd.tables.emoticon:itemID(arg_17_0.Emotion.emotionList[var_17_8].id)) > 0 then
						arg_17_0:chatToFriend(arg_17_0.Emotion.emotionList[var_17_8].id, xyd.FriendMsgType.EMOTICON)
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = xyd.tables.emoticon:lockDesc(arg_17_0.Emotion.emotionList[var_17_8].id)
						})
					end
				end
			end)
		end
	end

	return var_17_0
end

function var_0_0.createEmotion(arg_19_0, arg_19_1)
	local var_19_0 = display.newNode()
	local var_19_1 = xyd.tables.emoticon:isDynamic(arg_19_0.Emotion.emotionList[arg_19_1].id)
	local var_19_2 = xyd.tables.emoticon:image(arg_19_0.Emotion.emotionList[arg_19_1].id)
	local var_19_3 = xyd.tables.emoticon:path(arg_19_0.Emotion.emotionList[arg_19_1].id)
	local var_19_4
	local var_19_5
	local var_19_6 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if xyd.tables.emoticon:itemID(arg_19_0.Emotion.emotionList[arg_19_1].id) == 0 or var_19_6:getBackpack():getItemNumByID(xyd.tables.emoticon:itemID(arg_19_0.Emotion.emotionList[arg_19_1].id)) > 0 then
		if var_19_1 == 1 then
			var_19_4 = xyd.createEffect(var_19_3, 0.7)

			var_19_4:play(nil, true, nil, "halloween")

			var_19_5 = true
		else
			var_19_4 = xyd.AssetLoader.get():loadSprite(var_19_2)
		end
	else
		var_19_4 = display.newFilteredSprite(var_19_2, "GRAY", {
			0.2,
			0.3,
			0.5,
			0.1
		})
	end

	if var_19_1 == 1 and var_19_5 then
		local var_19_7 = cc.ClippingNode:create()
		local var_19_8 = xyd.AssetLoader:get():loadSprite("windows/chat_window/clip.png")

		var_19_7:setStencil(var_19_8)
		var_19_7:setInverted(true)
		var_19_7:setAlphaThreshold(0)
		var_19_7:setAnchorPoint(0.5, 0.5)
		var_19_7:setPosition(72, 47)
		var_19_7:addTo(var_19_0)
		var_19_4:setPosition(0, -47)
		var_19_4:addTo(var_19_7)
	else
		var_19_4:setAnchorPoint(cc.p(0.5, 0))
		var_19_4:setPosition(72, -5)
		var_19_4:addTo(var_19_0)
	end

	var_19_0:setContentSize(146, 104)

	return var_19_0
end

function var_0_0.updatePointShow(arg_20_0)
	arg_20_0.contentView_:nodeByName("point_pos"):removeAllChildren()
	arg_20_0.contentView_:nodeByName("point_pos"):setLocalZOrder(100)

	local var_20_0 = 24
	local var_20_1 = arg_20_0.emotionPageNum

	if var_20_1 <= 1 then
		arg_20_0.whitePoint = nil

		return
	end

	local var_20_2 = 0 - 24 * var_20_1 / 2

	for iter_20_0 = 1, var_20_1 do
		local var_20_3 = "windows/social_system/chat_wnd/point_black.png"
		local var_20_4 = xyd.AssetLoader:get():loadSprite(var_20_3)

		var_20_4:addTo(arg_20_0.contentView_:nodeByName("point_pos"))
		var_20_4:setPositionX(var_20_2)
		var_20_4:setName("black_point_" .. iter_20_0)

		var_20_2 = var_20_2 + var_20_0
	end

	if var_20_1 > 0 then
		local var_20_5 = "windows/social_system/chat_wnd/point_white.png"
		local var_20_6 = xyd.AssetLoader:get():loadSprite(var_20_5)

		var_20_6:addTo(arg_20_0.contentView_:nodeByName("point_pos"))
		var_20_6:setPosition(arg_20_0.contentView_:nodeByName("point_pos"):getChildByName("black_point_" .. 1):getPosition())
		var_20_6:setName("white_point")

		arg_20_0.whitePoint = var_20_6
	end
end

function var_0_0.updateList(arg_21_0)
	arg_21_0.list_:reload()
	arg_21_0:listScrollToEnd()
end

function var_0_0.contentView(arg_22_0)
	if arg_22_0.contentView_ == nil then
		arg_22_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_22_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1203/ragnarok/chat_wnd.csb"))
		arg_22_0.contentView_:addTo(arg_22_0)
		arg_22_0.contentView_:setTouchSwallowEnabled(true)
	end

	return arg_22_0.contentView_
end

function var_0_0.delegate(arg_23_0, arg_23_1, arg_23_2, arg_23_3)
	local var_23_0 = #arg_23_0.ragnarok.chatData

	if cc.ui.UIListView.COUNT_TAG == arg_23_2 then
		return var_23_0
	elseif cc.ui.UIListView.CELL_TAG == arg_23_2 then
		local var_23_1
		local var_23_2
		local var_23_3
		local var_23_4 = arg_23_0.list_:dequeueItem()

		if not var_23_4 then
			var_23_4 = arg_23_0.list_:newItem()
		else
			var_23_4:removeAllChildren()
		end

		local var_23_5 = arg_23_0.ragnarok.msgItems[arg_23_3]

		var_23_5:setTouchSwallowEnabled(false)
		var_23_5:removeFromParent(false)
		var_23_4:setItemSize(arg_23_0.list_.viewRect_.width, var_23_5:getContentSize().height)
		var_23_4:addContent(var_23_5)

		return var_23_4
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_23_2 then
		arg_23_0.ragnarok.msgItems[arg_23_3]:removeFromParent(false)
	end
end

function var_0_0.createChatMsgTimeLabelContent(arg_24_0, arg_24_1)
	local var_24_0 = {
		size = 20,
		color = cc.c3b(255, 255, 255)
	}
	local var_24_1 = os.date("%p %H:%M ", arg_24_1)
	local var_24_2 = xyd.AssetLoader.get():loadLabel(var_24_0)

	var_24_2:setAnchorPoint(cc.p(0, 0))
	var_24_2:setString(var_24_1)

	return var_24_2
end

function var_0_0.listScrollToEnd(arg_25_0)
	local var_25_0 = arg_25_0:getFriendMessageHeight()
	local var_25_1 = arg_25_0.list_:getViewRectInWorldSpace()
	local var_25_2 = 0

	if var_25_0 > var_25_1.height then
		var_25_2 = var_25_0 - var_25_1.height
	end

	local var_25_3 = arg_25_0.list_:getScrollNode()

	var_25_3:setPositionY(var_25_3:getPositionY() + var_25_2)
end

function var_0_0.getFriendMessageHeight(arg_26_0)
	local var_26_0 = 0

	for iter_26_0 = 1, #arg_26_0.ragnarok.msgItems do
		if arg_26_0.ragnarok.msgItems[iter_26_0] then
			var_26_0 = var_26_0 + (arg_26_0.ragnarok.msgItems[iter_26_0]:getContentSize().height or 0)
		end
	end

	return var_26_0
end

return var_0_0
