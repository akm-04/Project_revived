local var_0_0 = class("SingleDayAddPartnerWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.singleDay = xyd.ModelManager.get():loadModel(xyd.ModelType.SINGLE_DAY)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.data = arg_1_2.data or {}
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
	arg_4_0:nodeByName("search_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = {
				msg = arg_4_0.message or ""
			}

			if var_5_0.msg == "" then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("INPUT_PLAYERID_OR_NAME")
				})

				return
			end

			arg_4_0.singleDay:searchPlayers(var_5_0, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					if #arg_6_1 <= 0 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("SEARCH_NONE_TEXT")
						})

						return
					end

					arg_4_0.data = arg_6_1

					arg_4_0.list:reload()
				end
			end)
		end
	end)
end

function var_0_0.listDelegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return #arg_7_0.data
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_0
		local var_7_1 = arg_7_0.list:dequeueItem()

		if not var_7_1 then
			var_7_1 = arg_7_0.list:newItem()
		else
			var_7_1:removeAllChildren(false)
		end

		local var_7_2 = arg_7_0:createListContent(arg_7_0.data[arg_7_3])
		local var_7_3 = var_7_2:getWidth()
		local var_7_4 = var_7_2:getHeight()

		var_7_1:setItemSize(var_7_3, var_7_4)
		var_7_1:addContent(var_7_2)

		return var_7_1
	end
end

function var_0_0.createListContent(arg_8_0, arg_8_1)
	local var_8_0 = display.newNode()
	local var_8_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/single_day/add_partener_item.csb")
	local var_8_2 = var_8_1:getChildByName("container")
	local var_8_3 = var_8_2:getChildByName("name_bg")
	local var_8_4 = {
		avatar_id = arg_8_1.avatar_id,
		avatar_frame_id = arg_8_1.avatar_frame_id
	}

	xyd.setPlayerAvatar(var_8_2:getChildByName("avtar_container"), var_8_4)
	arg_8_0.socialSystem:setNameBg(var_8_3, arg_8_1)
	arg_8_0.socialSystem:setOnlineState(var_8_2:getChildByName("friend_state_txt"), arg_8_1)

	if arg_8_1.player_id == arg_8_0.selfPlayer.playerID or arg_8_1.lev < xyd.tables.activities:levelReq(xyd.Activities.SingleDay) then
		var_8_2:getChildByName("apply_btn"):setBright(false)
		var_8_2:getChildByName("apply_btn"):setTouchEnabled(false)
		var_8_2:getChildByName("apply_btn"):getChildByName("apply_text"):setVisible(false)
		var_8_2:getChildByName("apply_btn"):getChildByName("apply_gray_text"):setVisible(true)
	else
		var_8_2:getChildByName("apply_btn"):getChildByName("apply_text"):setVisible(true)
		var_8_2:getChildByName("apply_btn"):getChildByName("apply_gray_text"):setVisible(false)
	end

	var_8_2:getChildByName("friend_info_bg1"):setVisible(false)
	var_8_2:getChildByName("friend_info_bg2"):setVisible(false)
	var_8_2:getChildByName("friend_info_bg3"):setVisible(false)

	if arg_8_1.type == xyd.RelationshipType.Friend then
		var_8_2:getChildByName("friend_info_bg1"):setVisible(true)
		var_8_2:getChildByName("relationship_txt"):setString(var_0_1:translation("FRIEND_TEXT"))
	elseif arg_8_1.player_id ~= arg_8_0.selfPlayer.playerID and arg_8_1.guild_id ~= 0 and arg_8_1.guild_id == arg_8_0.selfPlayer.guildID then
		var_8_2:getChildByName("friend_info_bg2"):setVisible(true)
		var_8_2:getChildByName("relationship_txt"):setString(var_0_1:translation("GUILD"))
	else
		var_8_2:getChildByName("friend_info_bg3"):setVisible(true)
		var_8_2:getChildByName("relationship_txt"):setVisible(false)
		var_8_2:getChildByName("avtar_container"):setPositionY(30)
	end

	local function var_8_5()
		if var_8_2 and not tolua.isnull(var_8_2) then
			var_8_2:getChildByName("apply_btn"):setBright(false)
			var_8_2:getChildByName("apply_btn"):setTouchEnabled(false)
			var_8_2:getChildByName("apply_btn"):getChildByName("apply_text"):setVisible(false)
			var_8_2:getChildByName("apply_btn"):getChildByName("apply_gray_text"):setVisible(true)
		end
	end

	if arg_8_1.is_send_apply == true then
		var_8_5()
	end

	var_8_2:getChildByName("apply_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			local var_10_0 = {
				player_id = arg_8_1.player_id
			}

			arg_8_0.singleDay:applyFellow(var_10_0, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					arg_8_1.is_send_apply = true

					if arg_11_1.is_has_fellow == true then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("TARGET_HAS_FELLOW")
						})
					else
						var_8_5()
					end
				end
			end)
		end
	end)
	var_8_1:addTo(var_8_0)
	var_8_1:setAnchorPoint(cc.p(0, 0))
	var_8_0:setContentSize(var_8_2:getContentSize())
	var_8_1:setName("source")

	return var_8_0
