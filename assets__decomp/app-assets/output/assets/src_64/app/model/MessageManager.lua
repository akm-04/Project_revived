local var_0_0 = class("MessageManager", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.chatBubble
local var_0_3 = xyd.AssetLoader.get()
local var_0_4 = "[s&i?g&n]"
local var_0_5 = 60
local var_0_6 = 50
local var_0_7 = 24
local var_0_8 = 30
local var_0_9 = 600
local var_0_10 = 10
local var_0_11 = 670

var_0_0.WORLD_CHANNEL = 0
var_0_0.PERSONAL_CHANNEL = 1
var_0_0.GUILD_CHANNEL = 2
var_0_0.GM_CHANNEL = 3
var_0_0.SERVICE_CHANNEL = 4
var_0_0.TEAM_CHANNEL = 5

local var_0_12 = {
	var_0_0.WORLD_CHANNEL,
	var_0_0.PERSONAL_CHANNEL,
	var_0_0.GUILD_CHANNEL,
	var_0_0.GM_CHANNEL,
	var_0_0.SERVICE_CHANNEL,
	var_0_0.TEAM_CHANNEL
}

function var_0_0.ctor(arg_1_0)
	arg_1_0.messageList_ = {
		[arg_1_0.WORLD_CHANNEL] = {},
		[arg_1_0.PERSONAL_CHANNEL] = {},
		[arg_1_0.GUILD_CHANNEL] = {},
		[arg_1_0.GM_CHANNEL] = {},
		[arg_1_0.SERVICE_CHANNEL] = {},
		[arg_1_0.TEAM_CHANNEL] = {}
	}
	arg_1_0.blockList_ = {}
	arg_1_0.isNews = {
		[arg_1_0.WORLD_CHANNEL] = false,
		[arg_1_0.PERSONAL_CHANNEL] = false,
		[arg_1_0.GUILD_CHANNEL] = false,
		[arg_1_0.GM_CHANNEL] = false,
		[arg_1_0.SERVICE_CHANNEL] = false,
		[arg_1_0.TEAM_CHANNEL] = false
	}
	arg_1_0.currentChannel_ = var_0_0.SERVICE_CHANNEL

	local var_1_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_1_0.room_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).region
	arg_1_0.selfPlayerID_ = var_1_0.playerID
	arg_1_0.selfPlayerName_ = var_1_0.playerName
	arg_1_0.selfPlayerAvatar_ = var_1_0:getMyCurrentAvatarID()
	arg_1_0.selfPlayerFrame_ = var_1_0.avatarFrame
	arg_1_0.selfPlayerLev_ = var_1_0.lev
	arg_1_0.region_ = tonumber(var_1_0.region)
	arg_1_0.unreadNum = 0
	arg_1_0.playerType = var_1_0.playerType

	arg_1_0:enterChatRoom(arg_1_0.room_)
	arg_1_0:enterServiceChatRoom(99999)

	if var_1_0.guildID and var_1_0.guildID ~= 0 then
		arg_1_0.guildRoomId_ = var_1_0.guildID

		arg_1_0:enterLeagueChatRoom()
	end

	arg_1_0.dbMessageList_ = {
		[arg_1_0.WORLD_CHANNEL] = {},
		[arg_1_0.PERSONAL_CHANNEL] = {},
		[arg_1_0.GUILD_CHANNEL] = {},
		[arg_1_0.GM_CHANNEL] = {},
		[arg_1_0.SERVICE_CHANNEL] = {},
		[arg_1_0.TEAM_CHANNEL] = {}
	}
	arg_1_0.shareLastTime = {}

	arg_1_0:initChatMessageList()
	arg_1_0:initTeamList()
end

function var_0_0.initChatMessageList(arg_2_0)
	for iter_2_0, iter_2_1 in ipairs(var_0_12) do
		if xyd.tables.chatConfig:isRecordOpen(iter_2_1) == 1 then
			local var_2_0 = iter_2_1
			local var_2_1 = xyd.db.chatMessages:getChatMessages(arg_2_0.selfPlayerID_, arg_2_0.region_, var_2_0)

			arg_2_0:sortMessageByTime(var_2_1)

			arg_2_0.dbMessageList_[var_2_0] = var_2_1

			for iter_2_2, iter_2_3 in pairs(var_2_1) do
				local var_2_2 = arg_2_0:genChatMessage(iter_2_3.npInfo, iter_2_3.speakerID, iter_2_3.speakerName, iter_2_3.message, iter_2_3.isGM, iter_2_3.messageType, false, iter_2_3.time, nil, nil, nil, iter_2_3.speakerAvatar, iter_2_3.speakerFrame, iter_2_3.speakerLev, iter_2_0 - 1)

				table.insert(arg_2_0.messageList_[var_2_0], var_2_2)
				var_2_2:retain()
			end
		end
	end
end

function var_0_0.sortMessageByTime(arg_3_0, arg_3_1)
	table.sort(arg_3_1, function(arg_4_0, arg_4_1)
		if arg_4_0.time ~= arg_4_1.time then
			return arg_4_0.time < arg_4_1.time
		end
	end)
end

function var_0_0.appendMsg_(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = arg_5_0.messageList_[arg_5_1]
	local var_5_1 = false

	if #var_5_0 == var_0_6 and arg_5_1 ~= var_0_0.GM_CHANNEL then
		var_5_1 = true

		for iter_5_0 = 1, 10 do
			table.remove(var_5_0, 1):release()
		end
	end

	if var_5_1 then
		arg_5_0:updateTeamList()
	end

	if arg_5_1 == arg_5_0.currentChannel_ then
		arg_5_0.unreadNum = arg_5_0.unreadNum + 1
	end

	table.insert(var_5_0, arg_5_2)
	arg_5_2:retain()

	if arg_5_1 ~= arg_5_0.GM_CHANNEL then
		if arg_5_1 == arg_5_0.TEAM_CHANNEL then
			arg_5_0:insertTeamMessage(arg_5_2)
		end

		arg_5_0:updateLatestMessage(arg_5_2, arg_5_3, arg_5_1, var_5_1)
	end
end

function var_0_0.updateLatestMessage(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4)
	if arg_6_2 ~= nil and arg_6_0.selfPlayerID_ == arg_6_2 then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHAT_UPDATE,
			params = {
				needReload = arg_6_4
			}
		})
	elseif arg_6_3 and arg_6_3 == arg_6_0.currentChannel_ then
		arg_6_0.needCheckToEnd = true

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHAT_UPDATE,
			params = {
				needReload = arg_6_4
			}
		})
	end
end

function var_0_0.getTotalHeight(arg_7_0)
	local var_7_0 = 0
	local var_7_1 = arg_7_0.messageList_[arg_7_0.currentChannel_]

	if arg_7_0.currentChannel_ == arg_7_0.TEAM_CHANNEL then
		var_7_1 = arg_7_0.teamMessage
	end

	for iter_7_0, iter_7_1 in pairs(var_7_1) do
		if iter_7_1:getContentSize().height == 0 then
			if iter_7_1.itemHeight then
				var_7_0 = var_7_0 + iter_7_1.itemHeight
			end
		else
			var_7_0 = var_7_0 + iter_7_1:getContentSize().height
		end
	end

	return var_7_0
end

function var_0_0.initTeamList(arg_8_0)
	arg_8_0.teamTypeNum = 3
	arg_8_0.teamChoosen = {}

	for iter_8_0 = 1, arg_8_0.teamTypeNum do
		arg_8_0.teamChoosen[iter_8_0] = true
	end

	arg_8_0:updateTeamList()
end

function var_0_0.updateTeamList(arg_9_0)
	arg_9_0.teamMessage = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.messageList_[arg_9_0.TEAM_CHANNEL]) do
		arg_9_0:insertTeamMessage(iter_9_1)
	end
end

function var_0_0.insertTeamMessage(arg_10_0, arg_10_1)
	if arg_10_1.type == xyd.ChatTextType.ILLUSION and arg_10_0.teamChoosen[1] then
		table.insert(arg_10_0.teamMessage, arg_10_1)
	elseif arg_10_1.type == xyd.ChatTextType.OCCULT and arg_10_0.teamChoosen[2] then
		table.insert(arg_10_0.teamMessage, arg_10_1)
	elseif (arg_10_1.type == xyd.ChatTextType.ADVENTURE_ILLUSION or arg_10_1.type == xyd.ChatTextType.ADVENTURE_DEFENSE) and arg_10_0.teamChoosen[3] then
		table.insert(arg_10_0.teamMessage, arg_10_1)
	elseif arg_10_1.type == xyd.ChatTextType.RAGNAROK then
		table.insert(arg_10_0.teamMessage, arg_10_1)
	end
end

function var_0_0.checkShareTimes(arg_11_0, arg_11_1)
	local var_11_0 = arg_11_1.type
	local var_11_1 = arg_11_0.shareLastTime[var_11_0] or 0

	if arg_11_1.time - var_11_1 <= 180 then
		return false
	else
		return true
	end
end

