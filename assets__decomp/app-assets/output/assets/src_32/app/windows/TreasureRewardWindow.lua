local var_0_0 = class("TreasureRewardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.treasureLocation
local var_0_3 = xyd.tables.treasureType
local var_0_4 = 1
local var_0_5 = 60
local var_0_6 = import("app.common.ui.SplitLine")
local var_0_7 = 40
local var_0_8 = 20
local var_0_9 = 35
local var_0_10 = 30

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.treasureModel = xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE)
	arg_1_0.locationId = arg_1_2.locationId
	arg_1_0.locationName = arg_1_2.locationName
	arg_1_0.typeId = arg_1_2.typeId
	arg_1_0.reward = arg_1_2.reward
	arg_1_0.datas = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:sortReward()
	arg_2_0:layout()
end

function var_0_0.sortReward(arg_3_0)
	local var_3_0 = arg_3_0.reward.normal_award

	if var_3_0 and var_3_0.award_type then
		var_3_0.isNormal = true

		if var_3_0.award_type == xyd.TreasureProductType.STONE then
			for iter_3_0, iter_3_1 in pairs(var_3_0.items) do
				local var_3_1 = {
					item_num = iter_3_1.item_num,
					item_id = iter_3_1.item_id
				}

				table.insert(arg_3_0.datas, var_3_1)
			end
		else
			table.insert(arg_3_0.datas, var_3_0)
		end
	end

	if arg_3_0.reward.externa_crystal_award ~= 0 then
		local var_3_2 = {
			item_id = -1,
			item_num = arg_3_0.reward.externa_crystal_award
		}

		table.insert(arg_3_0.datas, var_3_2)
	end

	local var_3_3 = arg_3_0.reward.battle_award
	local var_3_4 = arg_3_0.reward.chest_award

	if var_3_3 and var_3_3.item_num then
		table.insert(arg_3_0.datas, var_3_3)
	end

	if var_3_4 and var_3_4.item_num then
		table.insert(arg_3_0.datas, var_3_4)
	end

	for iter_3_2, iter_3_3 in pairs(arg_3_0.datas) do
		if iter_3_3.item_id and iter_3_3.item_id > 0 then
			arg_3_0.selfPlayer:getBackpack():addItemsByID(tonumber(iter_3_3.item_id), tonumber(iter_3_3.item_num))
		elseif iter_3_3.award_type == xyd.TreasureProductType.STONE then
			for iter_3_4, iter_3_5 in pairs(iter_3_3.items) do
				arg_3_0.selfPlayer:getBackpack():addItemsByID(tonumber(iter_3_5.item_id), tonumber(iter_3_5.item_num))
			end
		end
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_title"):setString(var_0_1:translation("TREASURE_OVER_TITLE"))
	arg_4_0:nodeByName("txt_ok"):setString(var_0_1:translation("OK"))

	local var_4_0 = var_0_3:name(arg_4_0.typeId)

	arg_4_0:nodeByName("txt_address"):setString(arg_4_0.locationName .. " " .. var_4_0)
	arg_4_0:nodeByName("txt_address"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_4_0:nodeByName("btn_ok"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("btn_ok"), arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)

	arg_4_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(1, 1, arg_4_0:nodeByName("list_award"):getWidth(), arg_4_0:nodeByName("list_award"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("list_award")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.listView_:setBounceable(true)
	arg_4_0.listView_:setAnchorPoint(cc.p(0, 0))
	arg_4_0.listView_:setDelegate(handler(arg_4_0, arg_4_0.delegate))
	arg_4_0.listView_:reload()

	local var_4_1 = 490
	local var_4_2 = {
		size = var_4_1,
		align = xyd.SplitLineAlign.CENTER
	}
	local var_4_3 = var_0_6.new(var_4_2)

	var_4_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_3:addTo(arg_4_0:nodeByName("background"))
	var_4_3:setPosition(arg_4_0:nodeByName("background"):getWidth() / 2, 133)
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	arg_6_0:addBlockLayer()
	var_0_0.super:didOpen(arg_6_1)
end

function var_0_0.delegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return #arg_7_0.datas
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		return arg_7_0:updateListView(arg_7_2, arg_7_3)
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_7_2 then
		-- block empty
	end
end

function var_0_0.updateListView(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0
	local var_8_1 = arg_8_0.listView_:dequeueItem()

	if not var_8_1 then
		var_8_1 = arg_8_0.listView_:newItem()
	else
		var_8_1:removeAllChildren(true)
	end

	local var_8_2 = display.newNode()

	if arg_8_2 <= #arg_8_0.datas and arg_8_2 > 0 then
		local var_8_3 = display.newNode()

		arg_8_0:initCell(var_8_3, arg_8_0.datas[arg_8_2])
		var_8_2:addChild(var_8_3)
		var_8_3:setPosition(70, 0)
	end

	var_8_1:setItemSize(arg_8_0:nodeByName("list_award"):getWidth(), var_0_5 + 15)
	var_8_2:setContentSize(arg_8_0:nodeByName("list_award"):getWidth(), var_0_5 + 15)
	var_8_1:addContent(var_8_2)

	return var_8_1
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.startClick_ = true
		arg_9_0.prevY_ = arg_9_1.y
	elseif arg_9_1.name == "moved" and 20 <= math.abs(arg_9_1.y - arg_9_0.prevY_) then
		arg_9_0.startClick_ = false
	end

	arg_9_0.originY = arg_9_0.listView_.scrollNode:getPositionY()
end

function var_0_0.initCell(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = {}

	if arg_10_2.isNormal then
		if arg_10_2.award_type == xyd.TreasureProductType.MANA then
			var_10_0.item_id = -2
			var_10_0.item_num = arg_10_2.item_num
		elseif arg_10_2.award_type == xyd.TreasureProductType.DRINK then
			var_10_0 = arg_10_2
		elseif arg_10_2.award_type == xyd.TreasureProductType.STONE then
			var_10_0.item_id = -4
			var_10_0.item_num = 0
			var_10_0.items = arg_10_2.items

			for iter_10_0, iter_10_1 in pairs(arg_10_2.items) do
				var_10_0.item_num = var_10_0.item_num + iter_10_1.item_num
			end
		elseif arg_10_2.award_type == xyd.TreasureProductType.DUST then
			var_10_0.item_id = -11
			var_10_0.item_num = arg_10_2.item_num
		elseif arg_10_2.award_type == xyd.TreasureProductType.LIQUID then
			var_10_0.item_id = -12
			var_10_0.item_num = arg_10_2.item_num
		else
			var_10_0 = arg_10_2
		end
	else
		var_10_0 = arg_10_2
	end

	local var_10_1 = xyd.setItemWithTextNode(var_10_0.item_id, nil, nil, var_0_5)
	local var_10_2 = display.newNode()

	var_10_2:addChild(var_10_1)

	local var_10_3 = {
		size = 28,
		color = cc.c4b(255, 120, 0, 255)
	}
	local var_10_4 = {
		size = 28,
		color = cc.c4b(52, 54, 55, 255)
	}
	local var_10_5 = xyd.AssetLoader:get():loadLabel(var_10_3)
	local var_10_6 = 0

	if var_10_0.item_id < 0 then
		var_10_5:setString("x " .. var_10_0.item_num)
	else
		local var_10_7 = xyd.tables.item:name(var_10_0.item_id)
		local var_10_8 = xyd.AssetLoader:get():loadLabel(var_10_4)

		var_10_8:setString(var_10_7)
		var_10_8:setPosition(var_0_5 + 20, var_10_1:getHeight() / 2)
		var_10_2:addChild(var_10_8)

		var_10_6 = var_10_8:getContentSize().width

		var_10_5:setString(" x " .. var_10_0.item_num)
	end

	var_10_5:setPosition(var_0_5 + var_10_6 + 40, var_10_1:getHeight() / 2)
	var_10_2:addChild(var_10_5)
	arg_10_1:addChild(var_10_2)
end

return var_0_0
