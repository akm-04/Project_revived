local var_0_0 = class("DormRoomSelectHeroWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = 5
local var_0_2 = 30
local var_0_3 = 1
local var_0_4 = xyd.tables.heroTable
local var_0_5 = xyd.tables.translation
local var_0_6 = xyd.tables.dormHouse
local var_0_7 = {
	PET = 2,
	HERO = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dorm = xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)
	arg_1_0.houseDetail = arg_1_0.dorm.houseDetail
	arg_1_0.tmpHeros_ = {}
	arg_1_0.totalHero_ = {}
	arg_1_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_1_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.FILTER] = {}
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.enterHeros = arg_1_2.enterHeros
	arg_1_0.tableId = arg_1_2.table_id
	arg_1_0.heroNumLimit = arg_1_2.hero_num_limit
	arg_1_0.selectHeros = clone(arg_1_0.enterHeros)
	arg_1_0.houseType = var_0_6:maintype(arg_1_0.tableId)

	arg_1_0:initHeroInfos()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.initHeroInfos(arg_3_0)
	arg_3_0.heros_ = arg_3_0:getHeros()

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

	arg_3_0:updateFilterHeros()
end

function var_0_0.getHeros(arg_4_0)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in pairs(arg_4_0.selfPlayer.heros_) do
		table.insert(var_4_0, iter_4_1)
	end

	return var_4_0
end

function var_0_0.canHeroJoinBattle(arg_5_0, arg_5_1)
	return true
end

function var_0_0.sortHeros(arg_6_0, arg_6_1)
	local var_6_0 = xyd.tables.player:heroMaxLev(arg_6_0.selfPlayer.lev)

	table.sort(arg_6_1, function(arg_7_0, arg_7_1)
		if arg_6_0.houseType == xyd.DormType.LOUNGE then
			if arg_7_0.level_ >= var_6_0 and arg_7_1.level_ < var_6_0 then
				return false
			elseif arg_7_0.level_ < var_6_0 and arg_7_1.level_ >= var_6_0 then
				return true
			end
		end

		return xyd.heroNormalSort(arg_7_0, arg_7_1) or false
	end)
end

function var_0_0.layout(arg_8_0)
	arg_8_0:initMenu()

	local var_8_0 = arg_8_0:nodeByName("hero_list")
	local var_8_1 = var_8_0:getContentSize()

	arg_8_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_8_1.width, var_8_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_8_0):onScroll(handler(arg_8_0, arg_8_0.scrollListener))

	arg_8_0.heroList_:setDelegate(handler(arg_8_0, arg_8_0.delegate))
end

function var_0_0.initMenu(arg_9_0)
	arg_9_0.heroClassButtons_ = {}

	local var_9_0 = arg_9_0:nodeByName("container")

	table.insert(arg_9_0.heroClassButtons_, arg_9_0:nodeByName("quanbu_button"))
	table.insert(arg_9_0.heroClassButtons_, arg_9_0:nodeByName("qianpai_button"))
	table.insert(arg_9_0.heroClassButtons_, arg_9_0:nodeByName("zhongpai_button"))
	table.insert(arg_9_0.heroClassButtons_, arg_9_0:nodeByName("houpai_button"))

	for iter_9_0 = 1, #arg_9_0.heroClassButtons_ do
		arg_9_0.heroClassButtons_[iter_9_0]:setZoomScale(0.3)
		arg_9_0.heroClassButtons_[iter_9_0]:addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()
				arg_9_0:refreshSelectedHeroClass(iter_9_0)
			end
		end)
	end

	arg_9_0:nodeByName("filter_button"):addTouchEventListener(function(arg_11_0, arg_11_1)
		local var_11_0 = {
			checkAwaken = 1
		}

		xyd.WindowManager.get():openWindow("hero_filter", var_11_0)
	end)
	arg_9_0:nodeByName("sure_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playTabButtonSound()

			if not arg_9_0:isHeroChanged() then
				xyd.WindowManager.get():closeWindow(arg_9_0)

				return
			end

			local var_12_0 = arg_9_0.selectHeros
			local var_12_1 = arg_9_0.callback

			for iter_12_0 = 1, #var_12_0 do
				var_12_0[iter_12_0] = arg_9_0.selfPlayer:getHeroByID(var_12_0[iter_12_0]:getHeroID())
			end

			local var_12_2 = {
				house_id = arg_9_0.houseDetail.house_id,
				partner_ids = {}
			}

			for iter_12_1 = 1, #var_12_0 do
				table.insert(var_12_2.partner_ids, var_12_0[iter_12_1]:getHeroID())
			end

			if arg_9_0.houseType ~= xyd.DormType.LOUNGE then
				local var_12_3 = math.ceil(xyd.tables.misc.dormGirlsCoolTime / 3600)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_5:translation("DORM_CHANGE_HERO_TIME_TIP"), var_12_3), function()
					arg_9_0.dorm:enterHero(var_12_2, function(arg_14_0, arg_14_1)
						if arg_14_0 == xyd.error.OK then
							var_12_1(var_12_0)
							xyd.WindowManager.get():closeWindow(arg_9_0)
						end
					end)
				end, nil, nil, arg_9_0.colorMode)
			else
				arg_9_0.dorm:enterHero(var_12_2, function(arg_15_0, arg_15_1)
					if arg_15_0 == xyd.error.OK then
						var_12_1(var_12_0)
						xyd.WindowManager.get():closeWindow(arg_9_0)
					end
				end)
			end
		end
	end)
