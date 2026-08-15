local var_0_0 = class("SkillTipsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.skill
local var_0_3 = "windows/new_item_tips/jnkuang.png"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2
	arg_1_0.id = arg_1_2.id
	arg_1_0.courseId = arg_1_2.courseId
	arg_1_0.skillLevel = arg_1_2.skillLev
	arg_1_0.extraSkillLevel = arg_1_2.extraSkillLevel or 0
	arg_1_0.has_jiantou = arg_1_2.has_jiantou
	arg_1_0.skillDesc4Change = arg_1_2.skillDesc4Change or false
	arg_1_0.isShowSkillDesc4 = arg_1_2.isShowSkillDesc4 or false
	arg_1_0.isSpecialSkill_ = arg_1_2.isSpecialSkill or false
	arg_1_0.partnerID_ = arg_1_2.partnerID or 0
	arg_1_0.tipIndex_ = arg_1_2.tipIndex or 1
	arg_1_0.skills_ = arg_1_2.skills or {}
	arg_1_0.currentSkillID_ = arg_1_0.id
	arg_1_0.selfPlayer_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.hero_ = arg_1_2.hero
	arg_1_0.activitySkillDesc = arg_1_2.activitySkillDesc
	arg_1_0.isActivitySkill = arg_1_2.isActivitySkill
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0 = xyd.tables.sound:getSound("ui_tips")

	audio.playSound(var_2_0, false)
	arg_2_0:layout()
end

function var_0_0.createLabel(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4)
	local var_3_0 = {
		color = arg_3_2,
		size = arg_3_1
	}
	local var_3_1 = xyd.AssetLoader.get():loadLabel(var_3_0)

	if arg_3_4 then
		var_3_1:setDimensions(arg_3_4, 0)
	else
		var_3_1:setDimensions(290, 0)
	end

	if arg_3_3 then
		var_3_1:setString(arg_3_3)
	end

	return var_3_1
end

function var_0_0.layout(arg_4_0)
	if arg_4_0.isSpecialSkill_ then
		arg_4_0:zglSkillContain()
	else
		local var_4_0 = {}

		if arg_4_0.has_jiantou ~= nil and arg_4_0.has_jiantou == false then
			arg_4_0:nodeByName("jiantou"):setVisible(false)
		end

		arg_4_0.tipHeight = 0

		local var_4_1 = var_0_2:typeDesc(arg_4_0.id)

		if var_4_1 ~= -1 and var_4_1 >= 0 and var_4_1 <= 2 then
			local var_4_2 = display.newNode()

			var_4_2:setContentSize(290, 60)

			local var_4_3 = xyd.AssetLoader.get():loadSprite("windows/new_item_tips/type_desc_" .. var_4_1 .. ".png")

			var_4_3:setAnchorPoint(cc.p(0, 0.5))
			var_4_3:addTo(var_4_2)
			var_4_3:setPosition(cc.p(-2, 38))
			var_4_3:setScale(0.75)

			local var_4_4 = xyd.AssetLoader.get():loadSprite("windows/new_item_tips/split.png")

			var_4_4:setAnchorPoint(cc.p(0, 0.5))
			var_4_4:addTo(var_4_2)
			var_4_4:setPosition(cc.p(0, 10))

			local var_4_5 = arg_4_0:createLabel(22, cc.c3b(100, 255, 253), var_0_1:translation("SKILL_TYPE_DESC_" .. var_4_1))

			var_4_5:setAnchorPoint(cc.p(0, 0.5))
			var_4_5:setPosition(cc.p(40, 38))
			var_4_5:addTo(var_4_2)
			table.insert(var_4_0, var_4_2)

			arg_4_0.tipHeight = arg_4_0.tipHeight + 60
		end

		local var_4_6 = arg_4_0:createLabel(22, cc.c3b(255, 255, 255), xyd.tables.skill:desc(arg_4_0.id))

		var_4_6:setAnchorPoint(cc.p(0, 0))
		var_4_6:setName("skill_desc1")
		var_4_6:setPosition(cc.p(5, 0))

		local var_4_7 = var_4_6:getContentSize().height

		table.insert(var_4_0, var_4_6)

		arg_4_0.tipHeight = arg_4_0.tipHeight + var_4_7

		local var_4_8 = 0

		if arg_4_0.skillLevel and arg_4_0.skillLevel > 0 and arg_4_0:generateSkillDesc2(arg_4_0.id, arg_4_0.skillLevel) then
			local var_4_9 = arg_4_0:createLabel(22, cc.c3b(241, 255, 15), nil)

			var_4_9:setName("skill_desc2")
			var_4_9:setAnchorPoint(cc.p(0, 0))
			var_4_9:setPosition(cc.p(5, -10))
			var_4_9:setVisible(true)
			var_4_9:setString(arg_4_0:generateSkillDesc2(arg_4_0.id, arg_4_0.skillLevel + arg_4_0.extraSkillLevel))

			local var_4_10 = var_4_9:getContentSize().height

			table.insert(var_4_0, var_4_9)

			arg_4_0.tipHeight = arg_4_0.tipHeight + var_4_10
		end

		if arg_4_0.isActivitySkill and arg_4_0.skillLevel > 0 and arg_4_0.activitySkillDesc then
			local var_4_11 = arg_4_0:createLabel(22, cc.c3b(24, 184, 54), nil)

			var_4_11:setName("skill_desc3")
			var_4_11:setAnchorPoint(cc.p(0, 0))
			var_4_11:setPosition(cc.p(5, -10))
			var_4_11:setVisible(true)
			var_4_11:setString(arg_4_0.activitySkillDesc)

			local var_4_12 = var_4_11:getContentSize().height

			table.insert(var_4_0, var_4_11)

			arg_4_0.tipHeight = arg_4_0.tipHeight + var_4_12
		end

		local var_4_13 = 0

		if arg_4_0.skillLevel and arg_4_0.skillLevel > 0 and arg_4_0.isShowSkillDesc4 then
			local var_4_14 = arg_4_0:createLabel(18, cc.c3b(17, 209, 211))

			var_4_14:setName("skill_desc4")
			var_4_14:setAnchorPoint(cc.p(0, 0))
			var_4_14:setPosition(cc.p(5, -20))
			var_4_14:setVisible(true)
			var_4_14:setString(arg_4_0:generateSkillDesc4(arg_4_0.id, arg_4_0.skillLevel + arg_4_0.extraSkillLevel))

			local var_4_15 = var_4_14:getContentSize().height

			table.insert(var_4_0, var_4_14)

			arg_4_0.tipHeight = arg_4_0.tipHeight + var_4_15 + 10
		end

		if arg_4_0.courseId then
			local var_4_16 = display.newNode()
			local var_4_17 = arg_4_0:createLabel(24, cc.c3b(33, 234, 69), var_0_1:translation("COURSE_TEXT"))

			var_4_17:setAnchorPoint(cc.p(0, 0))
			var_4_17:setName("course_text")
			var_4_17:setPosition(cc.p(5, 0))
			var_4_17:addTo(var_4_16)

			local var_4_18 = var_4_17:getContentSize().height
			local var_4_19 = arg_4_0:createLabel(22, cc.c3b(0, 255, 170), xyd.tables.objectBook:name(arg_4_0.courseId))

			var_4_19:setAnchorPoint(cc.p(0, 0))
			var_4_19:setName("course_desc1")
			var_4_19:setPosition(cc.p(5, 0))
			var_4_19:addTo(var_4_16)
			var_4_19:setPosition(cc.p(80, 0))
			var_4_16:setContentSize(290, var_4_18 + 20)
			table.insert(var_4_0, var_4_16)

			arg_4_0.tipHeight = arg_4_0.tipHeight + var_4_18 + 20

			local var_4_20 = arg_4_0.hero_:getCourseLevelByID(arg_4_0.courseId)
			local var_4_21 = arg_4_0:createLabel(22, cc.c3b(0, 255, 170), xyd.tables.objectBook:des(arg_4_0.courseId, var_4_20))

			var_4_21:setAnchorPoint(cc.p(0, 0))
			var_4_21:setName("course_desc1")
			var_4_21:setPosition(cc.p(5, 0))

			local var_4_22 = var_4_21:getContentSize().height

			table.insert(var_4_0, var_4_21)

			arg_4_0.tipHeight = arg_4_0.tipHeight + var_4_22
		end

		arg_4_0.tipHeight = arg_4_0.tipHeight + 50

		if arg_4_0.tipHeight <= 100 then
			arg_4_0.tipHeight = 110
		end

		arg_4_0.list = cc.ui.UIListView.new({
			viewRect = cc.rect(1, 1, 312, arg_4_0.tipHeight - 40),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_4_0:nodeByName("container")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

		arg_4_0.list:setAnchorPoint(cc.p(0, 0))
		arg_4_0.list:setPosition(20, 20)

		for iter_4_0 = 1, #var_4_0 do
			local var_4_23 = var_4_0[iter_4_0]:getContentSize().width
			local var_4_24 = var_4_0[iter_4_0]:getContentSize().height
			local var_4_25 = display.newNode()
			local var_4_26 = arg_4_0.list:newItem()

			var_4_25:addChild(var_4_0[iter_4_0])
			var_4_25:setContentSize(var_4_23, var_4_24)
			var_4_26:addContent(var_4_25)
			var_4_26:setItemSize(var_4_23, var_4_24)
			arg_4_0.list:addItem(var_4_26)
		end

		local var_4_27 = arg_4_0:nodeByName("container")

		var_4_27:height(arg_4_0.tipHeight)

		local var_4_28 = var_4_27:getPositionY()

		arg_4_0:nodeByName("jiantou"):y(var_4_28 - 55)
		arg_4_0.list:reload()
	end
end

function var_0_0.resetJiantouPos(arg_5_0, arg_5_1)
	arg_5_0:nodeByName("jiantou"):setPosition(cc.p(arg_5_1))
end

function var_0_0.zglSkillContain(arg_6_0)
	arg_6_0:nodeByName("skill_container"):setVisible(false)
	arg_6_0:nodeByName("jiantou"):setVisible(false)
	arg_6_0:nodeByName("container"):setVisible(false)
	arg_6_0:nodeByName("zgl_skill_contain2"):setVisible(true)
	arg_6_0:nodeByName("zgl_skill_contain2"):setPosition(cc.p(100, 100))

	local var_6_0 = display.newNode()

	var_6_0:setContentSize(67, 67)
	xyd.setSkillBorder(var_6_0, arg_6_0.id, 0)
	var_6_0:addTo(arg_6_0:nodeByName("icon_pos"))

	local var_6_1 = xyd.tables.skill:desc(arg_6_0.id)

	arg_6_0:updateZglTips(var_6_1, arg_6_0:nodeByName("detail_contain"))

	local var_6_2 = xyd.tables.skill:name(arg_6_0.id)

	arg_6_0:nodeByName("name_label"):setString(var_6_2)

	if arg_6_0.skillLevel then
		lev = arg_6_0.skillLevel
	else
		lev = 0
	end

	arg_6_0:nodeByName("lv_label"):setVisible(false)
	arg_6_0:nodeByName("change_btn"):setTouchEnabled(true)
	arg_6_0:nodeByName("change_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			arg_6_0:nodeByName("zgl_skill_contain2"):setVisible(false)
			arg_6_0:resetLayer()
			arg_6_0:zglChangeSkillContain()
		end
	end)

	if not arg_6_0.skillLevel or arg_6_0.skillLevel < 1 then
		arg_6_0:nodeByName("change_btn"):setTouchEnabled(false)
		arg_6_0:nodeByName("change_btn"):setBright(false)
		arg_6_0:nodeByName("change_skill"):setGrayScale(1)
	else
		arg_6_0:nodeByName("change_btn"):setTouchEnabled(true)
		arg_6_0:nodeByName("change_btn"):setBright(true)
		arg_6_0:nodeByName("change_skill"):setGrayScale(0)
	end
end

function var_0_0.resetLayer(arg_8_0)
	arg_8_0.blockLayer_:removeSelf()

	arg_8_0.blockLayer_ = nil

	arg_8_0:getEventDispatcher():removeEventListener(arg_8_0.layerListener)

	arg_8_0.layerListener = nil

	arg_8_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 0))
end

function var_0_0.zglChangeSkillContain(arg_9_0)
	arg_9_0:nodeByName("zgl_skill_contain1"):setPosition(cc.p(100, 100))
	arg_9_0:nodeByName("zgl_skill_contain1"):setVisible(true)
	arg_9_0:nodeByName("deter_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			if arg_9_0.currentSkillID_ ~= arg_9_0.id then
				arg_9_0:changeSkillIndex()
			else
				local var_10_0 = xyd.WindowManager.get():getWindow("skill_tips")

				xyd.WindowManager.get():closeWindow("skill_tips")
			end
		end
	end)

	local var_9_0 = {
		viewRect = cc.rect(0, 0, arg_9_0:nodeByName("icons_contain"):getContentSize().width, 90),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}

	arg_9_0.zglListview = cc.ui.UIListView.new(var_9_0):addTo(arg_9_0:nodeByName("icons_contain")):onScroll(handler(arg_9_0, arg_9_0.scrollListener2))

	for iter_9_0 = 1, #arg_9_0.skills_ do
		local var_9_1 = arg_9_0.skills_[iter_9_0]
		local var_9_2 = display.newNode()
		local var_9_3 = display.newNode()

		var_9_3:setContentSize(67, 67)

		local var_9_4 = arg_9_0.zglListview:newItem()
		local var_9_5 = xyd.tables.skill:icon(var_9_1)
		local var_9_6 = xyd.SpriteLoader.new(var_9_5, nil, nil, xyd.DefaultImageType.SKILL_ICON)
		local var_9_7 = xyd.tables.skill:desc(var_9_1)

		var_9_6:setTouchEnabled(true)
		var_9_6:setTouchSwallowEnabled(false)
		var_9_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
			if arg_11_0.name == "began" then
				return true
			elseif arg_11_0.name == "ended" and not arg_9_0.scrollViewMoved_ then
				if arg_9_0:skillNotAvilable(iter_9_0) then
					arg_9_0:nodeByName("deter_btn"):setTouchEnabled(false)
					arg_9_0:nodeByName("deter_btn"):setBright(false)
					arg_9_0:nodeByName("determin"):setGrayScale(1)
				else
					arg_9_0:nodeByName("deter_btn"):setTouchEnabled(true)
					arg_9_0:nodeByName("deter_btn"):setBright(true)
					arg_9_0:nodeByName("determin"):setGrayScale(0)
				end

				arg_9_0.currentSkillID_ = arg_9_0.skills_[iter_9_0]

				arg_9_0.skillEffect_:removeSelf()

				arg_9_0.skillEffect_ = nil

				arg_9_0:createSkillEffect(var_9_3)
				arg_9_0:updateZglTips(var_9_7, arg_9_0:nodeByName("di_contain"))
			end
		end)

		if arg_9_0:skillNotAvilable(iter_9_0) then
			var_9_6:setGrayScale(1)
		else
			var_9_6:setGrayScale(0)
		end

		local var_9_8 = var_9_3:getContentSize().width
		local var_9_9 = var_9_3:getContentSize().height
		local var_9_10 = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

		var_9_10:setPosition(var_9_8 / 2, var_9_9 / 2)
		var_9_10:setAnchorPoint(cc.p(0.5, 0.5))
		var_9_10:setScale(var_9_9 / var_9_10:getHeight())

		local var_9_11 = var_9_9 / var_9_10:getHeight()
		local var_9_12 = cc.ClippingNode:create()

		var_9_12:setStencil(var_9_10)
		var_9_12:setInverted(true)
		var_9_12:setAlphaThreshold(0)
		var_9_3:addChild(var_9_12)
		var_9_12:addChild(var_9_6)
		var_9_6:setPosition(var_9_8 / 2, var_9_9 / 2)
		var_9_6:setAnchorPoint(cc.p(0.5, 0.5))

		local var_9_13 = var_9_9 / var_9_6:getHeight()

		var_9_6:setScale(var_9_13)
		var_9_12:setLocalZOrder(-1)

		local var_9_14 = xyd.getBorder(0)

		xyd.displaySpriteOnContainer(var_9_14, var_9_3, true)
		var_9_2:addChild(var_9_3)
		var_9_2:setContentSize(67, 67)
		var_9_4:addContent(var_9_2)
		var_9_4:setItemSize(67, 67)
		var_9_3:setPosition((iter_9_0 - 1) * 8 + 8, 0)
		arg_9_0.zglListview:addItem(var_9_4)
		var_9_3:setAnchorPoint(cc.p(0, 0))

		if arg_9_0.skills_[iter_9_0] == arg_9_0.currentSkillID_ then
			arg_9_0:createSkillEffect(var_9_3)
		end
	end

	arg_9_0.zglListview:reload()

	local var_9_15 = xyd.tables.skill:desc(arg_9_0.id)

	arg_9_0:updateZglTips(var_9_15, arg_9_0:nodeByName("di_contain"))
