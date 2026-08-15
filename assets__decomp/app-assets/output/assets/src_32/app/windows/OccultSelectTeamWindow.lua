local var_0_0 = class("OccultSelectTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = import("framework.scheduler")
local var_0_4 = xyd.tables.translation
local var_0_5 = 30
local var_0_6 = 16
local var_0_7 = 7
local var_0_8 = 50
local var_0_9 = 4
local var_0_10 = 7
local var_0_11 = xyd.tables.misc
local var_0_12 = xyd.tables.hero
local var_0_13 = {
	RENT_HERO = 2,
	SELF_HERO = 1,
	SELF_PET = 3
}
local var_0_14 = {
	RENT_HERO = 1,
	RENT_PET = 2
}
local var_0_15 = {
	RENT_PET = 2,
	SELF_PET = 1
}
local var_0_16 = {
	YES = 2,
	NO = 1
}
local var_0_17 = class("ScrollView", cc.ui.UIListView)

function var_0_17.ctor(arg_1_0, arg_1_1)
	var_0_17.super.ctor(arg_1_0, arg_1_1)
end

function var_0_17.removeItem(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0, var_2_1 = arg_2_1:getItemSize()

	arg_2_0.container:removeChild(arg_2_1)

	local var_2_2 = arg_2_0:getItemPos(arg_2_1)

	if var_2_2 then
		table.remove(arg_2_0.items_, var_2_2)
	end

	local var_2_3 = 0

	arg_2_0.size.width = arg_2_0.size.width - var_2_0
	arg_2_0.size.height = arg_2_0.size.height - var_2_3

	if table.nums(arg_2_0.items_) == 0 then
		return
	end

	if var_2_2 <= var_0_10 then
		arg_2_0:moveItems(var_2_2, table.nums(arg_2_0.items_), -var_2_0, -var_2_3, arg_2_2)
	else
		arg_2_0:moveItems(1, var_2_2 - 1, var_2_0, var_2_3, arg_2_2)
	end

	return arg_2_0
end

function var_0_0.ctor(arg_3_0, arg_3_1, arg_3_2)
	var_0_0.super.ctor(arg_3_0, arg_3_1, arg_3_2)

	arg_3_0.campaignId = arg_3_2.campaign_id
	arg_3_0.subId = arg_3_2.sub_id
	arg_3_0.monstersInfo = arg_3_2.monsters_info
	arg_3_0.battleID = xyd.tables.creatsCampaign:getFightId(arg_3_0.campaignId, arg_3_0.subId)
	arg_3_0.monstersInfo = arg_3_2.monsters_info
	arg_3_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_3_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_3_0.occult = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)
	arg_3_0.occultCampaignType = arg_3_0.occult:getRoomCampaignType()
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	arg_4_0:clear()
	arg_4_0:init()
	arg_4_0:refreshSelectedHeroClass()
	arg_4_0:initEnermys()

	if arg_4_0.occultCampaignType == xyd.OccultRoomType.MULTI_PLAYER then
		arg_4_0:createScheduler()
	else
		arg_4_0:nodeByName("down_time_txt"):setVisible(false)
	end

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.UPDATE_FILTER_HEROS, handler(arg_4_0, arg_4_0.updateList))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.HERO_SEARCH, handler(arg_4_0, arg_4_0.updateListBySearchTxt))
end

function var_0_0.didClose(arg_5_0, arg_5_1)
	var_0_0.super.didClose(arg_5_0, arg_5_1)

	if arg_5_0.handle then
		var_0_3.unscheduleGlobal(arg_5_0.handle)

		arg_5_0.handle = nil
	end
end

function var_0_0.createScheduler(arg_6_0)
	if arg_6_0.handle then
		var_0_3.unscheduleGlobal(arg_6_0.handle)

		arg_6_0.handle = nil
	end

	arg_6_0.downTime = xyd.tables.misc.creatsTimeOut1

	arg_6_0:updateTimeShow()

	arg_6_0.handle = var_0_3.scheduleGlobal(function()
		arg_6_0.downTime = arg_6_0.downTime - 1

		arg_6_0:updateTimeShow()

		if arg_6_0.downTime <= 0 then
			var_0_3.unscheduleGlobal(arg_6_0.handle)

			arg_6_0.handle = nil

			arg_6_0:quitSingleFight()
		end
	end, 1)
end

function var_0_0.updateTimeShow(arg_8_0)
	local var_8_0 = arg_8_0.downTime

	if var_8_0 < 0 then
		var_8_0 = 0
	end

	arg_8_0:nodeByName("down_time_txt"):setString(string.format(var_0_4:translation("OCCULT_SELECT_TIME_TIP"), var_8_0))
end

function var_0_0.clear(arg_9_0)
	arg_9_0.totalHero_ = {}
	arg_9_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_9_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_9_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_9_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
	arg_9_0.totalHero_[xyd.DistanceType.FILTER] = {}

	for iter_9_0, iter_9_1 in pairs(arg_9_0.totalHero_) do
		iter_9_1[var_0_16.NO] = {}
		iter_9_1[var_0_16.YES] = {}
	end

	arg_9_0.teamCells_ = {}
	arg_9_0.heroCells_ = {}
	arg_9_0.bottomItems_ = {}
	arg_9_0.isAnimated_ = false
	arg_9_0.collocationType_ = var_0_16.NO
	arg_9_0.tmpTotalHero_ = {}
	arg_9_0.selectedHeroClass_ = {}
	arg_9_0.tmpTotalPets = {}
	arg_9_0.leftMenuType_ = var_0_13.SELF_HERO
	arg_9_0.rentMenuType = var_0_14.RENT_HERO
	arg_9_0.petTeam_ = {}
	arg_9_0.team_ = {}
	arg_9_0.select_ = {}
	arg_9_0.petTeam_ = {}
	arg_9_0.petSelect_ = {}
end

function var_0_0.init(arg_10_0)
	arg_10_0:initHeros(arg_10_0:getHeros(), var_0_13.SELF_HERO)
	arg_10_0:initPets(arg_10_0:getPets() or {}, var_0_15.SELF_PET)
	arg_10_0:layout()
	arg_10_0:selectHeros()
	arg_10_0:selectPets()
end

function var_0_0.initEnermys(arg_11_0)
	for iter_11_0, iter_11_1 in pairs(arg_11_0.monstersInfo) do
		local var_11_0 = arg_11_0.monstersInfo[iter_11_0]
		local var_11_1 = var_0_1.new()

		var_11_1:populateWithTableID(var_11_0.monster_id)
		xyd.setAvatarBorderNewUI(var_11_1, arg_11_0:nodeByName("enemy_hero_" .. iter_11_0))

		local var_11_2 = {}
		local var_11_3 = cc.Node:create()

		var_11_3:setAnchorPoint(cc.p(0, 0))
		var_11_3:setContentSize(100, 100)
		arg_11_0:nodeByName("enemy_hero_" .. iter_11_0):addChild(var_11_3)

		var_11_2.id = var_11_1.tableID_
		var_11_2.lev = var_11_1.level_
		var_11_2.quality = var_11_1.color_
		var_11_2.name = xyd.tables.hero:name(var_11_1.tableID_)
		var_11_2.desc = xyd.tables.hero:getDes(var_11_1.tableID_)
		var_11_2.stars = var_11_1.star_
		var_11_2.isHero = true
		var_11_2.isHero = true

		var_11_3:setTouchEnabled(true)
		var_11_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
			if arg_12_0.name == "began" then
				local var_12_0 = xyd.WindowManager.get():getWindow("new_item_tips")
				local var_12_1 = arg_11_0:convertToWorldSpace(cc.p(0, 0))

				if not var_12_0 then
					local var_12_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_11_2)

					xyd.adaptToWorldPosition(var_11_3, var_12_2)
				end

				return true
			elseif arg_12_0.name == "ended" and xyd.WindowManager.get():getWindow("new_item_tips") then
				local var_12_3 = xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)
	end
end

function var_0_0.getHeros(arg_13_0)
	local var_13_0 = {}
	local var_13_1 = {}
	local var_13_2 = arg_13_0.selfPlayer.heros_

	for iter_13_0, iter_13_1 in ipairs(var_13_2) do
		local var_13_3 = var_0_1.new()

		var_13_3:populate(iter_13_1:toParams())
		table.insert(var_13_0, var_13_3)
	end

	return var_13_0
end

function var_0_0.getPets(arg_14_0)
	local var_14_0 = {}

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.selfPlayer.collectedPets) do
		local var_14_1 = var_0_2.new()

		var_14_1:populate(iter_14_1:toParams())
		table.insert(var_14_0, var_14_1)
	end

	return var_14_0
end

