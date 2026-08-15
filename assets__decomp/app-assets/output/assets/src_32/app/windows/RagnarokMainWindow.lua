local var_0_0 = class("RagnarokMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = xyd.tables.ragnarokBoss
local var_0_4 = xyd.tables.hero
local var_0_5 = var_0_2:getValue("activity_ragnarok_boss_ticket")
local var_0_6 = var_0_2:getValue("activity_ragnarok_boss_energy_cost")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.ragnarok = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	local var_2_0 = {
		ecoCount = 1,
		show_rule = true,
		ecoBarType = xyd.EcoSidebarType.DISPLAY,
		ecoTypes = {
			var_0_5
		},
		ecoIcons = {
			"windows/activities/1203/ragnarok/icon/icon_bugle.png"
		}
	}

	arg_2_0:addTopSidebar(var_2_0)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_boss"):setString(var_0_1:translation("RAGNAROK_BOSS_1"))
	arg_3_0:nodeByName("txt_name_2"):setString(var_0_1:translation("RAGNAROK_BOSS_2"))
	arg_3_0:nodeByName("txt_name_3"):setString(var_0_1:translation("RAGNAROK_BOSS_2"))
	arg_3_0:nodeByName("txt_team"):setString(var_0_1:translation("RAGNAROK_BOSS_3"))
	arg_3_0:nodeByName("txt_single"):setString(var_0_1:translation("RAGNAROK_BOSS_4"))
	arg_3_0:nodeByName("txt_rank"):setString(var_0_1:translation("RAGNAROK_BOSS_5"))
	arg_3_0:nodeByName("txt_shop"):setString(var_0_1:translation("RAGNAROK_BOSS_6"))
	arg_3_0:nodeByName("txt_boss"):enableOutline(cc.c4b(86, 33, 109, 255), 2)
	arg_3_0:nodeByName("txt_name_2"):enableOutline(cc.c4b(86, 33, 109, 255), 2)
	arg_3_0:nodeByName("txt_name_3"):enableOutline(cc.c4b(86, 33, 109, 255), 2)

	for iter_3_0 = 1, 3 do
		local var_3_0 = var_0_3:monsterId(xyd.RagnarokType.SINGLE, iter_3_0)
		local var_3_1 = var_0_4:modelID(var_3_0)
		local var_3_2 = xyd.HeroAnimation.new(nil, var_3_1, 0.6, {})

		var_3_2:addTo(arg_3_0:nodeByName("pos" .. iter_3_0))
		var_3_2:idle(true)

		if iter_3_0 > 1 then
			var_3_2:setPosition(-50, 0)
		end
	end

	arg_3_0:initButton()
end

function var_0_0.initButton(arg_4_0)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_team"), nil, function(arg_5_0)
		if not arg_4_0.ragnarok:checkTicket() then
			local var_5_0 = var_0_1:translation("RAGNAROK_BOSS_TEAM_26")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_5_0
			})

			return
		end

		if not arg_4_0.ragnarok:checkEnergy() then
			return
		end

		local var_5_1 = string.format(var_0_1:translation("RAGNAROK_BOSS_30"), var_0_6)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_1, function()
			arg_4_0.ragnarok:getRoomList(function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("ragnarok_select_model", arg_7_1)
				end
			end)
		end, nil, nil, xyd.ColorMode.PURPLE)
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_single"), nil, function(arg_8_0)
		if not arg_4_0.ragnarok:checkTicket() then
			local var_8_0 = var_0_1:translation("RAGNAROK_BOSS_TEAM_26")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_8_0
			})

			return
		end

		if not arg_4_0.ragnarok:checkEnergy() then
			return
		end

		local var_8_1 = string.format(var_0_1:translation("RAGNAROK_BOSS_30"), var_0_6)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_8_1, function()
			arg_4_0.ragnarok:singleEnter()
		end, nil, nil, xyd.ColorMode.PURPLE)
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_rank"), nil, function(arg_10_0)
		arg_4_0.ragnarok:enterRank()
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_shop"), nil, function(arg_11_0)
		arg_4_0.ragnarok:enterShop()
	end)

	local var_4_0 = arg_4_0:nodeByName("top_sidebar"):nodeByName("rule")

	xyd.nodeEventSample(var_4_0, nil, function()
		local var_12_0 = {}

		var_12_0.title_name = "RAGNAROK_BOSS_RULE_TITLE_1"
		var_12_0.rule = "RAGNAROK_BOSS_RULE_TEXT_1"
		var_12_0.style = xyd.RuleStyle.PURPLE

		xyd.WindowManager.get():openWindow("new_text_rule", var_12_0)
	end)
end

function var_0_0.updateEco(arg_13_0)
	local var_13_0 = {
		true
	}

	arg_13_0:nodeByName("eco_sidebar"):update(var_13_0)
end

return var_0_0
