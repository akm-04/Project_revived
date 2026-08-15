local var_0_0 = class("FriendRequestLayer", function()
	return display.newLayer()
end)

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0.size_ = arg_2_1.size

	arg_2_0:initLayout()
	arg_2_0:refresh()

	local var_2_0 = xyd.EventDispatcher.get():addEventListener(xyd.event.GET_REQUEST_PLAYERS_UPDATE, function(arg_3_0)
		arg_2_0:refresh()
	end)

	arg_2_0:addNodeEventListener(cc.NODE_EVENT, function(arg_4_0)
		if arg_4_0.name == "cleanup" then
			xyd.EventDispatcher.get():removeEventListener(var_2_0)
		end
	end)
end

function var_0_0.initLayout(arg_5_0)
	local var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/friend_request_layer.json")

	var_5_0:setPosition(cc.p(0, 0))
	arg_5_0:addChild(var_5_0)

	local var_5_1 = var_5_0:getChildByName("background")

	var_5_1:setContentSize(arg_5_0.size_)

	local var_5_2 = var_5_1:getChildByName("bottom_layer")

	arg_5_0.deleteAllButton_ = ccui.Helper:seekWidgetByName(var_5_1, "Button_delete_all")

	local var_5_3 = ccui.Helper:seekWidgetByName(var_5_1, "bg_layer")
	local var_5_4 = 5
	local var_5_5 = var_5_2:getContentSize().width - arg_5_0.deleteAllButton_:getContentSize().width + var_5_4
	local var_5_6 = var_5_3:getContentSize().height

	var_5_3:setContentSize(cc.size(var_5_5, var_5_6))

	local var_5_7 = xyd.AssetLoader.get():loadSprite("images/social_bottom_bg.png")

	var_5_7:setTextureRect(cc.rect(0, 0, var_5_5, var_5_6))
	var_5_7:setAnchorPoint(cc.p(0, 0))
	var_5_7:setPosition(cc.p(0, 0))
	var_5_3:addChild(var_5_7)

	local var_5_8 = ccui.Helper:seekWidgetByName(var_5_1, "Label_receive_request")
	local var_5_9 = xyd.tables.translation

	var_5_8:setString(var_5_9:translation("RECEIVE_REQUEST"))

	local var_5_10 = ccui.Helper:seekWidgetByName(var_5_1, "Label_delete_all")

	var_5_10:setString(var_5_9:translation("DELETE_ALL_REQUEST"))
	xyd.formatUIText(var_5_10, function(arg_6_0)
		arg_6_0:enableShadow()
	end)

	arg_5_0.requestNumLabel_ = ccui.Helper:seekWidgetByName(var_5_1, "Label_request_num")

	local var_5_11 = xyd.ModelManager.get():loadModel(xyd.ModelType.GET_REQUEST_PLAYERS)

	arg_5_0.deleteAllButton_:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_7_0 = {
				player_ids = {}
			}

			for iter_7_0, iter_7_1 in pairs(var_5_11.players_) do
				table.insert(var_7_0.player_ids, iter_7_1.playerID)
			end

			var_5_11:denyFriendRequest(var_7_0, function(arg_8_0)
				return
			end)
		end
	end)
	arg_5_0.deleteAllButton_:setTouchEnabled(false)

	arg_5_0.playerListContainer_ = var_5_1:getChildByName("player_list_container")

	local var_5_12 = arg_5_0.playerListContainer_:getContentSize().width
	local var_5_13 = arg_5_0.playerListContainer_:getContentSize().height

	arg_5_0.playerList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_12, var_5_13),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):onTouch(handler(arg_5_0, arg_5_0.touchListener)):addTo(arg_5_0.playerListContainer_)

	arg_5_0.playerList_:setDelegate(handler(arg_5_0, arg_5_0.sourceDelegate))
	arg_5_0:refreshPlayerList()
end

