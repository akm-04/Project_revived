local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")
local var_0_3 = xyd.tables.activitySkinWarmup2
local var_0_4 = {
	SEVER = 2,
	PERSONAL = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.btnState = var_0_4.SEVER
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

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:changeBtnState()
	arg_3_0:setButtonClick()
	arg_3_0.container:getChildByName("txt_server"):setString(var_0_1:translation("ACTIVITY_DACALL2_ACHIEVED_COUNT"))
	arg_3_0.container:getChildByName("server"):setString(arg_3_0.details.server_count)

	local var_3_0 = arg_3_0.container:getChildByName("item_container")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_0):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0:updateListInfo()
	arg_3_0.list:reload()
end

function var_0_0.release(arg_4_0)
	if arg_4_0.handle_ then
		var_0_2.unscheduleGlobal(arg_4_0.handle_)

		arg_4_0.handle_ = nil
	end
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.scrollViewMoved_ = false
		arg_5_0.prevX_ = arg_5_1.x
		arg_5_0.prevY_ = arg_5_1.y
	elseif arg_5_1.name == "moved" then
		local var_5_0 = 3

		if var_5_0 <= math.abs(arg_5_1.y - arg_5_0.prevY_) or var_5_0 <= math.abs(arg_5_1.x - arg_5_0.prevX_) then
			arg_5_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.updateListInfo(arg_6_0)
	arg_6_0.listInfo = {}

	local var_6_0 = var_0_3:getIds()

	for iter_6_0, iter_6_1 in pairs(var_6_0) do
		if var_0_3:type(iter_6_1) == arg_6_0.btnState then
			table.insert(arg_6_0.listInfo, iter_6_1)
		end
	end
end

function var_0_0.delegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return #arg_7_0.listInfo
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_0 = arg_7_0.list:dequeueItem()

		if not var_7_0 then
			var_7_0 = arg_7_0.list:newItem()
		else
			var_7_0:removeAllChildren(true)
		end

		local var_7_1 = 610
		local var_7_2 = 150

		var_7_0:setItemSize(var_7_1, var_7_2)

		local var_7_3 = display.newNode()

		var_7_3:setContentSize(var_7_1, 138)
		arg_7_0:initCell(var_7_3, arg_7_3)
		var_7_0:addContent(var_7_3)

		return var_7_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_7_2 then
		-- block empty
	end
end

