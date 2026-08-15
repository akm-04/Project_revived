local var_0_0 = class("SummerFishTaskWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.hero
local var_0_3 = xyd.tables.gift
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = xyd.tables.activitySummerTask

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.summer = xyd.ModelManager.get():loadModel(xyd.ModelType.SUMMER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initData()
	arg_2_0:layout()
end

function var_0_0.initData(arg_3_0)
	arg_3_0.missions = {}

	local var_3_0 = arg_3_0.summer.details.goldfish_info.task_list
	local var_3_1 = {}

	for iter_3_0, iter_3_1 in ipairs(var_3_0) do
		var_3_1[iter_3_1.task_id] = iter_3_1.is_award
	end

	for iter_3_2, iter_3_3 in ipairs(var_3_0) do
		if iter_3_3.is_award == 0 then
			local var_3_2 = iter_3_3.task_id
			local var_3_3 = var_0_5:preTaskID(var_3_2)

			if var_3_3 > 0 then
				if var_3_1[var_3_3] == 1 then
					table.insert(arg_3_0.missions, iter_3_3)
				end
			else
				table.insert(arg_3_0.missions, iter_3_3)
			end
		end
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("MISSION"))

	arg_4_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_4_0:nodeByName("list"):getWidth(), arg_4_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("list")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.list:setBounceable(true)
	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.delegate))
	arg_4_0.list:reload()
end

function var_0_0.delegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = arg_5_0.missions

	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #var_5_0
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		if arg_5_3 > #var_5_0 then
			return nil
		end

		local var_5_1 = arg_5_0.list:dequeueItem()

		if not var_5_1 then
			var_5_1 = arg_5_0.list:newItem()
		else
			var_5_1:removeAllChildren(true)
		end

		local var_5_2 = var_5_0[arg_5_3]
		local var_5_3 = display.newNode()

		arg_5_0:initCell(var_5_3, var_5_2)
		var_5_1:setItemSize(var_5_3:getContentSize().width, var_5_3:getContentSize().height)
		var_5_1:addContent(var_5_3)

		return var_5_1
	end
end

