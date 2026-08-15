local var_0_0 = class("RegionBattleScoresWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.model.Pet")
local var_0_4 = {
	ZHANJI = 0,
	ZHANBAO = 1
}
local var_0_5 = 16

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.herosInfo = arg_1_2.herosInfo
	arg_1_0.totalFight = arg_1_2.totalFight or 0
	arg_1_0.winFight = arg_1_2.winFight or 0
	arg_1_0.kingPoint = arg_1_2.kingPoint or 0
	arg_1_0.reports = arg_1_2.reports
	arg_1_0.finalHeros = {}
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
	arg_1_0.awards = arg_1_0.regionArena.awards
	arg_1_0.tabMode = arg_1_2.mode or var_0_4.ZHANJI
	arg_1_0.is_other = arg_1_2.is_other

	arg_1_0:checkHero()

	arg_1_0.bestHeros = clone(arg_1_0.herosInfo)

	arg_1_0:sortHerosInfo()
	arg_1_0:sortBestHeros()
	arg_1_0:initHero(arg_1_0.herosInfo)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.i18nMainWnd(arg_3_0)
	if arg_3_0.is_other then
		arg_3_0:nodeByName("text_title"):setString(var_0_1:translation("REGION_ARENA_TEXT_24"))
	else
		arg_3_0:nodeByName("text_title"):setString(var_0_1:translation("REGION_ARENA_TEXT_6"))
	end

	arg_3_0:nodeByName("zhanji_title"):setString(var_0_1:translation("REGION_ARENA_TIP21"))
	arg_3_0:nodeByName("king_point_txt"):setString(var_0_1:translation("REGION_ARENA_TIP22"))
	arg_3_0:nodeByName("match_times_txt"):setString(var_0_1:translation("REGION_ARENA_TIP23"))
	arg_3_0:nodeByName("win_times_txt"):setString(var_0_1:translation("REGION_ARENA_TIP24"))
	arg_3_0:nodeByName("win_ratio_txt"):setString(var_0_1:translation("REGION_ARENA_TIP25"))
	arg_3_0:nodeByName("use_formation_txt"):setString(var_0_1:translation("REGION_ARENA_TIP26"))
	arg_3_0:nodeByName("best_hero_txt"):setString(var_0_1:translation("REGION_ARENA_TIP27"))
	arg_3_0:nodeByName("zhanji_tongji_title"):setString(var_0_1:translation("REGION_ARENA_TIP28"))
	arg_3_0:nodeByName("text_zhanji"):setString(var_0_1:translation("REGION_ARENA_TEXT_13"))
	arg_3_0:nodeByName("text_zhanbao"):setString(var_0_1:translation("REGION_ARENA_TEXT_14"))
end

function var_0_0.i18nHeroCell(arg_4_0, arg_4_1)
	arg_4_1:getChildByName("chuchang_txt"):setString(var_0_1:translation("REGION_ARENA_TIP31"))
	arg_4_1:getChildByName("harm_txt"):setString(var_0_1:translation("REGION_ARENA_TIP33"))
	arg_4_1:getChildByName("win_ratio_txt"):setString(var_0_1:translation("REGION_ARENA_TIP32"))
	arg_4_1:getChildByName("jisha_txt"):setString(var_0_1:translation("REGION_ARENA_TIP34"))
end

function var_0_0.i18nRecordCell(arg_5_0, arg_5_1)
	arg_5_1:getChildByName("win"):getChildByName("win_txt"):enableOutline(cc.c4b(20, 112, 29, 255), 2)
	arg_5_1:getChildByName("failed"):getChildByName("failed_txt"):enableOutline(cc.c4b(147, 24, 24, 255), 2)
	arg_5_1:getChildByName("win"):getChildByName("win_txt"):setString(var_0_1:translation("REGION_ARENA_TIP29"))
	arg_5_1:getChildByName("failed"):getChildByName("failed_txt"):setString(var_0_1:translation("REGION_ARENA_TIP30"))
end

