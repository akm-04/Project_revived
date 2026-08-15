local var_0_0 = class("BattleCreateReport", function(arg_1_0)
	return display.newNode()
end)
local var_0_1 = xyd.tables.skill
local var_0_2 = ngx.ctx.battle.getRequire("SkillEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = import("app.model.Hero")
local var_0_5 = require("framework.scheduler")
local var_0_6 = require("cjson")
local var_0_7 = xyd
local var_0_8 = ngx
local var_0_9 = math.min
local var_0_10 = math.max
local var_0_11 = math.abs
local var_0_12 = math.floor
local var_0_13 = math.ceil
local var_0_14 = math.sqrt

function var_0_0.ctor(arg_2_0, arg_2_1)
	collectgarbage("collect")

	arg_2_0.battleType = arg_2_1.battleType or var_0_7.BattleType.Normal
	arg_2_0.jsonData_ = arg_2_1.jsonData or ""
	arg_2_0.group_ = 1
	arg_2_0.stories = arg_2_1.stories or {}
	arg_2_0.campaignType = arg_2_1.campaignType
	arg_2_0.campaignID = arg_2_1.campaignID
	arg_2_0.battleID = arg_2_1.battleID or 0
	arg_2_0.star_ = arg_2_1.star or 0
	arg_2_0.rentFlag_ = arg_2_1.rentFlag
	arg_2_0.fighterInfo = arg_2_1.fighterInfo
	arg_2_0.isGuide = arg_2_1.isGuide
	arg_2_0.formation = arg_2_1.formation
	arg_2_0.team1 = arg_2_1.team1
	arg_2_0.team2 = arg_2_1.team2
	arg_2_0.team3 = arg_2_1.team3
	arg_2_0.pet1 = arg_2_1.pet1
	arg_2_0.pet2 = arg_2_1.pet2
	arg_2_0.pet3 = arg_2_1.pet3
	arg_2_0.dropMana = arg_2_1.dropMana
	arg_2_0.dropItems = arg_2_1.drops or {}
	arg_2_0.isRegionArenaTest = arg_2_1.isRegionArenaTest
	arg_2_0.is_region_practice = arg_2_1.is_practice
	arg_2_0.selfPlayer = var_0_7.ModelManager.get():loadModel(var_0_7.ModelType.SELF_PLAYER)
	arg_2_0.regionArena = var_0_7.ModelManager.get():loadModel(var_0_7.ModelType.REGION_ARENA)
	arg_2_0.mapID_ = var_0_7.tables.battle:maps(arg_2_0.battleID)

	if arg_2_0.campaignType == var_0_7.CampaignType.ARENA then
		arg_2_0.herosA = arg_2_1.herosA
		arg_2_0.heroGroupB = arg_2_1.herosB
		arg_2_0.is_avenge = arg_2_1.is_avenge
		arg_2_0.enemyID_ = arg_2_1.enemy_id
	elseif arg_2_0.campaignType == var_0_7.CampaignType.REGION_ARENA then
		arg_2_0.herosA = arg_2_1.herosA
		arg_2_0.heroGroupB = arg_2_1.herosB
		arg_2_0.enemyID_ = arg_2_1.enemy_id
	elseif arg_2_0.campaignType == var_0_7.CampaignType.SUPER_ARENA then
		arg_2_0.peakArena = var_0_7.ModelManager.get():loadModel(var_0_7.ModelType.PEAK_ARENA)

		arg_2_0.peakArena:clear()
		arg_2_0.peakArena:setCurrentBattleRound(1)

		arg_2_0.heroGroupA = arg_2_1.herosA
		arg_2_0.heroGroupB = arg_2_1.herosB
		arg_2_0.herosA = arg_2_0.heroGroupA.team1
		arg_2_0.enemyID_ = arg_2_1.enemy_id
	elseif arg_2_0.campaignType == var_0_7.CampaignType.MARCH then
		arg_2_0.herosA = arg_2_1.herosA
		arg_2_0.heroGroupB = arg_2_1.herosB
		arg_2_0.march = var_0_7.ModelManager.get():loadModel(var_0_7.ModelType.MARCH)
	elseif arg_2_0.campaignType == var_0_7.CampaignType.TREASURE then
		arg_2_0.herosA = arg_2_1.herosA
		arg_2_0.heroGroupB = arg_2_1.herosB
		arg_2_0.mapID_ = var_0_7.tables.treasure:map(arg_2_1.treasureAwardType)
	else
		arg_2_0.herosA = arg_2_1.herosA
		arg_2_0.heroGroupB = arg_2_1.herosB
	end

	arg_2_0.petsA = arg_2_1.petsA
	arg_2_0.petsB = arg_2_1.petsB
	arg_2_0.isBattleEnded_ = false

	arg_2_0:size(var_0_7.STAGE_WIDTH, var_0_7.STAGE_HEIGHT)

	arg_2_0.noResult = arg_2_1.noResult
	arg_2_0.libraryFormations = {}
	arg_2_0.superArenaData = {}
end

function var_0_0.run(arg_3_0)
	arg_3_0:setupConfig()
	arg_3_0:init()
end

function var_0_0.init(arg_4_0)
	if arg_4_0.campaignType == var_0_7.CampaignType.SUPER_ARENA then
		arg_4_0.herosB = arg_4_0.heroGroupB["team" .. arg_4_0.peakArena:getCurrentBattleRound()]
	else
		arg_4_0.herosB = arg_4_0.heroGroupB[arg_4_0.group_]
	end

	arg_4_0:setupBasicData()
	arg_4_0:startBattle()
end

function var_0_0.setupBasicData(arg_5_0)
	arg_5_0:resetConfig()
	arg_5_0:clearFormation()
	arg_5_0:setFormation()
	arg_5_0:updateFighters()
end

function var_0_0.setupConfig(arg_6_0)
	var_0_8.ctx.battle.teamA = {}
	var_0_8.ctx.battle.teamB = {}
	var_0_8.ctx.battle.globalBuffsA = {}
	var_0_8.ctx.battle.globalBuffsB = {}
	var_0_8.ctx.battle.globalBuffs = {}
	var_0_8.ctx.battle.applyUnits = {}
	var_0_8.ctx.battle.moveUnits = {}
	var_0_8.ctx.battle.moveAttackUnits = {}
	var_0_8.ctx.battle.yOrder = {}
	var_0_8.ctx.battle.count = 0
	var_0_8.ctx.battle.nightCount = 0
	var_0_8.ctx.battle.timeCount = 0
	var_0_8.ctx.battle.soundQueue = {}
	var_0_8.ctx.battle.isEnergySkilling = false
	var_0_8.ctx.battle.playerLayer = display.newNode()

	var_0_8.ctx.battle.playerLayer:size(var_0_7.STAGE_WIDTH, var_0_7.STAGE_HEIGHT)
	var_0_8.ctx.battle.playerLayer:align(display.LEFT_BOTTOM, 0, 0):addTo(arg_6_0, 1)

	var_0_8.ctx.battle.unitLayer = display.newNode()

	var_0_8.ctx.battle.unitLayer:size(var_0_7.STAGE_WIDTH, var_0_7.STAGE_HEIGHT)
	var_0_8.ctx.battle.unitLayer:align(display.LEFT_BOTTOM, 0, 0):addTo(arg_6_0, 2)

	var_0_8.ctx.battle.blackLayer = display.newColorLayer(cc.c4b(0, 0, 0, 125))

	var_0_8.ctx.battle.blackLayer:size(arg_6_0:getContentSize())
	var_0_8.ctx.battle.blackLayer:align(display.LEFT_BOTTOM, 0, 0):addTo(arg_6_0, 0)
	var_0_8.ctx.battle.blackLayer:hide()

	var_0_8.ctx.battle.unitBottomLayer = display.newNode()

	var_0_8.ctx.battle.unitBottomLayer:size(var_0_7.STAGE_WIDTH, var_0_7.STAGE_HEIGHT)
	var_0_8.ctx.battle.unitBottomLayer:align(display.LEFT_BOTTOM, 0, 0):addTo(arg_6_0, 0)

	var_0_8.ctx.battle.battleType = arg_6_0.battleType
	var_0_8.ctx.battle.battleID = 0
	var_0_8.ctx.battle.autoA = arg_6_0:isAutoA()
	var_0_8.ctx.battle.autoB = true
	var_0_8.ctx.battle.dropAwardCount = 0
	var_0_8.ctx.battle.dropManaCount = 0
	var_0_8.ctx.battle.isEnd = false
	var_0_8.ctx.battle.walk2NextBattle_ = false
	var_0_8.ctx.battle.campaignType = arg_6_0.campaignType
	var_0_8.ctx.battle.allFighterHurt = 0
	var_0_8.ctx.battle.isCountHurtNum = false
	var_0_8.ctx.battle.infoListener = {}
	var_0_8.ctx.battle.infoList = {}
end

function var_0_0.resetConfig(arg_7_0)
	var_0_8.ctx.battle.globalBuffsA = {}
	var_0_8.ctx.battle.globalBuffsB = {}
	var_0_8.ctx.battle.globalBuffs = {}
	var_0_8.ctx.battle.yOrder = {}
	var_0_8.ctx.battle.count = 0
	var_0_8.ctx.battle.nightCount = 0
	var_0_8.ctx.battle.timeCount = 0
	var_0_8.ctx.battle.isEnergySkilling = false

	var_0_8.ctx.battle.unitLayer:removeAllChildren()
	var_0_8.ctx.battle.unitBottomLayer:removeAllChildren()

	arg_7_0.battleStar_ = nil
	arg_7_0.stopTimeCount_ = false
	arg_7_0.isBattleEnded_ = false
	arg_7_0.timeOut_ = false
	var_0_8.ctx.battle.allFighterHurt = 0
	var_0_8.ctx.battle.isCountHurtNum = false
	var_0_8.ctx.battle.teamAEnd = false
	var_0_8.ctx.battle.teamBEnd = false
end

function var_0_0.clear(arg_8_0)
	for iter_8_0, iter_8_1 in ipairs(var_0_8.ctx.battle.teamA) do
		if not iter_8_1:isDeath() then
			iter_8_1:cleanAllBuffs()
		end

		iter_8_1:clearResource()
	end

	for iter_8_2, iter_8_3 in ipairs(var_0_8.ctx.battle.teamB) do
		if not iter_8_3:isDeath() then
			iter_8_3:cleanAllBuffs()
		end

		iter_8_3:clearResource()
	end

	var_0_8.ctx.battle.unitLayer:removeAllChildren()
	var_0_8.ctx.battle.unitBottomLayer:removeAllChildren()
	collectgarbage("collect")
end

function var_0_0.clearFormation(arg_9_0, arg_9_1)
	if arg_9_1 then
		for iter_9_0 = #var_0_8.ctx.battle.teamA, 1, -1 do
			local var_9_0 = var_0_8.ctx.battle.teamA[iter_9_0]

			if not tolua.isnull(var_9_0.fighterModel) then
				var_9_0:getFighterModel():stopAttackEffect_()
				var_9_0.fighterModel:removeSelf()
			end

			if var_9_0:getSummonType() ~= var_0_7.summonMonsterType.None then
				table.remove(var_0_8.ctx.battle.teamA, iter_9_0)
			end
		end

		for iter_9_1 = #var_0_8.ctx.battle.teamB, 1, -1 do
			local var_9_1 = var_0_8.ctx.battle.teamB[iter_9_1]

			if not tolua.isnull(var_9_1.fighterModel) then
				var_9_1:getFighterModel():stopAttackEffect_()
				var_9_1.fighterModel:removeSelf()
			end

			if var_9_1:getSummonType() ~= var_0_7.summonMonsterType.None then
				table.remove(var_0_8.ctx.battle.teamB, iter_9_1)
			end
		end

		var_0_8.ctx.battle.playerLayer:removeAllChildren()

		return
	end

	for iter_9_2, iter_9_3 in ipairs(var_0_8.ctx.battle.teamB) do
		iter_9_3:getFighterModel():clearTracks()
		transition.stopTarget(iter_9_3.fighterModel)
		iter_9_3.fighterModel:removeSelf()
	end

	for iter_9_4 = #var_0_8.ctx.battle.teamA, 1, -1 do
		local var_9_2 = var_0_8.ctx.battle.teamA[iter_9_4]

		if var_9_2:getSummonType() ~= var_0_7.summonMonsterType.None then
			table.remove(var_0_8.ctx.battle.teamA, iter_9_4)
			var_9_2:getFighterModel():clearTracks()
			transition.stopTarget(var_9_2.fighterModel)
			var_9_2.fighterModel:removeSelf()
		end
	end

	var_0_8.ctx.battle.teamB = {}
end

function var_0_0.setFormation(arg_10_0)
	if next(var_0_8.ctx.battle.teamA) == nil then
		for iter_10_0, iter_10_1 in ipairs(arg_10_0.herosA) do
			local var_10_0 = iter_10_1:className()
			local var_10_1 = var_0_8.ctx.battle.requireFighter(var_10_0).new({
				is_arena = arg_10_0:isArena()
			})

			var_10_1:populateWithHero(iter_10_1)
			var_10_1:setTeamType(var_0_7.TeamType.A)
			var_10_1:initModels()
			var_10_1.fighterModel:addTo(var_0_8.ctx.battle.playerLayer)
			var_10_1:getFighterModel():idle()
			var_10_1.fighterModel:initHeaderView(0)
			table.insert(var_0_8.ctx.battle.teamA, var_10_1)
		end

		for iter_10_2, iter_10_3 in ipairs(arg_10_0.petsA or {}) do
			local var_10_2 = iter_10_3:className()
			local var_10_3 = var_0_8.ctx.battle.requireFighter(var_10_2).new({
				is_arena = arg_10_0:isArena()
			})

			var_10_3:populateWithHero(iter_10_3)
			var_10_3:setTeamType(var_0_7.TeamType.A)
			var_10_3:initModels()
			var_10_3.fighterModel:addTo(var_0_8.ctx.battle.playerLayer)
			var_10_3:getFighterModel():idle()
			var_10_3.fighterModel:initHeaderView(0)
			table.insert(var_0_8.ctx.battle.teamA, var_10_3)
		end
	else
		for iter_10_4, iter_10_5 in ipairs(var_0_8.ctx.battle.teamA) do
			if not iter_10_5:isDeath() then
				iter_10_5.fighterModel.headerView_:setCount(0)
				iter_10_5:getFighterModel():idle()
				iter_10_5:init()
			end
		end
	end

	for iter_10_6, iter_10_7 in ipairs(arg_10_0.herosB) do
		local var_10_4 = iter_10_7:className()
		local var_10_5 = var_0_8.ctx.battle.requireFighter(var_10_4).new({
			is_arena = arg_10_0:isArena()
		})

		var_10_5:populateWithHero(iter_10_7)
		var_10_5:setTeamType(var_0_7.TeamType.B)
		var_10_5:initModels()
		var_10_5.fighterModel:addTo(var_0_8.ctx.battle.playerLayer)
		var_10_5:getFighterModel():idle()
		var_10_5:getFighterModel():flipX(true)
		var_10_5.fighterModel:initHeaderView(1)
		table.insert(var_0_8.ctx.battle.teamB, var_10_5)

		var_10_5.dropItems_ = {}
		var_10_5.dropMana_ = 0

		if arg_10_0.dropMana then
			var_10_5.dropMana_ = arg_10_0.dropMana[arg_10_0.group_][iter_10_6]
		end

		for iter_10_8, iter_10_9 in ipairs(arg_10_0.dropItems) do
			if iter_10_9.drop_[1] == arg_10_0.group_ and iter_10_9.drop_[2] == iter_10_6 then
				table.insert(var_10_5.dropItems_, iter_10_9)
			end
		end
	end

	for iter_10_10, iter_10_11 in ipairs(arg_10_0.petsB or {}) do
		local var_10_6 = iter_10_11:className()
		local var_10_7 = var_0_8.ctx.battle.requireFighter(var_10_6).new({
			is_arena = arg_10_0:isArena()
		})

		var_10_7:populateWithHero(iter_10_11)
		var_10_7:setTeamType(var_0_7.TeamType.B)
		var_10_7:initModels()
		var_10_7.fighterModel:addTo(var_0_8.ctx.battle.playerLayer)
		var_10_7:getFighterModel():idle()
		var_10_7:getFighterModel():flipX(true)
		var_10_7.fighterModel:initHeaderView(1)
		table.insert(var_0_8.ctx.battle.teamB, var_10_7)
	end

	table.sort(var_0_8.ctx.battle.teamA, function(arg_11_0, arg_11_1)
		return arg_11_0:getDistance() < arg_11_1:getDistance()
	end)
	table.sort(var_0_8.ctx.battle.teamB, function(arg_12_0, arg_12_1)
		return arg_12_0:getDistance() < arg_12_1:getDistance()
	end)

	local var_10_8 = 1
	local var_10_9 = 0
	local var_10_10 = 9

	for iter_10_12 = 1, #var_0_8.ctx.battle.teamA do
		local var_10_11 = var_0_8.ctx.battle.teamA[iter_10_12]

		if not var_10_11:isDeath() then
			var_10_11.fighterIndex = "A|" .. iter_10_12
			var_10_9 = var_10_11:setFormation(var_10_8, var_10_9, var_10_10)

			var_10_11:setFormationDelay(var_0_7.tables.battleConfig.skillDelayQueue[var_10_8], var_0_7.tables.battleConfig.formationWalkQueue[var_10_8])
			table.insert(var_0_8.ctx.battle.yOrder, var_10_11)

			var_10_8 = var_10_8 + 1
			var_10_10 = var_10_10 - 2
		end
	end

	local var_10_12 = 0
	local var_10_13 = 10

	for iter_10_13 = 1, #var_0_8.ctx.battle.teamB do
		local var_10_14 = var_0_8.ctx.battle.teamB[iter_10_13]

		var_10_14.fighterIndex = "B|" .. iter_10_13
		var_10_12 = var_10_14:setFormation(iter_10_13, var_10_12, var_10_13)

		var_10_14:setFormationDelay(var_0_7.tables.battleConfig.skillDelayQueue[iter_10_13], var_0_7.tables.battleConfig.formationWalkQueue[iter_10_13])
		table.insert(var_0_8.ctx.battle.yOrder, var_10_14)

		var_10_13 = var_10_13 - 2
	end
end

function var_0_0.setupGlobalBuffs(arg_13_0)
	for iter_13_0, iter_13_1 in ipairs(var_0_8.ctx.battle.teamA) do
		iter_13_1:setupBattleAttrInfo()
		iter_13_1:setGlobalBuffs()
	end

	for iter_13_2, iter_13_3 in ipairs(var_0_8.ctx.battle.teamB) do
		iter_13_3:setupBattleAttrInfo()
		iter_13_3:setGlobalBuffs()
	end
end

function var_0_0.updateFighters(arg_14_0)
	for iter_14_0, iter_14_1 in ipairs(var_0_8.ctx.battle.teamA) do
		if var_0_8.ctx.battle.battleType == var_0_7.BattleType.ReplayReport then
			iter_14_1:setupReport(iter_14_1.hero_:getReportData())
		end
	end

	for iter_14_2, iter_14_3 in pairs(var_0_8.ctx.battle.teamB) do
		if var_0_8.ctx.battle.battleType == var_0_7.BattleType.ReplayReport then
			iter_14_3:setupReport(iter_14_3.hero_:getReportData())
		end
	end

	arg_14_0:setupGlobalBuffs()

	for iter_14_4, iter_14_5 in ipairs(var_0_8.ctx.battle.teamA) do
		iter_14_5:setupHpLimit()

		if iter_14_5.hero_.healthStatus and iter_14_5.hero_.healthStatus.health == 1 and arg_14_0.campaignType == var_0_7.CampaignType.MARCH then
			iter_14_5:updateHp(iter_14_5.hero_.healthStatus.hp)
			iter_14_5:updateEnergyTo(iter_14_5.hero_.healthStatus.mp)

			if (iter_14_5.hero_.healthStatus.is_reborn or 0) > 0 and iter_14_5:canReborn() then
				iter_14_5.hasReborn_ = true
			end
		elseif arg_14_0.group_ == 1 or arg_14_0.campaignType == var_0_7.CampaignType.SUPER_ARENA then
			iter_14_5:updateHp(iter_14_5:getHpLimit())
		end

		iter_14_5.hero_.healthStatus = nil
	end

	for iter_14_6, iter_14_7 in pairs(var_0_8.ctx.battle.teamB) do
		iter_14_7:setupHpLimit()

		if iter_14_7.hero_.healthStatus and iter_14_7.hero_.healthStatus.health == 1 and (arg_14_0.campaignType == var_0_7.CampaignType.MARCH or arg_14_0.campaignType == var_0_7.CampaignType.TREASURE) then
			iter_14_7:updateHp(iter_14_7.hero_.healthStatus.hp)
			iter_14_7:updateEnergyTo(iter_14_7.hero_.healthStatus.mp)

			if (iter_14_7.hero_.healthStatus.is_reborn or 0) > 0 and iter_14_7:canReborn() then
				iter_14_7.hasReborn_ = true
			end
		else
			iter_14_7:updateHp(iter_14_7:getHpLimit())
		end

		iter_14_7.hero_.healthStatus = nil
	end
end

function var_0_0.startBattle(arg_15_0)
	if not arg_15_0.handler then
		arg_15_0.handler = var_0_5.scheduleUpdateGlobal(handler(arg_15_0, arg_15_0.mainLoop))
	end
end

function var_0_0.pauseBattle(arg_16_0)
	if arg_16_0.handler ~= nil then
		var_0_5.unscheduleGlobal(arg_16_0.handler)

		arg_16_0.handler = nil
	end
end

function var_0_0.battleEnd(arg_17_0)
	arg_17_0.isBattleEnded_ = true

	arg_17_0:pauseBattle()

	var_0_8.ctx.battle.isEnd = true

	var_0_8.ctx.battle.popSoundQueue()
	arg_17_0:writeReport()
	arg_17_0:sendBattleResult()
end

function var_0_0.checkBlackLayerState(arg_18_0)
	if var_0_8.ctx.battle.isEnergySkilling then
		var_0_8.ctx.battle.isEnergySkilling = var_0_8.ctx.battle.isEnergySkilling - 1

		if var_0_8.ctx.battle.isEnergySkilling < 1 then
			arg_18_0:removeBlackLayer()
		end
	end
end

function var_0_0.removeBlackLayer(arg_19_0)
	if var_0_8.ctx.battle.blackLayer == nil or tolua.isnull(var_0_8.ctx.battle.blackLayer) then
		return
	end

	var_0_8.ctx.battle.blackLayer:hide()
	var_0_8.ctx.battle.resumeAllFighter()

	var_0_8.ctx.battle.isEnergySkilling = false
end

function var_0_0.mainLoop(arg_20_0)
	for iter_20_0 = 1, var_0_8.ctx.battleConst.loopsPerFrame + 1 do
		if tolua.isnull(arg_20_0) then
			arg_20_0:pauseBattle()

			return
		end

		if arg_20_0:checkEnds() then
			arg_20_0:processAfterBattleEnd()
			arg_20_0:battleEnd()

			return
		end

		var_0_8.ctx.battle.count = var_0_8.ctx.battle.count + 1

		if var_0_8.ctx.battle.nightCount > 0 and not arg_20_0.stopTimeCount_ then
			var_0_8.ctx.battle.nightCount = math.max(var_0_8.ctx.battle.nightCount - 1, 0)
		end

		if not arg_20_0.stopTimeCount_ then
			var_0_8.ctx.battle.timeCount = var_0_8.ctx.battle.timeCount + 1
		end

		arg_20_0:checkBlackLayerState()
		arg_20_0:adjustYs()

		for iter_20_1, iter_20_2 in ipairs(var_0_8.ctx.battle.teamA) do
			iter_20_2:singleLoop()
		end

		for iter_20_3, iter_20_4 in ipairs(var_0_8.ctx.battle.teamB) do
			iter_20_4:singleLoop()
		end

		if var_0_8.ctx.battle.isCountHurtNum then
			arg_20_0:setTotalHurt()
		end

		arg_20_0:updateInfoListener()
	end
end

function var_0_0.updateInfoListener(arg_21_0)
	for iter_21_0, iter_21_1 in pairs(var_0_8.ctx.battle.infoListener) do
		var_0_8.ctx.battle.infoList[iter_21_0] = {}

		for iter_21_2 = #iter_21_1, 1, -1 do
			var_0_8.ctx.battle.infoList[iter_21_0][iter_21_2] = iter_21_1[iter_21_2]
		end

		var_0_8.ctx.battle.infoListener[iter_21_0] = {}
	end
end

function var_0_0.updateWalk2Next(arg_22_0)
	if not var_0_8.ctx.battle.walk2NextBattle_ then
		return
	end

	for iter_22_0, iter_22_1 in ipairs(var_0_8.ctx.battle.teamA) do
		if iter_22_1:isDeath() ~= true and iter_22_1:getX() < var_0_7.STAGE_WIDTH + 100 then
			return
		end
	end

	var_0_8.ctx.battle.walk2NextBattle_ = false
	arg_22_0.stopTimeCount_ = false
	arg_22_0.group_ = arg_22_0.group_ + 1

	if arg_22_0.isGuide then
		if arg_22_0.group_ == 2 then
			arg_22_0.selfPlayer:sendOperationLog(var_0_7.StatID.ID_CLICK_CAMPAIGN_NEXT1)
		elseif arg_22_0.group_ == 3 then
			arg_22_0.selfPlayer:sendOperationLog(var_0_7.StatID.ID_CLICK_CAMPAIGN_NEXT2)
		end
	end

	arg_22_0:pauseBattle()
	arg_22_0:init()
end

function var_0_0.checkEnds(arg_23_0)
	if arg_23_0.isBattleEnded_ then
		return true
	end

	if var_0_8.ctx.battleConst.seconds - var_0_8.ctx.battle.timeCount <= 0 then
		arg_23_0.timeOut_ = true

		return true
	end

	if arg_23_0:checkEnd(var_0_7.TeamType.A) then
		arg_23_0.stopTimeCount_ = true

		if arg_23_0.group_ < #arg_23_0.heroGroupB then
			return false
		end

		return true
	elseif arg_23_0:checkEnd(var_0_7.TeamType.B) then
		return true
	end

	return false
end

function var_0_0.checkEnd(arg_24_0, arg_24_1)
	for iter_24_0, iter_24_1 in ipairs(var_0_8.ctx.battle.teamA) do
		if iter_24_1:canReborn() and iter_24_1:isDeath() then
			return false
		end
	end

	if arg_24_1 == var_0_7.TeamType.B then
		for iter_24_2, iter_24_3 in ipairs(var_0_8.ctx.battle.teamA) do
			if not iter_24_3:isDeath() or iter_24_3:canReborn() then
				return false
			end
		end

		return true
	else
		for iter_24_4, iter_24_5 in ipairs(var_0_8.ctx.battle.teamB) do
			if not iter_24_5:isDeath() or iter_24_5:canReborn() then
				return false
			end
		end

		return true
	end
end

function var_0_0.processAfterBattleEnd(arg_25_0, arg_25_1)
	for iter_25_0, iter_25_1 in ipairs(var_0_8.ctx.battle.teamA) do
		iter_25_1:processAfterBattleEnd(arg_25_1)
	end

	if not arg_25_1 then
		for iter_25_2, iter_25_3 in ipairs(var_0_8.ctx.battle.teamB) do
			iter_25_3:processAfterBattleEnd(false)
		end
	end
end

function var_0_0.reMpHp(arg_26_0)
	for iter_26_0, iter_26_1 in ipairs(var_0_8.ctx.battle.teamA) do
		iter_26_1:checkReHpMp()
	end

	for iter_26_2, iter_26_3 in ipairs(var_0_8.ctx.battle.teamB) do
		iter_26_3:checkReHpMp()
	end
end

function var_0_0.playWin(arg_27_0, arg_27_1)
	arg_27_0:removeBlackLayer()

	for iter_27_0, iter_27_1 in ipairs(arg_27_1) do
		iter_27_1:playWin()
	end
end

function var_0_0.adjustYs(arg_28_0)
	if var_0_8.ctx.battle.count % 10 > 0 or var_0_8.ctx.battle.count < 30 or var_0_8.ctx.battle.isEnergySkilling then
		return
	end

	arg_28_0.aOrders = {}
	arg_28_0.bOrders = {}

	for iter_28_0, iter_28_1 in ipairs(var_0_8.ctx.battle.teamA) do
		if not iter_28_1:isDeath() and not iter_28_1:isAffected() then
			table.insert(arg_28_0.aOrders, iter_28_1)
		end
	end

	for iter_28_2, iter_28_3 in ipairs(var_0_8.ctx.battle.teamB) do
		if not iter_28_3:isDeath() and not iter_28_3:isAffected() then
			table.insert(arg_28_0.bOrders, iter_28_3)
		end
	end

	table.sort(arg_28_0.aOrders, function(arg_29_0, arg_29_1)
		return arg_29_0:getY() < arg_29_1:getY()
	end)
	table.sort(arg_28_0.bOrders, function(arg_30_0, arg_30_1)
		return arg_30_0:getY() < arg_30_1:getY()
	end)
	arg_28_0:adjustY(arg_28_0.aOrders)
	arg_28_0:adjustY(arg_28_0.bOrders)
end

function var_0_0.adjustY(arg_31_0, arg_31_1)
	local var_31_0 = 100
	local var_31_1 = 400

	for iter_31_0 = 1, #arg_31_1 do
		local var_31_2 = arg_31_1[iter_31_0]
		local var_31_3 = iter_31_0 > 1 and arg_31_1[iter_31_0 - 1]
		local var_31_4 = iter_31_0 < #arg_31_1 and arg_31_1[iter_31_0 + 1]
		local var_31_5 = var_31_2:getX()
		local var_31_6 = var_31_2:getY()
		local var_31_7
		local var_31_8
		local var_31_9
		local var_31_10

		if var_31_3 then
			var_31_7, var_31_8 = var_31_3:getX(), var_31_3:getY()
		end

		if var_31_4 then
			var_31_9, var_31_10 = var_31_4:getX(), var_31_4:getY()
		end

		if not var_31_3 and not var_31_2:isMoveUnable() and not var_31_2:isInSkillRoll() and var_31_4 then
			if var_0_11(var_31_9 - var_31_5) < 80 and var_31_10 - var_31_6 < 35 and var_31_0 < var_31_6 then
				local var_31_11 = var_0_9(var_31_2:getBasicSpeed(), var_31_6 - var_31_0) * -1

				var_31_2:moveByY(var_31_11)

				var_31_2.isAdjustY_ = 1
			end
		elseif var_31_3 and not var_31_2:isMoveUnable() and not var_31_2:isInSkillRoll() and var_0_11(var_31_7 - var_31_5) < 80 and var_31_6 - var_31_8 < 35 and var_31_8 < var_31_1 then
			local var_31_12 = var_31_2:getBasicSpeed()

			var_31_2:moveByY(var_31_12)

			var_31_2.isAdjustY_ = 1
		elseif var_31_4 and not var_31_2:isMoveUnable() and not var_31_2:isInSkillRoll() and var_0_11(var_31_9 - var_31_5) < 80 and var_31_10 - var_31_6 < 35 and var_0_11(var_31_5 - var_31_7) < 80 and var_31_10 - var_31_6 > 100 + var_31_2:getBasicSpeed() then
			local var_31_13 = var_31_2:getBasicSpeed() * -1

			var_31_2:moveByY(var_31_13)

			var_31_2.isAdjustY_ = 1
		end
	end
end

function var_0_0.updateZorder(arg_32_0)
	table.sort(var_0_8.ctx.battle.yOrder, function(arg_33_0, arg_33_1)
		return arg_33_0:getY() > arg_33_1:getY()
	end)

	for iter_32_0 = 1, #var_0_8.ctx.battle.yOrder do
		local var_32_0 = var_0_8.ctx.battle.yOrder[iter_32_0]:getY()

		if iter_32_0 > 1 and var_32_0 == var_0_8.ctx.battle.yOrder[iter_32_0 - 1]:getY() then
			var_0_8.ctx.battle.yOrder[iter_32_0]:y(var_32_0 - 0.01)
		end

		var_0_8.ctx.battle.yOrder[iter_32_0].fighterModel:setLocalZOrder(iter_32_0)
	end
end

function var_0_0.clickNextBattle(arg_34_0)
	if var_0_8.ctx.battle.walk2NextBattle_ then
		return
	end

	var_0_8.ctx.battle.walk2NextBattle_ = true
	arg_34_0.stopTimeCount_ = false

	arg_34_0.battleBottomWindow:nextBattleBtn():hide()

	if arg_34_0.battleID <= var_0_8.ctx.battleConst.guideCampaignId - 1 and var_0_7.StoryData.get():getStoryID() <= arg_34_0.battleID then
		arg_34_0.battleBottomWindow:showGuideNext(false)
	end

	arg_34_0:clear()
	arg_34_0:reMpHp()
end

function var_0_0.clickAvatar(arg_35_0, arg_35_1, arg_35_2)
	arg_35_1:clickAvatar(arg_35_2)

	if not arg_35_1:checkEnergySkill() then
		return
	end

	if arg_35_1:manualType() == var_0_7.ManualType.None then
		if arg_35_2.name == "ended" and not arg_35_1.isEnergySkill_ then
			if arg_35_1:isCreatingUnits() then
				arg_35_1:skillIsBreak()
			end

			arg_35_1.isEnergySkill_ = true
			arg_35_1.leftInterval_ = 0

			arg_35_0.battleBottomWindow:energySkillEffect(arg_35_1, var_0_8.ctx.battle.teamA)
			var_0_8.ctx.battle.pushSoundQueue(var_0_7.tables.sound:getSound("battle_use_skill"))
		end

		return
	end

	if arg_35_2.name == "began" then
		if not arg_35_1.isEnergySkill_ then
			if arg_35_1:isCreatingUnits() then
				arg_35_1:skillIsBreak()
			end

			arg_35_1.isEnergySkill_ = true
			arg_35_1.leftInterval_ = 0
			arg_35_0.startX_ = arg_35_2.x
			arg_35_0.startY_ = arg_35_2.y

			arg_35_0:pauseBattle()
		end
	elseif arg_35_2.name == "moved" then
		local var_35_0 = var_0_11(arg_35_2.x - (arg_35_0.startX_ or arg_35_2.x)) > 10 or var_0_11(arg_35_2.y - (arg_35_0.startY_ or arg_35_2.y)) > 10

		if arg_35_1.isEnergySkill_ and var_35_0 then
			arg_35_0:manualTarget(arg_35_1, arg_35_2)
		end
	elseif arg_35_2.name == "ended" then
		if arg_35_1.isEnergySkill_ then
			if arg_35_0.manualSp1_ then
				arg_35_0.manualSp1_:setVisible(false)
			end

			if arg_35_0.manualSp2_ then
				arg_35_0.manualSp2_:setVisible(false)
			end

			if arg_35_0.manualSp1_1 then
				arg_35_0.manualSp1_3:setVisible(false)
				arg_35_0.manualSp1_2:setVisible(false)
				arg_35_0.manualSp1_1:setVisible(false)
				arg_35_0.manualSp1_1:setScale(1)
			end

			if arg_35_0.manualSp3_1 then
				arg_35_0.manualSp3_1:setVisible(false)
				arg_35_0.manualSp1_2:setVisible(false)
			end
		end

		arg_35_0:startBattle()
		arg_35_0.battleBottomWindow:energySkillEffect(arg_35_1, var_0_8.ctx.battle.teamA)
	end
end

function var_0_0.manualTarget(arg_36_0, arg_36_1, arg_36_2)
	if arg_36_1:manualType() == var_0_7.ManualType.Single then
		arg_36_0:manualTargetType_1(arg_36_1, arg_36_2)
	elseif arg_36_1:manualType() == var_0_7.ManualType.Area then
		arg_36_0:manualTargetType_2(arg_36_1, arg_36_2)
	elseif arg_36_1:manualType() == var_0_7.ManualType.Direction then
		arg_36_0:manualTargetType_3(arg_36_1, arg_36_2)
	elseif arg_36_1:manualType() == var_0_7.ManualType.MoonLight then
		arg_36_0:manualTargetType_4(arg_36_1, arg_36_2)
	end
end

function var_0_0.manualTargetType_1(arg_37_0, arg_37_1, arg_37_2)
	if not arg_37_0.manualSp1_1 then
		arg_37_0.manualSp1_1 = var_0_7.AssetLoader.get():loadSprite("images/battle_manual_1_1.png")

		arg_37_0.manualSp1_1:addTo(var_0_8.ctx.battle.playerLayer, 0)

		arg_37_0.manualSp1_2 = var_0_7.AssetLoader.get():loadSprite("images/battle_manual_1_2.png")

		arg_37_0.manualSp1_2:addTo(var_0_8.ctx.battle.playerLayer, 0)

		arg_37_0.manualSp1_3 = var_0_7.AssetLoader.get():loadSprite("images/battle_manual_1_3.png")

		arg_37_0.manualSp1_3:addTo(var_0_8.ctx.battle.playerLayer, 0)
	end

	local var_37_0 = arg_37_2.x
	local var_37_1 = arg_37_2.y
	local var_37_2, var_37_3 = arg_37_1.fighterModel:getPosition()

	if var_37_0 > arg_37_1:getX() then
		arg_37_1:getFighterModel():flipX(false)
	else
		arg_37_1:getFighterModel():flipX(true)
	end

	local var_37_4 = math.atan2(var_37_1 - var_37_3, var_37_0 - var_37_2)
	local var_37_5
	local var_37_6
	local var_37_7 = var_0_1:type(arg_37_1:getEnergySkillID()) == var_0_7.AttackType.CURE and var_0_8.ctx.battle.teamA or var_0_8.ctx.battle.teamB
	local var_37_8 = {}

	for iter_37_0, iter_37_1 in ipairs(var_37_7) do
		if not iter_37_1:isDeath() and not iter_37_1:isAffected() then
			table.insert(var_37_8, iter_37_1)
		end
	end

	table.sort(var_37_8, function(arg_38_0, arg_38_1)
		return var_0_11(arg_38_0:getX() - var_37_0) < var_0_11(arg_38_1:getX() - var_37_0)
	end)

	for iter_37_2 = 1, #var_37_8 do
		if not var_37_6 then
			var_37_6 = var_37_8[iter_37_2]
			var_37_5 = var_0_11(var_37_6:getY() - var_37_1)
		elseif var_0_11(var_37_8[iter_37_2]:getX() - var_37_0) < var_0_7.tables.battleConfig.manualSelectWidth and var_37_5 > var_0_11(var_37_8[iter_37_2]:getY() - var_37_1) then
			var_37_6 = var_37_8[iter_37_2]
			var_37_5 = var_0_11(var_37_8[iter_37_2]:getY() - var_37_1)
		end

		if var_0_11(var_37_8[iter_37_2]:getX() - var_37_0) >= var_0_7.tables.battleConfig.manualSelectWidth then
			break
		end
	end

	if not var_37_6 then
		arg_37_0.manualSp1_3:setVisible(false)
		arg_37_0.manualSp1_2:setVisible(false)
		arg_37_0.manualSp1_1:setVisible(false)

		return
	end

	local var_37_9 = math.atan2(var_37_6:getY() - var_37_3, var_37_6:getX() - var_37_2) / math.pi * -180
	local var_37_10 = var_0_14((var_37_6:getY() - var_37_3) * (var_37_6:getY() - var_37_3) + (var_37_6:getX() - var_37_2) * (var_37_6:getX() - var_37_2)) - arg_37_0.manualSp1_3:getWidth() / 2 - arg_37_0.manualSp1_2:getWidth() / 2 + 30
	local var_37_11 = var_0_10(var_37_10, 0)

	arg_37_0.manualSp1_2:setVisible(true)
	arg_37_0.manualSp1_2:pos(arg_37_1:getX(), arg_37_1:getY())
	arg_37_0.manualSp1_3:setVisible(true)
	arg_37_0.manualSp1_3:pos(var_37_6:getX(), var_37_6:getY())
	arg_37_0.manualSp1_1:setVisible(true)
	arg_37_0.manualSp1_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_37_0.manualSp1_1:setScaleX(var_37_11 / arg_37_0.manualSp1_1:getWidth())
	arg_37_0.manualSp1_1:pos(var_37_6:getX() / 2 + var_37_2 / 2, var_37_6:getY() / 2 + var_37_3 / 2)
	arg_37_0.manualSp1_1:setRotation(var_37_9)
	var_37_6:unsetMaskColor()

	for iter_37_3, iter_37_4 in ipairs(var_0_8.ctx.battle.teamB) do
		if not iter_37_4:isDeath() and iter_37_4 ~= var_37_6 then
			iter_37_4:setMaskColor()
		end
	end

	arg_37_1.manualTargets_ = {
		var_37_6
	}
end

function var_0_0.manualTargetType_2(arg_39_0, arg_39_1, arg_39_2)
	if not arg_39_0.manualSp2_ then
		arg_39_0.manualSp2_ = var_0_7.AssetLoader.get():loadSprite("images/battle_manual_2_1.png")

		arg_39_0.manualSp2_:addTo(var_0_8.ctx.battle.playerLayer, 0)
	end

	arg_39_0.manualSp2_:setVisible(true)
	arg_39_0.manualSp2_:setAnchorPoint(cc.p(0.5, 0.5))

	local var_39_0 = arg_39_2.x

	if var_39_0 > arg_39_1:getX() then
		arg_39_1:getFighterModel():flipX(false)
	else
		arg_39_1:getFighterModel():flipX(true)
	end

	if arg_39_1:getFlipX() then
		var_39_0 = var_0_10(var_39_0, arg_39_1:getX() - arg_39_1:getFrontSkillDistance())
		var_39_0 = var_0_10(arg_39_1:getScope() / 2, var_39_0)
	else
		var_39_0 = var_0_9(var_39_0, arg_39_1:getX() + arg_39_1:getFrontSkillDistance())
		var_39_0 = var_0_9(var_0_7.STAGE_WIDTH - arg_39_1:getScope() / 2, var_39_0)
	end

	arg_39_0.manualSp2_:pos(var_39_0, arg_39_2.y)

	local var_39_1 = {}
	local var_39_2 = var_0_1:type(arg_39_1:getEnergySkillID()) == var_0_7.AttackType.CURE and var_0_8.ctx.battle.teamA or var_0_8.ctx.battle.teamB

	for iter_39_0, iter_39_1 in ipairs(var_39_2) do
		if not iter_39_1:isDeath() and iter_39_1:getX() > var_39_0 - arg_39_1:getScope() / 2 and iter_39_1:getX() < var_39_0 + arg_39_1:getScope() / 2 then
			table.insert(var_39_1, iter_39_1)
			iter_39_1:unsetMaskColor()
		else
			iter_39_1:setMaskColor()
		end
	end

	arg_39_1.manualTargets_ = var_39_1
	arg_39_1.manualPosition_ = {
		var_39_0,
		arg_39_2.y
	}
end

function var_0_0.manualTargetType_3(arg_40_0, arg_40_1, arg_40_2)
	if not arg_40_0.manualSp3_1 then
		arg_40_0.manualSp3_1 = var_0_7.AssetLoader.get():loadSprite("images/battle_manual_3_1.png")

		arg_40_0.manualSp3_1:addTo(var_0_8.ctx.battle.playerLayer, 0)
	end

	if not arg_40_0.manualSp1_2 then
		arg_40_0.manualSp1_2 = var_0_7.AssetLoader.get():loadSprite("images/battle_manual_1_2.png")

		arg_40_0.manualSp1_2:addTo(var_0_8.ctx.battle.playerLayer, 0)
	end

	local var_40_0 = arg_40_2.x
	local var_40_1 = arg_40_2.y
	local var_40_2, var_40_3 = arg_40_1.fighterModel:getPosition()

	if var_40_0 >= arg_40_1:getX() then
		arg_40_1:getFighterModel():flipX(false)
		arg_40_0.manualSp3_1:flipX(false)
		arg_40_0.manualSp3_1:pos(var_40_2 + arg_40_0.manualSp3_1:getWidth() / 2 + arg_40_0.manualSp1_2:getWidth() / 2 - 15, var_40_3)
	else
		arg_40_1:getFighterModel():flipX(true)
		arg_40_0.manualSp3_1:flipX(true)
		arg_40_0.manualSp3_1:pos(var_40_2 - arg_40_0.manualSp3_1:getWidth() / 2 - arg_40_0.manualSp1_2:getWidth() / 2 + 15, var_40_3)
	end

	arg_40_0.manualSp1_2:setVisible(true)
	arg_40_0.manualSp1_2:pos(arg_40_1:getX(), arg_40_1:getY())
	arg_40_0.manualSp3_1:setVisible(true)
	arg_40_0.manualSp3_1:align(display.CENTER)

	arg_40_1.manualDirection_ = var_40_0 >= arg_40_1:getX() and 1 or 0
end

function var_0_0.manualTargetType_4(arg_41_0, arg_41_1, arg_41_2)
	if not arg_41_0.manualSp1_1 then
		arg_41_0.manualSp1_1 = var_0_7.AssetLoader.get():loadSprite("images/battle_manual_1_1.png")

		arg_41_0.manualSp1_1:addTo(var_0_8.ctx.battle.playerLayer, 0)

		arg_41_0.manualSp1_2 = var_0_7.AssetLoader.get():loadSprite("images/battle_manual_1_2.png")

		arg_41_0.manualSp1_2:addTo(var_0_8.ctx.battle.playerLayer, 0)

		arg_41_0.manualSp1_3 = var_0_7.AssetLoader.get():loadSprite("images/battle_manual_1_3.png")

		arg_41_0.manualSp1_3:addTo(var_0_8.ctx.battle.playerLayer, 0)
	end

	local var_41_0 = arg_41_2.x
	local var_41_1 = arg_41_2.y
	local var_41_2, var_41_3 = arg_41_1.fighterModel:getPosition()

	if var_41_0 > arg_41_1:getX() then
		arg_41_1:getFighterModel():flipX(false)
	else
		arg_41_1:getFighterModel():flipX(true)
	end

	local var_41_4 = math.atan2(var_41_1 - var_41_3, var_41_0 - var_41_2)
	local var_41_5
	local var_41_6
	local var_41_7 = var_0_1:type(arg_41_1:getSkillID()) == var_0_7.AttackType.CURE and var_0_8.ctx.battle.teamA or var_0_8.ctx.battle.teamB
	local var_41_8 = {}
	local var_41_9
	local var_41_10

	for iter_41_0, iter_41_1 in ipairs(var_41_7) do
		if not iter_41_1:isDeath() and not iter_41_1:isAffected() and iter_41_1:isHasBuffByID(var_0_7.MOON_LIGHT_BUFF) then
			table.insert(var_41_8, iter_41_1)
		end

		if not iter_41_1:isDeath() and not iter_41_1:isAffected() and (not var_41_10 or var_41_10 > var_0_11(iter_41_1:getX() - arg_41_1:getX())) then
			var_41_9 = iter_41_1
			var_41_10 = var_0_11(iter_41_1:getX() - arg_41_1:getX())
		end
	end

	if not next(var_41_8) and var_41_9 then
		var_41_8 = {
			var_41_9
		}
	end

	table.sort(var_41_8, function(arg_42_0, arg_42_1)
		return var_0_11(arg_42_0:getX() - var_41_0) < var_0_11(arg_42_1:getX() - var_41_0)
	end)

	for iter_41_2 = 1, #var_41_8 do
		if not var_41_6 then
			var_41_6 = var_41_8[iter_41_2]
			var_41_5 = var_0_11(var_41_6:getY() - var_41_1)
		elseif var_0_11(var_41_8[iter_41_2]:getX() - var_41_0) < var_0_7.tables.battleConfig.manualSelectWidth and var_41_5 > var_0_11(var_41_8[iter_41_2]:getY() - var_41_1) then
			var_41_6 = var_41_8[iter_41_2]
			var_41_5 = var_0_11(var_41_8[iter_41_2]:getY() - var_41_1)
		end

		if var_0_11(var_41_8[iter_41_2]:getX() - var_41_0) >= var_0_7.tables.battleConfig.manualSelectWidth then
			break
		end
	end

	if not var_41_6 then
		arg_41_0.manualSp1_3:setVisible(false)
		arg_41_0.manualSp1_2:setVisible(false)
		arg_41_0.manualSp1_1:setVisible(false)

		return
	end

	local var_41_11 = math.atan2(var_41_6:getY() - var_41_3, var_41_6:getX() - var_41_2) / math.pi * -180
	local var_41_12 = var_0_14((var_41_6:getY() - var_41_3) * (var_41_6:getY() - var_41_3) + (var_41_6:getX() - var_41_2) * (var_41_6:getX() - var_41_2)) - arg_41_0.manualSp1_3:getWidth() / 2 - arg_41_0.manualSp1_2:getWidth() / 2 + 30
	local var_41_13 = var_0_10(var_41_12, 0)

	arg_41_0.manualSp1_2:setVisible(true)
	arg_41_0.manualSp1_2:pos(arg_41_1:getX(), arg_41_1:getY())
	arg_41_0.manualSp1_3:setVisible(true)
	arg_41_0.manualSp1_3:pos(var_41_6:getX(), var_41_6:getY())
	arg_41_0.manualSp1_1:setVisible(true)
	arg_41_0.manualSp1_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_41_0.manualSp1_1:setScaleX(var_41_13 / arg_41_0.manualSp1_1:getWidth())
	arg_41_0.manualSp1_1:pos(var_41_6:getX() / 2 + var_41_2 / 2, var_41_6:getY() / 2 + var_41_3 / 2)
	arg_41_0.manualSp1_1:setRotation(var_41_11)
	var_41_6:unsetMaskColor()

	for iter_41_3, iter_41_4 in ipairs(var_0_8.ctx.battle.teamB) do
		if not iter_41_4:isDeath() and iter_41_4 ~= var_41_6 then
			iter_41_4:setMaskColor()
		end
	end

	arg_41_1.manualTargetsMoon_ = {
		var_41_6
	}
end

function var_0_0.writeReport(arg_43_0)
	if arg_43_0.report_ then
		return var_0_6.encode(arg_43_0.report_)
	end

	arg_43_0.report_ = {}
	arg_43_0.report_.fighter = {}

	for iter_43_0, iter_43_1 in ipairs(var_0_8.ctx.battle.teamA) do
		arg_43_0.report_.fighter[iter_43_1.fighterIndex] = iter_43_1:writeReport()
	end

	for iter_43_2, iter_43_3 in ipairs(var_0_8.ctx.battle.teamB) do
		arg_43_0.report_.fighter[iter_43_3.fighterIndex] = iter_43_3:writeReport()
	end

	arg_43_0.report_.star = arg_43_0:getBattleStar()

	return var_0_6.encode(arg_43_0.report_)
end

function var_0_0.checkBattleReport(arg_44_0)
	for iter_44_0, iter_44_1 in ipairs(var_0_8.ctx.battle.teamA) do
		if table.nums(iter_44_1.hero_.errorData_ or {}) > 0 then
			return 1
		end
	end

	for iter_44_2, iter_44_3 in ipairs(var_0_8.ctx.battle.teamB) do
		if table.nums(iter_44_3.hero_.errorData_ or {}) > 0 then
			return 1
		end
	end

	return 0
end

function var_0_0.getSuperArenaBattleStar(arg_45_0)
	if not arg_45_0.timeOut_ then
		return arg_45_0:getDefaultBattleStar()
	end

	if arg_45_0:getAliveCount(var_0_8.ctx.battle.teamA) > arg_45_0:getAliveCount(var_0_8.ctx.battle.teamB) then
		arg_45_0.battleStar_ = 1

		return 1
	elseif arg_45_0:getAliveCount(var_0_8.ctx.battle.teamA) < arg_45_0:getAliveCount(var_0_8.ctx.battle.teamB) then
		arg_45_0.battleStar_ = 0

		return 0
	else
		arg_45_0.battleStar_ = arg_45_0:getTotalHarms(var_0_8.ctx.battle.teamA) >= arg_45_0:getTotalHarms(var_0_8.ctx.battle.teamB) and 1 or 0

		return arg_45_0.battleStar_
	end
end

function var_0_0.getDefaultBattleStar(arg_46_0)
	if not arg_46_0.isBattleEnded_ or arg_46_0.timeOut_ then
		arg_46_0.battleStar_ = 0

		return 0
	end

	local var_46_0 = 0

	for iter_46_0, iter_46_1 in pairs(var_0_8.ctx.battle.teamA) do
		if iter_46_1:isDeath() and iter_46_1.summonType_ == var_0_7.summonMonsterType.None then
			var_46_0 = var_46_0 + 1
		end
	end

	if var_46_0 == 0 then
		if arg_46_0.rentFlag_ then
			arg_46_0.battleStar_ = 2

			return 2
		else
			arg_46_0.battleStar_ = 3

			return 3
		end
	elseif var_46_0 == 1 and var_46_0 < #arg_46_0.herosA then
		arg_46_0.battleStar_ = 2

		return 2
	elseif var_46_0 >= 2 and var_46_0 < #arg_46_0.herosA then
		arg_46_0.battleStar_ = 1

		return 1
	else
		arg_46_0.battleStar_ = 0

		return 0
	end
end

function var_0_0.getTotalHarms(arg_47_0, arg_47_1)
	local var_47_0 = 0

	for iter_47_0, iter_47_1 in ipairs(arg_47_1) do
		if iter_47_1:getSummonType() == var_0_7.summonMonsterType.None or iter_47_1:getSummonType() == var_0_7.summonMonsterType.Pet then
			var_47_0 = var_47_0 + iter_47_1.harms
		end
	end

	return var_47_0
end

function var_0_0.getAliveCount(arg_48_0, arg_48_1)
	local var_48_0 = 0

	for iter_48_0, iter_48_1 in ipairs(arg_48_1) do
		if iter_48_1:getSummonType() == var_0_7.summonMonsterType.None and not iter_48_1:isDeath() then
			var_48_0 = var_48_0 + 1
		end
	end

	return var_48_0
end

function var_0_0.getBattleStar(arg_49_0)
	if var_0_7.BattleType.ReplayReport == var_0_8.ctx.battle.battleType then
		return arg_49_0.reportStar_
	end

	if arg_49_0.battleStar_ and arg_49_0.battleStar_ >= 0 then
		return arg_49_0.battleStar_
	end

	if arg_49_0.campaignType == var_0_7.CampaignType.SUPER_ARENA or arg_49_0.campaignType == var_0_7.CampaignType.GUILD_ARENA or arg_49_0.campaignType == var_0_7.CampaignType.REGION_ARENA then
		return arg_49_0:getSuperArenaBattleStar()
	end

	return arg_49_0:getDefaultBattleStar()
end

function var_0_0.superArenaResult(arg_50_0, arg_50_1)
	local var_50_0 = arg_50_0.peakArena:getCurrentBattleRound()

	arg_50_0.peakArena:setBattleReport(var_50_0, arg_50_0:writeReport(), arg_50_0:checkBattleReport())

	arg_50_0.report_ = nil

	local var_50_1 = arg_50_0.peakArena:setBattleResult(var_50_0, arg_50_0:getBattleStar())

	for iter_50_0, iter_50_1 in ipairs(var_0_8.ctx.battle.teamA) do
		local var_50_2 = {
			iter_50_1:getDamage(),
			iter_50_1:getKillCount()
		}

		arg_50_0.superArenaData[tostring(iter_50_1.hero_:getTableID())] = var_50_2
	end

	if var_50_1 then
		local var_50_3 = {}
		local var_50_4 = {}

		for iter_50_2, iter_50_3 in ipairs(var_0_8.ctx.battle.teamA) do
			if iter_50_3:getSummonType() == var_0_7.summonMonsterType.None then
				table.insert(var_50_3, iter_50_3)
			end
		end

		for iter_50_4, iter_50_5 in ipairs(var_0_8.ctx.battle.teamB) do
			if iter_50_5:getSummonType() == var_0_7.summonMonsterType.None then
				table.insert(var_50_4, iter_50_5)
			end
		end

		arg_50_0:clearFormation(true)

		var_0_8.ctx.battle.teamA = {}
		var_0_8.ctx.battle.teamB = {}

		arg_50_0.peakArena:setCurrentBattleRound(arg_50_0.peakArena:getCurrentBattleRound() + 1)

		arg_50_0.herosA = arg_50_0.heroGroupA["team" .. arg_50_0.peakArena:getCurrentBattleRound()]
		arg_50_0.petsA = arg_50_0.heroGroupA["pet" .. arg_50_0.peakArena:getCurrentBattleRound()]
		arg_50_0.petsB = arg_50_0.heroGroupB["pet" .. arg_50_0.peakArena:getCurrentBattleRound()]

		arg_50_0:init()

		return
	end

	local var_50_5 = {
		hero_data = arg_50_0.superArenaData,
		team1 = arg_50_0.team1,
		team2 = arg_50_0.team2,
		team3 = arg_50_0.team3,
		pet1 = arg_50_0.pet1,
		pet2 = arg_50_0.pet2,
		pet3 = arg_50_0.pet3,
		campaign_type = arg_50_0.campaignType,
		stars = arg_50_0.peakArena:getBattleResult(),
		enemy_id = arg_50_0.enemyID_,
		reports = arg_50_0.peakArena:getBattleReport(),
		report_invalids = arg_50_0.peakArena:getReportInvalid(),
		lib_mission_formations = arg_50_0.libraryFormations
	}

	arg_50_0.superArenaData = {}

	var_0_7.Backend.get():request(var_0_7.mid.PEAK_FIGHT_RESULT, var_50_5, function(arg_51_0, arg_51_1)
		if arg_51_0 == var_0_7.error.OK or tonumber(arg_51_1.error_code or 0) == var_0_8.ctx.battleConst.errorIdFightExist then
			var_0_7.EventDispatcher.get():dispatchEvent({
				name = var_0_7.event.BATTLE_REPORT_CREATE,
				response = arg_51_1
			})
		end
	end, nil, nil, true)
end

function var_0_0.arenaResult(arg_52_0, arg_52_1)
	if arg_52_1 then
		return
	end

	arg_52_0.fighterInfo.self_formation = {}

	if #arg_52_0.petsA ~= 0 then
		arg_52_0.fighterInfo.self_pet = arg_52_0.petsA[1].petID_
	else
		arg_52_0.fighterInfo.self_pet = 0
	end

	if #arg_52_0.petsB ~= 0 then
		arg_52_0.fighterInfo.enemy_pet = arg_52_0.petsB[1].petID_
	else
		arg_52_0.fighterInfo.enemy_pet = 0
	end

	for iter_52_0, iter_52_1 in ipairs(arg_52_0.herosA) do
		table.insert(arg_52_0.fighterInfo.self_formation, iter_52_1:getTableID())
	end

	arg_52_0.fighterInfo.enemy_formation = {}

	for iter_52_2, iter_52_3 in ipairs(arg_52_0.herosB) do
		table.insert(arg_52_0.fighterInfo.enemy_formation, iter_52_3:getTableID())
	end

	table.sort(arg_52_0.fighterInfo.enemy_formation, function(arg_53_0, arg_53_1)
		return arg_53_0 < arg_53_1
	end)
	table.sort(arg_52_0.fighterInfo.self_formation, function(arg_54_0, arg_54_1)
		return arg_54_0 < arg_54_1
	end)

	arg_52_0.fighterInfo.self_hero_types = {}

	for iter_52_4, iter_52_5 in ipairs(arg_52_0.fighterInfo.self_formation) do
		local var_52_0 = var_0_7.tables.hero:distanceType(iter_52_5)
		local var_52_1 = var_0_7.tables.hero:heroType(iter_52_5)

		table.insert(arg_52_0.fighterInfo.self_hero_types, var_52_1 * 10 + var_52_0)
	end

	arg_52_0.fighterInfo.enemy_hero_types = {}

	for iter_52_6, iter_52_7 in ipairs(arg_52_0.fighterInfo.enemy_formation) do
		local var_52_2 = var_0_7.tables.hero:distanceType(iter_52_7)
		local var_52_3 = var_0_7.tables.hero:heroType(iter_52_7)

		table.insert(arg_52_0.fighterInfo.enemy_hero_types, var_52_3 * 10 + var_52_2)
	end

	local var_52_4 = {}

	for iter_52_8, iter_52_9 in ipairs(var_0_8.ctx.battle.teamA) do
		local var_52_5 = {
			iter_52_9:getDamage(),
			iter_52_9:getKillCount()
		}

		var_52_4[tostring(iter_52_9.hero_:getTableID())] = var_52_5
	end

	local var_52_6 = {
		hero_data = var_52_4,
		formation = arg_52_0.formation,
		campaign_type = arg_52_0.campaignType,
		star = arg_52_0:getBattleStar(),
		fighter_info = arg_52_0.fighterInfo,
		report = arg_52_0:writeReport(),
		report_invalid = arg_52_0:checkBattleReport(),
		is_avenge = arg_52_0.is_avenge,
		lib_mission_formations = arg_52_0.libraryFormations
	}

	if FRONT_ARENA_BATTLE then
		var_0_7.EventDispatcher.get():dispatchEvent({
			name = var_0_7.event.BATTLE_REPORT_CREATE,
			response = {
				partner_favor = {}
			}
		})
	else
		var_0_7.Backend.get():request(var_0_7.mid.ARENA_FIGHT_RESULT, var_52_6, function(arg_55_0, arg_55_1)
			if arg_55_0 == var_0_7.error.OK or tonumber(arg_55_1.error_code or 0) == var_0_8.ctx.battleConst.errorIdFightExist then
				var_0_7.EventDispatcher.get():dispatchEvent({
					name = var_0_7.event.BATTLE_REPORT_CREATE,
					response = arg_55_1
				})
			end
		end, nil, nil, true)
	end
end

function var_0_0.lvbuFestivalResult(arg_56_0, arg_56_1)
	if arg_56_1 then
		return
	end

	local var_56_0 = var_0_7.ModelManager.get():loadModel(var_0_7.ModelType.LVBU_FESTIVAL)
	local var_56_1 = {
		campaign_id = var_56_0.details.campaign_id,
		event_id = var_56_0.details.event_id,
		is_succ = arg_56_0:getBattleStar()
	}

	local function var_56_2()
		var_0_7.EventDispatcher.get():dispatchEvent({
			name = var_0_7.event.BATTLE_REPORT_CREATE,
			response = response
		})

		var_56_0.result = var_56_1
		var_56_0.result.story_id = var_56_0.story_id
		var_56_0.result.playingIndex = var_56_0.playingIndex
	end

	if var_56_1.is_succ == 0 then
		var_56_0:goForward(var_56_1, function(arg_58_0, arg_58_1)
			if arg_58_0 == var_0_7.error.OK then
				var_56_2()
			end
		end)
	else
		var_56_2()
	end
end

function var_0_0.campaignResult(arg_59_0, arg_59_1)
	local var_59_0 = ""

	for iter_59_0, iter_59_1 in ipairs(arg_59_0.herosA) do
		var_59_0 = var_59_0 .. string.format("%d", iter_59_1:getHeroID())

		if iter_59_0 < #arg_59_0.herosA then
			var_59_0 = var_59_0 .. "|"
		end
	end

	local var_59_1 = 0

	if #arg_59_0.petsA ~= 0 then
		var_59_1 = arg_59_0.petsA[1].petID_
	end

	local var_59_2 = {
		campaign_id = arg_59_0.campaignID,
		star = arg_59_0:getBattleStar(),
		campaign_type = arg_59_0.campaignType,
		formation = var_59_0,
		pet_id = var_59_1
	}
	local var_59_3 = var_0_7.ModelManager.get():loadModel(var_0_7.ModelType.SELF_PLAYER)

	var_0_7.Backend.get():request(var_0_7.mid.FIGHT_RESULT, var_59_2, function(arg_60_0, arg_60_1)
		if arg_60_0 == var_0_7.error.OK or tonumber(arg_60_1.error_code or 0) == var_0_8.ctx.battleConst.errorIdFightExist then
			local var_60_0 = arg_60_1.chapter_info

			if var_60_0 ~= nil then
				var_59_3.normal_chapter_id = var_60_0.normal_chapter_id
				var_59_3.normal_campaign_id = var_60_0.normal_campaign_id
				var_59_3.super_chapter_id = var_60_0.super_chapter_id
				var_59_3.super_campaign_id = var_60_0.super_campaign_id
				var_59_3.super_stars = var_60_0.super_stars
				var_59_3.normal_stars = var_60_0.normal_stars
			end

			if arg_60_1.campaigns ~= nil then
				for iter_60_0, iter_60_1 in pairs(arg_60_1.campaigns) do
					local var_60_1 = tonumber(iter_60_1.campaign_id)

					if var_60_1 then
						var_59_3.worldMaps_[var_60_1] = {}
						var_59_3.worldMaps_[var_60_1].star = tonumber(iter_60_1.star)
						var_59_3.worldMaps_[var_60_1].dailyLimit = tonumber(iter_60_1.daily_limit)
						var_59_3.worldMaps_[var_60_1].resetCount = tonumber(iter_60_1.reset_count)
					end
				end
			end

			if arg_60_1.trial ~= nil then
				local var_60_2 = arg_60_1.trial
				local var_60_3 = tonumber(var_60_2.id)

				if var_60_3 then
					var_59_3.trialInfos_[var_60_3] = {}
					var_59_3.trialInfos_[var_60_3].id = tonumber(var_60_2.id)
					var_59_3.trialInfos_[var_60_3].leftTimes = tonumber(var_60_2.left_times)
					var_59_3.trialInfos_[var_60_3].isOpen = tonumber(var_60_2.is_open)
					var_59_3.trialInfos_[var_60_3].maxTimes = tonumber(var_60_2.max_times)
					var_59_3.trialInfos_[var_60_3].lastID = tonumber(var_60_2.last_id)
				end
			end

			if not arg_59_1 then
				arg_59_0:runActionOnce(cc.CallFunc:create(function()
					arg_59_0:finishBattle(arg_60_1)
				end), false, nil, 2)
			end
		end
	end, nil, nil, true)
end

function var_0_0.treasureResult(arg_62_0, arg_62_1)
	if arg_62_1 then
		return
	end

	params = {
		win = arg_62_0:getBattleStar() > 0,
		report = arg_62_0:writeReport()
	}
	params.hero_status = {}

	for iter_62_0, iter_62_1 in ipairs(var_0_8.ctx.battle.teamA) do
		if iter_62_1.summonType_ == var_0_7.summonMonsterType.None then
			local var_62_0 = {
				hero_id = iter_62_1.hero_:getHeroID(),
				hp = arg_62_0.timeOut_ and 0 or iter_62_1:getHp(),
				mp = arg_62_0.timeOut_ and 0 or iter_62_1:getEnergy(),
				is_reborn = iter_62_1:hasReborned() and 1 or 0
			}

			table.insert(params.hero_status, var_62_0)
		end
	end

	params.enemy_status = {}

	for iter_62_2, iter_62_3 in ipairs(var_0_8.ctx.battle.teamB) do
		if iter_62_3.summonType_ == var_0_7.summonMonsterType.None then
			local var_62_1 = {
				hero_id = iter_62_3.hero_:getHeroID(),
				hp = arg_62_0.timeOut_ and 0 or iter_62_3:getHp(),
				mp = arg_62_0.timeOut_ and 0 or iter_62_3:getEnergy(),
				is_reborn = iter_62_3:hasReborned() and 1 or 0
			}

			table.insert(params.enemy_status, var_62_1)
		end
	end

	if arg_62_0:getBattleStar() <= 0 then
		local var_62_2 = var_0_7.ModelManager.get():loadModel(var_0_7.ModelType.TREASURE)

		var_62_2:updateHeroStatus(params.hero_status, true)
		var_62_2:updateHeroStatus(params.enemy_status, false)
	end

	var_0_7.Backend.get():request(var_0_7.mid.TREASURE_SAVE_BATTLE_RESULT, params, function(arg_63_0, arg_63_1)
		if (arg_63_0 == var_0_7.error.OK or tonumber(arg_63_1.error_code or 0) == var_0_8.ctx.battleConst.errorIdFightExist) and not arg_62_1 then
			arg_62_0:runActionOnce(cc.CallFunc:create(function()
				arg_62_0:finishBattle(arg_63_1)
			end), false, nil, 2)
		end
	end, nil, nil, true)
end

function var_0_0.marchResult(arg_65_0, arg_65_1)
	if arg_65_1 then
		return
	end

	local var_65_0 = {
		is_reborn = 0,
		win = arg_65_0:getBattleStar() > 0
	}

	if var_65_0.win == true then
		arg_65_0:reMpHp()
	end

	var_65_0.hero_status = {}

	for iter_65_0, iter_65_1 in ipairs(var_0_8.ctx.battle.teamA) do
		local var_65_1 = {}

		if iter_65_1.hero_.player_id then
			var_65_1.player_id = iter_65_1.hero_.player_id
		else
			var_65_1.player_id = arg_65_0.selfPlayer.playerID
		end

		var_65_1.hero_id = iter_65_1.hero_:getHeroID()
		var_65_1.hp = arg_65_0.timeOut_ and 0 or iter_65_1:getHp()
		var_65_1.mp = arg_65_0.timeOut_ and 0 or iter_65_1:getEnergy()
		var_65_1.is_reborn = iter_65_1:hasReborned() and 1 or 0

		table.insert(var_65_0.hero_status, var_65_1)
	end

	var_65_0.enemy_status = {}

	for iter_65_2, iter_65_3 in ipairs(var_0_8.ctx.battle.teamB) do
		local var_65_2 = {
			hero_id = iter_65_3.hero_:getHeroID(),
			hp = arg_65_0.timeOut_ and 0 or iter_65_3:getHp(),
			mp = arg_65_0.timeOut_ and 0 or iter_65_3:getEnergy(),
			is_reborn = iter_65_3:hasReborned() and 1 or 0
		}

		table.insert(var_65_0.enemy_status, var_65_2)
	end

	var_0_7.Backend.get():request(var_0_7.mid.MARCH_FIGHT_RESULT, var_65_0, function(arg_66_0, arg_66_1)
		if (arg_66_0 == var_0_7.error.OK or tonumber(arg_66_1.error_code or 0) == var_0_8.ctx.battleConst.errorIdFightExist) and not arg_65_1 then
			arg_65_0:runActionOnce(cc.CallFunc:create(function()
				arg_65_0:finishBattle(arg_66_1)
			end), false, nil, 2)
		end
	end, nil, nil, true)
end

function var_0_0.sendBattleResult(arg_68_0, arg_68_1)
	arg_68_0:updateLibraryFormations()

	if arg_68_0.campaignType == var_0_7.CampaignType.SUPER_ARENA then
		arg_68_0:superArenaResult(arg_68_1)
	elseif arg_68_0.campaignType == var_0_7.CampaignType.ARENA then
		arg_68_0:arenaResult(arg_68_1)
	elseif arg_68_0.campaignType == var_0_7.CampaignType.REGION_ARENA then
		arg_68_0:regionArenaResult(arg_68_1)
	elseif arg_68_0.campaignType == var_0_7.CampaignType.LVBU_FESTIVAL then
		arg_68_0:lvbuFestivalResult(arg_68_1)
	elseif arg_68_0.campaignType == var_0_7.CampaignType.MARCH then
		arg_68_0:marchResult(arg_68_1)
	elseif arg_68_0.campaignType == var_0_7.CampaignType.TREASURE then
		arg_68_0:treasureResult(arg_68_1)
	elseif arg_68_0.campaignType == var_0_7.CampaignType.PET then
		arg_68_0:petResult(arg_68_1)
	else
		arg_68_0:campaignResult(arg_68_1)
	end
end

function var_0_0.petResult(arg_69_0, arg_69_1)
	if arg_69_1 then
		return
	end

	local var_69_0 = {
		is_win = arg_69_0:getBattleStar() > 0,
		floor = var_0_7.tables.campaign:getFloor(arg_69_0.campaignID),
		floor_type = var_0_7.tables.campaign:getFloorType(arg_69_0.campaignID)
	}

	if var_69_0.floor_type == var_0_7.PetCampaignFloorType.SUPER and not var_69_0.is_win or arg_69_0.noResult then
		arg_69_0:finishBattle({}, {})

		return
	end

	var_0_7.ModelManager.get():loadModel(var_0_7.ModelType.PET_COMPAIGN):battleResult(function(arg_70_0, arg_70_1)
		if (arg_70_0 == var_0_7.error.OK or tonumber(arg_70_1.error_code or 0) == var_0_8.ctx.battleConst.errorIdFightExist) and not arg_69_1 then
			arg_69_0:runActionOnce(cc.CallFunc:create(function()
				arg_69_0:finishBattle(arg_70_1)
			end), false, nil, 2)
		end
	end, var_69_0)
end

function var_0_0.regionArenaResult(arg_72_0, arg_72_1)
	local function var_72_0()
		local var_73_0 = {}
		local var_73_1 = {}

		for iter_73_0, iter_73_1 in ipairs(var_0_8.ctx.battle.teamA) do
			local var_73_2 = {
				iter_73_1:getDamage(),
				iter_73_1:getKillCount()
			}

			var_73_0[tostring(iter_73_1.hero_:getTableID())] = var_73_2
		end

		var_73_1.report_hero_data = var_73_0
		var_73_1.battle_report = arg_72_0:writeReport()
		var_73_1.star = arg_72_0:getBattleStar()
		var_73_1.lib_mission_formations = arg_72_0.libraryFormations

		local var_73_3 = {
			battle_result = var_73_1,
			enemy_id = arg_72_0.enemyID_
		}

		arg_72_0.regionArena:fightResult(var_73_3, function(arg_74_0, arg_74_1)
			if arg_74_0 == var_0_7.error.OK then
				local var_74_0 = arg_74_1.arena_info

				arg_72_0.regionArena:setStar(var_74_0.star)
				var_0_7.EventDispatcher.get():dispatchEvent({
					name = var_0_7.event.BATTLE_REPORT_CREATE,
					response = arg_74_1
				})
			end
		end)
	end

	if arg_72_1 then
		return
	end

	if arg_72_0.isRegionArenaTest == 0 then
		var_72_0()
	else
		var_0_7.EventDispatcher.get():dispatchEvent({
			name = var_0_7.event.BATTLE_REPORT_CREATE
		})
	end
end

function var_0_0.updateLibraryFormations(arg_75_0)
	local var_75_0 = arg_75_0:getKilledBySameHeroFormationStr(var_0_8.ctx.battle.teamB)
	local var_75_1 = arg_75_0:getKilledBySameHeroFormationStr(var_0_8.ctx.battle.teamA)

	if var_75_0 ~= "" then
		if not arg_75_0.libraryFormations[tostring(arg_75_0.selfPlayer.playerID)] then
			arg_75_0.libraryFormations[tostring(arg_75_0.selfPlayer.playerID)] = var_75_0
		else
			arg_75_0.libraryFormations[tostring(arg_75_0.selfPlayer.playerID)] = arg_75_0.libraryFormations[tostring(arg_75_0.selfPlayer.playerID)] .. var_75_0
		end
	end

	if var_75_1 ~= "" then
		if not arg_75_0.libraryFormations[tostring(arg_75_0.enemyID_)] then
			arg_75_0.libraryFormations[tostring(arg_75_0.enemyID_)] = var_75_1
		else
			arg_75_0.libraryFormations[tostring(arg_75_0.enemyID_)] = arg_75_0.libraryFormations[tostring(arg_75_0.enemyID_)] .. var_75_1
		end
	end
end

function var_0_0.getKilledBySameHeroFormationStr(arg_76_0, arg_76_1)
	local var_76_0 = ""

	for iter_76_0, iter_76_1 in ipairs(arg_76_1) do
		if iter_76_1.killer_ then
			local var_76_1 = iter_76_1.killer_:getTableID()

			if var_0_7.tables.hero:beforeAwaken(var_76_1) > 0 then
				var_76_1 = var_0_7.tables.hero:beforeAwaken(var_76_1)
			end

			local var_76_2 = iter_76_1:getTableID()

			if var_0_7.tables.hero:beforeAwaken(var_76_2) > 0 then
				var_76_2 = var_0_7.tables.hero:beforeAwaken(var_76_2)
			end

			if var_76_1 == var_76_2 and iter_76_1.killer_.hero_ then
				var_76_0 = var_76_0 .. string.format("%d", iter_76_1.killer_.hero_:getHeroID())

				if iter_76_0 < #arg_76_1 then
					var_76_0 = var_76_0 .. "|"
				end
			end
		end
	end

	return var_76_0
end

function var_0_0.playStory(arg_77_0)
	local var_77_0 = arg_77_0:getBattleStar()

	if var_77_0 <= 0 and arg_77_0.stories[2] and arg_77_0.stories[2] > 0 then
		local var_77_1 = var_0_7.WindowManager.get():openWindow("story", {
			story_state = 2,
			story_id = arg_77_0.stories[2],
			battle_id = arg_77_0.battleID
		})

		cc.EventProxy.new(var_77_1, var_77_1):addEventListener(var_0_7.event.STORY_COMPLETE, function(arg_78_0)
			if arg_78_0.state >= 2 then
				if var_0_7.StoryData.get():getGuideID() <= var_0_7.GuideStoryType.GUIDE_END then
					arg_77_0.selfPlayer:sendOperationLog(var_0_7.StatID.ID_DIALOG7)
				end

				arg_77_0:sendBattleResult()
			end
		end)
	elseif var_77_0 > 0 and arg_77_0.stories[3] and arg_77_0.stories[3] > 0 then
		local var_77_2 = var_0_7.WindowManager.get():openWindow("story", {
			story_state = 3,
			story_id = arg_77_0.stories[3],
			battle_id = arg_77_0.battleID
		})

		cc.EventProxy.new(var_77_2, var_77_2):addEventListener(var_0_7.event.STORY_COMPLETE, function(arg_79_0)
			if arg_79_0.state >= 2 then
				if var_0_7.StoryData.get():getGuideID() <= var_0_7.GuideStoryType.GUIDE_END then
					arg_77_0.selfPlayer:sendOperationLog(var_0_7.StatID.ID_DIALOG7)
				end

				arg_77_0:sendBattleResult()
			end
		end)
	else
		arg_77_0:sendBattleResult()
	end
end

function var_0_0.finishSuperArena(arg_80_0, arg_80_1)
	var_0_7.WindowManager.get():closeWindow(var_0_7.WindowName.battleTopWnd)
	var_0_7.WindowManager.get():closeWindow(var_0_7.WindowName.battleBottomWnd)

	local var_80_0 = arg_80_0:getBattleStar()
	local var_80_1 = {}
	local var_80_2 = {}

	for iter_80_0, iter_80_1 in ipairs(var_0_8.ctx.battle.teamA) do
		if iter_80_1:getSummonType() == var_0_7.summonMonsterType.None then
			table.insert(var_80_1, iter_80_1)
		end
	end

	for iter_80_2, iter_80_3 in ipairs(var_0_8.ctx.battle.teamB) do
		if iter_80_3:getSummonType() == var_0_7.summonMonsterType.None then
			table.insert(var_80_2, iter_80_3)
		end
	end

	arg_80_0:clearFormation(true)

	var_0_8.ctx.battle.teamA = {}
	var_0_8.ctx.battle.teamB = {}

	if var_80_0 > 0 then
		local var_80_3 = {
			mana = 0,
			star = var_80_0,
			campaignID = arg_80_0.campaignID,
			campaignType = arg_80_0.campaignType,
			fighterA = var_80_1,
			fighterB = var_80_2,
			items = {},
			heroExp = {}
		}

		var_0_7.WindowManager.get():openWindow(var_0_7.WindowName.battleWinWnd, var_80_3, function(arg_81_0)
			if arg_81_0 == nil then
				return
			end

			arg_80_0.battleEndWindow_ = arg_81_0

			cc.EventProxy.new(arg_80_0.battleEndWindow_, arg_80_0.battleEndWindow_):addEventListener(var_0_7.event.BATTLE_END_BACK_TO_MAIN, function(arg_82_0)
				arg_80_0:closeBattleEndWindow(function()
					if arg_80_1 then
						arg_80_0.peakArena:setCurrentBattleRound(arg_80_0.peakArena:getCurrentBattleRound() + 1)

						arg_80_0.herosA = arg_80_0.heroGroupA["team" .. arg_80_0.peakArena:getCurrentBattleRound()]
						arg_80_0.petsA = arg_80_0.heroGroupA["pet" .. arg_80_0.peakArena:getCurrentBattleRound()]
						arg_80_0.petsB = arg_80_0.heroGroupB["pet" .. arg_80_0.peakArena:getCurrentBattleRound()]

						arg_80_0:setupWindows()
						arg_80_0:setupButtons()
						arg_80_0:setupMusic()
						arg_80_0:init()
					else
						var_0_7.WindowManager.get():closeAllWindows()
						cc.Director:getInstance():popScene()
					end
				end)
			end)
		end)
	else
		var_0_7.WindowManager.get():openWindow(var_0_7.WindowName.battleLoseWnd, {
			star = var_80_0,
			campaignType = arg_80_0.campaignType,
			fighterA = var_80_1,
			fighterB = var_80_2,
			is_timeout = arg_80_0.timeOut_
		}, function(arg_84_0)
			if arg_84_0 == nil then
				return
			end

			arg_80_0.battleEndWindow_ = arg_84_0

			cc.EventProxy.new(arg_80_0.battleEndWindow_, arg_80_0.battleEndWindow_):addEventListener(var_0_7.event.BATTLE_END_BACK_TO_MAIN, function(arg_85_0)
				arg_80_0:closeBattleEndWindow(function()
					if arg_80_1 then
						arg_80_0.peakArena:setCurrentBattleRound(arg_80_0.peakArena:getCurrentBattleRound() + 1)

						arg_80_0.herosA = arg_80_0.heroGroupA["team" .. arg_80_0.peakArena:getCurrentBattleRound()]
						arg_80_0.petsA = arg_80_0.heroGroupA["pet" .. arg_80_0.peakArena:getCurrentBattleRound()]
						arg_80_0.petsB = arg_80_0.heroGroupB["pet" .. arg_80_0.peakArena:getCurrentBattleRound()]

						arg_80_0:setupWindows()
						arg_80_0:setupButtons()
						arg_80_0:setupMusic()
						arg_80_0:init()
					else
						var_0_7.WindowManager.get():closeAllWindows()
						cc.Director:getInstance():popScene()
					end
				end)
			end)
		end)
	end
end

function var_0_0.finishBattle(arg_87_0, arg_87_1)
	var_0_7.WindowManager.get():closeWindow(var_0_7.WindowName.battleTopWnd)
	var_0_7.WindowManager.get():closeWindow(var_0_7.WindowName.battleBottomWnd)
	arg_87_0:clearFormation(true)

	if arg_87_0:getBattleStar() > 0 then
		local var_87_0 = {
			star = arg_87_0:getBattleStar(),
			campaignID = arg_87_0.campaignID,
			campaignType = arg_87_0.campaignType,
			fighterA = var_0_8.ctx.battle.teamA,
			fighterB = var_0_8.ctx.battle.teamB,
			mana = var_0_8.ctx.battle.dropManaCount,
			items = arg_87_0.dropItems,
			heroExp = arg_87_1 and arg_87_1.exps or {}
		}

		var_0_7.WindowManager.get():openWindow(var_0_7.WindowName.battleWinWnd, var_87_0, function(arg_88_0)
			if arg_88_0 == nil then
				return
			end

			arg_87_0.battleEndWindow_ = arg_88_0

			cc.EventProxy.new(arg_87_0.battleEndWindow_, arg_87_0.battleEndWindow_):addEventListener(var_0_7.event.BATTLE_END_BACK_TO_MAIN, function(arg_89_0)
				arg_87_0:closeBattleEndWindow(function()
					var_0_7.WindowManager.get():closeAllWindows()
					cc.Director:getInstance():popScene()
				end)
			end)
		end)
	else
		var_0_7.WindowManager.get():openWindow(var_0_7.WindowName.battleLoseWnd, {
			star = arg_87_0:getBattleStar(),
			campaignType = arg_87_0.campaignType,
			fighterA = var_0_8.ctx.battle.teamA,
			fighterB = var_0_8.ctx.battle.teamB,
			is_timeout = arg_87_0.timeOut_
		}, function(arg_91_0)
			if arg_91_0 == nil then
				return
			end

			arg_87_0.battleEndWindow_ = arg_91_0

			cc.EventProxy.new(arg_87_0.battleEndWindow_, arg_87_0.battleEndWindow_):addEventListener(var_0_7.event.BATTLE_END_BACK_TO_MAIN, function(arg_92_0)
				arg_87_0:closeBattleEndWindow(function()
					var_0_7.WindowManager.get():closeAllWindows()
					cc.Director:getInstance():popScene()
				end)
			end)
		end)
	end
end

function var_0_0.setupWindows(arg_94_0)
	local var_94_0 = {
		heros = arg_94_0.herosA
	}

	arg_94_0.battleBottomWindow = var_0_7.WindowManager.get():openWindow(var_0_7.WindowName.battleBottomWnd, var_94_0)
	arg_94_0.battleTopWindow = var_0_7.WindowManager.get():openWindow(var_0_7.WindowName.battleTopWnd)

	if arg_94_0.battleTopWindow ~= nil then
		if arg_94_0:isPausable() then
			cc.EventProxy.new(arg_94_0.battleTopWindow, arg_94_0.battleTopWindow):addEventListener(var_0_7.event.EXIT_BATTLE, function(arg_95_0)
				arg_94_0:pauseBattle()
				arg_94_0:sendBattleResult(true)
				var_0_7.WindowManager.get():closeWindow(var_0_7.WindowName.battleBottomWnd)
				var_0_7.WindowManager.get():closeWindow(var_0_7.WindowName.battleTopWnd, function()
					cc.Director:getInstance():popToRootScene()
				end)
			end):addEventListener(var_0_7.event.BATTLE_PAUSED, function()
				arg_94_0:pauseBattle()
			end):addEventListener(var_0_7.event.BATTLE_RESUMED, function()
				if arg_94_0.handler == nil and arg_94_0.isBattleEnded_ ~= true then
					arg_94_0:startBattle()
				end
			end)
		else
			arg_94_0.battleTopWindow:hidePauseButton()
		end
	end

	if arg_94_0.battleBottomWindow then
		local var_94_1 = arg_94_0.battleBottomWindow:nextBattleBtn()

		var_94_1:setTouchEnabled(true)
		var_94_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_99_0)
			if arg_99_0.name == "ended" then
				arg_94_0:clickNextBattle()
			end

			return true
		end)
	end
