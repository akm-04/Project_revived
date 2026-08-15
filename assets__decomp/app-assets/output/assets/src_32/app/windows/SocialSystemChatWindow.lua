local var_0_0 = class("SocialSystemChatWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 5
local var_0_3 = 2
local var_0_4 = 747
local var_0_5 = 250
local var_0_6 = 144
local var_0_7 = class("ScrollView", cc.ui.UIListView)

function var_0_7.ctor(arg_1_0, arg_1_1)
	var_0_7.super.ctor(arg_1_0, arg_1_1)
end

function var_0_7.scrollAuto(arg_2_0)
	return
end

function var_0_0.ctor(arg_3_0, arg_3_1, arg_3_2)
	var_0_0.super.ctor(arg_3_0, arg_3_1, arg_3_2)

	arg_3_0.currentFriend = arg_3_2.currentFriend
	arg_3_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_3_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_3_0.Emotion = xyd.ModelManager.get():loadModel(xyd.ModelType.EMOTION)
	arg_3_0.emotionPageNum = math.ceil(arg_3_0.Emotion:allCounts() / (var_0_2 * var_0_3))
	arg_3_0.msgItems = {}
	arg_3_0.num = 2
	arg_3_0.itemwidth = var_0_4
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super.willOpen(arg_4_0, arg_4_1)
	arg_4_0:layout()
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:addBlockLayer()
end

function var_0_0.didClose(arg_6_0, arg_6_1)
	var_0_0.super:didClose(arg_6_1)

	local var_6_0 = xyd.WindowManager.get():getWindow("teacher")

	if var_6_0 and not tolua.isnull(var_6_0) then
		var_6_0.list:reload()
	else
		local var_6_1 = xyd.WindowManager.get():getWindow("social_system")

		if var_6_1 and not tolua.isnull(var_6_1) then
			local var_6_2 = 1

			var_6_1:swapWindowState(var_6_2)
		end
	end
end

function var_0_0.layout(arg_7_0)
	local var_7_0 = {
		avatar_id = arg_7_0.currentFriend.avatar_id,
		avatar_frame_id = arg_7_0.currentFriend.avatar_frame_id
	}

	xyd.setPlayerAvatar(arg_7_0:nodeByName("friend_avatar"), var_7_0)
	arg_7_0.socialSystem:setNameBg(arg_7_0:nodeByName("lev_bg"), arg_7_0.currentFriend)
	arg_7_0.socialSystem:setOnlineState(arg_7_0:nodeByName("tip"), arg_7_0.currentFriend)
	arg_7_0:nodeByName("emotion_container"):setVisible(false)
	arg_7_0:nodeByName("emotion_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			arg_7_0.blockLayer_:setVisible(true)
			arg_7_0:nodeByName("emotion_btn"):setTouchEnabled(false)
			arg_7_0:nodeByName("emotion_container"):setVisible(true)
		end
	end)

	arg_7_0.emotionScroll = arg_7_0:nodeByName("emotion_scroll")

	local var_7_1 = arg_7_0.emotionScroll:getContentSize()

	arg_7_0.emotionList = var_0_7.new({
		async = true,
		viewRect = cc.rect(2, 0, var_7_1.width - 2, var_7_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_7_0.emotionScroll):onScroll(handler(arg_7_0, arg_7_0.scrollListener2))

	arg_7_0.emotionList:setBounceable(true)
	arg_7_0.emotionList:setTouchType(false)
	arg_7_0.emotionList:setDelegate(handler(arg_7_0, arg_7_0.emotionListDelegate))
	arg_7_0.emotionList:reload()
	arg_7_0:updatePointShow()
	arg_7_0.emotionList:scrollTo((1 - arg_7_0.num) * arg_7_0.itemwidth, 0)

	arg_7_0.chatList = arg_7_0:nodeByName("list")

	local var_7_2 = arg_7_0.chatList:getContentSize()

	arg_7_0.rightUpperList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 5, var_7_2.width, var_7_2.height - 20),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_7_0.chatList):onScroll(handler(arg_7_0, arg_7_0.scrollListener))

	arg_7_0.rightUpperList:setBounceable(true)
	arg_7_0.rightUpperList:setDelegate(handler(arg_7_0, arg_7_0.rightUpperListDelegate))
	arg_7_0.rightUpperList:reload()
	arg_7_0:initChatBox()
	arg_7_0:initMessage()
	arg_7_0:updateRightList()
end

function var_0_0.initChatBox(arg_9_0)
	local var_9_0 = xyd.AssetLoader.get()
	local var_9_1 = 24
	local var_9_2 = arg_9_0:nodeByName("edit_container")
	local var_9_3 = "windows/login/transparent.png"
	local var_9_4 = var_9_0:loadSprite(var_9_3)

	arg_9_0.chatBox_ = ccui.EditBox:create(var_9_2:getContentSize(), var_9_3)

	arg_9_0.chatBox_:setAnchorPoint(0, 0)
	arg_9_0.chatBox_:pos(20, 0):addTo(var_9_2)
	arg_9_0.chatBox_:setFont(var_9_0.FONT_NAME, var_9_1)
	arg_9_0.chatBox_:setFontColor(cc.c3b(255, 255, 255))
	arg_9_0.chatBox_:registerScriptEditBoxHandler(handler(arg_9_0, arg_9_0.inputboxEventHandler))
	arg_9_0.chatBox_:setInputFlag(3)
	arg_9_0:nodeByName("edit_desc"):setString("")
	arg_9_0:nodeByName("send_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_10_0, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			local var_10_0 = arg_9_0:nodeByName("edit_desc"):getString()

			if var_10_0 == "" then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("CHAT_MSG_BLANK_ALERT")
				})

				return
			end

			local var_10_1 = {
				player_id = arg_9_0.currentFriend.player_id
			}
			local var_10_2 = {
				message = var_10_0,
				msgType = xyd.FriendMsgType.COMMON
			}

			var_10_1.msg = json.encode(var_10_2)

			arg_9_0.socialSystem:chatToFriend(var_10_1, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					arg_9_0:nodeByName("edit_desc"):setString("")

					local var_11_0 = {
						id = xyd.generateUUID() or "",
						friendID = arg_9_0.currentFriend.player_id,
						playerID = arg_9_0.selfPlayer.playerID,
						message = var_10_0,
						msgType = xyd.FriendMsgType.COMMON,
						time = arg_11_1.server_time or xyd.ServerTime.get():getServerTime()
					}

					var_11_0.isOwnSend = 1

					xyd.db.friendMessages:addFriendMessage(var_11_0)
					table.insert(arg_9_0.data, var_11_0)
					arg_9_0:addMsgItem(var_11_0)
				end
			end)
		end
	end)
