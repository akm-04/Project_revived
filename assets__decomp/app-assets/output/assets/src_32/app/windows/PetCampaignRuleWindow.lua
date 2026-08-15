local var_0_0 = class("PetCampaignRuleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 30

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.floorType = arg_1_2.floorType
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 10 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)

	arg_3_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, 700, 475),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setBounceable(true)
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0:createRuleLabel()

	for iter_4_0 = 1, #var_4_0 do
		local var_4_1 = display.newNode()
		local var_4_2 = arg_4_0.list:newItem()
		local var_4_3 = display.newNode()

		var_4_0[iter_4_0]:addTo(var_4_3)
		var_4_0[iter_4_0]:setAnchorPoint(cc.p(0, 0))
		var_4_0[iter_4_0]:setPosition(0, 0)
		var_4_3:setContentSize(700, var_4_0[iter_4_0]:getContentSize().height)
		var_4_3:addTo(var_4_1)
		var_4_1:setContentSize(700, var_4_0[iter_4_0]:getContentSize().height + 20)
		var_4_2:addContent(var_4_1)
		var_4_2:setItemSize(700, var_4_0[iter_4_0]:getContentSize().height + 20)
		arg_4_0.list:addItem(var_4_2)
	end

	arg_4_0.list:reload()
end

function var_0_0.createRuleLabel(arg_5_0)
	local var_5_0
	local var_5_1

	if arg_5_0.floorType == xyd.PetCampaignFloorType.SUPER then
		local var_5_2 = var_0_1:translation("SKYCITY_HARD_RULE")

		var_5_1 = xyd.luaStringSplit(var_5_2, "|")

		arg_5_0:nodeByName("title_text"):setVisible(true)
		arg_5_0:nodeByName("hire_rule_txt"):setVisible(false)
		arg_5_0:nodeByName("title_text"):setString(var_0_1:translation("SKYCITY_HARD_RULE_TITLE"))
		arg_5_0:nodeByName("hua1"):setPositionX(arg_5_0:nodeByName("hua1"):getPositionX() + var_0_2)
		arg_5_0:nodeByName("hua2"):setPositionX(arg_5_0:nodeByName("hua2"):getPositionX() - var_0_2)
	else
		local var_5_3 = var_0_1:translation("SKYCITY_RULE")

		var_5_1 = xyd.luaStringSplit(var_5_3, "|")
	end

	local var_5_4 = {}

	for iter_5_0 = 1, #var_5_1 do
		local var_5_5 = {
			size = 24,
			color = cc.c3b(255, 255, 255)
		}
		local var_5_6 = xyd.AssetLoader.get():loadLabel(var_5_5)

		var_5_6:setMaxLineWidth(700)
		var_5_6:setString(var_5_1[iter_5_0])
		table.insert(var_5_4, var_5_6)
	end

	return var_5_4
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
	arg_6_0:addBlockLayer()
end

return var_0_0
