local var_0_0 = class("ActivityGirslTreasureBrowseWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityGirlsTreasure
local var_0_3 = xyd.tables.dropbox
local var_0_4 = import("app.model.Hero")
local var_0_5 = {
	HERO = 2,
	TITLE = 1,
	ITEM = 3
}
local var_0_6 = {
	NORMAL = 2,
	SX = 1
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
	local var_3_2 = var_0_2:names()

	for iter_3_0 = 1, #var_3_2 do
		local var_3_3 = {
			itemType = var_0_5.TITLE,
			text = var_3_2[iter_3_0]
		}

		table.insert(var_3_0, var_3_3)

		local var_3_4 = var_0_2:dropboxID(iter_3_0)
		local var_3_5 = var_0_3:itemIDs(var_3_4)
		local var_3_6 = var_0_3:itemNums(var_3_4)
		local var_3_7 = {}
		local var_3_8 = {}

		if iter_3_0 == var_0_6.SX or iter_3_0 == var_0_6.NORMAL then
			for iter_3_1 = 1, #var_3_5 do
				if arg_3_0.selfPlayer:getHeroIgnoreAwaken(var_3_5[iter_3_1]) then
					table.insert(var_3_7, var_3_5[iter_3_1])
				else
					table.insert(var_3_8, var_3_5[iter_3_1])
				end
			end

			local var_3_9 = {}

			for iter_3_2, iter_3_3 in ipairs(var_3_8) do
				table.insert(var_3_9, {
					isHas = false,
					tableID = iter_3_3
				})
			end

			for iter_3_4, iter_3_5 in ipairs(var_3_7) do
				table.insert(var_3_9, {
					isHas = true,
					tableID = iter_3_5
				})
			end

			for iter_3_6 = 1, #var_3_9, 6 do
				local var_3_10 = {
					itemType = var_0_5.HERO
				}
				local var_3_11 = {}

				for iter_3_7 = 1, 6 do
					if var_3_9[iter_3_6 + iter_3_7 - 1] then
						table.insert(var_3_11, var_3_9[iter_3_6 + iter_3_7 - 1])
					end
				end

				var_3_10.heros = var_3_11

				table.insert(var_3_0, var_3_10)
			end
		else
			for iter_3_8 = 1, #var_3_5, 6 do
				local var_3_12 = {
					itemType = var_0_5.ITEM
				}
				local var_3_13 = {}

				for iter_3_9 = 1, 6 do
					if var_3_5[iter_3_8 + iter_3_9 - 1] then
						table.insert(var_3_13, var_3_5[iter_3_8 + iter_3_9 - 1])
					end
				end

				local var_3_14 = {}

				for iter_3_10 = 1, 6 do
					if var_3_5[iter_3_8 + iter_3_10 - 1] then
						table.insert(var_3_14, var_3_6[iter_3_8 + iter_3_10 - 1])
					end
				end

				var_3_12.itemIDs = var_3_13
				var_3_12.itemNums = var_3_14

				table.insert(var_3_0, var_3_12)
			end
		end
	end

	arg_3_0.data = var_3_0
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("ACTIVITY_GIRLS_TREASURE_TEXT_2"))

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

	if arg_6_1.itemType == var_0_5.TITLE then
		var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1220/item_title.csb")
		var_6_1 = var_6_0:getChildByName("container")

		var_6_1:getChildByName("text"):setString(arg_6_1.text)
	else
		var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1220/item_avatar.csb")
		var_6_1 = var_6_0:getChildByName("container")

		if arg_6_1.itemType == var_0_5.ITEM then
			local var_6_2 = arg_6_1.itemIDs
			local var_6_3 = arg_6_1.itemNums

			for iter_6_0 = 1, #var_6_2 do
				local var_6_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1220/avatar.csb")

				var_6_4:getChildByName("shadow"):setVisible(false)
				var_6_4:getChildByName("text"):setVisible(false)
				xyd.setItemAndAddTips(var_6_4:getChildByName("container"), var_6_2[iter_6_0], var_6_3[iter_6_0])
				var_6_4:addTo(var_6_1)
				var_6_4:setPosition(43 + (iter_6_0 - 1) * 114, var_6_1:getHeight() - 86)
			end
		else
			local var_6_5 = arg_6_1.heros

			for iter_6_1 = 1, #var_6_5 do
				local var_6_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1220/avatar.csb")
				local var_6_7 = var_0_4.new()

				var_6_7:initUnCollected(var_6_5[iter_6_1].tableID)
				xyd.setAvatarBorderNewUI(var_6_7, var_6_6:getChildByName("container"))

				local var_6_8 = {
					id = var_6_5[iter_6_1].tableID
				}

				xyd.addTips(var_6_6, var_6_8)

				if var_6_5[iter_6_1].isHas then
					var_6_6:getChildByName("text"):enableOutline(cc.c4b(36, 138, 25, 255), 2)
					var_6_6:getChildByName("text"):setString(var_0_1:translation("MULTISKIN_OWN_TEXT"))
				else
					var_6_6:getChildByName("shadow"):setVisible(false)
					var_6_6:getChildByName("text"):setVisible(false)
				end

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
