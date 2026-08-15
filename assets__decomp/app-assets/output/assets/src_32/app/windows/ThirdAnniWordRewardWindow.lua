local var_0_0 = class("ThirdAnniWordRewardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.ThirdAnniversaryWordReward
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.gift

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.scroll = arg_2_0:nodeByName("scroll")

	local var_2_0 = arg_2_0.scroll:getContentSize()

	arg_2_0.scrollList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_2_0.width, var_2_0.height),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_2_0.scroll)

	arg_2_0.scrollList:setBounceable(true)
	arg_2_0:updateRewards()
end

function var_0_0.updateRewards(arg_3_0)
	local var_3_0 = var_0_1:ids()

	for iter_3_0 = 1, #var_3_0 do
		local var_3_1 = var_0_1:gift(var_3_0[iter_3_0])
		local var_3_2 = var_0_3:items(var_3_1)
		local var_3_3 = var_0_3:itemNum(var_3_1)
		local var_3_4 = arg_3_0.scrollList:newItem()
		local var_3_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary3rd/word_collection/award/award_item.csb")
		local var_3_6 = var_3_5:getChildByName("container")

		var_3_6:getChildByName("award_txt"):setString(var_0_2:translation("THIRD_ANNI_WORD_REWARD" .. iter_3_0))
		var_3_6:getChildByName("award_txt"):enableOutline(cc.c4b(165, 94, 42, 255), 0)

		for iter_3_1 = 1, #var_3_2 do
			local var_3_7 = display.newNode()

			var_3_7:setContentSize(85, 85)
			xyd.setItemAndAddTips(var_3_7, var_3_2[iter_3_1], var_3_3[iter_3_1])
			var_3_7:addTo(var_3_6:getChildByName("item_pos"))
			var_3_7:setAnchorPoint(cc.p(0.5, 0.5))
			var_3_7:setPosition(iter_3_1 * 93 - 93, 0)
		end

		local var_3_8 = var_3_6:getContentSize()

		var_3_5:setAnchorPoint(cc.p(0, 0))
		var_3_5:setContentSize(var_3_8.width, var_3_8.height)
		var_3_4:setItemSize(var_3_8.width, var_3_8.height)
		var_3_4:addContent(var_3_5)
		arg_3_0.scrollList:addItem(var_3_4)
	end

	arg_3_0.scrollList:reload()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:addBlockLayer()
end

return var_0_0
