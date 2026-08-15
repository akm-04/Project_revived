local var_0_0 = class("ZhugeSelectTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = import("framework.scheduler")
local var_0_4 = xyd.tables.translation
local var_0_5 = 30
local var_0_6 = 16
local var_0_7 = 5
local var_0_8 = 50
local var_0_9 = 4
local var_0_10 = 7
local var_0_11 = xyd.tables.misc
local var_0_12 = {
	RENT_HERO = 2,
	SELF_HERO = 1,
	SELF_PET = 3
}
local var_0_13 = {
	RENT_HERO = 1,
	RENT_PET = 2
}
local var_0_14 = {
	RENT_PET = 2,
	SELF_PET = 1
}
local var_0_15 = class("ScrollView", cc.ui.UIListView)

function var_0_15.ctor(arg_1_0, arg_1_1)
	var_0_15.super.ctor(arg_1_0, arg_1_1)
end

function var_0_15.removeItem(arg_2_0, arg_2_1, arg_2_2)
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

	arg_3_0.missionId = arg_3_2.missionId
	arg_3_0.heroId = arg_3_2.heroId
	arg_3_0.selectTeamType = arg_3_2.teamType
	arg_3_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_3_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_3_0.specialParams = arg_3_2.specialParams
	arg_3_0.isNoCanReturn_ = false
	arg_3_0.isBattle_ = false
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	arg_4_0:clear()
	arg_4_0:init()
	arg_4_0:refreshSelectedHeroClass()
end

function var_0_0.clear(arg_5_0)
	arg_5_0.totalHero_ = {}
	arg_5_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_5_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_5_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_5_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
	arg_5_0.teamCells_ = {}
	arg_5_0.heroCells_ = {}
	arg_5_0.bottomItems_ = {}
	arg_5_0.isAnimated_ = false
	arg_5_0.tmpTotalHero_ = {}
	arg_5_0.selectedHeroClass_ = {}
	arg_5_0.tmpTotalPets = {}
	arg_5_0.leftMenuType_ = var_0_12.SELF_HERO
	arg_5_0.rentMenuType = var_0_13.RENT_HERO
	arg_5_0.petTeam_ = {}
	arg_5_0.team_ = {}
	arg_5_0.select_ = {}
	arg_5_0.petTeam_ = {}
	arg_5_0.petSelect_ = {}
	arg_5_0.totalPet_ = {}
end

function var_0_0.init(arg_6_0)
	if arg_6_0.selectTeamType == xyd.ZhugeSelectTeamType.FIRST_SELECT then
		arg_6_0:initHeros(arg_6_0:getHeros(), var_0_12.SELF_HERO)
		arg_6_0:initHeros(arg_6_0:getRentHeros(), var_0_12.RENT_HERO)
		arg_6_0:initPets(arg_6_0:getPets() or {}, var_0_14.SELF_PET)
	elseif arg_6_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_EXTRA then
		arg_6_0:initHeros(arg_6_0:getHeros(), var_0_12.SELF_HERO)
		arg_6_0:initHeros(arg_6_0:getRentHeros(), var_0_12.RENT_HERO)
	elseif arg_6_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		arg_6_0:initHeros(arg_6_0:getHeros(), var_0_12.SELF_HERO)
		arg_6_0:initPets(arg_6_0:getPets() or {}, var_0_14.SELF_PET)
	end

	arg_6_0:initMaxTeamNum()
	arg_6_0:layout()
	arg_6_0:selectHeros()
	arg_6_0:selectPets()
end

function var_0_0.getHeros(arg_7_0)
	local var_7_0 = {}
	local var_7_1 = {}

	if arg_7_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		local var_7_2 = arg_7_0.zhugeModel:getMemberInfos()

		for iter_7_0, iter_7_1 in ipairs(var_7_2) do
			if iter_7_1.partner_type ~= 2 and iter_7_1.partner_type ~= 3 then
				local var_7_3 = var_0_1.new()
				local var_7_4 = arg_7_0.selfPlayer:getHeroIgnoreAwaken(iter_7_1.table_id)

				if var_7_4 then
					var_7_3:populate(var_7_4:toParams())

					var_7_3.type = var_0_12.SELF_HERO
				else
					var_7_3:initUnCollected(iter_7_1.table_id)

					var_7_3.type = var_0_12.RENT_HERO

					var_7_3:setStar(5)
				end

				var_7_3.partner_type = iter_7_1.partner_type

				table.insert(var_7_0, var_7_3)
			end
		end
	else
		local var_7_5 = arg_7_0.selfPlayer.heros_

		for iter_7_2, iter_7_3 in ipairs(var_7_5) do
			if arg_7_0:checkHeroCanJoin(iter_7_3) then
				local var_7_6 = var_0_1.new()

				var_7_6:populate(iter_7_3:toParams())
				table.insert(var_7_0, var_7_6)
			end
		end
	end

	arg_7_0.zhugeModel:formatNewHeros(var_7_0)

	if arg_7_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		arg_7_0.zhugeModel:setMemberHeros(var_7_0)
	end

	return var_7_0
end

function var_0_0.checkHeroCanJoin(arg_8_0, arg_8_1)
	if arg_8_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_EXTRA then
		local var_8_0 = arg_8_0.zhugeModel:getMemberInfos()

		for iter_8_0, iter_8_1 in pairs(var_8_0) do
			if iter_8_1.table_id == arg_8_1:getTableID() then
				return false
			end
		end
	end

	if arg_8_1:getTableID() == 10001144 or xyd.tables.hero:beforeAwaken(arg_8_1:getTableID()) == 10001144 then
		return false
	end

	local var_8_1 = xyd.tables.zhugeHero:ids(xyd.ZhugeRentHeroType.HERO)

	for iter_8_2 = 1, #var_8_1 do
		if var_8_1[iter_8_2] == arg_8_1:getTableID() or arg_8_1:beforeAwakenID() == var_8_1[iter_8_2] then
			return true
		end
	end

	return false
end

function var_0_0.getRentHeros(arg_9_0)
	local var_9_0 = xyd.tables.zhugeHero:ids(xyd.ZhugeRentHeroType.HERO)
	local var_9_1 = {}

	for iter_9_0 = 1, #var_9_0 do
		local var_9_2 = var_9_0[iter_9_0]

		if arg_9_0:checkHeroCanRent(var_9_2) then
			local var_9_3 = var_0_1.new()

			var_9_3:initUnCollected(var_9_2)
			var_9_3:setStar(5)
			table.insert(var_9_1, var_9_3)

			var_9_3.partner_type = 1
		end
	end

	arg_9_0.zhugeModel:formatNewHeros(var_9_1)

	return var_9_1
end

function var_0_0.checkHeroCanRent(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_0.selfPlayer.vip

	if arg_10_0.selfPlayer:getHeroIgnoreAwaken(arg_10_1) then
		return false
	end

	if var_10_0 < 9 and xyd.tables.hero:isSX(arg_10_1) then
		return false
	end

	local var_10_1 = arg_10_0.zhugeModel:getHeroStatus(arg_10_1)

	if var_10_1 and next(var_10_1) then
		return false
	end

	return true
end

function var_0_0.getPets(arg_11_0)
	local var_11_0 = {}

	if arg_11_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		local var_11_1 = arg_11_0.zhugeModel:getMemberInfos()

		for iter_11_0, iter_11_1 in ipairs(var_11_1) do
			if iter_11_1.partner_type == 2 or iter_11_1.partner_type == 3 then
				local var_11_2 = var_0_2.new()
				local var_11_3 = arg_11_0.selfPlayer:getPetIgnoreAwaken(iter_11_1.table_id)

				if var_11_3 then
					var_11_2:populate(var_11_3:toParams())

					var_11_2.type = var_0_14.SELF_PET
				else
					var_11_2:initUnCollected(iter_11_1.table_id)

					var_11_2.type = var_0_14.RENT_PET
					var_11_2.star_ = 5
					var_11_2.is_show_ = 1
				end

				var_11_2.partner_type = iter_11_1.partner_type

				table.insert(var_11_0, var_11_2)
			end
		end
	else
		for iter_11_2, iter_11_3 in ipairs(arg_11_0.selfPlayer.collectedPets) do
			local var_11_4 = var_0_2.new()

			var_11_4:populate(iter_11_3:toParams())
			table.insert(var_11_0, var_11_4)
		end
	end

	arg_11_0.zhugeModel:formatNewPets(var_11_0)

	return var_11_0
end

function var_0_0.getRentPets(arg_12_0)
	local var_12_0 = xyd.tables.zhugeHero:ids(xyd.ZhugeRentHeroType.PET)
	local var_12_1 = {}

	for iter_12_0 = 1, #var_12_0 do
		local var_12_2 = var_12_0[iter_12_0]

		if not arg_12_0.selfPlayer:getPetIgnoreAwaken(var_12_2) then
			local var_12_3 = var_0_2.new()

			var_12_3:initUnCollected(var_12_2)

			var_12_3.star_ = 5
			var_12_3.is_show_ = 1
			var_12_3.type = var_0_14.RENT_PET

			table.insert(var_12_1, var_12_3)
		end
	end

	arg_12_0.zhugeModel:formatNewPets(var_12_1)

	return var_12_1
end

function var_0_0.initHeros(arg_13_0, arg_13_1, arg_13_2)
	arg_13_0.tmpTotalHero_[arg_13_2] = {}
	arg_13_0.tmpTotalHero_[arg_13_2][xyd.DistanceType.ALL] = {}
	arg_13_0.tmpTotalHero_[arg_13_2][xyd.DistanceType.QIANPAI] = {}
	arg_13_0.tmpTotalHero_[arg_13_2][xyd.DistanceType.ZHONGPAI] = {}
	arg_13_0.tmpTotalHero_[arg_13_2][xyd.DistanceType.HOUPAI] = {}

	local var_13_0 = os.clock()

	for iter_13_0, iter_13_1 in pairs(arg_13_1) do
		iter_13_1.type = arg_13_2

		if arg_13_0:canHeroJoinBattle(iter_13_1) then
			if iter_13_1:getDistanceType() == xyd.DistanceType.QIANPAI then
				table.insert(arg_13_0.tmpTotalHero_[arg_13_2][xyd.DistanceType.QIANPAI], iter_13_1)
			elseif iter_13_1:getDistanceType() == xyd.DistanceType.ZHONGPAI then
				table.insert(arg_13_0.tmpTotalHero_[arg_13_2][xyd.DistanceType.ZHONGPAI], iter_13_1)
			elseif iter_13_1:getDistanceType() == xyd.DistanceType.HOUPAI then
				table.insert(arg_13_0.tmpTotalHero_[arg_13_2][xyd.DistanceType.HOUPAI], iter_13_1)
			end

			table.insert(arg_13_0.tmpTotalHero_[arg_13_2][xyd.DistanceType.ALL], iter_13_1)
		end
	end

	arg_13_0:sortTables(arg_13_0.tmpTotalHero_[arg_13_2])

	arg_13_0.selectedHeroClass_[arg_13_2] = xyd.DistanceType.ALL
end

function var_0_0.initMaxTeamNum(arg_14_0)
	if arg_14_0.selectTeamType == xyd.ZhugeSelectTeamType.FIRST_SELECT then
		arg_14_0.maxPartnerNum = var_0_11.zhugeForestPartnerNum
		arg_14_0.maxPetNum = var_0_11.zhugeForestPetNum
	elseif arg_14_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		arg_14_0.maxPartnerNum = xyd.MAX_TEAM_MEMBER_NUM
		arg_14_0.maxPetNum = xyd.MAX_PET_NUMBER
	elseif arg_14_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_EXTRA then
		arg_14_0.maxPartnerNum = arg_14_0.zhugeModel:getExtraPatnerNum()
		arg_14_0.maxPetNum = 0
	end
end

function var_0_0.initPets(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = {}

	for iter_15_0, iter_15_1 in ipairs(arg_15_1) do
		if iter_15_1.is_show_ == 1 then
			table.insert(var_15_0, iter_15_1)
		end
	end

	table.sort(var_15_0, function(arg_16_0, arg_16_1)
		return xyd.petNormalSort(arg_16_0, arg_16_1) or false
	end)

	arg_15_0.tmpTotalPets[arg_15_2] = var_15_0
end

function var_0_0.sortTables(arg_17_0, arg_17_1)
	for iter_17_0 = 1, #arg_17_1 do
		table.sort(arg_17_1[iter_17_0], function(arg_18_0, arg_18_1)
			if arg_18_0:getTableID() == arg_17_0.heroId then
				return true
			elseif arg_18_1:getTableID() == arg_17_0.heroId then
				return false
			end

			return xyd.heroNormalSort(arg_18_0, arg_18_1) or false
		end)
	end
end

function var_0_0.layout(arg_19_0)
	arg_19_0:initListView()
	arg_19_0:bottomListLayout()
	arg_19_0:setButtonClick()
	arg_19_0:updateSelectProgressShow()
	arg_19_0:updateBottomLayout()
	arg_19_0:updateTopRentMenu()
	arg_19_0:updateTopText()
	arg_19_0:updateScore()
end

function var_0_0.initListView(arg_20_0)
	local var_20_0 = arg_20_0:nodeByName("list_layer")
	local var_20_1 = var_20_0:getContentSize()

	if not arg_20_0.heroList_ then
		arg_20_0.heroList_ = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_20_1.width, var_20_1.height),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(var_20_0)
		arg_20_0.heroCells_ = {}

		arg_20_0.heroList_:setDelegate(handler(arg_20_0, arg_20_0.delegate))
	end

	local var_20_2 = arg_20_0:nodeByName("select_hero_list")
	local var_20_3 = var_20_2:getContentSize()

	if arg_20_0.bottomList_ then
		var_20_2:removeAllChildren()

		arg_20_0.bottomList_ = nil
	end

	local var_20_4 = arg_20_0:getBottomWidth(var_20_3.width)

	arg_20_0.bottomList_ = var_0_15.new({
		async = false,
		viewRect = cc.rect(0, 0, var_20_4, var_20_3.height),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_20_2):onScroll(handler(arg_20_0, arg_20_0.scrollListener))

	arg_20_0.bottomList_:setBounceable(true)
end

function var_0_0.getBottomWidth(arg_21_0, arg_21_1)
	local var_21_0 = arg_21_1

	if arg_21_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_EXTRA then
		local var_21_1 = arg_21_0.zhugeModel:getExtraPatnerNum()

		if var_21_1 < var_0_10 then
			var_21_0 = var_21_1 * 152
			var_0_10 = var_21_1
		end
	end

	return var_21_0
end

function var_0_0.bottomListLayout(arg_22_0)
	for iter_22_0 = 1, arg_22_0.maxPartnerNum do
		arg_22_0:addNewBottomItem()
	end

	arg_22_0.bottomList_:reload()
end

function var_0_0.updateBottomLayout(arg_23_0)
	if arg_23_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		arg_23_0:nodeByName("bottom_bg_2"):setVisible(false)
		arg_23_0:nodeByName("bottom_bg_1"):setVisible(true)
		arg_23_0:nodeByName("bottom_bg_3"):setVisible(false)
	elseif arg_23_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_EXTRA then
		arg_23_0:nodeByName("bottom_bg_1"):setVisible(false)
		arg_23_0:nodeByName("bottom_bg_2"):setVisible(true)
		arg_23_0:nodeByName("bottom_bg_3"):setVisible(false)
	else
		arg_23_0:nodeByName("bottom_bg_1"):setVisible(false)

		if arg_23_0.leftMenuType_ == var_0_12.SELF_PET or arg_23_0.rentMenuType == var_0_13.RENT_PET then
			arg_23_0:nodeByName("bottom_bg_3"):setVisible(true)
			arg_23_0:nodeByName("bottom_bg_2"):setVisible(false)
		else
			arg_23_0:nodeByName("bottom_bg_3"):setVisible(false)
			arg_23_0:nodeByName("bottom_bg_2"):setVisible(true)
		end
	end
end

function var_0_0.updateSelectProgressShow(arg_24_0)
	return
end

function var_0_0.updateTopText(arg_25_0)
	local var_25_0 = ""

	if arg_25_0.selectTeamType == xyd.ZhugeSelectTeamType.FIRST_SELECT then
		var_25_0 = var_0_4:translation("ZHUGE_FOREST_TIPS_6")
	elseif arg_25_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_EXTRA then
		var_25_0 = var_0_4:translation("ZHUGE_FOREST_TIPS_7")
	else
		var_25_0 = var_0_4:translation("ZHUGE_FOREST_TIPS_8")
	end

	arg_25_0:nodeByName("lev_limit_txt"):setString(var_25_0)
	arg_25_0:updateSelectNum()
end

function var_0_0.updateSelectNum(arg_26_0)
	if arg_26_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		arg_26_0:nodeByName("img_count"):setVisible(false)
	else
		arg_26_0:nodeByName("img_count"):setVisible(true)

		local var_26_0 = ""

		if arg_26_0.leftMenuType_ == var_0_12.SELF_PET or arg_26_0.rentMenuType == var_0_13.RENT_PET then
			var_26_0 = #arg_26_0.petSelect_ .. "/" .. arg_26_0.maxPetNum
		else
			var_26_0 = #arg_26_0.teamCells_ .. "/" .. arg_26_0.maxPartnerNum
		end

		arg_26_0:nodeByName("text_count"):setString(var_26_0)
	end
end

function var_0_0.setOrgPositonX(arg_27_0)
	arg_27_0.orgPositonX = arg_27_0.bottomList_:getScrollNode():getPositionX()
end

function var_0_0.scrollToOrgPositonX(arg_28_0, arg_28_1)
	if arg_28_0.orgPositonX and arg_28_0.orgPositonX <= 0 then
		if arg_28_1 and arg_28_0.orgPositonX + 152 <= 0 then
			arg_28_0.bottomList_:getScrollNode():setPositionX(arg_28_0.orgPositonX + 152)
		else
			arg_28_0.bottomList_:getScrollNode():setPositionX(arg_28_0.orgPositonX)
		end
	end

	arg_28_0.orgPositonX = nil
end

function var_0_0.scrollToIthItem(arg_29_0, arg_29_1)
	if arg_29_1 < 1 then
		arg_29_1 = 1
	elseif arg_29_1 >= arg_29_0.maxPartnerNum - (var_0_10 - 1) then
		arg_29_1 = arg_29_0.maxPartnerNum - (var_0_10 - 1)
	end

	arg_29_0.bottomList_:scrollTo(-(arg_29_1 - 1) * 152, 0)
end

function var_0_0.addNewBottomItem(arg_30_0)
	local var_30_0 = arg_30_0.bottomList_:dequeueItem()

	if not var_30_0 then
		var_30_0 = arg_30_0.bottomList_:newItem()
	else
		var_30_0:removeAllChildren(true)
	end

	local var_30_1 = arg_30_0:createBottomListContent()
	local var_30_2 = var_30_1:getWidth()
	local var_30_3 = var_30_1:getHeight()

	var_30_0:setItemSize(var_30_2, var_30_3)
	var_30_0:addContent(var_30_1)
	var_30_1:setName("content")
	table.insert(arg_30_0.bottomItems_, var_30_0)
	arg_30_0.bottomList_:addItem(var_30_0)
end

function var_0_0.createBottomListContent(arg_31_0)
	local var_31_0 = display.newNode()
	local var_31_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/awake_twice/select_team/bottom_item.csb")
	local var_31_2 = var_31_1:getChildByName("container")

	var_31_0:setAnchorPoint(cc.p(0, 0))
	var_31_0:setPosition(0, 0)
	var_31_1:addTo(var_31_0)
	var_31_1:setAnchorPoint(cc.p(0, 0))
	var_31_0:setContentSize(var_31_2:getContentSize())
	var_31_1:setName("source")

	return var_31_0
end

function var_0_0.delegate(arg_32_0, ...)
	if arg_32_0.leftMenuType_ == var_0_12.SELF_PET or arg_32_0.leftMenuType_ == var_0_12.RENT_HERO and arg_32_0.rentMenuType == var_0_13.RENT_PET then
		return arg_32_0:petDelegate(...)
	end

	return arg_32_0:heroDelegate(...)
end

function var_0_0.heroDelegate(arg_33_0, arg_33_1, arg_33_2, arg_33_3)
	if arg_33_0.leftMenuType_ == var_0_12.SELF_HERO then
		var_0_7 = 5
	else
		var_0_7 = 4
	end

	local var_33_0 = math.ceil(#arg_33_0.totalHero_[arg_33_0.selectedHeroClass_[arg_33_0.leftMenuType_]] / var_0_7)

	if cc.ui.UIListView.COUNT_TAG == arg_33_2 then
		return var_33_0
	elseif cc.ui.UIListView.CELL_TAG == arg_33_2 then
		local var_33_1
		local var_33_2 = arg_33_0.heroList_:dequeueItem()

		if not var_33_2 then
			var_33_2 = arg_33_0.heroList_:newItem()
		else
			var_33_2:removeAllChildren(true)
		end

		local var_33_3 = display.newNode()

		var_33_3:setTouchSwallowEnabled(false)

		for iter_33_0 = 1, var_0_7 do
			local var_33_4 = (arg_33_3 - 1) * var_0_7 + iter_33_0

			if var_33_4 > #arg_33_0.totalHero_[arg_33_0.selectedHeroClass_[arg_33_0.leftMenuType_]] then
				break
			end

			var_33_1 = arg_33_0:initHeroCell(var_33_4)

			local var_33_5 = var_33_1:getContentSize().width
			local var_33_6 = var_33_1:getContentSize().height
			local var_33_7 = (arg_33_0.heroList_.viewRect_.width - var_33_5 * var_0_7) / (var_0_7 + 1)

			var_33_1:pos(var_33_7 * iter_33_0 + (iter_33_0 - 1) * var_33_5 + var_33_5 / 2, var_0_5 + var_33_6 / 2 - 2)
			var_33_3:addChild(var_33_1)

			arg_33_0.heroCells_[var_33_4] = var_33_1
		end

		var_33_3:setContentSize(cc.size(arg_33_0.heroList_.viewRect_.width, var_33_1:getContentSize().height + var_0_5))
		var_33_2:setItemSize(arg_33_0.heroList_.viewRect_.width, var_33_1:getContentSize().height + var_0_5)
		var_33_2:addContent(var_33_3)

		return var_33_2
	end
end

function var_0_0.petDelegate(arg_34_0, arg_34_1, arg_34_2, arg_34_3)
	if arg_34_0.leftMenuType_ == var_0_12.SELF_PET then
		var_0_9 = 5
	else
		var_0_9 = 4
	end

	local var_34_0 = math.ceil(#arg_34_0.totalPet_ / var_0_9)

	if cc.ui.UIListView.COUNT_TAG == arg_34_2 then
		return var_34_0
	elseif cc.ui.UIListView.CELL_TAG == arg_34_2 then
		local var_34_1
		local var_34_2
		local var_34_3
		local var_34_4 = arg_34_0.heroList_:dequeueItem()

		if not var_34_4 then
			var_34_4 = arg_34_0.heroList_:newItem()
		else
			var_34_4:removeAllChildren()
		end

		local var_34_5 = display.newNode()

		var_34_5:setTouchSwallowEnabled(false)

		for iter_34_0 = 1, var_0_9 do
			local var_34_6 = (arg_34_3 - 1) * var_0_9 + iter_34_0

			if var_34_6 > #arg_34_0.totalPet_ then
				break
			end

			var_34_3 = display.newNode()

			arg_34_0:initPetCell(var_34_3, var_34_6)

			local var_34_7 = var_34_3:getContentSize().width
			local var_34_8 = var_34_3:getContentSize().height
			local var_34_9 = (arg_34_0.heroList_.viewRect_.width - var_34_7 * var_0_9) / (var_0_9 + 1)

			var_34_3:align(display.CENTER, var_34_9 * iter_34_0 + (iter_34_0 - 1) * var_34_7 + var_34_7 / 2, var_34_8 / 2)
			var_34_5:addChild(var_34_3)
		end

		var_34_5:setContentSize(cc.size(arg_34_0.heroList_.viewRect_.width, var_34_3:getContentSize().height))
		var_34_4:setItemSize(arg_34_0.heroList_.viewRect_.width, var_34_3:getContentSize().height)
		var_34_4:addContent(var_34_5)

		return var_34_4
	end
end

function var_0_0.initHeroCell(arg_35_0, arg_35_1)
	local var_35_0 = arg_35_0.totalHero_[arg_35_0.selectedHeroClass_[arg_35_0.leftMenuType_]][arg_35_1]
	local var_35_1 = arg_35_0:initTeamCell(var_35_0)

	var_35_1.hero = var_35_0

	if arg_35_0.selectTeamType ~= xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		for iter_35_0 = 1, #arg_35_0.teamCells_ do
			if arg_35_0.teamCells_[iter_35_0].hero:getTableID() == var_35_0:getTableID() then
				arg_35_0:setHeroCellSelectedState(var_35_1)

				break
			end
		end
	end

	var_35_1:setTouchEnabled(true)
	var_35_1:setTouchSwallowEnabled(false)
	var_35_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_36_0)
		if arg_36_0.name == "began" then
			var_35_1:setScale(0.9)

			arg_35_0.startClick_ = true
			arg_35_0.prevX_ = arg_36_0.x
			arg_35_0.prevY_ = arg_36_0.y
			isLongTouch = false

			if xyd.tables.zhugeHero:zhugeSkill(var_35_0:getTableID()) ~= 0 and var_35_0.partner_type ~= 1 and var_35_0.partner_type ~= 5 then
				local var_36_0 = 0

				local function var_36_1()
					var_36_0 = var_36_0 + 0.1

					if var_36_0 > 0.5 then
						isLongTouch = true

						local var_37_0 = var_35_1:getParent():convertToWorldSpace(cc.p(var_35_1:getPosition()))

						arg_35_0:showSkillDetail(true, var_37_0, var_35_0)
					else
						isLongTouch = false
					end
				end

				arg_35_0.touchHandler = var_0_3.scheduleGlobal(var_36_1, 0.1)
			end

			return true
		elseif arg_36_0.name == "moved" then
			if math.abs(arg_36_0.y - arg_35_0.prevY_) > 5 or math.abs(arg_36_0.x - arg_35_0.prevX_) > 5 then
				arg_35_0.startClick_ = false

				var_35_1:setScale(1)

				if arg_35_0.touchHandler then
					var_0_3.unscheduleGlobal(arg_35_0.touchHandler)
				end

				arg_35_0:showSkillDetail(false)

				isLongTouch = false
			end
		elseif arg_36_0.name == "ended" and arg_35_0.startClick_ then
			var_35_1:setScale(1)

			if arg_35_0.touchHandler then
				var_0_3.unscheduleGlobal(arg_35_0.touchHandler)
			end

			if isLongTouch then
				arg_35_0:showSkillDetail(false)

				return
			end

			if arg_35_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
				arg_35_0:clickSpecialAvatar(var_35_1)
			else
				arg_35_0:clickAvatar(var_35_1)
			end
		end

		return true
	end)

	if var_35_0.isDead then
		var_35_1:setTouchEnabled(false)
	end

	return var_35_1
end

function var_0_0.initTeamCell(arg_38_0, arg_38_1, arg_38_2)
	local var_38_0 = display.newNode()

	if arg_38_0.leftMenuType_ == var_0_12.RENT_HERO and not arg_38_2 then
		local var_38_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/hire_hero/select_mercenary_item.csb")
		local var_38_2 = var_38_1:getChildByName("container")

		var_38_2:getChildByName("player_name"):setString(var_0_4:translation("ZHUGE_FOREST_TIPS_37"))

		var_38_0.player_name = arg_38_1.player_name
		var_38_0.can_rent = arg_38_1.can_rent
		var_38_0.type = var_0_12.RENT_HERO

		var_38_2:getChildByName("rent_cost"):setString("")
		var_38_2:getChildByName("yongbing_tubiao"):setVisible(true)
		var_38_2:getChildByName("is_can_rent"):setVisible(false)
		var_38_2:getChildByName("jinbi"):setVisible(false)
		var_38_0:setContentSize(var_38_1:getChildByName("container"):getContentSize())
		xyd.setAvatarBorder(arg_38_1, var_38_2:getChildByName("avatar"))

		local var_38_3 = var_38_2:getChildByName("chosen")

		var_38_3:setLocalZOrder(100)
		var_38_3:setVisible(false)

		local var_38_4 = var_38_2:getChildByName("avatar_mask")

		var_38_4:setLocalZOrder(2)
		var_38_4:setVisible(false)
		var_38_2:getChildByName("lv_txt"):setString(arg_38_1:getLevel())

		local var_38_5 = var_38_2:getChildByName("name_txt")

		var_38_5:setString(arg_38_1:getName())
		var_38_5:enableOutline(cc.c4b(0, 0, 0, 105), 1)

		if xyd.Color2Level[arg_38_1:getColor()] ~= "" then
			local var_38_6 = {
				size = 20,
				align = cc.ui.TEXT_ALIGN_LEFT,
				valign = cc.ui.TEXT_VALIGN_BOTTOM,
				x = var_38_5:getX() + var_38_5:getWidth() / 2 - 10,
				y = var_38_5:getY(),
				color = xyd.color.HERO_QUALITY[arg_38_1:getColor()],
				text = xyd.Color2Level[arg_38_1:getColor()]
			}
			local var_38_7 = xyd.AssetLoader.get():loadLabel(var_38_6)

			var_38_7:addTo(var_38_2)
			var_38_7:align(display.CENTER_LEFT)
			var_38_7:enableOutline(cc.c4b(0, 0, 0, 255), 1)
			var_38_5:x(var_38_5:getX() - 15)
		end

		local var_38_8 = var_38_2:getChildByName("hp_bar")
		local var_38_9 = var_38_2:getChildByName("mp_bar")
		local var_38_10 = var_38_2:getChildByName("dead_txt")

		var_38_10:setString(var_0_4:translation("ALREADY_DEAD"))

		if var_38_10 then
			var_38_10:setVisible(false)
		end

		local var_38_11 = false
		local var_38_12

		var_38_8:hide()
		var_38_9:hide()
		var_38_2:getChildByName("hp_di"):hide()
		var_38_2:getChildByName("mp_di"):hide()

		arg_38_1.isDead = var_38_11

		var_38_2:setPosition(cc.p(0, 0))

		var_38_0.hero = arg_38_1

		var_38_0:setAnchorPoint(cc.p(0.5, 0.5))
		var_38_0:addChild(var_38_1)
		var_38_1:setName("yongbingCell")
		var_38_0:setTouchSwallowEnabled(false)
		var_38_0:setTouchEnabled(true)

		local var_38_13 = false
	else
		local var_38_14 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")
		local var_38_15 = var_38_14:getChildByName("background"):getContentSize()

		var_38_0:setContentSize(var_38_15)

		if arg_38_1.type == var_0_12.RENT_HERO or arg_38_1.partner_type == 1 or arg_38_1.partner_type == 5 then
			var_38_14:getChildByName("yongbing_tubiao"):setVisible(true)
		else
			var_38_14:getChildByName("yongbing_tubiao"):setVisible(false)
		end

		if xyd.tables.zhugeHero:zhugeSkill(arg_38_1:getTableID()) ~= 0 and arg_38_1.partner_type ~= 1 and arg_38_1.partner_type ~= 5 then
			local var_38_16 = xyd.AssetLoader.get():loadSprite("windows/zhugeliang/skill_icon.png")

			var_38_16:addTo(var_38_0)
			var_38_16:setAnchorPoint(cc.p(0.5, 0.5))
			var_38_16:setPosition(cc.p(110, 120))
			var_38_16:setLocalZOrder(100)
		end

		local var_38_17 = var_38_14:getChildByName("background"):getContentSize()

		var_38_14:setContentSize(var_38_17)
		xyd.setAvatarBorder(arg_38_1, var_38_14:getChildByName("avatar"))

		local var_38_18 = var_38_14:getChildByName("chosen")

		var_38_18:setLocalZOrder(100)
		var_38_18:setVisible(false)

		local var_38_19 = var_38_14:getChildByName("avatar_mask")

		var_38_19:setLocalZOrder(2)
		var_38_19:setVisible(false)
		var_38_14:getChildByName("is_can_rent"):setVisible(false)

		for iter_38_0 = 1, 3 do
			var_38_14:getChildByName("team" .. iter_38_0):setVisible(false)
		end

		var_38_14:getChildByName("lv_txt"):setString(arg_38_1:getLevel())

		local var_38_20 = var_38_14:getChildByName("name_text")

		var_38_20:setString(arg_38_1:getName())
		var_38_20:enableOutline(cc.c4b(0, 0, 0, 105), 1)

		if xyd.Color2Level[arg_38_1:getColor()] ~= "" then
			local var_38_21 = {
				size = 20,
				align = cc.ui.TEXT_ALIGN_LEFT,
				valign = cc.ui.TEXT_VALIGN_BOTTOM,
				x = var_38_20:getX() + var_38_20:getWidth() / 2 - 10,
				y = var_38_20:getY(),
				color = xyd.color.HERO_QUALITY[arg_38_1:getColor()],
				text = xyd.Color2Level[arg_38_1:getColor()]
			}
			local var_38_22 = xyd.AssetLoader.get():loadLabel(var_38_21)

			var_38_22:addTo(var_38_14)
			var_38_22:align(display.CENTER_LEFT)
			var_38_22:enableOutline(cc.c4b(0, 0, 0, 255), 1)
			var_38_20:x(var_38_20:getX() - 15)
		end

		local var_38_23 = var_38_14:getChildByName("hp_bar")
		local var_38_24 = var_38_14:getChildByName("mp_bar")
		local var_38_25 = var_38_14:getChildByName("dead_text")
		local var_38_26 = arg_38_0.zhugeModel:getHeroStatus(arg_38_1:getTableID())

		if var_38_26 and next(var_38_26) then
			arg_38_0:updateHeroAvatar(var_38_14, var_38_0, arg_38_1, var_38_26)
		else
			var_38_23:hide()
			var_38_24:hide()
			var_38_14:getChildByName("hp_di"):hide()
			var_38_14:getChildByName("mp_di"):hide()

			arg_38_1.isDead = false
		end

		var_38_14:setName("layout")

		var_38_0.hero = arg_38_1

		var_38_0:setAnchorPoint(cc.p(0.5, 0.5))
		var_38_0:addChild(var_38_14)
		arg_38_0:setHeroCellUnSelectedState(var_38_0, arg_38_2)

		if arg_38_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
			for iter_38_1, iter_38_2 in ipairs(arg_38_0.select_) do
				if iter_38_2:getTableID() == arg_38_1:getTableID() and iter_38_2.player_name == arg_38_1.player_name then
					var_38_0.teamNo_ = iter_38_1

					var_38_18:setVisible(true)
					var_38_19:setVisible(true)

					arg_38_0.team_[iter_38_1].iniCell_ = var_38_0
					arg_38_0.team_[iter_38_1].iniCellVisible_ = false

					break
				end
			end
		end
	end

	return var_38_0
end

function var_0_0.updateHeroAvatar(arg_39_0, arg_39_1, arg_39_2, arg_39_3, arg_39_4)
	if not arg_39_4 then
		return
	end

	local var_39_0 = arg_39_1:getChildByName("hp_bar")
	local var_39_1 = arg_39_1:getChildByName("mp_bar")
	local var_39_2 = arg_39_1:getChildByName("dead_text")

	var_39_2:setVisible(false)

	local var_39_3 = arg_39_1:getChildByName("avatar_mask")

	var_39_3:setVisible(false)

	local var_39_4 = false

	arg_39_3.healthStatus = arg_39_4

	if arg_39_4 and arg_39_4.health then
		local var_39_5 = 0
		local var_39_6 = 0

		if arg_39_4.health == 0 then
			var_39_5 = 100
			var_39_6 = arg_39_4.mp / 10
		elseif arg_39_4.health == 1 and arg_39_4.hp >= 1 then
			var_39_5 = arg_39_4.hp / arg_39_4.max_hp * 100
			var_39_6 = arg_39_4.mp / 10
		else
			var_39_5 = 0
			var_39_6 = 0

			var_39_3:setVisible(true)
			var_39_2:setLocalZOrder(3)
			var_39_2:setVisible(true)
			var_39_2:enableOutline(cc.c4b(0, 0, 0), 2)
			var_39_2:getVirtualRenderer():setAdditionalKerning(-2)

			var_39_4 = true
		end

		var_39_0:setPercent(var_39_5)
		var_39_0:setVisible(true)
		var_39_1:setPercent(var_39_6)
		var_39_1:setVisible(true)
	end

	arg_39_3.isDead = var_39_4
end

function var_0_0.setHeroCellSelectedState(arg_40_0, arg_40_1)
	local var_40_0

	if arg_40_0.leftMenuType_ == var_0_12.SELF_HERO then
		var_40_0 = arg_40_1:getChildByName("layout")
	else
		var_40_0 = arg_40_1:getChildByName("yongbingCell"):getChildByName("container")
	end

	local var_40_1 = var_40_0:getChildByName("avatar_mask")
	local var_40_2 = var_40_0:getChildByName("chosen")

	arg_40_1.isSelected = true

	var_40_1:setVisible(true)
	var_40_2:setVisible(true)
end

function var_0_0.setHeroCellUnSelectedState(arg_41_0, arg_41_1, arg_41_2)
	local var_41_0

	if arg_41_0.leftMenuType_ == var_0_12.SELF_HERO or arg_41_2 then
		var_41_0 = arg_41_1:getChildByName("layout")
	else
		var_41_0 = arg_41_1:getChildByName("yongbingCell"):getChildByName("container")
	end

	local var_41_1 = var_41_0:getChildByName("avatar_mask")
	local var_41_2 = var_41_0:getChildByName("chosen")

	var_41_2:setLocalZOrder(100)
	var_41_1:setLocalZOrder(2)

	arg_41_1.isSelected = false

	if arg_41_1.hero and arg_41_1.hero.isDead then
		var_41_1:setVisible(true)
	else
		var_41_1:setVisible(false)
	end

	var_41_2:setVisible(false)
end

function var_0_0.initPetCell(arg_42_0, arg_42_1, arg_42_2)
	local var_42_0 = arg_42_0.totalPet_[arg_42_2]
	local var_42_1 = false

	if arg_42_0.rentMenuType == var_0_13.RENT_PET then
		local var_42_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/cloud_city/rent_pet_avatar.csb")

		arg_42_1:addChild(var_42_2)

		arg_42_1.type = var_0_14.RENT_PET

		var_42_2:setName("rent_cell")

		local var_42_3 = var_42_2:getChildByName("container")

		arg_42_1:align(display.CENTER):size(var_42_3:getContentSize().width, var_42_3:getContentSize().height)

		local var_42_4 = var_42_3:getChildByName("avatar")

		var_42_3:getChildByName("player_name"):setString(var_42_0.player_name)
		var_42_3:getChildByName("rent_cost"):setString(var_42_0.rent_need_mana)
		var_42_4:getChildByName("yongbing_tubiao"):setPosition(cc.p(90, 100))
		xyd.setPetAvatar(var_42_4, var_42_0, 100)
		var_42_4:setPositionY(var_42_4:getPositionY() + 15)
		var_42_3:getChildByName("can_not_rent"):setVisible(false)
	else
		arg_42_1:align(display.CENTER):size(146, 146)
		xyd.setPetAvatar(arg_42_1, var_42_0, 100)

		arg_42_1.type = var_0_14.SELF_PET

		if var_42_0.partner_type == 3 then
			local var_42_5 = xyd.AssetLoader.get():loadSprite("windows/zhugeliang/yongbing_tubiao.png")

			var_42_5:addTo(arg_42_1)
			var_42_5:setAnchorPoint(cc.p(0.5, 0.5))
			var_42_5:setPosition(cc.p(110, 120))

			arg_42_1.type = var_0_14.RENT_PET
		end
	end

	arg_42_1.hero = var_42_0

	arg_42_1:setTouchEnabled(true)
	arg_42_1:setTouchSwallowEnabled(false)
	arg_42_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_43_0)
		if not var_42_1 then
			if arg_43_0.name == "began" then
				arg_42_0.startClick_ = true
				arg_42_0.prevX_ = arg_43_0.x
				arg_42_0.prevY_ = arg_43_0.y
			elseif arg_43_0.name == "moved" then
				if math.abs(arg_43_0.y - arg_42_0.prevY_) > 5 or math.abs(arg_43_0.x - arg_42_0.prevX_) > 5 then
					arg_42_0.startClick_ = false
				end
			elseif arg_43_0.name == "ended" and arg_42_0.startClick_ then
				arg_42_0:clickPetAvatar(arg_42_1)
			end
		end

		return true
	end)

	for iter_42_0, iter_42_1 in ipairs(arg_42_0.petTeam_) do
		if var_42_0 == iter_42_1.hero then
			arg_42_0.petTeam_[iter_42_0].iniCell_ = arg_42_1
			arg_42_1.teamNo_ = iter_42_0

			local var_42_6

			if arg_42_0.rentMenuType == var_0_13.RENT_PET then
				var_42_6 = arg_42_1:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
			else
				var_42_6 = arg_42_1:getChildByName("layout")
			end

			local var_42_7 = var_42_6:getChildByName("avatar_mask")
			local var_42_8 = var_42_6:getChildByName("chosen")

			var_42_7:setVisible(true)
			var_42_8:setVisible(true)

			break
		end
	end
end

function var_0_0.buttonHandler(arg_44_0, arg_44_1, arg_44_2, arg_44_3)
	if not arg_44_2 or not arg_44_2:getParent() then
		return
	end

	if arg_44_3.name == "ended" then
		transition.stopTarget(arg_44_2)
		arg_44_2:setScale(1)

		if arg_44_1 then
			arg_44_1(arg_44_2, eventType)
		end
	elseif arg_44_3.name == "began" then
		local var_44_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_44_2:runAction(var_44_0)

		return true
	elseif arg_44_3.name == "cancled" then
		transition.stopTarget(arg_44_2)
		arg_44_2:setScale(1)
	end
end

function var_0_0.getRentCost(arg_45_0)
	local var_45_0 = var_0_11.zhugeForestHelperCost
	local var_45_1 = var_0_11.zhugeForestHelperPetCost
	local var_45_2 = arg_45_0:getSelectTeamInfo()
	local var_45_3 = xyd.splitToNumber(var_45_2.rent_partner_ids, "|")
	local var_45_4 = xyd.splitToNumber(var_45_2.rent_pet_ids, "|")
	local var_45_5 = 0

	if var_45_3 and next(var_45_3) then
		for iter_45_0 = 1, #var_45_3 do
			var_45_5 = var_45_5 + var_45_0[iter_45_0]
		end
	end

	if var_45_4 and next(var_45_4) then
		for iter_45_1 = 1, #var_45_4 do
			var_45_5 = var_45_5 + var_45_1[iter_45_1]
		end
	end

	return var_45_5
end

function var_0_0.gotoNextWnd(arg_46_0)
	local function var_46_0()
		xyd.WindowManager.get():openWindow("toast", {
			isAutoClose = 0,
			message = var_0_4:translation("ZHUGE_ADVENTURE_TIPS_40")
		})

		arg_46_0.isBattle_ = true

		if arg_46_0.selectTeamType == xyd.ZhugeSelectTeamType.FIRST_SELECT then
			arg_46_0:setFirstTeam()
		elseif arg_46_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_EXTRA then
			arg_46_0:setExtraTeam()
		end
	end

	local var_46_1 = arg_46_0:getRentCost()

	if var_46_1 ~= 0 then
		local var_46_2 = string.format(var_0_4:translation("ZHUGE_FOREST_TIPS_38"), var_46_1)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_46_2, function()
			if var_46_1 > arg_46_0.selfPlayer.crystal then
				local var_48_0 = var_0_4:translation("ZHUGE_FOREST_TIPS_5")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_48_0
				})

				return
			end

			var_46_0()
		end, nil, nil, arg_46_0.colorMode)
	else
		var_46_0()
	end