end

function var_0_0.isHeroChanged(arg_16_0)
	if #arg_16_0.selectHeros ~= #arg_16_0.enterHeros then
		return true
	end

	for iter_16_0 = 1, #arg_16_0.selectHeros do
		local var_16_0 = false

		for iter_16_1 = 1, #arg_16_0.enterHeros do
			if arg_16_0.selectHeros[iter_16_0]:getHeroID() == arg_16_0.enterHeros[iter_16_1]:getHeroID() then
				var_16_0 = true

				break
			end
		end

		if not var_16_0 then
			return true
		end
	end

	return false
end

function var_0_0.refreshSelectedHeroClass(arg_17_0, arg_17_1)
	arg_17_0.heroList_:removeAllItems()

	if arg_17_1 == 1 then
		arg_17_0.tmpHeros_ = arg_17_0.heros_
	elseif arg_17_1 == 2 then
		arg_17_0.tmpHeros_ = arg_17_0.totalHero_[xyd.DistanceType.QIANPAI]
	elseif arg_17_1 == 3 then
		arg_17_0.tmpHeros_ = arg_17_0.totalHero_[xyd.DistanceType.ZHONGPAI]
	elseif arg_17_1 == 4 then
		arg_17_0.tmpHeros_ = arg_17_0.totalHero_[xyd.DistanceType.HOUPAI]
	elseif arg_17_1 == 5 then
		arg_17_0.tmpHeros_ = arg_17_0.totalHero_[xyd.DistanceType.FILTER]
	else
		arg_17_0.tmpHeros_ = arg_17_0.heros_
	end

	for iter_17_0 = 1, #arg_17_0.heroClassButtons_ do
		if arg_17_1 == iter_17_0 then
			arg_17_0.heroClassButtons_[iter_17_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_17_0.heroClassButtons_[iter_17_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_17_0.heroList_:reload()
end

function var_0_0.scrollListener(arg_18_0, arg_18_1)
	if arg_18_1.name == "began" then
		arg_18_0.scrollViewMoved_ = false
		arg_18_0.prevY_ = arg_18_1.y
	elseif arg_18_1.name == "moved" and 10 <= math.abs(arg_18_1.y - arg_18_0.prevY_) then
		arg_18_0.scrollViewMoved_ = true
	end
end

function var_0_0.delegate(arg_19_0, ...)
	return arg_19_0:heroDelegate(...)
end

function var_0_0.heroDelegate(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	arg_20_0.totalNum = #arg_20_0.tmpHeros_

	local var_20_0 = math.ceil(arg_20_0.totalNum / var_0_1)

	if cc.ui.UIListView.COUNT_TAG == arg_20_2 then
		return var_20_0
	elseif cc.ui.UIListView.CELL_TAG == arg_20_2 then
		local var_20_1
		local var_20_2 = arg_20_0.heroList_:dequeueItem()

		if not var_20_2 then
			var_20_2 = arg_20_0.heroList_:newItem()
		else
			var_20_2:removeAllChildren(true)
		end

		local var_20_3 = arg_20_0:createListContent(arg_20_3)

		var_20_2:setItemSize(arg_20_0.heroList_.viewRect_.width, var_20_3:getContentSize().height)
		var_20_2:addContent(var_20_3)

		return var_20_2
	end
end

function var_0_0.createListContent(arg_21_0, arg_21_1)
	local var_21_0 = display.newNode()

	var_21_0:setTouchSwallowEnabled(false)

	local var_21_1

	for iter_21_0 = 1, var_0_1 do
		if (arg_21_1 - 1) * var_0_1 + iter_21_0 <= arg_21_0.totalNum then
			local var_21_2 = (arg_21_1 - 1) * var_0_1 + iter_21_0

			var_21_1 = arg_21_0:initHeroCell(var_21_2)

			local var_21_3 = var_21_1:getContentSize().width
			local var_21_4 = var_21_1:getContentSize().height
			local var_21_5 = (arg_21_0.heroList_.viewRect_.width - var_21_3 * var_0_1) / (var_0_1 + 1)

			var_21_1:pos(var_21_5 * iter_21_0 + (iter_21_0 - 1) * var_21_3 + var_21_3 / 2, var_0_2 + var_21_4 / 2 - 2)
			var_21_0:addChild(var_21_1)
		end
	end

	var_21_0:setContentSize(cc.size(arg_21_0.heroList_.viewRect_.width, var_21_1:getContentSize().height + var_0_2))

	return var_21_0
end

function var_0_0.initHeroCell(arg_22_0, arg_22_1)
	local var_22_0 = display.newNode()
	local var_22_1 = arg_22_0.tmpHeros_[arg_22_1]
	local var_22_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")

	var_22_2:getChildByName("yongbing_tubiao"):setVisible(false)

	local var_22_3 = var_22_2:getChildByName("background"):getContentSize()

	var_22_2:setContentSize(var_22_3)
	var_22_0:setContentSize(var_22_3)
	xyd.setAvatarBorder(var_22_1, var_22_2:getChildByName("avatar"))

	local var_22_4 = var_22_2:getChildByName("chosen")

	var_22_4:setLocalZOrder(100)
	var_22_4:setVisible(false)

	local var_22_5 = var_22_2:getChildByName("avatar_mask")

	var_22_5:setLocalZOrder(2)
	var_22_5:setVisible(false)

	var_22_0.type = var_0_7.HERO

	var_22_2:getChildByName("is_can_rent"):setVisible(false)

	for iter_22_0 = 1, 3 do
		var_22_2:getChildByName("team" .. iter_22_0):setVisible(false)
	end

	var_22_2:getChildByName("lv_txt"):setString(var_22_1:getLevel())

	local var_22_6 = var_22_2:getChildByName("name_text")

	var_22_6:setString(var_22_1:getName())
	var_22_6:enableOutline(cc.c4b(0, 0, 0, 105), 1)

	if xyd.Color2Level[var_22_1:getColor()] ~= "" then
		local var_22_7 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_22_6:getX() + var_22_6:getWidth() / 2 - 10,
			y = var_22_6:getY(),
			color = xyd.color.HERO_QUALITY[var_22_1:getColor()],
			text = xyd.Color2Level[var_22_1:getColor()]
		}
		local var_22_8 = xyd.AssetLoader.get():loadLabel(var_22_7)

		var_22_8:addTo(var_22_2)
		var_22_8:align(display.CENTER_LEFT)
		var_22_8:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_22_6:x(var_22_6:getX() - 15)
	end

	local var_22_9 = var_22_2:getChildByName("hp_bar")
	local var_22_10 = var_22_2:getChildByName("mp_bar")
	local var_22_11 = var_22_2:getChildByName("dead_text")

	var_22_11:setString(var_0_5:translation("ALREADY_DEAD"))

	if var_22_11 then
		var_22_11:setVisible(false)
	end

	var_22_9:hide()
	var_22_10:hide()
	var_22_2:getChildByName("hp_di"):hide()
	var_22_2:getChildByName("mp_di"):hide()
	var_22_2:setName("layout")
	var_22_2:setPosition(cc.p(0, 0))

	var_22_0.data = var_22_1

	var_22_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_22_0:addChild(var_22_2)
	var_22_0:setTouchSwallowEnabled(false)
	var_22_0:setTouchEnabled(true)
	var_22_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
		if arg_23_0.name == "began" then
			arg_22_0.startClick_ = true
			arg_22_0.prevX_ = arg_23_0.x
			arg_22_0.prevY_ = arg_23_0.y
		elseif arg_23_0.name == "moved" then
			if math.abs(arg_23_0.y - arg_22_0.prevY_) > 5 or math.abs(arg_23_0.x - arg_22_0.prevX_) > 5 then
				arg_22_0.startClick_ = false
			end
		elseif arg_23_0.name == "ended" and arg_22_0.startClick_ then
			arg_22_0:clickAvatar(var_22_0.data)
		end

		return true
	end)

	if arg_22_0:checkCanSelect(var_22_1) then
		var_22_5:setVisible(false)
		var_22_4:setVisible(false)
	else
		var_22_5:setVisible(true)
		var_22_4:setVisible(true)
	end

	return var_22_0
end

function var_0_0.clickAvatar(arg_24_0, arg_24_1)
	for iter_24_0 = 1, #arg_24_0.selectHeros do
		if arg_24_1:getHeroID() == arg_24_0.selectHeros[iter_24_0]:getHeroID() and arg_24_0.heroNumLimit > 1 then
			table.remove(arg_24_0.selectHeros, iter_24_0)
			arg_24_0.heroList_:refreshList()

			return
		end
	end

	if arg_24_0.heroNumLimit == 1 then
		arg_24_0.selectHeros = {
			arg_24_1
		}
	elseif #arg_24_0.selectHeros < arg_24_0.heroNumLimit then
		table.insert(arg_24_0.selectHeros, arg_24_1)
	else
		xyd.WindowManager.get():openWindow("toast", {
			message = xyd.tables.translation:translation("DORM_HERO_LIMIT_TIP")
		})

		return
	end

	arg_24_0.heroList_:refreshList()
end

function var_0_0.checkCanSelect(arg_25_0, arg_25_1)
	for iter_25_0 = 1, #arg_25_0.selectHeros do
		if arg_25_1:getHeroID() == arg_25_0.selectHeros[iter_25_0]:getHeroID() then
			return false
		end
	end

	return true
end

function var_0_0.didOpen(arg_26_0)
	arg_26_0:addBlockLayer()
	arg_26_0:refreshSelectedHeroClass(var_0_3)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_26_0):addEventListener(xyd.event.UPDATE_FILTER_HEROS, handler(arg_26_0, arg_26_0.updateList))
