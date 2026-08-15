local var_0_0 = class("Activity", import("app.windows.activities.ActivityNormal"))

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.normalActivitiesLayout(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1058/normal_activity.csb")
	local var_2_1 = var_2_0:getChildByName("container")
	local var_2_2 = var_2_1:getChildByName("list")
	local var_2_3 = var_2_2:getContentSize()
	local var_2_4 = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_2_3.width, var_2_3.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_2):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	var_2_0:addTo(arg_2_0.parent)
	var_2_1:getChildByName("save_num_txt"):setString(arg_2_1.details.charge_count)
	var_2_1:getChildByName("rule_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("pet_sell_rule")
		end
	end)

	local var_2_5 = {
		activity = arg_2_1,
		list = var_2_4,
		count = arg_2_2
	}

	arg_2_0:addActivityAwardList(var_2_5)
end

function var_0_0.createAwardList(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1.list
	local var_4_1 = arg_4_1.activity
	local var_4_2 = arg_4_1.listNum
	local var_4_3 = arg_4_1.count

	if arg_4_1.type then
		var_4_0:removeAllItems()
	end

	local var_4_4 = 0
	local var_4_5 = xyd.ServerTime.get():getServerTime()
	local var_4_6 = xyd.splitToNumber(var_4_1.details.award_ids, "|")

	if not var_4_6 or var_4_5 < var_4_1.start_time or var_4_5 > var_4_1.end_time then
		var_4_6 = xyd.tables.activityPetDayTable:getIds()
	end

	for iter_4_0 = 1, #var_4_6 do
		local var_4_7 = var_4_6[iter_4_0]

		if arg_4_0:checkInitItem(var_4_7, arg_4_1) then
			var_4_4 = var_4_4 + 1

			local var_4_8 = var_4_0:newItem()
			local var_4_9 = display.newNode()
			local var_4_10 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1058/activity_item.csb")
			local var_4_11 = var_4_10:getChildByName("container")

			arg_4_0:rewardItemLayout(var_4_1, var_4_11, var_4_3, var_4_7, var_4_4)
			var_4_10:addTo(var_4_9)
			var_4_10:setTouchEnabled(true)
			var_4_10:setAnchorPoint(cc.p(0, 0))
			var_4_10:setPosition(0, 0)
			var_4_10:setTouchSwallowEnabled(false)
			var_4_9:setContentSize(665, 148)
			var_4_8:addContent(var_4_9)
			var_4_8:setItemSize(665, 148)
			var_4_0:addItem(var_4_8)
		end
	end

	var_4_0:reload()
end

function var_0_0.rewardItemLayout(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
	local var_5_0 = arg_5_2:getChildByName("btn")
	local var_5_1 = arg_5_2:getChildByName("yilingqu")
	local var_5_2 = arg_5_2:getChildByName("lingqu")
	local var_5_3 = arg_5_2:getChildByName("get_gray")
	local var_5_4 = arg_5_2:getChildByName("expired")
	local var_5_5 = arg_5_2:getChildByName("not_begin")

	arg_5_2:getChildByName("label_bg"):setVisible(true)

	local var_5_6 = {
		btn = var_5_0,
		alreadyObtain = var_5_1,
		obtain_bright = var_5_2,
		obtain_gray = var_5_3,
		expired = var_5_4,
		notBegin = var_5_5
	}
	local var_5_7 = arg_5_2:getChildByName("reward_container")
	local var_5_8 = arg_5_2:getChildByName("item_title_container")
	local var_5_9 = {
		color = cc.c3b(255, 255, 255)
	}

	var_5_9.size = 20

	local var_5_10 = xyd.AssetLoader.get():loadLabel(var_5_9)

	var_5_10:setMaxLineWidth(280)
	var_5_10:addTo(var_5_8)
	var_5_10:setAnchorPoint(cc.p(0, 0))
	var_5_10:setPosition(10, 3)
	var_5_10:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	local var_5_11 = xyd.tables.activityPetDayTable:name(arg_5_4)

	var_5_10:setString(var_5_11)

	local var_5_12 = xyd.ServerTime.get():getServerTime()
	local var_5_13 = xyd.splitToNumber(arg_5_1.details.is_awarded, "|")
	local var_5_14 = xyd.splitToNumber(arg_5_1.details.can_award, "|")
	local var_5_15 = xyd.tables.activityPetDayTable:gift(arg_5_4)

	if #var_5_15 == 1 then
		arg_5_0:rewardFormat(var_5_7, var_5_15[1])
	else
		arg_5_0:rewardMutiHeroFormat(var_5_7, var_5_15[1], arg_5_4)
	end

	if var_5_12 < arg_5_1.start_time then
		arg_5_0:setBtnGetState(-2, var_5_6)

		return
	elseif var_5_12 > arg_5_1.end_time then
		arg_5_0:setBtnGetState(2, var_5_6)

		return
	end

	if not var_5_13 or not var_5_14 then
		arg_5_0:setBtnGetState(-1, var_5_6)

		return
	end

	if var_5_13[arg_5_5] == 1 then
		arg_5_0:setBtnGetState(0, var_5_6)
	elseif var_5_14[arg_5_5] == 0 then
		arg_5_0:setBtnGetState(-1, var_5_6)
	else
		arg_5_0:setBtnGetState(1, var_5_6)
	end

	var_5_0:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended and arg_5_0.scrollViewMoved_ == false then
			local function var_6_0()
				arg_5_0:setBtnGetState(0, var_5_6)

				local var_7_0 = xyd.luaStringSplit(arg_5_0.activities[arg_5_3].details.is_awarded, "|")
				local var_7_1 = xyd.luaStringSplit(arg_5_0.activities[arg_5_3].details.can_award, "|")

				var_7_0[arg_5_5] = "1"

				local var_7_2 = xyd.luaStringMerge(var_7_0, "|")

				arg_5_0.activities[arg_5_3].details.is_awarded = var_7_2

				local var_7_3 = false

				for iter_7_0 = 1, #var_7_1 do
					if tonumber(var_7_1[iter_7_0]) == 1 and tonumber(var_7_0[iter_7_0]) == 0 then
						var_7_3 = true

						break
					end
				end

				if not var_7_3 then
					arg_5_0.activitiesModel:clearRedMarkState(arg_5_1.table_id, 2)
				end

				local var_7_4 = xyd.WindowManager.get():getWindow("activities")

				if var_7_4 then
					var_7_4:rightLayout()
				end
			end

			if #var_5_15 == 1 then
				arg_5_0.activitiesModel:getActivityReward2(arg_5_1.table_id, arg_5_4, 1, function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						arg_5_0.player:handleRewards(arg_8_1.awards)
						var_6_0()
					end
				end)
			elseif #xyd.tables.activityPetDayTable:modelID(arg_5_4) ~= 0 then
				local var_6_1 = {
					id = arg_5_4,
					activityID = arg_5_1.table_id,
					callback = var_6_0,
					giftIDs = xyd.tables.activityPetDayTable:gift(arg_5_4),
					modelIDs = xyd.tables.activityPetDayTable:modelID(arg_5_4)
				}

				xyd.WindowManager.get():openWindow("select_giftbag", var_6_1)
			elseif #var_5_15 > 1 then
				local var_6_2 = {
					count = arg_5_4,
					table_id = arg_5_1.table_id,
					callback = var_6_0
				}

				xyd.WindowManager.get():openWindow("petday_hero_sell", var_6_2)
			end
		end
	end)
end

function var_0_0.rewardMutiHeroFormat(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = display.newNode()

	var_9_0:setContentSize(arg_9_1:getHeight(), arg_9_1:getHeight())
	xyd.setSpriteBorder(var_9_0, xyd.tables.activityPetDayTable:icon(arg_9_3), 1)
	var_9_0:addTo(arg_9_1)
	var_9_0:setPosition(0, 0)
	var_9_0:setAnchorPoint(cc.p(0, 0))

	local var_9_1 = {}

	var_9_1.id = -100000
	var_9_1.tipsType = 1
	var_9_1.desc1 = xyd.tables.activityPetDayTable:desc(arg_9_3)

	arg_9_0:addTips(var_9_0, var_9_1)

	local var_9_2 = arg_9_1:getContentSize().height
	local var_9_3 = var_9_2 / 4
	local var_9_4 = xyd.tables.gift:items(arg_9_2)

	if #var_9_4 == 1 and var_9_4[1] == 0 then
		var_9_4 = {}
	end

	local var_9_5 = xyd.tables.gift:itemNum(arg_9_2)
	local var_9_6 = #var_9_4

	for iter_9_0 = 2, #var_9_4 do
		local var_9_7 = display.newNode()

		var_9_7:setContentSize(var_9_2, var_9_2)

		if xyd.tables.item:type(var_9_4[iter_9_0]) == -1 then
			xyd.setAvatarBorder(var_9_4[iter_9_0], var_9_7, 1, xyd.tables.hero:initialStar(var_9_4[iter_9_0]))
		else
			xyd.setItemBorder(var_9_7, var_9_4[iter_9_0], false, false, var_9_5[iter_9_0])
		end

		var_9_7:addTo(arg_9_1)
		var_9_7:setAnchorPoint(cc.p(0, 0))
		var_9_7:setPosition((iter_9_0 - 1) * (var_9_2 + var_9_3), 0)

		local var_9_8 = {
			id = var_9_4[iter_9_0],
			lev = xyd.tables.item:level(var_9_4[iter_9_0])
		}

		if xyd.tables.item:type(var_9_4[iter_9_0]) == -1 then
			var_9_8.tipsType = 0
			var_9_8.desc1 = xyd.tables.hero:getDes(var_9_4[iter_9_0])
		elseif specialItem then
			var_9_8.tipsType = 1
			var_9_8.id = -3
		else
			var_9_8.tipsType = 1
			var_9_8.desc1 = xyd.tables.item:desc1(var_9_4[iter_9_0])
			var_9_8.desc2 = xyd.tables.item:desc2(var_9_4[iter_9_0])
		end

		var_9_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_9_4[iter_9_0])
		var_9_8.name = xyd.tables.item:name(var_9_4[iter_9_0])

		arg_9_0:addTips(var_9_7, var_9_8)
	end

	local var_9_9 = xyd.tables.gift:crystal(arg_9_2)

	if var_9_9 and var_9_9 > 0 then
		local var_9_10 = display.newNode()

		var_9_10:setContentSize(var_9_2, var_9_2)
		xyd.setItemBorder(var_9_10, -1, false, false, var_9_9)
		var_9_10:addTo(arg_9_1)
		var_9_10:setAnchorPoint(cc.p(0, 0))
		var_9_10:setPosition(var_9_6 * (var_9_2 + var_9_3), 0)

		local var_9_11 = {}

		var_9_11.id = -1
		var_9_11.tipsType = 1

		arg_9_0:addTips(var_9_10, var_9_11)

		var_9_6 = var_9_6 + 1
	end

	local var_9_12 = xyd.tables.gift:mana(arg_9_2)

	if var_9_12 and var_9_12 > 0 then
		local var_9_13 = display.newNode()

		var_9_13:setContentSize(var_9_2, var_9_2)
		xyd.setItemBorder(var_9_13, -2, false, false, var_9_12)
		var_9_13:addTo(arg_9_1)
		var_9_13:setAnchorPoint(cc.p(0, 0))
		var_9_13:setPosition(var_9_6 * (var_9_2 + var_9_3), 0)

		local var_9_14 = {}

		var_9_14.id = -2
		var_9_14.tipsType = 1

		arg_9_0:addTips(var_9_13, var_9_14)

		local var_9_15 = var_9_6 + 1
	end
end

function var_0_0.checkInitItem(arg_10_0, arg_10_1, arg_10_2)
	return true
end

return var_0_0
