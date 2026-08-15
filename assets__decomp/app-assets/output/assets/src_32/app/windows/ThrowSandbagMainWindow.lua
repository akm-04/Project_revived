local var_0_0 = class("ThrowSandbagMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpriteNodeButton")
local var_0_3 = xyd.tables.throwSandbagActivity

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.throwSandbag = xyd.ModelManager.get():loadModel(xyd.ModelType.THROW_SANDBAG)
	arg_1_0.ticket = arg_1_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc:getValue("dodge_ticket"))
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setTexts()
	arg_3_0:setBtns()

	local var_3_0 = arg_3_0.throwSandbag.baseInfo.act_id

	if var_3_0 and var_3_0 ~= 0 then
		local var_3_1 = var_0_3:pic(var_3_0)
		local var_3_2 = xyd.AssetLoader.get():loadSprite(var_3_1)

		var_3_2:setAnchorPoint(cc.p(0, 0.5))
		var_3_2:addTo(arg_3_0:nodeByName("node_title"))

		local var_3_3 = arg_3_0:nodeByName("text_count")
		local var_3_4 = var_0_3:effectNum(var_3_0) - arg_3_0.throwSandbag.baseInfo.daily_count
		local var_3_5 = math.max(var_3_4, 0)

		var_3_3:setString("(" .. var_3_5 .. "/" .. var_0_3:effectNum(var_3_0) .. ")")
		var_3_3:setPositionX(var_3_2:getWidth() + 30)

		local var_3_6 = arg_3_0:nodeByName("activity_container")
		local var_3_7 = var_3_6:getChildByName("bg"):getContentSize()

		var_3_6:getChildByName("bg"):setContentSize(var_3_2:getWidth() + var_3_3:getWidth() + 70, var_3_7.height)

		local var_3_8 = var_3_6:getChildByName("line"):getContentSize()

		var_3_6:getChildByName("line"):setContentSize(var_3_2:getWidth() + var_3_3:getWidth() + 53, var_3_8.height)
		arg_3_0:nodeByName("text_activity"):setString(var_0_3:subTitle(var_3_0))
		arg_3_0:nodeByName("text_activity"):enableOutline(cc.c4b(130, 73, 73, 255), 2)
	else
		arg_3_0:nodeByName("activity_container"):setVisible(false)
	end
end

function var_0_0.setTexts(arg_4_0)
	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("THROW_SANDBAG_TEXT_1"))
	arg_4_0:nodeByName("text_invite"):setString(var_0_1:translation("THROW_SANDBAG_TEXT_2"))
	arg_4_0:nodeByName("text_invite"):enableOutline(cc.c4b(46, 56, 68, 255), 2)
	arg_4_0:nodeByName("text_start"):setString(var_0_1:translation("THROW_SANDBAG_TEXT_3"))
	arg_4_0:nodeByName("text_top_num"):setString(arg_4_0.ticket)
end

function var_0_0.setBtns(arg_5_0)
	local var_5_0 = var_0_2.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.BLUE)
	})

	var_5_0:addTo(arg_5_0)
	var_5_0:setAnchorPoint(0.5, 0.5)
	var_5_0:setPosition(46, 694)
	var_5_0:setName("return_btn")

	arg_5_0.returnBtn = var_5_0

	arg_5_0.returnBtn:addTouchEvent(function(arg_6_0)
		if arg_6_0.name == "ended" then
			xyd.playCloseSound()
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)
	arg_5_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = {}

			var_7_0.title_name = "THROW_SANDBAG_TEXT_1"
			var_7_0.rule = "THROW_SANDBAG_INFO"
			var_7_0.style = xyd.RuleStyle.BLUE

			xyd.WindowManager.get():openWindow("new_text_rule", var_7_0)
		end
	end)
	arg_5_0:nodeByName("btn_invite"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_8_0, arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			arg_5_0.throwSandbag:refreshFriendList({}, function()
				local var_9_0 = {
					friendInfos = arg_5_0.throwSandbag.friendInfos
				}

				xyd.WindowManager.get():openWindow("throw_sandbag_invite", var_9_0)
			end)
		end
	end)
	arg_5_0:nodeByName("btn_cancle_invite"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_10_0, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			arg_5_0.throwSandbag.inviteFriendID = 0

			arg_5_0:nodeByName("btn_cancle_invite"):setVisible(false)
			arg_5_0:nodeByName("container_invited"):setVisible(false)
			arg_5_0:nodeByName("btn_invite"):setVisible(true)
			arg_5_0:nodeByName("text_invite"):setString(var_0_1:translation("THROW_SANDBAG_TEXT_2"))
		end
	end)
	arg_5_0:nodeByName("btn_start"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_11_0, arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			if arg_5_0.ticket < 1 then
				local var_11_0 = var_0_1:translation("THROW_SANDBAG_TEXT_13")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_0
				})
			else
				local var_11_1 = {}

				if arg_5_0.throwSandbag.inviteFriendID > 0 then
					var_11_1.friend_id = arg_5_0.throwSandbag.inviteFriendID
				end

				arg_5_0.throwSandbag:beginGame(var_11_1, function(arg_12_0, arg_12_1)
					if arg_12_0 == xyd.error.OK then
						local var_12_0 = xyd.tables.misc:getValue("dodge_ticket")

						arg_5_0.selfPlayer:getBackpack():removeItem({
							itemNum = 1,
							itemID = var_12_0
						})

						arg_5_0.ticket = arg_5_0.ticket - 1

						arg_5_0:nodeByName("text_top_num"):setString(arg_5_0.ticket)
						arg_5_0:nodeByName("btn_cancle_invite"):setVisible(false)
						arg_5_0:nodeByName("container_invited"):setVisible(false)
						arg_5_0:nodeByName("btn_invite"):setVisible(true)
						arg_5_0:nodeByName("text_invite"):setString(var_0_1:translation("THROW_SANDBAG_TEXT_2"))

						local var_12_1 = arg_5_0.throwSandbag.baseInfo.act_id

						if var_12_1 and var_12_1 ~= 0 then
							local var_12_2 = arg_5_0:nodeByName("text_count")
							local var_12_3 = var_0_3:effectNum(var_12_1) - arg_5_0.throwSandbag.baseInfo.daily_count
							local var_12_4 = math.max(var_12_3, 0)

							var_12_2:setString("(" .. var_12_4 .. "/" .. var_0_3:effectNum(var_12_1) .. ")")
						end

						xyd.WindowManager.get():openWindow("throw_sandbag_choose", arg_12_1)
					else
						local var_12_5 = var_0_1:translation("THROW_SANDBAG_TEXT_16")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_12_5
						})
					end
				end)
			end
		end
	end)
end

function var_0_0.updateFriendIcon(arg_13_0, arg_13_1)
	if arg_13_0.throwSandbag.inviteFriendID ~= 0 then
		arg_13_0:nodeByName("btn_cancle_invite"):setVisible(true)
		arg_13_0:nodeByName("container_invited"):setVisible(true)
		arg_13_0:nodeByName("btn_invite"):setVisible(false)

		local var_13_0 = arg_13_1.player_info
		local var_13_1 = arg_13_0:nodeByName("icon_invited")

		xyd.setPlayerAvatar(var_13_1, {
			avatar_id = var_13_0.avatar_id,
			avatar_frame_id = var_13_0.avatar_frame_id
		})
		arg_13_0:nodeByName("text_invite"):setString(var_13_0.player_name)
	end
end

return var_0_0
