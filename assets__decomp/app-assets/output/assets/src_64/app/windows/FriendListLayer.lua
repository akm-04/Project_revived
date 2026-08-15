local var_0_0 = class("FriendListLayer", function()
	return display.newLayer()
end)
local var_0_1 = {}

var_0_1.NORMAL = 1
var_0_1.DELETE = 2

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0.size_ = arg_2_1.size
	arg_2_0.mode_ = var_0_1.NORMAL

	arg_2_0:initLayout()
	arg_2_0:refresh()

	local var_2_0 = xyd.EventDispatcher.get():addEventListener(xyd.event.FRIENDS_UPDATE, function(arg_3_0)
		arg_2_0:refresh()
	end)

	arg_2_0:addNodeEventListener(cc.NODE_EVENT, function(arg_4_0)
		if arg_4_0.name == "cleanup" then
			xyd.EventDispatcher.get():removeEventListener(var_2_0)
		end
	end)
end

function var_0_0.initLayout(arg_5_0)
	local var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/friend_list_layer.json")

	var_5_0:setPosition(cc.p(0, 0))
	arg_5_0:addChild(var_5_0)

	local var_5_1 = var_5_0:getChildByName("background")

	var_5_1:setContentSize(arg_5_0.size_)

	local var_5_2 = var_5_1:getChildByName("bottom_layer")

	arg_5_0.settingButton_ = ccui.Helper:seekWidgetByName(var_5_1, "Button_setting")

	arg_5_0.settingButton_:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_5_0.mode_ == var_0_1.NORMAL then
				arg_5_0.mode_ = var_0_1.DELETE

				arg_5_0:refreshPlayerList()
			else
				arg_5_0.mode_ = var_0_1.NORMAL

				arg_5_0:refreshPlayerList()
			end
		end
	end)
	arg_5_0.settingButton_:setTouchEnabled(false)

	local var_5_3 = ccui.Helper:seekWidgetByName(var_5_1, "bg_layer")
	local var_5_4 = 5
	local var_5_5 = var_5_2:getContentSize().width - arg_5_0.settingButton_:getContentSize().width + var_5_4
	local var_5_6 = var_5_3:getContentSize().height

	var_5_3:setContentSize(cc.size(var_5_5, var_5_6))

	local var_5_7 = xyd.AssetLoader.get():loadSprite("images/social_bottom_bg.png")

	var_5_7:setTextureRect(cc.rect(0, 0, var_5_5, var_5_6))
	var_5_7:setAnchorPoint(cc.p(0, 0))
	var_5_7:setPosition(cc.p(0, 0))
	var_5_3:addChild(var_5_7)

	arg_5_0.socialNumLabel_ = ccui.Helper:seekWidgetByName(var_5_1, "Label_social_num")
	arg_5_0.friendNumLabel_ = ccui.Helper:seekWidgetByName(var_5_1, "Label_friend_num")
	arg_5_0.playerListContainer_ = var_5_1:getChildByName("player_list_container")

	local var_5_8 = arg_5_0.playerListContainer_:getContentSize().width
	local var_5_9 = arg_5_0.playerListContainer_:getContentSize().height

	arg_5_0.listHeight_ = var_5_9
	arg_5_0.playerList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_8, var_5_9),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):onTouch(handler(arg_5_0, arg_5_0.touchListener)):addTo(arg_5_0.playerListContainer_)

	arg_5_0.playerList_:setDelegate(handler(arg_5_0, arg_5_0.sourceDelegate))
	arg_5_0:refreshPlayerList()
end

