local var_0_0 = class("LvbuWorldCampusReportWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.lvbuFestival = xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL)
	arg_1_0.record = arg_1_2.record
	arg_1_0.reports = arg_1_0.record.list
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.reportList = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 1135, 500),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.reportList:setAnchorPoint(cc.p(0, 0))
	arg_2_0.reportList:setPosition(0, -290)
	arg_2_0:nodeByName("bg"):height(560)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	if not arg_4_0.reports or next(arg_4_0.reports) == nil then
		return
	end

	for iter_4_0 = 1, #arg_4_0.reports do
		if arg_4_0.reports[iter_4_0] ~= nil and next(arg_4_0.reports[iter_4_0]) ~= nil then
			local var_4_0 = display.newNode()
			local var_4_1 = arg_4_0.reportList:newItem()
			local var_4_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena_share/share_item.csb")
			local var_4_3 = var_4_2:getChildByName("background")

			var_4_2:setAnchorPoint(cc.p(0, 0))
			var_4_2:setPosition(0, 0)
			var_4_2:addTo(var_4_0)
			var_4_3:getChildByName("battle_num"):setVisible(false)
			var_4_3:getChildByName("left_name_txt"):setString(arg_4_0.selfPlayer.playerName)
			var_4_3:getChildByName("right_name_txt"):setString(arg_4_0.reports[iter_4_0].player_name)
			var_4_3:getChildByName("left_lev"):setString(arg_4_0.selfPlayer.lev)
			var_4_3:getChildByName("right_lev"):setString(arg_4_0.reports[iter_4_0].lev)
			var_4_3:getChildByName("battle_num"):setString(string.format(xyd.tables.translation:translation("SUPER_ARENA_TITLE"), tostring(iter_4_0)))
			var_4_3:getChildByName("battle_num"):setVisible(true)

			if arg_4_0.reports[iter_4_0].star > 0 then
				var_4_3:getChildByName("piaodai_green_left"):setVisible(true)
				var_4_3:getChildByName("piaodai_red_left"):setVisible(false)
				var_4_3:getChildByName("piaodai_red_right"):setVisible(true)
				var_4_3:getChildByName("piaodai_green_right"):setVisible(false)
			else
				var_4_3:getChildByName("piaodai_green_left"):setVisible(false)
				var_4_3:getChildByName("piaodai_red_left"):setVisible(true)
				var_4_3:getChildByName("piaodai_red_right"):setVisible(false)
				var_4_3:getChildByName("piaodai_green_right"):setVisible(true)
			end

			local var_4_4 = 90
			local var_4_5 = 90

			xyd.setPlayerAvatar(var_4_3:getChildByName("left_avatar"), {
				avatar_id = arg_4_0.selfPlayer:getMyCurrentAvatarID(),
				avatar_frame_id = arg_4_0.selfPlayer.avatarFrame
			})
			xyd.setPlayerAvatar(var_4_3:getChildByName("right_avatar"), {
				avatar_id = arg_4_0.reports[iter_4_0].avatar_id,
				avatar_id,
				avatar_frame_id = arg_4_0.reports[iter_4_0].avatar_frame_id
			})

			local var_4_6 = 0
			local var_4_7 = xyd.splitToNumber(arg_4_0.reports[iter_4_0].self_team, "|")
			local var_4_8 = arg_4_0.lvbuFestival:initialTeam(var_4_7)

			for iter_4_1 = 1, #var_4_8 do
				var_4_6 = var_4_6 + 1

				local var_4_9 = var_4_3:getChildByName("icon" .. var_4_6)
				local var_4_10 = var_4_8[iter_4_1]
				local var_4_11 = var_4_10:getColor()
				local var_4_12 = var_4_10:getStar()
				local var_4_13 = var_4_10:getLevel()
				local var_4_14 = xyd.setAvatarBorderWithLevelAndHp(var_4_10, var_4_9, var_4_11, var_4_12, var_4_13)
				local var_4_15 = xyd.AssetLoader.get():loadSprite("windows/common/lv_di.png")
				local var_4_16 = var_4_4 / 90
				local var_4_17 = {
					size = 12
				}
			end

			local var_4_18 = 0
			local var_4_19 = xyd.splitToNumber(arg_4_0.reports[iter_4_0].enemy_team, "|")
			local var_4_20 = arg_4_0.lvbuFestival:initialTeam(var_4_19)

			for iter_4_2 = 1, #var_4_20 do
				var_4_18 = var_4_18 + 1

				local var_4_21 = var_4_3:getChildByName("icon" .. var_4_18 + 5)
				local var_4_22 = var_4_20[iter_4_2]
				local var_4_23 = var_4_22:getColor()
				local var_4_24 = var_4_22:getStar()
				local var_4_25 = var_4_22:getLevel()
				local var_4_26 = xyd.setAvatarBorderWithLevelAndHp(var_4_22, var_4_21, var_4_23, var_4_24, var_4_25)
				local var_4_27 = var_4_4 / 90
				local var_4_28 = {
					size = 12
				}
			end

			var_4_3:getChildByName("replay_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
				if arg_5_1 == ccui.TouchEventType.ended then
					local var_5_0 = {
						record_id = arg_4_0.record.record_id,
						index = iter_4_0
					}

					arg_4_0.lvbuFestival:getBattleReport(var_5_0, function(arg_6_0, arg_6_1)
						if arg_6_0 == xyd.error.OK then
							arg_4_0:replayRecord(arg_6_1.report[1])
						end
					end)
				end
			end)
			var_4_3:getChildByName("data_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
				if arg_7_1 == ccui.TouchEventType.ended then
					local var_7_0 = {
						record_id = arg_4_0.record.record_id,
						index = iter_4_0
					}

					arg_4_0.lvbuFestival:getBattleReport(var_7_0, function(arg_8_0, arg_8_1)
						if arg_8_0 == xyd.error.OK then
							arg_4_0:replayRecord(arg_8_1.report[1], true)
						end
					end)
				end
			end)
			var_4_0:setContentSize(var_4_3:getWidth(), var_4_3:getHeight())
			var_4_1:addContent(var_4_0)
			var_4_1:setItemSize(var_4_3:getWidth(), var_4_3:getHeight())
			arg_4_0.reportList:addItem(var_4_1)
		else
			return
		end
	end

	arg_4_0.reportList:reload()
