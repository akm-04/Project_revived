local var_0_0 = class("PlayerCardLayer", function()
	return display.newLayer()
end)

var_0_0.WIDTH = 191
var_0_0.HEIGHT = 123
var_0_0.PLAYER_NAME_LIMIT = 6

local var_0_1 = {
	ADD = 0,
	DELETE = 1
}

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0.player_ = arg_2_1.player
	arg_2_0.opType_ = arg_2_1.op_type

	arg_2_0:initLayout()
	arg_2_0:refresh()
end

function var_0_0.initLayout(arg_3_0)
	arg_3_0:setTouchEnabled(false)

	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/player_card.json")

	var_3_0:setPosition(cc.p(0, 0))
	arg_3_0:addChild(var_3_0)

	local var_3_1 = var_3_0:getChildByName("background")

	arg_3_0.playerLvLabel_ = var_3_1:getChildByName("Label_player_level")
	arg_3_0.playerNameLabel_ = var_3_1:getChildByName("Label_player_name")
	arg_3_0.addMark_ = var_3_1:getChildByName("add_mark")

	arg_3_0.addMark_:setVisible(false)

	arg_3_0.deleteMark_ = var_3_1:getChildByName("delete_mark")

	arg_3_0.deleteMark_:setVisible(false)

	arg_3_0.playerIconContainer_ = var_3_1:getChildByName("player_icon_container")

	local var_3_2 = var_3_1:getChildByName("player_button_container")

	arg_3_0.playerCardButton_ = xyd.AssetLoader.get():loadButton("#player_button", cc.ui.UIPushButton, nil)

	arg_3_0.playerCardButton_:setAnchorPoint(cc.p(0, 0))
	xyd.displaySpriteOnContainer(arg_3_0.playerCardButton_, var_3_2, false, "left_bottom")
	arg_3_0.playerCardButton_:setTouchSwallowEnabled(false)

	local var_3_3 = ccui.Helper:seekWidgetByName(var_3_1, "op_button_container")

	arg_3_0.opButton_ = xyd.AssetLoader.get():loadButton("#social_op_button", cc.ui.UIPushButton, nil)

	arg_3_0.opButton_:setAnchorPoint(cc.p(0, 0))
	xyd.displaySpriteOnContainer(arg_3_0.opButton_, var_3_3, false, "left_bottom")
	arg_3_0.opButton_:setTouchSwallowEnabled(false)

	local var_3_4 = arg_3_0.opButton_:getParent():convertToWorldSpace(cc.p(arg_3_0.opButton_:getPositionX(), arg_3_0.opButton_:getPositionY()))
	local var_3_5 = arg_3_0:convertToNodeSpace(var_3_4)
	local var_3_6 = arg_3_0.opButton_:getCascadeBoundingBox()

	arg_3_0.opButtonRect_ = cc.rect(var_3_5.x, var_3_5.y, var_3_6.width, var_3_6.height)

	xyd.formatAllLabels(arg_3_0, function(arg_4_0)
		arg_4_0:enableShadow()
	end)

	local var_3_7 = var_3_1:getContentSize()

	arg_3_0:setContentSize(var_3_7.width, var_3_7.height)
end