end

function var_0_0.setButtonClick(arg_49_0)
	arg_49_0:initLeftMenu()
	arg_49_0:initRightMenu()
	arg_49_0:initTopRentMenu()
	arg_49_0:nodeByName("button_ok_2"):addTouchEventListener(function(arg_50_0, arg_50_1)
		if arg_50_1 == ccui.TouchEventType.ended and not arg_49_0.isBattle_ then
			if #arg_49_0.teamCells_ < 1 then
				local var_50_0 = var_0_4:translation("ZHUGE_FOREST_TIPS_21")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_50_0
				})

				return
			end

			if #arg_49_0.teamCells_ ~= arg_49_0.maxPartnerNum or #arg_49_0.petSelect_ ~= arg_49_0.maxPetNum then
				local var_50_1 = ""

				if #arg_49_0.teamCells_ ~= arg_49_0.maxPartnerNum then
					var_50_1 = var_0_4:translation("ZHUGE_FOREST_TIPS_20")
				else
					var_50_1 = var_0_4:translation("ZHUGE_ADVENTURE_TIPS_37")
				end

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_50_1, function()
					arg_49_0:gotoNextWnd()
				end, nil, nil, arg_49_0.colorMode)
			else
				arg_49_0:gotoNextWnd()
			end
		end
	end)
	arg_49_0:nodeByName("button_ok_3"):addTouchEventListener(function(arg_52_0, arg_52_1)
		if arg_52_1 == ccui.TouchEventType.ended and not arg_49_0.isBattle_ then
			if #arg_49_0.teamCells_ < 1 then
				local var_52_0 = var_0_4:translation("ZHUGE_FOREST_TIPS_21")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_52_0
				})

				return
			end

			if #arg_49_0.teamCells_ ~= arg_49_0.maxPartnerNum or #arg_49_0.petSelect_ ~= arg_49_0.maxPetNum then
				local var_52_1 = ""

				if #arg_49_0.teamCells_ ~= arg_49_0.maxPartnerNum then
					var_52_1 = var_0_4:translation("ZHUGE_FOREST_TIPS_20")
				else
					var_52_1 = var_0_4:translation("ZHUGE_ADVENTURE_TIPS_37")
				end

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_52_1, function()
					arg_49_0:gotoNextWnd()
				end, nil, nil, arg_49_0.colorMode)
			else
				arg_49_0:gotoNextWnd()
			end
		end
	end)
	arg_49_0:nodeByName("button_ok"):addTouchEventListener(function(arg_54_0, arg_54_1)
		if arg_54_1 == ccui.TouchEventType.ended and not arg_49_0.isBattle_ then
			if #arg_49_0.select_ < 1 then
				local var_54_0 = var_0_4:translation("ZHUGE_FOREST_TIPS_21")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_54_0
				})

				return
			end

			if #arg_49_0.select_ ~= arg_49_0.maxPartnerNum or #arg_49_0.petSelect_ ~= arg_49_0.maxPetNum then
				local var_54_1 = var_0_4:translation("ZHUGE_FOREST_TIPS_20")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_54_1, function()
					if arg_49_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
						arg_49_0:endCurDialog()
					end
				end, nil, nil, arg_49_0.colorMode)
			elseif arg_49_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
				arg_49_0:endCurDialog()
			end
		end
	end)
	arg_49_0:nodeByName("close"):addTouchEventListener(function(arg_56_0, arg_56_1)
		if arg_56_1 == ccui.TouchEventType.ended and not arg_49_0.isBattle_ then
			local var_56_0 = var_0_4:translation("ZHUGE_ADVENTURE_TIPS_27")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_56_0, function()
				local var_57_0 = xyd.WindowManager.get():getWindow("zhuge_main_wnd")

				if not var_57_0 or tolua.isnull(var_57_0) then
					xyd.WindowManager.get():openWindow("zhuge_main_wnd")
				end

				xyd.WindowManager.get():closeWindow(arg_49_0)
			end, nil, nil, arg_49_0.colorMode)
		end
	end)
