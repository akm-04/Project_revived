local var_0_0 = class("CountShopTaskWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = xyd.tables.discountShopMission
local var_0_3 = xyd.tables.translation
local var_0_4 = {
	txt_rule = var_0_3:translation("ACTIVITY_RULE"),
	txt_title = var_0_3:translation("ACTIVITY_SP_SHOP_MISSION"),
	txt_have_get = var_0_3:translation("FIRST_STORE_AWARD_TEXT8"),
	txt_can_get = var_0_3:translation("OBTAIN"),
	txt_no_get = var_0_3:translation("ACTIVITY_GIRL_TRAINING_TEXT2")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.progress = tonumber(arg_1_2.progress)
	arg_1_0.task = arg_1_2.task
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.flag = {}

	for iter_1_0 = 1, #arg_1_0.task do
		if arg_1_0.task[iter_1_0].is_award == 0 then
			arg_1_0.flag[iter_1_0] = 0
		else
			arg_1_0.flag[iter_1_0] = 1
		end
	end
end

function var_0_0.willOpen(arg_2_0)
	var_0_0.super:willOpen(params)

	local var_2_0 = arg_2_0:nodeByName("list"):getContentSize()

	arg_2_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_0.width, var_2_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_2_0:nodeByName("list"))

	arg_2_0.list:setDelegate(handler(arg_2_0, arg_2_0.delegate))
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	var_0_0.super:didOpen()
	arg_3_0:addBlockLayer()
	arg_3_0.list:reload()
end

function var_0_0.didClose(arg_4_0)
	var_0_0.super:didClose()

	if arg_4_0.callback then
		arg_4_0.callback()
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("txt_name"):setString(var_0_4.txt_title)
end

function var_0_0.delegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return #arg_6_0.task
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0
		local var_6_1
		local var_6_2
		local var_6_3 = arg_6_0.list:dequeueItem()

		if not var_6_3 then
			var_6_3 = arg_6_0.list:newItem()
		else
			var_6_3:removeAllChildren()
		end

		local var_6_4 = display.newNode()

		var_6_4:setTouchSwallowEnabled(false)

		local var_6_5 = display.newNode()

		arg_6_0:initTaskCell(var_6_5, arg_6_3)
		var_6_4:addChild(var_6_5)
		var_6_4:setContentSize(cc.size(var_6_5:getContentSize().width, var_6_5:getContentSize().height))
		var_6_3:setItemSize(var_6_5:getContentSize().width, var_6_5:getContentSize().height + 5)
		var_6_3:addContent(var_6_4)

		return var_6_3
	end
end

function var_0_0.initTaskCell(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1180/task_item.csb")
	local var_7_1 = var_7_0:getChildByName("container")
	local var_7_2 = var_7_1:getContentSize()

	arg_7_1:setContentSize(var_7_2.width, var_7_2.height)
	var_7_0:addTo(arg_7_1)
	var_7_0:setPosition(cc.p(0, 0))
	var_7_0:setTouchSwallowEnabled(true)

	local var_7_3 = var_0_2:ids()
	local var_7_4 = var_0_2:Desc(var_7_3[arg_7_2])
	local var_7_5 = {
		size = 22,
		text = var_7_4,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		color = cc.c3b(210, 84, 16)
	}
	local var_7_6 = xyd.AssetLoader.get():loadLabel(var_7_5)

	var_7_6:setPosition(var_7_1:getChildByName("pos_task"):getPosition())
	var_7_6:setAnchorPoint(cc.p(0, 0.5))
	var_7_6:addTo(var_7_1)

	local var_7_7 = var_0_1.new({
		size = 300
	})

	var_7_7:addTo(var_7_1)
	var_7_7:setAnchorPoint(0, 0.5)
	var_7_7:setPosition(cc.p(25, 60))

	local var_7_8 = var_0_2:taskNum(var_7_3[arg_7_2])
	local var_7_9 = "(" .. arg_7_0.progress .. "/" .. var_7_8 .. ")"

	var_7_1:getChildByName("txt_require"):setString(var_7_9)

	local var_7_10 = var_0_2:gift(var_7_3[arg_7_2])
	local var_7_11 = xyd.tables.gift:items(var_7_10)
	local var_7_12 = xyd.tables.gift:itemNum(var_7_10)

	for iter_7_0 = 1, #var_7_11 do
		local var_7_13 = var_7_1:getChildByName("icon_" .. iter_7_0)

		xyd.setItemAndAddTips(var_7_13, var_7_11[iter_7_0], var_7_12[iter_7_0])
	end

	local var_7_14 = var_7_1:getChildByName("btn_get")

	if arg_7_0.flag[arg_7_2] == 0 and arg_7_0.task[arg_7_2].is_award == 0 then
		if var_7_8 > arg_7_0.progress then
			var_7_14:getChildByName("txt_get"):setString(var_0_4.txt_no_get)
			var_7_14:setTouchEnabled(false)
			var_7_14:setBright(false)
		else
			var_7_14:getChildByName("txt_get"):setString(var_0_4.txt_can_get)
			var_7_14:setTouchEnabled(true)
			var_7_14:setBright(true)
			var_7_14:addTouchEventListener(function(arg_8_0, arg_8_1)
				if arg_8_1 == ccui.TouchEventType.began then
					var_7_14:setScale(0.9)
				elseif arg_8_1 == ccui.TouchEventType.ended then
					var_7_14:setScale(1)

					local var_8_0 = {
						mission_id = var_7_3[arg_7_2]
					}

					if arg_7_0.progress < var_7_8 then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
							var_0_3:translation("MISSION_NOT_COMPLETE")
						}, nil, alertParams, nil, xyd.ColorMode.ACTIVITY)

						return
					else
						xyd.Backend.get():request(xyd.mid.DISCOUNT_SHOP_GET_TASK, var_8_0, function(arg_9_0, arg_9_1)
							if arg_9_0 == xyd.error.OK then
								arg_7_0.player:handleRewards(arg_9_1.awards)
								var_7_14:setTouchEnabled(false)
								var_7_14:setBright(false)
								var_7_14:getChildByName("txt_get"):setString(var_0_4.txt_have_get)

								arg_7_0.flag[arg_7_2] = 1
							end
						end)
					end
				end
			end)
		end
	elseif arg_7_0.task[arg_7_2].is_award == 1 or arg_7_0.flag[arg_7_2] == 1 then
		var_7_14:getChildByName("txt_get"):setString(var_0_4.txt_have_get)
		var_7_14:setTouchEnabled(false)
		var_7_14:setBright(false)
	else
		var_7_14:getChildByName("txt_get"):setString(var_0_4.txt_have_get)
		var_7_14:setTouchEnabled(false)
		var_7_14:setBright(false)
	end
end

return var_0_0
