local var_0_0 = class("ChampionsLeagueSelectTeamWindow", import("app.windows.BaseSelectTeamNewWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc
local var_0_5 = xyd.tables.hero
local var_0_6 = {
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

function var_0_0.initPreHeros(arg_2_0, arg_2_1)
	if arg_2_0.selectSpType == xyd.SelectSpType.PHANTOM and arg_2_0.preSelect_ and arg_2_0.preHeros_ then
		for iter_2_0, iter_2_1 in pairs(arg_2_0.preHeros_) do
			for iter_2_2 = 2, 5 do
				local var_2_0, var_2_1 = arg_2_0:nodeByName("avatar" .. iter_2_2):getPosition()
				local var_2_2 = arg_2_0:initBottomCell(iter_2_1)

				var_2_2.iniCell_ = cell

				var_2_2:pos(var_2_0, var_2_1 - 13)
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
		if arg_3_0.type == xyd.SelectTeamType.CHAMPIONS_DEFENSE then
			arg_3_0.battlepetBtn_ = arg_3_0:nodeByName("button_ok")

			arg_3_0.battlepetBtn_:addTouchEventListener(function(arg_4_0, arg_4_1)
				xyd.buttonScaleAnim(arg_3_0.battlepetBtn_, arg_4_1)

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
						name = xyd.event.CHAMPIONS_DEFENSE_UPDATE,
						params = var_4_0
					})
					xyd.WindowManager.get():closeWindow(arg_3_0)
				end
			end)
			arg_3_0.battlepetBtn_:setVisible(true)
			arg_3_0:nodeByName("button_battle"):setVisible(false)
		else
			arg_3_0.battlepetBtn_ = arg_3_0:nodeByName("button_battle")

			arg_3_0.battlepetBtn_:addTouchEventListener(function(arg_5_0, arg_5_1)
				xyd.buttonScaleAnim(arg_3_0.battlepetBtn_, arg_5_1)

				if not arg_3_0:checkCanStartBattle() then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("BATTLE_NO_HERO")
					})

					return
				end

				if arg_5_1 == ccui.TouchEventType.ended and not arg_3_0.battleBegan then
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

function var_0_0.startBattle(arg_6_0)
	if next(arg_6_0.team_) == nil then
		return
	end

	if next(arg_6_0.enemyHeroes_) == nil then
		return
	end

	arg_6_0:recordFormation()
	arg_6_0:startArenaBattle()
end

function var_0_0.checkCanLoadPreFormation(arg_7_0)
	if arg_7_0.campaignType == xyd.CampaignType.CHAMPIONS then
		return true
	end

	return false
end

