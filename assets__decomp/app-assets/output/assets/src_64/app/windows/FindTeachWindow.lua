local var_0_0 = class("FindTeachWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	STUDENT = 2,
	TEACHER = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.data = arg_1_2.data or {}
	arg_1_0.relation = arg_1_2.relation
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

	arg_4_0:initEditBox()

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
	arg_4_0:nodeByName("myid_text"):setString(var_0_1:translation("MYID_TEXT"))
	arg_4_0:nodeByName("myid_txt"):setString(arg_4_0.selfPlayer.playerID)
	arg_4_0:nodeByName("friend_num_text"):setString(var_0_1:translation("FRIEND_NUM_TEXT"))
	arg_4_0:nodeByName("friend_num_txt"):setString(arg_4_0.socialSystem:getFriendsCount() .. "/" .. xyd.tables.misc.friendNumberLimit)
	arg_4_0:nodeByName("title"):setString(var_0_1:translation("ADD_FRIEND"))
	arg_4_0:nodeByName("change_group_text"):setString(var_0_1:translation("MAKE_CHANGE"))
	arg_4_0:nodeByName("search_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = {
				filter_str = arg_4_0.message or ""
			}

			if var_5_0.filter_str == "" then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("INPUT_PLAYERID_OR_NAME")
				})

				return
			end

			local var_5_1 = string.format(var_0_1:translation("NAME_LEN_MAX"), xyd.tables.misc.playerNameMaxLength)
			local var_5_2 = string.format(var_0_1:translation("NAME_LEN_LEAST"), xyd.tables.misc.playerNameMinLength)

			if not tonumber(var_5_0.filter_str) then
				if xyd.utf8len(var_5_0.filter_str) > xyd.tables.misc.playerNameMaxLength then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_5_1
					})

					return
				elseif xyd.utf8len(var_5_0.filter_str) < xyd.tables.misc.playerNameMinLength then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_5_2
					})

					return
				end
			end

			var_5_0.relation_type = arg_4_0.relation

			arg_4_0.socialSystem:getFindingList(var_5_0, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					if #arg_6_1.player_list <= 0 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("SEARCH_NONE_TEXT")
						})
					end

					arg_4_0.data = arg_6_1.player_list

					arg_4_0.list:reload()
				end
			end)
		end
	end)
	arg_4_0:nodeByName("change_group_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			arg_4_0.message = ""

			arg_4_0:nodeByName("edit_desc"):setString(var_0_1:translation("INPUT_PLAYERID_OR_NAME"))
			arg_4_0:nodeByName("edit_desc"):setColor(cc.c3b(185, 185, 185))
			arg_4_0:changeRecommendFriends()
		end
	end)
end

function var_0_0.changeRecommendFriends(arg_8_0)
	local var_8_0 = {
		relation_type = arg_8_0.relation
	}

	arg_8_0.socialSystem:getFindingList(var_8_0, function(arg_9_0, arg_9_1)
		if arg_9_0 == xyd.error.OK then
			xyd.playButtonSound()

			arg_8_0.data = arg_9_1.player_list or {}

			arg_8_0.list:reload()
		end
	end)
end

function var_0_0.listDelegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return #arg_10_0.data
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_0
		local var_10_1 = arg_10_0.list:dequeueItem()

		if not var_10_1 then
			var_10_1 = arg_10_0.list:newItem()
		else
			var_10_1:removeAllChildren(false)
		end

		local var_10_2 = arg_10_0:createListContent(arg_10_0.data[arg_10_3])
		local var_10_3 = var_10_2:getWidth()
		local var_10_4 = var_10_2:getHeight()

		var_10_1:setItemSize(var_10_3, var_10_4)
		var_10_1:addContent(var_10_2)

		return var_10_1
	end
end

