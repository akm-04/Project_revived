local var_0_0 = class("NewBattleLoadingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = require("framework.scheduler")
local var_0_3 = import("app.model.Hero")
local var_0_4 = import("app.model.Pet")
local var_0_5 = xyd.tables.loadingTip
local var_0_6 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.params = arg_1_2
	arg_1_0.battleID = arg_1_2.battleID or 0
	arg_1_0.campaignType = arg_1_2.campaignType
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 0))
	arg_3_0:layout()
	arg_3_0:scheduleHandler()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("upper_wnd")
	local var_4_1 = arg_4_0:nodeByName("lower_wnd")

	arg_4_0:layoutEnemyInfo(var_4_1)
	arg_4_0:layoutSelfInfo(var_4_0)

	local var_4_2 = "windows/playoffs/playoffs_resource/vs/vs.png"
	local var_4_3 = xyd.AssetLoader.get():loadSprite(var_4_2)

	arg_4_0:nodeByName("background"):addChild(var_4_3)
	var_4_3:setName("vs")
	var_4_3:setPosition(arg_4_0:nodeByName("background"):getWidth() / 2, arg_4_0:nodeByName("background"):getHeight() / 2)
end

function var_0_0.layoutEnemyInfo(arg_5_0, arg_5_1)
	local var_5_0 = false

	if arg_5_0.params.petsB and arg_5_0.params.petsB[1] then
		local var_5_1 = arg_5_0.params.petsB[1]
		local var_5_2

		if var_5_1:isAwaken() then
			var_5_2 = xyd.getPetCard(var_5_1, 3, 3)
		else
			var_5_2 = xyd.getPetCard(var_5_1)
		end

		var_5_2:setAnchorPoint(cc.p(0, 0))

		local var_5_3 = arg_5_1:getChildByName("pet"):getWidth() / var_5_2:getContentSize().width

		var_5_2:setScale(var_5_3)
		var_5_2:addTo(arg_5_1:getChildByName("pet"))

		var_5_0 = true
	end

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.params.herosB[1]) do
		local var_5_4

		if iter_5_1.illusionSkinId_ and iter_5_1.illusionSkinId_ >= 0 then
			var_5_4 = xyd.getHeroCard(iter_5_1, 2, 2)
		elseif iter_5_1:isAwaken() then
			var_5_4 = xyd.getHeroCard(iter_5_1, 3, 3)
		else
			var_5_4 = xyd.getHeroCard(iter_5_1)
		end

		var_5_4:getChildByName("rare_lev"):scale(1.5)
		var_5_4:setAnchorPoint(cc.p(0, 0))

		local var_5_5 = arg_5_1:getChildByName("hero" .. iter_5_0):getWidth() / var_5_4:getContentSize().width

		var_5_4:setScale(var_5_5)

		local var_5_6

		if var_5_0 == false then
			if iter_5_0 == 1 then
				var_5_4:addTo(arg_5_1:getChildByName("pet"))
			else
				local var_5_7 = iter_5_0 - 1

				var_5_4:addTo(arg_5_1:getChildByName("hero" .. var_5_7))
			end
		else
			var_5_4:addTo(arg_5_1:getChildByName("hero" .. iter_5_0))
		end
	end

	xyd.setPlayerTitle(arg_5_1:getChildByName("title_container"), arg_5_0.params.enemy_title_info)
	arg_5_1:getChildByName("name"):setString(arg_5_0.params.enemyName)
	arg_5_1:getChildByName("id"):setString(arg_5_0.params.enemy_id)
	arg_5_1:getChildByName("from_txt"):setString(var_0_6:translation("LAI_ZI"))
	arg_5_1:getChildByName("server_txt"):setString(var_0_6:translation("REGION_ARENA_TIP10"))

	if arg_5_0.params.enemyGuild then
		arg_5_1:getChildByName("guild_name"):setString(arg_5_0.params.enemyGuild)
	else
		arg_5_1:getChildByName("from_txt"):setVisible(false)
		arg_5_1:getChildByName("guild_name"):setString(var_0_6:translation("PERSON_NO_GUILD"))
		arg_5_1:getChildByName("guild_name"):setPositionY(arg_5_1:getChildByName("guild_name"):getPositionY() + 24)
	end

	if arg_5_0.params.enemyRegionName then
		arg_5_1:getChildByName("server_name"):setString(arg_5_0.params.enemyRegionName .. "(S" .. arg_5_0.params.enemyRegion .. ")")
	else
		arg_5_1:getChildByName("server_txt"):setVisible(false)
		arg_5_1:getChildByName("server_name"):setVisible(false)
	end
