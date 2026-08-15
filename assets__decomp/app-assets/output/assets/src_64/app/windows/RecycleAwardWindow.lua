local var_0_0 = class("RecycleAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SplitLine")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backPack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.resolveTypes = arg_1_2.resolve_types
	arg_1_0.resolveNums = arg_1_2.resolve_nums
	arg_1_0.resolveCrits = arg_1_2.resolve_crits
	arg_1_0.title = arg_1_2.title

	arg_1_0:handleBackpack()
end

function var_0_0.handleBackpack(arg_2_0)
	for iter_2_0 = 1, #arg_2_0.resolveTypes do
		if arg_2_0.resolveTypes[iter_2_0] > 1000000 and arg_2_0.resolveNums[iter_2_0] > 0 then
			local var_2_0 = arg_2_0.resolveTypes[iter_2_0]
			local var_2_1 = arg_2_0.resolveNums[iter_2_0]

			if not arg_2_0.backPack:getItemByID(var_2_0) then
				local var_2_2 = {}

				var_2_2.itemNum = 0
				var_2_2.itemID = var_2_0

				arg_2_0.backPack:addItem(var_2_2)
			end

			arg_2_0.backPack:addItemsByID(var_2_0, var_2_1)
		end
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	if arg_4_0.title then
		arg_4_0:nodeByName("txt_title"):setString(arg_4_0.title)
	else
		arg_4_0:nodeByName("txt_title"):setVisible(false)
	end

	arg_4_0:nodeByName("title_txt"):setString(var_0_1:translation("RESOURCES_GET"))
	arg_4_0:nodeByName("txt_ok"):setString(var_0_1:translation("OK"))

	local var_4_0 = {
		viewRect = cc.rect(0, 0, arg_4_0:nodeByName("award_container"):getContentSize().width, arg_4_0:nodeByName("award_container"):getContentSize().height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}

	arg_4_0.listview = cc.ui.UIListView.new(var_4_0):addTo(arg_4_0:nodeByName("award_container")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	for iter_4_0 = 1, #arg_4_0.resolveTypes do
		local var_4_1 = arg_4_0.listview:newItem()
		local var_4_2 = arg_4_0:createItemContent(arg_4_0.resolveTypes[iter_4_0], arg_4_0.resolveNums[iter_4_0], arg_4_0.resolveCrits[iter_4_0])

		var_4_1:addContent(var_4_2)
		var_4_1:setItemSize(var_4_2:getContentSize().width, var_4_2:getContentSize().height + 20)
		arg_4_0.listview:addItem(var_4_1)
	end

	arg_4_0.listview:reload()
	var_0_2.new({
		size = 500
	}):addTo(arg_4_0:nodeByName("pos_line"))
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_ok"), nil, function(arg_5_0)
		arg_4_0:close()
	end)
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevY_ = arg_6_1.y
	elseif arg_6_1.name == "moved" and 20 <= math.abs(arg_6_1.y - arg_6_0.prevY_) then
		arg_6_0.scrollViewMoved_ = true
	end
end

function var_0_0.createItemContent(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = display.newNode()
	local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/event_centre/recycle/award_item.csb")
	local var_7_2 = var_7_1:getChildByName("container")
	local var_7_3 = var_7_2:getChildByName("item_icon_container")

	var_7_3:removeAllChildren()

	local var_7_4 = var_7_2:getChildByName("item_num_txt")
	local var_7_5 = var_7_2:getChildByName("name_txt")
	local var_7_6
	local var_7_7

	if arg_7_1 == 11 then
		var_7_6 = "images/icon/eco/magic_dust_small.png"
		var_7_7 = var_0_1:translation("MAGIC_DUST")
	elseif arg_7_1 == 12 then
		var_7_6 = "images/icon/eco/magic_liquid_small.png"
		var_7_7 = var_0_1:translation("MAGIC_LIQUID")
	elseif arg_7_1 == 13 then
		var_7_6 = "images/icon/eco/magic_energy_small.png"
		var_7_7 = var_0_1:translation("MAGIC_ENERGY")
	elseif arg_7_1 == 14 then
		var_7_6 = "images/icon/eco/magic_exp.png"
		var_7_7 = var_0_1:translation("MAGIC_EXP")
	end

	if var_7_6 then
		arg_7_0:setSpriteBorder(var_7_3, var_7_6)
	end

	if arg_7_1 > 14 then
		xyd.setItemBorder(var_7_3, arg_7_1)

		var_7_7 = xyd.tables.item:name(arg_7_1)
	end

	if var_7_7 then
		var_7_5:setString(var_7_7)
	end

	var_7_4:setString("x" .. arg_7_2)
	var_7_4:setPositionX(var_7_5:getPositionX() + var_7_5:getContentSize().width + 10)

	if arg_7_3 and arg_7_3 > 1 then
		var_7_2:getChildByName("txt_crit_num"):setString(arg_7_3)
	else
		var_7_2:getChildByName("txt_crit"):setVisible(false)
		var_7_2:getChildByName("txt_crit_num"):setVisible(false)
	end

	var_7_1:addTo(var_7_0)
	var_7_1:setAnchorPoint(cc.p(0, 0))
	var_7_0:setContentSize(var_7_2:getContentSize())
	var_7_1:setName("source")

	return var_7_0
end

function var_0_0.setSpriteBorder(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = xyd.AssetLoader:get():loadSprite(arg_8_2)

	var_8_0:addTo(arg_8_1)
	var_8_0:setAnchorPoint(0.5, 0.5)
	var_8_0:setPosition(arg_8_1:getContentSize().width / 2, arg_8_1:getContentSize().height / 2)
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	var_0_0.super:didOpen(arg_9_1)
	arg_9_0:addBlockLayer()
end

return var_0_0