function var_0_0.createListContent(arg_11_0, arg_11_1)
	local var_11_0 = display.newNode()
	local var_11_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/manage_friend/add_friend_item.csb")
	local var_11_2 = var_11_1:getChildByName("container")
	local var_11_3 = var_11_2:getChildByName("name_bg")
	local var_11_4 = {
		avatar_id = arg_11_1.avatar_id,
		avatar_frame_id = arg_11_1.avatar_frame_id
	}

	if arg_11_1.is_online == 0 then
		var_11_4.isGray = true
	end

	var_11_4.playerInfo = arg_11_1

	xyd.setPlayerAvatar(var_11_2:getChildByName("avtar_container"), var_11_4)
	arg_11_0.socialSystem:setNameBg(var_11_3, arg_11_1)
	var_11_3:getChildByName("region_txt"):setString("")
	arg_11_0.socialSystem:setOnlineState(var_11_2:getChildByName("friend_state_txt"), arg_11_1)
	var_11_2:getChildByName("btn"):getChildByName("apply_text"):setString(var_0_1:translation("APPLY"))
	var_11_2:getChildByName("btn"):getChildByName("set_black_text"):setVisible(false)

	if arg_11_1.player_id == arg_11_0.selfPlayer.playerID then
		var_11_2:getChildByName("btn"):setVisible(false)
	end

	local function var_11_5()
		var_11_2:getChildByName("btn"):setVisible(false)
	end

	if arg_11_1.is_send_apply == true then
		var_11_5()
	end

	var_11_2:getChildByName("btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_13_0, arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			if arg_11_0.socialSystem:getFriendsCount() >= xyd.tables.misc.friendNumberLimit then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("TEACHER_FRIEND_TIP")
				})

				return
			end

			local var_13_0 = arg_11_0.socialSystem.teacherInfo.applyTimes

			if arg_11_0.relation == var_0_2.STUDNET then
				var_13_0 = arg_11_0.socialSystem.studentInfo.applyTimes
			end

			if var_13_0 >= xyd.tables.misc.teacherRelationSendTimes then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("TEACHER_SEND_TIP4")
				})

				return true
			end

			local var_13_1 = {
				data = arg_11_1,
				relation = arg_11_0.relation,
				callback = var_11_5
			}

			xyd.WindowManager.get():openWindow("input_authentic_msg", var_13_1)
		end
	end)
	var_11_1:addTo(var_11_0)
	var_11_1:setAnchorPoint(cc.p(0, 0))
	var_11_0:setContentSize(var_11_2:getContentSize())
	var_11_1:setName("source")

	return var_11_0
end

function var_0_0.initEditBox(arg_14_0)
	arg_14_0:nodeByName("edit_desc"):setString("")

	local var_14_0 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_14_0, cc.rect(28, 28, 1, 1))

	arg_14_0.editbox_ = ccui.EditBox:create(cc.size(380, 60), var_14_0)

	arg_14_0:nodeByName("edit_container"):addChild(arg_14_0.editbox_)
	arg_14_0.editbox_:setAnchorPoint(cc.p(0, 0))
	arg_14_0.editbox_:setPosition(0, 0)
	arg_14_0.editbox_:registerScriptEditBoxHandler(handler(arg_14_0, arg_14_0.inputboxEventHandler))
	arg_14_0.editbox_:setInputFlag(3)

	if not arg_14_0.message or arg_14_0.message == "" then
		arg_14_0:nodeByName("edit_desc"):setString(var_0_1:translation("INPUT_PLAYERID_OR_NAME"))
		arg_14_0:nodeByName("edit_desc"):setColor(cc.c3b(255, 255, 255))
	else
		arg_14_0:nodeByName("edit_desc"):setString(arg_14_0.message)
		arg_14_0:nodeByName("edit_desc"):setColor(cc.c3b(255, 255, 255))
	end
end

function var_0_0.inputboxEventHandler(arg_15_0, arg_15_1)
	if arg_15_1 == "began" then
		if not arg_15_0.message or arg_15_0.message == "" then
			arg_15_0:nodeByName("edit_desc"):setString("")
		else
			arg_15_0.editbox_:setText(arg_15_0:nodeByName("edit_desc"):getString())
		end
	end

	if arg_15_1 == "return" then
		local var_15_0 = arg_15_0.editbox_:getText()

		if var_15_0 == "" then
			arg_15_0.message = ""

			arg_15_0:nodeByName("edit_desc"):setString(var_0_1:translation("INPUT_PLAYERID_OR_NAME"))
			arg_15_0:nodeByName("edit_desc"):setColor(cc.c3b(255, 255, 255))
		else
			if xyd.utf8len(var_15_0) > 20 then
				var_15_0 = xyd.getTextstr(var_15_0, 1, 20)
			end

			arg_15_0.message = var_15_0

			arg_15_0:nodeByName("edit_desc"):setString(var_15_0)
			arg_15_0:nodeByName("edit_desc"):setColor(cc.c3b(255, 255, 255))
		end

		arg_15_0.editbox_:setText("")
		arg_15_0.editbox_:setVisible(true)
	end
end

function var_0_0.scrollListener(arg_16_0, arg_16_1)
	if arg_16_1.name == "began" then
		arg_16_0.scrollViewMoved_ = false
		arg_16_0.prevX_ = arg_16_1.x
	elseif arg_16_1.name == "moved" and 20 <= math.abs(arg_16_1.x - arg_16_0.prevX_) then
		arg_16_0.scrollViewMoved_ = true
	end
end

return var_0_0
