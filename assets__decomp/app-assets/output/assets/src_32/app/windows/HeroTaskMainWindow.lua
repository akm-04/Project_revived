local var_0_0 = class("HeroTaskMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = 1000
local var_0_4 = 4
local var_0_5 = "main_scene_bottom"
local var_0_6 = "main_scene_left"
local var_0_7 = "main_scene_middle"
local var_0_8 = "main_scene_top"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.hero = arg_1_2.hero
	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.cardContainer = arg_2_0:nodeByName("card_container")

	local var_2_0 = arg_2_0.hero:getTableID()

	if arg_2_0.hero:isAwaken() then
		var_2_0 = xyd.tables.hero:beforeAwaken(var_2_0)
	end

	arg_2_0.dialogTable = import("app.common.tables.DialogueTable").new(var_2_0)

	arg_2_0:layout()

	local var_2_1 = {
		hero = arg_2_0.hero
	}

	xyd.WindowManager.get():openWindow("library_hero_favor", var_2_1)
end

function var_0_0.didClose(arg_3_0, arg_3_1)
	var_0_0.super.didClose(arg_3_0, arg_3_1)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_HERO_VISIT_REDPOINT
	})
	xyd.WindowManager.get():closeWindow("library_hero_favor")
end

function var_0_0.layout(arg_4_0)
	arg_4_0.bg = arg_4_0:nodeByName("bg")

	arg_4_0:setBG()
	arg_4_0:updateCardContainer()

	arg_4_0.scroll = arg_4_0:nodeByName("scroll")
	arg_4_0.scrollContent = arg_4_0.scroll:getContentSize()
	arg_4_0.taskList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_4_0.scrollContent.width, arg_4_0.scrollContent.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.taskList:setDelegate(handler(arg_4_0, arg_4_0.taskListDelegate))
	arg_4_0.taskList:setBounceable(true)
	arg_4_0.taskList:reload()
	arg_4_0:nodeByName("label_name"):setString(arg_4_0.hero:getName())
	arg_4_0:playTalk()
end

function var_0_0.setBG(arg_5_0)
	if arg_5_0.bg then
		arg_5_0.bg:removeSelf()
	end

	arg_5_0.bg = xyd.SpriteLoader.new(xyd.tables.libraryBG:getBG(arg_5_0.library.bgRoom), nil, nil, xyd.DefaultImageType.BG_ROOM)

	arg_5_0.bg:setAnchorPoint(0, 0)
	arg_5_0.bg:addTo(arg_5_0, -1)
end

function var_0_0.taskListDelegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = arg_6_0.library:getPartnerMissions(arg_6_0.hero)

	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return #var_6_0
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_1
		local var_6_2 = arg_6_0.taskList:dequeueItem()

		if not var_6_2 then
			var_6_2 = arg_6_0.taskList:newItem()
		else
			var_6_2:removeAllChildren(true)
		end

		local var_6_3 = arg_6_0:createListContent(var_6_0[arg_6_3])
		local var_6_4 = var_6_3:getWidth()
		local var_6_5 = var_6_3:getHeight()

		var_6_2:setItemSize(var_6_4, var_6_5)
		var_6_2:addContent(var_6_3)

		return var_6_2
	end
end

