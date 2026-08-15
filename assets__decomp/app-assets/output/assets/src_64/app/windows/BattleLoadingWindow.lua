local var_0_0 = class("BattleLoadingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = require("framework.scheduler")
local var_0_3 = import("app.model.Hero")
local var_0_4 = import("app.model.Pet")
local var_0_5 = xyd.tables.loadingTip
local var_0_6 = xyd.tables.translation
local var_0_7 = 6

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.params = arg_1_2
	arg_1_0.battleID = arg_1_2.battleID or 0
	arg_1_0.campaignType = arg_1_2.campaignType
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 0))
	arg_3_0:layout()
	arg_3_0:scheduleHandler()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_tip"):setString(arg_4_0:getTip())
	arg_4_0:nodeByName("text_loading"):setString(var_0_6:translation("BATTLE_LOADING"))
	math.randomseed(tonumber(tostring(os.clock() * 1000):reverse():sub(1, 6)))

	local var_4_0 = 3
	local var_4_1 = "images/battle/battle_loading_background_" .. var_4_0 .. ".png"

	arg_4_0.img = xyd.AssetLoader.get():loadSprite(var_4_1)

	arg_4_0.img:addTo(arg_4_0, -1)
	arg_4_0.img:align(display.LEFT_BOTTOM, 0, 0)

	local var_4_2 = arg_4_0:nodeByName("effect_container")

	if not arg_4_0.effect_ then
		local var_4_3 = "skeletons/ui_effect/battle_loading/battle_loading"
		local var_4_4 = var_4_3 .. ".json"
		local var_4_5 = var_4_3 .. ".atlas"

		arg_4_0.effect_ = var_0_1.new(var_4_4, var_4_5, 1)

		arg_4_0.effect_:align(display.CENTER, var_4_2:getWidth() / 2, var_4_2:getHeight() / 2)
		arg_4_0.effect_:addTo(var_4_2)
	end

	arg_4_0.effect_:play(nil, true)
end

function var_0_0.scheduleHandler(arg_5_0)
	arg_5_0:setupMusic()

	arg_5_0.handler = var_0_2.scheduleUpdateGlobal(handler(arg_5_0, arg_5_0.loop))
end

function var_0_0.loop(arg_6_0)
	arg_6_0.count = arg_6_0.count or 0

	if arg_6_0.count < 1 then
		arg_6_0.count = arg_6_0.count + 1
	else
		if arg_6_0.params.campaignType == xyd.CampaignType.ARENA then
			arg_6_0:arenaReport()
		elseif arg_6_0.params.campaignType == xyd.CampaignType.LVBU_FESTIVAL then
			arg_6_0:lvbuFestivalReport()
		elseif arg_6_0.params.campaignType == xyd.CampaignType.SUPER_ARENA then
			arg_6_0:superArenaReport()
		elseif arg_6_0.params.campaignType == xyd.CampaignType.REGION_ARENA then
			arg_6_0:regionArenaReport()
		end

		if arg_6_0.handler ~= nil then
			var_0_2.unscheduleGlobal(arg_6_0.handler)

			arg_6_0.handler = nil
		end
	end
end