end

function var_0_0.autoBtnClick(arg_100_0)
	if var_0_8.ctx.battle.autoA then
		arg_100_0.autoBtn_:setBrightStyle(ccui.BrightStyle.normal)
	else
		arg_100_0.autoBtn_:setBrightStyle(ccui.BrightStyle.highlight)
	end

	var_0_8.ctx.battle.autoA = not var_0_8.ctx.battle.autoA
end

function var_0_0.setupButtons(arg_101_0)
	arg_101_0.autoBtn_ = arg_101_0.battleBottomWindow:getAutoBtn()

	if arg_101_0.battleType == var_0_7.BattleType.ReplayReport then
		arg_101_0.autoBtn_:setBrightStyle(ccui.BrightStyle.highlight)
		arg_101_0.autoBtn_:addTouchEventListener(function(arg_102_0, arg_102_1)
			if arg_102_1 == ccui.TouchEventType.ended then
				arg_101_0.autoBtn_:setBrightStyle(ccui.BrightStyle.highlight)

				local var_102_0 = var_0_3:translation("AUTO_BATTLE_TIP3")

				var_0_7.WindowManager.get():openWindow("toast", {
					message = var_102_0
				})
			end
		end)
	elseif arg_101_0.campaignType == var_0_7.CampaignType.ARENA or arg_101_0.campaignType == var_0_7.CampaignType.SUPER_ARENA or arg_101_0.campaignType == var_0_7.CampaignType.REGION_ARENA or arg_101_0.campaignType == var_0_7.CampaignType.GUILD_ARENA then
		arg_101_0.autoBtn_:setBrightStyle(ccui.BrightStyle.highlight)
		arg_101_0.autoBtn_:addTouchEventListener(function(arg_103_0, arg_103_1)
			if arg_103_1 == ccui.TouchEventType.ended then
				arg_101_0.autoBtn_:setBrightStyle(ccui.BrightStyle.highlight)

				local var_103_0 = var_0_3:translation("AUTO_BATTLE_TIP2")

				var_0_7.WindowManager.get():openWindow("toast", {
					message = var_103_0
				})
			end
		end)
	elseif arg_101_0.star_ < 3 and (arg_101_0.campaignType == var_0_7.CampaignType.NORMAL or arg_101_0.campaignType == var_0_7.CampaignType.SUPER) then
		arg_101_0.autoBtn_:setBright(false)
		arg_101_0.autoBtn_:addTouchEventListener(function(arg_104_0, arg_104_1)
			if arg_104_1 == ccui.TouchEventType.ended then
				local var_104_0 = var_0_3:translation("AUTO_BATTLE_TIP1")

				var_0_7.WindowManager.get():openWindow("toast", {
					message = var_104_0
				})
			end
		end)
	else
		arg_101_0.battleBottomWindow:getLockIcon():hide()
		arg_101_0.autoBtn_:addTouchEventListener(function(arg_105_0, arg_105_1)
			arg_101_0:buttonHandler(handler(arg_101_0, arg_101_0.autoBtnClick), arg_105_0, arg_105_1)
		end)
	end
