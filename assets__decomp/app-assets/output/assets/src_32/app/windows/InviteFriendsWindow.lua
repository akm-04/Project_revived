local var_0_0 = class("InviteFriendsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	CHARGE_NUM = 4,
	LEVEL = 3,
	PLAYER_NUM = 1,
	HERO_NUM = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.windowState = 0
	arg_1_0.invite = xyd.ModelManager.get():loadModel(xyd.ModelType.INVITE_FRIENDS_INFOS)
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 20 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)

	local var_3_0 = {
		async = true,
		viewRect = cc.rect(0, 0, 725, 330),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}

	arg_3_0.listView = cc.ui.UIListView.new(var_3_0):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener)):setTouchType(true):pos(0, 0)
	arg_3_0.list = {}

	arg_3_0.invite:loadInviteInfos(function(arg_4_0)
		if arg_4_0 == xyd.error.OK then
			arg_3_0:layOut()
		end
	end)
end

function var_0_0.layOut(arg_5_0)
	arg_5_0:initWindowByState(arg_5_0.windowState)

	if arg_5_0.windowState == 0 then
		arg_5_0.list = arg_5_0:resortMissionList(arg_5_0.invite:getInviteMissions())

		arg_5_0.listView:setDelegate(handler(arg_5_0, arg_5_0.missionDelegate))
		arg_5_0.listView:reload()

		if arg_5_0.player.lev < xyd.tables.misc.inviteLevLimit and arg_5_0.invite:getInvitorID() <= 0 then
			arg_5_0:nodeByName("input_btn"):setBright(true)
			arg_5_0:nodeByName("input_txt_gray"):setVisible(false)
			arg_5_0:nodeByName("input_code"):setVisible(true)
		else
			arg_5_0:nodeByName("input_btn"):setBright(false)
			arg_5_0:nodeByName("input_txt_gray"):setVisible(true)
			arg_5_0:nodeByName("input_code"):setVisible(false)
		end

		arg_5_0:nodeByName("input_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.TouchEventType.ended then
				if arg_5_0.invite:getInvitorID() > 0 then
					local var_6_0 = string.format(var_0_1:translation("HAS_BEEN_INVITED"), arg_5_0.invite:getInvitorName())

					xyd.WindowManager.get():openWindow("toast", {
						message = var_6_0
					})

					return
				end

				if arg_5_0.player.lev < xyd.tables.misc.inviteLevLimit then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(xyd.tables.translation:translation("TIP_CODE")), function()
						xyd.WindowManager.get():openWindow("input_invite_code")
					end, nil, nil, arg_5_0.colorMode)
				else
					local var_6_1 = var_0_1:translation("INVITE_LEV_LIMIT")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_6_1
					})
				end
			end
		end)
		arg_5_0:nodeByName("invite_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
			if arg_8_1 == ccui.TouchEventType.ended then
				xyd.WindowManager.get():openWindow("copy_code")
			end
		end)
		arg_5_0:nodeByName("invited_list_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
			if arg_9_1 == ccui.TouchEventType.ended then
				arg_5_0:setWindowState(1)
				arg_5_0:initWindowByState()
				arg_5_0:layOut()
			end
		end)
	else
		arg_5_0.list = arg_5_0.invite:getInviteFriends()

		arg_5_0.listView:setDelegate(handler(arg_5_0, arg_5_0.friendDelegate))
		arg_5_0.listView:reload()
		arg_5_0:nodeByName("return_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended then
				arg_5_0:setWindowState(0)
				arg_5_0:initWindowByState()
				arg_5_0:layOut()
			end
		end)
	end
end

function var_0_0.initWindowByState(arg_11_0, arg_11_1)
	if arg_11_1 == 0 then
		arg_11_0:nodeByName("return_btn"):setVisible(false)
		arg_11_0:nodeByName("frends_title"):setVisible(false)
		arg_11_0:nodeByName("input_btn"):setVisible(true)
		arg_11_0:nodeByName("invite_btn"):setVisible(true)
		arg_11_0:nodeByName("invited_list_btn"):setVisible(true)
		arg_11_0:nodeByName("close"):setVisible(true)
		arg_11_0:nodeByName("input_txt_gray"):setVisible(true)
	elseif arg_11_1 == 1 then
		arg_11_0:nodeByName("return_btn"):setVisible(true)
		arg_11_0:nodeByName("frends_title"):setVisible(true)
		arg_11_0:nodeByName("input_btn"):setVisible(false)
		arg_11_0:nodeByName("invite_btn"):setVisible(false)
		arg_11_0:nodeByName("invited_list_btn"):setVisible(false)
		arg_11_0:nodeByName("close"):setVisible(false)
		arg_11_0:nodeByName("input_txt_gray"):setVisible(false)
	end

	if arg_11_0.listView then
		arg_11_0.listView:removeAllItems()
	end
