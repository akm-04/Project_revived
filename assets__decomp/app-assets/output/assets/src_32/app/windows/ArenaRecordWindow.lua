local var_0_0 = class("ArenaRecordWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.type = arg_1_2.type or xyd.CampaignType.ARENA
	arg_1_0.records = arg_1_2.records
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.peakArena = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA)
	arg_1_0.regionCasualArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_CASUAL_ARENA)
	arg_1_0.report = arg_1_2.reports or {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	local var_2_0 = xyd.AssetLoader.get():loadSprite("windows/arena/record/title_text.png")

	var_2_0:addTo(arg_2_0:nodeByName("title"))
	var_2_0:setAnchorPoint(cc.p(0, 0))
	arg_2_0:cancelArenaRedMark()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.cancelArenaRedMark(arg_4_0)
	if arg_4_0.type == xyd.CampaignType.ARENA then
		if arg_4_0.selfPlayer.arenaRedMarkEnable then
			if arg_4_0.selfPlayer.newReportKeyTable and next(arg_4_0.selfPlayer.newReportKeyTable) then
				xyd.db.arenaReportKeys:deleteAllReportKeys(arg_4_0.selfPlayer.playerID)

				for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfPlayer.newReportKeyTable) do
					xyd.db.arenaReportKeys:setArenaReportKeys(arg_4_0.selfPlayer.playerID, iter_4_1)
				end
			end

			arg_4_0.selfPlayer.arenaRedMarkEnable = false

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.CHECK_MIDDLE_RED_MARK,
				params = xyd.CheckMiddleRed.ARENA_CANCEL
			})
		end
	elseif (arg_4_0.type == xyd.CampaignType.SUPER_ARENA or arg_4_0.type == xyd.CampaignType.SUPER_ARENA_OLD) and arg_4_0.selfPlayer.peakArenaRedMarkEnable then
		if arg_4_0.selfPlayer.newPeakReportKeyTable and next(arg_4_0.selfPlayer.newPeakReportKeyTable) then
			xyd.db.peakArenaReportKeys:deleteAllReportKeys(arg_4_0.selfPlayer.playerID)

			for iter_4_2, iter_4_3 in ipairs(arg_4_0.selfPlayer.newPeakReportKeyTable) do
				xyd.db.peakArenaReportKeys:setReportKeys(arg_4_0.selfPlayer.playerID, iter_4_3)
			end
		end

		arg_4_0.selfPlayer.peakArenaRedMarkEnable = false

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHECK_MIDDLE_RED_MARK,
			params = xyd.CheckMiddleRed.PEAK_CANCEL
		})
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0.container = arg_5_0:nodeByName("inner")

	local var_5_0 = arg_5_0.container:getContentSize()

	arg_5_0.recordList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_5_0.width, var_5_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_5_0.container):onScroll(handler(arg_5_0, arg_5_0.scrollListener)):setTouchType(true):pos(0, 0)

	arg_5_0:updateRecordList()
end

