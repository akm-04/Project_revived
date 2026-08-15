local var_0_0 = require("framework.scheduler")
local var_0_1 = class("ChatWindow", import("app.common.ui.BaseWindow"))
local var_0_2 = xyd.AssetLoader.get()
local var_0_3 = xyd.tables.translation
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = "[s&i?g&n]"
local var_0_6 = 24
local var_0_7 = 5
local var_0_8 = 2
local var_0_9 = 5
local var_0_10 = 183
local var_0_11 = 191
local var_0_12 = 100
local var_0_13 = 0.2
local var_0_14 = 0.12
local var_0_15 = class("ScrollView", cc.ui.UIListView)

function var_0_15.ctor(arg_1_0, arg_1_1)
	var_0_15.super.ctor(arg_1_0, arg_1_1)
end

function var_0_15.scrollAuto(arg_2_0)
	return
end

function var_0_1.ctor(arg_3_0, arg_3_1, arg_3_2)
	arg_3_0.super.ctor(arg_3_0, arg_3_1, arg_3_2)

	arg_3_0.points = {}
	arg_3_0.toPlayerID = 0
	arg_3_0.pageIndex = 2
	arg_3_0.actionNum = 0
	arg_3_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_3_0.Emotion = xyd.ModelManager.get():loadModel(xyd.ModelType.EMOTION)
	arg_3_0.backpack = arg_3_0.selfPlayer:getBackpack()
	arg_3_0.chatBubble = xyd.ModelManager.get():loadModel(xyd.ModelType.CHAT_BUBBLE)
	arg_3_0.emotionPageNum = math.ceil(arg_3_0.Emotion:allCounts() / (var_0_7 * var_0_8))
	arg_3_0.messageManager = xyd.ModelManager.get():loadModel(xyd.ModelType.MESSAGE_MANAGER)
	arg_3_0.filterWord = xyd.ModelManager.get():loadModel(xyd.ModelType.FILTER_WORD)
end

function var_0_1.willOpen(arg_4_0, arg_4_1)
	arg_4_0:initMainScene()
	arg_4_0:initLabelTag()
	arg_4_0:initChatBox()
	arg_4_0:initTeamChoose()
	arg_4_0:runTagBtnAction()

	arg_4_0.barrages = {}
	arg_4_0.barragesMsg = {}
end

function var_0_1.addBarrageMessage(arg_5_0, arg_5_1)
	if arg_5_0.messageManager:getChannel() == arg_5_0.messageManager.SERVICE_CHANNEL then
		table.insert(arg_5_0.barragesMsg, arg_5_1)
	end
end

function var_0_1.switchToGMChannel(arg_6_0)
	arg_6_0:refreshMainScene()

	local var_6_0 = {}

	xyd.Backend.get():request(xyd.mid.LOAD_GM_QUESTIONS, var_6_0, xyd.backendCallbackWrapper(arg_6_0, function(arg_7_0)
		print("show_load_gm_questtions")

		if arg_7_0 == xyd.error.OK then
			arg_6_0.messageManager:setGmChannelStatus(0)
			arg_6_0:scrollToEnd(true)
		end
	end, {}))
end

function var_0_1.runTagBtnAction(arg_8_0)
	arg_8_0.actionNum = #arg_8_0.actionBtnList

	for iter_8_0 = 1, #arg_8_0.actionBtnList do
		local var_8_0 = arg_8_0:nodeByName("tag_btn" .. arg_8_0.actionBtnList[iter_8_0])
		local var_8_1 = cc.p(var_8_0:getPosition())

		var_8_0:pos(var_8_1.x - var_0_12, var_8_1.y)
		var_8_0:setOpacity(0)
		var_8_0:runAction(cc.Sequence:create({
			cc.DelayTime:create(var_0_14 * (iter_8_0 - 1)),
			cc.Spawn:create({
				cc.MoveBy:create(var_0_13, cc.p(var_0_12, 0)),
				cc.FadeIn:create(var_0_13)
			}),
			cc.CallFunc:create(function()
				arg_8_0.actionNum = arg_8_0.actionNum - 1
			end)
		}))
	end
end

function var_0_1.initLabelTag(arg_10_0)
	arg_10_0.actionBtnList = {
		0,
		1,
		2,
		4,
		5,
		3
	}

	arg_10_0:nodeByName("channel_tip"):setString(var_0_3:translation("CHAT_NO_TALK"))
	arg_10_0:enterRoom(arg_10_0.messageManager:getChannel())

	local var_10_0 = {
		"CHAT_SHIJIE",
		"CHAT_SIREN",
		"CHAT_SHETUAN",
		"CHAT_GM",
		"CHAT_KUAFU",
		"CHAT_ZUDUI"
	}

	for iter_10_0 = 0, 5 do
		local var_10_1 = arg_10_0:nodeByName("tag_btn" .. iter_10_0)

		var_10_1:addTouchEventListener(function(arg_11_0, arg_11_1)
			if arg_11_1 == ccui.TouchEventType.ended and arg_10_0.actionNum <= 0 then
				audio.playSound("sound/tab_button.ogg", false)
				arg_10_0:enterRoom(iter_10_0)
				arg_10_0:updateBarrageBtn()
				arg_10_0:clearBarrages()
			end
		end)

		local var_10_2 = var_10_1:getChildByName("label")

		var_10_2:setString(var_0_3:translation(var_10_0[iter_10_0 + 1]))

		if iter_10_0 == 1 then
			arg_10_0.personName = var_10_2
		end

		local var_10_3 = var_10_1:getContentSize()

		arg_10_0.points[iter_10_0] = var_0_2:loadSprite("windows/common/red_point.png")

		arg_10_0.points[iter_10_0]:addTo(var_10_1)
		arg_10_0.points[iter_10_0]:setPosition(var_10_3.width - 5, var_10_3.height - 5)
		arg_10_0.points[iter_10_0]:setVisible(arg_10_0.messageManager.isNews[iter_10_0] or false)
	end

	if not arg_10_0.messageManager:hasLeague() then
		arg_10_0:nodeByName("tag_btn2"):setVisible(false)
		table.remove(arg_10_0.actionBtnList, 3)

		for iter_10_1 = 3, 5 do
			local var_10_4 = arg_10_0:nodeByName("tag_btn" .. iter_10_1)
			local var_10_5 = cc.p(var_10_4:getPosition())

			var_10_4:pos(var_10_5.x, var_10_5.y + 90)
		end
	end

	if LANGUAGE_VERSION == xyd.LanguageVersion.CN then
		arg_10_0:nodeByName("tag_btn5"):setVisible(false)

		local var_10_6 = arg_10_0:nodeByName("tag_btn3")
		local var_10_7 = cc.p(var_10_6:getPosition())

		var_10_6:pos(var_10_7.x, var_10_7.y + 90)
		table.remove(arg_10_0.actionBtnList, #arg_10_0.actionBtnList - 1)
	end
end

function var_0_1.enterRoom(arg_12_0, arg_12_1)
	arg_12_0:nodeByName("bg_top"):setVisible(arg_12_1 == arg_12_0.messageManager.TEAM_CHANNEL)
	arg_12_0.messageManager:setChannel(arg_12_1)
	arg_12_0:updateTagBtn(arg_12_1)

	if arg_12_1 == arg_12_0.messageManager.GM_CHANNEL then
		arg_12_0:switchToGMChannel()
	else
		arg_12_0:scrollToEnd(true)
	end

	if arg_12_0.points[arg_12_1] then
		arg_12_0.points[arg_12_1]:setVisible(false)
	end

	arg_12_0.messageManager.isNews[arg_12_1] = false

	arg_12_0.messageManager:notifyChat()
end

function var_0_1.updateTagBtn(arg_13_0, arg_13_1)
	for iter_13_0 = 0, 5 do
		local var_13_0 = arg_13_0:nodeByName("tag_btn" .. iter_13_0)

		if iter_13_0 == arg_13_1 then
			var_13_0:setTouchEnabled(false)
			var_13_0:setBright(false)
		else
			var_13_0:setTouchEnabled(true)
			var_13_0:setBright(true)
		end
	end

	if arg_13_1 == 5 then
		arg_13_0:nodeByName("container_bottom"):setVisible(false)
		arg_13_0:nodeByName("channel_tip"):setVisible(true)
	else
		arg_13_0:nodeByName("container_bottom"):setVisible(true)
		arg_13_0:nodeByName("channel_tip"):setVisible(false)
	end
end

function var_0_1.initTeamChoose(arg_14_0)
	arg_14_0:nodeByName("label_team1"):setString(var_0_3:translation("ZUDUI_TIP_PARADISE"))
	arg_14_0:nodeByName("label_team2"):setString(var_0_3:translation("ZUDUI_TIP_MISHU"))
	arg_14_0:nodeByName("label_team3"):setString(var_0_3:translation("ZUDUI_TIP_QIYU"))

	for iter_14_0 = 1, arg_14_0.messageManager.teamTypeNum do
		local var_14_0 = arg_14_0:nodeByName("click_node" .. iter_14_0)

		var_14_0:getChildByName("icon_chosen"):setVisible(arg_14_0.messageManager.teamChoosen[iter_14_0])
		var_14_0:setTouchEnabled(true)
		var_14_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
			if arg_15_0.name == "began" then
				return true
			elseif arg_15_0.name == "ended" then
				arg_14_0.messageManager.teamChoosen[iter_14_0] = not arg_14_0.messageManager.teamChoosen[iter_14_0]

				var_14_0:getChildByName("icon_chosen"):setVisible(arg_14_0.messageManager.teamChoosen[iter_14_0])
				arg_14_0.messageManager:updateTeamList()
				arg_14_0:scrollToEnd(true)
			end
		end)
	end

	arg_14_0.messageManager:updateTeamList()