function var_0_0.startArenaBattle(arg_8_0)
	local var_8_0 = {
		herosA = {}
	}

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.team_) do
		table.insert(var_8_0.herosA, iter_8_1.data)
	end

	var_8_0.campaignType = arg_8_0.campaignType
	var_8_0.campaignID = arg_8_0.campaignID
	var_8_0.herosB = {
		arg_8_0.enemyHeroes_
	}
	var_8_0.fighterInfo = arg_8_0.fighterInfo
	var_8_0.battleID = xyd.MapBattleID.ARENA

	local var_8_1 = arg_8_0:getFormationStr(var_8_0.herosA)

	var_8_0.formation = var_8_1
	var_8_0.battleType = xyd.BattleType.CreateReport
	var_8_0.savenge = arg_8_0.is_avenge or 0

	local var_8_2

	if #arg_8_0.petTeam_ ~= 0 then
		var_8_2 = arg_8_0.petTeam_[1].data:getPetID()
	end

	local var_8_3 = {
		pet_id = var_8_2,
		formation = var_8_1,
		enemy_id = arg_8_0.fighterInfo.enemy_id
	}

	local function var_8_4(arg_9_0)
		arg_8_0.enemyHeroes_ = {}

		if arg_9_0.heros and next(arg_9_0.heros) then
			for iter_9_0, iter_9_1 in pairs(arg_9_0.heros) do
				local var_9_0 = iter_9_1

				if type(var_9_0.equips) == "string" then
					var_9_0.equips = xyd.splitToNumber(var_9_0.equips, "|")
				end

				if bookshelfLev and bookshelfLev > 0 then
					var_9_0.book_shelf_lev = bookshelfLev
				else
					var_9_0.book_shelf_lev = 0
				end

				local var_9_1 = import("app.model.Hero").new()

				var_9_1:populate(var_9_0)

				if arg_9_0.conquer_lev and arg_9_0.conquer_lev > 0 then
					var_9_1:setConquerSchoolLev(arg_9_0.conquer_lev)
				end

				table.insert(arg_8_0.enemyHeroes_, var_9_1)
			end
		end

		if arg_9_0.pet and next(arg_9_0.pet) then
			local var_9_2 = arg_9_0.pet

			if type(var_9_2.equips) == "string" then
				var_9_2.equips = xyd.splitToNumber(var_9_2.equips, "|")
			end

			local var_9_3 = import("app.model.Pet").new()

			var_9_3:populate(var_9_2)

			arg_8_0.enemyPets_ = var_9_3
		end
	end

	local function var_8_5(arg_10_0)
		xyd.Backend.get():request(xyd.mid.CHAMPIONS_LEAGUE_FIGHT, arg_10_0, function(arg_11_0, arg_11_1)
			if arg_11_0 == xyd.error.OK then
				local function var_11_0()
					if arg_11_1.self_formation and next(arg_11_1.self_formation) then
						local var_12_0 = {}
						local var_12_1 = arg_8_0.selfPlayer.conquerLev

						for iter_12_0, iter_12_1 in ipairs(arg_11_1.self_formation) do
							local var_12_2 = var_0_1.new()

							var_12_2:populate(iter_12_1)

							if var_12_1 and var_12_1 > 0 then
								var_12_2:setConquerSchoolLev(var_12_1)
							end

							table.insert(var_12_0, var_12_2)
						end

						var_8_0.herosA = var_12_0
					end

					if arg_11_1.battle_report then
						if arg_11_1.battle_report[1] then
							var_8_0.battle_report = arg_11_1.battle_report[1].content
						else
							var_8_0.battle_report = arg_11_1.battle_report
						end

						var_8_0.partner_favor = arg_11_1.partner_favor or {}
						var_8_0.award_crystal = arg_11_1.award_crystal
						var_8_0.is_win = arg_11_1.is_win
					end

					var_8_0.petsA = {}

					for iter_12_2, iter_12_3 in ipairs(arg_8_0.petSelect_) do
						table.insert(var_8_0.petsA, iter_12_3)
					end

					var_8_0.herosB = {
						arg_8_0.enemyHeroes_
					}
					var_8_0.petsB = {}

					table.insert(var_8_0.petsB, arg_8_0.enemyPets_)

					var_8_0.isNewLoading = true
					var_8_0.enemy_id = arg_8_0.fighterInfo.enemy_id
					var_8_0.enemy_title_info = arg_8_0.fighterInfo.enemy_title_info
					var_8_0.my_id = arg_8_0.fighterInfo.my_id
					var_8_0.enemyRegionName = arg_8_0.fighterInfo.enemy_region_name
					var_8_0.selfRegionName = arg_8_0.selfPlayer.regionName
					var_8_0.selfRegion = arg_8_0.selfPlayer.region
					var_8_0.enemyRegion = arg_8_0.fighterInfo.enemy_region
					var_8_0.enemyName = arg_8_0.fighterInfo.enemy_name
					var_8_0.myName = arg_8_0.selfPlayer.playerName

					if arg_11_1.enemy_formation.guild_id ~= 0 then
						var_8_0.enemyGuild = arg_11_1.enemy_formation.guild_name
					end

					if arg_8_0.guild.guild_name then
						var_8_0.myGuild = arg_8_0.guild.guild_name
					end

					local var_12_3 = {}

					if arg_11_1.items then
						for iter_12_4, iter_12_5 in pairs(arg_11_1.items) do
							local var_12_4 = {
								table_id = iter_12_5.item_id,
								item_num = iter_12_5.item_num
							}

							table.insert(var_12_3, var_12_4)
						end

						var_8_0.awards = var_12_3
					end

					xyd.WindowManager.get():hideAllWindows()
					xyd.LoadingProxy.get():openBattleLoading(var_8_0)
				end

				if not arg_11_1.enemy_formation.is_robot then
					var_8_4(arg_11_1.enemy_formation)
				end

				if arg_11_1.report_key == {} or #arg_11_1.report_key == 0 then
					var_0_2.performWithDelayGlobal(function()
						var_8_5(arg_10_0)
					end, 3)
				else
					var_11_0()
				end
			elseif arg_11_1.error_code == 31005 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("CHANGE_SEAL_HERO_TIPS")
				})

				arg_8_0.battleBegan = false
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("CHAMPIONS_LEAGUE_NOT_CHALLENGE")
				})

				local var_11_1 = xyd.WindowManager.get():getWindow("champions_league")

				if var_11_1 then
					var_11_1:updateInfo()
				end

				arg_8_0.battleBegan = false
			end
		end)
	end

	var_8_5(var_8_3)
