local var_0_0 = 2
local var_0_1 = class("CollectionItem", function()
	return xyd.AssetLoader.get():loadNodeFromJson("windows/snow/gacha/collection/collection_item.csb")
end)
local var_0_2 = xyd.tables.item
local var_0_3 = xyd.tables.hero

function var_0_1.ctor(arg_2_0)
	arg_2_0.container = arg_2_0:getChildByName("container")
end

function var_0_1.initItems(arg_3_0, arg_3_1)
	for iter_3_0 = 1, var_0_0 do
		arg_3_0:initItem(arg_3_0.container:getChildByName("bg_item" .. iter_3_0), arg_3_1[iter_3_0])
	end
end

function var_0_1.initItem(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = arg_4_2.itemID

	if var_4_0 == 0 then
		arg_4_1:setVisible(false)

		return
	end

	xyd.setItemAndAddTips(arg_4_1:getChildByName("item"), var_4_0, arg_4_2.itemNum)
	arg_4_1:getChildByName("name_txt"):setString(var_0_2:name(var_4_0))

	if arg_4_2.star == 1 then
		arg_4_1:getChildByName("rare"):setVisible(false)
		arg_4_1:getChildByName("star2"):setVisible(false)
		arg_4_1:getChildByName("star3"):setVisible(false)
	elseif arg_4_2.star == 2 then
		arg_4_1:getChildByName("rare"):loadTexture("windows/snow/gacha/collection/rare_txt.png")
		arg_4_1:getChildByName("star3"):setVisible(false)
	elseif arg_4_2.star == 3 then
		arg_4_1:getChildByName("rare"):loadTexture("windows/snow/gacha/collection/epic_txt.png")
	end
end

local var_0_4 = class("SnowGachaCollectionWindow", import("app.common.ui.BaseWindow"))
local var_0_5 = xyd.tables.snowGachaCollection

function var_0_4.willOpen(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0:nodeByName("listview")
	local var_5_1 = var_5_0:getContentSize()

	arg_5_0.listView = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_5_1.width, var_5_1.height),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL
	}):addTo(var_5_0):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0:updateItem()
end

function var_0_4.didOpen(arg_6_0, arg_6_1)
	arg_6_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

function var_0_4.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.listViewMoved_ = false
		arg_7_0.prevX_ = arg_7_1.x
	elseif arg_7_1.name == "moved" and 6 <= math.abs(arg_7_1.x - arg_7_0.prevX_) then
		arg_7_0.listViewMoved_ = true
	end
end

function var_0_4.updateItem(arg_8_0)
	local var_8_0 = math.ceil(var_0_5:size() / var_0_0)

	for iter_8_0 = 1, var_8_0 do
		local var_8_1 = arg_8_0.listView:newItem()
		local var_8_2 = var_0_1.new()
		local var_8_3 = {}
		local var_8_4 = (iter_8_0 - 1) * var_0_0

		for iter_8_1 = 1, var_0_0 do
			var_8_3[iter_8_1] = {}
			var_8_3[iter_8_1].itemID = var_0_5:itemID(var_8_4 + iter_8_1)
			var_8_3[iter_8_1].itemNum = var_0_5:itemNum(var_8_4 + iter_8_1)
			var_8_3[iter_8_1].star = var_0_5:rarity(var_8_4 + iter_8_1)
		end

		var_8_2:initItems(var_8_3)

		local var_8_5 = var_8_2:getChildByName("container"):getContentSize()

		var_8_2:setContentSize(var_8_5.width, var_8_5.height)
		var_8_1:addContent(var_8_2)
		var_8_1:setItemSize(var_8_5.width, var_8_5.height)
		arg_8_0.listView:addItem(var_8_1)
	end

	arg_8_0.listView:reload()
end

return var_0_4
