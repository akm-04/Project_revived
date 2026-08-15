local var_0_0 = class("MemoryCollectWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.libraryCG
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.item
local var_0_4 = 85
local var_0_5 = 110
local var_0_6 = 75
local var_0_7 = 60

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.index = 1
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.isAwarded = arg_2_0.library.memoryCollectInfo
	arg_2_0.scroll = arg_2_0:nodeByName("scroll")
	arg_2_0.right = arg_2_0:nodeByName("detail_container")

	arg_2_0:nodeByName("tip"):setString(var_0_2:translation("LIBRARY_CG_TIPS"))

	local var_2_0 = arg_2_0.scroll:getContentSize()

	arg_2_0.tagList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_0.width, var_2_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_2_0.scroll):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.tagList:setDelegate(handler(arg_2_0, arg_2_0.tagListDelegate))
	arg_2_0.tagList:reload()
	arg_2_0:updateRight()
end

function var_0_0.scrollListener(arg_3_0, arg_3_1)
	if arg_3_1.name == "began" then
		arg_3_0.scrollViewMoved_ = false
		arg_3_0.prevY_ = arg_3_1.y
	elseif arg_3_1.name == "moved" and 20 <= math.abs(arg_3_1.y - arg_3_0.prevY_) then
		arg_3_0.scrollViewMoved_ = true
	end
end

function var_0_0.tagListDelegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #arg_4_0.isAwarded
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0
		local var_4_1 = arg_4_0.tagList:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.tagList:newItem()
		else
			var_4_1:removeAllChildren(false)
		end

		local var_4_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/library/memory_collect/tag.csb")
		local var_4_3 = var_4_2:getChildByName("container")

		var_4_3:getChildByName("txt"):enableOutline(cc.c4b(92, 84, 53, 255), 2)
		var_4_3:getChildByName("txt"):setString(var_0_1:getName(arg_4_3))
		var_4_3:getChildByName("red_point"):setVisible(arg_4_0.library:isMemoryCollectItemRedPointShow(arg_4_3))

		if arg_4_0.index == arg_4_3 then
			var_4_3:getChildByName("bg_chosen"):setVisible(true)

			arg_4_0.currentTag = var_4_3
		end

		local var_4_4 = var_4_3:getContentSize()
		local var_4_5 = display.newNode()

		var_4_5:setContentSize(var_4_4.width, var_4_4.height)
		var_4_5:addTo(var_4_3)
		var_4_5:setAnchorPoint(0, 0)
		var_4_5:setTouchEnabled(true)
		var_4_5:setTouchSwallowEnabled(false)
		var_4_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
			if arg_5_0.name == "began" then
				return true
			elseif arg_5_0.name == "ended" and not arg_4_0.scrollViewMoved_ and arg_4_3 ~= arg_4_0.index and not arg_4_0.isAnimation then
				arg_4_0.index = arg_4_3

				if arg_4_0.currentTag and not tolua.isnull(arg_4_0.currentTag) then
					arg_4_0.currentTag:getChildByName("bg_chosen"):setVisible(false)
				end

				arg_4_0.currentTag = var_4_3

				arg_4_0.currentTag:getChildByName("bg_chosen"):setVisible(true)
				arg_4_0:updateRight()
			end
		end)
		var_4_1:setItemSize(var_4_4.width, var_4_4.height)
		var_4_1:addContent(var_4_2)

		return var_4_1
	end
end

