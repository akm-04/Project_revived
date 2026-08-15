local var_0_0 = class("AdventureDefenseInviteWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.adventureEvent = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
	arg_1_0.eventId = arg_1_2.table_id
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.messageManager = xyd.ModelManager.get():loadModel(xyd.ModelType.MESSAGE_MANAGER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setButtonClick()
	arg_3_0:initFriends()
	arg_3_0:initListview()
	arg_3_0:nodeByName("text_title"):setString(var_0_1:translation("ILLUSION_TEAM_TIPS_9"))
end

function var_0_0.initFriends(arg_4_0)
	local var_4_0 = arg_4_0.socialSystem.friendlist
	local var_4_1 = {}
	local var_4_2 = xyd.tables.functionOpen:level(xyd.FunctionID.ID_ILLUSION)
	local var_4_3 = xyd.tables.misc.paradiseTeamLimit
	local var_4_4 = 10 or math.max(var_4_2, masterInfo.lev - var_4_3)
	local var_4_5 = 100 or masterInfo.lev + var_4_3

	for iter_4_0 = 1, #var_4_0 do
		if var_4_4 <= var_4_0[iter_4_0].lev and var_4_5 >= var_4_0[iter_4_0].lev then
			table.insert(var_4_1, var_4_0[iter_4_0])
		end
	end

	table.sort(var_4_1, function(arg_5_0, arg_5_1)
		if arg_5_0.is_online == 1 and arg_5_1.is_online == 0 then
			return true
		end

		return false
	end)

	arg_4_0.friendList_ = var_4_1
end

function var_0_0.setButtonClick(arg_6_0)
	arg_6_0:nodeByName("btn_region"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if not arg_6_0.messageManager.chatLimit then
				arg_6_0.messageManager.chatLimit = {}
			end

			if arg_6_0.messageManager.chatLimit[5] and arg_6_0.messageManager.chatLimit[5] > 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_1:translation("TIME_TO_CHAT_ALERT"), arg_6_0.messageManager.chatLimit[5])
				})
			else
				local var_7_0 = arg_6_0.adventureEvent:getDefensePlayerInfoByID(arg_6_0.selfPlayer.playerID)
				local var_7_1 = {
					room_id = arg_6_0.adventureEvent.teamDefenseInfo.room_info.room_id,
					type = xyd.ChatTextType.ADVENTURE_DEFENSE,
					room_lev = var_7_0.lev
				}
				local var_7_2 = {
					message = json.encode(var_7_1),
					channel = arg_6_0.messageManager.SERVICE_CHANNEL,
					type = xyd.ChatTextType.ADVENTURE_DEFENSE
				}

				xyd.Backend.get():request(xyd.mid.SEND_CHAT_MESSAGE, var_7_2)
				arg_6_0.messageManager:setChatLimit(xyd.tables.misc.chatLimitTime, 5)
			end
		end
	end)
	arg_6_0:nodeByName("btn_guild"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_6_0.messageManager:hasLeague() == true then
				local var_8_0 = arg_6_0.adventureEvent:getDefensePlayerInfoByID(arg_6_0.selfPlayer.playerID)
				local var_8_1 = {
					room_id = arg_6_0.adventureEvent.teamDefenseInfo.room_info.room_id,
					type = xyd.ChatTextType.ADVENTURE_DEFENSE,
					room_lev = var_8_0.lev
				}
				local var_8_2 = {
					message = json.encode(var_8_1),
					channel = arg_6_0.messageManager.GUILD_CHANNEL,
					type = xyd.ChatTextType.ADVENTURE_DEFENSE
				}

				xyd.Backend.get():request(xyd.mid.SEND_CHAT_MESSAGE, var_8_2)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("GUILD_CHAT_ALERT")
				})
			end
		end
	end)
end

function var_0_0.initListview(arg_9_0)
	local var_9_0 = arg_9_0:nodeByName("list")
	local var_9_1 = var_9_0:getContentSize().width
	local var_9_2 = var_9_0:getContentSize().height

	arg_9_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_9_1, var_9_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_9_0)

	arg_9_0.list:setDelegate(handler(arg_9_0, arg_9_0.delegate))
	arg_9_0.list:reload()
end

function var_0_0.delegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = #arg_10_0.friendList_

	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return var_10_0
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_1
		local var_10_2
		local var_10_3
		local var_10_4 = arg_10_0.list:dequeueItem()

		if not var_10_4 then
			var_10_4 = arg_10_0.list:newItem()
		else
			var_10_4:removeAllChildren()
		end

		local var_10_5 = display.newNode()

		var_10_5:setTouchSwallowEnabled(false)

		local var_10_6 = display.newNode()

		arg_10_0:initInviteItem(var_10_6, arg_10_3)

		local var_10_7 = var_10_6:getContentSize().width
		local var_10_8 = var_10_6:getContentSize().height

		var_10_5:addChild(var_10_6)
		var_10_5:setContentSize(cc.size(arg_10_0.list.viewRect_.width, var_10_6:getContentSize().height + 5))
		var_10_4:setItemSize(arg_10_0.list.viewRect_.width, var_10_6:getContentSize().height + 5)
		var_10_4:addContent(var_10_5)

		return var_10_4
	end
end

function var_0_0.initInviteItem(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_0.friendList_[arg_11_2]
	local var_11_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/illusion/cooperation/invite_item.csb")

	var_11_1:addTo(arg_11_1)

	local var_11_2 = var_11_1:getChildByName("container")
	local var_11_3 = var_11_2:getContentSize()

	arg_11_1:setContentSize(var_11_3)

	var_11_0.playerInfo = var_11_0

	xyd.setPlayerAvatar(var_11_2:getChildByName("avatar"), var_11_0)

	if var_11_0.conquer_lev and var_11_0.conquer_lev > 0 then
		xyd.setConquerLev(var_11_0.conquer_lev, var_11_2:getChildByName("text_lev"), var_11_2:getChildByName("dengjiquan"), nil, false, 0.85, nil, var_11_0.conquer_loop_id)
	else
		var_11_2:getChildByName("text_lev"):setString(var_11_0.lev)
	end

	var_11_2:getChildByName("text_name"):setString(var_11_0.player_name)
	var_11_2:getChildByName("text_fight"):setString("")
	var_11_2:getChildByName("text_fight_num"):setString("")
	var_11_2:getChildByName("btn_invite"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			local var_12_0 = {
				player_id = var_11_0.player_id,
				table_id = xyd.AdventureEventType.DEFENSE
			}

			arg_11_0.adventureEvent:inviteFriend(var_12_0, function(arg_13_0, arg_13_1)
				if arg_13_0 == xyd.error.OK then
					arg_11_0.adventureEvent:addDefenseInvitedList(var_11_0.player_id)
					arg_12_0:setVisible(false)
					var_11_2:getChildByName("img_already_invite"):setVisible(true)
				end
			end)
		end
	end)

	if arg_11_0.adventureEvent:checkIsDefenseInvited(var_11_0.player_id) then
		var_11_2:getChildByName("img_already_invite"):setVisible(true)
		var_11_2:getChildByName("btn_invite"):setVisible(false)
	else
		var_11_2:getChildByName("img_already_invite"):setVisible(false)
		var_11_2:getChildByName("btn_invite"):setVisible(true)
	end
end

return var_0_0
