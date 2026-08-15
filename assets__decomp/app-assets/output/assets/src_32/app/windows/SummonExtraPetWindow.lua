local var_0_0 = class("SummonExtraPetWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = 150

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.items = arg_1_2.extraAwardItems or {}
	arg_1_0.items = arg_1_0:summaryAwards(arg_1_0.items)
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.summaryAwards(arg_2_0, arg_2_1)
	local var_2_0 = {}

	for iter_2_0 = 1, #arg_2_1 do
		var_2_0[arg_2_1[iter_2_0].item_id] = (var_2_0[arg_2_1[iter_2_0].item_id] or 0) + (arg_2_1[iter_2_0].item_num or 0)
	end

	local var_2_1 = {}

	for iter_2_1, iter_2_2 in pairs(var_2_0) do
		table.insert(var_2_1, {
			item_id = iter_2_1,
			item_num = iter_2_2
		})
	end

	return var_2_1
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen()
	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0)
	var_0_0.super.didOpen()
	arg_4_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = var_0_1 * #arg_5_0.items
	local var_5_1 = arg_5_0:nodeByName("scroll"):getContentSize()

	if var_5_0 < var_5_1.width then
		arg_5_0:nodeByName("scroll"):width(var_5_0)

		var_5_1 = arg_5_0:nodeByName("scroll"):getContentSize()
	end

	arg_5_0.itemList = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_5_1.width, var_5_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_5_0:nodeByName("scroll"))

	arg_5_0.itemList:setBounceable(false)
	arg_5_0:itemListLayout()
end

function var_0_0.itemListLayout(arg_6_0)
	for iter_6_0 = 1, #arg_6_0.items do
		local var_6_0 = arg_6_0.itemList:dequeueItem()

		if not var_6_0 then
			var_6_0 = arg_6_0.itemList:newItem()
		else
			var_6_0:removeAllChildren(true)
		end

		local var_6_1 = arg_6_0:creatItemContent(arg_6_0.items[iter_6_0])
		local var_6_2 = var_6_1:getWidth()
		local var_6_3 = var_6_1:getHeight()

		var_6_0:setItemSize(var_6_2, var_6_3)
		var_6_0:addContent(var_6_1)
		arg_6_0.itemList:addItem(var_6_0)
	end

	arg_6_0.itemList:reload()
end

function var_0_0.creatItemContent(arg_7_0, arg_7_1)
	local var_7_0 = display.newNode()

	var_7_0:setContentSize(150, 100)

	local var_7_1 = display.newNode()

	var_7_1:setContentSize(100, 100)
	xyd.setItemBorder(var_7_1, arg_7_1.item_id)
	var_7_1:addTo(var_7_0)
	var_7_1:setPosition(cc.p(0, 0))

	local var_7_2 = {
		font = "fonts/main_font.ttf",
		size = 24,
		color = cc.c3b(255, 255, 255)
	}
	local var_7_3 = xyd.AssetLoader.get():loadLabel(var_7_2)

	var_7_3:setString("X" .. arg_7_1.item_num)
	var_7_3:setAnchorPoint(cc.p(0, 0))
	var_7_3:addTo(var_7_0)
	var_7_3:setPosition(110, 40)

	return var_7_0
end

return var_0_0