end

function var_0_0.closeBattleEndWindow(arg_106_0, arg_106_1)
	arg_106_0.battleEndWindow_ = nil

	if var_0_7.WindowManager.get():isWindowOpen(var_0_7.WindowName.battleLoseWnd) then
		var_0_7.WindowManager.get():closeWindow(var_0_7.WindowName.battleLoseWnd, arg_106_1)
	else
		var_0_7.WindowManager.get():closeWindow(var_0_7.WindowName.battleWinWnd, arg_106_1)
	end

	var_0_7.EventDispatcher.get():dispatchEvent({
		name = var_0_7.event.UPDATE_STONE_EQUIP_CAMPAIGN,
		params = {}
	})
end

function var_0_0.isPausable(arg_107_0)
	if arg_107_0.battleType == var_0_7.BattleType.ReplayReport then
		return true
	end

	if arg_107_0.campaignType == var_0_7.CampaignType.SUPER_ARENA or arg_107_0.campaignType == var_0_7.CampaignType.ARENA or arg_107_0.campaignType == var_0_7.CampaignType.TREASURE or arg_107_0.campaignType == var_0_7.CampaignType.REGION_ARENA or arg_107_0.campaignType == var_0_7.CampaignType.GUILD_ARENA or arg_107_0.campaignType == var_0_7.CampaignType.LVBU_FESTIVAL then
		return false
	end

	return true