function var_0_0.createListContent(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_1.mission_id
	local var_7_1 = display.newNode()
	local var_7_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/library/task_main/task_item.csb")
	local var_7_3 = var_7_2:getChildByName("container")

	var_7_3:setAnchorPoint(cc.p(0.5, 0.5))
	;(function(...)
		local var_8_0 = xyd.tables.libraryMission

		var_7_3:getChildByName("name_txt"):setString(var_8_0:name(var_7_0))
		var_7_3:getChildByName("desc_txt"):setString(var_8_0:desc(var_7_0))
		var_7_3:getChildByName("name_txt"):enableOutline(cc.c4b(150, 243, 254, 255), 2)
		var_7_3:getChildByName("name_txt"):setColor(cc.c3b(0, 0, 0))
		arg_7_0.library:formatDifficultyText(var_7_3:getChildByName("rank_txt"), var_7_0)
		var_7_3:getChildByName("rank_txt"):setPositionX(var_7_3:getChildByName("name_txt"):getPositionX() + var_7_3:getChildByName("name_txt"):getContentSize().width + 15)

		local var_8_1 = var_7_3:getChildByName("award_container")

		var_8_1:getChildByName("award_text"):setString(var_0_1:translation("MISSION_TEXT"))
		var_8_1:getChildByName("award_num_txt"):setString(xyd.tables.libraryMission:amour(var_7_0))
		var_8_1:getChildByName("progress_txt"):setString(tostring(arg_7_1.process) .. "/" .. tostring(xyd.tables.libraryMission:req(var_7_0)))
		var_7_3:getChildByName("gotten"):setVisible(false)
		var_8_1:setVisible(false)

		if arg_7_1.mission_state == xyd.LibraryMissionState.AWARDED then
			var_7_3:getChildByName("gotten"):setVisible(true)
		else
			var_8_1:setVisible(true)
		end
	end)()
	var_7_2:addTo(var_7_1)
	var_7_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_7_2:setPosition(cc.p(var_7_3:getContentSize().width / 2, var_7_3:getContentSize().height / 2))
	var_7_2:setTouchEnabled(true)
	var_7_2:setTouchSwallowEnabled(false)
	var_7_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			var_7_3:setScale(0.9)

			return true
		elseif arg_9_0.name == "moved" then
			if arg_7_0.scrollViewMoved_ then
				var_7_3:setScale(1)
			end

			return true
		elseif arg_9_0.name == "ended" then
			var_7_3:setScale(1)

			if arg_7_0.scrollViewMoved_ then
				return
			end

			if var_7_0 == 1001 then
				local var_9_0 = {
					hero = arg_7_0.hero
				}

				xyd.WindowManager.get():openWindow("hero_gift_box", var_9_0)
			elseif var_7_0 == 1002 then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
					params = {
						window = "hero_task_main"
					}
				})
				xyd.WindowManager.get():retainHistory()

				local var_9_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)

				var_9_1.currentHero = arg_7_0.hero
				var_9_1.retainHistoryTmp = xyd.WindowManager.get():getRetainedHistory()

				local var_9_2 = {}

				var_9_2.not_clear_library_history = true

				xyd.WindowManager.get():openWindow("social_system", var_9_2)
			elseif var_7_0 == 1003 or var_7_0 == 1005 then
				local var_9_3 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

				var_9_3:loadSelfGuild(function(arg_10_0)
					if arg_10_0 == xyd.error.OK then
						if var_9_3.guild_id == nil or var_9_3.guild_id == 0 then
							xyd.WindowManager.get():openWindow("team_main")
						else
							local var_10_0 = xyd.WindowManager.get():openWindow("team")

							if var_7_0 == 1003 then
								var_10_0:enterBorrow()
							end
						end
					end
				end)
			elseif var_7_0 == 1004 then
				local var_9_4 = xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH)

				if var_9_4.mapInfo == nil then
					var_9_4:loadMarchInfo({}, function(arg_11_0)
						if arg_11_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("march")
						end
					end)
				else
					xyd.WindowManager.get():openWindow("march")
				end
			elseif var_7_0 == 1006 then
				xyd.WindowManager.get():openWindow("sub_arena")
			end
		end
	end)
	var_7_1:setContentSize(var_7_3:getContentSize())
	var_7_2:setName("source")

	return var_7_1
end

function var_0_0.closeAllWithoutExceptWindow(arg_12_0, arg_12_1)
	local var_12_0 = {}
	local var_12_1 = xyd.WindowManager.get():getWindowHistory()

	for iter_12_0 = 1, #var_12_1 do
		local var_12_2 = var_12_1[iter_12_0]

		if not xyd.isInTable(arg_12_1, var_12_2.name) then
			table.insert(var_12_0, var_12_2.name)
		end
	end

	for iter_12_1 = 1, #var_12_0 do
		xyd.WindowManager.get():closeWindow(var_12_0[iter_12_1])
	end
end

function var_0_0.scrollListener(arg_13_0, arg_13_1)
	if arg_13_1.name == "began" then
		arg_13_0.scrollViewMoved_ = false
		arg_13_0.prevY_ = arg_13_1.y
	elseif arg_13_1.name == "moved" and 5 <= math.abs(arg_13_1.y - arg_13_0.prevY_) then
		arg_13_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateCardContainer(arg_14_0)
	arg_14_0.library:updateCardContainer(arg_14_0.hero, arg_14_0.cardContainer, arg_14_0.library.cardState)
end

function var_0_0.playTalk(arg_15_0)
	arg_15_0:nodeByName("text"):setString("")
	arg_15_0:speak(arg_15_0.dialogTable:getDialog(0), arg_15_0:nodeByName("text"), xyd.tables.misc.dialogSpeed)
end

function var_0_0.speak(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	local var_16_0 = xyd.utf8len(arg_16_1)

	arg_16_0.showInOneTime = false
	arg_16_0.isOnSpeaking = true

	local var_16_1 = 0

	if arg_16_0.handler then
		var_0_2.unscheduleGlobal(arg_16_0.handler)

		arg_16_0.handler = nil
	end

	arg_16_0.handler = var_0_2.scheduleGlobal(function()
		var_16_1 = var_16_1 + 1

		if var_16_1 > var_16_0 and arg_16_0.handler or arg_16_0.showInOneTime == true then
			if not tolua.isnull(arg_16_2) then
				arg_16_2:setString(arg_16_1)
			end

			var_0_2.unscheduleGlobal(arg_16_0.handler)

			arg_16_0.isOnSpeaking = false

			return
		end

		local var_17_0 = xyd.getSplitUtf8Str(arg_16_1, 0, var_16_1 * 3)

		if not tolua.isnull(arg_16_2) then
			arg_16_2:setString(var_17_0)
		end
	end, arg_16_3)
end

return var_0_0
