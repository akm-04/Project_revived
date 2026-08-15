local var_0_0 = class("SchoolStoryWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.currentStoryIndex = 1
	arg_1_0.currentStoryItemContainer = nil
	arg_1_0.talkIds = xyd.tables.libraryTalkTable:getTalkIdsByIdPrefix(arg_1_0.currentStoryIndex)
	arg_1_0.talkInfo = arg_1_0.library.talkInfo

	arg_1_0.library:initTalkOPenList()

	arg_1_0.talkOpenList = arg_1_0.library.talkOpenList
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0.storyContainer = arg_4_0:nodeByName("story_container")
	arg_4_0.detailContainer = arg_4_0:nodeByName("detail_container")

	local var_4_0 = arg_4_0.storyContainer:getContentSize()

	arg_4_0.storyScroll = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.storyContainer):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.storyScroll:setBounceable(true)
	arg_4_0.storyScroll:setDelegate(handler(arg_4_0, arg_4_0.storyScrollDelegate))
	arg_4_0.storyScroll:reload()

	local var_4_1 = arg_4_0.detailContainer:getContentSize()

	arg_4_0.detailScroll = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_1.width, var_4_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_4_0.detailContainer):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.detailScroll:setBounceable(true)
	arg_4_0.detailScroll:setDelegate(handler(arg_4_0, arg_4_0.detailScrollDelegate))
	arg_4_0.detailScroll:reload()
	arg_4_0:nodeByName("detail_desc_txt"):setString(var_0_1:translation("STORY_READ_DESC"))
end

function var_0_0.storyScrollDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return xyd.tables.libraryTalkTable:getStoryTotalNum()
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0 = arg_5_0.storyScroll:dequeueItem()

		if not var_5_0 then
			var_5_0 = arg_5_0.storyScroll:newItem()
		else
			var_5_0:removeAllChildren(true)
		end

		local var_5_1 = arg_5_0:creatStoryItemContent(arg_5_3)
		local var_5_2 = var_5_1:getWidth()
		local var_5_3 = var_5_1:getHeight()

		var_5_0:setItemSize(var_5_2, var_5_3 - 8)
		var_5_0:addContent(var_5_1)

		return var_5_0
	end
end

function var_0_0.creatStoryItemContent(arg_6_0, arg_6_1)
	local var_6_0 = display.newNode()
	local var_6_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/library/school_story/story_item.csb")
	local var_6_2 = var_6_1:getChildByName("container")

	var_6_2:getChildByName("title_txt"):setString(xyd.tables.libraryTalkTable:getChapterNameByIdPrefix(arg_6_1))
	var_6_2:getChildByName("title_txt"):enableOutline(xyd.color.FONT_OUTLINE_A, 1)
	var_6_2:getChildByName("select_bg"):setOpacity(0)

	if arg_6_0.library:isStoryItemRedPointShow(arg_6_1) then
		var_6_2:getChildByName("red_point"):setVisible(true)
	else
		var_6_2:getChildByName("red_point"):setVisible(false)
	end

	if arg_6_1 == arg_6_0.currentStoryIndex then
		arg_6_0.currentStoryItemContainer = var_6_2

		var_6_2:getChildByName("select_bg"):setOpacity(255)

		arg_6_0.currentItemBg = var_6_2:getChildByName("select_bg")
	end

	var_6_2:getChildByName("select_bg"):setTouchEnabled(true)
	var_6_2:getChildByName("select_bg"):setTouchSwallowEnabled(false)
	var_6_2:getChildByName("select_bg"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			return true
		elseif arg_7_0.name == "ended" and arg_6_0.scrollViewMoved_ ~= true then
			var_6_2:getChildByName("select_bg"):setOpacity(255)

			if arg_6_0.currentStoryIndex ~= arg_6_1 and arg_6_0.currentItemBg then
				arg_6_0.currentItemBg:setOpacity(0)
			end

			arg_6_0.currentStoryItemContainer = var_6_2
			arg_6_0.currentItemBg = var_6_2:getChildByName("select_bg")

			arg_6_0.currentItemBg:setOpacity(255)

			arg_6_0.currentStoryIndex = arg_6_1
			arg_6_0.talkIds = xyd.tables.libraryTalkTable:getTalkIdsByIdPrefix(arg_6_0.currentStoryIndex)

			arg_6_0.detailScroll:reload()
		end
	end)
	var_6_1:addTo(var_6_0)
	var_6_1:setAnchorPoint(cc.p(0, 0))
	var_6_0:setContentSize(var_6_2:getContentSize())
	var_6_1:setName("source")

	return var_6_0
