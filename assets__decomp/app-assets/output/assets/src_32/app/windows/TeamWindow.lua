local var_0_0 = class("TeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.WndTopSidebar")
local var_0_2 = import("app.common.ui.SpriteNodeButton")
local var_0_3 = require("framework.scheduler")
local var_0_4 = xyd.tables.translation
local var_0_5 = "skeletons/ui_effect/club_shop/club_shop"
local var_0_6 = import("app.common.ui.SpineEffect")
local var_0_7 = xyd.tables.translation
local var_0_8 = xyd.tables.guildBattleTable

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.arena = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)

	arg_1_0:setTouchSwallowEnabled(true)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initPicBtn()

	local var_2_0 = {
		colorMode = 4,
		isEcoBar = 0,
		parent = arg_2_0,
		title = xyd.tables.window:title(arg_2_0.name)
	}
	local var_2_1 = var_0_1.new(xyd.WidgetName.wndTopSidebar, var_2_0)

	var_2_1:setAnchorPoint(0, 1)
	var_2_1:addTo(arg_2_0:nodeByName("top_side_bar"))

	local var_2_2 = "windows/button/btn_add_eco.png"
	local var_2_3 = xyd.tables.systemColor:btnColors(4)
	local var_2_4 = {
		sprite = var_2_2,
		colorModes = var_2_3
	}

	arg_2_0.goldBuyBtn_ = var_0_2.new(var_2_4)

	arg_2_0.goldBuyBtn_:setAnchorPoint(0.5, 0.5)
	arg_2_0.goldBuyBtn_:addTo(arg_2_0:nodeByName("add_coin_btn"))
	arg_2_0.goldBuyBtn_:setName("coin_btn")
	arg_2_0.goldBuyBtn_:addTouchEvent(function(arg_3_0)
		if arg_3_0.name == "ended" then
			local var_3_0 = xyd.FunctionID.ID_GOLD_HAND

			if arg_2_0.selfPlayer:isFuncOpen(var_3_0) == true then
				xyd.playButtonSound()
				xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
			else
				local var_3_1 = xyd.tables.functionOpen:level(var_3_0)
				local var_3_2 = string.format(var_0_7:translation("FUNCTION_OPEN_TIP_LEVEL"), var_3_1)

				if xyd.WindowManager.get():getWindow("toast") ~= nil then
					xyd.WindowManager.get():closeWindow("toast")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_3_2
				})

				return true
			end
		end
	end)

	arg_2_0.addDiamondBtn_ = var_0_2.new(var_2_4)

	arg_2_0.addDiamondBtn_:setAnchorPoint(0.5, 0.5)
	arg_2_0.addDiamondBtn_:addTo(arg_2_0:nodeByName("add_diamond_btn"))
	arg_2_0.addDiamondBtn_:setName("crystal_btn")
	arg_2_0.addDiamondBtn_:addTouchEvent(function(arg_4_0)
		if arg_4_0.name == "ended" then
			arg_2_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.CHARGE)
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)

			return true
		end
	end)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:nodeByName("coin_num_text"):setString(xyd.num2ThousandsStr(arg_5_0.selfPlayer.mana))
	arg_5_0:nodeByName("diamond_num_text"):setString(xyd.num2ThousandsStr(arg_5_0.selfPlayer.crystal))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_5_0):addEventListener(xyd.event.ECONOMY, handler(arg_5_0, arg_5_0.updateEconomicInfo))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_5_0):addEventListener(xyd.event.DRINK_NOTIF, handler(arg_5_0, arg_5_0.updateGuildNotif))
	arg_5_0:nodeByName("red_point2"):setVisible(false)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_5_0):addEventListener(xyd.event.GUILD_APPLY_NOTICE, handler(arg_5_0, arg_5_0.updateGuildApplyNotif))
	arg_5_0:nodeByName("guild_notif"):setVisible(false)
	arg_5_0.guild:getTeaTalkInfo(function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK and arg_5_0 and not tolua.isnull(arg_5_0) then
			arg_5_0:updateGuildNotif()
		end
	end, {
		is_self = 1
	})
	arg_5_0:updateGuildNotif_()
	arg_5_0:updateGuildApplyNotif()

	if not arg_5_0.eyeEffect then
		local var_5_0 = var_0_5 .. ".json"
		local var_5_1 = var_0_5 .. ".atlas"

		arg_5_0.eyeEffect = var_0_6.new(var_5_0, var_5_1, 1)

		arg_5_0.eyeEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_5_0.eyeEffect:setPosition(0, 0)
		arg_5_0.eyeEffect:addTo(arg_5_0:nodeByName("effect_node"))
	end

	arg_5_0.eyeEffect:play(nil, true)
