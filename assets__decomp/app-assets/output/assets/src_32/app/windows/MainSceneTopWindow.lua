local var_0_0 = class("MainSceneTopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.EcoSidebar")
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.AssetLoader.get()
local var_0_4 = xyd.tables.translation
local var_0_5 = "skeletons/ui_effect/charge/effect_charge"
local var_0_6 = import("app.common.ui.SpineEffect")
local var_0_7 = xyd.tables.activities
local var_0_8 = {
	"new_server_push",
	"gift_push",
	"walfare",
	"seven_day_login",
	"btn_battle_pass"
}
local var_0_9 = 331
local var_0_10 = 88

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.addEnergyModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ADD_ENERGY)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.achievement = xyd.ModelManager.get():loadModel(xyd.ModelType.ACHIEVEMENT)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.mailbox = xyd.ModelManager.get():loadModel(xyd.ModelType.MAILBOX)
	arg_1_0.adventureEvent = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
	arg_1_0.manualCloseTopBtn = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1, arg_2_2)
	arg_2_0:addEcoBar()
	arg_2_0:regLeftButtons()
	arg_2_0:updatePlayerInfo()
	arg_2_0:initActList()
	arg_2_0:onEnterAction()
	arg_2_0:checkGameStat()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.MAIN_SCENE_ACTION_START, function(arg_3_0)
		arg_2_0:onEnterAction(arg_3_0.params and arg_3_0.params.quickAction)
		xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):popGift()
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.MAIN_SCENE_ACTION_END, function(arg_4_0)
		arg_2_0:onEnterActionEnd()
	end)
end

function var_0_0.addEcoBar(arg_5_0)
	local var_5_0 = {
		type = xyd.EcoSidebarType.MAIN,
		colorMode = xyd.ColorMode.GREEN
	}
	local var_5_1 = var_0_1.new(xyd.WidgetName.ecoSidebar, var_5_0)

	var_5_1:addTo(arg_5_0:nodeByName("eco_bar_pos"))
	var_5_1:setAnchorPoint(0, 0)
	var_5_1:setPosition(0, 0)
	var_5_1:setName("eco_sidebar")

	arg_5_0.children_.eco_sidebar = var_5_1
end

function var_0_0.regLeftButtons(arg_6_0)
	arg_6_0.actBtn = arg_6_0:nodeByName("btn_act")

	xyd.nodeEventSample(arg_6_0.actBtn, {
		force = true
	}, function()
		arg_6_0:functionClickRecord(xyd.FunctionClick.ACTIVITIES)

		if arg_6_0.selfPlayer.lev < 20 then
			arg_6_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_ACTIVITIES_LEV_LESS_20)
		end

		arg_6_0.activities:loadActivities(function(arg_8_0)
			if arg_8_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("activities")
			end
		end)
	end)

	arg_6_0.shopBtn = arg_6_0:nodeByName("btn_shop")

	xyd.nodeEventSample(arg_6_0.shopBtn, {
		force = true
	}, function()
		if not arg_6_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_SHOP) then
			local var_9_0 = xyd.tables.functionOpen
			local var_9_1 = xyd.tables.campaign
			local var_9_2 = "NUM_" .. var_9_1:chapter(var_9_0:stage(xyd.FunctionID.ID_SHOP))
			local var_9_3 = string.format(var_0_4:translation("FUNCTION_OPEN_TIP_STAGE"), var_0_4:translation(var_9_2))

			xyd.WindowManager.get():openWindow("toast", {
				message = var_9_3
			})

			return
		end

		if arg_6_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_AUCTION) or arg_6_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_SKIN_SHOP) then
			xyd.WindowManager.get():openWindow("sub_shop")
		else
			xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
				xyd.WindowManager.get():openWindow("shop", {
					shop_type = 1
				})
			end)
		end

		arg_6_0:removeGuideHand("btn_shop")
	end)

	arg_6_0.mailBtn = arg_6_0:nodeByName("btn_mail")

	xyd.nodeEventSample(arg_6_0.mailBtn, {
		force = true
	}, function()
		xyd.WindowManager.get():openWindow("mailbox")
	end)

	arg_6_0.friendBtn = arg_6_0:nodeByName("btn_friend")

	xyd.nodeEventSample(arg_6_0.friendBtn, {
		force = true
	}, function()
		arg_6_0:removeGuideHand("btn_friend")

		local var_12_0 = {}

		if arg_6_0.goToClass then
			arg_6_0.goToClass = false
			var_12_0.goToClass = true
		end

		xyd.WindowManager.get():openWindow("social_system", var_12_0)
	end)

	arg_6_0.rankBtn = arg_6_0:nodeByName("btn_rank")

	xyd.nodeEventSample(arg_6_0.rankBtn, {
		force = true
	}, function()
		xyd.WindowManager.get():openWindow("new_rank_list", {})
	end)
end

function var_0_0.updatePlayerInfo(arg_14_0)
	local var_14_0 = {
		outlineSize = 2,
		lev = arg_14_0.selfPlayer.lev,
		conquerLev = arg_14_0.selfPlayer.conquerLev,
		loopID = arg_14_0.selfPlayer.conquerLoopID,
		fontColor = cc.c3b(255, 255, 255),
		outlineColor = cc.c4b(1, 1, 1, 200)
	}

	xyd.setLev(arg_14_0:nodeByName("lv_container"), var_14_0)
	arg_14_0:nodeByName("txt_name"):setString(arg_14_0.selfPlayer.playerName)
	arg_14_0:nodeByName("txt_vip"):setString("VIP " .. arg_14_0.selfPlayer.vip)

	local var_14_1 = {
		avatar_id = arg_14_0.selfPlayer:getMyCurrentAvatarID(),
		avatar_frame_id = arg_14_0.selfPlayer.avatarFrame,
		playerInfo = {
			player_id = arg_14_0.selfPlayer.playerID
		}
	}

	arg_14_0:nodeByName("avatar"):removeAllChildren()
	xyd.setPlayerAvatar(arg_14_0:nodeByName("avatar"), var_14_1)
end

function var_0_0.initActList(arg_15_0, arg_15_1, arg_15_2)
	arg_15_0.setupFunction = {}
	arg_15_0.setupFunction[1036] = arg_15_0.redEnvelopeSetup
	arg_15_0.setupFunction[1042] = arg_15_0.openServiceSetup
	arg_15_0.setupFunction[1051] = arg_15_0.luckyPacketSetup
	arg_15_0.setupFunction[1052] = arg_15_0.kiteSetup
	arg_15_0.setupFunction[1060] = arg_15_0.dragonBoatSetup
	arg_15_0.setupFunction[1062] = arg_15_0.beachSetup
	arg_15_0.setupFunction[1064] = arg_15_0.jigsawSetup
	arg_15_0.setupFunction[1070] = arg_15_0.starTreasureSetup
	arg_15_0.setupFunction[1075] = arg_15_0.fireworkSetup
	arg_15_0.setupFunction[1082] = arg_15_0.singleDaySetup
	arg_15_0.setupFunction[1083] = arg_15_0.lvbuFestivalSetup
	arg_15_0.setupFunction[1086] = arg_15_0.vipBoxDrawSetup
	arg_15_0.setupFunction[1092] = arg_15_0.sakura2Setup
	arg_15_0.setupFunction[1104] = arg_15_0.dragonBoat2017Setup
	arg_15_0.setupFunction[1106] = arg_15_0.zhangheBoxSetup
	arg_15_0.setupFunction[1109] = arg_15_0.zhugeFestivalSetup
	arg_15_0.setupFunction[1111] = arg_15_0.summerSetup
	arg_15_0.setupFunction[1113] = arg_15_0.popularityContestSetup
	arg_15_0.setupFunction[1114] = arg_15_0.concentrateSetup
	arg_15_0.setupFunction[1115] = arg_15_0.blackFridaySetup
	arg_15_0.setupFunction[1118] = arg_15_0.newTermSetup
	arg_15_0.setupFunction[1119] = arg_15_0.warCampSetup
	arg_15_0.setupFunction[1125] = arg_15_0.snowBallSetup
	arg_15_0.setupFunction[1132] = arg_15_0.snowActivitySetup
	arg_15_0.setupFunction[1138] = arg_15_0.stickBlessSetup
	arg_15_0.setupFunction[1144] = arg_15_0.sakura2018Setup
	arg_15_0.setupFunction[1150] = arg_15_0.gardenSeedSetup
	arg_15_0.setupFunction[1151] = arg_15_0.sakuraWishesSetup
	arg_15_0.setupFunction[1158] = arg_15_0.gardenSetup
	arg_15_0.setupFunction[1162] = arg_15_0.thirdAnniversarySetup
	arg_15_0.setupFunction[1167] = arg_15_0.newOpenServiceSetup
	arg_15_0.setupFunction[1169] = arg_15_0.superRichSetup
	arg_15_0.setupFunction[1170] = arg_15_0.cvLinkSetup
	arg_15_0.setupFunction[1172] = arg_15_0.monthLimit2Setup
	arg_15_0.setupFunction[1177] = arg_15_0.chocolateSetup
	arg_15_0.setupFunction[1178] = arg_15_0.activityRecall
	arg_15_0.setupFunction[1184] = arg_15_0.tutorSetup
	arg_15_0.setupFunction[1186] = arg_15_0.jigsaw2Setup
	arg_15_0.setupFunction[1188] = arg_15_0.dreamWorldSetup
	arg_15_0.setupFunction[1193] = arg_15_0.championsLeagueSetup
	arg_15_0.setupFunction[1194] = arg_15_0.fourthAnniversarySetup
	arg_15_0.setupFunction[1198] = arg_15_0.sakuraWishes2Setup
	arg_15_0.setupFunction[1199] = arg_15_0.allNigntSetup
	arg_15_0.setupFunction[1202] = arg_15_0.flappyBirdSetup
	arg_15_0.setupFunction[1203] = arg_15_0.ragnarokSetup
	arg_15_0.setupFunction[1204] = arg_15_0.monthLimit3Setup
	arg_15_0.setupFunction[1206] = arg_15_0.newVipBoxDrawSetup
	arg_15_0.setupFunction[1214] = arg_15_0.activityWufuSetup
	arg_15_0.setupFunction[1221] = arg_15_0.skinShopDiscountSetup
	arg_15_0.setupFunction[1226] = arg_15_0.activityFishingSetup
	arg_15_0.setupFunction[1232] = arg_15_0.fifthAnniversarySetup
	arg_15_0.setupFunction[9999] = arg_15_0.adventureEventSetup
	arg_15_0.setupFunction[10000] = arg_15_0.picNoticeSetup
	arg_15_0.actContainer = arg_15_0:nodeByName("act_container")

	local var_15_0 = display.newNode()

	var_15_0:addTo(arg_15_0.actContainer, -1)

	local var_15_1 = arg_15_0.actContainer:getContentSize()

	var_15_0:setContentSize(var_15_1.width, var_15_1.height)
	var_15_0:setTouchEnabled(true)
	arg_15_0:nodeByName("xue"):setTouchSwallowEnabled(false)
	arg_15_0:nodeByName("xuehua"):setTouchSwallowEnabled(false)

	arg_15_0.listContainer = arg_15_0:nodeByName("act_list")

	local var_15_2 = arg_15_0.listContainer:getContentSize()

	arg_15_0.listWidth = var_15_2.width

	local var_15_3 = cc.rect(0, 0, var_15_2.width, var_15_2.height)

	arg_15_0.actList = display.newClippingRectangleNode(var_15_3)

	arg_15_0.actList:addTo(arg_15_0.listContainer)

	arg_15_0.actArrowLeft = arg_15_0:nodeByName("arrow_act_left")

	xyd.nodeEventSample(arg_15_0.actArrowLeft, {
		force = true
	}, function(arg_16_0, arg_16_1)
		arg_15_0.actMoveCount = 0

		arg_15_0:actMove(false)
	end)

	arg_15_0.actArrowRight = arg_15_0:nodeByName("arrow_act_right")

	xyd.nodeEventSample(arg_15_0.actArrowRight, {
		force = true
	}, function(arg_17_0, arg_17_1)
		arg_15_0.actMoveCount = 0

		arg_15_0:actMove(true)
	end)
	arg_15_0:updateButtonTable()

	arg_15_0.chargeBtn = arg_15_0:nodeByName("btn_charge")
	arg_15_0.firstChargeBtn = arg_15_0:nodeByName("btn_first_charge")

	if arg_15_0.activities:isFirstChargeShow() then
		arg_15_0.firstChargeBtn:setVisible(true)
		arg_15_0.chargeBtn:setVisible(false)
	else
		arg_15_0.firstChargeBtn:setVisible(false)
		arg_15_0.chargeBtn:setVisible(true)
	end

	local var_15_4 = xyd.createEffect(var_0_5)

	var_15_4:addTo(arg_15_0.firstChargeBtn)

	local var_15_5 = arg_15_0.firstChargeBtn:getContentSize()

	var_15_4:play(nil, true)
	var_15_4:setPosition(var_15_5.width / 2 - 1, var_15_5.height / 2 + 2)

	local var_15_6 = xyd.createEffect(var_0_5)

	var_15_6:addTo(arg_15_0.chargeBtn)

	local var_15_7 = arg_15_0.chargeBtn:getContentSize()

	var_15_6:play(nil, true)
	var_15_6:setPosition(var_15_7.width / 2 - 1, var_15_7.height / 2 + 2)

	arg_15_0.energyTips = {}
	arg_15_0.GuideHands = {}

	arg_15_0:setTouchSwallowEnabled(false)
end

function var_0_0.isActivityShow(arg_18_0, arg_18_1)
	if var_0_7:isShow(arg_18_1) ~= 0 and var_0_7:isShow(arg_18_1) ~= 3 then
		return false
	end

	if arg_18_1 == xyd.Activities.BEACH then
		return arg_18_0.activities:isBeachShow()
	end

	if arg_18_1 == xyd.Activities.ZhugeFestival then
		return arg_18_0.activities:isZhugeActivityShow() > 0
	end

	if arg_18_1 == xyd.Activities.NewOpenService then
		return arg_18_0.activities:isNewOpenServiceShow()
	end

	if arg_18_1 == xyd.Activities.Recall then
		return arg_18_0.activities:isRecallShow()
	end

	return arg_18_0.activities:isActivityOpen(arg_18_1)
end

function var_0_0.updateButtonTable(arg_19_0)
	local var_19_0 = arg_19_0.activities:getActivitiesList()

	arg_19_0.activities:activityListSort()

	arg_19_0.buttonTable = {}
	arg_19_0.adventureEventEarliestTime = arg_19_0.adventureEvent:getStartEarliestTime().time

	if arg_19_0.adventureEventEarliestTime - xyd.ServerTime.get():getServerTime() > 0 then
		table.insert(arg_19_0.buttonTable, 9999)
	end

	for iter_19_0 = 1, #var_19_0 do
		local var_19_1 = var_19_0[iter_19_0].table_id

		if arg_19_0:isActivityShow(var_19_1) then
			table.insert(arg_19_0.buttonTable, var_19_1)
		end
	end

	table.insert(arg_19_0.buttonTable, 10000)
	arg_19_0.actList:removeAllChildren()

	if #arg_19_0.buttonTable > 0 then
		arg_19_0.actContainer:setVisible(true)
		arg_19_0:loadActList()
		arg_19_0:fitListView()
	else
		arg_19_0.actContainer:setVisible(false)
	end
end

