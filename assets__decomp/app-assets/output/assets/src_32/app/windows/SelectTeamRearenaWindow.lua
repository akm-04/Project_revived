local var_0_0 = class("SelectTeamRearenaWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = import("app.model.Item")
local var_0_5 = xyd.tables.translation
local var_0_6 = xyd.tables.hero
local var_0_7 = require("framework.scheduler")
local var_0_8 = 30
local var_0_9 = 30
local var_0_10 = 7
local var_0_11 = 6
local var_0_12 = 6
local var_0_13 = 30
local var_0_14 = "skeletons/ui_effect/effect_kfjjc/effect_kfjjc1"
local var_0_15 = 98
local var_0_16 = {
	RENT_PET = 2,
	SELF_PET = 1
}
local var_0_17 = {
	RENT_HERO = 2,
	SELF_HERO = 1,
	SELF_PET = 3
}
local var_0_18 = {
	YES = 2,
	NO = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.type = arg_1_2.type or xyd.SelectTeamType.REGION_ARENA
	arg_1_0.campaignType = arg_1_2.campaignType or xyd.CampaignType.REGION_ARENA
	arg_1_0.firstSelect = arg_1_2.firstSelect
	arg_1_0.mode = arg_1_2.mode
	arg_1_0.enemyID = arg_1_2.enemyID
	arg_1_0.isBackendBattle = arg_1_2.isBackendBattle
	arg_1_0.petTeam_ = {}
	arg_1_0.totalHero_ = {}
	arg_1_0.selectedHeroClass_ = {}
	arg_1_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_1_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.FILTER] = {}
	arg_1_0.totalHero_[xyd.DistanceType.SEARCH] = {}

	for iter_1_0, iter_1_1 in pairs(arg_1_0.totalHero_) do
		iter_1_1[var_0_18.NO] = {}
		iter_1_1[var_0_18.YES] = {}
	end

	arg_1_0.searchTxt = ""
	arg_1_0.totalIDs_ = {}
	arg_1_0.petSelect_ = {}
	arg_1_0.choosingPet = false
	arg_1_0.team_ = {}
	arg_1_0.select_ = {}
	arg_1_0.preSelect_ = arg_1_2.selected or {}
	arg_1_0.tmpTotalPets = {}
	arg_1_0.enemyHeroes_ = arg_1_2.enemyHeroes

	if arg_1_2.pet_id ~= 0 then
		arg_1_0.enemyPet = var_0_2.new()

		arg_1_0.enemyPet:initUnCollected(arg_1_2.pet_info.table_id, nil, {
			star = arg_1_2.pet_info.pet_star
		})
	end

	arg_1_0.fighterInfo = arg_1_2.fighterInfo
	arg_1_0.battleBegan = false
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
	arg_1_0.forceHeros = {}
	arg_1_0.enemySelectState = {
		0,
		0,
		0,
		0,
		0
	}
	arg_1_0.selfSelectState = {
		0,
		0,
		0,
		0,
		0
	}
	arg_1_0.enemyLocks = {}
	arg_1_0.selfLocks = {}
	arg_1_0.collocationType_ = var_0_18.NO
end

function var_0_0.initLock(arg_2_0)
	for iter_2_0 = 1, var_0_10 do
		table.insert(arg_2_0.enemyLocks, arg_2_0:nodeByName("select_lock_enemy" .. iter_2_0))
		table.insert(arg_2_0.selfLocks, arg_2_0:nodeByName("select_lock_self" .. iter_2_0))
	end
end

function var_0_0.initLabel(arg_3_0)
	arg_3_0:nodeByName("count_down_2"):setString("")
	arg_3_0:nodeByName("count_down_1"):setString("")
	arg_3_0:nodeByName("text_all"):setString(var_0_5:translation("TUJIAN_BUTTON_TEXT1"))
	arg_3_0:nodeByName("text_qianpai"):setString(var_0_5:translation("TUJIAN_BUTTON_TEXT2"))
	arg_3_0:nodeByName("text_zhongpai"):setString(var_0_5:translation("TUJIAN_BUTTON_TEXT3"))
	arg_3_0:nodeByName("text_houpai"):setString(var_0_5:translation("TUJIAN_BUTTON_TEXT4"))
	arg_3_0:nodeByName("text_zhandui"):setString(var_0_5:translation("SELECT_TEAM_REARENA_TEXT_1"))
	arg_3_0:nodeByName("text_pet"):setString(var_0_5:translation("SELECT_TEAM_REARENA_TEXT_2"))
	arg_3_0:nodeByName("text_enemy"):setString(var_0_5:translation("REGION_ARENA_TEXT_32"))
	arg_3_0:nodeByName("text_filter"):setString(var_0_5:translation("FILTER_TEXT"))
end

function var_0_0.initWarnEffect(arg_4_0)
	local var_4_0 = var_0_14 .. ".json"
	local var_4_1 = var_0_14 .. ".atlas"

	arg_4_0.warnEffect = var_0_3.new(var_4_0, var_4_1, 1)

	arg_4_0.warnEffect:addTo(arg_4_0)
	arg_4_0.warnEffect:setPosition(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2)
	arg_4_0.warnEffect:setVisible(false)
	arg_4_0.warnEffect:play(nil, true)
end

function var_0_0.willOpen(arg_5_0, arg_5_1)
	arg_5_0:initLock()

	arg_5_0.enemySelect_ = {}
	arg_5_0.selfProgress = 0
	arg_5_0.enemyProgress = 0
	arg_5_0.selfOldProgress = 0
	arg_5_0.enemyOldProgress = 0
	arg_5_0.heroCells_ = {}
	arg_5_0.heroBottomCells_ = {}
	arg_5_0.enemyHerosAvatars = {}
	arg_5_0.enemyGuildName = arg_5_1.enemyGuildName
	arg_5_0.enemyName = arg_5_1.enemyName
	arg_5_0.enemyServerName = arg_5_1.enemyServerName
	arg_5_0.enemyAvatarID = arg_5_1.enemyAvatarID
	arg_5_0.enemyAvatarFrameID = arg_5_1.enemyAvatarFrameID
	arg_5_0.selfRegionName = arg_5_1.selfRegionName
	arg_5_0.enemyRegion = arg_5_1.enemyRegion
	arg_5_0.selectState = arg_5_0.firstSelect
	arg_5_0.countDown = var_0_13

	arg_5_0:initWarnEffect()
	arg_5_0:selectStateMonitor()
	arg_5_0:initLabel()

	arg_5_0.battleBegan = false
	arg_5_0.awards = arg_5_0.regionArena.awards

	local var_5_0 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfPlayer.heros_) do
		local var_5_1 = var_0_1.new()

		var_5_1:populate(iter_5_1:toParams())
		table.insert(var_5_0, var_5_1)
	end

	local var_5_2 = {}

	for iter_5_2, iter_5_3 in ipairs(arg_5_0.selfPlayer.collectedPets) do
		local var_5_3 = var_0_2.new()

		var_5_3:populate(iter_5_3:toParams())
		table.insert(var_5_2, var_5_3)
	end

	arg_5_0:initOtherHero(var_5_0, arg_5_0.awards)
	xyd.formatRegionArenaHeros(var_5_0)
	xyd.formatRegionArenaHeros(arg_5_0.enemyHeroes_)
	xyd.formatRegionArenaPets(var_5_2)

	if arg_5_0.enemyPet then
		xyd.formatRegionArenaPets({
			arg_5_0.enemyPet
		})
	end

	arg_5_0.selectEnemyHeros_ = {}

	for iter_5_4, iter_5_5 in ipairs(arg_5_0.enemyHeroes_) do
		local var_5_4 = var_0_1.new()

		var_5_4:populate(iter_5_5:toParams())
		table.insert(arg_5_0.selectEnemyHeros_, var_5_4)
	end

	arg_5_0:initHeros(var_5_0)
	arg_5_0:initPets(var_5_2 or {}, var_0_16.SELF_PET)

	arg_5_0.leftMenuType_ = var_0_17.SELF_HERO
	arg_5_0.selectedHeroClass_[arg_5_0.leftMenuType_] = xyd.DistanceType.ALL

	arg_5_0:layout()
end

function var_0_0.formatRegionArenaPets(arg_6_0, arg_6_1)
	for iter_6_0, iter_6_1 in pairs(arg_6_1) do
		local var_6_0 = {}
		local var_6_1 = {}

		if iter_6_1:isHaveAwakenItem() and not iter_6_1:isAwaken() then
			var_6_0 = {
				90,
				90,
				70,
				50,
				0
			}
			var_6_1 = {
				1,
				1,
				1
			}
		elseif iter_6_1:isAwaken() then
			var_6_0 = {
				90,
				90,
				70,
				50,
				30
			}
			var_6_1 = {
				1,
				1,
				1
			}
		else
			var_6_0 = {
				90,
				90,
				70,
				50,
				0
			}
			var_6_1 = {
				0,
				1,
				1
			}
		end

		arg_6_0:renewPetInfo(iter_6_1, var_6_0, var_6_1)
	end
end

function var_0_0.renewHeroInfo(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4)
	local var_7_0 = xyd.tables.misc.regionHeroColor

	arg_7_1.level_, arg_7_1.color_ = xyd.tables.misc.regionHeroLevel, var_7_0
	arg_7_1.skillLev_ = {}
	arg_7_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_7_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_7_1.color_ >= xyd.EquipQuality.GREEN then
		arg_7_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_7_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_7_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_7_1.color_ >= xyd.EquipQuality.BLUE then
		arg_7_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_7_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_7_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_7_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_7_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_7_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_7_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_7_1:isAwaken() then
		arg_7_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_7_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_7_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	arg_7_1.equips_ = {}

	for iter_7_0 = 1, var_0_12 do
		table.insert(arg_7_1.equips_, tonumber(arg_7_4[iter_7_0]))
	end

	arg_7_1.fumo_ = {}

	for iter_7_1 = 1, var_0_12 do
		table.insert(arg_7_1.fumo_, tonumber(arg_7_3[iter_7_1]))
	end

	arg_7_1.fumoLev_ = {}

	for iter_7_2 = 1, var_0_12 do
		local var_7_1 = arg_7_1:getEquipByIndex(iter_7_2)

		table.insert(arg_7_1.fumoLev_, tonumber(var_7_1:getMaxFumoStar()))
	end
end

function var_0_0.renewSuperHeroInfo(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)
	local var_8_0 = 1
	local var_8_1 = 100

	if not arg_8_0.isfriend and arg_8_1:isCanAwaken() and not arg_8_1:isAwaken() then
		arg_8_1:setTableID(arg_8_1:afterAwakenID())
	end

	arg_8_1.color_ = var_8_0
	arg_8_1.level_ = var_8_1
	arg_8_1.skillLev_ = {}
	arg_8_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_8_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]
	arg_8_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_8_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	arg_8_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_8_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	arg_8_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_8_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	arg_8_1.equips_ = {}

	for iter_8_0 = 1, var_0_12 do
		table.insert(arg_8_1.equips_, tonumber(arg_8_4[iter_8_0]))
	end

	arg_8_1.fumo_ = {}

	for iter_8_1 = 1, var_0_12 do
		table.insert(arg_8_1.fumo_, tonumber(arg_8_3[iter_8_1]))
	end

	arg_8_1.fumoLev_ = {}

	for iter_8_2 = 1, var_0_12 do
		local var_8_2 = arg_8_1:getEquipByIndex(iter_8_2)

		table.insert(arg_8_1.fumoLev_, tonumber(var_8_2:getMaxFumoStar()))
	end
end

