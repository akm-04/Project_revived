local var_0_0 = class("IllusionSelectHeroWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = 7
local var_0_3 = 6
local var_0_4 = 1
local var_0_5 = xyd.tables.heroTable
local var_0_6 = xyd.tables.translation
local var_0_7 = {
	PET = 2,
	HERO = 1
}
local var_0_8 = {
	YES = 2,
	NO = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.illusion = xyd.ModelManager.get():loadModel(xyd.ModelType.ILLUSION)
	arg_1_0.tmpHeros_ = {}
	arg_1_0.totalHero_ = {}
	arg_1_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_1_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.FILTER] = {}

	for iter_1_0, iter_1_1 in pairs(arg_1_0.totalHero_) do
		iter_1_1[var_0_8.NO] = {}
		iter_1_1[var_0_8.YES] = {}
	end

	arg_1_0.tmpTotalPets = {}
	arg_1_0.totalPet_ = {}
	arg_1_0.leftMenuType = var_0_7.HERO
	arg_1_0.isPet = arg_1_2.isPet
	arg_1_0.index = arg_1_2.index
	arg_1_0.selfHeros = arg_1_2.selfHeros
	arg_1_0.collocationType_ = var_0_8.NO
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.playerInfo = arg_2_0.illusion:getPlayerInfoByID(arg_2_0.selfPlayer.playerID)

	if arg_2_0.isPet then
		arg_2_0.leftMenuType = var_0_7.PET

		arg_2_0:initPetInfos()
	else
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

	arg_3_0:sortHeros(var_3_1)

	arg_3_0.totalPet_ = var_3_1
end

function var_0_0.initHeroInfos(arg_4_0)
	arg_4_0.heros_ = arg_4_0:getHeros()

	arg_4_0:sortHeros(arg_4_0.heros_)

	for iter_4_0, iter_4_1 in pairs(arg_4_0.heros_) do
		if iter_4_1:getDistanceType() == xyd.DistanceType.QIANPAI then
			table.insert(arg_4_0.totalHero_[xyd.DistanceType.QIANPAI][var_0_8.NO], iter_4_1)

			if iter_4_1:isCollocation() then
				table.insert(arg_4_0.totalHero_[xyd.DistanceType.QIANPAI][var_0_8.YES], iter_4_1)
			end
		elseif iter_4_1:getDistanceType() == xyd.DistanceType.ZHONGPAI then
			table.insert(arg_4_0.totalHero_[xyd.DistanceType.ZHONGPAI][var_0_8.NO], iter_4_1)

			if iter_4_1:isCollocation() then
				table.insert(arg_4_0.totalHero_[xyd.DistanceType.ZHONGPAI][var_0_8.YES], iter_4_1)
			end
		elseif iter_4_1:getDistanceType() == xyd.DistanceType.HOUPAI then
			table.insert(arg_4_0.totalHero_[xyd.DistanceType.HOUPAI][var_0_8.NO], iter_4_1)

			if iter_4_1:isCollocation() then
				table.insert(arg_4_0.totalHero_[xyd.DistanceType.HOUPAI][var_0_8.YES], iter_4_1)
			end
		end

		table.insert(arg_4_0.totalHero_[xyd.DistanceType.ALL][var_0_8.NO], iter_4_1)

		if iter_4_1:isCollocation() then
			table.insert(arg_4_0.totalHero_[xyd.DistanceType.ALL][var_0_8.YES], iter_4_1)
		end
	end

	arg_4_0.tmpHeros_ = arg_4_0.totalHero_[xyd.DistanceType.ALL][arg_4_0.collocationType_]
end

function var_0_0.getHeros(arg_5_0)
	return arg_5_0.selfPlayer.heros_
end

function var_0_0.canHeroJoinBattle(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0.playerInfo.force or 0

	if var_6_0 ~= 0 and arg_6_1:getZhandouli() < math.floor(var_6_0 / xyd.tables.misc.teamPowerLimit) then
		return false
	end

	return true
end

function var_0_0.canPetJoinBattle(arg_7_0)
	return true
end

function var_0_0.sortHeros(arg_8_0, arg_8_1)
	table.sort(arg_8_1, function(arg_9_0, arg_9_1)
		return xyd.heroNormalSort(arg_9_0, arg_9_1) or false
	end)
end

function var_0_0.layout(arg_10_0)
	arg_10_0:nodeByName("txt_qianpai"):setString(var_0_6:translation("HERO_QIANPAI"))
	arg_10_0:nodeByName("txt_zhongpai"):setString(var_0_6:translation("HERO_ZHONGPAI"))
	arg_10_0:nodeByName("txt_houpai"):setString(var_0_6:translation("HERO_HOUPAI"))
	arg_10_0:nodeByName("txt_all"):setString(var_0_6:translation("PERSON_SELECT_ALL"))
	arg_10_0:nodeByName("txt_hero"):setString(var_0_6:translation("PERSON_SELECT_HERO"))
	arg_10_0:nodeByName("txt_pet"):setString(var_0_6:translation("PERSON_SELECT_PET"))
	arg_10_0:initMenu()

	if arg_10_0.isPet then
		arg_10_0:nodeByName("txt_title"):setString(var_0_6:translation("PERSON_SELECT_PET"))
	else
		arg_10_0:nodeByName("txt_title"):setString(var_0_6:translation("PERSON_SELECT_HERO"))
	end

	local var_10_0 = arg_10_0:nodeByName("hero_list")
	local var_10_1 = var_10_0:getContentSize()

	arg_10_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_10_1.width, var_10_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_10_0):onScroll(handler(arg_10_0, arg_10_0.scrollListener))

	arg_10_0.heroList_:setDelegate(handler(arg_10_0, arg_10_0.delegate))

	if arg_10_0.isPet then
		arg_10_0:nodeByName("btn_hero"):setVisible(false)

		local var_10_2 = cc.p(arg_10_0:nodeByName("btn_hero"):getPosition())

		arg_10_0:nodeByName("btn_pet"):setPosition(cc.p(var_10_2))
		arg_10_0:nodeByName("btn_pet"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_10_0:nodeByName("btn_pet"):setTouchEnabled(false)
		arg_10_0:nodeByName("quanbu_button"):setVisible(false)
		arg_10_0:nodeByName("qianpai_button"):setVisible(false)
		arg_10_0:nodeByName("zhongpai_button"):setVisible(false)
		arg_10_0:nodeByName("houpai_button"):setVisible(false)
	else
		arg_10_0:nodeByName("btn_pet"):setVisible(false)
		arg_10_0:nodeByName("btn_hero"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_10_0:nodeByName("btn_hero"):setTouchEnabled(false)
	end

	var_0_1.new({
		size = 888,
		type = xyd.SplitlineType.SOLID
	}):addTo(arg_10_0:nodeByName("pos_line"))
end

function var_0_0.initMenu(arg_11_0)
	arg_11_0:nodeByName("quanbu_button"):setBrightStyle(ccui.BrightStyle.highlight)

	arg_11_0.heroClassButtons_ = {}

	local var_11_0 = arg_11_0:nodeByName("container")

	table.insert(arg_11_0.heroClassButtons_, arg_11_0:nodeByName("quanbu_button"))
	table.insert(arg_11_0.heroClassButtons_, arg_11_0:nodeByName("qianpai_button"))
	table.insert(arg_11_0.heroClassButtons_, arg_11_0:nodeByName("zhongpai_button"))
	table.insert(arg_11_0.heroClassButtons_, arg_11_0:nodeByName("houpai_button"))
	table.insert(arg_11_0.heroClassButtons_, arg_11_0:nodeByName("button_filter"))
	table.insert(arg_11_0.heroClassButtons_, arg_11_0:nodeByName("button_search"))

	for iter_11_0 = 1, #arg_11_0.heroClassButtons_ do
		arg_11_0.heroClassButtons_[iter_11_0]:setZoomScale(0.3)
		arg_11_0.heroClassButtons_[iter_11_0]:addTouchEventListener(function(arg_12_0, arg_12_1)
			for iter_12_0 = 1, #arg_11_0.heroClassButtons_ do
				if iter_12_0 == iter_11_0 then
					arg_11_0.heroClassButtons_[iter_12_0]:setBrightStyle(ccui.BrightStyle.highlight)
				else
					arg_11_0.heroClassButtons_[iter_12_0]:setBrightStyle(ccui.BrightStyle.normal)
				end
			end

			if arg_12_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()
				arg_11_0:refreshSelectedHeroClass(iter_11_0)
			end
		end)
	end

	arg_11_0:nodeByName("text_filter"):setString(var_0_6:translation("FILTER_TEXT"))
	arg_11_0:nodeByName("button_filter"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_13_0, arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("hero_filter_wnd")
		end
	end)
	arg_11_0:nodeByName("button_search"):addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(arg_14_0, arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("hero_search_wnd")
		end
	end)
	arg_11_0:nodeByName("button_collocation"):addTouchEventListener(function(arg_15_0, arg_15_1)
		xyd.buttonScaleAnim(arg_15_0, arg_15_1)

		if arg_15_1 == ccui.TouchEventType.ended then
			arg_11_0.collocationType_ = 3 - arg_11_0.collocationType_

			arg_11_0:refreshSelectedHeroClass()
		end
	end)
end

function var_0_0.refreshSelectedHeroClass(arg_16_0, arg_16_1)
	arg_16_0.heroList_:removeAllItems()

	if arg_16_1 then
		arg_16_0.selectHeroClass_ = arg_16_1
		arg_16_0.tmpHeros_ = arg_16_0.totalHero_[arg_16_1][arg_16_0.collocationType_]
	else
		arg_16_0.tmpHeros_ = arg_16_0.totalHero_[arg_16_0.selectHeroClass_][arg_16_0.collocationType_]
	end

	for iter_16_0 = 1, #arg_16_0.heroClassButtons_ do
		if arg_16_0.selectHeroClass_ == iter_16_0 then
			arg_16_0.heroClassButtons_[iter_16_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_16_0.heroClassButtons_[iter_16_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_16_0.heroList_:reload()
end

function var_0_0.scrollListener(arg_17_0, arg_17_1)
	if arg_17_1.name == "began" then
		arg_17_0.scrollViewMoved_ = false
		arg_17_0.prevY_ = arg_17_1.y
	elseif arg_17_1.name == "moved" and 10 <= math.abs(arg_17_1.y - arg_17_0.prevY_) then
		arg_17_0.scrollViewMoved_ = true
	end
end

function var_0_0.delegate(arg_18_0, ...)
	if arg_18_0.leftMenuType == var_0_7.PET then
		return arg_18_0:petDelegate(...)
	end

	return arg_18_0:heroDelegate(...)
end

function var_0_0.heroDelegate(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	if cc.ui.UIListView.COUNT_TAG == arg_19_2 then
		return (math.ceil(#arg_19_0.tmpHeros_ / var_0_2))
	elseif cc.ui.UIListView.CELL_TAG == arg_19_2 then
		local var_19_0 = arg_19_0.heroList_:dequeueItem()

		if not var_19_0 then
			var_19_0 = arg_19_0.heroList_:newItem()
		else
			var_19_0:removeAllChildren(true)
		end

		local var_19_1 = 890
		local var_19_2 = 150

		var_19_0:setItemSize(var_19_1, var_19_2)

		local var_19_3 = display.newNode()

		var_19_3:setContentSize(var_19_1, var_19_2)

		for iter_19_0 = 1, var_0_2 do
			local var_19_4 = (arg_19_3 - 1) * var_0_2 + iter_19_0

			if var_19_4 > #arg_19_0.tmpHeros_ then
				break
			end

			local var_19_5 = display.newNode()
			local var_19_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/hero_avatar_list.csb")
			local var_19_7 = var_19_6:getChildByName("avatar")

			var_19_5:setContentSize(105, 105)
			var_19_5:setAnchorPoint(0.5, 0.5)
			var_19_5:addChild(var_19_6)
			var_19_6:setPosition(0, -10)
			var_19_3:addChild(var_19_5)
			var_19_5:setPosition(55 + (iter_19_0 - 1) * 130, 70)
			var_19_5:setTouchEnabled(true)
			var_19_5:setTouchSwallowEnabled(false)

			local var_19_8 = arg_19_0.tmpHeros_[var_19_4]

			xyd.setAvatarBorderNewUI(var_19_8, var_19_7, var_19_8:getColor(), var_19_8:getStar())

			local var_19_9 = var_19_6:getChildByName("avatar_mask")

			var_19_9:setLocalZOrder(2)
			var_19_9:setVisible(false)

			if not arg_19_0:checkCanSelect(var_19_8) then
				local var_19_10 = xyd.AssetLoader.get():loadSprite("windows/illusion/cooperation/word_18.png")

				var_19_10:setPosition(65, 90)
				var_19_7:addChild(var_19_10, 11)
				var_19_9:setVisible(true)
			end

			var_19_6:getChildByName("lv_txt"):setString(var_19_8:getLevel())
			var_19_6:getChildByName("name_text"):setString(var_19_8:getName())
			var_19_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
				if arg_20_0.name == "began" then
					var_19_5:setScale(0.9)

					return true
				elseif arg_20_0.name == "ended" then
					var_19_5:setScale(1)

					if not arg_19_0.scrollViewMoved_ then
						arg_19_0:clickAvatar(var_19_8)
					end
				end
			end)
		end

		var_19_0:addContent(var_19_3)

		return var_19_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_19_2 then
		-- block empty
	end
end

function var_0_0.petDelegate(arg_21_0, arg_21_1, arg_21_2, arg_21_3)
	local var_21_0 = math.ceil(#arg_21_0.totalPet_ / var_0_3)

	if cc.ui.UIListView.COUNT_TAG == arg_21_2 then
		return var_21_0
	elseif cc.ui.UIListView.CELL_TAG == arg_21_2 then
		local var_21_1
		local var_21_2
		local var_21_3
		local var_21_4 = arg_21_0.heroList_:dequeueItem()

		if not var_21_4 then
			var_21_4 = arg_21_0.heroList_:newItem()
		else
			var_21_4:removeAllChildren()
		end

		local var_21_5 = display.newNode()

		var_21_5:setTouchSwallowEnabled(false)

		for iter_21_0 = 1, var_0_3 do
			local var_21_6 = (arg_21_3 - 1) * var_0_3 + iter_21_0

			if var_21_6 > #arg_21_0.totalPet_ then
				break
			end

			var_21_3 = display.newNode()

			arg_21_0:initPetCell(var_21_3, var_21_6)

			local var_21_7 = var_21_3:getContentSize().width + 35
			local var_21_8 = var_21_3:getContentSize().height + 35
			local var_21_9 = (arg_21_0.heroList_.viewRect_.width - var_21_7 * var_0_3) / (var_0_3 + 1)

			var_21_3:align(display.CENTER, var_21_9 * iter_21_0 + (iter_21_0 - 1) * var_21_7 + var_21_7 / 2, var_21_8 / 2)
			var_21_5:addChild(var_21_3)
		end

		var_21_5:setContentSize(cc.size(arg_21_0.heroList_.viewRect_.width, var_21_3:getContentSize().height + 5))
		var_21_4:setItemSize(arg_21_0.heroList_.viewRect_.width, var_21_3:getContentSize().height + 50)
		var_21_4:addContent(var_21_5)

		return var_21_4
	end
end

function var_0_0.initPetCell(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = arg_22_0.totalPet_[arg_22_2]
	local var_22_1 = false

	arg_22_1:setContentSize(105, 105)
	xyd.setPetAvatarNewUI(arg_22_1, var_22_0, 100)

	arg_22_1.data = var_22_0

	arg_22_1:setTouchEnabled(true)
	arg_22_1:setTouchSwallowEnabled(false)
	arg_22_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
		if arg_23_0.name == "began" then
			arg_22_1:setScale(0.9)

			arg_22_0.startClick_ = true
			arg_22_0.prevX_ = arg_23_0.x
			arg_22_0.prevY_ = arg_23_0.y
		elseif arg_23_0.name == "moved" then
			if math.abs(arg_23_0.y - arg_22_0.prevY_) > 5 or math.abs(arg_23_0.x - arg_22_0.prevX_) > 5 then
				arg_22_0.startClick_ = false

				arg_22_1:setScale(1)
			end
		elseif arg_23_0.name == "ended" and arg_22_0.startClick_ then
			arg_22_1:setScale(1)
			arg_22_0:clickAvatar(var_22_0)
		end

		return true
	end)

	local var_22_2 = arg_22_1:getChildByName("layout")
	local var_22_3 = var_22_2:getChildByName("avatar_mask")
	local var_22_4 = var_22_2:getChildByName("chosen")

	if arg_22_0:checkCanSelect(var_22_0) then
		var_22_3:setVisible(false)
		var_22_4:setVisible(false)
	else
		var_22_3:setVisible(true)
		var_22_4:setVisible(true)

		local var_22_5 = xyd.AssetLoader.get():loadSprite("windows/illusion/cooperation/word_18.png")

		var_22_5:setPosition(85, 105)
		var_22_2:addChild(var_22_5, 11)
	end
end

function var_0_0.clickAvatar(arg_24_0, arg_24_1)
	if not arg_24_1.isPet_ and not arg_24_0:canHeroJoinBattle(arg_24_1) then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_6:translation("ILLUSION_TEAM_TIPS_25"), arg_24_1:getName())
		})

		return
	elseif not arg_24_0:checkCanSelect(arg_24_1) then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_6:translation("ILLUSION_TEAM_TIPS_14"), arg_24_1:getName())
		})

		return
	end

	local var_24_0 = {
		partner_str = arg_24_0:getPartnerStr(arg_24_1),
		pet_id = arg_24_0:getPetID(arg_24_1)
	}

	arg_24_0.illusion:setPartner(var_24_0, function(arg_25_0, arg_25_1)
		if arg_25_0 == xyd.error.OK then
			xyd.WindowManager.get():closeWindow(arg_24_0)
		end
	end)
end

function var_0_0.checkCanSelect(arg_26_0, arg_26_1)
	if arg_26_1.isPet_ then
		local var_26_0 = arg_26_0.illusion.teamInfo.master_pet

		if var_26_0 == arg_26_1:getTableID() or var_26_0 == arg_26_1:beforeAwakenID() and var_26_0 ~= 0 then
			return false
		end

		return true
	end

	local var_26_1 = arg_26_0.illusion:getSelectHeros()

	for iter_26_0 = 1, #var_26_1 do
		if var_26_1[iter_26_0] == arg_26_1:getTableID() or var_26_1[iter_26_0] == arg_26_1:beforeAwakenID() and var_26_1[iter_26_0] ~= 0 or var_26_1[iter_26_0] == arg_26_1:afterAwakenID() and var_26_1[iter_26_0] ~= 0 then
			return false
		end
	end

	return true
end

function var_0_0.didOpen(arg_27_0)
	arg_27_0:addBlockLayer()
	arg_27_0:refreshSelectedHeroClass(var_0_4)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_27_0):addEventListener(xyd.event.UPDATE_FILTER_HEROS, handler(arg_27_0, arg_27_0.updateList))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_27_0):addEventListener(xyd.event.HERO_SEARCH, handler(arg_27_0, arg_27_0.updateListBySearchTxt))
