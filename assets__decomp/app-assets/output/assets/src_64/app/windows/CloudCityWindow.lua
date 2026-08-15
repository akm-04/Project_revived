local var_0_0 = class("CloudCityWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 39
local var_0_3 = 200

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.guidePos = nil
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0.selfPlayer:loadTrialInfos(function()
		arg_2_0.trials = arg_2_0.selfPlayer.trialInfos_

		arg_2_0:layout()
	end)
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = arg_5_0:nodeByName("detail_container")
	local var_5_1 = 0

	for iter_5_0 = 1, 3 do
		local var_5_2 = cc.Node:create()
		local var_5_3 = display.newFilteredSprite("windows/cloud_city/img_" .. iter_5_0 .. ".png", "GRAY", {
			0.2,
			0.3,
			0.5,
			0.1
		})

		var_5_3:addTo(var_5_2)
		var_5_3:setAnchorPoint(cc.p(0.5, 0.5))

		local var_5_4 = var_5_3:getContentSize()

		var_5_3:setPosition(cc.p(var_5_4.width / 2, var_5_4.height / 2))
		var_5_2:setContentSize(var_5_4.width, var_5_4.height)
		var_5_2:setPosition(cc.p(var_5_1 + var_5_4.width / 2, -20 + var_5_4.height / 2))
		var_5_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_5_0:addChild(var_5_2)

		if arg_5_0.trials[iter_5_0 + var_0_2] ~= nil and tonumber(arg_5_0.trials[iter_5_0 + var_0_2].isOpen) == 1 then
			var_5_3:clearFilter()
		end

		var_5_1 = var_5_1 + var_5_4.width + var_0_2

		var_5_2:setTouchEnabled(true)
		var_5_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
			if arg_6_0.name == "began" then
				return true
			elseif arg_6_0.name == "ended" then
				if arg_5_0.trials[iter_5_0 + var_0_2] ~= nil and tonumber(arg_5_0.trials[iter_5_0 + var_0_2].isOpen) == 1 then
					local var_6_0 = {
						trialID = iter_5_0 + var_0_2
					}

					arg_5_0.selfPlayer:loadTrialInfos(function()
						var_6_0.campaigns = arg_5_0.selfPlayer.worldMaps_
						var_6_0.trial = arg_5_0.selfPlayer.trialInfos_[iter_5_0 + var_0_2]

						xyd.WindowManager.get():openWindow("select_cloud_difficult", var_6_0)
					end)
				else
					local var_6_1 = xyd.tables.trialConfig:openDates(iter_5_0 + var_0_2)
					local var_6_2 = ""

					for iter_6_0, iter_6_1 in pairs(var_6_1) do
						if string.len(var_6_2) > 0 then
							var_6_2 = var_6_2 .. "、" .. var_0_1:translation("NUM_" .. iter_6_1)
						else
							var_6_2 = var_0_1:translation("NUM_" .. iter_6_1)
						end
					end

					local var_6_3 = string.format(var_0_1:translation("OPEN_TIPS"), var_6_2)

					xyd.WindowManager.get():openWindow("trialtips", {
						trialType = iter_5_0 + var_0_2,
						openStr = var_6_3
					})
				end
			end
		end)
	end
end

return var_0_0
