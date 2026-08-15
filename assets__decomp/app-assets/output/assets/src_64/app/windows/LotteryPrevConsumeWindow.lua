local var_0_0 = class("LotteryPrevConsumeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.activityLotteryConsume
local var_0_2 = xyd.tables.translation
local var_0_3 = 3
local var_0_4 = var_0_1:getDays()

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.prevList = arg_1_2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("list")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_0):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.list:reload()
end

function var_0_0.delegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #arg_4_0.prevList
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0 = arg_4_0.list:dequeueItem()

		if not var_4_0 then
			var_4_0 = arg_4_0.list:newItem()
		else
			var_4_0:removeAllChildren(true)
		end

		local var_4_1 = display.newNode()

		arg_4_0:initCell(var_4_1, arg_4_3)

		local var_4_2 = var_4_1:getWidth()
		local var_4_3 = var_4_1:getHeight()

		var_4_0:setItemSize(var_4_2, var_4_3 + var_0_3)
		var_4_0:addContent(var_4_1)

		return var_4_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_4_2 then
		-- block empty
	end
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.scrollViewMoved_ = false
		arg_5_0.prevY_ = arg_5_1.y
	elseif arg_5_1.name == "moved" and 1 <= math.abs(arg_5_1.y - arg_5_0.prevY_) then
		arg_5_0.scrollViewMoved_ = true
	end
end

