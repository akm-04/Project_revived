local var_0_0 = class("SelectTeamWindow", import("app.windows.BaseSelectTeamWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc
local var_0_5 = xyd.tables.hero

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

function var_0_0.initPreHeros(arg_2_0, arg_2_1)
	if arg_2_0.selectSpType == xyd.SelectSpType.PHANTOM and arg_2_0.preSelect_ and arg_2_0.preHeros_ then
		for iter_2_0, iter_2_1 in pairs(arg_2_0.preHeros_) do
			for iter_2_2 = 2, 5 do
				local var_2_0, var_2_1 = arg_2_0:nodeByName("avatar" .. iter_2_2):getPosition()
				local var_2_2 = arg_2_0:initBottomCell(iter_2_1)

				var_2_2.iniCell_ = cell

				var_2_2:pos(var_2_0, var_2_1)
				var_2_2:addTo(arg_2_0)
				var_2_2:setTouchEnabled(false)
				var_2_2:getChildByName("layout"):getChildByName("hero_lock"):setVisible(true)
				table.insert(arg_2_0.phantoms, var_2_2)
			end

			break
		end
	end

	arg_2_0.super.initPreHeros(arg_2_0, arg_2_1)
end

function var_0_0.getBattleBtn(arg_3_0)
	if not arg_3_0.battlepetBtn_ then
		if arg_3_0.type == xyd.SelectTeamType.ARENA_DEFENSE then
			arg_3_0.battlepetBtn_ = arg_3_0:nodeByName("button_ok")

			arg_3_0.battlepetBtn_:addTouchEventListener(function(arg_4_0, arg_4_1)
				if #arg_3_0.select_ < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("BATTLE_NO_HERO")
					})

					return
				end

				if arg_4_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()

					local var_4_0 = {
						defenseHeroes = arg_3_0.select_
					}

					if #arg_3_0.petTeam_ ~= 0 then
						var_4_0.pet_id = arg_3_0.petTeam_[1].data:getPetID()
					else
						var_4_0.pet_id = 0
					end

					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.ARENA_DEFENSE_UPDATE,
						params = var_4_0
					})
					xyd.WindowManager.get():closeWindow(arg_3_0)
				end
			end)
			arg_3_0.battlepetBtn_:setVisible(true)
			arg_3_0:nodeByName("button_battle"):setVisible(false)
		elseif arg_3_0.type == xyd.SelectTeamType.ARENA_MODE_DEFENSE then
			arg_3_0.battlepetBtn_ = arg_3_0:nodeByName("button_ok")

			arg_3_0.battlepetBtn_:addTouchEventListener(function(arg_5_0, arg_5_1)
				if #arg_3_0.select_ < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("BATTLE_NO_HERO")
					})

					return
				end

				if arg_5_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()

					local function var_5_0(arg_6_0)
						xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA):saveModeDefenderData(arg_6_0, function()
							local var_7_0 = xyd.WindowManager.get():getWindow("arena")

							if var_7_0 then
								var_7_0:loadMHeroListView()
							end

							xyd.WindowManager.get():closeWindow(arg_3_0)
						end)
					end

					local var_5_1 = {
						defenseHeroes = arg_3_0.select_
					}

					if #arg_3_0.petTeam_ ~= 0 then
						var_5_1.pet_id = arg_3_0.petTeam_[1].data:getPetID()
					else
						var_5_1.pet_id = 0
					end

					if arg_3_0.selectSpType == xyd.SelectSpType.LEAD then
						xyd.WindowManager.get():openWindow("arena_mode_select_lead", {
							params = var_5_1,
							heros = arg_3_0.select_,
							callback = var_5_0
						})
					else
						var_5_0(var_5_1)
					end
				end
			end)
			arg_3_0.battlepetBtn_:setVisible(true)
			arg_3_0:nodeByName("button_battle"):setVisible(false)
		else
			arg_3_0.battlepetBtn_ = arg_3_0:nodeByName("button_battle")

			arg_3_0.battlepetBtn_:addTouchEventListener(function(arg_8_0, arg_8_1)
				if not arg_3_0:checkCanStartBattle() then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("BATTLE_NO_HERO")
					})

					return
				end

				if arg_8_1 == ccui.TouchEventType.ended and not arg_3_0.battleBegan then
					if not arg_3_0:challengeTimeDeal() then
						return
					end

					xyd.playButtonSound()

					arg_3_0.battleBegan = true

					arg_3_0:startBattle()
				end
			end)
			arg_3_0.battlepetBtn_:setVisible(true)
			arg_3_0:nodeByName("button_ok"):setVisible(false)
		end
	end

	return arg_3_0.battlepetBtn_