function var_0_0.initPlayerCell(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/friend_cell.json")

	var_7_0:setPosition(cc.p(0, 0))
	arg_7_1:addChild(var_7_0)

	local var_7_1 = var_7_0:getChildByName("background")

	var_7_1:setContentSize(cc.size(arg_7_0.playerListContainer_:getContentSize().width, var_7_1:getContentSize().height))

	local var_7_2 = var_7_1:getChildByName("normal_layer")
	local var_7_3 = var_7_1:getChildByName("delete_layer")
	local var_7_4

	if arg_7_0.mode_ == var_0_1.NORMAL then
		var_7_2:setVisible(true)
		var_7_3:setVisible(false)

		var_7_4 = var_7_2
	else
		var_7_2:setVisible(false)
		var_7_3:setVisible(true)

		var_7_4 = var_7_3
	end

	local var_7_5 = ccui.Helper:seekWidgetByName(var_7_4, "send_button_container")

	arg_7_1.sendButton_ = xyd.AssetLoader.get():loadButton("#social_button", cc.ui.UIPushButton, {
		scale9 = true,
		capInsets = cc.rect(27, 0, 1, 1),
		size = var_7_5:getContentSize()
	})

	arg_7_1.sendButton_:setAnchorPoint(cc.p(0, 0))
	arg_7_1.sendButton_:setPosition(cc.p(0, 0))
	var_7_5:addChild(arg_7_1.sendButton_)
	arg_7_1.sendButton_:setTouchSwallowEnabled(false)

	local var_7_6 = ccui.Helper:seekWidgetByName(var_7_4, "view_button_container")

	arg_7_1.viewButton_ = xyd.AssetLoader.get():loadButton("#social_button", cc.ui.UIPushButton, {
		scale9 = true,
		capInsets = cc.rect(27, 0, 1, 1),
		size = var_7_6:getContentSize()
	})

	arg_7_1.viewButton_:setAnchorPoint(cc.p(0, 0))
	arg_7_1.viewButton_:setPosition(cc.p(0, 0))
	var_7_6:addChild(arg_7_1.viewButton_)
	arg_7_1.viewButton_:setTouchSwallowEnabled(false)

	local var_7_7 = 5
	local var_7_8 = 150

	arg_7_1.infoLayer_ = ccui.Helper:seekWidgetByName(var_7_4, "info_layer")
	arg_7_1.playerBorder_ = ccui.Helper:seekWidgetByName(var_7_4, "player_border")

	local var_7_9 = ccui.Helper:seekWidgetByName(var_7_4, "name_bg")

	if arg_7_0.mode_ == var_0_1.NORMAL then
		local var_7_10 = var_7_4:getContentSize().width - var_7_7 - arg_7_1.playerBorder_:getContentSize().width - arg_7_1.sendButton_:getContentSize().width - arg_7_1.viewButton_:getContentSize().width

		arg_7_1.infoLayer_:setContentSize(cc.size(var_7_10, arg_7_1.infoLayer_:getContentSize().height))
		var_7_9:setContentSize(cc.size(var_7_10 - var_7_8, var_7_9:getContentSize().height))
	else
		local var_7_11 = ccui.Helper:seekWidgetByName(var_7_4, "delete_button_container")

		arg_7_1.deleteButton_ = xyd.AssetLoader.get():loadButton("#delete_button", cc.ui.UIPushButton, nil)

		arg_7_1.deleteButton_:setAnchorPoint(cc.p(0, 0))
		arg_7_1.deleteButton_:setPosition(cc.p(0, 0))
		var_7_11:addChild(arg_7_1.deleteButton_)
		arg_7_1.deleteButton_:setContentSize(arg_7_1.deleteButton_:getCascadeBoundingBox())
		arg_7_1.deleteButton_:setTouchSwallowEnabled(false)

		local var_7_12 = ccui.Helper:seekWidgetByName(var_7_4, "delete_bg")
		local var_7_13 = var_7_4:getContentSize().width - arg_7_1.deleteButton_:getContentSize().width

		var_7_12:setContentSize(cc.size(var_7_13, var_7_12:getContentSize().height))

		local var_7_14 = var_7_13 - var_7_7 - arg_7_1.playerBorder_:getContentSize().width - arg_7_1.sendButton_:getContentSize().width - arg_7_1.viewButton_:getContentSize().width

		arg_7_1.infoLayer_:setContentSize(cc.size(var_7_14, arg_7_1.infoLayer_:getContentSize().height))
		var_7_9:setContentSize(cc.size(var_7_14 - var_7_8, var_7_9:getContentSize().height))
	end

	arg_7_1.playerIconContainer_ = ccui.Helper:seekWidgetByName(var_7_4, "player_icon_container")
	arg_7_1.levelLabel_ = ccui.Helper:seekWidgetByName(var_7_4, "Label_lv")
	arg_7_1.nameLabel_ = ccui.Helper:seekWidgetByName(var_7_4, "Label_name")
	arg_7_1.lastTimeLabel_ = ccui.Helper:seekWidgetByName(var_7_4, "Label_last_time")
	arg_7_1.rankNameLabel_ = ccui.Helper:seekWidgetByName(var_7_4, "Label_rank_name")
	arg_7_1.pointNumLabel_ = ccui.Helper:seekWidgetByName(var_7_4, "Label_point_num")

	local var_7_15 = ccui.Helper:seekWidgetByName(var_7_4, "Label_point")
	local var_7_16 = ccui.Helper:seekWidgetByName(var_7_4, "Label_send")
	local var_7_17 = ccui.Helper:seekWidgetByName(var_7_4, "Label_view")
	local var_7_18 = xyd.tables.translation

	var_7_15:setString(var_7_18:translation("POINT"))
	var_7_16:setString(var_7_18:translation("SEND_SOCIAL"))
	var_7_17:setString(var_7_18:translation("VIEW"))

	local var_7_19 = xyd.ModelManager.get():loadModel(xyd.ModelType.FRIENDS)
	local var_7_20 = var_7_19.players_[arg_7_2]
	local var_7_21 = var_7_20.repHero_:getAvatar()
	local var_7_22

	if var_7_21 ~= "" then
		var_7_22 = xyd.AssetLoader.get():loadSprite(var_7_21)
	else
		var_7_22 = xyd.AssetLoader.get():loadSprite("images/anonymous.png")
	end

	xyd.displaySpriteOnContainer(var_7_22, arg_7_1.playerIconContainer_, true)
	arg_7_1.levelLabel_:setString(string.format("Lv.%d", var_7_20.lev))
	arg_7_1.nameLabel_:setString(var_7_20.playerName)
	arg_7_1.lastTimeLabel_:setString(string.format(var_7_18:translation("LAST_LOGIN_TIME_PROMPT"), xyd.lastLoginTimeString(var_7_20.lastTime_)))

	local var_7_23 = xyd.tables.arenaAward:rankName(xyd.tables.arenaAward:getID(var_7_20.point, var_7_20.rank))

	arg_7_1.rankNameLabel_:setString(var_7_23)
	arg_7_1.pointNumLabel_:setString(string.format("%d", var_7_20.point))

	local var_7_24 = var_7_20.socialTime_

	if var_7_24 == 0 then
		arg_7_1.sendButton_.fsm_:doEventForce("enable")
		arg_7_1.sendButton_:onButtonClicked(function(arg_8_0)
			if arg_7_0.listViewMoved_ then
				return
			end

			xyd.playButtonSound()

			local var_8_0 = {
				player_id = var_7_20.playerID
			}

			if xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).social < xyd.tables.misc.maxSocialPoint then
				var_7_19:sendSocial(var_8_0, function(arg_9_0)
					return
				end)
			else
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_7_18:translation("SOCIAL_POINTS_FULL_MESSAGE"))
			end
		end)
	else
		arg_7_1.sendButton_.fsm_:doEventForce("disable")
		arg_7_1.sendButton_:onButtonClicked(function(arg_10_0)
			if arg_7_0.listViewMoved_ then
				return
			end

			xyd.playButtonSound()

			local var_10_0 = xyd.ServerTime.get():getServerTime() - var_7_24
			local var_10_1 = 24 - math.floor(var_10_0 / 3600)
			local var_10_2 = var_7_18:translation("SEND_GIFT_AFTER_TIME_PROMPT")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_10_2)
		end)
	end

	arg_7_1.viewButton_:onButtonClicked(function(arg_11_0)
		if arg_7_0.listViewMoved_ then
			return
		end

		xyd.playButtonSound()
		cc.Director:getInstance():pushScene(xyd.HeroScene.new({
			player = var_7_20,
			viewConf = {
				modeSwitchEnabled = false,
				viewMode = xyd.HeroViewMode.SINGLE_VIEW
			}
		}))
	end)

	if arg_7_1.deleteButton_ then
		arg_7_1.deleteButton_:onButtonClicked(function(arg_12_0)
			if arg_7_0.listViewMoved_ then
				return
			end

			xyd.playButtonSound()

			local var_12_0 = {
				player_id = var_7_20.playerID
			}
			local var_12_1 = xyd.tables.translation:translation("DELETE_FRIEND")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_12_1, function()
				var_7_19:deleteFriend(var_12_0, function(arg_14_0)
					return
				end)
			end)
		end)
	end

	xyd.formatAllLabels(arg_7_1, function(arg_15_0)
		arg_15_0:enableShadow()
	end)

	local var_7_25 = var_7_1:getContentSize()

	var_7_0:setContentSize(var_7_25.width, var_7_25.height)
	arg_7_1:setContentSize(var_7_25.width, var_7_25.height)
