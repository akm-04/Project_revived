local var_0_0 = class("MemoriesOfSchoolRebornWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("framework.scheduler")
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = xyd.tables.item
local var_0_6 = xyd.tables.hero
local var_0_7 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
local var_0_8 = xyd.ModelManager.get():loadModel(xyd.ModelType.MEMORIES_OF_SCHOOL)
local var_0_9 = 10
local var_0_10 = 6

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("txt_title"):setString(var_0_1:translation("MEMORIES_OF_SCHOOL_TIPS13"))
	arg_2_0:nodeByName("txt_desc"):setString(var_0_1:translation("MEMORIES_OF_SCHOOL_TIPS14"))

	arg_2_0.diedHeros = arg_2_0:getDiedHeros()

	arg_2_0:initItemListViews()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.getDiedHeros(arg_4_0)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in pairs(var_0_8.heroStatus.self_list) do
		if iter_4_1.health == 1 and iter_4_1.hp == 0 then
			table.insert(var_4_0, var_0_7:getHero(tonumber(iter_4_0)))
		end
	end

	return var_4_0
end

function var_0_0.initItemListViews(arg_5_0)
	local var_5_0 = {
		touchOnContent = true,
		async = true,
		viewRect = cc.rect(0, 0, arg_5_0:nodeByName("heros_container"):getContentSize().width, arg_5_0:nodeByName("heros_container"):getContentSize().height + 10),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}

	arg_5_0.heroList = cc.ui.UIListView.new(var_5_0):addTo(arg_5_0:nodeByName("heros_container"))

	arg_5_0.heroList:setDelegate(handler(arg_5_0, arg_5_0.delegate))
	arg_5_0.heroList:reload()
end

function var_0_0.delegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return math.ceil(#arg_6_0.diedHeros / 6)
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0
		local var_6_1
		local var_6_2 = arg_6_0.heroList:dequeueItem()

		if not var_6_2 then
			var_6_2 = arg_6_0.heroList:newItem()
		else
			var_6_2:removeAllChildren()
		end

		local var_6_3 = display.newNode()

		for iter_6_0 = 1, 6 do
			if not arg_6_0.diedHeros[6 * (arg_6_3 - 1) + iter_6_0] then
				break
			end

			cell = display.newNode()

			arg_6_0:initHeroCell(cell, arg_6_0.diedHeros[6 * (arg_6_3 - 1) + iter_6_0])
			cell:addTo(var_6_3)

			local var_6_4 = cell:getContentSize().width
			local var_6_5 = cell:getContentSize().height
			local var_6_6 = (arg_6_0.heroList.viewRect_.width - var_6_4 * var_0_10) / (var_0_10 + 1)

			cell:setPosition(var_6_6 * iter_6_0 + (iter_6_0 - 1) * var_6_4 + var_6_4 / 2, var_0_9 + var_6_5 / 2 - 2)
			var_6_3:size(840, var_6_5 + var_0_9)
			var_6_2:setItemSize(840, var_6_5 + var_0_9)
		end

		var_6_2:addContent(var_6_3)

		return var_6_2
	end
end

function var_0_0.initHeroCell(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/hero_avatar_new.csb")

	var_7_0:getChildByName("yongbing_tubiao"):setVisible(false)

	local var_7_1 = var_7_0:getChildByName("background"):getContentSize()

	var_7_0:setContentSize(var_7_1)
	arg_7_1:setContentSize(cc.size(var_7_1.width, var_7_1.height + 5))
	xyd.setAvatarBorderNewUI(arg_7_2, var_7_0:getChildByName("avatar"))

	local var_7_2 = var_7_0:getChildByName("chosen")

	var_7_2:setLocalZOrder(100)
	var_7_2:setVisible(false)

	local var_7_3 = var_7_0:getChildByName("avatar_mask")

	var_7_3:setLocalZOrder(2)
	var_7_3:setVisible(false)
	var_7_0:getChildByName("is_can_rent"):setVisible(false)

	for iter_7_0 = 1, 3 do
		var_7_0:getChildByName("team" .. iter_7_0):setVisible(false)
	end

	var_7_0:getChildByName("lv_txt"):setString(arg_7_2:getLevel())
	var_7_0:getChildByName("name_text"):setString(arg_7_2:getName())

	local var_7_4 = var_7_0:getChildByName("hp_bar")
	local var_7_5 = var_7_0:getChildByName("mp_bar")
	local var_7_6 = var_7_0:getChildByName("dead_text")

	if not tolua.isnull(var_7_6) then
		var_7_6:setVisible(false)
	end

	var_7_4:hide()
	var_7_5:hide()
	var_7_0:getChildByName("hp_di"):hide()
	var_7_0:getChildByName("mp_di"):hide()
	var_7_0:setName("layout")
	var_7_0:setPosition(cc.p(0, 0))

	arg_7_1.data = arg_7_2

	arg_7_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_7_1:addChild(var_7_0)
	arg_7_1:setTouchSwallowEnabled(false)
	arg_7_1:setTouchEnabled(true)

	arg_7_1.hero = arg_7_2

	arg_7_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			arg_7_0.startClick_ = true
			arg_7_0.prevX_ = arg_8_0.x
			arg_7_0.prevY_ = arg_8_0.y
		elseif arg_8_0.name == "moved" then
			if math.abs(arg_8_0.y - arg_7_0.prevY_) > 5 or math.abs(arg_8_0.x - arg_7_0.prevX_) > 5 then
				arg_7_0.startClick_ = false
			end
		elseif arg_8_0.name == "ended" and arg_7_0.startClick_ then
			arg_7_0:clickAvatar(arg_7_1)
		end

		return true
	end)
end

function var_0_0.clickAvatar(arg_9_0, arg_9_1)
	print("the hero to reborn is " .. arg_9_1.hero:getHeroID())

	local var_9_0 = string.format(xyd.tables.translation:translation("MEMORIES_OF_SCHOOL_REBORN_CONFIRM"), xyd.tables.refreshCost:mazeRebornCost(tonumber(var_0_8.baseInfo.revive_times) + 1))

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_0, function()
		if xyd.tables.refreshCost:mazeRebornCost(tonumber(var_0_8.baseInfo.revive_times) + 1) > var_0_7.crystal then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
				local var_11_0 = {}

				var_11_0.windowState = true

				xyd.WindowManager.get():openWindow("vip_recharge", var_11_0)
			end, nil, nil, arg_9_0.colorMode)
		else
			var_0_8:rebornHero({
				partner_id = arg_9_1.hero:getHeroID()
			}, function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					var_0_8.baseInfo.revive_times = var_0_8.baseInfo.revive_times + 1
					arg_9_0.diedHeros = arg_9_0:getDiedHeros()

					arg_9_0.heroList:reload()
				end
			end)
		end
	end, nil, 0, arg_9_0.colorMode)
end

function var_0_0.initButtons(arg_13_0)
	return
end

function var_0_0.initDetailContainer(arg_14_0)
	return
end

return var_0_0
