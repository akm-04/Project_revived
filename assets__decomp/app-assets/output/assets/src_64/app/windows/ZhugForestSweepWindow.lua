local var_0_0 = class("ZhugForestSweepWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.item
local var_0_4 = xyd.tables.zhugeSweepEvent
local var_0_5 = 5
local var_0_6 = 100
local var_0_7 = 0.12
local var_0_8 = 0.1
local var_0_9 = 0.5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.resultAwards = {}
	arg_1_0.tmpAwards = {}
	arg_1_0.awards = {}
	arg_1_0.items = {}
	arg_1_0.adventureCount_ = 0
	arg_1_0.itemHeights_ = {}
	arg_1_0.itemDelays_ = {}
	arg_1_0.itemCounts_ = {}
	arg_1_0.isShowAnimation_ = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initListview()
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	if arg_3_0.handle_ then
		var_0_1.unscheduleGlobal(arg_3_0.handle_)

		arg_3_0.handle_ = nil
	end
end

function var_0_0.startEvent(arg_4_0)
	if arg_4_0.adventureCount_ > 0 then
		local var_4_0 = arg_4_0.list:getScrollNode()

		arg_4_0.recordScrollPos_ = cc.p(var_4_0:getPosition())
	end

	arg_4_0.adventureCount_ = arg_4_0.adventureCount_ + 1

	arg_4_0:initAwards()
	arg_4_0:initNewItems()
	arg_4_0:playAnimation()
end

function var_0_0.initAwards(arg_5_0)
	if arg_5_0.resultAwards and next(arg_5_0.resultAwards) then
		arg_5_0.awards[arg_5_0.adventureCount_] = {}

		local var_5_0 = {}

		for iter_5_0 = 1, #arg_5_0.resultAwards do
			local var_5_1 = arg_5_0.resultAwards[iter_5_0]

			for iter_5_1, iter_5_2 in pairs(var_5_1) do
				if iter_5_2 and next(iter_5_2) then
					arg_5_0.backpack:addItemsByID(iter_5_2[1].table_id, iter_5_2[1].item_num)
					table.insert(var_5_0, iter_5_2[1])
				end
			end
		end

		arg_5_0.awards[arg_5_0.adventureCount_] = var_5_0
	end
end

function var_0_0.layout(arg_6_0)
	arg_6_0:updateEnergy()
	arg_6_0:nodeByName("buy_box_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended and not arg_6_0.isShowAnimation_ then
			xyd.WindowManager.get():openWindow("garden_seed")
		end
	end)
	arg_6_0:nodeByName("btn_add_energy"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended and not arg_6_0.isShowAnimation_ then
			xyd.WindowManager.get():openWindow("zhuge_recover_energy")
		end
	end)
	arg_6_0:nodeByName("close"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended and not arg_6_0.isShowAnimation_ then
			xyd.WindowManager.get():closeWindow(arg_6_0)
		end
	end)
	arg_6_0:nodeByName("btn_start"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended and not arg_6_0.isShowAnimation_ then
			local var_10_0 = arg_6_0.zhugeModel:getBaseInfo()
			local var_10_1 = var_10_0.skin_least_use_cost
			local var_10_2 = var_10_0.least_use_cost

			if var_10_1 > var_10_0.sweep_energy then
				local var_10_3 = var_0_2:translation("ZHUGE_ADVENTURE_TIPS_19")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_10_3
				})

				return
			end

			local var_10_4 = string.format(var_0_2:translation("ZHUGE_ADVENTURE_TIPS_20"), var_10_1)

			if var_10_1 < var_10_2 then
				var_10_4 = var_10_4 .. "\n" .. var_0_2:translation("ZHUGE_ADVENTURE_TIPS_42")
			end

			local var_10_5 = arg_6_0.selfPlayer:getHeroIgnoreAwaken(10001242)

			if var_10_5 and var_10_5:getStar() == 3 then
				var_10_4 = var_10_4 .. "\n" .. var_0_2:translation("ZHUGE_ADVENTURE_TIPS_43")
			elseif var_10_5 and var_10_5:getStar() == 4 then
				var_10_4 = var_10_4 .. "\n" .. var_0_2:translation("ZHUGE_ADVENTURE_TIPS_44")
			elseif var_10_5 and var_10_5:getStar() == 5 then
				var_10_4 = var_10_4 .. "\n" .. var_0_2:translation("ZHUGE_ADVENTURE_TIPS_45")
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_4, function()
				arg_6_0.isShowAnimation_ = true

				local var_11_0 = {}

				arg_6_0.zhugeModel:sweep(function(arg_12_0, arg_12_1)
					if arg_12_0 == xyd.error.OK then
						arg_6_0.resultAwards = arg_12_1.result_awards

						arg_6_0:updateEnergy()
						arg_6_0:startEvent()
					else
						arg_6_0.isShowAnimation_ = false
					end
				end)
			end, nil, nil, arg_6_0.colorMode)
		end
	end)
	arg_6_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			local var_13_0 = {
				callback = function()
					arg_6_0:updateEnergy()
				end
			}

			xyd.WindowManager.get():openWindow("zhuge_spy", var_13_0)
		end
	end)

	if not arg_6_0.activitiesModel:isActivityOpen(xyd.Activities.END_MONTH) then
		arg_6_0:nodeByName("buy_box_btn"):setVisible(false)
		arg_6_0:nodeByName("btn_add_energy"):setPositionX(200)
		arg_6_0:nodeByName("btn_start"):setPositionX(503)
	end
