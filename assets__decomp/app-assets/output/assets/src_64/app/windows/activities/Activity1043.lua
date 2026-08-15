local var_0_0 = class("Activity", import("app.windows.activities.ActivityNormal"))

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1043/activity_1043.csb")

	var_2_0:addTo(arg_2_0.parent)

	local var_2_1 = var_2_0:getChildByName("container")

	arg_2_0:initDescLabel(var_2_1)

	local var_2_2 = xyd.tables.activityPeaceLogin:getGifts()
	local var_2_3 = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 665, 334),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_1:getChildByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))
	local var_2_4 = {
		list = var_2_3,
		activity = arg_2_0.activity,
		listNum = #var_2_2,
		count = arg_2_0.idx
	}

	arg_2_0:createAwardList(var_2_4)

	if arg_2_0.timeLabel then
		arg_2_0.timeLabel:setVisible(false)
	end
end

function var_0_0.initDescLabel(arg_3_0, arg_3_1)
	local var_3_0 = xyd.tables.translation:translation("GHOST_FESTIVAL_RULE")
	local var_3_1 = {
		color = cc.c3b(255, 255, 255)
	}

	var_3_1.size = 18

	local var_3_2 = xyd.AssetLoader.get():loadLabel(var_3_1)

	var_3_2:setString(var_3_0)
	var_3_2:setMaxLineWidth(450)
	var_3_2:addTo(arg_3_1)
	var_3_2:setAnchorPoint(cc.p(0, 1))
	var_3_2:setPosition(arg_3_1:getChildByName("desc_pos"):getPositionX() - 5, arg_3_1:getChildByName("desc_pos"):getPositionY() + 20)
	var_3_2:enableOutline(cc.c4b(22, 130, 14, 255), 2)
	var_3_2:setAdditionalKerning(-4)
end

function var_0_0.rewardItemLayout(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4)
	local var_4_0 = "windows/activities/1043/item_bg1.png"
	local var_4_1 = xyd.AssetLoader.get():loadSprite(var_4_0)

	arg_4_2:getChildByName("item_bg"):setSpriteFrame(var_4_1:getSpriteFrame())
	arg_4_2:getChildByName("notget_pic"):setVisible(false)
	arg_4_2:getChildByName("hasget_pic"):setVisible(false)
	arg_4_2:getChildByName("meirichong_piaodai"):setVisible(false)
	arg_4_2:getChildByName("item_bg"):getChildByName("meirichong_piaodai"):setVisible(false)

	local var_4_2 = arg_4_2:getChildByName("btn")
	local var_4_3 = arg_4_2:getChildByName("yilingqu")
	local var_4_4 = arg_4_2:getChildByName("lingqu")
	local var_4_5 = arg_4_2:getChildByName("get_gray")
	local var_4_6 = arg_4_2:getChildByName("expired")
	local var_4_7 = arg_4_2:getChildByName("not_begin")
	local var_4_8 = {
		btn = var_4_2,
		alreadyObtain = var_4_3,
		obtain_bright = var_4_4,
		obtain_gray = var_4_5,
		expired = var_4_6,
		notBegin = var_4_7
	}
	local var_4_9 = arg_4_2:getChildByName("reward_container")
	local var_4_10 = arg_4_2:getChildByName("item_title_container")
	local var_4_11 = cc.p(var_4_10:getPosition())

	var_4_10:setPosition(cc.p(var_4_11.x, var_4_11.y - 8))

	local var_4_12 = {
		color = cc.c3b(255, 255, 255)
	}

	var_4_12.size = 16

	local var_4_13 = xyd.AssetLoader.get():loadLabel(var_4_12)

	var_4_13:setMaxLineWidth(280)
	var_4_13:addTo(var_4_10)
	var_4_13:setAnchorPoint(cc.p(0, 0))
	var_4_13:setPosition(30, 3)
	var_4_13:enableOutline(cc.c4b(22, 130, 14, 255), 2)
	var_4_13:setAdditionalKerning(-4)

	local var_4_14 = xyd.tables.activityPeaceLogin:name(arg_4_4)

	var_4_13:setString(var_4_14)

	local var_4_15 = xyd.ServerTime.get():getServerTime()

	if arg_4_4 < arg_4_1.details.day_count then
		arg_4_0:setBtnGetState(2, var_4_8)
	elseif arg_4_4 > arg_4_1.details.day_count then
		arg_4_0:setBtnGetState(-1, var_4_8)
	elseif arg_4_1.details.can_award == 1 and arg_4_1.details.is_awarded == 0 then
		arg_4_0:setBtnGetState(1, var_4_8)
	elseif arg_4_1.details.is_awarded == 1 then
		arg_4_0:setBtnGetState(0, var_4_8)

		local var_4_16 = "windows/activities/1043/item_bg1.png"
		local var_4_17 = xyd.AssetLoader.get():loadSprite(var_4_16)

		arg_4_2:getChildByName("item_bg"):setSpriteFrame(var_4_17:getSpriteFrame())
	end

	local var_4_18 = xyd.tables.activityPeaceLogin:name(arg_4_4)

	var_4_13:setString(var_4_18)
	arg_4_0:rewardFormat(var_4_9, xyd.tables.activityPeaceLogin:gift(arg_4_4))

	if not arg_4_0:checkTime(arg_4_1) then
		arg_4_0:setBtnGetState(-1, var_4_8)
	end

	if var_4_15 < arg_4_1.start_time then
		arg_4_0:setBtnGetState(-2, var_4_8)
	end

	var_4_2:addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0.activitiesModel:getActivityReward(arg_4_1.table_id, nil, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					arg_4_0.player:handleRewards(arg_6_1.awards)
					arg_4_0:setBtnGetState(0, var_4_8)
					arg_4_0.activitiesModel:clearRedMarkState(arg_4_1.table_id, 2)

					if arg_4_0.activities[arg_4_3].details.is_awarded then
						arg_4_0.activities[arg_4_3].details.is_awarded = 1
					end

					if arg_4_0.activities[arg_4_3].details.is_awards then
						local var_6_0 = xyd.luaStringSplit(arg_4_0.activities[arg_4_3].details.is_awards, "|")

						var_6_0[arg_4_4] = "1"

						local var_6_1 = xyd.luaStringMerge(var_6_0, "|")

						arg_4_0.activities[arg_4_3].details.is_awards = var_6_1
					end

					arg_4_0.activity = arg_4_0.activities[arg_4_3]

					local var_6_2 = xyd.WindowManager.get():getWindow("activities")

					if var_6_2 then
						var_6_2:rightLayout()
					end
				end
			end)
		end
	end)
end

return var_0_0