function var_0_0.loadActList(arg_20_0)
	local var_20_0 = #arg_20_0.buttonTable
	local var_20_1 = 16
	local var_20_2, var_20_3 = arg_20_0:nodeByName("tab_pos"):getPosition()

	if arg_20_0.listTabs and next(arg_20_0.listTabs) then
		for iter_20_0, iter_20_1 in ipairs(arg_20_0.listTabs) do
			iter_20_1:removeSelf()
		end
	end

	arg_20_0.listTabs = {}

	for iter_20_2 = 1, var_20_0 do
		local var_20_4 = var_0_3:loadSprite("windows/main_top_window/tab.png")

		var_20_4:addTo(arg_20_0.actContainer)
		var_20_4:setPosition(var_20_2 + var_20_1 * (iter_20_2 - var_20_0 / 2 - 0.5), var_20_3)

		arg_20_0.listTabs[iter_20_2] = var_20_4
	end

	arg_20_0.actArrowLeft:setVisible(#arg_20_0.buttonTable > 1)
	arg_20_0.actArrowRight:setVisible(#arg_20_0.buttonTable > 1)

	local var_20_5 = arg_20_0:createActNode(1)

	var_20_5:addTo(arg_20_0.actList)
	var_20_5:setName("now")

	arg_20_0.actIdx = 1

	if arg_20_0.actMoveHandle then
		var_0_2.unscheduleGlobal(arg_20_0.actMoveHandle)
	end

	arg_20_0.actMoveHandle = var_0_2.scheduleGlobal(function()
		arg_20_0.actMoveCount = (arg_20_0.actMoveCount or 0) + 1

		if arg_20_0.actMoveCount >= 5 then
			arg_20_0:actMove(true)

			arg_20_0.actMoveCount = 0
		end
	end, 1)
end

function var_0_0.createActNode(arg_22_0, arg_22_1)
	local var_22_0 = xyd.SpriteLoader.new("images/main_act/" .. arg_22_0.buttonTable[arg_22_1] .. ".png", nil, nil, xyd.DefaultImageType.MAIN_ACT)
	local var_22_1 = var_22_0:getContentSize()
	local var_22_2 = xyd.AssetLoader.get():loadSprite("windows/common/red_point.png")

	var_22_2:addTo(var_22_0)
	var_22_2:setAnchorPoint(cc.p(1, 1))
	var_22_2:setPosition(var_22_1.width - 3, var_22_1.height - 3)
	var_22_2:setScale(0.8)
	var_22_2:setName("notif")
	var_22_2:setLocalZOrder(100)
	var_22_2:setVisible(false)

	var_22_0 = arg_22_0.setupFunction[arg_22_0.buttonTable[arg_22_1]] and arg_22_0.setupFunction[arg_22_0.buttonTable[arg_22_1]](arg_22_0, var_22_0, arg_22_0.buttonTable[arg_22_1]) or var_22_0

	var_22_0:setAnchorPoint(cc.p(0, 0))

	return var_22_0
end

function var_0_0.fitListView(arg_23_0)
	local var_23_0 = arg_23_0.actIdx

	if arg_23_0.listIdx and arg_23_0.listTabs[arg_23_0.listIdx] then
		arg_23_0.listTabs[arg_23_0.listIdx]:removeChildByName("light")
	end

	if arg_23_0.listTabs[var_23_0] then
		local var_23_1 = var_0_3:loadSprite("windows/main_top_window/tab_light.png")

		var_23_1:setAnchorPoint(cc.p(0, 0))
		var_23_1:addTo(arg_23_0.listTabs[var_23_0])
		var_23_1:setName("light")
	end

	arg_23_0.listIdx = var_23_0
end

function var_0_0.actMove(arg_24_0, arg_24_1)
	if #arg_24_0.buttonTable < 2 then
		return
	end

	arg_24_0.isActMoving = true

	local var_24_0 = arg_24_0.actIdx

	var_24_0 = arg_24_1 and var_24_0 + 1 or var_24_0 - 1
	var_24_0 = var_24_0 < 1 and #arg_24_0.buttonTable or var_24_0
	var_24_0 = var_24_0 > #arg_24_0.buttonTable and 1 or var_24_0
	arg_24_0.actIdx = var_24_0

	local var_24_1 = arg_24_0:createActNode(var_24_0)

	var_24_1:addTo(arg_24_0.actList)
	var_24_1:setPositionX(arg_24_1 and arg_24_0.listWidth or -arg_24_0.listWidth)

	local var_24_2 = 0.3
	local var_24_3 = cc.p(arg_24_1 and -arg_24_0.listWidth or arg_24_0.listWidth, 0)
	local var_24_4

	while true do
		local var_24_5 = arg_24_0.actList:getChildByName("now")

		if not var_24_5 then
			break
		end

		if var_24_4 and not tolua.isnull(var_24_4) then
			var_24_4:removeSelf()
		end

		var_24_5:setName("tmp")

		var_24_4 = var_24_5
	end

	if var_24_4 and not tolua.isnull(var_24_4) then
		var_24_4:runAction(cc.MoveBy:create(var_24_2, var_24_3))
	end

	var_24_1:runAction(cc.Sequence:create({
		cc.MoveBy:create(var_24_2, var_24_3),
		cc.CallFunc:create(function()
			if var_24_4 and not tolua.isnull(var_24_4) then
				var_24_4:removeSelf()
			end

			var_24_1:setName("now")
			arg_24_0:fitListView()

			arg_24_0.isActMoving = false
		end)
	}))
end

function var_0_0.didOpen(arg_26_0)
	arg_26_0:updateTopBtn()
	arg_26_0:checkMonthCardShow()
	arg_26_0:checkChargeBtnRedPoint()
	arg_26_0:onEnterAction()
	arg_26_0:onUpdateEnergyTimer()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_26_0):addEventListener(xyd.event.PLAYER_LEVEL_UP, handler(arg_26_0, arg_26_0.updatePlayerInfo))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_26_0):addEventListener(xyd.event.MAIN_TOP_ACTIVITIES, function(arg_27_0)
		arg_26_0:updateButtonTable()
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_26_0):addEventListener(xyd.event.REFRESH_SUMMER_SHOW, function(arg_28_0)
		arg_26_0:updateButtonTable()
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_26_0):addEventListener(xyd.event.REFRESH_GARDEN_SHOW, function(arg_29_0)
		arg_26_0:updateButtonTable()
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_26_0):addEventListener(xyd.event.REFRESH_CHARGE_ACTIVITY_MAIN, function(arg_30_0)
		local var_30_0 = arg_30_0.params

		if var_30_0.isShow then
			arg_26_0.firstChargeBtn:setVisible(true)
			arg_26_0.chargeBtn:setVisible(false)
		else
			arg_26_0.firstChargeBtn:setVisible(false)
			arg_26_0.chargeBtn:setVisible(true)
		end

		arg_26_0.firstChargeBtn:getChildByName("notif"):setVisible(var_30_0.hasPoint or false)
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_26_0):addEventListener(xyd.event.ADVENTURE_EVENT_OCCUR, function(arg_31_0)
		arg_26_0:updateButtonTable()
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_26_0):addEventListener(xyd.event.ADVENTURE_EVENT_FINISH, function(arg_32_0)
		arg_26_0:updateButtonTable()
	end)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_CHARGE_ACTIVITY_MAIN,
		params = {
			isShow = arg_26_0.activities:isFirstChargeShow(),
			hasPoint = arg_26_0.activities:hasFirstChargePoint()
		}
	})
	arg_26_0.chargeBtn:addTouchEventListener(function(arg_33_0, arg_33_1)
		xyd.buttonScaleAnim(arg_26_0.chargeBtn, arg_33_1)

		if arg_33_1 == ccui.TouchEventType.ended then
			if arg_26_0.selfPlayer.lev < 20 then
				arg_26_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CHARGE_LEV_LESS_20)
			end

			xyd.playButtonSound()
			arg_26_0:functionClickRecord(xyd.FunctionClick.CHARGE)
			xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge, {
				chargeState = xyd.ChargeState.giftbag
			})
			arg_26_0.chargeBtn:getChildByName("notif"):setVisible(false)
		end
	end)
	arg_26_0.firstChargeBtn:addTouchEventListener(function(arg_34_0, arg_34_1)
		xyd.buttonScaleAnim(arg_26_0.firstChargeBtn, arg_34_1)

		if arg_34_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_26_0.selfPlayer.lev < 20 then
				arg_26_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CHARGE_LEV_LESS_20)
			end

			local var_34_0 = {}

			if arg_26_0.activities:isFirstChargeShow() ~= xyd.Activities.FirstRechargeNew then
				var_34_0.activity_id = xyd.Activities.FirstStoreAward

				arg_26_0.activities:loadSingleActivity(var_34_0, function(arg_35_0, arg_35_1)
					if arg_35_1.details and arg_35_1.is_open == 1 then
						local var_35_0 = {
							activity_id = xyd.Activities.FirstRecharge
						}

						arg_26_0.activities:loadSingleActivity(var_35_0, function(arg_36_0, arg_36_1)
							if arg_36_1.details then
								arg_35_1.hasUnlimitGift = arg_36_1.details.is_awarded
								arg_35_1.UnlimitTableId = arg_36_1.table_id

								if arg_35_1.details.is_awarded == 0 or arg_35_1.hasUnlimitGift == 0 then
									xyd.WindowManager.get():openWindow("firststore_new", arg_35_1)
								else
									xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
								end
							end
						end)
					else
						xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
					end
				end)
			else
				var_34_0.activity_id = xyd.Activities.FirstRechargeNew

				arg_26_0.activities:loadSingleActivity(var_34_0, function(arg_37_0, arg_37_1)
					xyd.WindowManager.get():openWindow("firststore_new2", arg_37_1)
				end)
			end
		end
	end)
	arg_26_0:nodeByName("month_blue"):setTouchEnabled(true)
	arg_26_0:nodeByName("month_blue"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_38_0)
		if arg_38_0.name == "began" then
			arg_26_0:nodeByName("month_blue"):setScale(0.9)

			local var_38_0 = {}

			if arg_26_0.selfPlayer.leftEnergyMonthCardDay > 0 then
				var_38_0.tili = true

				if arg_26_0.selfPlayer.leftCardDay > 0 then
					var_38_0.both = true
				end
			end

			local var_38_1 = xyd.WindowManager.get():openWindow("month_card_tips", var_38_0)
			local var_38_2 = var_38_1:getWndSize()
			local var_38_3 = cc.p(arg_26_0:nodeByName("month_blue"):getPosition())
			local var_38_4 = arg_26_0:nodeByName("month_blue"):getParent():convertToWorldSpace(cc.p(var_38_3))

			var_38_1:setPosition(cc.p(var_38_4.x - 40, var_38_4.y - var_38_2.height - 40))

			return true
		elseif arg_38_0.name == "ended" then
			arg_26_0:nodeByName("month_blue"):setScale(1)

			if xyd.WindowManager.get():getWindow("month_card_tips") then
				xyd.WindowManager.get():closeWindow("month_card_tips")
			end
		end
	end)

	local var_26_0 = xyd.tables.monthlyPrivilege:iconDisplay(1)

	arg_26_0:nodeByName("month"):setTouchEnabled(true)
	arg_26_0:nodeByName("month"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_39_0)
		if arg_39_0.name == "began" then
			arg_26_0:nodeByName("month"):setScale(0.9)

			if var_26_0 ~= 3 then
				local var_39_0 = {}

				if arg_26_0.selfPlayer.leftEnergyMonthCardDay > 0 then
					var_39_0.tili = true

					if arg_26_0.selfPlayer.leftCardDay > 0 then
						var_39_0.both = true
					end
				end

				local var_39_1 = xyd.WindowManager.get():openWindow("month_card_tips", var_39_0)
				local var_39_2 = var_39_1:getWndSize()
				local var_39_3 = cc.p(arg_26_0:nodeByName("month"):getPosition())
				local var_39_4 = arg_26_0:nodeByName("month"):getParent():convertToWorldSpace(cc.p(var_39_3))

				var_39_1:setPosition(cc.p(var_39_4.x - 40, var_39_4.y - var_39_2.height - 40))
			end

			return true
		elseif arg_39_0.name == "ended" then
			arg_26_0:nodeByName("month"):setScale(1)

			if var_26_0 == 3 then
				xyd.WindowManager.get():openWindow("new_month_card")
			elseif xyd.WindowManager.get():getWindow("month_card_tips") then
				xyd.WindowManager.get():closeWindow("month_card_tips")
			end
		end
	end)
	arg_26_0:nodeByName("month_green"):setTouchEnabled(true)
	arg_26_0:nodeByName("month_green"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_40_0)
		if arg_40_0.name == "began" then
			arg_26_0:nodeByName("month_green"):setScale(0.9)

			return true
		elseif arg_40_0.name == "ended" then
			arg_26_0:nodeByName("month_green"):setScale(1)
			xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge, {
				chargeState = xyd.ChargeState.monthlyPrivilege
			})
		end
	end)
	arg_26_0:nodeByName("month_gray"):setTouchEnabled(true)
	arg_26_0:nodeByName("month_gray"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_41_0)
		if arg_41_0.name == "began" then
			arg_26_0:nodeByName("month_gray"):setScale(0.9)

			return true
		elseif arg_41_0.name == "ended" then
			arg_26_0:nodeByName("month_gray"):setScale(1)
			xyd.WindowManager.get():openWindow("new_month_card")
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_26_0):addEventListener(xyd.event.EDIT_NAME_FINISHED, function(arg_42_0)
		arg_26_0:updatePlayerInfo()
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_26_0):addEventListener(xyd.event.REFRESH_AVATAR, function(arg_43_0)
		arg_26_0:updatePlayerInfo()
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_26_0):addEventListener(xyd.event.MAIN_SCENE_BOTTOM_NOTIFY, function(arg_44_0)
		if arg_44_0.params then
			local var_44_0 = arg_44_0.params.index
			local var_44_1 = arg_44_0.params.show or false

			if var_44_0 == 3 then
				arg_26_0:nodeByName("activity_notif"):setVisible(arg_26_0.activities.isRedMark or false)
				arg_26_0:nodeByName("friend_notif"):setVisible(arg_26_0.socialSystem:isHasRedMarkShow() or false)
			elseif var_44_0 == 2 then
				arg_26_0:nodeByName("mail_notif"):setVisible(var_44_1)
			end
		end
	end)
	arg_26_0:nodeByName("mail_notif"):setVisible(arg_26_0.mailbox:hasNewMail())
	arg_26_0.achievement:loadAchievementInfo({}, function(arg_45_0, arg_45_1)
		if arg_45_0 == xyd.error.OK then
			local var_45_0 = xyd.WindowManager.get():getWindow("main_scene_top")

			if var_45_0 and not tolua.isnull(var_45_0) then
				var_45_0:updateAchievementRedMark()
			end
		end
	end)
end

function var_0_0.isOpenNewSeverPush(arg_46_0, arg_46_1)
	local var_46_0 = arg_46_0.activities:getActivityInfo(xyd.Activities.NewServerPush)

	if not var_46_0 then
		return
	end

	if var_46_0.is_open == 0 then
		return false
	end

	if arg_46_0.selfPlayer.lev <= 6 then
		return false
	end

	if arg_46_1 then
		var_46_0.details.lev_time = arg_46_1

		return true
	elseif var_46_0.details.lev_time and var_46_0.details.lev_time + 259200 > xyd.ServerTime.get():getServerTime() then
		return true
	else
		return false
	end
end

function var_0_0.updatePush(arg_47_0)
	if arg_47_0:isOpenNewSeverPush() then
		local var_47_0 = arg_47_0:nodeByName("new_server_push")

		if arg_47_0.activities:getActivityInfo(xyd.Activities.NewServerPush).details.lev_time + 259200 - xyd.ServerTime.get():getServerTime() <= 0 then
			var_47_0:setVisible(false)
		else
			arg_47_0:updateNewServerPush()
		end
	else
		arg_47_0:nodeByName("new_server_push"):setVisible(false)
	end
end

function var_0_0.updateSevenDayLogin(arg_48_0, arg_48_1)
	if arg_48_0.manualCloseTopBtn.seven_day_login then
		return
	end

	if arg_48_1 then
		arg_48_0.manualCloseTopBtn.seven_day_login = true

		arg_48_0:nodeByName("seven_day_login"):setVisible(false)
		arg_48_0:updateTopBtn()
	else
		local var_48_0 = arg_48_0.activities:isActivityOpen(xyd.Activities.SevenDayLogin)

		arg_48_0:nodeByName("seven_day_login"):setVisible(var_48_0)

		if var_48_0 then
			local var_48_1 = var_0_9 + arg_48_0.topBtnIndex * var_0_10

			arg_48_0:nodeByName("seven_day_login"):setPositionX(var_48_1)

			arg_48_0.topBtnIndex = arg_48_0.topBtnIndex + 1

			arg_48_0:nodeByName("seven_day_login"):addTouchEventListener(function(arg_49_0, arg_49_1)
				xyd.buttonScaleAnim(arg_49_0, arg_49_1)

				if arg_49_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()

					local var_49_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
					local var_49_1 = {
						activity_id = xyd.Activities.SevenDayLogin
					}

					var_49_0:loadSingleActivity(var_49_1, function(arg_50_0, arg_50_1)
						if arg_50_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("seven_day_login", {
								response = arg_50_1
							})
						end
					end)
				end
			end)
		end
	end
