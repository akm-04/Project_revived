local var_0_0 = class("SingleDayApplyListWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.singleDay = xyd.ModelManager.get():loadModel(xyd.ModelType.SINGLE_DAY)
	arg_1_0.data1 = arg_1_0.singleDay.applyList.recieve_list or {}
	arg_1_0.data2 = arg_1_0.singleDay.applyList.send_list or {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.scroll = arg_4_0:nodeByName("scroll")

	local var_4_0 = arg_4_0.scroll:getContentSize()

	arg_4_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 20, var_4_0.width, var_4_0.height - 20),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.list:setBounceable(true)
	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.listDelegate))
	arg_4_0.list:setTouchType(false)
	arg_4_0.list:reload()
end

function var_0_0.listDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #arg_5_0.data1 + #arg_5_0.data2 + 2
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0
		local var_5_1 = arg_5_0.list:dequeueItem()

		if not var_5_1 then
			var_5_1 = arg_5_0.list:newItem()
		else
			var_5_1:removeAllChildren(false)
		end

		local var_5_2

		if arg_5_3 == 1 then
			var_5_2 = arg_5_0:createTitleContent(true)
		elseif arg_5_3 < #arg_5_0.data1 + 2 then
			var_5_2 = arg_5_0:createListContent(arg_5_0.data1[arg_5_3 - 1], true)
		elseif arg_5_3 == #arg_5_0.data1 + 2 then
			var_5_2 = arg_5_0:createTitleContent(false)
		else
			var_5_2 = arg_5_0:createListContent(arg_5_0.data2[arg_5_3 - #arg_5_0.data1 - 2], false)
		end

		local var_5_3 = var_5_2:getWidth()
		local var_5_4 = var_5_2:getHeight()

		var_5_1:setItemSize(var_5_3, var_5_4)
		var_5_1:addContent(var_5_2)

		return var_5_1
	end
end

function var_0_0.createTitleContent(arg_6_0, arg_6_1)
	local var_6_0 = display.newNode()
	local var_6_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/single_day/apply_list_title.csb")
	local var_6_2 = var_6_1:getChildByName("container")
	local var_6_3 = var_0_1:translation("SINGLE_DAY_APPLY_TITLE1")

	if not arg_6_1 then
		var_6_3 = var_0_1:translation("SINGLE_DAY_APPLY_TITLE2")
	end

	var_6_2:getChildByName("title_bg"):getChildByName("title_txt"):setString(var_6_3)
	var_6_1:addTo(var_6_0)
	var_6_1:setAnchorPoint(cc.p(0, 0))
	var_6_0:setContentSize(var_6_2:getContentSize())
	var_6_1:setName("source")

	return var_6_0
end

function var_0_0.createListContent(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = display.newNode()
	local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/single_day/apply_list_item.csb")
	local var_7_2 = var_7_1:getChildByName("container")
	local var_7_3 = var_7_2:getChildByName("name_bg")
	local var_7_4 = {
		avatar_id = arg_7_1.avatar_id,
		avatar_frame_id = arg_7_1.avatar_frame_id
	}

	xyd.setPlayerAvatar(var_7_2:getChildByName("avtar_container"), var_7_4)
	arg_7_0.socialSystem:setNameBg(var_7_3, arg_7_1)
	arg_7_0.socialSystem:setOnlineState(var_7_2:getChildByName("friend_state_txt"), arg_7_1)

	local var_7_5 = arg_7_0:createTimeString(arg_7_1.send_time)

	var_7_2:getChildByName("time_state_txt"):setString(var_7_5)
	var_7_2:getChildByName("friend_info_bg1"):setVisible(false)
	var_7_2:getChildByName("friend_info_bg2"):setVisible(false)
	var_7_2:getChildByName("friend_info_bg3"):setVisible(false)
	var_7_2:getChildByName("relationship_txt"):setVisible(true)

	if arg_7_0.socialSystem:isInFriendList(arg_7_1.player_id) then
		var_7_2:getChildByName("friend_info_bg1"):setVisible(true)
		var_7_2:getChildByName("relationship_txt"):setString(var_0_1:translation("FRIEND_TEXT"))
	elseif arg_7_1.guild_id ~= 0 and arg_7_1.guild_id == arg_7_0.selfPlayer.guildID then
		var_7_2:getChildByName("friend_info_bg2"):setVisible(true)
		var_7_2:getChildByName("relationship_txt"):setString(var_0_1:translation("GUILD"))
	else
		var_7_2:getChildByName("friend_info_bg3"):setVisible(true)
		var_7_2:getChildByName("relationship_txt"):setVisible(false)
		var_7_2:getChildByName("avtar_container"):setPositionY(30)
	end

	if arg_7_2 == false then
		var_7_2:getChildByName("accept_btn"):setVisible(false)
		var_7_2:getChildByName("time_state_txt"):setVisible(false)
	end

	var_7_2:getChildByName("accept_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = {
				player_id = arg_7_1.player_id
			}

			arg_7_0.singleDay:acceptFellow(var_8_0, function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					if arg_9_1.is_has_fellow == true then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("TARGET_HAS_FELLOW")
						})

						return
					end

					local var_9_0 = xyd.WindowManager.get():getWindow("single_day")

					if var_9_0 and not tolua.isnull(var_9_0) then
						var_9_0:update()
					end

					xyd.WindowManager.get():closeWindow(arg_7_0)
				end
			end)
		end
	end)
	var_7_1:addTo(var_7_0)
	var_7_1:setAnchorPoint(cc.p(0, 0))
	var_7_0:setContentSize(var_7_2:getContentSize())
	var_7_1:setName("source")

	return var_7_0
end

function var_0_0.createTimeString(arg_10_0, arg_10_1)
	local var_10_0 = 1
	local var_10_1 = xyd.ServerTime.get():getServerTime()
	local var_10_2 = xyd.tables.misc.applyFellowTimeLimit * 3600 - (var_10_1 - arg_10_1)
	local var_10_3 = math.floor(var_10_2 / 3600)
	local var_10_4 = math.ceil(var_10_2 % 3600 / 60)

	if var_10_4 <= 1 then
		var_10_4 = 1
	end

	if var_10_3 > 0 then
		return string.format(var_0_1:translation("FELLOW_APPLY_RAMAIN_TIME"), var_10_3 .. xyd.tables.translation:translation("UNIT_HOUR"))
	else
		return string.format(var_0_1:translation("FELLOW_APPLY_RAMAIN_TIME"), var_10_4 .. xyd.tables.translation:translation("UNIT_MINUTE"))
	end
end

function var_0_0.scrollListener(arg_11_0, arg_11_1)
	if arg_11_1.name == "began" then
		arg_11_0.scrollViewMoved_ = false
		arg_11_0.prevX_ = arg_11_1.x
	elseif arg_11_1.name == "moved" and 20 <= math.abs(arg_11_1.x - arg_11_0.prevX_) then
		arg_11_0.scrollViewMoved_ = true
	end
end

return var_0_0
