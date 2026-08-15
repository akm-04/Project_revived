local var_0_0 = class("InscriptionSuitWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.inscriptionSuit
local var_0_3 = import("app.model.Hero")
local var_0_4 = {
	TWO = 4,
	THREE = 5
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.inscription = xyd.ModelManager.get():loadModel(xyd.ModelType.INSCRIPTION)
	arg_1_0.suitType = var_0_4.TWO
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_title"):setString(var_0_1:translation("INSCRIPTION_SUIT_TEXT1"))
	arg_3_0:nodeByName("detail_title1_txt"):setString(var_0_1:translation("INSCRIPTION_SUIT_TEXT1"))
	arg_3_0:nodeByName("detail_title2_txt"):setString(var_0_1:translation("INSCRIPTION_SUIT_TEXT2"))
	arg_3_0:nodeByName("recommend_title_txt"):setString(var_0_1:translation("INSCRIPTION_SUIT_TEXT3"))

	arg_3_0.scroll = arg_3_0:nodeByName("type_scroll")

	local var_3_0 = arg_3_0.scroll:getContentSize()

	arg_3_0.typeList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.typeList:setBounceable(false)

	arg_3_0.recommendScroll = arg_3_0:nodeByName("recommend_scroll")

	local var_3_1 = arg_3_0.recommendScroll:getContentSize()

	arg_3_0.recommendList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL
	}):addTo(arg_3_0.recommendScroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.recommendList:setBounceable(false)
	arg_3_0.recommendList:setDelegate(handler(arg_3_0, arg_3_0.recommendListDelegate))

	arg_3_0.suitIds = {}

	for iter_3_0, iter_3_1 in pairs(var_0_4) do
		arg_3_0.suitIds[iter_3_1] = {}
		arg_3_0.suitIds[iter_3_1].ids = var_0_2:getSuitIdsByType(iter_3_1)
		arg_3_0.suitIds[iter_3_1].is_show = iter_3_1 == arg_3_0.suitType
	end

	arg_3_0:updateSuitType(arg_3_0.suitType)
end

function var_0_0.updateSuitType(arg_4_0, arg_4_1)
	arg_4_0.suitIds[arg_4_0.suitType].is_show = false
	arg_4_0.suitIds[arg_4_1].is_show = true
	arg_4_0.suitType = arg_4_1
	arg_4_0.currentSuitId = arg_4_0.suitIds[arg_4_0.suitType].ids[1]

	arg_4_0:reloadTypeList()
	arg_4_0:updateSuitId(arg_4_0.currentSuitId)
end

function var_0_0.reloadTypeList(arg_5_0)
	arg_5_0.typeList:removeAllItems()

	arg_5_0.suitCells = {}

	for iter_5_0 = 4, 5 do
		local var_5_0 = arg_5_0.typeList:newItem()
		local var_5_1 = arg_5_0:createTypeListContent(iter_5_0)
		local var_5_2 = var_5_1:getContentSize()

		var_5_0:setItemSize(var_5_2.width, var_5_2.height + 3)
		var_5_0:addContent(var_5_1)
		arg_5_0.typeList:addItem(var_5_0)

		if arg_5_0.suitIds[iter_5_0].is_show then
			local var_5_3 = -1

			for iter_5_1, iter_5_2 in ipairs(arg_5_0.suitIds[iter_5_0].ids) do
				local var_5_4 = arg_5_0.typeList:newItem()
				local var_5_5 = arg_5_0:createSubTypeListContent(iter_5_2)
				local var_5_6 = var_5_5:getContentSize()

				var_5_4:setItemSize(var_5_6.width, var_5_6.height + 3)
				var_5_4:addContent(var_5_5)
				var_5_4:setLocalZOrder(var_5_3)

				var_5_3 = var_5_3 - 1

				arg_5_0.typeList:addItem(var_5_4)
			end
		end
	end

	arg_5_0.typeList:reload()
end

function var_0_0.createTypeListContent(arg_6_0, arg_6_1)
	local var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/inscription/suit/type_item.csb")
	local var_6_1 = var_6_0:getChildByName("container")

	var_6_1:getChildByName("name_txt"):setString(var_0_1:translation("INSCRIPTION_SUIT_TYPE_" .. arg_6_1))

	if arg_6_0.suitIds[arg_6_1].is_show then
		var_6_1:getChildByName("btn"):setBrightStyle(ccui.BrightStyle.highlight)
	else
		var_6_1:getChildByName("btn"):setBrightStyle(ccui.BrightStyle.normal)
	end

	var_6_1:getChildByName("btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			arg_6_0:updateSuitType(arg_6_1)
		end
	end)
	var_6_0:setContentSize(var_6_1:getContentSize())

	return var_6_0
end

function var_0_0.createSubTypeListContent(arg_8_0, arg_8_1)
	local var_8_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/inscription/suit/sub_type_item.csb")
	local var_8_1 = var_8_0:getChildByName("container")

	var_8_1:getChildByName("name_txt"):setString(var_0_2:nameShow(arg_8_1))

	if arg_8_0.currentSuitId == arg_8_1 then
		var_8_1:getChildByName("btn"):setBrightStyle(ccui.BrightStyle.highlight)
		var_8_1:getChildByName("left_click_on"):setVisible(true)
		var_8_1:getChildByName("left_click_not"):setVisible(false)
	else
		var_8_1:getChildByName("btn"):setBrightStyle(ccui.BrightStyle.normal)
		var_8_1:getChildByName("left_click_on"):setVisible(false)
		var_8_1:getChildByName("left_click_not"):setVisible(true)
	end

	var_8_1:getChildByName("btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			arg_8_0:updateSuitId(arg_8_1)
		end
	end)

	arg_8_0.suitCells[arg_8_1] = var_8_1

	var_8_0:setContentSize(var_8_1:getContentSize())

	return var_8_0
end

function var_0_0.updateSuitId(arg_10_0, arg_10_1)
	if arg_10_0.suitCells[arg_10_0.currentSuitId] then
		arg_10_0.suitCells[arg_10_0.currentSuitId]:getChildByName("btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_10_0.suitCells[arg_10_0.currentSuitId]:getChildByName("left_click_on"):setVisible(false)
		arg_10_0.suitCells[arg_10_0.currentSuitId]:getChildByName("left_click_not"):setVisible(true)
		arg_10_0.suitCells[arg_10_1]:getChildByName("btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_10_0.suitCells[arg_10_1]:getChildByName("left_click_on"):setVisible(true)
		arg_10_0.suitCells[arg_10_1]:getChildByName("left_click_not"):setVisible(false)
	end

	arg_10_0.currentSuitId = arg_10_1

	arg_10_0:updateSuitInfos()
end

function var_0_0.updateSuitInfos(arg_11_0)
	local var_11_0 = var_0_2:attr(arg_11_0.currentSuitId)[1]
	local var_11_1 = var_0_2:attr_num(arg_11_0.currentSuitId)[1]
	local var_11_2 = xyd.tables.attr:name(var_11_0) .. "+" .. tostring(var_11_1) .. xyd.tables.attr:suffix(var_11_0)

	arg_11_0:nodeByName("effect_desc_txt"):setString(var_11_2)

	arg_11_0.recommendHeros = var_0_2:recommend(arg_11_0.currentSuitId)

	table.sort(arg_11_0.recommendHeros, function(arg_12_0, arg_12_1)
		local var_12_0 = arg_11_0.selfPlayer:getHeroIgnoreAwaken(arg_12_0)
		local var_12_1 = arg_11_0.selfPlayer:getHeroIgnoreAwaken(arg_12_1)

		if var_12_0 and not var_12_1 then
			return true
		else
			return false
		end
	end)
	arg_11_0.recommendList:reload()

	local var_11_3 = var_0_2:itemID(arg_11_0.currentSuitId)

	arg_11_0:nodeByName("suit_pos"):removeAllChildren(true)

	for iter_11_0 = 1, #var_11_3 do
		local var_11_4 = arg_11_0:createSuitItemContent(var_11_3[iter_11_0])

		var_11_4:setAnchorPoint(cc.p(0, 1))
		var_11_4:addTo(arg_11_0:nodeByName("suit_pos"))
		var_11_4:setPosition(cc.p(0, -(iter_11_0 - 1) * 120))
	end
end

function var_0_0.recommendListDelegate(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0 = arg_13_0.recommendHeros

	if cc.ui.UIListView.COUNT_TAG == arg_13_2 then
		return #var_13_0
	elseif cc.ui.UIListView.CELL_TAG == arg_13_2 then
		local var_13_1
		local var_13_2 = arg_13_0.recommendList:dequeueItem()

		if not var_13_2 then
			var_13_2 = arg_13_0.recommendList:newItem()
		else
			var_13_2:removeAllChildren(true)
		end

		local var_13_3 = arg_13_0:createRecommendListContent(var_13_0[arg_13_3])
		local var_13_4 = var_13_3:getWidth()
		local var_13_5 = var_13_3:getHeight()

		var_13_2:setItemSize(var_13_4 + 10, var_13_5)
		var_13_2:addContent(var_13_3)

		return var_13_2
	end
end

function var_0_0.createRecommendListContent(arg_14_0, arg_14_1)
	local var_14_0 = display.newNode()
	local var_14_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/inscription/suit/recommend_item.csb")
	local var_14_2 = var_14_1:getChildByName("container")
	local var_14_3 = arg_14_0.selfPlayer:getHeroIgnoreAwaken(arg_14_1)
	local var_14_4 = false

	if var_14_3 then
		var_14_4 = true
	else
		var_14_3 = var_0_3.new()

		var_14_3:populateWithTableID(arg_14_1)
	end

	xyd.setAvatarBorderNewUI(var_14_3, var_14_2:getChildByName("icon_container"), nil, nil, nil, not var_14_4)
	var_14_2:getChildByName("name_txt"):setString(var_14_3:getName())
	var_14_1:addTo(var_14_0)
	var_14_1:setAnchorPoint(cc.p(0, 0))
	var_14_1:setTouchEnabled(true)
	var_14_1:setTouchSwallowEnabled(false)
	var_14_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
		if arg_15_0.name == "began" then
			return true
		elseif arg_15_0.name == "ended" then
			local var_15_0 = {
				heros = {
					var_14_3
				}
			}

			var_15_0.current = 1

			if not var_14_4 then
				xyd.WindowManager.get():openWindow("tujian_herodetail", var_15_0)
			else
				xyd.WindowManager.get():openWindow("hero_main", var_15_0)
			end
		end
	end)
	var_14_0:setContentSize(var_14_2:getContentSize())
	var_14_1:setName("source")

	return var_14_0
end

function var_0_0.createSuitItemContent(arg_16_0, arg_16_1)
	local var_16_0 = display.newNode()
	local var_16_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/inscription/suit/suit_item.csb")
	local var_16_2 = var_16_1:getChildByName("container")

	xyd.setItemBorder(var_16_2:getChildByName("icon_container"), arg_16_1)
	var_16_2:getChildByName("name_txt"):setString(xyd.tables.item:name(arg_16_1))

	local var_16_3, var_16_4, var_16_5 = arg_16_0.inscription:getInscriptionAttrLabelText(arg_16_1)

	var_16_2:getChildByName("attr_desc_txt"):setString(var_16_3 .. " + " .. var_16_4 .. var_16_5)
	var_16_1:addTo(var_16_0)
	var_16_1:setAnchorPoint(cc.p(0, 0))
	var_16_0:setContentSize(var_16_2:getContentSize())
	var_16_1:setName("source")

	return var_16_0
end

function var_0_0.scrollListener(arg_17_0, arg_17_1)
	if arg_17_1.name == "began" then
		arg_17_0.scrollViewMoved_ = false
		arg_17_0.prevY_ = arg_17_1.y
	elseif arg_17_1.name == "moved" and 5 <= math.abs(arg_17_1.y - arg_17_0.prevY_) then
		arg_17_0.scrollViewMoved_ = true
	end
end

return var_0_0