function var_0_0.refresh(arg_5_0)
	arg_5_0.playerLvLabel_:setString(string.format("Lv.%d", arg_5_0.player_.lev))

	local var_5_0 = arg_5_0.player_.playerName

	if string.utf8len(var_5_0) > var_0_0.PLAYER_NAME_LIMIT then
		var_5_0 = xyd.utf8str(var_5_0, 1, var_0_0.PLAYER_NAME_LIMIT) .. ".."
	end

	arg_5_0.playerNameLabel_:setString(var_5_0)

	local var_5_1 = arg_5_0.player_.repHero_:getAvatar()
	local var_5_2

	if var_5_1 ~= "" then
		var_5_2 = xyd.AssetLoader.get():loadSprite(var_5_1)
	else
		var_5_2 = xyd.AssetLoader.get():loadSprite("images/anonymous.png")
	end

	xyd.displaySpriteOnContainer(var_5_2, arg_5_0.playerIconContainer_, true)
	arg_5_0.playerCardButton_:onButtonClicked(function(arg_6_0)
		local var_6_0 = arg_5_0:convertToNodeSpace(cc.p(arg_6_0.x, arg_6_0.y))

		if cc.rectContainsPoint(arg_5_0.opButtonRect_, var_6_0) then
			return
		end

		xyd.playButtonSound()
		xyd.WindowManager.get():openWindow("chat_user_info", {
			player = arg_5_0.player_
		})
	end)

	local var_5_3 = xyd.tables.translation

	local function var_5_4(arg_7_0)
		local var_7_0 = string.format(var_5_3:translation("SEND_FRIEND_REQUEST_PROMPT"), arg_7_0.playerName)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_7_0, function()
			xyd.requestFriend(arg_7_0.playerID)
		end)
	end

	local function var_5_5(arg_9_0)
		local var_9_0 = string.format(var_5_3:translation("CANCEL_FRIEND_REQUEST_PROMPT"), arg_9_0.playerName)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_0, function()
			local var_10_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SEND_REQUEST_PLAYERS)
			local var_10_1 = {
				player_id = arg_9_0.playerID
			}

			var_10_0:cancelFriendRequest(var_10_1, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					-- block empty
				else
					xyd.errorAlert(arg_11_1)
				end
			end)
		end)
	end

	if arg_5_0.opType_ == var_0_1.ADD then
		arg_5_0.addMark_:setVisible(true)
		arg_5_0.opButton_:onButtonClicked(function(arg_12_0)
			xyd.playButtonSound()
			var_5_4(arg_5_0.player_)
		end)
	elseif arg_5_0.opType_ == var_0_1.DELETE then
		arg_5_0.deleteMark_:setVisible(true)
		arg_5_0.opButton_:onButtonClicked(function(arg_13_0)
			xyd.playButtonSound()
			var_5_5(arg_5_0.player_)
		end)
	end
end

local var_0_2 = class("AddFriendLayer", function()
	return display.newLayer()
end)
local var_0_3 = 8

function var_0_2.ctor(arg_15_0, arg_15_1)
	arg_15_0.size_ = arg_15_1.size

	arg_15_0:initLayout()
	arg_15_0:refresh()

	local var_15_0 = xyd.EventDispatcher.get():addEventListener(xyd.event.SEND_REQUEST_PLAYERS_UPDATE, function(arg_16_0)
		arg_15_0:refresh()
	end)
	local var_15_1 = xyd.EventDispatcher.get():addEventListener(xyd.event.RECOMMEND_FRIENDS_UPDATE, function(arg_17_0)
		arg_15_0:refresh()
	end)

	arg_15_0:addNodeEventListener(cc.NODE_EVENT, function(arg_18_0)
		if arg_18_0.name == "cleanup" then
			xyd.EventDispatcher.get():removeEventListener(var_15_0)
			xyd.EventDispatcher.get():removeEventListener(var_15_1)
		end
	end)
end

