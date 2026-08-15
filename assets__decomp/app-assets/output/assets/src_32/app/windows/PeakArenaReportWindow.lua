local var_0_0 = class("PeakArenaReportWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2
	arg_1_0.reportKeys = arg_1_2.reportKeys or {}
	arg_1_0.reports = {}
	arg_1_0.isWin = arg_1_2.isWin
	arg_1_0.wins = arg_1_2.wins
	arg_1_0.attackInfo = arg_1_2.attackInfo or {}
	arg_1_0.defendInfo = arg_1_2.defendInfo or {}
	arg_1_0.attackTeam = arg_1_2.attackTeam
	arg_1_0.defendTeam = arg_1_2.defendTeam
	arg_1_0.oldScore = arg_1_2.oldScore
	arg_1_0.isCasual = arg_1_2.is_casual
	arg_1_0.withWin = arg_1_2.withWin
	arg_1_0.awards = arg_1_2.awards
	arg_1_0.peakArena = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.isAttack = arg_1_2.isAttack or arg_1_0.attackInfo.player_id == arg_1_0.selfPlayer.playerID
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.reportNum = #arg_2_0.reports

	local var_2_0 = arg_2_0:nodeByName("list")
	local var_2_1 = var_2_0:getContentSize()

	arg_2_0.reportList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_0)

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.setLev(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6)
	if arg_4_1 and arg_4_1 > 0 then
		xyd.setConquerLev(arg_4_1, arg_4_3, arg_4_4, nil, nil, nil, "conquerLev" .. arg_4_5, arg_4_6)
	else
		arg_4_3:setString(arg_4_2)
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("txt_title"):setString(var_0_4:translation("FIGHT_RECORD"))

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.reportKeys) do
		local var_5_0 = display.newNode()
		local var_5_1 = arg_5_0.reportList:newItem()
		local var_5_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena/peak_report_item.csb")
		local var_5_3 = var_5_2:getChildByName("container")
		local var_5_4 = var_5_3:getChildByName("left_container")
		local var_5_5 = var_5_3:getChildByName("right_container")
		local var_5_6 = var_5_4:getChildByName("bg_failure"):getChildByName("txt_failure")
		local var_5_7 = var_5_4:getChildByName("bg_success"):getChildByName("txt_success")
		local var_5_8 = var_5_5:getChildByName("bg_failure"):getChildByName("txt_failure")
		local var_5_9 = var_5_5:getChildByName("bg_success"):getChildByName("txt_success")

		var_5_6:setString(var_0_4:translation("TOP_PEAKARENAREPORTWINDOW_TEXT2"))
		var_5_6:enableOutline(cc.c4b(147, 24, 24, 255), 2)
		var_5_7:setString(var_0_4:translation("TOP_PEAKARENAREPORTWINDOW_TEXT1"))
		var_5_7:enableOutline(cc.c4b(19, 112, 29, 255), 2)
		var_5_8:setString(var_0_4:translation("TOP_PEAKARENAREPORTWINDOW_TEXT2"))
		var_5_8:enableOutline(cc.c4b(147, 24, 24, 255), 2)
		var_5_9:setString(var_0_4:translation("TOP_PEAKARENAREPORTWINDOW_TEXT1"))
		var_5_9:enableOutline(cc.c4b(19, 112, 29, 255), 2)
		var_5_2:setAnchorPoint(cc.p(0, 0))
		var_5_2:setPosition(0, 0)
		var_5_2:addTo(var_5_0)
		var_5_4:getChildByName("bg_name"):getChildByName("txt_name"):setString(arg_5_0.attackInfo.player_name)
		var_5_5:getChildByName("bg_name"):getChildByName("txt_name"):setString(arg_5_0.defendInfo.player_name)
		arg_5_0:setLev(arg_5_0.attackInfo.conquer_lev, arg_5_0.attackInfo.lev, var_5_4:getChildByName("txt_lv"), var_5_4:getChildByName("level_round"), 1, arg_5_0.attackInfo.conquer_loop_id)
		arg_5_0:setLev(arg_5_0.defendInfo.conquer_lev, arg_5_0.defendInfo.lev, var_5_5:getChildByName("txt_lv"), var_5_5:getChildByName("level_round"), 2, arg_5_0.defendInfo.conquer_loop_id)

		local var_5_10 = var_5_3:getChildByName("bg_times"):getChildByName("txt_times")

		var_5_10:enableOutline(cc.c4b(255, 255, 255, 255), 2)
		var_5_10:setString(string.format(var_0_4:translation("SUPER_ARENA_TITLE"), tostring(iter_5_0)))

		if arg_5_0.wins[iter_5_0] == 1 == arg_5_0.isAttack then
			var_5_4:getChildByName("bg_success"):setVisible(true)
			var_5_4:getChildByName("bg_failure"):setVisible(false)
			var_5_5:getChildByName("bg_success"):setVisible(false)
			var_5_5:getChildByName("bg_failure"):setVisible(true)
		else
			var_5_4:getChildByName("bg_success"):setVisible(false)
			var_5_4:getChildByName("bg_failure"):setVisible(true)
			var_5_5:getChildByName("bg_success"):setVisible(true)
			var_5_5:getChildByName("bg_failure"):setVisible(false)
		end

		xyd.setPlayerAvatar(var_5_4:getChildByName("avatar"), {
			avatar_id = arg_5_0.attackInfo.avatar_id,
			avatar_frame_id = arg_5_0.attackInfo.avatar_frame_id
		})
		xyd.setPlayerAvatar(var_5_5:getChildByName("avatar"), {
			avatar_id = arg_5_0.defendInfo.avatar_id,
			avatar_frame_id = arg_5_0.defendInfo.avatar_frame_id
		})

		for iter_5_2, iter_5_3 in ipairs(arg_5_0.attackTeam[iter_5_0].heros) do
			xyd.setAvatarBorderNewUI(iter_5_3, var_5_4:getChildByName("hero" .. iter_5_2))
		end

		local var_5_11 = arg_5_0.attackTeam[iter_5_0].pet

		if var_5_11 then
			local var_5_12 = var_5_4:getChildByName("pet")

			xyd.setPetAvatarNewUI(var_5_12, var_5_11, nil, true)
			var_5_12:setScale(0.5, 0.5)
		end

		for iter_5_4, iter_5_5 in ipairs(arg_5_0.defendTeam[iter_5_0].heros) do
			xyd.setAvatarBorderNewUI(iter_5_5, var_5_5:getChildByName("hero" .. iter_5_4))
		end

		local var_5_13 = arg_5_0.defendTeam[iter_5_0].pet

		if var_5_13 then
			local var_5_14 = var_5_5:getChildByName("pet")

			xyd.setPetAvatarNewUI(var_5_14, var_5_13, nil, true)
			var_5_14:setScale(0.5, 0.5)
		end

		local var_5_15 = var_5_3:getChildByName("btn_review")

		xyd.nodeEventSample(var_5_15, nil, function(arg_6_0)
			arg_5_0:requestReport(iter_5_0, function()
				arg_5_0:replayRecord(arg_5_0.reports[iter_5_0])
			end)
		end)
		xyd.nodeEventSample(var_5_3:getChildByName("btn_rank"), nil, function(arg_8_0)
			arg_5_0:requestReport(iter_5_0, function()
				arg_5_0:replayRecord(arg_5_0.reports[iter_5_0], true)
			end)
		end)
		var_5_0:setContentSize(var_5_3:getWidth(), var_5_3:getHeight())
		var_5_1:addContent(var_5_0)
		var_5_1:setItemSize(var_5_3:getWidth(), var_5_3:getHeight() + 26)
		arg_5_0.reportList:addItem(var_5_1)
	end

	arg_5_0.reportList:reload()

	if arg_5_0.withWin then
		arg_5_0:addResultEffectLayer(arg_5_0.isWin)

		arg_5_0.withWin = false
	end

	if arg_5_0.awards and #arg_5_0.awards ~= 0 then
		arg_5_0.selfPlayer:handleRewards(arg_5_0.awards)

		arg_5_0.awards = nil
		arg_5_0.params.awards = nil
	end
