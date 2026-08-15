local var_0_0 = class("SelectTeamNewWindow", import("app.windows.BaseSelectTeamNewWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc
local var_0_5 = xyd.tables.hero
local var_0_6 = 28
local var_0_7 = tonumber(var_0_4:getValue("arena_preparation_time"))
local var_0_8 = {
	YES = 2,
	NO = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.sealHeroID = arg_1_2.sealHeroID or 0
	arg_1_0.enemyHeroes_ = arg_1_2.enemyHeroes
	arg_1_0.enemyPets_ = arg_1_2.enemyPets
	arg_1_0.enemyID_ = arg_1_2.enemyID
	arg_1_0.fighterInfo = arg_1_2.fighterInfo
	arg_1_0.bannedHeros = arg_1_2.bannedHeros or {}
	arg_1_0.banPet = arg_1_2.banPet
	arg_1_0.noPreset = arg_1_2.noPreset
	arg_1_0.phantoms = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.super.willOpen(arg_2_0, arg_2_1)

	if arg_2_0.type == xyd.SelectTeamType.ARENA or arg_2_0.type == xyd.SelectTeamType.ARENA_MODE then
		arg_2_0.startTime = xyd.ServerTime.get():getServerTime()

		arg_2_0:startTimer()
	end
end

function var_0_0.initPreHeros(arg_3_0, arg_3_1)
	if arg_3_0.selectSpType == xyd.SelectSpType.PHANTOM and arg_3_0.preSelect_ and arg_3_0.preHeros_ then
		for iter_3_0, iter_3_1 in pairs(arg_3_0.preHeros_) do
			for iter_3_2 = 2, 5 do
				local var_3_0, var_3_1 = arg_3_0:nodeByName("avatar" .. iter_3_2):getPosition()
				local var_3_2 = arg_3_0:initBottomCell(iter_3_1)

				var_3_2.iniCell_ = cell

				var_3_2:pos(var_3_0, var_3_1 - 13)
				var_3_2:addTo(arg_3_0)
				var_3_2:setTouchEnabled(false)
				var_3_2:getChildByName("layout"):getChildByName("hero_lock"):setVisible(true)
				table.insert(arg_3_0.phantoms, var_3_2)
			end

			break
		end
	end

	arg_3_0.super.initPreHeros(arg_3_0, arg_3_1)
end

function var_0_0.getBattleBtn(arg_4_0)
	if not arg_4_0.battlepetBtn_ then
		if arg_4_0.type == xyd.SelectTeamType.ARENA_DEFENSE then
			arg_4_0.battlepetBtn_ = arg_4_0:nodeByName("button_ok")

			arg_4_0.battlepetBtn_:addTouchEventListener(function(arg_5_0, arg_5_1)
				xyd.buttonScaleAnim(arg_4_0.battlepetBtn_, arg_5_1)

				if #arg_4_0.select_ < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("BATTLE_NO_HERO")
					})

					return
				end

				if arg_5_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()

					local var_5_0 = {
						defenseHeroes = arg_4_0.select_
					}

					if #arg_4_0.petTeam_ ~= 0 then
						var_5_0.pet_id = arg_4_0.petTeam_[1].data:getPetID()
					else
						var_5_0.pet_id = 0
					end

					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.ARENA_DEFENSE_UPDATE,
						params = var_5_0
					})
					xyd.WindowManager.get():closeWindow(arg_4_0)
				end
			end)
			arg_4_0.battlepetBtn_:setVisible(true)
			arg_4_0:nodeByName("button_battle"):setVisible(false)
		elseif arg_4_0.type == xyd.SelectTeamType.ARENA_MODE_DEFENSE then
			arg_4_0.battlepetBtn_ = arg_4_0:nodeByName("button_ok")

			arg_4_0.battlepetBtn_:addTouchEventListener(function(arg_6_0, arg_6_1)
				xyd.buttonScaleAnim(arg_4_0.battlepetBtn_, arg_6_1)

				if #arg_4_0.select_ < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("BATTLE_NO_HERO")
					})

					return
				end

				if arg_6_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()

					local function var_6_0(arg_7_0)
						xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA):saveModeDefenderData(arg_7_0, function()
							local var_8_0 = xyd.WindowManager.get():getWindow("arena")

							if var_8_0 then
								var_8_0:loadMHeroListView()
							end

							xyd.WindowManager.get():closeWindow(arg_4_0)
						end)
					end

					local var_6_1 = {
						defenseHeroes = arg_4_0.select_
					}

					if #arg_4_0.petTeam_ ~= 0 then
						var_6_1.pet_id = arg_4_0.petTeam_[1].data:getPetID()
					else
						var_6_1.pet_id = 0
					end

					if arg_4_0.selectSpType == xyd.SelectSpType.LEAD then
						xyd.WindowManager.get():openWindow("arena_mode_select_lead", {
							params = var_6_1,
							heros = arg_4_0.select_,
							callback = var_6_0
						})
					else
						var_6_0(var_6_1)
					end
				end
			end)
			arg_4_0.battlepetBtn_:setVisible(true)
			arg_4_0:nodeByName("button_battle"):setVisible(false)
		else
			arg_4_0.battlepetBtn_ = arg_4_0:nodeByName("button_battle")

			arg_4_0.battlepetBtn_:addTouchEventListener(function(arg_9_0, arg_9_1)
				xyd.buttonScaleAnim(arg_4_0.battlepetBtn_, arg_9_1)

				if not arg_4_0:checkCanStartBattle() then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("BATTLE_NO_HERO")
					})

					return
				end

				if arg_9_1 == ccui.TouchEventType.ended and not arg_4_0.battleBegan then
					if not arg_4_0:challengeTimeDeal() then
						return
					end

					xyd.playButtonSound()

					arg_4_0.battleBegan = true

					arg_4_0:startBattle()
				end
			end)
			arg_4_0.battlepetBtn_:setVisible(true)
			arg_4_0:nodeByName("button_ok"):setVisible(false)
		end
	end

	return arg_4_0.battlepetBtn_