end

function var_0_0.getSelectTeamInfo(arg_58_0)
	local var_58_0 = ""
	local var_58_1 = ""
	local var_58_2 = ""
	local var_58_3 = ""

	for iter_58_0, iter_58_1 in ipairs(arg_58_0.teamCells_) do
		local var_58_4 = iter_58_1.hero

		if var_58_4.type == var_0_12.RENT_HERO then
			var_58_1 = var_58_1 .. var_58_4:getTableID()

			if iter_58_0 ~= #arg_58_0.teamCells_ then
				var_58_1 = var_58_1 .. "|"
			end
		else
			var_58_0 = var_58_0 .. iter_58_1.hero:getTableID()

			if iter_58_0 ~= #arg_58_0.teamCells_ then
				var_58_0 = var_58_0 .. "|"
			end
		end
	end

	for iter_58_2 = 1, #arg_58_0.petSelect_ do
		local var_58_5 = arg_58_0.petSelect_[iter_58_2]

		if var_58_5.type == var_0_14.RENT_PET then
			var_58_3 = var_58_3 .. var_58_5:getTableID()

			if iter_58_2 ~= #arg_58_0.petSelect_ then
				var_58_3 = var_58_3 .. "|"
			end
		else
			var_58_2 = var_58_2 .. var_58_5:getTableID()

			if iter_58_2 ~= #arg_58_0.petSelect_ then
				var_58_2 = var_58_2 .. "|"
			end
		end
	end

	return {
		partner_ids = var_58_0,
		rent_partner_ids = var_58_1,
		pet_ids = var_58_2,
		rent_pet_ids = var_58_3
	}
