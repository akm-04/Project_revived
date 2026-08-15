local var_0_0 = class("OccultSelectHeroWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = 7
local var_0_3 = 30
local var_0_4 = 6
local var_0_5 = 1
local var_0_6 = xyd.tables.heroTable
local var_0_7 = xyd.tables.translation
local var_0_8 = {
	PET = 2,
	HERO = 1
}
local var_0_9 = {
	YES = 2,
	NO = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.occult = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)
	arg_1_0.tmpHeros_ = {}
	arg_1_0.totalHero_ = {}
	arg_1_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_1_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.FILTER] = {}

	for iter_1_0, iter_1_1 in pairs(arg_1_0.totalHero_) do
		iter_1_1[var_0_9.NO] = {}
		iter_1_1[var_0_9.YES] = {}
	end

	arg_1_0.tmpTotalPets = {}
	arg_1_0.totalPet_ = {}
	arg_1_0.leftMenuType = var_0_8.HERO
	arg_1_0.isPet = arg_1_2.isPet
	arg_1_0.index = arg_1_2.index
	arg_1_0.collocationType_ = var_0_9.NO
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.playerInfo = arg_2_0.occult:getPlayerInfoByID(arg_2_0.selfPlayer.playerID)

	if arg_2_0.isPet then
		arg_2_0.leftMenuType = var_0_8.PET

		arg_2_0:initPetInfos()
	else
		arg_2_0.leftMenuType = var_0_8.HERO

		arg_2_0:initHeroInfos()
	end

	arg_2_0:layout()
end

function var_0_0.initPetInfos(arg_3_0)
	local var_3_0 = arg_3_0.selfPlayer.collectedPets
	local var_3_1 = {}

	for iter_3_0, iter_3_1 in ipairs(var_3_0) do
		if iter_3_1.is_show_ == 1 and arg_3_0:canPetJoinBattle(iter_3_1) then
			table.insert(var_3_1, iter_3_1)
		end
	end

	arg_3_0:sortPets(var_3_1)

	arg_3_0.totalPet_ = var_3_1
end

function var_0_0.initHeroInfos(arg_4_0)
	arg_4_0.heros_ = arg_4_0:getHeros()

	arg_4_0:sortHeros(arg_4_0.heros_)

	for iter_4_0, iter_4_1 in pairs(arg_4_0.heros_) do
		if iter_4_1:getDistanceType() == xyd.DistanceType.QIANPAI then
			table.insert(arg_4_0.totalHero_[xyd.DistanceType.QIANPAI][var_0_9.NO], iter_4_1)

			if iter_4_1:isCollocation() then
				table.insert(arg_4_0.totalHero_[xyd.DistanceType.QIANPAI][var_0_9.YES], iter_4_1)
			end
		elseif iter_4_1:getDistanceType() == xyd.DistanceType.ZHONGPAI then
			table.insert(arg_4_0.totalHero_[xyd.DistanceType.ZHONGPAI][var_0_9.NO], iter_4_1)

			if iter_4_1:isCollocation() then
				table.insert(arg_4_0.totalHero_[xyd.DistanceType.ZHONGPAI][var_0_9.YES], iter_4_1)
			end
		elseif iter_4_1:getDistanceType() == xyd.DistanceType.HOUPAI then
			table.insert(arg_4_0.totalHero_[xyd.DistanceType.HOUPAI][var_0_9.NO], iter_4_1)

			if iter_4_1:isCollocation() then
				table.insert(arg_4_0.totalHero_[xyd.DistanceType.HOUPAI][var_0_9.YES], iter_4_1)
			end
		end

		table.insert(arg_4_0.totalHero_[xyd.DistanceType.ALL][var_0_9.NO], iter_4_1)

		if iter_4_1:isCollocation() then
			table.insert(arg_4_0.totalHero_[xyd.DistanceType.ALL][var_0_9.YES], iter_4_1)
		end
	end

	arg_4_0.totalDispatchNum = arg_4_0:getDispathHerosNum(arg_4_0.heros_)

	arg_4_0:updateFilterHeros()

	arg_4_0.tmpHeros_ = arg_4_0.totalHero_[xyd.DistanceType.ALL][arg_4_0.collocationType_]
