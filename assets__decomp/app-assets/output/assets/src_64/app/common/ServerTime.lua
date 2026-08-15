local var_0_0 = class("ServerTime")
local var_0_1 = require("framework.scheduler")

function var_0_0.get()
	if var_0_0.INSTANCE == nil then
		var_0_0.INSTANCE = var_0_0.new()
	end

	return var_0_0.INSTANCE
end

function var_0_0.ctor(arg_2_0)
	arg_2_0.canGetServerTime_ = false
	arg_2_0.serverTime_ = 0
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.treasureModel = xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE)
end

function var_0_0.start(arg_3_0)
	if arg_3_0.tickTaskHandle_ ~= nil then
		var_0_1.unscheduleGlobal(arg_3_0.tickTaskHandle_)

		arg_3_0.tickTaskHandle_ = nil
	end

	arg_3_0.tickTaskHandle_ = var_0_1.scheduleGlobal(function(arg_4_0)
		arg_3_0.serverTime_ = arg_3_0.serverTime_ + arg_4_0

		arg_3_0:doSysTimingAction()

		if arg_3_0.serverTime_ and math.floor(arg_3_0.serverTime_) % 2 == 0 then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.TICK_UPDATE
			})
		end
	end, 1)
end

function var_0_0.reset(arg_5_0)
	var_0_0.INSTANCE = nil

	if arg_5_0.tickTaskHandle_ ~= nil then
		var_0_1.unscheduleGlobal(arg_5_0.tickTaskHandle_)

		arg_5_0.tickTaskHandle_ = nil
	end
end

function var_0_0.getServerTime(arg_6_0)
	if arg_6_0.canGetServerTime_ then
		return math.floor(arg_6_0.serverTime_)
	else
		return nil
	end
end

function var_0_0.resetServerTime(arg_7_0, arg_7_1)
	arg_7_0.canGetServerTime_ = true
	arg_7_0.serverTime_ = arg_7_1

	arg_7_0:start()
end

function var_0_0.getSecondsOfDay(arg_8_0)
	local var_8_0 = 8

	if arg_8_0.canGetServerTime_ then
		return math.floor((arg_8_0.serverTime_ % 86400 + var_8_0 * 3600) % 86400)
	else
		return nil
	end
end

function var_0_0.doSysTimingAction(arg_9_0)
	local var_9_0

	if arg_9_0.canGetServerTime_ then
		var_9_0 = arg_9_0:getSecondsOfDay()
	else
		return
	end

	if var_9_0 == 18001 or var_9_0 == 43201 or var_9_0 == 50401 or var_9_0 == 64801 or var_9_0 == 72001 or var_9_0 == 75601 or var_9_0 == 82801 then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.UPDATE_MISSION_ONTIME
		})
	end

	if var_9_0 == 18001 then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.UPDATE_ACTIVITIES_ONTIME
		})
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.AUCTION_REFRESH_ONTIME
		})
	end

	if var_9_0 == 43201 or var_9_0 == 64801 or var_9_0 == 75601 then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.UPDATE_SHOP_ONTIME
		})
	end

	if var_9_0 == xyd.tables.misc.auctionEndTime + 1 then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.AUCTION_REFRESH_ONTIME
		})
	end

	local var_9_1 = false
	local var_9_2 = xyd.WindowManager.get():getWindow("main_scene_middle")

	if var_9_2 then
		var_9_1 = var_9_2.redMarks[xyd.RedMarks.SUMMON]:isVisible()
	else
		var_9_1 = true
	end

	local var_9_3 = arg_9_0.selfPlayer:getNextFreeManaSummonTime()
	local var_9_4 = arg_9_0.selfPlayer:getNextFreeCrystalSummonTime()

	if (var_9_3 == 0 and arg_9_0.selfPlayer:getFreeManaNum() > 0 or var_9_4 == 0) and not var_9_1 then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHECK_MIDDLE_RED_MARK,
			params = xyd.CheckMiddleRed.SUMMON
		})
	end

	arg_9_0:handleActCentreRedPoint()
	arg_9_0:checkPracticeRedPoint()
	arg_9_0:handleCourseRedPoint()

	local var_9_5 = xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN)
	local var_9_6 = var_9_5.normal

	if arg_9_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PET) and var_9_6 and var_9_6.begin_sweep_time and var_9_6.begin_sweep_time > 0 and not var_9_5.has_red and var_9_6.now_floor and var_9_6.max_floor then
		local var_9_7 = var_9_6.begin_sweep_time - arg_9_0:getServerTime() + xyd.tables.petCampaign:getSweepTime(var_9_6.now_floor, var_9_6.max_floor)

		if var_9_7 and var_9_7 <= 0 then
			var_9_5.has_red = true

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.CHECK_MIDDLE_RED_MARK,
				params = xyd.CheckMiddleRed.SKY
			})
		end
	end

	arg_9_0.treasureModel:checkRed()

	if var_9_0 == 18010 or var_9_0 == 43210 then
		xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD):loadGuildWarRedPointInfo(function(arg_10_0)
			if arg_10_0 == xyd.error.OK then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.DRINK_NOTIF
				})
			end
		end)
	end
end

