local var_0_0 = class("MayDropItemWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.chapterID = arg_1_2.chapter_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:nodeByName("desc"):setString(var_0_1:translation("MAY_GET"))

	arg_2_0.listInfo = xyd.tables.teamDungeonSelect:itemDisplay(arg_2_0.chapterID)

	local var_2_0 = arg_2_0:nodeByName("list")
	local var_2_1 = var_2_0:getContentSize()

	arg_2_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_0):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.list:setDelegate(handler(arg_2_0, arg_2_0.delegate))
	arg_2_0.list:reload()
	arg_2_0:layout()
end

function var_0_0.scrollListener(arg_3_0, arg_3_1)
	if arg_3_1.name == "began" then
		arg_3_0.scrollViewMoved_ = false
		arg_3_0.prevX_ = arg_3_1.x
		arg_3_0.prevY_ = arg_3_1.y
	elseif arg_3_1.name == "moved" then
		local var_3_0 = 3

		if var_3_0 <= math.abs(arg_3_1.y - arg_3_0.prevY_) or var_3_0 <= math.abs(arg_3_1.x - arg_3_0.prevX_) then
			arg_3_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.delegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return (math.ceil(#arg_4_0.listInfo / var_0_2))
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0 = arg_4_0.list:dequeueItem()

		if not var_4_0 then
			var_4_0 = arg_4_0.list:newItem()
		else
			var_4_0:removeAllChildren(true)
		end

		local var_4_1 = 415
		local var_4_2 = 80

		var_4_0:setItemSize(var_4_1, var_4_2)

		local var_4_3 = display.newNode()

		var_4_3:setContentSize(415, 70)
		arg_4_0:initCell(var_4_3, arg_4_3)
		var_4_0:addContent(var_4_3)

		return var_4_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_4_2 then
		-- block empty
	end
end

function var_0_0.initCell(arg_5_0, arg_5_1, arg_5_2)
	for iter_5_0 = 1, var_0_2 do
		local var_5_0 = (arg_5_2 - 1) * var_0_2 + iter_5_0

		if var_5_0 > #arg_5_0.listInfo then
			break
		end

		local var_5_1 = display.newNode()

		var_5_1:setContentSize(70, 70)
		var_5_1:setPosition(83 * (iter_5_0 - 1), 0)
		arg_5_1:addChild(var_5_1)
		var_5_1:setTouchEnabled(true)
		var_5_1:setTouchSwallowEnabled(false)
		xyd.setItemBorder(var_5_1, arg_5_0.listInfo[var_5_0])
	end
end

function var_0_0.layout(arg_6_0)
	local var_6_0 = xyd.tables.teamDungeonSelect:chapterName(arg_6_0.chapterID)
	local var_6_1 = string.format(var_0_1:translation("TEAM_CHAPTER"), arg_6_0.chapterID) .. " " .. var_6_0

	arg_6_0:nodeByName("chaper_name"):setString(var_6_1)
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	arg_7_0:addBlockLayer()
end

return var_0_0
