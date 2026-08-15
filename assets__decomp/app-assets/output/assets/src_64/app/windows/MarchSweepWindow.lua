local var_0_0 = class("TitleItem", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/map_window/sweep_new/sweep_title.csb"))
		arg_3_0.contentView_:addTo(arg_3_0):setAnchorPoint(0.5, 0.5)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	local var_4_0 = 30
	local var_4_1 = xyd.tables.translation
	local var_4_2 = arg_4_0:contentView():nodeByName("name_txt")

	var_4_2:enableOutline(cc.c4b(255, 255, 255, 255), 2)

	if arg_4_1 > 0 then
		var_4_2:setString(string.format(var_4_1:translation("SWEEP_COUNT"), tostring(arg_4_1)))
		arg_4_0:contentView():nodeByName("star_1"):setPositionX(var_4_2:getPositionX() - var_4_2:getWidth() / 2 - var_4_0)
		arg_4_0:contentView():nodeByName("star_2"):setPositionX(var_4_2:getPositionX() + var_4_2:getWidth() / 2 + var_4_0)
	else
		var_4_2:setString("")
		arg_4_0:contentView():nodeByName("star_1"):setVisible(false)
		arg_4_0:contentView():nodeByName("star_2"):setVisible(false)
	end
end

local var_0_1 = class("EconomyItem", function()
	return cc.Node:create()
end)

function var_0_1.ctor(arg_6_0)
	arg_6_0:contentView()
end

function var_0_1.contentView(arg_7_0)
	if arg_7_0.contentView_ == nil then
		arg_7_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_7_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/map_window/sweep_new/sweep_economy.csb"))
		arg_7_0.contentView_:addTo(arg_7_0):setAnchorPoint(0.5, 0.5)
		arg_7_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_7_0.contentView_
end

function var_0_1.setParams(arg_8_0, arg_8_1)
	local var_8_0 = 0
	local var_8_1 = 0
	local var_8_2 = 0

	if arg_8_1 then
		if arg_8_1.power_drink then
			var_8_0 = arg_8_1.power_drink
		end

		if arg_8_1.march_coin then
			var_8_1 = arg_8_1.march_coin
		end

		if arg_8_1.mana then
			var_8_2 = arg_8_1.mana
		end
	end

	arg_8_0:contentView():nodeByName("num_exp"):setString(var_8_0)
	arg_8_0:contentView():nodeByName("num_march_coin"):setString(var_8_1)
	arg_8_0:contentView():nodeByName("num_jinbi"):setString(var_8_2)
end

function var_0_1.layout(arg_9_0)
	arg_9_0:contentView():nodeByName("power_drink_pic"):setVisible(true)
	arg_9_0:contentView():nodeByName("march_coin_pic"):setVisible(true)
	arg_9_0:contentView():nodeByName("label_exp"):setVisible(false)
	arg_9_0:contentView():nodeByName("label_m"):setVisible(false)
end

local var_0_2 = class("SweepItem", function()
	return cc.Node:create()
end)

function var_0_2.ctor(arg_11_0)
	arg_11_0:contentView()
end

function var_0_2.contentView(arg_12_0)
	if arg_12_0.contentView_ == nil then
		arg_12_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_12_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/map_window/sweep_new/sweep_item.csb"))
		arg_12_0.contentView_:addTo(arg_12_0):setAnchorPoint(0.5, 0.5)
		arg_12_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_12_0.contentView_
end

function var_0_2.setParams(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0 = xyd.tables.translation
	local var_13_1 = arg_13_2 * 5 + 1
	local var_13_2 = math.min(#arg_13_3, (arg_13_2 + 1) * 5)
	local var_13_3 = 0

	arg_13_0.items = {}
	arg_13_0.tips = {}

	arg_13_0:contentView():nodeByName("item_text"):setVisible(false)

	for iter_13_0 = var_13_1, var_13_2 do
		local var_13_4 = arg_13_3[iter_13_0]

		if var_13_4.table_id then
			local var_13_5 = cc.Node:create()

			var_13_5:setContentSize(114, 113)
			var_13_5:setAnchorPoint(cc.p(0.5, 0.5))
			xyd.setItemBorder(var_13_5, var_13_4.table_id, false, false, var_13_4.item_num)
			arg_13_0:contentView():nodeByName("item_list"):addChild(var_13_5)
			var_13_5:setPosition(var_13_3 * 120 + 95, 60)

			var_13_3 = var_13_3 + 1

			var_13_5:setVisible(false)

			local var_13_6 = {
				id = var_13_4.table_id
			}

			xyd.addTips(var_13_5, var_13_6)
			table.insert(arg_13_0.items, var_13_5)
		end
	end
end

local var_0_3 = class("MarchSweepWindow", import("app.common.ui.BaseWindow"))
local var_0_4 = 6
local var_0_5 = require("framework.scheduler")
local var_0_6 = 0.12
local var_0_7 = 0.1

function var_0_3.ctor(arg_14_0, arg_14_1, arg_14_2)
	var_0_3.super.ctor(arg_14_0, arg_14_1, arg_14_2)

	arg_14_0.award = {}
	arg_14_0.economys = {}

	for iter_14_0 = 1, #arg_14_2.power_drink do
		arg_14_0.award[iter_14_0] = {}
		arg_14_0.economys[iter_14_0] = {}
		arg_14_0.economys[iter_14_0].power_drink = arg_14_2.power_drink[iter_14_0]

		for iter_14_1 = 1, #arg_14_2.award[iter_14_0] do
			if arg_14_2.award[iter_14_0][iter_14_1].table_id ~= -1 then
				table.insert(arg_14_0.award[iter_14_0], arg_14_2.award[iter_14_0][iter_14_1])
			elseif arg_14_2.award[iter_14_0][iter_14_1].mana then
				arg_14_0.economys[iter_14_0].mana = arg_14_2.award[iter_14_0][iter_14_1].item_num
			elseif arg_14_2.award[iter_14_0][iter_14_1].march_coin then
				arg_14_0.economys[iter_14_0].march_coin = arg_14_2.award[iter_14_0][iter_14_1].item_num
			end
		end
	end
end

function var_0_3.willOpen(arg_15_0, arg_15_1)
	arg_15_0.listView_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, arg_15_0:nodeByName("reward_list"):getWidth(), arg_15_0:nodeByName("reward_list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_15_0:nodeByName("reward_list")):onScroll(handler(arg_15_0, arg_15_0.scrollListener))

	local var_15_0 = import("app.common.ui.SplitLine")
	local var_15_1 = arg_15_0:nodeByName("line")
	local var_15_2 = var_15_0.new({
		size = var_15_1:getWidth(),
		align = xyd.SplitLineAlign.CENTER
	})

	var_15_2:addTo(var_15_1)
	var_15_2:setPosition(var_15_1:getWidth() / 2, 1)
end

function var_0_3.scrollListener(arg_16_0, arg_16_1)
	if arg_16_1.name == "began" then
		arg_16_0.scrollViewMoved_ = false
		arg_16_0.prevX_ = arg_16_1.x
	elseif arg_16_1.name == "moved" and 20 <= math.abs(arg_16_1.x - arg_16_0.prevX_) then
		arg_16_0.scrollViewMoved_ = true
	end
end

function var_0_3.didOpen(arg_17_0, arg_17_1)
	var_0_3.super:didOpen(arg_17_1)

	local var_17_0 = false
	local var_17_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).guideFuncList

	if not var_17_1[xyd.specialGuide.March] or var_17_1[xyd.specialGuide.March] == 0 then
		var_17_0 = true
	end

	arg_17_0:nodeByName("title_txt"):setString(xyd.tables.translation:translation("ALERT_AWARD_NAME"))
	arg_17_0:nodeByName("confirm_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
		xyd.buttonScaleAnim(arg_18_0, arg_18_1)

		if arg_18_1 == ccui.TouchEventType.ended then
			xyd.sendGudieBtnClick("confirm_btn")

			if var_17_0 then
				local var_18_0 = {}

				var_18_0.nowPage = 1
				var_18_0.pageNum = 2

				xyd.WindowManager.get():openWindow("march_guide_graphic", var_18_0)
			end

			xyd.WindowManager.get():closeWindow(arg_17_0)
		end
	end)
	arg_17_0:nodeByName("confirm_btn"):setVisible(false)
	arg_17_0:addBlockLayerWithNoTouchEvent()
	arg_17_0:updateItems()
end

function var_0_3.updateItems(arg_19_0)
	local var_19_0 = {}
	local var_19_1 = {}
	local var_19_2 = 0
	local var_19_3 = {}
	local var_19_4 = 0.1

	table.insert(var_19_3, var_19_4)

	for iter_19_0 = 1, #arg_19_0.award do
		local var_19_5 = 0
		local var_19_6 = {}
		local var_19_7 = arg_19_0:createTitleItem(iter_19_0)

		arg_19_0.listView_:addItem(var_19_7)

		var_19_2 = var_19_2 + 1

		table.insert(var_19_6, var_19_2)

		local var_19_8 = var_19_5 + var_19_7:getContentSize().height
		local var_19_9 = arg_19_0:createEconomyItem(iter_19_0)

		arg_19_0.listView_:addItem(var_19_9)

		var_19_2 = var_19_2 + 1

		table.insert(var_19_6, var_19_2)

		local var_19_10 = var_19_8 + var_19_9:getContentSize().height
		local var_19_11 = arg_19_0.award[iter_19_0]
		local var_19_12 = #var_19_11
		local var_19_13 = math.ceil(var_19_12 / var_0_4)

		for iter_19_1 = 1, var_19_13 do
			local var_19_14 = arg_19_0:createSweepItem(iter_19_1 - 1, var_19_11)

			arg_19_0.listView_:addItem(var_19_14)

			var_19_2 = var_19_2 + 1

			table.insert(var_19_6, var_19_2)

			var_19_10 = var_19_10 + var_19_14:getContentSize().height
		end

		table.insert(var_19_0, var_19_10)
		table.insert(var_19_1, var_19_6)

		var_19_4 = var_19_4 + math.max(var_0_6 * var_19_12 + 0.5, 1)

		table.insert(var_19_3, var_19_4)
	end

	arg_19_0.listView_:reload()

	for iter_19_2 = 1, #arg_19_0.listView_.items_ do
		arg_19_0.listView_.items_[iter_19_2]:setVisible(false)
	end

	arg_19_0.schedulerHanderList = {}

	local var_19_15 = 0
	local var_19_16 = 0
	local var_19_17 = 0

	for iter_19_3 = 1, #var_19_0 do
		var_19_17 = var_19_17 + var_19_0[iter_19_3]

		if var_19_17 > 320 then
			var_19_15 = iter_19_3
			var_19_16 = var_19_17 - 320

			break
		end
	end

	local var_19_18 = 0

	for iter_19_4 = 1, #var_19_0 do
		var_19_18 = var_19_18 + var_19_0[iter_19_4]

		if var_19_18 > 320 then
			local var_19_19 = var_0_5.performWithDelayGlobal(handler(arg_19_0, function()
				local var_20_0 = var_19_1[iter_19_4]

				for iter_20_0 = 1, #var_20_0 do
					local var_20_1 = arg_19_0.listView_.items_[var_20_0[iter_20_0]]

					var_20_1:setVisible(true)

					if var_20_1.itemViews then
						for iter_20_1 = 1, #var_20_1.itemViews do
							local var_20_2 = var_0_5.performWithDelayGlobal(handler(arg_19_0, function()
								var_20_1.itemViews[iter_20_1]:setVisible(true)

								local var_21_0 = transition.sequence({
									cc.ScaleTo:create(var_0_7, 1.2),
									cc.ScaleTo:create(var_0_7, 1)
								})

								var_20_1.itemViews[iter_20_1]:runAction(var_21_0)
							end), var_0_6 * iter_20_1 + (iter_20_0 - 3) * var_0_4 * var_0_6)

							table.insert(arg_19_0.schedulerHanderList, var_20_2)
						end
					end

					if var_20_1.effect then
						var_20_1.effect:play(nil, false)
					end
				end

				if iter_19_4 == var_19_15 then
					transition.moveBy(arg_19_0.listView_.container, {
						time = 0.2,
						x = 0,
						y = var_19_16
					})
				else
					transition.moveBy(arg_19_0.listView_.container, {
						time = 0.2,
						x = 0,
						y = var_19_0[iter_19_4]
					})
				end
			end), var_19_3[iter_19_4])

			table.insert(arg_19_0.schedulerHanderList, var_19_19)
		else
			local var_19_20 = var_0_5.performWithDelayGlobal(handler(arg_19_0, function()
				local var_22_0 = var_19_1[iter_19_4]

				for iter_22_0 = 1, #var_22_0 do
					local var_22_1 = arg_19_0.listView_.items_[var_22_0[iter_22_0]]

					var_22_1:setVisible(true)

					if var_22_1.itemViews then
						for iter_22_1 = 1, #var_22_1.itemViews do
							local var_22_2 = var_0_5.performWithDelayGlobal(handler(arg_19_0, function()
								var_22_1.itemViews[iter_22_1]:setVisible(true)

								local var_23_0 = transition.sequence({
									cc.ScaleTo:create(var_0_7, 1.2),
									cc.ScaleTo:create(var_0_7, 1)
								})

								var_22_1.itemViews[iter_22_1]:runAction(var_23_0)
							end), var_0_6 * iter_22_1 + (iter_22_0 - 3) * var_0_4 * var_0_6)

							table.insert(arg_19_0.schedulerHanderList, var_22_2)
						end
					end

					if var_22_1.effect then
						var_22_1.effect:play(nil, false)
					end
				end
			end), var_19_3[iter_19_4])

			table.insert(arg_19_0.schedulerHanderList, var_19_20)
		end
	end

	local var_19_21 = var_0_5.performWithDelayGlobal(handler(arg_19_0, function()
		arg_19_0:nodeByName("confirm_btn"):setVisible(true)
	end), var_19_3[#var_19_3])

	table.insert(arg_19_0.schedulerHanderList, var_19_21)
end

function var_0_3.createTitleItem(arg_25_0, arg_25_1)
	local var_25_0 = arg_25_0.listView_:newItem()
	local var_25_1 = display.newNode()
	local var_25_2 = var_0_0.new()

	var_25_2:setParams(arg_25_1)
	var_25_1:addChild(var_25_2)

	local var_25_3 = var_25_2:contentView():nodeByName("title_bg"):getContentSize()

	var_25_0:addContent(var_25_1)
	var_25_1:setContentSize(var_25_3.width, var_25_3.height)
	var_25_0:setItemSize(var_25_3.width, var_25_3.height)

	return var_25_0
end

function var_0_3.createEconomyItem(arg_26_0, arg_26_1)
	local var_26_0 = arg_26_0.listView_:newItem()
	local var_26_1 = display.newNode()
	local var_26_2 = var_0_1.new()

	if arg_26_0.economys == nil then
		var_26_2:setParams()
	else
		var_26_2:setParams(arg_26_0.economys[arg_26_1])
	end

	var_26_2:layout()
	var_26_1:addChild(var_26_2)

	local var_26_3 = var_26_2:contentView():nodeByName("economy_bg"):getContentSize()

	var_26_0:addContent(var_26_1)
	var_26_1:setContentSize(var_26_3.width, var_26_3.height)
	var_26_0:setItemSize(var_26_3.width, var_26_3.height)

	return var_26_0
end

function var_0_3.createSweepItem(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = arg_27_0.listView_:newItem()
	local var_27_1 = display.newNode()
	local var_27_2 = var_0_2.new()

	var_27_2:setParams(arg_27_0, arg_27_1, arg_27_2)
	var_27_1:addChild(var_27_2)

	local var_27_3 = var_27_2:contentView():nodeByName("item_bg"):getContentSize()

	var_27_0:addContent(var_27_1)
	var_27_1:setContentSize(var_27_3.width, var_27_3.height)

	local var_27_4 = 33

	var_27_2:setPositionY(var_27_4 / 2)
	var_27_0:setItemSize(var_27_3.width, var_27_3.height + var_27_4)

	var_27_0.itemViews = var_27_2.items

	return var_27_0
end

return var_0_3