end

function var_0_0.missionDelegate(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	if cc.ui.UIListView.COUNT_TAG == arg_12_2 then
		return #arg_12_0.list
	elseif cc.ui.UIListView.CELL_TAG == arg_12_2 then
		if arg_12_3 > #arg_12_0.list then
			return nil
		end

		local var_12_0 = arg_12_1:dequeueItem()

		if not var_12_0 then
			var_12_0 = arg_12_1:newItem()
		else
			var_12_0:removeAllChildren(true)
		end

		local var_12_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/invite_friends/invite_mission_item.csb")
		local var_12_2 = display.newNode()

		var_12_1:addTo(var_12_2)

		local var_12_3 = var_12_1:getChildByName("container")

		var_12_3:getChildByName("reward_txt"):setString(var_0_1:translation("REWARD") .. var_0_1:translation("COLON"))
		var_12_3:getChildByName("item_title"):setString(xyd.tables.inviteMission:desc(arg_12_0.list[arg_12_3].mission_id))

		if arg_12_0.list[arg_12_3].can_award then
			var_12_3:getChildByName("item_doing"):setVisible(false)
			var_12_3:getChildByName("item_done"):setVisible(true)
			var_12_3:getChildByName("get_goal"):setVisible(true)
		else
			var_12_3:getChildByName("item_doing"):setVisible(true)
			var_12_3:getChildByName("item_done"):setVisible(false)
			var_12_3:getChildByName("get_goal"):setVisible(false)
		end

		local var_12_4 = xyd.tables.inviteMission:condition(arg_12_0.list[arg_12_3].mission_id)
		local var_12_5 = arg_12_0:getMissionProgress(arg_12_0.list[arg_12_3].mission_id)

		var_12_3:getChildByName("process_txt"):setString(tostring(var_12_5) .. "/" .. tostring(var_12_4[1]))
		var_12_3:getChildByName("award_num"):setString("X" .. tostring(xyd.tables.inviteMission:diamond(arg_12_0.list[arg_12_3].mission_id)))
		var_12_1:setTouchEnabled(true)
		var_12_1:setTouchSwallowEnabled(false)
		var_12_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
			if arg_13_0.name == "began" then
				var_12_1:getChildByName("container"):setScale(0.9)

				return true
			elseif arg_13_0.name == "moved" then
				if arg_12_0.scrollViewMoved_ then
					var_12_1:getChildByName("container"):setScale(1)
				end

				return true
			elseif arg_13_0.name == "ended" then
				var_12_1:getChildByName("container"):setScale(1)

				if not arg_12_0.scrollViewMoved_ then
					if arg_12_0.list[arg_12_3].can_award then
						local var_13_0 = {
							mission_id = arg_12_0.list[arg_12_3].mission_id
						}

						arg_12_0.invite:getMissionReward(var_13_0, function(arg_14_0, arg_14_1)
							if arg_14_0 == xyd.error.OK then
								local var_14_0 = arg_14_1.awards
								local var_14_1 = arg_14_1.new_missions

								xyd.WindowManager.get():openWindow("alert_award", {
									awards = var_14_0
								})

								arg_12_0.list = arg_12_0:resortMissionList(arg_12_0.invite:getInviteMissions())

								local var_14_2 = xyd.tables.inviteMission:condition(arg_12_0.list[arg_12_3].mission_id)
								local var_14_3 = arg_12_0:getMissionProgress(arg_12_0.list[arg_12_3].mission_id)

								var_12_3:getChildByName("process_txt"):setString(tostring(var_14_3) .. "/" .. tostring(var_14_2[1]))
								var_12_3:getChildByName("award_num"):setString("X" .. tostring(xyd.tables.inviteMission:diamond(arg_12_0.list[arg_12_3].mission_id)))
								arg_12_0.listView:reload()
							end
						end)
					else
						local var_13_1 = var_0_1:translation("MISSION_NOT_COMPLETE")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_13_1
						})
					end
				end
			end
		end)
		var_12_1:setAnchorPoint(cc.p(0, 0))
		var_12_1:setPosition(12, 8)
		var_12_2:setContentSize(725, 110)
		var_12_0:addContent(var_12_2)
		var_12_0:setItemSize(725, 110)

		return var_12_0
	end