function var_0_0.initHeros(arg_15_0, arg_15_1, arg_15_2)
	arg_15_0.tmpTotalHero_[arg_15_2] = {}
	arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.ALL] = {}
	arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.QIANPAI] = {}
	arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.ZHONGPAI] = {}
	arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.HOUPAI] = {}
	arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.FILTER] = {}

	for iter_15_0, iter_15_1 in pairs(arg_15_0.tmpTotalHero_[arg_15_2]) do
		iter_15_1[var_0_16.NO] = {}
		iter_15_1[var_0_16.YES] = {}
	end

	for iter_15_2, iter_15_3 in pairs(arg_15_1) do
		iter_15_3.type = arg_15_2

		if arg_15_0:canHeroJoinBattle(iter_15_3) then
			if iter_15_3:getDistanceType() == xyd.DistanceType.QIANPAI then
				table.insert(arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.QIANPAI][var_0_16.NO], iter_15_3)

				if iter_15_3:isCollocation() then
					table.insert(arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.QIANPAI][var_0_16.YES], iter_15_3)
				end
			elseif iter_15_3:getDistanceType() == xyd.DistanceType.ZHONGPAI then
				table.insert(arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.ZHONGPAI][var_0_16.NO], iter_15_3)

				if iter_15_3:isCollocation() then
					table.insert(arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.ZHONGPAI][var_0_16.YES], iter_15_3)
				end
			elseif iter_15_3:getDistanceType() == xyd.DistanceType.HOUPAI then
				table.insert(arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.HOUPAI][var_0_16.NO], iter_15_3)

				if iter_15_3:isCollocation() then
					table.insert(arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.HOUPAI][var_0_16.YES], iter_15_3)
				end
			end

			table.insert(arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.ALL][var_0_16.NO], iter_15_3)

			if iter_15_3:isCollocation() then
				table.insert(arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.ALL][var_0_16.YES], iter_15_3)
			end
		end
	end

	arg_15_0:updateFilterHeros()

	arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.FILTER] = arg_15_0.totalHero_[xyd.DistanceType.FILTER]

	arg_15_0:sortTables(arg_15_0.tmpTotalHero_[arg_15_2])

	arg_15_0.selectedHeroClass_[arg_15_2] = xyd.DistanceType.ALL
	arg_15_0.totalDispatchNum = arg_15_0:getDispathHerosNum(arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.ALL][var_0_16.NO])
end

function var_0_0.initPets(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = {}

	for iter_16_0, iter_16_1 in ipairs(arg_16_1) do
		if iter_16_1.is_show_ == 1 then
			table.insert(var_16_0, iter_16_1)
		end
	end

	table.sort(var_16_0, function(arg_17_0, arg_17_1)
		return xyd.petNormalSort(arg_17_0, arg_17_1) or false
	end)

	arg_16_0.tmpTotalPets[arg_16_2] = var_16_0
end

function var_0_0.sortTables(arg_18_0, arg_18_1)
	for iter_18_0 = 1, #arg_18_1 do
		table.sort(arg_18_1[iter_18_0][var_0_16.NO], function(arg_19_0, arg_19_1)
			if arg_18_0:isDispatchHero(arg_19_0) ~= arg_18_0:isDispatchHero(arg_19_1) then
				return arg_18_0:isDispatchHero(arg_19_0) > arg_18_0:isDispatchHero(arg_19_1)
			end

			return xyd.heroNormalSort(arg_19_0, arg_19_1) or false
		end)
		table.sort(arg_18_1[iter_18_0][var_0_16.YES], function(arg_20_0, arg_20_1)
			if arg_18_0:isDispatchHero(arg_20_0) ~= arg_18_0:isDispatchHero(arg_20_1) then
				return arg_18_0:isDispatchHero(arg_20_0) > arg_18_0:isDispatchHero(arg_20_1)
			end

			return xyd.heroNormalSort(arg_20_0, arg_20_1) or false
		end)
	end
end

function var_0_0.isDispatchHero(arg_21_0, arg_21_1)
	if xyd.isInTable(table.keys(arg_21_0.occult.dispatchInfo or {}), tostring(arg_21_1:getHeroID())) then
		if arg_21_0.occult.dispatchInfo[tostring(arg_21_1:getHeroID())].hp <= 0 then
			return 1
		end

		return 2
	end

	return 0
end

function var_0_0.layout(arg_22_0)
	arg_22_0:initText()
	arg_22_0:initListView()
	arg_22_0:setButtonClick()
	arg_22_0:updateScore()
end

function var_0_0.initText(arg_23_0)
	arg_23_0:nodeByName("text_title"):setString(var_0_4:translation("SELECT_TEAM_TEXT_2"))
	arg_23_0:nodeByName("enermy_formation_text"):setString(var_0_4:translation("MAP_ENEMY_TXT"))
	arg_23_0:nodeByName("text_zhandui"):setString(var_0_4:translation("PERSON_SELECT_HERO"))
	arg_23_0:nodeByName("text_pet"):setString(var_0_4:translation("PERSON_SELECT_PET"))
	arg_23_0:nodeByName("text_filter"):setString(var_0_4:translation("FILTER_TEXT"))
	arg_23_0:nodeByName("text_all"):setString(var_0_4:translation("TUJIAN_BUTTON_TEXT1"))
	arg_23_0:nodeByName("text_qianpai"):setString(var_0_4:translation("TUJIAN_BUTTON_TEXT2"))
	arg_23_0:nodeByName("text_zhongpai"):setString(var_0_4:translation("TUJIAN_BUTTON_TEXT3"))
	arg_23_0:nodeByName("text_houpai"):setString(var_0_4:translation("TUJIAN_BUTTON_TEXT4"))
	arg_23_0:nodeByName("text_zhandouli"):setString(var_0_4:translation("HERO_MAIN_TEXT_11"))
end

function var_0_0.initListView(arg_24_0)
	local var_24_0 = arg_24_0:nodeByName("list_layer")
	local var_24_1 = var_24_0:getContentSize()

	if not arg_24_0.heroList_ then
		local var_24_2 = 0

		if arg_24_0.occultCampaignType ~= xyd.OccultRoomType.MULTI_PLAYER then
			var_24_2 = 27
		end

		arg_24_0.heroList_ = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_24_1.width, var_24_1.height + var_24_2),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(var_24_0)
		arg_24_0.heroCells_ = {}

		arg_24_0.heroList_:setDelegate(handler(arg_24_0, arg_24_0.delegate))
	end
end

function var_0_0.delegate(arg_25_0, ...)
	if arg_25_0.leftMenuType_ == var_0_13.SELF_PET or arg_25_0.leftMenuType_ == var_0_13.RENT_HERO and arg_25_0.rentMenuType == var_0_14.RENT_PET then
		return arg_25_0:petDelegate(...)
	end

	return arg_25_0:heroDelegate(...)
end

