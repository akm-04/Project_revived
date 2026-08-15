local var_0_0 = class("EventAdmin", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.conversionTable
local var_0_4 = 60
local var_0_5 = "yuanbao"
local var_0_6 = "magic_energy"
local var_0_7 = "magic_liquid"
local var_0_8 = "magic_dust"
local var_0_9 = "jinbi_new"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.info = arg_1_2.adminInfo.info
	arg_1_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.centre = xyd.WindowManager.get():getWindow("event_centre")
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.status = 0
	arg_2_0.conversionBtn = arg_2_0:nodeByName("conversion_btn")
	arg_2_0.levupBtn = arg_2_0:nodeByName("levup_btn")
	arg_2_0.item1 = arg_2_0:nodeByName("item1")
	arg_2_0.item2 = arg_2_0:nodeByName("item2")
	arg_2_0.item31 = arg_2_0:nodeByName("item31")
	arg_2_0.item32 = arg_2_0:nodeByName("item32")
	arg_2_0.item33 = arg_2_0:nodeByName("item33")
	arg_2_0.item34 = arg_2_0:nodeByName("item34")
	arg_2_0.item35 = arg_2_0:nodeByName("item35")
	arg_2_0.from = 0
	arg_2_0.to = 0
	arg_2_0.lev = arg_2_0.eventCentre.adminLev
	arg_2_0.delay = 1.5

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_cancel"):setString(var_0_2:translation("CANCEL"))
	arg_3_0:nodeByName("txt_speed_up"):setString(var_0_2:translation("EVENT_CENTRE_TIP2"))
	arg_3_0:nodeByName("txt_levup"):setString(var_0_2:translation("HERO_MAIN_TEXT_13"))
	arg_3_0:nodeByName("txt_conversion"):setString(var_0_2:translation("EXCHANGE"))
	arg_3_0:nodeByName("txt_title"):setString(xyd.tables.eventCentreTable:name(xyd.EventCentreBuildingType.ADMIN))
	arg_3_0:updateStatus()
	arg_3_0:updateAdminLev()
	arg_3_0:clipIcon(arg_3_0:nodeByName("item31"), var_0_5)
	arg_3_0:clipIcon(arg_3_0:nodeByName("item32"), var_0_6)
	arg_3_0:clipIcon(arg_3_0:nodeByName("item33"), var_0_7)
	arg_3_0:clipIcon(arg_3_0:nodeByName("item34"), var_0_8)
	arg_3_0:clipIcon(arg_3_0:nodeByName("item35"), var_0_9)
	arg_3_0:updateUpgradeTime()

	if arg_3_0.eventCentre.adminNewEvolve and arg_3_0.eventCentre.adminNewEvolve == 1 then
		arg_3_0:levupSucceed()
	end
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	arg_4_0.levupBtn:addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_4_0.levupBtn, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			if arg_4_0.lev == 5 then
				arg_4_0:openDialog(var_0_2:translation("ADMIN_HIGHEST_LEV"), arg_4_0.delay)

				return
			end

			arg_4_0.status = 0
			arg_4_0.from = 0
			arg_4_0.to = 0

			arg_4_0:updateStatus()
			arg_4_0.item1:removeAllChildren()
			arg_4_0.item2:removeAllChildren()

			local var_5_0 = {
				type = xyd.EventCentreBuildingType.ADMIN,
				lev = arg_4_0.lev
			}

			xyd.WindowManager.get():openWindow("event_centre_upgrade", var_5_0)
		end
	end)
	arg_4_0:nodeByName("levup_speedup_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("levup_speedup_btn"), arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = arg_4_0.eventCentre.adminNeedTime - (xyd.ServerTime.get():getServerTime() - arg_4_0.eventCentre.adminStartTime)
			local var_6_1

			if var_6_0 < 14400 then
				var_6_1 = var_6_0 / 72
			elseif var_6_0 < 43200 then
				var_6_1 = (var_6_0 - 14400) / 144 + 200
			else
				var_6_1 = (var_6_0 - 43200) / 432 + 400
			end

			local var_6_2 = math.ceil(var_6_1)
			local var_6_3 = string.format(var_0_2:translation("COST_TO_UPGRADE"), var_6_2, arg_4_0.lev + 1)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_3, function()
				if var_6_2 > arg_4_0.selfPlayer.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
						local var_8_0 = {}

						var_8_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_8_0)
					end, nil, nil, xyd.ColorMode.GREEN)
				else
					local var_7_0 = {
						type = xyd.EventCentreBuildingType.ADMIN
					}

					arg_4_0.eventCentre:speedUpBuilding(var_7_0, function(arg_9_0, arg_9_1)
						if arg_9_0 == xyd.error.OK then
							arg_4_0.eventCentre.adminStartTime = 0
							arg_4_0.eventCentre.adminNeedTime = 0
							arg_4_0.eventCentre.adminLev = arg_9_1.lev
							arg_4_0.eventCentre.buidingInfo["" .. xyd.EventCentreBuildingType.ADMIN].lev = arg_4_0.eventCentre.adminLev

							arg_4_0:updateUpgradeTime()
							arg_4_0:levupSucceed()
						end
					end)
				end
			end, nil, 0, xyd.ColorMode.GREEN)
		end
	end)
	arg_4_0:nodeByName("levup_cancel_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("levup_cancel_btn"), arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			local var_10_0 = var_0_2:translation("CANCEL_UPGRADE")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_0, function()
				local var_11_0 = {
					type = xyd.EventCentreBuildingType.ADMIN
				}

				arg_4_0.eventCentre:cancelEvolveBuilding(var_11_0, function(arg_12_0, arg_12_1)
					if arg_12_0 == xyd.error.OK then
						arg_4_0.eventCentre.adminStartTime = arg_12_1.building_info.start_time
						arg_4_0.eventCentre.adminNeedTime = arg_12_1.building_info.need_time
						arg_4_0.eventCentre.adminLev = arg_12_1.building_info.lev
						arg_4_0.eventCentre.buidingInfo["" .. xyd.EventCentreBuildingType.ADMIN].lev = arg_4_0.eventCentre.adminLev

						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.REFRESH_MAGIC_RES
						})
						arg_4_0:updateUpgradeTime()

						local var_12_0 = {
							resolve_types = arg_12_1.return_res_id,
							resolve_nums = arg_12_1.return_res_num,
							resolve_crits = {}
						}

						xyd.WindowManager.get():openWindow("recycle_award", var_12_0)
					end
				end)
			end, nil, nil, xyd.ColorMode.GREEN)
		end
	end)
	arg_4_0.item1:setTouchEnabled(true)
	arg_4_0.item1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			arg_4_0.item1:setScale(0.9)

			return true
		elseif arg_13_0.name == "ended" then
			arg_4_0.item1:setScale(1)
			xyd.playButtonSound()

			if arg_4_0.eventCentre.adminStartTime > 0 then
				arg_4_0:openDialog(var_0_2:translation("ADMIN_WHEN_LEVUP"), arg_4_0.delay)

				return
			end

			arg_4_0.status = 2

			arg_4_0:updateStatus()
		end
	end)
	arg_4_0.item2:setTouchEnabled(true)
	arg_4_0.item2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		if arg_14_0.name == "began" then
			arg_4_0.item2:setScale(0.9)

			return true
		elseif arg_14_0.name == "ended" then
			arg_4_0.item2:setScale(1)
			xyd.playButtonSound()

			if arg_4_0.eventCentre.adminStartTime > 0 then
				arg_4_0:openDialog(var_0_2:translation("ADMIN_WHEN_LEVUP"), arg_4_0.delay)

				return
			end

			arg_4_0.status = 3

			arg_4_0:updateStatus()
		end
	end)
	arg_4_0.item31:setTouchEnabled(true)
	arg_4_0.item31:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
		if arg_15_0.name == "began" then
			arg_4_0.item31:setScale(0.9)
			arg_4_0:nodeByName("unlock31"):setScale(1.35)

			return true
		elseif arg_15_0.name == "ended" then
			arg_4_0.item31:setScale(1)
			arg_4_0:nodeByName("unlock31"):setScale(1.5)
			xyd.playButtonSound()

			arg_4_0.from = xyd.currencyType.CRYSTAL

			arg_4_0:clipIcon(arg_4_0.item1, var_0_5)

			if arg_4_0.to > 0 then
				arg_4_0.status = 1
			else
				arg_4_0.status = 3
			end

			arg_4_0:updateStatus()
		end
	end)
	arg_4_0.item32:setTouchEnabled(true)
	arg_4_0.item32:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			arg_4_0.item32:setScale(0.9)
			arg_4_0:nodeByName("unlock32"):setScale(1.35)

			return true
		elseif arg_16_0.name == "ended" then
			arg_4_0.item32:setScale(1)
			arg_4_0:nodeByName("unlock32"):setScale(1.5)
			xyd.playButtonSound()

			if arg_4_0.status == 2 then
				if arg_4_0.lev < 2 then
					arg_4_0:openDialog(string.format(var_0_2:translation("ADMIN_UNLOCK_TIP"), 2), arg_4_0.delay)

					return
				end

				if arg_4_0.to == xyd.currencyType.MAGIC_ENERGY then
					arg_4_0:openDialog(var_0_2:translation("ADMIN_SAME_FROM_TO"), arg_4_0.delay)

					return
				end

				arg_4_0.from = xyd.currencyType.MAGIC_ENERGY

				arg_4_0:clipIcon(arg_4_0.item1, var_0_6)

				if arg_4_0.to > 0 then
					arg_4_0.status = 1
				else
					arg_4_0.status = 3
				end
			else
				if arg_4_0.from == xyd.currencyType.MAGIC_ENERGY then
					arg_4_0:openDialog(var_0_2:translation("ADMIN_SAME_FROM_TO"), arg_4_0.delay)

					return
				end

				arg_4_0.to = xyd.currencyType.MAGIC_ENERGY

				arg_4_0:clipIcon(arg_4_0.item2, var_0_6)

				if arg_4_0.from > 0 then
					arg_4_0.status = 1
				else
					arg_4_0.status = 2
				end
			end

			arg_4_0:updateStatus()
		end
	end)
	arg_4_0.item33:setTouchEnabled(true)
	arg_4_0.item33:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
		if arg_17_0.name == "began" then
			arg_4_0.item33:setScale(0.9)
			arg_4_0:nodeByName("unlock33"):setScale(1.35)

			return true
		elseif arg_17_0.name == "ended" then
			arg_4_0.item33:setScale(1)
			arg_4_0:nodeByName("unlock33"):setScale(1.5)
			xyd.playButtonSound()

			if arg_4_0.status == 2 then
				if arg_4_0.lev < 3 then
					arg_4_0:openDialog(string.format(var_0_2:translation("ADMIN_UNLOCK_TIP"), 3), arg_4_0.delay)

					return
				end

				if arg_4_0.to == xyd.currencyType.MAGIC_LIQUID then
					arg_4_0:openDialog(var_0_2:translation("ADMIN_SAME_FROM_TO"), arg_4_0.delay)

					return
				end

				arg_4_0.from = xyd.currencyType.MAGIC_LIQUID

				arg_4_0:clipIcon(arg_4_0.item1, var_0_7)

				if arg_4_0.to > 0 then
					arg_4_0.status = 1

					arg_4_0:updateStatus()
				else
					arg_4_0.status = 3
				end
			else
				if arg_4_0.from == xyd.currencyType.MAGIC_LIQUID then
					arg_4_0:openDialog(var_0_2:translation("ADMIN_SAME_FROM_TO"), arg_4_0.delay)

					return
				end

				arg_4_0.to = xyd.currencyType.MAGIC_LIQUID

				arg_4_0:clipIcon(arg_4_0.item2, var_0_7)

				if arg_4_0.from > 0 then
					arg_4_0.status = 1
				else
					arg_4_0.status = 2
				end
			end

			arg_4_0:updateStatus()
		end
	end)
	arg_4_0.item34:setTouchEnabled(true)
	arg_4_0.item34:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
		if arg_18_0.name == "began" then
			arg_4_0.item34:setScale(0.9)
			arg_4_0:nodeByName("unlock34"):setScale(1.35)

			return true
		elseif arg_18_0.name == "ended" then
			arg_4_0.item34:setScale(1)
			arg_4_0:nodeByName("unlock34"):setScale(1.5)
			xyd.playButtonSound()

			if arg_4_0.status == 2 then
				if arg_4_0.lev < 4 then
					arg_4_0:openDialog(string.format(var_0_2:translation("ADMIN_UNLOCK_TIP"), 4), arg_4_0.delay)

					return
				end

				if arg_4_0.to == xyd.currencyType.MAGIC_DUST then
					arg_4_0:openDialog(var_0_2:translation("ADMIN_SAME_FROM_TO"), arg_4_0.delay)

					return
				end

				arg_4_0.from = xyd.currencyType.MAGIC_DUST

				arg_4_0:clipIcon(arg_4_0.item1, var_0_8)

				if arg_4_0.to > 0 then
					arg_4_0.status = 1

					arg_4_0:updateStatus()
				else
					arg_4_0.status = 3
				end
			else
				if arg_4_0.from == xyd.currencyType.MAGIC_DUST then
					arg_4_0:openDialog(var_0_2:translation("ADMIN_SAME_FROM_TO"), arg_4_0.delay)

					return
				end

				arg_4_0.to = xyd.currencyType.MAGIC_DUST

				arg_4_0:clipIcon(arg_4_0.item2, var_0_8)

				if arg_4_0.from > 0 then
					arg_4_0.status = 1
				else
					arg_4_0.status = 2
				end
			end

			arg_4_0:updateStatus()
		end
	end)
	arg_4_0.item35:setTouchEnabled(true)
	arg_4_0.item35:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
		if arg_19_0.name == "began" then
			arg_4_0.item35:setScale(0.9)
			arg_4_0:nodeByName("unlock35"):setScale(1.35)

			return true
		elseif arg_19_0.name == "ended" then
			arg_4_0.item35:setScale(1)
			arg_4_0:nodeByName("unlock35"):setScale(1.5)
			xyd.playButtonSound()

			if arg_4_0.lev < 5 then
				arg_4_0:openDialog(string.format(var_0_2:translation("ADMIN_UNLOCK_TIP"), 5), arg_4_0.delay)

				return
			end

			arg_4_0.from = xyd.currencyType.MANA

			arg_4_0:clipIcon(arg_4_0.item1, var_0_9)

			if arg_4_0.to > 0 then
				arg_4_0.status = 1
			else
				arg_4_0.status = 3
			end

			arg_4_0:updateStatus()
		end
	end)
	arg_4_0.conversionBtn:addTouchEventListener(function(arg_20_0, arg_20_1)
		xyd.buttonScaleAnim(arg_4_0.conversionBtn, arg_20_1)

		if arg_20_1 == ccui.TouchEventType.ended then
			if arg_4_0.info["" .. arg_4_0.from .. arg_4_0.to] == var_0_4 then
				arg_4_0:openDialog(var_0_2:translation("ADMIN_COUNT_NOT_ENOUGH"), arg_4_0.delay)

				return
			end

			if not arg_4_0:isCostEnough() then
				local var_20_0 = string.format(xyd.tables.translation:translation("COST_NOT_ENOUGH"), nameString)

				arg_4_0:openDialog(var_20_0, arg_4_0.delay)

				return
			end

			local var_20_1 = {
				from_type = arg_4_0.from,
				to_type = arg_4_0.to
			}

			arg_4_0.eventCentre:adminConversion(var_20_1, function(arg_21_0, arg_21_1)
				if arg_21_0 == xyd.error.OK then
					arg_4_0.info["" .. arg_4_0.from .. arg_4_0.to] = arg_4_0.info["" .. arg_4_0.from .. arg_4_0.to] + 1

					arg_4_0:updateConversionNum()
					arg_4_0.centre:updateTop()

					local var_21_0 = {
						resolve_types = {
							arg_4_0.to
						},
						resolve_nums = {
							arg_4_0.toNum
						},
						resolve_crits = {}
					}

					xyd.WindowManager.get():openWindow("recycle_award", var_21_0)
				end
			end)
		end
	end)
	arg_4_0:openDialog(var_0_2:translation("ADMIN_OPEN_TIP"), 2)