function var_0_0.teamDelegate(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	if cc.ui.UIListView.COUNT_TAG == arg_12_2 then
		return #arg_12_0.teamMessage
	elseif cc.ui.UIListView.CELL_TAG == arg_12_2 then
		local var_12_0
		local var_12_1 = arg_12_1:dequeueItem()

		if not var_12_1 then
			var_12_1 = arg_12_1:newItem()
		else
			var_12_1:removeAllChildren(false)
		end

		local var_12_2 = arg_12_0.teamMessage[arg_12_3]

		var_12_2:removeFromParent()

		local var_12_3 = var_12_2:getContentSize().width
		local var_12_4 = var_12_2:getContentSize().height

		if var_12_4 == 0 then
			var_12_4 = var_12_2.itemHeight
		end

		local var_12_5 = display.newNode()

		var_12_5:addChild(var_12_2)
		var_12_2:setPositionY(-var_12_4 / 2)
		var_12_1:setItemSize(var_12_3, var_12_4)
		var_12_1:addContent(var_12_5)

		if var_12_2.reportParams then
			local var_12_6 = var_12_2.reportParams
			local var_12_7 = var_12_2:getChildByName("container"):getChildByName("chat_content")

			var_12_7:setTouchEnabled(true)
			var_12_7:setTouchSwallowEnabled(false)
			var_12_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
				if arg_13_0.name == "began" then
					arg_12_0.chatContentMoved_ = false
					arg_12_0.chatContentPreY_ = arg_13_0.y
				end

				if arg_13_0.name == "ended" and not arg_12_0.chatContentMoved_ then
					if var_12_6.type == xyd.ChatTextType.ILLUSION then
						local var_13_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).lev
						local var_13_1 = var_12_6.room_lev
						local var_13_2 = xyd.tables.misc.paradiseTeamLimit
						local var_13_3 = xyd.tables.functionOpen:level(xyd.FunctionID.ID_ILLUSION)
						local var_13_4 = math.max(var_13_3, var_13_1 - var_13_2)
						local var_13_5 = var_13_1 + var_13_2

						if var_13_0 < var_13_3 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ILLUSION_TEAM_TIPS_20")
							})
						elseif var_13_0 < var_13_4 or var_13_5 < var_13_0 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ILLUSION_TEAM_TIPS_21")
							})
						else
							local var_13_6 = xyd.ModelManager.get():loadModel(xyd.ModelType.ILLUSION)

							if var_13_6:checkCanJoinRoom(var_12_6.room_id) then
								var_13_6:enterRoom(var_12_6.room_id, function(arg_14_0, arg_14_1)
									if arg_14_0 == xyd.error.OK then
										xyd.WindowManager.get():openWindow("illusion_prepare")
										xyd.WindowManager.get():closeWindow("chat")
									else
										xyd.WindowManager.get():openWindow("toast", {
											message = var_0_1:translation("ILLUSION_TEAM_TIPS_10")
										})
									end
								end)
							else
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_1:translation("ILLUSION_TEAM_TIPS_22")
								})
							end
						end
					elseif var_12_6.type == xyd.ChatTextType.OCCULT then
						local var_13_7 = tonumber(var_12_6.room_id)
						local var_13_8 = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)

						if xyd.tables.functionOpen:is_open(xyd.FunctionID.ID_OCCULT, arg_12_0.selfPlayerLev_) then
							if var_13_8:checkCanJoinRoom(var_13_7) then
								local var_13_9 = {
									room_id = var_13_7
								}

								var_13_8:joinRoom(var_13_9, function(arg_15_0, arg_15_1)
									if arg_15_0 == xyd.error.OK then
										xyd.WindowManager.get():closeWindow("chat")
										xyd.WindowManager.get():openWindow("occult_prepare")
									end
								end)
							else
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_1:translation("ILLUSION_TEAM_TIPS_22")
								})
							end
						else
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("FUNCTION_OPEN_TIP_OTHER")
							})
						end
					elseif var_12_6.type == xyd.ChatTextType.ADVENTURE_ILLUSION then
						local var_13_10 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).lev
						local var_13_11 = var_12_6.room_lev
						local var_13_12 = xyd.tables.misc.paradiseTeamLimit
						local var_13_13 = xyd.tables.functionOpen:level(xyd.FunctionID.ID_ILLUSION)
						local var_13_14 = math.max(var_13_13, var_13_11 - var_13_12)
						local var_13_15 = var_13_11 + var_13_12

						if var_13_10 < var_13_13 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ILLUSION_TEAM_TIPS_20")
							})
						elseif var_13_10 < var_13_14 or var_13_15 < var_13_10 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ILLUSION_TEAM_TIPS_21")
							})
						else
							local var_13_16 = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)

							if var_13_16:checkCanJoinRoom(var_12_6.room_id) then
								var_13_16:joinRoom({
									room_id = var_12_6.room_id,
									table_id = xyd.AdventureEventType.ILLUSION
								}, function(arg_16_0, arg_16_1)
									if arg_16_0 == xyd.error.OK then
										xyd.WindowManager.get():openWindow("adventure_illusion_prepare", {
											table_id = xyd.AdventureEventType.ILLUSION
										})
										xyd.WindowManager.get():closeWindow("chat")
									elseif arg_16_1.error_code and arg_16_1.error_code == 35029 then
										local var_16_0 = xyd.tables.message:getContent(arg_16_1.error_code)

										if var_16_0 and var_16_0 ~= "" then
											xyd.WindowManager.get():openWindow("toast", {
												message = var_16_0
											})
										end
									else
										xyd.WindowManager.get():openWindow("toast", {
											message = var_0_1:translation("ILLUSION_TEAM_TIPS_10")
										})
									end
								end)
							else
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_1:translation("ILLUSION_TEAM_TIPS_22")
								})
							end
						end
					elseif var_12_6.type == xyd.ChatTextType.ADVENTURE_DEFENSE then
						local var_13_17 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).lev
						local var_13_18 = var_12_6.room_lev
						local var_13_19 = xyd.tables.misc.adventureDefenseLevelLimit
						local var_13_20 = 10
						local var_13_21 = math.max(var_13_20, var_13_18 - var_13_19)
						local var_13_22 = var_13_18 + var_13_19

						if var_13_17 < var_13_20 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ILLUSION_TEAM_TIPS_20")
							})
						elseif var_13_17 < var_13_21 or var_13_22 < var_13_17 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ILLUSION_TEAM_TIPS_21")
							})
						else
							local var_13_23 = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)

							if var_13_23:checkCanJoinDefenseRoom(var_12_6.room_id) then
								var_13_23:joinDefenseRoom({
									room_id = var_12_6.room_id,
									table_id = xyd.AdventureEventType.DEFENSE
								}, function(arg_17_0, arg_17_1)
									if arg_17_0 == xyd.error.OK then
										xyd.WindowManager.get():openWindow("adventure_defense")
										xyd.WindowManager.get():closeWindow("chat")
									end
								end)
							else
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_1:translation("ILLUSION_TEAM_TIPS_22")
								})
							end
						end
					elseif var_12_6.type == xyd.ChatTextType.RAGNAROK then
						if xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).lev < xyd.tables.activities:levelReq(1203) then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("RAGNAROK_BOSS_TEAM_25")
							})
						else
							local var_13_24 = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)

							var_13_24:getInfo(function()
								if var_13_24.isFuncOpen then
									if var_13_24:checkTicket() then
										if var_13_24:checkEnergy() then
											if var_13_24:checkCanJoinRoom(var_12_6.room_id) then
												var_13_24:enterRoom(var_12_6.room_id, 0, function(arg_19_0, arg_19_1)
													if arg_19_0 == xyd.error.OK then
														xyd.WindowManager.get():openWindow("ragnarok_prepare")
														xyd.WindowManager.get():closeWindow("chat")
													else
														xyd.WindowManager.get():openWindow("toast", {
															message = var_0_1:translation("RAGNAROK_BOSS_TEAM_27")
														})
													end
												end)
											else
												xyd.WindowManager.get():openWindow("toast", {
													message = var_0_1:translation("RAGNAROK_BOSS_TEAM_5")
												})
											end
										end
									else
										xyd.WindowManager.get():openWindow("toast", {
											message = var_0_1:translation("RAGNAROK_BOSS_TEAM_26")
										})
									end
								else
									xyd.WindowManager.get():openWindow("toast", {
										message = var_0_1:translation("RAGNAROK_BOSS_33")
									})
								end
							end)
						end
					end
				end

				if arg_13_0.name == "moved" and math.abs(arg_12_0.chatContentPreY_ - arg_13_0.y) > 20 then
					arg_12_0.chatContentMoved_ = true
				end

				return true
			end)

			if var_12_7._nextScriptEventHandleIndex_ > 3 then
				for iter_12_0 = var_12_7._nextScriptEventHandleIndex_ - 1, 2, -1 do
					var_12_7:removeNodeEventListener(iter_12_0)
				end
			end
		end

		if var_12_2:getChildByName("container") and var_12_2:getChildByName("container"):getChildByName("icon_container") then
			local var_12_8 = var_12_2:getChildByName("container"):getChildByName("icon_container")

			if var_12_8:getChildByName("avatar_click") then
				var_12_8:removeChildByName("avatar_click")
			end

			local var_12_9 = display.newNode()
			local var_12_10 = var_12_8:getContentSize()
			local var_12_11 = 0
			local var_12_12 = 0
			local var_12_13 = false

			var_12_9:setContentSize(var_12_10)
			var_12_9:setAnchorPoint(cc.p(0, 0))
			var_12_9:addTo(var_12_8)
			var_12_9:setName("avatar_click")
			var_12_9:setTouchEnabled(true)
			var_12_9:setTouchSwallowEnabled(false)
			var_12_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
				if arg_20_0.name == "began" then
					var_12_11 = arg_20_0.x
					var_12_12 = arg_20_0.y
					var_12_13 = false
				elseif arg_20_0.name == "moved" then
					if math.abs(arg_20_0.x - var_12_11) > 10 or math.abs(arg_20_0.y - var_12_12) > 10 then
						var_12_13 = true
					end
				elseif arg_20_0.name == "ended" and not var_12_13 then
					xyd.playerAvatarTouchEvent(var_12_2.playerInfo)
				end

				return true
			end)
		end

		return var_12_1
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_12_2 then
		arg_12_0.teamMessage[arg_12_3]:removeFromParent(false)
	end
end