end

function var_0_0.detailScrollDelegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return #arg_8_0.talkIds
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_0 = arg_8_0.detailScroll:dequeueItem()

		if not var_8_0 then
			var_8_0 = arg_8_0.detailScroll:newItem()
		else
			var_8_0:removeAllChildren(true)
		end

		local var_8_1 = arg_8_0:creatDetailItemContent(arg_8_0.talkIds[arg_8_3])
		local var_8_2 = var_8_1:getWidth()
		local var_8_3 = var_8_1:getHeight()

		var_8_0:setItemSize(var_8_2 + 20, var_8_3)
		var_8_0:addContent(var_8_1)

		return var_8_0
	end
end

function var_0_0.addCoverOnNode(arg_9_0, arg_9_1)
	local var_9_0 = "windows/library/school_story/cover.png"
	local var_9_1 = xyd.AssetLoader.get():loadSprite(var_9_0)

	var_9_1:setScale(0.9615384615384616)
	var_9_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_9_1:addTo(arg_9_1)
	var_9_1:setPosition(cc.p(arg_9_1:getContentSize().width / 2 + 2.5, arg_9_1:getContentSize().height / 2))
end

function var_0_0.createLevSprite(arg_10_0, arg_10_1)
	local var_10_0 = "windows/library/school_story/rank_bg.png"
	local var_10_1 = xyd.AssetLoader.get():loadSprite(var_10_0)

	var_10_1:setAnchorPoint(cc.p(0, 0))

	local var_10_2 = arg_10_0:createLabel(arg_10_1)

	var_10_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_10_2:addTo(var_10_1)
	var_10_2:setPosition(cc.p(var_10_1:getContentSize().width / 2, var_10_1:getContentSize().height / 2))

	return var_10_1
end

function var_0_0.createLabel(arg_11_0, arg_11_1)
	local var_11_0 = {
		font = "fonts/main_font.ttf",
		size = 20,
		color = cc.c3b(255, 255, 255)
	}
	local var_11_1 = xyd.AssetLoader.get():loadLabel(var_11_0)

	var_11_1:setMaxLineWidth(200)
	var_11_1:setString(arg_11_1)

	return var_11_1
end