function var_0_0.heroDelegate(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	if arg_26_0.leftMenuType_ == var_0_13.SELF_HERO then
		var_0_7 = 7
	else
		var_0_7 = 5
	end

	arg_26_0.dispatchNum = arg_26_0:getDispathHerosNum(arg_26_0.totalHero_[arg_26_0.selectedHeroClass_[arg_26_0.leftMenuType_]][arg_26_0.collocationType_])
	arg_26_0.totalNum = #arg_26_0.totalHero_[arg_26_0.selectedHeroClass_[arg_26_0.leftMenuType_]][arg_26_0.collocationType_]

	local var_26_0 = math.ceil(arg_26_0.dispatchNum / var_0_7) + math.ceil((arg_26_0.totalNum - arg_26_0.dispatchNum) / var_0_7) + 2

	if cc.ui.UIListView.COUNT_TAG == arg_26_2 then
		return var_26_0
	elseif cc.ui.UIListView.CELL_TAG == arg_26_2 then
		local var_26_1
		local var_26_2 = arg_26_0.heroList_:dequeueItem()

		if not var_26_2 then
			var_26_2 = arg_26_0.heroList_:newItem()
		else
			var_26_2:removeAllChildren(true)
		end

		local var_26_3

		if arg_26_3 == 1 or arg_26_3 == math.ceil(arg_26_0.dispatchNum / var_0_7) + 2 then
			var_26_3 = arg_26_0:createTitleContent(arg_26_3)
		else
			var_26_3 = arg_26_0:createListContent(arg_26_3)
		end

		var_26_2:setItemSize(arg_26_0.heroList_.viewRect_.width, var_26_3:getContentSize().height)
		var_26_2:addContent(var_26_3)

		return var_26_2
	end
end

function var_0_0.createTitleContent(arg_27_0, arg_27_1)
	local var_27_0 = display.newNode()
	local var_27_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/occult/select_team/title.csb")
	local var_27_2 = var_27_1:getChildByName("container")
	local var_27_3 = string.format(var_0_4:translation("OCCULT_DISPATCH_HERO_TEXT"), arg_27_0.totalDispatchNum, arg_27_0.occult.baseInfo.dispatch_limit or xyd.tables.misc.creatsDispatchHeroLimit)

	if arg_27_1 > 1 then
		var_27_3 = var_0_4:translation("OCCULT_UNDISPATCH_HERO_TEXT")
	end

	var_27_2:getChildByName("text"):setString(var_27_3)
	var_27_1:addTo(var_27_0)
	var_27_1:setAnchorPoint(cc.p(0, 0))
	var_27_0:setContentSize(var_27_2:getContentSize())
	var_27_1:setName("source")

	return var_27_0
end

function var_0_0.createListContent(arg_28_0, arg_28_1)
	local var_28_0 = display.newNode()

	var_28_0:setTouchSwallowEnabled(false)

	local var_28_1
	local var_28_2 = math.ceil(arg_28_0.dispatchNum / var_0_7) + 3

	for iter_28_0 = 1, var_0_7 do
		if (arg_28_1 - 2) * var_0_7 + iter_28_0 <= arg_28_0.dispatchNum then
			local var_28_3 = (arg_28_1 - 2) * var_0_7 + iter_28_0

			var_28_1 = arg_28_0:initHeroCell(var_28_3)

			local var_28_4 = var_28_1:getContentSize().width
			local var_28_5 = var_28_1:getContentSize().height
			local var_28_6 = (arg_28_0.heroList_.viewRect_.width - var_28_4 * var_0_7) / (var_0_7 + 1)

			var_28_1:pos(var_28_6 * iter_28_0 + (iter_28_0 - 1) * var_28_4 + var_28_4 / 2, var_0_5 + var_28_5 / 2 - 2)
			var_28_0:addChild(var_28_1)

			arg_28_0.heroCells_[var_28_3] = var_28_1
		elseif var_28_2 <= arg_28_1 and (arg_28_1 - var_28_2) * var_0_7 + iter_28_0 + arg_28_0.dispatchNum <= arg_28_0.totalNum then
			local var_28_7 = (arg_28_1 - var_28_2) * var_0_7 + iter_28_0 + arg_28_0.dispatchNum

			var_28_1 = arg_28_0:initHeroCell(var_28_7)

			local var_28_8 = var_28_1:getContentSize().width
			local var_28_9 = var_28_1:getContentSize().height
			local var_28_10 = (arg_28_0.heroList_.viewRect_.width - var_28_8 * var_0_7) / (var_0_7 + 1)

			var_28_1:pos(var_28_10 * iter_28_0 + (iter_28_0 - 1) * var_28_8 + var_28_8 / 2, var_0_5 + var_28_9 / 2 - 2)
			var_28_0:addChild(var_28_1)

			arg_28_0.heroCells_[var_28_7] = var_28_1
		end
	end

	var_28_0:setContentSize(cc.size(arg_28_0.heroList_.viewRect_.width, var_28_1:getContentSize().height + var_0_5))

	return var_28_0
end

function var_0_0.getDispathHerosNum(arg_29_0, arg_29_1)
	local var_29_0 = 0

	for iter_29_0 = 1, #arg_29_1 do
		if arg_29_0:isDispatchHero(arg_29_1[iter_29_0]) > 0 then
			var_29_0 = var_29_0 + 1
		else
			return var_29_0
		end
	end

	return var_29_0
end

function var_0_0.petDelegate(arg_30_0, arg_30_1, arg_30_2, arg_30_3)
	if arg_30_0.leftMenuType_ == var_0_13.SELF_PET then
		var_0_9 = 5
	else
		var_0_9 = 4
	end

	local var_30_0 = math.ceil(#arg_30_0.totalPet_ / var_0_9)

	if cc.ui.UIListView.COUNT_TAG == arg_30_2 then
		return var_30_0
	elseif cc.ui.UIListView.CELL_TAG == arg_30_2 then
		local var_30_1
		local var_30_2
		local var_30_3
		local var_30_4 = arg_30_0.heroList_:dequeueItem()

		if not var_30_4 then
			var_30_4 = arg_30_0.heroList_:newItem()
		else
			var_30_4:removeAllChildren()
		end

		local var_30_5 = display.newNode()

		var_30_5:setTouchSwallowEnabled(false)

		for iter_30_0 = 1, var_0_9 do
			local var_30_6 = (arg_30_3 - 1) * var_0_9 + iter_30_0

			if var_30_6 > #arg_30_0.totalPet_ then
				break
			end

			var_30_3 = display.newNode()

			arg_30_0:initPetCell(var_30_3, var_30_6)

			local var_30_7 = var_30_3:getContentSize().width
			local var_30_8 = var_30_3:getContentSize().height
			local var_30_9 = (arg_30_0.heroList_.viewRect_.width - var_30_7 * var_0_9) / (var_0_9 + 1)

			var_30_3:align(display.CENTER, var_30_9 * iter_30_0 + (iter_30_0 - 1) * var_30_7 + var_30_7 / 2, var_30_8 / 2)
			var_30_5:addChild(var_30_3)
		end

		var_30_5:setContentSize(cc.size(arg_30_0.heroList_.viewRect_.width, var_30_3:getContentSize().height))
		var_30_4:setItemSize(arg_30_0.heroList_.viewRect_.width, var_30_3:getContentSize().height)
		var_30_4:addContent(var_30_5)

		return var_30_4
	end
end

function var_0_0.initHeroCell(arg_31_0, arg_31_1)
	local var_31_0 = display.newNode()
	local var_31_1 = arg_31_0.totalHero_[arg_31_0.selectedHeroClass_[arg_31_0.leftMenuType_]][arg_31_0.collocationType_][arg_31_1]

	var_31_1.healthStatus = nil

	local var_31_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/hero_avatar_new.csb")

	var_31_2:getChildByName("yongbing_tubiao"):setVisible(false)

	local var_31_3 = var_31_2:getChildByName("background"):getContentSize()

	var_31_2:setContentSize(var_31_3)
	var_31_0:setContentSize(var_31_3)
	xyd.setAvatarBorderNewUI(var_31_1, var_31_2:getChildByName("avatar"))

	local var_31_4 = var_31_2:getChildByName("chosen")

	var_31_4:setLocalZOrder(100)
	var_31_4:setVisible(false)

	local var_31_5 = var_31_2:getChildByName("avatar_mask")

	var_31_5:setLocalZOrder(2)
	var_31_5:setVisible(false)

	var_31_0.type = var_0_13.SELF_HERO

	var_31_2:getChildByName("is_can_rent"):setVisible(false)

	for iter_31_0 = 1, 3 do
		var_31_2:getChildByName("team" .. iter_31_0):setVisible(false)
	end

	local var_31_6 = var_31_2:getChildByName("lv_txt")

	var_31_6:setString(var_31_1:getLevel())
	var_31_6:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	var_31_2:getChildByName("name_text"):setString(var_31_1:getName())

	local var_31_7 = var_31_2:getChildByName("hp_bar")
	local var_31_8 = var_31_2:getChildByName("mp_bar")
	local var_31_9 = var_31_2:getChildByName("dead_text")

	var_31_9:setString(var_0_4:translation("ALREADY_DEAD"))

	if var_31_9 then
		var_31_9:setVisible(false)
	end

	local var_31_10 = false
	local var_31_11 = arg_31_0.occult.dispatchInfo

	if var_31_11 and next(var_31_11) ~= nil and arg_31_0:isDispatchHero(var_31_1) > 0 then
		local var_31_12 = var_31_11[tostring(var_31_1:getHeroID())]

		var_31_1.healthStatus = var_31_12

		local var_31_13 = 0
		local var_31_14 = 0

		if var_31_12 and not var_31_12.mp then
			var_31_12.mp = 0
		end

		if var_31_12 and not var_31_12.total_hp then
			var_31_13 = 100
			var_31_14 = var_31_12.mp * 100 / xyd.ENERGY_DECIMAL_BASE
		elseif var_31_12 and var_31_12.hp > 0 and var_31_12.total_hp > 0 then
			var_31_13 = var_31_12.hp * 100 / var_31_12.total_hp
			var_31_14 = var_31_12.mp * 100 / xyd.ENERGY_DECIMAL_BASE
		elseif var_31_12 and var_31_12.hp == 0 then
			var_31_13 = 0
			var_31_14 = 0

			var_31_5:setVisible(true)
			var_31_9:setLocalZOrder(3)
			var_31_9:setVisible(true)
			var_31_9:getVirtualRenderer():setAdditionalKerning(2)

			var_31_10 = true
		end

		var_31_7:setPercent(var_31_13)
		var_31_7:setVisible(true)
		var_31_8:setPercent(var_31_14)
		var_31_8:setVisible(true)
	else
		var_31_7:hide()
		var_31_8:hide()
		var_31_2:getChildByName("hp_di"):hide()
		var_31_2:getChildByName("mp_di"):hide()
	end

	var_31_2:setName("layout")
	var_31_2:setPosition(cc.p(0, 0))

	var_31_0.data = var_31_1

	for iter_31_1, iter_31_2 in ipairs(arg_31_0.select_) do
		if iter_31_2:getTableID() == var_31_1:getTableID() and iter_31_2.player_name == var_31_1.player_name then
			var_31_0.teamNo_ = iter_31_1

			var_31_4:setVisible(true)
			var_31_5:setVisible(true)

			arg_31_0.team_[iter_31_1].iniCell_ = var_31_0
			arg_31_0.team_[iter_31_1].iniCellVisible_ = false

			break
		end
	end

	var_31_1.isDead = var_31_10

	var_31_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_31_0:addChild(var_31_2)
	var_31_0:setTouchSwallowEnabled(false)
	var_31_0:setTouchEnabled(true)
	var_31_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_32_0)
		arg_31_0:buttonHandler(nil, var_31_0, arg_32_0)

		if arg_32_0.name == "began" then
			arg_31_0.startClick_ = true
			arg_31_0.prevX_ = arg_32_0.x
			arg_31_0.prevY_ = arg_32_0.y
		elseif arg_32_0.name == "moved" then
			if math.abs(arg_32_0.y - arg_31_0.prevY_) > 5 or math.abs(arg_32_0.x - arg_31_0.prevX_) > 5 then
				arg_31_0.startClick_ = false
			end
		elseif arg_32_0.name == "ended" and arg_31_0.startClick_ then
			if var_31_10 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_4:translation("HERO_DIE_ERROR")
				})

				return
			end

			arg_31_0:clickAvatar(var_31_0)
		end

		return true
	end)

	return var_31_0
