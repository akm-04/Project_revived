local var_0_0 = class("OccultPrepareWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.occult = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)
	arg_1_0.playerItems_ = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.afterCompleteOpenWindow(arg_3_0)
	var_0_0.super.afterCompleteOpenWindow(arg_3_0)

	if arg_3_0.occult.co and coroutine.status(arg_3_0.occult.co) == "suspended" then
		coroutine.resume(arg_3_0.occult.co)
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0:setButtonClick()
	arg_4_0:initList()

	local var_4_0 = arg_4_0.occult:getRoomID()

	arg_4_0:nodeByName("text_house"):setString(var_0_1:translation("ILLUSION_TEAM_TIPS_4"))
	arg_4_0:nodeByName("text_house_num"):setString(var_4_0)
	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("ILLUSION_TEAM_TIPS_5"))
	arg_4_0:nodeByName("txt_prepare"):setString(var_0_1:translation("PARADISE_TEXT_1"))
end

function var_0_0.initList(arg_5_0)
	local var_5_0 = arg_5_0:nodeByName("detail")

	if not var_5_0 then
		return
	end

	var_5_0:removeAllChildren()

	local var_5_1 = 247
	local var_5_2 = 0

	for iter_5_0 = 1, var_0_2 do
		arg_5_0:updateItem(iter_5_0, (iter_5_0 - 2) * var_5_1, var_5_2)
	end
end

function var_0_0.updateItem(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if not arg_6_0.playerItems_[arg_6_1] or tolua.isnull(arg_6_0.playerItems_[arg_6_1]) then
		local var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/occult/cooperation/prepare_item.csb")

		var_6_0:addTo(arg_6_0:nodeByName("detail"))
		var_6_0:setPosition(cc.p(arg_6_2, arg_6_3))

		arg_6_0.playerItems_[arg_6_1] = var_6_0
	end

	local var_6_1 = arg_6_0.playerItems_[arg_6_1]:getChildByName("container")
	local var_6_2 = var_6_1:getContentSize()

	var_6_1:getChildByName("add"):setTouchEnabled(true)
	var_6_1:getChildByName("add"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			var_6_1:getChildByName("add"):setScale(0.9)

			return true
		elseif arg_7_0.name == "ended" then
			var_6_1:getChildByName("add"):setScale(1)
			xyd.WindowManager.get():openWindow("occult_invite")
		end
	end)
	var_6_1:getChildByName("add"):getChildByName("add_txt"):setString(var_0_1:translation("ILLUSION_INVITE_FRIEND_TXT"))
	var_6_1:getChildByName("add"):getChildByName("add_txt"):enableOutline(cc.c4b(12, 61, 107, 255), 2)
	arg_6_0:updatePlayerInfo(var_6_1, arg_6_1)
end

function var_0_0.updatePlayerInfo(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = arg_8_0.occult:getPlayerInfo(arg_8_2)

	if not var_8_0 then
		arg_8_1:getChildByName("partner"):setVisible(false)
		arg_8_1:getChildByName("add"):setVisible(true)

		return
	else
		arg_8_1:getChildByName("partner"):setVisible(true)
		arg_8_1:getChildByName("add"):setVisible(false)
	end

	local var_8_1 = arg_8_1:getChildByName("partner")

	var_8_0.playerInfo = var_8_0

	xyd.setPlayerAvatar(var_8_1:getChildByName("avatar"), var_8_0)

	if var_8_0.conquer_lev and var_8_0.conquer_lev > 0 then
		local var_8_2 = {
			x = 0,
			y = 0
		}

		xyd.setConquerLev(var_8_0.conquer_lev, var_8_1:getChildByName("text_lev"), var_8_1:getChildByName("dengjiquan"), var_8_2, false, 0.9, "conquer_bg", var_8_0.conquer_loop_id)
	else
		if var_8_1:getChildByName("conquer_bg") then
			var_8_1:removeChildByName("conquer_bg")
		end

		var_8_1:getChildByName("dengjiquan"):setVisible(true)
		var_8_1:getChildByName("text_lev"):setString(var_8_0.lev)
	end

	var_8_1:getChildByName("text_name"):setString(var_8_0.player_name)
	var_8_1:getChildByName("text_fight"):setString(var_0_1:translation("ILLUSION_TEAM_TIPS_6"))
	var_8_1:getChildByName("text_fight_num"):setString(var_8_0.force)

	if arg_8_2 == 1 then
		var_8_1:getChildByName("word_prepare"):setVisible(false)
	else
		var_8_1:getChildByName("word_prepare"):setVisible(true)
	end

	if arg_8_2 == 1 then
		var_8_1:getChildByName("img_delete"):setVisible(false)
	elseif not arg_8_0.occult:checkIsMaster(arg_8_0.selfPlayer.playerID) then
		var_8_1:getChildByName("img_delete"):setVisible(false)
		var_8_1:getChildByName("house"):setVisible(false)
	else
		var_8_1:getChildByName("house"):setVisible(false)
	end

	var_8_1:getChildByName("img_delete"):setTouchEnabled(true)
	xyd.nodeEventSample(var_8_1:getChildByName("img_delete"), nil, function()
		local var_9_0 = string.format(var_0_1:translation("ILLUSION_TEAM_TIPS_7"), var_8_0.player_name)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_0, function()
			local var_10_0 = {
				player_id = var_8_0.player_id
			}

			arg_8_0.occult:kickMember(var_10_0, function(arg_11_0, arg_11_1)
				return
			end)
		end, nil, nil, arg_8_0.colorMode)
	end)
end

function var_0_0.setButtonClick(arg_12_0)
	if not arg_12_0.occult:checkIsMaster(arg_12_0.selfPlayer.playerID) then
		arg_12_0:nodeByName("btn_prepare"):setVisible(false)
	end

	xyd.nodeEventSample(arg_12_0:nodeByName("btn_prepare"), nil, function()
		xyd.playButtonSound()

		if arg_12_0:checkCanPrepare() then
			local var_13_0 = {}

			arg_12_0.occult:startChallenge(var_13_0, function(arg_14_0, arg_14_1)
				if arg_14_0 == xyd.error.OK then
					-- block empty
				end
			end)
		else
			local var_13_1 = var_0_1:translation("ILLUSION_TEAM_TIPS_24")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_13_1
			})
		end
	end)
	xyd.nodeEventSample(arg_12_0:nodeByName("close_btn"), nil, function()
		xyd.playButtonSound()

		local var_15_0 = var_0_1:translation("ILLUSION_TEAM_TIPS_8")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_15_0, function()
			if arg_12_0 and not tolua.isnull(arg_12_0) then
				local var_16_0 = {
					room_id = arg_12_0.occult.baseInfo.room_id
				}

				arg_12_0.occult:exitRoom(var_16_0, function(arg_17_0, arg_17_1)
					if arg_17_0 == xyd.error.OK then
						xyd.WindowManager.get():closeWindow(arg_12_0)
					else
						xyd.WindowManager.get():closeWindow(arg_12_0)
					end
				end)
			end
		end, nil, nil, arg_12_0.colorMode)
	end)
end

function var_0_0.checkCanPrepare(arg_18_0)
	for iter_18_0 = 1, var_0_2 do
		if not arg_18_0.occult:getPlayerInfo(iter_18_0) then
			return false
		end
	end

	return true
end

return var_0_0
