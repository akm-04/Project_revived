local var_0_0 = class("SweepItem", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/map_window/sweep_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0):setAnchorPoint(0.5, 0.5)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = xyd.tables.translation
	local var_4_1 = arg_4_2 * 5 + 1
	local var_4_2 = math.min(#arg_4_3, (arg_4_2 + 1) * 5)
	local var_4_3 = 0

	arg_4_0.items = {}
	arg_4_0.tips = {}

	if var_4_2 < var_4_1 then
		arg_4_0:contentView():nodeByName("item_text"):setVisible(true)
		arg_4_0:contentView():nodeByName("item_text"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
		arg_4_0:contentView():nodeByName("item_text"):setString(var_4_0:translation("MAP_SWEEP_NO_ITEM"))
	else
		arg_4_0:contentView():nodeByName("item_text"):setVisible(false)
	end

	for iter_4_0 = var_4_1, var_4_2 do
		local var_4_4 = arg_4_3[iter_4_0]

		if var_4_4.item_id then
			local var_4_5 = cc.Node:create()

			var_4_5:setContentSize(114, 113)
			var_4_5:setAnchorPoint(cc.p(0.5, 0.5))
			xyd.setItemBorder(var_4_5, var_4_4.item_id, false, false, var_4_4.item_num)
			arg_4_0:contentView():nodeByName("item_list"):addChild(var_4_5)
			var_4_5:setPosition(var_4_3 * 120 + 95, 60)

			var_4_3 = var_4_3 + 1

			var_4_5:setVisible(false)

			local var_4_6 = {
				id = var_4_4.item_id
			}

			xyd.addTips(var_4_5, var_4_6)
			table.insert(arg_4_0.items, var_4_5)
		end
	end
end

local var_0_1 = class("IncubusSweepWindow", import("app.common.ui.BaseWindow"))
local var_0_2 = require("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = xyd.tables.translation
local var_0_5 = 0.2
local var_0_6 = 0.1
local var_0_7 = 6

function var_0_1.ctor(arg_5_0, arg_5_1, arg_5_2)
	var_0_1.super.ctor(arg_5_0, arg_5_1, arg_5_2)

	arg_5_0.awards = arg_5_2.awards
end

function var_0_1.willOpen(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0:nodeByName("list")
	local var_6_1 = var_6_0:getContentSize()

	arg_6_0.height = var_6_1.height
	arg_6_0.listView_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_6_1.width, var_6_1.height),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_6_0):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0:updateItems()
end

function var_0_1.didOpen(arg_7_0, arg_7_1)
	arg_7_0:addBlockLayerWithNoTouchEvent()
end

function var_0_1.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.scrollViewMoved_ = false
		arg_8_0.prevY_ = arg_8_1.y
	elseif arg_8_1.name == "moved" and 20 <= math.abs(arg_8_1.y - arg_8_0.prevY_) then
		arg_8_0.scrollViewMoved_ = true
	end
end

function var_0_1.updateItems(arg_9_0)
	local var_9_0 = {}
	local var_9_1 = {}
	local var_9_2 = 0
	local var_9_3 = {}
	local var_9_4 = 0.1

	table.insert(var_9_3, var_9_4)

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.awards) do
		local var_9_5 = 0
		local var_9_6 = {}
		local var_9_7 = arg_9_0:createTitleItem(iter_9_0)

		arg_9_0.listView_:addItem(var_9_7)

		var_9_2 = var_9_2 + 1

		table.insert(var_9_6, var_9_2)

		local var_9_8 = var_9_5 + var_9_7:getContentSize().height
		local var_9_9 = #iter_9_1

		if var_9_9 == 0 then
			local var_9_10 = arg_9_0:createSweepItem(0, iter_9_1)

			arg_9_0.listView_:addItem(var_9_10)

			var_9_8 = var_9_8 + var_9_10:getContentSize().height
			var_9_2 = var_9_2 + 1

			table.insert(var_9_6, var_9_2)
		else
			local var_9_11 = math.ceil(var_9_9 / var_0_7)

			for iter_9_2 = 1, var_9_11 do
				local var_9_12 = arg_9_0:createSweepItem(iter_9_2 - 1, iter_9_1)

				arg_9_0.listView_:addItem(var_9_12)

				var_9_2 = var_9_2 + 1

				table.insert(var_9_6, var_9_2)

				var_9_8 = var_9_8 + var_9_12:getContentSize().height
			end
		end

		table.insert(var_9_0, var_9_8)
		table.insert(var_9_1, var_9_6)

		var_9_4 = var_9_4 + math.max(var_0_5 * var_9_9 + 0.5, 1)

		table.insert(var_9_3, var_9_4)
	end

	local var_9_13 = arg_9_0:createEffectItem()

	arg_9_0.listView_:addItem(var_9_13)
	table.insert(var_9_0, 200)

	local var_9_14 = var_9_2 + 1

	table.insert(var_9_1, {
		var_9_14
	})

	local var_9_15 = var_9_4 + 1

	table.insert(var_9_3, var_9_15)
	arg_9_0.listView_:reload()

	for iter_9_3 = 1, #arg_9_0.listView_.items_ do
		arg_9_0.listView_.items_[iter_9_3]:setVisible(false)
	end

	arg_9_0.schedulerHanderList = {}

	local var_9_16 = 0
	local var_9_17 = 0
	local var_9_18 = 0

	for iter_9_4 = 1, #var_9_0 do
		var_9_18 = var_9_18 + var_9_0[iter_9_4]

		if var_9_18 > arg_9_0.height then
			var_9_16 = iter_9_4
			var_9_17 = var_9_18 - arg_9_0.height

			break
		end
	end

	local var_9_19 = 0

	for iter_9_5 = 1, #var_9_0 do
		var_9_19 = var_9_19 + var_9_0[iter_9_5]

		if var_9_19 > arg_9_0.height then
			local var_9_20 = var_0_2.performWithDelayGlobal(handler(arg_9_0, function()
				local var_10_0 = var_9_1[iter_9_5]

				for iter_10_0 = 1, #var_10_0 do
					local var_10_1 = arg_9_0.listView_.items_[var_10_0[iter_10_0]]

					var_10_1:setVisible(true)

					if var_10_1.itemViews then
						for iter_10_1 = 1, #var_10_1.itemViews do
							local var_10_2 = var_0_2.performWithDelayGlobal(handler(arg_9_0, function()
								var_10_1.itemViews[iter_10_1]:setVisible(true)

								local var_11_0 = transition.sequence({
									cc.ScaleTo:create(var_0_6, 1.2),
									cc.ScaleTo:create(var_0_6, 1)
								})

								var_10_1.itemViews[iter_10_1]:runAction(var_11_0)
							end), var_0_5 * iter_10_1 + (iter_10_0 - 2) * var_0_7 * var_0_5)

							table.insert(arg_9_0.schedulerHanderList, var_10_2)
						end
					end

					if var_10_1.effect then
						var_10_1.effect:play(nil, false)
					end
				end

				if iter_9_5 == var_9_16 then
					transition.moveBy(arg_9_0.listView_.container, {
						time = 0.2,
						x = 0,
						y = var_9_17
					})
				else
					transition.moveBy(arg_9_0.listView_.container, {
						time = 0.2,
						x = 0,
						y = var_9_0[iter_9_5]
					})
				end
			end), var_9_3[iter_9_5])

			table.insert(arg_9_0.schedulerHanderList, var_9_20)
		else
			local var_9_21 = var_0_2.performWithDelayGlobal(handler(arg_9_0, function()
				local var_12_0 = var_9_1[iter_9_5]

				for iter_12_0 = 1, #var_12_0 do
					local var_12_1 = arg_9_0.listView_.items_[var_12_0[iter_12_0]]

					var_12_1:setVisible(true)

					if var_12_1.itemViews then
						for iter_12_1 = 1, #var_12_1.itemViews do
							local var_12_2 = var_0_2.performWithDelayGlobal(handler(arg_9_0, function()
								var_12_1.itemViews[iter_12_1]:setVisible(true)

								local var_13_0 = transition.sequence({
									cc.ScaleTo:create(var_0_6, 1.2),
									cc.ScaleTo:create(var_0_6, 1)
								})

								var_12_1.itemViews[iter_12_1]:runAction(var_13_0)
							end), var_0_5 * iter_12_1 + (iter_12_0 - 2) * var_0_7 * var_0_5)

							table.insert(arg_9_0.schedulerHanderList, var_12_2)
						end
					end

					if var_12_1.effect then
						var_12_1.effect:play(nil, false)
					end
				end
			end), var_9_3[iter_9_5])

			table.insert(arg_9_0.schedulerHanderList, var_9_21)
		end
	end
end

function var_0_1.createTitleItem(arg_14_0, arg_14_1)
	local var_14_0 = arg_14_0.listView_:newItem()
	local var_14_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/map_window/sweep_title.csb")
	local var_14_2 = var_14_1:getChildByName("name_txt")

	var_14_2:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	var_14_2:setString(string.format(var_0_4:translation("INCUBUS_SWEEP_TITLE"), arg_14_1))

	local var_14_3 = var_14_1:getChildByName("title_bg"):getContentSize()

	var_14_1:setContentSize(var_14_3.width, var_14_3.height)
	var_14_0:setItemSize(var_14_3.width, var_14_3.height)
	var_14_0:addContent(var_14_1)

	return var_14_0
end

function var_0_1.createSweepItem(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = arg_15_0.listView_:newItem()
	local var_15_1 = display.newNode()
	local var_15_2 = var_0_0.new()

	var_15_2:setParams(arg_15_0, arg_15_1, arg_15_2)
	var_15_1:addChild(var_15_2)

	local var_15_3 = var_15_2:contentView():nodeByName("item_bg"):getContentSize()

	var_15_0:addContent(var_15_1)
	var_15_1:setContentSize(var_15_3.width, var_15_3.height)
	var_15_0:setItemSize(var_15_3.width, var_15_3.height + 10)

	var_15_0.itemViews = var_15_2.items

	return var_15_0
end

function var_0_1.createEffectItem(arg_16_0)
	local var_16_0 = arg_16_0.listView_:newItem()
	local var_16_1 = display.newNode()
	local var_16_2 = "skeletons/ui_effect/common_effect_spin2/common_effect_spin2"
	local var_16_3 = var_16_2 .. ".json"
	local var_16_4 = var_16_2 .. ".atlas"
	local var_16_5 = var_0_3.new(var_16_3, var_16_4, 1)

	var_16_5:setPosition(350, 100)
	var_16_1:addChild(var_16_5)
	var_16_5:play(nil, true)

	local var_16_6 = "skeletons/ui_effect/common_effect_campaign1/common_effect_campaign1"
	local var_16_7 = var_16_6 .. ".json"
	local var_16_8 = var_16_6 .. ".atlas"
	local var_16_9 = var_0_3.new(var_16_7, var_16_8, 1)

	var_16_9:setPosition(350, 100)
	var_16_1:addChild(var_16_9)
	var_16_9:play(nil, false)
	var_16_0:addContent(var_16_1)
	var_16_1:setContentSize(700, 200)
	var_16_0:setItemSize(700, 200)

	var_16_0.effect = var_16_9

	return var_16_0
end

function var_0_1.willClose(arg_17_0)
	if arg_17_0.schedulerHanderList then
		for iter_17_0, iter_17_1 in pairs(arg_17_0.schedulerHanderList) do
			if iter_17_1 then
				var_0_2.unscheduleGlobal(iter_17_1)
			end
		end
	end
end

return var_0_1