end

function var_0_0.initMessage(arg_12_0)
	local var_12_0 = arg_12_0:calculateShowMsgCount()

	arg_12_0.data = xyd.db.friendMessages:getFriendMessages(arg_12_0.selfPlayer.playerID, arg_12_0.currentFriend.player_id, var_12_0)

	arg_12_0:initMsgItems()
end

function var_0_0.updateRightList(arg_13_0)
	arg_13_0.rightUpperList:reload()
	arg_13_0:listScrollToEnd()

	local var_13_0 = {
		friendID = arg_13_0.currentFriend.player_id,
		playerID = arg_13_0.selfPlayer.playerID
	}

	var_13_0.count = 0

	xyd.db.newMessagesCount:setCount(var_13_0)
end

function var_0_0.addBlockLayer(arg_14_0)
	var_0_0.super.addBlockLayer(arg_14_0)
	arg_14_0:nodeByName("emotion_container"):setLocalZOrder(30)

	arg_14_0.blockLayer_ = display.newColorLayer(cc.c4b(0, 0, 0, 100))

	local var_14_0 = arg_14_0:nodeByName("emotion_container")
	local var_14_1, var_14_2 = var_14_0:getPosition()
	local var_14_3 = var_14_0:getParent():convertToWorldSpace(cc.p(var_14_1, var_14_2))

	arg_14_0.blockLayer_:pos(-var_14_3.x, -var_14_3.y):addTo(arg_14_0:nodeByName("emotion_container"), -1)
	arg_14_0.blockLayer_:setContentSize(10000, 10000)
	arg_14_0.blockLayer_:setTouchEnabled(true)
	arg_14_0.blockLayer_:setTouchSwallowEnabled(true)
	arg_14_0.blockLayer_:setVisible(false)
	arg_14_0.blockLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
		if arg_15_0.name == "began" then
			return true
		elseif arg_15_0.name == "ended" then
			arg_14_0.blockLayer_:setVisible(false)
			arg_14_0:nodeByName("emotion_container"):setVisible(false)
			arg_14_0:nodeByName("emotion_btn"):setTouchEnabled(true)
		end
	end)
end