end

function var_0_0.startBattle(arg_10_0)
	if next(arg_10_0.team_) == nil then
		return
	end

	if arg_10_0.type == xyd.SelectTeamType.ARENA then
		if next(arg_10_0.enemyHeroes_) == nil then
			return
		end

		arg_10_0:recordFormation()
		arg_10_0:startArenaBattle()
	elseif arg_10_0.type == xyd.SelectTeamType.ARENA_MODE then
		if next(arg_10_0.enemyHeroes_) == nil then
			return
		end

		arg_10_0:startArenaModeBattle()
	end
end

function var_0_0.checkCanLoadPreFormation(arg_11_0)
	if arg_11_0.campaignType == xyd.CampaignType.ARENA then
		return true
	end

	return false
end

function var_0_0.startArenaBattle(arg_12_0)
	if FRONT_ARENA_BATTLE then
		return arg_12_0:startArenaFrontBattle()
	end

	local var_12_0 = {
		herosA = {}
	}

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.team_) do
		table.insert(var_12_0.herosA, iter_12_1.data)
	end

	var_12_0.campaignType = arg_12_0.campaignType
	var_12_0.campaignID = arg_12_0.campaignID
	var_12_0.herosB = {
		arg_12_0.enemyHeroes_
	}
	var_12_0.fighterInfo = arg_12_0.fighterInfo
	var_12_0.battleID = xyd.MapBattleID.ARENA

	local var_12_1 = arg_12_0:getFormationStr(var_12_0.herosA)

	var_12_0.formation = var_12_1
	var_12_0.battleType = xyd.BattleType.CreateReport
	var_12_0.savenge = arg_12_0.is_avenge or 0

	local var_12_2

	if #arg_12_0.petTeam_ ~= 0 then
		var_12_2 = arg_12_0.petTeam_[1].data:getPetID()
	end

	local var_12_3 = {
		pet_id = var_12_2,
		campaign_id = var_12_0.campaignID,
		campaign_type = var_12_0.campaignType,
		formation = var_12_1,
		enemy_id = arg_12_0.fighterInfo.enemy_id,
		is_avenge = arg_12_0.is_avenge or 0
	}

	local function var_12_4(arg_13_0)
		arg_12_0.enemyHeroes_ = {}

		if arg_13_0.heros and next(arg_13_0.heros) then
			for iter_13_0, iter_13_1 in pairs(arg_13_0.heros) do
				local var_13_0 = iter_13_1

				if type(var_13_0.equips) == "string" then
					var_13_0.equips = xyd.splitToNumber(var_13_0.equips, "|")
				end

				if bookshelfLev and bookshelfLev > 0 then
					var_13_0.book_shelf_lev = bookshelfLev
				else
					var_13_0.book_shelf_lev = 0
				end

				local var_13_1 = import("app.model.Hero").new()

				var_13_1:populate(var_13_0)

				if arg_13_0.conquer_lev and arg_13_0.conquer_lev > 0 then
					var_13_1:setConquerSchoolLev(arg_13_0.conquer_lev)
				end

				table.insert(arg_12_0.enemyHeroes_, var_13_1)
			end
		end

		if arg_13_0.pet then
			local var_13_2 = arg_13_0.pet

			if type(var_13_2.equips) == "string" then
				var_13_2.equips = xyd.splitToNumber(var_13_2.equips, "|")
			end

			local var_13_3 = import("app.model.Pet").new()

			var_13_3:populate(var_13_2)

			arg_12_0.enemyPets_ = var_13_3
		end
	end

	local function var_12_5(arg_14_0)
		xyd.Backend.get():request(xyd.mid.START_FIGHT, arg_14_0, function(arg_15_0, arg_15_1)
			if arg_15_0 == xyd.error.OK then
				local function var_15_0()
					if arg_15_1.formation and next(arg_15_1.formation) then
						local var_16_0 = {}
						local var_16_1 = arg_12_0.selfPlayer.conquerLev

						for iter_16_0, iter_16_1 in ipairs(arg_15_1.formation) do
							local var_16_2 = var_0_1.new()

							var_16_2:populate(iter_16_1)

							if var_16_1 and var_16_1 > 0 then
								var_16_2:setConquerSchoolLev(var_16_1)
							end

							table.insert(var_16_0, var_16_2)
						end

						var_12_0.herosA = var_16_0
					end

					if arg_15_1.battle_report then
						if arg_15_1.battle_report[1] then
							var_12_0.battle_report = arg_15_1.battle_report[1].content
						else
							var_12_0.battle_report = arg_15_1.battle_report
						end

						var_12_0.partner_favor = arg_15_1.partner_favor
						var_12_0.award_crystal = arg_15_1.award_crystal
						var_12_0.is_win = arg_15_1.is_win
					end

					var_12_0.petsA = {}

					for iter_16_2, iter_16_3 in ipairs(arg_12_0.petSelect_) do
						table.insert(var_12_0.petsA, iter_16_3)
					end

					var_12_0.herosB = {
						arg_12_0.enemyHeroes_
					}
					var_12_0.petsB = {}

					table.insert(var_12_0.petsB, arg_12_0.enemyPets_)

					var_12_0.isNewLoading = true
					var_12_0.enemy_id = arg_12_0.fighterInfo.enemy_id
					var_12_0.enemy_title_info = arg_12_0.fighterInfo.enemy_title_info
					var_12_0.my_id = arg_12_0.fighterInfo.my_id
					var_12_0.enemyRegionName = arg_12_0.selfPlayer.regionName
					var_12_0.selfRegionName = arg_12_0.selfPlayer.regionName
					var_12_0.selfRegion = arg_12_0.selfPlayer.region
					var_12_0.enemyRegion = arg_12_0.selfPlayer.region
					var_12_0.enemyName = arg_15_1.enemy_formation.player_name
					var_12_0.myName = arg_12_0.selfPlayer.playerName

					if arg_15_1.enemy_formation.guild_id ~= 0 then
						var_12_0.enemyGuild = arg_15_1.enemy_formation.guild_name
					end

					if arg_12_0.guild.guild_name then
						var_12_0.myGuild = arg_12_0.guild.guild_name
					end

					local var_16_3 = {}

					if arg_15_1.items then
						for iter_16_4, iter_16_5 in pairs(arg_15_1.items) do
							local var_16_4 = {
								table_id = iter_16_5.item_id,
								item_num = iter_16_5.item_num
							}

							table.insert(var_16_3, var_16_4)
						end

						var_12_0.awards = var_16_3
					end

					xyd.WindowManager.get():hideAllWindows()
					xyd.LoadingProxy.get():openBattleLoading(var_12_0)
				end

				if not arg_15_1.enemy_formation.is_robot then
					var_12_4(arg_15_1.enemy_formation)
				end

				if arg_15_1.battle_report == {} or #arg_15_1.battle_report == 0 then
					var_0_2.performWithDelayGlobal(function()
						var_12_5(arg_14_0)
					end, 3)
				else
					var_15_0()
				end
			elseif arg_15_1.error_code == 31005 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("CHANGE_SEAL_HERO_TIPS")
				})

				arg_12_0.battleBegan = false
			else
				arg_12_0.battleBegan = false
			end
		end)
	end

	var_12_5(var_12_3)