function var_0_0.arenaReport(arg_7_0)
	local var_7_0 = arg_7_0.params
	local var_7_1 = xyd.BattleCreateReport.new(var_7_0)

	var_7_1:addTo(arg_7_0)
	var_7_1:hide()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.BATTLE_REPORT_CREATE, function(arg_8_0)
		var_7_0.responseData = arg_8_0.response
		var_7_0.battleType = xyd.BattleType.ReplayReport

		local var_8_0 = var_7_1:writeReport()

		ngx.ctx.battle.reportData = json.decode(var_8_0)
		var_7_0.herosA = {}
		var_7_0.herosB = {}
		var_7_0.summonMonsters = {}

		local var_8_1 = {}
		local var_8_2 = {}

		for iter_8_0, iter_8_1 in pairs(ngx.ctx.battle.reportData.fighter) do
			local var_8_3 = string.sub(iter_8_0, 1, 1)
			local var_8_4 = tonumber(string.sub(iter_8_0, 3, 3))

			if var_8_3 == "A" and tonumber(iter_8_1.summon_type) == xyd.summonMonsterType.None then
				local var_8_5 = var_0_3.new()

				var_8_5:populate(iter_8_1.hero)
				var_8_5:setReportData(iter_8_1)

				var_7_0.herosA[var_8_4] = var_8_5
			elseif var_8_3 == "A" and tonumber(iter_8_1.summon_type) == xyd.summonMonsterType.Pet then
				local var_8_6 = var_0_4.new()

				var_8_6:populate(iter_8_1.hero)
				var_8_6:setReportData(iter_8_1)

				var_7_0.petsA = {
					var_8_6
				}
			elseif var_8_3 == "B" and tonumber(iter_8_1.summon_type) == xyd.summonMonsterType.None then
				local var_8_7 = var_0_3.new()

				var_8_7:populate(iter_8_1.hero)
				var_8_7:setReportData(iter_8_1)

				var_8_1[var_8_4] = var_8_7
			elseif var_8_3 == "B" and tonumber(iter_8_1.summon_type) == xyd.summonMonsterType.Pet then
				local var_8_8 = var_0_4.new()

				var_8_8:populate(iter_8_1.hero)
				var_8_8:setReportData(iter_8_1)

				var_7_0.petsB = {
					var_8_8
				}
			elseif tonumber(iter_8_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_8_1.summon_type) ~= xyd.summonMonsterType.Pet then
				local var_8_9 = var_0_3.new()

				var_8_9:populate(iter_8_1.hero)
				var_8_9:setReportData(iter_8_1)

				var_8_2[iter_8_0] = var_8_9
			end
		end

		var_7_0.cancleMusic = true
		var_7_0.herosB = {
			var_8_1
		}
		var_7_0.summonMonsters = var_8_2
		var_7_0.reportStar = var_7_1:getBattleStar()

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = "arena",
				status = {
					oldBestRank = arg_7_0.oldBestRank
				}
			}
		})
		xyd.WindowManager.get():retainHistory()

		local var_8_10 = {}

		for iter_8_2, iter_8_3 in pairs(var_7_0.responseData.partner_favor) do
			if iter_8_3 > arg_7_0.selfPlayer:getHero(tonumber(iter_8_2)):getFavorDegree() then
				var_8_10[tonumber(iter_8_2)] = true

				arg_7_0.selfPlayer:getHero(tonumber(iter_8_2)):setFavorDegree(iter_8_3)
			end
		end

		var_7_0.favorDegreeUp = var_8_10

		xyd.pushBattleScene(var_7_0)
	end)
	var_7_1:run()
end

function var_0_0.lvbuFestivalReport(arg_9_0)
	local var_9_0 = arg_9_0.params
	local var_9_1 = xyd.BattleCreateReport.new(var_9_0)

	var_9_1:addTo(arg_9_0)
	var_9_1:hide()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_9_0):addEventListener(xyd.event.BATTLE_REPORT_CREATE, function(arg_10_0)
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

		xyd.WindowManager.get():retainHistory()
		xyd.pushBattleScene(var_9_0)
	end)
	var_9_1:run()
end

