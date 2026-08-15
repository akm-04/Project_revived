local var_0_0 = class("GoldenHandWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.WindowName.goldenHand
local var_0_2 = import("framework.scheduler")
local var_0_3 = "ctn_use_window"
local var_0_4 = xyd.tables.translation

var_0_0.USE_BUTTON = "use_btn"
var_0_0.CTN_USE_BUTTON = "ctn_use_btn"
var_0_0.CAN_USE_TIMES = "can_use_times_txt"
var_0_0.DIAMOND_NUM = "diamond_num_txt"
var_0_0.LEAST_COINS = "least_coins_txt"
var_0_0.COIN_IMG = "coin_img"
var_0_0.DIAMOND_IMG = "diamond_img"
var_0_0.JIANTOU_IMG = "jiantou_img"
var_0_0.CHECK_VIP = "check_vip_btn"
var_0_0.TIPS = "tips_txt"
var_0_0.USE_TXT = "use_txt"
var_0_0.CTN_USE_TXT = "ctn_use_txt"
var_0_0.BUTTON_BAO = "Button_bao"
var_0_0.CHECK_BAO_BTN = "check_bao_btn"
var_0_0.TEN_CRIT_TXT = "ten_crit_txt"
var_0_0.TEN_CRIT_TXT2 = "ten_crit_txt2"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.goldenHandModel = xyd.ModelManager.get():loadModel(xyd.ModelType.GOLDENHAND)
	arg_1_0.buyCoinTimes = arg_1_0.selfPlayer.buyManaTimes
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.container = arg_2_0:nodeByName("container")
	arg_2_0.tenfoldTimes = 0
	arg_2_0.maxtimes = xyd.tables.dailyConsume:getNum(xyd.DailyConsumeType.Gold)
	arg_2_0.tenfoldCoinCost = xyd.tables.dailyConsume:getCost(xyd.DailyConsumeType.Gold)
	arg_2_0.isTenfold = nil
	arg_2_0.listView_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 680, 120),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("list"))

	arg_2_0.listView_:setBounceable(true)
	arg_2_0.goldenHandModel:checkTenfoldUseTimes(function(arg_3_0)
		local var_3_0 = arg_3_0.buy_times

		arg_2_0.tenfoldTimes = tonumber(string.sub(var_3_0, 1, 1))
	end)
	arg_2_0:init()
	arg_2_0:checkCanUseTimes()
end

function var_0_0.init(arg_4_0)
	arg_4_0:nodeByName(var_0_0.DIAMOND_NUM):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_4_0:nodeByName(var_0_0.LEAST_COINS):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_4_0:nodeByName(var_0_0.TIPS):setString(var_0_4:translation("CRYSTAL_TO_COIN_ADD_VIP"))
	arg_4_0:nodeByName("title_text"):setString(var_0_4:translation("EXCHANGE_MANA_TEXT"))
	arg_4_0:nodeByName("exchange_mana_text"):setString(var_0_4:translation("EXCHANGE_MANA_TEXT"))
	arg_4_0:nodeByName("exchange_tip_txt"):setString(var_0_4:translation("CRYSTAL_TO_COIN"))
	arg_4_0:nodeByName("use_text"):setString(var_0_4:translation("GOLDEN_HAND_USE_TEXT"))
	arg_4_0:nodeByName("ctn_use_text"):setString(var_0_4:translation("GOLDEN_HAND_CONTINUE_USE_TEXT"))
	arg_4_0:nodeByName("check_vip_text"):setString(var_0_4:translation("GOLDEN_HAND_CHECK_VIP_TEXT"))
	arg_4_0:nodeByName("tenfold_text"):setString(var_0_4:translation("GOLDEN_HAND_TEN_FOLD_TEXT"))
	arg_4_0:nodeByName("tenfold_text1"):setString(var_0_4:translation("GOLDEN_HAND_TEN_FOLD_TEXT"))

	local var_4_0 = xyd.tables.translation
	local var_4_1 = xyd.tables.vip:dianJinNum(arg_4_0.selfPlayer.vip) - arg_4_0.selfPlayer.buyManaTimes

	if arg_4_0.selfPlayer.privilegeLeftCardDay > 0 then
		var_4_1 = var_4_1 + xyd.tables.monthlyPrivilege:numMidas(1)
	end

	local var_4_2 = var_4_0:translation("TODAY_USE_GOLDENHAND")

	arg_4_0.buyCoinCost = xyd.tables.refreshCost:buyCoinCost(arg_4_0.selfPlayer.buyManaTimes + 1)
	arg_4_0.buyManaRatio = xyd.tables.refreshCost:buyManaRatio(arg_4_0.selfPlayer.buyManaTimes + 1)

	arg_4_0:nodeByName("can_use_times_txt1"):setString(var_4_0:translation("GOLDEN_HAND_TIME_TEXT1"))
	arg_4_0:nodeByName("can_use_times_txt3"):setString(var_4_0:translation("GOLDEN_HAND_TIME_TEXT2"))

	local var_4_3 = xyd.tables.vip:dianJinNum(arg_4_0.selfPlayer.vip)

	if arg_4_0.selfPlayer.privilegeLeftCardDay > 0 then
		var_4_3 = var_4_3 + xyd.tables.monthlyPrivilege:numMidas(1)
	end

	arg_4_0:nodeByName("can_use_times_txt2"):setString(var_4_1 .. "/" .. var_4_3)

	for iter_4_0 = 2, 3 do
		local var_4_4 = arg_4_0:nodeByName("can_use_times_txt" .. iter_4_0 - 1)

		arg_4_0:nodeByName("can_use_times_txt" .. iter_4_0):setPositionX(var_4_4:getPositionX() + var_4_4:getContentSize().width + 10)
	end

	arg_4_0:nodeByName(var_0_0.DIAMOND_NUM):setString(arg_4_0.buyCoinCost)
	arg_4_0:nodeByName(var_0_0.LEAST_COINS):setString(arg_4_0:calCoinNum())

	local var_4_5 = xyd.AssetLoader:get():loadSprite("images/icon/mana_icon.png")
	local var_4_6 = arg_4_0.container:getContentSize().width
	local var_4_7 = arg_4_0.container:getContentSize().height
	local var_4_8 = var_4_6 / var_4_5:getContentSize().width

	var_4_5:setScale(var_4_8)

	local var_4_9 = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

	var_4_9:setPosition(var_4_6 / 2, var_4_7 / 2)
	var_4_9:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_9:setScale(var_4_7 / var_4_9:getHeight())

	local var_4_10 = cc.ClippingNode:create()

	var_4_10:setStencil(var_4_9)
	var_4_10:setInverted(true)
	var_4_10:setAlphaThreshold(0)
	arg_4_0.container:addChild(var_4_10)
	var_4_10:addChild(var_4_5)
	var_4_5:setPosition(var_4_6 / 2, var_4_7 / 2)
	var_4_5:setAnchorPoint(cc.p(0.5, 0.5))

	local var_4_11 = xyd.getBorder(1, false)

	xyd.displaySpriteOnContainer(var_4_11, arg_4_0.container, true)