end

function var_0_0.updateScore(arg_18_0)
	local var_18_0 = 0

	for iter_18_0, iter_18_1 in ipairs(arg_18_0.team_) do
		var_18_0 = var_18_0 + iter_18_1.data:getZhandouli()
	end

	for iter_18_2, iter_18_3 in ipairs(arg_18_0.petTeam_) do
		var_18_0 = var_18_0 + iter_18_3.data:getZhandouli()
	end

	if arg_18_0.selectSpType == xyd.SelectSpType.PHANTOM then
		var_18_0 = var_18_0 * 5
	end

	arg_18_0:nodeByName("zhandouli"):setString(var_18_0)
end

function var_0_0.startArenaModeBattle(arg_19_0)
	local var_19_0 = {
		herosA = {}
	}

	for iter_19_0, iter_19_1 in ipairs(arg_19_0.team_) do
		table.insert(var_19_0.herosA, iter_19_1.data)
	end

	var_19_0.campaignType = arg_19_0.campaignType
	var_19_0.campaignID = arg_19_0.campaignID
	var_19_0.herosB = {
		arg_19_0.enemyHeroes_
	}
	var_19_0.fighterInfo = arg_19_0.fighterInfo
	var_19_0.battleID = xyd.MapBattleID.ARENA

	local var_19_1 = arg_19_0:getFormationStr(var_19_0.herosA)

	var_19_0.formation = var_19_1
	var_19_0.battleType = xyd.BattleType.CreateReport
	var_19_0.savenge = arg_19_0.is_avenge or 0

	local var_19_2

	if #arg_19_0.petTeam_ ~= 0 then
		var_19_2 = arg_19_0.petTeam_[1].data:getPetID()
	end

	local var_19_3 = {
		pet_id = var_19_2,
		campaign_id = var_19_0.campaignID,
		campaign_type = var_19_0.campaignType,
		formation = var_19_1,
		enemy_id = arg_19_0.fighterInfo.enemy_id,
		is_avenge = arg_19_0.is_avenge or 0
	}

	local function var_19_4(arg_20_0)
		arg_19_0.enemyHeroes_ = {}

		if arg_20_0.heros and next(arg_20_0.heros) then
			for iter_20_0, iter_20_1 in pairs(arg_20_0.heros) do
				local var_20_0 = iter_20_1

				if type(var_20_0.equips) == "string" then
					var_20_0.equips = xyd.splitToNumber(var_20_0.equips, "|")
				end

				if bookshelfLev and bookshelfLev > 0 then
					var_20_0.book_shelf_lev = bookshelfLev
				else
					var_20_0.book_shelf_lev = 0
				end

				local var_20_1 = import("app.model.Hero").new()

				var_20_1:populate(var_20_0)

				if arg_20_0.conquer_lev and arg_20_0.conquer_lev > 0 then
					var_20_1:setConquerSchoolLev(arg_20_0.conquer_lev)
				end

				table.insert(arg_19_0.enemyHeroes_, var_20_1)
			end
		end

		if arg_20_0.pet then
			local var_20_2 = arg_20_0.pet

			if type(var_20_2.equips) == "string" then
				var_20_2.equips = xyd.splitToNumber(var_20_2.equips, "|")
			end

			local var_20_3 = import("app.model.Pet").new()

			var_20_3:populate(var_20_2)

			arg_19_0.enemyPets_ = var_20_3
		end
	end

	local function var_19_5(arg_21_0)
		xyd.Backend.get():request(xyd.mid.ARENA_MODE_FIGHT, arg_21_0, function(arg_22_0, arg_22_1)
			if arg_22_0 == xyd.error.OK then
				local function var_22_0()
					if arg_22_1.formation and next(arg_22_1.formation) then
						local var_23_0 = {}
						local var_23_1 = arg_19_0.selfPlayer.conquerLev

						for iter_23_0, iter_23_1 in ipairs(arg_22_1.formation) do
							local var_23_2 = var_0_1.new()

							var_23_2:populate(iter_23_1)

							if var_23_1 and var_23_1 > 0 then
								var_23_2:setConquerSchoolLev(var_23_1)
							end

							if arg_19_0.selectSpType == xyd.SelectSpType.PHANTOM then
								for iter_23_2 = 1, 5 do
									table.insert(var_23_0, var_23_2)
								end

								break
							else
								table.insert(var_23_0, var_23_2)
							end
						end

						var_19_0.herosA = var_23_0
					end

					if arg_22_1.battle_report then
						if arg_22_1.battle_report[1] then
							var_19_0.battle_report = arg_22_1.battle_report[1].content
						else
							var_19_0.battle_report = arg_22_1.battle_report
						end

						var_19_0.partner_favor = arg_22_1.partner_favor
						var_19_0.award_crystal = arg_22_1.award_crystal
						var_19_0.is_win = arg_22_1.is_win
					end

					var_19_0.petsA = {}

					for iter_23_3, iter_23_4 in ipairs(arg_19_0.petSelect_) do
						table.insert(var_19_0.petsA, iter_23_4)
					end

					var_19_0.herosB = {
						arg_19_0.enemyHeroes_
					}
					var_19_0.petsB = {}

					table.insert(var_19_0.petsB, arg_19_0.enemyPets_)

					var_19_0.isNewLoading = true
					var_19_0.enemy_id = arg_19_0.fighterInfo.enemy_id
					var_19_0.my_id = arg_19_0.fighterInfo.my_id
					var_19_0.enemyRegionName = arg_19_0.selfPlayer.regionName
					var_19_0.selfRegionName = arg_19_0.selfPlayer.regionName
					var_19_0.selfRegion = arg_19_0.selfPlayer.region
					var_19_0.enemyRegion = arg_19_0.selfPlayer.region
					var_19_0.enemyName = arg_22_1.enemy_formation.player_name
					var_19_0.myName = arg_19_0.selfPlayer.playerName

					if arg_22_1.enemy_formation.guild_id ~= 0 then
						var_19_0.enemyGuild = arg_22_1.enemy_formation.guild_name
					end

					if arg_19_0.guild.guild_name then
						var_19_0.myGuild = arg_19_0.guild.guild_name
					end

					xyd.WindowManager.get():hideAllWindows()

					if arg_19_0.selectSpType == xyd.SelectSpType.PHANTOM then
						local var_23_3 = {}

						for iter_23_5 = 1, 5 do
							table.insert(var_23_3, var_19_0.herosA[1])
						end

						var_19_0.herosA = var_23_3
					end

					xyd.LoadingProxy.get():openBattleLoading(var_19_0)
				end

				if not arg_22_1.enemy_formation.is_robot then
					var_19_4(arg_22_1.enemy_formation)
				end

				if arg_22_1.battle_report == {} or #arg_22_1.battle_report == 0 then
					var_0_2.performWithDelayGlobal(function()
						var_19_5(arg_21_0)
					end, 3)
				else
					var_22_0()
				end
			elseif arg_22_1.error_code == 31005 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("CHANGE_SEAL_HERO_TIPS")
				})

				arg_19_0.battleBegan = false
			else
				arg_19_0.battleBegan = false
			end
		end)
	end

	if arg_19_0.selectSpType == xyd.SelectSpType.LEAD then
		xyd.WindowManager.get():openWindow("arena_mode_select_lead", {
			params = var_19_3,
			heros = arg_19_0.select_,
			callback = var_19_5
		})
	else
		var_19_5(var_19_3)
	end