end

function var_0_0.activityVanishCheck(arg_51_0, arg_51_1)
	if arg_51_1.table_id == xyd.Activities.MysteryGift and arg_51_1.details.create_time < arg_51_1.start_time then
		return true
	end

	return false
end

function var_0_0.updateWalfareOpen(arg_52_0, arg_52_1)
	if arg_52_0.manualCloseTopBtn.walfare then
		return
	end

	if arg_52_1 then
		arg_52_0:nodeByName("walfare"):setVisible(false)

		arg_52_0.manualCloseTopBtn.walfare = true

		arg_52_0:updateTopBtn()
	else
		local var_52_0 = arg_52_0.activities:getActivitiesList()
		local var_52_1 = false

		for iter_52_0 = 1, #var_52_0 do
			local var_52_2 = var_52_0[iter_52_0]

			if var_52_2 and xyd.tables.activities:walfareShow(var_52_2.table_id) == 1 and not arg_52_0:activityVanishCheck(var_52_2) then
				var_52_1 = arg_52_0.activities:isActivityOpen(var_52_2.table_id)

				break
			end
		end

		arg_52_0.walfareIsOpen = var_52_1

		arg_52_0:nodeByName("walfare"):setVisible(var_52_1)

		if var_52_1 then
			local var_52_3 = var_0_9 + arg_52_0.topBtnIndex * var_0_10

			arg_52_0:nodeByName("walfare"):setPositionX(var_52_3)

			arg_52_0.topBtnIndex = arg_52_0.topBtnIndex + 1

			arg_52_0:nodeByName("walfare"):addTouchEventListener(function(arg_53_0, arg_53_1)
				xyd.buttonScaleAnim(arg_53_0, arg_53_1)

				if arg_53_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()
					xyd.WindowManager.get():openWindow("walfare_activities")
				end
			end)
			arg_52_0.activities:refreshWalfareRedMark()
		end
	end
end

function var_0_0.updateBattlePassOpen(arg_54_0)
	local var_54_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.BATTLE_PASS)

	arg_54_0.battlePassIsOpen = var_54_0:isOpen()

	if arg_54_0.battlePassIsOpen then
		arg_54_0:refreshBattlePassRedMark()
	else
		arg_54_0:nodeByName("btn_battle_pass"):setBright(false)
	end

	local var_54_1 = var_0_9 + arg_54_0.topBtnIndex * var_0_10

	arg_54_0:nodeByName("btn_battle_pass"):setPositionX(var_54_1)

	arg_54_0.topBtnIndex = arg_54_0.topBtnIndex + 1

	arg_54_0:nodeByName("btn_battle_pass"):addTouchEventListener(function(arg_55_0, arg_55_1)
		xyd.buttonScaleAnim(arg_55_0, arg_55_1)

		if arg_55_1 == ccui.TouchEventType.ended then
			if not arg_54_0.battlePassIsOpen then
				local var_55_0 = var_0_4:translation("BATTLE_PASS_TEXT_27")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_55_0
				})

				return
			end

			if not var_54_0:isFuncOpen() then
				local var_55_1 = xyd.tables.functionOpen:tip(xyd.FunctionID.ID_BATTLE_PASS)

				if var_55_1 == "" then
					var_55_1 = var_0_4:translation("FUNCTION_OPEN_TIP_OTHER")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_55_1
				})

				return
			end

			var_54_0:loadInfo(function(arg_56_0, arg_56_1)
				if arg_56_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("battle_pass_main")
				end
			end)
		end
	end)
end

function var_0_0.updateBattlePassRedMark(arg_57_0)
	if xyd.ModelManager.get():loadModel(xyd.ModelType.REDMARK):isRedmark(xyd.FunctionID.ID_BATTLE_PASS, xyd.redmark.BATTLE_PASS_LEVEL_UP) then
		arg_57_0:nodeByName("btn_battle_pass"):getChildByName("notif"):setVisible(true)
	else
		arg_57_0:nodeByName("btn_battle_pass"):getChildByName("notif"):setVisible(false)
	end
end

function var_0_0.refreshBattlePassRedMark(arg_58_0)
	if xyd.ModelManager.get():loadModel(xyd.ModelType.BATTLE_PASS):isRedMarkShow() then
		arg_58_0:nodeByName("btn_battle_pass"):getChildByName("notif"):setVisible(true)
	else
		arg_58_0:nodeByName("btn_battle_pass"):getChildByName("notif"):setVisible(false)
	end
end

function var_0_0.refreshWalfareRedMark(arg_59_0)
	if arg_59_0.activities.walfareRedMark == true then
		arg_59_0:nodeByName("walfare_red_point"):setVisible(true)
	else
		arg_59_0:nodeByName("walfare_red_point"):setVisible(false)
	end
end

function var_0_0.updateNewServerPush(arg_60_0)
	local var_60_0 = arg_60_0:nodeByName("new_server_push")
	local var_60_1 = arg_60_0.activities:getActivityInfo(xyd.Activities.NewServerPush).details.lev_time + 259200 - xyd.ServerTime.get():getServerTime()
	local var_60_2 = var_0_9 + arg_60_0.topBtnIndex * var_0_10

	arg_60_0:nodeByName("new_server_push"):setPosition(var_60_2, 626)

	arg_60_0.topBtnIndex = arg_60_0.topBtnIndex + 1

	var_60_0:setVisible(true)
	var_60_0:setTouchEnabled(true)
	var_60_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_61_0)
		if arg_61_0.name == "began" then
			var_60_0:setScale(0.9)

			return true
		elseif arg_61_0.name == "ended" then
			var_60_0:setScale(1)
			arg_60_0.selfPlayer:queryChargeData(function()
				xyd.WindowManager.get():openWindow("new_push_window")
			end)
		end
	end)
	arg_60_0:nodeByName("server_push_time"):setString(xyd.secondsToString1(var_60_1))

	arg_60_0.newPushHandle = var_0_2.scheduleGlobal(function()
		var_60_1 = var_60_1 - 1

		if not tolua.isnull(arg_60_0) then
			arg_60_0:nodeByName("server_push_time"):setString(xyd.secondsToString1(var_60_1))
		end

		if var_60_1 < 0 then
			if not tolua.isnull(var_60_0) then
				var_60_0:setVisible(false)
			end

			if not tolua.isnull(arg_60_0) then
				var_0_2.unscheduleGlobal(arg_60_0.newPushHandle)
			end

			arg_60_0:updateTopBtn()
		end
	end, 1)
end

function var_0_0.updateGiftPush(arg_64_0)
	local var_64_0 = arg_64_0:nodeByName("gift_push")
	local var_64_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH)
	local var_64_2 = var_64_1:getGiftInfo()

	if #var_64_2 > 0 then
		local var_64_3 = var_0_9 + arg_64_0.topBtnIndex * var_0_10

		var_64_0:setPositionX(var_64_3)

		arg_64_0.topBtnIndex = arg_64_0.topBtnIndex + 1

		var_64_0:setVisible(true)
		var_64_0:setTouchEnabled(true)
		var_64_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_65_0)
			if arg_65_0.name == "began" then
				var_64_0:setScale(0.9)

				return true
			elseif arg_65_0.name == "ended" then
				var_64_0:setScale(1)
				arg_64_0.selfPlayer:queryChargeData(function()
					xyd.WindowManager.get():openWindow("gift_push")
				end)
			end
		end)

		if arg_64_0.giftTimeHandle then
			var_0_2.unscheduleGlobal(arg_64_0.giftTimeHandle)
		end

		local var_64_4 = var_64_2[1].push_time + xyd.tables.giftPush:time(var_64_2[1].gift_id) - xyd.ServerTime.get():getServerTime()

		arg_64_0:nodeByName("gift_push_time"):setString(xyd.secondsToString1(var_64_4))

		arg_64_0.giftTimeHandle = var_0_2.scheduleGlobal(function()
			var_64_4 = var_64_4 - 1

			if not tolua.isnull(arg_64_0) then
				arg_64_0:nodeByName("gift_push_time"):setString(xyd.secondsToString1(var_64_4))
			end

			if var_64_4 < 0 then
				if not tolua.isnull(var_64_0) then
					var_64_0:setVisible(false)
				end

				if not tolua.isnull(arg_64_0) then
					var_0_2.unscheduleGlobal(arg_64_0.giftTimeHandle)
				end

				var_64_1:removeGift(var_64_2[1].gift_id)
				arg_64_0:updateTopBtn()
			end
		end, 1)
	else
		var_64_0:setVisible(false)
	end
end

function var_0_0.functionClickRecord(arg_68_0, arg_68_1)
	arg_68_0.selfPlayer:sendFunctionClick(arg_68_1)
end

function var_0_0.updateAchievementRedMark(arg_69_0, arg_69_1)
	if arg_69_1 or arg_69_0.achievement:getCanAwardLev() > 0 then
		arg_69_0:nodeByName("achievement_notif"):setVisible(true)
	else
		arg_69_0:nodeByName("achievement_notif"):setVisible(false)
	end
end

function var_0_0.setBgVisible(arg_70_0, arg_70_1)
	if arg_70_0 and not tolua.isnull(arg_70_0) then
		arg_70_0:nodeByName("left_container"):setVisible(not arg_70_1)
		arg_70_0:nodeByName("player_container"):setVisible(not arg_70_1)
		arg_70_0:nodeByName("extra_container"):setVisible(not arg_70_1)

		if arg_70_0.activities:isActivityOpen(xyd.Activities.NEW_MONTH_CARD) then
			arg_70_0:nodeByName("panel_month_card"):setVisible(not arg_70_1)
		end
	end

	local var_70_0 = xyd.WindowManager.get():getWindow("main_scene_middle")

	if var_70_0 then
		var_70_0:setVisible(not arg_70_1)
	end

	local var_70_1 = xyd.WindowManager.get():getWindow("main_scene_left")

	if var_70_1 and not tolua.isnull(var_70_1) then
		if not arg_70_1 and not var_70_1:isVisible() then
			var_70_1:random()
		end

		var_70_1:setVisible(not arg_70_1)
	end
end

function var_0_0.willClose(arg_71_0)
	if arg_71_0.energyCounter_ then
		arg_71_0.energyCounter_:stop()
	end

	if arg_71_0.invitationCounter_ then
		arg_71_0.invitationCounter_:stop()
	end

	if arg_71_0.expCounter_ then
		arg_71_0.expCounter_:stop()
	end

	if arg_71_0.giftTimeHandle then
		var_0_2.unscheduleGlobal(arg_71_0.giftTimeHandle)
	end

	if arg_71_0.newPushHandle then
		var_0_2.unscheduleGlobal(arg_71_0.newPushHandle)
	end

	if arg_71_0.handle_ then
		var_0_2.unscheduleGlobal(arg_71_0.handle_)
	end

	if arg_71_0.broadcastEndHandler_ then
		var_0_2.unscheduleGlobal(arg_71_0.broadcastEndHandler_)
	end

	if arg_71_0.broadcastShowHandler_ then
		var_0_2.unscheduleGlobal(arg_71_0.broadcastShowHandler_)
	end

	if arg_71_0.actMoveHandle then
		var_0_2.unscheduleGlobal(arg_71_0.actMoveHandle)
	end
end

function var_0_0.onUpdateEnergyTimer(arg_72_0)
	local var_72_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_72_0.handle_ = var_0_2.scheduleGlobal(function()
		if xyd.ServerTime.get() and xyd.ServerTime.get():getServerTime() and (xyd.ServerTime.get():getServerTime() % 300 == 1 or xyd.ServerTime.get():getServerTime() % 300 == 0) and not arg_72_0.showBird then
			arg_72_0:birdEffect(math.random(1, 4) > 2, math.random(1, 4) > 2)
		end
	end, 2)
end

function var_0_0.snowmaneffect(arg_74_0)
	arg_74_0.showSnowman = true

	local var_74_0 = xyd.HeroAnimation.new(nil, 12001030, 0.6, {})
	local var_74_1 = false
	local var_74_2
	local var_74_3 = math.random(1, 2)
	local var_74_4 = xyd.WindowManager.get():getWindow("main_scene_bottom")

	if not var_74_4 or tolua.isnull(var_74_4) then
		return
	end

	var_74_4:nodeByName("snow_man"):removeAllChildren()

	local var_74_5 = var_74_4:nodeByName("snow_man")

	if var_74_3 then
		var_74_0:addTo(var_74_5)
		var_74_0:look(false, function()
			var_74_0:idle()
		end)

		local var_74_6 = "skeletons/ui_effect/star_treasure_effect/yun"
		local var_74_7 = var_74_6 .. ".json"
		local var_74_8 = var_74_6 .. ".atlas"
		local var_74_9 = var_0_6.new(var_74_7, var_74_8, 1)

		var_74_9:setAnchorPoint(cc.p(0.5, 0.5))
		var_74_9:addTo(var_74_5)
		var_74_9:setName("yun")
		var_74_9:setPosition(0, 10)
		var_74_9:play(function()
			return
		end, false)

		local var_74_10 = display.newNode()

		var_74_10:addTo(var_74_5)
		var_74_10:setAnchorPoint(0.5, 0)
		var_74_10:setPosition(0, 0)
		var_74_10:setContentSize(50, 50)
		var_74_10:setTouchEnabled(true)
		var_74_10:setTouchSwallowEnabled(true)
		var_74_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_77_0)
			if arg_77_0.name == "began" then
				return true
			elseif arg_77_0.name == "moved" then
				-- block empty
			elseif arg_77_0.name == "ended" and not var_74_1 then
				var_74_1 = true

				var_74_0:win()
				var_74_5:runActionOnce(cc.Sequence:create({
					cc.DelayTime:create(1.5),
					cc.CallFunc:create(function()
						xyd.Backend.get():request(xyd.mid.CLICK_CRAB, nil, function(arg_79_0, arg_79_1)
							if arg_79_0 == xyd.error.OK then
								arg_74_0.selfPlayer:handleRewards(arg_79_1.awards)
							else
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_4:translation("PANGXIE_CLICK_NOTHING")
								})
							end
						end)
						var_74_0:setVisible(false)
					end),
					cc.CallFunc:create(function()
						var_74_4:nodeByName("snow_man"):removeAllChildren()

						arg_74_0.showSnowman = false
					end)
				}))
			end
		end)
	end
end

function var_0_0.birdEffect(arg_81_0, arg_81_1, arg_81_2)
	arg_81_0.showBird = true

	local var_81_0 = math.random(300, 1200)
	local var_81_1 = arg_81_2 and 1280 or 0
	local var_81_2 = 70
	local var_81_3 = xyd.HeroAnimation.new(nil, 12001028, 0.4, {})

	if arg_81_2 then
		var_81_3:setScaleX(-1)
	end

	local var_81_4 = false
	local var_81_5
	local var_81_6 = math.random(1, 2)

	arg_81_0:nodeByName("bird"):removeAllChildren()

	local var_81_7 = arg_81_0:nodeByName("bird")

	var_81_7:setPosition(var_81_1, 540)
	var_81_7:setVisible(true)

	if var_81_6 then
		var_81_3:addTo(var_81_7)
		var_81_3:idle()

		local var_81_8 = cc.p(1280 - var_81_1, var_81_7:getPositionY())
		local var_81_9 = cc.Sequence:create({
			cc.MoveTo:create(math.abs(var_81_1 - 925) / 100, cc.p(925, 42)),
			cc.Spawn:create({
				cc.DelayTime:create(5.6),
				cc.CallFunc:create(function()
					var_81_3:win()
				end)
			})
		})
		local var_81_10 = cc.Sequence:create({
			cc.CallFunc:create(function()
				var_81_3:idle()
			end),
			cc.MoveTo:create(math.abs((arg_81_1 and 925 or var_81_1) - (1280 - var_81_1)) / var_81_2, var_81_8),
			cc.CallFunc:create(function()
				var_81_7:stopAllActions()
				var_81_7:removeAllChildren()

				arg_81_0.showBird = false
			end)
		})
		local var_81_11 = {}

		for iter_81_0 = 1, 30 do
			table.insert(var_81_11, cc.MoveBy:create(0.3, cc.p(0, math.random(-1, 1) * 7)))
		end

		local var_81_12 = cc.Sequence:create(var_81_11)
		local var_81_13

		if arg_81_1 then
			var_81_13 = cc.Sequence:create({
				var_81_9,
				cc.Spawn:create({
					var_81_10,
					var_81_12
				})
			})
		else
			var_81_13 = cc.Spawn:create({
				var_81_10,
				var_81_12
			})
		end

		var_81_7:runActionOnce(var_81_13)

		local var_81_14 = display.newNode()

		var_81_14:addTo(var_81_7, 10000000)
		var_81_14:setAnchorPoint(0.5, 0)
		var_81_14:setPosition(0, 0)
		var_81_14:setContentSize(50, 50)
		var_81_14:setTouchEnabled(true)
		var_81_14:setTouchSwallowEnabled(true)
		var_81_14:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_85_0)
			if arg_85_0.name == "began" then
				return true
			elseif arg_85_0.name == "moved" then
				-- block empty
			elseif arg_85_0.name == "ended" and not var_81_4 then
				var_81_4 = true

				var_81_7:runActionOnce(cc.Sequence:create({
					cc.Spawn:create({
						cc.CallFunc:create(function()
							var_81_3:idle()
						end),
						cc.DelayTime:create(1),
						cc.MoveBy:create(1, cc.p(-50 * (arg_81_2 and 1 or -1), 170))
					}),
					cc.CallFunc:create(function()
						var_81_7:stopAllActions()
						var_81_3:setVisible(false)
						var_81_7:removeAllChildren()

						arg_81_0.showBird = false

						xyd.Backend.get():request(xyd.mid.CLICK_CRAB, nil, function(arg_88_0, arg_88_1)
							if arg_88_0 == xyd.error.OK then
								arg_81_0.selfPlayer:handleRewards(arg_88_1.awards)
							else
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_4:translation("PANGXIE_CLICK_NOTHING")
								})
							end
						end)
					end)
				}))
			end
		end)
	end