function var_0_0.initCell(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = arg_8_0.listInfo[arg_8_2]
	local var_8_1 = var_0_3:gift(var_8_0)
	local var_8_2 = var_0_3:req(var_8_0)
	local var_8_3 = var_0_3:discount(var_8_0) * 10
	local var_8_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1146/activity_item.csb")

	var_8_4:setPosition(0, 0)
	var_8_4:setAnchorPoint(0, 0)
	arg_8_1:addChild(var_8_4)

	local var_8_5 = var_8_4:getChildByName("container")

	if var_8_3 > 0 then
		var_8_5:getChildByName("discount"):setString(string.format(var_0_1:translation("ACTIVITY_DACALL_DISCOUNT"), var_8_3))
		var_8_5:getChildByName("award_container"):setPositionX(118)
	else
		var_8_5:getChildByName("discount"):setVisible(false)
		var_8_5:getChildByName("discount_bg"):setVisible(false)
		var_8_5:getChildByName("award_container"):setPositionX(20)
	end

	local var_8_6 = var_0_3:desc(var_8_0)

	if var_0_3:reqType(var_8_0) == 4 then
		var_8_6 = string.format(var_8_6, var_8_2)
	elseif var_0_3:reqType(var_8_0) == 1 or var_0_3:reqType(var_8_0) == 2 then
		local var_8_7 = xyd.tables.misc.activitySkinWarmupPartner

		if var_8_7[1] == 1 then
			var_8_6 = string.format(var_8_6, "", xyd.tables.hero:name(var_8_7[2]), var_8_2)
		elseif var_8_7[1] == 2 then
			local var_8_8 = xyd.split(var_0_1:translation("DISTANCE_TYPE_NAMES"), ":")

			var_8_6 = string.format(var_8_6, var_8_8[var_8_7[2]], "", var_8_2)
		end
	end

	var_8_5:getChildByName("support"):setString(var_8_6)
	var_8_5:getChildByName("support"):enableOutline(cc.c4b(171, 63, 115, 255), 2)
	var_8_5:getChildByName("progress_text"):setVisible(false)
	var_8_5:getChildByName("progress_txt"):setVisible(false)
	var_8_5:getChildByName("achieved"):setVisible(false)
	var_8_5:getChildByName("not_achieve"):setVisible(false)
	var_8_5:getChildByName("btn_get"):getChildByName("lingqu"):setString(var_0_1:translation("ACTIVITY_COMMON_TEXT1"))
	var_8_5:getChildByName("btn_get"):setVisible(false)

	local var_8_9 = arg_8_0.details.mission_list[var_8_0].count
	local var_8_10 = arg_8_0.details.mission_list[var_8_0].is_complete
	local var_8_11 = arg_8_0.details.base_info.is_awards[var_8_0]

	if var_8_1 and var_8_1 > 0 then
		arg_8_0:rewardLayer(var_8_5:getChildByName("award_container"), var_8_1)
	end

	if arg_8_0.btnState == var_0_4.SEVER then
		if var_8_10 == 1 then
			var_8_5:getChildByName("achieved"):setVisible(true)
		else
			var_8_5:getChildByName("not_achieve"):setVisible(true)
		end
	elseif arg_8_0.btnState == var_0_4.PERSONAL then
		if var_8_11 == 1 then
			var_8_5:getChildByName("achieved"):setVisible(true)
		elseif var_8_10 == 0 then
			var_8_5:getChildByName("progress_text"):setVisible(true)
			var_8_5:getChildByName("progress_txt"):setVisible(true)
			var_8_5:getChildByName("progress_text"):setString(var_0_1:translation("ACTIVITY_GIRL_TRAINING_TEXT2"))
			var_8_5:getChildByName("progress_txt"):setString(string.format("(%d/%d)", var_8_9, var_8_2))
		elseif var_8_10 == 1 then
			var_8_5:getChildByName("btn_get"):setVisible(true)
			var_8_5:getChildByName("btn_get"):addTouchEventListener(function(arg_9_0, arg_9_1)
				if arg_9_1 == ccui.TouchEventType.ended then
					local var_9_0

					if arg_8_0.activity.is_open == 1 then
						local var_9_1 = var_8_0

						arg_8_0.activitiesModel:getActivityReward(xyd.Activities.SkinWarmUp2, var_9_1, function(arg_10_0, arg_10_1)
							if arg_10_0 == xyd.error.OK then
								arg_8_0.selfPlayer:handleRewards(arg_10_1.awards)

								local var_10_0 = {
									activity_id = xyd.Activities.SkinWarmUp2
								}
								local var_10_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)

								var_10_1:loadSingleActivity(var_10_0, function(arg_11_0, arg_11_1)
									if arg_11_0 == xyd.error.OK then
										arg_8_0.details = arg_11_1.details

										arg_8_0.container:getChildByName("server"):setString(arg_8_0.details.server_count)
										arg_8_0.list:reload()
										var_10_1:refreshRedMark()

										local var_11_0 = xyd.WindowManager.get():getWindow("activities")

										if var_11_0 and not tolua.isnull(var_11_0) then
											var_11_0:rightLayout()
										end
									end
								end)
							end
						end)
					else
						if xyd.ServerTime.get():getServerTime() < arg_8_0.activity.start_time then
							var_9_0 = var_0_1:translation("ACTIVITY_NO_OPEN")
						elseif xyd.ServerTime.get():getServerTime() >= arg_8_0.activity.end_time then
							var_9_0 = var_0_1:translation("ACTIVITY_END")
						end

						xyd.WindowManager.get():openWindow("toast", {
							message = var_9_0
						})
					end
				end
			end)
		end
	end
end