end

function var_0_0.layoutSelfInfo(arg_6_0, arg_6_1)
	local var_6_0 = false

	if arg_6_0.params.petsA and arg_6_0.params.petsA[1] then
		local var_6_1 = arg_6_0.params.petsA[1]
		local var_6_2

		if var_6_1:isAwaken() then
			var_6_2 = xyd.getPetCard(var_6_1, 3, 3)
		else
			var_6_2 = xyd.getPetCard(var_6_1)
		end

		var_6_2:setAnchorPoint(cc.p(0, 0))

		local var_6_3 = arg_6_1:getChildByName("pet"):getWidth() / var_6_2:getContentSize().width

		var_6_2:setScale(var_6_3)
		var_6_2:addTo(arg_6_1:getChildByName("pet"))

		var_6_0 = true
	end

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.params.herosA) do
		local var_6_4

		if iter_6_1.illusionSkinId_ and iter_6_1.illusionSkinId_ >= 0 then
			var_6_4 = xyd.getHeroCard(iter_6_1, 2, 2)
		elseif iter_6_1:isAwaken() then
			var_6_4 = xyd.getHeroCard(iter_6_1, 3, 3)
		else
			var_6_4 = xyd.getHeroCard(iter_6_1)
		end

		var_6_4:getChildByName("rare_lev"):scale(1.5)
		var_6_4:setAnchorPoint(cc.p(0, 0))

		local var_6_5 = arg_6_1:getChildByName("hero" .. iter_6_0):getWidth() / var_6_4:getContentSize().width

		var_6_4:setScale(var_6_5)

		local var_6_6

		if var_6_0 == false then
			if iter_6_0 == 1 then
				var_6_4:addTo(arg_6_1:getChildByName("pet"))
			else
				local var_6_7 = iter_6_0 + 5 - #arg_6_0.params.herosA

				var_6_4:addTo(arg_6_1:getChildByName("hero" .. var_6_7))
			end
		else
			local var_6_8 = iter_6_0 + 5 - #arg_6_0.params.herosA

			var_6_4:addTo(arg_6_1:getChildByName("hero" .. var_6_8))
		end
	end

	xyd.setPlayerTitle(arg_6_1:getChildByName("title_container"), arg_6_0.selfPlayer.titleInfo)
	arg_6_1:getChildByName("from_txt"):setString(var_0_6:translation("LAI_ZI"))
	arg_6_1:getChildByName("server_txt"):setString(var_0_6:translation("REGION_ARENA_TIP10"))

	if not arg_6_0.selfPlayerID then
		arg_6_1:getChildByName("name"):setString(arg_6_0.selfPlayer.playerName)
		arg_6_1:getChildByName("id"):setString(arg_6_0.selfPlayer.playerID)

		if arg_6_0.guild.guild_name then
			arg_6_1:getChildByName("guild_name"):setString(arg_6_0.guild.guild_name)
		else
			arg_6_1:getChildByName("from_txt"):setVisible(false)
			arg_6_1:getChildByName("guild_name"):setString(var_0_6:translation("PERSON_NO_GUILD"))
			arg_6_1:getChildByName("guild_name"):setPositionY(arg_6_1:getChildByName("guild_name"):getPositionY() + 24)
		end

		if arg_6_0.selfPlayer.regionName then
			arg_6_1:getChildByName("server_name"):setString(arg_6_0.selfPlayer.regionName .. "(S" .. arg_6_0.selfPlayer.region .. ")")
		else
			arg_6_1:getChildByName("server_txt"):setVisible(false)
			arg_6_1:getChildByName("server_name"):setVisible(false)
		end
	else
		arg_6_1:getChildByName("name"):setString(arg_6_0.params.myName)
		arg_6_1:getChildByName("id"):setString(arg_6_0.params.my_id)

		if arg_6_0.params.myGuild then
			arg_6_1:getChildByName("guild_name"):setString(arg_6_0.params.myGuild)
		else
			arg_6_1:getChildByName("from_txt"):setVisible(false)
			arg_6_1:getChildByName("guild_name"):setString(var_0_6:translation("PERSON_NO_GUILD"))
			arg_6_1:getChildByName("guild_name"):setPositionY(arg_6_1:getChildByName("guild_name"):getPositionY() + 24)
		end

		if arg_6_0.params.selfRegionName then
			arg_6_1:getChildByName("server_name"):setString(arg_6_0.params.selfRegionName .. "(S" .. arg_6_0.params.selfRegion .. ")")
		else
			arg_6_1:getChildByName("server_txt"):setVisible(false)
			arg_6_1:getChildByName("server_name"):setVisible(false)
		end
	end