end

function var_0_0.startBattle(arg_9_0)
	if next(arg_9_0.team_) == nil then
		return
	end

	if arg_9_0.type == xyd.SelectTeamType.ARENA then
		if next(arg_9_0.enemyHeroes_) == nil then
			return
		end

		arg_9_0:recordFormation()
		arg_9_0:startArenaBattle()
	elseif arg_9_0.type == xyd.SelectTeamType.ARENA_MODE then
		if next(arg_9_0.enemyHeroes_) == nil then
			return
		end

		arg_9_0:startArenaModeBattle()
	end
end

function var_0_0.checkCanLoadPreFormation(arg_10_0)
	if arg_10_0.campaignType == xyd.CampaignType.ARENA then
		return true
	end

	return false
end

function var_0_0.startArenaBattle(arg_11_0)
	if FRONT_ARENA_BATTLE then
		return arg_11_0:startArenaFrontBattle()
	end

	local var_11_0 = {
		herosA = {}
	}

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.team_) do
		table.insert(var_11_0.herosA, iter_11_1.data)
	end

	var_11_0.campaignType = arg_11_0.campaignType
	var_11_0.campaignID = arg_11_0.campaignID
	var_11_0.herosB = {
		arg_11_0.enemyHeroes_
	}
	var_11_0.fighterInfo = arg_11_0.fighterInfo
	var_11_0.battleID = xyd.MapBattleID.ARENA

	local var_11_1 = arg_11_0:getFormationStr(var_11_0.herosA)

	var_11_0.formation = var_11_1
	var_11_0.battleType = xyd.BattleType.CreateReport
	var_11_0.savenge = arg_11_0.is_avenge or 0

	local var_11_2

	if #arg_11_0.petTeam_ ~= 0 then
		var_11_2 = arg_11_0.petTeam_[1].data:getPetID()
	end

	local var_11_3 = {
		pet_id = var_11_2,
		campaign_id = var_11_0.campaignID,
		campaign_type = var_11_0.campaignType,
		formation = var_11_1,
		enemy_id = arg_11_0.fighterInfo.enemy_id,
		is_avenge = arg_11_0.is_avenge or 0
	}

	local function var_11_4(arg_12_0)
		arg_11_0.enemyHeroes_ = {}

		if arg_12_0.heros and next(arg_12_0.heros) then
			for iter_12_0, iter_12_1 in pairs(arg_12_0.heros) do
				local var_12_0 = iter_12_1

				if type(var_12_0.equips) == "string" then
					var_12_0.equips = xyd.splitToNumber(var_12_0.equips, "|")
				end

				if bookshelfLev and bookshelfLev > 0 then
					var_12_0.book_shelf_lev = bookshelfLev
				else
					var_12_0.book_shelf_lev = 0
				end

				local var_12_1 = import("app.model.Hero").new()

				var_12_1:populate(var_12_0)

				if arg_12_0.conquer_lev and arg_12_0.conquer_lev > 0 then
					var_12_1:setConquerSchoolLev(arg_12_0.conquer_lev)
				end

				table.insert(arg_11_0.enemyHeroes_, var_12_1)
			end
		end

		if arg_12_0.pet then
			local var_12_2 = arg_12_0.pet

			if type(var_12_2.equips) == "string" then
				var_12_2.equips = xyd.splitToNumber(var_12_2.equips, "|")
			end

			local var_12_3 = import("app.model.Pet").new()

			var_12_3:populate(var_12_2)

			arg_11_0.enemyPets_ = var_12_3
		end
	end

	local function var_11_5(arg_13_0)
		xyd.Backend.get():request(xyd.mid.START_FIGHT, arg_13_0, function(arg_14_0, arg_14_1)
			if arg_14_0 == xyd.error.OK then
				local function var_14_0()
					if arg_14_1.formation and next(arg_14_1.formation) then
						local var_15_0 = {}
						local var_15_1 = arg_11_0.selfPlayer.conquerLev

						for iter_15_0, iter_15_1 in ipairs(arg_14_1.formation) do
							local var_15_2 = var_0_1.new()

							var_15_2:populate(iter_15_1)

							if var_15_1 and var_15_1 > 0 then
								var_15_2:setConquerSchoolLev(var_15_1)
							end

							table.insert(var_15_0, var_15_2)
						end

						var_11_0.herosA = var_15_0
					end

					if arg_14_1.battle_report then
						if arg_14_1.battle_report[1] then
							var_11_0.battle_report = arg_14_1.battle_report[1].content
						else
							var_11_0.battle_report = arg_14_1.battle_report
						end

						var_11_0.partner_favor = arg_14_1.partner_favor
						var_11_0.award_crystal = arg_14_1.award_crystal
						var_11_0.is_win = arg_14_1.is_win
					end

					var_11_0.petsA = {}

					for iter_15_2, iter_15_3 in ipairs(arg_11_0.petSelect_) do
						table.insert(var_11_0.petsA, iter_15_3)
					end

					var_11_0.herosB = {
						arg_11_0.enemyHeroes_
					}
					var_11_0.petsB = {}

					table.insert(var_11_0.petsB, arg_11_0.enemyPets_)

					var_11_0.isNewLoading = true
					var_11_0.enemy_id = arg_11_0.fighterInfo.enemy_id
					var_11_0.enemy_title_info = arg_11_0.fighterInfo.enemy_title_info
					var_11_0.my_id = arg_11_0.fighterInfo.my_id
					var_11_0.enemyRegionName = arg_11_0.selfPlayer.regionName
					var_11_0.selfRegionName = arg_11_0.selfPlayer.regionName
					var_11_0.selfRegion = arg_11_0.selfPlayer.region
					var_11_0.enemyRegion = arg_11_0.selfPlayer.region
					var_11_0.enemyName = arg_14_1.enemy_formation.player_name
					var_11_0.myName = arg_11_0.selfPlayer.playerName

					if arg_14_1.enemy_formation.guild_id ~= 0 then
						var_11_0.enemyGuild = arg_14_1.enemy_formation.guild_name
					end

					if arg_11_0.guild.guild_name then
						var_11_0.myGuild = arg_11_0.guild.guild_name
					end

					local var_15_3 = {}

					if arg_14_1.items then
						for iter_15_4, iter_15_5 in pairs(arg_14_1.items) do
							local var_15_4 = {
								table_id = iter_15_5.item_id,
								item_num = iter_15_5.item_num
							}

							table.insert(var_15_3, var_15_4)
						end

						var_11_0.awards = var_15_3
					end

					xyd.WindowManager.get():hideAllWindows()
					xyd.LoadingProxy.get():openBattleLoading(var_11_0)
				end

				if not arg_14_1.enemy_formation.is_robot then
					var_11_4(arg_14_1.enemy_formation)
				end

				if arg_14_1.battle_report == {} or #arg_14_1.battle_report == 0 then
					var_0_2.performWithDelayGlobal(function()
						var_11_5(arg_13_0)
					end, 3)
				else
					var_14_0()
				end
			elseif arg_14_1.error_code == 31005 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("CHANGE_SEAL_HERO_TIPS")
				})

				arg_11_0.battleBegan = false
			else
				arg_11_0.battleBegan = false
			end
		end)
	end

	var_11_5(var_11_3)
