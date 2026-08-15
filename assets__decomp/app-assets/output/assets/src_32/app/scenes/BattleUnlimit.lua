local var_0_0 = class("BattleUnlimit", import("app.scenes.BattleCreate"))
local var_0_1 = ngx.ctx.battle.getRequire("Hero")
local var_0_2 = ngx.ctx.battle.getRequire("Buff")
local var_0_3 = {
	0,
	100,
	200,
	300,
	400,
	600
}
local var_0_4 = {
	40010209,
	40010256
}
local var_0_5 = {
	10001,
	10002,
	10003
}
local var_0_6 = {
	40010257,
	40010258
}
local var_0_7 = 5
local var_0_8 = 5
local var_0_9 = "images/maps/shxm.png"
local var_0_10 = xyd.tables.translation
local var_0_11 = xyd.tables.incubusMonsterTable
local var_0_12 = xyd.tables.incubusTable
local var_0_13 = xyd.tables.dbuff
local var_0_14 = xyd.tables.incubusMissionTable
local var_0_15 = import("app.model.Item")
local var_0_16 = import("app.common.ui.SpineEffect")
local var_0_17 = "skeletons/ui_effect/incubus_choose/incubus_choose1"
local var_0_18 = "skeletons/ui_effect/incubus_choose/incubus_choose2.spine"
local var_0_19 = "skeletons/ui_effect/incubus_choose/energy_effect"
local var_0_20 = 142
local var_0_21 = xyd
local var_0_22 = ngx
local var_0_23 = math.min
local var_0_24 = math.max
local var_0_25 = math.abs
local var_0_26 = math.floor
local var_0_27 = math.ceil
local var_0_28 = math.sqrt

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.nextMonsters = {}
	arg_1_0.standbyHeros = arg_1_1.supportHeros or {}
	arg_1_0.unlimitID = tonumber(arg_1_1.id)
	arg_1_0.summonTimes = 0
	arg_1_0.currentTimes = 1
	arg_1_0.nextMonsterTime = 180
	arg_1_0.currentEnergy = 0
	arg_1_0.currentTargetEnergy = 300
	arg_1_0.monsterDrops = arg_1_1.drops or {}
	arg_1_0.mainTargetID = arg_1_1.partner
	arg_1_0.defenderID = arg_1_1.guard
	arg_1_0.mainTarget = nil
	arg_1_0.avatarEffect1_ = nil
	arg_1_0.avatarEffect2_ = nil
	arg_1_0.energyEffect_ = nil
	arg_1_0.isAwakeSecond_ = arg_1_1.isAwakeTwice or false
end

function var_0_0.init(arg_2_0)
	arg_2_0.summonCD_ = 0
	arg_2_0.isWin_ = false
	arg_2_0.unlimitBattleEnd_ = false
	var_0_22.ctx.battle.isUnlimitBattle = true
	arg_2_0.isClicked = false
	arg_2_0.isTipsShow_ = false
	arg_2_0.canSummonMonster = true
	arg_2_0.dropItems_ = {}
	arg_2_0.aliveMonsters = {}
	arg_2_0.aliveTeamates_ = {}
	arg_2_0.moveHeros_ = {}
	arg_2_0.deadHeros_ = {}
	arg_2_0.listHeros_ = {}
	arg_2_0.listNodes_ = {}

	arg_2_0:updateEnergyTarget()
	arg_2_0:setupBasicData()

	arg_2_0.hurtPerSecond = var_0_12:debuff(arg_2_0.unlimitID) * 0.01
	arg_2_0.mainTargetHurt = var_0_12:debuff2(arg_2_0.unlimitID) * 0.01
	arg_2_0.nodeTable = var_0_12:node(arg_2_0.unlimitID)
	arg_2_0.cureTable = var_0_12:cure(arg_2_0.unlimitID)
	arg_2_0.addHpLimit = var_0_12:addHpLimit(arg_2_0.unlimitID)
	arg_2_0.missionNum_ = var_0_12:missionNum(arg_2_0.unlimitID)

	var_0_22.ctx.battle.playerLayer:size(var_0_21.UNLIMIT_STAGE_WIDTH, var_0_21.UNLIMIT_STAGE_HEIGHT)
	var_0_22.ctx.battle.playerLayer:setScale(0.6)
	var_0_22.ctx.battle.unitLayer:size(var_0_21.UNLIMIT_STAGE_WIDTH, var_0_21.UNLIMIT_STAGE_HEIGHT)
	var_0_22.ctx.battle.unitLayer:setScale(0.6)
	var_0_22.ctx.battle.unitBottomLayer:size(var_0_21.UNLIMIT_STAGE_WIDTH, var_0_21.UNLIMIT_STAGE_HEIGHT)
	var_0_22.ctx.battle.unitBottomLayer:setScale(0.6)

	local var_2_0 = {}

	if arg_2_0.isAwakeSecond_ then
		for iter_2_0 = 1, #var_0_12:beginName(arg_2_0.unlimitID) do
			local var_2_1 = {
				name = var_0_12:beginName(arg_2_0.unlimitID)[iter_2_0],
				img = var_0_12:beginImg(arg_2_0.unlimitID)[iter_2_0],
				dialog = var_0_12:begin(arg_2_0.unlimitID)[iter_2_0],
				position = var_0_12:beginPosition_(arg_2_0.unlimitID)[iter_2_0]
			}

			table.insert(var_2_0, var_2_1)
		end
	else
		for iter_2_1 = 1, #var_0_12:dialogName(arg_2_0.unlimitID) do
			local var_2_2 = {
				name = var_0_12:dialogName(arg_2_0.unlimitID)[iter_2_1],
				img = var_0_12:img(arg_2_0.unlimitID)[iter_2_1],
				dialog = var_0_12:begin(arg_2_0.unlimitID)[iter_2_1],
				position = var_0_12:position(arg_2_0.unlimitID)[iter_2_1]
			}

			table.insert(var_2_0, var_2_2)
		end
	end

	local var_2_3 = var_0_21.WindowManager.get():openWindow("dialog", {
		dialog_data = var_2_0
	})

	cc.EventProxy.new(var_2_3, var_2_3):addEventListener(var_0_21.event.DIALOG_COMPLETE, function(arg_3_0)
		local var_3_0 = cc.Sequence:create({
			cc.MoveBy:create(1, cc.p(var_0_21.UNLIMIT_STAGE_WIDTH, 0)),
			cc.CallFunc:create(function()
				arg_2_0:startBattle()
			end)
		})

		arg_2_0.mainTarget.fighterModel:runAction(var_3_0)

		for iter_3_0, iter_3_1 in ipairs(arg_2_0.moveHeros_) do
			local var_3_1 = cc.Sequence:create({
				cc.MoveBy:create(1, cc.p(var_0_21.UNLIMIT_STAGE_WIDTH, 0)),
				cc.CallFunc:create(function()
					iter_3_1:updateHp(0)
					iter_3_1:die()
				end)
			})

			iter_3_1.fighterModel:runAction(var_3_1)
		end

		var_0_22.ctx.battle.background:runAction(cc.MoveBy:create(1, cc.p(0.5 * arg_2_0:getWidth(), 0)))
	end)
end

function var_0_0.updateMonsterID(arg_6_0)
	arg_6_0.currentMonsterID = tonumber(string.format("%d%03d", arg_6_0.unlimitID, arg_6_0.currentTimes))
	arg_6_0.leftMonsterID_ = var_0_11:leftMonster(arg_6_0.currentMonsterID)
	arg_6_0.rightMonsterID_ = var_0_11:rightMonster(arg_6_0.currentMonsterID)

	arg_6_0:updateMonster()
end

function var_0_0.updateMonster(arg_7_0)
	arg_7_0.leftMonster_ = {}
	arg_7_0.rightMonster_ = {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.leftMonsterID_) do
		local var_7_0 = var_0_1.new()

		var_7_0:populateWithTableID(iter_7_1)

		local var_7_1 = arg_7_0:newFighter(var_7_0, var_0_21.TeamType.B, true)

		table.insert(arg_7_0.leftMonster_, var_7_1)
		var_7_1.fighterModel:hide()

		local var_7_2 = arg_7_0.monsterDrops[tostring(iter_7_1)]

		if var_7_2 then
			local var_7_3 = {}

			for iter_7_2, iter_7_3 in pairs(var_7_2) do
				for iter_7_4 = 1, iter_7_3.item_num do
					local var_7_4 = var_0_15.new()

					var_7_4:populate({
						table_id = iter_7_3.item_id
					})
					table.insert(var_7_3, var_7_4)
				end
			end

			var_7_1.dropItems_ = var_7_3
		else
			var_7_1.dropItems_ = {}
		end

		var_7_1.dropMana_ = 0
	end

	for iter_7_5, iter_7_6 in ipairs(arg_7_0.rightMonsterID_) do
		local var_7_5 = var_0_1.new()

		var_7_5:populateWithTableID(iter_7_6)

		local var_7_6 = arg_7_0:newFighter(var_7_5, var_0_21.TeamType.B, true)

		table.insert(arg_7_0.rightMonster_, var_7_6)
		var_7_6.fighterModel:hide()

		local var_7_7 = arg_7_0.monsterDrops[tostring(iter_7_6)]

		if var_7_7 then
			local var_7_8 = {}

			for iter_7_7, iter_7_8 in ipairs(var_7_7) do
				for iter_7_9 = 1, iter_7_8.item_num do
					local var_7_9 = var_0_15.new()

					var_7_9:populate({
						table_id = iter_7_8.item_id
					})
					table.insert(var_7_8, var_7_9)
				end
			end

			var_7_6.dropItems_ = var_7_8
		else
			var_7_6.dropItems_ = {}
		end

		var_7_6.dropMana_ = 0
	end

	if next(arg_7_0.leftMonster_) or next(arg_7_0.rightMonster_) then
		arg_7_0.canSummonMonster = true
	else
		arg_7_0.canSummonMonster = false
	end
