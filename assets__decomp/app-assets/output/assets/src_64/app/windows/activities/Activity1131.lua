local var_0_0 = class("Activity", import("app.windows.activities.ActivityNormal"))

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.addActivityAwardList(arg_2_0, arg_2_1)
	local var_2_0 = xyd.tables.activities:tableName(arg_2_1.activity.table_id)

	if var_2_0 and var_2_0 ~= "" then
		arg_2_1.listNum = #import("app.common.tables." .. var_2_0).new():gifts()
		arg_2_1.obtainStates = xyd.luaStringSplit(arg_2_1.activity.details.is_awards, "|")

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

	local var_3_11 = xyd.tables.activityConsume2:name(arg_3_4)

	var_3_10:setString(var_3_11)

	local var_3_12 = xyd.ServerTime.get():getServerTime()
	local var_3_13 = xyd.luaStringSplit(arg_3_1.details.is_awards, "|")

	if xyd.tables.activityConsume2:consume(arg_3_4) > arg_3_1.details.consume_count then
		arg_3_0:setBtnGetState(-1, var_3_6)
	elseif var_3_13[arg_3_4] == "1" then
		arg_3_0:setBtnGetState(0, var_3_6)
	else
		arg_3_0:setBtnGetState(1, var_3_6)
	end

	arg_3_0:rewardFormat(var_3_7, xyd.tables.activityConsume2:gift(arg_3_4))

	if not arg_3_0:checkTime(arg_3_1) then
		arg_3_0:setBtnGetState(-1, var_3_6)
	end

	if var_3_12 < arg_3_1.start_time then
		arg_3_0:setBtnGetState(-2, var_3_6)
	end

	var_3_0:addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = arg_3_4

			arg_3_0.activitiesModel:getActivityReward(arg_3_1.table_id, var_4_0, function(arg_5_0, arg_5_1)
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

return var_0_0
