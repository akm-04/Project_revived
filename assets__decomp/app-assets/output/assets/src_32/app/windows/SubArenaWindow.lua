local var_0_0 = class("SubArenaWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.functionOpen
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()

	local var_2_0 = arg_2_0:nodeByName("arena_node")

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_ARENA) then
		xyd.nodeEventSample(var_2_0, {}, function()
			xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA):loadArenaInfo(function(arg_4_0, arg_4_1)
				if arg_4_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("arena")
				end
			end)
		end)
	else
		arg_2_0:addLock(var_2_0, xyd.FunctionID.ID_ARENA)
	end

	local var_2_1 = arg_2_0:nodeByName("peak_arena_node")

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PEAK_ARENA) then
		xyd.nodeEventSample(var_2_1, {}, function()
			if arg_2_0.selfPlayer.isOldTop == 1 then
				xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA_OLD):loadPeakArena(function(arg_6_0)
					if arg_6_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("peak_arena_old")
					end
				end)
			else
				xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA):loadPeakArena(function(arg_7_0)
					if arg_7_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("peak_arena")
					end
				end)
			end
		end)
	else
		arg_2_0:addLock(var_2_1, xyd.FunctionID.ID_PEAK_ARENA)
	end

	local var_2_2 = arg_2_0:nodeByName("region_arena_node")

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_REGION_ARENA) then
		xyd.nodeEventSample(var_2_2, {}, function()
			xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA):getRegionArenaInfo(function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					arg_2_0.selfPlayer.kingCoin = arg_9_1.king_coin

					if arg_9_1.is_close == 0 then
						xyd.WindowManager.get():openWindow("region_arena")
					else
						xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYOFFS):getBasePlayers(function(arg_10_0, arg_10_1)
							if arg_10_0 == xyd.error.OK then
								if arg_10_1.playoff_info.is_open == 1 then
									local var_10_0 = {
										is_playoff = true,
										response = arg_10_1
									}

									xyd.WindowManager.get():openWindow("region_arena", var_10_0)
								else
									local var_10_1 = var_0_2:translation("REGION_ARENA_CLOSE_TIP")

									xyd.WindowManager.get():openWindow("toast", {
										message = var_10_1
									})
								end
							else
								local var_10_2 = var_0_2:translation("REGION_ARENA_CLOSE_TIP")

								xyd.WindowManager.get():openWindow("toast", {
									message = var_10_2
								})
							end
						end)
					end
				end
			end)
		end)
	else
		arg_2_0:addLock(var_2_2, xyd.FunctionID.ID_REGION_ARENA)
	end

	local var_2_3 = arg_2_0:nodeByName("cross_arena_node")

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_CHAMPIONS_LEAGUE) then
		xyd.nodeEventSample(var_2_3, {}, function()
			xyd.ModelManager.get():loadModel(xyd.ModelType.CHAMPIONS_LEAGUE):loadInfo(function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("champions_league", arg_12_1)
				end
			end)
		end)
	else
		arg_2_0:addLock(var_2_3, xyd.FunctionID.ID_CHAMPIONS_LEAGUE)
	end

	arg_2_0.arenaRedP = arg_2_0:nodeByName("arena_red_p")

	arg_2_0:checkRedMark(xyd.CheckMiddleRed.ARENA)

	arg_2_0.peakAreRedP = arg_2_0:nodeByName("peak_are_red_p")

	arg_2_0:checkRedMark(xyd.CheckMiddleRed.PEAK)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.CHECK_MIDDLE_RED_MARK, function(arg_13_0)
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0:checkRedMark(arg_13_0.params)
		end
	end)

	for iter_2_0 = 1, 4 do
		arg_2_0:nodeByName("des" .. iter_2_0):setString(xyd.tables.translation:translation("PK_TIP" .. iter_2_0))
	end
end

function var_0_0.addLock(arg_14_0, arg_14_1, arg_14_2)
	arg_14_1:runActionOnce(cc.TintBy:create(0, -100, -100, -100))

	local var_14_0 = xyd.AssetLoader.get():loadSprite("windows/common/lock.png")

	var_14_0:addTo(arg_14_1)

	local var_14_1 = arg_14_1:getContentSize()

	var_14_0:setPosition(var_14_1.width / 2, var_14_1.height / 2)
	xyd.nodeEventSample(arg_14_1, {}, function()
		local var_15_0 = var_0_1:tip(arg_14_2)

		if var_15_0 == "" then
			var_15_0 = var_0_2:translation("FUNCTION_OPEN_TIP_OTHER")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_15_0
		})
	end)
end

function var_0_0.checkRedMark(arg_16_0, arg_16_1)
	if arg_16_1 == xyd.CheckMiddleRed.ARENA or arg_16_1 == xyd.CheckMiddleRed.ARENA_CANCEL then
		if arg_16_0.selfPlayer.arenaRedMarkEnable then
			arg_16_0.arenaRedP:setVisible(true)
		else
			arg_16_0.arenaRedP:setVisible(false)
		end
	elseif arg_16_1 == xyd.CheckMiddleRed.PEAK or arg_16_1 == xyd.CheckMiddleRed.PEAK_CANCEL then
		if arg_16_0.selfPlayer.peakArenaRedMarkEnable then
			arg_16_0.peakAreRedP:setVisible(true)
		else
			arg_16_0.peakAreRedP:setVisible(false)
		end
	end
end

function var_0_0.didClose(arg_17_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {}
	})
end

return var_0_0
