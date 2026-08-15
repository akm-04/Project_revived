local var_0_0 = class("RagnarokGachaDisplayWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = xyd.tables.ragnarokGachaTable
local var_0_4 = {
	title = var_0_1:translation("RAGNAROK_GACHA_1"),
	rare = var_0_1:translation("RAGNAROK_GACHA_4"),
	normal = var_0_1:translation("RAGNAROK_GACHA_5")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2 or {})
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	local var_2_0 = arg_2_0:nodeByName("list")
	local var_2_1 = var_2_0:getContentSize()

	arg_2_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):onScroll(handler(arg_2_0, arg_2_0.scrollListener)):setBounceable(true):pos(0, 0):addTo(var_2_0)

	arg_2_0:layout()
end

function var_0_0.scrollListener(arg_3_0, arg_3_1)
	if arg_3_1.name == "began" then
		arg_3_0.scrollViewMoved_ = false
		arg_3_0.prevX_ = arg_3_1.x
		arg_3_0.prevY_ = arg_3_1.y
	elseif arg_3_1.name == "moved" and 5 <= math.abs(arg_3_1.y - arg_3_0.prevY_) then
		arg_3_0.scrollViewMoved_ = true
	end
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayer()
end

function var_0_0.didClose(arg_5_0, arg_5_1)
	var_0_0.super.didClose(arg_5_0, arg_5_1)
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("title"):setString(var_0_4.title)
	arg_6_0:initList()
end

function var_0_0.initList(arg_7_0)
	local var_7_0 = {}
	local var_7_1 = {}

	for iter_7_0 = 1, #var_0_3:getItemIds() do
		if var_0_3:isPrevisible(iter_7_0) == 1 then
			table.insert(var_7_0, iter_7_0)
		else
			table.insert(var_7_1, iter_7_0)
		end
	end

	local var_7_2 = arg_7_0.list:newItem()
	local var_7_3 = display.newNode()

	arg_7_0.rareContainer = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1203/reward_odin/reward_item.csb")
	arg_7_0.normalContainer = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1203/reward_odin/reward_item.csb")

	local var_7_4 = 0

	arg_7_0.normalContainer:getChildByName("container"):getChildByName("txt_title"):setString(var_0_4.normal)

	local var_7_5 = 6
	local var_7_6 = math.ceil(#var_7_1 / var_7_5)
	local var_7_7 = var_7_4 + var_7_6 * 94

	for iter_7_1 = 1, var_7_6 do
		for iter_7_2 = 1, var_7_5 do
			local var_7_8 = var_0_3:getItemIdById(var_7_1[(iter_7_1 - 1) * var_7_5 + iter_7_2])
			local var_7_9 = var_0_3:getItemNumById(var_7_1[(iter_7_1 - 1) * var_7_5 + iter_7_2])

			if var_7_8 == 0 then
				break
			end

			local var_7_10 = display.newNode()

			var_7_10:setContentSize(85, 85)
			var_7_10:setAnchorPoint(cc.p(0, 0))
			var_7_10:addTo(arg_7_0.normalContainer)
			var_7_10:setPosition(cc.p(27 + (iter_7_2 - 1) * 110, 13 - iter_7_1 * 94))
			xyd.setItemAndAddTips(var_7_10, var_7_8, var_7_9)
		end
	end

	arg_7_0.normalContainer:addTo(var_7_3)
	arg_7_0.normalContainer:setPosition(0, var_7_7)

	local var_7_11 = var_7_7 + arg_7_0.normalContainer:getChildByName("container"):getContentSize().height

	arg_7_0.rareContainer:getChildByName("container"):getChildByName("txt_title"):setString(var_0_4.rare)

	local var_7_12 = 6
	local var_7_13 = math.ceil(#var_7_0 / var_7_12)
	local var_7_14 = var_7_11 + var_7_13 * 94

	for iter_7_3 = 1, var_7_13 do
		for iter_7_4 = 1, var_7_12 do
			local var_7_15 = var_0_3:getItemIdById(var_7_0[(iter_7_3 - 1) * var_7_12 + iter_7_4])
			local var_7_16 = var_0_3:getItemNumById(var_7_0[(iter_7_3 - 1) * var_7_12 + iter_7_4])

			if var_7_15 == 0 then
				break
			end

			local var_7_17 = display.newNode()

			var_7_17:setContentSize(85, 85)
			var_7_17:setAnchorPoint(cc.p(0, 0))
			var_7_17:addTo(arg_7_0.rareContainer)
			var_7_17:setPosition(cc.p(27 + (iter_7_4 - 1) * 110, 13 - iter_7_3 * 94))
			xyd.setItemAndAddTips(var_7_17, var_7_15, var_7_16)
		end
	end

	arg_7_0.rareContainer:addTo(var_7_3)
	arg_7_0.rareContainer:setPosition(0, var_7_14)

	local var_7_18 = var_7_14 + arg_7_0.rareContainer:getChildByName("container"):getContentSize().height
	local var_7_19 = arg_7_0:nodeByName("list"):getContentSize()

	var_7_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_7_3:setContentSize(var_7_19.width, var_7_18)
	var_7_3:setPosition(cc.p(0, 0))
	var_7_2:addContent(var_7_3)
	var_7_2:setItemSize(var_7_19.width, var_7_18)
	arg_7_0.list:addItem(var_7_2)
	arg_7_0.list:reload()
end

return var_0_0
