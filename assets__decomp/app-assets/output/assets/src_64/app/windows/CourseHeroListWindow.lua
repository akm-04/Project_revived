local var_0_0 = class("CourseHeroListWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.objectSubject
local var_0_3 = xyd.tables.objectClass
local var_0_4 = xyd.tables.objectBook
local var_0_5 = 4
local var_0_6 = "windows/course/hero_list/"
local var_0_7 = {
	var_0_1:translation("ALL_BUTTON"),
	var_0_1:translation("QIANPAI_BUTTON"),
	var_0_1:translation("ZHONGPAI_BUTTON"),
	var_0_1:translation("HOUPAI_BUTTON")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.course = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.currentListIndex = 1
	arg_1_0.currentStoryItemContainer = nil
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.tmpHeros_ = {}
	arg_1_0.totalHero_ = {}
	arg_1_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_1_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.HOUPAI] = {}

	arg_1_0:initBaseInfo()
end

function var_0_0.initBaseInfo(arg_2_0)
	arg_2_0.heros_ = arg_2_0.course:sortHeros(clone(arg_2_0.selfPlayer.heros_))

	arg_2_0:initHeros(arg_2_0.heros_)

	arg_2_0.tmpHeros_ = arg_2_0.heros_
end

function var_0_0.initHeros(arg_3_0, arg_3_1)
	for iter_3_0, iter_3_1 in pairs(arg_3_1) do
		if iter_3_1:getDistanceType() == xyd.DistanceType.QIANPAI then
			table.insert(arg_3_0.totalHero_[xyd.DistanceType.QIANPAI], iter_3_1)
		elseif iter_3_1:getDistanceType() == xyd.DistanceType.ZHONGPAI then
			table.insert(arg_3_0.totalHero_[xyd.DistanceType.ZHONGPAI], iter_3_1)
		elseif iter_3_1:getDistanceType() == xyd.DistanceType.HOUPAI then
			table.insert(arg_3_0.totalHero_[xyd.DistanceType.HOUPAI], iter_3_1)
		end
	end
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super:willOpen(arg_4_1)
	arg_4_0:layout()
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:addBlockLayer()
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("txt_title"):setString(var_0_1:translation("COURSE_TEXT_18"))

	arg_6_0.listContainer = arg_6_0:nodeByName("list_container")
	arg_6_0.detailContainer = arg_6_0:nodeByName("detail_container")

	local var_6_0 = arg_6_0.listContainer:getContentSize()

	arg_6_0.listScroll = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_6_0.width, var_6_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_6_0.listContainer):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.listScroll:setBounceable(true)
	arg_6_0.listScroll:setDelegate(handler(arg_6_0, arg_6_0.listScrollDelegate))
	arg_6_0.listScroll:reload()

	local var_6_1 = arg_6_0.detailContainer:getContentSize()

	arg_6_0.detailScroll = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_6_1.width, var_6_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_6_0.detailContainer):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.detailScroll:setBounceable(true)
	arg_6_0.detailScroll:setDelegate(handler(arg_6_0, arg_6_0.detailScrollDelegate))
	arg_6_0.detailScroll:reload()
end

function var_0_0.listScrollDelegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return #var_0_7
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_0 = arg_7_0.listScroll:dequeueItem()

		if not var_7_0 then
			var_7_0 = arg_7_0.listScroll:newItem()
		else
			var_7_0:removeAllChildren(true)
		end

		local var_7_1 = arg_7_0:creatListItemContent(arg_7_3)
		local var_7_2 = var_7_1:getWidth()
		local var_7_3 = var_7_1:getHeight()

		var_7_0:setItemSize(var_7_2, var_7_3 + 4)
		var_7_0:addContent(var_7_1)
		var_7_1:setPositionY(2)

		return var_7_0
	end
end

function var_0_0.creatListItemContent(arg_8_0, arg_8_1)
	local var_8_0 = display.newNode()
	local var_8_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/course/hero_list/list_item.csb")
	local var_8_2 = var_8_1:getChildByName("container")

	var_8_2:getChildByName("txt_name"):setString(var_0_7[arg_8_1])

	if arg_8_1 == arg_8_0.currentListIndex then
		arg_8_0.currentStoryItemContainer = var_8_2
		arg_8_0.currentItemBtn = var_8_2:getChildByName("select_btn")

		arg_8_0.currentItemBtn:setBrightStyle(ccui.BrightStyle.highlight)
	else
		var_8_2:getChildByName("select_btn"):setBrightStyle(ccui.BrightStyle.normal)
	end

	var_8_2:getChildByName("select_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended and arg_8_0.scrollViewMoved_ ~= true then
			if arg_8_0.currentListIndex ~= arg_8_1 and arg_8_0.currentItemBtn then
				arg_8_0.currentItemBtn:setBrightStyle(ccui.BrightStyle.normal)
			end

			arg_8_0.currentStoryItemContainer = var_8_2
			arg_8_0.currentItemBtn = var_8_2:getChildByName("select_btn")

			arg_8_0.currentItemBtn:setBrightStyle(ccui.BrightStyle.highlight)

			arg_8_0.currentListIndex = arg_8_1

			arg_8_0:refreshSelectedHeroClass()
		end
	end)
	var_8_1:addTo(var_8_0)
	var_8_1:setAnchorPoint(cc.p(0, 0))
	var_8_0:setContentSize(var_8_2:getContentSize())
	var_8_1:setName("source")

	return var_8_0