end

function var_0_0.replayRecord(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_1 == nil or next(arg_9_1) == nil then
		if xyd.WindowManager.get():getWindow("toast") ~= nil then
			xyd.WindowManager.get():closeWindow("toast")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_2:translation("ARENA_RECORD_OUT_OF_DATE")
		})

		return
	end

	local var_9_0 = {}
	local var_9_1 = json.decode(arg_9_1.content)

	var_9_0.herosA = {}
	var_9_0.herosB = {}
	var_9_0.summonMonsters = {}
	var_9_0.campaignType = xyd.CampaignType.ARENA
	var_9_0.battleID = xyd.MapBattleID.PEAK_ARENA
	var_9_0.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_9_1

	local var_9_2 = {}
	local var_9_3 = {}

	for iter_9_0, iter_9_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_9_4 = string.sub(iter_9_0, 1, 1)
		local var_9_5 = tonumber(string.sub(iter_9_0, 3, 3))

		if var_9_4 == "A" and tonumber(iter_9_1.summon_type) == xyd.summonMonsterType.None then
			local var_9_6 = var_0_1.new()

			var_9_6:populate(iter_9_1.hero)
			var_9_6:setReportData(iter_9_1)

			if arg_9_2 then
				var_9_6.harms = iter_9_1.harms
				var_9_6.willDie = (iter_9_1.die_count or 0) ~= -1
			end

			var_9_0.herosA[var_9_5] = var_9_6
		elseif var_9_4 == "A" and tonumber(iter_9_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_9_7 = Pet.new()

			var_9_7:populate(iter_9_1.hero)
			var_9_7:setReportData(iter_9_1)

			if arg_9_2 then
				var_9_7.harms = iter_9_1.harms
				var_9_7.willDie = (iter_9_1.die_count or 0) ~= -1
				var_9_0.petA = {
					var_9_7
				}
			else
				var_9_0.petsA = {
					var_9_7
				}
			end
		elseif var_9_4 == "B" and tonumber(iter_9_1.summon_type) == xyd.summonMonsterType.None then
			local var_9_8 = var_0_1.new()

			var_9_8:populate(iter_9_1.hero)
			var_9_8:setReportData(iter_9_1)

			if arg_9_2 then
				var_9_8.harms = iter_9_1.harms
				var_9_8.willDie = (iter_9_1.die_count or 0) ~= -1
				var_9_0.herosB[var_9_5] = var_9_8
			else
				var_9_2[var_9_5] = var_9_8
			end
		elseif var_9_4 == "B" and tonumber(iter_9_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_9_9 = Pet.new()

			var_9_9:populate(iter_9_1.hero)
			var_9_9:setReportData(iter_9_1)

			if arg_9_2 then
				var_9_9.harms = iter_9_1.harms
				var_9_9.willDie = (iter_9_1.die_count or 0) ~= -1
				var_9_0.petB = {
					var_9_9
				}
			else
				var_9_0.petsB = {
					var_9_9
				}
			end
		elseif tonumber(iter_9_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_9_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_9_10 = var_0_1.new()

			var_9_10:populate(iter_9_1.hero)
			var_9_10:setReportData(iter_9_1)

			var_9_3[iter_9_0] = var_9_10
		end
	end

	if arg_9_2 then
		var_9_0.isBeforeBattle = true

		xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, var_9_0)
	else
		var_9_0.herosB = {
			var_9_2
		}
		var_9_0.reportStar = tonumber(var_9_1.star)
		var_9_0.summonMonsters = var_9_3

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = xyd.WindowName.lvbuReportsWnd,
				status = arg_9_0.params
			}
		})
		xyd.WindowManager.get():retainHistory()
		xyd.pushBattleScene(var_9_0)
	end
end

function var_0_0.scrollListener(arg_10_0, arg_10_1)
	if arg_10_1.name == "began" then
		arg_10_0.scrollViewMoved_ = false
		arg_10_0.prevY_ = arg_10_1.y
	elseif arg_10_1.name == "moved" and 10 <= math.abs(arg_10_1.y - arg_10_0.prevY_) then
		arg_10_0.scrollViewMoved_ = true
	end
end

return var_0_0
