local var_0_0 = class("MemoriesOfSchoolMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("framework.scheduler")
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = import("app.common.ui.SpriteNodeButton")
local var_0_6 = xyd.tables.item
local var_0_7 = xyd.tables.hero
local var_0_8
local var_0_9
local var_0_10 = 1
local var_0_11 = 2
local var_0_12 = 1280
local var_0_13 = 720
local var_0_14 = 10001086

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	var_0_8 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	var_0_9 = xyd.ModelManager.get():loadModel(xyd.ModelType.MEMORIES_OF_SCHOOL)

	if arg_1_2 and arg_1_2.response then
		arg_1_0.response = arg_1_2.response
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("txt_rate"):setString(var_0_1:translation("MEMORIES_OF_SCHOOL_TIPS6"))
	arg_2_0:nodeByName("txt_have_got"):setString(var_0_1:translation("MEMORIES_OF_SCHOOL_TIPS7"))

	local var_2_0 = {
		isEcoBar = 0,
		show_rule = true,
		callback = function()
			if arg_2_0.status == var_0_10 or arg_2_0.status == var_0_11 and var_0_9.baseInfo.is_game_start == 1 then
				xyd.WindowManager.get():closeWindow(arg_2_0)
			else
				arg_2_0:updateWindow()
			end
		end
	}

	arg_2_0:addTopSidebar(var_2_0)

	arg_2_0.rule_btn = arg_2_0:nodeByName("top_sidebar"):nodeByName("rule")

	xyd.addTouchEvent(arg_2_0.rule_btn, function()
		local var_4_0 = {}

		var_4_0.title_name = "MAZE_RULE_TITLE"
		var_4_0.rule = "MAZE_RULE_TEXT"
		var_4_0.style = xyd.RuleStyle.BLUE

		xyd.WindowManager.get():openWindow("new_text_rule", var_4_0)
	end)
	arg_2_0:updateWindow()
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_0, arg_5_1)
end

function var_0_0.updateWindow(arg_6_0, arg_6_1)
	arg_6_0.rareAwards = {}

	arg_6_0:nodeByName("main_bg"):setScale(0.5)
	arg_6_0:nodeByName("main_bg"):setAnchorPoint(cc.p(0.5, 0.5))

	if not arg_6_0.response and not arg_6_1 then
		var_0_9:getInfo({}, function(arg_7_0, arg_7_1)
			if tolua.isnull(arg_6_0) then
				return
			end

			arg_6_0.hero_id = tonumber(arg_7_1.base_info.hero_id)

			if arg_7_1.base_info.is_game_start == 0 then
				arg_6_0:layout()
			else
				local var_7_0 = arg_6_0:nodeByName("main_bg")
				local var_7_1 = arg_6_0:nodeByName("button_" .. arg_6_0.hero_id):getPositionX()
				local var_7_2 = arg_6_0:nodeByName("button_" .. arg_6_0.hero_id):getPositionY()

				var_7_0:setAnchorPoint(cc.p(math.min(math.max(var_7_1, 320), 960) / var_0_12, math.min(math.max(var_7_2, 180), 540) / var_0_13))
				var_7_0:setPosition(640, 360)
				arg_6_0:initDetailContainer()
				var_7_0:setScale(1)
			end
		end)
	else
		local var_6_0 = arg_6_0.response or arg_6_1

		if tolua.isnull(arg_6_0) then
			return
		end

		arg_6_0.hero_id = tonumber(var_6_0.base_info.hero_id)

		if var_6_0.base_info.is_game_start == 0 then
			arg_6_0:layout()
		else
			local var_6_1 = arg_6_0:nodeByName("main_bg")
			local var_6_2 = arg_6_0:nodeByName("button_" .. arg_6_0.hero_id):getPositionX()
			local var_6_3 = arg_6_0:nodeByName("button_" .. arg_6_0.hero_id):getPositionY()

			var_6_1:setAnchorPoint(cc.p(math.min(math.max(var_6_2, 320), 960) / var_0_12, math.min(math.max(var_6_3, 180), 540) / var_0_13))
			var_6_1:setPosition(640, 360)
			arg_6_0:initDetailContainer()
			var_6_1:setScale(1)
		end

		arg_6_0.response = nil
	end
end

