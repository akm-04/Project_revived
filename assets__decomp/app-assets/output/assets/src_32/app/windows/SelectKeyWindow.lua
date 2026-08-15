local var_0_0 = class("SelectKeyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.item
local var_0_4 = 4

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.keyType = arg_1_2.keyType
	arg_1_0.floor = arg_1_2.floor
	arg_1_0.pos = arg_1_2.pos
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.listInfo = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	return
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super:didClose(arg_4_1)
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = arg_5_0:nodeByName("key_container")
	local var_5_1 = var_5_0:getContentSize()

	arg_5_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_1.width, var_5_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_5_0):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.list:setDelegate(handler(arg_5_0, arg_5_0.delegate))
	arg_5_0:updateListInfo()
	arg_5_0.list:reload()
	arg_5_0:nodeByName("tips"):setString(var_0_2:translation("DORM_CHOOSE_KEY_TIP"))
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevX_ = arg_6_1.x
		arg_6_0.prevY_ = arg_6_1.y
	elseif arg_6_1.name == "moved" then
		local var_6_0 = 3

		if var_6_0 <= math.abs(arg_6_1.y - arg_6_0.prevY_) or var_6_0 <= math.abs(arg_6_1.x - arg_6_0.prevX_) then
			arg_6_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.updateListInfo(arg_7_0)
	arg_7_0.listInfo = {}

	local var_7_0 = xyd.tables.dormHouseKey:getAllKeysByType(arg_7_0.keyType)

	for iter_7_0, iter_7_1 in pairs(var_7_0) do
		if arg_7_0.selfPlayer:getBackpack():getItemNumByID(iter_7_1) > 0 then
			table.insert(arg_7_0.listInfo, iter_7_1)
		end
	end
end

function var_0_0.delegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return (math.ceil(#arg_8_0.listInfo / var_0_4))
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_0 = arg_8_0.list:dequeueItem()

		if not var_8_0 then
			var_8_0 = arg_8_0.list:newItem()
		else
			var_8_0:removeAllChildren(true)
		end

		local var_8_1 = 400
		local var_8_2 = 125

		var_8_0:setItemSize(var_8_1, var_8_2)

		local var_8_3 = display.newNode()

		var_8_3:setContentSize(var_8_1, 100)
		arg_8_0:initCell(var_8_3, arg_8_3)
		var_8_0:addContent(var_8_3)

		return var_8_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_8_2 then
		-- block empty
	end
end

function var_0_0.initCell(arg_9_0, arg_9_1, arg_9_2)
	for iter_9_0 = 1, var_0_4 do
		local var_9_0 = (arg_9_2 - 1) * var_0_4 + iter_9_0

		if var_9_0 > #arg_9_0.listInfo then
			break
		end

		local var_9_1 = display.newNode()

		var_9_1:setContentSize(90, 90)
		var_9_1:setPosition(100 * iter_9_0 - 100, 0)
		var_9_1:setAnchorPoint(0, 0)
		arg_9_1:addChild(var_9_1)
		var_9_1:setTouchEnabled(true)
		var_9_1:setTouchSwallowEnabled(false)
		xyd.setItemBorder(var_9_1, arg_9_0.listInfo[var_9_0], false, false, arg_9_0.selfPlayer:getBackpack():getItemNumByID(arg_9_0.listInfo[var_9_0]))
		var_9_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
			if arg_10_0.name == "began" then
				var_9_1:setScale(0.9)
			elseif arg_10_0.name == "moved" then
				var_9_1:setScale(1)
			elseif arg_10_0.name == "ended" and not arg_9_0.scrollViewMoved_ then
				var_9_1:setScale(1)

				local var_10_0 = string.format(var_0_2:translation("DORM_CHOOSE_KEY_CONFIRM"), xyd.tables.item:name(arg_9_0.listInfo[var_9_0]))

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_0, function()
					local var_11_0 = {
						key_item = arg_9_0.listInfo[var_9_0],
						floor = arg_9_0.floor,
						pos = arg_9_0.pos
					}

					xyd.ModelManager.get():loadModel(xyd.ModelType.DORM):openHouse(var_11_0, function(arg_12_0, arg_12_1)
						if arg_12_0 == xyd.error.OK then
							local var_12_0 = xyd.WindowManager.get():getWindow("floor_view")

							if var_12_0 then
								var_12_0.lockRoomCanTouch = false

								arg_9_0.callback()

								arg_9_0.schedulerHandler = var_0_1.performWithDelayGlobal(function()
									local var_13_0 = xyd.WindowManager.get():getWindow("floor_view")

									var_13_0.dorm:updateBaseInfo(var_13_0.floorState, arg_12_1.house_info)
									var_13_0:updateListInfo(true)
									var_13_0.list:refreshList(1)

									if var_13_0.unlockFloor == true then
										local var_13_1 = cc.p(0, 1440)

										var_13_0.list:scrollTo(var_13_1.x, var_13_1.y)
										transition.moveBy(var_13_0.list:getScrollNode(), {
											time = 1.5,
											y = -720
										})

										var_13_0.unlockFloor = false
									end

									var_13_0.lockRoomCanTouch = true
								end, 1)
							end

							arg_9_0.selfPlayer:getBackpack():addItemsByID(arg_9_0.listInfo[var_9_0], -1)

							if arg_9_0.selfPlayer:getBackpack():getItemNumByID(arg_9_0.listInfo[var_9_0]) <= 0 then
								local var_12_1 = {
									itemID = arg_9_0.listInfo[var_9_0]
								}

								var_12_1.itemNum = 1

								arg_9_0.selfPlayer:getBackpack():removeItem(var_12_1)
							end
						end

						if xyd.WindowManager.get():getWindow("select_key") then
							xyd.WindowManager.get():closeWindow("select_key")
						end
					end)
				end, nil, nil, arg_9_0.colorMode)
			end

			return true
		end)
	end
end

return var_0_0
