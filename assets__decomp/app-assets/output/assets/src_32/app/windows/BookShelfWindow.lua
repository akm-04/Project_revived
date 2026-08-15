local var_0_0 = class("BookShelfWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.bookShelfTable

var_0_0.LILIANG_NUM = "liliang_num"
var_0_0.ZHILI_NUM = "zhili_num"
var_0_0.MINJIE_NUM = "minjie_num"
var_0_0.LILIANG = "liliang"
var_0_0.ZHILI = "zhili"
var_0_0.MINJIE = "minjie"
var_0_0.MAGIC_WORDS = "mid"
var_0_0.MAGIC_EXP = "mid_exp"
var_0_0.SKILL_LIMIT = "bottom_1"
var_0_0.HERO_ATTRIBUTE = "bottom_2"
var_0_0.TOP_BG = "top_container"
var_0_0.SKILL_LEV = "skill_lev"
var_0_0.UPGRADE = "upgrade"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.bookShelfInfo = arg_1_2
end

function var_0_0.init(arg_2_0)
	arg_2_0.lev = arg_2_0.bookShelfInfo.lev
	arg_2_0.startTime = arg_2_0.bookShelfInfo.start_time
	arg_2_0.needTime = arg_2_0.bookShelfInfo.need_time
	arg_2_0.magicExp = arg_2_0.selfPlayer.magicExp
	arg_2_0.newEvolve = arg_2_0.bookShelfInfo.new_evolve

	arg_2_0:UpdateUpGradeTime()
	arg_2_0:updateLevShow()
	arg_2_0:updateMidShow()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_title"):setString(xyd.tables.eventCentreTable:name(xyd.EventCentreBuildingType.BOOKSHELF))
	arg_3_0:nodeByName("txt_cancel"):setString(var_0_2:translation("CANCEL"))
	arg_3_0:nodeByName("txt_speed_up"):setString(var_0_2:translation("EVENT_CENTRE_TIP2"))
	arg_3_0:nodeByName("txt_upgrade"):setString(var_0_2:translation("HERO_MAIN_TEXT_13"))
	arg_3_0:nodeByName(var_0_0.LILIANG):setString(var_0_2:translation("WULICHENGZHANG"))
	arg_3_0:nodeByName(var_0_0.ZHILI):setString(var_0_2:translation("FASHUCHENGZHANG"))
	arg_3_0:nodeByName(var_0_0.MINJIE):setString(var_0_2:translation("LINGQIAOCHENGZHANG"))
	arg_3_0:nodeByName(var_0_0.SKILL_LIMIT):setString(var_0_2:translation("SKILL_LEV_UP_LIMIT"))
	arg_3_0:nodeByName(var_0_0.HERO_ATTRIBUTE):setString(var_0_2:translation("HERO_ATTRIBUTE"))
	arg_3_0:nodeByName(var_0_0.MAGIC_WORDS):setString(var_0_2:translation("MAGIC_EXP") .. ": ")

	if arg_3_0.lev >= 100 then
		arg_3_0:nodeByName(var_0_0.UPGRADE):setVisible(false)
	end

	arg_3_0:nodeByName(var_0_0.UPGRADE):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName(var_0_0.UPGRADE), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_4_0 = #var_0_3:ids()

			if arg_3_0.lev == var_4_0 then
				local var_4_1 = xyd.tables.eventCentreTable:name(xyd.EventCentreBuildingType.BOOKSHELF)
				local var_4_2 = string.format(var_0_2:translation("HIGHEST_LEV"), var_4_1)

				xyd.WindowManager.get():openWindow("toast", {
					message = var_4_2
				})

				return
			end

			if arg_3_0.startTime > 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("BUILDING_LEVING_UP")
				})
			else
				local var_4_3 = {
					type = xyd.EventCentreBuildingType.BOOKSHELF,
					lev = arg_3_0.lev
				}

				xyd.WindowManager.get():openWindow("event_centre_upgrade", var_4_3)
			end

			return true
		end
	end)
	arg_3_0:nodeByName("speed_up_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("speed_up_btn"), arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_5_0 = arg_3_0:countSpeedUpCost()

			if var_5_0 > arg_3_0.selfPlayer.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
					local var_6_0 = {}

					var_6_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_6_0)
				end, nil, nil, xyd.ColorMode.GREEN)
			else
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_2:translation("COST_TO_UPGRADE"), var_5_0), function()
					arg_3_0.currentTime = tonumber(xyd.ServerTime.get():getServerTime())

					local var_7_0 = {
						type = xyd.EventCentreBuildingType.BOOKSHELF
					}

					arg_3_0.eventCentre:speedUpBuilding(var_7_0, function(arg_8_0, arg_8_1)
						if arg_8_0 == xyd.error.OK then
							arg_3_0.bookShelfInfo = arg_8_1

							arg_3_0.selfPlayer:updateBookShelfLev(arg_3_0.bookShelfInfo.lev)
							arg_3_0:init()

							if arg_3_0.lev >= 100 then
								arg_3_0:nodeByName(var_0_0.UPGRADE):setVisible(false)
							end
						end
					end)
				end, nil, nil, xyd.ColorMode.GREEN)
			end
		end
	end)
	arg_3_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("cancel_btn"), arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("CANCEL_UPGRADE"), function()
				local var_10_0 = {
					type = xyd.EventCentreBuildingType.BOOKSHELF
				}

				arg_3_0.eventCentre:cancelEvolveBuilding(var_10_0, function(arg_11_0, arg_11_1)
					if arg_11_0 == xyd.error.OK then
						arg_3_0.bookShelfInfo = arg_11_1.building_info

						arg_3_0:init()
						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.REFRESH_MAGIC_RES
						})

						local var_11_0 = {
							resolve_types = arg_11_1.return_res_id,
							resolve_nums = arg_11_1.return_res_num,
							resolve_crits = {}
						}

						xyd.WindowManager.get():openWindow("recycle_award", var_11_0)
					end
				end)
			end, nil, nil, xyd.ColorMode.GREEN)
		end
	end)
