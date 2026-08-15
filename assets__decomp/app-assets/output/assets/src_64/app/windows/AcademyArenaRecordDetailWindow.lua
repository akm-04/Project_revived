local var_0_0 = class("AcademyArenaRecordDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.hero

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.recordList = arg_1_2.list
	arg_1_0.playerAId = arg_1_2.playerAId
	arg_1_0.playerBId = arg_1_2.playerBId
	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.ACADEMY_ARENA)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	local var_2_0 = arg_2_0:nodeByName("list_container")
	local var_2_1 = var_2_0:getContentSize()

	arg_2_0.width = var_2_1.width
	arg_2_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_0)

	arg_2_0:updateList()
end

function var_0_0.updateList(arg_3_0)
	arg_3_0.list:removeAllItems()

	local var_3_0 = 220
	local var_3_1 = {}

	for iter_3_0, iter_3_1 in pairs(arg_3_0.recordList) do
		local var_3_2 = arg_3_0.list:newItem()
		local var_3_3 = arg_3_0:createRecordItem(iter_3_0, iter_3_1)

		var_3_3:setContentSize(arg_3_0.width, var_3_0)
		var_3_2:setItemSize(arg_3_0.width, var_3_0)
		var_3_2:addContent(var_3_3)
		arg_3_0.list:addItem(var_3_2)
	end

	arg_3_0.list:reload()
end