end

function var_0_0.updateScore(arg_17_0)
	local var_17_0 = 0

	for iter_17_0, iter_17_1 in ipairs(arg_17_0.team_) do
		var_17_0 = var_17_0 + iter_17_1.data:getZhandouli()
	end

	for iter_17_2, iter_17_3 in ipairs(arg_17_0.petTeam_) do
		var_17_0 = var_17_0 + iter_17_3.data:getZhandouli()
	end

	if arg_17_0.selectSpType == xyd.SelectSpType.PHANTOM then
		var_17_0 = var_17_0 * 5
	end

	arg_17_0:nodeByName("zhandouli"):setString(var_17_0)
end

function var_0_0.startArenaModeBattle(arg_18_0)
	local var_18_0 = {
		herosA = {}
	}

	for iter_18_0, iter_18_1 in ipairs(arg_18_0.team_) do
		table.insert(var_18_0.herosA, iter_18_1.data)
	end

	var_18_0.campaignType = arg_18_0.campaignType
	var_18_0.campaignID = arg_18_0.campaignID
	var_18_0.herosB = {
		arg_18_0.enemyHeroes_
	}
	var_18_0.fighterInfo = arg_18_0.fighterInfo
	var_18_0.battleID = xyd.MapBattleID.ARENA

	local var_18_1 = arg_18_0:getFormationStr(var_18_0.herosA)

	var_18_0.formation = var_18_1
	var_18_0.battleType = xyd.BattleType.CreateReport
	var_18_0.savenge = arg_18_0.is_avenge or 0

	local var_18_2

	if #arg_18_0.petTeam_ ~= 0 then
		var_18_2 = arg_18_0.petTeam_[1].data:getPetID()
	end

	local var_18_3 = {
		pet_id = var_18_2,
		campaign_id = var_18_0.campaignID,
		campaign_type = var_18_0.campaignType,
		formation = var_18_1,
		enemy_id = arg_18_0.fighterInfo.enemy_id,
		is_avenge = arg_18_0.is_avenge or 0
	}

	local function var_18_4(arg_19_0)
		arg_18_0.enemyHeroes_ = {}

		if arg_19_0.heros and next(arg_19_0.heros) then
			for iter_19_0, iter_19_1 in pairs(arg_19_0.heros) do
				local var_19_0 = iter_19_1

				if type(var_19_0.equips) == "string" then
					var_19_0.equips = xyd.splitToNumber(var_19_0.equips, "|")
				end

				if bookshelfLev and bookshelfLev > 0 then
					var_19_0.book_shelf_lev = bookshelfLev
				else
					var_19_0.book_shelf_lev = 0
				end

				local var_19_1 = import("app.model.Hero").new()

				var_19_1:populate(var_19_0)

				if arg_19_0.conquer_lev and arg_19_0.conquer_lev > 0 then
					var_19_1:setConquerSchoolLev(arg_19_0.conquer_lev)
				end

				table.insert(arg_18_0.enemyHeroes_, var_19_1)
			end
		end

		if arg_19_0.pet then
			local var_19_2 = arg_19_0.pet

			if type(var_19_2.equips) == "string" then
				var_19_2.equips = xyd.splitToNumber(var_19_2.equips, "|")
			end

			local var_19_3 = import("app.model.Pet").new()

			var_19_3:populate(var_19_2)

			arg_18_0.enemyPets_ = var_19_3
		end
	end

	local function var_18_5(arg_20_0)
		xyd.Backend.get():request(xyd.mid.ARENA_MODE_FIGHT, arg_20_0, function(arg_21_0, arg_21_1)
			if arg_21_0 == xyd.error.OK then
				local function var_21_0()
					if arg_21_1.formation and next(arg_21_1.formation) then
						local var_22_0 = {}
						local var_22_1 = arg_18_0.selfPlayer.conquerLev

						for iter_22_0, iter_22_1 in ipairs(arg_21_1.formation) do
							local var_22_2 = var_0_1.new()

							var_22_2:populate(iter_22_1)

							if var_22_1 and var_22_1 > 0 then
								var_22_2:setConquerSchoolLev(var_22_1)
							end

							if arg_18_0.selectSpType == xyd.SelectSpType.PHANTOM then
								for iter_22_2 = 1, 5 do
									table.insert(var_22_0, var_22_2)
								end

								break
							else
								table.insert(var_22_0, var_22_2)
							end
						end

						var_18_0.herosA = var_22_0
					end

					if arg_21_1.battle_report then
						if arg_21_1.battle_report[1] then
							var_18_0.battle_report = arg_21_1.battle_report[1].content
						else
							var_18_0.battle_report = arg_21_1.battle_report
						end

						var_18_0.partner_favor = arg_21_1.partner_favor
						var_18_0.award_crystal = arg_21_1.award_crystal
						var_18_0.is_win = arg_21_1.is_win
					end

					var_18_0.petsA = {}

					for iter_22_3, iter_22_4 in ipairs(arg_18_0.petSelect_) do
						table.insert(var_18_0.petsA, iter_22_4)
					end

					var_18_0.herosB = {
						arg_18_0.enemyHeroes_
					}
					var_18_0.petsB = {}

					table.insert(var_18_0.petsB, arg_18_0.enemyPets_)

					var_18_0.isNewLoading = true
					var_18_0.enemy_id = arg_18_0.fighterInfo.enemy_id
					var_18_0.my_id = arg_18_0.fighterInfo.my_id
					var_18_0.enemyRegionName = arg_18_0.selfPlayer.regionName
					var_18_0.selfRegionName = arg_18_0.selfPlayer.regionName
					var_18_0.selfRegion = arg_18_0.selfPlayer.region
					var_18_0.enemyRegion = arg_18_0.selfPlayer.region
					var_18_0.enemyName = arg_21_1.enemy_formation.player_name
					var_18_0.myName = arg_18_0.selfPlayer.playerName

					if arg_21_1.enemy_formation.guild_id ~= 0 then
						var_18_0.enemyGuild = arg_21_1.enemy_formation.guild_name
					end

					if arg_18_0.guild.guild_name then
						var_18_0.myGuild = arg_18_0.guild.guild_name
					end

					xyd.WindowManager.get():hideAllWindows()

					if arg_18_0.selectSpType == xyd.SelectSpType.PHANTOM then
						local var_22_3 = {}

						for iter_22_5 = 1, 5 do
							table.insert(var_22_3, var_18_0.herosA[1])
						end

						var_18_0.herosA = var_22_3
					end

					xyd.LoadingProxy.get():openBattleLoading(var_18_0)
				end

				if not arg_21_1.enemy_formation.is_robot then
					var_18_4(arg_21_1.enemy_formation)
				end

				if arg_21_1.battle_report == {} or #arg_21_1.battle_report == 0 then
					var_0_2.performWithDelayGlobal(function()
						var_18_5(arg_20_0)
					end, 3)
				else
					var_21_0()
				end
			elseif arg_21_1.error_code == 31005 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("CHANGE_SEAL_HERO_TIPS")
				})

				arg_18_0.battleBegan = false
			else
				arg_18_0.battleBegan = false
			end
		end)
	end

	if arg_18_0.selectSpType == xyd.SelectSpType.LEAD then
		xyd.WindowManager.get():openWindow("arena_mode_select_lead", {
			params = var_18_3,
			heros = arg_18_0.select_,
			callback = var_18_5
		})
	else
		var_18_5(var_18_3)
	end