end

function var_0_0.onEnterTransitionFinish(arg_8_0)
	var_0_0.super.onEnterTransitionFinish(arg_8_0)
	arg_8_0:setupHeros()
end

function var_0_0.setupHeros(arg_9_0)
	local var_9_0 = cc.p(var_0_21.UNLIMIT_STAGE_WIDTH * 0.5, var_0_21.UNLIMIT_STAGE_HEIGHT * 0.5 - 50)
	local var_9_1 = var_9_0.x
	local var_9_2 = var_9_0.y
	local var_9_3 = var_0_1.new()

	var_9_3:populateWithTableID(arg_9_0.mainTargetID)

	local var_9_4 = arg_9_0:newFighter(var_9_3, var_0_21.TeamType.A, false)

	var_9_4.fighterModel:pos(var_9_1, var_9_2)

	local var_9_5 = #var_0_22.ctx.battle.teamA + 1

	var_9_4.fighterIndex = "A|" .. var_9_5

	var_9_4:setFormationDelay(var_0_21.tables.battleConfig.skillDelayQueue[var_9_5], var_0_21.tables.battleConfig.formationWalkQueue[var_9_5])
	var_9_4:setupBattleAttrInfo()
	var_9_4:setGlobalBuffs()
	var_9_4:addBuffs(arg_9_0:newBuff(var_0_4, var_9_4, var_9_4:getEnergySkillID()))
	table.insert(var_0_22.ctx.battle.teamA, var_9_4)

	arg_9_0.mainTarget = var_9_4

	for iter_9_0 = 1, 2 do
		local var_9_6 = var_0_1.new()

		var_9_6:populateWithTableID(arg_9_0.defenderID[iter_9_0])

		local var_9_7 = arg_9_0:newFighter(var_9_6, var_0_21.TeamType.A, false)

		if iter_9_0 == 1 then
			var_9_7.fighterModel:pos(var_9_1 - 300, var_9_2)
		else
			var_9_7.fighterModel:pos(var_9_1 + 300, var_9_2)
			var_9_7:flipX(true)
		end

		local var_9_8 = #var_0_22.ctx.battle.teamA + 1

		var_9_7.fighterIndex = "A|" .. var_9_8

		var_9_7:setFormationDelay(var_0_21.tables.battleConfig.skillDelayQueue[var_9_8], var_0_21.tables.battleConfig.formationWalkQueue[var_9_8])
		var_9_7:setupBattleAttrInfo()
		var_9_7:setGlobalBuffs()
		table.insert(var_0_22.ctx.battle.teamA, var_9_7)
		table.insert(arg_9_0.moveHeros_, var_9_7)
	end

	arg_9_0:setAvatarContainer()
end

function var_0_0.setAvatarContainer(arg_10_0)
	local var_10_0 = arg_10_0.mainTarget.hero_
	local var_10_1 = arg_10_0.battleTopWindow:getUnlimitAvartarContainer()

	var_10_1:removeAllChildren()

	local var_10_2 = var_10_0:getAvatar(2)
	local var_10_3 = var_0_21.AssetLoader.get():loadSprite(var_10_2)

	var_10_3:align(display.CENTER_BOTTOM, var_10_1:getWidth() / 2, 0):addTo(var_10_1)
	var_10_3:scale(100 / var_10_3:getWidth())
end

function var_0_0.setupWindows(arg_11_0)
	local var_11_0 = {
		heros = arg_11_0.herosA,
		optionHeros = arg_11_0.standbyHeros
	}

	var_11_0.isUnlimit = true
	var_11_0.isAwakeSecond = arg_11_0.isAwakeSecond_
	arg_11_0.battleBottomWindow = var_0_21.WindowManager.get():openWindow(var_0_21.WindowName.battleBottomWnd, var_11_0)
	arg_11_0.battleTopWindow = var_0_21.WindowManager.get():openWindow(var_0_21.WindowName.battleTopWnd)

	if arg_11_0.battleTopWindow ~= nil then
		arg_11_0.battleTopWindow:getAwakeDamage():hide()
		arg_11_0.battleTopWindow:getAwakeSelfKill():hide()
		arg_11_0:setDegree()
		arg_11_0.battleTopWindow:nodeByName("enemy_txt"):setString(var_0_10:translation("INCUBUS_ENEMYNUM"))
		arg_11_0.battleTopWindow:nodeByName("enemy_num"):setString("0")
		arg_11_0.battleTopWindow:nodeByName("teammate_txt"):setString(var_0_10:translation("INCUBUS_TEAMATE"))
		arg_11_0.battleTopWindow:nodeByName("teamate_num"):setString("0")
		arg_11_0.battleTopWindow:showUnlimitIcons()

		if arg_11_0:isPausable() then
			cc.EventProxy.new(arg_11_0.battleTopWindow, arg_11_0.battleTopWindow):addEventListener(var_0_21.event.EXIT_BATTLE, function(arg_12_0)
				var_0_22.ctx.battle.isEnd = true
				var_0_22.ctx.battle.isUnlimitBattle = false

				arg_11_0:pauseBattle()
				arg_11_0:sendBattleResult(true)
			end):addEventListener(var_0_21.event.BATTLE_PAUSED, function()
				arg_11_0:pauseBattle()
			end):addEventListener(var_0_21.event.BATTLE_RESUMED, function()
				if arg_11_0.handler == nil and arg_11_0.isBattleEnded_ ~= true then
					arg_11_0:startBattle()
				end
			end)
		end

		if arg_11_0:isShowPauseBtn() then
			arg_11_0.battleTopWindow:showPauseButton()
		else
			arg_11_0.battleTopWindow:hidePauseButton()
		end
	end

	if arg_11_0.battleBottomWindow then
		arg_11_0.battleBottomWindow:nextBattleBtn():hide()
		arg_11_0.battleBottomWindow:getAutoBtn():hide()
		arg_11_0.battleBottomWindow:showUnlimitContainer()
		arg_11_0.battleBottomWindow:nodeByName("battle_hero_tips"):setString(var_0_10:translation("INCUBUS_TIPS_NOTICE"))

		arg_11_0.xLeft, arg_11_0.xRight, arg_11_0.yBottom, arg_11_0.yUp = arg_11_0.battleBottomWindow:getUnlimitBorder()

		if arg_11_0.isAwakeSecond_ then
			arg_11_0.battleBottomWindow:nodeByName("defence_bottom_bg2"):setVisible(true)

			arg_11_0.heroList_ = cc.ui.UIListView.new({
				viewRect = cc.rect(0, 0, 700, 130),
				padding_ = {
					top = 0,
					bottom = 0,
					left = 0,
					right = 0
				},
				direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
			}):addTo(arg_11_0.battleBottomWindow:nodeByName("icon_position")):onScroll(handler(arg_11_0, arg_11_0.scrollListener))

			arg_11_0.heroList_:setAnchorPoint(cc.p(0, 0))
			arg_11_0.heroList_:setPosition(-350, 0)
		end
	end
end

function var_0_0.listLayout(arg_15_0, arg_15_1)
	local var_15_0 = display.newNode()
	local var_15_1 = arg_15_0.heroList_:newItem()

	for iter_15_0 = 1, #arg_15_1 do
		local var_15_2 = cc.Node:create()
		local var_15_3 = arg_15_1[iter_15_0]
		local var_15_4 = var_0_21.AssetLoader.get():loadNodeFromJson("windows/battle/unlimit_avatar.csb")

		var_15_4:setContentSize(108, 108)
		var_0_21.setAvatarBorderNewUI(var_15_3, var_15_4:getChildByName("avatar"))

		local var_15_5 = var_15_4:getChildByName("mask")

		var_15_5:setLocalZOrder(2)
		var_15_5:setVisible(true)
		var_15_4:setName("layout")
		var_15_2:addChild(var_15_4)
		var_15_2:setContentSize(108, 108)
		var_15_2:setAnchorPoint(cc.p(0, 0))
		var_15_2:setPosition(cc.p(var_0_20 * (iter_15_0 - 1), 11))
		var_15_2:setTouchEnabled(true)
		var_15_2:setTouchSwallowEnabled(false)

		local var_15_6 = arg_15_0:newFighter(var_15_3, var_0_21.TeamType.A, false)

		var_15_6.fighterModel:hide()
		table.insert(arg_15_0.listHeros_, var_15_6)
		table.insert(arg_15_0.listNodes_, var_15_2)
		var_15_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
			arg_15_0:clickAvatar(var_15_6, arg_16_0, iter_15_0)

			return true
		end)
		var_15_0:addChild(var_15_2)
	end

	var_15_0:setContentSize(700, 130)
	var_15_1:addContent(var_15_0)
	var_15_1:setItemSize(700, 130)
	arg_15_0.heroList_:addItem(var_15_1)
	arg_15_0.heroList_:reload()
end

function var_0_0.scrollListener(arg_17_0, arg_17_1)
	if arg_17_1.name == "began" then
		arg_17_0.scrollViewMoved_ = false
		arg_17_0.prevX_ = arg_17_1.x
	elseif arg_17_1.name == "moved" and 20 <= math.abs(arg_17_1.x - arg_17_0.prevX_) then
		arg_17_0.scrollViewMoved_ = true
	end