end

function var_0_0.getHeros(arg_5_0)
	return clone(arg_5_0.selfPlayer.heros_)
end

function var_0_0.canHeroJoinBattle(arg_6_0, arg_6_1)
	return true
end

function var_0_0.canPetJoinBattle(arg_7_0)
	return true
end

function var_0_0.sortHeros(arg_8_0, arg_8_1)
	table.sort(arg_8_1, function(arg_9_0, arg_9_1)
		if arg_8_0:isDispatchHero(arg_9_0) ~= arg_8_0:isDispatchHero(arg_9_1) then
			return arg_8_0:isDispatchHero(arg_9_0) > arg_8_0:isDispatchHero(arg_9_1)
		end

		return xyd.heroNormalSort(arg_9_0, arg_9_1) or false
	end)
end

function var_0_0.sortPets(arg_10_0, arg_10_1)
	table.sort(arg_10_1, function(arg_11_0, arg_11_1)
		return xyd.petNormalSort(arg_11_0, arg_11_1) or false
	end)
end

function var_0_0.isDispatchHero(arg_12_0, arg_12_1)
	if xyd.isInTable(table.keys(arg_12_0.occult.dispatchInfo or {}), tostring(arg_12_1:getHeroID())) then
		if arg_12_0.occult.dispatchInfo[tostring(arg_12_1:getHeroID())].hp <= 0 then
			return 1
		end

		return 2
	end

	return 0
end

