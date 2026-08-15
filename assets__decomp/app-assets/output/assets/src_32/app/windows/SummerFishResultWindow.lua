local var_0_0 = class("SummerFishResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.activitySummerGoldfish
local var_0_4 = {
	High = 2,
	Normal = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.summer = xyd.ModelManager.get():loadModel(xyd.ModelType.SUMMER)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.fishId = arg_1_2.fish_id
	arg_1_0.netType = arg_1_2.net_type
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	var_0_0.super.willClose(arg_3_0, arg_3_1)

	if arg_3_0.callback then
		arg_3_0.callback()
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("result_txt1"):setString(string.format(var_0_1:translation("FISH_RESUL_TEXT1"), var_0_3:color(arg_4_0.fishId)))

	local var_4_0 = var_0_3:pt(arg_4_0.fishId)

	if arg_4_0.netType == var_0_4.High then
		var_4_0 = math.floor(xyd.tables.misc.summerGoldFishSuperNetPt * var_4_0)
	end

	arg_4_0:nodeByName("result_txt2"):setString(string.format(var_0_1:translation("FISH_RESUL_TEXT2"), var_4_0))

	local var_4_1 = cc.c4b(94, 134, 236, 255)

	arg_4_0:nodeByName("result_txt1"):enableOutline(var_4_1, 2)
	arg_4_0:nodeByName("result_txt2"):enableOutline(var_4_1, 2)

	if arg_4_0.netType == var_0_4.Normal then
		arg_4_0:nodeByName("fishnet_high"):setVisible(false)
	else
		arg_4_0:nodeByName("fishnet_normal"):setVisible(false)
	end

	arg_4_0:createFishEffect()
end

function var_0_0.createFishEffect(arg_5_0)
	local var_5_0 = "skeletons/ui_effect/summer/fish2" .. ".json"
	local var_5_1 = "skeletons/ui_effect/summer/fish2" .. ".atlas"

	arg_5_0.effect = var_0_2.new(var_5_0, var_5_1, 1)

	arg_5_0.effect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_5_0.effect:addTo(arg_5_0:nodeByName("fish_pos"))
	arg_5_0.effect:setName("effect1")
	arg_5_0.effect:play(nil, true, nil, tostring(arg_5_0.fishId))
end

return var_0_0