function var_0_0.updateRecordList(arg_6_0)
	if not arg_6_0.records or not next(arg_6_0.records) then
		return
	end

	arg_6_0.recordList_:removeAllItems()

	local var_6_0 = {}

	for iter_6_0, iter_6_1 in pairs(arg_6_0.records) do
		local function var_6_1(arg_7_0, arg_7_1, arg_7_2)
			local var_7_0 = {}
			local var_7_1

			if arg_7_0 and next(arg_7_0) then
				for iter_7_0, iter_7_1 in pairs(arg_7_0) do
					local var_7_2 = iter_7_1

					if arg_7_2 == true then
						var_7_2.table_id = iter_7_1.partner_id
						var_7_2.partner_id = iter_7_0
					end

					if type(var_7_2.equips) == "string" then
						var_7_2.equips = xyd.splitToNumber(var_7_2.equips, "|")
					end

					if bookshelfLev and bookshelfLev > 0 then
						var_7_2.book_shelf_lev = bookshelfLev
					else
						var_7_2.book_shelf_lev = 0
					end

					local var_7_3 = import("app.model.Hero").new()

					var_7_3:populate(var_7_2)
					table.insert(var_7_0, var_7_3)
				end
			end

			if arg_7_1 then
				local var_7_4 = arg_7_1

				if type(var_7_4.equips) == "string" then
					var_7_4.equips = xyd.splitToNumber(var_7_4.equips, "|")
				end

				local var_7_5 = import("app.model.Pet").new()

				var_7_5:populate(var_7_4)

				var_7_1 = var_7_5
			end

			return var_7_0, var_7_1
		end

		local function var_6_2(arg_8_0)
			if arg_8_0.name == "began" then
				-- block empty
			elseif arg_8_0.name == "ended" then
				local var_8_0 = {
					id = iter_6_1.id
				}
				local var_8_1 = iter_6_1.mode and xyd.mid.ARENA_MODE_RECORD_PLAYER_INFO or xyd.mid.ARENA_GET_RCORD_PLAYER_INFO

				xyd.Backend.get():request(var_8_1, var_8_0, function(arg_9_0, arg_9_1)
					if arg_9_0 == xyd.error.OK then
						local var_9_0 = {
							name = arg_9_1.records.player_name,
							level = arg_9_1.records.lev,
							avatar_id = arg_9_1.records.avatar_id,
							avatar_frame_id = arg_9_1.records.avatar_frame_id,
							win = arg_9_1.records.win,
							rank = arg_9_1.records.rank,
							can_avenge = arg_9_1.records.can_avenge,
							guild = arg_9_1.records.guild_name,
							pet = arg_9_1.records.pet,
							table_id = arg_9_1.records.table_id,
							avenge_type = arg_9_1.records.avenge_type,
							is_attack = iter_6_1.is_attack,
							has_win = tonumber(iter_6_1.win),
							conquer_lev = arg_9_1.records.conquer_lev
						}

						var_9_0.heroes, var_9_0.pets = var_6_1(arg_9_1.records.heros, arg_9_1.records.pet, arg_9_1.records.is_robot)

						xyd.WindowManager.get():openWindow("arena_record_player_info", {
							team = var_9_0
						})
					end
				end)
			end

			return true
		end

		if arg_6_0.type == xyd.CampaignType.ARENA then
			if iter_6_1.attack_name then
				local var_6_3 = display.newNode()
				local var_6_4 = arg_6_0.recordList_:newItem()
				local var_6_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/record/record_item.csb")
				local var_6_6 = var_6_5:getChildByName("container")

				if tonumber(iter_6_1.is_attack) == 1 and tonumber(iter_6_1.defend_avatar) ~= 0 then
					local var_6_7 = {
						avatar_id = tonumber(iter_6_1.defend_avatar),
						avatar_frame_id = iter_6_1.defend_avatar_frame,
						callback = var_6_2
					}

					xyd.setPlayerAvatar(var_6_6:getChildByName("avatar"), var_6_7)

					if iter_6_1.defend_conquer_lev and iter_6_1.defend_conquer_lev > 0 then
						xyd.setConquerLev(iter_6_1.defend_conquer_lev, var_6_6:getChildByName("text_level"), var_6_6:getChildByName("dengjiquan"), nil, nil, nil, nil, iter_6_1.defend_conquer_loop_id)
					else
						var_6_6:getChildByName("text_level"):setString(iter_6_1.defend_lev)
					end

					var_6_6:getChildByName("text_player_name"):setString(iter_6_1.defend_name)
				elseif tonumber(iter_6_1.is_attack) == 1 and tonumber(iter_6_1.defend_avatar) == 0 then
					local var_6_8 = {
						avatar_id = xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId],
						avatar_frame_id = iter_6_1.defend_avatar_frame,
						callback = var_6_2
					}

					xyd.setPlayerAvatar(var_6_6:getChildByName("avatar"), var_6_8)

					if iter_6_1.defend_conquer_lev and iter_6_1.defend_conquer_lev > 0 then
						xyd.setConquerLev(iter_6_1.defend_conquer_lev, var_6_6:getChildByName("text_level"), var_6_6:getChildByName("dengjiquan"), nil, nil, nil, nil, iter_6_1.defend_conquer_loop_id)
					else
						var_6_6:getChildByName("text_level"):setString(iter_6_1.defend_lev)
					end

					var_6_6:getChildByName("text_player_name"):setString(iter_6_1.defend_name)
				else
					local var_6_9 = {
						avatar_id = tonumber(iter_6_1.attack_avatar),
						avatar_frame_id = iter_6_1.attack_avatar_frame,
						callback = var_6_2
					}

					xyd.setPlayerAvatar(var_6_6:getChildByName("avatar"), var_6_9)

					if iter_6_1.attack_conquer_lev and iter_6_1.attack_conquer_lev > 0 then
						xyd.setConquerLev(iter_6_1.attack_conquer_lev, var_6_6:getChildByName("text_level"), var_6_6:getChildByName("dengjiquan"), nil, nil, nil, nil, iter_6_1.attack_conquer_loop_id)
					else
						var_6_6:getChildByName("text_level"):setString(iter_6_1.attack_lev)
					end

					var_6_6:getChildByName("text_player_name"):setString(iter_6_1.attack_name)
				end

				local var_6_10 = var_6_6:getChildByName("win")
				local var_6_11 = var_6_6:getChildByName("lose")
				local var_6_12 = cc.p(var_6_10:getPosition())

				if tonumber(iter_6_1.win) == 1 then
					var_6_10:setVisible(true)
					var_6_10:setPosition(var_6_12.x, var_6_12.y + 20)
					var_6_11:setVisible(false)
				else
					var_6_11:setVisible(true)
					var_6_11:setPosition(var_6_12.x, var_6_12.y + 20)
					var_6_10:setVisible(false)
				end

				local var_6_13 = var_6_6:getChildByName("mode_name")

				if iter_6_1.mode then
					var_6_13:setString(xyd.tables.arenaMode:title(iter_6_1.mode))
				else
					var_6_13:setColor(cc.c3b(125, 51, 0))
					var_6_13:setString(var_0_3:translation("ARENA_REPORT_DESC"))
				end

				if iter_6_1.time then
					local var_6_14 = xyd.ServerTime.get():getServerTime() - iter_6_1.time

					var_6_6:getChildByName("text_time"):setString(xyd.secondsToString(var_6_14, {
						short = true,
						toText = true
					}) .. xyd.tables.translation:translation("BEFORE"))
				end

				local var_6_15 = var_6_6:getContentSize()

				var_6_5:setPosition(cc.p(15, 0))
				var_6_5:setContentSize(var_6_15.width + 15, var_6_15.height)
				var_6_3:addChild(var_6_5)
				var_6_3:setContentSize(cc.size(arg_6_0.recordList_.viewRect_.width, var_6_5:getContentSize().height + 5))
				var_6_4:addContent(var_6_3)
				var_6_4:setItemSize(arg_6_0.recordList_.viewRect_.width, var_6_3:getContentSize().height)

				local var_6_16 = var_6_6:getChildByName("share_btn")
				local var_6_17 = var_6_6:getChildByName("replay_btn")

				var_6_6:getChildByName("replay"):setVisible(true)
				var_6_6:getChildByName("select"):setVisible(false)
				var_6_16:addTouchEventListener(function(arg_10_0, arg_10_1)
					if arg_10_1 == ccui.TouchEventType.ended then
						local var_10_0 = {}

						if tonumber(iter_6_1.is_attack) == 1 then
							var_10_0.enemy_name = iter_6_1.defend_name
						else
							var_10_0.enemy_name = iter_6_1.attack_name
						end

						var_10_0.player_id = arg_6_0.selfPlayer.playerID
						var_10_0.player_name = arg_6_0.selfPlayer.playerName
						var_10_0.time = iter_6_1.time
						var_10_0.is_attack = iter_6_1.is_attack
						var_10_0.id = iter_6_1.id

						local var_10_1 = json.encode(var_10_0)

						xyd.WindowManager.get():openWindow("record_share_menu", {
							message = var_10_1
						})
					end
				end)

				local function var_6_18(arg_11_0)
					if arg_6_0.report[tonumber(iter_6_1.id)] then
						arg_6_0:replayRecord(arg_6_0.report[tonumber(iter_6_1.id)], arg_11_0)
					else
						local var_11_0 = {
							player_id = arg_6_0.selfPlayer.playerID,
							report_key = iter_6_1.report_key
						}
						local var_11_1 = iter_6_1.mode and xyd.mid.ARENA_MODE_RECORD_DETAIL or xyd.mid.LOAD_ARENA_FIGHT_REPORT

						xyd.Backend.get():request(var_11_1, var_11_0, function(arg_12_0, arg_12_1)
							if arg_12_0 == xyd.error.OK then
								if arg_12_1 == nil or arg_12_1 == {} then
									if xyd.WindowManager.get():getWindow("toast") ~= nil then
										xyd.WindowManager.get():closeWindow("toast")
									end

									xyd.WindowManager.get():openWindow("toast", {
										message = var_0_3:translation("ARENA_RECORD_OUT_OF_DATE")
									})
								else
									table.insert(arg_6_0.report, iter_6_1.id, arg_12_1.report)
									arg_6_0:replayRecord(arg_12_1.report, arg_11_0)
								end
							end
						end)
					end
				end

				var_6_17:addTouchEventListener(function(arg_13_0, arg_13_1)
					if arg_13_1 == ccui.TouchEventType.ended then
						var_6_18()
					end
				end)
				var_6_6:getChildByName("data_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
					if arg_14_1 == ccui.TouchEventType.ended then
						var_6_18(true)
					end
				end)
				arg_6_0.recordList_:addItem(var_6_4)
			end
		elseif arg_6_0.type == xyd.CampaignType.SUPER_ARENA then
			local var_6_19 = {}
			local var_6_20 = display.newNode()
			local var_6_21 = arg_6_0.recordList_:newItem()
			local var_6_22 = arg_6_0:createPeakItem(iter_6_1)

			var_6_20:addChild(var_6_22)
			var_6_20:setContentSize(cc.size(arg_6_0.recordList_.viewRect_.width, var_6_22:getContentSize().height + 5))
			var_6_21:addContent(var_6_20)
			var_6_21:setItemSize(arg_6_0.recordList_.viewRect_.width, var_6_20:getContentSize().height)
			arg_6_0.recordList_:addItem(var_6_21)
		elseif arg_6_0.type == xyd.CampaignType.SUPER_ARENA_OLD then
			local var_6_23 = {}

			if iter_6_1.attacker_name then
				local var_6_24 = display.newNode()
				local var_6_25 = arg_6_0.recordList_:newItem()
				local var_6_26 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/record/record_item.csb")
				local var_6_27 = var_6_26:getChildByName("container")

				if tonumber(iter_6_1.is_attack) == 1 and tonumber(iter_6_1.defencer_avatar) ~= 0 then
					local var_6_28 = {
						"attack"
					}
					local var_6_29 = {
						avatar_id = tonumber(iter_6_1.defencer_avatar),
						avatar_frame_id = iter_6_1.defencer_avatar_frame
					}

					xyd.setPlayerAvatar(var_6_27:getChildByName("avatar"), var_6_29)

					if iter_6_1.defencer_conquer_lev and iter_6_1.defencer_conquer_lev > 0 then
						xyd.setConquerLev(iter_6_1.defencer_conquer_lev, var_6_27:getChildByName("text_level"), var_6_27:getChildByName("dengjiquan"), nil, nil, nil, nil, iter_6_1.defencer_conquer_loop_id)
					else
						var_6_27:getChildByName("text_level"):setString(iter_6_1.defencer_lev)
					end

					var_6_27:getChildByName("text_player_name"):setString(iter_6_1.defencer_name)
				elseif tonumber(iter_6_1.is_attack) == 1 and tonumber(iter_6_1.defencer_avatar) == 0 then
					local var_6_30 = {
						"attack"
					}
					local var_6_31 = {
						avatar_id = xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId],
						avatar_frame_id = iter_6_1.defencer_avatar_frame
					}

					xyd.setPlayerAvatar(var_6_27:getChildByName("avatar"), var_6_31)

					if iter_6_1.defencer_conquer_lev and iter_6_1.defencer_conquer_lev > 0 then
						xyd.setConquerLev(iter_6_1.defencer_conquer_lev, var_6_27:getChildByName("text_level"), var_6_27:getChildByName("dengjiquan"), nil, nil, nil, nil, iter_6_1.defencer_conquer_loop_id)
					else
						var_6_27:getChildByName("text_level"):setString(iter_6_1.defencer_lev)
					end

					var_6_27:getChildByName("text_player_name"):setString(iter_6_1.defencer_name)
				else
					local var_6_32 = {
						"attack"
					}
					local var_6_33 = {
						avatar_id = tonumber(iter_6_1.attacker_avatar),
						avatar_frame_id = iter_6_1.attacker_avatar_frame
					}

					xyd.setPlayerAvatar(var_6_27:getChildByName("avatar"), var_6_33)

					if iter_6_1.attacker_conquer_lev and iter_6_1.attacker_conquer_lev > 0 then
						xyd.setConquerLev(iter_6_1.attacker_conquer_lev, var_6_27:getChildByName("text_level"), var_6_27:getChildByName("dengjiquan"), nil, nil, nil, nil, iter_6_1.attacker_conquer_loop_id)
					else
						var_6_27:getChildByName("text_level"):setString(iter_6_1.attacker_lev)
					end

					var_6_27:getChildByName("text_player_name"):setString(iter_6_1.attacker_name)
				end

				if tonumber(iter_6_1.win) == 1 then
					var_6_27:getChildByName("win"):setVisible(true)
					var_6_27:getChildByName("lose"):setVisible(false)
				else
					var_6_27:getChildByName("win"):setVisible(false)
					var_6_27:getChildByName("lose"):setVisible(true)
				end

				if iter_6_1.time then
					local var_6_34 = xyd.ServerTime.get():getServerTime() - iter_6_1.time

					var_6_27:getChildByName("text_time"):setString(xyd.secondsToString(var_6_34, {
						short = true,
						toText = true
					}) .. xyd.tables.translation:translation("BEFORE"))
				end

				local var_6_35 = var_6_27:getContentSize()

				var_6_26:setPosition(cc.p(15, 0))
				var_6_26:setContentSize(var_6_35.width + 15, var_6_35.height)
				var_6_24:addChild(var_6_26)
				var_6_24:setContentSize(cc.size(arg_6_0.recordList_.viewRect_.width, var_6_26:getContentSize().height + 5))
				var_6_25:addContent(var_6_24)
				var_6_25:setItemSize(arg_6_0.recordList_.viewRect_.width, var_6_24:getContentSize().height)

				local var_6_36 = var_6_27:getChildByName("share_btn")
				local var_6_37 = var_6_27:getChildByName("replay_btn")

				var_6_27:getChildByName("replay"):setVisible(false)
				var_6_27:getChildByName("select"):setVisible(true)
				var_6_27:getChildByName("data_icon"):setVisible(false)
				var_6_27:getChildByName("data_btn"):setVisible(false)
				var_6_36:addTouchEventListener(function(arg_15_0, arg_15_1)
					if arg_15_1 == ccui.TouchEventType.ended then
						local var_15_0 = {}

						if tonumber(iter_6_1.is_attack) == 1 then
							var_15_0.enemy_name = iter_6_1.defencer_name
						else
							var_15_0.enemy_name = iter_6_1.attacker_name
						end

						var_15_0.player_id = arg_6_0.selfPlayer.playerID
						var_15_0.player_name = arg_6_0.selfPlayer.playerName
						var_15_0.time = iter_6_1.time
						var_15_0.is_attack = iter_6_1.is_attack
						var_15_0.id = iter_6_1.id
						var_15_0.report_key = iter_6_1.report_key
						var_15_0.defencer_name = iter_6_1.defencer_name
						var_15_0.attacker_name = iter_6_1.attacker_name
						var_15_0.defencer_avatar = iter_6_1.defencer_avatar
						var_15_0.attacker_avatar = iter_6_1.attacker_avatar
						var_15_0.defencer_avatar_frame = iter_6_1.defencer_avatar_frame
						var_15_0.attacker_avatar_frame = iter_6_1.attacker_avatar_frame
						var_15_0.defencer_lev = iter_6_1.defencer_lev
						var_15_0.attacker_lev = iter_6_1.attacker_lev
						var_15_0.win = iter_6_1.win

						local var_15_1 = json.encode(var_15_0)

						xyd.WindowManager.get():openWindow("record_share_menu", {
							message = var_15_1
						})
					end
				end)
				var_6_37:addTouchEventListener(function(arg_16_0, arg_16_1)
					if arg_16_1 == ccui.TouchEventType.ended then
						local var_16_0 = {
							report_key = iter_6_1.report_key
						}

						arg_6_0.peakArena:getPeakReports(var_16_0, function(arg_17_0, arg_17_1)
							if arg_17_0 == xyd.error.OK then
								if arg_17_1 == nil or arg_17_1 == {} then
									if xyd.WindowManager.get():getWindow("toast") ~= nil then
										xyd.WindowManager.get():closeWindow("toast")
									end

									xyd.WindowManager.get():openWindow("toast", {
										message = var_0_3:translation("ARENA_RECORD_OUT_OF_DATE")
									})
								else
									local var_17_0 = {
										reports = arg_6_0.peakArena:getReports(),
										attackerName = iter_6_1.attacker_name,
										attackerLev = iter_6_1.attacker_lev,
										attackerConquerLev = iter_6_1.attacker_conquer_lev,
										attackerConquerLoopID = iter_6_1.attacker_conquer_loop_id,
										attackerAvatar = iter_6_1.attacker_avatar or xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId],
										attackerAvatarFrame = iter_6_1.attacker_avatar_frame,
										defenderName = iter_6_1.defencer_name,
										defenderLev = iter_6_1.defencer_lev,
										defenderConquerLev = iter_6_1.defencer_conquer_lev,
										defenderConquerLoopID = iter_6_1.defencer_conquer_loop_id,
										defenderAvatar = iter_6_1.defencer_avatar or xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId],
										defenderAvatarFrame = iter_6_1.defencer_avatar_frame,
										win = iter_6_1.win,
										isAttack = iter_6_1.is_attack
									}

									xyd.WindowManager.get():openWindow("peak_arena_report", var_17_0)
								end
							end
						end)
					end
				end)
				arg_6_0.recordList_:addItem(var_6_25)
			end
		elseif arg_6_0.type == xyd.CampaignType.REGION_CASUAL then
			local var_6_38 = {}

			if iter_6_1.player_name then
				local var_6_39 = display.newNode()
				local var_6_40 = arg_6_0.recordList_:newItem()
				local var_6_41 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/record/record_item.csb")
				local var_6_42 = var_6_41:getChildByName("container")
				local var_6_43 = {
					avatar_id = tonumber(iter_6_1.avatar_id),
					avatar_frame_id = iter_6_1.avatar_frame_id
				}

				xyd.setPlayerAvatar(var_6_42:getChildByName("avatar"), var_6_43)

				if iter_6_1.conquer_lev and iter_6_1.conquer_lev > 0 then
					xyd.setConquerLev(iter_6_1.conquer_lev, var_6_42:getChildByName("text_level"), var_6_42:getChildByName("dengjiquan"), nil, nil, nil, nil, iter_6_1.conquer_loop_id)
				else
					var_6_42:getChildByName("text_level"):setString(iter_6_1.player_lev)
				end

				var_6_42:getChildByName("text_player_name"):setString(iter_6_1.player_name)

				if tonumber(iter_6_1.is_win) == 1 then
					var_6_42:getChildByName("win"):setVisible(true)
					var_6_42:getChildByName("lose"):setVisible(false)
				else
					var_6_42:getChildByName("win"):setVisible(false)
					var_6_42:getChildByName("lose"):setVisible(true)
				end

				if iter_6_1.time then
					local var_6_44 = xyd.ServerTime.get():getServerTime() - iter_6_1.time

					var_6_42:getChildByName("text_time"):setString(xyd.secondsToString(var_6_44, {
						short = true,
						toText = true
					}) .. xyd.tables.translation:translation("BEFORE"))
				end

				local var_6_45 = var_6_42:getContentSize()

				var_6_41:setPosition(cc.p(15, 0))
				var_6_41:setContentSize(var_6_45.width + 15, var_6_45.height)
				var_6_39:addChild(var_6_41)
				var_6_39:setContentSize(cc.size(arg_6_0.recordList_.viewRect_.width, var_6_41:getContentSize().height + 5))
				var_6_40:addContent(var_6_39)
				var_6_40:setItemSize(arg_6_0.recordList_.viewRect_.width, var_6_39:getContentSize().height)

				local var_6_46 = var_6_42:getChildByName("share_btn")
				local var_6_47 = var_6_42:getChildByName("replay_btn")

				var_6_42:getChildByName("replay"):setVisible(false)
				var_6_42:getChildByName("select"):setVisible(true)
				var_6_42:getChildByName("data_icon"):setVisible(false)
				var_6_42:getChildByName("data_btn"):setVisible(false)
				var_6_46:addTouchEventListener(function(arg_18_0, arg_18_1)
					if arg_18_1 == ccui.TouchEventType.ended then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_3:translation("REGION_CASUAL_TXT15")
						})
					end
				end)
				var_6_47:addTouchEventListener(function(arg_19_0, arg_19_1)
					if arg_19_1 == ccui.TouchEventType.ended then
						local var_19_0 = {
							record_id = iter_6_1.record_id
						}

						arg_6_0.regionCasualArena:getReports(var_19_0, function(arg_20_0, arg_20_1)
							if arg_20_0 == xyd.error.OK then
								if arg_20_1 == nil or arg_20_1 == {} or #arg_20_1.report_list == 0 then
									if xyd.WindowManager.get():getWindow("toast") ~= nil then
										xyd.WindowManager.get():closeWindow("toast")
									end

									xyd.WindowManager.get():openWindow("toast", {
										message = var_0_3:translation("ARENA_RECORD_OUT_OF_DATE")
									})
								else
									local var_20_0 = {}

									if iter_6_1.B_player_id == arg_6_0.selfPlayer.playerID then
										var_20_0.reports = {}

										for iter_20_0 = 1, #arg_20_1.report_list do
											var_20_0.reports[iter_20_0] = {}
											var_20_0.reports[iter_20_0] = arg_20_1.report_list[iter_20_0].report[1]

											local var_20_1 = var_20_0.reports[iter_20_0]

											if json.decode(var_20_1.content).star > 0 then
												var_20_0.reports[iter_20_0].win = 1
											else
												var_20_0.reports[iter_20_0].win = 0
											end
										end

										var_20_0.attackerName = iter_6_1.player_name
										var_20_0.attackerLev = iter_6_1.player_lev
										var_20_0.attackerAvatar = iter_6_1.avatar_id or xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId]
										var_20_0.attackerAvatarFrame = iter_6_1.avatar_frame_id
										var_20_0.defenderName = arg_6_0.selfPlayer.playerName
										var_20_0.defenderLev = arg_6_0.selfPlayer.lev
										var_20_0.defenderAvatar = arg_6_0.selfPlayer.avatarId or xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId]
										var_20_0.defenderAvatarFrame = arg_6_0.selfPlayer.avatarFrame
										var_20_0.win = iter_6_1.is_win
									else
										var_20_0.reports = {}

										for iter_20_1 = 1, #arg_20_1.report_list do
											var_20_0.reports[iter_20_1] = {}
											var_20_0.reports[iter_20_1] = arg_20_1.report_list[iter_20_1].report[1]

											local var_20_2 = var_20_0.reports[iter_20_1]

											if json.decode(var_20_2.content).star > 0 then
												var_20_0.reports[iter_20_1].win = 1
											else
												var_20_0.reports[iter_20_1].win = 0
											end
										end

										var_20_0.defenderName = iter_6_1.player_name
										var_20_0.defenderLev = iter_6_1.player_lev
										var_20_0.defenderAvatar = iter_6_1.avatar_id or xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId]
										var_20_0.defenderAvatarFrame = iter_6_1.avatar_frame_id
										var_20_0.attackerName = arg_6_0.selfPlayer.playerName
										var_20_0.attackerLev = arg_6_0.selfPlayer.lev
										var_20_0.attackerAvatar = arg_6_0.selfPlayer.avatarId or xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId]
										var_20_0.attackerAvatarFrame = arg_6_0.selfPlayer.avatarFrame
										var_20_0.win = 1 - iter_6_1.is_win
									end

									var_20_0.is_casual = true

									xyd.WindowManager.get():openWindow("region_casual_report", var_20_0)
								end
							end
						end)
					end
				end)
				arg_6_0.recordList_:addItem(var_6_40)
			end
		end
	end

	arg_6_0.recordList_:reload()
