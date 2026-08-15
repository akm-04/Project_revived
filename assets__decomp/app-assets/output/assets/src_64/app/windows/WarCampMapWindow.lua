local var_0_0 = class("WarCampMapWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.warCamp
local var_0_4 = xyd.tables.warCampTimeline
local var_0_5 = 150
local var_0_6 = 86400
local var_0_7 = 36000
local var_0_8 = 79200
local var_0_9 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.warCamp_ = xyd.ModelManager.get():loadModel(xyd.ModelType.WAR_CAMP)
	arg_1_0.baseInfo = arg_1_0.warCamp_.baseInfo
	arg_1_0.camp_ = arg_1_0.warCamp_:getCampType()

	if arg_1_2 then
		arg_1_0.mapStatus = arg_1_2
	end

	arg_1_0.activity = arg_1_0.warCamp_.activity
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.handle_ = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	if arg_3_0.mapStatus then
		if arg_3_0.mapStatus.cityID then
			local var_3_0 = arg_3_0:nodeByName("node" .. arg_3_0.mapStatus.cityID)
			local var_3_1 = cc.p(var_3_0:getPosition())
			local var_3_2 = {
				x = var_3_1.x / xyd.STAGE_WIDTH,
				y = var_3_1.y / xyd.STAGE_HEIGHT
			}
			local var_3_3 = {
				city_id = arg_3_0.mapStatus.cityID,
				anchorPoint = var_3_2
			}

			xyd.WindowManager.get():openWindow("war_camp_city", var_3_3)
		elseif arg_3_0.mapStatus.is_record then
			xyd.WindowManager.get():openWindow("war_camp_records")
		end
	end

	xyd.WindowManager.get():openWindow("war_camp_chat")
end

function var_0_0.checkCanPlay(arg_4_0)
	local var_4_0 = xyd.ServerTime.get():getServerTime()
	local var_4_1 = arg_4_0.warCamp_:getDayCount()

	if var_4_0 < arg_4_0.activity.start_time then
		return false
	elseif var_4_0 > arg_4_0.activity.end_time then
		return false
	end

	if var_0_4:isOpenWar(var_4_1) == 0 then
		return false
	end

	if xyd.ServerTime.get():getSecondsOfDay() >= var_0_8 or xyd.ServerTime.get():getSecondsOfDay() < var_0_7 then
		return false
	end

	return true
end

function var_0_0.willClose(arg_5_0, arg_5_1)
	var_0_0.super:willClose(arg_5_1)

	if xyd.WindowManager.get():getWindow("war_camp_chat") then
		xyd.WindowManager.get():closeWindow("war_camp_chat")
	end

	if arg_5_0.handle_ and next(arg_5_0.handle_) then
		for iter_5_0, iter_5_1 in pairs(arg_5_0.handle_) do
			if arg_5_0.handle_[iter_5_0] then
				var_0_1.unscheduleGlobal(arg_5_0.handle_[iter_5_0])

				arg_5_0.handle_[iter_5_0] = nil
			end
		end
	end
end

function var_0_0.layout(arg_6_0)
	arg_6_0:setupButton()
	arg_6_0:createMap()
	arg_6_0:nodeByName("text_ticket"):setString(var_0_2:translation("WAR_CAMP_MAP_TIPS_1"))
	arg_6_0:nodeByName("text_coin"):setString(var_0_2:translation("CAMP_BOSS_HONOR_TOTAL"))
	arg_6_0:updateTop()
end

function var_0_0.updateTop(arg_7_0)
	local var_7_0 = arg_7_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.campWarReviveItem)

	arg_7_0:nodeByName("text_ticket_num"):setString(var_7_0)
	arg_7_0:nodeByName("text_coin_num"):setString(arg_7_0.warCamp_:getScore())
end