end

function var_0_0.refreshSelectedHeroClass(arg_10_0)
	local var_10_0 = arg_10_0.currentListIndex

	arg_10_0.detailScroll:removeAllItems()

	if var_10_0 == 1 then
		arg_10_0.tmpHeros_ = arg_10_0.heros_
	elseif var_10_0 == 2 then
		arg_10_0.tmpHeros_ = arg_10_0.totalHero_[xyd.DistanceType.QIANPAI]
	elseif var_10_0 == 3 then
		arg_10_0.tmpHeros_ = arg_10_0.totalHero_[xyd.DistanceType.ZHONGPAI]
	elseif var_10_0 == 4 then
		arg_10_0.tmpHeros_ = arg_10_0.totalHero_[xyd.DistanceType.HOUPAI]
	else
		arg_10_0.tmpHeros_ = arg_10_0.heros_
	end

	arg_10_0.detailScroll:reload()
end

function var_0_0.detailScrollDelegate(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	if cc.ui.UIListView.COUNT_TAG == arg_11_2 then
		return math.ceil(#arg_11_0.tmpHeros_ / var_0_5)
	elseif cc.ui.UIListView.CELL_TAG == arg_11_2 then
		local var_11_0 = arg_11_0.detailScroll:dequeueItem()

		if not var_11_0 then
			var_11_0 = arg_11_0.detailScroll:newItem()
		else
			var_11_0:removeAllChildren(true)
		end

		local var_11_1 = arg_11_0:creatDetailItemContent(arg_11_3)
		local var_11_2 = var_11_1:getWidth()
		local var_11_3 = var_11_1:getHeight()

		var_11_0:setItemSize(var_11_2, var_11_3 + 20)
		var_11_0:addContent(var_11_1)

		return var_11_0
	end
end

function var_0_0.creatDetailItemContent(arg_12_0, arg_12_1)
	local var_12_0 = display.newNode()
	local var_12_1 = 200
	local var_12_2 = 87
	local var_12_3 = 0

	var_12_0:setContentSize(774, 204)

	for iter_12_0 = 1, var_0_5 do
		if (arg_12_1 - 1) * var_0_5 + iter_12_0 <= #arg_12_0.tmpHeros_ then
			local var_12_4 = arg_12_0.tmpHeros_[(arg_12_1 - 1) * var_0_5 + iter_12_0]
			local var_12_5 = arg_12_0:createHeroItemContent(var_12_4)

			var_12_5:setContentSize(173, 204)
			var_12_5:setAnchorPoint(cc.p(0.5, 0))
			var_12_5:addTo(var_12_0)
			var_12_5:setPosition(cc.p(var_12_2, var_12_3))

			var_12_2 = var_12_2 + var_12_1
		end
	end

	return var_12_0
end

function var_0_0.createHeroItemContent(arg_13_0, arg_13_1)
	local var_13_0 = arg_13_0.selfPlayer:getHero(arg_13_1:getHeroID())
	local var_13_1 = display.newNode()
	local var_13_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/course/hero_list/item.csb")

	container = var_13_2:getChildByName("container")

	container:getChildByName("hero_name_txt"):setString(var_13_0:getName())
	xyd.setAvatarBorderNewUI(var_13_0, container:getChildByName("icon_container"), nil, 0)

	local var_13_3 = var_13_0:getCoursesInfo()
	local var_13_4 = "windows/course/hero_list/course_icon.png"

	for iter_13_0 = 1, #table.keys(var_13_3) do
		local var_13_5 = xyd.AssetLoader.get():loadSprite(var_13_4)

		var_13_5:addTo(container:getChildByName("icon_container"))
		var_13_5:setAnchorPoint(cc.p(0, 0))
		var_13_5:setPosition(cc.p((iter_13_0 - 1) * 22 + 8, 8))
	end

	var_13_2:setTouchEnabled(true)
	var_13_2:setTouchSwallowEnabled(false)
	var_13_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		if arg_14_0.name == "began" then
			var_13_2:setScale(0.9)

			return true
		elseif arg_14_0.name == "ended" then
			var_13_2:setScale(1)

			if arg_13_0.scrollViewMoved_ then
				return
			end

			xyd.playButtonSound()

			local var_14_0 = {
				partner_id = var_13_0:getHeroID()
			}

			arg_13_0.course:getCourseInfo(var_14_0, function(arg_15_0, arg_15_1)
				if arg_15_0 == xyd.error.OK then
					local var_15_0 = {
						hero = var_13_0,
						partner_courses = arg_15_1.partner_courses,
						study_infos = arg_15_1.study_infos or {}
					}

					if arg_13_0.callback then
						arg_13_0.callback(var_15_0)
					end

					arg_13_0:close()
				end
			end)
		end
	end)
	var_13_2:addTo(var_13_1)
	var_13_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_13_2:setPosition(cc.p(0, 0))
	var_13_1:setContentSize(container:getContentSize())
	var_13_2:setName("source")

	return var_13_1
end

function var_0_0.scrollListener(arg_16_0, arg_16_1)
	if arg_16_1.name == "began" then
		arg_16_0.scrollViewMoved_ = false
		arg_16_0.prevY_ = arg_16_1.y
	elseif arg_16_1.name == "moved" and 10 <= math.abs(arg_16_1.y - arg_16_0.prevY_) then
		arg_16_0.scrollViewMoved_ = true
	end
end

return var_0_0