function var_0_0.regionArenaReport(arg_11_0)
	local var_11_0 = arg_11_0.params
	local var_11_1 = xyd.BattleCreateReport.new(var_11_0)

	var_11_1:addTo(arg_11_0)
	var_11_1:hide()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_11_0):addEventListener(xyd.event.BATTLE_REPORT_CREATE, function(arg_12_0)
		var_11_0.responseData = arg_12_0.response
		var_11_0.battleType = xyd.BattleType.ReplayReport

		local var_12_0 = var_11_1:writeReport()

		ngx.ctx.battle.reportData = json.decode(var_12_0)
		var_11_0.herosA = {}
		var_11_0.herosB = {}
		var_11_0.summonMonsters = {}

		local var_12_1 = {}
		local var_12_2 = {}

		for iter_12_0, iter_12_1 in pairs(ngx.ctx.battle.reportData.fighter) do
			local var_12_3 = string.sub(iter_12_0, 1, 1)
			local var_12_4 = tonumber(string.sub(iter_12_0, 3, 3))

			if var_12_3 == "A" and tonumber(iter_12_1.summon_type) == xyd.summonMonsterType.None then
				local var_12_5 = var_0_3.new()

				var_12_5:populate(iter_12_1.hero)
				var_12_5:setReportData(iter_12_1)

				var_11_0.herosA[var_12_4] = var_12_5
			elseif var_12_3 == "A" and tonumber(iter_12_1.summon_type) == xyd.summonMonsterType.Pet then
				local var_12_6 = var_0_4.new()

				var_12_6:populate(iter_12_1.hero)
				var_12_6:setReportData(iter_12_1)

				var_11_0.petsA = {
					var_12_6
				}
			elseif var_12_3 == "B" and tonumber(iter_12_1.summon_type) == xyd.summonMonsterType.None then
				local var_12_7 = var_0_3.new()

				var_12_7:populate(iter_12_1.hero)
				var_12_7:setReportData(iter_12_1)

				var_12_1[var_12_4] = var_12_7
			elseif var_12_3 == "B" and tonumber(iter_12_1.summon_type) == xyd.summonMonsterType.Pet then
				local var_12_8 = var_0_4.new()

				var_12_8:populate(iter_12_1.hero)
				var_12_8:setReportData(iter_12_1)

				var_11_0.petsB = {
					var_12_8
				}
			elseif tonumber(iter_12_1.summon_type) ~= xyd.summonMonsterType.None then
				local var_12_9 = var_0_3.new()

				var_12_9:populate(iter_12_1.hero)
				var_12_9:setReportData(iter_12_1)

				var_12_2[iter_12_0] = var_12_9
			end
		end

		var_11_0.cancleMusic = true
		var_11_0.herosB = {
			var_12_1
		}
		var_11_0.summonMonsters = var_12_2
		var_11_0.reportStar = var_11_1:getBattleStar()

		local var_12_10 = var_11_0.reportStar > 0
		local var_12_11 = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = "region_arena",
				status = {
					mode = arg_11_0.params.isRegionArenaTest,
					oldStar = arg_11_0.params.oldStar,
					newStar = var_12_11:getStar(),
					isWin = var_12_10
				}
			}
		})
		xyd.WindowManager.get():retainHistory()
		xyd.pushBattleScene(var_11_0)
	end)
	var_11_1:run()
end

