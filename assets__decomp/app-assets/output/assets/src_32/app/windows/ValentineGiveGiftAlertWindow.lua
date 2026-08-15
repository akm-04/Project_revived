local var_0_0 = class("ValentineGiveGiftAlertWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.AssetLoader.get()
local var_0_3 = 1
local var_0_4 = 2
local var_0_5 = 90
local var_0_6 = 20
local var_0_7 = 1142

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.itemPos = 0
	arg_1_0.itemToGive = 0
	arg_1_0.givePlayerID = 0
	arg_1_0.wordsToSay = var_0_1:translation("VALENTINE_TIPS_TXT6")
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:layout()
	arg_3_0:registerEvents()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.activity = arg_4_0.activities:getActivityInfo(var_0_7)

	arg_4_0:nodeByName("friend_kuang"):setVisible(false)
	arg_4_0:nodeByName("Text_2"):setString(var_0_1:translation("VALENTINE_TIPS_TXT1"))
	arg_4_0:nodeByName("choose_txt"):setString(var_0_1:translation("VALENTINE_TIPS_TXT8"))
	arg_4_0:nodeByName("item_label"):setString(var_0_1:translation("VALENTINE_TIPS_TXT2"))
	arg_4_0:nodeByName("sth_to_say_label"):setString(var_0_1:translation("VALENTINE_TIPS_TXT3"))
	arg_4_0:nodeByName("sth_to_say"):setString(var_0_1:translation("VALENTINE_TIPS_TXT6"))
	arg_4_0:initItems()
	arg_4_0:initInputBox(arg_4_0:nodeByName("spelling_bg"))
end

function var_0_0.registerEvents(arg_5_0)
	arg_5_0:nodeByName("di"):setTouchEnabled(true)
	arg_5_0:nodeByName("di"):setTouchSwallowEnabled(false)
	arg_5_0:nodeByName("di"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "ended" then
			xyd.WindowManager.get():openWindow("valentine_choose_friend")
		end

		return true
	end)
	arg_5_0:nodeByName("confirm_button"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			if not arg_5_0.givePlayerID or arg_5_0.givePlayerID == 0 then
				local var_7_0 = var_0_1:translation("VALENTINE_TIPS_TXT9")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_0
				})
			end

			if not arg_5_0.itemPos or arg_5_0.itemPos == 0 then
				local var_7_1 = var_0_1:translation("ACTIVITY_VALENTINE_NO_CHOSEN_ITEM")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_1
				})
			end

			local var_7_2 = {
				player_id = arg_5_0.givePlayerID,
				gift_index = arg_5_0.itemPos,
				msg = arg_5_0.wordsToSay
			}

			xyd.Backend.get():request(xyd.mid.VALENTINE_GIVE_GIFT, var_7_2, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					local var_8_0 = {
						itemNum = 1,
						itemID = arg_5_0.itemToGive
					}

					xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():removeItem(var_8_0)
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("VALENTINE_TIPS_TXT7")
					})
					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.VALENTINE_ACTIVITY_UPDATE
					})
					xyd.WindowManager.get():closeWindow(arg_5_0)
				end
			end)
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_5_0):addEventListener(xyd.event.VALENTINE_CHOOSE_FRIEND, function(arg_9_0)
		if arg_5_0 and not tolua.isnull(arg_5_0) then
			arg_5_0:updateFriendContainer(arg_9_0.params.friend_info, arg_9_0.params.limit)

			arg_5_0.givePlayerID = arg_9_0.params.friend_info.player_id
		end
	end)
end

function var_0_0.updateFriendContainer(arg_10_0, arg_10_1, arg_10_2)
	arg_10_0.friendLimit = arg_10_2

	if arg_10_1 then
		arg_10_0:nodeByName("friend_kuang"):setVisible(true)
		arg_10_0:nodeByName("friend_kuang"):getChildByName("lev"):setString(arg_10_1.lev)

		if arg_10_1.conquer_lev and arg_10_1.conquer_lev > 0 then
			xyd.setConquerLev(arg_10_1.conquer_lev, arg_10_0:nodeByName("friend_kuang"):getChildByName("lev"), arg_10_0:nodeByName("friend_kuang"):getChildByName("level_bg"), {
				x = -2,
				y = 3
			})
		end

		arg_10_0:nodeByName("friend_kuang"):getChildByName("name"):setString(arg_10_1.player_name)
		arg_10_0.socialSystem:setOnlineState(arg_10_0:nodeByName("friend_kuang"):getChildByName("is_online"), arg_10_1)

		local var_10_0 = {
			avatar_id = arg_10_1.avatar_id,
			avatar_frame_id = arg_10_1.avatar_frame_id
		}

		arg_10_0:nodeByName("friend_kuang"):getChildByName("avatar"):setContentSize(80, 80)
		arg_10_0:nodeByName("friend_kuang"):getChildByName("avatar"):setAnchorPoint(0.5, 0.5)
		arg_10_0:nodeByName("friend_kuang"):getChildByName("region"):setString("S" .. arg_10_1.region)
		xyd.setPlayerAvatar(arg_10_0:nodeByName("friend_kuang"):getChildByName("avatar"), var_10_0)
	end
