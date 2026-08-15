local var_0_0 = class("ZhugeRecordsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_1_0.personData = arg_1_2.item_logs
	arg_1_0.worldData = arg_1_2.rank_list
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0.personList_:reload()
	arg_3_0.worldList_:reload()
end

function var_0_0.initData(arg_4_0)
	for iter_4_0 = 1, MAP_COL do
		arg_4_0.mapInfos[iter_4_0] = {}

		for iter_4_1 = 1, MAP_ROW do
			arg_4_0.mapInfos[iter_4_0][iter_4_1] = 0
		end
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:initListView()
end

function var_0_0.initListView(arg_6_0)
	local var_6_0 = arg_6_0:nodeByName("person_list")
	local var_6_1 = var_6_0:getContentSize().width
	local var_6_2 = var_6_0:getContentSize().height

	arg_6_0.personList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_6_1, var_6_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_6_0)

	arg_6_0.personList_:setDelegate(handler(arg_6_0, arg_6_0.personDelegate))

	local var_6_3 = arg_6_0:nodeByName("world_list")
	local var_6_4 = var_6_3:getContentSize().width
	local var_6_5 = var_6_3:getContentSize().height

	arg_6_0.worldList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_6_4, var_6_5),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_6_3)

	arg_6_0.worldList_:setDelegate(handler(arg_6_0, arg_6_0.worldDelegate))
end

function var_0_0.personDelegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = #arg_7_0.personData

	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return var_7_0
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_1
		local var_7_2
		local var_7_3
		local var_7_4 = arg_7_0.personList_:dequeueItem()

		if not var_7_4 then
			var_7_4 = arg_7_0.personList_:newItem()
		else
			var_7_4:removeAllChildren()
		end

		local var_7_5 = display.newNode()

		var_7_5:setTouchSwallowEnabled(false)

		local var_7_6 = display.newNode()

		arg_7_0:initPersonCell(var_7_6, arg_7_3)
		var_7_5:addChild(var_7_6)
		var_7_5:setContentSize(cc.size(arg_7_0.personList_.viewRect_.width, var_7_6:getContentSize().height))
		var_7_4:setItemSize(arg_7_0.personList_.viewRect_.width, var_7_6:getContentSize().height)
		var_7_4:addContent(var_7_5)

		return var_7_4
	end
end

function var_0_0.initPersonCell(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = arg_8_0.personData[arg_8_2]
	local var_8_1 = var_8_0.item_id
	local var_8_2 = var_8_0.item_num
	local var_8_3 = var_8_0.time
	local var_8_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/records/person_item.csb")
	local var_8_5 = var_8_4:getChildByName("container")
	local var_8_6 = string.format(var_0_1:translation("ZHUGE_ADVENTURE_TIPS_31"), os.date("%X", var_8_3))

	var_8_5:getChildByName("text_title"):setString(var_8_6)

	local var_8_7 = xyd.tables.item:name(var_8_1)

	var_8_5:getChildByName("text_item_desc"):setString(var_8_7 .. " x" .. var_8_2)
	xyd.setItemBorder(var_8_5:getChildByName("item"), var_8_1)

	local var_8_8 = var_8_5:getContentSize()

	arg_8_1:setContentSize(var_8_8)
	var_8_4:addTo(arg_8_1)
end

function var_0_0.worldDelegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = #arg_9_0.worldData

	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return var_9_0
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_1
		local var_9_2
		local var_9_3
		local var_9_4 = arg_9_0.worldList_:dequeueItem()

		if not var_9_4 then
			var_9_4 = arg_9_0.worldList_:newItem()
		else
			var_9_4:removeAllChildren()
		end

		local var_9_5 = display.newNode()

		var_9_5:setTouchSwallowEnabled(false)

		local var_9_6 = display.newNode()

		arg_9_0:initWorldCell(var_9_6, arg_9_3)
		var_9_5:addChild(var_9_6)
		var_9_5:setContentSize(cc.size(arg_9_0.worldList_.viewRect_.width, var_9_6:getContentSize().height + 10))
		var_9_4:setItemSize(arg_9_0.worldList_.viewRect_.width, var_9_6:getContentSize().height + 10)
		var_9_4:addContent(var_9_5)

		return var_9_4
	end
end

function var_0_0.initWorldCell(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = arg_10_0.worldData[arg_10_2]
	local var_10_1 = var_10_0.player_info

	var_10_1.playerInfo = var_10_1

	local var_10_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/records/world_item.csb")
	local var_10_3 = var_10_2:getChildByName("container")

	var_10_3:getChildByName("text_name"):setString(var_10_1.player_name)
	var_10_3:getChildByName("text_region"):setString("S" .. xyd.getPlayerRegion(var_10_1.player_id))
	var_10_3:getChildByName("text_tips"):setString(string.format(var_0_1:translation("ZHUGE_ADVENTURE_TIPS_32"), var_10_0.cost))
	xyd.setPlayerAvatar(var_10_3:getChildByName("avatar"), var_10_1)

	local var_10_4 = var_10_3:getContentSize()

	arg_10_1:setContentSize(var_10_4)
	var_10_2:addTo(arg_10_1)
	var_10_2:setPositionX(30)
end

return var_0_0
