local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	arg_2_0.container = var_2_0:getChildByName("background")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.container:getChildByName("bg_name"):setVisible(false)
	arg_3_0.container:getChildByName("tip_txt"):setString(var_0_1:translation("ACTIVITY_CHARGE_TIP"))
	arg_3_0.container:getChildByName("charge_txt"):setString(var_0_1:translation("ACTIVITY_1022_TEXT1"))
	arg_3_0.container:getChildByName("charge"):setString(arg_3_0.activity.details.charge_count)

	local var_3_0 = arg_3_0.container:getChildByName("award_bg"):getChildByName("award_container")
	local var_3_1 = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_0:getWidth(), var_3_0:getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_0)
	local var_3_2 = {
		activity = arg_3_0.activity,
		list = var_3_1,
		count = arg_3_0.idx
	}

	arg_3_0:addActivityAwardList(var_3_2)
end

function var_0_0.createAwardList(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1.list
	local var_4_1 = arg_4_1.activity
	local var_4_2 = arg_4_1.listNum
	local var_4_3 = arg_4_1.count

	if arg_4_1.type then
		var_4_0:removeAllItems()
	end

	for iter_4_0 = 1, var_4_2 do
		local var_4_4 = var_4_0:newItem()
		local var_4_5 = display.newNode()
		local var_4_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1022/item.csb")
		local var_4_7 = var_4_6:getChildByName("container")

		arg_4_0:rewardItemLayout(var_4_1, var_4_7, var_4_3, iter_4_0)
		var_4_6:addTo(var_4_5)
		var_4_6:setTouchEnabled(true)
		var_4_6:setAnchorPoint(cc.p(0, 0))
		var_4_6:setPosition(0, 0)
		var_4_6:setTouchSwallowEnabled(false)
		var_4_5:setContentSize(667, 166)
		var_4_4:addContent(var_4_5)
		var_4_4:setItemSize(667, 176)
		var_4_0:addItem(var_4_4)
	end

	var_4_0:reload()
end

function var_0_0.addActivityAwardList(arg_5_0, arg_5_1)
	local var_5_0 = xyd.tables.activities:tableName(arg_5_1.activity.table_id)

	if var_5_0 and var_5_0 ~= "" then
		arg_5_1.listNum = #import("app.common.tables." .. var_5_0).new():gifts()
		arg_5_1.obtainStates = xyd.luaStringSplit(arg_5_1.activity.details.is_awards, "|")

		if not arg_5_1.listNum then
			return
		else
			arg_5_0:createAwardList(arg_5_1)
		end
	end
end

function var_0_0.rewardItemLayout(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4)
	local var_6_0 = xyd.tables.activityCharge:name(arg_6_4)
	local var_6_1 = arg_6_2:getChildByName("lingqu_btn")

	var_6_1:getChildByName("lingqu_text"):setString(var_0_1:translation("OBTAIN"))

	local var_6_2 = arg_6_2:getChildByName("desc")

	var_6_2:setString(var_6_0)
	var_6_2:setPosition(var_6_2:getPositionX(), var_6_2:getPositionY() - 1)

	local var_6_3 = arg_6_2:getChildByName("award_container")
	local var_6_4 = xyd.ServerTime.get():getServerTime()
	local var_6_5 = xyd.luaStringSplit(arg_6_1.details.is_awards, "|")

	if xyd.tables.activityCharge:recharge(arg_6_4) > arg_6_1.details.charge_count then
		var_6_1:setTouchEnabled(false)
		var_6_1:setBright(false)
	elseif var_6_5[arg_6_4] == "1" then
		var_6_1:setVisible(false)
		arg_6_2:getChildByName("already_get"):setVisible(true)
	end

	arg_6_0:rewardFormat(var_6_3, xyd.tables.activityCharge:gift(arg_6_4), arg_6_0.activity, 15)

	if not arg_6_0:checkTime(arg_6_1) then
		var_6_1:setTouchEnabled(false)
		var_6_1:setBright(false)
	end

	if var_6_4 < arg_6_1.start_time then
		var_6_1:setTouchEnabled(false)
		var_6_1:setBright(false)
	end

	var_6_1:addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(var_6_1, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = arg_6_4

			arg_6_0.activitiesModel:getActivityReward(arg_6_1.table_id, var_7_0, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					arg_6_0.player:handleRewards(arg_8_1.awards)
					var_6_1:setVisible(false)
					arg_6_2:getChildByName("already_get"):setVisible(true)
					arg_6_0.activitiesModel:clearRedMarkState(arg_6_1.table_id, 2)

					if arg_6_0.activities[arg_6_3].details.is_awarded then
						arg_6_0.activities[arg_6_3].details.is_awarded = 1
					end

					if arg_6_0.activities[arg_6_3].details.is_awards then
						local var_8_0 = xyd.luaStringSplit(arg_6_0.activities[arg_6_3].details.is_awards, "|")

						var_8_0[arg_6_4] = "1"

						local var_8_1 = xyd.luaStringMerge(var_8_0, "|")

						arg_6_0.activities[arg_6_3].details.is_awards = var_8_1
					end

					local var_8_2 = xyd.WindowManager.get():getWindow("activities")

					if var_8_2 then
						var_8_2:updateRightCell(arg_6_0.activity.table_id)
					end
				end
			end)
		end
	end)
end

return var_0_0