function var_0_0.setupButton(arg_8_0)
	arg_8_0:nodeByName("btn_make_teams"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			if not arg_8_0:checkCanPlay() then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("WAR_CAMP_CANNOT_PLAY")
				})

				return
			end

			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("war_camp_team", {})
		end
	end)
	arg_8_0:nodeByName("btn_rank"):setTouchSwallowEnabled(true)
	arg_8_0:nodeByName("btn_rank"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_8_0.warCamp_:getScoreRank(function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					local var_11_0 = arg_11_1

					xyd.WindowManager.get():openWindow("war_camp_rank", var_11_0)
				end
			end)
		end
	end)
	arg_8_0:nodeByName("btn_reborn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			if not arg_8_0:checkCanPlay() then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("WAR_CAMP_CANNOT_PLAY")
				})

				return
			end

			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("war_camp_reborn")
		end
	end)
	arg_8_0:nodeByName("btn_report"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_8_0.warCamp_:getRecords(function(arg_14_0, arg_14_1)
				if arg_14_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("war_camp_records")
				end
			end)
		end
	end)
	arg_8_0:nodeByName("add_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_15_0 = xyd.tables.misc.campWarReviveItem
			local var_15_1 = xyd.tables.misc:getValue("camp_war_buy")
			local var_15_2 = xyd.tables.misc:getValue("camp_war_buy_get")
			local var_15_3 = var_0_2:translation("CAMP_WAR_BUY_TIPS")
			local var_15_4 = string.format(var_15_3, var_15_1, var_15_2)

			if var_15_1 > arg_8_0.selfPlayer.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
					local var_16_0 = {}

					var_16_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_16_0)
				end, nil, nil, arg_8_0.colorMode)

				return
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_15_4, function()
				arg_8_0.warCamp_:buyReviveItem(function(arg_18_0, arg_18_1)
					if arg_18_0 == xyd.error.OK then
						arg_8_0.selfPlayer:getBackpack():addItemsByID(var_15_0, var_15_2)
						arg_8_0:updateTop()
					end
				end)
			end, nil, nil, arg_8_0.colorMode)
		end
	end)
end

function var_0_0.createMap(arg_19_0)
	local var_19_0 = arg_19_0.warCamp_:getMaxCityNum()

	for iter_19_0 = 1, var_19_0 do
		local var_19_1 = arg_19_0:nodeByName("node" .. iter_19_0)

		var_19_1:setAnchorPoint(cc.p(0.5, 0.5))
		var_19_1:setContentSize(var_0_5, var_0_5)

		local var_19_2 = arg_19_0:nodeByName("city_" .. iter_19_0 .. "_click")

		var_19_2:setVisible(false)
		var_19_1:setTouchEnabled(true)
		var_19_1:setTouchSwallowEnabled(true)
		var_19_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
			if arg_20_0.name == "began" then
				var_19_2:setVisible(true)

				arg_19_0.preX = arg_20_0.x
				arg_19_0.preY = arg_20_0.y
				arg_19_0.isMove_ = false
			elseif arg_20_0.name == "moved" then
				local var_20_0 = 10

				if var_20_0 < math.abs(arg_20_0.x - arg_19_0.preX) or var_20_0 < math.abs(arg_20_0.y - arg_19_0.preY) then
					var_19_2:setVisible(false)

					arg_19_0.isMove_ = true
				end
			elseif arg_20_0.name == "ended" and not arg_19_0.isMove_ then
				var_19_2:setVisible(false)

				if not arg_19_0:checkCanPlay() then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("WAR_CAMP_CANNOT_PLAY")
					})

					return
				end

				local var_20_1 = cc.p(var_19_1:getPosition())
				local var_20_2 = {
					x = var_20_1.x / xyd.STAGE_WIDTH,
					y = var_20_1.y / xyd.STAGE_HEIGHT
				}
				local var_20_3 = {
					city_id = iter_19_0,
					anchorPoint = var_20_2
				}

				xyd.WindowManager.get():openWindow("war_camp_city", var_20_3)
			end

			return true
		end)

		local var_19_3 = arg_19_0.warCamp_:getMapInfoByMapID(iter_19_0)

		if var_19_3 and var_19_3.camp ~= xyd.WarCampSelectType.NONE then
			local var_19_4 = xyd.AssetLoader.get():loadSprite("windows/war_camp/war_map/flag_" .. var_19_3.camp .. ".png")

			var_19_4:setAnchorPoint(cc.p(0.5, 0))
			var_19_4:addTo(arg_19_0:nodeByName("layout"))

			local var_19_5 = cc.p(var_19_1:getPosition())

			var_19_4:setPosition(var_19_5)
		end

		if iter_19_0 ~= 1 and iter_19_0 ~= var_19_0 then
			local var_19_6, var_19_7 = arg_19_0:checkCanFight(iter_19_0, var_19_3)

			if var_19_6 ~= 0 then
				local var_19_8 = xyd.AssetLoader.get():loadSprite("windows/war_camp/war_map/time_bg.png")

				var_19_8:setAnchorPoint(cc.p(0.5, 1))
				var_19_8:addTo(arg_19_0:nodeByName("layout"))

				local var_19_9 = cc.p(var_19_1:getPosition())

				var_19_8:setPosition(var_19_9)

				local var_19_10 = arg_19_0:createTextLabel(var_19_7, 200, cc.ui.TEXT_ALIGN_CENTER, 24, cc.c3b(255, 255, 255))

				var_19_10:addTo(arg_19_0:nodeByName("layout"))
				var_19_10:setAnchorPoint(cc.p(0.5, 1))
				var_19_10:setPosition(cc.p(var_19_9.x, var_19_9.y - 5))
				var_19_10:enableOutline(cc.c4b(223, 120, 20, 255), 2)

				if var_19_6 > 0 then
					arg_19_0:updateTimeCount(var_19_10, iter_19_0, var_19_6, var_19_7, var_19_8)
				else
					var_19_10:setString(var_19_7)
				end
			end
		end
	end
