local var_0_0 = class("CourseInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.objectBook
local var_0_3 = xyd.tables.objectBookColor

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.course = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)
	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("zhandouli_text"):setString(var_0_1:translation("HERO_ZHANDOULI_UP_TEXT"))
	arg_3_0:nodeByName("hero_name_txt"):setString(arg_3_0.hero:getName())
	arg_3_0:nodeByName("zhandouli_txt"):setString(arg_3_0.hero:getCoursesForce())
	arg_3_0.library:updateCardContainer(arg_3_0.hero, arg_3_0:nodeByName("card_container"))
	arg_3_0:nodeByName("card_container"):getChildByName("card"):setScale(0.8)

	arg_3_0.scroll = arg_3_0:nodeByName("course_scroll")

	local var_3_0 = arg_3_0.scroll:getContentSize()

	arg_3_0.courseList = cc.ui.UIListView.new({
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

	arg_3_0.courseList:setDelegate(handler(arg_3_0, arg_3_0.courseListDelegate))
	arg_3_0.courseList:setTouchType(false)
	arg_3_0.courseList:reload()
	arg_3_0:setButtonClick()
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0:nodeByName("recommend_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_5_0 = {
				table_id = arg_4_0.hero:getFirstTableID()
			}

			arg_4_0.course:getCoursesRecommend(var_5_0, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK and arg_4_0 and not tolua.isnull(arg_4_0) then
					local var_6_0 = {
						hero = arg_4_0.hero,
						data = arg_6_1.recommend_list
					}

					xyd.WindowManager.get():openWindow("course_recommend", var_6_0)
				end
			end)
		end
	end)
end

function var_0_0.courseListDelegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	arg_7_0.coursesInfo = arg_7_0.hero:getCoursesInfo()
	arg_7_0.coursesIds = table.keys(arg_7_0.coursesInfo)
	arg_7_0.courseSkillIds = arg_7_0.hero:getCourseSkills()

	table.sort(arg_7_0.coursesIds, function(arg_8_0, arg_8_1)
		return tonumber(arg_8_0) < tonumber(arg_8_1)
	end)

	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		if #table.keys(arg_7_0.coursesInfo) >= #arg_7_0.courseSkillIds then
			return #arg_7_0.coursesIds
		else
			return #arg_7_0.coursesIds + 1
		end
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_0
		local var_7_1 = arg_7_0.courseList:dequeueItem()

		if not var_7_1 then
			var_7_1 = arg_7_0.courseList:newItem()
		else
			var_7_1:removeAllChildren(true)
		end

		local var_7_2

		if arg_7_3 == #arg_7_0.coursesIds + 1 and #arg_7_0.coursesIds < #arg_7_0.courseSkillIds then
			var_7_2 = arg_7_0:createApplyBtnItem()
		else
			var_7_2 = arg_7_0:createListContent(arg_7_0.coursesIds[arg_7_3])
		end

		local var_7_3 = var_7_2:getWidth()
		local var_7_4 = var_7_2:getHeight()

		var_7_1:setItemSize(var_7_3, var_7_4)
		var_7_1:addContent(var_7_2)

		return var_7_1
	end
end

function var_0_0.createListContent(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_0.coursesInfo[arg_9_1]
	local var_9_1 = display.newNode()
	local var_9_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/course/course_info/item.csb")
	local var_9_3 = var_9_2:getChildByName("container")
	local var_9_4 = var_9_3:getChildByName("desc_pos")
	local var_9_5 = var_9_3:getChildByName("progress_container")
	local var_9_6 = tonumber(arg_9_1)

	var_9_3:getChildByName("course_name_txt"):setString(var_0_2:name(var_9_6))

	local var_9_7 = arg_9_0:createCourseDescLabel(var_9_6, var_9_0.quality)

	var_9_7:setAnchorPoint(cc.p(0, 1))
	var_9_7:addTo(var_9_3)
	var_9_7:setPosition(var_9_4:getPosition())

	if var_9_0.progress < 100 then
		var_9_3:getChildByName("add_icon"):setVisible(false)

		local var_9_8 = xyd.AssetLoader.get():loadSprite("windows/course/course_info/progress_bar.png")

		progressBar = display.newProgressTimer(var_9_8, display.PROGRESS_TIMER_RADIAL)

		progressBar:addTo(var_9_5, 1)
		progressBar:setPosition(cc.p(var_9_5:getContentSize().width / 2, var_9_5:getContentSize().height / 2))
		progressBar:setMidpoint(cc.p(0.5, 0.5))
		progressBar:setBarChangeRate(cc.p(1, 0))
		progressBar:setPercentage(var_9_0.progress)
		progressBar:setLocalZOrder(20)
		var_9_5:getChildByName("progress_bg"):setLocalZOrder(10)
		var_9_5:getChildByName("progress_txt"):setLocalZOrder(30)
		var_9_5:getChildByName("progress_txt"):setString(tostring(var_9_0.progress) .. "%")
	elseif var_9_0.add_skill ~= 0 then
		local var_9_9 = arg_9_0.hero:getSkillId()[var_9_0.add_skill]

		xyd.setSkillBorder(var_9_3:getChildByName("skill_container"), var_9_9, true)
		var_9_3:getChildByName("add_icon"):setOpacity(0)
		var_9_3:getChildByName("progress_container"):setVisible(false)
	else
		var_9_3:getChildByName("add_icon"):setVisible(true)
		var_9_3:getChildByName("add_icon"):setOpacity(255)
		var_9_5:setVisible(false)
	end

	local var_9_10 = var_0_2:icon(var_9_6)

	xyd.setSpriteBorder(var_9_3:getChildByName("icon_container"), var_9_10, var_9_0.quality)

	local var_9_11 = var_9_3:getChildByName("upgrade_btn")

	var_9_11:setBright(false)
	var_9_11:setTouchEnabled(false)
	var_9_11:getChildByName("arrow"):setVisible(false)

	if var_9_0.progress < 100 then
		-- block empty
	elseif var_9_0.quality >= var_0_3:maxColorLev() then
		-- block empty
	else
		var_9_11:setBright(true)
		var_9_11:setTouchEnabled(true)
		var_9_11:getChildByName("arrow"):setVisible(true)
	end

	var_9_3:getChildByName("upgrade_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local function var_10_0()
				if arg_9_0 and arg_9_0.courseList and not tolua.isnull(arg_9_0.courseList) then
					arg_9_0.courseList:refreshList()
					arg_9_0:nodeByName("zhandouli_txt"):setString(arg_9_0.selfPlayer:getHero(arg_9_0.hero:getHeroID()):getCoursesForce())
				end
			end

			local var_10_1 = {
				hero = arg_9_0.hero,
				course_id = var_9_6,
				callback = var_10_0
			}

			xyd.WindowManager.get():openWindow("course_upgrade", var_10_1)
		end
	end)
	var_9_3:getChildByName("forgot_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if xyd.tables.misc.objectClassForget > arg_9_0.selfPlayer.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
					local var_13_0 = {}

					var_13_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_13_0)
				end, nil, nil, arg_9_0.colorMode)

				return
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("COURSE_FORGOT_TIPS"), xyd.tables.misc.objectClassForget), function()
				local var_14_0 = {
					partner_id = arg_9_0.hero:getHeroID(),
					course_id = var_9_6
				}

				arg_9_0.course:forgetCourse(var_14_0, function(arg_15_0, arg_15_1)
					if arg_15_0 == xyd.error.OK then
						arg_9_0.courseList:reload()
						arg_9_0:nodeByName("zhandouli_txt"):setString(arg_9_0.selfPlayer:getHero(arg_9_0.hero:getHeroID()):getCoursesForce())
						arg_9_0.selfPlayer:handleRewards(arg_15_1.return_items)
					end
				end)
			end, nil, nil, arg_9_0.colorMode)
		end
	end)
	var_9_3:getChildByName("add_icon"):setTouchEnabled(true)
	var_9_3:getChildByName("add_icon"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			var_9_3:getChildByName("add_icon"):setScale(0.9)

			return true
		elseif arg_16_0.name == "ended" then
			xyd.playButtonSound()
			var_9_3:getChildByName("add_icon"):setScale(1)

			local function var_16_0(arg_17_0)
				if var_9_0.add_skill == arg_17_0 then
					return
				end

				local var_17_0 = {
					partner_id = arg_9_0.hero:getHeroID(),
					course_id = var_9_6,
					skill_index = arg_17_0
				}

				arg_9_0.course:addSkill(var_17_0, function(arg_18_0, arg_18_1)
					if arg_18_0 == xyd.error.OK then
						var_9_0.add_skill = arg_17_0

						arg_9_0.courseList:refreshList()
						arg_9_0:nodeByName("zhandouli_txt"):setString(arg_9_0.selfPlayer:getHero(arg_9_0.hero:getHeroID()):getCoursesForce())
					end
				end)
			end

			local var_16_1 = {
				hero = arg_9_0.hero,
				course_id = var_9_6,
				callback = var_16_0
			}

			xyd.WindowManager.get():openWindow("course_add_skill", var_16_1)
		end
	end)
	var_9_2:addTo(var_9_1)
	var_9_2:setAnchorPoint(cc.p(0, 0))

	local var_9_12 = var_9_7:getContentSize().height

	if var_9_12 > cc.p(var_9_4:getPosition()).y then
		var_9_1:setContentSize(var_9_3:getContentSize().width, var_9_3:getContentSize().height + var_9_12 - cc.p(var_9_4:getPosition()).y)
		var_9_2:setPosition(0, var_9_12 - cc.p(var_9_4:getPosition()).y)
	else
		var_9_1:setContentSize(var_9_3:getContentSize())
	end

	var_9_2:setName("source")

	return var_9_1