end

function var_0_0.updateGuildNotif_(arg_7_0)
	if arg_7_0.guild.teaTalkFinish then
		arg_7_0:nodeByName("guild_notif"):setVisible(true)
	else
		arg_7_0:nodeByName("guild_notif"):setVisible(false)
	end

	arg_7_0:nodeByName("war_notif"):setVisible(false)

	if arg_7_0.guild.warStep then
		local var_7_0 = var_0_8:season(arg_7_0.guild.warStep) or 0
		local var_7_1 = var_0_8:round(arg_7_0.guild.warStep) or 0
		local var_7_2 = var_0_8:step(arg_7_0.guild.warStep) or 0
		local var_7_3 = 0

		if var_7_2 == xyd.GuildWarStep.ENROLL then
			var_7_3 = var_7_0 * 100 + var_7_1 * 10 + 1
		elseif var_7_2 == xyd.GuildWarStep.PREPARE and arg_7_0.guild.isEnrollWar and arg_7_0.guild.isEnrollWar == 1 then
			var_7_3 = var_7_0 * 100 + var_7_1 * 10 + 2
		end

		if var_7_3 >= 111 and var_7_3 > xyd.db.guildWarRedPoint:getGuildWarRedPointData() then
			arg_7_0:nodeByName("war_notif"):setVisible(true)
		end
	end
end

function var_0_0.updateGuildNotif(arg_8_0, arg_8_1)
	if arg_8_0.guild.teaTalkFinish then
		arg_8_0:nodeByName("guild_notif"):setVisible(true)
	else
		arg_8_0:nodeByName("guild_notif"):setVisible(false)
	end

	arg_8_0:nodeByName("war_notif"):setVisible(false)

	if arg_8_0.guild.warStep then
		local var_8_0 = var_0_8:season(arg_8_0.guild.warStep) or 0
		local var_8_1 = var_0_8:round(arg_8_0.guild.warStep) or 0
		local var_8_2 = var_0_8:step(arg_8_0.guild.warStep) or 0
		local var_8_3 = 0

		if var_8_2 == xyd.GuildWarStep.ENROLL then
			var_8_3 = var_8_0 * 100 + var_8_1 * 10 + 1
		elseif var_8_2 == xyd.GuildWarStep.PREPARE and arg_8_0.guild.isEnrollWar and arg_8_0.guild.isEnrollWar == 1 then
			var_8_3 = var_8_0 * 100 + var_8_1 * 10 + 2
		end

		if var_8_3 >= 111 and var_8_3 > xyd.db.guildWarRedPoint:getGuildWarRedPointData() then
			arg_8_0:nodeByName("war_notif"):setVisible(true)
		end
	end
end