function var_0_0.createRecordItem(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/academy_arena/record/record_detail_item.csb")
	local var_4_1 = var_4_0:getChildByName("bg")

	arg_4_0:initDetail(var_4_1:getChildByName("bg_left"), arg_4_2.A_partners_str, arg_4_0.model:getRecordPlayer(arg_4_0.playerAId), arg_4_2.is_win > 0)
	arg_4_0:initDetail(var_4_1:getChildByName("bg_right"), arg_4_2.B_partners_str, arg_4_0.model:getRecordPlayer(arg_4_0.playerBId), arg_4_2.is_win < 1)
	var_4_1:getChildByName("battle_num"):setString(string.format(var_0_3:translation("SUPER_ARENA_TITLE"), arg_4_1))
	var_4_1:getChildByName("replay_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			if not var_4_0.hasGot then
				var_4_0.hasGot = true

				arg_4_0.model:getRecord(arg_4_2.record_id, arg_4_1, function(arg_6_0)
					var_4_0.report = arg_6_0[1]

					arg_4_0:replayRecord(var_4_0.report)
				end)
			else
				arg_4_0:replayRecord(var_4_0.report)
			end
		end
	end)
	var_4_1:getChildByName("data_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			if not var_4_0.hasGot then
				var_4_0.hasGot = true

				arg_4_0.model:getRecord(arg_4_2.record_id, arg_4_1, function(arg_8_0)
					var_4_0.report = arg_8_0[1]

					arg_4_0:replayRecord(var_4_0.report, true)
				end)
			else
				arg_4_0:replayRecord(var_4_0.report, true)
			end
		end
	end)

	return var_4_0
end

function var_0_0.initDetail(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4)
	if not arg_9_4 then
		arg_9_1:getChildByName("icon_win"):setVisible(false)
		arg_9_1:getChildByName("icon_lose"):setVisible(true)
	end

	local var_9_0 = {
		avatar_id = arg_9_3.avatar_id,
		avatar_frame_id = arg_9_3.avatar_frame_id
	}

	xyd.setPlayerAvatar(arg_9_1:getChildByName("avatar"), var_9_0)

	local var_9_1 = arg_9_1:getChildByName("bg_name")

	if arg_9_3.conquer_lev and arg_9_3.conquer_lev > 0 then
		xyd.setConquerLev(arg_9_3.conquer_lev, var_9_1:getChildByName("lev"), var_9_1:getChildByName("bg_lev"), nil, nil, nil, nil, arg_9_3.conquer_loop_id)
	else
		var_9_1:getChildByName("lev"):setString(arg_9_3.lev)
	end

	var_9_1:getChildByName("name"):setString(arg_9_3.player_name)

	local var_9_2 = xyd.split(arg_9_2, ",")

	for iter_9_0, iter_9_1 in ipairs(var_9_2) do
		local var_9_3 = xyd.splitToNumber(iter_9_1, ":")

		if var_9_3[1] and var_0_4:isCanAwaken(var_9_3[1]) > 0 and var_0_4:afterAwaken(var_9_3[1]) > 0 then
			var_9_3[1] = var_0_4:afterAwaken(var_9_3[1])
		end

		xyd.setAvatarBorder(var_9_3[1], arg_9_1:getChildByName("hero" .. iter_9_0), var_9_3[3], var_9_3[2], var_9_3[4] == 3)
	end
end

function var_0_0.replayRecord(arg_10_0, arg_10_1, arg_10_2)
	if arg_10_1 == nil or next(arg_10_1) == nil then
		if xyd.WindowManager.get():getWindow("toast") ~= nil then
			xyd.WindowManager.get():closeWindow("toast")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_3:translation("ARENA_RECORD_OUT_OF_DATE")
		})

		return
	end

	local var_10_0 = {}
	local var_10_1 = json.decode(arg_10_1.content)

	var_10_0.herosA = {}
	var_10_0.herosB = {}
	var_10_0.summonMonsters = {}
	var_10_0.campaignType = xyd.CampaignType.ARENA

	if not arg_10_0.isCasual then
		var_10_0.battleID = xyd.MapBattleID.PEAK_ARENA
	else
		var_10_0.battleID = xyd.MapBattleID.ARENA
		var_10_0.campaignType = xyd.CampaignType.REGION_CASUAL
	end

	var_10_0.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_10_1

	local var_10_2 = {}

	for iter_10_0, iter_10_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_10_3 = string.sub(iter_10_0, 1, 1)
		local var_10_4 = tonumber(string.sub(iter_10_0, 3, 3))

		if var_10_3 == "A" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.None then
			local var_10_5 = var_0_1.new()

			var_10_5:populate(iter_10_1.hero)
			var_10_5:setReportData(iter_10_1)

			if arg_10_2 then
				var_10_5.harms = iter_10_1.harms
				var_10_5.willDie = (iter_10_1.die_count or 0) ~= -1
			end

			var_10_0.herosA[var_10_4] = var_10_5
		elseif var_10_3 == "A" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_10_6 = var_0_2.new()

			var_10_6:populate(iter_10_1.hero)
			var_10_6:setReportData(iter_10_1)

			if arg_10_2 then
				var_10_6.harms = iter_10_1.harms
				var_10_6.willDie = (iter_10_1.die_count or 0) ~= -1
				var_10_0.petA = {
					var_10_6
				}
			else
				var_10_0.petsA = {
					var_10_6
				}
			end
		elseif var_10_3 == "B" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.None then
			local var_10_7 = var_0_1.new()

			var_10_7:populate(iter_10_1.hero)
			var_10_7:setReportData(iter_10_1)

			if arg_10_2 then
				var_10_7.harms = iter_10_1.harms
				var_10_7.willDie = (iter_10_1.die_count or 0) ~= -1
				var_10_0.herosB[var_10_4] = var_10_7
			else
				var_10_2[var_10_4] = var_10_7
			end
		elseif var_10_3 == "B" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_10_8 = var_0_2.new()

			var_10_8:populate(iter_10_1.hero)
			var_10_8:setReportData(iter_10_1)

			if arg_10_2 then
				var_10_8.harms = iter_10_1.harms
				var_10_8.willDie = (iter_10_1.die_count or 0) ~= -1
				var_10_0.petB = {
					var_10_8
				}
			else
				var_10_0.petsB = {
					var_10_8
				}
			end
		elseif tonumber(iter_10_1.summon_type) ~= xyd.summonMonsterType.None then
			local var_10_9 = var_0_1.new()

			var_10_9:populate(iter_10_1.hero)
			var_10_9:setReportData(iter_10_1)

			var_10_0.summonMonsters[iter_10_0] = var_10_9
		end
	end

	if arg_10_2 then
		var_10_0.isBeforeBattle = true

		xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, var_10_0)
	else
		var_10_0.herosB = {
			var_10_2
		}
		var_10_0.reportStar = tonumber(var_10_1.star)

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = xyd.WindowName.peakArenaReportsWnd,
				status = arg_10_0.params
			}
		})
		xyd.WindowManager.get():retainHistory()
		xyd.pushBattleScene(var_10_0)
	end
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	arg_11_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
