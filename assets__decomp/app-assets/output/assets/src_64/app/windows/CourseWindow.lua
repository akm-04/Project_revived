local var_0_0 = class("CourseWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.objectSubject
local var_0_5 = xyd.tables.objectClass
local var_0_6 = xyd.tables.objectBook
local var_0_7 = xyd.tables.objectBranch
local var_0_8 = xyd.tables.skill
local var_0_9 = xyd.tables.hero
local var_0_10 = xyd.tables.item
local var_0_11 = xyd.tables.objectBookColor
local var_0_12 = xyd.tables.misc
local var_0_13 = {
	3,
	2,
	1,
	4
}
local var_0_14 = {}

var_0_14.Evolve = "skeletons/ui_effect/course/effect_object"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.course = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)
	arg_1_0.shop = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)
	arg_1_0.giftPush = xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.callback = arg_1_2.callback

	arg_1_0:initData()
end

function var_0_0.initData(arg_2_0)
	arg_2_0.usedItemNums = {}
	arg_2_0.handler = {}
	arg_2_0.courseList = {}
	arg_2_0.books = {}
	arg_2_0.timeLabel = {}
	arg_2_0.lvUpBtnCanUse = true
	arg_2_0.isStudying = false

	for iter_2_0 = 1, 4 do
		arg_2_0.books[iter_2_0] = {}

		for iter_2_1, iter_2_2 in ipairs(var_0_4:department(iter_2_0)) do
			for iter_2_3, iter_2_4 in ipairs(var_0_5:book(iter_2_2)) do
				table.insert(arg_2_0.books[iter_2_0], iter_2_4)
			end
		end
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:addTopSidebar({
		isEcoBar = 0,
		show_rule = true
	})
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_change"):setString(var_0_3:translation("COURSE_TEXT_1"))
	arg_4_0:nodeByName("txt_recommend"):setString(var_0_3:translation("COURSE_TEXT_2"))
	arg_4_0:nodeByName("txt_consume"):setString(var_0_3:translation("COURSE_TEXT_4"))
	arg_4_0:nodeByName("txt_learn"):setString(var_0_3:translation("COURSE_TEXT_5"))
	arg_4_0:nodeByName("txt_learn_2"):setString(var_0_3:translation("COURSE_TEXT_6"))
	arg_4_0:nodeByName("txt_abandon"):setString(var_0_3:translation("COURSE_TEXT_7"))
	arg_4_0:nodeByName("txt_accelerate"):setString(var_0_3:translation("COURSE_TEXT_8"))
	arg_4_0:nodeByName("txt_consume_2"):setString(var_0_3:translation("COURSE_TEXT_9"))
	arg_4_0:nodeByName("txt_forget"):setString(var_0_3:translation("COURSE_TEXT_10"))
	arg_4_0:nodeByName("txt_shop"):setString(var_0_3:translation("COURSE_TEXT_11"))
	arg_4_0:nodeByName("txt_shop"):enableOutline(cc.c4b(91, 30, 30, 255), 0)
	arg_4_0:nodeByName("txt_bar"):enableOutline(cc.c4b(87, 94, 103, 255), 2)
	arg_4_0:nodeByName("txt_bar_2"):enableOutline(cc.c4b(87, 94, 103, 255), 2)
	xyd.nodeEventSample(arg_4_0:nodeByName("top_sidebar"):nodeByName("rule"), nil, function()
		local var_5_0 = {
			title_name = "OBJECT_MAIN_RULE_TITLE",
			rule = "OBJECT_MAIN_RULE_TEXT",
			style = xyd.RuleStyle.YELLOW
		}

		xyd.WindowManager.get():openWindow("new_text_rule", var_5_0)
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_shop"), nil, function()
		local var_6_0 = {
			shop_type = xyd.ShopType.COURSE
		}

		arg_4_0.shop:loadShopInfo(var_6_0, function(arg_7_0, arg_7_1)
			if arg_7_0 == xyd.error.OK then
				arg_4_0.course:getGiftBoxInfo({}, function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("course_bookstore", arg_8_1)
					end
				end)
			end
		end)
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_change"), nil, function()
		local var_9_0 = {
			callback = handler(arg_4_0, arg_4_0.onSelectHero)
		}

		xyd.WindowManager.get():openWindow("course_hero_list", var_9_0)
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_recommend"), nil, function()
		arg_4_0.course:getCoursesRecommend({
			table_id = arg_4_0.hero:getFirstTableID()
		}, function(arg_11_0, arg_11_1)
			if arg_11_0 == xyd.error.OK then
				local var_11_0 = {
					hero = arg_4_0.hero,
					data = arg_11_1.recommend_list
				}

				xyd.WindowManager.get():openWindow("course_recommend", var_11_0)
			end
		end)
	end)
	arg_4_0:nodeByName("btn_forget"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_12_0, arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_3:translation("COURSE_FORGOT_TIPS"), var_0_12.objectClassForget), function()
				local var_13_0 = {
					partner_id = arg_4_0.hero:getHeroID(),
					course_id = arg_4_0.selectBookId
				}

				arg_4_0.course:forgetCourse(var_13_0, function(arg_14_0, arg_14_1)
					if arg_14_0 == xyd.error.OK then
						arg_4_0.selfPlayer:handleRewards(arg_14_1.return_items)
						arg_4_0:updateLevelUpItems()
						arg_4_0:refreshListBySelectCourse()
						arg_4_0:updateBottomLeftContainer()
						arg_4_0:updateBottomRightContainer()
					end
				end)
			end, nil, nil, arg_4_0.colorMode)
		end
	end)
	arg_4_0:nodeByName("btn_learn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		xyd.buttonScaleAnim(arg_15_0, arg_15_1)

		if arg_15_1 == ccui.TouchEventType.ended then
			if arg_4_0.isStudying then
				local var_15_0 = var_0_3:translation("COURSE_TEXT_12")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_15_0
				})

				return
			end

			local var_15_1 = var_0_6:classType(arg_4_0.selectBookId)
			local var_15_2 = var_0_5:application(var_15_1)

			if arg_4_0.backpack:getItemNumByID(var_15_2) < 1 then
				local var_15_3 = string.format(var_0_3:translation("COURSE_APPLY_ITEM_NOT_ENOUGH"), xyd.tables.item:name(var_15_2))

				xyd.WindowManager.get():openWindow("toast", {
					message = var_15_3
				})

				return
			elseif not arg_4_0.hero:canApplyCourse() then
				local var_15_4 = var_0_3:translation("COURSE_TEXT_13")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_15_4
				})

				return
			end

			if #arg_4_0.course.roomInfo.study_infos >= xyd.tables.vip:numStudy(arg_4_0.selfPlayer.vip) then
				local var_15_5 = var_0_3:translation("COURSE_TEXT_14")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_15_5
				})

				return
			end

			local var_15_6 = {
				partner_id = arg_4_0.hero:getHeroID(),
				course_id = arg_4_0.selectBookId
			}

			arg_4_0.course:study(var_15_6, function(arg_16_0, arg_16_1)
				if arg_16_0 == xyd.error.OK then
					arg_4_0.backpack:addItemsByID(var_15_2, -1)
					arg_4_0:refreshListBySelectCourse()
					arg_4_0:updateBottomRightContainer()
				end
			end)
		end
	end)
	arg_4_0:nodeByName("btn_learn_2"):addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(arg_17_0, arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended then
			if arg_4_0.isStudying then
				local var_17_0 = var_0_3:translation("COURSE_TEXT_12")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_17_0
				})

				return
			end

			if #arg_4_0.course.roomInfo.study_infos >= xyd.tables.vip:numStudy(arg_4_0.selfPlayer.vip) then
				local var_17_1 = var_0_3:translation("COURSE_TEXT_14")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_17_1
				})

				return
			end

			local var_17_2 = {
				partner_id = arg_4_0.hero:getHeroID(),
				course_id = arg_4_0.selectBookId
			}

			arg_4_0.course:continueStudy(var_17_2, function(arg_18_0, arg_18_1)
				if arg_18_0 == xyd.error.OK then
					arg_4_0:refreshListBySelectCourse()
					arg_4_0:updateBottomRightContainer()
				end
			end)
		end
	end)
	arg_4_0:nodeByName("btn_abandon"):addTouchEventListener(function(arg_19_0, arg_19_1)
		xyd.buttonScaleAnim(arg_19_0, arg_19_1)

		if arg_19_1 == ccui.TouchEventType.ended then
			if not arg_4_0.isStudying then
				return
			end

			local var_19_0 = var_0_3:translation("COURSE_TEXT_15")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_19_0, function()
				local var_20_0 = {
					partner_id = arg_4_0.hero:getHeroID(),
					course_id = arg_4_0.selectBookId
				}

				arg_4_0.course:forgetCourse(var_20_0, function(arg_21_0, arg_21_1)
					if arg_21_0 == xyd.error.OK then
						arg_4_0.isStudying = false

						arg_4_0.selfPlayer:handleRewards(arg_21_1.return_items)
						arg_4_0:refreshListBySelectCourse()
						arg_4_0:updateBottomRightContainer()
					end
				end)
			end, nil, nil, arg_4_0.colorMode)
		end
	end)
	arg_4_0:nodeByName("btn_accelerate"):addTouchEventListener(function(arg_22_0, arg_22_1)
		xyd.buttonScaleAnim(arg_22_0, arg_22_1)

		if arg_22_1 == ccui.TouchEventType.ended then
			if not arg_4_0.isStudying then
				return
			end

			local var_22_0

			for iter_22_0, iter_22_1 in ipairs(arg_4_0.course.roomInfo.study_infos) do
				if iter_22_1.partner_id == arg_4_0.hero:getHeroID() and iter_22_1.course_id == arg_4_0.selectBookId then
					var_22_0 = iter_22_1

					break
				end
			end

			if not var_22_0 then
				return
			end

			local var_22_1 = var_0_12.objectClassRoomMoney * math.ceil(arg_4_0:getDownTime(var_22_0) / 1800) / 2
			local var_22_2 = string.format(var_0_3:translation("COURSE_SPEED_COST_TIPS"), var_22_1)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_22_2, function()
				local var_23_0 = {
					partner_id = arg_4_0.hero:getHeroID(),
					course_id = arg_4_0.selectBookId
				}

				arg_4_0.course:speedStudy(var_23_0, function(arg_24_0, arg_24_1)
					if arg_24_0 == xyd.error.OK then
						arg_4_0.isStudying = false

						arg_4_0:refreshListBySelectCourse()
						arg_4_0:updateBottomRightContainer()
					end
				end)
			end, nil, nil, arg_4_0.colorMode)
		end
	end)
	arg_4_0:nodeByName("txt_course_desc"):getVirtualRenderer():setLineHeight(25)
	arg_4_0:updateLevelUpItems()
	arg_4_0:updateTopContainer()
	arg_4_0:updateBottomLeftContainer()
	arg_4_0:updateBottomRightContainer()
	arg_4_0:updateRedMarkShow()
