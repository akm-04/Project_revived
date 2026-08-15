local var_0_0 = class("BattleTestOutputWindow", import("app.common.ui.BaseWindow"))

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.reports = arg_1_2.reports
	arg_1_0.replays = arg_1_2.replays
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("list")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.list_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(var_3_0)

	arg_3_0.list_:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.list_:reload()
end

function var_0_0.delegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #arg_4_0.reports
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0 = arg_4_0.list_:dequeueItem()

		if not var_4_0 then
			var_4_0 = arg_4_0.list_:newItem()
		else
			var_4_0:removeAllChildren(true)
		end

		local var_4_1 = arg_4_0.reports[arg_4_3]
		local var_4_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/battle_test/output_item.csb")
		local var_4_3 = var_4_2:getChildByName("container")

		var_4_3:getChildByName("index"):setString("戰鬥" .. arg_4_3)
		var_4_3:getChildByName("winer"):setString(var_4_1.winner)
		var_4_3:getChildByName("time"):setString(var_4_1.cost_time .. "S")
		var_4_3:getChildByName("alive_num_1"):setString(var_4_1.aliveNumA)
		var_4_3:getChildByName("alive_num_2"):setString(var_4_1.aliveNumB)
		var_4_2:setContentSize(var_4_3:getContentSize())
		var_4_0:addContent(var_4_2)
		var_4_0:setItemSize(var_4_3:getWidth(), var_4_3:getHeight() + 5)
		var_4_3:getChildByName("btn_detail"):addTouchEventListener(function(arg_5_0, arg_5_1)
			if arg_5_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				arg_4_0:printDetail(arg_4_3)
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, "是否回放", function()
					arg_4_0:replay(arg_4_0.replays[arg_4_3])
				end, nil, nil, arg_4_0.colorMode)
			end
		end)

		return var_4_0
	end
end

function var_0_0.setWinRate(arg_7_0)
	local var_7_0 = 0

	for iter_7_0 = 1, #arg_7_0.reports do
		if arg_7_0.reports[iter_7_0].winner == "A" then
			var_7_0 = var_7_0 + 1
		end
	end

	arg_7_0:nodeByName("win_rate"):setString("進攻方勝率：" .. var_7_0 / #arg_7_0.reports)
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super.didOpen(arg_8_0, arg_8_1)
	arg_8_0:setWinRate()
	arg_8_0:addBlockLayer()
end

function var_0_0.printDetail(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_0.reports[arg_9_1]

	print("battle detail==========================================")

	for iter_9_0, iter_9_1 in ipairs(var_9_0.teamA) do
		local var_9_1 = iter_9_1.die_count == -1 and "存活" or iter_9_1.die_count

		print("                                                ")
		print("table_id:" .. iter_9_1.table_id .. "     " .. "死亡時間:" .. var_9_1)
		print("輸出傷害:" .. math.floor(iter_9_1.harms) .. "     " .. "承受傷害" .. math.floor(iter_9_1.bearHarms))
	end

	for iter_9_2, iter_9_3 in ipairs(var_9_0.teamB) do
		local var_9_2 = iter_9_3.die_count == -1 and "存活" or iter_9_3.die_count

		print("                                                ")
		print("table_id:" .. iter_9_3.table_id .. "     " .. "死亡時間:" .. var_9_2)
		print("輸出傷害:" .. math.floor(iter_9_3.harms) .. "     " .. "承受傷害" .. math.floor(iter_9_3.bearHarms))
	end
end

function var_0_0.replay(arg_10_0, arg_10_1)
	local var_10_0 = false
	local var_10_1 = import("app.model.Hero")
	local var_10_2 = import("app.model.Pet")

	if arg_10_1 == nil or next(arg_10_1) == nil then
		if xyd.WindowManager.get():getWindow("toast") ~= nil then
			xyd.WindowManager.get():closeWindow("toast")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = stringLocalizer:translation("ARENA_RECORD_OUT_OF_DATE")
		})

		return
	end

	local var_10_3 = {}
	local var_10_4 = json.decode(arg_10_1.battle_report)

	var_10_3.herosA = {}
	var_10_3.herosB = {}
	var_10_3.summonMonsters = {}
	var_10_3.campaignType = xyd.CampaignType.ARENA
	var_10_3.battleID = xyd.MapBattleID.ARENA
	var_10_3.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_10_4

	local var_10_5 = {}
	local var_10_6 = {}

	for iter_10_0, iter_10_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_10_7 = string.sub(iter_10_0, 1, 1)
		local var_10_8 = tonumber(string.sub(iter_10_0, 3, 3))

		if var_10_7 == "A" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.None then
			local var_10_9 = var_10_1.new()

			var_10_9:populate(iter_10_1.hero)
			var_10_9:setReportData(iter_10_1)

			if var_10_0 then
				var_10_9.harms = iter_10_1.harms
				var_10_9.willDie = (iter_10_1.die_count or 0) ~= -1
			end

			var_10_3.herosA[var_10_8] = var_10_9
		elseif var_10_7 == "A" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_10_10 = var_10_2.new()

			var_10_10:populate(iter_10_1.hero)
			var_10_10:setReportData(iter_10_1)

			if var_10_0 then
				var_10_10.harms = iter_10_1.harms
				var_10_10.willDie = (iter_10_1.die_count or 0) ~= -1
				var_10_3.petA = {
					var_10_10
				}
			else
				var_10_3.petsA = {
					var_10_10
				}
			end
		elseif var_10_7 == "B" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.None then
			local var_10_11 = var_10_1.new()

			var_10_11:populate(iter_10_1.hero)
			var_10_11:setReportData(iter_10_1)

			if var_10_0 then
				var_10_11.harms = iter_10_1.harms
				var_10_11.willDie = (iter_10_1.die_count or 0) ~= -1
				var_10_3.herosB[var_10_8] = var_10_11
			else
				var_10_5[var_10_8] = var_10_11
			end
		elseif var_10_7 == "B" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_10_12 = var_10_2.new()

			var_10_12:populate(iter_10_1.hero)
			var_10_12:setReportData(iter_10_1)

			if var_10_0 then
				var_10_12.harms = iter_10_1.harms
				var_10_12.willDie = (iter_10_1.die_count or 0) ~= -1
				var_10_3.petB = {
					var_10_12
				}
			else
				var_10_3.petsB = {
					var_10_12
				}
			end
		elseif tonumber(iter_10_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_10_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_10_13 = var_10_1.new()

			var_10_13:populate(iter_10_1.hero)
			var_10_13:setReportData(iter_10_1)

			var_10_6[iter_10_0] = var_10_13
		end
	end

	if var_10_0 then
		collectgarbage("collect")

		var_10_3.isBeforeBattle = true

		xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, var_10_3)
	else
		var_10_3.herosB = {
			var_10_5
		}
		var_10_3.summonMonsters = var_10_6
		var_10_3.reportStar = tonumber(var_10_4.star)

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = "battle_test_output",
				status = {
					replays = arg_10_0.replays,
					reports = arg_10_0.reports
				}
			}
		})
		xyd.WindowManager.get():retainHistory()
		xyd.pushBattleScene(var_10_3)
	end
end

return var_0_0
