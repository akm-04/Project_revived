local var_0_0 = class("FlappyBirdResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.score = arg_1_2.score
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("unlimit_container"):setVisible(false)
	arg_4_0:nodeByName("limit_container"):setVisible(true)
	arg_4_0:nodeByName("double_btn"):setVisible(false)
	arg_4_0:nodeByName("cost_txt"):setVisible(false)
	arg_4_0:nodeByName("yuanbao"):setVisible(false)
	arg_4_0:nodeByName("double_txt"):setVisible(false)
	arg_4_0:nodeByName("restart_btn"):setVisible(false)
	arg_4_0:nodeByName("close_limit"):setVisible(false)
	arg_4_0:nodeByName("restart_btn_limit"):setVisible(false)
	arg_4_0:nodeByName("close"):setPosition(arg_4_0:nodeByName("restart_btn"):getPosition())
	arg_4_0:nodeByName("unlimit_container"):setVisible(false)
	arg_4_0:nodeByName("unlimit_container"):setVisible(false)
	arg_4_0:nodeByName("unlimit_container"):setVisible(false)
	arg_4_0:nodeByName("game_over_text"):setString(var_0_1:translation("FLAPPY_BIRD_TEXT_1"))
	arg_4_0:nodeByName("score_text"):setString(var_0_1:translation("FLAPPY_BIRD_TEXT_15"))
	arg_4_0:nodeByName("score_txt"):setString(arg_4_0.score)
	arg_4_0:nodeByName("close"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playCloseSound()
			xyd.WindowManager.get():closeWindow(arg_4_0)
			cc.Director:getInstance():popScene()
		end
	end)
end

return var_0_0