function var_0_0.scrollListener(arg_16_0, arg_16_1)
	if arg_16_1.name == "began" then
		arg_16_0.scrollViewMoved_ = false
		arg_16_0.prevY_ = arg_16_1.y
	elseif arg_16_1.name == "moved" and 10 <= math.abs(arg_16_1.y - arg_16_0.prevY_) then
		arg_16_0.scrollViewMoved_ = true
	end
end

function var_0_0.scrollListener2(arg_17_0, arg_17_1)
	if arg_17_1.name == "began" then
		arg_17_0.scrollViewMoved2_ = false
		arg_17_0.prevx_ = arg_17_1.x
	elseif arg_17_1.name == "moved" then
		if 30 <= math.abs(arg_17_1.x - arg_17_0.prevx_) then
			arg_17_0.scrollViewMoved2_ = true
		end
	elseif arg_17_1.name == "ended" then
		if arg_17_0.prevx_ > arg_17_1.x then
			if arg_17_0.prevx_ - arg_17_1.x > 100 then
				arg_17_0.num = arg_17_0.num + 1

				if arg_17_0.num > arg_17_0.emotionPageNum + 1 then
					arg_17_0.num = 2
				end
			end

			arg_17_0.emotionList:scrollTo((1 - arg_17_0.num) * arg_17_0.itemwidth, 0)

			if arg_17_0.whitePoint then
				arg_17_0.whitePoint:setPosition(arg_17_0:nodeByName("point_pos"):getChildByName("black_point_" .. arg_17_0:getPageByIdx(arg_17_0.num)):getPosition())
			end
		elseif arg_17_0.prevx_ < arg_17_1.x then
			if arg_17_0.prevx_ - arg_17_1.x < -100 then
				arg_17_0.num = arg_17_0.num - 1

				if arg_17_0.num < 2 then
					arg_17_0.num = arg_17_0.emotionPageNum + 1
				end
			end

			arg_17_0.emotionList:scrollTo((1 - arg_17_0.num) * arg_17_0.itemwidth, 0)

			if arg_17_0.whitePoint then
				arg_17_0.whitePoint:setPosition(arg_17_0:nodeByName("point_pos"):getChildByName("black_point_" .. arg_17_0:getPageByIdx(arg_17_0.num)):getPosition())
			end
		end
	end
end

function var_0_0.rightUpperListDelegate(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	if cc.ui.UIListView.COUNT_TAG == arg_18_2 then
		arg_18_0.data = arg_18_0.data or {}

		return #arg_18_0.msgItems
	elseif cc.ui.UIListView.CELL_TAG == arg_18_2 then
		local var_18_0 = arg_18_0.rightUpperList:dequeueItem() or arg_18_0.rightUpperList:newItem()

		var_18_0:removeAllChildren(true)

		local var_18_1 = arg_18_0.msgItems[arg_18_3]

		if var_18_1.reportParams then
			arg_18_0:addRecordShareTouch(var_18_1)
		end

		local var_18_2 = var_18_1:getWidth()
		local var_18_3 = var_18_1:getHeight()

		var_18_0:setItemSize(var_18_2, var_18_3)
		var_18_0:addContent(var_18_1)

		return var_18_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_18_2 then
		arg_18_0.msgItems[arg_18_3]:removeFromParent(false)
	end
end

function var_0_0.addRecordShareTouch(arg_19_0, arg_19_1)
	local var_19_0 = arg_19_1.reportParams
	local var_19_1 = arg_19_1:getChildByName("source"):getChildByName("container"):getChildByName("message_node"):getChildByName("chat_msg")

	var_19_1:setTouchEnabled(true)
	var_19_1:setTouchSwallowEnabled(false)
	var_19_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
		if arg_20_0.name == "ended" and not arg_19_0.scrollViewMoved_ then
			if var_19_0.record_id then
				local var_20_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA)

				var_20_0:getPeakRecordsDetail({
					player_id = var_19_0.player_id,
					record_id = var_19_0.record_id
				}, function(arg_21_0)
					local var_21_0 = var_19_0.player_id == var_19_0.attackInfo.player_id
					local var_21_1 = {
						reportKeys = arg_21_0.report_keys,
						isWin = var_19_0.isWin,
						isAttack = var_21_0,
						wins = arg_21_0.wins,
						attackInfo = var_19_0.attackInfo,
						defendInfo = var_19_0.defendInfo,
						attackTeam = var_20_0:formatTeams(arg_21_0.attack_formations, var_19_0.attackInfo.conquer_lev),
						defendTeam = var_20_0:formatTeams(arg_21_0.defense_formations, var_19_0.defendInfo.conquer_lev)
					}

					xyd.WindowManager.get():openWindow("peak_arena_report", var_21_1)
				end)
			else
				local var_20_1 = {
					fighter_id = var_19_0.player_id,
					id = var_19_0.id
				}

				xyd.Backend.get():request(xyd.mid.LOAD_ARENA_FIGHT_RECORDS, var_20_1, function(arg_22_0, arg_22_1)
					if arg_22_0 == xyd.error.OK then
						local var_22_0 = arg_22_1.records

						if var_22_0.report and next(var_22_0.report) then
							local var_22_1 = {
								report = var_22_0.report,
								attackerName = var_22_0.attack_name,
								attackerLev = var_22_0.attack_lev,
								attackerAvatar = var_22_0.attack_avatar,
								attackerAvatarFrame = var_22_0.attack_avatar_frame,
								defenderName = var_22_0.defend_name,
								defenderLev = var_22_0.defend_lev,
								defenderAvatar = var_22_0.defend_avatar,
								defenderAvatarFrame = var_22_0.defend_avatar_frame,
								isAttack = var_22_0.is_attack,
								win = var_22_0.win
							}

							xyd.WindowManager.get():openWindow("arena_share", var_22_1)
						else
							if xyd.WindowManager.get():getWindow("toast") ~= nil then
								xyd.WindowManager.get():closeWindow("toast")
							end

							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ARENA_RECORD_OUT_OF_DATE")
							})

							return
						end
					end
				end)
			end
		end

		return true
	end)