function var_0_0.renewPetInfo(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = xyd.tables.misc.regionHeroColor

	arg_9_1.level_, arg_9_1.color_ = xyd.tables.misc.regionHeroLevel, var_9_0
	arg_9_1.skillLev_ = {}
	arg_9_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_9_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_9_1.color_ >= xyd.EquipQuality.GREEN then
		arg_9_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_9_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_9_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_9_1.color_ >= xyd.EquipQuality.BLUE then
		arg_9_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_9_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_9_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_9_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_9_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_9_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_9_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_9_1:isAwaken() then
		arg_9_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_9_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_9_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	arg_9_1.equips_ = {}

	for iter_9_0 = 1, var_0_12 do
		table.insert(arg_9_1.equips_, tonumber(arg_9_3[iter_9_0]))
	end
end

function var_0_0.controllLock(arg_10_0, arg_10_1)
	if arg_10_1 == 0 then
		for iter_10_0 = 1, arg_10_0.selfProgress do
			arg_10_0.selfLocks[iter_10_0]:setVisible(false)
		end
	else
		for iter_10_1 = 1, arg_10_0.enemyProgress do
			arg_10_0.enemyLocks[iter_10_1]:setVisible(false)
		end
	end
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	arg_11_0.super.didOpen(arg_11_0, arg_11_1)
	arg_11_0:refreshSelectedHeroClass()
	arg_11_0:getBattleBtn()
	arg_11_0:initComingSelect()
	arg_11_0:nodeByName("close"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playTabButtonSound()
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_5:translation("REGION_ARENA_TIP19"), function()
				if arg_11_0.mode == xyd.RegionArenaMode.ARENA then
					local var_13_0 = {
						enemy_id = arg_11_0.enemyID
					}

					xyd.Backend.get():request(xyd.mid.REARENA_STOP_FIGHT, var_13_0, function(arg_14_0, arg_14_1)
						if arg_14_0 == xyd.error.OK then
							xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA):setStar(arg_14_1.star)

							local var_14_0 = xyd.WindowManager.get():getWindow("region_arena")

							if var_14_0 then
								var_14_0:updateLevelPanel()
							end
						end
					end)
				end

				local var_13_1 = {
					fighterA = {},
					fighterB = {}
				}

				var_13_1.isTimeOut = false
				var_13_1.campaignType = xyd.CampaignType.REGION_ARENA

				xyd.WindowManager.get():openWindow("battle_lose", var_13_1, function(arg_15_0)
					if arg_15_0 == nil then
						return
					end

					arg_11_0.battleEndWindow_ = arg_15_0

					cc.EventProxy.new(arg_11_0.battleEndWindow_, arg_11_0.battleEndWindow_):addEventListener(xyd.event.BATTLE_END_BACK_TO_MAIN, function(arg_16_0)
						xyd.WindowManager.get():closeWindow("battle_lose")
					end)
				end)
				xyd.WindowManager.get():closeWindow(arg_11_0.name)
			end, nil, nil, arg_11_0.colorMode)
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_11_0):addEventListener(xyd.event.UPDATE_FILTER_HEROS, handler(arg_11_0, arg_11_0.updateList))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_11_0):addEventListener(xyd.event.HERO_SEARCH, handler(arg_11_0, arg_11_0.updateListBySearchTxt))
end

function var_0_0.updateList(arg_17_0, ...)
	arg_17_0.searchTxt = ""
	arg_17_0.selectedHeroClass_[arg_17_0.leftMenuType_] = xyd.DistanceType.FILTER

	arg_17_0:updateFilterHeros()
	arg_17_0:refreshSelectedHeroClass()
end

function var_0_0.updateListBySearchTxt(arg_18_0, arg_18_1)
	arg_18_0.searchTxt = arg_18_1.heroName
	arg_18_0.selectedHeroClass_[arg_18_0.leftMenuType_] = xyd.DistanceType.SEARCH

	arg_18_0:updateSearchHeros()
	arg_18_0:refreshSelectedHeroClass()
end

function var_0_0.willClose(arg_19_0)
	if arg_19_0.handle then
		var_0_7.unscheduleGlobal(arg_19_0.handle)
	end

	if xyd.WindowManager.get():getWindow("finding_enemy") then
		xyd.WindowManager.get():closeWindow("finding_enemy")
	end
end

function var_0_0.sortTables(arg_20_0, arg_20_1)
	table.sort(arg_20_1, function(arg_21_0, arg_21_1)
		if arg_21_0.region_arena_times ~= arg_21_1.region_arena_times then
			return arg_21_0.region_arena_times > arg_21_1.region_arena_times
		end

		return xyd.heroNormalSort(arg_21_0, arg_21_1) or false
	end)
end

function var_0_0.sortHerosByForce(arg_22_0, arg_22_1)
	table.sort(arg_22_1, function(arg_23_0, arg_23_1)
		if arg_23_0:getZhandouli() ~= arg_23_1:getZhandouli() then
			return arg_23_0:getZhandouli() > arg_23_1:getZhandouli()
		end
	end)
end

function var_0_0.exitScene(arg_24_0)
	arg_24_0:dispatchEvent({
		name = xyd.event.EXIT_BATTLE_PREPARE
	})
end

function var_0_0.layout(arg_25_0)
	arg_25_0:initMenu()
	arg_25_0:initLeftMenu()
	arg_25_0:nodeByName("text_bg"):setVisible(false)

	local var_25_0 = arg_25_0:nodeByName("list_layer_battle")
	local var_25_1 = var_25_0:getContentSize().width
	local var_25_2 = var_25_0:getContentSize().height

	arg_25_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_25_1, var_25_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_25_0)

	arg_25_0.heroList_:setDelegate(handler(arg_25_0, arg_25_0.delegate))
	arg_25_0:updateScore()
end

function var_0_0.delegate(arg_26_0, ...)
	if arg_26_0.leftMenuType_ == var_0_17.SELF_PET or arg_26_0.leftMenuType_ == var_0_17.RENT_HERO and arg_26_0.rentMenuType == RentMenuType.RENT_PET then
		return arg_26_0:petDelegate(...)
	end

	return arg_26_0:heroDelegate(...)
end

function var_0_0.petDelegate(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	if arg_27_0.leftMenuType_ == var_0_17.SELF_PET then
		var_0_11 = 5
	else
		var_0_11 = 4
	end

	local var_27_0 = math.ceil(#arg_27_0.totalPet_ / var_0_11)

	if cc.ui.UIListView.COUNT_TAG == arg_27_2 then
		return var_27_0
	elseif cc.ui.UIListView.CELL_TAG == arg_27_2 then
		local var_27_1
		local var_27_2
		local var_27_3
		local var_27_4 = arg_27_0.heroList_:dequeueItem()

		if not var_27_4 then
			var_27_4 = arg_27_0.heroList_:newItem()
		else
			var_27_4:removeAllChildren()
		end

		local var_27_5 = display.newNode()

		var_27_5:setTouchSwallowEnabled(false)

		for iter_27_0 = 1, var_0_11 do
			local var_27_6 = (arg_27_3 - 1) * var_0_11 + iter_27_0

			if var_27_6 > #arg_27_0.totalPet_ then
				break
			end

			var_27_3 = display.newNode()

			arg_27_0:initPetCell(var_27_3, var_27_6)

			local var_27_7 = var_27_3:getContentSize().width
			local var_27_8 = var_27_3:getContentSize().height
			local var_27_9 = (arg_27_0.heroList_.viewRect_.width - var_27_7 * var_0_11) / (var_0_11 + 1)

			var_27_3:align(display.CENTER, var_27_9 * iter_27_0 + (iter_27_0 - 1) * var_27_7 + var_27_7 / 2, var_27_8 / 2)
			var_27_5:addChild(var_27_3)
		end

		var_27_5:setContentSize(cc.size(arg_27_0.heroList_.viewRect_.width, var_27_3:getContentSize().height))
		var_27_4:setItemSize(arg_27_0.heroList_.viewRect_.width, var_27_3:getContentSize().height)
		var_27_4:addContent(var_27_5)

		return var_27_4
	end
end

function var_0_0.initPetCell(arg_28_0, arg_28_1, arg_28_2)
	local var_28_0 = arg_28_0.totalPet_[arg_28_2]

	arg_28_1:align(display.CENTER):size(146, 146)
	xyd.setPetAvatarNewUI(arg_28_1, var_28_0, 100)

	arg_28_1.type = var_0_16.SELF_PET
	arg_28_1.data = var_28_0

	arg_28_1:setTouchEnabled(true)
	arg_28_1:setTouchSwallowEnabled(false)
	arg_28_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_29_0)
		arg_28_0:buttonHandler(nil, arg_28_1, arg_29_0)

		if arg_29_0.name == "began" then
			arg_28_0.startClick_ = true
			arg_28_0.prevX_ = arg_29_0.x
			arg_28_0.prevY_ = arg_29_0.y
		elseif arg_29_0.name == "moved" then
			if math.abs(arg_29_0.y - arg_28_0.prevY_) > 5 or math.abs(arg_29_0.x - arg_28_0.prevX_) > 5 then
				arg_28_0.startClick_ = false
			end
		elseif arg_29_0.name == "ended" and arg_28_0.startClick_ then
			local var_29_0 = var_28_0.rent_need_mana

			if arg_28_0.isAwakeCampaign and arg_28_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.ALONE_KILL then
				local function var_29_1()
					arg_28_0:clickPetAvatar(arg_28_1)
				end

				local var_29_2 = {
					txt = TranslationTable:translation("AWAKE_SELECT_TEAM_TIP6"),
					rcallback = var_29_1,
					type = xyd.CommonAlertType.TWO_BTN,
					align = xyd.ui_align.CENTER
				}

				xyd.WindowManager.get():openWindow("common_alert", var_29_2)
			elseif var_29_0 and var_29_0 > arg_28_0.selfPlayer.mana and var_28_0.can_rent then
				local var_29_3 = TranslationTable:translation("MERCENARY_ERROR_TIP4")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_29_3
				})

				return
			else
				arg_28_0:clickPetAvatar(arg_28_1)
			end
		end

		return true
	end)

	for iter_28_0, iter_28_1 in ipairs(arg_28_0.petTeam_) do
		if var_28_0 == iter_28_1.data then
			arg_28_0.petTeam_[iter_28_0].iniCell_ = arg_28_1
			arg_28_1.teamNo_ = iter_28_0

			local var_28_1
			local var_28_2 = arg_28_1:getChildByName("layout")
			local var_28_3 = var_28_2:getChildByName("avatar_mask")
			local var_28_4 = var_28_2:getChildByName("chosen")

			var_28_3:setVisible(true)
			var_28_4:setVisible(true)

			break
		end
	end
end

