local var_0_0 = class("GroupChatWnd", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = 4
local var_0_3 = 2

function var_0_0.ctor(arg_2_0)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.FRIEND_CHAT_MESSAGE, handler(arg_2_0, arg_2_0.onFriendChatMessage))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.SERVICE_CHAT_ROOM_MESSAGE, handler(arg_2_0, arg_2_0.onServiceChatMessage))

	arg_2_0.Emotion = xyd.ModelManager.get():loadModel(xyd.ModelType.EMOTION)

	arg_2_0:contentView()
end

function var_0_0.setParams(arg_3_0, arg_3_1)
	arg_3_0.params = arg_3_1
	arg_3_0.selectType = arg_3_1.select_type
	arg_3_0.addWndName = arg_3_1.add_wnd_name
	arg_3_0.roomID = arg_3_1.room_id or 0
	arg_3_0.changeHeight = arg_3_1.change_height or 0
	arg_3_0.chatWndType = arg_3_1.chat_wnd_type or xyd.ChatWndType.FRIEND
	arg_3_0.noClickAvatar = arg_3_1.no_click_avatar or false
	arg_3_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_3_0.chatWndType == xyd.ChatWndType.SERVICE then
		arg_3_0.messageManager = xyd.ModelManager.get():loadModel(xyd.ModelType.MESSAGE_MANAGER)
		arg_3_0.myCamp = arg_3_1.my_camp or 0
		arg_3_0.isAll = arg_3_1.isAll
	else
		arg_3_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
		arg_3_0.memberInfos = arg_3_1.member_infos

		arg_3_0:initSendPlayerIDs()
	end

	arg_3_0.data = {}
	arg_3_0.msgItems = {}
	arg_3_0.num = 1
	arg_3_0.emotionPageNum = math.ceil(arg_3_0.Emotion:allCounts() / (var_0_2 * var_0_3))

	arg_3_0:initList()
	arg_3_0:layout()
end

function var_0_0.initSendPlayerIDs(arg_4_0)
	arg_4_0.playerIDs = table.keys(arg_4_0.memberInfos)

	for iter_4_0 = #arg_4_0.playerIDs, 1, -1 do
		if tonumber(arg_4_0.playerIDs[iter_4_0]) == arg_4_0.selfPlayer.playerID then
			table.remove(arg_4_0.playerIDs, iter_4_0)
		end
	end
end

function var_0_0.changeMember(arg_5_0, arg_5_1, arg_5_2)
	arg_5_0.memberInfos[tostring(arg_5_1)] = arg_5_2

	arg_5_0:initSendPlayerIDs()
end

function var_0_0.getItems(arg_6_0)
	arg_6_0.ids = arg_6_0.boxTable:ids(arg_6_0.selectIndex)
end

function var_0_0.initList(arg_7_0)
	local var_7_0 = arg_7_0.contentView_:nodeByName("list")
	local var_7_1 = var_7_0:getContentSize()

	arg_7_0.list_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_7_1.width, var_7_1.height + arg_7_0.changeHeight),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_7_0)

	arg_7_0.list_:setDelegate(handler(arg_7_0, arg_7_0.delegate))

	arg_7_0.emotionScroll = arg_7_0.contentView_:nodeByName("emotion_scroll")

	local var_7_2 = arg_7_0.emotionScroll:getContentSize()

	arg_7_0.emotionList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(2, 0, var_7_2.width - 2, var_7_2.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_7_0.emotionScroll):onScroll(handler(arg_7_0, arg_7_0.scrollListener2))

	arg_7_0.emotionList:disableScrollAuto(true)
	arg_7_0.emotionList:setBounceable(true)
	arg_7_0.emotionList:setTouchType(false)
	arg_7_0.emotionList:setDelegate(handler(arg_7_0, arg_7_0.emotionListDelegate))
	arg_7_0.emotionList:reload()
	arg_7_0:updatePointShow()
end