end

function var_0_0.emotionListDelegate(arg_23_0, arg_23_1, arg_23_2, arg_23_3)
	if cc.ui.UIListView.COUNT_TAG == arg_23_2 then
		if arg_23_0.emotionPageNum <= 1 then
			return arg_23_0.emotionPageNum
		else
			return arg_23_0.emotionPageNum + 2
		end
	elseif cc.ui.UIListView.CELL_TAG == arg_23_2 then
		local var_23_0
		local var_23_1 = arg_23_0.emotionList:dequeueItem()

		if not var_23_1 then
			var_23_1 = arg_23_0.emotionList:newItem()
		else
			var_23_1:removeAllChildren(true)
		end

		local var_23_2 = arg_23_0:createEmotionPage(arg_23_3)
		local var_23_3 = var_23_2:getWidth()
		local var_23_4 = var_23_2:getHeight()

		var_23_1:setItemSize(var_23_3, var_23_4)
		var_23_1:addContent(var_23_2)

		return var_23_1
	end
end

function var_0_0.initMsgItems(arg_24_0)
	arg_24_0:clearMsgItems()

	local var_24_0 = arg_24_0:createChatTitleContent()

	var_24_0:retain()
	table.insert(arg_24_0.msgItems, var_24_0)

	for iter_24_0 = 1, #arg_24_0.data do
		if not arg_24_0:isSameDayAsBeforeMsg(arg_24_0.data, iter_24_0) then
			local var_24_1 = arg_24_0:createChatDayTitleContent(arg_24_0.data[iter_24_0].time)

			var_24_1:retain()
			table.insert(arg_24_0.msgItems, var_24_1)
		end

		local var_24_2 = arg_24_0:createChatMsgContent(arg_24_0.data[iter_24_0])

		var_24_2:retain()
		table.insert(arg_24_0.msgItems, var_24_2)

		if arg_24_0.data[iter_24_0].msgType == xyd.FriendMsgType.REPORT then
			var_24_2.reportParams = json.decode(arg_24_0.data[iter_24_0].message)
		end
	end
end

