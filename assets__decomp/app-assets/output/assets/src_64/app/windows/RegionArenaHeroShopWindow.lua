local var_0_0 = class("RegionArenaHeroShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 6
local var_0_3 = import("app.model.Hero")
local var_0_4 = 1
local var_0_5 = 6

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
	arg_1_0.heros = clone(arg_1_0.player.heros_)
	arg_1_0.exchangeType = arg_1_2.exchange_type
	arg_1_0.awards = arg_1_0.regionArena.awards
	arg_1_0.isAddStarHeros = {}
	arg_1_0.isAwakeHeros = {}
	arg_1_0.isSummonHeros = {}
	arg_1_0.exchangeTimes = arg_1_0.regionArena.exchangeTimes
	arg_1_0.kingCoin = arg_1_0.player.kingCoin
	arg_1_0.tmpHeros = {}
	arg_1_0.totalHero = {}
	arg_1_0.totalHero[xyd.DistanceType.ALL] = {}
	arg_1_0.totalHero[xyd.DistanceType.QIANPAI] = {}
	arg_1_0.totalHero[xyd.DistanceType.ZHONGPAI] = {}
	arg_1_0.totalHero[xyd.DistanceType.HOUPAI] = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initOtherHero(arg_2_0.awards)
	arg_2_0:initHeros()
	arg_2_0:layout()
	arg_2_0:refreshSelectedHeroClass(var_0_4)
end

function var_0_0.layout(arg_3_0)
	arg_3_0:initMenu()
	arg_3_0:nodeByName("title"):setString(var_0_1:translation("REGION_SHOP_ITEM_" .. arg_3_0.exchangeType))

	local var_3_0 = arg_3_0:nodeByName("hero_container")

	arg_3_0.heroListWidth = var_3_0:getContentSize().width
	arg_3_0.heroListHeight = var_3_0:getContentSize().height
	arg_3_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_0:getWidth() + 20, var_3_0:getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_0):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.heroList_:setDelegate(handler(arg_3_0, arg_3_0.heroDelegate))
end

function var_0_0.initMenu(arg_4_0)
	arg_4_0.heroClassButtons_ = {}

	local var_4_0 = arg_4_0:nodeByName("container")

	table.insert(arg_4_0.heroClassButtons_, arg_4_0:nodeByName("btn_all"))
	table.insert(arg_4_0.heroClassButtons_, arg_4_0:nodeByName("btn_qianpai"))
	table.insert(arg_4_0.heroClassButtons_, arg_4_0:nodeByName("btn_zhongpai"))
	table.insert(arg_4_0.heroClassButtons_, arg_4_0:nodeByName("btn_houpai"))
	arg_4_0:nodeByName("text_all"):setString(var_0_1:translation("ALL_BUTTON"))
	arg_4_0:nodeByName("text_qianpai"):setString(var_0_1:translation("QIANPAI_BUTTON"))
	arg_4_0:nodeByName("text_zhongpai"):setString(var_0_1:translation("ZHONGPAI_BUTTON"))
	arg_4_0:nodeByName("text_houpai"):setString(var_0_1:translation("HOUPAI_BUTTON"))

	for iter_4_0 = 1, #arg_4_0.heroClassButtons_ do
		arg_4_0.heroClassButtons_[iter_4_0]:setZoomScale(0.3)
		arg_4_0.heroClassButtons_[iter_4_0]:addTouchEventListener(function(arg_5_0, arg_5_1)
			if arg_5_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()
				arg_4_0:refreshSelectedHeroClass(iter_4_0)
			end
		end)
	end
end