end

function var_0_0.pangxieeffect(arg_89_0)
	local var_89_0 = xyd.HeroAnimation.new(nil, 12001018, 0.3, {})
	local var_89_1 = math.random(300, 1200)
	local var_89_2 = false
	local var_89_3
	local var_89_4 = math.random(1, 2)
	local var_89_5 = 150
	local var_89_6 = xyd.WindowManager.get():getWindow("main_scene_bottom")

	if not var_89_6 or tolua.isnull(var_89_6) then
		return
	end

	var_89_6:nodeByName("pangxie"):removeAllChildren()

	local var_89_7 = display.newNode()

	var_89_7:setPositionY(20)
	var_89_7:addTo(var_89_6:nodeByName("pangxie"))
	var_89_6:nodeByName("pangxie"):setContentSize(50, 50)
	var_89_6:nodeByName("pangxie"):setAnchorPoint(0.5, 0.5)

	local var_89_8 = 0

	if var_89_4 then
		var_89_6:nodeByName("pangxie"):setVisible(true)
		var_89_7:setContentSize(50, 50)
		var_89_7:setAnchorPoint(0.5, 0.5)
		var_89_0:walk(true, nil)
		var_89_0:setPosition(25, 0)
		var_89_0:addTo(var_89_7)

		local var_89_9 = cc.p(var_89_8 - var_89_1, var_89_7:getPositionY())
		local var_89_10 = cc.p(var_89_8, var_89_7:getPositionY())
		local var_89_11 = cc.Sequence:create({
			cc.MoveTo:create(var_89_1 / var_89_5, var_89_9),
			cc.CallFunc:create(function()
				var_89_0:idle()
			end),
			cc.DelayTime:create(3),
			cc.CallFunc:create(function()
				var_89_0:walk(true, nil)
			end),
			cc.MoveTo:create(var_89_1 / var_89_5, var_89_10),
			cc.CallFunc:create(function()
				var_89_7:setVisible(false)
				var_89_7:setPositionX(var_89_8)
				var_89_6:nodeByName("pangxie"):removeAllChildren()
			end)
		})

		var_89_7:runActionOnce(var_89_11)

		local var_89_12 = display.newNode()

		var_89_12:addTo(var_89_7)
		var_89_12:setContentSize(50, 50)
		var_89_12:setTouchEnabled(true)
		var_89_12:setTouchSwallowEnabled(true)
		var_89_12:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_93_0)
			if arg_93_0.name == "began" then
				return true
			elseif arg_93_0.name == "moved" then
				-- block empty
			elseif arg_93_0.name == "ended" then
				if var_89_2 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_4:translation("PANGXIE_CLICK_NOTHING")
					})
				else
					var_89_2 = true

					var_89_7:stopAllActions()
					var_89_0:win()
					var_89_7:runActionOnce(cc.Sequence:create({
						cc.DelayTime:create(2),
						cc.CallFunc:create(function()
							xyd.Backend.get():request(xyd.mid.CLICK_CRAB, nil, function(arg_95_0, arg_95_1)
								if arg_95_0 == xyd.error.OK then
									arg_89_0.selfPlayer:handleRewards(arg_95_1.awards)
								else
									xyd.WindowManager.get():openWindow("toast", {
										message = var_0_4:translation("PANGXIE_CLICK_NOTHING")
									})
								end
							end)
							var_89_0:walk(true, nil)
						end),
						cc.MoveTo:create((var_89_8 - var_89_7:getPositionX()) / var_89_5, var_89_10),
						cc.CallFunc:create(function()
							var_89_6:nodeByName("pangxie"):setVisible(false)
							var_89_6:nodeByName("pangxie"):removeAllChildren()
						end)
					}))
				end
			end
		end)
	end
end

function var_0_0.playFunctionGuide(arg_97_0, arg_97_1)
	local var_97_0
	local var_97_1 = 30
	local var_97_2 = -60
	local var_97_3 = 0
	local var_97_4 = 0
	local var_97_5 = var_0_4:translation("OPEN_FUNCTION")

	if arg_97_1 == xyd.FunctionID.ID_GOLD_HAND then
		var_97_0 = "coin_btn"
		var_97_1 = -150
		var_97_2 = -30
		var_97_3 = -30
		var_97_4 = 80
		var_97_5 = var_97_5 .. var_0_4:translation("GOLD_HAND_TXT")
	elseif arg_97_1 == xyd.FunctionID.ID_SHOP or arg_97_1 == xyd.FunctionID.ID_GNOME_SHOP or arg_97_1 == xyd.FunctionID.ID_BLACK_SHOP or arg_97_1 == xyd.FunctionID.ID_TMP_GNOME_SHOP or arg_97_1 == xyd.FunctionID.ID_TMP_BLACK_SHOP or arg_97_1 == xyd.FunctionID.ID_TMP_SPACE or arg_97_1 == xyd.FunctionID.ID_AUCTION or arg_97_1 == xyd.FunctionID.ID_SPACE then
		var_97_0 = "btn_shop"
		var_97_1 = 70
		var_97_2 = -10
		var_97_3 = 30
		var_97_4 = 40

		if arg_97_1 == xyd.FunctionID.ID_SHOP then
			var_97_5 = var_97_5 .. var_0_4:translation("ZAHUOPU_TXT")
		end

		if arg_97_1 == xyd.FunctionID.ID_GNOME_SHOP then
			var_97_5 = var_97_5 .. var_0_4:translation("VIP_GNOME_SHOP_TXT")
		end

		if arg_97_1 == xyd.FunctionID.ID_BLACK_SHOP then
			var_97_5 = var_97_5 .. var_0_4:translation("VIP_BLACK_SHOP_TXT")
		end

		if arg_97_1 == xyd.FunctionID.ID_SPACE then
			var_97_5 = var_97_5 .. var_0_4:translation("VIP_SPACE_SHOP_TXT")
		end

		if arg_97_1 == xyd.FunctionID.ID_TMP_GNOME_SHOP then
			var_97_5 = var_0_4:translation("TMP_GNOME_SHOP_TXT")
		end

		if arg_97_1 == xyd.FunctionID.ID_TMP_BLACK_SHOP then
			var_97_5 = var_0_4:translation("TMP_BLACK_SHOP_TXT")
		end

		if arg_97_1 == xyd.FunctionID.ID_TMP_SPACE then
			var_97_5 = var_0_4:translation("TMP_SPACE_SHOP_TXT")
		end

		if arg_97_1 == xyd.FunctionID.ID_AUCTION then
			var_97_5 = var_97_5 .. var_0_4:translation("TMP_AUCTION_TXT")
		end
	elseif arg_97_1 == xyd.FunctionID.ID_INDIEGOGO then
		var_97_0 = "btn_friend"
		var_97_5 = var_97_5 .. var_0_4:translation("INDIEGOGO_OPEN")
		var_97_1 = 70
		var_97_2 = -10
		var_97_3 = 30
		var_97_4 = 40
	elseif arg_97_1 == xyd.FunctionID.ID_MY_CLASS then
		var_97_0 = "btn_friend"
		var_97_5 = var_97_5 .. var_0_4:translation("MY_CLASS_OPEN")
		var_97_1 = 70
		var_97_2 = -10
		var_97_3 = 30
		var_97_4 = 40
		arg_97_0.goToClass = true
	end

	if var_97_0 then
		local var_97_6
		local var_97_7
		local var_97_8
		local var_97_9

		if var_97_0 == "coin_btn" then
			local var_97_10 = arg_97_0:nodeByName("eco_bar_pos")
			local var_97_11 = arg_97_0:nodeByName("eco_sidebar"):nodeByName("coin_btn")

			var_97_9 = var_97_10:getPositionX() + var_97_11:getPositionX()
			var_97_8 = var_97_10:getPositionY() + var_97_11:getPositionY()
		else
			local var_97_12 = arg_97_0:nodeByName(var_97_0)
			local var_97_13 = arg_97_0:nodeByName("left_container")

			var_97_9 = var_97_13:getPositionX() + var_97_12:getPositionX() + 65
			var_97_8 = var_97_13:getPositionY() + var_97_12:getPositionY() + 12
		end

		local var_97_14 = display.newNode()

		var_97_14:setPosition(var_97_9, var_97_8)

		local var_97_15 = import("app.windows.GuideHand").new()

		var_97_14:addChild(var_97_15)
		var_97_15:setPosition(0, 0)

		local var_97_16 = xyd.AssetLoader.get():loadNodeFromJson("windows/function/function_open2.csb")

		var_97_14:addChild(var_97_16)
		var_97_16:setPosition(var_97_1, var_97_2)
		var_97_16:getChildByName("tip_container"):getChildByName("text_open"):setString(var_97_5)

		local var_97_17 = var_97_16:getChildByName("tip_container"):getChildByName("tip_arrow")

		if var_97_4 ~= 0 then
			local var_97_18 = cc.p(var_97_17:getPosition())

			var_97_17:setPosition(cc.p(var_97_18.x + var_97_4, var_97_18.y))
		end

		if var_97_3 ~= 0 then
			var_97_17:setSkewY(var_97_3)
		end

		if arg_97_0.GuideHands[var_97_0] == nil then
			arg_97_0:addChild(var_97_14)

			arg_97_0.GuideHands[var_97_0] = {
				nodes = {
					var_97_14
				},
				funcIDs = {
					arg_97_1
				}
			}
		else
			table.insert(arg_97_0.GuideHands[var_97_0].nodes, var_97_14)
			table.insert(arg_97_0.GuideHands[var_97_0].funcIDs, arg_97_1)
		end
	end
end

function var_0_0.removeGuideHand(arg_98_0, arg_98_1)
	local var_98_0 = arg_98_0.GuideHands[arg_98_1]

	if var_98_0 ~= nil then
		if var_98_0.nodes and next(var_98_0.nodes) then
			for iter_98_0, iter_98_1 in pairs(var_98_0.nodes) do
				arg_98_0:removeChild(iter_98_1)
			end
		end

		newFuncIDs = var_98_0.funcIDs

		if var_98_0.funcIDs and next(var_98_0.funcIDs) then
			for iter_98_2, iter_98_3 in pairs(var_98_0.funcIDs) do
				xyd.StoryData.get():removeFuncID(iter_98_3)
			end
		end

		arg_98_0.GuideHands[arg_98_1] = nil
	end
end

function var_0_0.playGuide(arg_99_0)
	local var_99_0 = xyd.StoryData.get():getGuideID()

	if var_99_0 >= xyd.GuideStoryType.GUIDE_LEVUP_THREE and var_99_0 < xyd.GuideStoryType.ACTIVITY_SIX then
		if arg_99_0.selfPlayer.lev >= 10 then
			if xyd.WindowManager.get():isWindowOpen("guide") then
				xyd.WindowManager.get():closeWindow("guide")
			end

			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_END, true)
			xyd.StoryData.get():persist()

			return
		else
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_THREE, true)
			xyd.StoryData.get():persist()
		end

		local var_99_1 = arg_99_0.actBtn
		local var_99_2 = {
			280,
			230
		}
		local var_99_3, var_99_4 = var_99_1:getPosition()
		local var_99_5 = var_99_1:getContentSize()

		xyd.WindowManager.get():openWindow("guide")

		local var_99_6 = xyd.WindowManager.get():getWindow("guide")

		var_99_6:addNode()
		var_99_6:setStencil(var_99_5.width, var_99_5.height + 50, 69, 535, 0, {
			main_scene = true,
			position = {
				700,
				200
			}
		})
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_FOUR, true)
	end
end

function var_0_0.showBroadcast(arg_100_0, arg_100_1)
	local var_100_0 = false
	local var_100_1 = 1

	if arg_100_1.msg_type == nil or arg_100_1.msg_type == 2 then
		if arg_100_1.cd and arg_100_1.cd == 0 then
			var_100_0 = false
		else
			var_100_0 = true
		end
	else
		var_100_1 = arg_100_1.msg_type == 3 and 1 or xyd.tables.misc.superAnnounceTimes
	end

	if not arg_100_0.broadcastEndHandler_ or var_100_0 == false then
		local var_100_2 = xyd.WindowManager.get():getWindow("broadcast_window")
		local var_100_3 = {
			text = arg_100_1.msg
		}

		if not var_100_2 then
			xyd.WindowManager.get():openWindow("broadcast_window", var_100_3)
		else
			var_100_2:updateText(var_100_3)
		end

		if arg_100_0.broadcastShowHandler_ then
			var_0_2.unscheduleGlobal(arg_100_0.broadcastShowHandler_)

			arg_100_0.broadcastShowHandler_ = nil
		end

		if not arg_100_0 or tolua.isnull(arg_100_0) then
			if arg_100_0.broadcastEndHandler_ then
				var_0_2.unscheduleGlobal(arg_100_0.broadcastEndHandler_)

				arg_100_0.broadcastEndHandler_ = nil
			end

			return
		end

		if not var_100_0 and arg_100_0.broadcastEndHandler_ then
			var_0_2.unscheduleGlobal(arg_100_0.broadcastEndHandler_)

			arg_100_0.broadcastEndHandler_ = nil
		end

		arg_100_0.broadcastEndHandler_ = var_0_2.scheduleGlobal(function()
			if not arg_100_0 or tolua.isnull(arg_100_0) then
				if arg_100_0.broadcastEndHandler_ then
					var_0_2.unscheduleGlobal(arg_100_0.broadcastEndHandler_)

					arg_100_0.broadcastEndHandler_ = nil
				end

				return
			end

			var_0_2.unscheduleGlobal(arg_100_0.broadcastEndHandler_)

			arg_100_0.broadcastEndHandler_ = nil
		end, xyd.tables.misc.announceScreenTime)
		arg_100_0.broadcastShowHandler_ = var_0_2.performWithDelayGlobal(function()
			if not arg_100_0 or tolua.isnull(arg_100_0) then
				if arg_100_0.broadcastShowHandler_ then
					var_0_2.unscheduleGlobal(arg_100_0.broadcastShowHandler_)

					arg_100_0.broadcastShowHandler_ = nil
				end

				return
			end

			xyd.WindowManager.get():closeWindow("broadcast_window")

			arg_100_0.broadcastShowHandler_ = nil
		end, xyd.tables.misc.announceLastTime * var_100_1)
	end
end

function var_0_0.showEnvelopeRedMark(arg_103_0, arg_103_1)
	if arg_103_0.redEnvelopeMark and not tolua.isnull(arg_103_0.redEnvelopeMark) then
		arg_103_0.redEnvelopeMark:setVisible(arg_103_1)
	end
end

function var_0_0.showPacketRedMark(arg_104_0, arg_104_1)
	if arg_104_0.luckyPacketMark and not tolua.isnull(arg_104_0.luckyPacketMark) then
		arg_104_0.luckyPacketMark:setVisible(arg_104_1)
	end