end

function var_0_0.updateLevelUpItems(arg_25_0)
	if arg_25_0.handler[1] ~= nil then
		var_0_1.unscheduleGlobal(arg_25_0.handler[1])

		arg_25_0.handler[1] = nil
	end

	if arg_25_0.handler[2] ~= nil then
		var_0_1.unscheduleGlobal(arg_25_0.handler[2])

		arg_25_0.handler[2] = nil
	end

	local var_25_0 = var_0_12.objectBoxBooks

	arg_25_0:nodeByName("level_up_item"):removeAllChildren()

	for iter_25_0, iter_25_1 in ipairs(var_25_0) do
		local var_25_1 = display.newNode()
		local var_25_2 = arg_25_0.backpack:getItemNumByID(iter_25_1)

		var_25_1:setContentSize(64, 64)
		xyd.setItemBorder(var_25_1, iter_25_1, nil, nil, arg_25_0.backpack:getItemNumByID(iter_25_1), nil, true)
		var_25_1:setPosition(84 * (iter_25_0 - 1), 0)
		arg_25_0:nodeByName("level_up_item"):addChild(var_25_1)

		arg_25_0.usedItemNums[iter_25_1] = 0

		local var_25_3 = var_25_1:getChildByName("clipper"):getChildByName("digit_bg"):getChildByName("num_label")

		var_25_1:setTouchEnabled(true)
		var_25_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_26_0)
			if arg_26_0.name == "began" then
				if not arg_25_0.lvUpBtnCanUse then
					return false
				end

				if arg_25_0.hero:getCourseInfo(arg_25_0.selectBookId).exp >= var_0_11:maxTotalProficiency() then
					local var_26_0 = var_0_3:translation("COURSE_EXP_FULL")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_26_0
					})

					return false
				end

				local var_26_1 = 0

				local function var_26_2()
					if arg_25_0 and not tolua.isnull(arg_25_0) then
						var_26_1 = var_26_1 + 0.06
						var_25_2 = arg_25_0:addExp(var_25_2, iter_25_1, var_25_1)

						var_25_3:setString(var_25_2)
					end
				end

				local function var_26_3()
					if arg_25_0 and not tolua.isnull(arg_25_0) then
						var_26_1 = var_26_1 + 0.1

						if var_26_1 > 0.5 and var_26_1 <= 4 then
							arg_25_0.isLongTouch = true
							var_25_2 = arg_25_0:addExp(var_25_2, iter_25_1, var_25_1)

							var_25_3:setString(var_25_2)
						elseif var_26_1 > 4 then
							if arg_25_0.handler[2] ~= nil then
								var_0_1.unscheduleGlobal(arg_25_0.handler[2])

								arg_25_0.handler[2] = nil
							end

							arg_25_0.handler[2] = var_0_1.scheduleGlobal(var_26_2, 0.06)

							var_0_1.unscheduleGlobal(arg_25_0.handler[1])

							arg_25_0.handler[1] = nil
						else
							arg_25_0.isLongTouch = false
						end
					end
				end

				arg_25_0.isLongTouch = false

				if arg_25_0.handler[1] ~= nil then
					var_0_1.unscheduleGlobal(arg_25_0.handler[1])

					arg_25_0.handler[1] = nil
				end

				arg_25_0.handler[1] = var_0_1.scheduleGlobal(var_26_3, 0.1)

				return true
			elseif arg_26_0.name == "ended" then
				if arg_25_0.handler[1] ~= nil then
					var_0_1.unscheduleGlobal(arg_25_0.handler[1])

					arg_25_0.handler[1] = nil
				end

				if arg_25_0.handler[2] ~= nil then
					var_0_1.unscheduleGlobal(arg_25_0.handler[2])

					arg_25_0.handler[2] = nil
				end

				if not arg_25_0.isLongTouch then
					var_25_2 = arg_25_0:addExp(var_25_2, iter_25_1, var_25_1)

					var_25_3:setString(var_25_2)
				end

				arg_25_0.lvUpBtnCanUse = false

				arg_25_0:sureUseBooks(iter_25_1, arg_25_0.usedItemNums[iter_25_1])

				arg_25_0.usedItemNums[iter_25_1] = 0
			end
		end)
	end
