local var_0_0 = class("PetCollectWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = 1
local var_0_4 = require("framework.scheduler")
local var_0_5 = "pet_collect"
local var_0_6 = import("app.common.ui.SpineEffect")
local var_0_7 = xyd.tables.translation
local var_0_8 = xyd.tables.hero
local var_0_9 = 3
local var_0_10 = 1
local var_0_11 = 2
local var_0_12 = 3

function var_0_0.willOpen(arg_1_0, arg_1_1)
	arg_1_0:addTopSidebar()
	arg_1_0:nodeByName("top_sidebar"):setLocalZOrder(-1)
	arg_1_0:nodeByName("eco_sidebar"):setVisible(false)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_1_0.selfPlayer.collectedPets and #arg_1_0.selfPlayer.collectedPets == 0 then
		arg_1_0.selfPlayer.petGuideId = 2
	end

	arg_1_0:scheduleHandler()
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	arg_2_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.scheduleHandler(arg_3_0)
	arg_3_0.handler = var_0_4.scheduleUpdateGlobal(handler(arg_3_0, arg_3_0.loop))
end

function var_0_0.loop(arg_4_0)
	arg_4_0.count = arg_4_0.count or 0

	if tolua.isnull(arg_4_0) then
		if arg_4_0.handler ~= nil then
			var_0_4.unscheduleGlobal(arg_4_0.handler)

			arg_4_0.handler = nil
		end
	elseif arg_4_0.count < 1 then
		arg_4_0.count = arg_4_0.count + 1
	elseif arg_4_0.count < 2 then
		arg_4_0:update()
		arg_4_0:sortTables()
		arg_4_0:initButtons()

		arg_4_0.count = arg_4_0.count + 1
	else
		arg_4_0:layout()

		arg_4_0.selectedHeroClass_ = xyd.DistanceType.ALL

		arg_4_0:refreshSelectedHeroClass()
		arg_4_0:setTouchSwallowEnabled(false)

		if xyd.StoryData.get():getGuideID() <= xyd.GuideStoryType.GUIDE_PET_ONE then
			if arg_4_0.selfPlayer.petGuideId == 2 then
				if arg_4_0.heroCells_[1].pet:isCollected() then
					if arg_4_0.heroCells_[1].pet.is_show_ == 0 then
						arg_4_0.selfPlayer:setPetGuideId()
						arg_4_0:playGuide(var_0_11)
					else
						arg_4_0.selfPlayer:setPetGuideId()
						arg_4_0.selfPlayer:setPetGuideId()
						arg_4_0:playGuide(var_0_12)
					end
				else
					arg_4_0:playGuide(var_0_10)
				end
			end
		elseif xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_PET_TWO then
			arg_4_0:playGuide(var_0_10)
		end

		if arg_4_0.handler ~= nil then
			var_0_4.unscheduleGlobal(arg_4_0.handler)

			arg_4_0.handler = nil
		end
	end
end

function var_0_0.update(arg_5_0)
	local var_5_0
	local var_5_1

	if not arg_5_0.petName and arg_5_0.filterParams and next(arg_5_0.filterParams) then
		var_5_0 = arg_5_0.filterParams.attrFilter
		var_5_1 = arg_5_0.filterParams.awakeFilter
	end

	arg_5_0.totalHero_ = {}
	arg_5_0.unCollected_ = {}
	arg_5_0.totalIDs_ = {}

	if arg_5_0.selfPlayer.collectedPets == nil then
		arg_5_0.selfPlayer.collectedPets = {}
	end

	for iter_5_0, iter_5_1 in pairs(arg_5_0.selfPlayer.collectedPets) do
		arg_5_0.totalIDs_[iter_5_1:getTableID()] = iter_5_1
	end

	for iter_5_2, iter_5_3 in pairs(xyd.tables.hero:getPetsIgnoreShow()) do
		local var_5_2

		if arg_5_0.totalIDs_[iter_5_3] ~= nil then
			var_5_2 = arg_5_0.totalIDs_[iter_5_3]
		else
			var_5_2 = var_0_2.new()

			var_5_2:initUnCollected(iter_5_3)

			if (var_5_2:isHasEgg() == true or var_5_2:isShow()) and not var_5_2:isAwaken() and not arg_5_0.totalIDs_[var_5_2:afterAwakenID()] then
				-- block empty
			else
				var_5_2 = nil
			end
		end

		if var_5_2 and arg_5_0.petName and not xyd.searchHeroByName(arg_5_0.petName, var_5_2) then
			var_5_2 = nil
		end

		if var_5_2 then
			local var_5_3 = false

			if not var_5_3 and var_5_0 then
				var_5_3 = true

				local var_5_4 = xyd.tables.hero:getHolyAttr(iter_5_3)

				for iter_5_4 = 1, #var_5_4 do
					if var_5_0[var_5_4[iter_5_4]] == 1 then
						var_5_3 = false

						break
					end
				end
			end

			if not var_5_3 and var_5_1 then
				local var_5_5

				if var_5_2:isCanAwaken() then
					var_5_5 = xyd.HeroAwakeType.AWAKE
				else
					var_5_5 = xyd.HeroAwakeType.NO_AWAKE
				end

				if not string.find(var_5_1, tostring(var_5_5)) then
					var_5_3 = true
				end
			end

			if not var_5_3 then
				if arg_5_0.totalIDs_[iter_5_3] ~= nil or var_5_2:canSummon() then
					table.insert(arg_5_0.totalHero_, var_5_2)
				else
					table.insert(arg_5_0.unCollected_, var_5_2)
				end
			end
		end
	end

	arg_5_0:sortTables()
	arg_5_0:updateButtons()
end

function var_0_0.scrollToHero(arg_6_0, arg_6_1)
	local var_6_0
	local var_6_1 = arg_6_0.totalHero_

	for iter_6_0, iter_6_1 in pairs(var_6_1) do
		if iter_6_1.heroID_ == arg_6_1 then
			var_6_0 = iter_6_0

			break
		end
	end

	if not var_6_0 then
		return
	end

	if var_6_0 > 3 and var_6_0 < #var_6_1 - 3 and #var_6_1 >= 6 then
		arg_6_0.heroList_:scrollTo(-(var_6_0 - 4) * 185 - 126, 0)
	elseif var_6_0 >= #var_6_1 - 3 and #var_6_1 >= 6 then
		arg_6_0.heroList_:scrollTo(-(#var_6_1 - 6) * 185 - 60, 0)
	elseif var_6_0 < 3 then
		arg_6_0.heroList_:scrollTo(0, 0)
	end
end

function var_0_0.sortTables(arg_7_0)
	table.sort(arg_7_0.totalHero_, function(arg_8_0, arg_8_1)
		local var_8_0 = arg_8_0.tableID_ < arg_8_1.tableID_ and 1 or 0
		local var_8_1 = arg_8_0.tableID_ > arg_8_1.tableID_ and 1 or 0
		local var_8_2 = arg_8_0.color_ > arg_8_1.color_ and 2 or 0
		local var_8_3 = arg_8_0.color_ < arg_8_1.color_ and 2 or 0
		local var_8_4 = arg_8_0.star_ > arg_8_1.star_ and 4 or 0
		local var_8_5 = arg_8_0.star_ < arg_8_1.star_ and 4 or 0
		local var_8_6 = arg_8_0.level_ > arg_8_1.level_ and 8 or 0
		local var_8_7 = arg_8_0.level_ < arg_8_1.level_ and 8 or 0
		local var_8_8 = (arg_8_0:canSummon() or arg_8_0.time_ ~= nil) and 16 or 0
		local var_8_9 = (arg_8_1:canSummon() or arg_8_1.time_ ~= nil) and 16 or 0
		local var_8_10 = var_8_0 + var_8_2 + var_8_4 + var_8_6 + var_8_8
		local var_8_11 = var_8_1 + var_8_3 + var_8_5 + var_8_7 + var_8_9

		if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_PET_THREE then
			var_8_10 = var_8_2 + var_8_4 + var_8_6
			var_8_11 = var_8_3 + var_8_5 + var_8_7
		end

		return var_8_11 < var_8_10
	end)
	table.sort(arg_7_0.unCollected_, function(arg_9_0, arg_9_1)
		if arg_9_0:getSuiPian() / xyd.TotalStarSuipian[arg_9_0:getStar()] ~= arg_9_1:getSuiPian() / xyd.TotalStarSuipian[arg_9_1:getStar()] then
			return arg_9_0:getSuiPian() / xyd.TotalStarSuipian[arg_9_0:getStar()] > arg_9_1:getSuiPian() / xyd.TotalStarSuipian[arg_9_1:getStar()]
		else
			return arg_9_0:getSuiPian() > arg_9_1:getSuiPian()
		end
	end)
end

function var_0_0.layout(arg_10_0)
	local var_10_0 = arg_10_0:nodeByName("hero_list_layer")
	local var_10_1 = var_10_0:getContentSize().width
	local var_10_2 = var_10_0:getContentSize().height

	arg_10_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_10_1, var_10_2 - 4),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_10_0):onScroll(handler(arg_10_0, arg_10_0.scrollListener))

	arg_10_0.heroList_:setTouchSwallowEnabled(false)
	var_10_0:setTouchSwallowEnabled(false)

	arg_10_0.heroCells_ = {}
	arg_10_0.cellsByHeroID = {}

	arg_10_0.heroList_:setDelegate(handler(arg_10_0, arg_10_0.heroDelegate))

	arg_10_0.scrollx = 0

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_10_0):addEventListener(xyd.event.PET_UPDATE_HATCH, function(arg_11_0)
		arg_10_0:updateTime()
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_10_0):addEventListener(xyd.event.PETS_UPDATE, function(arg_12_0)
		arg_10_0:update()
		arg_10_0.heroList_:reload()
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_10_0):addEventListener(xyd.event.PET_UPDATE_HOME_STYLE, function(arg_13_0)
		arg_10_0.heroList_:reload()
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_10_0):addEventListener(xyd.event.PET_SEARCH, function(arg_14_0)
		if arg_14_0 and arg_14_0.petName and arg_14_0.petName ~= var_0_7:translation("PET_SEARCH_TIPS") then
			arg_10_0.petName = arg_14_0.petName
			arg_10_0.filterParams = nil

			arg_10_0:update()
			arg_10_0:refreshSelectedHeroClass()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_10_0):addEventListener(xyd.event.PET_FILTER, function(arg_15_0)
		if arg_15_0 and arg_15_0.filterParams then
			arg_10_0.filterParams = arg_15_0.filterParams
			arg_10_0.petName = nil

			arg_10_0:update()
			arg_10_0:refreshSelectedHeroClass()
		end
	end)
