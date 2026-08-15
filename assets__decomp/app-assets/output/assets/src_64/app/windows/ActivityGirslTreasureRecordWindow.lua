local var_0_0 = class("ActivityGirslTreasureRecordWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.records = arg_1_2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("text_title"):setString(var_0_1:translation("ACTIVITY_GIRLS_TREASURE_TEXT_1"))
	arg_3_0:nodeByName("text_desc"):setString(var_0_1:translation("ACTIVITY_GIRLS_TREASURE_TEXT_11"))

	local var_3_0 = import("app.common.ui.SplitLine")
	local var_3_1 = arg_3_0:nodeByName("line")

	var_3_0.new({
		color = "#F5D283",
		size = var_3_1:getWidth()
	}):addTo(var_3_1)

	local var_3_2 = arg_3_0:nodeByName("list")

	arg_3_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_2:getWidth(), var_3_2:getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_2)

	arg_3_0.list:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.list:reload()
end

function var_0_0.delegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #arg_4_0.records
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0
		local var_4_1 = arg_4_1:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_1:newItem()
		else
			var_4_1:removeAllChildren(false)
		end

		local var_4_2 = arg_4_0.records[arg_4_3]
		local var_4_3 = arg_4_0:initCell(var_4_2, arg_4_3)
		local var_4_4 = var_4_3:getWidth()
		local var_4_5 = var_4_3:getHeight()

		var_4_1:setItemSize(var_4_4, var_4_5 + 7)
		var_4_1:addContent(var_4_3)

		return var_4_1
	end
end

function var_0_0.initCell(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1220/item_record.csb")
	local var_5_1 = var_5_0:getChildByName("container")
	local var_5_2 = arg_5_1.award

	var_5_1:getChildByName("bg_hero"):setVisible(var_5_2.is_partner)
	var_5_1:getChildByName("bg_item"):setVisible(not var_5_2.is_partner)

	if not var_5_2.is_partner then
		if not var_5_2.to_stone then
			var_5_1:getChildByName("name"):setColor(cc.c3b(150, 83, 54))
			var_5_1:getChildByName("num"):setColor(cc.c3b(150, 83, 54))
			var_5_1:getChildByName("time_1"):setColor(cc.c3b(150, 83, 54))
			var_5_1:getChildByName("time_2"):setColor(cc.c3b(150, 83, 54))
		end

		var_5_1:getChildByName("num"):setString("x" .. var_5_2.item_num)
		xyd.setItemBorder(var_5_1:getChildByName("icon"), var_5_2.table_id)
	else
		var_5_1:getChildByName("num"):setString("x1")

		local var_5_3 = var_0_2.new()

		var_5_3:initUnCollected(var_5_2.table_id)
		xyd.setAvatarBorderNewUI(var_5_3, var_5_1:getChildByName("icon"))
	end

	var_5_1:getChildByName("name"):setString(xyd.tables.item:name(var_5_2.table_id))

	local var_5_4 = os.date("%Y", arg_5_1.time)
	local var_5_5 = os.date("%m", arg_5_1.time)
	local var_5_6 = os.date("%d", arg_5_1.time)
	local var_5_7 = var_5_4 .. "." .. var_5_5 .. "." .. var_5_6

	var_5_1:getChildByName("time_1"):setString(var_5_7)
	var_5_1:getChildByName("time_2"):setString(xyd.timeFormatAsHMS(arg_5_1.time % xyd.OneDaySec))
	var_5_0:setContentSize(var_5_1:getContentSize())

	return var_5_0
end

function var_0_0.didOpen(arg_6_0)
	var_0_0.super.didOpen(arg_6_0)
	arg_6_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
