local var_0_0 = class("SyncSelectTeamWindow", import("app.common.ui.BaseWindow"))
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
local var_0_12 = 29
local var_0_13 = "skeletons/ui_effect/effect_kfjjc/effect_kfjjc1"
local var_0_14 = 98
local var_0_15 = {
	RENT_PET = 2,
	SELF_PET = 1
}
local var_0_16 = {
	RENT_HERO = 2,
	SELF_HERO = 1,
	SELF_PET = 3
}
local var_0_17 = {
	YES = 2,
	NO = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2, arg_1_3)
	print(collectgarbage("count"), "KB")
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.callback = arg_1_3

	cc.Director:getInstance():purgeCachedData()
	collectgarbage("collect")

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
	arg_1_0.playoffsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYOFFS)
	arg_1_0.regionCasualArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_CASUAL_ARENA)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.type = arg_1_2.type or xyd.SelectTeamType.REGION_ARENA
	arg_1_0.campaignType = arg_1_2.campaignType or xyd.CampaignType.REGION_ARENA
	arg_1_0.lockTime = 0
	arg_1_0.pet = {}

	if arg_1_0.selfPlayer.playerID == arg_1_2.params.record_info.A_player_id then
		if arg_1_2.params.record_info.team_1 ~= "" then
			arg_1_0.team_1 = xyd.splitToNumber(xyd.split(arg_1_2.params.record_info.team_1, "|")[1], ":")
		end

		if arg_1_2.params.record_info.team_2 ~= "" then
			arg_1_0.team_2 = xyd.splitToNumber(xyd.split(arg_1_2.params.record_info.team_2, "|")[1], ":")
		end

		if arg_1_2.params.record_info.team_3 ~= "" then
			arg_1_0.team_3 = xyd.splitToNumber(xyd.split(arg_1_2.params.record_info.team_3, "|")[1], ":")
		end

		for iter_1_0 = 1, 3 do
			arg_1_0.pet[iter_1_0] = xyd.splitToNumber(arg_1_2.params.record_info["pet_id_" .. iter_1_0], "|")[1]
		end
	else
		if arg_1_2.params.record_info.team_1 ~= "" then
			arg_1_0.team_1 = xyd.splitToNumber(xyd.split(arg_1_2.params.record_info.team_1, "|")[2], ":")
		end

		if arg_1_2.params.record_info.team_2 ~= "" then
			arg_1_0.team_2 = xyd.splitToNumber(xyd.split(arg_1_2.params.record_info.team_2, "|")[2], ":")
		end

		if arg_1_2.params.record_info.team_3 ~= "" then
			arg_1_0.team_3 = xyd.splitToNumber(xyd.split(arg_1_2.params.record_info.team_3, "|")[2], ":")
		end

		for iter_1_1 = 1, 3 do
			arg_1_0.pet[iter_1_1] = xyd.splitToNumber(arg_1_2.params.record_info["pet_id_" .. iter_1_1], "|")[2]
		end
	end

	if arg_1_0.selfPlayer.playerID == arg_1_2.A_player_id then
		arg_1_0.firstSelect = 0
	else
		arg_1_0.firstSelect = 1
	end

	if arg_1_0.firstSelect == 0 then
		arg_1_0.enemyID = arg_1_2.B_player_id
		arg_1_0.enemyAvatarID = arg_1_2.B_player_info.avatar_id
		arg_1_0.enemyAvatarFrameID = arg_1_2.B_player_info.avatar_frame_id
	else
		arg_1_0.enemyID = arg_1_2.A_player_id
		arg_1_0.enemyAvatarID = arg_1_2.A_player_info.avatar_id
		arg_1_0.enemyAvatarFrameID = arg_1_2.A_player_info.avatar_frame_id
	end

	arg_1_0.isBackendBattle = 1
	arg_1_0.totalteams = 3

	if arg_1_2.params.record_info.game_type then
		arg_1_0.isfriend = true
		arg_1_0.game_type = arg_1_2.params.record_info.game_type
		arg_1_0.model = arg_1_2.params.record_info.model

		if arg_1_0.game_type == 1 then
			arg_1_0.totalteams = 1
		end
	end

	if arg_1_2.params.record_info.battle_type and arg_1_2.params.record_info.battle_type == 3 then
		arg_1_0.isCasual = true
	end

	arg_1_0.room_key = arg_1_2.room_key

	if arg_1_2.stage and arg_1_2.stage - 1 > 0 then
		arg_1_0.stage = arg_1_2.stage - 1
	elseif arg_1_2.stage == 1 then
		arg_1_0.stage = 0.5
	else
		arg_1_0.stage = 0
	end

	if arg_1_2.params.team_id then
		arg_1_0.team_id = arg_1_2.params.team_id
	end

	arg_1_0.petTeam_ = {}
	arg_1_0.petCells_ = {}
	arg_1_0.petSelect_ = {}
	arg_1_0.totalHero_ = {}
	arg_1_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_1_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.FILTER] = {}
	arg_1_0.totalHero_[xyd.DistanceType.SEARCH] = {}

	for iter_1_2, iter_1_3 in pairs(arg_1_0.totalHero_) do
		iter_1_3[var_0_17.NO] = {}
		iter_1_3[var_0_17.YES] = {}
	end

	arg_1_0.searchTxt = ""
	arg_1_0.totalIDs_ = {}
	arg_1_0.detailparams = arg_1_2
	arg_1_0.team_ = {}
	arg_1_0.select_ = {}
	arg_1_0.preSelect_ = arg_1_2.selected or {}
	arg_1_0.enemyHeroes_ = {}
	arg_1_0.battleBegan = false
	arg_1_0.selectedHeroClass_ = {}
	arg_1_0.tmpTotalPets = {}
	arg_1_0.choosingPet = false
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
	arg_1_0.collocationType_ = var_0_17.NO
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
	local var_4_0 = var_0_13 .. ".json"
	local var_4_1 = var_0_13 .. ".atlas"

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
	arg_5_0.tempSelectHeros = {}
	arg_5_0.enemyGuildName = arg_5_1.enemyGuildName
	arg_5_0.enemyName = arg_5_1.enemyName
	arg_5_0.enemyServerName = arg_5_1.enemyServerName
	arg_5_0.selfRegionName = arg_5_1.selfRegionName
	arg_5_0.enemyRegion = arg_5_1.enemyRegion
	arg_5_0.selectState = clone(arg_5_0.firstSelect)
	arg_5_0.countDown = var_0_12
	arg_5_0.stageStartTime = xyd.ServerTime.get():getServerTime()

	arg_5_0:initWarnEffect()
	arg_5_0:selectStateMonitor()
	arg_5_0:initLabel()

	arg_5_0.battleBegan = false
	arg_5_0.awards = arg_5_0.regionArena.awards

	arg_5_0.socialSystem:loadFriends()

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

	if arg_5_0.team_id >= 3 then
		for iter_5_4 = 1, #arg_5_0.team_2 do
			for iter_5_5, iter_5_6 in pairs(var_5_0) do
				if iter_5_6:getHeroID() == arg_5_0.team_2[iter_5_4] then
					table.remove(var_5_0, iter_5_5)
				end
			end
		end

		for iter_5_7, iter_5_8 in pairs(var_5_2) do
			if iter_5_8:getPetID() == arg_5_0.pet[2] then
				table.remove(var_5_2, iter_5_7)
			end
		end
	end

	if arg_5_0.team_id >= 2 then
		for iter_5_9 = 1, #arg_5_0.team_1 do
			for iter_5_10, iter_5_11 in pairs(var_5_0) do
				if iter_5_11:getHeroID() == arg_5_0.team_1[iter_5_9] then
					table.remove(var_5_0, iter_5_10)
				end
			end
		end

		for iter_5_12, iter_5_13 in pairs(var_5_2) do
			if iter_5_13:getPetID() == arg_5_0.pet[1] then
				table.remove(var_5_2, iter_5_12)
			end
		end
	end

	if not arg_5_0.model or arg_5_0.model ~= 1 then
		xyd.formatRegionArenaHerosAwake(var_5_0)
		xyd.formatRegionArenaPetsAwake(var_5_2)
	end

	arg_5_0.leftMenuType_ = var_0_16.SELF_HERO

	arg_5_0:initHeros(var_5_0)
	arg_5_0:initPets(var_5_2 or {}, var_0_15.SELF_PET)

	arg_5_0.selectedHeroClass_[arg_5_0.leftMenuType_] = xyd.DistanceType.ALL

	arg_5_0:layout()
end

function var_0_0.controllLock(arg_6_0, arg_6_1)
	if arg_6_1 == 0 then
		for iter_6_0 = 1, arg_6_0.selfProgress do
			arg_6_0.selfLocks[iter_6_0]:setVisible(false)
		end
	else
		for iter_6_1 = 1, arg_6_0.enemyProgress do
			arg_6_0.enemyLocks[iter_6_1]:setVisible(false)
		end
	end
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	arg_7_0.super.didOpen(arg_7_0, arg_7_1)
	arg_7_0:refreshSelectedHeroClass()
	arg_7_0:getBattleBtn()
	arg_7_0:initComingSelect()
	arg_7_0:nodeByName("close"):setVisible(false)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.UPDATE_FILTER_HEROS, handler(arg_7_0, arg_7_0.updateList))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.HERO_SEARCH, handler(arg_7_0, arg_7_0.updateListBySearchTxt))

	if arg_7_0.callback then
		arg_7_0.callback()
	end
end

function var_0_0.updateList(arg_8_0, ...)
	arg_8_0.searchTxt = ""
	arg_8_0.selectedHeroClass_[arg_8_0.leftMenuType_] = xyd.DistanceType.FILTER

	arg_8_0:updateFilterHeros()
	arg_8_0:refreshSelectedHeroClass()
end

function var_0_0.updateListBySearchTxt(arg_9_0, arg_9_1)
	arg_9_0.searchTxt = arg_9_1.heroName
	arg_9_0.selectedHeroClass_[arg_9_0.leftMenuType_] = xyd.DistanceType.SEARCH

	arg_9_0:updateSearchHeros()
	arg_9_0:refreshSelectedHeroClass()
end

function var_0_0.willClose(arg_10_0)
	if arg_10_0.handle then
		var_0_7.unscheduleGlobal(arg_10_0.handle)
	end

	if arg_10_0.requestHandler then
		var_0_7.unscheduleGlobal(arg_10_0.requestHandler)
	end

	if xyd.WindowManager.get():getWindow("finding_enemy") then
		xyd.WindowManager.get():closeWindow("finding_enemy")
	end
end

function var_0_0.sortTables(arg_11_0, arg_11_1)
	table.sort(arg_11_1, function(arg_12_0, arg_12_1)
		if arg_12_0.region_arena_times ~= arg_12_1.region_arena_times then
			return arg_12_0.region_arena_times > arg_12_1.region_arena_times
		end

		return xyd.heroNormalSort(arg_12_0, arg_12_1) or false
	end)
end

function var_0_0.sortHerosByForce(arg_13_0, arg_13_1)
	table.sort(arg_13_1, function(arg_14_0, arg_14_1)
		if arg_14_0:getZhandouli() ~= arg_14_1:getZhandouli() then
			return arg_14_0:getZhandouli() > arg_14_1:getZhandouli()
		end
	end)
end

function var_0_0.exitScene(arg_15_0)
	arg_15_0:dispatchEvent({
		name = xyd.event.EXIT_BATTLE_PREPARE
	})
end

function var_0_0.layout(arg_16_0)
	arg_16_0:initMenu()
	arg_16_0:initLeftMenu()
	arg_16_0:nodeByName("text_bg"):setVisible(false)

	local var_16_0 = arg_16_0:nodeByName("list_layer_battle")
	local var_16_1 = var_16_0:getContentSize().width
	local var_16_2 = var_16_0:getContentSize().height

	arg_16_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_16_1, var_16_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_16_0)

	arg_16_0.heroList_:setDelegate(handler(arg_16_0, arg_16_0.delegate))
	arg_16_0:updateScore()
end