end

function var_0_0.scheduleHandler(arg_7_0)
	arg_7_0:setupMusic()

	arg_7_0.handler = var_0_2.scheduleUpdateGlobal(handler(arg_7_0, arg_7_0.loop))
end

function var_0_0.loop(arg_8_0)
	arg_8_0.count = arg_8_0.count or 0

	if arg_8_0.count < 1 then
		arg_8_0.count = arg_8_0.count + 1
	else
		if arg_8_0.params.campaignType == xyd.CampaignType.ARENA then
			arg_8_0:arenaReport()
		elseif arg_8_0.params.campaignType == xyd.CampaignType.ARENA_MODE then
			arg_8_0:arenaModeReport()
		elseif arg_8_0.params.campaignType == xyd.CampaignType.LVBU_FESTIVAL then
			arg_8_0:lvbuFestivalReport()
		elseif arg_8_0.params.campaignType == xyd.CampaignType.SUPER_ARENA then
			arg_8_0:superArenaReport()
		elseif arg_8_0.params.campaignType == xyd.CampaignType.REGION_ARENA then
			arg_8_0:regionArenaReport()
		end

		if arg_8_0.handler ~= nil then
			var_0_2.unscheduleGlobal(arg_8_0.handler)

			arg_8_0.handler = nil
		end
	end
end