end

function var_0_0.willClose(arg_22_0, arg_22_1)
	var_0_0.super:willClose(arg_22_1)

	if arg_22_0.handle1 then
		var_0_1.unscheduleGlobal(arg_22_0.handle1)

		arg_22_0.handle1 = nil
	end

	if arg_22_0.dialogHandle then
		var_0_1.unscheduleGlobal(arg_22_0.dialogHandle)
	end
end

function var_0_0.updateAdminLev(arg_23_0)
	arg_23_0:nodeByName("txt_lv"):setString("LV" .. arg_23_0.lev)
end

function var_0_0.addSelectEffect(arg_24_0, arg_24_1)
	if not tolua.isnull(arg_24_0.effect) and arg_24_0.effect then
		transition.stopTarget(arg_24_0.effect)
		arg_24_0.effect:removeSelf()

		arg_24_0.effect = nil
	end

	local var_24_0 = arg_24_0:nodeByName("item" .. arg_24_1):getContentSize()

	arg_24_0.effect = xyd.AssetLoader:get():loadSprite("windows/event_centre/bg_select.png")

	arg_24_0.effect:setAnchorPoint(0.5, 0.5)
	arg_24_0.effect:addTo(arg_24_0:nodeByName("item" .. arg_24_1))
	arg_24_0.effect:setPosition(cc.p(var_24_0.width / 2, var_24_0.height / 2))
	arg_24_0.effect:setName("effect")

	local var_24_1 = transition.sequence({
		cc.ScaleTo:create(0.3, 1.04),
		cc.ScaleTo:create(0.3, 1)
	})
	local var_24_2 = cc.RepeatForever:create(var_24_1)

	arg_24_0.effect:runAction(var_24_2)