function var_0_0.delegate(arg_17_0, ...)
	if arg_17_0.leftMenuType_ == var_0_16.SELF_PET or arg_17_0.leftMenuType_ == var_0_16.RENT_HERO and arg_17_0.rentMenuType == RentMenuType.RENT_PET then
		return arg_17_0:petDelegate(...)
	end

	return arg_17_0:heroDelegate(...)
end

function var_0_0.petDelegate(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	local var_18_0
	local var_18_1 = arg_18_0.leftMenuType_ == var_0_16.SELF_PET and 6 or 6
	local var_18_2 = math.ceil(#arg_18_0.totalPet_ / var_18_1)

	if cc.ui.UIListView.COUNT_TAG == arg_18_2 then
		return var_18_2
	elseif cc.ui.UIListView.CELL_TAG == arg_18_2 then
		local var_18_3
		local var_18_4
		local var_18_5
		local var_18_6 = arg_18_0.heroList_:dequeueItem()

		if not var_18_6 then
			var_18_6 = arg_18_0.heroList_:newItem()
		else
			var_18_6:removeAllChildren()
		end

		local var_18_7 = display.newNode()

		var_18_7:setTouchSwallowEnabled(false)

		for iter_18_0 = 1, var_18_1 do
			local var_18_8 = (arg_18_3 - 1) * var_18_1 + iter_18_0

			if var_18_8 > #arg_18_0.totalPet_ then
				break
			end

			var_18_5 = display.newNode()

			arg_18_0:initPetCell(var_18_5, var_18_8)

			local var_18_9 = var_18_5:getContentSize().width
			local var_18_10 = var_18_5:getContentSize().height
			local var_18_11 = (arg_18_0.heroList_.viewRect_.width - var_18_9 * var_18_1) / (var_18_1 + 1)

			var_18_5:align(display.CENTER, var_18_11 * iter_18_0 + (iter_18_0 - 1) * var_18_9 + var_18_9 / 2, var_18_10 / 2)
			var_18_7:addChild(var_18_5)
		end

		var_18_7:setContentSize(cc.size(arg_18_0.heroList_.viewRect_.width, var_18_5:getContentSize().height))
		var_18_6:setItemSize(arg_18_0.heroList_.viewRect_.width, var_18_5:getContentSize().height)
		var_18_6:addContent(var_18_7)

		return var_18_6
	end
end

function var_0_0.clickPetAvatar(arg_19_0, arg_19_1, arg_19_2)
	if #arg_19_0.petTeam_ == xyd.MAX_PET_NUMBER and arg_19_0.petTeam_[1].data:getTableID() == arg_19_1.data:getTableID() then
		local var_19_0 = arg_19_0.petTeam_[1]

		arg_19_0:clickPetBottomAvatar(var_19_0, function()
			return
		end)

		return
	elseif #arg_19_0.petTeam_ == xyd.MAX_PET_NUMBER then
		local var_19_1 = arg_19_0.petTeam_[1]

		arg_19_0:clickPetBottomAvatar(var_19_1, function()
			arg_19_0:clickPetAvatar(arg_19_1, arg_19_2)
		end)

		return
	end

	local var_19_2
	local var_19_3 = arg_19_1:getChildByName("layout")
	local var_19_4 = var_19_3:getChildByName("avatar_mask")
	local var_19_5 = var_19_3:getChildByName("chosen")
	local var_19_6 = arg_19_1:convertToWorldSpace(cc.p(0, 0))
	local var_19_7 = var_19_6.x
	local var_19_8 = var_19_6.y

	arg_19_1.isAnimated_ = false

	if arg_19_1.teamNo_ then
		local var_19_9 = arg_19_0.petTeam_[arg_19_1.teamNo_]

		var_19_4:setVisible(false)
		var_19_5:setVisible(false)

		for iter_19_0 = #arg_19_0.petTeam_, arg_19_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_19_0.petTeam_[iter_19_0])

			local var_19_10, var_19_11 = arg_19_0:nodeByName("avatar_pet" .. iter_19_0 - 1):getPosition()

			arg_19_0.petTeam_[iter_19_0]:setPosition(var_19_10, var_19_11)

			arg_19_0.petTeam_[iter_19_0].iniCell_.teamNo_ = iter_19_0 - 1
		end

		if arg_19_1.type == var_0_15.RENT_PET then
			arg_19_0.isSelectMerPet = false
			arg_19_0.selectMerPet = nil
		end

		table.remove(arg_19_0.petTeam_, arg_19_1.teamNo_)
		table.remove(arg_19_0.petSelect_, arg_19_1.teamNo_)

		arg_19_1.teamNo_ = nil
	elseif not arg_19_1.teamNo_ and #arg_19_0.petTeam_ < xyd.MAX_PET_NUMBER then
		local var_19_12 = arg_19_1.data

		if not arg_19_2 and var_0_6:chosenSound(var_19_12:getTableID()) ~= "" then
			xyd.AssetDownload.get():preloadCharacterSound({
				var_19_12:getTableID()
			}, function()
				return
			end, true)
			audio.playSound(var_0_6:chosenSound(var_19_12:getTableID()), false)
		end

		local var_19_13 = arg_19_0:initPetBottomCell(var_19_12)

		var_19_13.iniCell_ = arg_19_1

		var_19_13:pos(var_19_7, var_19_8)
		var_19_13:addTo(arg_19_0)
		var_19_13:setTouchEnabled(true)
		var_19_13:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
			if arg_23_0.name == "ended" then
				if arg_19_0.selfChoosingPet ~= 1 then
					return true
				end

				arg_19_0:clickPetBottomAvatar(var_19_13)
			end

			return true
		end)

		if arg_19_1.type == var_0_15.RENT_PET then
			arg_19_0.isSelectMerPet = true
			arg_19_0.selectMerPet = var_19_12
		end

		arg_19_1.teamNo_ = arg_19_0:getPetTeamNo(var_19_13)

		for iter_19_1 = arg_19_1.teamNo_, #arg_19_0.petTeam_ do
			local var_19_14, var_19_15 = arg_19_0:nodeByName("avatar_pet" .. iter_19_1):getPosition()

			if arg_19_2 then
				arg_19_0.petTeam_[iter_19_1]:pos(var_19_14, var_19_15)

				arg_19_1.isAnimated_ = false
			elseif iter_19_1 ~= arg_19_1.teamNo_ then
				arg_19_0.petTeam_[iter_19_1]:setPosition(var_19_14, var_19_15)
			else
				local var_19_16 = arg_19_0.petTeam_[iter_19_1]

				transition.stopTarget(var_19_16)

				var_19_13.isAnimated_ = false

				var_19_16:setPosition(var_19_14, var_19_15)
			end

			arg_19_0.petTeam_[iter_19_1].iniCell_.teamNo_ = iter_19_1
		end

		var_19_4:setVisible(true)
		var_19_5:setVisible(true)
	end

	arg_19_0:updateScore()
end

function var_0_0.initPetCell(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = arg_24_0.totalPet_[arg_24_2]

	arg_24_1:align(display.CENTER):size(146, 146)
	xyd.setPetAvatarNewUI(arg_24_1, var_24_0, 100)

	arg_24_1.type = var_0_15.SELF_PET
	arg_24_1.data = var_24_0

	arg_24_1:setTouchEnabled(true)
	arg_24_1:setTouchSwallowEnabled(false)
	arg_24_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_25_0)
		arg_24_0:buttonHandler(nil, arg_24_1, arg_25_0)

		if arg_25_0.name == "began" then
			arg_24_0.startClick_ = true
			arg_24_0.prevX_ = arg_25_0.x
			arg_24_0.prevY_ = arg_25_0.y
		elseif arg_25_0.name == "moved" then
			if math.abs(arg_25_0.y - arg_24_0.prevY_) > 5 or math.abs(arg_25_0.x - arg_24_0.prevX_) > 5 then
				arg_24_0.startClick_ = false
			end
		elseif arg_25_0.name == "ended" and arg_24_0.startClick_ then
			local var_25_0 = var_24_0.rent_need_mana

			if arg_24_0.selfChoosingPet ~= 1 then
				return true
			end

			arg_24_0:clickPetAvatar(arg_24_1)
		end

		return true
	end)

	for iter_24_0, iter_24_1 in ipairs(arg_24_0.petTeam_) do
		if var_24_0 == iter_24_1.data then
			arg_24_0.petTeam_[iter_24_0].iniCell_ = arg_24_1
			arg_24_1.teamNo_ = iter_24_0

			local var_24_1
			local var_24_2 = arg_24_1:getChildByName("layout")
			local var_24_3 = var_24_2:getChildByName("avatar_mask")
			local var_24_4 = var_24_2:getChildByName("chosen")

			var_24_3:setVisible(true)
			var_24_4:setVisible(true)

			break
		end
	end

	arg_24_0.petCells_[var_24_0:getTableID()] = arg_24_1
end

function var_0_0.clickPetBottomAvatar(arg_26_0, arg_26_1, arg_26_2)
	if arg_26_1.isAnimated_ then
		return
	end

	local var_26_0, var_26_1 = arg_26_0:nodeByName("list_layer"):getPosition()
	local var_26_2 = arg_26_1.iniCell_
	local var_26_3

	for iter_26_0, iter_26_1 in ipairs(arg_26_0.petSelect_) do
		if iter_26_1:getTableID() == arg_26_1.data:getTableID() and iter_26_1.player_name == arg_26_1.data.player_name then
			var_26_3 = iter_26_0

			break
		end
	end

	if not var_26_3 then
		return
	end

	if var_26_2 and not tolua.isnull(var_26_2) then
		local var_26_4 = var_26_2:convertToWorldSpace(cc.p(0, 0))
		local var_26_5 = var_26_4.x, var_26_4.y
		local var_26_6
		local var_26_7 = var_26_2:getChildByName("layout")
		local var_26_8 = var_26_7:getChildByName("avatar_mask")
		local var_26_9 = var_26_7:getChildByName("chosen")

		var_26_8:setVisible(false)
		var_26_9:setVisible(false)
	end

	arg_26_1:removeSelf()

	for iter_26_2 = #arg_26_0.petTeam_, var_26_3 + 1, -1 do
		local var_26_10, var_26_11 = arg_26_0:nodeByName("avatar_pet" .. iter_26_2 - 1):getPosition()

		arg_26_0.petTeam_[iter_26_2]:setPosition(var_26_10, var_26_11)

		arg_26_0.petTeam_[iter_26_2].iniCell_.teamNo_ = iter_26_2 - 1
	end

	if arg_26_1.type == var_0_15.RENT_PET then
		arg_26_0.isSelectMerPet = false
		arg_26_0.selectMerPet = nil
	end

	table.remove(arg_26_0.petTeam_, var_26_3)
	table.remove(arg_26_0.petSelect_, var_26_3)

	if var_26_2 then
		var_26_2.teamNo_ = nil
	end

	arg_26_0:updateScore()

	if arg_26_2 then
		arg_26_2()
	end
end

function var_0_0.clickPetBottomAvatarWithoutAnimation(arg_27_0, arg_27_1, arg_27_2)
	if arg_27_1.isAnimated_ then
		return
	end

	local var_27_0, var_27_1 = arg_27_0:nodeByName("list_layer"):getPosition()
	local var_27_2 = arg_27_1.iniCell_
	local var_27_3

	for iter_27_0, iter_27_1 in ipairs(arg_27_0.petTeam_) do
		if iter_27_1 == arg_27_1 then
			var_27_3 = iter_27_0

			break
		end
	end

	if not var_27_3 then
		return
	end

	if var_27_2 and not tolua.isnull(var_27_2) then
		local var_27_4 = var_27_2:convertToWorldSpace(cc.p(0, 0))
		local var_27_5
		local var_27_6 = var_27_2:getChildByName("layout")
		local var_27_7 = var_27_6:getChildByName("avatar_mask")
		local var_27_8 = var_27_6:getChildByName("chosen")

		var_27_7:setVisible(false)
		var_27_8:setVisible(false)
	end

	for iter_27_2 = #arg_27_0.petTeam_, var_27_3 + 1, -1 do
		local var_27_9 = arg_27_0.petTeam_[iter_27_2]
		local var_27_10, var_27_11 = arg_27_0:nodeByName("avatar_pet" .. iter_27_2 - 1):getPosition()

		transition.stopTarget(var_27_9)
		transition.moveTo(arg_27_0.petTeam_[iter_27_2], {
			time = 0.3,
			x = var_27_10,
			y = var_27_11
		})

		arg_27_0.petTeam_[iter_27_2].iniCell_.teamNo_ = iter_27_2 - 1
	end

	table.remove(arg_27_0.petTeam_, var_27_3)
	table.remove(arg_27_0.petSelect_, var_27_3)

	if var_27_2 then
		var_27_2.teamNo_ = nil
	end

	if arg_27_1 and not tolua.isnull(arg_27_1) then
		arg_27_1:removeSelf()
	end

	if arg_27_2 then
		arg_27_2()
	end
