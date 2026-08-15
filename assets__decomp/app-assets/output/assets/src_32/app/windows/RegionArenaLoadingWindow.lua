local var_0_0 = class("RegionArenaLoadingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.model.Pet")
local var_0_4 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfHeros = arg_1_2.selfHeros
	arg_1_0.selfPet = arg_1_2.selfPet
	arg_1_0.enemyHeros = arg_1_2.enemyHeros
	arg_1_0.enemyPet = arg_1_2.enemyPet
	arg_1_0.delay = arg_1_2.delay
	arg_1_0.isBackendBattle = arg_1_2.isBackendBattle
	arg_1_0.battleReport = arg_1_2.battleReport
	arg_1_0.mode = arg_1_2.mode
	arg_1_0.enemyName = arg_1_2.enemyName
	arg_1_0.enemyID = arg_1_2.enemyID
	arg_1_0.enemyGuildName = arg_1_2.enemyGuildName
	arg_1_0.enemyServerName = arg_1_2.enemyServerName
	arg_1_0.oldStar = arg_1_2.oldStar
	arg_1_0.selfRegionName = arg_1_2.selfRegionName
	arg_1_0.enemyRegion = arg_1_2.enemyRegion
	arg_1_0.haschange = false

	if arg_1_2.haschange then
		arg_1_0.haschange = arg_1_2.haschange
	end

	arg_1_0.is_friend = false
	arg_1_0.is_casual = false

	if arg_1_2.is_record then
		arg_1_0.is_record = true
	end

	if arg_1_2.is_friend then
		arg_1_0.is_friend = true
	end

	if arg_1_2.is_casual then
		arg_1_0.is_casual = true
	end

	if arg_1_2.selfPlayerID then
		arg_1_0.selfPlayerID = arg_1_2.selfPlayerID
		arg_1_0.selfPlayerName = arg_1_2.selfPlayerName
		arg_1_0.selfGuildName = arg_1_2.selfGuildName
		arg_1_0.selfRegion = arg_1_2.selfRegion
	end

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	xyd.WindowManager.get():closeWindow("main_scene_top")
	xyd.WindowManager.get():closeWindow("main_scene_left")
	xyd.WindowManager.get():closeWindow("main_scene_middle")
	xyd.WindowManager.get():closeWindow("main_scene_bottom")
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
	arg_3_0:scheduleHandler()
	arg_3_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.willClose(arg_4_0, arg_4_1)
	var_0_0.super.willClose(arg_4_0, arg_4_1)

	if arg_4_0.handle then
		var_0_4.unscheduleGlobal(arg_4_0.handle)
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:layoutEnemyInfo()
	arg_5_0:layoutSelfInfo()
end

