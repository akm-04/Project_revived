local var_0_0 = class("SummerFishRuleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = "skeletons/ui_effect/summer/fish1"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.summer = xyd.ModelManager.get():loadModel(xyd.ModelType.SUMMER)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("text_title"):setString(var_0_1:translation("ACTIVITY_RULE"))

	arg_3_0.scroll = arg_3_0:nodeByName("scroll")

	local var_3_0 = arg_3_0.scroll:getContentSize()

	arg_3_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.scrollList:setBounceable(false)
	arg_3_0.scrollList:setDelegate(handler(arg_3_0, arg_3_0.scrollListDelegate))
	arg_3_0.scrollList:setTouchType(false)
	arg_3_0.scrollList:reload()
end

function var_0_0.scrollListDelegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return 3
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0
		local var_4_1 = arg_4_0.scrollList:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.scrollList:newItem()
		else
			var_4_1:removeAllChildren(true)
		end

		local var_4_2 = arg_4_0:createListContent(arg_4_3)
		local var_4_3 = var_4_2:getWidth()
		local var_4_4 = var_4_2:getHeight()

		var_4_1:setItemSize(var_4_3, var_4_4)
		var_4_1:addContent(var_4_2)

		return var_4_1
	end
end

function var_0_0.createListContent(arg_5_0, arg_5_1)
	local var_5_0 = display.newNode()

	if arg_5_1 == 1 then
		local var_5_1 = var_0_1:translation("SUMMER_GOLDFISH_RULE_TEXT1")
		local var_5_2 = arg_5_0:crateRuleLabel(var_5_1)

		var_5_2:setAnchorPoint(cc.p(0, 0))
		var_5_2:addTo(var_5_0)
		var_5_0:setContentSize(var_5_2:getContentSize())

		return var_5_0
	elseif arg_5_1 == 3 then
		local var_5_3 = var_0_1:translation("SUMMER_GOLDFISH_RULE_TEXT2")
		local var_5_4 = arg_5_0:crateRuleLabel(var_5_3)

		var_5_4:setAnchorPoint(cc.p(0, 0))
		var_5_4:addTo(var_5_0)
		var_5_0:setContentSize(var_5_4:getContentSize())

		return var_5_0
	elseif arg_5_1 == 2 then
		return (arg_5_0:createFishReward())
	elseif arg_5_1 == 4 then
		return (arg_5_0:createHeadFrameReward())
	end
end

function var_0_0.crateRuleLabel(arg_6_0, arg_6_1)
	local var_6_0 = {
		size = 24,
		color = cc.c3b(121, 52, 52)
	}
	local var_6_1 = xyd.AssetLoader.get():loadLabel(var_6_0)

	var_6_1:setMaxLineWidth(700)
	var_6_1:setLineHeight(49)
	var_6_1:setString(arg_6_1)

	return var_6_1
end

function var_0_0.createFishReward(arg_7_0)
	local var_7_0 = display.newNode()

	var_7_0:setContentSize(700, 270)

	local var_7_1 = xyd.tables.activitySummerGoldfish
	local var_7_2 = var_7_1:fishCount()
	local var_7_3 = math.ceil(var_7_2 / 2)

	for iter_7_0 = 1, var_7_2 do
		local var_7_4 = var_7_1:getIdByOrder(iter_7_0)
		local var_7_5 = display.newNode()

		var_7_5:setContentSize(100, 100)

		local var_7_6 = {
			size = 24,
			color = cc.c3b(210, 84, 16)
		}
		local var_7_7 = xyd.AssetLoader.get():loadLabel(var_7_6)

		var_7_7:setString(tostring(var_7_1:pt(var_7_4)) .. var_0_1:translation("POINT_TEXT2"))
		var_7_7:addTo(var_7_5)
		var_7_7:setAnchorPoint(cc.p(0.5, 0))
		var_7_7:setPosition(cc.p(50, -55))

		local var_7_8 = xyd.AssetLoader.get():loadLabel(var_7_6)

		var_7_8:setString(string.format(var_0_1:translation("FISH_FORMAT"), var_7_1:color(var_7_4)))
		var_7_8:addTo(var_7_5)
		var_7_8:setAnchorPoint(cc.p(0.5, 0))
		var_7_8:setPosition(cc.p(50, -25))

		local var_7_9 = arg_7_0.summer:createEffect(var_0_2)

		var_7_9:play(nil, true, nil, var_7_4)
		var_7_9:setScale(0.6666666666666666)
		var_7_9:addTo(var_7_5)
		var_7_9:setAnchorPoint(cc.p(0.5, 0.5))
		var_7_9:setPosition(cc.p(0, 40))
		var_7_9:setRotation(90)
		var_7_5:addTo(var_7_0)
		var_7_5:setAnchorPoint(cc.p(0, 1))

		if iter_7_0 <= var_7_3 then
			var_7_5:setPosition(cc.p(170 * (iter_7_0 - 1) + 50, 310))
		else
			var_7_5:setPosition(cc.p(170 * (iter_7_0 - var_7_3 - 1) + 50, 170))
		end
	end

	return var_7_0
end

function var_0_0.createHeadFrameReward(arg_8_0)
	local var_8_0 = xyd.tables.misc.summerGoldFishTopReward
	local var_8_1 = display.newNode()

	var_8_1:setContentSize(700, 100)

	local var_8_2 = display.newNode()

	var_8_2:setContentSize(100, 100)
	var_8_2:addTo(var_8_1)
	var_8_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_2:setPosition(350, 70)
	xyd.setItemBorder(var_8_2, var_8_0)

	local var_8_3 = {
		size = 24,
		color = cc.c3b(145, 51, 0)
	}
	local var_8_4 = xyd.AssetLoader.get():loadLabel(var_8_3)

	var_8_4:setString(xyd.tables.item:name(var_8_0))
	var_8_4:addTo(var_8_2)
	var_8_4:setAnchorPoint(cc.p(0.5, 0))
	var_8_4:setPosition(cc.p(50, -30))

	return var_8_1
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevY_ = arg_9_1.y
	elseif arg_9_1.name == "moved" and 5 <= math.abs(arg_9_1.y - arg_9_0.prevY_) then
		arg_9_0.scrollViewMoved_ = true
	end
end

return var_0_0