end

function var_0_0.sourceDelegate(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	local var_16_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.FRIENDS)

	if cc.ui.UIListView.COUNT_TAG == arg_16_2 then
		return #var_16_0.players_
	elseif cc.ui.UIListView.CELL_TAG == arg_16_2 then
		local var_16_1
		local var_16_2
		local var_16_3 = arg_16_0.playerList_:dequeueItem()

		if not var_16_3 then
			var_16_3 = arg_16_0.playerList_:newItem()
		else
			var_16_3:removeAllChildren()
		end

		local var_16_4 = display.newNode()

		arg_16_0:initPlayerCell(var_16_4, arg_16_3)
		var_16_3:addContent(var_16_4)

		local var_16_5 = var_16_4:getContentSize()

		var_16_3:setItemSize(var_16_5.width, var_16_5.height)

		if not arg_16_0.CELL_HEIGHT or var_16_5.height > arg_16_0.CELL_HEIGHT then
			arg_16_0.CELL_HEIGHT = var_16_5.height
		end

		return var_16_3
	end
end

function var_0_0.touchListener(arg_17_0, arg_17_1)
	if arg_17_1.name == "began" then
		arg_17_0.listViewMoved_ = false
	elseif arg_17_1.name == "moved" then
		arg_17_0.listViewMoved_ = true
	elseif arg_17_1.name == "ended" then
		-- block empty
	end
