local var_0_0 = class("VipRechargeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.WndTopSidebar")
local var_0_2 = xyd.WindowName.vipRecharge
local var_0_3 = 2
local var_0_4 = 80001001
local var_0_5 = 80001008
local var_0_6 = 80001009
local var_0_7 = 80001010
local var_0_8 = 80001014
local var_0_9 = 80001015
local var_0_10 = 80001011
local var_0_11 = 80001012
local var_0_12 = 80001013
local var_0_13 = xyd.tables.translation
local var_0_14 = import("framework.scheduler")
local var_0_15 = 15

var_0_0.PRIVILEGE_BTN = "privilege_btn"
var_0_0.PRIVILEGE_TXT = "privilege_btn_txt"
var_0_0.PROGRESS_BAR = "progress_bar"
var_0_0.RECHARGE_RATIO = "recharge_num_ratio"
var_0_0.NEED_COST = "need_cost_txt"

local var_0_16 = xyd.tables.charge
local var_0_17 = xyd.tables.giftbag

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.giftAwardItems = {}
	arg_1_0.giftAwardNums = {}
	arg_1_0.vipGiftBoxData = {}
	arg_1_0.listData = {}
	arg_1_0.priListData = {}
	arg_1_0.showPrivilegeList = true
end

function var_0_0.changeChargeState(arg_2_0)
	if arg_2_0.chargeState == xyd.ChargeState.diamond then
		arg_2_0:nodeByName("btn_diamond"):setTouchEnabled(false)
		arg_2_0:nodeByName("btn_diamond"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_2_0:nodeByName("btn_giftbag"):setTouchEnabled(true)
		arg_2_0:nodeByName("btn_giftbag"):setBrightStyle(ccui.BrightStyle.normal)
		arg_2_0:nodeByName("btn_hero"):setTouchEnabled(true)
		arg_2_0:nodeByName("btn_hero"):setBrightStyle(ccui.BrightStyle.normal)
		arg_2_0:nodeByName("btn_privilege"):setTouchEnabled(true)
		arg_2_0:nodeByName("btn_privilege"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_2_0.chargeState == xyd.ChargeState.giftbag then
		arg_2_0:nodeByName("btn_diamond"):setTouchEnabled(true)
		arg_2_0:nodeByName("btn_diamond"):setBrightStyle(ccui.BrightStyle.normal)
		arg_2_0:nodeByName("btn_giftbag"):setTouchEnabled(false)
		arg_2_0:nodeByName("btn_giftbag"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_2_0:nodeByName("btn_hero"):setTouchEnabled(true)
		arg_2_0:nodeByName("btn_hero"):setBrightStyle(ccui.BrightStyle.normal)
		arg_2_0:nodeByName("btn_privilege"):setTouchEnabled(true)
		arg_2_0:nodeByName("btn_privilege"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_2_0.chargeState == xyd.ChargeState.hero then
		arg_2_0:nodeByName("btn_diamond"):setTouchEnabled(true)
		arg_2_0:nodeByName("btn_diamond"):setBrightStyle(ccui.BrightStyle.normal)
		arg_2_0:nodeByName("btn_giftbag"):setTouchEnabled(true)
		arg_2_0:nodeByName("btn_giftbag"):setBrightStyle(ccui.BrightStyle.normal)
		arg_2_0:nodeByName("btn_hero"):setTouchEnabled(false)
		arg_2_0:nodeByName("btn_hero"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_2_0:nodeByName("btn_privilege"):setTouchEnabled(true)
		arg_2_0:nodeByName("btn_privilege"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_2_0.chargeState == xyd.ChargeState.monthlyPrivilege then
		arg_2_0:nodeByName("btn_diamond"):setTouchEnabled(true)
		arg_2_0:nodeByName("btn_diamond"):setBrightStyle(ccui.BrightStyle.normal)
		arg_2_0:nodeByName("btn_giftbag"):setTouchEnabled(true)
		arg_2_0:nodeByName("btn_giftbag"):setBrightStyle(ccui.BrightStyle.normal)
		arg_2_0:nodeByName("btn_hero"):setTouchEnabled(true)
		arg_2_0:nodeByName("btn_hero"):setBrightStyle(ccui.BrightStyle.normal)
		arg_2_0:nodeByName("btn_privilege"):setTouchEnabled(false)
		arg_2_0:nodeByName("btn_privilege"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_0.initAwards(arg_3_0)
	arg_3_0.awards = {}
	arg_3_0.awardNums = {}

	for iter_3_0 = 1, var_0_15 do
		local var_3_0 = xyd.tables.vip:gift(iter_3_0)

		arg_3_0.awards[iter_3_0] = clone(xyd.tables.gift:items(var_3_0))
		arg_3_0.awardNums[iter_3_0] = clone(xyd.tables.gift:itemNum(var_3_0))

		local var_3_1 = xyd.tables.gift:crystal(var_3_0)

		if var_3_1 and var_3_1 > 0 then
			table.insert(arg_3_0.awards[iter_3_0], -1)
			table.insert(arg_3_0.awardNums[iter_3_0], var_3_1)
		end
	end
end

function var_0_0.scrollListener(arg_4_0, arg_4_1)
	if arg_4_1.name == "began" then
		arg_4_0.scrollViewMoved_ = false
		arg_4_0.prevY_ = arg_4_1.y
	elseif arg_4_1.name == "moved" and 20 <= math.abs(arg_4_1.y - arg_4_0.prevY_) then
		arg_4_0.scrollViewMoved_ = true
	end
end

function var_0_0.priScrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.priScrollViewMoved_ = false
		arg_5_0.priPrevY_ = arg_5_1.y
	elseif arg_5_1.name == "moved" and 20 <= math.abs(arg_5_1.y - arg_5_0.priPrevY_) then
		arg_5_0.priScrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_6_0, arg_6_1)
	arg_6_0:nodeByName("dangqian_txt"):setString(var_0_13:translation("VIP_WINDOW_TEXT_2"))
	arg_6_0:nodeByName("tequandengji_txt"):setString(var_0_13:translation("VIP_WINDOW_TEXT_3"))
	arg_6_0:nodeByName("need_buy_crystal_txt"):setString(var_0_13:translation("VIP_WINDOW_TEXT_4"))
	arg_6_0:nodeByName("can_be_txt"):setString(var_0_13:translation("VIP_WINDOW_TEXT_5"))
	arg_6_0:nodeByName("recharge_img"):setString(var_0_13:translation("VIP_WINDOW_TEXT_6"))
	arg_6_0:nodeByName("vip_privilege_img"):setString(var_0_13:translation("VIP_WINDOW_TEXT_7"))
	arg_6_0:nodeByName("word_zuanshi"):setString(var_0_13:translation("VIP_WINDOW_TEXT_8"))
	arg_6_0:nodeByName("word_libao"):setString(var_0_13:translation("VIP_WINDOW_TEXT_9"))
	arg_6_0:nodeByName("word_hero"):setString(var_0_13:translation("VIP_WINDOW_TEXT_10"))
	arg_6_0:nodeByName("word_tequan"):setString(var_0_13:translation("VIP_WINDOW_TEXT_17"))
	arg_6_0:nodeByName("left_container"):getChildByName("chakan_txt01"):setString(var_0_13:translation("VIP_WINDOW_TEXT_11"))
	arg_6_0:nodeByName("right_container"):getChildByName("chakan_txt01"):setString(var_0_13:translation("VIP_WINDOW_TEXT_11"))
	arg_6_0:addTopSidebar()
	arg_6_0:updateHeroContainer()

	arg_6_0.listContainer = arg_6_0:nodeByName("diamond_list")

	local var_6_0 = arg_6_0.listContainer:getContentSize()

	arg_6_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_6_0.width, var_6_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_6_0.listContainer):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.listView_:setBounceable(true)
	arg_6_0.listView_:setDelegate(handler(arg_6_0, arg_6_0.listDelegate))

	arg_6_0.left = arg_6_0:nodeByName("left_btn")
	arg_6_0.right = arg_6_0:nodeByName("right_btn")
	arg_6_0.leftView = {}
	arg_6_0.rightView = {}
	arg_6_0.middleView = {}

	local var_6_1 = xyd.ServerTime.get():getServerTime()

	if var_6_1 < var_0_17.lastShowTime2 then
		arg_6_0.chargeState = xyd.ChargeState.giftbag
	elseif var_6_1 < var_0_17.lastShowTime3 then
		arg_6_0.chargeState = xyd.ChargeState.hero
	else
		arg_6_0.chargeState = xyd.ChargeState.diamond
	end

	if arg_6_1 and arg_6_1.middleLev then
		arg_6_0.middleLev = arg_6_1.middleLev
		arg_6_0.leftLev = arg_6_0.middleLev - 1
		arg_6_0.rightLev = arg_6_0.middleLev + 1
		arg_6_0.fistOpen = true
	else
		arg_6_0.leftLev = arg_6_0.selfPlayer.vip - 1
		arg_6_0.rightLev = arg_6_0.selfPlayer.vip + 1
		arg_6_0.middleLev = arg_6_0.selfPlayer.vip
	end

	if arg_6_1 and arg_6_1.callback then
		arg_6_0.callback = arg_6_1.callback
	end

	if arg_6_1 == nil or arg_6_1.windowState == nil then
		arg_6_0.windowState = true
	else
		arg_6_0.windowState = arg_6_1.windowState
	end

	if arg_6_1 and arg_6_1.chargeState then
		arg_6_0.chargeState = arg_6_1.chargeState
	end

	arg_6_0.helpPanel = arg_6_0:nodeByName("helpInfo")
	arg_6_0.clippingNode = display.newClippingRegionNode()

	arg_6_0.clippingNode:setClippingRegion(cc.rect(0, 0, 700, 430))
	arg_6_0.helpPanel:addChild(arg_6_0.clippingNode)

	arg_6_0.vipChargeData = {}
	arg_6_0.hasCharged = arg_6_0.selfPlayer.charge
	arg_6_0.monthCardLeftTimes = arg_6_0.selfPlayer.leftCardDay or 0
	arg_6_0.weekCardLeftTimes = arg_6_0.selfPlayer.leftWeekCardDay or 0
	arg_6_0.energyMonthCardLeftTimes = arg_6_0.selfPlayer.leftEnergyMonthCardDay or 0
	arg_6_0.privilegeLeftCardTimes = arg_6_0.selfPlayer.privilegeLeftCardDay or 0

	arg_6_0:initAwards()

	arg_6_0.privilegeContainer = arg_6_0:nodeByName("container_privilege")

	if arg_6_0.windowState == true then
		arg_6_0:nodeByName("vip_privilege_img"):setVisible(true)
		arg_6_0:nodeByName("recharge_img"):setVisible(false)
		arg_6_0:nodeByName("charge_container"):setVisible(true)
		arg_6_0.privilegeContainer:setVisible(false)
	else
		arg_6_0:nodeByName("vip_privilege_img"):setVisible(false)
		arg_6_0:nodeByName("recharge_img"):setVisible(true)
		arg_6_0:nodeByName("charge_container"):setVisible(false)
		arg_6_0.privilegeContainer:setVisible(true)
	end

	if arg_6_0.selfPlayer.vip >= 15 then
		arg_6_0:nodeByName("vip01_img"):setVisible(false)
		arg_6_0:nodeByName("can_be_txt"):setVisible(false)
		arg_6_0:nodeByName("need_buy_crystal_txt"):setVisible(false)
		arg_6_0:nodeByName(var_0_0.NEED_COST):setVisible(false)
		arg_6_0:nodeByName("bg_top"):getChildByName("vip_lev2"):setVisible(false)
		arg_6_0:nodeByName("bg_top"):getChildByName("txt_bg"):setVisible(false)
	end

	arg_6_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			arg_6_0:nodeByName("rule_btn"):setScale(0.9, 0.9)
		end

		if arg_7_1 == ccui.TouchEventType.moved then
			arg_6_0:nodeByName("rule_btn"):setScale(1, 1)
		end

		if arg_7_1 == ccui.TouchEventType.ended then
			arg_6_0:nodeByName("rule_btn"):setScale(1, 1)

			local var_7_0 = {
				title_name = "CHRAGE_TIPS_TITLE",
				rule = "CHRAGE_TIPS_TITLE_CONTENT"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_7_0)
		end
	end)
	arg_6_0:update()
end

function var_0_0.addTopSidebar(arg_8_0)
	arg_8_0:setTouchEnabled(true)
	arg_8_0:setTouchSwallowEnabled(true)

	if arg_8_0:nodeByName("top_sidebar") then
		return
	end

	local var_8_0 = {
		colorMode = arg_8_0.colorMode,
		parent = arg_8_0,
		title = xyd.tables.window:title(arg_8_0.name)
	}
	local var_8_1 = var_0_1.new(xyd.WidgetName.wndTopSidebar, var_8_0)

	var_8_1:setAnchorPoint(0, 1)
	var_8_1:addTo(arg_8_0:nodeByName("background_top"))
	var_8_1:setPosition(0, 720)

	arg_8_0.children_.top_sidebar = var_8_1
	arg_8_0.children_.eco_sidebar = var_8_1:nodeByName("eco_sidebar")
end

function var_0_0.updateHeroContainer(arg_9_0)
	local var_9_0 = cc.p(arg_9_0:nodeByName("hero"):getPosition())
	local var_9_1 = xyd.tables.dialogConfig:dynamicImagePath("vip_recharge")
	local var_9_2 = xyd.tables.dialogConfig:location("vip_recharge")
	local var_9_3 = xyd.tables.dialogConfig:scale("vip_recharge")

	xyd.EffectLoader.new(var_9_1, 3, var_9_3, {
		x = var_9_0.x + var_9_2[1] + 50,
		y = var_9_0.y + var_9_2[2]
	}):addTo(arg_9_0:nodeByName("hero"))
	arg_9_0:showDialog()

	local var_9_4 = display.newNode()

	var_9_4:setContentSize(300, 600)
	var_9_4:addTo(arg_9_0)
	var_9_4:setPosition(0, 0)
	var_9_4:setTouchEnabled(true)
	var_9_4:setTouchSwallowEnabled(true)
	var_9_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			return true
		elseif arg_10_0.name == "ended" then
			arg_9_0:showDialog()
		end
	end)
end

function var_0_0.showDialog(arg_11_0)
	if arg_11_0.dialogHandler then
		var_0_14.unscheduleGlobal(arg_11_0.dialogHandler)
	end

	if arg_11_0.label then
		arg_11_0.label:removeSelf()

		arg_11_0.label = nil
	end

	arg_11_0:nodeByName("dialog"):removeAllChildren()

	local var_11_0, var_11_1, var_11_2 = xyd.tables.dialogConfig:dialogClick("vip_recharge")

	xyd.AssetDownload.get():downloadResByPath(var_11_1, function()
		return
	end)

	if var_11_2 and var_11_2 > 0 then
		arg_11_0.selfPlayer:playHeroSound(var_11_1, var_11_2)
	end

	local var_11_3 = {
		size = 26,
		color = cc.c3b(163, 40, 110)
	}

	arg_11_0.label = xyd.AssetLoader.get():loadLabel(var_11_3)

	arg_11_0.label:setMaxLineWidth(250)
	arg_11_0.label:setWidth(250)
	arg_11_0.label:setLineBreakWithoutSpace(true)
	arg_11_0.label:setString(var_11_0)
	arg_11_0.label:setAnchorPoint(cc.p(0, 1))
	arg_11_0.label:addTo(arg_11_0)
	arg_11_0.label:setPosition(35, 204)
	arg_11_0:nodeByName("dialog"):setVisible(true)

	local var_11_4 = arg_11_0.label:getContentSize().height

	arg_11_0:nodeByName("dialog"):setContentSize(arg_11_0:nodeByName("dialog"):getContentSize().width, var_11_4 + 69)

	arg_11_0.dialogHandler = var_0_14.performWithDelayGlobal(function()
		if arg_11_0 and not tolua.isnull(arg_11_0) then
			arg_11_0:nodeByName("dialog"):setVisible(false)
		end

		if arg_11_0.label then
			arg_11_0.label:removeSelf()

			arg_11_0.label = nil
		end
	end, 6)
end

function var_0_0.update(arg_14_0)
	arg_14_0.selfPlayer:queryChargeData(function(arg_15_0, arg_15_1)
		arg_14_0:updateVipGiftData(arg_15_0, arg_15_1)

		if not arg_14_0.selfPlayer then
			return
		end

		arg_14_0.vipChargeData = arg_14_0.selfPlayer.vipChargeData
		arg_14_0.vipGiftBoxData = arg_14_0.selfPlayer.vipGiftBoxData
		arg_14_0.charges = arg_14_0.selfPlayer.charges

		table.sort(arg_14_0.vipGiftBoxData, function(arg_16_0, arg_16_1)
			if var_0_17:seque(arg_16_0.charge_id) > var_0_17:seque(arg_16_1.charge_id) then
				return true
			elseif var_0_17:seque(arg_16_0.charge_id) == var_0_17:seque(arg_16_1.charge_id) and arg_16_0.charge_id > arg_16_1.charge_id then
				return true
			else
				return false
			end
		end)

		local var_15_0 = var_0_16:getChargeIds()
		local var_15_1 = var_0_16:getPrivilegeIds()

		arg_14_0.listData = {}
		arg_14_0.priListData = {}

		if arg_14_0.chargeState == xyd.ChargeState.diamond then
			for iter_15_0, iter_15_1 in pairs(arg_14_0.charges or {}) do
				if var_0_16:isPrivilege(iter_15_1.charge_id) == 0 and var_0_16:showType(iter_15_1.charge_id) == 0 and (device.platform ~= "ios" or iter_15_1.charge_id ~= 80001030) then
					table.insert(arg_14_0.listData, iter_15_1.charge_id)
				end
			end

			table.sort(arg_14_0.listData, function(arg_17_0, arg_17_1)
				if var_0_16:monthCardSort(arg_17_0) > var_0_16:monthCardSort(arg_17_1) then
					return true
				elseif var_0_16:monthCardSort(arg_17_0) < var_0_16:monthCardSort(arg_17_1) then
					return false
				elseif arg_14_0.vipChargeData[arg_17_0] and arg_14_0.vipChargeData[arg_17_0] > 0 and (not arg_14_0.vipChargeData[arg_17_1] or arg_14_0.vipChargeData[arg_17_1] <= 0) then
					return false
				elseif arg_14_0.vipChargeData[arg_17_1] and arg_14_0.vipChargeData[arg_17_1] > 0 and (not arg_14_0.vipChargeData[arg_17_0] or arg_14_0.vipChargeData[arg_17_0] <= 0) then
					return true
				else
					return var_0_16:charge(arg_17_0) < var_0_16:charge(arg_17_1)
				end
			end)

			if arg_14_0.helpItem then
				arg_14_0.helpItem:setVisible(false)
			end
		elseif arg_14_0.chargeState == xyd.ChargeState.giftbag then
			for iter_15_2, iter_15_3 in pairs(arg_14_0.vipGiftBoxData) do
				if var_0_17:page(iter_15_3.charge_id) == xyd.ChargeState.giftbag then
					table.insert(arg_14_0.listData, iter_15_3)
				end
			end

			if arg_14_0.helpItem then
				arg_14_0.helpItem:setVisible(false)
			end
		elseif arg_14_0.chargeState == xyd.ChargeState.hero then
			for iter_15_4, iter_15_5 in pairs(arg_14_0.vipGiftBoxData) do
				if var_0_17:page(iter_15_5.charge_id) == xyd.ChargeState.hero then
					table.insert(arg_14_0.listData, iter_15_5)
				end
			end

			if arg_14_0.helpItem then
				arg_14_0.helpItem:setVisible(false)
			end
		elseif arg_14_0.chargeState == xyd.ChargeState.monthlyPrivilege then
			for iter_15_6, iter_15_7 in pairs(arg_14_0.charges or {}) do
				if var_0_16:isPrivilege(iter_15_7.charge_id) == 1 and var_0_16:showType(iter_15_7.charge_id) == 0 then
					table.insert(arg_14_0.priListData, iter_15_7.charge_id)
				end
			end

			table.sort(arg_14_0.priListData, function(arg_18_0, arg_18_1)
				if var_0_16:monthCardSort(arg_18_0) > var_0_16:monthCardSort(arg_18_1) then
					return true
				elseif var_0_16:monthCardSort(arg_18_0) < var_0_16:monthCardSort(arg_18_1) then
					return false
				elseif arg_14_0.vipChargeData[arg_18_0] and arg_14_0.vipChargeData[arg_18_0] > 0 and (not arg_14_0.vipChargeData[arg_18_1] or arg_14_0.vipChargeData[arg_18_1] <= 0) then
					return false
				elseif arg_14_0.vipChargeData[arg_18_1] and arg_14_0.vipChargeData[arg_18_1] > 0 and (not arg_14_0.vipChargeData[arg_18_0] or arg_14_0.vipChargeData[arg_18_0] <= 0) then
					return true
				else
					return var_0_16:charge(arg_18_0) < var_0_16:charge(arg_18_1)
				end
			end)

			if not arg_14_0.helpItem then
				arg_14_0.helpItem = xyd.AssetLoader.get():loadNodeFromJson("windows/vipwindow/privilege_item.csb")

				arg_14_0.helpItem:addTo(arg_14_0:nodeByName("diamond_list"))
				arg_14_0.helpItem:setVisible(true)

				if arg_14_0.showPrivilegeList then
					if not arg_14_0.priListView_ then
						arg_14_0.priListContainer = arg_14_0.helpItem:getChildByName("list")

						local var_15_2 = arg_14_0.priListContainer:getContentSize()

						arg_14_0.priListView_ = cc.ui.UIListView.new({
							async = true,
							viewRect = cc.rect(0, 0, var_15_2.width, var_15_2.height),
							padding_ = {
								top = 0,
								bottom = 0,
								left = 0,
								right = 0
							},
							direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
						}):addTo(arg_14_0.priListContainer):onScroll(handler(arg_14_0, arg_14_0.priScrollListener))

						arg_14_0.priListView_:setBounceable(true)
						arg_14_0.priListView_:setDelegate(handler(arg_14_0, arg_14_0.priListDelegate))
					end

					arg_14_0.helpItem:getChildByName("list"):setVisible(true)
					arg_14_0.helpItem:getChildByName("container"):setVisible(false)
					arg_14_0.helpItem:getChildByName("right_container"):setVisible(true)
					arg_14_0.helpItem:getChildByName("middle_container"):setVisible(false)
					arg_14_0.helpItem:getChildByName("middle_container"):getChildByName("arrow"):setVisible(false)
					arg_14_0.priListView_:reload()

					local var_15_3 = arg_14_0.helpItem:getChildByName("right_container"):getChildByName("helpList")

					arg_14_0.helpItem:getChildByName("right_container"):getChildByName("txt_monthly_privilege"):setString(var_0_13:translation("VIP_WINDOW_TEXT_17"))

					local var_15_4 = var_15_3:getContentSize()
					local var_15_5 = cc.ui.UIListView.new({
						viewRect = cc.rect(0, 0, var_15_4.width, var_15_4.height),
						padding_ = {
							top = 0,
							bottom = 0,
							left = 0,
							right = 0
						},
						direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
					}):addTo(arg_14_0.helpItem:getChildByName("right_container"):getChildByName("helpList"))

					var_15_5:setBounceable(true)
					arg_14_0:updateRightPrivilegeItems(var_15_5)
				else
					arg_14_0.helpItem:getChildByName("list"):setVisible(false)
					arg_14_0.helpItem:getChildByName("container"):setVisible(true)
					arg_14_0.helpItem:getChildByName("right_container"):setVisible(false)
					arg_14_0.helpItem:getChildByName("middle_container"):setVisible(true)
					arg_14_0.helpItem:getChildByName("middle_container"):getChildByName("arrow"):setVisible(true)

					local var_15_6 = var_0_16:getPrivilegeIds()
					local var_15_7 = cc.ui.UIListView.new({
						viewRect = cc.rect(0, 0, 430, 345),
						padding_ = {
							top = 0,
							bottom = 0,
							left = 0,
							right = 0
						},
						direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
					}):addTo(arg_14_0.helpItem:getChildByName("middle_container"):getChildByName("helpList"))

					var_15_7:setBounceable(true)
					arg_14_0.helpItem:getChildByName("container"):getChildByName("bg_persent"):getChildByName("txt_persent"):setString(var_0_13:translation("VIP_WINDOW_TEXT_19"))
					arg_14_0.helpItem:getChildByName("container"):getChildByName("container_crystal"):getChildByName("txt_crystal"):setString(var_0_13:translation("VIP_WINDOW_TEXT_17"))
					arg_14_0.helpItem:getChildByName("middle_container"):getChildByName("txt_monthly_privilege"):setString(var_0_13:translation("VIP_WINDOW_TEXT_18"))

					local var_15_8

					if arg_14_0.privilegeLeftCardTimes > 0 then
						var_15_8 = string.format(var_0_13:translation("MONTHCARD_TAKEEFFECT"), arg_14_0.privilegeLeftCardTimes)
					else
						var_15_8 = ""
					end

					arg_14_0.helpItem:getChildByName("container"):getChildByName("desc"):setString(var_15_8)

					local var_15_9 = xyd.SpriteLoader.new("images/vip_recharge/month_card_privilege.png", nil, nil, xyd.DefaultImageType.CHARGE)

					var_15_9:setAnchorPoint(cc.p(0.5, 0.5))
					arg_14_0.helpItem:getChildByName("container"):getChildByName("img_gift"):addChild(var_15_9)

					local var_15_10 = var_0_16:getPrivilegeIds()

					arg_14_0.charge = var_0_16:charge(var_15_10[1])

					arg_14_0.helpItem:getChildByName("container"):getChildByName("btn_buy"):getChildByName("txt_price"):setString(arg_14_0.charge .. var_0_13:translation("VIP_WINDOW_TEXT_13"))
					arg_14_0.helpItem:getChildByName("middle_container"):getChildByName("txt_monthly_privilege"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
					arg_14_0.helpItem:getChildByName("container"):getChildByName("container_crystal"):getChildByName("txt_crystal"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
					arg_14_0.helpItem:setPosition(0, 0)
					arg_14_0.helpItem:setAnchorPoint(cc.p(0, 0))
					arg_14_0.helpItem:getChildByName("container"):getChildByName("btn_buy"):addTouchEventListener(function(arg_19_0, arg_19_1)
						if arg_19_1 == ccui.TouchEventType.began then
							arg_14_0.helpItem:getChildByName("container"):getChildByName("btn_buy"):setScale(0.9, 0.9)
						end

						if arg_19_1 == ccui.TouchEventType.moved then
							arg_14_0.helpItem:getChildByName("container"):getChildByName("btn_buy"):setScale(1, 1)
						end

						if arg_19_1 == ccui.TouchEventType.ended then
							arg_14_0.helpItem:getChildByName("container"):getChildByName("btn_buy"):setScale(1, 1)

							local var_19_0 = xyd.WindowManager.get():getWindow("vip_recharge")

							if var_19_0 and not var_19_0.scrollViewMoved_ then
								dump(var_15_10[1])
								var_19_0:purchase(var_15_10[1])
							end
						end
					end)
					arg_14_0:updatePrivilegeItems(var_15_7)
				end
			else
				arg_14_0.helpItem:setVisible(true)
			end
		end

		arg_14_0:init()
		arg_14_0:initWindowByState()
	end)
end

function var_0_0.init(arg_20_0)
	arg_20_0.hasCharged = arg_20_0.selfPlayer.charge

	arg_20_0:initVipNum()

	if arg_20_0.selfPlayer.vip < 15 then
		arg_20_0:nodeByName(var_0_0.NEED_COST):setString(xyd.tables.vip:chargeReq(arg_20_0.selfPlayer.vip + 1) - arg_20_0.hasCharged)
		arg_20_0:nodeByName(var_0_0.PROGRESS_BAR):setPercent(arg_20_0.hasCharged / xyd.tables.vip:chargeReq(arg_20_0.selfPlayer.vip + 1) * 100)
		arg_20_0:nodeByName(var_0_0.RECHARGE_RATIO):setString(arg_20_0.hasCharged .. "/" .. xyd.tables.vip:chargeReq(arg_20_0.selfPlayer.vip + 1))
	else
		arg_20_0:nodeByName(var_0_0.NEED_COST):setVisible(false)
		arg_20_0:nodeByName("vip01_img"):setVisible(false)
		arg_20_0:nodeByName("can_be_txt"):setVisible(false)
		arg_20_0:nodeByName("need_buy_crystal_txt"):setVisible(false)
		arg_20_0:nodeByName(var_0_0.PROGRESS_BAR):setPercent(arg_20_0.hasCharged / xyd.tables.vip:chargeReq(arg_20_0.selfPlayer.vip) * 100)
		arg_20_0:nodeByName(var_0_0.RECHARGE_RATIO):setString(arg_20_0.hasCharged .. "/" .. xyd.tables.vip:chargeReq(arg_20_0.selfPlayer.vip))
	end
end

function var_0_0.didOpen(arg_21_0, arg_21_1)
	var_0_0.super:didOpen(arg_21_1)
	arg_21_0:nodeByName(var_0_0.PRIVILEGE_BTN):addTouchEventListener(function(arg_22_0, arg_22_1)
		arg_21_0:buttonHandler(handler(arg_21_0, arg_21_0.changeWindowState), arg_22_0, arg_22_1)
	end)

	local var_21_0 = true

	arg_21_0.left:addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.began then
			arg_21_0.left:setScale(0.9, 0.9)
		end

		if arg_23_1 == ccui.TouchEventType.moved then
			arg_21_0.left:setScale(1, 1)
		end

		if arg_23_1 == ccui.TouchEventType.ended and arg_21_0.middleLev ~= 1 and var_21_0 then
			arg_21_0.left:setScale(1, 1)

			var_21_0 = false
			arg_21_0.middleLev = arg_21_0.middleLev - 1
			arg_21_0.leftLev = arg_21_0.middleLev - 1
			arg_21_0.rightLev = arg_21_0.middleLev + 1

			arg_21_0:setVipString()

			if arg_21_0.leftLev <= 0 then
				arg_21_0:nodeByName("left_container"):setVisible(false)
				arg_21_0:nodeByName("left_btn"):setVisible(false)
			else
				arg_21_0:nodeByName("left_container"):setVisible(true)
				arg_21_0:nodeByName("left_btn"):setVisible(true)
			end

			if arg_21_0.rightLev > xyd.tables.vip:vipLevel(#xyd.tables.vip.vipLev_) then
				arg_21_0:nodeByName("right_container"):setVisible(false)
				arg_21_0:nodeByName("right_btn"):setVisible(false)
			else
				arg_21_0:nodeByName("right_container"):setVisible(true)
				arg_21_0:nodeByName("right_btn"):setVisible(true)
			end

			arg_21_0.leftHelpItem = xyd.AssetLoader.get():loadNodeFromJson("windows/vipwindow/vip_help_item.csb")

			arg_21_0.leftHelpItem:addTo(arg_21_0.clippingNode)
			arg_21_0.leftHelpItem:setVisible(false)
			arg_21_0:initVipAward(arg_21_0.leftHelpItem:getChildByName("container"), arg_21_0.middleLev)

			local var_23_0 = cc.ui.UIListView.new({
				viewRect = cc.rect(0, 0, 430, 415),
				padding_ = {
					top = 0,
					bottom = 0,
					left = 0,
					right = 0
				},
				direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
			}):addTo(arg_21_0.leftHelpItem:getChildByName("container"):getChildByName("helpList"))

			var_23_0:setBounceable(true)
			arg_21_0.leftHelpItem:setPosition(-700, 0)
			arg_21_0.leftHelpItem:setAnchorPoint(cc.p(0, 0))
			arg_21_0:updateVipHelpItems(var_23_0, arg_21_0.middleLev)
			transition.moveBy(arg_21_0.middleHelpItem, {
				time = 0.1,
				x = 700,
				y = 0,
				onComplete = function()
					arg_21_0.middleHelpItem:removeAllChildren()

					arg_21_0.middleHelpItem = nil
					arg_21_0.middleHelpItem = arg_21_0.leftHelpItem

					arg_21_0.leftHelpItem:setVisible(true)
					transition.moveBy(arg_21_0.leftHelpItem, {
						time = 0.1,
						x = 700,
						y = 0
					})

					var_21_0 = true
				end
			})
		end
	end)

	local var_21_1 = true

	arg_21_0.right:addTouchEventListener(function(arg_25_0, arg_25_1)
		if arg_25_1 == ccui.TouchEventType.began then
			arg_21_0.right:setScale(0.9, 0.9)
		end

		if arg_25_1 == ccui.TouchEventType.moved then
			arg_21_0.right:setScale(1, 1)
		end

		if arg_25_1 == ccui.TouchEventType.ended and var_21_1 and arg_21_0.middleLev ~= 15 then
			arg_21_0.right:setScale(1, 1)

			var_21_1 = false
			arg_21_0.middleLev = arg_21_0.middleLev + 1
			arg_21_0.leftLev = arg_21_0.middleLev - 1
			arg_21_0.rightLev = arg_21_0.middleLev + 1

			arg_21_0:setVipString()

			if arg_21_0.leftLev <= 0 then
				arg_21_0:nodeByName("left_container"):setVisible(false)
				arg_21_0:nodeByName("left_btn"):setVisible(false)
			else
				arg_21_0:nodeByName("left_container"):setVisible(true)
				arg_21_0:nodeByName("left_btn"):setVisible(true)
			end

			if arg_21_0.rightLev > xyd.tables.vip:vipLevel(#xyd.tables.vip.vipLev_) then
				arg_21_0:nodeByName("right_container"):setVisible(false)
				arg_21_0:nodeByName("right_btn"):setVisible(false)
			else
				arg_21_0:nodeByName("right_container"):setVisible(true)
				arg_21_0:nodeByName("right_btn"):setVisible(true)
			end

			arg_21_0.rightHelpItem = xyd.AssetLoader.get():loadNodeFromJson("windows/vipwindow/vip_help_item.csb")

			arg_21_0.rightHelpItem:addTo(arg_21_0.clippingNode)
			arg_21_0:initVipAward(arg_21_0.rightHelpItem:getChildByName("container"), arg_21_0.middleLev)

			local var_25_0 = cc.ui.UIListView.new({
				viewRect = cc.rect(0, 0, 430, 415),
				padding_ = {
					top = 0,
					bottom = 0,
					left = 0,
					right = 0
				},
				direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
			}):addTo(arg_21_0.rightHelpItem:getChildByName("container"):getChildByName("helpList"))

			var_25_0:setBounceable(true)
			arg_21_0.rightHelpItem:setPosition(700, 0)
			arg_21_0.rightHelpItem:setAnchorPoint(cc.p(0, 0))
			arg_21_0:updateVipHelpItems(var_25_0, arg_21_0.middleLev)
			transition.moveBy(arg_21_0.middleHelpItem, {
				time = 0.1,
				x = -700,
				y = 0,
				onComplete = function()
					arg_21_0.middleHelpItem:removeAllChildren()

					arg_21_0.middleHelpItem = nil
					arg_21_0.middleHelpItem = arg_21_0.rightHelpItem

					transition.moveBy(arg_21_0.rightHelpItem, {
						time = 0.1,
						x = -700,
						y = 0
					})

					var_21_1 = true
				end
			})
		end
	end)
	arg_21_0:addBlockLayerWithNoTouchEvent()
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RIGHT_PULL
	})
	arg_21_0:nodeByName("btn_diamond"):addTouchEventListener(function(arg_27_0, arg_27_1)
		if arg_27_1 == ccui.TouchEventType.ended then
			arg_21_0.chargeState = xyd.ChargeState.diamond

			arg_21_0:update()
		end
	end)
	arg_21_0:nodeByName("btn_giftbag"):addTouchEventListener(function(arg_28_0, arg_28_1)
		if arg_28_1 == ccui.TouchEventType.ended then
			arg_21_0.chargeState = xyd.ChargeState.giftbag

			arg_21_0:update()
		end
	end)
	arg_21_0:nodeByName("btn_hero"):addTouchEventListener(function(arg_29_0, arg_29_1)
		if arg_29_1 == ccui.TouchEventType.ended then
			arg_21_0.chargeState = xyd.ChargeState.hero

			arg_21_0:update()
		end
	end)
	arg_21_0:nodeByName("btn_privilege"):addTouchEventListener(function(arg_30_0, arg_30_1)
		if arg_30_1 == ccui.TouchEventType.ended then
			arg_21_0.chargeState = xyd.ChargeState.monthlyPrivilege

			arg_21_0:update()
		end
	end)
end

function var_0_0.initVipAward(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0 = 10
	local var_31_1 = 200
	local var_31_2 = 95
	local var_31_3 = (var_31_1 - #arg_31_0.awards[arg_31_2] * var_31_2 - (#arg_31_0.awards[arg_31_2] - 1) * var_31_0) / 2

	arg_31_1:getChildByName("award_container"):removeAllChildren()

	for iter_31_0, iter_31_1 in pairs(arg_31_0.awards[arg_31_2]) do
		local var_31_4 = xyd.tables.item:type(iter_31_1)
		local var_31_5 = display.newNode()

		var_31_5:setContentSize(var_31_2, var_31_2)
		var_31_5:setAnchorPoint(cc.p(0, 0))
		var_31_5:addTo(arg_31_1:getChildByName("award_container"))
		xyd.setItemBorder(var_31_5, iter_31_1, nil, nil, arg_31_0.awardNums[arg_31_2][iter_31_0])
		var_31_5:setPosition((iter_31_0 - 1) % 2 * (var_31_2 + var_31_0), math.floor((iter_31_0 - 1) / 2) * (var_31_2 + var_31_0))
		var_31_5:setTouchEnabled(true)

		local var_31_6 = {
			id = iter_31_1
		}

		arg_31_0:addTips(var_31_5, var_31_6)
	end

	arg_31_1:getChildByName("gain_btn"):setGlobalZOrder(100)
	arg_31_0:initVipAwardBtnState(arg_31_1:getChildByName("gain_btn"), arg_31_2, arg_31_1)
end

function var_0_0.initVipAwardBtnState(arg_32_0, arg_32_1, arg_32_2, arg_32_3)
	local var_32_0 = arg_32_0.selfPlayer.vipAwards

	if arg_32_2 > arg_32_0.selfPlayer.vip or not var_32_0 or not next(var_32_0) then
		arg_32_1:setVisible(false)
		arg_32_3:getChildByName("gain_btn"):getChildByName("already_get_gray"):setVisible(false)
		arg_32_3:getChildByName("gain_btn"):getChildByName("get_txt"):setVisible(false)
	else
		arg_32_1:setVisible(true)

		if var_32_0[arg_32_2] == 1 then
			arg_32_1:setTouchEnabled(false)
			arg_32_1:setBright(false)
			arg_32_3:getChildByName("gain_btn"):getChildByName("already_get_gray"):setVisible(true)
			arg_32_3:getChildByName("gain_btn"):getChildByName("get_txt"):setVisible(false)
		else
			arg_32_1:setTouchEnabled(true)
			arg_32_1:setBright(true)
			arg_32_3:getChildByName("gain_btn"):getChildByName("already_get_gray"):setVisible(false)
			arg_32_3:getChildByName("gain_btn"):getChildByName("get_txt"):setVisible(true)
			arg_32_1:addTouchEventListener(function(arg_33_0, arg_33_1)
				if arg_33_1 == ccui.TouchEventType.began then
					arg_32_1:setScale(0.9, 0.9)
				end

				if arg_33_1 == ccui.TouchEventType.moved then
					arg_32_1:setScale(1, 1)
				end

				if arg_33_1 == ccui.TouchEventType.ended then
					arg_32_1:setScale(1, 1)

					local var_33_0 = {
						id = arg_32_2
					}

					xyd.Backend.get():request(xyd.mid.GET_VIP_AWARD, var_33_0, function(arg_34_0, arg_34_1)
						if arg_34_0 == xyd.error.OK and arg_34_1.awards then
							if not arg_32_0.selfPlayer then
								return
							end

							arg_32_0.selfPlayer:handleRewards(arg_34_1.awards)

							arg_32_0.selfPlayer.vipAwards[arg_32_2] = 1

							arg_32_0:initVipAwardBtnState(arg_32_1, arg_32_2, arg_32_3)

							local var_34_0 = xyd.WindowManager.get():getWindow("player_info")

							if var_34_0 then
								var_34_0:updateRedPointShow()
							end
						end
					end)
				end
			end)
		end
	end
end

function var_0_0.buttonHandler(arg_35_0, arg_35_1, arg_35_2, arg_35_3)
	if arg_35_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_35_2)
		arg_35_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound("sound/button.ogg", false)

		if arg_35_1 then
			arg_35_1(arg_35_2, arg_35_3)
		end
	elseif arg_35_3 == ccui.TouchEventType.began then
		arg_35_2:setScale(0.9)

		return true
	elseif arg_35_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_35_2)
		arg_35_2:setScale(1)
	end
end

function var_0_0.returnCallBack(arg_36_0)
	xyd.WindowManager.get():closeWindow("vip_recharge")
end

function var_0_0.changeWindowState(arg_37_0)
	if arg_37_0.windowState then
		arg_37_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.VIP_PRIVILEGE)
	end

	arg_37_0.windowState = not arg_37_0.windowState

	arg_37_0:initWindowByState()
end

function var_0_0.initWindowByState(arg_38_0)
	if arg_38_0.windowState == true then
		arg_38_0:nodeByName("vip_privilege_img"):setVisible(true)
		arg_38_0:nodeByName("recharge_img"):setVisible(false)
		arg_38_0:nodeByName("charge_container"):setVisible(true)
		arg_38_0:changeChargeState()
		arg_38_0.privilegeContainer:setVisible(false)
		arg_38_0:nodeByName("helpInfo"):setVisible(false)

		if arg_38_0.middleHelpItem then
			arg_38_0.middleHelpItem:removeAllChildren()
		end

		arg_38_0.listView_:reload()
	else
		arg_38_0:nodeByName("vip_privilege_img"):setVisible(false)
		arg_38_0:nodeByName("recharge_img"):setVisible(true)
		arg_38_0:nodeByName("charge_container"):setVisible(false)
		arg_38_0.privilegeContainer:setVisible(true)
		arg_38_0:nodeByName("helpInfo"):setVisible(true)

		if arg_38_0.fistOpen then
			-- block empty
		else
			arg_38_0.middleLev = arg_38_0.selfPlayer.vip
		end

		arg_38_0:updateVipHelpView()
	end
end

function var_0_0.listDelegate(arg_39_0, arg_39_1, arg_39_2, arg_39_3)
	if arg_39_2 == cc.ui.UIListView.COUNT_TAG then
		return #arg_39_0.listData
	elseif cc.ui.UIListView.CELL_TAG == arg_39_2 then
		local var_39_0 = arg_39_0.listView_:dequeueItem()

		if not var_39_0 then
			var_39_0 = arg_39_0.listView_:newItem()
		else
			var_39_0:removeAllChildren(true)
		end

		local var_39_1 = display.newNode()
		local var_39_2 = import("app.windows.VipRechargeItem").new()

		if arg_39_0.chargeState ~= xyd.ChargeState.diamond then
			local var_39_3 = arg_39_0.listData[arg_39_3].charge_id
			local var_39_4 = {
				iconUrl = "images/vip_recharge/bg_gift_bag_common.png",
				giftData = arg_39_0.listData[arg_39_3],
				chargeId = var_39_3,
				chargeName = var_0_17:chargeNameNew(var_39_3),
				charge = var_0_17:charge(var_39_3),
				iconNew = var_0_17:iconNew(var_39_3),
				percent = var_0_17:totalValue(var_39_3),
				time = arg_39_0.listData[arg_39_3].end_time - xyd.ServerTime.get():getServerTime(),
				chargeState = arg_39_0.chargeState,
				beforeId = var_0_16:beforeId(var_39_3)
			}

			var_39_2:setParams(var_39_4)
		else
			local var_39_5 = arg_39_0.listData[arg_39_3]
			local var_39_6 = {
				chargeId = var_39_5,
				chargeName = var_0_16:chargeNameNew(var_39_5),
				charge = var_0_16:charge(var_39_5),
				monthCard = var_0_16:monthCard(var_39_5),
				iconUrl = var_0_16:iconUrl(var_39_5),
				iconNew = var_0_16:iconNew(var_39_5),
				monthCardLeftTimes = arg_39_0.monthCardLeftTimes,
				weekCardLeftTimes = arg_39_0.weekCardLeftTimes,
				energyMonthCardLeftTimes = arg_39_0.energyMonthCardLeftTimes,
				privilegeLeftCardTimes = arg_39_0.privilegeLeftCardTimes,
				diamond = var_0_16:diamond(var_39_5),
				chargeState = arg_39_0.chargeState,
				cardType = var_0_16:cardType(var_39_5),
				beforeId = var_0_16:beforeId(var_39_5)
			}

			if arg_39_0.vipChargeData[var_39_5] and arg_39_0.vipChargeData[var_39_5] > 0 then
				var_39_6.extraDiamond = var_0_16:extraDiamond(var_39_5)
				var_39_6.onlyOnce = 0
				var_39_6.recommend = var_0_16:recommend(arg_39_0.listData[arg_39_3])
			else
				var_39_6.extraDiamond = var_0_16:firstExtraDiamond(var_39_5)
				var_39_6.onlyOnce = 1
				var_39_6.recommend = var_0_16:firstRecommend(arg_39_0.listData[arg_39_3])
			end

			var_39_2:setParams(var_39_6)
		end

		var_39_1:addChild(var_39_2)
		var_39_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_39_1:setContentSize(204, 471)
		var_39_0:addContent(var_39_1)
		var_39_0:setItemSize(220, 480)

		return var_39_0
	end
end

function var_0_0.priListDelegate(arg_40_0, arg_40_1, arg_40_2, arg_40_3)
	if arg_40_2 == cc.ui.UIListView.COUNT_TAG then
		return #arg_40_0.priListData
	elseif cc.ui.UIListView.CELL_TAG == arg_40_2 then
		local var_40_0 = arg_40_0.priListView_:dequeueItem()

		if not var_40_0 then
			var_40_0 = arg_40_0.priListView_:newItem()
		else
			var_40_0:removeAllChildren(true)
		end

		local var_40_1 = display.newNode()
		local var_40_2 = import("app.windows.VipRechargeItem").new()

		if arg_40_0.chargeState ~= xyd.ChargeState.monthlyPrivilege then
			local var_40_3 = arg_40_0.priListData[arg_40_3].charge_id
			local var_40_4 = {
				iconUrl = "images/vip_recharge/bg_gift_bag_common.png",
				giftData = arg_40_0.priListData[arg_40_3],
				chargeId = var_40_3,
				chargeName = var_0_17:chargeNameNew(var_40_3),
				charge = var_0_17:charge(var_40_3),
				iconNew = var_0_17:iconNew(var_40_3),
				percent = var_0_17:totalValue(var_40_3),
				time = arg_40_0.priListData[arg_40_3].end_time - xyd.ServerTime.get():getServerTime(),
				chargeState = arg_40_0.chargeState,
				cardType = var_0_16:cardType(var_40_3),
				beforeId = var_0_16:beforeId(var_40_3)
			}

			var_40_2:setParams(var_40_4)
		else
			local var_40_5 = arg_40_0.priListData[arg_40_3]
			local var_40_6 = {
				chargeId = var_40_5,
				chargeName = var_0_16:chargeNameNew(var_40_5),
				charge = var_0_16:charge(var_40_5),
				monthCard = var_0_16:monthCard(var_40_5),
				iconUrl = var_0_16:iconUrl(var_40_5),
				iconNew = var_0_16:iconNew(var_40_5),
				monthCardLeftTimes = arg_40_0.monthCardLeftTimes,
				weekCardLeftTimes = arg_40_0.weekCardLeftTimes,
				energyMonthCardLeftTimes = arg_40_0.energyMonthCardLeftTimes,
				privilegeLeftCardTimes = arg_40_0.privilegeLeftCardTimes,
				diamond = var_0_16:diamond(var_40_5),
				chargeState = arg_40_0.chargeState,
				cardType = var_0_16:cardType(var_40_5),
				beforeId = var_0_16:beforeId(var_40_5)
			}

			if arg_40_0.vipChargeData[var_40_5] and arg_40_0.vipChargeData[var_40_5] > 0 then
				var_40_6.extraDiamond = var_0_16:extraDiamond(var_40_5)
				var_40_6.onlyOnce = 0
				var_40_6.recommend = var_0_16:recommend(arg_40_0.priListData[arg_40_3])
			else
				var_40_6.extraDiamond = var_0_16:firstExtraDiamond(var_40_5)
				var_40_6.onlyOnce = 1
				var_40_6.recommend = var_0_16:firstRecommend(arg_40_0.priListData[arg_40_3])
			end

			var_40_2:setParams(var_40_6)
		end

		var_40_1:addChild(var_40_2)
		var_40_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_40_1:setContentSize(204, 471)
		var_40_0:addContent(var_40_1)
		var_40_0:setItemSize(220, 480)

		return var_40_0
	end
end

function var_0_0.purchase(arg_41_0, arg_41_1)
	local var_41_0 = true
	local var_41_1 = {}
	local var_41_2, var_41_3 = arg_41_0:getNewIDs(arg_41_1)
	local var_41_4 = tonumber(arg_41_0.selfPlayer.lastbuyTimes[var_0_8]) or 0
	local var_41_5 = tonumber(xyd.ServerTime.get():getServerTime() - var_41_4)
	local var_41_6 = math.floor(var_41_5 / 86400)
	local var_41_7 = tonumber(arg_41_0.selfPlayer.lastbuyTimes[var_0_9]) or 0
	local var_41_8 = tonumber(xyd.ServerTime.get():getServerTime() - var_41_7)
	local var_41_9 = math.floor(var_41_8 / 86400)
	local var_41_10 = xyd.tables.misc.monthCardTime2
	local var_41_11 = xyd.tables.misc.seasonPrivilegeCard
	local var_41_12 = xyd.tables.misc.halfyearPrivilegeCard

	if var_0_16:buyLimit(var_0_8) == 1 then
		if var_41_11 <= var_41_6 then
			table.insert(var_41_1, var_0_8)
		end
	else
		table.insert(var_41_1, var_0_8)
	end

	if var_0_16:buyLimit(var_0_9) == 1 then
		if var_41_12 <= var_41_9 then
			table.insert(var_41_1, var_0_9)
		end
	else
		table.insert(var_41_1, var_0_9)
	end

	table.insert(var_41_1, var_0_4)
	table.insert(var_41_1, var_0_5)

	if arg_41_0.selfPlayer.leftEnergyMonthCardDay <= 30 then
		table.insert(var_41_1, var_0_6)
	end

	table.insert(var_41_1, var_0_7)
	table.insert(var_41_1, var_0_10)
	table.insert(var_41_1, var_0_11)
	table.insert(var_41_1, var_0_12)

	if device.platform == "android" then
		if arg_41_1 == var_0_8 and var_0_16:buyLimit(arg_41_1) == 1 and var_41_6 < var_41_11 then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
				string.format(var_0_13:translation("DIAMOND_CAN_BUY"), var_0_13:translation("DIAMOND_SEASONCARD"))
			}, nil, nil, nil, arg_41_0.colorMode)

			return
		elseif arg_41_1 == var_0_9 and var_0_16:buyLimit(arg_41_1) == 1 and var_41_9 < var_41_12 then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
				string.format(var_0_13:translation("DIAMOND_CAN_BUY"), var_0_13:translation("DIAMOND_HALF_YEAR_CARD"))
			}, nil, nil, nil, arg_41_0.colorMode)

			return
		elseif arg_41_1 == var_0_6 and arg_41_0.selfPlayer.leftEnergyMonthCardDay > 30 then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
				var_0_13:translation("ENERGY_MONTH_CARD_BUY")
			}, nil, nil, nil, arg_41_0.colorMode)

			return
		else
			local var_41_13 = var_41_3 and var_0_16:chargeDoubleName(arg_41_1) or var_0_16:chargeName(arg_41_1)

			xyd.androidPurchase(var_41_1, var_41_2, arg_41_1, var_41_3, var_0_16:charge(arg_41_1), var_41_13, var_0_16:diamond(arg_41_1))
		end
	elseif device.platform == "ios" then
		if arg_41_1 == var_0_8 and var_0_16:buyLimit(arg_41_1) == 1 and var_41_6 < var_41_11 then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
				string.format(var_0_13:translation("DIAMOND_CAN_BUY"), var_0_13:translation("DIAMOND_SEASONCARD"))
			}, nil, nil, nil, arg_41_0.colorMode)

			return
		elseif arg_41_1 == var_0_9 and var_0_16:buyLimit(arg_41_1) == 1 and var_41_9 < var_41_12 then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
				string.format(var_0_13:translation("DIAMOND_CAN_BUY"), var_0_13:translation("DIAMOND_HALF_YEAR_CARD"))
			}, nil, nil, nil, arg_41_0.colorMode)

			return
		elseif arg_41_1 == var_0_6 and arg_41_0.selfPlayer.leftEnergyMonthCardDay > 30 then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
				var_0_13:translation("ENERGY_MONTH_CARD_BUY")
			}, nil, nil, nil, arg_41_0.colorMode)

			return
		else
			local var_41_14, var_41_15 = var_0_16:iosProductID(arg_41_1), xyd.sdkPurchase
			local var_41_16 = var_41_0
			local var_41_17 = arg_41_1
			local var_41_18 = var_41_2
			local var_41_19 = var_41_1
			local var_41_20

			var_41_20 = (arg_41_1 == var_0_6 or arg_41_1 == var_0_7 or arg_41_1 == var_0_8 or arg_41_1 == var_0_9 or arg_41_1 == var_0_10 or arg_41_1 == var_0_11 or arg_41_1 == var_0_12 or arg_41_1 == var_0_5) and {
				arg_41_1
			}

			var_41_15(var_41_14, var_41_16, var_41_17, var_41_18, var_41_19, var_41_20)
		end
	elseif arg_41_1 == var_0_8 and var_0_16:buyLimit(arg_41_1) == 1 and var_41_6 < var_41_11 then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
			string.format(var_0_13:translation("DIAMOND_CAN_BUY"), var_0_13:translation("DIAMOND_SEASONCARD"))
		}, nil, nil, nil, arg_41_0.colorMode)

		return
	elseif arg_41_1 == var_0_9 and var_0_16:buyLimit(arg_41_1) == 1 and var_41_9 < var_41_12 then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
			string.format(var_0_13:translation("DIAMOND_CAN_BUY"), var_0_13:translation("DIAMOND_HALF_YEAR_CARD"))
		}, nil, nil, nil, arg_41_0.colorMode)

		return
	elseif arg_41_1 == var_0_6 and arg_41_0.selfPlayer.leftEnergyMonthCardDay > 30 then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
			var_0_13:translation("ENERGY_MONTH_CARD_BUY")
		}, nil, nil, nil, arg_41_0.colorMode)

		return
	else
		dump("buy")
	end