end

function var_0_0.setHeroCellSelectedState(arg_33_0, arg_33_1)
	local var_33_0

	if arg_33_0.leftMenuType_ == var_0_13.SELF_HERO then
		var_33_0 = arg_33_1:getChildByName("layout")
	else
		var_33_0 = arg_33_1:getChildByName("yongbingCell"):getChildByName("container")
	end

	local var_33_1 = var_33_0:getChildByName("avatar_mask")
	local var_33_2 = var_33_0:getChildByName("chosen")

	arg_33_1.isSelected = true

	var_33_1:setVisible(true)
	var_33_2:setVisible(true)
end

function var_0_0.setHeroCellUnSelectedState(arg_34_0, arg_34_1, arg_34_2)
	local var_34_0

	if arg_34_0.leftMenuType_ == var_0_13.SELF_HERO or arg_34_2 then
		var_34_0 = arg_34_1:getChildByName("layout")
	else
		var_34_0 = arg_34_1:getChildByName("yongbingCell"):getChildByName("container")
	end

	local var_34_1 = var_34_0:getChildByName("avatar_mask")
	local var_34_2 = var_34_0:getChildByName("chosen")

	var_34_2:setLocalZOrder(100)
	var_34_1:setLocalZOrder(2)

	arg_34_1.isSelected = false

	var_34_1:setVisible(false)
	var_34_2:setVisible(false)
end

function var_0_0.buttonHandler(arg_35_0, arg_35_1, arg_35_2, arg_35_3)
	if not arg_35_2 or not arg_35_2:getParent() then
		return
	end

	if arg_35_3.name == "ended" then
		transition.stopTarget(arg_35_2)
		arg_35_2:setScale(1)

		if arg_35_1 then
			arg_35_1(arg_35_2, eventType)
		end
	elseif arg_35_3.name == "began" then
		local var_35_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_35_2:runAction(var_35_0)

		return true
	elseif arg_35_3.name == "cancled" then
		transition.stopTarget(arg_35_2)
		arg_35_2:setScale(1)
	end
end

function var_0_0.setButtonClick(arg_36_0)
	arg_36_0:initLeftMenu()
	arg_36_0:initRightMenu()
	arg_36_0:nodeByName("button_battle"):setVisible(false)
	arg_36_0:nodeByName("button_ok"):addTouchEventListener(function(arg_37_0, arg_37_1)
		xyd.buttonScaleAnim(arg_37_0, arg_37_1)

		if arg_37_1 == ccui.TouchEventType.ended then
			if #arg_36_0.select_ < 1 then
				local var_37_0 = var_0_4:translation("BATTLE_NO_HERO")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_37_0
				})

				return
			end

			local var_37_1 = {
				campaign_id = arg_36_0.campaignId,
				sub_id = arg_36_0.subId
			}

			arg_36_0.occult:startSingleFight(var_37_1, function(arg_38_0, arg_38_1)
				if arg_38_0 == xyd.error.OK then
					if arg_38_1.sub_monster_infos then
						arg_36_0.monstersInfo = arg_38_1.sub_monster_infos
					end

					arg_36_0:startBattle()
				end
			end)
		end
	end)
	arg_36_0:nodeByName("button_collocation"):addTouchEventListener(function(arg_39_0, arg_39_1)
		xyd.buttonScaleAnim(arg_39_0, arg_39_1)

		if arg_39_1 == ccui.TouchEventType.ended then
			if arg_36_0.leftMenuType_ ~= var_0_13.SELF_HERO then
				return
			end

			arg_36_0.collocationType_ = 3 - arg_36_0.collocationType_

			arg_36_0:refreshSelectedHeroClass()
		end
	end)
	arg_36_0:nodeByName("close"):addTouchEventListener(function(arg_40_0, arg_40_1)
		if arg_40_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_36_0:quitSingleFight()
		end
	end)
end

function var_0_0.quitSingleFight(arg_41_0)
	local var_41_0 = {
		campaign_id = arg_41_0.campaignId,
		sub_id = arg_41_0.subId
	}

	arg_41_0.occult:quitSingleFight(var_41_0, function(arg_42_0, arg_42_1)
		if arg_42_0 == xyd.error.OK then
			xyd.WindowManager.get():closeWindow(arg_41_0)
		end
	end)
end

function var_0_0.startBattle(arg_43_0)
	local var_43_0 = false
	local var_43_1 = {
		herosA = {},
		herosB = {}
	}
	local var_43_2 = {}

	for iter_43_0, iter_43_1 in ipairs(arg_43_0.team_) do
		iter_43_1.data.type = iter_43_1.type

		table.insert(var_43_2, iter_43_1.data)
		table.insert(var_43_1.herosA, iter_43_1.data)
	end

	var_43_1.petsA = {}

	for iter_43_2, iter_43_3 in ipairs(arg_43_0.petSelect_) do
		table.insert(var_43_1.petsA, iter_43_3)
	end

	var_43_1.campaignType = xyd.CampaignType.OCCULT
	var_43_1.campaignID = arg_43_0.campaignId
	var_43_1.battleID = arg_43_0.battleID
	var_43_1.sub_id = arg_43_0.subId
	var_43_1.chapter_id = arg_43_0.occult.baseInfo.chapter_id

	local var_43_3 = arg_43_0:getFormationStr(var_43_2)

	var_43_1.fightParams = {
		campaign_id = var_43_1.campaignID,
		formation = var_43_3
	}

	local var_43_4 = arg_43_0.monstersInfo

	var_43_1.herosB = {}

	local var_43_5 = {}

	for iter_43_4, iter_43_5 in pairs(var_43_4) do
		local var_43_6 = var_0_1.new()

		var_43_6:populateWithTableID(iter_43_5.monster_id)

		var_43_6.heroID_ = iter_43_5.partner_id
		iter_43_5.health = 1
		var_43_6.healthStatus = iter_43_5

		if iter_43_5.hp > 0 then
			table.insert(var_43_5, var_43_6)
		end
	end

	table.insert(var_43_1.herosB, var_43_5)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "single_day"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_43_1)
end

function var_0_0.getFormationStr(arg_44_0, arg_44_1)
	local var_44_0 = ""

	for iter_44_0, iter_44_1 in ipairs(arg_44_1) do
		var_44_0 = var_44_0 .. string.format("%d", iter_44_1:getHeroID())

		if iter_44_0 < #arg_44_1 then
			var_44_0 = var_44_0 .. "|"
		end
	end

	return var_44_0
end

function var_0_0.initRightMenu(arg_45_0)
	arg_45_0.rightMenuButtons_ = {}

	table.insert(arg_45_0.rightMenuButtons_, arg_45_0:nodeByName("button_all"))
	table.insert(arg_45_0.rightMenuButtons_, arg_45_0:nodeByName("button_qianpai"))
	table.insert(arg_45_0.rightMenuButtons_, arg_45_0:nodeByName("button_zhongpai"))
	table.insert(arg_45_0.rightMenuButtons_, arg_45_0:nodeByName("button_houpai"))
	table.insert(arg_45_0.rightMenuButtons_, arg_45_0:nodeByName("button_filter"))
	table.insert(arg_45_0.rightMenuButtons_, arg_45_0:nodeByName("button_search"))

	for iter_45_0 = 1, #arg_45_0.rightMenuButtons_ do
		arg_45_0.rightMenuButtons_[iter_45_0]:setZoomScale(0.3)
		arg_45_0.rightMenuButtons_[iter_45_0]:addTouchEventListener(function(arg_46_0, arg_46_1)
			if arg_46_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				if arg_45_0.selectedHeroClass_[arg_45_0.leftMenuType_] == iter_45_0 then
					for iter_46_0 = 1, #arg_45_0.rightMenuButtons_ do
						if iter_46_0 == arg_45_0.selectedHeroClass_[arg_45_0.leftMenuType_] then
							arg_45_0.rightMenuButtons_[iter_46_0]:setBrightStyle(ccui.BrightStyle.highlight)
						else
							arg_45_0.rightMenuButtons_[iter_46_0]:setBrightStyle(ccui.BrightStyle.normal)
						end
					end

					return
				end

				arg_45_0.selectedHeroClass_[arg_45_0.leftMenuType_] = iter_45_0

				arg_45_0:refreshSelectedHeroClass()
			end
		end)
	end

	arg_45_0:nodeByName("button_filter"):addTouchEventListener(function(arg_47_0, arg_47_1)
		xyd.buttonScaleAnim(arg_47_0, arg_47_1)

		if arg_47_1 == ccui.TouchEventType.ended then
			if arg_45_0.leftMenuType_ ~= var_0_13.SELF_HERO then
				return
			end

			xyd.WindowManager.get():openWindow("hero_filter_wnd")
		end
	end)
	arg_45_0:nodeByName("button_search"):addTouchEventListener(function(arg_48_0, arg_48_1)
		xyd.buttonScaleAnim(arg_48_0, arg_48_1)

		if arg_48_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("hero_search_wnd")
		end
	end)
end

