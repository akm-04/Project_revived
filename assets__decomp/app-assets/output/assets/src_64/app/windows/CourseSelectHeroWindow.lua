local var_0_0 = class("CourseSelectHeroWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = 5
local var_0_2 = 1
local var_0_3 = import("app.windows.EquipItem")
local var_0_4 = xyd.tables.heroTable

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.course = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)
	arg_1_0.studyInfos = arg_1_0.course.roomInfo.study_infos

	if arg_1_2 then
		arg_1_0.isApplyCourse = arg_1_2.is_apply_course
		arg_1_0.callback = arg_1_2.callback
		arg_1_0.courseId = arg_1_2.course_id
	end

	arg_1_0.tmpHeros_ = {}
	arg_1_0.totalHero_ = {}
	arg_1_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_1_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initBaseInfo()
	arg_2_0:layout()
end

function var_0_0.initBaseInfo(arg_3_0)
	arg_3_0.heros_ = clone(arg_3_0.player_.heros_)

	table.sort(arg_3_0.heros_, function(arg_4_0, arg_4_1)
		if not arg_3_0:checkHeroCannotSelect(arg_4_0) and arg_3_0:checkHeroCannotSelect(arg_4_1) then
			return true
		elseif not arg_3_0:checkHeroCannotSelect(arg_4_1) and arg_3_0:checkHeroCannotSelect(arg_4_0) then
			return false
		end

		if arg_4_0:canSummon() and not arg_4_1:canSummon() then
			return true
		elseif arg_4_1:canSummon() and not arg_4_0:canSummon() then
			return false
		end

		return xyd.heroNormalSort(arg_4_0, arg_4_1) or false
	end)
	arg_3_0:initHeros(arg_3_0.heros_)

	arg_3_0.tmpHeros_ = arg_3_0.heros_
end

function var_0_0.layout(arg_5_0)
	arg_5_0:initMenu()

	local var_5_0 = arg_5_0:nodeByName("hero_list")

	arg_5_0.heroListWidth = var_5_0:getContentSize().width
	arg_5_0.heroListHeight = var_5_0:getContentSize().height
	arg_5_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, 710, 540),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_5_0):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.heroList_:setDelegate(handler(arg_5_0, arg_5_0.heroDelegate))
end

function var_0_0.initMenu(arg_6_0)
	arg_6_0.heroClassButtons_ = {}

	local var_6_0 = arg_6_0:nodeByName("background")

	table.insert(arg_6_0.heroClassButtons_, arg_6_0:nodeByName("quanbu_button"))
	table.insert(arg_6_0.heroClassButtons_, arg_6_0:nodeByName("qianpai_button"))
	table.insert(arg_6_0.heroClassButtons_, arg_6_0:nodeByName("zhongpai_button"))
	table.insert(arg_6_0.heroClassButtons_, arg_6_0:nodeByName("houpai_button"))

	for iter_6_0 = 1, #arg_6_0.heroClassButtons_ do
		arg_6_0.heroClassButtons_[iter_6_0]:setZoomScale(0.3)
		arg_6_0.heroClassButtons_[iter_6_0]:addTouchEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()
				arg_6_0:refreshSelectedHeroClass(iter_6_0)
			end
		end)
	end
end

