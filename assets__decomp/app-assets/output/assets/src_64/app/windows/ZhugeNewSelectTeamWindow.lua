local var_0_0 = class("SelectTeamWindow", import("app.windows.BaseSelectTeamWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = import("framework.scheduler")
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.hero

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_1_0.selectTeamType = arg_1_2.teamType
	arg_1_0.specialParams = arg_1_2.specialParams
	arg_1_0.isShowTips = arg_1_2.isShowTips or false
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	var_0_0.super.didOpen(arg_2_0, arg_2_1)

	if arg_2_0.isShowTips then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_4:translation("ZHUGE_ADVENTURE_TIPS_35")
		})
	end
end

function var_0_0.layout(arg_3_0)
	var_0_0.super.layout(arg_3_0)
	arg_3_0:nodeByName("close"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended and not arg_3_0.battleBegan then
			local var_4_0 = var_0_4:translation("ZHUGE_ADVENTURE_TIPS_27")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_4_0, function()
				local var_5_0 = xyd.WindowManager.get():getWindow("zhuge_new_adventure")

				if var_5_0 and not tolua.isnull(var_5_0) then
					xyd.WindowManager.get():closeWindow("zhuge_new_adventure")
				end

				local var_5_1 = xyd.WindowManager.get():getWindow("zhuge_main_wnd")

				if not var_5_1 or tolua.isnull(var_5_1) then
					xyd.WindowManager.get():openWindow("zhuge_main_wnd")
				end

				xyd.WindowManager.get():closeWindow(arg_3_0)
			end, nil, nil, arg_3_0.colorMode)
		end
	end)
end

function var_0_0.startBattle(arg_6_0)
	if #arg_6_0.select_ < 1 then
		local var_6_0 = var_0_4:translation("ZHUGE_FOREST_TIPS_21")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_6_0
		})

		return
	end

	if #arg_6_0.select_ < xyd.MAX_TEAM_MEMBER_NUM then
		local var_6_1 = var_0_4:translation("ZHUGE_FOREST_TIPS_20")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_1, function()
			if arg_6_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
				arg_6_0:endCurDialog()
			end
		end, {
			lcallback = function()
				arg_6_0.battleBegan = false
			end
		}, nil, arg_6_0.colorMode)
	elseif arg_6_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		arg_6_0:endCurDialog()
	end
end

function var_0_0.endCurDialog(arg_9_0)
	if not arg_9_0.specialParams or not next(arg_9_0.specialParams) then
		return
	end

	arg_9_0.battleBegan = true

	xyd.WindowManager.get():openWindow("toast", {
		isAutoClose = 0,
		message = var_0_4:translation("ZHUGE_ADVENTURE_TIPS_41")
	})

	local var_9_0 = ""

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.select_) do
		local var_9_1 = arg_9_0.zhugeModel:getHeroStatus(iter_9_1:getTableID())

		if var_9_1 and next(var_9_1) then
			if var_9_0 ~= "" then
				var_9_0 = var_9_0 .. "|" .. var_9_1.init_id
			else
				var_9_0 = var_9_0 .. var_9_1.init_id
			end
		end
	end

	local var_9_2 = arg_9_0.petSelect_[1]
	local var_9_3 = 0

	if var_9_2 then
		local var_9_4 = arg_9_0.zhugeModel:getHeroStatus(var_9_2:getTableID())

		if var_9_4 and next(var_9_4) then
			var_9_3 = tonumber(var_9_4.init_id)
		end
	end

	arg_9_0.isBattle_ = true

	local var_9_5 = {
		team_str = var_9_0,
		pet_id = var_9_3
	}
	local var_9_6 = ""

	for iter_9_2, iter_9_3 in ipairs(arg_9_0.select_) do
		if var_9_6 ~= "" then
			var_9_6 = var_9_6 .. "|" .. iter_9_3:getTableID()
		else
			var_9_6 = var_9_6 .. iter_9_3:getTableID()
		end
	end

	local var_9_7 = 0

	if var_9_2 then
		var_9_7 = var_9_2:getTableID()
	end

	local var_9_8 = xyd.CampaignType.ZHUGE_ENEMY

	xyd.db.formation:setFormationData(var_9_8, var_9_6 .. "," .. var_9_7)
	arg_9_0.zhugeModel:endCurDialog(arg_9_0.specialParams.eventID, arg_9_0.specialParams.dialogID, arg_9_0.specialParams.mapIndex, var_9_5, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			if arg_9_0 and not tolua.isnull(arg_9_0) then
				arg_9_0:playReport(arg_10_1.battle_report)
			end
		else
			arg_9_0.battleBegan = false

			local var_10_0 = xyd.WindowManager.get():getWindow("toast")

			if var_10_0 and not tolua.isnull(var_10_0) then
				xyd.WindowManager.get():closeWindow("toast")
			end
		end
	end)
