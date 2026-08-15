local var_0_0 = class("ActivityRecallWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.activityRecall
local var_0_5 = xyd.tables.activityRecallGuide

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activity = arg_1_2.activity
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.recallTime = arg_1_0.details.base_info.recall_time

	if arg_1_0.recallTime > 0 then
		arg_1_0.btnType = 1
	else
		arg_1_0.btnType = 2
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:updatData()
	arg_2_0:layout()
end

function var_0_0.updatData(arg_3_0)
	if arg_3_0.btnType == 1 then
		arg_3_0.data = var_0_5:ids()

		if arg_3_0.selfPlayer.lev < 100 then
			table.remove(arg_3_0.data, 3)
		end
	elseif arg_3_0.btnType == 2 then
		if arg_3_0.recallTime > 0 then
			arg_3_0.data = var_0_4:getIds(1)
		else
			arg_3_0.data = var_0_4:getIds(2)
		end

		for iter_3_0 = #arg_3_0.data, 1, -1 do
			if var_0_4:show(arg_3_0.data[iter_3_0]) > arg_3_0.selfPlayer.lev then
				table.remove(arg_3_0.data, iter_3_0)
			end
		end
	elseif arg_3_0.btnType == 3 then
		arg_3_0.data = {
			1,
			2
		}
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0.scroll = arg_4_0:nodeByName("scroll")

	local var_4_0 = arg_4_0.scroll:getContentSize()

	arg_4_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.scrollList:setDelegate(handler(arg_4_0, arg_4_0.scrollListDelegate))
	arg_4_0.scrollList:reload()
	arg_4_0:setButtonClick()
	arg_4_0:updateBtnType()
	arg_4_0:updateCard()
	arg_4_0:nodeByName("down_time_text"):setString(var_0_3:translation("ACTIVITY_OVER_TIME"))
	arg_4_0:createScheduler()
end

function var_0_0.updateCard(arg_5_0, ...)
	local var_5_0 = xyd.tables.skinDynamic
	local var_5_1 = 10001001
	local var_5_2 = var_5_0:path(var_5_1)
	local var_5_3 = var_5_0:homeCardScale(var_5_1)
	local var_5_4 = var_5_0:pos(var_5_1, _type)
	local var_5_5 = xyd.EffectLoader.new(var_5_2, 3, var_5_3, var_5_4)
	local var_5_6 = var_5_1

	var_5_5:addTo(arg_5_0:nodeByName("card_container"))
	var_5_5:setPosition(cc.p(-50, -70))
end

function var_0_0.createScheduler(arg_6_0)
	if arg_6_0.handle then
		var_0_2.unscheduleGlobal(arg_6_0.handle)

		arg_6_0.handle = nil
	end

	local var_6_0 = arg_6_0.activity.end_time - xyd.ServerTime.get():getServerTime()

	arg_6_0:updateTimeText(var_6_0)

	arg_6_0.handle = var_0_2.scheduleGlobal(function()
		local var_7_0 = arg_6_0.activity.end_time - xyd.ServerTime.get():getServerTime()

		if not arg_6_0 or var_7_0 < 0 then
			if arg_6_0.handle then
				var_0_2.unscheduleGlobal(arg_6_0.handle)

				arg_6_0.handle = nil
			end

			return
		end

		arg_6_0:updateTimeText(var_7_0)
	end, 0.1)
end

function var_0_0.updateTimeText(arg_8_0, arg_8_1)
	if arg_8_1 < 0 then
		arg_8_1 = 0
	end

	if arg_8_0 and arg_8_0:nodeByName("down_time_txt") and not tolua.isnull(arg_8_0:nodeByName("down_time_txt")) then
		local var_8_0 = xyd.secondsToString1(arg_8_1, 3)

		arg_8_0:nodeByName("down_time_txt"):setString(var_8_0)
	end
end

function var_0_0.setButtonClick(arg_9_0)
	arg_9_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_10_0 = {}

			var_10_0.title_name = "ACTIVITY_RECALL_RULE_TITLE"
			var_10_0.rule = "ACTIVITY_RECALL_RULE"

			xyd.WindowManager.get():openWindow("new_text_rule", var_10_0)
		end
	end)

	for iter_9_0 = 1, 3 do
		arg_9_0:nodeByName("type_btn" .. iter_9_0):addTouchEventListener(function(arg_11_0, arg_11_1)
			if arg_11_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_11_0 = arg_9_0.btnType

				arg_9_0.btnType = iter_9_0

				if var_11_0 ~= arg_9_0.btnType then
					arg_9_0:updatData()
				end

				arg_9_0:updateBtnType()

				if var_11_0 == arg_9_0.btnType then
					arg_9_0.scrollList:refreshList()
				else
					arg_9_0.scrollList:reload()
				end
			end
		end)
	end

	if arg_9_0.recallTime <= 0 then
		arg_9_0:nodeByName("type_btn1"):setVisible(false)
		arg_9_0:nodeByName("type_btn3"):setVisible(false)
		arg_9_0:nodeByName("type_btn2"):setPositionX(arg_9_0:nodeByName("type_btn1"):getPositionX())
	end
