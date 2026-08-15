local var_0_0 = class("AdventureEventWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.adventureEvent
local var_0_5 = xyd.tables.adventureSummon
local var_0_6 = 2

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.adventureEvent = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
	arg_1_0.eventTable = arg_1_0.adventureEvent.adventureEventInfo
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:nodeByName("btn_left"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.began then
			arg_3_0:nodeByName("btn_left"):setScale(0.9)
		elseif arg_4_1 == ccui.TouchEventType.moved then
			arg_3_0:nodeByName("btn_left"):setScale(1)
		elseif arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0:nodeByName("btn_left"):setScale(1)

			arg_3_0.pageIndex_ = arg_3_0.pageIndex_ - 1

			arg_3_0:updateContainer()
		end
	end)
	arg_3_0:nodeByName("btn_right"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			arg_3_0:nodeByName("btn_right"):setScale(0.9)
		elseif arg_5_1 == ccui.TouchEventType.moved then
			arg_3_0:nodeByName("btn_right"):setScale(1)
		elseif arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0:nodeByName("btn_right"):setScale(1)

			arg_3_0.pageIndex_ = arg_3_0.pageIndex_ + 1

			arg_3_0:updateContainer()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.ADVENTURE_EVENT_FINISH, function(arg_6_0)
		arg_3_0.eventTable = arg_3_0.adventureEvent.adventureEventInfo

		arg_3_0:layout()
	end)
end

function var_0_0.didClose(arg_7_0, arg_7_1)
	var_0_0.super:didClose(arg_7_1)
end

function var_0_0.updateContainer(arg_8_0)
	arg_8_0:nodeByName("page"):setString(arg_8_0.pageIndex_ .. "/" .. arg_8_0.maxPage)

	if arg_8_0.pageIndex_ <= 1 then
		arg_8_0:nodeByName("btn_left"):setTouchEnabled(false)
		arg_8_0:nodeByName("btn_left"):setVisible(false)
	else
		arg_8_0:nodeByName("btn_left"):setTouchEnabled(true)
		arg_8_0:nodeByName("btn_left"):setVisible(true)
	end

	if arg_8_0.pageIndex_ >= arg_8_0.maxPage then
		arg_8_0:nodeByName("btn_right"):setTouchEnabled(false)
		arg_8_0:nodeByName("btn_right"):setVisible(false)
	else
		arg_8_0:nodeByName("btn_right"):setTouchEnabled(true)
		arg_8_0:nodeByName("btn_right"):setVisible(true)
	end

	if arg_8_0.pageIndex_ == arg_8_0.maxPage and arg_8_0.maxPage * var_0_6 > #arg_8_0.eventTable then
		arg_8_0:nodeByName("container_right"):setVisible(false)
		arg_8_0:updateContainerContent(arg_8_0:nodeByName("container_left"), arg_8_0.pageIndex_ * var_0_6 - 1)
	else
		arg_8_0:nodeByName("container_right"):setVisible(true)
		arg_8_0:updateContainerContent(arg_8_0:nodeByName("container_left"), arg_8_0.pageIndex_ * var_0_6 - 1)
		arg_8_0:updateContainerContent(arg_8_0:nodeByName("container_right"), arg_8_0.pageIndex_ * var_0_6)
	end
end

function var_0_0.updateContainerContent(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_0.eventTable[arg_9_2] then
		local var_9_0 = arg_9_0.eventTable[arg_9_2].id
		local var_9_1
		local var_9_2
		local var_9_3
		local var_9_4 = arg_9_1:getChildByName("img")
		local var_9_5 = arg_9_1:getChildByName("title")
		local var_9_6 = arg_9_1:getChildByName("card_container")
		local var_9_7 = arg_9_1:getChildByName("border")
		local var_9_8 = arg_9_1:getChildByName("effect")
		local var_9_9 = "skeletons/adventure/adventure_window_light"
		local var_9_10 = var_0_2.new(var_9_9 .. ".json", var_9_9 .. ".atlas", 1)

		var_9_6:removeAllChildren()
		var_9_4:removeAllChildren()
		var_9_5:removeAllChildren()

		if arg_9_0.eventTable[arg_9_2].event_info.end_time and arg_9_0.eventTable[arg_9_2].event_info.end_time > 0 then
			var_9_1 = xyd.AssetLoader.get():loadSprite(var_0_4:titleBg(var_9_0))
			var_9_2 = xyd.AssetLoader.get():loadSprite(var_0_4:titlePic(var_9_0))

			if arg_9_0.eventTable[arg_9_2].event_info and tonumber(var_9_0) == xyd.AdventureEventType.FAVOR then
				local var_9_11 = arg_9_0.selfPlayer:getHeroByID(arg_9_0.eventTable[arg_9_2].event_info.special_data)

				arg_9_0.adventureEvent:updateCardContainer(var_9_11, var_9_6)
			elseif tonumber(var_9_0) == xyd.AdventureEventType.SUMMON then
				local var_9_12 = var_0_5:itemId(tostring(arg_9_0.eventTable[arg_9_2].event_info.special_data))

				arg_9_0.adventureEvent:updateCardContainer(nil, var_9_6, nil, var_9_12)
			end

			arg_9_1:getChildByName("time"):setVisible(true)

			if arg_9_2 % 2 == 1 then
				arg_9_0:updateTimeCount(arg_9_1, arg_9_2)
			else
				arg_9_0:updateTimeCount2(arg_9_1, arg_9_2)
			end

			var_9_7:setTouchEnabled(true)

			local var_9_13 = 0
			local var_9_14 = 0
			local var_9_15 = false

			var_9_7:addTouchEventListener(function(arg_10_0, arg_10_1)
				if arg_10_1 == ccui.TouchEventType.began then
					-- block empty
				elseif arg_10_1 == ccui.TouchEventType.moved then
					-- block empty
				elseif arg_10_1 == ccui.TouchEventType.ended then
					local var_10_0 = {
						table_id = tonumber(var_9_0)
					}

					arg_9_0.adventureEvent:getAdventureEventInfo(var_10_0, function(arg_11_0, arg_11_1)
						if arg_11_0 == xyd.error.OK then
							local var_11_0 = {
								event_info = arg_9_0.eventTable[arg_9_2].event_info
							}

							var_11_0.event_info.detail = arg_11_1.detail

							if arg_11_1.detail and arg_11_1.detail.room_info and arg_11_1.detail.room_info.table_id == xyd.AdventureEventType.DEFENSE then
								arg_9_0.adventureEvent:updateDefenseTeamInfo(arg_11_1.detail)
								xyd.WindowManager.get():openWindow(var_0_4:windowName(tostring(xyd.AdventureEventType.DEFENSE)), var_11_0)
							end

							if arg_11_1.detail and arg_11_1.detail.enemy_infos and next(arg_11_1.detail.enemy_infos) then
								xyd.WindowManager.get():openWindow(var_0_4:windowName(tostring(xyd.AdventureEventType.BATTLE)), var_11_0)
							end

							if var_9_0 ~= tostring(xyd.AdventureEventType.DEFENSE) and var_9_0 ~= tostring(xyd.AdventureEventType.BATTLE) then
								xyd.WindowManager.get():openWindow(var_0_4:windowName(var_9_0), var_11_0)
							end
						end
					end)
				end
			end)
			var_9_8:removeAllChildren()
			var_9_10:align(display.CENTER, 0, 0):addTo(var_9_8)
			var_9_10:play(nil, true)
		else
			var_9_1 = display.newFilteredSprite(var_0_4:titleBg(var_9_0), "GRAY", {
				0.2,
				0.3,
				0.5,
				0.1
			})
			var_9_2 = display.newFilteredSprite(var_0_4:titlePic(var_9_0), "GRAY", {
				0.2,
				0.3,
				0.5,
				0.1
			})

			arg_9_1:getChildByName("time"):setVisible(false)
			var_9_8:removeAllChildren()
			var_9_7:setTouchEnabled(false)
		end

		var_9_1:addTo(var_9_4)
		var_9_2:addTo(var_9_5)
	end
end

function var_0_0.updateTimeCount(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_1:getChildByName("time")

	if arg_12_0.handle_ then
		var_0_1.unscheduleGlobal(arg_12_0.handle_)
	end

	local var_12_1 = arg_12_0.eventTable[arg_12_2].event_info.end_time - xyd.ServerTime.get():getServerTime()

	if var_12_1 <= 0 then
		arg_12_0.adventureEvent:reloadAdventureEventInfo(function(arg_13_0, arg_13_1)
			if arg_13_0 == xyd.error.OK then
				local var_13_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)

				arg_12_0.eventTable = var_13_0.adventureEventInfo

				arg_12_0:updateContainer()
			end
		end)
		var_12_0:setString(var_0_3:translation("ACTIVITY_TIME_LIMIT_1") .. "00:00:00")

		return
	end

	var_12_0:setString(var_0_3:translation("ACTIVITY_TIME_LIMIT_1") .. xyd.secondsToString(var_12_1))

	arg_12_0.handle_ = var_0_1.scheduleGlobal(function()
		if var_12_0 and not tolua.isnull(var_12_0) then
			var_12_1 = var_12_1 - 1

			var_12_0:setString(var_0_3:translation("ACTIVITY_TIME_LIMIT_1") .. xyd.secondsToString(var_12_1))

			if var_12_1 == 0 then
				if arg_12_0.handle_ then
					var_0_1.unscheduleGlobal(arg_12_0.handle_)

					arg_12_0.handle_ = nil
				end

				arg_12_0.adventureEvent:adventureEventFinish(arg_12_0.eventTable[arg_12_2].id)

				arg_12_0.eventTable = arg_12_0.adventureEvent.adventureEventInfo

				arg_12_0:layout()
			end
		elseif arg_12_0.handle_ then
			var_0_1.unscheduleGlobal(arg_12_0.handle_)

			arg_12_0.handle_ = nil
		end
	end, 1)
end

function var_0_0.updateTimeCount2(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = arg_15_1:getChildByName("time")

	if arg_15_0.handle2_ then
		var_0_1.unscheduleGlobal(arg_15_0.handle2_)
	end

	local var_15_1 = arg_15_0.eventTable[arg_15_2].event_info.end_time - xyd.ServerTime.get():getServerTime()

	if var_15_1 <= 0 then
		arg_15_0.adventureEvent:reloadAdventureEventInfo(function(arg_16_0, arg_16_1)
			if arg_16_0 == xyd.error.OK then
				local var_16_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)

				arg_15_0.eventTable = var_16_0.adventureEventInfo

				arg_15_0:updateContainer()
			end
		end)
		var_15_0:setString(var_0_3:translation("ACTIVITY_TIME_LIMIT_1") .. "00:00:00")

		return
	end

	var_15_0:setString(var_0_3:translation("ACTIVITY_TIME_LIMIT_1") .. xyd.secondsToString(var_15_1))

	arg_15_0.handle2_ = var_0_1.scheduleGlobal(function()
		if var_15_0 and not tolua.isnull(var_15_0) then
			var_15_1 = var_15_1 - 1

			var_15_0:setString(var_0_3:translation("ACTIVITY_TIME_LIMIT_1") .. xyd.secondsToString(var_15_1))

			if var_15_1 == 0 then
				if arg_15_0.handle2_ then
					var_0_1.unscheduleGlobal(arg_15_0.handle2_)

					arg_15_0.handle2_ = nil
				end

				arg_15_0.adventureEvent:adventureEventFinish(arg_15_0.eventTable[arg_15_2].id)

				arg_15_0.eventTable = arg_15_0.adventureEvent.adventureEventInfo

				arg_15_0:layout()
			end
		elseif arg_15_0.handle2_ then
			var_0_1.unscheduleGlobal(arg_15_0.handle2_)

			arg_15_0.handle2_ = nil
		end
	end, 1)
end

function var_0_0.layout(arg_18_0)
	arg_18_0.pageIndex_ = 1
	arg_18_0.maxPage = math.ceil(#arg_18_0.eventTable / var_0_6)

	arg_18_0:nodeByName("page"):setString(arg_18_0.pageIndex_ .. "/" .. arg_18_0.maxPage)
	arg_18_0:updateContainer()
end

function var_0_0.release(arg_19_0)
	if arg_19_0.handle_ then
		var_0_1.unscheduleGlobal(arg_19_0.handle_)

		arg_19_0.handle_ = nil
	end

	if arg_19_0.handle2_ then
		var_0_1.unscheduleGlobal(arg_19_0.handle2_)

		arg_19_0.handle2_ = nil
	end
end

return var_0_0