end

function var_0_0.getHeros(arg_11_0)
	local var_11_0 = {}
	local var_11_1 = {}

	if arg_11_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		local var_11_2 = arg_11_0.zhugeModel:getMemberInfos()

		for iter_11_0, iter_11_1 in ipairs(var_11_2) do
			if iter_11_1.partner_type ~= 2 and iter_11_1.partner_type ~= 3 then
				local var_11_3 = var_0_1.new()
				local var_11_4 = arg_11_0.selfPlayer:getHeroIgnoreAwaken(iter_11_1.table_id)

				if var_11_4 then
					var_11_3:populate(var_11_4:toParams())
				else
					var_11_3:initUnCollected(iter_11_1.table_id)
					var_11_3:setStar(5)
				end

				var_11_3.partner_type = iter_11_1.partner_type

				table.insert(var_11_0, var_11_3)
			end
		end
	else
		local var_11_5 = arg_11_0.selfPlayer.heros_

		for iter_11_2, iter_11_3 in ipairs(var_11_5) do
			if arg_11_0:checkHeroCanJoin(iter_11_3) then
				local var_11_6 = var_0_1.new()

				var_11_6:populate(iter_11_3:toParams())
				table.insert(var_11_0, var_11_6)
			end
		end
	end

	arg_11_0.zhugeModel:formatNewHeros(var_11_0)

	if arg_11_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		arg_11_0.zhugeModel:setMemberHeros(var_11_0)
	end

	return var_11_0
end

function var_0_0.checkCanLoadPreFormation(arg_12_0)
	return true
end

function var_0_0.loadPreFormation(arg_13_0)
	local var_13_0 = arg_13_0:getHeros()
	local var_13_1 = arg_13_0:getPets()
	local var_13_2 = {}
	local var_13_3 = {}
	local var_13_4 = xyd.CampaignType.ZHUGE_ENEMY
	local var_13_5 = xyd.db.formation:getFormationData(var_13_4) or {}
	local var_13_6 = var_13_5[1] or {}

	for iter_13_0, iter_13_1 in ipairs(var_13_6) do
		local var_13_7 = arg_13_0:selectHeroByTableID(var_13_0, iter_13_1)

		if var_13_7 and #var_13_2 < xyd.MAX_TEAM_MEMBER_NUM then
			var_13_7.type = xyd.LeftMenuType.SELF_HERO

			table.insert(var_13_2, iter_13_1)
			table.insert(var_13_3, var_13_7)
		end
	end

	arg_13_0.preSelect_ = var_13_2
	arg_13_0.preHeros_ = var_13_3

	local var_13_8 = var_13_5[2] or {}

	for iter_13_2, iter_13_3 in ipairs(var_13_8) do
		local var_13_9 = arg_13_0:selectHeroByTableID(var_13_1, iter_13_3)

		if var_13_9 and var_13_9 and #arg_13_0.prePet_ < xyd.MAX_PET_NUMBER then
			table.insert(arg_13_0.prePet_, var_13_9)
		end
	end
end

function var_0_0.selectHeroByTableID(arg_14_0, arg_14_1, arg_14_2)
	if arg_14_2 == 0 then
		return
	end

	local var_14_0 = arg_14_0.zhugeModel:getHeroStatus(arg_14_2)

	if not var_14_0 or not next(var_14_0) or var_14_0.health == 2 then
		return
	end

	for iter_14_0 = 1, #arg_14_1 do
		if arg_14_1[iter_14_0]:getTableID() == arg_14_2 then
			return arg_14_1[iter_14_0]
		end
	end
end

function var_0_0.getPets(arg_15_0)
	local var_15_0 = {}

	if arg_15_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		local var_15_1 = arg_15_0.zhugeModel:getMemberInfos()

		for iter_15_0, iter_15_1 in ipairs(var_15_1) do
			if iter_15_1.partner_type == 2 or iter_15_1.partner_type == 3 then
				local var_15_2 = var_0_2.new()
				local var_15_3 = arg_15_0.selfPlayer:getPetIgnoreAwaken(iter_15_1.table_id)

				if var_15_3 then
					var_15_2:populate(var_15_3:toParams())
				else
					var_15_2:initUnCollected(iter_15_1.table_id)

					var_15_2.star_ = 5
					var_15_2.is_show_ = 1
				end

				var_15_2.partner_type = iter_15_1.partner_type

				table.insert(var_15_0, var_15_2)
			end
		end
	else
		for iter_15_2, iter_15_3 in ipairs(arg_15_0.selfPlayer.collectedPets) do
			local var_15_4 = var_0_2.new()

			var_15_4:populate(iter_15_3:toParams())
			table.insert(var_15_0, var_15_4)
		end
	end

	arg_15_0.zhugeModel:formatNewPets(var_15_0)

	return var_15_0