end

function var_0_0.purchaseGiftBag(arg_42_0, arg_42_1)
	local var_42_0 = true
	local var_42_1 = arg_42_0:getNewIDs()

	if device.platform == "android" then
		xyd.androidPurchase({
			arg_42_1
		}, var_42_1, arg_42_1, false, var_0_17:charge(arg_42_1), var_0_17:chargeName(arg_42_1))
	elseif device.platform == "ios" then
		local var_42_2 = var_0_17:iosProductID(arg_42_1)

		xyd.sdkPurchase(var_42_2, var_42_0, arg_42_1, {}, var_42_1, {
			arg_42_1
		})
	end
end

function var_0_0.getNewIDs(arg_43_0, arg_43_1)
	local var_43_0 = false
	local var_43_1 = {}

	for iter_43_0, iter_43_1 in pairs(arg_43_0.vipChargeData) do
		if tonumber(iter_43_1) == 0 and iter_43_0 ~= var_0_4 and iter_43_0 ~= var_0_5 and iter_43_0 ~= var_0_6 and iter_43_0 ~= var_0_8 and iter_43_0 ~= var_0_9 and iter_43_0 ~= var_0_7 and iter_43_0 ~= var_0_10 and iter_43_0 ~= var_0_11 and iter_43_0 ~= var_0_12 then
			if iter_43_0 == arg_43_1 then
				var_43_0 = true
			end

			table.insert(var_43_1, iter_43_0)
		end
	end

	return var_43_1, var_43_0