function var_0_0.superArenaReport(arg_13_0)
	local var_13_0 = arg_13_0.params

	arg_13_0.peakArena = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA)

	local var_13_1 = xyd.BattleCreateReport.new(var_13_0)

	var_13_1:addTo(arg_13_0)
	var_13_1:hide()

	if not arg_13_0.params.reports then
		cc.EventProxy.new(xyd.EventDispatcher.get(), arg_13_0):addEventListener(xyd.event.BATTLE_REPORT_CREATE, function(arg_14_0)
			var_13_0.battleType = xyd.BattleType.ReplayReport
			var_13_0.responseData = arg_14_0.response
			var_13_0.herosA = {
				team1 = {},
				team2 = {},
				team3 = {},
				pet1 = {},
				pet2 = {},
				pet3 = {}
			}
			var_13_0.herosB = {
				team1 = {},
				team2 = {},
				team3 = {},
				pet1 = {},
				pet2 = {},
				pet3 = {}
			}
			var_13_0.summonMonsters = {
				team1 = {},
				team2 = {},
				team3 = {}
			}
			var_13_0.reportStar = {}

			for iter_14_0 = 1, 3 do
				local var_14_0 = arg_13_0.peakArena:getBattleReport(iter_14_0)

				ngx.ctx.battle.reportData = json.decode(var_14_0)

				if not ngx.ctx.battle.reportData then
					break
				end

				local var_14_1 = {}
				local var_14_2 = {}
				local var_14_3 = {}
				local var_14_4 = {}
				local var_14_5 = {}
				local var_14_6 = {}

				for iter_14_1, iter_14_2 in pairs(ngx.ctx.battle.reportData.fighter) do
					local var_14_7 = string.sub(iter_14_1, 1, 1)
					local var_14_8 = tonumber(string.sub(iter_14_1, 3, 3))

					if var_14_7 == "A" and tonumber(iter_14_2.summon_type) == xyd.summonMonsterType.None then
						local var_14_9 = var_0_3.new()

						var_14_9:populate(iter_14_2.hero)
						var_14_9:setReportData(iter_14_2)

						var_14_1[var_14_8] = var_14_9
					elseif var_14_7 == "A" and tonumber(iter_14_2.summon_type) == xyd.summonMonsterType.Pet then
						local var_14_10 = var_0_4.new()

						var_14_10:populate(iter_14_2.hero)
						var_14_10:setReportData(iter_14_2)

						var_13_0.petsA = {
							var_14_10
						}
						var_14_5 = {
							var_14_10
						}
					elseif var_14_7 == "B" and tonumber(iter_14_2.summon_type) == xyd.summonMonsterType.None then
						local var_14_11 = var_0_3.new()

						var_14_11:populate(iter_14_2.hero)
						var_14_11:setReportData(iter_14_2)

						var_14_2[var_14_8] = var_14_11
					elseif var_14_7 == "B" and tonumber(iter_14_2.summon_type) == xyd.summonMonsterType.Pet then
						local var_14_12 = var_0_4.new()

						var_14_12:populate(iter_14_2.hero)
						var_14_12:setReportData(iter_14_2)

						var_13_0.petsB = {
							var_14_12
						}
						var_14_6 = {
							var_14_12
						}
					elseif tonumber(iter_14_2.summon_type) ~= xyd.summonMonsterType.None then
						local var_14_13 = var_0_3.new()

						var_14_13:populate(iter_14_2.hero)
						var_14_13:setReportData(iter_14_2)

						var_14_3[iter_14_1] = var_14_13
					end
				end

				var_13_0.herosA["team" .. iter_14_0] = var_14_1
				var_13_0.herosB["team" .. iter_14_0] = var_14_2
				var_13_0.herosA["pet" .. iter_14_0] = var_14_5
				var_13_0.herosB["pet" .. iter_14_0] = var_14_6
				var_13_0.summonMonsters["team" .. iter_14_0] = var_14_3
				var_13_0.reportStar["team" .. iter_14_0] = arg_13_0.peakArena:getBattleResult(iter_14_0)
			end

			var_13_0.cancleMusic = true

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "peak_arena"
				}
			})
			xyd.WindowManager.get():retainHistory()

			local var_14_14 = {}

			for iter_14_3, iter_14_4 in pairs(var_13_0.responseData.partner_favor) do
				if iter_14_4 > arg_13_0.selfPlayer:getHero(tonumber(iter_14_3)):getFavorDegree() then
					var_14_14[tonumber(iter_14_3)] = true

					arg_13_0.selfPlayer:getHero(tonumber(iter_14_3)):setFavorDegree(iter_14_4)
				end
			end

			var_13_0.favorDegreeUp = var_14_14

			xyd.pushBattleScene(var_13_0)
		end)
		var_13_1:run()
	else
		var_13_0.battleType = xyd.BattleType.ReplayReport
		var_13_0.reportStar = {}
		var_13_0.herosA = {
			team1 = {},
			team2 = {},
			team3 = {},
			pet1 = {},
			pet2 = {},
			pet3 = {}
		}
		var_13_0.herosB = {
			team1 = {},
			team2 = {},
			team3 = {},
			pet1 = {},
			pet2 = {},
			pet3 = {}
		}
		var_13_0.summonMonsters = {
			team1 = {},
			team2 = {},
			team3 = {}
		}

		for iter_13_0 = 1, #arg_13_0.params.reports do
			local var_13_2

			if arg_13_0.params.reports[iter_13_0] and arg_13_0.params.reports[iter_13_0].content then
				var_13_2 = arg_13_0.params.reports[iter_13_0].content
			else
				var_13_2 = arg_13_0.params.reports[iter_13_0]
			end

			arg_13_0.peakArena:setBattleReport(iter_13_0, var_13_2)

			local var_13_3 = arg_13_0.peakArena:setBattleResult(iter_13_0, arg_13_0.params.stars[iter_13_0])
			local var_13_4 = arg_13_0.peakArena:getBattleReport(iter_13_0)

			ngx.ctx.battle.reportData = json.decode(var_13_4)

			if not ngx.ctx.battle.reportData then
				break
			end

			local var_13_5 = {}
			local var_13_6 = {}
			local var_13_7 = {}
			local var_13_8 = {}
			local var_13_9 = {}
			local var_13_10 = {}

			for iter_13_1, iter_13_2 in pairs(ngx.ctx.battle.reportData.fighter) do
				local var_13_11 = string.sub(iter_13_1, 1, 1)
				local var_13_12 = tonumber(string.sub(iter_13_1, 3, 3))

				if var_13_11 == "A" and tonumber(iter_13_2.summon_type) == xyd.summonMonsterType.None then
					local var_13_13 = var_0_3.new()

					var_13_13:populate(iter_13_2.hero)
					var_13_13:setReportData(iter_13_2)

					var_13_5[var_13_12] = var_13_13
				elseif var_13_11 == "A" and tonumber(iter_13_2.summon_type) == xyd.summonMonsterType.Pet then
					local var_13_14 = var_0_4.new()

					var_13_14:populate(iter_13_2.hero)
					var_13_14:setReportData(iter_13_2)

					var_13_0.petsA = {
						var_13_14
					}
					var_13_9 = {
						var_13_14
					}
				elseif var_13_11 == "B" and tonumber(iter_13_2.summon_type) == xyd.summonMonsterType.None then
					local var_13_15 = var_0_3.new()

					var_13_15:populate(iter_13_2.hero)
					var_13_15:setReportData(iter_13_2)

					var_13_6[var_13_12] = var_13_15
				elseif var_13_11 == "B" and tonumber(iter_13_2.summon_type) == xyd.summonMonsterType.Pet then
					local var_13_16 = var_0_4.new()

					var_13_16:populate(iter_13_2.hero)
					var_13_16:setReportData(iter_13_2)

					var_13_0.petsB = {
						var_13_16
					}
					var_13_10 = {
						var_13_16
					}
				elseif tonumber(iter_13_2.summon_type) ~= xyd.summonMonsterType.None then
					local var_13_17 = var_0_3.new()

					var_13_17:populate(iter_13_2.hero)
					var_13_17:setReportData(iter_13_2)

					var_13_7[iter_13_1] = var_13_17
				end
			end

			var_13_0.herosA["team" .. iter_13_0] = var_13_5
			var_13_0.herosB["team" .. iter_13_0] = var_13_6
			var_13_0.herosA["pet" .. iter_13_0] = var_13_9
			var_13_0.herosB["pet" .. iter_13_0] = var_13_10
			var_13_0.summonMonsters["team" .. iter_13_0] = var_13_7
			var_13_0.reportStar["team" .. iter_13_0] = arg_13_0.peakArena:getBattleResult(iter_13_0)
		end

		var_13_0.cancleMusic = true

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = "peak_arena"
			}
		})
		xyd.WindowManager.get():retainHistory()

		local var_13_18 = {}

		for iter_13_3, iter_13_4 in pairs(arg_13_0.params.partner_favor) do
			if iter_13_4 > arg_13_0.selfPlayer:getHero(tonumber(iter_13_3)):getFavorDegree() then
				var_13_18[tonumber(iter_13_3)] = true

				arg_13_0.selfPlayer:getHero(tonumber(iter_13_3)):setFavorDegree(iter_13_4)
			end
		end

		var_13_0.favorDegreeUp = var_13_18

		xyd.pushBattleScene(var_13_0)
	end
end

function var_0_0.getTip(arg_15_0)
	math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))

	local var_15_0 = math.random(var_0_5:tipNum())

	arg_15_0.tipText = var_0_5:tip(var_15_0)

	return arg_15_0.tipText
end

function var_0_0.setupMusic(arg_16_0)
	audio.stopMusic()
	audio.stopAllSounds()

	local var_16_0
	local var_16_1 = xyd.tables.battle:sounds(arg_16_0.battleID)

	if arg_16_0.campaignType ~= xyd.CampaignType.ARENA and arg_16_0.campaignType ~= xyd.CampaignType.SUPER_ARENA and arg_16_0.campaignType ~= xyd.CampaignType.MARCH then
		var_16_1 = xyd.tables.sound:getSound("battle_bg_music_1")
	end

	var_16_1 = (not var_16_1 or var_16_1 ~= "") and var_16_1 or xyd.tables.sound:getSound("battle_bg_music_1")

	audio.preloadMusic(var_16_1)
	audio.playMusic(var_16_1, true)
end

return var_0_0
