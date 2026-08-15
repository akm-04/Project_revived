local var_0_0 = class("FumoHeroWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = 6
local var_0_2 = 1
local var_0_3 = import("app.windows.EquipItem")
local var_0_4 = xyd.tables.heroTable
local var_0_5 = xyd.tables.translation
local var_0_6 = {
	txtName = var_0_5:translation("SELECT_HERO"),
	qianpai = var_0_5:translation("QIANPAI_BUTTON"),
	zhongpai = var_0_5:translation("ZHONGPAI_BUTTON"),
	houpai = var_0_5:translation("HOUPAI_BUTTON"),
	quanbu = var_0_5:translation("ALL_BUTTON")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.tmpHeros_ = {}
	arg_1_0.totalHero_ = {}
	arg_1_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_1_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initBaseInfo()
	arg_2_0:layout()
end

function var_0_0.initBaseInfo(arg_3_0)
	arg_3_0.heros_ = arg_3_0.player_.heros_

	table.sort(arg_3_0.heros_, function(arg_4_0, arg_4_1)
		if not arg_3_0:checkHeroCanFumo(arg_4_0) and arg_3_0:checkHeroCanFumo(arg_4_1) then
			return true
		elseif not arg_3_0:checkHeroCanFumo(arg_4_1) and arg_3_0:checkHeroCanFumo(arg_4_0) then
			return false
		end

		if arg_4_0:canSummon() and not arg_4_1:canSummon() then
			return true
		elseif arg_4_1:canSummon() and not arg_4_0:canSummon() then
			return false
		end

		return xyd.heroNormalSort(arg_4_0, arg_4_1) or false
	end)
	arg_3_0:initHeros(arg_3_0.heros_)

	arg_3_0.tmpHeros_ = arg_3_0.heros_
end

function var_0_0.layout(arg_5_0)
	arg_5_0:initMenu()
	arg_5_0:nodeByName("txt_name"):setString(var_0_6.txtName)
	arg_5_0:nodeByName("txt_all"):setString(var_0_6.quanbu)
	arg_5_0:nodeByName("txt_qianpai"):setString(var_0_6.qianpai)
	arg_5_0:nodeByName("txt_zhongpai"):setString(var_0_6.zhongpai)
	arg_5_0:nodeByName("txt_houpai"):setString(var_0_6.houpai)

	local var_5_0 = arg_5_0:nodeByName("hero_list")

	arg_5_0.heroListWidth = var_5_0:getContentSize().width
	arg_5_0.heroListHeight = var_5_0:getContentSize().height
	arg_5_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, 850, 540),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_5_0):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.heroList_:setDelegate(handler(arg_5_0, arg_5_0.heroDelegate))
end

function var_0_0.initMenu(arg_6_0)
	arg_6_0.heroClassButtons_ = {}

	local var_6_0 = arg_6_0:nodeByName("background")

	table.insert(arg_6_0.heroClassButtons_, arg_6_0:nodeByName("all_btn"))
	table.insert(arg_6_0.heroClassButtons_, arg_6_0:nodeByName("qianpai_btn"))
	table.insert(arg_6_0.heroClassButtons_, arg_6_0:nodeByName("zhongpai_btn"))
	table.insert(arg_6_0.heroClassButtons_, arg_6_0:nodeByName("houpai_btn"))

	for iter_6_0 = 1, #arg_6_0.heroClassButtons_ do
		arg_6_0.heroClassButtons_[iter_6_0]:setZoomScale(0.3)
		arg_6_0.heroClassButtons_[iter_6_0]:addTouchEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()
				arg_6_0:refreshSelectedHeroClass(iter_6_0)
			end
		end)
	end
end