end

function var_0_1.updatePersonLabel(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_1

	if xyd.getTextLen(arg_16_1) > 4 then
		var_16_0 = xyd.getTextstr(arg_16_1, 0, 4) .. "..."
	end

	arg_16_0.personName:setString(var_16_0)

	if arg_16_2 == nil then
		arg_16_0:enterRoom(1)
	end
end

function var_0_1.updatePointShow(arg_17_0)
	arg_17_0:nodeByName("point_pos"):removeAllChildren()
	arg_17_0:nodeByName("point_pos"):setLocalZOrder(100)

	local var_17_0 = 24
	local var_17_1 = arg_17_0.emotionPageNum

	if var_17_1 <= 1 then
		arg_17_0.whitePoint = nil

		return
	end

	local var_17_2 = 0 - 24 * var_17_1 / 2

	for iter_17_0 = 1, var_17_1 do
		local var_17_3 = "windows/social_system/chat_wnd/point_black.png"
		local var_17_4 = xyd.AssetLoader:get():loadSprite(var_17_3)

		var_17_4:addTo(arg_17_0:nodeByName("point_pos"))
		var_17_4:setPositionX(var_17_2)
		var_17_4:setName("black_point_" .. iter_17_0)

		var_17_2 = var_17_2 + var_17_0
	end

	if var_17_1 > 0 then
		local var_17_5 = "windows/social_system/chat_wnd/point_white.png"
		local var_17_6 = xyd.AssetLoader:get():loadSprite(var_17_5)

		var_17_6:addTo(arg_17_0:nodeByName("point_pos"))
		var_17_6:setPosition(arg_17_0:nodeByName("point_pos"):getChildByName("black_point_" .. 1):getPosition())
		var_17_6:setName("white_point")

		arg_17_0.whitePoint = var_17_6
	end
end

function var_0_1.scrollListener2(arg_18_0, arg_18_1)
	local var_18_0 = arg_18_0:nodeByName("emotion_scroll"):getWidth()

	if arg_18_1.name == "began" then
		arg_18_0.scrollViewMoved2_ = false
		arg_18_0.prevx_ = arg_18_1.x
	elseif arg_18_1.name == "moved" then
		if 30 <= math.abs(arg_18_1.x - arg_18_0.prevx_) then
			arg_18_0.scrollViewMoved2_ = true
		end
	elseif arg_18_1.name == "ended" then
		if arg_18_0.prevx_ > arg_18_1.x then
			if arg_18_0.prevx_ - arg_18_1.x > 100 then
				arg_18_0.pageIndex = arg_18_0.pageIndex + 1

				if arg_18_0.pageIndex > arg_18_0.emotionPageNum + 1 then
					arg_18_0.pageIndex = 2
				end
			end

			arg_18_0.emotionList:scrollTo((1 - arg_18_0.pageIndex) * var_18_0, 0)

			if arg_18_0.whitePoint then
				arg_18_0.whitePoint:setPosition(arg_18_0:nodeByName("point_pos"):getChildByName("black_point_" .. arg_18_0:getPageByIdx(arg_18_0.pageIndex)):getPosition())
			end
		elseif arg_18_0.prevx_ < arg_18_1.x then
			if arg_18_0.prevx_ - arg_18_1.x < -100 then
				arg_18_0.pageIndex = arg_18_0.pageIndex - 1

				if arg_18_0.pageIndex < 2 then
					arg_18_0.pageIndex = arg_18_0.emotionPageNum + 1
				end
			end

			arg_18_0.emotionList:scrollTo((1 - arg_18_0.pageIndex) * var_18_0, 0)

			if arg_18_0.whitePoint then
				arg_18_0.whitePoint:setPosition(arg_18_0:nodeByName("point_pos"):getChildByName("black_point_" .. arg_18_0:getPageByIdx(arg_18_0.pageIndex)):getPosition())
			end
		end
	end
end

function var_0_1.emotionListDelegate(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	if cc.ui.UIListView.COUNT_TAG == arg_19_2 then
		return arg_19_0.emotionPageNum + 2
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

function var_0_1.createEmotion(arg_20_0, arg_20_1)
	local var_20_0 = display.newNode()
	local var_20_1 = xyd.tables.emoticon:isDynamic(arg_20_0.Emotion.emotionList[arg_20_1].id)
	local var_20_2 = xyd.tables.emoticon:image(arg_20_0.Emotion.emotionList[arg_20_1].id)
	local var_20_3 = xyd.tables.emoticon:path(arg_20_0.Emotion.emotionList[arg_20_1].id)
	local var_20_4
	local var_20_5
	local var_20_6 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if xyd.tables.emoticon:itemID(arg_20_0.Emotion.emotionList[arg_20_1].id) == 0 or var_20_6:getBackpack():getItemNumByID(xyd.tables.emoticon:itemID(arg_20_0.Emotion.emotionList[arg_20_1].id)) > 0 then
		if var_20_1 == 1 then
			var_20_4 = xyd.createEffect(var_20_3, 0.7)

			var_20_4:play(nil, true, nil, "halloween")

			var_20_5 = true
		else
			var_20_4 = xyd.AssetLoader.get():loadSprite(var_20_2)
		end
	else
		var_20_4 = display.newFilteredSprite(var_20_2, "GRAY", {
			0.2,
			0.3,
			0.5,
			0.1
		})
	end

	if var_20_1 == 1 and var_20_5 then
		local var_20_7 = cc.ClippingNode:create()
		local var_20_8 = xyd.AssetLoader:get():loadSprite("windows/chat_window/clip.png")

		var_20_7:setStencil(var_20_8)
		var_20_7:setInverted(true)
		var_20_7:setAlphaThreshold(0)
		var_20_7:setAnchorPoint(0.5, 0.5)
		var_20_7:setPosition(72, 47)
		var_20_7:addTo(var_20_0)
		var_20_4:setPosition(0, -47)
		var_20_4:addTo(var_20_7)
	else
		var_20_4:setAnchorPoint(cc.p(0.5, 0))
		var_20_4:setPosition(72, -5)
		var_20_4:addTo(var_20_0)
	end

	var_20_0:setContentSize(146, 104)

	return var_20_0
end

function var_0_1.createEmotionPage(arg_21_0, arg_21_1)
	arg_21_1 = arg_21_0:getPageByIdx(arg_21_1)

	local var_21_0 = display.newNode()
	local var_21_1 = 147
	local var_21_2 = 110
	local var_21_3
	local var_21_4 = 109
	local var_21_5 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	var_21_0:setContentSize(arg_21_0:nodeByName("emotion_scroll"):getWidth(), arg_21_0:nodeByName("emotion_scroll"):getHeight())

	for iter_21_0 = 1, var_0_8 do
		local var_21_6 = 0

		for iter_21_1 = 1, var_0_7 do
			local var_21_7
			local var_21_8 = (arg_21_1 - 1) * var_0_8 * var_0_7 + (iter_21_0 - 1) * var_0_7 + iter_21_1

			if var_21_8 <= arg_21_0.Emotion:allCounts() then
				var_21_7 = arg_21_0:createEmotion(var_21_8)
			else
				return var_21_0
			end

			var_21_7:addTo(var_21_0)
			var_21_7:setPosition(cc.p(var_21_6, var_21_4 - var_21_2 * (iter_21_0 - 1)))

			var_21_6 = var_21_6 + var_21_1

			var_21_7:setTouchEnabled(true)
			var_21_7:setTouchSwallowEnabled(false)
			var_21_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
				if arg_22_0.name == "began" then
					if arg_21_0.scrollViewMoved2_ ~= true then
						var_21_7:setScale(0.9)
					end

					return true
				elseif arg_22_0.name == "ended" and arg_21_0.scrollViewMoved2_ ~= true then
					var_21_7:setScale(1)

					if xyd.tables.emoticon:itemID(arg_21_0.Emotion.emotionList[var_21_8].id) == 0 or var_21_5:getBackpack():getItemNumByID(xyd.tables.emoticon:itemID(arg_21_0.Emotion.emotionList[var_21_8].id)) > 0 then
						arg_21_0:nodeByName("emoticon_btn"):setTouchEnabled(true)

						local var_22_0 = arg_21_0.Emotion.emotionList[var_21_8].id .. "|" .. var_0_5

						arg_21_0:sendMsg(var_22_0, true)
						arg_21_0:nodeByName("emotion_container"):setVisible(false)
						arg_21_0.blockLayer2_:setVisible(false)
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = xyd.tables.emoticon:lockDesc(arg_21_0.Emotion.emotionList[var_21_8].id)
						})
					end
				end
			end)
		end
	end

	return var_21_0
