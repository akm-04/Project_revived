local var_0_0 = class("BaseActivity")
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.activities = arg_1_0.activitiesModel:getActivitiesList()
	arg_1_0.idx = arg_1_1.idx
	arg_1_0.parent = arg_1_1.parent
	arg_1_0.activity = arg_1_0.activities[arg_1_0.idx]
	arg_1_0.res = xyd.tables.activities:res(arg_1_0.activity.table_id)
end

function var_0_0.show(arg_2_0, arg_2_1)
	arg_2_0:getNewestData()
end

function var_0_0.getNewestData(arg_3_0)
	arg_3_0.activities = arg_3_0.activitiesModel:getActivitiesList()

	if not arg_3_0.activity or arg_3_0.activities[arg_3_0.idx] and arg_3_0.activities[arg_3_0.idx].table_id == arg_3_0.activity.table_id then
		arg_3_0.activity = arg_3_0.activities[arg_3_0.idx]
	end
end

function var_0_0.refreshRedPoint(arg_4_0)
	xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):refreshRedMark()

	local var_4_0 = xyd.WindowManager.get():getWindow("activities")

	if var_4_0 and not tolua.isnull(var_4_0) then
		var_4_0:rightLayout()
	end
end

function var_0_0.isShow(arg_5_0, arg_5_1)
	if arg_5_0.activity then
		return xyd.tables.activities:isShow(arg_5_0.activity.table_id) == 1
	else
		return false
	end
end

function var_0_0.setBtnGetState(arg_6_0, arg_6_1, arg_6_2)
	if arg_6_1 == 1 then
		arg_6_2.btn:setVisible(true)
		arg_6_2.btn:setTouchEnabled(true)
		arg_6_2.btn:setBright(true)
		arg_6_2.alreadyObtain:setVisible(false)
		arg_6_2.obtain_bright:setVisible(true)
		arg_6_2.obtain_gray:setVisible(false)
		arg_6_2.expired:setVisible(false)
		arg_6_2.notBegin:setVisible(false)
	elseif arg_6_1 == -1 then
		arg_6_2.btn:setVisible(true)
		arg_6_2.btn:setTouchEnabled(false)
		arg_6_2.btn:setBright(false)
		arg_6_2.alreadyObtain:setVisible(false)
		arg_6_2.obtain_bright:setVisible(false)
		arg_6_2.obtain_gray:setVisible(true)
		arg_6_2.expired:setVisible(false)
		arg_6_2.notBegin:setVisible(false)
	elseif arg_6_1 == 0 then
		arg_6_2.btn:setVisible(false)
		arg_6_2.alreadyObtain:setVisible(true)
		arg_6_2.obtain_bright:setVisible(false)
		arg_6_2.obtain_gray:setVisible(false)
		arg_6_2.expired:setVisible(false)
		arg_6_2.notBegin:setVisible(false)
	elseif arg_6_1 == -2 then
		arg_6_2.btn:setVisible(true)
		arg_6_2.btn:setTouchEnabled(false)
		arg_6_2.btn:setBright(false)
		arg_6_2.alreadyObtain:setVisible(false)
		arg_6_2.obtain_bright:setVisible(false)
		arg_6_2.obtain_gray:setVisible(false)
		arg_6_2.expired:setVisible(false)
		arg_6_2.notBegin:setVisible(true)
	elseif arg_6_1 == 2 then
		arg_6_2.btn:setVisible(false)
		arg_6_2.alreadyObtain:setVisible(false)
		arg_6_2.obtain_bright:setVisible(false)
		arg_6_2.obtain_gray:setVisible(false)
		arg_6_2.expired:setVisible(true)
		arg_6_2.notBegin:setVisible(false)
	end
end

function var_0_0.formatStateText(arg_7_0, arg_7_1)
	if arg_7_1.obtain_bright and arg_7_1.obtain_bright.setString then
		arg_7_1.obtain_bright:setString(var_0_1:translation("ACTIVITY_COMMON_TEXT1"))
	end

	if arg_7_1.obtain_gray and arg_7_1.obtain_gray.setString then
		arg_7_1.obtain_gray:setString(var_0_1:translation("ACTIVITY_COMMON_TEXT1"))
	end

	if arg_7_1.notBegin and arg_7_1.notBegin.setString then
		arg_7_1.notBegin:setString(var_0_1:translation("ACTIVITY_COMMON_TEXT3"))
	end

	if arg_7_1.expired and arg_7_1.expired.setString then
		arg_7_1.expired:setString(var_0_1:translation("ACTIVITY_COMMON_TEXT4"))
	end
