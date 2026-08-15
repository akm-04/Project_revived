local var_0_0 = class("BattleCreate", xyd.BattleCreate)

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.mainRoleA_ = arg_1_1.main_role_a
	arg_1_0.mainRoleB_ = arg_1_1.main_role_b
	arg_1_0.isShowResult = arg_1_1.isShowResult
end

function var_0_0.setupConfig(arg_2_0)
	var_0_0.super.setupConfig(arg_2_0)

	ngx.ctx.battle.isActivity = true
end

function var_0_0.resetConfig(arg_3_0)
	var_0_0.super.resetConfig(arg_3_0)

	ngx.ctx.battle.isActivity = true
end

function var_0_0.initFormation(arg_4_0)
	local var_4_0 = next(ngx.ctx.battle.teamA) == nil

	if next(ngx.ctx.battle.teamA) == nil then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0.herosA) do
			table.insert(ngx.ctx.battle.teamA, arg_4_0:newFighter(iter_4_1, xyd.TeamType.A, false))
		end

		if arg_4_0.mainRoleA_ then
			local var_4_1 = arg_4_0:newFighter(arg_4_0.mainRoleA_, xyd.TeamType.A, false, true)
			local var_4_2 = arg_4_0.mainRoleA_:getEffectBuffID()

			if var_4_2 > 0 then
				local var_4_3 = arg_4_0:newBuffs({
					var_4_2
				}, var_4_1, var_4_1, var_4_1:getEnergySkillID())

				var_4_1:addBuffs(var_4_3)
			end

			table.insert(ngx.ctx.battle.teamA, var_4_1)
		end
	else
		for iter_4_2, iter_4_3 in ipairs(ngx.ctx.battle.teamA) do
			if not iter_4_3:isDeath() then
				iter_4_3.fighterModel.headerView_:setCount(0)
				iter_4_3:getFighterModel():idle()
				iter_4_3:init()
			end
		end
	end

	for iter_4_4, iter_4_5 in ipairs(arg_4_0.herosB) do
		local var_4_4 = arg_4_0:newFighter(iter_4_5, xyd.TeamType.B, true)

		table.insert(ngx.ctx.battle.teamB, var_4_4)

		var_4_4.dropItems_ = {}
		var_4_4.dropMana_ = 0
	end

	if arg_4_0.mainRoleB_ then
		local var_4_5 = arg_4_0:newFighter(arg_4_0.mainRoleB_, xyd.TeamType.B, true, true)
		local var_4_6 = arg_4_0.mainRoleB_:getEffectBuffID()

		if var_4_6 > 0 then
			local var_4_7 = arg_4_0:newBuffs({
				var_4_6
			}, var_4_5, var_4_5, var_4_5:getEnergySkillID())

			var_4_5:addBuffs(var_4_7)
		end

		table.insert(ngx.ctx.battle.teamB, var_4_5)
	end

	if xyd.BattleType.ReplayReport == ngx.ctx.battle.battleType then
		for iter_4_6, iter_4_7 in pairs(arg_4_0.summonMonsters) do
			local var_4_8 = string.sub(iter_4_6, 1, 1) == "A" and xyd.TeamType.A or xyd.TeamType.B
			local var_4_9 = arg_4_0:newFighter(iter_4_7, var_4_8, false)

			var_4_9.fighterIndex = iter_4_6

			var_4_9:setFormationDelay(0, 100)
			var_4_9.fighterModel:removeSelf()

			ngx.ctx.battle.summonMonsters[iter_4_6] = var_4_9
		end
	end

	return var_4_0
end

