local var_0_0 = class("InscriptionRedoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

INSCIPTION_TYPE = {
	MOON = 2,
	STAR = 3,
	SUN = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.inscription = xyd.ModelManager.get():loadModel(xyd.ModelType.INSCRIPTION)
	arg_1_0.inscriptionType = INSCIPTION_TYPE.SUN
	arg_1_0.listItems = arg_1_0.inscription:getRedoItemsBaseOnType(arg_1_0.inscriptionType)

	if arg_1_2 then
		arg_1_0.callback = arg_1_2.callback
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super:didClose(arg_4_1)
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
	arg_5_0:setButtonClick()
	arg_5_0:update()
end

function var_0_0.setButtonClick(arg_6_0)
	arg_6_0.typeBtns = {}
	arg_6_0.typeBtns[INSCIPTION_TYPE.SUN] = arg_6_0:nodeByName("sun_btn")
	arg_6_0.typeBtns[INSCIPTION_TYPE.MOON] = arg_6_0:nodeByName("moon_btn")
	arg_6_0.typeBtns[INSCIPTION_TYPE.STAR] = arg_6_0:nodeByName("star_btn")

	for iter_6_0, iter_6_1 in pairs(arg_6_0.typeBtns) do
		iter_6_1:addTouchEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.TouchEventType.ended then
				arg_6_0.inscriptionType = iter_6_0

				arg_6_0:update()
			end
		end)
	end
end

function var_0_0.update(arg_8_0)
	arg_8_0:updateTypeBtnBrightStyle()

	arg_8_0.listItems = arg_8_0.inscription:getRedoItemsBaseOnType(arg_8_0.inscriptionType)

	local var_8_0 = xyd.split(var_0_1:translation("INSCRPTION_TYPE_NAMES"), ",")[arg_8_0.inscriptionType]

	arg_8_0:nodeByName("no_inscription_txt"):setVisible(false)

	if #arg_8_0.listItems == 0 then
		arg_8_0:nodeByName("no_inscription_txt"):setVisible(true)
		arg_8_0:nodeByName("no_inscription_txt"):setString(string.format(var_0_1:translation("NO_INSCRIPTION_TIP"), var_8_0))
	end

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
		return #arg_10_0.listItems
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_0
		local var_10_1 = arg_10_0.itemList:dequeueItem()

		if not var_10_1 then
			var_10_1 = arg_10_0.itemList:newItem()
		else
			var_10_1:removeAllChildren(false)
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
	local var_11_0 = arg_11_0.listItems[arg_11_1].itemID
	local var_11_1 = display.newNode()
	local var_11_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/inscription/redo/redo_item.csb")
	local var_11_3 = var_11_2:getChildByName("container")

	arg_11_0.inscription:setInscriptionInfo(var_11_3, var_11_0)

	local var_11_4 = var_11_3:getChildByName("redo_btn")

	var_11_4:getChildByName("txt_redo"):setString(var_0_1:translation("INSCRIPTION_TEXT_9"))
	var_11_4:addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_12_0, arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended and not arg_11_0.scrollViewMoved_ and arg_11_0.callback then
			arg_11_0.callback(var_11_0)
			xyd.WindowManager.get():closeWindow(arg_11_0)
		end
	end)
	var_11_2:addTo(var_11_1)
	var_11_2:setAnchorPoint(cc.p(0, 0))
	var_11_1:setContentSize(var_11_3:getContentSize().width, var_11_3:getContentSize().height + 5)
	var_11_2:setPositionY(2.5)
	var_11_2:setName("source")

	return var_11_1
end

function var_0_0.scrollListener(arg_13_0, arg_13_1)
	if arg_13_1.name == "began" then
		arg_13_0.scrollViewMoved_ = false
		arg_13_0.prevY_ = arg_13_1.y
	elseif arg_13_1.name == "moved" and 5 <= math.abs(arg_13_1.y - arg_13_0.prevY_) then
		arg_13_0.scrollViewMoved_ = true
	end
end

return var_0_0