function var_0_0.clickPetAvatar(arg_31_0, arg_31_1, arg_31_2)
	if arg_31_1.isAnimated_ or not arg_31_1.teamNo_ and #arg_31_0.petTeam_ > xyd.MAX_PET_NUMBER then
		return
	elseif arg_31_1.type == var_0_16.RENT_PET and arg_31_0.isSelectMerHero then
		local var_31_0 = TranslationTable:translation("MERCENARY_ERROR_TIP1")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_31_0
		})

		return
	elseif not arg_31_1.teamNo_ and #arg_31_0.petTeam_ == xyd.MAX_PET_NUMBER then
		local var_31_1 = arg_31_0.petTeam_[1]

		arg_31_0:clickPetBottomAvatarWithoutAnimation(var_31_1, function()
			arg_31_0:clickPetAvatar(arg_31_1, arg_31_2)
		end)

		return
	end

	local var_31_2
	local var_31_3 = arg_31_1:getChildByName("layout")
	local var_31_4 = var_31_3:getChildByName("avatar_mask")
	local var_31_5 = var_31_3:getChildByName("chosen")
	local var_31_6 = arg_31_1:convertToWorldSpace(cc.p(0, 0))
	local var_31_7 = var_31_6.x
	local var_31_8 = var_31_6.y

	arg_31_1.isAnimated_ = true

	if arg_31_1.teamNo_ then
		local var_31_9 = arg_31_0.petTeam_[arg_31_1.teamNo_]

		arg_31_0:moveFadeOutAction(var_31_7, var_31_8, var_31_9, function()
			arg_31_1.isAnimated_ = false
		end)
		var_31_4:setVisible(false)
		var_31_5:setVisible(false)

		for iter_31_0 = #arg_31_0.petTeam_, arg_31_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_31_0.petTeam_[iter_31_0])

			local var_31_10, var_31_11 = arg_31_0:nodeByName("avatar_pet" .. iter_31_0 - 1):getPosition()

			transition.moveTo(arg_31_0.petTeam_[iter_31_0], {
				time = 0.3,
				x = var_31_10,
				y = var_31_11
			})

			arg_31_0.petTeam_[iter_31_0].iniCell_.teamNo_ = iter_31_0 - 1
		end

		if arg_31_1.type == var_0_16.RENT_PET then
			arg_31_0.isSelectMerPet = false
			arg_31_0.selectMerPet = nil
		end

		table.remove(arg_31_0.petTeam_, arg_31_1.teamNo_)
		table.remove(arg_31_0.petSelect_, arg_31_1.teamNo_)

		arg_31_1.teamNo_ = nil
	elseif not arg_31_1.teamNo_ and #arg_31_0.petTeam_ < xyd.MAX_PET_NUMBER then
		local var_31_12 = arg_31_1.data

		if not arg_31_2 and var_0_6:chosenSound(var_31_12:getTableID()) ~= "" then
			xyd.AssetDownload.get():preloadCharacterSound({
				var_31_12:getTableID()
			}, function()
				return
			end, true)
			audio.playSound(var_0_6:chosenSound(var_31_12:getTableID()), false)
		end

		local var_31_13 = arg_31_0:initPetBottomCell(var_31_12)

		var_31_13.iniCell_ = arg_31_1

		var_31_13:pos(var_31_7, var_31_8)
		var_31_13:addTo(arg_31_0)
		var_31_13:setTouchEnabled(true)
		var_31_13:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_35_0)
			if arg_35_0.name == "ended" then
				arg_31_0:clickPetBottomAvatar(var_31_13)
			end

			return true
		end)

		if arg_31_1.type == var_0_16.RENT_PET then
			arg_31_0.isSelectMerPet = true
			arg_31_0.selectMerPet = var_31_12
		end

		arg_31_1.teamNo_ = arg_31_0:getPetTeamNo(var_31_13)

		for iter_31_1 = arg_31_1.teamNo_, #arg_31_0.petTeam_ do
			local var_31_14, var_31_15 = arg_31_0:nodeByName("avatar_pet" .. iter_31_1):getPosition()

			if arg_31_2 then
				arg_31_0.petTeam_[iter_31_1]:pos(var_31_14, var_31_15)

				arg_31_1.isAnimated_ = false
			elseif iter_31_1 ~= arg_31_1.teamNo_ then
				local var_31_16 = arg_31_0.petTeam_[iter_31_1]

				transition.stopTarget(var_31_16)
				transition.moveTo(var_31_16, {
					time = 0.3,
					x = var_31_14,
					y = var_31_15,
					onComplete = function()
						var_31_16.iniCell_.isAnimated_ = false
						var_31_16.isAnimated_ = false
					end
				})
			else
				local var_31_17 = arg_31_0.petTeam_[iter_31_1]

				transition.stopTarget(var_31_17)

				var_31_13.isAnimated_ = true

				transition.moveTo(var_31_17, {
					time = 0.3,
					x = var_31_14,
					y = var_31_15,
					onComplete = function()
						arg_31_1.isAnimated_ = false
						var_31_13.isAnimated_ = false
					end
				})
			end

			arg_31_0.petTeam_[iter_31_1].iniCell_.teamNo_ = iter_31_1
		end

		var_31_4:setVisible(true)
		var_31_5:setVisible(true)
	end

	arg_31_0:updateScore()
end

function var_0_0.clickPetBottomAvatar(arg_38_0, arg_38_1, arg_38_2)
	if arg_38_1.isAnimated_ then
		return
	end

	local var_38_0, var_38_1 = arg_38_0:nodeByName("list_layer"):getPosition()
	local var_38_2 = arg_38_1.iniCell_
	local var_38_3

	for iter_38_0, iter_38_1 in ipairs(arg_38_0.petSelect_) do
		if iter_38_1:getTableID() == arg_38_1.data:getTableID() and iter_38_1.player_name == arg_38_1.data.player_name then
			var_38_3 = iter_38_0

			break
		end
	end

	if not var_38_3 then
		return
	end

	if var_38_2 and not tolua.isnull(var_38_2) then
		local var_38_4 = var_38_2:convertToWorldSpace(cc.p(0, 0))

		var_38_0, var_38_1 = var_38_4.x, var_38_4.y

		local var_38_5
		local var_38_6 = var_38_2:getChildByName("layout")
		local var_38_7 = var_38_6:getChildByName("avatar_mask")
		local var_38_8 = var_38_6:getChildByName("chosen")

		var_38_7:setVisible(false)
		var_38_8:setVisible(false)
	end

	arg_38_0:moveFadeOutAction(var_38_0, var_38_1, arg_38_1, arg_38_2)

	for iter_38_2 = #arg_38_0.petTeam_, var_38_3 + 1, -1 do
		local var_38_9 = arg_38_0.petTeam_[iter_38_2]
		local var_38_10, var_38_11 = arg_38_0:nodeByName("avatar_pet" .. iter_38_2 - 1):getPosition()

		transition.stopTarget(var_38_9)
		transition.moveTo(arg_38_0.petTeam_[iter_38_2], {
			time = 0.3,
			x = var_38_10,
			y = var_38_11
		})

		arg_38_0.petTeam_[iter_38_2].iniCell_.teamNo_ = iter_38_2 - 1
	end

	if arg_38_1.type == var_0_16.RENT_PET then
		arg_38_0.isSelectMerPet = false
		arg_38_0.selectMerPet = nil
	end

	table.remove(arg_38_0.petTeam_, var_38_3)
	table.remove(arg_38_0.petSelect_, var_38_3)

	if var_38_2 then
		var_38_2.teamNo_ = nil
	end

	arg_38_0:updateScore()
end

function var_0_0.clickPetBottomAvatarWithoutAnimation(arg_39_0, arg_39_1, arg_39_2)
	if arg_39_1.isAnimated_ then
		return
	end

	local var_39_0, var_39_1 = arg_39_0:nodeByName("list_layer"):getPosition()
	local var_39_2 = arg_39_1.iniCell_
	local var_39_3

	for iter_39_0, iter_39_1 in ipairs(arg_39_0.petTeam_) do
		if iter_39_1 == arg_39_1 then
			var_39_3 = iter_39_0

			break
		end
	end

	if not var_39_3 then
		return
	end

	if var_39_2 and not tolua.isnull(var_39_2) then
		local var_39_4 = var_39_2:convertToWorldSpace(cc.p(0, 0))
		local var_39_5
		local var_39_6 = var_39_2:getChildByName("layout")
		local var_39_7 = var_39_6:getChildByName("avatar_mask")
		local var_39_8 = var_39_6:getChildByName("chosen")

		var_39_7:setVisible(false)
		var_39_8:setVisible(false)
	end

	for iter_39_2 = #arg_39_0.petTeam_, var_39_3 + 1, -1 do
		local var_39_9 = arg_39_0.petTeam_[iter_39_2]
		local var_39_10, var_39_11 = arg_39_0:nodeByName("avatar_pet" .. iter_39_2 - 1):getPosition()

		transition.stopTarget(var_39_9)
		transition.moveTo(arg_39_0.petTeam_[iter_39_2], {
			time = 0.3,
			x = var_39_10,
			y = var_39_11
		})

		arg_39_0.petTeam_[iter_39_2].iniCell_.teamNo_ = iter_39_2 - 1
	end

	table.remove(arg_39_0.petTeam_, var_39_3)
	table.remove(arg_39_0.petSelect_, var_39_3)

	if var_39_2 then
		var_39_2.teamNo_ = nil
	end

	if arg_39_1 and not tolua.isnull(arg_39_1) then
		arg_39_1:removeSelf()
	end

	if arg_39_2 then
		arg_39_2()
	end
end

function var_0_0.getPetTeamNo(arg_40_0, arg_40_1)
	table.insert(arg_40_0.petTeam_, arg_40_1)
	table.insert(arg_40_0.petSelect_, arg_40_1.data)

	return #arg_40_0.petTeam_
end

function var_0_0.initPetBottomCell(arg_41_0, arg_41_1)
	local var_41_0 = display.newNode()

	var_41_0:size(146, 146)
	var_41_0:align(display.CENTER)

	var_41_0.data = arg_41_1
	var_41_0.type = var_0_16.SELF_PET

	xyd.setPetAvatarNewUI(var_41_0, arg_41_1, 100)

	return var_41_0
end

function var_0_0.initComingSelect(arg_42_0)
	if arg_42_0.firstSelect == 0 then
		arg_42_0.selfProgress = 1

		arg_42_0:controllLock(0)

		local var_42_0 = var_0_5:translation("REGION_ARENA_TIP14")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_42_0
		})
	else
		arg_42_0.enemyProgress = 1

		arg_42_0:controllLock(1)

		local var_42_1 = {
			message = var_0_5:translation("REGION_ARENA_TIP13")
		}

		xyd.WindowManager.get():openWindow("finding_enemy", var_42_1)
		arg_42_0:selectEnemyHeros(arg_42_0.enemyOldProgress, arg_42_0.enemyProgress)
	end
end

function var_0_0.initMenu(arg_43_0)
	arg_43_0.heroClassButtons_ = {}

	table.insert(arg_43_0.heroClassButtons_, arg_43_0:nodeByName("button_all"))
	table.insert(arg_43_0.heroClassButtons_, arg_43_0:nodeByName("button_qianpai"))
	table.insert(arg_43_0.heroClassButtons_, arg_43_0:nodeByName("button_zhongpai"))
	table.insert(arg_43_0.heroClassButtons_, arg_43_0:nodeByName("button_houpai"))
	table.insert(arg_43_0.heroClassButtons_, arg_43_0:nodeByName("button_filter"))
	table.insert(arg_43_0.heroClassButtons_, arg_43_0:nodeByName("button_search"))

	for iter_43_0 = 1, #arg_43_0.heroClassButtons_ do
		arg_43_0.heroClassButtons_[iter_43_0]:setZoomScale(0.3)
		arg_43_0.heroClassButtons_[iter_43_0]:addTouchEventListener(function(arg_44_0, arg_44_1)
			if arg_44_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				if arg_43_0.selectedHeroClass_[arg_43_0.leftMenuType_] == iter_43_0 then
					for iter_44_0 = 1, #arg_43_0.heroClassButtons_ do
						if iter_44_0 == arg_43_0.selectedHeroClass_[arg_43_0.leftMenuType_] then
							arg_43_0.heroClassButtons_[iter_44_0]:setBrightStyle(ccui.BrightStyle.highlight)
						else
							arg_43_0.heroClassButtons_[iter_44_0]:setBrightStyle(ccui.BrightStyle.normal)
						end
					end

					return
				end

				arg_43_0.selectedHeroClass_[arg_43_0.leftMenuType_] = iter_43_0

				arg_43_0:refreshSelectedHeroClass()
			end
		end)
	end

	arg_43_0:nodeByName("button_filter"):addTouchEventListener(function(arg_45_0, arg_45_1)
		xyd.buttonScaleAnim(arg_45_0, arg_45_1)

		if arg_45_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("hero_filter_wnd")
		end
	end)
	arg_43_0:nodeByName("button_search"):addTouchEventListener(function(arg_46_0, arg_46_1)
		xyd.buttonScaleAnim(arg_46_0, arg_46_1)

		if arg_46_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("hero_search_wnd")
		end
	end)
	arg_43_0:nodeByName("button_collocation"):addTouchEventListener(function(arg_47_0, arg_47_1)
		xyd.buttonScaleAnim(arg_47_0, arg_47_1)

		if arg_47_1 == ccui.TouchEventType.ended then
			if arg_43_0.leftMenuType_ ~= var_0_17.SELF_HERO then
				return
			end

			arg_43_0.collocationType_ = 3 - arg_43_0.collocationType_

			arg_43_0:refreshSelectedHeroClass()
		end
	end)
