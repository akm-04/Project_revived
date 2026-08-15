local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

function var_0_0.show(arg_1_0, arg_1_1)
	var_0_0.super.show(arg_1_0, arg_1_1)
	dump(arg_1_0.activity)
	dump(arg_1_0.idx)
	arg_1_0:normalActivitiesLayout(arg_1_0.activity, arg_1_0.idx)
end

function var_0_0.normalActivitiesLayout(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1040/1040.csb")

	var_2_0:addTo(arg_2_0.parent)

	local var_2_1 = var_2_0:getChildByName("container")
	local var_2_2 = var_2_1:getContentSize()
	local var_2_3 = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_2_2.width, var_2_2.height),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_1)
	local var_2_4 = var_2_3:newItem()
	local var_2_5 = xyd.AssetLoader.get():loadSprite("windows/activities/1040/top_pic.png")

	var_2_4:addContent(var_2_5)
	var_2_4:setItemSize(var_2_2.width, 310)
	var_2_3:addItem(var_2_4)

	local var_2_6 = var_2_3:newItem()
	local var_2_7 = display.newNode()
	local var_2_8 = {
		color = cc.c3b(255, 255, 255)
	}

	var_2_8.size = 22

	local var_2_9 = xyd.AssetLoader.get():loadLabel(var_2_8)

	var_2_9:setMaxLineWidth(var_2_2.width - 30)
	var_2_9:setLineHeight(28)
	var_2_9:setString(xyd.tables.activities:desc(arg_2_1.table_id))
	var_2_9:addTo(var_2_7)
	var_2_9:setAnchorPoint(cc.p(0, 0))
	var_2_9:setPosition(25, 0)
	var_2_7:setContentSize(var_2_2.width, var_2_9:getContentSize().height)

	local var_2_10 = xyd.AssetLoader.get():loadSprite("windows/activities/1040/star.png")

	var_2_10:setAnchorPoint(0, 1)
	var_2_10:setPosition(0, var_2_9:getContentSize().height - 5)
	var_2_7:addChild(var_2_10)
	var_2_6:addContent(var_2_7)
	var_2_6:setItemSize(var_2_2.width, var_2_9:getContentSize().height)
	var_2_3:addItem(var_2_6)
	arg_2_0:addChargeLabel(var_2_3, var_2_2.width, arg_2_1)
	var_2_3:reload()

	local var_2_11 = {
		activity = arg_2_1,
		list = var_2_3,
		count = arg_2_2,
		width = var_2_2.width
	}

	arg_2_0:addActivityAwardList(var_2_11)
end