end

function var_0_0.getPetTeamNo(arg_28_0, arg_28_1)
	table.insert(arg_28_0.petTeam_, arg_28_1)
	table.insert(arg_28_0.petSelect_, arg_28_1.data)

	return #arg_28_0.petTeam_
end

function var_0_0.initPetBottomCell(arg_29_0, arg_29_1)
	local var_29_0 = display.newNode()

	var_29_0:size(146, 146)
	var_29_0:align(display.CENTER)

	var_29_0.data = arg_29_1
	var_29_0.type = var_0_15.SELF_PET

	xyd.setPetAvatarNewUI(var_29_0, arg_29_1, 100)

	return var_29_0
end

function var_0_0.initComingSelect(arg_30_0)
	if arg_30_0.firstSelect == 0 then
		arg_30_0.selfProgress = 1

		arg_30_0:controllLock(0)

		local var_30_0 = var_0_5:translation("REGION_ARENA_TIP14")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_30_0
		})
	else
		arg_30_0.enemyProgress = 1

		arg_30_0:controllLock(1)

		local var_30_1 = {
			message = var_0_5:translation("REGION_ARENA_TIP13")
		}

		xyd.WindowManager.get():openWindow("finding_enemy", var_30_1)
	end
end

function var_0_0.initMenu(arg_31_0)
	arg_31_0.heroClassButtons_ = {}

	table.insert(arg_31_0.heroClassButtons_, arg_31_0:nodeByName("button_all"))
	table.insert(arg_31_0.heroClassButtons_, arg_31_0:nodeByName("button_qianpai"))
	table.insert(arg_31_0.heroClassButtons_, arg_31_0:nodeByName("button_zhongpai"))
	table.insert(arg_31_0.heroClassButtons_, arg_31_0:nodeByName("button_houpai"))
	table.insert(arg_31_0.heroClassButtons_, arg_31_0:nodeByName("button_filter"))
	table.insert(arg_31_0.heroClassButtons_, arg_31_0:nodeByName("button_search"))

	for iter_31_0 = 1, #arg_31_0.heroClassButtons_ do
		arg_31_0.heroClassButtons_[iter_31_0]:setZoomScale(0.3)
		arg_31_0.heroClassButtons_[iter_31_0]:addTouchEventListener(function(arg_32_0, arg_32_1)
			if arg_32_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				if arg_31_0.selectedHeroClass_[arg_31_0.leftMenuType_] == iter_31_0 then
					for iter_32_0 = 1, #arg_31_0.heroClassButtons_ do
						if iter_32_0 == arg_31_0.selectedHeroClass_[arg_31_0.leftMenuType_] then
							arg_31_0.heroClassButtons_[iter_32_0]:setBrightStyle(ccui.BrightStyle.highlight)
						else
							arg_31_0.heroClassButtons_[iter_32_0]:setBrightStyle(ccui.BrightStyle.normal)
						end
					end

					return
				end

				arg_31_0.selectedHeroClass_[arg_31_0.leftMenuType_] = iter_31_0

				arg_31_0:refreshSelectedHeroClass()
			end
		end)
	end

	arg_31_0:nodeByName("button_filter"):addTouchEventListener(function(arg_33_0, arg_33_1)
		xyd.buttonScaleAnim(arg_33_0, arg_33_1)

		if arg_33_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("hero_filter_wnd")
		end
	end)
	arg_31_0:nodeByName("button_search"):addTouchEventListener(function(arg_34_0, arg_34_1)
		xyd.buttonScaleAnim(arg_34_0, arg_34_1)

		if arg_34_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("hero_search_wnd")
		end
	end)
	arg_31_0:nodeByName("button_collocation"):addTouchEventListener(function(arg_35_0, arg_35_1)
		xyd.buttonScaleAnim(arg_35_0, arg_35_1)

		if arg_35_1 == ccui.TouchEventType.ended then
			if arg_31_0.leftMenuType_ ~= var_0_16.SELF_HERO then
				return
			end

			arg_31_0.collocationType_ = 3 - arg_31_0.collocationType_

			arg_31_0:refreshSelectedHeroClass()
		end
	end)
end

