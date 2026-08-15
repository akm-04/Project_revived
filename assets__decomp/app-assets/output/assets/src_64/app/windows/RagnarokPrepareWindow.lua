local var_0_0 = class("RagnarokPrepareWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 3
local var_0_3 = {
	PRIVATE = 0,
	PUBLIC = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.ragnarok = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.afterCompleteOpenWindow(arg_4_0)
	var_0_0.super.afterCompleteOpenWindow(arg_4_0)

	if arg_4_0.ragnarok.co and coroutine.status(arg_4_0.ragnarok.co) == "suspended" then
		coroutine.resume(arg_4_0.ragnarok.co)
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("txt_title"):setString(var_0_1:translation("RAGNAROK_BOSS_TEAM_10"))
	arg_5_0:nodeByName("txt_enemy"):setString(var_0_1:translation("RAGNAROK_BOSS_TEAM_11"))
	arg_5_0:nodeByName("txt_prepare"):setString(var_0_1:translation("RAGNAROK_BOSS_TEAM_12"))
	arg_5_0:nodeByName("txt_my_room"):setString(var_0_1:translation("RAGNAROK_BOSS_TEAM_14"))
	arg_5_0:nodeByName("txt_type_1"):setString(var_0_1:translation("RAGNAROK_BOSS_TEAM_32"))
	arg_5_0:nodeByName("txt_type_2"):setString(var_0_1:translation("RAGNAROK_BOSS_TEAM_33"))
	arg_5_0:setButtonClick()

	for iter_5_0 = 1, var_0_2 do
		arg_5_0:updatePlayerInfo(iter_5_0)

		local var_5_0 = arg_5_0:nodeByName("player" .. iter_5_0)

		var_5_0:getChildByName("txt_ok"):enableOutline(cc.c4b(54, 58, 60, 255), 2)
		var_5_0:getChildByName("txt_ok"):setString(var_0_1:translation("RAGNAROK_BOSS_TEAM_13"))

		if iter_5_0 == 1 then
			var_5_0:getChildByName("enemy_name"):setString(var_0_1:translation("RAGNAROK_BOSS_1"))
		else
			var_5_0:getChildByName("enemy_name"):setString(var_0_1:translation("RAGNAROK_BOSS_2"))
		end

		arg_5_0:nodeByName("txt_click" .. iter_5_0):setString(var_0_1:translation("RAGNAROK_BOSS_TEAM_15"))
	end

	local var_5_1 = arg_5_0.ragnarok:getRoomID()

	arg_5_0:nodeByName("txt_room_id"):setString(var_5_1)
	arg_5_0:setType(arg_5_0.ragnarok:roomIsPublic())
end

function var_0_0.updateList(arg_6_0)
	for iter_6_0 = 1, var_0_2 do
		arg_6_0:updatePlayerInfo(iter_6_0)
	end
end

function var_0_0.updatePlayerInfo(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_0.ragnarok:getPlayerInfo(arg_7_1)
	local var_7_1 = arg_7_0:nodeByName("player" .. arg_7_1)

	if not var_7_0 then
		arg_7_0:nodeByName("null" .. arg_7_1):setVisible(true)
		var_7_1:setVisible(false)

		return
	else
		arg_7_0:nodeByName("null" .. arg_7_1):setVisible(false)
		var_7_1:setVisible(true)
	end

	var_7_0.is_new = true
	var_7_0.playerInfo = var_7_0

	var_7_1:getChildByName("avatar"):removeAllChildren()
	xyd.setPlayerAvatar(var_7_1:getChildByName("avatar"), var_7_0)

	if arg_7_1 == 1 then
		var_7_1:getChildByName("txt_ok"):setVisible(false)
	else
		var_7_1:getChildByName("txt_ok"):setVisible(true)
	end

	var_7_1:getChildByName("txt_name"):setString(var_7_0.player_name)

	if arg_7_1 == 1 then
		var_7_1:getChildByName("btn_close"):setVisible(false)
		var_7_1:getChildByName("house"):setVisible(true)
	elseif not arg_7_0.ragnarok:checkIsMaster(arg_7_0.selfPlayer.playerID) then
		var_7_1:getChildByName("btn_close"):setVisible(false)
		var_7_1:getChildByName("house"):setVisible(false)
	else
		var_7_1:getChildByName("house"):setVisible(false)
		var_7_1:getChildByName("btn_close"):setVisible(true)
	end
end

function var_0_0.setButtonClick(arg_8_0)
	if not arg_8_0.ragnarok:checkIsMaster(arg_8_0.selfPlayer.playerID) then
		arg_8_0:nodeByName("btn_prepare"):setVisible(false)
	end

	arg_8_0:nodeByName("btn_prepare"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_9_0, arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			if arg_8_0:checkCanPrepare() then
				arg_8_0.ragnarok:teamEnter()
			else
				local var_9_0 = var_0_1:translation("RAGNAROK_BOSS_TEAM_16")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_9_0
				})
			end
		end
	end)
	arg_8_0:nodeByName("close_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			local var_10_0 = var_0_1:translation("RAGNAROK_BOSS_TEAM_17")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_0, function()
				arg_8_0.ragnarok:exitRoom(function(arg_12_0, arg_12_1)
					xyd.WindowManager.get():closeWindow(arg_8_0)
				end)
			end, nil, nil, xyd.ColorMode.PURPLE)
		end
	end)

	if arg_8_0.ragnarok:checkIsMaster(arg_8_0.selfPlayer.playerID) then
		arg_8_0:nodeByName("type_container"):addTouchEventListener(function(arg_13_0, arg_13_1)
			if arg_13_1 == ccui.TouchEventType.ended then
				arg_8_0.ragnarok:setRoomType(1 - arg_8_0.type_, function(arg_14_0, arg_14_1)
					if arg_14_0 == xyd.error.OK then
						arg_8_0:setType(arg_8_0.ragnarok:roomIsPublic())
					end
				end)
			end
		end)
	else
		arg_8_0:nodeByName("type_container"):setVisible(false)
	end

	for iter_8_0 = 1, var_0_2 do
		local var_8_0 = arg_8_0:nodeByName("icon_plus" .. iter_8_0)

		var_8_0:setTouchEnabled(true)
		var_8_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
			if arg_15_0.name == "began" then
				var_8_0:setScale(0.9)

				return true
			elseif arg_15_0.name == "ended" then
				var_8_0:setScale(1)
				xyd.WindowManager.get():openWindow("ragnarok_invite")
			end
		end)

		local var_8_1 = arg_8_0:nodeByName("player" .. iter_8_0):getChildByName("btn_close")

		xyd.nodeEventSample(var_8_1, nil, function()
			local var_16_0 = arg_8_0.ragnarok:getPlayerInfo(iter_8_0)
			local var_16_1 = string.format(var_0_1:translation("RAGNAROK_BOSS_TEAM_18"), var_16_0.player_name)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_16_1, function()
				arg_8_0.ragnarok:removePlayer(var_16_0.player_id, function(arg_18_0, arg_18_1)
					if arg_18_0 == xyd.error.OK then
						-- block empty
					end
				end)
			end, nil, nil, xyd.ColorMode.PURPLE)
		end)
	end
end

function var_0_0.setType(arg_19_0, arg_19_1)
	local var_19_0 = arg_19_0:nodeByName("type_container")

	arg_19_0.type_ = arg_19_1

	var_19_0:getChildByName("type_1"):setVisible(arg_19_0.type_ == var_0_3.PUBLIC)
	var_19_0:getChildByName("type_2"):setVisible(arg_19_0.type_ == var_0_3.PRIVATE)
end

function var_0_0.checkCanPrepare(arg_20_0)
	for iter_20_0 = 1, var_0_2 do
		if not arg_20_0.ragnarok:getPlayerInfo(iter_20_0) then
			return false
		end
	end

	return true
end

return var_0_0
