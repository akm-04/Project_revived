local var_0_0 = class("MizhuChestDetailNewWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.mizhuTreasureNew
local var_0_3 = xyd.tables.gift

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.awardID = arg_1_2.award_id
	arg_1_0.pos = arg_1_2.pos
	arg_1_0.awardFlag = arg_1_2.award_flag
	arg_1_0.canOpen = arg_1_2.can_open
	arg_1_0.activityID = arg_1_2.activity_id
	arg_1_0.isOpen = arg_1_2.is_open
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_title"):setString(var_0_2:name(arg_4_0.pos, arg_4_0.awardID))
	arg_4_0:nodeByName("txt_info"):setString(var_0_1:translation("MIZHU_TREASURE_NEW_TEXT_4"))

	local var_4_0

	if arg_4_0.awardFlag == arg_4_0.pos then
		arg_4_0:nodeByName("txt_open"):setString(var_0_1:translation("MIZHU_TREASURE_NEW_TEXT_6"))

		var_4_0 = "windows/activities/1205/chest/chest_open_" .. arg_4_0.awardID .. ".png"
	else
		arg_4_0:nodeByName("txt_open"):setString(var_0_1:translation("MIZHU_TREASURE_NEW_TEXT_5"))

		var_4_0 = "windows/activities/1205/chest/chest_close_" .. arg_4_0.awardID .. ".png"
	end

	arg_4_0:nodeByName("chest"):setTexture(var_4_0)

	local var_4_1 = arg_4_0:nodeByName("list"):getContentSize()

	arg_4_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_4_1.width, var_4_1.height),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL
	}):addTo(arg_4_0:nodeByName("list"))

	arg_4_0:updateList()

	if arg_4_0.awardFlag ~= 0 or not arg_4_0.canOpen then
		arg_4_0:nodeByName("btn_open"):setTouchEnabled(false)
		arg_4_0:nodeByName("btn_open"):setBright(false)

		return
	end

	if arg_4_0.isOpen == 0 then
		arg_4_0:nodeByName("txt_open"):setString(var_0_1:translation("MIZHU_TREASURE_NEW_TEXT_8"))
		arg_4_0:nodeByName("btn_open"):setTouchEnabled(false)
		arg_4_0:nodeByName("btn_open"):setBright(false)

		return
	end

	arg_4_0:nodeByName("btn_open"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0.activities:getActivityReward2(arg_4_0.activityID, arg_4_0.awardID, arg_4_0.pos, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					arg_4_0.selfPlayer:handleRewards(arg_6_1.awards)

					if arg_4_0.callback then
						arg_4_0.callback(arg_4_0.awardID, arg_4_0.pos)
					end

					arg_4_0:close()
				end
			end)
		end
	end)
end

function var_0_0.updateList(arg_7_0)
	local var_7_0 = var_0_2:gift(arg_7_0.pos, arg_7_0.awardID)
	local var_7_1 = var_0_3:items(var_7_0)
	local var_7_2 = var_0_3:itemNum(var_7_0)
	local var_7_3 = arg_7_0:nodeByName("list"):getContentSize()

	for iter_7_0 = 1, #var_7_1 do
		local var_7_4 = arg_7_0.list:newItem()
		local var_7_5 = display.newNode()

		var_7_5:setContentSize(var_7_3.height, var_7_3.height)
		xyd.setItemAndAddTips(var_7_5, var_7_1[iter_7_0], var_7_2[iter_7_0])
		var_7_4:addContent(var_7_5)
		var_7_4:setContentSize(var_7_3.height, var_7_3.height)
		var_7_4:setItemSize(var_7_3.height + 29, var_7_3.height)
		arg_7_0.list:addItem(var_7_4)
	end

	arg_7_0.list:reload()
end

return var_0_0