function var_0_0.scrollListener2(arg_8_0, arg_8_1)
	arg_8_0.itemwidth = 604

	if arg_8_1.name == "began" then
		arg_8_0.scrollViewMoved2_ = false
		arg_8_0.prevx_ = arg_8_1.x
	elseif arg_8_1.name == "moved" then
		if 30 <= math.abs(arg_8_1.x - arg_8_0.prevx_) then
			arg_8_0.scrollViewMoved2_ = true
		end
	elseif arg_8_1.name == "ended" then
		if arg_8_0.prevx_ > arg_8_1.x then
			if arg_8_0.prevx_ - arg_8_1.x > 100 then
				arg_8_0.num = arg_8_0.num + 1

				if arg_8_0.num > arg_8_0.emotionPageNum then
					arg_8_0.num = arg_8_0.emotionPageNum
				end
			end

			arg_8_0.emotionList:scrollTo((1 - arg_8_0.num) * arg_8_0.itemwidth, 0)

			if arg_8_0.whitePoint then
				arg_8_0.whitePoint:setPosition(arg_8_0.contentView_:nodeByName("point_pos"):getChildByName("black_point_" .. arg_8_0.num):getPosition())
			end
		elseif arg_8_0.prevx_ < arg_8_1.x then
			if arg_8_0.prevx_ - arg_8_1.x < -100 then
				arg_8_0.num = arg_8_0.num - 1

				if arg_8_0.num < 1 then
					arg_8_0.num = 1
				end
			end

			arg_8_0.emotionList:scrollTo((1 - arg_8_0.num) * arg_8_0.itemwidth, 0)

			if arg_8_0.whitePoint then
				arg_8_0.whitePoint:setPosition(arg_8_0.contentView_:nodeByName("point_pos"):getChildByName("black_point_" .. arg_8_0.num):getPosition())
			end
		end
	end
end

function var_0_0.chatToFriends(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = {
		text = arg_9_1,
		msgType = arg_9_2
	}
	local var_9_1 = {
		data = var_9_0,
		player_ids = arg_9_0.playerIDs,
		select_type = arg_9_0.selectType,
		room_id = arg_9_0.roomID
	}

	arg_9_0.socialSystem:chatToFriends(var_9_1, function(arg_10_0, arg_10_1)
		if arg_10_1.index == #var_9_1.player_ids then
			local var_10_0 = {
				id = xyd.generateUUID() or "",
				playerInfo = arg_9_0:getPlayerInfoByID(arg_9_0.selfPlayer.playerID),
				message = arg_9_1,
				msgType = arg_9_2,
				selectType = arg_9_0.selectType,
				roomID = arg_9_0.roomID,
				time = arg_10_1.server_time or xyd.ServerTime.get():getServerTime()
			}

			var_10_0.isOwnSend = 1

			table.insert(arg_9_0.data, var_10_0)
			arg_9_0:addMsgItem(var_10_0)
			arg_9_0.blockLayer_:setVisible(false)
			arg_9_0.contentView_:nodeByName("emotion_container"):setVisible(false)
			arg_9_0.contentView_:nodeByName("btn_emotion"):setTouchEnabled(true)

			arg_9_0.text = ""

			arg_9_0.textInput:setString("")
		end
	end)
end

function var_0_0.chatToService(arg_11_0, arg_11_1, arg_11_2)
	if not arg_11_0.messageManager.chatLimit then
		arg_11_0.messageManager.chatLimit = {}
	end

	if arg_11_0.messageManager.chatLimit[5] and arg_11_0.messageManager.chatLimit[5] > 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_1:translation("TIME_TO_CHAT_ALERT"), arg_11_0.messageManager.chatLimit[5])
		})
	else
		local var_11_0 = {
			type = xyd.ChatTextType.WAR_CAMP,
			message = arg_11_1,
			msgType = arg_11_2,
			selectType = arg_11_0.selectType,
			roomID = arg_11_0.roomID,
			camp = arg_11_0.myCamp
		}
		local var_11_1 = {
			message = json.encode(var_11_0),
			channel = arg_11_0.messageManager.SERVICE_CHANNEL,
			type = xyd.ChatTextType.WAR_CAMP
		}

		xyd.Backend.get():request(xyd.mid.SEND_CHAT_MESSAGE, var_11_1)
		arg_11_0.messageManager:setChatLimit(xyd.tables.misc.chatLimitTime, 5)
		arg_11_0.blockLayer_:setVisible(false)
		arg_11_0.contentView_:nodeByName("emotion_container"):setVisible(false)
		arg_11_0.contentView_:nodeByName("btn_emotion"):setTouchEnabled(true)

		arg_11_0.text = ""

		arg_11_0.textInput:setString("")
	end
