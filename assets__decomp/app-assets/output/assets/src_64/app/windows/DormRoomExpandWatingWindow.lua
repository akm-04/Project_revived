local var_0_0 = class("DormRoomExpandWatingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = "skeletons/ui_effect/dorm/chuanglian"
local var_0_3 = "skeletons/ui_effect/dorm/kuojian_name"
local var_0_4 = "skeletons/ui_effect/dorm/chuang_particle_texture"
local var_0_5 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.dorm = xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.houseDetail = arg_1_0.dorm.houseDetail
	arg_1_0.houseInfo = arg_1_0.dorm.houseInfo
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	var_0_0.super.willClose(arg_3_0, arg_3_1)

	if arg_3_0.handle then
		var_0_5.unscheduleGlobal(arg_3_0.handle)

		arg_3_0.handle = nil
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("tip_txt"):setString(var_0_1:translation("DORM_ROOM_EXPAND_TEXT5"))
	arg_4_0:setButtonClick()

	arg_4_0.effect1 = xyd.createEffect(var_0_2)

	arg_4_0.effect1:addTo(arg_4_0:nodeByName("effect_pos"))
	arg_4_0.effect1:setPosition(cc.p(640, 360))
	arg_4_0:nodeByName("tip_container"):setVisible(false)
	arg_4_0.effect1:play(function(...)
		arg_4_0:nodeByName("tip_container"):setVisible(true)
	end, false, nil, "close")

	local var_4_0 = cc.ParticleSystemQuad:create(var_0_4 .. ".plist")

	var_4_0:addTo(arg_4_0:nodeByName("effect_pos"))
	var_4_0:setPosition(cc.p(640, 360))
	arg_4_0:createScheduler()
end

function var_0_0.timeEnd(arg_6_0)
	arg_6_0.dorm:toHouse(arg_6_0.houseInfo, function()
		arg_6_0:nodeByName("tip_container"):setVisible(false)
		arg_6_0:nodeByName("close"):setVisible(false)
		arg_6_0.effect1:play(function()
			var_0_5.performWithDelayGlobal(function()
				xyd.WindowManager.get():closeWindow("dorm_room_expand_wating")
			end, 0.2)
		end, false, nil, "open")
	end)
end

function var_0_0.createScheduler(arg_10_0)
	if arg_10_0.handle then
		var_0_5.unscheduleGlobal(arg_10_0.handle)

		arg_10_0.handle = nil
	end

	local var_10_0 = arg_10_0.houseInfo.expand_start_time + xyd.tables.dormExpand:costTimes(arg_10_0.houseInfo.expand_lev + 1)
	local var_10_1 = var_10_0 - xyd.ServerTime.get():getServerTime()

	arg_10_0:updateTimeText(var_10_1)

	arg_10_0.handle = var_0_5.scheduleGlobal(function()
		local var_11_0 = var_10_0 - xyd.ServerTime.get():getServerTime()

		if not arg_10_0 or var_11_0 < 0 then
			if arg_10_0.handle then
				var_0_5.unscheduleGlobal(arg_10_0.handle)

				arg_10_0.handle = nil
			end

			arg_10_0:timeEnd()

			return
		end

		arg_10_0:updateTimeText(var_11_0)
	end, 1)
end

function var_0_0.updateTimeText(arg_12_0, arg_12_1)
	if arg_12_1 < 0 then
		arg_12_1 = 0
	end

	local var_12_0 = xyd.timeFormatAsHMS(arg_12_1)
	local var_12_1 = xyd.tables.misc.skipExpandCost * math.ceil(arg_12_1 * 1 / xyd.tables.misc.skipExpandTimes)

	arg_12_0:nodeByName("tip_txt"):setString(string.format(var_0_1:translation("DORM_ROOM_EXPAND_TEXT5"), var_12_0, var_12_1))
end

function var_0_0.setButtonClick(arg_13_0)
	arg_13_0:nodeByName("sure_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_14_0 = {
				house_id = arg_13_0.houseDetail.house_id
			}

			arg_13_0.dorm:finishExpandHouse(var_14_0, function(arg_15_0, arg_15_1)
				if arg_15_0 == xyd.error.OK then
					arg_13_0:timeEnd()
				end
			end)
		end
	end)
	arg_13_0:nodeByName("close"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow("dorm_room")
			xyd.WindowManager.get():closeWindow(arg_13_0)
		end
	end)
end

return var_0_0