end

function var_0_0.playEffect(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4)
	local var_10_0
	local var_10_1 = arg_10_2 .. ".json"
	local var_10_2 = arg_10_2 .. ".atlas"
	local var_10_3 = var_0_3.new(var_10_1, var_10_2, 1)

	arg_10_1:addChild(var_10_3, arg_10_4)
	var_10_3:pos(arg_10_3.x, arg_10_3.y)
	var_10_3:setToSetupPose()
	var_10_3:setVisible(true)
	var_10_3:play(function()
		var_10_3:play(nil, true, nil, "texiao02")
	end, false, nil, "texiao01")
end

function var_0_0.addResultEffectLayer(arg_12_0, arg_12_1)
	local var_12_0 = 2

	arg_12_0.effectLayer = display.newColorLayer(cc.c4b(0, 0, 0, 200))

	arg_12_0.effectLayer:pos(-xyd.STAGE_WIDTH / 2, -xyd.STAGE_HEIGHT / 2):addTo(arg_12_0, var_12_0)
	arg_12_0.effectLayer:setName("effect_layer")
	arg_12_0.effectLayer:setTouchEnabled(true)
	arg_12_0.effectLayer:setTouchSwallowEnabled(true)

	local var_12_1 = {
		x = xyd.STAGE_WIDTH / 2,
		y = xyd.STAGE_HEIGHT / 2
	}

	if arg_12_1 == 1 then
		arg_12_0:playEffect(arg_12_0.effectLayer, "skeletons/ui_effect/douniu_effect/douniu_effect_win", var_12_1, 10)
	else
		arg_12_0:playEffect(arg_12_0.effectLayer, "skeletons/ui_effect/douniu_effect/douniu_effect_defeat", var_12_1, 20)
	end

	arg_12_0.effectLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			local var_13_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_13_0, false)
			arg_12_0:removeChildByName("effect_layer")

			return true
		elseif arg_13_0.name == "ended" then
			local var_13_1 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_13_1, false)
			arg_12_0:removeChildByName("effect_layer")
		end
	end)