end

function var_0_0.initLeftMenu(arg_48_0)
	arg_48_0:nodeByName("button_zhandui").menu_type = var_0_17.SELF_HERO
	arg_48_0:nodeByName("button_pet").menu_type = var_0_17.SELF_PET
	arg_48_0.leftMenuType_ = var_0_17.SELF_HERO
	arg_48_0.leftMenuButtons_ = {}

	table.insert(arg_48_0.leftMenuButtons_, arg_48_0:nodeByName("button_zhandui"))
	table.insert(arg_48_0.leftMenuButtons_, arg_48_0:nodeByName("button_pet"))

	for iter_48_0 = 1, #arg_48_0.leftMenuButtons_ do
		if iter_48_0 == 1 then
			arg_48_0.leftMenuButtons_[iter_48_0]:setBrightStyle(ccui.BrightStyle.highlight)
		end

		arg_48_0.leftMenuButtons_[iter_48_0]:setZoomScale(0.3)

		local var_48_0 = arg_48_0.leftMenuButtons_[1]:getY() - 85 * (iter_48_0 - 1)

		arg_48_0.leftMenuButtons_[iter_48_0]:y(var_48_0)
		arg_48_0.leftMenuButtons_[iter_48_0]:addTouchEventListener(function(arg_49_0, arg_49_1)
			if arg_49_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				if arg_49_0 == arg_48_0:nodeByName("button_pet") and not arg_48_0.choosingPet then
					return
				end

				for iter_49_0, iter_49_1 in ipairs(arg_48_0.leftMenuButtons_) do
					iter_49_1:setBrightStyle(arg_49_0 == iter_49_1 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
				end

				arg_48_0.leftMenuType_ = arg_49_0.menu_type
				arg_48_0.totalPet_ = arg_48_0.tmpTotalPets[var_0_16.SELF_PET]

				arg_48_0:refreshSelectedHeroClass()
			end
		end)
	end
end

function var_0_0.initPets(arg_50_0, arg_50_1, arg_50_2)
	local var_50_0 = {}

	for iter_50_0, iter_50_1 in ipairs(arg_50_1) do
		if iter_50_1.is_show_ == 1 then
			table.insert(var_50_0, iter_50_1)
		end
	end

	table.sort(var_50_0, function(arg_51_0, arg_51_1)
		return xyd.petNormalSort(arg_51_0, arg_51_1) or false
	end)

	arg_50_0.tmpTotalPets[arg_50_2] = var_50_0
end

function var_0_0.initHeros(arg_52_0, arg_52_1)
	arg_52_0.totalHero_ = {}
	arg_52_0.forceHeros = {}
	arg_52_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_52_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_52_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_52_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
	arg_52_0.totalHero_[xyd.DistanceType.FILTER] = {}
	arg_52_0.totalHero_[xyd.DistanceType.SEARCH] = {}

	for iter_52_0, iter_52_1 in pairs(arg_52_0.totalHero_) do
		iter_52_1[var_0_18.NO] = {}
		iter_52_1[var_0_18.YES] = {}
	end

	arg_52_0.searchTxt = ""

	arg_52_0:sortTables(arg_52_1)

	for iter_52_2, iter_52_3 in pairs(arg_52_1) do
		iter_52_3.isLock = false

		arg_52_0:updateHeroTable(arg_52_0.totalHero_, iter_52_3)
	end

	local var_52_0 = 5

	if var_52_0 > #arg_52_0.totalHero_[xyd.DistanceType.ALL][var_0_18.NO] then
		var_52_0 = #arg_52_0.totalHero_[xyd.DistanceType.ALL][var_0_18.NO]
	end

	for iter_52_4 = 1, var_52_0 do
		table.insert(arg_52_0.forceHeros, clone(arg_52_0.totalHero_[xyd.DistanceType.ALL][var_0_18.NO][iter_52_4]))
	end

	arg_52_0:sortHerosByForce(arg_52_0.forceHeros)
end

function var_0_0.updateFilterHeros(arg_53_0)
	arg_53_0.totalHero_[xyd.DistanceType.FILTER] = {}
	arg_53_0.totalHero_[xyd.DistanceType.FILTER][var_0_18.NO] = {}
	arg_53_0.totalHero_[xyd.DistanceType.FILTER][var_0_18.YES] = {}

	local var_53_0 = {
		0,
		0,
		0
	}
	local var_53_1 = {
		0,
		0,
		0
	}
	local var_53_2 = {
		0,
		0,
		0,
		0
	}
	local var_53_3 = {
		0,
		0,
		0
	}

	if arg_53_0.selfPlayer.sortType and arg_53_0.selfPlayer.sortType > 0 then
		local var_53_4 = {}
		local var_53_5 = arg_53_0.selfPlayer.sortType
		local var_53_6 = 1

		while var_53_5 > 0 do
			var_53_4[var_53_6] = var_53_5 % 2
			var_53_6 = var_53_6 + 1
			var_53_5 = math.floor(var_53_5 / 2)
		end

		local var_53_7 = 1

		for iter_53_0 = 13, 1, -1 do
			if iter_53_0 <= 4 then
				if iter_53_0 == 4 then
					var_53_7 = 1
				end

				var_53_2[var_53_7] = var_53_4[iter_53_0]
			elseif iter_53_0 <= 7 then
				if iter_53_0 == 7 then
					var_53_7 = 1
				end

				var_53_1[var_53_7] = var_53_4[iter_53_0]
			elseif iter_53_0 <= 10 then
				if iter_53_0 == 10 then
					var_53_7 = 1
				end

				if var_53_4[iter_53_0] then
					var_53_0[var_53_7] = var_53_4[iter_53_0]
				end
			elseif iter_53_0 <= 13 then
				if iter_53_0 == 13 then
					var_53_7 = 1
				end

				if var_53_4[iter_53_0] then
					var_53_3[var_53_7] = var_53_4[iter_53_0]
				end
			end

			var_53_7 = var_53_7 + 1
		end
	else
		var_53_0 = {
			1,
			1,
			1
		}
		var_53_1 = {
			1,
			1,
			1
		}
		var_53_2 = {
			1,
			1,
			1,
			1
		}
		var_53_3 = {
			1,
			1,
			1
		}
	end

	for iter_53_1, iter_53_2 in pairs(arg_53_0.totalHero_[xyd.DistanceType.ALL][var_0_18.NO]) do
		if var_53_0[iter_53_2:getDistanceType() - 1] == 1 and var_53_1[iter_53_2:getHeroType()] == 1 and var_53_2[iter_53_2:getFromType()] == 1 and var_53_3[iter_53_2:getAwakenType()] == 1 then
			table.insert(arg_53_0.totalHero_[xyd.DistanceType.FILTER][var_0_18.NO], iter_53_2)
		end
	end

	for iter_53_3, iter_53_4 in pairs(arg_53_0.totalHero_[xyd.DistanceType.ALL][var_0_18.YES]) do
		if var_53_0[iter_53_4:getDistanceType() - 1] == 1 and var_53_1[iter_53_4:getHeroType()] == 1 and var_53_2[iter_53_4:getFromType()] == 1 and var_53_3[iter_53_4:getAwakenType()] == 1 then
			table.insert(arg_53_0.totalHero_[xyd.DistanceType.FILTER][var_0_18.YES], iter_53_4)
		end
	end
end

function var_0_0.updateSearchHeros(arg_54_0)
	arg_54_0.totalHero_[xyd.DistanceType.SEARCH] = {}
	arg_54_0.totalHero_[xyd.DistanceType.SEARCH][var_0_18.NO] = {}
	arg_54_0.totalHero_[xyd.DistanceType.SEARCH][var_0_18.YES] = {}

	if arg_54_0.searchTxt ~= "" then
		for iter_54_0, iter_54_1 in pairs(arg_54_0.totalHero_[xyd.DistanceType.ALL][var_0_18.NO]) do
			if xyd.searchHeroByName(arg_54_0.searchTxt, iter_54_1) then
				table.insert(arg_54_0.totalHero_[xyd.DistanceType.SEARCH][var_0_18.NO], iter_54_1)
			end
		end

		for iter_54_2, iter_54_3 in pairs(arg_54_0.totalHero_[xyd.DistanceType.ALL][var_0_18.YES]) do
			if xyd.searchHeroByName(arg_54_0.searchTxt, iter_54_3) then
				table.insert(arg_54_0.totalHero_[xyd.DistanceType.SEARCH][var_0_18.YES], iter_54_3)
			end
		end
	end
end

function var_0_0.updateHeroTable(arg_55_0, arg_55_1, arg_55_2)
	if arg_55_2:getDistanceType() == xyd.DistanceType.QIANPAI then
		table.insert(arg_55_1[xyd.DistanceType.QIANPAI][var_0_18.NO], arg_55_2)

		if arg_55_2:isCollocation() then
			table.insert(arg_55_1[xyd.DistanceType.QIANPAI][var_0_18.YES], arg_55_2)
		end
	elseif arg_55_2:getDistanceType() == xyd.DistanceType.ZHONGPAI then
		table.insert(arg_55_1[xyd.DistanceType.ZHONGPAI][var_0_18.NO], arg_55_2)

		if arg_55_2:isCollocation() then
			table.insert(arg_55_1[xyd.DistanceType.ZHONGPAI][var_0_18.YES], arg_55_2)
		end
	elseif arg_55_2:getDistanceType() == xyd.DistanceType.HOUPAI then
		table.insert(arg_55_1[xyd.DistanceType.HOUPAI][var_0_18.NO], arg_55_2)

		if arg_55_2:isCollocation() then
			table.insert(arg_55_1[xyd.DistanceType.HOUPAI][var_0_18.YES], arg_55_2)
		end
	end

	table.insert(arg_55_1[xyd.DistanceType.ALL][var_0_18.NO], arg_55_2)

	if arg_55_2:isCollocation() then
		table.insert(arg_55_1[xyd.DistanceType.ALL][var_0_18.YES], arg_55_2)
	end
end

function var_0_0.initOtherHero(arg_56_0, arg_56_1, arg_56_2)
	for iter_56_0, iter_56_1 in pairs(arg_56_2) do
		local var_56_0 = arg_56_0:checkHeroExit(arg_56_1, iter_56_1.table_id)

		if iter_56_1.is_summon == 1 and not var_56_0 then
			var_56_0 = var_0_1.new()

			var_56_0:initUnCollected(iter_56_1.table_id)
			table.insert(arg_56_1, var_56_0)
		end

		if iter_56_1.add_star > 0 then
			local var_56_1 = var_56_0:getStar()

			if not xyd.isSuperHero(var_56_0) then
				if var_56_1 + iter_56_1.add_star > xyd.MAX_STAR_LEVEL then
					var_56_0:setStar(xyd.MAX_STAR_LEVEL)
				else
					var_56_0:setStar(var_56_1 + iter_56_1.add_star)
				end
			elseif var_56_1 + iter_56_1.add_star > xyd.SUPER_HERO_TOTAL_STARS then
				var_56_0:setStar(xyd.SUPER_HERO_TOTAL_STARS)
			else
				var_56_0:setStar(var_56_1 + iter_56_1.add_star)
			end
		end

		if var_56_0 and iter_56_1.is_awake == 1 and not var_56_0:isAwaken() then
			var_56_0:setTableID(xyd.tables.hero:afterAwaken(iter_56_1.table_id))
		end

		if var_56_0 and iter_56_1.region_arena_times then
			var_56_0.region_arena_times = (var_56_0.region_arena_times or 0) + iter_56_1.region_arena_times
		end
	end
end

function var_0_0.checkHeroExit(arg_57_0, arg_57_1, arg_57_2)
	local var_57_0 = false

	for iter_57_0, iter_57_1 in pairs(arg_57_1) do
		local var_57_1 = iter_57_1:getTableID()

		if var_57_1 == arg_57_2 then
			var_57_0 = iter_57_1

			break
		end

		if iter_57_1:isAwaken() then
			var_57_1 = iter_57_1:beforeAwakenID()
		end

		if var_57_1 == arg_57_2 then
			var_57_0 = iter_57_1

			break
		end
	end

	return var_57_0
end

function var_0_0.initHeroCell(arg_58_0, arg_58_1, arg_58_2, arg_58_3)
	local var_58_0

	if arg_58_3 then
		var_58_0 = arg_58_3
	else
		var_58_0 = arg_58_0.totalHero_[arg_58_0.selectedHeroClass_[arg_58_0.leftMenuType_]][arg_58_0.collocationType_][arg_58_2]
	end

	var_58_0.healthStatus = nil

	local var_58_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/across_arena/hero_avatar.csb")
	local var_58_2 = var_58_1:getChildByName("background"):getContentSize()

	var_58_1:setContentSize(var_58_2)
	arg_58_1:setContentSize(var_58_2)
	xyd.setAvatarBorderNewUI(var_58_0, var_58_1:getChildByName("avatar"), nil, nil, nil, nil, nil)

	local var_58_3 = var_58_1:getChildByName("chosen")

	var_58_3:setLocalZOrder(100)
	var_58_3:setVisible(false)

	local var_58_4 = var_58_1:getChildByName("avatar_mask")

	var_58_4:setLocalZOrder(2)
	var_58_4:setVisible(false)
	var_58_1:getChildByName("hero_lock"):setVisible(false)

	local var_58_5 = var_58_1:getChildByName("lv_txt")

	var_58_5:setString(var_58_0:getLevel())
	var_58_5:enableOutline(cc.c4b(63, 63, 63, 255), 2)
	var_58_1:getChildByName("name_text"):setString(var_58_0:getName())
	var_58_1:setName("layout")
	var_58_1:setPosition(cc.p(0, 0))

	arg_58_1.data = var_58_0

	for iter_58_0, iter_58_1 in ipairs(arg_58_0.select_) do
		if iter_58_1:getTableID() == var_58_0:getTableID() and iter_58_1.player_name == var_58_0.player_name then
			arg_58_1.teamNo_ = iter_58_0

			var_58_3:setVisible(true)
			var_58_4:setVisible(true)

			arg_58_0.team_[iter_58_0].iniCell_ = arg_58_1
			arg_58_0.team_[iter_58_0].iniCellVisible_ = false

			break
		end
	end

	var_58_0.isDead = isDead

	arg_58_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_58_1:addChild(var_58_1)
	arg_58_1:setTouchSwallowEnabled(false)
	arg_58_1:setTouchEnabled(true)
	arg_58_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_59_0)
		arg_58_0:buttonHandler(nil, arg_58_1, arg_59_0)

		if arg_59_0.name == "began" then
			arg_58_0.startClick_ = true
			arg_58_0.prevX_ = arg_59_0.x
			arg_58_0.prevY_ = arg_59_0.y
		elseif arg_59_0.name == "moved" then
			if math.abs(arg_59_0.y - arg_58_0.prevY_) > 5 or math.abs(arg_59_0.x - arg_58_0.prevX_) > 5 then
				arg_58_0.startClick_ = false
			end
		elseif arg_59_0.name == "ended" and arg_58_0.startClick_ and arg_58_0.selectState == 0 then
			if isDead then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_5:translation("HERO_DIE_ERROR")
				})
			elseif #arg_58_0.select_ >= arg_58_0.selfProgress then
				local var_59_0 = string.format(var_0_5:translation("REGION_ARENA_TIP17"), arg_58_0.selfProgress - arg_58_0.selfOldProgress)

				xyd.WindowManager.get():openWindow("toast", {
					message = var_59_0
				})
			elseif not arg_58_1.data or arg_58_1.data and not arg_58_1.data.isLock then
				arg_58_0:clickAvatar(arg_58_1)
			end
		end

		return true
	end)

	arg_58_0.heroCells_[var_58_0:getTableID()] = arg_58_1