function var_0_0.addChargeLabel(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	if arg_3_3.details and arg_3_3.details.charge_count then
		local var_3_0 = arg_3_1:newItem()
		local var_3_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1040/charge_item.csb")
		local var_3_2 = var_3_1:getChildByName("container")

		var_3_1:setContentSize(var_3_2:getContentSize())
		var_3_2:getChildByName("txt_charge"):setString(var_0_1:translation("ACTIVITY_TODAY_HAS_SAVED"))
		var_3_2:getChildByName("txt_num"):setString(arg_3_3.details.charge_count)
		var_3_0:addContent(var_3_1)
		var_3_0:setItemSize(arg_3_2, 40)
		arg_3_1:addItem(var_3_0)
	elseif arg_3_3.details and arg_3_3.details.consume_count then
		local var_3_3 = arg_3_1:newItem()
		local var_3_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1040/charge_item.csb")
		local var_3_5 = var_3_4:getChildByName("container")

		var_3_4:setContentSize(var_3_5:getContentSize())
		var_3_5:getChildByName("txt_charge"):setString(var_0_1:translation("ACTIVITY_TODAY_HAS_COST"))
		var_3_5:getChildByName("txt_num"):setString(arg_3_3.details.consume_count)
		var_3_3:addContent(var_3_4)
		var_3_3:setItemSize(arg_3_2, 40)
		arg_3_1:addItem(var_3_3)
	else
		local var_3_6 = arg_3_1:newItem()
		local var_3_7 = display.newNode()

		var_3_7:setContentSize(arg_3_2, 20)
		var_3_6:addContent(var_3_7)
		var_3_6:setItemSize(arg_3_2, 20)
		arg_3_1:addItem(var_3_6)
	end
end

function var_0_0.rewardHeroSellingFormat(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = display.newNode()

	var_4_0:setContentSize(arg_4_1:getHeight(), arg_4_1:getHeight())
	xyd.setSpriteBorder(var_4_0, xyd.tables.activityHeroSelling:icon(arg_4_3), 1)
	var_4_0:addTo(arg_4_1)
	var_4_0:setPosition(0, 0)
	var_4_0:setAnchorPoint(cc.p(0, 0))

	local var_4_1 = {}

	var_4_1.id = -6
	var_4_1.tipsType = 1

	arg_4_0:addTips(var_4_0, var_4_1, arg_4_3)
end

function var_0_0.addTips(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	arg_5_1:setTouchEnabled(true)
	arg_5_1:setTouchSwallowEnabled(false)

	local var_5_0

	arg_5_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			var_5_0 = arg_6_0.y
			arg_5_2.itemID = xyd.tables.activityHeroSelling:item(arg_5_3)
			arg_5_2.callback = callback
			arg_5_2.onlyShow = true

			xyd.WindowManager.get():openWindow("activity_select_hero", arg_5_2)

			return true
		elseif arg_6_0.name == "moved" then
			local var_6_0 = arg_6_0.y

			if math.abs(var_6_0 - var_5_0) > 30 then
				-- block empty
			end
		elseif arg_6_0.name == "ended" then
			-- block empty
		end
	end)
end

function var_0_0.addActivityAwardList(arg_7_0, arg_7_1)
	local var_7_0 = xyd.tables.activities:tableName(arg_7_1.activity.table_id)

	if var_7_0 and var_7_0 ~= "" then
		arg_7_1.listNum = #import("app.common.tables." .. var_7_0).new():getItems()
		arg_7_1.choosenHeros = arg_7_0.activity.details.ids

		if not arg_7_1.listNum then
			return
		else
			arg_7_0:createAwardList(arg_7_1)
		end
	end
end

function var_0_0.createAwardList(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_1.list
	local var_8_1 = arg_8_1.activity
	local var_8_2 = arg_8_1.listNum
	local var_8_3 = arg_8_1.count
	local var_8_4 = arg_8_1.choosenHeros

	if arg_8_1.type then
		var_8_0:removeAllItems()
	end

	for iter_8_0 = 1, var_8_2 do
		if arg_8_0:checkInitItem(iter_8_0, arg_8_1) then
			for iter_8_1 = 1, 2 do
				local var_8_5 = var_8_0:newItem()
				local var_8_6 = display.newNode()
				local var_8_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1040/item.csb")
				local var_8_8 = var_8_7:getChildByName("container")

				arg_8_0:rewardItemLayout(var_8_1, var_8_8, var_8_3, iter_8_0, iter_8_1)
				var_8_7:addTo(var_8_6)
				var_8_7:setTouchEnabled(true)
				var_8_7:setAnchorPoint(cc.p(0, 0))
				var_8_7:setPosition(25, 0)
				var_8_7:setTouchSwallowEnabled(false)
				var_8_6:setContentSize(arg_8_1.width, 159)
				var_8_5:addContent(var_8_6)
				var_8_5:setItemSize(arg_8_1.width, 159)
				var_8_0:addItem(var_8_5)
			end
		end
	end

	var_8_0:reload()
end

function var_0_0.rewardItemLayout(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5)
	local var_9_0 = xyd.tables.activityHeroSelling:recharge(arg_9_1.details.day_count)

	arg_9_2:getChildByName("desc"):setString(string.format(xyd.tables.activityHeroSelling:name(arg_9_4), var_9_0[arg_9_5] or 0))

	local var_9_1 = arg_9_2:getChildByName("btn")

	var_9_1:getChildByName("txt"):setString(var_0_1:translation("OBTAIN"))

	local var_9_2 = arg_9_2:getChildByName("award_container")
	local var_9_3 = xyd.ServerTime.get():getServerTime()

	if not arg_9_0:canAward(arg_9_1, arg_9_5) then
		var_9_1:setTouchEnabled(false)
		var_9_1:setBright(false)
	end

	arg_9_0:rewardHeroSellingFormat(var_9_2, arg_9_1, arg_9_4)

	if not arg_9_0:checkTime(arg_9_1) then
		var_9_1:setTouchEnabled(false)
		var_9_1:setBright(false)
	end

	if var_9_3 < arg_9_1.start_time then
		var_9_1:setTouchEnabled(false)
		var_9_1:setBright(false)
	end

	var_9_1:addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(var_9_1, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			local function var_10_0()
				if arg_9_0.activities[arg_9_3].details.award_count then
					arg_9_0.activities[arg_9_3].details.award_count = arg_9_0.activities[arg_9_3].details.award_count + 1
				end

				arg_9_2:getChildByName("desc2"):setString(var_0_1:translation("BUY_TIMES") .. " " .. arg_9_1.details.award_count .. " / " .. xyd.tables.misc.herosellBuyLimit)

				if not arg_9_0:canAward(arg_9_1, arg_9_5) then
					var_9_1:setTouchEnabled(false)
					var_9_1:setBright(false)
				end

				if arg_9_0.activities[arg_9_3].details.is_awards then
					local var_11_0 = xyd.luaStringSplit(arg_9_0.activities[arg_9_3].details.is_awards, "|")

					var_11_0[arg_9_4] = "1"

					local var_11_1 = xyd.luaStringMerge(var_11_0, "|")

					arg_9_0.activities[arg_9_3].details.is_awards = var_11_1
				end

				xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):refreshRedMark()

				local var_11_2 = xyd.WindowManager.get():getWindow("activities")

				if var_11_2 and not tolua.isnull(var_11_2) then
					var_11_2:rightLayout()
				end
			end

			if arg_9_1.details.award_count + 1 < arg_9_5 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_HEROSELL_TIP")
				})

				return
			end

			local var_10_1 = {
				itemID = xyd.tables.activityHeroSelling:item(arg_9_4),
				callback = var_10_0
			}

			xyd.WindowManager.get():openWindow("activity_select_hero", var_10_1)
		end
	end)
end

function var_0_0.canAward(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = xyd.tables.activityHeroSelling:recharge(arg_12_1.details.day_count)

	if arg_12_2 > arg_12_1.details.award_count and (var_12_0[arg_12_2] or 0) <= arg_12_1.details.charge_count then
		return true
	end

	return false
end

function var_0_0.checkInitItem(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_2.activity
	local var_13_1 = xyd.ServerTime.get():getServerTime()

	if var_13_1 >= var_13_0.start_time and var_13_0.details.day_count ~= arg_13_1 then
		return false
	end

	if var_13_1 < var_13_0.start_time and arg_13_1 ~= 1 then
		return false
	end

	return true
end

return var_0_0
