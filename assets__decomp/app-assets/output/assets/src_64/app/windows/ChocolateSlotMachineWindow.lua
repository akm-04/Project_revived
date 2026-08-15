local var_0_0 = class("ChocolateSlotMachineWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.model.Item")
local var_0_4 = xyd.tables.activityChocolateSlot
local var_0_5 = import("framework.scheduler")
local var_0_6 = 35
local var_0_7 = "skeletons/ui_effect/chocolate/"
local var_0_8 = 2
local var_0_9 = 1
local var_0_10 = 1
local var_0_11 = 1
local var_0_12 = 0.5
local var_0_13 = 1.2
local var_0_14 = 2

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.CHOCOLATE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.is_raise = 0
	arg_1_0.raisePirce = xyd.tables.misc.activityChocolateSlotMachineDiamondCost
	arg_1_0.doublePrice = xyd.tables.misc.activityChocolateSlotMachineDoubleCost
	arg_1_0.guaranteedNums = xyd.tables.misc:getValue("activity_chocolate_slot_machine_guaranteed")
	arg_1_0.award_times = arg_1_2.award_times
	arg_1_0.guaranteedNums = xyd.tables.misc:getValue("activity_chocolate_slot_machine_guaranteed")
	arg_1_0.loadDanmuHandler = nil
	arg_1_0.danmuInfos = {}
	arg_1_0.danmuItemNums = 0
	arg_1_0.unusedBallistic = {}
	arg_1_0.isShowDanmu = false
	arg_1_0.showDanmuHandler = nil
	arg_1_0.laohujiType = 1
	arg_1_0.totalTime = var_0_8 + var_0_9 + var_0_10 + var_0_11
	arg_1_0.effects = {}
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	var_0_0.super:didOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.danmuContainer = arg_3_0:nodeByName("screen_bullet")

	arg_3_0:nodeByName("word_jiazhu"):enableOutline(cc.c4b(167, 98, 235, 255), 2)
	arg_3_0:nodeByName("btn_rule_txt"):enableOutline(cc.c4b(216, 80, 48, 255), 2)
	arg_3_0:nodeByName("btn_rule_txt1"):enableOutline(cc.c4b(216, 80, 48, 255), 2)
	arg_3_0:nodeByName("word_dajiang1"):enableOutline(cc.c4b(86, 174, 75, 255), 2)
	arg_3_0:nodeByName("word_dajiang2"):enableOutline(cc.c4b(203, 61, 99, 255), 2)
	arg_3_0:nodeByName("word_one"):enableOutline(cc.c4b(185, 53, 204, 255), 2)
	arg_3_0:nodeByName("word_ten"):enableOutline(cc.c4b(185, 53, 204, 255), 2)
	arg_3_0:nodeByName("word_jiazhu"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP24"))
	arg_3_0:nodeByName("btn_rule_txt"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP25"))
	arg_3_0:nodeByName("btn_rule_txt1"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP30"))
	arg_3_0:nodeByName("word_dajiang1"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP26"))
	arg_3_0:nodeByName("word_dajiang2"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP27"))
	arg_3_0:nodeByName("word_one"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP28"))
	arg_3_0:nodeByName("word_ten"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP29"))
	arg_3_0:nodeByName("title_txt"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP31"))

	for iter_3_0 = 1, 8 do
		arg_3_0:nodeByName("txt_" .. iter_3_0):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	end

	arg_3_0:nodeByName("txt_1"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP9"))
	arg_3_0:nodeByName("txt_3"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP10"))
	arg_3_0:nodeByName("txt_4"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP11"))
	arg_3_0:nodeByName("txt_5"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP13"))
	arg_3_0:nodeByName("txt_6"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP14"))
	arg_3_0:nodeByName("txt_8"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP15"))

	local var_3_0 = 1

	for iter_3_1 = 1, 27 do
		if var_0_4:isRarest(iter_3_1) == 1 then
			local var_3_1 = var_0_4:giftId(iter_3_1)

			if var_3_1 and var_3_1 > 0 then
				arg_3_0:rewardLayer(arg_3_0:nodeByName("award_container" .. var_3_0), var_3_1)
			end

			var_3_0 = var_3_0 + 1
		end
	end

	arg_3_0:updateRise()
	arg_3_0:initFruit()
	arg_3_0:initEffect()
	arg_3_0:addTouchEventListener()
	arg_3_0:initDanmuScreen()
	arg_3_0:updateCoinNum(arg_3_0.award_times)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.ECONOMY_AFTER, handler(arg_3_0, arg_3_0.updateEconomicInfo))
	arg_3_0:nodeByName("crystal_num_txt"):setString(xyd.num2ThousandsStr(arg_3_0.selfPlayer.crystal))
end

function var_0_0.updateEconomicInfo(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1.params

	if not var_4_0 or not next(var_4_0) then
		return
	end

	if var_4_0.crystal then
		arg_4_0:nodeByName("crystal_num_txt"):setString(xyd.num2ThousandsStr(var_4_0.crystal))
	end
end

function var_0_0.updateRise(arg_5_0)
	if arg_5_0.is_raise == 1 then
		arg_5_0:nodeByName("gou"):setVisible(true)
		arg_5_0:nodeByName("zuanshi_little"):setVisible(false)
		arg_5_0:nodeByName("zuanshi_many"):setVisible(true)
	else
		arg_5_0:nodeByName("gou"):setVisible(false)
		arg_5_0:nodeByName("zuanshi_little"):setVisible(true)
		arg_5_0:nodeByName("zuanshi_many"):setVisible(false)
	end
end

function var_0_0.addTouchEventListener(arg_6_0)
	arg_6_0:nodeByName("click_on"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			if arg_6_0.is_raise == 1 then
				arg_6_0.is_raise = 0
			else
				arg_6_0.is_raise = 1
			end

			arg_6_0:updateRise()
		end
	end)
	arg_6_0:nodeByName("btn_one"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = {}

			var_8_0.times = 1
			var_8_0.is_raise = arg_6_0.is_raise

			if arg_6_0.coinAllNum >= 1 then
				var_8_0.is_coin = true
			else
				var_8_0.is_coin = false
			end

			var_8_0.coinID = arg_6_0.coinID

			xyd.WindowManager.get():openWindow("chocolate_slot_machine_raise", var_8_0)
		end
	end)
	arg_6_0:nodeByName("btn_ten"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			local var_9_0 = {}

			var_9_0.times = 10
			var_9_0.is_raise = arg_6_0.is_raise

			if arg_6_0.coinAllNum >= 10 then
				var_9_0.is_coin = true
			else
				var_9_0.is_coin = false
			end

			var_9_0.coinID = arg_6_0.coinID

			xyd.WindowManager.get():openWindow("chocolate_slot_machine_raise", var_9_0)
		end
	end)
	arg_6_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("chocolate_slot_machine_rule", {
				title_name = "ACTIVITY_CHOCOLATE_SLOT_TIP20",
				rule = "ACTIVITY_CHOCOLATE_SLOT_RULE"
			})
		end
	end)

	local var_6_0 = arg_6_0:nodeByName("box")

	var_6_0:setTouchEnabled(true)
	var_6_0:setVisible(true)
	var_6_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			var_6_0:setScale(0.9)

			return true
		elseif arg_11_0.name == "canceled" then
			var_6_0:setScale(1)
		elseif arg_11_0.name == "ended" then
			var_6_0:setScale(1)

			if arg_6_0.award_times >= arg_6_0.guaranteedNums then
				arg_6_0.model:chocolateSlotGetExtra(params, function(arg_12_0, arg_12_1)
					if arg_12_0 == xyd.error.OK then
						arg_6_0.selfPlayer:handleRewards(arg_12_1.awards)

						arg_6_0.award_times = arg_6_0.award_times - arg_6_0.guaranteedNums

						arg_6_0:updatetxt()
					end
				end)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP16"), arg_6_0.guaranteedNums - arg_6_0.award_times)
				})
			end
		end
	end)
end

function var_0_0.updatetxt(arg_13_0)
	if arg_13_0.coinAllNum <= 0 then
		arg_13_0:nodeByName("slot_coin1"):setVisible(false)
		arg_13_0:nodeByName("slot_coin10"):setVisible(false)
		arg_13_0:nodeByName("zuanshi1"):setVisible(true)
		arg_13_0:nodeByName("zuanshi10"):setVisible(true)
		arg_13_0:nodeByName("one_txt"):setString("X" .. arg_13_0.raisePirce)
		arg_13_0:nodeByName("ten_txt"):setString("X" .. arg_13_0.raisePirce * 10)
	elseif arg_13_0.coinAllNum <= 9 then
		arg_13_0:nodeByName("slot_coin1"):setVisible(true)
		arg_13_0:nodeByName("slot_coin10"):setVisible(false)
		arg_13_0:nodeByName("zuanshi1"):setVisible(false)
		arg_13_0:nodeByName("zuanshi10"):setVisible(true)
		arg_13_0:nodeByName("one_txt"):setString("X" .. 1)
		arg_13_0:nodeByName("ten_txt"):setString("X" .. arg_13_0.raisePirce * 10)
	else
		arg_13_0:nodeByName("slot_coin1"):setVisible(true)
		arg_13_0:nodeByName("slot_coin10"):setVisible(true)
		arg_13_0:nodeByName("zuanshi1"):setVisible(false)
		arg_13_0:nodeByName("zuanshi10"):setVisible(false)
		arg_13_0:nodeByName("one_txt"):setString("X" .. 1)
		arg_13_0:nodeByName("ten_txt"):setString("X" .. 10)
	end

	if arg_13_0.award_times < arg_13_0.guaranteedNums then
		arg_13_0:nodeByName("txt_2"):setString(arg_13_0.guaranteedNums - arg_13_0.award_times)

		for iter_13_0 = 1, 4 do
			arg_13_0:nodeByName("txt_" .. iter_13_0):setVisible(true)
		end

		for iter_13_1 = 5, 8 do
			arg_13_0:nodeByName("txt_" .. iter_13_1):setVisible(false)
		end

		arg_13_0.effects.lihe:setVisible(false)
		arg_13_0:nodeByName("box"):stopAllActions()
		arg_13_0:nodeByName("box"):setPosition(cc.p(49.5, 57))
		arg_13_0:nodeByName("box"):setRotation(0)
	elseif arg_13_0.award_times >= arg_13_0.guaranteedNums then
		arg_13_0:nodeByName("box"):stopAllActions()
		arg_13_0:nodeByName("box"):setPosition(cc.p(49.5, 57))
		arg_13_0:nodeByName("box"):setRotation(0)

		local var_13_0 = math.ceil((arg_13_0.award_times + 1) / arg_13_0.guaranteedNums - 1)

		arg_13_0:nodeByName("txt_7"):setString(var_13_0)

		for iter_13_2 = 1, 4 do
			arg_13_0:nodeByName("txt_" .. iter_13_2):setVisible(false)
		end

		for iter_13_3 = 5, 8 do
			arg_13_0:nodeByName("txt_" .. iter_13_3):setVisible(true)
		end

		local var_13_1 = 0.2
		local var_13_2 = cc.Spawn:create({
			cc.Sequence:create({
				cc.MoveBy:create(var_13_1, cc.p(5, 0)),
				cc.MoveBy:create(var_13_1, cc.p(-10, 0)),
				cc.MoveBy:create(var_13_1, cc.p(5, 0)),
				cc.DelayTime:create(var_13_1 * 3)
			}),
			cc.Sequence:create({
				cc.RotateBy:create(var_13_1, 15),
				cc.RotateBy:create(var_13_1, -30),
				cc.RotateBy:create(var_13_1, 15),
				cc.DelayTime:create(var_13_1 * 3)
			})
		})

		arg_13_0:nodeByName("box"):runAction(cc.RepeatForever:create(var_13_2))
		arg_13_0.effects.lihe:setVisible(false)
	end

	arg_13_0:nodeByName("coin_num_txt"):setString(xyd.num2ThousandsStr(arg_13_0.coinAllNum))
end

function var_0_0.updateCoinNum(arg_14_0, arg_14_1)
	arg_14_0.award_times = arg_14_1
	arg_14_0.coinID = xyd.tables.misc.activityChocolateSlotMachineItemCoin
	arg_14_0.coinAllNum = arg_14_0.selfPlayer:getBackpack():getItemNumByID(arg_14_0.coinID)

	arg_14_0:updatetxt()
end

function var_0_0.rewardLayer(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = xyd.tables.gift:items(arg_15_2)

	if #var_15_0 == 1 and var_15_0[1] == 0 then
		var_15_0 = {}
	end

	local var_15_1 = xyd.tables.gift:itemNum(arg_15_2)
	local var_15_2 = #var_15_1
	local var_15_3 = arg_15_1:getContentSize().height
	local var_15_4 = var_15_3 / 4 - 1
	local var_15_5 = #var_15_0

	for iter_15_0 = 1, #var_15_0 do
		local var_15_6 = display.newNode()

		var_15_6:setContentSize(var_15_3, var_15_3)

		local var_15_7 = xyd.tables.item:type(var_15_0[iter_15_0])

		xyd.setItemBorder(var_15_6, var_15_0[iter_15_0], false, false, var_15_1[iter_15_0])
		var_15_6:addTo(arg_15_1)
		var_15_6:setAnchorPoint(cc.p(0, 0))
		var_15_6:setPosition((iter_15_0 - 1) * (var_15_3 + var_15_4), 0)

		local var_15_8 = {
			id = var_15_0[iter_15_0],
			lev = xyd.tables.item:level(var_15_0[iter_15_0])
		}

		if xyd.tables.item:type(var_15_0[iter_15_0]) == -1 then
			var_15_8.tipsType = 0
			var_15_8.desc1 = xyd.tables.hero:getDes(var_15_0[iter_15_0])
		elseif specialItem then
			var_15_8.tipsType = 1
			var_15_8.id = -3
		else
			var_15_8.tipsType = 1
			var_15_8.desc1 = xyd.tables.item:desc1(var_15_0[iter_15_0])
			var_15_8.desc2 = xyd.tables.item:desc2(var_15_0[iter_15_0])
		end

		var_15_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_15_0[iter_15_0])
		var_15_8.name = xyd.tables.item:name(var_15_0[iter_15_0])

		arg_15_0:addTips(var_15_6, var_15_8)
	end

	local var_15_9 = xyd.tables.gift:crystal(arg_15_2)

	if var_15_9 and var_15_9 > 0 then
		local var_15_10 = display.newNode()

		var_15_10:setContentSize(var_15_3, var_15_3)
		xyd.setItemBorder(var_15_10, -1, false, false, var_15_9)
		var_15_10:addTo(arg_15_1)
		var_15_10:setAnchorPoint(cc.p(0, 0))
		var_15_10:setPosition(var_15_5 * (var_15_3 + var_15_4), 0)

		local var_15_11 = {}

		var_15_11.id = -1
		var_15_11.tipsType = 1

		arg_15_0:addTips(var_15_10, var_15_11)

		var_15_5 = var_15_5 + 1
	end

	local var_15_12 = xyd.tables.gift:mana(arg_15_2)

	if var_15_12 and var_15_12 > 0 then
		local var_15_13 = display.newNode()

		var_15_13:setContentSize(var_15_3, var_15_3)
		xyd.setItemBorder(var_15_13, -2, false, false, var_15_12)
		var_15_13:addTo(arg_15_1)
		var_15_13:setAnchorPoint(cc.p(0, 0))
		var_15_13:setPosition(var_15_5 * (var_15_3 + var_15_4), 0)

		local var_15_14 = {}

		var_15_14.id = -2
		var_15_14.tipsType = 1

		arg_15_0:addTips(var_15_13, var_15_14)

		local var_15_15 = var_15_5 + 1
	end

	return arg_15_1
end

function var_0_0.initDanmuScreen(arg_16_0)
	if arg_16_0.isShowDanmu then
		return
	end

	local var_16_0 = arg_16_0:nodeByName("screen_bullet")
	local var_16_1 = var_16_0:getContentSize()

	dump(var_16_1.width)
	dump(var_16_1.height)

	arg_16_0.danmuItemNums = math.floor(var_16_1.height / var_0_6) - 1

	for iter_16_0 = 1, arg_16_0.danmuItemNums do
		table.insert(arg_16_0.unusedBallistic, iter_16_0)
	end

	arg_16_0.clippingNode = display.newClippingRegionNode()

	arg_16_0.clippingNode:setClippingRegion(cc.rect(0, 0, var_16_1.width, var_16_1.height))
	var_16_0:addChild(arg_16_0.clippingNode)

	arg_16_0.newContainer = display.newNode()

	arg_16_0.newContainer:setContentSize(var_16_1.width, var_16_1.height)
	arg_16_0.newContainer:addTo(arg_16_0.clippingNode)
	arg_16_0:showDanmu()
end

function var_0_0.showDanmu(arg_17_0)
	arg_17_0.isShowDanmu = true

	if arg_17_0.loadDanmuHandler then
		var_0_5.unscheduleGlobal(arg_17_0.loadDanmuHandler)

		arg_17_0.loadDanmuHandler = nil
	end

	arg_17_0:getBulletScreen()

	arg_17_0.loadDanmuHandler = var_0_5.scheduleGlobal(function()
		if arg_17_0.danmuContainer and not tolua.isnull(arg_17_0.danmuContainer) and arg_17_0.danmuInfos and #arg_17_0.danmuInfos <= 10 and not arg_17_0.isLoadingDanmu then
			arg_17_0.isLoadingDanmu = true

			arg_17_0:getBulletScreen()
		end
	end, 1)

	if arg_17_0.showDanmuHandler then
		var_0_5.unscheduleGlobal(arg_17_0.showDanmuHandler)

		arg_17_0.showDanmuHandler = nil
	end

	arg_17_0.showDanmuHandler = var_0_5.scheduleGlobal(function()
		if arg_17_0.danmuContainer and not tolua.isnull(arg_17_0.danmuContainer) then
			arg_17_0:createDanmu()
		end
	end, 3.5)
end

function var_0_0.getBulletScreen(arg_20_0)
	if arg_20_0.loadBarrageHandler then
		var_0_5.unscheduleGlobal(arg_20_0.loadBarrageHandler)

		arg_20_0.loadBarrageHandler = nil
	end

	local var_20_0 = {}

	arg_20_0.model:chocolateSlotList(var_20_0, function(arg_21_0, arg_21_1)
		if arg_21_0 == xyd.error.OK then
			local var_21_0 = arg_21_1.messages

			if var_21_0 ~= nil then
				for iter_21_0 = 1, #var_21_0 do
					if var_21_0[iter_21_0].is_raise == 1 then
						table.insert(arg_20_0.danmuInfos, var_21_0[iter_21_0])
						table.insert(arg_20_0.danmuInfos, var_21_0[iter_21_0])
					else
						table.insert(arg_20_0.danmuInfos, var_21_0[iter_21_0])
					end
				end
			end
		end

		arg_20_0.isLoadingDanmu = false
	end)
end

function var_0_0.createDanmu(arg_22_0)
	local var_22_0 = math.random(2, 6)
	local var_22_1 = 1

	for iter_22_0 = 1, var_22_0 do
		if arg_22_0.danmuInfos and next(arg_22_0.danmuInfos) then
			local var_22_2 = arg_22_0.danmuInfos[1].name
			local var_22_3 = xyd.getPlayerRegion(arg_22_0.danmuInfos[1].player_id)
			local var_22_4 = arg_22_0.danmuInfos[1].table_id
			local var_22_5 = arg_22_0.danmuInfos[1].is_raise
			local var_22_6
			local var_22_7 = xyd.tables.activityChocolateSlot:content(var_22_4)[1] + 16
			local var_22_8 = xyd.tables.translation:translation("ACTIVITY_CHOCOLATE_SLOT_TIP" .. var_22_7)
			local var_22_9 = xyd.tables.activityChocolateSlot:giftId(var_22_4)
			local var_22_10 = xyd.tables.gift:items(var_22_9)

			if arg_22_0.danmuInfos[1].is_raise == 1 then
				if var_22_1 == 1 then
					var_22_6 = string.format(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_BARRAGE1"), var_22_3, var_22_2, xyd.tables.item:name(var_22_10[1]))
					var_22_1 = 1 - var_22_1
				else
					var_22_6 = string.format(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_BARRAGE2"), var_22_3, var_22_2, var_22_8, xyd.tables.item:name(var_22_10[1]))
					var_22_1 = 1 - var_22_1
				end
			else
				var_22_6 = string.format(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_BARRAGE2"), var_22_3, var_22_2, var_22_8, xyd.tables.item:name(var_22_10[1]))
			end

			local var_22_11 = arg_22_0:getRandomBallistic()

			if var_22_11 == 0 then
				break
			end

			local var_22_12 = {
				isSelf = 0,
				txtSize = 28,
				parent = arg_22_0.newContainer,
				text = var_22_6,
				duration = math.random(7, 11),
				ballistic = var_22_11,
				height = var_22_11 * var_0_6,
				callback = function()
					if arg_22_0.danmuContainer and not tolua.isnull(arg_22_0.danmuContainer) then
						table.insert(arg_22_0.unusedBallistic, var_22_11)
					end
				end
			}
			local var_22_13 = import("app.windows.TextBarrageItem").new()

			var_22_13:setParams(var_22_12)
			var_22_13:move()
			table.remove(arg_22_0.danmuInfos, 1)
		end
	end
end

function var_0_0.getRandomBallistic(arg_24_0)
	if #arg_24_0.unusedBallistic <= 0 then
		return 0
	end

	local var_24_0 = math.random(1, #arg_24_0.unusedBallistic)
	local var_24_1 = arg_24_0.unusedBallistic[var_24_0]

	table.remove(arg_24_0.unusedBallistic, var_24_0)

	return var_24_1
end

function var_0_0.release(arg_25_0)
	if arg_25_0.showDanmuHandler then
		var_0_5.unscheduleGlobal(arg_25_0.showDanmuHandler)

		arg_25_0.showDanmuHandler = nil
	end

	if arg_25_0.loadDanmuHandler then
		var_0_5.unscheduleGlobal(arg_25_0.loadDanmuHandler)

		arg_25_0.loadDanmuHandler = nil
	end

	arg_25_0.danmuInfos = {}
	arg_25_0.unusedBallistic = {}
	arg_25_0.danmuItemNums = 0
	arg_25_0.isLoadingDanmu = false
	arg_25_0.isShowDanmu = false
end

function var_0_0.getEffect(arg_26_0, arg_26_1)
	local var_26_0 = var_0_7 .. arg_26_1
	local var_26_1 = xyd.createEffect(var_26_0)

	var_26_1:setAnchorPoint(cc.p(0, 0))

	return var_26_1
end

function var_0_0.initFruit(arg_27_0)
	stencil1 = xyd.AssetLoader:get():loadSprite("windows/chocolate/extra_picture/left_shadow.png")
	stencil2 = xyd.AssetLoader:get():loadSprite("windows/chocolate/extra_picture/middle_shadow.png")
	stencil3 = xyd.AssetLoader:get():loadSprite("windows/chocolate/extra_picture/right_shadow.png")

	stencil1:setAnchorPoint(cc.p(0, 0))
	stencil1:setPosition(cc.p(-406, -383))
	stencil2:setAnchorPoint(cc.p(0, 0))
	stencil2:setPosition(cc.p(-618, -383))
	stencil3:setAnchorPoint(cc.p(0, 0))
	stencil3:setPosition(cc.p(-824, -383))

	local var_27_0 = cc.ClippingNode:create()

	var_27_0:setStencil(stencil1)
	var_27_0:setInverted(true)
	var_27_0:setAlphaThreshold(0)
	arg_27_0:nodeByName("left_container"):addChild(var_27_0)

	local var_27_1 = cc.ClippingNode:create()

	var_27_1:setStencil(stencil2)
	var_27_1:setInverted(true)
	var_27_1:setAlphaThreshold(0)
	arg_27_0:nodeByName("middle_container"):addChild(var_27_1)

	local var_27_2 = cc.ClippingNode:create()

	var_27_2:setStencil(stencil3)
	var_27_2:setInverted(true)
	var_27_2:setAlphaThreshold(0)
	arg_27_0:nodeByName("right_container"):addChild(var_27_2)

	local var_27_3 = xyd.AssetLoader.get():loadSprite("windows/chocolate/extra_picture/middle_apple.png")
	local var_27_4 = xyd.AssetLoader.get():loadSprite("windows/chocolate/extra_picture/middle_orange.png")
	local var_27_5 = xyd.AssetLoader.get():loadSprite("windows/chocolate/extra_picture/middle_mapple.png")

	var_27_3:addTo(var_27_0)
	var_27_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_27_3:setPosition(cc.p(100, 100))
	var_27_3:setLocalZOrder(21)
	var_27_4:addTo(var_27_1)
	var_27_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_27_4:setPosition(cc.p(100, 100))
	var_27_4:setLocalZOrder(21)
	var_27_5:addTo(var_27_2)
	var_27_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_27_5:setPosition(cc.p(100, 100))
	var_27_5:setLocalZOrder(21)
end

function var_0_0.initEffect(arg_28_0)
	stencil1 = xyd.AssetLoader:get():loadSprite("windows/chocolate/extra_picture/left_shadow.png")
	stencil2 = xyd.AssetLoader:get():loadSprite("windows/chocolate/extra_picture/middle_shadow.png")
	stencil3 = xyd.AssetLoader:get():loadSprite("windows/chocolate/extra_picture/right_shadow.png")
	stencil4 = xyd.AssetLoader:get():loadSprite("windows/chocolate/extra_picture/zhezhao.png")

	stencil1:setAnchorPoint(cc.p(0, 0))
	stencil1:setPosition(cc.p(0, 0))
	stencil2:setAnchorPoint(cc.p(0, 0))
	stencil2:setPosition(cc.p(0, 0))
	stencil3:setAnchorPoint(cc.p(0, 0))
	stencil3:setPosition(cc.p(0, 0))
	stencil4:setAnchorPoint(cc.p(0, 0))
	stencil4:setPosition(cc.p(913.5, 0))

	local var_28_0 = cc.ClippingNode:create()

	var_28_0:setStencil(stencil1)
	var_28_0:setInverted(true)
	var_28_0:setAlphaThreshold(0)
	arg_28_0:nodeByName("container"):addChild(var_28_0)

	local var_28_1 = cc.ClippingNode:create()

	var_28_1:setStencil(stencil2)
	var_28_1:setInverted(true)
	var_28_1:setAlphaThreshold(0)
	arg_28_0:nodeByName("container"):addChild(var_28_1)

	local var_28_2 = cc.ClippingNode:create()

	var_28_2:setStencil(stencil3)
	var_28_2:setInverted(true)
	var_28_2:setAlphaThreshold(0)
	arg_28_0:nodeByName("container"):addChild(var_28_2)

	local var_28_3 = cc.ClippingNode:create()

	var_28_3:setStencil(stencil4)
	var_28_3:setInverted(true)
	var_28_3:setAlphaThreshold(0)
	arg_28_0:nodeByName("container"):addChild(var_28_3)

	if not arg_28_0.effects.laohuji then
		local var_28_4 = arg_28_0:getEffect("laohuji")

		var_28_4:addTo(var_28_3)
		var_28_4:play(nil, true)
		var_28_4:setPosition(cc.p(7, -2))

		arg_28_0.effects.laohuji = var_28_4

		arg_28_0.effects.laohuji:play(nil, true, nil, "texiao01")
		arg_28_0.effects.laohuji:setLocalZOrder(20)
		arg_28_0:nodeByName("screen_bullet"):setLocalZOrder(23)
		arg_28_0:nodeByName("down_shadow"):setLocalZOrder(22)
		arg_28_0:nodeByName("up_shadow"):setLocalZOrder(22)
		arg_28_0:nodeByName("slot_coin"):setLocalZOrder(25)
		arg_28_0:nodeByName("bidi"):setLocalZOrder(24)
		arg_28_0:nodeByName("crystal"):setLocalZOrder(25)
		arg_28_0:nodeByName("crystal_bg"):setLocalZOrder(24)
		arg_28_0:nodeByName("title_container"):setLocalZOrder(30)
	end

	if not arg_28_0.effects.lihe then
		local var_28_5 = arg_28_0:getEffect("lihe")

		var_28_5:addTo(arg_28_0:nodeByName("container"))
		var_28_5:play(nil, true)
		var_28_5:setPosition(cc.p(999, 230))

		arg_28_0.effects.lihe = var_28_5

		arg_28_0.effects.lihe:play(nil, true, nil, "texiao")
		arg_28_0.effects.lihe:setLocalZOrder(20)
		arg_28_0:nodeByName("box"):setLocalZOrder(21)
		arg_28_0:nodeByName("box_bg"):setLocalZOrder(22)
	end

	if not arg_28_0.effects.xianshi then
		local var_28_6 = arg_28_0:getEffect("xianshi")

		var_28_6:addTo(arg_28_0:nodeByName("container"))
		var_28_6:play(nil, true)
		var_28_6:setPosition(cc.p(0, 0))

		arg_28_0.effects.xianshi = var_28_6

		arg_28_0.effects.xianshi:play(nil, true, nil, "idle")
		arg_28_0.effects.xianshi:setLocalZOrder(20)

		local var_28_7 = arg_28_0:getEffect("xianshi")

		var_28_7:addTo(var_28_0)
		var_28_7:setPosition(cc.p(506, 483))
		var_28_7:play(nil, true)
		var_28_7:setVisible(true)

		arg_28_0.effects.xianshi.moveEffect1 = var_28_7

		local var_28_8 = arg_28_0:getEffect("xianshi")

		var_28_8:addTo(var_28_0)
		var_28_8:setPosition(cc.p(506, 483))
		var_28_8:play(nil, true)
		var_28_8:setVisible(false)

		arg_28_0.effects.xianshi.fruitEffect1 = var_28_8

		local var_28_9 = arg_28_0:getEffect("xianshi")

		var_28_9:addTo(var_28_1)
		var_28_9:setPosition(cc.p(718, 483))
		var_28_9:play(nil, true)
		var_28_9:setVisible(false)

		arg_28_0.effects.xianshi.moveEffect2 = var_28_9

		local var_28_10 = arg_28_0:getEffect("xianshi")

		var_28_10:addTo(var_28_1)
		var_28_10:setPosition(cc.p(718, 483))
		var_28_10:play(nil, true)
		var_28_10:setVisible(false)

		arg_28_0.effects.xianshi.fruitEffect2 = var_28_10

		local var_28_11 = arg_28_0:getEffect("xianshi")

		var_28_11:addTo(var_28_2)
		var_28_11:setPosition(cc.p(924, 483))
		var_28_11:play(nil, true)
		var_28_11:setVisible(false)

		arg_28_0.effects.xianshi.moveEffect3 = var_28_11

		local var_28_12 = arg_28_0:getEffect("xianshi")

		var_28_12:addTo(var_28_2)
		var_28_12:setPosition(cc.p(924, 483))
		var_28_12:play(nil, true)
		var_28_12:setVisible(false)

		arg_28_0.effects.xianshi.fruitEffect3 = var_28_12
	end
end

function var_0_0.willClose(arg_29_0, arg_29_1)
	var_0_0.super.willClose(arg_29_0, arg_29_1)

	if arg_29_0.handle then
		var_0_5.unscheduleGlobal(arg_29_0.handle)

		arg_29_0.handle = nil
	end
end

function var_0_0.createScheduler(arg_30_0)
	if arg_30_0.handle then
		var_0_5.unscheduleGlobal(arg_30_0.handle)

		arg_30_0.handle = nil
	end

	arg_30_0.totalCount = 0

	arg_30_0.effects.laohuji:play(nil, true, nil, "texiao02")
	arg_30_0:nodeByName("left_container"):setVisible(false)
	arg_30_0:nodeByName("middle_container"):setVisible(false)
	arg_30_0:nodeByName("right_container"):setVisible(false)

	arg_30_0.handle = var_0_5.scheduleUpdateGlobal(handler(arg_30_0, arg_30_0.loop))
end

function var_0_0.loop(arg_31_0)
	local var_31_0 = arg_31_0.totalTime * 30
	local var_31_1 = var_0_8 * 30
	local var_31_2 = var_0_9 * 30 + var_31_1
	local var_31_3 = var_0_10 * 30 + var_31_2
	local var_31_4 = var_0_11 * 30 + var_31_3
	local var_31_5 = var_0_12 * 30 + var_31_4
	local var_31_6 = var_0_13 * 30 + var_31_5
	local var_31_7 = var_0_14 * 30 + var_31_6

	if arg_31_0.totalCount == 0 then
		arg_31_0.effects.xianshi.moveEffect1:setVisible(true)
		arg_31_0.effects.xianshi.moveEffect2:setVisible(true)
		arg_31_0.effects.xianshi.moveEffect3:setVisible(true)
		arg_31_0.effects.xianshi.fruitEffect1:setVisible(false)
		arg_31_0.effects.xianshi.fruitEffect2:setVisible(false)
		arg_31_0.effects.xianshi.fruitEffect3:setVisible(false)
		arg_31_0.effects.xianshi.moveEffect1:play(nil, true, nil, "texiao01")
		arg_31_0.effects.xianshi.moveEffect2:play(nil, true, nil, "texiao01")
		arg_31_0.effects.xianshi.moveEffect3:play(nil, true, nil, "texiao01")
		arg_31_0:nodeByName("close"):setVisible(false)
		arg_31_0:nodeByName("title_container"):setVisible(false)
		arg_31_0:nodeByName("btn_one"):setTouchEnabled(false)
		arg_31_0:nodeByName("btn_ten"):setTouchEnabled(false)
	elseif arg_31_0.totalCount == var_31_1 then
		arg_31_0.effects.xianshi.moveEffect1:setVisible(false)
		arg_31_0.effects.xianshi.fruitEffect1:setVisible(true)

		if arg_31_0.types[1] == 1 then
			arg_31_0.effects.xianshi.fruitEffect1:play(nil, false, nil, "texiao04")
		elseif arg_31_0.types[1] == 2 then
			arg_31_0.effects.xianshi.fruitEffect1:play(nil, false, nil, "texiao02")
		elseif arg_31_0.types[1] == 3 then
			arg_31_0.effects.xianshi.fruitEffect1:play(nil, false, nil, "texiao03")
		end
	elseif arg_31_0.totalCount == var_31_2 then
		arg_31_0.effects.xianshi.moveEffect2:setVisible(false)
		arg_31_0.effects.xianshi.fruitEffect2:setVisible(true)

		if arg_31_0.types[2] == 1 then
			arg_31_0.effects.xianshi.fruitEffect2:play(nil, false, nil, "texiao04")
		elseif arg_31_0.types[2] == 2 then
			arg_31_0.effects.xianshi.fruitEffect2:play(nil, false, nil, "texiao02")
		elseif arg_31_0.types[2] == 3 then
			arg_31_0.effects.xianshi.fruitEffect2:play(nil, false, nil, "texiao03")
		end
	elseif arg_31_0.totalCount == var_31_3 then
		arg_31_0.effects.xianshi.moveEffect3:setVisible(false)
		arg_31_0.effects.xianshi.fruitEffect3:setVisible(true)

		if arg_31_0.types[3] == 1 then
			arg_31_0.effects.xianshi.fruitEffect3:play(nil, false, nil, "texiao04")
		elseif arg_31_0.types[3] == 2 then
			arg_31_0.effects.xianshi.fruitEffect3:play(nil, false, nil, "texiao02")
		elseif arg_31_0.types[3] == 3 then
			arg_31_0.effects.xianshi.fruitEffect3:play(nil, false, nil, "texiao03")
		end
	elseif arg_31_0.totalCount == var_31_4 then
		if arg_31_0.gotSpecial then
			arg_31_0.effects.laohuji:play(nil, true, nil, "texiao03")
		end
	elseif arg_31_0.totalCount == var_31_5 then
		if arg_31_0.gotSpecial then
			-- block empty
		else
			xyd.WindowManager.get():openWindow("chocolate_slot_machine_award", arg_31_0.awardlist)
			arg_31_0:nodeByName("title_container"):setVisible(true)
			arg_31_0:nodeByName("close"):setVisible(true)
			arg_31_0:nodeByName("btn_one"):setTouchEnabled(true)
			arg_31_0:nodeByName("btn_ten"):setTouchEnabled(true)
		end
	elseif arg_31_0.totalCount == var_31_6 then
		if arg_31_0.gotSpecial then
			xyd.WindowManager.get():openWindow("chocolate_slot_machine_award", arg_31_0.awardlist)
			arg_31_0:nodeByName("title_container"):setVisible(true)
			arg_31_0:nodeByName("close"):setVisible(true)
			arg_31_0:nodeByName("btn_one"):setTouchEnabled(true)
			arg_31_0:nodeByName("btn_ten"):setTouchEnabled(true)
		end
	elseif arg_31_0.totalCount == var_31_7 then
		var_0_5.unscheduleGlobal(arg_31_0.handle)

		arg_31_0.handle = nil

		arg_31_0.effects.laohuji:play(nil, true, nil, "texiao01")
	end

	arg_31_0.totalCount = arg_31_0.totalCount + 1
end

function var_0_0.getAwards(arg_32_0, arg_32_1)
	local var_32_0 = xyd.WindowManager.get():getWindow("chocolate_slot_machine_raise")

	xyd.WindowManager.get():closeWindow(var_32_0)

	arg_32_0.awardlist = arg_32_1

	local var_32_1 = arg_32_0.awardlist.details[1].idx

	arg_32_0.types = var_0_4:content(var_32_1)
	arg_32_0.gotSpecial = false

	for iter_32_0 = 1, #arg_32_0.awardlist.details do
		local var_32_2 = arg_32_0.awardlist.details[iter_32_0].idx
		local var_32_3 = var_0_4:content(var_32_2)

		if var_32_3[1] == var_32_3[2] and var_32_3[2] == var_32_3[3] then
			arg_32_0.gotSpecial = true
		end
	end

	for iter_32_1 = 1, #arg_32_0.awardlist.awards do
		arg_32_0.selfPlayer:handleRewardsWithoutShow(arg_32_0.awardlist.awards[iter_32_1])
	end

	for iter_32_2 = 1, #arg_32_0.awardlist.extra_awards do
		arg_32_0.selfPlayer:handleRewardsWithoutShow(arg_32_0.awardlist.extra_awards[iter_32_2])
	end

	arg_32_0:createScheduler()
end

return var_0_0