function var_0_0.initItemListViews(arg_8_0)
	arg_8_0:nodeByName("have_got_container"):removeAllChildren()
	arg_8_0:nodeByName("rare_bonus_container"):removeAllChildren()

	local var_8_0 = {
		touchOnContent = true,
		async = false,
		viewRect = cc.rect(0, 0, arg_8_0:nodeByName("have_got_container"):getContentSize().width, arg_8_0:nodeByName("have_got_container"):getContentSize().height + 10),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}

	arg_8_0.haveGotList = cc.ui.UIListView.new(var_8_0):addTo(arg_8_0:nodeByName("have_got_container"))

	local var_8_1 = {
		touchOnContent = true,
		async = false,
		viewRect = cc.rect(0, 0, arg_8_0:nodeByName("rare_bonus_container"):getContentSize().width, arg_8_0:nodeByName("rare_bonus_container"):getContentSize().height + 10),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}

	arg_8_0.rareList = cc.ui.UIListView.new(var_8_1):addTo(arg_8_0:nodeByName("rare_bonus_container"))

	for iter_8_0 = 1, arg_8_0:rareDelegate(nil, cc.ui.UIListView.COUNT_TAG) do
		local var_8_2 = arg_8_0:rareDelegate(nil, cc.ui.UIListView.CELL_TAG, iter_8_0)

		arg_8_0.rareList:addItem(var_8_2)
	end

	arg_8_0.rareList:reload()

	for iter_8_1 = 1, arg_8_0:haveGotDelegate(nil, cc.ui.UIListView.COUNT_TAG) do
		local var_8_3 = arg_8_0:haveGotDelegate(nil, cc.ui.UIListView.CELL_TAG, iter_8_1)

		arg_8_0.haveGotList:addItem(var_8_3)
	end

	arg_8_0.haveGotList:reload()
end

function var_0_0.rareDelegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return math.ceil(#arg_9_0.rareAwards / 5)
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_0
		local var_9_1
		local var_9_2 = arg_9_0.rareList:dequeueItem()

		if not var_9_2 then
			var_9_2 = arg_9_0.rareList:newItem()
		else
			var_9_2:removeAllChildren()
		end

		local var_9_3 = display.newNode()

		var_9_3:setContentSize(390, 70)

		for iter_9_0 = 1, 5 do
			if not arg_9_0.rareAwards[5 * (arg_9_3 - 1) + iter_9_0] then
				break
			end

			local var_9_4 = display.newNode()

			var_9_4:setContentSize(70, 70)
			xyd.setItemBorder(var_9_4, tonumber(arg_9_0.rareAwards[5 * (arg_9_3 - 1) + iter_9_0]))
			var_9_4:setTouchEnabled(true)
			var_9_4:setTouchSwallowEnabled(false)
			var_9_4:addTo(var_9_3)
			var_9_4:setPosition(80 * (iter_9_0 - 1), 0)
			var_9_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
				if arg_10_0.name == "began" then
					touchBeganY = arg_10_0.y

					if not xyd.WindowManager.get():getWindow("new_item_tips") then
						local var_10_0 = {
							id = tonumber(arg_9_0.rareAwards[5 * (arg_9_3 - 1) + iter_9_0])
						}

						var_10_0.hasNum = 0
						var_10_0.showNum = false

						local var_10_1 = xyd.WindowManager.get():openWindow("new_item_tips", var_10_0)

						xyd.adaptToWorldPosition(var_9_4, var_10_1)
					end

					return true
				elseif arg_10_0.name == "moved" then
					local var_10_2 = arg_10_0.y

					if math.abs(var_10_2 - touchBeganY) > 30 then
						xyd.WindowManager.get():closeWindow("new_item_tips")
					end
				elseif arg_10_0.name == "ended" then
					wnd = xyd.WindowManager.get():closeWindow("new_item_tips")

					local var_10_3 = var_9_4:convertToWorldSpace(cc.p(0, 0))

					if arg_10_0.y - var_10_3.y < 0 or arg_10_0.y - var_10_3.y > 113 or arg_10_0.x - var_10_3.x < 0 or arg_10_0.x - var_10_3.x > 113 then
						return
					end
				end

				return true
			end)
		end

		var_9_2:setItemSize(390, 80)
		var_9_2:addContent(var_9_3)

		return var_9_2
	end
end