function var_0_0.arenaReport(arg_9_0)
	local var_9_0 = arg_9_0.params

	if FRONT_ARENA_BATTLE or not var_9_0.battle_report then
		local var_9_1 = xyd.BattleCreateReport.new(var_9_0)

		var_9_1:addTo(arg_9_0)
		var_9_1:hide()
		cc.EventProxy.new(xyd.EventDispatcher.get(), arg_9_0):addEventListener(xyd.event.BATTLE_REPORT_CREATE, function(arg_10_0)
			var_9_0.responseData = arg_10_0.response
			var_9_0.battleType = xyd.BattleType.ReplayReport

			local var_10_0 = var_9_1:writeReport()

			ngx.ctx.battle.reportData = json.decode(var_10_0)
			var_9_0.herosA = {}
			var_9_0.herosB = {}
			var_9_0.summonMonsters = {}

			local var_10_1 = {}
			local var_10_2 = {}

			for iter_10_0, iter_10_1 in pairs(ngx.ctx.battle.reportData.fighter) do
				local var_10_3 = string.sub(iter_10_0, 1, 1)
				local var_10_4 = tonumber(string.sub(iter_10_0, 3, 3))

				if var_10_3 == "A" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.None then
					local var_10_5 = var_0_3.new()

					var_10_5:populate(iter_10_1.hero)
					var_10_5:setReportData(iter_10_1)

					var_9_0.herosA[var_10_4] = var_10_5
				elseif var_10_3 == "A" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.Pet then
					local var_10_6 = var_0_4.new()

					var_10_6:populate(iter_10_1.hero)
					var_10_6:setReportData(iter_10_1)

					var_9_0.petsA = {
						var_10_6
					}
				elseif var_10_3 == "B" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.None then
					local var_10_7 = var_0_3.new()

					var_10_7:populate(iter_10_1.hero)
					var_10_7:setReportData(iter_10_1)

					var_10_1[var_10_4] = var_10_7
				elseif var_10_3 == "B" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.Pet then
					local var_10_8 = var_0_4.new()

					var_10_8:populate(iter_10_1.hero)
					var_10_8:setReportData(iter_10_1)

					var_9_0.petsB = {
						var_10_8
					}
				elseif tonumber(iter_10_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_10_1.summon_type) ~= xyd.summonMonsterType.Pet then
					local var_10_9 = var_0_3.new()

					var_10_9:populate(iter_10_1.hero)
					var_10_9:setReportData(iter_10_1)

					var_10_2[iter_10_0] = var_10_9
				end
			end

			var_9_0.cancleMusic = true
			var_9_0.herosB = {
				var_10_1
			}
			var_9_0.summonMonsters = var_10_2
			var_9_0.reportStar = var_9_1:getBattleStar()

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "arena",
					status = {
						oldBestRank = arg_9_0.oldBestRank
					}
				}
			})
			xyd.WindowManager.get():retainHistory()

			local var_10_10 = {}

			for iter_10_2, iter_10_3 in pairs(var_9_0.responseData.partner_favor) do
				if iter_10_3 > arg_9_0.selfPlayer:getHero(tonumber(iter_10_2)):getFavorDegree() then
					var_10_10[tonumber(iter_10_2)] = true

					arg_9_0.selfPlayer:getHero(tonumber(iter_10_2)):setFavorDegree(iter_10_3)
				end
			end

			var_9_0.favorDegreeUp = var_10_10

			xyd.pushBattleScene(var_9_0)
		end)
		var_9_1:run()
	else
		local var_9_2 = {}

		ngx.ctx.battle.reportData = json.decode(arg_9_0.params.battle_report)
		var_9_2.herosA = {}
		var_9_2.herosB = {}
		var_9_2.summonMonsters = {}
		var_9_2.battleType = xyd.BattleType.ReplayReport
		var_9_2.battleID = xyd.MapBattleID.ARENA
		var_9_2.campaignType = arg_9_0.params.campaignType

		local var_9_3 = {}
		local var_9_4 = {}

		for iter_9_0, iter_9_1 in pairs(ngx.ctx.battle.reportData.fighter) do
			local var_9_5 = string.sub(iter_9_0, 1, 1)
			local var_9_6 = tonumber(string.sub(iter_9_0, 3, 3))

			if var_9_5 == "A" and tonumber(iter_9_1.summon_type) == xyd.summonMonsterType.None then
				local var_9_7 = var_0_3.new()

				var_9_7:populate(iter_9_1.hero)
				var_9_7:setReportData(iter_9_1)

				var_9_2.herosA[var_9_6] = var_9_7
			elseif var_9_5 == "A" and tonumber(iter_9_1.summon_type) == xyd.summonMonsterType.Pet then
				local var_9_8 = var_0_4.new()

				var_9_8:populate(iter_9_1.hero)
				var_9_8:setReportData(iter_9_1)

				var_9_2.petsA = {
					var_9_8
				}
			elseif var_9_5 == "B" and tonumber(iter_9_1.summon_type) == xyd.summonMonsterType.None then
				local var_9_9 = var_0_3.new()

				var_9_9:populate(iter_9_1.hero)
				var_9_9:setReportData(iter_9_1)

				var_9_3[var_9_6] = var_9_9
			elseif var_9_5 == "B" and tonumber(iter_9_1.summon_type) == xyd.summonMonsterType.Pet then
				local var_9_10 = var_0_4.new()

				var_9_10:populate(iter_9_1.hero)
				var_9_10:setReportData(iter_9_1)

				var_9_2.petsB = {
					var_9_10
				}
			elseif tonumber(iter_9_1.summon_type) ~= xyd.summonMonsterType.None then
				local var_9_11 = var_0_3.new()

				var_9_11:populate(iter_9_1.hero)
				var_9_11:setReportData(iter_9_1)

				var_9_4[iter_9_0] = var_9_11
			end
		end

		var_9_2.reportStar = ngx.ctx.battle.reportData.star
		var_9_2.herosB = {
			var_9_3
		}
		var_9_2.summonMonsters = var_9_4

		local var_9_12 = arg_9_0.params.is_win
		local var_9_13 = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = "arena",
				status = {
					oldBestRank = arg_9_0.oldBestRank
				}
			}
		})
		xyd.WindowManager.get():retainHistory()

		local var_9_14 = {}

		for iter_9_2, iter_9_3 in pairs(arg_9_0.params.partner_favor) do
			if iter_9_3 > arg_9_0.selfPlayer:getHero(tonumber(iter_9_2)):getFavorDegree() then
				var_9_14[tonumber(iter_9_2)] = true

				arg_9_0.selfPlayer:getHero(tonumber(iter_9_2)):setFavorDegree(iter_9_3)
			end
		end

		var_9_2.favorDegreeUp = var_9_14
		var_9_2.awards = arg_9_0.params.awards

		xyd.pushBattleScene(var_9_2)
	end
end

