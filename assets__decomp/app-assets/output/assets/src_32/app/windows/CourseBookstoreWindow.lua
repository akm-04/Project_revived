local var_0_0 = class("CourseBookstoreWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = 19
local var_0_4 = 7

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.course = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)
	arg_1_0.shop_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.shopType_ = xyd.ShopType.COURSE
	arg_1_0.isHasGift = arg_1_2.is_has_gift
	arg_1_0.tipIndex = 0
	arg_1_0.freeItems = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.REFRESH_COURSE_BOOK, function(arg_3_0)
		local var_3_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH)

		if var_3_0:getSpecialTag(41)[1] then
			var_3_0:setSpecialTag(41, 2)
		end

		arg_2_0:updateBookBoxShow()
	end)
	arg_2_0:layout()
	arg_2_0:addTopSidebar()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.tipLabel = arg_4_0:nodeByName("tip_txt")

	arg_4_0.tipLabel:getVirtualRenderer():setLineHeight(28)
	arg_4_0:setButtonClick()
	arg_4_0:nextTip()
	arg_4_0:createContainer()
	arg_4_0:updateBookBoxShow()
end

function var_0_0.nextTip(arg_5_0)
	local var_5_0 = xyd.tables.shop

	arg_5_0.tipIndex = arg_5_0.tipIndex % 6 + 1

	local var_5_1 = ""

	if arg_5_0.tipIndex == 1 and arg_5_0.isHasGift == 1 then
		var_5_1 = var_5_0:specialDialog(arg_5_0.shopType_, false)
	elseif arg_5_0.tipIndex == 6 then
		var_5_1 = var_5_0:specialDialog(arg_5_0.shopType_, true)
	else
		var_5_1 = var_5_0:dialogClick(arg_5_0.shopType_)
	end

	arg_5_0:playTip(var_5_1)
end

function var_0_0.playTip(arg_6_0, arg_6_1)
	arg_6_0.tipLabel:setString(arg_6_1)
end

