local var_0_0 = class("TwoYearsGiveAlertWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.twoYearsCampaign
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.AssetLoader.get()
local var_0_4 = 1
local var_0_5 = 2
local var_0_6 = 90
local var_0_7 = 20
local var_0_8 = 1117
local var_0_9 = xyd.tables.misc.twoYearsPresentLimitNum

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.twoYearsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.TWO_YEARS)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.itemPos = 0
	arg_1_0.itemToGive = 0
	arg_1_0.givePlayerID = 0
	arg_1_0.itemNum = 0
	arg_1_0.wordsToSay = var_0_2:translation("ANNI2_TIPS_TXT31")
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
	arg_4_0.activity = arg_4_0.activities:getActivityInfo(var_0_8)

	arg_4_0:nodeByName("friend_kuang"):setVisible(false)
	arg_4_0:nodeByName("item_num"):setString(arg_4_0.itemNum)
	arg_4_0:nodeByName("Text_2"):setString(var_0_2:translation("ANNI2_TIPS_TXT11"))
	arg_4_0:nodeByName("choose_txt"):setString(var_0_2:translation("ANNI2_TIPS_TXT36"))
	arg_4_0:nodeByName("item_label"):setString(var_0_2:translation("ANNI2_TIPS_TXT12"))
	arg_4_0:nodeByName("num_label"):setString(var_0_2:translation("ANNI2_TIPS_TXT13"))
	arg_4_0:nodeByName("sth_to_say_label"):setString(var_0_2:translation("ANNI2_TIPS_TXT14"))
	arg_4_0:nodeByName("sth_to_say"):setString(var_0_2:translation("ANNI2_TIPS_TXT31"))
	arg_4_0:nodeByName("self_limit"):setString(string.format(var_0_2:translation("ANNI2_TIPS_TXT15"), arg_4_0.activity.details.base_info.give_num or 0, xyd.tables.misc.twoYearsPresentLimitNum))
	arg_4_0:nodeByName("friend_limit"):setVisible(false)
	arg_4_0:initItems()
	arg_4_0:initInputBox(arg_4_0:nodeByName("spelling_bg"))
end

function var_0_0.registerEvents(arg_5_0)
	arg_5_0:nodeByName("di"):setTouchEnabled(true)
	arg_5_0:nodeByName("di"):setTouchSwallowEnabled(false)
	arg_5_0:nodeByName("di"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "ended" then
			xyd.WindowManager.get():openWindow("two_years_choose_friend")
		end

		return true
	end)
	arg_5_0:nodeByName("plus_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			arg_5_0.itemNum = arg_5_0.itemNum + 1

			if arg_5_0.itemNum + arg_5_0.activity.details.base_info.give_num > var_0_9 then
				local var_7_0 = var_0_2:translation("ANNI2_TIPS_TXT16")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_0
				})

				arg_5_0.itemNum = var_0_9 - arg_5_0.activity.details.base_info.give_num
			end

			if arg_5_0.friendLimit and arg_5_0.itemNum + arg_5_0.friendLimit > var_0_9 then
				local var_7_1 = var_0_2:translation("ANNI2_TIPS_TXT35")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_1
				})

				arg_5_0.itemNum = var_0_9 - arg_5_0.friendLimit
			end

			if arg_5_0.itemToGive ~= 0 and arg_5_0.givePlayerID ~= 0 then
				local var_7_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(arg_5_0.itemToGive)

				if var_7_2 < arg_5_0.itemNum then
					local var_7_3 = var_0_2:translation("ANNI2_TIPS_TXT21")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_7_3
					})

					arg_5_0.itemNum = var_7_2
				end
			elseif arg_5_0.givePlayerID == 0 then
				local var_7_4 = var_0_2:translation("ANNI2_TIPS_TXT37")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_4
				})

				arg_5_0.itemNum = 0
			else
				local var_7_5 = var_0_2:translation("ANNI2_TIPS_TXT22")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_5
				})

				arg_5_0.itemNum = 0
			end

			arg_5_0:nodeByName("item_num"):setString(tostring(arg_5_0.itemNum))
		end
	end)
	arg_5_0:nodeByName("minus_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			arg_5_0.itemNum = arg_5_0.itemNum - 1

			if arg_5_0.itemNum < 0 then
				arg_5_0.itemNum = 0
			end

			arg_5_0:nodeByName("item_num"):setString(tostring(arg_5_0.itemNum))
		end
	end)
	arg_5_0:nodeByName("confirm_button"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			local var_9_0 = {
				player_id = arg_5_0.givePlayerID,
				item_id = arg_5_0.itemToGive,
				item_num = arg_5_0.itemNum,
				msg = arg_5_0.wordsToSay
			}

			xyd.Backend.get():request(xyd.mid.ANNI_GIVE_GIFTS, var_9_0, function(arg_10_0, arg_10_1)
				if arg_10_0 == xyd.error.OK then
					local var_10_0 = {
						itemID = arg_5_0.itemToGive,
						itemNum = arg_5_0.itemNum
					}

					xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():removeItem(var_10_0)
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("ANNI2_TIPS_TXT32")
					})

					arg_5_0.activity.details.base_info.give_num = arg_5_0.activity.details.base_info.give_num + arg_5_0.itemNum

					xyd.WindowManager.get():closeWindow(arg_5_0)
				end
			end)
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_5_0):addEventListener(xyd.event.TWO_YEARS_CHOOSE_FRIEND, function(arg_11_0)
		if arg_5_0 and not tolua.isnull(arg_5_0) then
			arg_5_0:updateFriendContainer(arg_11_0.params.friend_info, arg_11_0.params.limit)

			arg_5_0.givePlayerID = arg_11_0.params.friend_info.player_id
		end
	end)