function var_0_0.arenaModeReport(arg_11_0)
	local var_11_0 = {}

	ngx.ctx.battle.reportData = json.decode(arg_11_0.params.battle_report)
	var_11_0.herosA = {}
	var_11_0.herosB = {}
	var_11_0.summonMonsters = {}
	var_11_0.battleType = xyd.BattleType.ReplayReport
	var_11_0.battleID = xyd.MapBattleID.ARENA
	var_11_0.campaignType = arg_11_0.params.campaignType

	local var_11_1 = {}
	local var_11_2 = {}

	for iter_11_0, iter_11_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_11_3 = string.sub(iter_11_0, 1, 1)
		local var_11_4 = tonumber(string.sub(iter_11_0, 3, 3))

		if var_11_3 == "A" and tonumber(iter_11_1.summon_type) == xyd.summonMonsterType.None then
			local var_11_5 = var_0_3.new()

			var_11_5:populate(iter_11_1.hero)
			var_11_5:setReportData(iter_11_1)

			var_11_0.herosA[var_11_4] = var_11_5
		elseif var_11_3 == "A" and tonumber(iter_11_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_11_6 = var_0_4.new()

			var_11_6:populate(iter_11_1.hero)
			var_11_6:setReportData(iter_11_1)

			var_11_0.petsA = {
				var_11_6
			}
		elseif var_11_3 == "B" and tonumber(iter_11_1.summon_type) == xyd.summonMonsterType.None then
			local var_11_7 = var_0_3.new()

			var_11_7:populate(iter_11_1.hero)
			var_11_7:setReportData(iter_11_1)

			var_11_1[var_11_4] = var_11_7
		elseif var_11_3 == "B" and tonumber(iter_11_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_11_8 = var_0_4.new()

			var_11_8:populate(iter_11_1.hero)
			var_11_8:setReportData(iter_11_1)

			var_11_0.petsB = {
				var_11_8
			}
		elseif tonumber(iter_11_1.summon_type) ~= xyd.summonMonsterType.None then
			local var_11_9 = var_0_3.new()

			var_11_9:populate(iter_11_1.hero)
			var_11_9:setReportData(iter_11_1)

			var_11_2[iter_11_0] = var_11_9
		end
	end

	var_11_0.reportStar = ngx.ctx.battle.reportData.star
	var_11_0.herosB = {
		var_11_1
	}
	var_11_0.summonMonsters = var_11_2

	local var_11_10 = arg_11_0.params.is_win
	local var_11_11 = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "arena",
			status = {
				oldBestRank = arg_11_0.oldBestRank
			}
		}
	})
	xyd.WindowManager.get():retainHistory()

	local var_11_12 = {}

	for iter_11_2, iter_11_3 in pairs(arg_11_0.params.partner_favor) do
		if iter_11_3 > arg_11_0.selfPlayer:getHero(tonumber(iter_11_2)):getFavorDegree() then
			var_11_12[tonumber(iter_11_2)] = true

			arg_11_0.selfPlayer:getHero(tonumber(iter_11_2)):setFavorDegree(iter_11_3)
		end
	end

	var_11_0.favorDegreeUp = var_11_12

	xyd.pushBattleScene(var_11_0)
end

function var_0_0.lvbuFestivalReport(arg_12_0)
	local var_12_0 = arg_12_0.params
	local var_12_1 = xyd.BattleCreateReport.new(var_12_0)

	var_12_1:addTo(arg_12_0)
	var_12_1:hide()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_12_0):addEventListener(xyd.event.BATTLE_REPORT_CREATE, function(arg_13_0)
		var_12_0.battleType = xyd.BattleType.ReplayReport

		local var_13_0 = var_12_1:writeReport()

		ngx.ctx.battle.reportData = json.decode(var_13_0)
		var_12_0.herosA = {}
		var_12_0.herosB = {}
		var_12_0.summonMonsters = {}

		local var_13_1 = {}
		local var_13_2 = {}

		for iter_13_0, iter_13_1 in pairs(ngx.ctx.battle.reportData.fighter) do
			local var_13_3 = string.sub(iter_13_0, 1, 1)
			local var_13_4 = tonumber(string.sub(iter_13_0, 3, 3))

			if var_13_3 == "A" and tonumber(iter_13_1.summon_type) == xyd.summonMonsterType.None then
				local var_13_5 = var_0_3.new()

				var_13_5:populate(iter_13_1.hero)
				var_13_5:setReportData(iter_13_1)

				var_12_0.herosA[var_13_4] = var_13_5
			elseif var_13_3 == "A" and tonumber(iter_13_1.summon_type) == xyd.summonMonsterType.Pet then
				local var_13_6 = var_0_4.new()

				var_13_6:populate(iter_13_1.hero)
				var_13_6:setReportData(iter_13_1)

				var_12_0.petsA = {
					var_13_6
				}
			elseif var_13_3 == "B" and tonumber(iter_13_1.summon_type) == xyd.summonMonsterType.None then
				local var_13_7 = var_0_3.new()

				var_13_7:populate(iter_13_1.hero)
				var_13_7:setReportData(iter_13_1)

				var_13_1[var_13_4] = var_13_7
			elseif var_13_3 == "B" and tonumber(iter_13_1.summon_type) == xyd.summonMonsterType.Pet then
				local var_13_8 = var_0_4.new()

				var_13_8:populate(iter_13_1.hero)
				var_13_8:setReportData(iter_13_1)

				var_12_0.petsB = {
					var_13_8
				}
			elseif tonumber(iter_13_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_13_1.summon_type) ~= xyd.summonMonsterType.Pet then
				local var_13_9 = var_0_3.new()

				var_13_9:populate(iter_13_1.hero)
				var_13_9:setReportData(iter_13_1)

				var_13_2[iter_13_0] = var_13_9
			end
		end

		var_12_0.cancleMusic = true
		var_12_0.herosB = {
			var_13_1
		}
		var_12_0.summonMonsters = var_13_2
		var_12_0.reportStar = var_12_1:getBattleStar()

		xyd.WindowManager.get():retainHistory()
		xyd.pushBattleScene(var_12_0)
	end)
	var_12_1:run()