end

function var_0_0.initBottomCell(arg_60_0, arg_60_1)
	local var_60_0 = display.newNode()
	local var_60_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/across_arena/hero_avatar.csb")
	local var_60_2 = var_60_1:getChildByName("background"):getContentSize()

	var_60_1:setContentSize(var_60_2)
	var_60_0:setContentSize(var_60_2)
	xyd.setAvatarBorderNewUI(arg_60_1, var_60_1:getChildByName("avatar"), nil, nil, nil, nil, nil)

	local var_60_3 = var_60_1:getChildByName("chosen")

	var_60_3:setLocalZOrder(100)
	var_60_3:setVisible(false)

	local var_60_4 = var_60_1:getChildByName("avatar_mask")

	var_60_4:setLocalZOrder(2)
	var_60_4:setVisible(false)
	var_60_1:getChildByName("hero_lock"):setVisible(false)

	var_60_0.isLock = false

	local var_60_5 = var_60_1:getChildByName("lv_txt")

	var_60_5:setString(arg_60_1:getLevel())
	var_60_5:enableOutline(cc.c4b(63, 63, 63, 255), 2)
	var_60_1:getChildByName("name_text"):setString(arg_60_1:getName())
	var_60_1:setName("layout")

	var_60_0.data = arg_60_1

	var_60_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_60_0:addChild(var_60_1)

	arg_60_0.heroBottomCells_[arg_60_1:getTableID()] = var_60_0

	return var_60_0
end