function var_0_0.createEmotionPage(arg_25_0, arg_25_1)
	arg_25_1 = arg_25_0:getPageByIdx(arg_25_1)

	local var_25_0 = display.newNode()
	local var_25_1 = var_0_6
	local var_25_2 = 110
	local var_25_3
	local var_25_4 = 135
	local var_25_5 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	var_25_0:setContentSize(var_0_4, var_0_5)

	for iter_25_0 = 1, var_0_3 do
		local var_25_6 = 10

		for iter_25_1 = 1, var_0_2 do
			local var_25_7
			local var_25_8 = (arg_25_1 - 1) * var_0_3 * var_0_2 + (iter_25_0 - 1) * var_0_2 + iter_25_1

			if var_25_8 <= arg_25_0.Emotion:allCounts() then
				var_25_7 = arg_25_0:createEmotion(var_25_8)
			else
				return var_25_0
			end

			var_25_7:addTo(var_25_0)
			var_25_7:setPosition(cc.p(var_25_6, var_25_4 - var_25_2 * (iter_25_0 - 1)))

			var_25_6 = var_25_6 + var_25_1

			var_25_7:setTouchEnabled(true)
			var_25_7:setTouchSwallowEnabled(false)
			var_25_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_26_0)
				if arg_26_0.name == "began" then
					if arg_25_0.scrollViewMoved2_ ~= true then
						var_25_7:setScale(0.9)
					end

					return true
				elseif arg_26_0.name == "ended" and arg_25_0.scrollViewMoved2_ ~= true then
					var_25_7:setScale(1)

					if xyd.tables.emoticon:itemID(arg_25_0.Emotion.emotionList[var_25_8].id) == 0 or var_25_5:getBackpack():getItemNumByID(xyd.tables.emoticon:itemID(arg_25_0.Emotion.emotionList[var_25_8].id)) > 0 then
						local var_26_0 = {
							player_id = arg_25_0.currentFriend.player_id
						}
						local var_26_1 = {
							message = arg_25_0.Emotion.emotionList[var_25_8].id,
							msgType = xyd.FriendMsgType.EMOTICON
						}

						var_26_0.msg = json.encode(var_26_1)

						arg_25_0.socialSystem:chatToFriend(var_26_0, function(arg_27_0, arg_27_1)
							if arg_27_0 == xyd.error.OK then
								local var_27_0 = {
									id = xyd.generateUUID() or "",
									friendID = arg_25_0.currentFriend.player_id,
									playerID = arg_25_0.selfPlayer.playerID,
									message = arg_25_0.Emotion.emotionList[var_25_8].id,
									msgType = xyd.FriendMsgType.EMOTICON,
									time = xyd.ServerTime.get():getServerTime()
								}

								var_27_0.isOwnSend = 1

								xyd.db.friendMessages:addFriendMessage(var_27_0)
								table.insert(arg_25_0.data, var_27_0)
								arg_25_0:addMsgItem(var_27_0)
								arg_25_0.blockLayer_:setVisible(false)
								arg_25_0:nodeByName("emotion_container"):setVisible(false)
								arg_25_0:nodeByName("emotion_btn"):setTouchEnabled(true)
							end
						end)
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = xyd.tables.emoticon:lockDesc(arg_25_0.Emotion.emotionList[var_25_8].id)
						})
					end
				end
			end)
		end
	end

	return var_25_0
end

function var_0_0.createEmotion(arg_28_0, arg_28_1)
	local var_28_0 = display.newNode()
	local var_28_1 = xyd.tables.emoticon:isDynamic(arg_28_0.Emotion.emotionList[arg_28_1].id)
	local var_28_2 = xyd.tables.emoticon:image(arg_28_0.Emotion.emotionList[arg_28_1].id)
	local var_28_3 = xyd.tables.emoticon:path(arg_28_0.Emotion.emotionList[arg_28_1].id)
	local var_28_4
	local var_28_5
	local var_28_6 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if xyd.tables.emoticon:itemID(arg_28_0.Emotion.emotionList[arg_28_1].id) == 0 or var_28_6:getBackpack():getItemNumByID(xyd.tables.emoticon:itemID(arg_28_0.Emotion.emotionList[arg_28_1].id)) > 0 then
		if var_28_1 == 1 then
			var_28_4 = xyd.createEffect(var_28_3, 0.7)

			var_28_4:play(nil, true, nil, "halloween")

			var_28_5 = true
		else
			var_28_4 = xyd.AssetLoader.get():loadSprite(var_28_2)
		end
	else
		var_28_4 = display.newFilteredSprite(var_28_2, "GRAY", {
			0.2,
			0.3,
			0.5,
			0.1
		})
	end

	if var_28_1 == 1 and var_28_5 then
		local var_28_7 = cc.ClippingNode:create()
		local var_28_8 = xyd.AssetLoader:get():loadSprite("windows/chat_window/clip.png")

		var_28_7:setStencil(var_28_8)
		var_28_7:setInverted(true)
		var_28_7:setAlphaThreshold(0)
		var_28_7:setAnchorPoint(0.5, 0.5)
		var_28_7:setPosition(73.5, 52)
		var_28_7:addTo(var_28_0)
		var_28_4:setPosition(0, -52)
		var_28_4:addTo(var_28_7)
	else
		var_28_4:setAnchorPoint(cc.p(0.5, 0))
		var_28_4:setPosition(73.5, 0)
		var_28_4:addTo(var_28_0)
	end

	var_28_0:setContentSize(var_0_6, 104)

	return var_28_0