end

function var_0_0.isArena(arg_108_0)
	return arg_108_0.campaignType == var_0_7.CampaignType.ARENA or arg_108_0.campaignType == var_0_7.CampaignType.SUPER_ARENA or arg_108_0.campaignType == var_0_7.CampaignType.REGION_ARENA or arg_108_0.campaignType == var_0_7.CampaignType.GUILD_ARENA
end

function var_0_0.isAutoA(arg_109_0)
	if arg_109_0.battleType == var_0_7.BattleType.ReplayReport or arg_109_0.battleType == var_0_7.BattleType.CreateReport then
		return true
	end

	if arg_109_0.campaignType == var_0_7.CampaignType.SUPER_ARENA or arg_109_0.campaignType == var_0_7.CampaignType.ARENA or arg_109_0.campaignType == var_0_7.CampaignType.REGION_ARENA or arg_109_0.campaignType == var_0_7.CampaignType.GUILD_ARENA or arg_109_0.campaignType == var_0_7.CampaignType.LVBU_FESTIVAL then
		return true
	end

	return false
end

function var_0_0.setupMusic(arg_110_0)
	audio.stopMusic()
	audio.stopAllSounds()

	local var_110_0 = var_0_7.tables.battle:sounds(arg_110_0.battleID)

	if var_110_0 and var_110_0 ~= "" then
		var_110_0 = var_0_7.tables.sound:getSound("battle_bg_music_1")
	end

	audio.preloadMusic(var_110_0)
	audio.playMusic(var_110_0, true)