end

function var_0_0.setFirstTeam(arg_59_0)
	local var_59_0 = arg_59_0:getSelectTeamInfo()

	arg_59_0.zhugeModel:setSelectTeam(var_59_0, function(arg_60_0, arg_60_1)
		if arg_60_0 == xyd.error.OK then
			if arg_59_0.zhugeModel:getExtraPatnerNum() > 0 then
				arg_59_0.selectTeamType = xyd.ZhugeSelectTeamType.SELECT_EXTRA

				arg_59_0:clear()
				arg_59_0:init()
				arg_59_0:refreshSelectedHeroClass()
			else
				xyd.WindowManager.get():openWindow("zhuge_new_adventure")
				xyd.WindowManager.get():closeWindow(arg_59_0)
			end
		end

		local var_60_0 = xyd.WindowManager.get():getWindow("toast")

		if var_60_0 and not tolua.isnull(var_60_0) then
			xyd.WindowManager.get():closeWindow("toast")
		end

		arg_59_0.isBattle_ = false
	end)
end

function var_0_0.setExtraTeam(arg_61_0)
	local var_61_0 = arg_61_0:getSelectTeamInfo()

	arg_61_0.zhugeModel:setExtraPartner(var_61_0, function(arg_62_0, arg_62_1)
		xyd.WindowManager.get():openWindow("zhuge_new_adventure")
		xyd.WindowManager.get():closeWindow(arg_61_0)

		local var_62_0 = xyd.WindowManager.get():getWindow("toast")

		if var_62_0 and not tolua.isnull(var_62_0) then
			xyd.WindowManager.get():closeWindow("toast")
		end

		arg_61_0.isBattle_ = false
	end)
end

function var_0_0.getNewHeroList(arg_63_0)
	return arg_63_0.select_
end

function var_0_0.getNewPet(arg_64_0)
	return arg_64_0.petSelect_[1]
end

function var_0_0.setAdventureTeam(arg_65_0)
	local var_65_0 = {
		heros = arg_65_0:getNewHeroList(),
		pet = arg_65_0:getNewPet()
	}

	arg_65_0.zhugeModel:updateCurrentTeam(var_65_0)

	if arg_65_0.zhugeModel:getShopType() then
		local var_65_1 = {
			callback = function()
				xyd.WindowManager.get():openWindow("zhuge_adventure")
			end
		}

		xyd.WindowManager.get():openWindow("zhuge_shop", var_65_1)
	else
		if xyd.WindowManager.get():isWindowOpen("zhuge_adventure") then
			xyd.WindowManager.get():closeWindow("zhuge_adventure")
		end

		xyd.WindowManager.get():openWindow("zhuge_adventure")
	end

	xyd.WindowManager.get():closeWindow(arg_65_0)
end

