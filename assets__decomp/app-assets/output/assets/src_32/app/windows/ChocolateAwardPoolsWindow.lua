local var_0_0 = class("ChocolateAwardPoolsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.model.Hero")
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.activityChocolatePool
local var_0_6 = xyd.tables.activityChocolatePoolAward
local var_0_7 = 35

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.CHOCOLATE)
	arg_1_0.heroID = arg_1_2.heroID
	arg_1_0.pool = arg_1_2.pool
	arg_1_0.awardAllNum = xyd.tables.misc.activityChocolatePoolNum
	arg_1_0.poolCostNums = xyd.tables.misc.activityChocolatePoolCostNums
	arg_1_0.remainaward = awardAllNum
	arg_1_0.currentPool = arg_1_2.pool.base_info.pool_id
	arg_1_0.drop_info = arg_1_2.pool.drop_info
	arg_1_0.goNext = arg_1_2.pool.base_info.go_next
	arg_1_0.isDry = arg_1_2.pool.base_info.is_dry
	arg_1_0.getSpecial = arg_1_2.pool.base_info.get_special
	arg_1_0.poolOnShow = arg_1_0.currentPool
	arg_1_0.coin_num = arg_1_2.coin_num
	arg_1_0.saodang_num = arg_1_2.saodang_num
	arg_1_0.challege_num = arg_1_2.challege_num
	arg_1_0.chocolate_num = arg_1_2.chocolate_num
	arg_1_0.base_info = arg_1_2.pool.base_info
	arg_1_0.correspondlist = {}
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	var_0_0.super:didOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0.model:getEndTime() - xyd.ServerTime.get():getServerTime()

	arg_3_0:updateTimeTxt(var_3_0)

	arg_3_0.chocolateHandle = var_0_2.scheduleGlobal(function()
		var_3_0 = var_3_0 - 1

		arg_3_0:updateTimeTxt(var_3_0)
	end, 1)
	arg_3_0.container = arg_3_0:nodeByName("container")
	arg_3_0.cardContainer = arg_3_0:nodeByName("card_container")
	arg_3_0.awardContainer = arg_3_0:nodeByName("award_container")
	arg_3_0.label_index = arg_3_0.pool
	arg_3_0.hero = var_0_3.new()

	arg_3_0.hero:initUnCollected(arg_3_0.heroID)

	arg_3_0.skinDatas = arg_3_0.hero:getSkinDatas()
	arg_3_0.skinIndex = arg_3_0:getInitSkinIndex(arg_3_0.skinDatas)

	arg_3_0:updateCardContainer()
	arg_3_0:updateItemNum()
	arg_3_0:addtxtline()
	arg_3_0:correspond()

	arg_3_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_3_0:nodeByName("scroll"):getWidth(), arg_3_0:nodeByName("scroll"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("scroll")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.listView_:setBounceable(true)
	arg_3_0.listView_:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0:updateLeft(1)

	for iter_3_0 = 1, 6 do
		arg_3_0:nodeByName("btn" .. iter_3_0):addTouchEventListener(function(arg_5_0, arg_5_1)
			if arg_5_1 == ccui.TouchEventType.began then
				return true
			elseif arg_5_1 == ccui.TouchEventType.ended then
				arg_3_0:updateLeft(iter_3_0)

				return true
			end
		end)
	end

	arg_3_0:setButtonClick()
end

function var_0_0.addtxtline(arg_6_0)
	local var_6_0 = arg_6_0:nodeByName("container")
	local var_6_1 = var_6_0:getChildByName("next")
	local var_6_2 = var_6_0:getChildByName("regular")

	var_6_0:getChildByName("xiaofei2"):enableOutline(cc.c4b(144, 50, 198, 255), 2)
	var_6_0:getChildByName("xiaofei20"):enableOutline(cc.c4b(144, 50, 198, 255), 2)
	var_6_1:getChildByName("pool_num"):enableOutline(cc.c4b(228, 73, 150, 255), 2)
	arg_6_0:nodeByName("title_txt"):setString(var_0_4:translation("ACTIVITY_CHOCOLATE_AWARD_POOL_TIP1"))
	arg_6_0:nodeByName("word_next"):setString(var_0_4:translation("ACTIVITY_CHOCOLATE_AWARD_POOL_TIP2"))
	arg_6_0:nodeByName("item_num"):enableOutline(cc.c4b(207, 55, 173, 255), 2)
	arg_6_0:nodeByName("xiaofei2"):enableOutline(cc.c4b(210, 77, 179, 255), 2)
	arg_6_0:nodeByName("xiaofei20"):enableOutline(cc.c4b(210, 77, 179, 255), 2)
	arg_6_0:nodeByName("remain_time_text"):enableOutline(cc.c4b(207, 55, 173, 255), 2)
	arg_6_0:nodeByName("remain_time"):enableOutline(cc.c4b(207, 55, 173, 255), 2)
end

function var_0_0.updateItemNum(arg_7_0)
	arg_7_0.coinID = xyd.tables.misc.activityChocolateSlotMachineItemCoin
	arg_7_0.sweepItemID = xyd.tables.misc.activityChocolateCampaignSweepItem
	arg_7_0.fruitItemID = xyd.tables.misc.activityChocolateFruitItem
	arg_7_0.chocolateItemID = xyd.tables.misc.activityChocolateItem
	arg_7_0.poolResetID = xyd.tables.misc.activityChocolatePoolResetItem
	arg_7_0.coinAllNum = arg_7_0.selfPlayer:getBackpack():getItemNumByID(arg_7_0.coinID)
	arg_7_0.sweepNum = arg_7_0.selfPlayer:getBackpack():getItemNumByID(arg_7_0.sweepItemID)
	arg_7_0.fruitNum = arg_7_0.selfPlayer:getBackpack():getItemNumByID(arg_7_0.fruitItemID)
	arg_7_0.chocolateNum = arg_7_0.selfPlayer:getBackpack():getItemNumByID(arg_7_0.chocolateItemID)
	arg_7_0.poolResetNum = arg_7_0.selfPlayer:getBackpack():getItemNumByID(arg_7_0.poolResetID)
	arg_7_0.isDry = arg_7_0.base_info.is_dry
	arg_7_0.getSpecial = arg_7_0.base_info.get_special
	arg_7_0.goNext = arg_7_0.base_info.go_next
	arg_7_0.currentPool = arg_7_0.base_info.pool_id

	if arg_7_0.goNext == 1 then
		arg_7_0:nodeByName("next_pool"):setBright(true)
		arg_7_0:nodeByName("next_pool"):setTouchEnabled(true)
	else
		arg_7_0:nodeByName("next_pool"):setBright(false)
		arg_7_0:nodeByName("next_pool"):setTouchEnabled(false)
	end

	local var_7_0

	if arg_7_0.currentPool < 10 then
		var_7_0 = arg_7_0.currentPool
	else
		var_7_0 = 10
	end

	local var_7_1 = var_0_6:getids(var_7_0)

	arg_7_0.remainaward = arg_7_0.awardAllNum

	for iter_7_0 = 1, #var_7_1 do
		local var_7_2 = var_7_1[iter_7_0]
		local var_7_3 = tostring(var_7_2)

		if arg_7_0.drop_info[var_7_3] then
			arg_7_0.remainaward = arg_7_0.remainaward - arg_7_0.drop_info[var_7_3]
		end
	end

	arg_7_0:updatetxt()
end

function var_0_0.updatetxt(arg_8_0)
	local var_8_0 = arg_8_0:nodeByName("container"):getChildByName("next")

	arg_8_0:nodeByName("coin"):getChildByName("num"):setString(xyd.num2ThousandsStr(arg_8_0.coinAllNum))
	arg_8_0:nodeByName("challege"):getChildByName("num"):setString(xyd.num2ThousandsStr(arg_8_0.fruitNum))
	arg_8_0:nodeByName("saodang"):getChildByName("num"):setString(xyd.num2ThousandsStr(arg_8_0.sweepNum))
	arg_8_0:nodeByName("chongzhi"):getChildByName("num"):setString(xyd.num2ThousandsStr(arg_8_0.poolResetNum))
	arg_8_0:nodeByName("item_num"):setString(xyd.num2ThousandsStr(arg_8_0.chocolateNum))
	arg_8_0:nodeByName("word_txt_1"):setString(var_0_4:translation("NUM_1") .. var_0_4:translation("ACTIVITY_CHOCOLATE_AWARD_TIP19"))
	arg_8_0:nodeByName("xiaofei2"):setString(var_0_4:translation("ACTIVITY_CHOCOLATE_AWARD_TIP20") .. arg_8_0.poolCostNums)

	local var_8_1 = math.floor(arg_8_0.chocolateNum / arg_8_0.poolCostNums)
	local var_8_2 = math.min(var_8_1, arg_8_0.remainaward)
	local var_8_3 = math.min(var_8_2, 10)

	var_8_3 = var_8_3 < 2 and 10 or var_8_3

	arg_8_0:nodeByName("word_txt_10"):setString(var_0_4:translation("NUM_" .. var_8_3) .. var_0_4:translation("ACTIVITY_CHOCOLATE_AWARD_TIP19"))
	arg_8_0:nodeByName("xiaofei20"):setString(var_0_4:translation("ACTIVITY_CHOCOLATE_AWARD_TIP20") .. arg_8_0.poolCostNums * var_8_3)

	local var_8_4 = arg_8_0.remainaward < 2

	arg_8_0:nodeByName("excat_10"):setVisible(not var_8_4)
	arg_8_0:nodeByName("icon_chocolate10"):setVisible(not var_8_4)
	arg_8_0:nodeByName("xiaofei20"):setVisible(not var_8_4)
	arg_8_0:nodeByName("excat_1"):pos(174 + (var_8_4 and 125 or 0), 113)
	arg_8_0:nodeByName("icon_chocolate1"):pos(124 + (var_8_4 and 125 or 0), 55)
	arg_8_0:nodeByName("xiaofei2"):pos(157 + (var_8_4 and 125 or 0), 52)
	var_8_0:getChildByName("award_num"):setString(arg_8_0.remainaward .. "/" .. arg_8_0.awardAllNum)
	var_8_0:getChildByName("pool_num"):setString(arg_8_0.currentPool)
end

function var_0_0.updateLeft(arg_9_0, arg_9_1)
	arg_9_0.label_index = arg_9_1

	for iter_9_0 = 1, 7 do
		arg_9_0:nodeByName("btn" .. iter_9_0):setBrightStyle(ccui.BrightStyle.normal)
	end

	for iter_9_1 = 1, 6 do
		arg_9_0:nodeByName("btn" .. iter_9_1):getChildByName("txt"):setString(string.format(var_0_4:translation("ACTIVITY_CHOCOLATE_AWARD_TIP10"), arg_9_0.currentPool + iter_9_1 - 1))
	end

	arg_9_0:nodeByName("btn" .. arg_9_1):setBrightStyle(ccui.BrightStyle.highlight)

	arg_9_0.poolOnShow = arg_9_1 + arg_9_0.currentPool - 1

	if arg_9_0.poolOnShow == arg_9_0.currentPool then
		arg_9_0.container:getChildByName("hide_award"):setVisible(false)
	else
		arg_9_0.container:getChildByName("hide_award"):setVisible(true)
	end

	arg_9_0.listView_:reload()
end

function var_0_0.updateCardContainer(arg_10_0)
	arg_10_0:setHeroCardBaseOnCardState(arg_10_0.hero)
end

function var_0_0.getOneLineNum(arg_11_0, arg_11_1)
	local var_11_0 = 0

	if arg_11_1 < 10 then
		var_11_0 = arg_11_1
	else
		var_11_0 = 10
	end

	local var_11_1 = var_0_5:awardId(var_11_0)
	local var_11_2 = var_0_6:poolList()
	local var_11_3 = 0

	for iter_11_0 = 1, #var_11_2 do
		if var_11_2[iter_11_0] == var_11_1 then
			var_11_3 = var_11_3 + 1
		end
	end

	return var_11_3
end

function var_0_0.delegate(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	if cc.ui.UIListView.COUNT_TAG == arg_12_2 then
		return (arg_12_0:getOneLineNum(arg_12_0.poolOnShow))
	elseif cc.ui.UIListView.CELL_TAG == arg_12_2 then
		local var_12_0 = arg_12_0.listView_:dequeueItem()

		if not var_12_0 then
			var_12_0 = arg_12_0.listView_:newItem()
		else
			var_12_0:removeAllChildren(true)
		end

		local var_12_1 = arg_12_0:createListContent(arg_12_3)
		local var_12_2 = var_12_1:getWidth()
		local var_12_3 = var_12_1:getHeight()

		var_12_0:setItemSize(var_12_2, var_12_3 + 12)
		var_12_0:addContent(var_12_1)

		return var_12_0
	end
end

function var_0_0.createListContent(arg_13_0, arg_13_1)
	local var_13_0 = 0

	if arg_13_0.poolOnShow < 10 then
		var_13_0 = arg_13_0.poolOnShow
	else
		var_13_0 = 10
	end

	if arg_13_0.poolOnShow == arg_13_0.currentPool then
		arg_13_0:correspond()

		arg_13_1 = arg_13_0.correspondlist[arg_13_1]
	end

	local var_13_1 = var_0_5:awardId(var_13_0)
	local var_13_2 = var_0_6:poolList()
	local var_13_3 = var_0_5:isSpecial(var_13_0)

	if var_13_3 == 1 then
		local var_13_4 = var_0_5:specialItem(var_13_0)
	end

	local var_13_5 = display.newNode()
	local var_13_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/chocolate/award_pools/pool/mission_item.csb")
	local var_13_7 = var_13_6:getChildByName("container")
	local var_13_8 = var_0_6:items(var_13_0)
	local var_13_9 = var_0_6:getids(var_13_0)
	local var_13_10 = var_13_8[arg_13_1]
	local var_13_11 = var_13_9[arg_13_1]

	if var_13_10 and var_13_10 > 0 then
		arg_13_0:rewardLayer(var_13_7:getChildByName("award_container"), var_13_10, var_13_11)
	end

	local var_13_12 = xyd.tables.item:name(var_13_10)

	var_13_7:getChildByName("mission"):setString(var_13_12)
	var_13_7:getChildByName("mission_commom"):setString(var_13_12)

	local var_13_13 = var_13_9[arg_13_1]
	local var_13_14 = tostring(var_13_13)
	local var_13_15 = var_0_6:extractTimes(var_13_13)
	local var_13_16 = var_13_15

	if arg_13_0.drop_info[var_13_14] then
		var_13_16 = var_13_15 - arg_13_0.drop_info[var_13_14]
	end

	if arg_13_0.poolOnShow ~= arg_13_0.currentPool then
		var_13_16 = var_13_15
	end

	var_13_7:getChildByName("excat_num_txt"):setString(var_13_16 .. "/" .. var_13_15)
	var_13_7:getChildByName("discraption"):setString(var_0_4:translation("ACTIVITY_CHOCOLATE_AWARD_TIP9"))

	if var_13_16 == 0 then
		var_13_7:getChildByName("award_gray"):setVisible(true)
	end

	if arg_13_1 == 1 and var_13_3 == 1 then
		var_13_7:getChildByName("important"):setVisible(true)
		var_13_7:getChildByName("commom"):setVisible(false)
		var_13_7:getChildByName("mission"):setVisible(true)
		var_13_7:getChildByName("mission_commom"):setVisible(false)
		var_13_7:getChildByName("discraption"):setVisible(true)
	else
		var_13_7:getChildByName("important"):setVisible(false)
		var_13_7:getChildByName("commom"):setVisible(true)
		var_13_7:getChildByName("mission"):setVisible(false)
		var_13_7:getChildByName("mission_commom"):setVisible(true)
		var_13_7:getChildByName("discraption"):setVisible(false)
	end

	var_13_6:setTouchEnabled(true)
	var_13_6:setTouchSwallowEnabled(false)
	var_13_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		if arg_14_0.name == "began" then
			return true
		elseif arg_14_0.name == "ended" then
			if arg_13_0.scrollViewMoved_ then
				return
			end

			xyd.playButtonSound()
			arg_13_0.listView_:refreshList()
		end
	end)
	var_13_6:addTo(var_13_5)
	var_13_6:setAnchorPoint(cc.p(0, 0))
	var_13_5:setContentSize(var_13_7:getContentSize())
	var_13_6:setName("source")

	return var_13_5
end

function var_0_0.getInitSkinIndex(arg_15_0, arg_15_1)
	local var_15_0 = 1

	for iter_15_0 = 2, #arg_15_1 do
		local var_15_1 = arg_15_1[iter_15_0]

		if var_15_1.isHave then
			if var_15_1.cardState == xyd.CardStatus.AWAKE_CARD then
				var_15_0 = iter_15_0
			elseif var_15_1.cardState == xyd.CardStatus.SKIN_CARD and (arg_15_0.hero.isSkinOn_ == 1 and arg_15_0.hero.skinId_ == var_15_1.modelID or arg_15_0.hero.isSkinOn_ == 0) then
				return iter_15_0
			end
		end
	end

	return var_15_0
end

function var_0_0.setHeroCardBaseOnCardState(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_0.skinDatas[arg_16_0.skinIndex]
	local var_16_1 = var_16_0.modelID
	local var_16_2 = xyd.tables.libraryHomeCard:x(var_16_1)
	local var_16_3 = xyd.tables.libraryHomeCard:y(var_16_1)
	local var_16_4 = xyd.tables.model:live2d(var_16_1)

	if arg_16_0.live2d and not tolua.isnull(arg_16_0.live2d) and arg_16_0.live2d.showHeroID == var_16_1 and xyd.isLive2dCanUse() then
		return
	end

	if not arg_16_0 or tolua.isnull(arg_16_0) or not arg_16_0.cardContainer or tolua.isnull(arg_16_0.cardContainer) then
		return
	end

	arg_16_0.cardContainer:removeAllChildren()

	arg_16_0.live2d = nil

	if not var_16_4 or var_16_4 == "" or not xyd.isLive2dCanUse() then
		if not xyd.getTransparentCard(arg_16_1, xyd.SkinDynamicPosType.LIBRARY, var_16_0.modelID) then
			return
		end

		arg_16_0:addDialog(touchAreaSize)
	end
end

function var_0_0.addDialog(arg_17_0, arg_17_1)
	local var_17_0 = {
		touchPosition = cc.p(0, -25),
		touchAreaSize = touchAreaSize or {
			width = 420,
			height = 400
		},
		msgs = clone(xyd.tables.hero:clickDialog(arg_17_0.hero:getTableID())),
		sounds = clone(xyd.tables.hero:dialogSounds(arg_17_0.hero:getTableID())),
		times = clone(xyd.tables.hero:soundTimes(arg_17_0.hero:getTableID())),
		heroTableID = arg_17_0.hero:getTableID(),
		noTouch = arg_17_1
	}

	var_17_0.chocolate = true
	var_17_0.name = arg_17_0.hero:getName()

	local var_17_1, var_17_2 = arg_17_0.hero:getHeroVoiceState()

	arg_17_0.speakCellContent = import("app.windows.ChocolateSpeakWindow").new(var_17_0)

	arg_17_0.speakCellContent:addTo(arg_17_0.cardContainer)
	arg_17_0.speakCellContent:setAnchorPoint(cc.p(0, 0))
	arg_17_0.speakCellContent:setPosition(arg_17_0:nodeByName("talks_pos"):getPosition())
end

function var_0_0.setButtonClick(arg_18_0)
	arg_18_0:nodeByName("btn7"):addTouchEventListener(function(arg_19_0, arg_19_1)
		if arg_19_1 == ccui.TouchEventType.began then
			return true
		elseif arg_19_1 == ccui.TouchEventType.ended then
			local var_19_0 = var_0_4:translation("ACTIVITY_CHOCOLATE_AWARD_TIP18")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_19_0
			})

			return true
		end
	end)
	arg_18_0:nodeByName("excat_1"):addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.began then
			arg_18_0:nodeByName("excat_1"):setScale(0.9)
		elseif arg_20_1 == ccui.TouchEventType.moved then
			arg_18_0:nodeByName("excat_1"):setScale(1)
		elseif arg_20_1 == ccui.TouchEventType.ended then
			arg_18_0:nodeByName("excat_1"):setScale(1)
			xyd.playButtonSound()

			local var_20_0 = true

			if arg_18_0.remainaward < 1 then
				var_20_0 = false

				local var_20_1 = var_0_4:translation("ACTIVITY_CHOCOLATE_AWARD_TIP1")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_20_1
				})
			end

			if arg_18_0.chocolateNum >= arg_18_0.poolCostNums and var_20_0 then
				local var_20_2 = 1
				local var_20_3 = {
					times = var_20_2
				}

				arg_18_0.model:chocolateDrawPool(var_20_3, function(arg_21_0, arg_21_1)
					if arg_21_0 == xyd.error.OK then
						arg_18_0.chocolateNum = arg_18_0.chocolateNum - arg_18_0.poolCostNums

						local var_21_0 = arg_18_0.poolCostNums
						local var_21_1 = arg_21_1
						local var_21_2 = {
							itemID = arg_18_0.chocolateItemID,
							itemNum = var_21_0
						}

						arg_18_0.selfPlayer:getBackpack():removeItem(var_21_2)

						local var_21_3 = 0

						if arg_18_0.currentPool < 10 then
							var_21_3 = arg_18_0.currentPool
						else
							var_21_3 = 10
						end

						local var_21_4 = var_0_6:getids(var_21_3)
						local var_21_5 = arg_18_0:getOneLineNum(arg_18_0.currentPool)
						local var_21_6 = arg_21_1.drop_info
						local var_21_7 = arg_21_1.base_info
						local var_21_8
						local var_21_9
						local var_21_10 = 1

						arg_18_0.drop_info = arg_21_1.drop_info
						arg_18_0.base_info = arg_21_1.base_info

						arg_18_0:updateLeft(1)
						arg_18_0:updateItemNum()

						if arg_21_1 and arg_21_1.awards then
							local var_21_11 = {}

							arg_18_0.selfPlayer:handleRewardsWithoutShow(arg_21_1.awards)

							for iter_21_0, iter_21_1 in pairs(arg_21_1.awards) do
								if tonumber(iter_21_0) then
									table.insert(var_21_11, iter_21_1)
								end
							end

							local var_21_12 = {
								items = var_21_11,
								times = var_20_2,
								extraAward = arg_21_1.items
							}

							for iter_21_2, iter_21_3 in pairs(var_21_11) do
								arg_18_0.selfPlayer:heroUpdateEvent_({
									name = xyd.event.HERO_UPDATE,
									params = iter_21_3
								}, true)
							end

							xyd.WindowManager.get():openWindow("chocolate_award_show", var_21_12)
						end
					end
				end)
			elseif arg_18_0.chocolateNum < arg_18_0.poolCostNums and var_20_0 then
				xyd.CommonAlertWindow.open(xyd.AlertType.YES_NO, {
					var_0_4:translation("ACTIVITY_CHOCOLATE_POOL_TIP1")
				}, function()
					arg_18_0.model:enterMap()
				end, nil, nil, xyd.ColorMode.ACTIVITY)

				return
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_4:translation("ACTIVITY_CHOCOLATE_POOL_TIP2")
				})
			end
		end
	end)
	arg_18_0:nodeByName("excat_10"):addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.began then
			arg_18_0:nodeByName("excat_10"):setScale(0.9)
		elseif arg_23_1 == ccui.TouchEventType.moved then
			arg_18_0:nodeByName("excat_10"):setScale(1)
		elseif arg_23_1 == ccui.TouchEventType.ended then
			arg_18_0:nodeByName("excat_10"):setScale(1)
			xyd.playButtonSound()

			local var_23_0 = true

			if arg_18_0.remainaward < 1 then
				var_23_0 = false

				local var_23_1 = var_0_4:translation("ACTIVITY_CHOCOLATE_AWARD_TIP1")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_23_1
				})
			end

			local var_23_2 = math.floor(arg_18_0.chocolateNum / arg_18_0.poolCostNums)
			local var_23_3 = math.min(var_23_2, arg_18_0.remainaward)
			local var_23_4 = math.min(var_23_3, 10)

			var_23_4 = var_23_4 < 2 and 10 or var_23_4

			if arg_18_0.chocolateNum >= var_23_4 * arg_18_0.poolCostNums and var_23_0 then
				local var_23_5 = var_23_4
				local var_23_6 = {
					times = var_23_5
				}

				arg_18_0.model:chocolateDrawPool(var_23_6, function(arg_24_0, arg_24_1)
					if arg_24_0 == xyd.error.OK then
						arg_18_0.chocolateNum = arg_18_0.chocolateNum - var_23_4 * arg_18_0.poolCostNums

						local var_24_0 = var_23_4 * arg_18_0.poolCostNums
						local var_24_1 = arg_24_1
						local var_24_2 = {
							itemID = arg_18_0.chocolateItemID,
							itemNum = var_24_0
						}

						arg_18_0.selfPlayer:getBackpack():removeItem(var_24_2)

						local var_24_3 = 0

						if arg_18_0.currentPool < 10 then
							var_24_3 = arg_18_0.currentPool
						else
							var_24_3 = 10
						end

						local var_24_4 = var_0_6:getids(var_24_3)
						local var_24_5 = arg_18_0:getOneLineNum(arg_18_0.currentPool)
						local var_24_6 = arg_24_1.drop_info
						local var_24_7 = arg_24_1.base_info
						local var_24_8
						local var_24_9
						local var_24_10 = 1

						arg_18_0.drop_info = arg_24_1.drop_info
						arg_18_0.base_info = arg_24_1.base_info

						arg_18_0:updateLeft(1)
						arg_18_0:updateItemNum()

						if arg_24_1 and arg_24_1.awards then
							local var_24_11 = {}

							arg_18_0.selfPlayer:handleRewardsWithoutShow(arg_24_1.awards)

							for iter_24_0, iter_24_1 in pairs(arg_24_1.awards) do
								if tonumber(iter_24_0) then
									table.insert(var_24_11, iter_24_1)
								end
							end

							local var_24_12 = {
								items = var_24_11,
								times = var_23_5,
								extraAward = arg_24_1.items
							}

							for iter_24_2, iter_24_3 in pairs(var_24_11) do
								arg_18_0.selfPlayer:heroUpdateEvent_({
									name = xyd.event.HERO_UPDATE,
									params = iter_24_3
								}, true)
							end

							xyd.WindowManager.get():openWindow("chocolate_award_show", var_24_12)
						end
					end
				end)
			elseif arg_18_0.chocolateNum < var_23_4 * arg_18_0.poolCostNums and var_23_0 then
				xyd.CommonAlertWindow.open(xyd.AlertType.YES_NO, {
					var_0_4:translation("ACTIVITY_CHOCOLATE_POOL_TIP1")
				}, function()
					arg_18_0.model:enterMap()
				end, nil, nil, xyd.ColorMode.ACTIVITY)

				return
			end
		end
	end)
	arg_18_0:nodeByName("next_pool"):addTouchEventListener(function(arg_26_0, arg_26_1)
		if arg_26_1 == ccui.TouchEventType.began then
			arg_18_0:nodeByName("next_pool"):setScale(0.9)
		elseif arg_26_1 == ccui.TouchEventType.moved then
			arg_18_0:nodeByName("next_pool"):setScale(1)
		elseif arg_26_1 == ccui.TouchEventType.ended then
			arg_18_0:nodeByName("next_pool"):setScale(1)

			local var_26_0 = import("app.windows.ChocolateAwardGoNextWindow")
			local var_26_1

			if arg_18_0.isDry == 0 then
				var_26_1 = var_0_4:translation("ACTIVITY_CHOCOLATE_AWARD_TIP4")
			elseif arg_18_0.currentPool < 10 then
				var_26_1 = var_0_4:translation("ACTIVITY_CHOCOLATE_AWARD_TIP5")
			else
				var_26_1 = var_0_4:translation("ACTIVITY_CHOCOLATE_AWARD_TIP6")
			end

			local var_26_2 = true

			if arg_18_0.poolResetNum < 1 and arg_18_0.currentPool >= 10 then
				var_26_2 = false

				local var_26_3 = {}

				var_26_1 = var_0_4:translation("ACTIVITY_CHOCOLATE_AWARD_TIP17")

				var_26_0.open(xyd.AlertType.YES_NO, {
					var_26_1
				}, function(arg_27_0)
					if arg_27_0 then
						arg_18_0.model:chocolateInfo(var_26_3, function(arg_28_0, arg_28_1)
							if arg_28_0 == xyd.error.OK then
								xyd.WindowManager.get():openWindow("chocolate_fruits_main")
							end
						end)
						xyd.WindowManager.get():closeWindow(arg_18_0)
					end
				end)
			end

			if var_26_2 then
				local var_26_4 = {}

				var_26_0.open(xyd.AlertType.YES_NO, {
					var_26_1
				}, function(arg_29_0)
					if arg_29_0 then
						arg_18_0.model:chocolateGoNext(var_26_4, function(arg_30_0, arg_30_1)
							if arg_30_0 == xyd.error.OK then
								arg_18_0.currentPool = arg_18_0.currentPool + 1
								arg_18_0.base_info = arg_30_1.base_info
								arg_18_0.drop_info = arg_30_1.drop_info

								if arg_18_0.currentPool > 10 then
									local var_30_0 = {
										itemID = arg_18_0.poolResetID
									}

									var_30_0.itemNum = 1

									arg_18_0.selfPlayer:getBackpack():removeItem(var_30_0)
								end

								arg_18_0:updateLeft(1)
								arg_18_0:updateItemNum()
							end
						end)
					end
				end)
			end
		end
	end)
	arg_18_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_31_0, arg_31_1)
		if arg_31_1 == ccui.TouchEventType.began then
			arg_18_0:nodeByName("btn_rule"):setScale(0.9)
		elseif arg_31_1 == ccui.TouchEventType.moved then
			arg_18_0:nodeByName("btn_rule"):setScale(1)
		elseif arg_31_1 == ccui.TouchEventType.ended then
			arg_18_0:nodeByName("btn_rule"):setScale(1)

			local var_31_0 = {
				title_name = "ACTIVITY_CHOCOLATE_AWARD_TIP7",
				rule = "ACTIVITY_CHOCOLATE_AWARD_TIP8"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_31_0)
		end
	end)
