local var_0_0 = class("LoveLetterLookOverWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.loveLetter
local var_0_3 = xyd.tables.item
local var_0_4 = xyd.tables.hero

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0 = arg_2_0:nodeByName("list"):getContentSize()

	arg_2_0.width = var_2_0.width
	arg_2_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_0.width, var_2_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_2_0:nodeByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.list:setDelegate(handler(arg_2_0, arg_2_0.delegate))
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_name"):setString(var_0_1:translation("LOVE_LETTER_LOOKOVER"))
	arg_4_0:initItems()
	arg_4_0.list:reload()
end

function var_0_0.initItems(arg_5_0)
	arg_5_0.items = {}

	local var_5_0 = var_0_2:ids()

	for iter_5_0 = 1, #var_5_0 do
		local var_5_1 = {
			id = var_5_0[iter_5_0],
			rarity = var_0_2:rarity(var_5_0[iter_5_0]),
			item_id = var_0_2:itemID(var_5_0[iter_5_0]),
			vip_limit = var_0_2:VIPLimit(var_5_0[iter_5_0]),
			item_num = var_0_2:itemNum(var_5_0[iter_5_0]),
			rate = var_0_2:rate(var_5_0[iter_5_0])
		}

		var_5_1.type = var_0_3:type(var_5_1.item_id)

		table.insert(arg_5_0.items, var_5_1)
	end

	table.sort(arg_5_0.items, function(arg_6_0, arg_6_1)
		if arg_6_0.rarity ~= arg_6_1.rarity then
			return arg_6_0.rarity > arg_6_1.rarity
		else
			return arg_6_0.type < arg_6_1.type
		end
	end)

	for iter_5_1 = 1, #arg_5_0.items - 1 do
		for iter_5_2 = iter_5_1 + 1, #arg_5_0.items do
			if tolua.isnull(arg_5_0.items[iter_5_2]) then
				return
			end

			if arg_5_0.items[iter_5_1].item_id == arg_5_0.items[iter_5_2].item_id and arg_5_0.items[iter_5_1].item_num == arg_5_0.items[iter_5_2].item_num then
				table.remove(arg_5_0.items, iter_5_2)
			end
		end
	end
end

function var_0_0.delegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return math.ceil(#arg_7_0.items / 4)
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_0
		local var_7_1 = arg_7_1:dequeueItem()

		if not var_7_1 then
			var_7_1 = arg_7_1:newItem()
		else
			var_7_1:removeAllChildren(false)
		end

		local var_7_2 = display.newNode()
		local var_7_3 = 225

		for iter_7_0 = 1, 4 do
			local var_7_4 = arg_7_0.items[arg_7_3 * 4 - 4 + iter_7_0]

			if var_7_4 then
				local var_7_5, var_7_6 = arg_7_0:createShowNode(var_7_4)

				var_7_5:addTo(var_7_2)
				var_7_5:setPositionX((iter_7_0 - 1) * (var_7_6 + 12))
			end
		end

		var_7_2:setContentSize(arg_7_0.width, var_7_3)
		var_7_1:addContent(var_7_2)
		var_7_1:setItemSize(arg_7_0.width, var_7_3)

		return var_7_1
	end
end

function var_0_0.createShowNode(arg_8_0, arg_8_1)
	local var_8_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1183/item_hero.csb")
	local var_8_1 = var_8_0:getChildByName("container")
	local var_8_2 = var_8_1:getChildByName("icon")
	local var_8_3 = arg_8_1.item_id
	local var_8_4 = arg_8_1.item_num
	local var_8_5 = arg_8_1.rarity

	xyd.setItemAndAddTips(var_8_2, var_8_3, var_8_4)
	var_8_1:getChildByName("bg_mark_chao"):setVisible(false)
	var_8_1:getChildByName("bg_mark_pu"):setVisible(false)

	if var_8_5 == 3 then
		var_8_1:getChildByName("bg_mark_chao"):setVisible(true)
	elseif var_8_5 == 2 then
		var_8_1:getChildByName("bg_mark_pu"):setVisible(true)
	end

	local var_8_6 = var_0_3:name(var_8_3)

	var_8_1:getChildByName("txt_icon"):setString(var_8_6)

	if arg_8_1.type == -1 then
		local var_8_7 = var_8_1:getContentSize()

		local function var_8_8()
			local var_9_0 = "windows/common/hero_common/icon_hero_star.png"

			return xyd.AssetLoader.get():loadSprite(var_9_0)
		end

		local var_8_9 = display.newNode()
		local var_8_10 = var_0_4:initialStar(var_8_3)
		local var_8_11 = var_8_8()
		local var_8_12 = var_8_11:getWidth()
		local var_8_13 = var_8_12 + (var_8_10 - 1) * 20
		local var_8_14 = var_8_11:getHeight()

		var_8_9:setContentSize(var_8_13, var_8_14)
		var_8_9:setAnchorPoint(0.5, 0.5)
		var_8_9:setPosition(cc.p(0.5 * var_8_7.width + 25, var_8_7.height - 15 - var_8_14 / 2))
		var_8_11:addTo(var_8_9, 10)
		var_8_11:setAnchorPoint(0.5, 0.5)
		var_8_11:setPosition(var_8_12 / 2, var_8_14 / 2 + 2)

		for iter_8_0 = 1, var_8_10 - 1 do
			local var_8_15 = var_8_8()

			var_8_15:addTo(var_8_9, 10 - iter_8_0)
			var_8_15:setAnchorPoint(0.5, 0.5)
			var_8_15:setPosition(var_8_12 / 2 + iter_8_0 * 30, var_8_14 / 2 + 2)
		end

		var_8_9:setScale(0.75)
		var_8_1:addChild(var_8_9)
	end

	return var_8_0, var_8_1:getWidth()
end

function var_0_0.scrollListener(arg_10_0, arg_10_1)
	if arg_10_1.name == "began" then
		arg_10_0.scrollViewMoved_ = false
		arg_10_0.prevY_ = arg_10_1.y
	elseif arg_10_1.name == "moved" and 10 <= math.abs(arg_10_1.y - arg_10_0.prevY_) then
		arg_10_0.scrollViewMoved_ = true
	end
end

return var_0_0
