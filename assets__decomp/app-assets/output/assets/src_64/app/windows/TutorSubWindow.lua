local var_0_0 = class("TutorSubWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.tutor = xyd.ModelManager.get():loadModel(xyd.ModelType.TUTOR)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addThemeBG()
	arg_2_0:addTopSidebar({
		show_rule = true
	})
	xyd.nodeEventSample(arg_2_0:nodeByName("exam_node"), {}, function()
		xyd.WindowManager.get():openWindow("tutor_exam")
	end)
	xyd.nodeEventSample(arg_2_0:nodeByName("shop_node"), {}, function()
		xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
			xyd.WindowManager.get():openWindow("tutor_shop", {
				shop_type = 34
			})
		end)
	end)
	xyd.nodeEventSample(arg_2_0:nodeByName("instructor_node"), {}, function()
		xyd.WindowManager.get():openWindow("tutor_instructor")
	end)
	xyd.nodeEventSample(arg_2_0:nodeByName("top_sidebar"):nodeByName("rule"), nil, function(arg_7_0)
		xyd.playButtonSound()

		local var_7_0 = {}

		var_7_0.title_name = "ACTIVITY_TUTOR_RULE_TITLE"
		var_7_0.rule = "ACTIVITY_TUTOR_RULE_TEXT"
		var_7_0.style = xyd.RuleStyle.BLUE

		xyd.WindowManager.get():openWindow("new_text_rule", var_7_0)
	end)
	arg_2_0:nodeByName("exam_tip_text"):enableOutline(cc.c4b(93, 59, 143, 255), 2)
	arg_2_0:nodeByName("shop_tip_text"):enableOutline(cc.c4b(56, 60, 113, 255), 2)
	arg_2_0:nodeByName("instructor_tip_text"):enableOutline(cc.c4b(43, 88, 90, 255), 2)
	arg_2_0:nodeByName("instructor_tip_txt"):enableOutline(cc.c4b(43, 88, 90, 255), 2)
	arg_2_0:nodeByName("exam_tip_text"):setString(var_0_1:translation("TUTOR_EXAM_TIP_TEXT"))
	arg_2_0:nodeByName("shop_tip_text"):setString(var_0_1:translation("TUTOR_SHOP_TIP_TEXT"))
	arg_2_0:nodeByName("instructor_tip_text"):setString(var_0_1:translation("INSTRUCTOR_TIP_TEXT1"))
	arg_2_0:nodeByName("instructor_tip_txt"):setString(var_0_1:translation("INSTRUCTOR_TIP_TEXT2"))
end

function var_0_0.didClose(arg_8_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {}
	})
end

return var_0_0
