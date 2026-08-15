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
	local var_3_0 = {
		color = cc.c3b(142, 74, 122)
	}

	var_3_0.size = 22

	local var_3_1 = xyd.AssetLoader.get():loadLabel(var_3_0)

	var_3_1:setMaxLineWidth(570)
	var_3_1:setString(xyd.tables.activities:desc(arg_3_0.activity.table_id))
	var_3_1:addTo(arg_3_0.container:getChildByName("desc_container"))
	var_3_1:setAnchorPoint(cc.p(0, 1))
	var_3_1:setPosition(5, arg_3_0.container:getChildByName("desc_container"):getHeight() - 5)
	arg_3_0.container:getChildByName("fresh_time_txt"):setString(string.format(var_0_1:translation("ACTIVITY_1195_TXT"), arg_3_0.player.vip))

	local var_3_2 = arg_3_0.container:getChildByName("award_bg"):getChildByName("award_container")
	local var_3_3 = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_2:getWidth(), var_3_2:getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_2)

	local function var_3_4()
		local var_4_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)

		xyd.WindowManager.get():closeWindow("activities")
		var_4_0:loadActivities(function(arg_5_0)
			if arg_5_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("activities", {
					default_table_id = 1195
				})
			end
		end)
	end

	arg_3_0.container:getChildByName("go_vip_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_3_0.container:getChildByName("go_vip_btn"), arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = {}

			var_6_0.windowState = true
			var_6_0.callback = var_3_4

			xyd.WindowManager.get():openWindow("vip_recharge", var_6_0)
		end
	end)

	local var_3_5 = {
		activity = arg_3_0.activity,
		list = var_3_3,
		count = arg_3_0.idx
	}

	arg_3_0:addActivityAwardList(var_3_5)
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
		local var_7_4 = var_7_0:newItem()
		local var_7_5 = display.newNode()
		local var_7_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1195/vip_free_item.csb")
		local var_7_7 = var_7_6:getChildByName("container")

		arg_7_0:rewardItemLayout(var_7_1, var_7_7, var_7_3, iter_7_0)
		var_7_6:addTo(var_7_5)
		var_7_6:setTouchEnabled(true)
		var_7_6:setAnchorPoint(cc.p(0, 0))
		var_7_6:setPosition(0, 0)
		var_7_6:setTouchSwallowEnabled(false)
		var_7_5:setContentSize(610, 150)
		var_7_4:addContent(var_7_5)
		var_7_4:setItemSize(610, 150)
		var_7_0:addItem(var_7_4)
	end

	var_7_0:reload()
end

function var_0_0.addActivityAwardList(arg_8_0, arg_8_1)
	local var_8_0 = xyd.tables.activities:tableName(arg_8_1.activity.table_id)

	if var_8_0 and var_8_0 ~= "" then
		local var_8_1 = import("app.common.tables." .. var_8_0).new()

		arg_8_0.activityTable = var_8_1
		arg_8_1.listNum = #var_8_1:gifts()

		if not arg_8_1.listNum then
			return
		else
			arg_8_0:createAwardList(arg_8_1)
		end
	end
end

function var_0_0.rewardItemLayout(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4)
	local var_9_0 = arg_9_0.activityTable:name(arg_9_4)
	local var_9_1 = arg_9_2:getChildByName("lingqu_btn")

	arg_9_2:getChildByName("desc"):setString(var_9_0)
	arg_9_2:getChildByName("desc"):enableOutline(cc.c4b(178, 54, 33, 255), 2)

	local var_9_2 = arg_9_2:getChildByName("item_container")
	local var_9_3 = xyd.ServerTime.get():getServerTime()

	if arg_9_0.player.vip < arg_9_0.activityTable:vip(arg_9_4) then
		var_9_1:setTouchEnabled(false)
		var_9_1:setBright(false)
	end

	if arg_9_1.details.is_awarded[arg_9_4] == 1 then
		var_9_1:setVisible(false)
		arg_9_2:getChildByName("already_get"):setVisible(true)
	end

	arg_9_0:rewardFormat(var_9_2, arg_9_0.activityTable:gift(arg_9_4), arg_9_0.activity)

	if not arg_9_0:checkTime(arg_9_1) then
		var_9_1:setTouchEnabled(false)
		var_9_1:setBright(false)
	end

	if var_9_3 < arg_9_1.start_time then
		var_9_1:setTouchEnabled(false)
		var_9_1:setBright(false)
	end

	var_9_1:addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			local var_10_0 = arg_9_4

			arg_9_0.activitiesModel:getActivityReward(arg_9_1.table_id, var_10_0, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					arg_9_0.player:handleRewards(arg_11_1.awards)
					var_9_1:setVisible(false)
					arg_9_2:getChildByName("already_get"):setVisible(true)
					arg_9_0.activitiesModel:clearRedMarkState(arg_9_1.table_id, 2)

					if arg_9_0.activities[arg_9_3].details.is_awarded then
						arg_9_0.activities[arg_9_3].details.is_awarded = 1
					end

					if arg_9_0.activities[arg_9_3].details.is_awards then
						local var_11_0 = xyd.luaStringSplit(arg_9_0.activities[arg_9_3].details.is_awards, "|")

						var_11_0[arg_9_4] = "1"

						local var_11_1 = xyd.luaStringMerge(var_11_0, "|")

						arg_9_0.activities[arg_9_3].details.is_awards = var_11_1
					end

					local var_11_2 = xyd.WindowManager.get():getWindow("activities")

					if var_11_2 then
						var_11_2:rightLayout()
					end
				end
			end)
		end
	end)
end

function var_0_0.rewardFormat(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = arg_12_1:getContentSize().height

	dump(var_12_0)

	local var_12_1 = 10
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

	local var_12_7 = xyd.tables.gift:crystal(arg_12_2)

	if var_12_7 and var_12_7 > 0 then
		local var_12_8 = display.newNode()

		var_12_8:setContentSize(var_12_0, var_12_0)
		xyd.setItemBorder(var_12_8, -1, false, false, var_12_7)
		var_12_8:addTo(arg_12_1)
		var_12_8:setAnchorPoint(cc.p(0, 0))
		var_12_8:setPosition(var_12_4 * (var_12_0 + var_12_1), 0)

		local var_12_9 = {}

		var_12_9.id = -1
		var_12_9.tipsType = 1

		arg_12_0:addTips(var_12_8, var_12_9)

		var_12_4 = var_12_4 + 1
	end

	local var_12_10 = xyd.tables.gift:mana(arg_12_2)

	if var_12_10 and var_12_10 > 0 then
		local var_12_11 = display.newNode()

		var_12_11:setContentSize(var_12_0, var_12_0)
		xyd.setItemBorder(var_12_11, -2, false, false, var_12_10)
		var_12_11:addTo(arg_12_1)
		var_12_11:setAnchorPoint(cc.p(0, 0))
		var_12_11:setPosition(var_12_4 * (var_12_0 + var_12_1), 0)

		local var_12_12 = {}

		var_12_12.id = -2
		var_12_12.tipsType = 1

		arg_12_0:addTips(var_12_11, var_12_12)

		local var_12_13 = var_12_4 + 1
	end

	return arg_12_1
end

return var_0_0