end

function var_0_0.updateVipHelpView(arg_44_0)
	arg_44_0.middleHelpItem = xyd.AssetLoader.get():loadNodeFromJson("windows/vipwindow/vip_help_item.csb")

	arg_44_0.middleHelpItem:addTo(arg_44_0.clippingNode)

	local var_44_0 = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 430, 415),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_44_0.middleHelpItem:getChildByName("container"):getChildByName("helpList"))

	var_44_0:setBounceable(true)

	if arg_44_0.middleLev == 0 then
		arg_44_0.middleLev = arg_44_0.middleLev + 1
		arg_44_0.rightLev = arg_44_0.middleLev + 1
		arg_44_0.leftLev = arg_44_0.middleLev - 1

		arg_44_0:nodeByName("left_container"):setVisible(false)
		arg_44_0:nodeByName("left_btn"):setVisible(false)
	elseif arg_44_0.middleLev == 1 then
		arg_44_0:nodeByName("left_container"):setVisible(false)
		arg_44_0:nodeByName("left_btn"):setVisible(false)
	elseif arg_44_0.middleLev == xyd.tables.vip:vipLevel(#xyd.tables.vip.vipLev_) then
		arg_44_0:nodeByName("right_container"):setVisible(false)
		arg_44_0:nodeByName("right_btn"):setVisible(false)
	end

	arg_44_0:setVipString()
	arg_44_0:initVipAward(arg_44_0.middleHelpItem:getChildByName("container"), arg_44_0.middleLev)
	arg_44_0:updateVipHelpItems(var_44_0, arg_44_0.middleLev)
end

function var_0_0.updateVipHelpItems(arg_45_0, arg_45_1, arg_45_2)
	arg_45_1:removeAllItems()

	if arg_45_1 == nil or type(arg_45_1) ~= "userdata" then
		print("params is invalid.")

		return
	end

	local var_45_0 = xyd.luaStringSplit(xyd.tables.vip:vipPrivilege(arg_45_2), "|")

	for iter_45_0 = 1, #var_45_0 do
		local var_45_1 = arg_45_1:newItem()
		local var_45_2 = var_45_0[iter_45_0]
		local var_45_3 = xyd.createMultiColorTxt(var_45_2, cc.c3b(229, 92, 119), 22)

		var_45_3:setContentSize(430, 31)
		var_45_1:addContent(var_45_3)
		var_45_1:setItemSize(430, 31)
		arg_45_1:addItem(var_45_1)
	end

	arg_45_1:reload()
end

function var_0_0.updatePrivilegeItems(arg_46_0, arg_46_1)
	arg_46_1:removeAllItems()

	if arg_46_1 == nil or type(arg_46_1) ~= "userdata" then
		print("params is invalid.")

		return
	end

	local var_46_0 = xyd.luaStringSplit(xyd.tables.monthlyPrivilege:monthlyPrivilege(1), "|")

	for iter_46_0 = 1, #var_46_0 do
		local var_46_1 = arg_46_1:newItem()
		local var_46_2 = var_46_0[iter_46_0]
		local var_46_3 = xyd.createMultiColorTxt(var_46_2, cc.c3b(229, 92, 119), 22)

		var_46_3:setContentSize(430, 31)
		var_46_1:addContent(var_46_3)
		var_46_1:setItemSize(430, 31)
		arg_46_1:addItem(var_46_1)
	end

	arg_46_1:reload()
end

function var_0_0.updateRightPrivilegeItems(arg_47_0, arg_47_1)
	arg_47_1:removeAllItems()

	if arg_47_1 == nil or type(arg_47_1) ~= "userdata" then
		print("params is invalid.")

		return
	end

	local var_47_0 = xyd.luaStringSplit(xyd.tables.monthlyPrivilege:monthlyPrivilege(2), "|")

	for iter_47_0 = 1, #var_47_0 do
		local var_47_1 = arg_47_1:newItem()
		local var_47_2 = var_47_0[iter_47_0]
		local var_47_3 = xyd.createMultiColorTxt(var_47_2, cc.c3b(229, 92, 119), 18)

		var_47_3:setContentSize(240, 31)
		var_47_1:addContent(var_47_3)
		var_47_1:setItemSize(240, 31)
		arg_47_1:addItem(var_47_1)
	end

	arg_47_1:reload()
end

function var_0_0.initVipNum(arg_48_0)
	if not arg_48_0.fistOpen then
		arg_48_0.middleLev = arg_48_0.selfPlayer.vip
		arg_48_0.leftLev = arg_48_0.selfPlayer.vip - 1
		arg_48_0.rightLev = arg_48_0.selfPlayer.vip + 1
	end

	arg_48_0:nodeByName("bg_top"):getChildByName("vip_lev"):setString(arg_48_0.middleLev)
	arg_48_0:nodeByName("bg_top"):getChildByName("vip_lev2"):setString(arg_48_0.rightLev)
	arg_48_0:setVipString()
end

function var_0_0.setVipString(arg_49_0)
	arg_49_0:nodeByName("bg_top_privilege"):getChildByName("vip_lev"):setString(arg_49_0.middleLev)
	arg_49_0:nodeByName("left_container"):getChildByName("vip_lev"):setString(arg_49_0.leftLev)
	arg_49_0:nodeByName("right_container"):getChildByName("vip_lev"):setString(arg_49_0.rightLev)
end

function var_0_0.didClose(arg_50_0, arg_50_1)
	if arg_50_0.handler then
		var_0_14.unscheduleGlobal(arg_50_0.handler)

		arg_50_0.handler = nil
	end

	if arg_50_0.callback then
		arg_50_0.callback()
	end

	if xyd.WindowManager.get():getWindow(xyd.WindowName.summonWnd) then
		return
	end

	if xyd.WindowManager.get():getWindow("activities") then
		return
	end

	if xyd.WindowManager.get():getWindow("map_window") then
		return
	end
end

function var_0_0.updateVipGiftData(arg_51_0, arg_51_1, arg_51_2)
	if arg_51_1 == xyd.error.OK and xyd.db.vipGiftData:isUpdated(arg_51_2) then
		xyd.db.vipGiftData:updateVipGiftData(arg_51_2)
	end
end

return var_0_0