function var_0_0.updateEconomicInfo(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_1.params

	if var_9_0.mana ~= nil then
		arg_9_0:nodeByName("coin_num_text"):setString(var_9_0.mana)

		local var_9_1 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_9_2 = cc.Spawn:create(var_9_1)

		arg_9_0:nodeByName("coin_num_text"):runAction(var_9_2)
	end

	if var_9_0.crystal ~= nil then
		arg_9_0:nodeByName("diamond_num_text"):setString(var_9_0.crystal)

		local var_9_3 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_9_4 = cc.Spawn:create(var_9_3)

		arg_9_0:nodeByName("diamond_num_text"):runAction(var_9_4)
	end
end

function var_0_0.initPicBtn(arg_10_0)
	arg_10_0.iconNode = cc.Node:create()

	arg_10_0.iconNode:setContentSize(arg_10_0:nodeByName("icon_icon"):getWidth() / 2, arg_10_0:nodeByName("icon_icon"):getHeight() / 2 - 50)
	arg_10_0.iconNode:addTo(arg_10_0)
	arg_10_0.iconNode:setAnchorPoint(cc.p(0, 0))
	arg_10_0.iconNode:pos(arg_10_0:nodeByName("icon_icon"):getX() + arg_10_0:nodeByName("icon_icon"):getWidth() / 4, arg_10_0:nodeByName("icon_icon"):getY() + 80)
	arg_10_0.iconNode:setTouchEnabled(true)

	arg_10_0.dataNode = cc.Node:create()

	arg_10_0.dataNode:setContentSize(arg_10_0:nodeByName("data_icon"):getWidth() - 60, arg_10_0:nodeByName("data_icon"):getHeight() / 2 - 45)
	arg_10_0.dataNode:addTo(arg_10_0)
	arg_10_0.dataNode:setAnchorPoint(cc.p(0.5, 0.5))
	arg_10_0.dataNode:pos(arg_10_0:nodeByName("data_icon"):getX() + 5, arg_10_0:nodeByName("data_icon"):getY() + 45)
	arg_10_0.dataNode:setTouchEnabled(true)

	arg_10_0.teaNode = cc.Node:create()

	arg_10_0.teaNode:setContentSize(arg_10_0:nodeByName("tea_icon"):getWidth() * 3 / 4, arg_10_0:nodeByName("tea_icon"):getHeight())
	arg_10_0.teaNode:addTo(arg_10_0)
	arg_10_0.teaNode:setAnchorPoint(cc.p(0, 0))
	arg_10_0.teaNode:pos(arg_10_0:nodeByName("tea_icon"):getX() + arg_10_0:nodeByName("tea_icon"):getWidth() / 4, arg_10_0:nodeByName("tea_icon"):getY())
	arg_10_0.teaNode:setTouchEnabled(true)

	arg_10_0.activityNode = cc.Node:create()

	arg_10_0.activityNode:setContentSize(arg_10_0:nodeByName("activity_icon"):getWidth() / 2, arg_10_0:nodeByName("activity_icon"):getHeight() / 2)
	arg_10_0.activityNode:addTo(arg_10_0)
	arg_10_0.activityNode:setAnchorPoint(cc.p(0, 0))
	arg_10_0.activityNode:pos(arg_10_0:nodeByName("activity_icon"):getX() + 20, arg_10_0:nodeByName("activity_icon"):getY() + arg_10_0:nodeByName("activity_icon"):getHeight() / 2)
	arg_10_0.activityNode:setTouchEnabled(true)

	arg_10_0.shopNode = cc.Node:create()

	arg_10_0.shopNode:setContentSize(100, 270)
	arg_10_0.shopNode:addTo(arg_10_0)
	arg_10_0.shopNode:setAnchorPoint(cc.p(0, 0))
	arg_10_0.shopNode:pos(arg_10_0:nodeByName("effect_node"):getX() - 50, arg_10_0:nodeByName("effect_node"):getY())
	arg_10_0.shopNode:setTouchEnabled(true)
end

function var_0_0.layout(arg_11_0)
	local var_11_0 = xyd.STAGE_HEIGHT
	local var_11_1 = xyd.STAGE_WIDTH

	arg_11_0.container = arg_11_0:nodeByName("container")

	local var_11_2, var_11_3 = arg_11_0.container:getPosition()

	arg_11_0.container:setPosition(var_11_2, var_11_3)

	arg_11_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	local var_11_4 = arg_11_0.container:getChildByName("community_badge_btn")

	var_11_4:setTouchEnabled(true)
	var_11_4:addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(var_11_4, arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			arg_11_0:enterBadge()
		end
	end)
	arg_11_0.iconNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			return true
		elseif arg_13_0.name == "ended" then
			arg_11_0:enterBadge()
		end
	end)

	local var_11_5 = arg_11_0.container:getChildByName("community_log_btn")

	var_11_5:setTouchEnabled(true)
	var_11_5:addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(var_11_5, arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			arg_11_0:enterLog()
		end
	end)
	arg_11_0.dataNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
		if arg_15_0.name == "began" then
			return true
		elseif arg_15_0.name == "ended" then
			arg_11_0:enterLog()
		end
	end)

	local var_11_6 = arg_11_0.container:getChildByName("community_activities_btn")

	var_11_6:setTouchEnabled(true)
	var_11_6:addTouchEventListener(function(arg_16_0, arg_16_1)
		xyd.buttonScaleAnim(var_11_6, arg_16_1)

		if arg_16_1 == ccui.TouchEventType.ended then
			arg_11_0:enterActivities()
		end
	end)
	arg_11_0.activityNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
		if arg_17_0.name == "began" then
			return true
		elseif arg_17_0.name == "ended" then
			arg_11_0:enterActivities()
		end
	end)

	local var_11_7 = arg_11_0.container:getChildByName("afternoon_tea_btn")

	if arg_11_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_TEA_PARTY) then
		var_11_7:setTouchEnabled(true)
		var_11_7:setVisible(true)
		var_11_7:addTouchEventListener(function(arg_18_0, arg_18_1)
			xyd.buttonScaleAnim(var_11_7, arg_18_1)

			if arg_18_1 == ccui.TouchEventType.ended then
				arg_11_0:enterTea()
			end
		end)
		arg_11_0.teaNode:setVisible(true)
		arg_11_0.teaNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
			if arg_19_0.name == "began" then
				return true
			elseif arg_19_0.name == "ended" then
				arg_11_0:enterTea()
			end
		end)
	else
		var_11_7:setVisible(false)
		arg_11_0.teaNode:setVisible(false)
		arg_11_0:nodeByName("afternoon_tea_words"):setVisible(false)
	end

	local var_11_8 = arg_11_0.container:getChildByName("borrow_sister_btn")

	var_11_8:setTouchEnabled(true)
	var_11_8:addTouchEventListener(function(arg_20_0, arg_20_1)
		xyd.buttonScaleAnim(var_11_8, arg_20_1)

		if arg_20_1 == ccui.TouchEventType.ended then
			arg_11_0:enterBorrow()
		end
	end)
	arg_11_0:nodeByName("borrow_icon"):setTouchEnabled(true)
	arg_11_0:nodeByName("borrow_icon"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_21_0)
		if arg_21_0.name == "began" then
			return true
		elseif arg_21_0.name == "ended" then
			arg_11_0:enterBorrow()
		end
	end)

	if false then
		arg_11_0:nodeByName("war_btn"):setVisible(true)
		arg_11_0:nodeByName("war_btn"):addTouchEventListener(function(arg_22_0, arg_22_1)
			xyd.buttonScaleAnim(arg_11_0:nodeByName("war_btn"), arg_22_1)

			if arg_22_1 == ccui.TouchEventType.ended then
				arg_11_0:enterWar()
			end
		end)
		arg_11_0:nodeByName("war_icon"):setVisible(true)
		arg_11_0:nodeByName("war_icon"):setTouchEnabled(true)
		arg_11_0:nodeByName("war_icon"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
			if arg_23_0.name == "began" then
				return true
			elseif arg_23_0.name == "ended" then
				arg_11_0:enterWar()
			end
		end)
		arg_11_0:nodeByName("war_words"):setVisible(true)
	else
		arg_11_0:nodeByName("war_btn"):setVisible(false)
		arg_11_0:nodeByName("war_icon"):setVisible(false)
		arg_11_0:nodeByName("war_words"):setVisible(false)
	end

	arg_11_0:nodeByName("team_manage_btn"):setTouchEnabled(true)
	arg_11_0:nodeByName("team_manage_btn"):addTouchEventListener(function(arg_24_0, arg_24_1)
		xyd.buttonScaleAnim(arg_11_0:nodeByName("team_manage_btn"), arg_24_1)

		if arg_24_1 == ccui.TouchEventType.ended then
			arg_11_0:enterManage()
		end
	end)
	arg_11_0:nodeByName("manage_icon"):setTouchEnabled(true)
	arg_11_0:nodeByName("manage_icon"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_25_0)
		if arg_25_0.name == "began" then
			return true
		elseif arg_25_0.name == "ended" then
			arg_11_0:enterManage()
		end
	end)

	arg_11_0.ia = 0

	arg_11_0:nodeByName("test"):setTouchEnabled(true)
	arg_11_0:nodeByName("test"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_26_0)
		if arg_26_0.name == "began" then
			return true
		elseif arg_26_0.name == "ended" then
			arg_11_0.ia = arg_11_0.ia + 1

			if arg_11_0.ia == 3 then
				xyd.WindowManager.get():openWindow("toast", {
					message = "I LOVE YOU"
				})
			end
		end
	end)
	arg_11_0.shopNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_27_0)
		if arg_27_0.name == "began" then
			return true
		elseif arg_27_0.name == "ended" then
			xyd.playButtonSound()
			xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
				xyd.WindowManager.get():openWindow("shop", {
					shop_type = xyd.ShopType.GUILD
				})
				arg_11_0:nodeByName("panel_cup"):setVisible(false)
			end)
		end
	end)
	arg_11_0:nodeByName("shop_btn"):addTouchEventListener(function(arg_29_0, arg_29_1)
		xyd.buttonScaleAnim(arg_11_0:nodeByName("shop_btn"), arg_29_1)

		if arg_29_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
				xyd.WindowManager.get():openWindow("shop", {
					shop_type = xyd.ShopType.GUILD
				})
			end)
		end
	end)
	arg_11_0:nodeByName("cup_bg"):setTouchEnabled(true)
	arg_11_0:nodeByName("cup_bg"):addTouchEventListener(function(arg_31_0, arg_31_1)
		if arg_31_1 == ccui.TouchEventType.began then
			arg_11_0.tips = xyd.WindowManager.get():openWindow("team_active_icon_tip")

			arg_11_0.tips:setPosition(680, 450)
		elseif arg_31_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow("team_active_icon_tip")
		elseif arg_31_1 == 3 then
			xyd.WindowManager.get():closeWindow("team_active_icon_tip")
		end
	end)
	arg_11_0:addCoin()
	arg_11_0:addDiamond()
	arg_11_0:nodeByName("cup_num_text"):setString(xyd.num2ThousandsStr(arg_11_0.guild.self_all_huoyue))

	local var_11_9 = arg_11_0.container:getChildByName("bg")
