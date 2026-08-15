local var_0_0 = class("CourseUpgradeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.objectBookColor
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = {}

var_0_5.Upgrade = "skeletons/ui_effect/common_effect_hero3/common_effect_hero3"
var_0_5.Evolve = "skeletons/ui_effect/course/effect_object"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.course = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.giftPush = xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH)
	arg_1_0.books = xyd.tables.misc.objectBoxBooks
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.courseId = arg_1_2.course_id
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.selectBookId = nil
	arg_1_0.handler = {}
	arg_1_0.usedItemNums = {}
	arg_1_0.visibleHandler = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.didClose(arg_3_0, arg_3_1)
	var_0_0.super.didClose(arg_3_0, arg_3_1)

	if arg_3_0.callback then
		arg_3_0.callback()
	end
end

function var_0_0.sureUseBooks(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = arg_4_3:getChildByName("use_btn")
	local var_4_1 = arg_4_0.hero:getCourseInfo(arg_4_0.courseId)

	if arg_4_2 <= 0 then
		var_4_0:setButtonEnabled(true)

		return
	end

	local var_4_2 = {
		partner_id = arg_4_0.hero:getHeroID(),
		course_id = arg_4_0.courseId,
		item_id = arg_4_1,
		item_num = arg_4_2,
		total_num = arg_4_0.backpack:getItemNumByID(arg_4_1)
	}

	arg_4_0.course:incrCoureseExp(var_4_2, function(arg_5_0, arg_5_1)
		if arg_5_0 == xyd.error.OK then
			arg_4_0:updateCourseShow()

			if arg_5_1.item_id then
				local var_5_0 = arg_5_1.item_id
				local var_5_1 = arg_5_1.course_info
				local var_5_2 = arg_5_1.total_num

				arg_4_0.selfPlayer:getBackpack():setItemNumByID(var_5_0, var_5_2)
				arg_4_0.hero:setCourseInfo(var_5_1, var_4_2.course_id)
				arg_4_3:getChildByName("num_text"):setString(var_5_2)
			else
				local var_5_3 = {
					itemID = arg_4_1,
					itemNum = arg_4_2
				}

				arg_4_0.backpack:removeItem(var_5_3)
				arg_4_0:updateCourseShow()
			end
		end

		var_4_0:setButtonEnabled(true)
	end)
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("progress_txt"):setString(var_0_1:translation(""))
	arg_6_0:nodeByName("tip_txt"):setString(var_0_1:translation("COURSE_UPGRADE_TIP"))

	arg_6_0.scroll = arg_6_0:nodeByName("material_scroll")

	arg_6_0:updateCourseShow()
	arg_6_0:updateMaterialList()
end

function var_0_0.updateCourseShow(arg_7_0)
	local var_7_0 = xyd.tables.objectBook:icon(arg_7_0.courseId)
	local var_7_1 = arg_7_0.hero:getCourseInfo(arg_7_0.courseId)
	local var_7_2 = var_0_3:getColorByProficiency(var_7_1.exp + arg_7_0:getTempExp())
	local var_7_3 = var_7_2 + 1

	if var_7_2 == var_0_3:maxColorLev() then
		var_7_2 = var_7_2 - 1
		var_7_3 = var_0_3:maxColorLev()
	end

	arg_7_0:nodeByName("icon_container1"):removeAllChildren(true)
	arg_7_0:nodeByName("icon_container2"):removeAllChildren(true)
	xyd.setSpriteBorder(arg_7_0:nodeByName("icon_container1"), var_7_0, var_7_2)
	xyd.setSpriteBorder(arg_7_0:nodeByName("icon_container2"), var_7_0, var_7_3)

	local var_7_4 = var_0_3:proficiency(var_7_3)
	local var_7_5 = var_7_1.exp + arg_7_0:getTempExp() - var_0_3:totalProficiency(var_7_2)

	if var_7_4 < var_7_5 then
		var_7_5 = var_7_4
	end

	arg_7_0:nodeByName("progress_bar"):setPercent(100 * var_7_5 / var_7_4)
	arg_7_0:nodeByName("progress_txt"):setString(tostring(var_7_5) .. "/" .. tostring(var_7_4))

	if not arg_7_0.giftPush.specialInfo[39] or arg_7_0.giftPush.specialInfo[39] ~= arg_7_0.hero:getHeroID() or arg_7_0.giftPush:getSceneCondition(39) <= 0.85 then
		arg_7_0.giftPush.specialInfo[39] = arg_7_0.hero:getHeroID()

		arg_7_0.giftPush:cleanSceneCondition(39)
		arg_7_0.giftPush:setSceneCondition(39, var_7_1.exp / var_0_3:totalProficiency(var_0_3:maxColorLev()))
	else
		arg_7_0.giftPush:setSceneCondition(39, 0)
	end
end

function var_0_0.getTempExp(arg_8_0)
	local var_8_0 = 0

	for iter_8_0, iter_8_1 in pairs(arg_8_0.usedItemNums) do
		var_8_0 = var_8_0 + xyd.tables.item:proficiency(iter_8_0) * iter_8_1
	end

	return var_8_0
end

function var_0_0.updateMaterialList(arg_9_0)
	arg_9_0.usedItemNums = {}

	arg_9_0.scroll:removeAllChildren(true)

	for iter_9_0 = 1, #arg_9_0.books do
		local var_9_0 = arg_9_0.books[iter_9_0]
		local var_9_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/course/course_info/book_item.csb")
		local var_9_2 = var_9_1:getChildByName("container")

		var_9_2:getChildByName("use_num"):setVisible(false)
		var_9_2:getChildByName("use_num"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

		local var_9_3 = var_9_2:getContentSize()

		var_9_1:setContentSize(var_9_3)

		local var_9_4 = var_9_2:getChildByName("item")

		xyd.setItemBorder(var_9_4, var_9_0)

		local var_9_5 = arg_9_0.selfPlayer:getBackpack():getItemNumByID(var_9_0)

		var_9_2:getChildByName("num_text"):setString(var_9_5)

		local var_9_6 = var_9_2
		local var_9_7 = cc.ui.UIPushButton.new({
			pressed = "windows/button/small_button6.png",
			disabled = "windows/button/small_button5.png",
			normal = "windows/button/small_button5.png"
		})

		var_9_7:setAnchorPoint(cc.p(0.5, 0.5))

		local var_9_8 = var_9_4:getContentSize()
		local var_9_9 = var_9_6:getContentSize()

		var_9_7:setPosition(cc.p(var_9_9.width / 2, var_9_9.height / 2))
		var_9_7:addTo(var_9_6)
		var_9_7:setTouchSwallowEnabled(false)
		var_9_7:setButtonSize(var_9_8.width, var_9_8.height)
		var_9_7:setOpacity(0)
		var_9_7:setName("use_btn")

		arg_9_0.usedItemNums[var_9_0] = 0

		local var_9_10 = false

		var_9_7:onButtonPressed(function(arg_10_0)
			local var_10_0 = 0

			local function var_10_1()
				if tolua.isnull(arg_9_0) then
					if arg_9_0.handler and arg_9_0.handler[1] ~= nil then
						var_0_2.unscheduleGlobal(arg_9_0.handler[1])
					end

					if arg_9_0.handler and arg_9_0.handler[2] ~= nil then
						var_0_2.unscheduleGlobal(arg_9_0.handler[2])
					end

					return
				end

				var_10_0 = var_10_0 + 0.06
				var_9_5 = arg_9_0:addExp(var_9_5, var_9_0, var_9_2)

				var_9_2:getChildByName("num_text"):setString(var_9_5)
			end

			local function var_10_2()
				if tolua.isnull(arg_9_0) then
					if arg_9_0.handler and arg_9_0.handler[1] ~= nil then
						var_0_2.unscheduleGlobal(arg_9_0.handler[1])
					end

					if arg_9_0.handler and arg_9_0.handler[2] ~= nil then
						var_0_2.unscheduleGlobal(arg_9_0.handler[2])
					end

					return
				end

				var_10_0 = var_10_0 + 0.1

				if var_10_0 > 0.5 and var_10_0 <= 4 then
					var_9_10 = true
					var_9_5 = arg_9_0:addExp(var_9_5, var_9_0, var_9_2)

					var_9_2:getChildByName("num_text"):setString(var_9_5)
				elseif var_10_0 > 4 then
					arg_9_0.handler[2] = var_0_2.scheduleGlobal(var_10_1, 0.06)

					var_0_2.unscheduleGlobal(arg_9_0.handler[1])
				else
					var_9_10 = false
				end
			end

			var_9_10 = false
			arg_9_0.handler[1] = var_0_2.scheduleGlobal(var_10_2, 0.1)
		end)
		var_9_7:onButtonRelease(function(arg_13_0)
			if arg_9_0.handler[1] ~= nil then
				var_0_2.unscheduleGlobal(arg_9_0.handler[1])
			end

			if arg_9_0.handler[2] ~= nil then
				var_0_2.unscheduleGlobal(arg_9_0.handler[2])
			end

			if var_9_10 == false then
				var_9_5 = arg_9_0:addExp(var_9_5, var_9_0, var_9_2)

				var_9_2:getChildByName("num_text"):setString(var_9_5)
			end

			var_9_7:setButtonEnabled(false)
			arg_9_0:sureUseBooks(var_9_0, arg_9_0.usedItemNums[var_9_0], var_9_2)

			arg_9_0.usedItemNums[var_9_0] = 0
		end)
		var_9_1:addTo(arg_9_0.scroll)
		var_9_1:y((arg_9_0.scroll:getHeight() - var_9_3.height) / 2)
		var_9_1:x((iter_9_0 - 1) * (var_9_3.width + 6))
	end
end

function var_0_0.addExp(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	local var_14_0 = arg_14_0.hero:getCourseInfo(arg_14_0.courseId)
	local var_14_1 = var_0_3:maxTotalProficiency()

	if arg_14_1 <= 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_1:translation("COURSE_EXP_ITEM_ABSENCE")
		})
	elseif var_14_1 <= var_14_0.exp + arg_14_0:getTempExp() then
		local var_14_2 = xyd.tables.sound:getSound("train_exp_max")

		audio.playSound(var_14_2, false)
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_1:translation("COURSE_EXP_FULL")
		})
	else
		local var_14_3 = var_0_3:getColorByProficiency(var_14_0.exp + arg_14_0:getTempExp())

		arg_14_0.usedItemNums[arg_14_2] = arg_14_0.usedItemNums[arg_14_2] + 1

		local var_14_4 = var_0_3:getColorByProficiency(var_14_0.exp + arg_14_0:getTempExp())

		arg_14_1 = arg_14_1 - 1

		arg_14_0:updateCourseShow()

		if var_14_3 < var_14_4 then
			arg_14_0:playLevelUpEffect(arg_14_0:nodeByName("effect_pos"))
		end

		arg_14_0:playEatExpEffect(arg_14_3)

		if not tolua.isnull(arg_14_3) then
			arg_14_3:getChildByName("use_num"):setVisible(true)
			arg_14_3:getChildByName("use_num"):setString("X" .. arg_14_0.usedItemNums[arg_14_2])
		end

		if arg_14_0.visibleHandler[arg_14_2] ~= nil then
			var_0_2.unscheduleGlobal(arg_14_0.visibleHandler[arg_14_2])
		end

		if not tolua.isnull(arg_14_3) then
			local var_14_5 = arg_14_3:getChildByName("use_num")

			arg_14_0.visibleHandler[arg_14_2] = var_0_2.performWithDelayGlobal(function()
				if not tolua.isnull(arg_14_3) then
					var_14_5:setVisible(false)
				end
			end, 0.1)
		end

		arg_14_0.giftPush:setSceneCondition(40)

		if not arg_14_0.giftPush:getSpecialTag(41)[2] then
			arg_14_0.giftPush:setSpecialTag(41, 1)
		else
			arg_14_0.giftPush:setSpecialTag(41, 3)
		end
	end

	return arg_14_1