end

function var_0_0.startArenaFrontBattle(arg_24_0)
	local var_24_0 = {
		herosA = {},
		herosB = {}
	}

	for iter_24_0, iter_24_1 in ipairs(arg_24_0.team_) do
		table.insert(var_24_0.herosA, iter_24_1.data)
	end

	var_24_0.campaignType = arg_24_0.campaignType
	var_24_0.campaignID = arg_24_0.campaignID
	var_24_0.herosB = {
		arg_24_0.enemyHeroes_
	}
	var_24_0.petsB = {}

	table.insert(var_24_0.petsB, arg_24_0.enemyPets_)

	var_24_0.fighterInfo = arg_24_0.fighterInfo
	var_24_0.battleID = xyd.MapBattleID.ARENA
	var_24_0.formation = arg_24_0:getFormationStr(var_24_0.herosA)
	var_24_0.savenge = arg_24_0.is_avenge or 0

	local var_24_1

	if #arg_24_0.petTeam_ ~= 0 then
		local var_24_2 = arg_24_0.petTeam_[1].data:getPetID()
	end

	var_24_0.petsA = {}

	for iter_24_2, iter_24_3 in ipairs(arg_24_0.petSelect_) do
		table.insert(var_24_0.petsA, iter_24_3)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "arena"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_24_0)