end

function var_0_0.checkCanUseTimes(arg_5_0)
	local var_5_0 = xyd.tables.vip:dianJinNum(arg_5_0.selfPlayer.vip)

	if arg_5_0.selfPlayer.privilegeLeftCardDay > 0 then
		var_5_0 = var_5_0 + xyd.tables.monthlyPrivilege:numMidas(1)
	end

	if var_5_0 - arg_5_0.selfPlayer.buyManaTimes <= 0 then
		arg_5_0:nodeByName(var_0_0.COIN_IMG):setVisible(false)
		arg_5_0:nodeByName(var_0_0.DIAMOND_IMG):setVisible(false)
		arg_5_0:nodeByName(var_0_0.JIANTOU_IMG):setVisible(false)
		arg_5_0:nodeByName(var_0_0.LEAST_COINS):setVisible(false)
		arg_5_0:nodeByName(var_0_0.DIAMOND_NUM):setVisible(false)
		arg_5_0:nodeByName(var_0_0.USE_BUTTON):setVisible(false)
		arg_5_0:nodeByName(var_0_0.CTN_USE_BUTTON):setVisible(false)
		arg_5_0:nodeByName(var_0_0.BUTTON_BAO):setVisible(false)
		arg_5_0:nodeByName(var_0_0.CHECK_BAO_BTN):setVisible(true)
		arg_5_0:nodeByName(var_0_0.CHECK_VIP):setVisible(true)
		arg_5_0:nodeByName(var_0_0.TIPS):setVisible(true)
		arg_5_0:nodeByName("middle_bg"):height(80)
		xyd.setPositionBy(arg_5_0:nodeByName("middle_bg"), cc.p(0, -10))
	end
end