end

function var_0_0.startArenaFrontBattle(arg_25_0)
	local var_25_0 = {
		herosA = {},
		herosB = {}
	}

	for iter_25_0, iter_25_1 in ipairs(arg_25_0.team_) do
		table.insert(var_25_0.herosA, iter_25_1.data)
	end

	var_25_0.campaignType = arg_25_0.campaignType
	var_25_0.campaignID = arg_25_0.campaignID
	var_25_0.herosB = {
		arg_25_0.enemyHeroes_
	}
	var_25_0.petsB = {}

	table.insert(var_25_0.petsB, arg_25_0.enemyPets_)

	var_25_0.fighterInfo = arg_25_0.fighterInfo
	var_25_0.battleID = xyd.MapBattleID.ARENA
	var_25_0.formation = arg_25_0:getFormationStr(var_25_0.herosA)
	var_25_0.savenge = arg_25_0.is_avenge or 0

	local var_25_1

	if #arg_25_0.petTeam_ ~= 0 then
		local var_25_2 = arg_25_0.petTeam_[1].data:getPetID()
	end

	var_25_0.petsA = {}

	for iter_25_2, iter_25_3 in ipairs(arg_25_0.petSelect_) do
		table.insert(var_25_0.petsA, iter_25_3)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "arena"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_25_0)