end

function var_0_0.updateStatus(arg_25_0)
	if arg_25_0.status > 1 then
		if arg_25_0.status == 2 then
			arg_25_0:nodeByName("item31"):setVisible(true)
			arg_25_0:nodeByName("item35"):setVisible(true)
			arg_25_0:nodeByName("unlock"):setVisible(true)

			for iter_25_0 = 1, 5 do
				if iter_25_0 > arg_25_0.lev then
					arg_25_0:nodeByName("unlock3" .. iter_25_0):setVisible(true)
				else
					arg_25_0:nodeByName("unlock3" .. iter_25_0):setVisible(false)
				end
			end

			arg_25_0:addSelectEffect(1)
		else
			arg_25_0:nodeByName("item31"):setVisible(false)
			arg_25_0:nodeByName("item35"):setVisible(false)
			arg_25_0:nodeByName("unlock"):setVisible(false)
			arg_25_0:nodeByName("item32"):setTouchEnabled(true)
			arg_25_0:nodeByName("item33"):setTouchEnabled(true)
			arg_25_0:nodeByName("item34"):setTouchEnabled(true)
			arg_25_0:addSelectEffect(2)
		end

		arg_25_0:nodeByName("bg3"):setVisible(true)
	else
		arg_25_0:nodeByName("bg3"):setVisible(false)
	end

	if arg_25_0.status == 1 then
		arg_25_0:nodeByName("bg2"):setVisible(true)
		arg_25_0:nodeByName("bg1_top"):setVisible(false)
		arg_25_0:nodeByName("bg1_bottom"):setVisible(false)
		arg_25_0:nodeByName("bg_conversion"):setVisible(true)
		arg_25_0.conversionBtn:setVisible(true)
		arg_25_0:updateConversionNum()
	else
		arg_25_0:nodeByName("bg2"):setVisible(false)
		arg_25_0:nodeByName("bg1_top"):setVisible(true)
		arg_25_0:nodeByName("bg1_bottom"):setVisible(true)
		arg_25_0:nodeByName("bg_conversion"):setVisible(false)
		arg_25_0.conversionBtn:setVisible(false)
	end