function var_0_0.initPlayerCell(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/send_request_player_cell.json")

	var_9_0:setPosition(cc.p(0, 0))
	arg_9_1:addChild(var_9_0)

	local var_9_1 = var_9_0:getChildByName("background")

	var_9_1:setContentSize(cc.size(arg_9_0.playerListContainer_:getContentSize().width, var_9_1:getContentSize().height))

	local var_9_2 = var_9_1:getChildByName("add_button_container")

	arg_9_1.addButton_ = xyd.AssetLoader.get():loadButton("#social_button", cc.ui.UIPushButton, {
		scale9 = true,
		capInsets = cc.rect(27, 0, 1, 1),
		size = var_9_2:getContentSize()
	})

	arg_9_1.addButton_:setAnchorPoint(cc.p(0, 0))
	arg_9_1.addButton_:setPosition(cc.p(0, 0))
	var_9_2:addChild(arg_9_1.addButton_)

	local var_9_3 = var_9_1:getChildByName("delete_button_container")

	arg_9_1.deleteButton_ = xyd.AssetLoader.get():loadButton("#social_button", cc.ui.UIPushButton, {
		scale9 = true,
		capInsets = cc.rect(27, 0, 1, 1),
		size = var_9_3:getContentSize()
	})

	arg_9_1.deleteButton_:setAnchorPoint(cc.p(0, 0))
	arg_9_1.deleteButton_:setPosition(cc.p(0, 0))
	var_9_3:addChild(arg_9_1.deleteButton_)

	arg_9_1.playerBorder_ = var_9_1:getChildByName("player_border")
	arg_9_1.infoLayer_ = var_9_1:getChildByName("info_layer")

	local var_9_4 = 5
	local var_9_5 = 150
	local var_9_6 = var_9_1:getContentSize().width - var_9_4 - arg_9_1.playerBorder_:getContentSize().width - arg_9_1.addButton_:getContentSize().width - arg_9_1.deleteButton_:getContentSize().width

	arg_9_1.infoLayer_:setContentSize(cc.size(var_9_6, arg_9_1.infoLayer_:getContentSize().height))

	local var_9_7 = ccui.Helper:seekWidgetByName(var_9_1, "name_bg")

	var_9_7:setContentSize(cc.size(var_9_6 - var_9_5, var_9_7:getContentSize().height))

	arg_9_1.playerIconContainer_ = ccui.Helper:seekWidgetByName(var_9_1, "player_icon_container")
	arg_9_1.levelLabel_ = ccui.Helper:seekWidgetByName(var_9_1, "Label_lv")
	arg_9_1.nameLabel_ = ccui.Helper:seekWidgetByName(var_9_1, "Label_name")
	arg_9_1.lastTimeLabel_ = ccui.Helper:seekWidgetByName(var_9_1, "Label_last_time")
	arg_9_1.rankNameLabel_ = ccui.Helper:seekWidgetByName(var_9_1, "Label_rank_name")
	arg_9_1.pointNumLabel_ = ccui.Helper:seekWidgetByName(var_9_1, "Label_point_num")

	local var_9_8 = ccui.Helper:seekWidgetByName(var_9_1, "Label_point")
	local var_9_9 = xyd.tables.translation

	var_9_8:setString(var_9_9:translation("POINT"))

	local var_9_10 = xyd.ModelManager.get():loadModel(xyd.ModelType.GET_REQUEST_PLAYERS)
	local var_9_11 = var_9_10.players_[arg_9_2]
	local var_9_12 = var_9_11.repHero_:getAvatar()
	local var_9_13

	if var_9_12 ~= "" then
		var_9_13 = xyd.AssetLoader.get():loadSprite(var_9_12)
	else
		var_9_13 = xyd.AssetLoader.get():loadSprite("images/anonymous.png")
	end

	xyd.displaySpriteOnContainer(var_9_13, arg_9_1.playerIconContainer_, true)
	arg_9_1.levelLabel_:setString(string.format("Lv.%d", var_9_11.lev))
	arg_9_1.nameLabel_:setString(var_9_11.playerName)
	arg_9_1.lastTimeLabel_:setString(string.format(var_9_9:translation("LAST_LOGIN_TIME_PROMPT"), xyd.lastLoginTimeString(var_9_11.lastTime_)))

	local var_9_14 = xyd.tables.arenaAward:rankName(xyd.tables.arenaAward:getID(var_9_11.point, var_9_11.rank))

	arg_9_1.rankNameLabel_:setString(var_9_14)
	arg_9_1.pointNumLabel_:setString(string.format("%d", var_9_11.point))
	arg_9_1.addButton_:onButtonClicked(function(arg_10_0)
		xyd.playButtonSound()

		local var_10_0 = {
			player_id = var_9_11.playerID
		}

		var_9_10:acceptFriendRequest(var_10_0, function(arg_11_0)
			return
		end)
	end)
	arg_9_1.deleteButton_:onButtonClicked(function(arg_12_0)
		xyd.playButtonSound()

		local var_12_0 = {
			player_ids = {}
		}

		table.insert(var_12_0.player_ids, var_9_11.playerID)
		var_9_10:denyFriendRequest(var_12_0, function(arg_13_0)
			return
		end)
	end)
	xyd.formatAllLabels(arg_9_1, function(arg_14_0)
		arg_14_0:enableShadow()
	end)

	local var_9_15 = var_9_1:getContentSize()

	var_9_0:setContentSize(var_9_15.width, var_9_15.height)
	arg_9_1:setContentSize(var_9_15.width, var_9_15.height)
end

function var_0_0.sourceDelegate(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	local var_15_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.GET_REQUEST_PLAYERS)

	if cc.ui.UIListView.COUNT_TAG == arg_15_2 then
		return #var_15_0.players_
	elseif cc.ui.UIListView.CELL_TAG == arg_15_2 then
		local var_15_1
		local var_15_2
		local var_15_3 = arg_15_0.playerList_:dequeueItem()

		if not var_15_3 then
			var_15_3 = arg_15_0.playerList_:newItem()
		else
			var_15_3:removeAllChildren()
		end

		local var_15_4 = display.newNode()

		arg_15_0:initPlayerCell(var_15_4, arg_15_3)
		var_15_3:addContent(var_15_4)

		local var_15_5 = var_15_4:getContentSize()

		var_15_3:setItemSize(var_15_5.width, var_15_5.height)

		return var_15_3
	end
end

function var_0_0.touchListener(arg_16_0, arg_16_1)
	return
end

function var_0_0.refresh(arg_17_0)
	arg_17_0:loadGetRequestPlayers()
end

function var_0_0.loadGetRequestPlayers(arg_18_0)
	local var_18_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.GET_REQUEST_PLAYERS)
	local var_18_1 = arg_18_0

	var_18_0:load(function(arg_19_0, arg_19_1)
		if arg_19_0 == xyd.error.OK then
			var_18_1.requestNumLabel_:setString(string.format("%d", #var_18_0.players_))

			if #var_18_0.players_ > 0 then
				var_18_1:sortPlayers()
				var_18_1:refreshPlayerList()
				var_18_1.deleteAllButton_:setTouchEnabled(true)
			else
				var_18_1:refreshPlayerList()
				var_18_1.playerList_:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
				var_18_1.deleteAllButton_:setTouchEnabled(false)
			end
		else
			xyd.errorAlert(arg_19_1)
		end
	end)
end

function var_0_0.sortPlayers(arg_20_0)
	local function var_20_0(arg_21_0, arg_21_1)
		if arg_21_0.requestTime_ ~= arg_21_1.requestTime_ then
			return arg_21_0.requestTime_ > arg_21_1.requestTime_
		else
			return arg_21_0.playerID < arg_21_1.playerID
		end
	end

	local var_20_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.GET_REQUEST_PLAYERS)

	table.sort(var_20_1.players_, var_20_0)
end

function var_0_0.refreshPlayerList(arg_22_0)
	xyd.refreshUIListView(arg_22_0.playerList_)
end

return var_0_0
