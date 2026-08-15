local var_0_0 = class("ZhugeBoxCheckItem", function()
	return cc.Node:create()
end)
local var_0_1 = 4

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.setParams(arg_3_0, arg_3_1)
	arg_3_0.params = arg_3_1
	arg_3_0.boxTable = import("app.common.tables.ZhugeBoxTable").new()
	arg_3_0.btnWhite = arg_3_0.contentView_:nodeByName("btn_white")
	arg_3_0.btnBlack = arg_3_0.contentView_:nodeByName("btn_black")
	arg_3_0.btnWhite2 = arg_3_0.contentView_:nodeByName("btn_white2")
	arg_3_0.selectIndex = arg_3_1.boxType or xyd.ZhugeBoxType.WHITE
	arg_3_0.idx = arg_3_1.idx

	arg_3_0:getItems()
	arg_3_0:initList()
	arg_3_0:layout()
end

function var_0_0.getItems(arg_4_0)
	arg_4_0.ids = arg_4_0.boxTable:ids(arg_4_0.selectIndex)
end

function var_0_0.initList(arg_5_0)
	local var_5_0 = arg_5_0.contentView_:nodeByName("list")
	local var_5_1 = var_5_0:getContentSize()

	arg_5_0.list_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_1.width, var_5_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_5_0)

	arg_5_0.list_:setDelegate(handler(arg_5_0, arg_5_0.delegate))
end

function var_0_0.layout(arg_6_0)
	arg_6_0.btnWhite:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended and arg_6_0.selectIndex ~= xyd.ZhugeBoxType.WHITE then
			arg_6_0.btnWhite:setBrightStyle(ccui.BrightStyle.highlight)
			arg_6_0.btnBlack:setBrightStyle(ccui.BrightStyle.normal)
			arg_6_0.btnWhite2:setBrightStyle(ccui.BrightStyle.normal)

			arg_6_0.selectIndex = xyd.ZhugeBoxType.WHITE

			arg_6_0:getItems()
			arg_6_0.list_:reload()
		end
	end)
	arg_6_0.btnBlack:addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended and arg_6_0.selectIndex ~= xyd.ZhugeBoxType.BLACK then
			arg_6_0.btnBlack:setBrightStyle(ccui.BrightStyle.highlight)
			arg_6_0.btnWhite:setBrightStyle(ccui.BrightStyle.normal)
			arg_6_0.btnWhite2:setBrightStyle(ccui.BrightStyle.normal)

			arg_6_0.selectIndex = xyd.ZhugeBoxType.BLACK

			arg_6_0:getItems()
			arg_6_0.list_:reload()
		end
	end)
	arg_6_0.btnWhite2:addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended and arg_6_0.selectIndex ~= xyd.ZhugeBoxType.WHITE2 then
			arg_6_0.btnBlack:setBrightStyle(ccui.BrightStyle.normal)
			arg_6_0.btnWhite:setBrightStyle(ccui.BrightStyle.normal)
			arg_6_0.btnWhite2:setBrightStyle(ccui.BrightStyle.highlight)

			arg_6_0.selectIndex = xyd.ZhugeBoxType.WHITE2

			arg_6_0:getItems()
			arg_6_0.list_:reload()
		end
	end)

	if arg_6_0.selectIndex == xyd.ZhugeBoxType.WHITE then
		arg_6_0.btnWhite:setBrightStyle(ccui.BrightStyle.highlight)
		arg_6_0.btnBlack:setBrightStyle(ccui.BrightStyle.normal)
		arg_6_0.btnWhite2:setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_6_0.selectIndex == xyd.ZhugeBoxType.WHITE2 then
		arg_6_0.btnWhite:setBrightStyle(ccui.BrightStyle.normal)
		arg_6_0.btnBlack:setBrightStyle(ccui.BrightStyle.normal)
		arg_6_0.btnWhite2:setBrightStyle(ccui.BrightStyle.highlight)
	else
		arg_6_0.btnWhite:setBrightStyle(ccui.BrightStyle.normal)
		arg_6_0.btnBlack:setBrightStyle(ccui.BrightStyle.highlight)
		arg_6_0.btnWhite2:setBrightStyle(ccui.BrightStyle.normal)
	end
end

function var_0_0.updateList(arg_10_0)
	arg_10_0.list_:reload()
end