function var_0_2.initLayout(arg_19_0)
	local var_19_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/add_friend_layer.json")

	var_19_0:setPosition(cc.p(0, 0))
	arg_19_0:addChild(var_19_0)

	local var_19_1 = var_19_0:getChildByName("background")

	var_19_1:setContentSize(arg_19_0.size_)

	local var_19_2 = var_19_1:getChildByName("Button_request")

	var_19_2:addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_19_0.searchEditBox_:touchDownAction(arg_19_0, ccui.TouchEventType.ended)
		end
	end)

	arg_19_0.editBoxContainer_ = var_19_1:getChildByName("edit_box_container")

	local var_19_3 = var_19_1:getChildByName("add_friend_bg"):getContentSize().width - var_0_3 * 3 - var_19_2:getContentSize().width
	local var_19_4 = arg_19_0.editBoxContainer_:getContentSize().height

	arg_19_0.editBoxContainer_:setContentSize(cc.size(var_19_3, var_19_4))

	arg_19_0.searchIcon_ = var_19_1:getChildByName("search_icon")

	arg_19_0:initEditBox()

	local var_19_5 = var_19_1:getChildByName("scrollview_container")
	local var_19_6 = var_19_5:getContentSize().width
	local var_19_7 = var_19_5:getContentSize().height

	arg_19_0.addFriendScrollView_ = cc.ui.UIScrollView.new({
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		viewRect = cc.rect(0, 0, var_19_6, var_19_7)
	}):onScroll(handler(arg_19_0, arg_19_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0):addTo(var_19_5)

	local var_19_8 = cc.Node:create()

	var_19_8:setAnchorPoint(cc.p(0, 0))
	var_19_8:setPosition(cc.p(0, 0))
	arg_19_0.addFriendScrollView_:addScrollNode(var_19_8)

	local var_19_9 = xyd.AssetLoader.get():loadNodeFromJson("windows/add_friend_scroll_layer.json")

	var_19_9:setPosition(cc.p(0, 0))
	var_19_8:addChild(var_19_9)

	arg_19_0.addFriendScrollLayer_ = var_19_9:getChildByName("add_friend_scroll_layer")

	arg_19_0.addFriendScrollLayer_:setContentSize(var_19_5:getContentSize())

	local var_19_10 = xyd.tables.translation

	var_19_1:getChildByName("Label_request"):setString(var_19_10:translation("INVITE"))
	arg_19_0.addFriendScrollLayer_:getChildByName("Label_request_friend"):setString(var_19_10:translation("REQUEST_FRIEND"))
	arg_19_0.addFriendScrollLayer_:getChildByName("Label_recommend_friend"):setString(var_19_10:translation("RECOMMEND_FRIEND"))

	local var_19_11 = arg_19_0.addFriendScrollLayer_:getContentSize().width * 0.96
	local var_19_12 = arg_19_0.addFriendScrollLayer_:getChildByName("request_friend_bg")

	var_19_12:setContentSize(cc.size(var_19_11, var_19_12:getContentSize().height))

	local var_19_13 = arg_19_0.addFriendScrollLayer_:getChildByName("recommend_friend_bg")

	var_19_13:setContentSize(cc.size(var_19_11, var_19_13:getContentSize().height))

	arg_19_0.requestFriendLayer_ = arg_19_0.addFriendScrollLayer_:getChildByName("request_friend_layer")

	arg_19_0.requestFriendLayer_:setContentSize(cc.size(var_19_11, arg_19_0.requestFriendLayer_:getContentSize().height))

	arg_19_0.recommendFriendLayer_ = arg_19_0.addFriendScrollLayer_:getChildByName("recommend_friend_layer")

	arg_19_0.recommendFriendLayer_:setContentSize(cc.size(var_19_11, arg_19_0.recommendFriendLayer_:getContentSize().height))

	local var_19_14 = xyd.AssetLoader.get():loadLabel({
		size = 24,
		text = var_19_10:translation("NO_REQUEST_FRIEND")
	})

	var_19_14:setAnchorPoint(cc.p(0.5, 0.5))
	var_19_14:setPosition(cc.p(arg_19_0.requestFriendLayer_:getContentSize().width * 0.5, arg_19_0.requestFriendLayer_:getContentSize().height * 0.5))
	arg_19_0.requestFriendLayer_:addChild(var_19_14)

	local var_19_15 = xyd.AssetLoader.get():loadLabel({
		size = 24,
		text = var_19_10:translation("NO_RECOMMEND_FRIEND")
	})

	var_19_15:setAnchorPoint(cc.p(0.5, 0.5))
	var_19_15:setPosition(cc.p(arg_19_0.recommendFriendLayer_:getContentSize().width * 0.5, arg_19_0.recommendFriendLayer_:getContentSize().height * 0.5))
	arg_19_0.recommendFriendLayer_:addChild(var_19_15)
	arg_19_0:updateScrollLayoutPos()
	xyd.formatAllLabels(arg_19_0, function(arg_21_0)
		arg_21_0:enableShadow()
	end)
end

function var_0_2.scrollListener(arg_22_0, arg_22_1)
	return
end

function var_0_2.active(arg_23_0)
	arg_23_0:initEditBox()
end

function var_0_2.inactive(arg_24_0)
	arg_24_0.editBoxContainer_:removeAllChildren()
end

function var_0_2.initEditBox(arg_25_0)
	arg_25_0.editBoxContainer_:removeAllChildren()

	local var_25_0 = xyd.AssetLoader.get():loadSprite("images/input_box.png", cc.rect(67, 24, 1, 1))

	arg_25_0.searchEditBox_ = ccui.EditBox:create(arg_25_0.editBoxContainer_:getContentSize(), var_25_0)

	arg_25_0.searchEditBox_:setAnchorPoint(cc.p(0, 0))

	local var_25_1 = 20

	arg_25_0.searchEditBox_:setFont(xyd.AssetLoader.get().FONT_NAME, var_25_1)
	arg_25_0.searchEditBox_:setPlaceholderFontColor(xyd.color.FONT_K)
	arg_25_0.searchEditBox_:setFontColor(cc.c3b(0, 0, 0))
	arg_25_0.searchEditBox_:setInputMode(cc.EDITBOX_INPUT_MODE_ANY)
	arg_25_0.searchEditBox_:registerScriptEditBoxHandler(handler(arg_25_0, arg_25_0.searchEditBoxHandler))
	arg_25_0.searchEditBox_:setInputFlag(3)

	local var_25_2 = " "
	local var_25_3 = xyd.AssetLoader.get():loadLabel({
		text = var_25_2,
		size = var_25_1
	})
	local var_25_4 = arg_25_0.searchIcon_:getPositionX()

	while var_25_4 > var_25_3:getContentSize().width do
		var_25_2 = var_25_2 .. " "

		var_25_3:setString(var_25_2)
	end

	local var_25_5 = xyd.tables.translation
	local var_25_6 = var_25_2 .. var_25_5:translation("ENTER_PLAYER_NAME")

	arg_25_0.searchEditBox_:setPlaceHolder(var_25_6)
	arg_25_0.searchEditBox_:pos(0, 0):addTo(arg_25_0.editBoxContainer_)
end

function var_0_2.searchEditBoxHandler(arg_26_0, arg_26_1)
	if arg_26_1 == "return" then
		if #arg_26_0.searchEditBox_:getText() == 0 then
			return
		else
			arg_26_0:prepareFriendRequest()
		end
	end
end

function var_0_2.prepareFriendRequest(arg_27_0)
	local var_27_0 = arg_27_0.searchEditBox_:getText()
	local var_27_1 = xyd.tables.translation
	local var_27_2 = string.format(var_27_1:translation("SEND_FRIEND_REQUEST_PROMPT"), var_27_0)

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_27_2, function()
		local var_28_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		if var_27_0 == var_28_0.playerName then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_27_1:translation("CANNOT_SEND_YOURSELF_FRIEND_REQUEST"))
		else
			xyd.Backend.get():request(xyd.mid.SEARCH_PLAYER, {
				player_name = var_27_0
			}, function(arg_29_0, arg_29_1)
				if arg_29_0 == xyd.error.OK then
					local var_29_0 = arg_29_1.player_id

					xyd.requestFriend(var_29_0)
				else
					xyd.errorAlert(arg_29_1, var_27_1:translation("CANNOT_FIND_FRIEND"))
				end
			end)
		end
	end, nil, 0)