end

function var_0_0.layout(arg_12_0)
	arg_12_0.contentView_:nodeByName("send_txt"):setString(var_0_1:translation("CHAT_WINDOW_SEND"))
	xyd.nodeEventSample(arg_12_0.contentView_:nodeByName("btn_send"), nil, function()
		if arg_12_0.text and arg_12_0.text ~= "" then
			if arg_12_0.chatWndType == xyd.ChatWndType.SERVICE then
				arg_12_0:chatToService(arg_12_0.text, xyd.FriendMsgType.COMMON)
			else
				arg_12_0:chatToFriends(arg_12_0.text, xyd.FriendMsgType.COMMON)
			end
		end
	end)
	arg_12_0.contentView_:nodeByName("btn_emotion"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			arg_12_0.contentView_:nodeByName("emotion_container"):setVisible(true)
			arg_12_0.blockLayer_:setVisible(true)
			arg_12_0.contentView_:nodeByName("btn_emotion"):setTouchEnabled(false)
			arg_12_0.contentView_:nodeByName("emotion_container"):setVisible(true)
		end
	end)
	arg_12_0:initEditBox()
	arg_12_0:addBlockLayer()
	arg_12_0.blockLayer_:setVisible(false)
	arg_12_0.contentView_:nodeByName("emotion_container"):setVisible(false)
end

function var_0_0.addBlockLayer(arg_15_0)
	arg_15_0.contentView_:nodeByName("emotion_container"):setLocalZOrder(30)

	arg_15_0.blockLayer_ = display.newColorLayer(cc.c4b(0, 0, 0, 0))

	local var_15_0 = arg_15_0.contentView_:nodeByName("container")
	local var_15_1 = var_15_0:convertToWorldSpace(cc.p(0, 0))

	arg_15_0.blockLayer_:pos(-var_15_1.x, -var_15_1.y):addTo(var_15_0, 20)
	arg_15_0.blockLayer_:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	arg_15_0.blockLayer_:setTouchEnabled(true)
	arg_15_0.blockLayer_:setTouchSwallowEnabled(true)
	arg_15_0.blockLayer_:setVisible(false)
	arg_15_0.blockLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			return true
		elseif arg_16_0.name == "ended" then
			arg_15_0.blockLayer_:setVisible(false)
			arg_15_0.contentView_:nodeByName("emotion_container"):setVisible(false)
			arg_15_0.contentView_:nodeByName("btn_emotion"):setTouchEnabled(true)
		end
	end)
end

function var_0_0.initEditBox(arg_17_0)
	arg_17_0.textInput = arg_17_0.contentView_:nodeByName("text_input")

	arg_17_0.textInput:setString("")

	local var_17_0 = arg_17_0.contentView_:nodeByName("edit_box"):getContentSize()
	local var_17_1 = "windows/login/transparent.png"

	arg_17_0.editBox = ccui.EditBox:create(var_17_0, var_17_1)

	arg_17_0.contentView_:nodeByName("edit_box"):addChild(arg_17_0.editBox)
	arg_17_0.editBox:setAnchorPoint(cc.p(0, 0))
	arg_17_0.editBox:setPosition(0, 0)
	arg_17_0.editBox:registerScriptEditBoxHandler(handler(arg_17_0, arg_17_0.inputContentbox))
	arg_17_0.editBox:setInputFlag(3)
	arg_17_0.editBox:setInputMode(cc.EDITBOX_INPUT_MODE_PAD_NUMBER)
	arg_17_0.editBox:setMaxLength(40)

	if not arg_17_0.text or arg_17_0.text == "" then
		arg_17_0.textInput:setString(var_0_1:translation("ILLUSION_TEAM_TIPS_19"))
		arg_17_0.textInput:setColor(cc.c3b(185, 185, 185))
	else
		arg_17_0.textInput:setString(arg_17_0.text)
		arg_17_0.textInput:setColor(cc.c3b(0, 0, 0))
	end
end