function var_0_0.layout(arg_13_0)
	arg_13_0:nodeByName("txt_qianpai"):setString(var_0_7:translation("HERO_QIANPAI"))
	arg_13_0:nodeByName("txt_zhongpai"):setString(var_0_7:translation("HERO_ZHONGPAI"))
	arg_13_0:nodeByName("txt_houpai"):setString(var_0_7:translation("HERO_HOUPAI"))
	arg_13_0:nodeByName("txt_all"):setString(var_0_7:translation("PERSON_SELECT_ALL"))
	arg_13_0:nodeByName("txt_hero"):setString(var_0_7:translation("PERSON_SELECT_HERO"))
	arg_13_0:nodeByName("txt_pet"):setString(var_0_7:translation("PERSON_SELECT_PET"))
	arg_13_0:initMenu()

	if arg_13_0.isPet then
		arg_13_0:nodeByName("txt_title"):setString(var_0_7:translation("PERSON_SELECT_PET"))
	else
		arg_13_0:nodeByName("txt_title"):setString(var_0_7:translation("PERSON_SELECT_HERO"))
	end

	local var_13_0 = arg_13_0:nodeByName("hero_list")
	local var_13_1 = var_13_0:getContentSize()

	arg_13_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_13_1.width, var_13_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_13_0):onScroll(handler(arg_13_0, arg_13_0.scrollListener))

	arg_13_0.heroList_:setDelegate(handler(arg_13_0, arg_13_0.delegate))

	if arg_13_0.isPet then
		arg_13_0:nodeByName("btn_hero"):setVisible(false)

		local var_13_2 = cc.p(arg_13_0:nodeByName("btn_hero"):getPosition())

		arg_13_0:nodeByName("btn_pet"):setPosition(cc.p(var_13_2))
		arg_13_0:nodeByName("btn_pet"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_13_0:nodeByName("btn_pet"):setTouchEnabled(false)
		arg_13_0:nodeByName("quanbu_button"):setVisible(false)
		arg_13_0:nodeByName("qianpai_button"):setVisible(false)
		arg_13_0:nodeByName("zhongpai_button"):setVisible(false)
		arg_13_0:nodeByName("houpai_button"):setVisible(false)
	else
		arg_13_0:nodeByName("btn_pet"):setVisible(false)
		arg_13_0:nodeByName("btn_hero"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_13_0:nodeByName("btn_hero"):setTouchEnabled(false)
	end

	var_0_1.new({
		size = 888,
		type = xyd.SplitlineType.SOLID
	}):addTo(arg_13_0:nodeByName("pos_line"))
end

function var_0_0.initMenu(arg_14_0)
	arg_14_0:nodeByName("quanbu_button"):setBrightStyle(ccui.BrightStyle.highlight)

	arg_14_0.heroClassButtons_ = {}

	local var_14_0 = arg_14_0:nodeByName("container")

	table.insert(arg_14_0.heroClassButtons_, arg_14_0:nodeByName("quanbu_button"))
	table.insert(arg_14_0.heroClassButtons_, arg_14_0:nodeByName("qianpai_button"))
	table.insert(arg_14_0.heroClassButtons_, arg_14_0:nodeByName("zhongpai_button"))
	table.insert(arg_14_0.heroClassButtons_, arg_14_0:nodeByName("houpai_button"))
	table.insert(arg_14_0.heroClassButtons_, arg_14_0:nodeByName("button_filter"))
	table.insert(arg_14_0.heroClassButtons_, arg_14_0:nodeByName("button_search"))

	for iter_14_0 = 1, #arg_14_0.heroClassButtons_ do
		arg_14_0.heroClassButtons_[iter_14_0]:setZoomScale(0.3)
		arg_14_0.heroClassButtons_[iter_14_0]:addTouchEventListener(function(arg_15_0, arg_15_1)
			for iter_15_0 = 1, #arg_14_0.heroClassButtons_ do
				if iter_15_0 == iter_14_0 then
					arg_14_0.heroClassButtons_[iter_15_0]:setBrightStyle(ccui.BrightStyle.highlight)
				else
					arg_14_0.heroClassButtons_[iter_15_0]:setBrightStyle(ccui.BrightStyle.normal)
				end
			end

			if arg_15_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()
				arg_14_0:refreshSelectedHeroClass(iter_14_0)
			end
		end)
	end

	arg_14_0:nodeByName("text_filter"):setString(var_0_7:translation("FILTER_TEXT"))
	arg_14_0:nodeByName("button_filter"):addTouchEventListener(function(arg_16_0, arg_16_1)
		xyd.buttonScaleAnim(arg_16_0, arg_16_1)

		if arg_16_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("hero_filter_wnd")
		end
	end)
	arg_14_0:nodeByName("button_search"):addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(arg_17_0, arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("hero_search_wnd")
		end
	end)
	arg_14_0:nodeByName("button_collocation"):addTouchEventListener(function(arg_18_0, arg_18_1)
		xyd.buttonScaleAnim(arg_18_0, arg_18_1)

		if arg_18_1 == ccui.TouchEventType.ended then
			arg_14_0.collocationType_ = 3 - arg_14_0.collocationType_

			arg_14_0:refreshSelectedHeroClass()
		end
	end)
end

function var_0_0.refreshSelectedHeroClass(arg_19_0, arg_19_1)
	arg_19_0.heroList_:removeAllItems()

	if arg_19_1 then
		arg_19_0.selectHeroClass_ = arg_19_1
		arg_19_0.tmpHeros_ = arg_19_0.totalHero_[arg_19_1][arg_19_0.collocationType_]
	else
		arg_19_0.tmpHeros_ = arg_19_0.totalHero_[arg_19_0.selectHeroClass_][arg_19_0.collocationType_]
	end

	for iter_19_0 = 1, #arg_19_0.heroClassButtons_ do
		if arg_19_0.selectHeroClass_ == iter_19_0 then
			arg_19_0.heroClassButtons_[iter_19_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_19_0.heroClassButtons_[iter_19_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_19_0.heroList_:reload()
end

function var_0_0.scrollListener(arg_20_0, arg_20_1)
	if arg_20_1.name == "began" then
		arg_20_0.scrollViewMoved_ = false
		arg_20_0.prevY_ = arg_20_1.y
	elseif arg_20_1.name == "moved" and 10 <= math.abs(arg_20_1.y - arg_20_0.prevY_) then
		arg_20_0.scrollViewMoved_ = true
	end
end

function var_0_0.delegate(arg_21_0, ...)
	if arg_21_0.leftMenuType == var_0_8.PET then
		return arg_21_0:petDelegate(...)
	end

	return arg_21_0:heroDelegate(...)
end

function var_0_0.heroDelegate(arg_22_0, arg_22_1, arg_22_2, arg_22_3)
	arg_22_0.dispatchNum = arg_22_0:getDispathHerosNum(arg_22_0.tmpHeros_)
	arg_22_0.totalNum = #arg_22_0.tmpHeros_

	local var_22_0 = math.ceil(arg_22_0.dispatchNum / var_0_2) + math.ceil((arg_22_0.totalNum - arg_22_0.dispatchNum) / var_0_2) + 2

	if cc.ui.UIListView.COUNT_TAG == arg_22_2 then
		return var_22_0
	elseif cc.ui.UIListView.CELL_TAG == arg_22_2 then
		local var_22_1
		local var_22_2 = arg_22_0.heroList_:dequeueItem()

		if not var_22_2 then
			var_22_2 = arg_22_0.heroList_:newItem()
		else
			var_22_2:removeAllChildren(true)
		end

		local var_22_3

		if arg_22_3 == 1 or arg_22_3 == math.ceil(arg_22_0.dispatchNum / var_0_2) + 2 then
			var_22_3 = arg_22_0:createTitleContent(arg_22_3)
		else
			var_22_3 = arg_22_0:createListContent(arg_22_3)
		end

		var_22_2:setItemSize(arg_22_0.heroList_.viewRect_.width, var_22_3:getContentSize().height)
		var_22_2:addContent(var_22_3)

		return var_22_2
	end
end

function var_0_0.createTitleContent(arg_23_0, arg_23_1)
	local var_23_0 = display.newNode()
	local var_23_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/occult/select_team/title.csb")
	local var_23_2 = var_23_1:getChildByName("container")
	local var_23_3 = string.format(var_0_7:translation("OCCULT_DISPATCH_HERO_TEXT"), arg_23_0.totalDispatchNum, arg_23_0.occult.baseInfo.dispatch_limit or xyd.tables.misc.creatsDispatchHeroLimit)

	if arg_23_1 > 1 then
		var_23_3 = var_0_7:translation("OCCULT_UNDISPATCH_HERO_TEXT")
	end

	var_23_2:getChildByName("text"):setString(var_23_3)
	var_23_1:addTo(var_23_0)
	var_23_1:setAnchorPoint(cc.p(0, 0))
	var_23_0:setContentSize(var_23_2:getContentSize())
	var_23_1:setName("source")

	return var_23_0
end

function var_0_0.createListContent(arg_24_0, arg_24_1)
	local var_24_0 = display.newNode()

	var_24_0:setTouchSwallowEnabled(false)

	local var_24_1
	local var_24_2 = math.ceil(arg_24_0.dispatchNum / var_0_2) + 3

	for iter_24_0 = 1, var_0_2 do
		if (arg_24_1 - 2) * var_0_2 + iter_24_0 <= arg_24_0.dispatchNum then
			local var_24_3 = (arg_24_1 - 2) * var_0_2 + iter_24_0

			var_24_1 = arg_24_0:initHeroCell(var_24_3)

			local var_24_4 = var_24_1:getContentSize().width
			local var_24_5 = var_24_1:getContentSize().height
			local var_24_6 = (arg_24_0.heroList_.viewRect_.width - var_24_4 * var_0_2) / (var_0_2 + 1)

			var_24_1:pos(var_24_6 * iter_24_0 + (iter_24_0 - 1) * var_24_4 + var_24_4 / 2, var_0_3 + var_24_5 / 2 - 2)
			var_24_0:addChild(var_24_1)
		elseif var_24_2 <= arg_24_1 and (arg_24_1 - var_24_2) * var_0_2 + iter_24_0 + arg_24_0.dispatchNum <= arg_24_0.totalNum then
			local var_24_7 = (arg_24_1 - var_24_2) * var_0_2 + iter_24_0 + arg_24_0.dispatchNum

			var_24_1 = arg_24_0:initHeroCell(var_24_7)

			local var_24_8 = var_24_1:getContentSize().width
			local var_24_9 = var_24_1:getContentSize().height
			local var_24_10 = (arg_24_0.heroList_.viewRect_.width - var_24_8 * var_0_2) / (var_0_2 + 1)

			var_24_1:pos(var_24_10 * iter_24_0 + (iter_24_0 - 1) * var_24_8 + var_24_8 / 2, var_0_3 + var_24_9 / 2 - 2)
			var_24_0:addChild(var_24_1)
		end
	end

	var_24_0:setContentSize(cc.size(arg_24_0.heroList_.viewRect_.width, var_24_1:getContentSize().height + var_0_3))

	return var_24_0
end

function var_0_0.initHeroCell(arg_25_0, arg_25_1)
	local var_25_0 = display.newNode()
	local var_25_1 = arg_25_0.tmpHeros_[arg_25_1]

	var_25_1.healthStatus = nil

	local var_25_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/hero_avatar_new.csb")

	var_25_2:getChildByName("yongbing_tubiao"):setVisible(false)

	local var_25_3 = var_25_2:getChildByName("background"):getContentSize()

	var_25_2:setContentSize(var_25_3)
	var_25_0:setContentSize(var_25_3)
	xyd.setAvatarBorderNewUI(var_25_1, var_25_2:getChildByName("avatar"))

	local var_25_4 = var_25_2:getChildByName("chosen")

	var_25_4:setLocalZOrder(100)
	var_25_4:setVisible(false)

	local var_25_5 = var_25_2:getChildByName("avatar_mask")

	var_25_5:setLocalZOrder(2)
	var_25_5:setVisible(false)

	var_25_0.type = var_0_8.HERO

	var_25_2:getChildByName("is_can_rent"):setVisible(false)

	for iter_25_0 = 1, 3 do
		var_25_2:getChildByName("team" .. iter_25_0):setVisible(false)
	end

	local var_25_6 = var_25_2:getChildByName("lv_txt")

	var_25_6:setString(var_25_1:getLevel())
	var_25_6:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	var_25_2:getChildByName("name_text"):setString(var_25_1:getName())

	local var_25_7 = var_25_2:getChildByName("hp_bar")
	local var_25_8 = var_25_2:getChildByName("mp_bar")
	local var_25_9 = var_25_2:getChildByName("dead_text")

	var_25_9:setString(var_0_7:translation("ALREADY_DEAD"))

	if var_25_9 then
		var_25_9:setVisible(false)
	end

	local var_25_10 = false
	local var_25_11 = arg_25_0.occult.dispatchInfo

	if var_25_11 and next(var_25_11) ~= nil and arg_25_0:isDispatchHero(var_25_1) > 0 then
		local var_25_12 = var_25_11[tostring(var_25_1:getHeroID())]

		var_25_1.healthStatus = var_25_12

		if var_25_12 and not var_25_12.total_hp then
			var_25_12.total_hp = 10000
		end

		local var_25_13 = 0
		local var_25_14 = 0

		if var_25_12 and var_25_12.hp > 0 and var_25_12.total_hp > 0 then
			var_25_13 = var_25_12.hp * 100 / var_25_12.total_hp
			var_25_14 = var_25_12.mp * 100 / xyd.ENERGY_DECIMAL_BASE
		elseif var_25_12 and var_25_12.hp == 0 then
			var_25_13 = 0
			var_25_14 = 0

			var_25_5:setVisible(true)
			var_25_9:setLocalZOrder(3)
			var_25_9:setVisible(true)
			var_25_9:enableOutline(cc.c4b(0, 0, 0), 2)
			var_25_9:getVirtualRenderer():setAdditionalKerning(2)

			var_25_10 = true
		end

		var_25_7:setPercent(var_25_13)
		var_25_7:setVisible(true)
		var_25_8:setPercent(var_25_14)
		var_25_8:setVisible(true)
	else
		var_25_7:hide()
		var_25_8:hide()
		var_25_2:getChildByName("hp_di"):hide()
		var_25_2:getChildByName("mp_di"):hide()
	end

	var_25_2:setName("layout")
	var_25_2:setPosition(cc.p(0, 0))

	var_25_0.data = var_25_1
	var_25_1.isDead = var_25_10

	var_25_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_25_0:addChild(var_25_2)
	var_25_0:setTouchSwallowEnabled(false)
	var_25_0:setTouchEnabled(true)
	var_25_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_26_0)
		if arg_26_0.name == "began" then
			arg_25_0.startClick_ = true
			arg_25_0.prevX_ = arg_26_0.x
			arg_25_0.prevY_ = arg_26_0.y
		elseif arg_26_0.name == "moved" then
			if math.abs(arg_26_0.y - arg_25_0.prevY_) > 5 or math.abs(arg_26_0.x - arg_25_0.prevX_) > 5 then
				arg_25_0.startClick_ = false
			end
		elseif arg_26_0.name == "ended" and arg_25_0.startClick_ then
			if var_25_10 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_7:translation("HERO_DIE_ERROR")
				})

				return
			end

			arg_25_0:clickAvatar(var_25_0.data)
		end

		return true
	end)

	if arg_25_0:checkCanSelect(var_25_1) then
		var_25_5:setVisible(false)
		var_25_4:setVisible(false)
	else
		var_25_5:setVisible(true)
		var_25_4:setVisible(true)

		if not var_25_1.isDead then
			local var_25_15 = xyd.AssetLoader.get():loadSprite("windows/illusion/cooperation/word_18.png")

			var_25_15:setPosition(55, 105)
			var_25_2:addChild(var_25_15, 11)
			var_25_0:setTouchEnabled(false)
		end
	end

	return var_25_0
