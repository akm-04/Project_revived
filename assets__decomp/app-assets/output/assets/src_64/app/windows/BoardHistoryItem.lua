local var_0_0 = import("app.model.Hero")
local var_0_1 = class("BoardHistoryItem", function()
	return cc.Node:create()
end)

function var_0_1.ctor(arg_2_0, arg_2_1)
	arg_2_0:contentView()

	arg_2_0.container = arg_2_0:contentView():nodeByName("container")
	arg_2_0.mission = arg_2_1
	arg_2_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

	arg_2_0:setContentSize(arg_2_0.container:getContentSize())
	arg_2_0:layout()
end

function var_0_1.layout(arg_3_0)
	arg_3_0:contentView():nodeByName("task_name"):setString(xyd.tables.eventCentreMissionTable:name(arg_3_0.mission.mission_id))

	if arg_3_0.mission.is_win == 1 then
		arg_3_0:contentView():nodeByName("win_label"):setVisible(true)
		arg_3_0:contentView():nodeByName("fail_label"):setVisible(false)
	else
		arg_3_0:contentView():nodeByName("win_label"):setVisible(false)
		arg_3_0:contentView():nodeByName("fail_label"):setVisible(true)
	end

	if arg_3_0.mission.battle_id == 0 then
		arg_3_0:contentView():nodeByName("battle_button"):setVisible(false)
	else
		arg_3_0:contentView():nodeByName("battle_button"):setVisible(true)
	end

	arg_3_0:registerTouchEvent()
	arg_3_0:registerBattleButton()
end

function var_0_1.registerTouchEvent(arg_4_0)
	local var_4_0 = arg_4_0.container

	arg_4_0:contentView():addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			arg_4_0.prevX_ = arg_5_0.x
			arg_4_0.prevY_ = arg_5_0.y
			arg_4_0.startClick_ = true
		elseif arg_5_0.name == "moved" then
			if math.abs(arg_5_0.y - arg_4_0.prevY_) > 10 or math.abs(arg_5_0.x - arg_4_0.prevX_) > 20 then
				arg_4_0.startClick_ = false
			end
		elseif arg_5_0.name == "ended" and arg_4_0.startClick_ then
			local var_5_0 = var_4_0:convertToNodeSpace(cc.p(arg_5_0.x, arg_5_0.y))
		end

		return true
	end)
end

function var_0_1.registerBattleButton(arg_6_0)
	arg_6_0:contentView():nodeByName("battle_button"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			-- block empty
		end

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_7_0 = {
				battle_id = arg_6_0.mission.battle_id
			}

			arg_6_0.eventCentre:getNoticeBoardReport(var_7_0, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					arg_6_0.battleData = arg_8_1

					arg_6_0:showReport(arg_6_0.battleData)
				end
			end)
		end
	end)
end

function var_0_1.showReport(arg_9_0, arg_9_1)
	local var_9_0 = {}
	local var_9_1 = json.decode(arg_9_1.report[1].content)

	var_9_0.herosA = {}
	var_9_0.herosB = {}
	var_9_0.summonMonsters = {}
	var_9_0.campaignType = xyd.CampaignType.ARENA
	var_9_0.battleID = xyd.MapBattleID.ARENA
	var_9_0.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_9_1

	local var_9_2 = {}

	for iter_9_0, iter_9_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_9_3 = string.sub(iter_9_0, 1, 1)
		local var_9_4 = tonumber(string.sub(iter_9_0, 3, 3))

		if var_9_3 == "A" and tonumber(iter_9_1.summon_type) == xyd.summonMonsterType.None then
			local var_9_5 = var_0_0.new()

			var_9_5:populate(iter_9_1.hero)
			var_9_5:setReportData(iter_9_1)

			var_9_0.herosA[var_9_4] = var_9_5
		elseif var_9_3 == "B" and tonumber(iter_9_1.summon_type) == xyd.summonMonsterType.None then
			local var_9_6 = var_0_0.new()

			var_9_6:populate(iter_9_1.hero)
			var_9_6:setReportData(iter_9_1)

			var_9_2[var_9_4] = var_9_6
		elseif tonumber(iter_9_1.summon_type) ~= xyd.summonMonsterType.None then
			local var_9_7 = var_0_0.new()

			var_9_7:populate(iter_9_1.hero)
			var_9_7:setReportData(iter_9_1)

			var_9_0.summonMonsters[iter_9_0] = var_9_7
		end
	end

	var_9_0.herosB = {
		var_9_2
	}
	var_9_0.reportStar = tonumber(var_9_1.star)

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "board_main_window"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_9_0)
end

function var_0_1.contentView(arg_10_0)
	if arg_10_0.contentView_ == nil then
		arg_10_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_10_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/event_centre/board/board/history_item.csb"))
		arg_10_0.contentView_:addTo(arg_10_0)
		arg_10_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_10_0.contentView_
end

return var_0_1
