local var_0_0 = class("StickBlessAccessWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.stickBless = xyd.ModelManager.get():loadModel(xyd.ModelType.STICK_BLESS)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.campaignDropCount = arg_1_2.campaign_drop_count
	arg_1_0.summonDropCount = arg_1_2.summon_drop_count
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	xyd.imgEvent(arg_3_0:nodeByName("concent_bg_1"), function()
		arg_3_0.guild:loadGuildMap(function(arg_5_0)
			if arg_5_0 == xyd.error.OK then
				local var_5_0 = {}

				var_5_0.chapter_type = 1

				xyd.WindowManager.get():openWindow("map_window", var_5_0)
			else
				xyd.WindowManager.get():openWindow("map_window", {
					chapter_type = 1
				})
			end

			if xyd.WindowManager.get():getWindow("stick_bless_access") then
				xyd.WindowManager.get():closeWindow("stick_bless_access")
			end

			xyd.WindowManager.get():closeWindow(arg_3_0)
		end)
	end)
	xyd.imgEvent(arg_3_0:nodeByName("concent_bg_2"), function()
		local var_6_0 = var_0_3.activityStickerBuyCost

		xyd.AlertWindow.open(xyd.AlertType.YES_NO, {
			string.format(var_0_2:translation("STICK_BLESS_BUY_TIPS1"), var_6_0, var_0_3.activityStickerBuyNum)
		}, function(arg_7_0)
			if arg_7_0 then
				if var_6_0 > arg_3_0.selfPlayer.crystal then
					xyd.AlertWindow.open(xyd.AlertType.YES_NO, {
						var_0_2:translation("ZUANSHI_ABSENCE")
					}, function(arg_8_0)
						if arg_8_0 then
							xyd.WindowManager.get():openWindow("vip_recharge", {
								windowState = true
							})
						end
					end)

					return
				end

				arg_3_0.stickBless:stickBuy(function(arg_9_0)
					arg_3_0.selfPlayer:handleRewards(arg_9_0.awards)

					local var_9_0 = xyd.WindowManager.get():getWindow("stick_bless_word")

					if var_9_0 then
						var_9_0:updateNum()
					end
				end)
			end
		end)
	end)
	xyd.imgEvent(arg_3_0:nodeByName("concent_bg_3"), function()
		arg_3_0.selfPlayer:loadSummonInfo(nil, function()
			xyd.WindowManager.get():openWindow("summon")

			if xyd.WindowManager.get():getWindow("stick_bless_access") then
				xyd.WindowManager.get():closeWindow("stick_bless_access")
			end

			xyd.WindowManager.get():closeWindow(arg_3_0)
		end, true)
	end)

	for iter_3_0 = 1, 3 do
		arg_3_0:nodeByName("text_name_" .. iter_3_0):setString(var_0_2:translation("STICK_ACCESS_NAME_" .. iter_3_0))
		arg_3_0:nodeByName("text_desc_" .. iter_3_0):setString(var_0_2:translation("STICK_ACCESS_TIPS_" .. iter_3_0))
		arg_3_0:nodeByName("text_name_" .. iter_3_0):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	end

	arg_3_0:nodeByName("text_get_1"):setString(string.format(var_0_2:translation("STICK_FU_DROP_LIMIT_TEXT_1"), arg_3_0.campaignDropCount, var_0_3:getValue("stick_fu_campaign_drop_daily_limit")))
	arg_3_0:nodeByName("text_get_3"):setString(string.format(var_0_2:translation("STICK_FU_DROP_LIMIT_TEXT_2"), arg_3_0.summonDropCount, var_0_3:getValue("stick_fu_summon_drop_weekly_limit")))
end

return var_0_0