function var_0_0.refreshSelectedHeroClass(arg_8_0, arg_8_1)
	arg_8_0.heroList_:removeAllItems()

	if arg_8_1 == 1 then
		arg_8_0.tmpHeros_ = arg_8_0.heros_
	elseif arg_8_1 == 2 then
		arg_8_0.tmpHeros_ = arg_8_0.totalHero_[xyd.DistanceType.QIANPAI]
	elseif arg_8_1 == 3 then
		arg_8_0.tmpHeros_ = arg_8_0.totalHero_[xyd.DistanceType.ZHONGPAI]
	elseif arg_8_1 == 4 then
		arg_8_0.tmpHeros_ = arg_8_0.totalHero_[xyd.DistanceType.HOUPAI]
	else
		arg_8_0.tmpHeros_ = arg_8_0.heros_
	end

	for iter_8_0 = 1, #arg_8_0.heroClassButtons_ do
		if arg_8_1 == iter_8_0 then
			arg_8_0.heroClassButtons_[iter_8_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_8_0.heroClassButtons_[iter_8_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_8_0.heroList_:reload()
end

function var_0_0.initHeros(arg_9_0, arg_9_1)
	for iter_9_0, iter_9_1 in pairs(arg_9_1) do
		if iter_9_1:getDistanceType() == xyd.DistanceType.QIANPAI then
			table.insert(arg_9_0.totalHero_[xyd.DistanceType.QIANPAI], iter_9_1)
		elseif iter_9_1:getDistanceType() == xyd.DistanceType.ZHONGPAI then
			table.insert(arg_9_0.totalHero_[xyd.DistanceType.ZHONGPAI], iter_9_1)
		elseif iter_9_1:getDistanceType() == xyd.DistanceType.HOUPAI then
			table.insert(arg_9_0.totalHero_[xyd.DistanceType.HOUPAI], iter_9_1)
		end
	end
end

function var_0_0.sortTables(arg_10_0, arg_10_1)
	for iter_10_0 = 1, #arg_10_1 do
		table.sort(arg_10_1[iter_10_0], function(arg_11_0, arg_11_1)
			if (arg_11_0.can_rent or arg_11_1.can_rent) and (not arg_11_0.can_rent or not arg_11_1.can_rent) then
				return arg_11_0.can_rent and not arg_11_1.can_rent
			end

			return xyd.heroNormalSort(arg_11_0, arg_11_1) or false
		end)
	end
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevY_ = arg_12_1.y
	elseif arg_12_1.name == "moved" and 0.5 <= math.abs(arg_12_1.y - arg_12_0.prevY_) then
		arg_12_0.scrollViewMoved_ = true
	end
end

function var_0_0.heroDelegate(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	if cc.ui.UIListView.COUNT_TAG == arg_13_2 then
		return (math.ceil(#arg_13_0.tmpHeros_ / var_0_1))
	elseif cc.ui.UIListView.CELL_TAG == arg_13_2 then
		local var_13_0 = arg_13_0.heroList_:dequeueItem()

		if not var_13_0 then
			var_13_0 = arg_13_0.heroList_:newItem()
		else
			var_13_0:removeAllChildren(true)
		end

		local var_13_1 = 850
		local var_13_2 = 170

		var_13_0:setItemSize(var_13_1, var_13_2)

		local var_13_3 = display.newNode()

		var_13_3:setContentSize(var_13_1, 130)

		for iter_13_0 = 1, var_0_1 do
			local var_13_4 = (arg_13_3 - 1) * var_0_1 + iter_13_0

			if var_13_4 > #arg_13_0.tmpHeros_ then
				break
			end

			local var_13_5 = display.newNode()

			var_13_5:setContentSize(108, 108)
			var_13_5:setPosition(142 * iter_13_0 - 142 + 5 + 64, 92)
			var_13_5:setAnchorPoint(cc.p(0.5, 0.5))
			var_13_3:addChild(var_13_5)
			var_13_5:setTouchEnabled(true)
			var_13_5:setTouchSwallowEnabled(false)

			local var_13_6 = arg_13_0.tmpHeros_[var_13_4]

			xyd.setAvatarBorderNewUI(var_13_6, var_13_5, var_13_6:getColor(), var_13_6:getStar())

			local var_13_7 = xyd.AssetLoader.get():loadSprite("windows/common/lv_di.png")

			var_13_7:setScale(1.2)

			local var_13_8 = xyd.AssetLoader.get():loadSprite("windows/fumo_hero/bg_name.png")

			var_13_8:setAnchorPoint(0.5, 0.5)
			var_13_8:setPosition(54, -25)
			var_13_5:addChild(var_13_8)

			local var_13_9 = display.newNode()

			var_13_9:setAnchorPoint(0.5, 0.5)
			var_13_9:setPosition(54, -26)
			var_13_9:setContentSize(80, 20)
			var_13_9:setScale(0.8)
			var_13_9:addTo(var_13_5)

			local var_13_10 = cc.Node:create()
			local var_13_11 = var_13_6:getName()
			local var_13_12 = var_13_6:getColor()
			local var_13_13 = {
				text = var_13_11
			}
			local var_13_14 = xyd.AssetLoader:get():loadLabel(var_13_13)

			var_13_10:addChild(var_13_14)
			var_13_14:setAnchorPoint(cc.p(0, 0))

			local var_13_15 = var_13_9:getContentSize().width - var_13_14:getContentSize().width

			var_13_10:setPosition(var_13_15 / 2, 0)
			var_13_10:setAnchorPoint(cc.p(0, 0))
			var_13_9:addChild(var_13_10)

			if arg_13_0:checkHeroCanFumo(var_13_6) then
				local var_13_16 = xyd.AssetLoader.get():loadSprite("windows/fumo_hero/new_avatar_mask.png")
				local var_13_17 = xyd.AssetLoader.get():loadSprite("windows/fumo_hero/bg_fullfumo.png")

				var_13_16:setScale(1)
				var_13_16:setPosition(54, 54)
				var_13_17:setPosition(54, 20)
				var_13_5:addChild(var_13_16, 10)
				var_13_5:addChild(var_13_17, 11)
			end

			local var_13_18 = var_13_7:getWidth()
			local var_13_19 = var_13_5:getWidth()
			local var_13_20 = var_13_5:getHeight()

			var_13_7:setAnchorPoint(cc.p(0.5, 0.5))
			var_13_7:addTo(var_13_5)
			var_13_7:setPosition(var_13_18 / 2 + 5, var_13_20 / 3)

			local var_13_21 = {
				size = 16,
				color = cc.c3b(255, 255, 255)
			}
			local var_13_22 = xyd.AssetLoader.get():loadLabel(var_13_21)

			var_13_22:setString(var_13_6:getLevel())
			var_13_22:addTo(var_13_5)
			var_13_22:setAnchorPoint(cc.p(0.5, 0.5))
			var_13_22:setPosition(var_13_7:getPositionX() + 4, var_13_7:getPositionY() - 0.5)
			var_13_22:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
			var_13_5:getChildByName("border"):setLocalZOrder(var_13_22:getLocalZOrder() + 1)
			var_13_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
				if arg_14_0.name == "began" then
					var_13_5:setScale(0.9)

					return true
				elseif arg_14_0.name == "ended" then
					var_13_5:setScale(1)

					if not arg_13_0.scrollViewMoved_ then
						local var_14_0 = xyd.WindowManager.get():getWindow("fumo")
						local var_14_1 = arg_13_0.player_:getHeroByID(var_13_6:getHeroID())

						var_14_0:setHero(var_14_1)
						xyd.WindowManager.get():closeWindow(arg_13_0)
					end
				end
			end)
		end

		var_13_0:addContent(var_13_3)

		return var_13_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_13_2 then
		-- block empty
	end
end

function var_0_0.checkHeroCanFumo(arg_15_0, arg_15_1)
	local var_15_0
	local var_15_1 = true

	for iter_15_0 = 1, 6 do
		local var_15_2 = arg_15_1:getEquipByIndex(iter_15_0)

		if var_15_2:isCollected() and var_15_2:getFumoLev() < var_15_2:getMaxFumoStar() then
			var_15_1 = false
		end
	end

	return var_15_1
end

function var_0_0.didOpen(arg_16_0)
	arg_16_0:addBlockLayer()
	arg_16_0:refreshSelectedHeroClass(var_0_2)
end

return var_0_0