end

function var_0_0.updateEnergy(arg_15_0)
	local var_15_0 = arg_15_0.zhugeModel:getBaseInfo()

	arg_15_0:nodeByName("text_cur_energy"):setString(var_0_2:translation("ZHUGE_ADVENTURE_TIPS_18"))
	arg_15_0:nodeByName("text_energy_num"):setString(var_15_0.sweep_energy)
	arg_15_0:nodeByName("text_cost"):setString(var_0_2:translation("ZHUGE_ADVENTURE_TIPS_21"))
	arg_15_0:nodeByName("text_cost_num"):setString(var_15_0.skin_least_use_cost)

	if arg_15_0.adventureCount_ == 0 then
		arg_15_0:nodeByName("word_continute"):setVisible(false)
		arg_15_0:nodeByName("word_start"):setVisible(true)
	else
		arg_15_0:nodeByName("word_continute"):setVisible(true)
		arg_15_0:nodeByName("word_start"):setVisible(false)
	end
end

function var_0_0.showBg(arg_16_0, arg_16_1)
	if arg_16_1 then
		arg_16_0:nodeByName("close"):setVisible(true)
		arg_16_0:nodeByName("text_title"):setString(var_0_2:translation("ZHUGE_FOREST_TIPS_40"))
	else
		arg_16_0:nodeByName("close"):setVisible(false)
		arg_16_0:nodeByName("text_title"):setString(var_0_2:translation("ZHUGE_FOREST_TIPS_39"))
	end
end

function var_0_0.initListview(arg_17_0)
	local var_17_0 = arg_17_0:nodeByName("list")
	local var_17_1 = var_17_0:getContentSize().width
	local var_17_2 = var_17_0:getContentSize().height

	arg_17_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_17_1, var_17_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_17_0)
end

function var_0_0.didOpen(arg_18_0, arg_18_1)
	var_0_0.super:didOpen(arg_18_1)
end

function var_0_0.initNewItems(arg_19_0)
	local var_19_0 = arg_19_0.list:newItem()
	local var_19_1 = display.newNode()
	local var_19_2 = arg_19_0:createContent()

	var_19_1:addChild(var_19_2)

	local var_19_3 = var_19_2:getContentSize()

	var_19_0:addContent(var_19_1)
	var_19_1:setContentSize(var_19_3.width, var_19_3.height)
	var_19_0:setItemSize(var_19_3.width, var_19_3.height)
	arg_19_0.list:addItem(var_19_0)
	arg_19_0.list:reload()

	if arg_19_0.recordScrollPos_ then
		local var_19_4 = arg_19_0.itemHeights_[arg_19_0.adventureCount_]

		arg_19_0.list:getScrollNode():setPosition(cc.p(arg_19_0.recordScrollPos_.x, arg_19_0.recordScrollPos_.y - var_19_4))
	end
end

