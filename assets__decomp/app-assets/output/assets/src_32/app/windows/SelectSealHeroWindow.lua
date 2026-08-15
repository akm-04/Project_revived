local var_0_0 = class("SelectSealHeroWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = 5
local var_0_2 = 1
local var_0_3 = xyd.tables.heroTable
local var_0_4 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.arena_ = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)
	arg_1_0.tmpHeros_ = {}
	arg_1_0.totalHero_ = {}
	arg_1_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_1_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
	arg_1_0.sealHeroID = arg_1_0.arena_.sealHeroID
	arg_1_0.sealHero = nil
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initBaseInfo()
	arg_2_0:layout()
end

function var_0_0.initBaseInfo(arg_3_0)
	arg_3_0.heros_ = clone(arg_3_0.player_.heros_)

	arg_3_0:sortHeros(arg_3_0.heros_)

	for iter_3_0, iter_3_1 in pairs(arg_3_0.heros_) do
		if iter_3_1:getDistanceType() == xyd.DistanceType.QIANPAI then
			table.insert(arg_3_0.totalHero_[xyd.DistanceType.QIANPAI], iter_3_1)
		elseif iter_3_1:getDistanceType() == xyd.DistanceType.ZHONGPAI then
			table.insert(arg_3_0.totalHero_[xyd.DistanceType.ZHONGPAI], iter_3_1)
		elseif iter_3_1:getDistanceType() == xyd.DistanceType.HOUPAI then
			table.insert(arg_3_0.totalHero_[xyd.DistanceType.HOUPAI], iter_3_1)
		end
	end

	arg_3_0.tmpHeros_ = arg_3_0.heros_
end

function var_0_0.sortHeros(arg_4_0, arg_4_1)
	table.sort(arg_4_1, function(arg_5_0, arg_5_1)
		if arg_4_0.sealHeroID and arg_4_0.sealHeroID > 0 then
			local var_5_0 = arg_4_0:checkHeroIsSeal(arg_5_0)
			local var_5_1 = arg_4_0:checkHeroIsSeal(arg_5_1)

			if (var_5_0 or var_5_1) and (not var_5_0 or not var_5_1) then
				return var_5_0
			end
		end

		return xyd.heroNormalSort(arg_5_0, arg_5_1) or false
	end)
end

function var_0_0.layout(arg_6_0)
	arg_6_0:initMenu()
	arg_6_0:nodeByName("text_title"):setString(var_0_4:translation("SELECT_SEAL_HERO"))

	local var_6_0 = arg_6_0:nodeByName("hero_list")
	local var_6_1 = var_6_0:getContentSize()

	arg_6_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_6_1.width, var_6_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_6_0):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.heroList_:setDelegate(handler(arg_6_0, arg_6_0.heroDelegate))
end

function var_0_0.initMenu(arg_7_0)
	arg_7_0.heroClassButtons_ = {}

	local var_7_0 = arg_7_0:nodeByName("container")

	table.insert(arg_7_0.heroClassButtons_, arg_7_0:nodeByName("quanbu_button"))
	table.insert(arg_7_0.heroClassButtons_, arg_7_0:nodeByName("qianpai_button"))
	table.insert(arg_7_0.heroClassButtons_, arg_7_0:nodeByName("zhongpai_button"))
	table.insert(arg_7_0.heroClassButtons_, arg_7_0:nodeByName("houpai_button"))

	for iter_7_0 = 1, #arg_7_0.heroClassButtons_ do
		arg_7_0.heroClassButtons_[iter_7_0]:setZoomScale(0.3)
		arg_7_0.heroClassButtons_[iter_7_0]:addTouchEventListener(function(arg_8_0, arg_8_1)
			if arg_8_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()
				arg_7_0:refreshSelectedHeroClass(iter_7_0)
			end
		end)
	end
end