function var_0_0.endCurDialog(arg_67_0)
	if not arg_67_0.specialParams or not next(arg_67_0.specialParams) then
		return
	end

	local var_67_0 = arg_67_0:getNewHeroList()
	local var_67_1 = ""

	for iter_67_0, iter_67_1 in ipairs(var_67_0) do
		local var_67_2 = arg_67_0.zhugeModel:getHeroStatus(iter_67_1:getTableID())

		if var_67_2 and next(var_67_2) then
			if var_67_1 ~= "" then
				var_67_1 = var_67_1 .. "|" .. var_67_2.init_id
			else
				var_67_1 = var_67_1 .. var_67_2.init_id
			end
		end
	end

	local var_67_3 = arg_67_0:getNewPet()
	local var_67_4 = 0

	if var_67_3 then
		local var_67_5 = arg_67_0.zhugeModel:getHeroStatus(var_67_3:getTableID())

		if var_67_5 and next(var_67_5) then
			var_67_4 = tonumber(var_67_5.init_id)
		end
	end

	arg_67_0.isBattle_ = true

	local var_67_6 = {
		team_str = var_67_1,
		pet_id = var_67_4
	}
	local var_67_7 = arg_67_0:getSelectTeamInfo()

	arg_67_0.zhugeModel:endCurDialog(arg_67_0.specialParams.eventID, arg_67_0.specialParams.dialogID, arg_67_0.specialParams.mapIndex, var_67_6, function(arg_68_0, arg_68_1)
		if arg_68_0 == xyd.error.OK then
			if arg_67_0 and not tolua.isnull(arg_67_0) then
				arg_67_0:playReport(arg_68_1.battle_report)
			end
		else
			arg_67_0.isBattle_ = false
		end
	end)
end

function var_0_0.initRightMenu(arg_69_0)
	arg_69_0.rightMenuButtons_ = {}

	table.insert(arg_69_0.rightMenuButtons_, arg_69_0:nodeByName("button_all"))
	table.insert(arg_69_0.rightMenuButtons_, arg_69_0:nodeByName("button_qianpai"))
	table.insert(arg_69_0.rightMenuButtons_, arg_69_0:nodeByName("button_zhongpai"))
	table.insert(arg_69_0.rightMenuButtons_, arg_69_0:nodeByName("button_houpai"))

	for iter_69_0 = 1, #arg_69_0.rightMenuButtons_ do
		arg_69_0.rightMenuButtons_[iter_69_0]:setZoomScale(0.3)
		arg_69_0.rightMenuButtons_[iter_69_0]:addTouchEventListener(function(arg_70_0, arg_70_1)
			if arg_70_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				if arg_69_0.selectedHeroClass_[arg_69_0.leftMenuType_] == iter_69_0 then
					for iter_70_0 = 1, #arg_69_0.rightMenuButtons_ do
						if iter_70_0 == arg_69_0.selectedHeroClass_[arg_69_0.leftMenuType_] then
							arg_69_0.rightMenuButtons_[iter_70_0]:setBrightStyle(ccui.BrightStyle.highlight)
						else
							arg_69_0.rightMenuButtons_[iter_70_0]:setBrightStyle(ccui.BrightStyle.normal)
						end
					end

					return
				end

				arg_69_0.selectedHeroClass_[arg_69_0.leftMenuType_] = iter_69_0

				arg_69_0:refreshSelectedHeroClass()
			end
		end)
	end
end

function var_0_0.initLeftMenu(arg_71_0)
	arg_71_0:nodeByName("zhandui"):hide()
	arg_71_0:nodeByName("button_zhandui"):hide()

	arg_71_0:nodeByName("button_zhandui").menu_type = var_0_12.SELF_HERO

	arg_71_0:nodeByName("yongbing"):hide()
	arg_71_0:nodeByName("button_yongbing"):hide()

	arg_71_0:nodeByName("button_yongbing").menu_type = var_0_12.RENT_HERO

	arg_71_0:nodeByName("pet"):hide()
	arg_71_0:nodeByName("button_pet"):hide()

	arg_71_0:nodeByName("button_pet").menu_type = var_0_12.SELF_PET
	arg_71_0.leftMenuType_ = var_0_12.SELF_HERO
	arg_71_0.leftMenuButtons_, arg_71_0.leftMenuText_ = {}, {}

	table.insert(arg_71_0.leftMenuButtons_, arg_71_0:nodeByName("button_zhandui"))
	table.insert(arg_71_0.leftMenuText_, arg_71_0:nodeByName("zhandui"))

	if arg_71_0:canRentHero() then
		table.insert(arg_71_0.leftMenuButtons_, arg_71_0:nodeByName("button_yongbing"))
		table.insert(arg_71_0.leftMenuText_, arg_71_0:nodeByName("yongbing"))
	end

	if arg_71_0:isPet() then
		table.insert(arg_71_0.leftMenuButtons_, arg_71_0:nodeByName("button_pet"))
		table.insert(arg_71_0.leftMenuText_, arg_71_0:nodeByName("pet"))
	end

	if #arg_71_0.leftMenuButtons_ <= 1 then
		return
	end

	for iter_71_0 = 1, #arg_71_0.leftMenuButtons_ do
		arg_71_0.leftMenuButtons_[iter_71_0]:show()
		arg_71_0.leftMenuText_[iter_71_0]:show()
		arg_71_0.leftMenuButtons_[iter_71_0]:setZoomScale(0.3)

		local var_71_0 = arg_71_0.leftMenuButtons_[1]:getY() - 85 * (iter_71_0 - 1)

		arg_71_0.leftMenuButtons_[iter_71_0]:y(var_71_0)
		arg_71_0.leftMenuText_[iter_71_0]:y(var_71_0)
		arg_71_0.leftMenuButtons_[iter_71_0]:addTouchEventListener(function(arg_72_0, arg_72_1)
			if arg_72_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				for iter_72_0, iter_72_1 in ipairs(arg_71_0.leftMenuButtons_) do
					iter_72_1:setBrightStyle(arg_72_0 == iter_72_1 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
				end

				arg_71_0.leftMenuType_ = arg_72_0.menu_type
				arg_71_0.rentMenuType = var_0_13.RENT_HERO

				arg_71_0:updateTopRentMenu()
				arg_71_0:selectHeros()
				arg_71_0:selectPets()
				arg_71_0:updateTopText()
				arg_71_0:refreshSelectedHeroClass()
				arg_71_0:updateBottomLayout()
			end
		end)
	end

	for iter_71_1, iter_71_2 in ipairs(arg_71_0.leftMenuButtons_) do
		if iter_71_2 == arg_71_0:nodeByName("button_zhandui") then
			iter_71_2:setBrightStyle(ccui.BrightStyle.highlight)
		else
			iter_71_2:setBrightStyle(ccui.BrightStyle.normal)
		end
	end
end

function var_0_0.isPet(arg_73_0)
	if arg_73_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_EXTRA then
		return false
	end

	return true
end

function var_0_0.initTopRentMenu(arg_74_0)
	arg_74_0:nodeByName("btn_rent_hero"):addTouchEventListener(function(arg_75_0, arg_75_1)
		if arg_75_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_74_0.rentMenuType = var_0_13.RENT_HERO

			arg_74_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_74_0:nodeByName("btn_rent_pet"):setBrightStyle(ccui.BrightStyle.normal)
			arg_74_0:updateBottomLayout()
			arg_74_0:updateTopText()
			arg_74_0:selectPets()
			arg_74_0.heroList_:reload()
		end
	end)
	arg_74_0:nodeByName("btn_rent_pet"):addTouchEventListener(function(arg_76_0, arg_76_1)
		if arg_76_1 == ccui.TouchEventType.ended and not arg_74_0.isClickRentPet then
			arg_74_0.isClickRentPet = true

			xyd.playButtonSound()

			arg_74_0.rentMenuType = var_0_13.RENT_PET

			arg_74_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.normal)
			arg_74_0:nodeByName("btn_rent_pet"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_74_0:updateBottomLayout()
			arg_74_0:updateTopText()
			arg_74_0:initRentPets(function()
				arg_74_0:selectPets()
				arg_74_0.heroList_:reload()

				arg_74_0.isClickRentPet = false
			end)
		end
	end)
	arg_74_0:nodeByName("top_rent_container"):setVisible(false)

	arg_74_0.rentMenuType = var_0_13.RENT_HERO
end

function var_0_0.canRentHero(arg_78_0)
	if arg_78_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		return false
	end

	return true
end

function var_0_0.refreshSelectedHeroClass(arg_79_0)
	for iter_79_0 = 1, #arg_79_0.rightMenuButtons_ do
		if iter_79_0 == arg_79_0.selectedHeroClass_[arg_79_0.leftMenuType_] then
			arg_79_0.rightMenuButtons_[iter_79_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_79_0.rightMenuButtons_[iter_79_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_79_0.heroList_:removeAllItems()

	if arg_79_0.selectedHeroClass_[arg_79_0.leftMenuType_] ~= xyd.DistanceType.ALL then
		for iter_79_1, iter_79_2 in ipairs(arg_79_0.select_) do
			if iter_79_2:getDistanceType() ~= arg_79_0.selectedHeroClass_[arg_79_0.leftMenuType_] then
				arg_79_0.team_[iter_79_1].iniCellVisible_ = true
			end
		end
	end

	arg_79_0.heroList_:reload()
end

function var_0_0.updateTopRentMenu(arg_80_0)
	if not arg_80_0:isPet() then
		arg_80_0:nodeByName("top_rent_container"):setVisible(false)

		return
	end

	if arg_80_0.leftMenuType_ == var_0_12.RENT_HERO then
		arg_80_0:nodeByName("top_rent_container"):setVisible(true)
		arg_80_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_80_0:nodeByName("btn_rent_pet"):setBrightStyle(ccui.BrightStyle.normal)

		if not arg_80_0.ischangeListRect then
			if arg_80_0.selectTeamType == xyd.ZhugeSelectTeamType.FIRST_SELECT then
				var_0_8 = 70

				arg_80_0:nodeByName("lev_limit_txt"):setPositionY(arg_80_0:nodeByName("lev_limit_txt"):getPositionY() - var_0_8)
			end

			local var_80_0 = arg_80_0.heroList_:getViewRect()
			local var_80_1 = cc.rect(0, 0, var_80_0.width, var_80_0.height - var_0_8)

			arg_80_0.heroList_:setViewRect(var_80_1)

			arg_80_0.ischangeListRect = true
		end
	else
		arg_80_0:nodeByName("top_rent_container"):setVisible(false)

		if arg_80_0.ischangeListRect then
			if arg_80_0.selectTeamType == xyd.ZhugeSelectTeamType.FIRST_SELECT then
				var_0_8 = 70

				arg_80_0:nodeByName("lev_limit_txt"):setPositionY(arg_80_0:nodeByName("lev_limit_txt"):getPositionY() + var_0_8)
			end

			local var_80_2 = arg_80_0.heroList_:getViewRect()
			local var_80_3 = cc.rect(0, 0, var_80_2.width, var_80_2.height + var_0_8)

			arg_80_0.heroList_:setViewRect(var_80_3)
		end

		arg_80_0.ischangeListRect = false
	end
end

function var_0_0.selectHeros(arg_81_0)
	arg_81_0.totalHero_ = arg_81_0.tmpTotalHero_[arg_81_0.leftMenuType_]
end

function var_0_0.selectPets(arg_82_0)
	if arg_82_0.rentMenuType == var_0_13.RENT_PET then
		arg_82_0.totalPet_ = arg_82_0.tmpTotalPets[var_0_14.RENT_PET]
	else
		arg_82_0.totalPet_ = arg_82_0.tmpTotalPets[var_0_14.SELF_PET]
	end
end

function var_0_0.getHeroList(arg_83_0)
	local var_83_0 = {}

	for iter_83_0, iter_83_1 in ipairs(arg_83_0.teamCells_) do
		table.insert(var_83_0, iter_83_1.hero)
	end

	return var_83_0
end

function var_0_0.clickAvatar(arg_84_0, arg_84_1)
	if arg_84_0.isAnimated_ == true or arg_84_0.isBattle_ then
		return
	end

	if arg_84_1.isSelected then
		arg_84_0.isAnimated_ = true

		arg_84_0:deletePartner(arg_84_1.hero)
	elseif not arg_84_1.isSelected and arg_84_0:checkHeroValid(arg_84_1.hero) then
		arg_84_0.isAnimated_ = true

		arg_84_0:addPartner(arg_84_1.hero)
	end

	arg_84_0:updateSelectNum()
end

function var_0_0.deletePartner(arg_85_0, arg_85_1)
	if arg_85_1:getTableID() == arg_85_0.heroId then
		arg_85_0.isAnimated_ = false

		local var_85_0 = var_0_4:translation("BLOODLINE_INCUBUS_TIPS2")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_85_0
		})

		return
	end

	local var_85_1 = arg_85_0:getHeroCell(arg_85_1)
	local var_85_2, var_85_3 = arg_85_0:getTeamCell(arg_85_1)

	if not var_85_2 then
		return
	end

	var_85_2:retain()
	arg_85_0:removeItemFromTeamCells(arg_85_1)

	local var_85_4 = arg_85_0:getBottomItem(arg_85_1)

	if arg_85_0:scrollIfItemNotInviewRect(var_85_4, var_85_3) then
		arg_85_0:playRemoveBottomItem(var_85_2, var_85_4, var_85_1, var_85_3)
	else
		arg_85_0:playRemoveBottomItem(var_85_2, var_85_4, var_85_1, var_85_3)
	end
end

function var_0_0.addPartner(arg_86_0, arg_86_1)
	if #arg_86_0.teamCells_ >= arg_86_0.maxPartnerNum then
		arg_86_0.isAnimated_ = false

		local var_86_0 = var_0_4:translation("BLOODLINE_INCUBUS_TIPS4")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_86_0
		})

		return
	end

	local var_86_1 = arg_86_0:getHeroCell(arg_86_1)

	if var_86_1 then
		arg_86_0:setHeroCellSelectedState(var_86_1)

		local var_86_2 = arg_86_0:initTeamCell(arg_86_1, true)

		table.insert(arg_86_0.teamCells_, var_86_2)
		arg_86_0:updateSelectProgressShow()

		local var_86_3 = arg_86_0.bottomItems_[#arg_86_0.teamCells_]

		arg_86_0:scrollToIthItem(#arg_86_0.teamCells_ - 5)
		arg_86_0:playAddTeamCellToBottomItem(var_86_2, var_86_3, var_86_1)
	end
end

function var_0_0.playAddTeamCellToBottomItem(arg_87_0, arg_87_1, arg_87_2, arg_87_3)
	local var_87_0 = arg_87_3:convertToWorldSpace(cc.p(0, 0))
	local var_87_1 = arg_87_2:convertToWorldSpace(cc.p(0, 0))

	var_87_1.x = var_87_1.x + arg_87_1:getContentSize().width / 2

	arg_87_1:pos(var_87_0.x, var_87_0.y)
	arg_87_1:setAnchorPoint(cc.p(0, 0))
	arg_87_1:addTo(arg_87_0)
	arg_87_1:setLocalZOrder(100)
	transition.stopTarget(arg_87_1)
	transition.moveTo(arg_87_1, {
		time = 0.19,
		x = var_87_1.x,
		y = var_87_1.y,
		onComplete = function()
			arg_87_1.isAnimated_ = false
			arg_87_3.isAnimated_ = false
			arg_87_0.isAnimated_ = false

			arg_87_1:retain()
			arg_87_1:removeFromParent()
			arg_87_1:addTo(arg_87_2)

			arg_87_2.hero = arg_87_1.hero

			arg_87_1:setPosition(cc.p(16, 1))
			arg_87_1:setTouchEnabled(true)
			arg_87_1:setTouchSwallowEnabled(false)
			arg_87_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_89_0)
				if arg_89_0.name == "began" then
					arg_87_0.scrollViewMoved_ = false
				elseif arg_89_0.name == "ended" and arg_87_0.scrollViewMoved_ ~= true and not arg_87_0.isBattle_ then
					arg_87_0.isAnimated_ = true

					arg_87_0:deletePartner(arg_87_1.hero)
				end

				return true
			end)
		end
	})