function var_0_0.inputContentbox(arg_18_0, arg_18_1)
	if arg_18_1 == "began" then
		arg_18_0.editBox:setVisible(false)

		if not arg_18_0.text or arg_18_0.text == "" then
			arg_18_0.textInput:setString("")
		else
			arg_18_0.editBox:setText(arg_18_0.textInput:getString())
		end
	elseif arg_18_1 == "return" then
		local var_18_0 = arg_18_0.editBox:getText()

		if var_18_0 == "" then
			arg_18_0.text = ""

			arg_18_0.textInput:setString(var_0_1:translation("ILLUSION_TEAM_TIPS_19"))
			arg_18_0.textInput:setColor(cc.c3b(185, 185, 185))
		else
			if xyd.utf8len(var_18_0) > 40 then
				var_18_0 = xyd.getTextstr(var_18_0, 1, 40)
			end

			arg_18_0.text = var_18_0

			arg_18_0.textInput:setString(var_18_0)
			arg_18_0.textInput:setColor(cc.c3b(0, 0, 0))
		end

		arg_18_0.editBox:setText("")
		arg_18_0.editBox:setVisible(true)
	end
end

function var_0_0.emotionListDelegate(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	if cc.ui.UIListView.COUNT_TAG == arg_19_2 then
		return arg_19_0.emotionPageNum
	elseif cc.ui.UIListView.CELL_TAG == arg_19_2 then
		local var_19_0
		local var_19_1 = arg_19_0.emotionList:dequeueItem()

		if not var_19_1 then
			var_19_1 = arg_19_0.emotionList:newItem()
		else
			var_19_1:removeAllChildren(true)
		end

		local var_19_2 = arg_19_0:createEmotionPage(arg_19_3)
		local var_19_3 = var_19_2:getWidth()
		local var_19_4 = var_19_2:getHeight()

		var_19_1:setItemSize(var_19_3, var_19_4)
		var_19_1:addContent(var_19_2)

		return var_19_1
	end
end

function var_0_0.createEmotionPage(arg_20_0, arg_20_1)
	local var_20_0 = display.newNode()
	local var_20_1 = 148
	local var_20_2 = 110
	local var_20_3
	local var_20_4 = 135
	local var_20_5 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	var_20_0:setContentSize(604, 244)

	for iter_20_0 = 1, var_0_3 do
		local var_20_6 = 10

		for iter_20_1 = 1, var_0_2 do
			local var_20_7
			local var_20_8 = (arg_20_1 - 1) * var_0_3 * var_0_2 + (iter_20_0 - 1) * var_0_2 + iter_20_1

			if var_20_8 <= arg_20_0.Emotion:allCounts() then
				var_20_7 = arg_20_0:createEmotion(var_20_8)
			else
				return var_20_0
			end

			var_20_7:addTo(var_20_0)
			var_20_7:setPosition(cc.p(var_20_6, var_20_4 - var_20_2 * (iter_20_0 - 1)))

			var_20_6 = var_20_6 + var_20_1

			var_20_7:setTouchEnabled(true)
			var_20_7:setTouchSwallowEnabled(false)
			var_20_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_21_0)
				if arg_21_0.name == "began" then
					if arg_20_0.scrollViewMoved2_ ~= true then
						var_20_7:setScale(0.9)
					end

					return true
				elseif arg_21_0.name == "ended" and arg_20_0.scrollViewMoved2_ ~= true then
					var_20_7:setScale(1)

					if xyd.tables.emoticon:itemID(arg_20_0.Emotion.emotionList[var_20_8].id) == 0 or var_20_5:getBackpack():getItemNumByID(xyd.tables.emoticon:itemID(arg_20_0.Emotion.emotionList[var_20_8].id)) > 0 then
						if arg_20_0.chatWndType == xyd.ChatWndType.SERVICE then
							arg_20_0:chatToService(arg_20_0.Emotion.emotionList[var_20_8].id, xyd.FriendMsgType.EMOTICON)
						else
							arg_20_0:chatToFriends(arg_20_0.Emotion.emotionList[var_20_8].id, xyd.FriendMsgType.EMOTICON)
						end
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = xyd.tables.emoticon:lockDesc(arg_20_0.Emotion.emotionList[var_20_8].id)
						})
					end
				end
			end)
		end
	end

	return var_20_0
end