end

function var_0_0.updateScore(arg_14_0)
	local var_14_0 = 0

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.team_) do
		var_14_0 = var_14_0 + iter_14_1.data:getZhandouli()
	end

	for iter_14_2, iter_14_3 in ipairs(arg_14_0.petTeam_) do
		var_14_0 = var_14_0 + iter_14_3.data:getZhandouli()
	end

	if arg_14_0.selectSpType == xyd.SelectSpType.PHANTOM then
		var_14_0 = var_14_0 * 5
	end

	arg_14_0:nodeByName("zhandouli"):setString(var_14_0)
end

function var_0_0.sortTables(arg_15_0, arg_15_1)
	for iter_15_0 = 1, #arg_15_1 do
		table.sort(arg_15_1[iter_15_0][var_0_6.NO], function(arg_16_0, arg_16_1)
			if arg_15_0.type == xyd.SelectTeamType.CHAMPIONS or arg_15_0.type == xyd.SelectTeamType.CHAMPIONS_DEFENSE then
				local var_16_0 = arg_15_0:checkHeroIsSeal(arg_16_0)
				local var_16_1 = arg_15_0:checkHeroIsSeal(arg_16_1)

				if (var_16_0 or var_16_1) and (not var_16_0 or not var_16_1) then
					return var_16_0
				end
			end

			if (arg_16_0.can_rent or arg_16_1.can_rent) and (not arg_16_0.can_rent or not arg_16_1.can_rent) then
				return arg_16_0.can_rent and not arg_16_1.can_rent
			end

			return xyd.heroNormalSort(arg_16_0, arg_16_1) or false
		end)
		table.sort(arg_15_1[iter_15_0][var_0_6.YES], function(arg_17_0, arg_17_1)
			if arg_15_0.type == xyd.SelectTeamType.CHAMPIONS or arg_15_0.type == xyd.SelectTeamType.CHAMPIONS_DEFENSE then
				local var_17_0 = arg_15_0:checkHeroIsSeal(arg_17_0)
				local var_17_1 = arg_15_0:checkHeroIsSeal(arg_17_1)

				if (var_17_0 or var_17_1) and (not var_17_0 or not var_17_1) then
					return var_17_0
				end
			end

			if (arg_17_0.can_rent or arg_17_1.can_rent) and (not arg_17_0.can_rent or not arg_17_1.can_rent) then
				return arg_17_0.can_rent and not arg_17_1.can_rent
			end

			return xyd.heroNormalSort(arg_17_0, arg_17_1) or false
		end)
	end
end

function var_0_0.checkHeroIsSeal(arg_18_0, arg_18_1)
	if arg_18_0.sealHeroID and arg_18_0.sealHeroID > 0 and arg_18_1:getFirstTableID() == arg_18_0.sealHeroID then
		return true
	end

	return false
end

function var_0_0.isPet(arg_19_0)
	if not arg_19_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PET) then
		return false
	end

	if arg_19_0.banPet then
		return false
	end

	return true
end