end

function var_0_0.playRemoveBottomItem(arg_90_0, arg_90_1, arg_90_2, arg_90_3, arg_90_4)
	local var_90_0 = arg_90_2:convertToWorldSpace(cc.p(0, 0))

	var_90_0.x = var_90_0.x + arg_90_1:getContentSize().width / 2

	if var_90_0.x < 165 then
		var_90_0.x = 165
	elseif var_90_0.x > 1100 then
		var_90_0.x = 1100
	end

	local var_90_1 = arg_90_0:nodeByName("list_layer")
	local var_90_2 = cc.p(var_90_1:getPosition())

	arg_90_1:removeFromParent()
	arg_90_1:pos(var_90_0.x, var_90_0.y)
	arg_90_1:setAnchorPoint(cc.p(0, 0))
	arg_90_1:addTo(arg_90_0)
	arg_90_1:setLocalZOrder(100)
	transition.stopTarget(arg_90_1)

	if not tolua.isnull(arg_90_3) then
		var_90_2 = arg_90_3:convertToWorldSpace(cc.p(0, 0))

		local var_90_3

		if arg_90_0.leftMenuType_ == var_0_12.SELF_HERO or isBottom then
			var_90_3 = arg_90_3:getChildByName("layout")
		else
			var_90_3 = arg_90_3:getChildByName("yongbingCell"):getChildByName("container")
		end

		local var_90_4 = var_90_3:getChildByName("avatar_mask")
		local var_90_5 = var_90_3:getChildByName("chosen")

		var_90_4:setVisible(false)
		var_90_5:setVisible(false)

		arg_90_3.isSelected = false
	end

	arg_90_0:removeItem(arg_90_2, arg_90_4)
	arg_90_0:moveFadeOutAction(var_90_2.x, var_90_2.y, arg_90_1, function()
		arg_90_0:removeItemFromTeamCells(arg_90_1.hero)

		arg_90_0.isAnimated_ = false
	end)
end

function var_0_0.removeItemFromTeamCells(arg_92_0, arg_92_1)
	for iter_92_0 = 1, #arg_92_0.teamCells_ do
		local var_92_0 = arg_92_0.teamCells_[iter_92_0]

		if tolua.isnull(var_92_0) or var_92_0.hero:getTableID() == arg_92_1:getTableID() then
			table.remove(arg_92_0.teamCells_, iter_92_0)
		end
	end

	arg_92_0:updateSelectProgressShow()
	arg_92_0:updateSelectNum()
end

function var_0_0.getHeroCell(arg_93_0, arg_93_1)
	for iter_93_0 = 1, #arg_93_0.heroCells_ do
		local var_93_0 = arg_93_0.heroCells_[iter_93_0]

		if not tolua.isnull(var_93_0) and var_93_0.hero:getTableID() == arg_93_1:getTableID() and not tolua.isnull(var_93_0) then
			return var_93_0
		end
	end

	return nil
end

function var_0_0.getTeamCell(arg_94_0, arg_94_1)
	for iter_94_0 = 1, #arg_94_0.teamCells_ do
		local var_94_0 = arg_94_0.teamCells_[iter_94_0]

		if var_94_0.hero:getTableID() == arg_94_1:getTableID() and not tolua.isnull(var_94_0) then
			return var_94_0, iter_94_0
		end
	end

	return nil
end

function var_0_0.getBottomItem(arg_95_0, arg_95_1)
	for iter_95_0 = 1, #arg_95_0.bottomItems_ do
		local var_95_0 = arg_95_0.bottomItems_[iter_95_0]

		if var_95_0.hero and var_95_0.hero:getTableID() == arg_95_1:getTableID() and not tolua.isnull(var_95_0) then
			return var_95_0
		end
	end

	return nil
end

function var_0_0.removeItem(arg_96_0, arg_96_1, arg_96_2)
	arg_96_1.hero = nil

	arg_96_0.bottomList_:removeItem(arg_96_1, true)
	arg_96_0:setOrgPositonX()
	var_0_3.performWithDelayGlobal(function()
		if not arg_96_0 or tolua.isnull(arg_96_0) then
			return
		end

		for iter_97_0 = 1, #arg_96_0.bottomItems_ do
			if arg_96_0.bottomItems_[iter_97_0] == arg_96_1 then
				table.remove(arg_96_0.bottomItems_, iter_97_0)

				break
			end
		end

		arg_96_0:addNewBottomItem()
		arg_96_0.bottomList_:reload()

		if arg_96_2 >= var_0_10 then
			arg_96_0:scrollToOrgPositonX(true)
		else
			arg_96_0:scrollToOrgPositonX()
		end
	end, 0.19)
end

function var_0_0.scrollIfItemNotInviewRect(arg_98_0, arg_98_1, arg_98_2)
	if not arg_98_0.bottomList_:isItemInViewRect(arg_98_1) then
		if arg_98_2 > math.ceil(math.abs(arg_98_0.bottomList_:getScrollNode():getPositionX()) / 152) then
			arg_98_0:scrollToIthItem(arg_98_2 - 4)
		else
			arg_98_0:scrollToIthItem(arg_98_2)
		end

		return true
	elseif #arg_98_0.teamCells_ < var_0_10 then
		arg_98_0:scrollToIthItem(1)
	end

	return false
end

function var_0_0.getHeroCells(arg_99_0, arg_99_1)
	for iter_99_0 = 1, #arg_99_0.heroCells_ do
		if arg_99_0.heroCells_[iter_99_0].hero:getTableID() == arg_99_1:getTableID() and not tolua.isnull(arg_99_0.heroCells_[iter_99_0]) then
			return arg_99_0.heroCells_[iter_99_0]
		end
	end

	return nil
end

function var_0_0.moveFadeOutAction(arg_100_0, arg_100_1, arg_100_2, arg_100_3, arg_100_4)
	arg_100_0:widgetSet(arg_100_3)
	arg_100_3:setCascadeOpacityEnabled(true)

	local var_100_0 = cc.Spawn:create(cc.FadeOut:create(0.2), cc.MoveTo:create(0.3, cc.p(arg_100_1, arg_100_2)))

	arg_100_3:runActionOnce(var_100_0, true, arg_100_4)
end

function var_0_0.widgetSet(arg_101_0, arg_101_1)
	for iter_101_0, iter_101_1 in ipairs(arg_101_1:getChildren()) do
		if iter_101_1 ~= nil then
			iter_101_1:setCascadeOpacityEnabled(true)
			arg_101_0:widgetSet(iter_101_1)
		end
	end
end

function var_0_0.checkHeroValid(arg_102_0, arg_102_1)
	for iter_102_0, iter_102_1 in pairs(arg_102_0.teamCells_) do
		if arg_102_1:getTableID() == iter_102_1.hero:getTableID() or xyd.tables.hero:beforeAwaken(arg_102_1:getTableID()) == iter_102_1.hero:getTableID() or xyd.tables.hero:afterAwaken(arg_102_1:getTableID()) == iter_102_1.hero:getTableID() then
			return false
		end
	end

	return true
end

function var_0_0.canHeroJoinBattle(arg_103_0, arg_103_1)
	return true
end

function var_0_0.scrollListener(arg_104_0, arg_104_1)
	if arg_104_1.name == "began" then
		arg_104_0.scrollViewMoved_ = false
		arg_104_0.prevX_ = arg_104_1.x
	elseif arg_104_1.name == "moved" and 5 <= math.abs(arg_104_1.x - arg_104_0.prevX_) then
		arg_104_0.scrollViewMoved_ = true
	end
end

function var_0_0.clickSpecialAvatar(arg_105_0, arg_105_1, arg_105_2)
	if arg_105_1.isAnimated_ or not arg_105_1.teamNo_ and #arg_105_0.team_ >= arg_105_0.maxPartnerNum then
		return
	end

	if not arg_105_2 then
		arg_105_0.unPreSelect_ = true
	end

	local var_105_0

	if arg_105_0.leftMenuType_ == var_0_12.SELF_HERO then
		var_105_0 = arg_105_1:getChildByName("layout")
	else
		var_105_0 = arg_105_1:getChildByName("yongbingCell"):getChildByName("container")
	end

	local var_105_1 = var_105_0:getChildByName("avatar_mask")
	local var_105_2 = var_105_0:getChildByName("chosen")
	local var_105_3 = arg_105_1:convertToWorldSpace(cc.p(0, 0))
	local var_105_4 = var_105_3.x + arg_105_1:getContentSize().width / 2
	local var_105_5 = var_105_3.y + arg_105_1:getContentSize().height / 2

	arg_105_1.isAnimated_ = true

	if arg_105_1.teamNo_ then
		local var_105_6 = arg_105_0.team_[arg_105_1.teamNo_]

		arg_105_0:moveFadeOutAction(var_105_4, var_105_5, var_105_6, function()
			arg_105_1.isAnimated_ = false
		end)
		var_105_1:setVisible(false)
		var_105_2:setVisible(false)

		for iter_105_0 = #arg_105_0.team_, arg_105_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_105_0.team_[iter_105_0])

			local var_105_7, var_105_8 = arg_105_0:nodeByName("avatar" .. iter_105_0 - 1):getPosition()

			transition.moveTo(arg_105_0.team_[iter_105_0], {
				time = 0.3,
				x = var_105_7,
				y = var_105_8
			})

			arg_105_0.team_[iter_105_0].iniCell_.teamNo_ = iter_105_0 - 1
		end

		if arg_105_1.type == var_0_12.RENT_HERO then
			arg_105_0.isSelectMerHero = false
			arg_105_0.selectMerHero = nil
		end

		table.remove(arg_105_0.team_, arg_105_1.teamNo_)
		table.remove(arg_105_0.select_, arg_105_1.teamNo_)

		arg_105_1.teamNo_ = nil
	elseif not arg_105_1.teamNo_ and #arg_105_0.team_ < xyd.MAX_TEAM_MEMBER_NUM then
		local var_105_9 = arg_105_0:initBottomCell(arg_105_1.hero)

		var_105_9.iniCell_ = arg_105_1

		var_105_9:pos(var_105_4, var_105_5)
		var_105_9:addTo(arg_105_0)
		var_105_9:setTouchEnabled(true)

		local var_105_10 = arg_105_1.hero

		var_105_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_107_0)
			if arg_107_0.name == "ended" then
				arg_105_0:clickBottomAvatar(var_105_9)
			end

			return true
		end)

		arg_105_1.teamNo_ = arg_105_0:getTeamNo(var_105_9)

		for iter_105_1 = arg_105_1.teamNo_, #arg_105_0.team_ do
			local var_105_11, var_105_12 = arg_105_0:nodeByName("avatar" .. iter_105_1):getPosition()

			if arg_105_2 then
				arg_105_0.team_[iter_105_1]:pos(var_105_11, var_105_12)

				arg_105_1.isAnimated_ = false
			elseif iter_105_1 ~= arg_105_1.teamNo_ then
				local var_105_13 = arg_105_0.team_[iter_105_1]

				transition.stopTarget(var_105_13)
				transition.moveTo(var_105_13, {
					time = 0.3,
					x = var_105_11,
					y = var_105_12,
					onComplete = function()
						var_105_13.iniCell_.isAnimated_ = false
						var_105_13.isAnimated_ = false
					end
				})
			else
				local var_105_14 = arg_105_0.team_[iter_105_1]

				transition.stopTarget(var_105_14)

				var_105_9.isAnimated_ = true

				transition.moveTo(var_105_14, {
					time = 0.3,
					x = var_105_11,
					y = var_105_12,
					onComplete = function()
						arg_105_1.isAnimated_ = false
						var_105_9.isAnimated_ = false
					end
				})
			end

			arg_105_0.team_[iter_105_1].iniCell_.teamNo_ = iter_105_1
		end

		var_105_1:setVisible(true)
		var_105_2:setVisible(true)
	end

	arg_105_0:updateScore()
	arg_105_0:updateSelectNum()