end

function var_0_0.regionArenaReport(arg_14_0)
	local var_14_0 = arg_14_0.params
	local var_14_1 = xyd.BattleCreateReport.new(var_14_0)

	var_14_1:addTo(arg_14_0)
	var_14_1:hide()

	if arg_14_0.params.isBackendBattle == 0 then
		cc.EventProxy.new(xyd.EventDispatcher.get(), arg_14_0):addEventListener(xyd.event.BATTLE_REPORT_CREATE, function(arg_15_0)
			var_14_0.responseData = arg_15_0.response
			var_14_0.battleType = xyd.BattleType.ReplayReport

			local var_15_0 = var_14_1:writeReport()

			ngx.ctx.battle.reportData = json.decode(var_15_0)
			var_14_0.herosA = {}
			var_14_0.herosB = {}
			var_14_0.summonMonsters = {}

			local var_15_1 = {}
			local var_15_2 = {}

			for iter_15_0, iter_15_1 in pairs(ngx.ctx.battle.reportData.fighter) do
				local var_15_3 = string.sub(iter_15_0, 1, 1)
				local var_15_4 = tonumber(string.sub(iter_15_0, 3, 3))

				if var_15_3 == "A" and tonumber(iter_15_1.summon_type) == xyd.summonMonsterType.None then
					local var_15_5 = var_0_3.new()

					var_15_5:populate(iter_15_1.hero)
					var_15_5:setReportData(iter_15_1)

					var_14_0.herosA[var_15_4] = var_15_5
				elseif var_15_3 == "A" and tonumber(iter_15_1.summon_type) == xyd.summonMonsterType.Pet then
					local var_15_6 = var_0_4.new()

					var_15_6:populate(iter_15_1.hero)
					var_15_6:setReportData(iter_15_1)

					var_14_0.petsA = {
						var_15_6
					}
				elseif var_15_3 == "B" and tonumber(iter_15_1.summon_type) == xyd.summonMonsterType.None then
					local var_15_7 = var_0_3.new()

					var_15_7:populate(iter_15_1.hero)
					var_15_7:setReportData(iter_15_1)

					var_15_1[var_15_4] = var_15_7
				elseif var_15_3 == "B" and tonumber(iter_15_1.summon_type) == xyd.summonMonsterType.Pet then
					local var_15_8 = var_0_4.new()

					var_15_8:populate(iter_15_1.hero)
					var_15_8:setReportData(iter_15_1)

					var_14_0.petsB = {
						var_15_8
					}
				elseif tonumber(iter_15_1.summon_type) ~= xyd.summonMonsterType.None then
					local var_15_9 = var_0_3.new()

					var_15_9:populate(iter_15_1.hero)
					var_15_9:setReportData(iter_15_1)

					var_15_2[iter_15_0] = var_15_9
				end
			end

			var_14_0.cancleMusic = true
			var_14_0.herosB = {
				var_15_1
			}
			var_14_0.summonMonsters = var_15_2
			var_14_0.reportStar = var_14_1:getBattleStar()

			local var_15_10 = var_14_0.reportStar > 0
			local var_15_11 = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "region_arena",
					status = {
						mode = arg_14_0.params.isRegionArenaTest,
						oldStar = arg_14_0.params.oldStar,
						newStar = var_15_11:getStar(),
						isWin = var_15_10
					}
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_14_0)
		end)
		var_14_1:run()
	else
		var_14_0.battleType = xyd.BattleType.ReplayReport

		local var_14_2 = arg_14_0.params.battleReport

		ngx.ctx.battle.reportData = json.decode(var_14_2)
		var_14_0.herosA = {}
		var_14_0.herosB = {}
		var_14_0.petsB = {}
		var_14_0.petsA = {}
		var_14_0.summonMonsters = {}

		local var_14_3 = {}
		local var_14_4 = {}

		for iter_14_0, iter_14_1 in pairs(ngx.ctx.battle.reportData.fighter) do
			local var_14_5 = string.sub(iter_14_0, 1, 1)
			local var_14_6 = tonumber(string.sub(iter_14_0, 3, 3))

			if var_14_5 == "A" and tonumber(iter_14_1.summon_type) == xyd.summonMonsterType.None then
				local var_14_7 = var_0_3.new()

				var_14_7:populate(iter_14_1.hero)
				var_14_7:setReportData(iter_14_1)

				var_14_0.herosA[var_14_6] = var_14_7
			elseif var_14_5 == "A" and tonumber(iter_14_1.summon_type) == xyd.summonMonsterType.Pet then
				local var_14_8 = var_0_4.new()

				var_14_8:populate(iter_14_1.hero)
				var_14_8:setReportData(iter_14_1)

				var_14_0.petsA = {
					var_14_8
				}
			elseif var_14_5 == "B" and tonumber(iter_14_1.summon_type) == xyd.summonMonsterType.None then
				local var_14_9 = var_0_3.new()

				var_14_9:populate(iter_14_1.hero)
				var_14_9:setReportData(iter_14_1)

				var_14_3[var_14_6] = var_14_9
			elseif var_14_5 == "B" and tonumber(iter_14_1.summon_type) == xyd.summonMonsterType.Pet then
				local var_14_10 = var_0_4.new()

				var_14_10:populate(iter_14_1.hero)
				var_14_10:setReportData(iter_14_1)

				var_14_0.petsB = {
					var_14_10
				}
			elseif tonumber(iter_14_1.summon_type) ~= xyd.summonMonsterType.None then
				local var_14_11 = var_0_3.new()

				var_14_11:populate(iter_14_1.hero)
				var_14_11:setReportData(iter_14_1)

				var_14_4[iter_14_0] = var_14_11
			end
		end

		var_14_0.cancleMusic = true
		var_14_0.herosB = {
			var_14_3
		}
		var_14_0.summonMonsters = var_14_4
		var_14_0.reportStar = ngx.ctx.battle.reportData.star

		local var_14_12
		local var_14_13 = var_14_0.is_win == 1 and true or false
		local var_14_14 = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = "region_arena",
				status = {
					mode = arg_14_0.params.isRegionArenaTest,
					oldStar = arg_14_0.params.oldStar,
					newStar = var_14_14:getStar(),
					isWin = var_14_13
				}
			}
		})
		xyd.WindowManager.get():retainHistory()
		xyd.pushBattleScene(var_14_0)
	end