function var_0_0.sourceDelegate(arg_21_0, arg_21_1, arg_21_2, arg_21_3)
	if arg_21_0.currentChannel_ == arg_21_0.TEAM_CHANNEL then
		return arg_21_0:teamDelegate(arg_21_1, arg_21_2, arg_21_3)
	end

	if cc.ui.UIListView.COUNT_TAG == arg_21_2 then
		return #arg_21_0.messageList_[arg_21_0.currentChannel_]
	elseif cc.ui.UIListView.CELL_TAG == arg_21_2 then
		local var_21_0
		local var_21_1 = arg_21_1:dequeueItem()

		if not var_21_1 then
			var_21_1 = arg_21_1:newItem()
		else
			var_21_1:removeAllChildren(false)
		end

		local var_21_2 = arg_21_0.messageList_[arg_21_0.currentChannel_][arg_21_3]

		var_21_2:removeFromParent()

		local var_21_3 = var_21_2:getContentSize().width
		local var_21_4 = var_21_2:getContentSize().height

		if var_21_4 == 0 then
			var_21_4 = var_21_2.itemHeight
		end

		local var_21_5 = display.newNode()

		var_21_5:addChild(var_21_2)
		var_21_2:setPositionY(-var_21_4 / 2)
		var_21_1:setItemSize(var_21_3, var_21_4)
		var_21_1:addContent(var_21_5)

		if var_21_2.reportParams then
			local var_21_6 = var_21_2.reportParams
			local var_21_7 = var_21_2:getChildByName("container"):getChildByName("chat_content")

			var_21_7:setTouchEnabled(true)
			var_21_7:setTouchSwallowEnabled(false)
			var_21_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
				if arg_22_0.name == "began" then
					arg_21_0.chatContentMoved_ = false
					arg_21_0.chatContentPreY_ = arg_22_0.y
				end

				if arg_22_0.name == "ended" and not arg_21_0.chatContentMoved_ then
					if var_21_6.share_gua then
						local var_22_0 = {
							rand_card_group = var_21_6.rand_card_group,
							scratch_status = var_21_6.scratch_status,
							card_group = var_21_6.card_group
						}

						xyd.WindowManager.get():openWindow("scratch_card_record", var_22_0)
					elseif var_21_6.record_id then
						local var_22_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA)

						var_22_1:getPeakRecordsDetail({
							player_id = var_21_6.player_id,
							record_id = var_21_6.record_id
						}, function(arg_23_0)
							if arg_23_0 == nil or arg_23_0 == {} then
								if xyd.WindowManager.get():getWindow("toast") ~= nil then
									xyd.WindowManager.get():closeWindow("toast")
								end

								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_1:translation("ARENA_RECORD_OUT_OF_DATE")
								})
							else
								local var_23_0 = var_21_6.player_id == var_21_6.attackInfo.player_id
								local var_23_1 = {
									reportKeys = arg_23_0.report_keys,
									wins = arg_23_0.wins,
									attackInfo = var_21_6.attackInfo,
									defendInfo = var_21_6.defendInfo,
									isWin = var_21_6.isWin,
									isAttack = var_21_6.isAttack or var_23_0,
									attackTeam = var_22_1:formatTeams(arg_23_0.attack_formations, var_21_6.attackInfo.conquer_lev),
									defendTeam = var_22_1:formatTeams(arg_23_0.defense_formations, var_21_6.defendInfo.conquer_lev)
								}

								xyd.WindowManager.get():openWindow("peak_arena_report", var_23_1)
							end
						end)
					elseif var_21_6.type == xyd.ChatTextType.ILLUSION then
						local var_22_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).lev
						local var_22_3 = var_21_6.room_lev
						local var_22_4 = xyd.tables.misc.paradiseTeamLimit
						local var_22_5 = xyd.tables.functionOpen:level(xyd.FunctionID.ID_ILLUSION)
						local var_22_6 = math.max(var_22_5, var_22_3 - var_22_4)
						local var_22_7 = var_22_3 + var_22_4

						if var_22_2 < var_22_5 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ILLUSION_TEAM_TIPS_20")
							})
						elseif var_22_2 < var_22_6 or var_22_7 < var_22_2 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ILLUSION_TEAM_TIPS_21")
							})
						else
							local var_22_8 = xyd.ModelManager.get():loadModel(xyd.ModelType.ILLUSION)

							if var_22_8:checkCanJoinRoom(var_21_6.room_id) then
								var_22_8:enterRoom(var_21_6.room_id, function(arg_24_0, arg_24_1)
									if arg_24_0 == xyd.error.OK then
										xyd.WindowManager.get():openWindow("illusion_prepare")
										xyd.WindowManager.get():closeWindow("chat")
									else
										xyd.WindowManager.get():openWindow("toast", {
											message = var_0_1:translation("ILLUSION_TEAM_TIPS_10")
										})
									end
								end)
							else
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_1:translation("ILLUSION_TEAM_TIPS_22")
								})
							end
						end
					elseif var_21_6.type == xyd.ChatTextType.OCCULT then
						local var_22_9 = tonumber(var_21_6.room_id)
						local var_22_10 = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)

						if var_22_10:checkCanJoinRoom(var_22_9) then
							local var_22_11 = {
								room_id = var_22_9
							}

							var_22_10:joinRoom(var_22_11, function(arg_25_0, arg_25_1)
								if arg_25_0 == xyd.error.OK then
									xyd.WindowManager.get():closeWindow("chat")
									xyd.WindowManager.get():openWindow("occult_prepare")
								end
							end)
						else
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ILLUSION_TEAM_TIPS_22")
							})
						end
					elseif var_21_6.type == xyd.ChatTextType.ADVENTURE_ILLUSION then
						local var_22_12 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).lev
						local var_22_13 = var_21_6.room_lev
						local var_22_14 = xyd.tables.misc.paradiseTeamLimit
						local var_22_15 = xyd.tables.functionOpen:level(xyd.FunctionID.ID_ILLUSION)
						local var_22_16 = math.max(var_22_15, var_22_13 - var_22_14)
						local var_22_17 = var_22_13 + var_22_14

						if var_22_12 < var_22_15 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ILLUSION_TEAM_TIPS_20")
							})
						elseif var_22_12 < var_22_16 or var_22_17 < var_22_12 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ILLUSION_TEAM_TIPS_21")
							})
						else
							local var_22_18 = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)

							if var_22_18:checkCanJoinRoom(var_21_6.room_id) then
								var_22_18:joinRoom({
									room_id = var_21_6.room_id,
									table_id = xyd.AdventureEventType.ILLUSION
								}, function(arg_26_0, arg_26_1)
									if arg_26_0 == xyd.error.OK then
										xyd.WindowManager.get():openWindow("adventure_illusion_prepare", {
											table_id = xyd.AdventureEventType.ILLUSION
										})
										xyd.WindowManager.get():closeWindow("chat")
									else
										xyd.WindowManager.get():openWindow("toast", {
											message = var_0_1:translation("ILLUSION_TEAM_TIPS_10")
										})
									end
								end)
							else
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_1:translation("ILLUSION_TEAM_TIPS_22")
								})
							end
						end
					elseif var_21_6.type == xyd.ChatTextType.ADVENTURE_DEFENSE then
						local var_22_19 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).lev
						local var_22_20 = var_21_6.room_lev
						local var_22_21 = xyd.tables.misc.adventureDefenseLevelLimit
						local var_22_22 = 10
						local var_22_23 = math.max(var_22_22, var_22_20 - var_22_21)
						local var_22_24 = var_22_20 + var_22_21

						if var_22_19 < var_22_22 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ILLUSION_TEAM_TIPS_20")
							})
						elseif var_22_19 < var_22_23 or var_22_24 < var_22_19 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ILLUSION_TEAM_TIPS_21")
							})
						else
							local var_22_25 = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)

							if var_22_25:checkCanJoinDefenseRoom(var_21_6.room_id) then
								var_22_25:joinDefenseRoom({
									room_id = var_21_6.room_id,
									table_id = xyd.AdventureEventType.DEFENSE
								}, function(arg_27_0, arg_27_1)
									if arg_27_0 == xyd.error.OK then
										xyd.WindowManager.get():openWindow("adventure_defense")
										xyd.WindowManager.get():closeWindow("chat")
									end
								end)
							else
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_1:translation("ILLUSION_TEAM_TIPS_22")
								})
							end
						end
					elseif var_21_6.type == xyd.ChatTextType.RAGNAROK then
						if xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).lev < xyd.tables.activities:levelReq(1203) then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("RAGNAROK_BOSS_TEAM_25")
							})
						else
							local var_22_26 = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)

							var_22_26:getInfo(function()
								if var_22_26.isFuncOpen then
									if var_22_26:checkTicket() then
										if var_22_26:checkEnergy() then
											if var_22_26:checkCanJoinRoom(var_21_6.room_id) then
												var_22_26:enterRoom(var_21_6.room_id, 0, function(arg_29_0, arg_29_1)
													if arg_29_0 == xyd.error.OK then
														xyd.WindowManager.get():openWindow("ragnarok_prepare")
														xyd.WindowManager.get():closeWindow("chat")
													else
														xyd.WindowManager.get():openWindow("toast", {
															message = var_0_1:translation("RAGNAROK_BOSS_TEAM_27")
														})
													end
												end)
											else
												xyd.WindowManager.get():openWindow("toast", {
													message = var_0_1:translation("RAGNAROK_BOSS_TEAM_5")
												})
											end
										end
									else
										xyd.WindowManager.get():openWindow("toast", {
											message = var_0_1:translation("RAGNAROK_BOSS_TEAM_26")
										})
									end
								else
									xyd.WindowManager.get():openWindow("toast", {
										message = var_0_1:translation("RAGNAROK_BOSS_33")
									})
								end
							end)
						end
					else
						local var_22_27 = {
							fighter_id = var_21_6.player_id,
							id = var_21_6.id
						}

						xyd.Backend.get():request(xyd.mid.LOAD_ARENA_FIGHT_RECORDS, var_22_27, function(arg_30_0, arg_30_1)
							if arg_30_0 == xyd.error.OK then
								local var_30_0 = arg_30_1.records

								if var_30_0.report and next(var_30_0.report) then
									local var_30_1 = {
										report = var_30_0.report,
										attackerName = var_30_0.attack_name,
										attackerLev = var_30_0.attack_lev,
										attackerAvatar = var_30_0.attack_avatar,
										attackerAvatarFrame = var_30_0.attack_avatar_frame,
										defenderName = var_30_0.defend_name,
										defenderLev = var_30_0.defend_lev,
										defenderAvatar = var_30_0.defend_avatar,
										defenderAvatarFrame = var_30_0.defend_avatar_frame,
										isAttack = var_30_0.is_attack,
										win = var_30_0.win
									}

									xyd.WindowManager.get():openWindow("arena_share", var_30_1)
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

				if arg_22_0.name == "moved" and math.abs(arg_21_0.chatContentPreY_ - arg_22_0.y) > 20 then
					arg_21_0.chatContentMoved_ = true
				end

				return true
			end)

			if var_21_7._nextScriptEventHandleIndex_ > 3 then
				for iter_21_0 = var_21_7._nextScriptEventHandleIndex_ - 1, 2, -1 do
					var_21_7:removeNodeEventListener(iter_21_0)
				end
			end
		end

		if var_21_2:getChildByName("container") and var_21_2:getChildByName("container"):getChildByName("icon_container") then
			local var_21_8 = var_21_2:getChildByName("container"):getChildByName("icon_container")

			if var_21_8:getChildByName("avatar_click") then
				var_21_8:removeChildByName("avatar_click")
			end

			local var_21_9 = display.newNode()
			local var_21_10 = var_21_8:getContentSize()
			local var_21_11 = 0
			local var_21_12 = 0
			local var_21_13 = false

			var_21_9:setContentSize(var_21_10)
			var_21_9:setAnchorPoint(cc.p(0, 0))
			var_21_9:addTo(var_21_8)
			var_21_9:setName("avatar_click")
			var_21_9:setTouchEnabled(true)
			var_21_9:setTouchSwallowEnabled(false)
			var_21_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_31_0)
				if arg_31_0.name == "began" then
					var_21_11 = arg_31_0.x
					var_21_12 = arg_31_0.y
					var_21_13 = false
				elseif arg_31_0.name == "moved" then
					if math.abs(arg_31_0.x - var_21_11) > 10 or math.abs(arg_31_0.y - var_21_12) > 10 then
						var_21_13 = true
					end
				elseif arg_31_0.name == "ended" and not var_21_13 then
					xyd.playerAvatarTouchEvent(var_21_2.playerInfo)
				end

				return true
			end)
		end

		return var_21_1
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_21_2 then
		arg_21_0.messageList_[arg_21_0.currentChannel_][arg_21_3]:removeFromParent(false)
	end
end