end

function var_0_0.updateList(arg_27_0)
	arg_27_0:updateFilterHeros()
	arg_27_0:refreshSelectedHeroClass(xyd.DistanceType.FILTER)
end

function var_0_0.updateFilterHeros(arg_28_0)
	arg_28_0.totalHero_[xyd.DistanceType.FILTER] = {}

	local var_28_0 = {
		0,
		0,
		0
	}
	local var_28_1 = {
		0,
		0,
		0
	}
	local var_28_2 = {
		0,
		0,
		0,
		0
	}
	local var_28_3 = {
		0,
		0,
		0
	}

	if arg_28_0.selfPlayer.sortType and arg_28_0.selfPlayer.sortType > 0 then
		local var_28_4 = {}
		local var_28_5 = arg_28_0.selfPlayer.sortType
		local var_28_6 = 1

		while var_28_5 > 0 do
			var_28_4[var_28_6] = var_28_5 % 2
			var_28_6 = var_28_6 + 1
			var_28_5 = math.floor(var_28_5 / 2)
		end

		local var_28_7 = 1

		for iter_28_0 = 13, 1, -1 do
			if iter_28_0 <= 4 then
				if iter_28_0 == 4 then
					var_28_7 = 1
				end

				var_28_2[var_28_7] = var_28_4[iter_28_0]
			elseif iter_28_0 <= 7 then
				if iter_28_0 == 7 then
					var_28_7 = 1
				end

				var_28_1[var_28_7] = var_28_4[iter_28_0]
			elseif iter_28_0 <= 10 then
				if iter_28_0 == 10 then
					var_28_7 = 1
				end

				var_28_0[var_28_7] = var_28_4[iter_28_0]
			elseif iter_28_0 <= 13 then
				if iter_28_0 == 13 then
					var_28_7 = 1
				end

				if var_28_4[iter_28_0] then
					var_28_3[var_28_7] = var_28_4[iter_28_0]
				end
			end

			var_28_7 = var_28_7 + 1
		end
	else
		var_28_0 = {
			1,
			1,
			1
		}
		var_28_1 = {
			1,
			1,
			1
		}
		var_28_2 = {
			1,
			1,
			1,
			1
		}
		var_28_3 = {
			1,
			1,
			1
		}
	end

	for iter_28_1, iter_28_2 in pairs(arg_28_0.heros_) do
		if var_28_0[iter_28_2:getDistanceType() - 1] == 1 and var_28_1[iter_28_2:getHeroType()] == 1 and var_28_2[iter_28_2:getFromType()] == 1 and arg_28_0:canHeroJoinBattle(iter_28_2) and var_28_3[iter_28_2:getAwakenType()] == 1 then
			table.insert(arg_28_0.totalHero_[xyd.DistanceType.FILTER], iter_28_2)
		end
	end
end

return var_0_0
