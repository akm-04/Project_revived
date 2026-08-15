local var_0_0 = class("ChangeAvatarWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	110006002,
	110007026,
	110007027,
	110007043,
	110007049
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.changeAvatar_ = xyd.ModelManager.get():loadModel(xyd.ModelType.CHANGE_AVATAR)
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
	var_0_0.super:willOpen(arg_3_1)

	arg_3_0.listView_ = cc.ui.UIListView.new({
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, 780, 560),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.listView_:setDelegate(handler(arg_3_0, arg_3_0.sourceDelegate))
	arg_3_0.listView_:setBounceable(true)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.UPDATE_AVATAR_LIST, function(arg_4_0)
		arg_3_0:updateList()
		arg_3_0.listView_:reload()
	end)
	arg_3_0:updateList()
	arg_3_0.listView_:reload()
end

function var_0_0.updateList(arg_5_0)
	arg_5_0.titleRows_ = {}
	arg_5_0.timingAvatar = {}
	arg_5_0.avatars_ = {}

	local var_5_0 = 1

	table.insert(arg_5_0.titleRows_, var_5_0)
	table.insert(arg_5_0.avatars_, xyd.tables.avatar.base_avatar)

	local var_5_1 = var_5_0 + math.ceil(#xyd.tables.avatar.base_avatar / 5) + 1

	table.insert(arg_5_0.titleRows_, var_5_1)

	local var_5_2 = {}
	local var_5_3 = {}
	local var_5_4 = 0
	local var_5_5 = 0

	for iter_5_0, iter_5_1 in pairs(arg_5_0.selfPlayer.heros_) do
		if iter_5_1.color_ >= xyd.EquipQuality.PURPLE and xyd.tables.avatar.hero_avatar[iter_5_1.tableID_] ~= nil then
			table.insert(var_5_2, xyd.tables.avatar.hero_avatar[iter_5_1.tableID_])

			var_5_4 = var_5_4 + 1
		end

		if iter_5_1:isAwaken() then
			if xyd.tables.avatar.awaken_avatar[iter_5_1.tableID_] ~= nil then
				table.insert(var_5_3, xyd.tables.avatar.awaken_avatar[iter_5_1.tableID_])

				var_5_5 = var_5_5 + 1
			end

			local var_5_6 = iter_5_1:beforeAwakenID()

			table.insert(var_5_2, xyd.tables.avatar.hero_avatar[var_5_6])

			var_5_4 = var_5_4 + 1
		end
	end

	table.insert(arg_5_0.avatars_, var_5_2)

	local var_5_7 = var_5_1 + math.ceil(var_5_4 / 5) + 1

	table.insert(arg_5_0.titleRows_, var_5_7)
	table.insert(arg_5_0.avatars_, var_5_3)

	local var_5_8 = var_5_7 + math.ceil(var_5_5 / 5) + 1

	table.insert(arg_5_0.titleRows_, var_5_8)

	local var_5_9 = {}
	local var_5_10 = {}
	local var_5_11 = {}

	for iter_5_2, iter_5_3 in pairs(xyd.tables.avatar.specil_avatar) do
		local var_5_12 = false

		if xyd.tables.avatar.type_[iter_5_3] == 7 then
			for iter_5_4, iter_5_5 in pairs(arg_5_0.selfPlayer.heros_) do
				if iter_5_5.skinId_ == xyd.tables.avatar.partner_id_[iter_5_3] and iter_5_5.hasSkin_ == 1 then
					var_5_12 = true

					table.insert(var_5_11, iter_5_3)

					break
				end
			end
		end

		for iter_5_6, iter_5_7 in pairs(arg_5_0.selfPlayer:getBackpack():getItemsByTypes({
			xyd.ItemType.AVATAR
		})) do
			if iter_5_7.itemID == iter_5_3 then
				if iter_5_7.startTime and xyd.tables.avatar:getAvatarTime(iter_5_7.itemID) > 0 and iter_5_7.startTime + xyd.tables.avatar:getAvatarTime(iter_5_7.itemID) * 24 * 3600 > xyd.ServerTime.get():getServerTime() then
					arg_5_0.timingAvatar[iter_5_7.itemID] = iter_5_7
					var_5_12 = true

					table.insert(var_5_11, iter_5_3)

					break
				end

				if not iter_5_7.startTime or xyd.tables.avatar:getAvatarTime(iter_5_7.itemID) == -1 then
					var_5_12 = true

					table.insert(var_5_11, iter_5_3)
				end

				break
			end
		end

		if xyd.tables.avatar.type_[iter_5_3] == 11 then
			function swimsuitComplete()
				local var_6_0 = true

				for iter_6_0, iter_6_1 in ipairs(var_0_2) do
					local var_6_1 = false

					if iter_6_0 > 1 and var_6_0 then
						for iter_6_2, iter_6_3 in pairs(arg_5_0.selfPlayer.heros_) do
							if iter_6_3.skinId_ == xyd.tables.avatar.partner_id_[iter_6_1] and iter_6_3.hasSkin_ == 1 then
								var_6_1 = true

								break
							end
						end

						var_6_0 = var_6_1
					end
				end

				return var_6_0
			end

			if iter_5_3 == var_0_2[1] and swimsuitComplete() then
				table.insert(var_5_11, iter_5_3)

				var_5_12 = true
			end
		end

		if var_5_12 == false and xyd.tables.avatar.is_show_[iter_5_3] == 1 then
			table.insert(var_5_10, iter_5_3)
		end
	end

	local var_5_13 = var_5_11

	arg_5_0.lock_index_ = #var_5_11 + 1

	for iter_5_8, iter_5_9 in pairs(var_5_10) do
		table.insert(var_5_13, iter_5_9)
	end

	table.insert(arg_5_0.avatars_, var_5_13)

	if arg_5_0.scrollNodePosX and arg_5_0.scrollNodePosY then
		arg_5_0.listView_:getScrollNode():setPosition(arg_5_0.scrollNodePosX, arg_5_0.scrollNodePosY)
	end
end

function var_0_0.setAvatar(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = "images/avatars/" .. arg_7_1 .. ".png"
	local var_7_1 = arg_7_3
	local var_7_2
	local var_7_3 = xyd.AssetLoader.get():loadSprite(var_7_0)
	local var_7_4 = arg_7_2:getContentSize()

	var_7_3 = var_7_3 or xyd.AssetLoader.get():loadSprite("windows/common/common_avatar.png")

	local var_7_5 = xyd.AssetLoader:get():loadSprite("windows/common/avatar_mask.png")
	local var_7_6 = cc.ClippingNode:create()

	var_7_6:setStencil(var_7_5)
	var_7_6:setInverted(false)
	var_7_6:setAlphaThreshold(0)
	var_7_6:addChild(var_7_3)
	var_7_3:align(display.CENTER, var_7_4.width / 2, var_7_4.height / 2)
	var_7_3:scale(var_7_4.width / var_7_3:getWidth())
	var_7_5:addTo(arg_7_2, -1)
	var_7_5:align(display.CENTER, var_7_4.width / 2, var_7_4.height / 2)
	var_7_5:scale((var_7_4.width - 3) / var_7_5:getWidth())
	arg_7_2:addChild(var_7_6)

	if var_7_1 < 0 then
		local var_7_7 = xyd.getAvatarBorder(xyd.EquipQuality.ORANGE)
		local var_7_8 = clone(var_7_7:getContentSize())

		xyd.displaySpriteOnContainer(var_7_7, arg_7_2, true)
		var_7_7:setName("border")

		if var_7_1 == -1 then
			local var_7_9 = xyd.getAvatarBorder(0)

			xyd.displaySpriteOnContainer(var_7_9, arg_7_2, true)
			var_7_9:scale(var_7_4.width / var_7_9:getWidth() + 0.04)
		end
	else
		local var_7_10 = xyd.getAvatarBorder(var_7_1)
		local var_7_11 = clone(var_7_10:getContentSize())

		xyd.displaySpriteOnContainer(var_7_10, arg_7_2, true)
		var_7_10:setName("border")
	end
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super:didOpen(arg_8_1)
	arg_8_0:addBlockLayer()
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RIGHT_PULL
	})
end

function var_0_0.buttonHandler(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if arg_9_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_9_2)
		arg_9_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound("sound/button.ogg", false)

		if arg_9_1 then
			arg_9_1(arg_9_2, arg_9_3)
		end
	elseif arg_9_3 == ccui.TouchEventType.began then
		return true
	elseif arg_9_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_9_2)
		arg_9_2:setScale(1)
	end
