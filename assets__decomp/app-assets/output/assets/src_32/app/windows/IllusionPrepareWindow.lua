local var_0_0 = class("IllusionPrepareWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.illusion = xyd.ModelManager.get():loadModel(xyd.ModelType.ILLUSION)
	arg_1_0.playerItems_ = {}
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

	if arg_4_0.illusion.co and coroutine.status(arg_4_0.illusion.co) == "suspended" then
		coroutine.resume(arg_4_0.illusion.co)
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:setButtonClick()
	arg_5_0:initList()

	local var_5_0 = arg_5_0.illusion:getRoomID()

	arg_5_0:nodeByName("text_house"):setString(var_0_1:translation("ILLUSION_TEAM_TIPS_4"))
	arg_5_0:nodeByName("text_house_num"):setString(var_5_0)
	arg_5_0:nodeByName("text_title"):setString(var_0_1:translation("ILLUSION_TEAM_TIPS_5"))
	arg_5_0:nodeByName("txt_prepare"):setString(var_0_1:translation("PARADISE_TEXT_1"))
end

function var_0_0.initList(arg_6_0)
	local var_6_0 = 247
	local var_6_1 = 0

	for iter_6_0 = 1, var_0_2 do
		arg_6_0:updateItem(iter_6_0, (iter_6_0 - 2) * var_6_0, var_6_1)
	end
end

function var_0_0.updateItem(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if not arg_7_0.playerItems_[arg_7_1] or tolua.isnull(arg_7_0.playerItems_[arg_7_1]) then
		local var_7_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/illusion/cooperation_new/prepare_item.csb")

		if not var_7_0 then
			return
		end

		var_7_0:addTo(arg_7_0:nodeByName("detail"))
		var_7_0:setPosition(cc.p(arg_7_2, arg_7_3))

		arg_7_0.playerItems_[arg_7_1] = var_7_0
	end

	local var_7_1 = arg_7_0.playerItems_[arg_7_1]:getChildByName("container")
	local var_7_2 = var_7_1:getContentSize()

	var_7_1:getChildByName("add"):setTouchEnabled(true)
	var_7_1:getChildByName("add"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			var_7_1:getChildByName("add"):setScale(0.9)

			return true
		elseif arg_8_0.name == "ended" then
			var_7_1:getChildByName("add"):setScale(1)
			xyd.WindowManager.get():openWindow("illusion_invite")
		end
	end)
	var_7_1:getChildByName("add"):getChildByName("add_txt"):setString(var_0_1:translation("ILLUSION_INVITE_FRIEND_TXT"))
	var_7_1:getChildByName("add"):getChildByName("add_txt"):enableOutline(cc.c4b(12, 61, 107, 255), 2)
	arg_7_0:updatePlayerInfo(var_7_1, arg_7_1)
end

function var_0_0.updatePlayerInfo(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_0.illusion:getPlayerInfo(arg_9_2)

	if var_9_0 == 0 then
		arg_9_1:getChildByName("partner"):setVisible(false)
		arg_9_1:getChildByName("add"):setVisible(true)

		return
	else
		arg_9_1:getChildByName("partner"):setVisible(true)
		arg_9_1:getChildByName("add"):setVisible(false)
	end

	local var_9_1 = arg_9_1:getChildByName("partner")

	var_9_0.playerInfo = var_9_0
	var_9_0.is_new = true

	xyd.setPlayerAvatar(var_9_1:getChildByName("avatar"), var_9_0)
	var_9_1:getChildByName("text_name"):setString(var_9_0.player_name)
	var_9_1:getChildByName("text_fight"):setString(var_0_1:translation("ILLUSION_TEAM_TIPS_6"))
	var_9_1:getChildByName("text_fight_num"):setString(var_9_0.force)

	if arg_9_2 == 1 or arg_9_0.illusion:getPlayerStatus(arg_9_2) ~= 1 then
		var_9_1:getChildByName("word_prepare"):setVisible(false)
	else
		var_9_1:getChildByName("word_prepare"):setVisible(true)
	end

	if arg_9_2 == 1 then
		var_9_1:getChildByName("img_delete"):setVisible(false)
	elseif not arg_9_0.illusion:checkIsMaster(arg_9_0.selfPlayer.playerID) then
		var_9_1:getChildByName("img_delete"):setVisible(false)
		var_9_1:getChildByName("house"):setVisible(false)
	else
		var_9_1:getChildByName("house"):setVisible(false)
	end

	var_9_1:getChildByName("img_delete"):setTouchEnabled(true)
	xyd.nodeEventSample(var_9_1:getChildByName("img_delete"), nil, function()
		local var_10_0 = string.format(var_0_1:translation("ILLUSION_TEAM_TIPS_7"), var_9_0.player_name)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_0, function()
			arg_9_0.illusion:removePlayer(var_9_0.player_id, function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					-- block empty
				end
			end)
		end, nil, nil, arg_9_0.colorMode)
	end)
end

function var_0_0.setButtonClick(arg_13_0)
	if not arg_13_0.illusion:checkIsMaster(arg_13_0.selfPlayer.playerID) then
		arg_13_0:nodeByName("btn_prepare"):setVisible(false)
	end

	xyd.nodeEventSample(arg_13_0:nodeByName("btn_prepare"), nil, function()
		xyd.playButtonSound()

		if arg_13_0:checkCanPrepare() then
			arg_13_0.illusion:prepareRoom(function(arg_15_0, arg_15_1)
				if arg_15_0 == xyd.error.OK then
					-- block empty
				end
			end)
		else
			local var_14_0 = var_0_1:translation("ILLUSION_TEAM_TIPS_24")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_14_0
			})
		end
	end)
	xyd.nodeEventSample(arg_13_0:nodeByName("close_btn"), nil, function()
		xyd.playButtonSound()

		local var_16_0 = var_0_1:translation("ILLUSION_TEAM_TIPS_8")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_16_0, function()
			xyd.ModelManager.get():loadModel(xyd.ModelType.ILLUSION):exitRoom(function(arg_18_0, arg_18_1)
				xyd.WindowManager.get():closeWindow(arg_13_0)
			end)
		end, nil, nil, arg_13_0.colorMode)
	end)
end

function var_0_0.checkCanPrepare(arg_19_0)
	for iter_19_0 = 1, var_0_2 do
		if arg_19_0.illusion:getPlayerInfo(iter_19_0) == 0 then
			return false
		end
	end

	return true
end

return var_0_0