end

function var_0_0.createLabel(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)
	local var_8_0 = {
		color = arg_8_2,
		size = arg_8_1
	}
	local var_8_1 = xyd.AssetLoader.get():loadLabel(var_8_0)

	var_8_1:setMaxLineWidth(290)

	if arg_8_3 then
		var_8_1:setString(arg_8_3)
	end

	var_8_1:addTo(arg_8_4)

	return var_8_1
end

function var_0_0.createTimeTxt(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0
	local var_9_1
	local var_9_2 = xyd.tables.translation

	if arg_9_3 < 0 then
		var_9_0 = var_9_2:translation("FOREVER")
		var_9_1 = cc.c3b(255, 180, 34)

		return var_9_0, var_9_1
	end

	local var_9_3 = xyd.ServerTime.get():getServerTime()
	local var_9_4 = os.date("*t", var_9_3)

	var_9_4.hour = 24
	var_9_4.min = 0
	var_9_4.sec = 0

	local var_9_5 = var_9_3 + (86400 - xyd.ServerTime.get():getSecondsOfDay())

	if var_9_3 < arg_9_1 then
		local var_9_6 = (arg_9_1 - var_9_5) / 86400

		if var_9_6 < 1 and var_9_6 >= 0 then
			var_9_0 = string.format(var_9_2:translation("ACTIVITY_BEGIN_TOMORROW"), os.date("%X", arg_9_1))
		elseif var_9_6 < 0 then
			var_9_0 = string.format(var_9_2:translation("ACTIVITY_BEGIN_TODAY"), os.date("%X", arg_9_1))
		else
			local var_9_7 = math.ceil(var_9_6)

			var_9_0 = string.format(var_9_2:translation("ACTIVITY_BEGIN_DAYS"), var_9_7)
		end

		var_9_1 = cc.c3b(63, 212, 37)
	elseif arg_9_2 <= var_9_3 then
		var_9_0 = var_9_2:translation("ACTIVITY_FINISHED")
		var_9_1 = cc.c3b(255, 180, 34)
	elseif arg_9_1 <= var_9_3 and var_9_3 < arg_9_2 then
		local var_9_8 = (arg_9_2 - var_9_5) / 86400

		if var_9_8 < 0 then
			var_9_0 = string.format(var_9_2:translation("ACTIVITY_FINISH_TODAY"), os.date("%X", arg_9_2))
		elseif var_9_8 < 1 and var_9_8 >= 0 then
			var_9_0 = string.format(var_9_2:translation("ACTIVITY_FINISH_TOMORROW"), os.date("%X", arg_9_2))
		else
			local var_9_9 = math.ceil(var_9_8)

			var_9_0 = string.format(var_9_2:translation("ACTIVITY_FINISH_DAYS"), var_9_9)
		end

		var_9_1 = cc.c3b(255, 180, 34)
	end

	return var_9_0, var_9_1
end

function var_0_0.addTips(arg_10_0, arg_10_1, arg_10_2)
	xyd.addTips(arg_10_1, arg_10_2)
end

function var_0_0.scrollListener(arg_11_0, arg_11_1)
	if arg_11_1.name == "began" then
		arg_11_0.scrollViewMoved_ = false
		arg_11_0.prevY_ = arg_11_1.y
	elseif arg_11_1.name == "moved" and 20 <= math.abs(arg_11_1.y - arg_11_0.prevY_) then
		arg_11_0.scrollViewMoved_ = true
	end
end

function var_0_0.rewardFormat(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4)
	local var_12_0 = arg_12_1:getContentSize().height
	local var_12_1 = arg_12_4 or var_12_0 / 4
	local var_12_2 = xyd.tables.gift:items(arg_12_2)

	if #var_12_2 == 1 and var_12_2[1] == 0 then
		var_12_2 = {}
	end

	local var_12_3 = xyd.tables.gift:itemNum(arg_12_2)
	local var_12_4 = #var_12_2

	for iter_12_0 = 1, #var_12_2 do
		local var_12_5 = display.newNode()

		var_12_5:setContentSize(var_12_0, var_12_0)

		if xyd.tables.item:type(var_12_2[iter_12_0]) == -1 then
			xyd.setAvatarBorderNewUI(var_12_2[iter_12_0], var_12_5, 1, xyd.tables.hero:initialStar(var_12_2[iter_12_0]))
		else
			xyd.setItemBorder(var_12_5, var_12_2[iter_12_0], false, false, var_12_3[iter_12_0])
		end

		var_12_5:addTo(arg_12_1)
		var_12_5:setAnchorPoint(cc.p(0, 0))
		var_12_5:setPosition((iter_12_0 - 1) * (var_12_0 + var_12_1), 0)

		local var_12_6 = {
			id = var_12_2[iter_12_0],
			lev = xyd.tables.item:level(var_12_2[iter_12_0])
		}

		if xyd.tables.item:type(var_12_2[iter_12_0]) == -1 then
			var_12_6.tipsType = 0
			var_12_6.desc1 = xyd.tables.hero:getDes(var_12_2[iter_12_0])
		elseif specialItem then
			var_12_6.tipsType = 1
			var_12_6.id = -3
		else
			var_12_6.tipsType = 1
			var_12_6.desc1 = xyd.tables.item:desc1(var_12_2[iter_12_0])
			var_12_6.desc2 = xyd.tables.item:desc2(var_12_2[iter_12_0])
		end

		var_12_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_12_2[iter_12_0])
		var_12_6.name = xyd.tables.item:name(var_12_2[iter_12_0])

		arg_12_0:addTips(var_12_5, var_12_6)
	end

	local var_12_7 = xyd.tables.gift:skinFragment(arg_12_2)

	if var_12_7 and var_12_7 > 0 then
		local var_12_8 = display.newNode()

		var_12_8:setContentSize(var_12_0, var_12_0)
		xyd.setItemBorder(var_12_8, -101, false, false, var_12_7)
		var_12_8:addTo(arg_12_1)
		var_12_8:setAnchorPoint(cc.p(0, 0))
		var_12_8:setPosition(var_12_4 * (var_12_0 + var_12_1), 0)

		local var_12_9 = {}

		var_12_9.id = -101
		var_12_9.tipsType = 1

		arg_12_0:addTips(var_12_8, var_12_9)

		var_12_4 = var_12_4 + 1
	end

	local var_12_10 = xyd.tables.gift:crystal(arg_12_2)

	if var_12_10 and var_12_10 > 0 then
		local var_12_11 = display.newNode()

		var_12_11:setContentSize(var_12_0, var_12_0)
		xyd.setItemBorder(var_12_11, -1, false, false, var_12_10)
		var_12_11:addTo(arg_12_1)
		var_12_11:setAnchorPoint(cc.p(0, 0))
		var_12_11:setPosition(var_12_4 * (var_12_0 + var_12_1), 0)

		local var_12_12 = {}

		var_12_12.id = -1
		var_12_12.tipsType = 1

		arg_12_0:addTips(var_12_11, var_12_12)

		var_12_4 = var_12_4 + 1
	end

	local var_12_13 = xyd.tables.gift:mana(arg_12_2)

	if var_12_13 and var_12_13 > 0 then
		local var_12_14 = display.newNode()

		var_12_14:setContentSize(var_12_0, var_12_0)
		xyd.setItemBorder(var_12_14, -2, false, false, var_12_13)
		var_12_14:addTo(arg_12_1)
		var_12_14:setAnchorPoint(cc.p(0, 0))
		var_12_14:setPosition(var_12_4 * (var_12_0 + var_12_1), 0)

		local var_12_15 = {}

		var_12_15.id = -2
		var_12_15.tipsType = 1

		arg_12_0:addTips(var_12_14, var_12_15)

		var_12_4 = var_12_4 + 1
	end

	local var_12_16 = xyd.tables.gift:energy(arg_12_2)

	if var_12_16 and var_12_16 > 0 then
		local var_12_17 = display.newNode()

		var_12_17:setContentSize(var_12_0, var_12_0)
		xyd.setItemAndAddTips(var_12_17, -13, var_12_16)
		var_12_17:addTo(arg_12_1)
		var_12_17:setAnchorPoint(cc.p(0, 0))
		var_12_17:setPosition(var_12_4 * (var_12_0 + var_12_1), 0)

		local var_12_18 = var_12_4 + 1
	end

	return arg_12_1
