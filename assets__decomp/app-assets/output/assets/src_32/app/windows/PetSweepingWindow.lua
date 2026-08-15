local var_0_0 = class("PetSweepingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")
local var_0_3 = xyd.tables.petCampaign

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.petCampaign = xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN)
	arg_1_0.currentLayer = arg_1_2.currentLayer
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("finish_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_4_0 = arg_3_0.petCampaign.begin_sweep_time + var_0_3:getSweepTime(arg_3_0.currentLayer, arg_3_0.petCampaign.max_floor) - arg_3_0.currentTime
			local var_4_1 = math.ceil(var_4_0 / xyd.tables.misc.petSweepLayerTime) * xyd.tables.misc.petSweepLayerCost

			if var_4_1 > arg_3_0.selfPlayer.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
					local var_5_0 = {}

					var_5_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_5_0)
				end, nil, nil, arg_3_0.colorMode)
			else
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("PET_QUICK_SWEEP"), var_4_1), function()
					local var_6_0 = {
						finish_time = arg_3_0.currentTime
					}

					arg_3_0.petCampaign:finishSweep(function(arg_7_0, arg_7_1)
						if arg_7_0 == xyd.error.OK then
							var_6_0.isFinishAward = true
							var_6_0.awards = arg_7_1.awards
							var_6_0.floorType = xyd.PetCampaignFloorType.NORMAL

							xyd.WindowManager.get():openWindow("pet_campaign_award", var_6_0)

							local var_7_0 = xyd.WindowManager.get():openWindow("pet_campaign")

							if arg_7_1.now_floor < var_0_3:getMaxLimitFloor(xyd.PetCampaignFloorType.NORMAL) then
								var_7_0.currentIndex = tonumber(arg_7_1.now_floor) + 1
								var_7_0.minSearchIndex = var_7_0.currentIndex

								var_7_0:setCurrentItem(tonumber(arg_7_1.now_floor) + 1)
							else
								var_7_0.currentIndex = tonumber(arg_7_1.now_floor)
								var_7_0.minSearchIndex = var_7_0.currentIndex

								var_7_0:setCurrentItem(tonumber(arg_7_1.now_floor))
							end
						end
					end, var_6_0)
					xyd.WindowManager.get():closeWindow(arg_3_0)
				end, nil, nil, arg_3_0.colorMode)
			end
		end
	end)

	arg_3_0.currentTime = tonumber(xyd.ServerTime.get():getServerTime())

	arg_3_0:nodeByName("sweeping_words"):setString(var_0_1:translation("SWEEPING"))

	if arg_3_0.currentTime > arg_3_0.petCampaign.begin_sweep_time + var_0_3:getSweepTime(arg_3_0.currentLayer, arg_3_0.petCampaign.max_floor) then
		arg_3_0:setTimeWords(0)
	elseif arg_3_0.handle == nil then
		arg_3_0:setTimeWords()

		arg_3_0.handle = var_0_2.scheduleGlobal(handler(arg_3_0, arg_3_0.onTimer), 1)
	end
end

function var_0_0.setTimeWords(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_0.petCampaign.begin_sweep_time + var_0_3:getSweepTime(arg_8_0.currentLayer, arg_8_0.petCampaign.max_floor) - arg_8_0.currentTime

	if arg_8_1 then
		var_8_0 = arg_8_1
	end

	if var_8_0 < 0 then
		var_8_0 = 0
	end

	local var_8_1 = math.floor(var_8_0 % 3600 / 60)
	local var_8_2 = math.floor(var_8_0 / 3600)
	local var_8_3 = var_8_0 % 3600 % 60

	arg_8_0:nodeByName("time_text"):setString(string.format(var_0_1:translation("TEAM_DRINK_LEFT_TIME") .. "%02d:%02d:%02d", var_8_2, var_8_1, var_8_3))
end

function var_0_0.onTimer(arg_9_0)
	if arg_9_0.petCampaign.floorType == xyd.PetCampaignFloorType.SUPER then
		return
	end

	if arg_9_0.currentTime <= arg_9_0.petCampaign.begin_sweep_time + var_0_3:getSweepTime(arg_9_0.currentLayer, arg_9_0.petCampaign.max_floor) then
		arg_9_0.currentTime = arg_9_0.currentTime + 1

		arg_9_0:setTimeWords()
	else
		arg_9_0:setTimeWords(0)
		var_0_2.unscheduleGlobal(arg_9_0.handle)

		arg_9_0.handle = nil

		local var_9_0 = {
			finish_time = arg_9_0.currentTime
		}

		arg_9_0.petCampaign:finishSweep(function(arg_10_0, arg_10_1)
			if arg_10_0 == xyd.error.OK then
				var_9_0.isFinishAward = true
				var_9_0.awards = arg_10_1.awards
				var_9_0.floorType = xyd.PetCampaignFloorType.NORMAL

				xyd.WindowManager.get():openWindow("pet_campaign_award", var_9_0)

				if xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN).state == xyd.PetCampaignFloorType.NORMAL then
					local var_10_0 = xyd.WindowManager.get():openWindow("pet_campaign")

					if arg_10_1.now_floor < var_0_3:getMaxLimitFloor(xyd.PetCampaignFloorType.NORMAL) then
						var_10_0.currentIndex = tonumber(arg_10_1.now_floor) + 1
						var_10_0.minSearchIndex = var_10_0.currentIndex

						var_10_0:setCurrentItem(tonumber(arg_10_1.now_floor) + 1)
					else
						var_10_0.currentIndex = tonumber(arg_10_1.now_floor)
						var_10_0.minSearchIndex = var_10_0.currentIndex

						var_10_0:setCurrentItem(tonumber(arg_10_1.now_floor))
					end
				end
			end
		end, var_9_0)
		xyd.WindowManager.get():closeWindow(arg_9_0)
	end
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	var_0_0.super.didOpen(arg_11_0, arg_11_1)
end

function var_0_0.willClose(arg_12_0)
	var_0_0.super.willClose(arg_12_0, params)

	if arg_12_0.handle then
		var_0_2.unscheduleGlobal(arg_12_0.handle)

		arg_12_0.handle = nil
	end
end

function var_0_0.didClose(arg_13_0)
	return
end

return var_0_0
