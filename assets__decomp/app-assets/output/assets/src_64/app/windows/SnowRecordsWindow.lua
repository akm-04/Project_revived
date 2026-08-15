local var_0_0 = class("SnowRecordsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.ActivityHero")
local var_0_3 = import("app.model.Pet")
local var_0_4 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.snowActivity = xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_ACTIVITY)
	arg_1_0.recordDatas = arg_1_2.battle_records or {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0.recordsList_:reload()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:initListView()
end

function var_0_0.initListView(arg_5_0)
	local var_5_0 = arg_5_0:nodeByName("list")
	local var_5_1 = var_5_0:getContentSize().width
	local var_5_2 = var_5_0:getContentSize().height

	arg_5_0.recordsList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_1, var_5_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_5_0)

	arg_5_0.recordsList_:setDelegate(handler(arg_5_0, arg_5_0.delegate))
end

function var_0_0.delegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = #arg_6_0.recordDatas

	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return var_6_0
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_1
		local var_6_2
		local var_6_3
		local var_6_4 = arg_6_0.recordsList_:dequeueItem()

		if not var_6_4 then
			var_6_4 = arg_6_0.recordsList_:newItem()
		else
			var_6_4:removeAllChildren()
		end

		local var_6_5 = display.newNode()

		var_6_5:setTouchSwallowEnabled(false)

		local var_6_6 = display.newNode()

		arg_6_0:initRecordCell(var_6_6, arg_6_3)
		var_6_5:addChild(var_6_6)
		var_6_5:setContentSize(cc.size(arg_6_0.recordsList_.viewRect_.width, var_6_6:getContentSize().height + 10))
		var_6_4:setItemSize(arg_6_0.recordsList_.viewRect_.width, var_6_6:getContentSize().height + 10)
		var_6_4:addContent(var_6_5)

		return var_6_4
	end
end