end

function var_0_0.createSkillEffect(arg_12_0, arg_12_1)
	arg_12_0.skillEffect_ = xyd.AssetLoader.get():loadSprite(var_0_3)

	arg_12_0.skillEffect_:addTo(arg_12_1)
	arg_12_0.skillEffect_:setAnchorPoint(cc.p(0.5, 0.5))
	arg_12_0.skillEffect_:setLocalZOrder(101)
	arg_12_0.skillEffect_:setScale(0.94)
	arg_12_0.skillEffect_:setPosition(33.5, 33.5)
end

function var_0_0.skillNotAvilable(arg_13_0, arg_13_1)
	local var_13_0 = var_0_2:getItemID(arg_13_0.skills_[arg_13_1])

	if arg_13_0.selfPlayer_:getBackpack():getItemNumByID(var_13_0) == 0 then
		return true
	else
		return false
	end
end

function var_0_0.changeSkillIndex(arg_14_0)
	local var_14_0 = var_0_2:getItemID(arg_14_0.currentSkillID_)
	local var_14_1 = {
		skill_index = arg_14_0.tipIndex_,
		skill_item = var_14_0,
		partner_id = arg_14_0.partnerID_
	}

	xyd.Backend.get():request(xyd.mid.CHANGE_PARTNER_SKILL, var_14_1, function(arg_15_0, arg_15_1)
		if arg_15_0 == xyd.error.OK then
			arg_14_0.hero_:setSkillIDByIndex(arg_14_0.tipIndex_, arg_15_1.skill_ids[arg_14_0.tipIndex_])

			local var_15_0 = xyd.WindowManager.get():getWindow("hero_main")

			if var_15_0 and not tolua.isnull(var_15_0) then
				var_15_0:setSkillContainer(arg_14_0.hero_)
			end

			local var_15_1 = xyd.WindowManager.get():getWindow("course")

			if var_15_1 and not tolua.isnull(var_15_1) then
				var_15_1:updateBottomLeftContainer()
			end

			local var_15_2 = xyd.WindowManager.get():getWindow("skill_tips")

			xyd.WindowManager.get():closeWindow("skill_tips")
		end
	end, nil, nil, false)