end

function var_0_0.mainLoop(arg_18_0)
	if tolua.isnull(arg_18_0) then
		arg_18_0:pauseBattle()

		return
	end

	if arg_18_0.unlimitBattleEnd_ then
		return
	end

	if arg_18_0:checkEnds() then
		arg_18_0.unlimitBattleEnd_ = true

		var_0_22.ctx.battle.unitLayer:removeAllChildren()
		var_0_22.ctx.battle.unitBottomLayer:removeAllChildren()

		local var_18_0 = cc.Sequence:create({
			cc.MoveBy:create(1, cc.p(-arg_18_0:getWidth(), 0)),
			cc.CallFunc:create(function()
				local var_19_0 = {}

				if arg_18_0.isAwakeSecond_ then
					if arg_18_0.isWin_ then
						for iter_19_0 = 1, #var_0_12:winName(arg_18_0.unlimitID) do
							local var_19_1 = {
								name = var_0_12:winName(arg_18_0.unlimitID)[iter_19_0],
								img = var_0_12:winImg(arg_18_0.unlimitID)[iter_19_0],
								position = var_0_12:winPosition(arg_18_0.unlimitID)[iter_19_0],
								dialog = var_0_12:win(arg_18_0.unlimitID)[iter_19_0]
							}

							table.insert(var_19_0, var_19_1)
						end
					else
						for iter_19_1 = 1, #var_0_12:loseName(arg_18_0.unlimitID) do
							local var_19_2 = {
								name = var_0_12:loseName(arg_18_0.unlimitID)[iter_19_1],
								img = var_0_12:loseImg(arg_18_0.unlimitID)[iter_19_1],
								position = var_0_12:losePosition(arg_18_0.unlimitID)[iter_19_1],
								dialog = var_0_12:lose(arg_18_0.unlimitID)[iter_19_1]
							}

							table.insert(var_19_0, var_19_2)
						end
					end
				else
					for iter_19_2 = 1, #var_0_12:dialogName(arg_18_0.unlimitID) do
						local var_19_3 = {
							name = var_0_12:dialogName(arg_18_0.unlimitID)[iter_19_2],
							img = var_0_12:img(arg_18_0.unlimitID)[iter_19_2],
							position = var_0_12:position(arg_18_0.unlimitID)[iter_19_2]
						}

						if arg_18_0.isWin_ then
							var_19_3.dialog = var_0_12:win(arg_18_0.unlimitID)[iter_19_2]
						else
							var_19_3.dialog = var_0_12:lose(arg_18_0.unlimitID)[iter_19_2]
						end

						table.insert(var_19_0, var_19_3)
					end
				end

				local var_19_4 = var_0_21.WindowManager.get():openWindow("dialog", {
					dialog_data = var_19_0
				})

				cc.EventProxy.new(var_19_4, var_19_4):addEventListener(var_0_21.event.DIALOG_COMPLETE, function(arg_20_0)
					var_0_22.ctx.battle.isUnlimitBattle = false

					arg_18_0:battleEnd()
				end)
			end)
		})

		var_0_22.ctx.battle.playerLayer:runAction(var_18_0)
		var_0_22.ctx.battle.background:runAction(cc.MoveBy:create(1, cc.p(-0.5 * arg_18_0:getWidth(), 0)))
	end

	arg_18_0:checkBlackLayerState()

	for iter_18_0, iter_18_1 in ipairs(var_0_22.ctx.battle.teamA) do
		iter_18_1:singleLoop()
	end

	for iter_18_2, iter_18_3 in ipairs(var_0_22.ctx.battle.teamB) do
		iter_18_3:singleLoop()
	end

	arg_18_0:adjustYs()

	if var_0_22.ctx.battle.isCountHurtNum then
		arg_18_0:setTotalHurt()
	end

	arg_18_0:updateInfoListener()
	arg_18_0:updateWalk2Next()
	var_0_22.ctx.battle.popSoundQueue()

	if var_0_22.ctx.battle.isEnergySkilling and var_0_22.ctx.battle.isEnergySkilling > 0 then
		return
	end

	if var_0_22.ctx.battle.count % (var_0_22.ctx.battleConst.frames * 0.1) == 0 then
		arg_18_0.currentEnergy = math.min(arg_18_0.currentEnergy + 5, 1000)

		arg_18_0:updateCurrentEnergy()

		if arg_18_0.currentEnergy >= arg_18_0.currentTargetEnergy and arg_18_0:aliveTeamates() < var_0_8 then
			arg_18_0:setAvatarBright()

			if not arg_18_0.isTipsShow_ then
				arg_18_0.battleBottomWindow:nodeByName("battle_hero_tips"):show()

				arg_18_0.isTipsShow_ = true
			end

			arg_18_0:setEnergyEffect(true)
		end
	end

	arg_18_0:setupDefendGirlHpBar()

	var_0_22.ctx.battle.count = var_0_22.ctx.battle.count + 1

	if var_0_22.ctx.battle.nightCount > 0 and not arg_18_0.stopTimeCount then
		var_0_22.ctx.battle.nightCount = math.max(var_0_22.ctx.battle.nightCount - 1, 0)
	end

	if var_0_22.ctx.battle.count % var_0_22.ctx.battleConst.frames == 0 then
		arg_18_0:updateEnergyTarget()

		if not arg_18_0.nextMonsterTime then
			arg_18_0:updateHeroHp()
		end
	end

	if var_0_22.ctx.battle.count % 30 == 0 and not arg_18_0.isAwakeSecond_ then
		-- block empty
	end

	if arg_18_0.nextMonsterTime and arg_18_0.nextMonsterTime % 30 == 0 then
		if arg_18_0.nextMonsterTime > 0 then
			local var_18_1 = math.ceil(arg_18_0.nextMonsterTime / 30)
			local var_18_2 = arg_18_0.battleTopWindow:nodeByName("center_num")

			var_18_2:setVisible(true)
			var_18_2:stopAllActions()
			var_18_2:setString(var_18_1)
			var_18_2:setScale(5)
			var_18_2:runAction(cc.ScaleTo:create(1, 0))
		else
			if arg_18_0.canSummonMonster then
				arg_18_0:summonMonster()
			end

			arg_18_0.nextMonsterTime = nil
		end
	end

	if arg_18_0.nextMonsterTime then
		arg_18_0.nextMonsterTime = arg_18_0.nextMonsterTime - 1
	elseif var_0_22.ctx.battle.count % 5 == 0 then
		local var_18_3 = arg_18_0:aliveEnemies()

		if var_18_3 == 0 then
			if arg_18_0.canSummonMonster then
				if not arg_18_0.isAwakeSecond_ and next(arg_18_0.missionNum_) and arg_18_0.currentTimes == arg_18_0.missionNum_[1] then
					arg_18_0:getRandomMission()
					table.remove(arg_18_0.missionNum_, 1)
				elseif not arg_18_0.isAwakeSecond_ then
					arg_18_0:waveCheckMission()
				end

				collectgarbage("collect")
				arg_18_0:summonMonster()
			end
		else
			arg_18_0.battleTopWindow:nodeByName("enemy_num"):setString(var_18_3)
		end

		local var_18_4 = arg_18_0:aliveTeamates()

		arg_18_0.battleTopWindow:nodeByName("teamate_num"):setString(var_18_4)
	end

	if not arg_18_0.stopTimeCount_ then
		var_0_22.ctx.battle.timeCount = var_0_22.ctx.battle.timeCount + 1
	end

	if arg_18_0.summonCD_ > 0 then
		arg_18_0.summonCD_ = arg_18_0.summonCD_ - 1
	end
end