function var_0_0.playAnimation(arg_20_0)
	if not arg_20_0.itemHeights_[arg_20_0.adventureCount_] or not arg_20_0.itemDelays_[arg_20_0.adventureCount_] or not arg_20_0.itemCounts_[arg_20_0.adventureCount_] then
		return
	end

	local var_20_0 = arg_20_0.itemDelays_[arg_20_0.adventureCount_]

	local function var_20_1()
		local var_21_0 = arg_20_0.itemCounts_[arg_20_0.adventureCount_]

		for iter_21_0 = 1, #var_21_0 do
			local var_21_1 = var_21_0[iter_21_0]

			var_0_1.performWithDelayGlobal(handler(arg_20_0, function()
				if not var_21_1 or tolua.isnull(var_21_1) then
					return
				end

				if var_21_1.is_move then
					local var_22_0 = arg_20_0.list:getScrollNode()
					local var_22_1 = var_0_6

					transition.moveTo(var_22_0, {
						x = 0,
						y = var_22_0:getPositionY() + var_22_1,
						time = var_0_9
					})
				else
					var_21_1:setVisible(true)

					if var_21_1.nodeItems then
						for iter_22_0 = 1, #var_21_1.nodeItems do
							local var_22_2 = var_0_1.performWithDelayGlobal(handler(arg_20_0, function()
								if not var_21_1 or tolua.isnull(var_21_1) then
									return
								end

								var_21_1.nodeItems[iter_22_0]:setVisible(true)

								local var_23_0 = transition.sequence({
									cc.ScaleTo:create(var_0_8, 1.2),
									cc.ScaleTo:create(var_0_8, 1)
								})

								var_21_1.nodeItems[iter_22_0]:runAction(var_23_0)
							end), var_0_7 * iter_22_0)
						end
					end
				end

				if iter_21_0 == #var_21_0 then
					arg_20_0.isShowAnimation_ = false
				end
			end), var_20_0[iter_21_0])
		end
	end

	if arg_20_0.adventureCount_ > 1 then
		arg_20_0:scrollToEnd()
		var_0_1.performWithDelayGlobal(handler(arg_20_0, function()
			var_20_1()
		end), var_0_9)
	else
		var_20_1()
	end
end

function var_0_0.scrollToEnd(arg_25_0)
	local var_25_0 = arg_25_0.list:getScrollNode()
	local var_25_1 = 0

	for iter_25_0 = 1, #arg_25_0.itemHeights_ - 1 do
		var_25_1 = var_25_1 + arg_25_0.itemHeights_[iter_25_0]
	end

	local var_25_2 = arg_25_0.list.viewRect_.height - arg_25_0.list.size.height

	transition.moveTo(var_25_0, {
		x = 0,
		y = var_25_2 + var_25_1,
		time = var_0_9
	})
end

function var_0_0.createContent(arg_26_0)
	local var_26_0 = display.newNode()

	if not arg_26_0.awards[arg_26_0.adventureCount_] or not next(arg_26_0.awards[arg_26_0.adventureCount_]) then
		return var_26_0
	end

	local var_26_1 = 0
	local var_26_2 = {}
	local var_26_3 = 0
	local var_26_4 = 0
	local var_26_5 = {}

	local function var_26_6(arg_27_0, arg_27_1)
		table.insert(var_26_5, arg_27_0)

		var_26_3 = var_26_3 + 1

		table.insert(var_26_2, var_26_3)

		if var_26_4 > 300 and not arg_27_1 then
			var_26_3 = var_26_3 + 1

			table.insert(var_26_2, var_26_3)
			table.insert(var_26_5, {
				is_move = true
			})
		end
	end

	local var_26_7 = arg_26_0:createCostLabel()

	var_26_7:addTo(var_26_0)

	var_26_4 = var_26_4 + var_26_7:getContentSize().height

	var_26_6(var_26_7)

	local var_26_8 = arg_26_0:createTitleItem(true)

	var_26_8:addTo(var_26_0)

	var_26_4 = var_26_4 + var_26_8:getContentSize().height

	var_26_6(var_26_8)

	local var_26_9 = arg_26_0.awards[arg_26_0.adventureCount_]
	local var_26_10 = #var_26_9

	if var_26_10 > 0 then
		local var_26_11 = math.ceil(var_26_10 / var_0_5)

		for iter_26_0 = 1, var_26_11 do
			local var_26_12 = arg_26_0:createSweepItem(iter_26_0 - 1, var_26_9)

			var_26_12:addTo(var_26_0)

			var_26_4 = var_26_4 + var_26_12:getContentSize().height

			var_26_6(var_26_12)
		end
	end

	local var_26_13 = arg_26_0:createTitleItem()

	var_26_13:addTo(var_26_0)

	var_26_4 = var_26_4 + var_26_13:getContentSize().height

	var_26_6(var_26_13, true)

	local var_26_14 = 0

	for iter_26_1 = #var_26_5, 1, -1 do
		if not var_26_5[iter_26_1].is_move then
			var_26_5[iter_26_1]:setPosition(cc.p(0, var_26_14))

			var_26_14 = var_26_14 + var_26_5[iter_26_1]:getContentSize().height
		end
	end

	arg_26_0.itemHeights_[arg_26_0.adventureCount_] = var_26_4
	arg_26_0.itemDelays_[arg_26_0.adventureCount_] = var_26_2
	arg_26_0.itemCounts_[arg_26_0.adventureCount_] = var_26_5

	var_26_0:setContentSize(arg_26_0:nodeByName("list"):getContentSize().width, var_26_4)

	return var_26_0