end

function var_0_0.playEatExpEffect(arg_16_0, arg_16_1)
	if tolua.isnull(arg_16_1) then
		return
	end

	local var_16_0 = arg_16_1:getChildByName("item"):getContentSize().width
	local var_16_1 = arg_16_1:getChildByName("item"):getContentSize().height
	local var_16_2, var_16_3 = arg_16_1:getChildByName("item"):getPosition()

	if arg_16_0.clickEffect and not tolua.isnull(arg_16_0.clickEffect) then
		arg_16_0.clickEffect:removeAllChildren()
	end

	local var_16_4 = "skeletons/ui_effect/common_effect_exp_click/common_effect_exp_click"
	local var_16_5 = var_16_4 .. ".json"
	local var_16_6 = var_16_4 .. ".atlas"

	arg_16_0.clickEffect = var_0_4.new(var_16_5, var_16_6, 1)

	arg_16_0.clickEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_16_0.clickEffect:setPosition(var_16_2 + var_16_0 / 2, var_16_3 + var_16_1 / 2)
	arg_16_1:addChild(arg_16_0.clickEffect)
	arg_16_0.clickEffect:setScale(0.7)
	arg_16_0.clickEffect:play(nil, false)
end

function var_0_0.playLevelUpEffect(arg_17_0, arg_17_1)
	local var_17_0 = arg_17_1:getContentSize().width
	local var_17_1 = arg_17_1:getContentSize().height
	local var_17_2 = xyd.tables.sound:getSound("train_lv_up")

	audio.playSound(var_17_2, false)

	if arg_17_0.levelUpEffect == nil then
		local var_17_3 = var_0_5.Evolve .. ".json"
		local var_17_4 = var_0_5.Evolve .. ".atlas"

		arg_17_0.levelUpEffect = var_0_4.new(var_17_3, var_17_4, 1)

		arg_17_0.levelUpEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_17_0.levelUpEffect:setPosition(var_17_0 / 2, var_17_1 / 2)
		arg_17_0.levelUpEffect:addTo(arg_17_1)
	end

	arg_17_0.levelUpEffect:play(nil, false)
end

function var_0_0.scrollListener(arg_18_0, arg_18_1)
	if arg_18_1.name == "began" then
		arg_18_0.scrollViewMoved_ = false
		arg_18_0.prevY_ = arg_18_1.y
	elseif arg_18_1.name == "moved" and 5 <= math.abs(arg_18_1.y - arg_18_0.prevY_) then
		arg_18_0.scrollViewMoved_ = true
	end
end

return var_0_0
