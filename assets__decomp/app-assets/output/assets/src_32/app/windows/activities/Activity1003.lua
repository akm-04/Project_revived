local var_0_0 = class("Activity", import("app.windows.activities.ActivityNormal"))

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

	local var_2_1 = var_2_0:getChildByName("container"):getChildByName("list")
	local var_2_2 = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 650, 320),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_1):onScroll(handler(arg_2_0, arg_2_0.scrollListener))
	local var_2_3 = #xyd.tables.activitySevenLogin:gifts()
	local var_2_4 = {
		list = var_2_2,
		listNum = var_2_3,
		activity = arg_2_0.activity,
		obtainStates = xyd.luaStringSplit(arg_2_0.activity.details.is_awards, "|"),
		count = arg_2_0.idx
	}

	arg_2_0:createAwardList(var_2_4)
end

function var_0_0.rewardItemLayout(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4)
	local var_3_0 = arg_3_2:getChildByName("btn")
	local var_3_1 = arg_3_2:getChildByName("yilingqu")
	local var_3_2 = arg_3_2:getChildByName("lingqu")
	local var_3_3 = arg_3_2:getChildByName("get_gray")
	local var_3_4 = arg_3_2:getChildByName("expired")
	local var_3_5 = arg_3_2:getChildByName("not_begin")
	local var_3_6 = {
		btn = var_3_0,
		alreadyObtain = var_3_1,
		obtain_bright = var_3_2,
		obtain_gray = var_3_3,
		expired = var_3_4,
		notBegin = var_3_5
	}
	local var_3_7 = arg_3_2:getChildByName("reward_container")
	local var_3_8 = arg_3_2:getChildByName("item_title_container")
	local var_3_9 = {
		color = cc.c3b(255, 255, 255)
	}

	var_3_9.size = 20

	local var_3_10 = xyd.AssetLoader.get():loadLabel(var_3_9)

	var_3_10:setMaxLineWidth(280)
	var_3_10:addTo(var_3_8)
	var_3_10:setAnchorPoint(cc.p(0, 0))
	var_3_10:setPosition(10, 3)
	var_3_10:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	local var_3_11 = xyd.tables.activitySevenLogin:name(arg_3_4)

	var_3_10:setString(var_3_11)

	local var_3_12 = xyd.ServerTime.get():getServerTime()

	if arg_3_4 < arg_3_1.details.day_count then
		arg_3_0:setBtnGetState(2, var_3_6)
	elseif arg_3_4 > arg_3_1.details.day_count then
		arg_3_0:setBtnGetState(-1, var_3_6)
	elseif arg_3_1.details.can_award == 1 and arg_3_1.details.is_awarded == 0 then
		arg_3_0.parent.guideBtn = var_3_0

		arg_3_0:setBtnGetState(1, var_3_6)
	elseif arg_3_1.details.is_awarded == 1 then
		arg_3_0:setBtnGetState(0, var_3_6)
	end

	local var_3_13 = xyd.tables.activitySevenLogin:name(arg_3_4)

	var_3_10:setString(var_3_13)
	arg_3_0:rewardFormat(var_3_7, arg_3_4)

	if not arg_3_0:checkTime(arg_3_1) then
		arg_3_0:setBtnGetState(-1, var_3_6)
	end

	if var_3_12 < arg_3_1.start_time then
		arg_3_0:setBtnGetState(-2, var_3_6)
	end

	var_3_0:addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0.activitiesModel:getActivityReward(arg_3_1.table_id, nil, function(arg_5_0, arg_5_1)
				if arg_5_0 == xyd.error.OK then
					arg_3_0.activity.details.sign_times = arg_5_1.sign_times

					if arg_5_1.sign_times == 2 then
						xyd.tracking(xyd.AFInAppEventType.SIGNIN_SECOND_DAY, "")
					end

					arg_3_0.player:handleRewards(arg_5_1.awards)
					arg_3_0:setBtnGetState(0, var_3_6)
					arg_3_0.activitiesModel:clearRedMarkState(arg_3_1.table_id, 2)

					if arg_3_0.activities[arg_3_3].details.is_awarded then
						arg_3_0.activities[arg_3_3].details.is_awarded = 1
					end

					if arg_3_0.activities[arg_3_3].details.is_awards then
						local var_5_0 = xyd.luaStringSplit(arg_3_0.activities[arg_3_3].details.is_awards, "|")

						var_5_0[arg_3_4] = "1"

						local var_5_1 = xyd.luaStringMerge(var_5_0, "|")

						arg_3_0.activities[arg_3_3].details.is_awards = var_5_1
					end

					local var_5_2 = xyd.WindowManager.get():getWindow("activities")

					if var_5_2 then
						var_5_2:rightLayout()
					end
				end
			end)
		end
	end)