end

function var_0_0.createTextLabel(arg_21_0, arg_21_1, arg_21_2, arg_21_3, arg_21_4, arg_21_5)
	local var_21_0 = {
		text = arg_21_1,
		align = arg_21_3,
		color = arg_21_5,
		size = arg_21_4,
		dimensions = cc.size(arg_21_2, 0)
	}

	return (xyd.AssetLoader.get():loadLabel(var_21_0))
end

function var_0_0.checkCanFight(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = 0
	local var_22_1 = ""
	local var_22_2 = xyd.ServerTime.get():getServerTime()
	local var_22_3 = var_0_3:openTime(arg_22_1)
	local var_22_4 = arg_22_0.warCamp_.activity.start_time
	local var_22_5 = (var_0_4:getEndWarDay() - 1) * var_0_6 + var_22_4

	if var_22_2 < var_22_3 + var_22_4 then
		var_22_0 = var_22_3 + var_22_4 - var_22_2
		var_22_1 = var_0_2:translation("WAR_CAMP_MAP_TIPS_3")

		return var_22_0, var_22_1
	elseif var_22_5 < var_22_2 then
		var_22_0 = var_22_5 - var_22_2
		var_22_1 = var_0_2:translation("WAR_CAMP_MAP_TIPS_5")

		return var_22_0, var_22_1
	end

	local var_22_6 = var_0_3:link(arg_22_1)
	local var_22_7 = false

	for iter_22_0 = 1, #var_22_6 do
		if arg_22_0.warCamp_:getMapInfoByMapID(var_22_6[iter_22_0]).camp == arg_22_0.camp_ then
			var_22_7 = true

			break
		end
	end

	if not var_22_7 and arg_22_2.camp ~= arg_22_0.camp_ then
		var_22_0 = -1
		var_22_1 = var_0_2:translation("WAR_CAMP_MAP_TIPS_4")

		return var_22_0, var_22_1
	end

	local var_22_8 = var_0_3:freeWordTime(arg_22_1)
	local var_22_9 = arg_22_2.time

	if var_22_2 <= var_22_9 + var_22_8 then
		var_22_0 = var_22_9 + var_22_8 - var_22_2
		var_22_1 = var_0_2:translation("WAR_CAMP_MAP_TIPS_2")

		return var_22_0, var_22_1
	end

	return var_22_0, var_22_1
end

function var_0_0.updateTimeCount(arg_23_0, arg_23_1, arg_23_2, arg_23_3, arg_23_4, arg_23_5)
	if arg_23_0.handle_[arg_23_2] then
		var_0_1.unscheduleGlobal(arg_23_0.handle_[arg_23_2])
	end

	local function var_23_0(arg_24_0)
		if arg_24_0 > var_0_6 then
			return xyd.secondsToString1(arg_24_0, 2)
		end

		return xyd.secondsToString(arg_24_0)
	end

	arg_23_1:setString(arg_23_4 .. var_23_0(arg_23_3))

	arg_23_0.handle_[arg_23_2] = var_0_1.scheduleGlobal(function()
		if arg_23_0 and not tolua.isnull(arg_23_0) then
			arg_23_3 = arg_23_3 - 1

			arg_23_1:setString(arg_23_4 .. var_23_0(arg_23_3))

			if arg_23_3 == 0 then
				arg_23_1:removeSelf()
				arg_23_5:removeSelf()

				if arg_23_0.handle_[arg_23_2] then
					var_0_1.unscheduleGlobal(arg_23_0.handle_[arg_23_2])

					arg_23_0.handle_[arg_23_2] = nil
				end
			end
		elseif arg_23_0.handle_[arg_23_2] then
			var_0_1.unscheduleGlobal(arg_23_0.handle_[arg_23_2])

			arg_23_0.handle_[arg_23_2] = nil
		end
	end, 1)
end

return var_0_0