function var_0_0.creatDetailItemContent(arg_12_0, arg_12_1)
	local var_12_0 = display.newNode()
	local var_12_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/library/school_story/detail_item.csb")
	local var_12_2 = var_12_1:getChildByName("container")
	local var_12_3 = var_12_2:getChildByName("read_story_btn")

	var_12_2:getChildByName("title_txt"):setString(xyd.tables.libraryTalkTable:getTalkName(arg_12_1))

	local var_12_4 = xyd.tables.libraryTalkTable:getUnlockConditionTypes(arg_12_1)
	local var_12_5 = xyd.tables.libraryTalkTable:getUnlockHero(arg_12_1)
	local var_12_6 = xyd.tables.libraryTalkTable:getUnlockParam(arg_12_1)

	for iter_12_0 = 1, #var_12_4 do
		local var_12_7 = ""
		local var_12_8 = display.newNode()

		var_12_8:setContentSize(var_12_2:getChildByName("container_" .. iter_12_0):getContentSize())
		var_12_8:setAnchorPoint(cc.p(0, 0))
		var_12_8:addTo(var_12_2:getChildByName("container_" .. iter_12_0))

		local var_12_9 = true

		if var_12_4[iter_12_0] == xyd.SchoolStoryUnlockConditionTypes.ownHero and var_12_5[iter_12_0] and var_12_5[iter_12_0] > 0 then
			if arg_12_0.selfPlayer:getHeroIgnoreAwaken(var_12_5[iter_12_0]) then
				var_12_9 = false
			end

			xyd.setItemBorder(var_12_2:getChildByName("container_" .. iter_12_0), var_12_5[iter_12_0], nil, var_12_9, nil)
			var_12_2:getChildByName("container_" .. iter_12_0):getChildByName("name_txt"):setString(xyd.tables.hero:name(var_12_5[iter_12_0]))

			var_12_7 = string.format(var_0_1:translation("LIBRARY_TALK_DESC1"), xyd.tables.hero:name(var_12_5[iter_12_0]))
		elseif var_12_4[iter_12_0] == xyd.SchoolStoryUnlockConditionTypes.heroLev then
			local var_12_10 = arg_12_0.selfPlayer:getHeroIgnoreAwaken(var_12_5[iter_12_0])

			if var_12_10 and var_12_10:getLevel() >= var_12_6[iter_12_0] then
				var_12_9 = false
			end

			xyd.setItemBorder(var_12_2:getChildByName("container_" .. iter_12_0), var_12_5[iter_12_0], nil, var_12_9, nil)
			var_12_2:getChildByName("container_" .. iter_12_0):getChildByName("name_txt"):setString(xyd.tables.hero:name(var_12_5[iter_12_0]))

			local var_12_11 = arg_12_0:createLevSprite(var_12_6[iter_12_0])

			var_12_11:addTo(var_12_2:getChildByName("container_" .. iter_12_0))
			var_12_11:setPosition(cc.p(5, 5))

			var_12_7 = string.format(var_0_1:translation("LIBRARY_TALK_DESC2"), xyd.tables.hero:name(var_12_5[iter_12_0]), var_12_6[iter_12_0])
		elseif var_12_4[iter_12_0] == xyd.SchoolStoryUnlockConditionTypes.playerLev then
			if arg_12_0.selfPlayer.lev >= var_12_6[iter_12_0] then
				var_12_9 = false
			end

			local var_12_12 = "images/icon/exp_icon.png"

			xyd.setSpriteBorder(var_12_2:getChildByName("container_" .. iter_12_0), var_12_12, 1, var_12_9)
			var_12_2:getChildByName("container_" .. iter_12_0):getChildByName("name_txt"):setString("LV " .. var_12_6[iter_12_0])

			var_12_7 = string.format(var_0_1:translation("LIBRARY_TALK_DESC3"), var_12_6[iter_12_0])
		elseif var_12_4[iter_12_0] == xyd.SchoolStoryUnlockConditionTypes.nomalChapter then
			if arg_12_0.selfPlayer.normal_chapter_id > var_12_6[iter_12_0] then
				var_12_9 = false
			end

			local var_12_13 = "images/icon/campaign_icon.png"

			xyd.setSpriteBorder(var_12_2:getChildByName("container_" .. iter_12_0), var_12_13, 1, var_12_9)
			var_12_2:getChildByName("container_" .. iter_12_0):getChildByName("name_txt"):setString(string.format(var_0_1:translation("NORMAL_CHAPTER"), var_12_6[iter_12_0]))

			var_12_7 = string.format(var_0_1:translation("LIBRARY_TALK_DESC4"), var_12_6[iter_12_0])
		end

		local var_12_14 = {}

		var_12_14.id = -100000
		var_12_14.tipsType = 1
		var_12_14.desc1 = var_12_7

		arg_12_0:addTips(var_12_8, var_12_14)
	end

	if xyd.tables.libraryTalkTable:item(arg_12_1) > 0 then
		xyd.setItemBorder(var_12_2:getChildByName("award_icon"), xyd.tables.libraryTalkTable:item(arg_12_1), nil, nil, nil)
		var_12_2:getChildByName("award_num"):setString(xyd.tables.libraryTalkTable:itemNum(arg_12_1))
	elseif xyd.tables.libraryTalkTable:diamond(arg_12_1) > 0 then
		var_12_2:getChildByName("yuanbao"):setVisible(true)
		var_12_2:getChildByName("award_num"):setString(xyd.tables.libraryTalkTable:diamond(arg_12_1))
	elseif xyd.tables.libraryTalkTable:gold(arg_12_1) > 0 then
		var_12_2:getChildByName("jinbi"):setVisible(true)
		var_12_2:getChildByName("award_num"):setString(xyd.tables.libraryTalkTable:gold(arg_12_1))
	end

	local var_12_15 = false

	if arg_12_0.talkOpenList[arg_12_1] then
		var_12_15 = true
	end

	if var_12_15 and arg_12_0.talkInfo[tostring(arg_12_1)] == 0 then
		var_12_2:getChildByName("read_story_btn"):getChildByName("red_point"):setVisible(true)
	else
		var_12_2:getChildByName("read_story_btn"):getChildByName("red_point"):setVisible(false)
	end

	var_12_2:getChildByName("award_num"):enableOutline(xyd.color.FONT_OUTLINE_A, 1)
	var_12_2:getChildByName("read_story_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended and arg_12_0.scrollViewMoved_ ~= true then
			local var_13_0 = {
				talk_id = arg_12_1
			}

			if arg_12_0.talkInfo[tostring(arg_12_1)] == 0 then
				arg_12_0.library:getSchoolStoryReward(var_13_0, function(arg_14_0, arg_14_1)
					if arg_14_0 == xyd.error.OK then
						arg_12_0.talkInfo[tostring(arg_12_1)] = 1

						if not arg_12_0.library:isStoryItemRedPointShow(arg_12_0.currentStoryIndex) and arg_12_0.currentStoryItemContainer then
							arg_12_0.currentStoryItemContainer:getChildByName("red_point"):setVisible(false)
						end

						var_12_2:getChildByName("read_story_btn"):getChildByName("red_point"):setVisible(false)

						if arg_14_1.awards then
							var_13_0.awards = arg_14_1.awards

							xyd.WindowManager.get():openWindow("school_story_talk", var_13_0)
						else
							xyd.WindowManager.get():openWindow("school_story_talk", var_13_0)
						end
					else
						xyd.WindowManager.get():openWindow("school_story_talk", var_13_0)
					end
				end)
			else
				xyd.WindowManager.get():openWindow("school_story_talk", var_13_0)
			end
		end
	end)

	if var_12_15 then
		var_12_3:setVisible(true)
	else
		var_12_3:setVisible(false)
	end

	var_12_1:addTo(var_12_0)
	var_12_1:setAnchorPoint(cc.p(0, 0))
	var_12_0:setContentSize(var_12_2:getContentSize())
	var_12_1:setName("source")

	return var_12_0
end

function var_0_0.scrollListener(arg_15_0, arg_15_1)
	if arg_15_1.name == "began" then
		arg_15_0.scrollViewMoved_ = false
		arg_15_0.prevX_ = arg_15_1.x
	elseif arg_15_1.name == "moved" and 5 <= math.abs(arg_15_1.x - arg_15_0.prevX_) then
		arg_15_0.scrollViewMoved_ = true
	end
end

function var_0_0.didClose(arg_16_0, arg_16_1)
	var_0_0.super.didClose(arg_16_1)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.CHECK_MIDDLE_RED_MARK,
		params = xyd.CheckMiddleRed.LIBRARY
	})

	local var_16_0 = xyd.WindowManager.get():getWindow("library")

	if var_16_0 then
		var_16_0:updateRedMarkShow()
	end
end

return var_0_0