function var_0_0.initLeftMenu(arg_36_0)
	arg_36_0:nodeByName("button_zhandui").menu_type = var_0_16.SELF_HERO
	arg_36_0:nodeByName("button_pet").menu_type = var_0_16.SELF_PET
	arg_36_0.leftMenuType_ = var_0_16.SELF_HERO
	arg_36_0.leftMenuButtons_ = {}

	table.insert(arg_36_0.leftMenuButtons_, arg_36_0:nodeByName("button_zhandui"))
	table.insert(arg_36_0.leftMenuButtons_, arg_36_0:nodeByName("button_pet"))

	for iter_36_0 = 1, #arg_36_0.leftMenuButtons_ do
		arg_36_0.leftMenuButtons_[iter_36_0]:setZoomScale(0.3)

		if iter_36_0 == 1 then
			arg_36_0.leftMenuButtons_[iter_36_0]:setBrightStyle(ccui.BrightStyle.highlight)
		end

		local var_36_0 = arg_36_0.leftMenuButtons_[1]:getY() - 85 * (iter_36_0 - 1)

		arg_36_0.leftMenuButtons_[iter_36_0]:y(var_36_0)
		arg_36_0.leftMenuButtons_[iter_36_0]:addTouchEventListener(function(arg_37_0, arg_37_1)
			if arg_37_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				if arg_37_0 == arg_36_0:nodeByName("button_pet") and not arg_36_0.choosingPet then
					return
				end

				for iter_37_0, iter_37_1 in ipairs(arg_36_0.leftMenuButtons_) do
					iter_37_1:setBrightStyle(arg_37_0 == iter_37_1 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
				end

				arg_36_0.leftMenuType_ = arg_37_0.menu_type
				arg_36_0.totalPet_ = arg_36_0.tmpTotalPets[var_0_15.SELF_PET]

				arg_36_0:refreshSelectedHeroClass()
			end
		end)
	end
end

function var_0_0.initHeros(arg_38_0, arg_38_1)
	arg_38_0.totalHero_ = {}
	arg_38_0.forceHeros = {}
	arg_38_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_38_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_38_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_38_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
	arg_38_0.totalHero_[xyd.DistanceType.FILTER] = {}
	arg_38_0.totalHero_[xyd.DistanceType.SEARCH] = {}

	for iter_38_0, iter_38_1 in pairs(arg_38_0.totalHero_) do
		iter_38_1[var_0_17.NO] = {}
		iter_38_1[var_0_17.YES] = {}
	end

	arg_38_0.searchTxt = ""

	arg_38_0:sortTables(arg_38_1)

	for iter_38_2, iter_38_3 in pairs(arg_38_1) do
		iter_38_3.isLock = false

		arg_38_0:updateHeroTable(arg_38_0.totalHero_, iter_38_3)
	end

	local var_38_0 = 5

	if var_38_0 > #arg_38_0.totalHero_[xyd.DistanceType.ALL][var_0_17.NO] then
		var_38_0 = #arg_38_0.totalHero_[xyd.DistanceType.ALL][var_0_17.NO]
	end

	local var_38_1 = {}

	for iter_38_4, iter_38_5 in ipairs(arg_38_0.totalHero_[xyd.DistanceType.ALL][var_0_17.NO]) do
		local var_38_2 = var_0_1.new()

		var_38_2:populate(iter_38_5:toParams())
		table.insert(var_38_1, var_38_2)
	end

	for iter_38_6 = 1, var_38_0 do
		table.insert(arg_38_0.forceHeros, var_38_1[iter_38_6])
	end

	arg_38_0:sortHerosByForce(arg_38_0.forceHeros)
end

function var_0_0.updateHeroTable(arg_39_0, arg_39_1, arg_39_2)
	if arg_39_2:getDistanceType() == xyd.DistanceType.QIANPAI then
		table.insert(arg_39_1[xyd.DistanceType.QIANPAI][var_0_17.NO], arg_39_2)

		if arg_39_2:isCollocation() then
			table.insert(arg_39_1[xyd.DistanceType.QIANPAI][var_0_17.YES], arg_39_2)
		end
	elseif arg_39_2:getDistanceType() == xyd.DistanceType.ZHONGPAI then
		table.insert(arg_39_1[xyd.DistanceType.ZHONGPAI][var_0_17.NO], arg_39_2)

		if arg_39_2:isCollocation() then
			table.insert(arg_39_1[xyd.DistanceType.ZHONGPAI][var_0_17.YES], arg_39_2)
		end
	elseif arg_39_2:getDistanceType() == xyd.DistanceType.HOUPAI then
		table.insert(arg_39_1[xyd.DistanceType.HOUPAI][var_0_17.NO], arg_39_2)

		if arg_39_2:isCollocation() then
			table.insert(arg_39_1[xyd.DistanceType.HOUPAI][var_0_17.YES], arg_39_2)
		end
	end

	table.insert(arg_39_1[xyd.DistanceType.ALL][var_0_17.NO], arg_39_2)

	if arg_39_2:isCollocation() then
		table.insert(arg_39_1[xyd.DistanceType.ALL][var_0_17.YES], arg_39_2)
	end
end

function var_0_0.updateFilterHeros(arg_40_0)
	arg_40_0.totalHero_[xyd.DistanceType.FILTER] = {}
	arg_40_0.totalHero_[xyd.DistanceType.FILTER][var_0_17.NO] = {}
	arg_40_0.totalHero_[xyd.DistanceType.FILTER][var_0_17.YES] = {}

	local var_40_0 = {
		0,
		0,
		0
	}
	local var_40_1 = {
		0,
		0,
		0
	}
	local var_40_2 = {
		0,
		0,
		0,
		0
	}
	local var_40_3 = {
		0,
		0,
		0
	}

	if arg_40_0.selfPlayer.sortType and arg_40_0.selfPlayer.sortType > 0 then
		local var_40_4 = {}
		local var_40_5 = arg_40_0.selfPlayer.sortType
		local var_40_6 = 1

		while var_40_5 > 0 do
			var_40_4[var_40_6] = var_40_5 % 2
			var_40_6 = var_40_6 + 1
			var_40_5 = math.floor(var_40_5 / 2)
		end

		local var_40_7 = 1

		for iter_40_0 = 13, 1, -1 do
			if iter_40_0 <= 4 then
				if iter_40_0 == 4 then
					var_40_7 = 1
				end

				var_40_2[var_40_7] = var_40_4[iter_40_0]
			elseif iter_40_0 <= 7 then
				if iter_40_0 == 7 then
					var_40_7 = 1
				end

				var_40_1[var_40_7] = var_40_4[iter_40_0]
			elseif iter_40_0 <= 10 then
				if iter_40_0 == 10 then
					var_40_7 = 1
				end

				if var_40_4[iter_40_0] then
					var_40_0[var_40_7] = var_40_4[iter_40_0]
				end
			elseif iter_40_0 <= 13 then
				if iter_40_0 == 13 then
					var_40_7 = 1
				end

				if var_40_4[iter_40_0] then
					var_40_3[var_40_7] = var_40_4[iter_40_0]
				end
			end

			var_40_7 = var_40_7 + 1
		end
	else
		var_40_0 = {
			1,
			1,
			1
		}
		var_40_1 = {
			1,
			1,
			1
		}
		var_40_2 = {
			1,
			1,
			1,
			1
		}
		var_40_3 = {
			1,
			1,
			1
		}
	end

	for iter_40_1, iter_40_2 in pairs(arg_40_0.totalHero_[xyd.DistanceType.ALL][var_0_17.NO]) do
		if var_40_0[iter_40_2:getDistanceType() - 1] == 1 and var_40_1[iter_40_2:getHeroType()] == 1 and var_40_2[iter_40_2:getFromType()] == 1 and var_40_3[iter_40_2:getAwakenType()] == 1 then
			table.insert(arg_40_0.totalHero_[xyd.DistanceType.FILTER][var_0_17.NO], iter_40_2)
		end
	end

	for iter_40_3, iter_40_4 in pairs(arg_40_0.totalHero_[xyd.DistanceType.ALL][var_0_17.YES]) do
		if var_40_0[iter_40_4:getDistanceType() - 1] == 1 and var_40_1[iter_40_4:getHeroType()] == 1 and var_40_2[iter_40_4:getFromType()] == 1 and var_40_3[iter_40_4:getAwakenType()] == 1 then
			table.insert(arg_40_0.totalHero_[xyd.DistanceType.FILTER][var_0_17.YES], iter_40_4)
		end
	end
end

function var_0_0.updateSearchHeros(arg_41_0)
	arg_41_0.totalHero_[xyd.DistanceType.SEARCH] = {}
	arg_41_0.totalHero_[xyd.DistanceType.SEARCH][var_0_17.NO] = {}
	arg_41_0.totalHero_[xyd.DistanceType.SEARCH][var_0_17.YES] = {}

	if arg_41_0.searchTxt ~= "" then
		for iter_41_0, iter_41_1 in pairs(arg_41_0.totalHero_[xyd.DistanceType.ALL][var_0_17.NO]) do
			if xyd.searchHeroByName(arg_41_0.searchTxt, iter_41_1) then
				table.insert(arg_41_0.totalHero_[xyd.DistanceType.SEARCH][var_0_17.NO], iter_41_1)
			end
		end

		for iter_41_2, iter_41_3 in pairs(arg_41_0.totalHero_[xyd.DistanceType.ALL][var_0_17.YES]) do
			if xyd.searchHeroByName(arg_41_0.searchTxt, iter_41_3) then
				table.insert(arg_41_0.totalHero_[xyd.DistanceType.SEARCH][var_0_17.YES], iter_41_3)
			end
		end
	end
end

function var_0_0.initOtherHero(arg_42_0, arg_42_1, arg_42_2)
	for iter_42_0, iter_42_1 in pairs(arg_42_2) do
		local var_42_0 = arg_42_0:checkHeroExit(arg_42_1, iter_42_1.table_id)

		if iter_42_1.is_summon == 1 and not var_42_0 then
			var_42_0 = var_0_1.new()

			var_42_0:initUnCollected(iter_42_1.table_id)
			table.insert(arg_42_1, var_42_0)
		end

		if iter_42_1.add_star > 0 then
			local var_42_1 = var_42_0:getStar()

			if var_42_1 + iter_42_1.add_star > xyd.MAX_STAR_LEVEL then
				var_42_0:setStar(xyd.MAX_STAR_LEVEL)
			else
				var_42_0:setStar(var_42_1 + iter_42_1.add_star)
			end
		end

		if iter_42_1.is_awake == 1 and not var_42_0:isAwaken() then
			var_42_0:setTableID(xyd.tables.hero:afterAwaken(iter_42_1.table_id))
		end

		if iter_42_1.region_arena_times then
			var_42_0.region_arena_times = var_42_0.region_arena_times + iter_42_1.region_arena_times
		end
	end
end

function var_0_0.checkHeroExit(arg_43_0, arg_43_1, arg_43_2)
	local var_43_0 = false

	for iter_43_0, iter_43_1 in pairs(arg_43_1) do
		local var_43_1 = iter_43_1:getTableID()

		if var_43_1 == arg_43_2 then
			var_43_0 = iter_43_1

			break
		end

		if iter_43_1:isAwaken() then
			var_43_1 = iter_43_1:beforeAwakenID()
		end

		if var_43_1 == arg_43_2 then
			var_43_0 = iter_43_1

			break
		end
	end

	return var_43_0
end

function var_0_0.initHeroCell(arg_44_0, arg_44_1, arg_44_2, arg_44_3)
	local var_44_0

	if arg_44_3 then
		var_44_0 = arg_44_3
	else
		var_44_0 = arg_44_0.totalHero_[arg_44_0.selectedHeroClass_[arg_44_0.leftMenuType_]][arg_44_0.collocationType_][arg_44_2]
	end

	var_44_0.healthStatus = nil

	local var_44_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/across_arena/hero_avatar.csb")
	local var_44_2 = var_44_1:getChildByName("background"):getContentSize()

	var_44_1:setContentSize(var_44_2)
	arg_44_1:setContentSize(var_44_2)
	xyd.setAvatarBorderNewUI(var_44_0, var_44_1:getChildByName("avatar"), nil, nil, nil, nil, nil)

	local var_44_3 = var_44_1:getChildByName("chosen")

	var_44_3:setLocalZOrder(100)
	var_44_3:setVisible(false)

	local var_44_4 = var_44_1:getChildByName("avatar_mask")

	var_44_4:setLocalZOrder(2)
	var_44_4:setVisible(false)
	var_44_1:getChildByName("hero_lock"):setVisible(false)

	local var_44_5 = var_44_1:getChildByName("lv_txt")

	var_44_5:setString(var_44_0:getLevel())
	var_44_5:enableOutline(cc.c4b(63, 63, 63, 255), 2)
	var_44_1:getChildByName("name_text"):setString(var_44_0:getName())
	var_44_1:setName("layout")
	var_44_1:setPosition(cc.p(0, 0))

	arg_44_1.data = var_44_0

	for iter_44_0, iter_44_1 in ipairs(arg_44_0.select_) do
		if iter_44_1:getTableID() == var_44_0:getTableID() and iter_44_1.player_name == var_44_0.player_name then
			arg_44_1.teamNo_ = iter_44_0

			var_44_3:setVisible(true)
			var_44_4:setVisible(true)

			arg_44_0.team_[iter_44_0].iniCell_ = arg_44_1
			arg_44_0.team_[iter_44_0].iniCellVisible_ = false

			break
		end
	end

	var_44_0.isDead = isDead

	arg_44_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_44_1:addChild(var_44_1)
	arg_44_1:setTouchSwallowEnabled(false)
	arg_44_1:setTouchEnabled(true)
	arg_44_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_45_0)
		arg_44_0:buttonHandler(nil, arg_44_1, arg_45_0)

		if arg_45_0.name == "began" then
			arg_44_0.startClick_ = true
			arg_44_0.prevX_ = arg_45_0.x
			arg_44_0.prevY_ = arg_45_0.y
		elseif arg_45_0.name == "moved" then
			if math.abs(arg_45_0.y - arg_44_0.prevY_) > 5 or math.abs(arg_45_0.x - arg_44_0.prevX_) > 5 then
				arg_44_0.startClick_ = false
			end
		elseif arg_45_0.name == "ended" and arg_44_0.startClick_ and arg_44_0.selectState == 0 then
			if isDead then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_5:translation("HERO_DIE_ERROR")
				})
			elseif #arg_44_0.select_ >= arg_44_0.selfProgress then
				local var_45_0 = 2

				if arg_44_0.stage == 0 or arg_44_0.stage == 5 then
					var_45_0 = 1
				end

				local var_45_1 = string.format(var_0_5:translation("REGION_ARENA_TIP17"), var_45_0)

				xyd.WindowManager.get():openWindow("toast", {
					message = var_45_1
				})
			elseif not arg_44_1.data or arg_44_1.data and not arg_44_1.data.isLock then
				arg_44_0:clickAvatar(arg_44_1, true)
			end
		end

		return true
	end)

	arg_44_0.heroCells_[var_44_0:getTableID()] = arg_44_1
end

function var_0_0.initBottomCell(arg_46_0, arg_46_1)
	local var_46_0 = display.newNode()
	local var_46_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/across_arena/hero_avatar.csb")
	local var_46_2 = var_46_1:getChildByName("background"):getContentSize()

	var_46_1:setContentSize(var_46_2)
	var_46_0:setContentSize(var_46_2)
	xyd.setAvatarBorderNewUI(arg_46_1, var_46_1:getChildByName("avatar"), nil, nil, nil, nil, nil)

	local var_46_3 = var_46_1:getChildByName("chosen")

	var_46_3:setLocalZOrder(100)
	var_46_3:setVisible(false)

	local var_46_4 = var_46_1:getChildByName("avatar_mask")

	var_46_4:setLocalZOrder(2)
	var_46_4:setVisible(false)
	var_46_1:getChildByName("hero_lock"):setVisible(false)

	var_46_0.isLock = false

	local var_46_5 = var_46_1:getChildByName("lv_txt")

	var_46_5:setString(arg_46_1:getLevel())
	var_46_5:enableOutline(cc.c4b(63, 63, 63, 255), 2)
	var_46_1:getChildByName("name_text"):setString(arg_46_1:getName())
	var_46_1:setName("layout")

	var_46_0.data = arg_46_1

	var_46_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_46_0:addChild(var_46_1)

	arg_46_0.heroBottomCells_[arg_46_1:getTableID()] = var_46_0

	return var_46_0
end