end

function var_0_0.updatePointShow(arg_29_0)
	arg_29_0:nodeByName("point_pos"):removeAllChildren()
	arg_29_0:nodeByName("point_pos"):setLocalZOrder(100)

	local var_29_0 = 24
	local var_29_1 = arg_29_0.emotionPageNum

	if var_29_1 <= 1 then
		arg_29_0.whitePoint = nil

		return
	end

	local var_29_2 = 0 - 24 * var_29_1 / 2

	for iter_29_0 = 1, var_29_1 do
		local var_29_3 = "windows/social_system/chat_wnd/point_black.png"
		local var_29_4 = xyd.AssetLoader:get():loadSprite(var_29_3)

		var_29_4:addTo(arg_29_0:nodeByName("point_pos"))
		var_29_4:setPositionX(var_29_2)
		var_29_4:setName("black_point_" .. iter_29_0)

		var_29_2 = var_29_2 + var_29_0
	end

	if var_29_1 > 0 then
		local var_29_5 = "windows/social_system/chat_wnd/point_white.png"
		local var_29_6 = xyd.AssetLoader:get():loadSprite(var_29_5)

		var_29_6:addTo(arg_29_0:nodeByName("point_pos"))
		var_29_6:setPosition(arg_29_0:nodeByName("point_pos"):getChildByName("black_point_" .. 1):getPosition())
		var_29_6:setName("white_point")

		arg_29_0.whitePoint = var_29_6
	end
end

function var_0_0.getPageByIdx(arg_30_0, arg_30_1)
	if arg_30_0.emotionPageNum <= 1 then
		return 1
	elseif arg_30_1 == 1 then
		return arg_30_0.emotionPageNum
	elseif arg_30_1 == arg_30_0.emotionPageNum + 2 then
		return 1
	else
		return arg_30_1 - 1
	end
end

function var_0_0.inputboxEventHandler(arg_31_0, arg_31_1)
	if arg_31_1 == "return" then
		local var_31_0 = arg_31_0.chatBox_:getText()

		arg_31_0:nodeByName("edit_desc"):setString(var_31_0)
		arg_31_0.chatBox_:setText("")
	elseif arg_31_1 == "began" then
		local var_31_1 = arg_31_0:nodeByName("edit_desc"):getString()

		arg_31_0:nodeByName("edit_desc"):setString("")
		arg_31_0.chatBox_:setText(var_31_1)
	end
end

