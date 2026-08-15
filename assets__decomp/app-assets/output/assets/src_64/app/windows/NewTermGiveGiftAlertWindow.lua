local var_0_0 = class("NewTermGiveGiftAlertWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.newTermGift
local var_0_4 = import("framework.scheduler")
local var_0_5 = 4
local var_0_6 = 76

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.newTermModel = xyd.ModelManager.get():loadModel(xyd.ModelType.NEW_TERMS)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.playerInfo = arg_1_2
	arg_1_0.gifts = {}
	arg_1_0.itemToGive = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:initGifts()
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("label1"):setString(string.format(var_0_2:translation("LIANYI_TEXT5"), ""))
	arg_4_0:nodeByName("label1_num"):setString(arg_4_0.playerInfo.name or arg_4_0.playerInfo.player_name)
	arg_4_0:initListView()
	arg_4_0:registerListeners()
	arg_4_0:updatePanel()
end

function var_0_0.initGifts(arg_5_0)
	arg_5_0.gifts = {}

	local var_5_0 = var_0_3:giftIDs()
	local var_5_1 = arg_5_0.selfPlayer:getBackpack()
	local var_5_2 = 0

	for iter_5_0, iter_5_1 in pairs(var_5_0) do
		if var_5_1:getItemNumByID(tonumber(iter_5_1)) > 0 then
			var_5_2 = var_5_2 + 1

			local var_5_3 = {
				nowNum = 0,
				itemID = iter_5_1,
				itemNum = var_5_1:getItemNumByID(tonumber(iter_5_1)),
				index = var_5_2
			}

			table.insert(arg_5_0.gifts, var_5_3)
		end
	end
end

function var_0_0.initListView(arg_6_0)
	if not arg_6_0.listView_ then
		arg_6_0.listView_ = cc.ui.UIListView.new({
			touchOnContent = true,
			async = true,
			viewRect = cc.rect(0, 0, 443, 216),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_6_0:nodeByName("item_list"))
	else
		arg_6_0.listView_:removeAllItems()
	end

	arg_6_0.listView_:setDelegate(handler(arg_6_0, arg_6_0.delegate))
	arg_6_0.listView_:reload()
end

function var_0_0.delegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = math.ceil(#arg_7_0.gifts / var_0_5)

	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return var_7_0
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_1 = arg_7_1:dequeueItem()

		if not var_7_1 then
			var_7_1 = arg_7_1:newItem()
		else
			var_7_1:removeAllChildren()
		end

		local var_7_2 = display.newNode()

		var_7_2:setContentSize(430, var_0_6 + 10)

		for iter_7_0 = 1, var_0_5 do
			local var_7_3 = (arg_7_3 - 1) * var_0_5 + iter_7_0

			if var_7_3 > #arg_7_0.gifts then
				break
			end

			local var_7_4 = import("app.windows.NewTermGiftItem").new()

			var_7_4:setParams(arg_7_0.gifts[var_7_3])
			var_7_4:addTo(var_7_2)
			var_7_4:setAnchorPoint(0, 0)
			var_7_4:setPosition(18 + (var_0_6 + 34) * (iter_7_0 - 1), 0)
			var_7_4:contentView():nodeByName("item"):setTouchEnabled(true)
			var_7_4:contentView():nodeByName("item"):setTouchSwallowEnabled(false)
			var_7_4:contentView():nodeByName("container"):setTouchSwallowEnabled(false)
		end

		var_7_1:addContent(var_7_2)
		var_7_1:setItemSize(430, var_0_6 + 10)

		return var_7_1
	end
end

function var_0_0.willClose(arg_8_0)
	if arg_8_0.handle then
		var_0_4.unscheduleGlobal(arg_8_0.handle)

		arg_8_0.handle = nil
	end
end

function var_0_0.initGiftToGive(arg_9_0)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in pairs(arg_9_0.gifts) do
		local var_9_1 = {
			item_id = iter_9_1.itemID,
			item_num = iter_9_1.nowNum
		}

		if var_9_1.item_num ~= 0 then
			table.insert(var_9_0, var_9_1)
		end
	end

	arg_9_0.itemToGive = var_9_0
end

function var_0_0.updatePanel(arg_10_0)
	arg_10_0:initGiftToGive()

	local var_10_0 = 0
	local var_10_1 = 0

	for iter_10_0, iter_10_1 in pairs(arg_10_0.itemToGive) do
		var_10_0 = var_10_0 + var_0_3:charm(iter_10_1.item_id) * iter_10_1.item_num
		var_10_1 = var_10_1 + var_0_3:connection(iter_10_1.item_id) * iter_10_1.item_num
	end

	arg_10_0:nodeByName("label2"):setString(string.format(var_0_2:translation("LIANYI_TEXT21"), ""))
	arg_10_0:nodeByName("label2_num"):setString(var_10_0)
	arg_10_0:nodeByName("label3"):setString(string.format(var_0_2:translation("LIANYI_TEXT6"), ""))
	arg_10_0:nodeByName("label3_num"):setString(var_10_1)
end

function var_0_0.registerListeners(arg_11_0)
	arg_11_0:nodeByName("give_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			local var_12_0 = {
				items = arg_11_0.itemToGive,
				player_id = arg_11_0.playerInfo.player_id
			}

			if #arg_11_0.itemToGive == 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("LIANYI_TEXT23")
				})
			else
				arg_11_0.newTermModel:givePresent(var_12_0, function(arg_13_0, arg_13_1)
					for iter_13_0, iter_13_1 in pairs(arg_11_0.itemToGive) do
						local var_13_0 = {
							itemID = iter_13_1.item_id,
							itemNum = iter_13_1.item_num
						}

						arg_11_0.selfPlayer:getBackpack():removeItem(var_13_0)
					end

					xyd.WindowManager.get():closeWindow(arg_11_0)
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("LIANYI_TEXT24")
					})
				end)
			end
		end
	end)
	arg_11_0:nodeByName("select_all_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.NEW_TERM_GIFT_SELECT_ALL,
				params = {}
			})

			for iter_14_0, iter_14_1 in pairs(arg_11_0.gifts) do
				iter_14_1.nowNum = iter_14_1.itemNum
			end

			arg_11_0:updatePanel()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_11_0):addEventListener(xyd.event.NEW_TERM_GIFT_REFRESH, function(arg_15_0)
		if arg_11_0 and not tolua.isnull(arg_11_0) then
			arg_11_0:updatePanel()

			local var_15_0 = arg_15_0.params.item

			arg_11_0.gifts[var_15_0.index] = var_15_0
		end
	end)
end

return var_0_0