end

function var_0_0.sortTables(arg_26_0, arg_26_1)
	for iter_26_0 = 1, #arg_26_1 do
		table.sort(arg_26_1[iter_26_0][var_0_8.NO], function(arg_27_0, arg_27_1)
			if arg_26_0.type == xyd.SelectTeamType.ARENA or arg_26_0.type == xyd.SelectTeamType.ARENA_DEFENSE then
				local var_27_0 = arg_26_0:checkHeroIsSeal(arg_27_0)
				local var_27_1 = arg_26_0:checkHeroIsSeal(arg_27_1)

				if (var_27_0 or var_27_1) and (not var_27_0 or not var_27_1) then
					return var_27_0
				end
			end

			if (arg_27_0.can_rent or arg_27_1.can_rent) and (not arg_27_0.can_rent or not arg_27_1.can_rent) then
				return arg_27_0.can_rent and not arg_27_1.can_rent
			end

			return xyd.heroNormalSort(arg_27_0, arg_27_1) or false
		end)
		table.sort(arg_26_1[iter_26_0][var_0_8.YES], function(arg_28_0, arg_28_1)
			if arg_26_0.type == xyd.SelectTeamType.ARENA or arg_26_0.type == xyd.SelectTeamType.ARENA_DEFENSE then
				local var_28_0 = arg_26_0:checkHeroIsSeal(arg_28_0)
				local var_28_1 = arg_26_0:checkHeroIsSeal(arg_28_1)

				if (var_28_0 or var_28_1) and (not var_28_0 or not var_28_1) then
					return var_28_0
				end
			end

			if (arg_28_0.can_rent or arg_28_1.can_rent) and (not arg_28_0.can_rent or not arg_28_1.can_rent) then
				return arg_28_0.can_rent and not arg_28_1.can_rent
			end

			return xyd.heroNormalSort(arg_28_0, arg_28_1) or false
		end)
	end