end

function var_0_1.getPageByIdx(arg_23_0, arg_23_1)
	if arg_23_0.emotionPageNum <= 1 then
		return 1
	elseif arg_23_1 == 1 then
		return arg_23_0.emotionPageNum
	elseif arg_23_1 == arg_23_0.emotionPageNum + 2 then
		return 1
	else
		return arg_23_1 - 1
	end
end

function var_0_1.addBlockLayer2(arg_24_0)
	local var_24_0 = arg_24_0:nodeByName("container")
	local var_24_1 = var_24_0:getContentSize()

	arg_24_0.blockLayer2_ = display.newColorLayer(cc.c4b(0, 0, 0, 0))

	arg_24_0.blockLayer2_:pos(-45, 0):addTo(var_24_0)
	arg_24_0.blockLayer2_:setContentSize(var_24_1.width + 45, var_24_1.height)
	arg_24_0.blockLayer2_:setTouchEnabled(true)
	arg_24_0.blockLayer2_:setVisible(false)
	arg_24_0.blockLayer2_:setLocalZOrder(49)
	arg_24_0.blockLayer2_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_25_0)
		if arg_25_0.name == "began" then
			return true
		elseif arg_25_0.name == "ended" then
			arg_24_0.blockLayer2_:setVisible(false)
			arg_24_0:nodeByName("emotion_container"):setVisible(false)
			arg_24_0:nodeByName("emoticon_btn"):setTouchEnabled(true)
		end
	end)
	arg_24_0:nodeByName("emotion_container"):setLocalZOrder(50)
	arg_24_0:nodeByName("emotion_container"):setTouchSwallowEnabled(true)
end

