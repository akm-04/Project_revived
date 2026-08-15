local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	if var_2_0 then
		arg_2_0.container = var_2_0:getChildByName("container")

		var_2_0:addTo(arg_2_0.parent)

		arg_2_0.getBtn = arg_2_0.container:getChildByName("get_btn")

		arg_2_0.getBtn:addTouchEventListener(function(arg_3_0, arg_3_1)
			if arg_3_1 == ccui.TouchEventType.began then
				arg_2_0.getBtn:setScale(0.9)
			elseif arg_3_1 == ccui.TouchEventType.moved then
				arg_2_0.getBtn:setScale(1)
			elseif arg_3_1 == ccui.TouchEventType.ended then
				arg_2_0.getBtn:setScale(1)
				xyd.playButtonSound()

				if arg_2_0.activity.details.step == 2 then
					arg_2_0.activitiesModel:getActivityReward(arg_2_0.activity.table_id, nil, function(arg_4_0, arg_4_1)
						if arg_4_0 == xyd.error.OK then
							arg_2_0.activity.details = arg_4_1.base_info
							arg_2_0.activitiesModel:getActivitiesList()[arg_2_0.idx].details = arg_4_1.base_info

							arg_2_0:updateGetBtnState()

							if arg_4_1.awards then
								arg_2_0.selfPlayer:handleRewards(arg_4_1.awards)
							end
						end
					end)
				else
					xyd.Backend.get():request(xyd.mid.WATER_MUSHROOM, {}, function(arg_5_0, arg_5_1)
						if arg_5_0 == xyd.error.OK then
							arg_2_0.activity.details = arg_5_1
							arg_2_0.activitiesModel:getActivitiesList()[arg_2_0.idx].details = arg_5_1

							arg_2_0:updateGetBtnState()

							if arg_2_0.activity.details.grow_day == 1 then
								arg_2_0.heroModel:playAnimation_("yueka", false, nil, nil, function()
									if arg_2_0 and arg_2_0.heroModel and not tolua.isnull(arg_2_0.heroModel) then
										arg_2_0.heroModel:idle()
										arg_2_0:updateMashRoom()
									end
								end)
							else
								arg_2_0.heroModel:playAnimation_("yueka", false, nil, nil, function()
									if arg_2_0 and arg_2_0.heroModel and not tolua.isnull(arg_2_0.heroModel) then
										arg_2_0.heroModel:idle()
										arg_2_0:updateMashRoom()
									end
								end)
							end
						end
					end)
				end
			end
		end)

		local var_2_1 = xyd.createLabel(20, cc.c3b(255, 255, 223))

		var_2_1:setWidth(420)
		var_2_1:setLineHeight(35)
		var_2_1:setString(var_0_1:translation("ACTIVITY_1097_TEXT5"))
		var_2_1:setAnchorPoint(0, 1)
		var_2_1:addTo(arg_2_0.container:getChildByName("word_pos"))
		arg_2_0:update()
	end
end

function var_0_0.update(arg_8_0)
	arg_8_0:updateGetBtnState()
	arg_8_0:addLeftHeroModel()
	arg_8_0:updateMashRoom()
end

function var_0_0.updateMashRoom(arg_9_0)
	local var_9_0 = 7
	local var_9_1 = arg_9_0.activity.details.grow_day

	for iter_9_0 = 1, var_9_0 do
		arg_9_0:addMashroomModel(iter_9_0, var_9_1)
	end

	if arg_9_0.activity.details.step == 1 then
		arg_9_0.container:getChildByName("culture_img"):setVisible(true)
		arg_9_0.container:getChildByName("matrued_img"):setVisible(false)
	else
		arg_9_0.container:getChildByName("culture_img"):setVisible(false)
		arg_9_0.container:getChildByName("matrued_img"):setVisible(true)
	end

	arg_9_0.container:getChildByName("progress_pos1"):setString(arg_9_0.activity.details.day_count)

	if arg_9_0.activity.details.step == 1 then
		arg_9_0.container:getChildByName("progress_pos2"):setString(7)
	else
		arg_9_0.container:getChildByName("progress_pos2"):setString(30)
	end
end

function var_0_0.addLeftHeroModel(arg_10_0)
	local var_10_0 = xyd.tables.misc.smallMonthCardModel1

	arg_10_0.heroModel = xyd.HeroAnimation.new(nil, var_10_0, 1, {})

	arg_10_0.heroModel:addTo(arg_10_0.container:getChildByName("hero_pos"))
	arg_10_0.heroModel:setScale(1.2)
	arg_10_0.heroModel:idle()
end

function var_0_0.palyWatering(arg_11_0)
	arg_11_0.heroModel:playAnimation_("yueka", false, nil, nil, function()
		arg_11_0.heroModel:idle()
	end)
end

function var_0_0.addMashroomModel(arg_13_0, arg_13_1, arg_13_2)
	if arg_13_2 == 0 and arg_13_0.activity.details.is_login == 0 then
		return
	end

	arg_13_0.container:getChildByName("mashroom_pos" .. arg_13_1):removeAllChildren(true)

	local var_13_0 = xyd.tables.misc.smallMonthCardModel2
	local var_13_1 = xyd.HeroAnimation.new(nil, var_13_0, arg_13_2 / 7, {})

	var_13_1:addTo(arg_13_0.container:getChildByName("mashroom_pos" .. arg_13_1))
	var_13_1:setPosition(cc.p(0, 0))
	var_13_1:setScale(0.8)
	var_13_1:idle()
end

function var_0_0.updateGetBtnState(arg_14_0)
	local var_14_0 = arg_14_0.activities[arg_14_0.idx].details

	arg_14_0.getBtn:setTouchEnabled(false)

	if var_14_0.step == 1 then
		if var_14_0.is_login == 0 then
			arg_14_0.getBtn:setBright(true)
			arg_14_0.getBtn:setTouchEnabled(true)
			arg_14_0.getBtn:getChildByName("txt"):setString(var_0_1:translation("ACTIVITY_1097_TEXT1"))
		else
			arg_14_0.getBtn:setBright(false)
			arg_14_0.getBtn:getChildByName("txt"):setString(var_0_1:translation("ACTIVITY_1097_TEXT2"))
		end
	elseif var_14_0.is_awarded == 0 then
		arg_14_0.getBtn:setBright(true)
		arg_14_0.getBtn:setTouchEnabled(true)
		arg_14_0.getBtn:getChildByName("txt"):setString(var_0_1:translation("ACTIVITY_1097_TEXT3"))
	else
		arg_14_0.getBtn:setBright(false)
		arg_14_0.getBtn:getChildByName("txt"):setString(var_0_1:translation("ACTIVITY_1097_TEXT4"))
	end
end

return var_0_0