function var_0_0.notifyChatWindow(arg_32_0, arg_32_1, arg_32_2, arg_32_3)
	arg_32_0:notifyChat()

	local var_32_0 = xyd.WindowManager.get():getWindow("chat")

	if var_32_0 and arg_32_0:getChannel() ~= arg_32_1 then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHAT_WINDOW_NOTIFY,
			params = {
				channel = arg_32_1
			}
		})

		if arg_32_2 then
			var_32_0:updatePersonLabel(arg_32_3, true)

			var_32_0.toPlayerID = arg_32_2
		end
	elseif var_32_0 and arg_32_0:getChannel() == arg_32_1 then
		arg_32_0.isNews[arg_32_1] = false
	end
end

function var_0_0.notifyChat(arg_33_0)
	local var_33_0 = false

	for iter_33_0 = 0, 5 do
		if arg_33_0.isNews[iter_33_0] and (not xyd.WindowManager.get():getWindow("chat") or arg_33_0:getChannel() ~= iter_33_0) then
			var_33_0 = true

			break
		end
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_BOTTOM_NOTIFY,
		params = {
			index = 1,
			show = var_33_0
		}
	})
end

function var_0_0.getRoomID(arg_34_0)
	return arg_34_0.room_
end

function var_0_0.setRoomID(arg_35_0, arg_35_1)
	arg_35_0.room_ = arg_35_1
end

function var_0_0.enterChatRoom(arg_36_0, arg_36_1)
	xyd.Backend.get():enterChatRoom(arg_36_1)
end

function var_0_0.isLeagueSocketConnected(arg_37_0)
	return arg_37_0.leagueConnected
end

function var_0_0.hasLeague(arg_38_0)
	if arg_38_0.guildRoomId_ == nil then
		return false
	else
		return true
	end
end

function var_0_0.enterLeagueChatRoom(arg_39_0)
	if arg_39_0.guildRoomId_ ~= nil then
		xyd.Backend.get():enterLeagueRoom(arg_39_0.guildRoomId_)
	end
end

function var_0_0.enterServiceChatRoom(arg_40_0, arg_40_1)
	xyd.Backend.get():enterServiceChatRoom(arg_40_1)
end

function var_0_0.setLeagueSocketConnected(arg_41_0)
	arg_41_0.leagueConnected = true
end

function var_0_0.blockPlayer(arg_42_0, arg_42_1)
	arg_42_0.blockList_[arg_42_1] = true
end

function var_0_0.setChannel(arg_43_0, arg_43_1)
	arg_43_0.currentChannel_ = arg_43_1
end

function var_0_0.getChannel(arg_44_0)
	return arg_44_0.currentChannel_
end

function var_0_0.genLocalMessage(arg_45_0, arg_45_1, arg_45_2)
	local var_45_0 = display.newNode()
	local var_45_1 = xyd.color.CHAT_SYSTEM

	if arg_45_2 then
		var_45_1 = xyd.color.CHAT_SYSTEM
	end

	local var_45_2 = var_0_3:loadLabel({
		size = var_0_7,
		color = var_45_1
	})

	var_45_2:setString("[" .. var_0_1:translation("ANNOUNCEMENT") .. "]")
	var_45_2:setLineHeight(var_0_8)
	var_45_2:setAnchorPoint(0, 0)
	var_45_2:pos(-var_0_9 / 2 + 10, 0):addTo(var_45_0)

	local var_45_3 = var_0_3:loadLabel({
		size = var_0_7,
		color = var_45_1
	})

	var_45_3:setString(arg_45_1)
	var_45_3:setLineHeight(var_0_8)
	var_45_3:setAnchorPoint(0, 0)
	var_45_3:pos(var_45_2:getContentSize().width - var_0_9 / 2 + 10, 0):addTo(var_45_0)
	var_45_0:setContentSize(var_0_9, var_45_2:getContentSize().height)

	return var_45_0
end

function var_0_0.genUserName(arg_46_0, arg_46_1, arg_46_2, arg_46_3, arg_46_4, arg_46_5)
	local var_46_0 = display.newNode()
	local var_46_1 = var_0_3:loadLabel({
		size = var_0_7,
		color = arg_46_3
	})

	var_46_1:setString("[" .. arg_46_1 .. "]")
	var_46_1:setLineHeight(var_0_8)
	var_46_1:setAnchorPoint(0, 0)

	if arg_46_5 and arg_46_5 > 0 then
		var_46_1:enableOutline(arg_46_4, arg_46_5)
	end

	var_46_1:pos(0, 0):addTo(var_46_0)
	var_46_0:setContentSize(var_46_1:getContentSize())

	if arg_46_2 == arg_46_0.selfPlayerID_ or arg_46_2 == 0 or arg_46_2 == 10000 then
		return var_46_0
	end

	local var_46_2 = display.newDrawNode()
	local var_46_3 = cc.c4f(arg_46_3.r / 255, arg_46_3.g / 255, arg_46_3.b / 255, arg_46_3.a / 255)

	var_46_2:setAnchorPoint(0, 0)
	var_46_2:drawSegment(cc.p(0, 1), cc.p(var_46_0:getContentSize().width, 1), 1, var_46_3)
	var_46_2:pos(0, 2):addTo(var_46_0, 2)
	var_46_0:setTouchEnabled(true)
	var_46_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_47_0)
		if arg_47_0.name == "began" then
			return true
		elseif arg_47_0.name == "ended" then
			local var_47_0 = xyd.WindowManager.get():getWindow("chat")

			if var_47_0 then
				var_47_0:updatePersonLabel(arg_46_1)

				var_47_0.toPlayerID = arg_46_2
			end
		end
	end)
	var_46_0:setAnchorPoint(0, 0)
	var_46_0:pos(0, 0)

	return var_46_0
end

function var_0_0.genChatTime(arg_48_0, arg_48_1, arg_48_2)
	local var_48_0 = os.date("%x %X", arg_48_1)

	if arg_48_1 == 0 then
		var_48_0 = ""
	end

	return var_48_0
end

function var_0_0.genGmChatMessage(arg_49_0, arg_49_1)
	local var_49_0

	if arg_49_1.talker_id == 10000 then
		var_49_0 = arg_49_0:genChatMessage(nil, arg_49_1.talker_id, "GM", arg_49_1.msg, xyd.ChatPlayerType.GM, 0, false, arg_49_1.created_time, xyd.color.FONT_YELLOW, xyd.color.BROWN, true, 10001001, 0, 0)
	else
		local var_49_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
		local var_49_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.CHAT_BUBBLE)
		local var_49_3 = {
			title_info = tostring(var_49_1.titleInfo.title_id) .. "@" .. tostring(var_49_1.titleInfo.unique_id) .. "@" .. tostring(var_49_1.titleInfo.end_time),
			bubble_info = tostring(var_49_2:getBubbleID())
		}

		arg_49_1.np_info = json.encode(var_49_3)
		var_49_0 = arg_49_0:genChatMessage(arg_49_1.np_info, arg_49_1.player_id, arg_49_1.talker_name, arg_49_1.msg, arg_49_1.player_type, 0, false, arg_49_1.created_time, xyd.color.LIGHT_BLUE, nil, true, arg_49_0.selfPlayerAvatar_, arg_49_0.selfPlayerFrame_, arg_49_0.selfPlayerLev_)
	end

	return var_49_0
end

function var_0_0.genTitleInfo(arg_50_0, arg_50_1)
	local var_50_0 = xyd.splitToNumber(arg_50_1, "@")

	return {
		title_id = var_50_0[1],
		unique_id = var_50_0[2],
		end_time = var_50_0[3]
	}
end