function var_0_0.heroDelegate(arg_47_0, arg_47_1, arg_47_2, arg_47_3)
	local var_47_0 = math.ceil(#arg_47_0.totalHero_[arg_47_0.selectedHeroClass_[arg_47_0.leftMenuType_]][arg_47_0.collocationType_] / var_0_10)

	if cc.ui.UIListView.COUNT_TAG == arg_47_2 then
		return var_47_0
	elseif cc.ui.UIListView.CELL_TAG == arg_47_2 then
		local var_47_1
		local var_47_2
		local var_47_3
		local var_47_4 = arg_47_0.heroList_:dequeueItem()

		if not var_47_4 then
			var_47_4 = arg_47_0.heroList_:newItem()
		else
			var_47_4:removeAllChildren()
		end

		local var_47_5 = display.newNode()

		var_47_5:setTouchSwallowEnabled(false)

		for iter_47_0 = 1, var_0_10 do
			local var_47_6 = (arg_47_3 - 1) * var_0_10 + iter_47_0

			if var_47_6 > #arg_47_0.totalHero_[arg_47_0.selectedHeroClass_[arg_47_0.leftMenuType_]][arg_47_0.collocationType_] then
				break
			end

			var_47_3 = display.newNode()

			arg_47_0:initHeroCell(var_47_3, var_47_6)

			local var_47_7 = var_47_3:getContentSize().width
			local var_47_8 = var_47_3:getContentSize().height
			local var_47_9 = (arg_47_0.heroList_.viewRect_.width - var_47_7 * var_0_10) / (var_0_10 + 1)

			var_47_3:pos(var_47_9 * iter_47_0 + (iter_47_0 - 1) * var_47_7 + var_47_7 / 2, var_0_9 + var_47_8 / 2 - 2)
			var_47_5:addChild(var_47_3)
		end

		var_47_5:setContentSize(cc.size(arg_47_0.heroList_.viewRect_.width, var_47_3:getContentSize().height + var_0_9))
		var_47_4:setItemSize(arg_47_0.heroList_.viewRect_.width, var_47_3:getContentSize().height + var_0_9)
		var_47_4:addContent(var_47_5)

		return var_47_4
	end
end

function var_0_0.refreshSelectedHeroClass(arg_48_0)
	for iter_48_0 = 1, #arg_48_0.heroClassButtons_ do
		if iter_48_0 == arg_48_0.selectedHeroClass_[arg_48_0.leftMenuType_] then
			arg_48_0.heroClassButtons_[iter_48_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_48_0.heroClassButtons_[iter_48_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_48_0.heroList_:removeAllItems()

	if arg_48_0.selectedHeroClass_[arg_48_0.leftMenuType_] == xyd.DistanceType.FILTER then
		-- block empty
	elseif arg_48_0.selectedHeroClass_[arg_48_0.leftMenuType_] ~= xyd.DistanceType.ALL then
		for iter_48_1, iter_48_2 in ipairs(arg_48_0.select_) do
			if iter_48_2:getDistanceType() ~= arg_48_0.selectedHeroClass_[arg_48_0.leftMenuType_] then
				arg_48_0.team_[iter_48_1].iniCellVisible_ = true
			end
		end
	end

	arg_48_0.heroList_:reload()
end

function var_0_0.buttonHandler(arg_49_0, arg_49_1, arg_49_2, arg_49_3)
	if not arg_49_2 or not arg_49_2:getParent() then
		return
	end

	if arg_49_3.name == "ended" then
		transition.stopTarget(arg_49_2)
		arg_49_2:setScale(1)

		if arg_49_1 then
			arg_49_1(arg_49_2, eventType)
		end
	elseif arg_49_3.name == "began" then
		local var_49_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_49_2:runAction(var_49_0)

		return true
	elseif arg_49_3.name == "cancled" then
		transition.stopTarget(arg_49_2)
		arg_49_2:setScale(1)
	end
end

function var_0_0.clickAvatar(arg_50_0, arg_50_1, arg_50_2, arg_50_3)
	if not arg_50_1.teamNo_ and #arg_50_0.team_ >= xyd.MAX_TEAM_MEMBER_NUM then
		return
	end

	if not arg_50_2 then
		arg_50_0.unPreSelect_ = true
	end

	local var_50_0
	local var_50_1 = arg_50_1:getChildByName("layout")
	local var_50_2 = var_50_1:getChildByName("avatar_mask")
	local var_50_3 = var_50_1:getChildByName("chosen")
	local var_50_4
	local var_50_5

	if arg_50_3 then
		var_50_4, var_50_5 = xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2
	else
		local var_50_6 = arg_50_1:convertToWorldSpace(cc.p(0, 0))

		var_50_4, var_50_5 = var_50_6.x + arg_50_1:getContentSize().width / 2, var_50_6.y + arg_50_1:getContentSize().height / 2
	end

	arg_50_0.lockTime = xyd.ServerTime.get():getServerTime()

	if arg_50_1.teamNo_ then
		local var_50_7 = arg_50_0.team_[arg_50_1.teamNo_]

		var_50_2:setVisible(false)
		var_50_3:setVisible(false)

		for iter_50_0 = #arg_50_0.team_, arg_50_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_50_0.team_[iter_50_0])

			local var_50_8, var_50_9 = arg_50_0:nodeByName("avatar" .. iter_50_0 - 1):getPosition()

			arg_50_0.team_[iter_50_0]:setPosition(var_50_8, var_50_9)

			arg_50_0.team_[iter_50_0].iniCell_.teamNo_ = iter_50_0 - 1
		end

		table.remove(arg_50_0.team_, arg_50_1.teamNo_)
		table.remove(arg_50_0.select_, arg_50_1.teamNo_)

		if xyd.tableHaveElement(arg_50_0.tempSelectHeros, var_50_7) then
			table.remove(arg_50_0.tempSelectHeros, table.indexof(arg_50_0.tempSelectHeros, var_50_7))
		end

		arg_50_1.teamNo_ = nil

		if var_50_7 and not tolua.isnull(var_50_7) then
			var_50_7:removeSelf()
		end
	elseif not arg_50_1.teamNo_ and #arg_50_0.team_ < xyd.MAX_TEAM_MEMBER_NUM then
		if not arg_50_2 then
			local var_50_10 = arg_50_1.data

			if var_0_6:chosenSound(var_50_10:getTableID()) ~= "" then
				xyd.AssetDownload.get():preloadCharacterSound({
					var_50_10:getTableID()
				}, function()
					return
				end, true)
				audio.playSound(var_0_6:chosenSound(var_50_10:getTableID()), false)
			end
		end

		local var_50_11 = arg_50_0:initBottomCell(arg_50_1.data)

		var_50_11.iniCell_ = arg_50_1

		var_50_11:pos(var_50_4, var_50_5)
		var_50_11:addTo(arg_50_0)
		var_50_11:setTouchEnabled(true)

		local var_50_12 = arg_50_1.data

		var_50_11:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_52_0)
			if arg_52_0.name == "ended" then
				arg_50_0:clickBottomAvatar(var_50_11)
			end

			return true
		end)

		if not xyd.tableHaveElement(arg_50_0.tempSelectHeros, var_50_11) then
			table.insert(arg_50_0.tempSelectHeros, var_50_11)
		else
			table.remove(arg_50_0.tempSelectHeros, table.indexof(arg_50_0.tempSelectHeros, var_50_11))
		end

		arg_50_1.teamNo_ = arg_50_0:getTeamNo(var_50_11)

		for iter_50_1 = arg_50_1.teamNo_, #arg_50_0.team_ do
			local var_50_13, var_50_14 = arg_50_0:nodeByName("avatar" .. iter_50_1):getPosition()

			if arg_50_2 then
				arg_50_0.team_[iter_50_1]:pos(var_50_13, var_50_14)
			elseif iter_50_1 ~= arg_50_1.teamNo_ then
				local var_50_15 = arg_50_0.team_[iter_50_1]

				transition.stopTarget(var_50_15)
				transition.moveTo(var_50_15, {
					time = 0.3,
					x = var_50_13,
					y = var_50_14,
					onComplete = function()
						return
					end
				})
			else
				local var_50_16 = arg_50_0.team_[iter_50_1]

				transition.stopTarget(var_50_16)
				transition.moveTo(var_50_16, {
					time = 0.3,
					x = var_50_13,
					y = var_50_14,
					onComplete = function()
						return
					end
				})
			end

			arg_50_0.team_[iter_50_1].iniCell_.teamNo_ = iter_50_1
		end

		var_50_2:setVisible(true)
		var_50_3:setVisible(true)
	end

	arg_50_0:updateScore()
end

function var_0_0.checkHeroValid(arg_55_0, arg_55_1)
	for iter_55_0, iter_55_1 in pairs(arg_55_0.select_) do
		if arg_55_1:getTableID() == iter_55_1:getTableID() then
			return false
		end
	end

	return true
end

function var_0_0.updateScore(arg_56_0)
	local var_56_0 = 0

	for iter_56_0, iter_56_1 in ipairs(arg_56_0.team_) do
		var_56_0 = var_56_0 + iter_56_1.data:getZhandouli()
	end

	for iter_56_2, iter_56_3 in ipairs(arg_56_0.petTeam_) do
		var_56_0 = var_56_0 + iter_56_3.data:getZhandouli()
	end

	arg_56_0:nodeByName("zhandouli"):setString(var_56_0)
end

function var_0_0.clickBottomAvatar(arg_57_0, arg_57_1)
	if arg_57_1.isLock then
		return
	end

	local var_57_0, var_57_1 = arg_57_0:nodeByName("list_layer"):getPosition()
	local var_57_2 = arg_57_1.iniCell_
	local var_57_3

	for iter_57_0, iter_57_1 in ipairs(arg_57_0.select_) do
		if iter_57_1:getTableID() == arg_57_1.data:getTableID() and iter_57_1.player_name == arg_57_1.data.player_name then
			var_57_3 = iter_57_0

			break
		end
	end

	if not var_57_3 then
		return
	end

	if not arg_57_1.iniCellVisible_ and not tolua.isnull(var_57_2) then
		local var_57_4 = var_57_2:convertToWorldSpace(cc.p(0, 0))
		local var_57_5 = var_57_4.x + var_57_2:getContentSize().width / 2, var_57_4.y + var_57_2:getContentSize().height / 2
		local var_57_6 = var_57_2:getChildByName("layout")
		local var_57_7 = var_57_6:getChildByName("avatar_mask")
		local var_57_8 = var_57_6:getChildByName("chosen")

		var_57_7:setVisible(false)
		var_57_8:setVisible(false)
	end

	if arg_57_1 and not tolua.isnull(arg_57_1) then
		arg_57_1:removeSelf()
	end

	for iter_57_2 = #arg_57_0.team_, var_57_3 + 1, -1 do
		local var_57_9 = arg_57_0.team_[iter_57_2]
		local var_57_10, var_57_11 = arg_57_0:nodeByName("avatar" .. iter_57_2 - 1):getPosition()

		arg_57_0.team_[iter_57_2]:setPosition(var_57_10, var_57_11)

		arg_57_0.team_[iter_57_2].iniCell_.teamNo_ = iter_57_2 - 1
	end

	table.remove(arg_57_0.team_, var_57_3)
	table.remove(arg_57_0.select_, var_57_3)

	if xyd.tableHaveElement(arg_57_0.tempSelectHeros, arg_57_1) then
		table.remove(arg_57_0.tempSelectHeros, table.indexof(arg_57_0.tempSelectHeros, arg_57_1))
	end

	var_57_2.teamNo_ = nil

	arg_57_0:updateScore()
end

function var_0_0.getTeamNo(arg_58_0, arg_58_1)
	for iter_58_0, iter_58_1 in ipairs(arg_58_0.team_) do
		if arg_58_1.data:getDistance() < iter_58_1.data:getDistance() then
			table.insert(arg_58_0.team_, iter_58_0, arg_58_1)
			table.insert(arg_58_0.select_, iter_58_0, arg_58_1.data)

			return iter_58_0
		end
	end

	table.insert(arg_58_0.team_, arg_58_1)
	table.insert(arg_58_0.select_, arg_58_1.data)

	return #arg_58_0.team_
end

function var_0_0.widgetSet(arg_59_0, arg_59_1)
	for iter_59_0, iter_59_1 in ipairs(arg_59_1:getChildren()) do
		if iter_59_1 ~= nil then
			iter_59_1:setCascadeOpacityEnabled(true)
			arg_59_0:widgetSet(iter_59_1)
		end
	end
end

function var_0_0.moveFadeOutAction(arg_60_0, arg_60_1, arg_60_2, arg_60_3, arg_60_4)
	arg_60_0:widgetSet(arg_60_3)
	arg_60_3:setCascadeOpacityEnabled(true)

	local var_60_0 = cc.Spawn:create(cc.FadeOut:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_60_1, arg_60_2)))

	arg_60_3:runActionOnce(var_60_0, true, arg_60_4)
end

function var_0_0.getBattleBtn(arg_61_0)
	if not arg_61_0.battleBtn_ then
		arg_61_0.battleBtn_ = arg_61_0:nodeByName("button_ok")

		if arg_61_0.stage > 0.8 then
			if (arg_61_0.stage + 1) % 2 == 1 - arg_61_0.firstSelect then
				arg_61_0.battleBtn_:setBright(false)
				arg_61_0.battleBtn_:setTouchEnabled(false)
			else
				arg_61_0.battleBtn_:setBright(true)
				arg_61_0.battleBtn_:setTouchEnabled(true)
			end
		elseif arg_61_0.stage == 0.5 then
			if arg_61_0.firstSelect == 1 then
				arg_61_0.battleBtn_:setBright(true)
				arg_61_0.battleBtn_:setTouchEnabled(true)
			else
				arg_61_0.battleBtn_:setBright(false)
				arg_61_0.battleBtn_:setTouchEnabled(false)
			end
		elseif arg_61_0.firstSelect == 1 then
			arg_61_0.battleBtn_:setBright(false)
			arg_61_0.battleBtn_:setTouchEnabled(false)
		else
			arg_61_0.battleBtn_:setBright(true)
			arg_61_0.battleBtn_:setTouchEnabled(true)
		end

		arg_61_0.battleBtn_:addTouchEventListener(function(arg_62_0, arg_62_1)
			xyd.buttonScaleAnim(arg_62_0, arg_62_1)

			if arg_62_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if #arg_61_0.select_ < arg_61_0.selfProgress then
					local var_62_0 = var_0_5:translation("REGION_ARENA_TIP18")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_62_0
					})

					return
				else
					arg_61_0.battleBtn_:setBright(false)
					arg_61_0.battleBtn_:setTouchEnabled(false)

					local var_62_1 = {}

					for iter_62_0 = 1, #arg_61_0.select_ do
						table.insert(var_62_1, arg_61_0.select_[iter_62_0]:getHeroID())
					end

					local var_62_2
					local var_62_3

					for iter_62_1, iter_62_2 in ipairs(arg_61_0.petTeam_) do
						var_62_2 = iter_62_2.data
					end

					if var_62_2 then
						var_62_3 = var_62_2:getPetID()
					else
						var_62_3 = 0
					end

					if arg_61_0.selfChoosingPet == 1 and var_62_3 == 0 and #arg_61_0.totalPet_ ~= 0 then
						arg_61_0.battleBtn_:setBright(true)
						arg_61_0.battleBtn_:setTouchEnabled(true)

						local var_62_4 = var_0_5:translation("REGION_ARENA_TIP53")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_62_4
						})

						return
					end

					local var_62_5 = {
						room_key = arg_61_0.room_key,
						formation = var_62_1,
						stage = arg_61_0.stage,
						pet_id = var_62_3
					}

					xyd.Backend.get():request(xyd.mid.PLAYOFFS_CHOOSE_MEMBER, var_62_5, function(arg_63_0, arg_63_1)
						if arg_63_0 == xyd.error.OK and arg_61_0.stage >= 7 then
							arg_61_0.countDown = 0

							arg_61_0:setRequestHandler()
						end
					end)
				end
			end
		end)
	end

	return arg_61_0.battleBtn_