end

function var_0_0.sortTables(arg_25_0, arg_25_1)
	for iter_25_0 = 1, #arg_25_1 do
		table.sort(arg_25_1[iter_25_0], function(arg_26_0, arg_26_1)
			if arg_25_0.type == xyd.SelectTeamType.ARENA or arg_25_0.type == xyd.SelectTeamType.ARENA_DEFENSE then
				local var_26_0 = arg_25_0:checkHeroIsSeal(arg_26_0)
				local var_26_1 = arg_25_0:checkHeroIsSeal(arg_26_1)

				if (var_26_0 or var_26_1) and (not var_26_0 or not var_26_1) then
					return var_26_0
				end
			end

			if (arg_26_0.can_rent or arg_26_1.can_rent) and (not arg_26_0.can_rent or not arg_26_1.can_rent) then
				return arg_26_0.can_rent and not arg_26_1.can_rent
			end

			return xyd.heroNormalSort(arg_26_0, arg_26_1) or false
		end)
	end
end

function var_0_0.isPet(arg_27_0)
	if not arg_27_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PET) then
		return false
	end

	if arg_27_0.banPet then
		return false
	end

	return true
end

function var_0_0.isBanned(arg_28_0, arg_28_1)
	local var_28_0 = arg_28_1:getTableID()

	if var_0_5:beforeAwaken(var_28_0) > 0 then
		var_28_0 = var_0_5:beforeAwaken(var_28_0)
	end

	for iter_28_0 = 1, #arg_28_0.bannedHeros do
		if var_28_0 == arg_28_0.bannedHeros[iter_28_0] then
			return true
		end
	end

	return false