function var_0_1.initChatBox(arg_26_0)
	local var_26_0 = arg_26_0:nodeByName("emotion_scroll"):getContentSize()

	arg_26_0.emotionList = var_0_15.new({
		async = true,
		viewRect = cc.rect(0, 0, var_26_0.width, var_26_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_26_0:nodeByName("emotion_scroll")):onScroll(handler(arg_26_0, arg_26_0.scrollListener2))

	arg_26_0.emotionList:setBounceable(true)
	arg_26_0.emotionList:setTouchType(false)
	arg_26_0.emotionList:setDelegate(handler(arg_26_0, arg_26_0.emotionListDelegate))
	arg_26_0.emotionList:reload()
	arg_26_0.emotionList:scrollTo((1 - arg_26_0.pageIndex) * var_26_0.width, 0)
	arg_26_0:updatePointShow()

	local var_26_1 = arg_26_0:nodeByName("input_box")
	local var_26_2 = "images/input_box.png"

	arg_26_0.chatBox_ = ccui.EditBox:create(var_26_1:getContentSize(), var_26_2)

	arg_26_0.chatBox_:setAnchorPoint(0, 0)
	arg_26_0.chatBox_:setOpacity(0)
	arg_26_0.chatBox_:pos(0, 0):addTo(var_26_1)
	arg_26_0.chatBox_:setFont(var_0_2.FONT_NAME, var_0_6)
	arg_26_0.chatBox_:setPlaceholderFont(var_0_2.FONT_NAME, var_0_6)
	arg_26_0.chatBox_:setPlaceHolder(var_0_3:translation("CHAT_INPUT_MESSAGE"))
	arg_26_0.chatBox_:setPlaceholderFontColor(xyd.color.FONT_K)
	arg_26_0.chatBox_:setFontColor(cc.c3b(0, 0, 0))
	arg_26_0.chatBox_:registerScriptEditBoxHandler(handler(arg_26_0, arg_26_0.inputboxEventHandler))
	arg_26_0.chatBox_:setInputFlag(3)
	arg_26_0:nodeByName("input_txt"):setString("")
	arg_26_0:nodeByName("emoticon_btn"):addTouchEventListener(function(arg_27_0, arg_27_1)
		if arg_27_1 == ccui.TouchEventType.began then
			return true
		elseif arg_27_1 == ccui.TouchEventType.ended then
			arg_26_0.blockLayer2_:setVisible(true)
			arg_26_0:nodeByName("emoticon_btn"):setTouchEnabled(false)
			arg_26_0:nodeByName("emotion_container"):setVisible(true)
		end
	end)
	arg_26_0:nodeByName("btn_bubble"):addTouchEventListener(function(arg_28_0, arg_28_1)
		if arg_28_1 == ccui.TouchEventType.ended then
			arg_26_0.chatBubble:loadBubble(function(arg_29_0)
				if arg_29_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("chat_bubble")
				end
			end)
		end
	end)
	arg_26_0:nodeByName("send_btn"):getChildByName("txt"):setString(var_0_3:translation("CHAT_WINDOW_SEND"))
	arg_26_0:nodeByName("send_btn"):setTouchEnabled(true)
	arg_26_0:nodeByName("send_btn"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_30_0)
		if arg_30_0.name == "began" then
			arg_26_0:nodeByName("send_btn"):setScale(0.9)

			return true
		elseif arg_30_0.name == "cancled" then
			arg_26_0:nodeByName("send_btn"):setScale(1)
		elseif arg_30_0.name == "ended" then
			arg_26_0:nodeByName("send_btn"):setScale(1)
			arg_26_0:sendMsg()
		end
	end)
end

function var_0_1.updateBarrageBtn(arg_31_0)
	if arg_31_0.backpack:getItemNumByID(xyd.tables.misc.chatBarrageItem) <= 0 then
		arg_31_0.isBarrageMessage = false
	end
end

function var_0_1.sendMsg(arg_32_0, arg_32_1, arg_32_2)
	local var_32_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_32_1 = arg_32_0.messageManager:getChannel()

	if not arg_32_0.messageManager.chatLimit then
		arg_32_0.messageManager.chatLimit = {}
	end

	if not arg_32_0.messageManager.chatLimit[1] then
		arg_32_0.messageManager.chatLimit[1] = 0
	end

	if not arg_32_0.messageManager.chatLimit[5] then
		arg_32_0.messageManager.chatLimit[5] = 0
	end

	if arg_32_0.messageManager.chatLimit[1] > 0 and var_32_1 == arg_32_0.messageManager.WORLD_CHANNEL then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_3:translation("TIME_TO_CHAT_ALERT"), arg_32_0.messageManager.chatLimit[1])
		})

		return
	end

	if arg_32_0.messageManager.chatLimit[5] > 0 and var_32_1 == arg_32_0.messageManager.SERVICE_CHANNEL then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_3:translation("TIME_TO_CHAT_ALERT"), arg_32_0.messageManager.chatLimit[5])
		})

		return
	end

	local var_32_2 = arg_32_0:nodeByName("input_txt"):getString()

	if arg_32_1 then
		var_32_2 = arg_32_1
	else
		var_32_2 = arg_32_0:nodeByName("input_txt"):getString()

		local var_32_3 = xyd.split(var_32_2, "|")

		if var_32_3 and var_32_3[1] and var_32_3[2] and var_32_3[2] == var_0_5 then
			arg_32_0:nodeByName("input_txt"):setString("")

			return
		end
	end

	if #var_32_2 == 0 then
		return
	end

	if var_32_1 == arg_32_0.messageManager.GM_CHANNEL then
		local var_32_4 = {
			msg = var_32_2
		}

		xyd.Backend.get():request(xyd.mid.ASK_GM_QUESTION, var_32_4, xyd.backendCallbackWrapper(arg_32_0, function(arg_33_0)
			if arg_33_0 == xyd.error.OK then
				arg_32_0:scrollToEnd()
			end
		end), {
			msg = var_32_2
		})
	else
		if var_32_2 == "@debug" then
			arg_32_0:debugInfo()

			return
		elseif xyd.isDebug() and var_32_2 == "@report" then
			arg_32_0:showReport()

			return
		end

		if xyd.isDebug() and string.sub(var_32_2, 1, 1) == "@" then
			arg_32_0:gmOperation(string.sub(var_32_2, 2))

			return
		end

		if xyd.isDebug() and string.sub(var_32_2, 1, 1) == "!" then
			arg_32_0:helperOperation(string.sub(var_32_2, 2))

			return
		end

		if string.sub(var_32_2, 1, 1) == "@" then
			return
		end

		local var_32_5 = {
			message = var_32_2,
			channel = var_32_1
		}

		if var_32_1 == arg_32_0.messageManager.WORLD_CHANNEL then
			xyd.Backend.get():request(xyd.mid.SEND_CHAT_MESSAGE, var_32_5)
			arg_32_0.messageManager:setChatLimit(xyd.tables.misc.chatLimitTime, 1)
		elseif var_32_1 == arg_32_0.messageManager.SERVICE_CHANNEL then
			if xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):isActivityOpen(xyd.Activities.Ragnarok) then
				xyd.Backend.get():request(xyd.mid.RAGNAROK_MISSION_CHAT, nil, function(arg_34_0, arg_34_1)
					if arg_34_0 == xyd.error.OK then
						-- block empty
					end
				end)
			end

			if arg_32_0.isBarrageMessage and not arg_32_2 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_3:translation("SEND_BARRAGE_COST_TIP"), xyd.tables.misc.chatBarrageLength), function()
					if xyd.utf8len(var_32_2) > xyd.tables.misc.chatBarrageLength then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_3:translation("SEND_BARRAGE_LEN_TIP")
						})
						arg_32_0:nodeByName("input_txt"):setString(var_32_2)

						return
					end

					xyd.Backend.get():request(xyd.mid.SEND_BARRAGE_MESSAGE, {
						msg = var_32_2
					}, function(arg_36_0, arg_36_1)
						if arg_36_0 == xyd.error.OK then
							local var_36_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
							local var_36_1 = arg_32_0.selfPlayer:getBackpack()
							local var_36_2 = {
								itemID = xyd.tables.misc.chatBarrageItem
							}

							var_36_2.itemNum = 1

							var_36_1:removeItem(var_36_2)

							if arg_32_0 and not tolua.isnull(arg_32_0) then
								arg_32_0:updateBarrageBtn()
							end
						end
					end)
					xyd.Backend.get():request(xyd.mid.SEND_CHAT_MESSAGE, var_32_5)
					arg_32_0.messageManager:setChatLimit(xyd.tables.misc.chatLimitTime, 5)
				end, {
					lcallback = function()
						arg_32_0:nodeByName("input_txt"):setString(var_32_2)
					end
				}, nil, arg_32_0.colorMode)
			else
				xyd.Backend.get():request(xyd.mid.SEND_CHAT_MESSAGE, var_32_5)
				arg_32_0.messageManager:setChatLimit(xyd.tables.misc.chatLimitTime, 5)
			end
		elseif var_32_1 == arg_32_0.messageManager.GUILD_CHANNEL then
			if arg_32_0.messageManager:hasLeague() == true then
				local var_32_6 = {
					message = var_32_2,
					channel = var_32_1
				}

				xyd.Backend.get():request(xyd.mid.SEND_CHAT_MESSAGE, var_32_6)
			end
		elseif var_32_1 == arg_32_0.messageManager.PERSONAL_CHANNEL then
			if arg_32_0.toPlayerID ~= 0 then
				var_32_5 = {
					message = var_32_2,
					to_player_id = arg_32_0.toPlayerID
				}

				xyd.Backend.get():request(xyd.mid.CHAT_TO_PLAYER, var_32_5, function(arg_38_0, arg_38_1, arg_38_2)
					if arg_38_0 == xyd.error.OK then
						local var_38_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.CHAT_BUBBLE)
						local var_38_1 = {
							title_info = tostring(var_32_0.titleInfo.title_id) .. "@" .. tostring(var_32_0.titleInfo.unique_id) .. "@" .. tostring(var_32_0.titleInfo.end_time),
							bubble_info = tostring(var_38_0:getBubbleID())
						}
						local var_38_2 = json.encode(var_38_1)

						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.PERSONAL_CHAT_MESSAGE,
							params = {
								message = var_32_2,
								from_player_id = var_32_0.playerID,
								from_player_name = var_32_0.playerName,
								from_player_type = var_32_0.playerType,
								from_player_avatar_id = var_32_0:getMyCurrentAvatarID(),
								from_player_avatar_frame_id = var_32_0.avatarFrame,
								from_player_lev = var_32_0.lev,
								np_info = var_38_2
							}
						})
					end
				end)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("PERSONAL_CHAT_TO_NO_MAN")
				})
			end
		end
	end

	arg_32_0:nodeByName("input_txt"):setString("")
end

function var_0_1.inputboxEventHandler(arg_39_0, arg_39_1)
	if arg_39_1 == "return" then
		local var_39_0 = arg_39_0.filterWord:warningStrGsub(arg_39_0.chatBox_:getText())

		arg_39_0:nodeByName("input_txt"):setString(var_39_0)
		arg_39_0.chatBox_:setText("")
	elseif arg_39_1 == "began" then
		local var_39_1 = arg_39_0.filterWord:warningStrGsub(arg_39_0:nodeByName("input_txt"):getString())

		arg_39_0:nodeByName("input_txt"):setString("")
		arg_39_0.chatBox_:setText(var_39_1)
	end
end