function var_0_0.refreshSelectedHeroClass(arg_6_0, arg_6_1)
	arg_6_0.heroList_:removeAllItems()

	if arg_6_1 == 1 then
		arg_6_0.tmpHeros = arg_6_0.totalHero[xyd.DistanceType.ALL]
	elseif arg_6_1 == 2 then
		arg_6_0.tmpHeros = arg_6_0.totalHero[xyd.DistanceType.QIANPAI]
	elseif arg_6_1 == 3 then
		arg_6_0.tmpHeros = arg_6_0.totalHero[xyd.DistanceType.ZHONGPAI]
	elseif arg_6_1 == 4 then
		arg_6_0.tmpHeros = arg_6_0.totalHero[xyd.DistanceType.HOUPAI]
	else
		arg_6_0.tmpHeros = arg_6_0.totalHero[xyd.DistanceType.ALL]
	end

	for iter_6_0 = 1, #arg_6_0.heroClassButtons_ do
		if arg_6_1 == iter_6_0 then
			arg_6_0.heroClassButtons_[iter_6_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_6_0.heroClassButtons_[iter_6_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_6_0.heroList_:reload()
end

function var_0_0.initHeros(arg_7_0)
	if arg_7_0.exchangeType == 1 then
		arg_7_0:initAddStarHero()
		arg_7_0:updateHeroAwaken()
	elseif arg_7_0.exchangeType == 2 then
		arg_7_0:updateAddStar()
		arg_7_0:initAwakeHero()
	elseif arg_7_0.exchangeType == 3 then
		arg_7_0:initSummonHero()
	end

	xyd.formatRegionArenaHeros(arg_7_0.tmpHeros)
	arg_7_0:sortTables(arg_7_0.tmpHeros)

	for iter_7_0, iter_7_1 in pairs(arg_7_0.tmpHeros) do
		if iter_7_1:getDistanceType() == xyd.DistanceType.QIANPAI then
			table.insert(arg_7_0.totalHero[xyd.DistanceType.QIANPAI], iter_7_1)
		elseif iter_7_1:getDistanceType() == xyd.DistanceType.ZHONGPAI then
			table.insert(arg_7_0.totalHero[xyd.DistanceType.ZHONGPAI], iter_7_1)
		elseif iter_7_1:getDistanceType() == xyd.DistanceType.HOUPAI then
			table.insert(arg_7_0.totalHero[xyd.DistanceType.HOUPAI], iter_7_1)
		end

		table.insert(arg_7_0.totalHero[xyd.DistanceType.ALL], iter_7_1)
	end
end

function var_0_0.initOtherHero(arg_8_0, arg_8_1)
	for iter_8_0, iter_8_1 in pairs(arg_8_1) do
		if iter_8_1.add_star > 0 then
			table.insert(arg_8_0.isAddStarHeros, iter_8_1)
		end

		if iter_8_1.is_awake == 1 then
			table.insert(arg_8_0.isAwakeHeros, iter_8_1)
		end

		if iter_8_1.is_summon == 1 then
			table.insert(arg_8_0.isSummonHeros, iter_8_1)

			if not arg_8_0:checkHeroExit(arg_8_0.heros, iter_8_1.table_id) then
				local var_8_0 = var_0_3.new()

				var_8_0:initUnCollected(iter_8_1.table_id)
				table.insert(arg_8_0.heros, var_8_0)
			end
		end
	end
end

function var_0_0.initSummonHero(arg_9_0)
	for iter_9_0, iter_9_1 in pairs(xyd.tables.hero:getPartnerDistanceType()) do
		if arg_9_0:checkHeroCanSummon(iter_9_0) then
			local var_9_0 = var_0_3.new()

			var_9_0:initUnCollected(iter_9_0)
			table.insert(arg_9_0.tmpHeros, var_9_0)
		end
	end
end

function var_0_0.initAddStarHero(arg_10_0)
	arg_10_0:updateAddStar()

	for iter_10_0, iter_10_1 in pairs(arg_10_0.heros) do
		if not xyd.isSuperHero(iter_10_1) and iter_10_1:getStar() >= xyd.MAX_STAR_LEVEL or xyd.isSuperHero(iter_10_1) and iter_10_1:getStar() >= xyd.SUPER_HERO_TOTAL_STARS then
			iter_10_1.fullStar = true
		end
	end

	arg_10_0.tmpHeros = arg_10_0.heros
end

function var_0_0.initAwakeHero(arg_11_0)
	arg_11_0:updateHeroAwaken()

	for iter_11_0, iter_11_1 in pairs(arg_11_0.heros) do
		if iter_11_1:isCanAwaken() then
			if iter_11_1:isAwaken() then
				iter_11_1.awakenIsReady = true
			end

			table.insert(arg_11_0.tmpHeros, iter_11_1)
		end
	end
end

function var_0_0.checkHeroExit(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = false

	for iter_12_0, iter_12_1 in pairs(arg_12_1) do
		local var_12_1 = iter_12_1:getTableID()

		if iter_12_1:isAwaken() then
			var_12_1 = iter_12_1:beforeAwakenID()
		end

		if var_12_1 == arg_12_2 then
			var_12_0 = true

			break
		end
	end

	return var_12_0
end

function var_0_0.updateHeroAwaken(arg_13_0)
	local var_13_0 = arg_13_0.isAwakeHeros

	for iter_13_0, iter_13_1 in pairs(var_13_0) do
		local var_13_1 = iter_13_1.table_id

		for iter_13_2, iter_13_3 in pairs(arg_13_0.heros) do
			if var_13_1 == iter_13_3:getTableID() then
				iter_13_3:setTableID(xyd.tables.hero:afterAwaken(var_13_1))

				break
			end
		end
	end
end

function var_0_0.updateAddStar(arg_14_0)
	local var_14_0 = arg_14_0.isAddStarHeros

	for iter_14_0, iter_14_1 in pairs(var_14_0) do
		for iter_14_2, iter_14_3 in pairs(arg_14_0.heros) do
			local var_14_1 = iter_14_3:getTableID()

			if iter_14_3:isAwaken() then
				var_14_1 = iter_14_3:beforeAwakenID()
			end

			if var_14_1 == iter_14_1.table_id then
				local var_14_2 = iter_14_3:getStar() + iter_14_1.add_star

				iter_14_3:setStar(var_14_2)
			end
		end
	end
end

function var_0_0.checkHeroCanSummon(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_0.heros
	local var_15_1 = true

	for iter_15_0, iter_15_1 in pairs(var_15_0) do
		if iter_15_1:getTableID() == arg_15_1 or iter_15_1:beforeAwakenID() == arg_15_1 then
			var_15_1 = false

			break
		end
	end

	if xyd.tables.hero:isSX(arg_15_1) and arg_15_0.player.vip < 9 then
		var_15_1 = false
	end

	if xyd.tables.hero:isExchangeShow(arg_15_1) == false then
		var_15_1 = false
	end

	return var_15_1
end

function var_0_0.sortTables(arg_16_0, arg_16_1)
	table.sort(arg_16_1, function(arg_17_0, arg_17_1)
		if arg_17_0.star_ ~= arg_17_1.star_ then
			return arg_17_0.star_ > arg_17_1.star_
		end
	end)
end

function var_0_0.scrollListener(arg_18_0, arg_18_1)
	if arg_18_1.name == "began" then
		arg_18_0.scrollViewMoved_ = false
		arg_18_0.prevY_ = arg_18_1.y
	elseif arg_18_1.name == "moved" and 0.5 <= math.abs(arg_18_1.y - arg_18_0.prevY_) then
		arg_18_0.scrollViewMoved_ = true
	end
end

function var_0_0.heroDelegate(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	if cc.ui.UIListView.COUNT_TAG == arg_19_2 then
		return (math.ceil(#arg_19_0.tmpHeros / var_0_2))
	elseif cc.ui.UIListView.CELL_TAG == arg_19_2 then
		local var_19_0 = arg_19_0.heroList_:dequeueItem()

		if not var_19_0 then
			var_19_0 = arg_19_0.heroList_:newItem()
		else
			var_19_0:removeAllChildren(true)
		end

		local var_19_1 = 763
		local var_19_2 = 130

		var_19_0:setItemSize(var_19_1, 130)

		local var_19_3 = display.newNode()

		var_19_3:setContentSize(var_19_1, 130)

		for iter_19_0 = 1, var_0_2 do
			local var_19_4 = (arg_19_3 - 1) * var_0_2 + iter_19_0

			if var_19_4 > #arg_19_0.tmpHeros then
				break
			end

			local var_19_5 = display.newNode()

			var_19_5:setContentSize(108, 108)
			var_19_5:setPosition(130 * iter_19_0 - 130 + 5 + 64, 64)
			var_19_5:setAnchorPoint(cc.p(0.5, 0.5))
			var_19_3:addChild(var_19_5)
			var_19_5:setTouchEnabled(true)
			var_19_5:setTouchSwallowEnabled(false)

			local var_19_6 = arg_19_0.tmpHeros[var_19_4]

			arg_19_0:setAvatarBorder(var_19_6, var_19_5)

			local var_19_7 = xyd.AssetLoader.get():loadSprite("windows/across_arena/across_arena/select_team/level_bg.png")

			if var_19_6.fullStar then
				local var_19_8 = xyd.AssetLoader.get():loadSprite("windows/across_arena/across_arena/select_team/avatar_mask.png")

				var_19_8:setPosition(54, 54)
				var_19_5:addChild(var_19_8, 101)
			elseif var_19_6.awakenIsReady then
				local var_19_9 = xyd.AssetLoader.get():loadSprite("windows/across_arena/across_arena/select_team/avatar_mask2.png")

				var_19_9:setPosition(54, 54)
				var_19_5:addChild(var_19_9, 101)

				local var_19_10 = xyd.createLabel(18, cc.c3b(72, 239, 232))

				var_19_10:setAnchorPoint(cc.p(0.5, 0.5))
				var_19_10:setString(var_0_1:translation("REGION_ARENA_TEXT_15"))
				var_19_10:setPosition(54, 19)
				var_19_5:addChild(var_19_10, 111)
			end

			local var_19_11 = var_19_7:getWidth()
			local var_19_12 = var_19_5:getWidth()
			local var_19_13 = var_19_5:getHeight()

			var_19_7:setAnchorPoint(cc.p(0.5, 0.5))
			var_19_7:addTo(var_19_5)
			var_19_7:setPosition(var_19_11 / 2, var_19_13 / 3)

			local var_19_14 = {
				size = 18,
				color = cc.c3b(255, 255, 255)
			}
			local var_19_15 = xyd.AssetLoader.get():loadLabel(var_19_14)

			var_19_15:setString(var_19_6:getLevel())
			var_19_15:addTo(var_19_5)
			var_19_15:setAnchorPoint(cc.p(0.5, 0.5))
			var_19_15:setPosition(var_19_7:getPositionX(), var_19_7:getPositionY())
			var_19_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
				if arg_20_0.name == "began" then
					var_19_5:setScale(0.9)

					return true
				elseif arg_20_0.name == "ended" then
					var_19_5:setScale(1)

					if not arg_19_0.scrollViewMoved_ then
						local var_20_0 = xyd.tables.regionExchange:getCost(arg_19_0.exchangeType)
						local var_20_1 = arg_19_0.exchangeTimes[arg_19_0.exchangeType] + 1

						if var_20_1 > #var_20_0 then
							var_20_1 = #var_20_0
						end

						local function var_20_2(arg_21_0)
							if arg_21_0 then
								local var_21_0 = {
									exchange_type = arg_19_0.exchangeType,
									table_id = var_19_6:getTableID()
								}

								arg_19_0.regionArena:getExchangeAwards(var_21_0, function(arg_22_0, arg_22_1)
									if arg_22_0 == xyd.error.OK then
										arg_19_0.kingCoin = arg_19_0.kingCoin - var_20_0[var_20_1]
										arg_19_0.exchangeTimes = arg_19_0.regionArena.exchangeTimes

										local var_22_0 = xyd.WindowManager.get():getWindow("region_arena")

										var_22_0:updateKingCoin()
										var_22_0:showDefenceFormation()
										var_22_0:showForce()
										arg_19_0:openAwardWindow(arg_22_1.award, var_19_6)
									end
								end)
							end
						end

						if var_19_6.fullStar then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("FULL_STAR")
							})
						elseif var_19_6.awakenIsReady then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("AWAKEN_IS_READY")
							})
						elseif var_20_0[var_20_1] > arg_19_0.kingCoin then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("NOT_ENOUGH_KING_COIN")
							})
						else
							local var_20_3 = {}

							if arg_19_0.exchangeType == xyd.RegionArenaHeroShop.HERO_AWAKE then
								var_20_3 = {}

								local var_20_4 = xyd.tables.hero:getSkill(xyd.tables.hero:afterAwaken(var_19_6:getTableID()), 5)
								local var_20_5 = xyd.tables.skill:desc(var_20_4)
								local var_20_6 = var_19_6:getName()
								local var_20_7 = xyd.tables.skill:icon(var_20_4)

								var_20_3.skillID = var_20_4
								var_20_3.skillDesc = var_20_5
								var_20_3.heroName = var_20_6
								var_20_3.iconPath = var_20_7

								xyd.WindowManager.get():openWindow("region_alert_awake", {
									message = var_20_3,
									callback = var_20_2
								})
							else
								local var_20_8 = string.format(var_0_1:translation("REGION_SHOP_TIPS_" .. arg_19_0.exchangeType), var_19_6:getName())

								table.insert(var_20_3, var_20_8)
								xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_20_3, function()
									local var_23_0 = {
										exchange_type = arg_19_0.exchangeType,
										table_id = var_19_6:getTableID()
									}

									arg_19_0.regionArena:getExchangeAwards(var_23_0, function(arg_24_0, arg_24_1)
										if arg_24_0 == xyd.error.OK then
											arg_19_0.kingCoin = arg_19_0.kingCoin - var_20_0[var_20_1]
											arg_19_0.exchangeTimes = arg_19_0.regionArena.exchangeTimes

											local var_24_0 = xyd.WindowManager.get():getWindow("region_arena")

											var_24_0:updateKingCoin()
											var_24_0:showDefenceFormation()
											var_24_0:showForce()
											arg_19_0:openAwardWindow(arg_24_1.award, var_19_6)
										end
									end)
								end, nil, nil, arg_19_0.colorMode)
							end
						end
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