end

function var_0_0.createTitleItem(arg_28_0, arg_28_1)
	local var_28_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/adventure/sweep_item.csb")
	local var_28_1 = var_28_0:getChildByName("container")
	local var_28_2 = var_28_1:getContentSize()

	var_28_0:setContentSize(var_28_2)

	local var_28_3 = ""

	if arg_28_1 then
		var_28_3 = var_0_2:translation("ZHUGE_ADVENTURE_TIPS_22")
	else
		var_28_3 = var_0_2:translation("ZHUGE_ADVENTURE_TIPS_23")
	end

	var_28_1:getChildByName("text_title"):setString(var_28_3)
	var_28_0:setVisible(false)

	return var_28_0
end

function var_0_0.createSweepItem(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = arg_29_1 * var_0_5 + 1
	local var_29_1 = math.min(#arg_29_2, (arg_29_1 + 1) * var_0_5)
	local var_29_2 = 0
	local var_29_3 = display.newNode()

	var_29_3:setVisible(false)

	local var_29_4 = {}

	for iter_29_0 = var_29_0, var_29_1 do
		local var_29_5 = arg_29_2[iter_29_0]

		if var_29_5.table_id then
			local var_29_6 = display.newNode()

			var_29_6:setContentSize(var_0_6, var_0_6)
			var_29_6:setAnchorPoint(cc.p(0.5, 0.5))
			xyd.setItemBorder(var_29_6, tonumber(var_29_5.table_id), false, false, var_29_5.item_num)
			var_29_6:addTo(var_29_3)
			var_29_6:setPosition(var_29_2 * (var_0_6 + 10) + 100, var_0_6 / 2)

			var_29_2 = var_29_2 + 1

			var_29_6:setVisible(false)

			local var_29_7 = {
				id = var_29_5.table_id
			}

			var_29_7.isNotTouchSwallow = true
			var_29_7.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_29_5.table_id)

			xyd.addTips(var_29_6, var_29_7)
			table.insert(var_29_4, var_29_6)
		end
	end

	var_29_3.nodeItems = var_29_4

	var_29_3:setContentSize(arg_29_0:nodeByName("list"):getContentSize().width, var_0_6 + 10)

	return var_29_3
end

function var_0_0.createCostLabel(arg_30_0)
	local var_30_0 = arg_30_0.zhugeModel:getBaseInfo()
	local var_30_1 = var_30_0.sweep_energy
	local var_30_2 = var_30_0.skin_least_use_cost
	local var_30_3 = string.format(var_0_2:translation("ZHUGE_ADVENTURE_TIPS_24"), var_30_1 + var_30_2, var_30_1)
	local var_30_4 = {
		size = 24,
		text = var_30_3,
		align = cc.ui.TEXT_ALIGN_CENTER,
		color = cc.c3b(135, 67, 43),
		dimensions = cc.size(arg_30_0:nodeByName("list"):getContentSize().width, 0)
	}
	local var_30_5 = xyd.AssetLoader.get():loadLabel(var_30_4)

	var_30_5:setVisible(false)

	return var_30_5
end

return var_0_0