function var_0_0.genChatMessage(arg_51_0, arg_51_1, arg_51_2, arg_51_3, arg_51_4, arg_51_5, arg_51_6, arg_51_7, arg_51_8, arg_51_9, arg_51_10, arg_51_11, arg_51_12, arg_51_13, arg_51_14, arg_51_15)
	local var_51_0 = display.newNode()
	local var_51_1 = {}
	local var_51_2
	local var_51_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/chat_window/chat_item.csb")
	local var_51_4 = var_51_3:getChildByName("container")
	local var_51_5 = json.decode(arg_51_1)
	local var_51_6 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_51_7 = arg_51_12
	local var_51_8 = arg_51_13
	local var_51_9 = arg_51_14 or ""
	local var_51_10 = arg_51_3
	local var_51_11 = 0
	local var_51_12
	local var_51_13
	local var_51_14

	if var_51_5 and var_51_5.bubble_info then
		var_51_14 = xyd.splitToNumber(var_51_5.bubble_info, "@")[1] or xyd.tables.misc:getValue("default_bubble")
	else
		var_51_14 = xyd.tables.misc:getValue("default_bubble")
	end

	if var_51_9 == 0 then
		var_51_9 = ""
	end

	if var_51_5 and var_51_5.conquer_lev then
		var_51_11 = tonumber(var_51_5.conquer_lev) or 0
		var_51_12 = tonumber(var_51_5.conquer_loop_id) or 1
	end

	if arg_51_2 == var_51_6.playerID then
		var_51_10 = var_51_6.playerName
		var_51_7 = var_51_6:getMyCurrentAvatarID()
		var_51_8 = var_51_6.avatarFrame
		var_51_9 = var_51_6.lev
		var_51_11 = var_51_6.conquerLev or 0
		var_51_12 = var_51_6.conquerLoopID or 1
		var_51_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/chat_window/chat_item_self.csb")
		var_51_4 = var_51_3:getChildByName("container")
		var_51_13 = true
	end

	local var_51_15 = xyd.getLoopBy(var_51_11, var_51_12)

	xyd.setPlayerAvatar(var_51_4:getChildByName("icon_container"), {
		showLevel = false,
		avatar_id = var_51_7,
		avatar_frame_id = var_51_8 or 0,
		isFlipX = var_51_13
	})

	var_51_3.playerInfo = {
		player_id = arg_51_2
	}

	if (tonumber(var_51_9) or 0) <= 100 and var_51_11 <= 0 then
		var_51_4:getChildByName("level_txt"):setString(var_51_9)
		var_51_4:getChildByName("level_bg"):setVisible(true)
		var_51_4:getChildByName("conquer_lev_bg"):setVisible(false)
	elseif (tonumber(var_51_9) or 0) == 100 and var_51_11 > 0 then
		var_51_4:getChildByName("level_txt"):setString(var_51_11)
		var_51_4:getChildByName("level_bg"):setVisible(false)
		var_51_4:getChildByName("conquer_lev_bg"):setVisible(true)

		if var_51_15 < 2 then
			var_51_15 = ""
		end

		var_51_4:getChildByName("conquer_lev_bg"):setTexture("images/conquer_lev" .. var_51_15 .. ".png")
	end

	local var_51_16

	var_51_16 = arg_51_6 == xyd.ChatTextType.REPORT

	local var_51_17 = xyd.color.CHAT_NORMAL

	if arg_51_5 == xyd.ChatPlayerType.FreshManGuide then
		var_51_17 = xyd.color.CHAT_HANGUP
	end

	local var_51_18 = 0
	local var_51_19 = var_0_7
	local var_51_20 = 0

	if arg_51_5 and arg_51_5 == xyd.ChatPlayerType.GM then
		local var_51_21 = var_0_3:loadSprite("images/chat_game_manager.png")

		var_51_21:setAnchorPoint(0, 1)

		if var_51_13 then
			var_51_21:pos(630, var_51_4:getChildByName("name_txt"):getPositionY())

			var_51_20 = var_51_21:getContentSize().width
		else
			var_51_21:pos(420, var_51_4:getChildByName("name_txt"):getPositionY())
		end

		var_51_21:addTo(var_51_4, -1)
	elseif arg_51_5 and arg_51_5 == xyd.ChatPlayerType.FreshManGuide then
		local var_51_22 = var_0_3:loadSprite("images/chat_fresh_guide.png")

		if var_51_13 then
			var_51_22:setAnchorPoint(1, 1)
			var_51_22:pos(914, var_51_4:getPositionY() + var_51_4:getContentSize().height)
		else
			var_51_22:setAnchorPoint(0, 1)
			var_51_22:pos(10, var_51_4:getPositionY() + var_51_4:getContentSize().height)
		end

		var_51_22:addTo(var_51_4, 100)
	end

	if var_51_5 and var_51_5.title_info and var_51_5.title_info ~= "@@@@" then
		local var_51_23 = arg_51_0:genTitleInfo(var_51_5.title_info)

		size = xyd.setPlayerTitle(var_51_4:getChildByName("title_container"), var_51_23, true)

		if size and size.width then
			var_51_20 = size.width
		end
	end

	local var_51_24 = var_51_4:getChildByName("title_container"):getContentSize().width - var_51_20

	if var_51_13 then
		var_51_4:getChildByName("name_bg"):setPositionX(var_51_4:getChildByName("name_bg"):getPositionX() + var_51_24)
		var_51_4:getChildByName("level_bg"):setPositionX(var_51_4:getChildByName("level_bg"):getPositionX() + var_51_24)
		var_51_4:getChildByName("conquer_lev_bg"):setPositionX(var_51_4:getChildByName("conquer_lev_bg"):getPositionX() + var_51_24)
		var_51_4:getChildByName("name_txt"):setPositionX(var_51_4:getChildByName("name_txt"):getPositionX() + var_51_24)
		var_51_4:getChildByName("level_txt"):setPositionX(var_51_4:getChildByName("level_txt"):getPositionX() + var_51_24)
		var_51_4:getChildByName("title_container"):setPositionX(var_51_4:getChildByName("title_container"):getPositionX() + var_51_24)
	end

	if arg_51_15 and arg_51_15 == arg_51_0.SERVICE_CHANNEL then
		local var_51_25 = math.floor(arg_51_2 / 100000)
		local var_51_26 = var_0_3:loadLabel({
			size = var_0_7,
			color = xyd.color.CHAT_REGION
		})

		var_51_26:setString(string.format(var_0_1:translation("SERVICE_CHAT_ID"), var_51_25))
		var_51_26:setLineHeight(var_0_8)
		var_51_26:setAnchorPoint(0, 1)
		var_51_26:pos(var_51_4:getChildByName("name_txt"):getPositionX() + 255, var_51_4:getChildByName("name_txt"):getPositionY())
		var_51_26:addTo(var_51_4)
	end

	local var_51_27 = xyd.color.CHAT_NAME
	local var_51_28 = arg_51_0:genUserName(var_51_10, arg_51_2, var_51_27)

	var_51_28:setAnchorPoint(0, 1)
	var_51_28:pos(var_51_4:getChildByName("name_txt"):getPosition())
	var_51_28:addTo(var_51_4)

	local var_51_29

	if arg_51_6 == xyd.ChatTextType.REPORT then
		var_51_17 = cc.c4b(54, 100, 71, 255)

		local var_51_30 = json.decode(arg_51_4)

		var_51_3.reportParams = var_51_30
		arg_51_4 = string.format("[%s VS %s]", var_51_30.player_name, var_51_30.enemy_name)
		var_51_19 = var_0_7
	elseif arg_51_6 == xyd.ChatTextType.LUCKY_COIN then
		var_51_17 = cc.c4b(54, 100, 71, 255)

		local var_51_31 = json.decode(arg_51_4)

		var_51_3.reportParams = var_51_31
		arg_51_4 = string.format(var_0_1:translation("LUCKY_COIN_SHARED"), var_51_31.player_name)
		var_51_19 = var_0_7
	elseif arg_51_6 == xyd.ChatTextType.ILLUSION then
		var_51_17 = cc.c4b(54, 100, 71, 255)

		local var_51_32 = json.decode(arg_51_4)

		var_51_3.reportParams = var_51_32
		var_51_3.type = xyd.ChatTextType.ILLUSION

		local var_51_33 = var_51_32.boss_name or ""
		local var_51_34 = var_51_32.room_lev or 0

		arg_51_4 = string.format(var_0_1:translation("ILLUSION_TEAM_TIPS_11"), var_51_33, var_51_34)
		var_51_19 = var_0_7
	elseif arg_51_6 == xyd.ChatTextType.OCCULT then
		var_51_17 = cc.c4b(54, 100, 71, 255)

		local var_51_35 = json.decode(arg_51_4)

		var_51_3.reportParams = var_51_35
		var_51_3.type = xyd.ChatTextType.OCCULT

		local var_51_36 = var_51_35.chapter_id or 1
		local var_51_37 = xyd.tables.creatsChapterSelect:chapterName(tonumber(var_51_36))
		local var_51_38 = var_51_35.force or 0

		arg_51_4 = string.format(var_0_1:translation("CREATS_TIPS_13"), var_51_37, var_51_38)
		var_51_19 = var_0_7
	elseif arg_51_6 == xyd.ChatTextType.ADVENTURE_ILLUSION then
		var_51_17 = cc.c4b(54, 100, 71, 255)

		local var_51_39 = json.decode(arg_51_4)

		var_51_3.reportParams = var_51_39
		var_51_3.type = xyd.ChatTextType.ADVENTURE_ILLUSION

		local var_51_40 = var_51_39.boss_name or ""
		local var_51_41 = var_51_39.room_lev or 0

		arg_51_4 = string.format(var_0_1:translation("ADVENTURE_PARADISE_TEAM_TIP"), var_51_40, var_51_41)
		var_51_19 = var_0_7
	elseif arg_51_6 == xyd.ChatTextType.ADVENTURE_DEFENSE then
		var_51_17 = cc.c4b(54, 100, 71, 255)

		local var_51_42 = json.decode(arg_51_4)

		var_51_3.reportParams = var_51_42
		var_51_3.type = xyd.ChatTextType.ADVENTURE_DEFENSE

		local var_51_43 = var_51_42.room_lev or 0

		arg_51_4 = string.format(var_0_1:translation("ADVENTURE_MONSTER_TEAM_TIP"), var_51_43)
		var_51_19 = var_0_7
	elseif arg_51_6 == xyd.ChatTextType.RAGNAROK then
		var_51_17 = cc.c4b(54, 100, 71, 255)

		local var_51_44 = json.decode(arg_51_4)

		var_51_3.reportParams = var_51_44
		var_51_3.type = xyd.ChatTextType.RAGNAROK

		local var_51_45 = var_51_44.boss_name or ""
		local var_51_46 = var_51_44.room_lev or 0

		arg_51_4 = string.format(var_0_1:translation("RAGNAROK_BOSS_TEAM_24"), var_51_45, var_51_46)
		var_51_19 = var_0_7
	end

	local var_51_47

	if arg_51_8 and arg_51_8 ~= 0 then
		var_51_47 = arg_51_0:genChatTime(arg_51_8, xyd.color.LIGHT_BROWN)
	else
		var_51_47 = arg_51_0:genChatTime(xyd.ServerTime.get():getServerTime() or 0, xyd.color.LIGHT_BROWN)
	end

	var_51_4:getChildByName("time_txt"):setString(var_51_47)

	if arg_51_10 then
		var_51_17 = arg_51_10
	end

	local var_51_48 = var_0_9 - var_51_18
	local var_51_49 = var_0_3:loadLabel({
		size = var_51_19,
		color = var_51_17
	})

	var_51_49:setName("chat_content")
	var_51_49:setContentSize(var_0_11, var_51_49:getContentSize().height)

	local var_51_50 = var_51_49:getContentSize().width

	var_51_49:setLineHeight(var_0_8)
	var_51_49:setLineBreakWithoutSpace(true)
	var_51_49:setMaxLineWidth(var_51_48)
	var_51_49:setAnchorPoint(0.5, 0.5)
	var_51_49:pos(var_51_18, 0)

	var_51_3.itemHeight = var_51_49:getContentSize().height + 98

	local var_51_51 = 0
	local var_51_52 = xyd.split(arg_51_4, "|")

	if var_51_52 and var_51_52[1] and var_51_52[2] and var_51_52[2] == var_0_4 then
		local var_51_53 = tonumber(var_51_52[1])

		if var_51_53 then
			var_51_4:getChildByName("message_bg"):setVisible(false)

			local var_51_54 = display.newNode()
			local var_51_55 = xyd.tables.emoticon:isDynamic(var_51_53)
			local var_51_56 = xyd.tables.emoticon:image(var_51_53)
			local var_51_57 = xyd.tables.emoticon:path(var_51_53)
			local var_51_58

			if var_51_55 == 1 then
				var_51_58 = xyd.createEffect(var_51_57, 0.7)

				var_51_58:play(nil, true, nil, "halloween")

				local var_51_59 = cc.ClippingNode:create()
				local var_51_60 = xyd.AssetLoader:get():loadSprite("windows/chat_window/clip.png")

				var_51_59:setStencil(var_51_60)
				var_51_59:setInverted(true)
				var_51_59:setAlphaThreshold(0)
				var_51_59:setAnchorPoint(0, 1)
				var_51_59:setPosition(73.5, -48)
				var_51_59:addTo(var_51_54)
				var_51_58:setPosition(0, -52)
				var_51_58:addTo(var_51_59)
			else
				var_51_58 = xyd.AssetLoader.get():loadSprite(var_51_56)

				var_51_58:setAnchorPoint(cc.p(0, 1))
				var_51_58:addTo(var_51_54)
			end

			var_51_54:setContentSize(var_51_58:getContentSize())
			var_51_54:setPosition(var_51_4:getChildByName("message_txt"):getX(), var_51_49:getPositionY() + 51)
			var_51_54:addTo(var_51_4)

			if var_51_13 then
				var_51_54:setPositionX(var_51_54:getPositionX() - 147)
			end

			var_51_49:setString("")

			var_51_3.itemHeight = var_51_3.itemHeight + var_0_5
			var_51_51 = var_0_5
		else
			var_51_49:setString(arg_51_4)
		end
	else
		var_51_49:setString(arg_51_4)
	end

	local var_51_61 = var_51_49:getContentSize()
	local var_51_62 = cc.size(math.max(var_51_61.width + 26, var_0_2:minLength(var_51_14)), var_51_61.height + 21)
	local var_51_63 = var_0_2:capInsets(var_51_14)
	local var_51_64 = {
		41,
		-37
	}
	local var_51_65 = {
		37,
		25,
		37,
		24
	}
	local var_51_66 = xyd.SpriteLoader.new("images/bubble/arrow/" .. var_51_14 .. ".png", nil, nil, xyd.DefaultImageType.BUBBLE_ARROW)
	local var_51_67 = xyd.SpriteLoader.new("images/bubble/bg/" .. var_51_14 .. ".png", cc.rect(var_51_63[1], var_51_63[2], var_51_63[3], var_51_63[4]), {
		size = cc.size(var_51_62.width + var_51_65[1] + var_51_65[3], var_51_62.height + var_51_65[2] + var_51_65[4])
	}, xyd.DefaultImageType.BUBBLE_BG)
	local var_51_68, var_51_69 = var_51_4:getChildByName("message_bg"):getPosition()

	var_51_67:setFlippedX(var_51_13)
	var_51_67:setAnchorPoint(0, 1)
	var_51_67:setPosition(-var_51_65[1], var_51_65[4])
	var_51_66:setAnchorPoint(1, 1)
	var_51_66:setPosition(var_51_64[1], var_51_62.height + var_51_65[2] + var_51_65[4] + var_51_64[2])
	var_51_4:getChildByName("message_bg"):addChild(var_51_67)
	var_51_67:addChild(var_51_66)
	table.insert(var_51_1, var_51_49)

	for iter_51_0, iter_51_1 in pairs(var_51_1) do
		iter_51_1:addTo(var_51_4)
		iter_51_1:setPosition(var_51_68 + var_51_62.width / 2, var_51_69 - var_51_62.height / 2 - 2)
	end

	local var_51_70 = var_51_49:getContentSize()

	if var_51_13 then
		var_51_49:setPosition(var_51_49:getPositionX() - var_51_62.width, var_51_49:getPositionY())
		var_51_67:setPosition(var_51_65[1], var_51_65[4])
	end

	if arg_51_6 == xyd.ChatTextType.REPORT or arg_51_6 == xyd.ChatTextType.LUCKY_COIN or arg_51_6 == xyd.ChatTextType.ILLUSION or arg_51_6 == xyd.ChatTextType.OCCULT or arg_51_6 == xyd.ChatTextType.ADVENTURE_ILLUSION or arg_51_6 == xyd.ChatTextType.ADVENTURE_DEFENSE or arg_51_6 == xyd.ChatTextType.RAGNAROK then
		local var_51_71 = display.newDrawNode()
		local var_51_72 = cc.c4f(var_51_17.r / 255, var_51_17.g / 255, var_51_17.b / 255, var_51_17.a / 255)

		var_51_71:setAnchorPoint(0, 0)
		var_51_71:drawSegment(cc.p(0, 1), cc.p(var_51_70.width, 1), 1, var_51_72)

		local var_51_73 = var_51_13 and var_51_70.width or 0

		var_51_71:pos(var_51_4:getChildByName("message_txt"):getPositionX() - var_51_73, 25):addTo(var_51_3, 2)
	end

	if var_51_49:getStringNumLines() > 1 then
		var_51_4:setPositionY(var_51_4:getPositionY() + var_0_8 * (var_51_49:getStringNumLines() - 1))
		var_51_3:setContentSize(var_51_3:getContentSize().width, var_51_4:getContentSize().height + var_0_8 * (var_51_49:getStringNumLines() - 1))
	end

	if var_51_51 ~= 0 then
		var_51_4:setPositionY(var_51_4:getPositionY() + var_51_51)
	end

	return var_51_3