end

function var_0_0.initItems(arg_11_0)
	local var_11_0 = xyd.tables.misc.valentinePresentItems
	local var_11_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	for iter_11_0, iter_11_1 in pairs(var_11_0) do
		local var_11_2 = arg_11_0:nodeByName("item" .. iter_11_0)

		var_11_2:setScale(1.3)
		var_11_2:setContentSize(var_0_5, var_0_5)
		var_11_2:setAnchorPoint(0.5, 0.5)

		local var_11_3 = var_11_1:getBackpack():getItemNumByID(iter_11_1)

		xyd.setItemBorder(var_11_2, iter_11_1, nil, var_11_3 == 0, var_11_3)
		var_11_2:getChildByName("kuang"):setPosition(var_0_5 / 2, var_0_5 / 2)
		var_11_2:getChildByName("kuang"):setVisible(false)
		var_11_2:setTouchEnabled(true)
		var_11_2:setTouchSwallowEnabled(false)
		var_11_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
			if arg_12_0.name == "ended" then
				if var_11_1:getBackpack():getItemNumByID(iter_11_1) == 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("VALENTINE_TIPS_TXT10")
					})

					return
				end

				if arg_11_0.itemPos ~= 0 then
					arg_11_0:nodeByName("item" .. arg_11_0.itemPos):getChildByName("kuang"):setVisible(false)
				end

				var_11_2:getChildByName("kuang"):setVisible(true)

				arg_11_0.itemPos = iter_11_0
				arg_11_0.itemToGive = iter_11_1
			end

			return true
		end)
	end
end

function var_0_0.initInputBox(arg_13_0, arg_13_1)
	local var_13_0 = "windows/activities/1117/alert/spelling_bg.png"

	arg_13_0.spelling_box = ccui.EditBox:create(arg_13_1:getContentSize(), var_13_0)

	arg_13_0.spelling_box:setAnchorPoint(0, 0)
	arg_13_0.spelling_box:pos(0, 0)
	arg_13_1:addChild(arg_13_0.spelling_box, -100)
	arg_13_0.spelling_box:setFont(var_0_2.FONT_NAME, var_0_6)
	arg_13_0.spelling_box:setPlaceholderFont(var_0_2.FONT_NAME, var_0_6)
	arg_13_0.spelling_box:setPlaceHolder(var_0_1:translation("CHAT_INPUT_MESSAGE"))
	arg_13_0.spelling_box:setPlaceholderFontColor(xyd.color.FONT_K)
	arg_13_0.spelling_box:setFontColor(cc.c3b(0, 0, 0))
	arg_13_0.spelling_box:setMaxLength(50)
	arg_13_0.spelling_box:setInputMode(cc.EDITBOX_INPUT_MODE_ANY)
	arg_13_0.spelling_box:registerScriptEditBoxHandler(handler(arg_13_0, arg_13_0.channelboxEventHandler))
	arg_13_0.spelling_box:setInputFlag(3)

	arg_13_0.inputFlag = true
end

function var_0_0.channelboxEventHandler(arg_14_0, arg_14_1)
	print(arg_14_1)

	if arg_14_1 == "return" then
		print("channel return")

		arg_14_0.wordsToSay = arg_14_0.spelling_box:getText()

		if not arg_14_0.wordsToSay or arg_14_0.wordsToSay == "" then
			arg_14_0.wordsToSay = var_0_1:translation("VALENTINE_TIPS_TXT6")
		end

		arg_14_0:nodeByName("sth_to_say"):setString(arg_14_0.wordsToSay)

		arg_14_0.inputFlag = false
	end
end

function var_0_0.willClose(arg_15_0)
	return
end

return var_0_0
