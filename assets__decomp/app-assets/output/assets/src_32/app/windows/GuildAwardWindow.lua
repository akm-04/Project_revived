local var_0_0 = class("GuildAwardWindow", import("app.common.ui.BaseWindow"))

var_0_0.TEXT_TITLE = "text_tittle"
var_0_0.TEXT_TOP = "text_top"
var_0_0.TEXT_BOTTOM = "text_bottom"

local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.items = arg_1_2.guild_item
	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0)
	arg_2_0:layout()

	local var_2_0 = var_0_1:translation("GUILD_AWARD_TITLE")
	local var_2_1 = var_0_1:translation("GUILD_AWARD_TOP")
	local var_2_2 = var_0_1:translation("GUILD_AWARD_BOTTOM")
	local var_2_3 = arg_2_0:nodeByName(var_0_0.TEXT_TITLE)
	local var_2_4 = arg_2_0:nodeByName(var_0_0.TEXT_TOP)
	local var_2_5 = arg_2_0:nodeByName(var_0_0.TEXT_BOTTOM)

	var_2_3:setString(var_2_0)
	var_2_4:setString(var_2_1)
	var_2_5:setString(var_2_2)
end

function var_0_0.didOpen(arg_3_0)
	var_0_0.super.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.willClose(arg_4_0)
	var_0_0.super.willClose(arg_4_0)
end

function var_0_0.didClose(arg_5_0)
	var_0_0.super.didClose(arg_5_0)
	arg_5_0:dispatchEvent({
		name = xyd.event.ALERT_AWARD_CLOSE
	})
end

function var_0_0.layout(arg_6_0)
	arg_6_0.showItems = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.items) do
		arg_6_0.showItems[iter_6_1:getTableID()] = (arg_6_0.showItems[iter_6_1:getTableID()] or 0) + 1
	end

	arg_6_0.itemRecord_ = table.keys(arg_6_0.showItems)

	local var_6_0 = arg_6_0:nodeByName("container")

	arg_6_0.touchList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_6_0:getWidth(), var_6_0:getHeight()),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_VCENTER
	}):addTo(var_6_0):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.touchList_:align(display.LEFT_BOTTOM, 0, 0)
	arg_6_0.touchList_:setDelegate(handler(arg_6_0, arg_6_0.delegate))
	arg_6_0.touchList_:reload()
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevX_ = arg_7_1.x
	elseif arg_7_1.name == "moved" and 20 <= math.abs(arg_7_1.x - arg_7_0.prevX_) then
		arg_7_0.scrollViewMoved_ = true
	end
end

function var_0_0.delegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return #arg_8_0.itemRecord_
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_0
		local var_8_1
		local var_8_2 = arg_8_0.touchList_:dequeueItem()

		if not var_8_2 then
			var_8_2 = arg_8_0.touchList_:newItem()
		else
			var_8_2:removeAllChildren()
		end

		local var_8_3 = arg_8_0:nodeByName("container")
		local var_8_4 = display.newNode()

		var_8_4:setTouchSwallowEnabled(false)
		var_8_4:size(var_8_3:getHeight(), var_8_3:getHeight())
		xyd.setItemBorder(var_8_4, arg_8_0.itemRecord_[arg_8_3])
		var_8_4:align(display.LEFT_BOTTOM, 0, 0)

		if table.maxn(arg_8_0.items) == 1 then
			local var_8_5 = {
				top = 0,
				bottom = 0,
				left = 180,
				right = 0
			}

			var_8_2:setMargin(var_8_5)
		end

		if table.maxn(arg_8_0.items) == 2 then
			local var_8_6 = {
				top = 0,
				bottom = 0,
				left = 90,
				right = 0
			}

			var_8_2:setMargin(var_8_6)
		end

		if table.maxn(arg_8_0.items) == 3 then
			local var_8_7 = {
				top = 0,
				bottom = 0,
				left = 40,
				right = 0
			}

			var_8_2:setMargin(var_8_7)
		end

		var_8_2:setItemSize(var_8_4:getWidth() + 10, var_8_4:getHeight())
		var_8_2:addContent(var_8_4)

		local var_8_8 = arg_8_0.showItems[arg_8_0.itemRecord_[arg_8_3]]
		local var_8_9 = {
			size = 22,
			y = 5,
			text = tostring(var_8_8),
			color = cc.c3b(255, 255, 255),
			align = cc.ui.TEXT_ALIGN_CENTER,
			valign = cc.ui.TEXT_VALIGN_TOP,
			x = var_8_4:getWidth() - 10
		}

		if var_8_8 > 1 then
			local var_8_10 = xyd.AssetLoader.get():loadLabel(var_8_9)

			var_8_10:addTo(var_8_4)
			var_8_10:setAnchorPoint(1, 0)
		end

		local var_8_11 = arg_8_0:getPlusType(arg_8_0.itemRecord_[arg_8_3])
		local var_8_12 = {
			id = arg_8_0.itemRecord_[arg_8_3]
		}

		arg_8_0:addTips(var_8_4, var_8_12)

		return var_8_2
	end
end

function var_0_0.getPlusType(arg_9_0, arg_9_1)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in pairs(arg_9_0.player_.heros_) do
		if iter_9_1:getItemHeroHasNotEquip(arg_9_1) then
			local var_9_1 = {}

			if xyd.tables.item:level(arg_9_1) > iter_9_1:getLevel() then
				var_9_1 = {
					plusType = 0,
					hero = iter_9_1
				}
			else
				var_9_1 = {
					plusType = 1,
					hero = iter_9_1
				}
			end

			table.insert(var_9_0, var_9_1)
		end
	end

	return var_9_0
end

return var_0_0