end

function var_0_0.showKiteRedMark(arg_105_0, arg_105_1)
	if arg_105_0.kiteMark and not tolua.isnull(arg_105_0.kiteMark) then
		arg_105_0.kiteMark:setVisible(arg_105_1)
	end
end

function var_0_0.showJigsawRedMark(arg_106_0, arg_106_1)
	if arg_106_0.jigsawBtnMark and not tolua.isnull(arg_106_0.jigsawBtnMark) then
		arg_106_0.jigsawBtnMark:setVisible(arg_106_1)
	end
end

function var_0_0.showJigsaw2RedMark(arg_107_0, arg_107_1)
	if arg_107_0.jigsaw2BtnMark and not tolua.isnull(arg_107_0.jigsaw2BtnMark) then
		arg_107_0.jigsaw2BtnMark:setVisible(arg_107_1)
	end
end

function var_0_0.showSingleDayRedMark(arg_108_0, arg_108_1)
	if arg_108_0.singleDayBtnMark and not tolua.isnull(arg_108_0.singleDayBtnMark) then
		arg_108_0.singleDayBtnMark:setVisible(arg_108_1)
	end
end

function var_0_0.showStarTreasureMark(arg_109_0, arg_109_1)
	if arg_109_0.starTreasureMark and not tolua.isnull(arg_109_0.starTreasureMark) then
		arg_109_0.starTreasureMark:setVisible(arg_109_1)
	end
end

function var_0_0.checkMonthCardShow(arg_110_0)
	local var_110_0 = xyd.tables.monthlyPrivilege:iconDisplay(1)

	if not arg_110_0.activities:isActivityOpen(xyd.Activities.NEW_MONTH_CARD) and var_110_0 == 0 then
		arg_110_0:nodeByName("panel_month_card"):setVisible(false)

		return
	end

	if var_110_0 == 2 then
		arg_110_0.monthBtn = arg_110_0:nodeByName("month_green")

		arg_110_0:nodeByName("month_green"):setVisible(true)
		arg_110_0:nodeByName("month_blue"):setVisible(false)
		arg_110_0:nodeByName("month"):setVisible(false)
		arg_110_0:nodeByName("month_gray"):setVisible(false)
	elseif var_110_0 == 1 then
		arg_110_0:nodeByName("month_green"):setVisible(false)
		arg_110_0:nodeByName("month_blue"):setVisible(false)
		arg_110_0:nodeByName("month"):setVisible(false)

		if arg_110_0.selfPlayer.leftCardDay > 0 or arg_110_0.selfPlayer.leftEnergyMonthCardDay > 0 then
			arg_110_0.monthBtn = arg_110_0:nodeByName("month")

			arg_110_0:nodeByName("month"):setVisible(true)
			arg_110_0:nodeByName("month_gray"):setVisible(false)

			if arg_110_0.selfPlayer.leftCardDay > 0 and arg_110_0.selfPlayer.leftEnergyMonthCardDay > 0 then
				arg_110_0:nodeByName("month"):setVisible(false)
				arg_110_0:nodeByName("month_gray"):setVisible(false)
				arg_110_0:nodeByName("month_blue"):setVisible(true)

				arg_110_0.monthBtn = arg_110_0:nodeByName("month_blue")
			end
		elseif arg_110_0.selfPlayer.privilegeLeftCardDay > 0 then
			arg_110_0.monthBtn = arg_110_0:nodeByName("month_green")

			arg_110_0:nodeByName("month_green"):setVisible(true)
			arg_110_0:nodeByName("month_gray"):setVisible(false)
		else
			arg_110_0:nodeByName("month"):setVisible(false)
			arg_110_0:nodeByName("month_gray"):setVisible(true)

			arg_110_0.monthBtn = arg_110_0:nodeByName("month_gray")
		end
	elseif var_110_0 == 0 then
		arg_110_0:nodeByName("month_green"):setVisible(false)
		arg_110_0:nodeByName("month_blue"):setVisible(false)

		if arg_110_0.selfPlayer.leftCardDay > 0 or arg_110_0.selfPlayer.leftEnergyMonthCardDay > 0 then
			arg_110_0.monthBtn = arg_110_0:nodeByName("month")

			arg_110_0:nodeByName("month"):setVisible(true)
			arg_110_0:nodeByName("month_gray"):setVisible(false)

			if arg_110_0.selfPlayer.leftCardDay > 0 and arg_110_0.selfPlayer.leftEnergyMonthCardDay > 0 then
				arg_110_0:nodeByName("month"):setVisible(false)
				arg_110_0:nodeByName("month_gray"):setVisible(false)
				arg_110_0:nodeByName("month_blue"):setVisible(true)

				arg_110_0.monthBtn = arg_110_0:nodeByName("month_blue")
			end
		else
			arg_110_0:nodeByName("month"):setVisible(false)
			arg_110_0:nodeByName("month_gray"):setVisible(true)

			arg_110_0.monthBtn = arg_110_0:nodeByName("month_gray")
		end
	elseif var_110_0 == 3 then
		arg_110_0:nodeByName("month_green"):setVisible(false)
		arg_110_0:nodeByName("month_blue"):setVisible(false)
		arg_110_0:nodeByName("month"):setVisible(false)
		arg_110_0:nodeByName("month_gray"):setVisible(false)

		if arg_110_0.selfPlayer.leftCardDay > 0 or arg_110_0.selfPlayer.leftEnergyMonthCardDay > 0 or arg_110_0.selfPlayer.leftWeekCardDay > 0 or arg_110_0.selfPlayer.privilegeLeftCardDay > 0 then
			arg_110_0:nodeByName("month"):setVisible(true)

			arg_110_0.monthBtn = arg_110_0:nodeByName("month")
		else
			arg_110_0:nodeByName("month_gray"):setVisible(true)

			arg_110_0.monthBtn = arg_110_0:nodeByName("month_gray")
		end
	end
end

function var_0_0.checkChargeBtnRedPoint(arg_111_0)
	arg_111_0.selfPlayer:queryChargeData(function(arg_112_0, arg_112_1)
		if arg_112_0 == xyd.error.OK then
			local var_112_0 = xyd.db.vipGiftData:isUpdated(arg_112_1)

			if arg_111_0.chargeBtn and var_112_0 then
				arg_111_0.chargeBtn:getChildByName("notif"):setVisible(true)
			end
		end
	end)
end

function var_0_0.playWindowMove(arg_113_0, arg_113_1)
	local var_113_0 = arg_113_0:nodeByName("left_container")
	local var_113_1 = arg_113_0:nodeByName("top_container")

	if arg_113_1 then
		arg_113_0.headPosition = cc.p(var_113_0:getPosition())
		arg_113_0.detailPosition = cc.p(var_113_1:getPosition())

		var_113_0:runAction(cc.MoveTo:create(0.5, cc.p(-xyd.STAGE_WIDTH, arg_113_0.headPosition.y)))
		var_113_1:runAction(cc.MoveTo:create(0.5, cc.p(arg_113_0.detailPosition.x, xyd.STAGE_HEIGHT)))
	else
		var_113_0:runAction(cc.MoveTo:create(0.5, cc.p(arg_113_0.headPosition.x, arg_113_0.headPosition.y)))
		var_113_1:runAction(cc.MoveTo:create(0.5, cc.p(arg_113_0.detailPosition.x, arg_113_0.detailPosition.y)))
	end
end

function var_0_0.isHasTiLiItem(arg_114_0)
	local var_114_0 = arg_114_0.selfPlayer:getBackpack():getItems()

	for iter_114_0, iter_114_1 in pairs(var_114_0) do
		if xyd.tables.item:subType(iter_114_1.itemID) == xyd.ConsumeItemType.ENERGY_ITEM then
			return true
		end
	end

	return false
end

function var_0_0.redEnvelopeSetup(arg_115_0, arg_115_1)
	arg_115_0.redEnvelopeBtn = arg_115_1
	arg_115_0.redEnvelopeMark = arg_115_0.redEnvelopeBtn:getChildByName("notif")

	arg_115_0.redEnvelopeBtn:setTouchEnabled(true)
	arg_115_0.redEnvelopeBtn:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_116_0)
		if arg_116_0.name == "began" then
			return true
		elseif arg_116_0.name == "ended" then
			if arg_115_0.scrollViewMoved_ then
				return
			end

			arg_115_0.redEnvelopeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.RED_ENVELOPE)

			arg_115_0.redEnvelopeModel:loadEnvelopeInfo(nil, function(arg_117_0)
				if arg_117_0 == xyd.error.OK then
					arg_115_0:showEnvelopeRedMark(false)
					xyd.WindowManager.get():openWindow("red_envelope")
				end
			end)
		end
	end)

	return arg_115_0.redEnvelopeBtn
end

function var_0_0.openServiceSetup(arg_118_0, arg_118_1)
	arg_118_0.openServiceBtn = arg_118_1
	arg_118_0.openServiceMark = arg_118_0.openServiceBtn:getChildByName("notif")

	arg_118_0.openServiceBtn:setTouchEnabled(true)

	local var_118_0 = "skeletons/ui_effect/kaifukuanghuan01/kaifukuanghuan01"
	local var_118_1 = var_118_0 .. ".json"
	local var_118_2 = var_118_0 .. ".atlas"

	arg_118_0.skillEffect = var_0_6.new(var_118_1, var_118_2, 1)

	arg_118_0.skillEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_118_0.skillEffect:setPosition(1, 1)
	arg_118_0.skillEffect:addTo(arg_118_0.openServiceBtn)
	arg_118_0.skillEffect:setPosition(61, 53)
	arg_118_0.skillEffect:play(nil, true)
	arg_118_0.skillEffect:setGlobalZOrder(0)
	arg_118_0.openServiceMark:setVisible(false)

	local var_118_3 = arg_118_0.activities:getActivityInfo(xyd.Activities.OpenService)

	if var_118_3 and var_118_3.details then
		for iter_118_0, iter_118_1 in pairs(var_118_3.details.done_ids) do
			if math.floor(tonumber(iter_118_1) / 1000) <= var_118_3.details.day_count then
				arg_118_0.openServiceMark:setVisible(true)

				break
			end
		end
	end

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_118_0):addEventListener(xyd.event.OPEN_SERVICE_ACTIVITY_NOTICE, handler(arg_118_0, arg_118_0.updateOpenServiceNotif))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_118_0):addEventListener(xyd.event.OPEN_SERVICE_ACTIVITY_NOTICE_CLOSE, handler(arg_118_0, arg_118_0.updateOpenServiceNotifClose))
	arg_118_0.openServiceBtn:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_119_0)
		if arg_119_0.name == "began" then
			arg_118_0.openServiceBtn:setScale(0.8)

			return true
		elseif arg_119_0.name == "ended" then
			arg_118_0.openServiceBtn:setScale(1)

			if arg_118_0.scrollViewMoved_ then
				return
			end

			arg_118_0.activities:loadSingleActivity({
				activity_id = xyd.Activities.OpenService
			}, function(arg_120_0, arg_120_1)
				if arg_120_0 == xyd.error.OK then
					if arg_120_1.is_open and arg_120_1.is_open == 0 then
						arg_118_0:updateButtonTable()
					else
						xyd.WindowManager.get():openWindow("open_service", {
							arg_120_1
						})
					end
				end
			end)
		end
	end)
end

function var_0_0.updateOpenServiceNotif(arg_121_0, arg_121_1)
	arg_121_0.openServiceMark:setVisible(true)
end

function var_0_0.updateOpenServiceNotifClose(arg_122_0, arg_122_1)
	arg_122_0.openServiceMark:setVisible(false)
end

function var_0_0.luckyPacketSetup(arg_123_0, arg_123_1)
	arg_123_0.luckyPacketModel = arg_123_0.luckyPacketModel or xyd.ModelManager.get():loadModel(xyd.ModelType.LUCKY_PACKET)
	arg_123_0.luckyPacketBtn = arg_123_1
	arg_123_0.luckyPacketMark = arg_123_0.luckyPacketBtn:getChildByName("notif")

	arg_123_0.luckyPacketBtn:setTouchEnabled(true)
	arg_123_0.luckyPacketBtn:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_124_0)
		if arg_124_0.name == "began" then
			arg_123_0.luckyPacketBtn:setScale(0.8)

			return true
		elseif arg_124_0.name == "ended" then
			arg_123_0.luckyPacketBtn:setScale(1)

			if arg_123_0.scrollViewMoved_ then
				return
			end

			arg_123_0.luckyPacketModel:loadPacketInfo(nil, function(arg_125_0)
				if arg_125_0 == xyd.error.OK then
					arg_123_0:showPacketRedMark(false)
					xyd.WindowManager.get():openWindow("lucky_packet")
				end
			end)
		end
	end)
end

function var_0_0.kiteSetup(arg_126_0, arg_126_1)
	arg_126_0.kiteBtn = arg_126_1
	arg_126_0.kiteMark = arg_126_0.kiteBtn:getChildByName("notif")

	arg_126_0.kiteBtn:setTouchEnabled(true)
	arg_126_0.kiteBtn:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_127_0)
		if arg_127_0.name == "began" then
			arg_126_0.kiteBtn:setScale(0.8)

			return true
		elseif arg_127_0.name == "ended" then
			arg_126_0.kiteBtn:setScale(1)

			if arg_126_0.scrollViewMoved_ then
				return
			end

			arg_126_0.kiteModel:loadKiteInfo(nil, function(arg_128_0)
				if arg_128_0 == xyd.error.OK then
					arg_126_0:showKiteRedMark(false)
					xyd.WindowManager.get():openWindow("kite")
				end
			end)
		end
	end)
end

function var_0_0.dragonBoatSetup(arg_129_0, arg_129_1)
	arg_129_0.dragonBoatBtn = arg_129_1
	arg_129_0.dragonBoatBtnMark = arg_129_0.dragonBoatBtn:getChildByName("notif")

	arg_129_0.dragonBoatBtn:setTouchEnabled(true)
	arg_129_0.dragonBoatBtn:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_130_0)
		if arg_130_0.name == "began" then
			arg_129_0.dragonBoatBtn:setScale(0.8)

			return true
		elseif arg_130_0.name == "ended" then
			arg_129_0.dragonBoatBtn:setScale(1)

			if arg_129_0.scrollViewMoved_ then
				return
			end

			xyd.ModelManager.get():loadModel(xyd.ModelType.DRAGON_BOAT):loadInfo(function()
				xyd.WindowManager.get():openWindow("dragon_boat_main")
			end)
		end
	end)
end

function var_0_0.beachSetup(arg_132_0, arg_132_1, arg_132_2)
	arg_132_0.beach = arg_132_0.beach or xyd.ModelManager.get():loadModel(xyd.ModelType.BEACH_ACTIVITY)
	arg_132_0.beachBtn = arg_132_1
	arg_132_0.beachMark = arg_132_0.beachBtn:getChildByName("notif")

	arg_132_0:commonActSetup(arg_132_1, {
		endTime = arg_132_0:getActEndTime(arg_132_2)
	}, function()
		arg_132_0.activities:loadSingleActivity({
			activity_id = arg_132_2
		}, function(arg_134_0, arg_134_1)
			if arg_134_0 == xyd.error.OK then
				local var_134_0 = arg_134_1.details

				var_134_0.end_time = arg_134_1.end_time

				arg_132_0.beach:setParams(var_134_0)

				local var_134_1 = arg_132_0.beach:getStartTimes()
				local var_134_2 = xyd.tables.misc.beachBuyGamePrice

				if arg_132_0.beach:isStart() then
					xyd.WindowManager.get():openWindow("beach_main_wnd")
				else
					xyd.WindowManager.get():openWindow("beach_enter_wnd")
				end
			end
		end)
	end)
end

function var_0_0.jigsawSetup(arg_135_0, arg_135_1, arg_135_2)
	arg_135_0.jigsaw = arg_135_0.jigsaw or xyd.ModelManager.get():loadModel(xyd.ModelType.JIGSAW)
	arg_135_0.jigsawBtn = arg_135_1
	arg_135_0.jigsawBtnMark = arg_135_0.jigsawBtn:getChildByName("notif")

	arg_135_0:commonActSetup(arg_135_1, {
		endTime = arg_135_0:getActEndTime(arg_135_2)
	}, function(arg_136_0)
		arg_135_0.jigsaw:loadInfo(function(arg_137_0, arg_137_1)
			if arg_137_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("jigsaw")
			end
		end)
	end)