end

function var_0_0.lockTeamCells(arg_64_0)
	for iter_64_0, iter_64_1 in pairs(arg_64_0.team_) do
		iter_64_1.isLock = true

		iter_64_1:getChildByName("layout"):getChildByName("hero_lock"):setVisible(true)
	end

	for iter_64_2, iter_64_3 in pairs(arg_64_0.select_) do
		iter_64_3.isLock = true
	end
end

function var_0_0.startBattle(arg_65_0)
	arg_65_0:startRegionArenaBattle()
end

function var_0_0.startPlayoffsBattle(arg_66_0)
	local var_66_0 = {
		index = 1,
		stage = arg_66_0.detailparams.record_info.stage,
		record_id = arg_66_0.detailparams.record_info.record_id
	}

	var_0_7.performWithDelayGlobal(function()
		xyd.Backend.get():request(xyd.mid.REARENA_STOP_FIGHT, var_66_0, function(arg_68_0, arg_68_1)
			if arg_68_0 == xyd.error.OK then
				-- block empty
			end
		end)
	end, 5)
end

function var_0_0.initPets(arg_69_0, arg_69_1, arg_69_2)
	local var_69_0 = {}

	for iter_69_0, iter_69_1 in ipairs(arg_69_1) do
		if iter_69_1.is_show_ == 1 then
			table.insert(var_69_0, iter_69_1)
		end
	end

	table.sort(var_69_0, function(arg_70_0, arg_70_1)
		return xyd.petNormalSort(arg_70_0, arg_70_1) or false
	end)

	arg_69_0.tmpTotalPets[arg_69_2] = var_69_0
end

function var_0_0.choosePet(arg_71_0)
	arg_71_0.countDown = arg_71_0.ServerTime + var_0_12 - arg_71_0.stageStartTime

	if xyd.WindowManager.get():getWindow("finding_enemy") then
		xyd.WindowManager.get():closeWindow("finding_enemy")
	end

	arg_71_0.selfChoosingPet = 1
	arg_71_0.choosingPet = true

	arg_71_0.battleBtn_:setBright(true)
	arg_71_0.battleBtn_:setTouchEnabled(true)

	for iter_71_0, iter_71_1 in ipairs(arg_71_0.leftMenuButtons_) do
		iter_71_1:setBrightStyle(var_0_16.SELF_PET == iter_71_1.menu_type and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
	end

	arg_71_0.leftMenuType_ = var_0_16.SELF_PET
	arg_71_0.totalPet_ = arg_71_0.tmpTotalPets[var_0_15.SELF_PET]

	arg_71_0:refreshSelectedHeroClass()

	if arg_71_0.handle then
		var_0_7.unscheduleGlobal(arg_71_0.handle)

		arg_71_0.handle = nil
	end

	if not arg_71_0.handle then
		arg_71_0.warnEffect:setVisible(false)

		arg_71_0.handle = var_0_7.scheduleGlobal(function()
			local var_72_0
			local var_72_1 = {}

			if arg_71_0.countDown < 10 then
				local var_72_2 = "0" .. tostring(arg_71_0.countDown)
			else
				local var_72_3 = tostring(arg_71_0.countDown)
			end

			local var_72_4 = arg_71_0.selfSelectState

			arg_71_0:nodeByName("count_down_1"):setString(var_0_5:translation("REGION_ARENA_TIP47"))
			arg_71_0:nodeByName("count"):setString(arg_71_0.countDown)
			arg_71_0:nodeByName("count_down_2"):setString(var_0_5:translation("REGION_ARENA_TIP51"))

			if arg_71_0.countDown <= 5 and arg_71_0.countDown > -1 then
				arg_71_0.warnEffect:setVisible(true)
			else
				arg_71_0.warnEffect:setVisible(false)
			end

			arg_71_0.countDown = arg_71_0.countDown - 1

			if arg_71_0.countDown < 0 then
				var_0_7.unscheduleGlobal(arg_71_0.handle)

				arg_71_0.handle = nil

				arg_71_0:setRequestHandler()
			end
		end, 1)
	end
end

function var_0_0.setRequestHandler(arg_73_0)
	if arg_73_0.team_id ~= arg_73_0.totalteams or arg_73_0.stage < 7 then
		return
	end

	if not arg_73_0.requestHandler then
		arg_73_0.warnEffect:setVisible(false)

		arg_73_0.requestHandler = var_0_7.scheduleGlobal(function()
			if arg_73_0.countDown < 0 then
				print("Do a Request for room info")
				xyd.Backend.get():request(xyd.mid.PLAYOFFS_REQUEST_ROOM_INFO, {
					stage = arg_73_0.stage,
					room_key = arg_73_0.room_key
				}, function(arg_75_0, arg_75_1)
					if arg_75_0 == xyd.error.OK and xyd.WindowManager.get():getWindow("sync_select_team") then
						arg_73_0:updateSelectHeroes(arg_75_1)
						var_0_7.unscheduleGlobal(arg_73_0.requestHandler)

						arg_73_0.requestHandler = nil
					end
				end)
			else
				var_0_7.unscheduleGlobal(arg_73_0.requestHandler)

				arg_73_0.requestHandler = nil
			end
		end, 3)
	end
end

function var_0_0.startRegionArenaBattle(arg_76_0)
	if arg_76_0.isBackendBattle == 1 then
		local var_76_0 = {
			message = var_0_5:translation("PLAYOFFS_WATTING_FOR_BACKEND")
		}

		xyd.WindowManager.get():openWindow("finding_enemy", var_76_0)
		var_0_7.performWithDelayGlobal(function()
			if xyd.WindowManager.get():getWindow("finding_enemy") then
				xyd.WindowManager.get():closeWindow("finding_enemy")
			end

			if arg_76_0.isfriend then
				arg_76_0.socialSystem:startBattle(arg_76_0.detailparams.params.record_id, function(arg_78_0)
					local var_78_0 = arg_78_0

					if tonumber(var_78_0.record_info.have_battled) ~= 0 then
						local var_78_1 = arg_76_0.socialSystem:setBattleParams(var_78_0, 1, arg_76_0.model)

						xyd.WindowManager.get():openWindow("region_arena_loading", var_78_1)
						xyd.WindowManager.get():closeWindow(arg_76_0.name)
					else
						if xyd.WindowManager.get():getWindow("toast") ~= nil then
							xyd.WindowManager.get():closeWindow("toast")
						end

						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_5:translation("PLAYOFFS_RETRY")
						})

						arg_76_0.battleBegan = true

						arg_76_0:startBattle()
					end
				end)
			elseif arg_76_0.isCasual then
				arg_76_0.regionCasualArena:startBattle(arg_76_0.detailparams.params.stage, arg_76_0.detailparams.params.record_id, function(arg_79_0)
					if tonumber(arg_79_0.record_info.have_battled) ~= 0 then
						local var_79_0 = arg_76_0.regionCasualArena:setBattleParams(arg_79_0, 1)

						xyd.WindowManager.get():openWindow("region_arena_loading", var_79_0)
						xyd.WindowManager.get():closeWindow(arg_76_0.name)
					else
						if xyd.WindowManager.get():getWindow("toast") ~= nil then
							xyd.WindowManager.get():closeWindow("toast")
						end

						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_5:translation("PLAYOFFS_RETRY")
						})

						arg_76_0.battleBegan = true

						arg_76_0:startBattle()
					end
				end)
			else
				arg_76_0.playoffsModel:startBattle(arg_76_0.detailparams.params.stage, arg_76_0.detailparams.params.record_id, function(arg_80_0)
					if tonumber(arg_80_0.record_info.have_battled) ~= 0 then
						local var_80_0 = arg_76_0.playoffsModel:setBattleParams(arg_80_0, 1)

						xyd.WindowManager.get():openWindow("region_arena_loading", var_80_0)
						xyd.WindowManager.get():closeWindow(arg_76_0.name)
					else
						if xyd.WindowManager.get():getWindow("toast") ~= nil then
							xyd.WindowManager.get():closeWindow("toast")
						end

						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_5:translation("PLAYOFFS_RETRY")
						})

						arg_76_0.battleBegan = true

						arg_76_0:startBattle()
					end
				end)
			end
		end, 3)
	else
		local var_76_1 = {
			herosA = {}
		}

		for iter_76_0, iter_76_1 in ipairs(arg_76_0.team_) do
			table.insert(var_76_1.herosA, iter_76_1.data)
		end

		var_76_1.isRegionArenaTest = arg_76_0.mode
		var_76_1.enemy_id = arg_76_0.enemyID
		var_76_1.campaignType = xyd.CampaignType.REGION_ARENA
		var_76_1.campaignID = arg_76_0.campaignID
		var_76_1.herosB = {
			arg_76_0.enemyHeroes_
		}
		var_76_1.fighterInfo = arg_76_0.fighterInfo
		var_76_1.battleID = xyd.MapBattleID.ARENA
		var_76_1.isBackendBattle = arg_76_0.isBackendBattle

		local var_76_2 = arg_76_0:getFormationStr(var_76_1.herosA)

		var_76_1.battleType = xyd.BattleType.CreateReport
		var_76_1.oldStar = clone(arg_76_0.regionArena:getStar())

		xyd.Backend.get():request(xyd.mid.REARENA_PREPARE_FIGHT, {
			campaign_id = var_76_1.campaignID,
			campaign_type = var_76_1.campaignType,
			formation = var_76_2
		}, function(arg_81_0, arg_81_1)
			if arg_81_0 == xyd.error.OK then
				if arg_81_1.formation and next(arg_81_1.formation) then
					local var_81_0 = {}

					for iter_81_0, iter_81_1 in ipairs(arg_81_1.formation) do
						local var_81_1 = var_0_1.new()

						var_81_1:populate(iter_81_1)
						table.insert(var_81_0, var_81_1)
					end

					xyd.formatRegionArenaHerosAwake(var_81_0)

					var_76_1.herosA = var_81_0
				end

				xyd.WindowManager.get():hideAllWindows()
				xyd.LoadingProxy.get():openBattleLoading(var_76_1)
			else
				arg_76_0.battleBegan = false
			end
		end)
	end
end

function var_0_0.getFormationStr(arg_82_0, arg_82_1)
	local var_82_0 = ""

	for iter_82_0, iter_82_1 in ipairs(arg_82_1) do
		var_82_0 = var_82_0 .. string.format("%d", iter_82_1:getTableID())

		if iter_82_0 < #arg_82_1 then
			var_82_0 = var_82_0 .. "|"
		end
	end

	return var_82_0
end

function var_0_0.size(arg_83_0, arg_83_1, arg_83_2)
	return {
		width = arg_83_1,
		height = arg_83_2
	}
end

