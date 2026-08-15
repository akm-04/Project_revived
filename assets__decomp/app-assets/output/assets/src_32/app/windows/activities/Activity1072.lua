local var_0_0 = class("Activity", import("app.windows.activities.ActivityNormal"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.normalActivitiesLayout(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1072/day_recharge.csb")
	local var_2_1 = var_2_0:getChildByName("container")
	local var_2_2 = var_2_1:getChildByName("award_container")
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

	local var_2_5 = {
		activity = arg_2_1,
		list = var_2_4,
		count = arg_2_2
	}

	arg_2_0:addActivityAwardList(var_2_5)
	var_2_1:getChildByName("txt_num"):setString(arg_2_1.details.charge_count)
end

function var_0_0.addActivityAwardList(arg_3_0, arg_3_1)
	arg_3_1.listNum = #xyd.tables.activityNewDayCharge:getIDs()

	if not arg_3_1.listNum then
		return
	else
		arg_3_0:createAwardList(arg_3_1)
	end
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
	local var_4_6 = xyd.tables.activityNewDayCharge:getIDs()

	for iter_4_0 = 1, #var_4_6 do
		local var_4_7 = var_4_6[iter_4_0]

		if arg_4_0:checkInitItem(var_4_7, arg_4_1) then
			var_4_4 = var_4_4 + 1

			local var_4_8 = var_4_0:newItem()
			local var_4_9 = display.newNode()
			local var_4_10 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1072/award_item.csb")
			local var_4_11 = var_4_10:getChildByName("container")

			arg_4_0:rewardItemLayout(var_4_1, var_4_11, var_4_3, var_4_7, var_4_4)
			var_4_10:addTo(var_4_9)
			var_4_10:setTouchEnabled(true)
			var_4_10:setAnchorPoint(cc.p(0, 0))
			var_4_10:setPosition(0, 5)
			var_4_10:setTouchSwallowEnabled(false)
			var_4_9:setContentSize(667, 171)
			var_4_8:addContent(var_4_9)
			var_4_8:setItemSize(667, 171)
			var_4_0:addItem(var_4_8)
		end
	end

	var_4_0:reload()
end

function var_0_0.rewardItemLayout(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
	local var_5_0 = arg_5_2:getChildByName("btn_get")
	local var_5_1 = arg_5_2:getChildByName("yilingqu")
	local var_5_2 = var_5_0:getChildByName("txt_lingqu")
	local var_5_3 = var_5_0:getChildByName("txt_lingqu2")

	var_5_2:setString(var_0_1:translation("OBTAIN"))
	var_5_3:setString(var_0_1:translation("OBTAIN"))

	local var_5_4 = {
		btn = var_5_0,
		alreadyObtain = var_5_1,
		obtain_bright = var_5_2,
		obtain_gray = var_5_3
	}
	local var_5_5 = arg_5_2:getChildByName("award_container")

	arg_5_2:getChildByName("text_charge"):setString(xyd.tables.activityNewDayCharge:name(arg_5_4))

	local var_5_6 = xyd.ServerTime.get():getServerTime()
	local var_5_7 = xyd.splitToNumber(arg_5_1.details.is_awards, "|")
	local var_5_8 = xyd.tables.activityNewDayCharge:gift(arg_5_4)

	if #var_5_8 == 1 then
		arg_5_0:rewardFormat(var_5_5, var_5_8[1], nil, 15)
	else
		arg_5_0:rewardMutiHeroFormat(var_5_5, var_5_8[1], arg_5_4)
	end

	if var_5_6 < arg_5_1.start_time then
		arg_5_0:setBtnGetState(-1, var_5_4)

		return
	elseif var_5_6 > arg_5_1.end_time then
		arg_5_0:setBtnGetState(-1, var_5_4)

		return
	end

	if not var_5_7 then
		arg_5_0:setBtnGetState(-1, var_5_4)

		return
	end

	local var_5_9 = xyd.tables.activityNewDayCharge:charge(arg_5_4)

	if var_5_7[arg_5_5] == 1 then
		arg_5_0:setBtnGetState(0, var_5_4)
	elseif var_5_7[arg_5_5] == 0 and var_5_9 <= arg_5_1.details.charge_count then
		arg_5_0:setBtnGetState(1, var_5_4)
	else
		arg_5_0:setBtnGetState(-1, var_5_4)
	end

	var_5_0:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			var_5_0:setScale(0.9)
		elseif arg_6_1 == ccui.TouchEventType.cancled then
			var_5_0:setScale(1)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			local function var_6_0()
				arg_5_0:setBtnGetState(0, var_5_4)

				local var_7_0 = xyd.luaStringSplit(arg_5_0.activities[arg_5_3].details.is_awards, "|")

				var_7_0[arg_5_5] = "1"

				local var_7_1 = xyd.luaStringMerge(var_7_0, "|")

				arg_5_0.activities[arg_5_3].details.is_awards = var_7_1

				arg_5_0:refreshRedPoint()
			end

			var_5_0:setScale(1)

			if #var_5_8 == 1 then
				arg_5_0.activitiesModel:getActivityReward2(arg_5_1.table_id, arg_5_4, 1, function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						arg_5_0.player:handleRewards(arg_8_1.awards)
						var_6_0()
					end
				end)
			else
				local var_6_1 = {
					count = arg_5_4,
					table_id = arg_5_1.table_id,
					callback = var_6_0
				}

				xyd.WindowManager.get():openWindow("gift_choose", var_6_1)
			end
		end
	end)
end

function var_0_0.setBtnGetState(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_1 == 1 then
		arg_9_2.btn:setTouchEnabled(true)
		arg_9_2.btn:setBright(true)
		arg_9_2.alreadyObtain:setVisible(false)
		arg_9_2.obtain_bright:setVisible(true)
		arg_9_2.obtain_gray:setVisible(false)
	elseif arg_9_1 == -1 then
		arg_9_2.btn:setTouchEnabled(false)
		arg_9_2.btn:setBright(false)
		arg_9_2.alreadyObtain:setVisible(false)
		arg_9_2.obtain_bright:setVisible(false)
		arg_9_2.obtain_gray:setVisible(true)
	elseif arg_9_1 == 0 then
		arg_9_2.btn:setVisible(false)
		arg_9_2.btn:setTouchEnabled(false)
		arg_9_2.btn:setBright(false)
		arg_9_2.alreadyObtain:setVisible(true)
		arg_9_2.obtain_bright:setVisible(false)
		arg_9_2.obtain_gray:setVisible(false)
	end
end

function var_0_0.rewardMutiHeroFormat(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = display.newNode()

	var_10_0:setContentSize(arg_10_1:getHeight(), arg_10_1:getHeight())
	xyd.setSpriteBorder(var_10_0, xyd.tables.activityNewDayCharge:icon(arg_10_3), 1)
	var_10_0:addTo(arg_10_1)
	var_10_0:setPosition(0, 0)
	var_10_0:setAnchorPoint(cc.p(0, 0))

	local var_10_1 = {}

	var_10_1.id = -100000
	var_10_1.tipsType = 1
	var_10_1.desc1 = xyd.tables.activityNewDayCharge:desc(arg_10_3)

	arg_10_0:addTips(var_10_0, var_10_1)

	local var_10_2 = arg_10_1:getContentSize().height
	local var_10_3 = 15
	local var_10_4 = xyd.tables.gift:items(arg_10_2)

	if #var_10_4 == 1 and var_10_4[1] == 0 then
		var_10_4 = {}
	end

	local var_10_5 = xyd.tables.gift:itemNum(arg_10_2)
	local var_10_6 = #var_10_4

	for iter_10_0 = 2, #var_10_4 do
		local var_10_7 = display.newNode()

		var_10_7:setContentSize(var_10_2, var_10_2)

		if xyd.tables.item:type(var_10_4[iter_10_0]) == -1 then
			xyd.setAvatarBorder(var_10_4[iter_10_0], var_10_7, 1, xyd.tables.hero:initialStar(var_10_4[iter_10_0]))
		else
			xyd.setItemBorder(var_10_7, var_10_4[iter_10_0], false, false, var_10_5[iter_10_0])
		end

		var_10_7:addTo(arg_10_1)
		var_10_7:setAnchorPoint(cc.p(0, 0))
		var_10_7:setPosition((iter_10_0 - 1) * (var_10_2 + var_10_3), 0)

		local var_10_8 = {
			id = var_10_4[iter_10_0],
			lev = xyd.tables.item:level(var_10_4[iter_10_0])
		}

		if xyd.tables.item:type(var_10_4[iter_10_0]) == -1 then
			var_10_8.tipsType = 0
			var_10_8.desc1 = xyd.tables.hero:getDes(var_10_4[iter_10_0])
		elseif specialItem then
			var_10_8.tipsType = 1
			var_10_8.id = -3
		else
			var_10_8.tipsType = 1
			var_10_8.desc1 = xyd.tables.item:desc1(var_10_4[iter_10_0])
			var_10_8.desc2 = xyd.tables.item:desc2(var_10_4[iter_10_0])
		end

		var_10_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_10_4[iter_10_0])
		var_10_8.name = xyd.tables.item:name(var_10_4[iter_10_0])

		arg_10_0:addTips(var_10_7, var_10_8)
	end

	local var_10_9 = xyd.tables.gift:crystal(arg_10_2)

	if var_10_9 and var_10_9 > 0 then
		local var_10_10 = display.newNode()

		var_10_10:setContentSize(var_10_2, var_10_2)
		xyd.setItemBorder(var_10_10, -1, false, false, var_10_9)
		var_10_10:addTo(arg_10_1)
		var_10_10:setAnchorPoint(cc.p(0, 0))
		var_10_10:setPosition(var_10_6 * (var_10_2 + var_10_3), 0)

		local var_10_11 = {}

		var_10_11.id = -1
		var_10_11.tipsType = 1

		arg_10_0:addTips(var_10_10, var_10_11)

		var_10_6 = var_10_6 + 1
	end

	local var_10_12 = xyd.tables.gift:mana(arg_10_2)

	if var_10_12 and var_10_12 > 0 then
		local var_10_13 = display.newNode()

		var_10_13:setContentSize(var_10_2, var_10_2)
		xyd.setItemBorder(var_10_13, -2, false, false, var_10_12)
		var_10_13:addTo(arg_10_1)
		var_10_13:setAnchorPoint(cc.p(0, 0))
		var_10_13:setPosition(var_10_6 * (var_10_2 + var_10_3), 0)

		local var_10_14 = {}

		var_10_14.id = -2
		var_10_14.tipsType = 1

		arg_10_0:addTips(var_10_13, var_10_14)

		local var_10_15 = var_10_6 + 1
	end
end

function var_0_0.checkInitItem(arg_11_0, arg_11_1, arg_11_2)
	return true
end

return var_0_0