function var_0_0.initCell(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1148/lottery_prev_item.csb")
	local var_6_1 = var_6_0:getChildByName("container")
	local var_6_2 = var_6_1:getContentSize()

	arg_6_1:setContentSize(var_6_2.width, var_6_2.height)
	arg_6_1:addChild(var_6_0)

	local var_6_3 = #arg_6_0.prevList - arg_6_2 + 1
	local var_6_4 = var_6_3 % var_0_4

	if var_6_4 == 0 then
		var_6_4 = var_0_4
	end

	var_6_1:getChildByName("text_lucky_number"):setString(var_0_2:translation("ACTIVITY_LOTTERY_TIP8"))

	local var_6_5 = string.format(var_0_2:translation("LETOU_NUMBER"), var_6_3)

	var_6_1:getChildByName("title_txt"):setString(var_6_5)
	var_6_1:getChildByName("title_txt"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_6_1:getChildByName("prev_word2"):setString(var_0_2:translation("BOUNUS"))
	var_6_1:getChildByName("prev_word2"):enableOutline(cc.c4b(206, 115, 24, 255), 2)
	var_6_1:getChildByName("prev_word1"):setString(var_0_2:translation("BOUNUS_PLAYER"))
	var_6_1:getChildByName("prev_word1"):enableOutline(cc.c4b(206, 115, 24, 255), 2)
	var_6_1:getChildByName("prev_word3"):setString(var_0_2:translation("LUCK_NUMBER"))
	var_6_1:getChildByName("prev_word3"):enableOutline(cc.c4b(206, 115, 24, 255), 2)
	var_6_1:getChildByName("lucky_number"):setString(arg_6_0.prevList[var_6_3].major_num)

	local var_6_6 = ""

	for iter_6_0, iter_6_1 in pairs(arg_6_0.prevList[var_6_3].lucky_nums) do
		var_6_6 = var_6_6 .. iter_6_1 .. "   "

		if iter_6_0 % 5 == 0 and arg_6_0.prevList[var_6_3].lucky_nums[iter_6_0 + 1] then
			var_6_6 = var_6_6 .. "\n"
		end
	end

	local var_6_7 = (math.ceil(#arg_6_0.prevList[var_6_3].lucky_nums / 5) - 2) * 32

	var_6_1:getChildByName("award_di_0"):setContentSize(var_6_1:getChildByName("award_di_0"):getWidth(), 95 + var_6_7 - 23)
	var_6_1:getChildByName("item_bg3"):setContentSize(var_6_1:getChildByName("item_bg3"):getWidth(), 95 + var_6_7)
	var_6_1:setContentSize(var_6_1:getWidth(), 412 + var_6_7)

	for iter_6_2, iter_6_3 in pairs(var_6_1:getChildren()) do
		iter_6_3:setPositionY(iter_6_3:getPositionY() + var_6_7)
	end

	var_6_1:getChildByName("prev_word3"):setPositionY(var_6_1:getChildByName("prev_word3"):getPositionY() - var_6_7 / 2 + 16)
	arg_6_1:setContentSize(var_6_2.width, var_6_2.height + var_6_7)
	var_6_1:getChildByName("prev_lucky_number"):setString(var_6_6)
	arg_6_0:rewardLayer(var_6_1:getChildByName("item"), var_6_4)

	if xyd.tables.gift:itemNum(var_0_1:giftID(var_6_4))[1] ~= 0 then
		var_6_1:getChildByName("item_name"):setString(xyd.tables.item:name(xyd.tables.gift:items(var_0_1:giftID(var_6_4))[1]) .. "   X " .. xyd.tables.gift:itemNum(var_0_1:giftID(var_6_4))[1])
	elseif xyd.tables.gift:crystal(var_0_1:giftID(var_6_4)) ~= 0 then
		var_6_1:getChildByName("item_name"):setString(xyd.tables.translation:translation("CRYSTAL") .. "   X " .. xyd.tables.gift:crystal(var_0_1:giftID(var_6_4)))
	end

	if arg_6_0.prevList[var_6_3].major_award_info then
		var_6_1:getChildByName("player_name"):setString(arg_6_0.prevList[var_6_3].major_award_info.player_name)
		var_6_1:getChildByName("player_region"):setString("S" .. xyd.getPlayerRegion(arg_6_0.prevList[var_6_3].major_award_info.player_id))

		local var_6_8 = arg_6_0.prevList[var_6_3].major_award_info

		var_6_8.playerInfo = {
			player_id = arg_6_0.prevList[var_6_3].major_award_info.player_id
		}

		xyd.setPlayerAvatar(var_6_1:getChildByName("avatar"), var_6_8)
	else
		var_6_1:getChildByName("player_name"):setVisible(false)
	end
end

function var_0_0.rewardLayer(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1:getContentSize().height
	local var_7_1 = var_7_0 / 4
	local var_7_2 = var_0_1:giftID(arg_7_2)
	local var_7_3 = xyd.tables.gift:items(var_7_2)

	if #var_7_3 == 1 and var_7_3[1] == 0 then
		var_7_3 = {}
	end

	local var_7_4 = xyd.tables.gift:itemNum(var_7_2)
	local var_7_5 = #var_7_3

	for iter_7_0 = 1, #var_7_3 do
		if xyd.tables.item:type(var_7_3[iter_7_0]) ~= -1 then
			local var_7_6 = display.newNode()

			var_7_6:setContentSize(var_7_0, var_7_0)

			local var_7_7 = xyd.tables.item:type(var_7_3[iter_7_0])

			xyd.setItemBorder(var_7_6, var_7_3[iter_7_0], false, false, var_7_4[iter_7_0])
			var_7_6:addTo(arg_7_1)
			var_7_6:setAnchorPoint(cc.p(0, 0))
			var_7_6:setPosition((iter_7_0 - 1) * (var_7_0 + var_7_1), 0)

			local var_7_8 = {
				id = var_7_3[iter_7_0],
				lev = xyd.tables.item:level(var_7_3[iter_7_0])
			}

			if xyd.tables.item:type(var_7_3[iter_7_0]) == -1 then
				var_7_8.tipsType = 0
				var_7_8.desc1 = xyd.tables.hero:getDes(var_7_3[iter_7_0])
			elseif specialItem then
				var_7_8.tipsType = 1
				var_7_8.id = -3
			else
				var_7_8.tipsType = 1
				var_7_8.desc1 = xyd.tables.item:desc1(var_7_3[iter_7_0])
				var_7_8.desc2 = xyd.tables.item:desc2(var_7_3[iter_7_0])
			end

			var_7_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_7_3[iter_7_0])
			var_7_8.name = xyd.tables.item:name(var_7_3[iter_7_0])

			arg_7_0:addTips(var_7_6, var_7_8)
		end
	end

	local var_7_9 = xyd.tables.gift:crystal(var_7_2)

	if var_7_9 and var_7_9 > 0 then
		local var_7_10 = display.newNode()

		var_7_10:setContentSize(var_7_0, var_7_0)
		xyd.setItemBorder(var_7_10, -1, false, false, var_7_9)
		var_7_10:addTo(arg_7_1)
		var_7_10:setAnchorPoint(cc.p(0, 0))
		var_7_10:setPosition(var_7_5 * (var_7_0 + var_7_1), 0)

		local var_7_11 = {}

		var_7_11.id = -1
		var_7_11.tipsType = 1

		arg_7_0:addTips(var_7_10, var_7_11)

		var_7_5 = var_7_5 + 1
	end

	local var_7_12 = xyd.tables.gift:mana(var_7_2)

	if var_7_12 and var_7_12 > 0 then
		local var_7_13 = display.newNode()

		var_7_13:setContentSize(var_7_0, var_7_0)
		xyd.setItemBorder(var_7_13, -2, false, false, var_7_12)
		var_7_13:addTo(arg_7_1)
		var_7_13:setAnchorPoint(cc.p(0, 0))
		var_7_13:setPosition(var_7_5 * (var_7_0 + var_7_1), 0)

		local var_7_14 = {}

		var_7_14.id = -2
		var_7_14.tipsType = 1

		arg_7_0:addTips(var_7_13, var_7_14)

		local var_7_15 = var_7_5 + 1
	end

	return arg_7_1
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	arg_8_0:addBlockLayer()
end

return var_0_0
