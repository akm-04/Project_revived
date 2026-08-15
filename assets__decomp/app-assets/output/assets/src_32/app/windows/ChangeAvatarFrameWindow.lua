local var_0_0 = class("ChangeAvatarFrameWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

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
		viewRect = cc.rect(0, 0, 780, 560),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.listView_:setBounceable(true)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.UPDATE_AVATAR_LIST, function(arg_4_0)
		arg_3_0:updateList()
	end)
	arg_3_0:updateList()
end

function var_0_0.setTitle(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_0.listView_:newItem()
	local var_5_1 = display.newNode()
	local var_5_2 = import("app.windows.AvatarTypeTitle").new()

	params = {}

	local var_5_3 = 70

	if arg_5_2 then
		params.tip = var_0_1:translation(arg_5_2)
		var_5_3 = 90
	end

	params.title = var_0_1:translation(arg_5_1)

	var_5_2:setParams(params)
	var_5_1:addChild(var_5_2)
	var_5_2:setPosition(15, var_5_3 - 70)
	var_5_2:setAnchorPoint(cc.p(0, 0.5))
	var_5_1:setContentSize(700, var_5_3)
	var_5_0:addContent(var_5_1)
	var_5_0:setItemSize(700, var_5_3)
	arg_5_0.listView_:addItem(var_5_0)
end

function var_0_0.updateList(arg_6_0)
	arg_6_0.listView_:removeAllItems()

	local var_6_0 = {}
	local var_6_1 = {}
	local var_6_2 = arg_6_0.selfPlayer:getBackpack():getItemsByTypes({
		xyd.ItemType.AVATAR_FRAME
	})

	for iter_6_0, iter_6_1 in pairs(xyd.tables.avatar.avatar_frame) do
		if xyd.tables.avatar.type_[iter_6_1] <= 3 then
			table.insert(var_6_0, iter_6_1)
		else
			local var_6_3 = false
			local var_6_4 = xyd.tables.avatar.type_[iter_6_1]
			local var_6_5 = xyd.tables.avatar.vip_level_[iter_6_1]

			if var_6_4 == 6 and var_6_5 <= arg_6_0.selfPlayer.vip then
				var_6_3 = true

				table.insert(var_6_0, iter_6_1)
			end

			for iter_6_2, iter_6_3 in pairs(var_6_2) do
				if iter_6_3.itemID == iter_6_1 then
					var_6_3 = true

					table.insert(var_6_0, iter_6_1)

					break
				end
			end

			if var_6_3 == false and xyd.tables.avatar.is_show_[iter_6_1] == 1 then
				table.insert(var_6_1, iter_6_1)
			end
		end
	end

	arg_6_0:setTitle("UNLOCK_AVATAR_FRAME")
	arg_6_0:setListAvatars(var_6_0)
	arg_6_0:setTitle("LOCK_AVATAR_FRAME")
	arg_6_0:setListAvatars(var_6_1, true)
	arg_6_0.listView_:reload()
end

function var_0_0.setListAvatars(arg_7_0, arg_7_1, arg_7_2)
	for iter_7_0, iter_7_1 in pairs(arg_7_1) do
		local var_7_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/playerwindow/frame_item.csb")
		local var_7_1 = var_7_0:getChildByName("container")
		local var_7_2 = arg_7_0.listView_:newItem()
		local var_7_3 = var_7_1:getChildByName("frame_icon")

		var_7_3:setTouchEnabled(true)
		var_7_3:setTouchSwallowEnabled(false)
		var_7_1:getChildByName("name_text"):setString(xyd.tables.avatar.name_[iter_7_1])
		arg_7_0:setAvatar(iter_7_1, var_7_3)

		if arg_7_2 and arg_7_2 == true then
			local var_7_4 = cc.Sprite:create("windows/playerwindow/locked.png")

			var_7_3:addChild(var_7_4)
			var_7_4:setPosition(40, -40)
		end

		local var_7_5 = xyd.tables.avatar.icon_[iter_7_1]

		var_7_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
			if arg_8_0.name == "began" then
				var_7_3:setScale(0.95)

				return true
			elseif arg_8_0.name == "ended" then
				var_7_3:setScale(1)

				if not arg_7_0.scrollViewMoved_ then
					if arg_7_2 and arg_7_2 == true then
						if xyd.tables.avatar.value1_[iter_7_1] == 0 then
							xyd.WindowManager.get():openWindow("toast", {
								message = xyd.tables.avatar.description_[iter_7_1]
							})
						else
							xyd.WindowManager.get():openWindow("avatar_detail_window", {
								isFrame = true,
								ID = iter_7_1
							})
						end
					else
						local var_8_0 = {
							avatar_frame_id = iter_7_1
						}

						arg_7_0.changeAvatar_:editAvatarFrame(var_8_0, function(arg_9_0)
							if arg_9_0 == xyd.error.OK then
								xyd.Backend.get():enterChatRoom(arg_7_0.selfPlayer.region)
								xyd.Backend.get():enterServiceChatRoom(99999)

								if arg_7_0.selfPlayer.guildID and arg_7_0.selfPlayer.guildID ~= 0 then
									xyd.Backend.get():enterLeagueRoom(arg_7_0.selfPlayer.guildID)
								end

								arg_7_0.selfPlayer.avatarFrame = iter_7_1

								xyd.WindowManager.get():closeWindow(arg_7_0)
								xyd.EventDispatcher.get():dispatchEvent({
									name = xyd.event.REFRESH_AVATAR
								})
							end
						end)
					end
				end
			elseif arg_8_0.name == "moved" then
				var_7_3:setScale(1)

				return true
			end
		end)

		local var_7_6 = display.newNode()

		var_7_6:addChild(var_7_0)
		var_7_6:setContentSize(780, 150)
		var_7_2:setItemSize(780, 150)
		var_7_2:addContent(var_7_6)
		arg_7_0.listView_:addItem(var_7_2)
	end
end

function var_0_0.setAvatar(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = "images/avatar_frames/" .. arg_10_1 .. ".png"
	local var_10_1 = xyd.AssetLoader.get():loadSprite(var_10_0) or xyd.AssetLoader.get():loadSprite("images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png")

	arg_10_2:addChild(var_10_1)
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	var_0_0.super:didOpen(arg_11_1)
	arg_11_0:addBlockLayer()
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RIGHT_PULL
	})
end

function var_0_0.buttonHandler(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	if arg_12_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_12_2)
		arg_12_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound("sound/button.ogg", false)

		if arg_12_1 then
			arg_12_1(arg_12_2, arg_12_3)
		end
	elseif arg_12_3 == ccui.TouchEventType.began then
		return true
	elseif arg_12_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_12_2)
		arg_12_2:setScale(1)
	end
end

function var_0_0.returnCallBack(arg_13_0)
	xyd.WindowManager.get():closeWindow("player_info")
end

return var_0_0