end

function var_0_0.jigsaw2Setup(arg_138_0, arg_138_1, arg_138_2)
	arg_138_0.jigsaw2 = arg_138_0.jigsaw2 or xyd.ModelManager.get():loadModel(xyd.ModelType.JIGSAW2)
	arg_138_0.jigsaw2Btn = arg_138_1
	arg_138_0.jigsaw2BtnMark = arg_138_0.jigsaw2Btn:getChildByName("notif")

	arg_138_0:commonActSetup(arg_138_1, {
		endTime = arg_138_0:getActEndTime(arg_138_2)
	}, function(arg_139_0)
		arg_138_0.jigsaw2:loadInfo(function(arg_140_0, arg_140_1)
			if arg_140_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("jigsaw2")
			end
		end)
	end)
end

function var_0_0.dreamWorldSetup(arg_141_0, arg_141_1, arg_141_2)
	arg_141_0.dreamWorld = arg_141_0.dreamWorld or xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD)
	arg_141_0.dreamWorldBtn = arg_141_1

	arg_141_0.dreamWorldBtn:setTouchEnabled(true)
	arg_141_0:commonActSetup(arg_141_1, {
		endTime = arg_141_0:getActEndTime(arg_141_2)
	}, function(arg_142_0)
		arg_141_0.dreamWorld:loadInfo(function(arg_143_0, arg_143_1)
			if arg_143_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("dream_world_main")
			end
		end)
	end)
end

function var_0_0.starTreasureSetup(arg_144_0, arg_144_1, arg_144_2)
	arg_144_0.starTreasure = arg_144_0.starTreasure or xyd.ModelManager.get():loadModel(xyd.ModelType.STAR_TREASURE)
	arg_144_0.starTreasureBtn = arg_144_1
	arg_144_0.starTreasureMark = arg_144_0.starTreasureBtn:getChildByName("notif")

	arg_144_0:commonActSetup(arg_144_1, {
		endTime = arg_144_0:getActEndTime(arg_144_2)
	}, function(arg_145_0)
		local var_145_0 = arg_144_0.starTreasure:getFirstOpenFlag()

		arg_144_0.starTreasure:loadInfo(function(arg_146_0, arg_146_1)
			if arg_146_0 == xyd.error.OK then
				if var_145_0 == 1 then
					xyd.WindowManager.get():openWindow("star_treasure_start")
					arg_144_0.starTreasure:setFirstOpenFlag(0)
				else
					xyd.WindowManager.get():openWindow("star_treasure")
				end
			end
		end)
	end)
end

function var_0_0.fireworkSetup(arg_147_0, arg_147_1, arg_147_2)
	arg_147_0.fireworkBtn = arg_147_1
	arg_147_0.fireworkMark = arg_147_0.fireworkBtn:getChildByName("notif")

	arg_147_0:commonActSetup(arg_147_1, {
		endTime = arg_147_0:getActEndTime(arg_147_2)
	}, function(arg_148_0)
		arg_147_0.activities:loadActivities(function(arg_149_0)
			if arg_149_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("firework_main")
			end
		end)
	end)
end

function var_0_0.championsLeagueSetup(arg_150_0, arg_150_1, arg_150_2)
	arg_150_0.championsLeagueBtn = arg_150_1
	arg_150_0.championsLeagueMark = arg_150_0.championsLeagueBtn:getChildByName("notif")

	xyd.EventDispatcher.get():addEventListener(xyd.event.CHAMPIONS_CHECK_REDMARK, function(arg_151_0)
		if arg_150_0.championsLeagueMark and not tolua.isnull(arg_150_0.championsLeagueMark) then
			arg_150_0.championsLeagueMark:setVisible(true)
		end
	end)
	arg_150_0:commonActSetup(arg_150_0.championsLeagueBtn, {
		endTime = arg_150_0:getActEndTime(arg_150_2)
	}, function()
		xyd.ModelManager.get():loadModel(xyd.ModelType.CHAMPIONS_LEAGUE):loadInfo(function(arg_153_0, arg_153_1)
			if arg_153_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("champions_league", arg_153_1)
			end
		end)
	end)
end

function var_0_0.singleDaySetup(arg_154_0, arg_154_1, arg_154_2)
	arg_154_0.singleDayBtn = arg_154_1
	arg_154_0.singleDayBtnMark = arg_154_0.singleDayBtn:getChildByName("notif")
	arg_154_0.singleDay = xyd.ModelManager.get():loadModel(xyd.ModelType.SINGLE_DAY)

	arg_154_0:commonActSetup(arg_154_0.singleDayBtn, {
		endTime = arg_154_0:getActEndTime(arg_154_2)
	}, function()
		arg_154_0.singleDay:loadInfo({}, function(arg_156_0, arg_156_1)
			if arg_156_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("single_day")
			end
		end)
	end)
end

function var_0_0.lvbuFestivalSetup(arg_157_0, arg_157_1, arg_157_2)
	arg_157_0.lvbuFestivalBtn = arg_157_1
	arg_157_0.lvbuFestivalBtnMark = arg_157_0.lvbuFestivalBtn:getChildByName("notif")

	arg_157_0:commonActSetup(arg_157_0.lvbuFestivalBtn, {
		endTime = arg_157_0:getActEndTime(arg_157_2)
	}, function()
		arg_157_0.lvbuFestival = arg_157_0.lvbuFestival or xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL)

		arg_157_0.lvbuFestival:loadInfo({}, function(arg_159_0, arg_159_1)
			if arg_159_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("lvbu_entry")
			end
		end)
	end)
end

function var_0_0.vipBoxDrawSetup(arg_160_0, arg_160_1)
	arg_160_0.vipBoxDrawBtn = arg_160_1

	arg_160_0.vipBoxDrawBtn:setTouchEnabled(true)
	arg_160_0.vipBoxDrawBtn:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_161_0)
		if arg_161_0.name == "began" then
			arg_160_0.vipBoxDrawBtn:setScale(0.8)

			return true
		elseif arg_161_0.name == "ended" then
			arg_160_0.vipBoxDrawBtn:setScale(1)

			if arg_160_0.scrollViewMoved_ then
				return
			end

			local var_161_0 = {
				activity_id = xyd.Activities.VipBoxDraw
			}

			arg_160_0.activities:loadSingleActivity(var_161_0, function(arg_162_0, arg_162_1)
				if arg_162_0 == xyd.error.OK then
					if arg_162_1.is_open == 0 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_4:translation("ACTIVITY_FINISHED")
						})

						return
					end

					xyd.WindowManager.get():openWindow("vip_box_draw")
				end
			end)
		end
	end)
end

function var_0_0.sakura2Setup(arg_163_0, arg_163_1)
	arg_163_0.sakura2Btn = arg_163_1
	arg_163_0.sakura2BtnMark = arg_163_0.sakura2Btn:getChildByName("notif")

	arg_163_0.sakura2Btn:setTouchEnabled(true)
	arg_163_0.sakura2Btn:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_164_0)
		if arg_164_0.name == "began" then
			arg_163_0.sakura2Btn:setScale(0.8)

			return true
		elseif arg_164_0.name == "ended" then
			arg_163_0.sakura2Btn:setScale(1)

			if arg_163_0.scrollViewMoved_ then
				return
			end

			arg_163_0.sakura:loadInfo(function(arg_165_0, arg_165_1)
				if arg_165_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("sakura_main")
				end
			end)
		end
	end)
end

function var_0_0.dragonBoat2017Setup(arg_166_0, arg_166_1, arg_166_2)
	arg_166_0.dragonBoat2017Btn = arg_166_1
	arg_166_0.dragonBoat2017BtnMark = arg_166_0.dragonBoat2017Btn:getChildByName("notif")

	arg_166_0:commonActSetup(arg_166_1, {
		endTime = arg_166_0:getActEndTime(arg_166_2)
	}, function(arg_167_0)
		arg_166_0.dragonBoat2017 = arg_166_0.dragonBoat2017 or xyd.ModelManager.get():loadModel(xyd.ModelType.DRAGON_BOAT2017)

		arg_166_0.dragonBoat2017:loadInfo(function()
			xyd.WindowManager.get():openWindow("dragon_boat2017_main")
		end)
	end)
end

function var_0_0.zhangheBoxSetup(arg_169_0, arg_169_1, arg_169_2)
	arg_169_0.zhangheBoxBtn = arg_169_1

	arg_169_0:commonActSetup(arg_169_1, {
		endTime = arg_169_0:getActEndTime(arg_169_2)
	}, function(arg_170_0)
		local var_170_0 = {
			activity_id = xyd.Activities.ZhangheBox
		}

		arg_169_0.activities:loadSingleActivity(var_170_0, function(arg_171_0, arg_171_1)
			if arg_171_0 == xyd.error.OK then
				if arg_171_1.is_open == 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_4:translation("ACTIVITY_FINISHED")
					})

					return
				end

				local var_171_0 = {
					endTime = arg_171_1.end_time
				}

				xyd.WindowManager.get():openWindow("zhanghe_box", var_171_0)
			end
		end)
	end)
end

function var_0_0.zhugeFestivalSetup(arg_172_0, arg_172_1, arg_172_2)
	arg_172_0.zhugeBtn = arg_172_1

	if arg_172_0.activities:isZhugeActivityShow() == 2 then
		arg_172_0.zhugeBtn = xyd.SpriteLoader.new("images/main_act/1109_2.png", nil, nil, xyd.DefaultImageType.MAIN_ACT)
	end

	arg_172_0:commonActSetup(arg_172_0.zhugeBtn, {
		endTime = arg_172_0:getActEndTime(arg_172_2)
	}, function(arg_173_0)
		arg_172_0.zhugeModel = arg_172_0.zhugeModel or xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)

		arg_172_0.zhugeModel:loadInfo(function(arg_174_0, arg_174_1)
			if arg_174_0 == xyd.error.OK then
				if arg_172_0.zhugeModel:checkIsPass() then
					xyd.WindowManager.get():openWindow("zhuge_small_house")
				else
					xyd.WindowManager.get():openWindow("zhuge_main_wnd")
				end
			end
		end)
	end)

	return arg_172_0.zhugeBtn
end

function var_0_0.summerSetup(arg_175_0, arg_175_1, arg_175_2)
	arg_175_0.summer = arg_175_0.summer or xyd.ModelManager.get():loadModel(xyd.ModelType.SUMMER)
	arg_175_0.summerBtn = arg_175_1
	arg_175_0.summerBtnMark = arg_175_0.summerBtn:getChildByName("notif")

	if not arg_175_0.summer.activity then
		arg_175_0.summer:loadInfo(function(arg_176_0, arg_176_1)
			if arg_176_0 == xyd.error.OK and arg_175_0.summerBtn and not tolua.isnull(arg_175_0.summerBtn) then
				arg_175_0.summerBtn:setVisible(true)
				arg_175_0.summerBtnMark:setVisible(arg_175_0.summer:isSummerRedPointShow())
			end
		end)
	elseif arg_175_0.summerBtn and not tolua.isnull(arg_175_0.summerBtn) then
		arg_175_0.summerBtn:setVisible(true)
		arg_175_0.summerBtnMark:setVisible(arg_175_0.summer:isSummerRedPointShow())
	end

	arg_175_0:commonActSetup(arg_175_1, {
		endTime = arg_175_0:getActEndTime(arg_175_2)
	}, function(arg_177_0)
		arg_175_0.summer:loadInfo(function(arg_178_0, arg_178_1)
			if arg_178_0 == xyd.error.OK then
				if xyd.ServerTime.get():getServerTime() < arg_175_0.summer.activity.start_time then
					local var_178_0 = var_0_4:translation("ACTIVITY_UNRECHABLE")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_178_0
					})

					return
				elseif xyd.ServerTime.get():getServerTime() > arg_175_0.summer.activity.end_time then
					local var_178_1 = var_0_4:translation("ACTIVITY_FINISHED")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_178_1
					})

					return
				end

				xyd.WindowManager.get():openWindow("summer_main")

				if arg_175_0.summerBtnMark and not tolua.isnull(arg_175_0.summerBtnMark) then
					arg_175_0.summerBtnMark:setVisible(false)
				end
			end
		end)
	end)
end

function var_0_0.popularityContestSetup(arg_179_0, arg_179_1, arg_179_2)
	arg_179_0.popularityContest = arg_179_0.popularityContest or xyd.ModelManager.get():loadModel(xyd.ModelType.POPULARITY_CONTEST)
	arg_179_0.popularityContestBtn = arg_179_1

	arg_179_0:commonActSetup(arg_179_1, {
		endTime = arg_179_0:getActEndTime(arg_179_2)
	}, function(arg_180_0)
		arg_179_0.popularityContest:loadInfo(function(arg_181_0, arg_181_1)
			if arg_181_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("popularity_contest")
			end
		end)
	end)
end

function var_0_0.concentrateSetup(arg_182_0, arg_182_1)
	arg_182_0.concentrateBtn = arg_182_1

	arg_182_0.concentrateBtn:setTouchEnabled(true)
	arg_182_0.concentrateBtn:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_183_0)
		if arg_183_0.name == "began" then
			arg_182_0.concentrateBtn:setScale(0.8)

			return true
		elseif arg_183_0.name == "ended" then
			arg_182_0.concentrateBtn:setScale(1)

			if arg_182_0.scrollViewMoved_ then
				return
			end

			xyd.ModelManager.get():loadModel(xyd.ModelType.TWO_YEARS):loadInfo({}, function(arg_184_0, arg_184_1)
				if arg_184_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("two_years_main")
				end
			end)
		end
	end)
end

function var_0_0.newTermSetup(arg_185_0, arg_185_1, arg_185_2)
	arg_185_0.newTermBtn = arg_185_1

	arg_185_0:commonActSetup(arg_185_1, {
		endTime = arg_185_0:getActEndTime(arg_185_2)
	}, function()
		xyd.ModelManager.get():loadModel(xyd.ModelType.NEW_TERMS):loadInfo({}, function(arg_187_0, arg_187_1)
			if arg_187_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("new_term")
			end
		end)
	end)
end

function var_0_0.warCampSetup(arg_188_0, arg_188_1, arg_188_2)
	arg_188_0.warCampBtn = arg_188_1

	arg_188_0:commonActSetup(arg_188_1, {
		endTime = arg_188_0:getActEndTime(arg_188_2)
	}, function()
		xyd.ModelManager.get():loadModel(xyd.ModelType.WAR_CAMP):loadSingleActivity(function(arg_190_0, arg_190_1)
			if arg_190_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("war_camp_entrance")
			end
		end)
	end)
end

function var_0_0.snowBallSetup(arg_191_0, arg_191_1, arg_191_2)
	arg_191_0.snowBallBtn = arg_191_1

	arg_191_0:commonActSetup(arg_191_1, {
		endTime = arg_191_0:getActEndTime(arg_191_2)
	}, function(arg_192_0)
		xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_BALL):loadInfo(function(arg_193_0, arg_193_1)
			if arg_193_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("snow_ball")
			end
		end)
	end)
end

function var_0_0.snowActivitySetup(arg_194_0, arg_194_1, arg_194_2)
	arg_194_0.snowActivityBtn = arg_194_1

	arg_194_0:commonActSetup(arg_194_0.snowActivityBtn, {
		endTime = arg_194_0:getActEndTime(arg_194_2)
	}, function(arg_195_0)
		xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_ACTIVITY):loadSingleActivity(function(arg_196_0, arg_196_1)
			if arg_196_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("snow_main")
			end
		end)
	end)
end

function var_0_0.allNigntSetup(arg_197_0, arg_197_1, arg_197_2)
	arg_197_0.allNightBtn = arg_197_1

	arg_197_0:commonActSetup(arg_197_1, {
		endTime = arg_197_0:getActEndTime(arg_197_2)
	}, function()
		arg_197_0.activities:loadActivities(function(arg_199_0)
			if arg_199_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("activities", {
					default_table_id = 1199
				})
			end
		end)
	end)
end

function var_0_0.flappyBirdSetup(arg_200_0, arg_200_1, arg_200_2)
	arg_200_0.flappyBirdBtn = arg_200_1

	arg_200_0:commonActSetup(arg_200_1, {
		endTime = arg_200_0:getActEndTime(arg_200_2)
	}, function()
		xyd.ModelManager.get():loadModel(xyd.ModelType.FLAPPY_BIRD):getInfo(nil, function(arg_202_0, arg_202_1)
			if arg_202_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("flappy_bird_main")
			end
		end)
	end)
