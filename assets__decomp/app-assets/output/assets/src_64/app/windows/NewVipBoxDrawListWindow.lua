local var_0_0 = class("NewVipBoxDrawListWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.hero
local var_0_3 = 5
local var_0_4 = 100

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.rareIds = arg_1_2.rareIds or {}
	arg_1_0.normalIds = arg_1_2.normalIds or {}
	arg_1_0.index = arg_1_2.index
	arg_1_0.hasRare = #arg_1_0.rareIds > 0

	if arg_1_0.hasRare then
		arg_1_0.title1, arg_1_0.title2 = 1, 2 + math.ceil(#arg_1_0.rareIds / var_0_3)
	else
		arg_1_0.title1, arg_1_0.title2 = 0, 1
	end

	arg_1_0.title0 = "ACTIVITY_1206_TEXT_" .. arg_1_0.index + 4
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("title_txt"):setString(var_0_1:translation(arg_2_0.title0))

	local var_2_0 = arg_2_0:nodeByName("listview")
	local var_2_1 = var_2_0:getContentSize()

	arg_2_0.width = var_2_1.width
	arg_2_0.listView_ = cc.ui.UIListView.new({
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_2_0.width, var_2_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_0):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.listView_:setDelegate(handler(arg_2_0, arg_2_0.sourceDelegate))
	arg_2_0.listView_:setBounceable(true)
	arg_2_0.listView_:reload()
end

function var_0_0.scrollListener(arg_3_0, arg_3_1)
	if arg_3_1.name == "began" then
		arg_3_0.scrollViewMoved_ = false
		arg_3_0.prevY_ = arg_3_1.y
	elseif arg_3_1.name == "moved" and 10 <= math.abs(arg_3_1.y - arg_3_0.prevY_) then
		arg_3_0.scrollViewMoved_ = true
	end
end

function var_0_0.sourceDelegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if arg_4_2 == cc.ui.UIListView.COUNT_TAG then
		return arg_4_0.title2 + math.ceil(#arg_4_0.normalIds / var_0_3)
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0
		local var_4_1 = arg_4_0.listView_:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.listView_:newItem()
		else
			var_4_1:removeAllChildren(true)
		end

		if arg_4_3 == arg_4_0.title1 or arg_4_3 == arg_4_0.title2 then
			local var_4_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1206/vip_box_draw_list_title.csb")
			local var_4_3

			if arg_4_3 == arg_4_0.title1 then
				var_4_3 = var_0_1:translation("ACTIVITY_VIP_BOX_DRAW2_RARE")
			else
				var_4_3 = var_0_1:translation("ACTIVITY_VIP_BOX_DRAW2_NORMAL")
			end

			var_4_2:getChildByName("title_txt"):setString(var_4_3)
			var_4_1:setItemSize(arg_4_0.width, 40)
			var_4_1:addContent(var_4_2)
		elseif arg_4_3 < arg_4_0.title2 then
			arg_4_3 = arg_4_3 - arg_4_0.title1 - 1

			local var_4_4 = cc.Node:create()

			for iter_4_0 = 1, var_0_3 do
				local var_4_5 = arg_4_3 * var_0_3 + iter_4_0

				if var_4_5 > #arg_4_0.rareIds then
					break
				end

				local var_4_6 = cc.Node:create()

				var_4_6:setAnchorPoint(cc.p(0.5, 0.5))
				var_4_6:setContentSize(var_0_4, var_0_4)
				var_4_6:setPosition((iter_4_0 - (var_0_3 + 1) / 2) * (var_0_4 + 30), 0)
				var_4_4:addChild(var_4_6)
				arg_4_0:setBorder(arg_4_0.rareIds[var_4_5], var_4_6)
			end

			var_4_1:setItemSize(arg_4_0.width, var_0_4 + 30)
			var_4_1:addContent(var_4_4)
		elseif arg_4_3 > arg_4_0.title2 then
			arg_4_3 = arg_4_3 - arg_4_0.title2 - 1

			local var_4_7 = cc.Node:create()

			for iter_4_1 = 1, var_0_3 do
				local var_4_8 = arg_4_3 * var_0_3 + iter_4_1

				if var_4_8 > #arg_4_0.normalIds then
					break
				end

				local var_4_9 = cc.Node:create()

				var_4_9:setAnchorPoint(cc.p(0.5, 0.5))
				var_4_9:setContentSize(var_0_4, var_0_4)
				var_4_9:setPosition((iter_4_1 - (var_0_3 + 1) / 2) * (var_0_4 + 30), 0)
				var_4_7:addChild(var_4_9)
				arg_4_0:setBorder(arg_4_0.normalIds[var_4_8], var_4_9)
			end

			var_4_1:setItemSize(arg_4_0.width, var_0_4 + 30)
			var_4_1:addContent(var_4_7)
		end

		return var_4_1
	end
end

function var_0_0.setBorder(arg_5_0, arg_5_1, arg_5_2)
	xyd.setAvatarBorderNewUI(arg_5_1, arg_5_2, 1, var_0_2:initialStar(arg_5_1))
	arg_5_2:setTouchEnabled(true)
	arg_5_2:setTouchSwallowEnabled(false)
	arg_5_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			touchBeganY = arg_6_0.y

			if not xyd.WindowManager.get():getWindow("new_item_tips") then
				local var_6_0 = xyd.WindowManager.get():openWindow("new_item_tips", {
					isHero = true,
					id = arg_5_1,
					desc = var_0_2:getDes(arg_5_1),
					name = var_0_2:name(arg_5_1)
				})

				xyd.adaptToWorldPosition(arg_5_2, var_6_0)
			end

			return true
		elseif arg_6_0.name == "moved" then
			local var_6_1 = arg_6_0.y

			if math.abs(var_6_1 - touchBeganY) > 30 then
				xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		elseif arg_6_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("new_item_tips")
		end
	end)
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	arg_7_0:addBlockLayer()
end

return var_0_0
