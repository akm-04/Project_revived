local var_0_0 = class("IllusionWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.illusionCampaign
local var_0_3 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.illusion = xyd.ModelManager.get():loadModel(xyd.ModelType.ILLUSION)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar({
		show_rule = true
	})
	arg_2_0:layout()
	arg_2_0.illusion:loadIllusionInfos(function(arg_3_0)
		if arg_3_0 == xyd.error.OK and arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0:update()
		end
	end)
end

function var_0_0.layout(arg_4_0)
	if arg_4_0.activities:isIllusionBetOpen() then
		arg_4_0:nodeByName("btn_bet"):setVisible(true)
	else
		arg_4_0:nodeByName("btn_bet"):setVisible(false)
	end

	xyd.addTouchEvent(arg_4_0:nodeByName("btn_bet"), function()
		arg_4_0.illusion:getBetInfo(function(arg_6_0, arg_6_1)
			if arg_6_0 == xyd.error.OK and arg_4_0 and not tolua.isnull(arg_4_0) then
				xyd.WindowManager.get():openWindow("illusion_bet")
			end
		end)
	end)
	arg_4_0:nodeByName("time_txt"):setString("")
	arg_4_0:nodeByName("time_txt"):enableOutline(cc.c4b(71, 64, 97, 255), 2)
	xyd.addTouchEvent(arg_4_0:nodeByName("shop_btn"), function()
		xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
			xyd.WindowManager.get():openWindow("shop", {
				shop_type = xyd.ShopType.ILLUSION
			})
		end)
	end)
	xyd.addTouchEvent(arg_4_0:nodeByName("rank_btn"), function()
		local var_9_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.RANK_LIST)

		var_9_0:loadRankList({
			xyd.SubRankType.PARADISE_PERSON_RANK
		}, true, function(arg_10_0, arg_10_1)
			if arg_10_0 == xyd.error.OK then
				local var_10_0 = {
					rank_type = xyd.RankType.Illusion,
					sub_type = xyd.SubRankType.PARADISE_PERSON_RANK,
					rankData = var_9_0:getRankList()
				}

				xyd.WindowManager.get():openWindow("new_rank_list", var_10_0)
			end
		end)
	end)

	arg_4_0.rule_btn = arg_4_0:nodeByName("top_sidebar"):nodeByName("rule")

	xyd.addTouchEvent(arg_4_0.rule_btn, function()
		xyd.WindowManager.get():openWindow("illusion_rule", {
			rank = arg_4_0.illusion.rank
		})
	end)
	xyd.addTouchEvent(arg_4_0:nodeByName("add_btn"), function()
		if xyd.tables.vip:illusionReset(arg_4_0.player.vip) <= arg_4_0.illusion.buyPre then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
				string.format(var_0_1:translation("PARADISE_RESET_TIMES2"), arg_4_0.illusion.buyPre),
				var_0_1:translation("PARADISE_RESET_VIP")
			}, function()
				xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge, {
					windowState = false
				})
			end, {
				rightName = var_0_1:translation("CHECK_PRIVILEGE")
			}, nil, arg_4_0.colorMode)

			return
		end

		local var_12_0 = xyd.tables.refreshCost:illusionBuyCost(arg_4_0.illusion.buyPre + 1)

		if var_12_0 > arg_4_0.player.crystal then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
				local var_14_0 = {}

				var_14_0.windowState = true

				xyd.WindowManager.get():openWindow("vip_recharge", var_14_0)
			end, nil, nil, arg_4_0.colorMode)
		else
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
				string.format(var_0_1:translation("PARADISE_RESET"), var_12_0),
				var_0_1:translation("SWEEP_ITEM_CONTINUE") .. string.format(var_0_1:translation("MAP_RESET_TIMES"), arg_4_0.illusion.buyPre)
			}, function()
				arg_4_0.illusion:buyTimes(function()
					arg_4_0:updateTimes()
				end)
			end, nil, nil, arg_4_0.colorMode)
		end
	end)
end

function var_0_0.didOpen(arg_17_0, arg_17_1)
	arg_17_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 0))
end

function var_0_0.update(arg_18_0)
	local var_18_0 = arg_18_0:nodeByName("monster_click")

	var_18_0:setTouchEnabled(true)

	if not arg_18_0.illusion.isOpen then
		arg_18_0:nodeByName("name_txt"):setVisible(false)

		local var_18_1 = arg_18_0:nodeByName("monster_pic")

		var_18_1:setVisible(true)
		var_18_1:setScale(0.9)
		var_18_1:loadTexture("windows/illusion/text/" .. var_0_2:modelPic(arg_18_0.illusion.id))
		var_18_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
			if arg_19_0.name == "began" then
				return true
			elseif arg_19_0.name == "ended" then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PARADISE_BOSS_OPEN_TIP1")
				})
			end
		end)

		return
	end

	arg_18_0:updateTimes()

	local var_18_2 = "skeletons/ui_effect/paradise/paradise_light"
	local var_18_3 = var_18_2 .. ".json"
	local var_18_4 = var_18_2 .. ".atlas"
	local var_18_5 = var_0_3.new(var_18_3, var_18_4, 1)

	var_18_5:setPosition(0, 280)
	var_18_5:addTo(arg_18_0:nodeByName("monster"))
	var_18_5:play(nil, true)
	arg_18_0:nodeByName("name_txt"):setVisible(true)
	arg_18_0:nodeByName("name_txt"):loadTexture("windows/illusion/text/" .. var_0_2:heroName(arg_18_0.illusion.id))

	local var_18_6 = var_0_2:tableID(arg_18_0.illusion.id)
	local var_18_7 = var_0_2:modelId(arg_18_0.illusion.id)
	local var_18_8 = xyd.HeroAnimation.new(nil, var_18_7, 1, {})

	var_18_8:addTo(arg_18_0:nodeByName("monster"))
	var_18_8:setScale(1)
	var_18_8:idle(true)

	local var_18_9 = "skeletons/ui_effect/paradise/paradise_ring"
	local var_18_10 = var_18_9 .. ".json"
	local var_18_11 = var_18_9 .. ".atlas"
	local var_18_12 = var_0_3.new(var_18_10, var_18_11, 1)

	var_18_12:setPosition(0, 150)
	var_18_12:addTo(arg_18_0:nodeByName("monster"))
	var_18_12:play(nil, true)
	var_18_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
		if arg_20_0.name == "began" then
			return true
		elseif arg_20_0.name == "ended" then
			local var_20_0 = xyd.ServerTime.get():getSecondsOfDay()

			if var_20_0 < xyd.tables.misc.dungenBossStart or var_20_0 > xyd.tables.misc.dungenBossStop then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PARADISE_BOSS_OPEN_TIP2")
				})

				return
			end

			xyd.WindowManager.get():openWindow("illusion_detail", {
				modelId = var_18_7
			})
		end
	end)
end

function var_0_0.updateTimes(arg_21_0)
	arg_21_0:nodeByName("time_txt"):setString(string.format(var_0_1:translation("INCUBUS_LEFT_TIMES"), arg_21_0.illusion.times, arg_21_0.illusion.initTimes))

	if arg_21_0.illusion.times > 0 then
		arg_21_0:nodeByName("add_btn"):setVisible(false)
	else
		arg_21_0:nodeByName("add_btn"):setVisible(true)
	end
end

return var_0_0