end

function var_0_0.clipIcon(arg_26_0, arg_26_1, arg_26_2)
	arg_26_1:removeAllChildren()

	local var_26_0 = xyd.AssetLoader.get():loadSprite("images/icon/eco/" .. arg_26_2 .. ".png")
	local var_26_1 = arg_26_1:getContentSize()

	var_26_0:setAnchorPoint(0.5, 0.5)
	var_26_0:setPosition(var_26_1.width / 2, var_26_1.height / 2)
	var_26_0:addTo(arg_26_1)
end

function var_0_0.updateUpgradeTime(arg_27_0)
	if arg_27_0.handle1 then
		var_0_1.unscheduleGlobal(arg_27_0.handle1)

		arg_27_0.handle1 = nil
	end

	local var_27_0

	if arg_27_0.eventCentre.adminStartTime > 0 then
		var_27_0 = arg_27_0.eventCentre.adminNeedTime - (xyd.ServerTime.get():getServerTime() - arg_27_0.eventCentre.adminStartTime)

		arg_27_0:nodeByName("bg_top"):setVisible(true)
		arg_27_0:nodeByName("levup_time"):setString(xyd.secondsToString1(var_27_0))
		arg_27_0:nodeByName("bar_time"):setPercent(math.min((1 - var_27_0 / arg_27_0.eventCentre.adminNeedTime) * 100, 100))
		arg_27_0.levupBtn:setVisible(false)
	else
		var_27_0 = 0

		arg_27_0:nodeByName("bg_top"):setVisible(false)
		arg_27_0.levupBtn:setVisible(true)
		arg_27_0:nodeByName("bar_time"):setPercent(0)
	end

	if var_27_0 > 0 then
		arg_27_0:nodeByName("bg_top"):setVisible(true)

		arg_27_0.handle1 = var_0_1.scheduleGlobal(function()
			var_27_0 = var_27_0 - 1

			if not tolua.isnull(arg_27_0) then
				arg_27_0:nodeByName("levup_time"):setString(xyd.secondsToString1(var_27_0))
				arg_27_0:nodeByName("bar_time"):setPercent((1 - var_27_0 / arg_27_0.eventCentre.adminNeedTime) * 100)
				arg_27_0.levupBtn:setVisible(false)
			end

			if var_27_0 <= 0 and arg_27_0.handle1 then
				arg_27_0.eventCentre.adminLev = arg_27_0.eventCentre.adminLev + 1
				arg_27_0.eventCentre.buidingInfo["" .. xyd.EventCentreBuildingType.ADMIN].lev = arg_27_0.eventCentre.adminLev
				arg_27_0.eventCentre.adminNeedTime = 0
				arg_27_0.eventCentre.adminStartTime = 0

				arg_27_0:nodeByName("bar_time"):setPercent(0)
				var_0_1.unscheduleGlobal(arg_27_0.handle1)

				arg_27_0.handle1 = nil

				if not tolua.isnull(arg_27_0) then
					arg_27_0.levupBtn:setVisible(true)
					arg_27_0:nodeByName("bg_top"):setVisible(false)
				end
			end
		end, 1)
	else
		arg_27_0:nodeByName("bg_top"):setVisible(false)
		arg_27_0.levupBtn:setVisible(true)

		if arg_27_0.handle1 then
			var_0_1.unscheduleGlobal(arg_27_0.handle1)

			arg_27_0.handle1 = nil
		end
	end

	if arg_27_0.eventCentre.adminLev ~= arg_27_0.lev then
		arg_27_0.lev = arg_27_0.eventCentre.adminLev

		arg_27_0:updateAdminLev()
	end