function var_0_0.calCoinNum(arg_6_0)
	arg_6_0.coinNum = math.ceil((xyd.tables.misc.midasBase + arg_6_0.selfPlayer.lev * xyd.tables.misc.midasLvInr) * arg_6_0.buyManaRatio * (1 + xyd.tables.misc.midasLeast))

	return arg_6_0.coinNum
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	arg_7_0:nodeByName(var_0_0.BUTTON_BAO):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_7_0:nodeByName(var_0_0.BUTTON_BAO), arg_8_1)
		arg_7_0:buttonHandler(handler(arg_7_0, arg_7_0.ConfirmUseTenfold), arg_8_0, arg_8_1)
	end)
	arg_7_0:nodeByName(var_0_0.CHECK_BAO_BTN):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_7_0:nodeByName(var_0_0.CHECK_BAO_BTN), arg_9_1)
		arg_7_0:buttonHandler(handler(arg_7_0, arg_7_0.ConfirmUseTenfold), arg_9_0, arg_9_1)
	end)
	arg_7_0:nodeByName(var_0_0.USE_BUTTON):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_7_0:nodeByName(var_0_0.USE_BUTTON), arg_10_1)
		arg_7_0:buttonHandler(handler(arg_7_0, arg_7_0.useGoldenHandCallBack), arg_10_0, arg_10_1)
	end)
	arg_7_0:nodeByName(var_0_0.CTN_USE_BUTTON):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_7_0:nodeByName(var_0_0.CTN_USE_BUTTON), arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			local var_11_0 = {
				useTimes = arg_7_0:getCtnCount(),
				costTotal = arg_7_0.costTotal,
				gainTotal = arg_7_0.gainTotal
			}

			arg_7_0:nodeByName(var_0_0.CTN_USE_BUTTON):setScale(1)
			xyd.WindowManager.get():openWindow(var_0_3, var_11_0)
			xyd.playButtonSound()
		end
	end)
	arg_7_0:nodeByName(var_0_0.CHECK_VIP):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_7_0:nodeByName(var_0_0.CHECK_VIP), arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			local var_12_0 = {}

			var_12_0.windowState = false

			xyd.WindowManager.get():openWindow("vip_recharge", var_12_0)
			xyd.WindowManager.get():closeWindow("golden_hand")
			xyd.playButtonSound()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.CTN_USE_GOLDEN_HAND, function(arg_13_0)
		arg_7_0:ctnUseGoldenHand()
	end)
	arg_7_0:addBlockLayer()
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RIGHT_PULL
	})
end

function var_0_0.buttonHandler(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	if arg_14_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_14_2)
		arg_14_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound("sound/button.ogg", false)

		if arg_14_1 then
			arg_14_1(arg_14_2, arg_14_3)
		end
	elseif arg_14_3 == ccui.TouchEventType.began then
		return true
	elseif arg_14_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_14_2)
		arg_14_2:setScale(1)
	end
end

function var_0_0.returnCallBack(arg_15_0)
	xyd.WindowManager.get():closeWindow("golden_hand")
end

function var_0_0.useGoldenHandCallBack(arg_16_0)
	xyd.playButtonSound()

	if arg_16_0.selfPlayer.crystal < arg_16_0.buyCoinCost then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_4:translation("ZUANSHI_ABSENCE"), function()
			local var_17_0 = {}

			var_17_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_17_0)
		end, nil, nil, arg_16_0.colorMode)

		return
	end

	arg_16_0.goldenHandModel:useGoldenHand(function(arg_18_0)
		if arg_18_0 == xyd.error.OK then
			arg_16_0:updateItems()
		end
	end)
end

function var_0_0.ConfirmUseTenfold(arg_19_0)
	if arg_19_0.tenfoldTimes >= arg_19_0.maxtimes then
		local var_19_0 = xyd.tables.translation:translation("DAILY_TIMES_OVER")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_19_0
		})

		return
	end

	local var_19_1 = arg_19_0.buyCoinCost + xyd.tables.dailyConsume:getCost(xyd.DailyConsumeType.Gold)
	local var_19_2 = arg_19_0.buyCoinCost

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(xyd.tables.translation:translation("DAILY_GOLDEN_INFO"), var_19_1, var_19_2), function()
		arg_19_0:tenfoldUseGoldenHand()
	end, nil, 0, arg_19_0.colorMode)
end

function var_0_0.tenfoldUseGoldenHand(arg_21_0)
	xyd.playButtonSound()

	if arg_21_0.selfPlayer.crystal < arg_21_0.tenfoldCoinCost + arg_21_0.buyCoinCost then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_4:translation("ZUANSHI_ABSENCE"), function()
			local var_22_0 = {}

			var_22_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_22_0)
		end, nil, nil, arg_21_0.colorMode)

		return
	end

	arg_21_0.isTenfold = true

	arg_21_0.goldenHandModel:useTenfoldGoldenHand(function(arg_23_0)
		if arg_23_0 == xyd.error.OK then
			arg_21_0.tenfoldTimes = arg_21_0.tenfoldTimes + 1

			arg_21_0:updateItems()
		end
	end)
end