end

function var_0_0.isPet(arg_29_0)
	if not arg_29_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PET) then
		return false
	end

	if arg_29_0.banPet then
		return false
	end

	return true
end

function var_0_0.isBanned(arg_30_0, arg_30_1)
	local var_30_0 = arg_30_1:getTableID()

	if var_0_5:beforeAwaken(var_30_0) > 0 then
		var_30_0 = var_0_5:beforeAwaken(var_30_0)
	end

	for iter_30_0 = 1, #arg_30_0.bannedHeros do
		if var_30_0 == arg_30_0.bannedHeros[iter_30_0] then
			return true
		end
	end

	return false
end

function var_0_0.checkHeroIsSeal(arg_31_0, arg_31_1)
	if arg_31_0.sealHeroID and arg_31_0.sealHeroID > 0 and arg_31_1:getFirstTableID() == arg_31_0.sealHeroID then
		return true
	end

	return false
end

function var_0_0.checkCanPresetTeam(arg_32_0)
	if arg_32_0.noPreset then
		return false
	end

	return true
end

function var_0_0.checkPresetTeamCanUse(arg_33_0, arg_33_1)
	local var_33_0 = arg_33_0.presetTeams[arg_33_1].team

	if arg_33_0.type == xyd.SelectTeamType.ARENA or arg_33_0.type == xyd.SelectTeamType.ARENA_DEFENSE then
		for iter_33_0 = 1, #var_33_0 do
			local var_33_1 = var_33_0[iter_33_0]

			if arg_33_0:checkHeroIsSeal(var_33_1) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("HERO_IS_SEAL_TIPS_1")
				})

				return false
			end
		end
	end

	return arg_33_0.super.checkPresetTeamCanUse(arg_33_0, arg_33_1)
end

function var_0_0.checkClickAvatar(arg_34_0, arg_34_1)
	if (arg_34_0.type == xyd.SelectTeamType.ARENA or arg_34_0.type == xyd.SelectTeamType.ARENA_DEFENSE) and arg_34_0:checkHeroIsSeal(hero) then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_3:translation("HERO_IS_SEAL_TIPS_1")
		})

		return false
	end

	if arg_34_0.selectSpType == xyd.SelectSpType.SINGLE and #arg_34_0.team_ >= 1 then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_3:translation("ARENA_MODE_MAX_HERO"), 1)
		})

		return false
	end

	if arg_34_0.selectSpType == xyd.SelectSpType.TRIPLE and #arg_34_0.team_ >= 3 then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_3:translation("ARENA_MODE_MAX_HERO"), 3)
		})

		return false
	end

	if arg_34_0.selectSpType == xyd.SelectSpType.PHANTOM and #arg_34_0.team_ >= 1 then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_3:translation("ARENA_MODE_MAX_HERO"), 1)
		})

		return false
	end

	return arg_34_0.super.checkClickAvatar(arg_34_0, arg_34_1)
end