end

function var_0_0.getTeamNo(arg_110_0, arg_110_1)
	for iter_110_0, iter_110_1 in ipairs(arg_110_0.team_) do
		if arg_110_1.hero:getDistance() < iter_110_1.hero:getDistance() then
			table.insert(arg_110_0.team_, iter_110_0, arg_110_1)
			table.insert(arg_110_0.select_, iter_110_0, arg_110_1.hero)

			return iter_110_0
		end
	end

	table.insert(arg_110_0.team_, arg_110_1)
	table.insert(arg_110_0.select_, arg_110_1.hero)

	return #arg_110_0.team_
end

function var_0_0.initBottomCell(arg_111_0, arg_111_1)
	local var_111_0 = display.newNode()
	local var_111_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")
	local var_111_2 = var_111_1:getChildByName("background"):getContentSize()

	var_111_1:setContentSize(var_111_2)
	var_111_0:setContentSize(var_111_2)
	xyd.setAvatarBorder(arg_111_1, var_111_1:getChildByName("avatar"))

	local var_111_3 = var_111_1:getChildByName("chosen")

	var_111_3:setLocalZOrder(100)
	var_111_3:setVisible(false)

	local var_111_4 = var_111_1:getChildByName("avatar_mask")

	var_111_4:setLocalZOrder(2)
	var_111_4:setVisible(false)

	local var_111_5 = var_111_1:getChildByName("yongbing_tubiao")

	if arg_111_0.leftMenuType_ == var_0_12.RENT_HERO or arg_111_1.type == var_0_12.RENT_HERO or arg_111_1.partner_type == 1 or arg_111_1.partner_type == 5 then
		var_111_5:setVisible(true)

		var_111_0.type = var_0_12.RENT_HERO
	else
		var_111_5:setVisible(false)

		var_111_0.type = var_0_12.SELF_HERO
	end

	if xyd.tables.zhugeHero:zhugeSkill(arg_111_1:getTableID()) ~= 0 and arg_111_1.partner_type ~= 1 and arg_111_1.partner_type ~= 5 then
		local var_111_6 = xyd.AssetLoader.get():loadSprite("windows/zhugeliang/skill_icon.png")

		var_111_6:addTo(var_111_0)
		var_111_6:setAnchorPoint(cc.p(0.5, 0.5))
		var_111_6:setPosition(cc.p(110, 120))
		var_111_6:setLocalZOrder(100)
	end

	for iter_111_0 = 1, 3 do
		var_111_1:getChildByName("team" .. iter_111_0):setVisible(false)
	end

	var_111_1:getChildByName("lv_txt"):setString(arg_111_1:getLevel())

	local var_111_7 = var_111_1:getChildByName("name_text")

	var_111_7:setString(arg_111_1:getName())
	var_111_7:enableOutline(cc.c4b(0, 0, 0, 105), 1)

	if xyd.Color2Level[arg_111_1:getColor()] ~= "" then
		local var_111_8 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_111_7:getX() + var_111_7:getWidth() / 2 - 10,
			y = var_111_7:getY(),
			color = xyd.color.HERO_QUALITY[arg_111_1:getColor()],
			text = xyd.Color2Level[arg_111_1:getColor()]
		}
		local var_111_9 = xyd.AssetLoader.get():loadLabel(var_111_8)

		var_111_9:addTo(var_111_1)
		var_111_9:align(display.CENTER_LEFT)
		var_111_9:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_111_7:x(var_111_7:getX() - 15)
	end

	local var_111_10 = var_111_1:getChildByName("hp_bar")
	local var_111_11 = var_111_1:getChildByName("mp_bar")
	local var_111_12 = var_111_1:getChildByName("dead_text")

	if var_111_12 then
		var_111_12:setVisible(false)
	end

	local var_111_13 = false
	local var_111_14 = arg_111_0.zhugeModel:getHeroStatus(arg_111_1:getTableID())

	if var_111_14 and next(var_111_14) then
		arg_111_0:updateHeroAvatar(var_111_1, var_111_0, arg_111_1, var_111_14)
	else
		var_111_10:hide()
		var_111_11:hide()
		var_111_1:getChildByName("hp_di"):hide()
		var_111_1:getChildByName("mp_di"):hide()

		arg_111_1.isDead = false
	end

	var_111_1:setName("layout")

	var_111_0.hero = arg_111_1

	var_111_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_111_0:addChild(var_111_1)

	return var_111_0
end

function var_0_0.updateScore(arg_112_0)
	arg_112_0:nodeByName("text_bg"):setVisible(false)
end

function var_0_0.clickBottomAvatar(arg_113_0, arg_113_1)
	if arg_113_1.isAnimated_ or arg_113_0.isBattle_ then
		return
	end

	local var_113_0, var_113_1 = arg_113_0:nodeByName("list_layer"):getPosition()
	local var_113_2 = arg_113_1.iniCell_
	local var_113_3

	for iter_113_0, iter_113_1 in ipairs(arg_113_0.select_) do
		if iter_113_1:getTableID() == arg_113_1.hero:getTableID() and iter_113_1.player_name == arg_113_1.hero.player_name then
			var_113_3 = iter_113_0

			break
		end
	end

	if not var_113_3 then
		return
	end

	if not arg_113_1.iniCellVisible_ and arg_113_1.type == arg_113_0.leftMenuType_ and not tolua.isnull(var_113_2) then
		local var_113_4 = var_113_2:convertToWorldSpace(cc.p(0, 0))

		var_113_0, var_113_1 = var_113_4.x + var_113_2:getContentSize().width / 2, var_113_4.y + var_113_2:getContentSize().height / 2

		local var_113_5

		if arg_113_1.type == var_0_12.RENT_HERO then
			var_113_5 = var_113_2:getChildByName("yongbingCell"):getChildByName("container")
		else
			var_113_5 = var_113_2:getChildByName("layout")
		end

		local var_113_6 = var_113_5:getChildByName("avatar_mask")
		local var_113_7 = var_113_5:getChildByName("chosen")

		var_113_6:setVisible(false)
		var_113_7:setVisible(false)
	end

	arg_113_0:moveFadeOutAction(var_113_0, var_113_1, arg_113_1)

	for iter_113_2 = #arg_113_0.team_, var_113_3 + 1, -1 do
		local var_113_8 = arg_113_0.team_[iter_113_2]
		local var_113_9, var_113_10 = arg_113_0:nodeByName("avatar" .. iter_113_2 - 1):getPosition()

		transition.stopTarget(var_113_8)
		transition.moveTo(arg_113_0.team_[iter_113_2], {
			time = 0.3,
			x = var_113_9,
			y = var_113_10
		})

		arg_113_0.team_[iter_113_2].iniCell_.teamNo_ = iter_113_2 - 1
	end

	if arg_113_1.type == var_0_12.RENT_HERO then
		arg_113_0.isSelectMerHero = false
		arg_113_0.selectMerHero = nil
	end

	table.remove(arg_113_0.team_, var_113_3)
	table.remove(arg_113_0.select_, var_113_3)

	var_113_2.teamNo_ = nil

	arg_113_0:updateScore()
	arg_113_0:updateSelectNum()
end

function var_0_0.clickPetBottomAvatar(arg_114_0, arg_114_1, arg_114_2)
	if arg_114_1.isAnimated_ or arg_114_0.isBattle_ then
		return
	end

	local var_114_0, var_114_1 = arg_114_0:nodeByName("list_layer"):getPosition()
	local var_114_2 = arg_114_1.iniCell_
	local var_114_3

	for iter_114_0, iter_114_1 in ipairs(arg_114_0.petSelect_) do
		if iter_114_1:getTableID() == arg_114_1.hero:getTableID() and iter_114_1.player_name == arg_114_1.hero.player_name then
			var_114_3 = iter_114_0

			break
		end
	end

	if not var_114_3 then
		return
	end

	if var_114_2 and not tolua.isnull(var_114_2) then
		local var_114_4 = var_114_2:convertToWorldSpace(cc.p(0, 0))

		var_114_0, var_114_1 = var_114_4.x, var_114_4.y

		local var_114_5

		if arg_114_0.rentMenuType == var_0_13.RENT_PET then
			var_114_5 = var_114_2:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
		else
			var_114_5 = var_114_2:getChildByName("layout")
		end

		local var_114_6 = var_114_5:getChildByName("avatar_mask")
		local var_114_7 = var_114_5:getChildByName("chosen")

		var_114_6:setVisible(false)
		var_114_7:setVisible(false)
	end

	local var_114_8 = "avatar_pet"

	if arg_114_0.selectTeamType ~= xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		var_114_8 = "special_pet"
	end

	arg_114_0:moveFadeOutAction(var_114_0, var_114_1, arg_114_1, arg_114_2)

	for iter_114_2 = #arg_114_0.petTeam_, var_114_3 + 1, -1 do
		local var_114_9 = arg_114_0.petTeam_[iter_114_2]
		local var_114_10, var_114_11 = arg_114_0:nodeByName(var_114_8 .. iter_114_2 - 1):getPosition()

		transition.stopTarget(var_114_9)
		transition.moveTo(arg_114_0.petTeam_[iter_114_2], {
			time = 0.3,
			x = var_114_10,
			y = var_114_11
		})

		arg_114_0.petTeam_[iter_114_2].iniCell_.teamNo_ = iter_114_2 - 1
	end

	if arg_114_1.type == var_0_14.RENT_PET then
		arg_114_0.isSelectMerPet = false
		arg_114_0.selectMerPet = nil
	end

	table.remove(arg_114_0.petTeam_, var_114_3)
	table.remove(arg_114_0.petSelect_, var_114_3)

	if var_114_2 then
		var_114_2.teamNo_ = nil
	end

	arg_114_0:updateScore()
	arg_114_0:updateSelectNum()
end