end

function var_0_0.addCoin(arg_32_0)
	local var_32_0 = arg_32_0.container:getChildByName("panel_coin")

	arg_32_0.coinNum_ = var_32_0:getChildByName("coin_num_text")

	local function var_32_1(arg_33_0)
		if arg_33_0 == ccui.TouchEventType.began then
			return true
		elseif arg_33_0 == ccui.TouchEventType.ended then
			local var_33_0 = xyd.FunctionID.ID_GOLD_HAND

			if arg_32_0.selfPlayer:isFuncOpen(var_33_0) == true then
				xyd.playButtonSound()
				xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
			else
				local var_33_1 = xyd.tables.functionOpen:level(var_33_0)
				local var_33_2 = string.format(var_0_7:translation("FUNCTION_OPEN_TIP_LEVEL"), var_33_1)

				if xyd.WindowManager.get():getWindow("toast") ~= nil then
					xyd.WindowManager.get():closeWindow("toast")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_33_2
				})

				return true
			end
		end
	end

	var_32_0:getChildByName("coin_bg"):addTouchEventListener(function(arg_34_0, arg_34_1)
		var_32_1(arg_34_1)
	end)
end

function var_0_0.addDiamond(arg_35_0)
	local var_35_0 = arg_35_0.container:getChildByName("panel_diamond")

	arg_35_0.diamondNum_ = var_35_0:getChildByName("diamond_num_text")

	local function var_35_1(arg_36_0)
		if arg_36_0 == ccui.TouchEventType.began then
			return true
		elseif arg_36_0 == ccui.TouchEventType.ended then
			arg_35_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.CHARGE)
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
		end

		return true
	end

	var_35_0:getChildByName("diamond_bg"):addTouchEventListener(function(arg_37_0, arg_37_1)
		var_35_1(arg_37_1)
	end)
