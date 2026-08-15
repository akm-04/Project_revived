local var_0_0 = class("RegionWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.WindowName.regionWnd
local var_0_2 = xyd.tables.translation
local var_0_3 = 8

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.regions = arg_2_1.userRegions.regions
	arg_2_0.players = arg_2_1.userRegions.players
	arg_2_0.lastLogin = arg_2_1.lastLogin
	arg_2_0.recommendRegion = arg_2_1.recommendRegion
	arg_2_0.recallRegions = arg_2_1.userRegions.recall_regions
	arg_2_0.leftSelected = -1
	arg_2_0.itemButtons = {}

	table.sort(arg_2_0.players, function(arg_3_0, arg_3_1)
		return arg_3_0.lev > arg_3_1.lev
	end)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:addBlockLayer()
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("title"):setString(var_0_2:translation("REGION_LIST"))
	arg_5_0:nodeByName("title"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	arg_5_0.left_container = arg_5_0:nodeByName("left_container")

	local var_5_0 = arg_5_0.left_container:getContentSize()

	arg_5_0.leftList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_5_0.width, var_5_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_5_0.left_container):onScroll(handler(arg_5_0, arg_5_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0)
	arg_5_0.main_container = arg_5_0:nodeByName("main_container")

	local var_5_1 = arg_5_0.main_container:getContentSize()

	arg_5_0.mainList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_5_1.width, var_5_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_5_0.main_container):onScroll(handler(arg_5_0, arg_5_0.scrollListener)):setTouchType(true):pos(0, 0)

	arg_5_0:updateListView()

	local var_5_2 = arg_5_0:nodeByName("last_login_panel")

	var_5_2:getChildByName("last_title"):setString(var_0_2:translation("REGION_LAST_LOGIN_TXT"))

	if arg_5_0.lastLogin then
		arg_5_0:initSpecilServer(var_5_2, arg_5_0.lastLogin, 2)
	end

	local var_5_3 = arg_5_0:nodeByName("new_server_panel")

	var_5_3:getChildByName("new_title"):setString(var_0_2:translation("REGION_NEW_SERVER_TXT"))

	if arg_5_0.recommendRegion then
		arg_5_0:initSpecilServer(var_5_3, arg_5_0.recommendRegion, 1)
	end
end

function var_0_0.updateListView(arg_6_0)
	arg_6_0.leftList_:removeAllItems()

	local var_6_0 = 0
	local var_6_1 = {}

	arg_6_0.region_map = {}

	for iter_6_0, iter_6_1 in pairs(arg_6_0.regions) do
		if iter_6_1.region_id then
			table.insert(var_6_1, iter_6_1.region_id)

			arg_6_0.region_map[iter_6_1.region_id] = iter_6_1
		end
	end

	table.sort(var_6_1)

	local var_6_2 = math.ceil(#var_6_1 / var_0_3)

	arg_6_0.itemButtons = {}

	for iter_6_2 = var_6_2 + 2, 1, -1 do
		local var_6_3 = arg_6_0.leftList_:newItem()
		local var_6_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/login/region_left_item.csb")
		local var_6_5 = var_6_4:getChildByName("container")
		local var_6_6 = {}
		local var_6_7 = var_0_2:translation("REGION_SUOYOUJUESE")
		local var_6_8 = 0
		local var_6_9 = false

		if iter_6_2 <= var_6_2 then
			local var_6_10 = (iter_6_2 - 1) * var_0_3 + 1
			local var_6_11 = iter_6_2 * var_0_3

			if var_6_11 > #var_6_1 then
				var_6_11 = #var_6_1
			end

			for iter_6_3 = var_6_10, var_6_11 do
				table.insert(var_6_6, var_6_1[iter_6_3])
			end

			var_6_7 = string.format(var_0_2:translation("REGION_QU_2"), tonumber(var_6_1[var_6_10]), tonumber(var_6_1[var_6_11]))

			var_6_5:getChildByName("text"):setString(var_6_7)

			var_6_8 = iter_6_2
		elseif iter_6_2 == var_6_2 + 2 then
			var_6_5:getChildByName("text"):setString(var_0_2:translation("REGION_SUOYOUJUESE"))
		else
			var_6_7 = var_0_2:translation("RECALL_SERVER")

			var_6_5:getChildByName("text"):setString(var_6_7)

			var_6_8 = iter_6_2
			var_6_6 = arg_6_0.recallRegions
			var_6_9 = true
		end

		if next(var_6_6) or iter_6_2 == var_6_2 + 2 then
			local var_6_12 = var_6_5:getChildByName("button")
			local var_6_13 = {
				row = var_6_8,
				cell_ids = var_6_6,
				label = var_6_7,
				isRecallArea = var_6_9
			}

			if arg_6_0.leftSelected == iter_6_2 or arg_6_0.leftSelected and var_6_8 == 0 then
				var_6_12:setBrightStyle(ccui.BrightStyle.highlight)
				arg_6_0:updateMainContainer(var_6_13)
			else
				var_6_12:setBrightStyle(ccui.BrightStyle.normal)
			end

			table.insert(arg_6_0.itemButtons, var_6_12)

			local var_6_14 = var_6_5:getContentSize()

			var_6_4:setPosition(cc.p(0, 0))
			var_6_4:setContentSize(var_6_14)
			var_6_4:setTouchEnabled(true)
			var_6_4:setTouchSwallowEnabled(false)
			var_6_12:addTouchEventListener(handler(var_6_13, function(arg_7_0, arg_7_1, arg_7_2)
				if arg_7_2 == ccui.TouchEventType.began then
					local var_7_0 = xyd.tables.sound:getSound("ui_button_click")

					audio.playSound(var_7_0, false)

					return true
				elseif arg_7_2 == ccui.TouchEventType.ended then
					if not arg_6_0.scrollViewMoved_ then
						for iter_7_0, iter_7_1 in pairs(arg_6_0.itemButtons) do
							iter_7_1:setBrightStyle(ccui.BrightStyle.normal)
						end

						var_6_12:setBrightStyle(ccui.BrightStyle.highlight)
						arg_6_0:updateMainContainer(arg_7_0)

						return true
					else
						return true
					end
				end

				var_6_12:setBrightStyle(ccui.BrightStyle.highlight)
			end))
			var_6_3:addContent(var_6_4)
			var_6_3:setItemSize(var_6_14.width, var_6_14.height)
			arg_6_0.leftList_:addItem(var_6_3)
		end
	end

	arg_6_0.leftList_:reload()
end

function var_0_0.updateMainContainer(arg_8_0, arg_8_1)
	arg_8_0.mainList_:removeAllItems()

	local var_8_0 = {}

	arg_8_0:nodeByName("main_title"):setString(arg_8_1.label)

	local var_8_1 = arg_8_1.row
	local var_8_2 = arg_8_1.cell_ids
	local var_8_3
	local var_8_4
	local var_8_5
	local var_8_6
	local var_8_7

	if var_8_1 > 0 then
		var_8_3 = 2
		var_8_4 = 12
		var_8_5 = 3
		var_8_6 = "windows/login/region_main_item.csb"
		var_8_7 = #var_8_2

		arg_8_0.mainList_:setViewCanNotScroll(true)
	else
		var_8_3 = 2
		var_8_4 = 12
		var_8_5 = 3
		var_8_6 = "windows/login/player_item.csb"
		var_8_7 = #arg_8_0.players

		arg_8_0.mainList_:setViewCanNotScroll(false)
	end

	for iter_8_0 = 1, math.ceil(var_8_7 / var_8_3) do
		local var_8_8 = display.newNode()
		local var_8_9 = arg_8_0.mainList_:newItem()
		local var_8_10

		for iter_8_1 = 1, var_8_3 do
			local var_8_11 = (iter_8_0 - 1) * var_8_3 + iter_8_1

			if var_8_11 <= var_8_7 then
				var_8_10 = xyd.AssetLoader.get():loadNodeFromJson(var_8_6)

				local var_8_12 = var_8_10:getChildByName("container")

				var_8_12:setTouchSwallowEnabled(false)

				local var_8_13

				if var_8_1 > 0 then
					local var_8_14 = var_8_2[var_8_11]

					var_8_13 = arg_8_0.region_map[var_8_14]

					var_8_12:getChildByName("region_txt"):setString(string.format(var_0_2:translation("REGION_QU_NAME"), var_8_14, var_8_13.name))
					var_8_12:getChildByName("stage_new"):setVisible(false)
					var_8_12:getChildByName("stage_hot"):setVisible(true)
					var_8_12:getChildByName("stage_full"):setVisible(false)

					if arg_8_0.recommendRegion.region_id == var_8_14 then
						var_8_12:getChildByName("stage_new"):setVisible(true)
						var_8_12:getChildByName("stage_hot"):setVisible(false)
						var_8_12:getChildByName("stage_full"):setVisible(false)
					end

					if var_8_13.max_player_id <= var_8_13.cur_id then
						var_8_12:getChildByName("stage_new"):setVisible(false)
						var_8_12:getChildByName("stage_hot"):setVisible(false)
						var_8_12:getChildByName("stage_full"):setVisible(true)
					end
				else
					local var_8_15 = arg_8_0.players[var_8_11]
					local var_8_16 = arg_8_0.players[var_8_11].region

					var_8_13 = arg_8_0.region_map[var_8_16]

					var_8_12:getChildByName("region_text"):setString(string.format(var_0_2:translation("REGION_QU_NAME"), var_8_16, var_8_13.name))

					if var_8_15.vip > 0 then
						var_8_12:getChildByName("vip"):setVisible(true)
						var_8_12:getChildByName("vip_text"):setVisible(true)
						var_8_12:getChildByName("vip_text"):setString(string.format("VIP%d", tonumber(var_8_15.vip)))
						var_8_12:getChildByName("vip_text"):enableOutline(cc.c4b(136, 32, 64, 255), 2)
					else
						var_8_12:getChildByName("vip"):setVisible(false)
						var_8_12:getChildByName("vip_text"):setVisible(false)
					end

					var_8_12:getChildByName("level_text"):setString(string.format("%d", tonumber(var_8_15.lev)))

					if var_8_15.name and #var_8_15.name > 0 then
						var_8_12:getChildByName("name"):setString(string.format("%s", var_8_15.name))
					else
						var_8_12:getChildByName("name"):setString(string.format("%s", var_8_15.id))
					end

					xyd.setPlayerAvatar(var_8_12:getChildByName("avatar_panel"), {
						showLevel = false,
						avatar_id = var_8_15.avatar_id,
						avatar_frame_id = var_8_15.avatar_frame_id
					})

					if var_8_15.conquer_lev > 0 then
						local var_8_17 = xyd.getLoopBy(var_8_15.conquer_lev, var_8_15.conquer_loop_id)

						if var_8_17 < 2 then
							var_8_17 = ""
						end

						var_8_12:getChildByName("dengjiquan"):setTexture("images/conquer_lev" .. var_8_17 .. ".png")
						var_8_12:getChildByName("level_text"):setString(var_8_15.conquer_lev)
					end
				end

				local var_8_18 = var_8_12:getContentSize()

				var_8_10:setPosition(cc.p((iter_8_1 - 1) * (var_8_18.width + var_8_4) + var_8_5, 9))
				var_8_10:setContentSize(var_8_18.width + var_8_4, var_8_18.height)
				var_8_10:setTouchEnabled(true)
				var_8_10:setTouchSwallowEnabled(false)

				local var_8_19 = display.newNode()

				var_8_19:size(var_8_18.width + var_8_4, var_8_18.height)
				var_8_19:addTo(var_8_10)
				var_8_19:pos(0, 0)
				var_8_19:setTouchEnabled(true)
				var_8_19:setTouchSwallowEnabled(false)
				var_8_19:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(var_8_13, function(arg_9_0, arg_9_1)
					if arg_9_1.name == "began" then
						var_8_12:setScale(0.9)

						local var_9_0 = xyd.tables.sound:getSound("ui_button_click")

						return true
					elseif arg_9_1.name == "ended" then
						var_8_12:setScale(1)

						local var_9_1 = var_8_12:getContentSize()
						local var_9_2 = var_8_12:convertToNodeSpace(cc.p(arg_9_1.x, arg_9_1.y))

						if var_9_2.x < 0 or var_9_2.x > var_9_1.width or var_9_2.y < 0 or var_9_2.y > var_9_1.height then
							return
						end

						if not arg_8_0.scrollViewMoved_ then
							if arg_9_0.max_player_id <= arg_9_0.cur_id and not arg_8_0:haveCharactorsInRegion(arg_9_0.region_id) then
								local var_9_3 = var_0_2:translation("REGION_FULL_TEXT")

								xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_3, function()
									xyd.EventDispatcher.get():dispatchEvent({
										name = xyd.event.REGION_SELECTED,
										params = {
											region = arg_8_0.region_map[arg_8_0.recommendRegion.region_id]
										}
									})
									xyd.WindowManager.get():closeWindow(arg_8_0)
								end, nil, nil, arg_8_0.colorMode)
							else
								xyd.WindowManager.get():closeWindow(arg_8_0)
								xyd.EventDispatcher.get():dispatchEvent({
									name = xyd.event.REGION_SELECTED,
									params = {
										region = arg_9_0
									}
								})
							end

							return true
						else
							return true
						end
					end
				end))
				var_8_8:addChild(var_8_10)
			end
		end

		var_8_8:setContentSize(cc.size(arg_8_0.mainList_.viewRect_.width, var_8_10:getContentSize().height + 18))
		var_8_9:addContent(var_8_8)
		var_8_9:setItemSize(arg_8_0.mainList_.viewRect_.width, var_8_8:getContentSize().height)
		arg_8_0.mainList_:addItem(var_8_9)
	end

	arg_8_0.mainList_:reload()
