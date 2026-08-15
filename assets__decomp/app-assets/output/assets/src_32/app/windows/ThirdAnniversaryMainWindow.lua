local var_0_0 = class("ThirdAnniversaryMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.thirdAnniModel = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
		xyd.buttonScaleAnim(arg_2_0:nodeByName("rule_btn"), arg_3_1)

		if arg_3_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_3_0 = {
				title_name = "ACTIVITY_MAIN_RULE_TITLE",
				rule = "ACTIVITY_MAIN_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_3_0)
		end
	end)
	arg_2_0:nodeByName("mission_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_2_0:nodeByName("mission_btn"), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_2_0.thirdAnniModel:loadMissionInfo(function()
				xyd.WindowManager.get():openWindow("third_anni_mission")
			end)
		end
	end)
	arg_2_0:nodeByName("collect_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("third_anni_collection")
		end
	end)
	arg_2_0:nodeByName("hit_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("third_diglett_main")
		end
	end)
	arg_2_0:nodeByName("wish_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_2_0.thirdAnniModel:loadInfo(function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					local var_9_0 = {
						isCanGetBag = arg_9_1.wish_info.is_awards,
						wishTimes = arg_9_1.wish_info.wish_times,
						energy = arg_9_1.wish_info.energy,
						energyLev = arg_9_1.wish_info.energy_lev
					}

					xyd.WindowManager.get():openWindow("wishing_wnd", var_9_0)
				end
			end)
		end
	end)
	arg_2_0:nodeByName("boss_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("third_anniversary_boss")
		end
	end)
	arg_2_0:nodeByName("bag_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("luckybag_wnd")
		end
	end)
	arg_2_0:nodeByName("graphic_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_2_0:nodeByName("graphic_btn"), arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("third_anni_graphic")
		end
	end)
	arg_2_0:nodeByName("word_rule"):setString(var_0_1:translation("SPRINGLOGIN_RULE_TITLE"))
	arg_2_0:nodeByName("word_graphic"):setString(var_0_1:translation("FOURTH_ANNI_MAIN_TXT2"))
	arg_2_0:nodeByName("word_mission"):setString(var_0_1:translation("ACTIVITY_MISSION_RULE_TITLE"))
end

return var_0_0