function var_0_0.initCell(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/summer/fish/fish_task_item.csb")
	local var_6_1 = var_6_0:getChildByName("container")

	var_6_1:getChildByName("desc"):setString(var_0_5:desc(arg_6_2.task_id))
	var_6_1:getChildByName("count"):setString("(" .. arg_6_2.count .. "/" .. var_0_5:taskNum(arg_6_2.task_id) .. ")")

	local var_6_2 = import("app.common.ui.SplitLine")
	local var_6_3 = var_6_1:getChildByName("line")

	var_6_2.new({
		size = var_6_3:getWidth()
	}):addTo(var_6_3)
	arg_6_0:rewardFormat(var_6_1:getChildByName("award_container"), var_0_5:gift(arg_6_2.task_id))

	local var_6_4 = var_6_1:getChildByName("btn")

	var_6_4:getChildByName("txt"):setString(var_0_1:translation("GET"))

	if arg_6_2.count >= var_0_5:taskNum(arg_6_2.task_id) then
		var_6_4:getChildByName("txt"):setColor(cc.c3b(123, 55, 0))
		var_6_4:addTouchEventListener(function(arg_7_0, arg_7_1)
			xyd.buttonScaleAnim(arg_7_0, arg_7_1)

			if arg_7_1 == ccui.TouchEventType.ended then
				arg_6_0.summer:getReward(arg_6_2.task_id, function(arg_8_0, arg_8_1)
					if arg_6_0 and not tolua.isnull(arg_6_0) then
						arg_6_0:initData()
						arg_6_0.list:reload()
					end
				end)
			end
		end)
	else
		var_6_4:getChildByName("txt"):setColor(cc.c3b(52, 54, 55))
		var_6_4:setTouchEnabled(false)
		var_6_4:setBright(false)
	end

	var_6_0:addTo(arg_6_1)
	arg_6_1:setContentSize(var_6_1:getWidth(), var_6_1:getHeight() + 12)
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	arg_9_0:addBlockLayer()
end

function var_0_0.scrollListener(arg_10_0, arg_10_1)
	if arg_10_1.name == "began" then
		arg_10_0.startClick_ = true
		arg_10_0.prevY_ = arg_10_1.y
	elseif arg_10_1.name == "moved" and 20 <= math.abs(arg_10_1.y - arg_10_0.prevY_) then
		arg_10_0.startClick_ = false
	end
end

function var_0_0.rewardFormat(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4)
	local var_11_0 = arg_11_1:getContentSize().height
	local var_11_1 = arg_11_4 or var_11_0 / 4
	local var_11_2 = xyd.tables.gift:items(arg_11_2)

	if #var_11_2 == 1 and var_11_2[1] == 0 then
		var_11_2 = {}
	end

	local var_11_3 = xyd.tables.gift:itemNum(arg_11_2)
	local var_11_4 = #var_11_2

	for iter_11_0 = 1, #var_11_2 do
		local var_11_5 = display.newNode()

		var_11_5:setContentSize(var_11_0, var_11_0)

		if xyd.tables.item:type(var_11_2[iter_11_0]) == -1 then
			xyd.setAvatarBorder(var_11_2[iter_11_0], var_11_5, 1, xyd.tables.hero:initialStar(var_11_2[iter_11_0]))
		else
			xyd.setItemBorder(var_11_5, var_11_2[iter_11_0], false, false, var_11_3[iter_11_0])
		end

		var_11_5:addTo(arg_11_1)
		var_11_5:setAnchorPoint(cc.p(0, 0))
		var_11_5:setPosition((iter_11_0 - 1) * (var_11_0 + var_11_1), 0)

		local var_11_6 = {
			id = var_11_2[iter_11_0],
			lev = xyd.tables.item:level(var_11_2[iter_11_0])
		}

		if xyd.tables.item:type(var_11_2[iter_11_0]) == -1 then
			var_11_6.tipsType = 0
			var_11_6.desc1 = xyd.tables.hero:getDes(var_11_2[iter_11_0])
		elseif specialItem then
			var_11_6.tipsType = 1
			var_11_6.id = -3
		else
			var_11_6.tipsType = 1
			var_11_6.desc1 = xyd.tables.item:desc1(var_11_2[iter_11_0])
			var_11_6.desc2 = xyd.tables.item:desc2(var_11_2[iter_11_0])
		end

		var_11_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_11_2[iter_11_0])
		var_11_6.name = xyd.tables.item:name(var_11_2[iter_11_0])

		arg_11_0:addTips(var_11_5, var_11_6)
	end

	local var_11_7 = xyd.tables.gift:skinFragment(arg_11_2)

	if var_11_7 and var_11_7 > 0 then
		local var_11_8 = display.newNode()

		var_11_8:setContentSize(var_11_0, var_11_0)
		xyd.setItemBorder(var_11_8, -101, false, false, var_11_7)
		var_11_8:addTo(arg_11_1)
		var_11_8:setAnchorPoint(cc.p(0, 0))
		var_11_8:setPosition(var_11_4 * (var_11_0 + var_11_1), 0)

		local var_11_9 = {}

		var_11_9.id = -101
		var_11_9.tipsType = 1

		arg_11_0:addTips(var_11_8, var_11_9)

		var_11_4 = var_11_4 + 1
	end

	local var_11_10 = xyd.tables.gift:crystal(arg_11_2)

	if var_11_10 and var_11_10 > 0 then
		local var_11_11 = display.newNode()

		var_11_11:setContentSize(var_11_0, var_11_0)
		xyd.setItemBorder(var_11_11, -1, false, false, var_11_10)
		var_11_11:addTo(arg_11_1)
		var_11_11:setAnchorPoint(cc.p(0, 0))
		var_11_11:setPosition(var_11_4 * (var_11_0 + var_11_1), 0)

		local var_11_12 = {}

		var_11_12.id = -1
		var_11_12.tipsType = 1

		arg_11_0:addTips(var_11_11, var_11_12)

		var_11_4 = var_11_4 + 1
	end

	local var_11_13 = xyd.tables.gift:mana(arg_11_2)

	if var_11_13 and var_11_13 > 0 then
		local var_11_14 = display.newNode()

		var_11_14:setContentSize(var_11_0, var_11_0)
		xyd.setItemBorder(var_11_14, -2, false, false, var_11_13)
		var_11_14:addTo(arg_11_1)
		var_11_14:setAnchorPoint(cc.p(0, 0))
		var_11_14:setPosition(var_11_4 * (var_11_0 + var_11_1), 0)

		local var_11_15 = {}

		var_11_15.id = -2
		var_11_15.tipsType = 1

		arg_11_0:addTips(var_11_14, var_11_15)

		local var_11_16 = var_11_4 + 1
	end
end

return var_0_0