function var_0_0.heroDelegate(arg_61_0, arg_61_1, arg_61_2, arg_61_3)
	local var_61_0 = math.ceil(#arg_61_0.totalHero_[arg_61_0.selectedHeroClass_[arg_61_0.leftMenuType_]][arg_61_0.collocationType_] / var_0_10)

	if cc.ui.UIListView.COUNT_TAG == arg_61_2 then
		return var_61_0
	elseif cc.ui.UIListView.CELL_TAG == arg_61_2 then
		local var_61_1
		local var_61_2
		local var_61_3
		local var_61_4 = arg_61_0.heroList_:dequeueItem()

		if not var_61_4 then
			var_61_4 = arg_61_0.heroList_:newItem()
		else
			var_61_4:removeAllChildren()
		end

		local var_61_5 = display.newNode()

		var_61_5:setTouchSwallowEnabled(false)

		for iter_61_0 = 1, var_0_10 do
			local var_61_6 = (arg_61_3 - 1) * var_0_10 + iter_61_0

			if var_61_6 > #arg_61_0.totalHero_[arg_61_0.selectedHeroClass_[arg_61_0.leftMenuType_]][arg_61_0.collocationType_] then
				break
			end

			var_61_3 = display.newNode()

			arg_61_0:initHeroCell(var_61_3, var_61_6)

			local var_61_7 = var_61_3:getContentSize().width
			local var_61_8 = var_61_3:getContentSize().height
			local var_61_9 = (arg_61_0.heroList_.viewRect_.width - var_61_7 * var_0_10) / (var_0_10 + 1)

			var_61_3:pos(var_61_9 * iter_61_0 + (iter_61_0 - 1) * var_61_7 + var_61_7 / 2, var_0_9 + var_61_8 / 2 - 2)
			var_61_5:addChild(var_61_3)
		end

		var_61_5:setContentSize(cc.size(arg_61_0.heroList_.viewRect_.width, var_61_3:getContentSize().height + var_0_9))
		var_61_4:setItemSize(arg_61_0.heroList_.viewRect_.width, var_61_3:getContentSize().height + var_0_9)
		var_61_4:addContent(var_61_5)

		return var_61_4
	end
end

function var_0_0.refreshSelectedHeroClass(arg_62_0)
	for iter_62_0 = 1, #arg_62_0.heroClassButtons_ do
		if iter_62_0 == arg_62_0.selectedHeroClass_[arg_62_0.leftMenuType_] then
			arg_62_0.heroClassButtons_[iter_62_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_62_0.heroClassButtons_[iter_62_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_62_0.heroList_:removeAllItems()

	if arg_62_0.selectedHeroClass_[arg_62_0.leftMenuType_] == xyd.DistanceType.FILTER then
		-- block empty
	elseif arg_62_0.selectedHeroClass_[arg_62_0.leftMenuType_] ~= xyd.DistanceType.ALL then
		for iter_62_1, iter_62_2 in ipairs(arg_62_0.select_) do
			if iter_62_2:getDistanceType() ~= arg_62_0.selectedHeroClass_[arg_62_0.leftMenuType_] then
				arg_62_0.team_[iter_62_1].iniCellVisible_ = true
			end
		end
	end

	arg_62_0.heroList_:reload()
end

function var_0_0.buttonHandler(arg_63_0, arg_63_1, arg_63_2, arg_63_3)
	if not arg_63_2 or not arg_63_2:getParent() then
		return
	end

	if arg_63_3.name == "ended" then
		transition.stopTarget(arg_63_2)
		arg_63_2:setScale(1)

		if arg_63_1 then
			arg_63_1(arg_63_2, eventType)
		end
	elseif arg_63_3.name == "began" then
		local var_63_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_63_2:runAction(var_63_0)

		return true
	elseif arg_63_3.name == "cancled" then
		transition.stopTarget(arg_63_2)
		arg_63_2:setScale(1)
	end
end

function var_0_0.clickAvatar(arg_64_0, arg_64_1, arg_64_2, arg_64_3)
	if arg_64_1.isAnimated_ or not arg_64_1.teamNo_ and #arg_64_0.team_ >= xyd.MAX_TEAM_MEMBER_NUM then
		return
	end

	if not arg_64_2 then
		arg_64_0.unPreSelect_ = true
	end

	local var_64_0
	local var_64_1 = arg_64_1:getChildByName("layout")
	local var_64_2 = var_64_1:getChildByName("avatar_mask")
	local var_64_3 = var_64_1:getChildByName("chosen")
	local var_64_4
	local var_64_5

	if arg_64_3 then
		var_64_4, var_64_5 = xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2
	else
		local var_64_6 = arg_64_1:convertToWorldSpace(cc.p(0, 0))

		var_64_4, var_64_5 = var_64_6.x + arg_64_1:getContentSize().width / 2, var_64_6.y + arg_64_1:getContentSize().height / 2
	end

	arg_64_1.isAnimated_ = true

	if arg_64_1.teamNo_ then
		local var_64_7 = arg_64_0.team_[arg_64_1.teamNo_]

		arg_64_0:moveFadeOutAction(var_64_4, var_64_5, var_64_7, function()
			arg_64_1.isAnimated_ = false
		end)
		var_64_2:setVisible(false)
		var_64_3:setVisible(false)

		for iter_64_0 = #arg_64_0.team_, arg_64_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_64_0.team_[iter_64_0])

			local var_64_8, var_64_9 = arg_64_0:nodeByName("avatar" .. iter_64_0 - 1):getPosition()

			transition.moveTo(arg_64_0.team_[iter_64_0], {
				time = 0.3,
				x = var_64_8,
				y = var_64_9
			})

			arg_64_0.team_[iter_64_0].iniCell_.teamNo_ = iter_64_0 - 1
		end

		table.remove(arg_64_0.team_, arg_64_1.teamNo_)
		table.remove(arg_64_0.select_, arg_64_1.teamNo_)

		arg_64_1.teamNo_ = nil
	elseif not arg_64_1.teamNo_ and #arg_64_0.team_ < xyd.MAX_TEAM_MEMBER_NUM then
		if not arg_64_2 then
			local var_64_10 = arg_64_1.data

			if var_0_6:chosenSound(var_64_10:getTableID()) ~= "" then
				xyd.AssetDownload.get():preloadCharacterSound({
					var_64_10:getTableID()
				}, function()
					return
				end, true)
				audio.playSound(var_0_6:chosenSound(var_64_10:getTableID()), false)
			end
		end

		if arg_64_1.data.isDead then
			arg_64_1.isAnimated_ = false

			return
		end

		local var_64_11 = arg_64_0:initBottomCell(arg_64_1.data)

		var_64_11.iniCell_ = arg_64_1

		var_64_11:pos(var_64_4, var_64_5)
		var_64_11:addTo(arg_64_0)
		var_64_11:setTouchEnabled(true)

		local var_64_12 = arg_64_1.data

		var_64_11:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_67_0)
			if arg_67_0.name == "ended" then
				arg_64_0:clickBottomAvatar(var_64_11)
			end

			return true
		end)

		arg_64_1.teamNo_ = arg_64_0:getTeamNo(var_64_11)

		for iter_64_1 = arg_64_1.teamNo_, #arg_64_0.team_ do
			local var_64_13, var_64_14 = arg_64_0:nodeByName("avatar" .. iter_64_1):getPosition()

			if arg_64_2 then
				arg_64_0.team_[iter_64_1]:pos(var_64_13, var_64_14)

				arg_64_1.isAnimated_ = false
			elseif iter_64_1 ~= arg_64_1.teamNo_ then
				local var_64_15 = arg_64_0.team_[iter_64_1]

				transition.stopTarget(var_64_15)
				transition.moveTo(var_64_15, {
					time = 0.3,
					x = var_64_13,
					y = var_64_14,
					onComplete = function()
						var_64_15.iniCell_.isAnimated_ = false
						var_64_15.isAnimated_ = false
					end
				})
			else
				local var_64_16 = arg_64_0.team_[iter_64_1]

				transition.stopTarget(var_64_16)

				var_64_11.isAnimated_ = true

				transition.moveTo(var_64_16, {
					time = 0.3,
					x = var_64_13,
					y = var_64_14,
					onComplete = function()
						arg_64_1.isAnimated_ = false
						var_64_11.isAnimated_ = false
					end
				})
			end

			arg_64_0.team_[iter_64_1].iniCell_.teamNo_ = iter_64_1
		end

		var_64_2:setVisible(true)
		var_64_3:setVisible(true)
	end

	arg_64_0:updateScore()
end

function var_0_0.checkHeroValid(arg_70_0, arg_70_1)
	for iter_70_0, iter_70_1 in pairs(arg_70_0.select_) do
		if arg_70_1:getTableID() == iter_70_1:getTableID() then
			return false
		end
	end

	return true
end

function var_0_0.updateScore(arg_71_0)
	local var_71_0 = 0

	for iter_71_0, iter_71_1 in ipairs(arg_71_0.team_) do
		var_71_0 = var_71_0 + iter_71_1.data:getZhandouli()
	end

	for iter_71_2, iter_71_3 in ipairs(arg_71_0.petTeam_) do
		var_71_0 = var_71_0 + iter_71_3.data:getZhandouli()
	end

	arg_71_0:nodeByName("zhandouli"):setString(var_71_0)
end

function var_0_0.clickBottomAvatar(arg_72_0, arg_72_1)
	if arg_72_1.isAnimated_ or arg_72_1.isLock then
		return
	end

	local var_72_0, var_72_1 = arg_72_0:nodeByName("list_layer"):getPosition()
	local var_72_2 = arg_72_1.iniCell_
	local var_72_3

	for iter_72_0, iter_72_1 in ipairs(arg_72_0.select_) do
		if iter_72_1:getTableID() == arg_72_1.data:getTableID() and iter_72_1.player_name == arg_72_1.data.player_name then
			var_72_3 = iter_72_0

			break
		end
	end

	if not var_72_3 then
		return
	end

	if not arg_72_1.iniCellVisible_ and not tolua.isnull(var_72_2) then
		local var_72_4 = var_72_2:convertToWorldSpace(cc.p(0, 0))

		var_72_0, var_72_1 = var_72_4.x + var_72_2:getContentSize().width / 2, var_72_4.y + var_72_2:getContentSize().height / 2

		local var_72_5 = var_72_2:getChildByName("layout")
		local var_72_6 = var_72_5:getChildByName("avatar_mask")
		local var_72_7 = var_72_5:getChildByName("chosen")

		var_72_6:setVisible(false)
		var_72_7:setVisible(false)
	end

	arg_72_0:moveFadeOutAction(var_72_0, var_72_1, arg_72_1)

	for iter_72_2 = #arg_72_0.team_, var_72_3 + 1, -1 do
		local var_72_8 = arg_72_0.team_[iter_72_2]
		local var_72_9, var_72_10 = arg_72_0:nodeByName("avatar" .. iter_72_2 - 1):getPosition()

		transition.stopTarget(var_72_8)
		transition.moveTo(arg_72_0.team_[iter_72_2], {
			time = 0.3,
			x = var_72_9,
			y = var_72_10
		})

		arg_72_0.team_[iter_72_2].iniCell_.teamNo_ = iter_72_2 - 1
	end

	table.remove(arg_72_0.team_, var_72_3)
	table.remove(arg_72_0.select_, var_72_3)

	var_72_2.teamNo_ = nil

	arg_72_0:updateScore()
end

function var_0_0.getTeamNo(arg_73_0, arg_73_1)
	for iter_73_0, iter_73_1 in ipairs(arg_73_0.team_) do
		if arg_73_1.data:getDistance() < iter_73_1.data:getDistance() then
			table.insert(arg_73_0.team_, iter_73_0, arg_73_1)
			table.insert(arg_73_0.select_, iter_73_0, arg_73_1.data)

			return iter_73_0
		end
	end

	table.insert(arg_73_0.team_, arg_73_1)
	table.insert(arg_73_0.select_, arg_73_1.data)

	return #arg_73_0.team_
end

function var_0_0.widgetSet(arg_74_0, arg_74_1)
	for iter_74_0, iter_74_1 in ipairs(arg_74_1:getChildren()) do
		if iter_74_1 ~= nil then
			iter_74_1:setCascadeOpacityEnabled(true)
			arg_74_0:widgetSet(iter_74_1)
		end
	end
end

function var_0_0.moveFadeOutAction(arg_75_0, arg_75_1, arg_75_2, arg_75_3, arg_75_4)
	arg_75_0:widgetSet(arg_75_3)
	arg_75_3:setCascadeOpacityEnabled(true)

	local var_75_0 = cc.Spawn:create(cc.FadeOut:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_75_1, arg_75_2)))

	arg_75_3:runActionOnce(var_75_0, true, arg_75_4)
end

function var_0_0.getBattleBtn(arg_76_0)
	if not arg_76_0.battleBtn_ then
		arg_76_0.battleBtn_ = arg_76_0:nodeByName("button_ok")

		arg_76_0.battleBtn_:addTouchEventListener(function(arg_77_0, arg_77_1)
			xyd.buttonScaleAnim(arg_77_0, arg_77_1)

			if arg_77_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if #arg_76_0.select_ < arg_76_0.selfProgress then
					local var_77_0 = var_0_5:translation("REGION_ARENA_TIP18")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_77_0
					})

					return
				else
					arg_76_0.battleBtn_:setBright(false)
					arg_76_0.battleBtn_:setTouchEnabled(false)
					arg_76_0:lockTeamCells()

					arg_76_0.selectState = 1 - arg_76_0.selectState
					arg_76_0.countDown = var_0_13

					arg_76_0:updateSelfSelectStates()

					arg_76_0.enemyOldProgress = arg_76_0.enemyProgress

					if 5 - arg_76_0.enemyOldProgress > 1 then
						arg_76_0.enemyProgress = arg_76_0.enemyProgress + 2

						arg_76_0:controllLock(1)

						local var_77_1 = {
							message = var_0_5:translation("REGION_ARENA_TIP13")
						}

						xyd.WindowManager.get():openWindow("finding_enemy", var_77_1)
						arg_76_0:selectEnemyHeros(arg_76_0.enemyOldProgress, arg_76_0.enemyProgress)
					elseif 5 - arg_76_0.enemyOldProgress == 1 then
						arg_76_0.enemyProgress = arg_76_0.enemyProgress + 1

						arg_76_0:controllLock(1)

						local var_77_2 = {
							message = var_0_5:translation("REGION_ARENA_TIP13")
						}

						xyd.WindowManager.get():openWindow("finding_enemy", var_77_2)
						arg_76_0:selectEnemyHeros(arg_76_0.enemyOldProgress, arg_76_0.enemyProgress)
					else
						if arg_76_0.handle then
							var_0_7.unscheduleGlobal(arg_76_0.handle)

							arg_76_0.handle = nil
						end

						arg_76_0.battleBegan = true

						arg_76_0:choosePet()
					end
				end
			end
		end)
	end

	return arg_76_0.battleBtn_
end

function var_0_0.lockTeamCells(arg_78_0)
	for iter_78_0, iter_78_1 in pairs(arg_78_0.team_) do
		iter_78_1.isLock = true

		iter_78_1:getChildByName("layout"):getChildByName("hero_lock"):setVisible(true)
	end

	for iter_78_2, iter_78_3 in pairs(arg_78_0.select_) do
		iter_78_3.isLock = true
	end
end

function var_0_0.startBattle(arg_79_0)
	if next(arg_79_0.team_) == nil then
		return
	end

	if next(arg_79_0.enemyHeroes_) == nil then
		return
	end

	arg_79_0:startRegionArenaBattle()
end