end

function var_0_0.setupBackground_(arg_111_0)
	local var_111_0 = "images/maps/map_images/"

	if arg_111_0.background_ then
		arg_111_0.background_:removeSelf()

		arg_111_0.background_ = nil
	end

	local var_111_1

	if type(arg_111_0.mapID_) == "number" then
		var_111_1 = var_111_0 .. tostring(arg_111_0.mapID_) .. ".png"
	elseif type(arg_111_0.mapID_) == "string" then
		var_111_1 = arg_111_0.mapID_
	elseif next(arg_111_0.mapID_) and arg_111_0.group_ <= #arg_111_0.mapID_ then
		var_111_1 = var_111_0 .. tostring(arg_111_0.mapID_[arg_111_0.group_]) .. ".png"
	elseif next(arg_111_0.mapID_) then
		var_111_1 = var_111_0 .. tostring(arg_111_0.mapID_[#arg_111_0.mapID_]) .. ".png"
	end

	arg_111_0.background_ = var_0_7.ColoredSprite.new(var_111_1):align(display.LEFT_BOTTOM, 0, 0):addTo(arg_111_0, -1)

	arg_111_0.background_:setOpacity(255)
	arg_111_0.background_:setScaleX(arg_111_0:getWidth() / arg_111_0.background_:getWidth())
	arg_111_0.background_:setScaleY(arg_111_0:getHeight() / arg_111_0.background_:getHeight())
end

function var_0_0.buttonHandler(arg_112_0, arg_112_1, arg_112_2, arg_112_3)
	if arg_112_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_112_2)
		arg_112_2:setScale(1)
		var_0_7.playButtonSound()

		if arg_112_1 then
			arg_112_1(arg_112_2, arg_112_3)
		end
	elseif arg_112_3 == ccui.TouchEventType.began then
		local var_112_0 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_112_1 = cc.RepeatForever:create(var_112_0)

		arg_112_2:runAction(var_112_1)

		return true
	elseif arg_112_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_112_2)
		arg_112_2:setScale(1)
	end
end

function var_0_0.setTotalHurt(arg_113_0)
	for iter_113_0, iter_113_1 in ipairs(var_0_8.ctx.battle.teamA) do
		if not iter_113_1:isDeath() and iter_113_1:getSummonType() == var_0_7.summonMonsterType.None then
			var_0_8.ctx.battle.allFighterHurt = var_0_8.ctx.battle.allFighterHurt + iter_113_1:getHurtHp()

			if not iter_113_1:getParalysis() then
				iter_113_1:setHurtHp(0)
			end
		end
	end

	for iter_113_2, iter_113_3 in ipairs(var_0_8.ctx.battle.teamB) do
		if not iter_113_3:isDeath() and iter_113_3:getSummonType() == var_0_7.summonMonsterType.None then
			var_0_8.ctx.battle.allFighterHurt = var_0_8.ctx.battle.allFighterHurt + iter_113_3:getHurtHp()

			if not iter_113_3:getParalysis() then
				iter_113_3:setHurtHp(0)
			end
		end
	end
end

return var_0_0
