local var_0_0 = class("ChampionsLeagueRecordWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = xyd.tables.translation
local var_0_4 = {
	title = var_0_3:translation("PERSON_HIDE_MESSAGE_3")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.type = arg_1_2.type or xyd.CampaignType.ARENA
	arg_1_0.records = arg_1_2.records
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.report = arg_1_2.reports or {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_name"):setString(var_0_4.title)

	local var_4_0 = arg_4_0:nodeByName("container"):getContentSize()
	local var_4_1 = display.newScale9Sprite("windows/common/panel/bg_mid_bottom_red.png", 0, 0, cc.size(var_4_0.width, var_4_0.height), cc.rect(115, 158, 20, 20))

	var_4_1:setAnchorPoint(cc.p(0, 0))
	var_4_1:addTo(arg_4_0:nodeByName("container"), -1)

	arg_4_0.container = arg_4_0:nodeByName("inner")

	local var_4_2 = arg_4_0.container:getContentSize()

	arg_4_0.recordList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_4_2.width, var_4_2.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.container):onScroll(handler(arg_4_0, arg_4_0.scrollListener)):setTouchType(true):pos(0, 0)

	arg_4_0:updateRecordList()
end

function var_0_0.updateRecordList(arg_5_0)
	if not arg_5_0.records or not next(arg_5_0.records) then
		return
	end

	arg_5_0.recordList_:removeAllItems()

	local var_5_0 = {}

	for iter_5_0, iter_5_1 in pairs(arg_5_0.records) do
		local function var_5_1(arg_6_0, arg_6_1, arg_6_2)
			local var_6_0 = {}
			local var_6_1

			if arg_6_0 and next(arg_6_0) then
				for iter_6_0, iter_6_1 in pairs(arg_6_0) do
					local var_6_2 = iter_6_1

					if arg_6_2 == true then
						var_6_2.table_id = iter_6_1.partner_id
						var_6_2.partner_id = iter_6_0
					end

					if type(var_6_2.equips) == "string" then
						var_6_2.equips = xyd.splitToNumber(var_6_2.equips, "|")
					end

					if bookshelfLev and bookshelfLev > 0 then
						var_6_2.book_shelf_lev = bookshelfLev
					else
						var_6_2.book_shelf_lev = 0
					end

					local var_6_3 = import("app.model.Hero").new()

					var_6_3:populate(var_6_2)
					table.insert(var_6_0, var_6_3)
				end
			end

			if arg_6_1 then
				local var_6_4 = arg_6_1

				if type(var_6_4.equips) == "string" then
					var_6_4.equips = xyd.splitToNumber(var_6_4.equips, "|")
				end

				local var_6_5 = import("app.model.Pet").new()

				var_6_5:populate(var_6_4)

				var_6_1 = var_6_5
			end

			return var_6_0, var_6_1
		end

		if arg_5_0.type == xyd.CampaignType.ARENA and iter_5_1.attack_name then
			local var_5_2 = display.newNode()
			local var_5_3 = arg_5_0.recordList_:newItem()
			local var_5_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/battle_record/record_item.csb")
			local var_5_5 = var_5_4:getChildByName("container")

			if tonumber(iter_5_1.is_attack) == 1 and tonumber(iter_5_1.defend_avatar) ~= 0 then
				local var_5_6 = {
					avatar_id = tonumber(iter_5_1.defend_avatar),
					avatar_frame_id = iter_5_1.defend_avatar_frame
				}

				xyd.setPlayerAvatar(var_5_5:getChildByName("avatar"), var_5_6)

				if iter_5_1.defend_conquer_lev and iter_5_1.defend_conquer_lev > 0 then
					xyd.setConquerLev(iter_5_1.defend_conquer_lev, var_5_5:getChildByName("text_level"), var_5_5:getChildByName("dengjiquan"), nil, nil, nil, nil, iter_5_1.defend_conquer_loop_id)
				else
					var_5_5:getChildByName("text_level"):setString(iter_5_1.defend_lev)
				end

				var_5_5:getChildByName("text_player_name"):setString(iter_5_1.defend_name)
			elseif tonumber(iter_5_1.is_attack) == 1 and tonumber(iter_5_1.defend_avatar) == 0 then
				local var_5_7 = {
					avatar_id = xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId],
					avatar_frame_id = iter_5_1.defend_avatar_frame
				}

				xyd.setPlayerAvatar(var_5_5:getChildByName("avatar"), var_5_7)

				if iter_5_1.defend_conquer_lev and iter_5_1.defend_conquer_lev > 0 then
					xyd.setConquerLev(iter_5_1.defend_conquer_lev, var_5_5:getChildByName("text_level"), var_5_5:getChildByName("dengjiquan"), nil, nil, nil, nil, iter_5_1.defend_conquer_loop_id)
				else
					var_5_5:getChildByName("text_level"):setString(iter_5_1.defend_lev)
				end

				var_5_5:getChildByName("text_player_name"):setString(iter_5_1.defend_name)
			else
				local var_5_8 = {
					avatar_id = tonumber(iter_5_1.attack_avatar),
					avatar_frame_id = iter_5_1.attack_avatar_frame
				}

				xyd.setPlayerAvatar(var_5_5:getChildByName("avatar"), var_5_8)

				if iter_5_1.attack_conquer_lev and iter_5_1.attack_conquer_lev > 0 then
					xyd.setConquerLev(iter_5_1.attack_conquer_lev, var_5_5:getChildByName("text_level"), var_5_5:getChildByName("dengjiquan"), nil, nil, nil, nil, iter_5_1.attack_conquer_loop_id)
				else
					var_5_5:getChildByName("text_level"):setString(iter_5_1.attack_lev)
				end

				var_5_5:getChildByName("text_player_name"):setString(iter_5_1.attack_name)
			end

			if iter_5_1.time then
				local var_5_9 = xyd.ServerTime.get():getServerTime() - iter_5_1.time

				var_5_5:getChildByName("text_time"):setString(xyd.secondsToString(var_5_9, {
					short = true,
					toText = true
				}) .. xyd.tables.translation:translation("BEFORE"))
			end

			local var_5_10 = var_5_5:getChildByName("lose"):getChildByName("lose_text")
			local var_5_11 = var_5_5:getChildByName("win"):getChildByName("win_text")

			var_5_10:enableOutline(cc.c4b(147, 24, 24, 255), 2)
			var_5_11:enableOutline(cc.c4b(19, 112, 29, 255), 2)

			if iter_5_1.win == 0 then
				var_5_5:getChildByName("win"):setVisible(false)
				var_5_5:getChildByName("lose"):setVisible(true)

				local var_5_12 = math.ceil(-iter_5_1.change_point)

				var_5_10:setString("-" .. var_5_12)
			else
				var_5_5:getChildByName("win"):setVisible(true)
				var_5_5:getChildByName("lose"):setVisible(false)

				local var_5_13 = math.ceil(iter_5_1.change_point)

				var_5_11:setString("+" .. var_5_13)
			end

			local var_5_14 = var_5_5:getContentSize()

			var_5_4:setPosition(cc.p(0, 0))
			var_5_4:setContentSize(var_5_14.width, var_5_14.height)
			var_5_2:addChild(var_5_4)
			var_5_2:setContentSize(cc.size(arg_5_0.recordList_.viewRect_.width, var_5_4:getContentSize().height + 5))
			var_5_3:addContent(var_5_2)
			var_5_3:setItemSize(arg_5_0.recordList_.viewRect_.width, var_5_2:getContentSize().height)

			local var_5_15 = var_5_5:getChildByName("share_btn")
			local var_5_16 = var_5_5:getChildByName("replay_btn")

			var_5_5:getChildByName("replay"):setVisible(true)
			var_5_5:getChildByName("select"):setVisible(false)
			var_5_5:getChildByName("share"):setVisible(false)
			var_5_15:setVisible(false)
			var_5_15:addTouchEventListener(function(arg_7_0, arg_7_1)
				if arg_7_1 == ccui.TouchEventType.began then
					var_5_15:setScale(0.95)
				elseif arg_7_1 == ccui.TouchEventType.ended then
					var_5_15:setScale(1)

					local var_7_0 = {}

					if tonumber(iter_5_1.is_attack) == 1 then
						var_7_0.enemy_name = iter_5_1.defend_name
					else
						var_7_0.enemy_name = iter_5_1.attack_name
					end

					var_7_0.player_id = arg_5_0.selfPlayer.playerID
					var_7_0.player_name = arg_5_0.selfPlayer.playerName
					var_7_0.time = iter_5_1.time
					var_7_0.is_attack = iter_5_1.is_attack
					var_7_0.id = iter_5_1.id

					local var_7_1 = json.encode(var_7_0)

					xyd.WindowManager.get():openWindow("record_share_menu", {
						message = var_7_1
					})
				end
			end)

			local function var_5_17(arg_8_0)
				if arg_5_0.report[tonumber(iter_5_1.id)] then
					arg_5_0:replayRecord(arg_5_0.report[tonumber(iter_5_1.id)], arg_8_0)
				else
					local var_8_0 = {
						id = iter_5_1.id
					}
					local var_8_1 = xyd.mid.CHAMPIONS_GET_FIGHT_RECORD

					xyd.Backend.get():request(var_8_1, var_8_0, function(arg_9_0, arg_9_1)
						if arg_9_0 == xyd.error.OK then
							if arg_9_1 == nil or arg_9_1 == {} then
								if xyd.WindowManager.get():getWindow("toast") ~= nil then
									xyd.WindowManager.get():closeWindow("toast")
								end

								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_3:translation("ARENA_RECORD_OUT_OF_DATE")
								})
							else
								table.insert(arg_5_0.report, iter_5_1.id, arg_9_1.report)
								arg_5_0:replayRecord(arg_9_1.report, arg_8_0)
							end
						end
					end)
				end
			end

			var_5_16:addTouchEventListener(function(arg_10_0, arg_10_1)
				if arg_10_1 == ccui.TouchEventType.began then
					var_5_16:setScale(0.95)
				elseif arg_10_1 == ccui.TouchEventType.ended then
					var_5_16:setScale(1)
					var_5_17()
				end
			end)

			local var_5_18 = var_5_5:getChildByName("data_btn")

			var_5_18:addTouchEventListener(function(arg_11_0, arg_11_1)
				if arg_11_1 == ccui.TouchEventType.began then
					var_5_18:setScale(0.95)
				elseif arg_11_1 == ccui.TouchEventType.ended then
					var_5_18:setScale(1)
					var_5_17(true)
				end
			end)
			arg_5_0.recordList_:addItem(var_5_3)
		end
	end

	arg_5_0.recordList_:reload()