function var_0_0.updateRight(arg_6_0)
	arg_6_0.right:removeAllChildren()

	local var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/library/memory_collect/detail.csb")

	var_6_0:addTo(arg_6_0.right)

	local var_6_1 = var_6_0:getChildByName("container")
	local var_6_2, var_6_3 = arg_6_0.library:getMemoryCollectItemInfo(arg_6_0.index)
	local var_6_4 = var_6_1:getChildByName("btn")

	var_6_1:getChildByName("desc"):setString(var_0_1:getContent(arg_6_0.index))
	var_6_4:setBright(var_6_2 and arg_6_0.isAwarded[arg_6_0.index] == 0)
	var_6_4:setTouchEnabled(var_6_2 and arg_6_0.isAwarded[arg_6_0.index] == 0)
	var_6_4:getChildByName("award_gray"):setVisible(not var_6_2)
	var_6_4:getChildByName("word_award"):setVisible(var_6_2 and arg_6_0.isAwarded[arg_6_0.index] == 0)
	var_6_4:getChildByName("word_got"):setVisible(var_6_2 and arg_6_0.isAwarded[arg_6_0.index] == 1)
	var_6_4:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended and not arg_6_0.isAnimation then
			arg_6_0.library:getMemoryCollectAward(arg_6_0.index, function()
				var_6_4:setBright(false)
				var_6_4:getChildByName("word_award"):setVisible(false)
				var_6_4:getChildByName("word_got"):setVisible(true)
				arg_6_0.currentTag:getChildByName("red_point"):setVisible(false)

				arg_6_0.isAwarded[arg_6_0.index] = 1
			end)
		end
	end)

	local var_6_5

	if not var_6_2 then
		var_6_5 = {
			filter = {}
		}
		var_6_5.filter.name = "GRAY"
		var_6_5.filter.value = {
			0.3,
			0.59,
			0.11,
			0.1
		}
	end

	local var_6_6 = xyd.SpriteLoader.new(var_0_1:getCG(arg_6_0.index), nil, var_6_5, xyd.DefaultImageType.CG)
	local var_6_7 = var_6_6:getContentSize()
	local var_6_8 = var_6_1:getChildByName("clip"):getContentSize()
	local var_6_9 = xyd.AssetLoader.get():loadSprite("images/cg/logo.png", nil, var_6_5)

	var_6_9:addTo(var_6_6)
	var_6_9:setAnchorPoint(0, 0)
	var_6_9:setPosition(80, 50)
	var_6_6:setScaleX(var_6_8.width / var_6_7.width)
	var_6_6:setScaleY(var_6_8.height / var_6_7.height)
	var_6_6:setAnchorPoint(0.5, 0.5)
	var_6_6:addTo(var_6_1)
	var_6_6:setPosition(var_6_1:getChildByName("img_pos"):getPosition())
	var_6_6:setLocalZOrder(99)
	var_6_1:getChildByName("clip"):setVisible(not var_6_2)
	var_6_1:getChildByName("clip"):setTouchEnabled(true)
	var_6_1:getChildByName("clip"):setLocalZOrder(100)
	var_6_1:getChildByName("clip"):setTouchSwallowEnabled(true)
	var_6_6:setTouchEnabled(true)
	var_6_6:setTouchSwallowEnabled(true)
	var_6_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "ended" and not arg_6_0.isAnimation then
			if arg_6_0.cardClicked_ then
				local var_9_0 = cc.Spawn:create(cc.ScaleTo:create(0.3, var_6_8.width / var_6_7.width, var_6_8.height / var_6_7.height), cc.MoveBy:create(0.3, cc.p(1, 12)))

				arg_6_0.isAnimation = true

				arg_6_0:nodeByName("close"):setTouchEnabled(true)
				var_6_6:runActionOnce(var_9_0, false, function()
					arg_6_0.cardClicked_ = false
					arg_6_0.isAnimation = false
				end)
			else
				local var_9_1 = cc.Spawn:create(cc.ScaleTo:create(0.3, 1), cc.MoveBy:create(0.3, cc.p(-1, -12)))

				arg_6_0.isAnimation = true

				arg_6_0:nodeByName("close"):setTouchEnabled(false)
				var_6_6:runActionOnce(var_9_1, false, function()
					arg_6_0.cardClicked_ = true
					arg_6_0.isAnimation = false
				end)
			end
		end

		return true
	end)

	local var_6_10 = var_0_1:getUnlockIDs(arg_6_0.index)
	local var_6_11 = var_0_1:getUnlockTypes(arg_6_0.index)
	local var_6_12, var_6_13 = var_6_1:getChildByName("item_pos"):getPosition()
	local var_6_14, var_6_15 = var_6_1:getChildByName("txt_pos"):getPosition()

	for iter_6_0 = 1, #var_6_10 do
		local var_6_16 = math.ceil(iter_6_0 / 3)
		local var_6_17 = (iter_6_0 - 1) % 3 + 1
		local var_6_18 = display.newNode()

		var_6_18:setContentSize(var_0_6, var_0_6)
		xyd.setItemBorder(var_6_18, var_6_10[iter_6_0], nil, not var_6_3[iter_6_0])
		var_6_18:addTo(var_6_1)
		var_6_18:setAnchorPoint(0.5, 0.5)
		var_6_18:setPosition(var_6_12 + (var_6_17 - 1) * var_0_4, var_6_13 - (var_6_16 - 1) * var_0_5)

		local var_6_19 = {}

		var_6_19.id = -100000
		var_6_19.tipsType = 1

		if var_6_11[iter_6_0] == 1 then
			local var_6_20 = var_0_3:skinPartner(var_6_10[iter_6_0])

			var_6_19.desc1 = string.format(var_0_2:translation("LIBRARY_CG_DESC2"), xyd.tables.hero:name(var_6_20), var_0_3:name(var_6_10[iter_6_0]))
		elseif var_6_11[iter_6_0] == 2 then
			var_6_19.desc1 = string.format(var_0_2:translation("LIBRARY_TALK_DESC1"), var_0_3:name(var_6_10[iter_6_0]))
		elseif var_6_11[iter_6_0] == 3 then
			var_6_19.desc1 = string.format(var_0_2:translation("LIBRARY_CG_DESC1"), var_0_3:name(var_6_10[iter_6_0]))
		end

		arg_6_0:addTips(var_6_18, var_6_19)

		local var_6_21 = xyd.AssetLoader.get():loadLabel({
			size = 16,
			text = xyd.tables.item:name(var_6_10[iter_6_0]),
			color = cc.c3b(216, 147, 57)
		})

		var_6_21:addTo(var_6_1)
		var_6_21:setAnchorPoint(0.5, 0.5)
		var_6_21:setPosition(var_6_14 + (var_6_17 - 1) * var_0_4, var_6_15 - (var_6_16 - 1) * var_0_5)
	end

	local var_6_22 = display.newNode()

	var_6_22:setContentSize(var_0_7, var_0_7)
	xyd.setItemAndAddTips(var_6_22, var_0_1:getItem(arg_6_0.index))
	var_6_22:setAnchorPoint(0.5, 0.5)
	var_6_22:addTo(var_6_1:getChildByName("item_pos2"))
	var_6_1:getChildByName("num"):setString("x " .. var_0_1:getNum(arg_6_0.index))
end

function var_0_0.didOpen(arg_12_0, arg_12_1)
	arg_12_0:setTouchSwallowEnabled(true)
	arg_12_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 0))
end

function var_0_0.didClose(arg_13_0, arg_13_1)
	var_0_0.super.didClose(arg_13_1)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.CHECK_MIDDLE_RED_MARK,
		params = xyd.CheckMiddleRed.LIBRARY
	})

	local var_13_0 = xyd.WindowManager.get():getWindow("library")

	if var_13_0 then
		var_13_0:updateMemoryCollectRedMark()
	end
end

return var_0_0