end

function var_0_0.addExp(arg_29_0, arg_29_1, arg_29_2, arg_29_3)
	local var_29_0 = arg_29_0.hero:getCourseInfo(arg_29_0.selectBookId)
	local var_29_1 = var_0_11:maxTotalProficiency()

	if arg_29_1 <= 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_3:translation("COURSE_EXP_ITEM_ABSENCE")
		})
	elseif var_29_1 <= var_29_0.exp + arg_29_0:getTempExp() then
		local var_29_2 = xyd.tables.sound:getSound("train_exp_max")

		audio.playSound(var_29_2, false)
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_3:translation("COURSE_EXP_FULL")
		})
	else
		local var_29_3 = var_0_11:getColorByProficiency(var_29_0.exp + arg_29_0:getTempExp())

		arg_29_0.usedItemNums[arg_29_2] = arg_29_0.usedItemNums[arg_29_2] + 1

		local var_29_4 = var_0_11:getColorByProficiency(var_29_0.exp + arg_29_0:getTempExp())

		arg_29_1 = arg_29_1 - 1

		arg_29_0:updateLevelUpContainer()

		if var_29_3 < var_29_4 then
			arg_29_0:levelUp(var_29_4)
		end

		arg_29_0:playEatExpEffect(arg_29_3)
		arg_29_0.giftPush:setSceneCondition(40)

		if not arg_29_0.giftPush:getSpecialTag(41)[2] then
			arg_29_0.giftPush:setSpecialTag(41, 1)
		else
			arg_29_0.giftPush:setSpecialTag(41, 3)
		end
	end

	return arg_29_1