end

function var_0_0.getDispathHerosNum(arg_27_0, arg_27_1)
	local var_27_0 = 0

	for iter_27_0 = 1, #arg_27_1 do
		if arg_27_0:isDispatchHero(arg_27_1[iter_27_0]) > 0 then
			var_27_0 = var_27_0 + 1
		else
			return var_27_0
		end
	end

	return var_27_0
end

function var_0_0.petDelegate(arg_28_0, arg_28_1, arg_28_2, arg_28_3)
	local var_28_0 = math.ceil(#arg_28_0.totalPet_ / var_0_4)

	if cc.ui.UIListView.COUNT_TAG == arg_28_2 then
		return var_28_0
	elseif cc.ui.UIListView.CELL_TAG == arg_28_2 then
		local var_28_1
		local var_28_2
		local var_28_3
		local var_28_4 = arg_28_0.heroList_:dequeueItem()

		if not var_28_4 then
			var_28_4 = arg_28_0.heroList_:newItem()
		else
			var_28_4:removeAllChildren()
		end

		local var_28_5 = display.newNode()

		var_28_5:setTouchSwallowEnabled(false)

		for iter_28_0 = 1, var_0_4 do
			local var_28_6 = (arg_28_3 - 1) * var_0_4 + iter_28_0

			if var_28_6 > #arg_28_0.totalPet_ then
				break
			end

			var_28_3 = display.newNode()

			arg_28_0:initPetCell(var_28_3, var_28_6)

			local var_28_7 = var_28_3:getContentSize().width + 35
			local var_28_8 = var_28_3:getContentSize().height + 35
			local var_28_9 = (arg_28_0.heroList_.viewRect_.width - var_28_7 * var_0_4) / (var_0_4 + 1)

			var_28_3:align(display.CENTER, var_28_9 * iter_28_0 + (iter_28_0 - 1) * var_28_7 + var_28_7 / 2, var_28_8 / 2)
			var_28_5:addChild(var_28_3)
		end

		var_28_5:setContentSize(cc.size(arg_28_0.heroList_.viewRect_.width, var_28_3:getContentSize().height + 5))
		var_28_4:setItemSize(arg_28_0.heroList_.viewRect_.width, var_28_3:getContentSize().height + 50)
		var_28_4:addContent(var_28_5)

		return var_28_4
	end
end

function var_0_0.initPetCell(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = arg_29_0.totalPet_[arg_29_2]
	local var_29_1 = false

	arg_29_1:align(display.CENTER):size(105, 105)
	xyd.setPetAvatarNewUI(arg_29_1, var_29_0, 100)

	arg_29_1.data = var_29_0

	arg_29_1:setTouchEnabled(true)
	arg_29_1:setTouchSwallowEnabled(false)
	arg_29_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_30_0)
		if arg_30_0.name == "began" then
			arg_29_1:setScale(0.9)

			arg_29_0.startClick_ = true
			arg_29_0.prevX_ = arg_30_0.x
			arg_29_0.prevY_ = arg_30_0.y
		elseif arg_30_0.name == "moved" then
			if math.abs(arg_30_0.y - arg_29_0.prevY_) > 5 or math.abs(arg_30_0.x - arg_29_0.prevX_) > 5 then
				arg_29_0.startClick_ = false

				arg_29_1:setScale(1)
			end
		elseif arg_30_0.name == "ended" and arg_29_0.startClick_ then
			arg_29_1:setScale(1)
			arg_29_0:clickAvatar(var_29_0)
		end

		return true
	end)

	local var_29_2 = arg_29_1:getChildByName("layout")
	local var_29_3 = var_29_2:getChildByName("avatar_mask")
	local var_29_4 = var_29_2:getChildByName("chosen")

	if arg_29_0:checkCanSelect(var_29_0) then
		var_29_3:setVisible(false)
		var_29_4:setVisible(false)
	else
		var_29_3:setVisible(true)
		var_29_4:setVisible(true)

		local var_29_5 = xyd.AssetLoader.get():loadSprite("windows/illusion/cooperation/word_18.png")

		var_29_5:setPosition(55, 105)
		var_29_2:addChild(var_29_5, 11)
		arg_29_1:setTouchEnabled(false)
	end
