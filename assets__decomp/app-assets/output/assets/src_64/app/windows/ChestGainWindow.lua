local var_0_0 = class("ChestGainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.pass = arg_1_2.passedStage
	arg_1_0.marchModel = xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("desc"):setString(var_0_1:translation("EXTRA_CHEST_TIP4"))

	local var_3_0 = {
		size = 24,
		color = cc.c3b(232, 104, 14)
	}
	local var_3_1 = xyd.AssetLoader.get():loadLabel(var_3_0)

	var_3_1:setString(var_0_1:translation("EXTRA_CHEST_TIP5"))
	var_3_1:setAnchorPoint(cc.p(0, 1))
	var_3_1:addTo(arg_3_0:nodeByName("background"))
	var_3_1:setPosition(arg_3_0:nodeByName("tip_pos"):getPosition())
	var_3_1:setMaxLineWidth(330)

	local var_3_2 = "skeletons/ui_effect/effect_baoxiang/baoxiang01" .. ".json"
	local var_3_3 = "skeletons/ui_effect/effect_baoxiang/baoxiang01" .. ".atlas"

	arg_3_0.effect = var_0_2.new(var_3_2, var_3_3, 1)

	arg_3_0.effect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_3_0.effect:setPosition(arg_3_0:nodeByName("background"):getChildByName("chest_effect_pos"):getPosition())
	arg_3_0.effect:addTo(arg_3_0:nodeByName("background"))
	arg_3_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			return true
		elseif arg_4_0.name == "ended" and arg_3_0.marchModel.isGetExtraAward == 0 then
			local var_4_0 = {
				passedStage = arg_3_0.pass
			}

			xyd.WindowManager.get():openWindow("open_chest_wnd", var_4_0)
			xyd.WindowManager.get():closeWindow("chest_gain_wnd")
		end
	end)
	arg_3_0.effect:play(nil, true)
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:addBlockLayer()
end

return var_0_0