end

function var_0_0.initButtons(arg_16_0)
	arg_16_0:nodeByName("txt_filter"):setString(var_0_7:translation("FILTER_TEXT"))
	arg_16_0:nodeByName("txt_filter_active"):setString(var_0_7:translation("FILTER_TEXT"))
	arg_16_0:nodeByName("txt_search"):setString(var_0_7:translation("HERO_LIST_BTN_SEARCH"))
	arg_16_0:nodeByName("txt_all"):setString(var_0_7:translation("TOTAL_TEXT"))
	arg_16_0:nodeByName("txt_all_active"):setString(var_0_7:translation("TOTAL_TEXT"))
	arg_16_0:nodeByName("btn_filter"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended and not arg_16_0.isSummon then
			xyd.playButtonSound()
			arg_16_0:nodeByName("btn_filter_active"):setVisible(true)
			arg_16_0:nodeByName("btn_filter"):setVisible(false)
			arg_16_0:nodeByName("btn_all"):setVisible(true)
			arg_16_0:nodeByName("btn_all_active"):setVisible(false)
			xyd.WindowManager.get():openWindow("pet_filter")
		end
	end)
	arg_16_0:nodeByName("btn_filter_active"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.ended and not arg_16_0.isSummon then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("pet_filter")
		end
	end)
	arg_16_0:nodeByName("btn_search"):addTouchEventListener(function(arg_19_0, arg_19_1)
		if arg_19_1 == ccui.TouchEventType.ended and not arg_16_0.isSummon then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("pet_search")
		end
	end)
	arg_16_0:nodeByName("btn_all"):addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.ended and not arg_16_0.isSummon then
			xyd.playButtonSound()

			arg_16_0.filterParams = nil
			arg_16_0.petName = nil

			arg_16_0:update()
			arg_16_0:refreshSelectedHeroClass()
		end
	end)
	arg_16_0:nodeByName("btn_all_active"):addTouchEventListener(function(arg_21_0, arg_21_1)
		if arg_21_1 == ccui.TouchEventType.ended and not arg_16_0.isSummon then
			xyd.playButtonSound()

			arg_16_0.filterParams = nil
			arg_16_0.petName = nil

			arg_16_0:update()
			arg_16_0:refreshSelectedHeroClass()
		end
	end)