function var_0_0.layoutEnemyInfo(arg_6_0)
	local var_6_0 = arg_6_0:nodeByName("upper_wnd")

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.enemyHeros) do
		local var_6_1

		if iter_6_1.illusionSkinId_ and not iter_6_1.illusionSkinId_ == -1 then
			if arg_6_0.illusionSkinId_ == 0 then
				var_6_1 = xyd.getHeroCard(iter_6_1)
			elseif arg_6_0.illusionSkinId_ == 1 then
				var_6_1 = xyd.getHeroCard(iter_6_1, 3, 3)
			else
				var_6_1 = xyd.getHeroCard(iter_6_1, 2, 2)
			end
		elseif tonumber(iter_6_1.isSkinOn_) == 1 then
			var_6_1 = xyd.getHeroCard(iter_6_1, 2, 2)
		elseif iter_6_1:isAwaken() then
			var_6_1 = xyd.getHeroCard(iter_6_1, 3, 3)
		else
			var_6_1 = xyd.getHeroCard(iter_6_1)
		end

		var_6_1:setAnchorPoint(cc.p(0, 0))

		local var_6_2 = var_6_0:getChildByName("hero" .. iter_6_0):getWidth() / var_6_1:getContentSize().width

		var_6_1:setScale(var_6_2)
		var_6_1:addTo(var_6_0:getChildByName("hero" .. iter_6_0))
	end

	if arg_6_0.enemyPet then
		local var_6_3 = arg_6_0.enemyPet
		local var_6_4

		if var_6_3:isAwaken() then
			var_6_4 = xyd.getPetCard(var_6_3, 3, 3)
		else
			var_6_4 = xyd.getPetCard(var_6_3)
		end

		var_6_4:setAnchorPoint(cc.p(0, 0))

		local var_6_5 = var_6_0:getChildByName("pet"):getWidth() / var_6_4:getContentSize().width

		var_6_4:setScale(var_6_5)
		var_6_4:addTo(var_6_0:getChildByName("pet"))
	end

	var_6_0:getChildByName("name"):setString(arg_6_0.enemyName)
	var_6_0:getChildByName("id"):setString(arg_6_0.enemyID)
	var_6_0:getChildByName("from_txt"):setString(var_0_1:translation("LAI_ZI"))
	var_6_0:getChildByName("server_txt"):setString(var_0_1:translation("REGION_ARENA_TIP10"))

	if arg_6_0.enemyGuildName and arg_6_0.enemyGuildName ~= "" then
		var_6_0:getChildByName("guild_name"):setString(arg_6_0.enemyGuildName)
	else
		var_6_0:getChildByName("from_txt"):setVisible(false)
		var_6_0:getChildByName("guild_name"):setString(var_0_1:translation("PERSON_NO_GUILD"))
		var_6_0:getChildByName("guild_name"):setPositionY(var_6_0:getChildByName("guild_name"):getPositionY() + 24)
	end

	var_6_0:getChildByName("server_name"):setString(arg_6_0.enemyServerName .. "(S" .. arg_6_0.enemyRegion .. ")")
end

function var_0_0.layoutSelfInfo(arg_7_0)
	local var_7_0 = arg_7_0:nodeByName("lower_wnd")

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfHeros) do
		local var_7_1

		if iter_7_1.illusionSkinId_ and not iter_7_1.illusionSkinId_ == -1 then
			if arg_7_0.illusionSkinId_ == 0 then
				var_7_1 = xyd.getHeroCard(iter_7_1)
			elseif arg_7_0.illusionSkinId_ == 1 then
				var_7_1 = xyd.getHeroCard(iter_7_1, 3, 3)
			else
				var_7_1 = xyd.getHeroCard(iter_7_1, 2, 2)
			end
		elseif tonumber(iter_7_1.isSkinOn_) == 1 then
			var_7_1 = xyd.getHeroCard(iter_7_1, 2, 2)
		elseif iter_7_1:isAwaken() then
			var_7_1 = xyd.getHeroCard(iter_7_1, 3, 3)
		else
			var_7_1 = xyd.getHeroCard(iter_7_1)
		end

		var_7_1:setAnchorPoint(cc.p(0, 0))

		local var_7_2 = var_7_0:getChildByName("hero" .. iter_7_0):getWidth() / var_7_1:getContentSize().width

		var_7_1:setScale(var_7_2)
		var_7_1:addTo(var_7_0:getChildByName("hero" .. iter_7_0))
	end

	if arg_7_0.selfPet then
		local var_7_3 = arg_7_0.selfPet
		local var_7_4

		if var_7_3:isAwaken() then
			var_7_4 = xyd.getPetCard(var_7_3, 3, 3)
		else
			var_7_4 = xyd.getPetCard(var_7_3)
		end

		var_7_4:setAnchorPoint(cc.p(0, 0))

		local var_7_5 = var_7_0:getChildByName("pet"):getWidth() / var_7_4:getContentSize().width

		var_7_4:setScale(var_7_5)
		var_7_4:addTo(var_7_0:getChildByName("pet"))
	end

	var_7_0:getChildByName("from_txt"):setString(var_0_1:translation("LAI_ZI"))
	var_7_0:getChildByName("server_txt"):setString(var_0_1:translation("REGION_ARENA_TIP10"))

	if not arg_7_0.selfPlayerID then
		var_7_0:getChildByName("name"):setString(arg_7_0.player.playerName)
		var_7_0:getChildByName("id"):setString(arg_7_0.player.playerID)

		if arg_7_0.guild.guild_name and arg_7_0.guild.guild_name ~= "" then
			var_7_0:getChildByName("guild_name"):setString(arg_7_0.guild.guild_name)
		else
			var_7_0:getChildByName("from_txt"):setVisible(false)
			var_7_0:getChildByName("guild_name"):setString(var_0_1:translation("PERSON_NO_GUILD"))
			var_7_0:getChildByName("guild_name"):setPositionY(var_7_0:getChildByName("guild_name"):getPositionY() + 24)
		end

		var_7_0:getChildByName("server_name"):setString(arg_7_0.player.regionName .. "(S" .. arg_7_0.player.region .. ")")
	else
		var_7_0:getChildByName("name"):setString(arg_7_0.selfPlayerName)
		var_7_0:getChildByName("id"):setString(arg_7_0.selfPlayerID)

		if arg_7_0.selfGuildName and arg_7_0.selfGuildName ~= "" then
			var_7_0:getChildByName("guild_name"):setString(arg_7_0.selfGuildName)
		else
			var_7_0:getChildByName("from_txt"):setVisible(false)
			var_7_0:getChildByName("guild_name"):setString(var_0_1:translation("PERSON_NO_GUILD"))
			var_7_0:getChildByName("guild_name"):setPositionY(var_7_0:getChildByName("guild_name"):getPositionY() + 24)
		end

		var_7_0:getChildByName("server_name"):setString(arg_7_0.selfRegionName .. "(S" .. arg_7_0.selfRegion .. ")")
	end