end

function var_0_0.friendDelegate(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	if cc.ui.UIListView.COUNT_TAG == arg_15_2 then
		return #arg_15_0.list
	elseif cc.ui.UIListView.CELL_TAG == arg_15_2 then
		if arg_15_3 > #arg_15_0.list then
			return nil
		end

		local var_15_0 = arg_15_1:dequeueItem()

		if not var_15_0 then
			var_15_0 = arg_15_1:newItem()
		else
			var_15_0:removeAllChildren(true)
		end

		local var_15_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/invite_friends/invite_friends_item.csb")
		local var_15_2 = display.newNode()

		var_15_1:addTo(var_15_2)
		var_15_1:getChildByName("has_charge_txt"):setString(var_0_1:translation("ALREADY_CHARGE"))
		var_15_1:getChildByName("player_name"):setString(arg_15_0.list[arg_15_3].player_name)
		var_15_1:getChildByName("sever_name"):setString(arg_15_0.list[arg_15_3].region_name)
		var_15_1:getChildByName("charged_num"):setString(arg_15_0.list[arg_15_3].charge)
		arg_15_0:updateAvatar(var_15_1, arg_15_0.list[arg_15_3].avatar_id)
		var_15_1:setTouchSwallowEnabled(false)
		var_15_1:setAnchorPoint(cc.p(0, 0))
		var_15_1:setPosition(12, 8)
		var_15_2:setContentSize(725, 110)
		var_15_0:addContent(var_15_2)
		var_15_0:setItemSize(725, 110)

		return var_15_0
	end
end

function var_0_0.updateAvatar(arg_16_0, arg_16_1, arg_16_2)
	xyd.setAvatarClip(arg_16_1:getChildByName("avatar_container"), arg_16_2, 1)
	arg_16_1:getChildByName("avatar_kuang"):setLocalZOrder(1)
end

function var_0_0.setWindowState(arg_17_0, arg_17_1)
	arg_17_0.windowState = arg_17_1
end

function var_0_0.getMissionProgress(arg_18_0, arg_18_1)
	local var_18_0 = xyd.tables.inviteMission:condition(arg_18_1)
	local var_18_1 = xyd.tables.inviteMission:type(arg_18_1)
	local var_18_2 = arg_18_0.invite:getInviteFriends()
	local var_18_3 = 0

	for iter_18_0, iter_18_1 in ipairs(var_18_2) do
		if var_18_1 == var_0_2.PLAYER_NUM then
			var_18_3 = var_18_3 + 1
		elseif var_18_1 == var_0_2.HERO_NUM then
			if iter_18_1.partner_num >= var_18_0[#var_18_0] then
				var_18_3 = var_18_3 + 1
			end
		elseif var_18_1 == var_0_2.LEVEL then
			if iter_18_1.lev >= var_18_0[#var_18_0] then
				var_18_3 = var_18_3 + 1
			end
		elseif var_18_1 == var_0_2.CHARGE_NUM and iter_18_1.charge >= var_18_0[#var_18_0] then
			var_18_3 = var_18_3 + 1
		end
	end

	return var_18_3
end

function var_0_0.resortMissionList(arg_19_0, arg_19_1)
	local var_19_0 = {}
	local var_19_1 = 0

	for iter_19_0 = 1, #arg_19_1 do
		if arg_19_1[iter_19_0].can_award then
			var_19_1 = var_19_1 + 1

			table.insert(var_19_0, var_19_1, arg_19_1[iter_19_0])
		else
			table.insert(var_19_0, #var_19_0 + 1, arg_19_1[iter_19_0])
		end
	end

	return var_19_0
end

function var_0_0.didOpen(arg_20_0, arg_20_1)
	var_0_0.super.didOpen(arg_20_0, arg_20_1)
	arg_20_0:addBlockLayer()
end

return var_0_0