function var_0_1.gmOperation(arg_40_0, arg_40_1)
	arg_40_1 = string.lower(arg_40_1)

	local var_40_0 = {
		essense = 36869,
		spirit_enhance = 36982,
		lvbu_coin = 36923,
		yuanbao = 36865,
		graduate_cer = 36932,
		mapopen = 36872,
		social = 36883,
		conquer_report = 36937,
		region_arena = 36921,
		bless = 36905,
		king_coin = 36919,
		skin_fragment = 36951,
		arena_coin = 36866,
		degree_cer = 36931,
		top_coin = 36902,
		spirit_stone = 36928,
		tongqian = 36864,
		moling = 36873,
		item = 36881,
		conquer_chapter = 36934,
		liwu = 36868,
		add_point = 36949,
		partner = 36901,
		dungeon_coin = 36952,
		open = 36870,
		tili = 36871,
		goldfish = 36954,
		incr_fruit_point = 36972,
		region_coin = 36904,
		dust = 36914,
		add_occult_times = 36944,
		card_match_score = 36956,
		stick_fu_point = 36957,
		lottery_point = 36958,
		remove_super = 36960,
		refresh_force = 36961,
		exp = 36867,
		hero = 36873,
		finish_jigsaw = 36964,
		create_adv = 36947,
		crystal = 36865,
		add_coupon = 36968,
		war_camp_coin = 36945,
		dream_world_open = 36969,
		fuwen = 36880,
		nectar = 36955,
		incr_golden_point = 36973,
		war_camp_boss = 36950,
		compose = 36898,
		invitation = 36882,
		incr_diglett_point = 36974,
		spirit_energy = 36980,
		create_spirit = 36981,
		map_clear = 36940,
		guild_huoyue = 36899,
		rune = 36880,
		conquer_team = 36935,
		incr_beach_point = 36976,
		incr_witch_point = 36977,
		mana = 36864,
		clear_backpack = 36938,
		drink = 36912,
		liquid = 36915,
		gift = 36868,
		ice_core = 36948,
		skill_point = 36929,
		charge = 36896,
		friend_medal = 36930,
		guide = 26,
		gift_push = 36939,
		sky_floor = 36924,
		incr_eco = 36963,
		two_years_partner = 36942,
		friendship_coin = 36922,
		bubble = 36979,
		skillpoint = 36897,
		awake_partner = 36903,
		patent_cer = 36933,
		lucky_star = 36953,
		twice_awake = 36941,
		incr_act_eco = 36965,
		chapter = 36913,
		honor_coin = 36920,
		incr_skin_coin = 36978,
		energy = 36916,
		clear_adv = 36946,
		guild_coin = 36900,
		add_stamp = 36971,
		two_years_sweep = 36943,
		set_roles = 36970,
		buy = 36918,
		add_title = 36966,
		conquer_times = 36936,
		get_guild_hp = 1048576,
		magic_exp = 36917
	}
	local var_40_1 = (function(arg_41_0)
		local var_41_0 = {}

		if arg_41_0 == nil then
			return var_41_0
		end

		while true do
			local var_41_1, var_41_2 = arg_41_0:find(" ")

			if var_41_1 == nil then
				table.insert(var_41_0, arg_41_0)

				break
			else
				table.insert(var_41_0, arg_41_0:sub(1, var_41_1 - 1))

				arg_41_0 = arg_41_0:sub(var_41_2 + 1)
			end
		end

		return var_41_0
	end)(arg_40_1)
	local var_40_2 = {
		player_id = arg_40_0.messageManager.selfPlayerID_
	}
	local var_40_3 = var_40_0[var_40_1[1]]

	if var_40_3 == nil or var_40_3 == "" then
		return
	end

	if var_40_3 == 26 then
		var_40_2.story_id = xyd.GuideStoryType.GUIDE_MAX
		var_40_2.guide_id = xyd.GuideStoryType.GUIDE_ID_SET_DEFENSE
	elseif var_40_3 < 36868 or var_40_3 == 36871 or var_40_3 == 36882 or var_40_3 == 36883 or var_40_3 == 36896 or var_40_3 == 36913 or var_40_3 == 36919 or var_40_3 == 36922 or var_40_3 == 36923 or var_40_3 == 36930 or var_40_3 == 36945 or var_40_3 == 36948 or var_40_3 == 36951 or var_40_3 == 36952 or var_40_3 == 36978 or var_40_3 >= 36954 and var_40_3 <= 36958 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.delta = tonumber(var_40_1[2])
	elseif var_40_3 == 36953 then
		if #var_40_1 ~= 3 then
			return
		end

		var_40_2.act_id = tonumber(var_40_1[2])
		var_40_2.delta = tonumber(var_40_1[3])
	elseif var_40_3 == 36869 then
		if #var_40_1 ~= 3 then
			return
		end

		var_40_2.table_id = tonumber(var_40_1[2])
		var_40_2.num = tonumber(var_40_1[3])
	elseif var_40_3 == 36870 then
		var_40_2.ids = {}

		local var_40_4 = 2

		if var_40_1[2] == "f" then
			var_40_2.force = true
			var_40_4 = 3
		end

		for iter_40_0 = var_40_4, #var_40_1 do
			table.insert(var_40_2.ids, tonumber(var_40_1[iter_40_0]))
		end
	elseif var_40_3 == 36868 or var_40_3 == 36872 or var_40_3 == 36873 or var_40_3 == 36898 or var_40_3 == 36901 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.table_id = tonumber(var_40_1[2])
	elseif var_40_3 == 36880 then
		if #var_40_1 ~= 4 then
			return
		end

		var_40_2.table_id = tonumber(var_40_1[2])
		var_40_2.star = tonumber(var_40_1[3])
		var_40_2.rarity = tonumber(var_40_1[4])
	elseif var_40_3 == 36881 then
		if #var_40_1 ~= 3 then
			return
		end

		var_40_2.table_id = tonumber(var_40_1[2])
		var_40_2.num = tonumber(var_40_1[3])
	elseif var_40_3 == 36899 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.guild_huoyue = tonumber(var_40_1[2])
	elseif var_40_3 == 36920 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.honor_coin = tonumber(var_40_1[2])
	elseif var_40_3 == 36900 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.guild_coin = tonumber(var_40_1[2])
	elseif var_40_3 == 36902 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.top_coin = tonumber(var_40_1[2])
	elseif var_40_3 == 36903 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.table_id = tonumber(var_40_1[2])
	elseif var_40_3 == 36904 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.region_coin = tonumber(var_40_1[2])
	elseif var_40_3 == 36905 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.bless_value = tonumber(var_40_1[2])
	elseif var_40_3 == 36912 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.num = tonumber(var_40_1[2])
	elseif var_40_3 == 36914 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.num = tonumber(var_40_1[2])
	elseif var_40_3 == 36915 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.num = tonumber(var_40_1[2])
	elseif var_40_3 == 36916 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.num = tonumber(var_40_1[2])
	elseif var_40_3 == 36917 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.num = tonumber(var_40_1[2])
	elseif var_40_3 == 36918 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.charge_id = tonumber(var_40_1[2])
	elseif var_40_3 == 36921 then
		if #var_40_1 ~= 3 then
			return
		end

		var_40_2.star = tonumber(var_40_1[2])
		var_40_2.point = tonumber(var_40_1[3])
	elseif var_40_3 == 36928 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.spirit_stone = tonumber(var_40_1[2])
	elseif var_40_3 == 36929 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.skill_point = tonumber(var_40_1[2])
	elseif var_40_3 == 36924 then
		if #var_40_1 ~= 3 then
			return
		end

		var_40_2.floor = tonumber(var_40_1[2])
		var_40_2.floor_type = tonumber(var_40_1[3])
	elseif var_40_3 == 36931 then
		var_40_2.degree_cer = tonumber(var_40_1[2])
	elseif var_40_3 == 36932 then
		var_40_2.graduate_cer = tonumber(var_40_1[2])
	elseif var_40_3 == 36933 then
		var_40_2.patent_cer = tonumber(var_40_1[2])
	elseif var_40_3 == 36934 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.campaign_id = tonumber(var_40_1[2])
	elseif var_40_3 == 36935 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.team_id = tonumber(var_40_1[2])
	elseif var_40_3 == 36936 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.left_times = tonumber(var_40_1[2])
	elseif var_40_3 == 36937 then
		if #var_40_1 ~= 3 then
			return
		end

		var_40_2.campaign_id = tonumber(var_40_1[2])
		var_40_2.team_id = tonumber(var_40_1[3])
	elseif var_40_3 == 36939 then
		var_40_2.gift_id = tonumber(var_40_1[2])
	elseif var_40_3 == 36940 then
		if #var_40_1 ~= 3 then
			return
		end

		var_40_2.xpos = tonumber(var_40_1[2])
		var_40_2.ypos = tonumber(var_40_1[3])
	elseif var_40_3 == 36941 then
		if var_40_1[2] then
			var_40_2.table_id = tonumber(var_40_1[2])
		end
	elseif var_40_3 == 36942 then
		if var_40_1[2] then
			var_40_2.table_id = tonumber(var_40_1[2])
		end
	elseif var_40_3 == 36943 then
		if var_40_1[2] then
			var_40_2.campaign_num = tonumber(var_40_1[2])
		end
	elseif var_40_3 == 36944 then
		if var_40_1[2] then
			var_40_2.times = tonumber(var_40_1[2])
		end
	elseif var_40_3 == 36947 then
		if var_40_1[2] then
			var_40_2.table_id = tonumber(var_40_1[2])
		end

		if var_40_1[3] then
			var_40_2.partner_id = tonumber(var_40_1[3])
		end
	elseif var_40_3 == 36949 then
		if var_40_1[2] then
			var_40_2.add_point = tonumber(var_40_1[2])
		end
	elseif var_40_3 == 36950 then
		if var_40_1[3] then
			var_40_2.map_id = tonumber(var_40_1[2])
			var_40_2.group_id = tonumber(var_40_1[3])
		end
	elseif var_40_3 == 36960 then
		if var_40_1[2] then
			var_40_2.table_id = tonumber(var_40_1[2])
		end
	elseif var_40_3 == 36961 then
		if var_40_1[2] then
			var_40_2.table_id = tonumber(var_40_1[2])
		end
	elseif var_40_3 == 36963 then
		if var_40_1[2] then
			var_40_2.eco_name = var_40_1[2]
		end

		if var_40_1[3] then
			var_40_2.num = tonumber(var_40_1[3])
		end
	elseif var_40_3 == 36965 then
		if var_40_1[2] then
			var_40_2.act_id = tonumber(var_40_1[2])
		end

		if var_40_1[3] then
			var_40_2.num = tonumber(var_40_1[3])
		end
	elseif var_40_3 == 36966 then
		var_40_2.title_id = tonumber(var_40_1[2])

		if var_40_1[3] then
			var_40_2.unique_id = tonumber(var_40_1[3])
		end
	elseif var_40_3 == 36968 then
		if var_40_1[2] then
			var_40_2.slot_id = var_40_1[2]
		end

		if var_40_1[3] then
			var_40_2.buy_times = tonumber(var_40_1[3])
		end
	elseif var_40_3 == 36969 then
		local var_40_5 = {}

		for iter_40_1 = 1, #var_40_1 do
			if iter_40_1 > 1 then
				table.insert(var_40_5, tonumber(var_40_1[iter_40_1]))
			end
		end

		var_40_2.except_ids = var_40_5
	elseif var_40_3 == 36970 then
		local var_40_6 = {}

		for iter_40_2 = 1, #var_40_1 do
			if iter_40_2 > 1 then
				table.insert(var_40_6, tonumber(var_40_1[iter_40_2]))
			end
		end

		var_40_2.roles = var_40_6
	elseif var_40_3 == 36971 then
		if var_40_1[2] then
			var_40_2.add_val = var_40_1[2]
		end
	elseif var_40_3 == 36972 or var_40_3 == 36973 or var_40_3 == 36974 or var_40_3 == 36976 or var_40_3 == 36977 then
		var_40_2.add_point = tonumber(var_40_1[2])
	elseif var_40_3 == 36979 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.bubble_id = tonumber(var_40_1[2])
	elseif var_40_3 == 36980 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.delta = tonumber(var_40_1[2])
	elseif var_40_3 == 36981 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.delta = tonumber(var_40_1[2])
	elseif var_40_3 == 36982 then
		if #var_40_1 ~= 2 then
			return
		end

		var_40_2.delta = tonumber(var_40_1[2])
	elseif var_40_3 == 1048576 then
		arg_40_0:getGuidHpLimit(var_40_1[2], var_40_1[3])

		return
	end

	if var_40_3 == 36901 and not var_40_2.table_id then
		for iter_40_3 = 10001001, 11001099 do
			var_40_2.table_id = iter_40_3

			xyd.Backend.get():request(var_40_3, var_40_2)
		end
	end

	xyd.Backend.get():request(var_40_3, var_40_2)

	if var_40_3 == 36881 then
		local var_40_7 = {}
		local var_40_8 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		var_40_7.itemID = var_40_2.table_id
		var_40_7.itemNum = var_40_2.num

		var_40_8:getBackpack():addItem(var_40_7)
	end
