local var_0_0 = class("RagnarokInviteWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activities
local var_0_3 = 1203

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.ragnarok = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)
	arg_1_0.messageManager = xyd.ModelManager.get():loadModel(xyd.ModelType.MESSAGE_MANAGER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:setButtonClick()
	arg_4_0:initFriends()
	arg_4_0:initListview()
	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("RAGNAROK_BOSS_TEAM_19"))
	arg_4_0:nodeByName("region_txt"):setString(var_0_1:translation("RAGNAROK_BOSS_TEAM_20"))
	arg_4_0:nodeByName("guild_txt"):setString(var_0_1:translation("RAGNAROK_BOSS_TEAM_21"))
end

function var_0_0.initFriends(arg_5_0)
	local var_5_0 = arg_5_0.socialSystem.friendlist
	local var_5_1 = var_0_2:levelReq(var_0_3)
	local var_5_2 = {}

	for iter_5_0 = 1, #var_5_0 do
		if var_5_1 <= var_5_0[iter_5_0].lev then
			table.insert(var_5_2, var_5_0[iter_5_0])
		end
	end

	arg_5_0.friendList_ = var_5_2
end

function var_0_0.setButtonClick(arg_6_0)
	xyd.addTouchEvent(arg_6_0:nodeByName("btn_region"), function()
		if not arg_6_0.messageManager.chatLimit then
			arg_6_0.messageManager.chatLimit = {}
		end

		if arg_6_0.messageManager.chatLimit[5] and arg_6_0.messageManager.chatLimit[5] > 0 then
			xyd.WindowManager.get():openWindow("toast", {
				message = string.format(var_0_1:translation("TIME_TO_CHAT_ALERT"), arg_6_0.messageManager.chatLimit[5])
			})
		else
			local var_7_0 = arg_6_0.ragnarok:getPlayerInfo(1)
			local var_7_1 = {
				room_id = arg_6_0.ragnarok:getRoomID(),
				type = xyd.ChatTextType.RAGNAROK,
				boss_name = var_0_1:translation("RAGNAROK_BOSS_1"),
				room_lev = var_7_0.lev
			}
			local var_7_2 = {
				message = json.encode(var_7_1),
				channel = arg_6_0.messageManager.SERVICE_CHANNEL,
				type = xyd.ChatTextType.RAGNAROK
			}

			xyd.Backend.get():request(xyd.mid.SEND_CHAT_MESSAGE, var_7_2)
			arg_6_0.messageManager:setChatLimit(xyd.tables.misc.chatLimitTime, 5)
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("RAGNAROK_BOSS_TEAM_22")
			})
		end
	end)
	xyd.addTouchEvent(arg_6_0:nodeByName("btn_guild"), function()
		if arg_6_0.messageManager:hasLeague() == true then
			local var_8_0 = arg_6_0.ragnarok:getPlayerInfo(1)
			local var_8_1 = {
				room_id = arg_6_0.ragnarok:getRoomID(),
				type = xyd.ChatTextType.RAGNAROK,
				boss_name = var_0_1:translation("RAGNAROK_BOSS_1"),
				room_lev = var_8_0.lev
			}
			local var_8_2 = {
				message = json.encode(var_8_1),
				channel = arg_6_0.messageManager.GUILD_CHANNEL,
				type = xyd.ChatTextType.RAGNAROK
			}

			xyd.Backend.get():request(xyd.mid.SEND_CHAT_MESSAGE, var_8_2)
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("RAGNAROK_BOSS_TEAM_22")
			})
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("GUILD_CHAT_ALERT")
			})
		end
	end)
	xyd.nodeEventSample(arg_6_0:nodeByName("close_btn"), nil, function()
		xyd.WindowManager.get():closeWindow(arg_6_0.name)
	end)
end

function var_0_0.initListview(arg_10_0)
	local var_10_0 = arg_10_0:nodeByName("list")
	local var_10_1 = var_10_0:getContentSize().width
	local var_10_2 = var_10_0:getContentSize().height

	arg_10_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_10_1, var_10_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_10_0)

	arg_10_0.list:setDelegate(handler(arg_10_0, arg_10_0.delegate))
	arg_10_0.list:reload()
end

function var_0_0.delegate(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	local var_11_0 = #arg_11_0.friendList_

	if cc.ui.UIListView.COUNT_TAG == arg_11_2 then
		return var_11_0
	elseif cc.ui.UIListView.CELL_TAG == arg_11_2 then
		local var_11_1
		local var_11_2
		local var_11_3
		local var_11_4 = arg_11_0.list:dequeueItem()

		if not var_11_4 then
			var_11_4 = arg_11_0.list:newItem()
		else
			var_11_4:removeAllChildren()
		end

		local var_11_5 = display.newNode()

		var_11_5:setTouchSwallowEnabled(false)

		local var_11_6 = display.newNode()

		arg_11_0:initInviteItem(var_11_6, arg_11_3)

		local var_11_7 = var_11_6:getContentSize().width
		local var_11_8 = var_11_6:getContentSize().height

		var_11_5:addChild(var_11_6)
		var_11_5:setContentSize(cc.size(arg_11_0.list.viewRect_.width, var_11_6:getContentSize().height + 5))
		var_11_4:setItemSize(arg_11_0.list.viewRect_.width, var_11_6:getContentSize().height + 5)
		var_11_4:addContent(var_11_5)

		return var_11_4
	end
end

function var_0_0.initInviteItem(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_0.friendList_[arg_12_2]
	local var_12_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1203/ragnarok/invite_item.csb")

	var_12_1:addTo(arg_12_1)

	local var_12_2 = var_12_1:getChildByName("container")
	local var_12_3 = var_12_2:getContentSize()

	arg_12_1:setContentSize(var_12_3)

	var_12_0.playerInfo = var_12_0

	xyd.setPlayerAvatar(var_12_2:getChildByName("avatar"), var_12_0)

	if var_12_0.conquer_lev and var_12_0.conquer_lev > 0 then
		xyd.setConquerLev(var_12_0.conquer_lev, var_12_2:getChildByName("text_lev"), var_12_2:getChildByName("dengjiquan"), nil, false, 0.85, nil, var_12_0.conquer_loop_id)
	else
		var_12_2:getChildByName("text_lev"):setString(var_12_0.lev)
	end

	var_12_2:getChildByName("text_name"):setString(var_12_0.player_name)
	xyd.nodeEventSample(var_12_2:getChildByName("btn_invite"), nil, function()
		({}).player_id = var_12_0.player_id

		arg_12_0.ragnarok:inviteFriend(var_12_0.player_id, function(arg_14_0, arg_14_1)
			if arg_14_0 == xyd.error.OK then
				arg_12_0.ragnarok:addInvitedList(var_12_0.player_id)
				var_12_2:getChildByName("btn_invite"):setVisible(false)
				var_12_2:getChildByName("img_already_invite"):setVisible(true)
			end
		end)
	end)

	if arg_12_0.ragnarok:checkIsInvited(var_12_0.player_id) then
		var_12_2:getChildByName("img_already_invite"):setVisible(true)
		var_12_2:getChildByName("btn_invite"):setVisible(false)
	else
		var_12_2:getChildByName("img_already_invite"):setVisible(false)
		var_12_2:getChildByName("btn_invite"):setVisible(true)
	end

	var_12_2:getChildByName("btn_invite"):getChildByName("txt_invite"):setString(var_0_1:translation("RAGNAROK_BOSS_TEAM_23"))
end

return var_0_0