function var_0_0.updateList(arg_49_0, ...)
	if arg_49_0.leftMenuType_ ~= var_0_13.SELF_HERO then
		return
	end

	arg_49_0.selectedHeroClass_[arg_49_0.leftMenuType_] = xyd.DistanceType.FILTER
	arg_49_0.isHeroPreset = false

	arg_49_0:updateFilterHeros()
	arg_49_0:refreshSelectedHeroClass()
end

function var_0_0.updateListBySearchTxt(arg_50_0, arg_50_1)
	arg_50_0.searchTxt = arg_50_1.heroName
	arg_50_0.selectedHeroClass_[arg_50_0.leftMenuType_] = xyd.DistanceType.SEARCH

	arg_50_0:updateSearchHeros()
	arg_50_0:refreshSelectedHeroClass()
end

function var_0_0.updateSearchHeros(arg_51_0)
	arg_51_0.totalHero_[xyd.DistanceType.SEARCH] = {}
	arg_51_0.totalHero_[xyd.DistanceType.SEARCH][var_0_16.YES] = {}
	arg_51_0.totalHero_[xyd.DistanceType.SEARCH][var_0_16.NO] = {}

	if arg_51_0.searchTxt ~= "" then
		for iter_51_0, iter_51_1 in pairs(arg_51_0.totalHero_[xyd.DistanceType.ALL][var_0_16.NO]) do
			if xyd.searchHeroByName(arg_51_0.searchTxt, iter_51_1) then
				table.insert(arg_51_0.totalHero_[xyd.DistanceType.SEARCH][var_0_16.NO], iter_51_1)
			end
		end

		for iter_51_2, iter_51_3 in pairs(arg_51_0.totalHero_[xyd.DistanceType.ALL][var_0_16.YES]) do
			if xyd.searchHeroByName(arg_51_0.searchTxt, iter_51_3) then
				table.insert(arg_51_0.totalHero_[xyd.DistanceType.SEARCH][var_0_16.YES], iter_51_3)
			end
		end
	end
end

function var_0_0.initLeftMenu(arg_52_0)
	arg_52_0:nodeByName("button_zhandui"):hide()

	arg_52_0:nodeByName("button_zhandui").menu_type = var_0_13.SELF_HERO

	arg_52_0:nodeByName("button_pet"):hide()

	arg_52_0:nodeByName("button_pet").menu_type = var_0_13.SELF_PET
	arg_52_0.leftMenuType_ = var_0_13.SELF_HERO
	arg_52_0.leftMenuButtons_, arg_52_0.leftMenuText_ = {}, {}

	table.insert(arg_52_0.leftMenuButtons_, arg_52_0:nodeByName("button_zhandui"))
	table.insert(arg_52_0.leftMenuButtons_, arg_52_0:nodeByName("button_pet"))

	if #arg_52_0.leftMenuButtons_ <= 1 then
		return
	end

	for iter_52_0 = 1, #arg_52_0.leftMenuButtons_ do
		arg_52_0.leftMenuButtons_[iter_52_0]:show()
		arg_52_0.leftMenuButtons_[iter_52_0]:setZoomScale(0.3)

		local var_52_0 = arg_52_0.leftMenuButtons_[1]:getY() - 85 * (iter_52_0 - 1)

		arg_52_0.leftMenuButtons_[iter_52_0]:y(var_52_0)
		arg_52_0.leftMenuButtons_[iter_52_0]:addTouchEventListener(function(arg_53_0, arg_53_1)
			if arg_53_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				for iter_53_0, iter_53_1 in ipairs(arg_52_0.leftMenuButtons_) do
					iter_53_1:setBrightStyle(arg_53_0 == iter_53_1 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
				end

				arg_52_0.leftMenuType_ = arg_53_0.menu_type

				arg_52_0:selectHeros()
				arg_52_0:selectPets()
				arg_52_0:refreshSelectedHeroClass()
			end
		end)
	end

	for iter_52_1, iter_52_2 in ipairs(arg_52_0.leftMenuButtons_) do
		if iter_52_2 == arg_52_0:nodeByName("button_zhandui") then
			iter_52_2:setBrightStyle(ccui.BrightStyle.highlight)
		else
			iter_52_2:setBrightStyle(ccui.BrightStyle.normal)
		end
	end
end

function var_0_0.refreshSelectedHeroClass(arg_54_0)
	for iter_54_0 = 1, #arg_54_0.rightMenuButtons_ do
		if iter_54_0 == arg_54_0.selectedHeroClass_[arg_54_0.leftMenuType_] then
			arg_54_0.rightMenuButtons_[iter_54_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_54_0.rightMenuButtons_[iter_54_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_54_0.heroList_:removeAllItems()

	if arg_54_0.selectedHeroClass_[arg_54_0.leftMenuType_] ~= xyd.DistanceType.ALL then
		for iter_54_1, iter_54_2 in ipairs(arg_54_0.select_) do
			if iter_54_2:getDistanceType() ~= arg_54_0.selectedHeroClass_[arg_54_0.leftMenuType_] then
				arg_54_0.team_[iter_54_1].iniCellVisible_ = true
			end
		end
	end

	arg_54_0.heroList_:reload()
end

function var_0_0.selectHeros(arg_55_0)
	arg_55_0.totalHero_ = arg_55_0.tmpTotalHero_[arg_55_0.leftMenuType_]
end

function var_0_0.selectPets(arg_56_0)
	arg_56_0.totalPet_ = arg_56_0.tmpTotalPets[var_0_15.SELF_PET]
end

function var_0_0.getHeroList(arg_57_0)
	local var_57_0 = {}

	for iter_57_0, iter_57_1 in ipairs(arg_57_0.teamCells_) do
		table.insert(var_57_0, iter_57_1.hero)
	end

	return var_57_0
end

function var_0_0.clickAvatar(arg_58_0, arg_58_1, arg_58_2)
	if arg_58_1.isAnimated_ or not arg_58_1.teamNo_ and #arg_58_0.team_ >= xyd.MAX_TEAM_MEMBER_NUM then
		return
	end

	if not arg_58_2 then
		arg_58_0.unPreSelect_ = true
	end

	local var_58_0 = arg_58_1:getChildByName("layout")
	local var_58_1 = var_58_0:getChildByName("avatar_mask")
	local var_58_2 = var_58_0:getChildByName("chosen")
	local var_58_3 = arg_58_1:convertToWorldSpace(cc.p(0, 0))
	local var_58_4 = var_58_3.x + arg_58_1:getContentSize().width / 2
	local var_58_5 = var_58_3.y + arg_58_1:getContentSize().height / 2

	arg_58_1.isAnimated_ = true

	if arg_58_1.teamNo_ then
		local var_58_6 = arg_58_0.team_[arg_58_1.teamNo_]

		arg_58_0:moveFadeOutAction(var_58_4, var_58_5, var_58_6, function()
			arg_58_1.isAnimated_ = false
		end)
		var_58_1:setVisible(false)
		var_58_2:setVisible(false)

		for iter_58_0 = #arg_58_0.team_, arg_58_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_58_0.team_[iter_58_0])

			local var_58_7, var_58_8 = arg_58_0:nodeByName("avatar" .. iter_58_0 - 1):getPosition()

			transition.moveTo(arg_58_0.team_[iter_58_0], {
				time = 0.3,
				x = var_58_7,
				y = var_58_8
			})

			arg_58_0.team_[iter_58_0].iniCell_.teamNo_ = iter_58_0 - 1
		end

		table.remove(arg_58_0.team_, arg_58_1.teamNo_)
		table.remove(arg_58_0.select_, arg_58_1.teamNo_)

		arg_58_1.teamNo_ = nil
	elseif not arg_58_1.teamNo_ and #arg_58_0.team_ < xyd.MAX_TEAM_MEMBER_NUM then
		if arg_58_0:checkIsDispatchFull(arg_58_1.data) then
			local var_58_9 = var_0_4:translation("OCCULT_DISPATCH_LIMIT_TIP")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_58_9
			})

			return
		end

		if not arg_58_2 then
			local var_58_10 = arg_58_1.data

			if var_0_12:chosenSound(var_58_10:getTableID()) ~= "" then
				xyd.AssetDownload.get():preloadCharacterSound({
					var_58_10:getTableID()
				}, function()
					return
				end, true)
				audio.playSound(var_0_12:chosenSound(var_58_10:getTableID()), false)
			end
		end

		if arg_58_1.data.isDead then
			arg_58_1.isAnimated_ = false

			return
		end

		local var_58_11 = arg_58_0:initBottomCell(arg_58_1.data)

		var_58_11.iniCell_ = arg_58_1

		var_58_11:pos(var_58_4, var_58_5)
		var_58_11:addTo(arg_58_0)
		var_58_11:setTouchEnabled(true)

		var_58_11.data = arg_58_1.data

		var_58_11:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_61_0)
			if arg_61_0.name == "ended" then
				arg_58_0:clickBottomAvatar(var_58_11)
			end

			return true
		end)

		arg_58_1.teamNo_ = arg_58_0:getTeamNo(var_58_11)

		for iter_58_1 = arg_58_1.teamNo_, #arg_58_0.team_ do
			local var_58_12, var_58_13 = arg_58_0:nodeByName("avatar" .. iter_58_1):getPosition()

			if arg_58_2 then
				arg_58_0.team_[iter_58_1]:pos(var_58_12, var_58_13)

				arg_58_1.isAnimated_ = false
			elseif iter_58_1 ~= arg_58_1.teamNo_ then
				local var_58_14 = arg_58_0.team_[iter_58_1]

				transition.stopTarget(var_58_14)
				transition.moveTo(var_58_14, {
					time = 0.3,
					x = var_58_12,
					y = var_58_13,
					onComplete = function()
						var_58_14.iniCell_.isAnimated_ = false
						var_58_14.isAnimated_ = false
					end
				})
			else
				local var_58_15 = arg_58_0.team_[iter_58_1]

				transition.stopTarget(var_58_15)

				var_58_11.isAnimated_ = true

				transition.moveTo(var_58_15, {
					time = 0.3,
					x = var_58_12,
					y = var_58_13,
					onComplete = function()
						arg_58_1.isAnimated_ = false
						var_58_11.isAnimated_ = false
					end
				})
			end

			arg_58_0.team_[iter_58_1].iniCell_.teamNo_ = iter_58_1
		end

		var_58_1:setVisible(true)
		var_58_2:setVisible(true)
	end

	arg_58_0:updateScore()