end

function var_0_0.scheduleHandler(arg_8_0)
	var_0_4.performWithDelayGlobal(function()
		local var_9_0 = 4

		arg_8_0.handle = var_0_4.scheduleGlobal(function()
			arg_8_0:nodeByName("decount_num"):removeAllChildren()

			if var_9_0 <= 0 then
				arg_8_0:startBattle()

				if arg_8_0.handle then
					var_0_4.unscheduleGlobal(arg_8_0.handle)
				end

				xyd.WindowManager.get():closeWindow(arg_8_0.name)
			else
				local var_10_0 = xyd.AssetLoader.get():loadSprite("windows/across_arena/across_arena/pre_battle/" .. tostring(var_9_0) .. ".png")

				var_10_0:setAnchorPoint(cc.p(0, 0))
				var_10_0:addTo(arg_8_0:nodeByName("decount_num"))
				var_10_0:runAction(cc.FadeOut:create(1))
			end

			var_9_0 = var_9_0 - 1
		end, 1)
	end, arg_8_0.delay)
end

function var_0_0.startBattle(arg_11_0)
	local var_11_0 = {}

	ngx.ctx.battle.reportData = json.decode(arg_11_0.battleReport)
	var_11_0.herosA = {}
	var_11_0.herosB = {}
	var_11_0.summonMonsters = {}
	var_11_0.battleType = xyd.BattleType.ReplayReport
	var_11_0.battleID = xyd.MapBattleID.ARENA

	if arg_11_0.is_record then
		var_11_0.campaignType = xyd.CampaignType.PLAYOFFS_RECORD
	elseif arg_11_0.is_friend then
		var_11_0.campaignType = xyd.CampaignType.FRIEND_FIGHT
	elseif arg_11_0.is_casual then
		var_11_0.campaignType = xyd.CampaignType.REGION_CASUAL
	else
		var_11_0.campaignType = xyd.CampaignType.PLAYOFFS
	end

	local var_11_1 = {}
	local var_11_2 = {}

	if arg_11_0.haschange then
		for iter_11_0, iter_11_1 in pairs(ngx.ctx.battle.reportData.fighter) do
			local var_11_3 = string.sub(iter_11_0, 1, 1)
			local var_11_4 = tonumber(string.sub(iter_11_0, 3, 3))

			if var_11_3 == "B" and tonumber(iter_11_1.summon_type) == xyd.summonMonsterType.None then
				local var_11_5 = var_0_2.new()

				var_11_5:populate(iter_11_1.hero)
				var_11_5:setReportData(iter_11_1)

				var_11_0.herosA[var_11_4] = var_11_5
			elseif var_11_3 == "B" and tonumber(iter_11_1.summon_type) == xyd.summonMonsterType.Pet then
				local var_11_6 = var_0_3.new()

				var_11_6:populate(iter_11_1.hero)
				var_11_6:setReportData(iter_11_1)

				var_11_0.petsA = {
					var_11_6
				}
			elseif var_11_3 == "A" and tonumber(iter_11_1.summon_type) == xyd.summonMonsterType.None then
				local var_11_7 = var_0_2.new()

				var_11_7:populate(iter_11_1.hero)
				var_11_7:setReportData(iter_11_1)

				var_11_1[var_11_4] = var_11_7
			elseif var_11_3 == "A" and tonumber(iter_11_1.summon_type) == xyd.summonMonsterType.Pet then
				local var_11_8 = var_0_3.new()

				var_11_8:populate(iter_11_1.hero)
				var_11_8:setReportData(iter_11_1)

				var_11_0.petsB = {
					var_11_8
				}
			elseif tonumber(iter_11_1.summon_type) ~= xyd.summonMonsterType.None then
				local var_11_9 = var_0_2.new()

				var_11_9:populate(iter_11_1.hero)
				var_11_9:setReportData(iter_11_1)

				var_11_2[iter_11_0] = var_11_9
			end
		end

		var_11_0.reportStar = ngx.ctx.battle.reportData.star

		if var_11_0.reportStar > 0 then
			var_11_0.reportStar = 0
		else
			var_11_0.reportStar = 3
		end
	else
		for iter_11_2, iter_11_3 in pairs(ngx.ctx.battle.reportData.fighter) do
			local var_11_10 = string.sub(iter_11_2, 1, 1)
			local var_11_11 = tonumber(string.sub(iter_11_2, 3, 3))

			if var_11_10 == "A" and tonumber(iter_11_3.summon_type) == xyd.summonMonsterType.None then
				local var_11_12 = var_0_2.new()

				var_11_12:populate(iter_11_3.hero)
				var_11_12:setReportData(iter_11_3)

				var_11_0.herosA[var_11_11] = var_11_12
			elseif var_11_10 == "A" and tonumber(iter_11_3.summon_type) == xyd.summonMonsterType.Pet then
				local var_11_13 = var_0_3.new()

				var_11_13:populate(iter_11_3.hero)
				var_11_13:setReportData(iter_11_3)

				var_11_0.petsA = {
					var_11_13
				}
			elseif var_11_10 == "B" and tonumber(iter_11_3.summon_type) == xyd.summonMonsterType.None then
				local var_11_14 = var_0_2.new()

				var_11_14:populate(iter_11_3.hero)
				var_11_14:setReportData(iter_11_3)

				var_11_1[var_11_11] = var_11_14
			elseif var_11_10 == "B" and tonumber(iter_11_3.summon_type) == xyd.summonMonsterType.Pet then
				local var_11_15 = var_0_3.new()

				var_11_15:populate(iter_11_3.hero)
				var_11_15:setReportData(iter_11_3)

				var_11_0.petsB = {
					var_11_15
				}
			elseif tonumber(iter_11_3.summon_type) ~= xyd.summonMonsterType.None then
				local var_11_16 = var_0_2.new()

				var_11_16:populate(iter_11_3.hero)
				var_11_16:setReportData(iter_11_3)

				var_11_2[iter_11_2] = var_11_16
			end
		end

		var_11_0.reportStar = ngx.ctx.battle.reportData.star
	end

	var_11_0.herosB = {
		var_11_1
	}
	var_11_0.summonMonsters = var_11_2

	local var_11_17 = var_11_0.reportStar > 0
	local var_11_18 = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "region_arena_loading",
			status = {
				mode = arg_11_0.mode,
				oldStar = arg_11_0.oldStar,
				newStar = var_11_18:getStar(),
				isWin = var_11_17,
				is_friend = arg_11_0.is_friend,
				is_casual = arg_11_0.is_casual
			}
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_11_0)
end

return var_0_0