function var_0_0.createEmotion(arg_22_0, arg_22_1)
	local var_22_0 = display.newNode()
	local var_22_1 = xyd.tables.emoticon:image(arg_22_0.Emotion.emotionList[arg_22_1].id)
	local var_22_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_22_3

	if xyd.tables.emoticon:itemID(arg_22_0.Emotion.emotionList[arg_22_1].id) == 0 or var_22_2:getBackpack():getItemNumByID(xyd.tables.emoticon:itemID(arg_22_0.Emotion.emotionList[arg_22_1].id)) > 0 then
		var_22_3 = xyd.AssetLoader.get():loadSprite(var_22_1)
	else
		var_22_3 = display.newFilteredSprite(var_22_1, "GRAY", {
			0.2,
			0.3,
			0.5,
			0.1
		})
	end

	var_22_3:setAnchorPoint(cc.p(0, 0))
	var_22_3:addTo(var_22_0)
	var_22_0:setContentSize(var_22_3:getContentSize())

	return var_22_0
end

function var_0_0.updatePointShow(arg_23_0)
	arg_23_0.contentView_:nodeByName("point_pos"):removeAllChildren()
	arg_23_0.contentView_:nodeByName("point_pos"):setLocalZOrder(100)

	local var_23_0 = 24
	local var_23_1 = arg_23_0.emotionPageNum

	if var_23_1 <= 1 then
		arg_23_0.whitePoint = nil

		return
	end

	local var_23_2 = 0 - 24 * var_23_1 / 2

	for iter_23_0 = 1, var_23_1 do
		local var_23_3 = "windows/social_system/chat_wnd/point_black.png"
		local var_23_4 = xyd.AssetLoader:get():loadSprite(var_23_3)

		var_23_4:addTo(arg_23_0.contentView_:nodeByName("point_pos"))
		var_23_4:setPositionX(var_23_2)
		var_23_4:setName("black_point_" .. iter_23_0)

		var_23_2 = var_23_2 + var_23_0
	end

	if var_23_1 > 0 then
		local var_23_5 = "windows/social_system/chat_wnd/point_white.png"
		local var_23_6 = xyd.AssetLoader:get():loadSprite(var_23_5)

		var_23_6:addTo(arg_23_0.contentView_:nodeByName("point_pos"))
		var_23_6:setPosition(arg_23_0.contentView_:nodeByName("point_pos"):getChildByName("black_point_" .. 1):getPosition())
		var_23_6:setName("white_point")

		arg_23_0.whitePoint = var_23_6
	end
end

function var_0_0.updateList(arg_24_0)
	arg_24_0.list_:reload()
end

function var_0_0.contentView(arg_25_0)
	if arg_25_0.contentView_ == nil then
		arg_25_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_25_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/illusion/cooperation_new/chat_wnd.csb"))
		arg_25_0.contentView_:addTo(arg_25_0)
		arg_25_0.contentView_:setTouchSwallowEnabled(true)
	end

	return arg_25_0.contentView_
end

