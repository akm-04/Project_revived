local var_0_0 = class("WishingPoolWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc.activityAnniversaryWishWordLimit
local var_0_5 = 35

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.wishingTable = xyd.tables.AnniWishingpoolTable
	arg_1_0.gift = xyd.tables.gift
	arg_1_0.isCanGetBag = arg_1_2.isCanGetBag
	arg_1_0.wishTimes = arg_1_2.wishTimes
	arg_1_0.energy = arg_1_2.energy
	arg_1_0.energyLev = arg_1_2.energyLev
	arg_1_0.isCanPreview = 0
	arg_1_0.loadDanmuHandler = nil
	arg_1_0.danmuInfos = {}
	arg_1_0.unusedBallistic = {}
	arg_1_0.danmuItemNums = 0
	arg_1_0.clippingNode = nil
	arg_1_0.isShowDanmu = false
	arg_1_0.showDanmuHandler = nil
	arg_1_0.activityPrayTime = xyd.tables.misc.activityPrayTime
	arg_1_0.awardEffects = {}
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	var_0_0.super:didOpen(arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.danmuContainer = arg_3_0:nodeByName("screen_bullet")

	local var_3_0 = arg_3_0:nodeByName("gift_list")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_0):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setBounceable(true)
	arg_3_0:updatePresentList()

	local var_3_2 = string.format(var_0_3:translation("ANNIVERSARY_WISHED_TIMES"), arg_3_0.wishTimes)

	arg_3_0:nodeByName("word_wished"):setString(var_3_2)
	arg_3_0:nodeByName("word_wished"):enableOutline(cc.c4b(180, 101, 95, 255), 0)
	arg_3_0:nodeByName("spr_energy_txt"):setString(var_0_3:translation("WISHING_POOL_1"))
	arg_3_0:nodeByName("txt_energycost"):setString(arg_3_0.energy)
	arg_3_0:nodeByName("btn_tablet"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.began then
			arg_3_0:nodeByName("btn_tablet"):setScale(0.9)
		elseif arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0:nodeByName("btn_tablet"):setScale(1)

			local var_4_0 = {
				title_name = "ACTIVITY_WISH_RULE_TITLE",
				rule = "ACTIVITY_WISH_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_4_0)
		end
	end)
	arg_3_0:nodeByName("btn_get"):getChildByName("btn_txt"):setString(var_0_3:translation("GET"))
	arg_3_0:nodeByName("btn_get"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_3_0.model:getWishingCoin(function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					if arg_6_1 and arg_6_1.awards then
						arg_3_0.selfPlayer:handleRewards(arg_6_1.awards)
						arg_3_0:updateCoinNum()
					end
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("ANNIVERSARY_GETTINGCOIN_FALSE")
					})
				end
			end)
		end
	end)
	arg_3_0:updateCoinNum()
	arg_3_0:initDanmuBox()
	arg_3_0:nodeByName("bg"):getChildByName("hide_container_1"):setTouchEnabled(true)
	arg_3_0:nodeByName("bg"):getChildByName("hide_container_1"):setTouchSwallowEnabled(true)
	arg_3_0:nodeByName("bg"):getChildByName("hide_container_2"):setTouchEnabled(true)
	arg_3_0:nodeByName("bg"):getChildByName("hide_container_2"):setTouchSwallowEnabled(true)

	arg_3_0.dispatcher = xyd.EventDispatcher.get():addEventListener(xyd.event.WORLD_NOTICE, function(arg_7_0)
		if arg_7_0.params and arg_7_0.params.notice_type == xyd.NoticeType.NEW_YEAR_BLESSING then
			local var_7_0 = arg_7_0.params.params.message

			if var_7_0 then
				table.insert(arg_3_0.danmuInfos, 1, var_7_0)
			end
		end
	end)
end

function var_0_0.updateCoinNum(arg_8_0)
	arg_8_0.coinID = arg_8_0.wishingTable:getCoinID()
	arg_8_0.coinNum = arg_8_0.selfPlayer:getBackpack():getItemNumByID(arg_8_0.coinID)

	arg_8_0:nodeByName("txt_coin"):enableOutline(cc.c4b(180, 101, 95, 255), 0)
	arg_8_0:nodeByName("txt_coin"):setString(arg_8_0.coinNum)

	local var_8_0 = transition.sequence({
		cc.ScaleTo:create(0.3, 1.5),
		cc.ScaleTo:create(0.3, 1)
	})
	local var_8_1 = cc.Spawn:create(var_8_0)

	arg_8_0:nodeByName("txt_coin"):runAction(var_8_1)