end

function var_0_0.haveCharactorsInRegion(arg_11_0, arg_11_1)
	for iter_11_0, iter_11_1 in ipairs(arg_11_0.players) do
		if iter_11_1.region == arg_11_1 then
			return true
		end
	end

	return false
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevX_ = arg_12_1.x
	elseif arg_12_1.name == "moved" and 1 <= math.abs(arg_12_1.x - arg_12_0.prevX_) then
		arg_12_0.scrollViewMoved_ = true
	end
end

function var_0_0.initSpecilServer(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	if arg_13_2 then
		local var_13_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/login/region_main_item.csb")
		local var_13_1 = var_13_0:getChildByName("container")
		local var_13_2 = arg_13_2.region_id
		local var_13_3 = arg_13_2.name

		var_13_1:getChildByName("region_txt"):setString(string.format(var_0_2:translation("REGION_QU_NAME"), var_13_2, arg_13_2.name))

		local var_13_4 = xyd.tables.serverSelect:image(var_13_2)

		if var_13_4 == nil or var_13_4 == "" then
			local var_13_5 = xyd.tables.serverSelect:image(1)
		end

		var_13_1:getChildByName("stage_new"):setVisible(false)
		var_13_1:getChildByName("stage_hot"):setVisible(false)
		var_13_1:getChildByName("stage_full"):setVisible(false)

		if arg_13_3 == 1 then
			var_13_1:getChildByName("stage_new"):setVisible(true)
		elseif arg_13_3 == 2 then
			var_13_1:getChildByName("stage_hot"):setVisible(true)
		elseif arg_13_3 == 3 then
			var_13_1:getChildByName("stage_full"):setVisible(true)
		end

		if arg_13_0.region_map[arg_13_2.region_id].max_player_id <= arg_13_0.region_map[arg_13_2.region_id].cur_id then
			var_13_1:getChildByName("stage_new"):setVisible(false)
			var_13_1:getChildByName("stage_hot"):setVisible(false)
			var_13_1:getChildByName("stage_full"):setVisible(true)
		end

		var_13_0:setTouchEnabled(true)
		var_13_0:setTouchSwallowEnabled(false)
		var_13_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(arg_13_2, function(arg_14_0, arg_14_1)
			if arg_14_1.name == "began" then
				var_13_1:setScale(0.9)

				local var_14_0 = xyd.tables.sound:getSound("ui_button_click")

				audio.playSound(var_14_0, false)

				return true
			elseif arg_14_1.name == "ended" then
				var_13_1:setScale(1)

				local var_14_1 = var_13_1:getContentSize()
				local var_14_2 = var_13_1:convertToNodeSpace(cc.p(arg_14_1.x, arg_14_1.y))

				if var_14_2.x < 0 or var_14_2.x > var_14_1.width or var_14_2.y < 0 or var_14_2.y > var_14_1.height then
					return
				end

				xyd.WindowManager.get():closeWindow(arg_13_0)
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.REGION_SELECTED,
					params = {
						region = arg_14_0
					}
				})

				return true
			end
		end))
		arg_13_1:getChildByName("server"):addChild(var_13_0)
	else
		arg_13_1:getChildByName("server"):setVisible(false)
	end
end

return var_0_0
