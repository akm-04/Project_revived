local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = 6
local var_0_2 = 15
local var_0_3 = 7
local var_0_4 = 1800
local var_0_5 = xyd.tables.translation
local var_0_6 = import("app.common.ui.SpineEffect")

function var_0_0.show(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.show(arg_1_0, arg_1_1)

	local var_1_0 = arg_1_0.activity
	local var_1_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1041/1041.csb")
	local var_1_2 = var_1_1:getChildByName("container")

	if not arg_1_2 then
		var_1_1:addTo(arg_1_0.parent)
		var_1_1:setAnchorPoint(cc.p(0, 0))
		var_1_1:setPosition(0, 0)
	end

	local var_1_3 = var_1_0.details.days
	local var_1_4 = var_1_0.details.subject_status
	local var_1_5 = var_1_0.details.ans_status
	local var_1_6 = var_1_0.details

	var_1_2:getChildByName("time_text"):setString(var_0_5:translation("LATERN_TIP_3"))

	for iter_1_0 = 1, var_0_1 do
		local var_1_7 = var_1_2:getChildByName("lantern_" .. iter_1_0)

		var_1_7:getChildByName("lantern_txt_" .. iter_1_0):setLocalZOrder(100)

		if var_1_4[iter_1_0] >= var_0_2 and var_1_5[iter_1_0] >= var_0_3 then
			local var_1_8 = "skeletons/ui_effect/effect_denglong/effect_denglong" .. ".json"
			local var_1_9 = "skeletons/ui_effect/effect_denglong/effect_denglong" .. ".atlas"
			local var_1_10 = var_0_6.new(var_1_8, var_1_9, 1)

			var_1_10:setAnchorPoint(cc.p(0.5, 0.5))
			var_1_10:setPosition(var_1_7:getChildByName("effect_pos"):getPosition())
			var_1_10:addTo(var_1_7)
			var_1_10:play(nil, true)
		end

		if var_1_3 == iter_1_0 then
			local var_1_11 = "skeletons/ui_effect/effect_denglong/effect_denglong2" .. ".json"
			local var_1_12 = "skeletons/ui_effect/effect_denglong/effect_denglong2" .. ".atlas"
			local var_1_13 = var_0_6.new(var_1_11, var_1_12, 1)

			var_1_13:setAnchorPoint(cc.p(0.5, 0.5))

			local var_1_14, var_1_15 = var_1_7:getChildByName("effect_pos"):getPosition()

			var_1_13:setPosition(var_1_14 - 3, var_1_15 + 1)
			var_1_13:addTo(var_1_7)
			var_1_13:play(nil, true)
		end

		var_1_7:setTouchEnabled(true)
		var_1_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_2_0)
			if arg_2_0.name == "began" then
				var_1_7:setScale(0.9)

				return true
			elseif arg_2_0.name == "ended" then
				var_1_7:setScale(1)

				if var_1_3 == iter_1_0 then
					local var_2_0 = arg_1_0.activity.details.open_time[iter_1_0]

					local function var_2_1()
						arg_1_0.activitiesModel:openSubject(function(arg_4_0, arg_4_1)
							if arg_4_0 == xyd.error.OK then
								arg_1_0.activity.details = arg_4_1

								local var_4_0 = xyd.ServerTime.get():getServerTime()

								if arg_1_0.activity.details and arg_1_0.activity.details.external_award and next(arg_1_0.activity.details.external_award) then
									local var_4_1 = {
										chooseAwards = arg_1_0.activity.details.external_award
									}

									xyd.WindowManager.get():openWindow("extra_award_wnd", var_4_1)
								elseif arg_1_0.activity.details.subject_status[var_1_3] >= var_0_2 or var_4_0 - var_2_0 >= var_0_4 and var_2_0 > 0 then
									local var_4_2 = var_0_5:translation("LATERN_TIP_2")

									xyd.WindowManager.get():openWindow("toast", {
										message = var_4_2
									})
								else
									local function var_4_3(arg_5_0)
										arg_1_0.activity.details = arg_5_0

										arg_1_0:show(nil, true)
									end

									local var_4_4 = {
										details = arg_4_1,
										idx = iter_1_0,
										callback = var_4_3
									}

									xyd.WindowManager.get():openWindow("answer_wnd", var_4_4)
								end
							end
						end)
					end

					if not arg_1_0.activity.details.open_time[iter_1_0] or arg_1_0.activity.details.open_time[iter_1_0] == 0 then
						local var_2_2 = var_0_5:translation("IS_START_ANSWER")

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
							var_2_2
						}, function()
							var_2_1()
						end)
					else
						var_2_1()
					end
				else
					local var_2_3

					if var_1_3 > iter_1_0 then
						var_2_3 = var_0_5:translation("LATERN_TIP_9")
					elseif var_1_3 < iter_1_0 then
						var_2_3 = var_0_5:translation("LATERN_TIP_1")
					end

					xyd.WindowManager.get():openWindow("toast", {
						message = var_2_3
					})
				end
			end
		end)
	end

	var_1_2:getChildByName("btn_rule"):setTouchEnabled(true)
	var_1_2:getChildByName("btn_rule"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(var_1_2:getChildByName("btn_rule"), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = {
				title_name = "LANTERN_RULE_TITLE",
				rule = "LATERN_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_7_0)
		end
	end)

	local var_1_16 = os.date("%m", arg_1_0.activity.start_time) .. "." .. os.date("%d", arg_1_0.activity.start_time)
	local var_1_17 = os.date("%m", arg_1_0.activity.end_time) .. "." .. os.date("%d", arg_1_0.activity.end_time)
	local var_1_18 = var_1_16 .. "-" .. var_1_17

	var_1_2:getChildByName("time"):setString(var_1_18)
end

return var_0_0
