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

function var_0_0.setParams(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = 12
	local var_4_1 = 0

	if arg_4_2 then
		if arg_4_2.exp then
			var_4_0 = arg_4_2.exp
		end

		if arg_4_2.mana then
			var_4_1 = arg_4_2.mana
		end
	end

	local var_4_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_4_3

	if arg_4_1.lev <= 10 then
		var_4_3 = 1
		arg_4_1.exp = arg_4_1.exp + var_4_0

		if xyd.tables.player:totalExp(arg_4_1.lev) <= arg_4_1.exp then
			arg_4_1.lev = arg_4_1.lev + 1
		end
	else
		var_4_3 = var_4_2:getExpMulti()
	end

	local var_4_4 = xyd.getStudentExp(var_4_0, var_4_3)

	arg_4_0:contentView():nodeByName("num_exp"):setString(var_4_4)
	arg_4_0:contentView():nodeByName("num_jinbi"):setString(var_4_1)
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

function var_0_1.setParams(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = 30
	local var_8_1 = xyd.tables.translation
	local var_8_2 = arg_8_0:contentView():nodeByName("name_txt")

	var_8_2:enableOutline(cc.c4b(255, 255, 255, 255), 2)

	if arg_8_2 then
		var_8_2:setString(arg_8_2)
		arg_8_0:contentView():nodeByName("star_1"):setPositionX(var_8_2:getPositionX() - var_8_2:getWidth() / 2 - var_8_0)
		arg_8_0:contentView():nodeByName("star_2"):setPositionX(var_8_2:getPositionX() + var_8_2:getWidth() / 2 + var_8_0)

		return
	end

	if arg_8_1 > 0 then
		var_8_2:setString(string.format(var_8_1:translation("SWEEP_COUNT"), var_8_1:translation("NUM_" .. arg_8_1)))
	else
		var_8_2:setString(var_8_1:translation("SWEEP_ADDITIONAL"))
	end

	arg_8_0:contentView():nodeByName("star_1"):setPositionX(var_8_2:getPositionX() - var_8_2:getWidth() / 2 - var_8_0)
	arg_8_0:contentView():nodeByName("star_2"):setPositionX(var_8_2:getPositionX() + var_8_2:getWidth() / 2 + var_8_0)
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

		if var_12_4.item_id then
			local var_12_5 = cc.Node:create()

			var_12_5:setContentSize(100, 100)
			var_12_5:setAnchorPoint(cc.p(0.5, 0.5))
			xyd.setItemBorder(var_12_5, tonumber(var_12_4.item_id), false, false, var_12_4.item_num)
			arg_12_0:contentView():nodeByName("item_list"):addChild(var_12_5)
			var_12_5:setPosition(var_12_3 * 120 + 65, 60)

			var_12_3 = var_12_3 + 1

			var_12_5:setVisible(false)

			local var_12_6 = {
				id = var_12_4.item_id
			}

			xyd.addTips(var_12_5, var_12_6)
			table.insert(arg_12_0.items, var_12_5)
		end
	end
end

local var_0_3 = class("SweepWindow", import("app.common.ui.BaseWindow"))
local var_0_4 = 5
local var_0_5 = require("framework.scheduler")
local var_0_6 = import("app.common.ui.SpineEffect")
local var_0_7 = 0.12
local var_0_8 = 0.1
local var_0_9 = xyd.tables.translation

function var_0_3.ctor(arg_13_0, arg_13_1, arg_13_2)
	var_0_3.super.ctor(arg_13_0, arg_13_1, arg_13_2)

	arg_13_0.params = arg_13_2
	arg_13_0.itemComposeID = arg_13_2.itemComposeID
	arg_13_0.needItemComposeNum = arg_13_2.needItemComposeNum
	arg_13_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_13_0.campaignType = arg_13_2.campaign_type
	arg_13_0.awakeMissionID = arg_13_2.awake_mission
	arg_13_0.lev = arg_13_0.player.lev
	arg_13_0.exp = arg_13_0.player.exp
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

	for iter_15_0 = 1, #arg_15_0.dropItems do
		local var_15_5 = 0
		local var_15_6 = {}
		local var_15_7 = arg_15_0:createTitleItem(iter_15_0)

		arg_15_0.listView_:addItem(var_15_7)

		local var_15_8 = var_15_5 + var_15_7:getContentSize().height

		var_15_2 = var_15_2 + 1

		table.insert(var_15_6, var_15_2)

		local var_15_9 = arg_15_0:createEconomyItem(iter_15_0)

		arg_15_0.listView_:addItem(var_15_9)

		var_15_2 = var_15_2 + 1

		table.insert(var_15_6, var_15_2)

		local var_15_10 = var_15_8 + var_15_9:getContentSize().height
		local var_15_11 = arg_15_0.dropItems[iter_15_0]
		local var_15_12 = #var_15_11

		if var_15_12 == 0 then
			local var_15_13 = arg_15_0:createSweepItem(0, var_15_11)

			arg_15_0.listView_:addItem(var_15_13)

			var_15_10 = var_15_10 + var_15_13:getContentSize().height
			var_15_2 = var_15_2 + 1

			table.insert(var_15_6, var_15_2)
		else
			local var_15_14 = math.ceil(var_15_12 / var_0_4)

			for iter_15_1 = 1, var_15_14 do
				local var_15_15 = arg_15_0:createSweepItem(iter_15_1 - 1, var_15_11)

				arg_15_0.listView_:addItem(var_15_15)

				var_15_10 = var_15_10 + var_15_15:getContentSize().height
				var_15_2 = var_15_2 + 1

				table.insert(var_15_6, var_15_2)
			end
		end

		table.insert(var_15_0, var_15_10)
		table.insert(var_15_1, var_15_6)

		var_15_4 = var_15_4 + math.max(var_0_7 * var_15_12 + 0.5, 1)

		table.insert(var_15_3, var_15_4)
	end

	local var_15_16 = arg_15_0:createEffectItem()

	arg_15_0.listView_:addItem(var_15_16)
	table.insert(var_15_0, 200)

	local var_15_17 = var_15_2 + 1

	table.insert(var_15_1, {
		var_15_17
	})

	local var_15_18 = var_15_4 + 1

	table.insert(var_15_3, var_15_18)

	local var_15_19 = arg_15_0.additionalItems

	if var_15_19 and #var_15_19 > 0 then
		local var_15_20 = {}
		local var_15_21 = 0
		local var_15_22 = arg_15_0:createTitleItem(0)

		arg_15_0.listView_:addItem(var_15_22)

		local var_15_23 = var_15_21 + var_15_22:getContentSize().height

		var_15_17 = var_15_17 + 1

		table.insert(var_15_20, var_15_17)

		local var_15_24 = math.ceil(#var_15_19 / var_0_4)

		for iter_15_2 = 1, var_15_24 do
			local var_15_25 = arg_15_0:createSweepItem(0, var_15_19)

			arg_15_0.listView_:addItem(var_15_25)

			var_15_23 = var_15_23 + var_15_25:getContentSize().height
			var_15_17 = var_15_17 + 1

			table.insert(var_15_20, var_15_17)
		end

		table.insert(var_15_1, var_15_20)
		table.insert(var_15_0, var_15_23)
	end

	if arg_15_0.params and arg_15_0.params.tipMessage then
		local var_15_26 = {}
		local var_15_27 = 0
		local var_15_28 = arg_15_0:createTitleItem(0, arg_15_0.params.tipMessage)

		arg_15_0.listView_:addItem(var_15_28)

		local var_15_29 = var_15_27 + var_15_28:getContentSize().height
		local var_15_30 = var_15_17 + 1

		table.insert(var_15_26, var_15_30)
		table.insert(var_15_1, var_15_26)
		table.insert(var_15_0, var_15_29)
	end

	arg_15_0.listView_:reload()

	for iter_15_3 = 1, #arg_15_0.listView_.items_ do
		arg_15_0.listView_.items_[iter_15_3]:setVisible(false)
	end

	arg_15_0.schedulerHanderList = {}

	local var_15_31 = arg_15_0:nodeByName("list"):getHeight()
	local var_15_32 = 0
	local var_15_33 = 0
	local var_15_34 = 0

	for iter_15_4 = 1, #var_15_0 do
		var_15_34 = var_15_34 + var_15_0[iter_15_4]

		if var_15_31 <= var_15_34 then
			var_15_32 = iter_15_4
			var_15_33 = var_15_34 - var_15_31

			break
		end
	end

	local var_15_35 = 0

	for iter_15_5 = 1, #var_15_0 do
		var_15_35 = var_15_35 + var_15_0[iter_15_5]

		if var_15_31 <= var_15_35 then
			local var_15_36 = var_0_5.performWithDelayGlobal(handler(arg_15_0, function()
				local var_16_0 = var_15_1[iter_15_5]

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

				if iter_15_5 == var_15_32 then
					transition.moveBy(arg_15_0.listView_.container, {
						time = 0.2,
						x = 0,
						y = var_15_33
					})
				else
					transition.moveBy(arg_15_0.listView_.container, {
						time = 0.2,
						x = 0,
						y = var_15_0[iter_15_5]
					})
				end
			end), var_15_3[iter_15_5])

			table.insert(arg_15_0.schedulerHanderList, var_15_36)
		else
			local var_15_37 = var_0_5.performWithDelayGlobal(handler(arg_15_0, function()
				local var_19_0 = var_15_1[iter_15_5]

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
			end), var_15_3[iter_15_5])

			table.insert(arg_15_0.schedulerHanderList, var_15_37)
		end
	end
end

function var_0_3.createTitleItem(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = arg_22_0.listView_:newItem()
	local var_22_1 = display.newNode()
	local var_22_2 = var_0_1.new()

	var_22_2:setParams(arg_22_1, arg_22_2)
	var_22_1:addChild(var_22_2)

	local var_22_3 = var_22_2:contentView():nodeByName("title_bg"):getContentSize()
	local var_22_4 = 20

	var_22_0:addContent(var_22_1)
	var_22_1:setContentSize(var_22_3.width, var_22_3.height)

	if arg_22_1 > 0 then
		var_22_0:setItemSize(var_22_3.width, var_22_3.height)
	else
		var_22_2:setPositionY(var_22_4 / 2)
		var_22_0:setItemSize(var_22_3.width, var_22_3.height + var_22_4)
	end

	return var_22_0
end

function var_0_3.createEconomyItem(arg_23_0, arg_23_1)
	local var_23_0 = arg_23_0.listView_:newItem()
	local var_23_1 = display.newNode()
	local var_23_2 = var_0_0.new()

	if arg_23_0.economys == nil then
		var_23_2:setParams(arg_23_0)
	else
		var_23_2:setParams(arg_23_0, arg_23_0.economys[arg_23_1])
	end

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

	local var_24_4 = 40

	var_24_2:setPositionY(var_24_4 / 2)
	var_24_0:setItemSize(var_24_3.width, var_24_3.height + var_24_4)

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

	var_25_5:setPosition(350, 120)
	var_25_1:addChild(var_25_5)
	var_25_5:play(nil, false)
	var_25_0:addContent(var_25_1)
	var_25_1:setContentSize(700, 200)
	var_25_0:setItemSize(700, 200)

	var_25_0.effect = var_25_5

	return var_25_0
end

function var_0_3.willOpen(arg_26_0, arg_26_1)
	arg_26_0:nodeByName("txt_title"):setString(var_0_9:translation("SWEEP"))
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

	local var_26_0 = xyd.mid.SWEEP_CAMPAIGN
	local var_26_1 = arg_26_0.params

	if arg_26_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN then
		var_26_0 = xyd.mid.SWEEP_SAKURA
		var_26_1 = {}
	elseif arg_26_0.campaignType == xyd.CampaignType.CHOCOLATE then
		var_26_0 = xyd.mid.CHOCOLATE_SWEEP
		var_26_1 = {
			campaign_id = arg_26_0.params.campaign_id,
			sweep_num = arg_26_0.params.sweep_num
		}
	elseif arg_26_0.campaignType == xyd.CampaignType.FOURTH_ANNI_MAP then
		var_26_0 = xyd.mid.FOURTH_ANNI_MAP_SWEEP
		var_26_1 = {
			campaign_id = arg_26_0.params.campaign_id,
			sweep_num = arg_26_0.params.sweep_num
		}
	elseif arg_26_0.campaignType == xyd.CampaignType.ALL_NIGHT_MAP then
		var_26_0 = xyd.mid.POLAR_NIGHT_SWEEP
		var_26_1 = {
			campaign_id = arg_26_0.params.campaign_id,
			sweep_num = arg_26_0.params.sweep_num
		}
	end

	if arg_26_0.awakeMissionID then
		var_26_1.awake_mission = arg_26_0.awakeMissionID
	end

	local var_26_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).exp

	xyd.Backend.get():request(var_26_0, var_26_1, function(arg_27_0, arg_27_1)
		if arg_27_0 == xyd.error.OK then
			arg_26_0.isHasStone = false

			if arg_26_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN then
				arg_26_0.dropItems = {}
				arg_26_0.dropItems[1] = arg_27_1.items
				arg_26_0.economys = arg_27_1.economys
			elseif arg_26_0.campaignType == xyd.CampaignType.FOURTH_ANNI_MAP then
				arg_26_0.dropItems = {}
				arg_26_0.economys = {}

				for iter_27_0, iter_27_1 in ipairs(arg_27_1.award_infos) do
					local var_27_0 = {}
					local var_27_1 = {}

					for iter_27_2 = 1, #iter_27_1 do
						if iter_27_1[iter_27_2].table_id == -1 then
							if arg_27_1.economy_.exp then
								var_27_1 = {
									exp = (arg_27_1.economy_.exp - var_26_2) / #arg_27_1.award_infos / 3,
									mana = iter_27_1[iter_27_2].mana
								}
							else
								var_27_1 = {
									exp = 0,
									mana = iter_27_1[iter_27_2].mana
								}
							end
						else
							local var_27_2 = {
								item_id = iter_27_1[iter_27_2].table_id,
								item_num = iter_27_1[iter_27_2].item_num
							}

							table.insert(var_27_0, var_27_2)
						end
					end

					table.insert(arg_26_0.economys, var_27_1)
					table.insert(arg_26_0.dropItems, var_27_0)
				end
			else
				arg_26_0.dropItems = arg_27_1.items
				arg_26_0.economys = arg_27_1.economys
			end

			arg_26_0.additionalItems = arg_27_1.additional
			arg_26_0.campaign = arg_27_1.campaign

			local var_27_3 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

			var_27_3:handleChapterEvent(arg_27_1)

			if arg_26_1.sweep_type == xyd.SweepType.ITEM_SWEEP then
				local var_27_4 = {}

				var_27_4.itemID = 50001013
				var_27_4.itemNum = arg_26_1.sweep_num

				if arg_26_0.campaignType == xyd.CampaignType.CHOCOLATE then
					var_27_4.itemID = xyd.tables.misc.activityChocolateCampaignSweepItem
				end

				var_27_3:getBackpack():removeItem(var_27_4)

				if not xyd.WindowManager.get():getWindow("map_detail_window") then
					local var_27_5 = xyd.WindowManager.get():getWindow("new_map_detail_window")
				end

				if mapDetialWindow then
					mapDetialWindow:updateLayout()
				end
			end

			if arg_26_0.campaignType ~= xyd.CampaignType.PROPHESY_JIUWEI and arg_26_0.campaignType ~= xyd.CampaignType.PROPHESY_NIAN and arg_26_0.campaignType ~= xyd.CampaignType.PROPHESY_QIUBITE and arg_26_0.campaignType ~= xyd.CampaignType.PROPHESY_YUAN and arg_26_0.campaignType ~= xyd.CampaignType.PROPHESY_SINGLE_DOG and arg_26_0.campaignType ~= xyd.CampaignType.PROPHESY_SONGZHONGJI and arg_26_0.campaignType ~= xyd.CampaignType.SAKURA_CAMPAIGN and arg_26_0.campaignType ~= xyd.CampaignType.PROPHESY_SONGZHONGJI and arg_26_0.campaignType ~= xyd.CampaignType.CHOCOLATE and arg_26_0.campaignType ~= xyd.CampaignType.FOURTH_ANNI_MAP and arg_26_0.campaignType ~= xyd.CampaignType.ALL_NIGHT_MAP then
				local var_27_6 = arg_26_0.campaign.campaign_id

				var_27_3.worldMaps_[var_27_6].dailyLimit = tonumber(arg_26_0.campaign.daily_limit)
				var_27_3.worldMaps_[var_27_6].resetCount = tonumber(arg_26_0.campaign.reset_count)
			else
				local var_27_7 = xyd.WindowManager.get():getWindow("preperation_battle_prepare")

				if var_27_7 then
					var_27_7.dailyLimit = var_27_7.dailyLimit - 1
					var_27_7.hasItemNum = var_27_7.player_:getBackpack():getItemNumByID(50001013)

					var_27_7:nodeByName("txt_sweep_num"):setString(var_27_7.hasItemNum)
				end

				local var_27_8 = xyd.WindowManager.get():getWindow("difficultchoice")

				if var_27_8 then
					var_27_8.leftTimes = var_27_8.leftTimes - 1

					var_27_8:nodeByName("txt_left_times"):setString(var_0_9:translation("MAP_LEFT_TIMES") .. var_27_8.leftTimes)
				end
			end

			for iter_27_3 = 1, #arg_26_0.dropItems do
				local var_27_9 = arg_26_0.dropItems[iter_27_3]

				for iter_27_4 = 1, #var_27_9 do
					local var_27_10 = {
						itemID = var_27_9[iter_27_4].item_id,
						itemNum = var_27_9[iter_27_4].item_num
					}

					var_27_3:getBackpack():addItem(var_27_10)

					if var_27_10.itemID == arg_26_0.itemComposeID then
						arg_26_0.isHasStone = true
					end
				end
			end

			if arg_26_0.needItemComposeNum and arg_26_0.needItemComposeNum > 0 and arg_26_0.isHasStone then
				arg_26_0:playFloatText()
			end

			local var_27_11 = xyd.WindowManager.get():getWindow("map_detail_window") or xyd.WindowManager.get():getWindow("new_map_detail_window")

			if var_27_11 then
				if arg_27_1.trial ~= nil then
					var_27_11.params.dailyLimit = tonumber(arg_27_1.trial.left_times)
				elseif arg_26_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN then
					var_27_11.params.dailyLimit = var_27_11.params.dailyLimit - arg_26_1.sweep_num
				else
					var_27_11.params.dailyLimit = tonumber(arg_26_0.campaign.daily_limit)
				end

				if arg_26_0.campaign then
					var_27_11.params.resetCount = tonumber(arg_26_0.campaign.reset_count)
				end

				var_27_11:updateLayout()
			end

			if arg_27_1.trial ~= nil then
				local var_27_12 = arg_27_1.trial
				local var_27_13 = tonumber(var_27_12.id)

				if var_27_13 then
					var_27_3.trialInfos_[var_27_13] = {}
					var_27_3.trialInfos_[var_27_13].id = tonumber(var_27_12.id)
					var_27_3.trialInfos_[var_27_13].leftTimes = tonumber(var_27_12.left_times)
					var_27_3.trialInfos_[var_27_13].isOpen = tonumber(var_27_12.is_open)
					var_27_3.trialInfos_[var_27_13].maxTimes = tonumber(var_27_12.max_times)
					var_27_3.trialInfos_[var_27_13].lastID = tonumber(var_27_12.last_id)
				end
			end

			if arg_27_1.challenge ~= nil then
				local var_27_14 = arg_27_1.challenge
				local var_27_15 = tonumber(var_27_14.id)

				if var_27_15 then
					var_27_3.challengeInfos_[var_27_15] = {}
					var_27_3.challengeInfos_[var_27_15].id = tonumber(var_27_14.id)
					var_27_3.challengeInfos_[var_27_15].leftTimes = tonumber(var_27_14.left_times)
					var_27_3.challengeInfos_[var_27_15].isOpen = tonumber(var_27_14.is_open)
					var_27_3.challengeInfos_[var_27_15].maxTimes = tonumber(var_27_14.max_times)
					var_27_3.challengeInfos_[var_27_15].lastID = tonumber(var_27_14.last_id)
				end
			end

			local var_27_16 = xyd.WindowManager.get():getWindow("map_window")

			if var_27_16 then
				var_27_16:updateChapter()
			end

			if arg_26_0.additionalItems then
				for iter_27_5 = 1, #arg_26_0.additionalItems do
					local var_27_17 = {
						itemID = arg_26_0.additionalItems[iter_27_5].item_id,
						itemNum = arg_26_0.additionalItems[iter_27_5].item_num
					}

					var_27_3:getBackpack():addItem(var_27_17)
				end
			end

			if not arg_26_0 or tolua.isnull(arg_26_0) then
				return
			end

			arg_26_0:updateItems()
		end
	end)
end

function var_0_3.playFloatText(arg_28_0)
	local var_28_0 = arg_28_0:nodeByName("list")
	local var_28_1 = {
		color = cc.c3b(108, 253, 19)
	}

	var_28_1.size = 28

	local var_28_2 = xyd.AssetLoader.get():loadLabel(var_28_1)

	var_28_2:addTo(var_28_0)
	var_28_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_28_2:setPosition(var_28_0:getContentSize().width / 2, var_28_0:getContentSize().height / 2)
	var_28_2:setLocalZOrder(100)

	local var_28_3 = string.format(var_0_9:translation("SWEEP_FLOAT_TXT"), xyd.tables.item:name(arg_28_0.itemComposeID), arg_28_0.player:getBackpack():getItemNumByID(arg_28_0.itemComposeID), arg_28_0.needItemComposeNum)

	var_28_2:setString(var_28_3)
	var_28_2:enableOutline(cc.c4b(0, 0, 0, 255), 1)

	local var_28_4 = cc.MoveTo:create(1.5, cc.p(var_28_2:getPositionX(), var_28_2:getPositionY() + 70))
	local var_28_5 = cc.FadeOut:create(2)

	var_28_2:runAction(cc.Sequence:create(cc.Spawn:create(var_28_4, var_28_5), cc.CallFunc:create(function()
		var_28_2:setVisible(false)
		var_28_2:removeSelf()
	end)))
end

function var_0_3.didOpen(arg_30_0)
	arg_30_0:addBlockLayer()
end

function var_0_3.willClose(arg_31_0)
	if arg_31_0.schedulerHanderList then
		for iter_31_0, iter_31_1 in pairs(arg_31_0.schedulerHanderList) do
			if iter_31_1 then
				var_0_5.unscheduleGlobal(iter_31_1)
			end
		end
	end

	collectgarbage("collect")
	arg_31_0.listView_:removeAllItems()
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.HERO_EQUIP_UPDATE
	})
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAP_DETAIL_UPDATE
	})

	if arg_31_0.itemComposeID then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.UPDATE_STONE_EQUIP_CAMPAIGN,
			params = {
				itemComposeID = arg_31_0.itemComposeID
			}
		})
	end

	if xyd.WindowManager.get():getWindow("activities") then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.UPDATE_POINT_WAY
		})
	end

	if xyd.WindowManager.get():getWindow("hero_list") and arg_31_0.isHasStone then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.UPDATE_HERO_COLLECT_STONE,
			itemComposeID = arg_31_0.itemComposeID
		})
	end
end

return var_0_3