end

function var_0_0.clickAvatar(arg_31_0, arg_31_1)
	if not arg_31_0.isPet and arg_31_0.occult:checkIsDispatchFull(arg_31_1) then
		local var_31_0 = var_0_7:translation("OCCULT_DISPATCH_LIMIT_TIP")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_31_0
		})

		return
	end

	local var_31_1 = arg_31_0.occult.teamInviteInfos
	local var_31_2 = {
		campaign_id = var_31_1.campaign_id,
		sub_id = var_31_1.sub_id
	}

	if not arg_31_0.isPet then
		var_31_2.partner_id = arg_31_1:getHeroID()
		var_31_2.pos = arg_31_0.index
	else
		var_31_2.pet_id = arg_31_1:getPetID()
	end

	arg_31_0.occult:pickTeamFormation(var_31_2, function(arg_32_0, arg_32_1)
		if arg_32_0 == xyd.error.OK then
			xyd.WindowManager.get():closeWindow(arg_31_0)
		end
	end)
end

function var_0_0.checkCanSelect(arg_33_0, arg_33_1)
	return not arg_33_0.occult:isHeroSelected(arg_33_1) and not arg_33_1.isDead
end

function var_0_0.didOpen(arg_34_0)
	arg_34_0:addBlockLayer()
	arg_34_0:refreshSelectedHeroClass(var_0_5)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_34_0):addEventListener(xyd.event.UPDATE_FILTER_HEROS, handler(arg_34_0, arg_34_0.updateList))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_34_0):addEventListener(xyd.event.HERO_SEARCH, handler(arg_34_0, arg_34_0.updateListBySearchTxt))