end

function var_0_0.ragnarokSetup(arg_203_0, arg_203_1, arg_203_2)
	arg_203_0.ragnarokBtn = arg_203_1

	arg_203_0:commonActSetup(arg_203_1, {
		endTime = arg_203_0:getActEndTime(arg_203_2)
	}, function()
		arg_203_0.activities:loadActivities(function(arg_205_0)
			if arg_205_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("activities", {
					default_table_id = 1203
				})
			end
		end)
	end)
end

function var_0_0.stickBlessSetup(arg_206_0, arg_206_1, arg_206_2)
	arg_206_0.stickBlessBtn = arg_206_1

	arg_206_0:commonActSetup(arg_206_1, {
		endTime = arg_206_0:getActEndTime(arg_206_2)
	}, function(arg_207_0)
		xyd.ModelManager.get():loadModel(xyd.ModelType.STICK_BLESS):loadInfo(function()
			xyd.WindowManager.get():openWindow("stick_bless_word")
		end)
	end)
end

function var_0_0.sakura2018Setup(arg_209_0, arg_209_1, arg_209_2)
	arg_209_0.sakura2018 = arg_209_0.sakura2018 or xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA2018)
	arg_209_0.sakura2018Btn = arg_209_1
	arg_209_0.sakura2018BtnMark = arg_209_0.sakura2018Btn:getChildByName("notif")

	arg_209_0:commonActSetup(arg_209_1, {
		endTime = arg_209_0:getActEndTime(arg_209_2)
	}, function(arg_210_0)
		arg_209_0.sakura2018:loadInfo(function(arg_211_0, arg_211_1)
			if arg_211_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("sakura2018_main")
			end
		end)
	end)
end

function var_0_0.sakuraWishesSetup(arg_212_0, arg_212_1, arg_212_2)
	arg_212_0.sakuraWishes = arg_212_0.sakuraWishes or xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA_WISHES)
	arg_212_0.sakuraWishesBtn = arg_212_1

	arg_212_0:commonActSetup(arg_212_1, {
		endTime = arg_212_0:getActEndTime(arg_212_2)
	}, function(arg_213_0)
		arg_212_0.sakuraWishes:loadInfo(function(arg_214_0, arg_214_1)
			if arg_214_0 == xyd.error.OK then
				if xyd.ServerTime.get():getServerTime() < arg_212_0.sakuraWishes.activity.start_time then
					local var_214_0 = var_0_4:translation("ACTIVITY_UNRECHABLE")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_214_0
					})

					return
				elseif xyd.ServerTime.get():getServerTime() > arg_212_0.sakuraWishes.activity.end_time then
					local var_214_1 = var_0_4:translation("ACTIVITY_FINISHED")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_214_1
					})

					return
				end

				xyd.WindowManager.get():openWindow("sakura_wishes_main", arg_214_1)
			end
		end)
	end)
end

function var_0_0.sakuraWishes2Setup(arg_215_0, arg_215_1, arg_215_2)
	arg_215_0.sakuraWishes2 = arg_215_0.sakuraWishes2 or xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA_WISHES2)
	arg_215_0.sakuraWishes2Btn = arg_215_1

	arg_215_0:commonActSetup(arg_215_1, {
		endTime = arg_215_0:getActEndTime(arg_215_2)
	}, function(arg_216_0)
		arg_215_0.sakuraWishes2:loadInfo(function(arg_217_0, arg_217_1)
			if arg_217_0 == xyd.error.OK then
				if xyd.ServerTime.get():getServerTime() < arg_215_0.sakuraWishes2.activity.start_time then
					local var_217_0 = var_0_4:translation("ACTIVITY_UNRECHABLE")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_217_0
					})

					return
				elseif xyd.ServerTime.get():getServerTime() > arg_215_0.sakuraWishes2.activity.end_time then
					local var_217_1 = var_0_4:translation("ACTIVITY_FINISHED")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_217_1
					})

					return
				end

				xyd.WindowManager.get():openWindow("sakura_wishes_main_new", arg_217_1)
			end
		end)
	end)
end

function var_0_0.gardenSetup(arg_218_0, arg_218_1, arg_218_2)
	arg_218_0.garden = arg_218_0.garden or xyd.ModelManager.get():loadModel(xyd.ModelType.GARDEN)
	arg_218_0.gardenBtn = arg_218_1
	arg_218_0.gardenBtnMark = arg_218_0.gardenBtn:getChildByName("notif")

	if not arg_218_0.garden.activity then
		arg_218_0.garden:loadInfo(function(arg_219_0, arg_219_1)
			if arg_219_0 == xyd.error.OK and arg_218_0.gardenBtn and not tolua.isnull(arg_218_0.gardenBtn) then
				arg_218_0.gardenBtn:setVisible(true)

				local var_219_0 = arg_218_0.garden:isGardenRedPointShow()

				arg_218_0.gardenBtnMark:setVisible(var_219_0)
			end
		end)
	else
		local var_218_0 = arg_218_0.garden:isGardenRedPointShow()

		if arg_218_0.gardenBtn and not tolua.isnull(arg_218_0.gardenBtn) then
			arg_218_0.gardenBtn:setVisible(true)
			arg_218_0.gardenBtnMark:setVisible(var_218_0)
		end
	end

	arg_218_0:commonActSetup(arg_218_1, {
		endTime = arg_218_0:getActEndTime(arg_218_2)
	}, function(arg_220_0)
		arg_218_0.garden:loadInfo(function(arg_221_0, arg_221_1)
			if arg_221_0 == xyd.error.OK then
				if xyd.ServerTime.get():getServerTime() < arg_218_0.garden.activity.start_time then
					local var_221_0 = var_0_4:translation("ACTIVITY_UNRECHABLE")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_221_0
					})

					return
				elseif xyd.ServerTime.get():getServerTime() > arg_218_0.garden.activity.end_time then
					local var_221_1 = var_0_4:translation("ACTIVITY_FINISHED")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_221_1
					})

					return
				end

				xyd.WindowManager.get():openWindow("garden")

				if arg_218_0.gardenBtnMark and not tolua.isnull(arg_218_0.gardenBtnMark) then
					arg_218_0.gardenBtnMark:setVisible(false)
				end
			else
				xyd.WindowManager.get():openWindow("garden")
			end
		end)
	end)
end

function var_0_0.thirdAnniversarySetup(arg_222_0, arg_222_1, arg_222_2)
	arg_222_0.thirdAnniModel = arg_222_0.thirdAnniModel or xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_222_0.thirdAnniversaryBtn = arg_222_1
	arg_222_0.thirdAnniversaryMark = arg_222_0.thirdAnniversaryBtn:getChildByName("notif")

	arg_222_0:commonActSetup(arg_222_1, {
		endTime = arg_222_0:getActEndTime(arg_222_2)
	}, function(arg_223_0)
		arg_222_0.thirdAnniModel:loadInfo(function(arg_224_0, arg_224_1)
			if arg_224_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("third_anni_main")
			end
		end)
	end)
end

function var_0_0.newOpenServiceSetup(arg_225_0, arg_225_1, arg_225_2)
	arg_225_0.newOpenServiceBtn = arg_225_1
	arg_225_0.newOpenServiceMark = arg_225_0.newOpenServiceBtn:getChildByName("notif")

	arg_225_0.newOpenServiceMark:setVisible(false)

	local var_225_0 = arg_225_0.activities:getActivityInfo(xyd.Activities.NewOpenService)
	local var_225_1 = xyd.tables.newOpenServiceGift
	local var_225_2 = xyd.tables.newOpenService

	if var_225_0 and var_225_0.details then
		local var_225_3 = var_225_0.details.mission_list
		local var_225_4 = var_225_0.details.base_info
		local var_225_5 = var_225_0.details.day_count

		if var_225_5 > 7 then
			var_225_5 = 7
		end

		for iter_225_0 = 1, 4 do
			if var_225_4.finish_count > var_225_1:req(iter_225_0) and var_225_4.gift_awards[iter_225_0] == 0 then
				arg_225_0.newOpenServiceMark:setVisible(true)

				break
			end
		end

		for iter_225_1 = 1, #var_225_3 do
			local var_225_6 = var_225_3[iter_225_1]

			if var_225_6.mission_id < (var_225_5 + 1) * 1000 and var_225_6.count >= var_225_2:req(var_225_6.mission_id) and var_225_6.is_award == 0 then
				arg_225_0.newOpenServiceMark:setVisible(true)

				break
			end
		end
	end

	arg_225_0:commonActSetup(arg_225_1, {}, function(arg_226_0)
		arg_225_0.activities:loadSingleActivity({
			activity_id = xyd.Activities.NewOpenService
		}, function(arg_227_0, arg_227_1)
			if arg_227_0 == xyd.error.OK then
				if arg_227_1.is_open and arg_227_1.is_open == 0 then
					arg_225_0:updateButtonTable()
				else
					xyd.WindowManager.get():openWindow("open_service", arg_227_1)
				end
			end
		end)
	end)
end

function var_0_0.gardenSeedSetup(arg_228_0, arg_228_1, arg_228_2)
	arg_228_0.gardenSeedBtn = arg_228_1

	arg_228_0:commonActSetup(arg_228_1, {
		endTime = arg_228_0:getActEndTime(arg_228_2)
	}, function(arg_229_0)
		xyd.WindowManager.get():openWindow("garden_seed")
	end)
end

function var_0_0.monthLimit2Setup(arg_230_0, arg_230_1, arg_230_2)
	arg_230_0.monthLimit2Btn = arg_230_1

	arg_230_0:commonActSetup(arg_230_1, {
		endTime = arg_230_0:getActEndTime(arg_230_2)
	}, function()
		xyd.WindowManager.get():openWindow("month_limit2")
	end)
end

function var_0_0.monthLimit3Setup(arg_232_0, arg_232_1, arg_232_2)
	arg_232_0.monthLimit3Btn = arg_232_1

	arg_232_0:commonActSetup(arg_232_1, {
		endTime = arg_232_0:getActEndTime(arg_232_2)
	}, function()
		xyd.WindowManager.get():openWindow("month_limit3")
	end)
end

function var_0_0.cvLinkSetup(arg_234_0, arg_234_1)
	arg_234_0.cvLinkBtn = arg_234_1

	arg_234_0.cvLinkBtn:setTouchEnabled(true)
	arg_234_0.cvLinkBtn:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_235_0)
		if arg_235_0.name == "began" then
			arg_234_0.cvLinkBtn:setScale(0.8)

			return true
		elseif arg_235_0.name == "ended" then
			arg_234_0.cvLinkBtn:setScale(1)

			if arg_234_0.scrollViewMoved_ then
				return
			end

			arg_234_0.cvLink:loadInfo(function(arg_236_0, arg_236_1)
				if true or arg_236_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("cv_link")
				end
			end)
		end
	end)
end

function var_0_0.superRichSetup(arg_237_0, arg_237_1, arg_237_2)
	arg_237_0.superRich = arg_237_0.superRich or xyd.ModelManager.get():loadModel(xyd.ModelType.SUPER_RICH)
	arg_237_0.superRichBtn = arg_237_1

	arg_237_0:commonActSetup(arg_237_1, {
		endTime = arg_237_0:getActEndTime(arg_237_2)
	}, function(arg_238_0)
		local var_238_0 = {}

		arg_237_0.superRich:monoplyInfo(var_238_0, function(arg_239_0, arg_239_1)
			if arg_239_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("super_rich_main")
			end
		end)
	end)
end

function var_0_0.chocolateSetup(arg_240_0, arg_240_1, arg_240_2)
	arg_240_0.chocolateModel = arg_240_0.chocolateModel or xyd.ModelManager.get():loadModel(xyd.ModelType.CHOCOLATE)
	arg_240_0.chocolateBtn = arg_240_1

	arg_240_0:commonActSetup(arg_240_1, {
		endTime = arg_240_0:getActEndTime(arg_240_2)
	}, function(arg_241_0)
		arg_240_0.chocolateModel:chocolateInfo({}, function(arg_242_0, arg_242_1)
			if arg_242_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("chocolate_main")
			end
		end)
	end)
end

function var_0_0.fourthAnniversarySetup(arg_243_0, arg_243_1, arg_243_2)
	arg_243_0.FourthAnniModel = arg_243_0.FourthAnniModel or xyd.ModelManager.get():loadModel(xyd.ModelType.FOURTH_ANNIVERSARY)
	arg_243_0.fourthAnniversaryBtn = arg_243_1

	arg_243_0:commonActSetup(arg_243_1, {
		endTime = arg_243_0:getActEndTime(arg_243_2)
	}, function(arg_244_0)
		arg_243_0.FourthAnniModel:fourthAnniInfo({}, function(arg_245_0, arg_245_1)
			if arg_245_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("fourth_anni_main")
			end
		end)
	end)
end

function var_0_0.newVipBoxDrawSetup(arg_246_0, arg_246_1, arg_246_2)
	arg_246_0:commonActSetup(arg_246_1, {
		endTime = arg_246_0:getActEndTime(arg_246_2)
	}, function(arg_247_0)
		local var_247_0 = {
			activity_id = xyd.Activities.NewVipBoxDraw
		}

		arg_246_0.activities:loadSingleActivity(var_247_0, function(arg_248_0, arg_248_1)
			if arg_248_0 == xyd.error.OK then
				if arg_248_1.is_open == 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_4:translation("ACTIVITY_FINISHED")
					})

					return
				end

				local var_248_0 = {
					endTime = arg_248_1.end_time
				}

				xyd.WindowManager.get():openWindow("new_vip_box_draw", var_248_0)
			end
		end)
	end)
end

function var_0_0.activityWufuSetup(arg_249_0, arg_249_1, arg_249_2)
	arg_249_0:commonActSetup(arg_249_1, {
		endTime = arg_249_0:getActEndTime(arg_249_2)
	}, function(arg_250_0)
		local var_250_0 = {
			activity_id = xyd.Activities.Wufu
		}

		arg_249_0.activities:loadSingleActivity(var_250_0, function(arg_251_0, arg_251_1)
			if arg_251_0 == xyd.error.OK then
				if arg_251_1.is_open == 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_4:translation("ACTIVITY_FINISHED")
					})

					return
				end

				local var_251_0 = arg_251_1

				xyd.WindowManager.get():openWindow("activity_wufu_main", var_251_0)
			end
		end)
	end)
end

function var_0_0.skinShopDiscountSetup(arg_252_0, arg_252_1, arg_252_2)
	arg_252_0:commonActSetup(arg_252_1, {
		endTime = arg_252_0:getActEndTime(arg_252_2)
	}, function(arg_253_0)
		local var_253_0 = {
			activity_id = xyd.Activities.SkinShopDiscount
		}

		arg_252_0.activities:loadSingleActivity(var_253_0, function(arg_254_0, arg_254_1)
			if arg_254_0 == xyd.error.OK then
				if arg_254_1.is_open == 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_4:translation("ACTIVITY_FINISHED")
					})

					return
				end

				if not arg_252_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_SHOP) then
					local var_254_0 = xyd.tables.functionOpen
					local var_254_1 = xyd.tables.campaign
					local var_254_2 = "NUM_" .. var_254_1:chapter(var_254_0:stage(xyd.FunctionID.ID_SHOP))
					local var_254_3 = string.format(var_0_4:translation("FUNCTION_OPEN_TIP_STAGE"), var_0_4:translation(var_254_2))

					xyd.WindowManager.get():openWindow("toast", {
						message = var_254_3
					})

					return
				end

				local var_254_4 = xyd.FunctionID.ID_SKIN_SHOP

				if arg_252_0.selfPlayer:isFuncOpen(var_254_4) == false then
					local var_254_5 = xyd.tables.functionOpen:level(var_254_4)
					local var_254_6 = string.format(var_0_4:translation("FUNCTION_OPEN_TIP_LEVEL"), var_254_5)

					xyd.WindowManager.get():openWindow("toast", {
						message = var_254_6
					})

					return
				end

				xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadSkinShopInfo({}, function()
					xyd.WindowManager.get():openWindow("skin_shop", {})
				end)
			end
		end)
	end)
end

function var_0_0.activityFishingSetup(arg_256_0, arg_256_1, arg_256_2)
	arg_256_0:commonActSetup(arg_256_1, {
		endTime = arg_256_0:getActEndTime(arg_256_2)
	}, function()
		arg_256_0.activities:loadActivities(function(arg_258_0)
			if arg_258_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("activities", {
					default_table_id = 1226
				})
			end
		end)
	end)
