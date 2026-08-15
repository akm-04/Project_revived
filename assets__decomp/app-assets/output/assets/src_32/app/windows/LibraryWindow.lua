local var_0_0 = class("LibraryWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	{
		bookIconPath = "windows/library/book_1.png",
		correspondWindowName = "tujian_hero",
		nameIconPath = "windows/library/name_1.png",
		desc = var_0_1:translation("HERO_TUJIAN_DESC")
	},
	{
		bookIconPath = "windows/library/book_5.png",
		correspondWindowName = "adventure_event",
		nameIconPath = "windows/library/name_5.png",
		desc = var_0_1:translation("ADVENTURE_EVENT_DESC")
	},
	{
		bookIconPath = "windows/library/book_2.png",
		correspondWindowName = "tujian",
		nameIconPath = "windows/library/name_2.png",
		desc = var_0_1:translation("EQUIP_TUJIAN_DESC")
	},
	{
		bookIconPath = "windows/library/book_3.png",
		correspondWindowName = "tujian_pet",
		nameIconPath = "windows/library/name_3.png",
		desc = var_0_1:translation("PET_TUJIAN_DESC")
	},
	{
		bookIconPath = "windows/library/book_4.png",
		correspondWindowName = "school_story",
		nameIconPath = "windows/library/name_4.png",
		desc = var_0_1:translation("SCHOOL_STORY_DESC")
	},
	{
		bookIconPath = "windows/library/book_6.png",
		correspondWindowName = "memory_collect",
		nameIconPath = "windows/library/name_6.png",
		desc = var_0_1:translation("LIBRARY_CG_DESC")
	},
	{
		bookIconPath = "windows/library/book_7.png",
		correspondWindowName = "library_bg",
		nameIconPath = "windows/library/name_7.png",
		desc = var_0_1:translation("LIBRARY_BG_DESC")
	}
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:setTouchSwallowEnabled(true)
	arg_2_0:checkFuncOpen()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super:didClose(arg_4_1)

	if arg_4_0.speakCellContent then
		arg_4_0.speakCellContent:removeDelay()
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.CHECK_MIDDLE_RED_MARK,
		params = xyd.CheckMiddleRed.LIBRARY
	})
end

function var_0_0.checkFuncOpen(arg_5_0)
	local var_5_0 = {}

	for iter_5_0, iter_5_1 in ipairs(var_0_2) do
		if iter_5_1.correspondWindowName == "adventure_event" then
			if arg_5_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_ADVENTURE) then
				table.insert(var_5_0, iter_5_1)
			end
		elseif iter_5_1.correspondWindowName == "tujian_pet" then
			if arg_5_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PET_TUJIAN) then
				table.insert(var_5_0, iter_5_1)
			end
		else
			table.insert(var_5_0, iter_5_1)
		end
	end

	var_0_2 = var_5_0
end

function var_0_0.layout(arg_6_0)
	arg_6_0.scroll = arg_6_0:nodeByName("scroll")

	local var_6_0 = arg_6_0.scroll:getContentSize()

	arg_6_0.branchList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 20, var_6_0.width, var_6_0.height - 20),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_6_0.scroll):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.branchList:setBounceable(true)
	arg_6_0.branchList:setDelegate(handler(arg_6_0, arg_6_0.branchListDelegate))
	arg_6_0.branchList:setTouchType(false)
	arg_6_0.branchList:reload()
	arg_6_0:addDialog()
end

function var_0_0.addDialog(arg_7_0)
	local var_7_0 = {
		touchPosition = cc.p(0, -200),
		touchAreaSize = {
			width = 350,
			height = 420
		}
	}
	local var_7_1 = {}

	for iter_7_0 = 1, 5 do
		table.insert(var_7_1, var_0_1:translation("LIBRARY_MAIN_DIALOG" .. iter_7_0))
	end

	var_7_0.msgs = var_7_1
	var_7_0.times = {
		4,
		7,
		6,
		8,
		9
	}
	arg_7_0.speakCellContent = import("app.windows.SpeakCell").new(var_7_0)

	arg_7_0.speakCellContent:addTo(arg_7_0)
	arg_7_0.speakCellContent:setAnchorPoint(cc.p(0, 0))
	arg_7_0.speakCellContent:setPosition(arg_7_0:nodeByName("speak_pos"):getPosition())
	arg_7_0.speakCellContent:onclick()
end