end

function var_0_0.updateList(arg_28_0, ...)
	arg_28_0:updateFilterHeros()
	arg_28_0:refreshSelectedHeroClass(xyd.DistanceType.FILTER)
end

function var_0_0.updateListBySearchTxt(arg_29_0, arg_29_1)
	arg_29_0.searchTxt = arg_29_1.heroName

	arg_29_0:updateSearchHeros()
	arg_29_0:refreshSelectedHeroClass(xyd.DistanceType.SEARCH)
end

function var_0_0.updateFilterHeros(arg_30_0)
	arg_30_0.totalHero_[xyd.DistanceType.FILTER] = {}
	arg_30_0.totalHero_[xyd.DistanceType.FILTER][var_0_8.NO] = {}
	arg_30_0.totalHero_[xyd.DistanceType.FILTER][var_0_8.YES] = {}

	local var_30_0 = {
		0,
		0,
		0
	}
	local var_30_1 = {
		0,
		0,
		0
	}
	local var_30_2 = {
		0,
		0,
		0,
		0
	}
	local var_30_3 = {
		0,
		0,
		0
	}

	if arg_30_0.selfPlayer.sortType and arg_30_0.selfPlayer.sortType > 0 then
		local var_30_4 = {}
		local var_30_5 = arg_30_0.selfPlayer.sortType
		local var_30_6 = 1

		while var_30_5 > 0 do
			var_30_4[var_30_6] = var_30_5 % 2
			var_30_6 = var_30_6 + 1
			var_30_5 = math.floor(var_30_5 / 2)
		end

		local var_30_7 = 1

		for iter_30_0 = 13, 1, -1 do
			if iter_30_0 <= 4 then
				if iter_30_0 == 4 then
					var_30_7 = 1
				end

				var_30_2[var_30_7] = var_30_4[iter_30_0]
			elseif iter_30_0 <= 7 then
				if iter_30_0 == 7 then
					var_30_7 = 1
				end

				var_30_1[var_30_7] = var_30_4[iter_30_0]
			elseif iter_30_0 <= 10 then
				if iter_30_0 == 10 then
					var_30_7 = 1
				end

				if var_30_4[iter_30_0] then
					var_30_0[var_30_7] = var_30_4[iter_30_0]
				end
			elseif iter_30_0 <= 13 then
				if iter_30_0 == 13 then
					var_30_7 = 1
				end

				if var_30_4[iter_30_0] then
					var_30_3[var_30_7] = var_30_4[iter_30_0]
				end
			end

			var_30_7 = var_30_7 + 1
		end
	else
		var_30_0 = {
			1,
			1,
			1
		}
		var_30_1 = {
			1,
			1,
			1
		}
		var_30_2 = {
			1,
			1,
			1,
			1
		}
		var_30_3 = {
			1,
			1,
			1
		}
	end

	for iter_30_1, iter_30_2 in pairs(arg_30_0.totalHero_[xyd.DistanceType.ALL][var_0_8.NO]) do
		if var_30_0[iter_30_2:getDistanceType() - 1] == 1 and var_30_1[iter_30_2:getHeroType()] == 1 and var_30_2[iter_30_2:getFromType()] == 1 and arg_30_0:canHeroJoinBattle(iter_30_2) and var_30_3[iter_30_2:getAwakenType()] == 1 then
			table.insert(arg_30_0.totalHero_[xyd.DistanceType.FILTER][var_0_8.NO], iter_30_2)
		end
	end

	for iter_30_3, iter_30_4 in pairs(arg_30_0.totalHero_[xyd.DistanceType.ALL][var_0_8.YES]) do
		if var_30_0[iter_30_4:getDistanceType() - 1] == 1 and var_30_1[iter_30_4:getHeroType()] == 1 and var_30_2[iter_30_4:getFromType()] == 1 and arg_30_0:canHeroJoinBattle(iter_30_4) and var_30_3[iter_30_4:getAwakenType()] == 1 then
			table.insert(arg_30_0.totalHero_[xyd.DistanceType.FILTER][var_0_8.YES], iter_30_4)
		end
	end
