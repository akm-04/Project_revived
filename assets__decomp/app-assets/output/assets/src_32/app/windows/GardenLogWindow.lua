local var_0_0 = class("GardenLogWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.garden = xyd.ModelManager.get():loadModel(xyd.ModelType.GARDEN)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.data = arg_1_2.data
	arg_1_0.ownerInfo = arg_1_0.garden.details.np_info
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.scroll = arg_4_0:nodeByName("scroll")

	local var_4_0 = arg_4_0.scroll:getContentSize()

	arg_4_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.scrollList:setDelegate(handler(arg_4_0, arg_4_0.scrollListDelegate))
	arg_4_0.scrollList:reload()
	arg_4_0:nodeByName("tip_text"):getVirtualRenderer():setLineHeight(30)
	arg_4_0:nodeByName("tip_text"):setString(var_0_1:translation("GARDEN_NO_VISIT_TIP"))

	if #arg_4_0.data == 0 then
		arg_4_0:nodeByName("tip_node"):setVisible(true)
	else
		arg_4_0:nodeByName("tip_node"):setVisible(false)
	end
end

function var_0_0.scrollListDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #arg_5_0.data
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0
		local var_5_1 = arg_5_0.scrollList:dequeueItem()

		if not var_5_1 then
			var_5_1 = arg_5_0.scrollList:newItem()
		else
			var_5_1:removeAllChildren(true)
		end

		local var_5_2 = arg_5_0:createListContent(arg_5_0.data[arg_5_3])
		local var_5_3 = var_5_2:getWidth()
		local var_5_4 = var_5_2:getHeight()

		var_5_1:setItemSize(var_5_3, var_5_4)
		var_5_1:addContent(var_5_2)

		return var_5_1
	end
end

function var_0_0.createListContent(arg_6_0, arg_6_1)
	local var_6_0 = display.newNode()
	local var_6_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/garden/log/log_item.csb")
	local var_6_2 = var_6_1:getChildByName("container")
	local var_6_3 = xyd.tables.activityGardenFlower
	local var_6_4 = arg_6_1.np_info or {}
	local var_6_5 = var_6_4

	xyd.setPlayerAvatar(var_6_2:getChildByName("avtar_container"), var_6_5)

	local var_6_6 = var_6_2:getChildByName("avtar_container"):getChildByName("avatar")

	var_6_6:setTouchEnabled(true)
	var_6_6:setTouchSwallowEnabled(false)
	var_6_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			return true
		elseif arg_7_0.name == "ended" and not arg_6_0.scrollViewMoved_ then
			local var_7_0 = {
				player_id = var_6_4.player_id
			}

			arg_6_0.garden:getGardenInfo(var_7_0, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					xyd.WindowManager.get():closeWindow(arg_6_0)
				end
			end)
		end
	end)

	if arg_6_1.log_type == 1 then
		var_6_2:getChildByName("hand"):setVisible(true)
		var_6_2:getChildByName("water"):setVisible(false)
	else
		var_6_2:getChildByName("hand"):setVisible(false)
		var_6_2:getChildByName("water"):setVisible(true)
	end

	var_6_2:getChildByName("time_txt"):setString(os.date("%Y-%m-%d  %X", arg_6_1.time))
	var_6_2:getChildByName("desc_txt1"):setString(var_6_4.player_name)
	var_6_2:getChildByName("desc_txt3"):setString(string.format(var_0_1:translation("GARDEN_TIP_TITLE_TEXT"), arg_6_1.field_id))

	if arg_6_1.log_type == 1 then
		var_6_2:getChildByName("desc_txt2"):setString(var_0_1:translation("GARDEN_LOG_TEXT4"))
		var_6_2:getChildByName("desc_txt4"):setString(string.format(var_0_1:translation("GARDEN_LOG_TEXT2"), var_6_3:name(arg_6_1.seed_id)))
	else
		var_6_2:getChildByName("desc_txt2"):setString(var_0_1:translation("GARDEN_LOG_TEXT1"))
		var_6_2:getChildByName("desc_txt4"):setString(string.format(var_0_1:translation("GARDEN_LOG_TEXT3"), var_6_3:name(arg_6_1.seed_id)))
	end

	local var_6_7 = var_6_2:getChildByName("desc_txt1"):getPositionX()

	for iter_6_0 = 1, 4 do
		var_6_2:getChildByName("desc_txt" .. iter_6_0):setPositionX(var_6_7)

		var_6_7 = var_6_7 + var_6_2:getChildByName("desc_txt" .. iter_6_0):getContentSize().width + 5
	end

	var_6_1:addTo(var_6_0)
	var_6_1:setAnchorPoint(cc.p(0, 0))
	var_6_0:setContentSize(var_6_2:getContentSize())
	var_6_1:setName("source")

	return var_6_0
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevY_ = arg_9_1.y
	elseif arg_9_1.name == "moved" and 5 <= math.abs(arg_9_1.y - arg_9_0.prevY_) then
		arg_9_0.scrollViewMoved_ = true
	end
end

return var_0_0
