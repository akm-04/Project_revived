local var_0_0 = class("WashHeroSelectWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 6
local var_0_3 = 1
local var_0_4 = xyd.tables.hero

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.heros_ = arg_1_0.player_.heros_
	arg_1_0.tmpHeros_ = {}
	arg_1_0.totalHero_ = {}
	arg_1_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_1_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.HOUPAI] = {}

	table.sort(arg_1_0.heros_, function(arg_2_0, arg_2_1)
		local var_2_0 = arg_2_0.tableID_ < arg_2_1.tableID_ and 1 or 0
		local var_2_1 = arg_2_0.tableID_ > arg_2_1.tableID_ and 1 or 0
		local var_2_2 = arg_2_0.color_ > arg_2_1.color_ and 2 or 0
		local var_2_3 = arg_2_0.color_ < arg_2_1.color_ and 2 or 0
		local var_2_4 = arg_2_0.star_ > arg_2_1.star_ and 4 or 0
		local var_2_5 = arg_2_0.star_ < arg_2_1.star_ and 4 or 0
		local var_2_6 = arg_2_0.level_ > arg_2_1.level_ and 8 or 0
		local var_2_7 = arg_2_0.level_ < arg_2_1.level_ and 8 or 0
		local var_2_8 = 0
		local var_2_9 = 0

		if arg_2_0:isAwaken() and arg_2_1:isAwaken() then
			var_2_8 = arg_1_0:getPracticeNum(arg_2_0) > arg_1_0:getPracticeNum(arg_2_1) and 16 or 0
			var_2_9 = arg_1_0:getPracticeNum(arg_2_0) < arg_1_0:getPracticeNum(arg_2_1) and 16 or 0
		end

		local var_2_10 = arg_2_0:isAwaken() and 32 or 0
		local var_2_11 = arg_2_1:isAwaken() and 32 or 0
		local var_2_12 = arg_2_0:canSummon() and 64 or 0
		local var_2_13 = arg_2_1:canSummon() and 64 or 0

		return var_2_0 + var_2_2 + var_2_4 + var_2_6 + var_2_8 + var_2_10 + var_2_12 > var_2_1 + var_2_3 + var_2_5 + var_2_7 + var_2_9 + var_2_11 + var_2_13
	end)
end

function var_0_0.getPracticeNum(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1:getPractice()
	local var_3_1 = 0

	return tonumber(var_3_0[1]) >= xyd.WaskAttrUpLimit and tonumber(var_3_0[2]) >= xyd.WaskAttrUpLimit and tonumber(var_3_0[3]) >= xyd.WaskAttrUpLimit and -10000 or var_3_0[1] + var_3_0[2] + var_3_0[3]
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super.willOpen(arg_4_0, arg_4_1)
	arg_4_0:initHeros(arg_4_0.heros_)

	arg_4_0.tmpHeros_ = arg_4_0.heros_

	arg_4_0:layout()
	arg_4_0:refreshSelectedHeroClass(var_0_3)
end

function var_0_0.layout(arg_5_0)
	arg_5_0:initMenu()

	local var_5_0 = arg_5_0.container:getChildByName("list")

	arg_5_0.heroListWidth = var_5_0:getContentSize().width
	arg_5_0.heroListHeight = var_5_0:getContentSize().height
	arg_5_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, 850, 480),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_5_0):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.container:getChildByName("title_txt"):setString(var_0_1:translation("WASH_SELECT_TITLE"))

	local var_5_1 = arg_5_0.container:getChildByName("all_txt")
	local var_5_2 = arg_5_0.container:getChildByName("qianpai_txt")
	local var_5_3 = arg_5_0.container:getChildByName("zhongpai_txt")
	local var_5_4 = arg_5_0.container:getChildByName("houpai_txt")

	var_5_1:setString(var_0_1:translation("ALL_BUTTON"))
	var_5_2:setString(var_0_1:translation("QIANPAI_BUTTON"))
	var_5_3:setString(var_0_1:translation("ZHONGPAI_BUTTON"))
	var_5_4:setString(var_0_1:translation("HOUPAI_BUTTON"))
	arg_5_0.container:getChildByName("Text_6"):setString(var_0_1:translation("SELECT_HERO"))
	arg_5_0.heroList_:setDelegate(handler(arg_5_0, arg_5_0.heroDelegate))