function var_0_0.switchWndByMode(arg_6_0, arg_6_1)
	if arg_6_1 == var_0_4.ZHANJI then
		arg_6_0:nodeByName("zhanji"):setVisible(true)
		arg_6_0:nodeByName("zhanbao"):setVisible(false)
		arg_6_0:nodeByName("zhanji_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_6_0:nodeByName("zhanbao_btn"):setBrightStyle(ccui.BrightStyle.normal)
	else
		arg_6_0:nodeByName("zhanji"):setVisible(false)
		arg_6_0:nodeByName("zhanbao"):setVisible(true)
		arg_6_0:nodeByName("zhanji_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_6_0:nodeByName("zhanbao_btn"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_0.layout(arg_7_0)
	arg_7_0:i18nMainWnd()
	arg_7_0:update()
	arg_7_0:switchWndByMode(arg_7_0.tabMode)
	arg_7_0:nodeByName("zhanji_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			arg_7_0.tabMode = 1 - arg_7_0.tabMode

			arg_7_0:switchWndByMode(arg_7_0.tabMode)
		end
	end)
	arg_7_0:nodeByName("zhanbao_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			arg_7_0.tabMode = 1 - arg_7_0.tabMode

			arg_7_0:switchWndByMode(arg_7_0.tabMode)
		end
	end)
end

function var_0_0.initHero(arg_10_0, arg_10_1)
	for iter_10_0, iter_10_1 in pairs(arg_10_1) do
		hero = var_0_2.new()

		hero:initUnCollected(iter_10_1.table_id)
		hero:setStar(iter_10_1.star)

		hero.color_ = var_0_5
		arg_10_0.finalHeros[iter_10_1.table_id] = hero
	end
end

function var_0_0.update(arg_11_0)
	arg_11_0:nodeByName("best_hero_container"):removeAllChildren()
	arg_11_0:nodeByName("king_point"):setString(arg_11_0.kingPoint)
	arg_11_0:nodeByName("match_times"):setString(arg_11_0.totalFight)
	arg_11_0:nodeByName("win_times"):setString(arg_11_0.winFight)

	local var_11_0

	if arg_11_0.totalFight and arg_11_0.totalFight > 0 then
		var_11_0 = math.floor(arg_11_0.winFight / arg_11_0.totalFight * 100)
	else
		var_11_0 = 0
	end

	arg_11_0:nodeByName("win_ratio_bar"):setPercent(var_11_0)
	arg_11_0:nodeByName("win_ratio_num"):setString(var_11_0 .. "%")
	arg_11_0:layoutUsefulHeros()

	if arg_11_0.herosInfo and next(arg_11_0.herosInfo) then
		local var_11_1 = arg_11_0.finalHeros[arg_11_0.bestHeros[1].table_id]

		xyd.setAvatarBorder(var_11_1, arg_11_0:nodeByName("best_hero_container"))
		arg_11_0:updateHeroList()
	end

	arg_11_0:updateReportList()
end

function var_0_0.updateHeroList(arg_12_0)
	if not arg_12_0.heroList then
		arg_12_0.heroList = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, arg_12_0:nodeByName("hero_list"):getWidth(), arg_12_0:nodeByName("hero_list"):getHeight()),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		})

		arg_12_0.heroList:addTo(arg_12_0:nodeByName("hero_list"))
	else
		arg_12_0.heroList:removeAllItems()
	end

	for iter_12_0 = 1, #arg_12_0.herosInfo do
		local var_12_0 = arg_12_0.herosInfo[iter_12_0]
		local var_12_1 = arg_12_0.finalHeros[var_12_0.table_id]
		local var_12_2 = arg_12_0.heroList:newItem()
		local var_12_3 = display.newNode()
		local var_12_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/across_arena/hero_cell.csb")
		local var_12_5 = var_12_4:getChildByName("container")

		arg_12_0:i18nHeroCell(var_12_5)
		xyd.setAvatarBorder(var_12_1, var_12_5:getChildByName("avatar"))
		var_12_5:getChildByName("name"):setString(xyd.tables.hero:name(var_12_1:getTableID()))
		var_12_5:getChildByName("chuchang_num"):setString(var_12_0.total_fight)
		var_12_5:getChildByName("harm_num"):setString(tostring(math.floor(var_12_0.total_damage / var_12_0.total_fight)))
		var_12_5:getChildByName("jisha_num"):setString(tostring(math.ceil(var_12_0.total_kill / var_12_0.total_fight)))

		if var_12_0.total_fight > 0 then
			var_12_5:getChildByName("win_ratio"):setString(tostring(math.floor(var_12_0.win_fight / var_12_0.total_fight * 100) .. "%"))
		else
			var_12_5:getChildByName("win_ratio"):setString("N/A")
		end

		var_12_4:addTo(var_12_3)
		var_12_3:setContentSize(var_12_5:getContentSize().width, var_12_5:getContentSize().height)
		var_12_4:setAnchorPoint(cc.p(0, 0))
		var_12_2:addContent(var_12_3)
		var_12_2:setItemSize(var_12_5:getContentSize().width, var_12_5:getContentSize().height)
		arg_12_0.heroList:addItem(var_12_2)
	end

	arg_12_0.heroList:reload()