end

function var_0_0.levelUp(arg_30_0, arg_30_1)
	local var_30_0 = arg_30_0.selectItemContainer
	local var_30_1 = var_0_6:icon(arg_30_0.selectBookId)

	var_30_0:getChildByName("course"):removeAllChildren()
	xyd.setSpriteBorder(var_30_0:getChildByName("course"), var_30_1, arg_30_1)
	arg_30_0:addSelectEffect(var_30_0:getChildByName("course"))
	arg_30_0:nodeByName("course"):removeAllChildren()
	xyd.setSpriteBorder(arg_30_0:nodeByName("course"), var_30_1, arg_30_1)
	arg_30_0:nodeByName("txt_course_desc"):setString(var_0_6:des(arg_30_0.selectBookId, arg_30_1))

	local var_30_2 = arg_30_0.equipItems[arg_30_0.selectBookId]

	if var_30_2 then
		var_30_2:getChildByName("course"):removeAllChildren()
		xyd.setSpriteBorder(var_30_2:getChildByName("course"), var_30_1, arg_30_1)
	end

	local var_30_3 = xyd.tables.sound:getSound("train_lv_up")

	audio.playSound(var_30_3, false)

	if not arg_30_0.levelUpEffect then
		local var_30_4 = var_0_14.Evolve .. ".json"
		local var_30_5 = var_0_14.Evolve .. ".atlas"

		arg_30_0.levelUpEffect = var_0_2.new(var_30_4, var_30_5, 1)

		arg_30_0.levelUpEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_30_0.levelUpEffect:addTo(arg_30_0:nodeByName("effect_pos"))
	end

	arg_30_0.levelUpEffect:play(nil, false)
end

function var_0_0.playEatExpEffect(arg_31_0, arg_31_1)
	if tolua.isnull(arg_31_1) then
		return
	end

	local var_31_0 = arg_31_1:getContentSize().width
	local var_31_1 = arg_31_1:getContentSize().height

	if arg_31_0.clickEffect and not tolua.isnull(arg_31_0.clickEffect) then
		arg_31_0.clickEffect:removeFromParent()
	end

	local var_31_2 = "skeletons/ui_effect/common_effect_exp_click/common_effect_exp_click"
	local var_31_3 = var_31_2 .. ".json"
	local var_31_4 = var_31_2 .. ".atlas"

	arg_31_0.clickEffect = var_0_2.new(var_31_3, var_31_4, 0.5)

	arg_31_0.clickEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_31_0.clickEffect:setPosition(var_31_0 / 2, var_31_1 / 2)
	arg_31_1:addChild(arg_31_0.clickEffect)
	arg_31_0.clickEffect:play(nil, false)
end

function var_0_0.sureUseBooks(arg_32_0, arg_32_1, arg_32_2)
	if arg_32_2 <= 0 then
		arg_32_0.lvUpBtnCanUse = true

		return
	end

	local var_32_0 = {
		partner_id = arg_32_0.hero:getHeroID(),
		course_id = arg_32_0.selectBookId,
		item_id = arg_32_1,
		item_num = arg_32_2,
		total_num = arg_32_0.backpack:getItemNumByID(arg_32_1)
	}

	arg_32_0.course:incrCoureseExp(var_32_0, function(arg_33_0, arg_33_1)
		if arg_33_0 == xyd.error.OK then
			if arg_33_1.item_id then
				local var_33_0 = arg_33_1.item_id
				local var_33_1 = arg_33_1.course_info
				local var_33_2 = arg_33_1.total_num

				arg_32_0.backpack:setItemNumByID(var_33_0, var_33_2)
				arg_32_0.hero:setCourseInfo(var_33_1, var_32_0.course_id)
			else
				local var_33_3 = {
					itemID = arg_32_1,
					itemNum = arg_32_2
				}

				arg_32_0.backpack:removeItem(var_33_3)
				arg_32_0.hero:setCourseInfo(arg_33_1.course_info, var_32_0.course_id)
			end

			arg_32_0.lvUpBtnCanUse = true
		end
	end)