end

function var_0_0.updatePresentList(arg_9_0)
	local var_9_0 = arg_9_0.wishingTable:getAllIds()
	local var_9_1 = 3
	local var_9_2 = math.ceil(#var_9_0 / 3)

	local function var_9_3(arg_10_0)
		local var_10_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary3rd/wishing_pool/wishing_bag_item.csb")
		local var_10_1 = var_10_0:getChildByName("container")
		local var_10_2 = arg_9_0.wishingTable:getWishTimes(arg_10_0)

		var_10_1:getChildByName("txt1"):enableOutline(cc.c4b(153, 56, 56, 255), 2)
		var_10_1:getChildByName("txt2"):enableOutline(cc.c4b(153, 56, 56, 255), 2)
		var_10_1:getChildByName("wishing_times"):enableOutline(cc.c4b(207, 58, 117, 255), 2)
		var_10_1:getChildByName("wishing_times"):setString(var_10_2)
		var_10_1:setName("container" .. arg_10_0)

		arg_9_0.children_[var_10_1:getName()] = var_10_1

		arg_9_0:updateBagItem(arg_10_0)

		return var_10_0
	end

	for iter_9_0 = 1, var_9_2 do
		local var_9_4 = arg_9_0.list:newItem()
		local var_9_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary3rd/wishing_pool/wishing_bag_board.csb")
		local var_9_6 = var_9_5:getChildByName("container")
		local var_9_7 = var_9_6:getContentSize()

		for iter_9_1 = 0, 5 do
			var_9_6:getChildByName("arrow_" .. iter_9_1):setVisible(false)
		end

		for iter_9_2 = 1, var_9_1 do
			local var_9_8 = (iter_9_0 - 1) * 3 + iter_9_2
			local var_9_9 = var_9_0[var_9_8]

			if var_9_9 and var_9_9 > 0 then
				local var_9_10 = var_9_3(var_9_9)
				local var_9_11 = var_9_8 % 6

				if var_9_11 and var_9_8 ~= #var_9_0 then
					var_9_6:getChildByName("arrow_" .. var_9_11):setVisible(true)
				end

				if iter_9_0 % 2 == 1 then
					var_9_10:setPosition((iter_9_2 - 1) * 140, 0)
				else
					var_9_10:setPosition((3 - iter_9_2) * 140, 0)
				end

				var_9_6:getChildByName("item_container"):addChild(var_9_10)
			end
		end

		var_9_5:setAnchorPoint(cc.p(0.5, 0.5))
		var_9_5:setPosition(0, 0)
		var_9_4:addContent(var_9_5)
		var_9_4:setItemSize(var_9_7.width, var_9_7.height)
		arg_9_0.list:addItem(var_9_4)
	end

	arg_9_0.list:reload()
end

function var_0_0.updateWishTimes(arg_11_0)
	local var_11_0 = string.format(var_0_3:translation("ANNIVERSARY_WISHED_TIMES"), arg_11_0.wishTimes)

	arg_11_0:nodeByName("word_wished"):setString(var_11_0)
end

function var_0_0.updateBagItem(arg_12_0, arg_12_1)
	local var_12_0 = arg_12_0.wishingTable:getWishTimes(arg_12_1)
	local var_12_1 = arg_12_0.wishingTable:getGiftId(arg_12_1)
	local var_12_2 = arg_12_0.wishingTable:getIcon(arg_12_1)
	local var_12_3
	local var_12_4 = arg_12_0.children_["container" .. arg_12_1]:getChildByName("node_bag")

	if var_12_0 > arg_12_0.wishTimes then
		arg_12_0.isCanPreview = 1
	else
		arg_12_0.isCanPreview = 0
	end

	if arg_12_0.isCanPreview == 0 then
		if arg_12_0.isCanGetBag[arg_12_1] == 1 then
			var_12_3 = xyd.AssetLoader.get():loadButton({
				"windows/anniversary3rd/wishing_pool/bag" .. var_12_2,
				"windows/anniversary3rd/wishing_pool/bag" .. var_12_2,
				"windows/anniversary3rd/wishing_pool/bag" .. var_12_2
			}, ccui.Button, nil)

			var_12_3:setTouchEnabled(false)
			arg_12_0.children_["container" .. arg_12_1]:getChildByName("toget"):setVisible(false)
			arg_12_0.children_["container" .. arg_12_1]:getChildByName("havegot"):setVisible(true)
			arg_12_0.children_["container" .. arg_12_1]:getChildByName("preview"):setVisible(false)
		else
			local var_12_5

			if arg_12_0.awardEffects[arg_12_1] then
				var_12_5 = arg_12_0.awardEffects[arg_12_1]
			else
				local var_12_6 = "skeletons/ui_effect/activity_anniversary_3rd/wishing_pool/anniversary_box0"

				var_12_5 = var_0_1.new(var_12_6 .. var_12_2 .. ".json", var_12_6 .. var_12_2 .. ".atlas", 1)

				var_12_5:setAnchorPoint(cc.p(0.5, 0.5))
				var_12_5:addTo(arg_12_0.children_["container" .. arg_12_1])
				var_12_5:pos(var_12_4:getPositionX(), var_12_4:getPositionY() + 10)
				var_12_5:setTouchSwallowEnabled(true)
				var_12_5:play(nil, true)

				arg_12_0.awardEffects[arg_12_1] = var_12_5
			end

			local var_12_7 = arg_12_0.children_["container" .. arg_12_1]:getContentSize()
			local var_12_8
			local var_12_9
			local var_12_10

			var_12_3 = display.newNode()

			var_12_3:setAnchorPoint(cc.p(0.5, 0.5))
			var_12_3:setContentSize(var_12_7.width, var_12_7.height)
			xyd.imgEvent(var_12_3, function()
				local var_13_0 = {
					idx = arg_12_1
				}

				arg_12_0.model:getWishingpoolAwards(var_13_0, function(arg_14_0, arg_14_1)
					if arg_14_0 == xyd.error.OK then
						if arg_14_1 and arg_14_1.awards then
							arg_12_0.selfPlayer:handleRewards(arg_14_1.awards)
						end

						var_12_3:setTouchEnabled(false)

						local var_14_0 = cc.Sprite:create("windows/anniversary3rd/wishing_pool/bag" .. var_12_2 .. ".png")

						var_14_0:setAnchorPoint(cc.p(0.5, 0.5))
						var_14_0:addTo(var_12_4)
						var_14_0:setPosition(0, 0)
						arg_12_0.children_["container" .. arg_12_1]:getChildByName("toget"):setVisible(false)
						arg_12_0.children_["container" .. arg_12_1]:getChildByName("havegot"):setVisible(true)

						arg_12_0.isCanGetBag[arg_12_1] = 0

						var_12_5:setVisible(false)
					end
				end)
			end)
			arg_12_0.children_["container" .. arg_12_1]:getChildByName("toget"):setVisible(true)
			arg_12_0.children_["container" .. arg_12_1]:getChildByName("havegot"):setVisible(false)
			arg_12_0.children_["container" .. arg_12_1]:getChildByName("preview"):setVisible(false)
		end
	else
		arg_12_0.children_["container" .. arg_12_1]:getChildByName("toget"):setVisible(false)
		arg_12_0.children_["container" .. arg_12_1]:getChildByName("havegot"):setVisible(false)
		arg_12_0.children_["container" .. arg_12_1]:getChildByName("preview"):setVisible(true)

		var_12_3 = xyd.AssetLoader.get():loadButton({
			"windows/anniversary3rd/wishing_pool/bag" .. var_12_2,
			"windows/anniversary3rd/wishing_pool/bag" .. var_12_2,
			"windows/anniversary3rd/wishing_pool/bag" .. var_12_2
		}, ccui.Button, nil)

		var_12_3:addTouchEventListener(function(arg_15_0, arg_15_1)
			if arg_15_1 == ccui.TouchEventType.ended then
				if arg_12_0.scrollViewMoved_ then
					return
				end

				xyd.WindowManager.get():openWindow("wishing_present", {
					giftID = var_12_1,
					times = var_12_0
				})
			end
		end)
	end

	var_12_4:removeAllChildren()
	var_12_4:addChild(var_12_3)
end

function var_0_0.scrollListener(arg_16_0, arg_16_1)
	if arg_16_1.name == "began" then
		arg_16_0.scrollViewMoved_ = false
		arg_16_0.prevY_ = arg_16_1.y
	elseif arg_16_1.name == "moved" and 20 <= math.abs(arg_16_1.y - arg_16_0.prevY_) then
		arg_16_0.scrollViewMoved_ = true
	end
end

function var_0_0.initDanmuBox(arg_17_0)
	local var_17_0 = arg_17_0:nodeByName("container_enter")
	local var_17_1 = "windows/anniversary3rd/wishing_pool/enter_bar.png"

	arg_17_0.editbox_ = ccui.EditBox:create(var_17_0:getContentSize(), var_17_1)

	arg_17_0:nodeByName("container_enter"):addChild(arg_17_0.editbox_)
	arg_17_0.editbox_:setAnchorPoint(cc.p(0, 0))
	arg_17_0.editbox_:setPosition(0, 0)
	arg_17_0.editbox_:registerScriptEditBoxHandler(handler(arg_17_0, arg_17_0.inputboxEventHandler))
	arg_17_0.editbox_:setInputFlag(3)

	if not arg_17_0.message or arg_17_0.message == "" then
		arg_17_0:nodeByName("txt"):setString(var_0_3:translation("ANNIVERSARY_WISHING"))
	else
		arg_17_0:nodeByName("txt"):setString(arg_17_0.message)
	end

	arg_17_0:nodeByName("btn_enter"):getChildByName("send"):setString(var_0_3:translation("CHAT_WINDOW_SEND"))
	arg_17_0:nodeByName("btn_enter"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.began then
			arg_17_0:nodeByName("btn_enter"):setScale(0.9)
		elseif arg_18_1 == ccui.TouchEventType.ended then
			arg_17_0:nodeByName("btn_enter"):setScale(1)
			arg_17_0:sendWishing()
		end
	end)
	arg_17_0:initDanmuScreen()
end

function var_0_0.sendWishing(arg_19_0)
	local var_19_0 = {}
	local var_19_1 = var_0_3:translation("ANNIVERSARY_WISHING")

	var_19_0.coinID = arg_19_0.coinID
	var_19_0.msg = arg_19_0.message or var_19_1

	xyd.WindowManager.get():openWindow("wishing_coin_use", var_19_0)
end

function var_0_0.checkBarrageIsShow(arg_20_0)
	if xyd.ServerTime.get():getServerTime() >= arg_20_0.activityPrayTime then
		return true
	else
		return false
	end
end

function var_0_0.initDanmuScreen(arg_21_0)
	if arg_21_0.isShowDanmu then
		return
	end

	local var_21_0 = arg_21_0:nodeByName("screen_bullet")
	local var_21_1 = var_21_0:getContentSize()

	arg_21_0.danmuItemNums = math.floor(var_21_1.height / var_0_5) - 1

	for iter_21_0 = 1, arg_21_0.danmuItemNums do
		table.insert(arg_21_0.unusedBallistic, iter_21_0)
	end

	arg_21_0.clippingNode = display.newClippingRegionNode()

	arg_21_0.clippingNode:setClippingRegion(cc.rect(0, 0, var_21_1.width, var_21_1.height))
	var_21_0:addChild(arg_21_0.clippingNode)

	arg_21_0.newContainer = display.newNode()

	arg_21_0.newContainer:setContentSize(var_21_1.width, var_21_1.height)
	arg_21_0.newContainer:addTo(arg_21_0.clippingNode)
	arg_21_0:showDanmu()
end

function var_0_0.showDanmu(arg_22_0)
	if arg_22_0.loadDanmuHandler then
		var_0_2.unscheduleGlobal(arg_22_0.loadDanmuHandler)

		arg_22_0.loadDanmuHandler = nil
	end

	arg_22_0:getBulletScreen()

	arg_22_0.loadDanmuHandler = var_0_2.scheduleGlobal(function()
		if arg_22_0.danmuContainer and not tolua.isnull(arg_22_0.danmuContainer) and arg_22_0.danmuInfos and #arg_22_0.danmuInfos <= 10 and not arg_22_0.isLoadingDanmu then
			arg_22_0.isLoadingDanmu = true

			arg_22_0:getBulletScreen()
		end
	end, 1)

	if arg_22_0.showDanmuHandler then
		var_0_2.unscheduleGlobal(arg_22_0.showDanmuHandler)

		arg_22_0.showDanmuHandler = nil
	end

	arg_22_0.showDanmuHandler = var_0_2.scheduleGlobal(function()
		if arg_22_0.danmuContainer and not tolua.isnull(arg_22_0.danmuContainer) then
			arg_22_0:createDanmu()
		end
	end, 3)
end

function var_0_0.getRandomBallistic(arg_25_0)
	if #arg_25_0.unusedBallistic <= 0 then
		return 0
	end

	local var_25_0 = math.random(1, #arg_25_0.unusedBallistic)
	local var_25_1 = arg_25_0.unusedBallistic[var_25_0]

	table.remove(arg_25_0.unusedBallistic, var_25_0)

	return var_25_1
end

function var_0_0.getBulletScreen(arg_26_0)
	if arg_26_0.loadBarrageHandler then
		var_0_2.unscheduleGlobal(arg_26_0.loadBarrageHandler)

		arg_26_0.loadBarrageHandler = nil
	end

	arg_26_0.model:getWishingpoolList(function(arg_27_0, arg_27_1)
		if arg_27_0 == xyd.error.OK then
			local var_27_0 = arg_27_1.messages

			for iter_27_0 = 1, #var_27_0 do
				table.insert(arg_26_0.danmuInfos, var_27_0[iter_27_0])
			end
		end

		arg_26_0.isLoadingDanmu = false
	end)
end

function var_0_0.createDanmu(arg_28_0)
	local var_28_0 = math.random(4, 7)

	for iter_28_0 = 1, var_28_0 do
		if arg_28_0.danmuInfos and next(arg_28_0.danmuInfos) then
			local var_28_1 = arg_28_0.danmuInfos[1].msg
			local var_28_2 = arg_28_0.danmuInfos[1].name
			local var_28_3 = arg_28_0:getRandomBallistic()

			if var_28_3 == 0 then
				break
			end

			local var_28_4 = {
				isSelf = 0,
				txtSize = 24,
				parent = arg_28_0.newContainer,
				text = var_28_2,
				text_2 = var_28_1,
				duration = math.random(5, 8),
				ballistic = var_28_3,
				height = var_28_3 * var_0_5,
				callback = function()
					if arg_28_0.danmuContainer and not tolua.isnull(arg_28_0.danmuContainer) then
						table.insert(arg_28_0.unusedBallistic, var_28_3)
					end
				end
			}
			local var_28_5 = import("app.windows.TextBarrageItem").new()

			var_28_5:setParams(var_28_4)
			var_28_5:move()
			table.remove(arg_28_0.danmuInfos, 1)
		end
	end
end

function var_0_0.inputboxEventHandler(arg_30_0, arg_30_1)
	if arg_30_1 == "began" then
		if not arg_30_0.message or arg_30_0.message == "" then
			arg_30_0:nodeByName("txt"):setString("")
		else
			arg_30_0.editbox_:setText(arg_30_0:nodeByName("txt"):getString())
		end
	end

	if arg_30_1 == "return" then
		local var_30_0 = arg_30_0.editbox_:getText()

		if var_30_0 == "" then
			arg_30_0.message = nil

			arg_30_0:nodeByName("txt"):setString(var_0_3:translation("ANNIVERSARY_WISHING"))
			arg_30_0:nodeByName("txt"):setColor(cc.c3b(96, 58, 28))
		else
			if xyd.utf8len(var_30_0) > var_0_4 then
				var_30_0 = xyd.getTextstr(var_30_0, 1, var_0_4)
			end

			arg_30_0.message = var_30_0

			arg_30_0:nodeByName("txt"):setString(var_30_0)
			arg_30_0:nodeByName("txt"):setColor(cc.c3b(255, 255, 255))
		end

		arg_30_0.editbox_:setText("")
	end
end

function var_0_0.release(arg_31_0)
	if arg_31_0.showDanmuHandler then
		var_0_2.unscheduleGlobal(arg_31_0.showDanmuHandler)

		arg_31_0.showDanmuHandler = nil
	end

	if arg_31_0.loadDanmuHandler then
		var_0_2.unscheduleGlobal(arg_31_0.loadDanmuHandler)

		arg_31_0.loadDanmuHandler = nil
	end

	arg_31_0.danmuInfos = {}
	arg_31_0.unusedBallistic = {}
	arg_31_0.danmuItemNums = 0
	arg_31_0.isLoadingDanmu = false
	arg_31_0.isShowDanmu = false
end

return var_0_0
