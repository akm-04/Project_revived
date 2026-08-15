local var_0_0 = class("LibraryFeedWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.hero = arg_1_2.hero
	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.cardContainer = arg_2_0:nodeByName("card_container")
	arg_2_0.feedInfo = arg_2_0.hero:getFeedAttrs()
	arg_2_0.feedAddInfo = arg_2_1.feedAddInfo
	arg_2_0.selectCostId = nil
	arg_2_0.isFull = false

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
	arg_4_0:setButtonClick()
	arg_4_0:updateCardContainer()
	arg_4_0:updateShow()
end

function var_0_0.updateShow(arg_5_0)
	arg_5_0:updateAttrsList()
	arg_5_0:updateCost()
	arg_5_0:updateBtnState()
end

function var_0_0.setButtonClick(arg_6_0)
	arg_6_0:nodeByName("sure_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = {
				partner_id = arg_6_0.hero:getHeroID()
			}

			arg_6_0.library:saveHeroFeed(var_7_0, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					arg_6_0.feedInfo = arg_8_1.feed_attrs

					arg_6_0.hero:setFeedAttrs(arg_6_0.feedInfo)

					arg_6_0.feedAddInfo = nil

					arg_6_0:updateShow()
				end
			end)
		end
	end)
	arg_6_0:nodeByName("readd_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			if arg_6_0.isFull then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_1:translation("FEED_ATTRS_FULL_TIPS"), function()
					return
				end, nil, nil, arg_6_0.colorMode)

				return
			end

			if not arg_6_0.selectCostId then
				local var_9_0 = var_0_1:translation("SELECT_COSTTYPE_TIPS")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_9_0
				})
			elseif not arg_6_0:isCanFeed() then
				local var_9_1 = var_0_1:translation("COST_MATERIAL_NOT_ENOUGH")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_9_1
				})
			end

			local var_9_2 = {
				partner_id = arg_6_0.hero:getHeroID(),
				cost_id = arg_6_0.selectCostId
			}

			arg_6_0.library:heroFeed(var_9_2, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					arg_6_0.feedAddInfo = arg_11_1.feed_add

					arg_6_0:updateShow()

					local var_11_0 = xyd.tables.libraryFeedCost:costType(arg_6_0.selectCostId)
					local var_11_1 = xyd.tables.libraryFeedCost:cost(arg_6_0.selectCostId)

					if var_11_0 > 1000 then
						arg_6_0.backpack:removeItem({
							itemID = var_11_0,
							itemNum = var_11_1
						})
					end
				end
			end)
		end
	end)
end

function var_0_0.updateBtnState(arg_12_0)
	if arg_12_0.feedAddInfo then
		arg_12_0:nodeByName("sure_btn"):setTouchEnabled(true)
		arg_12_0:nodeByName("sure_btn"):setBright(true)
		arg_12_0:nodeByName("txt_confirm"):setVisible(true)
		arg_12_0:nodeByName("txt_confirm_gray"):setVisible(false)
		arg_12_0:nodeByName("feed_text"):setVisible(false)
		arg_12_0:nodeByName("refeed_text"):setVisible(true)
	else
		arg_12_0:nodeByName("sure_btn"):setTouchEnabled(false)
		arg_12_0:nodeByName("sure_btn"):setBright(false)
		arg_12_0:nodeByName("txt_confirm"):setVisible(false)
		arg_12_0:nodeByName("txt_confirm_gray"):setVisible(true)
		arg_12_0:nodeByName("feed_text"):setVisible(true)
		arg_12_0:nodeByName("refeed_text"):setVisible(false)
	end
end

function var_0_0.isCanFeed(arg_13_0)
	if arg_13_0.selectCostId and arg_13_0:isMaterialEnough(arg_13_0.selectCostId) then
		return true
	end

	return false
end

function var_0_0.isMaterialEnough(arg_14_0, arg_14_1)
	local var_14_0 = xyd.tables.libraryFeedCost:costType(arg_14_1)
	local var_14_1 = xyd.tables.libraryFeedCost:cost(arg_14_1)

	if var_14_0 == xyd.currencyType.MANA then
		if var_14_1 > arg_14_0.selfPlayer.mana then
			return false
		end
	elseif var_14_0 == xyd.currencyType.CRYSTAL then
		if var_14_1 > arg_14_0.selfPlayer.crystal then
			return false
		end
	elseif var_14_1 > arg_14_0.backpack:getItemNumByID(var_14_0) then
		return false
	end

	return true
end

function var_0_0.updateAttrsList(arg_15_0)
	arg_15_0:nodeByName("attrs_pos"):removeAllChildren(true)

	arg_15_0.isFull = arg_15_0:isAllAttrsFull()

	for iter_15_0 = 1, #arg_15_0.feedInfo do
		local var_15_0 = arg_15_0:createAttrItemContent(iter_15_0, arg_15_0.feedInfo[iter_15_0])

		var_15_0:setAnchorPoint(cc.p(0, 0.5))
		var_15_0:addTo(arg_15_0:nodeByName("attrs_pos"))
		var_15_0:setPositionY(-(iter_15_0 - 1) * 60)
	end
end

function var_0_0.isAllAttrsFull(arg_16_0)
	for iter_16_0 = 1, #arg_16_0.feedInfo do
		if arg_16_0.feedInfo[iter_16_0] < xyd.tables.libraryFeedAttr:attrLimit(iter_16_0) then
			return false
		end
	end

	return true
end