end

function var_0_0.didOpen(arg_12_0)
	var_0_0.super.didOpen(arg_12_0, params)
	arg_12_0:addBlockLayer()
end

function var_0_0.willOpen(arg_13_0, arg_13_1)
	var_0_0.super.willOpen(arg_13_0, arg_13_1)
	arg_13_0:init()
	arg_13_0:layout()
end

function var_0_0.UpdateUpGradeTime(arg_14_0)
	if arg_14_0.handler then
		var_0_1.unscheduleGlobal(arg_14_0.handler)

		arg_14_0.handler = nil
	end

	local var_14_0

	if arg_14_0.startTime > 0 then
		var_14_0 = arg_14_0.needTime - (xyd.ServerTime.get():getServerTime() - arg_14_0.startTime)
	else
		var_14_0 = 0
	end

	if var_14_0 > 0 then
		arg_14_0:nodeByName("upgrade_time_txt"):setString(xyd.secondsToString1(var_14_0))
		arg_14_0:nodeByName("loading_bar"):setPercent(100 - math.floor(var_14_0 / arg_14_0.needTime * 100))
		arg_14_0:nodeByName(var_0_0.UPGRADE):setVisible(false)
		arg_14_0:nodeByName(var_0_0.TOP_BG):setVisible(true)

		arg_14_0.handler = var_0_1.scheduleGlobal(function()
			var_14_0 = var_14_0 - 1

			if not tolua.isnull(arg_14_0) then
				arg_14_0:nodeByName("upgrade_time_txt"):setString(xyd.secondsToString1(var_14_0))
				arg_14_0:nodeByName("loading_bar"):setPercent(100 - math.floor(var_14_0 / arg_14_0.needTime * 100))
				arg_14_0:nodeByName(var_0_0.TOP_BG):setVisible(true)
			end

			if var_14_0 <= 0 and arg_14_0.handler then
				var_0_1.unscheduleGlobal(arg_14_0.handler)

				arg_14_0.handler = nil

				if not tolua.isnull(arg_14_0) then
					arg_14_0:nodeByName(var_0_0.TOP_BG):setVisible(false)
					arg_14_0:nodeByName(var_0_0.UPGRADE):setVisible(true)
				end

				if arg_14_0.lev >= 100 then
					arg_14_0:nodeByName(var_0_0.UPGRADE):setVisible(false)
				end

				arg_14_0.eventCentre:getBuildingList({}, function(arg_16_0, arg_16_1)
					if arg_16_0 == xyd.error.OK then
						arg_14_0.bookShelfInfo = arg_16_1.building_list[tostring(xyd.EventCentreBuildingType.BOOKSHELF)]

						arg_14_0:init()
					end
				end)
			end
		end, 1)
	else
		arg_14_0:nodeByName(var_0_0.TOP_BG):setVisible(false)
		arg_14_0:nodeByName(var_0_0.UPGRADE):setVisible(true)
	end