end

function var_0_2.checkFriend(arg_30_0, arg_30_1)
	local var_30_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.FRIENDS)
	local var_30_1 = xyd.tables.translation

	var_30_0:load(function(arg_31_0, arg_31_1)
		if arg_31_0 == xyd.error.OK then
			if #var_30_0.players_ == var_30_0.maxFriendNumLimit_ then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_30_1:translation("SELF_FRIEND_FULL"))

				return
			elseif var_30_0:getPlayerByID(arg_30_1) then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_30_1:translation("ALREADY_BE_FRIEND"))

				return
			else
				arg_30_0:checkSendRequest(arg_30_1)
			end
		else
			xyd.errorAlert(arg_31_1)
		end
	end)
end

function var_0_2.checkSendRequest(arg_32_0, arg_32_1)
	local var_32_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SEND_REQUEST_PLAYERS)
	local var_32_1 = xyd.tables.translation

	var_32_0:load(function(arg_33_0, arg_33_1)
		if arg_33_0 == xyd.error.OK then
			if var_32_0:getPlayerByID(arg_32_1) then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_32_1:translation("ALREADY_SEND_FRIEND_REQUEST"))
			else
				arg_32_0:checkGetRequest(arg_32_1)
			end
		else
			xyd.errorAlert(arg_33_1)
		end
	end)
end

function var_0_2.checkGetRequest(arg_34_0, arg_34_1)
	local var_34_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.GET_REQUEST_PLAYERS)
	local var_34_1 = xyd.tables.translation

	var_34_0:load(function(arg_35_0, arg_35_1)
		if arg_35_0 == xyd.error.OK then
			if var_34_0:getPlayerByID(arg_34_1) then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_34_1:translation("ALREADY_GET_FRIEND_REQUEST"))
			else
				arg_34_0:sendFriendRequest(arg_34_1)
			end
		else
			xyd.errorAlert(arg_35_1)
		end
	end)
end

function var_0_2.sendFriendRequest(arg_36_0, arg_36_1)
	local var_36_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SEND_REQUEST_PLAYERS)
	local var_36_1 = {
		player_id = arg_36_1
	}
	local var_36_2 = xyd.tables.translation

	var_36_0:requestFriend(var_36_1, function(arg_37_0, arg_37_1)
		if arg_37_0 == xyd.error.OK then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_36_2:translation("REQUEST_FRIEND_COMPLETE"))
		else
			xyd.errorAlert(arg_37_1)
		end
	end)
end