function var_0_0.getRandomMission(arg_21_0)
	arg_21_0.currentMission_ = var_0_5[math.random(1, #var_0_5)]

	local var_21_0 = var_0_12:rewardBuffs(arg_21_0.unlimitID)
	local var_21_1 = var_0_12:punishBuffs(arg_21_0.unlimitID)

	if arg_21_0.currentMission_ == var_0_21.UnlimtedMissions.LimitedKillWave then
		local var_21_2 = var_0_14:taskNum(arg_21_0.currentMission_)
		local var_21_3 = var_0_14:taskTime(arg_21_0.currentMission_)
		local var_21_4 = math.random(1, #var_21_2)

		arg_21_0.missionWaves_ = var_21_2[var_21_4]
		arg_21_0.missionTimes_ = var_21_3[var_21_4]
		arg_21_0.missionDes_ = string.format(var_0_14:taskDesc(arg_21_0.currentMission_), arg_21_0.missionTimes_, arg_21_0.missionWaves_)
	elseif arg_21_0.currentMission_ == var_0_21.UnlimtedMissions.AssignHeroAlive then
		arg_21_0.missionHero_ = nil

		local var_21_5 = {}

		for iter_21_0, iter_21_1 in ipairs(var_0_22.ctx.battle.teamA) do
			local var_21_6 = iter_21_1:getTableID()

			if iter_21_1:getSummonType() == var_0_21.summonMonsterType.None and not iter_21_1:isDeath() and not iter_21_1:isAffected() and var_21_6 ~= arg_21_0.mainTargetID and var_21_6 ~= arg_21_0.defenderID[1] and var_21_6 ~= arg_21_0.defenderID[2] then
				table.insert(var_21_5, iter_21_1)
			end
		end

		if next(var_21_5) then
			arg_21_0.missionHero_ = var_21_5[math.random(1, #var_21_5)]

			local var_21_7 = var_0_14:taskNum(arg_21_0.currentMission_)

			arg_21_0.missionWaves_ = var_21_7[math.random(1, #var_21_7)]
		else
			arg_21_0:getRandomMission()

			return
		end

		local var_21_8 = arg_21_0.currentTimes + arg_21_0.missionWaves_

		arg_21_0.missionDes_ = string.format(var_0_14:taskDesc(arg_21_0.currentMission_), arg_21_0.missionHero_:getName(), var_21_8)
	elseif arg_21_0.currentMission_ == var_0_21.UnlimtedMissions.BanIncreaseHero then
		arg_21_0.missionHeroLimit_ = 8

		local var_21_9 = var_0_14:taskTime(arg_21_0.currentMission_)

		arg_21_0.missionTimes_ = var_21_9[math.random(1, #var_21_9)]
		arg_21_0.missionDes_ = string.format(var_0_14:taskDesc(arg_21_0.currentMission_), arg_21_0.missionTimes_)
	elseif arg_21_0.currentMission_ == var_0_21.UnlimtedMissions.LimitedKillTarget then
		arg_21_0.missionTimes_ = unpack(var_0_14:taskTime(arg_21_0.currentMission_))

		local var_21_10 = var_0_14:monsterID(arg_21_0.currentMission_)
		local var_21_11 = var_0_1.new()

		var_21_11:populateWithTableID(var_21_10)

		arg_21_0.missionKillTarget_ = arg_21_0:newFighter(var_21_11, var_0_21.TeamType.B, true)
		arg_21_0.hasSummonMissionMonster_ = false
		arg_21_0.missionDes_ = string.format(var_0_14:taskDesc(arg_21_0.currentMission_), arg_21_0.missionTimes_)
	elseif arg_21_0.currentMission_ == var_0_21.UnlimtedMissions.BanArrivalArea then
		arg_21_0.missionTimes_ = unpack(var_0_14:taskTime(arg_21_0.currentMission_))
		arg_21_0.missionRadius_ = var_0_14:radius(arg_21_0.currentMission_)
		arg_21_0.missionDes_ = string.format(var_0_14:taskDesc(arg_21_0.currentMission_), arg_21_0.missionTimes_)

		if not arg_21_0.missionArea_ then
			local var_21_12 = cc.Sprite:create("windows/battle/mission_di.png"):align(display.CENTER, var_0_21.UNLIMIT_STAGE_WIDTH / 2, var_0_21.UNLIMIT_STAGE_HEIGHT / 2):addTo(var_0_22.ctx.battle.unitBottomLayer, -1)

			arg_21_0.missionArea_ = var_21_12

			local var_21_13 = arg_21_0.missionRadius_ * 2 / var_21_12:getContentSize().width

			arg_21_0.missionArea_:setScaleX(var_21_13)
		else
			arg_21_0.missionArea_:setVisible(true)
		end
	end

	arg_21_0.battleTopWindow:nodeByName("mission_text"):setString(arg_21_0.missionDes_)

	arg_21_0.rewardBuff_ = var_21_0[math.random(1, #var_21_0)]
	arg_21_0.punishBuff_ = var_21_1[math.random(1, #var_21_1)]

	arg_21_0.battleTopWindow:nodeByName("award_txt"):setString(string.format(var_0_10:translation("INCUBUS_TIPS_WIN"), var_0_13:desc(arg_21_0.rewardBuff_)))
	arg_21_0.battleTopWindow:nodeByName("punish_txt"):setString(string.format(var_0_10:translation("INCUBUS_TIPS_LOSE"), var_0_13:desc(arg_21_0.punishBuff_)))
	arg_21_0:playMissionAction()
end

function var_0_0.countCheckMission(arg_22_0)
	if arg_22_0.currentMission_ then
		if arg_22_0.currentMission_ == var_0_21.UnlimtedMissions.AssignHeroAlive then
			if arg_22_0.missionHero_ and arg_22_0.missionHero_:isDeath() then
				arg_22_0:missionFail()

				return
			end
		elseif arg_22_0.currentMission_ == var_0_21.UnlimtedMissions.LimitedKillTarget then
			arg_22_0.missionTimes_ = arg_22_0.missionTimes_ - 1

			if arg_22_0.missionTimes_ <= 0 then
				if arg_22_0.missionKillTarget_ and not arg_22_0.missionKillTarget_:isDeath() then
					arg_22_0:missionFail()

					return
				else
					arg_22_0:missionComplete()

					return
				end
			elseif arg_22_0.missionKillTarget_ and arg_22_0.missionKillTarget_:isDeath() then
				arg_22_0:missionComplete()

				return
			end
		elseif arg_22_0.currentMission_ == var_0_21.UnlimtedMissions.BanArrivalArea then
			arg_22_0.missionTimes_ = arg_22_0.missionTimes_ - 1

			if var_0_25(arg_22_0.mainTarget:getNearestTarget():getX() - arg_22_0.mainTarget:getX()) <= arg_22_0.missionRadius_ then
				arg_22_0.missionArea_:setVisible(false)
				arg_22_0:missionFail()

				return
			elseif arg_22_0.missionTimes_ <= 0 then
				arg_22_0.missionArea_:setVisible(false)
				arg_22_0:missionComplete()

				return
			end
		elseif arg_22_0.currentMission_ == var_0_21.UnlimtedMissions.BanIncreaseHero then
			arg_22_0.missionTimes_ = arg_22_0.missionTimes_ - 1

			if arg_22_0.missionTimes_ <= 0 then
				arg_22_0:missionComplete()

				return
			end
		elseif arg_22_0.currentMission_ == var_0_21.UnlimtedMissions.LimitedKillWave then
			arg_22_0.missionTimes_ = arg_22_0.missionTimes_ - 1

			if arg_22_0.missionTimes_ <= 0 then
				arg_22_0:missionFail()

				return
			end
		end

		arg_22_0:updateMissionDesc()
	end
end

function var_0_0.waveCheckMission(arg_23_0)
	if arg_23_0.currentMission_ then
		if arg_23_0.currentMission_ == var_0_21.UnlimtedMissions.LimitedKillWave or arg_23_0.currentMission_ == var_0_21.UnlimtedMissions.AssignHeroAlive then
			arg_23_0.missionWaves_ = arg_23_0.missionWaves_ - 1

			if arg_23_0.missionWaves_ <= 0 then
				arg_23_0:missionComplete()
			end
		end

		arg_23_0:updateMissionDesc()
	end
end

function var_0_0.updateMissionDesc(arg_24_0)
	if arg_24_0.missionDes_ and arg_24_0.currentMission_ then
		if arg_24_0.currentMission_ == var_0_21.UnlimtedMissions.LimitedKillWave then
			arg_24_0.missionDes_ = string.format(var_0_14:taskDesc(arg_24_0.currentMission_), arg_24_0.missionTimes_, arg_24_0.missionWaves_)
		elseif arg_24_0.currentMission_ == var_0_21.UnlimtedMissions.BanIncreaseHero then
			arg_24_0.missionDes_ = string.format(var_0_14:taskDesc(arg_24_0.currentMission_), arg_24_0.missionTimes_)
		elseif arg_24_0.currentMission_ == var_0_21.UnlimtedMissions.LimitedKillTarget then
			arg_24_0.missionDes_ = string.format(var_0_14:taskDesc(arg_24_0.currentMission_), arg_24_0.missionTimes_)
		elseif arg_24_0.currentMission_ == var_0_21.UnlimtedMissions.BanArrivalArea then
			arg_24_0.missionDes_ = string.format(var_0_14:taskDesc(arg_24_0.currentMission_), arg_24_0.missionTimes_)
		end

		arg_24_0.battleTopWindow:nodeByName("mission_text"):setString(arg_24_0.missionDes_)
	end
end

function var_0_0.missionComplete(arg_25_0)
	arg_25_0.currentMission_ = nil

	arg_25_0:addTeamBuffs(var_0_22.ctx.battle.teamA, {
		arg_25_0.rewardBuff_
	})

	local var_25_0 = cc.CallFunc:create(function()
		arg_25_0.battleTopWindow:nodeByName("mission_in"):setVisible(false)
		arg_25_0.battleTopWindow:nodeByName("mission_fail"):setVisible(false)
		arg_25_0.battleTopWindow:nodeByName("mission_complete"):setOpacity(0)
		arg_25_0.battleTopWindow:nodeByName("mission_complete"):setVisible(true)
		arg_25_0.battleTopWindow:nodeByName("mission_complete"):runAction(cc.Sequence:create({
			cc.FadeIn:create(0.3),
			cc.FadeOut:create(0.3),
			cc.FadeIn:create(0.3),
			cc.CallFunc:create(function()
				arg_25_0.battleTopWindow:nodeByName("mission_contain"):runAction(cc.FadeOut:create(2))
			end)
		}))
	end)

	arg_25_0.battleTopWindow:nodeByName("mission_in"):runAction(var_25_0)
	arg_25_0:clearMissionInfos()
end

function var_0_0.missionFail(arg_28_0)
	arg_28_0.currentMission_ = nil

	arg_28_0:addTeamBuffs(var_0_22.ctx.battle.teamA, {
		arg_28_0.punishBuff_
	})

	local var_28_0 = cc.CallFunc:create(function()
		arg_28_0.battleTopWindow:nodeByName("mission_in"):setVisible(false)
		arg_28_0.battleTopWindow:nodeByName("mission_complete"):setVisible(false)
		arg_28_0.battleTopWindow:nodeByName("mission_fail"):setOpacity(0)
		arg_28_0.battleTopWindow:nodeByName("mission_fail"):setVisible(true)
		arg_28_0.battleTopWindow:nodeByName("mission_fail"):runAction(cc.Sequence:create({
			cc.FadeIn:create(0.3),
			cc.FadeOut:create(0.3),
			cc.FadeIn:create(0.3),
			cc.CallFunc:create(function()
				arg_28_0.battleTopWindow:nodeByName("mission_contain"):runAction(cc.FadeOut:create(2))
			end)
		}))
	end)

	arg_28_0.battleTopWindow:nodeByName("mission_in"):runAction(var_28_0)
	arg_28_0:clearMissionInfos()
end

function var_0_0.playMissionAction(arg_31_0)
	arg_31_0.battleTopWindow:nodeByName("mission_contain"):setVisible(true)
	arg_31_0.battleTopWindow:nodeByName("mission_in"):setVisible(true)
	arg_31_0.battleTopWindow:nodeByName("mission_in"):setOpacity(255)
	arg_31_0.battleTopWindow:nodeByName("mission_fail"):setVisible(false)
	arg_31_0.battleTopWindow:nodeByName("mission_complete"):setVisible(false)
	arg_31_0.battleTopWindow:nodeByName("mission_contain"):setOpacity(0)
	arg_31_0.battleTopWindow:nodeByName("mission_contain"):runAction(cc.FadeIn:create(2))
end

function var_0_0.addTeamBuffs(arg_32_0, arg_32_1, arg_32_2)
	for iter_32_0, iter_32_1 in ipairs(arg_32_1) do
		if not iter_32_1:isDeath() and not iter_32_1:isAffected() then
			iter_32_1:addBuffs(arg_32_0:newBuff(arg_32_2, arg_32_0.mainTarget, arg_32_0.mainTarget:getEnergySkillID()))
		end
	end
end

function var_0_0.clearMissionInfos(arg_33_0)
	arg_33_0.missionTimes_ = nil
	arg_33_0.missionWaves_ = nil
	arg_33_0.missionHero_ = nil
	arg_33_0.missionHeroLimit_ = nil
	arg_33_0.missionKillTarget_ = nil
	arg_33_0.rewardBuff_ = nil
	arg_33_0.punishBuff_ = nil

	if arg_33_0.missionArea_ then
		arg_33_0.missionArea_:setVisible(false)
	end
end

function var_0_0.aliveEnemies(arg_34_0)
	for iter_34_0 = #arg_34_0.aliveMonsters, 1, -1 do
		local var_34_0 = arg_34_0.aliveMonsters[iter_34_0]

		if var_34_0:isDeath() and not var_34_0:canReborn() then
			table.remove(arg_34_0.aliveMonsters, iter_34_0)
		end
	end

	return #arg_34_0.aliveMonsters
end

function var_0_0.aliveTeamates(arg_35_0)
	for iter_35_0 = #arg_35_0.aliveTeamates_, 1, -1 do
		local var_35_0 = arg_35_0.aliveTeamates_[iter_35_0]

		if var_35_0:isDeath() and not var_35_0:canReborn() then
			table.remove(arg_35_0.aliveTeamates_, iter_35_0)
		end
	end

	return #arg_35_0.aliveTeamates_
end

function var_0_0.updateHeroHp(arg_36_0)
	for iter_36_0, iter_36_1 in ipairs(var_0_22.ctx.battle.teamA) do
		local var_36_0 = iter_36_1:getTableID()

		if not iter_36_1:isDeath() and not iter_36_1:isAffected() and var_36_0 ~= arg_36_0.mainTargetID and var_36_0 ~= arg_36_0.defenderID[1] and var_36_0 ~= arg_36_0.defenderID[2] then
			local var_36_1 = iter_36_1:getHp()
			local var_36_2 = iter_36_1:getHpLimit() * arg_36_0.hurtPerSecond

			if var_36_2 < var_36_1 then
				iter_36_1:updateHp(var_36_1 - var_36_2)

				if iter_36_1:isDeath() then
					iter_36_1:die()
				end
			end
		end
	end

	if arg_36_0.mainTarget and not arg_36_0.mainTarget:isDeath() then
		local var_36_3 = arg_36_0.mainTarget
		local var_36_4 = var_36_3:getHp()
		local var_36_5 = var_36_3:getHpLimit() * arg_36_0.mainTargetHurt

		var_36_3:updateHp(var_36_4 - var_36_5)
	end
end

function var_0_0.setupDefendGirlHpBar(arg_37_0)
	local var_37_0 = 100
	local var_37_1 = arg_37_0.mainTarget

	if var_37_1 then
		var_37_0 = var_37_1:getHp() / var_37_1:getHpLimit() * 100
	end

	arg_37_0.battleTopWindow:getUnlimitGirlHpBar():setPercent(var_37_0)
end

function var_0_0.initFormation(arg_38_0)
	local var_38_0 = next(var_0_22.ctx.battle.teamA) == nil

	arg_38_0.firstFighter = {}

	for iter_38_0, iter_38_1 in ipairs(arg_38_0.herosA) do
		local var_38_1 = arg_38_0:newFighter(iter_38_1, var_0_21.TeamType.A, false)

		var_38_1.fighterModel:hide()
		table.insert(arg_38_0.firstFighter, var_38_1)
	end

	arg_38_0:updateMonsterID()

	return var_38_0
end

function var_0_0.isHeroMax(arg_39_0)
	local var_39_0 = 0

	for iter_39_0, iter_39_1 in ipairs(var_0_22.ctx.battle.teamA) do
		local var_39_1 = iter_39_1:getTableID()

		if not iter_39_1:isDeath() and iter_39_1:getSummonType() == var_0_21.summonMonsterType.None and var_39_1 ~= arg_39_0.mainTargetID and var_39_1 ~= arg_39_0.defenderID[1] and var_39_1 ~= arg_39_0.defenderID[2] then
			var_39_0 = var_39_0 + 1
		end
	end

	if var_39_0 < var_0_8 then
		return false
	else
		return true
	end
end

function var_0_0.setAvatar(arg_40_0)
	if arg_40_0.isAwakeSecond_ then
		local var_40_0 = {}

		for iter_40_0, iter_40_1 in ipairs(arg_40_0.herosA) do
			table.insert(var_40_0, iter_40_1)
		end

		for iter_40_2, iter_40_3 in ipairs(arg_40_0.standbyHeros) do
			table.insert(var_40_0, iter_40_3)
		end

		arg_40_0:listLayout(var_40_0)
	else
		local var_40_1 = arg_40_0.firstFighter

		for iter_40_4, iter_40_5 in ipairs(var_40_1) do
			if iter_40_5:getSummonType() == var_0_21.summonMonsterType.None then
				local var_40_2 = arg_40_0.battleBottomWindow:getUnlimitContainerByIndex(iter_40_4)

				var_40_2:removeAllNodeEventListeners()
				var_40_2:setTouchEnabled(true)
				var_40_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_41_0)
					arg_40_0:clickAvatar(iter_40_5, arg_41_0, iter_40_4)

					return true
				end)
			end
		end
	end

	local var_40_3 = display.newLayer()

	var_40_3:addTo(arg_40_0)
	var_40_3:setTouchEnabled(true)
	var_40_3:size(var_0_21.UNLIMIT_STAGE_WIDTH, var_0_21.UNLIMIT_STAGE_HEIGHT)
	var_40_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_42_0)
		if arg_40_0.isClicked then
			if arg_42_0.name == "began" or arg_42_0.name == "moved" then
				local var_42_0 = var_40_3:convertToNodeSpace(cc.p(arg_42_0.x, arg_42_0.y))

				arg_40_0.startX_, arg_40_0.startY_ = var_42_0.x, var_42_0.y
			elseif arg_42_0.name == "ended" then
				if arg_40_0:isHeroMax() then
					var_0_21.WindowManager.get():openWindow("toast", {
						message = string.format(var_0_10:translation("INCUBUS_TIPS_NUM"), var_0_8)
					})
				else
					local var_42_1 = arg_40_0.clickedIndex
					local var_42_2 = arg_40_0.clickedFighter

					if arg_40_0.xLeft <= arg_40_0.startX_ and arg_40_0.startX_ <= arg_40_0.xRight and arg_40_0.yBottom <= arg_40_0.startY_ and arg_40_0.startY_ <= arg_40_0.yUp then
						var_42_2.fighterModel:show()

						local var_42_3 = 1
						local var_42_4 = #var_0_22.ctx.battle.teamA + 1

						var_42_2.fighterIndex = "A|" .. var_42_4

						var_42_2:setFormationDelay(var_0_21.tables.battleConfig.skillDelayQueue[var_42_4], var_0_21.tables.battleConfig.formationWalkQueue[var_42_4])
						table.insert(var_0_22.ctx.battle.yOrder, var_42_2)
						table.insert(var_0_22.ctx.battle.teamA, var_42_2)
						table.insert(arg_40_0.aliveTeamates_, var_42_2)
						var_42_2:updateEnergyTo(var_0_21.ENERGY_DECIMAL_BASE)

						local var_42_5 = cc.p(arg_40_0.startX_ / 0.6, arg_40_0.startY_ / 0.6)
						local var_42_6 = var_42_5.x
						local var_42_7 = var_42_5.y

						var_42_2:x(var_42_6)
						var_42_2:y(var_42_7)
						var_42_2:setupBattleAttrInfo()
						var_42_2:setGlobalBuffs()
						var_42_2:addBuffs(arg_40_0:newBuff(var_0_6, var_42_2, var_42_2:getEnergySkillID()))

						arg_40_0.currentEnergy = arg_40_0.currentEnergy - arg_40_0.currentTargetEnergy

						arg_40_0:updateCurrentEnergy()
						arg_40_0:updateEnergyTarget()
						arg_40_0:updateAvatar(var_42_1)
						arg_40_0.battleBottomWindow:getSummonArea():hide()
						arg_40_0.battleBottomWindow:nodeByName("battle_hero_tips"):hide()

						arg_40_0.isClicked = false
						arg_40_0.clickedFighter = nil
						arg_40_0.clickedIndex = 0

						if arg_40_0.avatarEffect1_ then
							arg_40_0.avatarEffect1_:setVisible(false)
						end

						if arg_40_0.avatarEffect2_ then
							arg_40_0.avatarEffect2_:setVisible(false)
						end

						arg_40_0.summonCD_ = 30

						if arg_40_0.currentMission_ and arg_40_0.currentMission_ == var_0_21.UnlimtedMissions.BanIncreaseHero then
							arg_40_0:missionFail()
						end

						for iter_42_0, iter_42_1 in ipairs(arg_40_0.listHeros_) do
							if var_42_2 == iter_42_1 then
								table.remove(arg_40_0.listHeros_, iter_42_0)
							end
						end
					else
						var_0_21.WindowManager.get():openWindow("toast", {
							message = var_0_10:translation("INCUBUS_MISTAKENLY_CLICKHINT")
						})
					end
				end
			end
		end

		return true
	end)
end

function var_0_0.clickAvatar(arg_43_0, arg_43_1, arg_43_2, arg_43_3)
	if arg_43_0:canSummonHero() and not arg_43_0.scrollViewMoved_ then
		if arg_43_0:isHeroMax() then
			var_0_21.WindowManager.get():openWindow("toast", {
				message = string.format(var_0_10:translation("INCUBUS_TIPS_NUM"), var_0_8)
			})

			return
		end

		if not arg_43_0.isClicked then
			if arg_43_2.name == "ended" then
				arg_43_0.battleBottomWindow:getSummonArea():show()

				arg_43_0.isClicked = true
				arg_43_0.clickedFighter = arg_43_1
				arg_43_0.clickedIndex = arg_43_3

				arg_43_0:addAvatarEffect(arg_43_3)
			end
		elseif arg_43_2.name == "ended" then
			if arg_43_0.clickedIndex ~= arg_43_3 then
				arg_43_0.clickedFighter = arg_43_1
				arg_43_0.clickedIndex = arg_43_3

				arg_43_0:addAvatarEffect(arg_43_3)
			else
				arg_43_0.battleBottomWindow:getSummonArea():hide()

				arg_43_0.isClicked = false
				arg_43_0.clickedFighter = nil
				arg_43_0.clickedIndex = 0

				arg_43_0.avatarEffect1_:setVisible(false)
				arg_43_0.avatarEffect2_:setVisible(false)
			end
		end
	end
end

function var_0_0.addAvatarEffect(arg_44_0, arg_44_1)
	local var_44_0

	if arg_44_0.isAwakeSecond_ then
		var_44_0 = arg_44_0.listNodes_[arg_44_1]
	else
		var_44_0 = arg_44_0.battleBottomWindow:getUnlimitContainerByIndex(arg_44_1)
	end

	if not arg_44_0.avatarEffect1_ then
		local var_44_1 = var_0_17 .. ".json"
		local var_44_2 = var_0_17 .. ".atlas"

		arg_44_0.avatarEffect1_ = var_0_16.new(var_44_1, var_44_2, 1)

		if arg_44_0.isAwakeSecond_ then
			arg_44_0.avatarEffect1_:addTo(arg_44_0.listNodes_[arg_44_1])
		else
			arg_44_0.avatarEffect1_:addTo(arg_44_0.battleBottomWindow)
		end

		arg_44_0.avatarEffect1_:setAnchorPoint(cc.p(0.5, 0.5))
		arg_44_0.avatarEffect1_:setLocalZOrder(100)
	end

	if not arg_44_0.avatarEffect2_ then
		local var_44_3 = var_0_18 .. ".json"
		local var_44_4 = var_0_18 .. ".atlas"

		arg_44_0.avatarEffect2_ = var_0_16.new(var_44_3, var_44_4, 1)

		if arg_44_0.isAwakeSecond_ then
			arg_44_0.avatarEffect2_:addTo(arg_44_0.listNodes_[arg_44_1])

			arg_44_0.avatarEffectIndex_ = arg_44_1
		else
			arg_44_0.avatarEffect2_:addTo(arg_44_0.battleBottomWindow)
		end

		arg_44_0.avatarEffect2_:setAnchorPoint(cc.p(0.5, 0.5))
		arg_44_0.avatarEffect2_:setLocalZOrder(101)
	end

	local var_44_5, var_44_6 = var_44_0:getPosition()

	arg_44_0.avatarEffect1_:setVisible(true)
	arg_44_0.avatarEffect1_:play(nil, true)
	arg_44_0.avatarEffect2_:setVisible(true)
	arg_44_0.avatarEffect2_:play(nil, true)

	if arg_44_0.isAwakeSecond_ then
		local var_44_7 = (arg_44_1 - arg_44_0.avatarEffectIndex_) * var_0_20

		arg_44_0.avatarEffect1_:setPosition(cc.p(var_44_7 + 55, 55))
		arg_44_0.avatarEffect2_:setPosition(cc.p(var_44_7 + 55, 55))
	else
		arg_44_0.avatarEffect1_:setPosition(cc.p(var_44_5 - 5, var_44_6))
		arg_44_0.avatarEffect2_:setPosition(cc.p(var_44_5 - 5, var_44_6))
	end
end

function var_0_0.updateEnergyTarget(arg_45_0)
	local var_45_0 = 1

	for iter_45_0, iter_45_1 in ipairs(var_0_22.ctx.battle.teamA) do
		local var_45_1 = iter_45_1:getTableID()

		if not iter_45_1:isDeath() and iter_45_1:getSummonType() == var_0_21.summonMonsterType.None and var_45_1 ~= arg_45_0.mainTargetID and var_45_1 ~= arg_45_0.defenderID[1] and var_45_1 ~= arg_45_0.defenderID[2] then
			var_45_0 = var_45_0 + 1

			if var_45_0 >= 6 then
				break
			end
		end
	end

	arg_45_0.currentTargetEnergy = math.min(900, 300 + var_0_3[var_45_0])

	local var_45_2 = arg_45_0.currentTargetEnergy / 1000
	local var_45_3 = arg_45_0.battleBottomWindow:getUnlimitEnergyProcess()
	local var_45_4 = arg_45_0.battleBottomWindow:getUnlimitEnergyScale()
	local var_45_5, var_45_6 = var_45_4:getPosition()
	local var_45_7 = var_45_3:getContentSize().width

	var_45_4:setPosition(cc.p(var_45_7 * var_45_2, var_45_6))

	if arg_45_0.currentEnergy < arg_45_0.currentTargetEnergy or arg_45_0.summonCD_ > 0 or arg_45_0:aliveTeamates() >= var_0_8 then
		arg_45_0:setAvatarDark()
		arg_45_0:setEnergyEffect(false)
	else
		arg_45_0:setAvatarBright()
		arg_45_0:setEnergyEffect(true)
	end
end

function var_0_0.updateCurrentEnergy(arg_46_0)
	arg_46_0.battleBottomWindow:getUnlimitEnergyProcess():setPercent(arg_46_0.currentEnergy / 10)
end

function var_0_0.summonMonster(arg_47_0)
	if not arg_47_0.aliveMonsters then
		arg_47_0.aliveMonsters = {}
	end

	local var_47_0 = cc.p(arg_47_0.xLeft / 0.6, arg_47_0.yBottom / 0.6)
	local var_47_1 = var_47_0.x
	local var_47_2 = var_47_0.y
	local var_47_3 = var_0_21.Direction.Left
	local var_47_4 = 0

	for iter_47_0 = 1, #arg_47_0.leftMonster_ do
		local var_47_5 = arg_47_0.leftMonster_[iter_47_0]

		var_47_5.fighterModel:show()

		var_47_5.fighterIndex = "B|" .. #var_0_22.ctx.battle.teamB + 1
		var_47_4 = var_47_5:setFormation(iter_47_0, var_47_4, 10 - iter_47_0, var_47_3)

		var_47_5:setFormationDelay(0, 0)
		var_47_5:x(var_47_1)
		var_47_5:y(var_47_2 + 50 * iter_47_0)
		var_47_5:setupBattleAttrInfo()
		var_47_5:setGlobalBuffs()
		var_47_5:flipX(false)
		table.insert(var_0_22.ctx.battle.yOrder, var_47_5)
		table.insert(var_0_22.ctx.battle.teamB, var_47_5)
		table.insert(arg_47_0.aliveMonsters, var_47_5)
	end

	local var_47_6 = var_0_21.Direction.Right
	local var_47_7 = 0
	local var_47_8 = cc.p(var_0_21.UNLIMIT_STAGE_WIDTH - 100, arg_47_0.yBottom / 0.6).x

	for iter_47_1 = 1, #arg_47_0.rightMonster_ do
		local var_47_9 = arg_47_0.rightMonster_[iter_47_1]

		var_47_9.fighterModel:show()

		var_47_9.fighterIndex = "B|" .. #var_0_22.ctx.battle.teamB + 1
		var_47_7 = var_47_9:setFormation(iter_47_1, var_47_7, 10 - iter_47_1, var_47_6)

		var_47_9:setFormationDelay(0, 0)
		var_47_9:x(var_47_8)
		var_47_9:y(var_47_2 + 50 * iter_47_1)
		var_47_9:flipX(true)
		var_47_9:setupBattleAttrInfo()
		var_47_9:setGlobalBuffs()
		table.insert(var_0_22.ctx.battle.yOrder, var_47_9)
		table.insert(var_0_22.ctx.battle.teamB, var_47_9)
		table.insert(arg_47_0.aliveMonsters, var_47_9)
	end

	if not arg_47_0.hasSummonMissionMonster_ and arg_47_0.missionKillTarget_ then
		arg_47_0.hasSummonMissionMonster_ = true

		local var_47_10 = 0
		local var_47_11 = var_0_21.Direction.Right
		local var_47_12 = arg_47_0.missionKillTarget_

		var_47_12.fighterModel:show()

		var_47_12.fighterIndex = "B|" .. #var_0_22.ctx.battle.teamB + 1

		local var_47_13 = var_47_12:setFormation(1, var_47_10, 9, var_47_11)

		var_47_12:setFormationDelay(0, 0)
		var_47_12:getFighterModel():setFlipX(not var_47_11)
		var_47_12:x(arg_47_0.mainTarget:getX() - 50)
		var_47_12:y(arg_47_0.mainTarget:getY())
		var_47_12:setupBattleAttrInfo()
		var_47_12:setGlobalBuffs()
		table.insert(var_0_22.ctx.battle.yOrder, var_47_12)
		table.insert(var_0_22.ctx.battle.teamB, var_47_12)
	end

	arg_47_0.currentTimes = arg_47_0.currentTimes + 1

	arg_47_0:updateMonsterID()
	arg_47_0:setDegree()
	arg_47_0:updateDefendGirlHp()
end

function var_0_0.canSummonHero(arg_48_0)
	if arg_48_0.currentEnergy >= arg_48_0.currentTargetEnergy and arg_48_0.summonCD_ <= 0 then
		return true
	end

	return false
end

function var_0_0.updateAvatar(arg_49_0, arg_49_1)
	arg_49_0.summonTimes = arg_49_0.summonTimes + 1

	if arg_49_0.isAwakeSecond_ then
		arg_49_0.listNodes_[arg_49_1]:setVisible(false)

		if arg_49_1 == #arg_49_0.listNodes_ and #arg_49_0.listNodes_ > 1 then
			if arg_49_0.heroList_.scrollNode:getPosition() < 0 then
				arg_49_0.heroList_.scrollNode:runAction(cc.MoveBy:create(0.3, cc.p(var_0_20, 0)))
			end
		else
			for iter_49_0 = arg_49_1 + 1, #arg_49_0.listNodes_ do
				local var_49_0 = arg_49_0.listNodes_[iter_49_0]

				var_49_0:runAction(cc.MoveBy:create(0.3, cc.p(-var_0_20, 0)))

				local var_49_1 = arg_49_0.listHeros_[iter_49_0]

				var_49_0:removeAllNodeEventListeners()
				var_49_0:setTouchSwallowEnabled(false)
				var_49_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_50_0)
					arg_49_0:clickAvatar(var_49_1, arg_50_0, iter_49_0 - 1)

					return true
				end)
			end
		end

		if arg_49_0.avatarEffectIndex_ then
			if arg_49_0.avatarEffectIndex_ == arg_49_1 then
				arg_49_0.avatarEffect1_:removeSelf()
				arg_49_0.avatarEffect2_:removeSelf()

				arg_49_0.avatarEffect1_ = nil
				arg_49_0.avatarEffect2_ = nil
			elseif arg_49_1 < arg_49_0.avatarEffectIndex_ then
				arg_49_0.avatarEffectIndex_ = arg_49_0.avatarEffectIndex_ - 1
			end
		end

		table.remove(arg_49_0.listNodes_, arg_49_1)
	elseif arg_49_0.summonTimes <= #arg_49_0.standbyHeros then
		local var_49_2 = arg_49_0.standbyHeros[arg_49_0.summonTimes]

		arg_49_0.battleBottomWindow:resetUnlimitAvatar(arg_49_1, arg_49_0.summonTimes, var_49_2)

		local var_49_3 = arg_49_0:newFighter(var_49_2, var_0_21.TeamType.A, false)

		var_49_3.fighterModel:hide()

		local var_49_4 = arg_49_0.battleBottomWindow:getUnlimitContainerByIndex(arg_49_1)

		arg_49_0.battleBottomWindow:getUnlimitAvatarMask(arg_49_1):setVisible(true)
		var_49_4:removeAllNodeEventListeners()
		var_49_4:setTouchEnabled(true)
		var_49_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_51_0)
			arg_49_0:clickAvatar(var_49_3, arg_51_0, arg_49_1)

			return true
		end)
	else
		arg_49_0.battleBottomWindow:removeIcon(arg_49_1)
	end
end

function var_0_0.checkEnds(arg_52_0)
	if arg_52_0.mainTarget and arg_52_0.mainTarget:isDeath() then
		arg_52_0.isWin_ = false

		return true
	end

	if arg_52_0:aliveTeamates() == 0 then
		flag = true

		if arg_52_0.isAwakeSecond_ then
			if next(arg_52_0.listHeros_) then
				flag = false
			end
		else
			for iter_52_0 = 1, 5 do
				if arg_52_0.battleBottomWindow:getUnlimitContainerByIndex(iter_52_0) then
					flag = false

					break
				end
			end
		end

		if flag then
			arg_52_0.isWin_ = false

			return true
		end
	end

	if not arg_52_0.canSummonMonster then
		for iter_52_1, iter_52_2 in ipairs(var_0_22.ctx.battle.teamB) do
			if not iter_52_2:isDeath() then
				return false
			end
		end

		arg_52_0.currentTimes = arg_52_0.currentTimes + 1
		arg_52_0.isWin_ = true

		return true
	end

	return false
end

function var_0_0.sendBattleResult(arg_53_0, arg_53_1)
	local function var_53_0(arg_54_0)
		if not arg_54_0 then
			return
		end

		var_0_21.WindowManager.get():closeWindow(var_0_21.WindowName.battleBottomWnd)
		var_0_21.WindowManager.get():closeWindow(var_0_21.WindowName.battleTopWnd, function()
			cc.Director:getInstance():popToRootScene()
		end)
	end

	arg_53_0:unlimitResult(arg_53_1)
	var_53_0(arg_53_1)
end

function var_0_0.unlimitResult(arg_56_0, arg_56_1)
	local function var_56_0(arg_57_0, arg_57_1)
		if arg_57_0 > 0 then
			arg_56_0:runActionOnce(cc.CallFunc:create(function()
				arg_56_0:finishBattle(arg_57_1)
			end), false, nil, arg_57_0)
		else
			arg_56_0:finishBattle(arg_57_1)
		end
	end

	if not arg_56_1 then
		if arg_56_0.isAwakeSecond_ then
			local var_56_1 = {
				incubus_id = arg_56_0.unlimitID,
				npc_ids = arg_56_0.deadHeros_,
				num = arg_56_0.currentTimes - 2
			}

			if arg_56_0.isWin_ then
				var_56_1.twice_awake_mission = arg_56_0.unlimitID
			else
				var_56_0(1)

				return
			end

			var_0_21.Backend.get():request(var_0_21.mid.UNLIMIT_FIGHT_RESULT, var_56_1, function(arg_59_0, arg_59_1)
				if arg_59_0 == var_0_21.error.OK then
					var_56_0(1, arg_59_1)
				end
			end, nil, nil, true)
		else
			for iter_56_0, iter_56_1 in ipairs(var_0_22.ctx.battle.teamB) do
				if iter_56_1:isDeath() and iter_56_1:getSummonType() == var_0_21.summonMonsterType.None then
					table.insert(arg_56_0.deadHeros_, iter_56_1:getTableID())
				end
			end

			local var_56_2 = 0
			local var_56_3 = {
				incubus_id = arg_56_0.unlimitID,
				npc_ids = arg_56_0.deadHeros_,
				num = arg_56_0.currentTimes - 2
			}
			local var_56_4 = var_0_21.ModelManager.get():loadModel(var_0_21.ModelType.SELF_PLAYER)

			var_0_21.Backend.get():request(var_0_21.mid.UNLIMIT_FIGHT_RESULT, var_56_3, function(arg_60_0, arg_60_1)
				if arg_60_0 == var_0_21.error.OK then
					for iter_60_0, iter_60_1 in pairs(arg_60_1.items) do
						for iter_60_2, iter_60_3 in ipairs(iter_60_1) do
							for iter_60_4 = 1, iter_60_3.item_num do
								local var_60_0 = var_0_15.new()

								var_60_0:populate({
									table_id = iter_60_3.item_id
								})
								table.insert(arg_56_0.dropItems_, var_60_0)
							end
						end
					end

					var_56_0(1, arg_60_1)
				end
			end, nil, nil, true)
		end
	else
		local var_56_5 = {
			incubus_id = arg_56_0.unlimitID
		}

		var_0_21.Backend.get():request(var_0_21.mid.UNLIMIT_TEMP_RESULT, var_56_5, function(arg_61_0, arg_61_1)
			return
		end, nil, nil, true)
	end
end

function var_0_0.finishBattle(arg_62_0, arg_62_1, arg_62_2)
	for iter_62_0 = 1, 5 do
		local var_62_0 = arg_62_0.battleBottomWindow:getUnlimitContainerByIndex(iter_62_0)

		if var_62_0 then
			var_62_0:setTouchEnabled(false)
		end
	end

	var_0_21.WindowManager.get():closeWindow(var_0_21.WindowName.battleTopWnd)
	var_0_21.WindowManager.get():closeWindow(var_0_21.WindowName.battleBottomWnd)

	local var_62_1 = {}
	local var_62_2 = {}
	local var_62_3 = {}
	local var_62_4 = {}

	for iter_62_1, iter_62_2 in ipairs(var_0_22.ctx.battle.teamA) do
		local var_62_5 = iter_62_2:getTableID()

		if iter_62_2:getSummonType() == var_0_21.summonMonsterType.None and var_62_5 ~= arg_62_0.mainTargetID and var_62_5 ~= arg_62_0.defenderID[1] and var_62_5 ~= arg_62_0.defenderID[2] then
			table.insert(var_62_1, iter_62_2)
		end
	end

	arg_62_0:clearFormation(true)

	local var_62_6 = {
		mana = 0,
		campaignID = arg_62_0.unlimitID,
		campaignType = var_0_21.CampaignType.INCUBUS,
		fighterA = var_62_1,
		fighterB = {},
		items = arg_62_0.dropItems_,
		heroExp = arg_62_1 and arg_62_1.exps or {},
		favorDegreeUp = arg_62_0.favorDegreeUp,
		thisRecordNum = arg_62_0.currentTimes - 2,
		historyRecordNum = arg_62_1 and arg_62_1.old_num or 0,
		addExp = arg_62_1 and arg_62_1.add_exp or 0,
		isAwakeSecond = arg_62_0.isAwakeSecond_
	}

	var_0_21.WindowManager.get():openWindow(var_0_21.WindowName.battleWinWnd, var_62_6, function(arg_63_0)
		if arg_63_0 == nil then
			return
		end

		arg_62_0.battleEndWindow_ = arg_63_0

		cc.EventProxy.new(arg_62_0.battleEndWindow_, arg_62_0.battleEndWindow_):addEventListener(var_0_21.event.BATTLE_END_BACK_TO_MAIN, function(arg_64_0)
			arg_62_0:closeBattleEndWindow(function()
				var_0_21.WindowManager.get():closeAllWindows()
				var_0_22.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end)
		end)
	end)
end

function var_0_0.isAutoA(arg_66_0)
	return true
end

function var_0_0.setDegree(arg_67_0)
	arg_67_0.battleTopWindow:getDegreeNum():setString(arg_67_0.currentTimes - 1)
end

function var_0_0.setupBackground_(arg_68_0)
	local var_68_0 = var_0_9

	if var_0_22.ctx.battle.background and tolua.isnull(var_0_22.ctx.battle.background) ~= true then
		var_0_22.ctx.battle.background:removeSelf()

		var_0_22.ctx.battle.background = nil
	end

	var_0_22.ctx.battle.background = var_0_21.ColoredSprite.new(var_68_0):align(display.RIGHT_BOTTOM, arg_68_0:getWidth(), 0):addTo(arg_68_0, -1)

	var_0_22.ctx.battle.background:setOpacity(255)
	var_0_22.ctx.battle.background:setScaleX(1.5 * arg_68_0:getWidth() / var_0_22.ctx.battle.background:getWidth())
	var_0_22.ctx.battle.background:setScaleY(arg_68_0:getHeight() / var_0_22.ctx.battle.background:getHeight())
end

function var_0_0.adjustY(arg_69_0, arg_69_1)
	local var_69_0 = 100
	local var_69_1 = 600

	for iter_69_0 = 1, #arg_69_1 do
		local var_69_2 = arg_69_1[iter_69_0]
		local var_69_3 = iter_69_0 > 1 and arg_69_1[iter_69_0 - 1]
		local var_69_4 = iter_69_0 < #arg_69_1 and arg_69_1[iter_69_0 + 1]
		local var_69_5 = var_69_2:getX()
		local var_69_6 = var_69_2:getY()
		local var_69_7
		local var_69_8
		local var_69_9
		local var_69_10

		if var_69_3 then
			var_69_7, var_69_8 = var_69_3:getX(), var_69_3:getY()
		end

		if var_69_4 then
			var_69_9, var_69_10 = var_69_4:getX(), var_69_4:getY()
		end

		if not var_69_3 and not var_69_2:isMoveUnable() and not var_69_2:isInSkillRoll() and var_69_4 then
			if var_0_25(var_69_9 - var_69_5) < 133 and var_69_10 - var_69_6 < 80 and var_69_0 < var_69_6 then
				local var_69_11 = var_0_23(var_69_2:getBasicSpeed(), var_69_6 - var_69_0) * -1 / 0.6

				var_69_2:moveByY(var_69_11)

				var_69_2.isAdjustY_ = 1
			end
		elseif var_69_3 and not var_69_2:isMoveUnable() and not var_69_2:isInSkillRoll() and var_0_25(var_69_7 - var_69_5) < 133 and var_69_6 - var_69_8 < 80 and var_69_8 < var_69_1 then
			local var_69_12 = var_69_2:getBasicSpeed() / 0.6

			var_69_2:moveByY(var_69_12)

			var_69_2.isAdjustY_ = 1
		elseif var_69_4 and not var_69_2:isMoveUnable() and not var_69_2:isInSkillRoll() and var_0_25(var_69_9 - var_69_5) < 133 and var_69_10 - var_69_6 < 80 and var_0_25(var_69_5 - var_69_7) < 133 and var_69_10 - var_69_6 > (100 + var_69_2:getBasicSpeed()) / 0.6 then
			local var_69_13 = var_69_2:getBasicSpeed() * -1 / 0.6

			var_69_2:moveByY(var_69_13)

			var_69_2.isAdjustY_ = 1
		end
	end

	arg_69_0:updateZorder()
end

function var_0_0.updateDefendGirlHp(arg_70_0)
	if arg_70_0.mainTarget and not arg_70_0.mainTarget:isDeath() then
		local var_70_0 = arg_70_0.mainTarget:getHp()
		local var_70_1

		for iter_70_0, iter_70_1 in ipairs(arg_70_0.nodeTable) do
			var_70_1 = not var_70_1 and 1 or var_70_1 + 1

			if iter_70_1 > arg_70_0.currentTimes - 1 then
				break
			end
		end

		local var_70_2 = arg_70_0.mainTarget:getHpLimit() * arg_70_0.cureTable[var_70_1] * 0.01

		arg_70_0.mainTarget:updateHp(var_70_0 + var_70_2)
	end
end

function var_0_0.setAvatarBright(arg_71_0)
	if arg_71_0.isAwakeSecond_ then
		for iter_71_0, iter_71_1 in ipairs(arg_71_0.listNodes_) do
			local var_71_0 = iter_71_1:getChildByName("layout"):getChildByName("mask")

			if var_71_0 then
				var_71_0:setVisible(false)
			end

			iter_71_1:setTouchEnabled(true)
		end
	else
		for iter_71_2 = 1, 5 do
			local var_71_1 = arg_71_0.battleBottomWindow:getUnlimitAvatarMask(iter_71_2)

			if var_71_1 then
				var_71_1:setVisible(false)
			end

			local var_71_2 = arg_71_0.battleBottomWindow:getUnlimitContainerByIndex(iter_71_2)

			if var_71_2 then
				var_71_2:setTouchEnabled(true)
			end
		end
	end
end

function var_0_0.setAvatarDark(arg_72_0)
	if arg_72_0.isAwakeSecond_ then
		for iter_72_0, iter_72_1 in ipairs(arg_72_0.listNodes_) do
			local var_72_0 = iter_72_1:getChildByName("layout"):getChildByName("mask")

			if var_72_0 then
				var_72_0:setVisible(true)
			end

			iter_72_1:setTouchEnabled(false)
		end
	else
		for iter_72_2 = 1, 5 do
			local var_72_1 = arg_72_0.battleBottomWindow:getUnlimitAvatarMask(iter_72_2)

			if var_72_1 then
				var_72_1:setVisible(true)
			end
		end
	end
end

function var_0_0.setEnergyEffect(arg_73_0, arg_73_1)
	if not arg_73_0.energyEffect_ then
		local var_73_0 = var_0_19 .. ".json"
		local var_73_1 = var_0_19 .. ".atlas"

		arg_73_0.energyEffect_ = var_0_16.new(var_73_0, var_73_1, 1)

		arg_73_0.energyEffect_:addTo(arg_73_0.battleBottomWindow)
		arg_73_0.energyEffect_:setLocalZOrder(102)
		arg_73_0.energyEffect_:setAnchorPoint(cc.p(0, 0))
		arg_73_0.energyEffect_:play(nil, true)

		local var_73_2, var_73_3 = arg_73_0.battleBottomWindow:nodeByName("energy_icon"):getPosition()

		arg_73_0.energyEffect_:setPosition(cc.p(var_73_2 + 227, var_73_3 - 12))
	end

	arg_73_0.energyEffect_:setVisible(arg_73_1)
end

function var_0_0.newBuff(arg_74_0, arg_74_1, arg_74_2, arg_74_3)
	local var_74_0 = {}

	for iter_74_0, iter_74_1 in ipairs(arg_74_1) do
		local var_74_1 = var_0_2.new({
			tableID = iter_74_1,
			start = var_0_22.ctx.battle.count,
			level = arg_74_2:getSkillLevelByID(arg_74_3),
			skillID = arg_74_3,
			fighter = arg_74_2,
			target = arg_74_2
		})

		var_74_1:setIsHit(true)
		var_74_1:setDirection(arg_74_2:getFighterModel():getFlipX())
		table.insert(var_74_0, var_74_1)
	end

	return var_74_0
end

return var_0_0
