local var_0_0 = class("StarTreasureRecordWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 45
local var_0_3 = 80
local var_0_4 = 32
local var_0_5 = 360

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.starTreasure = xyd.ModelManager.get():loadModel(xyd.ModelType.STAR_TREASURE)
	arg_1_0.selfRecord = arg_1_0.starTreasure:getSelfRecord()
	arg_1_0.worldRecord = arg_1_0.starTreasure:getWorldRecord()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0 = arg_2_0:nodeByName("list1")
	local var_2_1 = var_2_0:getContentSize().width
	local var_2_2 = var_2_0:getContentSize().height

	arg_2_0.listLeft = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_1, var_2_2),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_0):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	local var_2_3 = arg_2_0:nodeByName("list2")
	local var_2_4 = var_2_3:getContentSize().width
	local var_2_5 = var_2_3:getContentSize().height

	arg_2_0.listRight = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_4, var_2_5),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_3):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.listLeft:setDelegate(handler(arg_2_0, arg_2_0.delegateLeft))
	arg_2_0.listRight:setDelegate(handler(arg_2_0, arg_2_0.delegateRight))
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:layout()
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.listLeft:reload()
	arg_4_0.listRight:reload()
end

function var_0_0.delegateLeft(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #arg_5_0.selfRecord
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0
		local var_5_1
		local var_5_2 = arg_5_0.listLeft:dequeueItem()

		if not var_5_2 then
			var_5_2 = arg_5_0.listLeft:newItem()
		else
			var_5_2:removeAllChildren()
		end

		local var_5_3 = display.newNode()

		var_5_3:setTouchSwallowEnabled(false)

		local var_5_4 = arg_5_0.selfRecord[arg_5_3]
		local var_5_5 = var_5_4.floor
		local var_5_6 = var_5_4.awards

		var_5_3:setContentSize(var_0_5, #var_5_6 * var_0_4 + var_0_2)

		local var_5_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/star_treasure/star_treasure_record/self_record_title.csb")
		local var_5_8 = var_5_7:getChildByName("container")

		var_5_8:getChildByName("title"):setString(string.format(var_0_1:translation("STAR_TREASURE_SELF_RECORD_TITLE"), var_5_5))
		var_5_8:getChildByName("title"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
		var_5_7:addTo(var_5_3)
		var_5_7:setAnchorPoint(cc.p(0, 0))
		var_5_7:setPosition(0, #var_5_6 * var_0_4)

		local var_5_9 = 0

		for iter_5_0 = #var_5_6, 1, -1 do
			local var_5_10 = var_5_6[iter_5_0]
			local var_5_11 = xyd.AssetLoader.get():loadNodeFromJson("windows/star_treasure/star_treasure_record/record_cell.csb")
			local var_5_12 = var_5_11:getChildByName("container")

			if type(var_5_10.table_id) == "string" then
				if var_5_10.table_id == "mana" then
					var_5_12:getChildByName("txt"):setString(var_0_1:translation("STAR_TREASURE_TIP2") .. var_0_1:translation("COIN") .. " * " .. item_num)
				end
			else
				local var_5_13 = xyd.tables.item:name(var_5_10.table_id)
				local var_5_14 = var_5_10.item_num

				if var_5_14 then
					var_5_12:getChildByName("txt"):setString(var_0_1:translation("STAR_TREASURE_TIP2") .. var_5_13 .. " * " .. var_5_14)
				else
					var_5_12:getChildByName("txt"):setString(var_0_1:translation("STAR_TREASURE_TIP2") .. var_5_13)
				end
			end

			var_5_11:addTo(var_5_3)
			var_5_11:setAnchorPoint(cc.p(0, 0))
			var_5_11:setPosition(0, var_5_9 * var_0_4)

			var_5_9 = var_5_9 + 1
		end

		var_5_3:setAnchorPoint(cc.p(0, 0))
		var_5_3:setPosition(0, 0)
		var_5_2:addContent(var_5_3)
		var_5_2:setItemSize(var_0_5, #var_5_6 * var_0_4 + var_0_2)

		return var_5_2
	end
end

function var_0_0.delegateRight(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return #arg_6_0.worldRecord
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0
		local var_6_1
		local var_6_2 = arg_6_0.listLeft:dequeueItem()

		if not var_6_2 then
			var_6_2 = arg_6_0.listLeft:newItem()
		else
			var_6_2:removeAllChildren()
		end

		local var_6_3 = display.newNode()

		var_6_3:setTouchSwallowEnabled(false)

		local var_6_4 = arg_6_0.worldRecord[#arg_6_0.worldRecord - arg_6_3 + 1]
		local var_6_5 = var_6_4.floor
		local var_6_6 = var_6_4.awards
		local var_6_7 = var_6_4.player_info

		var_6_3:setContentSize(var_0_5, (#var_6_6 + 1) * var_0_4 + var_0_3)

		local var_6_8 = xyd.AssetLoader.get():loadNodeFromJson("windows/star_treasure/star_treasure_record/world_record_title.csb")
		local var_6_9 = var_6_8:getChildByName("container")

		var_6_9:getChildByName("name"):setString(var_6_7.player_name)
		var_6_9:getChildByName("name"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
		var_6_9:getChildByName("region"):setString("S" .. var_6_7.region)
		var_6_9:getChildByName("region"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

		local var_6_10 = {
			avatar_id = var_6_7.avatar_id,
			avatar_frame_id = var_6_7.avatar_frame_id
		}

		xyd.setPlayerAvatar(var_6_9:getChildByName("avatar"), var_6_10)
		var_6_8:addTo(var_6_3)
		var_6_8:setAnchorPoint(cc.p(0, 0))
		var_6_8:setPosition(0, (#var_6_6 + 1) * var_0_4)

		local var_6_11 = xyd.AssetLoader.get():loadNodeFromJson("windows/star_treasure/star_treasure_record/record_cell.csb")
		local var_6_12 = var_6_11:getChildByName("container")

		var_6_12:getChildByName("txt"):setString(string.format(var_0_1:translation("STAR_TREASURE_TIP3"), var_6_5))
		var_6_12:getChildByName("txt"):setPositionX(50)
		var_6_11:addTo(var_6_3)
		var_6_11:setAnchorPoint(cc.p(0, 0))
		var_6_11:setPosition(0, #var_6_6 * var_0_4)

		local var_6_13 = 0

		for iter_6_0 = #var_6_6, 1, -1 do
			local var_6_14 = var_6_6[iter_6_0]
			local var_6_15 = xyd.AssetLoader.get():loadNodeFromJson("windows/star_treasure/star_treasure_record/record_cell.csb")
			local var_6_16 = var_6_15:getChildByName("container")

			if type(var_6_14.table_id) == "string" then
				if var_6_14.table_id == "mana" then
					var_6_16:getChildByName("txt"):setString(var_0_1:translation("COIN") .. " * " .. item_num)
				end
			else
				local var_6_17 = xyd.tables.item:name(var_6_14.table_id)
				local var_6_18 = var_6_14.item_num

				if var_6_18 then
					var_6_16:getChildByName("txt"):setString(var_6_17 .. " * " .. var_6_18)
				else
					var_6_16:getChildByName("txt"):setString(var_6_17)
				end
			end

			var_6_16:getChildByName("txt"):setPositionX(50)
			var_6_15:addTo(var_6_3)
			var_6_15:setAnchorPoint(cc.p(0, 0))
			var_6_15:setPosition(0, var_6_13 * var_0_4)

			var_6_13 = var_6_13 + 1
		end

		var_6_3:setAnchorPoint(cc.p(0, 0))
		var_6_3:setPosition(0, 0)
		var_6_2:addContent(var_6_3)
		var_6_2:setItemSize(var_0_5, (#var_6_6 + 1) * var_0_4 + var_0_3)

		return var_6_2
	end
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" and 20 <= math.abs(arg_7_1.y - arg_7_0.prevY_) then
		arg_7_0.scrollViewMoved_ = true
	end
end

function var_0_0.willClose(arg_8_0)
	return
end

return var_0_0