end

function var_0_0.updateButtons(arg_22_0)
	btnFilter = arg_22_0:nodeByName("btn_filter")
	btnFilterActive = arg_22_0:nodeByName("btn_filter_active")
	btnAll = arg_22_0:nodeByName("btn_all")
	btnAllActive = arg_22_0:nodeByName("btn_all_active")

	if arg_22_0.petName then
		btnFilter:setVisible(true)
		btnFilterActive:setVisible(false)
		btnAll:setVisible(true)
		btnAllActive:setVisible(false)
	elseif arg_22_0.filterParams then
		btnFilter:setVisible(false)
		btnFilterActive:setVisible(true)
		btnAll:setVisible(true)
		btnAllActive:setVisible(false)
	else
		btnFilter:setVisible(true)
		btnFilterActive:setVisible(false)
		btnAll:setVisible(false)
		btnAllActive:setVisible(true)
	end
end

function var_0_0.updateTime(arg_23_0)
	for iter_23_0, iter_23_1 in pairs(arg_23_0.totalHero_) do
		local var_23_0 = arg_23_0.cellsByHeroID[iter_23_1:getTableID()]

		if var_23_0 ~= nil and var_23_0.is_load then
			local var_23_1 = var_23_0:getChildByName("cell")
			local var_23_2 = var_23_1:getChildByName("layout")
			local var_23_3 = var_23_2:getChildByName("time_container")
			local var_23_4 = var_23_3:getChildByName("time_text")

			var_23_4:enableOutline(cc.c4b(24, 41, 70, 255), 2)

			if iter_23_1.is_show_ == 0 and iter_23_1.time_ ~= nil then
				var_23_3:setVisible(true)

				if var_23_3:getChildByName("egg_effect") == nil then
					local var_23_5 = "skeletons/ui_effect/common_summon_pet/common_summon_pet01"
					local var_23_6 = var_23_5 .. ".json"
					local var_23_7 = var_23_5 .. ".atlas"
					local var_23_8 = var_0_6.new(var_23_6, var_23_7, 1)

					var_23_8:align(display.CENTER, 132, 69)
					var_23_8:play(nil, true)
					var_23_8:setName("egg_effect")
					var_23_3:addChild(var_23_8, 100)
				end

				local var_23_9 = math.floor(iter_23_1.time_ / 3600)
				local var_23_10 = math.floor(iter_23_1.time_ / 60) % 60
				local var_23_11 = iter_23_1.time_ % 60

				var_23_4:setString(string.format("%02d:%02d:%02d", var_23_9, var_23_10, var_23_11))
			else
				if iter_23_1.is_show_ == 1 then
					if var_23_2:getChildByName("card"):getChildByName("egg") then
						local var_23_12 = "skeletons/ui_effect/effect_petegg/effect_petegg"
						local var_23_13 = var_23_12 .. ".json"
						local var_23_14 = var_23_12 .. ".atlas"
						local var_23_15 = var_0_6.new(var_23_13, var_23_14, 1)

						var_23_15:align(display.CENTER, var_23_1:getWidth() / 2, var_23_1:getHeight() / 4)
						var_23_1:addChild(var_23_15, 1)
						var_23_15:play(nil, false)
						var_0_4.performWithDelayGlobal(function()
							if xyd.WindowManager.get():getWindow("pet_collect") then
								arg_23_0:updateHeroModel(iter_23_1, var_23_2:getChildByName("card"))
								arg_23_0:updateHeroHouse(iter_23_1, var_23_2)
							end
						end, 0.9)
					else
						arg_23_0:updateHeroModel(iter_23_1, var_23_2:getChildByName("card"))
					end
				end

				var_23_3:setVisible(false)

				if var_23_3:getChildByName("egg_effect") then
					var_23_3:getChildByName("egg_effect"):stop()
				end
			end
		end
	end