end

function var_0_0.updateBtnType(arg_12_0)
	for iter_12_0 = 1, 3 do
		if iter_12_0 == arg_12_0.btnType then
			arg_12_0:nodeByName("type_btn" .. iter_12_0):setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_12_0:nodeByName("type_btn" .. iter_12_0):setBrightStyle(ccui.BrightStyle.normal)
		end
	end
end

function var_0_0.scrollListDelegate(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	if cc.ui.UIListView.COUNT_TAG == arg_13_2 then
		return #arg_13_0.data
	elseif cc.ui.UIListView.CELL_TAG == arg_13_2 then
		local var_13_0
		local var_13_1 = arg_13_0.scrollList:dequeueItem()

		if not var_13_1 then
			var_13_1 = arg_13_0.scrollList:newItem()
		else
			var_13_1:removeAllChildren(true)
		end

		local var_13_2 = arg_13_0:createListContent(arg_13_0.data[arg_13_3])
		local var_13_3 = var_13_2:getWidth()
		local var_13_4 = var_13_2:getHeight()

		var_13_1:setItemSize(var_13_3, var_13_4 + 10)
		var_13_1:addContent(var_13_2)

		return var_13_1
	end
end

function var_0_0.createListContent(arg_14_0, arg_14_1)
	local var_14_0 = display.newNode()
	local var_14_1 = arg_14_0.details.mission_info
	local var_14_2 = arg_14_0.btnType

	if arg_14_0.btnType == 3 and arg_14_1 == 2 then
		var_14_2 = 4
	end

	local var_14_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/recall/list_item" .. var_14_2 .. ".csb")
	local var_14_4 = var_14_3:getChildByName("container")
	local var_14_5 = arg_14_1

	if var_14_2 == 1 then
		local var_14_6 = var_0_5:bg(var_14_5)
		local var_14_7 = var_0_5:word(var_14_5)
		local var_14_8 = xyd.AssetLoader.get():loadSprite(var_14_6)
		local var_14_9 = xyd.AssetLoader.get():loadSprite(var_14_7)

		var_14_8:addTo(var_14_4:getChildByName("bg_pos"))
		var_14_9:setAnchorPoint(cc.p(1, 0.5))
		var_14_9:addTo(var_14_4:getChildByName("bg_pos"))
		var_14_9:setPosition(cc.p(300, 0))
		var_14_3:setTouchEnabled(true)
		var_14_3:setTouchSwallowEnabled(false)
		var_14_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
			if arg_15_0.name == "began" and not arg_14_0.scrollViewMoved_ then
				return true
			elseif arg_15_0.name == "ended" and not arg_14_0.scrollViewMoved_ then
				xyd.playButtonSound()

				if var_14_5 == 1 then
					local var_15_0 = {}
					local var_15_1 = arg_14_0.selfPlayer:getHeroIgnoreAwaken(10001001)

					var_15_0.heros = {
						var_15_1
					}
					var_15_0.current = 1

					xyd.WindowManager.get():openWindow("hero_main", var_15_0)
				elseif var_14_5 == 2 then
					xyd.WindowManager.get():openWindow("library_bg")
				elseif var_14_5 == 3 then
					xyd.WindowManager.get():openWindow("super_partner")
				end
			end
		end)
	elseif var_14_2 == 2 then
		local var_14_10 = arg_14_1
		local var_14_11 = var_14_4:getChildByName("desc_text")

		var_14_11:setString(var_0_4:desc(var_14_10))
		var_0_1:rewardFormat(var_14_4:getChildByName("award_container"), var_0_4:gift(var_14_10))
		var_14_4:getChildByName("progress_text"):setString(var_0_3:translation("RATE_OF_ADVANCE"))
		var_14_4:getChildByName("recalled_names"):setPositionX(var_14_11:getPositionX() + var_14_11:getContentSize().width + 5)

		local var_14_12 = ""
		local var_14_13 = arg_14_0.details.base_info.player_names or {}

		for iter_14_0 = 1, #var_14_13 do
			var_14_12 = var_14_12 .. "  " .. var_14_13[iter_14_0]
		end

		if var_0_4:req(var_14_10)[1] == 8 then
			var_14_4:getChildByName("recalled_names"):setString(var_14_12)
		else
			var_14_4:getChildByName("recalled_names"):setString("")
		end

		local var_14_14 = var_14_1.counts[var_14_10] or 0
		local var_14_15 = var_14_1.is_awarded[var_14_10] or 0

		var_14_4:getChildByName("progress_txt"):setString(var_14_14 .. "/" .. var_0_4:req(var_14_10)[2])
		var_14_4:getChildByName("already_get"):setVisible(false)

		local var_14_16 = var_14_4:getChildByName("progress_txt"):getPositionX() - var_14_4:getChildByName("progress_txt"):getContentSize().width / 2

		if var_14_16 < var_14_4:getChildByName("progress_text"):getPositionX() then
			var_14_4:getChildByName("progress_text"):setPositionX(var_14_16)
		end

		if var_14_14 < var_0_4:req(var_14_10)[2] then
			var_14_4:getChildByName("get_btn"):setBright(false)
			var_14_4:getChildByName("get_btn"):setTouchEnabled(false)
			xyd.GrayNode(var_14_4:getChildByName("get_btn"):getChildByName("get_text"))
		elseif var_14_15 == 1 then
			var_14_4:getChildByName("get_btn"):setVisible(false)
			var_14_4:getChildByName("already_get"):setVisible(true)
			var_14_4:getChildByName("progress_text"):setVisible(false)
			var_14_4:getChildByName("progress_txt"):setVisible(false)
		end

		var_14_4:getChildByName("get_btn"):addTouchEventListener(function(arg_16_0, arg_16_1)
			if arg_16_1 == ccui.TouchEventType.ended then
				arg_14_0.activitiesModel:getActivityReward(xyd.Activities.Recall, var_14_10, function(arg_17_0, arg_17_1)
					if arg_17_0 == xyd.error.OK then
						arg_14_0.selfPlayer:handleRewards(arg_17_1.awards)
						arg_14_0.activitiesModel:clearRedMarkState(arg_14_0.activity.table_id, 2)

						if var_14_1.is_awarded[var_14_10] then
							var_14_1.is_awarded[var_14_10] = 1
						end

						arg_14_0.scrollList:refreshList()
					end
				end)
			end
		end)
	elseif var_14_2 == 3 then
		arg_14_0:initChatBox(var_14_4)
	elseif var_14_2 == 4 then
		if arg_14_0.details.base_info.recalled_player <= 0 and arg_14_0.searchInfo and next(arg_14_0.searchInfo) then
			local var_14_17 = arg_14_0.searchInfo[1]

			if var_14_17.conquer_lev and var_14_17.conquer_lev > 0 then
				var_14_4:getChildByName("lev_txt"):setString(var_14_17.conquer_lev)
				var_14_4:getChildByName("lv_bg"):setVisible(false)
			else
				var_14_4:getChildByName("lev_txt"):setString(var_14_17.lev)
				var_14_4:getChildByName("conquer_lev_bg"):setVisible(false)
			end

			arg_14_0.socialSystem:setOnlineState(var_14_4:getChildByName("online_time_text"), var_14_17)
			var_14_4:getChildByName("online_time_txt"):setVisible(false)

			local var_14_18 = {
				playerInfo = var_14_17,
				avatar_id = var_14_17.avatar_id,
				avatar_frame_id = var_14_17.avatar_frame_id
			}

			xyd.setPlayerAvatar(var_14_4:getChildByName("icon_container"), var_14_18)

			if var_14_17.region then
				var_14_4:getChildByName("region_txt"):setString("S" .. tostring(var_14_17.region))
			else
				var_14_4:getChildByName("region_txt"):setString("S" .. tostring(xyd.getPlayerRegion(var_14_17.player_id)))
			end

			var_14_4:getChildByName("name_txt"):setString(var_14_17.player_name)
			var_14_4:getChildByName("sure_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
				if arg_18_1 == ccui.TouchEventType.ended and not arg_14_0.scrollViewMoved_ then
					xyd.playButtonSound()

					local var_18_0 = {
						recalled_player = var_14_17.player_id
					}

					xyd.Backend.get():request(xyd.mid.RECALL_PLAYER_SURE, var_18_0, function(arg_19_0, arg_19_1)
						if arg_19_0 == xyd.error.OK then
							arg_14_0.details.base_info.recalled_player = var_18_0.recalled_player

							arg_14_0.scrollList:reload()
						end
					end)
				end
			end)
		else
			var_14_4:setVisible(false)
		end
	end

	var_14_3:addTo(var_14_0)
	var_14_3:setAnchorPoint(cc.p(0, 0))
	var_14_0:setContentSize(var_14_4:getContentSize())
	var_14_3:setName("source")

	return var_14_0
