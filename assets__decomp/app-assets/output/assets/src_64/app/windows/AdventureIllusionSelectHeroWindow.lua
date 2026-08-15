local var_0_0 = class("AdventureIllusionSelectHeroWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = 5
local var_0_2 = 30
local var_0_3 = 5
local var_0_4 = 1
local var_0_5 = xyd.tables.heroTable
local var_0_6 = xyd.tables.translation
local var_0_7 = {
	PET = 2,
	HERO = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.adventureEvent = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
	arg_1_0.tmpHeros_ = {}
	arg_1_0.totalHero_ = {}
	arg_1_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_1_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.FILTER] = {}
	arg_1_0.tmpTotalPets = {}
	arg_1_0.totalPet_ = {}
	arg_1_0.leftMenuType = var_0_7.HERO
	arg_1_0.isPet = arg_1_2.isPet
	arg_1_0.index = arg_1_2.index
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.playerInfo = arg_2_0.adventureEvent:getPlayerInfoByID(arg_2_0.selfPlayer.playerID)

	if arg_2_0.isPet then
		arg_2_0.leftMenuType = var_0_7.PET

		arg_2_0:initPetInfos()
	else
		arg_2_0.leftMenuType = var_0_7.HERO

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

	arg_3_0:sortHeros(var_3_1, true)

	arg_3_0.totalPet_ = var_3_1
end

function var_0_0.initHeroInfos(arg_4_0)
	arg_4_0.heros_ = arg_4_0:getHeros()

	arg_4_0:sortHeros(arg_4_0.heros_)

	for iter_4_0, iter_4_1 in pairs(arg_4_0.heros_) do
		if iter_4_1:getDistanceType() == xyd.DistanceType.QIANPAI then
			table.insert(arg_4_0.totalHero_[xyd.DistanceType.QIANPAI], iter_4_1)
		elseif iter_4_1:getDistanceType() == xyd.DistanceType.ZHONGPAI then
			table.insert(arg_4_0.totalHero_[xyd.DistanceType.ZHONGPAI], iter_4_1)
		elseif iter_4_1:getDistanceType() == xyd.DistanceType.HOUPAI then
			table.insert(arg_4_0.totalHero_[xyd.DistanceType.HOUPAI], iter_4_1)
		end
	end

	arg_4_0:updateFilterHeros()

	arg_4_0.tmpHeros_ = arg_4_0.heros_
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

function var_0_0.sortHeros(arg_8_0, arg_8_1, arg_8_2)
	table.sort(arg_8_1, function(arg_9_0, arg_9_1)
		if arg_8_2 then
			return xyd.petNormalSort(arg_9_0, arg_9_1) or false
		else
			return xyd.heroNormalSort(arg_9_0, arg_9_1) or false
		end
	end)
end

function var_0_0.layout(arg_10_0)
	arg_10_0:initMenu()

	if arg_10_0.isPet then
		arg_10_0:nodeByName("text_title"):setString(var_0_6:translation("OCCULT_TEAM_TIPS_13"))
	else
		arg_10_0:nodeByName("text_title"):setString(var_0_6:translation("OCCULT_TEAM_TIPS_12"))
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
	else
		arg_10_0:nodeByName("btn_pet"):setVisible(false)
		arg_10_0:nodeByName("btn_hero"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_10_0:nodeByName("btn_hero"):setTouchEnabled(false)
	end
end

function var_0_0.initMenu(arg_11_0)
	arg_11_0.heroClassButtons_ = {}

	local var_11_0 = arg_11_0:nodeByName("container")

	table.insert(arg_11_0.heroClassButtons_, arg_11_0:nodeByName("quanbu_button"))
	table.insert(arg_11_0.heroClassButtons_, arg_11_0:nodeByName("qianpai_button"))
	table.insert(arg_11_0.heroClassButtons_, arg_11_0:nodeByName("zhongpai_button"))
	table.insert(arg_11_0.heroClassButtons_, arg_11_0:nodeByName("houpai_button"))
	table.insert(arg_11_0.heroClassButtons_, arg_11_0:nodeByName("filter_button"))

	for iter_11_0 = 1, #arg_11_0.heroClassButtons_ do
		arg_11_0.heroClassButtons_[iter_11_0]:setZoomScale(0.3)
		arg_11_0.heroClassButtons_[iter_11_0]:addTouchEventListener(function(arg_12_0, arg_12_1)
			if arg_12_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()
				arg_11_0:refreshSelectedHeroClass(iter_11_0)
			end
		end)
	end
end

function var_0_0.refreshSelectedHeroClass(arg_13_0, arg_13_1)
	arg_13_0.heroList_:removeAllItems()

	if arg_13_1 == 1 then
		arg_13_0.tmpHeros_ = arg_13_0.heros_
	elseif arg_13_1 == 2 then
		arg_13_0.tmpHeros_ = arg_13_0.totalHero_[xyd.DistanceType.QIANPAI]
	elseif arg_13_1 == 3 then
		arg_13_0.tmpHeros_ = arg_13_0.totalHero_[xyd.DistanceType.ZHONGPAI]
	elseif arg_13_1 == 4 then
		arg_13_0.tmpHeros_ = arg_13_0.totalHero_[xyd.DistanceType.HOUPAI]
	elseif arg_13_1 == 5 then
		arg_13_0.tmpHeros_ = arg_13_0.totalHero_[xyd.DistanceType.FILTER]
	else
		arg_13_0.tmpHeros_ = arg_13_0.heros_
	end

	for iter_13_0 = 1, #arg_13_0.heroClassButtons_ do
		if arg_13_1 == iter_13_0 then
			arg_13_0.heroClassButtons_[iter_13_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_13_0.heroClassButtons_[iter_13_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_13_0.heroList_:reload()
end

function var_0_0.scrollListener(arg_14_0, arg_14_1)
	if arg_14_1.name == "began" then
		arg_14_0.scrollViewMoved_ = false
		arg_14_0.prevY_ = arg_14_1.y
	elseif arg_14_1.name == "moved" and 10 <= math.abs(arg_14_1.y - arg_14_0.prevY_) then
		arg_14_0.scrollViewMoved_ = true
	end
end

function var_0_0.delegate(arg_15_0, ...)
	if arg_15_0.leftMenuType == var_0_7.PET then
		return arg_15_0:petDelegate(...)
	end

	return arg_15_0:heroDelegate(...)
end

function var_0_0.heroDelegate(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	if cc.ui.UIListView.COUNT_TAG == arg_16_2 then
		return (math.ceil(#arg_16_0.tmpHeros_ / var_0_1))
	elseif cc.ui.UIListView.CELL_TAG == arg_16_2 then
		local var_16_0 = arg_16_0.heroList_:dequeueItem()

		if not var_16_0 then
			var_16_0 = arg_16_0.heroList_:newItem()
		else
			var_16_0:removeAllChildren(true)
		end

		local var_16_1 = 700
		local var_16_2 = 130

		var_16_0:setItemSize(var_16_1, 135)

		local var_16_3 = display.newNode()

		var_16_3:setContentSize(var_16_1, 135)

		for iter_16_0 = 1, var_0_1 do
			local var_16_4 = (arg_16_3 - 1) * var_0_1 + iter_16_0

			if var_16_4 > #arg_16_0.tmpHeros_ then
				break
			end

			local var_16_5 = display.newNode()

			var_16_5:setContentSize(128, 128)
			var_16_5:setPosition(142 * iter_16_0 - 142 + 64, 64)
			var_16_5:setAnchorPoint(cc.p(0.5, 0.5))
			var_16_3:addChild(var_16_5)
			var_16_5:setTouchEnabled(true)
			var_16_5:setTouchSwallowEnabled(false)

			local var_16_6 = arg_16_0.tmpHeros_[var_16_4]

			xyd.setAvatarBorder(var_16_6, var_16_5, var_16_6:getColor(), var_16_6:getStar())

			local var_16_7 = xyd.AssetLoader.get():loadSprite("windows/common/lv_di.png")

			var_16_7:setScale(1.2)

			if not arg_16_0:checkCanSelect(var_16_6) then
				local var_16_8 = xyd.AssetLoader.get():loadSprite("windows/arena/avatar_mask.png")
				local var_16_9 = xyd.AssetLoader.get():loadSprite("windows/illusion/cooperation/word_18.png")

				var_16_8:setScale(1.1)
				var_16_8:setPosition(63, 62)
				var_16_9:setPosition(85, 105)
				var_16_5:addChild(var_16_8, 10)
				var_16_5:addChild(var_16_9, 11)
			end

			local var_16_10 = var_16_7:getWidth()
			local var_16_11 = var_16_5:getWidth()
			local var_16_12 = var_16_5:getHeight()

			var_16_7:setAnchorPoint(cc.p(0.5, 0.5))
			var_16_7:addTo(var_16_5)
			var_16_7:setPosition(var_16_10 / 2, var_16_12 / 3)

			local var_16_13 = {
				size = 16,
				color = cc.c3b(255, 255, 255)
			}
			local var_16_14 = xyd.AssetLoader.get():loadLabel(var_16_13)

			var_16_14:setString(var_16_6:getLevel())
			var_16_14:addTo(var_16_5)
			var_16_14:setAnchorPoint(cc.p(0.5, 0.5))
			var_16_14:setPosition(var_16_7:getPositionX() + 4, var_16_7:getPositionY() - 0.5)
			var_16_14:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
			var_16_5:getChildByName("border"):setLocalZOrder(var_16_14:getLocalZOrder() + 1)
			var_16_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
				if arg_17_0.name == "began" then
					var_16_5:setScale(0.9)

					return true
				elseif arg_17_0.name == "ended" then
					var_16_5:setScale(1)

					if not arg_16_0.scrollViewMoved_ then
						arg_16_0:clickAvatar(var_16_6)
					end
				end
			end)
		end

		var_16_0:addContent(var_16_3)

		return var_16_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_16_2 then
		-- block empty
	end
end

function var_0_0.petDelegate(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	local var_18_0 = math.ceil(#arg_18_0.totalPet_ / var_0_3)

	if cc.ui.UIListView.COUNT_TAG == arg_18_2 then
		return var_18_0
	elseif cc.ui.UIListView.CELL_TAG == arg_18_2 then
		local var_18_1
		local var_18_2
		local var_18_3
		local var_18_4 = arg_18_0.heroList_:dequeueItem()

		if not var_18_4 then
			var_18_4 = arg_18_0.heroList_:newItem()
		else
			var_18_4:removeAllChildren()
		end

		local var_18_5 = display.newNode()

		var_18_5:setTouchSwallowEnabled(false)

		for iter_18_0 = 1, var_0_3 do
			local var_18_6 = (arg_18_3 - 1) * var_0_3 + iter_18_0

			if var_18_6 > #arg_18_0.totalPet_ then
				break
			end

			var_18_3 = display.newNode()

			arg_18_0:initPetCell(var_18_3, var_18_6)

			local var_18_7 = var_18_3:getContentSize().width
			local var_18_8 = var_18_3:getContentSize().height
			local var_18_9 = (arg_18_0.heroList_.viewRect_.width - var_18_7 * var_0_3) / (var_0_3 + 1)

			var_18_3:align(display.CENTER, var_18_9 * iter_18_0 + (iter_18_0 - 1) * var_18_7 + var_18_7 / 2, var_18_8 / 2)
			var_18_5:addChild(var_18_3)
		end

		var_18_5:setContentSize(cc.size(arg_18_0.heroList_.viewRect_.width, var_18_3:getContentSize().height + 5))
		var_18_4:setItemSize(arg_18_0.heroList_.viewRect_.width, var_18_3:getContentSize().height + 5)
		var_18_4:addContent(var_18_5)

		return var_18_4
	end
end

function var_0_0.initPetCell(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = arg_19_0.totalPet_[arg_19_2]
	local var_19_1 = false

	arg_19_1:align(display.CENTER):size(146, 146)
	xyd.setPetAvatar(arg_19_1, var_19_0, 100)

	arg_19_1.data = var_19_0

	arg_19_1:setTouchEnabled(true)
	arg_19_1:setTouchSwallowEnabled(false)
	arg_19_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
		if arg_20_0.name == "began" then
			arg_19_1:setScale(0.9)

			arg_19_0.startClick_ = true
			arg_19_0.prevX_ = arg_20_0.x
			arg_19_0.prevY_ = arg_20_0.y
		elseif arg_20_0.name == "moved" then
			if math.abs(arg_20_0.y - arg_19_0.prevY_) > 5 or math.abs(arg_20_0.x - arg_19_0.prevX_) > 5 then
				arg_19_0.startClick_ = false

				arg_19_1:setScale(1)
			end
		elseif arg_20_0.name == "ended" and arg_19_0.startClick_ then
			arg_19_1:setScale(1)
			arg_19_0:clickAvatar(var_19_0)
		end

		return true
	end)

	layout = arg_19_1:getChildByName("layout")

	local var_19_2 = layout:getChildByName("avatar_mask")
	local var_19_3 = layout:getChildByName("chosen")

	if arg_19_0:checkCanSelect(var_19_0) then
		var_19_2:setVisible(false)
		var_19_3:setVisible(false)
	else
		var_19_2:setVisible(true)
		var_19_3:setVisible(true)

		local var_19_4 = xyd.AssetLoader.get():loadSprite("windows/illusion/cooperation/word_18.png")

		var_19_4:setPosition(85, 105)
		layout:addChild(var_19_4, 11)
		arg_19_1:setTouchEnabled(false)
	end
end

function var_0_0.clickAvatar(arg_21_0, arg_21_1)
	if not arg_21_0.isPet and not arg_21_0:canHeroJoinBattle(arg_21_1) then
		local var_21_0 = var_0_6:translation("OCCULT_DISPATCH_LIMIT_TIP")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_21_0
		})

		return
	end

	local var_21_1 = {}

	if not arg_21_0.isPet then
		var_21_1.partner_id = arg_21_1:getHeroID()
		var_21_1.pos = arg_21_0.index
	else
		var_21_1.pet_id = arg_21_1:getPetID()
	end

	var_21_1.table_id = xyd.AdventureEventType.ILLUSION

	arg_21_0.adventureEvent:pickTeamFight(var_21_1, function(arg_22_0, arg_22_1)
		if arg_22_0 == xyd.error.OK then
			xyd.WindowManager.get():closeWindow(arg_21_0)
		end
	end)
end

function var_0_0.checkCanSelect(arg_23_0, arg_23_1)
	return not arg_23_0.adventureEvent:isHeroSelected(arg_23_1)
end

function var_0_0.didOpen(arg_24_0)
	arg_24_0:addBlockLayer()
	arg_24_0:refreshSelectedHeroClass(var_0_4)
end

function var_0_0.updateList(arg_25_0, ...)
	if arg_25_0.leftMenuType ~= var_0_7.HERO then
		return
	end

	arg_25_0:updateFilterHeros()
	arg_25_0:refreshSelectedHeroClass(5)
end

function var_0_0.updateFilterHeros(arg_26_0)
	arg_26_0.totalHero_[xyd.DistanceType.FILTER] = {}

	local var_26_0 = {
		0,
		0,
		0
	}
	local var_26_1 = {
		0,
		0,
		0
	}
	local var_26_2 = {
		0,
		0,
		0,
		0
	}

	if arg_26_0.selfPlayer.sortType and arg_26_0.selfPlayer.sortType > 0 then
		local var_26_3 = {}
		local var_26_4 = arg_26_0.selfPlayer.sortType
		local var_26_5 = 1

		while var_26_4 > 0 do
			var_26_3[var_26_5] = var_26_4 % 2
			var_26_5 = var_26_5 + 1
			var_26_4 = math.floor(var_26_4 / 2)
		end

		local var_26_6 = 1

		for iter_26_0 = 10, 1, -1 do
			if iter_26_0 <= 4 then
				if iter_26_0 == 4 then
					var_26_6 = 1
				end

				var_26_2[var_26_6] = var_26_3[iter_26_0]
			elseif iter_26_0 <= 7 then
				if iter_26_0 == 7 then
					var_26_6 = 1
				end

				var_26_1[var_26_6] = var_26_3[iter_26_0]
			elseif iter_26_0 <= 10 and var_26_3[iter_26_0] then
				var_26_0[var_26_6] = var_26_3[iter_26_0]
			end

			var_26_6 = var_26_6 + 1
		end
	else
		var_26_0 = {
			1,
			1,
			1
		}
		var_26_1 = {
			1,
			1,
			1
		}
		var_26_2 = {
			1,
			1,
			1,
			1
		}
	end

	for iter_26_1, iter_26_2 in pairs(arg_26_0.heros_) do
		if var_26_0[iter_26_2:getDistanceType() - 1] == 1 and var_26_1[iter_26_2:getHeroType()] == 1 and var_26_2[iter_26_2:getFromType()] == 1 and arg_26_0:canHeroJoinBattle(iter_26_2) then
			table.insert(arg_26_0.totalHero_[xyd.DistanceType.FILTER], iter_26_2)
		end
	end
end

function var_0_0.getPetID(arg_27_0, arg_27_1)
	if arg_27_0.adventureEvent:checkIsMaster(arg_27_0.selfPlayer.playerID) then
		if arg_27_0.isPet then
			return tonumber(arg_27_1:getTableID())
		else
			return tonumber(arg_27_0.adventureEvent.teamInfo.master_pet)
		end
	else
		return 0
	end
end

return var_0_0