end

function var_0_0.refresh(arg_18_0)
	arg_18_0:loadPlayer()
	arg_18_0:loadFriends()
end

function var_0_0.loadPlayer(arg_19_0)
	local var_19_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_19_0.socialNumLabel_:setString(string.format("%d", var_19_0.social))
end

function var_0_0.loadFriends(arg_20_0)
	local var_20_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.FRIENDS)
	local var_20_1 = arg_20_0

	var_20_0:load(function(arg_21_0, arg_21_1)
		if arg_21_0 == xyd.error.OK then
			var_20_1.friendNumLabel_:setString(string.format("%d/%d", #var_20_0.players_, var_20_0.maxFriendNumLimit_))

			if #var_20_0.players_ > 0 then
				var_20_1:sortPlayers()
				var_20_1:refreshPlayerList()
				var_20_1.settingButton_:setTouchEnabled(true)
			else
				var_20_1:refreshPlayerList()
				var_20_1.playerList_:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
				var_20_1.settingButton_:setTouchEnabled(false)
			end
		else
			xyd.errorAlert(arg_21_1)
		end
	end)
end

function var_0_0.sortPlayers(arg_22_0)
	local function var_22_0(arg_23_0, arg_23_1)
		if arg_23_0.point ~= arg_23_1.point then
			return arg_23_0.point > arg_23_1.point
		else
			return arg_23_0.playerID < arg_23_1.playerID
		end
	end

	local var_22_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.FRIENDS)

	table.sort(var_22_1.players_, var_22_0)
end

function var_0_0.refreshPlayerList(arg_24_0)
	xyd.refreshUIListView(arg_24_0.playerList_)

	local var_24_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.FRIENDS)

	if not arg_24_0.CELL_HEIGHT then
		return
	end

	if arg_24_0.CELL_HEIGHT * #var_24_0.players_ < arg_24_0.listHeight_ then
		xyd.elasticMoveUIScrollView(arg_24_0.playerList_, false)
	else
		xyd.elasticMoveUIScrollView(arg_24_0.playerList_, true)
	end
end

return var_0_0