end

function var_0_0.playReport(arg_52_0, arg_52_1)
	local var_52_0 = {
		campaignType = xyd.CampaignType.ARENA,
		campaignID = arg_52_0.campaignID,
		jsonData = arg_52_1[1].content
	}

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = xyd.WindowName.arenaRecordWnd
		}
	})
	xyd.WindowManager.get():retainHistory()
	cc.Director:getInstance():pushScene(xyd.ReportScene.new(var_52_0))
end

function var_0_0.onRegister(arg_53_0)
	arg_53_0:registerEvent(xyd.event.CHAT_SESSION_OPENED, function(arg_54_0)
		arg_53_0:setRoomID(arg_54_0.params.room_id)

		arg_53_0.active_ = true

		arg_53_0:appendMsg_(arg_53_0.WORLD_CHANNEL, arg_53_0:genLocalMessage(string.format(var_0_1:translation("CHAT_ROOM_ENTERED"), tostring(arg_53_0.room_)), false), nil)
	end)
	arg_53_0:registerEvent(xyd.event.CHAT_SESSION_CLOSED, function(arg_55_0)
		if arg_53_0.active_ then
			arg_53_0.active_ = false

			arg_53_0:appendMsg_(arg_53_0.WORLD_CHANNEL, arg_53_0:genLocalMessage(var_0_1:translation("CHAT_ROOM_STOPPED")), nil)
		end
	end)
	arg_53_0:registerEvent(xyd.event.CHAT_ROOM_MESSAGE, function(arg_56_0)
		if not arg_53_0.blockList_[arg_56_0.params.player_id] then
			arg_53_0:showMsg(arg_53_0.WORLD_CHANNEL, arg_56_0.params)
			arg_53_0:appendMsg_(arg_53_0.WORLD_CHANNEL, arg_53_0:genChatMessage(arg_56_0.params.np_info, arg_56_0.params.player_id, arg_56_0.params.player_name, arg_56_0.params.message, arg_56_0.params.player_type, arg_56_0.params.type, false, nil, nil, nil, nil, arg_56_0.params.avatar_id, arg_56_0.params.avatar_frame_id, arg_56_0.params.lev), arg_56_0.params.player_id)
			arg_53_0:saveChatMessgeToDB(arg_56_0.params.np_info, arg_53_0.WORLD_CHANNEL, arg_56_0.params.player_id, arg_56_0.params.player_name, arg_56_0.params.message, arg_56_0.params.type, arg_56_0.params.avatar_id, arg_56_0.params.avatar_frame_id, arg_56_0.params.lev, arg_56_0.params.player_type)

			arg_53_0.isNews[arg_53_0.WORLD_CHANNEL] = true

			arg_53_0:notifyChatWindow(arg_53_0.WORLD_CHANNEL)
		end
	end)
	arg_53_0:registerEvent(xyd.event.PERSONAL_CHAT_MESSAGE, function(arg_57_0)
		if not arg_53_0.blockList_[arg_57_0.params.player_id] and not arg_53_0.blockList_[arg_57_0.params.from_player_id] then
			arg_53_0:showMsg(arg_53_0.PERSONAL_CHANNEL, arg_57_0.params)
			arg_53_0:appendMsg_(arg_53_0.PERSONAL_CHANNEL, arg_53_0:genChatMessage(arg_57_0.params.np_info, arg_57_0.params.from_player_id, arg_57_0.params.from_player_name, arg_57_0.params.message, arg_57_0.params.from_player_type, arg_57_0.params.type, false, nil, nil, nil, nil, arg_57_0.params.from_player_avatar_id, arg_57_0.params.from_player_avatar_frame_id, arg_57_0.params.from_player_lev), arg_57_0.params.from_player_avatar_id)
			arg_53_0:saveChatMessgeToDB(arg_57_0.params.np_info, arg_53_0.PERSONAL_CHANNEL, arg_57_0.params.from_player_id, arg_57_0.params.from_player_name, arg_57_0.params.message, arg_57_0.params.type, arg_57_0.params.from_player_avatar_id, arg_57_0.params.from_player_avatar_frame_id, arg_57_0.params.from_player_lev, arg_57_0.params.player_type)

			arg_53_0.isNews[arg_53_0.PERSONAL_CHANNEL] = true

			arg_53_0:notifyChatWindow(arg_53_0.PERSONAL_CHANNEL, arg_57_0.params.from_player_id, arg_57_0.params.from_player_name)
		end
	end)
	arg_53_0:registerEvent(xyd.event.LEAGUE_CHAT_SESSION_OPENED, function(arg_58_0)
		arg_53_0.active_ = true

		arg_53_0:appendMsg_(arg_53_0.GUILD_CHANNEL, arg_53_0:genLocalMessage(string.format(var_0_1:translation("CHAT_ROOM_ENTERED"), var_0_1:translation("GUILD")), true), nil)
	end)
	arg_53_0:registerEvent(xyd.event.SERVICE_CHAT_SESSION_OPENED, function(arg_59_0)
		arg_53_0.active_ = true

		arg_53_0:appendMsg_(arg_53_0.SERVICE_CHANNEL, arg_53_0:genLocalMessage(string.format(var_0_1:translation("CHAT_ROOM_ENTERED"), var_0_1:translation("SERVICE_CHAT_CHANNEL")), true), nil)
	end)
	arg_53_0:registerEvent(xyd.event.LEAGUE_CHAT_ROOM_MESSAGE, function(arg_60_0)
		if not arg_53_0.blockList_[arg_60_0.params.player_id] then
			arg_53_0:showMsg(arg_53_0.GUILD_CHANNEL, arg_60_0.params)
			arg_53_0:appendMsg_(arg_53_0.GUILD_CHANNEL, arg_53_0:genChatMessage(arg_60_0.params.np_info, arg_60_0.params.player_id, arg_60_0.params.player_name, arg_60_0.params.message, arg_60_0.params.player_type, arg_60_0.params.type, false, nil, nil, nil, nil, arg_60_0.params.avatar_id, arg_60_0.params.avatar_frame_id, arg_60_0.params.lev), arg_60_0.params.player_id)
			arg_53_0:saveChatMessgeToDB(arg_60_0.params.np_info, arg_53_0.GUILD_CHANNEL, arg_60_0.params.player_id, arg_60_0.params.player_name, arg_60_0.params.message, arg_60_0.params.type, arg_60_0.params.avatar_id, arg_60_0.params.avatar_frame_id, arg_60_0.params.lev, arg_60_0.params.player_type)

			arg_53_0.isNews[arg_53_0.GUILD_CHANNEL] = true

			arg_53_0:notifyChatWindow(arg_53_0.GUILD_CHANNEL)
		end
	end)
	arg_53_0:registerEvent(xyd.event.SERVICE_CHAT_ROOM_MESSAGE, function(arg_61_0)
		if not arg_53_0.blockList_[arg_61_0.params.player_id] then
			if arg_61_0.params.type == xyd.ChatTextType.ILLUSION or arg_61_0.params.type == xyd.ChatTextType.OCCULT or arg_61_0.params.type == xyd.ChatTextType.ADVENTURE_ILLUSION or arg_61_0.params.type == xyd.ChatTextType.ADVENTURE_DEFENSE or arg_61_0.params.type == xyd.ChatTextType.RAGNAROK then
				arg_53_0:showMsg(arg_53_0.TEAM_CHANNEL, arg_61_0.params)
				arg_53_0:appendMsg_(arg_53_0.TEAM_CHANNEL, arg_53_0:genChatMessage(arg_61_0.params.np_info, arg_61_0.params.player_id, arg_61_0.params.player_name, arg_61_0.params.message, arg_61_0.params.player_type, arg_61_0.params.type, false, nil, nil, nil, nil, arg_61_0.params.avatar_id, arg_61_0.params.avatar_frame_id, arg_61_0.params.lev, arg_53_0.TEAM_CHANNEL), arg_61_0.params.player_id)
				arg_53_0:saveChatMessgeToDB(arg_61_0.params.np_info, arg_53_0.TEAM_CHANNEL, arg_61_0.params.player_id, arg_61_0.params.player_name, arg_61_0.params.message, arg_61_0.params.type, arg_61_0.params.avatar_id, arg_61_0.params.avatar_frame_id, arg_61_0.params.lev, arg_61_0.params.player_type)
			elseif arg_61_0.params.type == xyd.ChatTextType.WAR_CAMP then
				arg_53_0:nothingTodo()
			else
				arg_53_0:showMsg(arg_53_0.SERVICE_CHANNEL, arg_61_0.params)
				arg_53_0:appendMsg_(arg_53_0.SERVICE_CHANNEL, arg_53_0:genChatMessage(arg_61_0.params.np_info, arg_61_0.params.player_id, arg_61_0.params.player_name, arg_61_0.params.message, arg_61_0.params.player_type, arg_61_0.params.type, false, nil, nil, nil, nil, arg_61_0.params.avatar_id, arg_61_0.params.avatar_frame_id, arg_61_0.params.lev, arg_53_0.SERVICE_CHANNEL), arg_61_0.params.player_id)
				arg_53_0:saveChatMessgeToDB(arg_61_0.params.np_info, arg_53_0.SERVICE_CHANNEL, arg_61_0.params.player_id, arg_61_0.params.player_name, arg_61_0.params.message, arg_61_0.params.type, arg_61_0.params.avatar_id, arg_61_0.params.avatar_frame_id, arg_61_0.params.lev, arg_61_0.params.player_type)
			end
		end
	end)
	arg_53_0:registerEvent(xyd.event.LEAGUE_CHAT_ROOM_BROADCAST, function(arg_62_0)
		arg_53_0:appendMsg_(arg_53_0.GUILD_CHANNEL, arg_53_0:genChatMessage(arg_62_0.params.np_info, arg_62_0.params.from_player_id, arg_62_0.params.from_player_name, arg_62_0.params.msg, arg_62_0.params.player_type, arg_62_0.params.type, true, nil, nil, nil, nil, arg_62_0.params.from_player_avatar_id, arg_62_0.params.from_player_avatar_frame_id, arg_62_0.params.from_player_lev))
		arg_53_0:saveChatMessgeToDB(arg_62_0.params.np_info, arg_53_0.GUILD_CHANNEL, arg_62_0.params.from_player_id, arg_62_0.params.from_player_name, arg_62_0.params.msg, arg_62_0.params.type, arg_62_0.params.from_player_avatar_id, arg_62_0.params.from_player_avatar_frame_id, arg_62_0.params.from_player_lev, arg_62_0.params.player_type)

		arg_53_0.isNews[arg_53_0.GUILD_CHANNEL] = true

		arg_53_0:notifyChatWindow(arg_53_0.GUILD_CHANNEL)
	end)
	arg_53_0:registerEvent(xyd.event.RUNE_MAX_MESSAGE, function(arg_63_0)
		arg_53_0:onBroadcastMessage(10001, arg_63_0)
	end)
	arg_53_0:registerEvent(xyd.event.HERO_SUMMON_MESSAGE, function(arg_64_0)
		arg_53_0:onBroadcastMessage(10002, arg_64_0)
	end)
	arg_53_0:registerEvent(xyd.event.HERO_EVOLVE_MESSAGE, function(arg_65_0)
		arg_53_0:onBroadcastMessage(10003, arg_65_0)
	end)
	arg_53_0:registerEvent(xyd.event.SECRET_DUNGEON_MESSAGE, function(arg_66_0)
		arg_53_0:onBroadcastMessage(10004, arg_66_0)
	end)
	arg_53_0:registerEvent(xyd.event.ASK_GM_QUESTION, handler(arg_53_0, arg_53_0.afterAskGmQuestion_))
	arg_53_0:registerEvent(xyd.event.LOAD_GM_QUESTIONS, handler(arg_53_0, arg_53_0.onLoadGmQuestions_))
	arg_53_0:registerEvent(xyd.event.GM_BROADCAST, handler(arg_53_0, arg_53_0.onGlobalBroadcast))
	arg_53_0:registerEvent(xyd.event.CLOSE_GUILD_CHAT, handler(arg_53_0, arg_53_0.onCloseGuildChat))
	arg_53_0:registerEvent(xyd.event.ROOMID_UPDATE, handler(arg_53_0, arg_53_0.onGuildUpdate))
	arg_53_0:registerEvent(xyd.event.LEAGUE_ALLY_MESSAGE, handler(arg_53_0, arg_53_0.onGuildAlly))