function var_0_0.refreshSelectedHeroClass(arg_9_0, arg_9_1)
	arg_9_0.heroList_:removeAllItems()

	if arg_9_1 == 1 then
		arg_9_0.tmpHeros_ = arg_9_0.heros_
	elseif arg_9_1 == 2 then
		arg_9_0.tmpHeros_ = arg_9_0.totalHero_[xyd.DistanceType.QIANPAI]
	elseif arg_9_1 == 3 then
		arg_9_0.tmpHeros_ = arg_9_0.totalHero_[xyd.DistanceType.ZHONGPAI]
	elseif arg_9_1 == 4 then
		arg_9_0.tmpHeros_ = arg_9_0.totalHero_[xyd.DistanceType.HOUPAI]
	else
		arg_9_0.tmpHeros_ = arg_9_0.heros_
	end

	for iter_9_0 = 1, #arg_9_0.heroClassButtons_ do
		if arg_9_1 == iter_9_0 then
			arg_9_0.heroClassButtons_[iter_9_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_9_0.heroClassButtons_[iter_9_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_9_0.heroList_:reload()
end

function var_0_0.scrollListener(arg_10_0, arg_10_1)
	if arg_10_1.name == "began" then
		arg_10_0.scrollViewMoved_ = false
		arg_10_0.prevY_ = arg_10_1.y
	elseif arg_10_1.name == "moved" and 0.5 <= math.abs(arg_10_1.y - arg_10_0.prevY_) then
		arg_10_0.scrollViewMoved_ = true
	end
end

function var_0_0.heroDelegate(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	if cc.ui.UIListView.COUNT_TAG == arg_11_2 then
		return (math.ceil(#arg_11_0.tmpHeros_ / var_0_1))
	elseif cc.ui.UIListView.CELL_TAG == arg_11_2 then
		local var_11_0 = arg_11_0.heroList_:dequeueItem()

		if not var_11_0 then
			var_11_0 = arg_11_0.heroList_:newItem()
		else
			var_11_0:removeAllChildren(true)
		end

		local var_11_1 = 710
		local var_11_2 = 130

		var_11_0:setItemSize(var_11_1, 130)

		local var_11_3 = display.newNode()

		var_11_3:setContentSize(var_11_1, 130)

		for iter_11_0 = 1, var_0_1 do
			local var_11_4 = (arg_11_3 - 1) * var_0_1 + iter_11_0

			if var_11_4 > #arg_11_0.tmpHeros_ then
				break
			end

			local var_11_5 = display.newNode()

			var_11_5:setContentSize(128, 128)
			var_11_5:setPosition(142 * iter_11_0 - 142 + 5 + 64, 64)
			var_11_5:setAnchorPoint(cc.p(0.5, 0.5))
			var_11_3:addChild(var_11_5)
			var_11_5:setTouchEnabled(true)
			var_11_5:setTouchSwallowEnabled(false)

			local var_11_6 = arg_11_0.tmpHeros_[var_11_4]

			xyd.setAvatarBorder(var_11_6, var_11_5, var_11_6:getColor(), var_11_6:getStar())

			local var_11_7 = xyd.AssetLoader.get():loadSprite("windows/common/lv_di.png")

			var_11_7:setScale(1.2)

			if arg_11_0:checkHeroIsSeal(var_11_6) then
				local var_11_8 = xyd.AssetLoader.get():loadSprite("windows/arena/avatar_mask.png")
				local var_11_9 = xyd.AssetLoader.get():loadSprite("windows/arena/not_use.png")

				var_11_8:setScale(1.1)
				var_11_8:setPosition(63, 62)
				var_11_9:setPosition(95, 105)
				var_11_5:addChild(var_11_8, 10)
				var_11_5:addChild(var_11_9, 11)
			elseif arg_11_0:checkHeroIsDefense(var_11_6) then
				local var_11_10 = xyd.AssetLoader.get():loadSprite("windows/arena/avatar_mask.png")

				var_11_10:setScale(1.1)
				var_11_10:setPosition(63, 62)
				var_11_5:addChild(var_11_10, 10)
			end

			local var_11_11 = var_11_7:getWidth()
			local var_11_12 = var_11_5:getWidth()
			local var_11_13 = var_11_5:getHeight()

			var_11_7:setAnchorPoint(cc.p(0.5, 0.5))
			var_11_7:addTo(var_11_5)
			var_11_7:setPosition(var_11_11 / 2, var_11_13 / 3)

			local var_11_14 = {
				size = 16,
				color = cc.c3b(255, 255, 255)
			}
			local var_11_15 = xyd.AssetLoader.get():loadLabel(var_11_14)

			var_11_15:setString(var_11_6:getLevel())
			var_11_15:addTo(var_11_5)
			var_11_15:setAnchorPoint(cc.p(0.5, 0.5))
			var_11_15:setPosition(var_11_7:getPositionX() + 4, var_11_7:getPositionY() - 0.5)
			var_11_15:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
			var_11_5:getChildByName("border"):setLocalZOrder(var_11_15:getLocalZOrder() + 1)
			var_11_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
				if arg_12_0.name == "began" then
					var_11_5:setScale(0.9)

					return true
				elseif arg_12_0.name == "ended" then
					var_11_5:setScale(1)

					if not arg_11_0.scrollViewMoved_ then
						if arg_11_0:checkHeroIsSeal(var_11_6) then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_4:translation("HERO_IS_SEAL_TIPS_2")
							})

							return
						elseif arg_11_0:checkHeroIsDefense(var_11_6) then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_4:translation("HERO_IS_SEAL_TIPS_3")
							})

							return
						end

						local var_12_0 = string.format(var_0_4:translation("MAKE_SURE_SEAL_HERO"), var_11_6:getName())

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_12_0, function()
							local var_13_0 = var_11_6:getFirstTableID()

							arg_11_0.arena_:sealHeroByTableID(var_13_0, function(arg_14_0, arg_14_1)
								if arg_14_0 == xyd.error.OK then
									xyd.WindowManager.get():closeWindow(arg_11_0)
								end
							end)
						end, nil, nil, arg_11_0.colorMode)
					end
				end
			end)
		end

		var_11_0:addContent(var_11_3)

		return var_11_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_11_2 then
		-- block empty
	end
end

function var_0_0.checkHeroIsSeal(arg_15_0, arg_15_1)
	if arg_15_0.sealHeroID and arg_15_0.sealHeroID > 0 and arg_15_1:getFirstTableID() == arg_15_0.sealHeroID then
		return true
	end

	return false
end

function var_0_0.checkHeroIsDefense(arg_16_0, arg_16_1)
	arg_16_0.defenseHeroes = arg_16_0.arena_:getDefenseFormation().heros

	for iter_16_0, iter_16_1 in pairs(arg_16_0.defenseHeroes) do
		if iter_16_1:getTableID() == arg_16_1:getTableID() then
			return true
		end
	end

	return false
end

function var_0_0.didOpen(arg_17_0)
	arg_17_0:addBlockLayer()
	arg_17_0:refreshSelectedHeroClass(var_0_2)
end

return var_0_0