end

function var_0_0.updateList(arg_35_0, ...)
	if arg_35_0.leftMenuType ~= var_0_8.HERO then
		return
	end

	arg_35_0:updateFilterHeros()
	arg_35_0:refreshSelectedHeroClass(5)
end

function var_0_0.updateListBySearchTxt(arg_36_0, arg_36_1)
	arg_36_0.searchTxt = arg_36_1.heroName

	arg_36_0:updateSearchHeros()
	arg_36_0:refreshSelectedHeroClass(xyd.DistanceType.SEARCH)
end

function var_0_0.updateSearchHeros(arg_37_0)
	arg_37_0.totalHero_[xyd.DistanceType.SEARCH] = {}
	arg_37_0.totalHero_[xyd.DistanceType.SEARCH][var_0_9.NO] = {}
	arg_37_0.totalHero_[xyd.DistanceType.SEARCH][var_0_9.YES] = {}

	if arg_37_0.searchTxt ~= "" then
		for iter_37_0, iter_37_1 in pairs(arg_37_0.totalHero_[xyd.DistanceType.ALL][var_0_9.NO]) do
			if xyd.searchHeroByName(arg_37_0.searchTxt, iter_37_1) then
				table.insert(arg_37_0.totalHero_[xyd.DistanceType.SEARCH][var_0_9.NO], iter_37_1)
			end
		end

		for iter_37_2, iter_37_3 in pairs(arg_37_0.totalHero_[xyd.DistanceType.ALL][var_0_9.YES]) do
			if xyd.searchHeroByName(arg_37_0.searchTxt, iter_37_3) then
				table.insert(arg_37_0.totalHero_[xyd.DistanceType.SEARCH][var_0_9.YES], iter_37_3)
			end
		end
	end