end

function var_0_0.updateReportList(arg_13_0)
	if not arg_13_0.reports or not next(arg_13_0.reports) then
		return
	end

	if not arg_13_0.reportList then
		arg_13_0.reportList = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, arg_13_0:nodeByName("list"):getWidth(), arg_13_0:nodeByName("list"):getHeight()),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		})

		arg_13_0.reportList:addTo(arg_13_0:nodeByName("list"))
	else
		arg_13_0.reportList:removeAllItems()
	end

	for iter_13_0 = 1, #arg_13_0.reports do
		local var_13_0 = arg_13_0.reports[iter_13_0]
		local var_13_1 = display.newNode()
		local var_13_2 = arg_13_0.reportList:newItem()
		local var_13_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/across_arena/record_cell.csb")
		local var_13_4 = var_13_3:getChildByName("container")

		arg_13_0:i18nRecordCell(var_13_4)
		var_13_4:getChildByName("name"):setString(var_13_0.player_name)
		var_13_4:getChildByName("time"):setString(arg_13_0:createTimeTxt(var_13_0.time))

		local var_13_5 = {
			avatar_id = var_13_0.avatar_id,
			avatar_frame_id = var_13_0.avatar_frame_id,
			playerInfo = var_13_0
		}

		xyd.setPlayerAvatar(var_13_4:getChildByName("avatar"), var_13_5)

		if var_13_0.win == 1 then
			var_13_4:getChildByName("failed"):setVisible(false)
			var_13_4:getChildByName("win"):setVisible(true)
		else
			var_13_4:getChildByName("failed"):setVisible(true)
			var_13_4:getChildByName("win"):setVisible(false)
		end

		var_13_4:getChildByName("zhuanfa_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
			xyd.buttonScaleAnim(arg_14_0, arg_14_1)

			if arg_14_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_14_0 = xyd.tables.translation:translation("FUNCTION_OPEN_TIP_OTHER")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_14_0
				})
			end
		end)
		var_13_4:getChildByName("replay_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
			xyd.buttonScaleAnim(arg_15_0, arg_15_1)

			if arg_15_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_15_0 = {
					report_key = var_13_0.report_key
				}

				arg_13_0.regionArena:getFightReport(var_15_0, function(arg_16_0, arg_16_1)
					if arg_16_0 == xyd.error.OK then
						if arg_16_1 == nil or arg_16_1 == {} then
							if xyd.WindowManager.get():getWindow("toast") ~= nil then
								xyd.WindowManager.get():closeWindow("toast")
							end

							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ARENA_RECORD_OUT_OF_DATE")
							})
						else
							arg_13_0:replayRecord(arg_16_1.report)
						end
					end
				end)
			end
		end)
		var_13_4:getChildByName("data_btn"):addTouchEventListener(function(arg_17_0, arg_17_1)
			xyd.buttonScaleAnim(arg_17_0, arg_17_1)

			if arg_17_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_17_0 = {
					report_key = var_13_0.report_key
				}

				arg_13_0.regionArena:getFightReport(var_17_0, function(arg_18_0, arg_18_1)
					if arg_18_0 == xyd.error.OK then
						if arg_18_1 == nil or arg_18_1 == {} then
							if xyd.WindowManager.get():getWindow("toast") ~= nil then
								xyd.WindowManager.get():closeWindow("toast")
							end

							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ARENA_RECORD_OUT_OF_DATE")
							})
						else
							arg_13_0:replayRecord(arg_18_1.report, true)
						end
					end
				end)
			end
		end)
		var_13_3:addTo(var_13_1)
		var_13_1:setContentSize(var_13_4:getContentSize().width, var_13_4:getContentSize().height)
		var_13_2:addContent(var_13_1)
		var_13_2:setItemSize(var_13_4:getContentSize().width, var_13_4:getContentSize().height + 10)
		arg_13_0.reportList:addItem(var_13_2)
	end

	arg_13_0.reportList:reload()
end

