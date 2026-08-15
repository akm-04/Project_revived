local var_0_0 = class("MonsterProphecyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = 3
local var_0_4 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.listView_ = cc.ui.UIListView.new({
		touchOnContent = true,
		async = true,
		viewRect = cc.rect(0, 0, arg_2_0:nodeByName("container"):getWidth(), arg_2_0:nodeByName("container"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_2_0:nodeByName("container")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.listView_:setTouchSwallowEnabled(true)
	arg_2_0.listView_:setDelegate(handler(arg_2_0, arg_2_0.delegate))
	arg_2_0:nodeByName("label_name"):setString(var_0_4:translation("LEITAI_TITLE"))

	arg_2_0.openIds = arg_2_1.openIds

	arg_2_0:loadChallenge(xyd.mid.CHALLENGEINFO, function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			arg_2_0:getNextMonster(arg_3_1.challenges[1].id)
			arg_2_0.listView_:reload()
		end
	end)
end

function var_0_0.delegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #arg_4_0.nextMonster
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		if arg_4_3 > #arg_4_0.nextMonster then
			return nil
		end

		local var_4_0 = arg_4_0.listView_:dequeueItem()

		if not var_4_0 then
			var_4_0 = arg_4_0.listView_:newItem()
		else
			var_4_0:removeAllChildren(true)
		end

		local var_4_1 = arg_4_0.nextMonster[arg_4_3]
		local var_4_2 = display.newNode()

		arg_4_0:initCell(var_4_2, var_4_1, arg_4_3)

		local var_4_3 = display.newNode()

		var_4_3:addChild(var_4_2)
		var_4_3:setContentSize(335, 500)
		var_4_0:setItemSize(335, 500)
		var_4_0:addContent(var_4_3)

		return var_4_0
	end
end

function var_0_0.initCell(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/futrueprophecy/future_item.csb")
	local var_5_1 = var_5_0:getChildByName("container")
	local var_5_2 = var_5_1:getContentSize()
	local var_5_3 = var_5_1:getChildByName("bar"):getContentSize()
	local var_5_4 = var_0_2.new({
		size = var_5_3.width
	})

	var_5_4:addTo(var_5_1)
	var_5_4:setAnchorPoint(0.5, 0.5)
	var_5_4:setPosition(var_5_1:getChildByName("bar"):getPosition())

	local var_5_5 = var_0_2.new({
		size = var_5_3.width
	})

	var_5_5:addTo(var_5_1)
	var_5_5:setAnchorPoint(0.5, 0.5)
	var_5_5:setPosition(var_5_1:getChildByName("bar_down"):getPosition())

	local var_5_6
	local var_5_7
	local var_5_8
	local var_5_9

	if arg_5_2.monsterid then
		var_5_6 = xyd.tables.challenge:challengeName(arg_5_2.monsterid)
		var_5_7 = xyd.tables.challenge:itemDisplay(arg_5_2.monsterid) or {}
		var_5_8 = xyd.tables.challenge:challengeTypedes(arg_5_2.monsterid)
		var_5_9 = arg_5_0:getTime(arg_5_3)
	else
		var_5_6 = arg_5_2.trialName
		var_5_7 = xyd.tables.trialConfig:showItems(arg_5_2.idx)
		var_5_8 = xyd.tables.trialConfig:desc(arg_5_2.idx)
	end

	var_5_1:getChildByName("label_name"):setString(var_5_6)
	var_5_1:getChildByName("txt_describe"):setString(var_5_8)

	local var_5_10 = xyd.AssetLoader:get():loadSprite(arg_5_2.iconPath)

	var_5_10:setScale(arg_5_2.scale)

	local var_5_11 = {
		itemTable = var_5_7,
		monsterName = var_5_6,
		des = var_5_8
	}

	if not var_5_9 then
		var_5_1:getChildByName("txt_time"):setString(var_0_4:translation("TRIAL_CONFIG_" .. arg_5_2.idx))
	else
		var_5_1:getChildByName("txt_time"):setString(var_5_9.month .. var_0_4:translation("MONTH") .. var_5_9.day .. var_0_4:translation("DAY") .. var_0_4:translation("MONSTER_PROPHECY_TIP_1"))
	end

	local var_5_12 = var_5_1:getChildByName("container_monster")

	var_5_10:addTo(var_5_12)
	var_5_10:setPosition(var_5_12:getWidth() / 2, var_5_12:getHeight() / 2 - 25)
	var_5_0:setContentSize(var_5_2)
	arg_5_1:setContentSize(var_5_2)
	var_5_0:setName("layout")
	var_5_0:setPosition(cc.p(0, 0))
	arg_5_1:addChild(var_5_0)
	arg_5_1:setTouchSwallowEnabled(false)
	arg_5_1:setTouchEnabled(true)

	local var_5_13 = var_5_1:getChildByName("item_list")

	for iter_5_0 = 1, 4 do
		local var_5_14 = cc.Node:create()

		var_5_14:setContentSize(65, 65)
		xyd.setItemBorder(var_5_14, var_5_7[iter_5_0])

		local var_5_15 = {}

		arg_5_0:tipsFormat(var_5_14, var_5_7[iter_5_0], var_5_15)
		arg_5_0:addTips(var_5_14, var_5_15)
		var_5_14:addTo(var_5_13)
		var_5_14:setPosition(iter_5_0 * 70 - 65, 10)
		var_5_14:setTouchEnabled(true)
		var_5_14:setTouchSwallowEnabled(false)
	end
end

function var_0_0.getTime(arg_6_0, arg_6_1)
	local var_6_0 = {}
	local var_6_1 = 0
	local var_6_2 = os.date("*t", xyd.ServerTime.get():getServerTime())

	if var_6_2.hour >= 5 and var_6_2.hour < 24 then
		var_6_1 = 1
	end

	local var_6_3 = 0

	for iter_6_0 = var_6_1, 2 + var_6_1 do
		var_6_3 = var_6_3 + 1
		var_6_0[var_6_3] = os.date("*t", xyd.ServerTime.get():getServerTime() + iter_6_0 * xyd.OneDaySec)
	end

	return var_6_0[arg_6_1] or 0
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.startClick_ = true
		arg_7_0.prevX_ = arg_7_1.x
	elseif arg_7_1.name == "moved" and 20 <= math.abs(arg_7_1.x - arg_7_0.prevX_) then
		arg_7_0.startClick_ = false
	end
end

function var_0_0.getNextMonster(arg_8_0, arg_8_1)
	arg_8_0.nextMonster = {}

	local var_8_0 = xyd.tables.challenge:nextChallenge(arg_8_1)
	local var_8_1 = xyd.tables.timeTravel:trialModelNo(var_8_0)

	table.insert(arg_8_0.nextMonster, {
		scale = 0.6,
		monsterid = var_8_0,
		iconPath = var_8_1
	})

	while #arg_8_0.nextMonster ~= 3 do
		var_8_0 = xyd.tables.challenge:nextChallenge(var_8_0)

		local var_8_2 = xyd.tables.timeTravel:trialModelNo(var_8_0)

		table.insert(arg_8_0.nextMonster, {
			scale = 0.6,
			monsterid = var_8_0,
			iconPath = var_8_2
		})
	end

	local var_8_3 = os.date("*t", xyd.ServerTime.get():getServerTime() - 18000)
	local var_8_4 = os.date("*t", xyd.ServerTime.get():getServerTime())
	local var_8_5 = 0
	local var_8_6 = var_8_3.wday - 1

	if var_8_6 == 0 then
		var_8_6 = 7
	end

	local var_8_7 = {}

	for iter_8_0 = 11, 13 do
		local var_8_8 = xyd.tables.trialConfig:openDates(iter_8_0)
		local var_8_9 = {}

		for iter_8_1, iter_8_2 in ipairs(var_8_8) do
			var_8_9[iter_8_2] = true
		end

		local var_8_10 = 0

		for iter_8_3 = var_8_6, var_8_6 + 7 do
			local var_8_11 = iter_8_3

			if iter_8_3 > 7 then
				var_8_11 = var_8_11 - 7
			end

			if var_8_9[var_8_11] then
				break
			else
				var_8_10 = var_8_10 + 1
			end
		end

		if var_8_4.hour < 5 then
			var_8_10 = var_8_10 - 1
		end

		if not arg_8_0.openIds[iter_8_0] then
			table.insert(var_8_7, {
				scale = 0.8,
				trialName = xyd.tables.trialConfig:name(iter_8_0),
				iconPath = xyd.tables.timeTravel:trialModelNo(iter_8_0),
				addDay = var_8_10,
				idx = iter_8_0
			})
		end
	end

	table.sort(var_8_7, function(arg_9_0, arg_9_1)
		return arg_9_0.addDay < arg_9_1.addDay
	end)

	for iter_8_4, iter_8_5 in pairs(var_8_7) do
		table.insert(arg_8_0.nextMonster, iter_8_5)
	end
end

function var_0_0.loadChallenge(arg_10_0, arg_10_1, arg_10_2)
	xyd.Backend.get():request(arg_10_1, {}, function(arg_11_0, arg_11_1)
		if arg_10_2 then
			arg_10_2(arg_11_0, arg_11_1)
		end
	end)
end

function var_0_0.updateHeroModel(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_1:getHeroModel()

	var_12_0:setTouchSwallowEnabled(false)

	local var_12_1 = arg_12_2:getContentSize().width / 2

	var_12_0:setPosition(cc.p(var_12_1, 0))
	arg_12_2:removeAllChildren()
	var_12_0:addTo(arg_12_2)
end

function var_0_0.didOpen(arg_13_0, arg_13_1)
	arg_13_0:addBlockLayer(nil, true)
end

function var_0_0.tipsFormat(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	arg_14_3.id = arg_14_2
	arg_14_3.lev = xyd.tables.item:level(arg_14_2)

	if xyd.tables.item:type(arg_14_2) == -1 then
		arg_14_3.tipsType = 0
		arg_14_3.desc1 = xyd.tables.hero:getDes(arg_14_2)
	elseif specialItem then
		arg_14_3.tipsType = 1
		arg_14_3.id = -3
	else
		arg_14_3.tipsType = 1
		arg_14_3.desc1 = xyd.tables.item:desc1(arg_14_2)
		arg_14_3.desc2 = xyd.tables.item:desc2(arg_14_2)
	end

	arg_14_3.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(arg_14_2)
	arg_14_3.name = xyd.tables.item:name(arg_14_2)
end

return var_0_0