end

function var_0_0.checkIsDispatchFull(arg_64_0, arg_64_1)
	local var_64_0 = 0

	for iter_64_0, iter_64_1 in ipairs(arg_64_0.team_) do
		if not arg_64_0.occult:isDispatchedHero(iter_64_1.data:getHeroID()) then
			var_64_0 = var_64_0 + 1
		end
	end

	if not arg_64_0.occult:isDispatchedHero(arg_64_1:getHeroID()) then
		var_64_0 = var_64_0 + 1
	end

	if var_64_0 + #table.keys(arg_64_0.occult.dispatchInfo or {}) > arg_64_0.occult.baseInfo.dispatch_limit then
		return true
	end

	return false
end

function var_0_0.getHeroCell(arg_65_0, arg_65_1)
	for iter_65_0 = 1, #arg_65_0.heroCells_ do
		local var_65_0 = arg_65_0.heroCells_[iter_65_0]

		if not tolua.isnull(var_65_0) and var_65_0.hero:getTableID() == arg_65_1:getTableID() and not tolua.isnull(var_65_0) then
			return var_65_0
		end
	end

	return nil
end

function var_0_0.getTeamCell(arg_66_0, arg_66_1)
	for iter_66_0 = 1, #arg_66_0.teamCells_ do
		local var_66_0 = arg_66_0.teamCells_[iter_66_0]

		if var_66_0.hero:getTableID() == arg_66_1:getTableID() and not tolua.isnull(var_66_0) then
			return var_66_0, iter_66_0
		end
	end

	return nil
end

function var_0_0.getHeroCells(arg_67_0, arg_67_1)
	for iter_67_0 = 1, #arg_67_0.heroCells_ do
		if arg_67_0.heroCells_[iter_67_0].hero:getTableID() == arg_67_1:getTableID() and not tolua.isnull(arg_67_0.heroCells_[iter_67_0]) then
			return arg_67_0.heroCells_[iter_67_0]
		end
	end

	return nil
end

function var_0_0.moveFadeOutAction(arg_68_0, arg_68_1, arg_68_2, arg_68_3, arg_68_4)
	arg_68_0:widgetSet(arg_68_3)
	arg_68_3:setCascadeOpacityEnabled(true)

	local var_68_0 = cc.Spawn:create(cc.FadeOut:create(0.2), cc.MoveTo:create(0.3, cc.p(arg_68_1, arg_68_2)))

	arg_68_3:runActionOnce(var_68_0, true, arg_68_4)
end

function var_0_0.widgetSet(arg_69_0, arg_69_1)
	for iter_69_0, iter_69_1 in ipairs(arg_69_1:getChildren()) do
		if iter_69_1 ~= nil then
			iter_69_1:setCascadeOpacityEnabled(true)
			arg_69_0:widgetSet(iter_69_1)
		end
	end
end

function var_0_0.checkHeroValid(arg_70_0, arg_70_1)
	for iter_70_0, iter_70_1 in pairs(arg_70_0.teamCells_) do
		if arg_70_1:getTableID() == iter_70_1.hero:getTableID() or xyd.tables.hero:beforeAwaken(arg_70_1:getTableID()) == iter_70_1.hero:getTableID() or xyd.tables.hero:afterAwaken(arg_70_1:getTableID()) == iter_70_1.hero:getTableID() then
			return false
		end
	end

	return true
end

function var_0_0.canHeroJoinBattle(arg_71_0, arg_71_1)
	return true
end

function var_0_0.scrollListener(arg_72_0, arg_72_1)
	if arg_72_1.name == "began" then
		arg_72_0.scrollViewMoved_ = false
		arg_72_0.prevX_ = arg_72_1.x
	elseif arg_72_1.name == "moved" and 5 <= math.abs(arg_72_1.x - arg_72_0.prevX_) then
		arg_72_0.scrollViewMoved_ = true
	end
end

function var_0_0.getTeamNo(arg_73_0, arg_73_1)
	for iter_73_0, iter_73_1 in ipairs(arg_73_0.team_) do
		if arg_73_1.hero:getDistance() < iter_73_1.hero:getDistance() then
			table.insert(arg_73_0.team_, iter_73_0, arg_73_1)
			table.insert(arg_73_0.select_, iter_73_0, arg_73_1.hero)

			return iter_73_0
		end
	end

	table.insert(arg_73_0.team_, arg_73_1)
	table.insert(arg_73_0.select_, arg_73_1.hero)

	return #arg_73_0.team_
end

function var_0_0.initBottomCell(arg_74_0, arg_74_1)
	local var_74_0 = display.newNode()
	local var_74_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/hero_avatar_new.csb")
	local var_74_2 = var_74_1:getChildByName("background"):getContentSize()

	var_74_1:setContentSize(var_74_2)
	var_74_0:setContentSize(var_74_2)
	xyd.setAvatarBorderNewUI(arg_74_1, var_74_1:getChildByName("avatar"))

	local var_74_3 = var_74_1:getChildByName("chosen")

	var_74_3:setLocalZOrder(100)
	var_74_3:setVisible(false)

	local var_74_4 = var_74_1:getChildByName("avatar_mask")

	var_74_4:setLocalZOrder(2)
	var_74_4:setVisible(false)

	local var_74_5 = var_74_1:getChildByName("yongbing_tubiao")

	if arg_74_0.leftMenuType_ == var_0_13.RENT_HERO or arg_74_1.type == var_0_13.RENT_HERO or arg_74_1.partner_type == 1 or arg_74_1.partner_type == 5 then
		var_74_5:setVisible(true)

		var_74_0.type = var_0_13.RENT_HERO
	else
		var_74_5:setVisible(false)

		var_74_0.type = var_0_13.SELF_HERO
	end

	for iter_74_0 = 1, 3 do
		var_74_1:getChildByName("team" .. iter_74_0):setVisible(false)
	end

	local var_74_6 = var_74_1:getChildByName("lv_txt")

	var_74_6:setString(arg_74_1:getLevel())
	var_74_6:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	var_74_1:getChildByName("name_text"):setString(arg_74_1:getName())

	local var_74_7 = var_74_1:getChildByName("hp_bar")
	local var_74_8 = var_74_1:getChildByName("mp_bar")
	local var_74_9 = var_74_1:getChildByName("dead_text")

	if var_74_9 then
		var_74_9:setVisible(false)
	end

	local var_74_10 = false

	var_74_7:hide()
	var_74_8:hide()
	var_74_1:getChildByName("hp_di"):hide()
	var_74_1:getChildByName("mp_di"):hide()

	arg_74_1.isDead = false

	var_74_1:setName("layout")

	var_74_0.hero = arg_74_1

	var_74_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_74_0:addChild(var_74_1)

	return var_74_0
end

function var_0_0.clickBottomAvatar(arg_75_0, arg_75_1)
	if arg_75_1.isAnimated_ then
		return
	end

	local var_75_0, var_75_1 = arg_75_0:nodeByName("list_layer"):getPosition()
	local var_75_2 = arg_75_1.iniCell_
	local var_75_3

	for iter_75_0, iter_75_1 in ipairs(arg_75_0.select_) do
		if iter_75_1:getTableID() == arg_75_1.hero:getTableID() and iter_75_1.player_name == arg_75_1.hero.player_name then
			var_75_3 = iter_75_0

			break
		end
	end

	if not var_75_3 then
		return
	end

	if not arg_75_1.iniCellVisible_ and arg_75_1.type == arg_75_0.leftMenuType_ and not tolua.isnull(var_75_2) then
		local var_75_4 = var_75_2:convertToWorldSpace(cc.p(0, 0))

		var_75_0, var_75_1 = var_75_4.x + var_75_2:getContentSize().width / 2, var_75_4.y + var_75_2:getContentSize().height / 2

		local var_75_5

		if arg_75_1.type == var_0_13.RENT_HERO then
			var_75_5 = var_75_2:getChildByName("yongbingCell"):getChildByName("container")
		else
			var_75_5 = var_75_2:getChildByName("layout")
		end

		local var_75_6 = var_75_5:getChildByName("avatar_mask")
		local var_75_7 = var_75_5:getChildByName("chosen")

		var_75_6:setVisible(false)
		var_75_7:setVisible(false)
	end

	arg_75_0:moveFadeOutAction(var_75_0, var_75_1, arg_75_1)

	for iter_75_2 = #arg_75_0.team_, var_75_3 + 1, -1 do
		local var_75_8 = arg_75_0.team_[iter_75_2]
		local var_75_9, var_75_10 = arg_75_0:nodeByName("avatar" .. iter_75_2 - 1):getPosition()

		transition.stopTarget(var_75_8)
		transition.moveTo(arg_75_0.team_[iter_75_2], {
			time = 0.3,
			x = var_75_9,
			y = var_75_10
		})

		arg_75_0.team_[iter_75_2].iniCell_.teamNo_ = iter_75_2 - 1
	end

	if arg_75_1.type == var_0_13.RENT_HERO then
		arg_75_0.isSelectMerHero = false
		arg_75_0.selectMerHero = nil
	end

	table.remove(arg_75_0.team_, var_75_3)
	table.remove(arg_75_0.select_, var_75_3)

	var_75_2.teamNo_ = nil

	arg_75_0:updateScore()
