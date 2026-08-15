local var_0_0 = class("PeakArenaEffectWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.rankLev = arg_1_2.rankLev
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("icon1"):loadTexture("windows/peak_arena/pic/rank" .. arg_2_0.rankLev .. ".png")
	arg_2_0:nodeByName("word1"):setTexture("windows/peak_arena/pic/word" .. arg_2_0.rankLev .. ".png")
	arg_2_0:nodeByName("icon2"):loadTexture("windows/peak_arena/pic/rank" .. arg_2_0.rankLev - 1 .. ".png")
	arg_2_0:nodeByName("word2"):setTexture("windows/peak_arena/pic/word" .. arg_2_0.rankLev - 1 .. ".png")

	local var_2_0 = "skeletons/ui_effect/peak_promotion/legend_promo_title"
	local var_2_1 = var_0_1.new(var_2_0 .. ".json", var_2_0 .. ".atlas", 1)

	var_2_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_2_1:addTo(arg_2_0:nodeByName("effect_container"))
	var_2_1:play(function()
		var_2_1:play(nil, true, nil, "texiao02")
	end, false, nil, "texiao01")
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayer()
end

return var_0_0