function var_0_0.didOpen(arg_25_0)
	arg_25_0:addBlockLayer()
	arg_25_0.heroList_:reload()
end

function var_0_0.openAwardWindow(arg_26_0, arg_26_1, arg_26_2)
	if arg_26_0.exchangeType == xyd.RegionArenaHeroShop.HERO_ADD_STAR then
		local var_26_0 = arg_26_2:getStar()
		local var_26_1 = arg_26_2:getColor()
		local var_26_2 = var_26_0 + 1
		local var_26_3 = {
			type_ = xyd.LevelUpType.EVOLVE,
			hero = arg_26_2,
			vals = {
				oldStar = var_26_0,
				newStar = var_26_2,
				oldColor = arg_26_2:getColor()
			}
		}

		if not xyd.isSuperHero(arg_26_2) and var_26_2 == xyd.MAX_STAR_LEVEL or xyd.isSuperHero(arg_26_2) and var_26_2 == xyd.SUPER_HERO_TOTAL_STARS then
			arg_26_2.fullStar = true
		end

		arg_26_2:setStar(var_26_2)
		arg_26_0:updateHeroTable(arg_26_0.isAddStarHeros, arg_26_1)
		xyd.WindowManager.get():openWindow("levelup", var_26_3)
	elseif arg_26_0.exchangeType == xyd.RegionArenaHeroShop.HERO_AWAKE then
		local var_26_4 = arg_26_1.table_id
		local var_26_5 = xyd.tables.hero:afterAwaken(var_26_4)
		local var_26_6 = arg_26_2:getZhandouli()

		arg_26_2:setTableID(var_26_5)

		arg_26_2.skillLev_[xyd.SKILL_INDEX.Awake] = xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake] + 1

		local var_26_7 = {
			oldHeroID = var_26_4,
			newHeroID = var_26_5,
			oldHeroForce = var_26_6,
			hero = arg_26_2
		}

		arg_26_2.awakenIsReady = true

		xyd.WindowManager.get():openWindow("awake_hero_wnd", var_26_7)
	elseif arg_26_0.exchangeType == xyd.RegionArenaHeroShop.SUMMON_HERO then
		local var_26_8 = {
			toStone = false,
			partnerID = arg_26_1.table_id
		}

		arg_26_0:hide()
		arg_26_0:removeChild(arg_26_0.totalHero, arg_26_1.table_id)

		local var_26_9 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_26_8)

		cc.EventProxy.new(var_26_9, var_26_9):addEventListener(xyd.event.SUMMON_HERO_CLOSE, function()
			arg_26_0:show()
		end)
	end

	arg_26_0.heroList_:reload()