end

function var_0_0.rewardLayer(arg_32_0, arg_32_1, arg_32_2, arg_32_3)
	local var_32_0 = arg_32_2
	local var_32_1 = var_0_6:itemNum(arg_32_3)
	local var_32_2 = arg_32_1:getContentSize().height
	local var_32_3 = var_32_2 / 4 - 1
	local var_32_4 = display.newNode()

	var_32_4:setContentSize(var_32_2, var_32_2)

	local var_32_5 = xyd.tables.item:type(var_32_0)

	xyd.setItemBorder(var_32_4, var_32_0, false, false, var_32_1)
	var_32_4:addTo(arg_32_1)
	var_32_4:setAnchorPoint(cc.p(0, 0))
	var_32_4:setPosition(0, 0)

	local var_32_6 = {
		id = var_32_0,
		lev = xyd.tables.item:level(var_32_0)
	}

	if xyd.tables.item:type(var_32_0) == -1 then
		var_32_6.tipsType = 0
		var_32_6.desc1 = xyd.tables.hero:getDes(var_32_0)
	elseif specialItem then
		var_32_6.tipsType = 1
		var_32_6.id = -3
	else
		var_32_6.tipsType = 1
		var_32_6.desc1 = xyd.tables.item:desc1(var_32_0)
		var_32_6.desc2 = xyd.tables.item:desc2(var_32_0)
	end

	var_32_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_32_0)
	var_32_6.name = xyd.tables.item:name(var_32_0)

	arg_32_0:addTips(var_32_4, var_32_6)

	return arg_32_1