function var_0_0.ctnUseGoldenHand(arg_24_0)
	if arg_24_0.selfPlayer.crystal < arg_24_0.buyCoinCost then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_4:translation("ZUANSHI_ABSENCE"), function()
			local var_25_0 = {}

			var_25_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_25_0)
		end, nil, nil, arg_24_0.colorMode)

		if arg_24_0.handle_ then
			var_0_2.unscheduleGlobal(arg_24_0.handle_)
		end

		return
	end

	arg_24_0:nodeByName(var_0_0.USE_BUTTON):setTouchEnabled(false)
	arg_24_0:nodeByName(var_0_0.CTN_USE_BUTTON):setTouchEnabled(false)

	arg_24_0.handle_ = var_0_2.scheduleGlobal(function()
		arg_24_0.goldenHandModel:useGoldenHand(function(arg_27_0)
			if arg_27_0 == xyd.error.OK then
				local var_27_0 = xyd.WindowManager.get():getWindow("golden_hand")

				if var_27_0 then
					var_27_0.ctnCount = var_27_0.ctnCount - 1

					var_27_0:updateItems()

					if var_27_0.selfPlayer.crystal < var_27_0.buyCoinCost then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_4:translation("ZUANSHI_ABSENCE"), function()
							local var_28_0 = {}

							var_28_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_28_0)
						end, nil, nil, arg_24_0.colorMode)

						if var_27_0.handle_ then
							var_0_2.unscheduleGlobal(var_27_0.handle_)
						end
					end
				end
			end
		end)
	end, 0.3)
end

function var_0_0.stopCtnUse(arg_29_0, arg_29_1)
	var_0_2.unscheduleGlobal(arg_29_0.handle_)
	arg_29_0:nodeByName(var_0_0.USE_BUTTON):setTouchEnabled(true)
	arg_29_0:nodeByName(var_0_0.CTN_USE_BUTTON):setTouchEnabled(true)
end

function var_0_0.getCtnCount(arg_30_0)
	local var_30_0 = arg_30_0.selfPlayer.buyManaTimes + 1

	dump(arg_30_0.selfPlayer.buyManaTimes)

	arg_30_0.ctnCount = 1
	arg_30_0.costTotal = xyd.tables.refreshCost:buyCoinCost(var_30_0)

	local var_30_1 = #xyd.tables.refreshCost.buyCoinCost_
	local var_30_2 = xyd.tables.vip:dianJinNum(arg_30_0.selfPlayer.vip)

	if arg_30_0.selfPlayer.privilegeLeftCardDay > 0 then
		var_30_2 = var_30_2 + xyd.tables.monthlyPrivilege:numMidas(1)
	end

	while xyd.tables.refreshCost:buyCoinCost(var_30_0) == xyd.tables.refreshCost:buyCoinCost(var_30_0 + 1) and var_30_0 < var_30_1 and var_30_0 < var_30_2 do
		arg_30_0.ctnCount = arg_30_0.ctnCount + 1
		arg_30_0.costTotal = arg_30_0.costTotal + xyd.tables.refreshCost:buyCoinCost(var_30_0 + 1)
		var_30_0 = var_30_0 + 1
	end

	arg_30_0.gainTotal = arg_30_0.ctnCount * arg_30_0:calCoinNum()

	return arg_30_0.ctnCount
end

function var_0_0.updateItems(arg_31_0)
	arg_31_0:nodeByName("bg_bottom_img"):setVisible(true)

	if not arg_31_0.isTenfold then
		arg_31_0.selfPlayer.buyManaTimes = arg_31_0.goldenHandModel.buyManaTimes

		arg_31_0:init()
	end

	arg_31_0.isTenfold = false

	local var_31_0 = import("app.windows.GoldenHandItem").new()
	local var_31_1 = {
		cost = arg_31_0.goldenHandModel.diamond,
		gain = arg_31_0.goldenHandModel.coinNum,
		crit = arg_31_0.goldenHandModel.crit
	}

	var_31_0:setParams(var_31_1)
	var_31_0:setPosition(0, 0)
	var_31_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_31_0:ignoreAnchorPointForPosition(false)

	local var_31_2 = arg_31_0.listView_:newItem()

	var_31_2:addContent(var_31_0)
	var_31_0:setContentSize(600, 60)
	var_31_2:setItemSize(600, 43)
	arg_31_0.listView_:addItem(var_31_2)
	arg_31_0.listView_:reload()

	local var_31_3, var_31_4 = arg_31_0.listView_.scrollNode:getPosition()

	if var_31_4 <= 9 then
		arg_31_0.listView_.scrollNode:setPosition(0, 15)
		var_0_2.performWithDelayGlobal(function()
			if xyd.WindowManager.get():getWindow("golden_hand") then
				arg_31_0.listView_.scrollNode:setPosition(0, 9)
			end
		end, 0.1)
	end

	if arg_31_0.ctnCount == 0 then
		arg_31_0:stopCtnUse(arg_31_0.handle_)
	end

	arg_31_0:checkCanUseTimes()
end

function var_0_0.willClose(arg_33_0)
	if arg_33_0.handle_ then
		var_0_2.unscheduleGlobal(arg_33_0.handle_)

		arg_33_0.handle_ = nil
	end
end

return var_0_0
