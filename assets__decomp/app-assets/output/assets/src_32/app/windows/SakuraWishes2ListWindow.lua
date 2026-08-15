local var_0_0 = class("SakuraWishes2ListWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = xyd.tables.arenaMode
local var_0_4 = xyd.tables.activitySakuraWishes2Table
local var_0_5 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.sakuraWishesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA_WISHES2)
	arg_1_0.items = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:getItemList()
	arg_2_0:layout()
end

function var_0_0.getItemList(arg_3_0)
	arg_3_0.ids = clone(var_0_4:ids())

	arg_3_0:filterIDs()
	arg_3_0:sortItemList()
end

function var_0_0.filterIDs(arg_4_0)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in pairs(arg_4_0.ids) do
		var_4_0[iter_4_1] = {
			item_id = var_0_4:item(iter_4_1),
			num = var_0_4:num(iter_4_1)
		}
	end

	local var_4_1 = {}

	for iter_4_2, iter_4_3 in pairs(arg_4_0.ids) do
		for iter_4_4, iter_4_5 in pairs(var_4_0) do
			if iter_4_5.item_id == var_4_0[iter_4_3].item_id and iter_4_5.num == var_4_0[iter_4_3].num and iter_4_4 ~= iter_4_3 then
				table.insert(var_4_1, var_0_4:rarity(iter_4_3) > var_0_4:rarity(iter_4_4) and iter_4_3 or iter_4_4)
			end
		end
	end

	for iter_4_6 = #arg_4_0.ids, 1, -1 do
		if xyd.tableHaveElement(var_4_1, arg_4_0.ids[iter_4_6]) then
			table.remove(arg_4_0.ids, iter_4_6)
		end
	end
end

function var_0_0.sortItemList(arg_5_0)
	table.sort(arg_5_0.ids, function(arg_6_0, arg_6_1)
		if var_0_4:rarity(arg_6_0) ~= var_0_4:rarity(arg_6_1) then
			return var_0_4:rarity(arg_6_0) > var_0_4:rarity(arg_6_1)
		elseif var_0_4:isRarest(arg_6_0) ~= var_0_4:isRarest(arg_6_1) then
			return var_0_4:isRarest(arg_6_0) > var_0_4:isRarest(arg_6_1)
		else
			return arg_6_1 < arg_6_0
		end
	end)
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super.didOpen(arg_7_0, arg_7_1)
	arg_7_0:addBlockLayer()
end

function var_0_0.willClose(arg_8_0, arg_8_1)
	arg_8_0.super.willOpen(arg_8_0, arg_8_1)
end

function var_0_0.layout(arg_9_0)
	arg_9_0.itemList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, 908, 450),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_9_0:nodeByName("item_container"))

	arg_9_0.itemList_:setTouchSwallowEnabled(false)
	arg_9_0:nodeByName("item_container"):setTouchSwallowEnabled(false)
	arg_9_0.itemList_:setDelegate(handler(arg_9_0, arg_9_0.itemDelegate))
	arg_9_0.itemList_:reload()
end

function var_0_0.itemDelegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return math.ceil(#arg_10_0.ids / 2)
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_0
		local var_10_1
		local var_10_2
		local var_10_3 = arg_10_0.itemList_:dequeueItem()

		if not var_10_3 then
			var_10_3 = arg_10_0.itemList_:newItem()
		else
			var_10_3:removeAllChildren()
		end

		local var_10_4 = display.newNode()

		var_10_4:setTouchSwallowEnabled(false)

		for iter_10_0 = 1, 2 do
			local var_10_5 = display.newNode()

			if (arg_10_3 - 1) * 2 + iter_10_0 > #arg_10_0.ids then
				break
			end

			arg_10_0:initCell(var_10_5, (arg_10_3 - 1) * 2 + iter_10_0)
			var_10_5:setPosition(0, (2 - iter_10_0) * 240)
			var_10_4:addChild(var_10_5)
		end

		var_10_4:setContentSize(cc.size(208, 450))
		var_10_3:setItemSize(240, 450)
		var_10_3:addContent(var_10_4)

		return var_10_3
	end
end

function var_0_0.initCell(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_0.ids[arg_11_2]
	local var_11_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/sakura_wishes2/list/sakura_wishes_item.csb")
	local var_11_2 = var_11_1:getChildByName("bg"):getContentSize()

	var_11_1:addTo(arg_11_1)
	arg_11_1:setContentSize(var_11_2)
	xyd.setItemAndAddTips(var_11_1:getChildByName("item_avatar"), var_0_4:item(var_11_0))
	var_11_1:getChildByName("item_name"):setString(xyd.tables.item:name(var_0_4:item(var_11_0)))

	if var_0_4:rarity(var_11_0) <= 2 then
		var_11_1:getChildByName("rare_txt"):setVisible(true)
	elseif var_0_4:rarity(var_11_0) > 2 and var_0_4:isRarest(var_11_0) == 0 then
		var_11_1:getChildByName("epic_txt"):setVisible(true)
	else
		var_11_1:getChildByName("up"):setVisible(true)
	end

	local function var_11_3()
		local var_12_0 = "windows/sakura_wishes2/list/icon_star.png"

		return xyd.AssetLoader.get():loadSprite(var_12_0)
	end

	local var_11_4 = var_0_4:rarity(var_11_0)

	for iter_11_0 = 1, var_11_4 do
		local var_11_5 = var_11_3()

		var_11_5:addTo(var_11_1:getChildByName("star_node"))
		var_11_5:setPosition((3 - var_11_4) * 16 + (iter_11_0 - 1) * 33, 0)
	end
end

return var_0_0
