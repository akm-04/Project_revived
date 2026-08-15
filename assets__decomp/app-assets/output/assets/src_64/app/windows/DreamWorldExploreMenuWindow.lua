local var_0_0 = class("DreamWorldExploreMenuWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.dreamWorld = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:changeMenuState(false)
	arg_3_0:changeCollectState(false)
	arg_3_0:changeDiaryState(false)
	arg_3_0:nodeByName("btn_menu_open"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0:changeMenuState(true)
		end
	end)
	arg_3_0:nodeByName("btn_menu_close"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0:changeMenuState(false)
			arg_3_0:changeCollectState(false)
			arg_3_0:changeDiaryState(false)
		end
	end)
	arg_3_0:nodeByName("btn_return"):getChildByName("txt"):setString(var_0_1:translation("DREAM_WORLD_TEXT_7"))
	arg_3_0:nodeByName("btn_return"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_6_0 = xyd.WindowManager.get():getWindow("dream_world_explore")

			if var_6_0 and not tolua.isnull(var_6_0) then
				var_6_0:updateMapInfo()
				var_6_0:close()
			end
		end
	end)
	arg_3_0:nodeByName("btn_collect_open"):getChildByName("txt"):setString(var_0_1:translation("DREAM_WORLD_TEXT_8"))
	arg_3_0:nodeByName("btn_collect_open"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0:changeCollectState(true)
		end
	end)
	arg_3_0:nodeByName("btn_collect_close"):getChildByName("txt"):setString(var_0_1:translation("DREAM_WORLD_TEXT_8"))
	arg_3_0:nodeByName("btn_collect_close"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0:changeCollectState(false)
		end
	end)
	arg_3_0:nodeByName("btn_diary_open"):getChildByName("txt"):setString(var_0_1:translation("DREAM_WORLD_TEXT_9"))
	arg_3_0:nodeByName("btn_diary_open"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0:changeDiaryState(true)
		end
	end)
	arg_3_0:nodeByName("btn_diary_close"):getChildByName("txt"):setString(var_0_1:translation("DREAM_WORLD_TEXT_9"))
	arg_3_0:nodeByName("btn_diary_close"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0:changeDiaryState(false)
		end
	end)
	arg_3_0:nodeByName("btn_give_up"):getChildByName("txt"):setString(var_0_1:translation("DREAM_WORLD_TEXT_10"))
	arg_3_0:nodeByName("btn_give_up"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local function var_11_0()
				arg_3_0.dreamWorld:giveUpExplore()
			end

			local var_11_1 = {
				rcallBefore = 0,
				txt = var_0_1:translation("DREAM_WORLD_TEXT_12"),
				rcallback = var_11_0,
				align = xyd.ui_align.CENTER
			}

			xyd.WindowManager.get():openWindow("common_alert", var_11_1)
		end
	end)
end

function var_0_0.changeMenuState(arg_13_0, arg_13_1)
	arg_13_0:nodeByName("node_btn"):setVisible(arg_13_1)
	arg_13_0:nodeByName("btn_menu_open"):setVisible(not arg_13_1)
	arg_13_0:nodeByName("btn_menu_close"):setVisible(arg_13_1)
	arg_13_0:nodeByName("btn_collect_open"):setVisible(true)
	arg_13_0:nodeByName("btn_collect_close"):setVisible(false)
	arg_13_0:nodeByName("btn_diary_open"):setVisible(true)
	arg_13_0:nodeByName("btn_diary_close"):setVisible(false)
end

function var_0_0.changeCollectState(arg_14_0, arg_14_1)
	arg_14_0:nodeByName("btn_collect_open"):setVisible(not arg_14_1)
	arg_14_0:nodeByName("btn_collect_close"):setVisible(arg_14_1)

	if arg_14_1 then
		local var_14_0 = xyd.WindowManager.get():getWindow("dream_world_collect")

		if var_14_0 and not tolua.isnull(var_14_0) then
			var_14_0:show()
		end

		arg_14_0:changeDiaryState(false)
	else
		local var_14_1 = xyd.WindowManager.get():getWindow("dream_world_collect")

		if var_14_1 and not tolua.isnull(var_14_1) then
			var_14_1:hide()
		end
	end
end

function var_0_0.changeDiaryState(arg_15_0, arg_15_1)
	arg_15_0:nodeByName("btn_diary_open"):setVisible(not arg_15_1)
	arg_15_0:nodeByName("btn_diary_close"):setVisible(arg_15_1)

	if arg_15_1 then
		local var_15_0 = xyd.WindowManager.get():getWindow("dream_world_diary")

		if var_15_0 and not tolua.isnull(var_15_0) then
			var_15_0:show()
		end

		arg_15_0:changeCollectState(false)
	else
		local var_15_1 = xyd.WindowManager.get():getWindow("dream_world_diary")

		if var_15_1 and not tolua.isnull(var_15_1) then
			var_15_1:hide()
		end
	end
end

return var_0_0
