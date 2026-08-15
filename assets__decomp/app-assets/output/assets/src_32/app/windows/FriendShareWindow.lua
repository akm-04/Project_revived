local var_0_0 = class("FriendShareWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.data = arg_1_0.socialSystem.friendlist or {}
	arg_1_0.message = arg_1_2.message
	arg_1_0.isSlectAll = false
	arg_1_0.selectList = {}

	arg_1_0:initSelectList()
end

function var_0_0.initSelectList(arg_2_0)
	for iter_2_0 = 1, #arg_2_0.data do
		arg_2_0.selectList[iter_2_0] = 0
	end
end

function var_0_0.selectAll(arg_3_0)
	for iter_3_0 = 1, #arg_3_0.data do
		arg_3_0.selectList[iter_3_0] = 1
	end
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super.willOpen(arg_4_0, arg_4_1)
	arg_4_0:layout()
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:addBlockLayer()
end

function var_0_0.layout(arg_6_0)
	arg_6_0.scroll = arg_6_0:nodeByName("scroll")

	local var_6_0 = arg_6_0.scroll:getContentSize()

	arg_6_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 20, var_6_0.width, var_6_0.height - 20),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_6_0.scroll):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.list:setBounceable(true)
	arg_6_0.list:setDelegate(handler(arg_6_0, arg_6_0.listDelegate))
	arg_6_0.list:setTouchType(false)
	arg_6_0.list:reload()
	arg_6_0:nodeByName("title_txt"):setString(var_0_1:translation("SHARE_WITH_FRIEND"))
	arg_6_0:nodeByName("social_panel_text"):setString(var_0_1:translation("SOCIAL_PANEL_TEXT"))
	arg_6_0:nodeByName("add_all_friends_text"):setString(var_0_1:translation("ADD_ALL_FRIENDS_TEXT"))
	arg_6_0:nodeByName("select"):setTouchEnabled(true)
	arg_6_0:nodeByName("select"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			return true
		elseif arg_7_0.name == "ended" then
			xyd.playButtonSound()

			if arg_6_0.isSlectAll == false then
				arg_6_0:nodeByName("select"):setOpacity(255)

				arg_6_0.isSlectAll = true

				arg_6_0:selectAll()
				arg_6_0.list:reload()
			else
				arg_6_0:nodeByName("select"):setOpacity(0)

				arg_6_0.isSlectAll = false

				arg_6_0:initSelectList()
				arg_6_0.list:reload()
			end
		end
	end)
	arg_6_0:nodeByName("sure_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			for iter_8_0 = 1, #arg_6_0.selectList do
				if arg_6_0.selectList[iter_8_0] == 1 then
					arg_6_0:shareWithFriend(arg_6_0.data[iter_8_0].player_id)
				end
			end

			xyd.WindowManager.get():closeWindow(arg_6_0)
		end
	end)
end

function var_0_0.shareWithFriend(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_0.message
	local var_9_1 = {
		player_id = arg_9_1
	}
	local var_9_2 = {
		message = arg_9_0.message,
		msgType = xyd.FriendMsgType.REPORT
	}

	var_9_1.msg = json.encode(var_9_2)

	arg_9_0.socialSystem:chatToFriend(var_9_1, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			local var_10_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
			local var_10_1 = {
				id = xyd.generateUUID() or "",
				friendID = arg_9_1,
				playerID = var_10_0.playerID,
				message = var_9_0,
				msgType = xyd.FriendMsgType.REPORT,
				time = xyd.ServerTime.get():getServerTime()
			}

			var_10_1.isOwnSend = 1

			xyd.db.friendMessages:addFriendMessage(var_10_1)
		end
	end)
end

function var_0_0.listDelegate(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	if cc.ui.UIListView.COUNT_TAG == arg_11_2 then
		return #arg_11_0.data
	elseif cc.ui.UIListView.CELL_TAG == arg_11_2 then
		local var_11_0
		local var_11_1 = arg_11_0.list:dequeueItem()

		if not var_11_1 then
			var_11_1 = arg_11_0.list:newItem()
		else
			var_11_1:removeAllChildren(false)
		end

		local var_11_2 = arg_11_0:createListContent(arg_11_0.data[arg_11_3], arg_11_3)
		local var_11_3 = var_11_2:getWidth()
		local var_11_4 = var_11_2:getHeight()

		var_11_1:setItemSize(var_11_3, var_11_4)
		var_11_1:addContent(var_11_2)

		return var_11_1
	end
end

function var_0_0.createListContent(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = display.newNode()
	local var_12_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/friend_share/friend_share_item.csb")
	local var_12_2 = var_12_1:getChildByName("container")
	local var_12_3 = var_12_2:getChildByName("name_bg")
	local var_12_4 = {
		avatar_id = arg_12_1.avatar_id,
		avatar_frame_id = arg_12_1.avatar_frame_id
	}

	xyd.setPlayerAvatar(var_12_2:getChildByName("avtar_container"), var_12_4)
	arg_12_0.socialSystem:setNameBg(var_12_3, arg_12_1)

	if arg_12_1.is_online == 0 then
		var_12_2:getChildByName("friend_state_txt"):setString(var_0_1:translation("FRIEND_OFFLINE_TEXT"))
		var_12_2:getChildByName("friend_state_txt"):setColor(cc.c3b(88, 69, 69))
	else
		var_12_2:getChildByName("friend_state_txt"):setString(var_0_1:translation("FRIEND_ONLINE_TEXT"))
		var_12_2:getChildByName("friend_state_txt"):setColor(cc.c3b(32, 193, 62))
	end

	if arg_12_0.selectList[arg_12_2] == 0 then
		var_12_2:getChildByName("select"):setOpacity(0)
	else
		var_12_2:getChildByName("select"):setOpacity(255)
	end

	var_12_2:getChildByName("select"):setTouchEnabled(true)
	var_12_2:getChildByName("select"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			return true
		elseif arg_13_0.name == "ended" then
			xyd.playButtonSound()

			if arg_12_0.selectList[arg_12_2] == 0 then
				var_12_2:getChildByName("select"):setOpacity(255)

				arg_12_0.selectList[arg_12_2] = 1
			else
				var_12_2:getChildByName("select"):setOpacity(0)

				arg_12_0.selectList[arg_12_2] = 0
			end
		end
	end)
	var_12_1:addTo(var_12_0)
	var_12_1:setAnchorPoint(cc.p(0, 0))
	var_12_0:setContentSize(var_12_2:getContentSize())
	var_12_1:setName("source")

	return var_12_0
end

function var_0_0.scrollListener(arg_14_0, arg_14_1)
	if arg_14_1.name == "began" then
		arg_14_0.scrollViewMoved_ = false
		arg_14_0.prevX_ = arg_14_1.x
	elseif arg_14_1.name == "moved" and 20 <= math.abs(arg_14_1.x - arg_14_0.prevX_) then
		arg_14_0.scrollViewMoved_ = true
	end
end

return var_0_0
