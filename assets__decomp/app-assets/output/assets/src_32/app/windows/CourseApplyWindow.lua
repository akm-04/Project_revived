local var_0_0 = class("CourseApplyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.objectClass
local var_0_3 = xyd.tables.objectBook

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.course = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.departmentId = arg_1_2.departmentId
	arg_1_0.bookIds = var_0_2:book(arg_1_0.departmentId)
	arg_1_0.currentSelectId = nil
	arg_1_0.currentSelectIcon = nil

	if arg_1_2.hero then
		arg_1_0.selectHero = arg_1_2.hero
	end

	if arg_1_0.selectHero and not arg_1_0.selectHero:canApplyCourse() then
		arg_1_0.selectHero = nil
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("tip_txt"):setString(var_0_1:translation("COURSE_APPLY_TEXT"))
	arg_3_0:nodeByName("apply_partner_text"):setString(var_0_1:translation("APPLY_PARTENER_TEXT"))
	arg_3_0:nodeByName("cost_text"):setString(var_0_1:translation("COST_TEXT"))
	arg_3_0:nodeByName("apply_course_text"):setString(var_0_1:translation("APPLY_COURSE_TEXT"))
	arg_3_0:nodeByName("own_text"):setString("(" .. var_0_1:translation("ITEM_OWN"))
	arg_3_0:nodeByName("num_text"):setString(var_0_1:translation("ITEM_OWN_SUFFIX") .. ")")

	local var_3_0 = var_0_2:application(arg_3_0.departmentId)
	local var_3_1 = arg_3_0.backpack:getItemNumByID(var_3_0)

	arg_3_0:nodeByName("own_num_txt"):setString(var_3_1)

	if var_3_1 > 0 then
		xyd.setItemBorder(arg_3_0:nodeByName("application_icon"), var_3_0)
	else
		xyd.setItemBorder(arg_3_0:nodeByName("application_icon"), var_3_0, nil, true)
	end

	arg_3_0.scroll = arg_3_0:nodeByName("course_scroll")

	local var_3_2 = arg_3_0.scroll:getContentSize()

	arg_3_0.courseList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_2.width, var_3_2.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.courseList:setBounceable(false)
	arg_3_0.courseList:setDelegate(handler(arg_3_0, arg_3_0.courseListDelegate))
	arg_3_0.courseList:setTouchType(false)
	arg_3_0.courseList:reload()
	arg_3_0:setButtonClick()
	arg_3_0:updateSelectHero()
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0:nodeByName("add_icon"):setTouchEnabled(true)
	arg_4_0:nodeByName("add_icon"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			arg_4_0:nodeByName("add_icon"):setScale(0.9)

			return true
		elseif arg_5_0.name == "ended" then
			xyd.playButtonSound()
			arg_4_0:nodeByName("add_icon"):setScale(1)

			local function var_5_0(arg_6_0)
				arg_4_0.selectHero = arg_6_0

				arg_4_0:updateSelectHero()
			end

			local var_5_1 = {
				course_id = arg_4_0.currentSelectId
			}

			var_5_1.is_apply_course = true
			var_5_1.callback = var_5_0

			xyd.WindowManager.get():openWindow("course_select_hero", var_5_1)
		end
	end)
	arg_4_0:nodeByName("sure_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_7_0 = var_0_2:application(arg_4_0.departmentId)

			if arg_4_0.backpack:getItemNumByID(var_7_0) < 1 then
				local var_7_1 = string.format(var_0_1:translation("COURSE_APPLY_ITEM_NOT_ENOUGH"), xyd.tables.item:name(var_7_0))

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_1
				})

				return
			elseif not arg_4_0.currentSelectId then
				local var_7_2 = var_0_1:translation("COURSE_APPLY_TEXT")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_2
				})

				return
			elseif not arg_4_0.selectHero then
				local var_7_3 = var_0_1:translation("COURSE_APPLY_SELECT_HERO")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_3
				})

				return
			end

			local var_7_4 = {
				partner_id = arg_4_0.selectHero:getHeroID(),
				course_id = arg_4_0.currentSelectId
			}

			arg_4_0.course:applyCourse(var_7_4, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					local var_8_0 = var_0_2:application(arg_4_0.departmentId)
					local var_8_1 = {}

					var_8_1.itemNum = 1
					var_8_1.itemID = var_8_0

					arg_4_0.selfPlayer:getBackpack():removeItem(var_8_1)

					local var_8_2 = {
						hero = arg_4_0.selectHero,
						course_id = arg_4_0.currentSelectId
					}

					xyd.WindowManager.get():openWindow("course_apply_succeed", var_8_2)
					dump(#arg_4_0.selfPlayer.heros_)
					xyd.WindowManager.get():closeWindow(arg_4_0)
				end
			end)
		end
	end)