function var_0_0.updateCost(arg_17_0)
	arg_17_0:nodeByName("cost_pos"):removeAllChildren(true)

	for iter_17_0 = 1, xyd.tables.libraryFeedCost:getCostTypeNums() do
		local var_17_0 = arg_17_0:createCostItemContent(iter_17_0)

		var_17_0:setAnchorPoint(cc.p(0, 0.5))
		var_17_0:addTo(arg_17_0:nodeByName("cost_pos"))
		var_17_0:setPositionX((iter_17_0 - 1) * 143)
	end
end

function var_0_0.createAttrItemContent(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = xyd.tables.libraryFeedAttr:attrType(arg_18_1)
	local var_18_1 = display.newNode()
	local var_18_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/library/feed/feed_item.csb")
	local var_18_3 = var_18_2:getChildByName("container")

	var_18_3:getChildByName("attr_name_txt"):setString(xyd.tables.attr:name(var_18_0))
	var_18_3:getChildByName("progress_txt"):setString(tostring(arg_18_2) .. "/" .. xyd.tables.libraryFeedAttr:attrLimit(arg_18_1))
	var_18_3:getChildByName("progress_bar"):setPercent(arg_18_2 * 100 / xyd.tables.libraryFeedAttr:attrLimit(arg_18_1))

	if arg_18_0.isFull then
		var_18_3:getChildByName("add_txt"):setString(var_0_1:translation("WASH_FULL"))
		var_18_3:getChildByName("add_txt"):setColor(xyd.color.RED)
	elseif arg_18_0.feedAddInfo then
		if arg_18_0.feedAddInfo[arg_18_1] > 0 then
			var_18_3:getChildByName("add_txt"):setString("+" .. arg_18_0.feedAddInfo[arg_18_1])
			var_18_3:getChildByName("add_txt"):setColor(xyd.color.GREEN)
		elseif arg_18_0.feedAddInfo[arg_18_1] < 0 then
			var_18_3:getChildByName("add_txt"):setString(arg_18_0.feedAddInfo[arg_18_1])
			var_18_3:getChildByName("add_txt"):setColor(xyd.color.RED)
		else
			var_18_3:getChildByName("add_txt"):setString("")
		end
	else
		var_18_3:getChildByName("add_txt"):setString("")
	end

	var_18_2:addTo(var_18_1)
	var_18_2:setAnchorPoint(cc.p(0, 0))
	var_18_1:setContentSize(var_18_3:getContentSize())
	var_18_2:setName("source")

	return var_18_1
end

function var_0_0.createCostItemContent(arg_19_0, arg_19_1)
	local var_19_0 = xyd.tables.libraryFeedCost:costType(arg_19_1)
	local var_19_1 = display.newNode()
	local var_19_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/library/feed/cost_item.csb")
	local var_19_3 = var_19_2:getChildByName("container")
	local var_19_4
	local var_19_5

	if var_19_0 == xyd.currencyType.MANA then
		var_19_4 = xyd.AssetLoader:get():loadSprite("images/jinbi.png")
		var_19_5 = xyd.tables.libraryFeedCost:cost(arg_19_1)
	elseif var_19_0 == xyd.currencyType.CRYSTAL then
		var_19_4 = xyd.AssetLoader:get():loadSprite("images/zuanshi.png")
		var_19_5 = xyd.tables.libraryFeedCost:cost(arg_19_1)
	else
		var_19_4 = xyd.AssetLoader:get():loadSprite("windows/library/feed/rice_icon.png")
		var_19_5 = string.format(var_0_1:translation("LIBRARY_FEED_RICE_BALL"), xyd.tables.libraryFeedCost:cost(arg_19_1), arg_19_0.backpack:getItemNumByID(var_19_0))
	end

	local var_19_6 = var_19_3:getChildByName("icon"):getContentSize()

	var_19_4:addTo(var_19_3:getChildByName("icon"))
	var_19_4:setScale(var_19_6.width / var_19_4:getContentSize().width)
	var_19_4:setPosition(cc.p(var_19_6.width / 2, var_19_6.height / 2))
	var_19_3:getChildByName("cost_num_txt"):setString(var_19_5)

	if arg_19_0:isMaterialEnough(arg_19_1) then
		var_19_3:getChildByName("cost_num_txt"):setColor(cc.c3b(57, 53, 47))
	else
		var_19_3:getChildByName("cost_num_txt"):setColor(xyd.color.RED)
	end

	if arg_19_1 ~= arg_19_0.selectCostId then
		var_19_3:getChildByName("select"):setVisible(false)
	end

	var_19_3:getChildByName("box"):setTouchEnabled(true)
	var_19_3:getChildByName("box"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
		if arg_20_0.name == "began" then
			var_19_3:getChildByName("box"):setScale(0.9)

			return true
		elseif arg_20_0.name == "ended" then
			xyd.playButtonSound()
			var_19_3:getChildByName("box"):setScale(1)

			arg_19_0.selectCostId = arg_19_1

			arg_19_0:updateShow()
		end
	end)
	var_19_2:addTo(var_19_1)
	var_19_2:setAnchorPoint(cc.p(0, 0))
	var_19_1:setContentSize(var_19_3:getContentSize())
	var_19_2:setName("source")

	return var_19_1
end

function var_0_0.didClose(arg_21_0, arg_21_1)
	var_0_0.super.didClose(arg_21_0, arg_21_1)
	xyd.WindowManager.get():closeWindow("library_hero_favor")
end

function var_0_0.updateCardContainer(arg_22_0)
	arg_22_0.library:updateCardContainer(arg_22_0.hero, arg_22_0.cardContainer, arg_22_0.library.cardState)
end

return var_0_0