function var_0_0.startRegionArenaBattle(arg_80_0)
	if arg_80_0.isBackendBattle == 1 then
		local var_80_0 = 0

		var_0_7.performWithDelayGlobal(function()
			local var_81_0 = {}

			for iter_81_0, iter_81_1 in pairs(arg_80_0.select_) do
				table.insert(var_81_0, iter_81_1:getTableID())
			end

			local var_81_1 = {
				herosA = {}
			}

			for iter_81_2, iter_81_3 in ipairs(arg_80_0.team_) do
				table.insert(var_81_1.herosA, iter_81_3.data)
			end

			var_81_1.enemy_id = arg_80_0.enemyID
			var_81_1.isRegionArenaTest = arg_80_0.mode
			var_81_1.formation = var_81_0
			var_81_1.campaign_id = arg_80_0.campaignID
			var_81_1.herosB = {
				arg_80_0.enemyHeroes_
			}

			if arg_80_0.enemyPet then
				var_81_1.petsB = {
					arg_80_0.enemyPet
				}
			end

			var_81_1.fighterInfo = arg_80_0.fighterInfo
			var_81_1.campaignType = xyd.CampaignType.REGION_ARENA
			var_81_1.battleID = xyd.MapBattleID.ARENA

			local var_81_2

			if arg_80_0.petTeam_[1] then
				var_81_2 = arg_80_0.petTeam_[1].data:getPetID()
				var_81_1.petsA = {
					arg_80_0.petTeam_[1].data
				}
			else
				var_81_2 = 0
			end

			var_81_1.pet_id = var_81_2

			xyd.Backend.get():request(xyd.mid.REARENA_FIGHT, {
				enemy_id = arg_80_0.enemyID,
				is_test = arg_80_0.mode,
				campaign_id = var_81_1.campaignID,
				formation = var_81_0,
				pet_id = var_81_2
			}, function(arg_82_0, arg_82_1)
				if arg_82_0 == xyd.error.OK then
					if arg_82_1.battle_report == {} or #arg_82_1.battle_report == 0 then
						if xyd.WindowManager.get():getWindow("toast") ~= nil then
							xyd.WindowManager.get():closeWindow("toast")
						end

						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_5:translation("PLAYOFFS_RETRY")
						})

						arg_80_0.battleBegan = true
						var_80_0 = 3

						arg_80_0:startBattle()

						return
					end

					local var_82_0 = arg_82_1.arena_info
					local var_82_1 = arg_82_1.award

					arg_80_0.regionArena:setStar(var_82_0.star)

					var_81_1.is_win = arg_82_1.is_win

					if arg_82_1.battle_report[1] and arg_82_1.battle_report[1].content then
						var_81_1.battleReport = arg_82_1.battle_report[1].content
					elseif arg_82_1.battle_report[1] then
						var_81_1.battleReport = arg_82_1.battle_report[1]
					else
						var_81_1.battleReport = arg_82_1.battle_report
					end

					var_81_1.enemyName = arg_80_0.enemyName
					var_81_1.myName = arg_80_0.selfPlayer.playerName
					var_81_1.enemyRegionName = arg_80_0.enemyServerName
					var_81_1.enemyID = arg_80_0.enemyID

					dump(arg_80_0.enemyGuildName)

					var_81_1.enemyGuild = arg_80_0.enemyGuildName
					var_81_1.my_id = arg_80_0.fighterInfo.my_id
					var_81_1.isBackendBattle = arg_80_0.isBackendBattle
					var_81_1.oldStar = clone(arg_80_0.regionArena:getStar())
					var_81_1.selfRegionName = arg_80_0.selfRegionName
					var_81_1.selfRegion = arg_80_0.selfPlayer.region
					var_81_1.enemyRegion = arg_80_0.enemyRegion
					var_81_1.isNewLoading = true

					xyd.LoadingProxy.get():openBattleLoading(var_81_1)
					xyd.WindowManager.get():closeWindow(arg_80_0.name)
				else
					local var_82_2 = var_0_5:translation("REGION_ARENA_TIP20")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_82_2
					})
					xyd.WindowManager.get():closeWindow(arg_80_0.name)
				end
			end)
		end, var_80_0)
	elseif arg_80_0.isBackendBattle == 0 then
		local var_80_1 = {
			herosA = {}
		}

		for iter_80_0, iter_80_1 in ipairs(arg_80_0.team_) do
			table.insert(var_80_1.herosA, iter_80_1.data)
		end

		var_80_1.isRegionArenaTest = arg_80_0.mode
		var_80_1.enemy_id = arg_80_0.enemyID
		var_80_1.campaignType = xyd.CampaignType.REGION_ARENA
		var_80_1.campaignID = arg_80_0.campaignID
		var_80_1.herosB = {
			arg_80_0.enemyHeroes_
		}

		if arg_80_0.enemyPet then
			var_80_1.petsB = {
				arg_80_0.enemyPet
			}
		end

		var_80_1.fighterInfo = arg_80_0.fighterInfo
		var_80_1.battleID = xyd.MapBattleID.ARENA
		var_80_1.isBackendBattle = arg_80_0.isBackendBattle

		local var_80_2 = arg_80_0:getFormationStr(var_80_1.herosA)

		var_80_1.battleType = xyd.BattleType.CreateReport
		var_80_1.oldStar = clone(arg_80_0.regionArena:getStar())

		local var_80_3

		if arg_80_0.petTeam_[1] then
			var_80_3 = arg_80_0.petTeam_[1].data:getPetID()
		else
			var_80_3 = 0
		end

		xyd.Backend.get():request(xyd.mid.REARENA_PREPARE_FIGHT, {
			campaign_id = var_80_1.campaignID,
			campaign_type = var_80_1.campaignType,
			formation = var_80_2,
			pet_id = var_80_3
		}, function(arg_83_0, arg_83_1)
			if arg_83_0 == xyd.error.OK then
				if arg_83_1.formation and next(arg_83_1.formation) then
					local var_83_0 = {}

					for iter_83_0, iter_83_1 in ipairs(arg_83_1.formation) do
						local var_83_1 = var_0_1.new()

						var_83_1:populate(iter_83_1)
						table.insert(var_83_0, var_83_1)
					end

					xyd.formatRegionArenaHeros(var_83_0)

					var_80_1.herosA = var_83_0
				end

				if arg_83_1.pet_info then
					local var_83_2 = var_0_2.new()

					var_83_2:populate(arg_83_1.pet_info)
					xyd.formatRegionArenaPets({
						var_83_2
					})

					var_80_1.petsA = {
						var_83_2
					}
				end

				xyd.WindowManager.get():hideAllWindows()

				var_80_1.isNewLoading = true
				var_80_1.my_id = arg_80_0.fighterInfo.my_id
				var_80_1.enemyRegionName = arg_80_0.enemyServerName
				var_80_1.selfRegionName = arg_80_0.selfRegionName
				var_80_1.selfRegion = arg_80_0.selfPlayer.region
				var_80_1.enemyRegion = arg_80_0.enemyRegion
				var_80_1.enemyName = arg_80_0.enemyName
				var_80_1.myName = arg_80_0.selfPlayer.playerName

				if arg_80_0.enemyGuildName then
					var_80_1.enemyGuild = arg_80_0.enemyGuildName
				end

				if arg_80_0.guild.guild_name then
					var_80_1.myGuild = arg_80_0.guild.guild_name
				end

				xyd.LoadingProxy.get():openBattleLoading(var_80_1)
			else
				arg_80_0.battleBegan = false
			end
		end)
	else
		local var_80_4 = var_0_5:translation("BATTLE_BACKEND_ERROR")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_80_4
		})
		xyd.WindowManager.get():closeWindow(arg_80_0.name)

		return
	end
end

function var_0_0.getFormationStr(arg_84_0, arg_84_1)
	local var_84_0 = ""

	for iter_84_0, iter_84_1 in ipairs(arg_84_1) do
		var_84_0 = var_84_0 .. string.format("%d", iter_84_1:getTableID())

		if iter_84_0 < #arg_84_1 then
			var_84_0 = var_84_0 .. "|"
		end
	end

	return var_84_0
end

function var_0_0.size(arg_85_0, arg_85_1, arg_85_2)
	return {
		width = arg_85_1,
		height = arg_85_2
	}
end

function var_0_0.selectStateMonitor(arg_86_0)
	if not arg_86_0.handle then
		arg_86_0.warnEffect:setVisible(false)

		arg_86_0.handle = var_0_7.scheduleGlobal(function()
			local var_87_0
			local var_87_1 = {}

			if arg_86_0.countDown < 10 then
				local var_87_2 = "0" .. tostring(arg_86_0.countDown)
			else
				local var_87_3 = tostring(arg_86_0.countDown)
			end

			if arg_86_0.selectState == 0 then
				var_87_1 = arg_86_0.selfSelectState

				arg_86_0:nodeByName("count_down_1"):setString(var_0_5:translation("REGION_ARENA_TIP47"))
				arg_86_0:nodeByName("count"):setString(arg_86_0.countDown)
				arg_86_0:nodeByName("count_down_2"):setString(var_0_5:translation("REGION_ARENA_TIP46"))
			else
				var_87_1 = arg_86_0.enemySelectState

				arg_86_0:nodeByName("count_down_1"):setString(var_0_5:translation("REGION_ARENA_TIP45"))
				arg_86_0:nodeByName("count"):setString(arg_86_0.countDown)
				arg_86_0:nodeByName("count_down_2"):setString(var_0_5:translation("REGION_ARENA_TIP46"))
			end

			if arg_86_0.countDown <= 5 and arg_86_0.countDown > -1 then
				arg_86_0.warnEffect:setVisible(true)
			else
				arg_86_0.warnEffect:setVisible(false)
			end

			arg_86_0.countDown = arg_86_0.countDown - 1

			if arg_86_0.countDown < 0 and arg_86_0.selectState == 0 then
				var_0_7.unscheduleGlobal(arg_86_0.handle)

				arg_86_0.handle = nil
				arg_86_0.selectState = 1 - arg_86_0.selectState

				arg_86_0:autoSelectHeros(var_87_1)
			end
		end, 1)
	end
end

function var_0_0.autoSelectHeros(arg_88_0)
	local function var_88_0()
		if not arg_88_0.battleBtn_ then
			arg_88_0.battleBtn_ = arg_88_0:nodeByName("button_ok")
		end

		arg_88_0.battleBtn_:setBright(false)
		arg_88_0.battleBtn_:setTouchEnabled(false)
		arg_88_0:lockTeamCells()

		arg_88_0.countDown = var_0_13

		arg_88_0:updateSelfSelectStates()

		arg_88_0.enemyOldProgress = arg_88_0.enemyProgress

		if 5 - arg_88_0.enemyOldProgress > 1 then
			arg_88_0:selectStateMonitor()

			arg_88_0.enemyProgress = arg_88_0.enemyProgress + 2

			arg_88_0:controllLock(1)

			local var_89_0 = {
				message = var_0_5:translation("REGION_ARENA_TIP13")
			}

			xyd.WindowManager.get():openWindow("finding_enemy", var_89_0)
			arg_88_0:selectEnemyHeros(arg_88_0.enemyOldProgress, arg_88_0.enemyProgress)
		elseif 5 - arg_88_0.enemyOldProgress == 1 then
			arg_88_0:selectStateMonitor()

			arg_88_0.enemyProgress = arg_88_0.enemyProgress + 1

			arg_88_0:controllLock(1)

			local var_89_1 = {
				message = var_0_5:translation("REGION_ARENA_TIP13")
			}

			xyd.WindowManager.get():openWindow("finding_enemy", var_89_1)
			arg_88_0:selectEnemyHeros(arg_88_0.enemyOldProgress, arg_88_0.enemyProgress)
		else
			if arg_88_0.handle then
				var_0_7.unscheduleGlobal(arg_88_0.handle)

				arg_88_0.handle = nil
			end

			var_0_7.performWithDelayGlobal(function()
				if arg_88_0.startBattle and not arg_88_0.battleBegan then
					arg_88_0:choosePet()
				end
			end, 1)
		end
	end

	local var_88_1 = arg_88_0.selfProgress - #arg_88_0.select_

	if var_88_1 == 0 then
		var_88_0()
	else
		for iter_88_0 = 1, var_88_1 do
			local var_88_2 = arg_88_0:getMaxForceValidHero()
			local var_88_3

			if arg_88_0.heroCells_[var_88_2:getTableID()] and not tolua.isnull(arg_88_0.heroCells_[var_88_2:getTableID()]) then
				var_88_3 = arg_88_0.heroCells_[var_88_2:getTableID()]
			else
				var_88_3 = display.newNode()

				var_88_3:retain()
				var_88_3:setPosition(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2)
				arg_88_0:initHeroCell(var_88_3, nil, var_88_2)
			end

			if iter_88_0 == var_88_1 and var_88_1 ~= 1 then
				var_0_7.performWithDelayGlobal(function()
					if arg_88_0.clickAvatar then
						arg_88_0:clickAvatar(var_88_3, nil, true)
						var_88_3:release()
						var_88_0()
					end
				end, 0.5)
			elseif var_88_1 == 1 then
				arg_88_0:clickAvatar(var_88_3, nil, true)
				var_88_0()
			else
				arg_88_0:clickAvatar(var_88_3, nil, true)
			end

			table.remove(arg_88_0.forceHeros, 1)
		end
	end