end

function var_0_1.showReport(arg_42_0)
	local var_42_0 = import("app.model.Hero")
	local var_42_1 = cc.FileUtils:getInstance():fullPathForFilename("/res/battle_report/report.txt")
	local var_42_2 = io.readfile(var_42_1)
	local var_42_3 = {}
	local var_42_4 = json.decode(var_42_2)

	var_42_3.herosA = {}
	var_42_3.herosB = {}
	var_42_3.summonMonsters = {}
	var_42_3.campaignType = xyd.CampaignType.ARENA
	var_42_3.battleID = xyd.MapBattleID.ARENA
	var_42_3.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_42_4

	local var_42_5 = {}

	for iter_42_0, iter_42_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_42_6 = string.sub(iter_42_0, 1, 1)
		local var_42_7 = tonumber(string.sub(iter_42_0, 3, 3))

		if var_42_6 == "A" and tonumber(iter_42_1.summon_type) == xyd.summonMonsterType.None then
			local var_42_8 = var_42_0.new()

			var_42_8:populate(iter_42_1.hero)
			var_42_8:setReportData(iter_42_1)

			if isOnlyData then
				var_42_8.harms = iter_42_1.harms
				var_42_8.willDie = (iter_42_1.die_count or 0) ~= -1
			end

			var_42_3.herosA[var_42_7] = var_42_8
		elseif var_42_6 == "A" and tonumber(iter_42_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_42_9 = require("app.model.Pet").new()

			var_42_9:populate(iter_42_1.hero)
			var_42_9:setReportData(iter_42_1)

			if isOnlyData then
				var_42_9.harms = iter_42_1.harms
				var_42_9.willDie = (iter_42_1.die_count or 0) ~= -1
				var_42_3.petA = {
					var_42_9
				}
			else
				var_42_3.petsA = {
					var_42_9
				}
			end
		elseif var_42_6 == "B" and tonumber(iter_42_1.summon_type) == xyd.summonMonsterType.None then
			local var_42_10 = var_42_0.new()

			var_42_10:populate(iter_42_1.hero)
			var_42_10:setReportData(iter_42_1)

			if isOnlyData then
				var_42_10.harms = iter_42_1.harms
				var_42_10.willDie = (iter_42_1.die_count or 0) ~= -1
				var_42_3.herosB[var_42_7] = var_42_10
			else
				var_42_5[var_42_7] = var_42_10
			end
		elseif var_42_6 == "B" and tonumber(iter_42_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_42_11 = require("app.model.Pet").new()

			var_42_11:populate(iter_42_1.hero)
			var_42_11:setReportData(iter_42_1)

			if isOnlyData then
				var_42_11.harms = iter_42_1.harms
				var_42_11.willDie = (iter_42_1.die_count or 0) ~= -1
				var_42_3.petB = {
					var_42_11
				}
			else
				var_42_3.petsB = {
					var_42_11
				}
			end
		elseif tonumber(iter_42_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_42_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_42_12 = var_42_0.new()

			var_42_12:populate(iter_42_1.hero)
			var_42_12:setReportData(iter_42_1)

			var_42_3.summonMonsters[iter_42_0] = var_42_12
		end
	end

	var_42_3.herosB = {
		var_42_5
	}
	var_42_3.reportStar = tonumber(var_42_4.star)

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = xyd.WindowName.arenaRecordWnd,
			status = {
				reports = arg_42_0.report
			}
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_42_3)
end

function var_0_1.helperOperation(arg_43_0, arg_43_1)
	local function var_43_0(arg_44_0)
		local var_44_0 = {}

		if arg_44_0 == nil then
			return var_44_0
		end

		while true do
			local var_44_1, var_44_2 = arg_44_0:find(" ")

			if var_44_1 == nil then
				table.insert(var_44_0, arg_44_0)

				break
			else
				table.insert(var_44_0, arg_44_0:sub(1, var_44_1 - 1))

				arg_44_0 = arg_44_0:sub(var_44_2 + 1)
			end
		end

		return var_44_0
	end

	arg_43_1 = string.lower(arg_43_1)

	local var_43_1 = var_43_0(arg_43_1)

	if arg_43_1 == "exf" then
		import("app.common.ForceExporter").get():save()
	elseif arg_43_1 == "pexf" then
		import("app.common.ForceExporter").get():savePet()
	elseif arg_43_1 == "exp" then
		import("app.common.PointExporter").get():save()
	elseif var_43_1[1] == "spine_check" then
		import("app.common.SpineCheck").get():check(var_43_1[2])
	elseif arg_43_1 == "battle test" then
		xyd.WindowManager.get():openWindow("battle_test")
		arg_43_0:close()
	end
end

function var_0_1.refreshMainScene(arg_45_0, arg_45_1)
	local var_45_0 = xyd.AssetLoader.get()
	local var_45_1 = 26
	local var_45_2 = 35
	local var_45_3 = 958
	local var_45_4 = 10

	local function var_45_5(arg_46_0)
		local var_46_0 = display.newNode()
		local var_46_1 = xyd.color.CHAT_HANGUP
		local var_46_2 = var_45_0:loadLabel({
			size = var_45_1,
			color = var_46_1
		})

		var_46_2:setString("[" .. var_0_3:translation("ANNOUNCEMENT") .. "]")
		var_46_2:setLineHeight(var_45_2)
		var_46_2:setAnchorPoint(0, 0)

		local var_46_3 = var_45_3 - var_46_2:getContentSize().width
		local var_46_4 = var_45_0:loadLabel({
			size = var_45_1,
			color = var_46_1
		})

		var_46_4:setString(arg_46_0)
		var_46_4:setLineHeight(var_45_2)
		var_46_4:setAnchorPoint(0, 0)
		var_46_4:pos(var_46_2:getContentSize().width, 0):addTo(var_46_0)
		var_46_4:setLineBreakWithoutSpace(true)
		var_46_4:setDimensions(var_46_3, 0)
		var_46_0:setContentSize(var_45_3, var_46_4:getContentSize().height)
		var_46_2:pos(0, var_46_0:getContentSize().height - var_46_2:getContentSize().height):addTo(var_46_0)

		return var_46_0
	end

	arg_45_1 = arg_45_1 or {}

	arg_45_0.hangupNode_:removeAllChildren()

	local var_45_6 = 0

	for iter_45_0 = #arg_45_1, 1, -1 do
		local var_45_7 = var_45_5(arg_45_1[iter_45_0])

		var_45_7:pos(0, var_45_6):addTo(arg_45_0.hangupNode_)
		var_45_7:setAnchorPoint(0, 0)

		var_45_6 = var_45_6 + var_45_7:getContentSize().height
	end

	local var_45_8 = arg_45_0:nodeByName("chat_content"):getContentSize()

	arg_45_0.hangupNode_:size(var_45_3, var_45_6):pos(0, var_45_8.height - var_45_6)
	arg_45_0.table_:setContentSize(var_45_8.width, var_45_8.height - var_45_6)
	arg_45_0.table_:setViewRect(cc.rect(0, 0, var_45_8.width, var_45_8.height - var_45_6))

	arg_45_0.table_.redundancyViewVal = 0

	arg_45_0:scrollToEnd(true)
end

function var_0_1.initMainScene(arg_47_0)
	local var_47_0 = arg_47_0:nodeByName("chat_content")

	arg_47_0.messageManager = xyd.ModelManager.get():loadModel(xyd.ModelType.MESSAGE_MANAGER)
	arg_47_0.hangupNode_ = display.newNode()

	arg_47_0.hangupNode_:size(var_47_0:getContentSize().width, 0):pos(0, var_47_0:getContentSize().height):addTo(var_47_0)
	arg_47_0.hangupNode_:setAnchorPoint(0, 0)

	arg_47_0.table_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_47_0:getContentSize().width, var_47_0:getContentSize().height),
		alignment = cc.ui.UIListView.ALIGNMENT_VCENTER,
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):pos(0, 0):addTo(var_47_0):onScroll(handler(arg_47_0, arg_47_0.scrollListener))

	arg_47_0.table_:setAnchorPoint(0, 0)
	arg_47_0.table_:setDelegate(handler(arg_47_0.messageManager, arg_47_0.messageManager.sourceDelegate))
	arg_47_0:nodeByName("unread_message"):setTouchEnabled(true)
	arg_47_0:nodeByName("unread_message"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_48_0)
		if arg_48_0.name == "began" then
			return true
		elseif arg_48_0.name == "ended" then
			arg_47_0:scrollToEnd(true)
		end
	end)