end

function var_0_0.initChatBox(arg_20_0, arg_20_1)
	local var_20_0 = xyd.AssetLoader.get()
	local var_20_1 = 24
	local var_20_2 = arg_20_1:getChildByName("edit_container")

	arg_20_1:getChildByName("tip_text"):setString(var_0_3:translation("ACTIVITY_RECALL_SEARCH_TEXT1"))

	if arg_20_0.details.base_info.recalled_player > 0 then
		arg_20_1:getChildByName("inputed_btn"):setVisible(true)
		arg_20_1:getChildByName("search_btn"):setVisible(false)
		arg_20_1:getChildByName("input_bg"):setVisible(false)
		arg_20_1:getChildByName("edit_desc"):setString(arg_20_0.details.base_info.recalled_player)

		return
	else
		arg_20_1:getChildByName("inputed_btn"):setVisible(false)
		arg_20_1:getChildByName("edit_desc"):setString("")
		arg_20_1:getChildByName("edit_desc"):setColor(cc.c3b(255, 255, 255))
	end

	arg_20_0.itemContainer = arg_20_1

	local var_20_3 = "windows/login/transparent.png"
	local var_20_4 = var_20_0:loadSprite(var_20_3)
	local var_20_5 = ccui.EditBox:create(var_20_2:getContentSize(), var_20_3)

	var_20_5:setAnchorPoint(0, 0)
	var_20_5:pos(0, 0):addTo(var_20_2)
	var_20_5:setFont(var_20_0.FONT_NAME, var_20_1)
	var_20_5:setPlaceholderFont(var_20_0.FONT_NAME, var_20_1)
	var_20_5:setPlaceHolder(var_0_3:translation("CHAT_INPUT_MESSAGE"))
	var_20_5:setPlaceholderFontColor(xyd.color.FONT_K)
	var_20_5:setFontColor(cc.c3b(255, 255, 255))
	var_20_5:registerScriptEditBoxHandler(handler(arg_20_0, arg_20_0.inputboxEventHandler))
	var_20_5:setInputFlag(3)

	arg_20_0.chatBox_ = var_20_5

	arg_20_1:getChildByName("search_btn"):addTouchEventListener(function(arg_21_0, arg_21_1)
		if arg_21_1 == ccui.TouchEventType.ended and not arg_20_0.scrollViewMoved_ then
			local var_21_0 = arg_20_1:getChildByName("edit_desc"):getString()
			local var_21_1 = {
				msg = var_21_0
			}

			arg_20_0.selfPlayer:searchPlayer(var_21_1, function(arg_22_0, arg_22_1)
				if arg_22_0 == xyd.error.OK then
					if arg_22_1 and next(arg_22_1) then
						arg_20_0.searchInfo = arg_22_1

						arg_20_0.scrollList:reload()
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_3:translation("SEARCH_NONE_TEXT")
						})
					end
				end
			end)
		end
	end)
