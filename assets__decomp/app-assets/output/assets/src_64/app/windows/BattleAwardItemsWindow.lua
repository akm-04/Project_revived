local var_0_0 = class("BattleAwardItems", import("app.common.ui.BaseWindow"))

var_0_0.TEXT_TITLE = "txt_tittle"
var_0_0.TEXT_TOP = "txt_top"
var_0_0.TEXT_BOTTOM = "txt_bottom"

local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.items = arg_1_2.items
	arg_1_0.texts_ = arg_1_2.labels or {}
	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0)
	arg_2_0:layout()

	local var_2_0 = arg_2_0:nodeByName(var_0_0.TEXT_TITLE)
	local var_2_1 = arg_2_0:nodeByName(var_0_0.TEXT_TOP)
	local var_2_2 = arg_2_0:nodeByName(var_0_0.TEXT_BOTTOM)

	var_2_0:setString(arg_2_0.texts_[1] or "")
	var_2_1:setString(arg_2_0.texts_[2] or "")
	var_2_2:setString(arg_2_0.texts_[3] or "")
end

function var_0_0.didOpen(arg_3_0)
	var_0_0.super.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
	arg_3_0:confirmButton()
end

function var_0_0.confirmButton(arg_4_0)
	if not arg_4_0.confirmButton_ then
		arg_4_0.confirmButton_ = arg_4_0:nodeByName("btn_ok")

		arg_4_0:nodeByName("txt_ok"):setString(xyd.tables.translation:translation("OK"))
		xyd.nodeEventSample(arg_4_0.confirmButton_, nil, function(arg_5_0)
			xyd.playButtonSound()
			arg_4_0:close()
		end)
	end

	return arg_4_0.confirmButton_
end

function var_0_0.willClose(arg_6_0)
	var_0_0.super.willClose(arg_6_0)
	arg_6_0:dispatchEvent({
		name = xyd.event.ALERT_AWARD_CLOSE
	})
end

function var_0_0.didClose(arg_7_0)
	var_0_0.super.didClose(arg_7_0)
end

function var_0_0.layout(arg_8_0)
	arg_8_0.showItems = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.items) do
		arg_8_0.showItems[iter_8_1:getTableID()] = (arg_8_0.showItems[iter_8_1:getTableID()] or 0) + 1
	end

	arg_8_0.itemRecord_ = table.keys(arg_8_0.showItems)

	local var_8_0 = arg_8_0:nodeByName("container")

	arg_8_0.touchList_ = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_8_0:getWidth(), var_8_0:getHeight()),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_VCENTER
	}):addTo(var_8_0):onScroll(handler(arg_8_0, arg_8_0.scrollListener))

	arg_8_0.touchList_:align(display.LEFT_BOTTOM, 0, 0)

	for iter_8_2 = 1, #arg_8_0.itemRecord_ do
		arg_8_0:createListItems(iter_8_2)
	end

	arg_8_0.touchList_:reload()
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevX_ = arg_9_1.x
	elseif arg_9_1.name == "moved" and 20 <= math.abs(arg_9_1.x - arg_9_0.prevX_) then
		arg_9_0.scrollViewMoved_ = true
	end
end

function var_0_0.createListItems(arg_10_0, arg_10_1)
	local var_10_0 = math.min(#arg_10_0.itemRecord_, 4)
	local var_10_1 = arg_10_0.touchList_:newItem()
	local var_10_2 = arg_10_0:nodeByName("container")
	local var_10_3 = var_10_2:getWidth()
	local var_10_4 = var_10_2:getHeight()
	local var_10_5 = display.newNode()

	var_10_5:size(var_10_4, var_10_4)
	xyd.setItemBorder(var_10_5, arg_10_0.itemRecord_[arg_10_1])
	var_10_5:align(display.LEFT_BOTTOM, 0, 0)

	local var_10_6 = (var_10_3 - var_10_4 * var_10_0) / (var_10_0 + 1)
	local var_10_7 = arg_10_1 == 1 and var_10_6 or var_10_6 / 2
	local var_10_8 = arg_10_1 == #arg_10_0.itemRecord_ and var_10_6 or var_10_6 / 2

	var_10_1:setMargin({
		top = 0,
		bottom = 0,
		left = var_10_7,
		right = var_10_8
	})
	var_10_1:setItemSize(var_10_4, var_10_4)
	var_10_1:addContent(var_10_5)

	local var_10_9 = arg_10_0.showItems[arg_10_0.itemRecord_[arg_10_1]]
	local var_10_10 = {
		size = 22,
		y = 5,
		text = tostring(var_10_9),
		color = cc.c3b(255, 255, 255),
		align = cc.ui.TEXT_ALIGN_CENTER,
		valign = cc.ui.TEXT_VALIGN_TOP,
		x = var_10_5:getWidth() - 10
	}

	if var_10_9 > 1 then
		local var_10_11 = xyd.AssetLoader.get():loadLabel(var_10_10)

		var_10_11:addTo(var_10_5)
		var_10_11:setAnchorPoint(1, 0)
		var_10_11:enableOutline(cc.c4b(0, 0, 0, 255), 2)
	end

	local var_10_12 = arg_10_0:getPlusType(arg_10_0.itemRecord_[arg_10_1])
	local var_10_13 = {
		id = arg_10_0.itemRecord_[arg_10_1]
	}

	xyd.addTips(var_10_5, var_10_13)
	arg_10_0.touchList_:addItem(var_10_1)
end

function var_0_0.getPlusType(arg_11_0, arg_11_1)
	local var_11_0 = {}

	for iter_11_0, iter_11_1 in pairs(arg_11_0.player_.heros_) do
		if iter_11_1:getItemHeroHasNotEquip(arg_11_1) then
			local var_11_1 = {}

			if xyd.tables.item:level(arg_11_1) > iter_11_1:getLevel() then
				var_11_1 = {
					plusType = 0,
					hero = iter_11_1
				}
			else
				var_11_1 = {
					plusType = 1,
					hero = iter_11_1
				}
			end

			table.insert(var_11_0, var_11_1)
		end
	end

	return var_11_0
end

return var_0_0
