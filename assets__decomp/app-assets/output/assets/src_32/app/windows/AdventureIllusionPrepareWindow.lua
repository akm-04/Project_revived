local var_0_0 = class("AdventureIllusionPrepareWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.adventureEvent = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
	arg_1_0.illusion = xyd.ModelManager.get():loadModel(xyd.ModelType.ILLUSION)
	arg_1_0.eventId = arg_1_2.table_id
	arg_1_0.playerItems_ = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setButtonClick()
	arg_3_0:initList()

	local var_3_0 = arg_3_0.adventureEvent:getRoomID()

	arg_3_0:nodeByName("text_house"):setString(var_0_1:translation("ILLUSION_TEAM_TIPS_4"))
	arg_3_0:nodeByName("text_house_num"):setString(var_3_0)
	arg_3_0:nodeByName("text_title"):setString(var_0_1:translation("ILLUSION_TEAM_TIPS_5"))
end

function var_0_0.initList(arg_4_0)
	arg_4_0.playerItems_ = {}

	local var_4_0 = arg_4_0:nodeByName("detail")

	var_4_0:removeAllChildren()

	local var_4_1 = var_4_0:getContentSize().width / 3
	local var_4_2 = 20
	local var_4_3 = 0

	for iter_4_0 = 1, var_0_2 do
		arg_4_0:updateItem(iter_4_0, var_4_2, var_4_3)

		var_4_2 = var_4_1 + var_4_2
		var_4_3 = 0
	end
end

function var_0_0.updateItem(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if not arg_5_0.playerItems_[arg_5_1] or tolua.isnull(arg_5_0.playerItems_[arg_5_1]) then
		local var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/illusion/cooperation/prepare_item.csb")

		var_5_0:addTo(arg_5_0:nodeByName("detail"))
		var_5_0:setPosition(cc.p(arg_5_2, arg_5_3))

		arg_5_0.playerItems_[arg_5_1] = var_5_0
	end

	local var_5_1 = arg_5_0.playerItems_[arg_5_1]:getChildByName("container")
	local var_5_2 = var_5_1:getContentSize()

	var_5_1:getChildByName("add"):setTouchEnabled(true)
	var_5_1:getChildByName("add"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			var_5_1:getChildByName("add"):setScale(0.9)

			return true
		elseif arg_6_0.name == "ended" then
			var_5_1:getChildByName("add"):setScale(1)
			xyd.WindowManager.get():openWindow("adventure_illusion_invite", {
				table_id = xyd.AdventureEventType.ILLUSION
			})
		end
	end)
	arg_5_0:updatePlayerInfo(var_5_1, arg_5_1)
end

function var_0_0.updatePlayerInfo(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_0.adventureEvent:getPlayerInfo(arg_7_2)

	if not var_7_0 then
		arg_7_1:getChildByName("partner"):setVisible(false)
		arg_7_1:getChildByName("add"):setVisible(true)

		return
	else
		arg_7_1:getChildByName("partner"):setVisible(true)
		arg_7_1:getChildByName("add"):setVisible(false)
	end

	local var_7_1 = arg_7_1:getChildByName("partner")

	var_7_0.playerInfo = var_7_0

	xyd.setPlayerAvatar(var_7_1:getChildByName("avatar"), var_7_0)

	if var_7_0.conquer_lev and var_7_0.conquer_lev > 0 then
		local var_7_2 = {
			x = -3,
			y = 2
		}

		xyd.setConquerLev(var_7_0.conquer_lev, var_7_1:getChildByName("text_lev"), var_7_1:getChildByName("dengjiquan"), var_7_2, false, 0.9, "conquer_bg", var_7_0.conquer_loop_id)
	else
		if var_7_1:getChildByName("conquer_bg") then
			var_7_1:removeChildByName("conquer_bg")
		end

		var_7_1:getChildByName("dengjiquan"):setVisible(true)
		var_7_1:getChildByName("text_lev"):setString(var_7_0.lev)
	end

	var_7_1:getChildByName("text_name"):setString(var_7_0.player_name)
	var_7_1:getChildByName("text_fight"):setString(var_0_1:translation("ILLUSION_TEAM_TIPS_6"))
	var_7_1:getChildByName("text_fight_num"):setString(var_7_0.force)

	if arg_7_2 == 1 then
		var_7_1:getChildByName("word_prepare"):setVisible(false)
	else
		var_7_1:getChildByName("word_prepare"):setVisible(true)
	end

	if arg_7_2 == 1 then
		var_7_1:getChildByName("img_delete"):setVisible(false)
	elseif not arg_7_0.adventureEvent:checkIsMaster(arg_7_0.selfPlayer.playerID) then
		var_7_1:getChildByName("img_delete"):setVisible(false)
		var_7_1:getChildByName("house"):setVisible(false)
	else
		var_7_1:getChildByName("house"):setVisible(false)
	end

	var_7_1:getChildByName("img_delete"):setTouchEnabled(true)
	var_7_1:getChildByName("img_delete"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			return true
		elseif arg_8_0.name == "ended" then
			local var_8_0 = string.format(var_0_1:translation("ILLUSION_TEAM_TIPS_7"), var_7_0.player_name)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_8_0, function()
				local var_9_0 = {
					player_id = var_7_0.player_id,
					table_id = arg_7_0.eventId
				}

				arg_7_0.adventureEvent:kickMember(var_9_0, function(arg_10_0, arg_10_1)
					if arg_10_0 == xyd.error.OK then
						-- block empty
					end
				end)
			end, nil, nil, arg_7_0.colorMode)
		end
	end)
end

function var_0_0.setButtonClick(arg_11_0)
	if not arg_11_0.adventureEvent:checkIsMaster(arg_11_0.selfPlayer.playerID) then
		arg_11_0:nodeByName("btn_prepare"):setVisible(false)
	end

	arg_11_0:nodeByName("btn_prepare"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_11_0:checkCanPrepare() then
				local var_12_0 = {
					table_id = arg_11_0.eventId
				}

				arg_11_0.adventureEvent:startChallenge(var_12_0, function(arg_13_0, arg_13_1)
					if arg_13_0 == xyd.error.OK then
						-- block empty
					end
				end)
			else
				local var_12_1 = var_0_1:translation("ILLUSION_TEAM_TIPS_24")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_12_1
				})
			end
		end
	end)
	arg_11_0:nodeByName("btn_copy"):setVisible(false)
	arg_11_0:nodeByName("close"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_14_0 = var_0_1:translation("ILLUSION_TEAM_TIPS_8")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_14_0, function()
				local var_15_0 = {
					table_id = arg_11_0.eventId
				}

				arg_11_0.adventureEvent:exitRoom(var_15_0, function(arg_16_0, arg_16_1)
					if arg_16_0 == xyd.error.OK then
						xyd.WindowManager.get():closeWindow(arg_11_0)
					end
				end)
			end)
		end
	end)
end

function var_0_0.checkCanPrepare(arg_17_0)
	for iter_17_0 = 1, var_0_2 do
		if not arg_17_0.adventureEvent:getPlayerInfo(iter_17_0) then
			return false
		end
	end

	return true
end

return var_0_0
