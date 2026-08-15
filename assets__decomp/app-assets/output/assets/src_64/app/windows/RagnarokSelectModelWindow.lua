local var_0_0 = class("RagnarokSelectModelWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.ragnarok = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)
	arg_1_0.roomList = arg_1_2
	arg_1_0.canRefresh = true
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_create"):setString(var_0_2:translation("RAGNAROK_BOSS_TEAM_7"))
	arg_4_0:nodeByName("text_add"):setString(var_0_2:translation("RAGNAROK_BOSS_TEAM_8"))
	arg_4_0:nodeByName("text_title"):setString(var_0_2:translation("RAGNAROK_BOSS_TEAM_9"))
	arg_4_0:nodeByName("text_quickly_add"):setString(var_0_2:translation("RAGNAROK_BOSS_TEAM_31"))

	for iter_4_0 = 1, 3 do
		arg_4_0:nodeByName("room_null_" .. iter_4_0):getChildByName("txt"):setString(var_0_2:translation("RAGNAROK_BOSS_TEAM_34"))
	end

	arg_4_0:setButtonClick()
	arg_4_0:updateRoomList()
end

function var_0_0.setButtonClick(arg_5_0)
	xyd.nodeEventSample(arg_5_0:nodeByName("btn_create"), nil, function()
		local var_6_0 = {}

		arg_5_0.ragnarok:createHouse(var_6_0, function(arg_7_0, arg_7_1)
			if arg_7_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("ragnarok_prepare")
				xyd.WindowManager.get():closeWindow(arg_5_0)
			end
		end)
	end)
	xyd.nodeEventSample(arg_5_0:nodeByName("btn_add"), nil, function()
		xyd.WindowManager.get():openWindow("ragnarok_input_house")
	end)
	xyd.nodeEventSample(arg_5_0:nodeByName("btn_quickly_add"), nil, function()
		arg_5_0.ragnarok:quicklyEnterRoom(function(arg_10_0, arg_10_1)
			if arg_10_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("ragnarok_prepare")
				xyd.WindowManager.get():closeWindow(arg_5_0)
			end
		end)
	end)
	xyd.nodeEventSample(arg_5_0:nodeByName("btn_refresh"), nil, function()
		if not arg_5_0.canRefresh then
			local var_11_0 = var_0_2:translation("RAGNAROK_BOSS_TEAM_36")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_11_0
			})

			return
		end

		arg_5_0.canRefresh = false

		var_0_1.performWithDelayGlobal(function()
			if arg_5_0 and not tolua.isnull(arg_5_0) then
				arg_5_0.canRefresh = true
			end
		end, 3)
		arg_5_0.ragnarok:getRoomList(function(arg_13_0, arg_13_1)
			if arg_13_0 == xyd.error.OK then
				arg_5_0.roomList = arg_13_1

				arg_5_0:updateRoomList()
			end
		end)
	end)
	xyd.nodeEventSample(arg_5_0:nodeByName("close_btn"), nil, function()
		xyd.WindowManager.get():closeWindow(arg_5_0)
	end)

	for iter_5_0 = 1, 3 do
		xyd.nodeEventSample(arg_5_0:nodeByName("room_" .. iter_5_0), nil, function()
			arg_5_0.ragnarok:enterRoom(arg_5_0.roomList[iter_5_0].room_id, 1, function(arg_16_0, arg_16_1)
				if arg_16_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("ragnarok_prepare")
					arg_5_0:close()
				else
					local var_16_0 = var_0_2:translation("RAGNAROK_BOSS_TEAM_30")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_16_0
					})
					arg_5_0.ragnarok:getRoomList(function(arg_17_0, arg_17_1)
						if arg_17_0 == xyd.error.OK then
							arg_5_0.roomList = arg_17_1

							arg_5_0:updateRoomList()
						end
					end)
				end
			end)
		end)
	end
end

function var_0_0.updateRoomList(arg_18_0)
	for iter_18_0 = 1, 3 do
		local var_18_0 = arg_18_0:nodeByName("room_" .. iter_18_0)

		if arg_18_0.roomList[iter_18_0] then
			var_18_0:setVisible(true)
			arg_18_0:nodeByName("room_null_" .. iter_18_0):setVisible(false)

			local var_18_1 = arg_18_0:getRoomOwnerInfo(arg_18_0.roomList[iter_18_0].member_infos, arg_18_0.roomList[iter_18_0].owner)

			var_18_1.is_new = true
			var_18_1.conquerLev = var_18_1.conquer_lev
			var_18_1.conquerLoopID = var_18_1.conquer_loop_id

			xyd.setPlayerAvatar(var_18_0:getChildByName("avatar"), var_18_1)
			var_18_0:getChildByName("txt_id"):setString(arg_18_0.roomList[iter_18_0].room_id)
		else
			var_18_0:setVisible(false)
			arg_18_0:nodeByName("room_null_" .. iter_18_0):setVisible(true)
		end
	end
end

function var_0_0.getRoomOwnerInfo(arg_19_0, arg_19_1, arg_19_2)
	for iter_19_0 = 1, 3 do
		if arg_19_1[iter_19_0].player_id == arg_19_2 then
			return arg_19_1[iter_19_0]
		end
	end
end

return var_0_0