end

function var_0_0.updateRecallRedPointShow(arg_259_0, arg_259_1)
	local var_259_0 = arg_259_1 or arg_259_0.activities:getActivityInfo(xyd.Activities.Recall)
	local var_259_1 = xyd.tables.activityRecall
	local var_259_2 = var_259_0.details.mission_info
	local var_259_3 = {}

	if var_259_0.details.base_info.recall_time > 0 then
		var_259_3 = var_259_1:getIds(1)
	else
		var_259_3 = var_259_1:getIds(2)
	end

	for iter_259_0 = #var_259_3, 1, -1 do
		if var_259_1:show(var_259_3[iter_259_0]) > arg_259_0.selfPlayer.lev then
			table.remove(var_259_3, iter_259_0)
		end
	end

	local var_259_4 = false

	for iter_259_1, iter_259_2 in pairs(var_259_3) do
		local var_259_5 = var_259_2.counts[iter_259_2] or 0
		local var_259_6 = var_259_2.is_awarded[iter_259_2] or 0

		if var_259_5 >= var_259_1:req(iter_259_2)[2] and var_259_6 == 0 then
			var_259_4 = true

			break
		end
	end

	if arg_259_0.activityRecallBtn and not tolua.isnull(arg_259_0.activityRecallBtn) then
		arg_259_0.activityRecallBtn:getChildByName("notif"):setVisible(var_259_4)
	end
end

function var_0_0.activityRecall(arg_260_0, arg_260_1)
	arg_260_0.activityRecallBtn = arg_260_1

	arg_260_0.activityRecallBtn:setTouchEnabled(true)

	local function var_260_0(arg_261_0)
		arg_260_0:updateRecallRedPointShow(arg_261_0)
	end

	var_260_0()
	arg_260_0:commonActSetup(arg_260_1, {}, function(arg_262_0)
		arg_260_0.activities:loadSingleActivity({
			activity_id = xyd.Activities.Recall
		}, function(arg_263_0, arg_263_1)
			if arg_263_0 == xyd.error.OK then
				local var_263_0 = {
					activity = arg_263_1,
					callback = var_260_0
				}

				arg_260_0:updateRecallRedPointShow(arg_263_1)
				xyd.WindowManager.get():openWindow("activity_recall", var_263_0)
			end
		end)
	end)
end

function var_0_0.tutorSetup(arg_264_0, arg_264_1, arg_264_2)
	arg_264_0.tutor = arg_264_0.tutor or xyd.ModelManager.get():loadModel(xyd.ModelType.TUTOR)
	arg_264_0.tutorBtn = arg_264_1

	arg_264_0.tutorBtn:setTouchEnabled(true)

	local function var_264_0(arg_265_0)
		arg_264_0:updateRecallRedPointShow(arg_265_0)
	end

	arg_264_0:commonActSetup(arg_264_1, {
		endTime = arg_264_0:getActEndTime(arg_264_2)
	}, function(arg_266_0)
		arg_264_0.tutor:tutorInfo({}, function(arg_267_0, arg_267_1)
			if arg_267_0 == xyd.error.OK then
				local var_267_0 = {}

				xyd.WindowManager.get():openWindow("tutor_sub", var_267_0)
			end
		end)
	end)
end

function var_0_0.adventureEventSetup(arg_268_0, arg_268_1)
	arg_268_0.adventureEventBtn = arg_268_1

	local var_268_0 = {
		size = 18,
		color = cc.c3b(255, 240, 0)
	}

	arg_268_0.adventureEventTimeText = xyd.AssetLoader.get():loadLabel(var_268_0)

	arg_268_0.adventureEventTimeText:addTo(arg_268_0.adventureEventBtn)
	arg_268_0.adventureEventTimeText:setPosition(140, 18)
	arg_268_0:updateAdventureTime()
	arg_268_0:commonActSetup(arg_268_1, {}, function(arg_269_0)
		arg_268_0.adventureEvent:reloadAdventureEventInfo(function(arg_270_0, arg_270_1)
			if arg_270_0 == xyd.error.OK then
				local var_270_0 = xyd.WindowManager.get():getWindow("main_scene_top")

				if var_270_0 and not tolua.isnull(var_270_0) then
					var_270_0.adventureEventEarliestTime = var_270_0.adventureEvent:getStartEarliestTime().time

					if var_270_0.adventureEventEarliestTime < 0 then
						var_270_0.adventureEventBtn:setVisible(false)
					end

					var_270_0:updateAdventureTime()
					xyd.WindowManager.get():openWindow("adventure_event")
				end
			end
		end)
	end)
end

function var_0_0.picNoticeSetup(arg_271_0, arg_271_1)
	arg_271_0:commonActSetup(arg_271_1, {}, function(arg_272_0)
		xyd.Backend.get():request(xyd.mid.GET_PIC_NOTICE_INFO, {}, function(arg_273_0, arg_273_1)
			if arg_273_0 == xyd.error.OK then
				if #arg_273_1.contents > 0 then
					xyd.WindowManager.get():openWindow("pic_notice", {
						contents = arg_273_1.contents
					})
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_4:translation("ACTIVITIES_BOARD_NONE")
					})
				end
			end
		end)
	end)
end

function var_0_0.fifthAnniversarySetup(arg_274_0, arg_274_1, arg_274_2)
	arg_274_0:commonActSetup(arg_274_1, {
		endTime = arg_274_0:getActEndTime(arg_274_2)
	}, function(arg_275_0)
		arg_274_0.activities:loadActivities(function(arg_276_0)
			if arg_276_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("activities", {
					default_table_id = 1232
				})
			end
		end)
	end)
end

function var_0_0.getActEndTime(arg_277_0, arg_277_1)
	return (arg_277_0.activities:getActivityInfo(arg_277_1) or {}).end_time
end

function var_0_0.commonActSetup(arg_278_0, arg_278_1, arg_278_2, arg_278_3)
	arg_278_1:setTouchEnabled(true)
	arg_278_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_279_0)
		arg_278_0.actMoveCount = 0

		if arg_279_0.name == "began" then
			arg_278_0.prevX_ = arg_279_0.x

			return true
		elseif arg_279_0.name == "ended" then
			if math.abs(arg_279_0.x - arg_278_0.prevX_) < 20 then
				arg_278_3()

				return
			end

			arg_278_0:actMove(arg_279_0.x - arg_278_0.prevX_ < 0)
		end
	end)

	if arg_278_2.endTime then
		local var_278_0 = arg_278_2.endTime - xyd.ServerTime.get():getServerTime()
		local var_278_1 = xyd.AssetLoader.get():loadSprite("windows/main_top_window/bg_act_time.png")

		var_278_1:addTo(arg_278_1)
		var_278_1:setPosition(177, 80)

		local var_278_2 = {
			size = 18,
			color = cc.c3b(255, 42, 0)
		}
		local var_278_3 = xyd.AssetLoader.get():loadLabel(var_278_2)

		var_278_3:addTo(arg_278_1)
		var_278_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_278_3:setPosition(181, 78)
		var_278_3:enableOutline(cc.c4b(255, 255, 255, 255), 1)
		var_278_3:setString(xyd.secondsToString(var_278_0))

		local var_278_4

		var_278_4 = var_0_2.scheduleGlobal(function()
			if not var_278_3 or tolua.isnull(var_278_3) or var_278_0 < 1 then
				var_0_2.unscheduleGlobal(var_278_4)

				return
			end

			var_278_0 = var_278_0 - 1

			var_278_3:setString(xyd.secondsToString(var_278_0))
		end, 1)
	end
end

function var_0_0.updateAdventureTime(arg_281_0)
	if arg_281_0.adventureTimeHandle_ then
		var_0_2.unscheduleGlobal(arg_281_0.adventureTimeHandle_)
	end

	local var_281_0 = arg_281_0.adventureEventTimeText

	if not var_281_0 or tolua.isnull(var_281_0) then
		return
	end

	local var_281_1 = arg_281_0.adventureEventEarliestTime - xyd.ServerTime.get():getServerTime()

	if var_281_1 <= 0 then
		arg_281_0.adventureEvent:reloadAdventureEventInfo(function(arg_282_0, arg_282_1)
			if arg_282_0 == xyd.error.OK and arg_281_0 and not tolua.isnull(arg_281_0) then
				arg_281_0:updateButtonTable()
			end
		end)
		var_281_0:setString("00:00")

		return
	end

	var_281_0:setString(xyd.secondsToString(var_281_1))

	arg_281_0.adventureTimeHandle_ = var_0_2.scheduleGlobal(function()
		if var_281_0 and not tolua.isnull(var_281_0) then
			var_281_1 = var_281_1 - 1

			var_281_0:setString(xyd.secondsToString(var_281_1))

			if var_281_1 == 0 then
				arg_281_0.adventureEvent:reloadAdventureEventInfo(function(arg_284_0, arg_284_1)
					if arg_284_0 == xyd.error.OK then
						arg_281_0:updateButtonTable()
					end
				end)
			end
		elseif arg_281_0.adventureTimeHandle_ then
			var_0_2.unscheduleGlobal(arg_281_0.adventureTimeHandle_)

			arg_281_0.adventureTimeHandle_ = nil
		end
	end, 1)
end

function var_0_0.onEnterAction(arg_285_0, arg_285_1)
	local var_285_0 = {
		"btn_act",
		"btn_shop",
		"btn_mail",
		"btn_friend",
		"btn_rank"
	}

	for iter_285_0 = 1, #var_285_0 do
		arg_285_0:nodeByName(var_285_0[iter_285_0]):runAction(cc.Sequence:create({
			cc.MoveBy:create(0, cc.p(-160, 0)),
			cc.DelayTime:create((arg_285_1 and 0.03 or 0.46) + (iter_285_0 - 1) * 0.03),
			cc.MoveBy:create(0.2, cc.p(160, 0))
		}))
	end

	arg_285_0:nodeByName("act_container"):runAction(cc.Sequence:create({
		cc.MoveBy:create(0, cc.p(-270, 0)),
		cc.DelayTime:create(arg_285_1 and 0 or 0.2),
		cc.MoveBy:create(0.23, cc.p(270, 0)),
		cc.MoveBy:create(0.13, cc.p(2, 0)),
		cc.MoveBy:create(0.23, cc.p(-2, 0))
	}))

	if not arg_285_0:nodeByName("act_container"):getChildByName("act_clip") then
		local var_285_1 = display.newNode()

		var_285_1:setContentSize(300, 130)
		var_285_1:setTouchEnabled(true)
		var_285_1:setTouchSwallowEnabled(true)
		var_285_1:setAnchorPoint(0, 0)
		var_285_1:setPosition(0, 0)
		var_285_1:addTo(arg_285_0:nodeByName("act_container"))
		var_285_1:setName("act_clip")
	end

	arg_285_0:nodeByName("bg_label"):runAction(cc.Sequence:create({
		cc.DelayTime:create(arg_285_1 and 0.43 or 0.63),
		cc.RotateBy:create(0.06, 4),
		cc.RotateBy:create(0.06, -4)
	}))

	local var_285_2 = {}

	if arg_285_0.activities:isActivityOpen(xyd.Activities.NEW_MONTH_CARD) then
		table.insert(var_285_2, "panel_month_card")
	end

	if arg_285_0.activities:isFirstChargeShow() then
		table.insert(var_285_2, "btn_first_charge")
	else
		table.insert(var_285_2, "btn_charge")
	end

	if arg_285_0.monthBtn then
		table.insert(var_285_2, arg_285_0.monthBtn:getName())
	end

	local var_285_3 = arg_285_0.activities:getActivityInfo(xyd.Activities.NewServerPush)

	if (var_285_3 and var_285_3.details.lev_time + 259200 - xyd.ServerTime.get():getServerTime() or 0) > 0 then
		table.insert(var_285_2, "new_server_push")
	end

	if #xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):getGiftInfo() > 0 then
		table.insert(var_285_2, "gift_push")
	end

	if arg_285_0.activities:isActivityOpen(xyd.Activities.SevenDayLogin) then
		table.insert(var_285_2, "seven_day_login")
	end

	if arg_285_0.walfareIsOpen then
		table.insert(var_285_2, "walfare")
	end

	table.insert(var_285_2, "btn_battle_pass")

	for iter_285_1 = 1, #var_285_2 do
		arg_285_0:nodeByName(var_285_2[iter_285_1]):stopAllActions()
		arg_285_0:nodeByName(var_285_2[iter_285_1]):runAction(cc.Sequence:create({
			cc.CallFunc:create(function()
				arg_285_0:nodeByName(var_285_2[iter_285_1]):setScale(0)
				arg_285_0:nodeByName(var_285_2[iter_285_1]):setRotation(90)
			end),
			cc.DelayTime:create((arg_285_1 and -0.06 or 0.43) + iter_285_1 * 0.06),
			cc.Spawn:create({
				cc.RotateBy:create(0.16, 270),
				cc.ScaleTo:create(0.16, 1)
			}),
			cc.RotateBy:create(0.06, -20),
			cc.RotateBy:create(0.06, 26.6),
			cc.RotateBy:create(0.06, -6.6),
			cc.CallFunc:create(function()
				if iter_285_1 == #var_285_2 and not arg_285_1 then
					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.MAIN_SCENE_ACTION_END
					})
				end
			end)
		}))
	end

	local var_285_4 = {
		"btn_act",
		"btn_shop",
		"btn_mail",
		"btn_friend",
		"btn_rank",
		"month",
		"month_gray",
		"month_blue",
		"btn_first_charge",
		"btn_charge",
		"new_server_push",
		"gift_push",
		"seven_day_login",
		"walfare",
		"month_green",
		"btn_battle_pass"
	}

	for iter_285_2 = 1, #var_285_4 do
		arg_285_0:nodeByName(var_285_4[iter_285_2]):setTouchEnabled(false)
	end

	arg_285_0:nodeByName("eco_sidebar"):touchEnable(false)
	arg_285_0:nodeByName("bird"):setVisible(false)

	for iter_285_3, iter_285_4 in pairs(arg_285_0.GuideHands) do
		for iter_285_5, iter_285_6 in pairs(iter_285_4.nodes) do
			if iter_285_6 and not tolua.isnull(iter_285_6) then
				iter_285_6:setVisible(false)
			end
		end
	end
end

function var_0_0.onEnterActionEnd(arg_288_0)
	local var_288_0 = {
		"btn_act",
		"btn_shop",
		"btn_mail",
		"btn_friend",
		"btn_rank",
		"month",
		"month_gray",
		"month_blue",
		"btn_first_charge",
		"btn_charge",
		"new_server_push",
		"gift_push",
		"seven_day_login",
		"walfare",
		"month_green",
		"btn_battle_pass"
	}

	for iter_288_0 = 1, #var_288_0 do
		arg_288_0:nodeByName(var_288_0[iter_288_0]):setTouchEnabled(true)
	end

	if arg_288_0:nodeByName("act_container"):getChildByName("act_clip") then
		arg_288_0:nodeByName("act_container"):getChildByName("act_clip"):removeSelf()
	end

	arg_288_0:nodeByName("eco_sidebar"):touchEnable(true)
	arg_288_0:nodeByName("bird"):setVisible(true)

	for iter_288_1, iter_288_2 in pairs(arg_288_0.GuideHands) do
		for iter_288_3, iter_288_4 in pairs(iter_288_2.nodes) do
			if iter_288_4 and not tolua.isnull(iter_288_4) then
				iter_288_4:setVisible(true)
			end
		end
	end
end

function var_0_0.updateTopBtn(arg_289_0)
	arg_289_0.topBtnIndex = 0

	for iter_289_0, iter_289_1 in ipairs(var_0_8) do
		if iter_289_1 == "new_server_push" then
			arg_289_0:updatePush()
		elseif iter_289_1 == "gift_push" then
			arg_289_0:updateGiftPush()
		elseif iter_289_1 == "walfare" then
			arg_289_0:updateWalfareOpen()
		elseif iter_289_1 == "seven_day_login" then
			arg_289_0:updateSevenDayLogin()
		elseif iter_289_1 == "btn_battle_pass" then
			arg_289_0:updateBattlePassOpen()
		end
	end
end

function var_0_0.checkGameStat(arg_290_0)
	xyd.Backend.get():request(xyd.mid.CHECK_GAME_STAT, {}, nil, nil, nil, false)
end

return var_0_0