function var_0_0.setFormationPosition(arg_5_0, arg_5_1)
	if arg_5_1 then
		table.sort(ngx.ctx.battle.teamA, function(arg_6_0, arg_6_1)
			if arg_6_0:isMainRole() or arg_6_1:isMainRole() then
				return arg_6_0:isMainRole() and true or false
			end

			return arg_6_0:getDistance() < arg_6_1:getDistance()
		end)
	end

	table.sort(ngx.ctx.battle.teamB, function(arg_7_0, arg_7_1)
		if arg_7_0:isMainRole() or arg_7_1:isMainRole() then
			return arg_7_0:isMainRole() and true or false
		end

		return arg_7_0:getDistance() < arg_7_1:getDistance()
	end)

	local var_5_0 = 1
	local var_5_1 = 0
	local var_5_2 = 9

	for iter_5_0 = 1, #ngx.ctx.battle.teamA do
		local var_5_3 = ngx.ctx.battle.teamA[iter_5_0]

		if not var_5_3:isDeath() then
			var_5_3.fighterIndex = "A|" .. iter_5_0
			var_5_1 = var_5_3:setFormation(var_5_0, var_5_1, var_5_2)

			var_5_3:setFormationDelay(xyd.tables.battleConfig.skillDelayQueue[var_5_0], xyd.tables.battleConfig.formationWalkQueue[var_5_0])
			table.insert(ngx.ctx.battle.yOrder, var_5_3)

			var_5_0 = var_5_0 + 1
			var_5_2 = var_5_2 - 2
		end
	end

	local var_5_4 = 0
	local var_5_5 = 10

	for iter_5_1 = 1, #ngx.ctx.battle.teamB do
		local var_5_6 = ngx.ctx.battle.teamB[iter_5_1]

		var_5_6.fighterIndex = "B|" .. iter_5_1
		var_5_4 = var_5_6:setFormation(iter_5_1, var_5_4, var_5_5)

		var_5_6:setFormationDelay(xyd.tables.battleConfig.skillDelayQueue[iter_5_1], xyd.tables.battleConfig.formationWalkQueue[iter_5_1])
		table.insert(ngx.ctx.battle.yOrder, var_5_6)

		var_5_5 = var_5_5 - 2
	end

	if arg_5_0.sceneFighter then
		arg_5_0.sceneFighter.fighterIndex = "C|1"
	end
end

function var_0_0.setupWindows(arg_8_0)
	local var_8_0 = {
		heros = arg_8_0.herosA,
		pets = {
			arg_8_0.mainRoleA_
		}
	}

	if arg_8_0.location and arg_8_0.location == 0 then
		var_8_0.heros = arg_8_0.herosB
		var_8_0.pets = arg_8_0.petsB
	end

	arg_8_0.battleBottomWindow = xyd.WindowManager.get():openWindow(xyd.WindowName.battleBottomWnd, var_8_0)
	arg_8_0.battleTopWindow = xyd.WindowManager.get():openWindow(xyd.WindowName.battleTopWnd)

	if arg_8_0.battleTopWindow ~= nil then
		arg_8_0.battleTopWindow:getAwakeDamage():hide()
		arg_8_0.battleTopWindow:getAwakeSelfKill():hide()

		if arg_8_0:isPausable() then
			cc.EventProxy.new(arg_8_0.battleTopWindow, arg_8_0.battleTopWindow):addEventListener(xyd.event.EXIT_BATTLE, function(arg_9_0)
				ngx.ctx.battle.isEnd = true

				arg_8_0:pauseBattle()
				arg_8_0:sendBattleResult(true)
			end):addEventListener(xyd.event.BATTLE_PAUSED, function()
				arg_8_0:pauseBattle()
			end):addEventListener(xyd.event.BATTLE_RESUMED, function()
				if arg_8_0.handler == nil and arg_8_0.isBattleEnded_ ~= true then
					arg_8_0:startBattle()
				end
			end)
		end

		if arg_8_0:isShowPauseBtn() then
			arg_8_0.battleTopWindow:showPauseButton()
		else
			arg_8_0.battleTopWindow:hidePauseButton()
		end
	end

	if arg_8_0.battleBottomWindow then
		local var_8_1 = arg_8_0.battleBottomWindow:nextBattleBtn()

		var_8_1:setTouchEnabled(true)
		var_8_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
			if arg_12_0.name == "ended" then
				arg_8_0:clickNextBattle()
			end

			return true
		end)
	end
end

function var_0_0.newFighter(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4)
	local var_13_0 = arg_13_1:className()
	local var_13_1 = ngx.ctx.battle.requireFighter(var_13_0).new({
		is_arena = arg_13_0:isArena()
	})

	var_13_1:setIsMainRole(arg_13_4)
	var_13_1:populateWithHero(arg_13_1)
	var_13_1:setTeamType(arg_13_2)
	var_13_1:initModels()
	var_13_1:setTimeScale(ngx.ctx.battle.timeScale)
	var_13_1.fighterModel:addTo(ngx.ctx.battle.playerLayer)
	var_13_1:getFighterModel():idle()

	local var_13_2 = arg_13_2 - 1

	var_13_1.fighterModel:initHeaderView(var_13_2)
	var_13_1:getFighterModel():flipX(arg_13_3)

	return var_13_1
end

