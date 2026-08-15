local var_0_0 = class("NewChangeAvatarWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = {
	110006002,
	110007026,
	110007027,
	110007043,
	110007049
}
local var_0_4 = {
	AVATAR = 1,
	TITLE = 3,
	AVATAR_FRAME = 2
}
local var_0_5 = {
	SPECIL_AVATAR = 5,
	BASE_AVATAR = 1,
	SUPER_AVATAR = 3,
	AWAKEN_AVATAR = 4,
	HERO_AVATAR = 2
}
local var_0_6 = {
	AVATAR = var_0_1:translation("PERSON_CHANGE_AVATAR"),
	FRAME = var_0_1:translation("PERSON_CHANGE_FRAME"),
	TITLE = var_0_1:translation("PERSON_CHANGE_TITLE")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.changeAvatar_ = xyd.ModelManager.get():loadModel(xyd.ModelType.CHANGE_AVATAR)
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.loadTitleInfo(arg_2_0)
	xyd.Backend.get():request(xyd.mid.GET_TITLE_INFO, nil, function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			arg_2_0.titleInfo = arg_3_1.title_list or {}

			arg_2_0:changeListView()
		end
	end)
end

function var_0_0.scrollListener(arg_4_0, arg_4_1)
	if arg_4_1.name == "began" then
		arg_4_0.scrollViewMoved_ = false
		arg_4_0.prevY_ = arg_4_1.y
	elseif arg_4_1.name == "moved" and 20 <= math.abs(arg_4_1.y - arg_4_0.prevY_) then
		arg_4_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_5_0, arg_5_1)
	arg_5_0.listView_ = cc.ui.UIListView.new({
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, 720, 560),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_5_0:nodeByName("list")):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.listView_:setDelegate(handler(arg_5_0, arg_5_0.sourceDelegate))
	arg_5_0.listView_:setBounceable(true)

	arg_5_0.frameListView_ = cc.ui.UIListView.new({
		touchOnContent = true,
		viewRect = cc.rect(0, 0, 720, 560),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_5_0:nodeByName("list_frame")):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.frameListView_:setBounceable(true)

	arg_5_0.titleListView_ = cc.ui.UIListView.new({
		touchOnContent = true,
		viewRect = cc.rect(0, 0, 720, 560),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_5_0:nodeByName("list_title")):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.titleListView_:setBounceable(true)

	arg_5_0.titleFlag = 1
	arg_5_0.titleInfo = {}

	if arg_5_1.titleInfo then
		arg_5_0.titleInfo = arg_5_1.titleInfo
	end

	if arg_5_1.menuType and arg_5_1.menuType == var_0_4.TITLE then
		arg_5_0.titleFlag = 0
		arg_5_0.leftMenuType = var_0_4.TITLE
	else
		arg_5_0.leftMenuType = var_0_4.AVATAR
	end

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_5_0):addEventListener(xyd.event.UPDATE_AVATAR_LIST, function(arg_6_0)
		arg_5_0:updateList()
		arg_5_0.listView_:reload()
		arg_5_0:updateFrameList()
		arg_5_0.frameListView_:reload()
		arg_5_0:updateTitleList()
		arg_5_0.titleListView_:reload()
	end)
	arg_5_0:initLeftMenu()
	arg_5_0:changeListView()
end

function var_0_0.updateList(arg_7_0)
	arg_7_0.titleRows_ = {}
	arg_7_0.timingAvatar = {}
	arg_7_0.avatarTypeNums = {}
	arg_7_0.avatars_ = {}

	local var_7_0 = 1

	table.insert(arg_7_0.titleRows_, var_7_0)
	table.insert(arg_7_0.avatarTypeNums, #xyd.tables.avatar.base_avatar)

	if arg_7_0.changeAvatar_.avatarOrder[var_0_5.BASE_AVATAR] == 1 then
		table.insert(arg_7_0.avatars_, xyd.tables.avatar.base_avatar)

		var_7_0 = var_7_0 + math.ceil(#xyd.tables.avatar.base_avatar / 5) + 1
	else
		table.insert(arg_7_0.avatars_, {})

		var_7_0 = var_7_0 + 1
	end

	table.insert(arg_7_0.titleRows_, var_7_0)

	local var_7_1 = {}
	local var_7_2 = {}
	local var_7_3 = {}
	local var_7_4 = 0
	local var_7_5 = 0
	local var_7_6 = 0

	for iter_7_0, iter_7_1 in pairs(arg_7_0.selfPlayer.heros_) do
		if iter_7_1.color_ >= xyd.EquipQuality.PURPLE and xyd.tables.avatar.hero_avatar[iter_7_1.tableID_] ~= nil then
			table.insert(var_7_1, xyd.tables.avatar.hero_avatar[iter_7_1.tableID_])

			var_7_4 = var_7_4 + 1
		end

		if iter_7_1:isAwaken() then
			if xyd.tables.avatar.awaken_avatar[iter_7_1.tableID_] ~= nil then
				table.insert(var_7_2, xyd.tables.avatar.awaken_avatar[iter_7_1.tableID_])

				var_7_6 = var_7_6 + 1
			end

			local var_7_7 = iter_7_1:beforeAwakenID()

			table.insert(var_7_1, xyd.tables.avatar.hero_avatar[var_7_7])

			var_7_4 = var_7_4 + 1
		end

		if iter_7_1:isSuper() and iter_7_1:getStar() >= 2 and xyd.tables.avatar.hero_avatar[iter_7_1.tableID_] then
			table.insert(var_7_3, xyd.tables.avatar.hero_avatar[iter_7_1.tableID_])

			var_7_5 = var_7_5 + 1
		end
	end

	table.insert(arg_7_0.avatarTypeNums, #var_7_1)
	table.insert(arg_7_0.avatarTypeNums, #var_7_3)
	table.insert(arg_7_0.avatarTypeNums, #var_7_2)

	if arg_7_0.changeAvatar_.avatarOrder[var_0_5.HERO_AVATAR] == 1 then
		table.insert(arg_7_0.avatars_, var_7_1)

		var_7_0 = var_7_0 + math.ceil(var_7_4 / 5) + 1
	else
		table.insert(arg_7_0.avatars_, {})

		var_7_0 = var_7_0 + 1
	end

	table.insert(arg_7_0.titleRows_, var_7_0)

	if arg_7_0.changeAvatar_.avatarOrder[var_0_5.SUPER_AVATAR] == 1 then
		table.insert(arg_7_0.avatars_, var_7_3)

		var_7_0 = var_7_0 + math.ceil(var_7_5 / 5) + 1
	else
		table.insert(arg_7_0.avatars_, {})

		var_7_0 = var_7_0 + 1
	end

	table.insert(arg_7_0.titleRows_, var_7_0)

	if arg_7_0.changeAvatar_.avatarOrder[var_0_5.AWAKEN_AVATAR] == 1 then
		table.insert(arg_7_0.avatars_, var_7_2)

		var_7_0 = var_7_0 + math.ceil(var_7_6 / 5) + 1
	else
		table.insert(arg_7_0.avatars_, {})

		var_7_0 = var_7_0 + 1
	end

	table.insert(arg_7_0.titleRows_, var_7_0)

	local var_7_8 = {}
	local var_7_9 = {}
	local var_7_10 = {}

	for iter_7_2, iter_7_3 in pairs(xyd.tables.avatar.specil_avatar) do
		if xyd.tables.avatar.type_[iter_7_3] <= 3 then
			table.insert(var_7_10, iter_7_3)
		else
			local var_7_11 = false

			if xyd.tables.avatar.type_[iter_7_3] == 7 then
				for iter_7_4, iter_7_5 in pairs(arg_7_0.selfPlayer.heros_) do
					local var_7_12 = iter_7_5.skinIds_

					for iter_7_6 = 1, #var_7_12 do
						if var_7_12[iter_7_6] == xyd.tables.avatar.partner_id_[iter_7_3] then
							var_7_11 = true

							table.insert(var_7_10, iter_7_3)

							break
						end
					end

					if var_7_11 then
						break
					end
				end
			end

			for iter_7_7, iter_7_8 in pairs(arg_7_0.selfPlayer:getBackpack():getItemsByTypes({
				xyd.ItemType.AVATAR
			})) do
				if iter_7_8.itemID == iter_7_3 then
					if iter_7_8.startTime and xyd.tables.avatar:getAvatarTime(iter_7_8.itemID) > 0 and iter_7_8.startTime + xyd.tables.avatar:getAvatarTime(iter_7_8.itemID) * 24 * 3600 > xyd.ServerTime.get():getServerTime() then
						arg_7_0.timingAvatar[iter_7_8.itemID] = iter_7_8
						var_7_11 = true

						table.insert(var_7_10, iter_7_3)

						break
					end

					if not iter_7_8.startTime or xyd.tables.avatar:getAvatarTime(iter_7_8.itemID) == -1 then
						var_7_11 = true

						table.insert(var_7_10, iter_7_3)
					end

					break
				end
			end

			if xyd.tables.avatar.type_[iter_7_3] == 11 then
				function swimsuitComplete()
					local var_8_0 = true

					for iter_8_0, iter_8_1 in ipairs(var_0_3) do
						local var_8_1 = false

						if iter_8_0 > 1 and var_8_0 then
							for iter_8_2, iter_8_3 in pairs(arg_7_0.selfPlayer.heros_) do
								local var_8_2 = iter_8_3.skinIds_

								for iter_8_4 = 1, #var_8_2 do
									if var_8_2[iter_8_4] == xyd.tables.avatar.partner_id_[iter_8_1] then
										var_8_1 = true

										break
									end
								end

								if var_8_1 then
									break
								end
							end

							var_8_0 = var_8_1
						end
					end

					return var_8_0
				end

				if iter_7_3 == var_0_3[1] and swimsuitComplete() then
					table.insert(var_7_10, iter_7_3)

					var_7_11 = true
				end
			end

			if var_7_11 == false and xyd.tables.avatar.is_show_[iter_7_3] == 1 then
				table.insert(var_7_9, iter_7_3)
			end
		end
	end

	local var_7_13 = var_7_10

	arg_7_0.lock_index_ = #var_7_10 + 1

	for iter_7_9, iter_7_10 in pairs(var_7_9) do
		table.insert(var_7_13, iter_7_10)
	end

	table.insert(arg_7_0.avatarTypeNums, #var_7_13)

	if arg_7_0.changeAvatar_.avatarOrder[var_0_5.SPECIL_AVATAR] == 1 then
		table.insert(arg_7_0.avatars_, var_7_13)
	else
		table.insert(arg_7_0.avatars_, {})
	end

	if arg_7_0.scrollNodePosX and arg_7_0.scrollNodePosY then
		arg_7_0.listView_:getScrollNode():setPosition(arg_7_0.scrollNodePosX, arg_7_0.scrollNodePosY)
	end
end

function var_0_0.setAvatar(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = "images/avatars/" .. arg_9_1 .. ".png"
	local var_9_1 = arg_9_3
	local var_9_2
	local var_9_3

	if xyd.tables.avatar:isActive(arg_9_1) then
		var_9_3 = xyd.createEffect(xyd.tables.avatar:iconJson(arg_9_1))

		var_9_3:play(nil, true)
	else
		var_9_3 = xyd.SpriteLoader.new(var_9_0, nil, nil, xyd.DefaultImageType.AVATAR)
	end

	local var_9_4 = arg_9_2:getContentSize()

	var_9_3 = var_9_3 or xyd.AssetLoader.get():loadSprite("windows/common/common_avatar.png")

	local var_9_5 = xyd.AssetLoader:get():loadSprite("windows/common/avatar_mask.png")
	local var_9_6 = cc.ClippingNode:create()

	var_9_6:setStencil(var_9_5)
	var_9_6:setInverted(false)
	var_9_6:setAlphaThreshold(0)
	var_9_6:addChild(var_9_3)
	var_9_3:align(display.CENTER, var_9_4.width / 2, var_9_4.height / 2)

	if not xyd.tables.avatar:isActive(arg_9_1) then
		var_9_3:scale(var_9_4.width / var_9_3:getWidth())
	else
		var_9_3:scale(var_9_4.width / xyd.AvatarWidth)
	end

	var_9_5:addTo(arg_9_2, -1)
	var_9_5:align(display.CENTER, var_9_4.width / 2, var_9_4.height / 2)
	var_9_5:scale((var_9_4.width - 3) / var_9_5:getWidth())
	arg_9_2:addChild(var_9_6)

	if var_9_1 < 0 then
		local var_9_7 = xyd.getAvatarBorder(xyd.EquipQuality.ORANGE)
		local var_9_8 = clone(var_9_7:getContentSize())

		xyd.displaySpriteOnContainer(var_9_7, arg_9_2, true)
		var_9_7:setName("border")

		if var_9_1 == -1 then
			local var_9_9 = xyd.getAvatarBorder(0)

			xyd.displaySpriteOnContainer(var_9_9, arg_9_2, true)
			var_9_9:scale(var_9_4.width / var_9_9:getWidth() + 0.04)
		end

		if var_9_1 == -3 then
			local var_9_10 = xyd.getAvatarBorder(nil, nil, nil, nil, true)

			xyd.displaySpriteOnContainer(var_9_10, arg_9_2, true)
			var_9_10:scale(var_9_4.width / var_9_10:getWidth() + 0.04)
		end
	else
		local var_9_11 = xyd.getAvatarBorder(var_9_1)
		local var_9_12 = clone(var_9_11:getContentSize())

		xyd.displaySpriteOnContainer(var_9_11, arg_9_2, true)
		var_9_11:setName("border")
	end
end

function var_0_0.didOpen(arg_10_0, arg_10_1)
	var_0_0.super:didOpen(arg_10_1)
	arg_10_0:addBlockLayer()
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RIGHT_PULL
	})
end

function var_0_0.buttonHandler(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	if arg_11_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_11_2)
		arg_11_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound("sound/button.ogg", false)

		if arg_11_1 then
			arg_11_1(arg_11_2, arg_11_3)
		end
	elseif arg_11_3 == ccui.TouchEventType.began then
		return true
	elseif arg_11_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_11_2)
		arg_11_2:setScale(1)
	end
end

function var_0_0.returnCallBack(arg_12_0)
	xyd.WindowManager.get():closeWindow("player_info")
end

function var_0_0.willClose(arg_13_0, arg_13_1)
	if arg_13_0.countDown then
		arg_13_0.countDown:stop()
	end

	if arg_13_0.callback then
		local var_13_0 = {
			avatar_id = arg_13_0.selfPlayer:getMyCurrentAvatarID(),
			avatar_frame_id = arg_13_0.selfPlayer.avatarFrame,
			title_info = arg_13_0.selfPlayer.titleInfo
		}

		arg_13_0.callback(var_13_0)
	end

	arg_13_0.changeAvatar_:setAvatarOrder(arg_13_0.changeAvatar_.avatarOrder)
end

function var_0_0.updateListView(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0
	local var_14_1 = arg_14_0.listView_:dequeueItem()

	if not var_14_1 then
		var_14_1 = arg_14_0.listView_:newItem()
	else
		var_14_1:removeAllChildren(true)
	end

	local var_14_2 = 720
	local var_14_3 = 140

	var_14_1:setItemSize(var_14_2, var_14_3)

	local var_14_4 = display.newNode()

	var_14_4:setContentSize(var_14_2, var_14_3)

	local var_14_5 = false
	local var_14_6

	for iter_14_0, iter_14_1 in pairs(arg_14_0.titleRows_) do
		if arg_14_2 == iter_14_1 then
			local var_14_7 = {
				"BASE_AVATAR",
				"HERO_AVATAR",
				"TAITAN_AVATAR",
				"AWAKEN_AVATAR",
				"SPECIL_AVATAR"
			}
			local var_14_8 = {
				"",
				"HERO_AVATAR_ALERT",
				"TAITAN_AVATAR_ALERT",
				"AWAKEN_AVATAR_ALERT",
				""
			}
			local var_14_9 = xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/playerwindow/newtouxiangTitle.csb")

			var_14_9:setContentSize(600, 60)
			var_14_9:setTouchEnabled(true)
			var_14_9:setTouchSwallowEnabled(false)

			local var_14_10 = 70
			local var_14_11 = var_14_8[iter_14_0]
			local var_14_12 = var_14_7[iter_14_0]

			if #var_14_11 > 0 then
				var_14_9:getChildByName("container"):getChildByName("txt_tip"):setString(var_0_1:translation(var_14_11))
				var_14_9:getChildByName("container"):getChildByName("txt_tip"):setVisible(true)
				var_14_9:getChildByName("container"):getChildByName("txt_tip"):setPosition(var_14_9:getChildByName("container"):getChildByName("txt_tip"):getX(), var_14_9:getChildByName("container"):getChildByName("txt_tip"):getY() - 15)

				var_14_10 = 90
			end

			var_14_9:getChildByName("container"):getChildByName("btn_avatar"):setVisible(true)
			var_14_9:getChildByName("container"):getChildByName("btn_avatar_select"):setVisible(false)
			var_14_9:getChildByName("container"):getChildByName("txt_type"):setString(var_0_1:translation(var_14_12) .. "(" .. arg_14_0.avatarTypeNums[iter_14_0] .. ")")

			if arg_14_0.changeAvatar_.avatarOrder[iter_14_0] == 1 then
				var_14_9:getChildByName("container"):getChildByName("img_down"):setVisible(true)
				var_14_9:getChildByName("container"):getChildByName("img_up"):setVisible(false)
				var_14_9:getChildByName("container"):getChildByName("btn_avatar"):setVisible(false)
				var_14_9:getChildByName("container"):getChildByName("btn_avatar_select"):setVisible(true)
				var_14_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
					if arg_15_0.name == "began" then
						var_14_9:getChildByName("container"):getChildByName("btn_avatar"):setVisible(false)
						var_14_9:getChildByName("container"):getChildByName("btn_avatar_select"):setVisible(true)

						return true
					elseif arg_15_0.name == "ended" and not arg_14_0.scrollViewMoved_ then
						arg_14_0.changeAvatar_.avatarOrder[iter_14_0] = 0

						arg_14_0:updateList()

						local var_15_0 = cc.p(arg_14_0.listView_:getScrollNode():getPosition())

						arg_14_0.listView_:reload()
						arg_14_0.listView_:scrollTo(var_15_0.x, var_15_0.y)
					end
				end)
			else
				var_14_9:getChildByName("container"):getChildByName("img_down"):setVisible(false)
				var_14_9:getChildByName("container"):getChildByName("img_up"):setVisible(true)
				var_14_9:getChildByName("container"):getChildByName("btn_avatar"):setVisible(true)
				var_14_9:getChildByName("container"):getChildByName("btn_avatar_select"):setVisible(false)
				var_14_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
					if arg_16_0.name == "began" then
						var_14_9:getChildByName("container"):getChildByName("btn_avatar"):setVisible(false)
						var_14_9:getChildByName("container"):getChildByName("btn_avatar_select"):setVisible(true)

						return true
					elseif arg_16_0.name == "ended" and not arg_14_0.scrollViewMoved_ then
						arg_14_0.changeAvatar_.avatarOrder[iter_14_0] = 1

						arg_14_0:updateList()

						local var_16_0 = cc.p(arg_14_0.listView_:getScrollNode():getPosition())

						arg_14_0.listView_:reload()
						arg_14_0.listView_:scrollTo(var_16_0.x, var_16_0.y)
					end
				end)
			end

			var_14_4:addChild(var_14_9)
			var_14_9:setPosition(70, var_14_10 - 70)
			var_14_9:setAnchorPoint(cc.p(0, 0))
			var_14_4:setContentSize(700, var_14_10)
			var_14_1:setItemSize(700, var_14_10)

			var_14_5 = true

			break
		elseif arg_14_2 < iter_14_1 then
			var_14_6 = iter_14_0 - 1

			break
		end
	end

	var_14_6 = var_14_6 or 5

	if not var_14_5 then
		local var_14_13 = {
			1,
			xyd.EquipQuality.PURPLE,
			-3,
			-1,
			-2
		}
		local var_14_14 = arg_14_0.avatars_[var_14_6]
		local var_14_15 = arg_14_2

		for iter_14_2 = var_14_6 - 1, 1, -1 do
			var_14_15 = var_14_15 - 1 - math.ceil(#arg_14_0.avatars_[iter_14_2] / 5)
		end

		local var_14_16 = var_14_15 - 1
		local var_14_17 = 0

		for iter_14_3 = 4, 0, -1 do
			local var_14_18 = var_14_16 * 5 - iter_14_3

			if var_14_18 <= #var_14_14 and var_14_18 > 0 then
				local var_14_19 = var_14_13[var_14_6]
				local var_14_20 = var_14_14[var_14_18]
				local var_14_21 = display.newNode()

				var_14_21:setContentSize(120, 120)
				arg_14_0:setAvatar(xyd.tables.avatar.icon_[var_14_20], var_14_21, var_14_19)

				if var_14_6 == 5 and var_14_18 >= arg_14_0.lock_index_ then
					local var_14_22 = cc.Sprite:create("windows/person_display/person_main/icon_lock.png")

					var_14_21:addChild(var_14_22)
					var_14_22:setPosition(110, 105)
				end

				if arg_14_0.timingAvatar[var_14_20] then
					local var_14_23 = {
						size = 18,
						color = cc.c3b(255, 255, 255)
					}
					local var_14_24 = xyd.AssetLoader.get():loadLabel(var_14_23)

					var_14_24:addTo(var_14_21)
					var_14_24:setAnchorPoint(cc.p(0.5, 0.5))
					var_14_24:setPosition(var_14_21:getWidth() / 2, var_14_21:getHeight() / 6)
					var_14_24:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
					var_14_24:enableOutline(cc.c4b(11, 11, 11, 255), 1)

					local var_14_25 = arg_14_0.timingAvatar[var_14_20].startTime + xyd.tables.avatar:getAvatarTime(var_14_20) * 24 * 3600 - xyd.ServerTime.get():getServerTime()

					;(function(arg_17_0)
						if arg_17_0 <= 0 then
							arg_14_0.selfPlayer:getBackpack():removeItem(arg_14_0.timingAvatar[var_14_20])

							arg_14_0.scrollNodePosX = arg_14_0.listView_:getScrollNode():getPositionX()
							arg_14_0.scrollNodePosY = arg_14_0.listView_:getScrollNode():getPositionY()

							arg_14_0:updateList()
							arg_14_0.listView_:reload()

							if arg_14_0.countDown then
								arg_14_0.countDown:stop()

								arg_14_0.countDown = nil
							end

							return
						end

						local var_17_0 = math.ceil(arg_17_0 / 24 / 3600)
						local var_17_1 = math.ceil(arg_17_0 % 86400 / 3600)
						local var_17_2 = math.ceil(arg_17_0 % 86400 % 3600 / 60)
						local var_17_3 = math.ceil(arg_17_0 % 86400 % 3600 % 60)

						if arg_17_0 >= 86400 then
							var_14_24:setString(string.format(var_0_1:translation("AVATAR_LEFT_TIME_DAY"), var_17_0))
						elseif arg_17_0 < 86400 and arg_17_0 >= 3600 then
							var_14_24:setString(string.format(var_0_1:translation("AVATAR_LEFT_TIME_HOUR"), var_17_1))
						elseif arg_17_0 < 3600 and arg_17_0 >= 60 then
							var_14_24:setString(string.format(var_0_1:translation("AVATAR_LEFT_TIME_MINUTE"), var_17_2))
						else
							var_14_24:setString(string.format(var_0_1:translation("AVATAR_LEFT_TIME_SECOND"), var_17_3))
						end
					end)(var_14_25)
				end

				var_14_21:setTouchEnabled(true)
				var_14_21:setTouchSwallowEnabled(false)
				var_14_21:setAnchorPoint(cc.p(0.5, 0.5))

				local var_14_26 = xyd.tables.avatar.icon_[var_14_14[var_14_18]]

				var_14_21:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
					if arg_18_0.name == "began" then
						var_14_21:setScale(0.95)

						return true
					elseif arg_18_0.name == "ended" then
						var_14_21:setScale(1)

						if not arg_14_0.scrollViewMoved_ then
							if var_14_6 == 5 and var_14_18 >= arg_14_0.lock_index_ then
								if xyd.tables.avatar.value1_[var_14_14[var_14_18]] == 0 then
									xyd.WindowManager.get():openWindow("toast", {
										message = xyd.tables.avatar.description_[var_14_14[var_14_18]]
									})
								else
									xyd.WindowManager.get():openWindow("avatar_detail_window", {
										ID = var_14_14[var_14_18],
										color = var_14_19
									})
								end
							else
								local var_18_0 = {
									table_id = var_14_14[var_14_18],
									avatar_id = var_14_26,
									avatar_type = var_14_6
								}

								arg_14_0.changeAvatar_:changeAvatar(var_18_0, function(arg_19_0, arg_19_1)
									if arg_19_0 == xyd.error.OK then
										xyd.Backend.get():enterChatRoom(arg_14_0.selfPlayer.region)
										xyd.Backend.get():enterServiceChatRoom(99999)

										if arg_14_0.selfPlayer.guildID and arg_14_0.selfPlayer.guildID ~= 0 then
											xyd.Backend.get():enterLeagueRoom(arg_14_0.selfPlayer.guildID)
										end

										arg_14_0.selfPlayer.avatarId = var_14_26

										xyd.WindowManager.get():closeWindow(arg_14_0)
										xyd.EventDispatcher.get():dispatchEvent({
											name = xyd.event.REFRESH_AVATAR
										})
									end
								end)
							end
						end
					elseif arg_18_0.name == "moved" then
						var_14_21:setScale(1)

						return true
					end
				end)
				var_14_4:addChild(var_14_21)
				var_14_21:setPosition(var_14_17 * 133 + 105, 60)

				var_14_17 = var_14_17 + 1
			end
		end
	end

	var_14_1:addContent(var_14_4)

	return var_14_1
end

function var_0_0.sourceDelegate(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	if cc.ui.UIListView.COUNT_TAG == arg_20_2 then
		local var_20_0 = 5

		for iter_20_0, iter_20_1 in ipairs(arg_20_0.avatars_) do
			var_20_0 = var_20_0 + math.ceil(#iter_20_1 / 5)
		end

		return var_20_0
	elseif cc.ui.UIListView.CELL_TAG == arg_20_2 then
		return arg_20_0:updateListView(arg_20_2, arg_20_3)
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_20_2 then
		-- block empty
	end
end

function var_0_0.initLeftMenu(arg_21_0)
	arg_21_0:nodeByName("txt_change_avatar"):setString(var_0_6.AVATAR)
	arg_21_0:nodeByName("txt_change_frame"):setString(var_0_6.FRAME)
	arg_21_0:nodeByName("txt_change_title"):setString(var_0_6.TITLE)

	if arg_21_0.leftMenuType == var_0_4.AVATAR then
		arg_21_0:nodeByName("btn_change_avatar"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_21_0:nodeByName("btn_change_frame"):setBrightStyle(ccui.BrightStyle.normal)
		arg_21_0:nodeByName("btn_change_title"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_21_0.leftMenuType == var_0_4.TITLE then
		arg_21_0:nodeByName("btn_change_avatar"):setBrightStyle(ccui.BrightStyle.normal)
		arg_21_0:nodeByName("btn_change_frame"):setBrightStyle(ccui.BrightStyle.normal)
		arg_21_0:nodeByName("btn_change_title"):setBrightStyle(ccui.BrightStyle.highlight)
	else
		arg_21_0:nodeByName("btn_change_avatar"):setBrightStyle(ccui.BrightStyle.normal)
		arg_21_0:nodeByName("btn_change_frame"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_21_0:nodeByName("btn_change_title"):setBrightStyle(ccui.BrightStyle.normal)
	end

	arg_21_0:nodeByName("btn_change_avatar"):addTouchEventListener(function(arg_22_0, arg_22_1)
		if arg_22_1 == ccui.TouchEventType.ended and arg_21_0.leftMenuType ~= var_0_4.AVATAR then
			xyd.playTabButtonSound()
			arg_21_0:nodeByName("btn_change_avatar"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_21_0:nodeByName("btn_change_frame"):setBrightStyle(ccui.BrightStyle.normal)
			arg_21_0:nodeByName("btn_change_title"):setBrightStyle(ccui.BrightStyle.normal)

			arg_21_0.leftMenuType = var_0_4.AVATAR

			arg_21_0:changeListView()
		end
	end)
	arg_21_0:nodeByName("btn_change_frame"):addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.ended and arg_21_0.leftMenuType ~= var_0_4.AVATAR_FRAME then
			xyd.playTabButtonSound()
			arg_21_0:nodeByName("btn_change_frame"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_21_0:nodeByName("btn_change_avatar"):setBrightStyle(ccui.BrightStyle.normal)
			arg_21_0:nodeByName("btn_change_title"):setBrightStyle(ccui.BrightStyle.normal)

			arg_21_0.leftMenuType = var_0_4.AVATAR_FRAME

			arg_21_0:changeListView()
		end
	end)
	arg_21_0:nodeByName("btn_change_title"):addTouchEventListener(function(arg_24_0, arg_24_1)
		if arg_24_1 == ccui.TouchEventType.ended and arg_21_0.leftMenuType ~= var_0_4.TITLE then
			xyd.playTabButtonSound()
			arg_21_0:nodeByName("btn_change_title"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_21_0:nodeByName("btn_change_avatar"):setBrightStyle(ccui.BrightStyle.normal)
			arg_21_0:nodeByName("btn_change_frame"):setBrightStyle(ccui.BrightStyle.normal)

			if arg_21_0.titleFlag == 1 then
				arg_21_0:loadTitleInfo()

				arg_21_0.titleFlag = 0
			end

			arg_21_0.leftMenuType = var_0_4.TITLE

			if arg_21_0.titleFlag == 0 then
				arg_21_0:changeListView()
			end
		end
	end)
end

function var_0_0.changeListView(arg_25_0)
	if arg_25_0.leftMenuType == var_0_4.TITLE then
		arg_25_0.listView_:setVisible(false)
		arg_25_0.frameListView_:setVisible(false)
		arg_25_0.titleListView_:setVisible(true)
		arg_25_0:updateTitleList()
	elseif arg_25_0.leftMenuType == var_0_4.AVATAR_FRAME then
		arg_25_0.listView_:setVisible(false)
		arg_25_0.titleListView_:setVisible(false)
		arg_25_0.frameListView_:setVisible(true)
		arg_25_0:updateFrameList()
	else
		arg_25_0.listView_:setVisible(true)
		arg_25_0.titleListView_:setVisible(false)
		arg_25_0.frameListView_:setVisible(false)
		arg_25_0:updateList()
		arg_25_0.listView_:reload()
	end
end

function var_0_0.frameDelegate(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	if cc.ui.UIListView.COUNT_TAG == arg_26_2 then
		local var_26_0 = 4

		for iter_26_0, iter_26_1 in ipairs(arg_26_0.avatars_) do
			var_26_0 = var_26_0 + math.ceil(#iter_26_1 / 5)
		end

		return var_26_0
	elseif cc.ui.UIListView.CELL_TAG == arg_26_2 then
		return arg_26_0:updateListView(arg_26_2, arg_26_3)
	end
end

function var_0_0.setTitleTitle(arg_27_0, arg_27_1)
	local var_27_0 = arg_27_0.titleListView_:newItem()
	local var_27_1 = display.newNode()
	local var_27_2 = import("app.windows.NewAvatarTypeTitle").new()
	local var_27_3 = {}
	local var_27_4 = 70

	var_27_3.title = var_0_1:translation(arg_27_1)

	var_27_2:setParams(var_27_3)
	var_27_1:addChild(var_27_2)
	var_27_2:setPosition(15, var_27_4 - 70)
	var_27_2:setAnchorPoint(cc.p(0, 0.5))
	var_27_1:setContentSize(700, var_27_4)
	var_27_0:addContent(var_27_1)
	var_27_0:setItemSize(700, var_27_4)
	arg_27_0.titleListView_:addItem(var_27_0)
end

function var_0_0.setTitle(arg_28_0, arg_28_1, arg_28_2)
	local var_28_0 = arg_28_0.frameListView_:newItem()
	local var_28_1 = display.newNode()
	local var_28_2 = import("app.windows.NewAvatarTypeTitle").new()

	params = {}

	local var_28_3 = 70

	if arg_28_2 then
		params.tip = var_0_1:translation(arg_28_2)
		var_28_3 = 90
	end

	params.title = var_0_1:translation(arg_28_1)

	var_28_2:setParams(params)
	var_28_1:addChild(var_28_2)
	var_28_2:setPosition(15, var_28_3 - 70)
	var_28_2:setAnchorPoint(cc.p(0, 0.5))
	var_28_1:setContentSize(700, var_28_3)
	var_28_0:addContent(var_28_1)
	var_28_0:setItemSize(700, var_28_3)
	arg_28_0.frameListView_:addItem(var_28_0)
end

function var_0_0.updateTitleList(arg_29_0)
	arg_29_0.titleListView_:removeAllItems()

	local var_29_0 = arg_29_0.titleInfo
	local var_29_1 = {}

	table.sort(var_29_0, function(arg_30_0, arg_30_1)
		if arg_30_0.unique_id ~= 0 and arg_30_1.unique_id ~= 0 then
			return arg_30_0.unique_id < arg_30_1.unique_id
		end

		if arg_30_0.title_id == arg_30_1.title_id then
			return arg_30_0.end_time < arg_30_1.end_time
		end

		return arg_30_0.title_id < arg_30_1.title_id
	end)

	local var_29_2 = xyd.tables.titleSystemTable:getIDs()
	local var_29_3 = {}

	for iter_29_0, iter_29_1 in pairs(var_29_2) do
		var_29_3[iter_29_1] = {}
		var_29_3[iter_29_1].title_id = 0
	end

	for iter_29_2, iter_29_3 in pairs(var_29_0) do
		if var_29_3[iter_29_3.title_id] then
			var_29_3[iter_29_3.title_id].title_id = iter_29_3.title_id
		end
	end

	for iter_29_4, iter_29_5 in pairs(var_29_2) do
		if var_29_3[iter_29_5].title_id == 0 then
			local var_29_4 = {
				title_id = iter_29_5
			}

			table.insert(var_29_1, var_29_4)
		end
	end

	if var_29_0 and next(var_29_0) then
		arg_29_0:setTitleTitle("UNLOCK_TITLE")
		arg_29_0:setListTitles(var_29_0)
	end

	arg_29_0:setTitleTitle("LOCK_TITLE")
	arg_29_0:setListTitles(var_29_1, true)
	arg_29_0.titleListView_:reload()
end

function var_0_0.setListTitles(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0 = 2
	local var_31_1 = math.ceil(#arg_31_1 / var_31_0)

	for iter_31_0 = 1, var_31_1 do
		local var_31_2 = arg_31_0.titleListView_:newItem()

		for iter_31_1 = 1, var_31_0 do
			local var_31_3 = display.newNode()

			var_31_3:setContentSize(720, 120)

			local var_31_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/person_main/list_title.csb")
			local var_31_5 = var_31_4:getChildByName("container")
			local var_31_6 = var_31_5:getContentSize()

			var_31_2:setItemSize(720, var_31_6.height + 10)
			var_31_4:setPosition(720 / var_31_0 * iter_31_1 - 720 / var_31_0 / 2 - var_31_5:getContentSize().width / 2, 0)
			var_31_3:addChild(var_31_4)

			local var_31_7 = arg_31_1[(iter_31_0 - 1) * var_31_0 + iter_31_1]

			if not var_31_7 then
				break
			end

			local var_31_8

			if xyd.tables.titleSystemTable:isDynamic(var_31_7.title_id) ~= 1 then
				local var_31_9 = xyd.tables.titleSystemTable:bg(var_31_7.title_id)

				var_31_8 = xyd.AssetLoader:get():loadSprite(var_31_9)

				var_31_8:setAnchorPoint(0, 0)
				var_31_8:addTo(var_31_5:getChildByName("bg"), -1)
			else
				local var_31_10 = xyd.tables.titleSystemTable:dynamicPath(var_31_7.title_id)
				local var_31_11 = xyd.EffectLoader.new(var_31_10, 6)

				var_31_11:addTo(var_31_5:getChildByName("bg"), -1)

				local var_31_12 = var_31_5:getChildByName("bg"):getContentSize()

				var_31_11:pos(var_31_12.width / 2, var_31_12.height / 2)

				var_31_8 = display.newNode()

				var_31_8:setContentSize(var_31_12)
				var_31_8:setAnchorPoint(0, 0)
				var_31_8:addTo(var_31_5:getChildByName("bg"), -1)
			end

			if arg_31_2 and arg_31_2 == true then
				var_31_5:getChildByName("img_lock"):setVisible(true)
				var_31_5:getChildByName("bg_time_out"):setVisible(false)

				if xyd.tables.titleSystemTable:type(var_31_7.title_id) == 3 then
					var_31_5:getChildByName("bg"):getChildByName("img_txt"):setVisible(true)

					local var_31_13 = xyd.AssetLoader:get():loadSprite("images/title_system/unknown.png")

					var_31_13:setAnchorPoint(0.5, 0.5)
					var_31_13:addTo(var_31_5:getChildByName("bg"):getChildByName("img_txt"))
					var_31_5:getChildByName("txt_name"):setString(xyd.tables.titleSystemTable:name(var_31_7.title_id))
				elseif xyd.tables.titleSystemTable:type(var_31_7.title_id) == 1 then
					var_31_5:getChildByName("bg"):getChildByName("img_txt"):setVisible(true)

					local var_31_14 = xyd.AssetLoader:get():loadSprite("images/title_system/unknown.png")

					var_31_14:setAnchorPoint(0.5, 0.5)
					var_31_14:addTo(var_31_5:getChildByName("bg"):getChildByName("img_txt"))
					var_31_5:getChildByName("txt_name"):setString(var_0_1:translation("TITLE_SYSTEM_TIPS_1"))
				else
					var_31_5:getChildByName("bg"):getChildByName("img_txt"):setVisible(false)
					var_31_5:getChildByName("txt_name"):setString(xyd.tables.titleSystemTable:name(var_31_7.title_id))
				end
			else
				var_31_5:getChildByName("img_lock"):setVisible(false)
				var_31_5:getChildByName("bg_time_out"):setVisible(false)

				if xyd.tables.titleSystemTable:type(var_31_7.title_id) == 3 then
					var_31_5:getChildByName("bg"):getChildByName("img_txt"):setVisible(true)

					local var_31_15 = xyd.tables.titleSystemTable:textImg(var_31_7.title_id)
					local var_31_16 = xyd.AssetLoader:get():loadSprite(var_31_15 .. var_31_7.unique_id .. ".png")

					var_31_16:setAnchorPoint(0.5, 0.5)
					var_31_16:addTo(var_31_5:getChildByName("bg"):getChildByName("img_txt"))

					local var_31_17 = xyd.tables.hero:name(var_31_7.unique_id)

					var_31_5:getChildByName("txt_name"):setString(xyd.tables.titleSystemTable:name(var_31_7.title_id) .. var_31_17)
				elseif xyd.tables.titleSystemTable:type(var_31_7.title_id) == 1 then
					var_31_5:getChildByName("bg"):getChildByName("img_txt"):setVisible(true)

					local var_31_18 = xyd.tables.titleSystemTable:textImg(var_31_7.title_id)
					local var_31_19 = xyd.AssetLoader:get():loadSprite(var_31_18 .. var_31_7.unique_id .. ".png")

					var_31_19:setAnchorPoint(0.5, 0.5)
					var_31_19:addTo(var_31_5:getChildByName("bg"):getChildByName("img_txt"))

					local var_31_20 = xyd.tables.hero:name(var_31_7.unique_id)

					var_31_5:getChildByName("txt_name"):setString(xyd.tables.titleSystemTable:name(var_31_7.title_id) .. var_31_20)
				else
					var_31_5:getChildByName("bg"):getChildByName("img_txt"):setVisible(false)
					var_31_5:getChildByName("txt_name"):setString(xyd.tables.titleSystemTable:name(var_31_7.title_id))
				end

				if var_31_7.end_time > 0 then
					var_31_5:getChildByName("bg_time_out"):setVisible(true)

					local var_31_21 = var_31_7.end_time - xyd.ServerTime.get():getServerTime()
					local var_31_22 = var_31_5:getChildByName("bg_time_out"):getChildByName("txt_time")

					;(function(arg_32_0)
						if arg_32_0 <= 0 then
							arg_31_0:loadTitleInfo()
							arg_31_0:updateTitleList()

							return
						end

						local var_32_0 = math.ceil(arg_32_0 / 24 / 3600)
						local var_32_1 = math.ceil(arg_32_0 % 86400 / 3600)
						local var_32_2 = math.ceil(arg_32_0 % 86400 % 3600 / 60)
						local var_32_3 = math.ceil(arg_32_0 % 86400 % 3600 % 60)

						if arg_32_0 >= 86400 then
							var_31_22:setString(string.format(var_0_1:translation("AVATAR_LEFT_TIME_DAY"), var_32_0))
						elseif arg_32_0 < 86400 and arg_32_0 >= 3600 then
							var_31_22:setString(string.format(var_0_1:translation("AVATAR_LEFT_TIME_HOUR"), var_32_1))
						elseif arg_32_0 < 3600 and arg_32_0 >= 60 then
							var_31_22:setString(string.format(var_0_1:translation("AVATAR_LEFT_TIME_MINUTE"), var_32_2))
						else
							var_31_22:setString(string.format(var_0_1:translation("AVATAR_LEFT_TIME_SECOND"), var_32_3))
						end
					end)(var_31_21)
				end
			end

			var_31_8:setTouchEnabled(true)
			var_31_8:setTouchSwallowEnabled(false)
			var_31_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_33_0)
				if arg_33_0.name == "began" then
					var_31_5:getChildByName("bg"):setScale(0.95)

					return true
				elseif arg_33_0.name == "ended" then
					var_31_5:getChildByName("bg"):setScale(1)

					if not arg_31_0.scrollViewMoved_ then
						if arg_31_2 and arg_31_2 == true then
							xyd.WindowManager.get():openWindow("toast", {
								message = xyd.tables.titleSystemTable:desc(var_31_7.title_id)
							})
						else
							local var_33_0 = {
								title_id = var_31_7.title_id,
								unique_id = var_31_7.unique_id
							}

							xyd.Backend.get():request(xyd.mid.CHANGE_TITLE, var_33_0, function(arg_34_0, arg_34_1)
								if arg_34_0 == xyd.error.OK then
									local var_34_0 = arg_34_1.title_info

									arg_31_0.selfPlayer:changeTitleInfo(var_34_0)
									xyd.Backend.get():enterChatRoom(arg_31_0.selfPlayer.region)
									xyd.Backend.get():enterServiceChatRoom(99999)

									if arg_31_0.selfPlayer.guildID and arg_31_0.selfPlayer.guildID ~= 0 then
										xyd.Backend.get():enterLeagueRoom(arg_31_0.selfPlayer.guildID)
									end

									xyd.WindowManager.get():closeWindow(arg_31_0)
								end
							end)
						end
					end
				elseif arg_33_0.name == "moved" then
					var_31_5:getChildByName("bg"):setScale(1)

					return true
				end
			end)
			var_31_2:addContent(var_31_3)
		end

		arg_31_0.titleListView_:addItem(var_31_2)
	end
end

function var_0_0.updateFrameList(arg_35_0)
	arg_35_0.frameListView_:removeAllItems()

	local var_35_0 = {}
	local var_35_1 = {}

	arg_35_0.timingAvatarFrame = {}

	local var_35_2 = arg_35_0.selfPlayer:getBackpack():getItemsByTypes({
		xyd.ItemType.AVATAR_FRAME
	})

	for iter_35_0, iter_35_1 in pairs(xyd.tables.avatar.avatar_frame) do
		if xyd.tables.avatar.type_[iter_35_1] <= 3 then
			table.insert(var_35_0, iter_35_1)
		else
			local var_35_3 = false
			local var_35_4 = xyd.tables.avatar.type_[iter_35_1]
			local var_35_5 = xyd.tables.avatar.vip_level_[iter_35_1]

			if var_35_4 == 6 and var_35_5 <= arg_35_0.selfPlayer.vip then
				var_35_3 = true

				table.insert(var_35_0, iter_35_1)
			end

			for iter_35_2, iter_35_3 in pairs(var_35_2) do
				if iter_35_3.itemID == iter_35_1 then
					if iter_35_3.startTime and xyd.tables.avatar:getAvatarTime(iter_35_3.itemID) > 0 then
						if iter_35_3.startTime + xyd.tables.avatar:getAvatarTime(iter_35_3.itemID) * 24 * 3600 > xyd.ServerTime.get():getServerTime() then
							var_35_3 = true

							table.insert(var_35_0, iter_35_1)

							arg_35_0.timingAvatarFrame[iter_35_3.itemID] = iter_35_3
						end

						break
					end

					var_35_3 = true

					table.insert(var_35_0, iter_35_1)

					break
				end
			end

			if var_35_3 == false and xyd.tables.avatar.is_show_[iter_35_1] == 1 then
				table.insert(var_35_1, iter_35_1)
			end
		end
	end

	arg_35_0:setTitle("UNLOCK_AVATAR_FRAME")
	arg_35_0:setListAvatars(var_35_0)
	arg_35_0:setTitle("LOCK_AVATAR_FRAME")
	arg_35_0:setListAvatars(var_35_1, true)
	arg_35_0.frameListView_:reload()
end

function var_0_0.setListAvatars(arg_36_0, arg_36_1, arg_36_2)
	local var_36_0 = 3
	local var_36_1 = math.ceil(#arg_36_1 / var_36_0)

	for iter_36_0 = 1, var_36_1 do
		local var_36_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/playerwindow/frame_item.csb")
		local var_36_3 = var_36_2:getChildByName("container")
		local var_36_4 = arg_36_0.frameListView_:newItem()

		for iter_36_1 = 1, var_36_0 do
			local var_36_5 = arg_36_1[(iter_36_0 - 1) * var_36_0 + iter_36_1]

			if not var_36_5 then
				break
			end

			local var_36_6 = var_36_3:getChildByName("icon_frame_" .. iter_36_1)

			var_36_6:setTouchEnabled(true)
			var_36_6:setTouchSwallowEnabled(false)
			var_36_6:getChildByName("txt_name"):setString(xyd.tables.avatar.name_[var_36_5])
			arg_36_0:setAvatarFrame(var_36_5, var_36_6)

			if arg_36_2 and arg_36_2 == true then
				local var_36_7 = cc.Sprite:create("windows/person_display/person_main/icon_lock.png")

				var_36_6:addChild(var_36_7)
				var_36_7:setPosition(40, -40)
			end

			if arg_36_0.timingAvatarFrame[var_36_5] then
				local var_36_8 = {
					size = 18,
					color = cc.c3b(255, 255, 255)
				}
				local var_36_9 = xyd.AssetLoader.get():loadLabel(var_36_8)

				var_36_9:addTo(var_36_6)
				var_36_9:setAnchorPoint(cc.p(0.5, 0.5))
				var_36_9:setPosition(0, -10)
				var_36_9:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
				var_36_9:enableOutline(cc.c4b(11, 11, 11, 255), 1)

				local var_36_10 = arg_36_0.timingAvatarFrame[var_36_5].startTime + xyd.tables.avatar:getAvatarTime(var_36_5) * 24 * 3600 - xyd.ServerTime.get():getServerTime()

				;(function(arg_37_0)
					if arg_37_0 <= 0 then
						arg_36_0.selfPlayer:getBackpack():removeItem(arg_36_0.timingAvatarFrame[var_36_5])
						arg_36_0:updateFrameList()

						return
					end

					local var_37_0 = math.ceil(arg_37_0 / 24 / 3600)
					local var_37_1 = math.ceil(arg_37_0 % 86400 / 3600)
					local var_37_2 = math.ceil(arg_37_0 % 86400 % 3600 / 60)
					local var_37_3 = math.ceil(arg_37_0 % 86400 % 3600 % 60)

					if arg_37_0 >= 86400 then
						var_36_9:setString(string.format(var_0_1:translation("AVATAR_LEFT_TIME_DAY"), var_37_0))
					elseif arg_37_0 < 86400 and arg_37_0 >= 3600 then
						var_36_9:setString(string.format(var_0_1:translation("AVATAR_LEFT_TIME_HOUR"), var_37_1))
					elseif arg_37_0 < 3600 and arg_37_0 >= 60 then
						var_36_9:setString(string.format(var_0_1:translation("AVATAR_LEFT_TIME_MINUTE"), var_37_2))
					else
						var_36_9:setString(string.format(var_0_1:translation("AVATAR_LEFT_TIME_SECOND"), var_37_3))
					end
				end)(var_36_10)
			end

			local var_36_11 = xyd.tables.avatar.icon_[var_36_5]

			var_36_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_38_0)
				if arg_38_0.name == "began" then
					var_36_6:setScale(0.95)

					return true
				elseif arg_38_0.name == "ended" then
					var_36_6:setScale(1)

					if not arg_36_0.scrollViewMoved_ then
						if arg_36_2 and arg_36_2 == true then
							if xyd.tables.avatar.value1_[var_36_5] == 0 then
								xyd.WindowManager.get():openWindow("toast", {
									message = xyd.tables.avatar.description_[var_36_5]
								})
							else
								xyd.WindowManager.get():openWindow("avatar_detail_window", {
									isFrame = true,
									ID = var_36_5
								})
							end
						else
							local var_38_0 = {
								avatar_frame_id = var_36_5
							}

							arg_36_0.changeAvatar_:editAvatarFrame(var_38_0, function(arg_39_0)
								if arg_39_0 == xyd.error.OK then
									xyd.Backend.get():enterChatRoom(arg_36_0.selfPlayer.region)
									xyd.Backend.get():enterServiceChatRoom(99999)

									if arg_36_0.selfPlayer.guildID and arg_36_0.selfPlayer.guildID ~= 0 then
										xyd.Backend.get():enterLeagueRoom(arg_36_0.selfPlayer.guildID)
									end

									arg_36_0.selfPlayer.avatarFrame = var_36_5

									xyd.WindowManager.get():closeWindow(arg_36_0)
									xyd.EventDispatcher.get():dispatchEvent({
										name = xyd.event.REFRESH_AVATAR
									})
								end
							end)
						end
					end
				elseif arg_38_0.name == "moved" then
					var_36_6:setScale(1)

					return true
				end
			end)
		end

		local var_36_12 = var_36_3:getContentSize()

		var_36_2:setContentSize(var_36_12.width, var_36_12.height)
		var_36_4:setItemSize(var_36_12.width, var_36_12.height)
		var_36_4:addContent(var_36_2)
		arg_36_0.frameListView_:addItem(var_36_4)
	end
end

function var_0_0.setAvatarFrame(arg_40_0, arg_40_1, arg_40_2)
	local var_40_0 = "images/avatar_frames/" .. arg_40_1 .. ".png"
	local var_40_1 = xyd.SpriteLoader.new(var_40_0, nil, nil, xyd.DefaultImageType.AVATAR_FRAME) or xyd.AssetLoader.get():loadSprite("images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png")

	arg_40_2:addChild(var_40_1)
end

return var_0_0