end

function var_0_0.initMenu(arg_6_0)
	arg_6_0.heroClassButtons_ = {}
	arg_6_0.container = arg_6_0:nodeByName("container")

	table.insert(arg_6_0.heroClassButtons_, arg_6_0.container:getChildByName("all_btn"))
	table.insert(arg_6_0.heroClassButtons_, arg_6_0.container:getChildByName("qianpai_btn"))
	table.insert(arg_6_0.heroClassButtons_, arg_6_0.container:getChildByName("zhongpai_btn"))
	table.insert(arg_6_0.heroClassButtons_, arg_6_0.container:getChildByName("houpai_btn"))

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
			elseif arg_11_0.level_ ~= arg_11_1.level_ then
				return arg_11_0.level_ > arg_11_1.level_
			elseif arg_11_0.star_ ~= arg_11_1.star_ then
				return arg_11_0.star_ > arg_11_1.star_
			else
				return arg_11_0.color_ > arg_11_1.color_
			end
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
		return (math.ceil(#arg_13_0.tmpHeros_ / var_0_2))
	elseif cc.ui.UIListView.CELL_TAG == arg_13_2 then
		local var_13_0 = arg_13_0.heroList_:dequeueItem()

		if not var_13_0 then
			var_13_0 = arg_13_0.heroList_:newItem()
		else
			var_13_0:removeAllChildren(true)
		end

		local var_13_1 = 710
		local var_13_2 = 130

		var_13_0:setItemSize(var_13_1, 130)

		local var_13_3 = display.newNode()

		var_13_3:setContentSize(var_13_1, 130)

		for iter_13_0 = 1, var_0_2 do
			local var_13_4 = (arg_13_3 - 1) * var_0_2 + iter_13_0

			if var_13_4 > #arg_13_0.tmpHeros_ then
				break
			end

			local var_13_5 = display.newNode()

			var_13_5:setContentSize(108, 108)
			var_13_5:setPosition(142 * iter_13_0 - 142 + 5 + 60, 64)
			var_13_5:setAnchorPoint(cc.p(0.5, 0.5))
			var_13_3:addChild(var_13_5)
			var_13_5:setTouchEnabled(true)
			var_13_5:setTouchSwallowEnabled(false)

			local var_13_6 = arg_13_0.tmpHeros_[var_13_4]

			xyd.setAvatarBorderNewUI(var_13_6, var_13_5, var_13_6:getColor(), var_13_6:getStar())

			local var_13_7 = xyd.AssetLoader.get():loadSprite("windows/common/lv_di.png")

			var_13_7:setScale(1.2)

			local var_13_8 = xyd.AssetLoader.get():loadSprite("windows/wasg_select_hero/bg_name.png")

			var_13_8:setAnchorPoint(0.5, 0.5)
			var_13_8:setPosition(54, -20)
			var_13_5:addChild(var_13_8)

			local var_13_9 = display.newNode()

			var_13_9:setAnchorPoint(0.5, 0.5)
			var_13_9:setPosition(54, -21)
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

			if var_13_6:isAwaken() == false then
				local var_13_16 = xyd.AssetLoader.get():loadSprite("windows/fumo_hero/new_avatar_mask.png")

				var_13_16:setScale(1)
				var_13_16:setPosition(54, 54)
				var_13_5:addChild(var_13_16, 10)
			else
				local var_13_17 = xyd.AssetLoader.get():loadSprite("windows/wasg_select_hero/lamp_bg.png")

				var_13_17:setAnchorPoint(0.5, 0.5)
				var_13_17:setPosition(54, 90)
				var_13_5:addChild(var_13_17)

				local var_13_18 = xyd.AssetLoader.get():loadSprite("windows/wasg_select_hero/white.png")
				local var_13_19 = xyd.AssetLoader.get():loadSprite("windows/wasg_select_hero/white.png")
				local var_13_20 = xyd.AssetLoader.get():loadSprite("windows/wasg_select_hero/white.png")

				var_13_18:setPosition(43, 90)
				var_13_5:addChild(var_13_18)
				var_13_19:setPosition(60, 90)
				var_13_5:addChild(var_13_19)
				var_13_20:setPosition(77, 90)
				var_13_5:addChild(var_13_20)

				local var_13_21 = xyd.AssetLoader.get():loadSprite("windows/wasg_select_hero/green.png")
				local var_13_22 = xyd.AssetLoader.get():loadSprite("windows/wasg_select_hero/green.png")
				local var_13_23 = xyd.AssetLoader.get():loadSprite("windows/wasg_select_hero/green.png")

				var_13_21:setPosition(43, 90)
				var_13_5:addChild(var_13_21)
				var_13_22:setPosition(60, 90)
				var_13_5:addChild(var_13_22)
				var_13_23:setPosition(77, 90)
				var_13_5:addChild(var_13_23)

				local var_13_24 = var_13_6:getPractice()
				local var_13_25 = var_0_4:getPracticeNeeds(var_13_6:getTableID())

				if tonumber(var_13_24[1]) < var_13_25[1] then
					var_13_18:setVisible(true)
					var_13_21:setVisible(false)
				end

				if tonumber(var_13_24[2]) < var_13_25[2] then
					var_13_19:setVisible(true)
					var_13_22:setVisible(false)
				end

				if tonumber(var_13_24[3]) < var_13_25[3] then
					var_13_20:setVisible(true)
					var_13_23:setVisible(false)
				end
			end

			local var_13_26 = var_13_7:getWidth()
			local var_13_27 = var_13_5:getWidth()
			local var_13_28 = var_13_5:getHeight()

			var_13_7:setAnchorPoint(cc.p(0.5, 0.5))
			var_13_7:addTo(var_13_5)
			var_13_7:setPosition(var_13_26 / 2 + 5, var_13_28 / 3)

			local var_13_29 = {
				size = 16,
				color = cc.c3b(255, 255, 255)
			}
			local var_13_30 = xyd.AssetLoader.get():loadLabel(var_13_29)

			var_13_30:setString(var_13_6:getLevel())
			var_13_30:addTo(var_13_5)
			var_13_30:setAnchorPoint(cc.p(0.5, 0.5))
			var_13_30:setPosition(var_13_7:getPositionX() + 4, var_13_7:getPositionY() - 0.5)
			var_13_30:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
			var_13_5:getChildByName("border"):setLocalZOrder(var_13_30:getLocalZOrder() + 1)
			var_13_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
				if arg_14_0.name == "began" then
					var_13_5:setScale(0.9)

					return true
				elseif arg_14_0.name == "ended" then
					var_13_5:setScale(1)

					if not arg_13_0.scrollViewMoved_ then
						if var_13_6:isAwaken() == true then
							local var_14_0 = xyd.WindowManager.get():getWindow("wash_hero")

							if var_14_0 then
								local var_14_1 = arg_13_0.player_:getHeroByID(var_13_6:getHeroID())

								var_14_0:setHero(var_14_1, true, false)
							end

							xyd.WindowManager.get():closeWindow("wash_select_hero")
						else
							local var_14_2 = var_0_1:translation("HERO_NOT_AWAKEN")

							xyd.WindowManager.get():openWindow("toast", {
								message = var_14_2
							})
						end
					end
				end
			end)
		end

		var_13_0:addContent(var_13_3)
		var_13_0:setItemSize(720, 150)

		return var_13_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_13_2 then
		-- block empty
	end
end

function var_0_0.didOpen(arg_15_0)
	arg_15_0:addBlockLayer()
	arg_15_0.heroList_:reload()
end

return var_0_0
