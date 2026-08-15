local var_0_0 = class("ActivityNormal", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)
	arg_2_0:normalActivitiesLayout(arg_2_0.activity, arg_2_0.idx)
end

function var_0_0.normalActivitiesLayout(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/normal_activity.csb")
	local var_3_1, var_3_2 = var_3_0:getChildByName("container"):getChildByName("title_pos"):getPosition()
	local var_3_3 = var_3_0:getChildByName("container"):getChildByName("list")
	local var_3_4 = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 665, 500),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_3):onScroll(handler(arg_3_0, arg_3_0.scrollListener))
	local var_3_5 = xyd.tables.activities:title(arg_3_1.table_id)
	local var_3_6 = xyd.AssetLoader.get():loadSprite(var_3_5)

	var_3_6:addTo(var_3_0:getChildByName("container"))
	var_3_6:setAnchorPoint(cc.p(0.5, 0.5))
	var_3_6:setPosition(var_3_1, var_3_2)
	var_3_0:addTo(arg_3_0.parent)

	local var_3_7 = var_3_4:newItem()
	local var_3_8 = display.newNode()
	local var_3_9 = {
		color = cc.c3b(255, 236, 80)
	}

	var_3_9.size = 24

	local var_3_10 = xyd.AssetLoader.get():loadLabel(var_3_9)

	var_3_10:setMaxLineWidth(580)
	var_3_10:setString(xyd.tables.activities:desc(arg_3_1.table_id))
	var_3_10:addTo(var_3_8)
	var_3_10:setAnchorPoint(cc.p(0, 0))
	var_3_10:setPosition(33, 0)
	var_3_8:setContentSize(665, var_3_10:getContentSize().height)
	var_3_7:addContent(var_3_8)
	var_3_7:setItemSize(665, var_3_10:getContentSize().height)
	var_3_4:addItem(var_3_7)

	local var_3_11 = var_3_4:newItem()
	local var_3_12 = display.newNode()
	local var_3_13 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/normal_item_detail.csb")

	var_3_13:addTo(var_3_12)
	var_3_13:setAnchorPoint(cc.p(0, 0))
	var_3_13:setPosition(0, 0)

	local var_3_14 = var_3_13:getChildByName("container"):getChildByName("time_txt")

	arg_3_0.timeLabel = var_3_14

	var_3_13:getChildByName("container"):getChildByName("activity_time_txt"):setString(var_0_1:translation("ACTIVITY_TIME"))

	local var_3_15 = arg_3_1.start_time
	local var_3_16 = arg_3_1.end_time
	local var_3_17 = string.format(var_0_1:translation("ACTIVITY_TIME_SPAN"), os.date("%Y", var_3_15), os.date("%m", var_3_15), os.date("%d", var_3_15), os.date("%H", var_3_15), os.date("%M", var_3_15), os.date("%Y", var_3_16), os.date("%m", var_3_16), os.date("%d", var_3_16), os.date("%H", var_3_16), os.date("%M", var_3_16))

	if arg_3_1.days == -1 then
		var_3_14:setString(var_0_1:translation("FOREVER"))
	else
		var_3_14:setString(var_3_17)
	end

	var_3_12:setContentSize(665, 55)
	var_3_11:addContent(var_3_12)
	var_3_11:setItemSize(665, 55)
	var_3_4:addItem(var_3_11)
	arg_3_0:addChargeLabel(var_3_4, arg_3_1)

	local var_3_18 = arg_3_0.activity.player_info

	if var_3_18 then
		var_3_18.player_id = arg_3_0.activity.player_id

		arg_3_0:addPlayerInfo(var_3_4, var_3_18)
	end

	var_3_4:reload()

	local var_3_19 = {
		activity = arg_3_1,
		list = var_3_4,
		count = arg_3_2
	}

	arg_3_0:addActivityAwardList(var_3_19)
end