end

function var_0_0.playGuide(arg_25_0, arg_25_1)
	local var_25_0
	local var_25_1 = 0
	local var_25_2 = 0
	local var_25_3 = 2

	if xyd.WindowManager.get():getWindow("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	if arg_25_1 == var_0_10 then
		var_25_0 = arg_25_0.heroCells_[1]
		var_25_1 = -100
		var_25_2 = -100
	elseif arg_25_1 == var_0_11 then
		var_25_0 = arg_25_0.heroCells_[1]:getChildByName("cell"):getChildByName("layout"):getChildByName("time_container"):getChildByName("time_icon")
	elseif arg_25_1 == var_0_12 then
		var_25_0 = arg_25_0:nodeByName("top_sidebar"):nodeByName("return_btn")
		var_25_3 = 1
	end

	local var_25_4 = var_25_0:getPositionX()
	local var_25_5 = var_25_0:getPositionY()

	xyd.WindowManager.get():openWindow("guide")
	arg_25_0.heroList_.touchNode_:setTouchEnabled(false)

	local var_25_6 = xyd.WindowManager.get():getWindow("guide")
	local var_25_7 = var_25_6:convertToNodeSpace(var_25_0:getParent():convertToWorldSpace(cc.p(var_25_4, var_25_5)))

	var_25_6:addNode()
	var_25_6:setStencil(var_25_0:getContentSize().width + var_25_1, var_25_0:getContentSize().height + var_25_2, var_25_7.x, var_25_7.y, var_25_3)
end

function var_0_0.scrollListener(arg_26_0, arg_26_1)
	if arg_26_1.name == "began" then
		arg_26_0.startClick_ = true
		arg_26_0.prevX_ = arg_26_1.x
	elseif arg_26_1.name == "moved" then
		arg_26_0.scrollx = arg_26_0.heroList_:getScrollNode():getPositionX()

		if 20 <= math.abs(arg_26_1.x - arg_26_0.prevX_) then
			arg_26_0.startClick_ = false
		end
	elseif arg_26_1.name == "scrollEnd" then
		arg_26_0.scrollx = arg_26_0.heroList_:getScrollNode():getPositionX()
	end
end

function var_0_0.initHeroCell(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	local function var_27_0()
		local var_28_0 = "windows/common/small_yellow_star.png"

		return xyd.AssetLoader.get():loadSprite(var_28_0)
	end

	local var_27_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petCollectWindow/pet_list_item.csb")
	local var_27_2 = var_27_1:getChildByName("item_bg"):getContentSize()

	var_27_1:setContentSize(var_27_2.width, var_27_2.height)
	arg_27_1:setContentSize(var_27_2.width, var_27_2.height)

	if arg_27_3 and arg_27_2 > #arg_27_0.totalHero_ or not arg_27_3 and arg_27_2 > #arg_27_0.unCollected_ then
		return
	end

	var_27_1:setPosition(cc.p(0, 0))
	arg_27_1:addChild(var_27_1)
	var_27_1:setName("layout")

	local var_27_3

	if arg_27_3 then
		var_27_3 = arg_27_0.totalHero_[arg_27_2]
	else
		var_27_3 = arg_27_0.unCollected_[arg_27_2]
	end

	arg_27_1.heroID = var_27_3:getTableID()
	arg_27_1.pet = var_27_3
	arg_27_1.nameLabel_ = var_27_1:getChildByName("name_text")

	arg_27_1.nameLabel_:setString(var_27_3:getName())

	local var_27_4 = xyd.AssetLoader.get():loadSprite("images/card_mask2.png")

	var_27_4:align(display.LEFT_BOTTOM, 0, 0)

	local var_27_5 = cc.ClippingNode:create()

	var_27_5:setStencil(var_27_4)
	var_27_5:setInverted(true)
	var_27_5:setAlphaThreshold(0)
	var_27_5:setName("clipper")

	if var_27_3:isCollected() then
		if var_27_3.is_show_ == 1 then
			arg_27_0:updateHeroModel(var_27_3, var_27_1:getChildByName("card"))
			arg_27_0:updateHeroHouse(var_27_3, var_27_1)
			var_27_1:getChildByName("time_container"):setVisible(false)
		else
			arg_27_0:modelShowEgg(var_27_3, var_27_1:getChildByName("card"))
		end

		local var_27_6 = var_27_1:getChildByName("bar_text")

		var_27_6:enableOutline(cc.c4b(51, 31, 31, 255), 3)

		local var_27_7 = var_27_1:getChildByName("stone_bar")
		local var_27_8 = 100

		if var_27_3:getStar() >= xyd.MAX_STAR_LEVEL then
			var_27_6:setString(xyd.tables.translation:translation("HERO_MAIN_MAX_STAR"))

			var_27_8 = 100
		else
			var_27_6:setString(var_27_3:getSuiPian() .. " / " .. xyd.StarLevelSuipian[var_27_3:getStar() + 1])

			var_27_8 = math.min(var_27_3:getSuiPian() / xyd.StarLevelSuipian[var_27_3:getStar() + 1] * 100, 100)
		end

		var_27_7:setPercent(var_27_8)

		local var_27_9 = display.newNode()
		local var_27_10 = display.newNode()

		var_27_9:size(var_27_1:getWidth(), 120)
		var_27_10:size(var_27_1:getWidth(), 120)
		var_27_9:align(display.LEFT_BOTTOM, 0, 0):addTo(var_27_1)
		var_27_10:align(display.LEFT_BOTTOM, 0, 0):addTo(var_27_1)

		for iter_27_0 = 1, var_0_9 do
			if var_27_3.is_show_ == 1 then
				local var_27_11 = var_27_1:getChildByName("house_container")
				local var_27_12 = var_27_3:getEquipByIndexShow(iter_27_0)
				local var_27_13 = var_27_11:getChildByName("equip_bg_" .. iter_27_0)
				local var_27_14 = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
				local var_27_15 = var_27_13:getChildByName("hero_collect_hide")

				if var_27_15 then
					var_27_15:setVisible(false)
				end

				if var_27_12:isCollected() then
					local var_27_16 = var_27_12:getIcon()

					xyd.displaySpriteOnContainer(var_27_16, var_27_13, true)
				elseif var_27_12:getTableID() == 0 then
					var_27_15:setVisible(true)
				elseif iter_27_0 == 1 and var_27_3:isCanAwaken() and not var_27_14:isAwaking(var_27_3:getTableID(), xyd.AwakeType.PET) and xyd.tables.item:isAwakenItem(var_27_12:getTableID()) == 1 and arg_27_0.selfPlayer.maxTeamLev >= 90 then
					var_27_15:setVisible(true)

					if not var_27_14:isHasAwakeOpen(xyd.AwakeType.PET) and var_27_3:getLevel() >= xyd.tables.misc.awakenOpenLev then
						local var_27_17 = "skeletons/ui_effect/effect_awaken_item/effect_awaken_item_new"
						local var_27_18 = var_0_6.new(var_27_17 .. ".json", var_27_17 .. ".atlas", 1)

						var_27_18:addTo(var_27_13)
						var_27_18:setAnchorPoint(cc.p(0.5, 0.5))
						var_27_18:setPosition(var_27_13:getWidth() / 2, var_27_13:getHeight() / 2)
						var_27_18:play(nil, true)
					end
				elseif (var_27_3:isHasItem(iter_27_0) or var_27_3:canComposeItem(iter_27_0)) and var_27_3:getLevel() >= var_27_12:getLevel() then
					local var_27_19 = xyd.AssetLoader.get():loadSprite("windows/common/add_blue.png")

					var_27_19:align(display.CENTER, var_27_13:getX(), var_27_13:getY()):addTo(var_27_10)
					var_27_19:scale(var_27_13:getWidth() / var_27_19:getWidth() / 3)
				elseif (var_27_3:isHasItem(iter_27_0) or var_27_3:canComposeItem(iter_27_0)) and var_27_3:getLevel() < var_27_12:getLevel() then
					local var_27_20 = xyd.AssetLoader.get():loadSprite("windows/common/add_yellow.png")

					var_27_20:align(display.CENTER, var_27_13:getX(), var_27_13:getY()):addTo(var_27_9)
					var_27_20:scale(var_27_13:getWidth() / var_27_20:getWidth() / 3)
				end
			end
		end

		local var_27_21 = var_27_1:getChildByName("time_container"):getChildByName("time_icon")

		var_27_21:setTouchEnabled(true)
		var_27_21:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_29_0)
			if arg_29_0.name == "began" then
				return true
			elseif arg_29_0.name == "ended" and var_27_3.time_ ~= nil then
				local var_29_0 = math.floor((2 * var_0_8:getHatchTime(var_27_3:getTableID()) * var_27_3.time_ - var_27_3.time_ * var_27_3.time_) / xyd.tables.misc.petHatchCostParam)

				if arg_27_0.selfPlayer.petGuideId > 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_7:translation("PET_GUIDE_CLEAR_CD_ALERT")
					})

					if xyd.WindowManager.get():isWindowOpen("guide") then
						xyd.WindowManager.get():closeWindow("guide")
					end

					var_27_3:clearCD(function(arg_30_0)
						if arg_30_0 == xyd.error.OK then
							if arg_27_0.selfPlayer.petGuideId == 3 then
								arg_27_0.selfPlayer:setPetGuideId()
								arg_27_0:playGuide(var_0_12)
							end

							arg_27_0:update()
							arg_27_0.heroList_:reload()
						end
					end)
				elseif var_29_0 > arg_27_0.selfPlayer.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_7:translation("ZUANSHI_ABSENCE"), function()
						local var_31_0 = {}

						var_31_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_31_0)
					end, nil, nil, arg_27_0.colorMode)
				else
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_7:translation("PET_CLEAR_CD_ALERT"), var_29_0), function()
						var_27_3:clearCD(function(arg_33_0, arg_33_1)
							if arg_33_0 == xyd.error.OK then
								arg_27_0:update()
								arg_27_0.heroList_:reload()
							end
						end)
					end, nil, nil, arg_27_0.colorMode)
				end
			end
		end)
	else
		var_27_1:getChildByName("time_container"):setVisible(false)

		local var_27_22 = var_27_1:getChildByName("stone_bar")
		local var_27_23 = var_27_1:getChildByName("bar_text")

		var_27_23:enableOutline(cc.c4b(51, 31, 31, 255), 3)

		local var_27_24 = ""

		if var_27_3:isHasEgg() == true then
			arg_27_0:modelShowEgg(var_27_3, var_27_1:getChildByName("card"))

			var_27_24 = xyd.tables.translation:translation("HERO_KEZHAOHUAN")

			var_27_22:setPercent(100)
		else
			arg_27_0:modelShowEgg(var_27_3, var_27_1:getChildByName("card"), true)

			var_27_24 = var_27_3:getSuiPian() .. " / " .. xyd.TotalStarSuipian[var_27_3:getStar()]

			var_27_22:setPercent(math.min(var_27_3:getSuiPian() / xyd.TotalStarSuipian[var_27_3:getStar()] * 100, 100))
		end

		var_27_23:setString(var_27_24)
	end

	if not var_27_3:isCollected() and var_27_3:isHasEgg() == true then
		local var_27_25 = "skeletons/ui_effect/common_summon_pet/common_summon_pet03"
		local var_27_26 = var_27_25 .. ".json"
		local var_27_27 = var_27_25 .. ".atlas"
		local var_27_28 = var_0_6.new(var_27_26, var_27_27, 1)

		var_27_28:align(display.CENTER, arg_27_1:getWidth() / 2 - 2, arg_27_1:getHeight() / 4 - 2)
		arg_27_1:addChild(var_27_28, 1)
		var_27_28:play(nil, true)
	end

	local var_27_29 = display.newNode()

	var_27_29:setContentSize(var_27_2)
	var_27_29:addTo(arg_27_1)
	var_27_29:setName("touchNode")
	var_27_29:setTouchEnabled(true)
	var_27_29:setTouchSwallowEnabled(false)
	var_27_29:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_34_0)
		if arg_34_0.name == "began" then
			arg_27_0.prevX_ = arg_34_0.x
			arg_27_0.prevY_ = arg_34_0.y
			arg_27_0.startClick_ = true
		elseif arg_34_0.name == "moved" then
			if math.abs(arg_34_0.y - arg_27_0.prevY_) > 5 or math.abs(arg_34_0.x - arg_27_0.prevX_) > 5 then
				arg_27_0.startClick_ = false
			end
		elseif arg_34_0.name == "ended" and arg_27_0.startClick_ then
			if xyd.WindowManager.get():isWindowOpen("guide") then
				xyd.WindowManager.get():closeWindow("guide")
				arg_27_0.heroList_.touchNode_:setTouchEnabled(true)
			end

			if var_27_3:isCollected() then
				var_27_3 = arg_27_0.totalHero_[arg_27_2]

				xyd.playButtonSound()

				if var_27_3.is_show_ == 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_7:translation("PET_IS_IN_EGG")
					})
				else
					if var_27_3.is_show_ == 0 then
						var_27_3.is_show_ = 1

						var_27_3:setShow(function(arg_35_0, arg_35_1)
							return
						end, pet:getPetID())
					end

					if arg_27_0.selfPlayer.petGuideId == 3 and xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_PET_ONE then
						arg_27_0.selfPlayer:setPetGuideId()
						arg_27_0:playGuide(var_0_12)
					else
						xyd.WindowManager.get():openWindow("pet_main", {
							heros = arg_27_0.totalHero_,
							current = arg_27_2,
							scrollx = arg_27_0.scrollx
						})
					end
				end
			elseif var_27_3:isHasEgg() == true then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_7:translation("PET_BEGIN_MAKE"), function()
					arg_27_0:summonHero(var_27_3)
				end, {
					lcallback = function()
						if arg_27_0.selfPlayer.petGuideId == 2 then
							arg_27_0:playGuide(var_0_10)
						end
					end
				}, nil, arg_27_0.colorMode)
			else
				local var_34_0 = xyd.tables.hero:stoneID(var_27_3:getTableID())

				xyd.WindowManager.get():openWindow("pet_stone", {
					hero = var_27_3,
					itemComposeID = var_34_0
				})
			end
		end

		return true
	end)