end

function var_0_0.countSpeedUpCost(arg_17_0)
	local var_17_0 = 0

	arg_17_0.currentTime = tonumber(xyd.ServerTime.get():getServerTime())

	local var_17_1 = arg_17_0.startTime + var_0_3:time(arg_17_0.lev) - arg_17_0.currentTime

	if var_17_1 <= 14400 then
		var_17_0 = math.ceil(var_17_1 / 72)
	elseif var_17_1 > 14400 and var_17_1 <= 43200 then
		var_17_0 = math.ceil((var_17_1 - 14400) / 144 + 200)
	else
		var_17_0 = math.ceil((var_17_1 - 43200) / 432 + 400)
	end

	return var_17_0
end

function var_0_0.updateLevShow(arg_18_0)
	arg_18_0:nodeByName("txt_lv"):setString("LV" .. arg_18_0.lev)

	if arg_18_0.newEvolve == 1 then
		local var_18_0 = {
			type = xyd.EventCentreBuildingType.BOOKSHELF
		}

		arg_18_0.eventCentre:confirmBuildingUpgrade(var_18_0, function(arg_19_0, arg_19_1)
			if arg_19_0 == xyd.error.OK then
				arg_18_0.newEvolve = 0

				local var_19_0 = {
					type = xyd.EventCentreBuildingType.BOOKSHELF,
					lev = arg_18_0.lev
				}

				xyd.WindowManager.get():openWindow("building_levelup", var_19_0)
			end
		end)
	end
end

function var_0_0.updateMidShow(arg_20_0)
	arg_20_0:nodeByName(var_0_0.LILIANG_NUM):setString("+" .. var_0_3:attribute(arg_20_0.lev)[xyd.AttributeType.STRENGTH] .. "%")
	arg_20_0:nodeByName(var_0_0.ZHILI_NUM):setString("+" .. var_0_3:attribute(arg_20_0.lev)[xyd.AttributeType.WISE] .. "%")
	arg_20_0:nodeByName(var_0_0.MINJIE_NUM):setString("+" .. var_0_3:attribute(arg_20_0.lev)[xyd.AttributeType.AGILE] .. "%")
	arg_20_0:nodeByName(var_0_0.SKILL_LEV):setString("+" .. var_0_3:upperLimit(arg_20_0.lev))
	arg_20_0:nodeByName(var_0_0.MAGIC_EXP):setString(arg_20_0.magicExp)
end

function var_0_0.willClose(arg_21_0)
	var_0_0.super.willClose(arg_21_0, params)

	if arg_21_0.handler then
		var_0_1.unscheduleGlobal(arg_21_0.handler)

		arg_21_0.handler = nil
	end
end

return var_0_0