end

function var_0_0.rewardFormatWithUIListView(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4)
	local var_13_0 = cc.ui.UIListView.new({
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_13_1:getContentSize().width + 10, arg_13_1:getContentSize().height),
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_13_1)
	local var_13_1 = arg_13_1:getContentSize().height
	local var_13_2 = arg_13_4 or var_13_1 / 4
	local var_13_3 = xyd.tables.gift:items(arg_13_2)

	if #var_13_3 == 1 and var_13_3[1] == 0 then
		var_13_3 = {}
	end

	local var_13_4 = xyd.tables.gift:itemNum(arg_13_2)
	local var_13_5 = #var_13_3

	for iter_13_0 = 1, #var_13_3 do
		local var_13_6 = display.newNode()

		var_13_6:setContentSize(var_13_1, var_13_1)

		if xyd.tables.item:type(var_13_3[iter_13_0]) == -1 then
			xyd.setAvatarBorderNewUI(var_13_3[iter_13_0], var_13_6, 1, xyd.tables.hero:initialStar(var_13_3[iter_13_0]))
		else
			xyd.setItemBorder(var_13_6, var_13_3[iter_13_0], false, false, var_13_4[iter_13_0])
		end

		local var_13_7 = var_13_0:newItem()

		var_13_7:addContent(var_13_6)
		var_13_7:setContentSize(var_13_6:getContentSize())
		var_13_0:addItem(var_13_7)
		var_13_6:setAnchorPoint(cc.p(0, 0))
		var_13_6:setPosition((iter_13_0 - 1) * (var_13_1 + var_13_2), 0)

		local var_13_8 = {
			id = var_13_3[iter_13_0],
			lev = xyd.tables.item:level(var_13_3[iter_13_0])
		}

		if xyd.tables.item:type(var_13_3[iter_13_0]) == -1 then
			var_13_8.tipsType = 0
			var_13_8.desc1 = xyd.tables.hero:getDes(var_13_3[iter_13_0])
		elseif specialItem then
			var_13_8.tipsType = 1
			var_13_8.id = -3
		else
			var_13_8.tipsType = 1
			var_13_8.desc1 = xyd.tables.item:desc1(var_13_3[iter_13_0])
			var_13_8.desc2 = xyd.tables.item:desc2(var_13_3[iter_13_0])
		end

		var_13_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_13_3[iter_13_0])
		var_13_8.name = xyd.tables.item:name(var_13_3[iter_13_0])

		arg_13_0:addTips(var_13_6, var_13_8)
	end

	local var_13_9 = xyd.tables.gift:skinFragment(arg_13_2)

	if var_13_9 and var_13_9 > 0 then
		local var_13_10 = display.newNode()

		var_13_10:setContentSize(var_13_1, var_13_1)
		xyd.setItemBorder(var_13_10, -101, false, false, var_13_9)

		local var_13_11 = var_13_0:newItem()

		var_13_11:addContent(var_13_10)
		var_13_11:setContentSize(var_13_10:getContentSize())
		var_13_0:addItem(var_13_11)
		var_13_10:setAnchorPoint(cc.p(0, 0))
		var_13_10:setPosition(var_13_5 * (var_13_1 + var_13_2), 0)

		local var_13_12 = {}

		var_13_12.id = -101
		var_13_12.tipsType = 1

		arg_13_0:addTips(var_13_10, var_13_12)

		var_13_5 = var_13_5 + 1
	end

	local var_13_13 = xyd.tables.gift:crystal(arg_13_2)

	if var_13_13 and var_13_13 > 0 then
		local var_13_14 = display.newNode()

		var_13_14:setContentSize(var_13_1, var_13_1)
		xyd.setItemBorder(var_13_14, -1, false, false, var_13_13)

		local var_13_15 = var_13_0:newItem()

		var_13_15:addContent(var_13_14)
		var_13_15:setContentSize(var_13_14:getContentSize())
		var_13_0:addItem(var_13_15)
		var_13_14:setAnchorPoint(cc.p(0, 0))
		var_13_14:setPosition(var_13_5 * (var_13_1 + var_13_2), 0)

		local var_13_16 = {}

		var_13_16.id = -1
		var_13_16.tipsType = 1

		arg_13_0:addTips(var_13_14, var_13_16)

		var_13_5 = var_13_5 + 1
	end

	local var_13_17 = xyd.tables.gift:mana(arg_13_2)

	if var_13_17 and var_13_17 > 0 then
		local var_13_18 = display.newNode()

		var_13_18:setContentSize(var_13_1, var_13_1)
		xyd.setItemBorder(var_13_18, -2, false, false, var_13_17)

		local var_13_19 = var_13_0:newItem()

		var_13_19:addContent(var_13_18)
		var_13_19:setContentSize(var_13_18:getContentSize())
		var_13_0:addItem(var_13_19)
		var_13_18:setAnchorPoint(cc.p(0, 0))
		var_13_18:setPosition(var_13_5 * (var_13_1 + var_13_2), 0)

		local var_13_20 = {}

		var_13_20.id = -2
		var_13_20.tipsType = 1

		arg_13_0:addTips(var_13_18, var_13_20)

		var_13_5 = var_13_5 + 1
	end

	local var_13_21 = xyd.tables.gift:energy(arg_13_2)

	if var_13_21 and var_13_21 > 0 then
		local var_13_22 = display.newNode()

		var_13_22:setContentSize(var_13_1, var_13_1)
		xyd.setItemAndAddTips(var_13_22, -13, var_13_21)

		local var_13_23 = var_13_0:newItem()

		var_13_23:addContent(var_13_22)
		var_13_23:setContentSize(var_13_22:getContentSize())
		var_13_0:addItem(var_13_23)
		var_13_22:setAnchorPoint(cc.p(0, 0))
		var_13_22:setPosition(var_13_5 * (var_13_1 + var_13_2), 0)

		local var_13_24 = var_13_5 + 1
	end