function var_0_0.changeBtnState(arg_12_0)
	if arg_12_0.btnState == var_0_4.SEVER then
		arg_12_0.container:getChildByName("btn_server"):setTouchEnabled(false)
		arg_12_0.container:getChildByName("btn_personal"):setTouchEnabled(true)
		arg_12_0.container:getChildByName("btn_server"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_12_0.container:getChildByName("btn_personal"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_12_0.btnState == var_0_4.PERSONAL then
		arg_12_0.container:getChildByName("btn_server"):setTouchEnabled(true)
		arg_12_0.container:getChildByName("btn_personal"):setTouchEnabled(false)
		arg_12_0.container:getChildByName("btn_server"):setBrightStyle(ccui.BrightStyle.normal)
		arg_12_0.container:getChildByName("btn_personal"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_0.setButtonClick(arg_13_0)
	arg_13_0.container:getChildByName("btn_server"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			arg_13_0.btnState = var_0_4.SEVER

			arg_13_0:changeBtnState()
			arg_13_0:updateListInfo()
			arg_13_0.list:reload()
		end
	end)
	arg_13_0.container:getChildByName("btn_personal"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			arg_13_0.btnState = var_0_4.PERSONAL

			arg_13_0:changeBtnState()
			arg_13_0:updateListInfo()
			arg_13_0.list:reload()
		end
	end)
end

function var_0_0.rewardLayer(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = xyd.tables.gift:items(arg_16_2)

	if #var_16_0 == 1 and var_16_0[1] == 0 then
		var_16_0 = {}
	end

	local var_16_1 = xyd.tables.gift:itemNum(arg_16_2)
	local var_16_2 = #var_16_1
	local var_16_3 = arg_16_1:getContentSize().height
	local var_16_4 = var_16_3 / 4 - 1
	local var_16_5 = #var_16_0

	for iter_16_0 = 1, #var_16_0 do
		local var_16_6 = display.newNode()

		var_16_6:setContentSize(var_16_3, var_16_3)

		local var_16_7 = xyd.tables.item:type(var_16_0[iter_16_0])

		xyd.setItemBorder(var_16_6, var_16_0[iter_16_0], false, false, var_16_1[iter_16_0])
		var_16_6:addTo(arg_16_1)
		var_16_6:setAnchorPoint(cc.p(0, 0))
		var_16_6:setPosition((iter_16_0 - 1) * (var_16_3 + var_16_4), 0)

		local var_16_8 = {
			id = var_16_0[iter_16_0],
			lev = xyd.tables.item:level(var_16_0[iter_16_0])
		}

		if xyd.tables.item:type(var_16_0[iter_16_0]) == -1 then
			var_16_8.tipsType = 0
			var_16_8.desc1 = xyd.tables.hero:getDes(var_16_0[iter_16_0])
		elseif specialItem then
			var_16_8.tipsType = 1
			var_16_8.id = -3
		else
			var_16_8.tipsType = 1
			var_16_8.desc1 = xyd.tables.item:desc1(var_16_0[iter_16_0])
			var_16_8.desc2 = xyd.tables.item:desc2(var_16_0[iter_16_0])
		end

		var_16_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_16_0[iter_16_0])
		var_16_8.name = xyd.tables.item:name(var_16_0[iter_16_0])

		arg_16_0:addTips(var_16_6, var_16_8)
	end

	local var_16_9 = xyd.tables.gift:crystal(arg_16_2)

	if var_16_9 and var_16_9 > 0 then
		local var_16_10 = display.newNode()

		var_16_10:setContentSize(var_16_3, var_16_3)
		xyd.setItemBorder(var_16_10, -1, false, false, var_16_9)
		var_16_10:addTo(arg_16_1)
		var_16_10:setAnchorPoint(cc.p(0, 0))
		var_16_10:setPosition(var_16_5 * (var_16_3 + var_16_4), 0)

		local var_16_11 = {}

		var_16_11.id = -1
		var_16_11.tipsType = 1

		arg_16_0:addTips(var_16_10, var_16_11)

		var_16_5 = var_16_5 + 1
	end

	local var_16_12 = xyd.tables.gift:mana(arg_16_2)

	if var_16_12 and var_16_12 > 0 then
		local var_16_13 = display.newNode()

		var_16_13:setContentSize(var_16_3, var_16_3)
		xyd.setItemBorder(var_16_13, -2, false, false, var_16_12)
		var_16_13:addTo(arg_16_1)
		var_16_13:setAnchorPoint(cc.p(0, 0))
		var_16_13:setPosition(var_16_5 * (var_16_3 + var_16_4), 0)

		local var_16_14 = {}

		var_16_14.id = -2
		var_16_14.tipsType = 1

		arg_16_0:addTips(var_16_13, var_16_14)

		local var_16_15 = var_16_5 + 1
	end

	return arg_16_1
end

return var_0_0