end

function var_0_0.getTempExp(arg_34_0)
	local var_34_0 = 0

	for iter_34_0, iter_34_1 in pairs(arg_34_0.usedItemNums) do
		var_34_0 = var_34_0 + xyd.tables.item:proficiency(iter_34_0) * iter_34_1
	end

	return var_34_0
end

function var_0_0.refreshListBySelectCourse(arg_35_0)
	local var_35_0 = var_0_6:classType(arg_35_0.selectBookId)
	local var_35_1 = var_0_5:type(var_35_0)
	local var_35_2

	for iter_35_0, iter_35_1 in ipairs(var_0_13) do
		if iter_35_1 == var_35_1 then
			var_35_2 = iter_35_0

			break
		end
	end

	arg_35_0:refreshCourseList(var_35_2)
end

function var_0_0.refreshCourseList(arg_36_0, arg_36_1)
	local var_36_0 = arg_36_0.books[var_0_13[arg_36_1]]
	local var_36_1 = arg_36_0.courseList[arg_36_1]

	var_36_1:removeAllItems()

	for iter_36_0 = 1, math.ceil(#var_36_0 / 3) do
		local var_36_2 = var_36_1:newItem()
		local var_36_3 = display.newNode()

		var_36_3:setContentSize(var_36_1:getViewRect().width, 82)

		for iter_36_1 = 1, 3 do
			local var_36_4 = var_36_0[3 * (iter_36_0 - 1) + iter_36_1]
			local var_36_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/course/main/subject_course_item.csb")
			local var_36_6 = var_36_5:getChildByName("container")
			local var_36_7 = var_0_6:icon(var_36_4)
			local var_36_8 = arg_36_0.hero:getCourseInfo(var_36_4)

			if var_36_8 then
				var_36_6:getChildByName("icon"):setVisible(true)

				if var_36_8.progress >= 100 then
					xyd.setSpriteBorder(var_36_6:getChildByName("course"), var_36_7, var_36_8.quality)
				else
					local var_36_9 = false

					for iter_36_2, iter_36_3 in ipairs(arg_36_0.course.roomInfo.study_infos) do
						if iter_36_3.partner_id == arg_36_0.hero:getHeroID() and iter_36_3.course_id == var_36_4 then
							arg_36_0.isStudying = true

							xyd.setSpriteBorder(var_36_6:getChildByName("course"), var_36_7, 1)
							var_36_6:getChildByName("mask"):setVisible(true)
							var_36_6:getChildByName("hourglass"):setVisible(true)
							var_36_6:getChildByName("txt_time"):setVisible(true)
							var_36_6:getChildByName("txt_time"):enableOutline(cc.c4b(50, 45, 45, 255), 2)

							arg_36_0.timeLabel[1] = var_36_6:getChildByName("txt_time")

							arg_36_0:createTimeHandle(iter_36_3)

							var_36_9 = true

							break
						end
					end

					if not var_36_9 then
						xyd.setSpriteBorder(var_36_6:getChildByName("course"), var_36_7, 1)
					end
				end
			else
				xyd.setSpriteBorder(var_36_6:getChildByName("course"), var_36_7, 1)
			end

			var_36_6:getChildByName("course"):addTouchEventListener(function(arg_37_0, arg_37_1)
				if arg_37_1 == ccui.TouchEventType.ended then
					if arg_36_0.scrollViewMoved_ then
						return
					end

					if arg_36_0.selectBookId == var_36_4 then
						return
					end

					arg_36_0:addSelectEffect(var_36_6:getChildByName("course"))

					arg_36_0.selectBookId = var_36_4
					arg_36_0.selectItemContainer = var_36_6

					arg_36_0:updateBottomRightContainer()
				end
			end)

			if arg_36_0.selectBookId and arg_36_0.selectBookId == var_36_4 then
				arg_36_0:addSelectEffect(var_36_6:getChildByName("course"))

				arg_36_0.selectItemContainer = var_36_6
			end

			var_36_5:setPosition(90 * (iter_36_1 - 1), 0)
			var_36_3:addChild(var_36_5)
		end

		var_36_2:addContent(var_36_3)
		var_36_2:setItemSize(var_36_1:getViewRect().width, 92)
		var_36_1:addItem(var_36_2)
	end

	var_36_1:reload()
end

function var_0_0.updateTopContainer(arg_38_0)
	local var_38_0 = arg_38_0:nodeByName("top")

	var_38_0:removeAllChildren()

	for iter_38_0 = 1, #var_0_13 do
		local var_38_1 = var_0_13[iter_38_0]
		local var_38_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/course/main/subject_item.csb")
		local var_38_3 = var_38_2:getChildByName("bg")
		local var_38_4 = var_38_3:getChildByName("list")
		local var_38_5 = var_38_4:getContentSize()

		arg_38_0.courseList[iter_38_0] = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, var_38_5.width, var_38_5.height),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL
		}):addTo(var_38_4):onScroll(handler(arg_38_0, arg_38_0.scrollListener))

		arg_38_0:refreshCourseList(iter_38_0)
		var_38_3:setTexture("windows/course/main/subject/" .. var_38_1 .. ".png")
		var_38_3:getChildByName("txt_name"):setString(var_0_4:desc(var_38_1))
		var_38_2:setPosition(311 * (iter_38_0 - 1), 0)
		var_38_0:addChild(var_38_2)
	end