end

function var_0_0.updateZglTips(arg_16_0, arg_16_1, arg_16_2)
	if arg_16_0.zglTiplist then
		arg_16_0.zglTiplist:removeAllItems()
	end

	local var_16_0 = {}
	local var_16_1 = arg_16_0:createLabel(20, cc.c3b(255, 255, 255), arg_16_1, 320)

	var_16_1:setAnchorPoint(cc.p(0, 0))
	var_16_1:setName("skill_desc1")
	var_16_1:setPosition(cc.p(0, 0))
	table.insert(var_16_0, var_16_1)

	if arg_16_0.skillLevel and arg_16_0.skillLevel > 0 and arg_16_0:generateSkillDesc2(arg_16_0.id, arg_16_0.skillLevel) then
		local var_16_2 = arg_16_0:createLabel(20, cc.c3b(241, 255, 15), nil, 320)

		var_16_2:setName("skill_desc2")
		var_16_2:setAnchorPoint(cc.p(0, 0))
		var_16_2:setPosition(cc.p(0, -10))
		var_16_2:setVisible(true)
		var_16_2:setString(arg_16_0:generateSkillDesc2(arg_16_0.currentSkillID_, arg_16_0.skillLevel + arg_16_0.extraSkillLevel))
		table.insert(var_16_0, var_16_2)
	end

	local var_16_3 = arg_16_2:getContentSize()

	arg_16_0.zglTiplist = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, var_16_3.width, var_16_3.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_16_2):onScroll(handler(arg_16_0, arg_16_0.scrollListener))

	arg_16_0.zglTiplist:setAnchorPoint(cc.p(0, 0))
	arg_16_0.zglTiplist:setPosition(0, 0)

	for iter_16_0 = 1, #var_16_0 do
		local var_16_4 = var_16_0[iter_16_0]:getContentSize().width
		local var_16_5 = var_16_0[iter_16_0]:getContentSize().height
		local var_16_6 = display.newNode()
		local var_16_7 = arg_16_0.zglTiplist:newItem()

		var_16_6:addChild(var_16_0[iter_16_0])
		var_16_6:setContentSize(var_16_4, var_16_5)
		var_16_7:addContent(var_16_6)
		var_16_7:setItemSize(var_16_4, var_16_5)
		arg_16_0.zglTiplist:addItem(var_16_7)
	end

	arg_16_0.zglTiplist:reload()
