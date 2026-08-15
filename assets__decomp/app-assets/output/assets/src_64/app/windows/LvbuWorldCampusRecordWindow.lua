local var_0_0 = class("LvbuWorldCampusRecordWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.lvbuFestival = xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL)
	arg_1_0.records = arg_1_0.lvbuFestival.records
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = xyd.AssetLoader.get():loadSprite("windows/arena/record/title_text.png")

	var_4_0:addTo(arg_4_0:nodeByName("title"))
	var_4_0:setAnchorPoint(cc.p(0, 0))

	arg_4_0.container = arg_4_0:nodeByName("inner")

	local var_4_1 = arg_4_0.container:getContentSize()

	arg_4_0.recordList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_1.width, var_4_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.container):onScroll(handler(arg_4_0, arg_4_0.scrollListener)):setTouchType(true):pos(0, 0)

	arg_4_0.recordList_:setDelegate(handler(arg_4_0, arg_4_0.recordListDelegate))
	arg_4_0.recordList_:reload()
end

function var_0_0.recordListDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #arg_5_0.records
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0 = arg_5_0.recordList_:dequeueItem()

		if not var_5_0 then
			var_5_0 = arg_5_0.recordList_:newItem()
		else
			var_5_0:removeAllChildren(true)
		end

		local var_5_1 = arg_5_0:createBattleResultItem(arg_5_0.records[#arg_5_0.records - arg_5_3 + 1], arg_5_3)
		local var_5_2 = var_5_1:getWidth()
		local var_5_3 = var_5_1:getHeight()

		var_5_0:setItemSize(var_5_2, var_5_3)
		var_5_0:addContent(var_5_1)

		return var_5_0
	end
end

function var_0_0.createBattleResultItem(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = display.newNode()
	local var_6_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/lvbu/campus_record/result_item.csb")
	local var_6_2 = var_6_1:getChildByName("container")

	var_6_2:getChildByName("result_txt"):setString(xyd.tables.lvbuMatch:name(arg_6_1.wins))
	var_6_2:getChildByName("win_count_txt"):setString(string.format(var_0_1:translation("LVBU_BATTLE_COUNT"), arg_6_1.wins))
	var_6_2:getChildByName("lose_count_txt"):setString(string.format(var_0_1:translation("LVBU_BATTLE_COUNT"), #arg_6_1.list - arg_6_1.wins))
	var_6_2:getChildByName("win_text"):setString(var_0_1:translation("REGION_ARENA_TIP29"))
	var_6_2:getChildByName("lose_text"):setString(var_0_1:translation("REGION_ARENA_TIP30"))
	var_6_2:getChildByName("replay_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = {
				record = arg_6_1
			}

			xyd.WindowManager.get():openWindow("lvbu_world_campus_report", var_7_0)
		end
	end)
	var_6_1:addTo(var_6_0)
	var_6_0:setContentSize(var_6_2:getContentSize())

	return var_6_0
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.scrollViewMoved_ = false
		arg_8_0.prevX_ = arg_8_1.x
	elseif arg_8_1.name == "moved" and 1 <= math.abs(arg_8_1.x - arg_8_0.prevX_) then
		arg_8_0.scrollViewMoved_ = true
	end
end

return var_0_0