end

function var_0_0.createAwardList(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1.list
	local var_6_1 = arg_6_1.activity
	local var_6_2 = arg_6_1.listNum
	local var_6_3 = arg_6_1.count

	if arg_6_1.type then
		var_6_0:removeAllItems()
	end

	for iter_6_0 = 1, var_6_2 do
		if arg_6_0:checkInitItem(iter_6_0, arg_6_1) then
			local var_6_4 = var_6_0:newItem()
			local var_6_5 = display.newNode()
			local var_6_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1003/item.csb")
			local var_6_7 = var_6_6:getChildByName("container")

			arg_6_0:rewardItemLayout(var_6_1, var_6_7, var_6_3, iter_6_0, var_6_2, arg_6_1.type)
			var_6_6:addTo(var_6_5)
			var_6_6:setTouchEnabled(true)
			var_6_6:setAnchorPoint(cc.p(0, 0))
			var_6_6:setPosition(0, 0)
			var_6_6:setTouchSwallowEnabled(false)
			var_6_5:setContentSize(665, 148)
			var_6_4:addContent(var_6_5)
			var_6_4:setItemSize(665, 148)
			var_6_0:addItem(var_6_4)
		end
	end

	var_6_0:reload()
end

function var_0_0.rewardFormat(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = xyd.tables.activitySevenLogin:gift(arg_7_2)
	local var_7_1 = xyd.tables.activitySevenLogin:glowItem(arg_7_2)
	local var_7_2 = arg_7_1:getContentSize().height - 10
	local var_7_3 = var_7_2 / 4
	local var_7_4 = xyd.tables.gift:items(var_7_0)

	if #var_7_4 == 1 and var_7_4[1] == 0 then
		var_7_4 = {}
	end

	local var_7_5 = xyd.tables.gift:itemNum(var_7_0)
	local var_7_6 = #var_7_4
	local var_7_7 = 0

	for iter_7_0 = 1, #var_7_4 do
		local var_7_8 = xyd.tables.item:type(var_7_4[iter_7_0])

		var_7_7 = var_7_7 + 1

		local var_7_9 = display.newNode()

		var_7_9:setContentSize(var_7_2, var_7_2)

		if var_7_8 == -1 then
			xyd.setAvatarBorder(var_7_4[iter_7_0], var_7_9, 1, xyd.tables.hero:initialStar(var_7_4[iter_7_0]))
		else
			local var_7_10 = false

			for iter_7_1, iter_7_2 in pairs(var_7_1) do
				if iter_7_2 == var_7_4[iter_7_0] then
					var_7_10 = true
				end
			end

			xyd.setItemBorder(var_7_9, var_7_4[iter_7_0], var_7_10, false, var_7_5[iter_7_0])
		end

		var_7_9:addTo(arg_7_1)
		var_7_9:setAnchorPoint(cc.p(0, 0))
		var_7_9:setPosition((var_7_7 - 1) * (var_7_2 + var_7_3), 0)

		local var_7_11 = {
			id = var_7_4[iter_7_0],
			lev = xyd.tables.item:level(var_7_4[iter_7_0])
		}

		if xyd.tables.item:type(var_7_4[iter_7_0]) == -1 then
			var_7_11.tipsType = 0
			var_7_11.desc1 = xyd.tables.hero:getDes(var_7_4[iter_7_0])
		elseif specialItem then
			var_7_11.tipsType = 1
			var_7_11.id = -3
		else
			var_7_11.tipsType = 1
			var_7_11.desc1 = xyd.tables.item:desc1(var_7_4[iter_7_0])
			var_7_11.desc2 = xyd.tables.item:desc2(var_7_4[iter_7_0])
		end

		var_7_11.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_7_4[iter_7_0])
		var_7_11.name = xyd.tables.item:name(var_7_4[iter_7_0])

		arg_7_0:addTips(var_7_9, var_7_11)
	end

	local var_7_12 = xyd.tables.gift:crystal(var_7_0)

	if var_7_12 and var_7_12 > 0 then
		var_7_7 = var_7_7 + 1

		local var_7_13 = display.newNode()

		var_7_13:setContentSize(var_7_2, var_7_2)
		xyd.setItemBorder(var_7_13, -1, false, false, var_7_12)
		var_7_13:addTo(arg_7_1)
		var_7_13:setAnchorPoint(cc.p(0, 0))
		var_7_13:setPosition((var_7_7 - 1) * (var_7_2 + var_7_3), 0)

		local var_7_14 = {}

		var_7_14.id = -1
		var_7_14.tipsType = 1

		arg_7_0:addTips(var_7_13, var_7_14)

		var_7_6 = var_7_6 + 1
	end

	local var_7_15 = xyd.tables.gift:mana(var_7_0)

	if var_7_15 and var_7_15 > 0 then
		local var_7_16 = var_7_7 + 1
		local var_7_17 = display.newNode()

		var_7_17:setContentSize(var_7_2, var_7_2)
		xyd.setItemBorder(var_7_17, -2, false, false, var_7_15)
		var_7_17:addTo(arg_7_1)
		var_7_17:setAnchorPoint(cc.p(0, 0))
		var_7_17:setPosition((var_7_16 - 1) * (var_7_2 + var_7_3), 0)

		local var_7_18 = {}

		var_7_18.id = -2
		var_7_18.tipsType = 1

		arg_7_0:addTips(var_7_17, var_7_18)

		local var_7_19 = var_7_6 + 1
	end

	return arg_7_1
end

function var_0_0.setGiftIcon(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = arg_8_1:getContentSize().width
	local var_8_1 = arg_8_1:getContentSize().height

	icon = xyd.AssetLoader:get():loadSprite(arg_8_2)

	local var_8_2 = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

	var_8_2:setPosition(var_8_0 / 2, var_8_1 / 2)
	var_8_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_2:setScale(var_8_1 / var_8_2:getHeight())

	local var_8_3 = var_8_1 / var_8_2:getHeight()
	local var_8_4 = cc.ClippingNode:create()

	var_8_4:setStencil(var_8_2)
	var_8_4:setInverted(true)
	var_8_4:setAlphaThreshold(0)
	arg_8_1:addChild(var_8_4)
	var_8_4:addChild(icon)
	icon:setPosition(var_8_0 / 2, var_8_1 / 2)
	icon:setAnchorPoint(cc.p(0.5, 0.5))

	local var_8_5 = var_8_1 / icon:getHeight()

	icon:setScale(var_8_5)
	var_8_4:setLocalZOrder(-1)

	local var_8_6 = xyd.getBorder(1, false)

	xyd.displaySpriteOnContainer(var_8_6, arg_8_1, true)
end

function var_0_0.checkInitItem(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_2.activity

	if xyd.ServerTime.get():getServerTime() >= var_9_0.start_time and arg_9_1 < var_9_0.details.day_count then
		return false
	end

	return true
end

function var_0_0.playGuide(arg_10_0)
	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.ACTIVITY_FIVE then
		local var_10_0 = arg_10_0.parent.guideBtn

		if not var_10_0 then
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_END)
			xyd.StoryData.get():persist()

			return
		end

		local var_10_1 = {
			680,
			250
		}
		local var_10_2 = false

		xyd.showGuideWnd(var_10_0, nil, nil, 1, var_10_1, var_10_2)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_SIX)
		xyd.StoryData.get():persist()
	end
end

return var_0_0
