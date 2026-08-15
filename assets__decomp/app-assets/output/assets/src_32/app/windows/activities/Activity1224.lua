local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityConsumeItem
local var_0_3 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	arg_2_0.activitiesModel:loadSingleActivity({
		activity_id = arg_2_0.activity.table_id
	}, function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			arg_2_0.activity = arg_3_1

			local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

			var_3_0:addTo(arg_2_0.parent)

			arg_2_0.container = var_3_0:getChildByName("background")

			arg_2_0:layout()
		else
			local var_3_1 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

			var_3_1:addTo(arg_2_0.parent)

			arg_2_0.container = var_3_1:getChildByName("background")

			arg_2_0:layout()
		end
	end)
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0.container:getChildByName("rule_text")
	local var_4_1 = arg_4_0.container:getChildByName("cost_item")
	local var_4_2 = var_4_0:getContentSize()
	local var_4_3 = var_4_2.height
	local var_4_4 = {
		color = cc.c3b(228, 183, 183)
	}

	var_4_4.size = 20
	var_4_4.dimensions = cc.size(var_4_2.width, 0)

	local var_4_5 = xyd.split(xyd.tables.activities:desc(arg_4_0.activity.table_id), "\n")

	for iter_4_0, iter_4_1 in ipairs(var_4_5) do
		local var_4_6 = xyd.AssetLoader.get():loadSprite("windows/activities/1224/star.png")

		var_4_6:setPosition(10, var_4_3 - 9.5)
		var_4_0:addChild(var_4_6)

		local var_4_7 = xyd.AssetLoader.get():loadLabel(var_4_4)

		var_4_7:setAnchorPoint(0, 1)
		var_4_7:setPosition(25, var_4_3)
		var_4_7:setLineHeight(25)
		var_4_7:setString(iter_4_1)
		var_4_0:addChild(var_4_7)

		var_4_3 = var_4_3 - var_4_7:getContentSize().height - 2
	end

	arg_4_0.container:getChildByName("cost"):setString(arg_4_0.activity.details.consume_count or 0)

	local var_4_8 = var_0_3:getValue("item_consume_activity_item")

	xyd.setItemAndAddTips(var_4_1, var_4_8, 1)

	local var_4_9 = arg_4_0.container:getChildByName("award_container")

	arg_4_0.list = cc.ui.UITableView.new({
		size = var_4_9:getContentSize(),
		direction = cc.ui.UITableView.DIRECTION_VERTICAL
	}):addTo(var_4_9)

	local var_4_10 = {
		activity = arg_4_0.activity,
		count = arg_4_0.idx
	}

	arg_4_0:addActivityAwardList(var_4_10)
end

function var_0_0.createAwardList(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0.list
	local var_5_1 = arg_5_1.activity
	local var_5_2 = arg_5_1.listNum
	local var_5_3 = arg_5_1.count

	if arg_5_1.type then
		var_5_0:removeAllItems()
	end

	for iter_5_0 = 1, var_5_2 do
		local var_5_4 = var_5_0:newItem()
		local var_5_5 = display.newNode()
		local var_5_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1224/item.csb")
		local var_5_7 = var_5_6:getChildByName("container")

		arg_5_0:rewardItemLayout(var_5_1, var_5_7, var_5_3, iter_5_0)
		var_5_6:addTo(var_5_5)
		var_5_6:setTouchEnabled(true)
		var_5_6:setAnchorPoint(cc.p(0, 0))
		var_5_6:setPosition(0, 0)
		var_5_6:setTouchSwallowEnabled(false)
		var_5_5:setContentSize(667, 166)
		var_5_4:addContent(var_5_5)
		var_5_4:setItemSize(667, 176)
		var_5_0:addItem(var_5_4)
	end

	var_5_0:reload()
end

function var_0_0.addActivityAwardList(arg_6_0, arg_6_1)
	arg_6_1.listNum = #var_0_2:gifts()
	arg_6_1.obtainStates = xyd.luaStringSplit(arg_6_1.activity.details.is_awards, "|")

	arg_6_0:createAwardList(arg_6_1)
end

function var_0_0.rewardItemLayout(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4)
	local var_7_0 = var_0_2:name(arg_7_4)
	local var_7_1 = arg_7_2:getChildByName("lingqu_btn")

	arg_7_2:getChildByName("desc"):setString(var_7_0)

	local var_7_2 = arg_7_2:getChildByName("award_container")
	local var_7_3 = xyd.ServerTime.get():getServerTime()
	local var_7_4 = xyd.luaStringSplit(arg_7_1.details.is_awards, "|")

	if var_0_2:consume(arg_7_4) > arg_7_1.details.consume_count then
		var_7_1:setTouchEnabled(false)
		var_7_1:setBright(false)
	elseif var_7_4[arg_7_4] == "1" then
		var_7_1:setVisible(false)
		arg_7_2:getChildByName("already_get"):setVisible(true)
	end

	arg_7_0:rewardFormat(var_7_2, var_0_2:gift(arg_7_4), arg_7_0.activity, 15)

	if not arg_7_0:checkTime(arg_7_1) then
		var_7_1:setTouchEnabled(false)
		var_7_1:setBright(false)
	end

	if var_7_3 < arg_7_1.start_time then
		var_7_1:setTouchEnabled(false)
		var_7_1:setBright(false)
	end

	var_7_1:addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = arg_7_4

			arg_7_0.activitiesModel:getActivityReward(arg_7_1.table_id, var_8_0, function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					arg_7_0.selfPlayer:handleRewards(arg_9_1.awards)
					var_7_1:setVisible(false)
					arg_7_2:getChildByName("already_get"):setVisible(true)

					if arg_7_0.activities[arg_7_3].details.is_awarded then
						arg_7_0.activities[arg_7_3].details.is_awarded = 1
					end

					if arg_7_0.activities[arg_7_3].details.is_awards then
						local var_9_0 = xyd.luaStringSplit(arg_7_0.activities[arg_7_3].details.is_awards, "|")

						var_9_0[arg_7_4] = "1"

						local var_9_1 = xyd.luaStringMerge(var_9_0, "|")

						arg_7_0.activities[arg_7_3].details.is_awards = var_9_1
					end

					arg_7_0.activitiesModel:clearRedMarkState(arg_7_1.table_id, 2)

					local var_9_2 = xyd.WindowManager.get():getWindow("activities")

					if var_9_2 then
						var_9_2:rightLayout()
					end
				end
			end)
		end
	end)
end

return var_0_0
