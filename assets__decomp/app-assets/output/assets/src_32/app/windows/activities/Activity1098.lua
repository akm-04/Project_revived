local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

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

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	if var_2_0 then
		arg_2_0.container = var_2_0:getChildByName("container")

		var_2_0:addTo(arg_2_0.parent)
		var_2_0:setPosition(0, 0)

		arg_2_0.scroll = arg_2_0.container:getChildByName("scroll")

		local var_2_1 = arg_2_0.scroll:getContentSize()

		arg_2_0.awardList = cc.ui.UIListView.new({
			async = false,
			viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_2_0.scroll)

		arg_2_0.awardList:setBounceable(false)
		arg_2_0.awardList:setTouchType(false)
		arg_2_0.awardList:setTouchEnabled(false)
		arg_2_0:updateAwardScroll()
		arg_2_0.container:getChildByName("rule_text1"):setString(var_0_1:translation("ACTIVITY_1098_TEXT2"))
		arg_2_0.container:getChildByName("rule_text2"):setString(var_0_1:translation("ACTIVITY_1098_TEXT3"))
	end
end

function var_0_0.updateAwardScroll(arg_3_0)
	arg_3_0.awardList:removeAllItems()

	for iter_3_0 = 1, #arg_3_0.activity.details.is_awarded do
		local var_3_0
		local var_3_1 = arg_3_0.awardList:dequeueItem()

		if not var_3_1 then
			var_3_1 = arg_3_0.awardList:newItem()
		else
			var_3_1:removeAllChildren(true)
		end

		local var_3_2 = arg_3_0:createListContent(iter_3_0)
		local var_3_3 = var_3_2:getWidth()
		local var_3_4 = var_3_2:getHeight()

		var_3_1:setItemSize(var_3_3, var_3_4)
		var_3_1:addContent(var_3_2)
		arg_3_0.awardList:addItem(var_3_1)
		arg_3_0.awardList:reload()
	end
end

function var_0_0.createListContent(arg_4_0, arg_4_1)
	local var_4_0 = display.newNode()
	local var_4_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1098/activity_item.csb")
	local var_4_2 = var_4_1:getChildByName("container")

	var_4_2:getChildByName("charge_num_text"):setString(var_0_1:translation("ACTIVITY_1098_TEXT4"))
	var_4_2:getChildByName("rebate_num_text"):setString(var_0_1:translation("ACTIVITY_1098_TEXT5"))

	local var_4_3 = var_4_2:getChildByName("item_title_container")
	local var_4_4 = {
		color = cc.c3b(255, 255, 255)
	}

	var_4_4.size = 20

	local var_4_5 = xyd.AssetLoader.get():loadLabel(var_4_4)

	var_4_5:addTo(var_4_3)
	var_4_5:setAnchorPoint(cc.p(0, 0))
	var_4_5:setPosition(10, 3)
	var_4_5:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	local var_4_6 = arg_4_0.activity.details
	local var_4_7 = xyd.colorNumLabel(var_4_6.charge_count[arg_4_1], "pink")

	var_4_7:setAnchorPoint(cc.p(1, 0.5))
	var_4_7:addTo(var_4_2:getChildByName("charge_num_pos"))

	local var_4_8 = xyd.colorNumLabel(math.floor(var_4_6.charge_count[arg_4_1] * xyd.tables.misc.bankActivityRebateRatio[arg_4_1]), "yellow5")

	var_4_8:setAnchorPoint(cc.p(1, 0.5))
	var_4_8:addTo(var_4_2:getChildByName("rebate_num_pos"))

	local var_4_9 = var_4_6.begin_time + xyd.tables.misc.bankActivitySwitchTime
	local var_4_10 = var_4_6.begin_time + xyd.tables.misc.bankActivityEndTime
	local var_4_11 = os.date(var_0_1:translation("BANK_TIME_FORMAT"), var_4_6.begin_time)
	local var_4_12 = os.date(var_0_1:translation("BANK_TIME_FORMAT"), var_4_9)

	if arg_4_1 == 2 then
		var_4_11 = os.date(var_0_1:translation("BANK_TIME_FORMAT"), var_4_9)
		var_4_12 = os.date(var_0_1:translation("BANK_TIME_FORMAT"), var_4_10)
	end

	var_4_5:setString(var_4_11 .. "-" .. var_4_12)

	local var_4_13 = string.format(var_0_1:translation("ACTIVITY_1098_TEXT1"), math.ceil(100 * xyd.tables.misc.bankActivityRebateRatio[arg_4_1]))

	var_4_2:getChildByName("rebate_percent_text"):setString(var_4_13 .. "%")

	local var_4_14 = var_4_2:getChildByName("btn")
	local var_4_15 = var_4_2:getChildByName("yilingqu")
	local var_4_16 = var_4_2:getChildByName("get_text")
	local var_4_17 = var_4_2:getChildByName("get_gray")
	local var_4_18 = var_4_2:getChildByName("expired")
	local var_4_19 = var_4_2:getChildByName("not_begin")
	local var_4_20 = {
		btn = var_4_14,
		alreadyObtain = var_4_15,
		obtain_bright = var_4_16,
		obtain_gray = var_4_17,
		expired = var_4_18,
		notBegin = var_4_19
	}

	arg_4_0:formatStateText(var_4_20)

	local var_4_21 = xyd.ServerTime.get():getServerTime()

	if var_4_6.is_awarded[arg_4_1] == 1 then
		arg_4_0:setBtnGetState(0, var_4_20)
	elseif var_4_21 < var_4_6.begin_time then
		arg_4_0:setBtnGetState(-2, var_4_20)
	elseif var_4_6.charge_count[arg_4_1] > 0 and (arg_4_1 == 1 and var_4_9 < var_4_21 or arg_4_1 == 2 and var_4_10 < var_4_21) then
		arg_4_0:setBtnGetState(1, var_4_20)
	else
		arg_4_0:setBtnGetState(-1, var_4_20)
	end

	var_4_2:getChildByName("btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			var_4_2:getChildByName("btn"):setScale(0.9)
		elseif arg_5_1 == ccui.TouchEventType.moved then
			var_4_2:getChildByName("btn"):setScale(1)
		elseif arg_5_1 == ccui.TouchEventType.ended then
			var_4_2:getChildByName("btn"):setScale(1)

			if arg_4_0.scrollViewMoved_ == true then
				return
			end

			arg_4_0.activitiesModel:getActivityReward(arg_4_0.activity.table_id, arg_4_1, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					arg_4_0.activity.details.is_awarded[arg_4_1] = 1

					arg_4_0:setBtnGetState(0, var_4_20)

					if arg_6_1.awards then
						arg_4_0.selfPlayer:handleRewards(arg_6_1.awards)
					end
				end
			end)
		end
	end)
	var_4_1:addTo(var_4_0)
	var_4_1:setAnchorPoint(cc.p(0, 0))
	var_4_0:setContentSize(var_4_2:getContentSize())
	var_4_1:setName("source")

	return var_4_0
end

return var_0_0