end

function var_0_0.scrollListener2(arg_17_0, arg_17_1)
	if arg_17_1.name == "began" then
		arg_17_0.scrollViewMoved_ = false
		arg_17_0.prevX_ = arg_17_1.x
	elseif arg_17_1.name == "moved" and 20 <= math.abs(arg_17_1.x - arg_17_0.prevX_) then
		arg_17_0.scrollViewMoved_ = true
	end
end

function var_0_0.setSkillTipPosition(arg_18_0, arg_18_1, arg_18_2, arg_18_3, arg_18_4)
	return
end

function var_0_0.generateSkillDesc2(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = ""
	local var_19_1 = xyd.tables.skill:desc2(arg_19_1)
	local var_19_2 = xyd.tables.skill:descNumInit(arg_19_1)
	local var_19_3 = xyd.tables.skill:descNumStep(arg_19_1)

	for iter_19_0 = 1, #var_19_1 do
		var_19_1[iter_19_0] = string.gsub(var_19_1[iter_19_0], "%%d%%", "%%d@")

		local var_19_4 = tonumber(var_19_2[iter_19_0]) + arg_19_2 * tonumber(var_19_3[iter_19_0])

		if var_19_4 - math.floor(var_19_4) ~= 0 then
			var_19_1[iter_19_0] = string.gsub(var_19_1[iter_19_0], "%%d", "%%.1f")
		end

		if iter_19_0 ~= #var_19_1 then
			var_19_0 = var_19_0 .. string.format(var_19_1[iter_19_0], var_19_4) .. "\n"
		else
			var_19_0 = var_19_0 .. string.format(var_19_1[iter_19_0], var_19_4)
		end

		var_19_0 = string.gsub(var_19_0, "@", "%%")
	end

	return var_19_0
end

function var_0_0.generateSkillDesc4(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0
	local var_20_1 = xyd.tables.skill:desc4(arg_20_1)
	local var_20_2 = xyd.tables.skill:desc4NumStep(arg_20_1)
	local var_20_3 = xyd.tables.skill:petStarType(arg_20_1)
	local var_20_4 = 0

	if arg_20_0.skillDesc4Change then
		if not var_20_1[2] then
			return ""
		end

		var_20_0 = string.gsub(var_20_1[2], "%%d%%", "%%d@")

		if var_20_3 == xyd.PetStarType.NUMBER then
			var_20_4 = var_20_2[2] * arg_20_2 or 0
		else
			var_20_4 = var_20_2[2]
		end
	else
		if not var_20_1[1] then
			return ""
		end

		var_20_0 = string.gsub(var_20_1[1], "%%d%%", "%%d@")
		var_20_4 = var_20_2[1] or 0
	end

	if var_20_4 - math.floor(var_20_4) ~= 0 then
		var_20_0 = string.gsub(var_20_0, "%%d", "%%.1f")
	end

	local var_20_5 = string.format(var_20_0, var_20_4)

	return (string.gsub(var_20_5, "@", "%%"))
end

function var_0_0.getTipHeight(arg_21_0)
	return arg_21_0.tipHeight
end

function var_0_0.updateTip(arg_22_0, arg_22_1)
	if arg_22_1.iconType ~= arg_22_0.iconType then
		return
	end

	if arg_22_1.iconType == TipType.SKILL_TIP then
		arg_22_0.id = arg_22_0.id
		arg_22_0.skillLevel = arg_22_1.skillLevel
		arg_22_0.extraSkillLevel = arg_22_1.extraSkillLevel

		arg_22_0:reloadTip()
	end
end

function var_0_0.reloadTip(arg_23_0)
	local var_23_0 = arg_23_0:nodeByName("skill_container"):getChildByName("skill_desc1")

	var_23_0:setString(xyd.tables.skill:desc(arg_23_0.id))

	local var_23_1 = var_23_0:getContentSize().height
	local var_23_2 = 0
	local var_23_3 = arg_23_0:nodeByName("skill_container"):getChildByName("skill_desc2")

	if not arg_23_0.skillLevel or arg_23_0.skillLevel <= 0 then
		var_23_3:setString("")
		var_23_3:setVisible(false)
	else
		var_23_3:setString(arg_23_0:generateSkillDesc2(arg_23_0.id, arg_23_0.skillLevel + arg_23_0.extraSkillLevel))

		var_23_2 = var_23_3:getContentSize().height

		var_23_3:setVisible(true)
	end

	arg_23_0.tipHeight = var_23_1 + var_23_2 + 50

	arg_23_0:setSkillTipPosition(var_23_0, var_23_3, var_23_1, var_23_2)

	local var_23_4 = arg_23_0:nodeByName("container")

	var_23_4:height(arg_23_0.tipHeight)

	local var_23_5 = var_23_4:getPositionY()

	arg_23_0:nodeByName("jiantou"):y(var_23_5 - arg_23_0.tipHeight / 2)
end

function var_0_0.getSoundEffect(arg_24_0)
	return xyd.tables.sound:getSound("ui_tips")
end

function var_0_0.getTipHeight(arg_25_0)
	return arg_25_0.tipHeight
end

function var_0_0.getTipWidth(arg_26_0)
	return arg_26_0:nodeByName("container"):getWidth()
end

function var_0_0.didOpen(arg_27_0, arg_27_1)
	var_0_0.super:didOpen(arg_27_1)
	arg_27_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

function var_0_0.willClose(arg_28_0, arg_28_1)
	var_0_0.super:willClose(arg_28_1)
end

function var_0_0.scrollListener(arg_29_0, arg_29_1)
	if arg_29_1.name == "began" then
		arg_29_0.scrollViewMoved_ = false
		arg_29_0.prevY_ = arg_29_1.y
	elseif arg_29_1.name == "moved" and 5 <= math.abs(arg_29_1.y - arg_29_0.prevY_) then
		arg_29_0.scrollViewMoved_ = true
	end
end

return var_0_0
