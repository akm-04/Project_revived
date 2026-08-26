local var_0_0 = class("SelectEquipWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.attr
local var_0_3 = xyd.tables.elementEquip
local var_0_4 = import("framework.scheduler")
local var_0_5 = 5
local var_0_6 = 20
local var_0_7 = 20
local var_0_8 = 1.04
local var_0_9 = 0.008333333333333333
local var_0_10 = 0.03333333333333333

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.itemID = arg_1_2.itemID
	arg_1_0.num = arg_1_2.num or 1
	arg_1_0.add = true
	arg_1_0.scale = 1
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack_ = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.shop_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:initButton()
	arg_3_0:nodeByName("txt_tips"):setString(var_0_1:translation("SELECT_EQUIP_TIPS"))

	arg_3_0.itemList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_3_0:nodeByName("list"):getWidth(), arg_3_0:nodeByName("list"):getHeight()),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.itemList:setTouchSwallowEnabled(false)
	arg_3_0.itemList:setDelegate(handler(arg_3_0, arg_3_0.delegate))

	arg_3_0.scrollx = 0

	arg_3_0.itemList:reload()
end

function var_0_0.initButton(arg_4_0)
	arg_4_0:nodeByName("txt_btn_ok"):setString(var_0_1:translation("SELECT_EQUIP_OK"))
	arg_4_0:nodeByName("btn_ok"):setVisible(false)
	arg_4_0:nodeByName("btn_ok"):setTouchSwallowEnabled(false)
	arg_4_0:nodeByName("btn_ok"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("btn_ok"), arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_4_0.giftId then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ITEM_SELECT_TEXT"), function()
					local var_6_0 = {
						item_id = arg_4_0.itemID,
						gift_id = arg_4_0.giftId,
						num = arg_4_0.num
					}

					xyd.Backend.get():request(xyd.mid.EXCHAGE_CODE_HERO, var_6_0, function(arg_7_0, arg_7_1)
						if arg_7_0 == xyd.error.OK then
							local var_7_0 = {
								itemID = var_6_0.item_id,
								itemNum = arg_4_0.num
							}

							arg_4_0.selfPlayer:getBackpack():removeItem(var_7_0)
							arg_4_0.selfPlayer:handleRewards(arg_7_1.awards)

							local var_7_1 = xyd.WindowManager.get():getWindow("backpack")

							if var_7_1 and not tolua.isnull(var_7_1) then
								var_7_1:updateItemDetail(var_6_0.item_id)
								var_7_1:refreshDisplayOption()
							end

							local var_7_2 = xyd.WindowManager.get():getWindow("equipment_backpack")

							if var_7_2 and not tolua.isnull(var_7_2) then
								var_7_2:updateItemDetail(var_6_0.item_id)
								var_7_2:refreshDisplayOption()
							end

							xyd.WindowManager.get():closeWindow(arg_4_0)
						end
					end)
				end, nil, nil, arg_4_0.colorMode)
			end
		end
	end)
	arg_4_0:nodeByName("btn_close"):setTouchSwallowEnabled(false)
	arg_4_0:nodeByName("btn_close"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("btn_close"), arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevY_ = arg_9_1.y
	elseif arg_9_1.name == "moved" then
		arg_9_0.scrolly = arg_9_0.itemList:getScrollNode():getPositionY()

		if 20 <= math.abs(arg_9_1.y - arg_9_0.prevY_) then
			arg_9_0.scrollViewMoved_ = true
		end

		if arg_9_0.scrollViewMoved_ == true and not tolua.isnull(arg_9_0.selectItemCell) and arg_9_0.backpackHandle == nil then
			arg_9_0.backpackHandle = var_0_4.scheduleGlobal(function()
				arg_9_0:updateScale()

				if arg_9_0.giftId then
					arg_9_0:nodeByName("btn_ok"):setVisible(true)
				else
					arg_9_0:nodeByName("btn_ok"):setVisible(false)
				end
			end, var_0_10)
		end
	elseif arg_9_1.name == "scrollEnd" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.scrolly = arg_9_0.itemList:getScrollNode():getPositionY()
	end
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	var_0_0.super:didOpen(arg_11_1)
	arg_11_0:addBlockLayer()
end

function var_0_0.delegate(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = #xyd.tables.item:gifts(arg_12_0.itemID)

	if cc.ui.UIListView.COUNT_TAG == arg_12_2 then
		return math.ceil(var_12_0 / var_0_5)
	elseif cc.ui.UIListView.CELL_TAG == arg_12_2 then
		local var_12_1
		local var_12_2 = display.newNode()
		local var_12_3 = arg_12_0.itemList:dequeueItem()

		if not var_12_3 then
			var_12_3 = arg_12_0.itemList:newItem()
		else
			var_12_3:removeAllChildren()
		end

		local var_12_4 = xyd.tables.item:gifts(arg_12_0.itemID)

		for iter_12_0 = var_0_5 - 1, 0, -1 do
			if arg_12_3 * var_0_5 - iter_12_0 <= #var_12_4 and arg_12_3 * var_0_5 - iter_12_0 > 0 then
				local var_12_5 = xyd.tables.gift:items(var_12_4[arg_12_3 * var_0_5 - iter_12_0])[1]
				local var_12_6 = xyd.tables.item:gifts(arg_12_0.itemID)[arg_12_3 * var_0_5 - iter_12_0]
				local var_12_7 = display.newNode()

				arg_12_0:initCell(var_12_7, var_12_5, var_12_6)
				var_12_7:setAnchorPoint(cc.p(0.5, 0.5))
				var_12_2:addChild(var_12_7)

				local var_12_8 = var_12_7:getContentSize().width
				local var_12_9 = var_12_7:getContentSize().height

				var_12_7:pos((var_12_8 + var_0_6) * (var_0_5 - iter_12_0 - 1) + var_12_8 / 2, var_12_9 / 2)
				var_12_7:setName("cell")
				var_12_2:size(arg_12_0:nodeByName("list"):getContentSize().width, var_12_7:getHeight())

				if not tolua.isnull(arg_12_0.selectItemCell) and arg_12_0.backpackHandle == nil then
					arg_12_0.backpackHandle = var_0_4.scheduleGlobal(function()
						arg_12_0:updateScale()

						if arg_12_0.giftId then
							arg_12_0:nodeByName("btn_ok"):setVisible(true)
						else
							arg_12_0:nodeByName("btn_ok"):setVisible(false)
						end
					end, var_0_10)
				end
			end
		end

		var_12_3:setItemSize(var_12_2:getWidth(), var_12_2:getHeight() + var_0_7)
		var_12_3:addContent(var_12_2)

		return var_12_3
	end
end

function var_0_0.initCell(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	local var_14_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/select_equip_window/select_item.csb")
	local var_14_1 = var_14_0:getChildByName("container")
	local var_14_2 = var_14_1:getContentSize()

	var_14_1:setContentSize(var_14_2.width, var_14_2.height)
	var_14_1:getChildByName("bg"):setVisible(true)
	arg_14_1:setContentSize(var_14_2.width, var_14_2.height)
	var_14_0:setPosition(cc.p(0, 0))
	arg_14_1:addChild(var_14_0)
	var_14_0:setName("layout")

	local var_14_3 = var_14_1:getChildByName("txt_item_name")
	local var_14_4 = xyd.tables.item:name(arg_14_2)

	var_14_3:setString(var_14_4)

	local var_14_5 = var_14_1:getChildByName("item_icon")

	xyd.setItemAndAddTips(var_14_5, arg_14_2)
	arg_14_1:setTouchEnabled(true)
	arg_14_1:setTouchSwallowEnabled(false)
	arg_14_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
		if arg_15_0.name == "began" then
			arg_14_1:setScale(0.9)

			return true
		elseif arg_15_0.name == "ended" then
			arg_14_1:setScale(1)
			xyd.playButtonSound()

			if not arg_14_0.scrollViewMoved_ then
				arg_14_0.giftId = arg_14_3

				arg_14_0:addClickEffects(arg_14_1)
			end
		end
	end)

	if arg_14_0.giftId and arg_14_0.giftId == arg_14_3 then
		arg_14_0:addClickEffects(arg_14_1)
	end
end

function var_0_0.addClickEffects(arg_16_0, arg_16_1)
	if arg_16_0.selectItemCell and not tolua.isnull(arg_16_0.selectItemCell) then
		arg_16_0.selectItemCell:removeChild(arg_16_0.bg, true)
	end

	arg_16_0.selectItemCell = arg_16_1

	local var_16_0 = "windows/select_equip_window/bg_click_on.png"
	local var_16_1 = xyd.AssetLoader:get():loadSprite(var_16_0)

	arg_16_1:addChild(var_16_1)

	local var_16_2 = arg_16_1:getContentSize().width
	local var_16_3 = arg_16_1:getContentSize().height

	var_16_1:setPosition(var_16_2 / 2, var_16_3 / 2)
	var_16_1:setAnchorPoint(cc.p(0.5, 0.5))

	arg_16_0.bg = var_16_1

	if not tolua.isnull(arg_16_0.selectItemCell) and arg_16_0.backpackHandle == nil then
		arg_16_0.backpackHandle = var_0_4.scheduleGlobal(function()
			arg_16_0:updateScale()

			if arg_16_0.giftId then
				arg_16_0:nodeByName("btn_ok"):setVisible(true)
			else
				arg_16_0:nodeByName("btn_ok"):setVisible(false)
			end
		end, var_0_10)
	end
end

function var_0_0.updateScale(arg_18_0)
	if arg_18_0.add == false then
		if arg_18_0.scale <= 1 then
			arg_18_0.add = true
		end

		arg_18_0.scale = arg_18_0.scale - var_0_9
	else
		if arg_18_0.scale >= var_0_8 then
			arg_18_0.add = false
		end

		arg_18_0.scale = arg_18_0.scale + var_0_9
	end

	if not tolua.isnull(arg_18_0.selectItemCell) then
		arg_18_0.bg:setScale(arg_18_0.scale)
	end

	if tolua.isnull(arg_18_0.selectItemCell) then
		var_0_4.unscheduleGlobal(arg_18_0.backpackHandle)

		arg_18_0.backpackHandle = nil
	end
end

function var_0_0.willClose(arg_19_0)
	if arg_19_0.backpackHandle ~= nil then
		var_0_4.unscheduleGlobal(arg_19_0.backpackHandle)

		arg_19_0.backpackHandle = nil
	end
end

return var_0_0
