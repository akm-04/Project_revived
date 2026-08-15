local var_0_0 = class("GardenPlantWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = 4
local var_0_4 = xyd.tables.activityGardenFlower

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.garden = xyd.ModelManager.get():loadModel(xyd.ModelType.GARDEN)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.listItems = arg_1_0.garden:getCanPlantFlower()
	arg_1_0.landId = arg_1_2.land_id
	arg_1_0.currentItem = arg_1_0.listItems[1]
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.scroll = arg_4_0:nodeByName("scroll")

	local var_4_0 = arg_4_0.scroll:getContentSize()

	arg_4_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 20, var_4_0.width, var_4_0.height - 20),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.scrollList:setBounceable(false)
	arg_4_0.scrollList:setDelegate(handler(arg_4_0, arg_4_0.scrollListDelegate))
	arg_4_0.scrollList:setTouchType(false)
	arg_4_0.scrollList:reload()
	arg_4_0:setButtonClick()
	arg_4_0:updateDetail()
end

function var_0_0.updateDetail(arg_5_0)
	arg_5_0:nodeByName("select_text"):setString(string.format(var_0_1:translation("GARDEN_PLANT_SELECT_TEXT"), arg_5_0.landId))
	arg_5_0:nodeByName("text1"):setString(var_0_1:translation("GARDEN_TIP_TEXT1"))
	arg_5_0:nodeByName("name_txt"):setString(var_0_4:name(arg_5_0.currentItem))
	arg_5_0:nodeByName("desc_txt1"):setString(var_0_1:translation(""))

	local var_5_0 = {
		1,
		2,
		3
	}
	local var_5_1 = arg_5_0.garden:getFlowerInfos(arg_5_0.currentItem).txts

	for iter_5_0, iter_5_1 in pairs(var_5_0) do
		arg_5_0:nodeByName("text" .. iter_5_1):setString(var_0_1:translation("GARDEN_TIP_TEXT" .. iter_5_1))
		arg_5_0:nodeByName("desc_txt" .. iter_5_1):setString(var_5_1[iter_5_1])
	end

	local var_5_2 = var_0_4:icon(arg_5_0.currentItem)

	xyd.setSpriteBorder(arg_5_0:nodeByName("icon_container"), var_5_2, 5)
end

function var_0_0.setButtonClick(arg_6_0)
	arg_6_0:nodeByName("plant_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_7_0 = {
				seed_id = arg_6_0.currentItem,
				field_id = arg_6_0.landId
			}

			arg_6_0.garden:gardenSeeding(var_7_0, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					local var_8_0 = {
						itemID = var_0_4:seedId(arg_6_0.currentItem)
					}

					var_8_0.itemNum = 1

					arg_6_0.backpack:removeItem(var_8_0)
					xyd.WindowManager.get():closeWindow(arg_6_0)
				end
			end)
		end
	end)

	local function var_6_0()
		local var_9_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack()
		local var_9_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.GARDEN)
		local var_9_2 = var_9_1.details.field_info
		local var_9_3 = var_9_1:getCanPlantFlower()
		local var_9_4 = 0
		local var_9_5 = {}

		for iter_9_0, iter_9_1 in ipairs(var_9_2) do
			if iter_9_1.seed_id == 0 then
				var_9_4 = var_9_4 + 1

				local var_9_6 = var_9_4

				for iter_9_2, iter_9_3 in ipairs(var_9_3) do
					local var_9_7 = var_0_4:seedId(iter_9_3)
					local var_9_8 = var_9_0:getItemNumByID(var_9_7) or 0

					if var_9_6 <= var_9_8 then
						table.insert(var_9_5, {
							seed_id = iter_9_3,
							field_id = iter_9_0
						})

						break
					else
						var_9_6 = var_9_6 - var_9_8
					end
				end
			end
		end

		local function var_9_9(arg_10_0)
			if arg_10_0 > #var_9_5 then
				return
			end

			local var_10_0 = var_9_5[arg_10_0]

			var_9_1:gardenSeeding(var_10_0, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					local var_11_0 = {
						itemID = var_0_4:seedId(var_10_0.seed_id)
					}

					var_11_0.itemNum = 1

					var_9_0:removeItem(var_11_0)
				end

				var_9_9(arg_10_0 + 1)
			end)
		end

		var_9_9(1)
	end

	arg_6_0:nodeByName("onekey_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ACT_FARM_ONEKEY_SEEDING_CONFIRM"), function()
				var_6_0()
				xyd.WindowManager.get():closeWindow(arg_6_0)
			end, nil, nil, arg_6_0.colorMode)
		end
	end)