end

function var_0_1.scrollListener(arg_49_0, arg_49_1)
	if arg_49_1.name == "began" then
		-- block empty
	elseif arg_49_1.name == "moved" then
		arg_49_0.scrolly = arg_49_0.table_:getScrollNode():getPositionY()

		if arg_49_0.scrolly >= arg_49_0.messageManager:getTotalHeight() - 100 then
			arg_49_0:nodeByName("unread_container"):setVisible(false)

			arg_49_0.messageManager.unreadNum = 0
		end
	end
end

function var_0_1.didOpen(arg_50_0)
	arg_50_0:addBlockLayer(cc.c4b(0, 0, 0, 70))
	arg_50_0:addBlockLayer2()

	local var_50_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if not var_50_0.playerName or #var_50_0.playerName == 0 then
		xyd.WindowManager.get():openWindow("edit_player_name")
	end

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_50_0):addEventListener(xyd.event.CHAT_UPDATE, function(arg_51_0)
		local var_51_0 = false

		if arg_51_0.params then
			var_51_0 = arg_51_0.params.needReload
		end

		arg_50_0:scrollToEnd(var_51_0)
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_50_0):addEventListener(xyd.event.CHAT_WINDOW_NOTIFY, function(arg_52_0)
		if arg_52_0.params then
			local var_52_0 = arg_52_0.params.channel

			if arg_50_0.points[var_52_0] then
				arg_50_0.points[var_52_0]:setVisible(true)
			end
		end
	end)
	arg_50_0:createScheduler()
end

