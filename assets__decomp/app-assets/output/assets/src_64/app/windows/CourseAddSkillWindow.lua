local var_0_0 = class("CourseAddSkillWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.objectBook
local var_0_4 = xyd.tables.skill

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.course = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.idx = arg_1_2.idx
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.skillId = arg_1_2.skill_id
	arg_1_0.callback = arg_1_2.callback

	arg_1_0:initCourseInfo()
end

function var_0_0.initCourseInfo(arg_2_0)
	local var_2_0 = arg_2_0.hero:getCoursesInfo()

	arg_2_0.coursesInfo = {}
	arg_2_0.defaultCourseId = 0

	for iter_2_0, iter_2_1 in pairs(var_2_0) do
		if iter_2_1.progress >= 100 then
			local var_2_1 = clone(iter_2_1)

			var_2_1.course_id = iter_2_0

			table.insert(arg_2_0.coursesInfo, var_2_1)
		end
	end

	table.sort(arg_2_0.coursesInfo, function(arg_3_0, arg_3_1)
		return arg_3_0.course_id < arg_3_1.course_id
	end)

	for iter_2_2, iter_2_3 in ipairs(arg_2_0.coursesInfo) do
		if iter_2_3.add_skill == arg_2_0.idx then
			arg_2_0.defaultCourseId = iter_2_3.course_id
			arg_2_0.selectCourseId = iter_2_3.course_id
			arg_2_0.selectIndex = iter_2_2

			break
		end
	end
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super.willOpen(arg_4_0, arg_4_1)
	arg_4_0:layout()
end

function var_0_0.didOpen(arg_5_0)
	arg_5_0:addBlockLayer()
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("skill_name_txt"):setString(var_0_4:name(arg_6_0.skillId))
	arg_6_0:nodeByName("txt_sure"):setString(var_0_1:translation("SURE"))
	arg_6_0:nodeByName("desc_txt"):getVirtualRenderer():setLineHeight(28)
	xyd.setSkillBorder(arg_6_0:nodeByName("icon_container"), arg_6_0.skillId, 1)

	for iter_6_0 = 1, #arg_6_0.coursesInfo do
		local var_6_0 = arg_6_0:createListContent(iter_6_0)

		var_6_0:setPosition(106 * (iter_6_0 - 1), 0)
		arg_6_0:nodeByName("course_scroll"):addChild(var_6_0)
	end

	local var_6_1 = arg_6_0:nodeByName("desc_scroll"):getContentSize()

	arg_6_0.descList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_6_1.width, var_6_1.height),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_6_0:nodeByName("desc_scroll")):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.descList:setBounceable(true)

	local var_6_2 = arg_6_0.descList:newItem()
	local var_6_3 = arg_6_0:createSkillDescLabel(arg_6_0.skillId)

	var_6_2:setItemSize(290, var_6_3:getContentSize().height)
	var_6_2:addContent(var_6_3)
	arg_6_0.descList:addItem(var_6_2)
	arg_6_0.descList:reload()
	arg_6_0:updateCourseInfo()
	arg_6_0:setButtonClick()
end

function var_0_0.updateCourseInfo(arg_7_0)
	if arg_7_0.selectIndex then
		arg_7_0:nodeByName("coursel_name_txt"):setString(var_0_3:name(arg_7_0.selectCourseId))

		local var_7_0 = arg_7_0:createSkillDescLabel(arg_7_0.selectCourseId)

		arg_7_0:nodeByName("desc_txt"):setString(var_0_3:des(arg_7_0.selectCourseId, arg_7_0.coursesInfo[arg_7_0.selectIndex].quality))
	else
		arg_7_0:nodeByName("coursel_name_txt"):setString("")
		arg_7_0:nodeByName("desc_txt"):setString("")
	end
end

function var_0_0.createSkillDescLabel(arg_8_0, arg_8_1)
	local var_8_0 = display.newNode()
	local var_8_1 = xyd.tables.skill:desc(arg_8_1)
	local var_8_2 = {
		font = "fonts/main_font.ttf",
		size = 22,
		color = cc.c3b(82, 81, 71)
	}
	local var_8_3 = xyd.AssetLoader.get():loadLabel(var_8_2)

	var_8_3:setMaxLineWidth(270)
	var_8_3:setLineHeight(26)
	var_8_3:setString(var_8_1)
	var_8_3:setAnchorPoint(0, 0)
	var_8_0:setContentSize(290, var_8_3:getContentSize().height)
	var_8_0:addChild(var_8_3)

	return var_8_0
end

function var_0_0.setButtonClick(arg_9_0)
	arg_9_0:nodeByName("sure_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_10_0, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if not arg_9_0.selectCourseId then
				return
			end

			if arg_9_0.defaultCourseId == arg_9_0.selectCourseId then
				return
			end

			local var_10_0 = {
				partner_id = arg_9_0.hero:getHeroID(),
				course_id = arg_9_0.selectCourseId,
				skill_index = arg_9_0.idx
			}

			arg_9_0.course:addSkill(var_10_0, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					arg_9_0.callback(arg_11_1.partner_courses)
					arg_9_0:close()
				end
			end)
		end
	end)
end

function var_0_0.createListContent(arg_12_0, arg_12_1)
	local var_12_0 = arg_12_0.coursesInfo[arg_12_1].course_id
	local var_12_1 = display.newNode()

	var_12_1:setContentSize(88, 88)

	local var_12_2 = var_0_3:icon(var_12_0)

	xyd.setSpriteBorder(var_12_1, var_12_2, arg_12_0.coursesInfo[arg_12_1].quality)

	if arg_12_0.selectCourseId == var_12_0 then
		arg_12_0:addSelectEffectForItem(var_12_1)
	end

	var_12_1:setTouchEnabled(true)
	var_12_1:setTouchSwallowEnabled(false)
	var_12_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			return true
		elseif arg_13_0.name == "ended" then
			xyd.playButtonSound()

			arg_12_0.selectCourseId = var_12_0
			arg_12_0.selectIndex = arg_12_1

			arg_12_0:addSelectEffectForItem(var_12_1)
			arg_12_0:updateCourseInfo()
		end
	end)

	return var_12_1
end

function var_0_0.addSelectEffectForItem(arg_14_0, arg_14_1)
	if arg_14_0.selectEffect and not tolua.isnull(arg_14_0.selectEffect) then
		arg_14_0.selectEffect:removeFromParent(false)
	else
		arg_14_0.selectEffect = xyd.AssetLoader.get():loadSprite("windows/course/main/select.png")

		local var_14_0 = cc.ScaleBy:create(0.3, 1.04)
		local var_14_1 = transition.sequence({
			var_14_0,
			var_14_0:reverse()
		})
		local var_14_2 = cc.RepeatForever:create(var_14_1)

		arg_14_0.selectEffect:runAction(var_14_2)
		arg_14_0.selectEffect:setNormalizedPosition(cc.p(0.5, 0.5))
		arg_14_0.selectEffect:setScale(1.16)
	end

	arg_14_1:addChild(arg_14_0.selectEffect)
end

function var_0_0.scrollListener(arg_15_0, arg_15_1)
	if arg_15_1.name == "began" then
		arg_15_0.scrollViewMoved_ = false
		arg_15_0.prevX_ = arg_15_1.x
	elseif arg_15_1.name == "moved" and 5 <= math.abs(arg_15_1.x - arg_15_0.prevX_) then
		arg_15_0.scrollViewMoved_ = true
	end
end

return var_0_0