function var_0_0.updateBookBoxShow(arg_7_0)
	for iter_7_0 = 1, 2 do
		if arg_7_0.freeItems[iter_7_0] then
			arg_7_0.freeItems[iter_7_0]:removeFromParent()
		end
	end

	arg_7_0.freeItems = {}

	local var_7_0 = arg_7_0:nodeByName("scroll"):getContentSize()
	local var_7_1 = arg_7_0.backpack:getItemNumByID(xyd.tables.misc.objectBoxBook1)
	local var_7_2 = arg_7_0.backpack:getItemNumByID(xyd.tables.misc.objectBoxBook2)

	if var_7_1 > 0 or arg_7_0.isHasGift > 0 then
		local var_7_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/course/book_store/shop_item.csb")
		local var_7_4 = var_7_3:getChildByName("container")
		local var_7_5 = var_7_4:getContentSize()
		local var_7_6 = "windows/course/book_store/icon_box.png"

		table.insert(arg_7_0.freeItems, var_7_3)
		var_7_4:getChildByName("crystal"):setVisible(false)
		var_7_4:getChildByName("txt_price"):setVisible(false)
		var_7_4:getChildByName("btn_get"):setVisible(true)
		var_7_4:getChildByName("btn_get"):getChildByName("txt_get"):setString(var_0_1:translation("COURSE_TEXT_19"))
		var_7_4:getChildByName("txt_name"):setString(var_0_1:translation("COURSE_TEXT_20"))
		arg_7_0:setIconBorder(var_7_4:getChildByName("item"), var_7_6, var_7_1)
		xyd.nodeEventSample(var_7_4:getChildByName("btn_get"), nil, function()
			xyd.playButtonSound()

			local var_8_0 = {
				item_id = xyd.tables.misc.objectBoxBook1
			}

			arg_7_0.course:openGiftBox(var_8_0, function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					arg_7_0.selfPlayer:handleRewards(arg_9_1.awards)

					if arg_7_0.isHasGift == 0 then
						local var_9_0 = {
							itemID = xyd.tables.misc.objectBoxBook1
						}

						var_9_0.itemNum = 1

						arg_7_0.backpack:removeItem(var_9_0)
					else
						arg_7_0.isHasGift = 0

						local var_9_1 = xyd.WindowManager.get():getWindow("course")

						if var_9_1 and not tolua.isnull(var_9_1) then
							var_9_1:updateRedMarkShow()
						end
					end

					arg_7_0:nextTip()
					arg_7_0:updateBookBoxShow()

					local var_9_2 = xyd.WindowManager.get():getWindow("course")

					if var_9_2 and not tolua.isnull(var_9_2) then
						var_9_2:updateLevelUpItems()
					end
				end
			end)
		end)

		local var_7_7 = arg_7_0.shopItemNum + #arg_7_0.freeItems
		local var_7_8 = (var_7_7 - 1) % 4 * (var_7_5.width + var_0_3)
		local var_7_9 = var_7_0.height - var_7_5.height - math.floor((var_7_7 - 1) / 4) * (var_7_5.height + var_0_4)

		var_7_3:setPosition(var_7_8, var_7_9)
		arg_7_0:nodeByName("scroll"):addChild(var_7_3)
	end

	if var_7_2 > 0 then
		local var_7_10 = xyd.AssetLoader.get():loadNodeFromJson("windows/course/book_store/shop_item.csb")
		local var_7_11 = var_7_10:getChildByName("container")
		local var_7_12 = var_7_11:getContentSize()
		local var_7_13 = "windows/course/book_store/icon_box.png"

		table.insert(arg_7_0.freeItems, var_7_10)
		var_7_11:getChildByName("crystal"):setVisible(false)
		var_7_11:getChildByName("txt_price"):setVisible(false)
		var_7_11:getChildByName("btn_get"):setVisible(true)
		var_7_11:getChildByName("txt_name"):setString(var_0_1:translation("COURSE_TEXT_21"))
		arg_7_0:setIconBorder(var_7_11:getChildByName("item"), var_7_13, var_7_2)
		xyd.nodeEventSample(var_7_11:getChildByName("btn_get"), nil, function()
			xyd.playButtonSound()

			local var_10_0 = {
				item_id = xyd.tables.misc.objectBoxBook2
			}

			arg_7_0.course:openGiftBox(var_10_0, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					arg_7_0.selfPlayer:handleRewards(arg_11_1.awards)

					local var_11_0 = {
						itemID = xyd.tables.misc.objectBoxBook2
					}

					var_11_0.itemNum = 1

					arg_7_0.backpack:removeItem(var_11_0)
					arg_7_0:updateBookBoxShow()

					local var_11_1 = xyd.WindowManager.get():getWindow("course")

					if var_11_1 and not tolua.isnull(var_11_1) then
						var_11_1:updateLevelUpItems()
					end
				end
			end)
		end)

		local var_7_14 = arg_7_0.shopItemNum + #arg_7_0.freeItems
		local var_7_15 = (var_7_14 - 1) % 4 * (var_7_12.width + var_0_3)
		local var_7_16 = var_7_0.height - var_7_12.height - math.floor((var_7_14 - 1) / 4) * (var_7_12.height + var_0_4)

		var_7_10:setPosition(var_7_15, var_7_16)
		arg_7_0:nodeByName("scroll"):addChild(var_7_10)
	end
end