end

function var_0_0.scrollListener(arg_33_0, arg_33_1)
	if arg_33_1.name == "began" then
		arg_33_0.scrollViewMoved_ = false
		arg_33_0.prevY_ = arg_33_1.y
	elseif arg_33_1.name == "moved" and 20 <= math.abs(arg_33_1.y - arg_33_0.prevY_) then
		arg_33_0.scrollViewMoved_ = true
	end
end

function var_0_0.willClose(arg_34_0)
	var_0_0.super:willClose()

	if arg_34_0.chocolateHandle ~= nil then
		var_0_2.unscheduleGlobal(arg_34_0.chocolateHandle)

		arg_34_0.chocolateHandle = nil
	end
end

function var_0_0.updateTimeTxt(arg_35_0, arg_35_1)
	local var_35_0 = xyd.tables.misc:getValue("activity_chocolate_pool_times")
	local var_35_1 = arg_35_1

	if not tolua.isnull(arg_35_0) then
		arg_35_0:nodeByName("remain_time"):setString(string.format(xyd.secondsToString1(var_35_1)))
	end

	arg_35_0:nodeByName("remain_time_text"):setString(var_0_4:translation("ACTIVITY_CHOCOLATE_AWARD_TIP16"))

	if var_35_1 < 0 then
		if not tolua.isnull(arg_35_0) then
			var_0_2.unscheduleGlobal(arg_35_0.chocolateHandle)
		end

		arg_35_0:nodeByName("remain_time_text"):setString(var_0_4:translation("ACTIVITY_CLOSED"))
		arg_35_0:nodeByName("remain_time"):setVisible(false)
	end