function var_0_1.scrollToEnd(arg_53_0, arg_53_1)
	local var_53_0 = true

	if arg_53_0.messageManager.needCheckToEnd and arg_53_0.messageManager.needCheckToEnd == true then
		arg_53_0.scrolly = arg_53_0.table_:getScrollNode():getPositionY()
		var_53_0 = (arg_53_0.scrolly == nil or arg_53_0.scrolly > arg_53_0.messageManager:getTotalHeight() - 200) and true or false
		arg_53_0.messageManager.needCheckToEnd = false
	else
		var_53_0 = true
	end

	if var_53_0 == true or arg_53_1 then
		local var_53_1 = arg_53_0.table_:getScrollNode()

		if arg_53_1 then
			arg_53_0.table_:reload()

			if arg_53_0.table_.scrollNode:getPositionY() < arg_53_0.messageManager:getTotalHeight() then
				arg_53_0.table_.scrollNode:stopAllActions()
				arg_53_0.table_.scrollNode:setPositionY(arg_53_0.messageManager:getTotalHeight())
			end
		else
			arg_53_0.table_:refreshList()

			local var_53_2 = arg_53_0.table_.scrollNode:getPositionY()

			if var_53_2 < arg_53_0.messageManager:getTotalHeight() then
				arg_53_0.table_.scrollNode:stopAllActions()
				arg_53_0.table_.scrollNode:runAction(cc.MoveBy:create(1, cc.p(0, arg_53_0.messageManager:getTotalHeight() - var_53_2)))
			end
		end

		arg_53_0:nodeByName("unread_container"):setVisible(false)

		arg_53_0.messageManager.unreadNum = 0
	end

	if arg_53_0.messageManager.unreadNum > 0 then
		arg_53_0:nodeByName("unread_container"):setVisible(true)
		arg_53_0:nodeByName("unread_text"):setString(string.format(var_0_3:translation("CHAT_UNREAD_NUM"), arg_53_0.messageManager.unreadNum))
	end
end

function var_0_1.didClose(arg_54_0)
	if arg_54_0.handle then
		var_0_0.unscheduleGlobal(arg_54_0.handle)

		arg_54_0.handle = nil
	end

	arg_54_0.table_:removeAllItems()
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {}
	})
end

function var_0_1.debugInfo(arg_55_0)
	cc.Director:getInstance():setDisplayStats(true)
	arg_55_0:updateMemoryInfo()
	var_0_0.scheduleGlobal(handler(arg_55_0, arg_55_0.updateMemoryInfo), 5)
end

function var_0_1.updateMemoryInfo(arg_56_0)
	if xyd.memoryLabel_ and tolua.isnull(xyd.memoryLabel_) then
		xyd.memoryLabel_ = nil
	end

	if xyd.memoryLabel_ then
		xyd.memoryLabel_:removeSelf()
	end

	if not display.getRunningScene() then
		return
	end

	local var_56_0 = {
		size = 22,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		color = cc.c4b(255, 255, 255, 255),
		text = string.format("memory use: %0.2f KB", collectgarbage("count"))
	}

	xyd.memoryLabel_ = xyd.AssetLoader.get():loadLabel(var_56_0)

	xyd.memoryLabel_:addTo(display.getRunningScene(), 10000)
	xyd.memoryLabel_:align(display.LEFT_BOTTOM, 10, 70)
	xyd.memoryLabel_:enableOutline(cc.c4b(0, 0, 0, 255), 1)
end

function var_0_1.getGuidHpLimit(arg_57_0, arg_57_1, arg_57_2)
	if not arg_57_1 or not arg_57_2 then
		return
	end

	local var_57_0 = import("app.model.Hero")

	ngx.ctx.battle.battleID = 0

	local var_57_1 = {}
	local var_57_2 = ""

	for iter_57_0 = arg_57_1, arg_57_2 + arg_57_1 do
		local var_57_3 = xyd.tables.battle:monsters(iter_57_0)
		local var_57_4 = {}

		for iter_57_1 = 1, #var_57_3 do
			var_57_4[iter_57_1] = {}

			for iter_57_2 = 1, #var_57_3[iter_57_1] do
				local var_57_5 = var_57_0.new()

				var_57_5:populateWithTableID(var_57_3[iter_57_1][iter_57_2])

				local var_57_6 = arg_57_0:newFighter(var_57_5, xyd.TeamType.A, false)

				var_57_6:init()

				local var_57_7 = var_57_6:getHpLimit()

				table.insert(var_57_4[iter_57_1], {
					table_id = var_57_6:getTableID(),
					hp = var_57_7
				})

				var_57_2 = var_57_2 .. "id:" .. var_57_6:getTableID() .. "  hp:" .. var_57_7 .. "\n"
			end
		end

		table.insert(var_57_1, var_57_4)
	end

	local var_57_8 = cc.FileUtils:getInstance():fullPathForFilename("res/battle_report/guid_hp.txt")

	io.writefile(var_57_8, var_57_2, "w+")
end

function var_0_1.newFighter(arg_58_0, arg_58_1, arg_58_2, arg_58_3)
	local var_58_0 = arg_58_1:className()
	local var_58_1 = ngx.ctx.battle.requireFighter(var_58_0).new({
		is_arena = false
	})

	var_58_1:populateWithHero(arg_58_1)

	return var_58_1
end

function var_0_1.createLabel(arg_59_0, arg_59_1, arg_59_2)
	local var_59_0 = {
		color = arg_59_2 or xyd.color.WHITE,
		size = arg_59_1 or 40
	}
	local var_59_1 = xyd.AssetLoader.get():loadLabel(var_59_0)

	var_59_1:setAnchorPoint(cc.p(1, 0.5))
	var_59_1:enableOutline(cc.c4b(0, 0, 0, 255), 2)

	return var_59_1
end

function var_0_1.createScheduler(arg_60_0)
	if arg_60_0.handle then
		var_0_0.unscheduleGlobal(arg_60_0.handle)

		arg_60_0.handle = nil
	end

	arg_60_0.handle = var_0_0.scheduleGlobal(function()
		arg_60_0:loop()
	end, 0.01)
end

function var_0_1.loop(arg_62_0)
	arg_62_0:updateBarrages()
	arg_62_0:addNewBarrage()
end

function var_0_1.generateBarrageLine(arg_63_0)
	local var_63_0 = {}

	for iter_63_0 = 1, #arg_63_0.barrages do
		local var_63_1 = arg_63_0.barrages[iter_63_0]

		if var_63_1:getPositionX() > 1200 and not xyd.isInTable(var_63_0, var_63_1.barrageLine) then
			table.insert(var_63_0, var_63_1.barrageLine)
		end
	end

	local var_63_2 = {}

	for iter_63_1 = 1, var_0_9 do
		if not xyd.isInTable(var_63_0, iter_63_1) then
			table.insert(var_63_2, iter_63_1)
		end
	end

	if not next(var_63_2) then
		return
	end

	return var_63_2[math.random(1, #var_63_2)]
end

function var_0_1.addNewBarrage(arg_64_0)
	local var_64_0 = arg_64_0:generateBarrageLine()

	if not var_64_0 then
		return
	end

	if not arg_64_0.barragesMsg or not next(arg_64_0.barragesMsg) then
		return
	end

	local var_64_1 = arg_64_0.barragesMsg[1]

	table.remove(arg_64_0.barragesMsg, 1)

	local var_64_2 = arg_64_0:createLabel()

	var_64_2:setString("(S" .. tostring(var_64_1.region) .. ")" .. var_64_1.player_name .. ": " .. var_64_1.msg)

	var_64_2.barrageLine = var_64_0

	var_64_2:addTo(arg_64_0)
	var_64_2:setPosition(cc.p(1280 + var_64_2:getContentSize().width, var_64_0 * 70 + 270))
	table.insert(arg_64_0.barrages, var_64_2)
end

function var_0_1.updateBarrages(arg_65_0)
	for iter_65_0 = #arg_65_0.barrages, 1, -1 do
		local var_65_0 = arg_65_0.barrages[iter_65_0]
		local var_65_1 = var_65_0:getPositionX()

		var_65_0:setPositionX(var_65_1 - 5)

		if var_65_0:getPositionX() <= 0 then
			var_65_0:removeSelf()
			table.remove(arg_65_0.barrages, iter_65_0)
		end
	end
end

function var_0_1.clearBarrages(arg_66_0)
	arg_66_0.barragesMsg = {}

	for iter_66_0 = #arg_66_0.barrages, 1, -1 do
		arg_66_0.barrages[iter_66_0]:removeSelf()
	end

	arg_66_0.barrages = {}
end

return var_0_1
