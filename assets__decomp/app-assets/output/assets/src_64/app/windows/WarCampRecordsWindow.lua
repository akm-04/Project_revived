local var_0_0 = class("WarCampRecordsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.warCampCampaign
local var_0_3 = xyd.tables.warCamp
local var_0_4 = import("app.model.Hero")
local var_0_5 = import("app.model.Pet")
local var_0_6 = 60

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.warCamp_ = xyd.ModelManager.get():loadModel(xyd.ModelType.WAR_CAMP)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.reports = arg_1_0.warCamp_:getRecordsList()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initListview()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0.list:reload()
end

function var_0_0.initListview(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("list")
	local var_4_1 = var_4_0:getContentSize().width
	local var_4_2 = var_4_0:getContentSize().height

	arg_4_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_1, var_4_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_4_0)

	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.delegate))
end

function var_0_0.delegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = #arg_5_0.reports

	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return var_5_0
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_1
		local var_5_2
		local var_5_3
		local var_5_4 = arg_5_0.list:dequeueItem()

		if not var_5_4 then
			var_5_4 = arg_5_0.list:newItem()
		else
			var_5_4:removeAllChildren()
		end

		local var_5_5 = display.newNode()

		var_5_5:setTouchSwallowEnabled(false)

		local var_5_6 = display.newNode()

		arg_5_0:initReportItem(var_5_6, arg_5_3)

		local var_5_7 = var_5_6:getContentSize().width
		local var_5_8 = var_5_6:getContentSize().height

		var_5_5:addChild(var_5_6)
		var_5_5:setContentSize(cc.size(arg_5_0.list.viewRect_.width, var_5_6:getContentSize().height + 5))
		var_5_4:setItemSize(arg_5_0.list.viewRect_.width, var_5_6:getContentSize().height + 5)
		var_5_4:addContent(var_5_5)

		return var_5_4
	end
end