function var_0_0.setAvatar(arg_14_0)
	local var_14_0 = ngx.ctx.battle.teamA

	if arg_14_0.location and arg_14_0.location == 0 then
		var_14_0 = ngx.ctx.battle.teamB
	end

	local var_14_1 = 0

	for iter_14_0, iter_14_1 in ipairs(var_14_0) do
		if iter_14_1:isMainRole() then
			local var_14_2 = arg_14_0.battleBottomWindow:getPetAvatar()

			var_14_2:removeAllNodeEventListeners()
			var_14_2:setTouchEnabled(true)
			var_14_2:removeAllNodeEventListeners()
			var_14_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
				arg_14_0:clickAvatar(iter_14_1, arg_15_0)

				return true
			end)

			local var_14_3 = arg_14_0.battleBottomWindow:getPetMPBar()

			iter_14_1:setAvatar(var_14_2, nil, var_14_3)
		elseif iter_14_1:getSummonType() == xyd.summonMonsterType.None then
			var_14_1 = var_14_1 + 1

			local var_14_4 = arg_14_0.battleBottomWindow:getButtonByIndex(var_14_1)

			var_14_4:removeAllNodeEventListeners()
			var_14_4:setTouchEnabled(true)
			var_14_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
				arg_14_0:clickAvatar(iter_14_1, arg_16_0)

				return true
			end)

			local var_14_5 = arg_14_0.battleBottomWindow:getHpBarByIndex(var_14_1)
			local var_14_6 = arg_14_0.battleBottomWindow:getMpBarByIndex(var_14_1)

			iter_14_1:setAvatar(var_14_4, var_14_5, var_14_6, var_14_1)
		end
	end

	for iter_14_2, iter_14_3 in ipairs(ngx.ctx.battle.teamB) do
		if iter_14_3:isBoss() then
			iter_14_3:setBossAvatar()
		end
	end
end

function var_0_0.checkEnd(arg_17_0, arg_17_1)
	if arg_17_1 == xyd.TeamType.B then
		for iter_17_0, iter_17_1 in ipairs(ngx.ctx.battle.teamA) do
			if iter_17_1:isMainRole() and (not iter_17_1:isDeath() or iter_17_1:canReborn()) then
				return false
			end
		end

		return true
	else
		for iter_17_2, iter_17_3 in ipairs(ngx.ctx.battle.teamB) do
			if iter_17_3:isMainRole() and (not iter_17_3:isDeath() or iter_17_3:canReborn()) then
				return false
			end
		end

		return true
	end
end

function var_0_0.sendBattleResult(arg_18_0, arg_18_1)
	local function var_18_0(arg_19_0)
		if not arg_19_0 then
			return
		end

		xyd.WindowManager.get():closeWindow(xyd.WindowName.battleBottomWnd)
		xyd.WindowManager.get():closeWindow(xyd.WindowName.battleTopWnd, function()
			cc.Director:getInstance():popToRootScene()
		end)
	end

	if arg_18_0.campaignType == xyd.CampaignType.SNOW then
		if arg_18_0.isShowResult then
			arg_18_0:snowResult(arg_18_1)
		else
			arg_18_0:runActionOnce(cc.CallFunc:create(function()
				arg_18_0:finishBattle({}, {})
			end), false, nil, 2)
		end
	end
end

function var_0_0.snowResult(arg_22_0, arg_22_1)
	xyd.WindowManager.get():closeWindow(xyd.WindowName.battleTopWnd)
	xyd.WindowManager.get():closeWindow(xyd.WindowName.battleBottomWnd)

	local var_22_0 = {
		isWin = arg_22_0:getBattleStar() > 0 and 1 or 0
	}

	xyd.WindowManager.get():openWindow("snow_battle_result", var_22_0, function(arg_23_0)
		if arg_23_0 == nil then
			return
		end

		arg_22_0.battleEndWindow_ = arg_23_0

		cc.EventProxy.new(arg_22_0.battleEndWindow_, arg_22_0.battleEndWindow_):addEventListener(xyd.event.BATTLE_END_BACK_TO_MAIN, function(arg_24_0)
			arg_22_0:closeBattleEndWindow(function()
				xyd.WindowManager.get():closeAllWindows()
				ngx.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end)
		end)
	end)
end