function var_0_2.refresh(arg_38_0)
	arg_38_0:loadSendRequestPlayers()
	arg_38_0:loadRecommendFriends()
end

function var_0_2.loadSendRequestPlayers(arg_39_0)
	local var_39_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SEND_REQUEST_PLAYERS)
	local var_39_1 = arg_39_0

	var_39_0:load(function(arg_40_0, arg_40_1)
		if arg_40_0 == xyd.error.OK then
			var_39_1:showSendRequestPlayers()
		else
			xyd.errorAlert(arg_40_1)
		end
	end)
end

function var_0_2.loadRecommendFriends(arg_41_0)
	local var_41_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.RECOMMEND_FRIENDS)
	local var_41_1 = arg_41_0

	var_41_0:load(function(arg_42_0, arg_42_1)
		if arg_42_0 == xyd.error.OK then
			var_41_1:showRecommendFriends()
		else
			xyd.errorAlert(arg_42_1)
		end
	end)
end

function var_0_2.updateScrollLayoutPos(arg_43_0)
	arg_43_0.addFriendScrollLayer_:setAnchorPoint(cc.p(0, 0))

	local var_43_0 = arg_43_0.addFriendScrollLayer_:getContentSize().height
	local var_43_1 = arg_43_0.addFriendScrollView_:getViewRect().width
	local var_43_2 = arg_43_0.addFriendScrollView_:getViewRect().height

	if var_43_0 < var_43_2 then
		arg_43_0.addFriendScrollLayer_:setPosition(cc.p(0, 0))
	else
		arg_43_0.addFriendScrollLayer_:setPosition(cc.p(0, var_43_2 - var_43_0))
	end
end

function var_0_2.showPlayers(arg_44_0, arg_44_1, arg_44_2, arg_44_3, arg_44_4)
	arg_44_2:removeAllChildren()

	if #arg_44_1 == 0 then
		local var_44_0 = xyd.AssetLoader.get():loadLabel({
			size = 24,
			text = arg_44_3
		})

		var_44_0:enableShadow()
		var_44_0:setAnchorPoint(cc.p(0.5, 0.5))
		var_44_0:setPosition(cc.p(arg_44_2:getContentSize().width * 0.5, arg_44_2:getContentSize().height * 0.5))
		arg_44_2:addChild(var_44_0)

		return
	end

	local var_44_1 = arg_44_2:getContentSize().width
	local var_44_2 = math.floor(var_44_1 / var_0_0.WIDTH)
	local var_44_3 = (var_44_1 - var_0_0.WIDTH * var_44_2) / (var_44_2 - 1)
	local var_44_4 = var_0_0.HEIGHT * math.ceil(#arg_44_1 / var_44_2)

	for iter_44_0 = 1, #arg_44_1 do
		local var_44_5 = var_0_0.new({
			player = arg_44_1[iter_44_0],
			op_type = arg_44_4
		})
		local var_44_6 = (var_0_0.WIDTH + var_44_3) * math.mod(iter_44_0 - 1, var_44_2)
		local var_44_7 = var_44_4 - var_0_0.HEIGHT * (math.floor((iter_44_0 - 1) / var_44_2) + 1)

		var_44_5:setPosition(cc.p(var_44_6, var_44_7))
		arg_44_2:addChild(var_44_5)
	end

	local var_44_8 = arg_44_0.addFriendScrollLayer_:getContentSize().height - arg_44_2:getContentSize().height + var_44_4

	arg_44_2:setContentSize(cc.size(arg_44_2:getContentSize().width, var_44_4))
	arg_44_0.addFriendScrollLayer_:setContentSize(cc.size(arg_44_0.addFriendScrollLayer_:getContentSize().width, var_44_8))
	arg_44_0:updateScrollLayoutPos()
end

function var_0_2.showSendRequestPlayers(arg_45_0)
	local var_45_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SEND_REQUEST_PLAYERS)
	local var_45_1 = xyd.tables.translation

	arg_45_0:showPlayers(var_45_0.players_, arg_45_0.requestFriendLayer_, var_45_1:translation("NO_REQUEST_FRIEND"), var_0_1.DELETE)
end

function var_0_2.showRecommendFriends(arg_46_0)
	local var_46_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.RECOMMEND_FRIENDS)
	local var_46_1 = xyd.tables.translation

	arg_46_0:showPlayers(var_46_0.players_, arg_46_0.recommendFriendLayer_, var_46_1:translation("NO_RECOMMEND_FRIEND"), var_0_1.ADD)
end

return var_0_2