end

function var_0_0.updateFilterHeros(arg_38_0)
	arg_38_0.totalHero_[xyd.DistanceType.FILTER] = {}
	arg_38_0.totalHero_[xyd.DistanceType.FILTER][var_0_9.NO] = {}
	arg_38_0.totalHero_[xyd.DistanceType.FILTER][var_0_9.YES] = {}

	local var_38_0 = {
		0,
		0,
		0
	}
	local var_38_1 = {
		0,
		0,
		0
	}
	local var_38_2 = {
		0,
		0,
		0,
		0
	}
	local var_38_3 = {
		0,
		0,
		0
	}

	if arg_38_0.selfPlayer.sortType and arg_38_0.selfPlayer.sortType > 0 then
		local var_38_4 = {}
		local var_38_5 = arg_38_0.selfPlayer.sortType
		local var_38_6 = 1

		while var_38_5 > 0 do
			var_38_4[var_38_6] = var_38_5 % 2
			var_38_6 = var_38_6 + 1
			var_38_5 = math.floor(var_38_5 / 2)
		end

		local var_38_7 = 1

		for iter_38_0 = 13, 1, -1 do
			if iter_38_0 <= 4 then
				if iter_38_0 == 4 then
					var_38_7 = 1
				end

				var_38_2[var_38_7] = var_38_4[iter_38_0]
			elseif iter_38_0 <= 7 then
				if iter_38_0 == 7 then
					var_38_7 = 1
				end

				var_38_1[var_38_7] = var_38_4[iter_38_0]
			elseif iter_38_0 <= 10 then
				if iter_38_0 == 10 then
					var_38_7 = 1
				end

				if var_38_4[iter_38_0] then
					var_38_0[var_38_7] = var_38_4[iter_38_0]
				end
			elseif iter_38_0 <= 13 then
				if iter_38_0 == 13 then
					var_38_7 = 1
				end

				if var_38_4[iter_38_0] then
					var_38_3[var_38_7] = var_38_4[iter_38_0]
				end
			end

			var_38_7 = var_38_7 + 1
		end
	else
		var_38_0 = {
			1,
			1,
			1
		}
		var_38_1 = {
			1,
			1,
			1
		}
		var_38_2 = {
			1,
			1,
			1,
			1
		}
		var_38_3 = {
			1,
			1,
			1
		}
	end

	for iter_38_1, iter_38_2 in pairs(arg_38_0.totalHero_[xyd.DistanceType.ALL][var_0_9.NO]) do
		if var_38_0[iter_38_2:getDistanceType() - 1] == 1 and var_38_1[iter_38_2:getHeroType()] == 1 and var_38_2[iter_38_2:getFromType()] == 1 and arg_38_0:canHeroJoinBattle(iter_38_2) and var_38_3[iter_38_2:getAwakenType()] == 1 then
			table.insert(arg_38_0.totalHero_[xyd.DistanceType.FILTER][var_0_9.NO], iter_38_2)
		end
	end

	for iter_38_3, iter_38_4 in pairs(arg_38_0.totalHero_[xyd.DistanceType.ALL][var_0_9.YES]) do
		if var_38_0[iter_38_4:getDistanceType() - 1] == 1 and var_38_1[iter_38_4:getHeroType()] == 1 and var_38_2[iter_38_4:getFromType()] == 1 and arg_38_0:canHeroJoinBattle(iter_38_4) and var_38_3[iter_38_4:getAwakenType()] == 1 then
			table.insert(arg_38_0.totalHero_[xyd.DistanceType.FILTER][var_0_9.YES], iter_38_4)
		end
	end
end

function var_0_0.getPetID(arg_39_0, arg_39_1)
	if arg_39_0.occult:checkIsMaster(arg_39_0.selfPlayer.playerID) then
		if arg_39_0.isPet then
			return tonumber(arg_39_1:getTableID())
		else
			return tonumber(arg_39_0.occult.teamInfo.master_pet)
		end
	else
		return 0
	end
end

return var_0_0
