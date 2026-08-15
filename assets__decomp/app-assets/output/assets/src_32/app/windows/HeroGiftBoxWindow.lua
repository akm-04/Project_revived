local var_0_0 = class("HeroGiftBoxWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 1000
local var_0_3 = 3
local var_0_4 = 50001112
local var_0_5 = 120001018

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.hero = arg_1_2.hero
	arg_1_0.shop = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)
	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.cardContainer = arg_2_0:nodeByName("card_container")
	arg_2_0.listItems = xyd.tables.libraryGift:getAllItems()
	arg_2_0.partnerInfo = arg_2_0.library.libraryInfos[arg_2_0.hero:getHeroID()]
	arg_2_0.bg = arg_2_0:nodeByName("bg")

	arg_2_0:setBG()
	arg_2_0:layout()

	local var_2_0 = {
		hero = arg_2_0.hero
	}

	xyd.WindowManager.get():openWindow("library_hero_favor", var_2_0)
end

function var_0_0.setBG(arg_3_0)
	if arg_3_0.bg then
		arg_3_0.bg:removeSelf()
	end

	arg_3_0.bg = xyd.SpriteLoader.new(xyd.tables.libraryBG:getBG(arg_3_0.library.bgRoom), nil, nil, xyd.DefaultImageType.BG_ROOM)

	arg_3_0.bg:setAnchorPoint(0, 0)
	arg_3_0.bg:addTo(arg_3_0, -1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:updateCardContainer()

	arg_4_0.scroll = arg_4_0:nodeByName("scroll")
	arg_4_0.scrollContent = arg_4_0.scroll:getContentSize()
	arg_4_0.giftList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_4_0.scrollContent.width, arg_4_0.scrollContent.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.giftList:setDelegate(handler(arg_4_0, arg_4_0.giftListDelegate))
	arg_4_0.giftList:setBounceable(false)
	arg_4_0.giftList:reload()
	arg_4_0:setButtonClick()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.REFRESH_MAGIC_GIFT, function(arg_5_0)
		if arg_4_0 and not tolua.isnull(arg_4_0) then
			arg_4_0.giftList:reload()
		end
	end)
end

function var_0_0.setButtonClick(arg_6_0)
	arg_6_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("hero_send_gift_rule")
		end
	end)
	arg_6_0:nodeByName("gift_shop_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			arg_6_0.shop:loadShopList({}, function()
				xyd.WindowManager.get():openWindow("shop", {
					shop_type = xyd.ShopType.MAGIC,
					top_status = xyd.MainSceneTop.CLOSE
				})
			end)
		end
	end)
end

function var_0_0.giftListDelegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return math.ceil(#arg_10_0.listItems / var_0_3)
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_0
		local var_10_1 = arg_10_0.giftList:dequeueItem()

		if not var_10_1 then
			var_10_1 = arg_10_0.giftList:newItem()
		else
			var_10_1:removeAllChildren(true)
		end

		local var_10_2 = arg_10_0:createListContent(arg_10_3)
		local var_10_3 = var_10_2:getWidth()
		local var_10_4 = var_10_2:getHeight()

		var_10_1:setItemSize(var_10_3, var_10_4)
		var_10_1:addContent(var_10_2)

		return var_10_1
	end
end

function var_0_0.createListContent(arg_11_0, arg_11_1)
	local var_11_0 = display.newNode()
	local var_11_1 = 150
	local var_11_2 = 70
	local var_11_3 = 10

	var_11_0:setContentSize(480, 185)

	for iter_11_0 = 1, var_0_3 do
		if (arg_11_1 - 1) * var_0_3 + iter_11_0 <= #arg_11_0.listItems then
			local var_11_4 = arg_11_0.listItems[(arg_11_1 - 1) * var_0_3 + iter_11_0]
			local var_11_5 = arg_11_0:creatGiftItemContent(var_11_4)

			var_11_5:setContentSize(100, 100)
			var_11_5:setAnchorPoint(cc.p(0.5, 0))
			var_11_5:addTo(var_11_0)
			var_11_5:setPosition(cc.p(var_11_2, var_11_3))

			var_11_2 = var_11_2 + var_11_1

			var_11_5:setTouchEnabled(true)
			var_11_5:setTouchSwallowEnabled(false)
			var_11_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
				if arg_12_0.name == "began" and arg_11_0.scrollViewMoved_ ~= true then
					var_11_5:setScale(0.9)

					return true
				elseif arg_12_0.name == "ended" then
					var_11_5:setScale(1)

					if arg_11_0.scrollViewMoved_ then
						return
					end

					local var_12_0 = arg_11_0.backpack:getItemNumByID(var_11_4)

					if var_11_4 ~= var_0_4 and arg_11_0.hero:getFavorState() == xyd.FavorState.FULL then
						local var_12_1 = var_0_1:translation("HERO_FAVOR_FULL_TIPS")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_12_1
						})
					elseif arg_11_0.hero:getFavorState() == xyd.FavorState.MARRIED then
						local var_12_2 = var_0_1:translation("HAS_GOT_MARRIED_TIPS")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_12_2
						})
					elseif var_11_4 == var_0_4 and arg_11_0.hero:getFavorState() == xyd.FavorState.NOT_FULL then
						local var_12_3 = var_0_1:translation("FAVOR_NOT_FULL_TIPS")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_12_3
						})
					elseif var_12_0 > 0 and var_11_4 ~= var_0_4 then
						local var_12_4 = {
							item_id = var_11_4,
							item_type = xyd.ConsumeItemType.LOVE_ITEM,
							partner_id = arg_11_0.hero:getHeroID(),
							item_node = var_11_5,
							favor_degree = arg_11_0.hero:getFavorDegree(),
							hero_table_id = arg_11_0.hero:getTableID()
						}

						xyd.WindowManager.get():openWindow("giftbag_use", var_12_4)
					elseif var_12_0 > 0 and var_11_4 == var_0_4 then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("LIBRARY_SURE_SEND_GIFT"), function()
							local var_13_0 = {}

							var_13_0.gift_num = 1
							var_13_0.gift_id = var_11_4
							var_13_0.partner_id = arg_11_0.hero:getHeroID()

							arg_11_0:addFavorOrMarried(var_13_0, var_11_5)
						end, nil, nil, arg_11_0.colorMode)
					else
						local var_12_5 = var_0_1:translation("LIBBRAY_GIFT_NOT_ENOUGH")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_12_5
						})
					end
				end
			end)
		end
	end

	return var_11_0