function var_0_0.addMsgItem(arg_32_0, arg_32_1)
	if not arg_32_0:isSameDayAsBeforeMsg(arg_32_0.data, #arg_32_0.data) then
		local var_32_0 = arg_32_0:createChatDayTitleContent(arg_32_1.time)

		var_32_0:retain()
		table.insert(arg_32_0.msgItems, var_32_0)
	end

	local var_32_1 = arg_32_0:createChatMsgContent(arg_32_1)

	var_32_1:retain()
	table.insert(arg_32_0.msgItems, var_32_1)

	if arg_32_1.msgType == xyd.FriendMsgType.REPORT then
		var_32_1.reportParams = json.decode(arg_32_1.message)
	end

	arg_32_0.rightUpperList:reload()

	local var_32_2 = {
		friendID = arg_32_0.currentFriend.player_id,
		playerID = arg_32_0.selfPlayer.playerID
	}

	var_32_2.count = 0

	xyd.db.newMessagesCount:setCount(var_32_2)
	arg_32_0:listScrollToEnd()
end

function var_0_0.clearMsgItems(arg_33_0)
	for iter_33_0, iter_33_1 in pairs(arg_33_0.msgItems) do
		iter_33_1:release()
	end

	arg_33_0.msgItems = {}
end

function var_0_0.getFriendMessageHeight(arg_34_0)
	local var_34_0 = 0

	for iter_34_0 = 1, #arg_34_0.msgItems do
		if arg_34_0.msgItems[iter_34_0] then
			var_34_0 = var_34_0 + (arg_34_0.msgItems[iter_34_0]:getContentSize().height or 0)
		end
	end

	return var_34_0
end

function var_0_0.calculateShowMsgCount(arg_35_0)
	local var_35_0 = xyd.db.newMessagesCount:getCount(arg_35_0.selfPlayer.playerID, arg_35_0.currentFriend.player_id)

	if var_35_0 < xyd.tables.misc.offlineMessageNumber then
		var_35_0 = xyd.tables.misc.offlineMessageNumber
	end

	return var_35_0
end

function var_0_0.createChatMsgContent(arg_36_0, arg_36_1)
	local var_36_0 = display.newNode()
	local var_36_1
	local var_36_2

	if arg_36_1.isOwnSend == 0 then
		var_36_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/chat_wnd/chat_item_left.csb")
		var_36_2 = var_36_1:getChildByName("container")

		local var_36_3 = {
			avatar_id = arg_36_0.currentFriend.avatar_id,
			avatar_frame_id = arg_36_0.currentFriend.avatar_frame_id,
			playerInfo = arg_36_0.currentFriend
		}

		xyd.setPlayerAvatar(var_36_2:getChildByName("avtar_container"), var_36_3)
	else
		var_36_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/chat_wnd/chat_item_right.csb")
		var_36_2 = var_36_1:getChildByName("container")

		local var_36_4 = {
			avatar_id = arg_36_0.selfPlayer.avatarId,
			avatar_frame_id = arg_36_0.selfPlayer.avatarFrame,
			playerInfo = {
				player_id = arg_36_0.selfPlayer.playerID
			}
		}

		xyd.setPlayerAvatar(var_36_2:getChildByName("avtar_container"), var_36_4)
	end

	arg_36_0:addMsgLabel(var_36_2, arg_36_1)

	local var_36_5 = arg_36_0:createChatMsgTimeLabelContent(arg_36_1.time)

	var_36_5:addTo(var_36_2)

	if arg_36_1.isOwnSend == 0 then
		var_36_5:setPositionX(var_36_2:getChildByName("duihua_bg"):getPositionX() + var_36_2:getChildByName("duihua_bg"):getContentSize().width)
	else
		var_36_5:setAnchorPoint(cc.p(1, 0))
		var_36_5:setPositionX(var_36_2:getChildByName("duihua_bg"):getPositionX() - var_36_2:getChildByName("duihua_bg"):getContentSize().width)
	end

	var_36_5:setPositionY(var_36_2:getChildByName("duihua_bg"):getPositionY() - var_36_2:getChildByName("duihua_bg"):getContentSize().height)
	var_36_1:addTo(var_36_0)
	var_36_1:setAnchorPoint(cc.p(0, 0))

	local var_36_6 = var_36_2:getContentSize().width
	local var_36_7 = var_36_2:getChildByName("duihua_bg"):getContentSize().height + 70

	var_36_0:setContentSize(var_36_6, var_36_7)
	var_36_1:setPositionY(var_36_7 - var_36_2:getContentSize().height)
	var_36_1:setName("source")

	return var_36_0
end

function var_0_0.createChatTitleContent(arg_37_0)
	local var_37_0 = display.newNode()

	var_37_0:setContentSize(789, 80)

	return var_37_0
end

function var_0_0.createChatDayTitleContent(arg_38_0, arg_38_1)
	local var_38_0 = 789
	local var_38_1 = 40
	local var_38_2 = display.newNode()

	var_38_2:setContentSize(var_38_0, var_38_1)

	local var_38_3 = {
		size = 24,
		color = cc.c3b(70, 70, 70)
	}
	local var_38_4 = os.date("*t", arg_38_1)
	local var_38_5 = os.date("%m. %d(%a) ", arg_38_1)

	if var_38_4.year ~= os.date("*t", xyd.ServerTime.get():getServerTime()).year then
		var_38_5 = os.date("%Y. %m. %d(%a) ", arg_38_1)
	end

	local var_38_6 = xyd.AssetLoader.get():loadLabel(var_38_3)

	var_38_6:setAnchorPoint(cc.p(0.5, 0.5))
	var_38_6:setString(var_38_5)
	var_38_6:addTo(var_38_2)
	var_38_6:setPosition(cc.p(var_38_0 / 2, var_38_1 / 2))

	return var_38_2
end

function var_0_0.createChatMsgTimeLabelContent(arg_39_0, arg_39_1)
	local var_39_0 = {
		size = 20,
		color = cc.c3b(120, 120, 120)
	}
	local var_39_1 = os.date("%p %H:%M ", arg_39_1)
	local var_39_2 = xyd.AssetLoader.get():loadLabel(var_39_0)

	var_39_2:setAnchorPoint(cc.p(0, 0))
	var_39_2:setString(var_39_1)

	return var_39_2
end

function var_0_0.addMsgLabel(arg_40_0, arg_40_1, arg_40_2)
	local var_40_0 = 1.2
	local var_40_1 = arg_40_2.message
	local var_40_2

	if arg_40_2.msgType == xyd.FriendMsgType.REPORT then
		var_40_2 = cc.c4b(50, 100, 70, 255)

		local var_40_3 = json.decode(arg_40_2.message)

		var_40_1 = string.format("[%s VS %s]", var_40_3.player_name, var_40_3.enemy_name)
	end

	arg_40_1:getChildByName("message_node"):removeAllChildren()

	local var_40_4

	if arg_40_2.msgType ~= xyd.FriendMsgType.EMOTICON then
		local var_40_5 = {
			size = 24,
			color = var_40_2 or cc.c3b(118, 114, 114)
		}

		var_40_4 = xyd.AssetLoader.get():loadLabel(var_40_5)

		var_40_4:setMaxLineWidth(480)
		var_40_4:setLineBreakWithoutSpace(true)
		var_40_4:setString(var_40_1)
	elseif xyd.tables.emoticon:isDynamic(tonumber(var_40_1)) == 1 then
		var_40_4 = display.newNode()

		var_40_4:setContentSize(150, 104)

		local var_40_6 = xyd.tables.emoticon:path(tonumber(var_40_1))
		local var_40_7 = xyd.createEffect(var_40_6, 0.7)

		var_40_7:play(nil, true, nil, "halloween")

		local var_40_8 = cc.ClippingNode:create()
		local var_40_9 = xyd.AssetLoader:get():loadSprite("windows/chat_window/clip.png")

		var_40_8:setStencil(var_40_9)
		var_40_8:setInverted(true)
		var_40_8:setAlphaThreshold(0)
		var_40_8:setAnchorPoint(0.5, 0.5)
		var_40_8:setPosition(85, 52)
		var_40_8:addTo(var_40_4)
		var_40_7:setPosition(0, -52)
		var_40_7:addTo(var_40_8)
		var_40_4:setScale(var_40_0)
	else
		var_40_4 = xyd.AssetLoader.get():loadSprite(xyd.tables.emoticon:image(tonumber(var_40_1)))

		var_40_4:setScale(var_40_0)
	end

	var_40_4:setAnchorPoint(cc.p(0, 0.5))
	var_40_4:setName("chat_msg")

	local var_40_10 = var_40_4:getContentSize().width
	local var_40_11 = var_40_4:getContentSize().height

	if arg_40_2.msgType == xyd.FriendMsgType.EMOTICON then
		var_40_10 = var_40_10 * var_40_0
		var_40_11 = var_40_11 * var_40_0
	end

	if var_40_11 < arg_40_1:getChildByName("message_node"):getContentSize().height - 16 then
		var_40_11 = arg_40_1:getChildByName("message_node"):getContentSize().height - 16
	end

	arg_40_1:getChildByName("duihua_bg"):height(var_40_11 + 16)
	arg_40_1:getChildByName("duihua_bg"):width(var_40_10 + 60)
	arg_40_1:getChildByName("message_node"):height(var_40_11)
	arg_40_1:getChildByName("message_node"):width(var_40_10)
	var_40_4:addTo(arg_40_1:getChildByName("message_node"))
	var_40_4:setPositionY(var_40_11 / 2)
	arg_40_1:getChildByName("message_node"):setPositionY(arg_40_1:getChildByName("duihua_bg"):getPositionY() - 8)
end

function var_0_0.isSameDayAsBeforeMsg(arg_41_0, arg_41_1, arg_41_2)
	if arg_41_2 <= 1 then
		return false
	else
		local var_41_0 = os.date("*t", arg_41_1[arg_41_2 - 1].time)
		local var_41_1 = os.date("*t", arg_41_1[arg_41_2].time)

		if var_41_0.year == var_41_1.year and var_41_0.yday == var_41_1.yday then
			return true
		else
			return false
		end
	end

	return false
end

function var_0_0.listScrollToEnd(arg_42_0)
	local var_42_0 = arg_42_0:getFriendMessageHeight()
	local var_42_1 = arg_42_0.rightUpperList:getViewRectInWorldSpace()
	local var_42_2 = 0

	if var_42_0 > var_42_1.height then
		var_42_2 = var_42_0 - var_42_1.height
	end

	local var_42_3 = arg_42_0.rightUpperList:getScrollNode()

	var_42_3:setPositionY(var_42_3:getPositionY() + var_42_2 + 30)
end

return var_0_0
