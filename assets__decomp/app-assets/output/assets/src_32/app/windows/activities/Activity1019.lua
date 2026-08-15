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

	local var_2_0 = "windows/activities/1018_bg.png"
	local var_2_1 = xyd.tables.activities:title(arg_2_0.activity.table_id)
	local var_2_2 = xyd.AssetLoader.get():loadSprite(var_2_0)
	local var_2_3 = xyd.AssetLoader.get():loadSprite(var_2_1)
	local var_2_4 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_4:addTo(arg_2_0.parent)
	var_2_4:setAnchorPoint(cc.p(0, 0))
	var_2_4:setPosition(0, 0)

	local var_2_5 = var_2_4:getChildByName("container")
	local var_2_6, var_2_7 = var_2_5:getChildByName("bg_pos"):getPosition()
	local var_2_8, var_2_9 = var_2_5:getChildByName("title_pos"):getPosition()

	var_2_5:getChildByName("left_time_txt"):setString(var_0_1:translation("TEAM_DRINK_LEFT_TIME"))
	var_2_2:addTo(var_2_5)
	var_2_3:addTo(var_2_5)
	var_2_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_2_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_2_2:pos(var_2_6, var_2_7)
	var_2_3:pos(var_2_8, var_2_9)
	var_2_2:setLocalZOrder(-1)
	var_2_5:getChildByName("left_time"):setString(tostring(xyd.tables.activities:cutOffTime(arg_2_0.activity.table_id) - arg_2_0.activity.details.day_count + 1) .. var_0_1:translation("UNIT_DAY"))

	local var_2_10 = var_2_5:getChildByName("list")
	local var_2_11 = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 490, 350),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_10):onScroll(handler(arg_2_0, arg_2_0.scrollListener))
	local var_2_12 = #xyd.tables.activityStone:gifts()

	local function var_2_13(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
		arg_3_0:addTouchEventListener(function(arg_4_0, arg_4_1)
			if arg_4_1 == ccui.TouchEventType.ended then
				if arg_3_3 == 0 then
					arg_2_0.activitiesModel:getActivityReward(arg_2_0.activity.table_id, arg_3_1, function(arg_5_0, arg_5_1)
						if arg_5_0 == xyd.error.OK then
							arg_2_0.player:handleRewards(arg_5_1.awards)
							arg_2_0:setAlreadyGetState2(1, arg_3_2)
							arg_2_0.activitiesModel:clearRedMarkState(arg_2_0.activity.table_id, 2)

							if arg_2_0.activities[arg_2_0.idx].details.is_awarded then
								arg_2_0.activities[arg_2_0.idx].details.is_awarded = 1
							end

							if arg_2_0.activities[arg_2_0.idx].details.is_awards then
								local var_5_0 = xyd.luaStringSplit(arg_2_0.activities[arg_2_0.idx].details.is_awards, "|")

								var_5_0[arg_3_1] = "1"

								local var_5_1 = xyd.luaStringMerge(var_5_0, "|")

								arg_2_0.activities[arg_2_0.idx].details.is_awards = var_5_1
							end

							local var_5_2 = xyd.WindowManager.get():getWindow("activities")

							if var_5_2 then
								var_5_2:rightLayout()
							end
						end
					end)
				elseif arg_3_3 == 1 then
					local var_4_0 = var_0_1:translation("ACTIVITY_STONE_TIPS1")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_4_0
					})
				elseif arg_3_3 == 2 then
					local var_4_1 = var_0_1:translation("ACTIVITY_STONE_TIPS2")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_4_1
					})
				end
			end
		end)
	end

	for iter_2_0 = 1, var_2_12 do
		local var_2_14 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/activity_item2.csb")
		local var_2_15 = var_2_14:getChildByName("container")
		local var_2_16 = xyd.tables.activityStone:name(iter_2_0)

		var_2_15:getChildByName("item_desc_txt"):setString(var_2_16)
		arg_2_0:rewardFormat(var_2_15:getChildByName("award_container"), xyd.tables.activityStone:gift(iter_2_0))

		local var_2_17 = xyd.luaStringSplit(arg_2_0.activity.details.is_awards, "|")
		local var_2_18 = {
			btn = var_2_15:getChildByName("btn"),
			alreadyObtain = var_2_15:getChildByName("already_get_gray"),
			obtain_bright = var_2_15:getChildByName("lingqu"),
			obtain_gray = var_2_15:getChildByName("get_gray"),
			expired = var_2_15:getChildByName("expired"),
			notBegin = var_2_15:getChildByName("not_begin")
		}
		local var_2_19 = arg_2_0.activity.details.day_count
		local var_2_20 = xyd.tables.activityStone:dayMax(iter_2_0)
		local var_2_21 = xyd.tables.activityStone:dayMin(iter_2_0)
		local var_2_22 = xyd.tables.activityStone:level(iter_2_0)
		local var_2_23 = xyd.tables.activityStone:recharge(iter_2_0)

		if iter_2_0 == 1 then
			if var_2_17[iter_2_0] == "1" then
				arg_2_0:setAlreadyGetState2(1, var_2_18)
			elseif var_2_17[iter_2_0] == "0" then
				if var_2_19 < var_2_21 then
					arg_2_0:setBtnGetState(-1, var_2_18)
				elseif var_2_21 <= var_2_19 and var_2_19 <= var_2_20 then
					arg_2_0:setBtnGetState(1, var_2_18)
					var_2_13(var_2_15:getChildByName("btn"), iter_2_0, var_2_18, 0)
				else
					arg_2_0:setBtnGetState(2, var_2_18)
				end

				if var_2_23 > arg_2_0.player.charge or var_2_22 > arg_2_0.player.lev then
					arg_2_0:setCanNotGetState2(1, var_2_18)
					var_2_13(var_2_15:getChildByName("btn"), iter_2_0, var_2_18, 1)
				end
			end
		elseif iter_2_0 == 2 then
			if var_2_17[iter_2_0] == "1" then
				arg_2_0:setAlreadyGetState2(1, var_2_18)
			elseif var_2_17[iter_2_0] == "0" then
				if var_2_19 < var_2_21 then
					arg_2_0:setBtnGetState(-2, var_2_18)
				elseif var_2_21 <= var_2_19 and var_2_19 <= var_2_20 then
					arg_2_0:setBtnGetState(1, var_2_18)
					var_2_13(var_2_15:getChildByName("btn"), iter_2_0, var_2_18, 0)
				else
					arg_2_0:setBtnGetState(2, var_2_18)
				end
			end

			if var_2_23 > arg_2_0.player.charge or var_2_22 > arg_2_0.player.lev then
				arg_2_0:setCanNotGetState2(1, var_2_18)
				var_2_13(var_2_15:getChildByName("btn"), iter_2_0, var_2_18, 2)
			end
		end

		local var_2_24 = display.newNode()
		local var_2_25 = var_2_15:getWidth()
		local var_2_26 = var_2_15:getHeight()

		var_2_24:setContentSize(var_2_25, var_2_26)
		var_2_14:addTo(var_2_24)
		var_2_24:setAnchorPoint(cc.p(0, 0))

		local var_2_27 = var_2_11:newItem()

		var_2_27:addContent(var_2_24)
		var_2_27:setItemSize(var_2_25, var_2_26)
		var_2_11:addItem(var_2_27)
	end

	var_2_11:reload()
end

function var_0_0.setAlreadyGetState2(arg_6_0, arg_6_1, arg_6_2)
	if arg_6_1 == 1 then
		arg_6_2.btn:setVisible(true)
		arg_6_2.btn:setTouchEnabled(false)
		arg_6_2.btn:setBright(false)
		arg_6_2.alreadyObtain:setVisible(true)
		arg_6_2.obtain_bright:setVisible(false)
		arg_6_2.obtain_gray:setVisible(false)
		arg_6_2.expired:setVisible(false)
		arg_6_2.notBegin:setVisible(false)
	end
end

function var_0_0.setCanNotGetState2(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_1 == 1 then
		arg_7_2.btn:setVisible(true)
		arg_7_2.btn:setTouchEnabled(true)
		arg_7_2.btn:setBright(false)
		arg_7_2.alreadyObtain:setVisible(false)
		arg_7_2.obtain_bright:setVisible(false)
		arg_7_2.obtain_gray:setVisible(true)
		arg_7_2.expired:setVisible(false)
		arg_7_2.notBegin:setVisible(false)
	end
end

return var_0_0