end

function var_0_0.creatGiftItemContent(arg_14_0, arg_14_1)
	local var_14_0 = display.newNode()
	local var_14_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/library/gift_box/gift_box_item.csb")
	local var_14_2 = var_14_1:getChildByName("container")
	local var_14_3 = arg_14_0.backpack:getItemNumByID(arg_14_1)

	xyd.setItemBorder(var_14_2:getChildByName("icon_container"), arg_14_1, nil, nil, var_14_3, nil, true)
	var_14_2:getChildByName("name_txt"):setString(xyd.tables.item:name(arg_14_1))
	var_14_1:addTo(var_14_0)
	var_14_1:setAnchorPoint(cc.p(0, 0))
	var_14_0:setContentSize(var_14_2:getContentSize())
	var_14_1:setName("source")

	return var_14_0
end

function var_0_0.addFavorOrMarried(arg_15_0, arg_15_1, arg_15_2)
	arg_15_0.library:addFavor(arg_15_1, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			if arg_16_1.partner_dialogs then
				arg_15_0.partnerInfo.partner_dialogs = arg_16_1.partner_dialogs
			end

			if arg_16_1.partner_acts then
				arg_15_0.partnerInfo.partner_acts = arg_16_1.partner_acts
			end

			arg_15_0.selfPlayer:getBackpack():addItemsByID(arg_15_1.gift_id, 0 - arg_15_1.gift_num)

			if arg_15_0.selfPlayer:getBackpack():getItemNumByID(arg_15_1.gift_id) <= 0 then
				local var_16_0 = {}

				var_16_0.itemNum = 0
				var_16_0.itemID = arg_16_1.gift_id

				arg_15_0.selfPlayer:getBackpack():removeItem(var_16_0)
			end

			if arg_15_1.gift_id ~= var_0_4 and arg_16_1.favor_degree then
				arg_15_0.hero:setFavorDegree(arg_16_1.favor_degree)
			end

			if arg_15_1.gift_id == var_0_4 then
				local var_16_1 = {
					hero = arg_15_0.hero
				}

				arg_15_0.hero:setMarried()

				local var_16_2 = xyd.WindowManager.get():getWindow("hero_main")

				if var_16_2 then
					var_16_2:updateFavorContainer()
				end

				if not arg_15_0.selfPlayer:getBackpack():getItemByID(var_0_5) then
					local var_16_3 = {}

					var_16_3.itemNum = 1
					var_16_3.itemID = var_0_5

					arg_15_0.selfPlayer:getBackpack():addItem(var_16_3)
				end

				if xyd.WindowManager.get():getWindow("hero_task_main") then
					xyd.WindowManager.get():closeWindow("hero_task_main")
				end

				xyd.WindowManager.get():openWindow("get_married", var_16_1)
			end

			local var_16_4 = arg_15_2:getChildByName("source"):getChildByName("container"):getChildByName("icon_container")

			var_16_4:removeAllChildren()

			local var_16_5 = arg_15_1.gift_id
			local var_16_6 = arg_15_0.selfPlayer:getBackpack():getItemNumByID(var_16_5)

			xyd.setItemBorder(var_16_4, var_16_5, nil, nil, var_16_6, nil, true)

			if arg_15_1.gift_id ~= var_0_4 then
				local var_16_7 = arg_15_0.library:getSendGiftDialogId(arg_15_0.hero, arg_15_1.gift_id)
				local var_16_8 = {
					is_read = 1,
					dialog_id = var_16_7
				}

				arg_15_0.library:playDialog(arg_15_0.hero, var_16_8)
			end
		end
	end)
end

function var_0_0.scrollListener(arg_17_0, arg_17_1)
	if arg_17_1.name == "began" then
		arg_17_0.scrollViewMoved_ = false
		arg_17_0.prevY_ = arg_17_1.y
	elseif arg_17_1.name == "moved" and 5 <= math.abs(arg_17_1.y - arg_17_0.prevY_) then
		arg_17_0.scrollViewMoved_ = true
	end
end

function var_0_0.didClose(arg_18_0, arg_18_1)
	var_0_0.super.didClose(arg_18_0, arg_18_1)
	xyd.WindowManager.get():closeWindow("library_hero_favor")
end

function var_0_0.updateCardContainer(arg_19_0)
	arg_19_0.library:updateCardContainer(arg_19_0.hero, arg_19_0.cardContainer, arg_19_0.library.cardState)
end

return var_0_0