function var_0_0.checkClickAvatar(arg_20_0, arg_20_1)
	if (arg_20_0.type == xyd.SelectTeamType.CHAMPIONS or arg_20_0.type == xyd.SelectTeamType.CHAMPIONS_DEFENSE) and arg_20_0:checkHeroIsSeal(hero) then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_3:translation("HERO_IS_SEAL_TIPS_1")
		})

		return false
	end

	return arg_20_0.super.checkClickAvatar(arg_20_0, arg_20_1)
end

function var_0_0.clickAvatar(arg_21_0, arg_21_1, arg_21_2)
	if arg_21_0.selectSpType == xyd.SelectSpType.PHANTOM then
		if not arg_21_0:checkClickAvatar(arg_21_1) then
			return
		end

		local var_21_0

		if arg_21_0.leftMenuType_ == xyd.LeftMenuType.SELF_HERO then
			var_21_0 = arg_21_1:getChildByName("layout")
		else
			var_21_0 = arg_21_1:getChildByName("yongbingCell"):getChildByName("container")
		end

		local var_21_1 = var_21_0:getChildByName("avatar_mask")
		local var_21_2 = var_21_0:getChildByName("chosen")
		local var_21_3 = arg_21_1:convertToWorldSpace(cc.p(0, 0))
		local var_21_4 = var_21_3.x + arg_21_1:getContentSize().width / 2
		local var_21_5 = var_21_3.y + arg_21_1:getContentSize().height / 2

		arg_21_1.isAnimated_ = true

		if arg_21_1.teamNo_ then
			local var_21_6 = arg_21_0.team_[arg_21_1.teamNo_]

			arg_21_0:moveFadeOutAction(var_21_4, var_21_5, var_21_6, function()
				arg_21_1.isAnimated_ = false
			end)
			var_21_1:setVisible(false)
			var_21_2:setVisible(false)

			for iter_21_0 = #arg_21_0.team_, arg_21_1.teamNo_ + 1, -1 do
				transition.stopTarget(arg_21_0.team_[iter_21_0])

				local var_21_7, var_21_8 = arg_21_0:nodeByName("avatar" .. iter_21_0 - 1):getPosition()

				transition.moveTo(arg_21_0.team_[iter_21_0], {
					time = 0.3,
					x = var_21_7,
					y = var_21_8 - 13
				})

				arg_21_0.team_[iter_21_0].iniCell_.teamNo_ = iter_21_0 - 1
			end

			if arg_21_1.type == xyd.LeftMenuType.RENT_HERO then
				arg_21_0.isSelectMerHero = false
				arg_21_0.selectMerHero = nil
			end

			table.remove(arg_21_0.team_, arg_21_1.teamNo_)
			table.remove(arg_21_0.select_, arg_21_1.teamNo_)

			arg_21_1.teamNo_ = nil
		elseif not arg_21_1.teamNo_ and #arg_21_0.team_ < xyd.MAX_TEAM_MEMBER_NUM then
			if not arg_21_2 then
				local var_21_9 = arg_21_1.data

				if var_0_5:chosenSound(var_21_9:getTableID()) ~= "" then
					xyd.AssetDownload.get():preloadCharacterSound({
						var_21_9:getTableID()
					}, function()
						return
					end, true)
					audio.playSound(var_0_5:chosenSound(var_21_9:getTableID()), false)
				end
			end

			if not arg_21_0:checkClickNewAvatar(arg_21_1) then
				return
			end

			local var_21_10 = arg_21_0:initBottomCell(arg_21_1.data)

			var_21_10.iniCell_ = arg_21_1

			var_21_10:pos(var_21_4, var_21_5)
			var_21_10:addTo(arg_21_0)
			var_21_10:setTouchEnabled(true)

			local var_21_11 = arg_21_1.data

			var_21_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_24_0)
				if arg_24_0.name == "ended" then
					if var_21_11.isAssist and arg_21_0.selectSpType == xyd.SelectSpType.ASSIST then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_3:translation("CAMPAIGN_ASSIST_HERO")
						})
					else
						arg_21_0:clickBottomAvatar(var_21_10)
					end
				end

				return true
			end)

			if arg_21_1.type == xyd.LeftMenuType.RENT_HERO then
				arg_21_0.isSelectMerHero = true
				arg_21_0.selectMerHero = var_21_10.data
			end

			arg_21_1.teamNo_ = arg_21_0:getTeamNo(var_21_10)

			for iter_21_1 = arg_21_1.teamNo_, #arg_21_0.team_ do
				local var_21_12, var_21_13 = arg_21_0:nodeByName("avatar" .. iter_21_1):getPosition()

				if arg_21_2 then
					arg_21_0.team_[iter_21_1]:pos(var_21_12, var_21_13 - 13)

					arg_21_1.isAnimated_ = false
				elseif iter_21_1 ~= arg_21_1.teamNo_ then
					local var_21_14 = arg_21_0.team_[iter_21_1]

					transition.stopTarget(var_21_14)
					transition.moveTo(var_21_14, {
						time = 0.3,
						x = var_21_12,
						y = var_21_13 - 13,
						onComplete = function()
							var_21_14.iniCell_.isAnimated_ = false
							var_21_14.isAnimated_ = false
						end
					})
				else
					local var_21_15 = arg_21_0.team_[iter_21_1]

					transition.stopTarget(var_21_15)

					var_21_10.isAnimated_ = true

					transition.moveTo(var_21_15, {
						time = 0.3,
						x = var_21_12,
						y = var_21_13 - 13,
						onComplete = function()
							arg_21_1.isAnimated_ = false
							var_21_10.isAnimated_ = false
						end
					})
				end

				arg_21_0.team_[iter_21_1].iniCell_.teamNo_ = iter_21_1
			end

			if arg_21_0.selectSpType == xyd.SelectSpType.PHANTOM then
				for iter_21_2 = 2, 5 do
					local var_21_16, var_21_17 = arg_21_0:nodeByName("avatar" .. iter_21_2):getPosition()
					local var_21_18 = arg_21_0:initBottomCell(arg_21_1.data)

					var_21_18.iniCell_ = arg_21_1

					var_21_18:pos(var_21_16, var_21_17 - 13)
					var_21_18:addTo(arg_21_0)
					var_21_18:setTouchEnabled(false)
					var_21_18:getChildByName("layout"):getChildByName("hero_lock"):setVisible(true)
					arg_21_0:moveFadeInAction(var_21_16, var_21_17 - 13, var_21_18)
					table.insert(arg_21_0.phantoms, var_21_18)
				end
			end

			var_21_1:setVisible(true)
			var_21_2:setVisible(true)
		end

		if not arg_21_2 then
			arg_21_0:playGuide()
		end

		arg_21_0:updateScore()
	else
		arg_21_0.super.clickAvatar(arg_21_0, arg_21_1, arg_21_2)
	end
end

function var_0_0.clickBottomAvatar(arg_27_0, arg_27_1, arg_27_2)
	arg_27_0.super.clickBottomAvatar(arg_27_0, arg_27_1, arg_27_2)

	for iter_27_0, iter_27_1 in pairs(arg_27_0.phantoms) do
		local var_27_0, var_27_1 = iter_27_1:getPosition()

		arg_27_0:moveFadeOutAction(var_27_0, var_27_1, iter_27_1)
	end

	arg_27_0.phantoms = {}
end

function var_0_0.checkPreHeroCanLoad(arg_28_0, arg_28_1)
	if arg_28_0.campaignType == xyd.CampaignType.CHAMPIONS and arg_28_0:checkHeroIsSeal(arg_28_1) then
		return false
	end

	return arg_28_0.super.checkPreHeroCanLoad(arg_28_0, arg_28_1)
end

function var_0_0.checkHeroIsNotUse(arg_29_0, arg_29_1)
	if (arg_29_0.type == xyd.SelectTeamType.CHAMPIONS or arg_29_0.type == xyd.SelectTeamType.CHAMPIONS_DEFENSE) and arg_29_0:checkHeroIsSeal(arg_29_1) then
		return true
	end

	return false
end

return var_0_0