end

function var_0_0.checkHeroIsSeal(arg_29_0, arg_29_1)
	if arg_29_0.sealHeroID and arg_29_0.sealHeroID > 0 and arg_29_1:getFirstTableID() == arg_29_0.sealHeroID then
		return true
	end

	return false
end

function var_0_0.checkCanPresetTeam(arg_30_0)
	if arg_30_0.noPreset then
		return false
	end

	return true
end

function var_0_0.checkPresetTeamCanUse(arg_31_0, arg_31_1)
	local var_31_0 = arg_31_0.presetTeams[arg_31_1].team

	if arg_31_0.type == xyd.SelectTeamType.ARENA or arg_31_0.type == xyd.SelectTeamType.ARENA_DEFENSE then
		for iter_31_0 = 1, #var_31_0 do
			local var_31_1 = var_31_0[iter_31_0]

			if arg_31_0:checkHeroIsSeal(var_31_1) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("HERO_IS_SEAL_TIPS_1")
				})

				return false
			end
		end
	end

	return arg_31_0.super.checkPresetTeamCanUse(arg_31_0, arg_31_1)
end

function var_0_0.checkClickAvatar(arg_32_0, arg_32_1)
	if (arg_32_0.type == xyd.SelectTeamType.ARENA or arg_32_0.type == xyd.SelectTeamType.ARENA_DEFENSE) and arg_32_0:checkHeroIsSeal(hero) then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_3:translation("HERO_IS_SEAL_TIPS_1")
		})

		return false
	end

	if arg_32_0.selectSpType == xyd.SelectSpType.SINGLE and #arg_32_0.team_ >= 1 then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_3:translation("ARENA_MODE_MAX_HERO"), 1)
		})

		return false
	end

	if arg_32_0.selectSpType == xyd.SelectSpType.TRIPLE and #arg_32_0.team_ >= 3 then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_3:translation("ARENA_MODE_MAX_HERO"), 3)
		})

		return false
	end

	if arg_32_0.selectSpType == xyd.SelectSpType.PHANTOM and #arg_32_0.team_ >= 1 then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_3:translation("ARENA_MODE_MAX_HERO"), 1)
		})

		return false
	end

	return arg_32_0.super.checkClickAvatar(arg_32_0, arg_32_1)