end

function var_0_0.createApplyBtnItem(arg_19_0)
	local var_19_0 = display.newNode()
	local var_19_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/course/course_info/item.csb")
	local var_19_2 = var_19_1:getChildByName("container")

	var_19_2:setVisible(false)

	local var_19_3 = var_19_1:getChildByName("apply_btn")

	var_19_3:setVisible(true)
	var_19_3:addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local function var_20_0()
				if arg_19_0 and arg_19_0.courseList and not tolua.isnull(arg_19_0.courseList) then
					arg_19_0.courseList:reload()
				end
			end

			local var_20_1 = {
				hero = arg_19_0.hero,
				callback = var_20_0
			}

			xyd.WindowManager.get():openWindow("course_list", var_20_1)
		end
	end)
	var_19_1:addTo(var_19_0)
	var_19_1:setAnchorPoint(cc.p(0, 0))
	var_19_1:setName("source")
	var_19_0:setContentSize(var_19_2:getContentSize())

	return var_19_0
end

function var_0_0.createCourseDescLabel(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = var_0_2:des(arg_22_1, arg_22_2)
	local var_22_1 = {
		font = "fonts/main_font.ttf",
		size = 18,
		color = cc.c3b(98, 97, 92)
	}
	local var_22_2 = xyd.AssetLoader.get():loadLabel(var_22_1)

	var_22_2:setMaxLineWidth(239)
	var_22_2:setString(var_22_0)

	return var_22_2
end

function var_0_0.scrollListener(arg_23_0, arg_23_1)
	if arg_23_1.name == "began" then
		arg_23_0.scrollViewMoved_ = false
		arg_23_0.prevY_ = arg_23_1.y
	elseif arg_23_1.name == "moved" and 5 <= math.abs(arg_23_1.y - arg_23_0.prevY_) then
		arg_23_0.scrollViewMoved_ = true
	end
end

function var_0_0.didClose(arg_24_0, arg_24_1)
	var_0_0.super.didClose(arg_24_0, arg_24_1)

	if arg_24_0.callback then
		arg_24_0.callback()
	end
end

return var_0_0