function var_0_0.contentView(arg_11_0)
	if arg_11_0.contentView_ == nil then
		arg_11_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_11_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/small_house/box_check_wnd.csb"))
		arg_11_0.contentView_:addTo(arg_11_0)
		arg_11_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_11_0.contentView_
end

function var_0_0.delegate(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = math.ceil(#arg_12_0.ids / var_0_1)

	if cc.ui.UIListView.COUNT_TAG == arg_12_2 then
		return var_12_0
	elseif cc.ui.UIListView.CELL_TAG == arg_12_2 then
		local var_12_1
		local var_12_2
		local var_12_3
		local var_12_4 = arg_12_0.list_:dequeueItem()

		if not var_12_4 then
			var_12_4 = arg_12_0.list_:newItem()
		else
			var_12_4:removeAllChildren()
		end

		local var_12_5 = display.newNode()

		var_12_5:setTouchSwallowEnabled(false)

		for iter_12_0 = 1, var_0_1 do
			local var_12_6 = (arg_12_3 - 1) * var_0_1 + iter_12_0

			if var_12_6 > #arg_12_0.ids then
				break
			end

			var_12_3 = display.newNode()

			arg_12_0:initCell(var_12_3, var_12_6)

			local var_12_7 = var_12_3:getContentSize().width
			local var_12_8 = var_12_3:getContentSize().height
			local var_12_9 = (arg_12_0.list_.viewRect_.width - var_12_7 * var_0_1) / (var_0_1 + 1)

			var_12_3:align(display.CENTER, var_12_9 * iter_12_0 + (iter_12_0 - 1) * var_12_7 + var_12_7 / 2, var_12_8 / 2)
			var_12_5:addChild(var_12_3)
		end

		var_12_5:setContentSize(cc.size(arg_12_0.list_.viewRect_.width, var_12_3:getContentSize().height))
		var_12_4:setItemSize(arg_12_0.list_.viewRect_.width, var_12_3:getContentSize().height)
		var_12_4:addContent(var_12_5)

		return var_12_4
	end
end

function var_0_0.initCell(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_0.ids[arg_13_2]
	local var_13_1 = arg_13_0.boxTable:itemID(arg_13_0.selectIndex, var_13_0)
	local var_13_2 = var_13_1[arg_13_0.idx] or var_13_1[1]
	local var_13_3 = arg_13_0.boxTable:itemNum(arg_13_0.selectIndex, var_13_0)
	local var_13_4 = arg_13_0.boxTable:rarity(arg_13_0.selectIndex, var_13_0)
	local var_13_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/small_house/box_item.csb")
	local var_13_6 = var_13_5:getChildByName("container")
	local var_13_7 = var_13_6:getContentSize()

	var_13_5:addTo(arg_13_1)
	arg_13_1:setContentSize(var_13_7)

	if var_13_4 == 4 then
		var_13_6:getChildByName("special"):setVisible(true)
		var_13_6:getChildByName("epic_txt"):setVisible(false)
		var_13_6:getChildByName("rare_txt"):setVisible(false)
	elseif var_13_4 == 3 then
		var_13_6:getChildByName("epic_txt"):setVisible(true)
		var_13_6:getChildByName("rare_txt"):setVisible(false)
		var_13_6:getChildByName("special"):setVisible(false)
	elseif var_13_4 == 2 then
		var_13_6:getChildByName("epic_txt"):setVisible(false)
		var_13_6:getChildByName("rare_txt"):setVisible(true)
		var_13_6:getChildByName("star_2"):setVisible(false)
		var_13_6:getChildByName("special"):setVisible(false)
		var_13_6:getChildByName("star_1"):setPositionX(var_13_6:getChildByName("star_1"):getPositionX() + 10)
		var_13_6:getChildByName("star_3"):setPositionX(var_13_6:getChildByName("star_3"):getPositionX() - 10)
	else
		var_13_6:getChildByName("epic_txt"):setVisible(false)
		var_13_6:getChildByName("rare_txt"):setVisible(false)
		var_13_6:getChildByName("special"):setVisible(false)
		var_13_6:getChildByName("star_1"):setVisible(false)
		var_13_6:getChildByName("star_3"):setVisible(false)
	end

	xyd.setItemAndAddTips(var_13_6:getChildByName("item"), var_13_2, var_13_3)
end

return var_0_0