end

function var_0_0.createPeakItem(arg_21_0, arg_21_1)
	local var_21_0 = arg_21_1.attack_player_info
	local var_21_1 = arg_21_1.defense_player_info
	local var_21_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/record/record_item.csb")
	local var_21_3 = var_21_2:getChildByName("container")
	local var_21_4 = arg_21_1.attack_player_info.player_id == arg_21_0.selfPlayer.playerID
	local var_21_5 = var_21_4 and var_21_1 or var_21_0

	xyd.setPlayerAvatar(var_21_3:getChildByName("avatar"), {
		avatar_id = var_21_5.avatar_id,
		avatar_frame_id = var_21_5.avatar_frame_id
	})

	local var_21_6 = var_21_5.conquer_lev

	if var_21_6 and var_21_6 > 0 then
		xyd.setConquerLev(var_21_6, var_21_3:getChildByName("text_level"), var_21_3:getChildByName("dengjiquan"), nil, nil, nil, nil, var_21_5.conquer_loop_id)
	else
		var_21_3:getChildByName("text_level"):setString(var_21_5.lev)
	end

	var_21_3:getChildByName("text_player_name"):setString(var_21_5.player_name)

	local var_21_7

	if tonumber(arg_21_1.is_win) > 0 then
		var_21_7 = var_21_3:getChildByName("win")

		var_21_3:getChildByName("lose"):setVisible(false)
	else
		var_21_7 = var_21_3:getChildByName("lose")

		var_21_3:getChildByName("win"):setVisible(false)
	end

	var_21_7:setVisible(true)

	if arg_21_1.mode == 2 then
		local var_21_8 = cc.p(var_21_7:getPosition())

		var_21_7:setPosition(var_21_8.x, var_21_8.y + 20)
		var_21_3:getChildByName("mode_name"):setString(var_0_3:translation("LEGEND_PROMO_TEXT"))
	end

	if arg_21_1.time then
		local var_21_9 = xyd.ServerTime.get():getServerTime() - arg_21_1.time

		var_21_3:getChildByName("text_time"):setString(xyd.secondsToString(var_21_9, {
			short = true,
			toText = true
		}) .. xyd.tables.translation:translation("BEFORE"))
	end

	local var_21_10 = var_21_3:getContentSize()

	var_21_2:setPosition(cc.p(15, 0))
	var_21_2:setContentSize(var_21_10.width + 15, var_21_10.height)
	var_21_3:getChildByName("replay"):setVisible(false)
	var_21_3:getChildByName("select"):setVisible(true)
	var_21_3:getChildByName("data_icon"):setVisible(false)
	var_21_3:getChildByName("data_btn"):setVisible(false)
	var_21_3:getChildByName("share_btn"):addTouchEventListener(function(arg_22_0, arg_22_1)
		if arg_22_1 == ccui.TouchEventType.ended then
			local var_22_0 = {
				enemy_name = var_21_5.player_name,
				player_id = arg_21_0.selfPlayer.playerID,
				player_name = arg_21_0.selfPlayer.playerName,
				time = arg_21_1.time,
				isAttack = var_21_4,
				record_id = arg_21_1.record_id,
				attackInfo = var_21_0,
				defendInfo = var_21_1,
				isWin = arg_21_1.is_win
			}

			xyd.WindowManager.get():openWindow("record_share_menu", {
				message = json.encode(var_22_0)
			})
		end
	end)
	var_21_3:getChildByName("replay_btn"):addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.ended then
			arg_21_0.peakArena:getPeakRecordsDetail({
				record_id = arg_21_1.record_id
			}, function(arg_24_0)
				local var_24_0 = {
					reportKeys = arg_24_0.report_keys,
					isWin = arg_21_1.is_win,
					wins = arg_24_0.wins,
					attackInfo = arg_21_1.attack_player_info,
					defendInfo = arg_21_1.defense_player_info,
					attackTeam = arg_21_0.peakArena:formatTeams(arg_24_0.attack_formations, arg_21_1.attack_player_info.conquer_lev),
					defendTeam = arg_21_0.peakArena:formatTeams(arg_24_0.defense_formations, arg_21_1.defense_player_info.conquer_lev)
				}

				xyd.WindowManager.get():openWindow("peak_arena_report", var_24_0)
			end)
		end
	end)

	return var_21_2