end

function var_0_0.updateSearchHeros(arg_31_0)
	arg_31_0.totalHero_[xyd.DistanceType.SEARCH] = {}
	arg_31_0.totalHero_[xyd.DistanceType.SEARCH][var_0_8.NO] = {}
	arg_31_0.totalHero_[xyd.DistanceType.SEARCH][var_0_8.YES] = {}

	if arg_31_0.searchTxt ~= "" then
		for iter_31_0, iter_31_1 in pairs(arg_31_0.totalHero_[xyd.DistanceType.ALL][var_0_8.NO]) do
			if xyd.searchHeroByName(arg_31_0.searchTxt, iter_31_1) then
				table.insert(arg_31_0.totalHero_[xyd.DistanceType.SEARCH][var_0_8.NO], iter_31_1)
			end
		end

		for iter_31_2, iter_31_3 in pairs(arg_31_0.totalHero_[xyd.DistanceType.ALL][var_0_8.YES]) do
			if xyd.searchHeroByName(arg_31_0.searchTxt, iter_31_3) then
				table.insert(arg_31_0.totalHero_[xyd.DistanceType.SEARCH][var_0_8.YES], iter_31_3)
			end
		end
	end
end

function var_0_0.getPartnerStr(arg_32_0, arg_32_1)
	local var_32_0 = ""

	if arg_32_0.index == 1 then
		var_32_0 = var_32_0 .. arg_32_1:getTableID()

		if arg_32_0.selfHeros[2] then
			var_32_0 = var_32_0 .. "|" .. arg_32_0.selfHeros[2]
		end
	elseif arg_32_0.index == 2 then
		var_32_0 = var_32_0 .. arg_32_0.selfHeros[1] .. "|" .. arg_32_1:getTableID()
	elseif arg_32_0.index == 3 and arg_32_0.selfHeros[1] ~= 0 then
		var_32_0 = var_32_0 .. arg_32_0.selfHeros[1]
	end

	return var_32_0
end

function var_0_0.getPetID(arg_33_0, arg_33_1)
	if arg_33_0.illusion:checkIsMaster(arg_33_0.selfPlayer.playerID) then
		if arg_33_0.isPet then
			return tonumber(arg_33_1:getTableID())
		else
			return tonumber(arg_33_0.illusion.teamInfo.master_pet)
		end
	else
		return 0
	end
end

return var_0_0