end

function var_0_0.createAwardList(arg_14_0, arg_14_1)
	local var_14_0 = arg_14_1.list
	local var_14_1 = arg_14_1.activity
	local var_14_2 = arg_14_1.listNum
	local var_14_3 = arg_14_1.count

	if arg_14_1.type then
		var_14_0:removeAllItems()
	end

	for iter_14_0 = 1, var_14_2 do
		if arg_14_0:checkInitItem(iter_14_0, arg_14_1) then
			local var_14_4 = var_14_0:newItem()
			local var_14_5 = display.newNode()
			local var_14_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/activity_item.csb")
			local var_14_7 = var_14_6:getChildByName("container")

			arg_14_0:rewardItemLayout(var_14_1, var_14_7, var_14_3, iter_14_0)
			var_14_6:addTo(var_14_5)
			var_14_6:setTouchEnabled(true)
			var_14_6:setAnchorPoint(cc.p(0, 0))
			var_14_6:setPosition(0, 0)
			var_14_6:setTouchSwallowEnabled(false)
			var_14_5:setContentSize(665, 148)
			var_14_4:addContent(var_14_5)
			var_14_4:setItemSize(665, 148)
			var_14_0:addItem(var_14_4)
		end
	end

	var_14_0:reload()
end

function var_0_0.rewardItemLayout(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4)
	return
end

function var_0_0.checkTime(arg_16_0, arg_16_1)
	local var_16_0 = xyd.ServerTime.get():getServerTime()
	local var_16_1 = arg_16_1.start_time
	local var_16_2 = arg_16_1.end_time

	if arg_16_1.days < 0 or arg_16_1.days > 0 and var_16_1 <= var_16_0 and var_16_0 <= var_16_2 then
		return true
	end

	return false
end

function var_0_0.release(arg_17_0)
	return
end

function var_0_0.playGuide(arg_18_0)
	return
end

return var_0_0
