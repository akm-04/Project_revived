local var_0_0 = class("LvbuDoorWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.lvbuFestival = xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL)

	local var_1_0 = xyd.ServerTime.get():getServerTime()
	local var_1_1 = {
		playerID = arg_1_0.selfPlayer.playerID,
		name = xyd.state.LVBU_DOOR_OPEN_TIME,
		state = tostring(var_1_0)
	}

	if (tonumber(xyd.db.stateVariable:getState(var_1_1.playerID, var_1_1.name)) or 0) < arg_1_0.lvbuFestival.activity.start_time then
		arg_1_0.isFirst = true
	end

	xyd.db.stateVariable:setState(var_1_1)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addTopSidebar({
		show_rule = true
	})
	arg_2_0:nodeByName("eco_sidebar"):setVisible(false)
	arg_2_0:layout()

	if arg_2_0.isFirst then
		arg_2_0:nodeByName("prfiteer"):setTouchEnabled(false)
		arg_2_0:nodeByName("world_campus"):setTouchEnabled(false)
		arg_2_0:nodeByName("raffle"):setTouchEnabled(false)

		local function var_2_0(...)
			xyd.WindowManager.get():openWindow("lvbu_door_rule")

			local var_3_0 = xyd.WindowManager.get():getWindow("lvbu_door")

			if var_3_0 and not tolua.isnull(var_3_0) then
				var_3_0:nodeByName("prfiteer"):setTouchEnabled(true)
				var_3_0:nodeByName("world_campus"):setTouchEnabled(true)
				var_3_0:nodeByName("raffle"):setTouchEnabled(true)
			end

			xyd.Backend.get():request(xyd.mid.LVBU_SHOW_RULE, arg_2_1, function(arg_4_0, arg_4_1)
				if arg_4_0 == xyd.error.OK then
					arg_2_0.lvbuFestival.isDailyEnter = 1
				end
			end)
		end

		local var_2_1 = {}

		var_2_1.story_id = 10831001
		var_2_1.is_assist = true
		var_2_1.callback = var_2_0

		xyd.WindowManager.get():openWindow("story", var_2_1)
	elseif arg_2_0.lvbuFestival.isDailyEnter == 0 then
		xyd.WindowManager.get():openWindow("pic_tip", {
			path = "windows/lvbu/door/door_rule.png"
		})
		xyd.Backend.get():request(xyd.mid.LVBU_SHOW_RULE, arg_2_1, function(arg_5_0, arg_5_1)
			if arg_5_0 == xyd.error.OK then
				arg_2_0.lvbuFestival.isDailyEnter = 1
			end
		end)
	end
end

function var_0_0.layout(arg_6_0)
	arg_6_0:addDialog()

	local var_6_0 = arg_6_0:nodeByName("top_sidebar"):nodeByName("rule")

	xyd.nodeEventSample(var_6_0, nil, function(arg_7_0)
		xyd.playButtonSound()
		xyd.WindowManager.get():openWindow("pic_tip", {
			path = "windows/lvbu/door/door_rule.png"
		})
	end)
	xyd.nodeEventSample(arg_6_0:nodeByName("prfiteer"), nil, function()
		if arg_6_0.lvbuFestival:isHaveLvbu() then
			xyd.WindowManager.get():openWindow("lvbu_shop")

			return
		end

		if arg_6_0.selfPlayer.lvbuCoin < xyd.tables.misc.lvbuRepairDollar then
			arg_6_0.speakCellContent:onclick()

			return
		end

		if xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(xyd.tables.misc.lvbuBrokenCard) <= 0 then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("NOT_HAVE_LVBR_BROKEN_CARD")
			})

			return
		end

		arg_6_0:playRecoverLvbu()
	end)
	xyd.nodeEventSample(arg_6_0:nodeByName("world_campus"), nil, function()
		xyd.WindowManager.get():openWindow("lvbu_world_campus")
	end)
	xyd.nodeEventSample(arg_6_0:nodeByName("raffle"), nil, function()
		xyd.WindowManager.get():openWindow("lvbu_raffle")
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_6_0):addEventListener(xyd.event.ECONOMY_AFTER, function(arg_11_0)
		if arg_6_0 and not tolua.isnull(arg_6_0) then
			arg_6_0:nodeByName("money_txt"):setString(arg_6_0.selfPlayer.lvbuCoin)
			arg_6_0:nodeByName("diamond_txt"):setString(arg_6_0.selfPlayer.crystal)
		end
	end)
	arg_6_0:nodeByName("money_txt"):setString(arg_6_0.selfPlayer.lvbuCoin)
	arg_6_0:nodeByName("diamond_txt"):setString(arg_6_0.selfPlayer.crystal)

	for iter_6_0 = 1, 3 do
		arg_6_0:nodeByName("des" .. iter_6_0):setString(var_0_1:translation("LVBU_DOOR_DES" .. iter_6_0))
	end
end

function var_0_0.sureGoToShop(arg_12_0)
	local var_12_0 = xyd.tables.translation:translation("SURE_TO_LVBU_SHOP")

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_12_0, function()
		xyd.WindowManager.get():openWindow("lvbu_shop")
	end, nil, nil, arg_12_0.colorMode)
end

function var_0_0.playRecoverLvbu(arg_14_0)
	local var_14_0 = string.format(xyd.tables.translation:translation("SURE_COST_RECOVER_LVBU"), math.ceil(xyd.tables.misc.lvbuRepairDollar / 10000))

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_14_0, function()
		arg_14_0.lvbuFestival:repair({}, function(arg_16_0, arg_16_1)
			if arg_16_0 == xyd.error.OK then
				local var_16_0 = var_0_2.new()

				var_16_0:populate(arg_16_1.partner_info)
				arg_14_0.selfPlayer:addHero(var_16_0)

				params = {
					toStone = false,
					partnerID = arg_16_1.partner_info.table_id
				}

				local var_16_1 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, params)

				cc.EventProxy.new(var_16_1, var_16_1):addEventListener(xyd.event.SUMMON_HERO_CLOSE, function()
					arg_14_0:sureGoToShop()
				end)
			end
		end)
	end, nil, nil, arg_14_0.colorMode)
end

function var_0_0.addDialog(arg_18_0, arg_18_1)
	local var_18_0 = {
		touchPosition = cc.p(0, -200),
		touchAreaSize = {
			width = 0,
			height = 0
		}
	}
	local var_18_1 = string.format(var_0_1:translation("LVBU_MONEY_NOT_ENOUGH"), math.ceil(xyd.tables.misc.lvbuRepairDollar / 10000))

	var_18_0.msgs = {
		var_18_1
	}
	var_18_0.times = {
		3
	}
	arg_18_0.speakCellContent = import("app.windows.SpeakCell").new(var_18_0)

	arg_18_0.speakCellContent:addTo(arg_18_0:nodeByName("speak_pos"))
	arg_18_0.speakCellContent:setAnchorPoint(cc.p(0, 0))
end

return var_0_0