end

function var_0_0.updateBottomLeftContainer(arg_39_0)
	arg_39_0:nodeByName("hero"):removeAllChildren()
	xyd.setAvatarBorderNewUI(arg_39_0.hero, arg_39_0:nodeByName("hero"))
	arg_39_0:nodeByName("txt_hero_name"):setString(arg_39_0.hero:getName())
	arg_39_0:nodeByName("txt_point"):setString(string.format(var_0_3:translation("COURSE_TEXT_3"), arg_39_0.hero:getCoursesForce()))

	arg_39_0.equipItems = {}

	arg_39_0:nodeByName("skill"):removeAllChildren()

	local var_39_0 = arg_39_0.hero:getCourseSkills()

	for iter_39_0 = 1, #var_39_0 do
		local var_39_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/course/main/skill_item.csb")
		local var_39_2 = var_39_0[iter_39_0]

		if not var_39_2 then
			break
		end

		local var_39_3 = var_39_1:getChildByName("skill")

		xyd.setSkillBorder(var_39_3, var_39_2, 1)
		var_39_3:addTouchEventListener(function(arg_40_0, arg_40_1)
			if arg_40_1 == ccui.TouchEventType.ended then
				arg_39_0:closeTipWindow()

				local var_40_0 = {
					has_jiantou = false,
					id = var_39_2,
					skillLev = arg_39_0.hero:getSkillLevel(iter_39_0),
					extraSkillLevel = arg_39_0.hero:getExtraSkillLevel(),
					partnerID = arg_39_0.hero:getHeroID(),
					tipIndex = iter_39_0,
					skills = var_0_9:getSkillTable(arg_39_0.hero:getTableID(), iter_39_0),
					courseId = arg_39_0.hero:getSkillCourseId(var_39_2),
					hero = arg_39_0.hero
				}

				if var_0_8:getItemID(var_39_2) == 0 then
					var_40_0.isSpecialSkill = false
				else
					var_40_0.isSpecialSkill = true
				end

				local var_40_1 = arg_39_0:convertToWorldSpace(cc.p(0, 0))
				local var_40_2 = xyd.WindowManager.get():openWindow("skill_tips", var_40_0)
				local var_40_3 = var_39_3:convertToWorldSpace(cc.p(0, 0))
				local var_40_4 = var_40_2:getTipHeight() or var_40_2:getContentSize().height

				if var_40_0.isSpecialSkill then
					var_40_2:setPosition(var_40_3.x + 10 - var_40_1.x, var_40_3.y - 100 - var_40_1.y)
				else
					var_40_2:setPosition(var_40_3.x + 110 - var_40_1.x, var_40_3.y + var_40_4 - 190 - var_40_1.y)
				end
			end
		end)

		local var_39_4 = arg_39_0:getSkillCourseInfo(iter_39_0)

		if var_39_4 then
			var_39_1:getChildByName("equip"):setVisible(false)

			local var_39_5 = var_0_6:icon(var_39_4.course_id)

			xyd.setSpriteBorder(var_39_1:getChildByName("course"), var_39_5, var_39_4.quality)

			arg_39_0.equipItems[var_39_4.course_id] = var_39_1

			var_39_1:getChildByName("course"):addTouchEventListener(function(arg_41_0, arg_41_1)
				if arg_41_1 == ccui.TouchEventType.ended then
					local var_41_0 = {
						idx = iter_39_0,
						hero = arg_39_0.hero,
						skill_id = var_39_2,
						callback = handler(arg_39_0, arg_39_0.onAddSkill)
					}

					xyd.WindowManager.get():openWindow("course_add_skill", var_41_0)
				end
			end)
		else
			local var_39_6 = var_39_1:getChildByName("equip")
			local var_39_7 = var_39_6:getChildByName("icon_add")

			var_39_1:getChildByName("course"):setVisible(false)
			var_39_6:getChildByName("txt_equip"):enableOutline(cc.c4b(65, 74, 84, 255), 0)
			var_39_6:addTouchEventListener(function(arg_42_0, arg_42_1)
				if arg_42_1 == ccui.TouchEventType.began then
					var_39_7:setScale(0.9)
				elseif arg_42_1 == ccui.TouchEventType.canceled then
					var_39_7:setScale(1)
				elseif arg_42_1 == ccui.TouchEventType.ended then
					var_39_7:setScale(1)

					local var_42_0 = {
						idx = iter_39_0,
						hero = arg_39_0.hero,
						skill_id = var_39_2,
						callback = handler(arg_39_0, arg_39_0.onAddSkill)
					}

					xyd.WindowManager.get():openWindow("course_add_skill", var_42_0)
				end
			end)
		end

		var_39_1:setPosition(120 * (iter_39_0 - 1), 0)
		arg_39_0:nodeByName("skill"):addChild(var_39_1)
	end
end