end

function var_0_0.modelShowEgg(arg_38_0, arg_38_1, arg_38_2, arg_38_3)
	local var_38_0 = arg_38_1:getTableID()
	local var_38_1 = var_0_8:getEggImg(var_38_0)
	local var_38_2

	arg_38_2:removeAllChildren()

	local var_38_3 = xyd.AssetLoader.get():loadSprite(var_38_1)

	var_38_3:setTouchSwallowEnabled(false)
	var_38_3:setName("egg")

	local var_38_4 = arg_38_2:getContentSize().width / 2
	local var_38_5 = arg_38_2:getContentSize().height / 2

	var_38_3:setPosition(cc.p(var_38_4, var_38_5 - 20))
	var_38_3:addTo(arg_38_2)
end

function var_0_0.updateHeroModel(arg_39_0, arg_39_1, arg_39_2)
	if arg_39_2.is_load == nil then
		if not arg_39_2 or tolua.isnull(arg_39_2) then
			return
		end

		arg_39_2.is_load = true

		local var_39_0 = arg_39_1:getHeroModel()

		var_39_0:setTouchSwallowEnabled(false)

		if arg_39_2 and not tolua.isnull(arg_39_2) then
			local var_39_1 = arg_39_2:getContentSize().width / 2

			var_39_0:setPosition(cc.p(var_39_1, 0))
			arg_39_2:removeAllChildren()
			var_39_0:addTo(arg_39_2)
		end
	end
