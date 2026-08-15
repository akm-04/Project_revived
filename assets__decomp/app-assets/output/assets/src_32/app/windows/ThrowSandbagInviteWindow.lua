local var_0_0 = class("ThrowSandbagInviteWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 2
local var_0_3 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.throwSandbag = xyd.ModelManager.get():loadModel(xyd.ModelType.THROW_SANDBAG)
	arg_1_0.friendInfos = arg_1_2.friendInfos
	arg_1_0.chooseItem = nil
	arg_1_0.chooseID = 0
	arg_1_0.chooseInfo = nil
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:initData()

	arg_3_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, arg_3_0:nodeByName("list"):getWidth(), arg_3_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setBounceable(true)

	for iter_3_0 = 1, math.ceil(#arg_3_0.friendInfos / var_0_2) do
		local var_3_0 = arg_3_0.list:newItem()
		local var_3_1 = display.newNode()

		arg_3_0:initCell(var_3_1, iter_3_0)

		local var_3_2 = display.newNode()

		var_3_2:addChild(var_3_1)
		var_3_2:setContentSize(var_3_1:getContentSize())
		var_3_0:setItemSize(var_3_1:getContentSize().width, var_3_1:getContentSize().height)
		var_3_0:addContent(var_3_2)
		arg_3_0.list:addItem(var_3_0)
	end

	arg_3_0.list:reload()
	arg_3_0:nodeByName("text_title"):setString(var_0_1:translation("THROW_SANDBAG_TEXT_2"))
	arg_3_0:nodeByName("text_invite"):setString(var_0_1:translation("THROW_SANDBAG_TEXT_5"))
	arg_3_0:nodeByName("btn_invite"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playCloseSound()

			arg_3_0.throwSandbag.inviteFriendID = arg_3_0.chooseID

			xyd.WindowManager.get():getWindow("throw_sandbag_main"):updateFriendIcon(arg_3_0.chooseInfo)
			arg_3_0:close()
		end
	end)
	arg_3_0:nodeByName("text_cancle"):setString(var_0_1:translation("CANCEL"))
	arg_3_0:nodeByName("btn_cancle"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playCloseSound()
			arg_3_0:close()
		end
	end)
end

function var_0_0.initData(arg_6_0)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.friendInfos) do
		if iter_6_1.invited_time < var_0_3:getValue("dodge_invited") and iter_6_1.is_invited ~= 0 then
			table.insert(var_6_0, iter_6_1)
		end
	end

	for iter_6_2, iter_6_3 in ipairs(arg_6_0.friendInfos) do
		if iter_6_3.invited_time < var_0_3:getValue("dodge_invited") and iter_6_3.is_invited == 0 then
			table.insert(var_6_0, iter_6_3)
		end
	end

	for iter_6_4, iter_6_5 in ipairs(arg_6_0.friendInfos) do
		if iter_6_5.invited_time >= var_0_3:getValue("dodge_invited") then
			table.insert(var_6_0, iter_6_5)
		end
	end

	arg_6_0.friendInfos = var_6_0
end

function var_0_0.initCell(arg_7_0, arg_7_1, arg_7_2)
	for iter_7_0 = 1, var_0_2 do
		local var_7_0 = (arg_7_2 - 1) * var_0_2 + iter_7_0

		if var_7_0 > #arg_7_0.friendInfos then
			break
		end

		local var_7_1 = arg_7_0.friendInfos[var_7_0]
		local var_7_2 = var_7_1.player_info
		local var_7_3 = var_7_2.player_id
		local var_7_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/throw_sandbag/invite/invite_item.csb")
		local var_7_5 = var_7_4:getChildByName("container")

		xyd.setPlayerAvatar(var_7_5:getChildByName("avatar"), {
			avatar_id = var_7_2.avatar_id,
			avatar_frame_id = var_7_2.avatar_frame_id
		})

		if var_7_2.conquer_lev and var_7_2.conquer_lev > 0 then
			local var_7_6 = {
				x = -1,
				y = 2
			}

			xyd.setConquerLev(var_7_2.conquer_lev, var_7_5:getChildByName("lev"), var_7_5:getChildByName("level_bg"), var_7_6, nil, nil, nil, var_7_2.conquer_loop_id)
		else
			var_7_5:getChildByName("lev"):setString(var_7_2.lev)
		end

		var_7_5:getChildByName("name"):setString(var_7_2.player_name)

		if var_7_1.is_invited ~= 0 and var_7_1.invited_time < var_0_3:getValue("dodge_invited") then
			var_7_4:getChildByName("tag_red"):setVisible(true)
			var_7_4:getChildByName("text"):setVisible(true)
			var_7_4:getChildByName("text"):enableOutline(cc.c4b(130, 32, 64, 255), 2)
			var_7_4:getChildByName("text"):setString(var_0_1:translation("THROW_SANDBAG_TEXT_11"))
		elseif var_7_1.invited_time >= var_0_3:getValue("dodge_invited") then
			var_7_4:getChildByName("tag_blue"):setVisible(true)
			var_7_4:getChildByName("text"):setVisible(true)
			var_7_4:getChildByName("text"):enableOutline(cc.c4b(50, 107, 170, 255), 2)
			var_7_4:getChildByName("text"):setString(var_0_1:translation("THROW_SANDBAG_TEXT_12"))
			var_7_4:getChildByName("shadow"):setVisible(true)
		end

		if arg_7_0.throwSandbag.inviteFriendID == var_7_3 then
			var_7_5:getChildByName("bg_choose"):setVisible(true)

			arg_7_0.chooseID = var_7_3
			arg_7_0.chooseInfo = var_7_1
			arg_7_0.chooseItem = var_7_5
		end

		var_7_5:setTouchEnabled(true)
		var_7_5:addTouchEventListener(function(arg_8_0, arg_8_1)
			if arg_8_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if var_7_1.invited_time < var_0_3:getValue("dodge_invited") then
					arg_7_0:updateChoose(var_7_5, var_7_3, var_7_1)
				else
					local var_8_0 = var_0_1:translation("THROW_SANDBAG_TEXT_18")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_8_0
					})
				end
			end
		end)
		var_7_4:addTo(arg_7_1)
		var_7_4:setPosition((iter_7_0 - 1) * (var_7_5:getWidth() + 12), 0)
	end

	arg_7_1:setContentSize(arg_7_0:nodeByName("list"):getWidth(), 120)
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.startClick_ = true
		arg_9_0.prevX_ = arg_9_1.x
	elseif arg_9_1.name == "moved" and 20 <= math.abs(arg_9_1.x - arg_9_0.prevX_) then
		arg_9_0.startClick_ = false
	end
end

function var_0_0.didOpen(arg_10_0, arg_10_1)
	arg_10_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.updateChoose(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	if arg_11_0.chooseItem ~= arg_11_1 then
		if arg_11_0.chooseItem then
			arg_11_0.chooseItem:getChildByName("bg_choose"):setVisible(false)
		end

		arg_11_0.chooseID = arg_11_2
		arg_11_0.chooseInfo = arg_11_3
		arg_11_0.chooseItem = arg_11_1

		arg_11_1:getChildByName("bg_choose"):setVisible(true)
	end
end

return var_0_0