function var_0_0.delegate(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	local var_26_0 = #arg_26_0.data

	if cc.ui.UIListView.COUNT_TAG == arg_26_2 then
		return var_26_0
	elseif cc.ui.UIListView.CELL_TAG == arg_26_2 then
		local var_26_1
		local var_26_2
		local var_26_3
		local var_26_4 = arg_26_0.list_:dequeueItem()

		if not var_26_4 then
			var_26_4 = arg_26_0.list_:newItem()
		else
			var_26_4:removeAllChildren()
		end

		local var_26_5 = arg_26_0.msgItems[arg_26_3]

		var_26_5:setTouchSwallowEnabled(false)
		var_26_4:setItemSize(arg_26_0.list_.viewRect_.width, var_26_5:getContentSize().height)
		var_26_4:addContent(var_26_5)

		return var_26_4
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_26_2 then
		arg_26_0.msgItems[arg_26_3]:removeFromParent(false)
	end
end

function var_0_0.addMsgItem(arg_27_0, arg_27_1)
	if not arg_27_1.playerInfo then
		return
	end

	local var_27_0 = arg_27_0:createChatMsgContent(arg_27_1)

	var_27_0:retain()
	table.insert(arg_27_0.msgItems, var_27_0)
	arg_27_0.list_:reload()
	arg_27_0:listScrollToEnd()
end

function var_0_0.createChatMsgContent(arg_28_0, arg_28_1)
	local var_28_0 = display.newNode()
	local var_28_1
	local var_28_2

	if arg_28_1.isOwnSend == 0 then
		var_28_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/illusion/cooperation_new/chat_item_left.csb")
		var_28_2 = var_28_1:getChildByName("container")

		local var_28_3 = arg_28_1.playerInfo

		if not arg_28_0.noClickAvatar then
			var_28_3.playerInfo = arg_28_1.playerInfo
		end

		xyd.setPlayerAvatar(var_28_2:getChildByName("avtar_container"), var_28_3)
	else
		var_28_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/illusion/cooperation_new/chat_item_right.csb")
		var_28_2 = var_28_1:getChildByName("container")

		local var_28_4 = arg_28_1.playerInfo

		if not arg_28_0.noClickAvatar then
			var_28_4.playerInfo = arg_28_1.playerInfo
		end

		xyd.setPlayerAvatar(var_28_2:getChildByName("avtar_container"), var_28_4)
	end

	local var_28_5 = var_28_2:getChildByName("text_name")
	local var_28_6 = var_28_2:getChildByName("text_region")

	var_28_5:setString(arg_28_1.playerInfo.player_name)

	local var_28_7 = var_28_5:getContentSize()
	local var_28_8 = cc.p(var_28_5:getPosition())
	local var_28_9 = xyd.getPlayerRegion(arg_28_1.playerInfo.player_id)

	var_28_6:setString("S" .. var_28_9)

	if arg_28_1.isOwnSend == 0 then
		var_28_6:setPositionX(var_28_7.width + var_28_8.x + 5)
	else
		var_28_6:setPositionX(var_28_8.x - var_28_7.width - 5)
	end

	arg_28_0:addMsgLabel(var_28_2, arg_28_1)
	var_28_1:addTo(var_28_0)
	var_28_1:setAnchorPoint(cc.p(0, 0))

	local var_28_10 = var_28_2:getContentSize().width
	local var_28_11 = var_28_2:getChildByName("duihua_bg"):getContentSize().height + 70

	var_28_0:setContentSize(var_28_10, var_28_11)
	var_28_1:setPositionY(var_28_11 - var_28_2:getContentSize().height)
	var_28_1:setName("source")

	return var_28_0
end

function var_0_0.createChatMsgTimeLabelContent(arg_29_0, arg_29_1)
	local var_29_0 = {
		size = 20,
		color = cc.c3b(255, 255, 255)
	}
	local var_29_1 = os.date("%p %H:%M ", arg_29_1)
	local var_29_2 = xyd.AssetLoader.get():loadLabel(var_29_0)

	var_29_2:setAnchorPoint(cc.p(0, 0))
	var_29_2:setString(var_29_1)

	return var_29_2
end

function var_0_0.addMsgLabel(arg_30_0, arg_30_1, arg_30_2)
	local var_30_0 = 1.2
	local var_30_1 = arg_30_2.message
	local var_30_2

	arg_30_1:getChildByName("message_node"):removeAllChildren()

	local var_30_3

	if arg_30_2.msgType ~= xyd.FriendMsgType.EMOTICON then
		local var_30_4 = {
			size = 24,
			color = var_30_2 or cc.c3b(0, 0, 0)
		}

		var_30_3 = xyd.AssetLoader.get():loadLabel(var_30_4)

		var_30_3:setMaxLineWidth(310)
		var_30_3:setLineBreakWithoutSpace(true)
		var_30_3:setString(var_30_1)
	else
		var_30_3 = xyd.AssetLoader.get():loadSprite(xyd.tables.emoticon:image(tonumber(var_30_1)))

		var_30_3:setScale(var_30_0)
	end

	var_30_3:setAnchorPoint(cc.p(0, 0.5))
	var_30_3:setName("chat_msg")

	local var_30_5 = var_30_3:getContentSize().width
	local var_30_6 = var_30_3:getContentSize().height

	if arg_30_2.msgType == xyd.FriendMsgType.EMOTICON then
		var_30_5 = var_30_5 * var_30_0
		var_30_6 = var_30_6 * var_30_0
	end

	if var_30_6 < arg_30_1:getChildByName("message_node"):getContentSize().height then
		var_30_6 = arg_30_1:getChildByName("message_node"):getContentSize().height
	end

	arg_30_1:getChildByName("duihua_bg"):height(var_30_6 + 16)
	arg_30_1:getChildByName("duihua_bg"):width(var_30_5 + 60)
	arg_30_1:getChildByName("message_node"):height(var_30_6)
	arg_30_1:getChildByName("message_node"):width(var_30_5)
	var_30_3:addTo(arg_30_1:getChildByName("message_node"))
	var_30_3:setPositionY(var_30_6 / 2)
	arg_30_1:getChildByName("message_node"):setPositionY(arg_30_1:getChildByName("duihua_bg"):getPositionY() - 8)
end

function var_0_0.onFriendChatMessage(arg_31_0, arg_31_1)
	if arg_31_1.params then
		local var_31_0 = {
			id = xyd.generateUUID() or ""
		}
		local var_31_1 = json.decode(arg_31_1.params.message)

		var_31_0.message = var_31_1.message
		var_31_0.msgType = var_31_1.msgType
		var_31_0.selectType = var_31_1.selectType
		var_31_0.roomID = var_31_1.roomID

		if var_31_0.selectType ~= arg_31_0.selectType or var_31_0.roomID ~= arg_31_0.roomID then
			return
		end

		var_31_0.time = arg_31_1.params.time
		var_31_0.isOwnSend = 0
		var_31_0.playerInfo = arg_31_0:getPlayerInfoByID(arg_31_1.params.friend_id)

		local var_31_2 = var_31_0

		if not arg_31_0.data then
			arg_31_0.data = {}
		end

		table.insert(arg_31_0.data, var_31_2)
		arg_31_0:addMsgItem(var_31_2)

		if arg_31_0.addWndName then
			local var_31_3 = xyd.WindowManager.get():getWindow(arg_31_0.addWndName)

			if var_31_3 and not tolua.isnull(var_31_3) then
				var_31_3:updateRedMark(true)
			end
		end
	end
end

function var_0_0.onServiceChatMessage(arg_32_0, arg_32_1)
	if arg_32_1.params then
		local var_32_0 = arg_32_1.params

		if var_32_0.type == xyd.ChatTextType.WAR_CAMP then
			local var_32_1 = {
				id = xyd.generateUUID() or ""
			}
			local var_32_2 = json.decode(var_32_0.message)

			var_32_1.message = var_32_2.message
			var_32_1.msgType = var_32_2.msgType
			var_32_1.selectType = var_32_2.selectType
			var_32_1.roomID = var_32_2.roomID

			if var_32_1.selectType ~= arg_32_0.selectType or var_32_1.roomID ~= arg_32_0.roomID or not arg_32_0.isAll and arg_32_0.myCamp ~= var_32_2.camp or arg_32_0.isAll and var_32_2.camp ~= 0 then
				return
			end

			if arg_32_0.selfPlayer.playerID == var_32_0.player_id then
				var_32_1.isOwnSend = 1
			else
				var_32_1.isOwnSend = 0
			end

			var_32_1.playerInfo = var_32_0

			local var_32_3 = var_32_1

			if not arg_32_0.data then
				arg_32_0.data = {}
			end

			table.insert(arg_32_0.data, var_32_3)
			arg_32_0:addMsgItem(var_32_3)

			if arg_32_0.addWndName then
				local var_32_4 = xyd.WindowManager.get():getWindow(arg_32_0.addWndName)

				if var_32_4 and not tolua.isnull(var_32_4) then
					var_32_4:updateRedMark(true)
				end
			end
		end
	end
end

function var_0_0.getPlayerInfoByID(arg_33_0, arg_33_1)
	return arg_33_0.memberInfos[tostring(arg_33_1)]
end

function var_0_0.listScrollToEnd(arg_34_0)
	local var_34_0 = arg_34_0:getFriendMessageHeight()
	local var_34_1 = arg_34_0.list_:getViewRectInWorldSpace()
	local var_34_2 = 0

	if var_34_0 > var_34_1.height then
		var_34_2 = var_34_0 - var_34_1.height
	end

	local var_34_3 = arg_34_0.list_:getScrollNode()

	var_34_3:setPositionY(var_34_3:getPositionY() + var_34_2)
end

function var_0_0.getFriendMessageHeight(arg_35_0)
	local var_35_0 = 0

	for iter_35_0 = 1, #arg_35_0.msgItems do
		if arg_35_0.msgItems[iter_35_0] then
			var_35_0 = var_35_0 + (arg_35_0.msgItems[iter_35_0]:getContentSize().height or 0)
		end
	end

	return var_35_0
end

return var_0_0
