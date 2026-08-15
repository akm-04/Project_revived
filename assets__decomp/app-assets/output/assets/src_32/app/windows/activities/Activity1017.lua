local var_0_0 = class("Activity", import("app.windows.activities.ActivityNormal"))

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.rewardItemLayout(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4)
	local var_2_0 = arg_2_2:getChildByName("btn")
	local var_2_1 = arg_2_2:getChildByName("yilingqu")
	local var_2_2 = arg_2_2:getChildByName("lingqu")
	local var_2_3 = arg_2_2:getChildByName("get_gray")
	local var_2_4 = arg_2_2:getChildByName("expired")
	local var_2_5 = arg_2_2:getChildByName("not_begin")
	local var_2_6 = {
		btn = var_2_0,
		alreadyObtain = var_2_1,
		obtain_bright = var_2_2,
		obtain_gray = var_2_3,
		expired = var_2_4,
		notBegin = var_2_5
	}
	local var_2_7 = arg_2_2:getChildByName("reward_container")
	local var_2_8 = arg_2_2:getChildByName("item_title_container")
	local var_2_9 = {
		color = cc.c3b(255, 255, 255)
	}

	var_2_9.size = 20

	local var_2_10 = xyd.AssetLoader.get():loadLabel(var_2_9)

	var_2_10:setMaxLineWidth(280)
	var_2_10:addTo(var_2_8)
	var_2_10:setAnchorPoint(cc.p(0, 0))
	var_2_10:setPosition(10, 3)
	var_2_10:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	local var_2_11 = xyd.tables.activityMidAutumn:name(arg_2_4)

	var_2_10:setString(var_2_11)

	local var_2_12 = xyd.ServerTime.get():getServerTime()

	if arg_2_4 < arg_2_1.details.day_count then
		arg_2_0:setBtnGetState(2, var_2_6)
	elseif arg_2_4 > arg_2_1.details.day_count then
		arg_2_0:setBtnGetState(-1, var_2_6)
	elseif arg_2_1.details.can_award == 1 and arg_2_1.details.is_awarded == 0 then
		arg_2_0:setBtnGetState(1, var_2_6)
	elseif arg_2_1.details.is_awarded == 1 then
		arg_2_0:setBtnGetState(0, var_2_6)
	end

	local var_2_13 = xyd.tables.activityMidAutumn:name(arg_2_4)

	var_2_10:setString(var_2_13)
	arg_2_0:rewardFormat(var_2_7, xyd.tables.activityMidAutumn:gift(arg_2_4))

	if not arg_2_0:checkTime(arg_2_1) then
		arg_2_0:setBtnGetState(-1, var_2_6)
	end

	if var_2_12 < arg_2_1.start_time then
		arg_2_0:setBtnGetState(-2, var_2_6)
	end

	var_2_0:addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			arg_2_0.activitiesModel:getActivityReward(arg_2_1.table_id, nil, function(arg_4_0, arg_4_1)
				if arg_4_0 == xyd.error.OK then
					arg_2_0.player:handleRewards(arg_4_1.awards)
					arg_2_0:setBtnGetState(0, var_2_6)
					arg_2_0.activitiesModel:clearRedMarkState(arg_2_1.table_id, 2)

					if arg_2_0.activities[arg_2_3].details.is_awarded then
						arg_2_0.activities[arg_2_3].details.is_awarded = 1
					end

					if arg_2_0.activities[arg_2_3].details.is_awards then
						local var_4_0 = xyd.luaStringSplit(arg_2_0.activities[arg_2_3].details.is_awards, "|")

						var_4_0[arg_2_4] = "1"

						local var_4_1 = xyd.luaStringMerge(var_4_0, "|")

						arg_2_0.activities[arg_2_3].details.is_awards = var_4_1
					end

					local var_4_2 = xyd.WindowManager.get():getWindow("activities")

					if var_4_2 then
						var_4_2:rightLayout()
					end
				end
			end)
		end
	end)
end

function var_0_0.checkInitItem(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_2.activity

	if xyd.ServerTime.get():getServerTime() >= var_5_0.start_time and arg_5_1 < var_5_0.details.day_count then
		return false
	end

	return true
end

return var_0_0
