local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityNewCharge

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)
	arg_2_0:normalActivitiesLayout(arg_2_0.activity, arg_2_0.idx)
end

function var_0_0.normalActivitiesLayout(arg_3_0, arg_3_1, arg_3_2)
	if not arg_3_0.res or arg_3_0.res == "0" then
		print("No res available.")

		return
	end

	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_3_0.res)
	local var_3_1 = var_3_0:getChildByName("bg")
	local var_3_2 = var_3_0:getChildByName("bg"):getChildByName("list")
	local var_3_3 = var_3_2:getContentSize()
	local var_3_4 = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_3.width, var_3_3.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_2):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	var_3_0:addTo(arg_3_0.parent)

	local var_3_5 = {
		activity = arg_3_1,
		list = var_3_4,
		count = arg_3_2
	}

	arg_3_0:addActivityAwardList(var_3_5)
	var_3_0:getChildByName("bg"):getChildByName("txt_num"):setString(arg_3_1.details.charge_count)
end

function var_0_0.addActivityAwardList(arg_4_0, arg_4_1)
	local var_4_0 = xyd.tables.activities:tableName(arg_4_1.activity.table_id)

	if var_4_0 and var_4_0 ~= "" then
		arg_4_1.listNum = #var_0_2:gifts()
		arg_4_1.obtainStates = xyd.luaStringSplit(arg_4_1.activity.details.is_awards, "|")

		if not arg_4_1.listNum then
			return
		else
			arg_4_0:createAwardList(arg_4_1)
		end
	end
end

function var_0_0.createAwardList(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1.list
	local var_5_1 = arg_5_1.activity
	local var_5_2 = arg_5_1.listNum
	local var_5_3 = arg_5_1.count

	if arg_5_1.type then
		var_5_0:removeAllItems()
	end

	for iter_5_0 = 1, var_5_2 do
		if arg_5_0:checkInitItem(iter_5_0, arg_5_1) then
			local var_5_4 = var_5_0:newItem()
			local var_5_5 = display.newNode()
			local var_5_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1073/activity1073_item.csb")
			local var_5_7 = var_5_6:getChildByName("bg")

			arg_5_0:rewardItemLayout(var_5_1, var_5_7, var_5_3, iter_5_0)
			var_5_6:addTo(var_5_5)
			var_5_6:setTouchEnabled(true)
			var_5_6:setAnchorPoint(cc.p(0, 0))
			var_5_6:setPosition(0, 5)
			var_5_6:setTouchSwallowEnabled(false)
			var_5_5:setContentSize(667, 171)
			var_5_4:addContent(var_5_5)
			var_5_4:setItemSize(666, 171)
			var_5_0:addItem(var_5_4)
		end
	end

	var_5_0:reload()
end

function var_0_0.rewardItemLayout(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4)
	local var_6_0 = arg_6_2:getChildByName("btn")
	local var_6_1 = arg_6_2:getChildByName("yilingqu")
	local var_6_2 = var_6_0:getChildByName("lingqu")
	local var_6_3 = var_6_0:getChildByName("get_gray")
	local var_6_4 = arg_6_2:getChildByName("expired")
	local var_6_5 = var_6_0:getChildByName("not_begin")
	local var_6_6 = {
		btn = var_6_0,
		alreadyObtain = var_6_1,
		obtain_bright = var_6_2,
		obtain_gray = var_6_3,
		expired = var_6_4,
		notBegin = var_6_5
	}
	local var_6_7 = arg_6_2:getChildByName("reward_container")
	local var_6_8 = arg_6_2:getChildByName("item_title_container")
	local var_6_9 = {
		color = cc.c3b(255, 255, 255)
	}

	var_6_9.size = 20

	local var_6_10 = xyd.AssetLoader.get():loadLabel(var_6_9)

	var_6_10:setMaxLineWidth(280)
	var_6_10:addTo(var_6_8)
	var_6_10:setAnchorPoint(cc.p(0, 0))
	var_6_10:setPosition(0, 0)

	local var_6_11 = var_0_2:name(arg_6_4)

	var_6_10:setString(var_6_11)

	local var_6_12 = xyd.ServerTime.get():getServerTime()
	local var_6_13 = xyd.luaStringSplit(arg_6_1.details.is_awards, "|")

	if var_0_2:recharge(arg_6_4) > arg_6_1.details.charge_count then
		arg_6_0:setBtnGetState(-1, var_6_6)
	elseif var_6_13[arg_6_4] == "1" then
		arg_6_0:setBtnGetState(0, var_6_6)
	else
		arg_6_0:setBtnGetState(1, var_6_6)
	end

	local var_6_14 = var_0_2:gift(arg_6_4)

	if #var_6_14 == 1 then
		arg_6_0:rewardFormat(var_6_7, var_6_14[1])
	else
		arg_6_0:rewardMutiHeroFormat(var_6_7, var_6_14[1], arg_6_4)
	end

	if not arg_6_0:checkTime(arg_6_1) then
		arg_6_0:setBtnGetState(-1, var_6_6)
	end

	if var_6_12 < arg_6_1.start_time then
		arg_6_0:setBtnGetState(-2, var_6_6)
	end

	var_6_0:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			local function var_7_0()
				arg_6_0:setBtnGetState(0, var_6_6)

				if arg_6_0.activities[arg_6_3].details.is_awarded then
					arg_6_0.activities[arg_6_3].details.is_awarded = 1
				end

				if arg_6_0.activities[arg_6_3].details.is_awards then
					local var_8_0 = xyd.luaStringSplit(arg_6_0.activities[arg_6_3].details.is_awards, "|")

					var_8_0[arg_6_4] = "1"

					local var_8_1 = xyd.luaStringMerge(var_8_0, "|")

					arg_6_0.activities[arg_6_3].details.is_awards = var_8_1
				end

				arg_6_0:refreshRedPoint()
			end

			if #var_6_14 == 1 then
				arg_6_0.activitiesModel:getActivityReward2(arg_6_1.table_id, arg_6_4, 1, function(arg_9_0, arg_9_1)
					if arg_9_0 == xyd.error.OK then
						arg_6_0.player:handleRewards(arg_9_1.awards)
						var_7_0()
					end
				end)
			else
				local var_7_1 = {
					count = arg_6_4,
					table_id = arg_6_1.table_id,
					callback = var_7_0
				}

				xyd.WindowManager.get():openWindow("gift_choose", var_7_1)
			end
		end
	end)
end

function var_0_0.rewardMutiHeroFormat(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = display.newNode()

	var_10_0:setContentSize(arg_10_1:getHeight(), arg_10_1:getHeight())
	xyd.setSpriteBorder(var_10_0, var_0_2:icon(arg_10_3), 1)
	var_10_0:addTo(arg_10_1)
	var_10_0:setPosition(0, 0)
	var_10_0:setAnchorPoint(cc.p(0, 0))

	local var_10_1 = {}

	var_10_1.id = -100000
	var_10_1.tipsType = 1
	var_10_1.desc1 = var_0_2:desc(arg_10_3)

	arg_10_0:addTips(var_10_0, var_10_1)

	local var_10_2 = arg_10_1:getContentSize().height
	local var_10_3 = var_10_2 / 4
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
