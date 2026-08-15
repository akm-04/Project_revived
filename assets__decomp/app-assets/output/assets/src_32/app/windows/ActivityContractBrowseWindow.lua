local var_0_0 = class("ActivityContractBrowseWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityContract
local var_0_3 = import("app.model.Hero")
local var_0_4 = {
	ITEM = 4,
	TITLE = 0,
	JINGXUAN_HERO = 2,
	UP_HERO = 1,
	NORMAL_HERO = 3
}
local var_0_5 = {
	"ACTIVITY_CONTRACT_TEXT_9",
	"ACTIVITY_CONTRACT_TEXT_10",
	"ACTIVITY_CONTRACT_TEXT_11",
	"ACTIVITY_CONTRACT_TEXT_12",
	"ACTIVITY_CONTRACT_TEXT_13"
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initData()
	arg_2_0:layout()
end

function var_0_0.initData(arg_3_0)
	local var_3_0 = {}
	local var_3_1 = {}
	local var_3_2 = var_0_2:itemIDs()

	for iter_3_0 = 1, #var_3_2 do
		local var_3_3 = var_0_2:rarity(iter_3_0)

		if not var_3_0[var_3_3] then
			var_3_0[var_3_3] = {}
		end

		table.insert(var_3_0[var_3_3], iter_3_0)
	end

	for iter_3_1 = 1, #var_3_0 do
		local var_3_4 = {
			itemType = var_0_4.TITLE,
			text = var_0_1:translation(var_0_5[iter_3_1])
		}

		table.insert(var_3_1, var_3_4)

		for iter_3_2 = 1, #var_3_0[iter_3_1], 6 do
			local var_3_5 = {
				itemType = iter_3_1
			}
			local var_3_6 = {}
			local var_3_7 = {}

			for iter_3_3 = 1, 6 do
				local var_3_8 = var_3_0[iter_3_1][iter_3_2 + iter_3_3 - 1]

				if var_3_8 then
					table.insert(var_3_6, var_0_2:itemID(var_3_8))
					table.insert(var_3_7, var_0_2:itemNum(var_3_8))
				end
			end

			var_3_5.itemIDs = var_3_6
			var_3_5.itemNums = var_3_7

			table.insert(var_3_1, var_3_5)
		end
	end

	arg_3_0.data = var_3_1
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("ACTIVITY_CONTRACT_TEXT_3"))

	local var_4_0 = arg_4_0:nodeByName("list")

	arg_4_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0:getWidth(), var_4_0:getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_4_0)

	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.delegate))
	arg_4_0.list:reload()
end

function var_0_0.delegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #arg_5_0.data
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0
		local var_5_1 = arg_5_1:dequeueItem()

		if not var_5_1 then
			var_5_1 = arg_5_1:newItem()
		else
			var_5_1:removeAllChildren(false)
		end

		local var_5_2 = arg_5_0.data[arg_5_3]
		local var_5_3 = arg_5_0:initCell(var_5_2, arg_5_3)
		local var_5_4 = var_5_3:getWidth()
		local var_5_5 = var_5_3:getHeight()

		var_5_1:setItemSize(var_5_4, var_5_5)
		var_5_1:addContent(var_5_3)

		return var_5_1
	end
end

function var_0_0.initCell(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0
	local var_6_1

	if arg_6_1.itemType == var_0_4.TITLE then
		var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1223/item_title.csb")
		var_6_1 = var_6_0:getChildByName("container")

		var_6_1:getChildByName("text"):setString(arg_6_1.text)
	else
		var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1223/item_avatar.csb")
		var_6_1 = var_6_0:getChildByName("container")

		if arg_6_1.itemType == var_0_4.ITEM then
			local var_6_2 = arg_6_1.itemIDs
			local var_6_3 = arg_6_1.itemNums

			for iter_6_0 = 1, #var_6_2 do
				local var_6_4 = display.newNode()

				var_6_4:setContentSize(86, 86)
				xyd.setItemAndAddTips(var_6_4, var_6_2[iter_6_0], var_6_3[iter_6_0])
				var_6_4:addTo(var_6_1)
				var_6_4:setPosition(43 + (iter_6_0 - 1) * 114, var_6_1:getHeight() - 86)
			end
		else
			local var_6_5 = arg_6_1.itemIDs

			for iter_6_1 = 1, #var_6_5 do
				local var_6_6 = display.newNode()

				var_6_6:setContentSize(86, 86)

				local var_6_7 = var_0_3.new()

				var_6_7:initUnCollected(var_6_5[iter_6_1])
				xyd.setAvatarBorderNewUI(var_6_7, var_6_6)

				local var_6_8 = {
					id = var_6_5[iter_6_1]
				}

				xyd.addTips(var_6_6, var_6_8)
				var_6_6:addTo(var_6_1)
				var_6_6:setPosition(43 + (iter_6_1 - 1) * 114, var_6_1:getHeight() - 86)
			end
		end
	end

	var_6_0:setContentSize(var_6_1:getContentSize())

	return var_6_0
end

function var_0_0.didOpen(arg_7_0)
	var_0_0.super.didOpen(arg_7_0)
	arg_7_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