function var_0_0.selectStateMonitor(arg_84_0)
	if not arg_84_0.handle then
		arg_84_0.warnEffect:setVisible(false)

		arg_84_0.handle = var_0_7.scheduleGlobal(function()
			local var_85_0
			local var_85_1 = {}

			if arg_84_0.countDown < 10 then
				local var_85_2 = "0" .. tostring(arg_84_0.countDown)
			else
				local var_85_3 = tostring(arg_84_0.countDown)
			end

			if arg_84_0.selectState == 0 then
				local var_85_4 = arg_84_0.selfSelectState

				arg_84_0:nodeByName("count_down_1"):setString(var_0_5:translation("REGION_ARENA_TIP47"))
				arg_84_0:nodeByName("count"):setString(arg_84_0.countDown)
				arg_84_0:nodeByName("count_down_2"):setString(var_0_5:translation("REGION_ARENA_TIP46"))
			else
				local var_85_5 = arg_84_0.enemySelectState

				arg_84_0:nodeByName("count_down_1"):setString(var_0_5:translation("REGION_ARENA_TIP45"))
				arg_84_0:nodeByName("count"):setString(arg_84_0.countDown)
				arg_84_0:nodeByName("count_down_2"):setString(var_0_5:translation("REGION_ARENA_TIP46"))
			end

			if arg_84_0.countDown <= 5 and arg_84_0.countDown > -1 then
				arg_84_0.warnEffect:setVisible(true)
			else
				arg_84_0.warnEffect:setVisible(false)
			end

			arg_84_0.countDown = arg_84_0.countDown - 1

			if arg_84_0.countDown < 0 then
				var_0_7.unscheduleGlobal(arg_84_0.handle)
				arg_84_0:setRequestHandler()

				arg_84_0.handle = nil

				arg_84_0.battleBtn_:setBright(false)
				arg_84_0.battleBtn_:setTouchEnabled(false)
			end
		end, 1)
	end
end

function var_0_0.getMaxForceValidHero(arg_86_0)
	local var_86_0 = arg_86_0.forceHeros[1]

	while var_86_0 and (var_86_0.isDead or not arg_86_0:checkHeroValid(var_86_0)) do
		table.remove(arg_86_0.forceHeros, 1)

		var_86_0 = arg_86_0.forceHeros[1]
	end

	return var_86_0
end

function var_0_0.updateSelfSelectStates(arg_87_0)
	for iter_87_0 = 1, arg_87_0.selfProgress do
		arg_87_0.selfSelectState[iter_87_0] = 1
	end
end

function var_0_0.updateEnemySelectStates(arg_88_0)
	for iter_88_0 = 1, arg_88_0.enemyProgress do
		arg_88_0.enemySelectState[iter_88_0] = 1
	end
end

function var_0_0.createEnemyHeroAvatarAndMotion(arg_89_0)
	while true do
		local var_89_0 = display.newNode()

		var_89_0:setContentSize(var_0_14, var_0_14)
		var_89_0:setAnchorPoint(cc.p(0.5, 0.5))

		local var_89_1 = arg_89_0:getNewEnemyHero()

		if not var_89_1 then
			break
		end

		if arg_89_0.team_id >= 3 then
			local var_89_2 = xyd.AssetLoader.get():loadSprite("images/battle/hide_avatar.png")

			xyd.displaySpriteOnContainer(var_89_2, var_89_0, true)
		else
			xyd.setAvatarBorderNewUI(var_89_1, var_89_0, nil, nil, nil, false, nil, true)
		end

		var_89_0:addTo(arg_89_0:nodeByName("battle_team_bg"))

		var_89_0.distanceType = var_89_1.distanceType

		table.insert(arg_89_0.enemyHerosAvatars, var_89_0)
		arg_89_0:sortHeroAvatarsByDistance(arg_89_0.enemyHerosAvatars)

		local var_89_3 = table.keyof(arg_89_0.enemyHerosAvatars, var_89_0)

		var_89_0:setPositionX(arg_89_0:nodeByName("enemy_hero_" .. var_89_3):getPositionX())
		var_89_0:setPositionY(arg_89_0:nodeByName("enemy_hero_" .. var_89_3):getPositionY())

		if var_89_3 < #arg_89_0.enemyHerosAvatars then
			for iter_89_0 = var_89_3 + 1, #arg_89_0.enemyHerosAvatars do
				arg_89_0.enemyHerosAvatars[iter_89_0]:runAction(cc.MoveBy:create(0, cc.p(-120, 0)))
			end
		end
	end
end