function var_0_0.clickPetAvatar(arg_115_0, arg_115_1, arg_115_2)
	if arg_115_0.isAnimated_ == true or arg_115_0.isBattle_ then
		return
	elseif arg_115_1.isAnimated_ then
		return
	elseif not arg_115_1.teamNo_ and #arg_115_0.petTeam_ >= arg_115_0.maxPetNum then
		if arg_115_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
			local var_115_0 = arg_115_0.petTeam_[1]

			arg_115_0:clickPetBottomAvatarWithoutAnimation(var_115_0, function()
				arg_115_0:clickPetAvatar(arg_115_1, arg_115_2)
			end)
		end

		return
	end

	arg_115_0.isAnimated_ = true

	local var_115_1

	if arg_115_0.rentMenuType == var_0_13.RENT_PET then
		var_115_1 = arg_115_1:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
	else
		var_115_1 = arg_115_1:getChildByName("layout")
	end

	local var_115_2 = var_115_1:getChildByName("avatar_mask")
	local var_115_3 = var_115_1:getChildByName("chosen")
	local var_115_4 = "avatar_pet"

	if arg_115_0.selectTeamType ~= xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		var_115_4 = "special_pet"
	end

	local var_115_5 = arg_115_1:convertToWorldSpace(cc.p(0, 0))
	local var_115_6 = var_115_5.x
	local var_115_7 = var_115_5.y

	arg_115_1.isAnimated_ = true

	if arg_115_1.teamNo_ then
		local var_115_8 = arg_115_0.petTeam_[arg_115_1.teamNo_]

		arg_115_0:moveFadeOutAction(var_115_6, var_115_7, var_115_8, function()
			arg_115_1.isAnimated_ = false
		end)
		var_115_2:setVisible(false)
		var_115_3:setVisible(false)

		for iter_115_0 = #arg_115_0.petTeam_, arg_115_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_115_0.petTeam_[iter_115_0])

			local var_115_9, var_115_10 = arg_115_0:nodeByName(var_115_4 .. iter_115_0 - 1):getPosition()

			transition.moveTo(arg_115_0.petTeam_[iter_115_0], {
				time = 0.3,
				x = var_115_9,
				y = var_115_10
			})

			arg_115_0.petTeam_[iter_115_0].iniCell_.teamNo_ = iter_115_0 - 1
		end

		if arg_115_1.type == var_0_14.RENT_PET then
			arg_115_0.isSelectMerPet = false
			arg_115_0.selectMerPet = nil
		end

		table.remove(arg_115_0.petTeam_, arg_115_1.teamNo_)
		table.remove(arg_115_0.petSelect_, arg_115_1.teamNo_)

		arg_115_1.teamNo_ = nil
		arg_115_0.isAnimated_ = false
	elseif not arg_115_1.teamNo_ and #arg_115_0.petTeam_ < arg_115_0.maxPetNum then
		local var_115_11 = arg_115_1.hero
		local var_115_12 = arg_115_0:initPetBottomCell(var_115_11)

		var_115_12.iniCell_ = arg_115_1

		var_115_12:pos(var_115_6, var_115_7)

		if arg_115_0.selectTeamType == xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
			var_115_12:addTo(arg_115_0)
		else
			var_115_12:addTo(arg_115_0:nodeByName("bottom_bg_3"))
		end

		var_115_12:setTouchEnabled(true)
		var_115_12:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_118_0)
			if arg_118_0.name == "ended" then
				arg_115_0:clickPetBottomAvatar(var_115_12)
			end

			return true
		end)

		arg_115_1.teamNo_ = arg_115_0:getPetTeamNo(var_115_12)

		for iter_115_1 = arg_115_1.teamNo_, #arg_115_0.petTeam_ do
			local var_115_13, var_115_14 = arg_115_0:nodeByName(var_115_4 .. iter_115_1):getPosition()

			if arg_115_2 then
				arg_115_0.petTeam_[iter_115_1]:pos(var_115_13, var_115_14)

				arg_115_1.isAnimated_ = false
			elseif iter_115_1 ~= arg_115_1.teamNo_ then
				local var_115_15 = arg_115_0.petTeam_[iter_115_1]

				transition.stopTarget(var_115_15)
				transition.moveTo(var_115_15, {
					time = 0.3,
					x = var_115_13,
					y = var_115_14,
					onComplete = function()
						var_115_15.iniCell_.isAnimated_ = false
						var_115_15.isAnimated_ = false
					end
				})
			else
				local var_115_16 = arg_115_0.petTeam_[iter_115_1]

				transition.stopTarget(var_115_16)

				var_115_12.isAnimated_ = true

				transition.moveTo(var_115_16, {
					time = 0.3,
					x = var_115_13,
					y = var_115_14,
					onComplete = function()
						arg_115_1.isAnimated_ = false
						var_115_12.isAnimated_ = false
					end
				})
			end

			arg_115_0.petTeam_[iter_115_1].iniCell_.teamNo_ = iter_115_1
		end

		var_115_2:setVisible(true)
		var_115_3:setVisible(true)

		arg_115_0.isAnimated_ = false
	end

	arg_115_0:updateScore()
	arg_115_0:updateSelectNum()
end

function var_0_0.initPetBottomCell(arg_121_0, arg_121_1)
	local var_121_0 = display.newNode()

	var_121_0:size(146, 146)
	var_121_0:align(display.CENTER)

	var_121_0.hero = arg_121_1
	var_121_0.type = var_0_14.SELF_PET

	xyd.setPetAvatar(var_121_0, arg_121_1, 100)

	if arg_121_0.rentMenuType == var_0_13.RENT_PET or arg_121_1.partner_type == 3 then
		local var_121_1 = xyd.AssetLoader.get():loadSprite("windows/zhugeliang/yongbing_tubiao.png")

		var_121_1:addTo(var_121_0)
		var_121_1:setAnchorPoint(cc.p(0.5, 0.5))
		var_121_1:setPosition(cc.p(110, 120))

		var_121_0.type = var_0_14.RENT_PET
	end

	return var_121_0
end

function var_0_0.getPetTeamNo(arg_122_0, arg_122_1)
	table.insert(arg_122_0.petTeam_, arg_122_1)
	table.insert(arg_122_0.petSelect_, arg_122_1.hero)

	return #arg_122_0.petTeam_
end

function var_0_0.clickPetBottomAvatarWithoutAnimation(arg_123_0, arg_123_1, arg_123_2)
	if arg_123_1.isAnimated_ then
		return
	end

	local var_123_0, var_123_1 = arg_123_0:nodeByName("list_layer"):getPosition()
	local var_123_2 = arg_123_1.iniCell_
	local var_123_3

	for iter_123_0, iter_123_1 in ipairs(arg_123_0.petTeam_) do
		if iter_123_1 == arg_123_1 then
			var_123_3 = iter_123_0

			break
		end
	end

	if not var_123_3 then
		return
	end

	if var_123_2 and not tolua.isnull(var_123_2) then
		local var_123_4 = var_123_2:convertToWorldSpace(cc.p(0, 0))
		local var_123_5

		if arg_123_0.rentMenuType == var_0_13.RENT_PET then
			var_123_5 = var_123_2:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
		else
			var_123_5 = var_123_2:getChildByName("layout")
		end

		local var_123_6 = var_123_5:getChildByName("avatar_mask")
		local var_123_7 = var_123_5:getChildByName("chosen")

		var_123_6:setVisible(false)
		var_123_7:setVisible(false)
	end

	local var_123_8 = "avatar_pet"

	if arg_123_0.selectTeamType ~= xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM then
		var_123_8 = "special_pet"
	end

	for iter_123_2 = #arg_123_0.petTeam_, var_123_3 + 1, -1 do
		local var_123_9 = arg_123_0.petTeam_[iter_123_2]
		local var_123_10, var_123_11 = arg_123_0:nodeByName(var_123_8 .. iter_123_2 - 1):getPosition()

		transition.stopTarget(var_123_9)
		transition.moveTo(arg_123_0.petTeam_[iter_123_2], {
			time = 0.3,
			x = var_123_10,
			y = var_123_11
		})

		arg_123_0.petTeam_[iter_123_2].iniCell_.teamNo_ = iter_123_2 - 1
	end

	if arg_123_1.type == var_0_14.RENT_PET then
		arg_123_0.isSelectMerPet = false
		arg_123_0.selectMerPet = nil
	end

	table.remove(arg_123_0.petTeam_, var_123_3)
	table.remove(arg_123_0.petSelect_, var_123_3)

	if var_123_2 then
		var_123_2.teamNo_ = nil
	end

	if arg_123_1 and not tolua.isnull(arg_123_1) then
		arg_123_1:removeSelf()
	end

	if arg_123_2 then
		arg_123_2()
	end
end

function var_0_0.initRentPets(arg_124_0, arg_124_1)
	if not arg_124_0.isLoadAllTeamPets then
		local var_124_0 = arg_124_0:getRentPets()

		arg_124_0:initPets(var_124_0, var_0_14.RENT_PET)

		arg_124_0.isLoadAllTeamPets = true

		if arg_124_1 then
			arg_124_1()
		end
	elseif arg_124_1 then
		arg_124_1()
	end
end

function var_0_0.showSkillDetail(arg_125_0, arg_125_1, arg_125_2, arg_125_3)
	if not arg_125_1 then
		if arg_125_0.skillDetail and not tolua.isnull(arg_125_0.skillDetail) then
			arg_125_0.skillDetail:setVisible(false)
		end

		return
	end

	if not arg_125_0.skillDetail then
		local var_125_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/select_team/adventure_skill.csb")

		var_125_0:addTo(arg_125_0)

		arg_125_0.skillDetail = var_125_0
	end

	local var_125_1 = arg_125_0.skillDetail:getChildByName("container")
	local var_125_2 = var_125_1:getContentSize()

	arg_125_0.skillDetail:setPosition(cc.p(arg_125_2.x, arg_125_2.y - var_125_2.height / 2))
	var_125_1:getChildByName("text_name"):setString(arg_125_3:getName())
	var_125_1:getChildByName("text_lev"):setString("lv." .. arg_125_3:getLevel())
	var_125_1:getChildByName("text_hero_tips"):setString(arg_125_3:getDes())

	local var_125_3 = arg_125_3:getTableID()
	local var_125_4 = xyd.tables.zhugeHero:zhugeSkill(var_125_3)
	local var_125_5 = xyd.tables.zhugeSkill:name(var_125_4)
	local var_125_6 = arg_125_0:getSkillDesc(var_125_4)

	var_125_1:getChildByName("text_skill"):setString(var_125_5)
	var_125_1:getChildByName("text_skill__desc"):setString(var_125_6)
	xyd.setAvatarBorder(arg_125_3, var_125_1:getChildByName("hero"))
	arg_125_0.skillDetail:setVisible(true)
end

function var_0_0.getSkillDesc(arg_126_0, arg_126_1)
	local var_126_0 = xyd.tables.zhugeSkill:desc(arg_126_1)
	local var_126_1 = xyd.tables.zhugeSkill:type(arg_126_1)
	local var_126_2 = xyd.tables.zhugeSkill:num(arg_126_1)[1]

	return (string.format(var_126_0, var_126_2))
end

function var_0_0.playReport(arg_127_0, arg_127_1)
	if arg_127_1 == nil then
		return
	end

	if not arg_127_0 or tolua.isnull(arg_127_0) then
		return
	end

	local var_127_0 = {}
	local var_127_1 = json.decode(arg_127_1)

	var_127_0.herosA = {}
	var_127_0.herosB = {}
	var_127_0.summonMonsters = {}
	var_127_0.campaignType = xyd.CampaignType.ZHUGE_ENEMY
	var_127_0.battleID = xyd.MapBattleID.ZHUGE_ENEMY
	var_127_0.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_127_1

	local var_127_2 = {}
	local var_127_3 = {}

	for iter_127_0, iter_127_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_127_4 = string.sub(iter_127_0, 1, 1)
		local var_127_5 = tonumber(string.sub(iter_127_0, 3, 3))

		if var_127_4 == "A" and tonumber(iter_127_1.summon_type) == xyd.summonMonsterType.None then
			local var_127_6 = var_0_1.new()

			var_127_6:populate(iter_127_1.hero)
			var_127_6:setReportData(iter_127_1)

			var_127_6.healthStatus = arg_127_0.zhugeModel:getOldHeroStatus(var_127_6:getTableID())

			if isOnlyData then
				var_127_6.harms = iter_127_1.harms
				var_127_6.willDie = (iter_127_1.die_count or 0) ~= -1
			end

			var_127_0.herosA[var_127_5] = var_127_6
		elseif var_127_4 == "A" and tonumber(iter_127_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_127_7 = var_0_2.new()

			var_127_7:populate(iter_127_1.hero)
			var_127_7:setReportData(iter_127_1)

			if isOnlyData then
				var_127_7.harms = iter_127_1.harms
				var_127_7.willDie = (iter_127_1.die_count or 0) ~= -1
				var_127_0.petA = {
					var_127_7
				}
			else
				var_127_0.petsA = {
					var_127_7
				}
			end
		elseif var_127_4 == "B" and tonumber(iter_127_1.summon_type) == xyd.summonMonsterType.None then
			local var_127_8 = var_0_1.new()

			var_127_8:populate(iter_127_1.hero)
			var_127_8:setReportData(iter_127_1)

			if isOnlyData then
				var_127_8.harms = iter_127_1.harms
				var_127_8.willDie = (iter_127_1.die_count or 0) ~= -1
				var_127_0.herosB[var_127_5] = var_127_8
			else
				var_127_2[var_127_5] = var_127_8
			end
		elseif var_127_4 == "B" and tonumber(iter_127_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_127_9 = var_0_2.new()

			var_127_9:populate(iter_127_1.hero)
			var_127_9:setReportData(iter_127_1)

			if isOnlyData then
				var_127_9.harms = iter_127_1.harms
				var_127_9.willDie = (iter_127_1.die_count or 0) ~= -1
				var_127_0.petB = {
					var_127_9
				}
			else
				var_127_0.petsB = {
					var_127_9
				}
			end
		elseif var_127_4 == "C" then
			local var_127_10 = var_0_1.new()

			var_127_10:populate(iter_127_1.hero)
			var_127_10:setReportData(iter_127_1)

			if not isOnlyData then
				sceneFighter = var_127_10
			end
		elseif tonumber(iter_127_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_127_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_127_11 = var_0_1.new()

			var_127_11:populate(iter_127_1.hero)
			var_127_11:setReportData(iter_127_1)

			var_127_3[iter_127_0] = var_127_11
		end
	end

	var_127_0.herosB = {
		var_127_2
	}
	var_127_0.sceneFighter = sceneFighter
	var_127_0.summonMonsters = var_127_3
	var_127_0.reportStar = tonumber(var_127_1.star)

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "zhuge_new_adventure"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_127_0)
end

return var_0_0
