local var_0_0 = class("TeamCreateIconWindow", import("app.common.ui.BaseWindow"))

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.avatar = {}
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
		viewRect = cc.rect(0, 0, arg_3_0:nodeByName("list_container"):getWidth(), arg_3_0:nodeByName("list_container"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list_container")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.listView_:setBounceable(true)
	arg_3_0:init()
end

function var_0_0.init(arg_4_0)
	local var_4_0 = xyd.tables.translation
	local var_4_1 = arg_4_0.listView_:newItem()
	local var_4_2 = display.newNode()
	local var_4_3 = import("app.windows.AvatarTypeTitle").new()
	local var_4_4 = {
		title = var_4_0:translation("TEAM_ICON_TITLE")
	}

	var_4_3:setParams(var_4_4)
	var_4_2:addChild(var_4_3)
	var_4_3:setPosition(15, 0)
	var_4_3:setAnchorPoint(cc.p(0, 1))
	var_4_2:setContentSize(700, 50)
	var_4_1:addContent(var_4_2)
	var_4_1:setItemSize(700, 50)
	arg_4_0.listView_:addItem(var_4_1)

	arg_4_0.avatar = xyd.tables.misc.teamIcons

	local var_4_5 = math.ceil(#arg_4_0.avatar / 5)

	for iter_4_0 = 1, var_4_5 do
		local var_4_6 = display.newNode()
		local var_4_7 = arg_4_0.listView_:newItem()

		for iter_4_1 = 1, 5 do
			local var_4_8 = (iter_4_0 - 1) * 5 + iter_4_1

			if var_4_8 > #arg_4_0.avatar then
				break
			end

			local var_4_9 = display.newNode()

			var_4_9:setContentSize(120, 120)
			xyd.setTeamBorder(arg_4_0.avatar[var_4_8], var_4_9, 2)
			var_4_9:setTouchEnabled(true)
			var_4_9:setTouchSwallowEnabled(false)
			var_4_9:setAnchorPoint(cc.p(0.5, 0.5))
			var_4_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
				if arg_5_0.name == "began" then
					var_4_9:setScale(0.95)

					return true
				elseif arg_5_0.name == "ended" then
					var_4_9:setScale(1)

					if not arg_4_0.scrollViewMoved_ then
						xyd.playButtonSound()
						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.TEAM_ICON_REFRESH,
							params = arg_4_0.avatar[var_4_8]
						})
						xyd.WindowManager.get():closeWindow("team_create_icon")
					end
				elseif arg_5_0.name == "moved" then
					var_4_9:setScale(1)

					return true
				end
			end)
			var_4_6:addChild(var_4_9)
			var_4_9:setPosition(iter_4_1 * 153 - 70, 60)
		end

		var_4_6:setContentSize(780, 140)
		var_4_7:setItemSize(780, 140)
		var_4_7:addContent(var_4_6)
		arg_4_0.listView_:addItem(var_4_7)
	end

	arg_4_0.listView_:reload()
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
	arg_6_0:addBlockLayer()
end

function var_0_0.buttonHandler(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if arg_7_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_7_2)
		arg_7_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound("sound/button.ogg", false)

		if arg_7_1 then
			arg_7_1(arg_7_2, arg_7_3)
		end
	elseif arg_7_3 == ccui.TouchEventType.began then
		return true
	elseif arg_7_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_7_2)
		arg_7_2:setScale(1)
	end
end

function var_0_0.returnCallBack(arg_8_0)
	xyd.WindowManager.get():closeWindow("player_info")
end

return var_0_0