end

function var_0_0.showTop(arg_38_0, arg_38_1)
	arg_38_0:nodeByName("panel_cup"):setVisible(arg_38_1)
	arg_38_0:nodeByName("panel_diamond"):setVisible(arg_38_1)
	arg_38_0:nodeByName("panel_coin"):setVisible(arg_38_1)
end

function var_0_0.enterBadge(arg_39_0)
	if xyd.WindowManager.get():getWindow("shop") == nil then
		xyd.playButtonSound()

		local var_39_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.RANK_LIST)

		var_39_0:loadRankList({
			xyd.SubRankType.GUILD_RANK_INFO
		}, true, function(arg_40_0, arg_40_1)
			if arg_40_0 == xyd.error.OK then
				local var_40_0 = {
					rank_type = xyd.RankType.Guild,
					sub_type = xyd.SubRankType.GUILD_RANK_INFO,
					rankData = var_39_0:getRankList()
				}

				xyd.WindowManager.get():openWindow("new_rank_list", var_40_0)
			end
		end)
	end
end

function var_0_0.enterLog(arg_41_0)
	if xyd.WindowManager.get():getWindow("shop") == nil then
		xyd.playButtonSound()
		arg_41_0.guild:getData(function(arg_42_0, arg_42_1)
			if arg_42_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("team_data")
			end
		end)
	end
end