function var_0_0.getRandomEnemyHero(arg_90_0)
	local var_90_0 = math.ceil(math.random() * #arg_90_0.selectEnemyHeros_)
	local var_90_1 = arg_90_0.selectEnemyHeros_[var_90_0]

	table.remove(arg_90_0.selectEnemyHeros_, var_90_0)

	return var_90_1
end

function var_0_0.getNewEnemyHero(arg_91_0)
	local var_91_0

	if #arg_91_0.newEnemyHeroList >= 1 then
		var_91_0 = arg_91_0.newEnemyHeroList[1]

		table.remove(arg_91_0.newEnemyHeroList, 1)
	else
		var_91_0 = nil
	end

	return var_91_0
end

function var_0_0.sortHeroAvatarsByDistance(arg_92_0, arg_92_1)
	table.sort(arg_92_1, function(arg_93_0, arg_93_1)
		if arg_93_0.distanceType ~= arg_93_1.distanceType then
			return arg_93_0.distanceType < arg_93_1.distanceType
		end
	end)
end

function var_0_0.moveHeroAvatar(arg_94_0, arg_94_1)
	arg_94_0.enemyHerosAvatars[arg_94_1]:runAction(cc.MoveBy:create(0, cc.p(0, -50)))

	if arg_94_1 < #arg_94_0.enemyHerosAvatars then
		for iter_94_0 = arg_94_1 + 1, #arg_94_0.enemyHerosAvatars do
			arg_94_0.enemyHerosAvatars[iter_94_0]:runAction(cc.MoveBy:create(0, cc.p(-120, 0)))
		end
	end
end

function var_0_0.clearAlreadySelectHeros(arg_95_0, arg_95_1)
	if not arg_95_1.data then
		return
	end

	local var_95_0, var_95_1 = arg_95_0:nodeByName("list_layer"):getPosition()
	local var_95_2 = arg_95_1.iniCell_
	local var_95_3

	for iter_95_0, iter_95_1 in ipairs(arg_95_0.select_) do
		if iter_95_1:getTableID() == arg_95_1.data:getTableID() and iter_95_1.player_name == arg_95_1.data.player_name then
			var_95_3 = iter_95_0

			break
		end
	end

	if not var_95_3 then
		return
	end

	if not arg_95_1.iniCellVisible_ and not tolua.isnull(var_95_2) then
		local var_95_4 = var_95_2:convertToWorldSpace(cc.p(0, 0))
		local var_95_5 = var_95_4.x + var_95_2:getContentSize().width / 2, var_95_4.y + var_95_2:getContentSize().height / 2
		local var_95_6 = var_95_2:getChildByName("layout")
		local var_95_7 = var_95_6:getChildByName("avatar_mask")
		local var_95_8 = var_95_6:getChildByName("chosen")

		var_95_7:setVisible(false)
		var_95_8:setVisible(false)
	end

	if arg_95_1 and not tolua.isnull(arg_95_1) then
		arg_95_1:removeSelf()
	end

	for iter_95_2 = #arg_95_0.team_, var_95_3 + 1, -1 do
		local var_95_9 = arg_95_0.team_[iter_95_2]
		local var_95_10, var_95_11 = arg_95_0:nodeByName("avatar" .. iter_95_2 - 1):getPosition()

		arg_95_0.team_[iter_95_2]:setPosition(var_95_10, var_95_11)

		arg_95_0.team_[iter_95_2].iniCell_.teamNo_ = iter_95_2 - 1
	end

	table.remove(arg_95_0.team_, var_95_3)
	table.remove(arg_95_0.select_, var_95_3)

	if xyd.tableHaveElement(arg_95_0.tempSelectHeros, arg_95_1) then
		table.remove(arg_95_0.tempSelectHeros, table.indexof(arg_95_0.tempSelectHeros, arg_95_1))
	end

	var_95_2.teamNo_ = nil

	arg_95_0:updateScore()
end

function var_0_0.clearAlreadyEnemySelectHeros(arg_96_0)
	for iter_96_0 = 1, #arg_96_0.enemyHerosAvatars do
		arg_96_0.enemyHerosAvatars[iter_96_0]:removeSelf()
	end

	arg_96_0.enemyHerosAvatars = {}
	arg_96_0.enemyHeroes_ = {}
end

function var_0_0.updateSelfSelectHeroes(arg_97_0, arg_97_1)
	local var_97_0 = arg_97_1

	for iter_97_0, iter_97_1 in pairs(arg_97_0.heroBottomCells_) do
		arg_97_0:clearAlreadySelectHeros(iter_97_1)
	end

	arg_97_0.heroBottomCells_ = {}

	for iter_97_2 = 1, #var_97_0 do
		local var_97_1

		if arg_97_0.heroCells_[var_97_0[iter_97_2].table_id] and not tolua.isnull(arg_97_0.heroCells_[var_97_0[iter_97_2].table_id]) then
			var_97_1 = arg_97_0.heroCells_[var_97_0[iter_97_2].table_id]
		elseif arg_97_0.heroCells_[var_0_6:beforeAwaken(var_97_0[iter_97_2].table_id)] and not tolua.isnull(arg_97_0.heroCells_[var_0_6:beforeAwaken(var_97_0[iter_97_2].table_id)]) then
			var_97_1 = arg_97_0.heroCells_[var_0_6:beforeAwaken(var_97_0[iter_97_2].table_id)]
		elseif arg_97_0.heroCells_[var_0_6:afterAwaken(var_97_0[iter_97_2].table_id)] and not tolua.isnull(arg_97_0.heroCells_[var_0_6:afterAwaken(var_97_0[iter_97_2].table_id)]) then
			var_97_1 = arg_97_0.heroCells_[var_0_6:afterAwaken(var_97_0[iter_97_2].table_id)]
		else
			var_97_1 = display.newNode()

			var_97_1:setPosition(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2)

			local var_97_2

			for iter_97_3 = 1, #arg_97_0.totalHero_[xyd.DistanceType.ALL][var_0_17.NO] do
				if var_97_0[iter_97_2].table_id == arg_97_0.totalHero_[xyd.DistanceType.ALL][var_0_17.NO][iter_97_3]:getTableID() or var_97_0[iter_97_2].table_id == arg_97_0.totalHero_[xyd.DistanceType.ALL][var_0_17.NO][iter_97_3]:beforeAwakenID() then
					var_97_2 = arg_97_0.totalHero_[xyd.DistanceType.ALL][var_0_17.NO][iter_97_3]
				end
			end

			arg_97_0:initHeroCell(var_97_1, nil, var_97_2)
		end

		arg_97_0:clickAvatar(var_97_1, true, true)
	end

	arg_97_0:lockTeamCells()
end

function var_0_0.updateEnemySelectHeroes(arg_98_0, arg_98_1)
	local var_98_0 = arg_98_1 or {}
	local var_98_1 = {}

	if not arg_98_0.isfriend then
		for iter_98_0 = 1, #var_98_0 do
			if var_0_6:beforeAwaken(var_98_0[iter_98_0].table_id) ~= 0 then
				var_98_0[iter_98_0].table_id = var_0_6:beforeAwaken(var_98_0[iter_98_0].table_id)
			end
		end
	end

	arg_98_0:initEnemyHero(var_98_1, var_98_0)

	if not arg_98_0.model or arg_98_0.model ~= 1 then
		xyd.formatRegionArenaHerosAwake(var_98_1)
	end

	return var_98_1
end

function var_0_0.initEnemyHero(arg_99_0, arg_99_1, arg_99_2)
	for iter_99_0, iter_99_1 in pairs(arg_99_2) do
		local var_99_0 = arg_99_0:checkHeroExit(arg_99_1, iter_99_1.table_id)

		if not var_99_0 then
			var_99_0 = var_0_1.new()

			var_99_0:initUnCollected(iter_99_1.table_id)
			table.insert(arg_99_1, var_99_0)
		end

		var_99_0:setStar(iter_99_1.star)

		var_99_0.color_ = iter_99_1.color
		var_99_0.illusionSkinId_ = iter_99_1.illusion_skin_id

		var_99_0:setSkinInfo(iter_99_1.current_skin_id, iter_99_1.skin_ids)

		var_99_0.awakeTwiceStage_ = iter_99_1.twice_awake_stage or 0
	end
end

function var_0_0.enemyChoosePet(arg_100_0, ...)
	arg_100_0.countDown = arg_100_0.ServerTime + var_0_12 - arg_100_0.stageStartTime

	local var_100_0 = {
		message = var_0_5:translation("REGION_ARENA_TIP54")
	}

	xyd.WindowManager.get():openWindow("finding_enemy", var_100_0)

	arg_100_0.choosingPet = true
	arg_100_0.enemyChoosingPet = 1

	arg_100_0.battleBtn_:setBright(false)
	arg_100_0.battleBtn_:setTouchEnabled(false)

	for iter_100_0, iter_100_1 in ipairs(arg_100_0.leftMenuButtons_) do
		iter_100_1:setBrightStyle(var_0_16.SELF_PET == iter_100_1.menu_type and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
	end

	arg_100_0.leftMenuType_ = var_0_16.SELF_PET
	arg_100_0.totalPet_ = arg_100_0.tmpTotalPets[var_0_15.SELF_PET]

	arg_100_0:refreshSelectedHeroClass()

	if arg_100_0.handle then
		var_0_7.unscheduleGlobal(arg_100_0.handle)

		arg_100_0.handle = nil
	end

	if not arg_100_0.handle then
		arg_100_0.warnEffect:setVisible(false)

		arg_100_0.handle = var_0_7.scheduleGlobal(function()
			local var_101_0
			local var_101_1 = {}

			if arg_100_0.countDown < 10 then
				local var_101_2 = "0" .. tostring(arg_100_0.countDown)
			else
				local var_101_3 = tostring(arg_100_0.countDown)
			end

			local var_101_4 = arg_100_0.selfSelectState

			arg_100_0:nodeByName("count_down_1"):setString(var_0_5:translation("REGION_ARENA_TIP55"))
			arg_100_0:nodeByName("count"):setString(arg_100_0.countDown)
			arg_100_0:nodeByName("count_down_2"):setString(var_0_5:translation("REGION_ARENA_TIP51"))

			if arg_100_0.countDown <= 5 and arg_100_0.countDown > -1 then
				arg_100_0.warnEffect:setVisible(true)
			else
				arg_100_0.warnEffect:setVisible(false)
			end

			arg_100_0.countDown = arg_100_0.countDown - 1

			if arg_100_0.countDown < 0 then
				var_0_7.unscheduleGlobal(arg_100_0.handle)

				arg_100_0.handle = nil

				arg_100_0:setRequestHandler()
			end
		end, 1)
	end
end

function var_0_0.updateSelfSelectPets(arg_102_0, arg_102_1)
	arg_102_0.selfChoosingPet = 2

	if arg_102_1 then
		local var_102_0 = var_0_2.new()

		var_102_0:initUnCollected(arg_102_1.table_id, nil, {
			star = arg_102_1.star
		})

		if not arg_102_0.model or arg_102_0.model ~= 1 then
			xyd.formatRegionArenaPetsAwake({
				var_102_0
			})
		end

		local var_102_1

		for iter_102_0, iter_102_1 in ipairs(arg_102_0.petTeam_) do
			var_102_1 = iter_102_1.data
		end

		if not var_102_1 then
			arg_102_0:clickPetAvatar(arg_102_0.petCells_[var_102_0:getTableID()])
		elseif var_102_0:getTableID() ~= var_102_1:getTableID() then
			arg_102_0:clickPetAvatar(arg_102_0.petCells_[var_102_0:getTableID()])
		end
	end

	arg_102_0.battleBtn_:setBright(false)
	arg_102_0.battleBtn_:setTouchEnabled(false)

	if arg_102_0.selfChoosingPet == 2 and arg_102_0.enemyChoosingPet == 2 then
		if arg_102_0.team_id == arg_102_0.totalteams then
			arg_102_0:startBattle()
		end
	else
		arg_102_0:enemyChoosePet()
	end
end

function var_0_0.updateEnemySelectPets(arg_103_0, arg_103_1)
	arg_103_0.enemyChoosingPet = 2

	if arg_103_1 then
		local var_103_0 = var_0_2.new()

		var_103_0:initUnCollected(arg_103_1.table_id, nil, {
			star = arg_103_1.star,
			color = arg_103_1.color
		})

		if not arg_103_0.model or arg_103_0.model ~= 1 then
			xyd.formatRegionArenaPetsAwake({
				var_103_0
			})
		end

		local var_103_1 = display.newNode()

		var_103_1:setContentSize(var_0_14, var_0_14)
		var_103_1:setAnchorPoint(cc.p(0.5, 0.5))
		var_103_1:addTo(arg_103_0:nodeByName("enemy_pet_container"))
		var_103_1:setPositionX(arg_103_0:nodeByName("enemy_pet_container"):getContentSize().width / 2)
		var_103_1:setPositionY(arg_103_0:nodeByName("enemy_pet_container"):getContentSize().height / 2)

		if arg_103_0.team_id >= 3 then
			local var_103_2 = xyd.AssetLoader.get():loadSprite("windows/across_arena/new_/pet_hide.png")

			xyd.displaySpriteOnContainer(var_103_2, var_103_1, true)
		else
			xyd.setPetAvatarNewUI(var_103_1, var_103_0, 100, true)
		end
	end

	if arg_103_0.selfChoosingPet == 2 and arg_103_0.enemyChoosingPet == 2 then
		if arg_103_0.team_id == arg_103_0.totalteams then
			arg_103_0:startBattle()
		end
	else
		arg_103_0:choosePet()
	end
end

function var_0_0.progress(arg_104_0, arg_104_1, arg_104_2)
	if arg_104_1 >= 6 then
		return
	end

	arg_104_0.selfProgress = 0
	arg_104_0.enemyProgress = 0

	local var_104_0 = 1

	for iter_104_0 = 1, arg_104_1 + 1 do
		local var_104_1 = (iter_104_0 == 1 or iter_104_0 == 6) and 1 or 2

		if iter_104_0 % 2 == 1 - arg_104_0.firstSelect then
			arg_104_0.selfProgress = arg_104_0.selfProgress + var_104_1
		else
			arg_104_0.enemyProgress = arg_104_0.enemyProgress + var_104_1
		end
	end
end

function var_0_0.updateSelectHeroes(arg_105_0, arg_105_1)
	local var_105_0 = os.clock()

	if arg_105_1.stage <= arg_105_0.stage then
		return
	end

	if arg_105_1.room_key ~= arg_105_0.room_key then
		return
	end

	arg_105_0.stageStartTime = arg_105_1.stage_start_time
	arg_105_0.ServerTime = arg_105_1.server_time

	arg_105_0:progress(arg_105_1.stage, arg_105_0.firstSelect)

	local function var_105_1(arg_106_0)
		local var_106_0

		if arg_105_0.firstSelect == 0 then
			var_106_0 = arg_105_0:updateEnemySelectHeroes(arg_106_0.B_partners_info)
		else
			var_106_0 = arg_105_0:updateEnemySelectHeroes(arg_106_0.A_partners_info)
		end

		arg_105_0.newEnemyHeroList = var_106_0

		arg_105_0:createEnemyHeroAvatarAndMotion()
	end

	if arg_105_1.stage >= 7 then
		arg_105_0.choosingPet = true
	end

	arg_105_0.stage = arg_105_1.stage

	if arg_105_0.firstSelect == 0 then
		arg_105_0:clearAlreadyEnemySelectHeros()
		arg_105_0:updateSelfSelectHeroes(arg_105_1.A_partners_info or {})
		var_105_1(arg_105_1)
	else
		arg_105_0:clearAlreadyEnemySelectHeros()
		arg_105_0:updateSelfSelectHeroes(arg_105_1.B_partners_info or {})
		var_105_1(arg_105_1)
	end

	if arg_105_1.stage == 0 then
		-- block empty
	elseif arg_105_0.choosingPet and arg_105_1.stage % 2 ~= 1 - arg_105_0.firstSelect then
		if arg_105_0.firstSelect == 0 then
			if arg_105_0.stage >= 8 and arg_105_0.selfChoosingPet ~= 2 then
				arg_105_0:updateSelfSelectPets(arg_105_1.A_pet_info)
			end

			arg_105_0:updateEnemySelectPets(arg_105_1.B_pet_info)
		else
			if arg_105_0.stage >= 8 and arg_105_0.selfChoosingPet ~= 2 then
				arg_105_0:updateSelfSelectPets(arg_105_1.B_pet_info)
			end

			arg_105_0:updateEnemySelectPets(arg_105_1.A_pet_info)
		end
	elseif arg_105_0.choosingPet and arg_105_1.stage % 2 == 1 - arg_105_0.firstSelect then
		if arg_105_0.firstSelect == 0 then
			if arg_105_0.stage >= 8 and arg_105_0.enemyChoosingPet ~= 2 then
				arg_105_0:updateEnemySelectPets(arg_105_1.B_pet_info)
			end

			arg_105_0:updateSelfSelectPets(arg_105_1.A_pet_info)
		else
			if arg_105_0.stage >= 8 and arg_105_0.enemyChoosingPet ~= 2 then
				arg_105_0:updateEnemySelectPets(arg_105_1.A_pet_info)
			end

			arg_105_0:updateSelfSelectPets(arg_105_1.B_pet_info)
		end
	elseif arg_105_1.stage % 2 == 1 - arg_105_0.firstSelect then
		arg_105_0.selectState = 1

		local var_105_2

		arg_105_0.countDown = arg_105_0.ServerTime + var_0_12 - arg_105_0.stageStartTime

		arg_105_0:selectStateMonitor()
		arg_105_0:updateSelfSelectStates()
		arg_105_0.battleBtn_:setBright(false)
		arg_105_0.battleBtn_:setTouchEnabled(false)

		if arg_105_1.stage < 5 and arg_105_1.stage > 1 then
			arg_105_0:controllLock(1)

			local var_105_3 = {
				message = var_0_5:translation("REGION_ARENA_TIP13")
			}

			xyd.WindowManager.get():openWindow("finding_enemy", var_105_3)
		elseif arg_105_1.stage == 5 or arg_105_1.stage == 1 then
			arg_105_0:controllLock(1)

			local var_105_4 = {
				message = var_0_5:translation("REGION_ARENA_TIP13")
			}

			xyd.WindowManager.get():openWindow("finding_enemy", var_105_4)
		else
			if arg_105_0.handle then
				var_0_7.unscheduleGlobal(arg_105_0.handle)

				arg_105_0.handle = nil
			end

			arg_105_0:enemyChoosePet()
		end

		arg_105_0.tempSelectHeros = {}
	else
		arg_105_0.selectState = 0
		arg_105_0.countDown = arg_105_0.ServerTime + var_0_12 - arg_105_0.stageStartTime

		arg_105_0:selectStateMonitor()
		arg_105_0:updateEnemySelectStates()

		if xyd.WindowManager.get():getWindow("finding_enemy") then
			xyd.WindowManager.get():closeWindow("finding_enemy")
		end

		arg_105_0.battleBtn_:setBright(true)
		arg_105_0.battleBtn_:setTouchEnabled(true)

		if arg_105_1.stage < 5 and arg_105_1.stage > 1 then
			arg_105_0:controllLock(0)

			local var_105_5 = var_0_5:translation("REGION_ARENA_TIP16")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_105_5
			})
		elseif arg_105_1.stage == 5 or arg_105_1.stage == 1 then
			arg_105_0:controllLock(0)

			local var_105_6 = var_0_5:translation("REGION_ARENA_TIP15")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_105_6
			})
		else
			if arg_105_0.handle then
				var_0_7.unscheduleGlobal(arg_105_0.handle)

				arg_105_0.handle = nil
			end

			arg_105_0:choosePet()
		end
	end

	print(os.clock() - var_105_0)
end

return var_0_0