end

function var_0_0.nothingTodo(arg_67_0)
	return
end

function var_0_0.showMsg(arg_68_0, arg_68_1, arg_68_2)
	if arg_68_1 ~= arg_68_0:getChannel() then
		return
	end

	local var_68_0 = xyd.WindowManager.get():getWindow("main_scene_bottom")

	if var_68_0 then
		var_68_0:ChatShowEvent(arg_68_1, arg_68_2)
	end
end

function var_0_0.debugMessage(arg_69_0, arg_69_1)
	arg_69_0:appendMsg_(arg_69_0.WORLD_CHANNEL, arg_69_0:genLocalMessage(arg_69_1, false))
end

function var_0_0.parseMessage(arg_70_0, arg_70_1)
	local var_70_0 = {}

	while true do
		local var_70_1, var_70_2 = arg_70_1:find("%s", 1, true)

		if var_70_1 == nil then
			table.insert(var_70_0, arg_70_1)

			break
		else
			if var_70_1 > 1 then
				table.insert(var_70_0, arg_70_1:sub(1, var_70_1 - 1))
			end

			table.insert(var_70_0, "%s")

			arg_70_1 = arg_70_1:sub(var_70_2 + 1)
		end
	end

	return var_70_0
end

function var_0_0.genItem(arg_71_0, arg_71_1, arg_71_2, arg_71_3, arg_71_4)
	local var_71_0 = 10
	local var_71_1 = var_0_3:loadLabel({
		size = var_0_7,
		color = arg_71_2
	})

	var_71_1:setString(arg_71_1)
	var_71_1:setLineHeight(var_0_8)

	local var_71_2 = var_0_3:loadSprite("images/chat_item_background.png", cc.rect(14, 24, 1, 1))
	local var_71_3 = var_71_1:getContentSize().width

	if arg_71_4 then
		var_71_3 = var_71_3 + arg_71_4:getContentSize().width + 5

		arg_71_4:setAnchorPoint(0, 0.5)
		arg_71_4:pos(var_71_0, var_71_2:getContentSize().height * 0.5):addTo(var_71_2, 5)
	end

	var_71_2:setContentSize(var_71_3 + var_71_0 * 2, 49)
	var_71_1:setAnchorPoint(1, 0.5)
	var_71_1:pos(var_71_2:getContentSize().width - var_71_0, var_71_2:getContentSize().height * 0.5):addTo(var_71_2, 5)
	var_71_2:setTouchEnabled(true)
	var_71_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_72_0)
		if arg_72_0.name == "began" then
			return true
		elseif arg_72_0.name == "ended" then
			audio.playSound("sound/window_open.ogg", false)

			if arg_71_3 then
				arg_71_3()
			end
		end
	end)
	var_71_2:setAnchorPoint(0, 0)
	var_71_2:pos(0, 0)

	return var_71_2
end

function var_0_0.genBroadcastMessage(arg_73_0, arg_73_1, arg_73_2, arg_73_3)
	local var_73_0 = display.newNode()
	local var_73_1 = 0
	local var_73_2 = 0

	for iter_73_0, iter_73_1 in pairs(arg_73_1) do
		if iter_73_1 ~= "%s" then
			local var_73_3 = var_0_3:loadLabel({
				size = var_0_7,
				color = cc.c4b(93, 217, 222, 255)
			})

			var_73_3:setString(iter_73_1)
			var_73_3:setLineHeight(var_0_8)
			var_73_3:setAnchorPoint(0, 0.5)
			var_73_3:pos(var_73_1, var_0_8 * 0.5):addTo(var_73_0)

			var_73_1 = var_73_1 + var_73_3:getContentSize().width
		elseif var_73_2 == 0 then
			if iter_73_0 ~= 1 then
				var_73_1 = var_73_1 + var_0_10
			end

			local var_73_4 = arg_73_0:genUserName(arg_73_3.player_name, arg_73_3.player_id, cc.c4b(93, 217, 222, 255))

			var_73_4:setAnchorPoint(0, 0.5)
			var_73_4:pos(var_73_1, var_0_8 * 0.5):addTo(var_73_0)

			var_73_2 = var_73_2 + 1
			var_73_1 = var_73_1 + var_73_4:getContentSize().width + var_0_10
		elseif var_73_2 == 2 then
			local var_73_5 = var_0_3:loadLabel({
				size = var_0_7,
				color = cc.c4b(93, 217, 222, 255)
			})

			var_73_5:setString(arg_73_3.star)
			var_73_5:setLineHeight(var_0_8)
			var_73_5:setAnchorPoint(0, 0.5)
			var_73_5:pos(var_73_1, var_0_8 * 0.5):addTo(var_73_0)

			var_73_1 = var_73_1 + var_73_5:getContentSize().width
			var_73_2 = var_73_2 + 1
		elseif arg_73_2 == 10001 then
			if iter_73_0 ~= 1 then
				var_73_1 = var_73_1 + var_0_10
			end

			local var_73_6 = arg_73_0:genItem(xyd.tables.rune:getMainName(arg_73_3.table_id), cc.c4b(0, 0, 0, 255), function()
				xyd.WindowManager.get():openWindow("rune_info"):setRune(arg_73_3.rune_id, arg_73_3.player_id)
			end)

			var_73_6:setAnchorPoint(0, 0.5)
			var_73_6:pos(var_73_1, var_0_8 * 0.5):addTo(var_73_0)

			var_73_1 = var_73_1 + var_73_6:getContentSize().width + var_0_10
			var_73_2 = var_73_2 + 1
		else
			if iter_73_0 ~= 1 then
				var_73_1 = var_73_1 + var_0_10
			end

			local var_73_7 = arg_73_3.table_id

			if arg_73_2 == 10004 then
				var_73_7 = xyd.tables.stage:getDropHeroID(arg_73_3.table_id)
			end

			local var_73_8 = xyd.tables.scroll:initialStar(var_73_7)

			if arg_73_3.star then
				var_73_8 = arg_73_3.star
			end

			local var_73_9 = arg_73_0:genItem(xyd.tables.hero:name(var_73_7), cc.c4b(0, 0, 0, 255), function()
				xyd.WindowManager.get():openWindow("hero_detail"):setHero(var_73_7, var_73_8)
			end, var_0_3:loadSprite(xyd.heroClassMiddleIconName(xyd.tables.hero:heroClass(var_73_7))))

			var_73_9:setAnchorPoint(0, 0.5)
			var_73_9:pos(var_73_1, var_0_8 * 0.5):addTo(var_73_0)

			var_73_1 = var_73_1 + var_73_9:getContentSize().width + var_0_10
			var_73_2 = var_73_2 + 1
		end
	end

	var_73_0:setContentSize(var_0_9, var_0_8)

	return var_73_0