end

function var_0_0.returnCallBack(arg_10_0)
	xyd.WindowManager.get():closeWindow("player_info")
end

function var_0_0.willClose(arg_11_0, arg_11_1)
	if arg_11_0.countDown then
		arg_11_0.countDown:stop()
	end
end

function var_0_0.updateListView(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0
	local var_12_1 = arg_12_0.listView_:dequeueItem()

	if not var_12_1 then
		var_12_1 = arg_12_0.listView_:newItem()
	else
		var_12_1:removeAllChildren(true)
	end

	local var_12_2 = 780
	local var_12_3 = 140

	var_12_1:setItemSize(var_12_2, var_12_3)

	local var_12_4 = display.newNode()

	var_12_4:setContentSize(var_12_2, var_12_3)

	local var_12_5 = false
	local var_12_6

	for iter_12_0, iter_12_1 in pairs(arg_12_0.titleRows_) do
		if arg_12_2 == iter_12_1 then
			local var_12_7 = {
				"BASE_AVATAR",
				"HERO_AVATAR",
				"AWAKEN_AVATAR",
				"SPECIL_AVATAR"
			}
			local var_12_8 = {
				"",
				"HERO_AVATAR_ALERT",
				"AWAKEN_AVATAR_ALERT",
				""
			}
			local var_12_9 = import("app.windows.AvatarTypeTitle").new()
			local var_12_10 = {}
			local var_12_11 = 70
			local var_12_12 = var_12_8[iter_12_0]
			local var_12_13 = var_12_7[iter_12_0]

			if #var_12_12 > 0 then
				var_12_10.tip = var_0_1:translation(var_12_12)
				var_12_11 = 90
			end

			var_12_10.title = var_0_1:translation(var_12_13)

			var_12_9:setParams(var_12_10)
			var_12_4:addChild(var_12_9)
			var_12_9:setPosition(45, var_12_11 - 70)
			var_12_9:setAnchorPoint(cc.p(0, 0.5))
			var_12_4:setContentSize(700, var_12_11)
			var_12_1:setItemSize(700, var_12_11)

			var_12_5 = true

			break
		elseif arg_12_2 < iter_12_1 then
			var_12_6 = iter_12_0 - 1

			break
		end
	end

	var_12_6 = var_12_6 or 4

	if not var_12_5 then
		local var_12_14 = {
			1,
			xyd.EquipQuality.PURPLE,
			-1,
			-2
		}
		local var_12_15 = arg_12_0.avatars_[var_12_6]
		local var_12_16 = arg_12_2

		for iter_12_2 = var_12_6 - 1, 1, -1 do
			var_12_16 = var_12_16 - 1 - math.ceil(#arg_12_0.avatars_[iter_12_2] / 5)
		end

		local var_12_17 = var_12_16 - 1
		local var_12_18 = 0

		for iter_12_3 = 4, 0, -1 do
			local var_12_19 = var_12_17 * 5 - iter_12_3

			if var_12_19 <= #var_12_15 and var_12_19 > 0 then
				local var_12_20 = var_12_14[var_12_6]
				local var_12_21 = var_12_15[var_12_19]
				local var_12_22 = display.newNode()

				var_12_22:setContentSize(120, 120)
				arg_12_0:setAvatar(xyd.tables.avatar.icon_[var_12_21], var_12_22, var_12_20)

				if var_12_6 == 4 and var_12_19 >= arg_12_0.lock_index_ then
					local var_12_23 = cc.Sprite:create("windows/playerwindow/locked.png")

					var_12_22:addChild(var_12_23)
					var_12_23:setPosition(110, 105)
				end

				if arg_12_0.timingAvatar[var_12_21] then
					local var_12_24 = {
						size = 18,
						color = cc.c3b(255, 255, 255)
					}
					local var_12_25 = xyd.AssetLoader.get():loadLabel(var_12_24)

					var_12_25:addTo(var_12_22)
					var_12_25:setAnchorPoint(cc.p(0.5, 0.5))
					var_12_25:setPosition(var_12_22:getWidth() / 2, var_12_22:getHeight() / 6)
					var_12_25:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
					var_12_25:enableOutline(cc.c4b(11, 11, 11, 255), 1)

					local var_12_26 = arg_12_0.timingAvatar[var_12_21].startTime + xyd.tables.avatar:getAvatarTime(var_12_21) * 24 * 3600 - xyd.ServerTime.get():getServerTime()

					;(function(arg_13_0)
						if arg_13_0 <= 0 then
							arg_12_0.selfPlayer:getBackpack():removeItem(arg_12_0.timingAvatar[var_12_21])

							arg_12_0.scrollNodePosX = arg_12_0.listView_:getScrollNode():getPositionX()
							arg_12_0.scrollNodePosY = arg_12_0.listView_:getScrollNode():getPositionY()

							arg_12_0:updateList()
							arg_12_0.listView_:reload()

							if arg_12_0.countDown then
								arg_12_0.countDown:stop()

								arg_12_0.countDown = nil
							end

							return
						end

						local var_13_0 = math.ceil(arg_13_0 / 24 / 3600)
						local var_13_1 = math.ceil(arg_13_0 % 86400 / 3600)
						local var_13_2 = math.ceil(arg_13_0 % 86400 % 3600 / 60)
						local var_13_3 = math.ceil(arg_13_0 % 86400 % 3600 % 60)

						if arg_13_0 >= 86400 then
							var_12_25:setString(string.format(var_0_1:translation("AVATAR_LEFT_TIME_DAY"), var_13_0))
						elseif arg_13_0 < 86400 and arg_13_0 >= 3600 then
							var_12_25:setString(string.format(var_0_1:translation("AVATAR_LEFT_TIME_HOUR"), var_13_1))
						elseif arg_13_0 < 3600 and arg_13_0 >= 60 then
							var_12_25:setString(string.format(var_0_1:translation("AVATAR_LEFT_TIME_MINUTE"), var_13_2))
						else
							var_12_25:setString(string.format(var_0_1:translation("AVATAR_LEFT_TIME_SECOND"), var_13_3))
						end
					end)(var_12_26)
				end

				var_12_22:setTouchEnabled(true)
				var_12_22:setTouchSwallowEnabled(false)
				var_12_22:setAnchorPoint(cc.p(0.5, 0.5))

				local var_12_27 = xyd.tables.avatar.icon_[var_12_15[var_12_19]]

				var_12_22:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
					if arg_14_0.name == "began" then
						var_12_22:setScale(0.95)

						return true
					elseif arg_14_0.name == "ended" then
						var_12_22:setScale(1)

						if not arg_12_0.scrollViewMoved_ then
							if var_12_6 == 4 and var_12_19 >= arg_12_0.lock_index_ then
								if xyd.tables.avatar.value1_[var_12_15[var_12_19]] == 0 then
									xyd.WindowManager.get():openWindow("toast", {
										message = xyd.tables.avatar.description_[var_12_15[var_12_19]]
									})
								else
									xyd.WindowManager.get():openWindow("avatar_detail_window", {
										ID = var_12_15[var_12_19],
										color = var_12_20
									})
								end
							else
								local var_14_0 = {
									avatar_id = var_12_27
								}

								arg_12_0.changeAvatar_:changeAvatar(var_14_0, function(arg_15_0, arg_15_1)
									if arg_15_0 == xyd.error.OK then
										xyd.Backend.get():enterChatRoom(arg_12_0.selfPlayer.region)
										xyd.Backend.get():enterServiceChatRoom(99999)

										if arg_12_0.selfPlayer.guildID and arg_12_0.selfPlayer.guildID ~= 0 then
											xyd.Backend.get():enterLeagueRoom(arg_12_0.selfPlayer.guildID)
										end

										arg_12_0.selfPlayer.avatarId = var_12_27

										xyd.WindowManager.get():closeWindow("change_avatar")
										xyd.EventDispatcher.get():dispatchEvent({
											name = xyd.event.REFRESH_AVATAR
										})
									end
								end)
							end
						end
					elseif arg_14_0.name == "moved" then
						var_12_22:setScale(1)

						return true
					end
				end)
				var_12_4:addChild(var_12_22)
				var_12_22:setPosition(var_12_18 * 153 + 83, 60)

				var_12_18 = var_12_18 + 1
			end
		end
	end

	var_12_1:addContent(var_12_4)

	return var_12_1
end

function var_0_0.sourceDelegate(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	if cc.ui.UIListView.COUNT_TAG == arg_16_2 then
		local var_16_0 = 4

		for iter_16_0, iter_16_1 in ipairs(arg_16_0.avatars_) do
			var_16_0 = var_16_0 + math.ceil(#iter_16_1 / 5)
		end

		return var_16_0
	elseif cc.ui.UIListView.CELL_TAG == arg_16_2 then
		return arg_16_0:updateListView(arg_16_2, arg_16_3)
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_16_2 then
		-- block empty
	end
end

return var_0_0