end

function var_0_0.checkCanPresetTeam(arg_16_0)
	return false
end

function var_0_0.getListStatus(arg_17_0, arg_17_1, arg_17_2)
	return (arg_17_0.zhugeModel:getHeroStatus(arg_17_2:getTableID()))
end

function var_0_0.checkCanStartBattle(arg_18_0)
	local var_18_0 = true
	local var_18_1 = ""

	if #arg_18_0.select_ < 1 then
		var_18_0 = false
		var_18_1 = var_0_4:translation("BATTLE_NO_HERO")
	end

	if not var_18_0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_18_1
		})
	end

	return var_18_0
end

function var_0_0.playReport(arg_19_0, arg_19_1)
	if arg_19_1 == nil then
		return
	end

	if not arg_19_0 or tolua.isnull(arg_19_0) then
		return
	end

	local var_19_0 = {}
	local var_19_1 = json.decode(arg_19_1)

	var_19_0.herosA = {}
	var_19_0.herosB = {}
	var_19_0.summonMonsters = {}
	var_19_0.campaignType = xyd.CampaignType.ZHUGE_ENEMY
	var_19_0.battleID = xyd.MapBattleID.ZHUGE_ENEMY
	var_19_0.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_19_1

	local var_19_2 = {}
	local var_19_3 = {}

	for iter_19_0, iter_19_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_19_4 = string.sub(iter_19_0, 1, 1)
		local var_19_5 = tonumber(string.sub(iter_19_0, 3, 3))

		if var_19_4 == "A" and tonumber(iter_19_1.summon_type) == xyd.summonMonsterType.None then
			local var_19_6 = var_0_1.new()

			var_19_6:populate(iter_19_1.hero)
			var_19_6:setReportData(iter_19_1)

			var_19_6.healthStatus = arg_19_0.zhugeModel:getOldHeroStatus(var_19_6:getTableID())

			if isOnlyData then
				var_19_6.harms = iter_19_1.harms
				var_19_6.willDie = (iter_19_1.die_count or 0) ~= -1
			end

			var_19_0.herosA[var_19_5] = var_19_6
		elseif var_19_4 == "A" and tonumber(iter_19_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_19_7 = var_0_2.new()

			var_19_7:populate(iter_19_1.hero)
			var_19_7:setReportData(iter_19_1)

			if isOnlyData then
				var_19_7.harms = iter_19_1.harms
				var_19_7.willDie = (iter_19_1.die_count or 0) ~= -1
				var_19_0.petA = {
					var_19_7
				}
			else
				var_19_0.petsA = {
					var_19_7
				}
			end
		elseif var_19_4 == "B" and tonumber(iter_19_1.summon_type) == xyd.summonMonsterType.None then
			local var_19_8 = var_0_1.new()

			var_19_8:populate(iter_19_1.hero)
			var_19_8:setReportData(iter_19_1)

			if isOnlyData then
				var_19_8.harms = iter_19_1.harms
				var_19_8.willDie = (iter_19_1.die_count or 0) ~= -1
				var_19_0.herosB[var_19_5] = var_19_8
			else
				var_19_2[var_19_5] = var_19_8
			end
		elseif var_19_4 == "B" and tonumber(iter_19_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_19_9 = var_0_2.new()

			var_19_9:populate(iter_19_1.hero)

			var_19_9.star_ = xyd.tables.hero:star(var_19_9:getTableID())

			var_19_9:setReportData(iter_19_1)

			if isOnlyData then
				var_19_9.harms = iter_19_1.harms
				var_19_9.willDie = (iter_19_1.die_count or 0) ~= -1
				var_19_0.petB = {
					var_19_9
				}
			else
				var_19_0.petsB = {
					var_19_9
				}
			end
		elseif var_19_4 == "C" then
			local var_19_10 = var_0_1.new()

			var_19_10:populate(iter_19_1.hero)
			var_19_10:setReportData(iter_19_1)

			if not isOnlyData then
				sceneFighter = var_19_10
			end
		elseif tonumber(iter_19_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_19_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_19_11 = var_0_1.new()

			var_19_11:populate(iter_19_1.hero)
			var_19_11:setReportData(iter_19_1)

			var_19_3[iter_19_0] = var_19_11
		end
	end

	for iter_19_2 = 1, #var_19_2 do
		var_19_2[iter_19_2]:setStar(xyd.tables.hero:star(var_19_2[iter_19_2]:getTableID()))
	end

	var_19_0.herosB = {
		var_19_2
	}
	var_19_0.sceneFighter = sceneFighter
	var_19_0.summonMonsters = var_19_3
	var_19_0.reportStar = tonumber(var_19_1.star)

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "zhuge_new_adventure"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_19_0)
end

return var_0_0