function var_0_0.clickAvatar(arg_35_0, arg_35_1, arg_35_2)
	if arg_35_0.selectSpType == xyd.SelectSpType.PHANTOM then
		if not arg_35_0:checkClickAvatar(arg_35_1) then
			return
		end

		local var_35_0

		if arg_35_0.leftMenuType_ == xyd.LeftMenuType.SELF_HERO then
			var_35_0 = arg_35_1:getChildByName("layout")
		else
			var_35_0 = arg_35_1:getChildByName("yongbingCell"):getChildByName("container")
		end

		local var_35_1 = var_35_0:getChildByName("avatar_mask")
		local var_35_2 = var_35_0:getChildByName("chosen")
		local var_35_3 = arg_35_1:convertToWorldSpace(cc.p(0, 0))
		local var_35_4 = var_35_3.x + arg_35_1:getContentSize().width / 2
		local var_35_5 = var_35_3.y + arg_35_1:getContentSize().height / 2

		arg_35_1.isAnimated_ = true

		if arg_35_1.teamNo_ then
			local var_35_6 = arg_35_0.team_[arg_35_1.teamNo_]

			arg_35_0:moveFadeOutAction(var_35_4, var_35_5, var_35_6, function()
				arg_35_1.isAnimated_ = false
			end)
			var_35_1:setVisible(false)
			var_35_2:setVisible(false)

			for iter_35_0 = #arg_35_0.team_, arg_35_1.teamNo_ + 1, -1 do
				transition.stopTarget(arg_35_0.team_[iter_35_0])

				local var_35_7, var_35_8 = arg_35_0:nodeByName("avatar" .. iter_35_0 - 1):getPosition()

				transition.moveTo(arg_35_0.team_[iter_35_0], {
					time = 0.3,
					x = var_35_7,
					y = var_35_8 - 13
				})

				arg_35_0.team_[iter_35_0].iniCell_.teamNo_ = iter_35_0 - 1
			end

			if arg_35_1.type == xyd.LeftMenuType.RENT_HERO then
				arg_35_0.isSelectMerHero = false
				arg_35_0.selectMerHero = nil
			end

			table.remove(arg_35_0.team_, arg_35_1.teamNo_)
			table.remove(arg_35_0.select_, arg_35_1.teamNo_)

			arg_35_1.teamNo_ = nil
		elseif not arg_35_1.teamNo_ and #arg_35_0.team_ < xyd.MAX_TEAM_MEMBER_NUM then
			if not arg_35_2 then
				local var_35_9 = arg_35_1.data

				if var_0_5:chosenSound(var_35_9:getTableID()) ~= "" then
					xyd.AssetDownload.get():preloadCharacterSound({
						var_35_9:getTableID()
					}, function()
						return
					end, true)
					audio.playSound(var_0_5:chosenSound(var_35_9:getTableID()), false)
				end
			end

			if not arg_35_0:checkClickNewAvatar(arg_35_1) then
				return
			end

			local var_35_10 = arg_35_0:initBottomCell(arg_35_1.data)

			var_35_10.iniCell_ = arg_35_1

			var_35_10:pos(var_35_4, var_35_5)
			var_35_10:addTo(arg_35_0)
			var_35_10:setTouchEnabled(true)

			local var_35_11 = arg_35_1.data

			var_35_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_38_0)
				if arg_38_0.name == "ended" then
					if var_35_11.isAssist and arg_35_0.selectSpType == xyd.SelectSpType.ASSIST then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_3:translation("CAMPAIGN_ASSIST_HERO")
						})
					else
						arg_35_0:clickBottomAvatar(var_35_10)
					end
				end

				return true
			end)

			if arg_35_1.type == xyd.LeftMenuType.RENT_HERO then
				arg_35_0.isSelectMerHero = true
				arg_35_0.selectMerHero = var_35_10.data
			end

			arg_35_1.teamNo_ = arg_35_0:getTeamNo(var_35_10)

			for iter_35_1 = arg_35_1.teamNo_, #arg_35_0.team_ do
				local var_35_12, var_35_13 = arg_35_0:nodeByName("avatar" .. iter_35_1):getPosition()

				if arg_35_2 then
					arg_35_0.team_[iter_35_1]:pos(var_35_12, var_35_13 - 13)

					arg_35_1.isAnimated_ = false
				elseif iter_35_1 ~= arg_35_1.teamNo_ then
					local var_35_14 = arg_35_0.team_[iter_35_1]

					transition.stopTarget(var_35_14)
					transition.moveTo(var_35_14, {
						time = 0.3,
						x = var_35_12,
						y = var_35_13 - 13,
						onComplete = function()
							var_35_14.iniCell_.isAnimated_ = false
							var_35_14.isAnimated_ = false
						end
					})
				else
					local var_35_15 = arg_35_0.team_[iter_35_1]

					transition.stopTarget(var_35_15)

					var_35_10.isAnimated_ = true

					transition.moveTo(var_35_15, {
						time = 0.3,
						x = var_35_12,
						y = var_35_13 - 13,
						onComplete = function()
							arg_35_1.isAnimated_ = false
							var_35_10.isAnimated_ = false
						end
					})
				end

				arg_35_0.team_[iter_35_1].iniCell_.teamNo_ = iter_35_1
			end

			if arg_35_0.selectSpType == xyd.SelectSpType.PHANTOM then
				for iter_35_2 = 2, 5 do
					local var_35_16, var_35_17 = arg_35_0:nodeByName("avatar" .. iter_35_2):getPosition()
					local var_35_18 = arg_35_0:initBottomCell(arg_35_1.data)

					var_35_18.iniCell_ = arg_35_1

					var_35_18:pos(var_35_16, var_35_17 - 13)
					var_35_18:addTo(arg_35_0)
					var_35_18:setTouchEnabled(false)
					var_35_18:getChildByName("layout"):getChildByName("hero_lock"):setVisible(true)
					arg_35_0:moveFadeInAction(var_35_16, var_35_17 - 13, var_35_18)
					table.insert(arg_35_0.phantoms, var_35_18)
				end
			end

			var_35_1:setVisible(true)
			var_35_2:setVisible(true)
		end

		if not arg_35_2 then
			arg_35_0:playGuide()
		end

		arg_35_0:updateScore()
	else
		arg_35_0.super.clickAvatar(arg_35_0, arg_35_1, arg_35_2)
	end