end

function var_0_0.summonHero(arg_40_0, arg_40_1)
	arg_40_1:stoneSummonHero(function(arg_41_0)
		if arg_41_0 == xyd.error.OK then
			local var_41_0 = {
				toStone = false,
				partnerID = arg_40_1:getTableID()
			}

			if arg_40_0.selfPlayer.petGuideId == 2 then
				arg_40_0.selfPlayer:setPetGuideId()
				arg_40_0:playGuide(var_0_11)
			end

			arg_40_0:update()
			arg_40_0.heroList_:reload()
		end
	end)
end

function var_0_0.updateHeroHouse(arg_42_0, arg_42_1, arg_42_2)
	local var_42_0 = arg_42_2:getChildByName("house_container")

	arg_42_2:getChildByName("item_bg"):setVisible(false)
	var_42_0:getChildByName("bg_lev"):setVisible(false)
	var_42_0:setVisible(true)

	local var_42_1
	local var_42_2

	if arg_42_1:isHomeSkinOn() then
		arg_42_2:getChildByName("item_bg"):setVisible(false)

		local var_42_3 = xyd.tables.hero:getPetHomeColor(arg_42_1:getTableID())
		local var_42_4 = xyd.tables.hero:getPetLevTxtColor(arg_42_1:getTableID())

		if var_42_3 and next(var_42_3) and #var_42_3 == 2 then
			local var_42_5 = xyd.split(var_42_3[1], ",")
			local var_42_6 = xyd.split(var_42_3[2], ",")
			local var_42_7 = cc.c4b(var_42_5[1], var_42_5[2], var_42_5[3], var_42_5[4])
			local var_42_8 = cc.c4b(var_42_6[1], var_42_6[2], var_42_6[3], var_42_6[4])

			arg_42_2:getChildByName("name_text"):setColor(var_42_7)
		end

		if var_42_4 and next(var_42_4) and #var_42_4 == 2 then
			local var_42_9 = xyd.split(var_42_4[1], ",")
			local var_42_10 = xyd.split(var_42_4[2], ",")
			local var_42_11 = cc.c4b(var_42_9[1], var_42_9[2], var_42_9[3], var_42_9[4])
			local var_42_12 = cc.c4b(var_42_10[1], var_42_10[2], var_42_10[3], var_42_10[4])

			var_42_0:getChildByName("text_pet_lev"):setColor(var_42_11)
			var_42_0:getChildByName("text_pet_lev"):enableOutline(var_42_12, 2)
		end

		local var_42_13 = arg_42_1:getHomeSkinID()

		var_42_1 = "images/pet_home_styles/" .. var_42_13 .. ".png"
		var_42_2 = "images/pet_home_styles/" .. var_42_13 .. "_lev.png"
	else
		arg_42_2:getChildByName("name_text"):setColor(cc.c4b(72, 37, 85, 255))
		var_42_0:getChildByName("text_pet_lev"):setColor(cc.c4b(54, 17, 69, 255))
		var_42_0:getChildByName("text_pet_lev"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

		var_42_1 = "images/pet_home_styles/item_bg_default.png"
		var_42_2 = "images/pet_home_styles/lev_bg_default.png"
	end

	if var_42_0:getChildByName("home_skin_bg") then
		var_42_0:removeChildByName("home_skin_bg")
	end

	local var_42_14 = xyd.AssetLoader.get():loadSprite(var_42_1)

	var_42_14:addTo(var_42_0, -2)
	var_42_14:setAnchorPoint(cc.p(0, 0))
	var_42_14:setPosition(cc.p(0, 0))
	var_42_14:setName("home_skin_bg")

	if var_42_0:getChildByName("home_lev_bg") then
		var_42_0:removeChildByName("home_lev_bg")
	end

	local var_42_15 = xyd.AssetLoader.get():loadSprite(var_42_2)
	local var_42_16, var_42_17 = var_42_0:getChildByName("bg_lev"):getPosition()

	var_42_15:addTo(var_42_0, -1)
	var_42_15:setAnchorPoint(0.5, 0.5)
	var_42_15:setPosition(var_42_16, var_42_17)
	var_42_15:setName("home_lev_bg")

	for iter_42_0 = 1, var_0_9 do
		if var_42_0:getChildByName("equip_icon_" .. iter_42_0) then
			var_42_0:removeChildByName("equip_icon_" .. iter_42_0)
		end

		local var_42_18 = arg_42_1:getEquipByIndex(iter_42_0)
		local var_42_19 = var_42_0:getChildByName("equip_bg_" .. iter_42_0)
		local var_42_20 = var_42_19:getChildByName("hero_collect_hide")

		if var_42_20 then
			var_42_20:setVisible(false)
		end

		if var_42_18:isCollected() then
			var_42_19:setVisible(false)

			local var_42_21 = cc.p(var_42_19:getPosition())
			local var_42_22 = display.newNode()

			var_42_22:setContentSize(50, 50)
			var_42_22:addTo(arg_42_2:getChildByName("house_container"))
			var_42_22:setAnchorPoint(cc.p(0.5, 0.5))
			var_42_22:setPosition(cc.p(var_42_21))
			var_42_22:setName("equip_icon_" .. iter_42_0)
			xyd.setItemBorder(var_42_22, var_42_18:getTableID())
		else
			var_42_19:setVisible(true)
		end
	end

	var_42_0:getChildByName("text_pet_lev"):setString("LV" .. arg_42_1:getLevel())
end

function var_0_0.heroDelegate(arg_43_0, arg_43_1, arg_43_2, arg_43_3)
	local var_43_0 = #arg_43_0.totalHero_ + #arg_43_0.unCollected_

	if cc.ui.UIListView.COUNT_TAG == arg_43_2 then
		return var_43_0
	elseif cc.ui.UIListView.CELL_TAG == arg_43_2 then
		local var_43_1
		local var_43_2
		local var_43_3
		local var_43_4 = arg_43_0.heroList_:dequeueItem()

		if not var_43_4 then
			var_43_4 = arg_43_0.heroList_:newItem()
		else
			var_43_4:removeAllChildren()
		end

		local var_43_5 = display.newNode()
		local var_43_6 = arg_43_3
		local var_43_7 = display.newNode()

		if arg_43_3 > #arg_43_0.totalHero_ then
			var_43_6 = arg_43_3 - #arg_43_0.totalHero_

			arg_43_0:initHeroCell(var_43_7, var_43_6, false)
		else
			arg_43_0:initHeroCell(var_43_7, var_43_6, true)
		end

		var_43_7:setAnchorPoint(cc.p(0, 0))
		var_43_7:pos(0, 0)
		var_43_5:addChild(var_43_7)
		var_43_7:setName("cell")

		var_43_5.is_load = true
		var_43_5.heroID = var_43_7.heroID
		var_43_5.pet = var_43_7.pet
		arg_43_0.heroCells_[arg_43_3] = var_43_5
		arg_43_0.cellsByHeroID[var_43_7.heroID] = var_43_5

		var_43_5:size(var_43_7:getWidth(), var_43_7:getHeight())
		var_43_4:setItemSize(var_43_5:getWidth(), var_43_7:getHeight())
		var_43_5:align(display.CENTER, var_43_4:getWidth() / 2, var_43_4:getHeight() / 2)
		var_43_4:addContent(var_43_5)

		return var_43_4
	end
end

function var_0_0.refreshSelectedHeroClass(arg_44_0)
	arg_44_0.heroList_:reload()
	import("app.model.GlobalTimer"):onTimer()
end

function var_0_0.onUpdateSmallCard(arg_45_0, arg_45_1)
	local var_45_0 = arg_45_1.heroID
	local var_45_1 = arg_45_0.selfPlayer:getHeroByTableID(var_45_0)

	for iter_45_0, iter_45_1 in pairs(arg_45_0.heroCells_) do
		if iter_45_1.heroID == var_45_0 then
			local var_45_2 = iter_45_1:getChildByName("cell"):getChildByName("layout")
			local var_45_3
			local var_45_4 = xyd.SpriteLoader.new(var_45_1:getSmallCard(), nil, nil, xyd.DefaultImageType.SMALL_CARD)
			local var_45_5 = var_45_2:getChildByName("clipper"):getChildByName("card")

			var_45_5:removeAllChildren()
			xyd.displaySpriteOnContainer(var_45_4, var_45_5, true)
		end
	end
end

function var_0_0.willClose(arg_46_0, arg_46_1)
	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_PET_ONE then
		if arg_46_0.selfPlayer.collectedPets and arg_46_0.selfPlayer.collectedPets[1] and arg_46_0.selfPlayer.collectedPets[1]:isCollected() and arg_46_0.selfPlayer.collectedPets[1].is_show_ == 1 then
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_PET_ONE)
			xyd.StoryData.get():persist()
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.PET_GUIDE_TO_CAMPAIGN
			})
		else
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_ACTION_START,
				params = {}
			})
		end
	else
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_ACTION_START,
			params = {}
		})
	end
end

return var_0_0