function var_0_0.updateBottomRightContainer(arg_43_0)
	if not arg_43_0.selectBookId then
		arg_43_0:nodeByName("bottom_right"):setVisible(false)
	else
		arg_43_0:nodeByName("bottom_right"):setVisible(true)

		local var_43_0 = arg_43_0.hero:getCourseInfo(arg_43_0.selectBookId)
		local var_43_1 = var_0_6:icon(arg_43_0.selectBookId)
		local var_43_2 = 1

		if not var_43_0 then
			arg_43_0:nodeByName("learn"):setVisible(true)
			arg_43_0:nodeByName("learn2"):setVisible(false)
			arg_43_0:nodeByName("learning"):setVisible(false)
			arg_43_0:nodeByName("level_up"):setVisible(false)
			arg_43_0:updateLearnContainer()
		elseif var_43_0.progress < 100 then
			local var_43_3 = false

			for iter_43_0, iter_43_1 in ipairs(arg_43_0.course.roomInfo.study_infos) do
				if iter_43_1.partner_id == arg_43_0.hero:getHeroID() and iter_43_1.course_id == arg_43_0.selectBookId then
					arg_43_0:nodeByName("learn"):setVisible(false)
					arg_43_0:nodeByName("learn2"):setVisible(false)
					arg_43_0:nodeByName("learning"):setVisible(true)
					arg_43_0:nodeByName("level_up"):setVisible(false)

					var_43_2 = var_0_11:getColorByProficiency(var_43_0.exp + arg_43_0:getTempExp())

					arg_43_0:updateLearningContainer()

					var_43_3 = true

					break
				end
			end

			if not var_43_3 then
				arg_43_0:nodeByName("learn"):setVisible(false)
				arg_43_0:nodeByName("learn2"):setVisible(true)
				arg_43_0:nodeByName("learning"):setVisible(false)
				arg_43_0:nodeByName("level_up"):setVisible(false)
				arg_43_0:updateContiuneLearnContainer()
			end
		else
			arg_43_0:nodeByName("learn"):setVisible(false)
			arg_43_0:nodeByName("learn2"):setVisible(false)
			arg_43_0:nodeByName("learning"):setVisible(false)
			arg_43_0:nodeByName("level_up"):setVisible(true)

			var_43_2 = var_0_11:getColorByProficiency(var_43_0.exp + arg_43_0:getTempExp())

			arg_43_0:updateLevelUpContainer()
		end

		arg_43_0:nodeByName("course"):removeAllChildren()
		xyd.setSpriteBorder(arg_43_0:nodeByName("course"), var_43_1, var_43_2)
		arg_43_0:nodeByName("txt_course_desc"):setString(var_0_6:des(arg_43_0.selectBookId, var_43_2))
		arg_43_0:nodeByName("txt_course_name"):setString(var_0_6:name(arg_43_0.selectBookId))
	end
end

function var_0_0.updateLearnContainer(arg_44_0)
	local var_44_0 = var_0_6:classType(arg_44_0.selectBookId)
	local var_44_1 = var_0_5:application(var_44_0)

	arg_44_0:nodeByName("book"):removeAllChildren()
	xyd.setItemBorder(arg_44_0:nodeByName("book"), var_44_1)

	local var_44_2 = var_0_10:name(var_44_1) .. "x({#e02f2f#1}/%d)"
	local var_44_3 = string.format(var_44_2, arg_44_0.backpack:getItemNumByID(var_44_1))
	local var_44_4 = xyd.getColorlabel({
		size = 20,
		color = cc.c3b(88, 42, 30)
	}, var_44_3)

	var_44_4:setAnchorPoint(0, 0.5)
	arg_44_0:nodeByName("pos_book_name"):removeAllChildren()
	arg_44_0:nodeByName("pos_book_name"):addChild(var_44_4)
end

function var_0_0.updateContiuneLearnContainer(arg_45_0)
	local var_45_0 = arg_45_0.hero:getCourseInfo(arg_45_0.selectBookId)

	arg_45_0:nodeByName("bar_2"):setPercent(var_45_0.progress)
	arg_45_0:nodeByName("txt_bar_2"):setString(var_45_0.progress .. "%")
end

function var_0_0.updateLearningContainer(arg_46_0)
	arg_46_0.timeLabel[2] = arg_46_0:nodeByName("txt_time")
end

function var_0_0.updateLevelUpContainer(arg_47_0)
	local var_47_0 = arg_47_0.hero:getCourseInfo(arg_47_0.selectBookId).exp + arg_47_0:getTempExp()
	local var_47_1 = var_0_11:getColorByProficiency(var_47_0)
	local var_47_2 = var_47_0 - var_0_11:totalProficiency(var_47_1)

	if var_47_1 == var_0_11:maxColorLev() then
		local var_47_3 = var_0_11:proficiency(var_47_1)

		arg_47_0:nodeByName("bar"):setPercent(100)
		arg_47_0:nodeByName("txt_bar"):setString(var_47_3 .. "/" .. var_47_3)
	else
		local var_47_4 = var_0_11:proficiency(var_47_1 + 1)
		local var_47_5 = var_47_0 - var_0_11:totalProficiency(var_47_1)

		arg_47_0:nodeByName("bar"):setPercent(100 * var_47_5 / var_47_4)
		arg_47_0:nodeByName("txt_bar"):setString(var_47_5 .. "/" .. var_47_4)
	end
end