function var_0_0.initReportItem(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_0.reports[arg_6_2]
	local var_6_1 = var_6_0.enemy_info
	local var_6_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/war_camp/records/record_item.csb")

	var_6_2:addTo(arg_6_1)

	local var_6_3 = var_6_2:getChildByName("container")
	local var_6_4 = var_6_3:getContentSize()

	arg_6_1:setContentSize(var_6_4)
	var_6_3:getChildByName("text_name"):setString(var_6_1.player_name)

	if var_6_1.conquer_lev and var_6_1.conquer_lev > 0 then
		xyd.setConquerLev(var_6_1.conquer_lev, var_6_3:getChildByName("text_lev"), var_6_3:getChildByName("level_bg"), nil, nil, nil, nil, var_6_1.conquer_loop_id)
	else
		var_6_3:getChildByName("text_lev"):setString(var_6_1.lev)
	end

	local var_6_5 = xyd.getPlayerRegion(var_6_1.player_id)

	var_6_3:getChildByName("text_region"):setString("S" .. var_6_5)

	var_6_1.playerInfo = var_6_1

	xyd.setPlayerAvatar(var_6_3:getChildByName("avatar"), var_6_1)

	local var_6_6 = xyd.ServerTime.get():getServerTime() - var_6_0.time

	var_6_3:getChildByName("text_time"):setString(xyd.secondsToString(var_6_6, {
		short = true,
		toText = true
	}) .. xyd.tables.translation:translation("BEFORE"))
	var_6_3:getChildByName("btn_record"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			arg_6_0:getReport(var_6_0.battle_id, true)
		end
	end)
	var_6_3:getChildByName("btn_replay"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			arg_6_0:getReport(var_6_0.battle_id, false, var_6_0.map_id)
		end
	end)
	var_6_3:getChildByName("btn_share"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			local var_9_0 = {}
			local var_9_1 = 0

			if arg_6_0.selfPlayer.playerID == var_6_0.attack_id then
				var_9_1 = 1
			end

			var_9_0.enemy_name = var_6_1.player_name
			var_9_0.player_id = arg_6_0.selfPlayer.playerID
			var_9_0.player_name = arg_6_0.selfPlayer.playerName
			var_9_0.time = var_6_0.time
			var_9_0.is_attack = var_9_1
			var_9_0.id = var_6_0.battle_id

			local var_9_2 = json.encode(var_9_0)

			xyd.WindowManager.get():openWindow("record_share_menu", {
				message = var_9_2
			})
		end
	end)

	local var_6_7 = false
	local var_6_8 = 0

	if arg_6_0.selfPlayer.playerID == var_6_0.attack_id then
		var_6_8 = var_6_0.attack_kill

		var_6_3:getChildByName("shield"):setVisible(false)

		if var_6_0.star > 0 then
			var_6_7 = true
		end
	else
		var_6_8 = var_6_0.defend_kill

		var_6_3:getChildByName("sword"):setVisible(false)

		if var_6_0.star <= 0 then
			var_6_7 = true
		end
	end

	local var_6_9 = var_6_8 * xyd.tables.misc.campWarHeroHonor
	local var_6_10 = 1

	for iter_6_0, iter_6_1 in pairs(xyd.tables.misc.warCampSkinItems) do
		if arg_6_0.selfPlayer:hasSkin(iter_6_1) then
			var_6_10 = var_6_10 + xyd.tables.misc.warCampSkinItemRate
		end
	end

	local var_6_11 = math.floor(var_6_9 * var_6_10)

	var_6_3:getChildByName("text_score"):setString(string.format(var_0_1:translation("WAR_CAMP_RECORD_TIPS_3"), var_6_11))
	var_6_3:getChildByName("win"):setVisible(var_6_7)
	var_6_3:getChildByName("lose"):setVisible(not var_6_7)
end

function var_0_0.getReport(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = {
		id = arg_10_1
	}

	arg_10_0.warCamp_:getReport(var_10_0, function(arg_11_0, arg_11_1)
		if arg_11_0 == xyd.error.OK then
			arg_10_0:replayRecord(arg_11_1.result, arg_10_2, arg_10_3)
		end
	end)
end

function var_0_0.replayRecord(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	if arg_12_1 == nil or next(arg_12_1) == nil then
		return
	end

	local var_12_0 = {}
	local var_12_1 = json.decode(arg_12_1[1].content)
	local var_12_2 = json.decode(var_12_1.formation)
	local var_12_3 = json.decode(var_12_1.report)

	local function var_12_4(arg_13_0)
		local var_13_0 = {}

		for iter_13_0 = 1, #var_12_2 do
			if arg_13_0:getHeroID() == var_12_2[iter_13_0].partner_id then
				var_13_0 = var_12_2[iter_13_0].hero_status

				break
			end
		end

		return var_13_0
	end

	var_12_0.herosA = {}
	var_12_0.herosB = {}
	var_12_0.summonMonsters = {}
	var_12_0.campaignType = xyd.CampaignType.WAR_CAMP_ENEMY

	if arg_12_3 then
		local var_12_5 = var_0_3:bossId(arg_12_3)

		var_12_0.battleID = var_0_2:fightId(var_12_5)
	else
		var_12_0.battleID = xyd.MapBattleID.ARENA
	end

	var_12_0.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_12_3

	local var_12_6 = {}
	local var_12_7 = {}

	for iter_12_0, iter_12_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_12_8 = string.sub(iter_12_0, 1, 1)
		local var_12_9 = tonumber(string.sub(iter_12_0, 3, 3))

		if var_12_8 == "A" and tonumber(iter_12_1.summon_type) == xyd.summonMonsterType.None then
			local var_12_10 = var_0_4.new()

			var_12_10:populate(iter_12_1.hero)
			var_12_10:setReportData(iter_12_1)

			var_12_10.healthStatus = var_12_4(var_12_10)

			if arg_12_2 then
				var_12_10.harms = iter_12_1.harms
				var_12_10.willDie = (iter_12_1.die_count or 0) ~= -1
			end

			var_12_0.herosA[var_12_9] = var_12_10
		elseif var_12_8 == "A" and tonumber(iter_12_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_12_11 = var_0_5.new()

			var_12_11:populate(iter_12_1.hero)
			var_12_11:setReportData(iter_12_1)

			if arg_12_2 then
				var_12_11.harms = iter_12_1.harms
				var_12_11.willDie = (iter_12_1.die_count or 0) ~= -1
				var_12_0.petA = {
					var_12_11
				}
			else
				var_12_0.petsA = {
					var_12_11
				}
			end
		elseif var_12_8 == "B" and tonumber(iter_12_1.summon_type) == xyd.summonMonsterType.None then
			local var_12_12 = var_0_4.new()

			var_12_12:populate(iter_12_1.hero)
			var_12_12:setReportData(iter_12_1)

			if arg_12_2 then
				var_12_12.harms = iter_12_1.harms
				var_12_12.willDie = (iter_12_1.die_count or 0) ~= -1
				var_12_0.herosB[var_12_9] = var_12_12
			else
				var_12_6[var_12_9] = var_12_12
			end
		elseif var_12_8 == "B" and tonumber(iter_12_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_12_13 = var_0_5.new()

			var_12_13:populate(iter_12_1.hero)
			var_12_13:setReportData(iter_12_1)

			if arg_12_2 then
				var_12_13.harms = iter_12_1.harms
				var_12_13.willDie = (iter_12_1.die_count or 0) ~= -1
				var_12_0.petB = {
					var_12_13
				}
			else
				var_12_0.petsB = {
					var_12_13
				}
			end
		elseif var_12_8 == "C" then
			local var_12_14 = var_0_4.new()

			var_12_14:populate(iter_12_1.hero)
			var_12_14:setReportData(iter_12_1)

			if not arg_12_2 then
				sceneFighter = var_12_14
			end
		elseif tonumber(iter_12_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_12_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_12_15 = var_0_4.new()

			var_12_15:populate(iter_12_1.hero)
			var_12_15:setReportData(iter_12_1)

			var_12_7[iter_12_0] = var_12_15
		end
	end

	if arg_12_2 then
		collectgarbage("collect")

		var_12_0.isBeforeBattle = true

		xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, var_12_0)
	else
		var_12_0.herosB = {
			var_12_6
		}
		var_12_0.sceneFighter = sceneFighter
		var_12_0.summonMonsters = var_12_7
		var_12_0.reportStar = tonumber(var_12_3.star)

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = "war_camp_map",
				status = {
					is_record = true
				}
			}
		})
		xyd.WindowManager.get():retainHistory()
		xyd.pushBattleScene(var_12_0)
	end
end

return var_0_0