end

function var_0_0.clickBottomAvatar(arg_41_0, arg_41_1, arg_41_2)
	arg_41_0.super.clickBottomAvatar(arg_41_0, arg_41_1, arg_41_2)

	for iter_41_0, iter_41_1 in pairs(arg_41_0.phantoms) do
		local var_41_0, var_41_1 = iter_41_1:getPosition()

		arg_41_0:moveFadeOutAction(var_41_0, var_41_1, iter_41_1)
	end

	arg_41_0.phantoms = {}
end

function var_0_0.checkPreHeroCanLoad(arg_42_0, arg_42_1)
	if arg_42_0.campaignType == xyd.CampaignType.ARENA and arg_42_0:checkHeroIsSeal(arg_42_1) then
		return false
	end

	return arg_42_0.super.checkPreHeroCanLoad(arg_42_0, arg_42_1)
end

function var_0_0.checkHeroIsNotUse(arg_43_0, arg_43_1)
	if (arg_43_0.type == xyd.SelectTeamType.ARENA or arg_43_0.type == xyd.SelectTeamType.ARENA_DEFENSE) and arg_43_0:checkHeroIsSeal(arg_43_1) then
		return true
	end

	return false
end

function var_0_0.challengeTimeDeal(arg_44_0)
	local var_44_0 = xyd.ServerTime.get():getSecondsOfDay()

	if var_44_0 > var_0_4.arenaTime1 and var_44_0 < var_0_4.arenaTime2 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_3:translation("ARENA_BATTLE_LIMIT")
		})

		return false
	end

	return true
end

function var_0_0.startTimer(arg_45_0)
	local var_45_0 = var_0_3:translation("ARENA_PREPARATION_COUNTDOWN")

	arg_45_0:nodeByName("lev_limit_txt"):setString(string.format(var_45_0, var_0_7))

	if arg_45_0.timerHandle then
		var_0_2.unscheduleGlobal(arg_45_0.timerHandle)

		arg_45_0.timerHandle = nil
	end

	arg_45_0.timerHandle = var_0_2.scheduleGlobal(function()
		local var_46_0 = xyd.ServerTime.get():getServerTime()
		local var_46_1 = var_0_7 - (var_46_0 - arg_45_0.startTime)

		if var_46_1 >= 0 then
			local var_46_2 = var_0_3:translation("ARENA_PREPARATION_COUNTDOWN")

			arg_45_0:nodeByName("lev_limit_txt"):setString(string.format(var_46_2, var_46_1))
		else
			if arg_45_0.timerHandle then
				var_0_2.unscheduleGlobal(arg_45_0.timerHandle)

				arg_45_0.timerHandle = nil
			end

			arg_45_0:close()
		end
	end, 1)
end

function var_0_0.initTextOfList(arg_47_0)
	if arg_47_0.type == xyd.SelectTeamType.ARENA or arg_47_0.type == xyd.SelectTeamType.ARENA_MODE then
		arg_47_0.txt_height = arg_47_0:nodeByName("lev_limit_txt"):getY()

		arg_47_0:nodeByName("lev_limit_txt"):setVisible(true)

		local var_47_0 = arg_47_0.heroList_:getViewRect()
		local var_47_1 = cc.rect(0, 0, var_47_0.width, var_47_0.height - var_0_6)

		arg_47_0.heroList_:setViewRect(var_47_1)
	else
		arg_47_0.super.initTextOfList(arg_47_0)
	end
end

function var_0_0.willClose(arg_48_0)
	if arg_48_0.timerHandle then
		var_0_2.unscheduleGlobal(arg_48_0.timerHandle)

		arg_48_0.timerHandle = nil
	end
end

return var_0_0
