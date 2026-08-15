local var_0_0 = class("SummonListShowTitle", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/summon/list_show_title.csb"))
		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.size(arg_4_0)
	return arg_4_0.contentView_:nodeByName("bg_title"):getContentSize()
end

function var_0_0.setParams(arg_5_0, arg_5_1)
	arg_5_0.contentView_:nodeByName("title_txt"):setString(arg_5_1)
end

local var_0_1 = class("SummonListShowWindow", import("app.common.ui.BaseWindow"))
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.hero
local var_0_4 = 100

function var_0_1.ctor(arg_6_0, arg_6_1, arg_6_2)
	var_0_1.super.ctor(arg_6_0, arg_6_1, arg_6_2)

	arg_6_0.newHeroId = arg_6_2.id or 10001023
	arg_6_0.herolist = {}

	local var_6_0 = xyd.tables.summonListShow:herolist(arg_6_2.type or 1)

	for iter_6_0, iter_6_1 in ipairs(var_6_0) do
		table.insert(arg_6_0.herolist, iter_6_1)
	end

	arg_6_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_1.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" and 20 <= math.abs(arg_7_1.y - arg_7_0.prevY_) then
		arg_7_0.scrollViewMoved_ = true
	end
end

function var_0_1.willOpen(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_0:nodeByName("listview")
	local var_8_1 = var_8_0:getContentSize()

	arg_8_0.width = var_8_1.width
	arg_8_0.listView_ = cc.ui.UIListView.new({
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_8_0.width, var_8_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_8_0):onScroll(handler(arg_8_0, arg_8_0.scrollListener))

	arg_8_0.listView_:setDelegate(handler(arg_8_0, arg_8_0.sourceDelegate))
	arg_8_0.listView_:setBounceable(true)
	arg_8_0.listView_:reload()
	arg_8_0:nodeByName("title"):setString(var_0_2:translation("MIDDLE_MACHINE_TIP1"))
end

function var_0_1.didOpen(arg_9_0, arg_9_1)
	var_0_1.super:didOpen(arg_9_1)
	arg_9_0:addBlockLayer()
end

function var_0_1.sourceDelegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return 3 + math.ceil(#arg_10_0.herolist / 6)
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_0
		local var_10_1 = arg_10_0.listView_:dequeueItem()

		if not var_10_1 then
			var_10_1 = arg_10_0.listView_:newItem()
		else
			var_10_1:removeAllChildren(true)
		end

		if arg_10_3 == 1 or arg_10_3 == 3 then
			local var_10_2 = var_0_0.new()

			if arg_10_3 == 1 then
				var_10_2:setParams(var_0_2:translation("SUMMON_LIST_NEW_ADD"))
			else
				var_10_2:setParams(var_0_2:translation("SUMMON_LIST_GET_HERO"))
			end

			var_10_1:setItemSize(arg_10_0.width, 50)
			var_10_1:addContent(var_10_2)
		elseif arg_10_3 == 2 then
			local var_10_3 = cc.Node:create()
			local var_10_4 = cc.Node:create()

			var_10_4:setAnchorPoint(cc.p(0.5, 0.5))
			var_10_4:setContentSize(var_0_4, var_0_4)
			var_10_3:addChild(var_10_4)
			arg_10_0:setBorder(arg_10_0.newHeroId, var_10_4)
			var_10_1:setItemSize(arg_10_0.width, var_0_4 + 20)
			var_10_1:addContent(var_10_3)
		else
			arg_10_3 = arg_10_3 - 4

			local var_10_5 = cc.Node:create()

			for iter_10_0 = 1, 6 do
				local var_10_6 = arg_10_3 * 6 + iter_10_0

				if var_10_6 > #arg_10_0.herolist then
					break
				end

				local var_10_7 = cc.Node:create()

				var_10_7:setAnchorPoint(cc.p(0.5, 0.5))
				var_10_7:setContentSize(var_0_4, var_0_4)
				var_10_7:setPosition((iter_10_0 - 3) * 112 - 56, 0)
				var_10_5:addChild(var_10_7)
				arg_10_0:setBorder(arg_10_0.herolist[var_10_6], var_10_7)
			end

			var_10_1:setItemSize(arg_10_0.width, var_0_4 + 20)
			var_10_1:addContent(var_10_5)
		end

		return var_10_1
	end
end

function var_0_1.setBorder(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_0.player:getHeros()
	local var_11_1 = true

	for iter_11_0, iter_11_1 in ipairs(var_11_0) do
		local var_11_2 = iter_11_1:getTableID()

		if var_11_2 == arg_11_1 or var_0_3:beforeAwaken(var_11_2) == arg_11_1 then
			var_11_1 = false

			break
		end
	end

	if arg_11_1 ~= 0 then
		xyd.setAvatarBorder(arg_11_1, arg_11_2, 1, var_0_3:initialStar(arg_11_1), nil, var_11_1)
	end

	arg_11_2:setTouchEnabled(true)
	arg_11_2:setTouchSwallowEnabled(false)
	arg_11_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
		if arg_12_0.name == "began" then
			touchBeganY = arg_12_0.y

			if not xyd.WindowManager.get():getWindow("new_item_tips") then
				local var_12_0 = xyd.WindowManager.get():openWindow("new_item_tips", {
					noBlock = true,
					id = arg_11_1,
					desc = var_0_3:getDes(arg_11_1),
					name = var_0_3:name(arg_11_1)
				})

				xyd.adaptToWorldPosition(arg_11_2, var_12_0)
			end

			return true
		elseif arg_12_0.name == "moved" then
			local var_12_1 = arg_12_0.y

			if math.abs(var_12_1 - touchBeganY) > 30 then
				xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		elseif arg_12_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("new_item_tips")
		end
	end)
end

function var_0_1.willClose(arg_13_0, arg_13_1)
	xyd.WindowManager.get():closeWindow("new_item_tips")
end

return var_0_1