end

function var_0_0.superArenaReport(arg_16_0)
	local var_16_0 = arg_16_0.params

	arg_16_0.peakArena = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA)

	local var_16_1 = xyd.BattleCreateReport.new(var_16_0)

	var_16_1:addTo(arg_16_0)
	var_16_1:hide()

	if not arg_16_0.params.reports then
		cc.EventProxy.new(xyd.EventDispatcher.get(), arg_16_0):addEventListener(xyd.event.BATTLE_REPORT_CREATE, function(arg_17_0)
			var_16_0.battleType = xyd.BattleType.ReplayReport
			var_16_0.responseData = arg_17_0.response
			var_16_0.herosA = {
				team1 = {},
				team2 = {},
				team3 = {},
				pet1 = {},
				pet2 = {},
				pet3 = {}
			}
			var_16_0.herosB = {
				team1 = {},
				team2 = {},
				team3 = {},
				pet1 = {},
				pet2 = {},
				pet3 = {}
			}
			var_16_0.summonMonsters = {
				team1 = {},
				team2 = {},
				team3 = {}
			}
			var_16_0.reportStar = {}

			for iter_17_0 = 1, 3 do
				local var_17_0 = arg_16_0.peakArena:getBattleReport(iter_17_0)

				ngx.ctx.battle.reportData = json.decode(var_17_0)

				if not ngx.ctx.battle.reportData then
					break
				end

				local var_17_1 = {}
				local var_17_2 = {}
				local var_17_3 = {}
				local var_17_4 = {}
				local var_17_5 = {}
				local var_17_6 = {}

				for iter_17_1, iter_17_2 in pairs(ngx.ctx.battle.reportData.fighter) do
					local var_17_7 = string.sub(iter_17_1, 1, 1)
					local var_17_8 = tonumber(string.sub(iter_17_1, 3, 3))

					if var_17_7 == "A" and tonumber(iter_17_2.summon_type) == xyd.summonMonsterType.None then
						local var_17_9 = var_0_3.new()

						var_17_9:populate(iter_17_2.hero)
						var_17_9:setReportData(iter_17_2)

						var_17_1[var_17_8] = var_17_9
					elseif var_17_7 == "A" and tonumber(iter_17_2.summon_type) == xyd.summonMonsterType.Pet then
						local var_17_10 = var_0_4.new()

						var_17_10:populate(iter_17_2.hero)
						var_17_10:setReportData(iter_17_2)

						var_16_0.petsA = {
							var_17_10
						}
						var_17_5 = {
							var_17_10
						}
					elseif var_17_7 == "B" and tonumber(iter_17_2.summon_type) == xyd.summonMonsterType.None then
						local var_17_11 = var_0_3.new()

						var_17_11:populate(iter_17_2.hero)
						var_17_11:setReportData(iter_17_2)

						var_17_2[var_17_8] = var_17_11
					elseif var_17_7 == "B" and tonumber(iter_17_2.summon_type) == xyd.summonMonsterType.Pet then
						local var_17_12 = var_0_4.new()

						var_17_12:populate(iter_17_2.hero)
						var_17_12:setReportData(iter_17_2)

						var_16_0.petsB = {
							var_17_12
						}
						var_17_6 = {
							var_17_12
						}
					elseif tonumber(iter_17_2.summon_type) ~= xyd.summonMonsterType.None then
						local var_17_13 = var_0_3.new()

						var_17_13:populate(iter_17_2.hero)
						var_17_13:setReportData(iter_17_2)

						var_17_3[iter_17_1] = var_17_13
					end
				end

				var_16_0.herosA["team" .. iter_17_0] = var_17_1
				var_16_0.herosB["team" .. iter_17_0] = var_17_2
				var_16_0.herosA["pet" .. iter_17_0] = var_17_5
				var_16_0.herosB["pet" .. iter_17_0] = var_17_6
				var_16_0.summonMonsters["team" .. iter_17_0] = var_17_3
				var_16_0.reportStar["team" .. iter_17_0] = arg_16_0.peakArena:getBattleResult(iter_17_0)
			end

			var_16_0.cancleMusic = true

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "peak_arena"
				}
			})
			xyd.WindowManager.get():retainHistory()

			local var_17_14 = {}

			for iter_17_3, iter_17_4 in pairs(var_16_0.responseData.partner_favor) do
				if iter_17_4 > arg_16_0.selfPlayer:getHero(tonumber(iter_17_3)):getFavorDegree() then
					var_17_14[tonumber(iter_17_3)] = true

					arg_16_0.selfPlayer:getHero(tonumber(iter_17_3)):setFavorDegree(iter_17_4)
				end
			end

			var_16_0.favorDegreeUp = var_17_14

			xyd.pushBattleScene(var_16_0)
		end)
		var_16_1:run()
	end
end

function var_0_0.getTip(arg_18_0)
	math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))

	local var_18_0 = math.random(var_0_5:tipNum())

	arg_18_0.tipText = var_0_5:tip(var_18_0)

	return arg_18_0.tipText
end

function var_0_0.setupMusic(arg_19_0)
	audio.stopMusic()
	audio.stopAllSounds()

	local var_19_0
	local var_19_1 = xyd.tables.battle:sounds(arg_19_0.battleID)

	if arg_19_0.campaignType ~= xyd.CampaignType.ARENA and arg_19_0.campaignType ~= xyd.CampaignType.SUPER_ARENA and arg_19_0.campaignType ~= xyd.CampaignType.MARCH then
		var_19_1 = xyd.tables.sound:getSound("battle_bg_music_1")
	end

	var_19_1 = (not var_19_1 or var_19_1 ~= "") and var_19_1 or xyd.tables.sound:getSound("battle_bg_music_1")

	audio.preloadMusic(var_19_1)
	audio.playMusic(var_19_1, true)
end

return var_0_0
