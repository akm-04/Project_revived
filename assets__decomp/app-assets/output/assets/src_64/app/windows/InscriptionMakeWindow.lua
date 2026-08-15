local var_0_0 = class("InscriptionMakeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 5

INSCIPTION_TYPE = {
	MOON = 2,
	STAR = 3,
	SUN = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.inscription = xyd.ModelManager.get():loadModel(xyd.ModelType.INSCRIPTION)
	arg_1_0.inscriptionType = arg_1_0.inscription:getCurrentInscriptionType() or INSCIPTION_TYPE.SUN
	arg_1_0.listItems = xyd.tables.inscription:getItemIDsBaseOnType(arg_1_0.inscriptionType)

	if arg_1_2 and arg_1_2.callback then
		arg_1_0.callback = arg_1_2.callback
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	var_0_0.super.willClose(arg_3_0, arg_3_1)
	arg_3_0.inscription:setCurrentInscriptionType(arg_3_0.inscriptionType)
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:addBlockLayerClickClose()
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("txt_sun"):setString(var_0_1:translation("INSCRIPTION_TEXT_5"))
	arg_5_0:nodeByName("txt_moon"):setString(var_0_1:translation("INSCRIPTION_TEXT_6"))
	arg_5_0:nodeByName("txt_star"):setString(var_0_1:translation("INSCRIPTION_TEXT_7"))
	arg_5_0:nodeByName("txt_title"):setString(var_0_1:translation("INSCRIPTION_TEXT_8"))

	arg_5_0.scroll = arg_5_0:nodeByName("scroll")

	local var_5_0 = arg_5_0.scroll:getContentSize()

	arg_5_0.itemList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_0.width, var_5_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_5_0.scroll):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.itemList:setDelegate(handler(arg_5_0, arg_5_0.itemListDelegate))
	arg_5_0.itemList:setBounceable(false)
	arg_5_0.itemList:setTouchType(false)
	arg_5_0:setButtonClick()
	arg_5_0:updateItemList()
end

function var_0_0.setButtonClick(arg_6_0)
	arg_6_0.typeBtns = {}
	arg_6_0.typeBtns[INSCIPTION_TYPE.SUN] = arg_6_0:nodeByName("sun_btn")
	arg_6_0.typeBtns[INSCIPTION_TYPE.MOON] = arg_6_0:nodeByName("moon_btn")
	arg_6_0.typeBtns[INSCIPTION_TYPE.STAR] = arg_6_0:nodeByName("star_btn")

	arg_6_0:updateTypeBtnBrightStyle()

	for iter_6_0, iter_6_1 in pairs(arg_6_0.typeBtns) do
		iter_6_1:addTouchEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.TouchEventType.ended then
				arg_6_0.inscriptionType = iter_6_0

				arg_6_0:updateItemList()
				arg_6_0:updateTypeBtnBrightStyle()
			end
		end)
	end
end

function var_0_0.updateItemList(arg_8_0)
	arg_8_0.listItems = xyd.tables.inscription:getItemIDsBaseOnType(arg_8_0.inscriptionType)

	arg_8_0.itemList:reload()
end

function var_0_0.updateTypeBtnBrightStyle(arg_9_0)
	for iter_9_0, iter_9_1 in pairs(arg_9_0.typeBtns) do
		if iter_9_0 == arg_9_0.inscriptionType then
			arg_9_0.typeBtns[iter_9_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_9_0.typeBtns[iter_9_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end
end

function var_0_0.itemListDelegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return math.ceil(#arg_10_0.listItems / var_0_2)
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_0
		local var_10_1 = arg_10_0.itemList:dequeueItem()

		if not var_10_1 then
			var_10_1 = arg_10_0.itemList:newItem()
		else
			var_10_1:removeAllChildren(false)
		end

		local var_10_2 = arg_10_0:createListLineContent(arg_10_3)
		local var_10_3 = var_10_2:getWidth()
		local var_10_4 = var_10_2:getHeight()

		var_10_1:setItemSize(var_10_3, var_10_4)
		var_10_1:addContent(var_10_2)

		return var_10_1
	end
end

function var_0_0.createListLineContent(arg_11_0, arg_11_1)
	local var_11_0 = display.newNode()
	local var_11_1 = 148
	local var_11_2 = 54
	local var_11_3 = 101

	var_11_0:setContentSize(700, 172)

	for iter_11_0 = 1, var_0_2 do
		if (arg_11_1 - 1) * var_0_2 + iter_11_0 <= #arg_11_0.listItems then
			local var_11_4 = arg_11_0.listItems[(arg_11_1 - 1) * var_0_2 + iter_11_0]
			local var_11_5 = arg_11_0:creatItemContent(var_11_4)

			var_11_5:addTo(var_11_0)
			var_11_5:setAnchorPoint(cc.p(0.5, 0.5))
			var_11_5:setPosition(cc.p(var_11_2, var_11_3))

			var_11_2 = var_11_2 + var_11_1

			var_11_5:setTouchEnabled(true)
			var_11_5:setTouchSwallowEnabled(false)
			var_11_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
				if arg_12_0.name == "began" then
					var_11_5:setScale(0.9)

					arg_11_0.scrollViewMoved_ = false
					arg_11_0.prevX_ = arg_12_0.x
					arg_11_0.prevY_ = arg_12_0.y

					return true
				elseif arg_12_0.name == "moved" then
					local var_12_0 = 5

					if var_12_0 <= math.abs(arg_12_0.y - arg_11_0.prevY_) or var_12_0 <= math.abs(arg_12_0.x - arg_11_0.prevX_) then
						arg_11_0.scrollViewMoved_ = true
					end
				elseif arg_12_0.name == "ended" then
					if arg_11_0.scrollViewMoved_ then
						var_11_5:setScale(1)

						return
					end

					if arg_11_0.callback then
						arg_11_0.callback(var_11_4)
						xyd.WindowManager.get():closeWindow(arg_11_0)
					end
				end
			end)
		end
	end

	return var_11_0
end

function var_0_0.creatItemContent(arg_13_0, arg_13_1)
	local var_13_0 = xyd.tables.inscription:itemID(arg_13_1)[1]
	local var_13_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/inscription/make/make_item.csb")
	local var_13_2 = var_13_1:getChildByName("container")

	xyd.setItemBorder(var_13_2:getChildByName("icon_container"), var_13_0)
	var_13_2:getChildByName("lev_txt"):setString(string.format(var_0_1:translation("N_LEVEL"), xyd.tables.inscription:level(arg_13_1)))
	var_13_1:setName("source")

	return var_13_1
end

function var_0_0.scrollListener(arg_14_0, arg_14_1)
	if arg_14_1.name == "began" then
		arg_14_0.scrollViewMoved_ = false
		arg_14_0.prevY_ = arg_14_1.y
	elseif arg_14_1.name == "moved" and 5 <= math.abs(arg_14_1.y - arg_14_0.prevY_) then
		arg_14_0.scrollViewMoved_ = true
	end
end

return var_0_0