function var_0_0.replayRecord(arg_19_0, arg_19_1, arg_19_2)
	if not arg_19_1 or not next(arg_19_1) then
		if xyd.WindowManager.get():getWindow("toast") ~= nil then
			xyd.WindowManager.get():closeWindow("toast")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_1:translation("ARENA_RECORD_OUT_OF_DATE")
		})

		return
	end

	local var_19_0 = {}
	local var_19_1 = json.decode(arg_19_1[1].content)

	var_19_0.herosA = {}
	var_19_0.herosB = {}
	var_19_0.summonMonsters = {}
	var_19_0.campaignType = xyd.CampaignType.REGION_ARENA
	var_19_0.battleID = xyd.MapBattleID.ARENA
	var_19_0.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_19_1

	local var_19_2 = {}

	for iter_19_0, iter_19_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_19_3 = string.sub(iter_19_0, 1, 1)
		local var_19_4 = tonumber(string.sub(iter_19_0, 3, 3))

		if var_19_3 == "A" and tonumber(iter_19_1.summon_type) == xyd.summonMonsterType.None then
			local var_19_5 = var_0_2.new()

			var_19_5:populate(iter_19_1.hero)
			var_19_5:setReportData(iter_19_1)

			if arg_19_2 then
				var_19_5.willDie = (iter_19_1.die_count or 0) ~= -1
				var_19_5.harms = iter_19_1.harms
			end

			var_19_0.herosA[var_19_4] = var_19_5
		elseif var_19_3 == "A" and tonumber(iter_19_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_19_6 = var_0_3.new()

			var_19_6:populate(iter_19_1.hero)
			var_19_6:setReportData(iter_19_1)

			if arg_19_2 then
				var_19_6.willDie = (iter_19_1.die_count or 0) ~= -1
				var_19_6.harms = iter_19_1.harms
				var_19_0.petA = {
					var_19_6
				}
			else
				var_19_0.petsA = {
					var_19_6
				}
			end
		elseif var_19_3 == "B" and tonumber(iter_19_1.summon_type) == xyd.summonMonsterType.None then
			local var_19_7 = var_0_2.new()

			var_19_7:populate(iter_19_1.hero)
			var_19_7:setReportData(iter_19_1)

			if arg_19_2 then
				var_19_7.willDie = (iter_19_1.die_count or 0) ~= -1
				var_19_7.harms = iter_19_1.harms
				var_19_0.herosB[var_19_4] = var_19_7
			else
				var_19_2[var_19_4] = var_19_7
			end
		elseif var_19_3 == "B" and tonumber(iter_19_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_19_8 = var_0_3.new()

			var_19_8:populate(iter_19_1.hero)
			var_19_8:setReportData(iter_19_1)

			if arg_19_2 then
				var_19_8.willDie = (iter_19_1.die_count or 0) ~= -1
				var_19_8.harms = iter_19_1.harms
				var_19_0.petB = {
					var_19_8
				}
			else
				var_19_0.petsB = {
					var_19_8
				}
			end
		elseif tonumber(iter_19_1.summon_type) ~= xyd.summonMonsterType.None then
			local var_19_9 = var_0_2.new()

			var_19_9:populate(iter_19_1.hero)
			var_19_9:setReportData(iter_19_1)

			var_19_0.summonMonsters[iter_19_0] = var_19_9
		end
	end

	if arg_19_2 then
		var_19_0.isBeforeBattle = true

		xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, var_19_0)
	else
		var_19_0.herosB = {
			var_19_2
		}
		var_19_0.reportStar = tonumber(var_19_1.star)
		var_19_0.isWatchReplay = true

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = "battle_scores",
				status = {
					records = arg_19_0.records,
					tabMode = arg_19_0.tabMode
				}
			}
		})
		xyd.WindowManager.get():retainHistory()
		xyd.pushBattleScene(var_19_0)
	end
end