function var_0_0.createContainer(arg_12_0)
	local var_12_0 = arg_12_0:nodeByName("scroll"):getContentSize()
	local var_12_1 = 0
	local var_12_2 = var_12_0.height - 253
	local var_12_3 = arg_12_0.shop_.items_[arg_12_0.shopType_]

	arg_12_0.shopItemNum = 1

	for iter_12_0, iter_12_1 in ipairs(var_12_3) do
		local var_12_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/course/book_store/shop_item.csb")
		local var_12_5 = var_12_4:getChildByName("container")
		local var_12_6 = var_12_5:getContentSize()

		var_12_5:getChildByName("txt_name"):setString(var_0_2:name(iter_12_1.item_id))
		var_12_5:getChildByName("txt_price"):setString(iter_12_1.sell_price)
		var_12_5:getChildByName("txt_price"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
		xyd.setItemBorder(var_12_5:getChildByName("item"), iter_12_1.item_id, nil, nil, iter_12_1.item_num)
		var_12_5:addTouchEventListener(function(arg_13_0, arg_13_1)
			xyd.buttonScaleAnim(arg_13_0, arg_13_1)

			if arg_13_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_13_0 = {
					index = iter_12_1.index,
					itemID = iter_12_1.item_id,
					itemNum = iter_12_1.item_num,
					isBuy = 0 or iter_12_1.isbuy,
					sellPrice = iter_12_1.sell_price,
					sellType = iter_12_1.sell_type,
					shopType = arg_12_0.shopType_,
					disCount = iter_12_1.discount,
					stoneID = iter_12_1.stone_id
				}

				xyd.WindowManager.get():openWindow("shop_detail_window", var_13_0)
			end
		end)
		var_12_4:setPosition(var_12_1, var_12_2)

		if arg_12_0.shopItemNum % 4 == 0 then
			var_12_1 = 0
			var_12_2 = var_12_2 - var_12_6.height - var_0_4
		else
			var_12_1 = var_12_1 + var_12_6.width + var_0_3
		end

		arg_12_0.shopItemNum = arg_12_0.shopItemNum + 1

		arg_12_0:nodeByName("scroll"):addChild(var_12_4)
	end

	arg_12_0.shopItemNum = arg_12_0.shopItemNum - 1
end

function var_0_0.setButtonClick(arg_14_0)
	arg_14_0:nodeByName("hero_card"):setTouchEnabled(true)
	arg_14_0:nodeByName("hero_card"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
		if arg_15_0.name == "began" then
			return true
		elseif arg_15_0.name == "ended" then
			arg_14_0:nextTip()
		end
	end)
end

function var_0_0.setIconBorder(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	local var_16_0 = arg_16_1:getContentSize().width
	local var_16_1 = xyd.getItemBg(3)
	local var_16_2 = var_16_0 / var_16_1:getContentSize().width

	var_16_1:setScale(var_16_2)
	var_16_1:setNormalizedPosition(cc.p(0.5, 0.5))
	arg_16_1:addChild(var_16_1)

	local var_16_3 = xyd.AssetLoader.get():loadSprite(arg_16_2)

	var_16_3:setScale(var_16_2)
	var_16_3:setNormalizedPosition(cc.p(0.5, 0.5))
	arg_16_1:addChild(var_16_3)

	if arg_16_3 and arg_16_3 > 1 then
		local var_16_4 = xyd.AssetLoader:get():loadSprite("images/bg_num.png")
		local var_16_5 = var_16_4:getContentSize().width
		local var_16_6 = 12 * var_16_0 / 108

		arg_16_1:addChild(var_16_4)
		var_16_4:setAnchorPoint(cc.p(1, 0))
		var_16_4:setPosition(var_16_3:getContentSize().width * var_16_2, var_16_6 / 2)
		var_16_4:setName("digit_bg")

		if var_16_0 < var_16_5 then
			var_16_4:setScale(var_16_0 / var_16_5)
		end

		local var_16_7 = {
			size = 20,
			y = 2,
			text = arg_16_3,
			color = cc.c3b(255, 255, 255),
			align = cc.ui.TEXT_ALIGN_CENTER,
			valign = cc.ui.TEXT_VALIGN_TOP,
			x = var_16_5 - var_16_6
		}
		local var_16_8 = xyd.AssetLoader.get():loadLabel(var_16_7)

		var_16_8:addTo(var_16_4)
		var_16_8:setAnchorPoint(1, 0)
		var_16_8:setName("num_label")

		local var_16_9 = var_16_8:getContentSize().width

		if var_16_9 > var_16_5 - var_16_6 * 1.5 and var_16_9 > var_16_0 - var_16_6 * 1.5 then
			var_16_4:setScale((var_16_0 - var_16_6 * 1.5) / var_16_9)
		end
	end
end

return var_0_0