end

function var_0_0.removeChild(arg_28_0, arg_28_1, arg_28_2)
	for iter_28_0 = 1, #arg_28_1 do
		local var_28_0 = arg_28_1[iter_28_0]

		for iter_28_1, iter_28_2 in pairs(var_28_0) do
			if iter_28_2:getTableID() == arg_28_2 then
				table.remove(arg_28_1[iter_28_0], iter_28_1)

				break
			end
		end
	end
end

function var_0_0.updateHeroTable(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = true

	for iter_29_0, iter_29_1 in pairs(arg_29_1) do
		if iter_29_1.table_id == arg_29_2.table_id then
			arg_29_1[iter_29_0] = arg_29_2
			var_29_0 = false

			break
		end
	end

	if var_29_0 then
		table.insert(arg_29_1, arg_29_2)
	end
end

function var_0_0.formatRegionArenaHeros(arg_30_0, arg_30_1)
	for iter_30_0, iter_30_1 in pairs(arg_30_1) do
		if iter_30_1:isHaveAwakenItem() and not iter_30_1:isAwaken() then
			local var_30_0 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_30_1 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			local var_30_2 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_30_0:renewHeroInfo(iter_30_1, var_30_0, var_30_1, var_30_2)
		elseif iter_30_1:isAwaken() then
			local var_30_3 = {
				90,
				90,
				70,
				50,
				30
			}
			local var_30_4 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			local var_30_5 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_30_0:renewHeroInfo(iter_30_1, var_30_3, var_30_4, var_30_5)
		else
			local var_30_6 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_30_7 = {
				0,
				1,
				1,
				1,
				1,
				1
			}
			local var_30_8 = {
				0,
				1,
				1,
				1,
				1,
				1
			}

			arg_30_0:renewHeroInfo(iter_30_1, var_30_6, var_30_7, var_30_8)
		end

		iter_30_1.practice_attr_ = {
			0,
			0,
			0
		}

		iter_30_1:updatePracticeAwardAttr()
	end
end

function var_0_0.renewHeroInfo(arg_31_0, arg_31_1, arg_31_2, arg_31_3, arg_31_4)
	local var_31_0 = xyd.tables.misc.regionHeroColor

	arg_31_1.level_, arg_31_1.color_ = xyd.tables.misc.regionHeroLevel, var_31_0
	arg_31_1.skillLev_ = {}
	arg_31_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_31_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_31_1.color_ >= xyd.EquipQuality.GREEN then
		arg_31_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_31_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_31_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_31_1.color_ >= xyd.EquipQuality.BLUE then
		arg_31_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_31_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_31_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_31_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_31_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_31_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_31_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_31_1:isAwaken() then
		arg_31_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_31_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_31_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	arg_31_1.equips_ = {}

	for iter_31_0 = 1, var_0_5 do
		table.insert(arg_31_1.equips_, tonumber(arg_31_4[iter_31_0]))
	end

	arg_31_1.fumo_ = {}

	for iter_31_1 = 1, var_0_5 do
		table.insert(arg_31_1.fumo_, tonumber(arg_31_3[iter_31_1]))
	end

	arg_31_1.fumoLev_ = {}

	for iter_31_2 = 1, var_0_5 do
		local var_31_1 = arg_31_1:getEquipByIndex(iter_31_2)

		table.insert(arg_31_1.fumoLev_, tonumber(var_31_1:getMaxFumoStar()))
	end
end

function var_0_0.setAvatarBorder(arg_32_0, arg_32_1, arg_32_2)
	local function var_32_0(arg_33_0, arg_33_1, arg_33_2)
		local var_33_0

		if arg_33_0 == 1 then
			if xyd.isSuperHero(arg_33_1) and arg_33_2 > xyd.MAX_STAR_LEVEL then
				var_33_0 = "windows/common/hero_common/icon_pink_star.png"
			else
				var_33_0 = "windows/common/hero_common/icon_hero_star.png"
			end
		elseif arg_33_0 == 2 then
			var_33_0 = "windows/across_arena/icon_blue_star.png"
		end

		return xyd.AssetLoader.get():loadSprite(var_33_0)
	end

	xyd.setAvatarBorderNewUI(arg_32_1, arg_32_2, arg_32_1:getColor(), 0)

	local var_32_1 = arg_32_1:getStar()
	local var_32_2 = 0

	for iter_32_0, iter_32_1 in pairs(arg_32_0.isAddStarHeros) do
		local var_32_3 = arg_32_1:getTableID()

		if arg_32_1:isAwaken() then
			var_32_3 = arg_32_1:beforeAwakenID()
		end

		if var_32_3 == iter_32_1.table_id then
			var_32_2 = iter_32_1.add_star

			if not xyd.isSuperHero(arg_32_1) then
				if var_32_1 > xyd.MAX_STAR_LEVEL then
					var_32_2 = xyd.MAX_STAR_LEVEL - var_32_1 + var_32_2
					var_32_1 = var_32_1 - iter_32_1.add_star
				else
					var_32_1 = var_32_1 - var_32_2
				end
			elseif var_32_1 > xyd.SUPER_HERO_TOTAL_STARS then
				var_32_2 = xyd.SUPER_HERO_TOTAL_STARS - var_32_1 + var_32_2
				var_32_1 = var_32_1 - iter_32_1.add_star
			else
				var_32_1 = var_32_1 - var_32_2
			end
		end
	end

	local var_32_4 = arg_32_2:getChildByName("border")
	local var_32_5 = clone(var_32_4:getContentSize())
	local var_32_6 = arg_32_2:getContentSize()
	local var_32_7 = var_32_1 + var_32_2
	local var_32_8 = var_32_7

	if var_32_8 > xyd.MAX_STAR_LEVEL then
		var_32_8 = var_32_8 - xyd.MAX_STAR_LEVEL
	end

	local var_32_9 = 0.6666666666666666
	local var_32_10 = var_32_0(1, arg_32_1, var_32_7)

	var_32_10:setScale(var_32_9)

	local var_32_11 = var_32_10:getContentSize().width * var_32_9 - 8
	local var_32_12 = var_32_1

	if var_32_12 > xyd.MAX_STAR_LEVEL then
		var_32_12 = var_32_12 - xyd.MAX_STAR_LEVEL
	end

	local var_32_13 = (var_32_5.width - var_32_8 * var_32_11) / 2

	for iter_32_2 = 1, var_32_8 do
		local var_32_14 = 1

		if var_32_12 < iter_32_2 then
			var_32_14 = 2
		end

		local var_32_15 = var_32_0(var_32_14, arg_32_1, var_32_7)

		var_32_15:setScale(var_32_9)
		arg_32_2:getChildByName("view"):addChild(var_32_15)
		var_32_15:x(var_32_13 + (iter_32_2 - 1) * var_32_11 - 3):y(8)
		var_32_15:setAnchorPoint(cc.p(0, 0))
	end
end

return var_0_0
