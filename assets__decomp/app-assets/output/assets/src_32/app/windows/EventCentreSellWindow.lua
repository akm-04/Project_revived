local var_0_0 = class("EventCentreSellWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = 60
local var_0_2 = 380
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack_ = arg_1_0.player_:getBackpack()
end

function var_0_0.initEventCentreSellWindow(arg_2_0)
	arg_2_0:nodeByName("text_tip"):setString(var_0_3:translation("TIP"))
	arg_2_0:nodeByName("txt_ok"):setString(var_0_3:translation("OK"))

	local var_2_0 = arg_2_0:nodeByName("scroll"):getContentSize()
	local var_2_1 = {
		viewRect = cc.rect(0, 0, var_2_0.width, var_2_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}

	arg_2_0.listview = cc.ui.UIListView.new(var_2_1):addTo(arg_2_0:nodeByName("scroll")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))
end

function var_0_0.scrollListener(arg_3_0, arg_3_1)
	if arg_3_1.name == "began" then
		arg_3_0.scrollViewMoved_ = false
		arg_3_0.prevY_ = arg_3_1.y
	elseif arg_3_1.name == "moved" and 20 <= math.abs(arg_3_1.y - arg_3_0.prevY_) then
		arg_3_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	arg_4_0:nodeByName("text_willget"):setString(var_0_3:translation("SELL_WILLGET"))
	arg_4_0:nodeByName("txt_title"):setString(var_0_3:translation("USE_MAGIC"))

	local var_4_0 = 0
	local var_4_1 = 0
	local var_4_2 = 0
	local var_4_3 = arg_4_1.items
	local var_4_4 = #var_4_3
	local var_4_5 = math.ceil(var_4_4 / 2)

	arg_4_0:initEventCentreSellWindow()

	for iter_4_0 = 1, var_4_5 do
		local var_4_6 = 2

		if iter_4_0 == var_4_5 then
			var_4_6 = var_4_4 % 2

			if var_4_6 == 0 then
				var_4_6 = 2
			end
		end

		local var_4_7 = display.newNode()
		local var_4_8 = arg_4_0.listview:newItem()

		for iter_4_1 = 1, var_4_6 do
			local var_4_9 = var_4_3[(iter_4_0 - 1) * 2 + iter_4_1]
			local var_4_10 = var_0_4:name(var_4_9.item_id)
			local var_4_11 = var_0_4:magicEnergy(var_4_9.item_id)
			local var_4_12 = var_0_4:magicDust(var_4_9.item_id)
			local var_4_13 = var_0_4:magicLiquid(var_4_9.item_id)
			local var_4_14 = var_4_9.item_num

			if var_4_11 ~= nil and var_4_11 ~= 0 then
				var_4_2 = var_4_2 + var_4_11 * var_4_14
			elseif var_4_12 ~= nil and var_4_12 ~= 0 then
				var_4_0 = var_4_0 + var_4_12 * var_4_14
			elseif var_4_13 ~= nil and var_4_13 ~= 0 then
				var_4_1 = var_4_1 + var_4_13 * var_4_14
			end

			local var_4_15 = cc.Node:create()

			var_4_15:setContentSize(var_0_1, var_0_1)
			xyd.setItemBorder(var_4_15, var_4_9.item_id)
			var_4_7:addChild(var_4_15)
			var_4_15:setAnchorPoint(cc.p(0, 0))

			local var_4_16 = {
				size = 22,
				color = cc.c4b(52, 88, 82, 255)
			}
			local var_4_17 = xyd.AssetLoader:get():loadLabel(var_4_16)

			var_4_17:setString(var_4_10)
			var_4_7:addChild(var_4_17)
			var_4_17:setAnchorPoint(cc.p(0, 0))

			local var_4_18 = {
				size = 20,
				color = cc.c4b(52, 88, 82, 255)
			}
			local var_4_19 = xyd.AssetLoader:get():loadLabel(var_4_18)

			var_4_19:setString("x " .. var_4_14)
			var_4_7:addChild(var_4_19)
			var_4_19:setAnchorPoint(cc.p(0, 0))
			var_4_15:setPosition((iter_4_1 - 1) * var_0_2, 0)
			var_4_17:setPosition((iter_4_1 - 1) * var_0_2 + 70, 13)
			var_4_19:setPosition((iter_4_1 - 1) * var_0_2 + var_4_17:getContentSize().width + 85, 13)
		end

		var_4_7:setContentSize(arg_4_0:nodeByName("scroll"):getContentSize().width, var_0_1)
		var_4_7:setAnchorPoint(cc.p(0, 1))
		var_4_8:addContent(var_4_7)
		var_4_8:setItemSize(arg_4_0:nodeByName("scroll"):getContentSize().width, var_0_1 + 10)
		arg_4_0.listview:addItem(var_4_8)
	end

	arg_4_0.listview:reload()

	local var_4_20 = {}

	if var_4_2 ~= 0 then
		var_4_20.energy = var_4_2
	end

	if var_4_0 ~= 0 then
		var_4_20.dust = var_4_0
	end

	if var_4_1 ~= 0 then
		var_4_20.liquid = var_4_1
	end

	local var_4_21 = 1

	for iter_4_2, iter_4_3 in pairs(var_4_20) do
		local var_4_22 = cc.Sprite:create("images/icon/eco/magic_" .. iter_4_2 .. "_small.png")

		arg_4_0:nodeByName("node" .. var_4_21):addChild(var_4_22)
		var_4_22:setPosition(cc.p(0, 0))
		arg_4_0:nodeByName("txt_" .. var_4_21):setString(iter_4_3)

		var_4_21 = var_4_21 + 1
	end
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	arg_5_0:addBlockLayer()
	xyd.nodeEventSample(arg_5_0:nodeByName("btn_sell"), nil, function(arg_6_0)
		xyd.playButtonSound()
		arg_5_0.player_:useMagicItems(arg_5_1, function(arg_7_0)
			if arg_7_0 == xyd.error.OK then
				arg_5_0:close()
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.REFRESH_MAGIC_RES
				})
			end
		end)
	end)
end

return var_0_0