end

function var_0_0.initEditBox(arg_12_0)
	arg_12_0:nodeByName("edit_desc"):setString("")

	local var_12_0 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_12_0, cc.rect(28, 28, 1, 1))

	arg_12_0.editbox_ = ccui.EditBox:create(cc.size(220, 60), var_12_0)

	arg_12_0:nodeByName("edit_container"):addChild(arg_12_0.editbox_)
	arg_12_0.editbox_:setAnchorPoint(cc.p(0, 0))
	arg_12_0.editbox_:setPosition(0, 0)
	arg_12_0.editbox_:registerScriptEditBoxHandler(handler(arg_12_0, arg_12_0.inputboxEventHandler))
	arg_12_0.editbox_:setInputFlag(3)

	if not arg_12_0.message or arg_12_0.message == "" then
		arg_12_0:nodeByName("edit_desc"):setString(var_0_1:translation("INPUT_PLAYERID_OR_NAME"))
		arg_12_0:nodeByName("edit_desc"):setColor(cc.c3b(185, 185, 185))
	else
		arg_12_0:nodeByName("edit_desc"):setString(arg_12_0.message)
		arg_12_0:nodeByName("edit_desc"):setColor(cc.c3b(255, 255, 255))
	end
end

function var_0_0.inputboxEventHandler(arg_13_0, arg_13_1)
	if arg_13_1 == "began" then
		if not arg_13_0.message or arg_13_0.message == "" then
			arg_13_0:nodeByName("edit_desc"):setString("")
		else
			arg_13_0.editbox_:setText(arg_13_0:nodeByName("edit_desc"):getString())
		end
	end

	if arg_13_1 == "return" then
		local var_13_0 = arg_13_0.editbox_:getText()

		if var_13_0 == "" then
			arg_13_0.message = ""

			arg_13_0:nodeByName("edit_desc"):setString(var_0_1:translation("INPUT_PLAYERID_OR_NAME"))
			arg_13_0:nodeByName("edit_desc"):setColor(cc.c3b(185, 185, 185))
		else
			if xyd.utf8len(var_13_0) > 20 then
				var_13_0 = xyd.getTextstr(var_13_0, 1, 20)
			end

			arg_13_0.message = var_13_0

			arg_13_0:nodeByName("edit_desc"):setString(var_13_0)
			arg_13_0:nodeByName("edit_desc"):setColor(cc.c3b(255, 255, 255))
		end

		arg_13_0.editbox_:setText("")
		arg_13_0.editbox_:setVisible(true)
	end
end

function var_0_0.scrollListener(arg_14_0, arg_14_1)
	if arg_14_1.name == "began" then
		arg_14_0.scrollViewMoved_ = false
		arg_14_0.prevX_ = arg_14_1.x
	elseif arg_14_1.name == "moved" and 20 <= math.abs(arg_14_1.x - arg_14_0.prevX_) then
		arg_14_0.scrollViewMoved_ = true
	end
end

return var_0_0
