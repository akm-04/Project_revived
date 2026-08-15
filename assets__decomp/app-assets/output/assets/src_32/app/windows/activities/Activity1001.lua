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

	local var_2_1 = var_2_0:getChildByName("container"):getChildByName("reward_container")
	local var_2_2 = var_2_0:getChildByName("container"):getChildByName("skill_container")
	local var_2_3 = var_2_0:getChildByName("container"):getChildByName("reward_txt")
	local var_2_4 = var_2_0:getChildByName("container"):getChildByName("desc_text")
	local var_2_5 = xyd.tables.activities:title(arg_2_0.activity.table_id)
	local var_2_6 = xyd.AssetLoader.get():loadSprite(var_2_5)
	local var_2_7, var_2_8 = var_2_0:getChildByName("container"):getChildByName("title_pos"):getPosition()

	var_2_6:addTo(var_2_0:getChildByName("container"))
	var_2_6:setAnchorPoint(cc.p(0.5, 0.5))
	var_2_6:pos(var_2_7, var_2_8)
	arg_2_0:rewardFormat(var_2_1, tonumber(arg_2_0.activity.details.award_id))

	local var_2_9 = 10001029
	local var_2_10 = xyd.tables.hero:getSkill(var_2_9)
	local var_2_11 = var_2_2:getContentSize().height
	local var_2_12 = var_2_11 / 4

	var_2_3:setString(var_0_1:translation("FIRST_RECHARGE_TEXT"))
	var_2_4:setString(var_0_1:translation("FIRST_RECHARGE_DESC") .. xyd.tables.hero:getDes(var_2_9))

	for iter_2_0, iter_2_1 in ipairs(var_2_10) do
		if iter_2_1 and iter_2_1 ~= 0 then
			local var_2_13 = display.newNode()

			var_2_13:setContentSize(var_2_11, var_2_11)
			xyd.setSkillBorder(var_2_13, iter_2_1, 0)
			var_2_13:addTo(var_2_2)
			var_2_13:setAnchorPoint(cc.p(0, 0))
			var_2_13:setPosition((iter_2_0 - 1) * (var_2_11 + var_2_12), 0)

			local var_2_14 = {}

			var_2_14.tipsType = 2
			var_2_14.id = iter_2_1
			var_2_14.has_jiantou = false

			arg_2_0:addTips(var_2_13, var_2_14)
		end
	end

	local var_2_15 = var_2_0:getChildByName("container"):getChildByName("recharge_btn")
	local var_2_16 = var_2_0:getChildByName("container"):getChildByName("chuzhi")
	local var_2_17 = var_2_0:getChildByName("container"):getChildByName("get_reward_txt")
	local var_2_18 = var_2_0:getChildByName("container"):getChildByName("already_get_gray")

	if arg_2_0.activity.details.can_award == 0 then
		var_2_15:setTouchEnabled(true)
		var_2_15:setBright(true)
		var_2_16:setVisible(true)
		var_2_17:setVisible(false)
		var_2_18:setVisible(false)
	elseif arg_2_0.activity.details.is_awarded == 1 then
		var_2_15:setTouchEnabled(false)
		var_2_15:setBright(false)
		var_2_16:setVisible(false)
		var_2_17:setVisible(false)
		var_2_18:setVisible(true)
	else
		var_2_15:setTouchEnabled(true)
		var_2_15:setBright(true)
		var_2_16:setVisible(false)
		var_2_17:setVisible(true)
		var_2_18:setVisible(false)
	end

	var_2_15:addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			if arg_2_0.activity.details.can_award == 0 then
				local var_3_0 = {}

				var_3_0.windowState = true
				var_3_0.chargeState = xyd.ChargeState.diamond

				xyd.WindowManager.get():openWindow("vip_recharge", var_3_0)
			elseif arg_2_0.activity.details.is_awarded ~= 1 then
				arg_2_0.activitiesModel:getActivityReward(arg_2_0.activity.table_id, nil, function(arg_4_0, arg_4_1)
					if arg_4_0 == xyd.error.OK then
						arg_2_0.player:handleRewards(arg_4_1.awards)
						var_2_15:setTouchEnabled(false)
						var_2_15:setBright(false)
						var_2_16:setVisible(false)
						var_2_17:setVisible(false)
						var_2_18:setVisible(true)
						arg_2_0.activitiesModel:clearRedMarkState(arg_2_0.activity.table_id, 2)

						arg_2_0.activities[arg_2_0.idx].details.is_awarded = 1

						local var_4_0 = xyd.WindowManager.get():getWindow("activities")

						if var_4_0 then
							var_4_0:rightLayout()
						end
					end
				end)
			else
				local var_3_1 = var_0_1:translation("HAVE_GET_AWARD")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_3_1
				})
			end
		end
	end)
end

return var_0_0
