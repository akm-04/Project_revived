local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc.greenhandActivityGears

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
		var_2_0:setPosition(3.5, 5)

		arg_2_0.scroll = arg_2_0.container:getChildByName("scroll")

		local var_2_1 = arg_2_0.scroll:getContentSize()

		arg_2_0.awardedList = cc.ui.UIListView.new({
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

		arg_2_0.awardedList:setBounceable(false)
		arg_2_0.awardedList:setTouchType(false)

		arg_2_0.giftBoxPos = arg_2_0.container:getChildByName("gift_box_pos")
		arg_2_0.awardedIdx = {}

		arg_2_0:update()
		arg_2_0.container:getChildByName("progress_bar"):setVisible(false)
		arg_2_0.container:getChildByName("progress_bg"):setVisible(false)
	end
end

function var_0_0.update(arg_3_0)
	arg_3_0:updateProgress()
	arg_3_0:updateAwardScroll()
end

function var_0_0.updateProgress(arg_4_0)
	local var_4_0 = arg_4_0.activity.details.charge_count
	local var_4_1 = var_0_2[#arg_4_0.activity.details.is_awarded]

	if var_4_1 < var_4_0 then
		var_4_0 = var_4_1
	end

	arg_4_0.container:getChildByName("progress_txt"):setString(var_0_1:translation("ALREADY_DEAL") .. " " .. var_4_0 .. "/" .. var_4_1)
	arg_4_0.container:getChildByName("progress_txt"):enableShadow(xyd.color.FONT_SHADOW_E)
end

function var_0_0.updateGiftBoxs(arg_5_0)
	local var_5_0 = xyd.tables.activityGreenhandGift
	local var_5_1 = 200

	arg_5_0.giftBoxPos:removeAllChildren(true)

	for iter_5_0 = 1, #arg_5_0.activity.details.is_awarded do
		local var_5_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1090/gift_item.csb")
		local var_5_3 = var_5_2:getChildByName("container")

		var_5_2:addTo(arg_5_0.giftBoxPos)
		var_5_2:setPosition(cc.p((iter_5_0 - 1) * var_5_1 + 20, 10))
		var_5_3:getChildByName("time_txt"):setVisible(false)
		var_5_3:getChildByName("gift_light"):setVisible(false)
		var_5_3:getChildByName("gift_gray"):setVisible(false)
		var_5_3:getChildByName("gift_open"):setVisible(false)

		if arg_5_0.activity.details.charge_count < var_0_2[iter_5_0] then
			var_5_3:getChildByName("gift_gray"):setVisible(true)
		elseif iter_5_0 > arg_5_0.activity.details.award_count then
			var_5_3:getChildByName("gift_light"):setVisible(true)
		else
			var_5_3:getChildByName("gift_open"):setVisible(true)
		end
	end
end

function var_0_0.updateAwardScroll(arg_6_0)
	arg_6_0.awardedList:removeAllItems()

	for iter_6_0 = 1, #arg_6_0.activity.details.is_awarded do
		if not xyd.isInTable(arg_6_0.activity.details.is_awarded, iter_6_0) or xyd.isInTable(arg_6_0.awardedIdx, iter_6_0) or arg_6_0.activity.details.award_count == #arg_6_0.activity.details.is_awarded then
			local var_6_0
			local var_6_1 = arg_6_0.awardedList:dequeueItem()

			if not var_6_1 then
				var_6_1 = arg_6_0.awardedList:newItem()
			else
				var_6_1:removeAllChildren(true)
			end

			local var_6_2 = arg_6_0:createListContent(iter_6_0)
			local var_6_3 = var_6_2:getWidth()
			local var_6_4 = var_6_2:getHeight()

			var_6_1:setItemSize(var_6_3, var_6_4)
			var_6_1:addContent(var_6_2)
			arg_6_0.awardedList:addItem(var_6_1)
			arg_6_0.awardedList:reload()
		end
	end
end

function var_0_0.isCanAward(arg_7_0)
	local var_7_0 = arg_7_0.activity.details

	if var_7_0.award_count < #var_7_0.is_awarded and var_7_0.charge_count >= var_0_2[var_7_0.award_count + 1] then
		return true
	end

	return false
end

function var_0_0.createListContent(arg_8_0, arg_8_1)
	local var_8_0 = display.newNode()
	local var_8_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1099/activity_item.csb")
	local var_8_2 = var_8_1:getChildByName("container")
	local var_8_3 = xyd.tables.activityGreenhandGift

	arg_8_0:rewardFormat(var_8_2:getChildByName("reward_container"), var_8_3:gift(arg_8_1))

	local var_8_4 = var_8_2:getChildByName("item_title_container")
	local var_8_5 = {
		color = cc.c3b(255, 255, 255)
	}

	var_8_5.size = 24

	local var_8_6 = xyd.AssetLoader.get():loadLabel(var_8_5)

	var_8_6:addTo(var_8_4)
	var_8_6:setAnchorPoint(cc.p(0, 0))
	var_8_6:setPosition(10, 3)
	var_8_6:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	var_8_6:setString(var_8_3:name(arg_8_1))

	local var_8_7 = arg_8_0.activity.details
	local var_8_8 = var_8_2:getChildByName("btn")
	local var_8_9 = var_8_2:getChildByName("yilingqu")
	local var_8_10 = var_8_2:getChildByName("lingqu")
	local var_8_11 = var_8_2:getChildByName("get_gray")
	local var_8_12 = var_8_2:getChildByName("expired")
	local var_8_13 = var_8_2:getChildByName("not_begin")
	local var_8_14 = {
		btn = var_8_8,
		alreadyObtain = var_8_9,
		obtain_bright = var_8_10,
		obtain_gray = var_8_11,
		expired = var_8_12,
		notBegin = var_8_13
	}
	local var_8_15 = xyd.ServerTime.get():getServerTime()

	if xyd.isInTable(var_8_7.is_awarded, arg_8_1) then
		arg_8_0:setBtnGetState(0, var_8_14)
	elseif arg_8_0:isCanAward() then
		arg_8_0:setBtnGetState(1, var_8_14)
	else
		arg_8_0:setBtnGetState(-1, var_8_14)
	end

	var_8_2:getChildByName("btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended and arg_8_0.scrollViewMoved_ ~= true then
			arg_8_0.activitiesModel:getActivityReward(arg_8_0.activity.table_id, arg_8_1, function(arg_10_0, arg_10_1)
				if arg_10_0 == xyd.error.OK then
					var_8_7.award_count = var_8_7.award_count + 1
					var_8_7.is_awarded[var_8_7.award_count] = arg_8_1

					table.insert(arg_8_0.awardedIdx, arg_8_1)

					if arg_10_1.awards then
						arg_8_0.selfPlayer:handleRewards(arg_10_1.awards)
					end

					arg_8_0:updateAwardScroll()
				end
			end)
		end
	end)
	var_8_1:addTo(var_8_0)
	var_8_1:setAnchorPoint(cc.p(0, 0))
	var_8_0:setContentSize(var_8_2:getContentSize().width + 2, var_8_2:getContentSize().height + 4)
	var_8_1:setPosition(cc.p(1, 2))
	var_8_1:setName("source")

	return var_8_0
end

return var_0_0