function var_0_0.getSkillCourseInfo(arg_48_0, arg_48_1)
	for iter_48_0, iter_48_1 in pairs(arg_48_0.hero:getCoursesInfo()) do
		if iter_48_1.add_skill == arg_48_1 then
			local var_48_0 = clone(iter_48_1)

			var_48_0.course_id = tonumber(iter_48_0)

			return var_48_0
		end
	end
end

function var_0_0.closeTipWindow(arg_49_0)
	if xyd.WindowManager.get():getWindow("skill_tips") then
		xyd.WindowManager.get():closeWindow("skill_tips")
	end
end

function var_0_0.onSelectHero(arg_50_0, arg_50_1)
	arg_50_0.hero = arg_50_1.hero
	arg_50_0.selectBookId = nil
	arg_50_0.isStudying = false

	arg_50_0:updateTopContainer()
	arg_50_0:updateBottomLeftContainer()
	arg_50_0:updateBottomRightContainer()
end

function var_0_0.onAddSkill(arg_51_0, arg_51_1)
	arg_51_0:updateBottomLeftContainer()
end

function var_0_0.createTimeHandle(arg_52_0, arg_52_1)
	if arg_52_0.timeHandle then
		var_0_1.unscheduleGlobal(arg_52_0.timeHandle)

		arg_52_0.timeHandle = nil
	end

	arg_52_0.timeHandle = var_0_1.scheduleGlobal(function()
		local var_53_0 = arg_52_0:getDownTime(arg_52_1)

		if var_53_0 <= 0 then
			arg_52_0:clearTimeHandle()

			local var_53_1 = {
				partner_id = arg_52_0.hero:getHeroID()
			}

			arg_52_0.course:getCourseInfo(var_53_1, function(arg_54_0, arg_54_1)
				if arg_54_0 == xyd.error.OK then
					arg_52_0.isStudying = false

					arg_52_0:refreshListBySelectCourse()
					arg_52_0:updateBottomRightContainer()
				end
			end)
		else
			local var_53_2 = xyd.secondsToString(var_53_0)

			if arg_52_0.timeLabel[1] and not tolua.isnull(arg_52_0.timeLabel[1]) then
				arg_52_0.timeLabel[1]:setString(var_53_2)
			end

			if arg_52_0.timeLabel[2] and not tolua.isnull(arg_52_0.timeLabel[2]) then
				arg_52_0.timeLabel[2]:setString(string.format(var_0_3:translation("COURSE_TEXT_16"), var_53_2))
			end
		end
	end, 1)
end

function var_0_0.clearTimeHandle(arg_55_0)
	if arg_55_0.timeHandle then
		var_0_1.unscheduleGlobal(arg_55_0.timeHandle)

		arg_55_0.timeHandle = nil
	end

	arg_55_0.timeLabel = {}
end

function var_0_0.getDownTime(arg_56_0, arg_56_1)
	local var_56_0 = xyd.ServerTime.get():getServerTime()

	return arg_56_1.start_time + var_0_12.objectClassRoomTime - var_56_0
end

function var_0_0.addSelectEffect(arg_57_0, arg_57_1)
	if arg_57_0.selectEffect and not tolua.isnull(arg_57_0.selectEffect) then
		arg_57_0.selectEffect:removeFromParent(false)
	else
		arg_57_0.selectEffect = xyd.AssetLoader.get():loadSprite("windows/course/main/select.png")

		local var_57_0 = cc.ScaleBy:create(0.3, 1.04)
		local var_57_1 = transition.sequence({
			var_57_0,
			var_57_0:reverse()
		})
		local var_57_2 = cc.RepeatForever:create(var_57_1)

		arg_57_0.selectEffect:runAction(var_57_2)
		arg_57_0.selectEffect:setNormalizedPosition(cc.p(0.5, 0.5))
	end

	arg_57_1:addChild(arg_57_0.selectEffect)
end

function var_0_0.updateRedMarkShow(arg_58_0)
	arg_58_0:nodeByName("red_point"):setVisible(arg_58_0.course:isBookStoreRedPointShow())
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.CHECK_MIDDLE_RED_MARK,
		params = xyd.CheckMiddleRed.COURSE
	})
end

function var_0_0.scrollListener(arg_59_0, arg_59_1)
	if arg_59_1.name == "began" then
		arg_59_0.scrollViewMoved_ = false
		arg_59_0.prevY_ = arg_59_1.y
	elseif arg_59_1.name == "moved" and math.abs(arg_59_1.y - arg_59_0.prevY_) >= 10 then
		arg_59_0.scrollViewMoved_ = true
	end
end

function var_0_0.willClose(arg_60_0)
	if arg_60_0.handler[1] ~= nil then
		var_0_1.unscheduleGlobal(arg_60_0.handler[1])

		arg_60_0.handler[1] = nil
	end

	if arg_60_0.handler[2] ~= nil then
		var_0_1.unscheduleGlobal(arg_60_0.handler[2])

		arg_60_0.handler[2] = nil
	end

	if arg_60_0.timeHandle then
		var_0_1.unscheduleGlobal(arg_60_0.timeHandle)

		arg_60_0.timeHandle = nil
	end

	if arg_60_0.callback then
		arg_60_0.callback()
	end
end

return var_0_0