end

function var_0_0.clickPetBottomAvatar(arg_76_0, arg_76_1, arg_76_2)
	if arg_76_1.isAnimated_ then
		return
	end

	local var_76_0, var_76_1 = arg_76_0:nodeByName("list_layer"):getPosition()
	local var_76_2 = arg_76_1.iniCell_
	local var_76_3

	for iter_76_0, iter_76_1 in ipairs(arg_76_0.petSelect_) do
		if iter_76_1:getTableID() == arg_76_1.hero:getTableID() and iter_76_1.player_name == arg_76_1.hero.player_name then
			var_76_3 = iter_76_0

			break
		end
	end

	if not var_76_3 then
		return
	end

	if var_76_2 and not tolua.isnull(var_76_2) then
		local var_76_4 = var_76_2:convertToWorldSpace(cc.p(0, 0))

		var_76_0, var_76_1 = var_76_4.x, var_76_4.y

		local var_76_5

		if arg_76_0.rentMenuType == var_0_14.RENT_PET then
			var_76_5 = var_76_2:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
		else
			var_76_5 = var_76_2:getChildByName("layout")
		end

		local var_76_6 = var_76_5:getChildByName("avatar_mask")
		local var_76_7 = var_76_5:getChildByName("chosen")

		var_76_6:setVisible(false)
		var_76_7:setVisible(false)
	end

	local var_76_8 = "avatar_pet"

	if arg_76_0.selectTeamType ~= xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		var_76_8 = "special_pet"
	end

	arg_76_0:moveFadeOutAction(var_76_0, var_76_1, arg_76_1, arg_76_2)

	for iter_76_2 = #arg_76_0.petTeam_, var_76_3 + 1, -1 do
		local var_76_9 = arg_76_0.petTeam_[iter_76_2]
		local var_76_10, var_76_11 = arg_76_0:nodeByName(var_76_8 .. iter_76_2 - 1):getPosition()

		transition.stopTarget(var_76_9)
		transition.moveTo(arg_76_0.petTeam_[iter_76_2], {
			time = 0.3,
			x = var_76_10,
			y = var_76_11
		})

		arg_76_0.petTeam_[iter_76_2].iniCell_.teamNo_ = iter_76_2 - 1
	end

	if arg_76_1.type == var_0_15.RENT_PET then
		arg_76_0.isSelectMerPet = false
		arg_76_0.selectMerPet = nil
	end

	table.remove(arg_76_0.petTeam_, var_76_3)
	table.remove(arg_76_0.petSelect_, var_76_3)

	if var_76_2 then
		var_76_2.teamNo_ = nil
	end

	arg_76_0:updateScore()
end

function var_0_0.initPetCell(arg_77_0, arg_77_1, arg_77_2)
	local var_77_0 = arg_77_0.totalPet_[arg_77_2]
	local var_77_1 = false

	arg_77_1:align(display.CENTER):size(146, 146)
	xyd.setPetAvatarNewUI(arg_77_1, var_77_0, 100)

	arg_77_1.type = var_0_15.SELF_PET
	arg_77_1.data = var_77_0

	arg_77_1:setTouchEnabled(true)
	arg_77_1:setTouchSwallowEnabled(false)
	arg_77_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_78_0)
		if not var_77_1 then
			arg_77_0:buttonHandler(nil, arg_77_1, arg_78_0)

			if arg_78_0.name == "began" then
				arg_77_0.startClick_ = true
				arg_77_0.prevX_ = arg_78_0.x
				arg_77_0.prevY_ = arg_78_0.y
			elseif arg_78_0.name == "moved" then
				if math.abs(arg_78_0.y - arg_77_0.prevY_) > 5 or math.abs(arg_78_0.x - arg_77_0.prevX_) > 5 then
					arg_77_0.startClick_ = false
				end
			elseif arg_78_0.name == "ended" and arg_77_0.startClick_ then
				arg_77_0:clickPetAvatar(arg_77_1)
			end
		end

		return true
	end)

	for iter_77_0, iter_77_1 in ipairs(arg_77_0.petTeam_) do
		if var_77_0 == iter_77_1.data then
			arg_77_0.petTeam_[iter_77_0].iniCell_ = arg_77_1
			arg_77_1.teamNo_ = iter_77_0

			local var_77_2

			if arg_77_0.rentMenuType == var_0_14.RENT_PET then
				var_77_2 = arg_77_1:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
			else
				var_77_2 = arg_77_1:getChildByName("layout")
			end

			local var_77_3 = var_77_2:getChildByName("avatar_mask")
			local var_77_4 = var_77_2:getChildByName("chosen")

			var_77_3:setVisible(true)
			var_77_4:setVisible(true)

			break
		end
	end
end

function var_0_0.clickPetAvatar(arg_79_0, arg_79_1, arg_79_2)
	if arg_79_1.isAnimated_ or not arg_79_1.teamNo_ and #arg_79_0.petTeam_ > xyd.MAX_PET_NUMBER then
		return
	elseif not arg_79_1.teamNo_ and #arg_79_0.petTeam_ == xyd.MAX_PET_NUMBER then
		local var_79_0 = arg_79_0.petTeam_[1]

		arg_79_0:clickPetBottomAvatarWithoutAnimation(var_79_0, function()
			arg_79_0:clickPetAvatar(arg_79_1, arg_79_2)
		end)

		return
	end

	local var_79_1 = arg_79_1:getChildByName("layout")
	local var_79_2 = var_79_1:getChildByName("avatar_mask")
	local var_79_3 = var_79_1:getChildByName("chosen")
	local var_79_4 = arg_79_1:convertToWorldSpace(cc.p(0, 0))
	local var_79_5 = var_79_4.x
	local var_79_6 = var_79_4.y

	arg_79_1.isAnimated_ = true

	if arg_79_1.teamNo_ then
		local var_79_7 = arg_79_0.petTeam_[arg_79_1.teamNo_]

		arg_79_0:moveFadeOutAction(var_79_5, var_79_6, var_79_7, function()
			arg_79_1.isAnimated_ = false
		end)
		var_79_2:setVisible(false)
		var_79_3:setVisible(false)

		for iter_79_0 = #arg_79_0.petTeam_, arg_79_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_79_0.petTeam_[iter_79_0])

			local var_79_8, var_79_9 = arg_79_0:nodeByName("avatar_pet" .. iter_79_0 - 1):getPosition()

			transition.moveTo(arg_79_0.petTeam_[iter_79_0], {
				time = 0.3,
				x = var_79_8,
				y = var_79_9
			})

			arg_79_0.petTeam_[iter_79_0].iniCell_.teamNo_ = iter_79_0 - 1
		end

		if arg_79_1.type == var_0_15.RENT_PET then
			arg_79_0.isSelectMerPet = false
			arg_79_0.selectMerPet = nil
		end

		table.remove(arg_79_0.petTeam_, arg_79_1.teamNo_)
		table.remove(arg_79_0.petSelect_, arg_79_1.teamNo_)

		arg_79_1.teamNo_ = nil
	elseif not arg_79_1.teamNo_ and #arg_79_0.petTeam_ < xyd.MAX_PET_NUMBER then
		local var_79_10 = arg_79_1.data

		if not arg_79_2 and var_0_12:chosenSound(var_79_10:getTableID()) ~= "" then
			xyd.AssetDownload.get():preloadCharacterSound({
				var_79_10:getTableID()
			}, function()
				return
			end, true)
			audio.playSound(var_0_12:chosenSound(var_79_10:getTableID()), false)
		end

		if arg_79_0.rentMenuType == var_0_14.RENT_PET and var_79_10.can_rent == false then
			arg_79_1.isAnimated_ = false

			return
		end

		local var_79_11 = arg_79_0:initPetBottomCell(var_79_10)

		var_79_11.iniCell_ = arg_79_1
		var_79_11.data = var_79_10

		var_79_11:pos(var_79_5, var_79_6)
		var_79_11:addTo(arg_79_0)
		var_79_11:setTouchEnabled(true)
		var_79_11:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_83_0)
			if arg_83_0.name == "ended" then
				arg_79_0:clickPetBottomAvatar(var_79_11)
			end

			return true
		end)

		if arg_79_1.type == var_0_15.RENT_PET then
			arg_79_0.isSelectMerPet = true
			arg_79_0.selectMerPet = var_79_10
		end

		arg_79_1.teamNo_ = arg_79_0:getPetTeamNo(var_79_11)

		for iter_79_1 = arg_79_1.teamNo_, #arg_79_0.petTeam_ do
			local var_79_12, var_79_13 = arg_79_0:nodeByName("avatar_pet" .. iter_79_1):getPosition()

			if arg_79_2 then
				arg_79_0.petTeam_[iter_79_1]:pos(var_79_12, var_79_13)

				arg_79_1.isAnimated_ = false
			elseif iter_79_1 ~= arg_79_1.teamNo_ then
				local var_79_14 = arg_79_0.petTeam_[iter_79_1]

				transition.stopTarget(var_79_14)
				transition.moveTo(var_79_14, {
					time = 0.3,
					x = var_79_12,
					y = var_79_13,
					onComplete = function()
						var_79_14.iniCell_.isAnimated_ = false
						var_79_14.isAnimated_ = false
					end
				})
			else
				local var_79_15 = arg_79_0.petTeam_[iter_79_1]

				transition.stopTarget(var_79_15)

				var_79_11.isAnimated_ = true

				transition.moveTo(var_79_15, {
					time = 0.3,
					x = var_79_12,
					y = var_79_13,
					onComplete = function()
						arg_79_1.isAnimated_ = false
						var_79_11.isAnimated_ = false
					end
				})
			end

			arg_79_0.petTeam_[iter_79_1].iniCell_.teamNo_ = iter_79_1
		end

		var_79_2:setVisible(true)
		var_79_3:setVisible(true)
	end

	arg_79_0:updateScore()