end

function var_0_0.updateSelectHero(arg_9_0)
	if not arg_9_0.selectHero then
		arg_9_0:nodeByName("add_icon"):setOpacity(255)
		arg_9_0:nodeByName("hero_container"):setVisible(false)
	else
		arg_9_0:nodeByName("add_icon"):setOpacity(0)
		arg_9_0:nodeByName("hero_container"):removeAllChildren(true)
		arg_9_0:nodeByName("hero_container"):setVisible(true)
		xyd.setAvatarBorder(arg_9_0.selectHero, arg_9_0:nodeByName("hero_container"))
	end

	arg_9_0.courseList:reload()
end

function var_0_0.courseListDelegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return #arg_10_0.bookIds
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_0
		local var_10_1 = arg_10_0.courseList:dequeueItem()

		if not var_10_1 then
			var_10_1 = arg_10_0.courseList:newItem()
		else
			var_10_1:removeAllChildren(true)
		end

		local var_10_2 = arg_10_0:createBookItem(arg_10_0.bookIds[arg_10_3])
		local var_10_3 = var_10_2:getWidth()
		local var_10_4 = var_10_2:getHeight()

		var_10_1:setItemSize(var_10_3, var_10_4)
		var_10_1:addContent(var_10_2)

		return var_10_1
	end
end

function var_0_0.createBookItem(arg_11_0, arg_11_1)
	local var_11_0 = 50
	local var_11_1 = display.newNode()

	var_11_1:setContentSize(var_11_0, var_11_0)

	local var_11_2 = var_0_3:icon(arg_11_1)
	local var_11_3 = {}

	if arg_11_0.selectHero then
		var_11_3 = arg_11_0.selectHero:getCoursesInfo()
	end

	var_11_1:setTouchEnabled(true)

	if xyd.isInTable(table.keys(var_11_3), tostring(arg_11_1)) then
		var_11_1:setTouchEnabled(false)
		xyd.setSpriteBorder(var_11_1, var_11_2, 1, true)
	else
		xyd.setSpriteBorder(var_11_1, var_11_2, 1, false)
	end

	local var_11_4 = xyd.AssetLoader.get():loadSprite("windows/course/apply/selected.png")

	var_11_4:setScale(var_11_0 / var_11_4:getContentSize().width)
	var_11_4:addTo(var_11_1)
	var_11_4:setPosition(cc.p(var_11_0 / 2, var_11_0 / 2))
	var_11_4:setName("selected")
	var_11_4:setVisible(false)

	if arg_11_0.currentSelectId == arg_11_1 then
		var_11_4:setVisible(true)

		arg_11_0.currentSelectIcon = var_11_4
	end

	var_11_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
		if arg_12_0.name == "began" then
			var_11_1:setScale(0.9)

			return true
		elseif arg_12_0.name == "ended" then
			xyd.playButtonSound()
			var_11_1:setScale(1)

			arg_11_0.currentSelectId = arg_11_1

			if arg_11_0.currentSelectIcon then
				arg_11_0.currentSelectIcon:setVisible(false)
			end

			arg_11_0.currentSelectIcon = var_11_4

			arg_11_0.currentSelectIcon:setVisible(true)
			arg_11_0:nodeByName("tip_txt"):setString(var_0_3:name(arg_11_0.currentSelectId))
		end
	end)

	return var_11_1
end

function var_0_0.scrollListener(arg_13_0, arg_13_1)
	if arg_13_1.name == "began" then
		arg_13_0.scrollViewMoved_ = false
		arg_13_0.prevY_ = arg_13_1.y
	elseif arg_13_1.name == "moved" and 5 <= math.abs(arg_13_1.y - arg_13_0.prevY_) then
		arg_13_0.scrollViewMoved_ = true
	end
end

return var_0_0
