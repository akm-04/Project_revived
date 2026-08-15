local var_0_0 = class("ThrowSandbagResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.throwSandbag = xyd.ModelManager.get():loadModel(xyd.ModelType.ALL_NIGHT)
	arg_1_0.awards = arg_1_2.awards
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = 0

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.awards.self) do
		var_3_0 = var_3_0 + iter_3_1.num

		arg_3_0.selfPlayer:getBackpack():addItemsByID(iter_3_1.itemID, iter_3_1.num)
	end

	for iter_3_2, iter_3_3 in ipairs(arg_3_0.awards.friend) do
		var_3_0 = var_3_0 + iter_3_3.num
	end

	arg_3_0:nodeByName("text_title"):setString(var_0_1:translation("THROW_SANDBAG_TEXT_9"))
	arg_3_0:nodeByName("desc"):setString(string.format(var_0_1:translation("THROW_SANDBAG_TEXT_10"), var_3_0))
	arg_3_0:nodeByName("text_ok"):setString(var_0_1:translation("OK"))
	arg_3_0:nodeByName("btn_ok"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playCloseSound()

			local var_4_0 = xyd.WindowManager.get():getWindow("throw_sandbag")

			if var_4_0 then
				var_4_0:close()
			end

			arg_3_0:close()
		end
	end)
	arg_3_0:initData()

	arg_3_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_3_0:nodeByName("list"):getWidth(), arg_3_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setBounceable(true)
	arg_3_0.list:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.list:reload()
end

function var_0_0.initData(arg_5_0)
	arg_5_0.items_ = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.awards.self) do
		table.insert(arg_5_0.items_, iter_5_1)
	end

	for iter_5_2, iter_5_3 in ipairs(arg_5_0.awards.friend) do
		table.insert(arg_5_0.items_, iter_5_3)
	end
end

function var_0_0.delegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = math.ceil(#arg_6_0.items_ / var_0_2)

	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return var_6_0
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		if var_6_0 < arg_6_3 then
			return nil
		end

		local var_6_1 = arg_6_0.list:dequeueItem()

		if not var_6_1 then
			var_6_1 = arg_6_0.list:newItem()
		else
			var_6_1:removeAllChildren(true)
		end

		local var_6_2 = display.newNode()

		arg_6_0:initCell(var_6_2, arg_6_3)

		local var_6_3 = display.newNode()

		var_6_3:addChild(var_6_2)
		var_6_3:setContentSize(var_6_2:getContentSize())
		var_6_1:setItemSize(var_6_2:getContentSize().width, var_6_2:getContentSize().height)
		var_6_1:addContent(var_6_3)

		return var_6_1
	end
end

function var_0_0.initCell(arg_7_0, arg_7_1, arg_7_2)
	for iter_7_0 = 1, var_0_2 do
		local var_7_0 = (arg_7_2 - 1) * var_0_2 + iter_7_0

		if var_7_0 > #arg_7_0.items_ then
			break
		end

		local var_7_1 = arg_7_0.items_[var_7_0]
		local var_7_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/throw_sandbag/result/icon.csb")
		local var_7_3 = var_7_2:getChildByName("container")

		xyd.setItemAndAddTips(var_7_3:getChildByName("icon"), var_7_1.itemID)
		var_7_3:getChildByName("icon_choose"):setVisible(var_7_1.isDouble or false)
		var_7_3:getChildByName("icon_friend"):setVisible(var_7_1.isFriend or false)

		local var_7_4 = xyd.tables.item:heroID(var_7_1.itemID)

		if var_7_4 and var_7_4 ~= 0 then
			var_7_3:getChildByName("txt"):setString(xyd.tables.hero:name(var_7_4) .. " X" .. var_7_1.num)
		else
			var_7_3:getChildByName("txt"):setString(xyd.tables.item:name(var_7_1.itemID) .. " X" .. var_7_1.num)
		end

		var_7_2:addTo(arg_7_1)
		var_7_2:setPosition((iter_7_0 - 3) * (var_7_3:getWidth() + 38) + arg_7_0:nodeByName("list"):getWidth() / 2 - var_7_3:getWidth() / 2, 30)
	end

	arg_7_1:setContentSize(arg_7_0:nodeByName("list"):getWidth(), 150)
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.startClick_ = true
		arg_8_0.prevX_ = arg_8_1.x
	elseif arg_8_1.name == "moved" and 20 <= math.abs(arg_8_1.x - arg_8_0.prevX_) then
		arg_8_0.startClick_ = false
	end
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	arg_9_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