end

function var_0_0.inputboxEventHandler(arg_23_0, arg_23_1)
	if arg_23_1 == "return" and not arg_23_0.scrollViewMoved_ then
		local var_23_0 = arg_23_0.chatBox_:getText()

		arg_23_0.itemContainer:getChildByName("edit_desc"):setString(var_23_0)
		arg_23_0.chatBox_:setText("")
	elseif arg_23_1 == "began" then
		local var_23_1 = arg_23_0.itemContainer:getChildByName("edit_desc"):getString()

		arg_23_0.itemContainer:getChildByName("edit_desc"):setString("")
		arg_23_0.chatBox_:setText(var_23_1)
	end
end

function var_0_0.scrollListener(arg_24_0, arg_24_1)
	if arg_24_1.name == "began" then
		arg_24_0.scrollViewMoved_ = false
		arg_24_0.prevY_ = arg_24_1.y
	elseif arg_24_1.name == "moved" and 5 <= math.abs(arg_24_1.y - arg_24_0.prevY_) then
		arg_24_0.scrollViewMoved_ = true
	end
end

function var_0_0.willClose(arg_25_0, arg_25_1)
	var_0_0.super:willClose(arg_25_1)

	if arg_25_0.handle then
		var_0_2.unscheduleGlobal(arg_25_0.handle)

		arg_25_0.handle = nil
	end

	if arg_25_0.callback then
		arg_25_0.callback(arg_25_0.activity)
	end
end

return var_0_0