end

function var_0_0.levupSucceed(arg_29_0)
	local var_29_0 = {
		type = xyd.EventCentreBuildingType.ADMIN
	}

	arg_29_0.eventCentre:confirmBuildingUpgrade(var_29_0, function(arg_30_0, arg_30_1)
		if arg_30_0 == xyd.error.OK then
			local var_30_0 = {
				type = xyd.EventCentreBuildingType.ADMIN,
				lev = arg_29_0.eventCentre.adminLev
			}

			xyd.WindowManager.get():openWindow("building_levelup", var_30_0)

			arg_29_0.eventCentre.adminNewEvolve = 0
		end
	end)
end

function var_0_0.updateConversionNum(arg_31_0)
	local var_31_0 = arg_31_0.info["" .. arg_31_0.from .. arg_31_0.to]

	arg_31_0:nodeByName("conversion_tip"):setString(string.format(var_0_2:translation("ADMIN_CONVERSION"), var_0_4 - var_31_0, var_0_4))

	if var_31_0 < var_0_4 then
		local var_31_1 = arg_31_0.to * 100 + var_31_0 + 1

		arg_31_0.fromNum = var_0_3:from(var_31_1, arg_31_0.from)
		arg_31_0.toNum = var_0_3:resource(var_31_1)

		arg_31_0:nodeByName("from_num"):setVisible(true)
		arg_31_0:nodeByName("to_num"):setVisible(true)
		arg_31_0:nodeByName("from_num"):setString(arg_31_0.fromNum)
		arg_31_0:nodeByName("to_num"):setString(arg_31_0.toNum)
	else
		arg_31_0:nodeByName("from_num"):setVisible(false)
		arg_31_0:nodeByName("to_num"):setVisible(false)
	end