end

function var_0_0.replayRecord(arg_12_0, arg_12_1, arg_12_2)
	if arg_12_1 == nil or next(arg_12_1) == nil then
		if xyd.WindowManager.get():getWindow("toast") ~= nil then
			xyd.WindowManager.get():closeWindow("toast")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_3:translation("ARENA_RECORD_OUT_OF_DATE")
		})

		return
	end

	local var_12_0 = {}
	local var_12_1 = json.decode(arg_12_1[1].content)

	var_12_0.herosA = {}
	var_12_0.herosB = {}
	var_12_0.summonMonsters = {}
	var_12_0.campaignType = xyd.CampaignType.ARENA
	var_12_0.battleID = xyd.MapBattleID.ARENA
	var_12_0.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_12_1

	local var_12_2 = {}
	local var_12_3 = {}

	for iter_12_0, iter_12_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_12_4 = string.sub(iter_12_0, 1, 1)
		local var_12_5 = tonumber(string.sub(iter_12_0, 3, 3))

		if var_12_4 == "A" and tonumber(iter_12_1.summon_type) == xyd.summonMonsterType.None then
			local var_12_6 = var_0_1.new()

			var_12_6:populate(iter_12_1.hero)
			var_12_6:setReportData(iter_12_1)

			if arg_12_2 then
				var_12_6.harms = iter_12_1.harms
				var_12_6.bear_harms = iter_12_1.bear_harms
				var_12_6.willDie = (iter_12_1.die_count or 0) ~= -1
			end

			var_12_0.herosA[var_12_5] = var_12_6
		elseif var_12_4 == "A" and tonumber(iter_12_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_12_7 = var_0_2.new()

			var_12_7:populate(iter_12_1.hero)
			var_12_7:setReportData(iter_12_1)

			if arg_12_2 then
				var_12_7.harms = iter_12_1.harms
				var_12_7.bear_harms = iter_12_1.bear_harms
				var_12_7.willDie = (iter_12_1.die_count or 0) ~= -1
				var_12_0.petA = {
					var_12_7
				}
			else
				var_12_0.petsA = {
					var_12_7
				}
			end
		elseif var_12_4 == "B" and tonumber(iter_12_1.summon_type) == xyd.summonMonsterType.None then
			local var_12_8 = var_0_1.new()

			var_12_8:populate(iter_12_1.hero)
			var_12_8:setReportData(iter_12_1)

			if arg_12_2 then
				var_12_8.harms = iter_12_1.harms
				var_12_8.bear_harms = iter_12_1.bear_harms
				var_12_8.willDie = (iter_12_1.die_count or 0) ~= -1
				var_12_0.herosB[var_12_5] = var_12_8
			else
				var_12_2[var_12_5] = var_12_8
			end
		elseif var_12_4 == "B" and tonumber(iter_12_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_12_9 = var_0_2.new()

			var_12_9:populate(iter_12_1.hero)
			var_12_9:setReportData(iter_12_1)

			if arg_12_2 then
				var_12_9.harms = iter_12_1.harms
				var_12_9.bear_harms = iter_12_1.bear_harms
				var_12_9.willDie = (iter_12_1.die_count or 0) ~= -1
				var_12_0.petB = {
					var_12_9
				}
			else
				var_12_0.petsB = {
					var_12_9
				}
			end
		elseif tonumber(iter_12_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_12_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_12_10 = var_0_1.new()

			var_12_10:populate(iter_12_1.hero)
			var_12_10:setReportData(iter_12_1)

			var_12_3[iter_12_0] = var_12_10
		end
	end

	if arg_12_2 then
		collectgarbage("collect")

		var_12_0.isBeforeBattle = true

		xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, var_12_0)
	else
		var_12_0.herosB = {
			var_12_2
		}
		var_12_0.summonMonsters = var_12_3
		var_12_0.reportStar = tonumber(var_12_1.star)

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = "champions_league"
			}
		})
		xyd.WindowManager.get():retainHistory()
		xyd.pushBattleScene(var_12_0)
	end
end

function var_0_0.scrollListener(arg_13_0, arg_13_1)
	if arg_13_1.name == "began" then
		arg_13_0.scrollViewMoved_ = false
		arg_13_0.prevX_ = arg_13_1.x
	elseif arg_13_1.name == "moved" and 1 <= math.abs(arg_13_1.x - arg_13_0.prevX_) then
		arg_13_0.scrollViewMoved_ = true
	end
end

function var_0_0.willClose(arg_14_0)
	return
end

function var_0_0.didClose(arg_15_0)
	return
end

return var_0_0