end

function var_0_0.updateFriendContainer(arg_12_0, arg_12_1, arg_12_2)
	arg_12_0.friendLimit = arg_12_2

	if arg_12_1 then
		arg_12_0:nodeByName("friend_kuang"):setVisible(true)
		arg_12_0:nodeByName("friend_kuang"):getChildByName("lev"):setString(arg_12_1.lev)

		if arg_12_1.conquer_lev and arg_12_1.conquer_lev > 0 then
			xyd.setConquerLev(arg_12_1.conquer_lev, arg_12_0:nodeByName("friend_kuang"):getChildByName("lev"), arg_12_0:nodeByName("friend_kuang"):getChildByName("level_bg"), {
				x = -2,
				y = 3
			})
		end

		arg_12_0:nodeByName("friend_kuang"):getChildByName("name"):setString(arg_12_1.player_name)
		arg_12_0.socialSystem:setOnlineState(arg_12_0:nodeByName("friend_kuang"):getChildByName("is_online"), arg_12_1)

		local var_12_0 = {
			avatar_id = arg_12_1.avatar_id,
			avatar_frame_id = arg_12_1.avatar_frame_id
		}

		arg_12_0:nodeByName("friend_kuang"):getChildByName("avatar"):setContentSize(80, 80)
		arg_12_0:nodeByName("friend_kuang"):getChildByName("avatar"):setAnchorPoint(0.5, 0.5)
		arg_12_0:nodeByName("friend_kuang"):getChildByName("region"):setString("S" .. arg_12_1.region)
		arg_12_0:nodeByName("friend_limit"):setVisible(true)
		arg_12_0:nodeByName("friend_limit"):setString(string.format(var_0_2:translation("ANNI2_TIPS_TXT34"), arg_12_2, xyd.tables.misc.twoYearsPresentLimitNum))
		xyd.setPlayerAvatar(arg_12_0:nodeByName("friend_kuang"):getChildByName("avatar"), var_12_0)
	end
end

function var_0_0.initItems(arg_13_0)
	local var_13_0 = xyd.tables.misc.twoYearspresentItem
	local var_13_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	for iter_13_0, iter_13_1 in pairs(var_13_0) do
		local var_13_2 = arg_13_0:nodeByName("item" .. iter_13_0)

		var_13_2:setContentSize(var_0_6, var_0_6)
		var_13_2:setAnchorPoint(0.5, 0.5)

		local var_13_3 = var_13_1:getBackpack():getItemNumByID(iter_13_1)

		xyd.setItemBorder(var_13_2, iter_13_1, nil, var_13_3 == 0, var_13_3)
		var_13_2:getChildByName("kuang"):setPosition(var_0_6 / 2, var_0_6 / 2)
		var_13_2:getChildByName("kuang"):setVisible(false)
		var_13_2:setTouchEnabled(true)
		var_13_2:setTouchSwallowEnabled(false)
		var_13_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
			if arg_14_0.name == "ended" then
				if var_13_1:getBackpack():getItemNumByID(iter_13_1) == 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("ANNI2_TIPS_TXT38")
					})

					return
				end

				if arg_13_0.itemPos ~= 0 then
					arg_13_0:nodeByName("item" .. arg_13_0.itemPos):getChildByName("kuang"):setVisible(false)
				end

				var_13_2:getChildByName("kuang"):setVisible(true)

				arg_13_0.itemPos = iter_13_0
				arg_13_0.itemToGive = iter_13_1
				arg_13_0.itemNum = 0

				arg_13_0:nodeByName("item_num"):setString(arg_13_0.itemNum)
			end

			return true
		end)
	end
end

function var_0_0.initInputBox(arg_15_0, arg_15_1)
	local var_15_0 = "windows/activities/1117/alert/spelling_bg.png"

	arg_15_0.spelling_box = ccui.EditBox:create(arg_15_1:getContentSize(), var_15_0)

	arg_15_0.spelling_box:setAnchorPoint(0, 0)
	arg_15_0.spelling_box:pos(0, 0)
	arg_15_1:addChild(arg_15_0.spelling_box, -100)
	arg_15_0.spelling_box:setFont(var_0_3.FONT_NAME, var_0_7)
	arg_15_0.spelling_box:setPlaceholderFont(var_0_3.FONT_NAME, var_0_7)
	arg_15_0.spelling_box:setPlaceHolder(var_0_2:translation("CHAT_INPUT_MESSAGE"))
	arg_15_0.spelling_box:setPlaceholderFontColor(xyd.color.FONT_K)
	arg_15_0.spelling_box:setFontColor(cc.c3b(0, 0, 0))
	arg_15_0.spelling_box:setMaxLength(50)
	arg_15_0.spelling_box:setInputMode(cc.EDITBOX_INPUT_MODE_ANY)
	arg_15_0.spelling_box:registerScriptEditBoxHandler(handler(arg_15_0, arg_15_0.channelboxEventHandler))
	arg_15_0.spelling_box:setInputFlag(3)

	arg_15_0.inputFlag = true
end

function var_0_0.channelboxEventHandler(arg_16_0, arg_16_1)
	print(arg_16_1)

	if arg_16_1 == "return" then
		print("channel return")

		arg_16_0.wordsToSay = arg_16_0.spelling_box:getText()

		if not arg_16_0.wordsToSay or arg_16_0.wordsToSay == "" then
			arg_16_0.wordsToSay = var_0_2:translation("ANNI2_TIPS_TXT31")
		end

		arg_16_0:nodeByName("sth_to_say"):setString(arg_16_0.wordsToSay)

		arg_16_0.inputFlag = false
	end
end

function var_0_0.willClose(arg_17_0)
	return
end

return var_0_0