end

function var_0_0.correspond(arg_36_0)
	local var_36_0 = arg_36_0.currentPool

	if var_36_0 > 10 then
		var_36_0 = 10
	end

	local var_36_1 = arg_36_0:getOneLineNum(var_36_0)
	local var_36_2 = var_0_6:items(var_36_0)
	local var_36_3 = var_0_6:getids(var_36_0)
	local var_36_4 = {}
	local var_36_5 = {}
	local var_36_6 = 1
	local var_36_7 = 1

	for iter_36_0 = 1, var_36_1 do
		local var_36_8 = var_36_3[iter_36_0]
		local var_36_9 = tostring(var_36_8)
		local var_36_10 = var_0_6:extractTimes(var_36_8)
		local var_36_11 = var_36_10

		if arg_36_0.drop_info[var_36_9] then
			var_36_11 = var_36_10 - arg_36_0.drop_info[var_36_9]
		end

		if var_36_11 == 0 then
			var_36_5[var_36_7] = iter_36_0
			var_36_7 = var_36_7 + 1
		else
			var_36_4[var_36_6] = iter_36_0
			var_36_6 = var_36_6 + 1
		end
	end

	local var_36_12 = #var_36_4

	for iter_36_1 = 1, #var_36_4 do
		arg_36_0.correspondlist[iter_36_1] = var_36_4[iter_36_1]
	end

	for iter_36_2 = 1, #var_36_5 do
		arg_36_0.correspondlist[iter_36_2 + var_36_12] = var_36_5[iter_36_2]
	end
end

return var_0_0