function var_0_0.haveGotDelegate(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	if cc.ui.UIListView.COUNT_TAG == arg_11_2 then
		return math.ceil(#var_0_9.dropsInfo / 5)
	elseif cc.ui.UIListView.CELL_TAG == arg_11_2 then
		local var_11_0
		local var_11_1
		local var_11_2 = arg_11_0.haveGotList:dequeueItem()

		if not var_11_2 then
			var_11_2 = arg_11_0.haveGotList:newItem()
		else
			var_11_2:removeAllChildren()
		end

		local var_11_3 = display.newNode()

		var_11_3:size(390, 70)

		for iter_11_0 = 1, 5 do
			if not var_0_9.dropsInfo[5 * (arg_11_3 - 1) + iter_11_0] then
				break
			end

			local var_11_4 = display.newNode()

			var_11_4:size(70, 70)
			xyd.setItemBorder(var_11_4, tonumber(var_0_9.dropsInfo[5 * (arg_11_3 - 1) + iter_11_0].item_id), nil, nil, tonumber(var_0_9.dropsInfo[5 * (arg_11_3 - 1) + iter_11_0].item_num))
			var_11_4:addTo(var_11_3)

			local var_11_5 = {
				id = tonumber(var_0_9.dropsInfo[5 * (arg_11_3 - 1) + iter_11_0].item_id)
			}

			var_11_4:setPosition(80 * (iter_11_0 - 1), 0)
			xyd.addTips(var_11_4, var_11_5)
		end

		var_11_2:setItemSize(390, 80)
		var_11_2:addContent(var_11_3)

		return var_11_2
	end
end

function var_0_0.layout(arg_12_0)
	arg_12_0:nodeByName("main_bg"):setScale(0.5)
	arg_12_0:nodeByName("main_bg"):setAnchorPoint(cc.p(0.5, 0.5))
	arg_12_0:initButtons()
	arg_12_0:nodeByName("detail_container"):setVisible(false)

	arg_12_0.status = var_0_10
end

function var_0_0.initButtons(arg_13_0)
	for iter_13_0 = 1, #xyd.tables.misc.memoriesOfSchoolMazeGirls do
		arg_13_0:nodeByName("button_" .. xyd.tables.misc.memoriesOfSchoolMazeGirls[iter_13_0]):setVisible(true)

		local var_13_0 = arg_13_0:nodeByName("main_bg")

		arg_13_0:nodeByName("button_" .. xyd.tables.misc.memoriesOfSchoolMazeGirls[iter_13_0]):addTouchEventListener(function(arg_14_0, arg_14_1)
			xyd.buttonScaleAnim(arg_14_0, arg_14_1)

			if arg_14_1 == ccui.TouchEventType.ended then
				arg_13_0.hero_id = tonumber(xyd.tables.misc.memoriesOfSchoolMazeGirls[iter_13_0])

				arg_13_0:initDetailContainer()
				var_13_0:setScale(1)
			end
		end)
	end
end

function var_0_0.setIsShow(arg_15_0)
	arg_15_0.isShow = false

	arg_15_0.model:idle()
end

function var_0_0.resetModelState(arg_16_0)
	if arg_16_0.modelState == 8 then
		arg_16_0.modelState = arg_16_0.modelState + 1
	end

	arg_16_0.modelState = arg_16_0.modelState % 8
	arg_16_0.isShow = true

	local var_16_0

	if arg_16_0.modelState == xyd.ModelState.Walk then
		arg_16_0.model:walk(true)

		arg_16_0.isShow = false
		var_16_0 = xyd.tables.model:getMoveSound(tonumber(arg_16_0.hero_id))
	elseif arg_16_0.modelState == xyd.ModelState.Win then
		arg_16_0.model:win(false, handler(arg_16_0, arg_16_0.setIsShow))

		var_16_0 = xyd.tables.model:getWinSound(tonumber(arg_16_0.hero_id))
	elseif arg_16_0.modelState == xyd.ModelState.Attack1 then
		arg_16_0.model:attack(1, nil, nil, handler(arg_16_0, arg_16_0.setIsShow))

		var_16_0 = xyd.tables.model:getNormalAttackSound(tonumber(arg_16_0.hero_id))
	elseif arg_16_0.modelState == xyd.ModelState.Attack2 then
		arg_16_0.model:attack(2, nil, nil, handler(arg_16_0, arg_16_0.setIsShow))

		var_16_0 = xyd.tables.model:getAttack1Sound(tonumber(arg_16_0.hero_id))
	elseif arg_16_0.modelState == xyd.ModelState.Attack3 then
		arg_16_0.model:attack(3, nil, nil, handler(arg_16_0, arg_16_0.setIsShow))

		var_16_0 = xyd.tables.model:getAttack2Sound(tonumber(arg_16_0.hero_id))
	elseif arg_16_0.modelState == xyd.ModelState.Attack4 then
		if not arg_16_0.model:hasAnimation("gongji04") then
			arg_16_0.modelState = arg_16_0.modelState + 1

			arg_16_0:resetModelState()

			return
		end

		arg_16_0.model:attack(4, nil, nil, handler(arg_16_0, arg_16_0.setIsShow))

		var_16_0 = xyd.tables.model:getAttack4Sound(tonumber(arg_16_0.hero_id))
	elseif arg_16_0.modelState == xyd.ModelState.Attack5 then
		if not arg_16_0.model:hasAnimation("gongji05") then
			arg_16_0.modelState = arg_16_0.modelState + 1

			arg_16_0:resetModelState()

			return
		end

		arg_16_0.model:attack(5, nil, nil, handler(arg_16_0, arg_16_0.setIsShow))

		var_16_0 = xyd.tables.model:getAttack4Sound(tonumber(arg_16_0.hero_id))
	else
		arg_16_0.setIsShow()
	end

	if var_16_0 and var_16_0 ~= "" then
		audio.stopAllSounds()
		audio.playSound(var_16_0, false)
	end

	arg_16_0.modelState = arg_16_0.modelState + 1
end

function var_0_0.initDetailContainer(arg_17_0)
	for iter_17_0 = 1, #xyd.tables.misc.memoriesOfSchoolMazeGirls do
		arg_17_0:nodeByName("button_" .. xyd.tables.misc.memoriesOfSchoolMazeGirls[iter_17_0]):setVisible(false)
	end

	local var_17_0 = arg_17_0:nodeByName("button_" .. arg_17_0.hero_id):getPositionX()
	local var_17_1 = arg_17_0:nodeByName("button_" .. arg_17_0.hero_id):getPositionY()
	local var_17_2 = arg_17_0:nodeByName("main_bg")

	var_17_2:setAnchorPoint(cc.p(math.min(math.max(var_17_0, 320), 960) / var_0_12, math.min(math.max(var_17_1, 180), 540) / var_0_13))
	var_17_2:setPosition(640, 360)

	arg_17_0.status = var_0_11
	arg_17_0.model = nil
	arg_17_0.model = xyd.HeroAnimation.new(nil, tonumber(arg_17_0.hero_id), 0.5, {
		loadAttackEffect = true
	})

	local var_17_3 = arg_17_0.model

	arg_17_0:nodeByName("model_node"):removeAllChildren()
	var_17_3:setScale(2)
	var_17_3:addTo(arg_17_0:nodeByName("model_node"))
	var_17_3:setAnchorPoint(cc.p(0, 0))
	var_17_3:setTouchEnabled(true)
	var_17_3:setTouchSwallowEnabled(false)

	arg_17_0.modelState = xyd.ModelState.Walk

	var_17_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
		if arg_18_0.name == "ended" and not arg_17_0.isShow then
			arg_17_0:resetModelState()
		end

		return true
	end)
	arg_17_0:setIsShow()
	arg_17_0:nodeByName("hero_name"):setTexture("windows/memories_of_school/hero_name/" .. arg_17_0.hero_id .. ".png")
	arg_17_0:nodeByName("detail_container"):setVisible(true)

	arg_17_0.rareAwards = xyd.tables.mazePartnerCampaign:awards(arg_17_0.hero_id)

	if var_0_9.baseInfo.is_game_start == 0 then
		arg_17_0:nodeByName("continue_button"):setVisible(false)
		arg_17_0:nodeByName("start_button"):setVisible(true)
	else
		arg_17_0:nodeByName("start_button"):setVisible(false)
		arg_17_0:nodeByName("continue_button"):setVisible(true)
	end

	arg_17_0:nodeByName("start_button"):addTouchEventListener(function(arg_19_0, arg_19_1)
		xyd.buttonScaleAnim(arg_19_0, arg_19_1)

		if arg_19_1 == ccui.TouchEventType.ended then
			var_0_9:startGame({
				hero_id = arg_17_0.hero_id
			}, function(arg_20_0, arg_20_1)
				xyd.WindowManager.get():openWindow("memories_of_school", {
					response = clone(arg_20_1)
				})
			end)
		end
	end)
	arg_17_0:nodeByName("continue_button"):addTouchEventListener(function(arg_21_0, arg_21_1)
		xyd.buttonScaleAnim(arg_21_0, arg_21_1)

		if arg_21_1 == ccui.TouchEventType.ended then
			var_0_9:getInfo({}, function(arg_22_0, arg_22_1)
				xyd.WindowManager.get():openWindow("memories_of_school", {
					response = clone(arg_22_1)
				})
			end)
		end
	end)
	arg_17_0:initItemListViews()
	arg_17_0:nodeByName("max_floor_txt"):setString(string.format(var_0_1:translation("MEMORIES_OF_SCHOOL_MAX_FLOOR_TIPS"), var_0_9.maxFloorInfo[tostring(arg_17_0.hero_id)] or 0))
end

return var_0_0