end

function var_0_0.isCostEnough(arg_32_0)
	if arg_32_0.from == xyd.currencyType.MANA and arg_32_0.selfPlayer.mana < arg_32_0.fromNum then
		return false
	elseif arg_32_0.from == xyd.currencyType.CRYSTAL and arg_32_0.selfPlayer.crystal < arg_32_0.fromNum then
		return false
	elseif arg_32_0.from == xyd.currencyType.MAGIC_DUST and arg_32_0.selfPlayer.magicDust < arg_32_0.fromNum then
		return false
	elseif arg_32_0.from == xyd.currencyType.MAGIC_LIQUID and arg_32_0.selfPlayer.magicLiquid < arg_32_0.fromNum then
		return false
	elseif arg_32_0.from == xyd.currencyType.MAGIC_ENERGY and arg_32_0.selfPlayer.magicEnergy < arg_32_0.fromNum then
		return false
	end

	return true
end

function var_0_0.openDialog(arg_33_0, arg_33_1, arg_33_2)
	if arg_33_0.dialogHandle then
		var_0_1.unscheduleGlobal(arg_33_0.dialogHandle)
	end

	arg_33_0:nodeByName("dialog"):setVisible(true)
	arg_33_0:nodeByName("dialog_txt"):setString(arg_33_1)

	arg_33_0.dialogHandle = var_0_1.performWithDelayGlobal(function()
		arg_33_0:nodeByName("dialog"):setVisible(false)
	end, arg_33_2)
end

return var_0_0