end

function var_0_0.initHeros(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_1

	arg_14_0.jsonData_ = json.decode(var_14_0)

	local var_14_1 = {}
	local var_14_2 = {}
	local var_14_3 = {}
	local var_14_4 = {}

	ngx.ctx.battle.reportData = arg_14_0.jsonData_

	for iter_14_0, iter_14_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_14_5 = string.sub(iter_14_0, 1, 1)
		local var_14_6 = tonumber(string.sub(iter_14_0, 3, 3))

		if var_14_5 == "A" and tonumber(iter_14_1.summon_type) == xyd.summonMonsterType.None then
			local var_14_7 = var_0_1.new()

			var_14_7:populate(iter_14_1.hero)
			var_14_7:setReportData(iter_14_1)

			var_14_1[var_14_6] = var_14_7
		elseif var_14_5 == "A" and tonumber(iter_14_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_14_8 = var_0_2.new()

			var_14_8:populate(iter_14_1.hero)
			var_14_8:setReportData(iter_14_1)

			var_14_3[1] = var_14_8
		elseif var_14_5 == "B" and tonumber(iter_14_1.summon_type) == xyd.summonMonsterType.None then
			local var_14_9 = var_0_1.new()

			var_14_9:populate(iter_14_1.hero)
			var_14_9:setReportData(iter_14_1)

			var_14_2[var_14_6] = var_14_9
		elseif var_14_5 == "B" and tonumber(iter_14_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_14_10 = var_0_2.new()

			var_14_10:populate(iter_14_1.hero)
			var_14_10:setReportData(iter_14_1)

			var_14_4[1] = var_14_10
		elseif tonumber(iter_14_1.summon_type) ~= xyd.summonMonsterType.None then
			-- block empty
		end
	end

	arg_14_0.herosA[arg_14_2] = var_14_1
	arg_14_0.herosB[arg_14_2] = var_14_2
	arg_14_0.petsA[arg_14_2] = var_14_3
	arg_14_0.petsB[arg_14_2] = var_14_4
end

function var_0_0.replayRecord(arg_15_0, arg_15_1, arg_15_2)
	if arg_15_1 == nil or arg_15_1 == "" then
		if xyd.WindowManager.get():getWindow("toast") ~= nil then
			xyd.WindowManager.get():closeWindow("toast")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_4:translation("ARENA_RECORD_OUT_OF_DATE")
		})

		return
	end

	local var_15_0 = {}
	local var_15_1, var_15_2 = json.decode(arg_15_1)

	var_15_0.herosA = {}
	var_15_0.herosB = {}
	var_15_0.summonMonsters = {}
	var_15_0.campaignType = xyd.CampaignType.ARENA

	if not arg_15_0.isCasual then
		var_15_0.battleID = xyd.MapBattleID.PEAK_ARENA
	else
		var_15_0.battleID = xyd.MapBattleID.ARENA
		var_15_0.campaignType = xyd.CampaignType.REGION_CASUAL
	end

	var_15_0.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_15_1

	local var_15_3 = {}

	for iter_15_0, iter_15_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_15_4 = string.sub(iter_15_0, 1, 1)
		local var_15_5 = tonumber(string.sub(iter_15_0, 3, 3))

		if var_15_4 == "A" and tonumber(iter_15_1.summon_type) == xyd.summonMonsterType.None then
			local var_15_6 = var_0_1.new()

			var_15_6:populate(iter_15_1.hero)
			var_15_6:setReportData(iter_15_1)

			if arg_15_2 then
				var_15_6.harms = iter_15_1.harms
				var_15_6.willDie = (iter_15_1.die_count or 0) ~= -1
			end

			var_15_0.herosA[var_15_5] = var_15_6
		elseif var_15_4 == "A" and tonumber(iter_15_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_15_7 = var_0_2.new()

			var_15_7:populate(iter_15_1.hero)
			var_15_7:setReportData(iter_15_1)

			if arg_15_2 then
				var_15_7.harms = iter_15_1.harms
				var_15_7.willDie = (iter_15_1.die_count or 0) ~= -1
				var_15_0.petA = {
					var_15_7
				}
			else
				var_15_0.petsA = {
					var_15_7
				}
			end
		elseif var_15_4 == "B" and tonumber(iter_15_1.summon_type) == xyd.summonMonsterType.None then
			local var_15_8 = var_0_1.new()

			var_15_8:populate(iter_15_1.hero)
			var_15_8:setReportData(iter_15_1)

			if arg_15_2 then
				var_15_8.harms = iter_15_1.harms
				var_15_8.willDie = (iter_15_1.die_count or 0) ~= -1
				var_15_0.herosB[var_15_5] = var_15_8
			else
				var_15_3[var_15_5] = var_15_8
			end
		elseif var_15_4 == "B" and tonumber(iter_15_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_15_9 = var_0_2.new()

			var_15_9:populate(iter_15_1.hero)
			var_15_9:setReportData(iter_15_1)

			if arg_15_2 then
				var_15_9.harms = iter_15_1.harms
				var_15_9.willDie = (iter_15_1.die_count or 0) ~= -1
				var_15_0.petB = {
					var_15_9
				}
			else
				var_15_0.petsB = {
					var_15_9
				}
			end
		elseif tonumber(iter_15_1.summon_type) ~= xyd.summonMonsterType.None then
			local var_15_10 = var_0_1.new()

			var_15_10:populate(iter_15_1.hero)
			var_15_10:setReportData(iter_15_1)

			var_15_0.summonMonsters[iter_15_0] = var_15_10
		end
	end

	if arg_15_2 then
		var_15_0.isBeforeBattle = true

		xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, var_15_0)
	else
		var_15_0.herosB = {
			var_15_3
		}
		var_15_0.reportStar = tonumber(var_15_1.star)

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = xyd.WindowName.peakArenaReportsWnd,
				status = arg_15_0.params
			}
		})
		xyd.WindowManager.get():retainHistory()
		arg_15_0.peakArena:clearTotalResult()
		xyd.pushBattleScene(var_15_0)
	end
end

function var_0_0.requestReport(arg_16_0, arg_16_1, arg_16_2)
	if arg_16_0.reports[arg_16_1] then
		arg_16_2()
	else
		arg_16_0.peakArena:requestReport({
			report_key = arg_16_0.reportKeys[arg_16_1]
		}, function(arg_17_0)
			arg_16_0.reports[arg_16_1] = arg_17_0.report

			arg_16_2()
		end)
	end
end

return var_0_0