function var_0_0.enterActivities(arg_43_0)
	if xyd.WindowManager.get():getWindow("shop") == nil then
		xyd.playButtonSound()
		arg_43_0.guild:loadGuildCampaignList(function(arg_44_0)
			if arg_44_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("team_campaign_list")
			end
		end)
	end
end

function var_0_0.enterTea(arg_45_0)
	if xyd.WindowManager.get():getWindow("shop") == nil then
		xyd.playButtonSound()
		arg_45_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.TEA_TALK)
		arg_45_0.guild:getTeaTalkInfo(function(arg_46_0, arg_46_1)
			if arg_46_0 == xyd.error.OK then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.DRINK_NOTIF
				})
				xyd.WindowManager.get():openWindow("team_tea_talk")
			end
		end)
	end
end

function var_0_0.enterManage(arg_47_0)
	if xyd.WindowManager.get():getWindow("shop") == nil then
		xyd.playButtonSound()
		arg_47_0.guild:loadTeam(function(arg_48_0, arg_48_1)
			if arg_48_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("team_member_list")
			end
		end)
	end
end

function var_0_0.enterWar(arg_49_0)
	arg_49_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.GUILD_WAR)
	xyd.playButtonSound()
	arg_49_0.guild:loadGuildWarInfo(function(arg_50_0, arg_50_1)
		if arg_50_0 == xyd.error.OK then
			if not arg_49_0 or tolua.isnull(arg_49_0) then
				return
			end

			arg_49_0:nodeByName("war_notif"):setVisible(false)

			if arg_49_0.guild.warStep then
				local var_50_0 = var_0_8:season(arg_49_0.guild.warStep) or 0
				local var_50_1 = var_0_8:round(arg_49_0.guild.warStep) or 0
				local var_50_2 = var_0_8:step(arg_49_0.guild.warStep) or 0
				local var_50_3 = 0

				if var_50_2 == xyd.GuildWarStep.ENROLL then
					var_50_3 = var_50_0 * 100 + var_50_1 * 10 + 1
				elseif var_50_2 == xyd.GuildWarStep.PREPARE and arg_49_0.guild.isEnrollWar and arg_49_0.guild.isEnrollWar == 1 then
					var_50_3 = var_50_0 * 100 + var_50_1 * 10 + 2
				end

				if var_50_3 >= 111 and var_50_3 > xyd.db.guildWarRedPoint:getGuildWarRedPointData() then
					xyd.db.guildWarRedPoint:setGuildWarRedPointData(var_50_3)
				end

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.DRINK_NOTIF
				})
			end

			xyd.WindowManager.get():openWindow("guild_war")
		end
	end)
end

function var_0_0.enterBorrow(arg_51_0)
	arg_51_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.HIRE_HERO)

	if xyd.WindowManager.get():getWindow("shop") == nil then
		xyd.playButtonSound()
		arg_51_0.guild:loadSentHeros(function(arg_52_0)
			arg_51_0.guild:loadRentPets(function(arg_53_0)
				if arg_53_0 == xyd.error.OK then
					local var_53_0 = xyd.WindowManager.get():openWindow("hire_hero")
				end
			end)
		end)
	end
end

function var_0_0.willClose(arg_54_0, arg_54_1)
	var_0_0.super:willClose(arg_54_1)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.DRINK_NOTIF
	})
	xyd.WindowManager.get():closeWindow("team_active_icon_tip")
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {}
	})
end

function var_0_0.updateGuildApplyNotif(arg_55_0, arg_55_1)
	arg_55_0.guild:loadTeam(function(arg_56_0, arg_56_1)
		if arg_56_0 == xyd.error.OK then
			if not arg_55_0 or tolua.isnull(arg_55_0) then
				return
			end

			if arg_56_1 ~= nil then
				for iter_56_0, iter_56_1 in pairs(arg_56_1.members) do
					if arg_55_0.selfPlayer.playerID == iter_56_1.player_id then
						arg_55_0.job = iter_56_1.job

						break
					end
				end
			end

			if xyd.GuildJobType.LEADER == arg_55_0.job or xyd.GuildJobType.DEPUTY_LEADER == arg_55_0.job then
				arg_55_0.guild:loadAllApply(function(arg_57_0, arg_57_1)
					if arg_57_1 ~= nil and #arg_57_1 ~= 0 then
						arg_55_0:nodeByName("red_point2"):setVisible(true)
					else
						arg_55_0:nodeByName("red_point2"):setVisible(false)
					end
				end)
			end
		end
	end)
end

return var_0_0