function var_0_0.addPlayerInfo(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = arg_4_1:newItem()
	local var_4_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/open_item/open_player.csb")
	local var_4_2 = var_4_1:getChildByName("container")
	local var_4_3 = var_4_2:getContentSize()

	xyd.setPlayerAvatar(var_4_2:getChildByName("player"), {
		avatar_id = arg_4_2.avatar_id,
		avatar_frame_id = arg_4_2.avatar_frame_id,
		playerInfo = arg_4_2
	})
	var_4_2:getChildByName("label_name"):setString(arg_4_2.player_name)
	var_4_1:setContentSize(var_4_3.width, var_4_3.height)
	var_4_0:addContent(var_4_1)
	var_4_0:setItemSize(var_4_3.width, var_4_3.height)
	arg_4_1:addItem(var_4_0)
end

function var_0_0.addChargeLabel(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_2.details and arg_5_2.details.charge_count then
		local var_5_0 = arg_5_1:newItem()
		local var_5_1 = display.newNode()
		local var_5_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/charge_count.csb")
		local var_5_3 = var_5_2:getChildByName("container"):getChildByName("charge_num_txt")

		var_5_2:getChildByName("container"):getChildByName("have_charged_txt"):setString(var_0_1:translation("ACTIVITY_TODAY_HAS_SAVED"))
		var_5_3:setString(arg_5_2.details.charge_count .. var_0_1:translation("CRYSTAL"))
		var_5_2:addTo(var_5_1)
		var_5_2:setAnchorPoint(cc.p(0, 0))
		var_5_2:setPosition(0, 0)
		var_5_1:setContentSize(665, 50)
		var_5_0:addContent(var_5_1)
		var_5_0:setItemSize(665, 50)
		arg_5_1:addItem(var_5_0)
	elseif arg_5_2.details and arg_5_2.details.consume_count then
		local var_5_4 = arg_5_1:newItem()
		local var_5_5 = display.newNode()
		local var_5_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/charge_count.csb")
		local var_5_7 = var_5_6:getChildByName("container"):getChildByName("charge_num_txt")
		local var_5_8 = var_5_6:getChildByName("container"):getChildByName("have_charged_txt"):setString(var_0_1:translation("ACTIVITY_TODAY_HAS_COST"))

		var_5_7:setString(arg_5_2.details.consume_count .. var_0_1:translation("CRYSTAL"))
		var_5_6:addTo(var_5_5)
		var_5_6:setAnchorPoint(cc.p(0, 0))
		var_5_6:setPosition(0, 0)
		var_5_5:setContentSize(665, 50)
		var_5_4:addContent(var_5_5)
		var_5_4:setItemSize(665, 50)
		arg_5_1:addItem(var_5_4)
	else
		local var_5_9 = arg_5_1:newItem()
		local var_5_10 = display.newNode()

		var_5_10:setContentSize(665, 20)
		var_5_9:addContent(var_5_10)
		var_5_9:setItemSize(665, 20)
		arg_5_1:addItem(var_5_9)
	end
end

function var_0_0.addActivityAwardList(arg_6_0, arg_6_1)
	local var_6_0 = xyd.tables.activities:tableName(arg_6_1.activity.table_id)

	if var_6_0 and var_6_0 ~= "" then
		arg_6_1.listNum = #import("app.common.tables." .. var_6_0).new():gifts()

		if not arg_6_1.listNum then
			return
		else
			arg_6_0:createAwardList(arg_6_1)
		end
	end
end

function var_0_0.createAwardList(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_1.list
	local var_7_1 = arg_7_1.activity
	local var_7_2 = arg_7_1.listNum
	local var_7_3 = arg_7_1.count

	if arg_7_1.type then
		var_7_0:removeAllItems()
	end

	for iter_7_0 = 1, var_7_2 do
		if arg_7_0:checkInitItem(iter_7_0, arg_7_1) then
			local var_7_4 = var_7_0:newItem()
			local var_7_5 = display.newNode()
			local var_7_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/activity_item.csb")
			local var_7_7 = var_7_6:getChildByName("container")

			arg_7_0:rewardItemLayout(var_7_1, var_7_7, var_7_3, iter_7_0)
			var_7_6:addTo(var_7_5)
			var_7_6:setTouchEnabled(true)
			var_7_6:setAnchorPoint(cc.p(0, 0))
			var_7_6:setPosition(0, 0)
			var_7_6:setTouchSwallowEnabled(false)
			var_7_5:setContentSize(665, 148)
			var_7_4:addContent(var_7_5)
			var_7_4:setItemSize(665, 148)
			var_7_0:addItem(var_7_4)
		end
	end

	var_7_0:reload()
end

function var_0_0.rewardItemLayout(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)
	return
end

function var_0_0.checkInitItem(arg_9_0, arg_9_1, arg_9_2)
	return true
end

return var_0_0