function var_0_0.initRecordCell(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_0.recordDatas[arg_7_2]
	local var_7_1 = var_7_0.attack_player_info
	local var_7_2 = var_7_0.defense_player_info
	local var_7_3 = var_7_0.attack_act_info or {}
	local var_7_4 = var_7_0.defense_act_info or {}
	local var_7_5 = var_7_1
	local var_7_6
	local var_7_7 = var_7_0.is_win > 0

	if var_7_1.player_id == arg_7_0.selfPlayer.playerID then
		var_7_5 = var_7_2
	else
		var_7_7 = not var_7_7
	end

	local var_7_8 = xyd.AssetLoader.get():loadNodeFromJson("windows/snow/snow_records/record_cell.csb")
	local var_7_9 = var_7_8:getChildByName("container")

	if var_7_7 then
		var_7_9:getChildByName("failed"):setVisible(false)
	else
		var_7_9:getChildByName("win"):setVisible(false)
	end

	var_7_9:getChildByName("region"):setString(var_7_5.region)
	var_7_9:getChildByName("name"):setString(var_7_5.player_name)
	var_7_9:getChildByName("time"):setString(var_7_5.player_name)

	local var_7_10 = xyd.ServerTime.get():getServerTime() - var_7_0.time

	var_7_9:getChildByName("time"):setString(xyd.secondsToString(var_7_10, {
		short = true,
		toText = true
	}) .. xyd.tables.translation:translation("BEFORE"))
	var_7_9:getChildByName("btn_replay"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = {
				report_key = var_7_0.report_key
			}

			arg_7_0.snowActivity:getReport(var_8_0, function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK and arg_7_0 and not tolua.isnull(arg_7_0) then
					arg_7_0:showRecord(arg_9_1, false, var_7_3, var_7_4)
				end
			end)
		end
	end)

	if var_7_5.conquer_lev and var_7_5.conquer_lev > 0 then
		xyd.setConquerLev(var_7_5.conquer_lev, var_7_9:getChildByName("text_lev"), var_7_9:getChildByName("level_bg"), nil, nil, 1.2, nil, var_7_5.conquer_loop_id)
	else
		var_7_9:getChildByName("text_lev"):setString(var_7_5.lev)
	end

	var_7_5.playerInfo = var_7_5

	xyd.setPlayerAvatar(var_7_9:getChildByName("avatar"), var_7_5)

	local var_7_11 = var_7_9:getContentSize()

	arg_7_1:setContentSize(var_7_11)
	var_7_8:addTo(arg_7_1)
end

function var_0_0.showRecord(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4)
	local var_10_0 = arg_10_1.report

	if var_10_0 == nil then
		return
	end

	if not arg_10_0 or tolua.isnull(arg_10_0) then
		return
	end

	local var_10_1 = {}
	local var_10_2 = json.decode(var_10_0)

	var_10_1.herosA = {}
	var_10_1.herosB = {}
	var_10_1.summonMonsters = {}
	var_10_1.campaignType = xyd.CampaignType.SNOW
	var_10_1.battleID = xyd.MapBattleID.SNOW_ACTIVITY
	var_10_1.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_10_2

	local var_10_3 = {}
	local var_10_4 = {}

	for iter_10_0, iter_10_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_10_5 = string.sub(iter_10_0, 1, 1)
		local var_10_6 = tonumber(string.sub(iter_10_0, 3, 3))

		if var_10_5 == "A" and tonumber(iter_10_1.is_main_role) == 1 then
			local var_10_7 = var_0_2.new()

			var_10_7:populate(iter_10_1.hero)
			var_10_7:setReportData(iter_10_1)

			local var_10_8 = xyd.tables.activitySnowEffect:buff(arg_10_3.effect_id or 0)

			var_10_7:setEffectBuffID(var_10_8)

			if arg_10_2 then
				var_10_7.harms = iter_10_1.harms
				var_10_7.willDie = (iter_10_1.die_count or 0) ~= -1
				var_10_1.herosA[var_10_6] = var_10_7
			end

			var_10_1.main_role_a = var_10_7
		elseif var_10_5 == "A" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.None then
			local var_10_9 = var_0_1.new()

			var_10_9:populate(iter_10_1.hero)
			var_10_9:setReportData(iter_10_1)

			if arg_10_2 then
				var_10_9.harms = iter_10_1.harms
				var_10_9.willDie = (iter_10_1.die_count or 0) ~= -1
				var_10_1.herosA[var_10_6] = var_10_9
			else
				table.insert(var_10_1.herosA, var_10_9)
			end
		elseif var_10_5 == "A" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_10_10 = var_0_3.new()

			var_10_10:populate(iter_10_1.hero)
			var_10_10:setReportData(iter_10_1)

			if arg_10_2 then
				var_10_10.harms = iter_10_1.harms
				var_10_10.willDie = (iter_10_1.die_count or 0) ~= -1
				var_10_1.petA = {
					var_10_10
				}
			else
				var_10_1.petsA = {
					var_10_10
				}
			end
		elseif var_10_5 == "B" and tonumber(iter_10_1.is_main_role) == 1 then
			local var_10_11 = var_0_2.new()

			var_10_11:populate(iter_10_1.hero)
			var_10_11:setReportData(iter_10_1)

			local var_10_12 = xyd.tables.activitySnowEffect:buff(arg_10_4.effect_id or 0)

			var_10_11:setEffectBuffID(var_10_12)

			if arg_10_2 then
				var_10_11.harms = iter_10_1.harms
				var_10_11.willDie = (iter_10_1.die_count or 0) ~= -1
				var_10_1.herosB[var_10_6] = var_10_11
			else
				var_10_1.main_role_b = var_10_11
			end
		elseif var_10_5 == "B" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.None then
			local var_10_13 = var_0_1.new()

			var_10_13:populate(iter_10_1.hero)
			var_10_13:setReportData(iter_10_1)

			if arg_10_2 then
				var_10_13.harms = iter_10_1.harms
				var_10_13.willDie = (iter_10_1.die_count or 0) ~= -1
				var_10_1.herosB[var_10_6] = var_10_13
			else
				table.insert(var_10_3, var_10_13)
			end
		elseif var_10_5 == "B" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_10_14 = var_0_3.new()

			var_10_14:populate(iter_10_1.hero)
			var_10_14:setReportData(iter_10_1)

			if arg_10_2 then
				var_10_14.harms = iter_10_1.harms
				var_10_14.willDie = (iter_10_1.die_count or 0) ~= -1
				var_10_1.petB = {
					var_10_14
				}
			else
				var_10_1.petsB = {
					var_10_14
				}
			end
		elseif var_10_5 == "C" then
			local var_10_15 = var_0_1.new()

			var_10_15:populate(iter_10_1.hero)
			var_10_15:setReportData(iter_10_1)

			if not arg_10_2 then
				sceneFighter = var_10_15
			end
		elseif tonumber(iter_10_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_10_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_10_16 = var_0_1.new()

			var_10_16:populate(iter_10_1.hero)
			var_10_16:setReportData(iter_10_1)

			var_10_4[iter_10_0] = var_10_16
		end
	end

	if arg_10_2 then
		collectgarbage("collect")

		var_10_1.isBeforeBattle = true

		xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, var_10_1)
	else
		var_10_1.herosB = {
			var_10_3
		}
		var_10_1.sceneFighter = sceneFighter
		var_10_1.summonMonsters = var_10_4
		var_10_1.reportStar = tonumber(var_10_2.star)

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = "snow_battle"
			}
		})
		xyd.WindowManager.get():retainHistory()
		cc.Director:getInstance():pushScene(import("app.scenes.ActivityBattleCreate").new(var_10_1))
	end
end

return var_0_0
