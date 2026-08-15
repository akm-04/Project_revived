local var_0_0 = class("VipBoxDrawExtraWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.award = arg_1_2.award
	arg_1_0.multiple = arg_1_2.multiple
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("txt_title"):setString(var_0_2:translation("ACTIVITY_1106_TEXT_3"))
	arg_2_0:nodeByName("txt_scroll"):setString(var_0_2:translation("ACTIVITY_1106_TEXT_4"))

	arg_2_0.container = arg_2_0:nodeByName("card_container")

	arg_2_0.container:setVisible(false)
	arg_2_0:nodeByName("txt_num"):setString("x" .. arg_2_0.multiple)
	arg_2_0:nodeByName("txt_num"):enableOutline(cc.c4b(93, 151, 218, 255), 4)
	arg_2_0:nodeByName("txt_scroll"):enableOutline(cc.c4b(52, 60, 75, 255), 2)
	arg_2_0:nodeByName("txt_title"):enableOutline(cc.c4b(52, 60, 75, 255), 2)

	local var_2_0 = "skeletons/ui_effect/vip_box_draw/vip_box_draw_open1"
	local var_2_1 = var_0_1.new(var_2_0 .. ".json", var_2_0 .. ".atlas", 1)

	var_2_1:addTo(arg_2_0:nodeByName("effect_container1"))
	var_2_1:play(function()
		arg_2_0.container:setVisible(true)

		local var_3_0 = "skeletons/ui_effect/vip_box_draw/vip_box_draw_open3"
		local var_3_1 = var_0_1.new(var_3_0 .. ".json", var_3_0 .. ".atlas", 1)

		var_3_1:addTo(arg_2_0.container)
		var_3_1:play(function()
			if arg_2_0.multiple > 0 then
				xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_2_0.award)
			end

			arg_2_0.canClose = true
		end)
	end, false)
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	arg_5_0:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	arg_5_0:setTouchEnabled(true)
	arg_5_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			return true
		elseif arg_6_0.name == "ended" and arg_5_0.canClose then
			xyd.WindowManager.get():closeWindow(arg_5_0.name)
		end
	end)
	arg_5_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
