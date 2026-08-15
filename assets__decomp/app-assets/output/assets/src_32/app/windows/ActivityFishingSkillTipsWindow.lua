local var_0_0 = class("ActivityFishingSkillTipsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.activityFish

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.id = arg_1_2.id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = cc.ui.UITableView.new({
		itemGap = 6,
		size = arg_4_0:nodeByName("skill_container"):getContentSize(),
		direction = cc.ui.UITableView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("skill_container"))
	local var_4_1 = display.newNode()
	local var_4_2 = var_4_0:newItem()
	local var_4_3 = xyd.AssetLoader.get():loadSprite("windows/activities/1226/skill_icon/" .. arg_4_0.id .. ".png")
	local var_4_4 = xyd.AssetLoader.get():loadSprite("windows/activities/1226/skill_icon/border.png")
	local var_4_5 = xyd.createLabel(24, cc.c3b(100, 255, 253))

	var_4_3:setPosition(35, 35)
	var_4_3:setScale(0.64)
	var_4_4:setPosition(35, 35)
	var_4_4:setScale(0.64)
	var_4_5:setPosition(75, 35)
	var_4_5:setString(var_0_1:skill(arg_4_0.id))
	var_4_1:addChild(var_4_3)
	var_4_1:addChild(var_4_4)
	var_4_1:addChild(var_4_5)
	var_4_2:addContent(var_4_1)
	var_4_2:setItemSize(300, 70)
	var_4_0:addItem(var_4_2)

	local var_4_6 = display.newScale9Sprite("windows/new_item_tips/split.png", 0, 0, cc.size(300, 8), cc.rect(40, 0, 226, 8))
	local var_4_7 = var_4_0:newItem()

	var_4_7:addContent(var_4_6)
	var_4_7:setItemSize(300, 8)
	var_4_0:addItem(var_4_7)

	local var_4_8 = xyd.createLabel(20, cc.c3b(255, 255, 255))

	var_4_8:setAnchorPoint(0, 0)
	var_4_8:setWidth(290)
	var_4_8:setString(var_0_1:skillDesc(arg_4_0.id))

	local var_4_9 = var_4_0:newItem()

	var_4_9:addContent(var_4_8)
	var_4_9:setItemSize(300, var_4_8:getContentSize().height)
	var_4_0:addItem(var_4_9)
	var_4_0:reload()
end

return var_0_0