end

function var_0_0.onBroadcastMessage(arg_76_0, arg_76_1, arg_76_2)
	local var_76_0 = arg_76_0:parseMessage(xyd.tables.message:getContent(arg_76_1))

	arg_76_0:appendMsg_(arg_76_0.WORLD_CHANNEL, arg_76_0:genBroadcastMessage(var_76_0, arg_76_1, arg_76_2.params.params))
end

function var_0_0.clear(arg_77_0)
	for iter_77_0, iter_77_1 in pairs(arg_77_0.messageList_[arg_77_0.WORLD_CHANNEL]) do
		iter_77_1:release()
	end

	arg_77_0.messageList_[arg_77_0.WORLD_CHANNEL] = {}

	for iter_77_2, iter_77_3 in pairs(arg_77_0.messageList_[arg_77_0.GUILD_CHANNEL]) do
		iter_77_3:release()
	end

	for iter_77_4, iter_77_5 in pairs(arg_77_0.messageList_[arg_77_0.PERSONAL_CHANNEL]) do
		iter_77_5:release()
	end

	for iter_77_6, iter_77_7 in pairs(arg_77_0.messageList_[arg_77_0.SERVICE_CHANNEL]) do
		iter_77_7:release()
	end

	for iter_77_8, iter_77_9 in pairs(arg_77_0.messageList_[arg_77_0.TEAM_CHANNEL]) do
		iter_77_9:release()
	end

	arg_77_0.messageList_[arg_77_0.PERSONAL_CHANNEL] = {}
end

local var_0_13 = require("framework.scheduler")

function var_0_0.onGlobalBroadcast(arg_78_0, arg_78_1)
	local var_78_0 = 1.8
	local var_78_1 = string.len(arg_78_1.params.msg) / 3 / var_78_0
	local var_78_2 = 690 / xyd.rollingWidthPerWorld(text, xyd.AssetLoader.FONT_NAME, 30) / var_78_0 + var_78_1
	local var_78_3 = 1

	arg_78_0.broadcastList = arg_78_0.broadcastList or {}

	table.insert(arg_78_0.broadcastList, arg_78_1.params.msg)

	if arg_78_0.broadcastHandler == nil then
		arg_78_0:showBroadcast(var_78_2, arg_78_1.params.msg_type)

		arg_78_0.broadcastHandler = var_0_13.scheduleGlobal(function(arg_79_0)
			if #arg_78_0.broadcastList == 0 then
				var_0_13.unscheduleGlobal(arg_78_0.broadcastHandler)

				arg_78_0.broadcastHandler = nil
			else
				arg_78_0:showBroadcast(var_78_2, arg_78_1.params.msg_type)
			end
		end, var_78_2 + var_78_3)
	end
end

function var_0_0.setChatLimit(arg_80_0, arg_80_1, arg_80_2)
	local var_80_0 = arg_80_1
	local var_80_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if xyd.isDebug() == true or var_80_1.playerType == xyd.ChatPlayerType.FreshManGuide then
		var_80_0 = 0
	end

	if not arg_80_0.chatLimit then
		arg_80_0.chatLimit = {}
	end

	arg_80_0.chatLimit[arg_80_2] = var_80_0

	local function var_80_2()
		local var_81_0 = 0

		for iter_81_0 = 1, 5 do
			if arg_80_0.chatLimit[iter_81_0] == nil or arg_80_0.chatLimit[iter_81_0] <= 0 then
				var_81_0 = var_81_0 + 1
			else
				arg_80_0.chatLimit[iter_81_0] = arg_80_0.chatLimit[iter_81_0] - 1
			end
		end

		if var_81_0 == 5 then
			var_0_13.unscheduleGlobal(arg_80_0.handle_)

			arg_80_0.handle_ = nil
		end
	end

	if arg_80_0.handle_ == nil then
		arg_80_0.handle_ = var_0_13.scheduleGlobal(function()
			var_80_2()
		end, 1)
	end
end

function var_0_0.setGmChannelStatus(arg_83_0, arg_83_1)
	arg_83_0.hasGmResponse = arg_83_1
end

function var_0_0.onGuildUpdate(arg_84_0, arg_84_1)
	local var_84_0 = arg_84_1.params

	if var_84_0 == nil then
		return
	else
		local var_84_1 = var_84_0.roomID

		if var_84_1 == nil then
			arg_84_0.guildRoom_ = nil
			arg_84_0.guildRoomId_ = nil

			xyd.Backend.get():closeLeagueRoom()
		elseif arg_84_0.guildRoomId_ ~= var_84_1 then
			arg_84_0.guildRoomId_ = var_84_1

			arg_84_0:enterLeagueChatRoom()
		end
	end
end

function var_0_0.onCloseGuildChat(arg_85_0, arg_85_1)
	arg_85_0.guildRoom_ = nil
	arg_85_0.guildRoomId_ = nil

	xyd.Backend.get():closeLeagueRoom()
end

function var_0_0.showBroadcast(arg_86_0, arg_86_1, arg_86_2)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.SHOW_BROADCAST,
		params = {
			msg = arg_86_0.broadcastList[1],
			time = arg_86_1,
			msg_type = arg_86_2
		}
	})
	table.remove(arg_86_0.broadcastList, 1)
end

function var_0_0.afterAskGmQuestion_(arg_87_0, arg_87_1)
	local var_87_0 = {
		id = 8,
		talker_id = arg_87_0.selfPlayerID_,
		player_id = arg_87_0.selfPlayerID_,
		created_time = xyd.ServerTime.get():getServerTime() or 0,
		msg = arg_87_1.userdata.msg,
		talker_name = arg_87_0.selfPlayerName_,
		avatar_id = arg_87_0.selfPlayerAvatar_,
		avatar_frame_id = arg_87_0.selfPlayerFrame_,
		lev = arg_87_0.selfPlayerLev_
	}
	local var_87_1 = arg_87_0:genGmChatMessage(var_87_0)

	if arg_87_0.waitGmAnswer == true then
		table.remove(arg_87_0.messageList_[arg_87_0.GM_CHANNEL], 1)
	end

	arg_87_0:appendMsg_(arg_87_0.GM_CHANNEL, var_87_1)

	arg_87_0.waitGmAnswer = true
end

function var_0_0.onLoadGmQuestions_(arg_88_0, arg_88_1)
	if #arg_88_1.params.list ~= 0 then
		for iter_88_0, iter_88_1 in pairs(arg_88_0.messageList_[arg_88_0.GM_CHANNEL]) do
			iter_88_1:release()
		end

		arg_88_0.messageList_[arg_88_0.GM_CHANNEL] = {}

		for iter_88_2, iter_88_3 in pairs(arg_88_1.params.list) do
			arg_88_0:appendMsg_(arg_88_0.GM_CHANNEL, arg_88_0:genGmChatMessage(iter_88_3))
		end

		if arg_88_1.params.list[#arg_88_1.params.list].talker_id ~= 10000 then
			arg_88_0.waitGmAnswer = true
		end

		local function var_88_0(arg_89_0)
			local var_89_0 = {}
			local var_89_1 = #arg_89_0

			for iter_89_0, iter_89_1 in ipairs(arg_89_0) do
				var_89_0[var_89_1 + 1 - iter_89_0] = iter_89_1
			end

			return var_89_0
		end
	end
end

function var_0_0.reloadEvent_(arg_90_0, arg_90_1)
	arg_90_0.allOfflineInfoNum = 0

	if arg_90_1.params.talk_gm ~= nil then
		arg_90_0.hasGmResponse = arg_90_1.params.talk_gm
	end
end

function var_0_0.saveChatMessgeToDB(arg_91_0, arg_91_1, arg_91_2, arg_91_3, arg_91_4, arg_91_5, arg_91_6, arg_91_7, arg_91_8, arg_91_9, arg_91_10)
	local var_91_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_91_1 = arg_91_7
	local var_91_2 = arg_91_8
	local var_91_3 = arg_91_9
	local var_91_4 = arg_91_4

	if arg_91_3 == var_91_0.playerID then
		var_91_4 = var_91_0.playerName
		var_91_1 = var_91_0:getMyCurrentAvatarID()
		var_91_2 = var_91_0.avatarFrame
		var_91_3 = var_91_0.lev
	end

	if xyd.tables.chatConfig:isRecordOpen(arg_91_2) == 1 then
		local var_91_5 = {
			npInfo = arg_91_1 or "",
			id = xyd.generateUUID() or "",
			serverID = arg_91_0.region_ or 1,
			playerID = arg_91_0.selfPlayerID_ or 0,
			channelID = arg_91_2 or 0,
			time = xyd.ServerTime.get():getServerTime() or 0,
			message = arg_91_5 or "",
			messageType = arg_91_6 or 0,
			speakerID = arg_91_3 or 0,
			speakerName = var_91_4 or "",
			speakerLev = var_91_3 or 0,
			speakerAvatar = var_91_1 or 0,
			speakerFrame = var_91_2 or 0
		}

		if arg_91_10 and type(arg_91_10) == "number" then
			var_91_5.isGM = arg_91_10
		else
			var_91_5.isGM = 0
		end

		xyd.db.chatMessages:addChatMessage(var_91_5)
		table.insert(arg_91_0.dbMessageList_[arg_91_2], var_91_5)

		if #arg_91_0.dbMessageList_[arg_91_2] > xyd.tables.chatConfig:maxRecordNum(arg_91_2) then
			local var_91_6 = arg_91_0.dbMessageList_[arg_91_2][1].id

			table.remove(arg_91_0.dbMessageList_[arg_91_2], 1)
			xyd.db.chatMessages:deleteChatMessage(var_91_6)
		end
	end
end

return var_0_0