end

function var_0_0.clickAvatar(arg_33_0, arg_33_1, arg_33_2)
	if arg_33_0.selectSpType == xyd.SelectSpType.PHANTOM then
		if not arg_33_0:checkClickAvatar(arg_33_1) then
			return
		end

		local var_33_0

		if arg_33_0.leftMenuType_ == xyd.LeftMenuType.SELF_HERO then
			var_33_0 = arg_33_1:getChildByName("layout")
		else
			var_33_0 = arg_33_1:getChildByName("yongbingCell"):getChildByName("container")
		end

		local var_33_1 = var_33_0:getChildByName("avatar_mask")
		local var_33_2 = var_33_0:getChildByName("chosen")
		local var_33_3 = arg_33_1:convertToWorldSpace(cc.p(0, 0))
		local var_33_4 = var_33_3.x + arg_33_1:getContentSize().width / 2
		local var_33_5 = var_33_3.y + arg_33_1:getContentSize().height / 2

		arg_33_1.isAnimated_ = true

		if arg_33_1.teamNo_ then
			local var_33_6 = arg_33_0.team_[arg_33_1.teamNo_]

			arg_33_0:moveFadeOutAction(var_33_4, var_33_5, var_33_6, function()
				arg_33_1.isAnimated_ = false
			end)
			var_33_1:setVisible(false)
			var_33_2:setVisible(false)

			for iter_33_0 = #arg_33_0.team_, arg_33_1.teamNo_ + 1, -1 do
				transition.stopTarget(arg_33_0.team_[iter_33_0])

				local var_33_7, var_33_8 = arg_33_0:nodeByName("avatar" .. iter_33_0 - 1):getPosition()

				transition.moveTo(arg_33_0.team_[iter_33_0], {
					time = 0.3,
					x = var_33_7,
					y = var_33_8
				})

				arg_33_0.team_[iter_33_0].iniCell_.teamNo_ = iter_33_0 - 1
			end

			if arg_33_1.type == xyd.LeftMenuType.RENT_HERO then
				arg_33_0.isSelectMerHero = false
				arg_33_0.selectMerHero = nil
			end

			table.remove(arg_33_0.team_, arg_33_1.teamNo_)
			table.remove(arg_33_0.select_, arg_33_1.teamNo_)

			arg_33_1.teamNo_ = nil
		elseif not arg_33_1.teamNo_ and #arg_33_0.team_ < xyd.MAX_TEAM_MEMBER_NUM then
			if not arg_33_2 then
				local var_33_9 = arg_33_1.data

				if var_0_5:chosenSound(var_33_9:getTableID()) ~= "" then
					xyd.AssetDownload.get():preloadCharacterSound({
						var_33_9:getTableID()
					}, function()
						return
					end, true)
					audio.playSound(var_0_5:chosenSound(var_33_9:getTableID()), false)
				end
			end

			if not arg_33_0:checkClickNewAvatar(arg_33_1) then
				return
			end

			local var_33_10 = arg_33_0:initBottomCell(arg_33_1.data)

			var_33_10.iniCell_ = arg_33_1

			var_33_10:pos(var_33_4, var_33_5)
			var_33_10:addTo(arg_33_0)
			var_33_10:setTouchEnabled(true)

			local var_33_11 = arg_33_1.data

			var_33_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_36_0)
				if arg_36_0.name == "ended" then
					if var_33_11.isAssist and arg_33_0.selectSpType == xyd.SelectSpType.ASSIST then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_3:translation("CAMPAIGN_ASSIST_HERO")
						})
					else
						arg_33_0:clickBottomAvatar(var_33_10)
					end
				end

				return true
			end)

			if arg_33_1.type == xyd.LeftMenuType.RENT_HERO then
				arg_33_0.isSelectMerHero = true
				arg_33_0.selectMerHero = var_33_10.data
			end

			arg_33_1.teamNo_ = arg_33_0:getTeamNo(var_33_10)

			for iter_33_1 = arg_33_1.teamNo_, #arg_33_0.team_ do
				local var_33_12, var_33_13 = arg_33_0:nodeByName("avatar" .. iter_33_1):getPosition()

				if arg_33_2 then
					arg_33_0.team_[iter_33_1]:pos(var_33_12, var_33_13)

					arg_33_1.isAnimated_ = false
				elseif iter_33_1 ~= arg_33_1.teamNo_ then
					local var_33_14 = arg_33_0.team_[iter_33_1]

					transition.stopTarget(var_33_14)
					transition.moveTo(var_33_14, {
						time = 0.3,
						x = var_33_12,
						y = var_33_13,
						onComplete = function()
							var_33_14.iniCell_.isAnimated_ = false
							var_33_14.isAnimated_ = false
						end
					})
				else
					local var_33_15 = arg_33_0.team_[iter_33_1]

					transition.stopTarget(var_33_15)

					var_33_10.isAnimated_ = true

					transition.moveTo(var_33_15, {
						time = 0.3,
						x = var_33_12,
						y = var_33_13,
						onComplete = function()
							arg_33_1.isAnimated_ = false
							var_33_10.isAnimated_ = false
						end
					})
				end

				arg_33_0.team_[iter_33_1].iniCell_.teamNo_ = iter_33_1
			end

			if arg_33_0.selectSpType == xyd.SelectSpType.PHANTOM then
				for iter_33_2 = 2, 5 do
					local var_33_16, var_33_17 = arg_33_0:nodeByName("avatar" .. iter_33_2):getPosition()
					local var_33_18 = arg_33_0:initBottomCell(arg_33_1.data)

					var_33_18.iniCell_ = arg_33_1

					var_33_18:pos(var_33_16, var_33_17)
					var_33_18:addTo(arg_33_0)
					var_33_18:setTouchEnabled(false)
					var_33_18:getChildByName("layout"):getChildByName("hero_lock"):setVisible(true)
					arg_33_0:moveFadeInAction(var_33_16, var_33_17, var_33_18)
					table.insert(arg_33_0.phantoms, var_33_18)
				end
			end

			var_33_1:setVisible(true)
			var_33_2:setVisible(true)
		end

		if not arg_33_2 then
			arg_33_0:playGuide()
		end

		arg_33_0:updateScore()
	else
		arg_33_0.super.clickAvatar(arg_33_0, arg_33_1, arg_33_2)
	end