function var_0_0.createTimeTxt(arg_20_0, arg_20_1)
	local var_20_0 = xyd.ServerTime.get():getServerTime() - arg_20_1

	if var_20_0 > 0 then
		local var_20_1 = math.floor(var_20_0 / 86400)
		local var_20_2 = math.floor(var_20_0 % 86400 / 60 / 60)
		local var_20_3 = math.floor(var_20_0 % 86400 % 3600 / 60)
		local var_20_4 = math.floor(var_20_0 % 86400 % 3600 % 60)
		local var_20_5 = {}

		if var_20_1 > 0 then
			var_20_5[1] = var_20_1 .. var_0_1:translation("UNIT_DAY")
		else
			var_20_5[1] = ""
		end

		if var_20_2 > 0 then
			var_20_5[2] = var_20_2 .. var_0_1:translation("UNIT_HOUR")
		else
			var_20_5[2] = ""
		end

		if var_20_3 > 0 then
			var_20_5[3] = var_20_3 .. var_0_1:translation("UNIT_MINUTE")
		else
			var_20_5[3] = ""
		end

		if var_20_4 > 0 then
			var_20_5[4] = var_20_4 .. var_0_1:translation("UNIT_SECOND")
		else
			var_20_5[4] = ""
		end

		local var_20_6 = ""

		for iter_20_0 = 1, 4 do
			if var_20_5[iter_20_0] ~= "" then
				var_20_6 = var_20_6 .. var_20_5[iter_20_0]
			end
		end

		return var_20_6 .. var_0_1:translation("BEFORE")
	else
		return nil
	end
end

function var_0_0.layoutUsefulHeros(arg_21_0)
	arg_21_0:nodeByName("formation_container"):removeAllChildren()

	if not arg_21_0.herosInfo or not next(arg_21_0.herosInfo) then
		return
	end

	for iter_21_0 = 1, 5 do
		local var_21_0 = arg_21_0.herosInfo[iter_21_0]
		local var_21_1 = arg_21_0.finalHeros[var_21_0.table_id]
		local var_21_2 = display.newNode()

		var_21_2:setContentSize(76, 76)
		xyd.setAvatarBorder(var_21_1, var_21_2)
		var_21_2:addTo(arg_21_0:nodeByName("formation_container"))
		var_21_2:setPosition((iter_21_0 - 1) * 89, 0)
	end
end

function var_0_0.sortHerosInfo(arg_22_0)
	table.sort(arg_22_0.herosInfo, function(arg_23_0, arg_23_1)
		if arg_23_0.total_fight ~= arg_23_1.total_fight then
			return arg_23_0.total_fight > arg_23_1.total_fight
		end
	end)
end

function var_0_0.checkHero(arg_24_0)
	local var_24_0 = arg_24_0.awards

	for iter_24_0, iter_24_1 in pairs(arg_24_0.herosInfo) do
		for iter_24_2, iter_24_3 in pairs(var_24_0) do
			local var_24_1 = iter_24_3.region_arena_times or 0

			if iter_24_3.table_id == iter_24_1.table_id then
				if iter_24_3.is_awake == 1 then
					iter_24_1.table_id = xyd.tables.hero:afterAwaken(iter_24_1.table_id)
				end

				iter_24_1.total_fight = iter_24_1.total_fight + var_24_1
			elseif iter_24_3.table_id == xyd.tables.hero:beforeAwaken(iter_24_1.table_id) then
				iter_24_1.total_fight = iter_24_1.total_fight + var_24_1
			else
				iter_24_1.total_fight = iter_24_1.total_fight
			end
		end
	end
end

function var_0_0.sortBestHeros(arg_25_0)
	for iter_25_0, iter_25_1 in pairs(arg_25_0.bestHeros) do
		local var_25_0

		if iter_25_1.total_fight > 0 then
			var_25_0 = iter_25_1.win_fight / iter_25_1.total_fight
			iter_25_1.perKill = iter_25_1.total_kill / iter_25_1.total_fight
			iter_25_1.perDamage = iter_25_1.total_damage / iter_25_1.total_fight
		else
			var_25_0 = 0
			iter_25_1.perKill = 0
			iter_25_1.perDamage = 0
		end

		iter_25_1.best = var_25_0 * iter_25_1.total_fight
	end

	table.sort(arg_25_0.bestHeros, function(arg_26_0, arg_26_1)
		if arg_26_0.best ~= arg_26_1.best then
			return arg_26_0.best > arg_26_1.best
		elseif arg_26_0.total_fight ~= arg_26_1.total_fight then
			return arg_26_0.total_fight > arg_26_1.total_fight
		elseif arg_26_0.perKill ~= arg_26_1.perKill then
			return arg_26_0.perKill > arg_26_1.perKill
		elseif arg_26_0.perDamage ~= arg_26_1.perDamage then
			return arg_26_0.perDamage > arg_26_1.perDamage
		end
	end)
end

function var_0_0.didOpen(arg_27_0, arg_27_1)
	var_0_0.super:didOpen(arg_27_1)
	arg_27_0:addBlockLayer()
end

return var_0_0