end

function var_0_0.getMaxForceValidHero(arg_92_0)
	local var_92_0 = arg_92_0.forceHeros[1]

	while var_92_0 and (var_92_0.isDead or not arg_92_0:checkHeroValid(var_92_0)) do
		table.remove(arg_92_0.forceHeros, 1)

		var_92_0 = arg_92_0.forceHeros[1]
	end

	return var_92_0
end

function var_0_0.getUnlockHeroNum(arg_93_0, arg_93_1)
	local var_93_0 = 0

	for iter_93_0, iter_93_1 in ipairs(arg_93_1) do
		if iter_93_1 == 1 then
			var_93_0 = var_93_0 + 1
		end
	end

	return var_93_0
end

function var_0_0.updateSelfSelectStates(arg_94_0)
	for iter_94_0 = 1, arg_94_0.selfProgress do
		arg_94_0.selfSelectState[iter_94_0] = 1
	end
end

function var_0_0.updateEnemySelectStates(arg_95_0)
	for iter_95_0 = 1, arg_95_0.enemyProgress do
		arg_95_0.enemySelectState[iter_95_0] = 1
	end
end

function var_0_0.selectEnemyHeros(arg_96_0, arg_96_1, arg_96_2)
	arg_96_0.battleBtn_:setBright(false)
	arg_96_0.battleBtn_:setTouchEnabled(false)

	local var_96_0 = arg_96_0:nodeByName("battle_team_bg")
	local var_96_1 = arg_96_2 - arg_96_1

	var_0_7.performWithDelayGlobal(function()
		if arg_96_0.enemyHeroes_ and arg_96_0.selectEnemyHeros_ then
			arg_96_0:createEnemyHeroAvatarAndMotion()

			if var_96_1 > 1 then
				var_0_7.performWithDelayGlobal(function()
					if arg_96_0.enemyHeroes_ and arg_96_0.selectEnemyHeros_ then
						arg_96_0:createEnemyHeroAvatarAndMotion()

						arg_96_0.selectState = 1 - arg_96_0.selectState
						arg_96_0.countDown = var_0_13

						arg_96_0:updateEnemySelectStates()

						if xyd.WindowManager.get():getWindow("finding_enemy") then
							xyd.WindowManager.get():closeWindow("finding_enemy")
						end

						arg_96_0.selfOldProgress = arg_96_0.selfProgress

						if 5 - arg_96_0.selfOldProgress >= 1 then
							arg_96_0.battleBtn_:setBright(true)
							arg_96_0.battleBtn_:setTouchEnabled(true)
						end

						if 5 - arg_96_0.selfOldProgress > 1 then
							arg_96_0.selfProgress = arg_96_0.selfProgress + 2

							arg_96_0:controllLock(0)

							local var_98_0 = var_0_5:translation("REGION_ARENA_TIP16")

							xyd.WindowManager.get():openWindow("toast", {
								message = var_98_0
							})
						elseif 5 - arg_96_0.selfOldProgress == 1 then
							arg_96_0.selfProgress = arg_96_0.selfProgress + 1

							arg_96_0:controllLock(0)

							local var_98_1 = var_0_5:translation("REGION_ARENA_TIP15")

							xyd.WindowManager.get():openWindow("toast", {
								message = var_98_1
							})
						else
							if arg_96_0.handle then
								var_0_7.unscheduleGlobal(arg_96_0.handle)

								arg_96_0.handle = nil
							end

							var_0_7.performWithDelayGlobal(function()
								if arg_96_0.startBattle and not arg_96_0.battleBegan then
									arg_96_0:choosePet()
								end
							end, 1)
						end
					end
				end, 0.2)
			else
				arg_96_0.selectState = 1 - arg_96_0.selectState
				arg_96_0.countDown = var_0_13

				arg_96_0:updateEnemySelectStates()

				arg_96_0.selfOldProgress = arg_96_0.selfProgress

				if 5 - arg_96_0.selfOldProgress >= 1 then
					arg_96_0.battleBtn_:setBright(true)
					arg_96_0.battleBtn_:setTouchEnabled(true)
				end

				if 5 - arg_96_0.selfOldProgress > 1 then
					arg_96_0.selfProgress = arg_96_0.selfProgress + 2

					arg_96_0:controllLock(0)

					local var_97_0 = var_0_5:translation("REGION_ARENA_TIP16")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_97_0
					})
				elseif 5 - arg_96_0.selfOldProgress == 1 then
					arg_96_0.selfProgress = arg_96_0.selfProgress + 1

					arg_96_0:controllLock(0)

					local var_97_1 = var_0_5:translation("REGION_ARENA_TIP15")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_97_1
					})
				else
					if arg_96_0.handle then
						var_0_7.unscheduleGlobal(arg_96_0.handle)

						arg_96_0.handle = nil
					end

					var_0_7.performWithDelayGlobal(function()
						arg_96_0:choosePet()
					end, 1)
				end

				if xyd.WindowManager.get():getWindow("finding_enemy") then
					xyd.WindowManager.get():closeWindow("finding_enemy")
				end
			end
		end
	end, 0.1)
end

function var_0_0.choosePet(arg_101_0)
	if arg_101_0.choosingPet then
		arg_101_0:startBattle()
	else
		arg_101_0.choosingPet = true

		arg_101_0:createEnemyPetAvatarAndMotion()
		arg_101_0.battleBtn_:setBright(true)
		arg_101_0.battleBtn_:setTouchEnabled(true)

		for iter_101_0, iter_101_1 in ipairs(arg_101_0.leftMenuButtons_) do
			iter_101_1:setBrightStyle(var_0_17.SELF_PET == iter_101_1.menu_type and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
		end

		arg_101_0.leftMenuType_ = var_0_17.SELF_PET
		arg_101_0.totalPet_ = arg_101_0.tmpTotalPets[var_0_16.SELF_PET]

		arg_101_0:refreshSelectedHeroClass()

		if not arg_101_0.handle then
			arg_101_0.warnEffect:setVisible(false)

			arg_101_0.handle = var_0_7.scheduleGlobal(function()
				local var_102_0
				local var_102_1 = {}

				if arg_101_0.countDown < 10 then
					local var_102_2 = "0" .. tostring(arg_101_0.countDown)
				else
					local var_102_3 = tostring(arg_101_0.countDown)
				end

				local var_102_4 = arg_101_0.selfSelectState

				arg_101_0:nodeByName("count_down_1"):setString(var_0_5:translation("REGION_ARENA_TIP47"))
				arg_101_0:nodeByName("count"):setString(arg_101_0.countDown)
				arg_101_0:nodeByName("count_down_2"):setString(var_0_5:translation("REGION_ARENA_TIP51"))

				if arg_101_0.countDown <= 5 and arg_101_0.countDown > -1 then
					arg_101_0.warnEffect:setVisible(true)
				else
					arg_101_0.warnEffect:setVisible(false)
				end

				arg_101_0.countDown = arg_101_0.countDown - 1

				if arg_101_0.countDown <= 0 then
					var_0_7.unscheduleGlobal(arg_101_0.handle)

					arg_101_0.handle = nil

					arg_101_0:startBattle()
				end
			end, 1)
		end
	end
end

function var_0_0.createEnemyHeroAvatarAndMotion(arg_103_0)
	local var_103_0 = display.newNode()

	var_103_0:setContentSize(var_0_15, var_0_15)
	var_103_0:setAnchorPoint(cc.p(0.5, 0.5))

	local var_103_1 = arg_103_0:getRandomEnemyHero()

	xyd.setAvatarBorderNewUI(var_103_1, var_103_0, nil, nil, nil, nil, nil)
	var_103_0:addTo(arg_103_0:nodeByName("battle_team_bg"))

	var_103_0.distanceType = var_103_1:getDistanceType()

	table.insert(arg_103_0.enemyHerosAvatars, var_103_0)
	arg_103_0:sortHeroAvatarsByDistance(arg_103_0.enemyHerosAvatars)

	local var_103_2 = table.keyof(arg_103_0.enemyHerosAvatars, var_103_0)

	var_103_0:setPositionX(arg_103_0:nodeByName("enemy_hero_" .. var_103_2):getPositionX())
	var_103_0:setPositionY(arg_103_0:nodeByName("enemy_hero_" .. var_103_2):getPositionY() + 50)
	arg_103_0:moveHeroAvatar(var_103_2)
end

function var_0_0.createEnemyPetAvatarAndMotion(arg_104_0)
	if not arg_104_0.enemyPet then
		return
	end

	local var_104_0 = display.newNode()

	var_104_0:setContentSize(var_0_15, var_0_15)
	var_104_0:setAnchorPoint(cc.p(0.5, 0.5))
	xyd.setPetAvatarNewUI(var_104_0, arg_104_0.enemyPet, 100, true)
	var_104_0:addTo(arg_104_0:nodeByName("enemy_pet_container"))
	var_104_0:setPositionX(arg_104_0:nodeByName("enemy_pet_container"):getContentSize().width / 2)
	var_104_0:setPositionY(arg_104_0:nodeByName("enemy_pet_container"):getContentSize().height / 2 + 50)
	var_104_0:runAction(cc.MoveBy:create(0.2, cc.p(0, -50)))
end

function var_0_0.getRandomEnemyHero(arg_105_0)
	local var_105_0 = math.random(#arg_105_0.selectEnemyHeros_)
	local var_105_1 = arg_105_0.selectEnemyHeros_[var_105_0]

	table.remove(arg_105_0.selectEnemyHeros_, var_105_0)

	return var_105_1
end

function var_0_0.sortHeroAvatarsByDistance(arg_106_0, arg_106_1)
	table.sort(arg_106_1, function(arg_107_0, arg_107_1)
		if arg_107_0.distanceType ~= arg_107_1.distanceType then
			return arg_107_0.distanceType < arg_107_1.distanceType
		end
	end)
end

function var_0_0.moveHeroAvatar(arg_108_0, arg_108_1)
	arg_108_0.enemyHerosAvatars[arg_108_1]:runAction(cc.MoveBy:create(0.2, cc.p(0, -50)))

	if arg_108_1 < #arg_108_0.enemyHerosAvatars then
		for iter_108_0 = arg_108_1 + 1, #arg_108_0.enemyHerosAvatars do
			arg_108_0.enemyHerosAvatars[iter_108_0]:runAction(cc.MoveBy:create(0.2, cc.p(-120, 0)))
		end
	end
end

return var_0_0