end

function var_0_0.clickBottomAvatar(arg_39_0, arg_39_1, arg_39_2)
	arg_39_0.super.clickBottomAvatar(arg_39_0, arg_39_1, arg_39_2)

	for iter_39_0, iter_39_1 in pairs(arg_39_0.phantoms) do
		local var_39_0, var_39_1 = iter_39_1:getPosition()

		arg_39_0:moveFadeOutAction(var_39_0, var_39_1, iter_39_1)
	end

	arg_39_0.phantoms = {}
end

function var_0_0.checkPreHeroCanLoad(arg_40_0, arg_40_1)
	if arg_40_0.campaignType == xyd.CampaignType.ARENA and arg_40_0:checkHeroIsSeal(arg_40_1) then
		return false
	end

	return arg_40_0.super.checkPreHeroCanLoad(arg_40_0, arg_40_1)
end

function var_0_0.checkHeroIsNotUse(arg_41_0, arg_41_1)
	if (arg_41_0.type == xyd.SelectTeamType.ARENA or arg_41_0.type == xyd.SelectTeamType.ARENA_DEFENSE) and arg_41_0:checkHeroIsSeal(arg_41_1) then
		return true
	end

	return false
end

function var_0_0.challengeTimeDeal(arg_42_0)
	local var_42_0 = xyd.ServerTime.get():getSecondsOfDay()

	if var_42_0 > var_0_4.arenaTime1 and var_42_0 < var_0_4.arenaTime2 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_3:translation("ARENA_BATTLE_LIMIT")
		})

		return false
	end

	return true
end

return var_0_0
