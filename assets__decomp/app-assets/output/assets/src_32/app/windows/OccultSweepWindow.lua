local var_0_0 = class("EconomyItem", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/map_window/sweep_new/sweep_economy.csb"))
		arg_3_0.contentView_:addTo(arg_3_0):setAnchorPoint(0.5, 0.5)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	local var_4_0 = xyd.tables.translation
	local var_4_1 = arg_4_0:contentView():nodeByName("label_exp")

	var_4_1:setAnchorPoint(cc.p(0, 0.5))
	var_4_1:setString(var_4_0:translation("OCCULT_TOP_SCORE"))
	arg_4_0:contentView():nodeByName("num_exp"):setString(arg_4_1 or 0)
	arg_4_0:contentView():nodeByName("num_exp"):setAnchorPoint(cc.p(0, 0.5))
	arg_4_0:contentView():nodeByName("num_exp"):setPositionX(var_4_1:getPositionX() + var_4_1:getContentSize().width + 20)
	arg_4_0:contentView():nodeByName("img_jinbi"):setVisible(false)
	arg_4_0:contentView()
end

local var_0_1 = class("TitleItem", function()
	return cc.Node:create()
end)

function var_0_1.ctor(arg_6_0)
	arg_6_0:contentView()
end

function var_0_1.contentView(arg_7_0)
	if arg_7_0.contentView_ == nil then
		arg_7_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_7_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/map_window/sweep_new/sweep_title.csb"))
		arg_7_0.contentView_:addTo(arg_7_0):setAnchorPoint(0.5, 0.5)
		arg_7_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_7_0.contentView_
end

function var_0_1.setParams(arg_8_0, arg_8_1)
	local var_8_0 = xyd.tables.translation

	arg_8_0:contentView():nodeByName("name_txt"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_8_0:contentView():nodeByName("name_txt"):setString(var_8_0:translation("OCCULT_SWEEP_REWARD_TEXT"))
end

local var_0_2 = class("SweepItem", function()
	return cc.Node:create()
end)

function var_0_2.ctor(arg_10_0)
	arg_10_0:contentView()
end

function var_0_2.contentView(arg_11_0)
	if arg_11_0.contentView_ == nil then
		arg_11_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_11_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/map_window/sweep_new/sweep_item.csb"))
		arg_11_0.contentView_:addTo(arg_11_0):setAnchorPoint(0.5, 0.5)
		arg_11_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_11_0.contentView_
end

function var_0_2.setParams(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = xyd.tables.translation
	local var_12_1 = arg_12_2 * 5 + 1
	local var_12_2 = math.min(#arg_12_3, (arg_12_2 + 1) * 5)
	local var_12_3 = 0

	arg_12_0.items = {}
	arg_12_0.tips = {}

	if var_12_2 < var_12_1 then
		arg_12_0:contentView():nodeByName("item_text"):setVisible(true)
		arg_12_0:contentView():nodeByName("item_text"):setString(var_12_0:translation("MAP_SWEEP_NO_ITEM"))
	else
		arg_12_0:contentView():nodeByName("item_text"):setVisible(false)
	end

	for iter_12_0 = var_12_1, var_12_2 do
		local var_12_4 = arg_12_3[iter_12_0]

		if var_12_4.table_id then
			local var_12_5 = cc.Node:create()

			var_12_5:setContentSize(100, 100)
			var_12_5:setAnchorPoint(cc.p(0.5, 0.5))
			xyd.setItemBorder(var_12_5, tonumber(var_12_4.table_id), false, false, var_12_4.item_num)
			arg_12_0:contentView():nodeByName("item_list"):addChild(var_12_5)
			var_12_5:setPosition(var_12_3 * 120 + 65, 60)

			var_12_3 = var_12_3 + 1

			var_12_5:setVisible(false)

			local var_12_6 = {
				id = var_12_4.table_id
			}

			xyd.addTips(var_12_5, var_12_6)
			table.insert(arg_12_0.items, var_12_5)
		end
	end
end

local var_0_3 = class("OccultSweepWindow", import("app.common.ui.BaseWindow"))
local var_0_4 = 5
local var_0_5 = require("framework.scheduler")
local var_0_6 = import("app.common.ui.SpineEffect")
local var_0_7 = 0.12
local var_0_8 = 0.1
local var_0_9 = xyd.tables.translation

function var_0_3.ctor(arg_13_0, arg_13_1, arg_13_2)
	var_0_3.super.ctor(arg_13_0, arg_13_1, arg_13_2)

	arg_13_0.params = arg_13_2
	arg_13_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_13_0.dropItems = arg_13_2.awards
	arg_13_0.topScore = arg_13_2.top_score

	arg_13_0.player:handleRewardsWithoutShow(arg_13_0.dropItems)
end

function var_0_3.scrollListener(arg_14_0, arg_14_1)
	if arg_14_1.name == "began" then
		arg_14_0.scrollViewMoved_ = false
		arg_14_0.prevX_ = arg_14_1.x
	elseif arg_14_1.name == "moved" and 20 <= math.abs(arg_14_1.x - arg_14_0.prevX_) then
		arg_14_0.scrollViewMoved_ = true
	end
end

function var_0_3.updateItems(arg_15_0)
	arg_15_0.listView_:removeAllItems()

	local var_15_0 = {}
	local var_15_1 = {}
	local var_15_2 = 0
	local var_15_3 = {}
	local var_15_4 = 0.1

	table.insert(var_15_3, var_15_4)

	local var_15_5 = arg_15_0:createEffectItem()

	arg_15_0.listView_:addItem(var_15_5)
	table.insert(var_15_0, 300)

	local var_15_6 = var_15_2 + 1

	table.insert(var_15_1, {
		var_15_6
	})

	local var_15_7 = var_15_4 + 1

	table.insert(var_15_3, var_15_7)

	local var_15_8 = 0
	local var_15_9 = {}
	local var_15_10 = 1
	local var_15_11 = arg_15_0:createTitleItem(var_15_10)

	arg_15_0.listView_:addItem(var_15_11)

	local var_15_12 = var_15_8 + var_15_11:getContentSize().height
	local var_15_13 = var_15_6 + 1

	table.insert(var_15_9, var_15_13)

	local var_15_14 = arg_15_0:createEconomyItem(arg_15_0.topScore)

	arg_15_0.listView_:addItem(var_15_14)

	local var_15_15 = var_15_13 + 1

	table.insert(var_15_9, var_15_15)

	local var_15_16 = var_15_12 + var_15_14:getContentSize().height
	local var_15_17 = arg_15_0.dropItems
	local var_15_18 = #var_15_17

	if var_15_18 == 0 then
		local var_15_19 = arg_15_0:createSweepItem(0, var_15_17)

		arg_15_0.listView_:addItem(var_15_19)

		var_15_16 = var_15_16 + var_15_19:getContentSize().height
		var_15_15 = var_15_15 + 1

		table.insert(var_15_9, var_15_15)
	else
		local var_15_20 = math.ceil(var_15_18 / var_0_4)

		for iter_15_0 = 1, var_15_20 do
			local var_15_21 = arg_15_0:createSweepItem(iter_15_0 - 1, var_15_17)

			arg_15_0.listView_:addItem(var_15_21)

			var_15_16 = var_15_16 + var_15_21:getContentSize().height
			var_15_15 = var_15_15 + 1

			table.insert(var_15_9, var_15_15)
		end
	end

	table.insert(var_15_0, var_15_16)
	table.insert(var_15_1, var_15_9)

	local var_15_22 = var_15_7 + math.max(var_0_7 * var_15_18 + 0.5, 1)

	table.insert(var_15_3, var_15_22)
	arg_15_0.listView_:reload()

	for iter_15_1 = 1, #arg_15_0.listView_.items_ do
		arg_15_0.listView_.items_[iter_15_1]:setVisible(false)
	end

	arg_15_0.schedulerHanderList = {}

	local var_15_23 = 0
	local var_15_24 = 0
	local var_15_25 = 0

	for iter_15_2 = 1, #var_15_0 do
		var_15_25 = var_15_25 + var_15_0[iter_15_2]

		if var_15_25 > 510 then
			var_15_23 = iter_15_2
			var_15_24 = var_15_25 - 510

			break
		end
	end

	local var_15_26 = 0

	for iter_15_3 = 1, #var_15_0 do
		var_15_26 = var_15_26 + var_15_0[iter_15_3]

		if var_15_26 >= 510 then
			local var_15_27 = var_0_5.performWithDelayGlobal(handler(arg_15_0, function()
				local var_16_0 = var_15_1[iter_15_3]

				for iter_16_0 = 1, #var_16_0 do
					local var_16_1 = arg_15_0.listView_.items_[var_16_0[iter_16_0]]

					var_16_1:setVisible(true)

					if var_16_1.itemViews then
						for iter_16_1 = 1, #var_16_1.itemViews do
							local var_16_2 = var_0_5.performWithDelayGlobal(handler(arg_15_0, function()
								var_16_1.itemViews[iter_16_1]:setVisible(true)

								local var_17_0 = transition.sequence({
									cc.ScaleTo:create(var_0_8, 1.2),
									cc.ScaleTo:create(var_0_8, 1)
								})

								var_16_1.itemViews[iter_16_1]:runAction(var_17_0)
							end), var_0_7 * iter_16_1 + (iter_16_0 - 3) * var_0_4 * var_0_7)

							table.insert(arg_15_0.schedulerHanderList, var_16_2)
						end
					end

					if var_16_1.effect then
						var_16_1.effect:play(function()
							var_16_1.effect:play(nil, true, nil, "texiao02")
						end, false, nil, "texiao01")
					end
				end

				if iter_15_3 == var_15_23 then
					transition.moveBy(arg_15_0.listView_.container, {
						time = 0.2,
						x = 0,
						y = var_15_24
					})
				else
					transition.moveBy(arg_15_0.listView_.container, {
						time = 0.2,
						x = 0,
						y = var_15_0[iter_15_3]
					})
				end
			end), var_15_3[iter_15_3])

			table.insert(arg_15_0.schedulerHanderList, var_15_27)
		else
			local var_15_28 = var_0_5.performWithDelayGlobal(handler(arg_15_0, function()
				local var_19_0 = var_15_1[iter_15_3]

				for iter_19_0 = 1, #var_19_0 do
					local var_19_1 = arg_15_0.listView_.items_[var_19_0[iter_19_0]]

					var_19_1:setVisible(true)

					if var_19_1.itemViews then
						for iter_19_1 = 1, #var_19_1.itemViews do
							local var_19_2 = var_0_5.performWithDelayGlobal(handler(arg_15_0, function()
								var_19_1.itemViews[iter_19_1]:setVisible(true)

								local var_20_0 = transition.sequence({
									cc.ScaleTo:create(var_0_8, 1.2),
									cc.ScaleTo:create(var_0_8, 1)
								})

								var_19_1.itemViews[iter_19_1]:runAction(var_20_0)
							end), var_0_7 * iter_19_1 + (iter_19_0 - 3) * var_0_4 * var_0_7)

							table.insert(arg_15_0.schedulerHanderList, var_19_2)
						end
					end

					if var_19_1.effect then
						var_19_1.effect:play(function()
							var_19_1.effect:play(nil, true, nil, "texiao02")
						end, false, nil, "texiao01")
					end
				end
			end), var_15_3[iter_15_3])

			table.insert(arg_15_0.schedulerHanderList, var_15_28)
		end
	end
end

function var_0_3.createTitleItem(arg_22_0, arg_22_1)
	local var_22_0 = arg_22_0.listView_:newItem()
	local var_22_1 = display.newNode()
	local var_22_2 = var_0_1.new()

	var_22_2:setParams(arg_22_1)
	var_22_1:addChild(var_22_2)

	local var_22_3 = var_22_2:contentView():nodeByName("title_bg"):getContentSize()

	var_22_0:addContent(var_22_1)
	var_22_1:setContentSize(var_22_3.width, var_22_3.height)
	var_22_0:setItemSize(var_22_3.width, var_22_3.height)

	return var_22_0
end

function var_0_3.createEconomyItem(arg_23_0, arg_23_1)
	local var_23_0 = arg_23_0.listView_:newItem()
	local var_23_1 = display.newNode()
	local var_23_2 = var_0_0.new()

	var_23_2:setParams(arg_23_1)
	var_23_1:addChild(var_23_2)

	local var_23_3 = var_23_2:contentView():nodeByName("economy_bg"):getContentSize()

	var_23_0:addContent(var_23_1)
	var_23_1:setContentSize(var_23_3.width, var_23_3.height)
	var_23_0:setItemSize(var_23_3.width, var_23_3.height)

	return var_23_0
end

function var_0_3.createSweepItem(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = arg_24_0.listView_:newItem()
	local var_24_1 = display.newNode()
	local var_24_2 = var_0_2.new()

	var_24_2:setParams(arg_24_0, arg_24_1, arg_24_2)
	var_24_1:addChild(var_24_2)

	local var_24_3 = var_24_2:contentView():nodeByName("item_bg"):getContentSize()

	var_24_0:addContent(var_24_1)
	var_24_1:setContentSize(var_24_3.width, var_24_3.height)
	var_24_0:setItemSize(var_24_3.width, var_24_3.height + 10)

	var_24_0.itemViews = var_24_2.items

	return var_24_0
end

function var_0_3.createEffectItem(arg_25_0)
	local var_25_0 = arg_25_0.listView_:newItem()
	local var_25_1 = display.newNode()
	local var_25_2 = "skeletons/ui_effect/common_effect_spin2/sweep_out"
	local var_25_3 = var_25_2 .. ".json"
	local var_25_4 = var_25_2 .. ".atlas"
	local var_25_5 = var_0_6.new(var_25_3, var_25_4, 1)

	var_25_5:setPosition(350, 100)
	var_25_1:addChild(var_25_5)
	var_25_5:play(nil, false)
	var_25_0:addContent(var_25_1)
	var_25_1:setContentSize(700, 200)
	var_25_0:setItemSize(700, 200)

	var_25_0.effect = var_25_5

	return var_25_0
end

function var_0_3.willOpen(arg_26_0, arg_26_1)
	var_0_3.super.willOpen(arg_26_0, arg_26_1)

	arg_26_0.listView_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, arg_26_0:nodeByName("list"):getWidth(), arg_26_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_26_0:nodeByName("list")):onScroll(handler(arg_26_0, arg_26_0.scrollListener))

	arg_26_0:updateItems()
end

function var_0_3.playFloatText(arg_27_0)
	local var_27_0 = arg_27_0:nodeByName("list")
	local var_27_1 = {
		color = cc.c3b(108, 253, 19)
	}

	var_27_1.size = 28

	local var_27_2 = xyd.AssetLoader.get():loadLabel(var_27_1)

	var_27_2:addTo(var_27_0)
	var_27_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_27_2:setPosition(var_27_0:getContentSize().width / 2, var_27_0:getContentSize().height / 2)
	var_27_2:setLocalZOrder(100)

	local var_27_3 = string.format(var_0_9:translation("SWEEP_FLOAT_TXT"), xyd.tables.item:name(arg_27_0.itemComposeID), arg_27_0.player:getBackpack():getItemNumByID(arg_27_0.itemComposeID), arg_27_0.needItemComposeNum)

	var_27_2:setString(var_27_3)
	var_27_2:enableOutline(cc.c4b(0, 0, 0, 255), 1)

	local var_27_4 = cc.MoveTo:create(1.5, cc.p(var_27_2:getPositionX(), var_27_2:getPositionY() + 70))
	local var_27_5 = cc.FadeOut:create(2)

	var_27_2:runAction(cc.Sequence:create(cc.Spawn:create(var_27_4, var_27_5), cc.CallFunc:create(function()
		var_27_2:setVisible(false)
		var_27_2:removeSelf()
	end)))
end

function var_0_3.didOpen(arg_29_0)
	arg_29_0:addBlockLayer()
end

function var_0_3.willClose(arg_30_0)
	if arg_30_0.schedulerHanderList then
		for iter_30_0, iter_30_1 in pairs(arg_30_0.schedulerHanderList) do
			if iter_30_1 then
				var_0_5.unscheduleGlobal(iter_30_1)
			end
		end
	end
end

return var_0_3