end

function var_0_0.scrollListDelegate(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	if cc.ui.UIListView.COUNT_TAG == arg_14_2 then
		return math.ceil(#arg_14_0.listItems / var_0_3)
	elseif cc.ui.UIListView.CELL_TAG == arg_14_2 then
		local var_14_0
		local var_14_1 = arg_14_0.scrollList:dequeueItem()

		if not var_14_1 then
			var_14_1 = arg_14_0.scrollList:newItem()
		else
			var_14_1:removeAllChildren(true)
		end

		local var_14_2 = arg_14_0:createListContent(arg_14_3)
		local var_14_3 = var_14_2:getWidth()
		local var_14_4 = var_14_2:getHeight()

		var_14_1:setItemSize(var_14_3, var_14_4)
		var_14_1:addContent(var_14_2)

		return var_14_1
	end
end

function var_0_0.createListContent(arg_15_0, arg_15_1)
	local var_15_0 = display.newNode()
	local var_15_1 = 70
	local var_15_2 = 10
	local var_15_3 = 130

	var_15_0:setContentSize(546, 120)

	for iter_15_0 = 1, var_0_3 do
		if (arg_15_1 - 1) * var_0_3 + iter_15_0 <= #arg_15_0.listItems then
			local var_15_4 = (arg_15_1 - 1) * var_0_3 + iter_15_0
			local var_15_5 = var_0_4:seedId(arg_15_0.listItems[var_15_4])
			local var_15_6 = arg_15_0.backpack:getItemNumByID(var_15_5)
			local var_15_7 = display.newNode()

			var_15_7:setContentSize(100, 100)
			var_15_7:setAnchorPoint(cc.p(0.5, 0))
			xyd.setItemBorder(var_15_7, var_15_5, nil, nil, var_15_6, nil, true)
			var_15_7:addTo(var_15_0)
			var_15_7:setPosition(cc.p(var_15_1, var_15_2))

			var_15_1 = var_15_1 + var_15_3

			if arg_15_0.currentItem and arg_15_0.currentItem == arg_15_0.listItems[var_15_4] then
				arg_15_0:addSelectEffectForItem(var_15_7)
			end

			var_15_7:setTouchEnabled(true)
			var_15_7:setTouchSwallowEnabled(false)
			var_15_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
				if arg_16_0.name == "began" and arg_15_0.scrollViewMoved_ ~= true then
					var_15_7:setScale(0.9)

					return true
				elseif arg_16_0.name == "ended" then
					var_15_7:setScale(1)

					if arg_15_0.currentItem ~= arg_15_0.listItems[var_15_4] then
						arg_15_0.currentItem = arg_15_0.listItems[var_15_4]
						arg_15_0.currentNode = var_15_7

						arg_15_0:addSelectEffectForItem(var_15_7)
						arg_15_0:updateDetail()
					end
				end
			end)
		end
	end

	return var_15_0
end

function var_0_0.addSelectEffectForItem(arg_17_0, arg_17_1)
	if not tolua.isnull(arg_17_0.effect) and arg_17_0.effect then
		arg_17_0.effect:removeSelf()

		arg_17_0.effect = nil
	end

	local var_17_0 = "skeletons/ui_effect/event_centre_select/event_centre_select_eff" .. ".json"
	local var_17_1 = "skeletons/ui_effect/event_centre_select/event_centre_select_eff" .. ".atlas"

	arg_17_0.effect = var_0_2.new(var_17_0, var_17_1, 1)

	arg_17_0.effect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_17_0.effect:addTo(arg_17_1)
	arg_17_0.effect:setPosition(cc.p(arg_17_1:getContentSize().width / 2, arg_17_1:getContentSize().height / 2))
	arg_17_0.effect:setName("effect")
	arg_17_0.effect:play(nil, true)
end

function var_0_0.scrollListener(arg_18_0, arg_18_1)
	if arg_18_1.name == "began" then
		arg_18_0.scrollViewMoved_ = false
		arg_18_0.prevY_ = arg_18_1.y
	elseif arg_18_1.name == "moved" and 5 <= math.abs(arg_18_1.y - arg_18_0.prevY_) then
		arg_18_0.scrollViewMoved_ = true
	end
end

return var_0_0