function var_0_0.checkPracticeRedPoint(arg_11_0)
	if not arg_11_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PRACTICE) then
		return
	end

	local var_11_0 = false

	if xyd.WindowManager.get():getWindow("main_scene_middle") then
		-- block empty
	else
		var_11_0 = true
	end

	if not var_11_0 and arg_11_0.selfPlayer:checkPracticeRedMark() then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHECK_MIDDLE_RED_MARK,
			params = xyd.CheckMiddleRed.PRACTICE
		})
	end
end

function var_0_0.handleActCentreRedPoint(arg_12_0)
	local var_12_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

	local function var_12_1()
		local var_13_0, var_13_1 = var_12_0:getRedPointInfo()

		if xyd.WindowManager.get():getWindow("main_scene_middle") then
			if var_13_0 then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.CHECK_MIDDLE_RED_MARK,
					params = xyd.CheckMiddleRed.EVENT_CENTRE
				})
			else
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.CHECK_MIDDLE_RED_MARK,
					params = xyd.CheckMiddleRed.EVENT_CENTRE_CANCEL
				})
			end
		end

		if var_13_1 == 0 then
			var_12_0:getBuildingList({}, function(arg_14_0)
				if arg_14_0 == xyd.error.OK then
					var_12_1()
				end
			end)
		end
	end

	if not var_12_0.deskInfo then
		var_12_0:getBuildingList({}, function(arg_15_0)
			if arg_15_0 == xyd.error.OK then
				var_12_1()
			end
		end)
	else
		var_12_1()
	end
end

function var_0_0.handleCourseRedPoint(arg_16_0)
	if not arg_16_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_COURSE) then
		return
	end

	local var_16_0 = false

	if xyd.WindowManager.get():getWindow("main_scene_middle") then
		-- block empty
	else
		var_16_0 = true
	end

	local var_16_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)

	if not var_16_0 and var_16_1:isCourseRedPointShow() then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHECK_MIDDLE_RED_MARK,
			params = xyd.CheckMiddleRed.COURSE
		})
	end
end

function var_0_0.getNotificationDelay(arg_17_0, arg_17_1)
	local var_17_0

	if arg_17_0.canGetServerTime_ then
		var_17_0 = arg_17_0:getSecondsOfDay()
	else
		return -1
	end

	local function var_17_1()
		local var_18_0 = 43201 - var_17_0

		if var_18_0 > 0 then
			return var_18_0
		end

		return 86400 + var_18_0
	end

	local function var_17_2()
		local var_19_0 = 64801 - var_17_0

		if var_19_0 > 0 then
			return var_19_0
		end

		return 86400 + var_19_0
	end

	local function var_17_3()
		if arg_17_0.selfPlayer:getTotalEnergyCoolTime() < 1 then
			return -1
		end

		return arg_17_0.selfPlayer:getTotalEnergyCoolTime()
	end

	local function var_17_4()
		return -1
	end

	local function var_17_5()
		return -1
	end

	local function var_17_6()
		local var_23_0 = 32401 - var_17_0

		if var_23_0 > 0 then
			return var_23_0
		end

		return 86400 + var_23_0
	end

	local function var_17_7()
		local var_24_0 = 75601 - var_17_0

		if var_24_0 > 0 then
			return var_24_0
		end

		return 86400 + var_24_0
	end

	local function var_17_8()
		if arg_17_0.selfPlayer:getTotalSkillRecoverTime() < 1 then
			return -1
		end

		return arg_17_0.selfPlayer:getTotalSkillRecoverTime()
	end

	local function var_17_9()
		return -1
	end

	local function var_17_10()
		local var_27_0
		local var_27_1

		for iter_27_0, iter_27_1 in pairs(arg_17_0.treasureModel.teams) do
			if iter_27_1.start_time + xyd.tables.misc.workTimeLimit > arg_17_0.serverTime_ then
				if not var_27_0 or var_27_0 > iter_27_1.start_time + xyd.tables.misc.workTimeLimit - arg_17_0.serverTime_ then
					var_27_0 = iter_27_1.start_time + xyd.tables.misc.workTimeLimit - arg_17_0.serverTime_
				end
			else
				var_27_1 = 0
			end
		end

		return var_27_0 or var_27_1 or -1
	end

	local function var_17_11()
		if arg_17_0.selfPlayer:getTotalSpiritEnergyCoolTime() < 1 then
			return -1
		end

		return arg_17_0.selfPlayer:getTotalSpiritEnergyCoolTime()
	end

	local function var_17_12()
		local var_29_0 = arg_17_0.selfPlayer.spiritCampaignInfo

		if not var_29_0 or var_29_0.auto_start_time < 1 then
			return -1
		end

		local var_29_1 = var_29_0.auto_times * xyd.tables.misc:getValue("spirit_auto_time") * 60 - (xyd.ServerTime.get():getServerTime() - var_29_0.auto_start_time)

		if var_29_1 < 1 then
			return -1
		end

		return var_29_1
	end

	local var_17_13 = {
		var_17_1,
		var_17_2,
		var_17_3,
		var_17_4,
		var_17_5,
		var_17_6,
		var_17_7,
		var_17_8,
		var_17_9,
		var_17_10,
		var_17_11,
		var_17_12
	}

	if var_17_13[arg_17_1] then
		return var_17_13[arg_17_1]()
	end

	return -1
end

return var_0_0