function var_0_0.branchListDelegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return #var_0_2
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_0
		local var_8_1 = arg_8_0.branchList:dequeueItem()

		if not var_8_1 then
			var_8_1 = arg_8_0.branchList:newItem()
		else
			var_8_1:removeAllChildren(false)
		end

		local var_8_2 = arg_8_0:createListContent(var_0_2[arg_8_3], var_8_1)
		local var_8_3 = var_8_2:getWidth()
		local var_8_4 = var_8_2:getHeight()

		var_8_1:setItemSize(var_8_3, var_8_4)
		var_8_1:addContent(var_8_2)

		return var_8_1
	end
end

function var_0_0.updateRedMarkShow(arg_9_0)
	if arg_9_0.storyRedPoint then
		if arg_9_0.library:isSchoolStoryRedPointShow() then
			arg_9_0.storyRedPoint:setVisible(true)
		else
			arg_9_0.storyRedPoint:setVisible(false)
		end
	end
end

function var_0_0.createListContent(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = display.newNode()
	local var_10_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/library/branch_item.csb")
	local var_10_2 = var_10_1:getChildByName("container")
	local var_10_3 = xyd.AssetLoader.get():loadSprite(arg_10_1.nameIconPath)

	var_10_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_10_3:addTo(var_10_1)
	var_10_3:setPosition(var_10_2:getChildByName("name_pos"):getPosition())

	local var_10_4 = arg_10_1.bookIconPath

	xyd.setSpriteBorder(var_10_2:getChildByName("icon_container"), var_10_4, nil)
	var_10_2:getChildByName("red_point"):setVisible(false)

	if arg_10_1.correspondWindowName == "school_story" then
		arg_10_0.storyRedPoint = var_10_2:getChildByName("red_point")

		arg_10_0:updateRedMarkShow()
	end

	if arg_10_1.correspondWindowName == "memory_collect" then
		arg_10_0.memoryCollectRedPoint = var_10_2:getChildByName("red_point")

		arg_10_0:updateMemoryCollectRedMark()
	end

	var_10_2:getChildByName("desc"):setString(arg_10_1.desc)
	var_10_1:setTouchEnabled(true)
	var_10_1:setTouchSwallowEnabled(false)
	var_10_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			return true
		elseif arg_11_0.name == "ended" and arg_10_0.scrollViewMoved_ ~= true then
			xyd.playButtonSound()

			if arg_10_1.correspondWindowName == "school_story" then
				arg_10_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.SCHOOL_STORY)
				xyd.WindowManager.get():openWindow("school_story")
			elseif arg_10_1.correspondWindowName == "tujian_hero" then
				arg_10_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.HERO_TUJIAN)
				xyd.WindowManager.get():openWindow("tujian_hero")
			elseif arg_10_1.correspondWindowName == "tujian_pet" then
				if arg_10_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PET) == true then
					xyd.WindowManager.get():openWindow(arg_10_1.correspondWindowName)
				else
					local var_11_0 = xyd.tables.functionOpen
					local var_11_1 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_11_0:level(xyd.FunctionID.ID_PET))

					xyd.WindowManager.get():openWindow("toast", {
						message = var_11_1
					})
				end
			elseif arg_10_1.correspondWindowName == "tujian" then
				arg_10_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.EQUIP_TUJIAN)
				xyd.WindowManager.get():openWindow(arg_10_1.correspondWindowName)
			elseif arg_10_1.correspondWindowName == "adventure_event" then
				arg_10_0.adventureEvent = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)

				xyd.WindowManager.get():openWindow(arg_10_1.correspondWindowName)
			elseif arg_10_1.correspondWindowName == "memory_collect" then
				xyd.WindowManager.get():openWindow(arg_10_1.correspondWindowName)
			elseif arg_10_1.correspondWindowName == "library_bg" then
				xyd.WindowManager.get():openWindow(arg_10_1.correspondWindowName)
			end
		end
	end)
	var_10_1:addTo(var_10_0)
	var_10_1:setAnchorPoint(cc.p(0, 0))
	var_10_0:setContentSize(var_10_2:getContentSize())
	var_10_1:setName("source")

	return var_10_0
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevY_ = arg_12_1.y
	elseif arg_12_1.name == "moved" and 5 <= math.abs(arg_12_1.y - arg_12_0.prevY_) then
		arg_12_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateMemoryCollectRedMark(arg_13_0)
	if arg_13_0.memoryCollectRedPoint then
		if arg_13_0.library:isMemoryCollectRedPointShow() then
			arg_13_0.memoryCollectRedPoint:setVisible(true)
		else
			arg_13_0.memoryCollectRedPoint:setVisible(false)
		end
	end
end

return var_0_0
