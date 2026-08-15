local var_0_0 = class("LoveLetterHeroChangeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = 3
local var_0_2 = xyd.tables.misc
local var_0_3 = xyd.tables.item
local var_0_4 = xyd.tables.translation
local var_0_5 = var_0_2:getValue("activity_love_letter_star")
local var_0_6 = var_0_2:getValue("activity_love_letter_exchange")
local var_0_7 = {
	txt_not_get = var_0_4:translation("LOVE_LETTER_NOT_GET"),
	txt_not_star = var_0_4:translation("LOVE_LETTER_NOT_STAR"),
	txt_not_extra = var_0_4:translation("LOVE_LETTER_NOT_EXTRA"),
	txt_star = var_0_4:translation("LOVE_LETTER_STAR"),
	txt_own = var_0_4:translation("LOVE_LETTER_OWN"),
	txt_duihuanbi = var_0_4:translation("LOVE_LETTER_DUIHUANBI"),
	txt_num = var_0_4:translation("LOVE_LETTER_NUM"),
	txt_up = var_0_4:translation("LOVE_LETTER_UP"),
	txt_down = var_0_4:translation("LOVE_LETTER_DOWN"),
	txt_false = var_0_4:translation("LOVE_LETTER_FALSE"),
	txt_succeed = var_0_4:translation("LOVE_LETTER_SUCCEED"),
	txt_choose_from = var_0_4:translation("LOVE_LETTER_CHOOSE_FROM"),
	txt_choose_to = var_0_4:translation("LOVE_LETTER_CHOOSE_TO"),
	txt_choose = var_0_4:translation("LOVE_LETTER_CHOOSE"),
	txt_choose_num = var_0_4:translation("LOVE_LETTER_CHOOSE_NUM"),
	txt_choose_get = var_0_4:translation("LOVE_LETTER_CHOOSE_GET"),
	txt_max = var_0_4:translation("MAX"),
	txt_cancel = var_0_4:translation("CANCEL"),
	txt_sure = var_0_4:translation("OK")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0 = arg_2_0:nodeByName("list_left"):getContentSize()

	arg_2_0.leftWidth = var_2_0.width
	arg_2_0.list_left = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_0.width, var_2_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_2_0:nodeByName("list_left")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.list_left:setDelegate(handler(arg_2_0, arg_2_0.leftDelegate))

	local var_2_1 = arg_2_0:nodeByName("list_right"):getContentSize()

	arg_2_0.rightWidth = var_2_1.width
	arg_2_0.list_right = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_2_0:nodeByName("list_right")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.list_right:setDelegate(handler(arg_2_0, arg_2_0.rightDelegate))
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.heros = xyd.tables.misc:getValue("activity_love_letter_hero")

	arg_4_0:nodeByName("txt_left"):setString(var_0_7.txt_choose_from)
	arg_4_0:nodeByName("txt_middle"):setString(var_0_7.txt_choose)
	arg_4_0:nodeByName("txt_right"):setString(var_0_7.txt_choose_to)
	arg_4_0:nodeByName("txt_choose_nun"):setString(var_0_7.txt_choose_num)
	arg_4_0:nodeByName("txt_qiyueshu"):setString(var_0_7.txt_choose_get)
	arg_4_0:nodeByName("txt_max"):setString(var_0_7.txt_max)
	arg_4_0:nodeByName("txt_cancel"):setString(var_0_7.txt_cancel)
	arg_4_0:nodeByName("txt_sure"):setString(var_0_7.txt_sure)

	arg_4_0.flagL = 1
	arg_4_0.flagR = 1
	arg_4_0.leftContainer = {}
	arg_4_0.rightContainer = {}
	arg_4_0.selectLeft = {}
	arg_4_0.selectRight = {}

	arg_4_0:initHeros()
	arg_4_0.list_left:reload()
	arg_4_0.list_right:reload()

	local var_4_0 = arg_4_0:nodeByName("container_middle")
	local var_4_1, var_4_2 = var_4_0:getChildByName("txt_duihuanbi"):getPosition()
	local var_4_3 = xyd.createLabel(22, cc.c4b(86, 35, 23, 255))

	var_4_3:setString(var_0_7.txt_duihuanbi)
	var_4_3:setAnchorPoint(cc.p(1, 0.5))
	var_4_3:addTo(var_4_0)
	var_4_3:setPosition(var_4_1, var_4_2)

	local var_4_4 = xyd.createLabel(22, cc.c4b(254, 115, 22, 255))

	var_4_4:setString(var_0_7.txt_num)
	var_4_4:setAnchorPoint(cc.p(0, 0.5))
	var_4_4:addTo(var_4_0)
	var_4_4:setPosition(var_4_1 + 5, var_4_2)
	arg_4_0:initMiddle()
end

function var_0_0.initHeros(arg_5_0)
	arg_5_0.leftHeros = {}
	arg_5_0.rightHeros = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.heros) do
		local var_5_0 = {
			itemId = iter_5_1,
			heroId = var_0_3:heroID(iter_5_1)
		}

		var_5_0.star = (arg_5_0.selfPlayer:getHeroIgnoreAwaken(var_5_0.heroId) or {}).star_ or 0
		var_5_0.extra = arg_5_0.backpack:getItemNumByID(iter_5_1) or 0

		table.insert(arg_5_0.leftHeros, var_5_0)
		table.insert(arg_5_0.rightHeros, clone(var_5_0))
	end

	table.sort(arg_5_0.leftHeros, function(arg_6_0, arg_6_1)
		if arg_6_0.star ~= var_0_5 or arg_6_1.star ~= var_0_5 then
			return arg_6_0.star > arg_6_1.star
		else
			return arg_6_0.extra > arg_6_1.extra
		end
	end)
	table.sort(arg_5_0.rightHeros, function(arg_7_0, arg_7_1)
		return arg_7_0.star < arg_7_1.star
	end)
end

function var_0_0.leftDelegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return math.ceil(#arg_8_0.leftHeros / 3)
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_0
		local var_8_1 = arg_8_1:dequeueItem()

		if not var_8_1 then
			var_8_1 = arg_8_1:newItem()
		else
			var_8_1:removeAllChildren(false)
		end

		local var_8_2 = display.newNode()
		local var_8_3 = 135

		for iter_8_0 = 1, 3 do
			local var_8_4 = arg_8_0.leftHeros[arg_8_3 * 3 - 3 + iter_8_0]

			if var_8_4 then
				local var_8_5, var_8_6 = arg_8_0:createChangeLeftNode(var_8_4, arg_8_3 * 3 - 3 + iter_8_0)

				var_8_5:addTo(var_8_2)
				var_8_5:setPositionX((iter_8_0 - 1) * (var_8_6 + 3))
			end
		end

		var_8_2:setContentSize(arg_8_0.leftWidth, var_8_3)
		var_8_1:addContent(var_8_2)
		var_8_1:setItemSize(arg_8_0.leftWidth, var_8_3)

		return var_8_1
	end
end

function var_0_0.rightDelegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return math.ceil(#arg_9_0.rightHeros / 3)
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_0
		local var_9_1 = arg_9_1:dequeueItem()

		if not var_9_1 then
			var_9_1 = arg_9_1:newItem()
		else
			var_9_1:removeAllChildren(false)
		end

		local var_9_2 = display.newNode()
		local var_9_3 = 135

		for iter_9_0 = 1, 3 do
			local var_9_4 = arg_9_0.rightHeros[arg_9_3 * 3 - 3 + iter_9_0]

			if var_9_4 then
				local var_9_5, var_9_6 = arg_9_0:createChangeRightNode(var_9_4, arg_9_3 * 3 - 3 + iter_9_0)

				var_9_5:addTo(var_9_2)
				var_9_5:setPositionX((iter_9_0 - 1) * (var_9_6 + 3))
			end
		end

		var_9_2:setContentSize(arg_9_0.rightWidth, var_9_3)
		var_9_1:addContent(var_9_2)
		var_9_1:setItemSize(arg_9_0.rightWidth, var_9_3)

		return var_9_1
	end
end

function var_0_0.createChangeLeftNode(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = arg_10_1.itemId
	local var_10_1 = arg_10_1.heroId
	local var_10_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1183/item_hero_change.csb")
	local var_10_3 = var_10_2:getChildByName("container")
	local var_10_4 = var_10_3:getChildByName("icon_hero")

	var_10_3:getChildByName("bg_grey"):setVisible(false)

	local var_10_5 = arg_10_0.backpack:getItemNumByID(var_10_0)

	xyd.setItemBorder(var_10_4, var_10_0, false, false, var_10_5)

	local var_10_6 = xyd.tables.hero:name(var_10_1)

	var_10_3:getChildByName("txt_hero"):setString(var_10_6)
	var_10_3:getChildByName("txt_hero"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	local var_10_7 = false

	if arg_10_0.flagL == arg_10_2 then
		var_10_7 = true
		arg_10_0.selectLeft.item = var_10_0
		arg_10_0.selectLeft.hero = var_10_1
		arg_10_0.selectLeft.isChange = true
	end

	var_10_3:getChildByName("bg_select"):setVisible(var_10_7)
	var_10_3:getChildByName("bg"):setVisible(not var_10_7)

	arg_10_0.leftContainer[arg_10_2] = var_10_3

	local var_10_8 = display.newNode()

	var_10_8:setContentSize(var_10_3:getContentSize())
	var_10_8:setAnchorPoint(cc.p(0, 0))
	var_10_8:addTo(var_10_3)

	local var_10_9 = arg_10_0.backpack:getItemNumByID(var_10_0)
	local var_10_10 = (arg_10_0.selfPlayer:getHeroIgnoreAwaken(var_10_1) or {}).star_ or 0
	local var_10_11 = var_10_3:getChildByName("bg_grey")
	local var_10_12 = var_10_3:getChildByName("bg_grey"):getChildByName("txt_state")

	if var_10_10 == 0 then
		var_10_11:setVisible(true)
		var_10_12:setString(var_0_7.txt_not_get)
		var_10_12:setColor(cc.c4b(147, 246, 255, 255))
		var_10_8:setTouchEnabled(false)

		if arg_10_0.flagL == arg_10_2 then
			arg_10_0.selectLeft.isChange = false
		end
	elseif var_10_10 < var_0_5 then
		var_10_11:setVisible(true)
		var_10_12:setString(var_0_7.txt_not_star)
		var_10_12:setColor(cc.c4b(147, 246, 255, 255))
		var_10_8:setTouchEnabled(false)

		if arg_10_0.flagL == arg_10_2 then
			arg_10_0.selectLeft.isChange = false
		end
	elseif var_10_9 == 0 then
		var_10_11:setVisible(true)
		var_10_12:setString(var_0_7.txt_not_extra)
		var_10_12:setColor(cc.c4b(147, 246, 255, 255))
		var_10_8:setTouchEnabled(false)

		if arg_10_0.flagL == arg_10_2 then
			arg_10_0.selectLeft.isChange = false
		end
	else
		var_10_8:setTouchEnabled(true)
		var_10_8:setTouchSwallowEnabled(false)

		if arg_10_0.flagL == arg_10_2 then
			arg_10_0.selectLeft.isChange = true
		end
	end

	var_10_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			var_10_3:setScale(0.9)

			return true
		elseif arg_11_0.name == "moved" then
			var_10_3:setScale(1)
		elseif arg_11_0.name == "ended" then
			var_10_3:setScale(1)

			var_10_7 = false

			if arg_10_0.leftContainer[arg_10_0.flagL] and not tolua.isnull(arg_10_0.leftContainer[arg_10_0.flagL]) then
				arg_10_0.leftContainer[arg_10_0.flagL]:getChildByName("bg_select"):setVisible(var_10_7)
				arg_10_0.leftContainer[arg_10_0.flagL]:getChildByName("bg"):setVisible(not var_10_7)
			end

			arg_10_0.flagL = arg_10_2
			var_10_7 = true

			arg_10_0.leftContainer[arg_10_2]:getChildByName("bg_select"):setVisible(var_10_7)
			arg_10_0.leftContainer[arg_10_2]:getChildByName("bg"):setVisible(not var_10_7)

			arg_10_0.selectLeft.item = var_10_0
			arg_10_0.selectLeft.hero = var_10_1

			arg_10_0:initMiddle()
		end
	end)

	return var_10_2, var_10_3:getWidth()
end

function var_0_0.createChangeRightNode(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_1.itemId
	local var_12_1 = arg_12_1.heroId
	local var_12_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1183/item_hero_change.csb")
	local var_12_3 = var_12_2:getChildByName("container")
	local var_12_4 = var_12_3:getChildByName("icon_hero")

	var_12_3:getChildByName("bg_grey"):setVisible(false)

	local var_12_5 = arg_12_0.backpack:getItemNumByID(var_12_0)

	xyd.setItemBorder(var_12_4, var_12_0, false, false, var_12_5)

	local var_12_6 = xyd.tables.hero:name(var_12_1)

	var_12_3:getChildByName("txt_hero"):setString(var_12_6)
	var_12_3:getChildByName("txt_hero"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	local var_12_7 = false

	if arg_12_0.flagR == arg_12_2 then
		var_12_7 = true
		arg_12_0.selectRight.item = var_12_0
		arg_12_0.selectRight.hero = var_12_1
	end

	var_12_3:getChildByName("bg_select"):setVisible(var_12_7)
	var_12_3:getChildByName("bg"):setVisible(not var_12_7)

	arg_12_0.rightContainer[arg_12_2] = var_12_3

	local var_12_8 = display.newNode()

	var_12_8:setContentSize(var_12_3:getContentSize())
	var_12_8:setAnchorPoint(cc.p(0, 0))
	var_12_8:addTo(var_12_3)

	local var_12_9 = (arg_12_0.selfPlayer:getHeroIgnoreAwaken(var_12_1) or {}).star_ or 0
	local var_12_10 = var_12_3:getChildByName("bg_grey")
	local var_12_11 = var_12_3:getChildByName("bg_grey"):getChildByName("txt_state")

	if var_12_9 == var_0_5 then
		var_12_10:setVisible(true)
		var_12_11:setString(var_0_7.txt_star)
		var_12_11:setColor(cc.c4b(255, 240, 0, 255))
		var_12_8:setTouchEnabled(false)

		if arg_12_0.flagR == arg_12_2 then
			arg_12_0.selectRight.isChange = true
		end
	else
		var_12_8:setTouchEnabled(true)
		var_12_8:setTouchSwallowEnabled(false)

		if arg_12_0.flagR == arg_12_2 then
			arg_12_0.selectRight.isChange = true
		end
	end

	var_12_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			var_12_3:setScale(0.9)

			return true
		elseif arg_13_0.name == "moved" then
			var_12_3:setScale(1)
		elseif arg_13_0.name == "ended" then
			var_12_3:setScale(1)

			var_12_7 = false

			if arg_12_0.rightContainer[arg_12_0.flagR] and not tolua.isnull(arg_12_0.rightContainer[arg_12_0.flagR]) then
				arg_12_0.rightContainer[arg_12_0.flagR]:getChildByName("bg_select"):setVisible(var_12_7)
				arg_12_0.rightContainer[arg_12_0.flagR]:getChildByName("bg"):setVisible(not var_12_7)
			end

			arg_12_0.flagR = arg_12_2
			var_12_7 = true

			arg_12_0.rightContainer[arg_12_2]:getChildByName("bg_select"):setVisible(var_12_7)
			arg_12_0.rightContainer[arg_12_2]:getChildByName("bg"):setVisible(not var_12_7)

			arg_12_0.selectRight.item = var_12_0
			arg_12_0.selectRight.hero = var_12_1

			arg_12_0:initMiddle()
		end
	end)

	return var_12_2, var_12_3:getWidth()
end

function var_0_0.initMiddle(arg_14_0)
	local var_14_0 = arg_14_0:nodeByName("container_middle")
	local var_14_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1183/item_hero_change.csb")
	local var_14_2 = var_14_1:getChildByName("container")
	local var_14_3 = var_14_2:getChildByName("icon_hero")

	xyd.setItemBorder(var_14_3, arg_14_0.selectLeft.item)

	local var_14_4 = xyd.tables.hero:name(arg_14_0.selectLeft.hero)

	var_14_2:getChildByName("txt_hero"):setString(var_14_4)
	var_14_2:getChildByName("txt_hero"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	if arg_14_0.selectLeft.isChange then
		var_14_2:getChildByName("bg_grey"):setVisible(false)
	else
		var_14_2:getChildByName("bg_grey"):setVisible(true)
	end

	local var_14_5 = arg_14_0.backpack:getItemNumByID(arg_14_0.selectLeft.item) or 0

	var_14_0:getChildByName("txt_from"):setString(var_0_7.txt_own .. var_14_5)

	local var_14_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1183/item_hero_change.csb")
	local var_14_7 = var_14_6:getChildByName("container")
	local var_14_8 = var_14_7:getChildByName("icon_hero")

	xyd.setItemBorder(var_14_8, arg_14_0.selectRight.item)

	local var_14_9 = xyd.tables.hero:name(arg_14_0.selectRight.hero)

	var_14_7:getChildByName("txt_hero"):setString(var_14_9)
	var_14_7:getChildByName("txt_hero"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	if arg_14_0.selectRight.isChange then
		var_14_7:getChildByName("bg_grey"):setVisible(false)
	else
		var_14_7:getChildByName("bg_grey"):setVisible(true)
	end

	local var_14_10 = arg_14_0.backpack:getItemNumByID(arg_14_0.selectRight.item) or 0

	var_14_0:getChildByName("txt_to"):setString(var_0_7.txt_own .. var_14_10)
	var_14_1:addTo(var_14_0:getChildByName("node_from"))
	var_14_6:addTo(var_14_0:getChildByName("node_to"))

	local var_14_11 = 0
	local var_14_12 = var_14_11 / 4
	local var_14_13 = var_14_5

	var_14_0:getChildByName("txt_use_num"):setString(var_14_11)
	var_14_0:getChildByName("txt_qiyueshu_num"):setString(var_14_12)

	local var_14_14 = arg_14_0:nodeByName("btn_add")
	local var_14_15 = arg_14_0:nodeByName("btn_sub")
	local var_14_16 = arg_14_0:nodeByName("btn_max")

	var_14_14:addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.began then
			var_14_14:setScale(0.9)
		elseif arg_15_1 == ccui.TouchEventType.ended then
			var_14_14:setScale(1)

			var_14_11 = var_14_11 + 4

			if var_14_11 > var_14_13 then
				var_14_11 = var_14_11 - 4

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_7.txt_up, nil, nil, nil, arg_14_0.colorMode)
			end

			var_14_12 = var_14_11 / 4

			var_14_0:getChildByName("txt_use_num"):setString(var_14_11)
			var_14_0:getChildByName("txt_qiyueshu_num"):setString(var_14_12)
		end
	end)
	var_14_15:addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.began then
			var_14_15:setScale(0.9)
		elseif arg_16_1 == ccui.TouchEventType.ended then
			var_14_15:setScale(1)

			var_14_11 = var_14_11 - 4

			if var_14_11 < 0 then
				var_14_11 = var_14_11 + 4

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_7.txt_down, nil, nil, nil, arg_14_0.colorMode)
			end

			var_14_12 = var_14_11 / 4

			var_14_0:getChildByName("txt_use_num"):setString(var_14_11)
			var_14_0:getChildByName("txt_qiyueshu_num"):setString(var_14_12)
		end
	end)
	var_14_16:addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.began then
			var_14_16:setScale(0.9)
		elseif arg_17_1 == ccui.TouchEventType.ended then
			var_14_16:setScale(1)

			var_14_11 = math.floor(var_14_13 / 4) * 4
			var_14_12 = var_14_11 / 4

			var_14_0:getChildByName("txt_use_num"):setString(var_14_11)
			var_14_0:getChildByName("txt_qiyueshu_num"):setString(var_14_12)
		end
	end)

	local var_14_17 = arg_14_0:nodeByName("btn_sure")

	var_14_17:addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.began then
			var_14_17:setScale(0.9)
		elseif arg_18_1 == ccui.TouchEventType.ended then
			var_14_17:setScale(1)

			local var_18_0 = {
				cost_item = arg_14_0.selectLeft.item,
				get_item = arg_14_0.selectRight.item,
				num = var_14_12
			}

			xyd.Backend.get():request(xyd.mid.LOVE_LETTER_CHANGE, var_18_0, function(arg_19_0, arg_19_1)
				if arg_14_0.selectRight.isChange and arg_14_0.selectLeft.isChange then
					if arg_19_0 == xyd.error.OK then
						arg_14_0.selfPlayer:handleRewardsWithoutShow(arg_19_1.awards)

						local var_19_0 = {
							itemID = arg_14_0.selectLeft.item,
							itemNum = var_14_11
						}

						arg_14_0.backpack:removeItem(var_19_0)

						local var_19_1 = arg_14_0.backpack:getItemNumByID(arg_14_0.selectLeft.item) or 0
						local var_19_2 = arg_14_0.backpack:getItemNumByID(arg_14_0.selectRight.item) or 0

						var_14_13 = var_19_1
						var_14_11 = 0
						var_14_12 = var_14_11 / 4

						var_14_0:getChildByName("txt_use_num"):setString(var_14_11)
						var_14_0:getChildByName("txt_qiyueshu_num"):setString(var_14_12)

						if arg_14_0.leftContainer[arg_14_0.flagL] and not tolua.isnull(arg_14_0.leftContainer[arg_14_0.flagL]) then
							arg_14_0.leftContainer[arg_14_0.flagL]:getChildByName("icon_hero"):removeAllChildren()

							local var_19_3 = arg_14_0.leftContainer[arg_14_0.flagL]:getChildByName("icon_hero")

							xyd.setItemBorder(var_19_3, arg_14_0.selectLeft.item, false, false, var_19_1)
						end

						if arg_14_0.rightContainer[arg_14_0.flagR] and not tolua.isnull(arg_14_0.rightContainer[arg_14_0.flagR]) then
							arg_14_0.rightContainer[arg_14_0.flagR]:getChildByName("icon_hero"):removeAllChildren()

							local var_19_4 = arg_14_0.rightContainer[arg_14_0.flagR]:getChildByName("icon_hero")

							xyd.setItemBorder(var_19_4, arg_14_0.selectRight.item, false, false, var_19_2)
						end

						var_14_0:getChildByName("txt_from"):setString(var_0_7.txt_own .. var_19_1)
						var_14_0:getChildByName("txt_to"):setString(var_0_7.txt_own .. var_19_2)
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_7.txt_succeed, nil, nil, nil, arg_14_0.colorMode)
					else
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_7.txt_false, nil, nil, nil, arg_14_0.colorMode)
					end
				else
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_7.txt_false, nil, nil, nil, arg_14_0.colorMode)

					return
				end
			end)
		end
	end)

	local var_14_18 = arg_14_0:nodeByName("btn_cancel")

	var_14_18:addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.began then
			var_14_18:setScale(0.9)
		elseif arg_20_1 == ccui.TouchEventType.ended then
			var_14_18:setScale(1)
			xyd.WindowManager.get():closeWindow(arg_14_0.name)
		end
	end)
end

function var_0_0.scrollListener(arg_21_0, arg_21_1)
	if arg_21_1.name == "began" then
		arg_21_0.scrollViewMoved_ = false
		arg_21_0.prevY_ = arg_21_1.y
	elseif arg_21_1.name == "moved" and 10 <= math.abs(arg_21_1.y - arg_21_0.prevY_) then
		arg_21_0.scrollViewMoved_ = true
	end
end

return var_0_0