end

function var_0_0.replayRecord(arg_25_0, arg_25_1, arg_25_2)
	if arg_25_1 == nil or next(arg_25_1) == nil then
		if xyd.WindowManager.get():getWindow("toast") ~= nil then
			xyd.WindowManager.get():closeWindow("toast")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_3:translation("ARENA_RECORD_OUT_OF_DATE")
		})

		return
	end

	local var_25_0 = {}
	local var_25_1 = json.decode(arg_25_1[1].content)

	var_25_0.herosA = {}
	var_25_0.herosB = {}
	var_25_0.summonMonsters = {}
	var_25_0.campaignType = xyd.CampaignType.ARENA
	var_25_0.battleID = xyd.MapBattleID.ARENA
	var_25_0.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_25_1

	local var_25_2 = {}
	local var_25_3 = {}

	for iter_25_0, iter_25_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_25_4 = string.sub(iter_25_0, 1, 1)
		local var_25_5 = tonumber(string.sub(iter_25_0, 3, 3))

		if var_25_4 == "A" and tonumber(iter_25_1.summon_type) == xyd.summonMonsterType.None then
			local var_25_6 = var_0_1.new()

			var_25_6:populate(iter_25_1.hero)
			var_25_6:setReportData(iter_25_1)

			if arg_25_2 then
				var_25_6.harms = iter_25_1.harms
				var_25_6.bear_harms = iter_25_1.bear_harms
				var_25_6.willDie = (iter_25_1.die_count or 0) ~= -1
			end

			var_25_0.herosA[var_25_5] = var_25_6
		elseif var_25_4 == "A" and tonumber(iter_25_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_25_7 = var_0_2.new()

			var_25_7:populate(iter_25_1.hero)
			var_25_7:setReportData(iter_25_1)

			if arg_25_2 then
				var_25_7.harms = iter_25_1.harms
				var_25_7.bear_harms = iter_25_1.bear_harms
				var_25_7.willDie = (iter_25_1.die_count or 0) ~= -1
				var_25_0.petA = {
					var_25_7
				}
			else
				var_25_0.petsA = {
					var_25_7
				}
			end
		elseif var_25_4 == "B" and tonumber(iter_25_1.summon_type) == xyd.summonMonsterType.None then
			local var_25_8 = var_0_1.new()

			var_25_8:populate(iter_25_1.hero)
			var_25_8:setReportData(iter_25_1)

			if arg_25_2 then
				var_25_8.harms = iter_25_1.harms
				var_25_8.bear_harms = iter_25_1.bear_harms
				var_25_8.willDie = (iter_25_1.die_count or 0) ~= -1
				var_25_0.herosB[var_25_5] = var_25_8
			else
				var_25_2[var_25_5] = var_25_8
			end
		elseif var_25_4 == "B" and tonumber(iter_25_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_25_9 = var_0_2.new()

			var_25_9:populate(iter_25_1.hero)
			var_25_9:setReportData(iter_25_1)

			if arg_25_2 then
				var_25_9.harms = iter_25_1.harms
				var_25_9.bear_harms = iter_25_1.bear_harms
				var_25_9.willDie = (iter_25_1.die_count or 0) ~= -1
				var_25_0.petB = {
					var_25_9
				}
			else
				var_25_0.petsB = {
					var_25_9
				}
			end
		elseif tonumber(iter_25_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_25_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_25_10 = var_0_1.new()

			var_25_10:populate(iter_25_1.hero)
			var_25_10:setReportData(iter_25_1)

			var_25_3[iter_25_0] = var_25_10
		end
	end

	if arg_25_2 then
		collectgarbage("collect")

		var_25_0.isBeforeBattle = true

		xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, var_25_0)
	else
		var_25_0.herosB = {
			var_25_2
		}
		var_25_0.summonMonsters = var_25_3
		var_25_0.reportStar = tonumber(var_25_1.star)

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = xyd.WindowName.arenaRecordWnd,
				status = {
					mytype = arg_25_0.type,
					records = arg_25_0.records,
					reports = arg_25_0.report
				}
			}
		})
		xyd.WindowManager.get():retainHistory()
		xyd.pushBattleScene(var_25_0)
	end
end

function var_0_0.scrollListener(arg_26_0, arg_26_1)
	if arg_26_1.name == "began" then
		arg_26_0.scrollViewMoved_ = false
		arg_26_0.prevX_ = arg_26_1.x
	elseif arg_26_1.name == "moved" and 1 <= math.abs(arg_26_1.x - arg_26_0.prevX_) then
		arg_26_0.scrollViewMoved_ = true
	end
end

function var_0_0.willClose(arg_27_0)
	return
end

function var_0_0.didClose(arg_28_0)
	return
end

return var_0_0
