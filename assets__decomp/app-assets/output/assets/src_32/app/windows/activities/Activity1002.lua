local var_0_0 = class("Activity", import("app.windows.activities.ActivityNormal"))

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.addActivityAwardList(arg_2_0, arg_2_1)
	local var_2_0 = xyd.tables.activities:tableName(arg_2_1.activity.table_id)

	if var_2_0 and var_2_0 ~= "" then
		arg_2_1.listNum = #import("app.common.tables." .. var_2_0).new():gifts()

		local var_2_1

		for iter_2_0 = 1, arg_2_1.listNum do
			if arg_2_0:checkInitItem(iter_2_0, arg_2_1) then
				var_2_1 = xyd.tables.activityEveryDayCharge:gift(iter_2_0)

				break
			end
		end

		if var_2_1 then
			local var_2_2 = xyd.tables.gift:items(var_2_1)

			for iter_2_1, iter_2_2 in pairs(var_2_2) do
				local var_2_3 = cc.FileUtils:getInstance():fullPathForFilename("windows/activities/hero/activities_" .. iter_2_2 .. ".png")

				if io.exists(var_2_3) == true then
					local var_2_4 = arg_2_1.list:newItem()
					local var_2_5 = display.newNode()
					local var_2_6 = xyd.AssetLoader.get():loadSprite(var_2_3)

					var_2_6:addTo(var_2_5)
					var_2_6:setAnchorPoint(cc.p(0, 0))
					var_2_6:setPosition(0, 0)
					var_2_5:setContentSize(650, 215)
					var_2_4:addContent(var_2_5)
					var_2_4:setItemSize(650, 215)
					arg_2_1.list:addItem(var_2_4, 1)

					break
				end
			end
		end

		if not arg_2_1.listNum then
			return
		else
			arg_2_0:createAwardList(arg_2_1)
		end
	end
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

	local var_3_11 = xyd.tables.activityEveryDayCharge:name(arg_3_4)

	var_3_10:setString(var_3_11)

	local var_3_12 = xyd.ServerTime.get():getServerTime()

	if arg_3_1.details.is_awarded == 1 then
		arg_3_0:setBtnGetState(0, var_3_6)
	elseif arg_3_1.details.can_award == 0 then
		arg_3_0:setBtnGetState(-1, var_3_6)
	else
		arg_3_0:setBtnGetState(1, var_3_6)
	end

	arg_3_0:rewardFormat(var_3_7, xyd.tables.activityEveryDayCharge:gift(arg_3_4))

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

function var_0_0.checkInitItem(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_2.activity

	if xyd.ServerTime.get():getServerTime() >= var_6_0.start_time and var_6_0.details.day_count ~= arg_6_1 then
		return false
	end

	return true
end

return var_0_0