function var_0_0.finishBattle(arg_26_0, arg_26_1, arg_26_2)
	xyd.WindowManager.get():closeWindow(xyd.WindowName.battleTopWnd)
	xyd.WindowManager.get():closeWindow(xyd.WindowName.battleBottomWnd)

	local var_26_0 = {}
	local var_26_1 = {}
	local var_26_2 = {}
	local var_26_3 = {}

	for iter_26_0, iter_26_1 in ipairs(ngx.ctx.battle.teamA) do
		if iter_26_1:isMainRole() then
			table.insert(var_26_2, iter_26_1)
		elseif iter_26_1:getSummonType() == xyd.summonMonsterType.None then
			table.insert(var_26_0, iter_26_1)
		end
	end

	for iter_26_2, iter_26_3 in ipairs(ngx.ctx.battle.teamB) do
		if iter_26_3:isMainRole() then
			table.insert(var_26_3, iter_26_3)
		elseif iter_26_3:getSummonType() == xyd.summonMonsterType.None then
			table.insert(var_26_1, iter_26_3)
		end
	end

	arg_26_0:clearFormation(true)

	if arg_26_0:getBattleStar() > 0 then
		local var_26_4 = {
			star = arg_26_0:getBattleStar(),
			campaignID = arg_26_0.campaignID,
			campaignType = arg_26_0.campaignType,
			fighterA = var_26_0,
			fighterB = var_26_1,
			petA = var_26_2,
			petB = var_26_3,
			mana = ngx.ctx.battle.dropManaCount,
			items = arg_26_0.dropItems,
			heroExp = arg_26_1 and arg_26_1.exps or {},
			data = arg_26_2,
			favorDegreeUp = arg_26_0.favorDegreeUp,
			allParams = arg_26_0.allParams
		}

		xyd.WindowManager.get():openWindow(xyd.WindowName.battleWinWnd, var_26_4, function(arg_27_0)
			if arg_27_0 == nil then
				return
			end

			arg_26_0.battleEndWindow_ = arg_27_0

			cc.EventProxy.new(arg_26_0.battleEndWindow_, arg_26_0.battleEndWindow_):addEventListener(xyd.event.BATTLE_END_BACK_TO_MAIN, function(arg_28_0)
				arg_26_0:closeBattleEndWindow(function()
					xyd.WindowManager.get():closeAllWindows()
					ngx.ctx.battle.releaseCache()
					cc.Director:getInstance():popScene()
				end)
			end)
		end)
	else
		xyd.WindowManager.get():openWindow(xyd.WindowName.battleLoseWnd, {
			star = arg_26_0:getBattleStar(),
			campaignID = arg_26_0.campaignID,
			campaignType = arg_26_0.campaignType,
			fighterA = var_26_0,
			fighterB = var_26_1,
			petA = var_26_2,
			petB = var_26_3,
			is_timeout = arg_26_0.timeOut_,
			allParams = arg_26_0.allParams
		}, function(arg_30_0)
			if arg_30_0 == nil then
				return
			end

			arg_26_0.battleEndWindow_ = arg_30_0

			cc.EventProxy.new(arg_26_0.battleEndWindow_, arg_26_0.battleEndWindow_):addEventListener(xyd.event.BATTLE_END_BACK_TO_MAIN, function(arg_31_0)
				arg_26_0:closeBattleEndWindow(function()
					xyd.battleBackEnterWindow = arg_31_0.click_id

					xyd.WindowManager.get():closeAllWindows()
					ngx.ctx.battle.releaseCache()
					cc.Director:getInstance():popScene()
				end)
			end)
		end)
	end
end

function var_0_0.getBattleStar(arg_33_0)
	if xyd.BattleType.ReplayReport == ngx.ctx.battle.battleType then
		return arg_33_0.reportStar_
	end

	if arg_33_0.battleStar_ and arg_33_0.battleStar_ >= 0 then
		return arg_33_0.battleStar_
	end

	return arg_33_0:getDefaultBattleStar()
end

function var_0_0.getDefaultBattleStar(arg_34_0)
	if not arg_34_0.isBattleEnded_ or arg_34_0.timeOut_ then
		arg_34_0.battleStar_ = 0

		return 0
	end

	local var_34_0 = false

	for iter_34_0, iter_34_1 in pairs(ngx.ctx.battle.teamA) do
		if iter_34_1:isMainRole() and iter_34_1:isDeath() then
			var_34_0 = true

			break
		end
	end

	if var_34_0 then
		arg_34_0.battleStar_ = 0
	else
		arg_34_0.battleStar_ = 3
	end

	return arg_34_0.battleStar_
end

return var_0_0