end

function var_0_0.initPetBottomCell(arg_86_0, arg_86_1)
	local var_86_0 = display.newNode()

	var_86_0:size(146, 146)
	var_86_0:align(display.CENTER)

	var_86_0.hero = arg_86_1
	var_86_0.type = var_0_15.SELF_PET

	xyd.setPetAvatarNewUI(var_86_0, arg_86_1, 100)

	if arg_86_0.rentMenuType == var_0_14.RENT_PET or arg_86_1.partner_type == 3 then
		local var_86_1 = xyd.AssetLoader.get():loadSprite("windows/zhugeliang/yongbing_tubiao.png")

		var_86_1:addTo(var_86_0)
		var_86_1:setAnchorPoint(cc.p(0.5, 0.5))
		var_86_1:setPosition(cc.p(110, 120))

		var_86_0.type = var_0_15.RENT_PET
	end

	return var_86_0
end

function var_0_0.getPetTeamNo(arg_87_0, arg_87_1)
	table.insert(arg_87_0.petTeam_, arg_87_1)
	table.insert(arg_87_0.petSelect_, arg_87_1.hero)

	return #arg_87_0.petTeam_
end

function var_0_0.clickPetBottomAvatarWithoutAnimation(arg_88_0, arg_88_1, arg_88_2)
	if arg_88_1.isAnimated_ then
		return
	end

	local var_88_0, var_88_1 = arg_88_0:nodeByName("list_layer"):getPosition()
	local var_88_2 = arg_88_1.iniCell_
	local var_88_3

	for iter_88_0, iter_88_1 in ipairs(arg_88_0.petTeam_) do
		if iter_88_1 == arg_88_1 then
			var_88_3 = iter_88_0

			break
		end
	end

	if not var_88_3 then
		return
	end

	if var_88_2 and not tolua.isnull(var_88_2) then
		local var_88_4 = var_88_2:convertToWorldSpace(cc.p(0, 0))
		local var_88_5

		if arg_88_0.rentMenuType == var_0_14.RENT_PET then
			var_88_5 = var_88_2:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
		else
			var_88_5 = var_88_2:getChildByName("layout")
		end

		local var_88_6 = var_88_5:getChildByName("avatar_mask")
		local var_88_7 = var_88_5:getChildByName("chosen")

		var_88_6:setVisible(false)
		var_88_7:setVisible(false)
	end

	local var_88_8 = "avatar_pet"

	if arg_88_0.selectTeamType ~= xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		var_88_8 = "special_pet"
	end

	for iter_88_2 = #arg_88_0.petTeam_, var_88_3 + 1, -1 do
		local var_88_9 = arg_88_0.petTeam_[iter_88_2]
		local var_88_10, var_88_11 = arg_88_0:nodeByName(var_88_8 .. iter_88_2 - 1):getPosition()

		transition.stopTarget(var_88_9)
		transition.moveTo(arg_88_0.petTeam_[iter_88_2], {
			time = 0.3,
			x = var_88_10,
			y = var_88_11
		})

		arg_88_0.petTeam_[iter_88_2].iniCell_.teamNo_ = iter_88_2 - 1
	end

	if arg_88_1.type == var_0_15.RENT_PET then
		arg_88_0.isSelectMerPet = false
		arg_88_0.selectMerPet = nil
	end

	table.remove(arg_88_0.petTeam_, var_88_3)
	table.remove(arg_88_0.petSelect_, var_88_3)

	if var_88_2 then
		var_88_2.teamNo_ = nil
	end

	if arg_88_1 and not tolua.isnull(arg_88_1) then
		arg_88_1:removeSelf()
	end

	if arg_88_2 then
		arg_88_2()
	end
end

function var_0_0.updateScore(arg_89_0)
	local var_89_0 = 0

	for iter_89_0, iter_89_1 in ipairs(arg_89_0.team_) do
		var_89_0 = var_89_0 + iter_89_1.data:getZhandouli()
	end

	for iter_89_2, iter_89_3 in ipairs(arg_89_0.petTeam_) do
		var_89_0 = var_89_0 + iter_89_3.data:getZhandouli()
	end

	arg_89_0:nodeByName("zhandouli"):setString(var_89_0)
end

function var_0_0.updateFilterHeros(arg_90_0)
	arg_90_0.totalHero_[xyd.DistanceType.FILTER] = {}
	arg_90_0.totalHero_[xyd.DistanceType.FILTER][var_0_16.NO] = {}
	arg_90_0.totalHero_[xyd.DistanceType.FILTER][var_0_16.YES] = {}

	local var_90_0 = {
		0,
		0,
		0
	}
	local var_90_1 = {
		0,
		0,
		0
	}
	local var_90_2 = {
		0,
		0,
		0,
		0
	}
	local var_90_3 = {
		0,
		0,
		0
	}

	if arg_90_0.selfPlayer.sortType and arg_90_0.selfPlayer.sortType > 0 then
		local var_90_4 = {}
		local var_90_5 = arg_90_0.selfPlayer.sortType
		local var_90_6 = 1

		while var_90_5 > 0 do
			var_90_4[var_90_6] = var_90_5 % 2
			var_90_6 = var_90_6 + 1
			var_90_5 = math.floor(var_90_5 / 2)
		end

		local var_90_7 = 1

		for iter_90_0 = 13, 1, -1 do
			if iter_90_0 <= 4 then
				if iter_90_0 == 4 then
					var_90_7 = 1
				end

				var_90_2[var_90_7] = var_90_4[iter_90_0]
			elseif iter_90_0 <= 7 then
				if iter_90_0 == 7 then
					var_90_7 = 1
				end

				var_90_1[var_90_7] = var_90_4[iter_90_0]
			elseif iter_90_0 <= 10 then
				if iter_90_0 == 10 then
					var_90_7 = 1
				end

				if var_90_4[iter_90_0] then
					var_90_0[var_90_7] = var_90_4[iter_90_0]
				end
			elseif iter_90_0 <= 13 then
				if iter_90_0 == 13 then
					var_90_7 = 1
				end

				if var_90_4[iter_90_0] then
					var_90_3[var_90_7] = var_90_4[iter_90_0]
				end
			end

			var_90_7 = var_90_7 + 1
		end
	else
		var_90_0 = {
			1,
			1,
			1
		}
		var_90_1 = {
			1,
			1,
			1
		}
		var_90_2 = {
			1,
			1,
			1,
			1
		}
		var_90_3 = {
			1,
			1,
			1
		}
	end

	for iter_90_1, iter_90_2 in pairs(arg_90_0.totalHero_[xyd.DistanceType.ALL][var_0_16.NO]) do
		if var_90_0[iter_90_2:getDistanceType() - 1] == 1 and var_90_1[iter_90_2:getHeroType()] == 1 and var_90_2[iter_90_2:getFromType()] == 1 and arg_90_0:canHeroJoinBattle(iter_90_2) and var_90_3[iter_90_2:getAwakenType()] == 1 then
			table.insert(arg_90_0.totalHero_[xyd.DistanceType.FILTER][var_0_16.NO], iter_90_2)
		end
	end

	for iter_90_3, iter_90_4 in pairs(arg_90_0.totalHero_[xyd.DistanceType.ALL][var_0_16.YES]) do
		if var_90_0[iter_90_4:getDistanceType() - 1] == 1 and var_90_1[iter_90_4:getHeroType()] == 1 and var_90_2[iter_90_4:getFromType()] == 1 and arg_90_0:canHeroJoinBattle(iter_90_4) and var_90_3[iter_90_4:getAwakenType()] == 1 then
			table.insert(arg_90_0.totalHero_[xyd.DistanceType.FILTER][var_0_16.YES], iter_90_4)
		end
	end
end

return var_0_0