function var_0_0.refreshSelectedHeroClass(arg_8_0, arg_8_1)
	arg_8_0.heroList_:removeAllItems()

	if arg_8_1 == 1 then
		arg_8_0.tmpHeros_ = arg_8_0.heros_
	elseif arg_8_1 == 2 then
		arg_8_0.tmpHeros_ = arg_8_0.totalHero_[xyd.DistanceType.QIANPAI]
	elseif arg_8_1 == 3 then
		arg_8_0.tmpHeros_ = arg_8_0.totalHero_[xyd.DistanceType.ZHONGPAI]
	elseif arg_8_1 == 4 then
		arg_8_0.tmpHeros_ = arg_8_0.totalHero_[xyd.DistanceType.HOUPAI]
	else
		arg_8_0.tmpHeros_ = arg_8_0.heros_
	end

	for iter_8_0 = 1, #arg_8_0.heroClassButtons_ do
		if arg_8_1 == iter_8_0 then
			arg_8_0.heroClassButtons_[iter_8_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_8_0.heroClassButtons_[iter_8_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_8_0.heroList_:reload()
end

function var_0_0.initHeros(arg_9_0, arg_9_1)
	for iter_9_0, iter_9_1 in pairs(arg_9_1) do
		if iter_9_1:getDistanceType() == xyd.DistanceType.QIANPAI then
			table.insert(arg_9_0.totalHero_[xyd.DistanceType.QIANPAI], iter_9_1)
		elseif iter_9_1:getDistanceType() == xyd.DistanceType.ZHONGPAI then
			table.insert(arg_9_0.totalHero_[xyd.DistanceType.ZHONGPAI], iter_9_1)
		elseif iter_9_1:getDistanceType() == xyd.DistanceType.HOUPAI then
			table.insert(arg_9_0.totalHero_[xyd.DistanceType.HOUPAI], iter_9_1)
		end
	end
end

function var_0_0.sortTables(arg_10_0, arg_10_1)
	for iter_10_0 = 1, #arg_10_1 do
		table.sort(arg_10_1[iter_10_0], function(arg_11_0, arg_11_1)
			if (arg_11_0.can_rent or arg_11_1.can_rent) and (not arg_11_0.can_rent or not arg_11_1.can_rent) then
				return arg_11_0.can_rent and not arg_11_1.can_rent
			end

			return xyd.heroNormalSort(arg_11_0, arg_11_1) or false
		end)
	end
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevY_ = arg_12_1.y
	elseif arg_12_1.name == "moved" and 0.5 <= math.abs(arg_12_1.y - arg_12_0.prevY_) then
		arg_12_0.scrollViewMoved_ = true
	end
end

function var_0_0.heroDelegate(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	if cc.ui.UIListView.COUNT_TAG == arg_13_2 then
		return (math.ceil(#arg_13_0.tmpHeros_ / var_0_1))
	elseif cc.ui.UIListView.CELL_TAG == arg_13_2 then
		local var_13_0 = arg_13_0.heroList_:dequeueItem()

		if not var_13_0 then
			var_13_0 = arg_13_0.heroList_:newItem()
		else
			var_13_0:removeAllChildren(true)
		end

		local var_13_1 = 710
		local var_13_2 = 130

		var_13_0:setItemSize(var_13_1, 130)

		local var_13_3 = display.newNode()

		var_13_3:setContentSize(var_13_1, 130)

		for iter_13_0 = 1, var_0_1 do
			local var_13_4 = (arg_13_3 - 1) * var_0_1 + iter_13_0

			if var_13_4 > #arg_13_0.tmpHeros_ then
				break
			end

			local var_13_5 = display.newNode()

			var_13_5:setContentSize(128, 128)
			var_13_5:setPosition(142 * iter_13_0 - 142 + 5 + 64, 64)
			var_13_5:setAnchorPoint(cc.p(0.5, 0.5))
			var_13_3:addChild(var_13_5)
			var_13_5:setTouchEnabled(true)
			var_13_5:setTouchSwallowEnabled(false)

			local var_13_6 = arg_13_0.tmpHeros_[var_13_4]

			xyd.setAvatarBorder(var_13_6, var_13_5, var_13_6:getColor(), var_13_6:getStar())

			local var_13_7 = xyd.AssetLoader.get():loadSprite("windows/common/lv_di.png")

			var_13_7:setScale(1.2)

			if arg_13_0:checkHeroCannotSelect(var_13_6) then
				local var_13_8 = xyd.AssetLoader.get():loadSprite("windows/fumo_hero/avatar_mask.png")

				var_13_8:setScale(1.1)
				var_13_8:setPosition(63, 62)
				var_13_5:addChild(var_13_8, 10)
				var_13_5:setTouchEnabled(false)
			end

			local var_13_9 = var_13_7:getWidth()
			local var_13_10 = var_13_5:getWidth()
			local var_13_11 = var_13_5:getHeight()

			var_13_7:setAnchorPoint(cc.p(0.5, 0.5))
			var_13_7:addTo(var_13_5)
			var_13_7:setPosition(var_13_9 / 2, var_13_11 / 3)

			local var_13_12 = {
				size = 16,
				color = cc.c3b(255, 255, 255)
			}
			local var_13_13 = xyd.AssetLoader.get():loadLabel(var_13_12)

			var_13_13:setString(var_13_6:getLevel())
			var_13_13:addTo(var_13_5)
			var_13_13:setAnchorPoint(cc.p(0.5, 0.5))
			var_13_13:setPosition(var_13_7:getPositionX() + 4, var_13_7:getPositionY() - 0.5)
			var_13_13:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
			var_13_5:getChildByName("border"):setLocalZOrder(var_13_13:getLocalZOrder() + 1)
			var_13_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
				if arg_14_0.name == "began" then
					var_13_5:setScale(0.9)

					return true
				elseif arg_14_0.name == "ended" then
					var_13_5:setScale(1)

					if not arg_13_0.scrollViewMoved_ then
						arg_13_0.callback(var_13_6)
						xyd.WindowManager.get():closeWindow(arg_13_0)
					end
				end
			end)
		end

		var_13_0:addContent(var_13_3)

		return var_13_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_13_2 then
		-- block empty
	end
end

function var_0_0.checkHeroCannotSelect(arg_15_0, arg_15_1)
	if not arg_15_0.isApplyCourse then
		return not arg_15_0:isCanStudy(arg_15_1)
	end

	local var_15_0 = arg_15_1:getCoursesInfo()

	if #table.keys(var_15_0) >= #arg_15_1:getCourseSkills() then
		return true
	end

	local var_15_1 = false

	if arg_15_0.courseId and xyd.isInTable(table.keys(var_15_0), tostring(arg_15_0.courseId)) then
		var_15_1 = true
	end

	return var_15_1
end

function var_0_0.isCanStudy(arg_16_0, arg_16_1)
	if arg_16_0.course:isPatnerInRoom(arg_16_1:getHeroID()) then
		return false
	end

	local var_16_0 = arg_16_1:getCoursesInfo()

	for iter_16_0, iter_16_1 in pairs(var_16_0) do
		if iter_16_1.progress < 100 then
			return true
		end
	end

	return false
end

function var_0_0.didOpen(arg_17_0)
	arg_17_0:addBlockLayer()
	arg_17_0:refreshSelectedHeroClass(var_0_2)
end

return var_0_0
